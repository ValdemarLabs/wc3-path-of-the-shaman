using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a loot tier for level-based generic drops
    /// </summary>
    public class LootTier
    {
        public int Id { get; set; }
        public string TierName { get; set; }        // e.g., "TIER_1_5"
        public int MinUnitLevel { get; set; }
        public int MaxUnitLevel { get; set; }
        public string Description { get; set; }
        public decimal DropChanceBase { get; set; } = 10.00m;
        
        // Per-rarity item levels (NULL = rarity unavailable at this tier)
        public int? CommonItemLevel { get; set; }
        public int? UncommonItemLevel { get; set; }
        public int? RareItemLevel { get; set; }
        public int? EpicItemLevel { get; set; }
        public int? LegendaryItemLevel { get; set; }
        public int? ArtifactItemLevel { get; set; }
        
        // Per-rarity weights (0 = disabled)
        public int CommonWeight { get; set; } = 60;
        public int UncommonWeight { get; set; } = 25;
        public int RareWeight { get; set; } = 12;
        public int EpicWeight { get; set; } = 3;
        public int LegendaryWeight { get; set; } = 0;
        public int ArtifactWeight { get; set; } = 0;
        
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }
        
        // Display helpers
        public string LevelRange => $"{MinUnitLevel}-{MaxUnitLevel}";
        
        public string AvailableRarities
        {
            get
            {
                var rarities = new System.Collections.Generic.List<string>();
                if (CommonWeight > 0) rarities.Add("C");
                if (UncommonWeight > 0) rarities.Add("U");
                if (RareWeight > 0) rarities.Add("R");
                if (EpicWeight > 0) rarities.Add("E");
                if (LegendaryWeight > 0) rarities.Add("L");
                if (ArtifactWeight > 0) rarities.Add("A");
                return string.Join("/", rarities);
            }
        }
        
        /// <summary>
        /// Gets the item level for a specific rarity (0-5)
        /// </summary>
        public int? GetItemLevelForRarity(int rarityId)
        {
            return rarityId switch
            {
                0 => CommonItemLevel,
                1 => UncommonItemLevel,
                2 => RareItemLevel,
                3 => EpicItemLevel,
                4 => LegendaryItemLevel,
                5 => ArtifactItemLevel,
                _ => null
            };
        }
        
        /// <summary>
        /// Gets the weight for a specific rarity (0-5)
        /// </summary>
        public int GetWeightForRarity(int rarityId)
        {
            return rarityId switch
            {
                0 => CommonWeight,
                1 => UncommonWeight,
                2 => RareWeight,
                3 => EpicWeight,
                4 => LegendaryWeight,
                5 => ArtifactWeight,
                _ => 0
            };
        }
    }
}
