using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for LootTier entities
    /// </summary>
    public class LootTierRepository
    {
        private readonly string _connectionString;

        public LootTierRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        /// <summary>
        /// Get all loot tiers
        /// </summary>
        public List<LootTier> GetAll()
        {
            var tiers = new List<LootTier>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
                           common_item_level, uncommon_item_level, rare_item_level, 
                           epic_item_level, legendary_item_level, artifact_item_level,
                           common_weight, uncommon_weight, rare_weight, 
                           epic_weight, legendary_weight, artifact_weight,
                           enabled, created_at
                    FROM loot_tiers
                    ORDER BY min_unit_level", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            tiers.Add(MapToLootTier(reader));
                        }
                    }
                }
            }
            
            return tiers;
        }

        /// <summary>
        /// Get a loot tier by ID
        /// </summary>
        public LootTier GetById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
                           common_item_level, uncommon_item_level, rare_item_level, 
                           epic_item_level, legendary_item_level, artifact_item_level,
                           common_weight, uncommon_weight, rare_weight, 
                           epic_weight, legendary_weight, artifact_weight,
                           enabled, created_at
                    FROM loot_tiers
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToLootTier(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        /// <summary>
        /// Get loot tier for a unit level
        /// </summary>
        public LootTier GetForUnitLevel(int unitLevel)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
                           common_item_level, uncommon_item_level, rare_item_level, 
                           epic_item_level, legendary_item_level, artifact_item_level,
                           common_weight, uncommon_weight, rare_weight, 
                           epic_weight, legendary_weight, artifact_weight,
                           enabled, created_at
                    FROM loot_tiers
                    WHERE enabled = true AND @level BETWEEN min_unit_level AND max_unit_level
                    ORDER BY min_unit_level
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@level", unitLevel);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToLootTier(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        /// <summary>
        /// Insert a new loot tier
        /// </summary>
        public int Insert(LootTier tier)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO loot_tiers (
                        tier_name, min_unit_level, max_unit_level, description, drop_chance_base,
                        common_item_level, uncommon_item_level, rare_item_level,
                        epic_item_level, legendary_item_level, artifact_item_level,
                        common_weight, uncommon_weight, rare_weight,
                        epic_weight, legendary_weight, artifact_weight,
                        enabled
                    ) VALUES (
                        @tier_name, @min_level, @max_level, @description, @drop_chance,
                        @common_level, @uncommon_level, @rare_level,
                        @epic_level, @legendary_level, @artifact_level,
                        @common_weight, @uncommon_weight, @rare_weight,
                        @epic_weight, @legendary_weight, @artifact_weight,
                        @enabled
                    ) RETURNING id", conn))
                {
                    AddParameters(cmd, tier);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        /// <summary>
        /// Update an existing loot tier
        /// </summary>
        public void Update(LootTier tier)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE loot_tiers SET
                        tier_name = @tier_name,
                        min_unit_level = @min_level,
                        max_unit_level = @max_level,
                        description = @description,
                        drop_chance_base = @drop_chance,
                        common_item_level = @common_level,
                        uncommon_item_level = @uncommon_level,
                        rare_item_level = @rare_level,
                        epic_item_level = @epic_level,
                        legendary_item_level = @legendary_level,
                        artifact_item_level = @artifact_level,
                        common_weight = @common_weight,
                        uncommon_weight = @uncommon_weight,
                        rare_weight = @rare_weight,
                        epic_weight = @epic_weight,
                        legendary_weight = @legendary_weight,
                        artifact_weight = @artifact_weight,
                        enabled = @enabled
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", tier.Id);
                    AddParameters(cmd, tier);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Delete a loot tier
        /// </summary>
        public void Delete(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM loot_tiers WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Get count of items matching each rarity for a tier
        /// </summary>
        public Dictionary<string, int> GetItemCountsForTier(LootTier tier)
        {
            var counts = new Dictionary<string, int>
            {
                { "Common", 0 },
                { "Uncommon", 0 },
                { "Rare", 0 },
                { "Epic", 0 },
                { "Legendary", 0 },
                { "Artifact", 0 }
            };

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                
                // Count items by rarity that match tier's item levels
                using (var cmd = new NpgsqlCommand(@"
                    SELECT r.rarity_name, COUNT(i.id) as cnt
                    FROM items i
                    JOIN item_rarities r ON i.rarity_id = r.id
                    WHERE (i.item_level = @common_level AND r.rarity_level = 0)
                       OR (i.item_level = @uncommon_level AND r.rarity_level = 1)
                       OR (i.item_level = @rare_level AND r.rarity_level = 2)
                       OR (i.item_level = @epic_level AND r.rarity_level = 3)
                       OR (i.item_level = @legendary_level AND r.rarity_level = 4)
                       OR (i.item_level = @artifact_level AND r.rarity_level = 5)
                    GROUP BY r.rarity_name", conn))
                {
                    cmd.Parameters.AddWithValue("@common_level", (object)tier.CommonItemLevel ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@uncommon_level", (object)tier.UncommonItemLevel ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@rare_level", (object)tier.RareItemLevel ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@epic_level", (object)tier.EpicItemLevel ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@legendary_level", (object)tier.LegendaryItemLevel ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@artifact_level", (object)tier.ArtifactItemLevel ?? DBNull.Value);

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string rarity = reader.GetString(0);
                            int count = reader.GetInt32(1);
                            if (counts.ContainsKey(rarity))
                            {
                                counts[rarity] = count;
                            }
                        }
                    }
                }
            }

            return counts;
        }

        private LootTier MapToLootTier(NpgsqlDataReader reader)
        {
            return new LootTier
            {
                Id = reader.GetInt32(0),
                TierName = reader.GetString(1),
                MinUnitLevel = reader.GetInt32(2),
                MaxUnitLevel = reader.GetInt32(3),
                Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                DropChanceBase = reader.GetDecimal(5),
                CommonItemLevel = reader.IsDBNull(6) ? null : reader.GetInt32(6),
                UncommonItemLevel = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                RareItemLevel = reader.IsDBNull(8) ? null : reader.GetInt32(8),
                EpicItemLevel = reader.IsDBNull(9) ? null : reader.GetInt32(9),
                LegendaryItemLevel = reader.IsDBNull(10) ? null : reader.GetInt32(10),
                ArtifactItemLevel = reader.IsDBNull(11) ? null : reader.GetInt32(11),
                CommonWeight = reader.GetInt32(12),
                UncommonWeight = reader.GetInt32(13),
                RareWeight = reader.GetInt32(14),
                EpicWeight = reader.GetInt32(15),
                LegendaryWeight = reader.GetInt32(16),
                ArtifactWeight = reader.GetInt32(17),
                Enabled = reader.GetBoolean(18),
                CreatedAt = reader.GetDateTime(19)
            };
        }

        private void AddParameters(NpgsqlCommand cmd, LootTier tier)
        {
            cmd.Parameters.AddWithValue("@tier_name", tier.TierName);
            cmd.Parameters.AddWithValue("@min_level", tier.MinUnitLevel);
            cmd.Parameters.AddWithValue("@max_level", tier.MaxUnitLevel);
            cmd.Parameters.AddWithValue("@description", (object)tier.Description ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@drop_chance", tier.DropChanceBase);
            cmd.Parameters.AddWithValue("@common_level", (object)tier.CommonItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@uncommon_level", (object)tier.UncommonItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@rare_level", (object)tier.RareItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@epic_level", (object)tier.EpicItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@legendary_level", (object)tier.LegendaryItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@artifact_level", (object)tier.ArtifactItemLevel ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@common_weight", tier.CommonWeight);
            cmd.Parameters.AddWithValue("@uncommon_weight", tier.UncommonWeight);
            cmd.Parameters.AddWithValue("@rare_weight", tier.RareWeight);
            cmd.Parameters.AddWithValue("@epic_weight", tier.EpicWeight);
            cmd.Parameters.AddWithValue("@legendary_weight", tier.LegendaryWeight);
            cmd.Parameters.AddWithValue("@artifact_weight", tier.ArtifactWeight);
            cmd.Parameters.AddWithValue("@enabled", tier.Enabled);
        }
    }
}
