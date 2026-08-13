/**
    BossAbomination

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements the Abomination encounter and its zombie reinforcement waves.

    Credits:
    - DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI/Boss Abomination

    How to install:
    Import after Boss, CreepRespawn, and DungeonGnollHideout. Keep the named
    Abomination combat, zombie-spawn, and attack rects. Disable the legacy
    Abomination GUI triggers.

    API:
    - BossAbomination_GetId() returns integer

**/
library BossAbomination initializer Init requires Boss, CreepRespawn, DungeonGnollHideout
    globals
        private integer BossId = 0
        private timer ZombieTimer = null
        private group Adds = null
    endglobals

    private function ClearAdds takes nothing returns nothing
        local unit picked = null

        loop
            set picked = FirstOfGroup(Adds)
            exitwhen picked == null
            call GroupRemoveUnit(Adds, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function SpawnZombies takes nothing returns nothing
        local integer index = 0
        local unit zombie = null
        local rect spawnRect = gg_rct_AbominationZombieSpawn01

        if not Boss_IsActive(BossId) then
            call PauseTimer(ZombieTimer)
            set spawnRect = null
            return
        endif
        loop
            exitwhen index >= 6
            if index == 3 then
                set spawnRect = gg_rct_AbominationZombieSpawn02
            endif
            set zombie = CreateUnit(Player(11), 'nzom', GetRectCenterX(spawnRect), GetRectCenterY(spawnRect), 0.00)
            if zombie != null then
                call CreepRespawn_DiscardUnit(zombie)
                call GroupAddUnit(Adds, zombie)
                call IssuePointOrder(zombie, "attack", GetRandomReal(GetRectMinX(gg_rct_AbominationZombieAttackRegion), GetRectMaxX(gg_rct_AbominationZombieAttackRegion)), GetRandomReal(GetRectMinY(gg_rct_AbominationZombieAttackRegion), GetRectMaxY(gg_rct_AbominationZombieAttackRegion)))
            endif
            set zombie = null
            set index = index + 1
        endloop
        set spawnRect = null
    endfunction

    private function OnStart takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call TimerStart(ZombieTimer, GetRandomReal(30.00, 50.00), true, function SpawnZombies)
        endif
    endfunction

    private function OnEnd takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call PauseTimer(ZombieTimer)
            call ClearAdds()
        endif
    endfunction

    private function OnRespawn takes nothing returns nothing
        set udg_BossAbomination = Boss_GetUnit(BossId)
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit boss = Boss_FindUnitByName("Abomination", gg_rct_AbominationArea)

        if boss != null then
            set udg_BossAbomination = boss
            set BossId = Boss_Register(boss, "Abomination")
            call Boss_SetCombatArea(BossId, gg_rct_AbominationArea, Player(0), true)
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetDescription(BossId, "A lumbering undead brute supported by periodic zombie reinforcements.", "One phase with repeated add waves.", "Six zombies emerge from two spawn points roughly every 30-50 seconds.", "Keep the zombies controlled and defeat them before they can surround the group.")
            call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnEnd)
            call Boss_SetEventCallback(BossId, BOSS_EVENT_RESPAWN, function OnRespawn)
            call Dungeon_RegisterBoss(DungeonGnollHideout_GetDungeonId(), BossId)
        endif
        call DestroyTimer(initTimer)
        set boss = null
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set ZombieTimer = CreateTimer()
        set Adds = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
