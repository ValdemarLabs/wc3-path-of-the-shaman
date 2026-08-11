/**
    DungeonGnollHideout

    Author: Valdemar
    Version: 1.0.0

    Description:
    Migrates the recoverable Gnoll Hideout GUI boss encounters into the shared
    Dungeon and Boss systems. Preplaced bosses are found by their editor names
    after map initialization; all ordinary dungeon creeps are registered for
    the dungeon respawn policy.

    Credits:
    - DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI

    How to install:
    Import after Dungeon and Boss. Keep the referenced editor rects and boss
    unit names. Disable the corresponding legacy GUI triggers.

    API:
    - DungeonGnollHideout_GetDungeonId() returns integer

**/
library DungeonGnollHideout initializer Init requires Dungeon, Boss, CreepRespawn
    globals
        private constant integer ZONE_ID = 101
        private constant real FULL_RESPAWN_DELAY = 300.00
        private constant real RANDOM_RESPAWN_PERCENT = 35.00

        private integer DungeonId = 0
        private integer ImpalerId = 0
        private integer FeldokId = 0
        private integer AbominationId = 0
        private timer ImpalerTimer = null
        private timer FeldokTimer = null
        private timer FeldokPhaseTimer = null
        private timer FeldokResumeTimer = null
        private timer AbominationTimer = null
        private group FeldokAdds = null
        private group AbominationAdds = null
        private real ImpalerBaseArmor = 0.00
        private integer ImpalerBaseDamage = 0
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function StopTimer takes timer whichTimer returns nothing
        if whichTimer != null then
            call PauseTimer(whichTimer)
        endif
    endfunction

    private function ClearAdds takes group addGroup returns nothing
        local unit picked = null
        loop
            set picked = FirstOfGroup(addGroup)
            exitwhen picked == null
            call GroupRemoveUnit(addGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function ImpalerFight takes nothing returns nothing
        local unit boss = Boss_GetUnit(ImpalerId)
        local effect fx = null

        if not Boss_IsActive(ImpalerId) or not IsAlive(boss) then
            call StopTimer(ImpalerTimer)
        else
            call BlzSetUnitArmor(boss, BlzGetUnitArmor(boss) + 1.00)
            call BlzSetUnitBaseDamage(boss, BlzGetUnitBaseDamage(boss, 0) + 3, 0)
            call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 1.00, "Impaler: Me strong!")
            set fx = AddSpecialEffectTarget("Abilities\\Spells\\NightElf\\FaerieDragonInvis\\FaerieDragon_Invis.mdl", boss, "overhead")
            call DestroyEffect(fx)
        endif
        set fx = null
        set boss = null
    endfunction

    private function StartImpalerFight takes nothing returns nothing
        if Boss_EventBossId == ImpalerId then
            call TimerStart(ImpalerTimer, 15.00, true, function ImpalerFight)
        endif
    endfunction

    private function StopImpalerFight takes nothing returns nothing
        local unit boss = Boss_GetUnit(ImpalerId)
        if Boss_EventBossId == ImpalerId then
            call StopTimer(ImpalerTimer)
            if Boss_EventType == BOSS_EVENT_RESET and boss != null then
                call BlzSetUnitArmor(boss, ImpalerBaseArmor)
                call BlzSetUnitBaseDamage(boss, ImpalerBaseDamage, 0)
            endif
        endif
        set boss = null
    endfunction

    private function FeldokFight takes nothing returns nothing
        local unit boss = Boss_GetUnit(FeldokId)
        local group targets = CreateGroup()
        local unit target = null
        local integer roll
        local real x
        local real y

        if not Boss_IsActive(FeldokId) or not IsAlive(boss) then
            call StopTimer(FeldokTimer)
        else
            set roll = GetRandomInt(1, 15)
            call GroupEnumUnitsInRect(targets, gg_rct_BossFeldokArea01, null)
            set target = FirstOfGroup(targets)
            if roll == 2 and target != null then
                set x = GetUnitX(target)
                set y = GetUnitY(target)
                call IssuePointOrder(boss, "rainoffire", x, y)
            elseif roll == 5 then
                call SetUnitMoveSpeed(boss, 666.00)
                call IssuePointOrder(boss, "move", GetUnitX(boss) + 400.00, GetUnitY(boss) + 400.00)
                call SetUnitMoveSpeed(boss, 270.00)
            elseif (roll == 7 or roll == 8 or roll == 10 or roll == 15) and target != null then
                call IssueTargetOrder(boss, "attack", target)
            endif
        endif
        call DestroyGroup(targets)
        set target = null
        set targets = null
        set boss = null
    endfunction

    private function ResumeFeldokPhase takes nothing returns nothing
        local unit boss = Boss_GetUnit(FeldokId)
        if Boss_IsActive(FeldokId) and IsAlive(boss) then
            call SetUnitInvulnerable(boss, false)
            call SetUnitOwner(boss, Player(11), true)
            call TimerStart(FeldokTimer, GetRandomReal(10.00, 20.00), true, function FeldokFight)
        endif
        set boss = null
    endfunction

    private function FeldokPhaseCheck takes nothing returns nothing
        local unit boss = Boss_GetUnit(FeldokId)
        local integer count = 0
        local unit summoned = null
        local real x
        local real y

        if not Boss_IsActive(FeldokId) or not IsAlive(boss) then
            set boss = null
            return
        endif
        if GetWidgetLife(boss) > GetUnitState(boss, UNIT_STATE_MAX_LIFE) * 0.50 or Boss_GetPhase(FeldokId) > 1 then
            set boss = null
            return
        endif
        call Boss_SetPhase(FeldokId, 2)
        call StopTimer(FeldokTimer)
        loop
            exitwhen count >= 19
            set x = GetRandomReal(GetRectMinX(gg_rct_BossFeldokMobs01), GetRectMaxX(gg_rct_BossFeldokMobs01))
            set y = GetRandomReal(GetRectMinY(gg_rct_BossFeldokMobs01), GetRectMaxY(gg_rct_BossFeldokMobs01))
            if count < 11 then
                set summoned = CreateUnit(Player(11), 'u603', x, y, 0.00)
            else
                set summoned = CreateUnit(Player(11), 'nzom', x, y, 0.00)
            endif
            if summoned != null then
                call CreepRespawn_DiscardUnit(summoned)
                call GroupAddUnit(FeldokAdds, summoned)
                call IssuePointOrder(summoned, "attack", GetRectCenterX(gg_rct_BossFeldokMobs01Attack), GetRectCenterY(gg_rct_BossFeldokMobs01Attack))
            endif
            set summoned = null
            set count = count + 1
        endloop
        call SetUnitInvulnerable(boss, true)
        call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), true)
        call IssuePointOrder(boss, "move", GetRectCenterX(gg_rct_BossFeldokPhase2Point), GetRectCenterY(gg_rct_BossFeldokPhase2Point))
        call TimerStart(FeldokResumeTimer, 3.00, false, function ResumeFeldokPhase)
        set boss = null
    endfunction

    private function StartFeldokFight takes nothing returns nothing
        if Boss_EventBossId == FeldokId then
            call TimerStart(FeldokTimer, GetRandomReal(10.00, 20.00), true, function FeldokFight)
            call TimerStart(FeldokPhaseTimer, 0.20, true, function FeldokPhaseCheck)
        endif
    endfunction

    private function StopFeldokFight takes nothing returns nothing
        if Boss_EventBossId == FeldokId then
            call StopTimer(FeldokTimer)
            call StopTimer(FeldokPhaseTimer)
            call StopTimer(FeldokResumeTimer)
            call ClearAdds(FeldokAdds)
        endif
    endfunction

    private function AbominationZombies takes nothing returns nothing
        local integer index = 0
        local unit zombie = null
        local rect spawnRect = gg_rct_AbominationZombieSpawn01
        local real x
        local real y

        if not Boss_IsActive(AbominationId) then
            call StopTimer(AbominationTimer)
            set spawnRect = null
            return
        endif
        loop
            exitwhen index >= 6
            if index == 3 then
                set spawnRect = gg_rct_AbominationZombieSpawn02
            endif
            set x = GetRectCenterX(spawnRect)
            set y = GetRectCenterY(spawnRect)
            set zombie = CreateUnit(Player(11), 'nzom', x, y, 0.00)
            if zombie != null then
                call CreepRespawn_DiscardUnit(zombie)
                call GroupAddUnit(AbominationAdds, zombie)
                call IssuePointOrder(zombie, "attack", GetRandomReal(GetRectMinX(gg_rct_AbominationZombieAttackRegion), GetRectMaxX(gg_rct_AbominationZombieAttackRegion)), GetRandomReal(GetRectMinY(gg_rct_AbominationZombieAttackRegion), GetRectMaxY(gg_rct_AbominationZombieAttackRegion)))
            endif
            set zombie = null
            set index = index + 1
        endloop
        set spawnRect = null
    endfunction

    private function StartAbominationFight takes nothing returns nothing
        if Boss_EventBossId == AbominationId then
            call TimerStart(AbominationTimer, GetRandomReal(30.00, 50.00), true, function AbominationZombies)
        endif
    endfunction

    private function StopAbominationFight takes nothing returns nothing
        if Boss_EventBossId == AbominationId then
            call StopTimer(AbominationTimer)
            call ClearAdds(AbominationAdds)
        endif
    endfunction

    private function OnImpalerRespawn takes nothing returns nothing
        set udg_BossImpaler = Boss_GetUnit(ImpalerId)
    endfunction

    private function OnFeldokRespawn takes nothing returns nothing
        set udg_BossFeldok = Boss_GetUnit(FeldokId)
    endfunction

    private function OnAbominationRespawn takes nothing returns nothing
        set udg_BossAbomination = Boss_GetUnit(AbominationId)
    endfunction

    private function RegisterBosses takes nothing returns nothing
        local unit boss = null

        set boss = Boss_FindUnitByName("Impaler", gg_rct_BossImpalerArea)
        if boss != null then
            set udg_BossImpaler = boss
            set ImpalerId = Boss_Register(boss, "Impaler")
            set ImpalerBaseArmor = BlzGetUnitArmor(boss)
            set ImpalerBaseDamage = BlzGetUnitBaseDamage(boss, 0)
            call Boss_SetArena(ImpalerId, gg_rct_BossImpalerArea, Player(0), true)
            call Boss_SetAutoStartOnAttack(ImpalerId, true)
            call Boss_SetDescription(ImpalerId, "A brutal gnoll champion who steadily hardens during a prolonged fight.", "One escalating phase.", "Every 15 seconds he gains armor and base damage.", "Finish the fight quickly; his scaling makes long engagements increasingly dangerous.")
            call Boss_SetEventCallback(ImpalerId, BOSS_EVENT_START, function StartImpalerFight)
            call Boss_SetEventCallback(ImpalerId, BOSS_EVENT_RESET, function StopImpalerFight)
            call Boss_SetEventCallback(ImpalerId, BOSS_EVENT_DEATH, function StopImpalerFight)
            call Boss_SetEventCallback(ImpalerId, BOSS_EVENT_RESPAWN, function OnImpalerRespawn)
            call Dungeon_RegisterBoss(DungeonId, ImpalerId)
        endif
        set boss = Boss_FindUnitByName("Deathlord Fel'Dok", gg_rct_BossFeldokArea01)
        if boss != null then
            set udg_BossFeldok = boss
            set FeldokId = Boss_Register(boss, "Deathlord Fel'Dok")
            call Boss_SetArena(FeldokId, gg_rct_BossFeldokArea01, Player(0), true)
            call Boss_SetAutoStartOnAttack(FeldokId, true)
            call Boss_SetPhaseCount(FeldokId, 2)
            call Boss_SetDescription(FeldokId, "An undead deathlord who turns the arena into a feast when wounded.", "At half health he calls a skeleton-and-zombie wave before resuming the fight.", "Rain of Fire, sudden movement, and target switching in phase one; an add wave at 50%.", "Spread for Rain of Fire and clear the add wave before it overwhelms the party.")
            call Boss_SetEventCallback(FeldokId, BOSS_EVENT_START, function StartFeldokFight)
            call Boss_SetEventCallback(FeldokId, BOSS_EVENT_RESET, function StopFeldokFight)
            call Boss_SetEventCallback(FeldokId, BOSS_EVENT_DEATH, function StopFeldokFight)
            call Boss_SetEventCallback(FeldokId, BOSS_EVENT_RESPAWN, function OnFeldokRespawn)
            call Dungeon_RegisterBoss(DungeonId, FeldokId)
        endif
        set boss = Boss_FindUnitByName("Abomination", gg_rct_AbominationArea)
        if boss != null then
            set udg_BossAbomination = boss
            set AbominationId = Boss_Register(boss, "Abomination")
            call Boss_SetArena(AbominationId, gg_rct_AbominationArea, Player(0), true)
            call Boss_SetAutoStartOnAttack(AbominationId, true)
            call Boss_SetDescription(AbominationId, "A lumbering undead brute supported by periodic zombie reinforcements.", "One phase with repeated add waves.", "Six zombies emerge from two spawn points roughly every 30-50 seconds.", "Keep the zombies controlled and defeat them before they can surround the group.")
            call Boss_SetEventCallback(AbominationId, BOSS_EVENT_START, function StartAbominationFight)
            call Boss_SetEventCallback(AbominationId, BOSS_EVENT_RESET, function StopAbominationFight)
            call Boss_SetEventCallback(AbominationId, BOSS_EVENT_DEATH, function StopAbominationFight)
            call Boss_SetEventCallback(AbominationId, BOSS_EVENT_RESPAWN, function OnAbominationRespawn)
            call Dungeon_RegisterBoss(DungeonId, AbominationId)
        endif
        set boss = null
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer whichTimer = GetExpiredTimer()

        set DungeonId = Dungeon_Register(ZONE_ID, gg_rct_EnteringDungeon01, gg_rct_Dungeon01StartingPoint, FULL_RESPAWN_DELAY)
        call RegisterBosses()
        call Dungeon_RegisterZoneCreeps(DungeonId, RANDOM_RESPAWN_PERCENT, 120.00, 320.00)
        call DestroyTimer(whichTimer)
        set whichTimer = null
    endfunction

    public function GetDungeonId takes nothing returns integer
        return DungeonId
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set ImpalerTimer = CreateTimer()
        set FeldokTimer = CreateTimer()
        set FeldokPhaseTimer = CreateTimer()
        set FeldokResumeTimer = CreateTimer()
        set AbominationTimer = CreateTimer()
        set FeldokAdds = CreateGroup()
        set AbominationAdds = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
