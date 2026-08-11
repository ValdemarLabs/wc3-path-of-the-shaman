/**
    BossMadBlix

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements Mad Blix's only recoverable exported combat mechanic.

    Credits:
    - DungeonsAndBosses/Dungeons/Boom Brothers Mine/_oldGUI/Boss Mad Blix

    How to install:
    Import after Boss and DungeonBoomBrothersMine. Keep the Mad Blix unit name
    and BoomBrothersMine arena rect. Disable the legacy Mad Blix GUI triggers.

    API:
    - BossMadBlix_GetId() returns integer

**/
library BossMadBlix initializer Init requires Boss, DungeonBoomBrothersMine
    globals
        private integer BossId = 0
        private timer ChargeTimer = null
        private group TargetGroup = null
    endglobals

    private function Charge takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit target = null

        if Boss_IsActive(BossId) and boss != null then
            call GroupEnumUnitsInRange(TargetGroup, GetUnitX(boss), GetUnitY(boss), 700.00, null)
            loop
                set target = FirstOfGroup(TargetGroup)
                exitwhen target == null or IsUnitEnemy(target, GetOwningPlayer(boss))
                call GroupRemoveUnit(TargetGroup, target)
            endloop
            if target != null and IsUnitEnemy(target, GetOwningPlayer(boss)) then
                call IssueTargetOrder(boss, "absorbmana", target)
            endif
            call GroupClear(TargetGroup)
            call TimerStart(ChargeTimer, GetRandomReal(15.00, 30.00), false, function Charge)
        endif
        set target = null
        set boss = null
    endfunction

    private function OnStart takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call TimerStart(ChargeTimer, GetRandomReal(15.00, 30.00), false, function Charge)
        endif
    endfunction

    private function OnEnd takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call PauseTimer(ChargeTimer)
            call GroupClear(TargetGroup)
        endif
    endfunction

    private function OnRespawn takes nothing returns nothing
        set udg_BossMadBlix = Boss_GetUnit(BossId)
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit boss = Boss_FindUnitByName("Mad Blix", gg_rct_BoomBrothersMine)

        if boss != null then
            set udg_BossMadBlix = boss
            set BossId = Boss_Register(boss, "Mad Blix")
            call Boss_SetArena(BossId, gg_rct_BoomBrothersMine, Player(0), true)
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetDescription(BossId, "A goblin overseer whose only recoverable exported mechanic is mana absorption.", "The legacy phase files are empty, so no phase transition is reconstructed.", "Every 15-30 seconds he targets a nearby enemy with Absorb Mana.", "Keep mana available for key responses and interrupt or pressure him when he begins the drain.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESPAWN, function OnRespawn)
            call Dungeon_RegisterBoss(DungeonBoomBrothersMine_GetDungeonId(), BossId)
        endif
        call DestroyTimer(initTimer)
        set boss = null
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set ChargeTimer = CreateTimer()
        set TargetGroup = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
