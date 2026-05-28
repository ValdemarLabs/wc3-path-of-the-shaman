using System;

namespace WC3ItemManager.Models
{
    /// <summary>
    /// Represents a category for organizing gather nodes
    /// </summary>
    public class GatherNodeCategory
    {
        public int Id { get; set; }
        public string CategoryName { get; set; }
        public string NodeType { get; set; } // "item" or "unit"
        public string Description { get; set; }
        public int DisplayOrder { get; set; }
        public bool Enabled { get; set; } = true;
        public DateTime CreatedAt { get; set; }

        // Display helper
        public override string ToString() => CategoryName;
    }
}
