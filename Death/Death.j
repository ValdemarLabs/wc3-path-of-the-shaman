/**
    FallenHeroState

    Author: Valdemar
    Version:

    Description:
    Stores retained fallen-hero state independently from the high-level Death
    system so low-level consumers can reject fake corpses without requiring
    the full revival system.

    Credits:
    - Path of the Shaman Death system

    How to install:
    Import before Death and systems that query fallen-hero state.

    API:
    call FallenHeroState_SetFallen(whichHero, isFallen)
    call FallenHeroState_IsFallen(whichHero) returns boolean
    call FallenHeroState_IsAlive(whichUnit) returns boolean
    call FallenHeroState_IsDead(whichUnit) returns boolean
    call FallenHeroState_ForEach(callback)

**/
library FallenHeroState initializer Init

globals
    // All hero bodies currently retained by the Death system.
    private group FallenHeroState_Heroes = null
endglobals

public function SetFallen takes unit whichHero, boolean isFallen returns nothing
    if whichHero == null then
        return
    endif
    if isFallen then
        call GroupAddUnit(FallenHeroState_Heroes, whichHero)
    else
        call GroupRemoveUnit(FallenHeroState_Heroes, whichHero)
    endif
endfunction

public function IsFallen takes unit whichHero returns boolean
    return whichHero != null and IsUnitInGroup(whichHero, FallenHeroState_Heroes)
endfunction

public function IsAlive takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 and not IsUnitType(whichUnit, UNIT_TYPE_DEAD) and not FallenHeroState_IsFallen(whichUnit)
endfunction

public function IsDead takes unit whichUnit returns boolean
    return whichUnit != null and GetUnitTypeId(whichUnit) != 0 and (GetWidgetLife(whichUnit) <= 0.405 or IsUnitType(whichUnit, UNIT_TYPE_DEAD) or FallenHeroState_IsFallen(whichUnit))
endfunction

public function ForEach takes code callback returns nothing
    call ForGroup(FallenHeroState_Heroes, callback)
endfunction

private function Init takes nothing returns nothing
    set FallenHeroState_Heroes = CreateGroup()
endfunction

endlibrary

/**
    Death

    Author: Valdemar
    Version:

    Description:
    Intercepts configured lethal damage and presents the unit as a frozen corpse
    at one life, preventing immediate decay. A Revive item restores the nearest
    allied fallen unit or fatigued pet within 250 range. Hired non-hero companions remain
    revivable for 60 seconds before receiving a real death. Companion AI and AI party
    members can approach and use their own Revive items without a map-wide
    periodic unit scan. Other hero corpses receive the same visual protection
    but are removed after 60 seconds and cannot be revived through this system.

    Credits:
    - `Companions/Pet.j` retained-death animation handling
    - Old GUI HeroDeathResurrect triggers

    How to install:
    Import after AI, Companions, Pet, DamageEngine, Events, FallenHeroState,
    UnitDeathEvent, and Table. Disable the
    old HeroDeathResurrect GUI triggers. The Revive item must be `I00C` and
    grant the no-target, three-second cast ability `A0F4`.

    API:
    call Death_RegisterHero(whichHero)
    call Death_UnregisterHero(whichHero)
    call Death_IsFallen(whichHero) returns boolean
    call Death_ReviveAt(whichHero, x, y, lifePercent, manaPercent, showEffects) returns boolean
    call Death_RegisterReviveCallback(callback)

**/
library Death initializer Init requires Table, Companions, Pet, AI, DInventory, DamageEngine, Events, FallenHeroState, UnitDeathEvent

globals
    // Object data and tuning
    private constant integer DEATH_REVIVE_ITEM_ID = 'I00C'
    private constant integer DEATH_REVIVE_ABILITY_ID = 'A0F4'
    private constant real DEATH_REVIVE_RANGE = 250.00
    private constant real DEATH_AI_SEARCH_RANGE = 1200.00
    private constant real DEATH_AI_INTERVAL = 0.50
    private constant real DEATH_FREEZE_LEAD_TIME = 0.10
    private constant real DEATH_MIN_FREEZE_DELAY = 0.03
    private constant real DEATH_RETAINED_CORPSE_DURATION = 60.00
    private constant integer DEATH_MAX_REVIVE_CALLBACKS = 10
    private constant string DEATH_REVIVE_EFFECT = "Abilities\\Spells\\Human\\Resurrect\\ResurrectTarget.mdl"

    private group Death_FakeCorpses = null
    private group Death_ManagedFallenHeroes = null
    private group Death_RetainedCorpses = null
    private group Death_RegisteredHeroes = null
    private group Death_ExpiringHiredCorpses = null
    private group Death_SearchGroup = null
    private timer Death_AITimer = null
    private integer Death_FallenCount = 0

    private Table Death_FreezeTimerHero = 0
    private Table Death_HeroFreezeTimer = 0
    private Table Death_RemoveTimerHero = 0
    private Table Death_HeroRemoveTimer = 0
    private Table Death_FallTimerHero = 0
    private Table Death_FallTimerKiller = 0
    private Table Death_ReviverTarget = 0
    private Table Death_TargetReviver = 0
    private Table Death_CastTarget = 0
    private Table Death_CastingReviver = 0

    private trigger array Death_ReviveCallbacks
    private integer Death_ReviveCallbackCount = 0
    public unit EventHero = null

    private unit Death_FindCaster = null
    private unit Death_FindResult = null
    private real Death_FindX = 0.00
    private real Death_FindY = 0.00
    private real Death_FindRangeSquared = 0.00
    private real Death_FindDistanceSquared = 0.00

    private unit Death_AIFallen = null
    private unit Death_AIResult = null
    private real Death_AIDistanceSquared = 0.00
endglobals

private function Death_IsAlive takes unit whichUnit returns boolean
    return FallenHeroState_IsAlive(whichUnit)
endfunction

private function Death_IsHiredUnit takes unit whichUnit returns boolean
    return whichUnit != null and not IsUnitType(whichUnit, UNIT_TYPE_HERO) and udg_Companion_Group != null and IsUnitInGroup(whichUnit, udg_Companion_Group) and Companions_IsControlled(whichUnit)
endfunction

private function Death_IsManagedUnit takes unit whichHero returns boolean
    local player owner
    local boolean managed = false

    if Death_IsHiredUnit(whichHero) then
        return true
    endif
    if whichHero == null or not IsUnitType(whichHero, UNIT_TYPE_HERO) then
        return false
    endif
    set owner = GetOwningPlayer(whichHero)
    set managed = IsUnitInGroup(whichHero, Death_RegisteredHeroes) or GetPlayerController(owner) == MAP_CONTROL_USER or Companions_IsControlled(whichHero) or AI_GetInstance(whichHero) > 0
    set owner = null
    return managed
endfunction

private function Death_GetReviveItem takes unit whichUnit returns item
    local integer slot = 0
    local integer inventorySize
    local item slotItem

    if whichUnit == null then
        return null
    endif
    set inventorySize = UnitInventorySize(whichUnit)
    if inventorySize > bj_MAX_INVENTORY then
        set inventorySize = bj_MAX_INVENTORY
    endif
    loop
        exitwhen slot >= inventorySize
        set slotItem = UnitItemInSlot(whichUnit, slot)
        if slotItem != null and GetItemTypeId(slotItem) == DEATH_REVIVE_ITEM_ID then
            set slotItem = null
            return UnitItemInSlot(whichUnit, slot)
        endif
        set slot = slot + 1
    endloop
    set slotItem = null
    return null
endfunction

private function Death_IsInReviveRange takes unit caster, unit fallen returns boolean
    local real dx
    local real dy

    if caster == null or fallen == null then
        return false
    endif
    set dx = GetUnitX(caster) - GetUnitX(fallen)
    set dy = GetUnitY(caster) - GetUnitY(fallen)
    return dx * dx + dy * dy <= DEATH_REVIVE_RANGE * DEATH_REVIVE_RANGE
endfunction

private function Death_IsValidCastTarget takes unit caster, unit fallen returns boolean
    return caster != null and fallen != null and (Pet_IsDead(fallen) or (FallenHeroState_IsFallen(fallen) and not Death_IsAlive(fallen))) and IsUnitAlly(fallen, GetOwningPlayer(caster)) and Death_IsInReviveRange(caster, fallen)
endfunction

private function Death_FindClosestFallenEnum takes nothing returns nothing
    local unit fallen = GetEnumUnit()
    local real dx
    local real dy
    local real distanceSquared

    if fallen != null and not Death_IsAlive(fallen) and IsUnitAlly(fallen, GetOwningPlayer(Death_FindCaster)) then
        set dx = GetUnitX(fallen) - Death_FindX
        set dy = GetUnitY(fallen) - Death_FindY
        set distanceSquared = dx * dx + dy * dy
        if distanceSquared <= Death_FindRangeSquared and (Death_FindResult == null or distanceSquared < Death_FindDistanceSquared) then
            set Death_FindResult = fallen
            set Death_FindDistanceSquared = distanceSquared
        endif
    endif
    set fallen = null
endfunction

private function Death_FindClosestFallen takes unit caster, real range returns unit
    local unit pet
    local real dx
    local real dy
    local real distanceSquared

    set Death_FindCaster = caster
    set Death_FindResult = null
    set Death_FindX = GetUnitX(caster)
    set Death_FindY = GetUnitY(caster)
    set Death_FindRangeSquared = range * range
    set Death_FindDistanceSquared = Death_FindRangeSquared + 1.00
    call ForGroup(Death_ManagedFallenHeroes, function Death_FindClosestFallenEnum)
    set pet = udg_TamedUnit
    if Pet_IsDead(pet) and IsUnitAlly(pet, GetOwningPlayer(caster)) then
        set dx = GetUnitX(pet) - Death_FindX
        set dy = GetUnitY(pet) - Death_FindY
        set distanceSquared = dx * dx + dy * dy
        if distanceSquared <= Death_FindRangeSquared and (Death_FindResult == null or distanceSquared < Death_FindDistanceSquared) then
            set Death_FindResult = pet
            set Death_FindDistanceSquared = distanceSquared
        endif
    endif
    set Death_FindCaster = null
    set pet = null
    return Death_FindResult
endfunction

private function Death_ClearReviver takes unit reviver returns nothing
    local integer reviverId
    local unit fallen

    if reviver == null then
        return
    endif
    set reviverId = GetHandleId(reviver)
    set fallen = Death_ReviverTarget.unit[reviverId]
    if fallen != null and Death_TargetReviver.unit[GetHandleId(fallen)] == reviver then
        call Death_TargetReviver.unit.remove(GetHandleId(fallen))
    endif
    call Death_ReviverTarget.unit.remove(reviverId)
    call Death_CastTarget.unit.remove(reviverId)
    call Death_CastingReviver.boolean.remove(reviverId)
    set fallen = null
endfunction

private function Death_ClearFallenReservation takes unit fallen returns nothing
    local unit reviver

    if fallen == null then
        return
    endif
    set reviver = Death_TargetReviver.unit[GetHandleId(fallen)]
    if reviver != null then
        call Death_ClearReviver(reviver)
    endif
    call Death_TargetReviver.unit.remove(GetHandleId(fallen))
    set reviver = null
endfunction

private function Death_RunReviveCallbacks takes nothing returns nothing
    local integer callbackIndex = 0

    loop
        exitwhen callbackIndex >= Death_ReviveCallbackCount
        if IsTriggerEnabled(Death_ReviveCallbacks[callbackIndex]) and TriggerEvaluate(Death_ReviveCallbacks[callbackIndex]) then
            call TriggerExecute(Death_ReviveCallbacks[callbackIndex])
        endif
        set callbackIndex = callbackIndex + 1
    endloop
endfunction

private function Death_CancelFreezeTimer takes unit whichHero returns nothing
    local integer heroId
    local timer freezeTimer

    if whichHero == null then
        return
    endif
    set heroId = GetHandleId(whichHero)
    set freezeTimer = Death_HeroFreezeTimer.timer[heroId]
    if freezeTimer != null then
        call Death_FreezeTimerHero.unit.remove(GetHandleId(freezeTimer))
        call Death_HeroFreezeTimer.timer.remove(heroId)
        call PauseTimer(freezeTimer)
        call DestroyTimer(freezeTimer)
    endif
    set freezeTimer = null
endfunction

private function Death_CancelRemoveTimer takes unit whichHero returns nothing
    local integer heroId
    local timer removeTimer

    if whichHero == null then
        return
    endif
    set heroId = GetHandleId(whichHero)
    set removeTimer = Death_HeroRemoveTimer.timer[heroId]
    if removeTimer != null then
        call Death_RemoveTimerHero.unit.remove(GetHandleId(removeTimer))
        call Death_HeroRemoveTimer.timer.remove(heroId)
        call PauseTimer(removeTimer)
        call DestroyTimer(removeTimer)
    endif
    set removeTimer = null
endfunction

private function Death_RestoreUnitState takes unit whichHero returns nothing
    call UnitSuspendDecay(whichHero, false)
    call SetUnitInvulnerable(whichHero, false)
    call PauseUnit(whichHero, false)
    call SetUnitTimeScale(whichHero, 1.00)
    call SetUnitPathing(whichHero, true)
    call ResetUnitAnimation(whichHero)
    call SetUnitAnimation(whichHero, "stand")
endfunction

private function Death_ReleaseCorpse takes unit whichHero returns boolean
    if whichHero == null or not IsUnitInGroup(whichHero, Death_ManagedFallenHeroes) then
        return false
    endif
    call Death_CancelFreezeTimer(whichHero)
    call Death_CancelRemoveTimer(whichHero)
    call GroupRemoveUnit(Death_FakeCorpses, whichHero)
    call GroupRemoveUnit(Death_RetainedCorpses, whichHero)
    call GroupRemoveUnit(Death_ExpiringHiredCorpses, whichHero)

    call Death_ClearFallenReservation(whichHero)
    call GroupRemoveUnit(Death_ManagedFallenHeroes, whichHero)
    call FallenHeroState_SetFallen(whichHero, false)
    set Death_FallenCount = Death_FallenCount - 1
    if Death_FallenCount <= 0 then
        set Death_FallenCount = 0
    endif

    call Death_RestoreUnitState(whichHero)
    set Death_EventHero = whichHero
    call Death_RunReviveCallbacks()
    set Death_EventHero = null
    return true
endfunction

private function Death_ReleaseUnmanagedCorpse takes unit whichHero returns boolean
    if whichHero == null or IsUnitInGroup(whichHero, Death_ManagedFallenHeroes) or not IsUnitInGroup(whichHero, Death_RetainedCorpses) then
        return false
    endif
    call Death_CancelFreezeTimer(whichHero)
    call Death_CancelRemoveTimer(whichHero)
    call GroupRemoveUnit(Death_FakeCorpses, whichHero)
    call GroupRemoveUnit(Death_RetainedCorpses, whichHero)
    call GroupRemoveUnit(Death_ExpiringHiredCorpses, whichHero)
    call FallenHeroState_SetFallen(whichHero, false)
    call Death_RestoreUnitState(whichHero)
    return true
endfunction

public function ReviveAt takes unit whichHero, real x, real y, real lifePercent, real manaPercent, boolean showEffects returns boolean
    local boolean revived

    if Pet_IsDead(whichHero) then
        return Pet_Revive(whichHero, lifePercent, manaPercent, showEffects)
    endif
    if whichHero == null or not IsUnitInGroup(whichHero, Death_ManagedFallenHeroes) or Death_IsAlive(whichHero) then
        return false
    endif
    if IsUnitInGroup(whichHero, Death_FakeCorpses) and AI_GetInstance(whichHero) > 0 then
        set revived = AI_ReviveAt(whichHero, x, y, showEffects)
    elseif IsUnitInGroup(whichHero, Death_FakeCorpses) then
        call SetUnitPosition(whichHero, x, y)
        if showEffects then
            call DestroyEffect(AddSpecialEffectTarget(DEATH_REVIVE_EFFECT, whichHero, "origin"))
        endif
        set revived = true
    elseif AI_GetInstance(whichHero) > 0 then
        set revived = AI_ReviveAt(whichHero, x, y, showEffects)
    else
        set revived = ReviveHero(whichHero, x, y, showEffects)
    endif
    if revived then
        call SetWidgetLife(whichHero, GetUnitState(whichHero, UNIT_STATE_MAX_LIFE) * lifePercent * 0.01)
        call SetUnitState(whichHero, UNIT_STATE_MANA, GetUnitState(whichHero, UNIT_STATE_MAX_MANA) * manaPercent * 0.01)
        call Death_ReleaseCorpse(whichHero)
    endif
    return revived
endfunction

private function Death_FreezeHero takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit whichHero = Death_FreezeTimerHero.unit[timerId]

    if whichHero != null and IsUnitInGroup(whichHero, Death_RetainedCorpses) then
        call PauseUnit(whichHero, true)
        call SetUnitTimeScale(whichHero, 0.00)
        call SetUnitPathing(whichHero, false)
    endif
    if whichHero != null and Death_HeroFreezeTimer.timer[GetHandleId(whichHero)] == expired then
        call Death_HeroFreezeTimer.timer.remove(GetHandleId(whichHero))
    endif
    call Death_FreezeTimerHero.unit.remove(timerId)
    call DestroyTimer(expired)
    set whichHero = null
    set expired = null
endfunction

private function Death_StartFreezeTimer takes unit whichHero returns nothing
    local timer freezeTimer = CreateTimer()
    local real freezeDelay = BlzGetUnitRealField(whichHero, UNIT_RF_DEATH_TIME) - DEATH_FREEZE_LEAD_TIME

    if freezeDelay < DEATH_MIN_FREEZE_DELAY then
        set freezeDelay = DEATH_MIN_FREEZE_DELAY
    endif
    set Death_FreezeTimerHero.unit[GetHandleId(freezeTimer)] = whichHero
    set Death_HeroFreezeTimer.timer[GetHandleId(whichHero)] = freezeTimer
    call TimerStart(freezeTimer, freezeDelay, false, function Death_FreezeHero)
    set freezeTimer = null
endfunction

private function Death_ExpireRetainedCorpse takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit whichHero = Death_RemoveTimerHero.unit[timerId]
    local boolean expiringHired = whichHero != null and IsUnitInGroup(whichHero, Death_ExpiringHiredCorpses)

    call Death_RemoveTimerHero.unit.remove(timerId)
    if whichHero != null and Death_HeroRemoveTimer.timer[GetHandleId(whichHero)] == expired then
        call Death_HeroRemoveTimer.timer.remove(GetHandleId(whichHero))
    endif
    if whichHero != null and IsUnitInGroup(whichHero, Death_RetainedCorpses) and (expiringHired or not IsUnitInGroup(whichHero, Death_ManagedFallenHeroes)) then
        call Death_CancelFreezeTimer(whichHero)
        call Death_ClearFallenReservation(whichHero)
        call GroupRemoveUnit(Death_FakeCorpses, whichHero)
        call GroupRemoveUnit(Death_RetainedCorpses, whichHero)
        call GroupRemoveUnit(Death_ExpiringHiredCorpses, whichHero)
        if IsUnitInGroup(whichHero, Death_ManagedFallenHeroes) then
            call GroupRemoveUnit(Death_ManagedFallenHeroes, whichHero)
            set Death_FallenCount = Death_FallenCount - 1
            if Death_FallenCount <= 0 then
                set Death_FallenCount = 0
            endif
        endif
        call FallenHeroState_SetFallen(whichHero, false)
        call UnitSuspendDecay(whichHero, false)
        call SetUnitInvulnerable(whichHero, false)
        if expiringHired then
            call PauseUnit(whichHero, false)
            call SetUnitTimeScale(whichHero, 1.00)
            call SetUnitPathing(whichHero, true)
            call AI_UnregisterUnit(whichHero)
            call KillUnit(whichHero)
        else
            call RemoveUnit(whichHero)
        endif
    endif
    call DestroyTimer(expired)
    set whichHero = null
    set expired = null
endfunction

private function Death_StartRetainedExpiryTimer takes unit whichHero returns nothing
    local timer removeTimer = CreateTimer()

    set Death_RemoveTimerHero.unit[GetHandleId(removeTimer)] = whichHero
    set Death_HeroRemoveTimer.timer[GetHandleId(whichHero)] = removeTimer
    call TimerStart(removeTimer, DEATH_RETAINED_CORPSE_DURATION, false, function Death_ExpireRetainedCorpse)
    set removeTimer = null
endfunction

private function Death_CanAIRevive takes unit reviver, unit fallen returns boolean
    local player fallenOwner
    local boolean allowed = false

    if reviver == null or fallen == null or not Death_IsAlive(reviver) or not IsUnitType(reviver, UNIT_TYPE_HERO) or AI_GetInstance(reviver) <= 0 then
        return false
    endif
    if not IsUnitAlly(fallen, GetOwningPlayer(reviver)) then
        return false
    endif
    if Death_GetReviveItem(reviver) == null and not DInvEnsureItemTypeInVanillaInventory(reviver, DEATH_REVIVE_ITEM_ID) then
        return false
    endif
    if Death_GetReviveItem(reviver) == null then
        return false
    endif
    if Companions_IsControlled(reviver) then
        set fallenOwner = GetOwningPlayer(fallen)
        set allowed = Companions_IsControlled(fallen) or GetPlayerController(fallenOwner) == MAP_CONTROL_USER
        set fallenOwner = null
        return allowed
    endif
    return AI_ArePartyMembers(reviver, fallen)
endfunction

private function Death_FindAIReviverEnum takes nothing returns nothing
    local unit candidate = GetEnumUnit()
    local unit reservedTarget
    local real dx
    local real dy
    local real distanceSquared

    if Death_CanAIRevive(candidate, Death_AIFallen) then
        set reservedTarget = Death_ReviverTarget.unit[GetHandleId(candidate)]
        if reservedTarget == null or reservedTarget == Death_AIFallen then
            set dx = GetUnitX(candidate) - GetUnitX(Death_AIFallen)
            set dy = GetUnitY(candidate) - GetUnitY(Death_AIFallen)
            set distanceSquared = dx * dx + dy * dy
            if Death_AIResult == null or distanceSquared < Death_AIDistanceSquared then
                set Death_AIResult = candidate
                set Death_AIDistanceSquared = distanceSquared
            endif
        endif
    endif
    set reservedTarget = null
    set candidate = null
endfunction

private function Death_FindAIReviver takes unit fallen returns unit
    set Death_AIFallen = fallen
    set Death_AIResult = null
    set Death_AIDistanceSquared = DEATH_AI_SEARCH_RANGE * DEATH_AI_SEARCH_RANGE + 1.00
    call GroupEnumUnitsInRange(Death_SearchGroup, GetUnitX(fallen), GetUnitY(fallen), DEATH_AI_SEARCH_RANGE, null)
    call ForGroup(Death_SearchGroup, function Death_FindAIReviverEnum)
    call GroupClear(Death_SearchGroup)
    set Death_AIFallen = null
    return Death_AIResult
endfunction

private function Death_ProcessFallenAIUnit takes unit fallen returns nothing
    local unit reviver
    local item reviveItem

    if fallen != null and IsUnitInGroup(fallen, Death_FakeCorpses) then
        call SetWidgetLife(fallen, 1.00)
    endif
    if fallen == null then
        return
    endif
    if not Pet_IsDead(fallen) and Death_IsAlive(fallen) then
        set reviver = Death_TargetReviver.unit[GetHandleId(fallen)]
        if reviver != null then
            call Death_ClearReviver(reviver)
        endif
        set reviver = null
        return
    endif
    set reviver = Death_TargetReviver.unit[GetHandleId(fallen)]
    if reviver != null and not Death_CastingReviver.boolean[GetHandleId(reviver)] and not Death_CanAIRevive(reviver, fallen) then
        call Death_ClearReviver(reviver)
        set reviver = null
    endif
    if reviver == null then
        set reviver = Death_FindAIReviver(fallen)
        if reviver != null then
            set Death_ReviverTarget.unit[GetHandleId(reviver)] = fallen
            set Death_TargetReviver.unit[GetHandleId(fallen)] = reviver
        endif
    endif
    if reviver != null and not Death_CastingReviver.boolean[GetHandleId(reviver)] then
        if Death_IsInReviveRange(reviver, fallen) then
            set reviveItem = Death_GetReviveItem(reviver)
            if reviveItem != null and UnitUseItem(reviver, reviveItem) then
                set Death_CastTarget.unit[GetHandleId(reviver)] = fallen
                set Death_CastingReviver.boolean[GetHandleId(reviver)] = true
            endif
        else
            call IssuePointOrder(reviver, "move", GetUnitX(fallen), GetUnitY(fallen))
        endif
    endif

    set reviveItem = null
    set reviver = null
endfunction

private function Death_ProcessFallenAIEnum takes nothing returns nothing
    local unit fallen = GetEnumUnit()

    call Death_ProcessFallenAIUnit(fallen)

    set fallen = null
endfunction

private function Death_ProcessFallenAI takes nothing returns nothing
    local unit pet = udg_TamedUnit

    call ForGroup(Death_ManagedFallenHeroes, function Death_ProcessFallenAIEnum)
    if Pet_IsDead(pet) then
        call Death_ProcessFallenAIUnit(pet)
    endif
    set pet = null
endfunction

private function Death_RetainUnit takes unit whichHero, boolean managed returns nothing
    call GroupAddUnit(Death_RetainedCorpses, whichHero)
    call FallenHeroState_SetFallen(whichHero, true)
    if GetWidgetLife(whichHero) <= 0.405 then
        call UnitSuspendDecay(whichHero, true)
    endif
    call IssueImmediateOrder(whichHero, "stop")
    call SetUnitTimeScale(whichHero, 1.00)
    call SetUnitAnimation(whichHero, "death")
    call PauseUnit(whichHero, true)
    call SetUnitPathing(whichHero, false)
    call Death_StartFreezeTimer(whichHero)
    if managed then
        call GroupAddUnit(Death_ManagedFallenHeroes, whichHero)
        set Death_FallenCount = Death_FallenCount + 1
        if Death_IsHiredUnit(whichHero) then
            call GroupAddUnit(Death_ExpiringHiredCorpses, whichHero)
            call Death_StartRetainedExpiryTimer(whichHero)
        endif
    else
        call Death_StartRetainedExpiryTimer(whichHero)
    endif
endfunction

private function Death_DispatchFakeFall takes nothing returns nothing
    local timer expired = GetExpiredTimer()
    local integer timerId = GetHandleId(expired)
    local unit whichHero = Death_FallTimerHero.unit[timerId]
    local unit killer = Death_FallTimerKiller.unit[timerId]

    call Death_FallTimerHero.unit.remove(timerId)
    call Death_FallTimerKiller.unit.remove(timerId)
    if whichHero != null and IsUnitInGroup(whichHero, Death_RetainedCorpses) then
        call SetWidgetLife(whichHero, 1.00)
        call UnitDeathEvent_Fire(whichHero, killer)
    endif
    call DestroyTimer(expired)
    set killer = null
    set whichHero = null
    set expired = null
endfunction

private function Death_StartFakeFall takes unit whichHero, unit killer returns nothing
    local timer dispatchTimer = CreateTimer()

    call GroupAddUnit(Death_FakeCorpses, whichHero)
    call SetUnitInvulnerable(whichHero, true)
    call Death_RetainUnit(whichHero, Death_IsManagedUnit(whichHero))
    set Death_FallTimerHero.unit[GetHandleId(dispatchTimer)] = whichHero
    set Death_FallTimerKiller.unit[GetHandleId(dispatchTimer)] = killer
    call TimerStart(dispatchTimer, 0.00, false, function Death_DispatchFakeFall)
    set dispatchTimer = null
endfunction

private function Death_OnLethalDamage takes nothing returns nothing
    local unit whichHero = udg_DamageEventTarget
    local unit killer = udg_DamageEventSource

    if whichHero != null and (Death_IsHiredUnit(whichHero) or (IsUnitType(whichHero, UNIT_TYPE_HERO) and (AI_GetInstance(whichHero) <= 0 or AI_UsesFakeDeath(whichHero)))) and not IsUnitInGroup(whichHero, Death_RetainedCorpses) then
        set udg_LethalDamageHP = 1.00
        call Death_StartFakeFall(whichHero, killer)
    endif
    set killer = null
    set whichHero = null
endfunction

private function Death_OnHeroDeath takes nothing returns nothing
    local unit whichHero = UnitDeathEvent_GetDyingUnit()

    if whichHero != null and IsUnitType(whichHero, UNIT_TYPE_HERO) and not IsUnitInGroup(whichHero, Death_RetainedCorpses) then
        call Death_RetainUnit(whichHero, Death_IsManagedUnit(whichHero))
    endif
    set whichHero = null
endfunction

private function Death_OnHeroRevived takes nothing returns nothing
    local unit whichHero = GetRevivingUnit()

    if whichHero == null then
        set whichHero = GetTriggerUnit()
    endif
    if not Death_ReleaseCorpse(whichHero) then
        call Death_ReleaseUnmanagedCorpse(whichHero)
    endif
    set whichHero = null
endfunction

private function Death_OnReviveChannel takes nothing returns nothing
    local unit caster
    local unit fallen

    if GetSpellAbilityId() != DEATH_REVIVE_ABILITY_ID then
        return
    endif
    set caster = GetTriggerUnit()
    set fallen = Death_FindClosestFallen(caster, DEATH_REVIVE_RANGE)
    if fallen == null then
        call IssueImmediateOrder(caster, "stop")
        call DisplayTimedTextToPlayer(GetOwningPlayer(caster), 0.00, 0.00, 2.00, "|cffff4040No fallen allied unit is close enough to revive.|r")
    else
        set Death_CastTarget.unit[GetHandleId(caster)] = fallen
        set Death_CastingReviver.boolean[GetHandleId(caster)] = true
    endif
    set fallen = null
    set caster = null
endfunction

private function Death_OnReviveEffect takes nothing returns nothing
    local unit caster
    local unit fallen
    local real x
    local real y

    if GetSpellAbilityId() != DEATH_REVIVE_ABILITY_ID then
        return
    endif
    set caster = GetTriggerUnit()
    set fallen = Death_CastTarget.unit[GetHandleId(caster)]
    if not Death_IsValidCastTarget(caster, fallen) then
        set fallen = Death_FindClosestFallen(caster, DEATH_REVIVE_RANGE)
    endif
    if fallen == null then
        call DisplayTimedTextToPlayer(GetOwningPlayer(caster), 0.00, 0.00, 2.00, "|cffff4040The fallen unit is no longer in revive range.|r")
    else
        set x = GetUnitX(fallen)
        set y = GetUnitY(fallen)
        call Death_ReviveAt(fallen, x, y, 50.00, 50.00, true)
    endif
    call Death_ClearReviver(caster)
    set fallen = null
    set caster = null
endfunction

private function Death_OnReviveEndcast takes nothing returns nothing
    local unit caster

    if GetSpellAbilityId() != DEATH_REVIVE_ABILITY_ID then
        return
    endif
    set caster = GetTriggerUnit()
    call Death_ClearReviver(caster)
    set caster = null
endfunction

public function RegisterHero takes unit whichHero returns nothing
    if whichHero != null and IsUnitType(whichHero, UNIT_TYPE_HERO) then
        call GroupAddUnit(Death_RegisteredHeroes, whichHero)
    endif
endfunction

public function UnregisterHero takes unit whichHero returns nothing
    if whichHero != null then
        call GroupRemoveUnit(Death_RegisteredHeroes, whichHero)
    endif
endfunction

public function IsFallen takes unit whichHero returns boolean
    return FallenHeroState_IsFallen(whichHero)
endfunction

public function RegisterReviveCallback takes code callback returns nothing
    local trigger callbackTrigger

    if Death_ReviveCallbackCount >= DEATH_MAX_REVIVE_CALLBACKS then
        call BJDebugMsg("[Death] ERROR: Maximum revive callbacks reached.")
        return
    endif
    set callbackTrigger = CreateTrigger()
    call TriggerAddAction(callbackTrigger, callback)
    set Death_ReviveCallbacks[Death_ReviveCallbackCount] = callbackTrigger
    set Death_ReviveCallbackCount = Death_ReviveCallbackCount + 1
    set callbackTrigger = null
endfunction

private function Init takes nothing returns nothing
    set Death_FakeCorpses = CreateGroup()
    set Death_ManagedFallenHeroes = CreateGroup()
    set Death_RetainedCorpses = CreateGroup()
    set Death_RegisteredHeroes = CreateGroup()
    set Death_ExpiringHiredCorpses = CreateGroup()
    set Death_SearchGroup = CreateGroup()
    set Death_AITimer = CreateTimer()
    set Death_FreezeTimerHero = Table.create()
    set Death_HeroFreezeTimer = Table.create()
    set Death_RemoveTimerHero = Table.create()
    set Death_HeroRemoveTimer = Table.create()
    set Death_FallTimerHero = Table.create()
    set Death_FallTimerKiller = Table.create()
    set Death_ReviverTarget = Table.create()
    set Death_TargetReviver = Table.create()
    set Death_CastTarget = Table.create()
    set Death_CastingReviver = Table.create()
    call TimerStart(Death_AITimer, DEATH_AI_INTERVAL, true, function Death_ProcessFallenAI)

    call RegisterDamageEngine(function Death_OnLethalDamage, "Lethal", 1.00)
    call UnitDeathEvent_Register(function Death_OnHeroDeath)
    call Events_RegisterPlayerUnitEvent(function Death_OnHeroRevived, EVENT_PLAYER_HERO_REVIVE_FINISH)
    call Events_RegisterPlayerUnitEvent(function Death_OnReviveChannel, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call Events_RegisterPlayerUnitEvent(function Death_OnReviveEffect, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call Events_RegisterPlayerUnitEvent(function Death_OnReviveEndcast, EVENT_PLAYER_UNIT_SPELL_ENDCAST)
endfunction

endlibrary
