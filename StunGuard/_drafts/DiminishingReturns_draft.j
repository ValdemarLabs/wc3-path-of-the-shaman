/**
    DiminishingReturns

    Author: Valdemar
    Version: 1.0

    Description:
    Configurable crowd-control diminishing returns, or StunGuard-style rejection
    while any buff in an ability's shared control group is active.

    Credits:
    Based on StunGuard.

    How to install:
    Import instead of StunGuard, configure Configure(), and create DUMMY_STUN_ID
    as a zero-damage, zero-cost, zero-cooldown, instant Storm Bolt with no missile
    and the grouped stun buff. Do not register that dummy ability. Gameplay
    Constant "CanInterruptByZeroDurationBuffs" must be FALSE.

    API:
    DiminishingReturns_SetScale(stage, multiplier)
    DiminishingReturns_SetResetWindow(seconds)
    DiminishingReturns_RegisterBuff(groupId, buffId)
    DiminishingReturns_RegisterTargetStun(abilityId, groupId, behavior)
    DiminishingReturns_RegisterAoEStun(abilityId, groupId, behavior)
    DiminishingReturns_RegisterPassiveStun(abilityId, groupId, behavior)
    DiminishingReturns_GetStage(target, groupId)
    DiminishingReturns_Reset(target, groupId)
**/
library DiminishingReturns initializer Init

globals
    // Configuration
    private constant boolean DEBUG = true
    private constant integer DUMMY_ID = 'ndum'
    private constant integer DUMMY_STUN_ID = 'A000'
    private constant real SUPPRESS_DURATION = 0.01

    public constant integer BEHAVIOR_REJECT = 1
    public constant integer BEHAVIOR_DIMINISH = 2

    private constant integer KIND_TARGET = 1
    private constant integer KIND_AOE = 2
    private constant integer KIND_PASSIVE = 3
    private constant integer C_KIND = 0
    private constant integer C_GROUP = 1
    private constant integer C_BEHAVIOR = 2
    private constant integer A_KIND = 0
    private constant integer A_LEVEL = 1
    private constant integer A_NORMAL = 2
    private constant integer A_HERO = 3
    private constant integer A_GROUP = 4
    private constant integer A_TARGET = 5
    private constant integer A_HAD_BUFF = 6
    private constant integer A_DURATION = 7
    private constant integer A_BEHAVIOR = 8
    private constant integer A_PENDING = 9

    private hashtable Config = InitHashtable()
    private hashtable Buffs = InitHashtable()
    private hashtable Active = InitHashtable()
    private hashtable Stages = InitHashtable()
    private hashtable Expires = InitHashtable()
    private real array Scale
    private integer ScaleCount = 0
    private real ResetWindow = 18.00
    private integer array PassiveId
    private integer PassiveCount = 0
    private timer Clock = null
endglobals


// =============================================================================
// PUBLIC CONFIGURATION
// =============================================================================
public function SetScale takes integer stage, real multiplier returns nothing
    if stage < 0 then
        return
    endif
    if multiplier < 0.00 then
        set multiplier = 0.00
    endif
    set Scale[stage] = multiplier
    if stage >= ScaleCount then
        set ScaleCount = stage + 1
    endif
endfunction


public function SetResetWindow takes real seconds returns nothing
    if seconds < 0.00 then
        set seconds = 0.00
    endif
    set ResetWindow = seconds
endfunction


public function RegisterBuff takes integer groupId, integer buffId returns nothing
    local integer count
    if groupId == 0 or buffId == 0 then
        return
    endif
    set count = LoadInteger(Buffs, groupId, 0) + 1
    call SaveInteger(Buffs, groupId, 0, count)
    call SaveInteger(Buffs, groupId, count, buffId)
endfunction


private function RegisterStun takes integer abilityId, integer groupId, integer behavior, integer kind returns boolean
    if abilityId == 0 or groupId == 0 then
        return false
    endif
    if behavior != BEHAVIOR_REJECT and behavior != BEHAVIOR_DIMINISH then
        if DEBUG then
            call BJDebugMsg("|cffffcc00[DiminishingReturns]|r Invalid behavior for " + GetObjectName(abilityId))
        endif
        return false
    endif
    call SaveInteger(Config, abilityId, C_KIND, kind)
    call SaveInteger(Config, abilityId, C_GROUP, groupId)
    call SaveInteger(Config, abilityId, C_BEHAVIOR, behavior)
    return true
endfunction


public function RegisterTargetStun takes integer abilityId, integer groupId, integer behavior returns nothing
    call RegisterStun(abilityId, groupId, behavior, KIND_TARGET)
endfunction


public function RegisterAoEStun takes integer abilityId, integer groupId, integer behavior returns nothing
    call RegisterStun(abilityId, groupId, behavior, KIND_AOE)
endfunction


public function RegisterPassiveStun takes integer abilityId, integer groupId, integer behavior returns nothing
    local integer oldKind = LoadInteger(Config, abilityId, C_KIND)
    if RegisterStun(abilityId, groupId, behavior, KIND_PASSIVE) and oldKind != KIND_PASSIVE then
        set PassiveCount = PassiveCount + 1
        set PassiveId[PassiveCount] = abilityId
    endif
endfunction


// The reset window starts after the expected end of the latest accepted effect.
// Immune attempts do not advance or refresh it.
private function CurrentStage takes unit target, integer groupId returns integer
    local integer targetKey
    if target == null or groupId == 0 then
        return 0
    endif
    set targetKey = GetHandleId(target)
    if not HaveSavedInteger(Stages, targetKey, groupId) then
        return 0
    endif
    if TimerGetElapsed(Clock) >= LoadReal(Expires, targetKey, groupId) then
        call RemoveSavedInteger(Stages, targetKey, groupId)
        call RemoveSavedReal(Expires, targetKey, groupId)
        return 0
    endif
    return LoadInteger(Stages, targetKey, groupId)
endfunction


public function GetStage takes unit target, integer groupId returns integer
    return CurrentStage(target, groupId)
endfunction


public function Reset takes unit target, integer groupId returns nothing
    if target != null and groupId != 0 then
        call RemoveSavedInteger(Stages, GetHandleId(target), groupId)
        call RemoveSavedReal(Expires, GetHandleId(target), groupId)
    endif
endfunction


private function StageScale takes unit target, integer groupId returns real
    local integer stage = CurrentStage(target, groupId)
    if ScaleCount == 0 then
        return 1.00
    endif
    if stage >= ScaleCount then
        set stage = ScaleCount - 1
    endif
    return Scale[stage]
endfunction


private function Advance takes unit target, integer groupId, real duration returns nothing
    local integer stage
    local integer targetKey
    if target == null or groupId == 0 or duration <= 0.00 then
        return
    endif
    set targetKey = GetHandleId(target)
    set stage = CurrentStage(target, groupId) + 1
    if ScaleCount > 0 and stage >= ScaleCount then
        set stage = ScaleCount - 1
    endif
    call SaveInteger(Stages, targetKey, groupId, stage)
    call SaveReal(Expires, targetKey, groupId, TimerGetElapsed(Clock) + duration + ResetWindow)
endfunction


private function HasGroupBuff takes unit target, integer groupId returns boolean
    local integer index = 1
    local integer count
    if target == null or groupId == 0 then
        return false
    endif
    set count = LoadInteger(Buffs, groupId, 0)
    loop
        exitwhen index > count
        if GetUnitAbilityLevel(target, LoadInteger(Buffs, groupId, index)) > 0 then
            return true
        endif
        set index = index + 1
    endloop
    return false
endfunction


private function GetPassiveId takes unit source returns integer
    local integer index = 1
    loop
        exitwhen index > PassiveCount
        if LoadInteger(Config, PassiveId[index], C_KIND) == KIND_PASSIVE and GetUnitAbilityLevel(source, PassiveId[index]) > 0 then
            return PassiveId[index]
        endif
        set index = index + 1
    endloop
    return 0
endfunction


private function DurationFor takes unit target, real normalDuration, real heroDuration returns real
    if IsUnitType(target, UNIT_TYPE_HERO) or IsUnitType(target, UNIT_TYPE_RESISTANT) then
        return heroDuration
    endif
    return normalDuration
endfunction


// Adjust this for registered AoE abilities with different targeting rules.
private function IsAoETarget takes unit caster, unit target returns boolean
    if target == null or target == caster or GetWidgetLife(target) <= 0.405 then
        return false
    endif
    if not IsUnitEnemy(target, GetOwningPlayer(caster)) then
        return false
    endif
    if IsUnitType(target, UNIT_TYPE_STRUCTURE) or IsUnitType(target, UNIT_TYPE_FLYING) then
        return false
    endif
    return not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE)
endfunction


private function Restore takes ability whichAbility returns nothing
    local integer key
    local integer level
    local group pending
    if whichAbility == null then
        return
    endif
    set key = GetHandleId(whichAbility)
    if not HaveSavedInteger(Active, key, A_KIND) then
        return
    endif
    set level = LoadInteger(Active, key, A_LEVEL)
    call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, LoadReal(Active, key, A_NORMAL))
    call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, LoadReal(Active, key, A_HERO))
    set pending = LoadGroupHandle(Active, key, A_PENDING)
    if pending != null then
        call DestroyGroup(pending)
    endif
    call FlushChildHashtable(Active, key)
    set pending = null
endfunction


private function Modify takes ability whichAbility, integer level, integer kind, real normalDuration, real heroDuration returns nothing
    local integer key
    if whichAbility == null then
        return
    endif
    call Restore(whichAbility)
    set key = GetHandleId(whichAbility)
    call SaveInteger(Active, key, A_KIND, kind)
    call SaveInteger(Active, key, A_LEVEL, level)
    call SaveReal(Active, key, A_NORMAL, BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level))
    call SaveReal(Active, key, A_HERO, BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level))
    call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level, normalDuration)
    call BlzSetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level, heroDuration)
endfunction


private function DummyStun takes unit source, unit target, real duration returns boolean
    local unit dummy
    local ability dummyAbility
    local boolean issued = false
    if source == null or target == null or duration <= 0.00 or GetWidgetLife(target) <= 0.405 then
        return false
    endif
    set dummy = CreateUnit(GetOwningPlayer(source), DUMMY_ID, GetUnitX(target), GetUnitY(target), 0.00)
    call UnitAddAbility(dummy, DUMMY_STUN_ID)
    set dummyAbility = BlzGetUnitAbility(dummy, DUMMY_STUN_ID)
    if dummyAbility != null then
        call BlzSetAbilityRealLevelField(dummyAbility, ABILITY_RLF_DURATION_NORMAL, 0, duration)
        call BlzSetAbilityRealLevelField(dummyAbility, ABILITY_RLF_DURATION_HERO, 0, duration)
        set issued = IssueTargetOrder(dummy, "thunderbolt", target)
    endif
    call UnitApplyTimedLife(dummy, 'BTLF', 1.00)
    set dummyAbility = null
    set dummy = null
    return issued
endfunction


private function DebugResult takes string result, unit target, integer abilityId, real scale returns nothing
    if DEBUG then
        call BJDebugMsg("|cffffcc00[DiminishingReturns]|r " + result)
        call BJDebugMsg("  Target: |cff00ff00" + GetUnitName(target) + "|r")
        call BJDebugMsg("  Ability: |cff00ccff" + GetObjectName(abilityId) + "|r")
        if scale >= 0.00 then
            call BJDebugMsg("  Duration scale: " + R2S(scale))
        endif
    endif
endfunction


private function OnChannel takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local ability whichAbility
    if LoadInteger(Config, abilityId, C_KIND) != 0 then
        set whichAbility = BlzGetUnitAbility(caster, abilityId)
        call Restore(whichAbility)
    endif
    set whichAbility = null
    set caster = null
endfunction


private function TargetStun takes unit caster, unit target, integer abilityId returns nothing
    local integer behavior = LoadInteger(Config, abilityId, C_BEHAVIOR)
    local integer groupId = LoadInteger(Config, abilityId, C_GROUP)
    local integer level
    local real normalDuration
    local real heroDuration
    local real duration
    local real multiplier
    local ability whichAbility
    if target == null then
        return
    endif
    set whichAbility = BlzGetUnitAbility(caster, abilityId)
    if whichAbility == null then
        return
    endif
    set level = GetUnitAbilityLevel(caster, abilityId) - 1
    set normalDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level)
    set heroDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level)
    set duration = DurationFor(target, normalDuration, heroDuration)

    if behavior == BEHAVIOR_REJECT then
        if HasGroupBuff(target, groupId) then
            call Modify(whichAbility, level, KIND_TARGET, SUPPRESS_DURATION, SUPPRESS_DURATION)
            call DebugResult("Rejected targeted stun reapplication", target, abilityId, -1.00)
        endif
    else
        set multiplier = StageScale(target, groupId)
        if multiplier <= 0.00 then
            call Modify(whichAbility, level, KIND_TARGET, SUPPRESS_DURATION, SUPPRESS_DURATION)
            call DebugResult("Target is immune through diminishing returns", target, abilityId, 0.00)
        else
            if multiplier < 1.00 then
                call Modify(whichAbility, level, KIND_TARGET, normalDuration * multiplier, heroDuration * multiplier)
            endif
            call Advance(target, groupId, duration * multiplier)
            call DebugResult("Applied targeted stun", target, abilityId, multiplier)
        endif
    endif
    set whichAbility = null
endfunction


private function AoEStun takes unit caster, integer abilityId returns nothing
    local integer behavior = LoadInteger(Config, abilityId, C_BEHAVIOR)
    local integer groupId = LoadInteger(Config, abilityId, C_GROUP)
    local integer level
    local integer key
    local integer replaced = 0
    local real area
    local real normalDuration
    local real heroDuration
    local real duration
    local real multiplier
    local unit target
    local ability whichAbility = BlzGetUnitAbility(caster, abilityId)
    local group scan
    local group pending
    if whichAbility == null then
        return
    endif
    set level = GetUnitAbilityLevel(caster, abilityId) - 1
    set key = GetHandleId(whichAbility)
    set area = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_AREA_OF_EFFECT, level)
    set normalDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level)
    set heroDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level)
    set scan = CreateGroup()
    set pending = CreateGroup()
    call GroupEnumUnitsInRange(scan, GetUnitX(caster), GetUnitY(caster), area, null)

    loop
        set target = FirstOfGroup(scan)
        exitwhen target == null
        call GroupRemoveUnit(scan, target)
        if IsAoETarget(caster, target) then
            set duration = DurationFor(target, normalDuration, heroDuration)
            if behavior == BEHAVIOR_REJECT then
                if HasGroupBuff(target, groupId) then
                    set replaced = replaced + 1
                    call DebugResult("Rejected AoE stun reapplication", target, abilityId, -1.00)
                else
                    call GroupAddUnit(pending, target)
                    call SaveReal(Active, key, GetHandleId(target), duration)
                endif
            else
                set multiplier = StageScale(target, groupId)
                if multiplier <= 0.00 then
                    set replaced = replaced + 1
                    call DebugResult("AoE target is immune through diminishing returns", target, abilityId, 0.00)
                else
                    call GroupAddUnit(pending, target)
                    call SaveReal(Active, key, GetHandleId(target), duration * multiplier)
                    if multiplier < 1.00 then
                        set replaced = replaced + 1
                    endif
                endif
            endif
        endif
    endloop
    call DestroyGroup(scan)
    set scan = null

    if replaced > 0 then
        call Modify(whichAbility, level, KIND_AOE, SUPPRESS_DURATION, SUPPRESS_DURATION)
        set key = GetHandleId(whichAbility)
        call SaveInteger(Active, key, A_BEHAVIOR, behavior)
        call SaveInteger(Active, key, A_GROUP, groupId)
        call SaveGroupHandle(Active, key, A_PENDING, pending)
        set pending = null
    else
        loop
            set target = FirstOfGroup(pending)
            exitwhen target == null
            call GroupRemoveUnit(pending, target)
            if behavior == BEHAVIOR_DIMINISH then
                call Advance(target, groupId, LoadReal(Active, key, GetHandleId(target)))
            endif
        endloop
        call DestroyGroup(pending)
        call FlushChildHashtable(Active, key)
        set pending = null
    endif
    set whichAbility = null
    set target = null
endfunction


private function OnEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target
    local integer abilityId = GetSpellAbilityId()
    local integer kind = LoadInteger(Config, abilityId, C_KIND)
    if kind == KIND_TARGET then
        set target = GetSpellTargetUnit()
        call TargetStun(caster, target, abilityId)
    elseif kind == KIND_AOE then
        call AoEStun(caster, abilityId)
    endif
    set target = null
    set caster = null
endfunction


private function OnFinish takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target
    local integer abilityId = GetSpellAbilityId()
    local integer groupId
    local integer behavior
    local integer key
    local real duration
    local ability whichAbility
    local group pending
    if LoadInteger(Config, abilityId, C_KIND) != KIND_AOE then
        set caster = null
        return
    endif
    set whichAbility = BlzGetUnitAbility(caster, abilityId)
    if whichAbility == null then
        set caster = null
        return
    endif
    set key = GetHandleId(whichAbility)
    if LoadInteger(Active, key, A_KIND) != KIND_AOE then
        set whichAbility = null
        set caster = null
        return
    endif
    set groupId = LoadInteger(Active, key, A_GROUP)
    set behavior = LoadInteger(Active, key, A_BEHAVIOR)
    set pending = LoadGroupHandle(Active, key, A_PENDING)
    if pending != null then
        loop
            set target = FirstOfGroup(pending)
            exitwhen target == null
            call GroupRemoveUnit(pending, target)
            set duration = LoadReal(Active, key, GetHandleId(target))
            if IsAoETarget(caster, target) then
                if behavior == BEHAVIOR_DIMINISH or not HasGroupBuff(target, groupId) then
                    if DummyStun(caster, target, duration) and behavior == BEHAVIOR_DIMINISH then
                        call Advance(target, groupId, duration)
                    endif
                endif
            endif
        endloop
    endif
    call Restore(whichAbility)
    set pending = null
    set whichAbility = null
    set target = null
    set caster = null
endfunction


private function OnEndCast takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local ability whichAbility
    if LoadInteger(Config, abilityId, C_KIND) != 0 then
        set whichAbility = BlzGetUnitAbility(caster, abilityId)
        call Restore(whichAbility)
    endif
    set whichAbility = null
    set caster = null
endfunction


// Passive diminishing can confirm only a newly appearing buff. Native Bash does
// not expose whether it proc-refreshed a grouped buff which was already active.
private function OnDamaging takes nothing returns nothing
    local unit source
    local unit target
    local integer abilityId
    local integer behavior
    local integer groupId
    local integer level
    local integer key
    local real normalDuration
    local real heroDuration
    local real duration
    local real multiplier = 1.00
    local ability whichAbility
    if not BlzGetEventIsAttack() then
        return
    endif
    set source = GetEventDamageSource()
    set target = BlzGetEventDamageTarget()
    if source == null or target == null then
        set source = null
        set target = null
        return
    endif
    set abilityId = GetPassiveId(source)
    if abilityId == 0 then
        set source = null
        set target = null
        return
    endif
    set whichAbility = BlzGetUnitAbility(source, abilityId)
    if whichAbility != null then
        call Restore(whichAbility)
        set behavior = LoadInteger(Config, abilityId, C_BEHAVIOR)
        set groupId = LoadInteger(Config, abilityId, C_GROUP)
        set level = GetUnitAbilityLevel(source, abilityId) - 1
        set normalDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_NORMAL, level)
        set heroDuration = BlzGetAbilityRealLevelField(whichAbility, ABILITY_RLF_DURATION_HERO, level)
        set duration = DurationFor(target, normalDuration, heroDuration)

        if behavior == BEHAVIOR_REJECT then
            if HasGroupBuff(target, groupId) then
                call Modify(whichAbility, level, KIND_PASSIVE, SUPPRESS_DURATION, SUPPRESS_DURATION)
                call DebugResult("Rejected passive stun reapplication", target, abilityId, -1.00)
            endif
        else
            set multiplier = StageScale(target, groupId)
            if multiplier <= 0.00 then
                call Modify(whichAbility, level, KIND_PASSIVE, SUPPRESS_DURATION, SUPPRESS_DURATION)
            else
                call Modify(whichAbility, level, KIND_PASSIVE, normalDuration * multiplier, heroDuration * multiplier)
            endif
            set key = GetHandleId(whichAbility)
            call SaveInteger(Active, key, A_TARGET, GetHandleId(target))
            call SaveBoolean(Active, key, A_HAD_BUFF, HasGroupBuff(target, groupId))
            call SaveReal(Active, key, A_DURATION, duration * multiplier)
            call SaveInteger(Active, key, A_GROUP, groupId)
            call SaveInteger(Active, key, A_BEHAVIOR, behavior)
        endif
    endif
    set whichAbility = null
    set source = null
    set target = null
endfunction


private function OnDamaged takes nothing returns nothing
    local unit source
    local unit target = BlzGetEventDamageTarget()
    local integer abilityId
    local integer groupId
    local integer key
    local ability whichAbility
    if not BlzGetEventIsAttack() then
        set target = null
        return
    endif
    set source = GetEventDamageSource()
    if source == null then
        set target = null
        return
    endif
    set abilityId = GetPassiveId(source)
    if abilityId != 0 then
        set whichAbility = BlzGetUnitAbility(source, abilityId)
        if whichAbility != null then
            set key = GetHandleId(whichAbility)
            if LoadInteger(Active, key, A_KIND) == KIND_PASSIVE then
                set groupId = LoadInteger(Active, key, A_GROUP)
                if LoadInteger(Active, key, A_BEHAVIOR) == BEHAVIOR_DIMINISH then
                    if GetHandleId(target) == LoadInteger(Active, key, A_TARGET) then
                        if not LoadBoolean(Active, key, A_HAD_BUFF) and HasGroupBuff(target, groupId) then
                            call Advance(target, groupId, LoadReal(Active, key, A_DURATION))
                        endif
                    endif
                endif
                call Restore(whichAbility)
            endif
        endif
    endif
    set whichAbility = null
    set source = null
    set target = null
endfunction


private function OnDeath takes nothing returns nothing
    local unit target = GetTriggerUnit()
    local integer targetKey = GetHandleId(target)
    call FlushChildHashtable(Stages, targetKey)
    call FlushChildHashtable(Expires, targetKey)
    set target = null
endfunction


// =============================================================================
// PROJECT CONFIGURATION
// =============================================================================
private function Configure takes nothing returns nothing
    local integer stunGroup = 'DRst'

    // Traditional WC3-friendly model: full, half, quarter, immune.
    call SetScale(0, 1.00)
    call SetScale(1, 0.50)
    call SetScale(2, 0.25)
    call SetScale(3, 0.00)
    call SetResetWindow(18.00)

    // Every buff registered to a group counts as the same control category.
    call RegisterBuff(stunGroup, 'BPSE')
    call RegisterTargetStun('AHtb', stunGroup, BEHAVIOR_DIMINISH)
    call RegisterAoEStun('AOws', stunGroup, BEHAVIOR_DIMINISH)
    call RegisterPassiveStun('AHbh', stunGroup, BEHAVIOR_DIMINISH)

    // Examples:
    // call RegisterBuff(stunGroup, 'B001')
    // call RegisterTargetStun('A001', stunGroup, BEHAVIOR_REJECT)

    set stunGroup = 0
endfunction


private function Init takes nothing returns nothing
    local trigger channelTrigger = CreateTrigger()
    local trigger effectTrigger = CreateTrigger()
    local trigger finishTrigger = CreateTrigger()
    local trigger endCastTrigger = CreateTrigger()
    local trigger damagingTrigger = CreateTrigger()
    local trigger damagedTrigger = CreateTrigger()
    local trigger deathTrigger = CreateTrigger()

    set Clock = CreateTimer()
    call TimerStart(Clock, 1000000.00, false, null)
    call Configure()

    call TriggerRegisterAnyUnitEventBJ(channelTrigger, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call TriggerRegisterAnyUnitEventBJ(effectTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerRegisterAnyUnitEventBJ(finishTrigger, EVENT_PLAYER_UNIT_SPELL_FINISH)
    call TriggerRegisterAnyUnitEventBJ(endCastTrigger, EVENT_PLAYER_UNIT_SPELL_ENDCAST)
    call TriggerRegisterAnyUnitEventBJ(damagingTrigger, EVENT_PLAYER_UNIT_DAMAGING)
    call TriggerRegisterAnyUnitEventBJ(damagedTrigger, EVENT_PLAYER_UNIT_DAMAGED)
    call TriggerRegisterAnyUnitEventBJ(deathTrigger, EVENT_PLAYER_UNIT_DEATH)

    call TriggerAddAction(channelTrigger, function OnChannel)
    call TriggerAddAction(effectTrigger, function OnEffect)
    call TriggerAddAction(finishTrigger, function OnFinish)
    call TriggerAddAction(endCastTrigger, function OnEndCast)
    call TriggerAddAction(damagingTrigger, function OnDamaging)
    call TriggerAddAction(damagedTrigger, function OnDamaged)
    call TriggerAddAction(deathTrigger, function OnDeath)

    set channelTrigger = null
    set effectTrigger = null
    set finishTrigger = null
    set endCastTrigger = null
    set damagingTrigger = null
    set damagedTrigger = null
    set deathTrigger = null
endfunction

endlibrary
