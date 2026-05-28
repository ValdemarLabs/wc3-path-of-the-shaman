using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Reward row for a unit-based gather node harvest.
    /// </summary>
    public class GatherUnitNodeDrop
    {
        public const string MainGroup = "Main";
        public const string SecondaryGroup = "Secondary";

        public int Id { get; set; }
        public int NodeId { get; set; }
        public string GroupName { get; set; } = MainGroup;
        public string ItemCode { get; set; }
        public string ItemName { get; set; }
        public int DropChancePercent { get; set; } = 100;
        public int Weight { get; set; } = 100;
        public int MinQuantity { get; set; } = 1;
        public int MaxQuantity { get; set; } = 1;
        public bool Enabled { get; set; } = true;
        public int DisplayOrder { get; set; }
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        public string QuantityDisplay => MinQuantity == MaxQuantity
            ? MinQuantity.ToString()
            : $"{MinQuantity}-{MaxQuantity}";
    }
}
