/**
    VendorFloatingText

    Author: Valdemar
    Version: 1.1.1

    Description:
    Displays a vendor-type label above registered Shop units while they are in
    the local player's current camera view. Labels follow moving vendors and
    remain hidden through fog, cinematics, or outside the configured camera
    range. A small reusable label pool prevents vendor labels from exhausting
    Warcraft III's shared text-tag limit.

    Credits:
    - Totems.j camera-local floating-text visibility pattern

    How to install:
    Import after Shop and Table. Vendor libraries may initialize in any order;
    registered vendor units are discovered periodically.

    API:
    - call VendorFloatingText_RegisterUnit(vendor)
    - call VendorFloatingText_SetEnabled(enabled)

**/
library VendorFloatingText initializer Init requires Shop, Table, FallenHeroState
    globals
        private constant integer VFT_MAX_VENDORS = 256
        private constant integer VFT_MAX_VISIBLE_LABELS = 8
        private constant real VFT_TEXT_SIZE = 7.00
        private constant real VFT_TEXT_OFFSET_Z = 80.00
        private constant real VFT_TEXT_CHARACTER_WIDTH = 5.00
        private constant real VFT_VISIBLE_RANGE = 1000.00
        private constant real VFT_UPDATE_PERIOD = 0.25
        private constant real VFT_DISCOVERY_PERIOD = 5.00
        private constant integer VFT_TEXT_RED = 255
        private constant integer VFT_TEXT_GREEN = 204
        private constant integer VFT_TEXT_BLUE = 0

        private Table VFT_TrackedByHandle = 0
        private group VFT_EnumGroup = null
        private timer VFT_UpdateTimer = null
        private unit array VFT_Vendors
        private unit array VFT_VisibleVendors
        private real array VFT_VisibleDistanceSquared
        private texttag array VFT_LabelPool
        private integer VFT_VendorCount = 0
        private integer VFT_VisibleCount = 0
        private real VFT_DiscoveryElapsed = VFT_DISCOVERY_PERIOD
        private boolean VFT_Enabled = true
    endglobals

    private function VFT_GetCameraDistanceSquared takes unit vendor returns real
        local real dx = GetUnitX(vendor) - GetCameraTargetPositionX()
        local real dy = GetUnitY(vendor) - GetCameraTargetPositionY()

        set vendor = null
        return dx * dx + dy * dy
    endfunction

    private function VFT_IsInCameraView takes unit vendor returns boolean
        local real distanceSquared

        if not FallenHeroState_IsAlive(vendor) or IsUnitHidden(vendor) or not IsUnitVisible(vendor, GetLocalPlayer()) then
            set vendor = null
            return false
        endif
        set distanceSquared = VFT_GetCameraDistanceSquared(vendor)
        set vendor = null
        return distanceSquared <= VFT_VISIBLE_RANGE * VFT_VISIBLE_RANGE
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

        if vendor == null or Shop_GetVendorIdForUnit(vendor) <= 0 or VFT_VendorCount >= VFT_MAX_VENDORS then
            set vendor = null
            return false
        endif
        set handleId = GetHandleId(vendor)
        if VFT_TrackedByHandle.boolean[handleId] then
            set vendor = null
            return true
        endif

        set VFT_VendorCount = VFT_VendorCount + 1
        set VFT_Vendors[VFT_VendorCount] = vendor
        set VFT_TrackedByHandle.boolean[handleId] = true

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

        call VFT_TrackedByHandle.boolean.remove(handleId)
        set VFT_Vendors[index] = VFT_Vendors[VFT_VendorCount]
        set VFT_Vendors[VFT_VendorCount] = null
        set VFT_VendorCount = VFT_VendorCount - 1

        set vendor = null
    endfunction

    // Camera state is local, so this selection is used only for local text-tag presentation.
    private function VFT_CollectVisibleVendor takes unit vendor returns nothing
        local real distanceSquared = VFT_GetCameraDistanceSquared(vendor)
        local integer index = 2
        local integer farthestIndex = 1

        if VFT_VisibleCount < VFT_MAX_VISIBLE_LABELS then
            set VFT_VisibleCount = VFT_VisibleCount + 1
            set VFT_VisibleVendors[VFT_VisibleCount] = vendor
            set VFT_VisibleDistanceSquared[VFT_VisibleCount] = distanceSquared
            set vendor = null
            return
        endif

        loop
            exitwhen index > VFT_VisibleCount
            if VFT_VisibleDistanceSquared[index] > VFT_VisibleDistanceSquared[farthestIndex] then
                set farthestIndex = index
            endif
            set index = index + 1
        endloop

        if distanceSquared < VFT_VisibleDistanceSquared[farthestIndex] then
            set VFT_VisibleVendors[farthestIndex] = vendor
            set VFT_VisibleDistanceSquared[farthestIndex] = distanceSquared
        endif
        set vendor = null
    endfunction

    private function VFT_RenderVisibleLabels takes nothing returns nothing
        local integer index = 1
        local string label
        local real offsetX
        local unit vendor
        local texttag tt

        loop
            exitwhen index > VFT_MAX_VISIBLE_LABELS
            set tt = VFT_LabelPool[index]
            if index <= VFT_VisibleCount then
                set vendor = VFT_VisibleVendors[index]
                if tt != null and vendor != null then
                    set label = VFT_GetLabel(vendor)
                    set offsetX = I2R(StringLength(label)) * VFT_TEXT_CHARACTER_WIDTH * 0.50
                    call SetTextTagText(tt, label, VFT_TEXT_SIZE * 0.023 / 10.00)
                    call SetTextTagPos(tt, GetUnitX(vendor) - offsetX, GetUnitY(vendor), VFT_TEXT_OFFSET_Z)
                    call SetTextTagVisibility(tt, true)
                endif
            elseif tt != null then
                call SetTextTagVisibility(tt, false)
            endif
            set VFT_VisibleVendors[index] = null
            set VFT_VisibleDistanceSquared[index] = 0.00
            set index = index + 1
        endloop

        set VFT_VisibleCount = 0
        set label = null
        set tt = null
        set vendor = null
    endfunction

    private function VFT_Update takes nothing returns nothing
        local integer index = 1
        local unit vendor

        loop
            exitwhen index > VFT_VendorCount
            set vendor = VFT_Vendors[index]
            if vendor == null or GetUnitTypeId(vendor) == 0 or Shop_GetVendorIdForUnit(vendor) <= 0 then
                call VFT_RemoveAt(index)
            else
                if VFT_Enabled and not udg_InCinematic and VFT_IsInCameraView(vendor) then
                    call VFT_CollectVisibleVendor(vendor)
                endif
                set index = index + 1
            endif
        endloop
        call VFT_RenderVisibleLabels()

        set VFT_DiscoveryElapsed = VFT_DiscoveryElapsed + VFT_UPDATE_PERIOD
        if VFT_DiscoveryElapsed >= VFT_DISCOVERY_PERIOD then
            set VFT_DiscoveryElapsed = 0.00
            call VFT_DiscoverVendors()
        endif

        set vendor = null
    endfunction

    public function SetEnabled takes boolean enabled returns nothing
        set VFT_Enabled = enabled
    endfunction

    private function VFT_CreateLabelPool takes nothing returns nothing
        local integer index = 1
        local texttag tt

        loop
            exitwhen index > VFT_MAX_VISIBLE_LABELS
            set tt = CreateTextTag()
            call SetTextTagText(tt, "", VFT_TEXT_SIZE * 0.023 / 10.00)
            call SetTextTagColor(tt, VFT_TEXT_RED, VFT_TEXT_GREEN, VFT_TEXT_BLUE, 255)
            call SetTextTagPermanent(tt, true)
            call SetTextTagVelocity(tt, 0.00, 0.00)
            call SetTextTagVisibility(tt, false)
            set VFT_LabelPool[index] = tt
            set index = index + 1
        endloop
        set tt = null
    endfunction

    private function Init takes nothing returns nothing
        set VFT_TrackedByHandle = Table.create()
        set VFT_EnumGroup = CreateGroup()
        set VFT_UpdateTimer = CreateTimer()
        call VFT_CreateLabelPool()
        call TimerStart(VFT_UpdateTimer, VFT_UPDATE_PERIOD, true, function VFT_Update)
    endfunction
endlibrary
