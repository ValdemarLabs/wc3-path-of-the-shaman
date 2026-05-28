using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a WC3 destructible type for loot configuration
    /// </summary>
    public class DestructibleType
    {
        public int Id { get; set; }
        
        // WC3-imported fields
        public string DestructibleCode { get; set; }    // 4-char WC3 ID (rawcode)
        public string BaseId { get; set; }              // Base destructible ID (for custom)
        public string DestructibleName { get; set; }    // Display name
        public string EditorSuffix { get; set; }        // Editor suffix (variants)
        public string ModelPath { get; set; }           // Art model path
        
        // Loot configuration
        public int DestructibleLevel { get; set; } = 1;
        public LootMode LootMode { get; set; } = LootMode.Generic;
        public int? LootTierId { get; set; }            // Legacy tier system (deprecated)
        public int? LootTableId { get; set; }           // New: Pre-defined loot table
        public int DropCountMin { get; set; } = 0;      // 0 = possible no drop
        public int DropCountMax { get; set; } = 1;
        public decimal? DropChanceOverride { get; set; } // null = use table/tier default
        
        // Category/classification
        public string Category { get; set; }            // 'crate', 'barrel', 'chest', etc.
        public bool IsContainer { get; set; }           // True for crates/chests/barrels
        
        // Metadata
        public string Notes { get; set; }
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Display helpers
        public string DisplayName => string.IsNullOrEmpty(EditorSuffix) 
            ? DestructibleName 
            : $"{DestructibleName} {EditorSuffix}";
            
        public string DropCountDisplay => DropCountMin == DropCountMax 
            ? DropCountMin.ToString() 
            : $"{DropCountMin}-{DropCountMax}";
    }
}
