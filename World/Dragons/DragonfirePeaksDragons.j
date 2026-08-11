/**
    DragonfirePeaksDragons

    Author: Valdemar
    Version: 1.0.0

    Description:
    Owns the high-altitude dragons in Dragonfire Peaks. Existing preplaced
    dragons are reused first, missing dragons are created up to the configured
    count, and all managed dragons wander and occasionally cast Flame Strike
    at random living units inside the zone.

    Credits:
    - Emberpeak ambient dragon behavior used as the gameplay reference

    How to install:
    Import after DragonBehavior, Table, and CreepRespawn. Keep
    gg_rct_04DragonfirePeaks and the Red Dragon (High Height) object data.

    API:
    - DragonfirePeaksDragons_GetGroup() returns group

**/
library DragonfirePeaksDragons initializer Init requires DragonBehavior, Table, CreepRespawn
    globals
        // Configuration
        private constant integer UNIT_HIGH_DRAGON = 'n647'
        private constant integer WANDERER_COUNT = 3
        private constant real WANDER_PERIOD = 7.00
        private constant real CAST_DELAY_MIN = 10.00
        private constant real CAST_DELAY_MAX = 20.00

        private group DragonGroup = null
        private group WorkGroup = null
        private group CastWorkGroup = null
        private group TargetGroup = null
        private timer WanderTimer = null
        private timer CastTimer = null
        private timer array CastingTimers
        private unit array CastingUnits
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
        if CastingSlotCount >= 16 then
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

        if dragon != null then
            call UnitCasting.remove(GetHandleId(dragon))
        endif
        set dragon = null
        set expiredTimer = null
    endfunction

    private function StartCasting takes unit dragon returns nothing
        local integer slot = FindCastingSlot(dragon)

        if slot <= 0 then
            return
        endif
        set UnitCasting[GetHandleId(dragon)] = 1
        call TimerStart(CastingTimers[slot], 2.00, false, function FinishCasting)
    endfunction

    private function CanWander takes unit dragon returns boolean
        local integer orderId

        if not IsAlive(dragon) or UnitCasting[GetHandleId(dragon)] == 1 then
            return false
        endif
        set orderId = GetUnitCurrentOrder(dragon)
        return orderId != OrderId("flamestrike") and orderId != OrderId("cast") and orderId != OrderId("move")
    endfunction

    private function Wander takes nothing returns nothing
        local unit dragon = null

        call GroupClear(CastWorkGroup)
        call BlzGroupAddGroupFast(DragonGroup, CastWorkGroup)
        loop
            set dragon = FirstOfGroup(CastWorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(CastWorkGroup, dragon)
            if CanWander(dragon) then
                call IssuePointOrder(dragon, "move", GetRandomReal(GetRectMinX(gg_rct_04DragonfirePeaks), GetRectMaxX(gg_rct_04DragonfirePeaks)), GetRandomReal(GetRectMinY(gg_rct_04DragonfirePeaks), GetRectMaxY(gg_rct_04DragonfirePeaks)))
                call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_04DragonfirePeaks)
            endif
        endloop
        set dragon = null
    endfunction

    private function PickRandomZoneTarget takes unit dragon returns unit
        local unit picked = null
        local unit target = null

        call GroupClear(WorkGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_04DragonfirePeaks, null)
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

    private function CastFlameStrikes takes nothing returns nothing
        local unit dragon = null
        local unit target = null

        call GroupClear(CastWorkGroup)
        call BlzGroupAddGroupFast(DragonGroup, CastWorkGroup)
        loop
            set dragon = FirstOfGroup(CastWorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(CastWorkGroup, dragon)
            if IsAlive(dragon) and GetRandomInt(1, 3) == 1 then
                set target = PickRandomZoneTarget(dragon)
                if target != null then
                    call StartCasting(dragon)
                    call IssuePointOrder(dragon, "flamestrike", GetUnitX(target), GetUnitY(target))
                    call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_04DragonfirePeaks)
                endif
            endif
        endloop
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
        set target = null
        set dragon = null
    endfunction

    private function RegisterDragon takes nothing returns nothing
        local unit dragon = GetEnumUnit()

        if GetUnitTypeId(dragon) == UNIT_HIGH_DRAGON then
            call CreepRespawn_DiscardUnit(dragon)
            call SetUnitInvulnerable(dragon, true)
            call GroupAddUnit(DragonGroup, dragon)
        endif
        set dragon = null
    endfunction

    private function EnsureWandererCount takes nothing returns nothing
        local unit dragon = null
        local integer count = BlzGroupGetSize(DragonGroup)

        loop
            exitwhen count >= WANDERER_COUNT
            set dragon = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_HIGH_DRAGON, GetRandomReal(GetRectMinX(gg_rct_04DragonfirePeaks), GetRectMaxX(gg_rct_04DragonfirePeaks)), GetRandomReal(GetRectMinY(gg_rct_04DragonfirePeaks), GetRectMaxY(gg_rct_04DragonfirePeaks)), GetRandomReal(0.00, 360.00))
            if dragon != null then
                call CreepRespawn_DiscardUnit(dragon)
                call SetUnitInvulnerable(dragon, true)
                call GroupAddUnit(DragonGroup, dragon)
            endif
            set dragon = null
            set count = count + 1
        endloop
    endfunction

    public function GetGroup takes nothing returns group
        return DragonGroup
    endfunction

    private function DelayedInit takes nothing returns nothing
        local timer initTimer = GetExpiredTimer()

        call GroupEnumUnitsInRect(WorkGroup, gg_rct_04DragonfirePeaks, null)
        call ForGroup(WorkGroup, function RegisterDragon)
        call GroupClear(WorkGroup)
        call EnsureWandererCount()
        call TimerStart(WanderTimer, WANDER_PERIOD, true, function Wander)
        call TimerStart(CastTimer, GetRandomReal(CAST_DELAY_MIN, CAST_DELAY_MAX), false, function CastFlameStrikes)
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set DragonGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        set CastWorkGroup = CreateGroup()
        set TargetGroup = CreateGroup()
        set WanderTimer = CreateTimer()
        set CastTimer = CreateTimer()
        set CastingTimerToSlot = Table.create()
        set UnitCasting = Table.create()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
