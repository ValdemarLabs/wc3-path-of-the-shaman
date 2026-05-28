using System;
using System.Collections.Generic;
using Npgsql;
using WC3ItemManager.Models;

namespace WC3ItemManager.Repositories
{
    /// <summary>
    /// Database operations for gather node entities
    /// </summary>
    public class GatherNodeRepository
    {
        private readonly string _connectionString;

        public GatherNodeRepository(string connectionString)
        {
            _connectionString = connectionString;
        }

        #region Categories

        public List<GatherNodeCategory> GetAllCategories()
        {
            var categories = new List<GatherNodeCategory>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, category_name, node_type, description, display_order, enabled, created_at
                    FROM gather_node_categories
                    ORDER BY display_order, category_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            categories.Add(new GatherNodeCategory
                            {
                                Id = reader.GetInt32(0),
                                CategoryName = reader.GetString(1),
                                NodeType = reader.GetString(2),
                                Description = reader.IsDBNull(3) ? null : reader.GetString(3),
                                DisplayOrder = reader.GetInt32(4),
                                Enabled = reader.GetBoolean(5),
                                CreatedAt = reader.GetDateTime(6)
                            });
                        }
                    }
                }
            }
            
            return categories;
        }

        public List<GatherNodeCategory> GetCategoriesByType(string nodeType)
        {
            var categories = new List<GatherNodeCategory>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, category_name, node_type, description, display_order, enabled, created_at
                    FROM gather_node_categories
                    WHERE node_type = @nodeType
                    ORDER BY display_order, category_name", conn))
                {
                    cmd.Parameters.AddWithValue("@nodeType", nodeType);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            categories.Add(new GatherNodeCategory
                            {
                                Id = reader.GetInt32(0),
                                CategoryName = reader.GetString(1),
                                NodeType = reader.GetString(2),
                                Description = reader.IsDBNull(3) ? null : reader.GetString(3),
                                DisplayOrder = reader.GetInt32(4),
                                Enabled = reader.GetBoolean(5),
                                CreatedAt = reader.GetDateTime(6)
                            });
                        }
                    }
                }
            }
            
            return categories;
        }

        #endregion

        #region Item Nodes

        public List<GatherItemNode> GetAllItemNodes()
        {
            var nodes = new List<GatherItemNode>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT gin.id, gin.item_code, gin.node_name, gin.category_id,
                           COALESCE(gnc.category_name, 'Uncategorized') as category_name,
                           gin.spawn_weight, gin.respawn_time_min, gin.respawn_time_max,
                           gin.max_per_zone, gin.skill_required,
                           gin.glow_effect, gin.glow_color_r, gin.glow_color_g, gin.glow_color_b, gin.glow_alpha,
                           gin.is_rare, gin.enabled, gin.notes, gin.created_at, gin.updated_at
                    FROM gather_item_nodes gin
                    LEFT JOIN gather_node_categories gnc ON gin.category_id = gnc.id
                    ORDER BY gnc.display_order, gin.node_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            nodes.Add(MapToItemNode(reader));
                        }
                    }
                }
            }
            
            return nodes;
        }

        public GatherItemNode GetItemNodeById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT gin.id, gin.item_code, gin.node_name, gin.category_id,
                           COALESCE(gnc.category_name, 'Uncategorized') as category_name,
                           gin.spawn_weight, gin.respawn_time_min, gin.respawn_time_max,
                           gin.max_per_zone, gin.skill_required,
                           gin.glow_effect, gin.glow_color_r, gin.glow_color_g, gin.glow_color_b, gin.glow_alpha,
                           gin.is_rare, gin.enabled, gin.notes, gin.created_at, gin.updated_at
                    FROM gather_item_nodes gin
                    LEFT JOIN gather_node_categories gnc ON gin.category_id = gnc.id
                    WHERE gin.id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToItemNode(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        public int InsertItemNode(GatherItemNode node)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_item_nodes 
                    (item_code, node_name, category_id, spawn_weight, respawn_time_min, respawn_time_max,
                     max_per_zone, skill_required, glow_effect, glow_color_r, glow_color_g, glow_color_b,
                     glow_alpha, is_rare, enabled, notes)
                    VALUES (@item_code, @node_name, @category_id, @spawn_weight, @respawn_time_min, @respawn_time_max,
                            @max_per_zone, @skill_required, @glow_effect, @glow_color_r, @glow_color_g, @glow_color_b,
                            @glow_alpha, @is_rare, @enabled, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@item_code", node.ItemCode);
                    cmd.Parameters.AddWithValue("@node_name", node.NodeName);
                    cmd.Parameters.AddWithValue("@category_id", node.CategoryId.HasValue ? (object)node.CategoryId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_weight", node.SpawnWeight);
                    cmd.Parameters.AddWithValue("@respawn_time_min", node.RespawnTimeMin);
                    cmd.Parameters.AddWithValue("@respawn_time_max", node.RespawnTimeMax);
                    cmd.Parameters.AddWithValue("@max_per_zone", node.MaxPerZone);
                    cmd.Parameters.AddWithValue("@skill_required", node.SkillRequired);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateItemNode(GatherItemNode node)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_item_nodes SET
                        item_code = @item_code,
                        node_name = @node_name,
                        category_id = @category_id,
                        spawn_weight = @spawn_weight,
                        respawn_time_min = @respawn_time_min,
                        respawn_time_max = @respawn_time_max,
                        max_per_zone = @max_per_zone,
                        skill_required = @skill_required,
                        glow_effect = @glow_effect,
                        glow_color_r = @glow_color_r,
                        glow_color_g = @glow_color_g,
                        glow_color_b = @glow_color_b,
                        glow_alpha = @glow_alpha,
                        is_rare = @is_rare,
                        enabled = @enabled,
                        notes = @notes,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", node.Id);
                    cmd.Parameters.AddWithValue("@item_code", node.ItemCode);
                    cmd.Parameters.AddWithValue("@node_name", node.NodeName);
                    cmd.Parameters.AddWithValue("@category_id", node.CategoryId.HasValue ? (object)node.CategoryId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_weight", node.SpawnWeight);
                    cmd.Parameters.AddWithValue("@respawn_time_min", node.RespawnTimeMin);
                    cmd.Parameters.AddWithValue("@respawn_time_max", node.RespawnTimeMax);
                    cmd.Parameters.AddWithValue("@max_per_zone", node.MaxPerZone);
                    cmd.Parameters.AddWithValue("@skill_required", node.SkillRequired);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteItemNode(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                
                // Delete zone assignments first
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_node_zones WHERE node_type = 'item' AND node_id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
                
                // Delete the node
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_item_nodes WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Set enabled status for multiple item nodes
        /// </summary>
        public void SetItemNodesEnabled(IEnumerable<int> ids, bool enabled)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_item_nodes SET enabled = @enabled, updated_at = CURRENT_TIMESTAMP 
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@enabled", enabled);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        private GatherItemNode MapToItemNode(NpgsqlDataReader reader)
        {
            return new GatherItemNode
            {
                Id = reader.GetInt32(0),
                ItemCode = reader.GetString(1),
                NodeName = reader.GetString(2),
                CategoryId = reader.IsDBNull(3) ? (int?)null : reader.GetInt32(3),
                CategoryName = reader.GetString(4),
                SpawnWeight = reader.GetInt32(5),
                RespawnTimeMin = reader.GetDouble(6),
                RespawnTimeMax = reader.GetDouble(7),
                MaxPerZone = reader.GetInt32(8),
                SkillRequired = reader.GetInt32(9),
                GlowEffect = reader.GetBoolean(10),
                GlowColorR = reader.GetInt32(11),
                GlowColorG = reader.GetInt32(12),
                GlowColorB = reader.GetInt32(13),
                GlowAlpha = reader.GetInt32(14),
                IsRare = reader.GetBoolean(15),
                Enabled = reader.GetBoolean(16),
                Notes = reader.IsDBNull(17) ? null : reader.GetString(17),
                CreatedAt = reader.GetDateTime(18),
                UpdatedAt = reader.GetDateTime(19)
            };
        }

        #endregion

        #region Unit Nodes

        public List<GatherUnitNode> GetAllUnitNodes()
        {
            var nodes = new List<GatherUnitNode>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT gun.id, gun.unit_code, gun.node_name, gun.category_id,
                           COALESCE(gnc.category_name, 'Uncategorized') as category_name,
                           gun.spawn_weight, gun.respawn_time_min, gun.respawn_time_max,
                           gun.max_per_zone, gun.skill_required, gun.owner_player,
                           gun.glow_effect, gun.glow_color_r, gun.glow_color_g, gun.glow_color_b, 
                           gun.glow_alpha, gun.glow_scale,
                           gun.is_rare, gun.enabled, gun.notes, gun.created_at, gun.updated_at
                    FROM gather_unit_nodes gun
                    LEFT JOIN gather_node_categories gnc ON gun.category_id = gnc.id
                    ORDER BY gnc.display_order, gun.node_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            nodes.Add(MapToUnitNode(reader));
                        }
                    }
                }
            }
            
            return nodes;
        }

        public GatherUnitNode GetUnitNodeById(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT gun.id, gun.unit_code, gun.node_name, gun.category_id,
                           COALESCE(gnc.category_name, 'Uncategorized') as category_name,
                           gun.spawn_weight, gun.respawn_time_min, gun.respawn_time_max,
                           gun.max_per_zone, gun.skill_required, gun.owner_player,
                           gun.glow_effect, gun.glow_color_r, gun.glow_color_g, gun.glow_color_b, 
                           gun.glow_alpha, gun.glow_scale,
                           gun.is_rare, gun.enabled, gun.notes, gun.created_at, gun.updated_at
                    FROM gather_unit_nodes gun
                    LEFT JOIN gather_node_categories gnc ON gun.category_id = gnc.id
                    WHERE gun.id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return MapToUnitNode(reader);
                        }
                    }
                }
            }
            
            return null;
        }

        public int InsertUnitNode(GatherUnitNode node)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_unit_nodes 
                    (unit_code, node_name, category_id, spawn_weight, respawn_time_min, respawn_time_max,
                     max_per_zone, skill_required, owner_player, glow_effect, glow_color_r, glow_color_g, 
                     glow_color_b, glow_alpha, glow_scale, is_rare, enabled, notes)
                    VALUES (@unit_code, @node_name, @category_id, @spawn_weight, @respawn_time_min, @respawn_time_max,
                            @max_per_zone, @skill_required, @owner_player, @glow_effect, @glow_color_r, @glow_color_g,
                            @glow_color_b, @glow_alpha, @glow_scale, @is_rare, @enabled, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@unit_code", node.UnitCode);
                    cmd.Parameters.AddWithValue("@node_name", node.NodeName);
                    cmd.Parameters.AddWithValue("@category_id", node.CategoryId.HasValue ? (object)node.CategoryId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_weight", node.SpawnWeight);
                    cmd.Parameters.AddWithValue("@respawn_time_min", node.RespawnTimeMin);
                    cmd.Parameters.AddWithValue("@respawn_time_max", node.RespawnTimeMax);
                    cmd.Parameters.AddWithValue("@max_per_zone", node.MaxPerZone);
                    cmd.Parameters.AddWithValue("@skill_required", node.SkillRequired);
                    cmd.Parameters.AddWithValue("@owner_player", node.OwnerPlayer);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateUnitNode(GatherUnitNode node)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_unit_nodes SET
                        unit_code = @unit_code,
                        node_name = @node_name,
                        category_id = @category_id,
                        spawn_weight = @spawn_weight,
                        respawn_time_min = @respawn_time_min,
                        respawn_time_max = @respawn_time_max,
                        max_per_zone = @max_per_zone,
                        skill_required = @skill_required,
                        owner_player = @owner_player,
                        glow_effect = @glow_effect,
                        glow_color_r = @glow_color_r,
                        glow_color_g = @glow_color_g,
                        glow_color_b = @glow_color_b,
                        glow_alpha = @glow_alpha,
                        glow_scale = @glow_scale,
                        is_rare = @is_rare,
                        enabled = @enabled,
                        notes = @notes,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", node.Id);
                    cmd.Parameters.AddWithValue("@unit_code", node.UnitCode);
                    cmd.Parameters.AddWithValue("@node_name", node.NodeName);
                    cmd.Parameters.AddWithValue("@category_id", node.CategoryId.HasValue ? (object)node.CategoryId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_weight", node.SpawnWeight);
                    cmd.Parameters.AddWithValue("@respawn_time_min", node.RespawnTimeMin);
                    cmd.Parameters.AddWithValue("@respawn_time_max", node.RespawnTimeMax);
                    cmd.Parameters.AddWithValue("@max_per_zone", node.MaxPerZone);
                    cmd.Parameters.AddWithValue("@skill_required", node.SkillRequired);
                    cmd.Parameters.AddWithValue("@owner_player", node.OwnerPlayer);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteUnitNode(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                
                // Delete zone assignments first
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_node_zones WHERE node_type = 'unit' AND node_id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
                
                // Delete the node
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_unit_nodes WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Set enabled status for multiple unit nodes
        /// </summary>
        public void SetUnitNodesEnabled(IEnumerable<int> ids, bool enabled)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_unit_nodes SET enabled = @enabled, updated_at = CURRENT_TIMESTAMP 
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@enabled", enabled);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        private GatherUnitNode MapToUnitNode(NpgsqlDataReader reader)
        {
            return new GatherUnitNode
            {
                Id = reader.GetInt32(0),
                UnitCode = reader.GetString(1),
                NodeName = reader.GetString(2),
                CategoryId = reader.IsDBNull(3) ? (int?)null : reader.GetInt32(3),
                CategoryName = reader.GetString(4),
                SpawnWeight = reader.GetInt32(5),
                RespawnTimeMin = reader.GetDouble(6),
                RespawnTimeMax = reader.GetDouble(7),
                MaxPerZone = reader.GetInt32(8),
                SkillRequired = reader.GetInt32(9),
                OwnerPlayer = reader.GetInt32(10),
                GlowEffect = reader.GetBoolean(11),
                GlowColorR = reader.GetInt32(12),
                GlowColorG = reader.GetInt32(13),
                GlowColorB = reader.GetInt32(14),
                GlowAlpha = reader.GetInt32(15),
                GlowScale = reader.GetDouble(16),
                IsRare = reader.GetBoolean(17),
                Enabled = reader.GetBoolean(18),
                Notes = reader.IsDBNull(19) ? null : reader.GetString(19),
                CreatedAt = reader.GetDateTime(20),
                UpdatedAt = reader.GetDateTime(21)
            };
        }

        #endregion

        #region Zone Assignments

        public List<GatherNodeZone> GetZoneAssignmentsByNode(string nodeType, int nodeId)
        {
            var zones = new List<GatherNodeZone>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, node_type, node_id, zone_id, zone_name, spawn_mode, 
                           weight_override, max_override, enabled, created_at
                    FROM gather_node_zones
                    WHERE node_type = @nodeType AND node_id = @nodeId
                    ORDER BY zone_id", conn))
                {
                    cmd.Parameters.AddWithValue("@nodeType", nodeType);
                    cmd.Parameters.AddWithValue("@nodeId", nodeId);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            zones.Add(MapToNodeZone(reader));
                        }
                    }
                }
            }
            
            return zones;
        }

        public List<GatherNodeZone> GetZoneAssignmentsByZone(int zoneId)
        {
            var zones = new List<GatherNodeZone>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT gnz.id, gnz.node_type, gnz.node_id, gnz.zone_id, gnz.zone_name, 
                           gnz.spawn_mode, gnz.weight_override, gnz.max_override, gnz.enabled, gnz.created_at,
                           CASE WHEN gnz.node_type = 'item' THEN gin.node_name ELSE gun.node_name END as node_name,
                           CASE WHEN gnz.node_type = 'item' THEN gin.item_code ELSE gun.unit_code END as node_code
                    FROM gather_node_zones gnz
                    LEFT JOIN gather_item_nodes gin ON gnz.node_type = 'item' AND gnz.node_id = gin.id
                    LEFT JOIN gather_unit_nodes gun ON gnz.node_type = 'unit' AND gnz.node_id = gun.id
                    WHERE gnz.zone_id = @zoneId
                    ORDER BY gnz.node_type, node_name", conn))
                {
                    cmd.Parameters.AddWithValue("@zoneId", zoneId);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var zone = MapToNodeZone(reader);
                            zone.NodeName = reader.IsDBNull(10) ? null : reader.GetString(10);
                            zone.NodeCode = reader.IsDBNull(11) ? null : reader.GetString(11);
                            zones.Add(zone);
                        }
                    }
                }
            }
            
            return zones;
        }

        public int InsertZoneAssignment(GatherNodeZone zone)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_node_zones 
                    (node_type, node_id, zone_id, zone_name, spawn_mode, weight_override, max_override, enabled)
                    VALUES (@node_type, @node_id, @zone_id, @zone_name, @spawn_mode, @weight_override, @max_override, @enabled)
                    ON CONFLICT (node_type, node_id, zone_id) DO UPDATE SET
                        zone_name = EXCLUDED.zone_name,
                        spawn_mode = EXCLUDED.spawn_mode,
                        weight_override = EXCLUDED.weight_override,
                        max_override = EXCLUDED.max_override,
                        enabled = EXCLUDED.enabled
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@node_type", zone.NodeType);
                    cmd.Parameters.AddWithValue("@node_id", zone.NodeId);
                    cmd.Parameters.AddWithValue("@zone_id", zone.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", zone.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_mode", zone.SpawnMode);
                    cmd.Parameters.AddWithValue("@weight_override", zone.WeightOverride.HasValue ? (object)zone.WeightOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@max_override", zone.MaxOverride.HasValue ? (object)zone.MaxOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", zone.Enabled);
                    
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void DeleteZoneAssignment(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_node_zones WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private GatherNodeZone MapToNodeZone(NpgsqlDataReader reader)
        {
            return new GatherNodeZone
            {
                Id = reader.GetInt32(0),
                NodeType = reader.GetString(1),
                NodeId = reader.GetInt32(2),
                ZoneId = reader.GetInt32(3),
                ZoneName = reader.IsDBNull(4) ? null : reader.GetString(4),
                SpawnMode = reader.GetString(5),
                WeightOverride = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                MaxOverride = reader.IsDBNull(7) ? (int?)null : reader.GetInt32(7),
                Enabled = reader.GetBoolean(8),
                CreatedAt = reader.GetDateTime(9)
            };
        }

        #endregion

        #region Spawn Points

        public List<GatherSpawnPoint> GetAllSpawnPoints()
        {
            var points = new List<GatherSpawnPoint>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, zone_id, zone_name, point_name, region_variable, node_type, 
                           spawn_point_index, enabled, notes, created_at
                    FROM gather_spawn_points
                    ORDER BY zone_id, point_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            points.Add(MapToSpawnPoint(reader));
                        }
                    }
                }
            }
            
            return points;
        }

        public List<GatherSpawnPoint> GetSpawnPointsByZone(int zoneId)
        {
            var points = new List<GatherSpawnPoint>();
            
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, zone_id, zone_name, point_name, region_variable, node_type, 
                           spawn_point_index, enabled, notes, created_at
                    FROM gather_spawn_points
                    WHERE zone_id = @zoneId
                    ORDER BY point_name", conn))
                {
                    cmd.Parameters.AddWithValue("@zoneId", zoneId);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            points.Add(MapToSpawnPoint(reader));
                        }
                    }
                }
            }
            
            return points;
        }

        public int InsertSpawnPoint(GatherSpawnPoint point)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_spawn_points 
                    (zone_id, zone_name, point_name, region_variable, node_type, spawn_point_index, enabled, notes)
                    VALUES (@zone_id, @zone_name, @point_name, @region_variable, @node_type, @spawn_point_index, @enabled, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@zone_id", point.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", point.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@point_name", point.PointName);
                    cmd.Parameters.AddWithValue("@region_variable", point.RegionVariable);
                    cmd.Parameters.AddWithValue("@node_type", point.NodeType);
                    cmd.Parameters.AddWithValue("@spawn_point_index", point.SpawnPointIndex.HasValue ? (object)point.SpawnPointIndex.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", point.Enabled);
                    cmd.Parameters.AddWithValue("@notes", point.Notes ?? (object)DBNull.Value);
                    
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateSpawnPoint(GatherSpawnPoint point)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_spawn_points SET
                        zone_id = @zone_id,
                        zone_name = @zone_name,
                        point_name = @point_name,
                        region_variable = @region_variable,
                        node_type = @node_type,
                        spawn_point_index = @spawn_point_index,
                        enabled = @enabled,
                        notes = @notes
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", point.Id);
                    cmd.Parameters.AddWithValue("@zone_id", point.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", point.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@point_name", point.PointName);
                    cmd.Parameters.AddWithValue("@region_variable", point.RegionVariable);
                    cmd.Parameters.AddWithValue("@node_type", point.NodeType);
                    cmd.Parameters.AddWithValue("@spawn_point_index", point.SpawnPointIndex.HasValue ? (object)point.SpawnPointIndex.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", point.Enabled);
                    cmd.Parameters.AddWithValue("@notes", point.Notes ?? (object)DBNull.Value);
                    
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteSpawnPoint(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_spawn_points WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Set enabled status for multiple spawn points
        /// </summary>
        public void SetSpawnPointsEnabled(IEnumerable<int> ids, bool enabled)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_spawn_points SET enabled = @enabled 
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@enabled", enabled);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        private GatherSpawnPoint MapToSpawnPoint(NpgsqlDataReader reader)
        {
            return new GatherSpawnPoint
            {
                Id = reader.GetInt32(0),
                ZoneId = reader.GetInt32(1),
                ZoneName = reader.IsDBNull(2) ? null : reader.GetString(2),
                PointName = reader.GetString(3),
                RegionVariable = reader.GetString(4),
                NodeType = reader.GetString(5),
                SpawnPointIndex = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                Enabled = reader.GetBoolean(7),
                Notes = reader.IsDBNull(8) ? null : reader.GetString(8),
                CreatedAt = reader.GetDateTime(9)
            };
        }

        #endregion

        #region Herb Definitions (Predefined Templates)

        /// <summary>
        /// Get all predefined herb/item definitions for quick selection
        /// </summary>
        public List<GatherHerbDefinition> GetHerbDefinitions()
        {
            var definitions = new List<GatherHerbDefinition>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, item_code, item_name, category, description, 
                           suggested_respawn_min, suggested_respawn_max, suggested_skill, 
                           tier_level, display_order
                    FROM gather_herb_definitions
                    ORDER BY tier_level, display_order, item_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            definitions.Add(new GatherHerbDefinition
                            {
                                Id = reader.GetInt32(0),
                                ItemCode = reader.GetString(1),
                                ItemName = reader.GetString(2),
                                Category = reader.IsDBNull(3) ? "Herbs" : reader.GetString(3),
                                Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                                SuggestedRespawnMin = reader.IsDBNull(5) ? 120.0 : reader.GetDouble(5),
                                SuggestedRespawnMax = reader.IsDBNull(6) ? 300.0 : reader.GetDouble(6),
                                SuggestedSkill = reader.IsDBNull(7) ? 0 : reader.GetInt32(7),
                                TierLevel = reader.IsDBNull(8) ? 1 : reader.GetInt32(8),
                                DisplayOrder = reader.IsDBNull(9) ? 0 : reader.GetInt32(9)
                            });
                        }
                    }
                }
            }

            return definitions;
        }

        #endregion

        #region Vein Definitions (Predefined Templates)

        /// <summary>
        /// Get all predefined vein/unit definitions for quick selection
        /// </summary>
        public List<GatherVeinDefinition> GetVeinDefinitions()
        {
            var definitions = new List<GatherVeinDefinition>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, unit_code, unit_name, category, description,
                           suggested_glow_r, suggested_glow_g, suggested_glow_b,
                           suggested_respawn_min, suggested_respawn_max, suggested_skill,
                           tier_level, display_order
                    FROM gather_vein_definitions
                    ORDER BY tier_level, display_order, unit_name", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            definitions.Add(new GatherVeinDefinition
                            {
                                Id = reader.GetInt32(0),
                                UnitCode = reader.GetString(1),
                                UnitName = reader.GetString(2),
                                Category = reader.IsDBNull(3) ? "Ore Veins" : reader.GetString(3),
                                Description = reader.IsDBNull(4) ? null : reader.GetString(4),
                                SuggestedGlowR = reader.IsDBNull(5) ? 255 : reader.GetInt32(5),
                                SuggestedGlowG = reader.IsDBNull(6) ? 200 : reader.GetInt32(6),
                                SuggestedGlowB = reader.IsDBNull(7) ? 0 : reader.GetInt32(7),
                                SuggestedRespawnMin = reader.IsDBNull(8) ? 180.0 : reader.GetDouble(8),
                                SuggestedRespawnMax = reader.IsDBNull(9) ? 400.0 : reader.GetDouble(9),
                                SuggestedSkill = reader.IsDBNull(10) ? 0 : reader.GetInt32(10),
                                TierLevel = reader.IsDBNull(11) ? 1 : reader.GetInt32(11),
                                DisplayOrder = reader.IsDBNull(12) ? 0 : reader.GetInt32(12)
                            });
                        }
                    }
                }
            }

            return definitions;
        }

        #endregion

        #region Database Items Lookup

        /// <summary>
        /// Get items from the main items table for selection
        /// </summary>
        public List<DatabaseItemInfo> GetDatabaseItems(string searchFilter = null)
        {
            var items = new List<DatabaseItemInfo>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                var sql = @"
                    SELECT i.id, i.item_code, i.item_name, 
                           COALESCE(it.type_name, 'Unknown') as type_name,
                           COALESCE(ir.rarity_name, 'Unknown') as rarity_name,
                           i.item_level
                    FROM items i
                    LEFT JOIN item_types it ON i.type_id = it.id
                    LEFT JOIN item_rarities ir ON i.rarity_id = ir.id";
                
                if (!string.IsNullOrEmpty(searchFilter))
                {
                    sql += " WHERE i.item_name ILIKE @filter OR i.item_code ILIKE @filter";
                }
                
                sql += " ORDER BY i.item_name LIMIT 500";

                using (var cmd = new NpgsqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchFilter))
                    {
                        cmd.Parameters.AddWithValue("@filter", "%" + searchFilter + "%");
                    }

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            items.Add(new DatabaseItemInfo
                            {
                                Id = reader.GetInt32(0),
                                ItemCode = reader.GetString(1),
                                ItemName = reader.GetString(2),
                                TypeName = reader.GetString(3),
                                RarityName = reader.GetString(4),
                                ItemLevel = reader.IsDBNull(5) ? 1 : reader.GetInt32(5)
                            });
                        }
                    }
                }
            }

            return items;
        }

        #endregion

        #region Database Unit Types Lookup

        /// <summary>
        /// Get unit types from the unit_types table for selection
        /// </summary>
        public List<DatabaseUnitInfo> GetDatabaseUnitTypes(string searchFilter = null)
        {
            var units = new List<DatabaseUnitInfo>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                var sql = @"
                    SELECT id, unit_code, unit_name, editor_suffix, unit_level, is_boss
                    FROM unit_types";
                
                if (!string.IsNullOrEmpty(searchFilter))
                {
                    sql += " WHERE unit_name ILIKE @filter OR unit_code ILIKE @filter OR editor_suffix ILIKE @filter";
                }
                
                sql += " ORDER BY unit_name LIMIT 500";

                using (var cmd = new NpgsqlCommand(sql, conn))
                {
                    if (!string.IsNullOrEmpty(searchFilter))
                    {
                        cmd.Parameters.AddWithValue("@filter", "%" + searchFilter + "%");
                    }

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            units.Add(new DatabaseUnitInfo
                            {
                                Id = reader.GetInt32(0),
                                UnitCode = reader.GetString(1),
                                UnitName = reader.GetString(2),
                                EditorSuffix = reader.IsDBNull(3) ? null : reader.GetString(3),
                                UnitLevel = reader.IsDBNull(4) ? 1 : reader.GetInt32(4),
                                IsBoss = reader.IsDBNull(5) ? false : reader.GetBoolean(5)
                            });
                        }
                    }
                }
            }

            return units;
        }

        #endregion

        #region Zones

        /// <summary>
        /// Get all zones from gather_zones table
        /// </summary>
        public List<GatherZone> GetAllZones()
        {
            var zones = new List<GatherZone>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, zone_id, zone_name, environment_type, is_dungeon, 
                           level_range, parent_zone_id, enabled, created_at
                    FROM gather_zones
                    WHERE enabled = true
                    ORDER BY 
                        CASE WHEN is_dungeon THEN 1 ELSE 0 END,
                        CASE WHEN parent_zone_id IS NULL THEN zone_id ELSE parent_zone_id END,
                        CASE WHEN parent_zone_id IS NULL THEN 0 ELSE 1 END,
                        zone_id", conn))
                {
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            zones.Add(new GatherZone
                            {
                                Id = reader.GetInt32(0),
                                ZoneId = reader.GetInt32(1),
                                ZoneName = reader.GetString(2),
                                EnvironmentType = reader.IsDBNull(3) ? null : reader.GetString(3),
                                IsDungeon = reader.GetBoolean(4),
                                LevelRange = reader.IsDBNull(5) ? null : reader.GetString(5),
                                ParentZoneId = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                                Enabled = reader.GetBoolean(7),
                                CreatedAt = reader.GetDateTime(8)
                            });
                        }
                    }
                }
            }

            return zones;
        }

        /// <summary>
        /// Get zone by zone_id
        /// </summary>
        public GatherZone GetZoneById(int zoneId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, zone_id, zone_name, environment_type, is_dungeon, 
                           level_range, parent_zone_id, enabled, created_at
                    FROM gather_zones
                    WHERE zone_id = @zoneId", conn))
                {
                    cmd.Parameters.AddWithValue("@zoneId", zoneId);

                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new GatherZone
                            {
                                Id = reader.GetInt32(0),
                                ZoneId = reader.GetInt32(1),
                                ZoneName = reader.GetString(2),
                                EnvironmentType = reader.IsDBNull(3) ? null : reader.GetString(3),
                                IsDungeon = reader.GetBoolean(4),
                                LevelRange = reader.IsDBNull(5) ? null : reader.GetString(5),
                                ParentZoneId = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                                Enabled = reader.GetBoolean(7),
                                CreatedAt = reader.GetDateTime(8)
                            };
                        }
                    }
                }
            }

            return null;
        }

        #endregion
    }

    #region Definition Model Classes

    /// <summary>
    /// Predefined herb/item definition for quick selection
    /// </summary>
    public class GatherHerbDefinition
    {
        public int Id { get; set; }
        public string ItemCode { get; set; }
        public string ItemName { get; set; }
        public string Category { get; set; }
        public string Description { get; set; }
        public double SuggestedRespawnMin { get; set; }
        public double SuggestedRespawnMax { get; set; }
        public int SuggestedSkill { get; set; }
        public int TierLevel { get; set; }
        public int DisplayOrder { get; set; }

        public override string ToString() => $"[{ItemCode}] {ItemName} (Tier {TierLevel})";
    }

    /// <summary>
    /// Predefined vein/unit definition for quick selection
    /// </summary>
    public class GatherVeinDefinition
    {
        public int Id { get; set; }
        public string UnitCode { get; set; }
        public string UnitName { get; set; }
        public string Category { get; set; }
        public string Description { get; set; }
        public int SuggestedGlowR { get; set; }
        public int SuggestedGlowG { get; set; }
        public int SuggestedGlowB { get; set; }
        public double SuggestedRespawnMin { get; set; }
        public double SuggestedRespawnMax { get; set; }
        public int SuggestedSkill { get; set; }
        public int TierLevel { get; set; }
        public int DisplayOrder { get; set; }

        public override string ToString() => $"[{UnitCode}] {UnitName} ({Category})";
    }

    /// <summary>
    /// Item info from the main items database table
    /// </summary>
    public class DatabaseItemInfo
    {
        public int Id { get; set; }
        public string ItemCode { get; set; }
        public string ItemName { get; set; }
        public string TypeName { get; set; }
        public string RarityName { get; set; }
        public int ItemLevel { get; set; }

        public override string ToString() => $"[{ItemCode}] {ItemName} ({TypeName}, L{ItemLevel})";
    }

    /// <summary>
    /// Unit type info from the unit_types database table
    /// </summary>
    public class DatabaseUnitInfo
    {
        public int Id { get; set; }
        public string UnitCode { get; set; }
        public string UnitName { get; set; }
        public string EditorSuffix { get; set; }
        public int UnitLevel { get; set; }
        public bool IsBoss { get; set; }

        public string DisplayName => string.IsNullOrEmpty(EditorSuffix) 
            ? UnitName 
            : $"{UnitName} ({EditorSuffix})";

        public override string ToString() => $"[{UnitCode}] {DisplayName} (L{UnitLevel})";
    }

    #endregion
}
