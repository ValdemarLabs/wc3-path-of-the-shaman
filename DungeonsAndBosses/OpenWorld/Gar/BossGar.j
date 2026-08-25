/**
    BossGar
    Author: Valdemar
    Version: 1.0.0
    Description:
    Provides the quest/event-controlled Gar spawn, slow Deadwoods patrol,
    and simple two-phase boss encounter.
    Credits:
    - Gar encounter direction and waypoint layout provided by the map author.
    How to install:
    Import after Boss and PatrolSystem. Create GarWP01 through GarWP06 and
    the BossGar unit variable in World Editor. Do not preplace Gar.
    API:
    - BossGar_Spawn()
    - BossGar_IsSpawned()
    - BossGar_GetId()
*/
library BossGar initializer Init requires Boss, PatrolSystem
    globals
        // Configuration
        private constant integer UNIT_GAR = 'n60Z'
        private constant real PATROL_SPEED = 60.00
        private constant real PATROL_RESET_TIME = 30.00
        private constant real PHASE_TWO_LIFE_FACTOR = 0.50
        private constant real PHASE_TWO_ATTACK_FACTOR = 0.75
        private constant real RESET_SEARCH_RANGE = 1200.00

        private integer BossId = 0
        private timer PhaseTimer = null
        private timer ResetTimer = null
        private group ResetSearchGroup = null
        private real BaseAttackCooldown = 0.00
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function StartPatrol takes unit whichUnit returns nothing
        call PatrolSystem_Begin(whichUnit)
        call PatrolSystem_SetPoint(whichUnit, 0, GetRectCenterX(gg_rct_GarWP01), GetRectCenterY(gg_rct_GarWP01), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 1, GetRectCenterX(gg_rct_GarWP02), GetRectCenterY(gg_rct_GarWP02), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 2, GetRectCenterX(gg_rct_GarWP03), GetRectCenterY(gg_rct_GarWP03), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 3, GetRectCenterX(gg_rct_GarWP04), GetRectCenterY(gg_rct_GarWP04), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 4, GetRectCenterX(gg_rct_GarWP05), GetRectCenterY(gg_rct_GarWP05), 0.00)
        call PatrolSystem_SetPoint(whichUnit, 5, GetRectCenterX(gg_rct_GarWP06), GetRectCenterY(gg_rct_GarWP06), 0.00)
        call PatrolSystem_StartConfigured(whichUnit, 6, PATROL_RESET_TIME, PATROL_STYLE_PINGPONG, true, "attack", PATROL_SPEED)
    endfunction

    private function RestoreCombatStats takes unit whichUnit returns nothing
        if IsAlive(whichUnit) and BaseAttackCooldown > 0.00 then
            call BlzSetUnitAttackCooldown(whichUnit, BaseAttackCooldown, 0)
        endif
    endfunction

    private function CheckPhase takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if Boss_IsActive(BossId) and IsAlive(boss) and Boss_GetPhase(BossId) == 1 and GetUnitState(boss, UNIT_STATE_LIFE) <= GetUnitState(boss, UNIT_STATE_MAX_LIFE) * PHASE_TWO_LIFE_FACTOR then
            call Boss_SetPhase(BossId, 2)
        endif
        set boss = null
    endfunction

    private function CheckReset takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit picked = null
        local boolean enemyFound = false

        if Boss_IsActive(BossId) and IsAlive(boss) then
            call GroupEnumUnitsInRange(ResetSearchGroup, GetUnitX(boss), GetUnitY(boss), RESET_SEARCH_RANGE, null)
            loop
                set picked = FirstOfGroup(ResetSearchGroup)
                exitwhen picked == null
                call GroupRemoveUnit(ResetSearchGroup, picked)
                if IsAlive(picked) and IsUnitEnemy(picked, GetOwningPlayer(boss)) then
                    set enemyFound = true
                    exitwhen true
                endif
            endloop
            call GroupClear(ResetSearchGroup)
            if not enemyFound then
                call Boss_Reset(BossId)
            endif
        endif
        set picked = null
        set boss = null
    endfunction

    private function OnStart takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        call PatrolSystem_Pause(boss)
        call TimerStart(PhaseTimer, 0.25, true, function CheckPhase)
        call TimerStart(ResetTimer, 5.00, true, function CheckReset)
        set boss = null
    endfunction

    private function OnPhase takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if Boss_EventBossId == BossId and Boss_EventPhase == 2 and IsAlive(boss) then
            call BlzSetUnitAttackCooldown(boss, BaseAttackCooldown * PHASE_TWO_ATTACK_FACTOR, 0)
            call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Orc\\Bloodlust\\BloodlustTarget.mdl", boss, "origin"))
        endif
        set boss = null
    endfunction

    private function OnReset takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        call PauseTimer(PhaseTimer)
        call PauseTimer(ResetTimer)
        call RestoreCombatStats(boss)
        if IsAlive(boss) then
            call StartPatrol(boss)
        endif
        set boss = null
    endfunction

    private function OnDeath takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        call PauseTimer(PhaseTimer)
        call PauseTimer(ResetTimer)
        call PatrolSystem_Stop(boss)
        set boss = null
    endfunction

    private function ConfigureBoss takes unit boss returns nothing
        set udg_BossGar = boss
        set BaseAttackCooldown = BlzGetUnitAttackCooldown(boss, 0)
        call Boss_SetAutoStartOnAttack(BossId, true)
        call Boss_SetHome(BossId, GetRectCenterX(gg_rct_GarWP01), GetRectCenterY(gg_rct_GarWP01), GetUnitFacing(boss))
        call Boss_SetPhaseCount(BossId, 2)
        call Boss_SetDescription(BossId, "A slow-roaming flesh golem unleashed in Deadwoods by a quest or world event.", "Phase 1 uses Gar's normal attacks. At 50% health, phase 2 sends him into a frenzy.", "Frenzy reduces Gar's attack cooldown by 25%.", "Keep space around his patrol route and be ready for faster attacks below half health.")
        call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
        call Boss_SetEventCallback(BossId, BOSS_EVENT_PHASE, function OnPhase)
        call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnReset)
        call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
        call StartPatrol(boss)
    endfunction

    private function RegisterBoss takes unit boss returns nothing
        set BossId = Boss_Register(boss, "Gar")
        if BossId > 0 then
            call ConfigureBoss(boss)
        endif
    endfunction

    public function Spawn takes nothing returns unit
        local unit boss = null
        local real facing = Atan2(GetRectCenterY(gg_rct_GarWP02) - GetRectCenterY(gg_rct_GarWP01), GetRectCenterX(gg_rct_GarWP02) - GetRectCenterX(gg_rct_GarWP01)) * bj_RADTODEG

        if BossId > 0 then
            set boss = Boss_GetUnit(BossId)
            if IsAlive(boss) then
                set udg_BossGar = boss
                return boss
            endif
            set boss = Boss_Respawn(BossId)
            if boss != null then
                call ConfigureBoss(boss)
            endif
        else
            set boss = CreateUnit(Player(PLAYER_NEUTRAL_AGGRESSIVE), UNIT_GAR, GetRectCenterX(gg_rct_GarWP01), GetRectCenterY(gg_rct_GarWP01), facing)
            if boss != null then
                call RegisterBoss(boss)
            endif
        endif
        return boss
    endfunction

    public function IsSpawned takes nothing returns boolean
        local unit boss = udg_BossGar
        local boolean result = IsAlive(boss)

        set boss = null
        return result
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Init takes nothing returns nothing
        set PhaseTimer = CreateTimer()
        set ResetTimer = CreateTimer()
        set ResetSearchGroup = CreateGroup()
    endfunction
endlibrary
