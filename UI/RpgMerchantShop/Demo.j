scope Demo initializer OnInit

globals
    private RpgMerchantShop demoShop
endglobals

private function OnInit takes nothing returns nothing
    local integer weapons
    local integer armor
    local integer accessories
    local integer potions
    local integer materials
    local integer scrolls
    local integer misc
    local integer common
    local integer uncommon
    local integer rare
    local integer epic
    local integer legendary

    set demoShop = RpgMerchantShop.create("MERCHANT'S STORE")
    call demoShop.setVisualStyle("Fonts\\FRIZQT__.TTF", "UI\\Widgets\\EscMenu\\Human\\blank-background.blp", "UI\\Widgets\\EscMenu\\Human\\human-options-menu-background.blp", "UI\\Widgets\\ToolTips\\Human\\human-tooltip-background.blp")
    call demoShop.setVisibleItemSlotCount(8)

    set weapons = demoShop.addCategory("Weapons")
    set armor = demoShop.addCategory("Armor")
    set accessories = demoShop.addCategory("Accessories")
    set potions = demoShop.addCategory("Potions")
    set materials = demoShop.addCategory("Materials")
    set scrolls = demoShop.addCategory("Scrolls")
    set misc = demoShop.addCategory("Miscellaneous")

    set common = demoShop.addRarity("COMMON", "|cffffffff")
    set uncommon = demoShop.addRarity("UNCOMMON", "|cff66ff66")
    set rare = demoShop.addRarity("RARE", "|cff66aaff")
    set epic = demoShop.addRarity("EPIC", "|cffcc66ff")
    set legendary = demoShop.addRarity("LEGENDARY", "|cffff9900")

    call demoShop.addItem("Abyssal Greatsword", "ReplaceableTextures\\CommandButtons\\BTNArcaniteMelee.blp", weapons, epic, 48750, 126, 0, 'ratf', "+15 Strength|n+8% Life Steal|nSoul Drain: chance to restore health on hit.")
    call demoShop.addItem("Dragonscale Armor", "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp", armor, legendary, 72500, 0, 87, 'rde4', "Armor crafted from ancient dragon scales.|nIncredibly tough and heat resistant.")
    call demoShop.addItem("Arcanist's Staff", "ReplaceableTextures\\CommandButtons\\BTNStaffOfSanctuary.blp", weapons, rare, 23400, 98, 0, 'ssan', "Imbued with arcane energy.|nPerfect for masters of magic.")
    call demoShop.addItem("Pendant of Vitality", "ReplaceableTextures\\CommandButtons\\BTNPendantOfMana.blp", accessories, epic, 31250, 0, 0, 'bgst', "+250 Health|nA gem that pulses with life.")
    call demoShop.addItem("Elixir of Superior Healing", "ReplaceableTextures\\CommandButtons\\BTNPotionRed.blp", potions, rare, 1250, 0, 0, 'phea', "Restores 750 Health.|nA potent elixir for emergencies.")
    call demoShop.addItem("Shadow Cloak", "ReplaceableTextures\\CommandButtons\\BTNCloak.blp", accessories, rare, 18600, 0, 0, 'clfm', "+20% Critical Chance.|nA cloak woven from shadow.")
    call demoShop.addVirtualItem("Soulstone Shard", "ReplaceableTextures\\CommandButtons\\BTNGem.blp", materials, uncommon, 750, 0, 0, "Crafting material used to imbue powerful gear.")
    call demoShop.addItem("Ironwood Bow", "ReplaceableTextures\\CommandButtons\\BTNImprovedBows.blp", weapons, uncommon, 2150, 64, 0, 'rat9', "A sturdy bow made from reinforced ironwood.")
    call demoShop.addItem("Town Portal Scroll", "ReplaceableTextures\\CommandButtons\\BTNSnazzyScroll.blp", scrolls, common, 350, 0, 0, 'stwp', "Returns the hero to a friendly town hall.")
    call demoShop.addVirtualItem("Merchant's Chest", "ReplaceableTextures\\CommandButtons\\BTNChestOfGold.blp", misc, uncommon, 5000, 0, 0, "A sealed chest of trade goods and valuables.")
    call demoShop.addItem("Knight's Shield", "ReplaceableTextures\\CommandButtons\\BTNHumanArmorUpOne.blp", armor, rare, 9800, 0, 42, 'rde3', "A reliable shield polished with blue steel.")
    call demoShop.addVirtualItem("Crystal Focus", "ReplaceableTextures\\CommandButtons\\BTNGem.blp", materials, rare, 3200, 0, 0, "A focused crystal used by enchanters.")
    call demoShop.openFor(Player(0))
endfunction

endscope
