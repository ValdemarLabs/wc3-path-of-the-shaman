using System;
using System.Collections.Generic;
using System.Drawing;

namespace WC3ItemManager
{
    internal static class ItemClassColorDefaults
    {
        private const string FallbackHex = "#A52A2A";

        private static readonly Dictionary<string, string> HexByClass = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["Ability"] = "#00CED1",
            ["Skill"] = "#1E90FF",
            ["Quest"] = "#FFFF00",
            ["Miscellaneous"] = "#D3D3D3",
            ["Other"] = "#D3D3D3",
            ["MISC"] = "#D3D3D3",
            ["Consumable"] = "#90EE90",
            ["CONSUMABLE"] = "#90EE90",
            ["Artifact"] = "#FFB400",
            ["ARTIFACT"] = "#FFB400",
            ["Head Armor"] = "#C0C0C0",
            ["Helm"] = "#C0C0C0",
            ["Chest Armor"] = "#B0C4DE",
            ["Chest"] = "#B0C4DE",
            ["Shoulders"] = "#9FA8DA",
            ["Leg Armor"] = "#A9B7C6",
            ["Legpiece"] = "#A9B7C6",
            ["Foot Armor"] = "#CD853F",
            ["Boots"] = "#CD853F",
            ["Hand Armor"] = "#DEB887",
            ["Gloves"] = "#DEB887",
            ["Bracers"] = "#D2B48C",
            ["Belt"] = "#8B5A2B",
            ["Main Hand Weapon"] = "#A52A2A",
            ["Weapon"] = "#A52A2A",
            ["1h"] = "#A52A2A",
            ["Off Hand Weapon"] = "#8B4513",
            ["Shield"] = "#8B4513",
            ["Two-Hand Weapon"] = "#B22222",
            ["2h"] = "#B22222",
            ["Stave"] = "#6A5ACD",
            ["Ring"] = "#FFD700",
            ["Rings"] = "#FFD700",
            ["Amulet"] = "#40E0D0",
            ["Neck"] = "#40E0D0",
            ["Trinket"] = "#DA70D6",
            ["Back"] = "#708090",
            ["reserved_1"] = "#778899",
            ["reserved_2"] = "#778899",
            ["reserved_3"] = "#778899",
            ["reserved_4"] = "#778899"
        };

        public static string GetHex(string className)
        {
            if (string.IsNullOrWhiteSpace(className))
                return FallbackHex;

            string trimmed = className.Trim();
            return HexByClass.TryGetValue(trimmed, out string hex) ? hex : FallbackHex;
        }

        public static Color GetColor(string className)
        {
            return ColorManager.ColorFromHex(GetHex(className), Color.FromArgb(150, 150, 150));
        }

        public static string GetWC3ColorCode(string className)
        {
            string hex = GetHex(className);
            return hex.StartsWith("#", StringComparison.Ordinal) && hex.Length == 7
                ? "|cFF" + hex.Substring(1)
                : "|cFFA52A2A";
        }
    }
}
