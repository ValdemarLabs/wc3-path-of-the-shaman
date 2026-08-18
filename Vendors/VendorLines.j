/**
    VendorLines

    Author: Valdemar
    Version: 1.4.0

    Description:
    Vendor dialogue profiles and trade-session voice configuration for PotS
    merchants. Dialogue profiles and reusable voice types can be bound
    independently to individual units or unit types, while vendor names and
    type labels remain automatic fallbacks.

    Credits:

    How to install:
    Import after Shop, ZonesCore, DialogSystem, DialogInteraction, and Table.
    Import VoicelinesVendorLines afterward to register all merchant content,
    then import ShopUI, VendorDialogs, catalogs, and vendor templates.

    API:
    - call VendorLines_RegisterBasicLines(name, greet1, greet2, trade, farewell)
    - call VendorLines_RegisterCatalogBasicLines(name, offset, greet1, greet2, trade, farewell)
    - call VendorLines_RegisterLine(profile, category, text, soundKey)
    - call VendorLines_RegisterCatalogLine(profile, category, offset, text)
    - call VendorLines_RegisterProfileSoundType(profile, soundType)
    - call VendorLines_RegisterProfileVoiceLine(profile, category, text, lineIndex)
    - call VendorLines_RegisterSoundTypeCatalogStart(soundType, firstLine)
    - call VendorLines_RegisterSpeakerLine(profile, category, speakerName, text, soundKey)
    - call VendorLines_BindUnitTypeProfile(unitTypeId, profile)
    - call VendorLines_BindUnitProfile(vendor, profile)
    - call VendorLines_BindUnitTypeVoiceType(unitTypeId, soundType)
    - call VendorLines_BindUnitVoiceType(vendor, soundType)
    - call VendorLines_BindVendorZoneProfile(vendorId, zoneId, profile)
    - call VendorLines_SetVendorRandomLinesEnabled(vendorId, enabled)
    - call VendorLines_SetDefaultRandomLineInterval(minimum, maximum)
    - call VendorLines_SetVendorRandomLineInterval(vendorId, minimum, maximum)
    - call VendorLines_PickGreetLine(vendor)
    - call VendorLines_PickTradeLine(vendor)
    - call VendorLines_PickFarewellLine(vendor)
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
        public constant string TYPE_BARTENDER = "Bartender"
        public constant string TYPE_JEWELCRAFTER = "Jewelcrafter"
        public constant string TYPE_SHAMANIC_GOODS = "Shamanic Goods"
        public constant string TYPE_FEL_CURIOS = "Fel Curios"
        public constant string TYPE_VOODOO_GOODS = "Voodoo Goods"
        public constant string TYPE_ARCANIST = "Arcanist"
        public constant string TYPE_MAGISTER = "Magister"

        private constant integer VL_MAX_PROFILES = 80
        private constant integer VL_MAX_LINES_PER_CATEGORY = 8
        private constant integer VL_LINE_STRIDE = 10
        private constant integer VL_CATEGORY_STRIDE = 10
        private constant integer VL_PROFILE_STRIDE = 80
        private constant string VL_CATALOG_SOUND_MARKER = "@VC"
        private constant string VL_PROFILE_SOUND_MARKER = "@VP"

        private Table VL_ProfileByName = 0
        private Table VL_ProfileByUnitType = 0
        private Table VL_ProfileByUnit = 0
        private Table VL_VoiceTypeByUnitType = 0
        private Table VL_VoiceTypeByUnit = 0
        private hashtable VL_ProfileByVendorZone = InitHashtable()
        private Table VL_LineCount = 0
        private Table VL_LastLine = 0
        private Table VL_SoundTypeByProfile = 0
        private Table VL_CatalogFirstBySoundType = 0
        private integer VL_ProfileCount = 0
        private string array VL_ProfileName
        private string array VL_LineText
        private string array VL_LineSound
        private string array VL_LineSpeaker

        private boolean VL_DefaultRandomLinesEnabled = true
        private real VL_DefaultMinimumInterval = 60.00
        private real VL_DefaultMaximumInterval = 120.00
        private boolean array VL_VendorRandomLinesOverride
        private boolean array VL_VendorRandomLinesEnabled
        private real array VL_VendorMinimumInterval
        private real array VL_VendorMaximumInterval

        private string VL_PickedText = ""
        private string VL_PickedSound = ""
        private string VL_PickedSpeaker = ""
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

    private function VL_FormatSoundKey takes string soundType, integer lineIndex returns string
        if lineIndex < 10 then
            return soundType + "000" + I2S(lineIndex)
        elseif lineIndex < 100 then
            return soundType + "00" + I2S(lineIndex)
        elseif lineIndex < 1000 then
            return soundType + "0" + I2S(lineIndex)
        endif
        return soundType + I2S(lineIndex)
    endfunction

    private function VL_GetCatalogSoundMarker takes integer lineOffset returns string
        return VL_CATALOG_SOUND_MARKER + I2S(lineOffset)
    endfunction

    private function VL_GetProfileSoundMarker takes integer lineIndex returns string
        return VL_PROFILE_SOUND_MARKER + I2S(lineIndex)
    endfunction

    private function VL_GetBoundVoiceType takes unit vendor, integer profileId returns string
        local string soundType = ""

        if vendor != null then
            set soundType = VL_VoiceTypeByUnit.string[GetHandleId(vendor)]
            if soundType == null or soundType == "" then
                set soundType = VL_VoiceTypeByUnitType.string[GetUnitTypeId(vendor)]
            endif
        endif
        if soundType == null or soundType == "" then
            set soundType = VL_SoundTypeByProfile.string[profileId]
        endif
        set vendor = null
        return soundType
    endfunction

    private function VL_ResolveSoundKey takes unit vendor, string soundKey returns string
        local integer profileId
        local integer firstLine
        local integer markerLength
        local string soundType

        if soundKey == null or soundKey == "" then
            return soundKey
        endif
        if (StringLength(soundKey) <= StringLength(VL_PROFILE_SOUND_MARKER) or SubString(soundKey, 0, StringLength(VL_PROFILE_SOUND_MARKER)) != VL_PROFILE_SOUND_MARKER) and (StringLength(soundKey) <= StringLength(VL_CATALOG_SOUND_MARKER) or SubString(soundKey, 0, StringLength(VL_CATALOG_SOUND_MARKER)) != VL_CATALOG_SOUND_MARKER) then
            return soundKey
        endif
        set profileId = VL_GetBoundProfile(vendor)
        set soundType = VL_GetBoundVoiceType(vendor, profileId)
        if soundType == null or soundType == "" then
            return ""
        endif
        set markerLength = StringLength(VL_PROFILE_SOUND_MARKER)
        if StringLength(soundKey) > markerLength and SubString(soundKey, 0, markerLength) == VL_PROFILE_SOUND_MARKER then
            return VL_FormatSoundKey(soundType, S2I(SubString(soundKey, markerLength, StringLength(soundKey))))
        endif
        set markerLength = StringLength(VL_CATALOG_SOUND_MARKER)
        if StringLength(soundKey) > markerLength and SubString(soundKey, 0, markerLength) == VL_CATALOG_SOUND_MARKER then
            set firstLine = VL_CatalogFirstBySoundType.integer[StringHash(soundType)]
            if firstLine > 0 then
                return VL_FormatSoundKey(soundType, firstLine + S2I(SubString(soundKey, markerLength, StringLength(soundKey))))
            endif
            return ""
        endif
        return soundKey
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
        set VL_PickedSpeaker = VL_LineSpeaker[lineKey]
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
        set VL_PickedSpeaker = ""
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
        local string speakerName = VL_PickedSpeaker
        if vendor != null and VL_PickedText != "" then
            if speakerName == "" then
                set speakerName = VL_GetVendorSpeakerName(vendor)
            endif
            set VL_PickedSound = VL_ResolveSoundKey(vendor, VL_PickedSound)
            call DialogSystem_QueueFieldLine(vendor, speakerName, VL_PickedSound, VL_PickedText)
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

    private function VL_RegisterLine takes string profileName, integer category, string speakerName, string text, string soundKey returns nothing
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
        if speakerName == null then
            set speakerName = ""
        endif
        set VL_LineSound[lineKey] = soundKey
        set VL_LineSpeaker[lineKey] = speakerName
    endfunction

    public function RegisterLine takes string profileName, integer category, string text, string soundKey returns nothing
        call VL_RegisterLine(profileName, category, "", text, soundKey)
    endfunction

    public function RegisterCatalogLine takes string profileName, integer category, integer lineOffset, string text returns nothing
        call VL_RegisterLine(profileName, category, "", text, VL_GetCatalogSoundMarker(lineOffset))
    endfunction

    public function RegisterProfileVoiceLine takes string profileName, integer category, string text, integer lineIndex returns nothing
        if lineIndex > 0 then
            call VL_RegisterLine(profileName, category, "", text, VL_GetProfileSoundMarker(lineIndex))
        endif
    endfunction

    public function RegisterSpeakerLine takes string profileName, integer category, string speakerName, string text, string soundKey returns nothing
        call VL_RegisterLine(profileName, category, speakerName, text, soundKey)
    endfunction

    public function RegisterProfileSoundType takes string profileName, string soundType returns nothing
        local integer profileId = VL_GetOrCreateProfile(profileName)

        if profileId > 0 and soundType != null and soundType != "" then
            set VL_SoundTypeByProfile.string[profileId] = soundType
        endif
    endfunction

    public function RegisterSoundTypeCatalogStart takes string soundType, integer firstLine returns nothing
        if soundType != null and soundType != "" and firstLine > 0 then
            set VL_CatalogFirstBySoundType.integer[StringHash(soundType)] = firstLine
        endif
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

    public function BindUnitTypeVoiceType takes integer unitTypeId, string soundType returns nothing
        if unitTypeId != 0 and soundType != null and soundType != "" then
            set VL_VoiceTypeByUnitType.string[unitTypeId] = soundType
        endif
    endfunction

    public function BindUnitVoiceType takes unit vendor, string soundType returns nothing
        if vendor != null and soundType != null and soundType != "" then
            set VL_VoiceTypeByUnit.string[GetHandleId(vendor)] = soundType
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

    public function RegisterCatalogBasicLines takes string vendorName, integer lineOffset, string greetA, string greetB, string tradeLine, string farewellLine returns nothing
        local integer profileId = VL_GetOrCreateProfile(vendorName)

        if vendorName == "" then
            set vendorName = "Merchant"
        endif
        if greetA != "" then
            call DialogSystem_RegisterGreetLine(vendorName, greetA, VL_GetCatalogSoundMarker(lineOffset), true)
        endif
        if greetB != "" then
            call DialogSystem_RegisterGreetLine(vendorName, greetB, VL_GetCatalogSoundMarker(lineOffset + 1), true)
        endif
        if tradeLine != "" then
            call DialogSystem_RegisterTradeLine(vendorName, tradeLine, VL_GetCatalogSoundMarker(lineOffset + 2), true)
        endif
        if farewellLine != "" then
            call DialogSystem_RegisterExitLine(vendorName, farewellLine, VL_GetCatalogSoundMarker(lineOffset + 3), true)
            call DialogSystem_RegisterFarewellLine(vendorName, farewellLine, VL_GetCatalogSoundMarker(lineOffset + 3), true)
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

    public function PickGreetLine takes unit vendor returns boolean
        local boolean result = DialogSystem_PickGreetLine(vendor, VL_GetVendorName(vendor))

        set DialogSystem_PickedSound = VL_ResolveSoundKey(vendor, DialogSystem_PickedSound)
        set vendor = null
        return result
    endfunction

    public function PickTradeLine takes unit vendor returns boolean
        local boolean result = DialogSystem_PickTradeLine(vendor, VL_GetVendorName(vendor))

        set DialogSystem_PickedSound = VL_ResolveSoundKey(vendor, DialogSystem_PickedSound)
        set vendor = null
        return result
    endfunction

    public function PickFarewellLine takes unit vendor returns boolean
        local boolean result = DialogSystem_PickFarewellLine(vendor, VL_GetVendorName(vendor))

        set DialogSystem_PickedSound = VL_ResolveSoundKey(vendor, DialogSystem_PickedSound)
        set vendor = null
        return result
    endfunction

    public function PlayTradeLine takes unit vendor returns nothing
        call PickTradeLine(vendor)
        call DialogSystem_PlayLine(vendor, VL_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    public function PlayFarewellLine takes unit vendor returns nothing
        call PickFarewellLine(vendor)
        call DialogSystem_PlayLine(vendor, VL_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    private function Init takes nothing returns nothing
        set VL_ProfileByName = Table.create()
        set VL_ProfileByUnitType = Table.create()
        set VL_ProfileByUnit = Table.create()
        set VL_VoiceTypeByUnitType = Table.create()
        set VL_VoiceTypeByUnit = Table.create()
        set VL_LineCount = Table.create()
        set VL_LastLine = Table.create()
        set VL_SoundTypeByProfile = Table.create()
        set VL_CatalogFirstBySoundType = Table.create()

    endfunction
endlibrary
