using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a game zone from Zones.j
    /// </summary>
    public class GatherZone
    {
        public int Id { get; set; }
        public int ZoneId { get; set; }
        public string ZoneName { get; set; }
        public string EnvironmentType { get; set; }
        public bool IsDungeon { get; set; }
        public string LevelRange { get; set; }
        public int? ParentZoneId { get; set; }
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }

        // Display helper
        public string DisplayName => IsDungeon 
            ? $"[D] {ZoneName}" 
            : (ParentZoneId.HasValue ? $"  └ {ZoneName}" : ZoneName);

        public override string ToString()
        {
            if (ZoneId <= 0)
            {
                return string.IsNullOrWhiteSpace(ZoneName) ? "Any / Not configured" : ZoneName;
            }

            return $"{ZoneId}: {ZoneName}";
        }
    }
}
