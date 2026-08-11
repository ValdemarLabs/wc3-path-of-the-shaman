/**
    BossRoljin
    Author: Valdemar
    Version: 1.0.0
    Description:
    Registers Rol'jin and his recovered reinforcement encounter.
    Credits:
    - Legacy Roljin GUI exports.
    How to install:
    Import after Boss and the Bloodtusk map rects.
    API:
    - BossRoljin_GetId()
*/
library BossRoljin initializer Init requires Boss, CreepRespawn
    globals
        private integer BossId = 0
        private timer MoveTimer = null
        private timer SupportTimer = null
        private timer RespawnTimer = null
        private group SupportGroup = null
        private group WorkGroup = null
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405
    endfunction

    private function CountLivingSupports takes nothing returns integer
        local group swapGroup = null
        local unit picked = null
        local integer count = 0

        call GroupClear(WorkGroup)
        loop
            set picked = FirstOfGroup(SupportGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SupportGroup, picked)
            if IsAlive(picked) then
                call GroupAddUnit(WorkGroup, picked)
                set count = count + 1
            endif
        endloop
        set swapGroup = SupportGroup
        set SupportGroup = WorkGroup
        set WorkGroup = swapGroup
        set udg_RoljinGroup = SupportGroup
        set swapGroup = null
        set picked = null
        return count
    endfunction

    private function ClearSupports takes nothing returns nothing
        local unit picked = null

        loop
            set picked = FirstOfGroup(SupportGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SupportGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call KillUnit(picked)
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function CreateSupport takes integer unitTypeId, rect spawnRect returns nothing
        local unit boss = Boss_GetUnit(BossId)
        local unit spawned = null

        if IsAlive(boss) then
            set spawned = CreateUnit(Player(11), unitTypeId, GetRectCenterX(spawnRect), GetRectCenterY(spawnRect), GetRandomReal(0.00, 360.00))
            if spawned != null then
                call CreepRespawn_DiscardUnit(spawned)
                call GroupAddUnit(SupportGroup, spawned)
                call IssueTargetOrder(spawned, "smart", boss)
            endif
        endif
        set spawned = null
        set boss = null
    endfunction

    private function SpawnSupport takes nothing returns nothing
        local integer wave

        if Boss_IsActive(BossId) and CountLivingSupports() <= 6 then
            set wave = GetRandomInt(1, 4)
            if wave == 1 then
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nftt', gg_rct_ForestTrollsSpawn01)
            elseif wave == 2 then
                call CreateSupport('nfsh', gg_rct_ForestTrollsSpawn02)
                call CreateSupport('nfsh', gg_rct_ForestTrollsSpawn02)
            elseif wave == 3 then
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nftb', gg_rct_ForestTrollsSpawn02)
                call CreateSupport('nftb', gg_rct_ForestTrollsSpawn02)
            else
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nfsp', gg_rct_ForestTrollsSpawn01)
                call CreateSupport('nftr', gg_rct_ForestTrollsSpawn02)
                call CreateSupport('nfsp', gg_rct_ForestTrollsSpawn02)
                call CreateSupport('nfsp', gg_rct_ForestTrollsSpawn02)
            endif
        endif
        if Boss_IsActive(BossId) then
            call TimerStart(SupportTimer, GetRandomReal(20.00, 100.00), false, function SpawnSupport)
        endif
    endfunction

    private function MoveRandomly takes nothing returns nothing
        local unit whichUnit = Boss_GetUnit(BossId)
        local integer pick = GetRandomInt(1, 4)
        if Boss_IsActive(BossId) and whichUnit != null then
            if pick == 1 then
                call IssuePointOrder(whichUnit, "move", GetRectCenterX(gg_rct_BossRoljinMove01), GetRectCenterY(gg_rct_BossRoljinMove01))
                call PlaySoundOnUnitBJ(gg_snd_ForestTrollYesAttack1, 100.00, whichUnit)
                call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 2.00, "|cffffcc00Rol'jin:|r Die!")
            elseif pick == 2 then
                call IssuePointOrder(whichUnit, "move", GetRectCenterX(gg_rct_BossRoljinMove02), GetRectCenterY(gg_rct_BossRoljinMove02))
                call PlaySoundOnUnitBJ(gg_snd_ForestTrollYesAttack2, 100.00, whichUnit)
                call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 2.00, "|cffffcc00Rol'jin:|r Argh!")
            elseif pick == 3 then
                call IssuePointOrder(whichUnit, "move", GetRectCenterX(gg_rct_BossRoljinMove03), GetRectCenterY(gg_rct_BossRoljinMove03))
                call PlaySoundOnUnitBJ(gg_snd_ForestTrollYesAttack2, 100.00, whichUnit)
                call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 2.00, "|cffffcc00Rol'jin:|r Argh!")
            else
                call IssuePointOrder(whichUnit, "move", GetRectCenterX(gg_rct_BossRoljinMove04), GetRectCenterY(gg_rct_BossRoljinMove04))
                call PlaySoundOnUnitBJ(gg_snd_ForestTrollYesAttack2, 100.00, whichUnit)
                call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 2.00, "|cffffcc00Rol'jin:|r Argh!")
            endif
            call TimerStart(MoveTimer, GetRandomReal(30.00, 45.00), false, function MoveRandomly)
        endif
        set whichUnit = null
    endfunction
    private function OnStart takes nothing returns nothing
        call TimerStart(MoveTimer, GetRandomReal(30.00, 45.00), false, function MoveRandomly)
        call TimerStart(SupportTimer, GetRandomReal(20.00, 100.00), false, function SpawnSupport)
    endfunction
    private function OnEnd takes nothing returns nothing
        call PauseTimer(MoveTimer)
        call PauseTimer(SupportTimer)
        call ClearSupports()
    endfunction

    private function Respawn takes nothing returns nothing
        local unit boss = Boss_Respawn(BossId)
        if boss != null then
            set udg_Roljin = boss
        endif
        set boss = null
    endfunction

    private function OnDeath takes nothing returns nothing
        call OnEnd()
        call TimerStart(RespawnTimer, GetRandomReal(120.00, 320.00), false, function Respawn)
    endfunction
    public function GetId takes nothing returns integer
        return BossId
    endfunction
    private function Register takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()
        local unit whichUnit = udg_Roljin
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Rol'jin", gg_rct_BloodtuskTribe)
        endif
        if whichUnit == null then
            set whichUnit = Boss_FindUnitByName("Roljin", gg_rct_BloodtuskTribe)
        endif
        if whichUnit == null then
            call TimerStart(initTimer, 1.00, false, function Register)
            set initTimer = null
            return
        endif
        set udg_Roljin = whichUnit
        set BossId = Boss_Register(whichUnit, "Rol'jin")
        call Boss_SetAutoStartOnAttack(BossId, true)
        call Boss_SetArena(BossId, gg_rct_BloodtuskTribe, Player(0), true)
        call Boss_SetDescription(BossId, "The Bloodtusk chieftain calls troll support while roaming his grounds.", "One recovered phase: periodic movement and reinforcements.", "Support packs include trappers, berserkers, high priests, and shadow priests.", "Prioritize healers and keep his escort group under control.")
        call Boss_SetEventCallback(BossId, BOSS_EVENT_START, function OnStart)
        call Boss_SetEventCallback(BossId, BOSS_EVENT_RESET, function OnEnd)
        call Boss_SetEventCallback(BossId, BOSS_EVENT_DEATH, function OnDeath)
        call DestroyTimer(initTimer)
        set initTimer = null
        set whichUnit = null
    endfunction
    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set MoveTimer = CreateTimer()
        set SupportTimer = CreateTimer()
        set RespawnTimer = CreateTimer()
        if udg_RoljinGroup == null then
            set udg_RoljinGroup = CreateGroup()
        endif
        set SupportGroup = udg_RoljinGroup
        set WorkGroup = CreateGroup()
        call TimerStart(initTimer, 0.00, false, function Register)
        set initTimer = null
    endfunction
endlibrary
