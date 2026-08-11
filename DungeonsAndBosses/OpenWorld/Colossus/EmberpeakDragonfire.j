/**
    EmberpeakDragonfire

    Author: Valdemar
    Version: 1.0.0

    Description:
    Replaces the Colossus arena dragonfire GUI triggers. The two center dragons
    can pressure the Colossus before combat, target player forces during phases
    one and two, or focus the Colossus during phase three.

    Credits:
    - Legacy Emberpeak Dragonfire Flame Strike GUI triggers

    How to install:
    Import before BossColossus and retain the two center dragon preplaced units.

    API:
    - call EmberpeakDragonfire_SetBoss(whichUnit)
    - call EmberpeakDragonfire_SetMode(mode)

**/
library EmberpeakDragonfire initializer Init
    globals
        constant integer EMBERPEAK_DRAGONFIRE_IDLE = 0
        constant integer EMBERPEAK_DRAGONFIRE_PLAYERS = 1
        constant integer EMBERPEAK_DRAGONFIRE_COLOSSUS = 2

        private timer CastTimer = null
        private timer DragonOneTimer = null
        private timer DragonTwoTimer = null
        private group SearchGroup = null
        private group TargetGroup = null
        private unit BossUnit = null
        private integer Mode = EMBERPEAK_DRAGONFIRE_IDLE
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function ClearDragonOne takes nothing returns nothing
        set udg_EmberpeakDragonCasting[1] = false
    endfunction

    private function ClearDragonTwo takes nothing returns nothing
        set udg_EmberpeakDragonCasting[2] = false
    endfunction

    private function PickPlayerTarget takes unit dragon returns unit
        local unit picked = null

        call GroupClear(SearchGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRect(SearchGroup, gg_rct_DragonFireSpam01, null)
        loop
            set picked = FirstOfGroup(SearchGroup)
            exitwhen picked == null
            call GroupRemoveUnit(SearchGroup, picked)
            if IsAlive(picked) and IsUnitEnemy(picked, GetOwningPlayer(dragon)) and IsPlayerInForce(GetOwningPlayer(picked), udg_PlayerGroup) then
                call GroupAddUnit(TargetGroup, picked)
            endif
        endloop
        set picked = GroupPickRandomUnit(TargetGroup)
        call GroupClear(TargetGroup)
        return picked
    endfunction

    private function Cast takes nothing returns nothing
        local integer dragonIndex = GetRandomInt(1, 2)
        local unit dragon = null
        local unit target = null

        if dragonIndex == 1 then
            set dragon = gg_unit_n647_1904
        else
            set dragon = gg_unit_n647_0823
        endif
        if not IsAlive(dragon) then
            if Mode == EMBERPEAK_DRAGONFIRE_COLOSSUS then
                call TimerStart(CastTimer, GetRandomReal(6.00, 11.00), false, function Cast)
            else
                call TimerStart(CastTimer, GetRandomReal(10.00, 20.00), false, function Cast)
            endif
            set dragon = null
            return
        endif

        if Mode == EMBERPEAK_DRAGONFIRE_PLAYERS then
            set target = PickPlayerTarget(dragon)
        else
            set target = BossUnit
        endif
        if IsAlive(target) then
            set udg_EmberpeakDragonCasting[dragonIndex] = true
            call IssuePointOrder(dragon, "flamestrike", GetUnitX(target), GetUnitY(target))
            if dragonIndex == 1 then
                call TimerStart(DragonOneTimer, 2.00, false, function ClearDragonOne)
            else
                call TimerStart(DragonTwoTimer, 2.00, false, function ClearDragonTwo)
            endif
        endif
        if Mode == EMBERPEAK_DRAGONFIRE_COLOSSUS then
            call TimerStart(CastTimer, GetRandomReal(6.00, 11.00), false, function Cast)
        else
            call TimerStart(CastTimer, GetRandomReal(10.00, 20.00), false, function Cast)
        endif
        set target = null
        set dragon = null
    endfunction

    public function SetBoss takes unit whichUnit returns nothing
        set BossUnit = whichUnit
    endfunction

    public function SetMode takes integer mode returns nothing
        if mode < EMBERPEAK_DRAGONFIRE_IDLE or mode > EMBERPEAK_DRAGONFIRE_COLOSSUS then
            set mode = EMBERPEAK_DRAGONFIRE_IDLE
        endif
        set Mode = mode
        call PauseTimer(CastTimer)
        if BossUnit != null then
            if Mode == EMBERPEAK_DRAGONFIRE_COLOSSUS then
                call TimerStart(CastTimer, GetRandomReal(6.00, 11.00), false, function Cast)
            else
                call TimerStart(CastTimer, GetRandomReal(10.00, 20.00), false, function Cast)
            endif
        endif
    endfunction

    private function Init takes nothing returns nothing
        set CastTimer = CreateTimer()
        set DragonOneTimer = CreateTimer()
        set DragonTwoTimer = CreateTimer()
        set SearchGroup = CreateGroup()
        set TargetGroup = CreateGroup()
    endfunction
endlibrary
