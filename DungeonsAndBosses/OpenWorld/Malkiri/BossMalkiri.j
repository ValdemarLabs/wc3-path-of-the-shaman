/**
    BossMalkiri
    Author: Valdemar
    Version: 1.0.0
    Description:
    Catalog registration for Mal'kiri until source encounter data is available.
    Credits:
    - No legacy Malkiri export was present.
    How to install:
    Import after Boss.
    API:
    - BossMalkiri_GetId()
*/
library BossMalkiri initializer Init requires Boss
    globals
        private integer BossId = 0
        private timer RespawnTimer = null
    endglobals

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossMalkiri = boss
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
        local unit whichUnit = udg_BossMalkiri
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Mal'kiri (Level 15) - Panther", null)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Mal'kiri", null)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Malkiri", null)
        endif

        if whichUnit != null then
            set udg_BossMalkiri = whichUnit
            set BossId = Boss_Register(whichUnit, "Mal'kiri")
            call Boss_SetDescription(BossId, "Mal'kiri is catalogued as an open-world boss.", "No source phase data is available.", "No source ability data is available.", "Encounter mechanics await a design pass.")
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
