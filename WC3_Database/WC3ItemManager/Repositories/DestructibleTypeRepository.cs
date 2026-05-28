using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for DestructibleType entities
    /// </summary>
    public class DestructibleTypeRepository
    {
        private readonly string _connectionString;

        public DestructibleTypeRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        /// <summary>
        /// Get all destructible types
        /// </summary>
        public List<DestructibleType> GetAll()
        {
            var destructibles = new List<DestructibleType>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, destructible_code, base_id, destructible_name, editor_suffix,
                           model_path, destructible_level, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, drop_chance_override,
                           category, is_container, notes, enabled, created_at, updated_at
                    FROM destructible_types
                    ORDER BY destructible_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            destructibles.Add(MapToDestructibleType(reader));
                        }
                    }
                }
            }
            
            return destructibles;
        }

        /// <summary>
        /// Get destructible types with filters
        /// </summary>
        public List<DestructibleType> GetFiltered(
            bool? isContainer = null, 
            LootMode? lootMode = null, 
            int? minLevel = null, 
            int? maxLevel = null, 
            string searchText = null,
            string category = null)
        {
            var destructibles = new List<DestructibleType>();
            var conditions = new List<string>();
            
            if (isContainer.HasValue)
                conditions.Add("is_container = @is_container");
            if (lootMode.HasValue)
                conditions.Add("loot_mode = @loot_mode");
            if (minLevel.HasValue)
                conditions.Add("destructible_level >= @min_level");
            if (maxLevel.HasValue)
                conditions.Add("destructible_level <= @max_level");
            if (!string.IsNullOrEmpty(searchText))
                conditions.Add("(destructible_name ILIKE @search OR destructible_code ILIKE @search)");
            if (!string.IsNullOrEmpty(category))
                conditions.Add("category = @category");

            string whereClause = conditions.Count > 0 
                ? "WHERE " + string.Join(" AND ", conditions) 
                : "";

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand($@"
                    SELECT id, destructible_code, base_id, destructible_name, editor_suffix,
                           model_path, destructible_level, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, drop_chance_override,
                           category, is_container, notes, enabled, created_at, updated_at
                    FROM destructible_types
                    {whereClause}
                    ORDER BY destructible_name", conn))
                {
                    if (isContainer.HasValue)
                        cmd.Parameters.AddWithValue("@is_container", isContainer.Value);
                    if (lootMode.HasValue)
                        cmd.Parameters.AddWithValue("@loot_mode", lootMode.Value.ToDbString());
                    if (minLevel.HasValue)
                        cmd.Parameters.AddWithValue("@min_level", minLevel.Value);
                    if (maxLevel.HasValue)
                        cmd.Parameters.AddWithValue("@max_level", maxLevel.Value);
                    if (!string.IsNullOrEmpty(searchText))
                        cmd.Parameters.AddWithValue("@search", $"%{searchText}%");
                    if (!string.IsNullOrEmpty(category))
                        cmd.Parameters.AddWithValue("@category", category);

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            destructibles.Add(MapToDestructibleType(reader));
                        }
                    }
                }
            }
            
            return destructibles;
        }

        /// <summary>
        /// Get a destructible type by code
        /// </summary>
        public DestructibleType GetByCode(string destructibleCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, destructible_code, base_id, destructible_name, editor_suffix,
                           model_path, destructible_level, loot_mode, loot_tier_id, loot_table_id,
                           drop_count_min, drop_count_max, drop_chance_override,
                           category, is_container, notes, enabled, created_at, updated_at
                    FROM destructible_types
                    WHERE destructible_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", destructibleCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToDestructibleType(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        /// <summary>
        /// Check if destructible code exists
        /// </summary>
        public bool Exists(string destructibleCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "SELECT 1 FROM destructible_types WHERE destructible_code = @code LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@code", destructibleCode);
                    return cmd.ExecuteScalar() != null;
                }
            }
        }

        /// <summary>
        /// Insert a new destructible type
        /// </summary>
        public int Insert(DestructibleType dest)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO destructible_types (
                        destructible_code, base_id, destructible_name, editor_suffix,
                        model_path, destructible_level, loot_mode, loot_tier_id, loot_table_id,
                        drop_count_min, drop_count_max, drop_chance_override,
                        category, is_container, notes, enabled
                    ) VALUES (
                        @code, @base_id, @name, @suffix, @model,
                        @level, @loot_mode, @tier_id, @table_id, @drop_min, @drop_max, @drop_override,
                        @category, @is_container, @notes, @enabled
                    ) RETURNING id", conn))
                {
                    AddParameters(cmd, dest);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        /// <summary>
        /// Update an existing destructible type
        /// </summary>
        public void Update(DestructibleType dest)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE destructible_types SET
                        base_id = @base_id,
                        destructible_name = @name,
                        editor_suffix = @suffix,
                        model_path = @model,
                        destructible_level = @level,
                        loot_mode = @loot_mode,
                        loot_tier_id = @tier_id,
                        loot_table_id = @table_id,
                        drop_count_min = @drop_min,
                        drop_count_max = @drop_max,
                        drop_chance_override = @drop_override,
                        category = @category,
                        is_container = @is_container,
                        notes = @notes,
                        enabled = @enabled
                    WHERE destructible_code = @code", conn))
                {
                    AddParameters(cmd, dest);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete a destructible type
        /// </summary>
        public void Delete(string destructibleCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "DELETE FROM destructible_types WHERE destructible_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", destructibleCode);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Get all distinct categories
        /// </summary>
        public List<string> GetCategories()
        {
            var categories = new List<string>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "SELECT DISTINCT category FROM destructible_types WHERE category IS NOT NULL ORDER BY category", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            categories.Add(reader.GetString(0));
                        }
                    }
                }
            }
            
            return categories;
        }

        /// <summary>
        /// Get all enabled destructibles with specific loot mode for JASS export
        /// </summary>
        public List<DestructibleType> GetEnabledWithSpecificDrops()
        {
            var destructibles = new List<DestructibleType>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT DISTINCT dt.id, dt.destructible_code, dt.base_id, dt.destructible_name, 
                           dt.editor_suffix, dt.model_path, dt.destructible_level, dt.loot_mode, 
                           dt.loot_tier_id, dt.loot_table_id, dt.drop_count_min, dt.drop_count_max, dt.drop_chance_override,
                           dt.category, dt.is_container, dt.notes, dt.enabled, dt.created_at, dt.updated_at
                    FROM destructible_types dt
                    WHERE dt.enabled = true 
                      AND dt.loot_mode IN ('specific', 'both')
                    ORDER BY dt.destructible_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            destructibles.Add(MapToDestructibleType(reader));
                        }
                    }
                }
            }
            
            return destructibles;
        }

        private void AddParameters(NpgsqlCommand cmd, DestructibleType dest)
        {
            cmd.Parameters.AddWithValue("@code", dest.DestructibleCode);
            cmd.Parameters.AddWithValue("@base_id", (object)dest.BaseId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@name", dest.DestructibleName);
            cmd.Parameters.AddWithValue("@suffix", (object)dest.EditorSuffix ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@model", (object)dest.ModelPath ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@level", dest.DestructibleLevel);
            cmd.Parameters.AddWithValue("@loot_mode", dest.LootMode.ToDbString());
            cmd.Parameters.AddWithValue("@tier_id", (object)dest.LootTierId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@table_id", (object)dest.LootTableId ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@drop_min", dest.DropCountMin);
            cmd.Parameters.AddWithValue("@drop_max", dest.DropCountMax);
            cmd.Parameters.AddWithValue("@drop_override", (object)dest.DropChanceOverride ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@category", (object)dest.Category ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@is_container", dest.IsContainer);
            cmd.Parameters.AddWithValue("@notes", (object)dest.Notes ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@enabled", dest.Enabled);
        }

        private DestructibleType MapToDestructibleType(NpgsqlDataReader reader)
        {
            return new DestructibleType
            {
                Id = reader.GetInt32(reader.GetOrdinal("id")),
                DestructibleCode = reader.GetString(reader.GetOrdinal("destructible_code")).Trim(),
                BaseId = reader.IsDBNull(reader.GetOrdinal("base_id")) ? null : reader.GetString(reader.GetOrdinal("base_id")),
                DestructibleName = reader.GetString(reader.GetOrdinal("destructible_name")),
                EditorSuffix = reader.IsDBNull(reader.GetOrdinal("editor_suffix")) ? null : reader.GetString(reader.GetOrdinal("editor_suffix")),
                ModelPath = reader.IsDBNull(reader.GetOrdinal("model_path")) ? null : reader.GetString(reader.GetOrdinal("model_path")),
                DestructibleLevel = reader.GetInt32(reader.GetOrdinal("destructible_level")),
                LootMode = LootModeExtensions.FromDbString(reader.GetString(reader.GetOrdinal("loot_mode"))),
                LootTierId = reader.IsDBNull(reader.GetOrdinal("loot_tier_id")) ? null : (int?)reader.GetInt32(reader.GetOrdinal("loot_tier_id")),
                LootTableId = reader.IsDBNull(reader.GetOrdinal("loot_table_id")) ? null : (int?)reader.GetInt32(reader.GetOrdinal("loot_table_id")),
                DropCountMin = reader.GetInt32(reader.GetOrdinal("drop_count_min")),
                DropCountMax = reader.GetInt32(reader.GetOrdinal("drop_count_max")),
                DropChanceOverride = reader.IsDBNull(reader.GetOrdinal("drop_chance_override")) ? null : (decimal?)reader.GetDecimal(reader.GetOrdinal("drop_chance_override")),
                Category = reader.IsDBNull(reader.GetOrdinal("category")) ? null : reader.GetString(reader.GetOrdinal("category")),
                IsContainer = reader.GetBoolean(reader.GetOrdinal("is_container")),
                Notes = reader.IsDBNull(reader.GetOrdinal("notes")) ? null : reader.GetString(reader.GetOrdinal("notes")),
                Enabled = reader.GetBoolean(reader.GetOrdinal("enabled")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at")),
                UpdatedAt = reader.GetDateTime(reader.GetOrdinal("updated_at"))
            };
        }
    }
}
