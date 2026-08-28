using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;

namespace WC3ItemManager.Exporters
{
    public sealed class QuestLibraryExportResult
    {
        public bool Success { get; set; }
        public int GiversExported { get; set; }
        public int GiversUnchanged { get; set; }
        public int QuestsExported { get; set; }
        public List<string> FilesExported { get; } = new List<string>();
        public List<string> Warnings { get; } = new List<string>();
        public List<string> Errors { get; } = new List<string>();
        public string ErrorMessage => string.Join(Environment.NewLine, Errors);
    }

    /// <summary>
    /// Exports database-owned quest givers as PotS qXXX JASS sublibraries.
    /// Complex world behavior remains explicit hybrid hook scaffolding.
    /// </summary>
    public sealed class QuestLibraryExporter
    {
        private static readonly Regex JassIdentifier = new Regex(
            "^[A-Za-z][A-Za-z0-9_]*$", RegexOptions.Compiled);
        private static readonly Regex Rawcode = new Regex(
            "^[A-Za-z0-9]{4}$", RegexOptions.Compiled);

        private readonly QuestDesignerRepository _repository;

        public QuestLibraryExporter(string connectionString)
        {
            _repository = new QuestDesignerRepository(connectionString);
        }

        public QuestLibraryExportResult ExportAll(string outputFolder)
        {
            var result = new QuestLibraryExportResult();
            try
            {
                Directory.CreateDirectory(outputFolder);
                string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss", CultureInfo.InvariantCulture);
                var givers = _repository.GetGivers(enabledOnly: true);
                var allGivers = _repository.GetGivers().ToDictionary(g => g.Id);
                var allQuests = _repository.GetQuests().ToDictionary(q => q.Id);
                var voicelines = _repository.GetVoicelines().ToDictionary(v => v.Id);

                foreach (var giver in givers)
                {
                    if (giver.OwnershipMode == "external")
                    {
                        result.Warnings.Add(
                            $"{giver.DisplayName}: external ownership; existing source '{giver.SourceFile}' was not generated.");
                        continue;
                    }

                    var quests = _repository.GetQuests(giver.Id, exportableOnly: true);
                    var sequences = _repository.GetSequences(giver.Id, enabledOnly: true);
                    var dependencies = _repository.GetWorldEditorDependencies(giver.Id);
                    var validation = ValidateGiver(
                        giver, quests, sequences, dependencies, allGivers, allQuests, voicelines);
                    result.Warnings.AddRange(validation.Warnings);
                    if (validation.Errors.Count > 0)
                    {
                        result.Errors.AddRange(validation.Errors);
                        WriteValidationReport(outputFolder, giver, timestamp, validation, result);
                        continue;
                    }

                    string libraryName = GetLibraryName(giver);
                    string suffix = giver.OwnershipMode == "hybrid" ? ".hybrid" : "";
                    string baseName = $"{libraryName}_{timestamp}{suffix}";
                    string jassPath = Path.Combine(outputFolder, baseName + ".j");
                    string snapshotPath = Path.Combine(outputFolder, baseName + ".json");
                    string manifestPath = Path.Combine(outputFolder, baseName + ".we-dependencies.txt");
                    string reportPath = Path.Combine(outputFolder, baseName + ".validation.txt");
                    string jassText = BuildLibrary(giver, quests, sequences, allGivers, allQuests, voicelines);
                    string fingerprint = ComputeFingerprint(jassText);
                    if (string.Equals(
                            fingerprint,
                            _repository.GetLastExportFingerprint(giver.Id),
                            StringComparison.OrdinalIgnoreCase))
                    {
                        result.GiversUnchanged++;
                        continue;
                    }

                    File.WriteAllText(
                        jassPath,
                        jassText,
                        new UTF8Encoding(false));
                    File.WriteAllText(
                        snapshotPath,
                        BuildSnapshot(giver, quests, sequences, dependencies),
                        new UTF8Encoding(false));
                    File.WriteAllText(
                        manifestPath,
                        BuildWorldEditorManifest(giver, quests, sequences, dependencies),
                        new UTF8Encoding(false));
                    File.WriteAllText(
                        reportPath,
                        validation.Format(giver),
                        new UTF8Encoding(false));

                    result.FilesExported.Add(jassPath);
                    result.FilesExported.Add(snapshotPath);
                    result.FilesExported.Add(manifestPath);
                    result.FilesExported.Add(reportPath);
                    result.GiversExported++;
                    result.QuestsExported += quests.Count;
                    _repository.MarkGiverExported(giver.Id, fingerprint);
                }

                result.Success = result.Errors.Count == 0;
            }
            catch (Exception ex)
            {
                result.Errors.Add(ex.Message);
                result.Success = false;
            }
            return result;
        }

        private ValidationReport ValidateGiver(
            QuestGiverDefinition giver,
            IReadOnlyCollection<QuestDefinition> quests,
            IReadOnlyCollection<QuestSequenceDefinition> sequences,
            IReadOnlyCollection<QuestWorldEditorDependency> dependencies,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests,
            IReadOnlyDictionary<int, QuestVoicelineDefinition> voicelines)
        {
            var report = new ValidationReport();
            string prefix = giver.DisplayName + ": ";
            if (!JassIdentifier.IsMatch(GetLibraryName(giver)))
            {
                report.Errors.Add(prefix + "library name is not a valid JASS identifier.");
            }
            if (!string.IsNullOrWhiteSpace(giver.UnitCode) && !Rawcode.IsMatch(giver.UnitCode))
            {
                report.Errors.Add(prefix + "giver unit rawcode must contain four letters or digits.");
            }
            if (string.IsNullOrWhiteSpace(giver.PlacedUnitVariable) && string.IsNullOrWhiteSpace(giver.UnitCode))
            {
                report.Errors.Add(prefix + "no placed-unit variable or fallback unit rawcode is configured.");
            }
            if (giver.OwnershipMode == "hybrid")
            {
                report.Warnings.Add(prefix + "hybrid output is a scaffold; custom hooks and cleanup require review.");
            }
            foreach (var dependency in dependencies.Where(d => !d.Verified))
            {
                report.Warnings.Add(prefix + $"World Editor dependency is unverified: {dependency.DependencyKind} {dependency.Symbol}.");
            }

            foreach (var quest in quests)
            {
                string questPrefix = $"{giver.DisplayName} / {quest.Title}: ";
                if (!JassIdentifier.IsMatch(quest.QuestKey))
                {
                    report.Errors.Add(questPrefix + "quest key is not a valid JASS identifier.");
                }
                if (quest.QuestType != "normal" && quest.QuestType != "daily" && quest.QuestType != "repeatable")
                {
                    report.Errors.Add(questPrefix + "quest type must be normal, daily, or repeatable.");
                }
                if (quest.Category == "story" && quest.QuestType != "normal")
                {
                    report.Errors.Add(questPrefix + "main/story content cannot be a daily or repeatable gate.");
                }
                if (quest.RequiredReputation < -20000 || quest.RequiredReputation > 20000)
                {
                    report.Errors.Add(questPrefix + "required reputation must be between -20000 and 20000.");
                }
                if (quest.ReceiverGiverId.HasValue && quest.ReceiverGiverId.Value != giver.Id)
                {
                    if (!allGivers.TryGetValue(quest.ReceiverGiverId.Value, out var receiverGiver))
                    {
                        report.Errors.Add(questPrefix + "the selected turn-in giver does not exist.");
                    }
                    else if (string.IsNullOrWhiteSpace(receiverGiver.PlacedUnitVariable))
                    {
                        report.Errors.Add(questPrefix +
                            $"turn-in giver '{receiverGiver.DisplayName}' needs a placed-unit variable for generated JASS binding.");
                    }
                    else if (!receiverGiver.Enabled)
                    {
                        report.Errors.Add(questPrefix +
                            $"turn-in giver '{receiverGiver.DisplayName}' is disabled and cannot expose a completion dialog.");
                    }
                    else if (receiverGiver.OwnershipMode == "external")
                    {
                        AddOwnershipIssue(report, giver, questPrefix +
                            $"external turn-in giver '{receiverGiver.DisplayName}' must add the completion option in hand-owned source.");
                    }
                    if (string.IsNullOrWhiteSpace(giver.PlacedUnitVariable))
                    {
                        report.Errors.Add(questPrefix +
                            "cross-giver completion needs a placed-unit variable for the owning giver as well as the receiver.");
                    }
                }

                var objectives = _repository.GetObjectives(quest.Id);
                var reward = _repository.GetReward(quest.Id);
                var prerequisites = _repository.GetPrerequisiteIds(quest.Id);
                if (!string.IsNullOrWhiteSpace(reward.ItemCode) && !Rawcode.IsMatch(reward.ItemCode))
                {
                    report.Errors.Add(questPrefix + "reward item needs a four-character alphanumeric rawcode.");
                }
                if (!string.IsNullOrWhiteSpace(reward.CustomText))
                {
                    AddOwnershipIssue(report, giver,
                        questPrefix + "custom reward text is preview metadata; custom reward execution requires a hook.");
                }
                if (HasPrerequisiteCycle(quest.Id, new HashSet<int>(), new HashSet<int>()))
                {
                    report.Errors.Add(questPrefix + "the prerequisite graph contains a cycle.");
                }
                if (quest.Category == "story" &&
                    DependencyTreeContainsDailyOrRepeatable(prerequisites, allQuests, new HashSet<int>()))
                {
                    report.Errors.Add(questPrefix +
                        "the prerequisite tree contains a daily or repeatable quest and cannot gate main-story progression.");
                }
                if (objectives.Count > (quest.RequiresTurnIn && !quest.AutoComplete ? 7 : 8))
                {
                    report.Errors.Add(questPrefix + "the return-to-giver requirement needs one of QuestMaster's eight objective slots.");
                }
                if (prerequisites.Count > 4)
                {
                    report.Errors.Add(questPrefix + "QuestMaster supports only four prerequisites.");
                }
                foreach (int prerequisiteId in prerequisites)
                {
                    if (!allQuests.TryGetValue(prerequisiteId, out var prerequisite))
                    {
                        report.Errors.Add(questPrefix + $"prerequisite quest id {prerequisiteId} does not exist.");
                        continue;
                    }
                    if (quest.Category == "story" && prerequisite.QuestType != "normal")
                    {
                        report.Errors.Add(questPrefix + $"story progression cannot depend on {prerequisite.QuestType} quest '{prerequisite.Title}'.");
                    }
                    if (!prerequisite.Enabled || prerequisite.Draft)
                    {
                        report.Errors.Add(questPrefix +
                            $"prerequisite '{prerequisite.Title}' is disabled or still a draft.");
                    }
                    if (allGivers.TryGetValue(prerequisite.QuestGiverId, out var prerequisiteOwner) &&
                        !prerequisiteOwner.Enabled)
                    {
                        report.Errors.Add(questPrefix +
                            $"prerequisite giver '{prerequisiteOwner.DisplayName}' is disabled.");
                    }
                    if (prerequisite.QuestGiverId != giver.Id &&
                        (!allGivers.TryGetValue(prerequisite.QuestGiverId, out var prerequisiteGiver) ||
                         string.IsNullOrWhiteSpace(prerequisiteGiver.PlacedUnitVariable)))
                    {
                        report.Errors.Add(questPrefix + $"cross-giver prerequisite '{prerequisite.Title}' needs a placed-unit variable.");
                    }
                }

                int automaticTrackers = objectives.Count(o =>
                    o.CompletionMode == "automatic" && o.ObjectiveType != "manual" && o.ObjectiveType != "investigate");
                if (automaticTrackers > 1)
                {
                    AddOwnershipIssue(report, giver,
                        questPrefix + "multiple automatic trackers require a custom all-objectives aggregator.");
                }
                if (quest.QuestType == "repeatable" && objectives.All(o => string.IsNullOrWhiteSpace(o.ExternalHook)))
                {
                    AddOwnershipIssue(report, giver,
                        questPrefix + "repeatable quests require an explicit reset hook/policy.");
                }
                if (quest.AutoComplete && objectives.All(o => string.IsNullOrWhiteSpace(o.ExternalHook)))
                {
                    AddOwnershipIssue(report, giver,
                        questPrefix + "auto-complete presentation does not complete runtime state without an explicit hook.");
                }

                foreach (var objective in objectives)
                {
                    ValidateObjective(report, giver, questPrefix, objective);
                }
            }

            foreach (var inboundQuest in GetInboundQuests(giver, allQuests))
            {
                string inboundPrefix = $"{giver.DisplayName} / inbound {inboundQuest.Title}: ";
                if (!allGivers.TryGetValue(inboundQuest.QuestGiverId, out var sourceGiver))
                {
                    report.Errors.Add(inboundPrefix + "the owning quest giver does not exist.");
                }
                else if (!sourceGiver.Enabled)
                {
                    report.Errors.Add(inboundPrefix +
                        $"owning giver '{sourceGiver.DisplayName}' is disabled, so the quest cannot exist at runtime.");
                }
                else if (string.IsNullOrWhiteSpace(sourceGiver.PlacedUnitVariable))
                {
                    report.Errors.Add(inboundPrefix +
                        $"owning giver '{sourceGiver.DisplayName}' needs a placed-unit variable for completion lookup.");
                }
            }

            foreach (var sequence in sequences)
            {
                string sequencePrefix = $"{giver.DisplayName} / {sequence.DisplayName}: ";
                if (!JassIdentifier.IsMatch(sequence.SequenceKey))
                {
                    report.Errors.Add(sequencePrefix + "sequence key is not a valid JASS identifier.");
                }
                var steps = _repository.GetSequenceSteps(sequence.Id);
                if (!string.IsNullOrWhiteSpace(sequence.OnStartHook) ||
                    !string.IsNullOrWhiteSpace(sequence.OnFinishHook) ||
                    steps.Any(s => !string.IsNullOrWhiteSpace(s.ActionHook)))
                {
                    AddOwnershipIssue(report, giver,
                        sequencePrefix + "custom sequence hooks require hybrid ownership and implementation review.");
                }
                if (sequence.Purpose == "greet" &&
                    (!string.IsNullOrWhiteSpace(sequence.OnStartHook) ||
                     !string.IsNullOrWhiteSpace(sequence.OnFinishHook)))
                {
                    report.Errors.Add(sequencePrefix +
                        "greeting callbacks are reserved by DialogInteraction; use an action step instead.");
                }
                if (steps.Count > 100)
                {
                    report.Errors.Add(sequencePrefix + "DialogSystem supports at most 100 steps.");
                }
                if (sequence.QuestId.HasValue &&
                    allQuests.TryGetValue(sequence.QuestId.Value, out var linkedQuest) &&
                    linkedQuest.QuestGiverId != giver.Id &&
                    (!allGivers.TryGetValue(linkedQuest.QuestGiverId, out var linkedGiver) ||
                     string.IsNullOrWhiteSpace(linkedGiver.PlacedUnitVariable)))
                {
                    report.Errors.Add(sequencePrefix +
                        "a sequence linked to another giver's quest needs that owning giver's placed-unit variable.");
                }
                foreach (var step in steps)
                {
                    if (step.Duration < 0)
                    {
                        report.Errors.Add(sequencePrefix + $"step {step.DisplayOrder} has a negative duration.");
                    }
                    if ((step.StepType == "face_point" || step.StepType == "look_point") &&
                        (!step.PointX.HasValue || !step.PointY.HasValue))
                    {
                        report.Errors.Add(sequencePrefix +
                            $"point step {step.DisplayOrder} needs both X and Y coordinates.");
                    }
                    if (step.StepType == "line" && string.IsNullOrWhiteSpace(step.Text) && !step.VoicelineId.HasValue)
                    {
                        report.Errors.Add(sequencePrefix + $"line step {step.DisplayOrder} has no text or voiceline.");
                    }
                    if (step.VoicelineId.HasValue)
                    {
                        if (!voicelines.TryGetValue(step.VoicelineId.Value, out var voice))
                        {
                            report.Errors.Add(sequencePrefix + $"step {step.DisplayOrder} references a missing voiceline.");
                        }
                        else if (!voice.Verified)
                        {
                            report.Warnings.Add(sequencePrefix + $"voiceline '{voice.LineKey}' is not reconciled with its source library/audio.");
                        }
                        if (voicelines.TryGetValue(step.VoicelineId.Value, out voice) &&
                            !string.IsNullOrWhiteSpace(voice.ConstantName) &&
                            string.IsNullOrWhiteSpace(voice.SourceLibrary))
                        {
                            report.Errors.Add(sequencePrefix +
                                $"voiceline '{voice.LineKey}' uses a JASS constant but has no source library dependency.");
                        }
                        if (voicelines.TryGetValue(step.VoicelineId.Value, out voice) &&
                            string.Equals(voice.SourceLibrary, GetLibraryName(giver), StringComparison.Ordinal))
                        {
                            report.Errors.Add(sequencePrefix +
                                $"voiceline '{voice.LineKey}' cannot require the generated library itself.");
                        }
                    }
                    if (step.StepType == "action" && string.IsNullOrWhiteSpace(step.ActionHook))
                    {
                        report.Errors.Add(sequencePrefix + $"action step {step.DisplayOrder} has no hook name.");
                    }
                }
            }

            return report;
        }

        private static void ValidateObjective(
            ValidationReport report,
            QuestGiverDefinition giver,
            string prefix,
            QuestObjectiveDefinition objective)
        {
            if (string.IsNullOrWhiteSpace(objective.Text))
            {
                report.Errors.Add(prefix + $"objective {objective.DisplayOrder} has no player-facing text.");
            }
            if (objective.CompletionMode != "automatic")
            {
                if (string.IsNullOrWhiteSpace(objective.ExternalHook))
                {
                    AddOwnershipIssue(report, giver,
                        prefix + $"objective {objective.DisplayOrder} uses {objective.CompletionMode} completion but has no hook.");
                }
                else
                {
                    AddOwnershipIssue(report, giver,
                        prefix + $"objective {objective.DisplayOrder} uses custom hook '{objective.ExternalHook}'.");
                }
            }
            switch (objective.ObjectiveType)
            {
                case "item":
                    if (!Rawcode.IsMatch(objective.ItemCode ?? ""))
                    {
                        report.Errors.Add(prefix + $"item objective {objective.DisplayOrder} needs a four-character item rawcode.");
                    }
                    if (string.IsNullOrWhiteSpace(objective.ExternalHook))
                    {
                        AddOwnershipIssue(report, giver,
                            prefix + $"item objective {objective.DisplayOrder} validates possession but needs an explicit consume policy at turn-in.");
                    }
                    else
                    {
                        AddOwnershipIssue(report, giver,
                            prefix + $"item objective {objective.DisplayOrder} uses custom hook '{objective.ExternalHook}'.");
                    }
                    break;
                case "kill":
                    if (!Rawcode.IsMatch(objective.UnitCode ?? ""))
                    {
                        report.Errors.Add(prefix + $"kill objective {objective.DisplayOrder} needs a four-character unit rawcode.");
                    }
                    break;
                case "escort":
                    if (string.IsNullOrWhiteSpace(objective.TargetVariable) || string.IsNullOrWhiteSpace(objective.RegionVariable))
                    {
                        report.Errors.Add(prefix + $"escort objective {objective.DisplayOrder} needs target-unit and destination-rect variables.");
                    }
                    break;
                case "talk":
                case "find":
                    if (string.IsNullOrWhiteSpace(objective.TargetVariable))
                    {
                        report.Errors.Add(prefix + $"{objective.ObjectiveType} objective {objective.DisplayOrder} needs a target-unit variable.");
                    }
                    break;
                case "goto":
                    if (string.IsNullOrWhiteSpace(objective.RegionVariable))
                    {
                        report.Errors.Add(prefix + $"go-to objective {objective.DisplayOrder} needs a concrete rect variable; a zone id alone is not enough for the current tracker.");
                    }
                    break;
                case "reputation":
                    if (string.IsNullOrWhiteSpace(objective.Faction))
                    {
                        report.Errors.Add(prefix + $"reputation objective {objective.DisplayOrder} needs a faction.");
                    }
                    break;
                case "manual":
                    if (objective.CompletionMode == "automatic")
                    {
                        AddOwnershipIssue(report, giver, string.IsNullOrWhiteSpace(objective.ExternalHook)
                            ? prefix + $"manual objective {objective.DisplayOrder} needs an external completion hook."
                            : prefix + $"manual objective {objective.DisplayOrder} uses custom hook '{objective.ExternalHook}'.");
                    }
                    break;
                case "investigate":
                    if (objective.CompletionMode == "automatic")
                    {
                        AddOwnershipIssue(report, giver, string.IsNullOrWhiteSpace(objective.ExternalHook)
                            ? prefix + $"investigate objective {objective.DisplayOrder} needs a hook that calls CompleteInvestigateRequirement."
                            : prefix + $"investigate objective {objective.DisplayOrder} uses custom hook '{objective.ExternalHook}'.");
                    }
                    break;
            }
        }

        private bool HasPrerequisiteCycle(
            int questId,
            HashSet<int> visiting,
            HashSet<int> visited)
        {
            if (visiting.Contains(questId)) return true;
            if (!visited.Add(questId)) return false;
            visiting.Add(questId);
            foreach (int prerequisiteId in _repository.GetPrerequisiteIds(questId))
            {
                if (HasPrerequisiteCycle(prerequisiteId, visiting, visited)) return true;
            }
            visiting.Remove(questId);
            return false;
        }

        private bool DependencyTreeContainsDailyOrRepeatable(
            IEnumerable<int> prerequisiteIds,
            IReadOnlyDictionary<int, QuestDefinition> allQuests,
            HashSet<int> visited)
        {
            foreach (int prerequisiteId in prerequisiteIds)
            {
                if (!visited.Add(prerequisiteId)) continue;
                if (!allQuests.TryGetValue(prerequisiteId, out var prerequisite)) continue;
                if (prerequisite.QuestType == "daily" || prerequisite.QuestType == "repeatable") return true;
                if (DependencyTreeContainsDailyOrRepeatable(
                        _repository.GetPrerequisiteIds(prerequisiteId), allQuests, visited)) return true;
            }
            return false;
        }

        private static void AddOwnershipIssue(ValidationReport report, QuestGiverDefinition giver, string message)
        {
            if (giver.OwnershipMode == "managed")
            {
                report.Errors.Add(message + " Switch the giver to hybrid ownership while implementing it.");
            }
            else
            {
                report.Warnings.Add(message);
            }
        }

        private string BuildLibrary(
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests,
            IReadOnlyDictionary<int, QuestVoicelineDefinition> voicelines)
        {
            var sb = new StringBuilder();
            string libraryName = GetLibraryName(giver);
            var voiceLibraries = sequences
                .SelectMany(s => _repository.GetSequenceSteps(s.Id))
                .Where(s => s.VoicelineId.HasValue && voicelines.ContainsKey(s.VoicelineId.Value))
                .Select(s => voicelines[s.VoicelineId.Value].SourceLibrary)
                .Where(l => !string.IsNullOrWhiteSpace(l) && JassIdentifier.IsMatch(l))
                .Distinct()
                .OrderBy(l => l)
                .ToList();
            string requires = "QuestGiver, QuestMaster, DialogInteraction, DialogSystem";
            if (voiceLibraries.Count > 0)
            {
                requires += ", " + string.Join(", ", voiceLibraries);
            }

            sb.AppendLine("/**");
            sb.AppendLine($"    {libraryName}");
            sb.AppendLine();
            sb.AppendLine("    Author: Valdemar");
            sb.AppendLine("    Version:");
            sb.AppendLine();
            sb.AppendLine("    Description:");
            sb.AppendLine($"    Database-managed quest-giver sublibrary for {giver.DisplayName}.");
            if (giver.OwnershipMode == "hybrid")
            {
                sb.AppendLine("    Hybrid scaffold: review every GENERATED-HOOK marker before map import.");
            }
            sb.AppendLine();
            sb.AppendLine("    Credits:");
            sb.AppendLine("    Generated by WC3 Manager from the PotS Quest Designer database.");
            sb.AppendLine();
            sb.AppendLine("    How to install:");
            sb.AppendLine("    Import after the required quest/dialog libraries and satisfy the companion");
            sb.AppendLine("    World Editor dependency manifest emitted beside this file.");
            sb.AppendLine();
            sb.AppendLine("    API:");
            sb.AppendLine($"    - {libraryName}_ContinueToDialogAfterSelection()");
            sb.AppendLine($"    - {libraryName}_RefreshAvailability()");
            sb.AppendLine();
            sb.AppendLine("**/");
            sb.AppendLine($"library {libraryName} initializer Init requires {requires}");
            sb.AppendLine();
            AppendGlobals(sb, giver, quests);
            AppendDebugAndSync(sb, giver, libraryName);
            AppendExitHelper(sb);
            AppendGeneratedHooks(sb, giver, quests, sequences);
            AppendSequenceHandlers(sb, giver, quests, sequences, allGivers, allQuests, voicelines);
            AppendDefaultQuestHandlers(sb, giver, quests, sequences);
            AppendInboundQuestHandlers(sb, giver, sequences, allGivers, allQuests);
            AppendFarewellHandler(sb, giver, sequences);
            AppendBuildDialog(sb, giver, quests, sequences, allGivers, allQuests);
            AppendDialogEntry(sb, giver, libraryName, sequences, voicelines);
            AppendCreateQuests(sb, giver, quests, allGivers, allQuests);
            AppendInitialization(sb, giver, libraryName);
            sb.AppendLine("endlibrary");
            return sb.ToString();
        }

        private static void AppendGlobals(StringBuilder sb, QuestGiverDefinition giver, IReadOnlyList<QuestDefinition> quests)
        {
            sb.AppendLine("globals");
            sb.AppendLine("    private constant boolean DEBUG = false");
            sb.AppendLine();
            foreach (var quest in quests)
            {
                sb.AppendLine($"    public constant string QUEST_{quest.QuestKey.ToUpperInvariant()} = \"{Escape(quest.QuestName)}\"");
            }
            if (quests.Count > 0)
            {
                sb.AppendLine();
            }
            sb.AppendLine($"    private constant string GIVER_NAME = \"{Escape(giver.DisplayName)}\"");
            if (!string.IsNullOrWhiteSpace(giver.UnitCode))
            {
                sb.AppendLine($"    private constant integer GIVER_UNIT_TYPE = '{giver.UnitCode}'");
            }
            sb.AppendLine($"    private constant real DIALOG_RANGE = {Real(giver.DialogRange)}");
            sb.AppendLine($"    private constant real DIALOG_COOLDOWN = {Real(giver.DialogCooldown)}");
            sb.AppendLine($"    private constant boolean ALLOW_NAZGREK = {Bool(giver.AllowNazgrek)}");
            sb.AppendLine($"    private constant boolean ALLOW_ZULKIS = {Bool(giver.AllowZulkis)}");
            sb.AppendLine($"    private constant boolean USE_DIALOG_CAMERA = {Bool(giver.UseDialogCamera)}");
            sb.AppendLine($"    private constant boolean CINEMATIC = {Bool(giver.UseCinematicMode)}");
            sb.AppendLine();
            sb.AppendLine("    private unit Giver = null");
            sb.AppendLine("    private unit SelectedHero = null");
            sb.AppendLine("    private dialog GiverDialog = null");
            sb.AppendLine("    private timer DialogCooldown = null");
            sb.AppendLine("    private timer InitTimer = null");
            sb.AppendLine("endglobals");
            sb.AppendLine();
        }

        private static void AppendDebugAndSync(StringBuilder sb, QuestGiverDefinition giver, string libraryName)
        {
            sb.AppendLine("private function DebugMsg takes string msg returns nothing");
            sb.AppendLine("    if DEBUG then");
            sb.AppendLine($"        call BJDebugMsg(\"|cff88ccff[{libraryName}]|r \" + msg)");
            sb.AppendLine("    endif");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("private function SyncUnitReferences takes nothing returns nothing");
            if (!string.IsNullOrWhiteSpace(giver.PlacedUnitVariable))
            {
                sb.AppendLine($"    if {giver.PlacedUnitVariable} != null and {giver.PlacedUnitVariable} != Giver then");
                sb.AppendLine("        if Giver != null then");
                sb.AppendLine($"            call QuestGiver_UpdateGiverUnitReference(Giver, {giver.PlacedUnitVariable})");
                sb.AppendLine("        endif");
                sb.AppendLine($"        set Giver = {giver.PlacedUnitVariable}");
                sb.AppendLine("    endif");
            }
            if (!string.IsNullOrWhiteSpace(giver.UnitCode))
            {
                sb.AppendLine("    if not DialogInteraction_IsUnitAlive(Giver) then");
                sb.AppendLine("        set Giver = QuestGiver_FindPreferredUnitInRect(bj_mapInitialPlayableArea, GIVER_UNIT_TYPE, null, null, null, null, null, false)");
                sb.AppendLine("    endif");
            }
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private static void AppendExitHelper(StringBuilder sb)
        {
            sb.AppendLine("private function StartExitFadeOut takes nothing returns nothing");
            sb.AppendLine("    call DialogInteraction_StartConfiguredDialogExitTransition(Giver, SelectedHero, DialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private string BuildSnapshot(
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyList<QuestWorldEditorDependency> dependencies)
        {
            var snapshot = new
            {
                format = "pots-wc3-manager-quest-v1",
                exportedAt = DateTimeOffset.Now,
                giver,
                quests = quests.Select(q => new
                {
                    quest = q,
                    objectives = _repository.GetObjectives(q.Id),
                    reward = _repository.GetReward(q.Id),
                    prerequisiteIds = _repository.GetPrerequisiteIds(q.Id)
                }),
                sequences = sequences.Select(s => new
                {
                    sequence = s,
                    steps = _repository.GetSequenceSteps(s.Id)
                }),
                worldEditorDependencies = dependencies
            };
            return JsonSerializer.Serialize(snapshot, new JsonSerializerOptions { WriteIndented = true });
        }

        private string BuildWorldEditorManifest(
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyList<QuestWorldEditorDependency> dependencies)
        {
            var lines = new List<string>
            {
                $"WC3 Manager World Editor dependencies: {giver.DisplayName}",
                $"Ownership: {giver.OwnershipMode}",
                "",
                "Automatic bindings"
            };
            if (!string.IsNullOrWhiteSpace(giver.PlacedUnitVariable))
            {
                lines.Add($"- [ ] Unit global: {giver.PlacedUnitVariable}");
            }
            if (!string.IsNullOrWhiteSpace(giver.UnitCode))
            {
                lines.Add($"- [ ] Unit rawcode: {giver.UnitCode}");
            }
            foreach (var objective in quests.SelectMany(q => _repository.GetObjectives(q.Id)))
            {
                if (!string.IsNullOrWhiteSpace(objective.RegionVariable))
                {
                    lines.Add($"- [ ] Rect: {objective.RegionVariable} ({objective.Text})");
                }
                if (!string.IsNullOrWhiteSpace(objective.TargetVariable))
                {
                    lines.Add($"- [ ] Unit/global: {objective.TargetVariable} ({objective.Text})");
                }
            }
            foreach (var receiver in quests
                         .Where(q => q.ReceiverGiverId.HasValue && q.ReceiverGiverId.Value != giver.Id)
                         .Select(q => q.ReceiverGiverId.Value)
                         .Distinct()
                         .Select(id => _repository.GetGiver(id))
                         .Where(g => g != null && !string.IsNullOrWhiteSpace(g.PlacedUnitVariable)))
            {
                lines.Add($"- [ ] Turn-in unit global: {receiver.PlacedUnitVariable} ({receiver.DisplayName})");
            }
            foreach (var inbound in _repository.GetQuests()
                         .Where(q => q.Enabled && !q.Draft && q.ReceiverGiverId == giver.Id && q.QuestGiverId != giver.Id))
            {
                var sourceGiver = _repository.GetGiver(inbound.QuestGiverId);
                if (sourceGiver != null && !string.IsNullOrWhiteSpace(sourceGiver.PlacedUnitVariable))
                {
                    lines.Add($"- [ ] Owning giver unit global: {sourceGiver.PlacedUnitVariable} ({inbound.Title})");
                }
            }
            foreach (var step in sequences.SelectMany(s => _repository.GetSequenceSteps(s.Id)))
            {
                if (!string.IsNullOrWhiteSpace(step.SpeakerBinding) &&
                    step.SpeakerBinding != "Giver" && step.SpeakerBinding != "SelectedHero")
                {
                    lines.Add($"- [ ] Sequence unit binding: {step.SpeakerBinding}");
                }
                if (!string.IsNullOrWhiteSpace(step.TargetBinding) &&
                    step.TargetBinding != "Giver" && step.TargetBinding != "SelectedHero")
                {
                    lines.Add($"- [ ] Sequence target binding: {step.TargetBinding}");
                }
            }
            lines.Add("");
            lines.Add("Authored dependencies");
            if (dependencies.Count == 0)
            {
                lines.Add("- None recorded.");
            }
            foreach (var dependency in dependencies)
            {
                string state = dependency.Verified ? "x" : " ";
                lines.Add($"- [{state}] {dependency.DependencyKind}: {dependency.Symbol} {dependency.ExpectedValue}".TrimEnd());
                if (!string.IsNullOrWhiteSpace(dependency.ManualFollowUp))
                {
                    lines.Add($"      Follow-up: {dependency.ManualFollowUp}");
                }
                if (!string.IsNullOrWhiteSpace(dependency.SourceEvidence))
                {
                    lines.Add($"      Evidence: {dependency.SourceEvidence}");
                }
            }
            lines.Add("");
            lines.Add("_MISC/war3map.wts is supporting evidence only and must not be edited.");
            return string.Join(Environment.NewLine, lines);
        }

        private void WriteValidationReport(
            string outputFolder,
            QuestGiverDefinition giver,
            string timestamp,
            ValidationReport validation,
            QuestLibraryExportResult result)
        {
            string path = Path.Combine(outputFolder, $"{GetLibraryName(giver)}_{timestamp}.validation.txt");
            File.WriteAllText(path, validation.Format(giver), new UTF8Encoding(false));
            result.FilesExported.Add(path);
        }

        private static string GetLibraryName(QuestGiverDefinition giver)
        {
            return giver.LibraryName.StartsWith("q", StringComparison.Ordinal)
                ? giver.LibraryName
                : "q" + giver.LibraryName;
        }

        private static string Escape(string value)
        {
            return (value ?? "")
                .Replace("\\", "\\\\")
                .Replace("\"", "\\\"")
                .Replace("\r\n", "\\n")
                .Replace("\n", "\\n")
                .Replace("\r", "\\n");
        }

        private static string Bool(bool value) => value ? "true" : "false";

        private static string ComputeFingerprint(string generatedLibrary)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(generatedLibrary);
            return Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
        }

        private static string Real(decimal value)
        {
            return value.ToString("0.00", CultureInfo.InvariantCulture);
        }

        private sealed class ValidationReport
        {
            public List<string> Warnings { get; } = new List<string>();
            public List<string> Errors { get; } = new List<string>();

            public string Format(QuestGiverDefinition giver)
            {
                var sb = new StringBuilder();
                sb.AppendLine($"WC3 Manager quest export validation: {giver.DisplayName}");
                sb.AppendLine($"Ownership: {giver.OwnershipMode}");
                sb.AppendLine($"Errors: {Errors.Count}; warnings: {Warnings.Count}");
                sb.AppendLine();
                sb.AppendLine("Errors");
                if (Errors.Count == 0) sb.AppendLine("- None");
                foreach (string error in Errors) sb.AppendLine("- " + error);
                sb.AppendLine();
                sb.AppendLine("Warnings");
                if (Warnings.Count == 0) sb.AppendLine("- None");
                foreach (string warning in Warnings) sb.AppendLine("- " + warning);
                return sb.ToString();
            }
        }

        // The methods below keep generated function order compatible with JASS.
        private void AppendGeneratedHooks(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IEnumerable<QuestDefinition> quests,
            IEnumerable<QuestSequenceDefinition> sequences)
        {
            var hookNames = sequences
                .SelectMany(s => new[] { s.OnStartHook, s.OnFinishHook })
                .Concat(sequences.SelectMany(s => _repository.GetSequenceSteps(s.Id)).Select(s => s.ActionHook))
                .Concat(quests.SelectMany(q => _repository.GetObjectives(q.Id)).Select(o => o.ExternalHook))
                .Where(h => !string.IsNullOrWhiteSpace(h))
                .Distinct()
                .OrderBy(h => h);
            foreach (string hookName in hookNames)
            {
                string safeName = "GeneratedHook_" + hookName;
                sb.AppendLine($"private function {safeName} takes nothing returns nothing");
                sb.AppendLine($"    // GENERATED-HOOK: implement or bridge {hookName} before release.");
                sb.AppendLine("endfunction");
                sb.AppendLine();
            }
        }

        private void AppendSequenceHandlers(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests,
            IReadOnlyDictionary<int, QuestVoicelineDefinition> voicelines)
        {
            foreach (var sequence in sequences.Where(s => s.Purpose != "greet"))
            {
                string id = sequence.SequenceKey;
                QuestDefinition quest = sequence.QuestId.HasValue && allQuests.ContainsKey(sequence.QuestId.Value)
                    ? allQuests[sequence.QuestId.Value]
                    : null;
                string questName = quest == null
                    ? "\"\""
                    : GetQuestNameExpression(quest, giver);
                string questGiver = quest == null
                    ? "Giver"
                    : GetQuestGiverExpression(quest, giver, allGivers);
                sb.AppendLine($"private function Finish_{id} takes nothing returns nothing");
                if (quest != null && sequence.Purpose == "accept")
                {
                    sb.AppendLine($"    call QuestGiver_AcceptQuestByNameAndGiver({questName}, {questGiver})");
                }
                else if (quest != null && sequence.Purpose == "complete")
                {
                    sb.AppendLine($"    call QuestGiver_CompleteQuestByNameAndGiver({questName}, {questGiver})");
                }
                else if (quest != null && sequence.Purpose == "fail")
                {
                    sb.AppendLine($"    call QuestGiver_AcceptQuestByNameAndGiver({questName}, {questGiver})");
                }
                if (!string.IsNullOrWhiteSpace(sequence.OnFinishHook))
                {
                    sb.AppendLine($"    call GeneratedHook_{sequence.OnFinishHook}()");
                }
                sb.AppendLine("    call StartExitFadeOut()");
                sb.AppendLine("endfunction");
                sb.AppendLine();
                sb.AppendLine($"private function Play_{id} takes nothing returns nothing");
                sb.AppendLine("    local integer seq");
                sb.AppendLine("    local integer stepIndex");
                sb.AppendLine("    call DialogInteraction_BeginDialogSequence()");
                sb.AppendLine("    set seq = DialogInteraction_CreateBaseSequence(Giver, GIVER_NAME)");
                sb.AppendLine($"    call DialogSystem_SetSequenceSkippable(seq, {Bool(sequence.Skippable)})");
                AppendSequenceSteps(sb, _repository.GetSequenceSteps(sequence.Id), voicelines);
                string onStart = string.IsNullOrWhiteSpace(sequence.OnStartHook)
                    ? "null"
                    : $"function GeneratedHook_{sequence.OnStartHook}";
                sb.AppendLine($"    call DialogSystem_SetSequenceCallbacks(seq, {onStart}, function Finish_{id})");
                sb.AppendLine("    call DialogSystem_PlaySequence(seq, Player(0), Giver)");
                sb.AppendLine("endfunction");
                sb.AppendLine();
            }
        }

        private static void AppendSequenceSteps(
            StringBuilder sb,
            IEnumerable<QuestSequenceStepDefinition> steps,
            IReadOnlyDictionary<int, QuestVoicelineDefinition> voicelines)
        {
            foreach (var step in steps.OrderBy(s => s.DisplayOrder))
            {
                string speaker = string.IsNullOrWhiteSpace(step.SpeakerBinding) ? "Giver" : step.SpeakerBinding;
                string target = string.IsNullOrWhiteSpace(step.TargetBinding) ? "Giver" : step.TargetBinding;
                string speakerName = string.IsNullOrWhiteSpace(step.SpeakerName)
                    ? (speaker == "Giver" ? "GIVER_NAME" : $"GetUnitName({speaker})")
                    : $"\"{Escape(step.SpeakerName)}\"";
                string text = $"\"{Escape(step.Text)}\"";
                string sound = $"\"{Escape(step.SoundKey)}\"";
                if (step.VoicelineId.HasValue && voicelines.TryGetValue(step.VoicelineId.Value, out var voice))
                {
                    if (!string.IsNullOrWhiteSpace(voice.ConstantName) && JassIdentifier.IsMatch(voice.ConstantName))
                    {
                        sound = voice.ConstantName;
                        string textConstant = voice.ConstantName.EndsWith("_KEY", StringComparison.Ordinal)
                            ? voice.ConstantName.Substring(0, voice.ConstantName.Length - 4) + "_TEXT"
                            : "";
                        if (JassIdentifier.IsMatch(textConstant))
                        {
                            text = textConstant;
                        }
                    }
                    else
                    {
                        text = $"\"{Escape(voice.Text)}\"";
                        sound = $"\"{Escape(voice.LineKey)}\"";
                    }
                }

                switch (step.StepType)
                {
                    case "line":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddLine(seq, {speaker}, {speakerName}, {text}, {sound}, {Bool(step.SoundAtUnit)})");
                        break;
                    case "delay":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddDelay(seq, {Real(step.Duration)})");
                        break;
                    case "face_unit":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddMakeUnitFaceUnit(seq, {speaker}, {target}, {Real(step.Duration)}, 0.00)");
                        break;
                    case "face_point":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddMakeUnitFacePoint(seq, {speaker}, {Real(step.PointX ?? 0m)}, {Real(step.PointY ?? 0m)}, {Real(step.Duration)}, 0.00)");
                        break;
                    case "look_unit":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddLookAtUnit(seq, {speaker}, {target}, {Real(step.Duration)})");
                        break;
                    case "look_point":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddLookAtPoint(seq, {speaker}, {Real(step.PointX ?? 0m)}, {Real(step.PointY ?? 0m)}, {Real(step.Duration)})");
                        break;
                    case "reset_look":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddResetLookAt(seq, {speaker}, {Real(step.Duration)})");
                        break;
                    case "fade_out":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddFadeOut(seq, {Real(step.Duration)})");
                        break;
                    case "fade_in":
                        sb.AppendLine($"    set stepIndex = DialogSystem_AddFadeIn(seq, {Real(step.Duration)})");
                        break;
                    case "action":
                        sb.AppendLine("    set stepIndex = DialogSystem_AddDelay(seq, 0.01)");
                        sb.AppendLine($"    call DialogSystem_BindLineAction(seq, stepIndex, function GeneratedHook_{step.ActionHook})");
                        break;
                }
            }
        }

        private static void AppendDefaultQuestHandlers(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences)
        {
            foreach (var quest in quests)
            {
                bool hasAccept = sequences.Any(s => s.QuestId == quest.Id && s.Purpose == "accept");
                bool hasComplete = sequences.Any(s => s.QuestId == quest.Id && s.Purpose == "complete");
                bool hasFail = sequences.Any(s => s.QuestId == quest.Id && s.Purpose == "fail");
                string id = quest.QuestKey;
                if (!hasAccept)
                {
                    sb.AppendLine($"private function OnAccept_{id} takes nothing returns nothing");
                    sb.AppendLine($"    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_{id.ToUpperInvariant()}, Giver)");
                    sb.AppendLine("    call StartExitFadeOut()");
                    sb.AppendLine("endfunction");
                    sb.AppendLine();
                }
                if (!hasComplete)
                {
                    sb.AppendLine($"private function OnComplete_{id} takes nothing returns nothing");
                    sb.AppendLine($"    call QuestGiver_CompleteQuestByNameAndGiver(QUEST_{id.ToUpperInvariant()}, Giver)");
                    sb.AppendLine("    call StartExitFadeOut()");
                    sb.AppendLine("endfunction");
                    sb.AppendLine();
                }
                if (!hasFail)
                {
                    sb.AppendLine($"private function OnRetry_{id} takes nothing returns nothing");
                    sb.AppendLine($"    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_{id.ToUpperInvariant()}, Giver)");
                    sb.AppendLine("    call StartExitFadeOut()");
                    sb.AppendLine("endfunction");
                    sb.AppendLine();
                }
            }
        }

        private static void AppendInboundQuestHandlers(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests)
        {
            foreach (var quest in GetInboundQuests(giver, allQuests))
            {
                if (sequences.Any(s => s.QuestId == quest.Id && s.Purpose == "complete"))
                {
                    continue;
                }
                string sourceGiver = GetQuestGiverExpression(quest, giver, allGivers);
                string handlerName = GetInboundHandlerName(quest, allGivers);
                sb.AppendLine($"private function {handlerName} takes nothing returns nothing");
                sb.AppendLine($"    call QuestGiver_CompleteQuestByNameAndGiver(\"{Escape(quest.QuestName)}\", {sourceGiver})");
                sb.AppendLine("    call StartExitFadeOut()");
                sb.AppendLine("endfunction");
                sb.AppendLine();
            }
        }

        private static void AppendFarewellHandler(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestSequenceDefinition> sequences)
        {
            if (sequences.Any(s => s.Purpose == "farewell"))
            {
                return;
            }
            sb.AppendLine("private function OnFarewell takes nothing returns nothing");
            sb.AppendLine("    call StartExitFadeOut()");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private static void AppendBuildDialog(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests)
        {
            sb.AppendLine("private function BuildDialog takes nothing returns nothing");
            sb.AppendLine("    local button b = null");
            sb.AppendLine("    if GiverDialog == null then");
            sb.AppendLine("        set GiverDialog = DialogSystem_CreateDialog(GIVER_NAME)");
            sb.AppendLine("    endif");
            sb.AppendLine("    call QuestGiver_RefreshAvailabilityForGiver(Giver)");
            sb.AppendLine("    call DialogSystem_ClearDialog(GiverDialog)");
            sb.AppendLine("    call DialogSystem_SetTitle(GiverDialog, GIVER_NAME)");
            int actionId = 1;
            foreach (var quest in quests)
            {
                var acceptSequence = sequences.FirstOrDefault(s => s.QuestId == quest.Id && s.Purpose == "accept");
                var completeSequence = sequences.FirstOrDefault(s => s.QuestId == quest.Id && s.Purpose == "complete");
                var failSequence = sequences.FirstOrDefault(s => s.QuestId == quest.Id && s.Purpose == "fail");
                string acceptHandler = acceptSequence == null ? $"OnAccept_{quest.QuestKey}" : $"Play_{acceptSequence.SequenceKey}";
                string completeHandler = completeSequence == null ? $"OnComplete_{quest.QuestKey}" : $"Play_{completeSequence.SequenceKey}";
                string failHandler = failSequence == null ? $"OnRetry_{quest.QuestKey}" : $"Play_{failSequence.SequenceKey}";
                sb.AppendLine($"    call QuestGiver_AddAvailableQuestAcceptButton(GiverDialog, QUEST_{quest.QuestKey.ToUpperInvariant()}, Giver, {actionId++}, function {acceptHandler}, true, true)");
                if (!quest.ReceiverGiverId.HasValue || quest.ReceiverGiverId.Value == giver.Id)
                {
                    sb.AppendLine($"    call QuestGiver_AddReadyQuestCompleteButton(GiverDialog, QUEST_{quest.QuestKey.ToUpperInvariant()}, Giver, {actionId++}, function {completeHandler}, true)");
                }
                sb.AppendLine($"    call QuestGiver_AddFailedQuestButton(GiverDialog, QUEST_{quest.QuestKey.ToUpperInvariant()}, Giver, {actionId++}, function {failHandler})");
            }
            foreach (var quest in GetInboundQuests(giver, allQuests))
            {
                var completeSequence = sequences.FirstOrDefault(s => s.QuestId == quest.Id && s.Purpose == "complete");
                string completeHandler = completeSequence == null
                    ? GetInboundHandlerName(quest, allGivers)
                    : $"Play_{completeSequence.SequenceKey}";
                string sourceGiver = GetQuestGiverExpression(quest, giver, allGivers);
                sb.AppendLine($"    call QuestGiver_AddReadyQuestCompleteButton(GiverDialog, \"{Escape(quest.QuestName)}\", {sourceGiver}, {actionId++}, function {completeHandler}, true)");
            }
            foreach (var sequence in sequences
                         .Where(s => s.ShowAsDialogOption && s.Purpose != "greet" && s.Purpose != "farewell")
                         .OrderBy(s => s.ButtonOrder)
                         .ThenBy(s => s.DisplayName))
            {
                string label = string.IsNullOrWhiteSpace(sequence.ButtonLabel) ? sequence.DisplayName : sequence.ButtonLabel;
                sb.AppendLine($"    set b = DialogSystem_AddButton(GiverDialog, \"{Escape(label)}\", {actionId++})");
                sb.AppendLine($"    call DialogSystem_BindButtonCode(b, function Play_{sequence.SequenceKey})");
                sb.AppendLine("    set b = null");
            }
            var farewell = sequences.FirstOrDefault(s => s.Purpose == "farewell");
            sb.AppendLine("    set b = DialogSystem_AddFarewellButton(GiverDialog)");
            sb.AppendLine($"    call DialogSystem_BindButtonCode(b, function {(farewell == null ? "OnFarewell" : "Play_" + farewell.SequenceKey)})");
            sb.AppendLine("    set b = null");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private static IEnumerable<QuestDefinition> GetInboundQuests(
            QuestGiverDefinition giver,
            IReadOnlyDictionary<int, QuestDefinition> allQuests)
        {
            return allQuests.Values
                .Where(q => q.Enabled && !q.Draft && q.ReceiverGiverId == giver.Id && q.QuestGiverId != giver.Id)
                .OrderBy(q => q.SortOrder)
                .ThenBy(q => q.Title);
        }

        private static string GetQuestNameExpression(QuestDefinition quest, QuestGiverDefinition currentGiver)
        {
            return quest.QuestGiverId == currentGiver.Id
                ? $"QUEST_{quest.QuestKey.ToUpperInvariant()}"
                : $"\"{Escape(quest.QuestName)}\"";
        }

        private static string GetQuestGiverExpression(
            QuestDefinition quest,
            QuestGiverDefinition currentGiver,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers)
        {
            if (quest.QuestGiverId == currentGiver.Id)
            {
                return "Giver";
            }
            return allGivers.TryGetValue(quest.QuestGiverId, out var sourceGiver)
                ? sourceGiver.PlacedUnitVariable
                : "null";
        }

        private static string GetInboundHandlerName(
            QuestDefinition quest,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers)
        {
            string sourceKey = allGivers.TryGetValue(quest.QuestGiverId, out var sourceGiver)
                ? sourceGiver.GiverKey
                : "MissingGiver";
            return $"OnCompleteInbound_{sourceKey}_{quest.QuestKey}";
        }

        private void AppendDialogEntry(
            StringBuilder sb,
            QuestGiverDefinition giver,
            string libraryName,
            IReadOnlyList<QuestSequenceDefinition> sequences,
            IReadOnlyDictionary<int, QuestVoicelineDefinition> voicelines)
        {
            var greet = sequences.FirstOrDefault(s => s.Purpose == "greet");
            sb.AppendLine("private function PlayDialogGreeting takes unit hero returns nothing");
            sb.AppendLine("    local integer seq = DialogInteraction_CreateGreetSequenceBase(Giver, GIVER_NAME, hero, 1.00, 1.00, true)");
            sb.AppendLine("    local integer stepIndex");
            if (greet != null)
            {
                AppendSequenceSteps(sb, _repository.GetSequenceSteps(greet.Id), voicelines);
            }
            sb.AppendLine("    call DialogInteraction_PlayGreetSequenceEx(seq, Giver, Player(0), GiverDialog, CINEMATIC)");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("private function ContinueToDialogInternal takes nothing returns nothing");
            sb.AppendLine("    local unit hero = null");
            sb.AppendLine("    call SyncUnitReferences()");
            sb.AppendLine("    if not DialogInteraction_IsUnitAlive(Giver) then");
            sb.AppendLine("        call StartExitFadeOut()");
            sb.AppendLine("        set hero = null");
            sb.AppendLine("        return");
            sb.AppendLine("    endif");
            sb.AppendLine("    set hero = DialogInteraction_ResolveDialogHero(SelectedHero, Giver, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)");
            sb.AppendLine("    if hero == null then");
            sb.AppendLine("        call StartExitFadeOut()");
            sb.AppendLine("        set hero = null");
            sb.AppendLine("        return");
            sb.AppendLine("    endif");
            sb.AppendLine("    call BuildDialog()");
            sb.AppendLine("    call PlayDialogGreeting(hero)");
            sb.AppendLine("    set hero = null");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("public function ContinueToDialogAfterSelection takes nothing returns nothing");
            sb.AppendLine("    call ContinueToDialogInternal()");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("private function OnSelected takes nothing returns nothing");
            sb.AppendLine("    call SyncUnitReferences()");
            sb.AppendLine("    if not DialogInteraction_IsUnitAlive(Giver) then");
            sb.AppendLine("        return");
            sb.AppendLine("    endif");
            sb.AppendLine("    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Giver, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)");
            sb.AppendLine("    if not DialogInteraction_PassDialogSelectionGate(Giver, SelectedHero, DIALOG_RANGE, DialogCooldown, true, true, true, true, false, false) then");
            sb.AppendLine("        set SelectedHero = null");
            sb.AppendLine("        return");
            sb.AppendLine("    endif");
            sb.AppendLine($"    call DialogInteraction_StartConfiguredDialogEntryTransition(Giver, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, \"{libraryName}_ContinueToDialogAfterSelection\")");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private void AppendCreateQuests(
            StringBuilder sb,
            QuestGiverDefinition giver,
            IReadOnlyList<QuestDefinition> quests,
            IReadOnlyDictionary<int, QuestGiverDefinition> allGivers,
            IReadOnlyDictionary<int, QuestDefinition> allQuests)
        {
            sb.AppendLine("private function CreateQuests takes nothing returns nothing");
            sb.AppendLine("    local QuestData q");
            foreach (var quest in quests)
            {
                var objectives = _repository.GetObjectives(quest.Id).OrderBy(o => o.DisplayOrder).ToList();
                var reward = _repository.GetReward(quest.Id);
                string receiverExpression = "null";
                string receiverDisplayName = quest.ReceiverDisplayName;
                if (quest.ReceiverGiverId.HasValue && quest.ReceiverGiverId.Value != giver.Id &&
                    allGivers.TryGetValue(quest.ReceiverGiverId.Value, out var receiverGiver))
                {
                    receiverExpression = receiverGiver.PlacedUnitVariable;
                    if (string.IsNullOrWhiteSpace(receiverDisplayName))
                    {
                        receiverDisplayName = receiverGiver.DisplayName;
                    }
                }
                else if (string.IsNullOrWhiteSpace(receiverDisplayName))
                {
                    receiverDisplayName = giver.DisplayName;
                }
                sb.AppendLine($"    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_{quest.QuestKey.ToUpperInvariant()}, Giver) then");
                sb.AppendLine($"        set q = QuestGiver_CreateConfiguredQuest(QUEST_{quest.QuestKey.ToUpperInvariant()}, Giver, \"{quest.QuestType}\", {quest.QuestLevel}, {receiverExpression}, \"{Escape(quest.Title)}\", \"{Escape(quest.IconPath)}\", \"{Escape(quest.Description)}\", \"{Escape(quest.InfoText)}\", \"{Escape(quest.Info2Text)}\", {quest.RequiredLevel}, true, {Bool(quest.AllowNazgrek)}, {Bool(quest.AllowZulkis)}, \"{Escape(quest.Faction)}\", \"{Escape(receiverDisplayName)}\")");
                sb.AppendLine($"        call QuestGiver_SetQuestRequiredReputation(q, {quest.RequiredReputation})");
                sb.AppendLine($"        call QuestGiver_SetQuestRewards(q, {Bool(reward.XpActive)}, {reward.XpAdjust}, {Bool(reward.GoldActive)}, {reward.GoldAdjust}, {Bool(reward.ArenaActive)}, {reward.ArenaAdjust}, {Bool(reward.ReputationActive)}, {reward.ReputationAdjust}, {Bool(reward.ReputationLinked)})");
                if (quest.Category != "general")
                {
                    sb.AppendLine($"        call QuestGiver_SetQuestCategory(q, \"{quest.Category}\")");
                }
                if (!string.IsNullOrWhiteSpace(reward.ItemCode))
                {
                    sb.AppendLine($"        call q.setRewardItemType('{reward.ItemCode}')");
                }
                if (quest.AutoComplete)
                {
                    sb.AppendLine("        call q.setAutoComplete(true)");
                }
                var requirementTexts = Enumerable.Range(1, 8)
                    .Select(index => objectives.FirstOrDefault(o => o.DisplayOrder == index)?.Text ?? "")
                    .Select(text => $"\"{Escape(text)}\"");
                sb.AppendLine($"        call QuestGiver_SetRequirements(q.id, \"\", {string.Join(", ", requirementTexts)})");
                foreach (var objective in objectives)
                {
                    AppendObjectiveRegistration(sb, objective);
                }
                foreach (int prerequisiteId in _repository.GetPrerequisiteIds(quest.Id))
                {
                    if (!allQuests.TryGetValue(prerequisiteId, out var prerequisite)) continue;
                    string prerequisiteGiver = "Giver";
                    if (prerequisite.QuestGiverId != giver.Id && allGivers.TryGetValue(prerequisite.QuestGiverId, out var otherGiver))
                    {
                        prerequisiteGiver = otherGiver.PlacedUnitVariable;
                    }
                    sb.AppendLine($"        call QuestGiver_AddQuestPrerequisite(q, \"{Escape(prerequisite.QuestName)}\", {prerequisiteGiver})");
                }
                if (quest.RequiresTurnIn && !quest.AutoComplete)
                {
                    sb.AppendLine("        call q.addReturnRequirement()");
                }
                sb.AppendLine("    endif");
                sb.AppendLine();
            }
            sb.AppendLine("    set q = 0");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }

        private static void AppendObjectiveRegistration(StringBuilder sb, QuestObjectiveDefinition objective)
        {
            string prefix = "        ";
            if (objective.CompletionMode != "automatic")
            {
                sb.AppendLine($"{prefix}// GENERATED-HOOK: {objective.ExternalHook} owns completion of objective {objective.DisplayOrder}.");
                return;
            }
            switch (objective.ObjectiveType)
            {
                case "item":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterItemRequirement(q.id, Giver, {objective.DisplayOrder}, '{objective.ItemCode}', {objective.Amount})");
                    break;
                case "kill":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterUnitKillRequirement(q.id, Giver, {objective.DisplayOrder}, '{objective.UnitCode}', {objective.Amount})");
                    break;
                case "escort":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterEscortRequirement(q.id, Giver, {objective.DisplayOrder}, {objective.TargetVariable}, {objective.RegionVariable}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "talk":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterTalkToRequirement(q.id, Giver, {objective.DisplayOrder}, {objective.TargetVariable}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "find":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterFindNPCRequirement(q.id, Giver, {objective.DisplayOrder}, {objective.TargetVariable}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "goto":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterGoToPlaceRequirement(q.id, Giver, {objective.DisplayOrder}, {objective.RegionVariable}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "reputation":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterReputationRequirement(q.id, Giver, {objective.DisplayOrder}, \"{Escape(objective.Faction)}\", {objective.RequiredReputation}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "investigate":
                    sb.AppendLine($"{prefix}call QuestGiver_RegisterInvestigateRequirement(q.id, Giver, {objective.DisplayOrder}, \"{Escape(objective.TargetName)}\")");
                    break;
                case "manual":
                    sb.AppendLine($"{prefix}// GENERATED-HOOK: {objective.ExternalHook} completes objective {objective.DisplayOrder}.");
                    break;
            }
        }

        private static void AppendInitialization(StringBuilder sb, QuestGiverDefinition giver, string libraryName)
        {
            sb.AppendLine("private function InitDelayed takes nothing returns nothing");
            sb.AppendLine("    call SyncUnitReferences()");
            sb.AppendLine("    if Giver == null then");
            sb.AppendLine("        call TimerStart(InitTimer, 0.50, false, function InitDelayed)");
            sb.AppendLine("        return");
            sb.AppendLine("    endif");
            sb.AppendLine("    call PauseTimer(InitTimer)");
            sb.AppendLine("    call DestroyTimer(InitTimer)");
            sb.AppendLine("    set InitTimer = null");
            sb.AppendLine("    call QuestGiver_Register(Giver)");
            sb.AppendLine($"    call DialogInteraction_ConfigureDialogTransition(Giver, 0, 0.00, 0.00, {Real(giver.CameraDistance)}, {Real(giver.CameraZOffset)}, {Real(giver.CameraAngle)}, {Real(giver.CameraRotationOffset)}, {Real(giver.CameraFarZ)}, {Real(giver.CameraFov)}, {Real(giver.CameraBlockRadius)}, {Bool(giver.CameraBlockCheck)})");
            sb.AppendLine("    call CreateQuests()");
            sb.AppendLine("    call DialogInteraction_RegisterSelectionHandler(Giver, function OnSelected)");
            sb.AppendLine("    call QuestGiver_RefreshAvailabilityForGiver(Giver)");
            sb.AppendLine("    call DebugMsg(\"Initialized.\")");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("private function Init takes nothing returns nothing");
            sb.AppendLine("    set DialogCooldown = CreateTimer()");
            sb.AppendLine("    set InitTimer = CreateTimer()");
            sb.AppendLine("    call TimerStart(InitTimer, 0.00, false, function InitDelayed)");
            sb.AppendLine("endfunction");
            sb.AppendLine();
            sb.AppendLine("public function RefreshAvailability takes nothing returns nothing");
            sb.AppendLine("    call SyncUnitReferences()");
            sb.AppendLine("    if Giver != null then");
            sb.AppendLine("        call QuestGiver_RefreshAvailabilityForGiver(Giver)");
            sb.AppendLine("    endif");
            sb.AppendLine("endfunction");
            sb.AppendLine();
        }
    }
}
