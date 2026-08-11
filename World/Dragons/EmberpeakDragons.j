/**
    EmberpeakDragons

    Author: Valdemar
    Version: 1.0.0

    Description:
    Owns Emberpeak's high-altitude dragon activity: center and zone wandering,
    ambient flame strikes, Dragonfire Peaks wanderers, sounds, and the arena
    targeting modes used by Colossus.

    Credits:
    - World/_oldGUI/Dragons/Emberpeak Dragonfire triggers

    How to install:
    Import after DragonBehavior, Table, and CreepRespawn. Keep the five named
    high-altitude dragon units and the Emberpeak/Dragonfire rects. Disable the
    legacy Emberpeak Dragonfire GUI triggers.

    API:
    - EmberpeakDragons_SetColossus(whichUnit)
    - EmberpeakDragons_SetArenaMode(mode)
    - EmberpeakDragons_GetDragonfirePeaksGroup() returns group

**/
library EmberpeakDragons initializer Init requires DragonBehavior, Table, CreepRespawn
    globals
        constant integer EMBERPEAK_DRAGONS_ARENA_IDLE = 0
        constant integer EMBERPEAK_DRAGONS_ARENA_PLAYERS = 1
        constant integer EMBERPEAK_DRAGONS_ARENA_COLOSSUS = 2

        private constant integer UNIT_HIGH_DRAGON = 'n647'
        private constant integer DRAGONFIRE_PEAKS_WANDERER_COUNT = 3

        private unit Colossus = null
        private integer ArenaMode = EMBERPEAK_DRAGONS_ARENA_IDLE
        private group CenterGroup = null
        private group HighlandsGroup = null
        private group DragonfirePeaksGroup = null
        private group WorkGroup = null
        private group TargetGroup = null
        private timer CenterWanderTimer = null
        private timer ZoneWanderTimer = null
        private timer ZoneCastTimer = null
        private timer ArenaCastTimer = null
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
        set orderId = GetUnitCurrentOrder(dragon)
        return orderId != OrderId("flamestrike") and orderId != OrderId("cast") and orderId != OrderId("move")
    endfunction

    private function WanderGroup takes group dragonGroup, rect destinationRect, rect audienceRect returns nothing
        local unit dragon = null
        local real x
        local real y

        call GroupClear(WorkGroup)
        call BlzGroupAddGroupFast(dragonGroup, WorkGroup)
        loop
            set dragon = FirstOfGroup(WorkGroup)
            exitwhen dragon == null
            call GroupRemoveUnit(WorkGroup, dragon)
            if CanWander(dragon) then
                set x = GetRandomReal(GetRectMinX(destinationRect), GetRectMaxX(destinationRect))
                set y = GetRandomReal(GetRectMinY(destinationRect), GetRectMaxY(destinationRect))
                call IssuePointOrder(dragon, "move", x, y)
                call DragonBehavior_TryPlayAmbientSound(dragon, audienceRect)
            endif
        endloop
        set dragon = null
    endfunction

    private function CenterWander takes nothing returns nothing
        call WanderGroup(CenterGroup, gg_rct_DragonFireSpam02, gg_rct_DragonFireSpam01)
    endfunction

    private function ZoneWander takes nothing returns nothing
        call WanderGroup(HighlandsGroup, gg_rct_03EmberpeakHighlands, gg_rct_03EmberpeakHighlands)
        call WanderGroup(DragonfirePeaksGroup, gg_rct_04DragonfirePeaks, gg_rct_04DragonfirePeaks)
    endfunction

    private function TryCastHighlandsFlame takes unit dragon, integer legacyIndex, integer rollMaximum, integer successRoll returns nothing
        if IsAlive(dragon) and GetRandomInt(1, rollMaximum) == successRoll then
            call StartCasting(dragon, legacyIndex)
            call IssuePointOrder(dragon, "flamestrike", GetUnitX(dragon) + 250.00, GetUnitY(dragon))
            call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_03EmberpeakHighlands)
        endif
    endfunction

    private function CastHighlandsFlame takes nothing returns nothing
        call TryCastHighlandsFlame(gg_unit_n647_1938, 3, 2, 1)
        call TryCastHighlandsFlame(gg_unit_n647_1009, 4, 2, 2)
        call TryCastHighlandsFlame(gg_unit_n647_0846, 5, 3, 3)
        call TimerStart(ZoneCastTimer, GetRandomReal(10.00, 20.00), false, function CastHighlandsFlame)
    endfunction

    private function PickArenaPlayerTarget takes unit dragon returns unit
        local unit picked = null
        local unit target = null

        call GroupClear(WorkGroup)
        call GroupClear(TargetGroup)
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_DragonFireSpam01, null)
        loop
            set picked = FirstOfGroup(WorkGroup)
            exitwhen picked == null
            call GroupRemoveUnit(WorkGroup, picked)
            if IsAlive(picked) and IsUnitEnemy(picked, GetOwningPlayer(dragon)) and IsPlayerInForce(GetOwningPlayer(picked), udg_PlayerGroup) then
                call GroupAddUnit(TargetGroup, picked)
            endif
        endloop
        set target = GroupPickRandomUnit(TargetGroup)
        call GroupClear(TargetGroup)
        set picked = null
        return target
    endfunction

    private function TryCastArenaFlame takes unit dragon, integer dragonIndex, integer successRoll returns nothing
        local unit target = null

        if IsAlive(dragon) and GetRandomInt(1, 2) == successRoll then
            if ArenaMode == EMBERPEAK_DRAGONS_ARENA_PLAYERS then
                set target = PickArenaPlayerTarget(dragon)
            else
                set target = Colossus
            endif
            if IsAlive(target) then
                call StartCasting(dragon, dragonIndex)
                call IssuePointOrder(dragon, "flamestrike", GetUnitX(target), GetUnitY(target))
                call DragonBehavior_TryPlayAmbientSound(dragon, gg_rct_DragonFireSpam01)
            endif
        endif
        set target = null
    endfunction

    private function ArenaCast takes nothing returns nothing
        local real nextDelay = GetRandomReal(10.00, 20.00)

        call TryCastArenaFlame(gg_unit_n647_1904, 1, 1)
        call TryCastArenaFlame(gg_unit_n647_0823, 2, 2)
        if ArenaMode == EMBERPEAK_DRAGONS_ARENA_COLOSSUS then
            set nextDelay = GetRandomReal(6.00, 11.00)
        endif
        if Colossus != null then
            call TimerStart(ArenaCastTimer, nextDelay, false, function ArenaCast)
        endif
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

    private function RegisterPeaksDragon takes nothing returns nothing
        local unit dragon = GetEnumUnit()

        if GetUnitTypeId(dragon) == UNIT_HIGH_DRAGON then
            call CreepRespawn_DiscardUnit(dragon)
            call SetUnitInvulnerable(dragon, true)
            call GroupAddUnit(DragonfirePeaksGroup, dragon)
        endif
        set dragon = null
    endfunction

    private function EnsureDragonfirePeaksWanderers takes nothing returns nothing
        local unit dragon = null
        local integer count = BlzGroupGetSize(DragonfirePeaksGroup)

        loop
            exitwhen count >= DRAGONFIRE_PEAKS_WANDERER_COUNT
            set dragon = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_HIGH_DRAGON, GetRandomReal(GetRectMinX(gg_rct_04DragonfirePeaks), GetRectMaxX(gg_rct_04DragonfirePeaks)), GetRandomReal(GetRectMinY(gg_rct_04DragonfirePeaks), GetRectMaxY(gg_rct_04DragonfirePeaks)), GetRandomReal(0.00, 360.00))
            if dragon != null then
                call CreepRespawn_DiscardUnit(dragon)
                call SetUnitInvulnerable(dragon, true)
                call GroupAddUnit(DragonfirePeaksGroup, dragon)
            endif
            set dragon = null
            set count = count + 1
        endloop
    endfunction

    public function SetColossus takes unit whichUnit returns nothing
        set Colossus = whichUnit
    endfunction

    public function SetArenaMode takes integer mode returns nothing
        if mode < EMBERPEAK_DRAGONS_ARENA_IDLE or mode > EMBERPEAK_DRAGONS_ARENA_COLOSSUS then
            set mode = EMBERPEAK_DRAGONS_ARENA_IDLE
        endif
        set ArenaMode = mode
        call PauseTimer(ArenaCastTimer)
        if Colossus != null then
            if ArenaMode == EMBERPEAK_DRAGONS_ARENA_COLOSSUS then
                call TimerStart(ArenaCastTimer, GetRandomReal(6.00, 11.00), false, function ArenaCast)
            else
                call TimerStart(ArenaCastTimer, GetRandomReal(10.00, 20.00), false, function ArenaCast)
            endif
        endif
    endfunction

    public function GetDragonfirePeaksGroup takes nothing returns group
        return DragonfirePeaksGroup
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
        call GroupEnumUnitsInRect(WorkGroup, gg_rct_04DragonfirePeaks, null)
        call ForGroup(WorkGroup, function RegisterPeaksDragon)
        call GroupClear(WorkGroup)
        call EnsureDragonfirePeaksWanderers()
        call TimerStart(CenterWanderTimer, 3.00, true, function CenterWander)
        call TimerStart(ZoneWanderTimer, 7.00, true, function ZoneWander)
        call TimerStart(ZoneCastTimer, GetRandomReal(10.00, 20.00), false, function CastHighlandsFlame)
        call DestroyTimer(initTimer)
        set initTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer = CreateTimer()

        set HighlandsGroup = CreateGroup()
        set DragonfirePeaksGroup = CreateGroup()
        set WorkGroup = CreateGroup()
        set TargetGroup = CreateGroup()
        set CenterWanderTimer = CreateTimer()
        set ZoneWanderTimer = CreateTimer()
        set ZoneCastTimer = CreateTimer()
        set ArenaCastTimer = CreateTimer()
        set CastingTimerToSlot = Table.create()
        set UnitCasting = Table.create()
        call TimerStart(initTimer, 0.00, false, function DelayedInit)
        set initTimer = null
    endfunction
endlibrary
