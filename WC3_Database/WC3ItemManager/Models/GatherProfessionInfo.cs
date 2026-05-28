using System;
using System.Collections.Generic;
using System.Linq;

namespace WC3ItemManager.Models
{
    public sealed class GatherProfessionOption
    {
        public int Id { get; set; }
        public string Name { get; set; }

        public override string ToString() => Name;
    }

    public static class GatherProfessionInfo
    {
        public const int None = 0;
        public const int Mining = 1;
        public const int Herbalism = 2;
        public const int Skinning = 3;
        public const int Fishing = 4;
        public const int Alchemy = 5;
        public const int Blacksmithing = 6;
        public const int Leatherworking = 7;
        public const int Enchanting = 8;
        public const int Cooking = 9;

        private static readonly IReadOnlyList<GatherProfessionOption> _options = new[]
        {
            new GatherProfessionOption { Id = None, Name = "None" },
            new GatherProfessionOption { Id = Mining, Name = "Mining" },
            new GatherProfessionOption { Id = Herbalism, Name = "Herbalism" },
            new GatherProfessionOption { Id = Skinning, Name = "Skinning" },
            new GatherProfessionOption { Id = Fishing, Name = "Fishing" },
            new GatherProfessionOption { Id = Alchemy, Name = "Alchemy" },
            new GatherProfessionOption { Id = Blacksmithing, Name = "Blacksmithing" },
            new GatherProfessionOption { Id = Leatherworking, Name = "Leatherworking" },
            new GatherProfessionOption { Id = Enchanting, Name = "Enchanting" },
            new GatherProfessionOption { Id = Cooking, Name = "Cooking" }
        };

        public static IReadOnlyList<GatherProfessionOption> Options => _options;

        public static string GetName(int professionId)
        {
            return _options.FirstOrDefault(o => o.Id == professionId)?.Name ?? "None";
        }

        public static int InferDefault(string nodeType, string categoryName)
        {
            string normalizedType = (nodeType ?? string.Empty).Trim().ToLowerInvariant();
            string normalizedCategory = (categoryName ?? string.Empty).Trim().ToLowerInvariant();

            if (normalizedType == "item")
            {
                if (normalizedCategory.Contains("herb") ||
                    normalizedCategory.Contains("flower") ||
                    normalizedCategory.Contains("mushroom") ||
                    normalizedCategory.Contains("reagent"))
                {
                    return Herbalism;
                }

                return None;
            }

            if (normalizedType == "unit")
            {
                if (normalizedCategory.Contains("ore") ||
                    normalizedCategory.Contains("crystal") ||
                    normalizedCategory.Contains("vein"))
                {
                    return Mining;
                }

                if (normalizedCategory.Contains("fish"))
                {
                    return Fishing;
                }

                return None;
            }

            return None;
        }
    }
}
