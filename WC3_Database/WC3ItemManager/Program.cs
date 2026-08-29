using System;
using System.Linq;
using System.Windows.Forms;
using WC3ItemManager.Importers;
using WC3ItemManager.Models;
using WC3ItemManager.Repositories;
using WC3ItemManager.SourceEditing;

namespace WC3ItemManager
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length >= 1 && string.Equals(args[0], "--audit-quest-source-editing", StringComparison.OrdinalIgnoreCase))
            {
                QuestSourceEditor.RunMarkerContractSelfTest();
                var repository = new QuestDesignerRepository(MainForm.DefaultConnectionString);
                var editor = new QuestSourceEditor();
                var givers = repository.GetGivers()
                    .Where(giver => string.Equals(giver.OwnershipMode, "external", StringComparison.OrdinalIgnoreCase) &&
                                    !string.IsNullOrWhiteSpace(giver.SourceImportFingerprint))
                    .ToList();
                int quests = 0;
                int editableGiverFields = 0;
                int editableQuestFields = 0;
                int editableRewardFields = 0;
                int editableObjectiveFields = 0;
                int patchPreviews = 0;
                int rewardPatchPreviews = 0;
                int objectivePatchPreviews = 0;
                int conflictChecks = 0;
                int customLogicChecks = 0;
                int errors = 0;
                foreach (var giver in givers)
                {
                    bool giverFieldsCounted = false;
                    foreach (var quest in repository.GetQuests(giver.Id))
                    {
                        try
                        {
                            var objectives = repository.GetObjectives(quest.Id);
                            var session = editor.Analyze(giver, quest, objectives);
                            quests++;
                            if (!giverFieldsCounted)
                            {
                                editableGiverFields += session.GiverFields.Values.Count(field => field.Editable);
                                giverFieldsCounted = true;
                            }
                            editableQuestFields += session.QuestFields.Values.Count(field => field.Editable);
                            editableRewardFields += session.RewardFields.Values.Count(field => field.Editable);
                            editableObjectiveFields += session.ObjectiveFields.Values
                                .Sum(fields => fields.Values.Count(field => field.Editable));
                            if (string.Equals(quest.SourceSymbol, "QUEST_RIFTS_CORRUPTION", StringComparison.OrdinalIgnoreCase))
                            {
                                if (session.QuestFields[nameof(QuestDefinition.Description)].Editable ||
                                    session.QuestFields[nameof(QuestDefinition.InfoText)].Editable)
                                    throw new InvalidOperationException("Computed qAradion text was incorrectly marked editable.");
                                customLogicChecks++;
                            }
                            if (string.Equals(quest.SourceSymbol, "QUEST_SHREDDER_FUEL", StringComparison.OrdinalIgnoreCase))
                            {
                                if (!session.QuestFields[nameof(QuestDefinition.Description)].Editable ||
                                    session.QuestFields[nameof(QuestDefinition.InfoText)].Editable)
                                    throw new InvalidOperationException("qQuinx literal/custom text classification was incorrect.");
                                customLogicChecks++;
                            }
                            if (patchPreviews < 10 && session.QuestFields.TryGetValue(nameof(QuestDefinition.Title), out var title) && title.Editable)
                            {
                                QuestDefinition proposed = CloneModel(quest);
                                proposed.Title += " [source-edit audit]";
                                QuestRewardDefinition reward = repository.GetReward(quest.Id);
                                SourcePatchPreview preview = editor.PrepareQuestPatch(
                                    giver, quest, proposed, reward, CloneModel(reward), objectives, objectives);
                                if (!preview.HasChanges || preview.Conflicts.Count > 0)
                                    throw new InvalidOperationException("A mapped title did not produce a safe dry-run source patch.");
                                if (conflictChecks == 0)
                                {
                                    QuestDefinition stale = CloneModel(quest);
                                    stale.Title += " [stale repository value]";
                                    SourcePatchPreview conflict = editor.PrepareQuestPatch(
                                        giver, stale, proposed, reward, CloneModel(reward), objectives, objectives);
                                    if (conflict.Conflicts.Count == 0 || conflict.HasChanges)
                                        throw new InvalidOperationException("A same-field source conflict was not blocked.");
                                    conflictChecks++;
                                }
                                patchPreviews++;
                            }
                            if (rewardPatchPreviews == 0 &&
                                session.RewardFields.TryGetValue(nameof(QuestRewardDefinition.XpAdjust), out var xpAdjust) &&
                                xpAdjust.Editable)
                            {
                                QuestRewardDefinition reward = repository.GetReward(quest.Id);
                                QuestRewardDefinition proposedReward = CloneModel(reward);
                                proposedReward.XpAdjust++;
                                SourcePatchPreview rewardPreview = editor.PrepareQuestPatch(
                                    giver, quest, CloneModel(quest), reward, proposedReward, objectives, objectives);
                                if (!rewardPreview.HasChanges || rewardPreview.Conflicts.Count > 0)
                                    throw new InvalidOperationException("A mapped reward did not produce a safe dry-run source patch.");
                                rewardPatchPreviews++;
                            }
                            if (objectivePatchPreviews == 0)
                            {
                                var editableObjective = objectives.FirstOrDefault(objective =>
                                    session.ObjectiveFields.TryGetValue(objective.Id, out var fields) &&
                                    fields.TryGetValue(nameof(QuestObjectiveDefinition.Text), out var text) && text.Editable);
                                if (editableObjective != null)
                                {
                                    var proposedObjectives = objectives.Select(CloneModel).ToList();
                                    proposedObjectives.First(objective => objective.Id == editableObjective.Id).Text += " [source-edit audit]";
                                    QuestRewardDefinition reward = repository.GetReward(quest.Id);
                                    SourcePatchPreview objectivePreview = editor.PrepareQuestPatch(
                                        giver, quest, CloneModel(quest), reward, CloneModel(reward), objectives, proposedObjectives);
                                    if (!objectivePreview.HasChanges || objectivePreview.Conflicts.Count > 0)
                                        throw new InvalidOperationException("A mapped objective did not produce a safe dry-run source patch.");
                                    objectivePatchPreviews++;
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            errors++;
                            Console.Error.WriteLine($"ERROR: {giver.SourceFile}:{quest.SourceSymbol}: {ex.Message}");
                        }
                    }
                }
                Console.WriteLine(
                    $"Givers={givers.Count}; Quests={quests}; EditableGiverFields={editableGiverFields}; EditableQuestFields={editableQuestFields}; " +
                    $"EditableRewardFields={editableRewardFields}; EditableObjectiveFields={editableObjectiveFields}; " +
                    $"PatchPreviews={patchPreviews}; RewardPatchPreviews={rewardPatchPreviews}; " +
                    $"ObjectivePatchPreviews={objectivePatchPreviews}; ConflictChecks={conflictChecks}; " +
                    $"CustomLogicChecks={customLogicChecks}; MarkerContractChecks=1; Errors={errors}");
                return errors == 0 ? 0 : 1;
            }
            if (args.Length >= 2 && string.Equals(args[0], "--sync-quest-sources", StringComparison.OrdinalIgnoreCase))
            {
                var sync = new QuestSourceSynchronizer(MainForm.DefaultConnectionString);
                QuestSourceSyncResult result = sync.Synchronize(args[1]);
                Console.WriteLine(
                    $"Files={result.FilesScanned}; QuestsFound={result.QuestDefinitionsFound}; " +
                    $"Containers={result.GiversSynchronized}; GiversCreated={result.GiversCreated}; " +
                    $"GiversUpdated={result.GiversUpdated}; QuestsCreated={result.QuestsCreated}; " +
                    $"QuestsUpdated={result.QuestsUpdated}; Unchanged={result.UnchangedSources}; " +
                    $"Warnings={result.Warnings.Count}; Errors={result.Errors.Count}");
                foreach (string warning in result.Warnings) Console.WriteLine("WARNING: " + warning);
                foreach (string error in result.Errors) Console.Error.WriteLine("ERROR: " + error);
                return result.Errors.Count == 0 ? 0 : 1;
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
            return 0;
        }

        private static T CloneModel<T>(T source) where T : class, new()
        {
            if (source == null) return null;
            var clone = new T();
            foreach (var property in typeof(T).GetProperties()
                         .Where(property => property.CanRead && property.CanWrite && property.GetIndexParameters().Length == 0))
            {
                property.SetValue(clone, property.GetValue(source));
            }
            return clone;
        }

    }
}
