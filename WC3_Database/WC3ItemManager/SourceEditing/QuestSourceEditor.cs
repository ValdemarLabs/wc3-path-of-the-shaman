using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using WC3ItemManager.Importers;
using WC3ItemManager.Models;

namespace WC3ItemManager.SourceEditing
{
    /// <summary>
    /// Produces narrow, conflict-checked edits for recognized qXXX metadata calls.
    /// It never regenerates a hand-owned source file or changes an unmapped expression.
    /// </summary>
    public sealed class QuestSourceEditor
    {
        private const string SourceOnlyReason =
            "This field contains custom logic, a shared expression, or no unique source mapping. Edit it in the repository .j file.";

        private static readonly string[] QuestCallNames =
        {
            "QuestGiver_CreateConfiguredQuest",
            "QuestGiver_SetQuestCategory",
            "QuestGiver_SetQuestRewards",
            "QuestGiver_SetRequirements",
            "QuestGiver_SetQuestRequiredReputation",
            "QuestGiver_SetRequiredReputation"
        };

        public QuestSourceEditSession Analyze(QuestGiverDefinition giver, QuestDefinition quest,
            IReadOnlyList<QuestObjectiveDefinition> objectives)
        {
            if (giver == null) throw new ArgumentNullException(nameof(giver));
            string path = ResolveSourcePath(giver.SourceFile);
            SourceDocument document = SourceDocument.Load(path);
            var session = new QuestSourceEditSession
            {
                FullPath = path,
                RelativePath = giver.SourceFile ?? "",
                Fingerprint = document.Fingerprint,
                FingerprintMatchesDatabase = string.Equals(
                    giver.SourceImportFingerprint, document.Fingerprint, StringComparison.OrdinalIgnoreCase),
                DefaultReadOnlyReason = SourceOnlyReason,
                SourceText = document.Text,
                SourceMaskedText = document.MaskedText,
                SourceNewLine = document.NewLine
            };

            AddGiverMappings(session, giver, document);
            SourceCall firstQuestCall = document.Calls
                .FirstOrDefault(call => call.Name == "QuestGiver_CreateConfiguredQuest" && call.Arguments.Count >= 2);
            if (firstQuestCall != null)
            {
                session.SuggestedQuestVariable = string.IsNullOrWhiteSpace(firstQuestCall.AssignmentTarget)
                    ? "q" : firstQuestCall.AssignmentTarget;
                string giverExpression = firstQuestCall.Arguments[1].Text.Trim();
                session.SuggestedGiverExpression = Regex.IsMatch(giverExpression,
                    @"^(?:null|[A-Za-z][A-Za-z0-9_]*)$") ? giverExpression : "null";
            }
            if (quest != null)
            {
                AddQuestMappings(session, quest, objectives ?? Array.Empty<QuestObjectiveDefinition>(), document);
            }
            FindManagedRegions(session, document);
            return session;
        }

        internal static void RunMarkerContractSelfTest()
        {
            const string source =
                "library qSourceEditAudit requires QuestGiver\n" +
                "globals\n" +
                "    // WC3M-BEGIN QUEST CONSTANTS\n" +
                "    // WC3M-END QUEST CONSTANTS\n" +
                "endglobals\n" +
                "private function CreateQuests takes nothing returns nothing\n" +
                "    local QuestData q\n" +
                "    // WC3M-BEGIN QUESTS variable=q giver=AuditGiver receiver=null\n" +
                "    // WC3M-END QUESTS\n" +
                "endfunction\n" +
                "endlibrary\n";
            SourceDocument document = SourceDocument.Parse("qSourceEditAudit.j", source, false);
            var session = new QuestSourceEditSession();
            FindManagedRegions(session, document);
            if (!session.CanAddQuest)
                throw new InvalidOperationException("The valid QuestData marker contract was rejected: " + session.AddQuestReason);
        }

        public SourcePatchPreview PrepareGiverPatch(QuestGiverDefinition giver,
            QuestGiverDefinition baseline, QuestGiverDefinition proposed)
        {
            QuestSourceEditSession session = Analyze(giver, null, Array.Empty<QuestObjectiveDefinition>());
            var preview = CreatePreview(session);
            AddModelChanges(preview, session.GiverFields, baseline, proposed, "Quest giver");
            FinalizePreview(preview);
            return preview;
        }

        public SourcePatchPreview PrepareQuestPatch(QuestGiverDefinition giver,
            QuestDefinition baselineQuest, QuestDefinition proposedQuest,
            QuestRewardDefinition baselineReward, QuestRewardDefinition proposedReward,
            IReadOnlyList<QuestObjectiveDefinition> baselineObjectives,
            IReadOnlyList<QuestObjectiveDefinition> proposedObjectives)
        {
            QuestSourceEditSession session = Analyze(giver, baselineQuest, baselineObjectives);
            var preview = CreatePreview(session);
            AddModelChanges(preview, session.QuestFields, baselineQuest, proposedQuest, "Quest");
            AddModelChanges(preview, session.RewardFields, baselineReward, proposedReward, "Reward");

            var proposedById = (proposedObjectives ?? Array.Empty<QuestObjectiveDefinition>())
                .Where(objective => objective.Id > 0)
                .ToDictionary(objective => objective.Id);
            foreach (QuestObjectiveDefinition baseline in baselineObjectives ?? Array.Empty<QuestObjectiveDefinition>())
            {
                if (!proposedById.TryGetValue(baseline.Id, out QuestObjectiveDefinition proposed))
                {
                    preview.Conflicts.Add($"Objective {baseline.DisplayOrder + 1}: source-backed objectives cannot be deleted from WC3 Manager.");
                    continue;
                }
                session.ObjectiveFields.TryGetValue(baseline.Id,
                    out IReadOnlyDictionary<string, SourceFieldAccess> fields);
                AddModelChanges(preview, fields, baseline, proposed,
                    $"Objective {baseline.DisplayOrder + 1}");
            }
            if ((proposedObjectives?.Count ?? 0) > (baselineObjectives?.Count ?? 0))
            {
                preview.Conflicts.Add("Existing synchronized quests cannot add objective calls unless they are inside a WC3 Manager-owned source region.");
            }

            FinalizePreview(preview);
            return preview;
        }

        public SourcePatchPreview PrepareNewQuestPatch(QuestGiverDefinition giver, QuestDefinition quest,
            QuestRewardDefinition reward, IReadOnlyList<QuestObjectiveDefinition> objectives)
        {
            QuestSourceEditSession session = Analyze(giver, null, Array.Empty<QuestObjectiveDefinition>());
            var preview = CreatePreview(session);
            if (!session.CanAddQuest)
            {
                preview.Conflicts.Add(session.AddQuestReason);
                return preview;
            }

            string key = FitIdentifier(quest.QuestKey, 48).ToUpperInvariant();
            string symbol = "WC3M_QUEST_" + key;
            if (Regex.IsMatch(session.SourceMaskedText, $@"\b{Regex.Escape(symbol)}\b"))
            {
                preview.Conflicts.Add($"The source already contains '{symbol}'. Choose a different stable key.");
                return preview;
            }

            SourceManagedRegion constants = session.ConstantsRegion;
            SourceManagedRegion registrations = session.QuestRegion;
            string newLine = session.SourceNewLine;
            string constantIndent = constants.Indent;
            string callIndent = registrations.Indent + "    ";
            string constantText = $"{constantIndent}private constant string {symbol} = {FormatString(quest.QuestName)}{newLine}";
            string giverExpression = registrations.Options.TryGetValue("giver", out string giverValue)
                ? giverValue : "null";
            string receiverExpression = registrations.Options.TryGetValue("receiver", out string receiverValue)
                ? receiverValue : "null";
            string variable = registrations.Options.TryGetValue("variable", out string variableValue)
                ? variableValue : "q";
            string receiverName = quest.ReceiverDisplayName ?? giver.DisplayName ?? "";

            var registration = new StringBuilder();
            registration.Append(callIndent).Append("set ").Append(variable)
                .Append(" = QuestGiver_CreateConfiguredQuest(").Append(symbol).Append(", ")
                .Append(giverExpression).Append(", ").Append(FormatString(quest.QuestType)).Append(", ")
                .Append(quest.QuestLevel.ToString(CultureInfo.InvariantCulture)).Append(", ")
                .Append(receiverExpression).Append(", ").Append(FormatString(quest.Title)).Append(", ")
                .Append(FormatString(quest.IconPath)).Append(", ").Append(FormatString(quest.Description)).Append(", ")
                .Append(FormatString(quest.InfoText)).Append(", ").Append(FormatString(quest.Info2Text)).Append(", ")
                .Append(quest.RequiredLevel.ToString(CultureInfo.InvariantCulture)).Append(", true, ")
                .Append(FormatBool(quest.AllowNazgrek)).Append(", ").Append(FormatBool(quest.AllowZulkis)).Append(", ")
                .Append(FormatString(quest.Faction)).Append(", ").Append(FormatString(receiverName)).Append(')')
                .Append(newLine);
            if (quest.RequiredReputation != 0)
            {
                registration.Append(callIndent).Append("call QuestGiver_SetQuestRequiredReputation(")
                    .Append(variable).Append(", ").Append(quest.RequiredReputation.ToString(CultureInfo.InvariantCulture))
                    .Append(')').Append(newLine);
            }
            QuestRewardDefinition safeReward = reward ?? new QuestRewardDefinition();
            registration.Append(callIndent).Append("call QuestGiver_SetQuestRewards(").Append(variable).Append(", ")
                .Append(FormatBool(safeReward.XpActive)).Append(", ").Append(safeReward.XpAdjust).Append(", ")
                .Append(FormatBool(safeReward.GoldActive)).Append(", ").Append(safeReward.GoldAdjust).Append(", ")
                .Append(FormatBool(safeReward.ArenaActive)).Append(", ").Append(safeReward.ArenaAdjust).Append(", ")
                .Append(FormatBool(safeReward.ReputationActive)).Append(", ").Append(safeReward.ReputationAdjust).Append(", ")
                .Append(FormatBool(safeReward.ReputationLinked)).Append(')').Append(newLine);
            registration.Append(callIndent).Append("call QuestGiver_SetQuestCategory(").Append(variable).Append(", ")
                .Append(FormatString(quest.Category)).Append(')').Append(newLine);
            List<string> objectiveTexts = (objectives ?? Array.Empty<QuestObjectiveDefinition>())
                .OrderBy(objective => objective.DisplayOrder).Take(8)
                .Select(objective => FormatString(objective.Text)).ToList();
            while (objectiveTexts.Count < 8) objectiveTexts.Add("\"\"");
            registration.Append(callIndent).Append("call QuestGiver_SetRequirements(").Append(variable)
                .Append(".id, \"\", ").Append(string.Join(", ", objectiveTexts)).Append(')').Append(newLine);

            preview.Replacements.Add(new SourceReplacement(constants.BodyEnd, 0, constantText,
                "Add quest-name constant", "", symbol));
            preview.Replacements.Add(new SourceReplacement(registrations.BodyEnd, 0, registration.ToString(),
                "Add standard quest registration", "", quest.Title));
            FinalizePreview(preview);
            return preview;
        }

        public string Apply(SourcePatchPreview preview)
        {
            if (preview == null) throw new ArgumentNullException(nameof(preview));
            if (preview.Conflicts.Count > 0) throw new InvalidOperationException(string.Join(Environment.NewLine, preview.Conflicts));
            if (!preview.HasChanges) throw new InvalidOperationException("The source patch contains no changes.");

            SourceDocument current = SourceDocument.Load(preview.FullPath);
            if (!string.Equals(current.Fingerprint, preview.OriginalFingerprint, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException(
                    "The .j file changed after the patch preview was prepared. No file was written; review the latest source again.");
            }

            string updated = ApplyReplacements(current.Text, preview.Replacements);
            ValidatePatchedSource(current, updated);
            string backupRoot = Path.Combine(Path.GetTempPath(), "WC3Manager", "source-backups");
            Directory.CreateDirectory(backupRoot);
            string backupName = Path.GetFileNameWithoutExtension(preview.FullPath) + "_" +
                                DateTime.Now.ToString("yyyyMMdd_HHmmssfff", CultureInfo.InvariantCulture) + ".j";
            string backupPath = Path.Combine(backupRoot, backupName);

            string temporaryPath = preview.FullPath + ".wc3manager." + Guid.NewGuid().ToString("N") + ".tmp";
            try
            {
                byte[] content = Encode(updated, current.HasUtf8Bom);
                File.WriteAllBytes(temporaryPath, content);
                SourceDocument latest = SourceDocument.Load(preview.FullPath);
                if (!string.Equals(latest.Fingerprint, preview.OriginalFingerprint, StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException(
                        "The .j file changed while the patch was being prepared. No file was written; review the latest source again.");
                }
                File.Copy(preview.FullPath, backupPath, false);
                File.Move(temporaryPath, preview.FullPath, true);
            }
            finally
            {
                if (File.Exists(temporaryPath)) File.Delete(temporaryPath);
            }
            return backupPath;
        }

        private static void AddGiverMappings(QuestSourceEditSession session, QuestGiverDefinition giver,
            SourceDocument document)
        {
            foreach (PropertyInfo property in typeof(QuestGiverDefinition).GetProperties())
            {
                session.MutableGiverFields[property.Name] = SourceFieldAccess.ReadOnly(property.Name, SourceOnlyReason);
            }

            List<SourceArgument> displayArguments = document.Calls
                .Where(call => call.Name == "QuestGiver_CreateConfiguredQuest" && call.Arguments.Count >= 16)
                .Select(call => call.Arguments[15]).ToList();
            if (displayArguments.Count == 0) return;
            if (TryCreateSharedField(document, "DisplayName", displayArguments, ValueKind.String,
                    out SourceFieldMapping mapping, out string reason))
            {
                RegisterMapping(session, mapping);
                session.MutableGiverFields["DisplayName"] = mapping.Access;
            }
            else
            {
                session.MutableGiverFields["DisplayName"] = SourceFieldAccess.ReadOnly("DisplayName", reason);
            }
        }

        private static void AddQuestMappings(QuestSourceEditSession session, QuestDefinition quest,
            IReadOnlyList<QuestObjectiveDefinition> objectives, SourceDocument document)
        {
            foreach (PropertyInfo property in typeof(QuestDefinition).GetProperties())
            {
                session.MutableQuestFields[property.Name] = SourceFieldAccess.ReadOnly(property.Name, SourceOnlyReason);
            }
            foreach (PropertyInfo property in typeof(QuestRewardDefinition).GetProperties())
            {
                session.MutableRewardFields[property.Name] = SourceFieldAccess.ReadOnly(property.Name, SourceOnlyReason);
            }
            foreach (QuestObjectiveDefinition objective in objectives)
            {
                var access = typeof(QuestObjectiveDefinition).GetProperties()
                    .ToDictionary(property => property.Name,
                        property => SourceFieldAccess.ReadOnly(property.Name, SourceOnlyReason),
                        StringComparer.Ordinal);
                session.MutableObjectiveFields[objective.Id] = access;
            }

            SourceCall create = document.FindQuestCreate(quest.SourceSymbol);
            if (create == null)
            {
                session.AnalysisWarnings.Add($"Could not locate source quest symbol '{quest.SourceSymbol}'. Run Sync JASS sources.");
                return;
            }
            AddArgumentField(session, document, session.MutableQuestFields,
                "QuestName", create, 0, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "QuestType", create, 2, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "QuestLevel", create, 3, ValueKind.Integer);
            AddArgumentField(session, document, session.MutableQuestFields,
                "Title", create, 5, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "IconPath", create, 6, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "Description", create, 7, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "InfoText", create, 8, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "Info2Text", create, 9, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "RequiredLevel", create, 10, ValueKind.Integer);
            AddArgumentField(session, document, session.MutableQuestFields,
                "AllowNazgrek", create, 12, ValueKind.Boolean);
            AddArgumentField(session, document, session.MutableQuestFields,
                "AllowZulkis", create, 13, ValueKind.Boolean);
            AddArgumentField(session, document, session.MutableQuestFields,
                "Faction", create, 14, ValueKind.String);
            AddArgumentField(session, document, session.MutableQuestFields,
                "ReceiverDisplayName", create, 15, ValueKind.String);

            SourceCall category = document.FindSingleRelatedCall(create, "QuestGiver_SetQuestCategory");
            AddRelatedField(session, document, category, session.MutableQuestFields,
                "Category", 1, ValueKind.String);
            SourceCall reputation = document.FindSingleRelatedCall(create,
                "QuestGiver_SetQuestRequiredReputation", "QuestGiver_SetRequiredReputation");
            AddRelatedField(session, document, reputation, session.MutableQuestFields,
                "RequiredReputation", 1, ValueKind.Integer);

            SourceCall rewards = document.FindSingleRelatedCall(create, "QuestGiver_SetQuestRewards");
            string[] rewardProperties =
            {
                "XpActive", "XpAdjust", "GoldActive", "GoldAdjust", "ArenaActive", "ArenaAdjust",
                "ReputationActive", "ReputationAdjust", "ReputationLinked"
            };
            for (int index = 0; index < rewardProperties.Length; index++)
            {
                ValueKind kind = index % 2 == 0 || index == 8 ? ValueKind.Boolean : ValueKind.Integer;
                AddRelatedField(session, document, rewards, session.MutableRewardFields,
                    rewardProperties[index], index + 1, kind);
            }

            SourceCall requirements = document.FindSingleRelatedCall(create, "QuestGiver_SetRequirements");
            if (requirements == null) return;
            int objectiveIndex = 0;
            for (int argumentIndex = 2; argumentIndex < requirements.Arguments.Count && objectiveIndex < objectives.Count;
                 argumentIndex++)
            {
                SourceArgument argument = requirements.Arguments[argumentIndex];
                if (!document.TryResolveValue(argument, ValueKind.String, true,
                        out SourceFieldMapping objectiveMapping, out _)) continue;
                QuestObjectiveDefinition objective = objectives[objectiveIndex++];
                objectiveMapping.PropertyName = "Text";
                objectiveMapping.Access.PropertyName = "Text";
                RegisterMapping(session, objectiveMapping);
                session.MutableObjectiveFields[objective.Id]["Text"] = objectiveMapping.Access;
            }
        }

        private static void AddArgumentField(QuestSourceEditSession session, SourceDocument document,
            IDictionary<string, SourceFieldAccess> access,
            string property, SourceCall call, int argumentIndex, ValueKind kind)
        {
            if (call == null || argumentIndex >= call.Arguments.Count) return;
            if (document.TryResolveValue(call.Arguments[argumentIndex], kind, true,
                    out SourceFieldMapping mapping, out string reason))
            {
                mapping.PropertyName = property;
                mapping.Access.PropertyName = property;
                RegisterMapping(session, mapping);
                access[property] = mapping.Access;
            }
            else
            {
                access[property] = SourceFieldAccess.ReadOnly(property, reason);
            }
        }

        private static void AddRelatedField(QuestSourceEditSession session, SourceDocument document, SourceCall call,
            IDictionary<string, SourceFieldAccess> access,
            string property, int argumentIndex, ValueKind kind)
        {
            if (call == null)
            {
                access[property] = SourceFieldAccess.ReadOnly(property,
                    "No unique recognized JASS call owns this value. Edit it in the repository .j file.");
                return;
            }
            AddArgumentField(session, document, access, property, call, argumentIndex, kind);
        }

        private static void RegisterMapping(QuestSourceEditSession session, SourceFieldMapping mapping)
        {
            session.Bindings[mapping.Access] = new SourceEditBinding
            {
                Access = mapping.Access,
                Targets = mapping.Targets.Select(target => new SourceEditTarget(target.Start, target.Length)).ToList(),
                Formatter = value => FormatValue(value, mapping.Kind)
            };
        }

        private static bool TryCreateSharedField(SourceDocument document, string property,
            IReadOnlyList<SourceArgument> arguments, ValueKind kind,
            out SourceFieldMapping mapping, out string reason)
        {
            mapping = null;
            reason = SourceOnlyReason;
            var resolved = new List<SourceFieldMapping>();
            foreach (SourceArgument argument in arguments)
            {
                if (!document.TryResolveValue(argument, kind, true, out SourceFieldMapping item, out reason)) return false;
                resolved.Add(item);
            }
            if (resolved.Select(item => Convert.ToString(item.Access.CurrentValue, CultureInfo.InvariantCulture))
                .Distinct(StringComparer.Ordinal).Count() != 1)
            {
                reason = "The recognized calls use different values, so there is no single reliable giver field to edit.";
                return false;
            }
            List<SourceSpan> targets = resolved.SelectMany(item => item.Targets)
                .GroupBy(target => (target.Start, target.Length)).Select(group => group.First()).ToList();
            mapping = new SourceFieldMapping(property, kind, resolved[0].Access.CurrentValue, targets);
            return true;
        }

        private static void FindManagedRegions(QuestSourceEditSession session, SourceDocument document)
        {
            session.ConstantsRegion = document.FindRegion("QUEST CONSTANTS");
            session.QuestRegion = document.FindRegion("QUESTS");
            if (session.ConstantsRegion == null || session.QuestRegion == null)
            {
                session.CanAddQuest = false;
                session.AddQuestReason =
                    "Adding a quest is disabled until the source contains both WC3M-BEGIN/END QUEST CONSTANTS " +
                    "inside a globals block and WC3M-BEGIN/END QUESTS inside the correct registration function.";
                return;
            }
            if (!IsInsideBlock(document.MaskedText, session.ConstantsRegion.BodyStart,
                    @"(?m)^\s*globals\b", @"(?m)^\s*endglobals\b"))
            {
                session.CanAddQuest = false;
                session.AddQuestReason = "The QUEST CONSTANTS region must be inside this library's globals/endglobals block.";
                return;
            }
            if (!IsInsideBlock(document.MaskedText, session.QuestRegion.BodyStart,
                    @"(?m)^\s*(?:private\s+|public\s+)?function\s+[A-Za-z][A-Za-z0-9_]*\b",
                    @"(?m)^\s*endfunction\b"))
            {
                session.CanAddQuest = false;
                session.AddQuestReason = "The QUESTS region must be inside the reviewed quest-registration function.";
                return;
            }
            if (!session.QuestRegion.Options.ContainsKey("variable") || !session.QuestRegion.Options.ContainsKey("giver"))
            {
                session.CanAddQuest = false;
                session.AddQuestReason =
                    "The QUESTS marker must declare its local quest variable and giver expression, for example: " +
                    "// WC3M-BEGIN QUESTS variable=q giver=Aradion receiver=null";
                return;
            }
            string variable = session.QuestRegion.Options["variable"];
            string giver = session.QuestRegion.Options["giver"];
            string receiver = session.QuestRegion.Options.TryGetValue("receiver", out string receiverValue)
                ? receiverValue : "null";
            if (!Regex.IsMatch(variable, @"^[A-Za-z][A-Za-z0-9_]*$") ||
                !Regex.IsMatch(giver, @"^(?:null|[A-Za-z][A-Za-z0-9_]*)$") ||
                !Regex.IsMatch(receiver, @"^(?:null|[A-Za-z][A-Za-z0-9_]*)$"))
            {
                session.CanAddQuest = false;
                session.AddQuestReason = "The QUESTS marker variable, giver, and receiver must be simple JASS identifiers or null.";
                return;
            }
            int functionStart = LastMatchStart(document.MaskedText, session.QuestRegion.BodyStart,
                @"(?m)^\s*(?:private\s+|public\s+)?function\s+[A-Za-z][A-Za-z0-9_]*\b");
            string functionPrefix = functionStart >= 0
                ? document.MaskedText.Substring(functionStart, session.QuestRegion.BodyStart - functionStart)
                : "";
            if (!Regex.IsMatch(functionPrefix, $@"(?m)^\s*local\s+QuestData\s+{Regex.Escape(variable)}\b"))
            {
                session.CanAddQuest = false;
                session.AddQuestReason = $"The containing function must declare 'local QuestData {variable}' before the QUESTS region.";
                return;
            }
            session.CanAddQuest = true;
            session.AddQuestReason = "A reviewed WC3 Manager-owned quest region is available.";
        }

        private static bool IsInsideBlock(string text, int position, string beginPattern, string endPattern)
        {
            int begin = LastMatchStart(text, position, beginPattern);
            int end = LastMatchStart(text, position, endPattern);
            return begin >= 0 && begin > end;
        }

        private static int LastMatchStart(string text, int before, string pattern)
        {
            int result = -1;
            foreach (Match match in Regex.Matches(text.Substring(0, Math.Min(before, text.Length)), pattern))
                result = match.Index;
            return result;
        }

        private static SourcePatchPreview CreatePreview(QuestSourceEditSession session)
        {
            var preview = new SourcePatchPreview
            {
                FullPath = session.FullPath,
                RelativePath = session.RelativePath,
                OriginalFingerprint = session.Fingerprint,
                OriginalText = session.SourceText,
                Bindings = session.Bindings
            };
            preview.Warnings.AddRange(session.AnalysisWarnings);
            if (!session.FingerprintMatchesDatabase)
            {
                preview.Warnings.Add(
                    "The source fingerprint differs from the last database synchronization. Field-level three-way checks will protect overlapping edits.");
            }
            return preview;
        }

        private static void AddModelChanges(SourcePatchPreview preview,
            IReadOnlyDictionary<string, SourceFieldAccess> access, object baseline, object proposed, string prefix)
        {
            if (baseline == null || proposed == null) return;
            Type type = baseline.GetType();
            foreach (PropertyInfo property in type.GetProperties(BindingFlags.Public | BindingFlags.Instance))
            {
                if (!property.CanRead || property.GetIndexParameters().Length != 0) continue;
                object before = property.GetValue(baseline);
                object after = property.GetValue(proposed);
                if (ValuesEqual(before, after)) continue;
                SourceFieldAccess field = null;
                if (access == null || !access.TryGetValue(property.Name, out field) || !field.Editable)
                {
                    string reason = field?.Reason;
                    if (string.IsNullOrWhiteSpace(reason)) reason = SourceOnlyReason;
                    preview.Conflicts.Add($"{prefix} / {property.Name}: {reason}");
                    continue;
                }
                if (!ValuesEqual(field.CurrentValue, before) && !ValuesEqual(field.CurrentValue, after))
                {
                    preview.Conflicts.Add(
                        $"{prefix} / {property.Name}: both the repository and WC3 Manager changed this field " +
                        $"(synced '{DisplayValue(before)}', source '{DisplayValue(field.CurrentValue)}', manager '{DisplayValue(after)}').");
                    continue;
                }
                if (ValuesEqual(field.CurrentValue, after)) continue;
                if (!preview.Bindings.TryGetValue(field, out SourceEditBinding binding))
                {
                    preview.Conflicts.Add($"{prefix} / {property.Name}: the source mapping was lost; synchronize and retry.");
                    continue;
                }
                foreach (SourceEditTarget target in binding.Targets)
                {
                    preview.Replacements.Add(new SourceReplacement(target.Start, target.Length,
                        binding.Formatter(after), $"{prefix} / {property.Name}",
                        DisplayValue(field.CurrentValue), DisplayValue(after)));
                }
            }
        }

        private static void FinalizePreview(SourcePatchPreview preview)
        {
            preview.Replacements.Sort((left, right) => right.Start.CompareTo(left.Start));
            for (int index = 1; index < preview.Replacements.Count; index++)
            {
                SourceReplacement previous = preview.Replacements[index - 1];
                SourceReplacement current = preview.Replacements[index];
                if (current.Start + current.Length > previous.Start)
                {
                    preview.Conflicts.Add($"Overlapping source mappings were detected around {current.Label}; no patch can be applied.");
                }
            }
            if (preview.Conflicts.Count == 0 && preview.Replacements.Count > 0)
            {
                preview.UpdatedText = ApplyReplacements(preview.OriginalText, preview.Replacements);
            }
        }

        private static string ApplyReplacements(string text, IEnumerable<SourceReplacement> replacements)
        {
            var builder = new StringBuilder(text);
            foreach (SourceReplacement replacement in replacements.OrderByDescending(item => item.Start))
            {
                builder.Remove(replacement.Start, replacement.Length);
                builder.Insert(replacement.Start, replacement.NewText);
            }
            return builder.ToString();
        }

        private static void ValidatePatchedSource(SourceDocument original, string updated)
        {
            SourceDocument patched = SourceDocument.Parse(original.FullPath, updated, original.HasUtf8Bom);
            if (!string.Equals(original.LibraryName, patched.LibraryName, StringComparison.Ordinal))
            {
                throw new InvalidOperationException("The patch changed or lost the JASS library declaration; no file was written.");
            }
            if (patched.Calls.Count(call => call.Name == "QuestGiver_CreateConfiguredQuest") <
                original.Calls.Count(call => call.Name == "QuestGiver_CreateConfiguredQuest"))
            {
                throw new InvalidOperationException("The patch removed a recognized quest registration; no file was written.");
            }
        }

        private static string ResolveSourcePath(string relativePath)
        {
            string questsRoot = QuestSourceSynchronizer.FindQuestsAndDialogsRoot();
            if (string.IsNullOrWhiteSpace(questsRoot))
                throw new DirectoryNotFoundException("Could not locate the repository QuestsAndDialogs folder.");
            string repositoryRoot = Directory.GetParent(questsRoot)?.FullName ?? questsRoot;
            string safeRoot = Path.GetFullPath(repositoryRoot).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            string fullPath = Path.GetFullPath(Path.Combine(repositoryRoot,
                (relativePath ?? "").Replace('/', Path.DirectorySeparatorChar)));
            if (!fullPath.StartsWith(safeRoot, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("The synchronized source path leaves the repository root.");
            if (!File.Exists(fullPath)) throw new FileNotFoundException("The synchronized source file was not found.", fullPath);
            return fullPath;
        }

        private static bool ValuesEqual(object left, object right)
        {
            if (left == null || left == DBNull.Value) return right == null || right == DBNull.Value;
            if (right == null || right == DBNull.Value) return false;
            if (left is decimal || right is decimal)
                return Convert.ToDecimal(left, CultureInfo.InvariantCulture) == Convert.ToDecimal(right, CultureInfo.InvariantCulture);
            if (left is int || right is int)
                return Convert.ToInt32(left, CultureInfo.InvariantCulture) == Convert.ToInt32(right, CultureInfo.InvariantCulture);
            if (left is bool || right is bool)
                return Convert.ToBoolean(left, CultureInfo.InvariantCulture) == Convert.ToBoolean(right, CultureInfo.InvariantCulture);
            return string.Equals(Convert.ToString(left, CultureInfo.InvariantCulture),
                Convert.ToString(right, CultureInfo.InvariantCulture), StringComparison.Ordinal);
        }

        private static string DisplayValue(object value)
        {
            string text = Convert.ToString(value, CultureInfo.InvariantCulture) ?? "";
            return text.Replace("\r", "\\r").Replace("\n", "\\n");
        }

        private static string FormatValue(object value, ValueKind kind)
        {
            return kind switch
            {
                ValueKind.Boolean => FormatBool(Convert.ToBoolean(value, CultureInfo.InvariantCulture)),
                ValueKind.Integer => Convert.ToInt32(value, CultureInfo.InvariantCulture).ToString(CultureInfo.InvariantCulture),
                _ => FormatString(Convert.ToString(value, CultureInfo.InvariantCulture) ?? "")
            };
        }

        private static string FormatString(string value)
        {
            string escaped = (value ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"")
                .Replace("\r", "\\r").Replace("\n", "\\n").Replace("\t", "\\t");
            return "\"" + escaped + "\"";
        }

        private static string FormatBool(bool value) => value ? "true" : "false";

        private static string FitIdentifier(string value, int maximumLength)
        {
            string result = Regex.Replace(value ?? "", @"[^A-Za-z0-9_]", "_");
            result = Regex.Replace(result, @"_+", "_").Trim('_');
            if (string.IsNullOrWhiteSpace(result)) result = "NEW_QUEST";
            if (!char.IsLetter(result[0])) result = "Q_" + result;
            return result.Length <= maximumLength ? result : result.Substring(0, maximumLength);
        }

        private static byte[] Encode(string text, bool withBom)
        {
            byte[] content = new UTF8Encoding(false).GetBytes(text ?? "");
            if (!withBom) return content;
            byte[] preamble = Encoding.UTF8.GetPreamble();
            var result = new byte[preamble.Length + content.Length];
            Buffer.BlockCopy(preamble, 0, result, 0, preamble.Length);
            Buffer.BlockCopy(content, 0, result, preamble.Length, content.Length);
            return result;
        }

        private enum ValueKind { String, Integer, Boolean }

        private sealed class SourceDocument
        {
            public string FullPath { get; private set; } = "";
            public string Text { get; private set; } = "";
            public string MaskedText { get; private set; } = "";
            public string Fingerprint { get; private set; } = "";
            public string LibraryName { get; private set; } = "";
            public string NewLine { get; private set; } = Environment.NewLine;
            public bool HasUtf8Bom { get; private set; }
            public List<SourceCall> Calls { get; } = new List<SourceCall>();
            public Dictionary<string, SourceConstant> Constants { get; } =
                new Dictionary<string, SourceConstant>(StringComparer.OrdinalIgnoreCase);

            public static SourceDocument Load(string path)
            {
                byte[] bytes = File.ReadAllBytes(path);
                bool bom = bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
                string text = new UTF8Encoding(false, true).GetString(bytes, bom ? 3 : 0, bytes.Length - (bom ? 3 : 0));
                return Parse(path, text, bom);
            }

            public static SourceDocument Parse(string path, string text, bool bom)
            {
                var document = new SourceDocument
                {
                    FullPath = path,
                    Text = text ?? "",
                    HasUtf8Bom = bom,
                    NewLine = (text ?? "").Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n"
                };
                document.MaskedText = MaskComments(document.Text);
                document.Fingerprint = ComputeSha256(document.Text);
                Match library = Regex.Match(document.MaskedText, @"(?m)^\s*library\s+([A-Za-z][A-Za-z0-9_]*)\b");
                document.LibraryName = library.Success ? library.Groups[1].Value : "";
                document.ParseConstants();
                document.ParseCalls();
                return document;
            }

            public SourceCall FindQuestCreate(string sourceSymbol)
            {
                List<SourceCall> creates = Calls.Where(call => call.Name == "QuestGiver_CreateConfiguredQuest")
                    .OrderBy(call => call.Start).ToList();
                for (int index = 0; index < creates.Count; index++)
                {
                    string expression = creates[index].Arguments.FirstOrDefault()?.Text.Trim() ?? "";
                    string symbol = Regex.IsMatch(expression, @"^[A-Za-z][A-Za-z0-9_]*$")
                        ? expression : "Quest" + (index + 1);
                    if (string.Equals(symbol, sourceSymbol, StringComparison.OrdinalIgnoreCase)) return creates[index];
                }
                return null;
            }

            public SourceCall FindSingleRelatedCall(SourceCall create, params string[] names)
            {
                if (create == null) return null;
                int nextCreate = Calls.Where(call => call.Name == "QuestGiver_CreateConfiguredQuest" && call.Start > create.Start)
                    .Select(call => call.Start).DefaultIfEmpty(int.MaxValue).Min();
                Match endFunction = Regex.Match(MaskedText.Substring(create.End), @"(?m)^\s*endfunction\b");
                int functionEnd = endFunction.Success ? create.End + endFunction.Index : int.MaxValue;
                int end = Math.Min(nextCreate, functionEnd);
                string target = create.AssignmentTarget;
                List<SourceCall> matches = Calls.Where(call => call.Start > create.End && call.Start < end)
                    .Where(call => names.Contains(call.Name, StringComparer.Ordinal))
                    .Where(call => call.Arguments.Count > 0 && TargetMatches(call.Arguments[0].Text, target))
                    .ToList();
                return matches.Count == 1 ? matches[0] : null;
            }

            public bool TryResolveValue(SourceArgument argument, ValueKind kind, bool requireUniqueConstant,
                out SourceFieldMapping mapping, out string reason)
            {
                mapping = null;
                reason = SourceOnlyReason;
                if (argument == null) return false;
                string expression = argument.Text.Trim();
                if (TryParseLiteral(expression, kind, out object direct))
                {
                    mapping = new SourceFieldMapping("", kind, direct,
                        new[] { new SourceSpan(argument.Start, argument.Length) });
                    return true;
                }
                if (!Regex.IsMatch(expression, @"^[A-Za-z][A-Za-z0-9_]*$") ||
                    !Constants.TryGetValue(expression, out SourceConstant constant))
                {
                    reason = "The source uses a computed expression or function call. Edit it in the repository .j file.";
                    return false;
                }
                if (!TryParseLiteral(constant.Expression, kind, out object constantValue))
                {
                    reason = $"Constant '{expression}' is not a simple literal. Edit it in the repository .j file.";
                    return false;
                }
                int references = Regex.Matches(MaskedText, $@"\b{Regex.Escape(expression)}\b").Count;
                if (requireUniqueConstant && references != 2)
                {
                    reason = $"Constant '{expression}' is shared by other source logic. Edit it in the repository .j file.";
                    return false;
                }
                mapping = new SourceFieldMapping("", kind, constantValue,
                    new[] { new SourceSpan(constant.ExpressionStart, constant.ExpressionLength) });
                return true;
            }

            public SourceManagedRegion FindRegion(string name)
            {
                Match begin = Regex.Match(Text,
                    $@"(?m)^(?<indent>[ \t]*)//[ \t]*WC3M-BEGIN[ \t]+{Regex.Escape(name)}(?<options>[^\r\n]*)\r?$",
                    RegexOptions.IgnoreCase);
                if (!begin.Success) return null;
                Match end = Regex.Match(Text.Substring(begin.Index + begin.Length),
                    $@"(?m)^[ \t]*//[ \t]*WC3M-END[ \t]+{Regex.Escape(name)}[ \t]*\r?$",
                    RegexOptions.IgnoreCase);
                if (!end.Success) return null;
                int bodyStart = SkipLineBreak(Text, begin.Index + begin.Length);
                int bodyEnd = begin.Index + begin.Length + end.Index;
                var region = new SourceManagedRegion
                {
                    Name = name,
                    Indent = begin.Groups["indent"].Value,
                    BodyStart = bodyStart,
                    BodyEnd = bodyEnd
                };
                foreach (Match option in Regex.Matches(begin.Groups["options"].Value,
                             @"\b([A-Za-z][A-Za-z0-9_]*)=([^\s]+)"))
                {
                    region.Options[option.Groups[1].Value] = option.Groups[2].Value;
                }
                return region;
            }

            private void ParseConstants()
            {
                foreach (Match match in Regex.Matches(MaskedText,
                             @"(?m)^\s*(?:public\s+|private\s+)?constant\s+(string|integer|boolean|real)\s+([A-Za-z][A-Za-z0-9_]*)\s*=\s*([^\r\n]+)"))
                {
                    Group expression = match.Groups[3];
                    int leading = expression.Value.Length - expression.Value.TrimStart().Length;
                    string trimmed = expression.Value.Trim();
                    Constants[match.Groups[2].Value] = new SourceConstant
                    {
                        Name = match.Groups[2].Value,
                        TypeName = match.Groups[1].Value,
                        Expression = trimmed,
                        ExpressionStart = expression.Index + leading,
                        ExpressionLength = trimmed.Length
                    };
                }
            }

            private void ParseCalls()
            {
                foreach (string name in QuestCallNames)
                {
                    int search = 0;
                    while (search < MaskedText.Length)
                    {
                        int start = MaskedText.IndexOf(name, search, StringComparison.Ordinal);
                        if (start < 0) break;
                        if ((start > 0 && IsIdentifierCharacter(MaskedText[start - 1])) ||
                            (start + name.Length < MaskedText.Length && IsIdentifierCharacter(MaskedText[start + name.Length])))
                        {
                            search = start + name.Length;
                            continue;
                        }
                        int open = start + name.Length;
                        while (open < MaskedText.Length && char.IsWhiteSpace(MaskedText[open])) open++;
                        if (open >= MaskedText.Length || MaskedText[open] != '(')
                        {
                            search = start + name.Length;
                            continue;
                        }
                        int close = FindClosingParenthesis(MaskedText, open);
                        if (close < 0) break;
                        Calls.Add(new SourceCall
                        {
                            Name = name,
                            Start = start,
                            End = close + 1,
                            AssignmentTarget = FindAssignmentTarget(MaskedText, start),
                            Arguments = SplitArguments(Text, open + 1, close)
                        });
                        search = close + 1;
                    }
                }
                Calls.Sort((left, right) => left.Start.CompareTo(right.Start));
            }

            private static bool TargetMatches(string expression, string target)
            {
                if (string.IsNullOrWhiteSpace(target)) return false;
                string value = Regex.Replace(expression ?? "", @"\s+", "");
                return string.Equals(value, target, StringComparison.OrdinalIgnoreCase) ||
                       string.Equals(value, target + ".id", StringComparison.OrdinalIgnoreCase);
            }

            private static bool TryParseLiteral(string expression, ValueKind kind, out object value)
            {
                value = null;
                string text = (expression ?? "").Trim();
                if (kind == ValueKind.String)
                {
                    if (!IsSingleStringLiteral(text)) return false;
                    value = DecodeString(text.Substring(1, text.Length - 2));
                    return true;
                }
                if (kind == ValueKind.Integer)
                {
                    if (!int.TryParse(text, NumberStyles.Integer, CultureInfo.InvariantCulture, out int number)) return false;
                    value = number;
                    return true;
                }
                if (!bool.TryParse(text, out bool boolean)) return false;
                value = boolean;
                return true;
            }

            private static bool IsSingleStringLiteral(string text)
            {
                if (string.IsNullOrEmpty(text) || text[0] != '"') return false;
                bool escaped = false;
                for (int index = 1; index < text.Length; index++)
                {
                    char character = text[index];
                    if (escaped)
                    {
                        escaped = false;
                        continue;
                    }
                    if (character == '\\')
                    {
                        escaped = true;
                        continue;
                    }
                    if (character == '"') return index == text.Length - 1;
                }
                return false;
            }

            private static string DecodeString(string value)
            {
                var result = new StringBuilder();
                bool escaped = false;
                foreach (char character in value)
                {
                    if (!escaped)
                    {
                        if (character == '\\') escaped = true;
                        else result.Append(character);
                        continue;
                    }
                    escaped = false;
                    result.Append(character switch { 'n' => '\n', 'r' => '\r', 't' => '\t', _ => character });
                }
                if (escaped) result.Append('\\');
                return result.ToString();
            }

            private static List<SourceArgument> SplitArguments(string text, int start, int end)
            {
                var result = new List<SourceArgument>();
                int argumentStart = start;
                int depth = 0;
                bool inString = false;
                bool escaped = false;
                for (int index = start; index < end; index++)
                {
                    char character = text[index];
                    if (inString)
                    {
                        if (escaped) escaped = false;
                        else if (character == '\\') escaped = true;
                        else if (character == '"') inString = false;
                        continue;
                    }
                    if (character == '"') inString = true;
                    else if (character == '(' || character == '[') depth++;
                    else if (character == ')' || character == ']') depth--;
                    else if (character == ',' && depth == 0)
                    {
                        result.Add(CreateArgument(text, argumentStart, index));
                        argumentStart = index + 1;
                    }
                }
                result.Add(CreateArgument(text, argumentStart, end));
                return result;
            }

            private static SourceArgument CreateArgument(string text, int start, int end)
            {
                while (start < end && char.IsWhiteSpace(text[start])) start++;
                while (end > start && char.IsWhiteSpace(text[end - 1])) end--;
                return new SourceArgument { Start = start, Length = end - start, Text = text.Substring(start, end - start) };
            }

            private static int FindClosingParenthesis(string text, int open)
            {
                int depth = 0;
                bool inString = false;
                bool escaped = false;
                for (int index = open; index < text.Length; index++)
                {
                    char character = text[index];
                    if (inString)
                    {
                        if (escaped) escaped = false;
                        else if (character == '\\') escaped = true;
                        else if (character == '"') inString = false;
                        continue;
                    }
                    if (character == '"') inString = true;
                    else if (character == '(') depth++;
                    else if (character == ')' && --depth == 0) return index;
                }
                return -1;
            }

            private static string FindAssignmentTarget(string code, int callStart)
            {
                int lineStart = code.LastIndexOf('\n', Math.Max(0, callStart - 1));
                string prefix = code.Substring(lineStart + 1, callStart - lineStart - 1);
                Match match = Regex.Match(prefix,
                    @"(?:\bset|\blocal\s+[A-Za-z][A-Za-z0-9_]*)\s+([A-Za-z][A-Za-z0-9_]*)\s*=\s*$");
                return match.Success ? match.Groups[1].Value : "";
            }

            private static int SkipLineBreak(string text, int index)
            {
                if (index < text.Length && text[index] == '\r') index++;
                if (index < text.Length && text[index] == '\n') index++;
                return index;
            }

            private static string MaskComments(string source)
            {
                char[] characters = (source ?? "").ToCharArray();
                bool inString = false;
                bool escaped = false;
                for (int index = 0; index < characters.Length; index++)
                {
                    if (inString)
                    {
                        if (escaped) escaped = false;
                        else if (characters[index] == '\\') escaped = true;
                        else if (characters[index] == '"') inString = false;
                        continue;
                    }
                    if (characters[index] == '"') { inString = true; continue; }
                    if (characters[index] == '/' && index + 1 < characters.Length && characters[index + 1] == '/')
                    {
                        while (index < characters.Length && characters[index] != '\n') characters[index++] = ' ';
                    }
                    else if (characters[index] == '/' && index + 1 < characters.Length && characters[index + 1] == '*')
                    {
                        characters[index++] = ' ';
                        characters[index] = ' ';
                        while (++index < characters.Length)
                        {
                            if (characters[index] == '*' && index + 1 < characters.Length && characters[index + 1] == '/')
                            {
                                characters[index] = characters[index + 1] = ' ';
                                index++;
                                break;
                            }
                            if (characters[index] != '\r' && characters[index] != '\n') characters[index] = ' ';
                        }
                    }
                }
                return new string(characters);
            }

            private static string ComputeSha256(string text)
            {
                byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(text ?? ""));
                return Convert.ToHexString(bytes).ToLowerInvariant();
            }

            private static bool IsIdentifierCharacter(char character) => char.IsLetterOrDigit(character) || character == '_';
        }

        private sealed class SourceFieldMapping
        {
            public SourceFieldMapping(string propertyName, ValueKind kind, object value, IEnumerable<SourceSpan> targets)
            {
                PropertyName = propertyName;
                Kind = kind;
                Targets = targets.ToList();
                Access = new SourceFieldAccess
                {
                    PropertyName = propertyName,
                    Editable = true,
                    Reason = "Mapped to a recognized literal in the synchronized JASS source.",
                    CurrentValue = value
                };
            }
            public string PropertyName { get; set; }
            public ValueKind Kind { get; }
            public List<SourceSpan> Targets { get; }
            public SourceFieldAccess Access { get; }
        }

        private sealed class SourceSpan
        {
            public SourceSpan(int start, int length) { Start = start; Length = length; }
            public int Start { get; }
            public int Length { get; }
        }

        private sealed class SourceCall
        {
            public string Name { get; set; } = "";
            public int Start { get; set; }
            public int End { get; set; }
            public string AssignmentTarget { get; set; } = "";
            public List<SourceArgument> Arguments { get; set; } = new List<SourceArgument>();
        }

        private sealed class SourceArgument
        {
            public int Start { get; set; }
            public int Length { get; set; }
            public string Text { get; set; } = "";
        }

        private sealed class SourceConstant
        {
            public string Name { get; set; } = "";
            public string TypeName { get; set; } = "";
            public string Expression { get; set; } = "";
            public int ExpressionStart { get; set; }
            public int ExpressionLength { get; set; }
        }
    }

    public sealed class QuestSourceEditSession
    {
        public string FullPath { get; set; } = "";
        public string RelativePath { get; set; } = "";
        public string Fingerprint { get; set; } = "";
        public bool FingerprintMatchesDatabase { get; set; }
        public string DefaultReadOnlyReason { get; set; } = "";
        public bool CanAddQuest { get; set; }
        public string AddQuestReason { get; set; } = "";
        public string SuggestedQuestVariable { get; set; } = "q";
        public string SuggestedGiverExpression { get; set; } = "null";
        public IReadOnlyDictionary<string, SourceFieldAccess> GiverFields => MutableGiverFields;
        public IReadOnlyDictionary<string, SourceFieldAccess> QuestFields => MutableQuestFields;
        public IReadOnlyDictionary<string, SourceFieldAccess> RewardFields => MutableRewardFields;
        public IReadOnlyDictionary<int, IReadOnlyDictionary<string, SourceFieldAccess>> ObjectiveFields =>
            MutableObjectiveFields.ToDictionary(pair => pair.Key,
                pair => (IReadOnlyDictionary<string, SourceFieldAccess>)pair.Value);
        public List<string> AnalysisWarnings { get; } = new List<string>();

        internal Dictionary<string, SourceFieldAccess> MutableGiverFields { get; } = new Dictionary<string, SourceFieldAccess>();
        internal Dictionary<string, SourceFieldAccess> MutableQuestFields { get; } = new Dictionary<string, SourceFieldAccess>();
        internal Dictionary<string, SourceFieldAccess> MutableRewardFields { get; } = new Dictionary<string, SourceFieldAccess>();
        internal Dictionary<int, Dictionary<string, SourceFieldAccess>> MutableObjectiveFields { get; } =
            new Dictionary<int, Dictionary<string, SourceFieldAccess>>();
        internal string SourceText { get; set; } = "";
        internal string SourceMaskedText { get; set; } = "";
        internal string SourceNewLine { get; set; } = Environment.NewLine;
        internal SourceManagedRegion ConstantsRegion { get; set; }
        internal SourceManagedRegion QuestRegion { get; set; }
        internal Dictionary<SourceFieldAccess, SourceEditBinding> Bindings { get; } =
            new Dictionary<SourceFieldAccess, SourceEditBinding>();
    }

    public sealed class SourcePatchPreview
    {
        public string FullPath { get; set; } = "";
        public string RelativePath { get; set; } = "";
        public string OriginalFingerprint { get; set; } = "";
        public string OriginalText { get; set; } = "";
        public string UpdatedText { get; set; } = "";
        public List<string> Warnings { get; } = new List<string>();
        public List<string> Conflicts { get; } = new List<string>();
        public List<SourceReplacement> Replacements { get; } = new List<SourceReplacement>();
        public bool HasChanges => Replacements.Count > 0 && Conflicts.Count == 0;
        internal IReadOnlyDictionary<SourceFieldAccess, SourceEditBinding> Bindings { get; set; } =
            new Dictionary<SourceFieldAccess, SourceEditBinding>();
    }

    public sealed class SourceReplacement
    {
        public SourceReplacement(int start, int length, string newText, string label, string oldValue, string newValue)
        {
            Start = start;
            Length = length;
            NewText = newText ?? "";
            Label = label ?? "";
            OldValue = oldValue ?? "";
            NewValue = newValue ?? "";
        }
        public int Start { get; }
        public int Length { get; }
        public string NewText { get; }
        public string Label { get; }
        public string OldValue { get; }
        public string NewValue { get; }
    }

    internal sealed class SourceManagedRegion
    {
        public string Name { get; set; } = "";
        public string Indent { get; set; } = "";
        public int BodyStart { get; set; }
        public int BodyEnd { get; set; }
        public Dictionary<string, string> Options { get; } = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    }

    internal sealed class SourceEditBinding
    {
        public SourceFieldAccess Access { get; set; }
        public List<SourceEditTarget> Targets { get; set; } = new List<SourceEditTarget>();
        public Func<object, string> Formatter { get; set; }
    }

    internal sealed class SourceEditTarget
    {
        public SourceEditTarget(int start, int length) { Start = start; Length = length; }
        public int Start { get; }
        public int Length { get; }
    }
}
