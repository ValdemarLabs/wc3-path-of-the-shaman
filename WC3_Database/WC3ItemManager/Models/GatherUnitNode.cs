using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a unit-based gather node (ore veins, fish pools, treasure chests)
    /// </summary>
    public class GatherUnitNode
    {
        public int Id { get; set; }
        public string UnitCode { get; set; }
        public string NodeName { get; set; }
        public int? CategoryId { get; set; }
        public string CategoryName { get; set; }
        public int DisplayOrder { get; set; }
        
        // Spawning configuration
        public int SpawnWeight { get; set; } = 100;
        public double RespawnTimeMin { get; set; } = 120.0;
        public double RespawnTimeMax { get; set; } = 360.0;
        public int MaxPerZone { get; set; } = 3;
        public int SkillRequired { get; set; } = 0;
        public int ProfessionId { get; set; } = GatherProfessionInfo.Mining;
        public int HarvestYieldMin { get; set; } = 3;
        public int HarvestYieldMax { get; set; } = 6;
        public int GatherSuccessChancePercent { get; set; } = 100;
        public int MainDropGroupChancePercent { get; set; } = 100;
        public int SecondaryDropGroupChancePercent { get; set; } = 25;
        public int SpecialBehaviorId { get; set; } = GatherUnitSpecialBehaviorInfo.None;
        public int SpecialBehaviorChancePercent { get; set; } = 20;
        public int OwnerPlayer { get; set; } = 24; // Neutral Passive
        public bool PreventWaterSpawn { get; set; } = false;
        
        // Visual effects
        public bool GlowEffect { get; set; } = true;
        public int GlowColorR { get; set; } = 255;
        public int GlowColorG { get; set; } = 200;
        public int GlowColorB { get; set; } = 0;
        public int GlowAlpha { get; set; } = 200;
        public double GlowScale { get; set; } = 1.5;
        public double GlowHeight { get; set; } = 0.0;
        
        // State
        public bool IsRare { get; set; } = false;
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }

        // Display helpers
        public string RespawnTimeDisplay => RespawnTimeMin == RespawnTimeMax 
            ? $"{RespawnTimeMin:F0}s" 
            : $"{RespawnTimeMin:F0}-{RespawnTimeMax:F0}s";
        
        public string GlowColorDisplay => GlowEffect 
            ? $"RGB({GlowColorR},{GlowColorG},{GlowColorB})" 
            : "None";
        
        public string OwnerPlayerDisplay => OwnerPlayer switch
        {
            0 => "Player 1 (Red)",
            24 => "Neutral Passive",
            25 => "Neutral Hostile",
            27 => "Neutral Victim",
            _ => $"Player {OwnerPlayer + 1}"
        };

        public string ProfessionName => GatherProfessionInfo.GetName(ProfessionId);
        public string SpecialBehaviorName => GatherUnitSpecialBehaviorInfo.GetName(SpecialBehaviorId);
    }
}
