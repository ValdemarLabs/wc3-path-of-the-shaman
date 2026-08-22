using Npgsql;

namespace WC3ItemManager
{
    // Historical one-time development seeder. This file is excluded from the normal build;
    // run it only when intentionally preparing a development database.
    internal static class ProfessionItemStatsSeeder
    {
        public static void RunOnce(NpgsqlConnection conn)
        {
            const string seedQuery = @"
                INSERT INTO item_stats (id, stat_code, stat_name, stat_description, display_format, color_hex, display_order, is_active)
                VALUES
                    (39, 'healing_power', 'Healing Power', 'Healing effectiveness percentage', '+{value}%', '#7CFC00', 39, TRUE),
                    (40, 'profession_mining', 'Mining', 'Mining profession skill bonus', '+{value}', '#B8860B', 40, TRUE),
                    (41, 'profession_herbalism', 'Herbalism', 'Herbalism profession skill bonus', '+{value}', '#32CD32', 41, TRUE),
                    (42, 'profession_skinning', 'Skinning', 'Skinning profession skill bonus', '+{value}', '#CD853F', 42, TRUE),
                    (43, 'profession_fishing', 'Fishing', 'Fishing profession skill bonus', '+{value}', '#40C7EB', 43, TRUE),
                    (44, 'profession_alchemy', 'Alchemy', 'Alchemy profession skill bonus', '+{value}', '#9370DB', 44, TRUE),
                    (45, 'profession_blacksmithing', 'Blacksmithing', 'Blacksmithing profession skill bonus', '+{value}', '#708090', 45, TRUE),
                    (46, 'profession_leatherworking', 'Leatherworking', 'Leatherworking profession skill bonus', '+{value}', '#8B4513', 46, TRUE),
                    (47, 'profession_enchanting', 'Enchanting', 'Enchanting profession skill bonus', '+{value}', '#DA70D6', 47, TRUE),
                    (48, 'profession_cooking', 'Cooking', 'Cooking profession skill bonus', '+{value}', '#FF8C00', 48, TRUE),
                    (49, 'drunk', 'Drunk', 'Intoxication added when consumed', '+{value}', '#DDA0DD', 49, TRUE)
                ON CONFLICT DO NOTHING;

                SELECT setval('item_stats_id_seq', GREATEST((SELECT COALESCE(MAX(id), 1) FROM item_stats), 49), true);";

            using (var cmd = new NpgsqlCommand(seedQuery, conn))
            {
                cmd.ExecuteNonQuery();
            }
        }
    }
}
