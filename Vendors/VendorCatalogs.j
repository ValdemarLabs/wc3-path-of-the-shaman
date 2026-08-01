/**
    VendorCatalogs

    Author: Valdemar
    Version: 1.0.0

    Description:
    Ready-to-use PotS vendor definitions for equipment, professions, factions,
    travelling trade, randomized goods, and general adventuring supplies.
    Known vendor unit types are bound automatically; map-specific units can be
    assigned through the public registration API.

    Credits:
    - Warcraft Wiki vendor taxonomy, used as role inspiration

    How to install:
    Import after Shop, VendorLines, VendorVoiceProfiles, and Reputation.

    API:
    - VendorCatalogs_VENDOR_CATALOG_* constants select one of the 26 catalogs.
    - set vendorId = VendorCatalogs_GetVendorId(catalogType)
    - call VendorCatalogs_RegisterUnit(vendor, catalogType, voiceProfile)
    - call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, voiceProfile)

**/
library VendorCatalogs initializer Init requires Shop, VendorLines, VendorVoiceProfiles, Reputation
    globals
        constant integer VENDOR_CATALOG_WEAPONS = 1
        constant integer VENDOR_CATALOG_ARMOR = 2
        constant integer VENDOR_CATALOG_SHIELDS = 3
        constant integer VENDOR_CATALOG_ARENA = 4
        constant integer VENDOR_CATALOG_TRAVELLING = 5
        constant integer VENDOR_CATALOG_FISHER = 6
        constant integer VENDOR_CATALOG_MINER = 7
        constant integer VENDOR_CATALOG_COOK = 8
        constant integer VENDOR_CATALOG_ALCHEMY_SUPPLIES = 9
        constant integer VENDOR_CATALOG_BLACKSMITHING_SUPPLIES = 10
        constant integer VENDOR_CATALOG_COOKING_SUPPLIES = 11
        constant integer VENDOR_CATALOG_ENCHANTING_SUPPLIES = 12
        constant integer VENDOR_CATALOG_FISHING_SUPPLIES = 13
        constant integer VENDOR_CATALOG_LEATHERWORKING_SUPPLIES = 14
        constant integer VENDOR_CATALOG_MINING_SUPPLIES = 15
        constant integer VENDOR_CATALOG_SKINNING_SUPPLIES = 16
        constant integer VENDOR_CATALOG_PROFESSION_SUPPLIES = 17
        constant integer VENDOR_CATALOG_QUARTERMASTER = 18
        constant integer VENDOR_CATALOG_RANDOMIZED_GOODS = 19
        constant integer VENDOR_CATALOG_REAGENTS = 20
        constant integer VENDOR_CATALOG_FOOD_AND_DRINK = 21
        constant integer VENDOR_CATALOG_POTIONS = 22
        constant integer VENDOR_CATALOG_RARE_GOODS = 23
        constant integer VENDOR_CATALOG_ADVENTURING_SUPPLIES = 24
        constant integer VENDOR_CATALOG_TRADE_GOODS = 25
        constant integer VENDOR_CATALOG_BEAST_SUPPLIES = 26

        private constant integer VC_MAX_CATALOGS = 26
        private integer array VC_VendorId
    endglobals

    private function CreateCatalog takes integer catalogType, string name, string vendorType, integer unitTypeId returns nothing
        set VC_VendorId[catalogType] = Shop_CreateVendor(name, unitTypeId)
        call Shop_SetVendorTypeLabel(VC_VendorId[catalogType], vendorType)
    endfunction

    private function AddStock takes integer catalogType, integer itemTypeId, integer price, string category returns integer
        return Shop_AddStock(VC_VendorId[catalogType], itemTypeId, price, category)
    endfunction

    private function AddZoneStock takes integer catalogType, integer itemTypeId, integer price, string category, integer zoneId returns nothing
        local integer stockId = AddStock(catalogType, itemTypeId, price, category)

        call Shop_SetStockZone(stockId, zoneId, true)
    endfunction

    private function RegisterRole takes string profileName, string greetingA, string greetingB, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterBasicLines(profileName, greetingA, greetingB, "Let us see what changes hands.", "Safe roads until next time.")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
    endfunction

    private function ConfigureCatalogs takes nothing returns nothing
        // Explicit merchant unit types and selected generic vendor placeholders
        // are bound here. Change these rawcodes when map placement roles settle.
        set VC_VendorId[VENDOR_CATALOG_WEAPONS] = 0
        call CreateCatalog(VENDOR_CATALOG_WEAPONS, "Weapons Merchant", VendorLines_TYPE_WEAPONS, 'o60Q')
        call CreateCatalog(VENDOR_CATALOG_ARMOR, "Armor Merchant", VendorLines_TYPE_ARMOR, 'o60G')
        call CreateCatalog(VENDOR_CATALOG_SHIELDS, "Shield Merchant", VendorLines_TYPE_SHIELDS, 'o62H')
        call CreateCatalog(VENDOR_CATALOG_ARENA, "Arena Quartermaster", VendorLines_TYPE_ARENA, 'N60L')
        call CreateCatalog(VENDOR_CATALOG_TRAVELLING, "Travelling Merchant", VendorLines_TYPE_TRAVELLING, 'h00H')
        call CreateCatalog(VENDOR_CATALOG_FISHER, "Fisher", VendorLines_TYPE_FISHER, 'o62I')
        call CreateCatalog(VENDOR_CATALOG_MINER, "Miner", VendorLines_TYPE_MINER, 0)
        call CreateCatalog(VENDOR_CATALOG_COOK, "Cook", VendorLines_TYPE_COOK, 'o60I')
        call CreateCatalog(VENDOR_CATALOG_ALCHEMY_SUPPLIES, "Alchemy Supplier", VendorLines_TYPE_ALCHEMY_SUPPLIES, 'o62F')
        call CreateCatalog(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, "Blacksmithing Supplier", VendorLines_TYPE_BLACKSMITHING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_COOKING_SUPPLIES, "Cooking Supplier", VendorLines_TYPE_COOKING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_ENCHANTING_SUPPLIES, "Enchanting Supplier", VendorLines_TYPE_ENCHANTING_SUPPLIES, 'n60N')
        call CreateCatalog(VENDOR_CATALOG_FISHING_SUPPLIES, "Fishing Supplier", VendorLines_TYPE_FISHING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, "Leatherworking Supplier", VendorLines_TYPE_LEATHERWORKING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_MINING_SUPPLIES, "Mining Supplier", VendorLines_TYPE_MINING_SUPPLIES, 'o62G')
        call CreateCatalog(VENDOR_CATALOG_SKINNING_SUPPLIES, "Skinning Supplier", VendorLines_TYPE_SKINNING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_PROFESSION_SUPPLIES, "Profession Supplier", VendorLines_TYPE_PROFESSION_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_QUARTERMASTER, "Faction Quartermaster", VendorLines_TYPE_FACTION_QUARTERMASTER, 0)
        call CreateCatalog(VENDOR_CATALOG_RANDOMIZED_GOODS, "Curiosity Merchant", VendorLines_TYPE_RANDOMIZED_GOODS, 0)
        call CreateCatalog(VENDOR_CATALOG_REAGENTS, "Reagent Merchant", VendorLines_TYPE_REAGENTS, 0)
        call CreateCatalog(VENDOR_CATALOG_FOOD_AND_DRINK, "Provisioner", VendorLines_TYPE_FOOD_AND_DRINK, 0)
        call CreateCatalog(VENDOR_CATALOG_POTIONS, "Potion Seller", VendorLines_TYPE_POTIONS, 0)
        call CreateCatalog(VENDOR_CATALOG_RARE_GOODS, "Rare Goods Dealer", VendorLines_TYPE_RARE_GOODS, 0)
        call CreateCatalog(VENDOR_CATALOG_ADVENTURING_SUPPLIES, "Expedition Supplier", VendorLines_TYPE_ADVENTURING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_TRADE_GOODS, "Trade Goods Merchant", VendorLines_TYPE_TRADE_GOODS, 0)
        call CreateCatalog(VENDOR_CATALOG_BEAST_SUPPLIES, "Beastmaster Supplier", VendorLines_TYPE_BEAST_SUPPLIES, 'o001')
    endfunction

    private function ConfigureEquipmentStock takes nothing returns nothing
        local integer stockId

        call AddStock(VENDOR_CATALOG_WEAPONS, 'I6B1', 60, "Swords")
        call AddStock(VENDOR_CATALOG_WEAPONS, 'I6B2', 65, "Axes")
        call AddStock(VENDOR_CATALOG_WEAPONS, 'I6B4', 130, "Axes")
        call AddStock(VENDOR_CATALOG_WEAPONS, 'stwa', 260, "Two-Handed")
        call AddStock(VENDOR_CATALOG_WEAPONS, 'I65K', 850, "Swords")

        call AddStock(VENDOR_CATALOG_ARMOR, 'I68F', 140, "Mail")
        call AddStock(VENDOR_CATALOG_ARMOR, 'I68M', 120, "Mail")
        call AddStock(VENDOR_CATALOG_ARMOR, 'I66B', 90, "Leather")
        call AddStock(VENDOR_CATALOG_ARMOR, 'I668', 70, "Leather")
        call AddStock(VENDOR_CATALOG_ARMOR, 'I65S', 1200, "Plate")

        call AddStock(VENDOR_CATALOG_SHIELDS, 'I66E', 55, "Shields")
        call AddStock(VENDOR_CATALOG_SHIELDS, 'I6B6', 90, "Shields")
        call AddStock(VENDOR_CATALOG_SHIELDS, 'I62D', 450, "Shields")
        call AddStock(VENDOR_CATALOG_SHIELDS, 'I62Z', 900, "Shields")

        set stockId = AddStock(VENDOR_CATALOG_ARENA, 'I60R', 1200, "Arena Armor")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_FRIENDLY)
        set stockId = AddStock(VENDOR_CATALOG_ARENA, 'I60S', 1400, "Arena Armor")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_FRIENDLY)
        set stockId = AddStock(VENDOR_CATALOG_ARENA, 'I60T', 2200, "Arena Armor")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_COVENANT)
        set stockId = AddStock(VENDOR_CATALOG_ARENA, 'I60V', 1800, "Arena Armor")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_COVENANT)
    endfunction

    private function ConfigureProfessionStock takes nothing returns nothing
        call AddStock(VENDOR_CATALOG_FISHER, 'I6CQ', 50, "Fishing Poles")
        call AddStock(VENDOR_CATALOG_FISHER, 'I6CR', 250, "Fishing Poles")
        call AddStock(VENDOR_CATALOG_FISHER, 'I6CU', 15, "Fish")
        call AddStock(VENDOR_CATALOG_FISHER, 'I6CV', 20, "Fish")

        call AddStock(VENDOR_CATALOG_MINER, 'I672', 75, "Tools")
        call AddStock(VENDOR_CATALOG_MINER, 'I67E', 35, "Ore")
        call AddStock(VENDOR_CATALOG_MINER, 'I67F', 55, "Ore")
        call AddStock(VENDOR_CATALOG_MINER, 'I67H', 90, "Ore")
        call AddStock(VENDOR_CATALOG_MINER, 'I689', 25, "Fuel")

        call AddStock(VENDOR_CATALOG_COOK, 'j2b0', 20, "Food")
        call AddStock(VENDOR_CATALOG_COOK, 'j2b1', 25, "Food")
        call AddStock(VENDOR_CATALOG_COOK, 'j2b4', 55, "Food")
        call AddStock(VENDOR_CATALOG_COOK, 'j3a0', 30, "Drinks")
        call AddStock(VENDOR_CATALOG_COOK, 'I60Z', 20, "Drinks")

        call AddStock(VENDOR_CATALOG_ALCHEMY_SUPPLIES, 'I60Y', 20, "Herbs")
        call AddStock(VENDOR_CATALOG_ALCHEMY_SUPPLIES, 'i1db', 65, "Herbs")
        call AddStock(VENDOR_CATALOG_ALCHEMY_SUPPLIES, 'I6C6', 80, "Reagents")
        call AddStock(VENDOR_CATALOG_ALCHEMY_SUPPLIES, 'I6BB', 35, "Reagents")

        call AddStock(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, 'j1d2', 75, "Tools")
        call AddStock(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, 'I689', 25, "Fuel")
        call AddStock(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, 'I67E', 35, "Ore")
        call AddStock(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, 'I67H', 90, "Ore")

        call AddStock(VENDOR_CATALOG_COOKING_SUPPLIES, 'I611', 35, "Tools")
        call AddStock(VENDOR_CATALOG_COOKING_SUPPLIES, 'I620', 20, "Meat")
        call AddStock(VENDOR_CATALOG_COOKING_SUPPLIES, 'I61O', 20, "Meat")
        call AddStock(VENDOR_CATALOG_COOKING_SUPPLIES, 'I6CU', 15, "Fish")

        call AddStock(VENDOR_CATALOG_ENCHANTING_SUPPLIES, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_ENCHANTING_SUPPLIES, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_ENCHANTING_SUPPLIES, 'I6E0', 110, "Essences")

        call AddStock(VENDOR_CATALOG_FISHING_SUPPLIES, 'I6CQ', 50, "Poles")
        call AddStock(VENDOR_CATALOG_FISHING_SUPPLIES, 'I6CR', 250, "Poles")
        call AddStock(VENDOR_CATALOG_FISHING_SUPPLIES, 'I6CS', 700, "Poles")

        call AddStock(VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, 'I66M', 75, "Tools")
        call AddStock(VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, 'I6A6', 35, "Leather")
        call AddStock(VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, 'I6A7', 70, "Leather")
        call AddStock(VENDOR_CATALOG_LEATHERWORKING_SUPPLIES, 'I6A8', 120, "Leather")

        call AddStock(VENDOR_CATALOG_MINING_SUPPLIES, 'I672', 75, "Tools")
        call AddStock(VENDOR_CATALOG_MINING_SUPPLIES, 'I689', 25, "Fuel")
        call AddStock(VENDOR_CATALOG_MINING_SUPPLIES, 'I67E', 35, "Ore")
        call AddStock(VENDOR_CATALOG_MINING_SUPPLIES, 'I67H', 90, "Ore")

        call AddStock(VENDOR_CATALOG_SKINNING_SUPPLIES, 'I66M', 75, "Tools")
        call AddStock(VENDOR_CATALOG_SKINNING_SUPPLIES, 'I61B', 30, "Skins")
        call AddStock(VENDOR_CATALOG_SKINNING_SUPPLIES, 'I61C', 35, "Skins")
        call AddStock(VENDOR_CATALOG_SKINNING_SUPPLIES, 'I61F', 30, "Skins")

        call AddStock(VENDOR_CATALOG_PROFESSION_SUPPLIES, 'I672', 75, "Mining")
        call AddStock(VENDOR_CATALOG_PROFESSION_SUPPLIES, 'I66M', 75, "Skinning")
        call AddStock(VENDOR_CATALOG_PROFESSION_SUPPLIES, 'I6CQ', 50, "Fishing")
        call AddStock(VENDOR_CATALOG_PROFESSION_SUPPLIES, 'I611', 35, "Cooking")
        call AddStock(VENDOR_CATALOG_PROFESSION_SUPPLIES, 'j1d2', 75, "Blacksmithing")
    endfunction

    private function ConfigureGeneralStock takes nothing returns nothing
        local integer stockId

        call AddStock(VENDOR_CATALOG_TRAVELLING, 'I6BD', 35, "Consumables")
        call AddStock(VENDOR_CATALOG_TRAVELLING, 'I6BS', 35, "Consumables")
        call AddStock(VENDOR_CATALOG_TRAVELLING, 'I611', 35, "Utility")
        call AddZoneStock(VENDOR_CATALOG_TRAVELLING, 'hslv', 45, "Riverbane Goods", 10)
        call AddZoneStock(VENDOR_CATALOG_TRAVELLING, 'I60Z', 20, "Stormhaven Goods", 13)
        call AddZoneStock(VENDOR_CATALOG_TRAVELLING, 'I60Y', 25, "Forest Goods", 2)
        call AddZoneStock(VENDOR_CATALOG_TRAVELLING, 'I689', 30, "Mountain Goods", 3)
        call AddZoneStock(VENDOR_CATALOG_TRAVELLING, 'I6CV', 25, "Sirensong Goods", 14)

        set stockId = AddStock(VENDOR_CATALOG_QUARTERMASTER, 'I010', 300, "Supplies")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_FRIENDLY)
        set stockId = AddStock(VENDOR_CATALOG_QUARTERMASTER, 'I6AN', 600, "Supplies")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_COVENANT)
        set stockId = AddStock(VENDOR_CATALOG_QUARTERMASTER, 'I65K', 1000, "Equipment")
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_COVENANT)

        set stockId = Shop_AddRandomStock(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 'I6B1', 200, "Rotating Equipment")
        call Shop_AddRandomStockOption(stockId, 'I6B2')
        call Shop_AddRandomStockOption(stockId, 'I6B6')
        call Shop_AddRandomStockOption(stockId, 'I66E')
        set stockId = Shop_AddRandomStock(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 'phea', 100, "Rotating Consumables")
        call Shop_AddRandomStockOption(stockId, 'pman')
        call Shop_AddRandomStockOption(stockId, 'hslv')
        call Shop_AddRandomStockOption(stockId, 'I6BC')
        set stockId = Shop_AddRandomStock(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 'I60Y', 80, "Rotating Materials")
        call Shop_AddRandomStockOption(stockId, 'I689')
        call Shop_AddRandomStockOption(stockId, 'I67E')
        call Shop_AddRandomStockOption(stockId, 'I6A6')
        call Shop_SetVendorRandomStockOnTrade(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], true)

        call AddStock(VENDOR_CATALOG_REAGENTS, 'I60Y', 20, "Herbs")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I6BB', 35, "Water")

        call AddStock(VENDOR_CATALOG_FOOD_AND_DRINK, 'j2b0', 20, "Food")
        call AddStock(VENDOR_CATALOG_FOOD_AND_DRINK, 'j2b4', 55, "Food")
        call AddStock(VENDOR_CATALOG_FOOD_AND_DRINK, 'I60Z', 20, "Drinks")
        call AddStock(VENDOR_CATALOG_FOOD_AND_DRINK, 'j3a0', 30, "Drinks")

        call AddStock(VENDOR_CATALOG_POTIONS, 'I6BD', 35, "Healing")
        call AddStock(VENDOR_CATALOG_POTIONS, 'phea', 90, "Healing")
        call AddStock(VENDOR_CATALOG_POTIONS, 'I6BS', 35, "Mana")
        call AddStock(VENDOR_CATALOG_POTIONS, 'pman', 90, "Mana")
        call AddStock(VENDOR_CATALOG_POTIONS, 'I6BG', 65, "Replenishment")

        set stockId = AddStock(VENDOR_CATALOG_RARE_GOODS, 'I62Z', 1200, "Rare Equipment")
        call Shop_SetStockSupply(stockId, 1, 600.00)
        set stockId = AddStock(VENDOR_CATALOG_RARE_GOODS, 'I6CS', 700, "Rare Tools")
        call Shop_SetStockSupply(stockId, 1, 600.00)
        set stockId = AddStock(VENDOR_CATALOG_RARE_GOODS, 'I67K', 450, "Rare Materials")
        call Shop_SetStockSupply(stockId, 2, 480.00)

        call AddStock(VENDOR_CATALOG_ADVENTURING_SUPPLIES, 'I611', 35, "Camp")
        call AddStock(VENDOR_CATALOG_ADVENTURING_SUPPLIES, 'hslv', 45, "Recovery")
        call AddStock(VENDOR_CATALOG_ADVENTURING_SUPPLIES, 'I60Z', 20, "Provisions")
        call AddStock(VENDOR_CATALOG_ADVENTURING_SUPPLIES, 'I672', 75, "Tools")
        call AddStock(VENDOR_CATALOG_ADVENTURING_SUPPLIES, 'I66M', 75, "Tools")

        call AddStock(VENDOR_CATALOG_TRADE_GOODS, 'I689', 25, "Materials")
        call AddStock(VENDOR_CATALOG_TRADE_GOODS, 'I67E', 35, "Materials")
        call AddStock(VENDOR_CATALOG_TRADE_GOODS, 'I6A6', 35, "Materials")
        call AddStock(VENDOR_CATALOG_TRADE_GOODS, 'I60Y', 20, "Materials")

        call AddStock(VENDOR_CATALOG_BEAST_SUPPLIES, 'I61O', 20, "Feed")
        call AddStock(VENDOR_CATALOG_BEAST_SUPPLIES, 'I620', 20, "Feed")
        call AddStock(VENDOR_CATALOG_BEAST_SUPPLIES, 'hslv', 45, "Care")
        call AddStock(VENDOR_CATALOG_BEAST_SUPPLIES, 'I66M', 75, "Tools")
    endfunction

    private function ConfigureRoleLines takes nothing returns nothing
        call RegisterRole("Weapons Merchant", "Looking for a proper weapon?", "Steel for every fighting style.", "A weapon should suit the hand before it suits the eye.", "Edges, hafts, balance. Choose all three wisely.", "That one is ready for battle.", "I can put a new edge on this.", "Old weapon out, stronger weapon in.", "No blade today? Trouble rarely waits.")
        call RegisterRole("Armor Merchant", "Armor for road or war.", "Protection is cheaper than recovery.", "Good armor bends where it should and nowhere else.", "Mail for movement, plate for confidence.", "A sound choice. Wear it well.", "This can be patched and sold again.", "Less burden, better protection.", "Come back before the next battle, not after.")
        call RegisterRole("Shield Merchant", "A shield keeps tomorrow possible.", "Round, broad, light, or reinforced.", "A shield is only useful when raised in time.", "Mind the straps; they matter more than decoration.", "That will turn a hard blow.", "The face is scarred, but the frame is useful.", "A stronger wall for your shield arm.", "Planning to block with your face instead?")
        call RegisterRole("Arena Quartermaster", "Marks and coin buy an edge here.", "Champions need equipment worthy of the sand.", "Arena gear is tested under very direct conditions.", "The crowd remembers victories, not repair bills.", "Take it into the ring and earn its price.", "Someone else may fight better with this.", "A champion's exchange.", "Spectating remains the inexpensive option.")
        call RegisterRole("Travelling Merchant", "My road brought me here at the right time.", "The cart moves, but the bargains linger.", "Local stock changes at every stop.", "Buy now; the next road may carry me elsewhere.", "One less thing to haul onward.", "I know a market down the road for this.", "A profitable stop for both of us.", "Then I will save the cart space.")
        call RegisterRole("Fisher", "Fresh catch and sound tackle.", "The water always has another secret.", "Good line catches fish; patience catches stories.", "Never trust a calm pool without testing it.", "May the next cast repay you.", "Fresh enough for stew.", "Tackle out, catch in.", "The fish are browsing more eagerly.")
        call RegisterRole("Miner", "Tools and ore from honest stone.", "The mountain charges in sweat.", "Listen before you swing; stone warns the careful.", "A dull pick makes a long tunnel.", "That should bite cleanly into rock.", "There is metal left in this yet.", "Ore and tools, fairly exchanged.", "The mountain will still be there tomorrow.")
        call RegisterRole("Cook", "Hungry travelers make sensible customers.", "Sit, eat, and face the road stronger.", "A full stomach improves nearly every plan.", "Fresh ingredients need very little boasting.", "Eat it while it is worth eating.", "I can make use of that in the kitchen.", "Provisions traded and appetites answered.", "Come back when hunger wins.")
        call RegisterRole("Alchemy Supplier", "Measured reagents, clean bottles.", "Do not taste anything without asking.", "Alchemy rewards precision and punishes optimism.", "Fresh water matters as much as rare herbs.", "Keep the stopper tight.", "Useful material, once properly cleaned.", "A balanced exchange, unlike some mixtures.", "No experiments today? Sensible, perhaps.")
        call RegisterRole("Blacksmithing Supplier", "Coal, ore, and proper smithing tools.", "A forge is only as good as its fuel.", "Cheap coal wastes expensive metal.", "Keep a second hammer near the anvil.", "Your forge is ready for work.", "Scrap becomes stock with enough heat.", "Fuel in, salvage out.", "The forge can wait, but rust will not.")
        call RegisterRole("Cooking Supplier", "Ingredients and camp tools here.", "Good meals begin before the fire is lit.", "Pack dry fuel and fresher meat.", "A cook's knife should never be an afterthought.", "That belongs over a steady flame.", "I can season or preserve this.", "A lighter pantry, a better meal.", "No supplies means a cold supper.")
        call RegisterRole("Enchanting Supplier", "Crystals and essences, carefully handled.", "Magic leaves residue. I sell the useful kind.", "Every enchantment begins with something being consumed.", "Do not store volatile essences beside lunch.", "May the magic hold true.", "This still carries a trace worth keeping.", "Old magic becomes new work.", "The mundane life has its admirers.")
        call RegisterRole("Fishing Supplier", "Poles for streams, coast, and deep water.", "Strong line costs less than lost fish.", "Match the pole to the water, not your pride.", "Salt ruins tackle faster than monsters do.", "A fine choice for the next pool.", "I can salvage the fittings.", "Old tackle traded for a better cast.", "The water will wait.")
        call RegisterRole("Leatherworking Supplier", "Leather, hides, and cutting tools.", "Good leather remembers careful hands.", "Work with the grain, never against it.", "Dry hides slowly if you want them strong.", "That will take a clean stitch.", "I can trim useful pieces from this.", "Fresh material for worn gear.", "No stitching today, then.")
        call RegisterRole("Mining Supplier", "Picks, coal, and workable ore.", "Everything here was earned one strike at a time.", "Carry wedges when the stone turns stubborn.", "Rich veins punish careless miners first.", "A reliable tool for hard ground.", "I will sort the metal from the waste.", "Tools and ore exchanged cleanly.", "Return when the rock starts calling.")
        call RegisterRole("Skinning Supplier", "Knives and hides for practiced hands.", "A clean cut preserves the value.", "Keep the blade short, sharp, and controlled.", "The wilds provide if nothing is wasted.", "That edge should serve you well.", "This hide can still be worked.", "Tools out, useful hides in.", "The beasts will not skin themselves.")
        call RegisterRole("Profession Supplier", "Tools for every useful trade.", "One stall, many crafts.", "A missing tool can stop an entire expedition.", "Professionals buy spares before they need them.", "That should keep your work moving.", "Another craft will find a use for this.", "Many trades, one fair exchange.", "Come back when work creates a need.")
        call RegisterRole("Faction Quartermaster", "Standing earns access to the best stores.", "Service is remembered here.", "Trusted allies see stock others do not.", "Reputation opens storerooms coin cannot.", "Your service has earned this.", "The faction can reclaim value from it.", "Supplies exchanged among trusted hands.", "More service may reveal better stock.")
        call RegisterRole("Curiosity Merchant", "The selection changes whenever fortune stirs.", "Rare, odd, and occasionally useful.", "Close the stall and open it again; fate may restock it.", "Certainty is expensive. Curiosity is profitable.", "A brave purchase.", "How wonderfully unexpected.", "Chance favored the exchange.", "Even fortune cannot tempt you today.")
        call RegisterRole("Reagent Merchant", "Reagents for practical and arcane work.", "Everything measured, labeled, and mostly stable.", "Purity decides whether a spell sings or sputters.", "Keep crystals apart unless sparks are intended.", "Exactly what the formula calls for.", "I can refine this.", "Raw material traded for prepared stock.", "Return when the recipe demands it.")
        call RegisterRole("Provisioner", "Food and drink for the road.", "Fresh provisions, clean water.", "Never begin a long road on an empty stomach.", "Water weighs less than regret.", "Packed for travel.", "Someone less particular will eat this.", "Old provisions out, fresh supplies in.", "Hunger will negotiate later.")
        call RegisterRole("Potion Seller", "Healing, mana, and restorative mixtures.", "Read the label before the emergency.", "Potions work best before the final breath.", "Never mix two bottles because the colors match.", "Keep it within reach.", "The bottle is worth something, at least.", "Used stock traded for fresh remedies.", "May you remain healthy enough to reconsider.")
        call RegisterRole("Rare Goods Dealer", "Uncommon goods for uncommon customers.", "Limited stock, limited patience.", "Rarity is supply arguing with demand.", "If you see it twice, buy it the second time.", "There may not be another.", "Interesting. I know a collector.", "One rarity replaces another.", "The rarest purchase is restraint.")
        call RegisterRole("Expedition Supplier", "Everything needed beyond the safe road.", "Prepare here or improvise badly later.", "A campfire, salve, and proper tool solve many problems.", "Expeditions fail from small omissions.", "Your pack is better prepared now.", "I can equip another traveler with this.", "Old weight exchanged for useful supplies.", "The wilderness charges more than I do.")
        call RegisterRole("Trade Goods Merchant", "Materials bought and sold in useful quantities.", "Every craft begins with ordinary goods.", "Common materials keep uncommon work moving.", "Markets are built one crate at a time.", "Useful stock for useful work.", "Another artisan will need this.", "Materials exchanged without waste.", "The warehouses remain patient.")
        call RegisterRole("Beastmaster Supplier", "Feed and field care for loyal beasts.", "A healthy companion fights longer.", "Pack food for the beast before yourself.", "Good care earns loyalty no command can force.", "Your companion will approve.", "Another handler can use this.", "Fresh care supplies for old field goods.", "Your beast may have stronger opinions later.")
    endfunction

    private function ConfigureZoneVoices takes nothing returns nothing
        // Parent-zone bindings also apply inside configured child zones.
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_WEAPONS], 3, "Fiery Mountain Orc")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_ARMOR], 3, "Fiery Mountain Orc")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_SHIELDS], 3, "Fiery Mountain Orc")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_TRAVELLING], 10, "Riverbane Human")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_TRAVELLING], 13, "Stormhaven Human")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_TRAVELLING], 14, "Sirensong Jungle Orc")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_PROFESSION_SUPPLIES], 2, "Forest Orc")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 10, "Goblin Riverbane")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 13, "Goblin Stormhaven")
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 14, "Goblin Sirensong")
    endfunction

    public function GetVendorId takes integer catalogType returns integer
        if catalogType > 0 and catalogType <= VC_MAX_CATALOGS then
            return VC_VendorId[catalogType]
        endif
        return 0
    endfunction

    public function RegisterUnit takes unit vendor, integer catalogType, string voiceProfile returns boolean
        local integer vendorId = VendorCatalogs_GetVendorId(catalogType)
        local boolean result = Shop_RegisterVendorUnit(vendor, vendorId)

        if result and voiceProfile != null and voiceProfile != "" then
            call VendorLines_BindUnitProfile(vendor, voiceProfile)
        endif
        set vendor = null
        return result
    endfunction

    public function RegisterUnitType takes integer unitTypeId, integer catalogType, string voiceProfile returns boolean
        local integer vendorId = VendorCatalogs_GetVendorId(catalogType)
        local boolean result = Shop_RegisterVendorUnitType(vendorId, unitTypeId)

        if result and voiceProfile != null and voiceProfile != "" then
            call VendorLines_BindUnitTypeProfile(unitTypeId, voiceProfile)
        endif
        return result
    endfunction

    private function Init takes nothing returns nothing
        call ConfigureCatalogs()
        call ConfigureEquipmentStock()
        call ConfigureProfessionStock()
        call ConfigureGeneralStock()
        call ConfigureRoleLines()
        call ConfigureZoneVoices()
    endfunction
endlibrary
