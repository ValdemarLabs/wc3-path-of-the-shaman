using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace WC3ItemManager.Parsers
{
    /// <summary>
    /// Represents a destructible parsed from a .w3b file
    /// </summary>
    public class W3BDestructible
    {
        public string BaseId { get; set; }              // Original destructible ID (4 chars)
        public string DestructibleCode { get; set; }    // New/custom destructible ID (4 chars)
        public string Name { get; set; }                // Destructible name (bnam)
        public string EditorSuffix { get; set; }        // Editor suffix (bsuf)
        public bool IsCustom { get; set; }              // True if custom destructible
        public Dictionary<string, object> Properties { get; set; } = new Dictionary<string, object>();
        
        public string DisplayName => !string.IsNullOrEmpty(Name)
            ? (string.IsNullOrEmpty(EditorSuffix) ? Name : $"{Name} ({EditorSuffix})")
            : DestructibleCode;
    }

    /// <summary>
    /// Parser for Warcraft 3 .w3b (destructible object data) files
    /// Format is same as .w3u but with different field IDs:
    /// - bnam = destructible name
    /// - bsuf = editor suffix
    /// </summary>
    public class W3BParser
    {
        private long _fileLength;
        
        /// <summary>
        /// Parse a .w3b file and return all destructibles
        /// </summary>
        public List<W3BDestructible> Parse(string filePath)
        {
            return Parse(filePath, out _, out _);
        }
        
        /// <summary>
        /// Parse a .w3b file and return all destructibles with counts
        /// </summary>
        public List<W3BDestructible> Parse(string filePath, out int expectedOriginal, out int expectedCustom)
        {
            var destructibles = new List<W3BDestructible>();
            expectedOriginal = 0;
            expectedCustom = 0;
            
            using (var fs = new FileStream(filePath, FileMode.Open, FileAccess.Read))
            using (var reader = new BinaryReader(fs, Encoding.UTF8))
            {
                _fileLength = fs.Length;
                
                // Read file version (1, 2, or 3)
                int version = reader.ReadInt32();
                
                // Read original/modified destructibles table
                if (CanRead(reader, 4))
                {
                    expectedOriginal = reader.ReadInt32();
                    for (int i = 0; i < expectedOriginal; i++)
                    {
                        if (!CanRead(reader, 12)) break;
                        var dest = ReadDestructible(reader, false);
                        if (dest != null)
                        {
                            destructibles.Add(dest);
                        }
                    }
                }
                
                // Read custom destructibles table  
                if (CanRead(reader, 4))
                {
                    expectedCustom = reader.ReadInt32();
                    for (int i = 0; i < expectedCustom; i++)
                    {
                        if (!CanRead(reader, 12)) break;
                        var dest = ReadDestructible(reader, true);
                        if (dest != null)
                        {
                            destructibles.Add(dest);
                        }
                    }
                }
            }
            
            return destructibles;
        }

        /// <summary>
        /// Try to parse a .w3b file, returning success and any error message
        /// </summary>
        public bool TryParse(string filePath, out List<W3BDestructible> destructibles, out string error)
        {
            return TryParse(filePath, out destructibles, out _, out _, out error);
        }
        
        /// <summary>
        /// Try to parse a .w3b file with expected counts
        /// </summary>
        public bool TryParse(string filePath, out List<W3BDestructible> destructibles, out int expectedOriginal, out int expectedCustom, out string error)
        {
            destructibles = new List<W3BDestructible>();
            expectedOriginal = 0;
            expectedCustom = 0;
            error = null;
            
            try
            {
                destructibles = Parse(filePath, out expectedOriginal, out expectedCustom);
                return true;
            }
            catch (Exception ex)
            {
                error = $"Failed to parse .w3b file: {ex.Message}";
                return false;
            }
        }

        private bool CanRead(BinaryReader reader, int bytes)
        {
            return reader.BaseStream.Position + bytes <= _fileLength;
        }

        private W3BDestructible ReadDestructible(BinaryReader reader, bool isCustom)
        {
            var dest = new W3BDestructible { IsCustom = isCustom };
            
            // Read original destructible ID (4 bytes, ASCII)
            dest.BaseId = ReadFourCC(reader);
            
            // Read new destructible ID (4 bytes, ASCII or 0 for modifications)
            string newId = ReadFourCC(reader);
            
            // For modifications (original table), new ID is null/0 - use base ID as code
            // For custom destructibles, new ID is the custom code (e.g., "B001")
            dest.DestructibleCode = string.IsNullOrEmpty(newId) ? dest.BaseId : newId;
            
            // Read modification set count (usually 1)
            if (!CanRead(reader, 4)) return dest;
            int setCount = reader.ReadInt32();
            
            // Read each modification set
            for (int s = 0; s < setCount; s++)
            {
                if (!CanRead(reader, 8)) break;
                
                // Level/variation for this set (usually 0)
                int level = reader.ReadInt32();
                
                // Number of fields in this set
                int fieldCount = reader.ReadInt32();
                
                // Read each field modification
                for (int f = 0; f < fieldCount; f++)
                {
                    if (!CanRead(reader, 8)) break;
                    ReadFieldModification(reader, dest);
                }
            }
            
            return dest;
        }

        private void ReadFieldModification(BinaryReader reader, W3BDestructible dest)
        {
            // Field ID (4 bytes) - e.g., "bnam", "bsuf"
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
            
            // Read end marker (original destructible ID, 4 bytes)
            if (CanRead(reader, 4))
            {
                reader.ReadBytes(4);
            }
            
            // Store the modification
            if (!string.IsNullOrEmpty(fieldId))
            {
                dest.Properties[fieldId] = value;
                
                // Map known fields for destructibles
                switch (fieldId.ToLowerInvariant())
                {
                    case "bnam": // Destructible name (Text - Name)
                        dest.Name = value?.ToString();
                        break;
                    case "bsuf": // Editor suffix (Text - Editor Suffix)
                        dest.EditorSuffix = value?.ToString();
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
