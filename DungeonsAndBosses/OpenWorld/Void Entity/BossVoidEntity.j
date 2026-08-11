/**
    BossVoidEntity
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers the quest-gated Void Entity encounter.
    Credits:
    - Legacy Void Entity GUI exports.
    How to install:
    Import after Boss and the ElvenTown map rect.
    API:
    - BossVoidEntity_GetId()
*/
library BossVoidEntity initializer Init requires Boss
    globals
        private integer BossId = 0
        private timer DefeatTimer = null
    endglobals
    private function FinishDefeat takes nothing returns nothing
        call Boss_FinishScriptedDefeat(BossId)
    endfunction
    private function OnDefeat takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), false)
        call TimerStart(DefeatTimer, 1.00, false, function FinishDefeat)
        set boss = null
    endfunction
    public function GetId takes nothing returns integer
        return BossId
    endfunction
    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByName("Void Entity", gg_rct_ElvenTown)
        if whichUnit != null then
            set udg_BossVoidEntity = whichUnit
            set BossId = Boss_Register(whichUnit, "Void Entity")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetArena(BossId, gg_rct_ElvenTown, Player(0), true)
            call Boss_SetDefeatMode(BossId, BOSS_DEFEAT_MODE_SCRIPTED)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEFEAT, function OnDefeat)
            call Boss_SetDescription(BossId, "A hidden void manifestation tied to Mad Blix's quest in ElvenTown.", "One recovered phase; its death is a scripted quest sequence.", "No recoverable combat abilities exist; its legacy triggers provide proximity-limited combat dialogue.", "Keep the fight in ElvenTown or it resets. The last hit must remain scripted so the quest can complete.")
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        set DefeatTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
