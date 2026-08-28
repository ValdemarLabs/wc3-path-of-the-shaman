using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Npgsql;

namespace WC3ItemManager.Importers
{
    /// <summary>
    /// Imports a read-only database projection of active qXXX JASS sources.
    /// The JASS files remain authoritative and are never modified by this class.
    /// </summary>
    public sealed class QuestSourceSynchronizer
    {
        private static readonly string[] ExcludedDirectoryNames =
        {
            "OLDGUI", "Plans", "tools", "backups", "bin", "obj"
        };

        private readonly string _connectionString;

        public QuestSourceSynchronizer(string connectionString)
        {
            _connectionString = connectionString;
        }

        public static string FindQuestsAndDialogsRoot()
        {
            foreach (string start in new[] { Environment.CurrentDirectory, AppDomain.CurrentDomain.BaseDirectory })
            {
                var directory = new DirectoryInfo(start);
                for (int depth = 0; directory != null && depth < 10; depth++, directory = directory.Parent)
                {
                    string candidate = Path.Combine(directory.FullName, "QuestsAndDialogs");
                    if (HasSourceRoots(candidate)) return candidate;
                    if (HasSourceRoots(directory.FullName)) return directory.FullName;
                }
            }
            return "";
        }

        public QuestSourceSyncResult Synchronize(string selectedPath)
        {
            string questsRoot = ResolveQuestsRoot(selectedPath);
            string repositoryRoot = Directory.GetParent(questsRoot)?.FullName ?? questsRoot;
            var files = EnumerateSources(questsRoot).ToList();
            var result = new QuestSourceSyncResult { FilesScanned = files.Count };
            var sources = new List<SourceRecord>();

            foreach (SourceFile sourceFile in files)
            {
                try
                {
                    string text = File.ReadAllText(sourceFile.FullPath, Encoding.UTF8);
                    string relativePath = Path.GetRelativePath(repositoryRoot, sourceFile.FullPath).Replace('\\', '/');
                    SourceRecord source = ParseSource(relativePath, sourceFile.Kind, text, result);
                    if (source == null)
                    {
                        result.Warnings.Add($"{relativePath}: no library declaration was found.");
                        continue;
                    }
                    sources.Add(source);
                    result.QuestDefinitionsFound += source.Quests.Count;
                }
                catch (Exception ex)
                {
                    result.Errors.Add($"{sourceFile.FullPath}: {ex.Message}");
                }
            }

            if (result.Errors.Count > 0)
            {
                return result;
            }

            Persist(sources, result);
            DeduplicateMessages(result.Warnings);
            DeduplicateMessages(result.Errors);
            return result;
        }

        private void Persist(IReadOnlyList<SourceRecord> sources, QuestSourceSyncResult result)
        {
            using var connection = new NpgsqlConnection(_connectionString);
            connection.Open();
            using var transaction = connection.BeginTransaction();
            try
            {
                var giverIds = new Dictionary<SourceRecord, int>();
                var giverIdsByBinding = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var questIdsBySymbol = LoadQuestIdsBySymbol(connection, transaction);

                foreach (SourceRecord source in sources)
                {
                    ExistingGiver existing = FindGiver(connection, transaction, source);
                    if (existing != null && !string.Equals(existing.OwnershipMode, "external", StringComparison.OrdinalIgnoreCase))
                    {
                        result.SkippedProtectedSources++;
                        result.Warnings.Add($"{source.RelativePath}: database library {source.LibraryName} is {existing.OwnershipMode}; source sync did not change it.");
                        continue;
                    }

                    bool unchanged = existing != null && string.Equals(existing.Fingerprint, source.Fingerprint, StringComparison.OrdinalIgnoreCase);
                    int giverId = UpsertGiver(connection, transaction, source, existing);
                    giverIds[source] = giverId;
                    if (!string.IsNullOrWhiteSpace(source.PrimaryBinding))
                    {
                        giverIdsByBinding[source.PrimaryBinding] = giverId;
                    }
                    ReplaceSourceLinks(connection, transaction, giverId, source);
                    if (existing == null) result.GiversCreated++;
                    else if (unchanged) result.UnchangedSources++;
                    else result.GiversUpdated++;

                    foreach (ParsedQuest quest in source.Quests)
                    {
                        int? existingQuestId = FindImportedQuestId(connection, transaction, giverId, quest.SourceSymbol);
                        int questId;
                        if (unchanged && existingQuestId.HasValue)
                        {
                            questId = existingQuestId.Value;
                        }
                        else
                        {
                            questId = UpsertQuest(connection, transaction, giverId, source, quest, existingQuestId);
                            ReplaceObjectives(connection, transaction, questId, quest.Objectives);
                            UpsertReward(connection, transaction, questId, quest.Reward);
                            if (existingQuestId.HasValue) result.QuestsUpdated++;
                            else result.QuestsCreated++;
                        }
                        quest.DatabaseId = questId;
                        if (!questIdsBySymbol.TryGetValue(quest.SourceSymbol, out var ids))
                        {
                            ids = new List<int>();
                            questIdsBySymbol[quest.SourceSymbol] = ids;
                        }
                        if (!ids.Contains(questId)) ids.Add(questId);
                    }
                }

                foreach (SourceRecord source in sources.Where(giverIds.ContainsKey))
                {
                    int giverId = giverIds[source];
                    foreach (ParsedQuest quest in source.Quests.Where(q => q.DatabaseId > 0))
                    {
                        int? receiverId = quest.RequiresTurnIn && IsNullExpression(quest.ReceiverBinding) ? giverId : null;
                        if (!IsNullExpression(quest.ReceiverBinding))
                        {
                            giverIdsByBinding.TryGetValue(quest.ReceiverBinding, out int resolvedReceiver);
                            if (resolvedReceiver > 0) receiverId = resolvedReceiver;
                            else result.Warnings.Add($"{source.RelativePath}:{quest.SourceSymbol}: turn-in binding '{quest.ReceiverBinding}' was not resolved to an imported giver.");
                        }
                        UpdateReceiver(connection, transaction, quest.DatabaseId, receiverId);
                        ReplacePrerequisites(connection, transaction, quest, questIdsBySymbol, result, source.RelativePath);
                    }
                    result.GiversSynchronized++;
                }

                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        private static SourceRecord ParseSource(string relativePath, string sourceKind, string sourceText, QuestSourceSyncResult result)
        {
            string code = MaskComments(sourceText);
            var libraryMatch = Regex.Match(code, @"(?m)^\s*library\s+([A-Za-z][A-Za-z0-9_]*)\b");
            if (!libraryMatch.Success) return null;

            string libraryName = libraryMatch.Groups[1].Value;
            var constants = ParseStringConstants(code);
            var source = new SourceRecord
            {
                RelativePath = relativePath,
                SourceKind = sourceKind,
                LibraryName = libraryName,
                GiverKey = libraryName,
                DisplayName = sourceKind == "generic_quest"
                    ? "Generic: " + HumanizeLibraryName(libraryName)
                    : HumanizeLibraryName(libraryName),
                Fingerprint = ComputeSha256(sourceText)
            };
            Match requiresMatch = Regex.Match(code,
                @"(?m)^\s*library\s+[A-Za-z][A-Za-z0-9_]*[^\r\n]*\brequires\s+([^\r\n]+)");
            if (requiresMatch.Success)
            {
                foreach (string dependency in requiresMatch.Groups[1].Value.Split(','))
                {
                    string name = Regex.Replace(dependency.Trim(), @"^optional\s+", "", RegexOptions.IgnoreCase);
                    if (Regex.IsMatch(name, @"^q[A-Z][A-Za-z0-9_]*$")) source.RequiredLibraries.Add(name);
                }
            }

            var calls = ExtractCalls(code, new[]
            {
                "QuestGiver_CreateConfiguredQuest",
                "QuestGiver_SetQuestCategory",
                "QuestGiver_SetQuestRewards",
                "QuestGiver_SetRequirements",
                "QuestGiver_AddQuestPrerequisite",
                "QuestGiver_SetRequiredReputation",
                "QuestsVendor_RegisterFetchQuest",
                "QuestsVendor_RegisterKillQuest",
                "QuestsVendor_RegisterSupplyQuest",
                "qANightToRemember_RegisterVendorType",
                "QuestsVendor_SetFactionReward"
            }).OrderBy(c => c.Position).ToList();

            var currentByVariable = new Dictionary<string, ParsedQuest>(StringComparer.OrdinalIgnoreCase);
            ParsedQuest mostRecent = null;
            int order = 0;
            foreach (ParsedCall call in calls)
            {
                if (call.Name == "QuestGiver_CreateConfiguredQuest" && call.Arguments.Count >= 16)
                {
                    var quest = ParseConfiguredQuest(call, constants, order++);
                    source.Quests.Add(quest);
                    mostRecent = quest;
                    if (!string.IsNullOrWhiteSpace(call.AssignmentTarget)) currentByVariable[call.AssignmentTarget] = quest;
                    if (string.IsNullOrWhiteSpace(source.PrimaryBinding) && !IsNullExpression(quest.GiverBinding))
                    {
                        source.PrimaryBinding = quest.GiverBinding;
                    }
                    if (!string.IsNullOrWhiteSpace(quest.ReceiverDisplayName) && sourceKind != "generic_quest")
                    {
                        source.DisplayName = quest.GiverBinding == quest.ReceiverBinding || IsNullExpression(quest.ReceiverBinding)
                            ? quest.ReceiverDisplayName
                            : source.DisplayName;
                    }
                    continue;
                }

                if (call.Name == "qANightToRemember_RegisterVendorType" && call.Arguments.Count >= 1)
                {
                    source.UnitCode = ParseRawcode(call.Arguments[0]);
                    source.PrimaryBinding = "rawcode:" + source.UnitCode;
                    source.RegistersForGenericQuest = true;
                    if (!source.RequiredLibraries.Contains("qANightToRemember", StringComparer.OrdinalIgnoreCase))
                        source.RequiredLibraries.Add("qANightToRemember");
                    continue;
                }

                if ((call.Name == "QuestsVendor_RegisterFetchQuest" ||
                     call.Name == "QuestsVendor_RegisterKillQuest" ||
                     call.Name == "QuestsVendor_RegisterSupplyQuest") && call.Arguments.Count >= 14)
                {
                    var quest = ParseVendorQuest(call, constants, order++);
                    source.Quests.Add(quest);
                    mostRecent = quest;
                    source.UnitCode = ParseRawcode(call.Arguments[0]);
                    source.PrimaryBinding = "rawcode:" + source.UnitCode;
                    if (!string.IsNullOrWhiteSpace(call.AssignmentTarget)) currentByVariable[call.AssignmentTarget] = quest;
                    continue;
                }

                ParsedQuest target = ResolveTargetQuest(call, currentByVariable, mostRecent);
                if (target == null) continue;
                ApplyQuestCall(target, call, constants, result, relativePath);
            }

            ApplyMemberCalls(code, source);
            InferGiverBinding(source, code);
            bool registeredQuestGiverModule = Regex.IsMatch(code, @"\bQuestGiver_Register\s*\(");
            if (source.Quests.Count == 0 && !source.RegistersForGenericQuest && !registeredQuestGiverModule)
            {
                result.Warnings.Add($"{relativePath}: library imported as a giver/module but no supported quest registration call was found.");
            }
            source.Notes = $"Synchronized from {relativePath}. JASS remains authoritative; edit the source and sync again.";
            return source;
        }

        private static ParsedQuest ParseConfiguredQuest(ParsedCall call, IReadOnlyDictionary<string, string> constants, int order)
        {
            string symbol = NormalizeSymbol(call.Arguments[0], "Quest" + (order + 1));
            string questName = ResolveString(call.Arguments[0], constants);
            string title = ResolveString(call.Arguments[5], constants);
            if (string.IsNullOrWhiteSpace(title)) title = questName;
            if (string.IsNullOrWhiteSpace(title)) title = HumanizeIdentifier(symbol);
            if (string.IsNullOrWhiteSpace(questName)) questName = title;
            string type = ResolveString(call.Arguments[2], constants).ToLowerInvariant();
            if (type != "daily" && type != "repeatable") type = "normal";

            return new ParsedQuest
            {
                SourceSymbol = symbol,
                QuestKey = FitIdentifier(symbol, 64),
                QuestName = questName,
                Title = title,
                QuestType = type,
                QuestLevel = ParseInt(call.Arguments[3], 1),
                RequiredLevel = ParseInt(call.Arguments[10], 1),
                IconPath = ResolveString(call.Arguments[6], constants),
                Description = ResolveString(call.Arguments[7], constants),
                InfoText = ResolveString(call.Arguments[8], constants),
                Info2Text = ResolveString(call.Arguments[9], constants),
                GiverBinding = NormalizeBinding(call.Arguments[1]),
                ReceiverBinding = NormalizeBinding(call.Arguments[4]),
                ReceiverDisplayName = ResolveString(call.Arguments[15], constants),
                Faction = ResolveString(call.Arguments[14], constants),
                AllowNazgrek = ParseBool(call.Arguments[12], true),
                AllowZulkis = ParseBool(call.Arguments[13], false),
                SortOrder = order,
                Reward = new ParsedReward(),
                Position = call.Position,
                AssignmentTarget = call.AssignmentTarget
            };
        }

        private static ParsedQuest ParseVendorQuest(ParsedCall call, IReadOnlyDictionary<string, string> constants, int order)
        {
            string questName = ResolveString(call.Arguments[1], constants);
            string symbol = "VENDOR_" + FitIdentifier(questName, 52).ToUpperInvariant();
            string type = ResolveString(call.Arguments[2], constants).ToLowerInvariant();
            if (type != "daily" && type != "repeatable") type = "normal";
            bool supply = call.Name == "QuestsVendor_RegisterSupplyQuest";
            bool kill = call.Name == "QuestsVendor_RegisterKillQuest";
            string objectiveCode = ParseRawcode(call.Arguments[supply ? 9 : 7]);
            int amount = supply ? 1 : ParseInt(call.Arguments[8], 1);
            int goldIndex = supply ? 10 : 9;
            var quest = new ParsedQuest
            {
                SourceSymbol = symbol,
                QuestKey = FitIdentifier(symbol, 64),
                QuestName = questName,
                Title = ResolveString(call.Arguments[4], constants),
                QuestType = type,
                QuestLevel = ParseInt(call.Arguments[3], 1),
                RequiredLevel = Math.Max(1, ParseInt(call.Arguments[3], 1)),
                IconPath = ResolveString(call.Arguments[5], constants),
                Description = ResolveString(call.Arguments[6], constants),
                GiverBinding = "rawcode:" + ParseRawcode(call.Arguments[0]),
                ReceiverDisplayName = "",
                SortOrder = order,
                Reward = new ParsedReward { GoldActive = true, GoldAdjust = ParseInt(call.Arguments[goldIndex], 0) },
                Position = call.Position,
                AssignmentTarget = call.AssignmentTarget
            };
            quest.Objectives.Add(new ParsedObjective
            {
                Text = supply
                    ? $"Deliver item {objectiveCode} to {ResolveString(call.Arguments[8], constants)}"
                    : kill ? $"Kill {amount} of unit {objectiveCode}" : $"Bring {amount} of item {objectiveCode}",
                ObjectiveType = kill ? "kill" : "item",
                Amount = Math.Max(1, amount),
                ItemCode = kill ? "" : objectiveCode,
                ExternalHook = "QuestsGeneric",
                Notes = "Imported from QuestsVendor_RegisterFetchQuest; source controls runtime tracking."
            });
            return quest;
        }

        private static void ApplyQuestCall(ParsedQuest quest, ParsedCall call,
            IReadOnlyDictionary<string, string> constants, QuestSourceSyncResult result, string relativePath)
        {
            if (call.Name == "QuestGiver_SetQuestCategory" && call.Arguments.Count >= 2)
            {
                string category = ResolveString(call.Arguments[1], constants).ToLowerInvariant();
                quest.Category = new[] { "story", "dungeon", "class", "profession" }.Contains(category) ? category : "general";
            }
            else if (call.Name == "QuestGiver_SetQuestRewards" && call.Arguments.Count >= 10)
            {
                quest.Reward = new ParsedReward
                {
                    XpActive = ParseBool(call.Arguments[1], true),
                    XpAdjust = ParseInt(call.Arguments[2], 0),
                    GoldActive = ParseBool(call.Arguments[3], true),
                    GoldAdjust = ParseInt(call.Arguments[4], 0),
                    ArenaActive = ParseBool(call.Arguments[5], false),
                    ArenaAdjust = ParseInt(call.Arguments[6], 0),
                    ReputationActive = ParseBool(call.Arguments[7], false),
                    ReputationAdjust = ParseInt(call.Arguments[8], 0),
                    ReputationLinked = ParseBool(call.Arguments[9], false)
                };
            }
            else if (call.Name == "QuestGiver_SetRequirements" && call.Arguments.Count >= 2)
            {
                quest.Objectives.Clear();
                bool unresolved = false;
                for (int index = 2; index < Math.Min(10, call.Arguments.Count); index++)
                {
                    string text = ResolveString(call.Arguments[index], constants);
                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        quest.Objectives.Add(new ParsedObjective
                        {
                            Text = text,
                            ObjectiveType = InferObjectiveType(text),
                            Amount = InferAmount(text),
                            ExternalHook = "SourceOwnedObjective",
                            Notes = "Runtime completion remains owned by the imported JASS library."
                        });
                    }
                    else if (!IsEmptyStringExpression(call.Arguments[index]))
                    {
                        unresolved = true;
                    }
                }
                if (unresolved)
                {
                    result.Warnings.Add($"{relativePath}:{quest.SourceSymbol}: one or more dynamic requirement texts remain source-only.");
                }
            }
            else if (call.Name == "QuestGiver_AddQuestPrerequisite" && call.Arguments.Count >= 2)
            {
                quest.PrerequisiteSymbols.Add(NormalizeSymbol(call.Arguments[1], ""));
            }
            else if (call.Name == "QuestGiver_SetRequiredReputation" && call.Arguments.Count >= 2)
            {
                quest.RequiredReputation = ParseInt(call.Arguments[1], 0);
            }
            else if (call.Name == "QuestsVendor_SetFactionReward" && call.Arguments.Count >= 3)
            {
                quest.Faction = ResolveString(call.Arguments[1], constants);
                quest.Reward.ReputationActive = true;
                quest.Reward.ReputationAdjust = ParseInt(call.Arguments[2], 0);
                if (call.Arguments.Count > 3) quest.Reward.ReputationLinked = ParseBool(call.Arguments[3], false);
            }
        }

        private static void ApplyMemberCalls(string code, SourceRecord source)
        {
            foreach (Match match in Regex.Matches(code, @"\b([A-Za-z][A-Za-z0-9_]*)\s*\.\s*setAutoComplete\s*\(\s*(true|false)\s*\)", RegexOptions.IgnoreCase))
            {
                ParsedQuest quest = FindQuestAtPosition(source, match.Groups[1].Value, match.Index);
                if (quest != null)
                {
                    quest.AutoComplete = string.Equals(match.Groups[2].Value, "true", StringComparison.OrdinalIgnoreCase);
                    if (quest.AutoComplete) quest.RequiresTurnIn = false;
                }
            }
            foreach (Match match in Regex.Matches(code, @"\b([A-Za-z][A-Za-z0-9_]*)\s*\.\s*setRewardItemType\s*\(([^\r\n\)]*)\)", RegexOptions.IgnoreCase))
            {
                ParsedQuest quest = FindQuestAtPosition(source, match.Groups[1].Value, match.Index);
                if (quest != null)
                {
                    quest.Reward.ItemCode = ParseRawcode(match.Groups[2].Value);
                }
            }
        }

        private static ParsedQuest FindQuestAtPosition(SourceRecord source, string variable, int position)
        {
            return source.Quests
                .Where(q => string.Equals(q.AssignmentTarget, variable, StringComparison.OrdinalIgnoreCase) && q.Position <= position)
                .OrderByDescending(q => q.Position)
                .FirstOrDefault();
        }

        private static void InferGiverBinding(SourceRecord source, string code)
        {
            if (!string.IsNullOrWhiteSpace(source.UnitCode)) return;
            if (source.PrimaryBinding.StartsWith("rawcode:", StringComparison.OrdinalIgnoreCase))
            {
                source.UnitCode = source.PrimaryBinding.Substring("rawcode:".Length);
                return;
            }
            if (Regex.IsMatch(source.PrimaryBinding ?? "", @"^[A-Za-z][A-Za-z0-9_]*$"))
            {
                string pattern = @"(?m)^\s*set\s+" + Regex.Escape(source.PrimaryBinding) + @"\s*=\s*(udg_[A-Za-z0-9_]+)\b";
                Match match = Regex.Match(code, pattern);
                source.PlacedUnitVariable = match.Success ? match.Groups[1].Value : source.PrimaryBinding;
                return;
            }

            string candidate = Regex.Replace(source.LibraryName ?? "", @"^q(?=[A-Z])", "");
            if (Regex.IsMatch(candidate, @"^[A-Za-z][A-Za-z0-9_]*$") &&
                Regex.IsMatch(code, @"(?m)^\s*(?:public\s+|private\s+)?unit\s+" + Regex.Escape(candidate) + @"\b"))
            {
                source.PrimaryBinding = candidate;
                Match match = Regex.Match(code,
                    @"(?m)^\s*set\s+" + Regex.Escape(candidate) + @"\s*=\s*(udg_[A-Za-z0-9_]+)\b");
                source.PlacedUnitVariable = match.Success ? match.Groups[1].Value : candidate;
            }
        }

        private static ParsedQuest ResolveTargetQuest(ParsedCall call,
            IReadOnlyDictionary<string, ParsedQuest> currentByVariable, ParsedQuest mostRecent)
        {
            if (call.Arguments.Count == 0) return mostRecent;
            string target = NormalizeBinding(call.Arguments[0]);
            if (target.EndsWith(".id", StringComparison.OrdinalIgnoreCase)) target = target.Substring(0, target.Length - 3);
            return currentByVariable.TryGetValue(target, out ParsedQuest quest) ? quest : mostRecent;
        }

        private static void ReplaceObjectives(NpgsqlConnection connection, NpgsqlTransaction transaction,
            int questId, IReadOnlyList<ParsedObjective> objectives)
        {
            using (var delete = new NpgsqlCommand("DELETE FROM quest_objectives WHERE quest_id = @quest_id", connection, transaction))
            {
                delete.Parameters.AddWithValue("quest_id", questId);
                delete.ExecuteNonQuery();
            }
            for (int index = 0; index < Math.Min(8, objectives.Count); index++)
            {
                ParsedObjective objective = objectives[index];
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_objectives (
                        quest_id, objective_key, display_order, objective_type, text, amount,
                        item_code, completion_mode, external_hook, notes)
                    VALUES (@quest_id, @key, @display_order, @type, @text, @amount,
                            NULLIF(@item_code, ''), 'external', NULLIF(@external_hook, ''), @notes)", connection, transaction);
                insert.Parameters.AddWithValue("quest_id", questId);
                insert.Parameters.AddWithValue("key", "SourceObjective" + (index + 1));
                insert.Parameters.AddWithValue("display_order", index + 1);
                insert.Parameters.AddWithValue("type", objective.ObjectiveType);
                insert.Parameters.AddWithValue("text", objective.Text);
                insert.Parameters.AddWithValue("amount", Math.Max(1, objective.Amount));
                insert.Parameters.AddWithValue("item_code", objective.ItemCode ?? "");
                insert.Parameters.AddWithValue("external_hook", objective.ExternalHook ?? "");
                insert.Parameters.AddWithValue("notes", objective.Notes ?? "");
                insert.ExecuteNonQuery();
            }
        }

        private static void UpsertReward(NpgsqlConnection connection, NpgsqlTransaction transaction,
            int questId, ParsedReward reward)
        {
            using var command = new NpgsqlCommand(@"
                INSERT INTO quest_rewards (
                    quest_id, xp_active, xp_adjust, gold_active, gold_adjust, arena_active, arena_adjust,
                    reputation_active, reputation_adjust, reputation_linked, item_code, custom_text)
                VALUES (@quest_id, @xp_active, @xp_adjust, @gold_active, @gold_adjust, @arena_active, @arena_adjust,
                        @reputation_active, @reputation_adjust, @reputation_linked, NULLIF(@item_code, ''), '')
                ON CONFLICT (quest_id) DO UPDATE SET
                    xp_active = EXCLUDED.xp_active, xp_adjust = EXCLUDED.xp_adjust,
                    gold_active = EXCLUDED.gold_active, gold_adjust = EXCLUDED.gold_adjust,
                    arena_active = EXCLUDED.arena_active, arena_adjust = EXCLUDED.arena_adjust,
                    reputation_active = EXCLUDED.reputation_active,
                    reputation_adjust = EXCLUDED.reputation_adjust,
                    reputation_linked = EXCLUDED.reputation_linked, item_code = EXCLUDED.item_code", connection, transaction);
            command.Parameters.AddWithValue("quest_id", questId);
            command.Parameters.AddWithValue("xp_active", reward.XpActive);
            command.Parameters.AddWithValue("xp_adjust", reward.XpAdjust);
            command.Parameters.AddWithValue("gold_active", reward.GoldActive);
            command.Parameters.AddWithValue("gold_adjust", reward.GoldAdjust);
            command.Parameters.AddWithValue("arena_active", reward.ArenaActive);
            command.Parameters.AddWithValue("arena_adjust", reward.ArenaAdjust);
            command.Parameters.AddWithValue("reputation_active", reward.ReputationActive);
            command.Parameters.AddWithValue("reputation_adjust", reward.ReputationAdjust);
            command.Parameters.AddWithValue("reputation_linked", reward.ReputationLinked);
            command.Parameters.AddWithValue("item_code", reward.ItemCode ?? "");
            command.ExecuteNonQuery();
        }

        private static int UpsertGiver(NpgsqlConnection connection, NpgsqlTransaction transaction,
            SourceRecord source, ExistingGiver existing)
        {
            if (existing == null)
            {
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_givers (
                        giver_key, display_name, library_name, ownership_mode, source_file, source_kind,
                        source_import_fingerprint, source_imported_at, unit_code, placed_unit_variable,
                        allow_nazgrek, allow_zulkis, enabled, notes)
                    VALUES (@giver_key, @display_name, @library_name, 'external', @source_file, @source_kind,
                            @fingerprint, CURRENT_TIMESTAMP, NULLIF(@unit_code, ''), NULLIF(@placed_variable, ''),
                            TRUE, FALSE, TRUE, @notes)
                    RETURNING id", connection, transaction);
                AddSourceParameters(insert, source);
                return Convert.ToInt32(insert.ExecuteScalar(), CultureInfo.InvariantCulture);
            }

            using var update = new NpgsqlCommand(@"
                UPDATE quest_givers SET
                    display_name = @display_name, source_file = @source_file, source_kind = @source_kind,
                    source_import_fingerprint = @fingerprint, source_imported_at = CURRENT_TIMESTAMP,
                    unit_code = NULLIF(@unit_code, ''), placed_unit_variable = NULLIF(@placed_variable, ''),
                    enabled = TRUE, notes = @notes
                WHERE id = @id AND ownership_mode = 'external'
                RETURNING id", connection, transaction);
            AddSourceParameters(update, source);
            update.Parameters.AddWithValue("id", existing.Id);
            return Convert.ToInt32(update.ExecuteScalar(), CultureInfo.InvariantCulture);
        }

        private static int UpsertQuest(NpgsqlConnection connection, NpgsqlTransaction transaction, int giverId,
            SourceRecord source, ParsedQuest quest, int? existingQuestId)
        {
            if (existingQuestId.HasValue)
            {
                using var update = new NpgsqlCommand(@"
                    UPDATE quests SET
                        quest_key = @quest_key, quest_name = @quest_name, title = @title,
                        quest_type = @quest_type, category = @category, quest_level = @quest_level,
                        required_level = @required_level, required_reputation = @required_reputation,
                        icon_path = @icon_path, description = @description, info_text = @info_text,
                        info2_text = @info2_text, receiver_display_name = @receiver_display_name,
                        faction = @faction, allow_nazgrek = @allow_nazgrek, allow_zulkis = @allow_zulkis,
                        requires_turn_in = @requires_turn_in, auto_complete = @auto_complete,
                        draft = FALSE, enabled = TRUE, notes = @notes, source_file = @source_file,
                        source_import_fingerprint = @fingerprint, source_imported_at = CURRENT_TIMESTAMP
                    WHERE id = @id RETURNING id", connection, transaction);
                AddQuestParameters(update, giverId, source, quest);
                update.Parameters.AddWithValue("id", existingQuestId.Value);
                return Convert.ToInt32(update.ExecuteScalar(), CultureInfo.InvariantCulture);
            }

            using var insert = new NpgsqlCommand(@"
                INSERT INTO quests (
                    quest_giver_id, quest_key, quest_name, title, quest_type, category, quest_level,
                    required_level, required_reputation, icon_path, description, info_text, info2_text,
                    receiver_display_name, faction, allow_nazgrek, allow_zulkis, requires_turn_in,
                    auto_complete, draft, enabled, sort_order, notes, source_file, source_symbol,
                    source_import_fingerprint, source_imported_at)
                VALUES (
                    @giver_id, @quest_key, @quest_name, @title, @quest_type, @category, @quest_level,
                    @required_level, @required_reputation, @icon_path, @description, @info_text, @info2_text,
                    @receiver_display_name, @faction, @allow_nazgrek, @allow_zulkis, @requires_turn_in,
                    @auto_complete, FALSE, TRUE,
                    (SELECT COALESCE(MAX(sort_order), -1) + 1 FROM quests WHERE quest_giver_id = @giver_id),
                    @notes, @source_file, @source_symbol, @fingerprint, CURRENT_TIMESTAMP)
                RETURNING id", connection, transaction);
            AddQuestParameters(insert, giverId, source, quest);
            return Convert.ToInt32(insert.ExecuteScalar(), CultureInfo.InvariantCulture);
        }

        private static void AddSourceParameters(NpgsqlCommand command, SourceRecord source)
        {
            command.Parameters.AddWithValue("giver_key", source.GiverKey);
            command.Parameters.AddWithValue("display_name", source.DisplayName);
            command.Parameters.AddWithValue("library_name", source.LibraryName);
            command.Parameters.AddWithValue("source_file", source.RelativePath);
            command.Parameters.AddWithValue("source_kind", source.SourceKind);
            command.Parameters.AddWithValue("fingerprint", source.Fingerprint);
            command.Parameters.AddWithValue("unit_code", source.UnitCode ?? "");
            command.Parameters.AddWithValue("placed_variable", source.PlacedUnitVariable ?? "");
            command.Parameters.AddWithValue("notes", source.Notes);
        }

        private static void AddQuestParameters(NpgsqlCommand command, int giverId, SourceRecord source, ParsedQuest quest)
        {
            command.Parameters.AddWithValue("giver_id", giverId);
            command.Parameters.AddWithValue("quest_key", quest.QuestKey);
            command.Parameters.AddWithValue("quest_name", quest.QuestName);
            command.Parameters.AddWithValue("title", quest.Title);
            command.Parameters.AddWithValue("quest_type", quest.QuestType);
            command.Parameters.AddWithValue("category", quest.Category);
            command.Parameters.AddWithValue("quest_level", Math.Max(0, quest.QuestLevel));
            command.Parameters.AddWithValue("required_level", Math.Max(0, quest.RequiredLevel));
            command.Parameters.AddWithValue("required_reputation", Math.Max(-20000, Math.Min(20000, quest.RequiredReputation)));
            command.Parameters.AddWithValue("icon_path", quest.IconPath ?? "");
            command.Parameters.AddWithValue("description", quest.Description ?? "");
            command.Parameters.AddWithValue("info_text", quest.InfoText ?? "");
            command.Parameters.AddWithValue("info2_text", quest.Info2Text ?? "");
            command.Parameters.AddWithValue("receiver_display_name", quest.ReceiverDisplayName ?? "");
            command.Parameters.AddWithValue("faction", quest.Faction ?? "");
            command.Parameters.AddWithValue("allow_nazgrek", quest.AllowNazgrek);
            command.Parameters.AddWithValue("allow_zulkis", quest.AllowZulkis);
            command.Parameters.AddWithValue("requires_turn_in", quest.RequiresTurnIn);
            command.Parameters.AddWithValue("auto_complete", quest.AutoComplete);
            command.Parameters.AddWithValue("notes", "Read-only projection of " + source.RelativePath + "; runtime behavior remains source-owned.");
            command.Parameters.AddWithValue("source_file", source.RelativePath);
            command.Parameters.AddWithValue("source_symbol", quest.SourceSymbol);
            command.Parameters.AddWithValue("fingerprint", source.Fingerprint);
        }

        private static ExistingGiver FindGiver(NpgsqlConnection connection, NpgsqlTransaction transaction, SourceRecord source)
        {
            using var command = new NpgsqlCommand(@"
                SELECT id, ownership_mode, source_import_fingerprint
                FROM quest_givers
                WHERE source_file = @source_file OR library_name = @library_name OR giver_key = @giver_key
                ORDER BY CASE WHEN source_file = @source_file THEN 0 WHEN library_name = @library_name THEN 1 ELSE 2 END
                LIMIT 1", connection, transaction);
            command.Parameters.AddWithValue("source_file", source.RelativePath);
            command.Parameters.AddWithValue("library_name", source.LibraryName);
            command.Parameters.AddWithValue("giver_key", source.GiverKey);
            using var reader = command.ExecuteReader();
            return reader.Read()
                ? new ExistingGiver { Id = reader.GetInt32(0), OwnershipMode = reader.GetString(1), Fingerprint = reader.GetString(2) }
                : null;
        }

        private static int? FindImportedQuestId(NpgsqlConnection connection, NpgsqlTransaction transaction,
            int giverId, string sourceSymbol)
        {
            using var command = new NpgsqlCommand(@"
                SELECT id FROM quests
                WHERE quest_giver_id = @giver_id AND source_symbol = @source_symbol
                LIMIT 1", connection, transaction);
            command.Parameters.AddWithValue("giver_id", giverId);
            command.Parameters.AddWithValue("source_symbol", sourceSymbol);
            object value = command.ExecuteScalar();
            return value == null || value == DBNull.Value ? null : Convert.ToInt32(value, CultureInfo.InvariantCulture);
        }

        private static Dictionary<string, List<int>> LoadQuestIdsBySymbol(NpgsqlConnection connection, NpgsqlTransaction transaction)
        {
            var result = new Dictionary<string, List<int>>(StringComparer.OrdinalIgnoreCase);
            using var command = new NpgsqlCommand("SELECT id, source_symbol FROM quests WHERE source_symbol <> ''", connection, transaction);
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                string symbol = reader.GetString(1);
                if (!result.TryGetValue(symbol, out var ids))
                {
                    ids = new List<int>();
                    result[symbol] = ids;
                }
                ids.Add(reader.GetInt32(0));
            }
            return result;
        }

        private static void UpdateReceiver(NpgsqlConnection connection, NpgsqlTransaction transaction, int questId, int? receiverId)
        {
            using var command = new NpgsqlCommand("UPDATE quests SET receiver_giver_id = @receiver_id WHERE id = @quest_id", connection, transaction);
            command.Parameters.AddWithValue("quest_id", questId);
            command.Parameters.AddWithValue("receiver_id", receiverId.HasValue ? (object)receiverId.Value : DBNull.Value);
            command.ExecuteNonQuery();
        }

        private static void ReplaceSourceLinks(NpgsqlConnection connection, NpgsqlTransaction transaction,
            int giverId, SourceRecord source)
        {
            using (var delete = new NpgsqlCommand(@"
                DELETE FROM quest_we_dependencies
                WHERE quest_giver_id = @giver_id AND source_evidence LIKE 'Source sync:%'", connection, transaction))
            {
                delete.Parameters.AddWithValue("giver_id", giverId);
                delete.ExecuteNonQuery();
            }
            foreach (string library in source.RequiredLibraries.Distinct(StringComparer.OrdinalIgnoreCase))
            {
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_we_dependencies (
                        quest_giver_id, quest_id, dependency_kind, symbol, expected_value,
                        verified, manual_follow_up, source_evidence)
                    VALUES (@giver_id, NULL, 'other', @symbol, 'JASS library dependency',
                            TRUE, '', @evidence)
                    ON CONFLICT (quest_giver_id, dependency_kind, symbol) DO NOTHING", connection, transaction);
                insert.Parameters.AddWithValue("giver_id", giverId);
                insert.Parameters.AddWithValue("symbol", "library:" + library);
                insert.Parameters.AddWithValue("evidence", "Source sync:" + source.RelativePath);
                insert.ExecuteNonQuery();
            }
        }

        private static void ReplacePrerequisites(NpgsqlConnection connection, NpgsqlTransaction transaction,
            ParsedQuest quest, IReadOnlyDictionary<string, List<int>> idsBySymbol,
            QuestSourceSyncResult result, string relativePath)
        {
            using (var delete = new NpgsqlCommand("DELETE FROM quest_prerequisites WHERE quest_id = @quest_id", connection, transaction))
            {
                delete.Parameters.AddWithValue("quest_id", quest.DatabaseId);
                delete.ExecuteNonQuery();
            }
            foreach (string symbol in quest.PrerequisiteSymbols.Where(s => !string.IsNullOrWhiteSpace(s)).Distinct(StringComparer.OrdinalIgnoreCase))
            {
                if ((!idsBySymbol.TryGetValue(symbol, out var ids) || ids.Count != 1) && symbol.StartsWith("q", StringComparison.Ordinal))
                {
                    int separator = symbol.IndexOf('_');
                    if (separator > 1) idsBySymbol.TryGetValue(symbol.Substring(separator + 1), out ids);
                }
                if (ids == null || ids.Count != 1)
                {
                    result.Warnings.Add($"{relativePath}:{quest.SourceSymbol}: prerequisite '{symbol}' was not uniquely resolved.");
                    continue;
                }
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_prerequisites (quest_id, prerequisite_quest_id)
                    VALUES (@quest_id, @prerequisite_id)
                    ON CONFLICT DO NOTHING", connection, transaction);
                insert.Parameters.AddWithValue("quest_id", quest.DatabaseId);
                insert.Parameters.AddWithValue("prerequisite_id", ids[0]);
                insert.ExecuteNonQuery();
            }
        }

        private static IEnumerable<SourceFile> EnumerateSources(string questsRoot)
        {
            foreach (var pair in new[]
            {
                new { Folder = "QuestGivers", Kind = "quest_giver" },
                new { Folder = "GenericQuests", Kind = "generic_quest" }
            })
            {
                string root = Path.Combine(questsRoot, pair.Folder);
                if (!Directory.Exists(root)) continue;
                foreach (string path in Directory.EnumerateFiles(root, "*.j", SearchOption.AllDirectories)
                             .Where(IsActiveSourcePath).OrderBy(p => p, StringComparer.OrdinalIgnoreCase))
                {
                    string kind = path.IndexOf(Path.DirectorySeparatorChar + "Vendors" + Path.DirectorySeparatorChar,
                        StringComparison.OrdinalIgnoreCase) >= 0 ? "vendor_quest_giver" : pair.Kind;
                    yield return new SourceFile { FullPath = path, Kind = kind };
                }
            }
        }

        private static bool IsActiveSourcePath(string path)
        {
            string[] parts = path.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            if (parts.Any(part => ExcludedDirectoryNames.Contains(part, StringComparer.OrdinalIgnoreCase))) return false;
            string file = Path.GetFileNameWithoutExtension(path);
            return !file.StartsWith("_", StringComparison.OrdinalIgnoreCase)
                   && file.IndexOf("old", StringComparison.OrdinalIgnoreCase) < 0
                   && file.IndexOf("backup", StringComparison.OrdinalIgnoreCase) < 0
                   && file.IndexOf("test", StringComparison.OrdinalIgnoreCase) < 0;
        }

        private static string ResolveQuestsRoot(string selectedPath)
        {
            if (string.IsNullOrWhiteSpace(selectedPath)) throw new DirectoryNotFoundException("Select the repository or QuestsAndDialogs folder.");
            string fullPath = Path.GetFullPath(selectedPath);
            string candidate = Path.Combine(fullPath, "QuestsAndDialogs");
            if (HasSourceRoots(candidate)) return candidate;
            if (HasSourceRoots(fullPath)) return fullPath;
            throw new DirectoryNotFoundException("The selected folder does not contain QuestsAndDialogs/QuestGivers or QuestsAndDialogs/GenericQuests.");
        }

        private static bool HasSourceRoots(string path)
        {
            return Directory.Exists(path) &&
                   (Directory.Exists(Path.Combine(path, "QuestGivers")) || Directory.Exists(Path.Combine(path, "GenericQuests")));
        }

        private static List<ParsedCall> ExtractCalls(string code, IEnumerable<string> names)
        {
            var calls = new List<ParsedCall>();
            foreach (string name in names)
            {
                int search = 0;
                while (search < code.Length)
                {
                    int start = code.IndexOf(name, search, StringComparison.Ordinal);
                    if (start < 0) break;
                    if ((start > 0 && IsIdentifierCharacter(code[start - 1])) ||
                        (start + name.Length < code.Length && IsIdentifierCharacter(code[start + name.Length])))
                    {
                        search = start + name.Length;
                        continue;
                    }
                    int open = start + name.Length;
                    while (open < code.Length && char.IsWhiteSpace(code[open])) open++;
                    if (open >= code.Length || code[open] != '(')
                    {
                        search = start + name.Length;
                        continue;
                    }
                    int close = FindClosingParenthesis(code, open);
                    if (close < 0) break;
                    calls.Add(new ParsedCall
                    {
                        Name = name,
                        Position = start,
                        Arguments = SplitArguments(code.Substring(open + 1, close - open - 1)),
                        AssignmentTarget = FindAssignmentTarget(code, start)
                    });
                    search = close + 1;
                }
            }
            return calls;
        }

        private static int FindClosingParenthesis(string text, int open)
        {
            int depth = 0;
            bool inString = false;
            bool escaped = false;
            for (int index = open; index < text.Length; index++)
            {
                char c = text[index];
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (c == '\\') escaped = true;
                    else if (c == '"') inString = false;
                    continue;
                }
                if (c == '"') inString = true;
                else if (c == '(') depth++;
                else if (c == ')' && --depth == 0) return index;
            }
            return -1;
        }

        private static List<string> SplitArguments(string arguments)
        {
            var result = new List<string>();
            int start = 0;
            int depth = 0;
            bool inString = false;
            bool escaped = false;
            for (int index = 0; index < arguments.Length; index++)
            {
                char c = arguments[index];
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (c == '\\') escaped = true;
                    else if (c == '"') inString = false;
                    continue;
                }
                if (c == '"') inString = true;
                else if (c == '(' || c == '[') depth++;
                else if (c == ')' || c == ']') depth--;
                else if (c == ',' && depth == 0)
                {
                    result.Add(arguments.Substring(start, index - start).Trim());
                    start = index + 1;
                }
            }
            result.Add(arguments.Substring(start).Trim());
            return result;
        }

        private static string FindAssignmentTarget(string code, int callStart)
        {
            int lineStart = code.LastIndexOf('\n', Math.Max(0, callStart - 1));
            string prefix = code.Substring(lineStart + 1, callStart - lineStart - 1);
            Match match = Regex.Match(prefix, @"(?:\bset|\blocal\s+[A-Za-z][A-Za-z0-9_]*)\s+([A-Za-z][A-Za-z0-9_]*)\s*=\s*$");
            return match.Success ? match.Groups[1].Value : "";
        }

        private static Dictionary<string, string> ParseStringConstants(string code)
        {
            var constants = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (Match match in Regex.Matches(code,
                         @"(?m)^\s*(?:public\s+|private\s+)?constant\s+string\s+([A-Za-z][A-Za-z0-9_]*)\s*=\s*([^\r\n]+)"))
            {
                string value = ResolveString(match.Groups[2].Value.Trim(), constants);
                if (!string.IsNullOrEmpty(value) || IsEmptyStringExpression(match.Groups[2].Value))
                {
                    constants[match.Groups[1].Value] = value;
                }
            }
            return constants;
        }

        private static string ResolveString(string expression, IReadOnlyDictionary<string, string> constants)
        {
            if (string.IsNullOrWhiteSpace(expression)) return "";
            var parts = SplitTopLevelPlus(expression);
            var builder = new StringBuilder();
            foreach (string rawPart in parts)
            {
                string part = rawPart.Trim();
                if (part.Length >= 2 && part[0] == '"' && part[part.Length - 1] == '"')
                {
                    builder.Append(DecodeJassString(part.Substring(1, part.Length - 2)));
                }
                else if (constants.TryGetValue(part, out string value))
                {
                    builder.Append(value);
                }
                else
                {
                    return "";
                }
            }
            return builder.ToString();
        }

        private static List<string> SplitTopLevelPlus(string expression)
        {
            var parts = new List<string>();
            int start = 0;
            int depth = 0;
            bool inString = false;
            bool escaped = false;
            for (int index = 0; index < expression.Length; index++)
            {
                char c = expression[index];
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (c == '\\') escaped = true;
                    else if (c == '"') inString = false;
                    continue;
                }
                if (c == '"') inString = true;
                else if (c == '(') depth++;
                else if (c == ')') depth--;
                else if (c == '+' && depth == 0)
                {
                    parts.Add(expression.Substring(start, index - start));
                    start = index + 1;
                }
            }
            parts.Add(expression.Substring(start));
            return parts;
        }

        private static string DecodeJassString(string value)
        {
            var builder = new StringBuilder();
            bool escaped = false;
            foreach (char c in value)
            {
                if (!escaped)
                {
                    if (c == '\\') escaped = true;
                    else builder.Append(c);
                    continue;
                }
                escaped = false;
                if (c == 'n') builder.Append('\n');
                else if (c == 'r') builder.Append('\r');
                else if (c == 't') builder.Append('\t');
                else builder.Append(c);
            }
            if (escaped) builder.Append('\\');
            return builder.ToString();
        }

        private static string MaskComments(string source)
        {
            var chars = source.ToCharArray();
            bool inString = false;
            bool escaped = false;
            for (int index = 0; index < chars.Length; index++)
            {
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (chars[index] == '\\') escaped = true;
                    else if (chars[index] == '"') inString = false;
                    continue;
                }
                if (chars[index] == '"')
                {
                    inString = true;
                    continue;
                }
                if (chars[index] == '/' && index + 1 < chars.Length && chars[index + 1] == '/')
                {
                    while (index < chars.Length && chars[index] != '\n') chars[index++] = ' ';
                }
                else if (chars[index] == '/' && index + 1 < chars.Length && chars[index + 1] == '*')
                {
                    chars[index++] = ' ';
                    chars[index] = ' ';
                    while (++index < chars.Length)
                    {
                        if (chars[index] == '*' && index + 1 < chars.Length && chars[index + 1] == '/')
                        {
                            chars[index] = chars[index + 1] = ' ';
                            index++;
                            break;
                        }
                        if (chars[index] != '\r' && chars[index] != '\n') chars[index] = ' ';
                    }
                }
            }
            return new string(chars);
        }

        private static string NormalizeSymbol(string expression, string fallback)
        {
            string symbol = NormalizeBinding(expression);
            if (Regex.IsMatch(symbol, @"^[A-Za-z][A-Za-z0-9_]*$")) return symbol;
            return FitIdentifier(fallback, 128);
        }

        private static string NormalizeBinding(string expression)
        {
            return (expression ?? "").Trim().Replace(" ", "");
        }

        private static bool IsNullExpression(string expression)
        {
            return string.IsNullOrWhiteSpace(expression) || string.Equals(expression.Trim(), "null", StringComparison.OrdinalIgnoreCase);
        }

        private static string ParseRawcode(string expression)
        {
            Match match = Regex.Match(expression ?? "", @"'([^']{4})'");
            return match.Success ? match.Groups[1].Value : "";
        }

        private static bool ParseBool(string expression, bool fallback)
        {
            if (bool.TryParse((expression ?? "").Trim(), out bool value)) return value;
            return fallback;
        }

        private static int ParseInt(string expression, int fallback)
        {
            return int.TryParse((expression ?? "").Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out int value)
                ? value
                : fallback;
        }

        private static bool IsEmptyStringExpression(string expression)
        {
            return string.Equals((expression ?? "").Trim(), "\"\"", StringComparison.Ordinal);
        }

        private static string InferObjectiveType(string text)
        {
            string lower = (text ?? "").ToLowerInvariant();
            if (lower.StartsWith("kill ") || lower.Contains("defeat ")) return "kill";
            if (lower.StartsWith("bring ") || lower.StartsWith("collect ") || lower.StartsWith("gather ")) return "item";
            if (lower.StartsWith("talk ") || lower.StartsWith("speak ") || lower.StartsWith("meet ")) return "talk";
            if (lower.StartsWith("escort ")) return "escort";
            if (lower.StartsWith("find ") || lower.StartsWith("locate ")) return "find";
            if (lower.StartsWith("go to ") || lower.StartsWith("travel ") || lower.StartsWith("enter ")) return "goto";
            if (lower.Contains("investigate")) return "investigate";
            return "manual";
        }

        private static int InferAmount(string text)
        {
            Match progress = Regex.Match(text ?? "", @"\(\s*\d+\s*/\s*(\d+)\s*\)");
            if (progress.Success && int.TryParse(progress.Groups[1].Value, out int total)) return Math.Max(1, total);
            Match number = Regex.Match(text ?? "", @"\b(\d+)\b");
            return number.Success && int.TryParse(number.Groups[1].Value, out int amount) ? Math.Max(1, amount) : 1;
        }

        private static string HumanizeLibraryName(string libraryName)
        {
            string value = Regex.Replace(libraryName ?? "", @"^q(?=[A-Z])", "");
            value = Regex.Replace(value, @"(?<=[a-z0-9])(?=[A-Z])", " ");
            value = Regex.Replace(value, @"(?<=[A-Z])(?=[A-Z][a-z])", " ");
            return string.IsNullOrWhiteSpace(value) ? libraryName : value;
        }

        private static string HumanizeIdentifier(string identifier)
        {
            string value = (identifier ?? "").Trim('_').Replace('_', ' ').ToLowerInvariant();
            return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(value);
        }

        private static string FitIdentifier(string value, int maxLength)
        {
            string identifier = Regex.Replace(value ?? "", @"[^A-Za-z0-9_]", "_");
            identifier = Regex.Replace(identifier, @"_+", "_").Trim('_');
            if (string.IsNullOrWhiteSpace(identifier)) identifier = "ImportedQuest";
            if (!char.IsLetter(identifier[0])) identifier = "Q_" + identifier;
            return identifier.Length <= maxLength ? identifier : identifier.Substring(0, maxLength);
        }

        private static string ComputeSha256(string text)
        {
            byte[] bytes = SHA256.HashData(Encoding.UTF8.GetBytes(text ?? ""));
            return Convert.ToHexString(bytes).ToLowerInvariant();
        }

        private static void DeduplicateMessages(List<string> messages)
        {
            var unique = messages.Distinct(StringComparer.OrdinalIgnoreCase).ToList();
            messages.Clear();
            messages.AddRange(unique);
        }

        private static bool IsIdentifierCharacter(char c) => char.IsLetterOrDigit(c) || c == '_';

        private sealed class SourceFile
        {
            public string FullPath { get; set; } = "";
            public string Kind { get; set; } = "";
        }

        private sealed class SourceRecord
        {
            public string RelativePath { get; set; } = "";
            public string SourceKind { get; set; } = "";
            public string LibraryName { get; set; } = "";
            public string GiverKey { get; set; } = "";
            public string DisplayName { get; set; } = "";
            public string Fingerprint { get; set; } = "";
            public string PrimaryBinding { get; set; } = "";
            public string UnitCode { get; set; } = "";
            public string PlacedUnitVariable { get; set; } = "";
            public string Notes { get; set; } = "";
            public bool RegistersForGenericQuest { get; set; }
            public List<string> RequiredLibraries { get; } = new List<string>();
            public List<ParsedQuest> Quests { get; } = new List<ParsedQuest>();
        }

        private sealed class ParsedQuest
        {
            public int DatabaseId { get; set; }
            public int Position { get; set; }
            public string AssignmentTarget { get; set; } = "";
            public string SourceSymbol { get; set; } = "";
            public string QuestKey { get; set; } = "";
            public string QuestName { get; set; } = "";
            public string Title { get; set; } = "";
            public string QuestType { get; set; } = "normal";
            public string Category { get; set; } = "general";
            public int QuestLevel { get; set; } = 1;
            public int RequiredLevel { get; set; } = 1;
            public int RequiredReputation { get; set; }
            public string IconPath { get; set; } = "";
            public string Description { get; set; } = "";
            public string InfoText { get; set; } = "";
            public string Info2Text { get; set; } = "";
            public string GiverBinding { get; set; } = "";
            public string ReceiverBinding { get; set; } = "";
            public string ReceiverDisplayName { get; set; } = "";
            public string Faction { get; set; } = "";
            public bool AllowNazgrek { get; set; } = true;
            public bool AllowZulkis { get; set; }
            public bool RequiresTurnIn { get; set; } = true;
            public bool AutoComplete { get; set; }
            public int SortOrder { get; set; }
            public ParsedReward Reward { get; set; } = new ParsedReward();
            public List<ParsedObjective> Objectives { get; } = new List<ParsedObjective>();
            public List<string> PrerequisiteSymbols { get; } = new List<string>();
        }

        private sealed class ParsedObjective
        {
            public string Text { get; set; } = "";
            public string ObjectiveType { get; set; } = "manual";
            public int Amount { get; set; } = 1;
            public string ItemCode { get; set; } = "";
            public string ExternalHook { get; set; } = "";
            public string Notes { get; set; } = "";
        }

        private sealed class ParsedReward
        {
            public bool XpActive { get; set; } = true;
            public int XpAdjust { get; set; }
            public bool GoldActive { get; set; } = true;
            public int GoldAdjust { get; set; }
            public bool ArenaActive { get; set; }
            public int ArenaAdjust { get; set; }
            public bool ReputationActive { get; set; }
            public int ReputationAdjust { get; set; }
            public bool ReputationLinked { get; set; }
            public string ItemCode { get; set; } = "";
        }

        private sealed class ParsedCall
        {
            public string Name { get; set; } = "";
            public int Position { get; set; }
            public List<string> Arguments { get; set; } = new List<string>();
            public string AssignmentTarget { get; set; } = "";
        }

        private sealed class ExistingGiver
        {
            public int Id { get; set; }
            public string OwnershipMode { get; set; } = "";
            public string Fingerprint { get; set; } = "";
        }
    }

    public sealed class QuestSourceSyncResult
    {
        public int FilesScanned { get; set; }
        public int QuestDefinitionsFound { get; set; }
        public int GiversSynchronized { get; set; }
        public int GiversCreated { get; set; }
        public int GiversUpdated { get; set; }
        public int QuestsCreated { get; set; }
        public int QuestsUpdated { get; set; }
        public int UnchangedSources { get; set; }
        public int SkippedProtectedSources { get; set; }
        public List<string> Warnings { get; } = new List<string>();
        public List<string> Errors { get; } = new List<string>();
    }
}
