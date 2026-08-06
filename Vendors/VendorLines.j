/**
    VendorLines

    Author: Valdemar
    Version: 1.1.0

    Description:
    Vendor dialogue profiles and trade-session voice configuration for PotS
    merchants. Profiles can be bound to individual units or unit types, while
    vendor names and type labels remain automatic fallbacks.

    Credits:

    How to install:
    Import after Shop, ZonesCore, DialogSystem, DialogInteraction, and Table.
    Import VoicelinesVendorLines afterward to register all merchant content,
    then import ShopUI, VendorDialogs, catalogs, and vendor templates.

    API:
    - call VendorLines_RegisterBasicLines(name, greet1, greet2, trade, farewell)
    - call VendorLines_RegisterLine(profile, category, text, soundKey)
    - call VendorLines_BindUnitTypeProfile(unitTypeId, profile)
    - call VendorLines_BindUnitProfile(vendor, profile)
    - call VendorLines_BindVendorZoneProfile(vendorId, zoneId, profile)
    - call VendorLines_SetVendorRandomLinesEnabled(vendorId, enabled)
    - call VendorLines_SetDefaultRandomLineInterval(minimum, maximum)
    - call VendorLines_SetVendorRandomLineInterval(vendorId, minimum, maximum)
    - call VendorLines_PlayRandomTradeLine(vendor)
    - call VendorLines_PlayTradeOutcome(vendor, boughtCount, soldCount)
    - Content libraries should register text only from VoicelinesVendorLines.

**/
library VendorLines initializer Init requires Table, DialogSystem, DialogInteraction, Shop, ZonesCore
    globals
        public constant integer LINE_CHATTER = 1
        public constant integer LINE_BOUGHT = 2
        public constant integer LINE_SOLD = 3
        public constant integer LINE_BOUGHT_AND_SOLD = 4
        public constant integer LINE_NO_TRANSACTION = 5

        // Standardized commerce labels. Stock libraries may use narrower labels.
        public constant string TYPE_GENERAL_GOODS = "General Goods"
        public constant string TYPE_BAGS = "Bags"
        public constant string TYPE_WEAPONS = "Weapons"
        public constant string TYPE_ARMOR = "Armor"
        public constant string TYPE_SHIELDS = "Shields"
        public constant string TYPE_BLACKSMITH = "Blacksmith"
        public constant string TYPE_ARENA = "Arena Vendor"
        public constant string TYPE_TRAVELLING = "Travelling Merchant"
        public constant string TYPE_FISHER = "Fisher"
        public constant string TYPE_MINER = "Miner"
        public constant string TYPE_COOK = "Cook/Chef"
        public constant string TYPE_ALCHEMY_SUPPLIES = "Alchemy Supplies"
        public constant string TYPE_BLACKSMITHING_SUPPLIES = "Blacksmithing Supplies"
        public constant string TYPE_COOKING_SUPPLIES = "Cooking Supplies"
        public constant string TYPE_ENCHANTING_SUPPLIES = "Enchanting Supplies"
        public constant string TYPE_FISHING_SUPPLIES = "Fishing Supplies"
        public constant string TYPE_LEATHERWORKING_SUPPLIES = "Leatherworking Supplies"
        public constant string TYPE_MINING_SUPPLIES = "Mining Supplies"
        public constant string TYPE_SKINNING_SUPPLIES = "Skinning Supplies"
        public constant string TYPE_PROFESSION_SUPPLIES = "Profession Supplies"
        public constant string TYPE_FACTION_QUARTERMASTER = "Faction Quartermaster"
        public constant string TYPE_RANDOMIZED_GOODS = "Randomized Goods"
        public constant string TYPE_REAGENTS = "Reagents"
        public constant string TYPE_FOOD_AND_DRINK = "Food and Drink"
        public constant string TYPE_POTIONS = "Potion Seller"
        public constant string TYPE_RARE_GOODS = "Rare Goods"
        public constant string TYPE_ADVENTURING_SUPPLIES = "Adventuring Supplies"
        public constant string TYPE_TRADE_GOODS = "Trade Goods"
        public constant string TYPE_BEAST_SUPPLIES = "Beast Supplies"
        public constant string TYPE_ARCANE_GOODS = "Arcane Goods"

        private constant integer VL_MAX_PROFILES = 80
        private constant integer VL_MAX_LINES_PER_CATEGORY = 8
        private constant integer VL_LINE_STRIDE = 10
        private constant integer VL_CATEGORY_STRIDE = 10
        private constant integer VL_PROFILE_STRIDE = 80

        private Table VL_ProfileByName = 0
        private Table VL_ProfileByUnitType = 0
        private Table VL_ProfileByUnit = 0
        private hashtable VL_ProfileByVendorZone = InitHashtable()
        private Table VL_LineCount = 0
        private Table VL_LastLine = 0
        private integer VL_ProfileCount = 0
        private string array VL_ProfileName
        private string array VL_LineText
        private string array VL_LineSound

        private boolean VL_DefaultRandomLinesEnabled = true
        private real VL_DefaultMinimumInterval = 60.00
        private real VL_DefaultMaximumInterval = 120.00
        private boolean array VL_VendorRandomLinesOverride
        private boolean array VL_VendorRandomLinesEnabled
        private real array VL_VendorMinimumInterval
        private real array VL_VendorMaximumInterval

        private string VL_PickedText = ""
        private string VL_PickedSound = ""
    endglobals

    private function VL_GetCountKey takes integer profileId, integer category returns integer
        return profileId * VL_CATEGORY_STRIDE + category
    endfunction

    private function VL_GetLineKey takes integer profileId, integer category, integer lineIndex returns integer
        return profileId * VL_PROFILE_STRIDE + category * VL_LINE_STRIDE + lineIndex
    endfunction

    private function VL_GetOrCreateProfile takes string profileName returns integer
        local integer key
        local integer profileId

        if profileName == null or profileName == "" then
            set profileName = "Merchant"
        endif
        set key = StringHash(profileName)
        set profileId = VL_ProfileByName.integer[key]
        if profileId <= 0 and VL_ProfileCount < VL_MAX_PROFILES then
            set VL_ProfileCount = VL_ProfileCount + 1
            set profileId = VL_ProfileCount
            set VL_ProfileName[profileId] = profileName
            set VL_ProfileByName.integer[key] = profileId
        endif
        return profileId
    endfunction

    private function VL_GetProfileByName takes string profileName returns integer
        if profileName == null or profileName == "" then
            return 0
        endif
        return VL_ProfileByName.integer[StringHash(profileName)]
    endfunction

    private function VL_GetBoundProfile takes unit vendor returns integer
        local integer profileId = 0
        local integer vendorId
        local integer zoneId

        if vendor != null then
            set profileId = VL_ProfileByUnit.integer[GetHandleId(vendor)]
            if profileId <= 0 then
                set vendorId = Shop_GetVendorIdForUnit(vendor)
                set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(vendor), GetUnitY(vendor))
                set profileId = LoadInteger(VL_ProfileByVendorZone, vendorId, zoneId)
                if profileId <= 0 then
                    set profileId = LoadInteger(VL_ProfileByVendorZone, vendorId, ZonesCore_GetParentZoneId(zoneId))
                endif
            endif
            if profileId <= 0 then
                set profileId = VL_ProfileByUnitType.integer[GetUnitTypeId(vendor)]
            endif
        endif
        set vendor = null
        return profileId
    endfunction

    private function VL_GetVendorName takes unit vendor returns string
        local integer vendorId

        if vendor == null then
            set vendor = null
            return "Merchant"
        endif
        set vendorId = Shop_GetVendorIdForUnit(vendor)
        if vendorId > 0 then
            set vendor = null
            return Shop_GetVendorName(vendorId)
        endif
        set vendor = null
        return "Merchant"
    endfunction

    private function VL_GetVendorSpeakerName takes unit vendor returns string
        local integer vendorId
        local string unitName
        local string vendorType

        if vendor == null then
            set vendor = null
            return "Merchant"
        endif
        set vendorId = Shop_GetVendorIdForUnit(vendor)
        set unitName = Shop_GetVendorUnitDisplayName(vendor)
        set vendorType = Shop_GetVendorTypeLabel(vendorId)
        if unitName == null or unitName == "" then
            set unitName = VL_GetVendorName(vendor)
        endif
        if vendorType == null or vendorType == "" or vendorType == unitName then
            set vendor = null
            return unitName
        endif
        set vendor = null
        return unitName + " (" + vendorType + ")"
    endfunction

    private function VL_PickFromProfile takes integer profileId, integer category returns boolean
        local integer count
        local integer countKey
        local integer lineIndex
        local integer lastIndex
        local integer lineKey

        if profileId <= 0 then
            return false
        endif
        set countKey = VL_GetCountKey(profileId, category)
        set count = VL_LineCount.integer[countKey]
        if count <= 0 then
            return false
        endif
        set lineIndex = GetRandomInt(1, count)
        set lastIndex = VL_LastLine.integer[countKey]
        if count > 1 and lineIndex == lastIndex then
            set lineIndex = lineIndex + 1
            if lineIndex > count then
                set lineIndex = 1
            endif
        endif
        set VL_LastLine.integer[countKey] = lineIndex
        set lineKey = VL_GetLineKey(profileId, category, lineIndex)
        set VL_PickedText = VL_LineText[lineKey]
        set VL_PickedSound = VL_LineSound[lineKey]
        return VL_PickedText != ""
    endfunction

    private function VL_PickForVendor takes unit vendor, integer category returns boolean
        local integer vendorId = Shop_GetVendorIdForUnit(vendor)
        local integer profileId = VL_GetBoundProfile(vendor)
        local integer fallbackProfile
        local integer roleProfile
        local string vendorName = VL_GetVendorName(vendor)
        local string vendorType = Shop_GetVendorTypeLabel(vendorId)

        set VL_PickedText = ""
        set VL_PickedSound = ""
        set roleProfile = VL_GetProfileByName(vendorName)
        if profileId > 0 and roleProfile > 0 and profileId != roleProfile then
            if GetRandomInt(0, 1) == 0 then
                if VL_PickFromProfile(profileId, category) then
                    set vendor = null
                    return true
                endif
                if VL_PickFromProfile(roleProfile, category) then
                    set vendor = null
                    return true
                endif
            else
                if VL_PickFromProfile(roleProfile, category) then
                    set vendor = null
                    return true
                endif
                if VL_PickFromProfile(profileId, category) then
                    set vendor = null
                    return true
                endif
            endif
        else
            if VL_PickFromProfile(profileId, category) then
                set vendor = null
                return true
            endif
            if roleProfile != profileId and VL_PickFromProfile(roleProfile, category) then
                set vendor = null
                return true
            endif
        endif
        set fallbackProfile = VL_GetProfileByName(vendorType)
        if fallbackProfile != profileId and fallbackProfile != roleProfile and VL_PickFromProfile(fallbackProfile, category) then
            set vendor = null
            return true
        endif
        set fallbackProfile = VL_GetProfileByName("Merchant")
        set vendor = null
        return VL_PickFromProfile(fallbackProfile, category)
    endfunction

    private function VL_QueuePickedLine takes unit vendor returns nothing
        if vendor != null and VL_PickedText != "" then
            call DialogSystem_QueueFieldLine(vendor, VL_GetVendorSpeakerName(vendor), VL_PickedSound, VL_PickedText)
        endif
        set vendor = null
    endfunction

    public function GetVendorNameByType takes integer unitTypeId returns string
        local integer vendorId = Shop_GetVendorIdForUnitType(unitTypeId)

        if vendorId > 0 then
            return Shop_GetVendorName(vendorId)
        endif
        return "Merchant"
    endfunction

    public function GetVendorName takes unit vendor returns string
        return VL_GetVendorName(vendor)
    endfunction

    public function GetVendorSpeakerName takes unit vendor returns string
        return VL_GetVendorSpeakerName(vendor)
    endfunction

    public function RegisterLine takes string profileName, integer category, string text, string soundKey returns nothing
        local integer profileId
        local integer countKey
        local integer count
        local integer lineKey

        if text == null or text == "" or category < LINE_CHATTER or category > LINE_NO_TRANSACTION then
            return
        endif
        set profileId = VL_GetOrCreateProfile(profileName)
        set countKey = VL_GetCountKey(profileId, category)
        set count = VL_LineCount.integer[countKey]
        if profileId <= 0 or count >= VL_MAX_LINES_PER_CATEGORY then
            return
        endif
        set count = count + 1
        set VL_LineCount.integer[countKey] = count
        set lineKey = VL_GetLineKey(profileId, category, count)
        set VL_LineText[lineKey] = text
        if soundKey == null then
            set soundKey = ""
        endif
        set VL_LineSound[lineKey] = soundKey
    endfunction

    public function BindUnitTypeProfile takes integer unitTypeId, string profileName returns nothing
        local integer profileId = VL_GetOrCreateProfile(profileName)

        if unitTypeId != 0 and profileId > 0 then
            set VL_ProfileByUnitType.integer[unitTypeId] = profileId
        endif
    endfunction

    public function BindUnitProfile takes unit vendor, string profileName returns nothing
        local integer profileId = VL_GetOrCreateProfile(profileName)

        if vendor != null and profileId > 0 then
            set VL_ProfileByUnit.integer[GetHandleId(vendor)] = profileId
        endif
        set vendor = null
    endfunction

    public function BindVendorZoneProfile takes integer vendorId, integer zoneId, string profileName returns nothing
        local integer profileId = VL_GetOrCreateProfile(profileName)

        if vendorId > 0 and zoneId > 0 and profileId > 0 then
            call SaveInteger(VL_ProfileByVendorZone, vendorId, zoneId, profileId)
        endif
    endfunction

    public function RegisterBasicLines takes string vendorName, string greetA, string greetB, string tradeLine, string farewellLine returns nothing
        local integer profileId = VL_GetOrCreateProfile(vendorName)

        if vendorName == "" then
            set vendorName = "Merchant"
        endif
        if greetA != "" then
            call DialogSystem_RegisterGreetLine(vendorName, greetA, "", true)
        endif
        if greetB != "" then
            call DialogSystem_RegisterGreetLine(vendorName, greetB, "", true)
        endif
        if tradeLine != "" then
            call DialogSystem_RegisterTradeLine(vendorName, tradeLine, "", true)
        endif
        if farewellLine != "" then
            call DialogSystem_RegisterExitLine(vendorName, farewellLine, "", true)
            call DialogSystem_RegisterFarewellLine(vendorName, farewellLine, "", true)
        endif
    endfunction

    public function SetDefaultRandomLinesEnabled takes boolean enabled returns nothing
        set VL_DefaultRandomLinesEnabled = enabled
    endfunction

    public function SetVendorRandomLinesEnabled takes integer vendorId, boolean enabled returns nothing
        if vendorId > 0 then
            set VL_VendorRandomLinesOverride[vendorId] = true
            set VL_VendorRandomLinesEnabled[vendorId] = enabled
        endif
    endfunction

    public function SetDefaultRandomLineInterval takes real minimum, real maximum returns nothing
        local real swap

        if minimum < 1.00 then
            set minimum = 1.00
        endif
        if maximum < minimum then
            set swap = minimum
            set minimum = maximum
            set maximum = swap
            if minimum < 1.00 then
                set minimum = 1.00
            endif
        endif
        set VL_DefaultMinimumInterval = minimum
        set VL_DefaultMaximumInterval = maximum
    endfunction

    public function SetVendorRandomLineInterval takes integer vendorId, real minimum, real maximum returns nothing
        local real swap

        if vendorId <= 0 then
            return
        endif
        if minimum < 1.00 then
            set minimum = 1.00
        endif
        if maximum < minimum then
            set swap = minimum
            set minimum = maximum
            set maximum = swap
            if minimum < 1.00 then
                set minimum = 1.00
            endif
        endif
        set VL_VendorMinimumInterval[vendorId] = minimum
        set VL_VendorMaximumInterval[vendorId] = maximum
    endfunction

    public function AreRandomLinesEnabled takes integer vendorId returns boolean
        if vendorId > 0 and VL_VendorRandomLinesOverride[vendorId] then
            return VL_VendorRandomLinesEnabled[vendorId]
        endif
        return VL_DefaultRandomLinesEnabled
    endfunction

    public function GetRandomLineInterval takes integer vendorId returns real
        local real minimum = VL_VendorMinimumInterval[vendorId]
        local real maximum = VL_VendorMaximumInterval[vendorId]

        if minimum <= 0.00 then
            set minimum = VL_DefaultMinimumInterval
        endif
        if maximum < minimum then
            set maximum = VL_DefaultMaximumInterval
        endif
        return GetRandomReal(minimum, maximum)
    endfunction

    public function PlayRandomTradeLine takes unit vendor returns nothing
        if VL_PickForVendor(vendor, LINE_CHATTER) then
            call VL_QueuePickedLine(vendor)
        endif
        set vendor = null
    endfunction

    public function PlayTradeOutcome takes unit vendor, integer boughtCount, integer soldCount returns nothing
        local integer category = LINE_NO_TRANSACTION

        if boughtCount > 0 and soldCount > 0 then
            set category = LINE_BOUGHT_AND_SOLD
        elseif boughtCount > 0 then
            set category = LINE_BOUGHT
        elseif soldCount > 0 then
            set category = LINE_SOLD
        endif
        if VL_PickForVendor(vendor, category) then
            call VL_QueuePickedLine(vendor)
        endif
        set vendor = null
    endfunction

    public function PlayTradeLine takes unit vendor returns nothing
        call DialogSystem_PickTradeLine(vendor, VL_GetVendorName(vendor))
        call DialogSystem_PlayLine(vendor, VL_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    public function PlayFarewellLine takes unit vendor returns nothing
        call DialogSystem_PickFarewellLine(vendor, VL_GetVendorName(vendor))
        call DialogSystem_PlayLine(vendor, VL_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    private function Init takes nothing returns nothing
        set VL_ProfileByName = Table.create()
        set VL_ProfileByUnitType = Table.create()
        set VL_ProfileByUnit = Table.create()
        set VL_LineCount = Table.create()
        set VL_LastLine = Table.create()

    endfunction
endlibrary
