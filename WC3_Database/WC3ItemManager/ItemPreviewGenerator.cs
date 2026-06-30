using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text.RegularExpressions;
using System.Windows.Forms;

namespace WC3ItemManager
{
    /// <summary>
    /// Generates consistent item previews for both MainForm and ItemEditForm
    /// </summary>
    public static class ItemPreviewGenerator
    {
        /// <summary>
        /// Renders an item preview in WC3 style with proper formatting and colors
        /// </summary>
        public static void RenderPreview(
            RichTextBox rtb,
            string itemName,
            string rarity,
            string itemClass,
            string itemType,
            string extendedTooltip,
            List<ItemStatValue> stats,
            int goldCost,
            Dictionary<string, Color> rarityColors = null)
        {
            try
            {
                rtb.Clear();
                
                // Item Name (colored by rarity)
                Color rarityColor = GetRarityColor(rarity, rarityColors);
                AppendColoredText(rtb, itemName + "\n", rarityColor, true, 10f);
                
                // [Class, Rarity] header - displays class and rarity
                if (!string.IsNullOrEmpty(itemClass) || !string.IsNullOrEmpty(rarity))
                {
                    Color classColor = GetClassColor(itemClass);
                    Color headerColor = Color.FromArgb(150, 150, 150);

                    rtb.AppendText("[");
                    
                    AppendColoredText(rtb, itemClass, classColor, false, 8.5f);
                    
                    if (!string.IsNullOrEmpty(rarity))
                    {
                        AppendColoredText(rtb, ", ", headerColor, false, 8.5f);
                        
                        // Rarity with rarity color
                        AppendColoredText(rtb, rarity, rarityColor, false, 8.5f);
                    }
                    
                    AppendColoredText(rtb, "]\n", headerColor, false, 8.5f);
                }
                
                rtb.AppendText("\n");
                
                // Extended Tooltip/Description (player-visible lore/description)
                if (!string.IsNullOrWhiteSpace(extendedTooltip))
                {
                    // Remove old [Class, Rarity] headers from database
                    string cleanedText = RemoveOldHeaders(extendedTooltip);
                    
                    // Strip WC3-formatted stats from description to prevent duplication
                    // Stats will be rendered separately below from the stats list
                    cleanedText = StripStatsFromDescription(cleanedText);
                    
                    // Remove WC3 color codes for clean display
                    string displayText = RemoveWC3ColorCodes(cleanedText);
                    AppendColoredText(rtb, displayText + "\n", Color.FromArgb(220, 220, 220), false, 9f);
                }
                
                // Stats
                if (stats != null && stats.Count > 0)
                {
                    rtb.AppendText("\n");
                    foreach (var stat in stats.OrderBy(s => s.Stat?.DisplayOrder ?? 999))
                    {
                        if (stat.Stat != null)
                        {
                            // Use stat's color from database
                            Color statColor = ParseStatColor(stat.Stat.ColorHex);
                            
                            // GetFormattedText() already contains +/- from DisplayFormat
                            string statText = $"{stat.GetFormattedText()} {stat.Stat.Name}\n";
                            AppendColoredText(rtb, statText, statColor, false, 9f);
                        }
                    }
                }
                
                // Separator before Buy/Sell info
                rtb.AppendText("\n");
                AppendColoredText(rtb, "─────────────────────────\n", Color.FromArgb(100, 100, 100), false, 8f);
                
                // Buy/Sell information
                AppendColoredText(rtb, $"Buy: {itemName}\n", Color.FromArgb(180, 180, 180), false, 8f);
                AppendColoredText(rtb, $"Sell: {itemName}\n", Color.FromArgb(180, 180, 180), false, 8f);
                AppendColoredText(rtb, $"Gold Cost: {goldCost}\n", Color.FromArgb(255, 215, 0), false, 8f);
            }
            catch (Exception ex)
            {
                rtb.Clear();
                rtb.ForeColor = Color.Red;
                rtb.Text = $"Error rendering preview: {ex.Message}";
            }
        }
        
        /// <summary>
        /// Renders a preview from database row data (for MainForm)
        /// </summary>
        public static void RenderPreviewFromRow(
            RichTextBox rtb,
            PictureBox iconBox,
            string name,
            string rarity,
            string itemClass,
            string itemType,
            string iconPath,
            string tooltipExtended,
            int level,
            int cost,
            List<ItemStatValue> stats,
            Dictionary<string, Color> rarityColors = null)
        {
            // Load icon if provided
            if (iconBox != null)
            {
                // Clear previous image first to prevent ghost icons
                if (iconBox.Image != null)
                {
                    var oldImage = iconBox.Image;
                    iconBox.Image = null;
                    oldImage.Dispose();
                }
                
                if (!string.IsNullOrEmpty(iconPath))
                {
                    try
                    {
                        // Resolve WC3 icon path to file system path
                        string fullPath = IconPathConfig.Instance.ResolveIconPath(iconPath);
                        
                        if (!string.IsNullOrEmpty(fullPath))
                        {
                            // Prefer PNG over BLP if available
                            string actualPath = fullPath;
                            if (System.IO.Path.GetExtension(fullPath).ToLower() == ".blp")
                            {
                                string pngPath = System.IO.Path.ChangeExtension(fullPath, ".png");
                                if (System.IO.File.Exists(pngPath))
                                {
                                    actualPath = pngPath;
                                }
                            }
                            
                            if (System.IO.File.Exists(actualPath))
                            {
                                iconBox.Image = Image.FromFile(actualPath);
                                iconBox.SizeMode = PictureBoxSizeMode.Zoom;
                                iconBox.BackColor = Color.Black;
                            }
                            else
                            {
                                iconBox.Image = CreateErrorIconImage(iconBox, "Error: File not found");
                                iconBox.BackColor = Color.FromArgb(60, 60, 70);
                            }
                        }
                        else
                        {
                            iconBox.Image = CreateErrorIconImage(iconBox, "Error: Path not found");
                            iconBox.BackColor = Color.FromArgb(60, 60, 70);
                        }
                    }
                    catch
                    {
                        iconBox.Image = CreateErrorIconImage(iconBox, "Error: Load failed");
                        iconBox.BackColor = Color.FromArgb(60, 60, 70);
                    }
                }
                else
                {
                    iconBox.Image = CreateErrorIconImage(iconBox, "Error: No icon");
                    iconBox.BackColor = Color.FromArgb(60, 60, 70);
                }
            }
            
            // Render tooltip
            RenderPreview(rtb, name, rarity, itemClass, itemType, tooltipExtended, stats, cost, rarityColors);
        }
        
        /// <summary>
        /// Creates an error icon image with text message.
        /// </summary>
        private static Image CreateErrorIconImage(PictureBox pictureBox, string message)
        {
            int width = pictureBox?.Width ?? 64;
            int height = pictureBox?.Height ?? 64;
            
            var errorImage = new Bitmap(width, height);
            using (var graphics = Graphics.FromImage(errorImage))
            {
                graphics.Clear(Color.FromArgb(45, 45, 55));
                
                // Draw border
                using (var pen = new Pen(Color.FromArgb(100, 100, 110), 2))
                {
                    graphics.DrawRectangle(pen, 2, 2, width - 4, height - 4);
                }
                
                // Draw error icon (X symbol)
                using (var pen = new Pen(Color.FromArgb(180, 80, 80), 3))
                {
                    int margin = width / 4;
                    graphics.DrawLine(pen, margin, margin, width - margin, height - margin);
                    graphics.DrawLine(pen, width - margin, margin, margin, height - margin);
                }
                
                // Draw text message
                using (var font = new Font("Segoe UI", height > 80 ? 9f : 7f, FontStyle.Regular))
                using (var brush = new SolidBrush(Color.FromArgb(180, 180, 190)))
                {
                    var format = new StringFormat
                    {
                        Alignment = StringAlignment.Center,
                        LineAlignment = StringAlignment.Far
                    };
                    
                    var textRect = new RectangleF(0, 0, width, height - 5);
                    graphics.DrawString(message, font, brush, textRect, format);
                }
            }
            return errorImage;
        }
        
        /// <summary>
        /// Appends colored text to RichTextBox
        /// </summary>
        private static void AppendColoredText(RichTextBox rtb, string text, Color color, bool bold, float fontSize)
        {
            int startIndex = rtb.TextLength;
            rtb.AppendText(text);
            int endIndex = rtb.TextLength;
            
            rtb.Select(startIndex, endIndex - startIndex);
            rtb.SelectionColor = color;
            rtb.SelectionFont = bold 
                ? new Font("Consolas", fontSize, FontStyle.Bold) 
                : new Font("Consolas", fontSize);
            rtb.Select(endIndex, 0); // Deselect
        }
        
        /// <summary>
        /// Gets the display color for a rarity
        /// </summary>
        public static Color GetRarityColor(string rarity, Dictionary<string, Color> customColors = null)
        {
            if (string.IsNullOrEmpty(rarity))
                return Color.Gray;
            
            // Check custom colors first (loaded from database)
            if (customColors != null && customColors.TryGetValue(rarity, out Color customColor))
                return customColor;
            
            // Fallback to hardcoded colors
            return rarity switch
            {
                "Common" => Color.LightGray,
                "Uncommon" => Color.FromArgb(30, 255, 0),
                "Rare" => Color.FromArgb(0, 112, 221),
                "Epic" => Color.FromArgb(163, 53, 238),
                "Legendary" => Color.FromArgb(255, 128, 0),
                _ => Color.Gray
            };
        }

        private static Color GetClassColor(string itemClass)
        {
            return ItemClassColorDefaults.GetColor(itemClass);
        }
        
        /// <summary>
        /// Parses a hex color string (#RRGGBB) to Color
        /// </summary>
        private static Color ParseStatColor(string colorHex)
        {
            if (string.IsNullOrEmpty(colorHex))
                return Color.FromArgb(100, 200, 255); // Default stat color
            
            try
            {
                string hex = colorHex.TrimStart('#');
                if (hex.Length == 6)
                {
                    int r = Convert.ToInt32(hex.Substring(0, 2), 16);
                    int g = Convert.ToInt32(hex.Substring(2, 2), 16);
                    int b = Convert.ToInt32(hex.Substring(4, 2), 16);
                    return Color.FromArgb(r, g, b);
                }
            }
            catch { /* Use default color */ }
            
            return Color.FromArgb(100, 200, 255);
        }
        
        /// <summary>
        /// Removes old-style [Class, Rarity] headers and stat lines from extended tooltip text
        /// Handles both WC3 colored format and plain text format
        /// </summary>
        private static string RemoveOldHeaders(string text)
        {
            if (string.IsNullOrEmpty(text))
                return text;
            
            // Remove WC3 colored headers like [|c00FFFFFFBelt|r, |c00AA00FFEpic|r]
            text = Regex.Replace(text, @"\[(\|c[0-9A-Fa-f]{8}[^\|]+\|r,?\s*)+\]", "", RegexOptions.IgnoreCase);
            
            // Remove plain text headers like [Belt, Epic] or [Belt, Material]
            // Match opening bracket, word characters/spaces/commas, closing bracket at start of string or after newline
            text = Regex.Replace(text, @"(?:^|\n)\s*\[[A-Za-z\s,]+\]\s*\n?", "", RegexOptions.Multiline);
            
            // Remove stat lines with WC3 color codes: |cFFFFD700+24 Strength|r
            text = Regex.Replace(text, @"(?:^|\n)\s*\|c[0-9A-Fa-f]{8}[+\-]\d+[^\|]*\|r\s*", "", RegexOptions.Multiline);
            
            // Remove plain text stat lines more comprehensively
            // Matches any line starting with +/- followed by number and optional % (covers all stat formats)
            text = Regex.Replace(text, @"(?:^|\n)\s*[+\-]\d+(?:\.\d+)?%?\s+[A-Za-z][^\n]*", "", RegexOptions.Multiline);
            
            return text.TrimStart('\n', '\r', ' ');
        }
        
        /// <summary>
        /// Removes WC3 color codes and converts |n to newlines
        /// </summary>
        public static string RemoveWC3ColorCodes(string text)
        {
            if (string.IsNullOrEmpty(text))
                return text;
            
            // Replace WC3 newlines with actual newlines
            text = text.Replace("|n", "\n");
            
            // Remove WC3 color codes like |c00RRGGBB and |r
            text = Regex.Replace(text, @"\|c[0-9A-Fa-f]{8}|\|r", "");
            
            return text;
        }
        
        /// <summary>
        /// Converts plain text to WC3 format with color codes
        /// </summary>
        public static string ConvertToWC3Format(string plainText, Dictionary<string, string> colorMappings = null)
        {
            if (string.IsNullOrEmpty(plainText))
                return plainText;
            
            // Convert newlines to |n
            string wc3Text = plainText.Replace("\n", "|n");
            
            // Apply color mappings if provided
            if (colorMappings != null)
            {
                foreach (var mapping in colorMappings)
                {
                    string keyword = mapping.Key;
                    string colorCode = mapping.Value;
                    wc3Text = wc3Text.Replace(keyword, $"{colorCode}{keyword}|r");
                }
            }
            
            return wc3Text;
        }
        
        /// <summary>
        /// Strips WC3-formatted stats from description text to prevent duplication in preview.
        /// Removes lines like "|cffRRGGBB+10 Strength|r" while preserving abilities.
        /// </summary>
        private static string StripStatsFromDescription(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                return text;
            
            // Remove lines that look like WC3-formatted stats: |cffXXXXXX+/-N StatName|r
            // Split by WC3 line breaks and regular newlines
            var lines = text.Split(new[] { "|n", "\n" }, StringSplitOptions.None);
            var filteredLines = new List<string>();
            
            foreach (var line in lines)
            {
                string trimmedLine = line.Trim();
                
                // Skip lines that look like WC3-formatted stats
                // Stats: start with |c, end with |r, contain + or -, and don't contain : (not an ability)
                bool isStatLine = trimmedLine.StartsWith("|c") && 
                                  trimmedLine.EndsWith("|r") &&
                                  (trimmedLine.Contains("+") || trimmedLine.Contains("-")) &&
                                  !trimmedLine.Contains(":");  // Abilities have ":" like "Passive: Bash"
                
                if (!isStatLine)
                {
                    filteredLines.Add(line);
                }
            }
            
            // Join back with |n (WC3 line break)
            return string.Join("|n", filteredLines);
        }
    }
}
