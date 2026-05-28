using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for UnitType entities
    /// </summary>
    public class UnitTypeRepository
    {
        private readonly string _connectionString;

        public UnitTypeRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        /// <summary>
        /// Get all unit types
        /// </summary>
        public List<UnitType> GetAll()
        {
            var units = new List<UnitType>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, unit_code, base_id, unit_name, editor_suffix, icon_path,
                           unit_level, is_boss, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, notes, created_at, updated_at
                    FROM unit_types
                    ORDER BY unit_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            units.Add(MapToUnitType(reader));
                        }
                    }
                }
            }
            
            return units;
        }

        /// <summary>
        /// Get unit types with filters
        /// </summary>
        public List<UnitType> GetFiltered(bool? isBoss = null, LootMode? lootMode = null, 
            int? minLevel = null, int? maxLevel = null, string searchText = null)
        {
            var units = new List<UnitType>();
            var conditions = new List<string>();
            
            if (isBoss.HasValue)
                conditions.Add("is_boss = @is_boss");
            if (lootMode.HasValue)
                conditions.Add("loot_mode = @loot_mode");
            if (minLevel.HasValue)
                conditions.Add("unit_level >= @min_level");
            if (maxLevel.HasValue)
                conditions.Add("unit_level <= @max_level");
            if (!string.IsNullOrEmpty(searchText))
                conditions.Add("(unit_name ILIKE @search OR unit_code ILIKE @search)");

            string whereClause = conditions.Count > 0 
                ? "WHERE " + string.Join(" AND ", conditions) 
                : "";

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand($@"
                    SELECT id, unit_code, base_id, unit_name, editor_suffix, icon_path,
                           unit_level, is_boss, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, notes, created_at, updated_at
                    FROM unit_types
                    {whereClause}
                    ORDER BY unit_name", conn))
                {
                    if (isBoss.HasValue)
                        cmd.Parameters.AddWithValue("@is_boss", isBoss.Value);
                    if (lootMode.HasValue)
                        cmd.Parameters.AddWithValue("@loot_mode", lootMode.Value.ToDbString());
                    if (minLevel.HasValue)
                        cmd.Parameters.AddWithValue("@min_level", minLevel.Value);
                    if (maxLevel.HasValue)
                        cmd.Parameters.AddWithValue("@max_level", maxLevel.Value);
                    if (!string.IsNullOrEmpty(searchText))
                        cmd.Parameters.AddWithValue("@search", $"%{searchText}%");

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            units.Add(MapToUnitType(reader));
                        }
                    }
                }
            }
            
            return units;
        }

        /// <summary>
        /// Get a unit type by unit code
        /// </summary>
        public UnitType GetByCode(string unitCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, unit_code, base_id, unit_name, editor_suffix, icon_path,
                           unit_level, is_boss, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, notes, created_at, updated_at
                    FROM unit_types
                    WHERE unit_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", unitCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToUnitType(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        /// <summary>
        /// Check if unit code exists
        /// </summary>
        public bool Exists(string unitCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "SELECT 1 FROM unit_types WHERE unit_code = @code LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@code", unitCode);
                    return cmd.ExecuteScalar() != null;
                }
            }
        }

        /// <summary>
        /// Insert a new unit type
        /// </summary>
        public int Insert(UnitType unit)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO unit_types (
                        unit_code, base_id, unit_name, editor_suffix, icon_path,
                        unit_level, is_boss, loot_mode, loot_tier_id, loot_table_id,
                        drop_count_min, drop_count_max, notes
                    ) VALUES (
                        @code, @base_id, @name, @suffix, @icon,
                        @level, @is_boss, @loot_mode, @tier_id, @table_id,
                        @min_drop, @max_drop, @notes
                    ) RETURNING id", conn))
                {
                    AddParameters(cmd, unit);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        /// <summary>
        /// Update an existing unit type
        /// </summary>
        public void Update(UnitType unit)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE unit_types SET
                        base_id = @base_id,
                        unit_name = @name,
                        editor_suffix = @suffix,
                        icon_path = @icon,
                        unit_level = @level,
                        is_boss = @is_boss,
                        loot_mode = @loot_mode,
                        loot_tier_id = @tier_id,
                        loot_table_id = @table_id,
                        drop_count_min = @min_drop,
                        drop_count_max = @max_drop,
                        notes = @notes
                    WHERE unit_code = @code", conn))
                {
                    AddParameters(cmd, unit);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Upsert unit type (insert or update)
        /// </summary>
        public void Upsert(UnitType unit)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO unit_types (
                        unit_code, base_id, unit_name, editor_suffix, icon_path,
                        unit_level, is_boss, loot_mode, loot_tier_id, loot_table_id,
                        drop_count_min, drop_count_max, notes
                    ) VALUES (
                        @code, @base_id, @name, @suffix, @icon,
                        @level, @is_boss, @loot_mode, @tier_id, @table_id,
                        @min_drop, @max_drop, @notes
                    )
                    ON CONFLICT (unit_code) DO UPDATE SET
                        base_id = EXCLUDED.base_id,
                        unit_name = EXCLUDED.unit_name,
                        editor_suffix = EXCLUDED.editor_suffix,
                        icon_path = EXCLUDED.icon_path,
                        unit_level = EXCLUDED.unit_level
                    ", conn))
                {
                    AddParameters(cmd, unit);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete a unit type
        /// </summary>
        public void Delete(string unitCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "DELETE FROM unit_types WHERE unit_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", unitCode);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Get count of units by loot mode
        /// </summary>
        public Dictionary<LootMode, int> GetCountsByLootMode()
        {
            var counts = new Dictionary<LootMode, int>
            {
                { LootMode.Generic, 0 },
                { LootMode.Specific, 0 },
                { LootMode.Both, 0 },
                { LootMode.None, 0 }
            };

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT loot_mode, COUNT(*) 
                    FROM unit_types 
                    GROUP BY loot_mode", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var mode = LootModeExtensions.FromDbString(reader.GetString(0));
                            counts[mode] = reader.GetInt32(1);
                        }
                    }
                }
            }

            return counts;
        }

        private UnitType MapToUnitType(NpgsqlDataReader reader)
        {
            return new UnitType
            {
                Id = reader.GetInt32(0),
                UnitCode = reader.GetString(1),
                BaseId = reader.IsDBNull(2) ? null : reader.GetString(2),
                UnitName = reader.GetString(3),
                EditorSuffix = reader.IsDBNull(4) ? null : reader.GetString(4),
                IconPath = reader.IsDBNull(5) ? null : reader.GetString(5),
                UnitLevel = reader.GetInt32(6),
                IsBoss = reader.GetBoolean(7),
                LootMode = LootModeExtensions.FromDbString(reader.GetString(8)),
                LootTierId = reader.IsDBNull(9) ? null : reader.GetInt32(9),
                LootTableId = reader.IsDBNull(10) ? null : reader.GetInt32(10),
                DropCountMin = reader.GetInt32(11),
                DropCountMax = reader.GetInt32(12),
                Notes = reader.IsDBNull(13) ? null : reader.GetString(13),
                CreatedAt = reader.GetDateTime(14),
                UpdatedAt = reader.GetDateTime(15)
            };
        }

        private void AddParameters(NpgsqlCommand cmd, UnitType unit)
        {
            cmd.Parameters.AddWithValue("@code", unit.UnitCode);
            cmd.Parameters.AddWithValue("@base_id", (object)unit.BaseId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@name", unit.UnitName);
            cmd.Parameters.AddWithValue("@suffix", (object)unit.EditorSuffix ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@icon", (object)unit.IconPath ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@level", unit.UnitLevel);
            cmd.Parameters.AddWithValue("@is_boss", unit.IsBoss);
            cmd.Parameters.AddWithValue("@loot_mode", unit.LootMode.ToDbString());
            cmd.Parameters.AddWithValue("@tier_id", (object)unit.LootTierId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@table_id", (object)unit.LootTableId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@min_drop", unit.DropCountMin);
            cmd.Parameters.AddWithValue("@max_drop", unit.DropCountMax);
            cmd.Parameters.AddWithValue("@notes", (object)unit.Notes ?? DBNull.Value);
        }
    }
}
