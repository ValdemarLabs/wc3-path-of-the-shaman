using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for UnitSpecificDrop entities
    /// </summary>
    public class UnitSpecificDropRepository
    {
        private readonly string _connectionString;

        public UnitSpecificDropRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        /// <summary>
        /// Get all specific drops for a unit
        /// </summary>
        public List<UnitSpecificDrop> GetByUnitCode(string unitCode)
        {
            var drops = new List<UnitSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT usd.id, usd.unit_code, usd.item_code, 
                           usd.drop_chance, usd.min_quantity, usd.max_quantity,
                           usd.is_guaranteed, usd.weight, usd.enabled, usd.notes, usd.created_at,
                           ut.unit_name, i.item_name, r.rarity_name
                    FROM unit_specific_drops usd
                    JOIN unit_types ut ON usd.unit_code = ut.unit_code
                    JOIN items i ON usd.item_code = i.item_code
                    LEFT JOIN item_rarities r ON i.rarity_id = r.id
                    WHERE usd.unit_code = @unit_code
                    ORDER BY usd.is_guaranteed DESC, usd.drop_chance DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@unit_code", unitCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToUnitSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Get all specific drops for an item
        /// </summary>
        public List<UnitSpecificDrop> GetByItemCode(string itemCode)
        {
            var drops = new List<UnitSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT usd.id, usd.unit_code, usd.item_code, 
                           usd.drop_chance, usd.min_quantity, usd.max_quantity,
                           usd.is_guaranteed, usd.weight, usd.enabled, usd.notes, usd.created_at,
                           ut.unit_name, i.item_name, r.rarity_name
                    FROM unit_specific_drops usd
                    JOIN unit_types ut ON usd.unit_code = ut.unit_code
                    JOIN items i ON usd.item_code = i.item_code
                    LEFT JOIN item_rarities r ON i.rarity_id = r.id
                    WHERE usd.item_code = @item_code
                    ORDER BY ut.unit_name", conn))
                {
                    cmd.Parameters.AddWithValue("@item_code", itemCode);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToUnitSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Get all enabled specific drops (for JASS export)
        /// </summary>
        public List<UnitSpecificDrop> GetAllEnabled()
        {
            var drops = new List<UnitSpecificDrop>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT usd.id, usd.unit_code, usd.item_code, 
                           usd.drop_chance, usd.min_quantity, usd.max_quantity,
                           usd.is_guaranteed, usd.weight, usd.enabled, usd.notes, usd.created_at,
                           ut.unit_name, i.item_name, r.rarity_name
                    FROM unit_specific_drops usd
                    JOIN unit_types ut ON usd.unit_code = ut.unit_code
                    JOIN items i ON usd.item_code = i.item_code
                    LEFT JOIN item_rarities r ON i.rarity_id = r.id
                    WHERE usd.enabled = true
                    ORDER BY usd.unit_code, usd.is_guaranteed DESC, usd.drop_chance DESC", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToUnitSpecificDrop(reader));
                        }
                    }
                }
            }
            
            return drops;
        }

        /// <summary>
        /// Insert a new specific drop
        /// </summary>
        public int Insert(UnitSpecificDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO unit_specific_drops (
                        unit_code, item_code, drop_chance, min_quantity, max_quantity,
                        is_guaranteed, weight, enabled, notes
                    ) VALUES (
                        @unit_code, @item_code, @drop_chance, @min_qty, @max_qty,
                        @guaranteed, @weight, @enabled, @notes
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
        public void Update(UnitSpecificDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE unit_specific_drops SET
                        drop_chance = @drop_chance,
                        min_quantity = @min_qty,
                        max_quantity = @max_qty,
                        is_guaranteed = @guaranteed,
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
                    "DELETE FROM unit_specific_drops WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete all specific drops for a unit
        /// </summary>
        public void DeleteByUnitCode(string unitCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(
                    "DELETE FROM unit_specific_drops WHERE unit_code = @code", conn))
                {
                    cmd.Parameters.AddWithValue("@code", unitCode);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Check if specific drop exists for unit+item combination
        /// </summary>
        public bool Exists(string unitCode, string itemCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT 1 FROM unit_specific_drops 
                    WHERE unit_code = @unit AND item_code = @item LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@unit", unitCode);
                    cmd.Parameters.AddWithValue("@item", itemCode);
                    return cmd.ExecuteScalar() != null;
                }
            }
        }

        private UnitSpecificDrop MapToUnitSpecificDrop(NpgsqlDataReader reader)
        {
            return new UnitSpecificDrop
            {
                Id = reader.GetInt32(0),
                UnitCode = reader.GetString(1),
                ItemCode = reader.GetString(2),
                DropChance = reader.GetDecimal(3),
                MinQuantity = reader.GetInt32(4),
                MaxQuantity = reader.GetInt32(5),
                IsGuaranteed = reader.GetBoolean(6),
                Weight = reader.GetInt32(7),
                Enabled = reader.GetBoolean(8),
                Notes = reader.IsDBNull(9) ? null : reader.GetString(9),
                CreatedAt = reader.GetDateTime(10),
                UnitName = reader.GetString(11),
                ItemName = reader.GetString(12),
                ItemRarity = reader.IsDBNull(13) ? null : reader.GetString(13)
            };
        }

        private void AddParameters(NpgsqlCommand cmd, UnitSpecificDrop drop)
        {
            cmd.Parameters.AddWithValue("@unit_code", drop.UnitCode);
            cmd.Parameters.AddWithValue("@item_code", drop.ItemCode);
            cmd.Parameters.AddWithValue("@drop_chance", drop.DropChance);
            cmd.Parameters.AddWithValue("@min_qty", drop.MinQuantity);
            cmd.Parameters.AddWithValue("@max_qty", drop.MaxQuantity);
            cmd.Parameters.AddWithValue("@guaranteed", drop.IsGuaranteed);
            cmd.Parameters.AddWithValue("@weight", drop.Weight);
            cmd.Parameters.AddWithValue("@enabled", drop.Enabled);
            cmd.Parameters.AddWithValue("@notes", (object)drop.Notes ?? DBNull.Value);
        }
    }
}
