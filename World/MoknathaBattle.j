/**
    MoknathaBattle

    Author: Valdemar
    Version: 1.0.0

    Description:
    Runs the recurring Mok'natha skirmish between orc and ogre forces and
    creates the permanent crater ubersplats used by the battlefield.

    Credits:
    - World/_oldGUI/Sirensong Moknatha Battle

    How to install:
    Import this library, keep MoknathaBattleRegion01 through 05 and
    MoknathaCrater01 through 07, then disable the two legacy GUI triggers.

    API:
    - MoknathaBattle_Start()
    - MoknathaBattle_Stop(removeUnits)
    - MoknathaBattle_RunCycle()
    - MoknathaBattle_GetOrcGroup()
    - MoknathaBattle_GetOgreGroup()
    - MoknathaBattle_SetCratersVisible(visible)

**/
library MoknathaBattle initializer Init
    globals
        // Configuration
        private constant integer ORC_OWNER_ID = 1
        private constant integer OGRE_OWNER_ID = 11
        private constant integer UNIT_ORC_GRUNT = 'ogru'
        private constant integer UNIT_OGRE_WARRIOR = 'n01P'
        private constant integer ORC_COUNT_MIN = 2
        private constant integer ORC_COUNT_MAX = 3
        private constant integer OGRE_COUNT_MIN = 1
        private constant integer OGRE_COUNT_MAX = 2
        private constant real BATTLE_PERIOD = 120.00
        private constant real CRATER_CREATE_DELAY = 5.00
        private constant string CRATER_UBERSPLAT = "HCRT"

        private group OrcUnits = null
        private group OgreUnits = null
        private group WorkGroup = null
        private timer BattleTimer = null
        private timer CraterTimer = null
        private ubersplat array Craters
        private boolean Enabled = true
        private boolean CratersCreated = false
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function CountLiving takes group whichGroup returns integer
        local unit picked = null
        local integer count = 0

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(whichGroup, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) then
                set count = count + 1
            else
                call GroupRemoveUnit(whichGroup, picked)
            endif
        endloop
        set picked = null
        return count
    endfunction

    private function RemoveTrackedUnits takes group whichGroup returns nothing
        local unit picked = null

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(whichGroup, WorkGroup)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            call GroupRemoveUnit(whichGroup, picked)
            if GetUnitTypeId(picked) != 0 then
                call RemoveUnit(picked)
            endif
        endloop
        set picked = null
    endfunction

    private function SpawnAttackers takes group whichGroup, player owner, integer unitTypeId, integer count, rect spawnRect, rect targetRect returns nothing
        local unit spawned = null
        local integer index = 0

        loop
            exitwhen index >= count
            set spawned = CreateUnit(owner, unitTypeId, GetRandomReal(GetRectMinX(spawnRect), GetRectMaxX(spawnRect)), GetRandomReal(GetRectMinY(spawnRect), GetRectMaxY(spawnRect)), GetRandomReal(0.00, 360.00))
            if spawned != null then
                call GroupAddUnit(whichGroup, spawned)
                call IssuePointOrder(spawned, "attack", GetRandomReal(GetRectMinX(targetRect), GetRectMaxX(targetRect)), GetRandomReal(GetRectMinY(targetRect), GetRectMaxY(targetRect)))
            endif
            set index = index + 1
        endloop
        set spawned = null
    endfunction

    private function SpawnOrcs takes nothing returns nothing
        local player owner = Player(ORC_OWNER_ID)

        call SpawnAttackers(OrcUnits, owner, UNIT_ORC_GRUNT, GetRandomInt(ORC_COUNT_MIN, ORC_COUNT_MAX), gg_rct_MoknathaBattleRegion01, gg_rct_MoknathaBattleRegion03)
        call SpawnAttackers(OrcUnits, owner, UNIT_ORC_GRUNT, GetRandomInt(ORC_COUNT_MIN, ORC_COUNT_MAX), gg_rct_MoknathaBattleRegion02, gg_rct_MoknathaBattleRegion03)
        set owner = null
    endfunction

    private function SpawnOgres takes nothing returns nothing
        local player owner = Player(OGRE_OWNER_ID)
        local rect firstTarget = gg_rct_MoknathaBattleRegion01
        local rect secondTarget = gg_rct_MoknathaBattleRegion02

        if GetRandomInt(0, 1) == 1 then
            set firstTarget = gg_rct_MoknathaBattleRegion02
            set secondTarget = gg_rct_MoknathaBattleRegion01
        endif
        call SpawnAttackers(OgreUnits, owner, UNIT_OGRE_WARRIOR, GetRandomInt(OGRE_COUNT_MIN, OGRE_COUNT_MAX), gg_rct_MoknathaBattleRegion04, firstTarget)
        call SpawnAttackers(OgreUnits, owner, UNIT_OGRE_WARRIOR, GetRandomInt(OGRE_COUNT_MIN, OGRE_COUNT_MAX), gg_rct_MoknathaBattleRegion05, secondTarget)
        set firstTarget = null
        set secondTarget = null
        set owner = null
    endfunction

    private function RunCycleInternal takes nothing returns nothing
        if CountLiving(OrcUnits) == 0 then
            call SpawnOrcs()
        endif
        if CountLiving(OgreUnits) == 0 then
            call SpawnOgres()
        endif
    endfunction

    private function CreateCrater takes integer index, rect craterRect returns nothing
        set Craters[index] = CreateUbersplat(GetRectCenterX(craterRect), GetRectCenterY(craterRect), CRATER_UBERSPLAT, 255, 255, 255, 255, true, false)
        call SetUbersplatRenderAlways(Craters[index], true)
        call ShowUbersplat(Craters[index], true)
    endfunction

    private function CreateCraters takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        if not CratersCreated then
            call CreateCrater(1, gg_rct_MoknathaCrater01)
            call CreateCrater(2, gg_rct_MoknathaCrater02)
            call CreateCrater(3, gg_rct_MoknathaCrater03)
            call CreateCrater(4, gg_rct_MoknathaCrater04)
            call CreateCrater(5, gg_rct_MoknathaCrater05)
            call CreateCrater(6, gg_rct_MoknathaCrater06)
            call CreateCrater(7, gg_rct_MoknathaCrater07)
            set CratersCreated = true
        endif
        call PauseTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function OnBattlePeriod takes nothing returns nothing
        if Enabled and not udg_InCinematic then
            call RunCycleInternal()
        endif
    endfunction

    public function Start takes nothing returns nothing
        if not Enabled then
            set Enabled = true
        endif
        call TimerStart(BattleTimer, BATTLE_PERIOD, true, function OnBattlePeriod)
    endfunction

    public function Stop takes boolean removeUnits returns nothing
        set Enabled = false
        call PauseTimer(BattleTimer)
        if removeUnits then
            call RemoveTrackedUnits(OrcUnits)
            call RemoveTrackedUnits(OgreUnits)
        endif
    endfunction

    public function RunCycle takes nothing returns nothing
        if Enabled and not udg_InCinematic then
            call RunCycleInternal()
        endif
    endfunction

    public function GetOrcGroup takes nothing returns group
        return OrcUnits
    endfunction

    public function GetOgreGroup takes nothing returns group
        return OgreUnits
    endfunction

    public function SetCratersVisible takes boolean visible returns nothing
        local integer index = 1

        loop
            exitwhen index > 7
            if Craters[index] != null then
                call ShowUbersplat(Craters[index], visible)
            endif
            set index = index + 1
        endloop
    endfunction

    private function Init takes nothing returns nothing
        if udg_MoknathaBattle_Orcs == null then
            set udg_MoknathaBattle_Orcs = CreateGroup()
        endif
        if udg_MoknathaBattle_Ogres == null then
            set udg_MoknathaBattle_Ogres = CreateGroup()
        endif
        set OrcUnits = udg_MoknathaBattle_Orcs
        set OgreUnits = udg_MoknathaBattle_Ogres
        set WorkGroup = CreateGroup()
        set BattleTimer = CreateTimer()
        set CraterTimer = CreateTimer()
        call TimerStart(BattleTimer, BATTLE_PERIOD, true, function OnBattlePeriod)
        call TimerStart(CraterTimer, CRATER_CREATE_DELAY, false, function CreateCraters)
    endfunction
endlibrary
