/**
    Revival

    Author: Valdemar
    Version:

    Description:
    Revives Nazgrek and Zulkis at the selected graveyard after 30 seconds,
    keeps the legacy player revive timers and graveyard globals compatible,
    and creates a temporary Spirit Healer or Spirit Walker that can recover
    items dropped at the death location.

    Credits:
    - Old GUI ReviveSystemPlayer triggers

    How to install:
    Import after Death, Events, UnitDeathEvent, Table, and ExSound. Disable the
    old ReviveSystemPlayer death, graveyard, revive, reveal, and healer-dialog
    GUI triggers while retaining their GUI variables.

    API:
    call Revival_SetGraveyardHealerType(graveyardId, unitTypeId)
    call Revival_GetGraveyardRect(graveyardId) returns rect
    call Revival_GetSelectedGraveyard() returns integer

**/
library Revival initializer Init requires Death, Table, Events, UnitDeathEvent, ExSound

globals
    // Configuration
    private constant real REVIVAL_DELAY = 30.00
    private constant real REVIVAL_LIFE_PERCENT = 50.00
    private constant real REVIVAL_MANA_PERCENT = 50.00
    private constant real REVIVAL_ITEM_REGION_RADIUS = 150.00
    private constant real REVIVAL_HEALER_INTERACT_RANGE = 500.00
    private constant real REVIVAL_HEALER_DURATION = 60.00
    private constant integer REVIVAL_SPIRIT_HEALER_ID = 'u605'
    private constant integer REVIVAL_SPIRIT_WALKER_ID = 'u607'
    private constant integer REVIVAL_TIMED_LIFE_BUFF_ID = 'BTLF'
    private constant string REVIVAL_GRAVEYARD_EFFECT = "Abilities\\Spells\\Items\\HealingSalve\\HealingSalveTarget.mdl"

    private Table Revival_TimerHero = 0
    private Table Revival_DeathX = 0
    private Table Revival_DeathY = 0
    private Table Revival_HealerGraveyard = 0
    private Table Revival_OwnerTimerHealer = 0

    private integer array Revival_HealerType
    private unit array Revival_Healer
    private trigger array Revival_GraveyardTrigger

    private dialog Revival_RestoreDialog = null
    private button Revival_RestoreNazgrekButton = null
    private button Revival_RestoreZulkisButton = null
    private button Revival_CancelButton = null
    private unit Revival_SelectedHealer = null
    private real Revival_ItemTargetX = 0.00
    private real Revival_ItemTargetY = 0.00
endglobals

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
        return 1
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
            call RemoveRegion(udg_NazgrekDeathRegion)
            set udg_NazgrekDeathRegion = null
        endif
    elseif whichHero == udg_Zulkis then
        if udg_ZulkisDeathRegion != null then
            call RemoveRegion(udg_ZulkisDeathRegion)
            set udg_ZulkisDeathRegion = null
        endif
    endif
endfunction

private function Revival_CreateDeathRegion takes unit whichHero, real x, real y returns nothing
    local rect deathRect = Rect(x - REVIVAL_ITEM_REGION_RADIUS, y - REVIVAL_ITEM_REGION_RADIUS, x + REVIVAL_ITEM_REGION_RADIUS, y + REVIVAL_ITEM_REGION_RADIUS)

    call Revival_ClearDeathRegion(whichHero)
    if whichHero == udg_Nazgrek then
        set udg_NazgrekDeathRegion = CreateRegion()
        call RegionAddRect(udg_NazgrekDeathRegion, deathRect)
    elseif whichHero == udg_Zulkis then
        set udg_ZulkisDeathRegion = CreateRegion()
        call RegionAddRect(udg_ZulkisDeathRegion, deathRect)
    endif
    call RemoveRect(deathRect)
    set deathRect = null
endfunction

private function Revival_DropHeroItems takes unit whichHero, real x, real y returns nothing
    local integer slot = 0
    local integer inventorySize = UnitInventorySize(whichHero)
    local item droppedItem

    if inventorySize > bj_MAX_INVENTORY then
        set inventorySize = bj_MAX_INVENTORY
    endif
    loop
        exitwhen slot >= inventorySize
        set droppedItem = UnitItemInSlot(whichHero, slot)
        if droppedItem != null then
            call UnitDropItemPoint(whichHero, droppedItem, x, y)
        endif
        set slot = slot + 1
    endloop
    set droppedItem = null
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

private function Revival_CreateSpiritHealer takes integer graveyardId returns unit
    local rect graveyardRect
    local unit healer = Revival_Healer[graveyardId]
    local integer healerType = Revival_HealerType[graveyardId]

    if healer != null and GetUnitTypeId(healer) != 0 and GetWidgetLife(healer) > 0.405 then
        call UnitApplyTimedLife(healer, REVIVAL_TIMED_LIFE_BUFF_ID, REVIVAL_HEALER_DURATION)
        set healer = null
        return Revival_Healer[graveyardId]
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
    set graveyardRect = null
    set healer = null
    return Revival_Healer[graveyardId]
endfunction

private function Revival_OnDeathRevived takes nothing returns nothing
    local unit whichHero = Death_EventHero

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
    set whichHero = null
endfunction

private function Revival_ReviveTimerExpired takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local unit whichHero = Revival_TimerHero.unit[GetHandleId(expired)]
    local integer graveyardId = Revival_GetSelectedGraveyardId()
    local rect graveyardRect = Revival_GetGraveyardRect(graveyardId)
    local real x = GetRectCenterX(graveyardRect)
    local real y = GetRectCenterY(graveyardRect)

    call Revival_TimerHero.unit.remove(GetHandleId(expired))
    if whichHero != null and Death_IsFallen(whichHero) and Death_ReviveAt(whichHero, x, y, REVIVAL_LIFE_PERCENT, REVIVAL_MANA_PERCENT, true) then
        if whichHero == udg_Nazgrek then
            set udg_RestoreItemsPossibleN = true
        elseif whichHero == udg_Zulkis then
            set udg_RestoreItemsPossibleZ = true
        endif
        call Revival_CreateSpiritHealer(graveyardId)
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
    local unit whichHero = GetDyingUnit()
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
    endif
    if not Revival_IsPlayerHero(whichHero) then
        set whichHero = null
        return
    endif

    set x = GetUnitX(whichHero)
    set y = GetUnitY(whichHero)
    set Revival_DeathX.real[GetHandleId(whichHero)] = x
    set Revival_DeathY.real[GetHandleId(whichHero)] = y
    call Revival_DropHeroItems(whichHero, x, y)
    call Revival_CreateDeathRegion(whichHero, x, y)
    call Revival_StartPlayerTimer(whichHero)

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

    if not Revival_IsPlayerHero(entering) or GetWidgetLife(entering) <= 0.405 then
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
        call DisplayTimedTextToPlayer(GetOwningPlayer(entering), 0.00, 0.00, 3.00, "|cff80ff80Graveyard " + I2S(graveyardId) + " is now your revival point.|r")
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
    if whichHero == udg_Nazgrek then
        set udg_RestoreItemsPossibleN = false
    elseif whichHero == udg_Zulkis then
        set udg_RestoreItemsPossibleZ = false
    endif
    set itemRect = null
endfunction

private function Revival_OnDialogClick takes nothing returns nothing
    local button clicked = GetClickedButton()

    call DialogDisplay(Player(0), Revival_RestoreDialog, false)
    if clicked == Revival_RestoreNazgrekButton then
        call Revival_RestoreItems(udg_Nazgrek)
    elseif clicked == Revival_RestoreZulkisButton then
        call Revival_RestoreItems(udg_Zulkis)
    endif
    set Revival_SelectedHealer = null
    set clicked = null
endfunction

private function Revival_OnSpiritHealerSelected takes nothing returns nothing
    local unit healer = GetTriggerUnit()
    local player selectingPlayer = GetTriggerPlayer()
    local boolean nazgrekAvailable
    local boolean zulkisAvailable

    if selectingPlayer != Player(0) or healer == null or udg_SpiritHealers == null or not IsUnitInGroup(healer, udg_SpiritHealers) then
        set selectingPlayer = null
        set healer = null
        return
    endif
    set nazgrekAvailable = udg_RestoreItemsPossibleN and GetWidgetLife(udg_Nazgrek) > 0.405 and Revival_IsNear(healer, udg_Nazgrek, REVIVAL_HEALER_INTERACT_RANGE)
    set zulkisAvailable = udg_RestoreItemsPossibleZ and GetWidgetLife(udg_Zulkis) > 0.405 and Revival_IsNear(healer, udg_Zulkis, REVIVAL_HEALER_INTERACT_RANGE)
    if not nazgrekAvailable and not zulkisAvailable then
        set selectingPlayer = null
        set healer = null
        return
    endif

    set Revival_SelectedHealer = healer
    set udg_SpiritHealer = healer
    call DisplayTimedTextToPlayer(selectingPlayer, 0.00, 0.00, 3.00, GetUnitName(healer) + ": I can restore the items lost at your death site.")
    call DialogClear(Revival_RestoreDialog)
    call DialogSetMessage(Revival_RestoreDialog, "Restore lost items")
    set Revival_RestoreNazgrekButton = null
    set Revival_RestoreZulkisButton = null
    if nazgrekAvailable then
        set Revival_RestoreNazgrekButton = DialogAddButton(Revival_RestoreDialog, "Restore " + GetHeroProperName(udg_Nazgrek) + "'s items", 0)
    endif
    if zulkisAvailable then
        set Revival_RestoreZulkisButton = DialogAddButton(Revival_RestoreDialog, "Restore " + GetHeroProperName(udg_Zulkis) + "'s items", 0)
    endif
    set Revival_CancelButton = DialogAddButton(Revival_RestoreDialog, "Cancel", 0)
    call DialogDisplay(selectingPlayer, Revival_RestoreDialog, true)
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
    local trigger dialogTrigger = CreateTrigger()

    set Revival_TimerHero = Table.create()
    set Revival_DeathX = Table.create()
    set Revival_DeathY = Table.create()
    set Revival_HealerGraveyard = Table.create()
    set Revival_OwnerTimerHealer = Table.create()
    set Revival_RestoreDialog = DialogCreate()

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
    if udg_GraveyardSelect < 1 or udg_GraveyardSelect > 9 then
        set udg_GraveyardSelect = 1
    endif

    call Death_RegisterReviveCallback(function Revival_OnDeathRevived)
    call UnitDeathEvent_Register(function Revival_OnHeroDeath)
    call Events_RegisterPlayerUnitEvent(function Revival_OnSpiritHealerSelected, EVENT_PLAYER_UNIT_SELECTED)
    call TriggerRegisterDialogEvent(dialogTrigger, Revival_RestoreDialog)
    call TriggerAddAction(dialogTrigger, function Revival_OnDialogClick)
    call Revival_RegisterGraveyardEvents()

    set dialogTrigger = null
endfunction

endlibrary
