/**
    VendorFloatingText

    Author: Valdemar
    Version: 1.0.0

    Description:
    Displays a vendor-type label above registered Shop units while they are in
    the local player's current camera view. Labels follow moving vendors and
    remain hidden through fog or outside the configured camera range.

    Credits:
    - Totems.j camera-local floating-text visibility pattern

    How to install:
    Import after Shop and Table. Vendor libraries may initialize in any order;
    registered vendor units are discovered periodically.

    API:
    - call VendorFloatingText_RegisterUnit(vendor)
    - call VendorFloatingText_SetEnabled(enabled)

**/
library VendorFloatingText initializer Init requires Shop, Table
    globals
        private constant integer VFT_MAX_VENDORS = 256
        private constant real VFT_TEXT_SIZE = 7.00
        private constant real VFT_TEXT_OFFSET_Z = 80.00
        private constant real VFT_VISIBLE_RANGE = 1000.00
        private constant real VFT_UPDATE_PERIOD = 0.25
        private constant real VFT_DISCOVERY_PERIOD = 5.00
        private constant integer VFT_TEXT_RED = 255
        private constant integer VFT_TEXT_GREEN = 204
        private constant integer VFT_TEXT_BLUE = 0

        private Table VFT_TextByHandle = 0
        private Table VFT_TrackedByHandle = 0
        private group VFT_EnumGroup = null
        private timer VFT_UpdateTimer = null
        private unit array VFT_Vendors
        private integer VFT_VendorCount = 0
        private real VFT_DiscoveryElapsed = VFT_DISCOVERY_PERIOD
        private boolean VFT_Enabled = true
    endglobals

    private function VFT_IsInCameraView takes unit vendor returns boolean
        local real dx
        local real dy

        if vendor == null or GetUnitTypeId(vendor) == 0 or GetWidgetLife(vendor) <= 0.405 or IsUnitHidden(vendor) or not IsUnitVisible(vendor, GetLocalPlayer()) then
            set vendor = null
            return false
        endif
        set dx = GetUnitX(vendor) - GetCameraTargetPositionX()
        set dy = GetUnitY(vendor) - GetCameraTargetPositionY()
        set vendor = null
        return dx * dx + dy * dy <= VFT_VISIBLE_RANGE * VFT_VISIBLE_RANGE
    endfunction

    private function VFT_GetLabel takes unit vendor returns string
        local integer vendorId = Shop_GetVendorIdForUnit(vendor)
        local string vendorType = Shop_GetVendorTypeLabel(vendorId)

        if vendorType == null or vendorType == "" then
            set vendor = null
            return "<Merchant>"
        endif
        set vendor = null
        return "<" + vendorType + ">"
    endfunction

    public function RegisterUnit takes unit vendor returns boolean
        local integer handleId
        local texttag tt

        if vendor == null or Shop_GetVendorIdForUnit(vendor) <= 0 or VFT_VendorCount >= VFT_MAX_VENDORS then
            set vendor = null
            return false
        endif
        set handleId = GetHandleId(vendor)
        if VFT_TrackedByHandle.boolean[handleId] then
            set vendor = null
            return true
        endif

        set tt = CreateTextTag()
        call SetTextTagText(tt, VFT_GetLabel(vendor), VFT_TEXT_SIZE * 0.023 / 10.00)
        call SetTextTagPosUnit(tt, vendor, VFT_TEXT_OFFSET_Z)
        call SetTextTagColor(tt, VFT_TEXT_RED, VFT_TEXT_GREEN, VFT_TEXT_BLUE, 255)
        call SetTextTagPermanent(tt, true)
        call SetTextTagVelocity(tt, 0.00, 0.00)
        call SetTextTagVisibility(tt, false)
        set VFT_VendorCount = VFT_VendorCount + 1
        set VFT_Vendors[VFT_VendorCount] = vendor
        set VFT_TextByHandle.texttag[handleId] = tt
        set VFT_TrackedByHandle.boolean[handleId] = true

        set tt = null
        set vendor = null
        return true
    endfunction

    private function VFT_DiscoverVendors takes nothing returns nothing
        local unit vendor

        call GroupEnumUnitsInRect(VFT_EnumGroup, bj_mapInitialPlayableArea, null)
        loop
            set vendor = FirstOfGroup(VFT_EnumGroup)
            exitwhen vendor == null
            call GroupRemoveUnit(VFT_EnumGroup, vendor)
            if Shop_GetVendorIdForUnit(vendor) > 0 then
                call VendorFloatingText_RegisterUnit(vendor)
            endif
        endloop
        set vendor = null
    endfunction

    private function VFT_RemoveAt takes integer index returns nothing
        local unit vendor = VFT_Vendors[index]
        local integer handleId = GetHandleId(vendor)
        local texttag tt = VFT_TextByHandle.texttag[handleId]

        if tt != null then
            call DestroyTextTag(tt)
        endif
        call VFT_TextByHandle.texttag.remove(handleId)
        call VFT_TrackedByHandle.boolean.remove(handleId)
        set VFT_Vendors[index] = VFT_Vendors[VFT_VendorCount]
        set VFT_Vendors[VFT_VendorCount] = null
        set VFT_VendorCount = VFT_VendorCount - 1

        set tt = null
        set vendor = null
    endfunction

    private function VFT_Update takes nothing returns nothing
        local integer index = 1
        local unit vendor
        local texttag tt

        loop
            exitwhen index > VFT_VendorCount
            set vendor = VFT_Vendors[index]
            if vendor == null or GetUnitTypeId(vendor) == 0 or Shop_GetVendorIdForUnit(vendor) <= 0 then
                call VFT_RemoveAt(index)
            else
                set tt = VFT_TextByHandle.texttag[GetHandleId(vendor)]
                if tt != null then
                    call SetTextTagText(tt, VFT_GetLabel(vendor), VFT_TEXT_SIZE * 0.023 / 10.00)
                    call SetTextTagPosUnit(tt, vendor, VFT_TEXT_OFFSET_Z)
                    call SetTextTagVisibility(tt, VFT_Enabled and VFT_IsInCameraView(vendor))
                endif
                set index = index + 1
            endif
        endloop

        set VFT_DiscoveryElapsed = VFT_DiscoveryElapsed + VFT_UPDATE_PERIOD
        if VFT_DiscoveryElapsed >= VFT_DISCOVERY_PERIOD then
            set VFT_DiscoveryElapsed = 0.00
            call VFT_DiscoverVendors()
        endif

        set tt = null
        set vendor = null
    endfunction

    public function SetEnabled takes boolean enabled returns nothing
        set VFT_Enabled = enabled
    endfunction

    private function Init takes nothing returns nothing
        set VFT_TextByHandle = Table.create()
        set VFT_TrackedByHandle = Table.create()
        set VFT_EnumGroup = CreateGroup()
        set VFT_UpdateTimer = CreateTimer()
        call TimerStart(VFT_UpdateTimer, VFT_UPDATE_PERIOD, true, function VFT_Update)
    endfunction
endlibrary
