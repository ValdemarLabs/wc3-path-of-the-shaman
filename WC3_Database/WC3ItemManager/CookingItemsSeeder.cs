using Npgsql;

namespace WC3ItemManager
{
    internal static class CookingItemsSeeder
    {
        private const string ConsumeAbility = "A0F5";

        private sealed class SeedItem
        {
            public string Code = "";
            public string Name = "";
            public string Rarity = "Common";
            public string ClassName = "Consumable";
            public string TypeName = "Consumable";
            public int Level;
            public int GoldCost;
            public int SellValue;
            public int MaxCharges = 1;
            public int MaxStack = 5;
            public string IconPath = "";
            public string ModelPath = "";
            public string Tooltip = "";
            public string TooltipExtended = "";
            public string Description = "";
            public string BaseId = "rej3";
            public string Wc3Classification = "Charged";
            public string Wc3Abilities = "";
            public bool ActivelyUsed = true;
            public bool CopyBaseAbilities;
        }

        private static readonly SeedItem[] Items =
        {
            Food("j0c6", "Smoked Wolf Jerky", "Uncommon", 1, 65, "+1 Agility, +1 hit point regeneration."),
            Food("j0c7", "Roasted Stag Haunch", "Uncommon", 3, 70, "+1 Strength, +50 maximum hit points."),
            Food("j0c8", "Bear Fat Biscuit", "Uncommon", 13, 85, "+2 Strength, +100 maximum hit points, +1 hit point regeneration."),
            Food("j0c9", "Boiled Makrura Claw", "Uncommon", 18, 90, "+2 Intelligence, +60 maximum mana, +1 mana regeneration."),
            Food("j0d0", "Spiced Snake Strips", "Uncommon", 8, 75, "+2 Agility, +1 Critical Chance."),
            Food("j0d1", "Fried Crawler Cake", "Uncommon", 22, 95, "+1 Armor, +1 Block, +1 hit point regeneration."),

            FishFood("j2b0", "Brilliant Smallfish", "Common", 1, 18, "+1 hit point regeneration, +25 maximum hit points."),
            FishFood("j2b1", "Slitherskin Mackerel", "Common", 5, 22, "+35 maximum mana, +1 mana regeneration."),
            Food("j2a0", "Charred Boar Ribs", "Common", 25, 90, "+3 Strength, +3 Damage."),
            FishFood("j2b2", "Mud Snapper Cake", "Common", 17, 60, "+75 maximum hit points, +1 Dodge."),
            Stew("j2a1", "Rabbit Broth", "Common", 27, 85, "+2 hit point regeneration, +1 Dodge, +40 maximum mana."),
            Food("j2a2", "Hawk Skewer", "Uncommon", 30, 105, "+3 Agility, +1 Hit, +4 Damage."),
            FishFood("j2b3", "Rainbow Albacore", "Uncommon", 32, 110, "+2 Agility, +2 Hit, +1 mana regeneration."),
            Stew("j2a3", "Turtle Stew", "Uncommon", 33, 125, "+2 Armor, +2 Block, +150 maximum hit points."),
            Stew("j2b4", "Catfish Chowder", "Uncommon", 37, 135, "+125 maximum hit points, +2 hit point regeneration, +1 Armor."),
            Stew("j2a4", "Murloc Fin Soup", "Uncommon", 40, 145, "+3 Intelligence, +90 maximum mana, +1 Spell Power."),
            FishFood("j2b5", "Loch Frenzy Delight", "Uncommon", 42, 145, "+2 Critical Chance, +2 Hit, +4 Damage."),
            Food("j2a5", "Lizard Pepper Roast", "Uncommon", 43, 150, "+3 Strength, +5 Damage, +1 Critical Chance."),
            Stew("j2b6", "Firefin Chili", "Uncommon", 47, 175, "+5 Spell Power, +2 Critical Chance, -1 Armor."),
            Food("j2a6", "Tiger Steak", "Uncommon", 50, 190, "+5 Agility, +2 Critical Chance, +7 Damage."),
            Stew("j2b7", "Sagefish Soup", "Uncommon", 52, 200, "+4 Intelligence, +2 mana regeneration, +5 Spell Power."),
            Food("j2a7", "Panther Fillet", "Uncommon", 55, 215, "+5 Agility, +2 Dodge, +12 movement speed."),
            FishFood("j2b9", "Rockscale Cod", "Uncommon", 57, 225, "+3 Armor, +2 Block, +100 maximum hit points."),
            Stew("j2a8", "Raptor Chili", "Rare", 60, 260, "+5 Strength, +8 Damage, +3 Critical Chance, -1 Hit."),
            FishFood("j2c0", "Mithril Head Trout", "Uncommon", 63, 250, "+3 Block, +2 Armor, +3 Hit."),
            Food("j2a9", "Cow Rump Roast", "Uncommon", 67, 280, "+4 Strength, +250 maximum hit points, +2 hit point regeneration."),
            FishFood("j2c1", "Spotted Yellowtail", "Uncommon", 68, 275, "+4 Agility, +3 Hit, +10 movement speed."),
            OddFood("j2d2", "Deviate Delight", "Rare", 72, 330, "+4 Agility, +3 Dodge, -2 Intelligence, +30 sight range."),
            FishFood("j2c2", "Glossy Mightfish Steak", "Rare", 75, 390, "+7 Strength, +12 Damage, +4 Critical Chance."),
            FishFood("j2c3", "Redgill Skillet", "Rare", 77, 405, "+4 Critical Chance, +5 Hit, +6 Damage."),
            Stew("j2c4", "Nightfin Soup", "Rare", 80, 440, "+3 mana regeneration, +10 Spell Power, +180 maximum mana."),
            FishFood("j2c5", "Sunscale Fillet", "Rare", 82, 450, "+4 hit point regeneration, +300 maximum hit points, +2 Armor."),
            FishFood("j2c6", "Stonescale Eel", "Rare", 83, 475, "+4 Armor, +5 Block, -8 movement speed."),
            FishFood("j2c7", "Whitescale Salmon", "Rare", 87, 520, "+5% Spell Power, +250 maximum mana, +4 Hit."),
            Stew("j2c8", "Darkclaw Bisque", "Rare", 90, 600, "+8 Strength, +300 maximum hit points, +4 Armor."),
            FishFood("j2c9", "Winter Squid", "Rare", 93, 650, "+8 Agility, +5 Critical Chance, +6 Dodge."),
            FishFood("j2d0", "Summer Bass", "Rare", 97, 675, "+20 movement speed, +5 Hit, +5 Dodge."),
            OddFood("j2d1", "Tigerseye Eel", "Rare", 100, 720, "+25 Spell Power, +5 Dodge, +5% Spell Power."),
            OddFood("j2d3", "Ember Whelp Roast", "Rare", 95, 700, "+20 Damage, +5% Spell Power, +5 Critical Chance, -2 Armor."),
            OddFood("j2d4", "Plaguebloom Dumpling", "Rare", 98, 730, "+8 Critical Chance, +8 Spell Power, +40 sight range, -2 hit point regeneration."),

            Beverage("j3a0", "Springwater Tea", "Common", 1, 25, "+25 maximum mana, +1 mana regeneration."),
            Beverage("j3a1", "Honeyed Milk", "Common", 7, 35, "+50 maximum hit points, -1 Intelligence."),
            Beverage("j3a2", "Bitter Cactus Ale", "Common", 15, 55, "+1 Strength, -2 Intelligence, -1 Armor."),
            Beverage("j3a3", "Stout Mead", "Uncommon", 25, 95, "+3 Strength, -2 Intelligence, -1 Armor."),
            Beverage("j3a4", "Salted Makrura Broth", "Uncommon", 30, 110, "+1 mana regeneration, +60 maximum mana, -1 Armor."),
            Beverage("j3a5", "Blackmouth Grog", "Uncommon", 40, 150, "+5 Damage, -2 Hit, -3 Intelligence."),
            Beverage("j3a6", "Firefin Whiskey", "Uncommon", 50, 210, "+3 Critical Chance, +6 Damage, -4 Intelligence, -2 Armor."),
            Beverage("j3a7", "Sagefish Tonic", "Uncommon", 58, 230, "+4 Intelligence, +1 mana regeneration, -1 Armor."),
            Beverage("j3a8", "Deviate Rum", "Rare", 67, 310, "+5 Dodge, -5 Hit, +20 sight range, -4 Intelligence."),
            Beverage("j3a9", "Nightfin Wine", "Rare", 75, 380, "+15 Spell Power, -20 movement speed, -2 Armor."),
            Beverage("j3b0", "Stonescale Porter", "Rare", 83, 430, "+4 Armor, +4 Block, -4 Agility."),
            Beverage("j3b1", "Lobster Bisque Cup", "Rare", 90, 500, "+200 maximum hit points, +2 hit point regeneration, -3 Intelligence."),
            Beverage("j3b2", "Dragonfire Punch", "Rare", 95, 620, "+20 Damage, +5 Critical Chance, -5 Intelligence, -4 Armor."),
            Beverage("j3b3", "Winter Squid Absinthe", "Rare", 98, 680, "+10% Spell Power, +10 Spell Power, -5 Hit, -6 Intelligence."),
            Beverage("j3b4", "Brew of Bad Ideas", "Rare", 100, 750, "+10 Critical Chance, +10 Damage, -10 Intelligence, -5 Dodge, -5 Armor."),

            Material("j4a0", "Coarse Flour", 5, 20, "Ground grain for biscuits, cakes, and dumplings."),
            Material("j4a1", "Honey", 5, 35, "Sweetener used in roasts, mead, and glazes."),
            Material("j4a2", "Peppercorn", 10, 45, "Sharp seasoning used in higher cooking recipes."),
            Material("j4a3", "Baker's Yeast", 10, 40, "Fermentation starter for breads and beverages."),
            Material("j4a4", "Bitter Hops", 25, 55, "Bitter flowers used in ales and strong drinks."),
            Material("j4a5", "Cactus Pulp", 30, 60, "Dry pulp with a hot, green bite."),
            Material("j4a6", "Sour Berries", 40, 65, "Acidic berries used to cut heavy fish oils."),
            Material("j4a7", "Glowcap", 80, 120, "A faintly luminous mushroom for odd recipes."),
            Material("j4a8", "Icecap Shavings", 120, 180, "Cold herbal flakes used in advanced seafood and drinks."),
            Material("j4a9", "Empty Bottle", 1, 10, "A clean bottle for prepared beverages.")
        };

        public static void Ensure(NpgsqlConnection conn)
        {
            EnsureColumns(conn);
            EnsureLookupRows(conn);
            EnsureConsumeAbility(conn);

            foreach (var item in Items)
            {
                UpsertItem(conn, item);
            }
        }

        private static SeedItem Food(string code, string name, string rarity, int level, int goldCost, string effectText)
        {
            return Consumable(code, name, rarity, level, goldCost, effectText, "Food", "rej3", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "war3campImported\\ITEMMonsterLure.mdl");
        }

        private static SeedItem FishFood(string code, string name, string rarity, int level, int goldCost, string effectText)
        {
            return Consumable(code, name, rarity, level, goldCost, effectText, "Food", "rej3", "ReplaceableTextures\\CommandButtons\\BTNMonsterLure.blp", "war3campImported\\ITEMMonsterLure.mdl");
        }

        private static SeedItem Stew(string code, string name, string rarity, int level, int goldCost, string effectText)
        {
            return Consumable(code, name, rarity, level, goldCost, effectText, "Food", "rej3", "ReplaceableTextures\\CommandButtons\\BTNPotionGreenSmall.blp", "war3campImported\\ITEMPotionGreenSmall.mdl");
        }

        private static SeedItem OddFood(string code, string name, string rarity, int level, int goldCost, string effectText)
        {
            return Consumable(code, name, rarity, level, goldCost, effectText, "Food", "rej3", "ReplaceableTextures\\CommandButtons\\BTNOrbOfCorruption.blp", "war3campImported\\ITEMMonsterLure.mdl");
        }

        private static SeedItem Beverage(string code, string name, string rarity, int level, int goldCost, string effectText)
        {
            return Consumable(code, name, rarity, level, goldCost, effectText, "Beverage", "pclr", "ReplaceableTextures\\CommandButtons\\BTNPotionBlueSmall.blp", "war3campImported\\ITEMPotionGreenSmall.mdl");
        }

        private static SeedItem Consumable(string code, string name, string rarity, int level, int goldCost, string effectText, string kind, string baseId, string iconPath, string modelPath)
        {
            string extended = $"|cff87CEEB{kind}|r|nCooking applies for a limited time: {effectText}";
            return new SeedItem
            {
                Code = code,
                Name = name,
                Rarity = rarity,
                ClassName = "Consumable",
                TypeName = "Consumable",
                Level = level,
                GoldCost = goldCost,
                SellValue = System.Math.Max(1, goldCost / 5),
                MaxCharges = 1,
                MaxStack = 5,
                IconPath = iconPath,
                ModelPath = modelPath,
                Tooltip = name,
                TooltipExtended = extended,
                Description = extended,
                BaseId = baseId,
                Wc3Classification = "Charged",
                Wc3Abilities = ConsumeAbility,
                ActivelyUsed = true,
                CopyBaseAbilities = false
            };
        }

        private static SeedItem Material(string code, string name, int level, int goldCost, string description)
        {
            string extended = "|cffC0C0C0Material|r|n" + description;
            return new SeedItem
            {
                Code = code,
                Name = name,
                Rarity = "Common",
                ClassName = "Material",
                TypeName = "Material",
                Level = level,
                GoldCost = goldCost,
                SellValue = System.Math.Max(1, goldCost / 5),
                MaxCharges = 1,
                MaxStack = 49,
                IconPath = "ReplaceableTextures\\CommandButtons\\BTNTrueShot.blp",
                Tooltip = name,
                TooltipExtended = extended,
                Description = extended,
                BaseId = "phea",
                Wc3Classification = "Charged",
                Wc3Abilities = "",
                ActivelyUsed = false,
                CopyBaseAbilities = false
            };
        }

        private static void EnsureColumns(NpgsqlConnection conn)
        {
            const string query = @"
                ALTER TABLE items ADD COLUMN IF NOT EXISTS item_level_unclassified INTEGER;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS specific_drop_only BOOLEAN DEFAULT FALSE;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS copy_base_abilities BOOLEAN DEFAULT FALSE;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS actively_used BOOLEAN;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS dropped_on_death BOOLEAN;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_abilities TEXT;
                ALTER TABLE items ADD COLUMN IF NOT EXISTS tooltip_extended TEXT;";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.ExecuteNonQuery();
            }
        }

        private static void EnsureLookupRows(NpgsqlConnection conn)
        {
            EnsureRarity(conn, "Common", 0, "#9D9D9D", 1.00m, "Common quality items");
            EnsureRarity(conn, "Uncommon", 1, "#1EFF00", 1.50m, "Uncommon quality items");
            EnsureRarity(conn, "Rare", 2, "#0070DD", 2.00m, "Rare quality items");
            EnsureClass(conn, "Consumable", "CONSUMABLE", "Food, drinks, potions, and other used items");
            EnsureClass(conn, "Material", "MATERIAL", "Crafting materials");
            EnsureType(conn, "Consumable");
            EnsureType(conn, "Material");
        }

        private static void EnsureConsumeAbility(NpgsqlConnection conn)
        {
            const string query = @"
                INSERT INTO wc3_abilities (ability_code, ability_name, tooltip_normal, tooltip_extended)
                VALUES (@code, 'Eat/Drink', 'Eat/Drink', 'Consumes one food or beverage charge. Cooking applies the configured timed effect.')
                ON CONFLICT (ability_code) DO UPDATE SET
                    ability_name = EXCLUDED.ability_name,
                    tooltip_normal = EXCLUDED.tooltip_normal,
                    tooltip_extended = EXCLUDED.tooltip_extended,
                    updated_at = CURRENT_TIMESTAMP;";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("code", ConsumeAbility);
                cmd.ExecuteNonQuery();
            }
        }

        private static void EnsureRarity(NpgsqlConnection conn, string name, int level, string colorCode, decimal multiplier, string description)
        {
            const string query = @"
                INSERT INTO item_rarities (rarity_name, rarity_level, color_code, gold_multiplier, description)
                SELECT @name, @level, @color, @multiplier, @description
                WHERE NOT EXISTS (SELECT 1 FROM item_rarities WHERE rarity_name = @name);";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("name", name);
                cmd.Parameters.AddWithValue("level", level);
                cmd.Parameters.AddWithValue("color", colorCode);
                cmd.Parameters.AddWithValue("multiplier", multiplier);
                cmd.Parameters.AddWithValue("description", description);
                cmd.ExecuteNonQuery();
            }
        }

        private static void EnsureClass(NpgsqlConnection conn, string name, string slotType, string description)
        {
            const string query = @"
                INSERT INTO item_classes (class_name, slot_type, description)
                SELECT @name, @slot_type, @description
                WHERE NOT EXISTS (SELECT 1 FROM item_classes WHERE class_name = @name);";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("name", name);
                cmd.Parameters.AddWithValue("slot_type", slotType);
                cmd.Parameters.AddWithValue("description", description);
                cmd.ExecuteNonQuery();
            }
        }

        private static void EnsureType(NpgsqlConnection conn, string name)
        {
            const string query = @"
                INSERT INTO item_types (type_name)
                SELECT @name
                WHERE NOT EXISTS (SELECT 1 FROM item_types WHERE type_name = @name);";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("name", name);
                cmd.ExecuteNonQuery();
            }
        }

        private static int GetLookupId(NpgsqlConnection conn, string tableName, string idColumn, string nameColumn, string name)
        {
            string query = $"SELECT {idColumn} FROM {tableName} WHERE {nameColumn} = @name";
            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("name", name);
                object result = cmd.ExecuteScalar();
                if (result == null || result == System.DBNull.Value)
                {
                    throw new System.InvalidOperationException($"Missing lookup row {tableName}.{nameColumn} = {name}");
                }
                return System.Convert.ToInt32(result);
            }
        }

        private static void UpsertItem(NpgsqlConnection conn, SeedItem item)
        {
            int rarityId = GetLookupId(conn, "item_rarities", "id", "rarity_name", item.Rarity);
            int classId = GetLookupId(conn, "item_classes", "id", "class_name", item.ClassName);
            int typeId = GetLookupId(conn, "item_types", "id", "type_name", item.TypeName);

            const string query = @"
                INSERT INTO items (
                    item_code, item_name, base_id, rarity_id, class_id, type_id,
                    item_level, item_level_unclassified, required_level,
                    gold_cost, sell_value, max_charges, max_stack,
                    tooltip, tooltip_extended, description,
                    icon_path, model_path, wc3_abilities, wc3_classification,
                    is_powerup, use_automatically, is_droppable, is_sellable, is_pawnable,
                    actively_used, dropped_on_death, specific_drop_only, copy_base_abilities,
                    updated_at
                ) VALUES (
                    @item_code, @item_name, @base_id, @rarity_id, @class_id, @type_id,
                    @item_level, @item_level_unclassified, @required_level,
                    @gold_cost, @sell_value, @max_charges, @max_stack,
                    @tooltip, @tooltip_extended, @description,
                    @icon_path, @model_path, @wc3_abilities, @wc3_classification,
                    FALSE, FALSE, TRUE, TRUE, TRUE,
                    @actively_used, FALSE, FALSE, @copy_base_abilities,
                    CURRENT_TIMESTAMP
                )
                ON CONFLICT (item_code) DO NOTHING;";

            using (var cmd = new NpgsqlCommand(query, conn))
            {
                cmd.Parameters.AddWithValue("item_code", item.Code);
                cmd.Parameters.AddWithValue("item_name", GetColoredName(item.Name, item.Rarity));
                cmd.Parameters.AddWithValue("base_id", item.BaseId);
                cmd.Parameters.AddWithValue("rarity_id", rarityId);
                cmd.Parameters.AddWithValue("class_id", classId);
                cmd.Parameters.AddWithValue("type_id", typeId);
                cmd.Parameters.AddWithValue("item_level", GetWc3ItemLevel(item));
                cmd.Parameters.AddWithValue("item_level_unclassified", item.Level);
                cmd.Parameters.AddWithValue("required_level", 1);
                cmd.Parameters.AddWithValue("gold_cost", item.GoldCost);
                cmd.Parameters.AddWithValue("sell_value", item.SellValue);
                cmd.Parameters.AddWithValue("max_charges", item.MaxCharges);
                cmd.Parameters.AddWithValue("max_stack", item.MaxStack);
                cmd.Parameters.AddWithValue("tooltip", item.Tooltip);
                cmd.Parameters.AddWithValue("tooltip_extended", item.TooltipExtended);
                cmd.Parameters.AddWithValue("description", item.Description);
                cmd.Parameters.AddWithValue("icon_path", item.IconPath);
                cmd.Parameters.AddWithValue("model_path", item.ModelPath);
                cmd.Parameters.AddWithValue("wc3_abilities", item.Wc3Abilities);
                cmd.Parameters.AddWithValue("wc3_classification", item.Wc3Classification);
                cmd.Parameters.AddWithValue("actively_used", item.ActivelyUsed);
                cmd.Parameters.AddWithValue("copy_base_abilities", item.CopyBaseAbilities);
                cmd.ExecuteNonQuery();
            }
        }

        private static int GetWc3ItemLevel(SeedItem item)
        {
            if (item.ClassName == "Consumable" || item.ClassName == "Material")
            {
                if (item.MaxStack <= 0)
                {
                    return 0;
                }

                return System.Math.Min(item.MaxStack, 49);
            }

            return item.Level;
        }

        private static string GetColoredName(string name, string rarity)
        {
            switch (rarity)
            {
                case "Uncommon":
                    return "|cFF1EFF00" + name + "|r";
                case "Rare":
                    return "|cFF0070DD" + name + "|r";
                default:
                    return "|cFFFFFFFF" + name + "|r";
            }
        }
    }
}
