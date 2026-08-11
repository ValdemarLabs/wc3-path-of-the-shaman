/**
    BossFeldok

    Author: Valdemar
    Version: 1.0.0

    Description:
    Implements Deathlord Fel'Dok's two-phase Gnoll Hideout encounter.

    Credits:
    - DungeonsAndBosses/Dungeons/Gnoll Hideout/_oldGUI/Boss Fel'Dok

    How to install:
    Import after Boss, CreepRespawn, and DungeonGnollHideout. Keep the named
    Fel'Dok arena, add-spawn, movement, and attack rects. Disable the legacy
    Fel'Dok GUI triggers.

    API:
    - BossFeldok_GetId() returns integer

**/
library BossFeldok initializer Init requires Boss, CreepRespawn, DungeonGnollHideout
    globals
        private integer BossId = 0
        private timer FightTimer = null
        private timer PhaseTimer = null
        private timer ResumeTimer = null
        private group Adds = null
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

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

    private function Fight takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local group targets = CreateGroup()
        local unit target = null
        local integer roll

        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            call PauseTimer(FightTimer)
        else
            set roll = GetRandomInt(1, 15)
            call GroupEnumUnitsInRect(targets, gg_rct_BossFeldokArea01, null)
            set target = FirstOfGroup(targets)
            if roll == 2 and target != null then
                call IssuePointOrder(boss, "rainoffire", GetUnitX(target), GetUnitY(target))
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

    private function ResumePhase takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)

        if Boss_IsActive(BossId) and IsAlive(boss) then
            call SetUnitInvulnerable(boss, false)
            call SetUnitOwner(boss, Player(11), true)
            call TimerStart(FightTimer, GetRandomReal(10.00, 20.00), true, function Fight)
        endif
        set boss = null
    endfunction

    private function PhaseCheck takes nothing returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit summoned = null
        local integer count = 0
        local real x
        local real y

        if not Boss_IsActive(BossId) or not IsAlive(boss) then
            set boss = null
            return
        endif
        if GetWidgetLife(boss) > GetUnitState(boss, UNIT_STATE_MAX_LIFE) * 0.50 or Boss_GetPhase(BossId) > 1 then
            set boss = null
            return
        endif

        call Boss_SetPhase(BossId, 2)
        call PauseTimer(FightTimer)
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
                call GroupAddUnit(Adds, summoned)
                call IssuePointOrder(summoned, "attack", GetRectCenterX(gg_rct_BossFeldokMobs01Attack), GetRectCenterY(gg_rct_BossFeldokMobs01Attack))
            endif
            set summoned = null
            set count = count + 1
        endloop
        call SetUnitInvulnerable(boss, true)
        call SetUnitOwner(boss, Player(PLAYER_NEUTRAL_PASSIVE), true)
        call IssuePointOrder(boss, "move", GetRectCenterX(gg_rct_BossFeldokPhase2Point), GetRectCenterY(gg_rct_BossFeldokPhase2Point))
        call TimerStart(ResumeTimer, 3.00, false, function ResumePhase)
        set boss = null
    endfunction

    private function OnStart takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call TimerStart(FightTimer, GetRandomReal(10.00, 20.00), true, function Fight)
            call TimerStart(PhaseTimer, 0.20, true, function PhaseCheck)
        endif
    endfunction

    private function OnEnd takes nothing returns nothing
        if Boss_EventBossId == BossId then
            call PauseTimer(FightTimer)
            call PauseTimer(PhaseTimer)
            call PauseTimer(ResumeTimer)
            call ClearAdds()
        endif
    endfunction

    private function OnRespawn takes nothing returns nothing
        set udg_BossFeldok = Boss_GetUnit(BossId)
    endfunction

    public function GetId takes nothing returns integer
        return BossId
    endfunction

    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit boss = Boss_FindUnitByName("Deathlord Fel'Dok", gg_rct_BossFeldokArea01)

        if boss != null then
            set udg_BossFeldok = boss
            set BossId = Boss_Register(boss, "Deathlord Fel'Dok")
            call Boss_SetArena(BossId, gg_rct_BossFeldokArea01, Player(0), true)
            call Boss_SetAutoStartOnAttack(BossId, true)
            call Boss_SetPhaseCount(BossId, 2)
            call Boss_SetDescription(BossId, "An undead deathlord who turns the arena into a feast when wounded.", "At half health he calls a skeleton-and-zombie wave before resuming the fight.", "Rain of Fire, sudden movement, and target switching in phase one; an add wave at 50%.", "Spread for Rain of Fire and clear the add wave before it overwhelms the party.")
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

        set FightTimer = CreateTimer()
        set PhaseTimer = CreateTimer()
        set ResumeTimer = CreateTimer()
        set Adds = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
