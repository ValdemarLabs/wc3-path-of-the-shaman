using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for DestructibleSpecificDrop entities
    /// </summary>
    public class DestructibleSpecificDropRepository
    {
        private readonly string _connectionString;

        public DestructibleSpecificDropRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        /// <summary>
        /// Get all specific drops for a destructible
        /// </summary>
        public List<DestructibleSpecificDrop> GetByDestructibleCode(string destructibleCode)
        {
            var drops = new List<DestructibleSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, destructible_code, item_code, drop_chance, 
                           min_quantity, max_quantity, is_guaranteed, weight,
                           enabled, notes, created_at
                    FROM destructible_specific_drops
                    WHERE destructible_code = @code
                    ORDER BY is_guaranteed DESC, drop_chance DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@code", destructibleCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToDestructibleSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Get all drops for a specific item code (reverse lookup)
        /// </summary>
        public List<DestructibleSpecificDrop> GetByItemCode(string itemCode)
        {
            var drops = new List<DestructibleSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, destructible_code, item_code, drop_chance, 
                           min_quantity, max_quantity, is_guaranteed, weight,
                           enabled, notes, created_at
                    FROM destructible_specific_drops
                    WHERE item_code = @code
                    ORDER BY destructible_code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", itemCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToDestructibleSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Get all enabled drops for JASS export
        /// </summary>
        public List<DestructibleSpecificDrop> GetAllEnabled()
        {
            var drops = new List<DestructibleSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT dsd.id, dsd.destructible_code, dsd.item_code, dsd.drop_chance, 
                           dsd.min_quantity, dsd.max_quantity, dsd.is_guaranteed, dsd.weight,
                           dsd.enabled, dsd.notes, dsd.created_at
                    FROM destructible_specific_drops dsd
                    INNER JOIN destructible_types dt ON dsd.destructible_code = dt.destructible_code
                    WHERE dsd.enabled = true AND dt.enabled = true
                    ORDER BY dsd.destructible_code, dsd.is_guaranteed DESC, dsd.drop_chance DESC", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToDestructibleSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Get a specific drop by ID
        /// </summary>
        public DestructibleSpecificDrop GetById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, destructible_code, item_code, drop_chance, 
                           min_quantity, max_quantity, is_guaranteed, weight,
                           enabled, notes, created_at
                    FROM destructible_specific_drops
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToDestructibleSpecificDrop(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        /// <summary>
        /// Check if a specific drop already exists
        /// </summary>
        public bool Exists(string destructibleCode, string itemCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT 1 FROM destructible_specific_drops 
                    WHERE destructible_code = @dest_code AND item_code = @item_code 
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@dest_code", destructibleCode);
                    cmd.Parameters.AddWithValue("@item_code", itemCode);
                    return cmd.ExecuteScalar() != null;
                }
            }
        }

        /// <summary>
        /// Insert a new specific drop
        /// </summary>
        public int Insert(DestructibleSpecificDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO destructible_specific_drops (
                        destructible_code, item_code, drop_chance, 
                        min_quantity, max_quantity, is_guaranteed, weight,
                        enabled, notes
                    ) VALUES (
                        @dest_code, @item_code, @drop_chance,
                        @min_qty, @max_qty, @is_guaranteed, @weight,
                        @enabled, @notes
                    ) RETURNING id", conn))
                {
                    AddParameters(cmd, drop);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        /// <summary>
        /// Update an existing specific drop
        /// </summary>
        public void Update(DestructibleSpecificDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE destructible_specific_drops SET
                        item_code = @item_code,
                        drop_chance = @drop_chance,
                        min_quantity = @min_qty,
                        max_quantity = @max_qty,
                        is_guaranteed = @is_guaranteed,
                        weight = @weight,
                        enabled = @enabled,
                        notes = @notes
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", drop.Id);
                    AddParameters(cmd, drop);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete a specific drop
        /// </summary>
        public void Delete(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "DELETE FROM destructible_specific_drops WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete all specific drops for a destructible
        /// </summary>
        public void DeleteByDestructibleCode(string destructibleCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "DELETE FROM destructible_specific_drops WHERE destructible_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", destructibleCode);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private void AddParameters(NpgsqlCommand cmd, DestructibleSpecificDrop drop)
        {
            cmd.Parameters.AddWithValue("@dest_code", drop.DestructibleCode);
            cmd.Parameters.AddWithValue("@item_code", drop.ItemCode);
            cmd.Parameters.AddWithValue("@drop_chance", drop.DropChance);
            cmd.Parameters.AddWithValue("@min_qty", drop.MinQuantity);
            cmd.Parameters.AddWithValue("@max_qty", drop.MaxQuantity);
            cmd.Parameters.AddWithValue("@is_guaranteed", drop.IsGuaranteed);
            cmd.Parameters.AddWithValue("@weight", drop.Weight);
            cmd.Parameters.AddWithValue("@enabled", drop.Enabled);
            cmd.Parameters.AddWithValue("@notes", (object)drop.Notes ?? DBNull.Value);
        }

        private DestructibleSpecificDrop MapToDestructibleSpecificDrop(NpgsqlDataReader reader)
        {
            return new DestructibleSpecificDrop
            {
                Id = reader.GetInt32(reader.GetOrdinal("id")),
                DestructibleCode = reader.GetString(reader.GetOrdinal("destructible_code")).Trim(),
                ItemCode = reader.GetString(reader.GetOrdinal("item_code")).Trim(),
                DropChance = reader.GetDecimal(reader.GetOrdinal("drop_chance")),
                MinQuantity = reader.GetInt32(reader.GetOrdinal("min_quantity")),
                MaxQuantity = reader.GetInt32(reader.GetOrdinal("max_quantity")),
                IsGuaranteed = reader.GetBoolean(reader.GetOrdinal("is_guaranteed")),
                Weight = reader.GetInt32(reader.GetOrdinal("weight")),
                Enabled = reader.GetBoolean(reader.GetOrdinal("enabled")),
                Notes = reader.IsDBNull(reader.GetOrdinal("notes")) ? null : reader.GetString(reader.GetOrdinal("notes")),
                CreatedAt = reader.GetDateTime(reader.GetOrdinal("created_at"))
            };
        }
    }
}
