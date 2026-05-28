using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Repository for loot_table_items table operations
    /// </summary>
    public class LootTableItemRepository
    {
        private readonly string _connectionString;

        public LootTableItemRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        public List<LootTableItem> GetByLootTableId(int lootTableId)
        {
            var items = new List<LootTableItem>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT lti.id, lti.loot_table_id, lti.item_code, lti.drop_chance, lti.weight,
                           lti.is_guaranteed, lti.quantity_min, lti.quantity_max, lti.notes, lti.created_at,
                           i.item_name, r.rarity_name, 
                           COALESCE(i.item_level_unclassified, i.item_level) as item_level
                    FROM loot_table_items lti
                    LEFT JOIN items i ON i.item_code = lti.item_code
                    LEFT JOIN item_rarities r ON r.id = i.rarity_id
                    WHERE lti.loot_table_id = @loot_table_id
                    ORDER BY lti.is_guaranteed DESC, lti.weight DESC, lti.drop_chance DESC", conn))
                {
                    cmd.Parameters.AddWithValue("@loot_table_id", lootTableId);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add(MapFromReader(reader));
                        }
                    }
                }
            }

            return items;
        }

        public LootTableItem GetById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT lti.id, lti.loot_table_id, lti.item_code, lti.drop_chance, lti.weight,
                           lti.is_guaranteed, lti.quantity_min, lti.quantity_max, lti.notes, lti.created_at,
                           i.item_name, r.rarity_name,
                           COALESCE(i.item_level_unclassified, i.item_level) as item_level
                    FROM loot_table_items lti
                    LEFT JOIN items i ON i.item_code = lti.item_code
                    LEFT JOIN item_rarities r ON r.id = i.rarity_id
                    WHERE lti.id = @id", conn))
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

        public bool ItemExistsInTable(int lootTableId, string itemCode)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT COUNT(*) FROM loot_table_items 
                    WHERE loot_table_id = @loot_table_id AND item_code = @item_code", conn))
                {
                    cmd.Parameters.AddWithValue("@loot_table_id", lootTableId);
                    cmd.Parameters.AddWithValue("@item_code", itemCode);
                    return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
                }
            }
        }

        public int Insert(LootTableItem item)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO loot_table_items (loot_table_id, item_code, drop_chance, weight,
                                                   is_guaranteed, quantity_min, quantity_max, notes)
                    VALUES (@loot_table_id, @item_code, @drop_chance, @weight,
                            @is_guaranteed, @quantity_min, @quantity_max, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@loot_table_id", item.LootTableId);
                    cmd.Parameters.AddWithValue("@item_code", item.ItemCode);
                    cmd.Parameters.AddWithValue("@drop_chance", item.DropChance);
                    cmd.Parameters.AddWithValue("@weight", item.Weight);
                    cmd.Parameters.AddWithValue("@is_guaranteed", item.IsGuaranteed);
                    cmd.Parameters.AddWithValue("@quantity_min", item.QuantityMin);
                    cmd.Parameters.AddWithValue("@quantity_max", item.QuantityMax);
                    cmd.Parameters.AddWithValue("@notes", (object)item.Notes ?? DBNull.Value);

                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void Update(LootTableItem item)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE loot_table_items
                    SET item_code = @item_code, drop_chance = @drop_chance, weight = @weight,
                        is_guaranteed = @is_guaranteed, quantity_min = @quantity_min,
                        quantity_max = @quantity_max, notes = @notes
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", item.Id);
                    cmd.Parameters.AddWithValue("@item_code", item.ItemCode);
                    cmd.Parameters.AddWithValue("@drop_chance", item.DropChance);
                    cmd.Parameters.AddWithValue("@weight", item.Weight);
                    cmd.Parameters.AddWithValue("@is_guaranteed", item.IsGuaranteed);
                    cmd.Parameters.AddWithValue("@quantity_min", item.QuantityMin);
                    cmd.Parameters.AddWithValue("@quantity_max", item.QuantityMax);
                    cmd.Parameters.AddWithValue("@notes", (object)item.Notes ?? DBNull.Value);

                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void Delete(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM loot_table_items WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteByLootTableId(int lootTableId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM loot_table_items WHERE loot_table_id = @loot_table_id", conn))
                {
                    cmd.Parameters.AddWithValue("@loot_table_id", lootTableId);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private LootTableItem MapFromReader(NpgsqlDataReader reader)
        {
            return new LootTableItem
            {
                Id = reader.GetInt32(0),
                LootTableId = reader.GetInt32(1),
                ItemCode = reader.GetString(2),
                DropChance = reader.GetInt32(3),
                Weight = reader.GetInt32(4),
                IsGuaranteed = reader.GetBoolean(5),
                QuantityMin = reader.GetInt32(6),
                QuantityMax = reader.GetInt32(7),
                Notes = reader.IsDBNull(8) ? null : reader.GetString(8),
                CreatedAt = reader.GetDateTime(9),
                ItemName = reader.IsDBNull(10) ? reader.GetString(2) : reader.GetString(10),
                ItemRarity = reader.IsDBNull(11) ? null : reader.GetString(11),
                ItemLevel = reader.IsDBNull(12) ? null : (int?)reader.GetInt32(12)
            };
        }
    }
}
