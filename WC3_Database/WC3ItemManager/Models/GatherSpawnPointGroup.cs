using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Logical group of spawn point regions for targeted gather-node placement.
    /// </summary>
    public class GatherSpawnPointGroup
    {
        public int Id { get; set; }
        public int ZoneId { get; set; }
        public string ZoneName { get; set; }
        public string GroupName { get; set; }
        public string NodeType { get; set; } = "both";
        public bool Enabled { get; set; } = true;
        public string Notes { get; set; }
        public DateTime CreatedAt { get; set; }

        public string NodeTypeDisplay => NodeType switch
        {
            "item" => "Items Only",
            "unit" => "Units Only",
            "both" => "Both",
            _ => NodeType
        };

        public string DisplayName
        {
            get
            {
                if (string.IsNullOrWhiteSpace(GroupName))
                {
                    if (ZoneId <= 0)
                    {
                        return $"Any / Not configured ({NodeTypeDisplay})";
                    }

                    return $"Zone {ZoneId} ({NodeTypeDisplay})";
                }

                if (string.IsNullOrWhiteSpace(ZoneName))
                {
                    return $"{GroupName} ({NodeTypeDisplay})";
                }

                if (ZoneId <= 0)
                {
                    return $"{GroupName} [Any / Not configured]";
                }

                return $"{GroupName} [{ZoneName}]";
            }
        }

        public override string ToString() => DisplayName;
    }
}
