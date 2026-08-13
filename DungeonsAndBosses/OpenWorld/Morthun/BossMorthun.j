/**
    BossMorthun
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers Morthun and restores the recovered open-world patrol.
    Credits:
    - Legacy Morthun Movement Start GUI export.
    How to install:
    Import after Boss and PatrolSystem.
    API:
    - BossMorthun_GetId()
*/
library BossMorthun initializer Init requires Boss, PatrolSystem
    globals
        private integer BossId = 0
        private timer RespawnTimer = null
    endglobals

    private function StartPatrol takes unit whichUnit returns nothing
        call PatrolSystem_Begin(whichUnit)
        call PatrolSystem_SetPoint(whichUnit, 0, GetRectCenterX(gg_rct_MorthunWP02), GetRectCenterY(gg_rct_MorthunWP02), 15.00)
        call PatrolSystem_SetPoint(whichUnit, 1, GetRectCenterX(gg_rct_MorthunWP03), GetRectCenterY(gg_rct_MorthunWP03), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 2, GetRectCenterX(gg_rct_MorthunWP04), GetRectCenterY(gg_rct_MorthunWP04), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 3, GetRectCenterX(gg_rct_MorthunWP05), GetRectCenterY(gg_rct_MorthunWP05), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 4, GetRectCenterX(gg_rct_MorthunWP06), GetRectCenterY(gg_rct_MorthunWP06), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 5, GetRectCenterX(gg_rct_MorthunWP07), GetRectCenterY(gg_rct_MorthunWP07), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 6, GetRectCenterX(gg_rct_MorthunWP08), GetRectCenterY(gg_rct_MorthunWP08), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 7, GetRectCenterX(gg_rct_MorthunWP09), GetRectCenterY(gg_rct_MorthunWP09), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 8, GetRectCenterX(gg_rct_MorthunWP10), GetRectCenterY(gg_rct_MorthunWP10), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 9, GetRectCenterX(gg_rct_MorthunWP11), GetRectCenterY(gg_rct_MorthunWP11), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 10, GetRectCenterX(gg_rct_MorthunWP12), GetRectCenterY(gg_rct_MorthunWP12), 15.00)
        call PatrolSystem_SetPoint(whichUnit, 11, GetRectCenterX(gg_rct_MorthunWP13), GetRectCenterY(gg_rct_MorthunWP13), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 12, GetRectCenterX(gg_rct_MorthunWP14), GetRectCenterY(gg_rct_MorthunWP14), 10.00)
        call PatrolSystem_StartConfigured(whichUnit, 13, 30.00, PATROL_STYLE_PINGPONG, true, "attack", 120.00)
    endfunction

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossMorthun = boss
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
        local unit whichUnit = udg_BossMorthun
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Morthun (Level 5)", null)
        endif

        if whichUnit != null then
            set udg_BossMorthun = whichUnit
            set BossId = Boss_Register(whichUnit, "Morthun")
            call Boss_SetDescription(BossId, "Morthun is an aggressive open-world patrol.", "No combat phases were recovered.", "No boss-only abilities were recovered.", "Expect him along the lake and mountain route.")
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
