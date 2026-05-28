using System;
using System.Collections.Generic;
using System.Linq;
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
            EnsureSchema();
        }

        private void EnsureSchema()
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();

                using (var cmd = new NpgsqlCommand(@"
                    CREATE TABLE IF NOT EXISTS gather_spawn_point_groups (
                        id SERIAL PRIMARY KEY,
                        zone_id INT NOT NULL,
                        zone_name VARCHAR(100),
                        group_name VARCHAR(100) NOT NULL,
                        node_type VARCHAR(10) DEFAULT 'both' CHECK (node_type IN ('item', 'unit', 'both')),
                        enabled BOOLEAN DEFAULT TRUE,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE(zone_id, group_name, node_type)
                    );

                    ALTER TABLE gather_spawn_points
                        ADD COLUMN IF NOT EXISTS spawn_group_id INT NULL;

                    ALTER TABLE gather_node_zones
                        ADD COLUMN IF NOT EXISTS spawn_group_id INT NULL;

                    ALTER TABLE gather_node_zones
                        ADD COLUMN IF NOT EXISTS shared_max_override INT NULL;

                    ALTER TABLE gather_item_nodes
                        ADD COLUMN IF NOT EXISTS display_order INT NULL;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS display_order INT NULL;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS glow_height DOUBLE PRECISION NULL;

                    ALTER TABLE gather_item_nodes
                        ADD COLUMN IF NOT EXISTS glow_scale DOUBLE PRECISION NULL;

                    ALTER TABLE gather_item_nodes
                        ADD COLUMN IF NOT EXISTS glow_height DOUBLE PRECISION NULL;

                    ALTER TABLE gather_item_nodes
                        ADD COLUMN IF NOT EXISTS prevent_water_spawn BOOLEAN NOT NULL DEFAULT FALSE;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS prevent_water_spawn BOOLEAN NOT NULL DEFAULT FALSE;

                    ALTER TABLE gather_item_nodes
                        ADD COLUMN IF NOT EXISTS profession_id INT NOT NULL DEFAULT 0;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS profession_id INT NOT NULL DEFAULT 0;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS harvest_yield_min INT NOT NULL DEFAULT 3;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS harvest_yield_max INT NOT NULL DEFAULT 6;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS gather_success_chance_percent INT NOT NULL DEFAULT 100;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS main_drop_group_chance_percent INT NOT NULL DEFAULT 100;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS secondary_drop_group_chance_percent INT NOT NULL DEFAULT 25;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS special_behavior_id INT NOT NULL DEFAULT 0;

                    ALTER TABLE gather_unit_nodes
                        ADD COLUMN IF NOT EXISTS special_behavior_chance_percent INT NOT NULL DEFAULT 20;

                    CREATE TABLE IF NOT EXISTS gather_unit_node_drops (
                        id SERIAL PRIMARY KEY,
                        node_id INT NOT NULL REFERENCES gather_unit_nodes(id) ON DELETE CASCADE,
                        group_name VARCHAR(100) NOT NULL DEFAULT 'Main',
                        item_code VARCHAR(4) NOT NULL,
                        item_name VARCHAR(255),
                        drop_chance_percent INT NOT NULL DEFAULT 100,
                        weight INT NOT NULL DEFAULT 100,
                        min_quantity INT NOT NULL DEFAULT 1,
                        max_quantity INT NOT NULL DEFAULT 1,
                        enabled BOOLEAN NOT NULL DEFAULT TRUE,
                        display_order INT NOT NULL DEFAULT 0,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );

                    ALTER TABLE gather_unit_node_drops
                        ADD COLUMN IF NOT EXISTS group_name VARCHAR(100) NOT NULL DEFAULT 'Main';

                    ALTER TABLE gather_unit_node_drops
                        ADD COLUMN IF NOT EXISTS weight INT NOT NULL DEFAULT 100;

                    UPDATE gather_item_nodes
                    SET display_order = id
                    WHERE display_order IS NULL;

                    UPDATE gather_unit_nodes
                    SET display_order = id
                    WHERE display_order IS NULL;

                    UPDATE gather_unit_nodes
                    SET glow_height = 0
                    WHERE glow_height IS NULL;

                    UPDATE gather_item_nodes
                    SET glow_scale = 1.0
                    WHERE glow_scale IS NULL;

                    UPDATE gather_item_nodes
                    SET glow_height = 0
                    WHERE glow_height IS NULL;

                    UPDATE gather_item_nodes gin
                    SET profession_id = CASE
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%herb%' THEN 2
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%flower%' THEN 2
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%mushroom%' THEN 2
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%reagent%' THEN 2
                        ELSE 0
                    END
                    FROM gather_node_categories gnc
                    WHERE gin.category_id = gnc.id
                      AND gin.profession_id = 0;

                    UPDATE gather_unit_nodes gun
                    SET profession_id = CASE
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%ore%' THEN 1
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%crystal%' THEN 1
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%vein%' THEN 1
                        WHEN LOWER(COALESCE(gnc.category_name, '')) LIKE '%fish%' THEN 4
                        ELSE 0
                    END
                    FROM gather_node_categories gnc
                    WHERE gun.category_id = gnc.id
                      AND gun.profession_id = 0;

                    UPDATE gather_unit_nodes
                    SET special_behavior_id = 1,
                        special_behavior_chance_percent = 20
                    WHERE special_behavior_id = 0
                      AND LOWER(COALESCE(node_name, '')) LIKE '%mana crystal%';

                    CREATE INDEX IF NOT EXISTS idx_gather_spawn_point_groups_zone ON gather_spawn_point_groups(zone_id);
                    CREATE INDEX IF NOT EXISTS idx_gather_spawn_points_group ON gather_spawn_points(spawn_group_id);
                    CREATE INDEX IF NOT EXISTS idx_gather_node_zones_group ON gather_node_zones(spawn_group_id);
                    CREATE INDEX IF NOT EXISTS idx_gather_unit_node_drops_node ON gather_unit_node_drops(node_id);
                ", conn))
                {
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_spawn_point_groups (zone_id, zone_name, group_name, node_type, enabled, notes)
                    SELECT DISTINCT
                        sp.zone_id,
                        COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text),
                        CASE
                            WHEN sp.node_type = 'item' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Items'
                            WHEN sp.node_type = 'unit' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Units'
                            ELSE COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Shared'
                        END,
                        sp.node_type,
                        TRUE,
                        'Auto-created legacy group'
                    FROM gather_spawn_points sp
                    LEFT JOIN gather_spawn_point_groups g
                        ON g.zone_id = sp.zone_id
                       AND g.node_type = sp.node_type
                       AND g.group_name = CASE
                            WHEN sp.node_type = 'item' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Items'
                            WHEN sp.node_type = 'unit' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Units'
                            ELSE COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Shared'
                        END
                    WHERE g.id IS NULL;

                    UPDATE gather_spawn_points sp
                    SET spawn_group_id = g.id
                    FROM gather_spawn_point_groups g
                    WHERE sp.spawn_group_id IS NULL
                      AND g.zone_id = sp.zone_id
                      AND g.node_type = sp.node_type
                      AND g.group_name = CASE
                            WHEN sp.node_type = 'item' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Items'
                            WHEN sp.node_type = 'unit' THEN COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Units'
                            ELSE COALESCE(sp.zone_name, 'Zone ' || sp.zone_id::text) || ' Shared'
                        END;

                    UPDATE gather_node_zones gnz
                    SET spawn_group_id = g.id
                    FROM gather_spawn_point_groups g
                    WHERE gnz.spawn_group_id IS NULL
                      AND gnz.spawn_mode IN ('fixed', 'both')
                      AND g.zone_id = gnz.zone_id
                      AND g.node_type IN (gnz.node_type, 'both')
                      AND g.group_name = CASE
                            WHEN gnz.node_type = 'item' THEN COALESCE(gnz.zone_name, 'Zone ' || gnz.zone_id::text) || ' Items'
                            WHEN gnz.node_type = 'unit' THEN COALESCE(gnz.zone_name, 'Zone ' || gnz.zone_id::text) || ' Units'
                            ELSE COALESCE(gnz.zone_name, 'Zone ' || gnz.zone_id::text) || ' Shared'
                        END;
                ", conn))
                {
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private int GetNextNodeDisplayOrder(NpgsqlConnection conn, string tableName)
        {
            using (var cmd = new NpgsqlCommand($"SELECT COALESCE(MAX(display_order), 0) + 10 FROM {tableName}", conn))
            {
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
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
                           gin.max_per_zone, gin.skill_required, gin.profession_id, gin.prevent_water_spawn,
                           gin.glow_effect, gin.glow_color_r, gin.glow_color_g, gin.glow_color_b, gin.glow_alpha,
                           gin.glow_scale, gin.glow_height,
                           gin.is_rare, gin.enabled, gin.notes, gin.created_at, gin.updated_at, gin.display_order
                    FROM gather_item_nodes gin
                    LEFT JOIN gather_node_categories gnc ON gin.category_id = gnc.id
                    ORDER BY COALESCE(gnc.display_order, 2147483647), gin.display_order, gin.node_name", conn))
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
                           gin.max_per_zone, gin.skill_required, gin.profession_id, gin.prevent_water_spawn,
                           gin.glow_effect, gin.glow_color_r, gin.glow_color_g, gin.glow_color_b, gin.glow_alpha,
                           gin.glow_scale, gin.glow_height,
                           gin.is_rare, gin.enabled, gin.notes, gin.created_at, gin.updated_at, gin.display_order
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
                if (node.DisplayOrder <= 0)
                {
                    node.DisplayOrder = GetNextNodeDisplayOrder(conn, "gather_item_nodes");
                }
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_item_nodes 
                    (item_code, node_name, category_id, spawn_weight, respawn_time_min, respawn_time_max,
                     max_per_zone, skill_required, profession_id, prevent_water_spawn, glow_effect, glow_color_r, glow_color_g, glow_color_b,
                     glow_alpha, glow_scale, glow_height, is_rare, enabled, notes, display_order)
                    VALUES (@item_code, @node_name, @category_id, @spawn_weight, @respawn_time_min, @respawn_time_max,
                            @max_per_zone, @skill_required, @profession_id, @prevent_water_spawn, @glow_effect, @glow_color_r, @glow_color_g, @glow_color_b,
                            @glow_alpha, @glow_scale, @glow_height, @is_rare, @enabled, @notes, @display_order)
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
                    cmd.Parameters.AddWithValue("@profession_id", node.ProfessionId);
                    cmd.Parameters.AddWithValue("@prevent_water_spawn", node.PreventWaterSpawn);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@glow_height", node.GlowHeight);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    cmd.Parameters.AddWithValue("@display_order", node.DisplayOrder);
                    
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
                        profession_id = @profession_id,
                        prevent_water_spawn = @prevent_water_spawn,
                        glow_effect = @glow_effect,
                        glow_color_r = @glow_color_r,
                        glow_color_g = @glow_color_g,
                        glow_color_b = @glow_color_b,
                        glow_alpha = @glow_alpha,
                        glow_scale = @glow_scale,
                        glow_height = @glow_height,
                        is_rare = @is_rare,
                        enabled = @enabled,
                        notes = @notes,
                        display_order = @display_order,
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
                    cmd.Parameters.AddWithValue("@profession_id", node.ProfessionId);
                    cmd.Parameters.AddWithValue("@prevent_water_spawn", node.PreventWaterSpawn);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@glow_height", node.GlowHeight);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    cmd.Parameters.AddWithValue("@display_order", node.DisplayOrder);
                    
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

        public void SetItemNodesCategory(IEnumerable<int> ids, int? categoryId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_item_nodes
                        SET category_id = @category_id, updated_at = CURRENT_TIMESTAMP
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@category_id", categoryId.HasValue ? (object)categoryId.Value : DBNull.Value);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        public bool MoveItemNode(int nodeId, bool moveUp)
        {
            var nodesInCategory = GetAllItemNodes();
            var current = nodesInCategory.FirstOrDefault(n => n.Id == nodeId);
            if (current == null)
            {
                return false;
            }

            var sameCategory = nodesInCategory
                .Where(n => n.CategoryId == current.CategoryId)
                .OrderBy(n => n.DisplayOrder)
                .ThenBy(n => n.NodeName)
                .ToList();

            var index = sameCategory.FindIndex(n => n.Id == nodeId);
            var targetIndex = moveUp ? index - 1 : index + 1;
            if (index < 0 || targetIndex < 0 || targetIndex >= sameCategory.Count)
            {
                return false;
            }

            var moved = sameCategory[index];
            sameCategory[index] = sameCategory[targetIndex];
            sameCategory[targetIndex] = moved;
            SaveItemNodeDisplayOrder(sameCategory);
            return true;
        }

        private void SaveItemNodeDisplayOrder(List<GatherItemNode> orderedNodes)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                for (int i = 0; i < orderedNodes.Count; i++)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_item_nodes
                        SET display_order = @display_order, updated_at = CURRENT_TIMESTAMP
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", orderedNodes[i].Id);
                        cmd.Parameters.AddWithValue("@display_order", (i + 1) * 10);
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
                ProfessionId = reader.GetInt32(10),
                PreventWaterSpawn = reader.GetBoolean(11),
                GlowEffect = reader.GetBoolean(12),
                GlowColorR = reader.GetInt32(13),
                GlowColorG = reader.GetInt32(14),
                GlowColorB = reader.GetInt32(15),
                GlowAlpha = reader.GetInt32(16),
                GlowScale = reader.IsDBNull(17) ? 1.0 : reader.GetDouble(17),
                GlowHeight = reader.IsDBNull(18) ? 0.0 : reader.GetDouble(18),
                IsRare = reader.GetBoolean(19),
                Enabled = reader.GetBoolean(20),
                Notes = reader.IsDBNull(21) ? null : reader.GetString(21),
                CreatedAt = reader.GetDateTime(22),
                UpdatedAt = reader.GetDateTime(23),
                DisplayOrder = reader.IsDBNull(24) ? 0 : reader.GetInt32(24)
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
                           gun.max_per_zone, gun.skill_required, gun.profession_id,
                           gun.harvest_yield_min, gun.harvest_yield_max, gun.gather_success_chance_percent,
                           gun.main_drop_group_chance_percent, gun.secondary_drop_group_chance_percent,
                           gun.special_behavior_id, gun.special_behavior_chance_percent,
                           gun.owner_player, gun.prevent_water_spawn,
                           gun.glow_effect, gun.glow_color_r, gun.glow_color_g, gun.glow_color_b, 
                           gun.glow_alpha, gun.glow_scale, gun.glow_height,
                           gun.is_rare, gun.enabled, gun.notes, gun.created_at, gun.updated_at, gun.display_order
                    FROM gather_unit_nodes gun
                    LEFT JOIN gather_node_categories gnc ON gun.category_id = gnc.id
                    ORDER BY COALESCE(gnc.display_order, 2147483647), gun.display_order, gun.node_name", conn))
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
                           gun.max_per_zone, gun.skill_required, gun.profession_id,
                           gun.harvest_yield_min, gun.harvest_yield_max, gun.gather_success_chance_percent,
                           gun.main_drop_group_chance_percent, gun.secondary_drop_group_chance_percent,
                           gun.special_behavior_id, gun.special_behavior_chance_percent,
                           gun.owner_player, gun.prevent_water_spawn,
                           gun.glow_effect, gun.glow_color_r, gun.glow_color_g, gun.glow_color_b, 
                           gun.glow_alpha, gun.glow_scale, gun.glow_height,
                           gun.is_rare, gun.enabled, gun.notes, gun.created_at, gun.updated_at, gun.display_order
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
                if (node.DisplayOrder <= 0)
                {
                    node.DisplayOrder = GetNextNodeDisplayOrder(conn, "gather_unit_nodes");
                }
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_unit_nodes 
                    (unit_code, node_name, category_id, spawn_weight, respawn_time_min, respawn_time_max,
                     max_per_zone, skill_required, profession_id, harvest_yield_min, harvest_yield_max,
                     gather_success_chance_percent, main_drop_group_chance_percent, secondary_drop_group_chance_percent,
                     special_behavior_id, special_behavior_chance_percent,
                     owner_player, prevent_water_spawn, glow_effect, glow_color_r, glow_color_g, 
                     glow_color_b, glow_alpha, glow_scale, glow_height, is_rare, enabled, notes, display_order)
                    VALUES (@unit_code, @node_name, @category_id, @spawn_weight, @respawn_time_min, @respawn_time_max,
                            @max_per_zone, @skill_required, @profession_id, @harvest_yield_min, @harvest_yield_max,
                            @gather_success_chance_percent, @main_drop_group_chance_percent, @secondary_drop_group_chance_percent, @special_behavior_id, @special_behavior_chance_percent,
                            @owner_player, @prevent_water_spawn, @glow_effect, @glow_color_r, @glow_color_g,
                            @glow_color_b, @glow_alpha, @glow_scale, @glow_height, @is_rare, @enabled, @notes, @display_order)
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
                    cmd.Parameters.AddWithValue("@profession_id", node.ProfessionId);
                    cmd.Parameters.AddWithValue("@harvest_yield_min", node.HarvestYieldMin);
                    cmd.Parameters.AddWithValue("@harvest_yield_max", node.HarvestYieldMax);
                    cmd.Parameters.AddWithValue("@gather_success_chance_percent", node.GatherSuccessChancePercent);
                    cmd.Parameters.AddWithValue("@main_drop_group_chance_percent", node.MainDropGroupChancePercent);
                    cmd.Parameters.AddWithValue("@secondary_drop_group_chance_percent", node.SecondaryDropGroupChancePercent);
                    cmd.Parameters.AddWithValue("@special_behavior_id", node.SpecialBehaviorId);
                    cmd.Parameters.AddWithValue("@special_behavior_chance_percent", node.SpecialBehaviorChancePercent);
                    cmd.Parameters.AddWithValue("@owner_player", node.OwnerPlayer);
                    cmd.Parameters.AddWithValue("@prevent_water_spawn", node.PreventWaterSpawn);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@glow_height", node.GlowHeight);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    cmd.Parameters.AddWithValue("@display_order", node.DisplayOrder);
                    
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
                        profession_id = @profession_id,
                        harvest_yield_min = @harvest_yield_min,
                        harvest_yield_max = @harvest_yield_max,
                        gather_success_chance_percent = @gather_success_chance_percent,
                        main_drop_group_chance_percent = @main_drop_group_chance_percent,
                        secondary_drop_group_chance_percent = @secondary_drop_group_chance_percent,
                        special_behavior_id = @special_behavior_id,
                        special_behavior_chance_percent = @special_behavior_chance_percent,
                        owner_player = @owner_player,
                        prevent_water_spawn = @prevent_water_spawn,
                        glow_effect = @glow_effect,
                        glow_color_r = @glow_color_r,
                        glow_color_g = @glow_color_g,
                        glow_color_b = @glow_color_b,
                        glow_alpha = @glow_alpha,
                        glow_scale = @glow_scale,
                        glow_height = @glow_height,
                        is_rare = @is_rare,
                        enabled = @enabled,
                        notes = @notes,
                        display_order = @display_order,
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
                    cmd.Parameters.AddWithValue("@profession_id", node.ProfessionId);
                    cmd.Parameters.AddWithValue("@harvest_yield_min", node.HarvestYieldMin);
                    cmd.Parameters.AddWithValue("@harvest_yield_max", node.HarvestYieldMax);
                    cmd.Parameters.AddWithValue("@gather_success_chance_percent", node.GatherSuccessChancePercent);
                    cmd.Parameters.AddWithValue("@main_drop_group_chance_percent", node.MainDropGroupChancePercent);
                    cmd.Parameters.AddWithValue("@secondary_drop_group_chance_percent", node.SecondaryDropGroupChancePercent);
                    cmd.Parameters.AddWithValue("@special_behavior_id", node.SpecialBehaviorId);
                    cmd.Parameters.AddWithValue("@special_behavior_chance_percent", node.SpecialBehaviorChancePercent);
                    cmd.Parameters.AddWithValue("@owner_player", node.OwnerPlayer);
                    cmd.Parameters.AddWithValue("@prevent_water_spawn", node.PreventWaterSpawn);
                    cmd.Parameters.AddWithValue("@glow_effect", node.GlowEffect);
                    cmd.Parameters.AddWithValue("@glow_color_r", node.GlowColorR);
                    cmd.Parameters.AddWithValue("@glow_color_g", node.GlowColorG);
                    cmd.Parameters.AddWithValue("@glow_color_b", node.GlowColorB);
                    cmd.Parameters.AddWithValue("@glow_alpha", node.GlowAlpha);
                    cmd.Parameters.AddWithValue("@glow_scale", node.GlowScale);
                    cmd.Parameters.AddWithValue("@glow_height", node.GlowHeight);
                    cmd.Parameters.AddWithValue("@is_rare", node.IsRare);
                    cmd.Parameters.AddWithValue("@enabled", node.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrEmpty(node.Notes) ? DBNull.Value : (object)node.Notes);
                    cmd.Parameters.AddWithValue("@display_order", node.DisplayOrder);
                    
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

        public void SetUnitNodesCategory(IEnumerable<int> ids, int? categoryId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_unit_nodes
                        SET category_id = @category_id, updated_at = CURRENT_TIMESTAMP
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@category_id", categoryId.HasValue ? (object)categoryId.Value : DBNull.Value);
                        cmd.ExecuteNonQuery();
                    }
                }
            }
        }

        public bool MoveUnitNode(int nodeId, bool moveUp)
        {
            var nodesInCategory = GetAllUnitNodes();
            var current = nodesInCategory.FirstOrDefault(n => n.Id == nodeId);
            if (current == null)
            {
                return false;
            }

            var sameCategory = nodesInCategory
                .Where(n => n.CategoryId == current.CategoryId)
                .OrderBy(n => n.DisplayOrder)
                .ThenBy(n => n.NodeName)
                .ToList();

            var index = sameCategory.FindIndex(n => n.Id == nodeId);
            var targetIndex = moveUp ? index - 1 : index + 1;
            if (index < 0 || targetIndex < 0 || targetIndex >= sameCategory.Count)
            {
                return false;
            }

            var moved = sameCategory[index];
            sameCategory[index] = sameCategory[targetIndex];
            sameCategory[targetIndex] = moved;
            SaveUnitNodeDisplayOrder(sameCategory);
            return true;
        }

        private void SaveUnitNodeDisplayOrder(List<GatherUnitNode> orderedNodes)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                for (int i = 0; i < orderedNodes.Count; i++)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_unit_nodes
                        SET display_order = @display_order, updated_at = CURRENT_TIMESTAMP
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", orderedNodes[i].Id);
                        cmd.Parameters.AddWithValue("@display_order", (i + 1) * 10);
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
                ProfessionId = reader.GetInt32(10),
                HarvestYieldMin = reader.GetInt32(11),
                HarvestYieldMax = reader.GetInt32(12),
                GatherSuccessChancePercent = reader.GetInt32(13),
                MainDropGroupChancePercent = reader.GetInt32(14),
                SecondaryDropGroupChancePercent = reader.GetInt32(15),
                SpecialBehaviorId = reader.GetInt32(16),
                SpecialBehaviorChancePercent = reader.GetInt32(17),
                OwnerPlayer = reader.GetInt32(18),
                PreventWaterSpawn = reader.GetBoolean(19),
                GlowEffect = reader.GetBoolean(20),
                GlowColorR = reader.GetInt32(21),
                GlowColorG = reader.GetInt32(22),
                GlowColorB = reader.GetInt32(23),
                GlowAlpha = reader.GetInt32(24),
                GlowScale = reader.GetDouble(25),
                GlowHeight = reader.IsDBNull(26) ? 0.0 : reader.GetDouble(26),
                IsRare = reader.GetBoolean(27),
                Enabled = reader.GetBoolean(28),
                Notes = reader.IsDBNull(29) ? null : reader.GetString(29),
                CreatedAt = reader.GetDateTime(30),
                UpdatedAt = reader.GetDateTime(31),
                DisplayOrder = reader.IsDBNull(32) ? 0 : reader.GetInt32(32)
            };
        }

        public List<GatherUnitNodeDrop> GetUnitNodeDrops(int nodeId)
        {
            var drops = new List<GatherUnitNodeDrop>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, node_id, item_code, item_name, drop_chance_percent,
                           min_quantity, max_quantity, enabled, display_order, notes, created_at, updated_at,
                           group_name, weight
                    FROM gather_unit_node_drops
                    WHERE node_id = @nodeId
                    ORDER BY display_order, item_name", conn))
                {
                    cmd.Parameters.AddWithValue("@nodeId", nodeId);
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            drops.Add(MapToUnitNodeDrop(reader));
                        }
                    }
                }
            }

            return drops;
        }

        public int InsertUnitNodeDrop(GatherUnitNodeDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                if (drop.DisplayOrder <= 0)
                {
                    using (var orderCmd = new NpgsqlCommand("SELECT COALESCE(MAX(display_order), 0) + 10 FROM gather_unit_node_drops WHERE node_id = @nodeId", conn))
                    {
                        orderCmd.Parameters.AddWithValue("@nodeId", drop.NodeId);
                        drop.DisplayOrder = Convert.ToInt32(orderCmd.ExecuteScalar());
                    }
                }

                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_unit_node_drops
                    (node_id, group_name, item_code, item_name, drop_chance_percent, weight, min_quantity, max_quantity, enabled, display_order, notes)
                    VALUES
                    (@node_id, @group_name, @item_code, @item_name, @drop_chance_percent, @weight, @min_quantity, @max_quantity, @enabled, @display_order, @notes)
                    RETURNING id", conn))
                {
                    AddUnitNodeDropParameters(cmd, drop);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateUnitNodeDrop(GatherUnitNodeDrop drop)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_unit_node_drops SET
                        item_code = @item_code,
                        item_name = @item_name,
                        group_name = @group_name,
                        drop_chance_percent = @drop_chance_percent,
                        weight = @weight,
                        min_quantity = @min_quantity,
                        max_quantity = @max_quantity,
                        enabled = @enabled,
                        display_order = @display_order,
                        notes = @notes,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", drop.Id);
                    AddUnitNodeDropParameters(cmd, drop);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteUnitNodeDrop(int dropId)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand("DELETE FROM gather_unit_node_drops WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", dropId);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private GatherUnitNodeDrop MapToUnitNodeDrop(NpgsqlDataReader reader)
        {
            return new GatherUnitNodeDrop
            {
                Id = reader.GetInt32(0),
                NodeId = reader.GetInt32(1),
                ItemCode = reader.GetString(2),
                ItemName = reader.IsDBNull(3) ? reader.GetString(2) : reader.GetString(3),
                DropChancePercent = reader.GetInt32(4),
                MinQuantity = reader.GetInt32(5),
                MaxQuantity = reader.GetInt32(6),
                Enabled = reader.GetBoolean(7),
                DisplayOrder = reader.GetInt32(8),
                Notes = reader.IsDBNull(9) ? null : reader.GetString(9),
                CreatedAt = reader.GetDateTime(10),
                UpdatedAt = reader.GetDateTime(11),
                GroupName = reader.IsDBNull(12) || !string.Equals(reader.GetString(12), GatherUnitNodeDrop.SecondaryGroup, StringComparison.OrdinalIgnoreCase)
                    ? GatherUnitNodeDrop.MainGroup
                    : GatherUnitNodeDrop.SecondaryGroup,
                Weight = reader.IsDBNull(13) ? 100 : reader.GetInt32(13)
            };
        }

        private void AddUnitNodeDropParameters(NpgsqlCommand cmd, GatherUnitNodeDrop drop)
        {
            cmd.Parameters.AddWithValue("@node_id", drop.NodeId);
            cmd.Parameters.AddWithValue("@group_name", string.Equals(drop.GroupName, GatherUnitNodeDrop.SecondaryGroup, StringComparison.OrdinalIgnoreCase)
                ? GatherUnitNodeDrop.SecondaryGroup
                : GatherUnitNodeDrop.MainGroup);
            cmd.Parameters.AddWithValue("@item_code", drop.ItemCode);
            cmd.Parameters.AddWithValue("@item_name", string.IsNullOrWhiteSpace(drop.ItemName) ? DBNull.Value : (object)drop.ItemName);
            cmd.Parameters.AddWithValue("@drop_chance_percent", drop.DropChancePercent);
            cmd.Parameters.AddWithValue("@weight", drop.Weight);
            cmd.Parameters.AddWithValue("@min_quantity", drop.MinQuantity);
            cmd.Parameters.AddWithValue("@max_quantity", drop.MaxQuantity);
            cmd.Parameters.AddWithValue("@enabled", drop.Enabled);
            cmd.Parameters.AddWithValue("@display_order", drop.DisplayOrder);
            cmd.Parameters.AddWithValue("@notes", string.IsNullOrWhiteSpace(drop.Notes) ? DBNull.Value : (object)drop.Notes);
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
                    SELECT gnz.id, gnz.node_type, gnz.node_id, gnz.zone_id, gnz.zone_name, gnz.spawn_mode,
                           gnz.spawn_group_id, gspg.group_name,
                           gnz.weight_override, gnz.max_override, gnz.shared_max_override, gnz.enabled, gnz.created_at
                    FROM gather_node_zones gnz
                    LEFT JOIN gather_spawn_point_groups gspg ON gnz.spawn_group_id = gspg.id
                    WHERE gnz.node_type = @nodeType AND gnz.node_id = @nodeId
                    ORDER BY gnz.zone_id", conn))
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
                           gnz.spawn_mode, gnz.spawn_group_id, gspg.group_name,
                           gnz.weight_override, gnz.max_override, gnz.shared_max_override, gnz.enabled, gnz.created_at,
                           CASE WHEN gnz.node_type = 'item' THEN gin.node_name ELSE gun.node_name END as node_name,
                           CASE WHEN gnz.node_type = 'item' THEN gin.item_code ELSE gun.unit_code END as node_code
                    FROM gather_node_zones gnz
                    LEFT JOIN gather_item_nodes gin ON gnz.node_type = 'item' AND gnz.node_id = gin.id
                    LEFT JOIN gather_unit_nodes gun ON gnz.node_type = 'unit' AND gnz.node_id = gun.id
                    LEFT JOIN gather_spawn_point_groups gspg ON gnz.spawn_group_id = gspg.id
                    WHERE gnz.zone_id = @zoneId
                    ORDER BY gnz.node_type, node_name", conn))
                {
                    cmd.Parameters.AddWithValue("@zoneId", zoneId);
                    
                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var zone = MapToNodeZone(reader);
                            zone.NodeName = reader.IsDBNull(13) ? null : reader.GetString(13);
                            zone.NodeCode = reader.IsDBNull(14) ? null : reader.GetString(14);
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
                    (node_type, node_id, zone_id, zone_name, spawn_mode, spawn_group_id, weight_override, max_override, shared_max_override, enabled)
                    VALUES (@node_type, @node_id, @zone_id, @zone_name, @spawn_mode, @spawn_group_id, @weight_override, @max_override, @shared_max_override, @enabled)
                    ON CONFLICT (node_type, node_id, zone_id) DO UPDATE SET
                        zone_name = EXCLUDED.zone_name,
                        spawn_mode = EXCLUDED.spawn_mode,
                        spawn_group_id = EXCLUDED.spawn_group_id,
                        weight_override = EXCLUDED.weight_override,
                        max_override = EXCLUDED.max_override,
                        shared_max_override = EXCLUDED.shared_max_override,
                        enabled = EXCLUDED.enabled
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@node_type", zone.NodeType);
                    cmd.Parameters.AddWithValue("@node_id", zone.NodeId);
                    cmd.Parameters.AddWithValue("@zone_id", zone.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", zone.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_mode", zone.SpawnMode);
                    cmd.Parameters.AddWithValue("@spawn_group_id", zone.SpawnGroupId.HasValue ? (object)zone.SpawnGroupId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@weight_override", zone.WeightOverride.HasValue ? (object)zone.WeightOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@max_override", zone.MaxOverride.HasValue ? (object)zone.MaxOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@shared_max_override", zone.SharedMaxOverride.HasValue ? (object)zone.SharedMaxOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", zone.Enabled);
                    
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateZoneAssignment(GatherNodeZone zone)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_node_zones SET
                        zone_id = @zone_id,
                        zone_name = @zone_name,
                        spawn_mode = @spawn_mode,
                        spawn_group_id = @spawn_group_id,
                        weight_override = @weight_override,
                        max_override = @max_override,
                        shared_max_override = @shared_max_override,
                        enabled = @enabled
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", zone.Id);
                    cmd.Parameters.AddWithValue("@zone_id", zone.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", zone.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@spawn_mode", zone.SpawnMode);
                    cmd.Parameters.AddWithValue("@spawn_group_id", zone.SpawnGroupId.HasValue ? (object)zone.SpawnGroupId.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@weight_override", zone.WeightOverride.HasValue ? (object)zone.WeightOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@max_override", zone.MaxOverride.HasValue ? (object)zone.MaxOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@shared_max_override", zone.SharedMaxOverride.HasValue ? (object)zone.SharedMaxOverride.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@enabled", zone.Enabled);
                    cmd.ExecuteNonQuery();
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

        public void SetZoneAssignmentsEnabled(IEnumerable<int> ids, bool enabled)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                foreach (var id in ids)
                {
                    using (var cmd = new NpgsqlCommand(@"
                        UPDATE gather_node_zones
                        SET enabled = @enabled
                        WHERE id = @id", conn))
                    {
                        cmd.Parameters.AddWithValue("@id", id);
                        cmd.Parameters.AddWithValue("@enabled", enabled);
                        cmd.ExecuteNonQuery();
                    }
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
                SpawnGroupId = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                SpawnGroupName = reader.IsDBNull(7) ? null : reader.GetString(7),
                WeightOverride = reader.IsDBNull(8) ? (int?)null : reader.GetInt32(8),
                MaxOverride = reader.IsDBNull(9) ? (int?)null : reader.GetInt32(9),
                SharedMaxOverride = reader.IsDBNull(10) ? (int?)null : reader.GetInt32(10),
                Enabled = reader.GetBoolean(11),
                CreatedAt = reader.GetDateTime(12)
            };
        }

        #endregion

        #region Spawn Point Groups

        public List<GatherSpawnPointGroup> GetAllSpawnPointGroups()
        {
            var groups = new List<GatherSpawnPointGroup>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, zone_id, zone_name, group_name, node_type, enabled, notes, created_at
                    FROM gather_spawn_point_groups
                    ORDER BY zone_id, group_name", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        groups.Add(MapToSpawnPointGroup(reader));
                    }
                }
            }

            return groups;
        }

        public List<GatherSpawnPointGroup> GetSpawnPointGroupsByZone(int zoneId, string nodeType = null)
        {
            var groups = new List<GatherSpawnPointGroup>();

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                var sql = @"
                    SELECT id, zone_id, zone_name, group_name, node_type, enabled, notes, created_at
                    FROM gather_spawn_point_groups
                    WHERE (zone_id = 0";

                if (zoneId > 0)
                {
                    sql += " OR zone_id = @zoneId";
                }

                sql += ")";

                if (!string.IsNullOrEmpty(nodeType))
                {
                    sql += " AND node_type IN (@nodeType, 'both')";
                }

                sql += " ORDER BY group_name";

                using (var cmd = new NpgsqlCommand(sql, conn))
                {
                    if (zoneId > 0)
                    {
                        cmd.Parameters.AddWithValue("@zoneId", zoneId);
                    }
                    if (!string.IsNullOrEmpty(nodeType))
                    {
                        cmd.Parameters.AddWithValue("@nodeType", nodeType);
                    }

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            groups.Add(MapToSpawnPointGroup(reader));
                        }
                    }
                }
            }

            return groups;
        }

        public int InsertSpawnPointGroup(GatherSpawnPointGroup group)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    INSERT INTO gather_spawn_point_groups
                    (zone_id, zone_name, group_name, node_type, enabled, notes)
                    VALUES (@zone_id, @zone_name, @group_name, @node_type, @enabled, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@zone_id", group.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", group.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@group_name", group.GroupName);
                    cmd.Parameters.AddWithValue("@node_type", group.NodeType);
                    cmd.Parameters.AddWithValue("@enabled", group.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrWhiteSpace(group.Notes) ? DBNull.Value : (object)group.Notes);
                    return (int)cmd.ExecuteScalar();
                }
            }
        }

        public void UpdateSpawnPointGroup(GatherSpawnPointGroup group)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    UPDATE gather_spawn_point_groups SET
                        zone_id = @zone_id,
                        zone_name = @zone_name,
                        group_name = @group_name,
                        node_type = @node_type,
                        enabled = @enabled,
                        notes = @notes
                    WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", group.Id);
                    cmd.Parameters.AddWithValue("@zone_id", group.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", group.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@group_name", group.GroupName);
                    cmd.Parameters.AddWithValue("@node_type", group.NodeType);
                    cmd.Parameters.AddWithValue("@enabled", group.Enabled);
                    cmd.Parameters.AddWithValue("@notes", string.IsNullOrWhiteSpace(group.Notes) ? DBNull.Value : (object)group.Notes);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public void DeleteSpawnPointGroup(int id)
        {
            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var clearPoints = new NpgsqlCommand("UPDATE gather_spawn_points SET spawn_group_id = NULL WHERE spawn_group_id = @id", conn))
                {
                    clearPoints.Parameters.AddWithValue("@id", id);
                    clearPoints.ExecuteNonQuery();
                }

                using (var clearZones = new NpgsqlCommand("UPDATE gather_node_zones SET spawn_group_id = NULL, spawn_mode = 'random' WHERE spawn_group_id = @id", conn))
                {
                    clearZones.Parameters.AddWithValue("@id", id);
                    clearZones.ExecuteNonQuery();
                }

                using (var cmd = new NpgsqlCommand("DELETE FROM gather_spawn_point_groups WHERE id = @id", conn))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private GatherSpawnPointGroup MapToSpawnPointGroup(NpgsqlDataReader reader)
        {
            return new GatherSpawnPointGroup
            {
                Id = reader.GetInt32(0),
                ZoneId = reader.GetInt32(1),
                ZoneName = reader.IsDBNull(2) ? null : reader.GetString(2),
                GroupName = reader.GetString(3),
                NodeType = reader.GetString(4),
                Enabled = reader.GetBoolean(5),
                Notes = reader.IsDBNull(6) ? null : reader.GetString(6),
                CreatedAt = reader.GetDateTime(7)
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
                    SELECT sp.id, sp.zone_id, sp.zone_name, sp.point_name, sp.region_variable, sp.node_type,
                           sp.spawn_group_id, g.group_name, sp.spawn_point_index, sp.enabled, sp.notes, sp.created_at
                    FROM gather_spawn_points sp
                    LEFT JOIN gather_spawn_point_groups g ON sp.spawn_group_id = g.id
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
                    SELECT sp.id, sp.zone_id, sp.zone_name, sp.point_name, sp.region_variable, sp.node_type,
                           sp.spawn_group_id, g.group_name, sp.spawn_point_index, sp.enabled, sp.notes, sp.created_at
                    FROM gather_spawn_points sp
                    LEFT JOIN gather_spawn_point_groups g ON sp.spawn_group_id = g.id
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
                    (zone_id, zone_name, point_name, region_variable, node_type, spawn_group_id, spawn_point_index, enabled, notes)
                    VALUES (@zone_id, @zone_name, @point_name, @region_variable, @node_type, @spawn_group_id, @spawn_point_index, @enabled, @notes)
                    RETURNING id", conn))
                {
                    cmd.Parameters.AddWithValue("@zone_id", point.ZoneId);
                    cmd.Parameters.AddWithValue("@zone_name", point.ZoneName ?? (object)DBNull.Value);
                    cmd.Parameters.AddWithValue("@point_name", point.PointName);
                    cmd.Parameters.AddWithValue("@region_variable", point.RegionVariable);
                    cmd.Parameters.AddWithValue("@node_type", point.NodeType);
                    cmd.Parameters.AddWithValue("@spawn_group_id", point.SpawnGroupId.HasValue ? (object)point.SpawnGroupId.Value : DBNull.Value);
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
                        spawn_group_id = @spawn_group_id,
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
                    cmd.Parameters.AddWithValue("@spawn_group_id", point.SpawnGroupId.HasValue ? (object)point.SpawnGroupId.Value : DBNull.Value);
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
                SpawnGroupId = reader.IsDBNull(6) ? (int?)null : reader.GetInt32(6),
                SpawnGroupName = reader.IsDBNull(7) ? null : reader.GetString(7),
                SpawnPointIndex = reader.IsDBNull(8) ? (int?)null : reader.GetInt32(8),
                Enabled = reader.GetBoolean(9),
                Notes = reader.IsDBNull(10) ? null : reader.GetString(10),
                CreatedAt = reader.GetDateTime(11)
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
                    SELECT hd.id,
                           COALESCE(db.item_code, hd.item_code) as item_code,
                           hd.item_name,
                           hd.category,
                           hd.description,
                           hd.suggested_respawn_min,
                           hd.suggested_respawn_max,
                           hd.suggested_skill,
                           hd.tier_level,
                           hd.display_order
                    FROM gather_herb_definitions hd
                    LEFT JOIN LATERAL (
                        SELECT i.item_code
                        FROM items i
                        WHERE LOWER(TRIM(i.item_name)) = LOWER(TRIM(hd.item_name))
                           OR LOWER(TRIM(i.item_code)) = LOWER(TRIM(hd.item_code))
                        ORDER BY CASE
                            WHEN LOWER(TRIM(i.item_name)) = LOWER(TRIM(hd.item_name)) THEN 0
                            ELSE 1
                        END,
                        i.id
                        LIMIT 1
                    ) db ON TRUE
                    ORDER BY hd.tier_level, hd.display_order, hd.item_name", conn))
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
                    SELECT vd.id,
                           COALESCE(db.unit_code, vd.unit_code) as unit_code,
                           vd.unit_name,
                           vd.category,
                           vd.description,
                           vd.suggested_glow_r,
                           vd.suggested_glow_g,
                           vd.suggested_glow_b,
                           vd.suggested_respawn_min,
                           vd.suggested_respawn_max,
                           vd.suggested_skill,
                           vd.tier_level,
                           vd.display_order
                    FROM gather_vein_definitions vd
                    LEFT JOIN LATERAL (
                        SELECT ut.unit_code
                        FROM unit_types ut
                        WHERE LOWER(TRIM(ut.unit_name)) = LOWER(TRIM(vd.unit_name))
                           OR LOWER(TRIM(
                                CASE
                                    WHEN COALESCE(ut.editor_suffix, '') = '' THEN ut.unit_name
                                    ELSE ut.unit_name || ' (' || ut.editor_suffix || ')'
                                END
                           )) = LOWER(TRIM(vd.unit_name))
                           OR LOWER(TRIM(ut.unit_code)) = LOWER(TRIM(vd.unit_code))
                        ORDER BY CASE
                            WHEN LOWER(TRIM(ut.unit_name)) = LOWER(TRIM(vd.unit_name)) THEN 0
                            WHEN LOWER(TRIM(
                                CASE
                                    WHEN COALESCE(ut.editor_suffix, '') = '' THEN ut.unit_name
                                    ELSE ut.unit_name || ' (' || ut.editor_suffix || ')'
                                END
                           )) = LOWER(TRIM(vd.unit_name)) THEN 1
                            ELSE 2
                        END,
                        ut.id
                        LIMIT 1
                    ) db ON TRUE
                    ORDER BY vd.tier_level, vd.display_order, vd.unit_name", conn))
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

        public DatabaseItemInfo GetDatabaseItemByCode(string itemCode)
        {
            if (string.IsNullOrWhiteSpace(itemCode))
            {
                return null;
            }

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT i.id, i.item_code, i.item_name,
                           COALESCE(it.type_name, 'Unknown') as type_name,
                           COALESCE(ir.rarity_name, 'Unknown') as rarity_name,
                           i.item_level
                    FROM items i
                    LEFT JOIN item_types it ON i.type_id = it.id
                    LEFT JOIN item_rarities ir ON i.rarity_id = ir.id
                    WHERE i.item_code = @itemCode
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@itemCode", itemCode);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new DatabaseItemInfo
                            {
                                Id = reader.GetInt32(0),
                                ItemCode = reader.GetString(1),
                                ItemName = reader.GetString(2),
                                TypeName = reader.GetString(3),
                                RarityName = reader.GetString(4),
                                ItemLevel = reader.IsDBNull(5) ? 1 : reader.GetInt32(5)
                            };
                        }
                    }
                }
            }

            return null;
        }

        public DatabaseItemInfo GetDatabaseItemByName(string itemName)
        {
            if (string.IsNullOrWhiteSpace(itemName))
            {
                return null;
            }

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT i.id, i.item_code, i.item_name,
                           COALESCE(it.type_name, 'Unknown') as type_name,
                           COALESCE(ir.rarity_name, 'Unknown') as rarity_name,
                           i.item_level
                    FROM items i
                    LEFT JOIN item_types it ON i.type_id = it.id
                    LEFT JOIN item_rarities ir ON i.rarity_id = ir.id
                    WHERE LOWER(TRIM(i.item_name)) = LOWER(TRIM(@itemName))
                    ORDER BY i.id
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@itemName", itemName.Trim());
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new DatabaseItemInfo
                            {
                                Id = reader.GetInt32(0),
                                ItemCode = reader.GetString(1),
                                ItemName = reader.GetString(2),
                                TypeName = reader.GetString(3),
                                RarityName = reader.GetString(4),
                                ItemLevel = reader.IsDBNull(5) ? 1 : reader.GetInt32(5)
                            };
                        }
                    }
                }
            }

            return null;
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

        public DatabaseUnitInfo GetDatabaseUnitTypeByCode(string unitCode)
        {
            if (string.IsNullOrWhiteSpace(unitCode))
            {
                return null;
            }

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, unit_code, unit_name, editor_suffix, unit_level, is_boss
                    FROM unit_types
                    WHERE unit_code = @unitCode
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@unitCode", unitCode);
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new DatabaseUnitInfo
                            {
                                Id = reader.GetInt32(0),
                                UnitCode = reader.GetString(1),
                                UnitName = reader.GetString(2),
                                EditorSuffix = reader.IsDBNull(3) ? null : reader.GetString(3),
                                UnitLevel = reader.IsDBNull(4) ? 1 : reader.GetInt32(4),
                                IsBoss = reader.IsDBNull(5) ? false : reader.GetBoolean(5)
                            };
                        }
                    }
                }
            }

            return null;
        }

        public DatabaseUnitInfo GetDatabaseUnitTypeByName(string unitName)
        {
            if (string.IsNullOrWhiteSpace(unitName))
            {
                return null;
            }

            using (var conn = new NpgsqlConnection(_connectionString))
            {
                conn.Open();
                using (var cmd = new NpgsqlCommand(@"
                    SELECT id, unit_code, unit_name, editor_suffix, unit_level, is_boss
                    FROM unit_types
                    WHERE LOWER(TRIM(unit_name)) = LOWER(TRIM(@unitName))
                       OR LOWER(TRIM(
                            CASE
                                WHEN COALESCE(editor_suffix, '') = '' THEN unit_name
                                ELSE unit_name || ' (' || editor_suffix || ')'
                            END
                       )) = LOWER(TRIM(@unitName))
                    ORDER BY CASE
                        WHEN LOWER(TRIM(unit_name)) = LOWER(TRIM(@unitName)) THEN 0
                        ELSE 1
                    END,
                    id
                    LIMIT 1", conn))
                {
                    cmd.Parameters.AddWithValue("@unitName", unitName.Trim());
                    using (var reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            return new DatabaseUnitInfo
                            {
                                Id = reader.GetInt32(0),
                                UnitCode = reader.GetString(1),
                                UnitName = reader.GetString(2),
                                EditorSuffix = reader.IsDBNull(3) ? null : reader.GetString(3),
                                UnitLevel = reader.IsDBNull(4) ? 1 : reader.GetInt32(4),
                                IsBoss = reader.IsDBNull(5) ? false : reader.GetBoolean(5)
                            };
                        }
                    }
                }
            }

            return null;
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
