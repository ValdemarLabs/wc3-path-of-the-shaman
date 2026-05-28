using System;
using System.Collections.Generic;
using System.Linq;

namespace WC3ItemManager
{
    /// <summary>
    /// Maps item stat types to WC3 ability codes for implementing stat bonuses.
    /// Abilities are invisible to players but provide the mechanical bonuses.
    /// </summary>
    public static class StatAbilityMapper
    {
        // Mapping of stat types to available abilities with their values
        private static readonly Dictionary<string, List<AbilityValue>> StatMap = new Dictionary<string, List<AbilityValue>>
        {
            ["Hit"] = new List<AbilityValue>
            {
                new AbilityValue("A04T", 100),
                new AbilityValue("A04S", 90),
                new AbilityValue("A04R", 75),
                new AbilityValue("A04Q", 60),
                new AbilityValue("A04P", 50),
                new AbilityValue("A04O", 40),
                new AbilityValue("A04N", 35),
                new AbilityValue("A04M", 30),
                new AbilityValue("A04L", 25),
                new AbilityValue("A04K", 20),
                new AbilityValue("A04J", 15),
                new AbilityValue("A04I", 10),
                new AbilityValue("A04H", 5),
                new AbilityValue("A64B", 5),
                new AbilityValue("A64D", 4),
                new AbilityValue("A64C", 3),
                new AbilityValue("A64A", 2),
                new AbilityValue("A649", 1),
            },
            
            ["Crit"] = new List<AbilityValue>
            {
                new AbilityValue("A01R", 100),
                new AbilityValue("A01Q", 90),
                new AbilityValue("A01P", 75),
                new AbilityValue("A01O", 60),
                new AbilityValue("A01N", 50),
                new AbilityValue("A01M", 40),
                new AbilityValue("A01L", 35),
                new AbilityValue("A01K", 30),
                new AbilityValue("A01J", 25),
                new AbilityValue("A01I", 20),
                new AbilityValue("A01H", 15),
                new AbilityValue("A01F", 10),
                new AbilityValue("A01G", 5),
                new AbilityValue("A64I", 5),
                new AbilityValue("A64H", 4),
                new AbilityValue("A64G", 3),
                new AbilityValue("A64F", 2),
                new AbilityValue("A64E", 1),
            },
            
            ["Block"] = new List<AbilityValue>
            {
                new AbilityValue("A64T", 100),
                new AbilityValue("A00Z", 90),
                new AbilityValue("A00Y", 75),
                new AbilityValue("A00X", 60),
                new AbilityValue("A00W", 50),
                new AbilityValue("A00V", 40),
                new AbilityValue("A6F7", 35),
                new AbilityValue("A6F0", 30),
                new AbilityValue("A6EZ", 25),
                new AbilityValue("A6EY", 20),
                new AbilityValue("A6EX", 15),
                new AbilityValue("A6EW", 10),
                new AbilityValue("A64N", 5),
                new AbilityValue("A64M", 4),
                new AbilityValue("A64L", 3),
                new AbilityValue("A64K", 2),
                new AbilityValue("A64J", 1),
            },
            
            ["Dodge"] = new List<AbilityValue>
            {
                new AbilityValue("A017", 100),
                new AbilityValue("A016", 90),
                new AbilityValue("A015", 75),
                new AbilityValue("A014", 60),
                new AbilityValue("A013", 50),
                new AbilityValue("A012", 40),
                new AbilityValue("A011", 35),
                new AbilityValue("A6EU", 30),
                new AbilityValue("A6ET", 25),
                new AbilityValue("A6ES", 20),
                new AbilityValue("A6ER", 15),
                new AbilityValue("A6EQ", 10),
                new AbilityValue("A6EP", 5),
                new AbilityValue("A64S", 5),
                new AbilityValue("A64R", 4),
                new AbilityValue("A64Q", 3),
                new AbilityValue("A64P", 2),
                new AbilityValue("A64O", 1),
            },
            
            ["Spell"] = new List<AbilityValue>
            {
                new AbilityValue("A01E", 100),
                new AbilityValue("A01D", 90),
                new AbilityValue("A01C", 75),
                new AbilityValue("A01B", 60),
                new AbilityValue("A01A", 50),
                new AbilityValue("A019", 40),
                new AbilityValue("A018", 35),
                new AbilityValue("A6F6", 30),
                new AbilityValue("A6F5", 25),
                new AbilityValue("A6F4", 20),
                new AbilityValue("A6F3", 15),
                new AbilityValue("A6F2", 10),
                new AbilityValue("A6F1", 5),
                new AbilityValue("A06P", 4),
                new AbilityValue("A06O", 3),
                new AbilityValue("A06N", 2),
                new AbilityValue("A06M", 1),
            },
            
            ["Strength"] = new List<AbilityValue>
            {
                new AbilityValue("A6D4", 15),
                new AbilityValue("A6D7", 10),
                new AbilityValue("A073", 9),
                new AbilityValue("A64V", 8),
                new AbilityValue("A072", 7),
                new AbilityValue("A071", 6),
                new AbilityValue("A070", 5),
                new AbilityValue("A06Z", 4),
                new AbilityValue("A06Y", 3),
                new AbilityValue("A669", 2),
                new AbilityValue("A06X", 1),
            },
            
            ["Agility"] = new List<AbilityValue>
            {
                new AbilityValue("A06W", 9),
                new AbilityValue("A64W", 8),
                new AbilityValue("A06V", 7),
                new AbilityValue("A06U", 6),
                new AbilityValue("A06T", 5),
                new AbilityValue("A06S", 4),
                new AbilityValue("A06R", 3),
                new AbilityValue("A648", 2),
                new AbilityValue("A06Q", 1),
            },
            
            ["Intelligence"] = new List<AbilityValue>
            {
                new AbilityValue("A6D5", 20),
                new AbilityValue("A6D9", 15),
                new AbilityValue("A07A", 9),
                new AbilityValue("A647", 8),
                new AbilityValue("A079", 7),
                new AbilityValue("A078", 6),
                new AbilityValue("A077", 5),
                new AbilityValue("A076", 4),
                new AbilityValue("A075", 3),
                new AbilityValue("A64X", 2),
                new AbilityValue("A074", 1),
            },
            
            ["Mana"] = new List<AbilityValue>
            {
                new AbilityValue("A07H", 1000),
                new AbilityValue("A646", 500),
                new AbilityValue("A645", 250),
                new AbilityValue("A07G", 200),
                new AbilityValue("A64U", 150),
                new AbilityValue("A07F", 100),
                new AbilityValue("A644", 50),
                new AbilityValue("A07E", 25),
                new AbilityValue("A07D", 10),
                new AbilityValue("A07C", 5),
                new AbilityValue("A07B", 1),
            },
            
            ["Health"] = new List<AbilityValue>
            {
                new AbilityValue("A642", 1000),
                new AbilityValue("A641", 500),
                new AbilityValue("A6D8", 250),
                new AbilityValue("A63Z", 200),
                new AbilityValue("A63Y", 150),
                new AbilityValue("A63E", 100),
                new AbilityValue("A643", 50),
                new AbilityValue("A66A", 25),
                new AbilityValue("A07I", 10),
                new AbilityValue("A07J", 5),
                new AbilityValue("A07K", 1),
            },
            
            ["HP"] = new List<AbilityValue>
            {
                new AbilityValue("A642", 1000),
                new AbilityValue("A641", 500),
                new AbilityValue("A6D8", 250),
                new AbilityValue("A63Z", 200),
                new AbilityValue("A63Y", 150),
                new AbilityValue("A63E", 100),
                new AbilityValue("A643", 50),
                new AbilityValue("A66A", 25),
                new AbilityValue("A07I", 10),
                new AbilityValue("A07J", 5),
                new AbilityValue("A07K", 1),
            },
            
            ["Damage"] = new List<AbilityValue>
            {
                new AbilityValue("A07Y", 500),
                new AbilityValue("A07X", 200),
                new AbilityValue("A07W", 100),
                new AbilityValue("A07V", 50),
                new AbilityValue("A07U", 40),
                new AbilityValue("A07T", 30),
                new AbilityValue("A07S", 20),
                new AbilityValue("A07R", 15),
                new AbilityValue("A07Q", 10),
                new AbilityValue("A07P", 5),
                new AbilityValue("A07O", 4),
                new AbilityValue("A07N", 3),
                new AbilityValue("A07M", 2),
                new AbilityValue("A07L", 1),
            },
            
            ["Armor"] = new List<AbilityValue>
            {
                new AbilityValue("A08A", 100),
                new AbilityValue("A089", 50),
                new AbilityValue("A088", 40),
                new AbilityValue("A087", 30),
                new AbilityValue("A086", 20),
                new AbilityValue("A085", 15),
                new AbilityValue("A084", 10),
                new AbilityValue("A083", 5),
                new AbilityValue("A082", 4),
                new AbilityValue("A081", 3),
                new AbilityValue("A080", 2),
                new AbilityValue("A07Z", 1),
            },
            
            ["Attack Speed"] = new List<AbilityValue>
            {
                new AbilityValue("A08U", 50),
                new AbilityValue("A08T", 40),
                new AbilityValue("A08S", 30),
                new AbilityValue("A08R", 20),
                new AbilityValue("A08Q", 10),
                new AbilityValue("A08P", 5),
                new AbilityValue("A08O", 4),
                new AbilityValue("A08N", 3),
                new AbilityValue("A08M", 2),
                new AbilityValue("A08L", 1),
            },
            
            ["Movement Speed"] = new List<AbilityValue>
            {
                new AbilityValue("A08K", 50),
                new AbilityValue("A08J", 40),
                new AbilityValue("A08I", 30),
                new AbilityValue("A08H", 20),
                new AbilityValue("A08G", 10),
                new AbilityValue("A08F", 5),
                new AbilityValue("A08E", 4),
                new AbilityValue("A08D", 3),
                new AbilityValue("A08C", 2),
                new AbilityValue("A08B", 1),
            },
            
            // NEW STAT ABILITIES ADDED 2026-03-17
            
            ["HP Regen %"] = new List<AbilityValue>
            {
                new AbilityValue("A09Q", 10),
                new AbilityValue("A09R", 5),
                new AbilityValue("A09S", 3),  // 2.5 rounded
                new AbilityValue("A09T", 1),
                new AbilityValue("A09U", 1),  // 0.5 rounded
                new AbilityValue("A09V", 1),  // 0.1 rounded
            },
            
            ["Mana Regen %"] = new List<AbilityValue>
            {
                new AbilityValue("A09W", 10),
                new AbilityValue("A09X", 5),
                new AbilityValue("A09Y", 3),  // 2.5 rounded
                new AbilityValue("A09Z", 1),
                new AbilityValue("A0A0", 1),  // 0.5 rounded
                new AbilityValue("A0A1", 1),  // 0.1 rounded
            },
            
            ["Melee Damage"] = new List<AbilityValue>
            {
                new AbilityValue("A0AO", 100),
                new AbilityValue("A0AP", 50),
                new AbilityValue("A0AQ", 25),
                new AbilityValue("A0AR", 10),
                new AbilityValue("A0AS", 5),
                new AbilityValue("A0AT", 1),
            },
            
            ["Melee Damage %"] = new List<AbilityValue>
            {
                new AbilityValue("A0AU", 50),
                new AbilityValue("A0AV", 25),
                new AbilityValue("A0AW", 10),
                new AbilityValue("A0AX", 5),
                new AbilityValue("A0AY", 2),
                new AbilityValue("A0AZ", 1),
            },
            
            ["Ranged Damage"] = new List<AbilityValue>
            {
                new AbilityValue("A0A2", 100),
                new AbilityValue("A0A3", 50),
                new AbilityValue("A0A4", 25),
                new AbilityValue("A0A5", 10),
                new AbilityValue("A0A6", 5),
                new AbilityValue("A0A7", 1),
            },
            
            ["Ranged Damage %"] = new List<AbilityValue>
            {
                new AbilityValue("A0A8", 50),
                new AbilityValue("A0A9", 25),
                new AbilityValue("A0AA", 10),
                new AbilityValue("A0AB", 5),
                new AbilityValue("A0AC", 2),
                new AbilityValue("A0AD", 1),
            },
            
            ["Cleave %"] = new List<AbilityValue>
            {
                new AbilityValue("A0AE", 50),
                new AbilityValue("A0AF", 25),
                new AbilityValue("A0AG", 10),
                new AbilityValue("A0AH", 5),
                new AbilityValue("A0AI", 2),
                new AbilityValue("A0AJ", 1),
            },
            
            ["Cleave Area"] = new List<AbilityValue>
            {
                new AbilityValue("A0AK", 300),
                new AbilityValue("A0AL", 200),
                new AbilityValue("A0AM", 100),
                new AbilityValue("A0AN", 50),
            },
            
            ["Lifesteal"] = new List<AbilityValue>
            {
                new AbilityValue("A0B0", 50),
                new AbilityValue("A0B1", 25),
                new AbilityValue("A0B2", 10),
                new AbilityValue("A0B3", 5),
                new AbilityValue("A0B4", 2),
                new AbilityValue("A0B5", 1),
            },
            
            ["Thorns"] = new List<AbilityValue>
            {
                new AbilityValue("A0B6", 100),
                new AbilityValue("A0B7", 50),
                new AbilityValue("A0B8", 25),
                new AbilityValue("A0B9", 10),
                new AbilityValue("A0BA", 5),
            },
            
            ["Thorns %"] = new List<AbilityValue>
            {
                new AbilityValue("A0BZ", 50),
                new AbilityValue("A0C0", 25),
                new AbilityValue("A0C1", 10),
                new AbilityValue("A0C2", 5),
                new AbilityValue("A0C3", 2),
                new AbilityValue("A0C4", 1),
            },
            
            ["Armor %"] = new List<AbilityValue>
            {
                new AbilityValue("A0BH", 50),
                new AbilityValue("A0BI", 25),
                new AbilityValue("A0BJ", 10),
                new AbilityValue("A0BK", 5),
                new AbilityValue("A0BL", 2),
                new AbilityValue("A0BM", 1),
            },
            
            ["Magic Damage Taken"] = new List<AbilityValue>
            {
                new AbilityValue("A0BN", -50),
                new AbilityValue("A0BO", -25),
                new AbilityValue("A0BP", -10),
                new AbilityValue("A0BQ", -5),
                new AbilityValue("A0BR", -2),
                new AbilityValue("A0BS", -1),
                new AbilityValue("A0BT", 50),
                new AbilityValue("A0BU", 25),
                new AbilityValue("A0BV", 10),
                new AbilityValue("A0BW", 5),
                new AbilityValue("A0BX", 2),
                new AbilityValue("A0BY", 1),
            },
            
            ["Melee Damage Taken"] = new List<AbilityValue>
            {
                new AbilityValue("A0BB", -50),
                new AbilityValue("A0BC", -25),
                new AbilityValue("A0BD", -10),
                new AbilityValue("A0BE", -5),
                new AbilityValue("A0BF", -2),
                new AbilityValue("A0BG", -1),
                new AbilityValue("A0C5", 50),
                new AbilityValue("A0C6", 25),
                new AbilityValue("A0C7", 10),
                new AbilityValue("A0C8", 5),
                new AbilityValue("A0C9", 2),
                new AbilityValue("A0CA", 1),
            },
            
            ["Pierce Damage Taken"] = new List<AbilityValue>
            {
                new AbilityValue("A09E", -50),
                new AbilityValue("A09F", -25),
                new AbilityValue("A09G", -10),
                new AbilityValue("A09H", -5),
                new AbilityValue("A09I", -2),
                new AbilityValue("A09J", -1),
                new AbilityValue("A09K", 50),
                new AbilityValue("A09L", 25),
                new AbilityValue("A09M", 10),
                new AbilityValue("A09N", 5),
                new AbilityValue("A09O", 2),
                new AbilityValue("A09P", 1),
            },
            
            ["Movement Speed %"] = new List<AbilityValue>
            {
                // TODO: Create these abilities in World Editor if needed for values >50
                // new AbilityValue("A09E", 100),
                // new AbilityValue("A09F", 90),
                // new AbilityValue("A0A0", 75),
                // new AbilityValue("A0A1", 60),
                new AbilityValue("A092", 50),
                new AbilityValue("A093", 25),
                new AbilityValue("A094", 10),
                new AbilityValue("A095", 5),
                new AbilityValue("A096", 2),
                new AbilityValue("A097", 1),
                // Negative values (for slows)
                new AbilityValue("A098", -50),
                new AbilityValue("A099", -25),
                new AbilityValue("A09A", -10),
                new AbilityValue("A09B", -5),
                new AbilityValue("A09C", -2),
                new AbilityValue("A09D", -1),
            },
            
            // Note: "Spell" already maps to spell_power_pct (A01E-A06M)
            // Spell Power flat bonus requires UnitStats.j implementation
            ["Spell Power Flat"] = new List<AbilityValue>
            {
                new AbilityValue("A091", 300),
                new AbilityValue("A08V", 100),
                new AbilityValue("A08W", 50),
                new AbilityValue("A08X", 25),
                new AbilityValue("A08Y", 10),
                new AbilityValue("A08Z", 5),
                new AbilityValue("A090", 1),
            },
        };

        /// <summary>
        /// Get all available abilities for a stat type (for error messages/debugging).
        /// </summary>
        public static List<AbilityValue> GetAbilitiesForStat(string statType)
        {
            if (StatMap.ContainsKey(statType))
            {
                return StatMap[statType];
            }
            return null;
        }

        /// <summary>
        /// Find optimal ability combination to reach target stat value.
        /// Uses greedy algorithm: selects largest values first to minimize ability count.
        /// </summary>
        /// <param name="statType">Stat type (e.g., "Hit", "Crit", "Strength")</param>
        /// <param name="targetValue">Target value to reach</param>
        /// <returns>List of ability codes, or null if exact match impossible</returns>
        public static List<string> FindAbilityCombination(string statType, int targetValue)
        {
            if (!StatMap.ContainsKey(statType))
            {
                return null; // Unknown stat type
            }

            var abilities = StatMap[statType];
            var selected = new List<string>();
            int remaining = targetValue;

            // Handle both positive and negative values
            if (targetValue >= 0)
            {
                // Greedy approach for positive values: pick largest values first
                foreach (var ability in abilities)
                {
                    // Only use positive abilities for positive targets
                    if (ability.Value <= 0)
                        continue;
                        
                    while (remaining >= ability.Value)
                    {
                        selected.Add(ability.Code);
                        remaining -= ability.Value;
                        
                        if (remaining == 0)
                        {
                            return selected; // Exact match found
                        }
                    }
                }
            }
            else
            {
                // Greedy approach for negative values: pick smallest (most negative) values first
                foreach (var ability in abilities)
                {
                    // Only use negative abilities for negative targets
                    if (ability.Value >= 0)
                        continue;
                        
                    while (remaining <= ability.Value)
                    {
                        selected.Add(ability.Code);
                        remaining -= ability.Value;
                        
                        if (remaining == 0)
                        {
                            return selected; // Exact match found
                        }
                    }
                }
            }

            // Could not reach exact value
            if (remaining != 0)
            {
                return null; // Cannot build this value exactly
            }

            return selected;
        }

        /// <summary>
        /// Parse stat string and generate ability codes.
        /// E.g., "Hit: 25%" → ["A04L"]
        ///       "Strength: 12" → ["A6D7", "A669"] (10 + 2)
        /// </summary>
        /// <param name="statString">Stat string (e.g., "Hit: 25%")</param>
        /// <returns>List of ability codes, or empty list if parsing fails</returns>
        public static List<string> ParseStatAndGetAbilities(string statString)
        {
            if (string.IsNullOrWhiteSpace(statString))
                return new List<string>();

            // Extract stat type and value
            // Formats: "Hit: 25%", "Strength: +10", "Crit: 15%"
            var parts = statString.Split(':');
            if (parts.Length != 2)
                return new List<string>();

            string statType = parts[0].Trim();
            string valueStr = parts[1].Trim()
                .Replace("%", "")
                .Replace("+", "")
                .Trim();

            if (!int.TryParse(valueStr, out int value))
                return new List<string>();

            // Find ability combination
            var abilities = FindAbilityCombination(statType, value);
            return abilities ?? new List<string>();
        }

        /// <summary>
        /// Get all supported stat types
        /// </summary>
        public static List<string> GetSupportedStatTypes()
        {
            return StatMap.Keys.ToList();
        }

        /// <summary>
        /// Check if a stat type is supported
        /// </summary>
        public static bool IsStatTypeSupported(string statType)
        {
            return StatMap.ContainsKey(statType);
        }

        /// <summary>
        /// Represents an ability code with its stat value
        /// </summary>
        public class AbilityValue
        {
            public string Code { get; }
            public int Value { get; }

            public AbilityValue(string code, int value)
            {
                Code = code;
                Value = value;
            }
        }
    }
}
