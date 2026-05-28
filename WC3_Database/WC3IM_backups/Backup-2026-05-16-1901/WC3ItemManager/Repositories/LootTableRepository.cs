using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Repository for loot_tables table operations
    /// </summary>
    public class LootTableRepository
    {
        private readonly string _connectionString;

        public LootTableRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public List<LootTable> GetAll()
        {
            var tables = new List<LootTable>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
                           min_level, max_level, category, enabled, created_at, updated_at
                    FROM loot_tables
                    ORDER BY category, min_level, name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            tables.Add(MapFromReader(reader));
                        }
                    }
                }
            }

            return tables;
        }

        public List<LootTable> GetEnabled()
        {
            var tables = new List<LootTable>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
                           min_level, max_level, category, enabled, created_at, updated_at
                    FROM loot_tables
                    WHERE enabled = true
                    ORDER BY category, min_level, name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            tables.Add(MapFromReader(reader));
                        }
                    }
                }
            }

            return tables;
        }

        public List<LootTable> GetByCategory(string category)
        {
            var tables = new List<LootTable>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
                           min_level, max_level, category, enabled, created_at, updated_at
                    FROM loot_tables
                    WHERE category = @category OR category = 'both'
                    ORDER BY min_level, name", conn))
                {
                    cmd.Parameters.AddWithValue("@category", category);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            tables.Add(MapFromReader(reader));
                        }
                    }
                }
            }

            return tables;
        }

        public LootTable GetById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
                           min_level, max_level, category, enabled, created_at, updated_at
                    FROM loot_tables
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapFromReader(reader);
                        }
                    }
                }
            }
            return null;
        }

        public LootTable GetByName(string name)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, name, description, drop_chance, drop_count_min, drop_count_max,
                           min_level, max_level, category, enabled, created_at, updated_at
                    FROM loot_tables
                    WHERE name = @name", conn))
                {
                    cmd.Parameters.AddWithValue("@name", name);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapFromReader(reader);
                        }
                    }
                }
            }
            return null;
        }

        public int Insert(LootTable table)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max,
                                             min_level, max_level, category, enabled)
                    VALUES (@name, @description, @drop_chance, @drop_count_min, @drop_count_max,
                            @min_level, @max_level, @category, @enabled)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@name", table.Name);
                    cmd.Parameters.AddWithValue("@description", (object)table.Description ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@drop_chance", table.DropChance);
                    cmd.Parameters.AddWithValue("@drop_count_min", table.DropCountMin);
                    cmd.Parameters.AddWithValue("@drop_count_max", table.DropCountMax);
                    cmd.Parameters.AddWithValue("@min_level", table.MinLevel);
                    cmd.Parameters.AddWithValue("@max_level", table.MaxLevel);
                    cmd.Parameters.AddWithValue("@category", (object)table.Category ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", table.Enabled);

                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void Update(LootTable table)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE loot_tables
                    SET name = @name, description = @description, drop_chance = @drop_chance,
                        drop_count_min = @drop_count_min, drop_count_max = @drop_count_max,
                        min_level = @min_level, max_level = @max_level,
                        category = @category, enabled = @enabled
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", table.Id);
                    cmd.Parameters.AddWithValue("@name", table.Name);
                    cmd.Parameters.AddWithValue("@description", (object)table.Description ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@drop_chance", table.DropChance);
                    cmd.Parameters.AddWithValue("@drop_count_min", table.DropCountMin);
                    cmd.Parameters.AddWithValue("@drop_count_max", table.DropCountMax);
                    cmd.Parameters.AddWithValue("@min_level", table.MinLevel);
                    cmd.Parameters.AddWithValue("@max_level", table.MaxLevel);
                    cmd.Parameters.AddWithValue("@category", (object)table.Category ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", table.Enabled);

                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void Delete(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM loot_tables WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public int Duplicate(int sourceId, string newName)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var transaction = conn.BeginTransaction())
                {
                    try
                    {
                        // Copy loot table
                        int newId;
                        using (var cmd = new NpgsqlCommand(@"
                            INSERT INTO loot_tables (name, description, drop_chance, drop_count_min, drop_count_max,
                                                     min_level, max_level, category, enabled)
                            SELECT @new_name, description, drop_chance, drop_count_min, drop_count_max,
                                   min_level, max_level, category, enabled
                            FROM loot_tables WHERE id = @source_id
                            RETURNING id", conn, transaction))
                        {
                            cmd.Parameters.AddWithValue("@source_id", sourceId);
                            cmd.Parameters.AddWithValue("@new_name", newName);
                            newId = (int)cmd.ExecuteScalar();
                        }

                        // Copy loot table items
                        using (var cmd = new NpgsqlCommand(@"
                            INSERT INTO loot_table_items (loot_table_id, item_code, drop_chance, weight,
                                                          is_guaranteed, quantity_min, quantity_max, notes)
                            SELECT @new_id, item_code, drop_chance, weight,
                                   is_guaranteed, quantity_min, quantity_max, notes
                            FROM loot_table_items WHERE loot_table_id = @source_id", conn, transaction))
                        {
                            cmd.Parameters.AddWithValue("@source_id", sourceId);
                            cmd.Parameters.AddWithValue("@new_id", newId);
                            cmd.ExecuteNonQuery();
                        }

                        transaction.Commit();
                        return newId;
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
                }
            }
        }

        public List<string> GetCategories()
        {
            var categories = new List<string>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT DISTINCT category FROM loot_tables 
                    WHERE category IS NOT NULL 
                    ORDER BY category", conn))
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

        public int GetItemCount(int lootTableId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT COUNT(*) FROM loot_table_items WHERE loot_table_id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", lootTableId);
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
        }

        private LootTable MapFromReader(NpgsqlDataReader reader)
        {
            return new LootTable
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                Description = reader.IsDBNull(2) ? null : reader.GetString(2),
                DropChance = reader.GetInt32(3),
                DropCountMin = reader.GetInt32(4),
                DropCountMax = reader.GetInt32(5),
                MinLevel = reader.GetInt32(6),
                MaxLevel = reader.GetInt32(7),
                Category = reader.IsDBNull(8) ? null : reader.GetString(8),
                Enabled = reader.GetBoolean(9),
                CreatedAt = reader.GetDateTime(10),
                UpdatedAt = reader.GetDateTime(11)
            };
        }
    }
}
