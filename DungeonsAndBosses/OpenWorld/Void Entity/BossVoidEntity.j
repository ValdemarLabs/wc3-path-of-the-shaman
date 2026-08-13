/**
    BossVoidEntity
    Author: Valdemar
    Version: 1.0.0
    Description:
    Replaces the quest-gated Void Entity lifecycle, reveal state, scripted
    defeat, quest requirement completion, and combat dialogue integration.
    Credits:
    - Legacy Void Entity GUI exports.
    How to install:
    Import after Boss, BossVoidEntityDialogue, and the ElvenTown map rect.
    API:
    - BossVoidEntity_GetId()
    - BossVoidEntity_Hide()
    - BossVoidEntity_Reveal()
    - BossVoidEntity_RegisterCompletionCallback(callback)
*/
library BossVoidEntity initializer Init requires Boss, BossVoidEntityDialogue
    globals
        private integer BossId = 0
        private timer DefeatTimer = null
        private trigger CompletionCallback = null
        private boolean Revealed = false
    endglobals

    private function CompleteQuest takes nothing returns nothing
        if udg_QuestBoomWillBeBackReq1 != null then
            call QuestItemSetCompleted(udg_QuestBoomWillBeBackReq1, true)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 8.00, "|cffffcc00QUEST UPDATE|r")
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 8.00, "Mad Blix has been defeated.")
        endif
        if CompletionCallback != null then
            call TriggerExecute(CompletionCallback)
        endif
    endfunction

    private function FinishDefeat takes nothing returns nothing
        call Boss_FinishScriptedDefeat(BossId)
        call CompleteQuest()
    endfunction

    public function Hide takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        set Revealed = false
        if boss != null then
            call UnitAddAbility(boss, 'Agho')
            call SetUnitInvulnerable(boss, true)
            call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), false)
            call BossVoidEntityDialogue_SetEnabled(false)
        endif
        set boss = null
    endfunction

    public function Reveal takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        set Revealed = true
        if boss != null then
            call UnitRemoveAbility(boss, 'Agho')
            call SetUnitInvulnerable(boss, false)
            call SetUnitOwner(boss, Player(11), true)
            call Boss_SetResetOwner(BossId, Player(11))
            call BossVoidEntityDialogue_SetEnabled(true)
        endif
        set boss = null
    endfunction

    public function RegisterCompletionCallback takes code callback returns nothing
        if CompletionCallback == null then
            set CompletionCallback = CreateTrigger()
        endif
        call TriggerAddAction(CompletionCallback, callback)
    endfunction

    private function OnStart takes nothing returns nothing
        call BossVoidEntityDialogue_SetEnabled(true)
        call BossVoidEntityDialogue_PlayStart()
    endfunction

    private function OnReset takes nothing returns nothing
        if Revealed then
            call Reveal()
        else
            call Hide()
        endif
    endfunction

    private function OnDefeat takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        call BossVoidEntityDialogue_PlayDeath()
        call BossVoidEntityDialogue_SetEnabled(false)
        call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), false)
        call TimerStart(DefeatTimer, 4.00, false, function FinishDefeat)
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
            call Boss_SetCombatArea(BossId, gg_rct_ElvenTown, Player(0), true)
            call Boss_SetDefeatMode(BossId, BOSS_DEFEAT_MODE_SCRIPTED)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEFEAT, function OnDefeat)
            call Boss_SetDescription(BossId, "A hidden void manifestation tied to Mad Blix's quest in ElvenTown.", "One recovered phase; its death is a scripted quest sequence.", "No recoverable combat abilities exist; its legacy triggers provide proximity-limited combat dialogue.", "Keep the fight in ElvenTown or it resets. The last hit must remain scripted so the quest can complete.")
            call BossVoidEntityDialogue_Bind(whichUnit)
            call Hide()
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction

    private function OnDebugReveal takes nothing returns nothing
        call Reveal()
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()
        local trigger debugTrigger = CreateTrigger()
        set DefeatTimer = CreateTimer()
        call TriggerRegisterPlayerChatEvent(debugTrigger, Player(0), "/debug VoidEntity", true)
        call TriggerAddAction(debugTrigger, function OnDebugReveal)
        call TimerStart(initTimer, 0.00, false, function Register)
        set debugTrigger = null
        set initTimer = null
    endfunction
endlibrary
