/**
    VendorCatalogs

    Author: Valdemar
    Version: 1.3.1

    Description:
    Ready-to-use PotS vendor definitions for equipment, professions, factions,
    travelling trade, randomized goods, and general adventuring supplies.
    Known vendor unit types are bound automatically; map-specific units can be
    assigned through the public registration API.

    Credits:
    - Warcraft Wiki vendor taxonomy, used as role inspiration

    How to install:
    Import after Shop, VoicelinesVendorLines, and Reputation. Import
    VendorOrcs, VendorSatyrs, VendorHumans, VendorGoblins,
    VendorBonecrusherOgres, VendorElarindor, VendorTauren, VendorDwarves, and
    VendorTrolls afterward when those object families are present.

    API:
    - VendorCatalogs_VENDOR_CATALOG_* constants select one of the 35 catalogs.
    - set vendorId = VendorCatalogs_GetVendorId(catalogType)
    - call VendorCatalogs_RegisterUnit(vendor, catalogType, voiceProfile)
    - call VendorCatalogs_RegisterUnitType(unitTypeId, catalogType, voiceProfile)
    - Canonical vendor names are registered automatically by unit rawcode.

**/
library VendorCatalogs initializer Init requires Shop, VendorLines, VoicelinesVendorLines, Reputation
    globals
        public constant integer VENDOR_CATALOG_WEAPONS = 1
        public constant integer VENDOR_CATALOG_ARMOR = 2
        public constant integer VENDOR_CATALOG_SHIELDS = 3
        public constant integer VENDOR_CATALOG_ARENA = 4
        public constant integer VENDOR_CATALOG_TRAVELLING = 5
        public constant integer VENDOR_CATALOG_FISHER = 6
        public constant integer VENDOR_CATALOG_MINER = 7
        public constant integer VENDOR_CATALOG_COOK = 8
        public constant integer VENDOR_CATALOG_ALCHEMY_SUPPLIES = 9
        public constant integer VENDOR_CATALOG_BLACKSMITHING_SUPPLIES = 10
        public constant integer VENDOR_CATALOG_COOKING_SUPPLIES = 11
        public constant integer VENDOR_CATALOG_ENCHANTING_SUPPLIES = 12
        public constant integer VENDOR_CATALOG_FISHING_SUPPLIES = 13
        public constant integer VENDOR_CATALOG_LEATHERWORKING_SUPPLIES = 14
        public constant integer VENDOR_CATALOG_MINING_SUPPLIES = 15
        public constant integer VENDOR_CATALOG_SKINNING_SUPPLIES = 16
        public constant integer VENDOR_CATALOG_PROFESSION_SUPPLIES = 17
        public constant integer VENDOR_CATALOG_QUARTERMASTER = 18
        public constant integer VENDOR_CATALOG_RANDOMIZED_GOODS = 19
        public constant integer VENDOR_CATALOG_REAGENTS = 20
        public constant integer VENDOR_CATALOG_FOOD_AND_DRINK = 21
        public constant integer VENDOR_CATALOG_POTIONS = 22
        public constant integer VENDOR_CATALOG_RARE_GOODS = 23
        public constant integer VENDOR_CATALOG_ADVENTURING_SUPPLIES = 24
        public constant integer VENDOR_CATALOG_TRADE_GOODS = 25
        public constant integer VENDOR_CATALOG_BEAST_SUPPLIES = 26
        public constant integer VENDOR_CATALOG_BLACKSMITH = 27
        public constant integer VENDOR_CATALOG_BARTENDER = 28
        public constant integer VENDOR_CATALOG_JEWELCRAFTER = 29
        public constant integer VENDOR_CATALOG_SHAMANIC_GOODS = 30
        public constant integer VENDOR_CATALOG_FEL_CURIOS = 31
        public constant integer VENDOR_CATALOG_VOODOO_GOODS = 32
        public constant integer VENDOR_CATALOG_ARCANIST = 33
        public constant integer VENDOR_CATALOG_MAGISTER = 34
        public constant integer VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS = 35

        private constant integer VC_MAX_CATALOGS = 35
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

    private function RegisterVendorName takes integer unitTypeId, string displayName returns nothing
        call Shop_SetVendorUnitTypeName(unitTypeId, displayName)
    endfunction

    private function ConfigureVendorNames takes nothing returns nothing
        // Orc vendors
        call RegisterVendorName('o011', "Kargun Ashblade")
        call RegisterVendorName('o012', "Drokmar Ironhide")
        call RegisterVendorName('o013', "Varok Emberwall")
        call RegisterVendorName('o00A', "Ghorak Bloodmark")
        call RegisterVendorName('o00B', "Rukgar Longroad")
        call RegisterVendorName('o00C', "Nargash Tidehook")
        call RegisterVendorName('o00D', "Kazrum Deepdelver")
        call RegisterVendorName('o00E', "Hurgan Potbelly")
        call RegisterVendorName('o00F', "Zarkul Vialroot")
        call RegisterVendorName('o00G', "Brakkun Coalhand")
        call RegisterVendorName('o00H', "Dagrok Firekeeper")
        call RegisterVendorName('o00I', "Velgor Runeleaf")
        call RegisterVendorName('o00J', "Mokrag Reedline")
        call RegisterVendorName('o00K', "Kragmar Hidebinder")
        call RegisterVendorName('o00L', "Thurgash Ore-Eye")
        call RegisterVendorName('o00M', "Lokruk Skinner")
        call RegisterVendorName('o00N', "Garshan Manytools")
        call RegisterVendorName('o00O', "Korghan Greenbanner")
        call RegisterVendorName('o00P', "Snagrok Oddskeeper")
        call RegisterVendorName('o00Q', "Urgash Saltleaf")
        call RegisterVendorName('o00R', "Grosh Fullbelly")
        call RegisterVendorName('o00S', "Mazgor Bitterbrew")
        call RegisterVendorName('o00T', "Mordrak Cindercoin")
        call RegisterVendorName('o00U', "Dravok Trailwise")
        call RegisterVendorName('o00V', "Korgul Barterhand")
        call RegisterVendorName('o00W', "Brugar Beastfriend")
        call RegisterVendorName('o00X', "Rethgar Reefblade")
        call RegisterVendorName('o00Y', "Vrokan Scalehide")
        call RegisterVendorName('o00Z', "Shargul Tidewall")
        call RegisterVendorName('o010', "Krazhan Far-Sail")
        call RegisterVendorName('o014', "Gorthak Jungle Banner")

        // Satyr vendors
        call RegisterVendorName('n02Y', "Xyros Bloodwager")
        call RegisterVendorName('n02Z', "Velyssra the Covetous")
        call RegisterVendorName('n030', "Malthera Duskmoss")
        call RegisterVendorName('n031', "Ithryssa Runehorn")
        call RegisterVendorName('n032', "Zarethis Oddhoof")
        call RegisterVendorName('n033', "Selyth Venomcup")
        call RegisterVendorName('n034', "Krythos Thornblade")
        call RegisterVendorName('n036', "Velthyr Nighthide")
        call RegisterVendorName('n037', "Ozyr Blackhorn")
        call RegisterVendorName('n038', "Faelrix Wayhoof")

        // Human vendors
        call RegisterVendorName('n035', "Garrick Holt")
        call RegisterVendorName('n039', "Edric Vale")
        call RegisterVendorName('n03A', "Rowan Targe")
        call RegisterVendorName('n03B', "Roderic Kane")
        call RegisterVendorName('n03C', "Merrick Wayland")
        call RegisterVendorName('n03D', "Silas Reed")
        call RegisterVendorName('n03E', "Tobin Slate")
        call RegisterVendorName('n03F', "Owen Marlow")
        call RegisterVendorName('n03G', "Aldren Voss")
        call RegisterVendorName('n03H', "Bram Calder")
        call RegisterVendorName('n03I', "Percy Bell")
        call RegisterVendorName('n03J', "Lucan Wren")
        call RegisterVendorName('n03K', "Hollis Finn")
        call RegisterVendorName('n03L', "Osric Tanner")
        call RegisterVendorName('n03M', "Martin Greaves")
        call RegisterVendorName('n03N', "Corwin Hale")
        call RegisterVendorName('n03O', "Alistair Crane")
        call RegisterVendorName('n03P', "Cedran Pike")
        call RegisterVendorName('n03Q', "Jasper Quill")
        call RegisterVendorName('n03R', "Elias Moor")
        call RegisterVendorName('n03S', "Walter Shore")
        call RegisterVendorName('n03T', "Edwin Harrow")
        call RegisterVendorName('n03U', "Leander Crow")
        call RegisterVendorName('n03V', "Roland Mercer")

        // Goblin vendors
        call RegisterVendorName('n03W', "Nackle Quickdeal")
        call RegisterVendorName('n03X', "Rixit Roadcoin")
        call RegisterVendorName('n03Y', "Giznak Edgeprice")
        call RegisterVendorName('n03Z', "Brizzle Rivetcoat")
        call RegisterVendorName('n040', "Skabbin Bucklesnap")
        call RegisterVendorName('n041', "Fizzik Hookline")
        call RegisterVendorName('n042', "Krikzak Deepcut")
        call RegisterVendorName('n043', "Nibbs Hotpan")
        call RegisterVendorName('n044', "Zabble Mixwell")
        call RegisterVendorName('n045', "Tinksy Multitool")
        call RegisterVendorName('n046', "Grizzik Bloodbet")
        call RegisterVendorName('n047', "Snikka Sparkdust")
        call RegisterVendorName('n048', "Poggle Snackstack")
        call RegisterVendorName('n049', "Vexli Quickdose")
        call RegisterVendorName('n04A', "Razwick Goldglint")
        call RegisterVendorName('n04B', "Bixby Packsmart")
        call RegisterVendorName('n04C', "Mogzik Cratecount")
        call RegisterVendorName('n04D', "Zippi Beastbits")

        // Bonecrusher Ogre vendors
        call RegisterVendorName('n04E', "Mugrok Ironclub")
        call RegisterVendorName('n04F', "Grumbar Thickhide")
        call RegisterVendorName('n04G', "Bolguk Broadwall")
        call RegisterVendorName('n04H', "Kragmog Skullstake")
        call RegisterVendorName('n04I', "Durgan Rockbite")
        call RegisterVendorName('n04J', "Gubmog Stewpot")
        call RegisterVendorName('n04K', "Thrumgar Forgelug")
        call RegisterVendorName('n04L', "Mogrum Manythings")
        call RegisterVendorName('n04M', "Bargul Bonecount")
        call RegisterVendorName('n04N', "Grothak Heavytrade")

        // Elarindor vendors
        call RegisterVendorName('h00L', "Aerendir Sunblade")
        call RegisterVendorName('h00P', "Lyssara Moonweave")
        call RegisterVendorName('n00M', "Thaelion Spellward")
        call RegisterVendorName('h00Q', "Elowen Starweaver")
        call RegisterVendorName('h00N', "Sylvaris Dewleaf")
        call RegisterVendorName('h00R', "Vaeriel Dawnflask")
        call RegisterVendorName('h00O', "Arannis Wayfarer")
        call RegisterVendorName('h00S', "Maerith Silvercrest")

        // Horde Tauren vendors
        call RegisterVendorName('o015', "Korak Ironhorn")
        call RegisterVendorName('o016', "Bovan Earthhide")
        call RegisterVendorName('o017', "Turog Stoneguard")
        call RegisterVendorName('o018', "Marn Thunderkettle")
        call RegisterVendorName('o019', "Doran Plainstrider")
        call RegisterVendorName('o01A', "Kargan Redtotem")
        call RegisterVendorName('o01B', "Boran Flintmane")
        call RegisterVendorName('o01C', "Tawa Deepvein")
        call RegisterVendorName('o01D', "Koro Windpack")
        call RegisterVendorName('o01E', "Nara Stormhoof")

        // Morgrim Clan Dwarf vendors
        call RegisterVendorName('h00T', "Durnik Forgefather")
        call RegisterVendorName('h00U', "Helgar Ironbraid")
        call RegisterVendorName('h00V', "Torren Deepsteel")
        call RegisterVendorName('h00W', "Bruni Axeledger")
        call RegisterVendorName('h00X', "Hildrek Stoneplate")
        call RegisterVendorName('h00Y', "Keld Coalvein")
        call RegisterVendorName('h00Z', "Orin Deepdelver")
        call RegisterVendorName('h010', "Magdor Caskcoin")

        // Female Human vendors
        call RegisterVendorName('n04O', "Mara Vane")
        call RegisterVendorName('n04P', "Elayne Ward")
        call RegisterVendorName('n04Q', "Catrin Targe")
        call RegisterVendorName('n04R', "Nora Flint")
        call RegisterVendorName('n04S', "Elira Moss")
        call RegisterVendorName('n04T', "Hester Bellows")
        call RegisterVendorName('n04U', "Talia Tanner")
        call RegisterVendorName('n04V', "Greta Stone")
        call RegisterVendorName('n04W', "Willa Hart")
        call RegisterVendorName('n04X', "Sabine Pike")
        call RegisterVendorName('n04Y', "Maren Tidewell")
        call RegisterVendorName('n04Z', "Odette Hearth")
        call RegisterVendorName('n050', "Clara Bell")
        call RegisterVendorName('n051', "Isolde Wren")
        call RegisterVendorName('n052', "Fenna Reed")
        call RegisterVendorName('n053', "Mira Salt")
        call RegisterVendorName('n054', "Adele Shore")
        call RegisterVendorName('n055', "Kessa Kane")
        call RegisterVendorName('n056', "Elara Wayland")
        call RegisterVendorName('n057', "Petra Crane")
        call RegisterVendorName('n058', "Vianne Quill")
        call RegisterVendorName('n059', "Celia Harrow")
        call RegisterVendorName('n05A', "Lenora Crow")
        call RegisterVendorName('n05B', "Roslyn Mercer")

        // Bartenders
        call RegisterVendorName('o01F', "Harn Earthbrew")
        call RegisterVendorName('o01G', "Tobar Keghoof")
        call RegisterVendorName('o01H', "Borug Foamaxe")
        call RegisterVendorName('o01I', "Krogar Caskfire")
        call RegisterVendorName('h013', "Bromli Alethane")
        call RegisterVendorName('n05C', "Duncan Cask")
        call RegisterVendorName('n05D', "Marta Vale")
        call RegisterVendorName('n05E', "Ilyse Faircup")
        call RegisterVendorName('n05F', "Kizzi Kegcoin")
        call RegisterVendorName('n05G', "Brugrum Manymugs")

        // Jewelcrafters
        call RegisterVendorName('n05H', "Zanjin Gemeye")
        call RegisterVendorName('h011', "Saelira Gemwhisper")
        call RegisterVendorName('o01J', "Zugrak Gemfang")
        call RegisterVendorName('n05I', "Jexxi Gemcut")

        // Mystical goods vendors
        call RegisterVendorName('o01K', "Drekhan Spiritbead")
        call RegisterVendorName('o01L', "Vorgra Totemveil")
        call RegisterVendorName('o01M', "Gulvar Ashsigil")
        call RegisterVendorName('o01N', "Morzun Felwhisper")
        call RegisterVendorName('n05J', "Rokjin Hexsmoke")
        call RegisterVendorName('n05K', "Arlen Wyrd")
        call RegisterVendorName('h012', "Caladren Starvault")
    endfunction

    private function ConfigureCatalogs takes nothing returns nothing
        // Explicit merchant unit types and selected generic vendor placeholders
        // are bound here. Change these rawcodes when map placement roles settle.
        set VC_VendorId[VENDOR_CATALOG_WEAPONS] = 0
        call CreateCatalog(VENDOR_CATALOG_WEAPONS, "Weapons Merchant", VendorLines_TYPE_WEAPONS, 0)
        call CreateCatalog(VENDOR_CATALOG_ARMOR, "Armor Merchant", VendorLines_TYPE_ARMOR, 0)
        call CreateCatalog(VENDOR_CATALOG_SHIELDS, "Shield Merchant", VendorLines_TYPE_SHIELDS, 'o62H')
        call VendorLines_BindUnitTypeProfile('o62H', VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE)
        call VendorLines_BindUnitTypeVoiceType('o62H', VL_GENERIC_ORC_MALE_3_TYPE)
        call CreateCatalog(VENDOR_CATALOG_ARENA, "Arena Quartermaster", VendorLines_TYPE_ARENA, 'N60L')
        call CreateCatalog(VENDOR_CATALOG_TRAVELLING, "Travelling Merchant", VendorLines_TYPE_TRAVELLING, 'h00H')
        call CreateCatalog(VENDOR_CATALOG_FISHER, "Fisher", VendorLines_TYPE_FISHER, 'o62I')
        call CreateCatalog(VENDOR_CATALOG_MINER, "Miner", VendorLines_TYPE_MINER, 0)
        call CreateCatalog(VENDOR_CATALOG_COOK, "Cook", VendorLines_TYPE_COOK, 'o60I')
        call CreateCatalog(VENDOR_CATALOG_ALCHEMY_SUPPLIES, "Alchemy Supplier", VendorLines_TYPE_ALCHEMY_SUPPLIES, 'o62F')
        call CreateCatalog(VENDOR_CATALOG_BLACKSMITHING_SUPPLIES, "Blacksmithing Supplier", VendorLines_TYPE_BLACKSMITHING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_COOKING_SUPPLIES, "Cooking Supplier", VendorLines_TYPE_COOKING_SUPPLIES, 0)
        call CreateCatalog(VENDOR_CATALOG_ENCHANTING_SUPPLIES, "Enchanting Supplier", VendorLines_TYPE_ENCHANTING_SUPPLIES, 0)
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
        call CreateCatalog(VENDOR_CATALOG_BLACKSMITH, "Blacksmith", VendorLines_TYPE_BLACKSMITH, 0)
        call CreateCatalog(VENDOR_CATALOG_BARTENDER, "Bartender", VendorLines_TYPE_BARTENDER, 0)
        call CreateCatalog(VENDOR_CATALOG_JEWELCRAFTER, "Jewelcrafter", VendorLines_TYPE_JEWELCRAFTER, 0)
        call CreateCatalog(VENDOR_CATALOG_SHAMANIC_GOODS, "Spirit Speaker", VendorLines_TYPE_SHAMANIC_GOODS, 0)
        call CreateCatalog(VENDOR_CATALOG_FEL_CURIOS, "Fel Curio Dealer", VendorLines_TYPE_FEL_CURIOS, 0)
        call CreateCatalog(VENDOR_CATALOG_VOODOO_GOODS, "Voodoo Merchant", VendorLines_TYPE_VOODOO_GOODS, 0)
        call CreateCatalog(VENDOR_CATALOG_ARCANIST, "Arcanist", VendorLines_TYPE_ARCANIST, 0)
        call CreateCatalog(VENDOR_CATALOG_MAGISTER, "Magister", VendorLines_TYPE_MAGISTER, 0)
        call CreateCatalog(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, "Explosives and Reagent Merchant", VendorLines_TYPE_REAGENTS, 0)
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

        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I6B1', 60, "Weapons")
        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I6B2', 65, "Weapons")
        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I68F', 140, "Armor")
        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I68M', 120, "Armor")
        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I66E', 55, "Shields")
        call AddStock(VENDOR_CATALOG_BLACKSMITH, 'I6B6', 90, "Shields")

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
        call Shop_RerollVendorStock(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS])
        call Shop_SetVendorRandomStockInterval(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 900.00)

        call AddStock(VENDOR_CATALOG_REAGENTS, 'I60Y', 20, "Herbs")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_REAGENTS, 'I6BB', 35, "Water")

        call AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'I60Y', 20, "Herbs")
        call AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'I6BB', 35, "Water")
        set stockId = AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'j4c2', 150, "Fuel")
        call Shop_SetStockCharges(stockId, 1)
        call Shop_SetStockSupply(stockId, 4, 300.00)
        set stockId = AddStock(VENDOR_CATALOG_EXPLOSIVES_AND_REAGENTS, 'I00F', 500, "Explosives")
        call Shop_SetStockCharges(stockId, 1)
        call Shop_SetStockSupply(stockId, 2, 600.00)

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

        call AddStock(VENDOR_CATALOG_BARTENDER, 'I60Z', 20, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'j3a0', 30, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'I60E', 5, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'I60F', 50, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'i1g2', 55, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'i1g3', 55, "Drinks")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'j2b0', 20, "Food")
        call AddStock(VENDOR_CATALOG_BARTENDER, 'j2b1', 25, "Food")

        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'I60N', 45, "Rings")
        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'I62C', 90, "Rings")
        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'I62N', 90, "Rings")
        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'I62B', 90, "Necklaces")
        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'I62M', 90, "Necklaces")
        call AddStock(VENDOR_CATALOG_JEWELCRAFTER, 'j4c1', 650, "Trinkets")

        call AddStock(VENDOR_CATALOG_SHAMANIC_GOODS, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_SHAMANIC_GOODS, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_SHAMANIC_GOODS, 'I6E0', 110, "Essences")
        call AddStock(VENDOR_CATALOG_SHAMANIC_GOODS, 'j4b7', 180, "Totems and Charms")

        call AddStock(VENDOR_CATALOG_FEL_CURIOS, 'I6C6', 90, "Essences")
        call AddStock(VENDOR_CATALOG_FEL_CURIOS, 'I6E0', 125, "Essences")
        call AddStock(VENDOR_CATALOG_FEL_CURIOS, 'I003', 65, "Crystals")
        call AddStock(VENDOR_CATALOG_FEL_CURIOS, 'I60N', 375, "Fel Curios")

        call AddStock(VENDOR_CATALOG_VOODOO_GOODS, 'I60Y', 25, "Herbs")
        call AddStock(VENDOR_CATALOG_VOODOO_GOODS, 'I6BB', 40, "Ritual Water")
        call AddStock(VENDOR_CATALOG_VOODOO_GOODS, 'I6C6', 90, "Essences")
        call AddStock(VENDOR_CATALOG_VOODOO_GOODS, 'j4c1', 200, "Charms")

        call AddStock(VENDOR_CATALOG_ARCANIST, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_ARCANIST, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_ARCANIST, 'I6E0', 110, "Essences")
        call AddStock(VENDOR_CATALOG_ARCANIST, 'j4c1', 650, "Arcane Items")

        call AddStock(VENDOR_CATALOG_MAGISTER, 'I003', 55, "Crystals")
        call AddStock(VENDOR_CATALOG_MAGISTER, 'I6C6', 80, "Essences")
        call AddStock(VENDOR_CATALOG_MAGISTER, 'I6E0', 110, "Essences")
        call AddStock(VENDOR_CATALOG_MAGISTER, 'j4b7', 450, "Arcane Relics")
    endfunction

    private function ConfigureZoneVoices takes nothing returns nothing
        // Parent-zone bindings also apply inside configured child zones.
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_WEAPONS], 3, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_ARMOR], 3, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_SHIELDS], 3, VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE)
        // Human vendors retain their unit-type profile here so male and female voices stay distinct.
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_TRAVELLING], 14, VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_PROFESSION_SUPPLIES], 2, VL_VENDOR_PROFILE_ORC_FOREST_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 10, VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 13, VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE)
        call VendorLines_BindVendorZoneProfile(VC_VendorId[VENDOR_CATALOG_RANDOMIZED_GOODS], 14, VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE)
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
        call ConfigureVendorNames()
        call ConfigureEquipmentStock()
        call ConfigureProfessionStock()
        call ConfigureGeneralStock()
        call ConfigureZoneVoices()
    endfunction
endlibrary
