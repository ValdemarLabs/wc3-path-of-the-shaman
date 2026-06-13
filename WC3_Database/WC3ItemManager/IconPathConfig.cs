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

            string normalizedIconPath = NormalizeIconPath(iconPath);
            if (string.IsNullOrEmpty(normalizedIconPath))
                return null;

            // If absolute path and exists, return it
            if (Path.IsPathRooted(normalizedIconPath) && File.Exists(normalizedIconPath))
                return normalizedIconPath;

            string wc3Match = ResolveIconPathUnderRoot(WarCraft3IconPath, normalizedIconPath);
            if (!string.IsNullOrEmpty(wc3Match))
                return wc3Match;

            string customMatch = ResolveIconPathUnderRoot(CustomIconPath, normalizedIconPath);
            if (!string.IsNullOrEmpty(customMatch))
                return customMatch;

            return null;
        }

        private static string NormalizeIconPath(string iconPath)
        {
            if (string.IsNullOrWhiteSpace(iconPath))
                return null;

            string normalized = iconPath
                .Trim()
                .Trim('"')
                .Replace('\0', ' ')
                .Replace('/', '\\');

            while (normalized.Contains(@"\\"))
            {
                normalized = normalized.Replace(@"\\", @"\");
            }

            return normalized.Trim();
        }

        private static string ResolveIconPathUnderRoot(string rootPath, string normalizedIconPath)
        {
            if (string.IsNullOrWhiteSpace(rootPath) || string.IsNullOrWhiteSpace(normalizedIconPath))
                return null;

            string directPath = Path.Combine(rootPath, normalizedIconPath);
            if (File.Exists(directPath))
                return directPath;

            string extension = Path.GetExtension(normalizedIconPath).ToLowerInvariant();

            // ItemManager caches game textures primarily as PNGs, so normalize native WC3
            // texture references to the PNG cache whenever possible.
            if (extension == ".blp" || extension == ".tga" || extension == ".dds")
            {
                string pngPath = Path.ChangeExtension(directPath, ".png");
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
