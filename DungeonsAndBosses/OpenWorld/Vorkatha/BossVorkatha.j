/**
    BossVorkatha
    Author: Valdemar
    Version: 1.0.0
    Description:
    Catalog registration for Vorkatha until encounter mechanics are recovered.
    Credits:
    - Empty legacy Vorkatha GUI exports.
    How to install:
    Import after Boss.
    API:
    - BossVorkatha_GetId()
*/
library BossVorkatha initializer Init requires Boss
    globals
        private integer BossId = 0
        private timer RespawnTimer = null
    endglobals

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossVorkatha = boss
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
        local unit whichUnit = udg_BossVorkatha
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Vorkatha (Level 20) - Devilsaur", null)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Vorkatha", null)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Vorkahta", null)
        endif

        if whichUnit != null then
            set udg_BossVorkatha = whichUnit
            set BossId = Boss_Register(whichUnit, "Vorkatha")
            call Boss_SetDescription(BossId, "Vorkatha is catalogued as an open-world boss.", "No recoverable phase data exists.", "No recoverable ability data exists.", "Encounter mechanics await a source trigger or design pass.")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
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
