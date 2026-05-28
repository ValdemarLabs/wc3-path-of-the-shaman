using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace WC3ItemManager.Parsers
{
    /// <summary>
    /// Represents a unit parsed from a .w3u file
    /// </summary>
    public class W3UUnit
    {
        public string BaseId { get; set; }      // Original unit ID (4 chars)
        public string UnitCode { get; set; }    // New/custom unit ID (4 chars)
        public string Name { get; set; }        // Unit name (unam)
        public string EditorSuffix { get; set; } // Editor suffix (unsf)
        public string IconPath { get; set; }    // Icon path (uico)
        public int Level { get; set; }          // Unit level (ulev)
        public bool IsCustom { get; set; }      // True if custom unit, false if modification
        public Dictionary<string, object> Properties { get; set; } = new Dictionary<string, object>();
        
        public string DisplayName => !string.IsNullOrEmpty(Name)
            ? (string.IsNullOrEmpty(EditorSuffix) ? Name : $"{Name} ({EditorSuffix})")
            : UnitCode;
    }

    /// <summary>
    /// Parser for Warcraft 3 .w3u (unit object data) files
    /// Format: https://github.com/stijnherfst/HiveWE/wiki/war3map.w3u-Ede-Units
    /// </summary>
    public class W3UParser
    {
        private long _fileLength;
        
        /// <summary>
        /// Parse a .w3u file and return all units
        /// </summary>
        public List<W3UUnit> Parse(string filePath)
        {
            return Parse(filePath, out _, out _);
        }
        
        /// <summary>
        /// Parse a .w3u file and return all units with counts
        /// </summary>
        public List<W3UUnit> Parse(string filePath, out int expectedOriginal, out int expectedCustom)
        {
            var units = new List<W3UUnit>();
            expectedOriginal = 0;
            expectedCustom = 0;
            
            using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read))
            using (var reader = new BinaryReader(fs, Encoding.UTF8))
            {
                _fileLength = fs.Length;
                
                // Read file version (1, 2, or 3)
                int version = reader.ReadInt32();
                
                // Read original/modified units table
                if (CanRead(reader, 4))
                {
                    expectedOriginal = reader.ReadInt32();
                    for (int i = 0; i < expectedOriginal; i++)
                    {
                        if (!CanRead(reader, 12)) break;
                        var unit = ReadUnit(reader, false);
                        if (unit != null)
                        {
                            units.Add(unit);
                        }
                    }
                }
                
                // Read custom units table  
                if (CanRead(reader, 4))
                {
                    expectedCustom = reader.ReadInt32();
                    for (int i = 0; i < expectedCustom; i++)
                    {
                        if (!CanRead(reader, 12)) break;
                        var unit = ReadUnit(reader, true);
                        if (unit != null)
                        {
                            units.Add(unit);
                        }
                    }
                }
            }
            
            return units;
        }

        /// <summary>
        /// Try to parse a .w3u file, returning success and any error message
        /// </summary>
        public bool TryParse(string filePath, out List<W3UUnit> units, out string error)
        {
            return TryParse(filePath, out units, out _, out _, out error);
        }
        
        /// <summary>
        /// Try to parse a .w3u file with expected counts
        /// </summary>
        public bool TryParse(string filePath, out List<W3UUnit> units, out int expectedOriginal, out int expectedCustom, out string error)
        {
            units = new List<W3UUnit>();
            expectedOriginal = 0;
            expectedCustom = 0;
            error = null;
            
            try
            {
                units = Parse(filePath, out expectedOriginal, out expectedCustom);
                return true;
            }
            catch (Exception ex)
            {
                error = $"Failed to parse .w3u file: {ex.Message}";
                return false;
            }
        }

        private bool CanRead(BinaryReader reader, int bytes)
        {
            return reader.BaseStream.Position + bytes <= _fileLength;
        }

        private W3UUnit ReadUnit(BinaryReader reader, bool isCustom)
        {
            var unit = new W3UUnit { IsCustom = isCustom };
            
            // Read original unit ID (4 bytes, ASCII)
            unit.BaseId = ReadFourCC(reader);
            
            // Read new unit ID (4 bytes, ASCII or 0 for modifications)
            string newId = ReadFourCC(reader);
            
            // For modifications (original table), new ID is null/0 - use base ID as code
            // For custom units, new ID is the custom unit code (e.g., "h001")
            unit.UnitCode = string.IsNullOrEmpty(newId) ? unit.BaseId : newId;
            
            // Read modification set count (usually 1)
            if (!CanRead(reader, 4)) return unit;
            int setCount = reader.ReadInt32();
            
            // Read each modification set
            for (int s = 0; s < setCount; s++)
            {
                if (!CanRead(reader, 8)) break;
                
                // Level/variation for this set (usually 0 for units)
                int level = reader.ReadInt32();
                
                // Number of fields in this set
                int fieldCount = reader.ReadInt32();
                
                // Read each field modification
                for (int f = 0; f < fieldCount; f++)
                {
                    if (!CanRead(reader, 8)) break;
                    ReadFieldModification(reader, unit);
                }
            }
            
            return unit;
        }

        private void ReadFieldModification(BinaryReader reader, W3UUnit unit)
        {
            // Field ID (4 bytes) - e.g., "unam", "ulev", "uico"
            string fieldId = ReadFourCC(reader);
            
            // Data type: 0=int, 1=real, 2=unreal, 3=string
            int dataType = reader.ReadInt32();
            
            // Read value based on type
            object value = null;
            switch (dataType)
            {
                case 0: // Integer
                    if (!CanRead(reader, 4)) return;
                    value = reader.ReadInt32();
                    break;
                case 1: // Real
                case 2: // Unreal
                    if (!CanRead(reader, 4)) return;
                    value = reader.ReadSingle();
                    break;
                case 3: // String (null-terminated)
                    value = ReadNullTerminatedString(reader);
                    break;
                default:
                    // Unknown type, read as int
                    if (!CanRead(reader, 4)) return;
                    value = reader.ReadInt32();
                    break;
            }
            
            // Read end marker (original unit ID, 4 bytes)
            if (CanRead(reader, 4))
            {
                reader.ReadBytes(4);
            }
            
            // Store the modification
            if (!string.IsNullOrEmpty(fieldId))
            {
                unit.Properties[fieldId] = value;
                
                // Map known fields
                switch (fieldId.ToLowerInvariant())
                {
                    case "unam": // Unit name
                        unit.Name = value?.ToString();
                        break;
                    case "unsf": // Editor suffix
                        unit.EditorSuffix = value?.ToString();
                        break;
                    case "uico": // Icon path
                        unit.IconPath = value?.ToString();
                        break;
                    case "ulev": // Unit level
                        if (value is int intVal)
                            unit.Level = intVal;
                        break;
                }
            }
        }

        private string ReadFourCC(BinaryReader reader)
        {
            byte[] bytes = reader.ReadBytes(4);
            
            // Check for null (all zeros = no custom ID)
            if (bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 0 && bytes[3] == 0)
            {
                return null;
            }
            
            // Convert to ASCII string (direct order, no reversal)
            var sb = new StringBuilder(4);
            foreach (byte b in bytes)
            {
                if (b >= 32 && b < 127)
                    sb.Append((char)b);
            }
            
            return sb.Length > 0 ? sb.ToString() : null;
        }

        private string ReadNullTerminatedString(BinaryReader reader)
        {
            var bytes = new List<byte>();
            int maxLen = 8192; // Safety limit
            
            while (maxLen-- > 0 && CanRead(reader, 1))
            {
                byte b = reader.ReadByte();
                if (b == 0) break;
                bytes.Add(b);
            }
            
            return Encoding.UTF8.GetString(bytes.ToArray());
        }
    }
}
