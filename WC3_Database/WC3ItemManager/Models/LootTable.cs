using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a pre-defined loot table that can be assigned to units or destructibles
    /// </summary>
    public class LootTable
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        
        // Drop configuration
        public int DropChance { get; set; } = 5000;     // 0-10000 = 0-100.00%
        public int DropCountMin { get; set; } = 0;
        public int DropCountMax { get; set; } = 1;
        
        // Level range (for categorization/filtering)
        public int MinLevel { get; set; } = 1;
        public int MaxLevel { get; set; } = 99;
        
        // Categorization
        public string Category { get; set; }            // 'units', 'destructibles', 'both', 'boss', etc.
        
        // State
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
        
        // Display helpers
        public string DropChanceDisplay => $"{DropChance / 100.0:F1}%";
        public string DropCountDisplay => DropCountMin == DropCountMax 
            ? DropCountMin.ToString() 
            : $"{DropCountMin}-{DropCountMax}";
        public string LevelRangeDisplay => $"{MinLevel}-{MaxLevel}";
    }
}
