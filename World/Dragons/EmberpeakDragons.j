/**
    EmberpeakDragons

    Author: Valdemar
    Version: 1.1.0

    Description:
    Manages the high-altitude dragons in Emberpeak Highlands. The dragons
    wander within their configured areas and occasionally cast Flame Strike
    at random living units in the Emberpeak zone.

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

        private group CenterGroup = null
        private group HighlandsGroup = null
        private group WorkGroup = null
        private group TargetGroup = null
        private timer CenterWanderTimer = null
        private timer HighlandsWanderTimer = null
        private timer CastTimer = null
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
        local integer orderId

        if not IsAlive(dragon) or UnitCasting[GetHandleId(dragon)] == 1 then
            return false
        endif
        if dragon == gg_unit_n647_1904 and udg_EmberpeakDragonCasting[1] then
            return false
        endif
        if dragon == gg_unit_n647_0823 and udg_EmberpeakDragonCasting[2] then
            return false
        endif
        set orderId = GetUnitCurrentOrder(dragon)
        return orderId != OrderId("flamestrike") and orderId != OrderId("cast") and orderId != OrderId("move")
    endfunction

    private function WanderGroup takes group dragonGroup, rect destinationRect, rect audienceRect returns nothing
        local unit dragon = null

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(dragonGroup, WorkGroup)
        loop
            set dragon = FirstOfGroup(WorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(WorkGroup, dragon)
            if CanWander(dragon) then
                call IssuePointOrder(dragon, "move", GetRandomReal(GetRectMinX(destinationRect), GetRectMaxX(destinationRect)), GetRandomReal(GetRectMinY(destinationRect), GetRectMaxY(destinationRect)))
                call DragonBehavior_TryPlayAmbientSound(dragon, audienceRect)
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

    private function PickRandomZoneTarget takes unit dragon returns unit
        local unit picked = null
        local unit target = null

        call GroupClear(WorkGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_03EmberpeakHighlands, null)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if picked != dragon and IsAlive(picked) and GetUnitTypeId(picked) != UNIT_HIGH_DRAGON and GetUnitAbilityLevel(picked, 'Aloc') == 0 then
                call GroupAddUnit(TargetGroup, picked)
            endif
        endloop
        set target = GroupPickRandomUnit(TargetGroup)
        call GroupClear(TargetGroup)
        set picked = null
        return target
    endfunction

    private function TryCastFlameStrike takes unit dragon, integer legacyIndex, integer rollMaximum, integer successRoll returns nothing
        local unit target = null

        if IsAlive(dragon) and GetRandomInt(1, rollMaximum) == successRoll then
            set target = PickRandomZoneTarget(dragon)
            if target != null then
                call StartCasting(dragon, legacyIndex)
                call IssuePointOrder(dragon, "flamestrike", GetUnitX(target), GetUnitY(target))
                call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_03EmberpeakHighlands)
            endif
        endif
        set target = null
    endfunction

    private function CastFlameStrikes takes nothing returns nothing
        call TryCastFlameStrike(gg_unit_n647_1938, 3, 2, 1)
        call TryCastFlameStrike(gg_unit_n647_1009, 4, 2, 2)
        call TryCastFlameStrike(gg_unit_n647_0846, 5, 3, 3)
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
    endfunction

    private function RegisterHighlandsDragon takes nothing returns nothing
        local unit dragon = GetEnumUnit()

        if GetUnitTypeId(dragon) == UNIT_HIGH_DRAGON and not IsUnitInGroup(dragon, CenterGroup) then
            call CreepRespawn_DiscardUnit(dragon)
            call SetUnitInvulnerable(dragon, true)
            call GroupAddUnit(HighlandsGroup, dragon)
        endif
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
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_03EmberpeakHighlands, null)
        call ForGroup(WorkGroup, function RegisterHighlandsDragon)
        call GroupClear(WorkGroup)
        call TimerStart(CenterWanderTimer, CENTER_WANDER_PERIOD, true, function CenterWander)
        call TimerStart(HighlandsWanderTimer, HIGHLANDS_WANDER_PERIOD, true, function HighlandsWander)
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set HighlandsGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        set TargetGroup = CreateGroup()
        set CenterWanderTimer = CreateTimer()
        set HighlandsWanderTimer = CreateTimer()
        set CastTimer = CreateTimer()
        set CastingTimerToSlot = Table.create()
        set UnitCasting = Table.create()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
