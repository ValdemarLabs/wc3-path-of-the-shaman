/**
    DEquipmentItemDefinitions

    Author: Valdemar
    Version:

    Description:
    Auto-generated PotS item definitions for DEquipment.

    Credits:
    - WC3ItemManager database export

    How to install:
    Import after DEquipment and regenerate after equipment database changes.

    API:
    - Registers exported item definitions during map initialization.

**/
library DEquipmentItemDefinitions initializer Init requires DEquipment

function DEqPreDefineItemsHere takes nothing returns nothing
    // Auto-generated from WC3 Item Database
    // Generated: 2026-08-22 11:05:24
    // Total items: 955

    // |c000080FFAncient Janggo of Endurance|r (Rare)
    // Base: ajen, Class: MISC

    // Unknown Item (ankh) (Common)
    // Base: ankh, Class: MISC

    // Unknown Item (arsc) (Common)
    // Base: arsc, Class: MISC

    // Unknown Item (asbl) (Common)
    // Base: asbl, Class: MISC
    call DEqItemTypeDefineGoldValue('asbl', 5000)

    // Unknown Item (belv) (Common)
    // Base: belv, Class: MISC

    // |c0090EE90Belt of Giant Strength|r (Uncommon)
    // Base: bgst, Class: MISC

    // |c000080FFBoots of Speed|r (Rare)
    // Base: bspd, Class: MISC

    // Unknown Item (clfm) (Common)
    // Base: clfm, Class: MISC

    // Unknown Item (clsd) (Common)
    // Base: clsd, Class: MISC

    // |c0090EE90Circlet of Nobility|r (Uncommon)
    // Base: cnob, Class: MISC

    // Unknown Item (fgsk) (Common)
    // Base: fgsk, Class: MISC

    // Unknown Item (frgd) (Common)
    // Base: frgd, Class: MISC
    call DEqItemTypeDefineGoldValue('frgd', 5000)

    // Unknown Item (frhg) (Common)
    // Base: frhg, Class: MISC
    call DEqItemTypeDefineGoldValue('frhg', 5000)

    // Unknown Item (gcel) (Common)
    // Base: gcel, Class: MISC

    // Unknown Item (gobm) (Common)
    // Base: gobm, Class: MISC
    call DEqItemTypeDefineGoldValue('gobm', 250)

    // Unknown Item (hbth) (Common)
    // Base: hbth, Class: MISC
    call DEqItemTypeDefineGoldValue('hbth', 7000)

    // |c00A9A9A9Hood of Cunning|r (Common)
    // Base: hcun, Class: MISC

    // Unknown Item (hlst) (Common)
    // Base: hlst, Class: MISC

    // Unknown Item (hslv) (Common)
    // Base: hslv, Class: MISC
    call DEqItemTypeDefineGoldValue('hslv', 50)

    // |c00A9A9A9Helm of Valor|r (Common)
    // Base: hval, Class: MISC

    // Scout's Report (Common)
    // Base: mort, Class: MISC

    // Earth Crystal (Common)
    // Base: bzbe, Class: MISC

    // Fire Crystal (Common)
    // Base: bzbe, Class: MISC

    // Water Crystal (Common)
    // Base: bzbe, Class: MISC

    // Wind Crystal (Common)
    // Base: bzbe, Class: MISC

    // Blue Crystal (Common)
    // Base: phea, Class: MISC

    // Red Crystal (Common)
    // Base: phea, Class: MISC

    // Yellow Crystal (Common)
    // Base: phea, Class: MISC

    // Green Crystal (Common)
    // Base: phea, Class: MISC

    // Spirit Link (Common)
    // Base: tdex, Class: MISC

    // Wind Shear (Common)
    // Base: tdex, Class: MISC

    // |cFF0070DDSpirit Shard|r (Rare)
    // Base: fgrg, Class: Consumable
    call DEqItemTypeDefineGoldValue('I00C', 1000)
    call DEqItemTypeDefineAbilityGranted('I00C', 'A0F4', 1)

    // Frost Protection Potion (Common)
    // Base: pgma, Class: MISC

    // Cannonballs (Common)
    // Base: bzbe, Class: MISC

    // Barrel of Explosives (Common)
    // Base: bzbe, Class: MISC

    // Dustfilter 9000-BA (Common)
    // Base: bzbe, Class: MISC

    // Vent-o-Matic Blower R200 (Common)
    // Base: bzbe, Class: MISC

    // Dust Collector M25 (Common)
    // Base: bzbe, Class: MISC

    // The One Ring (Common)
    // Base: rde4, Class: MISC
    call DEqItemTypeDefineGoldValue('I00J', 5000)
    call DEqItemTypeDefineAbilityGranted('I00J', 'A035', 1)
    call DEqItemTypeDefineAbilityGranted('I00J', 'AIi6', 1)

    // |c0090EE90Medal of Honor|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I00K', 'AIi6', 1)
    call DEqItemTypeDefineAbilityGranted('I00K', 'AIs6', 1)

    // Old Sandwich (Common)
    // Base: bzbe, Class: MISC

    // Kribug's Satchel (Common)
    // Base: bzbe, Class: MISC

    // Gutcleanser Elixir (Common)
    // Base: bzbe, Class: MISC

    // Shovel (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I00O', 'A038', 1)
    call DEqItemTypeDefineAbilityGranted('I00O', 'A02M', 1)

    // Dragon Egg (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I00P', 300)

    // |cFFFFFFFFBird Egg|r (Common)
    // Base: bzbe, Class: Material
    // Rawcode aliases: 'i00q', 'I00Q'
    call DEqItemTypeDefineGoldValue('i00q', 100)
    call DEqItemTypeDefineGoldValue('I00Q', 100)

    // Raptor Egg (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I00Q', 300)

    // Chimaera Egg (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I00R', 300)

    // Whelp Scale (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I00S', 200)

    // |cff0000ffScale of Mordrax|r (Common)
    // Base: phea, Class: MISC

    // |cff6f2583Dragonslayer's Sword|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I00U', 5000)
    call DEqItemTypeDefineAbilityGranted('I00U', 'A65B', 1)
    call DEqItemTypeDefineAbilityGranted('I00U', 'AItf', 1)
    call DEqItemTypeDefineAbilityGranted('I00U', 'A64V', 1)
    call DEqItemTypeDefineAbilityGranted('I00U', 'A669', 1)

    // Small Flame Sac (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I00V', 200)

    // Ruined Dragonhide (Common)
    // Base: rst1, Class: MISC

    // Sharp Claw (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I00X', 50)

    // Mana Crystal (Common)
    // Base: phea, Class: MISC

    // |cff0000ffHeart of the Ocean|r (Common)
    // Base: ches, Class: MISC

    // Supplies (Common)
    // Base: bzbe, Class: MISC

    // Wraith Essence (Common)
    // Base: bzbe, Class: MISC

    // |cFFFFFFFFSafety Instructions|r (Common)
    // Base: jpnt, Class: Quest

    // |c001EFF00Tel’anor Rod|r (Uncommon)
    // Base: crys, Class: Quest
    call DEqItemTypeDefineAbilityGranted('I013', 'A04W', 1)

    // Small Bag (Common)
    // Base: tdex, Class: MISC

    // Medium Bag (Common)
    // Base: tdex, Class: MISC

    // Large Bag (Common)
    // Base: tdex, Class: MISC

    // item_objectcomponents_shield_buckler_damaged_a_01 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I017', 'A05N', 1)

    // item_objectcomponents_shield_buckler_damaged_a_02 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I018', 'A05O', 1)

    // item_objectcomponents_shield_buckler_oval_a_01 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I019', 'A05P', 1)

    // item_objectcomponents_shield_buckler_round_a_01 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01A', 'A05Q', 1)

    // item_objectcomponents_shield_shield_ahnqiraj_d_01 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01B', 'A05R', 1)

    // item_objectcomponents_shield_buckler_damaged_a_01_test (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01C', 'A06J', 1)

    // item_objectcomponents_shield_buckler_damaged_a_01a (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01D', 'A05N', 1)

    // item_objectcomponents_shield_buckler_damaged_a_01b (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01E', 'A06K', 1)

    // item_objectcomponents_shield_buckler_damaged_a_01c (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I01F', 'A06L', 1)

    // |c00FFFFFFReliable Belt|r (Common)
    // Base: sor4, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i0a7', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i0a7', "Agility", 13)
    call DEqItemTypeDefineStatGrantedByName('i0a7', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('i0a7', "Hitpoints", 57)
    call DEqItemTypeDefineGoldValue('i0a7', 4500)
    call DEqItemTypeDefineAbilityGranted('i0a7', 'A06G', 1)

    // |cFF1EFF00TEST Solid Ring of Power|r (Uncommon)
    // Base: afac, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('i0a8', 8)
    call DEqItemTypeDefineAllowedSlotId('i0a8', 9)
    call DEqItemTypeDefineStatGrantedByName('i0a8', "Agility", 13)
    call DEqItemTypeDefineStatGrantedByName('i0a8', "Intelligence", 13)
    call DEqItemTypeDefineStatGrantedByName('i0a8', "Lifesteal Pct", 0.13)
    call DEqItemTypeDefineStatGrantedByName('i0a8', "Strength", 13)
    call DEqItemTypeDefineGoldValue('i0a8', 15250)

    // |c001EFF00TEST Sturdy Shoulders of Power|r (Uncommon)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('i0a9', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('i0a9', "Armor", 6)
    call DEqItemTypeDefineStatGrantedByName('i0a9', "Hitpoints", 63)
    call DEqItemTypeDefineStatGrantedByName('i0a9', "Intelligence", 14)
    call DEqItemTypeDefineGoldValue('i0a9', 5250)

    // |c001EFF00TEST Sturdy Blade of the Eagle|r (Uncommon)
    // Base: rspd, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotId('i0b0', 19)
    call DEqItemTypeDefineAs2Handed('i0b0')
    call DEqItemTypeDefineStatGrantedByName('i0b0', "Agility", 26)
    call DEqItemTypeDefineStatGrantedByName('i0b0', "Armor", 11)
    call DEqItemTypeDefineStatGrantedByName('i0b0', "Hitpoints", 113)
    call DEqItemTypeDefineGoldValue('i0b0', 19000)

    // |c001EFF00TEST Reliable Foot of Swiftness|r (Uncommon)
    // Base: ward, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('i0b1', "Boots")
    call DEqItemTypeDefineStatGrantedByName('i0b1', "Armor", 9)
    call DEqItemTypeDefineStatGrantedByName('i0b1', "Hitpoints", 95)
    call DEqItemTypeDefineStatGrantedByName('i0b1', "Strength", 22)
    call DEqItemTypeDefineGoldValue('i0b1', 14000)

    // |c00FFFFFFQuality reserved_4 of Protection|r (Common)
    // Base: gold, Class: reserved_4
    call DEqItemTypeDefineStatGrantedByName('i0b2', "Agility", 4)
    call DEqItemTypeDefineStatGrantedByName('i0b2', "Hitpoints", 24)
    call DEqItemTypeDefineStatGrantedByName('i0b2', "Strength", 4)
    call DEqItemTypeDefineGoldValue('i0b2', 1230)

    // |c00FF8000Test Solid Shoulders of Apocalypse|r (Legendary)
    // Base: sman, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('i0b3', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('i0b3', "Armor", 19)
    call DEqItemTypeDefineStatGrantedByName('i0b3', "Hitpoints", 199)
    call DEqItemTypeDefineStatGrantedByName('i0b3', "Hitpoint regeneration", 13)
    call DEqItemTypeDefineStatGrantedByName('i0b3', "Strength", 46)
    call DEqItemTypeDefineGoldValue('i0b3', 48000)

    // |c00FF8000Sturdy Weapon of the Warrior|r (Legendary)
    // Base: ssil, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotId('i0b4', 19)
    call DEqItemTypeDefineAs2Handed('i0b4')
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Agility", 10)
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Cleave Pct", 0.05)
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Hitpoints", 44)
    call DEqItemTypeDefineStatGrantedByName('i0b4', "Sight Range", 6)
    call DEqItemTypeDefineGoldValue('i0b4', 2420)

    // |c000070DDReliable Neck of the Titan|r (Rare)
    // Base: ssil, Class: Neck
    call DEqItemTypeDefineAllowedSlotByName('i0b5', "Neck")
    call DEqItemTypeDefineStatGrantedByName('i0b5', "Agility", 10)
    call DEqItemTypeDefineStatGrantedByName('i0b5', "Critical Chance", 1)
    call DEqItemTypeDefineStatGrantedByName('i0b5', "Intelligence", 10)
    call DEqItemTypeDefineStatGrantedByName('i0b5', "Strength", 10)
    call DEqItemTypeDefineGoldValue('i0b5', 8500)

    // |c001EFF00Reliable reserved_1 of Power|r (Uncommon)
    // Base: gold, Class: reserved_1
    call DEqItemTypeDefineStatGrantedByName('i0b6', "Agility", 7)
    call DEqItemTypeDefineStatGrantedByName('i0b6', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0b6', "Hitpoints", 38)
    call DEqItemTypeDefineStatGrantedByName('i0b6', "Strength", 7)
    call DEqItemTypeDefineGoldValue('i0b6', 3400)

    // |c00A335EEQuality Belt of the Ancients|r (Epic)
    // Base: tagi, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i0b7', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i0b7', "Armor", 17)
    call DEqItemTypeDefineStatGrantedByName('i0b7', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0b7', "Hitpoints", 176)
    call DEqItemTypeDefineStatGrantedByName('i0b7', "Movement Speed", 11)
    call DEqItemTypeDefineStatGrantedByName('i0b7', "Strength", 41)
    call DEqItemTypeDefineGoldValue('i0b7', 48000)

    // |c00FF8000Solid Neck of Creation|r (Legendary)
    // Base: stel, Class: Neck
    call DEqItemTypeDefineAllowedSlotByName('i0b8', "Neck")
    call DEqItemTypeDefineStatGrantedByName('i0b8', "Agility", 24)
    call DEqItemTypeDefineStatGrantedByName('i0b8', "Critical Chance", 25)
    call DEqItemTypeDefineStatGrantedByName('i0b8', "Intelligence", 24)
    call DEqItemTypeDefineStatGrantedByName('i0b8', "Movement Speed", 12)
    call DEqItemTypeDefineStatGrantedByName('i0b8', "Strength", 24)
    call DEqItemTypeDefineGoldValue('i0b8', 38000)

    // |c001EFF00Sturdy Stave of the Bear|r (Uncommon)
    // Base: rej1, Class: Stave
    call DEqItemTypeDefineAllowedSlotId('i0b9', 19)
    call DEqItemTypeDefineAs2Handed('i0b9')
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Attack Speed", 0.15)
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Damage", 39)
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Dodge", 1)
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Hit Chance", 35)
    call DEqItemTypeDefineStatGrantedByName('i0b9', "Intelligence", 27)
    call DEqItemTypeDefineGoldValue('i0b9', 20250)

    // |c001EFF00Reliable Blade of the Bear|r (Uncommon)
    // Base: very, Class: Off Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('i0c0', "OffHand")
    call DEqItemTypeDefineStatGrantedByName('i0c0', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c0', "Hitpoints", 58)
    call DEqItemTypeDefineStatGrantedByName('i0c0', "Strength", 13)
    call DEqItemTypeDefineGoldValue('i0c0', 3825)

    // |c00FFFFFFFine Chest of Strength|r (Common)
    // Base: sor5, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0c1', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0c1', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('i0c1', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c1', "Hitpoints", 48)
    call DEqItemTypeDefineStatGrantedByName('i0c1', "Hit Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c1', "Strength", 12)
    call DEqItemTypeDefineGoldValue('i0c1', 3000)

    // |c00A335EESturdy Stave of Eternity|r (Epic)
    // Base: rej4, Class: Stave
    call DEqItemTypeDefineAllowedSlotId('i0c2', 19)
    call DEqItemTypeDefineAs2Handed('i0c2')
    call DEqItemTypeDefineStatGrantedByName('i0c2', "Attack Speed", 0.31)
    call DEqItemTypeDefineStatGrantedByName('i0c2', "Damage", 79)
    call DEqItemTypeDefineStatGrantedByName('i0c2', "Hit Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c2', "Intelligence", 55)
    call DEqItemTypeDefineStatGrantedByName('i0c2', "Movement Speed", 15)
    call DEqItemTypeDefineGoldValue('i0c2', 83000)

    // |c000070DDQuality Weapon of Legends|r (Rare)
    // Base: tkno, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotId('i0c3', 19)
    call DEqItemTypeDefineAs2Handed('i0c3')
    call DEqItemTypeDefineStatGrantedByName('i0c3', "Armor", 15)
    call DEqItemTypeDefineStatGrantedByName('i0c3', "Hitpoints", 152)
    call DEqItemTypeDefineStatGrantedByName('i0c3', "Strength", 35)
    call DEqItemTypeDefineGoldValue('i0c3', 38500)

    // |c000070DDSturdy Axe of the Phoenix|r (Rare)
    // Base: bspd, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i0c4', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('i0c4', "Agility", 10)
    call DEqItemTypeDefineStatGrantedByName('i0c4', "Intelligence", 10)
    call DEqItemTypeDefineStatGrantedByName('i0c4', "Strength", 10)
    call DEqItemTypeDefineGoldValue('i0c4', 7250)

    // |c001EFF00Sturdy Other of the Bear|r (Uncommon)
    // Base: afac, Class: Other
    call DEqItemTypeDefineStatGrantedByName('i0c5', "Agility", 8)
    call DEqItemTypeDefineStatGrantedByName('i0c5', "Hit Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c5', "Strength", 8)
    call DEqItemTypeDefineGoldValue('i0c5', 4875)
    call DEqItemTypeDefineAbilityGranted('i0c5', 'Albx', 1)

    // |c000070DDSturdy Chest of the Warrior|r (Rare)
    // Base: phea, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0c6', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0c6', "Hit Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c6', "Strength", 10)
    call DEqItemTypeDefineGoldValue('i0c6', 3000)

    // |c001EFF00Fine 1h of the Eagle|r (Uncommon)
    // Base: rnsp, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i0c7', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('i0c7', "Critical Chance", 15)
    call DEqItemTypeDefineStatGrantedByName('i0c7', "Damage", 36)
    call DEqItemTypeDefineStatGrantedByName('i0c7', "Strength", 25)
    call DEqItemTypeDefineGoldValue('i0c7', 17750)
    call DEqItemTypeDefineAbilityGranted('i0c7', 'AIbx', 1)

    // |c00FF8000Reliable Bracers of Infinity|r (Legendary)
    // Base: ckng, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('i0c8', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('i0c8', "Agility", 10)
    call DEqItemTypeDefineStatGrantedByName('i0c8', "Critical Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c8', "Hit Chance", 5)
    call DEqItemTypeDefineStatGrantedByName('i0c8', "Intelligence", 10)
    call DEqItemTypeDefineStatGrantedByName('i0c8', "Strength", 10)
    call DEqItemTypeDefineGoldValue('i0c8', 78000)

    // |c00A335EEReliable Other of the Ancients|r (Epic)
    // Base: pinv, Class: Other
    call DEqItemTypeDefineStatGrantedByName('i0c9', "Agility", 14)
    call DEqItemTypeDefineStatGrantedByName('i0c9', "Hitpoints", 74)
    call DEqItemTypeDefineStatGrantedByName('i0c9', "Mana regeneration", 7)
    call DEqItemTypeDefineStatGrantedByName('i0c9', "Strength", 14)
    call DEqItemTypeDefineGoldValue('i0c9', 11900)

    // |c00A335EETEST Chest of the Ancients|r (Epic)
    // Base: rej4, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d0', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d0', "Agility", 34)
    call DEqItemTypeDefineStatGrantedByName('i0d0', "Armor", 14)
    call DEqItemTypeDefineStatGrantedByName('i0d0', "Hitpoints", 149)
    call DEqItemTypeDefineStatGrantedByName('i0d0', "Mana regeneration", 9)
    call DEqItemTypeDefineGoldValue('i0d0', 33000)

    // |c00FFFFFFTEST Quality Belt|r (Common)
    // Base: tagi, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i0d1', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i0d1', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('i0d1', "Hitpoints", 57)
    call DEqItemTypeDefineStatGrantedByName('i0d1', "Intelligence", 13)
    call DEqItemTypeDefineGoldValue('i0d1', 4500)

    // |c001EFF00TEST Quality Trinket of the Bear|r (Uncommon)
    // Base: pspd, Class: Trinket
    call DEqItemTypeDefineAllowedSlotId('i0d2', 17)
    call DEqItemTypeDefineAllowedSlotId('i0d2', 18)
    call DEqItemTypeDefineStatGrantedByName('i0d2', "Agility", 13)
    call DEqItemTypeDefineStatGrantedByName('i0d2', "Critical Chance", 13)
    call DEqItemTypeDefineStatGrantedByName('i0d2', "Intelligence", 13)
    call DEqItemTypeDefineStatGrantedByName('i0d2', "Strength", 13)
    call DEqItemTypeDefineGoldValue('i0d2', 16500)

    // |c001EFF00Quality Foot of Power|r (Uncommon)
    // Base: sor2, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d3', "Boots")
    call DEqItemTypeDefineStatGrantedByName('i0d3', "Armor", 9)
    call DEqItemTypeDefineStatGrantedByName('i0d3', "Hitpoints", 95)
    call DEqItemTypeDefineStatGrantedByName('i0d3', "Strength", 22)
    call DEqItemTypeDefineGoldValue('i0d3', 14000)
    call DEqItemTypeDefineAbilityGranted('i0d3', 'TEST', 1)
    call DEqItemTypeDefineAbilityGranted('i0d3', 'TEST', 1)

    // |c00FF8000Sturdy Miscellaneous of Creation|r (Legendary)
    // Base: rnsp, Class: Miscellaneous
    call DEqItemTypeDefineStatGrantedByName('i0d4', "Agility", 21)
    call DEqItemTypeDefineStatGrantedByName('i0d4', "Hitpoints", 106)
    call DEqItemTypeDefineStatGrantedByName('i0d4', "Movement Speed", 10)
    call DEqItemTypeDefineStatGrantedByName('i0d4', "Strength", 21)
    call DEqItemTypeDefineGoldValue('i0d4', 18000)
    call DEqItemTypeDefineAbilityGranted('i0d4', 'Tase', 1)
    call DEqItemTypeDefineAbilityGranted('i0d4', 'rrtt', 1)

    // |c00FF8000TEST_stat_str|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d5', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d5', "Strength", 1)
    call DEqItemTypeDefineGoldValue('i0d5', 2020)

    // |c00FF8000TEST_stat_agi|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d6', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d6', "Agility", 1)
    call DEqItemTypeDefineGoldValue('i0d6', 2020)

    // |c00FF8000TEST_stat_int|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d7', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d7', "Intelligence", 1)
    call DEqItemTypeDefineGoldValue('i0d7', 2020)

    // |c00FF8000TEST_stat_health|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d8', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d8', "Hitpoints", 1)
    call DEqItemTypeDefineGoldValue('i0d8', 2020)

    // |c00FF8000TEST_stat_hpregen|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0d9', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0d9', "HP Pct Per Sec", 0.1)
    call DEqItemTypeDefineGoldValue('i0d9', 2020)

    // |c00FF8000TEST_stat_mana|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e0', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e0', "Mana", 500)
    call DEqItemTypeDefineGoldValue('i0e0', 2020)

    // |c00FF8000TEST_stat_manaregen|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e1', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e1', "Mana Pct Per Sec", 0.1)
    call DEqItemTypeDefineGoldValue('i0e1', 2020)

    // |c00FF8000TEST_stat_critchance|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e2', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e2', "Critical Chance", 100)
    call DEqItemTypeDefineGoldValue('i0e2', 2020)

    // |c00FF8000TEST_stat_damage|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e3', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e3', "Damage", 50)
    call DEqItemTypeDefineGoldValue('i0e3', 2020)

    // |c00FF8000TEST_stat_meleeDMG|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e4', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e4', "Melee Damage", 50)
    call DEqItemTypeDefineGoldValue('i0e4', 2020)

    // |c00FF8000TEST_stat_meleeDMGPct|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e5', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e5', "Melee DMG Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0e5', 2020)

    // |c00FF8000TEST_stat_rangedDMG|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e6', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e6', "Ranged Damage", 50)
    call DEqItemTypeDefineGoldValue('i0e6', 2020)

    // |c00FF8000TEST_stat_rangedDMGPct|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e7', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e7', "Ranged DMG Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0e7', 2020)

    // |c00FF8000TEST_stat_cleavePct|r (Legendary)
    // Base: bspd, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('i0e8', "Chest")
    call DEqItemTypeDefineStatGrantedByName('i0e8', "Cleave Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0e8', 2020)

    // |c00FF8000TEST_stat_cleaveArea|r (Legendary)
    // Base: bspd, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('i0e9', 8)
    call DEqItemTypeDefineAllowedSlotId('i0e9', 9)
    call DEqItemTypeDefineStatGrantedByName('i0e9', "Cleave Area", 300)
    call DEqItemTypeDefineGoldValue('i0e9', 2020)

    // |c00FF8000TEST_stat_attackSpeed|r (Legendary)
    // Base: bspd, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('i0f0', 8)
    call DEqItemTypeDefineAllowedSlotId('i0f0', 9)
    call DEqItemTypeDefineStatGrantedByName('i0f0', "Attack Speed", 0.5)
    call DEqItemTypeDefineGoldValue('i0f0', 2020)

    // |c00FF8000TEST_stat_lifesteal|r (Legendary)
    // Base: bspd, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('i0f1', 8)
    call DEqItemTypeDefineAllowedSlotId('i0f1', 9)
    call DEqItemTypeDefineStatGrantedByName('i0f1', "Lifesteal Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f1', 2020)

    // |c00FF8000TEST_stat_thornsFlat|r (Legendary)
    // Base: bspd, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i0f2', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i0f2', "Thorns", 100)
    call DEqItemTypeDefineGoldValue('i0f2', 2020)

    // |c00FF8000TEST_stat_thornsPct|r (Legendary)
    // Base: bspd, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i0f3', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i0f3', "Thorns Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f3', 2020)

    // |c00FF8000TEST_stat_armor|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f4', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f4', "Armor", 25)
    call DEqItemTypeDefineGoldValue('i0f4', 2020)

    // |c00FF8000TEST_stat_armorPct|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f5', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f5', "Armor Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f5', 2020)

    // |c00FF8000TEST_stat_dodge|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f6', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f6', "Dodge", 100)
    call DEqItemTypeDefineGoldValue('i0f6', 2020)

    // |c00FF8000TEST_stat_magictakenPct|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f7', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f7', "Spell Damage Taken Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f7', 2020)

    // |c00FF8000TEST_stat_meleetakenPct|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f8', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f8', "Melee Damage Taken Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f8', 2020)

    // |c00FF8000TEST_stat_piercetakenPct|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0f9', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0f9', "Pierce Damage Taken Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0f9', 2020)

    // |c00FF8000TEST_stat_movementSpeed|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g0', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0g0', "Movement Speed", 50)
    call DEqItemTypeDefineGoldValue('i0g0', 2020)

    // |c00FF8000TEST_stat_movementSpeedPct|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g1', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0g1', "MoveSPD Pct", 0.5)
    call DEqItemTypeDefineGoldValue('i0g1', 2020)

    // |c00FF8000TEST_stat_block|r (Legendary)
    // Base: bspd, Class: Shield
    call DEqItemTypeDefineAllowedSlotByName('i0g2', "OffHand")
    call DEqItemTypeDefineShieldBlock('i0g2', 100)
    call DEqItemTypeDefineStatGrantedByName('i0g2', "Block Chance", 100)
    call DEqItemTypeDefineGoldValue('i0g2', 2020)

    // |c00FF8000TEST_stat_hit|r (Legendary)
    // Base: bspd, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotId('i0g3', 19)
    call DEqItemTypeDefineAs2Handed('i0g3')
    call DEqItemTypeDefineStatGrantedByName('i0g3', "Hit Chance", 100)
    call DEqItemTypeDefineGoldValue('i0g3', 2020)

    // |c00FF8000TEST_stat_spellpowerPct|r (Legendary)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('i0g4', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('i0g4', "Spell Power Pct", 100)
    call DEqItemTypeDefineGoldValue('i0g4', 2020)

    // |c00FF8000TEST_stat_spellpowerFlat|r (Legendary)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g5', "Boots")
    call DEqItemTypeDefineStatGrantedByName('i0g5', "Spell Power", 400)
    call DEqItemTypeDefineGoldValue('i0g5', 2020)

    // |c00FF8000TEST_stat_magictakenPctNeg|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g6', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0g6', "Spell Damage Taken Pct", -0.5)
    call DEqItemTypeDefineGoldValue('i0g6', 2020)

    // |c00FF8000TEST_stat_meleetakenPctNeg|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g7', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0g7', "Melee Damage Taken Pct", -0.5)
    call DEqItemTypeDefineGoldValue('i0g7', 2020)

    // |c00FF8000TEST_stat_piercetakenPctNeg|r (Legendary)
    // Base: bspd, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('i0g8', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('i0g8', "Pierce Damage Taken Pct", -0.5)
    call DEqItemTypeDefineGoldValue('i0g8', 2020)

    // Ancient Lichen (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1c6', 150)

    // Arthas' Tears (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1c7', 250)

    // Azshara's Veil (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1c8', 300)

    // Black Lotus (Epic)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1c9', 1000)

    // Bloodthistle (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ca', 75)

    // Chameleon Lotus (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1cb', 400)

    // Cinderbloom (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1cc', 120)

    // Constrictor Grass (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1cd', 180)

    // Crown Royal (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ce', 350)

    // Dragon's Teeth (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1cf', 450)

    // Dreamfoil (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d0', 200)

    // Dreaming Glory (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d1', 175)

    // Evergreen Moss (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d2', 90)

    // Fadeleaf (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d3', 110)

    // Felweed (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d4', 95)

    // Firebloom (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d5', 160)

    // Fireweed (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d6', 105)

    // Flame Cap (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d7', 280)

    // Fool's Cap (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d8', 220)

    // Frost Lotus (Epic)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1d9', 800)

    // Frostweed (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1da', 130)

    // Frozen Herb (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1db', 190)

    // Goldclover (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1dc', 85)

    // Golden Lotus (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1dd', 500)

    // Grave Moss (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1de', 95)

    // Heartblossom (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1df', 185)

    // Icecap (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e0', 170)

    // Jade Tea Leaf (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e1', 125)

    // Khadgar's Whisker (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e2', 195)

    // Magebloom (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e3', 320)

    // Mana Thistle (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e4', 380)

    // Gloom Cap (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e5', 70)

    // Fel Cap (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e6', 75)

    // Spawn Cap (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e7', 65)

    // Netherbloom (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e8', 340)

    // Nightmare Vine (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1e9', 215)

    // Purple Lotus (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ea', 230)

    // Ragveil (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1eb', 165)

    // Rain Poppy (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ec', 80)

    // Mountain Sansam (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ed', 195)

    // Sha-Touched Herb (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ee', 420)

    // Silkweed (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ef', 115)

    // Silverleaf (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f0', 45)

    // Snow Lily (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f1', 135)

    // Spineleaf (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f2', 180)

    // Stardust (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f3', 460)

    // Starflower (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f4', 200)

    // Steelbloom (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f5', 105)

    // Stormvine (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f6', 190)

    // Stormvine Bubbles (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f7', 310)

    // Stranglekelp (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f8', 90)

    // Sungrass (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1f9', 155)

    // Swiftthistle (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1fa', 100)

    // Talador Orchid (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1fb', 175)

    // Talandra's Rose (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1fc', 185)

    // Goldthorn (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1fd', 120)

    // Icethorn (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1fe', 180)

    // Terocone (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1ff', 170)

    // |c00FFFFFFWillow Branch|r (Common)
    // Base: wtlg, Class: MISC
    call DEqItemTypeDefineGoldValue('i1g0', 5)

    // |c000070DDReliable Ring of the Warrior|r (Rare)
    // Base: sor4, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('i1g1', 8)
    call DEqItemTypeDefineAllowedSlotId('i1g1', 9)
    call DEqItemTypeDefineStatGrantedByName('i1g1', "Agility", 8)
    call DEqItemTypeDefineStatGrantedByName('i1g1', "Intelligence", 8)
    call DEqItemTypeDefineStatGrantedByName('i1g1', "Strength", 8)
    call DEqItemTypeDefineGoldValue('i1g1', 6000)
    call DEqItemTypeDefineAbilityGranted('i1g1', '1111', 1)

    // |c00FFFFFFWine Bottle|r (Common)
    // Base: rej2, Class: Consumable
    call DEqItemTypeDefineGoldValue('i1g2', 55)

    // |c00FFFFFFElven Wine|r (Common)
    // Base: rej2, Class: Consumable
    call DEqItemTypeDefineGoldValue('i1g3', 55)

    // |c00FFFFFFBaseItemAbilitiesTestItem|r (Common)
    // Base: rat3, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i1g4', 55)

    // |c00FFFFFFafac nostats|r (Common)
    // Base: afac, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i1g5', "MainHand")

    // |c00FFFFFFafac stats|r (Common)
    // Base: afac, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i1g6', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('i1g6', "Critical Chance", 1)

    // |c00FFFFFFamrc nostats|r (Common)
    // Base: amrc, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i1g7', "MainHand")

    // |c00FFFFFFamrc stats|r (Common)
    // Base: amrc, Class: 1h
    call DEqItemTypeDefineAllowedSlotByName('i1g8', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('i1g8', "Critical Chance", 1)

    // |c00FFFFFFshea test|r (Common)
    // Base: shea, Class: Consumable

    // |c00FF8000Eliaksen Hondan Avain|r (Legendary)
    // Base: afac, Class: Trinket
    call DEqItemTypeDefineAllowedSlotId('i1h0', 17)
    call DEqItemTypeDefineAllowedSlotId('i1h0', 18)
    call DEqItemTypeDefineStatGrantedByName('i1h0', "Critical Chance", 100)
    call DEqItemTypeDefineStatGrantedByName('i1h0', "Hitpoints", -100)
    call DEqItemTypeDefineStatGrantedByName('i1h0', "Hit Chance", 100)
    call DEqItemTypeDefineStatGrantedByName('i1h0', "Intelligence", 666)
    call DEqItemTypeDefineGoldValue('i1h0', 666)
    call DEqItemTypeDefineAbilityGranted('i1h0', 'A0CE', 1)

    // |c00FFFFFFSturdy Material|r (Common)
    // Base: thle, Class: Material
    call DEqItemTypeDefineStatGrantedByName('i1h1', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('i1h1', "Hitpoints", 26)
    call DEqItemTypeDefineStatGrantedByName('i1h1', "Strength", 5)
    call DEqItemTypeDefineGoldValue('i1h1', 1670)

    // |c001EFF00Divine Stave of the Bear|r (Uncommon)
    // Base: fgrd, Class: Stave
    call DEqItemTypeDefineAllowedSlotId('i1h2', 19)
    call DEqItemTypeDefineAs2Handed('i1h2')
    call DEqItemTypeDefineStatGrantedByName('i1h2', "Critical Chance", 15)
    call DEqItemTypeDefineStatGrantedByName('i1h2', "Damage", 39)
    call DEqItemTypeDefineStatGrantedByName('i1h2', "Intelligence", 27)
    call DEqItemTypeDefineGoldValue('i1h2', 20250)

    // |c00FFFFFFReliable Quest of the Warrior|r (Common)
    // Base: bgst, Class: Quest
    call DEqItemTypeDefineStatGrantedByName('i1h3', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('i1h3', "Hitpoints", 29)
    call DEqItemTypeDefineStatGrantedByName('i1h3', "Strength", 5)
    call DEqItemTypeDefineGoldValue('i1h3', 2350)

    // |c00FF8000Fine Belt of Apocalypse|r (Legendary)
    // Base: tpow, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('i1h4', "Belt")
    call DEqItemTypeDefineStatGrantedByName('i1h4', "Armor", 26)
    call DEqItemTypeDefineStatGrantedByName('i1h4', "Hitpoints", 267)
    call DEqItemTypeDefineStatGrantedByName('i1h4', "Movement Speed", 17)
    call DEqItemTypeDefineStatGrantedByName('i1h4', "Strength", 62)
    call DEqItemTypeDefineGoldValue('i1h4', 98000)

    // Tiger Lily (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i200', 125)

    // Twilight Jasmine (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i201', 190)

    // Whiptail (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i202', 165)

    // Whispervine (Rare)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i203', 290)

    // Winter's Bite (Common)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i204', 110)

    // Snakeroot (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i205', 155)

    // |c001EFF00Thornroot|r (Uncommon)
    // Base: bspd, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('i206', 145)

    // Rol'jin's Head (Common)
    // Base: bzbe, Class: MISC

    // Eye of Mur'gal (Common)
    // Base: ches, Class: MISC

    // Light Boots (Common)
    // Base: belv, Class: MISC
    call DEqItemTypeDefineGoldValue('I602', 3000)
    call DEqItemTypeDefineAbilityGranted('I602', 'AIx2', 1)

    // |c0090EE90Heavy Boots|r (Uncommon)
    // Base: belv, Class: MISC
    call DEqItemTypeDefineGoldValue('I603', 6500)
    call DEqItemTypeDefineAbilityGranted('I603', 'AIs6', 1)
    call DEqItemTypeDefineAbilityGranted('I603', 'AId1', 1)

    // |c0090EE90Voodoo Mask|r (Uncommon)
    // Base: ckng, Class: MISC
    call DEqItemTypeDefineGoldValue('I604', 4000)
    call DEqItemTypeDefineAbilityGranted('I604', 'AImz', 1)
    call DEqItemTypeDefineAbilityGranted('I604', 'AIi6', 1)

    // Hammer of Blood (Common)
    // Base: mlst, Class: MISC
    call DEqItemTypeDefineGoldValue('I605', 8500)
    call DEqItemTypeDefineAbilityGranted('I605', 'AIav', 1)
    call DEqItemTypeDefineAbilityGranted('I605', 'AIa6', 1)

    // Helm of Fel'Dok (Common)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I606', 10000)
    call DEqItemTypeDefineAbilityGranted('I606', 'AId0', 1)
    call DEqItemTypeDefineAbilityGranted('I606', 'AI2m', 1)

    // |c00FF8000Weapon of Fel'Dok|r (Common)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I607', 10000)
    call DEqItemTypeDefineAbilityGranted('I607', 'AItx', 1)
    call DEqItemTypeDefineAbilityGranted('I607', 'AItx', 1)

    // Tome of God (Common)
    // Base: tpow, Class: MISC
    call DEqItemTypeDefineGoldValue('I608', 4800)
    call DEqItemTypeDefineAbilityGranted('I608', 'AIxm', 1)
    call DEqItemTypeDefineAbilityGranted('I608', 'AIxm', 1)
    call DEqItemTypeDefineAbilityGranted('I608', 'AIxm', 1)
    call DEqItemTypeDefineAbilityGranted('I608', 'AIxm', 1)

    // Manual of Eternal (Common)
    // Base: manh, Class: MISC
    call DEqItemTypeDefineGoldValue('I609', 1000)
    call DEqItemTypeDefineAbilityGranted('I609', 'AImh', 1)
    call DEqItemTypeDefineAbilityGranted('I609', 'AImh', 1)
    call DEqItemTypeDefineAbilityGranted('I609', 'AImh', 1)
    call DEqItemTypeDefineAbilityGranted('I609', 'AImh', 1)

    // Tome of Eternal Agility (Common)
    // Base: tdex, Class: MISC
    call DEqItemTypeDefineGoldValue('I60A', 1200)
    call DEqItemTypeDefineAbilityGranted('I60A', 'AIgm', 1)
    call DEqItemTypeDefineAbilityGranted('I60A', 'AIgm', 1)
    call DEqItemTypeDefineAbilityGranted('I60A', 'AIgm', 1)
    call DEqItemTypeDefineAbilityGranted('I60A', 'AIgm', 1)

    // Tome of Eternal Intelligence (Common)
    // Base: tint, Class: MISC
    call DEqItemTypeDefineGoldValue('I60B', 1200)
    call DEqItemTypeDefineAbilityGranted('I60B', 'AItm', 1)
    call DEqItemTypeDefineAbilityGranted('I60B', 'AItm', 1)
    call DEqItemTypeDefineAbilityGranted('I60B', 'AItm', 1)
    call DEqItemTypeDefineAbilityGranted('I60B', 'AItm', 1)

    // Tome of Eternal Strength (Common)
    // Base: tstr, Class: MISC
    call DEqItemTypeDefineGoldValue('I60C', 1200)
    call DEqItemTypeDefineAbilityGranted('I60C', 'AInm', 1)
    call DEqItemTypeDefineAbilityGranted('I60C', 'AInm', 1)
    call DEqItemTypeDefineAbilityGranted('I60C', 'AInm', 1)
    call DEqItemTypeDefineAbilityGranted('I60C', 'AInm', 1)

    // Unknown Item (I60D) (Common)
    // Base: tkno, Class: MISC

    // Bottle of Beer (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I60E', 5)

    // Keg of Beer (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I60F', 50)

    // Unknown Item (I60G) (Common)
    // Base: gold, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60G', 'A60G', 1)

    // Unknown Item (I60H) (Common)
    // Base: gold, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60H', 'A60H', 1)

    // |c0090EE90Steel Blade|r (Uncommon)
    // Base: ratc, Class: MISC
    call DEqItemTypeDefineGoldValue('I60I', 1250)
    call DEqItemTypeDefineAbilityGranted('I60I', 'AItf', 1)

    // Margul's Claw (Common)
    // Base: rat3, Class: MISC
    call DEqItemTypeDefineGoldValue('I60J', 1000)
    call DEqItemTypeDefineAbilityGranted('I60J', 'AItx', 1)

    // Pile Of Wood (Common)
    // Base: lmbr, Class: MISC

    // Useless Cloak (Common)
    // Base: lmbr, Class: MISC
    call DEqItemTypeDefineGoldValue('I60L', 60)

    // Rusty Kitchen Knive (Common)
    // Base: lmbr, Class: MISC
    call DEqItemTypeDefineGoldValue('I60M', 45)

    // Old Copper Ring (Common)
    // Base: lmbr, Class: MISC
    call DEqItemTypeDefineGoldValue('I60N', 165)

    // Holy Cross (Common)
    // Base: lmbr, Class: MISC

    // Worn Gloves (Common)
    // Base: rst1, Class: MISC

    // |CFFFF8C00Cloak of Arenamaster|r (Common)
    // Base: clsd, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60Q', 'AIsx', 1)
    call DEqItemTypeDefineAbilityGranted('I60Q', 'A615', 1)
    call DEqItemTypeDefineAbilityGranted('I60Q', 'A617', 1)
    call DEqItemTypeDefineAbilityGranted('I60Q', 'AIms', 1)

    // |CFFFF8C00Boots of Arenamaster|r (Common)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60R', 'AId5', 1)
    call DEqItemTypeDefineAbilityGranted('I60R', 'A618', 1)

    // |CFFFF8C00Gloves of Arenamaster|r (Common)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60S', 'A619', 1)
    call DEqItemTypeDefineAbilityGranted('I60S', 'AIbx', 1)

    // |CFFFF8C00Chestpiece of Arenamaster|r (Common)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60T', 'AId0', 1)
    call DEqItemTypeDefineAbilityGranted('I60T', 'Arel', 1)
    call DEqItemTypeDefineAbilityGranted('I60T', 'AIrm', 1)
    call DEqItemTypeDefineAbilityGranted('I60T', 'A61A', 1)

    // |CFFFF8C00Shoulders of Arenamaster|r (Common)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60U', 'A61C', 1)
    call DEqItemTypeDefineAbilityGranted('I60U', 'A61B', 1)

    // |CFFFF8C00Helm of Arenamaster|r (Common)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I60V', 'A61D', 1)
    call DEqItemTypeDefineAbilityGranted('I60V', 'AIae', 1)

    // Agave (Common)
    // Base: phea, Class: MISC

    // Earth Roots (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I60X', 300)

    // Forest Flower (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I60Y', 125)

    // |cFFFFFFFFSpring Water|r (Common)
    // Base: pclr, Class: Consumable
    call DEqItemTypeDefineGoldValue('I60Z', 150)
    call DEqItemTypeDefineAbilityGranted('I60Z', 'A61F', 1)

    // Murloc Head (Common)
    // Base: kybl, Class: MISC

    // Camp Fire (Common)
    // Base: tgrh, Class: MISC
    call DEqItemTypeDefineGoldValue('I611', 350)
    call DEqItemTypeDefineAbilityGranted('I611', 'A61P', 1)

    // Torch (Common)
    // Base: ledg, Class: MISC
    call DEqItemTypeDefineGoldValue('I612', 50)
    call DEqItemTypeDefineAbilityGranted('I612', 'A62I', 1)
    call DEqItemTypeDefineAbilityGranted('I612', 'A62J', 1)

    // Mount Reins (Common)
    // Base: crys, Class: MISC
    call DEqItemTypeDefineGoldValue('I613', 2000)
    call DEqItemTypeDefineAbilityGranted('I613', 'A626', 1)

    // Stag Hair (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I614', 50)

    // Frog Slime (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I615', 50)

    // Tame Beast I (Common)
    // Base: crys, Class: MISC
    call DEqItemTypeDefineGoldValue('I616', 2000)
    call DEqItemTypeDefineAbilityGranted('I616', 'A623', 1)

    // Tame Beast II (Common)
    // Base: crys, Class: MISC
    call DEqItemTypeDefineGoldValue('I617', 2000)
    call DEqItemTypeDefineAbilityGranted('I617', 'A625', 1)

    // Tame Beast III (Common)
    // Base: crys, Class: MISC
    call DEqItemTypeDefineGoldValue('I618', 2000)
    call DEqItemTypeDefineAbilityGranted('I618', 'A627', 1)

    // |c000080FFNecromancer Robes|r (Rare)
    // Base: rin1, Class: MISC

    // |c00800080Lich Robe|r (Epic)
    // Base: rin1, Class: MISC

    // Bear Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61B', 50)

    // Boar Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61C', 50)

    // Frog Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61D', 50)

    // Turtle Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61E', 50)

    // Wolf Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61F', 50)

    // Thunder Lizard Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61G', 50)

    // Hawk Wing (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61H', 50)

    // |c0090EE90Gnarled Staff|r (Uncommon)
    // Base: rde0, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I61I', 'A648', 1)
    call DEqItemTypeDefineAbilityGranted('I61I', 'AIi3', 1)

    // Create Spring Water (Common)
    // Base: pclr, Class: MISC

    // Empty Vial (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61K', 100)

    // Nazgrek's Flask (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61L', 1500)
    call DEqItemTypeDefineAbilityGranted('I61L', 'A63V', 1)

    // Empty Flask (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61M', 100)

    // Vizier Skin (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I61N', 200)

    // Raw Wolf Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61O', 50)
    call DEqItemTypeDefineAbilityGranted('I61O', 'A60V', 1)

    // Raw Stag Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61P', 25)
    call DEqItemTypeDefineAbilityGranted('I61P', 'A60V', 1)

    // Raw Bear Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61Q', 150)
    call DEqItemTypeDefineAbilityGranted('I61Q', 'A60V', 1)

    // Raw Lizard Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61R', 100)
    call DEqItemTypeDefineAbilityGranted('I61R', 'A60V', 1)

    // Raw Hawk Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61S', 50)
    call DEqItemTypeDefineAbilityGranted('I61S', 'A60V', 1)

    // Raw Murloc Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61T', 50)
    call DEqItemTypeDefineAbilityGranted('I61T', 'A60V', 1)

    // Raw Turtle Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61U', 200)
    call DEqItemTypeDefineAbilityGranted('I61U', 'A60V', 1)

    // Raw Tiger Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61V', 200)
    call DEqItemTypeDefineAbilityGranted('I61V', 'A60V', 1)

    // Raw Panther Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61W', 200)
    call DEqItemTypeDefineAbilityGranted('I61W', 'A60V', 1)

    // Raw Raptor Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61X', 200)
    call DEqItemTypeDefineAbilityGranted('I61X', 'A60V', 1)

    // Raw Snake Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61Y', 50)
    call DEqItemTypeDefineAbilityGranted('I61Y', 'A60V', 1)

    // Raw Makrura Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I61Z', 100)
    call DEqItemTypeDefineAbilityGranted('I61Z', 'A60V', 1)

    // Raw Boar Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I620', 50)
    call DEqItemTypeDefineAbilityGranted('I620', 'A60V', 1)

    // Raw Crawler Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I621', 25)
    call DEqItemTypeDefineAbilityGranted('I621', 'A60V', 1)

    // Raw Rabbit Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I622', 25)
    call DEqItemTypeDefineAbilityGranted('I622', 'A60V', 1)

    // Raw Cow Meat (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I623', 100)
    call DEqItemTypeDefineAbilityGranted('I623', 'A60V', 1)

    // Jin'Zun Healing Ward (Common)
    // Base: phea, Class: MISC

    // Blood Signed Summon Letter (Common)
    // Base: jpnt, Class: MISC

    // Gloves of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I626', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I626', 'AIs1', 1)
    call DEqItemTypeDefineAbilityGranted('I626', 'AIs1', 1)

    // |c0090EE90Belt of Strength|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I627', 'A63E', 1)
    call DEqItemTypeDefineAbilityGranted('I627', 'AId2', 1)
    call DEqItemTypeDefineAbilityGranted('I627', 'AIs3', 1)

    // Boots of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I628', 'AIa4', 1)
    call DEqItemTypeDefineAbilityGranted('I628', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I628', 'AIs3', 1)

    // Chestpiece of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I629', 'A63Y', 1)
    call DEqItemTypeDefineAbilityGranted('I629', 'AId2', 1)
    call DEqItemTypeDefineAbilityGranted('I629', 'AIs6', 1)

    // Helm of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62A', 'A63E', 1)
    call DEqItemTypeDefineAbilityGranted('I62A', 'AIi3', 1)
    call DEqItemTypeDefineAbilityGranted('I62A', 'AId2', 1)
    call DEqItemTypeDefineAbilityGranted('I62A', 'AIs6', 1)

    // Necklace of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62B', 'AImz', 1)
    call DEqItemTypeDefineAbilityGranted('I62B', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62B', 'AIs4', 1)

    // Ring of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62C', 'A63E', 1)
    call DEqItemTypeDefineAbilityGranted('I62C', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62C', 'AIs3', 1)

    // Shield of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62D', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I62D', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62D', 'AId4', 1)
    call DEqItemTypeDefineAbilityGranted('I62D', 'AIs3', 1)

    // Axe of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62E', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62E', 'AIt6', 1)

    // Staff of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62F', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62F', 'A63Y', 1)

    // Sword of Strength (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62G', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I62G', 'AIa4', 1)
    call DEqItemTypeDefineAbilityGranted('I62G', 'AIti', 1)

    // Chestpiece of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62H', 'AI2m', 1)
    call DEqItemTypeDefineAbilityGranted('I62H', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I62H', 'AIi6', 1)

    // Belt of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62I', 'AImz', 1)
    call DEqItemTypeDefineAbilityGranted('I62I', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I62I', 'AIi3', 1)

    // Boots of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62J', 'AIa3', 1)
    call DEqItemTypeDefineAbilityGranted('I62J', 'AIi3', 1)
    call DEqItemTypeDefineAbilityGranted('I62J', 'AIlz', 1)
    call DEqItemTypeDefineAbilityGranted('I62J', 'A644', 1)

    // Gloves of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62K', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I62K', 'AIi3', 1)
    call DEqItemTypeDefineAbilityGranted('I62K', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I62K', 'A644', 1)

    // Helm of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62L', 'A644', 1)
    call DEqItemTypeDefineAbilityGranted('I62L', 'A647', 1)
    call DEqItemTypeDefineAbilityGranted('I62L', 'AId1', 1)
    call DEqItemTypeDefineAbilityGranted('I62L', 'A648', 1)

    // Necklace of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62M', 'AImz', 1)
    call DEqItemTypeDefineAbilityGranted('I62M', 'A647', 1)

    // Ring of Intelligence (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62N', 'A643', 1)
    call DEqItemTypeDefineAbilityGranted('I62N', 'AIi6', 1)
    call DEqItemTypeDefineAbilityGranted('I62N', 'AImz', 1)

    // |c00800080Stormguard|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I62O', 'A640', 1)
    call DEqItemTypeDefineAbilityGranted('I62O', 'AId5', 1)
    call DEqItemTypeDefineAbilityGranted('I62O', 'AId1', 1)

    // Frostward Shield (Common)
    // Base: rst1, Class: MISC

    // Celestial Aegis (Common)
    // Base: rst1, Class: MISC

    // Embersteel Bulwark (Common)
    // Base: rst1, Class: MISC

    // Thunderstrike Defender (Common)
    // Base: rst1, Class: MISC

    // Venomspine Ward (Common)
    // Base: rst1, Class: MISC

    // Runebound Shield (Common)
    // Base: rst1, Class: MISC

    // Crystaline Guardian (Common)
    // Base: rst1, Class: MISC

    // Shadowbane Barrier (Common)
    // Base: rst1, Class: MISC

    // Ironwood Protector (Common)
    // Base: rst1, Class: MISC

    // Arcane Ward (Common)
    // Base: rst1, Class: MISC

    // Dragonhide Shield (Common)
    // Base: rst1, Class: MISC

    // Radiant Crest (Common)
    // Base: rst1, Class: MISC

    // Gloomsteel Shield (Common)
    // Base: rst1, Class: MISC

    // Phoenixguard Shield (Common)
    // Base: rst1, Class: MISC

    // Astral Sentinel (Common)
    // Base: rst1, Class: MISC

    // Frostbite Ward (Common)
    // Base: rst1, Class: MISC

    // Luminous Ward (Common)
    // Base: rst1, Class: MISC

    // Bloodforged Bulwark (Common)
    // Base: rst1, Class: MISC

    // Serpent Scale Shield (Common)
    // Base: rst1, Class: MISC

    // Arcane Scepter (Common)
    // Base: rst1, Class: MISC

    // Celestial Staff (Common)
    // Base: rst1, Class: MISC

    // Emberflare Rod (Common)
    // Base: rst1, Class: MISC

    // Frostbinder Wand (Common)
    // Base: rst1, Class: MISC

    // Thunderstruck Staff (Common)
    // Base: rst1, Class: MISC

    // Venomspire Staff (Common)
    // Base: rst1, Class: MISC

    // Runeblade Staff (Common)
    // Base: rst1, Class: MISC

    // Enigma Arcanum (Common)
    // Base: rst1, Class: MISC

    // Moonlit Rod (Common)
    // Base: rst1, Class: MISC

    // Inferno Scepter (Common)
    // Base: rst1, Class: MISC

    // Doomblade (Common)
    // Base: rst1, Class: MISC

    // Shadowstrike Dagger (Common)
    // Base: rst1, Class: MISC

    // Thunderfury Sword (Common)
    // Base: rst1, Class: MISC

    // Frostbite Axe (Common)
    // Base: rst1, Class: MISC

    // Emberforged Spear (Common)
    // Base: rst1, Class: MISC

    // |c00800080Vortex Warhammer|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I63N', 'AItx', 1)

    // Venomfang Scimitar (Common)
    // Base: rst1, Class: MISC

    // Runeblade Longsword (Common)
    // Base: rst1, Class: MISC

    // Serpent's Bite Dagger (Common)
    // Base: rst1, Class: MISC

    // |c00800080Stormcaller Mace|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I63R', 'AItn', 1)

    // Dragonfang Katana (Common)
    // Base: rst1, Class: MISC

    // Soulreaper Halberd (Common)
    // Base: rst1, Class: MISC

    // Infernal Flare Wand (Common)
    // Base: rst1, Class: MISC

    // Frostshard Greatsword (Common)
    // Base: rst1, Class: MISC

    // Runebound War Axe (Common)
    // Base: rst1, Class: MISC

    // Celestial Crescent Blade (Common)
    // Base: rst1, Class: MISC

    // Shadowmeld Shiv (Common)
    // Base: rst1, Class: MISC

    // Flamestrike Lance (Common)
    // Base: rst1, Class: MISC

    // Bloodfang Cleaver (Common)
    // Base: rst1, Class: MISC

    // Ironjaw Warblade (Common)
    // Base: rst1, Class: MISC

    // Skullcrusher Maul (Common)
    // Base: rst1, Class: MISC

    // Raging Blade of Doom (Common)
    // Base: rst1, Class: MISC

    // Thunderhorn Warhammer (Common)
    // Base: rst1, Class: MISC

    // Talisman of Arcane Resonance (Common)
    // Base: rst1, Class: MISC

    // Moonlit Amulet (Common)
    // Base: rst1, Class: MISC

    // Frostbound Pendant (Common)
    // Base: rst1, Class: MISC

    // Thunderheart Medallion (Common)
    // Base: rst1, Class: MISC

    // Celestial Harmony Necklace (Common)
    // Base: rst1, Class: MISC

    // Emberflare Charm (Common)
    // Base: rst1, Class: MISC

    // Venomweave Locket (Common)
    // Base: rst1, Class: MISC

    // Rune-etched Collar (Common)
    // Base: rst1, Class: MISC

    // Shadowcloak Talisman (Common)
    // Base: rst1, Class: MISC

    // Serpent's Coil Necklace (Common)
    // Base: rst1, Class: MISC

    // Ring of Eternal Frost (Common)
    // Base: rst1, Class: MISC

    // Thunderforged Band (Common)
    // Base: rst1, Class: MISC

    // Emberstone Loop (Common)
    // Base: rst1, Class: MISC

    // Celestial Halo (Common)
    // Base: rst1, Class: MISC

    // Runebound Circlet (Common)
    // Base: rst1, Class: MISC

    // Shadowweaver Ring (Common)
    // Base: rst1, Class: MISC

    // Serpent's Coil Ring (Common)
    // Base: rst1, Class: MISC

    // Bloodfire Signet (Common)
    // Base: rst1, Class: MISC

    // Moonstone Seal (Common)
    // Base: rst1, Class: MISC

    // Ironheart Ring (Common)
    // Base: rst1, Class: MISC

    // Dragonscale Chestplate (Common)
    // Base: rst1, Class: MISC

    // Thunderforged Breastplate (Common)
    // Base: rst1, Class: MISC

    // Celestial Mail (Common)
    // Base: rst1, Class: MISC

    // Emberheart Cuirass (Common)
    // Base: rst1, Class: MISC

    // Runebound Hauberk (Common)
    // Base: rst1, Class: MISC

    // |c00800080Shadowmantle Armor|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I64U', 'AImz', 1)
    call DEqItemTypeDefineAbilityGranted('I64U', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I64U', 'AIs6', 1)
    call DEqItemTypeDefineAbilityGranted('I64U', 'AId4', 1)

    // Frostbitten Plate (Common)
    // Base: rst1, Class: MISC

    // Serpent's Scale Vest (Common)
    // Base: rst1, Class: MISC

    // Obsidian Warplate (Common)
    // Base: rst1, Class: MISC

    // Moonshadow Robes (Common)
    // Base: rst1, Class: MISC

    // Silks of Celestial Harmony (Common)
    // Base: rst1, Class: MISC

    // Emberweave Robes (Common)
    // Base: rst1, Class: MISC

    // Frostshroud Vestments (Common)
    // Base: rst1, Class: MISC

    // Thunderfall Raiment (Common)
    // Base: rst1, Class: MISC

    // Runebound Silk Tunic (Common)
    // Base: rst1, Class: MISC

    // Shadowcloak Mantle (Common)
    // Base: rst1, Class: MISC

    // Serpent's Whispering Garb (Common)
    // Base: rst1, Class: MISC

    // Moonlight Veil (Common)
    // Base: rst1, Class: MISC

    // Ethereal Frostcloth Wrap (Common)
    // Base: rst1, Class: MISC

    // Astral Silken Robe (Common)
    // Base: rst1, Class: MISC

    // Cloak of Shadowsong (Common)
    // Base: rst1, Class: MISC

    // Frostweave Mantle (Common)
    // Base: rst1, Class: MISC

    // Thunderfall Shroud (Common)
    // Base: rst1, Class: MISC

    // Celestial Veil (Common)
    // Base: rst1, Class: MISC

    // Emberwind Wrap (Common)
    // Base: rst1, Class: MISC

    // |c000080FFRunebound Cloak|r (Rare)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65E', 'A643', 1)
    call DEqItemTypeDefineAbilityGranted('I65E', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I65E', 'AIi4', 1)
    call DEqItemTypeDefineAbilityGranted('I65E', 'AId2', 1)

    // Shadowshroud Drape (Common)
    // Base: rst1, Class: MISC

    // Serpent's Embrace (Common)
    // Base: rst1, Class: MISC

    // Moonlit Whisper Cloak (Common)
    // Base: rst1, Class: MISC

    // Astral Ebon Mantle (Common)
    // Base: rst1, Class: MISC

    // Rusty Dagger (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I65J', 50)

    // |c0090EE90Steel Longsword|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I65K', 1000)
    call DEqItemTypeDefineAbilityGranted('I65K', 'A65B', 1)
    call DEqItemTypeDefineAbilityGranted('I65K', 'AItk', 1)
    call DEqItemTypeDefineAbilityGranted('I65K', 'AIs4', 1)

    // |c0090EE90Enchanted Amulet|r (Uncommon)
    // Base: rst1, Class: MISC

    // |c0090EE90Polished Wooden Wand|r (Uncommon)
    // Base: rde0, Class: MISC

    // |c00800080Vortex Blade|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65N', 'A65E', 1)
    call DEqItemTypeDefineAbilityGranted('I65N', 'AItx', 1)

    // |c00800080Stormcaller Boots|r (Epic)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65O', 'AI2m', 1)
    call DEqItemTypeDefineAbilityGranted('I65O', 'A63E', 1)

    // Mystic Orb (Common)
    // Base: rst1, Class: MISC

    // Shadow Cloak (Common)
    // Base: rst1, Class: MISC

    // Hammer of the Ancients (Common)
    // Base: rst1, Class: MISC

    // Gleaming Plate Armor (Common)
    // Base: rst1, Class: MISC

    // Arcane Staff of Elements (Common)
    // Base: rst1, Class: MISC

    // Celestial Gauntlets (Common)
    // Base: rst1, Class: MISC

    // Celestial Robes (Common)
    // Base: rst1, Class: MISC

    // Swift Boots of Agility (Common)
    // Base: rst1, Class: MISC

    // |c0090EE90Reinforced Leather Gloves|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65X', 'A64V', 1)
    call DEqItemTypeDefineAbilityGranted('I65X', 'AIa4', 1)
    call DEqItemTypeDefineAbilityGranted('I65X', 'AId1', 1)

    // |c0090EE90Reinforced Leather Boots|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65Y', 'AIa6', 1)
    call DEqItemTypeDefineAbilityGranted('I65Y', 'AIa1', 1)
    call DEqItemTypeDefineAbilityGranted('I65Y', 'AId1', 1)

    // |c0090EE90Reinforced Leather Helmet|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I65Z', 'A64U', 1)
    call DEqItemTypeDefineAbilityGranted('I65Z', 'AIs4', 1)
    call DEqItemTypeDefineAbilityGranted('I65Z', 'AIi4', 1)
    call DEqItemTypeDefineAbilityGranted('I65Z', 'AId2', 1)

    // |c0090EE90Reinforced Leather Chestpiece|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I660', 'A63E', 1)
    call DEqItemTypeDefineAbilityGranted('I660', 'A644', 1)
    call DEqItemTypeDefineAbilityGranted('I660', 'AIa6', 1)

    // |c0090EE90Reinforced Leather Belt|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I661', 'A643', 1)
    call DEqItemTypeDefineAbilityGranted('I661', 'AIa6', 1)
    call DEqItemTypeDefineAbilityGranted('I661', 'AIs3', 1)
    call DEqItemTypeDefineAbilityGranted('I661', 'AId2', 1)

    // |c0090EE90Reinforced Leather Shoulderpads|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I662', 'A643', 1)
    call DEqItemTypeDefineAbilityGranted('I662', 'AIi4', 1)
    call DEqItemTypeDefineAbilityGranted('I662', 'AId1', 1)

    // Crown of Celestial Mastery (Common)
    // Base: rst1, Class: MISC

    // Starforged Battleaxe (Common)
    // Base: rst1, Class: MISC

    // Dragonhide Cloak of the Serpent (Common)
    // Base: rst1, Class: MISC

    // Blade of the Eternal (Common)
    // Base: rst1, Class: MISC

    // Phoenix Feather Talisman (Common)
    // Base: rst1, Class: MISC

    // Tattered Leather Boots (Common)
    // Base: rst1, Class: MISC

    // Tattered Leather Gloves (Common)
    // Base: rst1, Class: MISC

    // Tattered Leather Shoulderpads (Common)
    // Base: rst1, Class: MISC

    // Tattered Leather Chestpiece (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I66B', 'A65C', 1)

    // Tattered Leather Helmet (Common)
    // Base: rst1, Class: MISC

    // Tattered Leather Belt (Common)
    // Base: rst1, Class: MISC

    // |cFFFFFFFFWooden Shield|r (Common)
    // Base: rst1, Class: Shield
    call DEqItemTypeDefineAllowedSlotByName('I66E', "OffHand")
    call DEqItemTypeDefineShieldBlock('I66E', 50)
    call DEqItemTypeDefineStatGrantedByName('I66E', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('I66E', "Strength", 4)
    call DEqItemTypeDefineGoldValue('I66E', 250)
    call DEqItemTypeDefineAbilityGranted('I66E', 'A65N', 1)

    // |c00A9A9A9Faded Cloth Robes|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I66F', 'A644', 1)
    call DEqItemTypeDefineAbilityGranted('I66F', 'A64X', 1)

    // |c00A9A9A9Frayed Hat|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I66G', 'A643', 1)
    call DEqItemTypeDefineAbilityGranted('I66G', 'A64X', 1)

    // Critmaster (Common)
    // Base: ofro, Class: MISC

    // Sargoth's Ichor (Common)
    // Base: ches, Class: MISC

    // Venomweave Flask (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I66J', 1500)
    call DEqItemTypeDefineAbilityGranted('I66J', 'A650', 1)
    call DEqItemTypeDefineAbilityGranted('I66J', 'A64Z', 1)

    // |cFFFFFFFFSalt|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('I66K', 50)

    // |cFFFFFFFFDeeprock Salt|r (Common)
    // Base: phea, Class: Material
    // Rawcode aliases: 'i66l', 'I66L'
    call DEqItemTypeDefineGoldValue('i66l', 200)
    call DEqItemTypeDefineGoldValue('I66L', 200)

    // Thread (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I66L', 50)

    // |cFFFFFFFFSkinning Knife|r (Common)
    // Base: fgrg, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I66M', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I66M', "Damage", 3)
    call DEqItemTypeDefineGoldValue('I66M', 100)
    call DEqItemTypeDefineAbilityGranted('I66M', 'A0F3', 1)

    // Dye (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I66N', 200)

    // Disgusting Slime (Common)
    // Base: ches, Class: MISC

    // Rotten Part (Common)
    // Base: ches, Class: MISC

    // Spider Ichor (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I66Q', 200)

    // Adept Shaman Claws (Common)
    // Base: shcw, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I66R', 'A658', 1)

    // Blindweed (Common)
    // Base: phea, Class: MISC

    // Bruiseweed (Common)
    // Base: phea, Class: MISC

    // Gromsblood (Common)
    // Base: phea, Class: MISC

    // Liferoot (Common)
    // Base: phea, Class: MISC

    // Mountain Silversage (Common)
    // Base: phea, Class: MISC

    // Peacebloom (Common)
    // Base: phea, Class: MISC

    // Plaguebloom (Common)
    // Base: phea, Class: MISC

    // Shroom Blue (Common)
    // Base: phea, Class: MISC

    // Shroom Red (Common)
    // Base: phea, Class: MISC

    // Shroom Green (Common)
    // Base: phea, Class: MISC

    // Mining Pick (Common)
    // Base: rump, Class: MISC
    call DEqItemTypeDefineGoldValue('I672', 150)
    call DEqItemTypeDefineAbilityGranted('I672', 'A65F', 1)
    call DEqItemTypeDefineAbilityGranted('I672', 'AIat', 1)

    // TEST 1H Axe 04 (Common)
    // Base: rst1, Class: MISC

    // TEST 2H Axe B 01 (Common)
    // Base: rst1, Class: MISC

    // TEST 2H Polearm (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I675', 'A65G', 1)

    // TEST 1H Mace (Common)
    // Base: rst1, Class: MISC

    // TEST 2H Mace (Common)
    // Base: rst1, Class: MISC

    // TEST 1H Sword (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I678', 'A65D', 1)

    // TEST 2H Sword (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I679', 'A65E', 1)

    // TEST Shield 1 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I67A', 'A65H', 1)

    // TEST Shield 2 (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I67B', 'A65I', 1)

    // Utilities (Common)
    // Base: sbok, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I67C', 'A65J', 1)

    // Utilities 2 (Common)
    // Base: sbok, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I67D', 'A65M', 1)

    // Copper Ore (Common)
    // Base: phea, Class: Material

    // Tin Ore (Common)
    // Base: phea, Class: Material

    // Silver Ore (Common)
    // Base: phea, Class: Material

    // Iron Ore (Common)
    // Base: phea, Class: Material

    // Gold Ore (Common)
    // Base: phea, Class: Material

    // Mithril Ore (Common)
    // Base: phea, Class: Material

    // Arcanite Ore (Common)
    // Base: phea, Class: Material

    // Thorium Ore (Common)
    // Base: phea, Class: Material

    // Copper Bar (Common)
    // Base: phea, Class: Material

    // Tin Bar (Common)
    // Base: phea, Class: Material

    // Silver Bar (Common)
    // Base: phea, Class: Material

    // Bronze Bar (Common)
    // Base: phea, Class: Material

    // Iron Bar (Common)
    // Base: phea, Class: Material

    // Steel Bar (Common)
    // Base: phea, Class: Material

    // Gold Bar (Common)
    // Base: phea, Class: Material

    // Mithril Bar (Common)
    // Base: phea, Class: Material

    // Arcanite Bar (Common)
    // Base: phea, Class: Material

    // Thorium Bar (Common)
    // Base: phea, Class: Material

    // Malachite (Common)
    // Base: phea, Class: MISC

    // Tigerseye (Common)
    // Base: phea, Class: MISC

    // Shadowgem (Common)
    // Base: phea, Class: MISC

    // Moonstone (Common)
    // Base: phea, Class: MISC

    // Moss Agate (Common)
    // Base: phea, Class: MISC

    // Jade (Common)
    // Base: phea, Class: MISC

    // Citrine (Common)
    // Base: phea, Class: MISC

    // Opal (Common)
    // Base: phea, Class: MISC

    // Blue Sapphire (Common)
    // Base: phea, Class: MISC

    // Emerald (Common)
    // Base: phea, Class: MISC

    // Diamond (Common)
    // Base: phea, Class: MISC

    // Arcane Crystal (Common)
    // Base: phea, Class: MISC

    // Star Ruby (Common)
    // Base: phea, Class: MISC

    // Coal (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I689', 50)

    // |cFF1EFF00Nazgrek's Axe|r (Uncommon)
    // Base: rst1, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I68A', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I68A', "Agility", 2)
    call DEqItemTypeDefineStatGrantedByName('I68A', "Strength", 3)
    call DEqItemTypeDefineGoldValue('I68A', 300)
    call DEqItemTypeDefineAbilityGranted('I68A', 'A666', 1)

    // |c0090EE90Shadowcaster's Scepter|r (Uncommon)
    // Base: rde0, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I68B', 'A62U', 1)
    call DEqItemTypeDefineAbilityGranted('I68B', 'A648', 1)
    call DEqItemTypeDefineAbilityGranted('I68B', 'AIi3', 1)

    // test_helmet_level_100 (Common)
    // Base: rst1, Class: MISC

    // test_helmet_level_105 (Common)
    // Base: rst1, Class: MISC

    // test_helmet_level_149 (Common)
    // Base: rst1, Class: MISC

    // |cFF1EFF00Copper Chain Helmet|r (Uncommon)
    // Base: rst1, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('I68F', "Head")
    call DEqItemTypeDefineStatGrantedByName('I68F', "Armor", 3)
    call DEqItemTypeDefineStatGrantedByName('I68F', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('I68F', "Strength", 16)
    call DEqItemTypeDefineGoldValue('I68F', 500)

    // |cFF1EFF00Copper Chain Leggings|r (Uncommon)
    // Base: rst1, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('I68G', "Legs")
    call DEqItemTypeDefineStatGrantedByName('I68G', "Agility", 12)
    call DEqItemTypeDefineStatGrantedByName('I68G', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('I68G', "Hitpoints", 50)
    call DEqItemTypeDefineStatGrantedByName('I68G', "Strength", 12)
    call DEqItemTypeDefineGoldValue('I68G', 500)

    // |cFF1EFF00Copper Chain Vest|r (Uncommon)
    // Base: rst1, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('I68H', "Chest")
    call DEqItemTypeDefineStatGrantedByName('I68H', "Agility", 6)
    call DEqItemTypeDefineStatGrantedByName('I68H', "Armor Pct", 0.03)
    call DEqItemTypeDefineStatGrantedByName('I68H', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('I68H', "Strength", 16)
    call DEqItemTypeDefineGoldValue('I68H', 500)

    // |cFF1EFF00Copper Chain Bracers|r (Uncommon)
    // Base: rst1, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('I68I', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('I68I', "Agility", 8)
    call DEqItemTypeDefineStatGrantedByName('I68I', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('I68I', "Strength", 8)
    call DEqItemTypeDefineGoldValue('I68I', 400)

    // |cFF1EFF00Copper Chain Gauntlets|r (Uncommon)
    // Base: rst1, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('I68J', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('I68J', "Agility", 8)
    call DEqItemTypeDefineStatGrantedByName('I68J', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('I68J', "Hitpoints", 50)
    call DEqItemTypeDefineStatGrantedByName('I68J', "Strength", 8)
    call DEqItemTypeDefineGoldValue('I68J', 500)

    // |cFF1EFF00Copper Chain Belt|r (Uncommon)
    // Base: rst1, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('I68K', "Belt")
    call DEqItemTypeDefineStatGrantedByName('I68K', "Agility", 10)
    call DEqItemTypeDefineStatGrantedByName('I68K', "Hitpoints", 100)
    call DEqItemTypeDefineStatGrantedByName('I68K', "Strength", 6)
    call DEqItemTypeDefineGoldValue('I68K', 400)

    // |cFF1EFF00Copper Chain Shoulders|r (Uncommon)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('I68L', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('I68L', "Agility", 14)
    call DEqItemTypeDefineStatGrantedByName('I68L', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('I68L', "Hitpoints", 70)
    call DEqItemTypeDefineStatGrantedByName('I68L', "Strength", 14)
    call DEqItemTypeDefineGoldValue('I68L', 500)

    // |cFF1EFF00Copper Chain Boots|r (Uncommon)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('I68M', "Boots")
    call DEqItemTypeDefineStatGrantedByName('I68M', "Agility", 14)
    call DEqItemTypeDefineStatGrantedByName('I68M', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('I68M', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('I68M', "Strength", 14)
    call DEqItemTypeDefineGoldValue('I68M', 500)

    // Bronze Belt (Common)
    // Base: rst1, Class: MISC

    // Bronze Boots (Common)
    // Base: rst1, Class: MISC

    // Bronze Helmet (Common)
    // Base: rst1, Class: MISC

    // Bronze Gauntlets (Common)
    // Base: rst1, Class: MISC

    // Bronze Chestpiece (Common)
    // Base: rst1, Class: MISC

    // Bronze Leggings (Common)
    // Base: rst1, Class: MISC

    // Bronze Shoulders (Common)
    // Base: rst1, Class: MISC

    // Silvered Bronze Helmet (Common)
    // Base: rst1, Class: MISC

    // Silvered Bronze Breastplate (Common)
    // Base: rst1, Class: MISC

    // Iron Helmet (Common)
    // Base: rst1, Class: MISC

    // Iron Shoulders (Common)
    // Base: rst1, Class: MISC

    // Iron Breastplate (Common)
    // Base: rst1, Class: MISC

    // Iron Bracers (Common)
    // Base: rst1, Class: MISC

    // Iron Gauntlets (Common)
    // Base: rst1, Class: MISC

    // Iron Belt (Common)
    // Base: rst1, Class: MISC

    // Iron Leggings (Common)
    // Base: rst1, Class: MISC

    // Iron Boots (Common)
    // Base: rst1, Class: MISC

    // test_1hwep_level_705 (Common)
    // Base: rst1, Class: MISC

    // test_1hwep_level_749 (Common)
    // Base: rst1, Class: MISC

    // test_2hwep_level_760 (Common)
    // Base: rst1, Class: MISC

    // test_2hwep_level_799 (Common)
    // Base: rst1, Class: MISC

    // test_shield_level_851 (Common)
    // Base: rst1, Class: MISC

    // test_shield_level_899 (Common)
    // Base: rst1, Class: MISC

    // Gnoll Head (Common)
    // Base: bzbe, Class: MISC

    // Stolen Goods (Common)
    // Base: bzbe, Class: MISC

    // Barricade (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I69C', 300)
    call DEqItemTypeDefineAbilityGranted('I69C', 'A65J', 1)

    // Healing Rain (Common)
    // Base: tdex, Class: MISC

    // Chain Heal (Common)
    // Base: tdex, Class: MISC

    // Healing Wave (Common)
    // Base: tdex, Class: MISC

    // Fire Shock (Common)
    // Base: tdex, Class: MISC

    // Summon Elemental (Common)
    // Base: tdex, Class: MISC

    // Bloodlust (Common)
    // Base: tdex, Class: MISC

    // Ghost Wolf (Common)
    // Base: tdex, Class: MISC

    // Voodoo Spirits (Common)
    // Base: tdex, Class: MISC

    // Flurry (Common)
    // Base: tdex, Class: MISC

    // Feral Spirits (Common)
    // Base: tdex, Class: MISC

    // Reincarnation (Common)
    // Base: tdex, Class: MISC

    // |cFFFFFFFFGnoll Pillage|r (Common)
    // Base: bzbe, Class: Quest

    // Orb of Lifesteal (Common)
    // Base: wneu, Class: MISC
    call DEqItemTypeDefineGoldValue('I6A5', 2000)
    call DEqItemTypeDefineAbilityGranted('I6A5', 'A690', 1)
    call DEqItemTypeDefineAbilityGranted('I6A5', 'AI2m', 1)
    call DEqItemTypeDefineAbilityGranted('I6A5', 'A692', 1)

    // Light Leather (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6A6', 50)

    // Medium Leather (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6A7', 50)

    // Heavy Leather (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6A8', 50)

    // Rugged Leather (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6A9', 50)

    // Thick Leather (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6AA', 50)

    // Big Bear Tooth (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I6AB', 250)

    // Frost Shock (Common)
    // Base: tdex, Class: MISC

    // Nature Shock (Common)
    // Base: tdex, Class: MISC

    // Murloc Fin (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I6AE', 100)

    // Rejuvenation (Common)
    // Base: tdex, Class: MISC

    // Spiritmender (Common)
    // Base: tdex, Class: MISC

    // Earthwarden (Common)
    // Base: tdex, Class: MISC

    // Seeds of Life (Common)
    // Base: dtsb, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AL', 'A6AM', 1)

    // Ancestral Ward (Common)
    // Base: tdex, Class: MISC

    // Supply Crate (Common)
    // Base: bzbe, Class: MISC

    // Spiritual Healing (Common)
    // Base: tdex, Class: MISC

    // Wolf Jawbone (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I6AR', 50)

    // Large Hoof (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I6AS', 25)

    // |c00A9A9A9Worn Boots|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AT', 'AIa1', 1)

    // |c00A9A9A9Worn Gloves|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AU', 'A66A', 1)

    // |c00A9A9A9Dusty Cap|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AV', 'AIi1', 1)

    // |c00A9A9A9Ragged Cloak|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AW', 'AIa1', 1)

    // |c00A9A9A9Worn Chainmail|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AX', 'AIs1', 1)

    // |c00A9A9A9Frayed Bindings|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AY', 'AIs1', 1)

    // |c00A9A9A9Frayed Girdle|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6AZ', 'AId1', 1)

    // |c00A9A9A9Worn Pants|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B0', 'A66A', 1)

    // |c00A9A9A9Blunt Sword|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B1', 'AItg', 1)

    // |c00A9A9A9Chipped Axe|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B2', 'A6AT', 1)
    call DEqItemTypeDefineAbilityGranted('I6B2', 'AItg', 1)

    // |c00A9A9A9Dulled Dagger|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B3', 'AItg', 1)

    // |c00A9A9A9Rusted Battleaxe|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B4', 'A6AS', 1)
    call DEqItemTypeDefineAbilityGranted('I6B4', 'AIs1', 1)
    call DEqItemTypeDefineAbilityGranted('I6B4', 'AItg', 1)

    // |c00A9A9A9Warped Staff|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B5', 'AIi1', 1)

    // |cFFFFFFFFDented Shield|r (Common)
    // Base: rst1, Class: Shield
    call DEqItemTypeDefineAllowedSlotByName('I6B6', "OffHand")
    call DEqItemTypeDefineShieldBlock('I6B6', 50)
    call DEqItemTypeDefineGoldValue('I6B6', 150)
    call DEqItemTypeDefineAbilityGranted('I6B6', 'A6AR', 1)
    call DEqItemTypeDefineAbilityGranted('I6B6', 'AId1', 1)

    // |c00A9A9A9Cracked Aegis|r (Common)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B7', 'A65H', 1)
    call DEqItemTypeDefineAbilityGranted('I6B7', 'AIs1', 1)
    call DEqItemTypeDefineAbilityGranted('I6B7', 'AId1', 1)

    // |c0090EE90Belt of Wise Man|r (Uncommon)
    // Base: bgst, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B8', 'AIi6', 1)

    // |c0090EE90Belt of Tiger Trainer|r (Uncommon)
    // Base: bgst, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6B9', 'AIa6', 1)

    // Crystal Water (Common)
    // Base: pclr, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BA', 350)
    call DEqItemTypeDefineAbilityGranted('I6BA', 'A6AU', 1)

    // Purified Water (Common)
    // Base: pclr, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BB', 150)
    call DEqItemTypeDefineAbilityGranted('I6BB', 'A6AV', 1)

    // Greater Healing Salve (Common)
    // Base: hslv, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BC', 150)
    call DEqItemTypeDefineAbilityGranted('I6BC', 'A6AW', 1)

    // Minor Healing Potion (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BD', 'A6AX', 1)

    // Major Healing Potion (Common)
    // Base: pghe, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BE', 600)
    call DEqItemTypeDefineAbilityGranted('I6BE', 'A6B0', 1)

    // Greater Restoration Potion (Common)
    // Base: pres, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BF', 800)
    call DEqItemTypeDefineAbilityGranted('I6BF', 'A6B2', 1)

    // Minor Replenishment Potion (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BG', 'A6B4', 1)

    // Greater Replenishment Potion (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BH', 600)
    call DEqItemTypeDefineAbilityGranted('I6BH', 'A6B6', 1)

    // Scroll of Greater Healing (Common)
    // Base: shea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BI', 400)
    call DEqItemTypeDefineAbilityGranted('I6BI', 'A6B8', 1)

    // Scroll of Major Healing (Common)
    // Base: shea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BJ', 600)
    call DEqItemTypeDefineAbilityGranted('I6BJ', 'A6B9', 1)

    // Scroll of Greater Mana (Common)
    // Base: sman, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BK', 400)
    call DEqItemTypeDefineAbilityGranted('I6BK', 'A6BB', 1)

    // Scroll of Major Mana (Common)
    // Base: sman, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BL', 600)
    call DEqItemTypeDefineAbilityGranted('I6BL', 'A6BC', 1)

    // Scroll of Greater Protection (Common)
    // Base: spro, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BM', 400)
    call DEqItemTypeDefineAbilityGranted('I6BM', 'A6BE', 1)

    // Scroll of Major Protection (Common)
    // Base: spro, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BN', 600)
    call DEqItemTypeDefineAbilityGranted('I6BN', 'A6BF', 1)

    // Scroll of Greater Regeneration (Common)
    // Base: sreg, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BO', 300)
    call DEqItemTypeDefineAbilityGranted('I6BO', 'A6BH', 1)

    // Scroll of Major Regeneration (Common)
    // Base: sreg, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BP', 600)
    call DEqItemTypeDefineAbilityGranted('I6BP', 'A6BI', 1)

    // Scroll of Greater Restoration (Common)
    // Base: sres, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BQ', 800)
    call DEqItemTypeDefineAbilityGranted('I6BQ', 'A6BK', 1)

    // Scroll of Major Restoration (Common)
    // Base: sres, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BR', 1000)
    call DEqItemTypeDefineAbilityGranted('I6BR', 'A6BL', 1)

    // Minor Mana Potion (Common)
    // Base: pman, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BS', 150)
    call DEqItemTypeDefineAbilityGranted('I6BS', 'A6BM', 1)

    // Major Mana Potion (Common)
    // Base: pman, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BT', 600)
    call DEqItemTypeDefineAbilityGranted('I6BT', 'A6BO', 1)

    // Unknown Item (I6BU) (Common)
    // Base: gold, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BU', 'A6BQ', 1)

    // Unknown Item (I6BV) (Common)
    // Base: gold, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BV', 'A6BR', 1)

    // Unknown Item (I6BW) (Common)
    // Base: gold, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BW', 'A6BS', 1)

    // |c0090EE90Gem of Lesser Health|r (Uncommon)
    // Base: rhth, Class: MISC
    call DEqItemTypeDefineGoldValue('I6BX', 450)
    call DEqItemTypeDefineAbilityGranted('I6BX', 'A63E', 1)

    // |c0090EE90Gem of Health|r (Uncommon)
    // Base: rhth, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BY', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I6BY', 'A643', 1)

    // |c0090EE90Gem of Greater Health|r (Uncommon)
    // Base: rhth, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6BZ', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I6BZ', 'A63Z', 1)

    // |c0090EE90Gem of Major Health|r (Uncommon)
    // Base: rhth, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6C0', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I6C0', 'A63Z', 1)
    call DEqItemTypeDefineAbilityGranted('I6C0', 'A63Z', 1)

    // |c0090EE90Claws of Attack +20|r (Uncommon)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineGoldValue('I6C1', 1000)
    call DEqItemTypeDefineAbilityGranted('I6C1', 'AItj', 1)
    call DEqItemTypeDefineAbilityGranted('I6C1', 'AItf', 1)

    // |c0090EE90Claws of Attack +24|r (Uncommon)
    // Base: ratf, Class: MISC
    call DEqItemTypeDefineGoldValue('I6C2', 1200)
    call DEqItemTypeDefineAbilityGranted('I6C2', 'AItx', 1)
    call DEqItemTypeDefineAbilityGranted('I6C2', 'AIti', 1)

    // Tent (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineGoldValue('I6C4', 500)
    call DEqItemTypeDefineAbilityGranted('I6C4', 'A6CH', 1)

    // |c0090EE90Essence of Fire|r (Uncommon)
    // Base: phea, Class: MISC

    // |c0090EE90Essence of Water|r (Uncommon)
    // Base: phea, Class: MISC

    // |c0090EE90Essence of Air|r (Uncommon)
    // Base: phea, Class: MISC

    // |c0090EE90Essence of Earth|r (Uncommon)
    // Base: phea, Class: MISC

    // |c0090EE90Stealth Cloak|r (Uncommon)
    // Base: rst1, Class: MISC
    call DEqItemTypeDefineGoldValue('I6C9', 1200)

    // Rock (Common)
    // Base: wneg, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CA', 25)
    call DEqItemTypeDefineAbilityGranted('I6CA', 'A6CT', 1)

    // |c00800080Blazing Obsidian Sharpblade|r (Epic)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CB', 20000)
    call DEqItemTypeDefineAbilityGranted('I6CB', 'A65E', 1)
    call DEqItemTypeDefineAbilityGranted('I6CB', 'AItx', 1)
    call DEqItemTypeDefineAbilityGranted('I6CB', 'AItf', 1)
    call DEqItemTypeDefineAbilityGranted('I6CB', 'A6D4', 1)

    // |c00800080Cloak of Dragonbound Mountain|r (Epic)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CC', 10000)
    call DEqItemTypeDefineAbilityGranted('I6CC', 'A640', 1)
    call DEqItemTypeDefineAbilityGranted('I6CC', 'AId8', 1)

    // |c00800080Crown of of the Molten Golem King|r (Epic)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CD', 10000)
    call DEqItemTypeDefineAbilityGranted('I6CD', 'A6C4', 1)
    call DEqItemTypeDefineAbilityGranted('I6CD', 'A6D5', 1)
    call DEqItemTypeDefineAbilityGranted('I6CD', 'A6D6', 1)

    // |c00800080Dragonforged Warboots|r (Epic)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CE', 10000)
    call DEqItemTypeDefineAbilityGranted('I6CE', 'A6D7', 1)
    call DEqItemTypeDefineAbilityGranted('I6CE', 'A6D8', 1)
    call DEqItemTypeDefineAbilityGranted('I6CE', 'A6D6', 1)

    // |c00FF8000Infernal Sigil of Colossus|r (Common)
    // Base: crdt, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CF', 30000)
    call DEqItemTypeDefineAbilityGranted('I6CF', 'A6D9', 1)
    call DEqItemTypeDefineAbilityGranted('I6CF', 'AI2m', 1)
    call DEqItemTypeDefineAbilityGranted('I6CF', 'A63Z', 1)

    // Belt03 (Common)
    // Base: rst1, Class: MISC

    // Net (Common)
    // Base: silk, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CH', 500)
    call DEqItemTypeDefineAbilityGranted('I6CH', 'A6DD', 1)

    // Frost Trap (Common)
    // Base: gobm, Class: MISC
    call DEqItemTypeDefineGoldValue('I6CI', 250)
    call DEqItemTypeDefineAbilityGranted('I6CI', 'A6DK', 1)

    // |cFFA335EEJin'Zun's Fishing Pole|r (Epic)
    // Base: bzbe, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6CJ', "MainHand")
    call DEqItemTypeDefineAs2Handed('I6CJ')
    call DEqItemTypeDefineAbilityGranted('I6CJ', 'A6DL', 1)

    // Whirlwind (Common)
    // Base: tdex, Class: MISC

    // Traveler's Journal (Common)
    // Base: dtsb, Class: MISC
    call DEqItemTypeDefineAbilityGranted('I6CL', 'A6DU', 1)

    // Shiny Bauble (Common)
    // Base: bzbe, Class: Consumable

    // Nightcrawlers (Common)
    // Base: bzbe, Class: Consumable

    // Bright Baubles (Common)
    // Base: bzbe, Class: Consumable

    // Aquadynamic Fish (Common)
    // Base: bzbe, Class: Consumable

    // |cFFFFFFFFFishing Pole|r (Common)
    // Base: bzbe, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6CQ', "MainHand")
    call DEqItemTypeDefineAs2Handed('I6CQ')
    call DEqItemTypeDefineAbilityGranted('I6CQ', 'A6DL', 1)

    // |cFF1EFF00Strong Fishing Pole|r (Uncommon)
    // Base: bzbe, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6CR', "MainHand")
    call DEqItemTypeDefineAs2Handed('I6CR')
    call DEqItemTypeDefineStatGrantedByName('I6CR', "Fishing", 5)
    call DEqItemTypeDefineAbilityGranted('I6CR', 'A6DL', 1)

    // |cFF0070DDBig Iron Fishing Pole|r (Rare)
    // Base: bzbe, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6CS', "MainHand")
    call DEqItemTypeDefineAs2Handed('I6CS')
    call DEqItemTypeDefineStatGrantedByName('I6CS', "Fishing", 20)
    call DEqItemTypeDefineAbilityGranted('I6CS', 'A6DL', 1)

    // |cFFFF8000ProMaster Fishing Pole 2000|r (Legendary)
    // Base: bzbe, Class: Two-Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6CT', "MainHand")
    call DEqItemTypeDefineAs2Handed('I6CT')
    call DEqItemTypeDefineStatGrantedByName('I6CT', "Fishing", 100)
    call DEqItemTypeDefineAbilityGranted('I6CT', 'A6DL', 1)

    // |cFFFFFFFFRaw Brilliant Smallfish|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CU', 5)
    call DEqItemTypeDefineAbilityGranted('I6CU', 'A60V', 1)

    // |cFFFFFFFFRaw Slitherskin Mackerel|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CV', 5)
    call DEqItemTypeDefineAbilityGranted('I6CV', 'A60V', 1)

    // |cFFFFFFFFSickly Looking Fish|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CW', 4)
    call DEqItemTypeDefineAbilityGranted('I6CW', 'A60V', 1)

    // |cFFFFFFFFOily Blackmouth|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CX', 12)
    call DEqItemTypeDefineAbilityGranted('I6CX', 'A60V', 1)

    // |cFFFFFFFFRaw Longjaw Mud Snapper|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CY', 10)
    call DEqItemTypeDefineAbilityGranted('I6CY', 'A60V', 1)

    // |cFFFFFFFFRaw Rainbow Fin Albacore|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6CZ', 12)
    call DEqItemTypeDefineAbilityGranted('I6CZ', 'A60V', 1)

    // |cFFFFFFFFRaw Bristle Whisker Catfish|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D0', 15)
    call DEqItemTypeDefineAbilityGranted('I6D0', 'A60V', 1)

    // |cFFFFFFFFRaw Loch Frenzy|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D1', 16)
    call DEqItemTypeDefineAbilityGranted('I6D1', 'A60V', 1)

    // |cFFFFFFFFFirefin Snapper|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D2', 20)
    call DEqItemTypeDefineAbilityGranted('I6D2', 'A60V', 1)

    // |cFF1EFF00Deviate Fish|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D3', 35)
    call DEqItemTypeDefineAbilityGranted('I6D3', 'A60V', 1)

    // |cFFFFFFFFRaw Sagefish|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D4', 22)
    call DEqItemTypeDefineAbilityGranted('I6D4', 'A60V', 1)

    // |cFF1EFF00Raw Greater Sagefish|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D5', 40)
    call DEqItemTypeDefineAbilityGranted('I6D5', 'A60V', 1)

    // |cFFFFFFFFRaw Rockscale Cod|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D6', 25)
    call DEqItemTypeDefineAbilityGranted('I6D6', 'A60V', 1)

    // |cFFFFFFFFRaw Mithril Head Trout|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D7', 30)
    call DEqItemTypeDefineAbilityGranted('I6D7', 'A60V', 1)

    // |cFFFFFFFFRaw Spotted Yellowtail|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D8', 32)
    call DEqItemTypeDefineAbilityGranted('I6D8', 'A60V', 1)

    // |cFF1EFF00Raw Glossy Mightfish|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6D9', 45)
    call DEqItemTypeDefineAbilityGranted('I6D9', 'A60V', 1)

    // |cFFFFFFFFRaw Redgill|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DA', 36)
    call DEqItemTypeDefineAbilityGranted('I6DA', 'A60V', 1)

    // |cFF1EFF00Nightfin Snapper|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DB', 55)
    call DEqItemTypeDefineAbilityGranted('I6DB', 'A60V', 1)

    // |cFF1EFF00Sunscale Salmon|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DC', 55)
    call DEqItemTypeDefineAbilityGranted('I6DC', 'A60V', 1)

    // |cFF1EFF00Stonescale Eel|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DD', 65)
    call DEqItemTypeDefineAbilityGranted('I6DD', 'A60V', 1)

    // |cFF1EFF00Raw Whitescale Salmon|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DE', 70)
    call DEqItemTypeDefineAbilityGranted('I6DE', 'A60V', 1)

    // |cFF1EFF00Darkclaw Lobster|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DF', 75)
    call DEqItemTypeDefineAbilityGranted('I6DF', 'A60V', 1)

    // |cFF1EFF00Winter Squid|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DG', 60)
    call DEqItemTypeDefineAbilityGranted('I6DG', 'A60V', 1)

    // |cFFFFFFFFRaw Summer Bass|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DH', 34)
    call DEqItemTypeDefineAbilityGranted('I6DH', 'A60V', 1)

    // |cFFFFFFFFRaw Tigerseye Eel|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DI', 24)
    call DEqItemTypeDefineAbilityGranted('I6DI', 'A60V', 1)

    // |cFFFFFFFFBarbed Gill Trout|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DJ', 28)
    call DEqItemTypeDefineAbilityGranted('I6DJ', 'A60V', 1)

    // |cFF0070DDFurious Crawdad|r (Rare)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DK', 100)
    call DEqItemTypeDefineAbilityGranted('I6DK', 'A60V', 1)

    // |cFFFFFFFF10 Pound Mud Snapper|r (Common)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DL', "MainHand")
    call DEqItemTypeDefineGoldValue('I6DL', 15)
    call DEqItemTypeDefineAbilityGranted('I6DL', 'A0CN', 1)
    call DEqItemTypeDefineAbilityGranted('I6DL', 'A07L', 1)

    // |cFFFFFFFF12 Pound Mud Snapper|r (Common)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DM', "MainHand")
    call DEqItemTypeDefineGoldValue('I6DM', 18)
    call DEqItemTypeDefineAbilityGranted('I6DM', 'A0CN', 1)
    call DEqItemTypeDefineAbilityGranted('I6DM', 'A07L', 1)

    // |cFF1EFF0015 Pound Mud Snapper|r (Uncommon)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DN', "MainHand")
    call DEqItemTypeDefineGoldValue('I6DN', 22)
    call DEqItemTypeDefineAbilityGranted('I6DN', 'A0CN', 1)
    call DEqItemTypeDefineAbilityGranted('I6DN', 'A07L', 1)

    // |cFFFFFFFF17 Pound Catfish|r (Common)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DO', "MainHand")
    call DEqItemTypeDefineGoldValue('I6DO', 28)
    call DEqItemTypeDefineAbilityGranted('I6DO', 'A0CN', 1)
    call DEqItemTypeDefineAbilityGranted('I6DO', 'A07M', 1)

    // |cFF1EFF0022 Pound Catfish|r (Uncommon)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DP', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I6DP', "Damage", 2)
    call DEqItemTypeDefineGoldValue('I6DP', 35)
    call DEqItemTypeDefineAbilityGranted('I6DP', 'A0CN', 1)

    // |cFF0070DD26 Pound Catfish|r (Rare)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DQ', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I6DQ', "Damage", 4)
    call DEqItemTypeDefineStatGrantedByName('I6DQ', "Fishing", 25)
    call DEqItemTypeDefineGoldValue('I6DQ', 42)
    call DEqItemTypeDefineAbilityGranted('I6DQ', 'A0CN', 1)

    // |cFF1EFF00Steelscale Crushfish|r (Uncommon)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DR', "MainHand")
    call DEqItemTypeDefineGoldValue('I6DR', 70)
    call DEqItemTypeDefineAbilityGranted('I6DR', 'A0CN', 1)
    call DEqItemTypeDefineAbilityGranted('I6DR', 'A07N', 1)

    // |cFF1EFF00Rockhide Strongfish|r (Uncommon)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DS', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I6DS', "Thorns", 10)
    call DEqItemTypeDefineGoldValue('I6DS', 85)
    call DEqItemTypeDefineAbilityGranted('I6DS', 'A0CN', 1)

    // |cFF0070DDDark Herring|r (Rare)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DT', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I6DT', "Block Chance", 5)
    call DEqItemTypeDefineGoldValue('I6DT', 120)
    call DEqItemTypeDefineAbilityGranted('I6DT', 'A0CN', 1)

    // |cFFFFFFFFBroken Wine Bottle|r (Common)
    // Base: bzbe, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('I6DU', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('I6DU', "Damage", 2)
    call DEqItemTypeDefineGoldValue('I6DU', 25)
    call DEqItemTypeDefineAbilityGranted('I6DU', 'A0CJ', 1)

    // |cFFFFFFFFFirefin Oil|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6DV', 24)

    // |cFF1EFF00Elemental Fire|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6DW', 45)

    // |cFFFFFFFFVolcanic Scale|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6DX', 30)

    // |cFF0070DDSmoldering Pearl|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6DY', 90)

    // |cFF1EFF00Lavafin Snapper|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6DZ', 42)
    call DEqItemTypeDefineAbilityGranted('I6DZ', 'A60V', 1)

    // |cFF1EFF00Elemental Water|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E0', 45)

    // |cFFFFFFFFPure Water Globule|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E1', 22)

    // |cFF0070DDTidal Pearl|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E2', 86)

    // |cFFFFFFFFEnchanted Seaweed|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E3', 20)

    // |cFFFFFFFFAzurefin Minnow|r (Common)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6E4', 24)
    call DEqItemTypeDefineAbilityGranted('I6E4', 'A60V', 1)

    // |cFF1EFF00Fel-Touched Fish|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6E5', 48)
    call DEqItemTypeDefineAbilityGranted('I6E5', 'A60V', 1)

    // |cFFFFFFFFBlack Ichor|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E6', 28)

    // |cFF1EFF00Demonic Scale|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E7', 52)

    // |cFF0070DDCorrupted Pearl|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E8', 96)

    // |cFF0070DDAbyssal Eye|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6E9', 110)

    // Nightscale Eel (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6EA', 44)
    call DEqItemTypeDefineAbilityGranted('I6EA', 'A60V', 1)

    // |cFF1EFF00Moonlit Pearl|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EB', 60)

    // |cFFFFFFFFDarkwater Clam|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EC', 26)

    // Shadowfin (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6ED', 46)
    call DEqItemTypeDefineAbilityGranted('I6ED', 'A60V', 1)

    // |cFF0070DDOily Black Pearl|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EE', 84)

    // Barnacled Crate (Common)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EF', 65)

    // Waterlogged Lockbox (Rare)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EG', 130)

    // Sailor's Coinpurse (Common)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EH', 70)

    // Ancient Compass (Rare)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EI', 145)

    // Tarnished Goblet (Common)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EJ', 52)

    // Sealed Message Bottle (Uncommon)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EK', 76)

    // |cFFFFFFFFShipwreck Debris|r (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I6EL', 18)

    // |cFF1EFF00Polished Pearl|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EM', 58)

    // |cFFFFFFFFStranglekelp Clump|r (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I6EN', 18)

    // Broken Fishing Hook (Common)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6EO', 10)

    // |cFFFFFFFFRusted Anchor Fragment|r (Common)
    // Base: bzbe, Class: MISC
    call DEqItemTypeDefineGoldValue('I6EP', 22)

    // |cFF1EFF00Glowing Fish Scale|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EQ', 34)

    // |cFF0070DDPrismatic Shell|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6ER', 94)

    // |cFFFFFFFFDriftwood Bundle|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6ES', 14)

    // Sunken Silver Ring (Uncommon)
    // Base: bzbe, Class: Other
    call DEqItemTypeDefineGoldValue('I6ET', 88)

    // |cFF0070DDDrowned Sapphire|r (Rare)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EU', 120)

    // |cFFFFFFFFNoxious Fin|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EV', 30)

    // |cFFFFFFFFFelweed Bundle|r (Common)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EW', 32)

    // |cFF1EFF00Searing Eel|r (Uncommon)
    // Base: rej3, Class: Consumable
    call DEqItemTypeDefineGoldValue('I6EX', 56)
    call DEqItemTypeDefineAbilityGranted('I6EX', 'A60V', 1)

    // |cFF1EFF00Magma Clam|r (Uncommon)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EY', 64)

    // |cFFA335EEArcane Pearl|r (Epic)
    // Base: bzbe, Class: Material
    call DEqItemTypeDefineGoldValue('I6EZ', 118)

    // |c009D9D9DFrayed Wolf Pelt|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a0', 12)

    // |c009D9D9DCracked Boar Tusk|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0a1', 9)

    // |c009D9D9DPolished Stag Antler|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a2', 18)

    // |c001EFF00Bear Grease|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a3', 45)

    // |c009D9D9DGnoll Coin Pouch|r (Common)
    // Base: bzbe, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0a4', 24)

    // |c009D9D9DBent Gnoll Dagger|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0a5', 32)

    // |c009D9D9DMurloc Gill Slime|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a6', 20)

    // |c001EFF00Briny Murloc Scale|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a7', 60)

    // |c001EFF00Makrura Chitin Plate|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0a8', 75)

    // |c009D9D9DMakrura Claw|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0a9', 36)

    // |c009D9D9DShed Snake Scale|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b0', 15)

    // |c001EFF00Clouded Venom Fang|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b1', 90)

    // |c009D9D9DSticky Frog Mucus|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b2', 14)

    // |c009D9D9DGlassy Frog Eye|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0b3', 18)

    // |c009D9D9DCracked Crawler Shell|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b4', 22)

    // |c001EFF00Sea-Salt Gland|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b5', 70)

    // |c001EFF00Charred Whelp Horn|r (Uncommon)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b6', 110)

    // |c000070DDEmber-Warmed Scale|r (Rare)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b7', 240)

    // |c009D9D9DGrave Moss|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0b8', 30)

    // |c009D9D9DRotten Rib|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0b9', 16)

    // |c009D9D9DRagged Banner Scrap|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0c0', 20)

    // |c009D9D9DTarnished Button|r (Common)
    // Base: rst1, Class: Miscellaneous
    call DEqItemTypeDefineGoldValue('j0c1', 8)

    // |c009D9D9DDull Copper Buckle|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0c2', 28)

    // |c009D9D9DEmpty Vial|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0c3', 12)

    // |c009D9D9DCoarse Thread Spool|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0c4', 18)

    // |c009D9D9DCampfire Ash|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j0c5', 10)

    // |cFF1EFF00Smoked Wolf Jerky|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0c6', 65)
    call DEqItemTypeDefineAbilityGranted('j0c6', 'A0F5', 1)

    // |cFF1EFF00Roasted Stag Haunch|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0c7', 70)
    call DEqItemTypeDefineAbilityGranted('j0c7', 'A0F5', 1)

    // |cFF1EFF00Bear Fat Biscuit|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0c8', 85)
    call DEqItemTypeDefineAbilityGranted('j0c8', 'A0F5', 1)

    // |cFF1EFF00Boiled Makrura Claw|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0c9', 90)
    call DEqItemTypeDefineAbilityGranted('j0c9', 'A0F5', 1)

    // |cFF1EFF00Spiced Snake Strips|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0d0', 75)
    call DEqItemTypeDefineAbilityGranted('j0d0', 'A0F5', 1)

    // |cFF1EFF00Fried Crawler Cake|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j0d1', 95)
    call DEqItemTypeDefineAbilityGranted('j0d1', 'A0F5', 1)

    // |c009D9D9DMistwoven Hood|r (Common)
    // Base: rst1, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a0', "Head")
    call DEqItemTypeDefineStatGrantedByName('j1a0', "Intelligence", 2)
    call DEqItemTypeDefineStatGrantedByName('j1a0', "Mana", 25)
    call DEqItemTypeDefineGoldValue('j1a0', 120)

    // |c009D9D9DMistwoven Mantle|r (Common)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('j1a1', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('j1a1', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a1', "Intelligence", 2)
    call DEqItemTypeDefineStatGrantedByName('j1a1', "Mana", 25)
    call DEqItemTypeDefineGoldValue('j1a1', 140)

    // |c001EFF00Mistwoven Robe|r (Uncommon)
    // Base: rst1, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a2', "Chest")
    call DEqItemTypeDefineStatGrantedByName('j1a2', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a2', "Intelligence", 4)
    call DEqItemTypeDefineStatGrantedByName('j1a2', "Mana", 50)
    call DEqItemTypeDefineGoldValue('j1a2', 300)

    // |c009D9D9DMistwoven Wraps|r (Common)
    // Base: rst1, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('j1a3', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('j1a3', "Intelligence", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a3', "Mana", 25)
    call DEqItemTypeDefineGoldValue('j1a3', 100)

    // |c001EFF00Mistwoven Gloves|r (Uncommon)
    // Base: rst1, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a4', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('j1a4', "Intelligence", 3)
    call DEqItemTypeDefineStatGrantedByName('j1a4', "Spell Power", 10)
    call DEqItemTypeDefineGoldValue('j1a4', 260)

    // |c009D9D9DMistwoven Sash|r (Common)
    // Base: rst1, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('j1a5', "Belt")
    call DEqItemTypeDefineStatGrantedByName('j1a5', "Hitpoints", 25)
    call DEqItemTypeDefineStatGrantedByName('j1a5', "Intelligence", 2)
    call DEqItemTypeDefineGoldValue('j1a5', 110)

    // |c001EFF00Mistwoven Trousers|r (Uncommon)
    // Base: rst1, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a6', "Legs")
    call DEqItemTypeDefineStatGrantedByName('j1a6', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a6', "Intelligence", 3)
    call DEqItemTypeDefineStatGrantedByName('j1a6', "Mana", 50)
    call DEqItemTypeDefineGoldValue('j1a6', 280)

    // |c009D9D9DMistwoven Slippers|r (Common)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a7', "Boots")
    call DEqItemTypeDefineStatGrantedByName('j1a7', "Agility", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a7', "Intelligence", 2)
    call DEqItemTypeDefineStatGrantedByName('j1a7', "Movement Speed", 2)
    call DEqItemTypeDefineGoldValue('j1a7', 130)

    // |c009D9D9DTrailscarred Leather Coif|r (Common)
    // Base: rst1, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('j1a8', "Head")
    call DEqItemTypeDefineStatGrantedByName('j1a8', "Agility", 4)
    call DEqItemTypeDefineStatGrantedByName('j1a8', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a8', "Hitpoints", 50)
    call DEqItemTypeDefineGoldValue('j1a8', 180)

    // |c009D9D9DTrailscarred Leather Shoulders|r (Common)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('j1a9', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('j1a9', "Agility", 4)
    call DEqItemTypeDefineStatGrantedByName('j1a9', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1a9', "Strength", 2)
    call DEqItemTypeDefineGoldValue('j1a9', 190)

    // |c001EFF00Trailscarred Leather Jerkin|r (Uncommon)
    // Base: rst1, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b0', "Chest")
    call DEqItemTypeDefineStatGrantedByName('j1b0', "Agility", 6)
    call DEqItemTypeDefineStatGrantedByName('j1b0', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('j1b0', "Hitpoints", 75)
    call DEqItemTypeDefineGoldValue('j1b0', 420)

    // |c009D9D9DTrailscarred Leather Bracers|r (Common)
    // Base: rst1, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('j1b1', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('j1b1', "Agility", 3)
    call DEqItemTypeDefineStatGrantedByName('j1b1', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1b1', "Critical Chance", 1)
    call DEqItemTypeDefineGoldValue('j1b1', 160)

    // |c001EFF00Trailscarred Leather Gloves|r (Uncommon)
    // Base: rst1, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b2', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('j1b2', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('j1b2', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1b2', "Damage", 5)
    call DEqItemTypeDefineGoldValue('j1b2', 390)

    // |c009D9D9DTrailscarred Leather Belt|r (Common)
    // Base: rst1, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('j1b3', "Belt")
    call DEqItemTypeDefineStatGrantedByName('j1b3', "Agility", 3)
    call DEqItemTypeDefineStatGrantedByName('j1b3', "Hitpoints", 50)
    call DEqItemTypeDefineStatGrantedByName('j1b3', "Strength", 3)
    call DEqItemTypeDefineGoldValue('j1b3', 170)

    // |c001EFF00Trailscarred Leather Legguards|r (Uncommon)
    // Base: rst1, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b4', "Legs")
    call DEqItemTypeDefineStatGrantedByName('j1b4', "Agility", 6)
    call DEqItemTypeDefineStatGrantedByName('j1b4', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('j1b4', "Hitpoints", 50)
    call DEqItemTypeDefineGoldValue('j1b4', 410)

    // |c009D9D9DTrailscarred Leather Boots|r (Common)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b5', "Boots")
    call DEqItemTypeDefineStatGrantedByName('j1b5', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('j1b5', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j1b5', "Movement Speed", 3)
    call DEqItemTypeDefineGoldValue('j1b5', 180)

    // |c001EFF00Stormlink Coif|r (Uncommon)
    // Base: rst1, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b6', "Head")
    call DEqItemTypeDefineStatGrantedByName('j1b6', "Agility", 3)
    call DEqItemTypeDefineStatGrantedByName('j1b6', "Armor", 3)
    call DEqItemTypeDefineStatGrantedByName('j1b6', "Strength", 5)
    call DEqItemTypeDefineGoldValue('j1b6', 520)

    // |c001EFF00Stormlink Spaulders|r (Uncommon)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('j1b7', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('j1b7', "Agility", 4)
    call DEqItemTypeDefineStatGrantedByName('j1b7', "Armor", 3)
    call DEqItemTypeDefineStatGrantedByName('j1b7', "Hitpoints", 50)
    call DEqItemTypeDefineStatGrantedByName('j1b7', "Strength", 4)
    call DEqItemTypeDefineGoldValue('j1b7', 540)

    // |c000070DDStormlink Hauberk|r (Rare)
    // Base: rst1, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('j1b8', "Chest")
    call DEqItemTypeDefineStatGrantedByName('j1b8', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('j1b8', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('j1b8', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('j1b8', "Strength", 8)
    call DEqItemTypeDefineGoldValue('j1b8', 1200)

    // |c001EFF00Stormlink Wristguards|r (Uncommon)
    // Base: rst1, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('j1b9', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('j1b9', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('j1b9', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('j1b9', "Strength", 3)
    call DEqItemTypeDefineGoldValue('j1b9', 430)

    // |c000070DDStormlink Grips|r (Rare)
    // Base: rst1, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c0', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('j1c0', "Agility", 6)
    call DEqItemTypeDefineStatGrantedByName('j1c0', "Armor", 3)
    call DEqItemTypeDefineStatGrantedByName('j1c0', "Critical Chance", 2)
    call DEqItemTypeDefineStatGrantedByName('j1c0', "Strength", 6)
    call DEqItemTypeDefineGoldValue('j1c0', 1000)

    // |c001EFF00Stormlink Girdle|r (Uncommon)
    // Base: rst1, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('j1c1', "Belt")
    call DEqItemTypeDefineStatGrantedByName('j1c1', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('j1c1', "Hitpoints", 100)
    call DEqItemTypeDefineStatGrantedByName('j1c1', "Strength", 5)
    call DEqItemTypeDefineGoldValue('j1c1', 460)

    // |c000070DDStormlink Legguards|r (Rare)
    // Base: rst1, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c2', "Legs")
    call DEqItemTypeDefineStatGrantedByName('j1c2', "Agility", 7)
    call DEqItemTypeDefineStatGrantedByName('j1c2', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('j1c2', "Hitpoints", 100)
    call DEqItemTypeDefineStatGrantedByName('j1c2', "Strength", 7)
    call DEqItemTypeDefineGoldValue('j1c2', 1150)

    // |c001EFF00Stormlink Sabatons|r (Uncommon)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c3', "Boots")
    call DEqItemTypeDefineStatGrantedByName('j1c3', "Agility", 5)
    call DEqItemTypeDefineStatGrantedByName('j1c3', "Armor", 2)
    call DEqItemTypeDefineStatGrantedByName('j1c3', "Movement Speed", 3)
    call DEqItemTypeDefineStatGrantedByName('j1c3', "Strength", 5)
    call DEqItemTypeDefineGoldValue('j1c3', 480)

    // |c000070DDIronbound Greathelm|r (Rare)
    // Base: rst1, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c4', "Head")
    call DEqItemTypeDefineStatGrantedByName('j1c4', "Armor", 6)
    call DEqItemTypeDefineStatGrantedByName('j1c4', "Hitpoints", 200)
    call DEqItemTypeDefineStatGrantedByName('j1c4', "Strength", 10)
    call DEqItemTypeDefineGoldValue('j1c4', 1450)

    // |c000070DDIronbound Pauldrons|r (Rare)
    // Base: bspd, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('j1c5', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('j1c5', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('j1c5', "Block Chance", 2)
    call DEqItemTypeDefineStatGrantedByName('j1c5', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('j1c5', "Strength", 8)
    call DEqItemTypeDefineGoldValue('j1c5', 1420)

    // |c00A335EEIronbound Breastplate|r (Epic)
    // Base: rst1, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c6', "Chest")
    call DEqItemTypeDefineStatGrantedByName('j1c6', "Armor", 8)
    call DEqItemTypeDefineStatGrantedByName('j1c6', "Armor Pct", 0.05)
    call DEqItemTypeDefineStatGrantedByName('j1c6', "Hitpoints", 250)
    call DEqItemTypeDefineStatGrantedByName('j1c6', "Strength", 15)
    call DEqItemTypeDefineGoldValue('j1c6', 2600)

    // |c000070DDIronbound Vambraces|r (Rare)
    // Base: rst1, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('j1c7', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('j1c7', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('j1c7', "Block Chance", 2)
    call DEqItemTypeDefineStatGrantedByName('j1c7', "Hitpoints", 100)
    call DEqItemTypeDefineStatGrantedByName('j1c7', "Strength", 6)
    call DEqItemTypeDefineGoldValue('j1c7', 1200)

    // |c000070DDIronbound Gauntlets|r (Rare)
    // Base: rst1, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('j1c8', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('j1c8', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('j1c8', "Damage", 5)
    call DEqItemTypeDefineStatGrantedByName('j1c8', "Strength", 8)
    call DEqItemTypeDefineGoldValue('j1c8', 1250)

    // |c000070DDIronbound Warbelt|r (Rare)
    // Base: rst1, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('j1c9', "Belt")
    call DEqItemTypeDefineStatGrantedByName('j1c9', "Armor", 4)
    call DEqItemTypeDefineStatGrantedByName('j1c9', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('j1c9', "Strength", 8)
    call DEqItemTypeDefineGoldValue('j1c9', 1180)

    // |c00A335EEIronbound Legplates|r (Epic)
    // Base: rst1, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('j1d0', "Legs")
    call DEqItemTypeDefineStatGrantedByName('j1d0', "Armor", 7)
    call DEqItemTypeDefineStatGrantedByName('j1d0', "Hitpoints", 250)
    call DEqItemTypeDefineStatGrantedByName('j1d0', "Movement Speed", 2)
    call DEqItemTypeDefineStatGrantedByName('j1d0', "Strength", 12)
    call DEqItemTypeDefineGoldValue('j1d0', 2500)

    // |c000070DDIronbound Greaves|r (Rare)
    // Base: bspd, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('j1d1', "Boots")
    call DEqItemTypeDefineStatGrantedByName('j1d1', "Armor", 5)
    call DEqItemTypeDefineStatGrantedByName('j1d1', "Hitpoints", 150)
    call DEqItemTypeDefineStatGrantedByName('j1d1', "Movement Speed", 2)
    call DEqItemTypeDefineStatGrantedByName('j1d1', "Strength", 8)
    call DEqItemTypeDefineGoldValue('j1d1', 1320)

    // |cFFFFFFFFBlacksmith's Hammer|r (Common)
    // Base: fgrg, Class: Main Hand Weapon
    call DEqItemTypeDefineAllowedSlotByName('j1d2', "MainHand")
    call DEqItemTypeDefineStatGrantedByName('j1d2', "Damage", 3)
    call DEqItemTypeDefineGoldValue('j1d2', 100)

    // |cFFFFFFFFMild Spices|r (Common)
    // Base: fgsk, Class: Material
    call DEqItemTypeDefineGoldValue('j1d3', 50)

    // |cFFFFFFFFHot Spices|r (Common)
    // Base: fgsk, Class: Material
    call DEqItemTypeDefineGoldValue('j1d4', 100)

    // |cFFFFFFFFSoothing Spices|r (Common)
    // Base: fgsk, Class: Material
    call DEqItemTypeDefineGoldValue('j1d5', 150)

    // |cFFFFFFFFExotic Spices|r (Common)
    // Base: fgsk, Class: Material
    call DEqItemTypeDefineGoldValue('j1d6', 200)

    // |cFFFFFFFFCharred Boar Ribs|r (Common)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a0', 90)
    call DEqItemTypeDefineAbilityGranted('j2a0', 'A0F5', 1)

    // |cFFFFFFFFRabbit Broth|r (Common)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a1', 85)
    call DEqItemTypeDefineAbilityGranted('j2a1', 'A0F5', 1)

    // |cFF1EFF00Hawk Skewer|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a2', 105)
    call DEqItemTypeDefineAbilityGranted('j2a2', 'A0F5', 1)

    // |cFF1EFF00Turtle Stew|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a3', 125)
    call DEqItemTypeDefineAbilityGranted('j2a3', 'A0F5', 1)

    // |cFF1EFF00Murloc Fin Soup|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a4', 145)
    call DEqItemTypeDefineAbilityGranted('j2a4', 'A0F5', 1)

    // |cFF1EFF00Lizard Pepper Roast|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a5', 150)
    call DEqItemTypeDefineAbilityGranted('j2a5', 'A0F5', 1)

    // |cFF1EFF00Tiger Steak|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a6', 190)
    call DEqItemTypeDefineAbilityGranted('j2a6', 'A0F5', 1)

    // |cFF1EFF00Panther Fillet|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a7', 215)
    call DEqItemTypeDefineAbilityGranted('j2a7', 'A0F5', 1)

    // |cFF0070DDRaptor Chili|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a8', 260)
    call DEqItemTypeDefineAbilityGranted('j2a8', 'A0F5', 1)

    // |cFF1EFF00Cow Rump Roast|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2a9', 280)
    call DEqItemTypeDefineAbilityGranted('j2a9', 'A0F5', 1)

    // |cFFFFFFFFBrilliant Smallfish|r (Common)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b0', 18)
    call DEqItemTypeDefineAbilityGranted('j2b0', 'A0F5', 1)

    // |cFFFFFFFFSlitherskin Mackerel|r (Common)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b1', 22)
    call DEqItemTypeDefineAbilityGranted('j2b1', 'A0F5', 1)

    // |cFFFFFFFFMud Snapper Cake|r (Common)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b2', 60)
    call DEqItemTypeDefineAbilityGranted('j2b2', 'A0F5', 1)

    // |cFF1EFF00Rainbow Albacore|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b3', 110)
    call DEqItemTypeDefineAbilityGranted('j2b3', 'A0F5', 1)

    // |cFF1EFF00Catfish Chowder|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b4', 135)
    call DEqItemTypeDefineAbilityGranted('j2b4', 'A0F5', 1)

    // |cFF1EFF00Loch Frenzy Delight|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b5', 145)
    call DEqItemTypeDefineAbilityGranted('j2b5', 'A0F5', 1)

    // |cFF1EFF00Firefin Chili|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b6', 175)
    call DEqItemTypeDefineAbilityGranted('j2b6', 'A0F5', 1)

    // |cFF1EFF00Sagefish Soup|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b7', 200)
    call DEqItemTypeDefineAbilityGranted('j2b7', 'A0F5', 1)

    // |cFF1EFF00Rockscale Cod|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2b9', 225)
    call DEqItemTypeDefineAbilityGranted('j2b9', 'A0F5', 1)

    // |cFF1EFF00Mithril Head Trout|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c0', 250)
    call DEqItemTypeDefineAbilityGranted('j2c0', 'A0F5', 1)

    // |cFF1EFF00Spotted Yellowtail|r (Uncommon)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c1', 275)
    call DEqItemTypeDefineAbilityGranted('j2c1', 'A0F5', 1)

    // |cFF0070DDGlossy Mightfish Steak|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c2', 390)
    call DEqItemTypeDefineAbilityGranted('j2c2', 'A0F5', 1)

    // |cFF0070DDRedgill Skillet|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c3', 405)
    call DEqItemTypeDefineAbilityGranted('j2c3', 'A0F5', 1)

    // |cFF0070DDNightfin Soup|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c4', 440)
    call DEqItemTypeDefineAbilityGranted('j2c4', 'A0F5', 1)

    // |cFF0070DDSunscale Fillet|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c5', 450)
    call DEqItemTypeDefineAbilityGranted('j2c5', 'A0F5', 1)

    // |cFF0070DDStonescale Eel|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c6', 475)
    call DEqItemTypeDefineAbilityGranted('j2c6', 'A0F5', 1)

    // |cFF0070DDWhitescale Salmon|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c7', 520)
    call DEqItemTypeDefineAbilityGranted('j2c7', 'A0F5', 1)

    // |cFF0070DDDarkclaw Bisque|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c8', 600)
    call DEqItemTypeDefineAbilityGranted('j2c8', 'A0F5', 1)

    // |cFF0070DDWinter Squid|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2c9', 650)
    call DEqItemTypeDefineAbilityGranted('j2c9', 'A0F5', 1)

    // |cFF0070DDSummer Bass|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2d0', 675)
    call DEqItemTypeDefineAbilityGranted('j2d0', 'A0F5', 1)

    // |cFF0070DDTigerseye Eel|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2d1', 720)
    call DEqItemTypeDefineAbilityGranted('j2d1', 'A0F5', 1)

    // |cFF0070DDDeviate Delight|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2d2', 330)
    call DEqItemTypeDefineAbilityGranted('j2d2', 'A0F5', 1)

    // |cFF0070DDEmber Whelp Roast|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2d3', 700)
    call DEqItemTypeDefineAbilityGranted('j2d3', 'A0F5', 1)

    // |cFF0070DDPlaguebloom Dumpling|r (Rare)
    // Base: rej3, Class: Food
    call DEqItemTypeDefineGoldValue('j2d4', 730)
    call DEqItemTypeDefineAbilityGranted('j2d4', 'A0F5', 1)

    // |cFFFFFFFFSpringwater Tea|r (Common)
    // Base: pclr, Class: Drink
    call DEqItemTypeDefineGoldValue('j3a0', 25)
    call DEqItemTypeDefineAbilityGranted('j3a0', 'A0F5', 1)

    // |cFFFFFFFFHoneyed Milk|r (Common)
    // Base: pclr, Class: Drink
    call DEqItemTypeDefineGoldValue('j3a1', 35)
    call DEqItemTypeDefineAbilityGranted('j3a1', 'A0F5', 1)

    // |cFFFFFFFFBitter Cactus Ale|r (Common)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 6
    call DEqItemTypeDefineGoldValue('j3a2', 55)
    call DEqItemTypeDefineAbilityGranted('j3a2', 'A0F5', 1)

    // |cFF1EFF00Stout Mead|r (Uncommon)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 8
    call DEqItemTypeDefineGoldValue('j3a3', 95)
    call DEqItemTypeDefineAbilityGranted('j3a3', 'A0F5', 1)

    // |cFF1EFF00Salted Makrura Broth|r (Uncommon)
    // Base: pclr, Class: Drink
    call DEqItemTypeDefineGoldValue('j3a4', 110)
    call DEqItemTypeDefineAbilityGranted('j3a4', 'A0F5', 1)

    // |cFF1EFF00Blackmouth Grog|r (Uncommon)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 10
    call DEqItemTypeDefineGoldValue('j3a5', 150)
    call DEqItemTypeDefineAbilityGranted('j3a5', 'A0F5', 1)

    // |cFF1EFF00Firefin Whiskey|r (Uncommon)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 14
    call DEqItemTypeDefineGoldValue('j3a6', 210)
    call DEqItemTypeDefineAbilityGranted('j3a6', 'A0F5', 1)

    // |cFF1EFF00Sagefish Tonic|r (Uncommon)
    // Base: pclr, Class: Drink
    call DEqItemTypeDefineGoldValue('j3a7', 230)
    call DEqItemTypeDefineAbilityGranted('j3a7', 'A0F5', 1)

    // |cFF0070DDDeviate Rum|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 16
    call DEqItemTypeDefineGoldValue('j3a8', 310)
    call DEqItemTypeDefineAbilityGranted('j3a8', 'A0F5', 1)

    // |cFF0070DDNightfin Wine|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 10
    call DEqItemTypeDefineGoldValue('j3a9', 380)
    call DEqItemTypeDefineAbilityGranted('j3a9', 'A0F5', 1)

    // |cFF0070DDStonescale Porter|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 12
    call DEqItemTypeDefineGoldValue('j3b0', 430)
    call DEqItemTypeDefineAbilityGranted('j3b0', 'A0F5', 1)

    // |cFF0070DDLobster Bisque Cup|r (Rare)
    // Base: pclr, Class: Drink
    call DEqItemTypeDefineGoldValue('j3b1', 500)
    call DEqItemTypeDefineAbilityGranted('j3b1', 'A0F5', 1)

    // |cFF0070DDDragonfire Punch|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 20
    call DEqItemTypeDefineGoldValue('j3b2', 620)
    call DEqItemTypeDefineAbilityGranted('j3b2', 'A0F5', 1)

    // |cFF0070DDWinter Squid Absinthe|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 25
    call DEqItemTypeDefineGoldValue('j3b3', 680)
    call DEqItemTypeDefineAbilityGranted('j3b3', 'A0F5', 1)

    // |cFF0070DDBrew of Bad Ideas|r (Rare)
    // Base: pclr, Class: Drink
    // Unsupported DEquipment stat skipped: Drunk = 30
    call DEqItemTypeDefineGoldValue('j3b4', 750)
    call DEqItemTypeDefineAbilityGranted('j3b4', 'A0F5', 1)

    // |cFFFFFFFFCoarse Flour|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a0', 20)

    // |cFFFFFFFFHoney|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a1', 35)

    // |cFFFFFFFFPeppercorn|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a2', 45)

    // |cFFFFFFFFBaker's Yeast|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a3', 40)

    // |cFFFFFFFFBitter Hops|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a4', 55)

    // |cFFFFFFFFCactus Pulp|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a5', 60)

    // |cFFFFFFFFSour Berries|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a6', 65)

    // |cFFFFFFFFGlowcap|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a7', 120)

    // |cFFFFFFFFIcecap Shavings|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a8', 180)

    // |cFFFFFFFFEmpty Bottle|r (Common)
    // Base: phea, Class: Material
    call DEqItemTypeDefineGoldValue('j4a9', 10)

    // |c001EFF00Bonebound Mantle|r (Uncommon)
    // Base: rat9, Class: Shoulders
    call DEqItemTypeDefineAllowedSlotByName('j4b0', "Shoulder")
    call DEqItemTypeDefineStatGrantedByName('j4b0', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j4b0', "Strength", 3)
    call DEqItemTypeDefineGoldValue('j4b0', 100)

    // |c001EFF00Shaman’s Garb|r (Uncommon)
    // Base: rat9, Class: Chest Armor
    call DEqItemTypeDefineAllowedSlotByName('j4b1', "Chest")
    call DEqItemTypeDefineStatGrantedByName('j4b1', "Agility", 1)
    call DEqItemTypeDefineStatGrantedByName('j4b1', "Intelligence", 3)
    call DEqItemTypeDefineStatGrantedByName('j4b1', "Mana Pct Per Sec", 0.01)
    call DEqItemTypeDefineGoldValue('j4b1', 100)

    // |c001EFF00Leather Handwraps|r (Uncommon)
    // Base: rat9, Class: Hand Armor
    call DEqItemTypeDefineAllowedSlotByName('j4b2', "Gloves")
    call DEqItemTypeDefineStatGrantedByName('j4b2', "Agility", 2)
    call DEqItemTypeDefineStatGrantedByName('j4b2', "Strength", 2)
    call DEqItemTypeDefineGoldValue('j4b2', 100)

    // |c001EFF00Braided Ritual Belt|r (Uncommon)
    // Base: rat9, Class: Belt
    call DEqItemTypeDefineAllowedSlotByName('j4b3', "Belt")
    call DEqItemTypeDefineStatGrantedByName('j4b3', "Agility", 2)
    call DEqItemTypeDefineStatGrantedByName('j4b3', "Intelligence", 2)
    call DEqItemTypeDefineGoldValue('j4b3', 100)

    // |c001EFF00Shaman’s Kilt|r (Uncommon)
    // Base: rat9, Class: Leg Armor
    call DEqItemTypeDefineAllowedSlotByName('j4b4', "Legs")
    call DEqItemTypeDefineStatGrantedByName('j4b4', "Agility", 2)
    call DEqItemTypeDefineStatGrantedByName('j4b4', "Armor", 1)
    call DEqItemTypeDefineStatGrantedByName('j4b4', "Intelligence", 2)
    call DEqItemTypeDefineStatGrantedByName('j4b4', "Strength", 2)
    call DEqItemTypeDefineGoldValue('j4b4', 200)

    // |c001EFF00Earthwalker Sandals|r (Uncommon)
    // Base: rat9, Class: Foot Armor
    call DEqItemTypeDefineAllowedSlotByName('j4b5', "Boots")
    call DEqItemTypeDefineStatGrantedByName('j4b5', "Agility", 3)
    call DEqItemTypeDefineStatGrantedByName('j4b5', "Armor", 1)
    call DEqItemTypeDefineGoldValue('j4b5', 150)

    // |c001EFF00Weathered Cloak|r (Uncommon)
    // Base: rat9, Class: Back
    call DEqItemTypeDefineAllowedSlotByName('j4b6', "Back")
    call DEqItemTypeDefineStatGrantedByName('j4b6', "Intelligence", 3)
    call DEqItemTypeDefineStatGrantedByName('j4b6', "Strength", 1)
    call DEqItemTypeDefineGoldValue('j4b6', 150)

    // |c001EFF00Spirit Beads|r (Uncommon)
    // Base: rat9, Class: Neck
    call DEqItemTypeDefineAllowedSlotByName('j4b7', "Neck")
    call DEqItemTypeDefineStatGrantedByName('j4b7', "Intelligence", 3)
    call DEqItemTypeDefineGoldValue('j4b7', 100)

    // |c001EFF00Carved Bone Ring|r (Uncommon)
    // Base: rat9, Class: Ring
    call DEqItemTypeDefineAllowedSlotId('j4b8', 8)
    call DEqItemTypeDefineAllowedSlotId('j4b8', 9)
    call DEqItemTypeDefineStatGrantedByName('j4b8', "Intelligence", 1)
    call DEqItemTypeDefineGoldValue('j4b8', 50)

    // |c001EFF00Shaman’s Hood|r (Uncommon)
    // Base: rat9, Class: Head Armor
    call DEqItemTypeDefineAllowedSlotByName('j4b9', "Head")
    call DEqItemTypeDefineStatGrantedByName('j4b9', "Intelligence", 3)
    call DEqItemTypeDefineStatGrantedByName('j4b9', "Mana Pct Per Sec", 0.01)
    call DEqItemTypeDefineGoldValue('j4b9', 150)

    // |c001EFF00Bone-laced Bracers|r (Uncommon)
    // Base: rat9, Class: Bracers
    call DEqItemTypeDefineAllowedSlotByName('j4c0', "Bracers")
    call DEqItemTypeDefineStatGrantedByName('j4c0', "Agility", 3)
    call DEqItemTypeDefineStatGrantedByName('j4c0', "Armor", 1)
    call DEqItemTypeDefineGoldValue('j4c0', 150)

    // |c001EFF00Ancestral Charm|r (Uncommon)
    // Base: rat9, Class: Trinket
    call DEqItemTypeDefineAllowedSlotId('j4c1', 17)
    call DEqItemTypeDefineAllowedSlotId('j4c1', 18)
    call DEqItemTypeDefineStatGrantedByName('j4c1', "Critical Chance", 1)
    call DEqItemTypeDefineGoldValue('j4c1', 150)

    // |c0090EE90Jade Ring|r (Uncommon)
    // Base: jdrn, Class: MISC
    call DEqItemTypeDefineAbilityGranted('jdrn', 'AIa3', 1)

    // Unknown Item (klmm) (Common)
    // Base: klmm, Class: MISC
    call DEqItemTypeDefineGoldValue('klmm', 12500)

    // |c00A9A9A9Lion's Ring|r (Common)
    // Base: lnrn, Class: MISC

    // Unknown Item (mcri) (Common)
    // Base: mcri, Class: MISC

    // |c00A9A9A9Maul of Strength|r (Common)
    // Base: mlst, Class: MISC

    // Unknown Item (mnst) (Common)
    // Base: mnst, Class: MISC

    // Unknown Item (modt) (Common)
    // Base: modt, Class: MISC
    call DEqItemTypeDefineGoldValue('modt', 8500)

    // Unknown Item (moon) (Common)
    // Base: moon, Class: MISC

    // Unknown Item (ocor) (Common)
    // Base: ocor, Class: MISC
    call DEqItemTypeDefineGoldValue('ocor', 500)

    // Unknown Item (odef) (Common)
    // Base: odef, Class: MISC

    // Unknown Item (ofir) (Common)
    // Base: ofir, Class: MISC
    call DEqItemTypeDefineGoldValue('ofir', 500)

    // Unknown Item (ofro) (Common)
    // Base: ofro, Class: MISC
    call DEqItemTypeDefineGoldValue('ofro', 900)

    // Unknown Item (oli2) (Common)
    // Base: oli2, Class: MISC
    call DEqItemTypeDefineGoldValue('oli2', 500)

    // Unknown Item (olig) (Common)
    // Base: olig, Class: MISC
    call DEqItemTypeDefineGoldValue('olig', 550)

    // Unknown Item (oslo) (Common)
    // Base: oslo, Class: MISC
    call DEqItemTypeDefineGoldValue('oslo', 650)

    // Unknown Item (oven) (Common)
    // Base: oven, Class: MISC
    call DEqItemTypeDefineGoldValue('oven', 500)

    // Unknown Item (pams) (Common)
    // Base: pams, Class: MISC

    // Unknown Item (pclr) (Common)
    // Base: pclr, Class: MISC

    // Greater Healing Potion (Common)
    // Base: pghe, Class: MISC
    call DEqItemTypeDefineAbilityGranted('pghe', 'A6AZ', 1)

    // Unknown Item (pgin) (Common)
    // Base: pgin, Class: MISC

    // Greater Mana Potion (Common)
    // Base: pgma, Class: MISC
    call DEqItemTypeDefineAbilityGranted('pgma', 'A6BN', 1)

    // Healing Potion (Common)
    // Base: phea, Class: MISC
    call DEqItemTypeDefineAbilityGranted('phea', 'A6AY', 1)

    // Unknown Item (pinv) (Common)
    // Base: pinv, Class: MISC

    // Unknown Item (plcl) (Common)
    // Base: plcl, Class: MISC

    // Mana Potion (Common)
    // Base: pman, Class: MISC
    call DEqItemTypeDefineAbilityGranted('pman', 'A6BP', 1)

    // Unknown Item (pnvl) (Common)
    // Base: pnvl, Class: MISC

    // Restoration Potion (Common)
    // Base: pres, Class: MISC
    call DEqItemTypeDefineAbilityGranted('pres', 'A6B1', 1)

    // Unknown Item (pspd) (Common)
    // Base: pspd, Class: MISC

    // |c00A9A9A9Slippers of Agility|r (Common)
    // Base: rag1, Class: MISC

    // |c0090EE90Claws of Attack +3|r (Uncommon)
    // Base: rat3, Class: MISC
    call DEqItemTypeDefineGoldValue('rat3', 150)

    // |c0090EE90Claws of Attack +6|r (Uncommon)
    // Base: rat6, Class: MISC
    call DEqItemTypeDefineGoldValue('rat6', 350)

    // |c0090EE90Claws of Attack +9|r (Uncommon)
    // Base: rat9, Class: MISC
    call DEqItemTypeDefineGoldValue('rat9', 500)

    // |c0090EE90Claws of Attack +12|r (Uncommon)
    // Base: ratc, Class: MISC
    call DEqItemTypeDefineGoldValue('ratc', 600)

    // |c0090EE90Claws of Attack +15|r (Uncommon)
    // Base: ratf, Class: MISC

    // |c0090EE90Ring of Protection +2|r (Uncommon)
    // Base: rde1, Class: MISC

    // |c0090EE90Ring of Protection +3|r (Uncommon)
    // Base: rde2, Class: MISC

    // |c0090EE90Ring of Protection +4|r (Uncommon)
    // Base: rde3, Class: MISC

    // Unknown Item (rde4) (Common)
    // Base: rde4, Class: MISC

    // Minor Replenishment Potion (old) (Common)
    // Base: rej1, Class: MISC

    // Lesser Replenishment Potion (old) (Common)
    // Base: rej2, Class: MISC

    // Unknown Item (rej3) (Common)
    // Base: rej3, Class: MISC
    call DEqItemTypeDefineGoldValue('rej3', 300)
    call DEqItemTypeDefineAbilityGranted('rej3', 'A6B5', 1)

    // Greater Replenishment Potion (old) (Common)
    // Base: rej4, Class: MISC

    // Unknown Item (rej5) (Common)
    // Base: rej5, Class: MISC

    // Greater Scroll of Replenishment (old) (Common)
    // Base: rej6, Class: MISC

    // Unknown Item (rin1) (Common)
    // Base: rin1, Class: MISC

    // |c0090EE90Ring of Regeneration|r (Uncommon)
    // Base: rlif, Class: MISC

    // Unknown Item (rnec) (Common)
    // Base: rnec, Class: MISC

    // |c0090EE90Scepter of the Sea|r (Uncommon)
    // Base: rots, Class: MISC

    // Unknown Item (rst1) (Common)
    // Base: rst1, Class: MISC

    // Unknown Item (rugt) (Common)
    // Base: rugt, Class: MISC
    call DEqItemTypeDefineGoldValue('rugt', 950)

    // Unknown Item (rump) (Common)
    // Base: rump, Class: MISC
    call DEqItemTypeDefineGoldValue('rump', 300)

    // |c000080FFSobi Mask|r (Rare)
    // Base: rwiz, Class: MISC
    call DEqItemTypeDefineGoldValue('rwiz', 900)
    call DEqItemTypeDefineAbilityGranted('rwiz', 'A6C7', 1)

    // Unknown Item (sand) (Common)
    // Base: sand, Class: MISC

    // |c0090EE90Scepter of Healing|r (Uncommon)
    // Base: schl, Class: MISC

    // Unknown Item (scul) (Common)
    // Base: scul, Class: MISC

    // Unknown Item (shas) (Common)
    // Base: shas, Class: MISC

    // |c00800080Shield of Deathlord|r (Epic)
    // Base: shdt, Class: MISC
    call DEqItemTypeDefineGoldValue('shdt', 14500)

    // Unknown Item (shea) (Common)
    // Base: shea, Class: MISC
    call DEqItemTypeDefineAbilityGranted('shea', 'A6B7', 1)

    // Unknown Item (shen) (Common)
    // Base: shen, Class: MISC
    call DEqItemTypeDefineGoldValue('shen', 1000)

    // |c00800080Shield of Honor|r (Epic)
    // Base: shhn, Class: MISC
    call DEqItemTypeDefineGoldValue('shhn', 5000)

    // Unknown Item (silk) (Common)
    // Base: silk, Class: MISC

    // |c0090EE90Skull Shield|r (Uncommon)
    // Base: sksh, Class: MISC
    call DEqItemTypeDefineAbilityGranted('sksh', 'A64V', 1)
    call DEqItemTypeDefineAbilityGranted('sksh', 'A669', 1)

    // Unknown Item (sman) (Common)
    // Base: sman, Class: MISC
    call DEqItemTypeDefineAbilityGranted('sman', 'A6BA', 1)

    // Unknown Item (sneg) (Common)
    // Base: sneg, Class: MISC

    // Unknown Item (spro) (Common)
    // Base: spro, Class: MISC
    call DEqItemTypeDefineAbilityGranted('spro', 'A6BD', 1)

    // |c000080FFAmulet of Spell Shield|r (Rare)
    // Base: spsh, Class: MISC

    // Unknown Item (srbd) (Common)
    // Base: srbd, Class: MISC
    call DEqItemTypeDefineGoldValue('srbd', 5500)

    // Unknown Item (sreg) (Common)
    // Base: sreg, Class: MISC
    call DEqItemTypeDefineGoldValue('sreg', 150)
    call DEqItemTypeDefineAbilityGranted('sreg', 'A6BG', 1)

    // Unknown Item (sres) (Common)
    // Base: sres, Class: MISC
    call DEqItemTypeDefineAbilityGranted('sres', 'A6BJ', 1)

    // Unknown Item (sror) (Common)
    // Base: sror, Class: MISC

    // Unknown Item (srrc) (Common)
    // Base: srrc, Class: MISC

    // Unknown Item (srtl) (Common)
    // Base: srtl, Class: MISC
    call DEqItemTypeDefineGoldValue('srtl', 12000)

    // Unknown Item (ssan) (Common)
    // Base: ssan, Class: MISC

    // Unknown Item (stwp) (Common)
    // Base: stwp, Class: MISC

    // Unknown Item (tgxp) (Common)
    // Base: tgxp, Class: MISC

    // |c00A9A9A9Totem of Might|r (Common)
    // Base: tmmt, Class: MISC

    // Unknown Item (tret) (Common)
    // Base: tret, Class: MISC

    // Unknown Item (vamp) (Common)
    // Base: vamp, Class: MISC

    // |c00A9A9A9Voodoo Doll|r (Common)
    // Base: vddl, Class: MISC

    // Unknown Item (whwd) (Common)
    // Base: whwd, Class: MISC

    // Unknown Item (wneg) (Common)
    // Base: wneg, Class: MISC

    // Unknown Item (wneu) (Common)
    // Base: wneu, Class: MISC

endfunction

private function Init takes nothing returns nothing
    call TriggerRegisterTimerEvent(trg_DEqPreDefinedItems, 0.1, false)
    call TriggerAddAction(trg_DEqPreDefinedItems, function DEqPreDefineItemsHere)
endfunction

endlibrary