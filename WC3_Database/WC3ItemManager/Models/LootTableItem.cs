using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents an item entry within a loot table
    /// </summary>
    public class LootTableItem
    {
        public int Id { get; set; }
        public int LootTableId { get; set; }
        public string ItemCode { get; set; }
        
        // Drop configuration
        public int DropChance { get; set; } = 10000;    // 0-10000 = 0-100.00%
        public int Weight { get; set; } = 100;
        public bool IsGuaranteed { get; set; } = false;
        
        // Quantity
        public int QuantityMin { get; set; } = 1;
        public int QuantityMax { get; set; } = 1;
        
        // Metadata
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        
        // Joined fields (from items table)
        public string ItemName { get; set; }
        public string ItemRarity { get; set; }
        public int? ItemLevel { get; set; }
        
        // Display helpers
        public string DropChanceDisplay => IsGuaranteed ? "Guaranteed" : $"{DropChance / 100.0:F1}%";
        public string QuantityDisplay => QuantityMin == QuantityMax 
            ? QuantityMin.ToString() 
            : $"{QuantityMin}-{QuantityMax}";
    }
}
