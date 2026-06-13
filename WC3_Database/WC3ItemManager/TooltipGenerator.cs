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
        private readonly Random random = new Random();

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
            string typeColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("class", className, ItemClassColorDefaults.GetHex(className)) ?? ItemClassColorDefaults.GetHex(className));
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
            string typeColor = colorManager.GetWC3ColorCode(colorManager.GetColorHex("class", className, ItemClassColorDefaults.GetHex(className)) ?? ItemClassColorDefaults.GetHex(className));
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
            var sections = new List<string>();

            string intro = CombineSentences(
                GetFlavorTextForRarity(rarityName),
                GetClassFlavorText(className),
                GenerateIdentityLine(className, rarityName, itemLevel));
            AddSection(sections, intro);

            string profileLore = GenerateProfileLore(className, itemLevel, stats);
            AddSection(sections, profileLore);

            string statLore = GenerateDominantStatLore(stats);
            AddSection(sections, statLore);

            string closing = CombineSentences(
                GenerateLevelBandLore(className, rarityName, itemLevel),
                GetRarityClosing(rarityName));
            AddSection(sections, closing);

            return string.Join("|n|n", sections);
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

        private string GetClassFlavorText(string className)
        {
            if (string.IsNullOrWhiteSpace(className))
            {
                return null;
            }

            string phrase = phrasesLoader.GetClassPhrase(className);
            if (!string.IsNullOrWhiteSpace(phrase))
            {
                return phrase;
            }

            string normalizedClass = NormalizeItemClass(className);
            if (!string.Equals(normalizedClass, className, StringComparison.OrdinalIgnoreCase))
            {
                phrase = phrasesLoader.GetClassPhrase(normalizedClass);
                if (!string.IsNullOrWhiteSpace(phrase))
                {
                    return phrase;
                }
            }

            return null;
        }

        private string GenerateIdentityLine(string className, string rarityName, int itemLevel)
        {
            string normalizedClass = NormalizeItemClass(className);
            string rarityTone = GetRarityTone(rarityName);
            string levelTone = GetLevelTierLabel(itemLevel);

            string[] templates = normalizedClass switch
            {
                "Weapon" => new[]
                {
                    $"A {levelTone.ToLowerInvariant()} weapon carrying {rarityTone.ToLowerInvariant()} intent.",
                    $"This {rarityName.ToLowerInvariant()} armament bears the feel of a {levelTone.ToLowerInvariant()} killer.",
                    $"Made for direct action, it wears its {rarityTone.ToLowerInvariant()} nature openly."
                },
                "Armor" => new[]
                {
                    $"A {levelTone.ToLowerInvariant()} defense piece shaped for long campaigns.",
                    $"Its craft speaks of endurance, discipline, and {rarityTone.ToLowerInvariant()} resilience.",
                    $"Built to outlast punishment, it carries the weight of seasoned wars."
                },
                "Ring" => new[]
                {
                    $"A compact focus of {rarityTone.ToLowerInvariant()} power with a {levelTone.ToLowerInvariant()} presence.",
                    $"Though small in form, it feels like the work of a {levelTone.ToLowerInvariant()} enchanter.",
                    $"Its influence is subtle in shape, but not in consequence."
                },
                "Amulet" => new[]
                {
                    $"A {rarityTone.ToLowerInvariant()} charm worn close for constant effect.",
                    $"Its power lingers near the heart, calm but unmistakable.",
                    $"This pendant feels meant for a bearer beyond common trials."
                },
                "Consumable" => new[]
                {
                    $"Prepared for a decisive moment, not for idle keeping.",
                    $"A short-lived answer with {rarityTone.ToLowerInvariant()} impact.",
                    $"Its purpose is immediate, practical, and battlefield-ready."
                },
                "Material" => new[]
                {
                    $"Unworked potential rests inside every fragment.",
                    $"Craftsmen would judge it first by purity, then by promise.",
                    $"Even before shaping, it carries the feel of something valuable."
                },
                _ => new[]
                {
                    $"Its form suggests a {levelTone.ToLowerInvariant()} piece of {rarityTone.ToLowerInvariant()} make.",
                    $"There is more intention in this item than its surface first reveals.",
                    $"Its construction hints at careful purpose rather than mere decoration."
                }
            };

            return PickRandom(templates);
        }

        private string GenerateProfileLore(string className, int itemLevel, List<ItemStatValue> stats)
        {
            string normalizedClass = NormalizeItemClass(className);
            string profile = DetermineStatProfile(stats);
            string tier = GetLevelTierLabel(itemLevel).ToLowerInvariant();

            string[] lines = profile switch
            {
                "Bruiser" => new[]
                {
                    $"Its power favors direct confrontation, rewarding force, staying power, and relentless pressure.",
                    $"This is the kind of {tier} piece carried by fighters who win by breaking the line in front of them.",
                    $"Everything about it points toward momentum, impact, and front-line brutality."
                },
                "Assassin" => new[]
                {
                    $"Its enchantments lean toward speed, timing, and the kind of precision that ends fights quickly.",
                    $"The item rewards quick hands and cleaner kills rather than drawn-out exchanges.",
                    $"Built for sudden violence, it favors movement, accuracy, and punishing openings."
                },
                "Caster" => new[]
                {
                    $"Arcane currents gather around it, favoring focus, reserve, and controlled spellcraft.",
                    $"Its strength lies in channeling thought into force rather than muscle into impact.",
                    $"The item feels tuned for concentration, magical output, and sustained casting."
                },
                "Guardian" => new[]
                {
                    $"Its design favors patience and resistance, turning pressure aside rather than racing to answer it.",
                    $"This piece feels made for those who hold ground while others falter.",
                    $"Protection comes first here, with every quality angled toward survival and control."
                },
                "Predator" => new[]
                {
                    $"It carries a hungry edge, rewarding pursuit, pressure, and the refusal to let prey recover.",
                    $"The item feels most alive in extended hunts where momentum keeps feeding itself.",
                    $"Its strengths point toward aggression that sharpens as the fight continues."
                },
                "Hybrid" => new[]
                {
                    $"Its strengths are mixed with intent, blending offense, utility, and resilience into a more flexible whole.",
                    $"Rather than commit to a single discipline, it supports a bearer who adapts on instinct.",
                    $"The item seems built for versatility, answering changing fights with changing strengths."
                },
                _ => null
            };

            string classBias = normalizedClass switch
            {
                "Weapon" when profile == "Caster" => "A weapon like this serves as much as a conduit as it does an instrument of war.",
                "Armor" when profile == "Assassin" => "Even its protection feels tailored for mobility rather than simple weight.",
                "Armor" when profile == "Guardian" => "Every layer seems chosen to keep its bearer standing long after others would fall.",
                "Ring" when profile == "Caster" => "Its power reads less like ornament and more like a sealed focus.",
                "Amulet" when profile == "Guardian" => "It feels protective in a way that borders on ritual.",
                "Consumable" => "Its value lies in choosing the exact right moment to unleash it.",
                _ => null
            };

            return CombineSentences(PickRandom(lines), classBias);
        }

        private string GenerateDominantStatLore(List<ItemStatValue> stats)
        {
            if (stats == null || stats.Count == 0)
            {
                return null;
            }

            var topStats = stats
                .Where(s => s?.Stat != null)
                .OrderByDescending(s => Math.Abs(s.Value))
                .Take(2)
                .ToList();

            if (topStats.Count == 0)
            {
                return null;
            }

            string dominantLore = GenerateLoreForStat(topStats[0].Stat.Code);
            if (topStats.Count == 1)
            {
                return dominantLore;
            }

            string pairLore = GenerateStatPairLore(topStats[0].Stat.Code, topStats[1].Stat.Code);
            return CombineSentences(pairLore, dominantLore);
        }

        private string GenerateStatPairLore(string firstStatCode, string secondStatCode)
        {
            string first = CanonicalizeStatCode(firstStatCode);
            string second = CanonicalizeStatCode(secondStatCode);
            string pairKey = string.Join("+", new[] { first, second }.OrderBy(s => s));

            string[] lines = pairKey switch
            {
                "Armor+Strength" => new[]
                {
                    "Power and protection meet here in equal measure.",
                    "Its craft marries heavy impact with the discipline to endure the return blow."
                },
                "Agility+Critical" => new[]
                {
                    "Its strengths favor clean execution over prolonged struggle.",
                    "Swiftness and lethal precision are woven tightly together in its design."
                },
                "Intelligence+Mana" => new[]
                {
                    "The item supports a deeper reserve for minds that shape battle through spellcraft.",
                    "It feels made for steady casting, not reckless bursts."
                },
                "AttackSpeed+Damage" => new[]
                {
                    "Every quality pushes toward constant pressure and mounting harm.",
                    "Speed and force reinforce one another with little wasted motion."
                },
                "Health+Regeneration" => new[]
                {
                    "Its power is patient, restoring what battle tries to take away.",
                    "Endurance is its language, written slowly but relentlessly."
                },
                "Critical+Damage" => new[]
                {
                    "It was not made for soft exchanges; it was made to end them.",
                    "Its strengths concentrate on the kind of strikes that decide outcomes immediately."
                },
                "Lifesteal+MovementSpeed" => new[]
                {
                    "It rewards pursuit, contact, and never giving distance back once taken.",
                    "The item feels predatory, built for hunters rather than duelists."
                },
                "Armor+Health" => new[]
                {
                    "Durability is layered into it from every angle.",
                    "This item values staying power above spectacle."
                },
                "Intelligence+SpellPower" => new[]
                {
                    "Its enchantments favor disciplined minds and heavier spell impact.",
                    "The item feels tuned for casters who prefer quality of magic over haste."
                },
                _ => null
            };

            return PickRandom(lines);
        }

        private string GenerateLevelBandLore(string className, string rarityName, int itemLevel)
        {
            string normalizedClass = NormalizeItemClass(className);

            string[] lines = itemLevel switch
            {
                < 10 => new[]
                {
                    $"It feels suited to first real campaigns, where skill matters more than renown.",
                    $"There is modest power here, but it is honest power that earns its keep early."
                },
                < 25 => new[]
                {
                    $"It belongs to the stage where adventurers stop surviving by luck alone.",
                    $"Its quality suggests a bearer already tested beyond the village road."
                },
                < 50 => new[]
                {
                    $"This is the sort of item carried by proven hands, not fresh recruits.",
                    $"Its power feels established, reliable, and ready for harsher terrain."
                },
                < 75 => new[]
                {
                    $"It bears the confidence of equipment chosen for major campaigns.",
                    $"This piece feels like veteran gear, meant for battles with real consequences."
                },
                < 90 => new[]
                {
                    $"Only seasoned champions would treat such power as routine equipment.",
                    $"Its presence suggests conflicts where ordinary gear would simply not suffice."
                },
                _ => new[]
                {
                    $"There is endgame weight to it, the kind carried into defining battles.",
                    $"Its power belongs to the upper edge of mortal conflict."
                }
            };

            string classTail = normalizedClass switch
            {
                "Weapon" => "Weapons of this caliber are remembered by the wounds they leave behind.",
                "Armor" => "Armor like this is trusted when failure is not an acceptable outcome.",
                "Ring" => "A ring of this quality is rarely worn without purpose.",
                "Amulet" => "Amulets of this grade tend to pass between exceptional bearers.",
                _ => null
            };

            return CombineSentences(PickRandom(lines), classTail);
        }

        private string NormalizeItemClass(string className)
        {
            if (string.IsNullOrWhiteSpace(className))
            {
                return "Misc";
            }

            string normalized = className.Trim().ToLowerInvariant();

            if (normalized.Contains("ring"))
            {
                return "Ring";
            }

            if (normalized.Contains("amulet") || normalized.Contains("necklace") || normalized.Contains("pendant"))
            {
                return "Amulet";
            }

            if (normalized.Contains("consumable") || normalized.Contains("potion") || normalized.Contains("elixir") ||
                normalized.Contains("scroll") || normalized.Contains("food") || normalized.Contains("flask"))
            {
                return "Consumable";
            }

            if (normalized.Contains("material") || normalized.Contains("reagent") || normalized.Contains("ore") ||
                normalized.Contains("herb") || normalized.Contains("cloth") || normalized.Contains("leather"))
            {
                return "Material";
            }

            if (normalized.Contains("trinket") || normalized.Contains("relic") || normalized.Contains("idol") ||
                normalized.Contains("totem") || normalized.Contains("charm"))
            {
                return "Trinket";
            }

            if (normalized.Contains("armor") || normalized.Contains("helm") || normalized.Contains("helmet") ||
                normalized.Contains("hood") || normalized.Contains("cap") || normalized.Contains("chest") ||
                normalized.Contains("robe") || normalized.Contains("boots") || normalized.Contains("gloves") ||
                normalized.Contains("belt") || normalized.Contains("bracer") || normalized.Contains("shoulder") ||
                normalized.Contains("cloak") || normalized.Contains("shield"))
            {
                return "Armor";
            }

            if (normalized.Contains("weapon") || normalized.Contains("sword") || normalized.Contains("axe") ||
                normalized.Contains("mace") || normalized.Contains("hammer") || normalized.Contains("dagger") ||
                normalized.Contains("bow") || normalized.Contains("staff") || normalized.Contains("wand") ||
                normalized.Contains("gun") || normalized.Contains("spear"))
            {
                return "Weapon";
            }

            return className;
        }

        private string DetermineStatProfile(List<ItemStatValue> stats)
        {
            if (stats == null || stats.Count == 0)
            {
                return null;
            }

            decimal offense = 0;
            decimal defense = 0;
            decimal caster = 0;
            decimal mobility = 0;
            decimal sustain = 0;

            foreach (var statValue in stats.Where(s => s?.Stat != null))
            {
                decimal weight = Math.Abs(statValue.Value);
                switch (CanonicalizeStatCode(statValue.Stat.Code))
                {
                    case "Strength":
                    case "Damage":
                    case "MeleeDamage":
                    case "RangedDamage":
                    case "Critical":
                    case "AttackSpeed":
                    case "Accuracy":
                        offense += weight;
                        break;
                    case "Armor":
                    case "PhysicalResist":
                    case "MagicResist":
                    case "Block":
                    case "Health":
                        defense += weight;
                        break;
                    case "Intelligence":
                    case "Mana":
                    case "SpellPower":
                        caster += weight;
                        break;
                    case "Agility":
                    case "MovementSpeed":
                    case "Evasion":
                    case "Range":
                        mobility += weight;
                        break;
                    case "Regeneration":
                    case "Lifesteal":
                    case "Vitality":
                        sustain += weight;
                        break;
                }
            }

            if (caster > offense && caster >= defense && caster >= mobility)
            {
                return "Caster";
            }

            if (defense >= offense && defense >= mobility && defense + sustain > caster)
            {
                return "Guardian";
            }

            if (mobility + offense > defense + caster && mobility > 0)
            {
                return sustain > 0 ? "Predator" : "Assassin";
            }

            if (offense > 0 && defense > 0)
            {
                return "Bruiser";
            }

            if (offense > 0 || sustain > 0 || mobility > 0 || defense > 0 || caster > 0)
            {
                return "Hybrid";
            }

            return null;
        }

        private string CanonicalizeStatCode(string statCode)
        {
            if (string.IsNullOrWhiteSpace(statCode))
            {
                return string.Empty;
            }

            return statCode.Trim().ToLowerInvariant() switch
            {
                "str" => "Strength",
                "agi" => "Agility",
                "int" => "Intelligence",
                "hp" => "Health",
                "vit" => "Vitality",
                "hp_regen" => "Regeneration",
                "hp_regen_pct" => "Regeneration",
                "mp" => "Mana",
                "mana" => "Mana",
                "mp_regen" => "Mana",
                "mp_regen_pct" => "Mana",
                "crit" => "Critical",
                "crit_dmg" => "Critical",
                "critchance" => "Critical",
                "dmg" => "Damage",
                "damage" => "Damage",
                "dmg_pct" => "Damage",
                "melee_dmg" => "MeleeDamage",
                "melee_dmg_pct" => "MeleeDamage",
                "ranged_dmg" => "RangedDamage",
                "ranged_dmg_pct" => "RangedDamage",
                "aspd" => "AttackSpeed",
                "attack_speed" => "AttackSpeed",
                "attack_range" => "Range",
                "lifesteal" => "Lifesteal",
                "armor" => "Armor",
                "def" => "Armor",
                "armor_pct" => "Armor",
                "evasion" => "Evasion",
                "dodge" => "Evasion",
                "magic_dmg_taken" => "MagicResist",
                "melee_dmg_taken" => "PhysicalResist",
                "pierce_dmg_taken" => "PhysicalResist",
                "ms" => "MovementSpeed",
                "ms_pct" => "MovementSpeed",
                "move_speed" => "MovementSpeed",
                "block" => "Block",
                "hit" => "Accuracy",
                "spell_power" => "SpellPower",
                "spell_power_pct" => "SpellPower",
                _ => statCode
            };
        }

        private string GetRarityTone(string rarityName)
        {
            return rarityName?.ToLowerInvariant() switch
            {
                "common" => "practical",
                "uncommon" => "refined",
                "rare" => "coveted",
                "epic" => "storied",
                "legendary" => "mythic",
                "artifact" => "otherworldly",
                _ => "purposeful"
            };
        }

        private string GetLevelTierLabel(int itemLevel)
        {
            return itemLevel switch
            {
                < 10 => "Novice",
                < 25 => "Seasoned",
                < 50 => "Battle-Proven",
                < 75 => "Veteran",
                < 90 => "Champion",
                _ => "Mythic"
            };
        }

        private string CombineSentences(params string[] parts)
        {
            return string.Join(" ", parts.Where(p => !string.IsNullOrWhiteSpace(p)).Select(p => p.Trim()));
        }

        private void AddSection(List<string> sections, string text)
        {
            if (!string.IsNullOrWhiteSpace(text))
            {
                sections.Add(text.Trim());
            }
        }

        private string PickRandom(string[] options)
        {
            if (options == null || options.Length == 0)
            {
                return null;
            }

            return options[random.Next(options.Length)];
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
