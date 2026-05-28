using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace WC3ItemManager
{
    /// <summary>
    /// Loads and provides tooltip phrase data from TooltipPhrases.json
    /// </summary>
    public class TooltipPhrasesLoader
    {
        private static TooltipPhrasesLoader _instance;
        private static readonly object _lock = new object();
        
        private Dictionary<string, string[]> _byRarity = new();
        private Dictionary<string, string[]> _byClass = new();
        private Dictionary<string, string[]> _byDominantStat = new();
        private Dictionary<string, string[]> _closingLines = new();
        private Dictionary<string, string> _statCodeMapping = new();
        
        private readonly Random _random = new();
        private bool _loaded = false;

        public static TooltipPhrasesLoader Instance
        {
            get
            {
                if (_instance == null)
                {
                    lock (_lock)
                    {
                        _instance ??= new TooltipPhrasesLoader();
                    }
                }
                return _instance;
            }
        }

        private TooltipPhrasesLoader() { }

        /// <summary>
        /// Load phrases from the JSON file
        /// </summary>
        public void LoadPhrases(string jsonPath = null)
        {
            if (_loaded) return;

            jsonPath ??= Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Data", "TooltipPhrases.json");

            if (!File.Exists(jsonPath))
            {
                Logger.Instance.Warn($"TooltipPhrases.json not found at {jsonPath}, using empty phrases");
                _loaded = true;
                return;
            }

            try
            {
                string json = File.ReadAllText(jsonPath);
                var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;

                // Check if flavorText exists (v2.0 format)
                JsonElement flavorRoot = root;
                if (root.TryGetProperty("flavorText", out var flavorText))
                {
                    flavorRoot = flavorText;
                }

                // Load byRarity (from flavorText in v2.0 or root in v1.0)
                if (flavorRoot.TryGetProperty("byRarity", out var byRarity))
                {
                    _byRarity = new Dictionary<string, string[]>();
                    foreach (var prop in byRarity.EnumerateObject())
                    {
                        var phrases = new List<string>();
                        foreach (var phrase in prop.Value.EnumerateArray())
                        {
                            phrases.Add(phrase.GetString());
                        }
                        _byRarity[prop.Name] = phrases.ToArray();
                    }
                }

                // Load byClass (from flavorText in v2.0 or root in v1.0)
                if (flavorRoot.TryGetProperty("byClass", out var byClass))
                {
                    _byClass = new Dictionary<string, string[]>();
                    foreach (var prop in byClass.EnumerateObject())
                    {
                        var phrases = new List<string>();
                        foreach (var phrase in prop.Value.EnumerateArray())
                        {
                            phrases.Add(phrase.GetString());
                        }
                        _byClass[prop.Name] = phrases.ToArray();
                    }
                }

                // Load byDominantStat (from flavorText in v2.0 or root in v1.0)
                // v2.0 has arrays, v1.0 had single strings
                if (flavorRoot.TryGetProperty("byDominantStat", out var byDominantStat))
                {
                    _byDominantStat = new Dictionary<string, string[]>();
                    foreach (var prop in byDominantStat.EnumerateObject())
                    {
                        if (prop.Value.ValueKind == JsonValueKind.Array)
                        {
                            // v2.0 format: array of phrases
                            var phrases = new List<string>();
                            foreach (var phrase in prop.Value.EnumerateArray())
                            {
                                phrases.Add(phrase.GetString());
                            }
                            _byDominantStat[prop.Name] = phrases.ToArray();
                        }
                        else
                        {
                            // v1.0 format: single string
                            _byDominantStat[prop.Name] = new[] { prop.Value.GetString() };
                        }
                    }
                }

                // Load closingLines (at root level)
                if (root.TryGetProperty("closingLines", out var closingLines))
                {
                    _closingLines = new Dictionary<string, string[]>();
                    foreach (var prop in closingLines.EnumerateObject())
                    {
                        var phrases = new List<string>();
                        foreach (var phrase in prop.Value.EnumerateArray())
                        {
                            phrases.Add(phrase.GetString());
                        }
                        _closingLines[prop.Name] = phrases.ToArray();
                    }
                }

                // Load statCodeMapping (at root level)
                if (root.TryGetProperty("statCodeMapping", out var statCodeMapping))
                {
                    _statCodeMapping = new Dictionary<string, string>();
                    foreach (var prop in statCodeMapping.EnumerateObject())
                    {
                        _statCodeMapping[prop.Name] = prop.Value.GetString();
                    }
                }

                _loaded = true;
                Logger.Instance.Info($"Loaded tooltip phrases: {_byRarity.Count} rarities, {_byClass.Count} classes, {_byDominantStat.Count} stats");
            }
            catch (Exception ex)
            {
                Logger.Instance.Error("Failed to load TooltipPhrases.json", ex);
            }
        }

        /// <summary>
        /// Get a random flavor phrase for a rarity
        /// </summary>
        public string GetRarityPhrase(string rarity)
        {
            if (_byRarity.TryGetValue(rarity, out var phrases) && phrases.Length > 0)
            {
                return phrases[_random.Next(phrases.Length)];
            }
            return "An item of power awaits its destiny.";
        }

        /// <summary>
        /// Get a random flavor phrase for an item class
        /// </summary>
        public string GetClassPhrase(string className)
        {
            if (_byClass.TryGetValue(className, out var phrases) && phrases.Length > 0)
            {
                return phrases[_random.Next(phrases.Length)];
            }
            return null;
        }

        /// <summary>
        /// Get lore text for a dominant stat
        /// </summary>
        public string GetDominantStatLore(string statCode)
        {
            // Try direct match first
            if (_byDominantStat.TryGetValue(statCode, out var phrases) && phrases.Length > 0)
            {
                return phrases[_random.Next(phrases.Length)];
            }

            // Try mapping to canonical stat code
            if (_statCodeMapping.TryGetValue(statCode, out var mappedCode))
            {
                if (_byDominantStat.TryGetValue(mappedCode, out var mappedPhrases) && mappedPhrases.Length > 0)
                {
                    return mappedPhrases[_random.Next(mappedPhrases.Length)];
                }
            }

            return "An item of considerable power, its true nature remains mysterious.";
        }

        /// <summary>
        /// Get a random closing line for a rarity
        /// </summary>
        public string GetClosingLine(string rarity)
        {
            if (_closingLines.TryGetValue(rarity, out var phrases) && phrases.Length > 0)
            {
                return phrases[_random.Next(phrases.Length)];
            }
            return "An item of mysterious origin.";
        }

        /// <summary>
        /// Force reload phrases (useful after JSON file is updated)
        /// </summary>
        public void Reload()
        {
            _loaded = false;
            LoadPhrases();
        }

        /// <summary>
        /// Check if phrases are loaded
        /// </summary>
        public bool IsLoaded => _loaded;

        /// <summary>
        /// Get all available rarities
        /// </summary>
        public IEnumerable<string> AvailableRarities => _byRarity.Keys;

        /// <summary>
        /// Get all available classes
        /// </summary>
        public IEnumerable<string> AvailableClasses => _byClass.Keys;
    }
}
