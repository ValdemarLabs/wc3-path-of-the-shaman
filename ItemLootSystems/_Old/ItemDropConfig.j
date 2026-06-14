library ItemDropConfig requires Table
//===========================================================================
/*
    ItemDropConfig 1.0
    
    Author: [Valdemar]
    
    Description:
    Configuration library for ItemDropSystem. Contains all item arrays,
    loot tables, and drop chance configurations organized by level ranges
    and rarity tiers.
    
    Uses Table library for dynamic mappings (unit types, bosses, destructibles)
    while keeping arrays for static item data.
*/
//===========================================================================
globals
    // Player group for units that can drop items
    force ItemDrop_Players = CreateForce()
    
    // ===== TABLE STRUCTURES FOR DYNAMIC MAPPINGS =====
    // Unit type → loot type mapping
    Table UnitLootTypeTable
    
    // Boss metadata (per unit handle ID)
    Table BossMetadataTable
    
    // Destructible type → level mapping
    Table DestructibleLevelTable
    
    // ===== LOOT TYPE CONSTANTS =====
    constant integer LOOT_TYPE_NONE = 0
    constant integer LOOT_TYPE_WOLF = 1
    constant integer LOOT_TYPE_STAG = 2
    constant integer LOOT_TYPE_GNOLL = 3
    constant integer LOOT_TYPE_DRAGON_WHELP_6_10 = 4
    constant integer LOOT_TYPE_DRAGON_WHELP_16_20 = 5
    
    // ===== BOSS TYPE CONSTANTS =====
    constant integer BOSS_FELDOK = 1
    constant integer BOSS_MARGUL = 2
    constant integer BOSS_MURGAL = 3
    constant integer BOSS_SARGOTH = 4
    constant integer BOSS_UNKNOWN_ENTITY = 5
    constant integer BOSS_ROLJIN = 6
    constant integer BOSS_SUCCUBUS = 7
    constant integer BOSS_COLOSSUS = 8
    constant integer BOSS_GOLLUM = 9
    constant integer BOSS_MORDRAX = 10
    
    // ===== USELESS ITEMS =====
    integer array ItemUseless
    
    // ===== GENERIC CONSUMABLE ITEMS BY LEVEL RANGE =====
    integer array ItemGeneric_1_5
    integer array ItemGeneric_6_10
    integer array ItemGeneric_11_15
    integer array ItemGeneric_16_20
    integer array ItemGeneric_21_25
    integer array ItemGeneric_26_30
    
    // ===== LOOT RANGE ITEM LEVELS (for random item generation) =====
    // Common rarity
    integer array ItemLootRanges_1_5_Common
    integer array ItemLootRanges_6_10_Common
    integer array ItemLootRanges_11_15_Common
    integer array ItemLootRanges_16_20_Common
    integer array ItemLootRanges_21_25_Common
    integer array ItemLootRanges_26_30_Common
    
    // Uncommon rarity
    integer array ItemLootRanges_1_5_Uncommon
    integer array ItemLootRanges_6_10_Uncommon
    integer array ItemLootRanges_11_15_Uncommon
    integer array ItemLootRanges_16_20_Uncommon
    integer array ItemLootRanges_21_25_Uncommon
    integer array ItemLootRanges_26_30_Uncommon
    
    // Rare rarity
    integer array ItemLootRanges_1_5_Rare
    integer array ItemLootRanges_6_10_Rare
    integer array ItemLootRanges_11_15_Rare
    integer array ItemLootRanges_16_20_Rare
    integer array ItemLootRanges_21_25_Rare
    integer array ItemLootRanges_26_30_Rare
    
    // Epic rarity
    integer array ItemLootRanges_6_10_Epic
    integer array ItemLootRanges_11_15_Epic
    integer array ItemLootRanges_16_20_Epic
    integer array ItemLootRanges_21_25_Epic
    integer array ItemLootRanges_26_30_Epic
    
    // Legendary rarity
    integer array ItemLootRanges_11_15_Legendary
    integer array ItemLootRanges_16_20_Legendary
    integer array ItemLootRanges_21_25_Legendary
    integer array ItemLootRanges_26_30_Legendary
    
    // ===== UNIT-SPECIFIC LOOT TABLES =====
    integer array ItemLootTable // Reusable array for unit-specific drops
endglobals

//===========================================================================
// INITIALIZATION FUNCTION
// Called by ItemDropSystem to set up all item arrays and player groups
//===========================================================================
function ItemDropConfig_Init takes nothing returns nothing
    // ===== INITIALIZE TABLE STRUCTURES =====
    set UnitLootTypeTable = Table.create()
    set BossMetadataTable = Table.create()
    set DestructibleLevelTable = Table.create()
    
    // ===== ADD PLAYERS TO DROP GROUP =====
    call ForceAddPlayer(ItemDrop_Players, Player(2))   // Player 3 (Teal)
    call ForceAddPlayer(ItemDrop_Players, Player(3))   // Player 4 (Purple)
    call ForceAddPlayer(ItemDrop_Players, Player(4))   // Player 5 (Yellow)
    call ForceAddPlayer(ItemDrop_Players, Player(7))   // Player 8 (Pink)
    call ForceAddPlayer(ItemDrop_Players, Player(8))   // Player 9 (Gray)
    call ForceAddPlayer(ItemDrop_Players, Player(9))   // Player 10 (Light Blue)
    call ForceAddPlayer(ItemDrop_Players, Player(10))  // Player 11 (Dark Green)
    call ForceAddPlayer(ItemDrop_Players, Player(11))  // Player 12 (Brown)
    call ForceAddPlayer(ItemDrop_Players, Player(12))  // Player 13 (Maroon)
    call ForceAddPlayer(ItemDrop_Players, Player(20))  // Player 21 (Coal)
    call ForceAddPlayer(ItemDrop_Players, Player(22))  // Player 23 (Emerald)
    call ForceAddPlayer(ItemDrop_Players, Player(PLAYER_NEUTRAL_AGGRESSIVE))
    call ForceAddPlayer(ItemDrop_Players, Player(PLAYER_NEUTRAL_PASSIVE))
    
    // ===== USELESS ITEMS =====
    set ItemUseless[1] = 'I001' // Useless Cloak
    set ItemUseless[2] = 'I002' // Rusty Kitchen Knive
    set ItemUseless[3] = 'I003' // Old Copper Ring
    set ItemUseless[4] = 'I004' // Holy Cross
    set ItemUseless[5] = 'I005' // Worn Gloves
    set ItemUseless[6] = 'I006' // Rusty Dagger
    
    // ===== GENERIC ITEMS | LEVELS 1 to 5 =====
    set ItemGeneric_1_5[1] = 'I010' // Spring Water
    set ItemGeneric_1_5[2] = 'I011' // Minor Healing Potion
    set ItemGeneric_1_5[3] = 'I012' // Minor Mana Potion
    set ItemGeneric_1_5[4] = 'I013' // Minor Replenishment Potion
    set ItemGeneric_1_5[5] = 'I014' // Gold Coins
    set ItemGeneric_1_5[6] = 'I015' // Scroll of Protection
    set ItemGeneric_1_5[7] = 'I016' // Lesser Clarity Potion
    set ItemGeneric_1_5[8] = 'I017' // Clarity Potion
    
    // ===== GENERIC ITEMS | LEVELS 6 to 10 =====
    set ItemGeneric_6_10[1] = 'I020' // Healing Potion
    set ItemGeneric_6_10[2] = 'I021' // Mana Potion
    set ItemGeneric_6_10[3] = 'I022' // Replenishment Potion
    set ItemGeneric_6_10[4] = 'I023' // Restoration Potion
    set ItemGeneric_6_10[5] = 'I024' // Scroll of Healing
    set ItemGeneric_6_10[6] = 'I025' // Scroll of Mana
    set ItemGeneric_6_10[7] = 'I026' // Scroll of Protection
    set ItemGeneric_6_10[8] = 'I027' // Scroll of Regeneration
    set ItemGeneric_6_10[9] = 'I028' // Scroll of Restoration
    set ItemGeneric_6_10[10] = 'I029' // Scroll of Speed
    set ItemGeneric_6_10[11] = 'I02A' // Scroll of the Beast
    set ItemGeneric_6_10[12] = 'I02B' // Healing Salve
    set ItemGeneric_6_10[13] = 'I02C' // Gold Coins
    set ItemGeneric_6_10[14] = 'I02D' // Purified Water
    
    // ===== GENERIC ITEMS | LEVELS 11 to 15 =====
    set ItemGeneric_11_15[1] = 'I030' // Healing Potion
    set ItemGeneric_11_15[2] = 'I031' // Mana Potion
    set ItemGeneric_11_15[3] = 'I032' // Replenishment Potion
    set ItemGeneric_11_15[4] = 'I033' // Restoration Potion
    set ItemGeneric_11_15[5] = 'I034' // Scroll of Healing
    set ItemGeneric_11_15[6] = 'I035' // Scroll of Mana
    set ItemGeneric_11_15[7] = 'I036' // Scroll of Protection
    set ItemGeneric_11_15[8] = 'I037' // Scroll of Regeneration
    set ItemGeneric_11_15[9] = 'I038' // Scroll of Restoration
    set ItemGeneric_11_15[10] = 'I039' // Scroll of Speed
    set ItemGeneric_11_15[11] = 'I03A' // Scroll of the Beast
    set ItemGeneric_11_15[12] = 'I03B' // Greater Healing Salve
    set ItemGeneric_11_15[13] = 'I03C' // Gold Coins
    set ItemGeneric_11_15[14] = 'I03D' // Purified Water
    set ItemGeneric_11_15[15] = 'I03E' // Potion of Speed
    set ItemGeneric_11_15[16] = 'I03F' // Potion of Lesser Invulnerability
    
    // ===== GENERIC ITEMS | LEVELS 16 to 20 =====
    set ItemGeneric_16_20[1] = 'I040' // Greater Healing Potion
    set ItemGeneric_16_20[2] = 'I041' // Greater Mana Potion
    set ItemGeneric_16_20[3] = 'I042' // Greater Replenishment Potion
    set ItemGeneric_16_20[4] = 'I043' // Greater Restoration Potion
    set ItemGeneric_16_20[5] = 'I044' // Scroll of Greater Healing
    set ItemGeneric_16_20[6] = 'I045' // Scroll of Greater Mana
    set ItemGeneric_16_20[7] = 'I046' // Scroll of Greater Protection
    set ItemGeneric_16_20[8] = 'I047' // Scroll of Greater Regeneration
    set ItemGeneric_16_20[9] = 'I048' // Scroll of Greater Restoration
    set ItemGeneric_16_20[10] = 'I049' // Scroll of Speed
    set ItemGeneric_16_20[11] = 'I04A' // Scroll of the Beast
    set ItemGeneric_16_20[12] = 'I04B' // Greater Healing Salve
    set ItemGeneric_16_20[13] = 'I04C' // Gold Coins
    set ItemGeneric_16_20[14] = 'I04D' // Purified Water
    set ItemGeneric_16_20[15] = 'I04E' // Potion of Speed
    set ItemGeneric_16_20[16] = 'I04F' // Potion of Lesser Invulnerability
    
    // ===== GENERIC ITEMS | LEVELS 21 to 25 =====
    set ItemGeneric_21_25[1] = 'I050' // Greater Healing Potion
    set ItemGeneric_21_25[2] = 'I051' // Greater Mana Potion
    set ItemGeneric_21_25[3] = 'I052' // Greater Replenishment Potion
    set ItemGeneric_21_25[4] = 'I053' // Greater Restoration Potion
    set ItemGeneric_21_25[5] = 'I054' // Scroll of Greater Healing
    set ItemGeneric_21_25[6] = 'I055' // Scroll of Greater Mana
    set ItemGeneric_21_25[7] = 'I056' // Scroll of Greater Protection
    set ItemGeneric_21_25[8] = 'I057' // Scroll of Greater Regeneration
    set ItemGeneric_21_25[9] = 'I058' // Scroll of Greater Restoration
    set ItemGeneric_21_25[10] = 'I059' // Scroll of Speed
    set ItemGeneric_21_25[11] = 'I05A' // Scroll of the Beast
    set ItemGeneric_21_25[12] = 'I05B' // Greater Healing Salve
    set ItemGeneric_21_25[13] = 'I05C' // Gold Coins
    set ItemGeneric_21_25[14] = 'I05D' // Purified Water
    set ItemGeneric_21_25[15] = 'I05E' // Potion of Speed
    set ItemGeneric_21_25[16] = 'I05F' // Potion of Lesser Invulnerability
    set ItemGeneric_21_25[17] = 'I060' // Potion of Invulnerability
    set ItemGeneric_21_25[18] = 'I061' // Potion of Invisibility
    set ItemGeneric_21_25[19] = 'I062' // Major Healing Potion
    set ItemGeneric_21_25[20] = 'I063' // Major Mana Potion
    set ItemGeneric_21_25[21] = 'I064' // Scroll of Major Healing
    set ItemGeneric_21_25[22] = 'I065' // Scroll of Major Mana
    set ItemGeneric_21_25[23] = 'I066' // Scroll of Major Protection
    set ItemGeneric_21_25[24] = 'I067' // Scroll of Major Regeneration
    set ItemGeneric_21_25[25] = 'I068' // Scroll of Major Restoration
    
    // ===== GENERIC ITEMS | LEVELS 26 to 30 =====
    set ItemGeneric_26_30[1] = 'I070' // Major Healing Potion
    set ItemGeneric_26_30[2] = 'I071' // Major Mana Potion
    set ItemGeneric_26_30[3] = 'I072' // Greater Replenishment Potion
    set ItemGeneric_26_30[4] = 'I073' // Greater Restoration Potion
    set ItemGeneric_26_30[5] = 'I074' // Scroll of Major Healing
    set ItemGeneric_26_30[6] = 'I075' // Scroll of Major Mana
    set ItemGeneric_26_30[7] = 'I076' // Scroll of Major Protection
    set ItemGeneric_26_30[8] = 'I077' // Scroll of Major Regeneration
    set ItemGeneric_26_30[9] = 'I078' // Scroll of Major Restoration
    set ItemGeneric_26_30[10] = 'I079' // Gold Coins
    set ItemGeneric_26_30[11] = 'I07A' // Potion of Speed
    set ItemGeneric_26_30[12] = 'I07B' // Anti-magic Potion
    set ItemGeneric_26_30[13] = 'I07C' // Potion of Invulnerability
    set ItemGeneric_26_30[14] = 'I07D' // Vampiric Potion
    set ItemGeneric_26_30[15] = 'I07E' // Purified Water
    set ItemGeneric_26_30[16] = 'I07F' // Crystal Water
    set ItemGeneric_26_30[17] = 'I080' // Greater Healing Salve
    
    // ===== LOOT RANGES - LEVELS 1-5 =====
    // Common (iLvl 5)
    set ItemLootRanges_1_5_Common[1] = 50
    set ItemLootRanges_1_5_Common[2] = 100
    set ItemLootRanges_1_5_Common[3] = 150
    set ItemLootRanges_1_5_Common[4] = 200
    set ItemLootRanges_1_5_Common[5] = 250
    set ItemLootRanges_1_5_Common[6] = 300
    set ItemLootRanges_1_5_Common[7] = 350
    set ItemLootRanges_1_5_Common[8] = 400
    set ItemLootRanges_1_5_Common[9] = 450
    set ItemLootRanges_1_5_Common[10] = 500
    set ItemLootRanges_1_5_Common[11] = 550
    set ItemLootRanges_1_5_Common[12] = 600
    set ItemLootRanges_1_5_Common[13] = 650
    set ItemLootRanges_1_5_Common[14] = 700
    set ItemLootRanges_1_5_Common[15] = 750
    set ItemLootRanges_1_5_Common[16] = 800
    set ItemLootRanges_1_5_Common[17] = 850
    
    // Uncommon (iLvl 10)
    set ItemLootRanges_1_5_Uncommon[1] = 60
    set ItemLootRanges_1_5_Uncommon[2] = 110
    set ItemLootRanges_1_5_Uncommon[3] = 160
    set ItemLootRanges_1_5_Uncommon[4] = 210
    set ItemLootRanges_1_5_Uncommon[5] = 260
    set ItemLootRanges_1_5_Uncommon[6] = 310
    set ItemLootRanges_1_5_Uncommon[7] = 360
    set ItemLootRanges_1_5_Uncommon[8] = 410
    set ItemLootRanges_1_5_Uncommon[9] = 460
    set ItemLootRanges_1_5_Uncommon[10] = 510
    set ItemLootRanges_1_5_Uncommon[11] = 560
    set ItemLootRanges_1_5_Uncommon[12] = 610
    set ItemLootRanges_1_5_Uncommon[13] = 660
    set ItemLootRanges_1_5_Uncommon[14] = 710
    set ItemLootRanges_1_5_Uncommon[15] = 760
    set ItemLootRanges_1_5_Uncommon[16] = 810
    set ItemLootRanges_1_5_Uncommon[17] = 860
    
    // Rare (iLvl 15)
    set ItemLootRanges_1_5_Rare[1] = 70
    set ItemLootRanges_1_5_Rare[2] = 120
    set ItemLootRanges_1_5_Rare[3] = 170
    set ItemLootRanges_1_5_Rare[4] = 220
    set ItemLootRanges_1_5_Rare[5] = 270
    set ItemLootRanges_1_5_Rare[6] = 320
    set ItemLootRanges_1_5_Rare[7] = 370
    set ItemLootRanges_1_5_Rare[8] = 420
    set ItemLootRanges_1_5_Rare[9] = 470
    set ItemLootRanges_1_5_Rare[10] = 520
    set ItemLootRanges_1_5_Rare[11] = 570
    set ItemLootRanges_1_5_Rare[12] = 620
    set ItemLootRanges_1_5_Rare[13] = 670
    set ItemLootRanges_1_5_Rare[14] = 720
    set ItemLootRanges_1_5_Rare[15] = 770
    set ItemLootRanges_1_5_Rare[16] = 820
    set ItemLootRanges_1_5_Rare[17] = 850
    
    // ===== LOOT RANGES - LEVELS 6-10 =====
    // Common (iLvl 10)
    set ItemLootRanges_6_10_Common[1] = 51
    set ItemLootRanges_6_10_Common[2] = 101
    set ItemLootRanges_6_10_Common[3] = 151
    set ItemLootRanges_6_10_Common[4] = 201
    set ItemLootRanges_6_10_Common[5] = 251
    set ItemLootRanges_6_10_Common[6] = 301
    set ItemLootRanges_6_10_Common[7] = 351
    set ItemLootRanges_6_10_Common[8] = 401
    set ItemLootRanges_6_10_Common[9] = 451
    set ItemLootRanges_6_10_Common[10] = 501
    set ItemLootRanges_6_10_Common[11] = 551
    set ItemLootRanges_6_10_Common[12] = 601
    set ItemLootRanges_6_10_Common[13] = 651
    set ItemLootRanges_6_10_Common[14] = 701
    set ItemLootRanges_6_10_Common[15] = 751
    set ItemLootRanges_6_10_Common[16] = 801
    set ItemLootRanges_6_10_Common[17] = 851
    
    // Uncommon (iLvl 15)
    set ItemLootRanges_6_10_Uncommon[1] = 61
    set ItemLootRanges_6_10_Uncommon[2] = 111
    set ItemLootRanges_6_10_Uncommon[3] = 161
    set ItemLootRanges_6_10_Uncommon[4] = 211
    set ItemLootRanges_6_10_Uncommon[5] = 261
    set ItemLootRanges_6_10_Uncommon[6] = 311
    set ItemLootRanges_6_10_Uncommon[7] = 361
    set ItemLootRanges_6_10_Uncommon[8] = 411
    set ItemLootRanges_6_10_Uncommon[9] = 461
    set ItemLootRanges_6_10_Uncommon[10] = 511
    set ItemLootRanges_6_10_Uncommon[11] = 561
    set ItemLootRanges_6_10_Uncommon[12] = 611
    set ItemLootRanges_6_10_Uncommon[13] = 661
    set ItemLootRanges_6_10_Uncommon[14] = 711
    set ItemLootRanges_6_10_Uncommon[15] = 761
    set ItemLootRanges_6_10_Uncommon[16] = 811
    set ItemLootRanges_6_10_Uncommon[17] = 861
    
    // Rare (iLvl 20)
    set ItemLootRanges_6_10_Rare[1] = 71
    set ItemLootRanges_6_10_Rare[2] = 121
    set ItemLootRanges_6_10_Rare[3] = 171
    set ItemLootRanges_6_10_Rare[4] = 221
    set ItemLootRanges_6_10_Rare[5] = 271
    set ItemLootRanges_6_10_Rare[6] = 321
    set ItemLootRanges_6_10_Rare[7] = 371
    set ItemLootRanges_6_10_Rare[8] = 421
    set ItemLootRanges_6_10_Rare[9] = 471
    set ItemLootRanges_6_10_Rare[10] = 521
    set ItemLootRanges_6_10_Rare[11] = 571
    set ItemLootRanges_6_10_Rare[12] = 621
    set ItemLootRanges_6_10_Rare[13] = 671
    set ItemLootRanges_6_10_Rare[14] = 721
    set ItemLootRanges_6_10_Rare[15] = 771
    set ItemLootRanges_6_10_Rare[16] = 821
    set ItemLootRanges_6_10_Rare[17] = 871
    
    // Epic (iLvl 25)
    set ItemLootRanges_6_10_Epic[1] = 81
    set ItemLootRanges_6_10_Epic[2] = 131
    set ItemLootRanges_6_10_Epic[3] = 181
    set ItemLootRanges_6_10_Epic[4] = 231
    set ItemLootRanges_6_10_Epic[5] = 281
    set ItemLootRanges_6_10_Epic[6] = 331
    set ItemLootRanges_6_10_Epic[7] = 381
    set ItemLootRanges_6_10_Epic[8] = 431
    set ItemLootRanges_6_10_Epic[9] = 481
    set ItemLootRanges_6_10_Epic[10] = 531
    set ItemLootRanges_6_10_Epic[11] = 581
    set ItemLootRanges_6_10_Epic[12] = 631
    set ItemLootRanges_6_10_Epic[13] = 681
    set ItemLootRanges_6_10_Epic[14] = 731
    set ItemLootRanges_6_10_Epic[15] = 781
    set ItemLootRanges_6_10_Epic[16] = 831
    set ItemLootRanges_6_10_Epic[17] = 881
    
    // ===== LOOT RANGES - LEVELS 11-15 =====
    // Common (iLvl 15)
    set ItemLootRanges_11_15_Common[1] = 52
    set ItemLootRanges_11_15_Common[2] = 102
    set ItemLootRanges_11_15_Common[3] = 152
    set ItemLootRanges_11_15_Common[4] = 202
    set ItemLootRanges_11_15_Common[5] = 252
    set ItemLootRanges_11_15_Common[6] = 302
    set ItemLootRanges_11_15_Common[7] = 352
    set ItemLootRanges_11_15_Common[8] = 402
    set ItemLootRanges_11_15_Common[9] = 452
    set ItemLootRanges_11_15_Common[10] = 502
    set ItemLootRanges_11_15_Common[11] = 552
    set ItemLootRanges_11_15_Common[12] = 602
    set ItemLootRanges_11_15_Common[13] = 652
    set ItemLootRanges_11_15_Common[14] = 702
    set ItemLootRanges_11_15_Common[15] = 752
    set ItemLootRanges_11_15_Common[16] = 802
    set ItemLootRanges_11_15_Common[17] = 852
    
    // Uncommon (iLvl 20)
    set ItemLootRanges_11_15_Uncommon[1] = 62
    set ItemLootRanges_11_15_Uncommon[2] = 112
    set ItemLootRanges_11_15_Uncommon[3] = 162
    set ItemLootRanges_11_15_Uncommon[4] = 212
    set ItemLootRanges_11_15_Uncommon[5] = 262
    set ItemLootRanges_11_15_Uncommon[6] = 312
    set ItemLootRanges_11_15_Uncommon[7] = 362
    set ItemLootRanges_11_15_Uncommon[8] = 412
    set ItemLootRanges_11_15_Uncommon[9] = 462
    set ItemLootRanges_11_15_Uncommon[10] = 512
    set ItemLootRanges_11_15_Uncommon[11] = 562
    set ItemLootRanges_11_15_Uncommon[12] = 612
    set ItemLootRanges_11_15_Uncommon[13] = 662
    set ItemLootRanges_11_15_Uncommon[14] = 712
    set ItemLootRanges_11_15_Uncommon[15] = 762
    set ItemLootRanges_11_15_Uncommon[16] = 812
    set ItemLootRanges_11_15_Uncommon[17] = 862
    
    // Rare (iLvl 25)
    set ItemLootRanges_11_15_Rare[1] = 72
    set ItemLootRanges_11_15_Rare[2] = 122
    set ItemLootRanges_11_15_Rare[3] = 172
    set ItemLootRanges_11_15_Rare[4] = 222
    set ItemLootRanges_11_15_Rare[5] = 272
    set ItemLootRanges_11_15_Rare[6] = 322
    set ItemLootRanges_11_15_Rare[7] = 372
    set ItemLootRanges_11_15_Rare[8] = 422
    set ItemLootRanges_11_15_Rare[9] = 472
    set ItemLootRanges_11_15_Rare[10] = 522
    set ItemLootRanges_11_15_Rare[11] = 572
    set ItemLootRanges_11_15_Rare[12] = 622
    set ItemLootRanges_11_15_Rare[13] = 672
    set ItemLootRanges_11_15_Rare[14] = 722
    set ItemLootRanges_11_15_Rare[15] = 772
    set ItemLootRanges_11_15_Rare[16] = 822
    set ItemLootRanges_11_15_Rare[17] = 872
    
    // Epic (iLvl 30)
    set ItemLootRanges_11_15_Epic[1] = 82
    set ItemLootRanges_11_15_Epic[2] = 132
    set ItemLootRanges_11_15_Epic[3] = 182
    set ItemLootRanges_11_15_Epic[4] = 232
    set ItemLootRanges_11_15_Epic[5] = 282
    set ItemLootRanges_11_15_Epic[6] = 332
    set ItemLootRanges_11_15_Epic[7] = 382
    set ItemLootRanges_11_15_Epic[8] = 432
    set ItemLootRanges_11_15_Epic[9] = 482
    set ItemLootRanges_11_15_Epic[10] = 532
    set ItemLootRanges_11_15_Epic[11] = 582
    set ItemLootRanges_11_15_Epic[12] = 632
    set ItemLootRanges_11_15_Epic[13] = 682
    set ItemLootRanges_11_15_Epic[14] = 732
    set ItemLootRanges_11_15_Epic[15] = 782
    set ItemLootRanges_11_15_Epic[16] = 832
    set ItemLootRanges_11_15_Epic[17] = 882
    
    // Legendary (iLvl 35) - Starts here
    set ItemLootRanges_11_15_Legendary[1] = 92
    set ItemLootRanges_11_15_Legendary[2] = 142
    set ItemLootRanges_11_15_Legendary[3] = 192
    set ItemLootRanges_11_15_Legendary[4] = 242
    set ItemLootRanges_11_15_Legendary[5] = 292
    set ItemLootRanges_11_15_Legendary[6] = 342
    set ItemLootRanges_11_15_Legendary[7] = 392
    set ItemLootRanges_11_15_Legendary[8] = 442
    set ItemLootRanges_11_15_Legendary[9] = 492
    set ItemLootRanges_11_15_Legendary[10] = 542
    set ItemLootRanges_11_15_Legendary[11] = 592
    set ItemLootRanges_11_15_Legendary[12] = 642
    set ItemLootRanges_11_15_Legendary[13] = 692
    set ItemLootRanges_11_15_Legendary[14] = 742
    set ItemLootRanges_11_15_Legendary[15] = 792
    set ItemLootRanges_11_15_Legendary[16] = 842
    set ItemLootRanges_11_15_Legendary[17] = 892
    
    // ===== LOOT RANGES - LEVELS 16-20 =====
    // Common (iLvl 20)
    set ItemLootRanges_16_20_Common[1] = 53
    set ItemLootRanges_16_20_Common[2] = 103
    set ItemLootRanges_16_20_Common[3] = 153
    set ItemLootRanges_16_20_Common[4] = 203
    set ItemLootRanges_16_20_Common[5] = 253
    set ItemLootRanges_16_20_Common[6] = 303
    set ItemLootRanges_16_20_Common[7] = 353
    set ItemLootRanges_16_20_Common[8] = 403
    set ItemLootRanges_16_20_Common[9] = 453
    set ItemLootRanges_16_20_Common[10] = 503
    set ItemLootRanges_16_20_Common[11] = 553
    set ItemLootRanges_16_20_Common[12] = 603
    set ItemLootRanges_16_20_Common[13] = 653
    set ItemLootRanges_16_20_Common[14] = 703
    set ItemLootRanges_16_20_Common[15] = 753
    set ItemLootRanges_16_20_Common[16] = 803
    set ItemLootRanges_16_20_Common[17] = 853
    
    // Uncommon (iLvl 25)
    set ItemLootRanges_16_20_Uncommon[1] = 63
    set ItemLootRanges_16_20_Uncommon[2] = 113
    set ItemLootRanges_16_20_Uncommon[3] = 163
    set ItemLootRanges_16_20_Uncommon[4] = 213
    set ItemLootRanges_16_20_Uncommon[5] = 263
    set ItemLootRanges_16_20_Uncommon[6] = 313
    set ItemLootRanges_16_20_Uncommon[7] = 363
    set ItemLootRanges_16_20_Uncommon[8] = 413
    set ItemLootRanges_16_20_Uncommon[9] = 463
    set ItemLootRanges_16_20_Uncommon[10] = 513
    set ItemLootRanges_16_20_Uncommon[11] = 563
    set ItemLootRanges_16_20_Uncommon[12] = 613
    set ItemLootRanges_16_20_Uncommon[13] = 663
    set ItemLootRanges_16_20_Uncommon[14] = 713
    set ItemLootRanges_16_20_Uncommon[15] = 763
    set ItemLootRanges_16_20_Uncommon[16] = 813
    set ItemLootRanges_16_20_Uncommon[17] = 863
    
    // Rare (iLvl 30)
    set ItemLootRanges_16_20_Rare[1] = 73
    set ItemLootRanges_16_20_Rare[2] = 123
    set ItemLootRanges_16_20_Rare[3] = 173
    set ItemLootRanges_16_20_Rare[4] = 223
    set ItemLootRanges_16_20_Rare[5] = 273
    set ItemLootRanges_16_20_Rare[6] = 323
    set ItemLootRanges_16_20_Rare[7] = 373
    set ItemLootRanges_16_20_Rare[8] = 423
    set ItemLootRanges_16_20_Rare[9] = 473
    set ItemLootRanges_16_20_Rare[10] = 523
    set ItemLootRanges_16_20_Rare[11] = 573
    set ItemLootRanges_16_20_Rare[12] = 623
    set ItemLootRanges_16_20_Rare[13] = 673
    set ItemLootRanges_16_20_Rare[14] = 723
    set ItemLootRanges_16_20_Rare[15] = 773
    set ItemLootRanges_16_20_Rare[16] = 823
    set ItemLootRanges_16_20_Rare[17] = 873
    
    // Epic (iLvl 35)
    set ItemLootRanges_16_20_Epic[1] = 83
    set ItemLootRanges_16_20_Epic[2] = 133
    set ItemLootRanges_16_20_Epic[3] = 183
    set ItemLootRanges_16_20_Epic[4] = 233
    set ItemLootRanges_16_20_Epic[5] = 283
    set ItemLootRanges_16_20_Epic[6] = 333
    set ItemLootRanges_16_20_Epic[7] = 383
    set ItemLootRanges_16_20_Epic[8] = 433
    set ItemLootRanges_16_20_Epic[9] = 483
    set ItemLootRanges_16_20_Epic[10] = 533
    set ItemLootRanges_16_20_Epic[11] = 583
    set ItemLootRanges_16_20_Epic[12] = 633
    set ItemLootRanges_16_20_Epic[13] = 683
    set ItemLootRanges_16_20_Epic[14] = 733
    set ItemLootRanges_16_20_Epic[15] = 783
    set ItemLootRanges_16_20_Epic[16] = 833
    set ItemLootRanges_16_20_Epic[17] = 883
    
    // Legendary (iLvl 40)
    set ItemLootRanges_16_20_Legendary[1] = 93
    set ItemLootRanges_16_20_Legendary[2] = 143
    set ItemLootRanges_16_20_Legendary[3] = 193
    set ItemLootRanges_16_20_Legendary[4] = 243
    set ItemLootRanges_16_20_Legendary[5] = 293
    set ItemLootRanges_16_20_Legendary[6] = 343
    set ItemLootRanges_16_20_Legendary[7] = 393
    set ItemLootRanges_16_20_Legendary[8] = 443
    set ItemLootRanges_16_20_Legendary[9] = 493
    set ItemLootRanges_16_20_Legendary[10] = 543
    set ItemLootRanges_16_20_Legendary[11] = 593
    set ItemLootRanges_16_20_Legendary[12] = 643
    set ItemLootRanges_16_20_Legendary[13] = 693
    set ItemLootRanges_16_20_Legendary[14] = 743
    set ItemLootRanges_16_20_Legendary[15] = 793
    set ItemLootRanges_16_20_Legendary[16] = 843
    set ItemLootRanges_16_20_Legendary[17] = 893
    
    // ===== LOOT RANGES - LEVELS 21-25 =====
    // Common (iLvl 25)
    set ItemLootRanges_21_25_Common[1] = 54
    set ItemLootRanges_21_25_Common[2] = 104
    set ItemLootRanges_21_25_Common[3] = 154
    set ItemLootRanges_21_25_Common[4] = 204
    set ItemLootRanges_21_25_Common[5] = 254
    set ItemLootRanges_21_25_Common[6] = 304
    set ItemLootRanges_21_25_Common[7] = 354
    set ItemLootRanges_21_25_Common[8] = 404
    set ItemLootRanges_21_25_Common[9] = 454
    set ItemLootRanges_21_25_Common[10] = 504
    set ItemLootRanges_21_25_Common[11] = 554
    set ItemLootRanges_21_25_Common[12] = 604
    set ItemLootRanges_21_25_Common[13] = 654
    set ItemLootRanges_21_25_Common[14] = 704
    set ItemLootRanges_21_25_Common[15] = 754
    set ItemLootRanges_21_25_Common[16] = 804
    set ItemLootRanges_21_25_Common[17] = 854
    
    // Uncommon (iLvl 30)
    set ItemLootRanges_21_25_Uncommon[1] = 64
    set ItemLootRanges_21_25_Uncommon[2] = 114
    set ItemLootRanges_21_25_Uncommon[3] = 164
    set ItemLootRanges_21_25_Uncommon[4] = 214
    set ItemLootRanges_21_25_Uncommon[5] = 264
    set ItemLootRanges_21_25_Uncommon[6] = 314
    set ItemLootRanges_21_25_Uncommon[7] = 364
    set ItemLootRanges_21_25_Uncommon[8] = 414
    set ItemLootRanges_21_25_Uncommon[9] = 464
    set ItemLootRanges_21_25_Uncommon[10] = 514
    set ItemLootRanges_21_25_Uncommon[11] = 564
    set ItemLootRanges_21_25_Uncommon[12] = 614
    set ItemLootRanges_21_25_Uncommon[13] = 664
    set ItemLootRanges_21_25_Uncommon[14] = 714
    set ItemLootRanges_21_25_Uncommon[15] = 764
    set ItemLootRanges_21_25_Uncommon[16] = 814
    set ItemLootRanges_21_25_Uncommon[17] = 864
    
    // Rare (iLvl 35)
    set ItemLootRanges_21_25_Rare[1] = 74
    set ItemLootRanges_21_25_Rare[2] = 124
    set ItemLootRanges_21_25_Rare[3] = 174
    set ItemLootRanges_21_25_Rare[4] = 224
    set ItemLootRanges_21_25_Rare[5] = 274
    set ItemLootRanges_21_25_Rare[6] = 324
    set ItemLootRanges_21_25_Rare[7] = 374
    set ItemLootRanges_21_25_Rare[8] = 424
    set ItemLootRanges_21_25_Rare[9] = 474
    set ItemLootRanges_21_25_Rare[10] = 524
    set ItemLootRanges_21_25_Rare[11] = 574
    set ItemLootRanges_21_25_Rare[12] = 624
    set ItemLootRanges_21_25_Rare[13] = 674
    set ItemLootRanges_21_25_Rare[14] = 724
    set ItemLootRanges_21_25_Rare[15] = 774
    set ItemLootRanges_21_25_Rare[16] = 824
    set ItemLootRanges_21_25_Rare[17] = 874
    
    // Epic (iLvl 40)
    set ItemLootRanges_21_25_Epic[1] = 84
    set ItemLootRanges_21_25_Epic[2] = 134
    set ItemLootRanges_21_25_Epic[3] = 184
    set ItemLootRanges_21_25_Epic[4] = 234
    set ItemLootRanges_21_25_Epic[5] = 284
    set ItemLootRanges_21_25_Epic[6] = 334
    set ItemLootRanges_21_25_Epic[7] = 384
    set ItemLootRanges_21_25_Epic[8] = 434
    set ItemLootRanges_21_25_Epic[9] = 484
    set ItemLootRanges_21_25_Epic[10] = 534
    set ItemLootRanges_21_25_Epic[11] = 584
    set ItemLootRanges_21_25_Epic[12] = 634
    set ItemLootRanges_21_25_Epic[13] = 684
    set ItemLootRanges_21_25_Epic[14] = 734
    set ItemLootRanges_21_25_Epic[15] = 784
    set ItemLootRanges_21_25_Epic[16] = 834
    set ItemLootRanges_21_25_Epic[17] = 884
    
    // Legendary (iLvl 45)
    set ItemLootRanges_21_25_Legendary[1] = 94
    set ItemLootRanges_21_25_Legendary[2] = 144
    set ItemLootRanges_21_25_Legendary[3] = 194
    set ItemLootRanges_21_25_Legendary[4] = 244
    set ItemLootRanges_21_25_Legendary[5] = 294
    set ItemLootRanges_21_25_Legendary[6] = 344
    set ItemLootRanges_21_25_Legendary[7] = 394
    set ItemLootRanges_21_25_Legendary[8] = 444
    set ItemLootRanges_21_25_Legendary[9] = 494
    set ItemLootRanges_21_25_Legendary[10] = 544
    set ItemLootRanges_21_25_Legendary[11] = 594
    set ItemLootRanges_21_25_Legendary[12] = 644
    set ItemLootRanges_21_25_Legendary[13] = 694
    set ItemLootRanges_21_25_Legendary[14] = 744
    set ItemLootRanges_21_25_Legendary[15] = 794
    set ItemLootRanges_21_25_Legendary[16] = 844
    set ItemLootRanges_21_25_Legendary[17] = 894
    
    // ===== LOOT RANGES - LEVELS 26-30 =====
    // Common (iLvl 30)
    set ItemLootRanges_26_30_Common[1] = 55
    set ItemLootRanges_26_30_Common[2] = 105
    set ItemLootRanges_26_30_Common[3] = 155
    set ItemLootRanges_26_30_Common[4] = 205
    set ItemLootRanges_26_30_Common[5] = 255
    set ItemLootRanges_26_30_Common[6] = 305
    set ItemLootRanges_26_30_Common[7] = 355
    set ItemLootRanges_26_30_Common[8] = 405
    set ItemLootRanges_26_30_Common[9] = 455
    set ItemLootRanges_26_30_Common[10] = 505
    set ItemLootRanges_26_30_Common[11] = 555
    set ItemLootRanges_26_30_Common[12] = 605
    set ItemLootRanges_26_30_Common[13] = 655
    set ItemLootRanges_26_30_Common[14] = 705
    set ItemLootRanges_26_30_Common[15] = 755
    set ItemLootRanges_26_30_Common[16] = 805
    set ItemLootRanges_26_30_Common[17] = 855
    
    // Uncommon (iLvl 35)
    set ItemLootRanges_26_30_Uncommon[1] = 65
    set ItemLootRanges_26_30_Uncommon[2] = 115
    set ItemLootRanges_26_30_Uncommon[3] = 165
    set ItemLootRanges_26_30_Uncommon[4] = 215
    set ItemLootRanges_26_30_Uncommon[5] = 265
    set ItemLootRanges_26_30_Uncommon[6] = 315
    set ItemLootRanges_26_30_Uncommon[7] = 365
    set ItemLootRanges_26_30_Uncommon[8] = 415
    set ItemLootRanges_26_30_Uncommon[9] = 465
    set ItemLootRanges_26_30_Uncommon[10] = 515
    set ItemLootRanges_26_30_Uncommon[11] = 565
    set ItemLootRanges_26_30_Uncommon[12] = 615
    set ItemLootRanges_26_30_Uncommon[13] = 665
    set ItemLootRanges_26_30_Uncommon[14] = 715
    set ItemLootRanges_26_30_Uncommon[15] = 765
    set ItemLootRanges_26_30_Uncommon[16] = 815
    set ItemLootRanges_26_30_Uncommon[17] = 865
    
    // Rare (iLvl 40)
    set ItemLootRanges_26_30_Rare[1] = 75
    set ItemLootRanges_26_30_Rare[2] = 125
    set ItemLootRanges_26_30_Rare[3] = 175
    set ItemLootRanges_26_30_Rare[4] = 225
    set ItemLootRanges_26_30_Rare[5] = 275
    set ItemLootRanges_26_30_Rare[6] = 325
    set ItemLootRanges_26_30_Rare[7] = 375
    set ItemLootRanges_26_30_Rare[8] = 425
    set ItemLootRanges_26_30_Rare[9] = 475
    set ItemLootRanges_26_30_Rare[10] = 525
    set ItemLootRanges_26_30_Rare[11] = 575
    set ItemLootRanges_26_30_Rare[12] = 625
    set ItemLootRanges_26_30_Rare[13] = 675
    set ItemLootRanges_26_30_Rare[14] = 725
    set ItemLootRanges_26_30_Rare[15] = 775
    set ItemLootRanges_26_30_Rare[16] = 825
    set ItemLootRanges_26_30_Rare[17] = 875
    
    // Epic (iLvl 45)
    set ItemLootRanges_26_30_Epic[1] = 85
    set ItemLootRanges_26_30_Epic[2] = 135
    set ItemLootRanges_26_30_Epic[3] = 185
    set ItemLootRanges_26_30_Epic[4] = 235
    set ItemLootRanges_26_30_Epic[5] = 285
    set ItemLootRanges_26_30_Epic[6] = 335
    set ItemLootRanges_26_30_Epic[7] = 385
    set ItemLootRanges_26_30_Epic[8] = 435
    set ItemLootRanges_26_30_Epic[9] = 485
    set ItemLootRanges_26_30_Epic[10] = 535
    set ItemLootRanges_26_30_Epic[11] = 585
    set ItemLootRanges_26_30_Epic[12] = 635
    set ItemLootRanges_26_30_Epic[13] = 685
    set ItemLootRanges_26_30_Epic[14] = 735
    set ItemLootRanges_26_30_Epic[15] = 785
    set ItemLootRanges_26_30_Epic[16] = 835
    set ItemLootRanges_26_30_Epic[17] = 885
    
    // Legendary (iLvl 50)
    set ItemLootRanges_26_30_Legendary[1] = 95
    set ItemLootRanges_26_30_Legendary[2] = 145
    set ItemLootRanges_26_30_Legendary[3] = 195
    set ItemLootRanges_26_30_Legendary[4] = 245
    set ItemLootRanges_26_30_Legendary[5] = 295
    set ItemLootRanges_26_30_Legendary[6] = 345
    set ItemLootRanges_26_30_Legendary[7] = 395
    set ItemLootRanges_26_30_Legendary[8] = 445
    set ItemLootRanges_26_30_Legendary[9] = 495
    set ItemLootRanges_26_30_Legendary[10] = 545
    set ItemLootRanges_26_30_Legendary[11] = 595
    set ItemLootRanges_26_30_Legendary[12] = 645
    set ItemLootRanges_26_30_Legendary[13] = 695
    set ItemLootRanges_26_30_Legendary[14] = 745
    set ItemLootRanges_26_30_Legendary[15] = 795
    set ItemLootRanges_26_30_Legendary[16] = 845
    set ItemLootRanges_26_30_Legendary[17] = 895
    
    // ===== UNIT TYPE MAPPINGS =====
    // Wolves
    set UnitLootTypeTable['n001'] = LOOT_TYPE_WOLF  // Timber Wolf (Level 2)
    set UnitLootTypeTable['n002'] = LOOT_TYPE_WOLF  // Giant Wolf (Level 4)
    set UnitLootTypeTable['n003'] = LOOT_TYPE_WOLF  // Dire Wolf (Level 5)
    
    // Stags
    set UnitLootTypeTable['n004'] = LOOT_TYPE_STAG  // Stag (Level 1)
    set UnitLootTypeTable['n005'] = LOOT_TYPE_STAG  // Stag (Level 5)
    
    // Gnolls
    set UnitLootTypeTable['n006'] = LOOT_TYPE_GNOLL  // Gnoll
    set UnitLootTypeTable['n007'] = LOOT_TYPE_GNOLL  // Gnoll Brute
    set UnitLootTypeTable['n008'] = LOOT_TYPE_GNOLL  // Gnoll Crusher
    set UnitLootTypeTable['n009'] = LOOT_TYPE_GNOLL  // Gnoll Necromancer
    set UnitLootTypeTable['n00A'] = LOOT_TYPE_GNOLL  // Gnoll Ravager
    set UnitLootTypeTable['n00B'] = LOOT_TYPE_GNOLL  // Deathlord Fel'Dok (also gnoll)
    set UnitLootTypeTable['n00C'] = LOOT_TYPE_GNOLL  // Gnoll Poacher
    set UnitLootTypeTable['n00D'] = LOOT_TYPE_GNOLL  // Gnoll Assassin
    set UnitLootTypeTable['n00E'] = LOOT_TYPE_GNOLL  // Gnoll Warden
    set UnitLootTypeTable['n00F'] = LOOT_TYPE_GNOLL  // Gnoll Overseer
    
    // Dragons (Level 6-10)
    set UnitLootTypeTable['n020'] = LOOT_TYPE_DRAGON_WHELP_6_10   // Red Whelp (Level 10)
    set UnitLootTypeTable['n021'] = LOOT_TYPE_DRAGON_WHELP_6_10   // Scorching Whelp (Level 10)
    
    // Dragons (Level 16-20)
    set UnitLootTypeTable['n022'] = LOOT_TYPE_DRAGON_WHELP_16_20  // Red Whelp (Level 20)
    set UnitLootTypeTable['n023'] = LOOT_TYPE_DRAGON_WHELP_16_20  // Scorching Whelp (Level 20)
    
    // ===== BOSS TYPE MAPPINGS =====
    set UnitLootTypeTable['U001'] = BOSS_FELDOK          // Deathlord Fel'Dok
    set UnitLootTypeTable['U002'] = BOSS_MARGUL          // Margul
    set UnitLootTypeTable['U003'] = BOSS_MURGAL          // Mur'gal
    set UnitLootTypeTable['U004'] = BOSS_SARGOTH         // Sargoth
    set UnitLootTypeTable['U005'] = BOSS_UNKNOWN_ENTITY  // Unknown Entity
    set UnitLootTypeTable['U006'] = BOSS_ROLJIN          // Rol'jin
    set UnitLootTypeTable['U007'] = BOSS_SUCCUBUS        // Velaria (Succubus)
    set UnitLootTypeTable['U008'] = BOSS_COLOSSUS        // Colossus
    set UnitLootTypeTable['U009'] = BOSS_GOLLUM          // Gollum
    set UnitLootTypeTable['U00A'] = BOSS_MORDRAX         // Mordrax
    
    // ===== DESTRUCTIBLE TYPE MAPPINGS =====
    // Crates by level
    set DestructibleLevelTable['B001'] = 3   // Crates (Level 1-5)
    set DestructibleLevelTable['B002'] = 8   // Crates (Level 6-10)
    set DestructibleLevelTable['B003'] = 13  // Crates (Level 11-15)
    set DestructibleLevelTable['B004'] = 18  // Crates (Level 16-20)
    set DestructibleLevelTable['B005'] = 23  // Crates (Level 21-25)
    set DestructibleLevelTable['B006'] = 28  // Crates (Level 26-30)
    
    // Barrels by level
    set DestructibleLevelTable['B010'] = 3   // Barrel (Level 1-5)
    set DestructibleLevelTable['B011'] = 8   // Barrel (Level 6-10)
    set DestructibleLevelTable['B012'] = 13  // Barrel (Level 11-15)
    set DestructibleLevelTable['B013'] = 18  // Barrel (Level 16-20)
    set DestructibleLevelTable['B014'] = 23  // Barrel (Level 21-25)
    set DestructibleLevelTable['B015'] = 28  // Barrel (Level 26-30)
endfunction

//===========================================================================
endlibrary
//===========================================================================
