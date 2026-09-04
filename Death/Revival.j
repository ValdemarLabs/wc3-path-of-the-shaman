/**
    Revival

    Author: Valdemar
    Version:

    Description:
    Revives Nazgrek and Zulkis at the selected graveyard after 30 seconds,
    initially selects Graveyard04 for Nazgrek,
    keeps the legacy player revive timers and graveyard globals compatible,
    and uses the preplaced Spirit Healer or Spirit Walker at that graveyard to
    recover items dropped at the death location. The active fallen player hero receives
    a rotating death camera until revival or a switch to the other living hero.

    Credits:
    - Old GUI ReviveSystemPlayer triggers

    How to install:
    Import after Death, Events, UnitDeathEvent, Table, ExSound, CameraControl,
    and ZonesCore. Disable the
    old ReviveSystemPlayer death, graveyard, revive, reveal, and healer-dialog
    GUI triggers while retaining their GUI variables.

    API:
    call Revival_SetGraveyardHealerType(graveyardId, unitTypeId)
    call Revival_SetCreateMissingSpiritHealers(enabled)
    call Revival_SetUseGameDifficultyDropRules(enabled)
    call Revival_SetDropEquipmentOnDeath(enabled)
    call Revival_SetDropItemsOnDeath(enabled)
    call Revival_GetGraveyardRect(graveyardId) returns rect
    call Revival_GetSelectedGraveyard() returns integer
    call Revival_SelectGraveyard(graveyardId)

**/
library Revival initializer Init requires Death, Table, Events, UnitDeathEvent, ExSound, CameraControl, DEquipment, DialogInteraction, DialogSystem, ZonesCore, optional HintsUI

globals
    // Configuration
    private constant real REVIVAL_DELAY = 30.00
    private constant real REVIVAL_LIFE_PERCENT = 50.00
    private constant real REVIVAL_MANA_PERCENT = 50.00
    private constant real REVIVAL_ITEM_REGION_RADIUS = 150.00
    private constant real REVIVAL_HEALER_INTERACT_RANGE = 500.00
    private constant real REVIVAL_HEALER_DURATION = 60.00
    private constant real REVIVAL_DEATH_CAMERA_CHECK_INTERVAL = 0.10
    private constant real REVIVAL_DEATH_CAMERA_INITIAL_DISTANCE = 1400.00
    private constant real REVIVAL_DEATH_CAMERA_INITIAL_ANGLE = 280.00
    private constant real REVIVAL_DEATH_CAMERA_FINAL_DISTANCE = 1300.00
    private constant real REVIVAL_DEATH_CAMERA_FINAL_ANGLE = 315.00
    private constant real REVIVAL_DEATH_CAMERA_ROTATION = 90.00
    private constant real REVIVAL_DEATH_CAMERA_INITIAL_DURATION = 2.00
    private constant real REVIVAL_DEATH_CAMERA_DISTANCE_DURATION = 4.00
    private constant real REVIVAL_DEATH_CAMERA_ANGLE_DURATION = 8.00
    private constant real REVIVAL_DEATH_CAMERA_ROTATE_DURATION = 45.00
    private constant integer REVIVAL_SPIRIT_HEALER_ID = 'u605'
    private constant integer REVIVAL_SPIRIT_WALKER_ID = 'u607'
    private constant integer REVIVAL_TIMED_LIFE_BUFF_ID = 'BTLF'
    private constant integer REVIVAL_INITIAL_GRAVEYARD_ID = 4
    private constant string REVIVAL_GRAVEYARD_EFFECT = "Abilities\\Spells\\Items\\HealingSalve\\HealingSalveTarget.mdl"

    private Table Revival_TimerHero = 0
    private Table Revival_DeathX = 0
    private Table Revival_DeathY = 0
    private Table Revival_HasDroppedItems = 0
    private Table Revival_HealerGraveyard = 0
    private Table Revival_GeneratedHealer = 0
    private Table Revival_OwnerTimerHealer = 0

    private integer array Revival_HealerType
    private unit array Revival_Healer
    private trigger array Revival_GraveyardTrigger

    private dialog Revival_RestoreDialog = null
    private unit Revival_SelectedHealer = null
    private real Revival_ItemTargetX = 0.00
    private real Revival_ItemTargetY = 0.00
    private timer Revival_DeathCameraTimer = null
    private unit Revival_DeathCameraHero = null
    private boolean Revival_DeathCameraActive = false
    public boolean DropEquipmentOnDeath = true
    public boolean DropItemsOnDeath = false
    public boolean CreateMissingSpiritHealers = false
    public boolean UseGameDifficultyDropRules = true
endglobals

public function SetUseGameDifficultyDropRules takes boolean enabled returns nothing
    set UseGameDifficultyDropRules = enabled
endfunction

public function SetDropEquipmentOnDeath takes boolean enabled returns nothing
    set UseGameDifficultyDropRules = false
    set DropEquipmentOnDeath = enabled
endfunction

public function SetDropItemsOnDeath takes boolean enabled returns nothing
    set UseGameDifficultyDropRules = false
    set DropItemsOnDeath = enabled
endfunction

public function SetCreateMissingSpiritHealers takes boolean enabled returns nothing
    set CreateMissingSpiritHealers = enabled
endfunction

public function GetGraveyardRect takes integer graveyardId returns rect
    if graveyardId == 2 then
        return gg_rct_Graveyard02
    elseif graveyardId == 3 then
        return gg_rct_Graveyard03
    elseif graveyardId == 4 then
        return gg_rct_Graveyard04
    elseif graveyardId == 5 then
        return gg_rct_Graveyard05
    elseif graveyardId == 6 then
        return gg_rct_Graveyard06
    elseif graveyardId == 7 then
        return gg_rct_Graveyard07
    elseif graveyardId == 8 then
        return gg_rct_Graveyard08
    elseif graveyardId == 9 then
        return gg_rct_Graveyard09
    endif
    return gg_rct_Graveyard
endfunction

private function Revival_GetGraveyardAreaRect takes integer graveyardId returns rect
    if graveyardId == 2 then
        return gg_rct_Graveyard02Area
    elseif graveyardId == 3 then
        return gg_rct_Graveyard03Area
    elseif graveyardId == 4 then
        return gg_rct_Graveyard04Area
    elseif graveyardId == 5 then
        return gg_rct_Graveyard05Area
    elseif graveyardId == 6 then
        return gg_rct_Graveyard06Area
    elseif graveyardId == 7 then
        return gg_rct_Graveyard07Area
    elseif graveyardId == 8 then
        return gg_rct_Graveyard08Area
    elseif graveyardId == 9 then
        return gg_rct_Graveyard09Area
    endif
    return gg_rct_Graveyard01Area
endfunction

private function Revival_GetSelectedGraveyardId takes nothing returns integer
    if udg_GraveyardSelect < 1 or udg_GraveyardSelect > 9 then
        return REVIVAL_INITIAL_GRAVEYARD_ID
    endif
    return udg_GraveyardSelect
endfunction

public function GetSelectedGraveyard takes nothing returns integer
    return Revival_GetSelectedGraveyardId()
endfunction

public function SetGraveyardHealerType takes integer graveyardId, integer unitTypeId returns nothing
    if graveyardId >= 1 and graveyardId <= 9 and (unitTypeId == REVIVAL_SPIRIT_HEALER_ID or unitTypeId == REVIVAL_SPIRIT_WALKER_ID) then
        set Revival_HealerType[graveyardId] = unitTypeId
    endif
endfunction

private function Revival_IsPlayerHero takes unit whichHero returns boolean
    return whichHero != null and (whichHero == udg_Nazgrek or whichHero == udg_Zulkis)
endfunction

private function Revival_StopDeathCamera takes nothing returns nothing
    if not Revival_DeathCameraActive then
        return
    endif
    set Revival_DeathCameraActive = false
    call PauseTimer(Revival_DeathCameraTimer)
    set Revival_DeathCameraHero = null
    call StopCameraForPlayerBJ(Player(0))
    call ResetToGameCameraForPlayer(Player(0), 0.00)
    call CameraControl_ResumeQuick(Player(0))
endfunction

private function Revival_CheckDeathCamera takes nothing returns nothing
    local unit cameraTarget = CameraControl_GetStoredTargetUnit(Player(0))

    if Revival_DeathCameraHero == null or GetUnitTypeId(Revival_DeathCameraHero) == 0 or not Death_IsFallen(Revival_DeathCameraHero) then
        call Revival_StopDeathCamera()
    elseif cameraTarget != Revival_DeathCameraHero and Revival_IsPlayerHero(cameraTarget) and not Death_IsFallen(cameraTarget) then
        call Revival_StopDeathCamera()
    endif
    set cameraTarget = null
endfunction

private function Revival_StartDeathCamera takes unit whichHero, real x, real y returns nothing
    local unit storedTarget = CameraControl_GetStoredTargetUnit(Player(0))
    local location cameraPoint
    local boolean isActiveTarget = storedTarget == whichHero

    // A missing or dead stored target means CameraControl was using its
    // Nazgrek-then-Zulkis fallback immediately before this death.
    if not isActiveTarget and (storedTarget == null or Death_IsFallen(storedTarget)) then
        set isActiveTarget = whichHero == udg_Nazgrek or (whichHero == udg_Zulkis and Death_IsFallen(udg_Nazgrek))
    endif
    if not isActiveTarget or (not Revival_DeathCameraActive and CameraControl_IsSuspended(Player(0))) then
        set storedTarget = null
        return
    endif
    if Revival_DeathCameraActive then
        call PauseTimer(Revival_DeathCameraTimer)
    endif
    set Revival_DeathCameraHero = whichHero
    set Revival_DeathCameraActive = true
    call CameraControl_Suspend(Player(0))
    call SetCameraTargetControllerNoZForPlayer(Player(0), whichHero, 0.00, 0.00, false)
    call PanCameraToTimedForPlayer(Player(0), x, y, 0.00)
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_TARGET_DISTANCE, REVIVAL_DEATH_CAMERA_INITIAL_DISTANCE, REVIVAL_DEATH_CAMERA_INITIAL_DURATION)
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_ANGLE_OF_ATTACK, REVIVAL_DEATH_CAMERA_INITIAL_ANGLE, REVIVAL_DEATH_CAMERA_INITIAL_DURATION)
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_ROTATION, REVIVAL_DEATH_CAMERA_ROTATION, REVIVAL_DEATH_CAMERA_INITIAL_DURATION)
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_TARGET_DISTANCE, REVIVAL_DEATH_CAMERA_FINAL_DISTANCE, REVIVAL_DEATH_CAMERA_DISTANCE_DURATION)
    call SetCameraFieldForPlayer(Player(0), CAMERA_FIELD_ANGLE_OF_ATTACK, REVIVAL_DEATH_CAMERA_FINAL_ANGLE, REVIVAL_DEATH_CAMERA_ANGLE_DURATION)
    set cameraPoint = Location(x, y)
    call RotateCameraAroundLocBJ(360.00, cameraPoint, Player(0), REVIVAL_DEATH_CAMERA_ROTATE_DURATION)
    call RemoveLocation(cameraPoint)
    call TimerStart(Revival_DeathCameraTimer, REVIVAL_DEATH_CAMERA_CHECK_INTERVAL, true, function Revival_CheckDeathCamera)

    set cameraPoint = null
    set storedTarget = null
endfunction

private function Revival_OnPlayerHeroSelected takes nothing returns nothing
    local unit selectedHero = GetTriggerUnit()

    if GetTriggerPlayer() == Player(0) and Revival_DeathCameraActive and selectedHero != Revival_DeathCameraHero and Revival_IsPlayerHero(selectedHero) and not Death_IsFallen(selectedHero) then
        call CameraControl_SetTargetUnit(Player(0), selectedHero)
        call Revival_StopDeathCamera()
    endif
    set selectedHero = null
endfunction

private function Revival_IsNear takes unit firstUnit, unit secondUnit, real range returns boolean
    local real dx
    local real dy

    if firstUnit == null or secondUnit == null then
        return false
    endif
    set dx = GetUnitX(firstUnit) - GetUnitX(secondUnit)
    set dy = GetUnitY(firstUnit) - GetUnitY(secondUnit)
    return dx * dx + dy * dy <= range * range
endfunction

private function Revival_ClearDeathRegion takes unit whichHero returns nothing
    if whichHero == udg_Nazgrek then
        if udg_NazgrekDeathRegion != null then
            call RemoveRect(udg_NazgrekDeathRegion)
            set udg_NazgrekDeathRegion = null
        endif
    elseif whichHero == udg_Zulkis then
        if udg_ZulkisDeathRegion != null then
            call RemoveRect(udg_ZulkisDeathRegion)
            set udg_ZulkisDeathRegion = null
        endif
    endif
endfunction

private function Revival_CreateDeathRegion takes unit whichHero, real x, real y returns nothing
    local rect deathRect = Rect(x - REVIVAL_ITEM_REGION_RADIUS, y - REVIVAL_ITEM_REGION_RADIUS, x + REVIVAL_ITEM_REGION_RADIUS, y + REVIVAL_ITEM_REGION_RADIUS)

    call Revival_ClearDeathRegion(whichHero)
    if whichHero == udg_Nazgrek then
        set udg_NazgrekDeathRegion = deathRect
    elseif whichHero == udg_Zulkis then
        set udg_ZulkisDeathRegion = deathRect
    else
        call RemoveRect(deathRect)
    endif
    set deathRect = null
endfunction

private function Revival_DropHeroItems takes unit whichHero, real x, real y returns boolean
    local integer slot = 0
    local integer inventorySize = UnitInventorySize(whichHero)
    local integer droppedCount = 0
    local item droppedItem
    local boolean dropEquipment = DropEquipmentOnDeath
    local boolean dropItems = DropItemsOnDeath

    if UseGameDifficultyDropRules then
        if GetGameDifficulty() == MAP_DIFFICULTY_EASY then
            set dropEquipment = false
            set dropItems = false
        elseif GetGameDifficulty() == MAP_DIFFICULTY_HARD then
            set dropEquipment = true
            set dropItems = true
        else
            set dropEquipment = true
            set dropItems = false
        endif
    endif
    if dropEquipment then
        set droppedCount = droppedCount + DInvDropEquippedItemsForUnit(whichHero, x, y)
    endif
    if dropItems then
        set droppedCount = droppedCount + DInvDropStoredItemsForUnit(whichHero, x, y)
        if inventorySize > bj_MAX_INVENTORY then
            set inventorySize = bj_MAX_INVENTORY
        endif
        loop
            exitwhen slot >= inventorySize
            set droppedItem = UnitItemInSlot(whichHero, slot)
            if droppedItem != null then
                if UnitDropItemPoint(whichHero, droppedItem, x, y) then
                    set droppedCount = droppedCount + 1
                endif
            endif
            set slot = slot + 1
        endloop
    endif
    set droppedItem = null
    return droppedCount > 0
endfunction

private function Revival_UpdateGraveyardLegacyState takes integer graveyardId returns nothing
    local rect graveyardRect = Revival_GetGraveyardRect(graveyardId)
    local real x = GetRectCenterX(graveyardRect)
    local real y = GetRectCenterY(graveyardRect)

    set udg_GraveyardSelect = graveyardId
    if udg_GraveyardPoint != null then
        call RemoveLocation(udg_GraveyardPoint)
    endif
    set udg_GraveyardPoint = Location(x, y)
    if udg_GraveyardSpecialEffect != null then
        call DestroyEffect(udg_GraveyardSpecialEffect)
    endif
    set udg_GraveyardSpecialEffect = AddSpecialEffect(REVIVAL_GRAVEYARD_EFFECT, x, y)
    set graveyardRect = null
endfunction

public function SelectGraveyard takes integer graveyardId returns nothing
    if graveyardId < 1 or graveyardId > 9 then
        return
    endif
    call Revival_UpdateGraveyardLegacyState(graveyardId)
endfunction

private function Revival_GetNearestGraveyardId takes unit healer returns integer
    local integer graveyardId = 1
    local integer nearestId = 1
    local rect graveyardRect
    local real dx
    local real dy
    local real distanceSquared
    local real nearestDistanceSquared = 999999999.00

    loop
        exitwhen graveyardId > 9
        set graveyardRect = Revival_GetGraveyardRect(graveyardId)
        set dx = GetUnitX(healer) - GetRectCenterX(graveyardRect)
        set dy = GetUnitY(healer) - GetRectCenterY(graveyardRect)
        set distanceSquared = dx * dx + dy * dy
        if distanceSquared < nearestDistanceSquared then
            set nearestDistanceSquared = distanceSquared
            set nearestId = graveyardId
        endif
        set graveyardId = graveyardId + 1
    endloop
    set graveyardRect = null
    set healer = null
    return nearestId
endfunction

private function Revival_RegisterSpiritHealer takes unit healer returns nothing
    local integer graveyardId
    local unit current

    if healer == null or (GetUnitTypeId(healer) != REVIVAL_SPIRIT_HEALER_ID and GetUnitTypeId(healer) != REVIVAL_SPIRIT_WALKER_ID) then
        set healer = null
        return
    endif
    set graveyardId = Revival_GetNearestGraveyardId(healer)
    set current = Revival_Healer[graveyardId]
    if current == null or GetUnitTypeId(current) == 0 or GetWidgetLife(current) <= 0.405 then
        set Revival_Healer[graveyardId] = healer
    endif
    call SetUnitInvulnerable(healer, true)
    call GroupAddUnit(udg_SpiritHealers, healer)
    set Revival_HealerGraveyard[GetHandleId(healer)] = graveyardId
    set current = null
    set healer = null
endfunction

private function Revival_RegisterSpiritHealerEnum takes nothing returns nothing
    call Revival_RegisterSpiritHealer(GetEnumUnit())
endfunction

private function Revival_RegisterPreplacedSpiritHealers takes nothing returns nothing
    local group healerGroup = CreateGroup()

    call GroupEnumUnitsInRect(healerGroup, bj_mapInitialPlayableArea, null)
    call ForGroup(healerGroup, function Revival_RegisterSpiritHealerEnum)
    call DestroyGroup(healerGroup)
    set healerGroup = null
endfunction

private function Revival_CreateSpiritHealer takes integer graveyardId returns unit
    local rect graveyardRect
    local unit healer = Revival_Healer[graveyardId]
    local integer healerType = Revival_HealerType[graveyardId]

    if healer != null and GetUnitTypeId(healer) != 0 and GetWidgetLife(healer) > 0.405 then
        set healer = null
        return Revival_Healer[graveyardId]
    endif
    if not CreateMissingSpiritHealers then
        set healer = null
        return null
    endif
    if healerType == 0 then
        set healerType = REVIVAL_SPIRIT_HEALER_ID
    endif
    set graveyardRect = Revival_GetGraveyardRect(graveyardId)
    set healer = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), healerType, GetRectCenterX(graveyardRect), GetRectCenterY(graveyardRect), bj_UNIT_FACING)
    call SetUnitInvulnerable(healer, true)
    call UnitApplyTimedLife(healer, REVIVAL_TIMED_LIFE_BUFF_ID, REVIVAL_HEALER_DURATION)
    if udg_SpiritHealers == null then
        set udg_SpiritHealers = CreateGroup()
    endif
    call GroupAddUnit(udg_SpiritHealers, healer)
    set Revival_Healer[graveyardId] = healer
    set Revival_HealerGraveyard[GetHandleId(healer)] = graveyardId
    set Revival_GeneratedHealer.boolean[GetHandleId(healer)] = true
    set graveyardRect = null
    set healer = null
    return Revival_Healer[graveyardId]
endfunction

private function Revival_OnDeathRevived takes nothing returns nothing
    local unit whichHero = Death_EventHero

    if Revival_DeathCameraActive and Revival_DeathCameraHero == whichHero then
        call CameraControl_SetTargetUnit(Player(0), whichHero)
        call Revival_StopDeathCamera()
    endif

    if whichHero == udg_Nazgrek then
        if udg_ReviveTimerNazgrek != null then
            call PauseTimer(udg_ReviveTimerNazgrek)
            call Revival_TimerHero.unit.remove(GetHandleId(udg_ReviveTimerNazgrek))
        endif
        set udg_NazgrekDead = false
    elseif whichHero == udg_Zulkis then
        if udg_ReviveTimerZulkis != null then
            call PauseTimer(udg_ReviveTimerZulkis)
            call Revival_TimerHero.unit.remove(GetHandleId(udg_ReviveTimerZulkis))
        endif
        set udg_ZulkisDead = false
    endif
    if whichHero != null and not Revival_HasDroppedItems.boolean[GetHandleId(whichHero)] then
        call Revival_DeathX.real.remove(GetHandleId(whichHero))
        call Revival_DeathY.real.remove(GetHandleId(whichHero))
        call Revival_HasDroppedItems.boolean.remove(GetHandleId(whichHero))
    endif
    set whichHero = null
endfunction

private function Revival_ReviveTimerExpired takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local unit whichHero = Revival_TimerHero.unit[GetHandleId(expired)]
    local integer graveyardId = Revival_GetSelectedGraveyardId()
    local rect graveyardRect = Revival_GetGraveyardRect(graveyardId)
    local real x = GetRectCenterX(graveyardRect)
    local real y = GetRectCenterY(graveyardRect)
    local boolean hasDroppedItems = whichHero != null and Revival_HasDroppedItems.boolean[GetHandleId(whichHero)]

    call Revival_TimerHero.unit.remove(GetHandleId(expired))
    if whichHero != null and Death_IsFallen(whichHero) and Death_ReviveAt(whichHero, x, y, REVIVAL_LIFE_PERCENT, REVIVAL_MANA_PERCENT, true) then
        if whichHero == udg_Nazgrek then
            set udg_RestoreItemsPossibleN = hasDroppedItems
        elseif whichHero == udg_Zulkis then
            set udg_RestoreItemsPossibleZ = hasDroppedItems
        endif
        if hasDroppedItems then
            call Revival_CreateSpiritHealer(graveyardId)
        endif
        call PingMinimapEx(x, y, 1.00, 255, 255, 255, true)
        call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 5.00, "|cffffff00" + GetHeroProperName(whichHero) + "|r |cff00ff00has been revived at the graveyard.|r")
    endif

    set graveyardRect = null
    set whichHero = null
    set expired = null
endfunction

private function Revival_StartPlayerTimer takes unit whichHero returns nothing
    local timer reviveTimer

    if whichHero == udg_Nazgrek then
        if udg_ReviveTimerNazgrek == null then
            set udg_ReviveTimerNazgrek = CreateTimer()
        endif
        set reviveTimer = udg_ReviveTimerNazgrek
    else
        if udg_ReviveTimerZulkis == null then
            set udg_ReviveTimerZulkis = CreateTimer()
        endif
        set reviveTimer = udg_ReviveTimerZulkis
    endif
    set Revival_TimerHero.unit[GetHandleId(reviveTimer)] = whichHero
    call TimerStart(reviveTimer, REVIVAL_DELAY, false, function Revival_ReviveTimerExpired)
    set reviveTimer = null
endfunction

private function Revival_OnHeroDeath takes nothing returns nothing
    local unit whichHero = UnitDeathEvent_GetDyingUnit()
    local integer healerGraveyard
    local real x
    local real y

    if whichHero != null and udg_SpiritHealers != null and IsUnitInGroup(whichHero, udg_SpiritHealers) then
        set healerGraveyard = Revival_HealerGraveyard[GetHandleId(whichHero)]
        call GroupRemoveUnit(udg_SpiritHealers, whichHero)
        if healerGraveyard > 0 and Revival_Healer[healerGraveyard] == whichHero then
            set Revival_Healer[healerGraveyard] = null
        endif
        call Revival_HealerGraveyard.remove(GetHandleId(whichHero))
        call Revival_GeneratedHealer.boolean.remove(GetHandleId(whichHero))
    endif
    if not Revival_IsPlayerHero(whichHero) then
        set whichHero = null
        return
    endif

    set x = GetUnitX(whichHero)
    set y = GetUnitY(whichHero)
    set Revival_DeathX.real[GetHandleId(whichHero)] = x
    set Revival_DeathY.real[GetHandleId(whichHero)] = y
    set Revival_HasDroppedItems.boolean[GetHandleId(whichHero)] = Revival_DropHeroItems(whichHero, x, y)
    if Revival_HasDroppedItems.boolean[GetHandleId(whichHero)] then
        call Revival_CreateDeathRegion(whichHero, x, y)
    else
        call Revival_ClearDeathRegion(whichHero)
    endif
    call Revival_StartPlayerTimer(whichHero)
    call Revival_StartDeathCamera(whichHero, x, y)
    static if LIBRARY_HintsUI then
        call HintsUI_PublishForUnit(HintsUI_HINT_GRAVEYARDS, whichHero)
    endif

    if whichHero == udg_Nazgrek then
        set udg_NazgrekDead = true
        set udg_RestoreItemsPossibleN = false
    else
        set udg_ZulkisDead = true
        set udg_RestoreItemsPossibleZ = false
    endif
    call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, 4.00, "|cffffcc00" + GetHeroProperName(whichHero) + "|r has |cffff4040fallen.|r")
    set whichHero = null
endfunction

private function Revival_OnGraveyardEnter takes nothing returns nothing
    local trigger sourceTrigger = GetTriggeringTrigger()
    local unit entering = GetTriggerUnit()
    local integer graveyardId = 1
    local integer zoneId

    if not Revival_IsPlayerHero(entering) or Death_IsFallen(entering) then
        set sourceTrigger = null
        set entering = null
        return
    endif
    loop
        exitwhen graveyardId > 9 or Revival_GraveyardTrigger[graveyardId] == sourceTrigger
        set graveyardId = graveyardId + 1
    endloop
    if graveyardId <= 9 and graveyardId != Revival_GetSelectedGraveyardId() then
        call Revival_UpdateGraveyardLegacyState(graveyardId)
        set zoneId = ZonesCore_GetZoneIdAtPoint(GetUnitX(entering), GetUnitY(entering))
        call DisplayTimedTextToPlayer(GetOwningPlayer(entering), 0.00, 0.00, 3.00, "|cff80ff80" + ZonesCore_GetZoneName(zoneId) + " graveyard selected.|r")
        static if LIBRARY_HintsUI then
            call HintsUI_PublishForUnit(HintsUI_HINT_GRAVEYARDS_CHANGE, entering)
        endif
    endif
    set sourceTrigger = null
    set entering = null
endfunction

private function Revival_MoveItemEnum takes nothing returns nothing
    local item movedItem = GetEnumItem()

    if movedItem != null and GetWidgetLife(movedItem) > 0.405 and not IsItemOwned(movedItem) then
        call SetItemPosition(movedItem, Revival_ItemTargetX, Revival_ItemTargetY)
    endif
    set movedItem = null
endfunction

private function Revival_RestoreHealerOwner takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local unit healer = Revival_OwnerTimerHealer.unit[GetHandleId(expired)]

    if healer != null and GetUnitTypeId(healer) != 0 then
        call SetUnitOwner(healer, Player(PLAYER_NEUTRAL_PASSIVE), false)
    endif
    call Revival_OwnerTimerHealer.unit.remove(GetHandleId(expired))
    call DestroyTimer(expired)
    set healer = null
    set expired = null
endfunction

private function Revival_ApplyResurrectionSickness takes unit healer, unit whichHero returns nothing
    local timer ownerTimer

    if healer == null or whichHero == null then
        return
    endif
    call SetUnitOwner(healer, Player(PLAYER_NEUTRAL_AGGRESSIVE), false)
    call IssueTargetOrder(healer, "acidbomb", whichHero)
    set ownerTimer = CreateTimer()
    set Revival_OwnerTimerHealer.unit[GetHandleId(ownerTimer)] = healer
    call TimerStart(ownerTimer, 0.50, false, function Revival_RestoreHealerOwner)
    call ExSound_PlayLabelOnUnit("SpiritHealerResSickness", whichHero, false)
    set ownerTimer = null
endfunction

private function Revival_RestoreItems takes unit whichHero returns nothing
    local real deathX
    local real deathY
    local rect itemRect

    if whichHero == null then
        return
    endif
    set deathX = Revival_DeathX.real[GetHandleId(whichHero)]
    set deathY = Revival_DeathY.real[GetHandleId(whichHero)]
    set Revival_ItemTargetX = GetUnitX(whichHero)
    set Revival_ItemTargetY = GetUnitY(whichHero)
    set itemRect = Rect(deathX - REVIVAL_ITEM_REGION_RADIUS, deathY - REVIVAL_ITEM_REGION_RADIUS, deathX + REVIVAL_ITEM_REGION_RADIUS, deathY + REVIVAL_ITEM_REGION_RADIUS)
    call EnumItemsInRect(itemRect, null, function Revival_MoveItemEnum)
    call RemoveRect(itemRect)
    call ExSound_PlayLabelOnUnit("ItemRestore", whichHero, false)
    call Revival_ApplyResurrectionSickness(Revival_SelectedHealer, whichHero)
    call Revival_ClearDeathRegion(whichHero)
    call Revival_DeathX.real.remove(GetHandleId(whichHero))
    call Revival_DeathY.real.remove(GetHandleId(whichHero))
    call Revival_HasDroppedItems.boolean.remove(GetHandleId(whichHero))
    if whichHero == udg_Nazgrek then
        set udg_RestoreItemsPossibleN = false
    elseif whichHero == udg_Zulkis then
        set udg_RestoreItemsPossibleZ = false
    endif
    set itemRect = null
endfunction

private function Revival_EndSpiritHealerDialog takes nothing returns nothing
    call DialogSystem_HideDialog(Revival_RestoreDialog, Player(0))
    call DialogInteraction_EndCinematicSequence(true)
    set Revival_SelectedHealer = null
endfunction

private function Revival_OnRestoreNazgrek takes nothing returns nothing
    call Revival_RestoreItems(udg_Nazgrek)
    call Revival_EndSpiritHealerDialog()
endfunction

private function Revival_OnRestoreZulkis takes nothing returns nothing
    call Revival_RestoreItems(udg_Zulkis)
    call Revival_EndSpiritHealerDialog()
endfunction

private function Revival_OnRestoreCancel takes nothing returns nothing
    call Revival_EndSpiritHealerDialog()
endfunction

private function Revival_OnSpiritHealerSelected takes nothing returns nothing
    local unit healer = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()
    local boolean nazgrekAvailable
    local boolean zulkisAvailable
    local button dialogButton
    local integer sequenceId

    if selectingPlayer != Player(0) or healer == null or udg_SpiritHealers == null or not IsUnitInGroup(healer, udg_SpiritHealers) then
        set selectingPlayer = null
        set healer = null
        return
    endif
    set nazgrekAvailable = udg_RestoreItemsPossibleN and not Death_IsFallen(udg_Nazgrek) and Revival_IsNear(healer, udg_Nazgrek, REVIVAL_HEALER_INTERACT_RANGE)
    set zulkisAvailable = udg_RestoreItemsPossibleZ and not Death_IsFallen(udg_Zulkis) and Revival_IsNear(healer, udg_Zulkis, REVIVAL_HEALER_INTERACT_RANGE)
    if not nazgrekAvailable and not zulkisAvailable then
        set selectingPlayer = null
        set healer = null
        return
    endif

    set Revival_SelectedHealer = healer
    set udg_SpiritHealer = healer
    call DialogSystem_ClearDialog(Revival_RestoreDialog)
    call DialogSystem_SetTitle(Revival_RestoreDialog, GetUnitName(healer))
    if nazgrekAvailable then
        set dialogButton = DialogSystem_AddButton(Revival_RestoreDialog, "Restore " + GetHeroProperName(udg_Nazgrek) + "'s items", 1)
        call DialogSystem_BindButtonCode(dialogButton, function Revival_OnRestoreNazgrek)
    endif
    if zulkisAvailable then
        set dialogButton = DialogSystem_AddButton(Revival_RestoreDialog, "Restore " + GetHeroProperName(udg_Zulkis) + "'s items", 2)
        call DialogSystem_BindButtonCode(dialogButton, function Revival_OnRestoreZulkis)
    endif
    set dialogButton = DialogSystem_AddButtonExit(Revival_RestoreDialog, 3)
    call DialogSystem_BindButtonCode(dialogButton, function Revival_OnRestoreCancel)
    set sequenceId = DialogSystem_CreateSequence()
    call DialogSystem_SetSequenceDefaultSpeaker(sequenceId, healer, GetUnitName(healer))
    call DialogSystem_AddLine(sequenceId, healer, GetUnitName(healer), "I can restore the items lost at your death site.", "", true)
    call DialogInteraction_PlayGreetSequenceEx(sequenceId, healer, selectingPlayer, Revival_RestoreDialog, true)
    set dialogButton = null
    set selectingPlayer = null
    set healer = null
endfunction

private function Revival_RegisterGraveyardEvents takes nothing returns nothing
    local integer graveyardId = 1
    local trigger graveyardTrigger

    loop
        exitwhen graveyardId > 9
        set graveyardTrigger = CreateTrigger()
        set Revival_GraveyardTrigger[graveyardId] = graveyardTrigger
        call TriggerRegisterEnterRectSimple(graveyardTrigger, Revival_GetGraveyardAreaRect(graveyardId))
        call TriggerAddAction(graveyardTrigger, function Revival_OnGraveyardEnter)
        set graveyardId = graveyardId + 1
    endloop
    set graveyardTrigger = null
endfunction

private function Init takes nothing returns nothing

    set Revival_TimerHero = Table.create()
    set Revival_DeathX = Table.create()
    set Revival_DeathY = Table.create()
    set Revival_HasDroppedItems = Table.create()
    set Revival_HealerGraveyard = Table.create()
    set Revival_GeneratedHealer = Table.create()
    set Revival_OwnerTimerHealer = Table.create()
    set Revival_RestoreDialog = DialogSystem_CreateDialog("Spirit Healer")
    set Revival_DeathCameraTimer = CreateTimer()

    set Revival_HealerType[1] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[2] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[3] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[4] = REVIVAL_SPIRIT_WALKER_ID
    set Revival_HealerType[5] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[6] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[7] = REVIVAL_SPIRIT_WALKER_ID
    set Revival_HealerType[8] = REVIVAL_SPIRIT_HEALER_ID
    set Revival_HealerType[9] = REVIVAL_SPIRIT_HEALER_ID

    if udg_SpiritHealers == null then
        set udg_SpiritHealers = CreateGroup()
    endif
    call Revival_UpdateGraveyardLegacyState(REVIVAL_INITIAL_GRAVEYARD_ID)
    call Revival_RegisterPreplacedSpiritHealers()

    call Death_RegisterReviveCallback(function Revival_OnDeathRevived)
    call UnitDeathEvent_Register(function Revival_OnHeroDeath)
    call Events_RegisterPlayerUnitEvent(function Revival_OnPlayerHeroSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Events_RegisterPlayerUnitEvent(function Revival_OnSpiritHealerSelected, EVENT_PLAYER_UNIT_SELECTED)
    call Revival_RegisterGraveyardEvents()
endfunction

endlibrary
