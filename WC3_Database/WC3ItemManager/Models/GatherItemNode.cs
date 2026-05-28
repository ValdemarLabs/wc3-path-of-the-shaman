using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents an item-based gather node (herbs, flowers, mushrooms)
    /// </summary>
    public class GatherItemNode
    {
        public int Id { get; set; }
        public string ItemCode { get; set; }
        public string NodeName { get; set; }
        public int? CategoryId { get; set; }
        public string CategoryName { get; set; }
        public int DisplayOrder { get; set; }
        
        // Spawning configuration
        public int SpawnWeight { get; set; } = 100;
        public double RespawnTimeMin { get; set; } = 60.0;
        public double RespawnTimeMax { get; set; } = 180.0;
        public int MaxPerZone { get; set; } = 5;
        public int SkillRequired { get; set; } = 0;
        public int ProfessionId { get; set; } = GatherProfessionInfo.Herbalism;
        public bool PreventWaterSpawn { get; set; } = false;
        
        // Visual effects
        public bool GlowEffect { get; set; } = false;
        public int GlowColorR { get; set; } = 0;
        public int GlowColorG { get; set; } = 255;
        public int GlowColorB { get; set; } = 0;
        public int GlowAlpha { get; set; } = 200;
        public double GlowScale { get; set; } = 1.0;
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

        public string ProfessionName => GatherProfessionInfo.GetName(ProfessionId);
    }
}
