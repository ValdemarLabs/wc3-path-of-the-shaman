using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace WC3ItemManager
{
    /// <summary>
    /// Manages configuration for icon texture locations
    /// </summary>
    public class IconPathConfig
    {
        public string WarCraft3IconPath { get; set; }
        public string CustomIconPath { get; set; }
        
        private static IconPathConfig instance;
        private static readonly string configFile = "IconPathConfig.ini";
        
        public static IconPathConfig Instance
        {
            get
            {
                if (instance == null)
                {
                    instance = new IconPathConfig();
                    instance.Load();
                }
                return instance;
            }
        }
        
        private IconPathConfig()
        {
            // Prefer app-local asset folders so build/publish outputs are self-contained.
            string baseDir = AppDomain.CurrentDomain.BaseDirectory;
            WarCraft3IconPath = Path.Combine(baseDir, "blizzard");
            CustomIconPath = Path.Combine(baseDir, "custom");
        }
        
        public void Load()
        {
            try
            {
                if (File.Exists(configFile))
                {
                    foreach (var line in File.ReadAllLines(configFile))
                    {
                        var parts = line.Split('=');
                        if (parts.Length == 2)
                        {
                            string key = parts[0].Trim();
                            string value = parts[1].Trim();
                            
                            switch (key)
                            {
                                case "WarCraft3IconPath":
                                    WarCraft3IconPath = value;
                                    break;
                                case "CustomIconPath":
                                    CustomIconPath = value;
                                    break;
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading icon config: {ex.Message}");
            }
        }
        
        public void Save()
        {
            try
            {
                var lines = new List<string>
                {
                    $"WarCraft3IconPath={WarCraft3IconPath}",
                    $"CustomIconPath={CustomIconPath}"
                };
                File.WriteAllLines(configFile, lines);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving icon config: {ex.Message}");
            }
        }
        
        // Static helper methods for easy access
        public static string GetBlizzardIconPath()
        {
            return Instance.WarCraft3IconPath;
        }
        
        public static string GetCustomIconPath()
        {
            return Instance.CustomIconPath;
        }
        
        public static void SaveIconPaths(string blizzardPath, string customPath)
        {
            Instance.WarCraft3IconPath = blizzardPath;
            Instance.CustomIconPath = customPath;
            Instance.Save();
        }
        
        /// <summary>
        /// Get all BLP/TGA/PNG files from configured paths
        /// </summary>
        public List<IconEntry> GetAllIcons()
        {
            var icons = new List<IconEntry>();
            
            // Load Blizzard icons
            if (Directory.Exists(WarCraft3IconPath))
            {
                LoadIconsFromDirectory(icons, WarCraft3IconPath, "Blizzard", true);
            }
            
            // Load custom icons
            if (Directory.Exists(CustomIconPath))
            {
                LoadIconsFromDirectory(icons, CustomIconPath, "Custom", true);
            }
            
            return icons.OrderBy(i => i.Name).ToList();
        }
        
        private void LoadIconsFromDirectory(List<IconEntry> icons, string path, string source, bool recursive)
        {
            try
            {
                // Supported formats: BLP (WC3 native), TGA, PNG, JPG
                string[] extensions = { "*.blp", "*.tga", "*.png", "*.jpg", "*.jpeg" };
                
                foreach (var ext in extensions)
                {
                    var files = Directory.GetFiles(path, ext, 
                        recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly);
                    
                    foreach (var file in files)
                    {
                        string relativePath = file.Replace(path, "").TrimStart('\\', '/');
                        icons.Add(new IconEntry
                        {
                            FullPath = file,
                            RelativePath = relativePath,
                            Name = Path.GetFileNameWithoutExtension(file),
                            Source = source
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error loading icons from {path}: {ex.Message}");
            }
        }
        
        /// <summary>
        /// Resolve icon path - tries both WC3 and custom paths
        /// </summary>
        public string ResolveIconPath(string iconPath)
        {
            if (string.IsNullOrEmpty(iconPath))
                return null;
                
            // If absolute path and exists, return it
            if (Path.IsPathRooted(iconPath) && File.Exists(iconPath))
                return iconPath;
            
            // Try WC3 path - check both .blp and .png
            string wc3Path = Path.Combine(WarCraft3IconPath, iconPath);
            if (File.Exists(wc3Path))
                return wc3Path;
            
            // If looking for .blp, check for .png version in WC3 path
            if (Path.GetExtension(iconPath).ToLower() == ".blp")
            {
                string pngPath = Path.ChangeExtension(wc3Path, ".png");
                if (File.Exists(pngPath))
                    return pngPath;
            }
            
            // Try custom path
            string customPath = Path.Combine(CustomIconPath, iconPath);
            if (File.Exists(customPath))
                return customPath;
                
            // If looking for .blp, check for .png version in custom path
            if (Path.GetExtension(iconPath).ToLower() == ".blp")
            {
                string pngPath = Path.ChangeExtension(customPath, ".png");
                if (File.Exists(pngPath))
                    return pngPath;
            }
            
            return null;
        }
    }
    
    // Shared model for icon metadata
    public class IconEntry
    {
        public string FullPath { get; set; }
        public string RelativePath { get; set; }
        public string Name { get; set; }
        public string Source { get; set; } // "Blizzard" or "Custom"
        
        public override string ToString()
        {
            return $"{Name} ({Source})";
        }
    }
    
    // Folder information for tree view
    public class FolderInfo
    {
        public string FullPath { get; set; }
        public string Source { get; set; }
    }
}
