using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a specific spawn point region for gather nodes
    /// </summary>
    public class GatherSpawnPoint
    {
        public int Id { get; set; }
        public int ZoneId { get; set; }
        public string ZoneName { get; set; }
        public string PointName { get; set; }
        public string RegionVariable { get; set; } // JASS variable name like "gg_rct_Herb_Spawn_01"
        public int? SpawnGroupId { get; set; }
        public string SpawnGroupName { get; set; }

        // Configuration
        public string NodeType { get; set; } = "both"; // "item", "unit", "both"
        public int? SpawnPointIndex { get; set; }
        
        // State
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }

        // Display helper
        public string NodeTypeDisplay => NodeType switch
        {
            "item" => "Items Only",
            "unit" => "Units Only",
            "both" => "Both",
            _ => NodeType
        };
    }
}
