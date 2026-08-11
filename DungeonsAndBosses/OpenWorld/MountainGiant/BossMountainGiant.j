/**
    BossMountainGiant
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers the Mountain Giant and restores its patrol route.
    Credits:
    - Legacy MountainGiant movement GUI exports.
    How to install:
    Import after Boss and PatrolSystem.
    API:
    - BossMountainGiant_GetId()
*/
library BossMountainGiant initializer Init requires Boss, PatrolSystem
    globals
        private integer BossId = 0
        private timer RespawnTimer = null
    endglobals

    private function StartPatrol takes unit whichUnit returns nothing
        call PatrolSystem_SetPoint(whichUnit, 0, GetRectCenterX(gg_rct_MountainGiantWP01), GetRectCenterY(gg_rct_MountainGiantWP01), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 1, GetRectCenterX(gg_rct_MountainGiantWP02), GetRectCenterY(gg_rct_MountainGiantWP02), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 2, GetRectCenterX(gg_rct_MountainGiantWP03), GetRectCenterY(gg_rct_MountainGiantWP03), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 3, GetRectCenterX(gg_rct_MountainGiantWP04), GetRectCenterY(gg_rct_MountainGiantWP04), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 4, GetRectCenterX(gg_rct_MountainGiantWP05), GetRectCenterY(gg_rct_MountainGiantWP05), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 5, GetRectCenterX(gg_rct_MountainGiantWP06), GetRectCenterY(gg_rct_MountainGiantWP06), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 6, GetRectCenterX(gg_rct_MountainGiantWP07), GetRectCenterY(gg_rct_MountainGiantWP07), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 7, GetRectCenterX(gg_rct_MountainGiantWP08), GetRectCenterY(gg_rct_MountainGiantWP08), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 8, GetRectCenterX(gg_rct_MountainGiantWP09), GetRectCenterY(gg_rct_MountainGiantWP09), 15.00)
        call PatrolSystem_SetPoint(whichUnit, 9, GetRectCenterX(gg_rct_MountainGiantWP10), GetRectCenterY(gg_rct_MountainGiantWP10), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 10, GetRectCenterX(gg_rct_MountainGiantWP11), GetRectCenterY(gg_rct_MountainGiantWP11), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 11, GetRectCenterX(gg_rct_MountainGiantWP12), GetRectCenterY(gg_rct_MountainGiantWP12), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 12, GetRectCenterX(gg_rct_MountainGiantWP06), GetRectCenterY(gg_rct_MountainGiantWP06), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 13, GetRectCenterX(gg_rct_MountainGiantWP05), GetRectCenterY(gg_rct_MountainGiantWP05), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 14, GetRectCenterX(gg_rct_MountainGiantWP04), GetRectCenterY(gg_rct_MountainGiantWP04), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 15, GetRectCenterX(gg_rct_MountainGiantWP03), GetRectCenterY(gg_rct_MountainGiantWP03), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 16, GetRectCenterX(gg_rct_MountainGiantWP02), GetRectCenterY(gg_rct_MountainGiantWP02), 0.00)
        call PatrolSystem_Start(whichUnit, 17, 30.00, 0, true, "attack", 120.00)
    endfunction

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossMountainGiant = boss
            call StartPatrol(boss)
        endif
        set boss = null
    endfunction

    private function OnDeath takes nothing returns nothing
        call TimerStart(RespawnTimer, GetRandomReal(120.00, 320.00), false, function Respawn)
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = udg_BossMountainGiant
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Mountain Giant", null)
        endif

        if whichUnit != null then
            set udg_BossMountainGiant = whichUnit
            set BossId = Boss_Register(whichUnit, "Mountain Giant")
            call Boss_SetDescription(BossId, "A roaming mountain giant.", "No combat phases were recovered.", "No boss-only abilities were recovered.", "Watch the mountain path and avoid starting a fight without room to maneuver.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
            call StartPatrol(whichUnit)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
