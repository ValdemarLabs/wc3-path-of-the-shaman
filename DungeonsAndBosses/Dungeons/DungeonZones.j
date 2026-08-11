/**
    DungeonZones

    Author: Valdemar
    Version: 1.0.0

    Description:
    Registers the gameplay dungeon zones that do not yet have a dedicated
    encounter library. Wyrmhold Sanctum and Firelands receive the shared
    grouped/random creep policy and use their zone footprints as routing
    fallbacks because the map defines no dedicated entrance rects for them.
    Dreadforge supplies synchronized entrance routing data while its encounter
    roster remains explicit and unregistered.

    Credits:
    - ZonesCore dungeon definitions 103, 105, and 106

    How to install:
    Import after Dungeon and ZoneEvent. Keep the referenced zone and transition
    rects. Replace the Wyrmhold/Firelands routing rects here if dedicated
    entrance rects are added in World Editor.

    API:
    - DungeonZones_GetWyrmholdId() returns integer
    - DungeonZones_GetFirelandsId() returns integer
    - DungeonZones_GetDreadforgeId() returns integer

**/
library DungeonZones initializer Init requires Dungeon, ZoneEvent
    globals
        private integer WyrmholdId = 0
        private integer FirelandsId = 0
        private integer DreadforgeId = 0
    endglobals

    public function GetWyrmholdId takes nothing returns integer
        return WyrmholdId
    endfunction

    public function GetFirelandsId takes nothing returns integer
        return FirelandsId
    endfunction

    public function GetDreadforgeId takes nothing returns integer
        return DreadforgeId
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()

        set WyrmholdId = Dungeon_Register(103, gg_rct_05WyrmholdSanctum, gg_rct_05WyrmholdSanctum, 300.00)
        call Dungeon_AddArea(WyrmholdId, gg_rct_05WyrmholdSanctum)
        call Dungeon_RegisterZoneCreeps(WyrmholdId, 35.00, 120.00, 320.00)

        set FirelandsId = Dungeon_Register(105, gg_rct_016Firelands, gg_rct_016Firelands, 300.00)
        call Dungeon_AddArea(FirelandsId, gg_rct_016Firelands)
        call Dungeon_RegisterZoneCreeps(FirelandsId, 35.00, 120.00, 320.00)
        call ZoneEvent_SetFastPanOnEnter(105, true)

        set DreadforgeId = Dungeon_Register(106, gg_rct_106Dreadforge, gg_rct_106DreadforgeA, 300.00)
        call Dungeon_AddArea(DreadforgeId, gg_rct_106DreadforgeA)
        call Dungeon_AddArea(DreadforgeId, gg_rct_106DreadforgeB)
        call Dungeon_AddArea(DreadforgeId, gg_rct_106DreadforgeExit)

        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
