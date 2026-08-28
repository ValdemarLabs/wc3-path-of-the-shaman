using System;
using System.Collections.Generic;
using System.Linq;
using Npgsql;
using NpgsqlTypes;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database boundary for the WC3 Manager quest designer.
    /// </summary>
    public sealed class QuestDesignerRepository
    {
        private readonly string _connectionString;

        public QuestDesignerRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public bool SchemaExists()
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT
                    (SELECT COUNT(*) = 9
                     FROM information_schema.tables
                     WHERE table_schema = 'public'
                       AND table_name IN (
                           'quest_givers', 'quests', 'quest_objectives', 'quest_rewards',
                           'quest_prerequisites', 'quest_voicelines', 'quest_sequences',
                           'quest_sequence_steps', 'quest_we_dependencies'))
                    AND EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_schema = 'public' AND table_name = 'quest_givers'
                          AND column_name = 'last_export_fingerprint')
                    AND EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_schema = 'public' AND table_name = 'quests'
                          AND column_name = 'required_reputation')
                    AND EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_schema = 'public' AND table_name = 'quest_givers'
                          AND column_name = 'source_import_fingerprint')
                    AND EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_schema = 'public' AND table_name = 'quests'
                          AND column_name = 'source_symbol')", conn);
            return Convert.ToBoolean(cmd.ExecuteScalar());
        }

        public List<QuestGiverDefinition> GetGivers(bool enabledOnly = false)
        {
            var result = new List<QuestGiverDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, giver_key, display_name, library_name, unit_code, placed_unit_variable,
                       zone_id, faction, allow_nazgrek, allow_zulkis, dialog_range, dialog_cooldown,
                       use_dialog_camera, use_cinematic_mode, camera_distance, camera_z_offset,
                       camera_angle, camera_rotation_offset, camera_far_z, camera_fov,
                       camera_block_radius, camera_block_check, enabled, notes, created_at, updated_at,
                       ownership_mode, source_file, source_kind, source_import_fingerprint, source_imported_at
                FROM quest_givers
                WHERE (@enabled_only = FALSE OR enabled = TRUE)
                ORDER BY display_name, giver_key", conn);
            cmd.Parameters.AddWithValue("enabled_only", enabledOnly);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(MapGiver(reader));
            }
            return result;
        }

        public QuestGiverDefinition GetGiver(int id)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, giver_key, display_name, library_name, unit_code, placed_unit_variable,
                       zone_id, faction, allow_nazgrek, allow_zulkis, dialog_range, dialog_cooldown,
                       use_dialog_camera, use_cinematic_mode, camera_distance, camera_z_offset,
                       camera_angle, camera_rotation_offset, camera_far_z, camera_fov,
                       camera_block_radius, camera_block_check, enabled, notes, created_at, updated_at,
                       ownership_mode, source_file, source_kind, source_import_fingerprint, source_imported_at
                FROM quest_givers WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", id);
            using var reader = cmd.ExecuteReader();
            return reader.Read() ? MapGiver(reader) : null;
        }

        public int SaveGiver(QuestGiverDefinition giver)
        {
            ValidateGiver(giver);
            using var conn = OpenConnection();
            string sql = giver.Id == 0
                ? @"INSERT INTO quest_givers (
                        giver_key, display_name, library_name, unit_code, placed_unit_variable, zone_id,
                        faction, allow_nazgrek, allow_zulkis, dialog_range, dialog_cooldown,
                        use_dialog_camera, use_cinematic_mode, camera_distance, camera_z_offset,
                        camera_angle, camera_rotation_offset, camera_far_z, camera_fov,
                        camera_block_radius, camera_block_check, enabled, notes, ownership_mode, source_file)
                    VALUES (
                        @giver_key, @display_name, @library_name, @unit_code, @placed_unit_variable, @zone_id,
                        @faction, @allow_nazgrek, @allow_zulkis, @dialog_range, @dialog_cooldown,
                        @use_dialog_camera, @use_cinematic_mode, @camera_distance, @camera_z_offset,
                        @camera_angle, @camera_rotation_offset, @camera_far_z, @camera_fov,
                        @camera_block_radius, @camera_block_check, @enabled, @notes, @ownership_mode, @source_file)
                    RETURNING id"
                : @"UPDATE quest_givers SET
                        giver_key = @giver_key, display_name = @display_name, library_name = @library_name,
                        unit_code = @unit_code, placed_unit_variable = @placed_unit_variable, zone_id = @zone_id,
                        faction = @faction, allow_nazgrek = @allow_nazgrek, allow_zulkis = @allow_zulkis,
                        dialog_range = @dialog_range, dialog_cooldown = @dialog_cooldown,
                        use_dialog_camera = @use_dialog_camera, use_cinematic_mode = @use_cinematic_mode,
                        camera_distance = @camera_distance, camera_z_offset = @camera_z_offset,
                        camera_angle = @camera_angle, camera_rotation_offset = @camera_rotation_offset,
                        camera_far_z = @camera_far_z, camera_fov = @camera_fov,
                        camera_block_radius = @camera_block_radius, camera_block_check = @camera_block_check,
                        enabled = @enabled, notes = @notes,
                        ownership_mode = @ownership_mode, source_file = @source_file
                    WHERE id = @id RETURNING id";
            using var cmd = new NpgsqlCommand(sql, conn);
            AddGiverParameters(cmd, giver);
            giver.Id = Convert.ToInt32(cmd.ExecuteScalar());
            return giver.Id;
        }

        public void DeleteGiver(int id)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand("DELETE FROM quest_givers WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public string GetLastExportFingerprint(int giverId)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(
                "SELECT last_export_fingerprint FROM quest_givers WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", giverId);
            return Convert.ToString(cmd.ExecuteScalar()) ?? "";
        }

        public void MarkGiverExported(int giverId, string fingerprint)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                UPDATE quest_givers
                SET last_export_fingerprint = @fingerprint,
                    last_exported_at = CURRENT_TIMESTAMP
                WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", giverId);
            cmd.Parameters.AddWithValue("fingerprint", fingerprint);
            cmd.ExecuteNonQuery();
        }

        public List<QuestDefinition> GetQuests(int? giverId = null, bool exportableOnly = false)
        {
            var result = new List<QuestDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, quest_giver_id, quest_key, quest_name, title, quest_type, category,
                       quest_level, required_level, required_reputation, icon_path, description, info_text, info2_text,
                       receiver_giver_id, receiver_display_name, zone_id, faction,
                       allow_nazgrek, allow_zulkis, requires_turn_in, auto_complete, fail_reason,
                       draft, enabled, sort_order, notes, created_at, updated_at,
                       source_file, source_symbol, source_import_fingerprint, source_imported_at
                FROM quests
                WHERE (@giver_id IS NULL OR quest_giver_id = @giver_id)
                  AND (@exportable_only = FALSE OR (enabled = TRUE AND draft = FALSE))
                ORDER BY quest_giver_id, sort_order, title", conn);
            AddNullableInt(cmd, "giver_id", giverId);
            cmd.Parameters.AddWithValue("exportable_only", exportableOnly);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(MapQuest(reader));
            }
            return result;
        }

        public QuestDefinition GetQuest(int id)
        {
            return GetQuests().FirstOrDefault(q => q.Id == id);
        }

        public int GetNextQuestSortOrder(int giverId)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(
                "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM quests WHERE quest_giver_id = @giver_id", conn);
            cmd.Parameters.AddWithValue("giver_id", giverId);
            return Convert.ToInt32(cmd.ExecuteScalar());
        }

        public int SaveQuest(
            QuestDefinition quest,
            IEnumerable<QuestObjectiveDefinition> objectives,
            QuestRewardDefinition reward,
            IEnumerable<int> prerequisiteIds)
        {
            var objectiveList = objectives.OrderBy(o => o.DisplayOrder).ToList();
            var prerequisiteList = prerequisiteIds.Distinct().ToList();
            ValidateQuest(quest, objectiveList, prerequisiteList);

            using var conn = OpenConnection();
            using var transaction = conn.BeginTransaction();
            try
            {
                if (quest.Id != 0 && WouldCreatePrerequisiteCycle(conn, transaction, quest.Id, prerequisiteList))
                {
                    throw new InvalidOperationException("The selected prerequisites create a quest dependency cycle.");
                }
                if (quest.Category == "story" && HasDailyOrRepeatablePrerequisite(conn, transaction, prerequisiteList))
                {
                    throw new InvalidOperationException("A story quest cannot depend on a daily or repeatable quest.");
                }

                string sql = quest.Id == 0
                    ? @"INSERT INTO quests (
                            quest_giver_id, quest_key, quest_name, title, quest_type, category,
                            quest_level, required_level, required_reputation, icon_path, description, info_text, info2_text,
                            receiver_giver_id, receiver_display_name, zone_id, faction,
                            allow_nazgrek, allow_zulkis, requires_turn_in, auto_complete, fail_reason,
                            draft, enabled, sort_order, notes)
                        VALUES (
                            @quest_giver_id, @quest_key, @quest_name, @title, @quest_type, @category,
                            @quest_level, @required_level, @required_reputation, @icon_path, @description, @info_text, @info2_text,
                            @receiver_giver_id, @receiver_display_name, @zone_id, @faction,
                            @allow_nazgrek, @allow_zulkis, @requires_turn_in, @auto_complete, @fail_reason,
                            @draft, @enabled, @sort_order, @notes)
                        RETURNING id"
                    : @"UPDATE quests SET
                            quest_giver_id = @quest_giver_id, quest_key = @quest_key,
                            quest_name = @quest_name, title = @title, quest_type = @quest_type,
                            category = @category, quest_level = @quest_level,
                            required_level = @required_level, required_reputation = @required_reputation,
                            icon_path = @icon_path,
                            description = @description, info_text = @info_text, info2_text = @info2_text,
                            receiver_giver_id = @receiver_giver_id,
                            receiver_display_name = @receiver_display_name, zone_id = @zone_id,
                            faction = @faction, allow_nazgrek = @allow_nazgrek,
                            allow_zulkis = @allow_zulkis, requires_turn_in = @requires_turn_in,
                            auto_complete = @auto_complete, fail_reason = @fail_reason,
                            draft = @draft, enabled = @enabled, sort_order = @sort_order, notes = @notes
                        WHERE id = @id RETURNING id";
                using (var cmd = new NpgsqlCommand(sql, conn, transaction))
                {
                    AddQuestParameters(cmd, quest);
                    quest.Id = Convert.ToInt32(cmd.ExecuteScalar());
                }

                ReplaceObjectives(conn, transaction, quest.Id, objectiveList);
                SaveReward(conn, transaction, quest.Id, reward ?? new QuestRewardDefinition());
                ReplacePrerequisites(conn, transaction, quest.Id, prerequisiteList);
                transaction.Commit();
                return quest.Id;
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        public void DeleteQuest(int id)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand("DELETE FROM quests WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public List<QuestObjectiveDefinition> GetObjectives(int questId)
        {
            var result = new List<QuestObjectiveDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, quest_id, objective_key, display_order, objective_type, text, amount,
                       item_code, unit_code, target_variable, target_name, region_variable, zone_id,
                       faction, required_reputation, completion_mode, external_hook, notes
                FROM quest_objectives WHERE quest_id = @quest_id ORDER BY display_order", conn);
            cmd.Parameters.AddWithValue("quest_id", questId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(new QuestObjectiveDefinition
                {
                    Id = reader.GetInt32(0),
                    QuestId = reader.GetInt32(1),
                    ObjectiveKey = reader.GetString(2),
                    DisplayOrder = reader.GetInt32(3),
                    ObjectiveType = reader.GetString(4),
                    Text = reader.GetString(5),
                    Amount = reader.GetInt32(6),
                    ItemCode = GetString(reader, 7),
                    UnitCode = GetString(reader, 8),
                    TargetVariable = GetString(reader, 9),
                    TargetName = reader.GetString(10),
                    RegionVariable = GetString(reader, 11),
                    ZoneId = GetNullableInt(reader, 12),
                    Faction = reader.GetString(13),
                    RequiredReputation = reader.GetInt32(14),
                    CompletionMode = reader.GetString(15),
                    ExternalHook = GetString(reader, 16),
                    Notes = reader.GetString(17)
                });
            }
            return result;
        }

        public QuestRewardDefinition GetReward(int questId)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT quest_id, xp_active, xp_adjust, gold_active, gold_adjust,
                       arena_active, arena_adjust, reputation_active, reputation_adjust,
                       reputation_linked, item_code, custom_text
                FROM quest_rewards WHERE quest_id = @quest_id", conn);
            cmd.Parameters.AddWithValue("quest_id", questId);
            using var reader = cmd.ExecuteReader();
            if (!reader.Read())
            {
                return new QuestRewardDefinition { QuestId = questId };
            }
            return new QuestRewardDefinition
            {
                QuestId = reader.GetInt32(0),
                XpActive = reader.GetBoolean(1),
                XpAdjust = reader.GetInt32(2),
                GoldActive = reader.GetBoolean(3),
                GoldAdjust = reader.GetInt32(4),
                ArenaActive = reader.GetBoolean(5),
                ArenaAdjust = reader.GetInt32(6),
                ReputationActive = reader.GetBoolean(7),
                ReputationAdjust = reader.GetInt32(8),
                ReputationLinked = reader.GetBoolean(9),
                ItemCode = GetString(reader, 10),
                CustomText = reader.GetString(11)
            };
        }

        public List<int> GetPrerequisiteIds(int questId)
        {
            var result = new List<int>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT prerequisite_quest_id FROM quest_prerequisites
                WHERE quest_id = @quest_id ORDER BY prerequisite_quest_id", conn);
            cmd.Parameters.AddWithValue("quest_id", questId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(reader.GetInt32(0));
            }
            return result;
        }

        public List<QuestSequenceDefinition> GetSequences(int giverId, bool enabledOnly = false)
        {
            var result = new List<QuestSequenceDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, quest_giver_id, quest_id, sequence_key, display_name, purpose,
                       show_as_dialog_option, button_label, button_order, on_start_hook,
                       on_finish_hook, skippable, enabled, notes
                FROM quest_sequences
                WHERE quest_giver_id = @giver_id AND (@enabled_only = FALSE OR enabled = TRUE)
                ORDER BY button_order, display_name", conn);
            cmd.Parameters.AddWithValue("giver_id", giverId);
            cmd.Parameters.AddWithValue("enabled_only", enabledOnly);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(new QuestSequenceDefinition
                {
                    Id = reader.GetInt32(0),
                    QuestGiverId = reader.GetInt32(1),
                    QuestId = GetNullableInt(reader, 2),
                    SequenceKey = reader.GetString(3),
                    DisplayName = reader.GetString(4),
                    Purpose = reader.GetString(5),
                    ShowAsDialogOption = reader.GetBoolean(6),
                    ButtonLabel = reader.GetString(7),
                    ButtonOrder = reader.GetInt32(8),
                    OnStartHook = GetString(reader, 9),
                    OnFinishHook = GetString(reader, 10),
                    Skippable = reader.GetBoolean(11),
                    Enabled = reader.GetBoolean(12),
                    Notes = reader.GetString(13)
                });
            }
            return result;
        }

        public List<QuestSequenceStepDefinition> GetSequenceSteps(int sequenceId)
        {
            var result = new List<QuestSequenceStepDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, sequence_id, display_order, step_type, speaker_binding, speaker_name,
                       text, sound_key, voiceline_id, duration, target_binding, point_x, point_y,
                       action_hook, sound_at_unit, notes
                FROM quest_sequence_steps WHERE sequence_id = @sequence_id ORDER BY display_order", conn);
            cmd.Parameters.AddWithValue("sequence_id", sequenceId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(new QuestSequenceStepDefinition
                {
                    Id = reader.GetInt32(0),
                    SequenceId = reader.GetInt32(1),
                    DisplayOrder = reader.GetInt32(2),
                    StepType = reader.GetString(3),
                    SpeakerBinding = GetString(reader, 4),
                    SpeakerName = reader.GetString(5),
                    Text = reader.GetString(6),
                    SoundKey = reader.GetString(7),
                    VoicelineId = GetNullableInt(reader, 8),
                    Duration = reader.GetDecimal(9),
                    TargetBinding = GetString(reader, 10),
                    PointX = GetNullableDecimal(reader, 11),
                    PointY = GetNullableDecimal(reader, 12),
                    ActionHook = GetString(reader, 13),
                    SoundAtUnit = reader.GetBoolean(14),
                    Notes = reader.GetString(15)
                });
            }
            return result;
        }

        public int SaveSequence(QuestSequenceDefinition sequence, IEnumerable<QuestSequenceStepDefinition> steps)
        {
            var stepList = steps.OrderBy(s => s.DisplayOrder).ToList();
            ValidateSequence(sequence, stepList);
            using var conn = OpenConnection();
            using var transaction = conn.BeginTransaction();
            try
            {
                string sql = sequence.Id == 0
                    ? @"INSERT INTO quest_sequences (
                            quest_giver_id, quest_id, sequence_key, display_name, purpose,
                            show_as_dialog_option, button_label, button_order, on_start_hook,
                            on_finish_hook, skippable, enabled, notes)
                        VALUES (
                            @quest_giver_id, @quest_id, @sequence_key, @display_name, @purpose,
                            @show_as_dialog_option, @button_label, @button_order, @on_start_hook,
                            @on_finish_hook, @skippable, @enabled, @notes)
                        RETURNING id"
                    : @"UPDATE quest_sequences SET
                            quest_giver_id = @quest_giver_id, quest_id = @quest_id,
                            sequence_key = @sequence_key, display_name = @display_name,
                            purpose = @purpose, show_as_dialog_option = @show_as_dialog_option,
                            button_label = @button_label, button_order = @button_order,
                            on_start_hook = @on_start_hook, on_finish_hook = @on_finish_hook,
                            skippable = @skippable, enabled = @enabled, notes = @notes
                        WHERE id = @id RETURNING id";
                using (var cmd = new NpgsqlCommand(sql, conn, transaction))
                {
                    AddSequenceParameters(cmd, sequence);
                    sequence.Id = Convert.ToInt32(cmd.ExecuteScalar());
                }

                using (var delete = new NpgsqlCommand(
                    "DELETE FROM quest_sequence_steps WHERE sequence_id = @sequence_id", conn, transaction))
                {
                    delete.Parameters.AddWithValue("sequence_id", sequence.Id);
                    delete.ExecuteNonQuery();
                }

                foreach (var step in stepList)
                {
                    using var insert = new NpgsqlCommand(@"
                        INSERT INTO quest_sequence_steps (
                            sequence_id, display_order, step_type, speaker_binding, speaker_name,
                            text, sound_key, voiceline_id, duration, target_binding, point_x, point_y,
                            action_hook, sound_at_unit, notes)
                        VALUES (
                            @sequence_id, @display_order, @step_type, @speaker_binding, @speaker_name,
                            @text, @sound_key, @voiceline_id, @duration, @target_binding, @point_x, @point_y,
                            @action_hook, @sound_at_unit, @notes)", conn, transaction);
                    AddStepParameters(insert, sequence.Id, step);
                    insert.ExecuteNonQuery();
                }

                transaction.Commit();
                return sequence.Id;
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        public void DeleteSequence(int id)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand("DELETE FROM quest_sequences WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public List<QuestVoicelineDefinition> GetVoicelines()
        {
            var result = new List<QuestVoicelineDefinition>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, speaker_key, speaker_name, line_key, text, constant_name,
                       source_library, source_file, verified, notes
                FROM quest_voicelines ORDER BY speaker_name, line_key", conn);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(new QuestVoicelineDefinition
                {
                    Id = reader.GetInt32(0),
                    SpeakerKey = reader.GetString(1),
                    SpeakerName = reader.GetString(2),
                    LineKey = reader.GetString(3),
                    Text = reader.GetString(4),
                    ConstantName = GetString(reader, 5),
                    SourceLibrary = GetString(reader, 6),
                    SourceFile = GetString(reader, 7),
                    Verified = reader.GetBoolean(8),
                    Notes = reader.GetString(9)
                });
            }
            return result;
        }

        public int SaveVoiceline(QuestVoicelineDefinition line)
        {
            if (string.IsNullOrWhiteSpace(line.SpeakerKey) || string.IsNullOrWhiteSpace(line.LineKey))
            {
                throw new InvalidOperationException("Speaker key and line key are required.");
            }
            using var conn = OpenConnection();
            string sql = line.Id == 0
                ? @"INSERT INTO quest_voicelines (
                        speaker_key, speaker_name, line_key, text, constant_name,
                        source_library, source_file, verified, notes)
                    VALUES (
                        @speaker_key, @speaker_name, @line_key, @text, @constant_name,
                        @source_library, @source_file, @verified, @notes)
                    RETURNING id"
                : @"UPDATE quest_voicelines SET
                        speaker_key = @speaker_key, speaker_name = @speaker_name,
                        line_key = @line_key, text = @text, constant_name = @constant_name,
                        source_library = @source_library, source_file = @source_file,
                        verified = @verified, notes = @notes
                    WHERE id = @id RETURNING id";
            using var cmd = new NpgsqlCommand(sql, conn);
            cmd.Parameters.AddWithValue("id", line.Id);
            cmd.Parameters.AddWithValue("speaker_key", line.SpeakerKey.Trim());
            cmd.Parameters.AddWithValue("speaker_name", line.SpeakerName?.Trim() ?? "");
            cmd.Parameters.AddWithValue("line_key", line.LineKey.Trim());
            cmd.Parameters.AddWithValue("text", line.Text ?? "");
            AddNullableText(cmd, "constant_name", line.ConstantName);
            AddNullableText(cmd, "source_library", line.SourceLibrary);
            AddNullableText(cmd, "source_file", line.SourceFile);
            cmd.Parameters.AddWithValue("verified", line.Verified);
            cmd.Parameters.AddWithValue("notes", line.Notes ?? "");
            line.Id = Convert.ToInt32(cmd.ExecuteScalar());
            return line.Id;
        }

        public void DeleteVoiceline(int id)
        {
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand("DELETE FROM quest_voicelines WHERE id = @id", conn);
            cmd.Parameters.AddWithValue("id", id);
            cmd.ExecuteNonQuery();
        }

        public List<QuestWorldEditorDependency> GetWorldEditorDependencies(int giverId)
        {
            var result = new List<QuestWorldEditorDependency>();
            using var conn = OpenConnection();
            using var cmd = new NpgsqlCommand(@"
                SELECT id, quest_giver_id, quest_id, dependency_kind, symbol, expected_value,
                       verified, manual_follow_up, source_evidence
                FROM quest_we_dependencies
                WHERE quest_giver_id = @giver_id
                ORDER BY verified, dependency_kind, symbol", conn);
            cmd.Parameters.AddWithValue("giver_id", giverId);
            using var reader = cmd.ExecuteReader();
            while (reader.Read())
            {
                result.Add(new QuestWorldEditorDependency
                {
                    Id = reader.GetInt32(0),
                    QuestGiverId = reader.GetInt32(1),
                    QuestId = GetNullableInt(reader, 2),
                    DependencyKind = reader.GetString(3),
                    Symbol = reader.GetString(4),
                    ExpectedValue = reader.GetString(5),
                    Verified = reader.GetBoolean(6),
                    ManualFollowUp = reader.GetString(7),
                    SourceEvidence = reader.GetString(8)
                });
            }
            return result;
        }

        public void ReplaceWorldEditorDependencies(
            int giverId,
            IEnumerable<QuestWorldEditorDependency> dependencies)
        {
            var dependencyList = dependencies.ToList();
            using var conn = OpenConnection();
            using var transaction = conn.BeginTransaction();
            try
            {
                using (var delete = new NpgsqlCommand(
                    "DELETE FROM quest_we_dependencies WHERE quest_giver_id = @giver_id", conn, transaction))
                {
                    delete.Parameters.AddWithValue("giver_id", giverId);
                    delete.ExecuteNonQuery();
                }

                foreach (var dependency in dependencyList)
                {
                    if (string.IsNullOrWhiteSpace(dependency.Symbol))
                    {
                        continue;
                    }
                    using var insert = new NpgsqlCommand(@"
                        INSERT INTO quest_we_dependencies (
                            quest_giver_id, quest_id, dependency_kind, symbol, expected_value,
                            verified, manual_follow_up, source_evidence)
                        VALUES (
                            @giver_id, @quest_id, @kind, @symbol, @expected_value,
                            @verified, @manual_follow_up, @source_evidence)", conn, transaction);
                    insert.Parameters.AddWithValue("giver_id", giverId);
                    AddNullableInt(insert, "quest_id", dependency.QuestId);
                    insert.Parameters.AddWithValue("kind", dependency.DependencyKind ?? "other");
                    insert.Parameters.AddWithValue("symbol", dependency.Symbol.Trim());
                    insert.Parameters.AddWithValue("expected_value", dependency.ExpectedValue ?? "");
                    insert.Parameters.AddWithValue("verified", dependency.Verified);
                    insert.Parameters.AddWithValue("manual_follow_up", dependency.ManualFollowUp ?? "");
                    insert.Parameters.AddWithValue("source_evidence", dependency.SourceEvidence ?? "");
                    insert.ExecuteNonQuery();
                }
                transaction.Commit();
            }
            catch
            {
                transaction.Rollback();
                throw;
            }
        }

        private NpgsqlConnection OpenConnection()
        {
            var conn = new NpgsqlConnection(_connectionString);
            conn.Open();
            return conn;
        }

        private static void ReplaceObjectives(
            NpgsqlConnection conn,
            NpgsqlTransaction transaction,
            int questId,
            IEnumerable<QuestObjectiveDefinition> objectives)
        {
            using (var delete = new NpgsqlCommand(
                "DELETE FROM quest_objectives WHERE quest_id = @quest_id", conn, transaction))
            {
                delete.Parameters.AddWithValue("quest_id", questId);
                delete.ExecuteNonQuery();
            }

            foreach (var objective in objectives)
            {
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_objectives (
                        quest_id, objective_key, display_order, objective_type, text, amount,
                        item_code, unit_code, target_variable, target_name, region_variable, zone_id,
                        faction, required_reputation, completion_mode, external_hook, notes)
                    VALUES (
                        @quest_id, @objective_key, @display_order, @objective_type, @text, @amount,
                        @item_code, @unit_code, @target_variable, @target_name, @region_variable, @zone_id,
                        @faction, @required_reputation, @completion_mode, @external_hook, @notes)", conn, transaction);
                insert.Parameters.AddWithValue("quest_id", questId);
                insert.Parameters.AddWithValue("objective_key", objective.ObjectiveKey?.Trim() ?? "");
                insert.Parameters.AddWithValue("display_order", objective.DisplayOrder);
                insert.Parameters.AddWithValue("objective_type", objective.ObjectiveType ?? "manual");
                insert.Parameters.AddWithValue("text", objective.Text ?? "");
                insert.Parameters.AddWithValue("amount", objective.Amount);
                AddNullableText(insert, "item_code", objective.ItemCode);
                AddNullableText(insert, "unit_code", objective.UnitCode);
                AddNullableText(insert, "target_variable", objective.TargetVariable);
                insert.Parameters.AddWithValue("target_name", objective.TargetName ?? "");
                AddNullableText(insert, "region_variable", objective.RegionVariable);
                AddNullableInt(insert, "zone_id", objective.ZoneId);
                insert.Parameters.AddWithValue("faction", objective.Faction ?? "");
                insert.Parameters.AddWithValue("required_reputation", objective.RequiredReputation);
                insert.Parameters.AddWithValue("completion_mode", objective.CompletionMode ?? "automatic");
                AddNullableText(insert, "external_hook", objective.ExternalHook);
                insert.Parameters.AddWithValue("notes", objective.Notes ?? "");
                insert.ExecuteNonQuery();
            }
        }

        private static void SaveReward(
            NpgsqlConnection conn,
            NpgsqlTransaction transaction,
            int questId,
            QuestRewardDefinition reward)
        {
            using var cmd = new NpgsqlCommand(@"
                INSERT INTO quest_rewards (
                    quest_id, xp_active, xp_adjust, gold_active, gold_adjust,
                    arena_active, arena_adjust, reputation_active, reputation_adjust,
                    reputation_linked, item_code, custom_text)
                VALUES (
                    @quest_id, @xp_active, @xp_adjust, @gold_active, @gold_adjust,
                    @arena_active, @arena_adjust, @reputation_active, @reputation_adjust,
                    @reputation_linked, @item_code, @custom_text)
                ON CONFLICT (quest_id) DO UPDATE SET
                    xp_active = EXCLUDED.xp_active,
                    xp_adjust = EXCLUDED.xp_adjust,
                    gold_active = EXCLUDED.gold_active,
                    gold_adjust = EXCLUDED.gold_adjust,
                    arena_active = EXCLUDED.arena_active,
                    arena_adjust = EXCLUDED.arena_adjust,
                    reputation_active = EXCLUDED.reputation_active,
                    reputation_adjust = EXCLUDED.reputation_adjust,
                    reputation_linked = EXCLUDED.reputation_linked,
                    item_code = EXCLUDED.item_code,
                    custom_text = EXCLUDED.custom_text", conn, transaction);
            cmd.Parameters.AddWithValue("quest_id", questId);
            cmd.Parameters.AddWithValue("xp_active", reward.XpActive);
            cmd.Parameters.AddWithValue("xp_adjust", reward.XpAdjust);
            cmd.Parameters.AddWithValue("gold_active", reward.GoldActive);
            cmd.Parameters.AddWithValue("gold_adjust", reward.GoldAdjust);
            cmd.Parameters.AddWithValue("arena_active", reward.ArenaActive);
            cmd.Parameters.AddWithValue("arena_adjust", reward.ArenaAdjust);
            cmd.Parameters.AddWithValue("reputation_active", reward.ReputationActive);
            cmd.Parameters.AddWithValue("reputation_adjust", reward.ReputationAdjust);
            cmd.Parameters.AddWithValue("reputation_linked", reward.ReputationLinked);
            AddNullableText(cmd, "item_code", reward.ItemCode);
            cmd.Parameters.AddWithValue("custom_text", reward.CustomText ?? "");
            cmd.ExecuteNonQuery();
        }

        private static void ReplacePrerequisites(
            NpgsqlConnection conn,
            NpgsqlTransaction transaction,
            int questId,
            IEnumerable<int> prerequisiteIds)
        {
            using (var delete = new NpgsqlCommand(
                "DELETE FROM quest_prerequisites WHERE quest_id = @quest_id", conn, transaction))
            {
                delete.Parameters.AddWithValue("quest_id", questId);
                delete.ExecuteNonQuery();
            }

            foreach (int prerequisiteId in prerequisiteIds)
            {
                using var insert = new NpgsqlCommand(@"
                    INSERT INTO quest_prerequisites (quest_id, prerequisite_quest_id)
                    VALUES (@quest_id, @prerequisite_id)", conn, transaction);
                insert.Parameters.AddWithValue("quest_id", questId);
                insert.Parameters.AddWithValue("prerequisite_id", prerequisiteId);
                insert.ExecuteNonQuery();
            }
        }

        private static bool WouldCreatePrerequisiteCycle(
            NpgsqlConnection conn,
            NpgsqlTransaction transaction,
            int questId,
            IReadOnlyCollection<int> prerequisiteIds)
        {
            if (prerequisiteIds.Count == 0)
            {
                return false;
            }
            if (prerequisiteIds.Contains(questId))
            {
                return true;
            }

            using var cmd = new NpgsqlCommand(@"
                WITH RECURSIVE dependency_tree(id) AS (
                    SELECT unnest(@prerequisite_ids::integer[])
                    UNION
                    SELECT qp.prerequisite_quest_id
                    FROM quest_prerequisites qp
                    JOIN dependency_tree d ON qp.quest_id = d.id
                )
                SELECT EXISTS(SELECT 1 FROM dependency_tree WHERE id = @quest_id)", conn, transaction);
            cmd.Parameters.AddWithValue("prerequisite_ids", prerequisiteIds.ToArray());
            cmd.Parameters.AddWithValue("quest_id", questId);
            return Convert.ToBoolean(cmd.ExecuteScalar());
        }

        private static bool HasDailyOrRepeatablePrerequisite(
            NpgsqlConnection conn,
            NpgsqlTransaction transaction,
            IReadOnlyCollection<int> prerequisiteIds)
        {
            if (prerequisiteIds.Count == 0)
            {
                return false;
            }
            using var cmd = new NpgsqlCommand(@"
                WITH RECURSIVE dependency_tree(id) AS (
                    SELECT unnest(@prerequisite_ids::integer[])
                    UNION
                    SELECT qp.prerequisite_quest_id
                    FROM quest_prerequisites qp
                    JOIN dependency_tree d ON qp.quest_id = d.id
                )
                SELECT EXISTS(
                    SELECT 1
                    FROM dependency_tree d
                    JOIN quests q ON q.id = d.id
                    WHERE q.quest_type IN ('daily', 'repeatable'))", conn, transaction);
            cmd.Parameters.AddWithValue("prerequisite_ids", prerequisiteIds.ToArray());
            return Convert.ToBoolean(cmd.ExecuteScalar());
        }

        private static void AddGiverParameters(NpgsqlCommand cmd, QuestGiverDefinition giver)
        {
            cmd.Parameters.AddWithValue("id", giver.Id);
            cmd.Parameters.AddWithValue("giver_key", giver.GiverKey.Trim());
            cmd.Parameters.AddWithValue("display_name", giver.DisplayName.Trim());
            cmd.Parameters.AddWithValue("library_name", giver.LibraryName.Trim());
            AddNullableText(cmd, "unit_code", giver.UnitCode);
            AddNullableText(cmd, "placed_unit_variable", giver.PlacedUnitVariable);
            AddNullableInt(cmd, "zone_id", giver.ZoneId);
            cmd.Parameters.AddWithValue("faction", giver.Faction?.Trim() ?? "");
            cmd.Parameters.AddWithValue("allow_nazgrek", giver.AllowNazgrek);
            cmd.Parameters.AddWithValue("allow_zulkis", giver.AllowZulkis);
            cmd.Parameters.AddWithValue("dialog_range", giver.DialogRange);
            cmd.Parameters.AddWithValue("dialog_cooldown", giver.DialogCooldown);
            cmd.Parameters.AddWithValue("use_dialog_camera", giver.UseDialogCamera);
            cmd.Parameters.AddWithValue("use_cinematic_mode", giver.UseCinematicMode);
            cmd.Parameters.AddWithValue("camera_distance", giver.CameraDistance);
            cmd.Parameters.AddWithValue("camera_z_offset", giver.CameraZOffset);
            cmd.Parameters.AddWithValue("camera_angle", giver.CameraAngle);
            cmd.Parameters.AddWithValue("camera_rotation_offset", giver.CameraRotationOffset);
            cmd.Parameters.AddWithValue("camera_far_z", giver.CameraFarZ);
            cmd.Parameters.AddWithValue("camera_fov", giver.CameraFov);
            cmd.Parameters.AddWithValue("camera_block_radius", giver.CameraBlockRadius);
            cmd.Parameters.AddWithValue("camera_block_check", giver.CameraBlockCheck);
            cmd.Parameters.AddWithValue("enabled", giver.Enabled);
            cmd.Parameters.AddWithValue("notes", giver.Notes ?? "");
            cmd.Parameters.AddWithValue("ownership_mode", giver.OwnershipMode ?? "managed");
            cmd.Parameters.AddWithValue("source_file", giver.SourceFile ?? "");
        }

        private static void AddQuestParameters(NpgsqlCommand cmd, QuestDefinition quest)
        {
            cmd.Parameters.AddWithValue("id", quest.Id);
            cmd.Parameters.AddWithValue("quest_giver_id", quest.QuestGiverId);
            cmd.Parameters.AddWithValue("quest_key", quest.QuestKey.Trim());
            cmd.Parameters.AddWithValue("quest_name", quest.QuestName.Trim());
            cmd.Parameters.AddWithValue("title", quest.Title.Trim());
            cmd.Parameters.AddWithValue("quest_type", quest.QuestType ?? "normal");
            cmd.Parameters.AddWithValue("category", quest.Category ?? "general");
            cmd.Parameters.AddWithValue("quest_level", quest.QuestLevel);
            cmd.Parameters.AddWithValue("required_level", quest.RequiredLevel);
            cmd.Parameters.AddWithValue("required_reputation", quest.RequiredReputation);
            cmd.Parameters.AddWithValue("icon_path", quest.IconPath ?? "");
            cmd.Parameters.AddWithValue("description", quest.Description ?? "");
            cmd.Parameters.AddWithValue("info_text", quest.InfoText ?? "");
            cmd.Parameters.AddWithValue("info2_text", quest.Info2Text ?? "");
            AddNullableInt(cmd, "receiver_giver_id", quest.ReceiverGiverId);
            cmd.Parameters.AddWithValue("receiver_display_name", quest.ReceiverDisplayName ?? "");
            AddNullableInt(cmd, "zone_id", quest.ZoneId);
            cmd.Parameters.AddWithValue("faction", quest.Faction ?? "");
            cmd.Parameters.AddWithValue("allow_nazgrek", quest.AllowNazgrek);
            cmd.Parameters.AddWithValue("allow_zulkis", quest.AllowZulkis);
            cmd.Parameters.AddWithValue("requires_turn_in", quest.RequiresTurnIn);
            cmd.Parameters.AddWithValue("auto_complete", quest.AutoComplete);
            cmd.Parameters.AddWithValue("fail_reason", quest.FailReason ?? "");
            cmd.Parameters.AddWithValue("draft", quest.Draft);
            cmd.Parameters.AddWithValue("enabled", quest.Enabled);
            cmd.Parameters.AddWithValue("sort_order", quest.SortOrder);
            cmd.Parameters.AddWithValue("notes", quest.Notes ?? "");
        }

        private static void AddSequenceParameters(NpgsqlCommand cmd, QuestSequenceDefinition sequence)
        {
            cmd.Parameters.AddWithValue("id", sequence.Id);
            cmd.Parameters.AddWithValue("quest_giver_id", sequence.QuestGiverId);
            AddNullableInt(cmd, "quest_id", sequence.QuestId);
            cmd.Parameters.AddWithValue("sequence_key", sequence.SequenceKey.Trim());
            cmd.Parameters.AddWithValue("display_name", sequence.DisplayName.Trim());
            cmd.Parameters.AddWithValue("purpose", sequence.Purpose ?? "custom");
            cmd.Parameters.AddWithValue("show_as_dialog_option", sequence.ShowAsDialogOption);
            cmd.Parameters.AddWithValue("button_label", sequence.ButtonLabel ?? "");
            cmd.Parameters.AddWithValue("button_order", sequence.ButtonOrder);
            AddNullableText(cmd, "on_start_hook", sequence.OnStartHook);
            AddNullableText(cmd, "on_finish_hook", sequence.OnFinishHook);
            cmd.Parameters.AddWithValue("skippable", sequence.Skippable);
            cmd.Parameters.AddWithValue("enabled", sequence.Enabled);
            cmd.Parameters.AddWithValue("notes", sequence.Notes ?? "");
        }

        private static void AddStepParameters(NpgsqlCommand cmd, int sequenceId, QuestSequenceStepDefinition step)
        {
            cmd.Parameters.AddWithValue("sequence_id", sequenceId);
            cmd.Parameters.AddWithValue("display_order", step.DisplayOrder);
            cmd.Parameters.AddWithValue("step_type", step.StepType ?? "line");
            AddNullableText(cmd, "speaker_binding", step.SpeakerBinding);
            cmd.Parameters.AddWithValue("speaker_name", step.SpeakerName ?? "");
            cmd.Parameters.AddWithValue("text", step.Text ?? "");
            cmd.Parameters.AddWithValue("sound_key", step.SoundKey ?? "");
            AddNullableInt(cmd, "voiceline_id", step.VoicelineId);
            cmd.Parameters.AddWithValue("duration", step.Duration);
            AddNullableText(cmd, "target_binding", step.TargetBinding);
            AddNullableDecimal(cmd, "point_x", step.PointX);
            AddNullableDecimal(cmd, "point_y", step.PointY);
            AddNullableText(cmd, "action_hook", step.ActionHook);
            cmd.Parameters.AddWithValue("sound_at_unit", step.SoundAtUnit);
            cmd.Parameters.AddWithValue("notes", step.Notes ?? "");
        }

        private static QuestGiverDefinition MapGiver(NpgsqlDataReader reader)
        {
            return new QuestGiverDefinition
            {
                Id = reader.GetInt32(0),
                GiverKey = reader.GetString(1),
                DisplayName = reader.GetString(2),
                LibraryName = reader.GetString(3),
                UnitCode = GetString(reader, 4),
                PlacedUnitVariable = GetString(reader, 5),
                ZoneId = GetNullableInt(reader, 6),
                Faction = reader.GetString(7),
                AllowNazgrek = reader.GetBoolean(8),
                AllowZulkis = reader.GetBoolean(9),
                DialogRange = reader.GetDecimal(10),
                DialogCooldown = reader.GetDecimal(11),
                UseDialogCamera = reader.GetBoolean(12),
                UseCinematicMode = reader.GetBoolean(13),
                CameraDistance = reader.GetDecimal(14),
                CameraZOffset = reader.GetDecimal(15),
                CameraAngle = reader.GetDecimal(16),
                CameraRotationOffset = reader.GetDecimal(17),
                CameraFarZ = reader.GetDecimal(18),
                CameraFov = reader.GetDecimal(19),
                CameraBlockRadius = reader.GetDecimal(20),
                CameraBlockCheck = reader.GetBoolean(21),
                Enabled = reader.GetBoolean(22),
                Notes = reader.GetString(23),
                CreatedAt = reader.GetDateTime(24),
                UpdatedAt = reader.GetDateTime(25),
                OwnershipMode = reader.GetString(26),
                SourceFile = reader.GetString(27),
                SourceKind = reader.GetString(28),
                SourceImportFingerprint = reader.GetString(29),
                SourceImportedAt = reader.IsDBNull(30) ? null : reader.GetDateTime(30)
            };
        }

        private static QuestDefinition MapQuest(NpgsqlDataReader reader)
        {
            return new QuestDefinition
            {
                Id = reader.GetInt32(0),
                QuestGiverId = reader.GetInt32(1),
                QuestKey = reader.GetString(2),
                QuestName = reader.GetString(3),
                Title = reader.GetString(4),
                QuestType = reader.GetString(5),
                Category = reader.GetString(6),
                QuestLevel = reader.GetInt32(7),
                RequiredLevel = reader.GetInt32(8),
                RequiredReputation = reader.GetInt32(9),
                IconPath = reader.GetString(10),
                Description = reader.GetString(11),
                InfoText = reader.GetString(12),
                Info2Text = reader.GetString(13),
                ReceiverGiverId = GetNullableInt(reader, 14),
                ReceiverDisplayName = reader.GetString(15),
                ZoneId = GetNullableInt(reader, 16),
                Faction = reader.GetString(17),
                AllowNazgrek = reader.GetBoolean(18),
                AllowZulkis = reader.GetBoolean(19),
                RequiresTurnIn = reader.GetBoolean(20),
                AutoComplete = reader.GetBoolean(21),
                FailReason = reader.GetString(22),
                Draft = reader.GetBoolean(23),
                Enabled = reader.GetBoolean(24),
                SortOrder = reader.GetInt32(25),
                Notes = reader.GetString(26),
                CreatedAt = reader.GetDateTime(27),
                UpdatedAt = reader.GetDateTime(28),
                SourceFile = reader.GetString(29),
                SourceSymbol = reader.GetString(30),
                SourceImportFingerprint = reader.GetString(31),
                SourceImportedAt = reader.IsDBNull(32) ? null : reader.GetDateTime(32)
            };
        }

        private static void ValidateGiver(QuestGiverDefinition giver)
        {
            if (string.IsNullOrWhiteSpace(giver.GiverKey) || string.IsNullOrWhiteSpace(giver.DisplayName) ||
                string.IsNullOrWhiteSpace(giver.LibraryName))
            {
                throw new InvalidOperationException("Giver key, display name, and library name are required.");
            }
            if (!string.Equals(giver.OwnershipMode, "external", StringComparison.OrdinalIgnoreCase) &&
                string.IsNullOrWhiteSpace(giver.UnitCode) && string.IsNullOrWhiteSpace(giver.PlacedUnitVariable))
            {
                throw new InvalidOperationException("A quest giver needs a four-character unit code or a placed-unit variable.");
            }
        }

        private static void ValidateQuest(
            QuestDefinition quest,
            IReadOnlyCollection<QuestObjectiveDefinition> objectives,
            IReadOnlyCollection<int> prerequisites)
        {
            if (quest.QuestGiverId <= 0 || string.IsNullOrWhiteSpace(quest.QuestKey) ||
                string.IsNullOrWhiteSpace(quest.QuestName) || string.IsNullOrWhiteSpace(quest.Title))
            {
                throw new InvalidOperationException("Quest giver, key, internal name, and title are required.");
            }
            if (objectives.Count > 8)
            {
                throw new InvalidOperationException("QuestMaster supports at most eight objectives per quest.");
            }
            if (quest.RequiresTurnIn && !quest.AutoComplete && objectives.Count > 7)
            {
                throw new InvalidOperationException("A turn-in quest supports at most seven authored objectives because the return objective uses the eighth slot.");
            }
            if (prerequisites.Count > 4)
            {
                throw new InvalidOperationException("QuestMaster supports at most four prerequisite quests.");
            }
            if (quest.RequiredReputation < -20000 || quest.RequiredReputation > 20000)
            {
                throw new InvalidOperationException("Required reputation must be between -20000 and 20000.");
            }
            if (objectives.Select(o => o.DisplayOrder).Distinct().Count() != objectives.Count ||
                objectives.Any(o => o.DisplayOrder < 1 || o.DisplayOrder > 8))
            {
                throw new InvalidOperationException("Objective positions must be unique values from 1 through 8.");
            }
        }

        private static void ValidateSequence(
            QuestSequenceDefinition sequence,
            IReadOnlyCollection<QuestSequenceStepDefinition> steps)
        {
            if (sequence.QuestGiverId <= 0 || string.IsNullOrWhiteSpace(sequence.SequenceKey) ||
                string.IsNullOrWhiteSpace(sequence.DisplayName))
            {
                throw new InvalidOperationException("Sequence giver, key, and display name are required.");
            }
            if (steps.Count > 100)
            {
                throw new InvalidOperationException("DialogSystem supports at most 100 steps in one sequence.");
            }
            if (steps.Select(s => s.DisplayOrder).Distinct().Count() != steps.Count ||
                steps.Any(s => s.DisplayOrder < 1 || s.DisplayOrder > 100))
            {
                throw new InvalidOperationException("Sequence step positions must be unique values from 1 through 100.");
            }
            if (steps.Any(s => s.Duration < 0))
            {
                throw new InvalidOperationException("Sequence step durations cannot be negative.");
            }
            if ((sequence.Purpose == "accept" || sequence.Purpose == "complete" || sequence.Purpose == "fail") &&
                !sequence.QuestId.HasValue)
            {
                throw new InvalidOperationException($"A {sequence.Purpose} sequence must be linked to a quest.");
            }
        }

        private static string GetString(NpgsqlDataReader reader, int ordinal)
        {
            return reader.IsDBNull(ordinal) ? "" : reader.GetString(ordinal);
        }

        private static int? GetNullableInt(NpgsqlDataReader reader, int ordinal)
        {
            return reader.IsDBNull(ordinal) ? null : reader.GetInt32(ordinal);
        }

        private static decimal? GetNullableDecimal(NpgsqlDataReader reader, int ordinal)
        {
            return reader.IsDBNull(ordinal) ? null : reader.GetDecimal(ordinal);
        }

        private static void AddNullableInt(NpgsqlCommand cmd, string name, int? value)
        {
            cmd.Parameters.Add(name, NpgsqlDbType.Integer).Value = value.HasValue ? value.Value : DBNull.Value;
        }

        private static void AddNullableDecimal(NpgsqlCommand cmd, string name, decimal? value)
        {
            cmd.Parameters.Add(name, NpgsqlDbType.Numeric).Value = value.HasValue ? value.Value : DBNull.Value;
        }

        private static void AddNullableText(NpgsqlCommand cmd, string name, string value)
        {
            cmd.Parameters.Add(name, NpgsqlDbType.Text).Value =
                string.IsNullOrWhiteSpace(value) ? DBNull.Value : value.Trim();
        }
    }
}
