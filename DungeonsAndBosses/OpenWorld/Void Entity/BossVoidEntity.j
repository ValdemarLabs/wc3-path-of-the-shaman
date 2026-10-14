/**
    BossVoidEntity
    Author: Valdemar
    Version: 1.3.0
    Description:
    Replaces the hidden Void Entity lifecycle, reveal state, scripted defeat,
    and combat dialogue integration. Quest state remains owned by qXXX code
    through an optional defeat callback.
    Credits:
    - Draft legacy Void Entity GUI exports, used only for encounter mechanics.
    How to install:
    Import after Boss, BossVoidEntityDialogue, and the ElvenTown map rect.
    A current qXXX quest may register the optional defeat callback.
    API:
    - BossVoidEntity_GetId()
    - BossVoidEntity_Hide()
    - BossVoidEntity_Reveal()
    - BossVoidEntity_SetQuestCallback(onBossDefeated)
*/
library BossVoidEntity initializer Init requires Boss, BossVoidEntityDialogue
    globals
        private constant integer UNIT_VOID_ENTITY = 'n01Z'
        private integer BossId = 0
        private timer DefeatTimer = null
        private trigger BossDefeatedCallback = null
        private boolean Revealed = false
    endglobals

    private function RunQuestCallback takes nothing returns nothing
        if BossDefeatedCallback != null then
            call TriggerExecute(BossDefeatedCallback)
        endif
    endfunction

    private function FinishDefeat takes nothing returns nothing
        call Boss_FinishScriptedDefeat(BossId)
        call RunQuestCallback()
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

    // The owning qXXX library performs QuestData updates inside this callback.
    public function SetQuestCallback takes code onBossDefeated returns nothing
        if BossDefeatedCallback != null then
            call DestroyTrigger(BossDefeatedCallback)
            set BossDefeatedCallback = null
        endif
        if onBossDefeated != null then
            set BossDefeatedCallback = CreateTrigger()
            call TriggerAddAction(BossDefeatedCallback, onBossDefeated)
        endif
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
        local unit whichUnit = Boss_ResolvePlacedUnit(gg_unit_n01Z_2102, udg_BossVoidEntity, UNIT_VOID_ENTITY, gg_rct_ElvenTown)
        if whichUnit != null then
            set udg_BossVoidEntity = whichUnit
            set BossId = Boss_Register(whichUnit, "Void Entity")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetCombatArea(BossId, gg_rct_ElvenTown, Player(0), true)
            call Boss_SetDefeatMode(BossId, BOSS_DEFEAT_MODE_SCRIPTED)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEFEAT, function OnDefeat)
            call Boss_SetDescription(BossId, "A hidden Void Entity manifestation.", "The current library runs one combat phase and delays defeat so the death dialogue can finish.", "No encounter-specific combat abilities are defined here; the dialogue library handles proximity-limited combat lines.", "Stay inside the configured combat area or the encounter resets. The final blow resolves after the death dialogue.")
            call BossVoidEntityDialogue_Bind(whichUnit)
            call Hide()
        else
            call BJDebugMsg("|cffff8080[BossVoidEntity] ERROR:|r Could not find placed Void Entity unit 'n01Z'.")
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
