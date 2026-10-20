/**
    ModernAbilityController

    Author: Valdemar
    Version: 0.1.0

    Description:
    Converts local custom action-slot input into validated synchronized ability
    orders. Unit-target abilities resolve from a clicked world point, immediate
    and self abilities cast directly, and precise point abilities retain the
    exact synchronized coordinates.

    Credits:
    - Blizzard Entertainment, Warcraft III frame, input, sync, and order APIs

    How to install:
    Import after AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog,
    ModernAbilityLoadout, and ModernAbilityTargeting. Call BeginLocal only for
    the local triggering player.

    API:
    - call ModernAbilityController_BeginLocal(whichPlayer, whichHero, slot)
    - call ModernAbilityController_CancelLocal(whichPlayer)
    - set active = ModernAbilityController_IsTargetingLocal(whichPlayer)
    - set abilityId = ModernAbilityController_GetPendingAbilityId(whichPlayer)

**/
library ModernAbilityController initializer Init requires AbilitiesPlayer, ShamanCommon, ModernAbilityCatalog, ModernAbilityLoadout, ModernAbilityTargeting

globals
    private constant string MAC_SYNC_PREFIX = "POTS_MAB_CAST"

    private boolean array MAC_Targeting
    private integer array MAC_PendingHeroSlot
    private integer array MAC_PendingSlot

    private trigger MAC_MouseTrigger = CreateTrigger()
    private trigger MAC_SyncTrigger = CreateTrigger()
endglobals

private function MAC_FindSeparator takes string source, integer startIndex returns integer
    local integer sourceLength = StringLength(source)
    local integer index = startIndex

    loop
        exitwhen index >= sourceLength
        if SubString(source, index, index + 1) == "," then
            return index
        endif
        set index = index + 1
    endloop

    return -1
endfunction

private function MAC_SetOrderCollisionsDisabled takes unit caster, integer selectedAbilityId, boolean disabled returns nothing
    local integer selectedOrderId = ModernAbilityCatalog_GetOrderId(selectedAbilityId)
    local integer entryIndex = 1
    local integer entryCount = AbilitiesPlayer_GetEntryCount()
    local integer abilityId

    if caster == null or selectedOrderId == 0 then
        return
    endif

    loop
        exitwhen entryIndex > entryCount
        set abilityId = AbilitiesPlayer_GetEntryAbilityId(entryIndex)
        if abilityId != selectedAbilityId and GetUnitAbilityLevel(caster, abilityId) > 0 and ModernAbilityCatalog_GetOrderId(abilityId) == selectedOrderId then
            call BlzUnitDisableAbility(caster, abilityId, disabled, false)
        endif
        set entryIndex = entryIndex + 1
    endloop
endfunction

private function MAC_Execute takes player sourcePlayer, integer heroSlot, integer slot, real pointX, real pointY returns nothing
    local unit caster = ShamanCommon_GetHeroBySlot(heroSlot)
    local unit target = null
    local integer abilityId
    local integer actionKind
    local integer targetPolicy
    local integer orderId
    local boolean issued = false

    if caster == null or GetOwningPlayer(caster) != sourcePlayer then
        set sourcePlayer = null
        set caster = null
        return
    endif

    set abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(caster, slot)
    if abilityId == 0 or GetUnitAbilityLevel(caster, abilityId) <= 0 or not ModernAbilityCatalog_IsRuntimeReady(abilityId) then
        call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080That action is not ready for the modern bar yet.|r")
        set sourcePlayer = null
        set caster = null
        return
    endif

    set actionKind = ModernAbilityCatalog_GetActionKind(abilityId)
    set targetPolicy = ModernAbilityCatalog_GetTargetPolicy(abilityId)
    set orderId = ModernAbilityCatalog_GetOrderId(abilityId)

    call MAC_SetOrderCollisionsDisabled(caster, abilityId, true)
    if actionKind == ModernAbilityCatalog_ACTION_IMMEDIATE then
        set issued = IssueImmediateOrderById(caster, orderId)
    elseif actionKind == ModernAbilityCatalog_ACTION_UNIT then
        set target = ModernAbilityTargeting_ResolveUnit(caster, abilityId, pointX, pointY)
        if target != null then
            set issued = IssueTargetOrderById(caster, orderId, target)
        endif
    elseif actionKind == ModernAbilityCatalog_ACTION_POINT then
        set issued = IssuePointOrderById(caster, orderId, pointX, pointY)
    endif
    call MAC_SetOrderCollisionsDisabled(caster, abilityId, false)

    if not issued then
        if actionKind == ModernAbilityCatalog_ACTION_UNIT and target == null then
            call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080No valid target was found near that point.|r")
        else
            call DisplayTimedTextToPlayer(sourcePlayer, 0.00, 0.00, 2.00, "|cffff8080The ability could not be cast.|r")
        endif
    endif

    set sourcePlayer = null
    set caster = null
    set target = null
endfunction

private function MAC_SendCast takes integer heroSlot, integer slot, real pointX, real pointY returns nothing
    call BlzSendSyncData(MAC_SYNC_PREFIX, I2S(heroSlot) + "," + I2S(slot) + "," + R2S(pointX) + "," + R2S(pointY))
endfunction

public function CancelLocal takes player whichPlayer returns nothing
    local integer playerIndex

    if whichPlayer == null or whichPlayer != GetLocalPlayer() then
        set whichPlayer = null
        return
    endif

    set playerIndex = GetPlayerId(whichPlayer)
    set MAC_Targeting[playerIndex] = false
    set MAC_PendingHeroSlot[playerIndex] = 0
    set MAC_PendingSlot[playerIndex] = 0
    set whichPlayer = null
endfunction

public function IsTargetingLocal takes player whichPlayer returns boolean
    local boolean active = false

    if whichPlayer != null and whichPlayer == GetLocalPlayer() then
        set active = MAC_Targeting[GetPlayerId(whichPlayer)]
    endif
    set whichPlayer = null
    return active
endfunction

public function GetPendingAbilityId takes player whichPlayer returns integer
    local integer playerIndex
    local unit caster
    local integer abilityId = 0

    if whichPlayer == null or whichPlayer != GetLocalPlayer() then
        set whichPlayer = null
        return 0
    endif

    set playerIndex = GetPlayerId(whichPlayer)
    if MAC_Targeting[playerIndex] then
        set caster = ShamanCommon_GetHeroBySlot(MAC_PendingHeroSlot[playerIndex])
        set abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(caster, MAC_PendingSlot[playerIndex])
    endif

    set whichPlayer = null
    set caster = null
    return abilityId
endfunction

public function BeginLocal takes player whichPlayer, unit whichHero, integer slot returns nothing
    local integer playerIndex
    local integer heroSlot
    local integer abilityId
    local integer actionKind
    local integer targetPolicy

    if whichPlayer == null or whichHero == null or whichPlayer != GetLocalPlayer() or GetOwningPlayer(whichHero) != whichPlayer then
        set whichPlayer = null
        set whichHero = null
        return
    endif

    set playerIndex = GetPlayerId(whichPlayer)
    set heroSlot = ShamanCommon_GetHeroSlot(whichHero)
    set abilityId = ModernAbilityLoadout_GetEffectiveAbilityId(whichHero, slot)
    if heroSlot == ShamanCommon_HERO_SLOT_NONE or abilityId == 0 or not ModernAbilityCatalog_IsRuntimeReady(abilityId) then
        call DisplayTimedTextToPlayer(whichPlayer, 0.00, 0.00, 2.00, "|cffff8080That action is not ready for the modern bar yet.|r")
        set whichPlayer = null
        set whichHero = null
        return
    endif

    set actionKind = ModernAbilityCatalog_GetActionKind(abilityId)
    set targetPolicy = ModernAbilityCatalog_GetTargetPolicy(abilityId)
    if (actionKind == ModernAbilityCatalog_ACTION_UNIT and targetPolicy != ModernAbilityCatalog_TARGET_SELF and targetPolicy != ModernAbilityCatalog_TARGET_MELEE_AUTO) or actionKind == ModernAbilityCatalog_ACTION_POINT then
        set MAC_Targeting[playerIndex] = true
        set MAC_PendingHeroSlot[playerIndex] = heroSlot
        set MAC_PendingSlot[playerIndex] = slot
        call DisplayTimedTextToPlayer(whichPlayer, 0.00, 0.00, 2.00, "|cffffcc00Choose a world target. Right-click to cancel.|r")
    else
        call MAC_SendCast(heroSlot, slot, GetUnitX(whichHero), GetUnitY(whichHero))
    endif

    set whichPlayer = null
    set whichHero = null
endfunction

private function MAC_OnMouseDown takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer playerIndex = GetPlayerId(whichPlayer)
    local mousebuttontype mouseButton

    if whichPlayer == GetLocalPlayer() and MAC_Targeting[playerIndex] then
        set mouseButton = BlzGetTriggerPlayerMouseButton()
        if mouseButton == MOUSE_BUTTON_TYPE_RIGHT then
            call CancelLocal(whichPlayer)
        elseif mouseButton == MOUSE_BUTTON_TYPE_LEFT then
            call MAC_SendCast(MAC_PendingHeroSlot[playerIndex], MAC_PendingSlot[playerIndex], BlzGetTriggerPlayerMouseX(), BlzGetTriggerPlayerMouseY())
            set MAC_Targeting[playerIndex] = false
            set MAC_PendingHeroSlot[playerIndex] = 0
            set MAC_PendingSlot[playerIndex] = 0
        endif
    endif

    set mouseButton = null
    set whichPlayer = null
endfunction

private function MAC_OnSync takes nothing returns nothing
    local string data = BlzGetTriggerSyncData()
    local integer separator1 = MAC_FindSeparator(data, 0)
    local integer separator2
    local integer separator3
    local integer heroSlot
    local integer slot
    local real pointX
    local real pointY
    local player sourcePlayer = GetTriggerPlayer()

    if separator1 <= 0 then
        set sourcePlayer = null
        return
    endif
    set separator2 = MAC_FindSeparator(data, separator1 + 1)
    if separator2 <= separator1 then
        set sourcePlayer = null
        return
    endif
    set separator3 = MAC_FindSeparator(data, separator2 + 1)
    if separator3 <= separator2 then
        set sourcePlayer = null
        return
    endif

    set heroSlot = S2I(SubString(data, 0, separator1))
    set slot = S2I(SubString(data, separator1 + 1, separator2))
    set pointX = S2R(SubString(data, separator2 + 1, separator3))
    set pointY = S2R(SubString(data, separator3 + 1, StringLength(data)))
    if slot >= 1 and slot <= ModernAbilityLoadout_SLOT_COUNT then
        call MAC_Execute(sourcePlayer, heroSlot, slot, pointX, pointY)
    endif

    set sourcePlayer = null
endfunction

private function Init takes nothing returns nothing
    local integer playerIndex = 0

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerEvent(MAC_MouseTrigger, Player(playerIndex), EVENT_PLAYER_MOUSE_DOWN)
        call BlzTriggerRegisterPlayerSyncEvent(MAC_SyncTrigger, Player(playerIndex), MAC_SYNC_PREFIX, false)
        set playerIndex = playerIndex + 1
    endloop
    call TriggerAddAction(MAC_MouseTrigger, function MAC_OnMouseDown)
    call TriggerAddAction(MAC_SyncTrigger, function MAC_OnSync)
endfunction

endlibrary
