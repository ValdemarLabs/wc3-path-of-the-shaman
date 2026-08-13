/**
    EmberpeakDragonfire

    Author: Valdemar
    Version: 2.0.0

    Description:
    Owns only the two Emberpeak dragons that interact with the Colossus fight.
    The dragons target Colossus while idle, target player units during the
    encounter, and turn back on Colossus during the final phase.

    Credits:
    - World/_oldGUI/Dragons/Emberpeak Dragonfire Flame Strike triggers

    How to install:
    Import after DragonBehavior and before BossColossus. Keep the two center
    high-altitude dragon units and gg_rct_DragonFireSpam01. Disable the three
    legacy Colossus/Player Units Flame Strike GUI triggers.

    API:
    - EmberpeakDragonfire_SetBoss(whichUnit)
    - EmberpeakDragonfire_SetMode(mode)

**/
library EmberpeakDragonfire initializer Init requires DragonBehavior
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
        local unit target = null

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
        set target = GroupPickRandomUnit(TargetGroup)
        call GroupClear(TargetGroup)
        set picked = null
        return target
    endfunction

    private function TryCast takes unit dragon, integer dragonIndex, integer successRoll returns nothing
        local unit target = null

        if IsAlive(dragon) and GetRandomInt(1, 2) == successRoll then
            if Mode == EMBERPEAK_DRAGONFIRE_PLAYERS then
                set target = PickPlayerTarget(dragon)
            else
                set target = BossUnit
            endif
            if IsAlive(target) then
                set udg_EmberpeakDragonCasting[dragonIndex] = true
                call IssuePointOrder(dragon, "flamestrike", GetUnitX(target), GetUnitY(target))
                call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_DragonFireSpam01)
                if dragonIndex == 1 then
                    call TimerStart(DragonOneTimer, 2.00, false, function ClearDragonOne)
                else
                    call TimerStart(DragonTwoTimer, 2.00, false, function ClearDragonTwo)
                endif
            endif
        endif
        set target = null
    endfunction

    private function Cast takes nothing returns nothing
        local real nextDelay = GetRandomReal(10.00, 20.00)

        call TryCast(gg_unit_n647_1904, 1, 1)
        call TryCast(gg_unit_n647_0823, 2, 2)
        if Mode == EMBERPEAK_DRAGONFIRE_COLOSSUS then
            set nextDelay = GetRandomReal(6.00, 11.00)
        endif
        if BossUnit != null then
            call TimerStart(CastTimer, nextDelay, false, function Cast)
        endif
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
