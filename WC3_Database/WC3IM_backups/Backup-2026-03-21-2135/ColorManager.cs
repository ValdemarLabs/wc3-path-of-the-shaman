using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.Linq;
using Npgsql;

namespace WC3ItemManager
{
    /// <summary>
    /// Manages color schemes from database for UI elements
    /// </summary>
    public class ColorManager
    {
        private string connectionString;
        private Dictionary<string, Dictionary<string, string>> colorCache;

        public ColorManager(string connectionString)
        {
            this.connectionString = connectionString;
            this.colorCache = new Dictionary<string, Dictionary<string, string>>();
            LoadColors();
        }

        public void LoadColors()
        {
            colorCache.Clear();
            
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "SELECT element_type, element_name, color_hex FROM ui_color_scheme WHERE is_active = true";
                    
                    using (var cmd = new NpgsqlCommand(query, conn))
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            string type = reader["element_type"].ToString();
                            string name = reader["element_name"].ToString();
                            string hex = reader["color_hex"].ToString();
                            
                            if (!colorCache.ContainsKey(type))
                                colorCache[type] = new Dictionary<string, string>();
                            
                            colorCache[type][name] = hex;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading colors: {ex.Message}");
            }
        }

        public string GetColorHex(string elementType, string elementName, string defaultHex = "#FFFFFF")
        {
            if (colorCache.ContainsKey(elementType) && colorCache[elementType].ContainsKey(elementName))
                return colorCache[elementType][elementName];
            return defaultHex;
        }

        public Color GetColor(string elementType, string elementName, Color? defaultColor = null)
        {
            string hex = GetColorHex(elementType, elementName);
            return ColorFromHex(hex, defaultColor ?? Color.White);
        }

        public string GetWC3ColorCode(string elementType, string elementName)
        {
            string hex = GetColorHex(elementType, elementName);
            // Convert #RRGGBB to WC3 format |cFFRRGGBB
            if (hex.StartsWith("#") && hex.Length == 7)
            {
                return "|cFF" + hex.Substring(1);
            }
            return "|cFFFFFFFF";
        }

        // Overload to convert hex directly to WC3 color code
        public string GetWC3ColorCode(string colorHex)
        {
            // Convert #RRGGBB to WC3 format |cFFRRGGBB or |c00RRGGBB
            if (!string.IsNullOrEmpty(colorHex) && colorHex.StartsWith("#") && colorHex.Length == 7)
            {
                return "|c00" + colorHex.Substring(1);
            }
            return "|c00FFFFFF";
        }

        public string WrapWithColor(string text, string elementType, string elementName)
        {
            string colorCode = GetWC3ColorCode(elementType, elementName);
            return $"{colorCode}{text}|r";
        }

        public void UpdateColor(string elementType, string elementName, string colorHex)
        {
            try
            {
                using (var conn = new NpgsqlConnection(connectionString))
                {
                    conn.Open();
                    string query = @"
                        INSERT INTO ui_color_scheme (element_type, element_name, color_hex)
                        VALUES (@type, @name, @hex)
                        ON CONFLICT (element_type, element_name) 
                        DO UPDATE SET color_hex = @hex, updated_at = CURRENT_TIMESTAMP";
                    
                    using (var cmd = new NpgsqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("type", elementType);
                        cmd.Parameters.AddWithValue("name", elementName);
                        cmd.Parameters.AddWithValue("hex", colorHex);
                        cmd.ExecuteNonQuery();
                    }
                }
                LoadColors(); // Reload cache
            }
            catch (Exception ex)
            {
                throw new Exception($"Error updating color: {ex.Message}");
            }
        }

        public Dictionary<string, string> GetColorsByType(string elementType)
        {
            if (colorCache.ContainsKey(elementType))
                return new Dictionary<string, string>(colorCache[elementType]);
            return new Dictionary<string, string>();
        }

        public static Color ColorFromHex(string hex, Color defaultColor)
        {
            try
            {
                if (string.IsNullOrEmpty(hex))
                    return defaultColor;
                
                hex = hex.TrimStart('#');
                if (hex.Length == 6)
                {
                    int r = Convert.ToInt32(hex.Substring(0, 2), 16);
                    int g = Convert.ToInt32(hex.Substring(2, 2), 16);
                    int b = Convert.ToInt32(hex.Substring(4, 2), 16);
                    return Color.FromArgb(r, g, b);
                }
            }
            catch { }
            
            return defaultColor;
        }

        public static string ColorToHex(Color color)
        {
            return $"#{color.R:X2}{color.G:X2}{color.B:X2}";
        }
    }

    /// <summary>
    /// Represents an item stat/attribute
    /// </summary>
    public class ItemStat
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string DisplayFormat { get; set; }
        public string ColorHex { get; set; }
        public int DisplayOrder { get; set; }

        public string FormatValue(decimal value)
        {
            return DisplayFormat.Replace("{value}", value.ToString("0.##"));
        }

        public override string ToString()
        {
            return Name;
        }
    }

    /// <summary>
    /// Represents a stat value assigned to an item
    /// </summary>
    public class ItemStatValue
    {
        public int ItemId { get; set; }
        public int StatId { get; set; }
        public decimal Value { get; set; }
        public ItemStat Stat { get; set; }

        public string GetFormattedText()
        {
            return Stat?.FormatValue(Value) ?? Value.ToString();
        }
    }
}
