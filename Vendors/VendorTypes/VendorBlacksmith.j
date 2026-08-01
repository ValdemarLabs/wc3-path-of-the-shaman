/**
    BlacksmithVendor

    Author: Valdemar
    Version: 1.1.0

    Description:
    Template blacksmith merchant for the PotS shop system. This vendor sells
    starter weapons, shields, armor pieces, and basic profession tools.

    Credits:

    How to install:
    Import after Shop and VoicelinesVendorLines. Replace or extend the unit-type
    constants below for map-specific blacksmiths, then call
    BlacksmithVendor_RegisterUnit for hand-picked vendor units if needed.

    API:
    - set vendorId = BlacksmithVendor_GetVendorId()
    - call BlacksmithVendor_RegisterUnit(vendor)
    - call BlacksmithVendor_RegisterUnitType(unitTypeId)
    - call BlacksmithVendor_BindAIProfile(profileId)

**/
library BlacksmithVendor initializer Init requires Shop, VoicelinesVendorLines, Reputation, optional AI
    globals
        private constant integer VB_UNIT_TYPE_HUMAN_BLACKSMITH = 'h00I'
        private constant integer VB_UNIT_TYPE_ORC_BLACKSMITH = 'o60H'
        private constant integer VB_UNIT_TYPE_BROKKAR = 'o62K'
        private constant integer VB_UNIT_TYPE_THROGAR = 'o62J'

        private constant integer VB_ITEM_BLUNT_SWORD = 'I6B1'
        private constant integer VB_ITEM_CHIPPED_AXE = 'I6B2'
        private constant integer VB_ITEM_DENTED_SHIELD = 'I6B6'
        private constant integer VB_ITEM_WOODEN_SHIELD = 'I66E'
        private constant integer VB_ITEM_COPPER_CHAIN_HELMET = 'I68F'
        private constant integer VB_ITEM_COPPER_CHAIN_BOOTS = 'I68M'
        private constant integer VB_ITEM_STURDY_WAR_AXE = 'stwa'
        private constant integer VB_ITEM_CLAWS_ATTACK = 'rat6'
        private constant integer VB_ITEM_MINING_PICK = 'I672'
        private constant integer VB_ITEM_BLACKSMITH_HAMMER = 'j1d2'
        private constant integer VB_ITEM_COAL = 'I689'

        private integer VB_VendorId = 0
    endglobals

    public function GetVendorId takes nothing returns integer
        return VB_VendorId
    endfunction

    public function RegisterUnit takes unit vendor returns boolean
        local boolean result = Shop_RegisterVendorUnit(vendor, VB_VendorId)

        set vendor = null
        return result
    endfunction

    public function RegisterUnitType takes integer unitTypeId returns boolean
        return Shop_RegisterVendorUnitType(VB_VendorId, unitTypeId)
    endfunction

    public function BindAIProfile takes integer profileId returns nothing
        static if LIBRARY_AI then
            call AI_AddProfileShopUnitType(profileId, VB_UNIT_TYPE_HUMAN_BLACKSMITH)
            call AI_AddProfileShopUnitType(profileId, VB_UNIT_TYPE_ORC_BLACKSMITH)
            call AI_AddProfileShopUnitType(profileId, VB_UNIT_TYPE_BROKKAR)
            call AI_AddProfileShopUnitType(profileId, VB_UNIT_TYPE_THROGAR)
        endif
    endfunction

    private function RegisterStock takes nothing returns nothing
        local integer stockId

        call Shop_AddStockEx(VB_VendorId, VB_ITEM_BLUNT_SWORD, 60, "Weapons", 220, 4)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_CHIPPED_AXE, 65, "Weapons", 240, 4)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_WOODEN_SHIELD, 55, "Shields", 220, 3)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_DENTED_SHIELD, 90, "Shields", 320, 3)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_COPPER_CHAIN_HELMET, 140, "Armor", 450, 2)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_COPPER_CHAIN_BOOTS, 120, "Armor", 420, 2)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_MINING_PICK, 75, "Tools", 300, 2)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_BLACKSMITH_HAMMER, 75, "Tools", 300, 2)
        call Shop_AddStockEx(VB_VendorId, VB_ITEM_COAL, 75, "Tools", 300, 2)
        set stockId = Shop_AddStockEx(VB_VendorId, VB_ITEM_STURDY_WAR_AXE, 260, "Weapons", 700, 1)
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_FRIENDLY)
        call Shop_SetStockSupply(stockId, 2, 300.00)

        set stockId = Shop_AddStockEx(VB_VendorId, VB_ITEM_CLAWS_ATTACK, 500, "Weapons", 900, 1)
        call Shop_SetStockMinimumReputation(stockId, Reputation_REP_COVENANT)
        call Shop_SetStockSupply(stockId, 1, 600.00)
    endfunction

    private function BindVoiceProfiles takes nothing returns nothing
        call VendorLines_BindUnitTypeProfile(VB_UNIT_TYPE_HUMAN_BLACKSMITH, "Riverbane Human Blacksmith")
        call VendorLines_BindUnitTypeProfile(VB_UNIT_TYPE_ORC_BLACKSMITH, "Fiery Mountain Orc Blacksmith")
        call VendorLines_BindUnitTypeProfile(VB_UNIT_TYPE_BROKKAR, "Fiery Mountain Orc Blacksmith")
        call VendorLines_BindUnitTypeProfile(VB_UNIT_TYPE_THROGAR, "Fiery Mountain Orc Blacksmith")
    endfunction

    private function Init takes nothing returns nothing
        set VB_VendorId = Shop_CreateVendor("Blacksmith", VB_UNIT_TYPE_HUMAN_BLACKSMITH)
        call Shop_SetVendorTypeLabel(VB_VendorId, "Blacksmith")
        call BlacksmithVendor_RegisterUnitType(VB_UNIT_TYPE_ORC_BLACKSMITH)
        call BlacksmithVendor_RegisterUnitType(VB_UNIT_TYPE_BROKKAR)
        call BlacksmithVendor_RegisterUnitType(VB_UNIT_TYPE_THROGAR)
        call RegisterStock()
        call BindVoiceProfiles()
    endfunction
endlibrary
