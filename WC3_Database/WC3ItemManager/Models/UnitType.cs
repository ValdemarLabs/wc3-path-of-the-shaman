using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a WC3 unit type for loot configuration
    /// </summary>
    public class UnitType
    {
        public int Id { get; set; }
        
        // WC3-imported fields
        public string UnitCode { get; set; }          // 4-char WC3 ID
        public string BaseId { get; set; }            // Base unit ID (custom units)
        public string UnitName { get; set; }          // Display name
        public string EditorSuffix { get; set; }      // Editor suffix
        public string IconPath { get; set; }          // Art icon path
        
        // Loot configuration
        public int UnitLevel { get; set; } = 1;
        public bool IsBoss { get; set; }
        public LootMode LootMode { get; set; } = LootMode.Generic;
        public int? LootTierId { get; set; }          // Legacy tier system (deprecated)
        public int? LootTableId { get; set; }         // New: Pre-defined loot table
        public int DropCountMin { get; set; } = 1;
        public int DropCountMax { get; set; } = 1;
        
        // Metadata
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Display helper
        public string DisplayName => string.IsNullOrEmpty(EditorSuffix) 
            ? UnitName 
            : $"{UnitName} {EditorSuffix}";
    }

    /// <summary>
    /// Loot mode options for unit types
    /// </summary>
    public enum LootMode
    {
        Generic,    // Uses level-based item pool only
        Specific,   // Uses explicit unit-item mappings only
        Both,       // Generic pool + specific additions
        None        // No item drops
    }
    
    /// <summary>
    /// Helper to convert LootMode enum to/from database string
    /// </summary>
    public static class LootModeExtensions
    {
        public static string ToDbString(this LootMode mode)
        {
            return mode switch
            {
                LootMode.Generic => "generic",
                LootMode.Specific => "specific",
                LootMode.Both => "both",
                LootMode.None => "none",
                _ => "generic"
            };
        }
        
        public static LootMode FromDbString(string value)
        {
            return value?.ToLower() switch
            {
                "generic" => LootMode.Generic,
                "specific" => LootMode.Specific,
                "both" => LootMode.Both,
                "none" => LootMode.None,
                _ => LootMode.Generic
            };
        }
    }
}
