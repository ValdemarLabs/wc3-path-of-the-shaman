using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a specific item drop for a boss/unique unit
    /// </summary>
    public class UnitSpecificDrop
    {
        public int Id { get; set; }
        public string UnitCode { get; set; }         // FK to unit_types
        public string ItemCode { get; set; }         // FK to items
        
        // Drop configuration
        public decimal DropChance { get; set; } = 100.00m;  // 0-100%
        public int MinQuantity { get; set; } = 1;
        public int MaxQuantity { get; set; } = 1;
        public bool IsGuaranteed { get; set; }       // Always drops
        public int Weight { get; set; } = 100;       // For weighted random
        
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Navigation/display properties (loaded separately)
        public string UnitName { get; set; }
        public string ItemName { get; set; }
        public string ItemRarity { get; set; }
        
        // Display helpers
        public string DropChanceDisplay => IsGuaranteed 
            ? "Guaranteed" 
            : $"{DropChance:F1}%";
        
        public string QuantityDisplay => MinQuantity == MaxQuantity 
            ? MinQuantity.ToString() 
            : $"{MinQuantity}-{MaxQuantity}";
    }
}
