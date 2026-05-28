using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Npgsql;

namespace WC3ItemManager
{
    /// <summary>
    /// Generates tooltips and descriptions for items based on stats and properties
    /// </summary>
    public class TooltipGenerator
    {
        private string connectionString;
        private ColorManager colorManager;
        private TooltipPhrasesLoader phrasesLoader;

        public TooltipGenerator(string connectionString, ColorManager colorManager)
        {
            this.connectionString = connectionString;
            this.colorManager = colorManager;
            this.phrasesLoader = TooltipPhrasesLoader.Instance;
            
            // Ensure phrases are loaded
            if (!phrasesLoader.IsLoaded)
            {
                phrasesLoader.LoadPhrases();
            }
        }

        public string GenerateExtendedTooltip(
            string itemName,
            string rarityName,
            int itemLevel,
            List<ItemStatValue> stats,
            string abilities,
            string className,
            string requirements = null)
        {
            StringBuilder tooltip = new StringBuilder();

            // Header: [Type, Rarity] with WC3 color codes
            string typeColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("class", className) ?? "#A52A2A");
            string rarityColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("rarity", rarityName) ?? "#90EE90");
            tooltip.Append($"[{typeColor}{className}|r, {rarityColor}{rarityName}|r]");

            // Stats section with proper WC3 format
            if (stats != null && stats.Count > 0)
            {
                tooltip.Append("|n"); // Empty line after header
                foreach (var statValue in stats.OrderBy(s => s.Stat.DisplayOrder))
                {
                    // Get color from stat's own color or default
                    string statColorHex = !string.IsNullOrEmpty(statValue.Stat.ColorHex) ? 
                        statValue.Stat.ColorHex : 
                        (statValue.Value >= 0 ? "#FF6347" : "#FF4444");
                    
                    string statColor = colorManager.GetWC3ColorCode(statColorHex);
                    
                    // Format: DisplayFormat already contains +/- sign, just replace {value}
                    string formattedValue = statValue.Stat.DisplayFormat
                        .Replace("{value}", statValue.Value.ToString("0.##"));
                    
                    tooltip.Append($"|n{statColor}{formattedValue} {statValue.Stat.Name}|r");
                }
            }

            // Abilities are no longer shown in tooltip - they're hidden technical codes for stats (A04H, etc.)
            // User-defined abilities and their descriptions should be added manually to the tooltip/description field

            // Requirements
            if (!string.IsNullOrWhiteSpace(requirements))
            {
                tooltip.Append("|n|c00D3D3D3r|r"); // Separator
                tooltip.Append($"|n|cFFFF0000Requires: {requirements}|r");
            }

            return tooltip.ToString();
        }

        public string GenerateDescription(
            string itemName,
            string className,
            string rarityName,
            int itemLevel,
            List<ItemStatValue> stats)
        {
            StringBuilder desc = new StringBuilder();

            // Header: [Type, Rarity] with WC3 color codes
            string typeColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("class", className) ?? "#A52A2A");
            string rarityColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("rarity", rarityName) ?? "#90EE90");
            desc.Append($"[{typeColor}{className}|r, {rarityColor}{rarityName}|r]");

            // Stats section with proper WC3 format
            if (stats != null && stats.Count > 0)
            {
                desc.Append("|n"); // Empty line after header
                foreach (var statValue in stats.OrderBy(s => s.Stat.DisplayOrder))
                {
                    // Get color from stat's own color or default
                    string statColorHex = !string.IsNullOrEmpty(statValue.Stat.ColorHex) ? 
                        statValue.Stat.ColorHex : 
                        (statValue.Value >= 0 ? "#FF6347" : "#FF4444");
                    
                    string statColor = colorManager.GetWC3ColorCode(statColorHex);
                    
                    // Format: DisplayFormat already contains +/- sign, just replace {value}
                    string formattedValue = statValue.Stat.DisplayFormat
                        .Replace("{value}", statValue.Value.ToString("0.##"));
                    
                    desc.Append($"|n{statColor}{formattedValue} {statValue.Stat.Name}|r");
                }
            }

            return desc.ToString();
        }

        public string GenerateSimpleTooltip(string itemName, string className, int itemLevel)
        {
            return $"{itemName} - Level {itemLevel} {className} item";
        }
        
        /// <summary>
        /// Generates ONLY descriptive/lore text without stats (for Extended Tooltip field)
        /// </summary>
        public string GenerateDescriptiveText(
            string itemName,
            string className,
            string rarityName,
            int itemLevel,
            List<ItemStatValue> stats)
        {
            StringBuilder desc = new StringBuilder();
            
            // Generate flavor text based on rarity (with random variation)
            string flavorText = GetFlavorTextForRarity(rarityName);
            desc.Append(flavorText);
            
            // Add context based on dominant stat if available
            if (stats != null && stats.Count > 0)
            {
                var dominantStat = stats.OrderByDescending(s => Math.Abs(s.Value)).FirstOrDefault();
                if (dominantStat != null && dominantStat.Stat != null)
                {
                    string loreHint = GenerateLoreForStat(dominantStat.Stat.Code);
                    if (!string.IsNullOrEmpty(loreHint))
                    {
                        desc.Append("|n|n");
                        desc.Append(loreHint);
                    }
                }
            }
            
            // Add rarity-specific closing
            desc.Append("|n|n");
            desc.Append(GetRarityClosing(rarityName));
            
            return desc.ToString();
        }

        private string GetRarityClosing(string rarity)
        {
            return phrasesLoader.GetClosingLine(rarity);
        }

        private string GenerateLoreForStat(string statCode)
        {
            return phrasesLoader.GetDominantStatLore(statCode);
        }

        private string GetFlavorTextForRarity(string rarity)
        {
            return phrasesLoader.GetRarityPhrase(rarity);
        }

        private string GetAbilityName(string abilityCode)
        {
            // Try to get ability name from database
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    // You would need an abilities table for this
                    // For now, return the code
                    return abilityCode;
                }
            }
            catch
            {
                return abilityCode;
            }
        }

        public List<ItemStatValue> LoadItemStats(int itemId)
        {
            var stats = new List<ItemStatValue>();
            
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = @"
                        SELECT isv.item_id, isv.stat_id, isv.stat_value, isv.sort_order,
                               s.stat_code, s.stat_name, s.stat_description, 
                               s.display_format, s.color_hex, s.display_order
                        FROM item_stat_values isv
                        JOIN item_stats s ON isv.stat_id = s.id
                        WHERE isv.item_id = @itemId AND s.is_active = true
                        ORDER BY isv.sort_order, s.display_order";
                    
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("itemId", itemId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var stat = new ItemStat
                                {
                                    Id = Convert.ToInt32(reader["stat_id"]),
                                    Code = reader["stat_code"].ToString(),
                                    Name = reader["stat_name"].ToString(),
                                    Description = reader["stat_description"]?.ToString(),
                                    DisplayFormat = reader["display_format"]?.ToString() ?? "{value}",
                                    ColorHex = reader["color_hex"]?.ToString() ?? "#FFFFFF",
                                    DisplayOrder = reader["display_order"] != DBNull.Value ? 
                                        Convert.ToInt32(reader["display_order"]) : 0
                                };

                                stats.Add(new ItemStatValue
                                {
                                    ItemId = Convert.ToInt32(reader["item_id"]),
                                    StatId = stat.Id,
                                    Value = Convert.ToDecimal(reader["stat_value"]),
                                    Stat = stat
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading item stats: {ex.Message}");
            }

            return stats;
        }

        public void SaveItemStats(int itemId, List<ItemStatValue> stats)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    
                    // Delete existing stats
                    using (var cmd = new NpgsqlCommand("DELETE FROM item_stat_values WHERE item_id = @itemId", conn))
                    {
                        cmd.Parameters.AddWithValue("itemId", itemId);
                        cmd.ExecuteNonQuery();
                    }
                    
                    // Insert new stats
                    int sortOrder = 0;
                    foreach (var stat in stats)
                    {
                        if (stat.Value != 0) // Only save non-zero values
                        {
                            string insert = @"
                                INSERT INTO item_stat_values (item_id, stat_id, stat_value, sort_order)
                                VALUES (@itemId, @statId, @value, @sortOrder)";
                            
                            using (var cmd = new NpgsqlCommand(insert, conn))
                            {
                                cmd.Parameters.AddWithValue("itemId", itemId);
                                cmd.Parameters.AddWithValue("statId", stat.StatId);
                                cmd.Parameters.AddWithValue("value", stat.Value);
                                cmd.Parameters.AddWithValue("sortOrder", sortOrder++);
                                cmd.ExecuteNonQuery();
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                throw new Exception($"Error saving item stats: {ex.Message}");
            }
        }

        public List<ItemStat> LoadAllStats()
        {
            var stats = new List<ItemStat>();
            
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "SELECT * FROM item_stats WHERE is_active = true ORDER BY display_order";
                    
                    using (var cmd = new NpgsqlCommand(query, conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            stats.Add(new ItemStat
                            {
                                Id = Convert.ToInt32(reader["id"]),
                                Code = reader["stat_code"].ToString(),
                                Name = reader["stat_name"].ToString(),
                                Description = reader["stat_description"]?.ToString(),
                                DisplayFormat = reader["display_format"]?.ToString() ?? "{value}",
                                ColorHex = reader["color_hex"]?.ToString() ?? "#FFFFFF",
                                DisplayOrder = reader["display_order"] != DBNull.Value ? 
                                    Convert.ToInt32(reader["display_order"]) : 0
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading stats: {ex.Message}");
            }

            return stats;
        }
    }
}
