/**
    VendorLines

    Author: Valdemar
    Version:

    Description:
    Generic vendor display-name and dialogue-line helpers for PotS shop
    merchants. Vendor template libraries can register their own greet, trade,
    and farewell lines with one call.

    Credits:

    How to install:
    Import after Shop, DialogSystem, and DialogInteraction. Import before
    VendorDialogs and vendor template libraries that register lines.

    API:
    - set name = VendorLines_GetVendorNameByType(unitTypeId)
    - set name = VendorLines_GetVendorName(vendor)
    - set name = VendorLines_GetVendorSpeakerName(vendor)
    - call VendorLines_RegisterBasicLines(name, greet1, greet2, trade, farewell)
    - call VendorLines_PlayTradeLine(vendor)
    - call VendorLines_PlayFarewellLine(vendor)

**/
library VendorLines initializer Init requires DialogSystem, DialogInteraction, Shop
    public function GetVendorNameByType takes integer unitTypeId returns string
        local integer vendorId = Shop_GetVendorIdForUnitType(unitTypeId)

        if vendorId > 0 then
            return Shop_GetVendorName(vendorId)
        endif
        return "Merchant"
    endfunction

    public function GetVendorName takes unit vendor returns string
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

    public function GetVendorSpeakerName takes unit vendor returns string
        local integer vendorId
        local string unitName
        local string vendorType

        if vendor == null then
            set vendor = null
            return "Merchant"
        endif
        set vendorId = Shop_GetVendorIdForUnit(vendor)
        set unitName = DialogInteraction_GetUnitDisplayName(vendor)
        set vendorType = Shop_GetVendorTypeLabel(vendorId)
        if unitName == null or unitName == "" then
            set unitName = VendorLines_GetVendorName(vendor)
        endif
        if vendorType == null or vendorType == "" or vendorType == unitName then
            set vendor = null
            return unitName
        endif

        set vendor = null
        return unitName + " (" + vendorType + ")"
    endfunction

    public function RegisterBasicLines takes string vendorName, string greetA, string greetB, string tradeLine, string farewellLine returns nothing
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

    public function PlayTradeLine takes unit vendor returns nothing
        call DialogSystem_PickTradeLine(vendor, VendorLines_GetVendorName(vendor))
        call DialogSystem_PlayLine(vendor, VendorLines_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    public function PlayFarewellLine takes unit vendor returns nothing
        call DialogSystem_PickFarewellLine(vendor, VendorLines_GetVendorName(vendor))
        call DialogSystem_PlayLine(vendor, VendorLines_GetVendorSpeakerName(vendor), DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        set vendor = null
    endfunction

    private function Init takes nothing returns nothing
        call VendorLines_RegisterBasicLines("Merchant", "Take a look. Fair prices today.", "If you have coin, I have goods.", "Let us see what changes hands.", "Come back when your purse is heavier.")
    endfunction
endlibrary
