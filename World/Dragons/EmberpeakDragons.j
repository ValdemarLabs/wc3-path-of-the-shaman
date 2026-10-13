/**
    EmberpeakDragons

    Author: Valdemar
    Version: 1.3.0

    Description:
    Manages the high-altitude dragons in Emberpeak Highlands. The dragons
    wander within their configured areas and occasionally cast Flame Strike
    at nearby player/hostile units or random nearby points in the zone.

    Credits:
    - World/_oldGUI/Dragons/Emberpeak Dragonfire ambient triggers

    How to install:
    Import after DragonBehavior, Table, and CreepRespawn. Keep the five named
    Emberpeak high-altitude dragons and their zone rects. Disable the legacy
    Emberpeak center/zone wander and zone Flame Strike GUI triggers.

    API:
    - EmberpeakDragons_GetCenterGroup() returns group
    - EmberpeakDragons_GetHighlandsGroup() returns group

**/
library EmberpeakDragons initializer Init requires DragonBehavior, Table, CreepRespawn
    globals
        // Configuration
        private constant integer UNIT_HIGH_DRAGON = 'n647'
        private constant real CENTER_WANDER_PERIOD = 3.00
        private constant real HIGHLANDS_WANDER_PERIOD = 7.00
        private constant real CAST_DELAY_MIN = 10.00
        private constant real CAST_DELAY_MAX = 20.00
        private constant real CAST_TARGET_RADIUS = 1200.00
        private constant real RANDOM_CAST_RADIUS = 800.00

        private group CenterGroup = null
        private group HighlandsGroup = null
        private group WorkGroup = null
        private group CastWorkGroup = null
        private timer CenterWanderTimer = null
        private timer HighlandsWanderTimer = null
        private timer CastTimer = null
        private trigger ZoneEnterTrigger = null
        private timer array CastingTimers
        private unit array CastingUnits
        private integer array CastingLegacyIndex
        private Table CastingTimerToSlot = 0
        private Table UnitCasting = 0
        private integer CastingSlotCount = 0
    endglobals

    private function IsAlive takes unit whichUnit returns boolean
        return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD)
    endfunction

    private function FindCastingSlot takes unit dragon returns integer
        local integer slot = 1

        loop
            exitwhen slot > CastingSlotCount
            if CastingUnits[slot] == dragon then
                return slot
            endif
            set slot = slot + 1
        endloop
        if CastingSlotCount >= 8 then
            return 0
        endif
        set CastingSlotCount = CastingSlotCount + 1
        set slot = CastingSlotCount
        set CastingUnits[slot] = dragon
        set CastingTimers[slot] = CreateTimer()
        set CastingTimerToSlot[GetHandleId(CastingTimers[slot])] = slot
        return slot
    endfunction

    private function FinishCasting takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer slot = CastingTimerToSlot[GetHandleId(expiredTimer)]
        local unit dragon = CastingUnits[slot]
        local integer legacyIndex = CastingLegacyIndex[slot]

        if dragon != null then
            call UnitCasting.remove(GetHandleId(dragon))
        endif
        if legacyIndex > 0 then
            set udg_EmberpeakDragonCasting[legacyIndex] = false
        endif
        set CastingLegacyIndex[slot] = 0
        set dragon = null
        set expiredTimer = null
    endfunction

    private function StartCasting takes unit dragon, integer legacyIndex returns nothing
        local integer slot = FindCastingSlot(dragon)

        if slot <= 0 then
            return
        endif
        set UnitCasting[GetHandleId(dragon)] = 1
        set CastingLegacyIndex[slot] = legacyIndex
        if legacyIndex > 0 then
            set udg_EmberpeakDragonCasting[legacyIndex] = true
        endif
        call TimerStart(CastingTimers[slot], 2.00, false, function FinishCasting)
    endfunction

    private function CanWander takes unit dragon returns boolean
        if not IsAlive(dragon) or UnitCasting[GetHandleId(dragon)] == 1 then
            return false
        endif
        if dragon == gg_unit_n647_1904 and udg_EmberpeakDragonCasting[1] then
            return false
        endif
        if dragon == gg_unit_n647_0823 and udg_EmberpeakDragonCasting[2] then
            return false
        endif
        return true
    endfunction

    private function WanderGroup takes group dragonGroup, rect destinationRect, rect audienceRect returns nothing
        local unit dragon = null

        if not DragonBehavior_HasAudience(audienceRect) then
            return
        endif
        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(dragonGroup, WorkGroup)
        loop
            set dragon = FirstOfGroup(WorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(WorkGroup, dragon)
            if CanWander(dragon) then
                if IssuePointOrder(dragon, "move", GetRandomReal(GetRectMinX(destinationRect), GetRectMaxX(destinationRect)), GetRandomReal(GetRectMinY(destinationRect), GetRectMaxY(destinationRect))) then
                    call DragonBehavior_TryPlayAmbientSound(dragon, audienceRect)
                endif
            endif
        endloop
        set dragon = null
    endfunction

    private function CenterWander takes nothing returns nothing
        call WanderGroup(CenterGroup, gg_rct_DragonFireSpam02, gg_rct_DragonFireSpam01)
    endfunction

    private function HighlandsWander takes nothing returns nothing
        call WanderGroup(HighlandsGroup, gg_rct_03EmberpeakHighlands, gg_rct_03EmberpeakHighlands)
    endfunction

    private function TryCastFlameStrike takes unit dragon, integer legacyIndex, integer rollMaximum, integer successRoll returns nothing
        if IsAlive(dragon) and GetRandomInt(1, rollMaximum) == successRoll and DragonBehavior_TryAmbientFlameStrike(dragon, gg_rct_03EmberpeakHighlands, CAST_TARGET_RADIUS, RANDOM_CAST_RADIUS) then
            call StartCasting(dragon, legacyIndex)
            call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_03EmberpeakHighlands)
        endif
    endfunction

    private function RunFlameStrikePass takes nothing returns nothing
        local unit dragon = null

        if not DragonBehavior_HasAudience(gg_rct_03EmberpeakHighlands) then
            return
        endif
        call GroupClear(CastWorkGroup)
        call BlzGroupAddGroupFast(HighlandsGroup, CastWorkGroup)
        loop
            set dragon = FirstOfGroup(CastWorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(CastWorkGroup, dragon)
            call TryCastFlameStrike(dragon, 0, 3, 1)
        endloop
        set dragon = null
    endfunction

    private function CastFlameStrikes takes nothing returns nothing
        call RunFlameStrikePass()
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
    endfunction

    private function OnZoneEnter takes nothing returns nothing
        local unit enteringUnit = GetTriggerUnit()

        if DragonBehavior_IsAudienceHero(enteringUnit) then
            call CenterWander()
            call HighlandsWander()
            call RunFlameStrikePass()
        endif
        set enteringUnit = null
    endfunction

    private function AddHighlandsDragon takes unit dragon returns nothing
        if GetUnitTypeId(dragon) == UNIT_HIGH_DRAGON and not IsUnitInGroup(dragon, CenterGroup) then
            call CreepRespawn_DiscardUnit(dragon)
            call SetUnitInvulnerable(dragon, true)
            call GroupAddUnit(HighlandsGroup, dragon)
        endif
    endfunction

    private function RegisterHighlandsDragon takes nothing returns nothing
        local unit dragon = GetEnumUnit()

        call AddHighlandsDragon(dragon)
        set dragon = null
    endfunction

    public function GetCenterGroup takes nothing returns group
        return CenterGroup
    endfunction

    public function GetHighlandsGroup takes nothing returns group
        return HighlandsGroup
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()

        if udg_EmberpeakDragonsCenter == null then
            set udg_EmberpeakDragonsCenter = CreateGroup()
        endif
        set CenterGroup = udg_EmberpeakDragonsCenter
        call GroupAddUnit(CenterGroup, gg_unit_n647_1904)
        call GroupAddUnit(CenterGroup, gg_unit_n647_0823)
        call CreepRespawn_DiscardUnit(gg_unit_n647_1904)
        call CreepRespawn_DiscardUnit(gg_unit_n647_0823)
        call SetUnitInvulnerable(gg_unit_n647_1904, true)
        call SetUnitInvulnerable(gg_unit_n647_0823, true)
        call AddHighlandsDragon(gg_unit_n647_1938)
        call AddHighlandsDragon(gg_unit_n647_1009)
        call AddHighlandsDragon(gg_unit_n647_0846)
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_03EmberpeakHighlands, null)
        call ForGroup(WorkGroup, function RegisterHighlandsDragon)
        call GroupClear(WorkGroup)
        set ZoneEnterTrigger = CreateTrigger()
        call TriggerRegisterEnterRectSimple(ZoneEnterTrigger, gg_rct_03EmberpeakHighlands)
        call TriggerAddAction(ZoneEnterTrigger, function OnZoneEnter)
        call TimerStart(CenterWanderTimer, CENTER_WANDER_PERIOD, true, function CenterWander)
        call TimerStart(HighlandsWanderTimer, HIGHLANDS_WANDER_PERIOD, true, function HighlandsWander)
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
        call CenterWander()
        call HighlandsWander()
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set HighlandsGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        set CastWorkGroup = CreateGroup()
        set CenterWanderTimer = CreateTimer()
        set HighlandsWanderTimer = CreateTimer()
        set CastTimer = CreateTimer()
        set CastingTimerToSlot = Table.create()
        set UnitCasting = Table.create()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
