/**
    BossSargoth
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers Sargoth and replaces its two recovered burrow/add phases.
    Credits:
    - Legacy Sargoth GUI exports.
    How to install:
    Import after Boss, CreepRespawn, and the Sargoth lair map rects.
    API:
    - BossSargoth_GetId()
*/
library BossSargoth initializer Init requires Boss, CreepRespawn
    globals
        private constant integer ABILITY_BURROW = 'A63A'
        private integer BossId = 0
        private timer PhaseTimer = null
        private timer BurrowTimer = null
        private timer RespawnTimer = null
        private group SpiderGroup = null
        private integer BurrowStage = 0
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function ClearSpiders takes nothing returns nothing
        local unit picked = null

        loop
            set picked = FirstOfGroup(SpiderGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SpiderGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function SpawnSpiders takes integer unitTypeId, integer count, rect spawnRect returns nothing
        local integer index = 0
        local unit spawned = null

        loop
            exitwhen index >= count
            set spawned = CreateUnit(Player(11), unitTypeId, GetRandomReal(GetRectMinX(spawnRect), GetRectMaxX(spawnRect)), GetRandomReal(GetRectMinY(spawnRect), GetRectMaxY(spawnRect)), GetRandomReal(0.00, 360.00))
            if spawned != null then
                call CreepRespawn_DiscardUnit(spawned)
                call GroupAddUnit(SpiderGroup, spawned)
                call IssuePointOrder(spawned, "attack", GetRandomReal(GetRectMinX(gg_rct_SargothSpiderAttackPoint), GetRectMaxX(gg_rct_SargothSpiderAttackPoint)), GetRandomReal(GetRectMinY(gg_rct_SargothSpiderAttackPoint), GetRectMaxY(gg_rct_SargothSpiderAttackPoint)))
            endif
            set spawned = null
            set index = index + 1
        endloop
    endfunction

    private function SpawnAtAllEntrances takes integer unitTypeId, integer count returns nothing
        call SpawnSpiders(unitTypeId, count, gg_rct_SargothSpiders1)
        call SpawnSpiders(unitTypeId, count, gg_rct_SargothSpiders2)
        call SpawnSpiders(unitTypeId, count, gg_rct_SargothSpiders3)
    endfunction

    private function FinishBurrow takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        set BurrowStage = 0
        if IsAlive(boss) then
            call SetUnitInvulnerable(boss, false)
            call IssueImmediateOrder(boss, "unburrow")
            call UnitRemoveAbility(boss, ABILITY_BURROW)
        endif
        set boss = null
    endfunction

    private function AdvanceBurrow takes nothing returns nothing
        if not Boss_IsActive(BossId) then
            set BurrowStage = 0
            return
        endif

        if BurrowStage == 1 then
            call SpawnAtAllEntrances('nssp', 1)
            set BurrowStage = 2
            call TimerStart(BurrowTimer, 15.00, false, function AdvanceBurrow)
        elseif BurrowStage == 3 then
            call SpawnAtAllEntrances('nsgt', 1)
            call SpawnAtAllEntrances('nspr', 4)
            set BurrowStage = 4
            call TimerStart(BurrowTimer, 15.00, false, function AdvanceBurrow)
        else
            call FinishBurrow()
        endif
    endfunction

    private function BeginBurrow takes integer phase returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if not IsAlive(boss) then
            set boss = null
            return
        endif
        call UnitAddAbility(boss, ABILITY_BURROW)
        call SetUnitInvulnerable(boss, true)
        call IssueImmediateOrder(boss, "burrow")
        if phase == 2 then
            set BurrowStage = 1
            call SpawnAtAllEntrances('nspr', 3)
        else
            set BurrowStage = 3
            call SpawnAtAllEntrances('nsgt', 3)
        endif
        call TimerStart(BurrowTimer, 15.00, false, function AdvanceBurrow)
        set boss = null
    endfunction

    private function OnPhase takes nothing returns nothing
        if Boss_EventBossId == BossId and (Boss_EventPhase == 2 or Boss_EventPhase == 3) then
            call BeginBurrow(Boss_EventPhase)
        endif
    endfunction

    private function CheckPhase takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        if Boss_IsActive(BossId) and whichUnit != null then
            if Boss_GetPhase(BossId) < 3 and GetUnitState(whichUnit, UNIT_STATE_LIFE) <= GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.25 then
                call Boss_SetPhase(BossId, 3)
            elseif Boss_GetPhase(BossId) == 1 and GetUnitState(whichUnit, UNIT_STATE_LIFE) <= GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE) * 0.50 then
                call Boss_SetPhase(BossId, 2)
            endif
        endif
        set whichUnit = null
    endfunction
    private function OnStart takes nothing returns nothing
        call TimerStart(PhaseTimer, 0.10, true, function CheckPhase)
    endfunction
    private function OnEnd takes nothing returns nothing
        call PauseTimer(PhaseTimer)
        call PauseTimer(BurrowTimer)
        call FinishBurrow()
        call ClearSpiders()
    endfunction
    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_BossSargoth = boss
        endif
        set boss = null
    endfunction
    private function OnDeath takes nothing returns nothing
        call OnEnd()
        call TimerStart(RespawnTimer, GetRandomReal(240.00, 500.00), false, function Respawn)
    endfunction
    public function GetId takes nothing returns integer
        return BossId
    endfunction
    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = Boss_FindUnitByName("Sargoth", gg_rct_SargothLair)
        if whichUnit != null then
            set udg_BossSargoth = whichUnit
            set BossId = Boss_Register(whichUnit, "Sargoth")
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetCombatArea(BossId, gg_rct_SargothLair, Player(0), true)
            call Boss_SetPhaseCount(BossId, 3)
            call Boss_SetDescription(BossId, "Sargoth retreats underground twice, releasing spider waves from the lair.", "Phase 1 above ground; phase 2 at 50%; phase 3 at 25%.", "Burrow calls spiders, giant spiders, spitting spiders, then larger mixed waves.", "Clear spitters and adds while he is buried; use the surface windows for boss damage.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_PHASE, function OnPhase)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
        endif
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set PhaseTimer = CreateTimer()
        set BurrowTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        set SpiderGroup = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
