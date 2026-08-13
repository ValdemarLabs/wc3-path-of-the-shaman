/**
    DungeonGnollHideout

    Author: Valdemar
    Version: 1.0.0

    Description:
    Configures Gnoll Hideout gameplay containment and the ordinary-creep
    respawn policy. ZonesCore owns its portal geometry, while each boss is
    implemented in a separate BossXXX library in this folder.

    Credits:
    - DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI

    How to install:
    Import after Dungeon and ZoneEvent. Import BossImpaler, BossFeldok, and
    BossAbomination after this library. Keep the referenced editor rects and
    disable the corresponding legacy GUI triggers.

    API:
    - DungeonGnollHideout_GetDungeonId() returns integer

**/
library DungeonGnollHideout initializer Init requires Dungeon, ZoneEvent
    globals
        private constant integer ZONE_ID = 101
        private constant real FULL_RESPAWN_DELAY = 1800.00
        private constant real RANDOM_RESPAWN_PERCENT = 35.00

        private integer DungeonId = 0
    endglobals

    private function RegisterCreeps takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()

        call Dungeon_RegisterZoneCreeps(DungeonId, RANDOM_RESPAWN_PERCENT, 120.00, 320.00)
        call DestroyTimer(whichTimer)
        set whichTimer = null
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()

        set DungeonId = Dungeon_Register(ZONE_ID, gg_rct_EnteringDungeon01, gg_rct_Dungeon01StartingPoint, FULL_RESPAWN_DELAY)
        call Dungeon_AddArea(DungeonId, gg_rct_Dungeon01Area)
        call ZoneEvent_SetZoneCameraMode(ZONE_ID, CameraControl_CAMERA_SPECIAL_MODE_GNOLLHIDEOUT)
        call ZoneEvent_SetFastPanOnEnter(ZONE_ID, true)
        call TimerStart(whichTimer, 0.10, false, function RegisterCreeps)
        set whichTimer = null
    endfunction

    public function GetDungeonId takes nothing returns integer
        return DungeonId
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
