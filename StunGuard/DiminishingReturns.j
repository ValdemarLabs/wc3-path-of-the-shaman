/**
    DiminishingReturns

    Author: Valdemar
    Version: 1.0

    Description:
    Applies shared, per-target diminishing returns to roots, stuns,
    incapacitates, disorients, and silences. Active abilities are classified
    from known buff rawcodes in their Object Editor Buffs field. Known PotS
    and stock fallbacks cover hardcoded cases, and Bash passives are discovered
    from their Bash-specific chance field.

    Warcraft III has no general buff-added event and does not expose an
    arbitrary buff's semantic category. Unknown custom buffs and triggered
    controls which never cast an ability require the optional integration API.
    An ability with several recognized CC buffs is classified by the first
    matching category. Generic AoE trimming is limited to dispellable buffs;
    non-dispellable AoE controls need a verified per-target replacement.

    Credits:
    - StunGuard and DiminishingReturns_draft
    - ScrewTheTrees' Warcraft 3 WE Ability Insight reference

    How to install:
    Import after `Table` (TableV6), `Events`, and `UnitDeathEvent`, and
    import instead of `StunGuard`. If both libraries are present,
    DiminishingReturns disables itself to prevent double mutation of ability
    fields.

    AoE War Stomp replacement uses patch 3.0's `ndum` unit and the existing
    `A000` zero-damage instant Storm Bolt dummy ability. The Gameplay Constant
    `CanInterruptByZeroDurationBuffs` must be FALSE because native AoE stun is
    suppressed to 0.01 seconds before per-target replacement.

    API:
    - DR_ROOTS, DR_STUNS, DR_INCAPACITATES, DR_DISORIENTS, DR_SILENCES
    - DR_GetStage(target, category): 0 fresh, 1 half, 2 quarter, 3 immune
    - DR_GetDurationScale(target, category)
    - DR_GetResetRemaining(target, category): -1 while a tracked CC is active
    - DR_Reset(target, category)
    - DR_SetEnabled(enabled)
    - DR_IsEnabled()
    - DR_SetDebugMode(enabled), DR_IsDebugMode()
    - DR_SetTestMode(enabled), DR_IsTestMode()
      Debug mode reports configuration and failures. Test mode additionally
      traces classification, category, stage, scale, confirmation, and reset.
    - DR_CommitApplied(target, category, buffId): optional triggered-CC seam;
      callers must query the scale before applying the scaled effect, then call
      this only after the buff is confirmed on the target
    - DR_GetTrackedStateCount(), DR_GetPendingCount(), DR_GetTrimCount()
**/
library DiminishingReturns initializer Init requires Table, Events, UnitDeathEvent

globals
    // Public categories.
    constant integer DR_ROOTS = 1
    constant integer DR_STUNS = 2
    constant integer DR_INCAPACITATES = 3
    constant integer DR_DISORIENTS = 4
    constant integer DR_SILENCES = 5

    // Configuration.
    private constant boolean DR_DEBUG_MODE_DEFAULT = true
    private constant boolean DR_TEST_MODE_DEFAULT = true
    private constant real DR_RESET_WINDOW = 18.00
    private constant real DR_PULSE_INTERVAL = 0.05
    private constant real DR_SUPPRESS_DURATION = 0.01
    private constant real DR_TARGET_CONFIRM_GRACE = 1.00
    private constant real DR_AREA_CONFIRM_TIMEOUT = 1.00
    private constant real DR_PASSIVE_CACHE_SECONDS = 2.00
    private constant integer DR_MAX_UNIT_ABILITIES = 64
    private constant integer DR_DUMMY_ID = 'ndum'
    private constant integer DR_DUMMY_STUN_ID = 'A0F8'

    private constant integer DR_MODE_AUTO = 0
    private constant integer DR_MODE_STOMP = 1
    private constant integer DR_PENDING_TARGET = 1
    private constant integer DR_PENDING_PASSIVE = 2

    private constant integer DR_META_CATEGORY = 0
    private constant integer DR_META_BUFF = 1
    private constant integer DR_META_TRIM_SAFE = 2
    private constant integer DR_META_CACHED = 3
    private constant integer DR_META_STRIDE = 4

    private Table DR_StateIndex = 0
    private Table DR_AbilityCache = 0
    private Table DR_KnownAbilities = 0
    private Table DR_TargetMutationByAbility = 0
    private Table DR_AreaMutationByAbility = 0
    private Table DR_PassivePendingBySource = 0
    private Table DR_PassiveCache = 0
    private Table DR_TrimIndex = 0
    private Table DR_InternalDummy = 0

    private abilitystringlevelfield DR_ABILITY_SLF_BUFFS = ConvertAbilityStringLevelField('abuf')
    private timer DR_Clock = null
    private timer DR_PulseTimer = null
    private boolean DR_PulseRunning = false
    private boolean DR_Enabled = true
    private boolean DR_StunGuardConflict = false
    private boolean DR_DebugMode = DR_DEBUG_MODE_DEFAULT
    private boolean DR_TestMode = DR_TEST_MODE_DEFAULT

    private integer DR_StateHead = 0
    private integer DR_PendingHead = 0
    private integer DR_AreaHead = 0
    private integer DR_TrimHead = 0
    private integer DR_StateCount = 0
    private integer DR_PendingCount = 0
    private integer DR_AreaCount = 0
    private integer DR_TrimCount = 0

    private integer array DR_BuffId
    private integer array DR_BuffCategory
    private string array DR_BuffCode
    private boolean array DR_BuffTrimSafe
    private integer DR_BuffCount = 0

    private ability DR_FoundPassiveAbility = null
    private integer DR_FoundPassiveId = 0
    private integer DR_FoundPassiveLevel = 0
    private integer DR_FoundPassiveBuff = 0
endglobals

private struct DRState
    unit target
    integer category
    integer stage
    integer extraBuff
    boolean active
    real resetAt
    integer previous
    integer next

    static method create takes unit target, integer category returns thistype
        local thistype this = thistype.allocate()
        set .target = target
        set .category = category
        set .stage = 0
        set .extraBuff = 0
        set .active = false
        set .resetAt = 0.00
        set .previous = 0
        set .next = 0
        return this
    endmethod

    method release takes nothing returns nothing
        set .target = null
        call .destroy()
    endmethod
endstruct

private struct DRPending
    unit source
    unit target
    ability whichAbility
    integer abilityId
    integer level
    integer category
    integer buffId
    integer kind
    real scale
    real originalNormal
    real originalHero
    real notBefore
    real deadline
    boolean hadBuff
    boolean acceptExisting
    boolean ownsMutation
    integer previous
    integer next

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set .source = null
        set .target = null
        set .whichAbility = null
        set .ownsMutation = false
        set .previous = 0
        set .next = 0
        return this
    endmethod

    method release takes nothing returns nothing
        set .source = null
        set .target = null
        set .whichAbility = null
        call .destroy()
    endmethod
endstruct

private struct DRArea
    unit source
    ability whichAbility
    group candidates
    integer abilityId
    integer level
    integer category
    integer buffId
    real originalNormal
    real originalHero
    real startedAt
    real readyAt
    real deadline
    boolean stomp
    boolean ownsMutation
    integer previous
    integer next

    static method create takes nothing returns thistype
        local thistype this = thistype.allocate()
        set .source = null
        set .whichAbility = null
        set .candidates = null
        set .ownsMutation = false
        set .previous = 0
        set .next = 0
        return this
    endmethod

    method release takes nothing returns nothing
        if .candidates != null then
            call DestroyGroup(.candidates)
        endif
        set .source = null
        set .whichAbility = null
        set .candidates = null
        call .destroy()
    endmethod
endstruct

private struct DRTrim
    unit target
    integer buffId
    real endAt
    integer previous
    integer next

    static method create takes unit target, integer buffId, real endAt returns thistype
        local thistype this = thistype.allocate()
        set .target = target
        set .buffId = buffId
        set .endAt = endAt
        set .previous = 0
        set .next = 0
        return this
    endmethod

    method release takes nothing returns nothing
        set .target = null
        call .destroy()
    endmethod
endstruct

private function DR_Debug takes string message returns nothing
    if DR_DebugMode or DR_TestMode then
        call BJDebugMsg("|cffffcc00[DiminishingReturns]|r " + message)
    endif
endfunction

private function DR_Test takes string message returns nothing
    if DR_TestMode then
        call BJDebugMsg("|cff80dfff[DR test]|r " + message)
    endif
endfunction

private function DR_IsCategory takes integer category returns boolean
    return category >= DR_ROOTS and category <= DR_SILENCES
endfunction

private function DR_CategoryName takes integer category returns string
    if category == DR_ROOTS then
        return "Roots"
    elseif category == DR_STUNS then
        return "Stuns"
    elseif category == DR_INCAPACITATES then
        return "Incapacitates"
    elseif category == DR_DISORIENTS then
        return "Disorients"
    elseif category == DR_SILENCES then
        return "Silences"
    endif
    return "Invalid(" + I2S(category) + ")"
endfunction

private function DR_UnitLabel takes unit target returns string
    if target == null then
        return "<null>"
    endif
    return GetUnitName(target) + "#" + I2S(GetHandleId(target))
endfunction

private function DR_AbilityLabel takes integer abilityId returns string
    return GetObjectName(abilityId) + "#" + I2S(abilityId)
endfunction

private function DR_BooleanName takes boolean value returns string
    if value then
        return "true"
    endif
    return "false"
endfunction

private function DR_IsPresent takes unit target returns boolean
    return target != null and GetUnitTypeId(target) != 0
endfunction

private function DR_IsAlive takes unit target returns boolean
    return DR_IsPresent(target) and GetWidgetLife(target) > 0.405
endfunction

private function DR_Now takes nothing returns real
    return TimerGetElapsed(DR_Clock)
endfunction

private function DR_StringContains takes string source, string value returns boolean
    local integer sourceLength = StringLength(source)
    local integer valueLength = StringLength(value)
    local integer index = 0
    if valueLength <= 0 or valueLength > sourceLength then
        return false
    endif
    loop
        exitwhen index + valueLength > sourceLength
        if SubString(source, index, index + valueLength) == value then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function DR_RegisterBuff takes integer category, integer buffId, string rawCode, boolean trimSafe returns boolean
    local integer index = 1
    if not DR_IsCategory(category) or buffId == 0 then
        return false
    endif
    loop
        exitwhen index > DR_BuffCount
        if DR_BuffId[index] == buffId then
            return DR_BuffCategory[index] == category
        endif
        set index = index + 1
    endloop
    set DR_BuffCount = DR_BuffCount + 1
    set DR_BuffId[DR_BuffCount] = buffId
    set DR_BuffCategory[DR_BuffCount] = category
    set DR_BuffCode[DR_BuffCount] = rawCode
    set DR_BuffTrimSafe[DR_BuffCount] = trimSafe
    return true
endfunction

private function DR_RegisterAbility takes integer abilityId, integer category, integer buffId, integer mode returns nothing
    local Table data = DR_KnownAbilities.link(abilityId)
    set data[DR_META_CATEGORY] = category
    set data[DR_META_BUFF] = buffId
    set data[DR_META_TRIM_SAFE] = mode
endfunction

private function DR_GetBuffTrimSafe takes integer buffId returns boolean
    local integer index = 1
    loop
        exitwhen index > DR_BuffCount
        if DR_BuffId[index] == buffId then
            return DR_BuffTrimSafe[index]
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function DR_HasCategoryBuff takes unit target, integer category, integer extraBuff returns boolean
    local integer index = 1
    if target == null then
        return false
    endif
    if extraBuff != 0 and GetUnitAbilityLevel(target, extraBuff) > 0 then
        return true
    endif
    loop
        exitwhen index > DR_BuffCount
        if DR_BuffCategory[index] == category and GetUnitAbilityLevel(target, DR_BuffId[index]) > 0 then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction

private function DR_ResolveAbility takes integer abilityId, ability whichAbility, integer level returns integer
    local integer key = level * DR_META_STRIDE
    local integer category = 0
    local integer buffId = 0
    local integer index = 1
    local Table cache = DR_AbilityCache.link(abilityId)
    local Table known
    local string buffs
    if cache.boolean[key + DR_META_CACHED] then
        return cache[key + DR_META_CATEGORY]
    endif

    set buffs = BlzGetAbilityStringLevelField(whichAbility, DR_ABILITY_SLF_BUFFS, level)
    loop
        exitwhen index > DR_BuffCount or category != 0
        if DR_BuffCode[index] != "" and DR_StringContains(buffs, DR_BuffCode[index]) then
            set category = DR_BuffCategory[index]
            set buffId = DR_BuffId[index]
        endif
        set index = index + 1
    endloop
    if category == 0 then
        set known = DR_KnownAbilities[abilityId]
        if known != 0 then
            set category = known[DR_META_CATEGORY]
            set buffId = known[DR_META_BUFF]
        endif
    endif

    set cache[key + DR_META_CATEGORY] = category
    set cache[key + DR_META_BUFF] = buffId
    set cache.boolean[key + DR_META_TRIM_SAFE] = DR_GetBuffTrimSafe(buffId)
    set cache.boolean[key + DR_META_CACHED] = true
    if DR_TestMode then
        if category != 0 then
            call DR_Test("Classified " + DR_AbilityLabel(abilityId) + " as " + DR_CategoryName(category) + ", buff=" + DR_AbilityLabel(buffId) + ", level=" + I2S(level + 1))
        else
            call DR_Test("Ignored " + DR_AbilityLabel(abilityId) + ": no recognized CC buff or fallback.")
        endif
    endif
    set buffs = null
    return category
endfunction

private function DR_GetResolvedBuff takes integer abilityId, integer level returns integer
    local Table cache = DR_AbilityCache[abilityId]
    if cache == 0 then
        return 0
    endif
    return cache[level * DR_META_STRIDE + DR_META_BUFF]
endfunction

private function DR_IsResolvedTrimSafe takes integer abilityId, integer level returns boolean
    local Table cache = DR_AbilityCache[abilityId]
    return cache != 0 and cache.boolean[level * DR_META_STRIDE + DR_META_TRIM_SAFE]
endfunction

private function DR_GetAbilityMode takes integer abilityId, unit caster returns integer
    local Table known = DR_KnownAbilities[abilityId]
    if known != 0 and known[DR_META_TRIM_SAFE] == DR_MODE_STOMP then
        return DR_MODE_STOMP
    endif
    if GetUnitCurrentOrder(caster) == OrderId("stomp") then
        return DR_MODE_STOMP
    endif
    return DR_MODE_AUTO
endfunction

private function DR_RemoveState takes DRState state returns nothing
    local integer targetKey
    if state == 0 then
        return
    endif
    if state.target != null then
        set targetKey = GetHandleId(state.target)
        if DR_StateIndex.switch(state.category - DR_ROOTS)[targetKey] == state then
            call DR_StateIndex.switch(state.category - DR_ROOTS).remove(targetKey)
        endif
    endif
    if state.previous == 0 then
        set DR_StateHead = state.next
    else
        set DRState(state.previous).next = state.next
    endif
    if state.next != 0 then
        set DRState(state.next).previous = state.previous
    endif
    set DR_StateCount = DR_StateCount - 1
    call state.release()
endfunction

private function DR_GetState takes unit target, integer category returns DRState
    local DRState state
    local real now
    if target == null or not DR_IsCategory(category) then
        return 0
    endif
    set state = DR_StateIndex.switch(category - DR_ROOTS)[GetHandleId(target)]
    if state == 0 or state.target != target then
        return 0
    endif
    if not DR_IsPresent(target) then
        call DR_RemoveState(state)
        return 0
    endif
    set now = DR_Now()
    if state.active and not DR_HasCategoryBuff(target, category, state.extraBuff) then
        set state.active = false
        set state.resetAt = now + DR_RESET_WINDOW
        if DR_TestMode then
            call DR_Test("Ended: target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category) + ", stage=" + I2S(state.stage) + ", reset=" + R2S(DR_RESET_WINDOW) + "s")
        endif
    endif
    if not state.active and now >= state.resetAt then
        if DR_TestMode then
            call DR_Test("Reset: target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category))
        endif
        call DR_RemoveState(state)
        return 0
    endif
    return state
endfunction

private function DR_GetScale takes unit target, integer category returns real
    local DRState state = DR_GetState(target, category)
    if state == 0 or state.stage <= 0 then
        return 1.00
    elseif state.stage == 1 then
        return 0.50
    elseif state.stage == 2 then
        return 0.25
    endif
    return 0.00
endfunction

private function DR_GetStageValue takes unit target, integer category returns integer
    local DRState state = DR_GetState(target, category)
    if state == 0 then
        return 0
    endif
    return state.stage
endfunction

private function DR_RestorePendingMutation takes DRPending pending returns nothing
    local integer key
    if pending == 0 or not pending.ownsMutation or pending.whichAbility == null then
        return
    endif
    set key = GetHandleId(pending.whichAbility)
    if DR_TargetMutationByAbility[key] == pending then
        call BlzSetAbilityRealLevelField(pending.whichAbility, ABILITY_RLF_DURATION_NORMAL, pending.level, pending.originalNormal)
        call BlzSetAbilityRealLevelField(pending.whichAbility, ABILITY_RLF_DURATION_HERO, pending.level, pending.originalHero)
        call DR_TargetMutationByAbility.remove(key)
    endif
    set pending.ownsMutation = false
endfunction

private function DR_RestoreAreaMutation takes DRArea area returns nothing
    local integer key
    if area == 0 or not area.ownsMutation or area.whichAbility == null then
        return
    endif
    set key = GetHandleId(area.whichAbility)
    if DR_AreaMutationByAbility[key] == area then
        call BlzSetAbilityRealLevelField(area.whichAbility, ABILITY_RLF_DURATION_NORMAL, area.level, area.originalNormal)
        call BlzSetAbilityRealLevelField(area.whichAbility, ABILITY_RLF_DURATION_HERO, area.level, area.originalHero)
        call DR_AreaMutationByAbility.remove(key)
    endif
    set area.ownsMutation = false
endfunction

private function DR_RemovePending takes DRPending pending returns nothing
    local integer sourceKey
    if pending == 0 then
        return
    endif
    call DR_RestorePendingMutation(pending)
    if pending.source != null and pending.kind == DR_PENDING_PASSIVE then
        set sourceKey = GetHandleId(pending.source)
        if DR_PassivePendingBySource[sourceKey] == pending then
            call DR_PassivePendingBySource.remove(sourceKey)
        endif
    endif
    if pending.previous == 0 then
        set DR_PendingHead = pending.next
    else
        set DRPending(pending.previous).next = pending.next
    endif
    if pending.next != 0 then
        set DRPending(pending.next).previous = pending.previous
    endif
    set DR_PendingCount = DR_PendingCount - 1
    call pending.release()
endfunction

private function DR_RemoveArea takes DRArea area returns nothing
    if area == 0 then
        return
    endif
    call DR_RestoreAreaMutation(area)
    if area.previous == 0 then
        set DR_AreaHead = area.next
    else
        set DRArea(area.previous).next = area.next
    endif
    if area.next != 0 then
        set DRArea(area.next).previous = area.previous
    endif
    set DR_AreaCount = DR_AreaCount - 1
    call area.release()
endfunction

private function DR_RemoveTrim takes DRTrim trim returns nothing
    local integer targetKey
    local Table index
    if trim == 0 then
        return
    endif
    if trim.target != null then
        set targetKey = GetHandleId(trim.target)
        set index = DR_TrimIndex[targetKey]
        if index != 0 and index[trim.buffId] == trim then
            call index.remove(trim.buffId)
        endif
    endif
    if trim.previous == 0 then
        set DR_TrimHead = trim.next
    else
        set DRTrim(trim.previous).next = trim.next
    endif
    if trim.next != 0 then
        set DRTrim(trim.next).previous = trim.previous
    endif
    set DR_TrimCount = DR_TrimCount - 1
    call trim.release()
endfunction

private function DR_CommitConfirmed takes unit target, integer category, integer buffId returns boolean
    local DRState state
    local integer oldStage
    if not DR_Enabled or not DR_IsAlive(target) or not DR_IsCategory(category) or buffId == 0 then
        return false
    endif
    if DR_GetScale(target, category) <= 0.00 then
        if DR_TestMode then
            call DR_Test("Commit rejected: target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category) + ", stage=3 immune")
        endif
        return false
    endif
    call DR_RegisterBuff(category, buffId, "", false)
    set state = DR_GetState(target, category)
    if state == 0 then
        set state = DRState.create(target, category)
        set state.next = DR_StateHead
        if DR_StateHead != 0 then
            set DRState(DR_StateHead).previous = state
        endif
        set DR_StateHead = state
        set DR_StateCount = DR_StateCount + 1
        set DR_StateIndex.switch(category - DR_ROOTS)[GetHandleId(target)] = state
    endif
    set oldStage = state.stage
    set state.stage = state.stage + 1
    if state.stage > 3 then
        set state.stage = 3
    endif
    set state.extraBuff = buffId
    set state.active = true
    set state.resetAt = 0.00
    if DR_TestMode then
        call DR_Test("Confirmed: target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category) + ", stage=" + I2S(oldStage) + "->" + I2S(state.stage) + ", nextScale=" + R2S(DR_GetScale(target, category)))
    endif
    return true
endfunction

private function DR_ScheduleTrim takes unit target, integer buffId, real endAt returns nothing
    local integer targetKey = GetHandleId(target)
    local Table index = DR_TrimIndex.link(targetKey)
    local DRTrim trim = index[buffId]
    if trim != 0 and trim.target == target then
        if endAt < trim.endAt then
            set trim.endAt = endAt
        endif
        return
    endif
    set trim = DRTrim.create(target, buffId, endAt)
    set trim.next = DR_TrimHead
    if DR_TrimHead != 0 then
        set DRTrim(DR_TrimHead).previous = trim
    endif
    set DR_TrimHead = trim
    set DR_TrimCount = DR_TrimCount + 1
    set index[buffId] = trim
    if DR_TestMode then
        call DR_Test("Trim scheduled: target=" + DR_UnitLabel(target) + ", buff=" + DR_AbilityLabel(buffId) + ", endsAt=" + R2S(endAt))
    endif
endfunction

private function DR_DurationFor takes unit target, real normalDuration, real heroDuration returns real
    if IsUnitType(target, UNIT_TYPE_HERO) or IsUnitType(target, UNIT_TYPE_RESISTANT) then
        return heroDuration
    endif
    return normalDuration
endfunction

private function DR_IsStompTarget takes unit source, unit target returns boolean
    if not DR_IsAlive(target) or target == source then
        return false
    endif
    if not IsUnitEnemy(target, GetOwningPlayer(source)) then
        return false
    endif
    if IsUnitType(target, UNIT_TYPE_STRUCTURE) or IsUnitType(target, UNIT_TYPE_FLYING) then
        return false
    endif
    return not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE)
endfunction

private function DR_ApplyDummyStun takes unit source, unit target, real duration returns boolean
    local unit dummy
    local ability whichAbility
    local boolean issued = false
    if not DR_IsAlive(source) or not DR_IsAlive(target) or duration <= 0.00 then
        return false
    endif
    set dummy = CreateUnit(GetOwningPlayer(source), DR_DUMMY_ID, GetUnitX(target), GetUnitY(target), 0.00)
    if dummy != null then
        set DR_InternalDummy.unit[GetHandleId(dummy)] = dummy
        if UnitAddAbility(dummy, DR_DUMMY_STUN_ID) then
            set whichAbility = BlzGetUnitAbility(dummy, DR_DUMMY_STUN_ID)
            if whichAbility != null then
                call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, 0, duration)
                call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, 0, duration)
                set issued = IssueTargetOrder(dummy, "thunderbolt", target)
            endif
        endif
        call UnitApplyTimedLife(dummy, 'BTLF', 1.00)
    endif
    set whichAbility = null
    set dummy = null
    return issued
endfunction

private function DR_ProcessPending takes DRPending pending, real now returns nothing
    if not DR_IsAlive(pending.target) then
        if DR_TestMode then
            call DR_Test("Cancelled: target no longer valid, category=" + DR_CategoryName(pending.category))
        endif
        call DR_RemovePending(pending)
        return
    endif
    if now >= pending.notBefore then
        if GetUnitAbilityLevel(pending.target, pending.buffId) > 0 then
            if pending.scale > 0.00 and (not pending.hadBuff or pending.acceptExisting) then
                call DR_CommitConfirmed(pending.target, pending.category, pending.buffId)
            endif
            call DR_RemovePending(pending)
            return
        endif
    endif
    if now >= pending.deadline then
        if DR_TestMode then
            call DR_Test("Unconfirmed: target=" + DR_UnitLabel(pending.target) + ", category=" + DR_CategoryName(pending.category) + ", ability=" + DR_AbilityLabel(pending.abilityId) + "; DR stage unchanged")
        endif
        call DR_RemovePending(pending)
    endif
endfunction

private function DR_ProcessStompArea takes DRArea area, real now returns nothing
    local unit target
    local real scale
    local real duration
    local boolean hadBuff
    local DRPending pending
    call DR_RestoreAreaMutation(area)
    loop
        set target = FirstOfGroup(area.candidates)
        exitwhen target == null
        call GroupRemoveUnit(area.candidates, target)
        if DR_IsStompTarget(area.source, target) then
            set scale = DR_GetScale(target, area.category)
            if scale > 0.00 then
                set duration = DR_DurationFor(target, area.originalNormal, area.originalHero) * scale
                set hadBuff = GetUnitAbilityLevel(target, area.buffId) > 0
                if DR_ApplyDummyStun(area.source, target, duration) and not hadBuff then
                    set pending = DRPending.create()
                    set pending.source = area.source
                    set pending.target = target
                    set pending.category = area.category
                    set pending.buffId = area.buffId
                    set pending.kind = DR_PENDING_TARGET
                    set pending.scale = scale
                    set pending.hadBuff = false
                    set pending.acceptExisting = false
                    set pending.notBefore = now
                    set pending.deadline = now + DR_TARGET_CONFIRM_GRACE
                    set pending.next = DR_PendingHead
                    if DR_PendingHead != 0 then
                        set DRPending(DR_PendingHead).previous = pending
                    endif
                    set DR_PendingHead = pending
                    set DR_PendingCount = DR_PendingCount + 1
                endif
            else
                if DR_TestMode then
                    call DR_Test("Immune: skipped AoE replacement on " + DR_UnitLabel(target) + ", category=" + DR_CategoryName(area.category) + ", stage=3")
                endif
            endif
        endif
    endloop
    set pending = 0
    set target = null
    call DR_RemoveArea(area)
endfunction

private function DR_ProcessGenericArea takes DRArea area, real now returns nothing
    local group retained = CreateGroup()
    local unit target
    local real scale
    local real duration
    loop
        set target = FirstOfGroup(area.candidates)
        exitwhen target == null
        call GroupRemoveUnit(area.candidates, target)
        if DR_IsAlive(target) then
            if GetUnitAbilityLevel(target, area.buffId) > 0 then
                set scale = DR_GetScale(target, area.category)
                if scale <= 0.00 then
                    call UnitRemoveAbility(target, area.buffId)
                    if DR_TestMode then
                        call DR_Test("Immune: removed AoE buff from " + DR_UnitLabel(target) + ", category=" + DR_CategoryName(area.category) + ", stage=3")
                    endif
                else
                    call DR_CommitConfirmed(target, area.category, area.buffId)
                    if scale < 1.00 then
                        set duration = DR_DurationFor(target, area.originalNormal, area.originalHero) * scale
                        if area.startedAt + duration <= now then
                            call UnitRemoveAbility(target, area.buffId)
                        else
                            call DR_ScheduleTrim(target, area.buffId, area.startedAt + duration)
                        endif
                    endif
                endif
            elseif now < area.deadline then
                call GroupAddUnit(retained, target)
            endif
        endif
    endloop
    call DestroyGroup(area.candidates)
    set area.candidates = retained
    if now >= area.deadline or FirstOfGroup(area.candidates) == null then
        call DR_RemoveArea(area)
    endif
    set retained = null
    set target = null
endfunction

private function DR_ProcessTrim takes DRTrim trim, real now returns nothing
    if not DR_IsPresent(trim.target) or GetUnitAbilityLevel(trim.target, trim.buffId) <= 0 then
        call DR_RemoveTrim(trim)
    elseif now >= trim.endAt then
        call UnitRemoveAbility(trim.target, trim.buffId)
        if DR_TestMode then
            call DR_Test("Trim applied: target=" + DR_UnitLabel(trim.target) + ", buff=" + DR_AbilityLabel(trim.buffId))
        endif
        call DR_RemoveTrim(trim)
    endif
endfunction

private function DR_ProcessState takes DRState state, real now returns nothing
    if not DR_IsPresent(state.target) or GetWidgetLife(state.target) <= 0.405 then
        call DR_RemoveState(state)
    elseif state.active then
        if not DR_HasCategoryBuff(state.target, state.category, state.extraBuff) then
            set state.active = false
            set state.resetAt = now + DR_RESET_WINDOW
            if DR_TestMode then
                call DR_Test("Ended: target=" + DR_UnitLabel(state.target) + ", category=" + DR_CategoryName(state.category) + ", stage=" + I2S(state.stage) + ", reset=" + R2S(DR_RESET_WINDOW) + "s")
            endif
        endif
    elseif now >= state.resetAt then
        if DR_TestMode then
            call DR_Test("Reset: target=" + DR_UnitLabel(state.target) + ", category=" + DR_CategoryName(state.category))
        endif
        call DR_RemoveState(state)
    endif
endfunction

private function DR_OnPulse takes nothing returns nothing
    local real now = DR_Now()
    local DRPending pending = DR_PendingHead
    local DRArea area
    local DRTrim trim
    local DRState state
    local integer next
    loop
        exitwhen pending == 0
        set next = pending.next
        call DR_ProcessPending(pending, now)
        set pending = next
    endloop
    set area = DR_AreaHead
    loop
        exitwhen area == 0
        set next = area.next
        if now >= area.readyAt then
            if area.stomp then
                call DR_ProcessStompArea(area, now)
            else
                call DR_ProcessGenericArea(area, now)
            endif
        endif
        set area = next
    endloop
    set trim = DR_TrimHead
    loop
        exitwhen trim == 0
        set next = trim.next
        call DR_ProcessTrim(trim, now)
        set trim = next
    endloop
    set state = DR_StateHead
    loop
        exitwhen state == 0
        set next = state.next
        call DR_ProcessState(state, now)
        set state = next
    endloop
    if DR_PendingHead == 0 and DR_AreaHead == 0 and DR_TrimHead == 0 and DR_StateHead == 0 then
        call PauseTimer(DR_PulseTimer)
        set DR_PulseRunning = false
    endif
endfunction

private function DR_EnsurePulse takes nothing returns nothing
    if not DR_PulseRunning then
        set DR_PulseRunning = true
        call TimerStart(DR_PulseTimer, DR_PULSE_INTERVAL, true, function DR_OnPulse)
    endif
endfunction

private function DR_AddPending takes DRPending pending returns nothing
    set pending.next = DR_PendingHead
    if DR_PendingHead != 0 then
        set DRPending(DR_PendingHead).previous = pending
    endif
    set DR_PendingHead = pending
    set DR_PendingCount = DR_PendingCount + 1
    call DR_EnsurePulse()
endfunction

private function DR_AddArea takes DRArea area returns nothing
    set area.next = DR_AreaHead
    if DR_AreaHead != 0 then
        set DRArea(DR_AreaHead).previous = area
    endif
    set DR_AreaHead = area
    set DR_AreaCount = DR_AreaCount + 1
    call DR_EnsurePulse()
endfunction

private function DR_DetachAbilityMutations takes ability whichAbility returns nothing
    local integer key
    local DRPending pending
    local DRArea area
    if whichAbility == null then
        return
    endif
    set key = GetHandleId(whichAbility)
    set pending = DR_TargetMutationByAbility[key]
    if pending != 0 then
        call DR_RestorePendingMutation(pending)
    endif
    set area = DR_AreaMutationByAbility[key]
    if area != 0 then
        call DR_RestoreAreaMutation(area)
    endif
endfunction

private function DR_StartTargeted takes unit source, unit target, integer abilityId, ability whichAbility, integer level, integer category, integer buffId returns nothing
    local DRPending pending
    local real scale
    local real normalDuration
    local real heroDuration
    local real dx
    local real dy
    local real travel = 0.00
    local integer missileSpeed
    local boolean normalSet = true
    local boolean heroSet = true
    if not DR_IsAlive(target) then
        return
    endif
    set scale = DR_GetScale(target, category)
    if DR_TestMode then
        call DR_Test("Targeted: ability=" + DR_AbilityLabel(abilityId) + ", target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category) + ", stage=" + I2S(DR_GetStageValue(target, category)) + ", scale=" + R2S(scale))
    endif
    set normalDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level)
    set heroDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level)
    if normalDuration <= 0.00 and heroDuration <= 0.00 then
        if DR_TestMode then
            call DR_Test("Ignored targeted ability " + DR_AbilityLabel(abilityId) + ": both duration fields are zero.")
        endif
        return
    endif

    call DR_DetachAbilityMutations(whichAbility)
    set pending = DRPending.create()
    set pending.source = source
    set pending.target = target
    set pending.whichAbility = whichAbility
    set pending.abilityId = abilityId
    set pending.level = level
    set pending.category = category
    set pending.buffId = buffId
    set pending.kind = DR_PENDING_TARGET
    set pending.scale = scale
    set pending.originalNormal = normalDuration
    set pending.originalHero = heroDuration
    set pending.hadBuff = GetUnitAbilityLevel(target, buffId) > 0
    set pending.acceptExisting = true

    if scale < 1.00 then
        if scale <= 0.00 then
            set normalSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, DR_SUPPRESS_DURATION)
            set heroSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, DR_SUPPRESS_DURATION)
        else
            set normalSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, normalDuration * scale)
            set heroSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, heroDuration * scale)
        endif
        if not normalSet or not heroSet then
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, normalDuration)
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, heroDuration)
            call pending.release()
            call DR_Debug("Could not mutate duration fields for " + GetObjectName(abilityId))
            return
        endif
        set pending.ownsMutation = true
        set DR_TargetMutationByAbility[GetHandleId(whichAbility)] = pending
    endif

    set missileSpeed = BlzGetAbilityIntegerField(whichAbility, ABILITY_IF_MISSILE_SPEED)
    if missileSpeed > 0 then
        set dx = GetUnitX(target) - GetUnitX(source)
        set dy = GetUnitY(target) - GetUnitY(source)
        set travel = SquareRoot(dx * dx + dy * dy) / I2R(missileSpeed)
    endif
    set pending.notBefore = DR_Now() + travel
    set pending.deadline = pending.notBefore + DR_TARGET_CONFIRM_GRACE
    call DR_AddPending(pending)
endfunction

private function DR_StartArea takes unit source, integer abilityId, ability whichAbility, integer level, integer category, integer buffId, boolean stomp returns nothing
    local DRArea area
    local group scan
    local unit target
    local real x = GetSpellTargetX()
    local real y = GetSpellTargetY()
    local real radius = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_AREA_OF_EFFECT, level)
    local boolean normalSet
    local boolean heroSet
    if radius <= 0.00 then
        if DR_TestMode then
            call DR_Test("Ignored AoE ability " + DR_AbilityLabel(abilityId) + ": area of effect is zero.")
        endif
        return
    endif
    if stomp then
        set x = GetUnitX(source)
        set y = GetUnitY(source)
    elseif not DR_IsResolvedTrimSafe(abilityId, level) then
        if DR_TestMode then
            call DR_Test("Ignored AoE ability " + DR_AbilityLabel(abilityId) + ": buff is not safe to trim per target.")
        endif
        return
    endif

    set area = DRArea.create()
    set area.source = source
    set area.whichAbility = whichAbility
    set area.abilityId = abilityId
    set area.level = level
    set area.category = category
    set area.buffId = buffId
    set area.originalNormal = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level)
    set area.originalHero = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level)
    set area.startedAt = DR_Now()
    set area.readyAt = area.startedAt + DR_PULSE_INTERVAL
    set area.deadline = area.startedAt + DR_AREA_CONFIRM_TIMEOUT
    set area.stomp = stomp
    set area.candidates = CreateGroup()
    set scan = CreateGroup()
    call GroupEnumUnitsInRange(scan, x, y, radius, null)
    loop
        set target = FirstOfGroup(scan)
        exitwhen target == null
        call GroupRemoveUnit(scan, target)
        if stomp then
            if DR_IsStompTarget(source, target) then
                call GroupAddUnit(area.candidates, target)
            endif
        elseif DR_IsAlive(target) and GetUnitAbilityLevel(target, buffId) == 0 then
            call GroupAddUnit(area.candidates, target)
        endif
    endloop
    call DestroyGroup(scan)
    set scan = null

    if FirstOfGroup(area.candidates) == null then
        if DR_TestMode then
            call DR_Test("AoE: no eligible targets for " + DR_AbilityLabel(abilityId) + ", category=" + DR_CategoryName(category))
        endif
        call area.release()
        set target = null
        return
    endif
    if stomp then
        call DR_DetachAbilityMutations(whichAbility)
        set normalSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, DR_SUPPRESS_DURATION)
        set heroSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, DR_SUPPRESS_DURATION)
        if not normalSet or not heroSet then
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, area.originalNormal)
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, area.originalHero)
            call area.release()
            call DR_Debug("Could not suppress AoE duration fields for " + DR_AbilityLabel(abilityId))
            set target = null
            return
        endif
        set area.ownsMutation = true
        set DR_AreaMutationByAbility[GetHandleId(whichAbility)] = area
    endif
    if DR_TestMode then
        call DR_Test("AoE queued: ability=" + DR_AbilityLabel(abilityId) + ", category=" + DR_CategoryName(category) + ", stompReplacement=" + DR_BooleanName(stomp))
    endif
    call DR_AddArea(area)
    set target = null
endfunction

private function DR_ClearPassiveScratch takes nothing returns nothing
    set DR_FoundPassiveAbility = null
    set DR_FoundPassiveId = 0
    set DR_FoundPassiveLevel = 0
    set DR_FoundPassiveBuff = 0
endfunction

private function DR_TryPassiveAbility takes unit source, integer abilityId returns boolean
    local ability whichAbility = BlzGetUnitAbility(source, abilityId)
    local integer level = GetUnitAbilityLevel(source, abilityId) - 1
    local integer category
    local integer buffId
    if whichAbility == null or level < 0 then
        set whichAbility = null
        return false
    endif
    if BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_CHANCE_TO_BASH, level) <= 0.00 then
        set whichAbility = null
        return false
    endif
    set category = DR_ResolveAbility(abilityId, whichAbility, level)
    set buffId = DR_GetResolvedBuff(abilityId, level)
    if category == 0 and (abilityId == 'AHbh' or abilityId == 'ACbh' or abilityId == 'ANbh' or abilityId == 'Albx') then
        set category = DR_STUNS
        set buffId = 'BPSE'
    endif
    if category != DR_STUNS or buffId == 0 then
        set whichAbility = null
        return false
    endif
    set DR_FoundPassiveAbility = whichAbility
    set DR_FoundPassiveId = abilityId
    set DR_FoundPassiveLevel = level
    set DR_FoundPassiveBuff = buffId
    set whichAbility = null
    return true
endfunction

private function DR_FindPassiveBash takes unit source returns boolean
    local integer sourceKey = GetHandleId(source)
    local integer abilityId
    local integer index = 0
    local real now = DR_Now()
    local ability whichAbility
    call DR_ClearPassiveScratch()
    set abilityId = DR_PassiveCache.switch(0)[sourceKey]
    if abilityId != 0 and DR_TryPassiveAbility(source, abilityId) then
        return true
    endif
    if now < DR_PassiveCache.switch(1).real[sourceKey] then
        return false
    endif
    loop
        exitwhen index >= DR_MAX_UNIT_ABILITIES
        set whichAbility = BlzGetUnitAbilityByIndex(source, index)
        exitwhen whichAbility == null
        set abilityId = BlzGetAbilityId(whichAbility)
        set whichAbility = null
        if abilityId != 0 and DR_TryPassiveAbility(source, abilityId) then
            set DR_PassiveCache.switch(0)[sourceKey] = abilityId
            set DR_PassiveCache.switch(1).real[sourceKey] = now + DR_PASSIVE_CACHE_SECONDS
            if DR_TestMode then
                call DR_Test("Passive discovered: source=" + DR_UnitLabel(source) + ", ability=" + DR_AbilityLabel(abilityId) + ", category=Stuns")
            endif
            return true
        endif
        set index = index + 1
    endloop
    set DR_PassiveCache.switch(0)[sourceKey] = 0
    set DR_PassiveCache.switch(1).real[sourceKey] = now + DR_PASSIVE_CACHE_SECONDS
    set whichAbility = null
    return false
endfunction

private function DR_OnSpellChannel takes nothing returns nothing
    local unit source
    local ability whichAbility
    local integer abilityId
    if not DR_Enabled then
        return
    endif
    set source = GetTriggerUnit()
    set abilityId = GetSpellAbilityId()
    set whichAbility = BlzGetUnitAbility(source, abilityId)
    call DR_DetachAbilityMutations(whichAbility)
    set whichAbility = null
    set source = null
endfunction

private function DR_OnSpellEffect takes nothing returns nothing
    local unit source
    local unit target
    local ability whichAbility
    local integer abilityId
    local integer level
    local integer category
    local integer buffId
    local integer mode
    if not DR_Enabled then
        return
    endif
    set source = GetTriggerUnit()
    set abilityId = GetSpellAbilityId()
    if DR_InternalDummy.unit[GetHandleId(source)] == source and abilityId == DR_DUMMY_STUN_ID then
        set source = null
        return
    endif
    set whichAbility = BlzGetUnitAbility(source, abilityId)
    set level = GetUnitAbilityLevel(source, abilityId) - 1
    if whichAbility == null or level < 0 then
        set whichAbility = null
        set source = null
        return
    endif
    set category = DR_ResolveAbility(abilityId, whichAbility, level)
    set buffId = DR_GetResolvedBuff(abilityId, level)
    if category != 0 and buffId != 0 then
        set target = GetSpellTargetUnit()
        if target != null then
            call DR_StartTargeted(source, target, abilityId, whichAbility, level, category, buffId)
        else
            set mode = DR_GetAbilityMode(abilityId, source)
            call DR_StartArea(source, abilityId, whichAbility, level, category, buffId, mode == DR_MODE_STOMP and category == DR_STUNS)
        endif
    endif
    set whichAbility = null
    set target = null
    set source = null
endfunction

private function DR_OnSpellEndcast takes nothing returns nothing
    local unit source = GetTriggerUnit()
    local ability whichAbility = BlzGetUnitAbility(source, GetSpellAbilityId())
    local DRArea area
    if whichAbility != null then
        set area = DR_AreaMutationByAbility[GetHandleId(whichAbility)]
        if area != 0 then
            call DR_RestoreAreaMutation(area)
        endif
    endif
    set whichAbility = null
    set source = null
endfunction

private function DR_OnDamaging takes nothing returns nothing
    local unit source
    local unit target
    local ability whichAbility
    local DRPending pending
    local DRPending oldPending
    local real scale
    local real normalDuration
    local real heroDuration
    local boolean normalSet = true
    local boolean heroSet = true
    if not DR_Enabled or not BlzGetEventIsAttack() then
        return
    endif
    set source = GetEventDamageSource()
    set target = BlzGetEventDamageTarget()
    if not DR_IsAlive(source) or not DR_IsAlive(target) or not DR_FindPassiveBash(source) then
        set source = null
        set target = null
        return
    endif
    set whichAbility = DR_FoundPassiveAbility
    set scale = DR_GetScale(target, DR_STUNS)
    set normalDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, DR_FoundPassiveLevel)
    set heroDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, DR_FoundPassiveLevel)
    if DR_TestMode then
        call DR_Test("Passive attempt: ability=" + DR_AbilityLabel(DR_FoundPassiveId) + ", target=" + DR_UnitLabel(target) + ", category=Stuns, stage=" + I2S(DR_GetStageValue(target, DR_STUNS)) + ", scale=" + R2S(scale))
    endif
    set oldPending = DR_PassivePendingBySource[GetHandleId(source)]
    if oldPending != 0 then
        call DR_RemovePending(oldPending)
    endif
    call DR_DetachAbilityMutations(whichAbility)
    set pending = DRPending.create()
    set pending.source = source
    set pending.target = target
    set pending.whichAbility = whichAbility
    set pending.abilityId = DR_FoundPassiveId
    set pending.level = DR_FoundPassiveLevel
    set pending.category = DR_STUNS
    set pending.buffId = DR_FoundPassiveBuff
    set pending.kind = DR_PENDING_PASSIVE
    set pending.scale = scale
    set pending.originalNormal = normalDuration
    set pending.originalHero = heroDuration
    set pending.hadBuff = GetUnitAbilityLevel(target, pending.buffId) > 0
    set pending.acceptExisting = false
    set pending.notBefore = DR_Now()
    set pending.deadline = pending.notBefore + DR_TARGET_CONFIRM_GRACE
    if scale < 1.00 then
        if scale <= 0.00 then
            set normalSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, pending.level, DR_SUPPRESS_DURATION)
            set heroSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, pending.level, DR_SUPPRESS_DURATION)
        else
            set normalSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, pending.level, normalDuration * scale)
            set heroSet = BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, pending.level, heroDuration * scale)
        endif
        if not normalSet or not heroSet then
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, pending.level, normalDuration)
            call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, pending.level, heroDuration)
            call pending.release()
            call DR_Debug("Could not mutate passive duration fields for " + DR_AbilityLabel(DR_FoundPassiveId))
            call DR_ClearPassiveScratch()
            set whichAbility = null
            set source = null
            set target = null
            return
        endif
        set pending.ownsMutation = true
        set DR_TargetMutationByAbility[GetHandleId(whichAbility)] = pending
    endif
    set DR_PassivePendingBySource[GetHandleId(source)] = pending
    call DR_AddPending(pending)
    call DR_ClearPassiveScratch()
    set whichAbility = null
    set source = null
    set target = null
endfunction

private function DR_OnDamaged takes nothing returns nothing
    local unit source
    local unit target
    local DRPending pending
    if not DR_Enabled or not BlzGetEventIsAttack() then
        return
    endif
    set source = GetEventDamageSource()
    set target = BlzGetEventDamageTarget()
    if source != null then
        set pending = DR_PassivePendingBySource[GetHandleId(source)]
        if pending != 0 then
            call DR_RestorePendingMutation(pending)
            if pending.target == target and not pending.hadBuff and pending.scale > 0.00 and GetUnitAbilityLevel(target, pending.buffId) > 0 then
                call DR_CommitConfirmed(target, pending.category, pending.buffId)
            endif
            call DR_RemovePending(pending)
        endif
    endif
    set target = null
    set source = null
endfunction

private function DR_OnDeath takes nothing returns nothing
    local unit target = UnitDeathEvent_GetDyingUnit()
    local integer targetKey
    local integer category = DR_ROOTS
    local integer passiveAbility
    local DRState state
    local boolean hadState = false
    local boolean internalDummy
    if target == null then
        return
    endif
    set targetKey = GetHandleId(target)
    set passiveAbility = DR_PassiveCache.switch(0)[targetKey]
    set internalDummy = DR_InternalDummy.unit[targetKey] == target
    if DR_StateCount > 0 then
        loop
            exitwhen category > DR_SILENCES
            set state = DR_StateIndex.switch(category - DR_ROOTS)[targetKey]
            if state != 0 and state.target == target then
                set hadState = true
                call DR_RemoveState(state)
            endif
            set category = category + 1
        endloop
    endif
    if internalDummy then
        call DR_InternalDummy.handle.remove(targetKey)
    endif
    call DR_PassiveCache.switch(0).remove(targetKey)
    call DR_PassiveCache.switch(1).real.remove(targetKey)
    call DR_TrimIndex.remove(targetKey)
    if DR_TestMode then
        if internalDummy then
            call DR_Test("Internal AoE dummy expired: " + DR_UnitLabel(target))
        elseif hadState or passiveAbility != 0 then
            call DR_Test("Tracked-unit death cleanup: target=" + DR_UnitLabel(target) + ", hadState=" + DR_BooleanName(hadState) + ", passiveAbility=" + I2S(passiveAbility))
        endif
    endif
    set target = null
endfunction

function DR_GetStage takes unit target, integer category returns integer
    return DR_GetStageValue(target, category)
endfunction

function DR_GetDurationScale takes unit target, integer category returns real
    return DR_GetScale(target, category)
endfunction

function DR_GetResetRemaining takes unit target, integer category returns real
    local DRState state = DR_GetState(target, category)
    local real remaining
    if state == 0 then
        return 0.00
    endif
    if state.active then
        return -1.00
    endif
    set remaining = state.resetAt - DR_Now()
    if remaining < 0.00 then
        return 0.00
    endif
    return remaining
endfunction

function DR_Reset takes unit target, integer category returns nothing
    local DRState state = DR_GetState(target, category)
    if state != 0 then
        if DR_TestMode then
            call DR_Test("Manual reset: target=" + DR_UnitLabel(target) + ", category=" + DR_CategoryName(category))
        endif
        call DR_RemoveState(state)
    endif
endfunction

function DR_CommitApplied takes unit target, integer category, integer buffId returns boolean
    if target == null or buffId == 0 or GetUnitAbilityLevel(target, buffId) <= 0 then
        return false
    endif
    if not DR_RegisterBuff(category, buffId, "", false) then
        return false
    endif
    if DR_CommitConfirmed(target, category, buffId) then
        call DR_EnsurePulse()
        return true
    endif
    return false
endfunction

function DR_IsEnabled takes nothing returns boolean
    return DR_Enabled
endfunction

function DR_IsDebugMode takes nothing returns boolean
    return DR_DebugMode
endfunction

function DR_SetDebugMode takes boolean enabled returns nothing
    set DR_DebugMode = enabled
    if enabled then
        call BJDebugMsg("|cffffcc00[DiminishingReturns]|r Debug mode enabled; recognizedBuffs=" + I2S(DR_BuffCount) + ", enabled=" + DR_BooleanName(DR_Enabled) + ".")
    endif
endfunction

function DR_IsTestMode takes nothing returns boolean
    return DR_TestMode
endfunction

function DR_SetTestMode takes boolean enabled returns nothing
    set DR_TestMode = enabled
    if enabled then
        call BJDebugMsg("|cff80dfff[DR test]|r Test mode enabled; verbose DR tracing is active. tracked=" + I2S(DR_StateCount) + ", pending=" + I2S(DR_PendingCount + DR_AreaCount) + ", trims=" + I2S(DR_TrimCount) + ".")
    endif
endfunction

function DR_SetEnabled takes boolean enabled returns nothing
    local DRPending pending
    local DRArea area
    local DRTrim trim
    local DRState state
    if enabled and DR_StunGuardConflict then
        call BJDebugMsg("|cffff0000[DiminishingReturns]|r Cannot enable while StunGuard is imported.")
        return
    endif
    if enabled == DR_Enabled then
        return
    endif
    set DR_Enabled = enabled
    if enabled then
        call DR_Debug("System enabled.")
    else
        call DR_Debug("System disabled; runtime state cleared.")
    endif
    if not enabled then
        loop
            set pending = DR_PendingHead
            exitwhen pending == 0
            call DR_RemovePending(pending)
        endloop
        loop
            set area = DR_AreaHead
            exitwhen area == 0
            call DR_RemoveArea(area)
        endloop
        loop
            set trim = DR_TrimHead
            exitwhen trim == 0
            call DR_RemoveTrim(trim)
        endloop
        loop
            set state = DR_StateHead
            exitwhen state == 0
            call DR_RemoveState(state)
        endloop
        call PauseTimer(DR_PulseTimer)
        set DR_PulseRunning = false
    endif
endfunction

function DR_GetTrackedStateCount takes nothing returns integer
    return DR_StateCount
endfunction

function DR_GetPendingCount takes nothing returns integer
    return DR_PendingCount + DR_AreaCount
endfunction

function DR_GetTrimCount takes nothing returns integer
    return DR_TrimCount
endfunction

private function DR_Configure takes nothing returns nothing
    // Roots and movement immobilizers.
    call DR_RegisterBuff(DR_ROOTS, 'BEer', "BEer", true)
    call DR_RegisterBuff(DR_ROOTS, 'Bena', "Bena", true)
    call DR_RegisterBuff(DR_ROOTS, 'Beng', "Beng", true)
    call DR_RegisterBuff(DR_ROOTS, 'B60V', "B60V", true)

    // Stuns share the standard Stunned (Pause) buff.
    call DR_RegisterBuff(DR_STUNS, 'BPSE', "BPSE", false)

    // Incapacitates.
    call DR_RegisterBuff(DR_INCAPACITATES, 'BOhx', "BOhx", true)
    call DR_RegisterBuff(DR_INCAPACITATES, 'BHbn', "BHbn", true)
    call DR_RegisterBuff(DR_INCAPACITATES, 'Bply', "Bply", true)
    call DR_RegisterBuff(DR_INCAPACITATES, 'BUsl', "BUsl", true)

    // Disorients.
    call DR_RegisterBuff(DR_DISORIENTS, 'Bcyc', "Bcyc", false)
    call DR_RegisterBuff(DR_DISORIENTS, 'B61I', "B61I", true)

    // Silences.
    call DR_RegisterBuff(DR_SILENCES, 'BNsi', "BNsi", true)
    call DR_RegisterBuff(DR_SILENCES, 'BIse', "BIse", true)
    call DR_RegisterBuff(DR_SILENCES, 'BNso', "BNso", true)
    call DR_RegisterBuff(DR_SILENCES, 'B01T', "B01T", true)

    // Stock and PotS fallbacks for hardcoded or unavailable Buffs fields.
    call DR_RegisterAbility('AEer', DR_ROOTS, 'BEer', DR_MODE_AUTO)
    call DR_RegisterAbility('Aenr', DR_ROOTS, 'BEer', DR_MODE_AUTO)
    call DR_RegisterAbility('Aenw', DR_ROOTS, 'BEer', DR_MODE_AUTO)
    call DR_RegisterAbility('Aens', DR_ROOTS, 'Bena', DR_MODE_AUTO)
    call DR_RegisterAbility('A69O', DR_ROOTS, 'B60V', DR_MODE_AUTO)

    call DR_RegisterAbility('AHtb', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('ACfb', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('ANfb', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('AOws', DR_STUNS, 'BPSE', DR_MODE_STOMP)
    call DR_RegisterAbility('AOs2', DR_STUNS, 'BPSE', DR_MODE_STOMP)
    call DR_RegisterAbility('AOw2', DR_STUNS, 'BPSE', DR_MODE_STOMP)
    call DR_RegisterAbility('AHbh', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('ACbh', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('ANbh', DR_STUNS, 'BPSE', DR_MODE_AUTO)
    call DR_RegisterAbility('Albx', DR_STUNS, 'BPSE', DR_MODE_AUTO)

    call DR_RegisterAbility('AOhx', DR_INCAPACITATES, 'BOhx', DR_MODE_AUTO)
    call DR_RegisterAbility('A673', DR_INCAPACITATES, 'BOhx', DR_MODE_AUTO)
    call DR_RegisterAbility('A005', DR_INCAPACITATES, 'BOhx', DR_MODE_AUTO)
    call DR_RegisterAbility('AHbn', DR_INCAPACITATES, 'BHbn', DR_MODE_AUTO)
    call DR_RegisterAbility('ACbn', DR_INCAPACITATES, 'BHbn', DR_MODE_AUTO)
    call DR_RegisterAbility('A6EC', DR_INCAPACITATES, 'BHbn', DR_MODE_AUTO)
    call DR_RegisterAbility('Aply', DR_INCAPACITATES, 'Bply', DR_MODE_AUTO)
    call DR_RegisterAbility('AUsl', DR_INCAPACITATES, 'BUsl', DR_MODE_AUTO)

    call DR_RegisterAbility('Acyc', DR_DISORIENTS, 'Bcyc', DR_MODE_AUTO)
    call DR_RegisterAbility('A6EG', DR_DISORIENTS, 'B61I', DR_MODE_AUTO)

    call DR_RegisterAbility('ANsi', DR_SILENCES, 'BNsi', DR_MODE_AUTO)
    call DR_RegisterAbility('ACsi', DR_SILENCES, 'BNsi', DR_MODE_AUTO)
    call DR_RegisterAbility('AIse', DR_SILENCES, 'BIse', DR_MODE_AUTO)
    call DR_RegisterAbility('ANso', DR_SILENCES, 'BNso', DR_MODE_AUTO)
    call DR_RegisterAbility('A028', DR_SILENCES, 'B01T', DR_MODE_AUTO)
endfunction

private function DR_InitializeTables takes nothing returns nothing
    set DR_StateIndex = Table.createFork(DR_SILENCES - DR_ROOTS + 1)
    set DR_AbilityCache = Table.create()
    set DR_KnownAbilities = Table.create()
    set DR_TargetMutationByAbility = Table.create()
    set DR_AreaMutationByAbility = Table.create()
    set DR_PassivePendingBySource = Table.create()
    set DR_PassiveCache = Table.createFork(2)
    set DR_TrimIndex = Table.create()
    set DR_InternalDummy = Table.create()
endfunction

private function Init takes nothing returns nothing
    call DR_InitializeTables()
    static if LIBRARY_StunGuard then
        set DR_StunGuardConflict = true
        set DR_Enabled = false
        call BJDebugMsg("|cffff0000[DiminishingReturns]|r Disabled because StunGuard is also imported. Import only one CC handler.")
        return
    endif

    set DR_Clock = CreateTimer()
    set DR_PulseTimer = CreateTimer()
    call TimerStart(DR_Clock, 1000000.00, false, null)
    call DR_Configure()
    call DR_Debug("Initialized with " + I2S(DR_BuffCount) + " recognized buffs; TableV6 storage active.")

    call Events_RegisterSpellChannel(function DR_OnSpellChannel)
    call Events_RegisterSpellEffect(function DR_OnSpellEffect)
    call Events_RegisterSpellEndcast(function DR_OnSpellEndcast)
    call Events_RegisterPlayerUnitEvent(function DR_OnDamaging, EVENT_PLAYER_UNIT_DAMAGING)
    call Events_RegisterPlayerUnitEvent(function DR_OnDamaged, EVENT_PLAYER_UNIT_DAMAGED)
    call UnitDeathEvent_Register(function DR_OnDeath)
endfunction

endlibrary
