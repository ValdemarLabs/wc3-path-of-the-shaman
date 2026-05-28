using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a zone assignment for a gather node
    /// </summary>
    public class GatherNodeZone
    {
        public int Id { get; set; }
        public string NodeType { get; set; } // "item" or "unit"
        public int NodeId { get; set; }
        public int ZoneId { get; set; }
        public string ZoneName { get; set; }
        
        // Spawn configuration
        public string SpawnMode { get; set; } = "random"; // "random", "fixed", "both"
        public int? SpawnGroupId { get; set; }
        public string SpawnGroupName { get; set; }
        public int? WeightOverride { get; set; }
        public int? MaxOverride { get; set; }
        public int? SharedMaxOverride { get; set; }
        public int EffectiveWeight { get; set; }
        public int SharedPoolTotalWeight { get; set; }
        public string SharedScopeDisplay { get; set; }
        public string SharedChanceDisplay { get; set; }
        
        // State
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }

        // Node info (joined from parent table)
        public string NodeName { get; set; }
        public string NodeCode { get; set; }

        // Display helper
        public string SpawnModeDisplay => SpawnMode switch
        {
            "random" => "Random In Zone (ZonesCore)",
            "fixed" => "Spawn Group",
            "both" => "Spawn Group + Zone Random Fallback",
            _ => SpawnMode
        };

        public string EffectiveWeightDisplay => EffectiveWeight > 0 ? EffectiveWeight.ToString() : (WeightOverride?.ToString() ?? "-");
    }
}
