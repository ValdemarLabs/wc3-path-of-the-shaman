/**
    StunGuard

    Author: Valdemar
    Version: 1.0

    Description:
    StunGuard prevents stun effects from repeatedly resetting the stun duration of units that are already stunned.
    Its purpose is to make stun behavior more consistent and fair, if a unit is already stunned, another stun can still deal its normal damage and other effects, but it will not extend or restart the existing stun.

    The library supports 
    - targeted stuns
    - area-of-effect stuns
    - passive stun abilities

**/
library StunGuard initializer Init
    
globals
    // =========================================================================
    // CONFIGURATION
    // =========================================================================

    private constant boolean DEBUG = true

    // Standard "Stunned (Pause)" buff.
    private constant integer STUN_BUFF = 'BPSE'

    // Required only for AoE stuns.
    // Dummy unit should have Locust, no model, 0 cast point.
    // NOTE: uses patch 3.0 included native dummy unit 'ndum'
    private constant integer DUMMY_ID = 'ndum'

    // Note! Required only for custom stuns.
    // Custom Storm Bolt:
    // - Damage = 0
    // - Mana = 0
    // - Cooldown = 0
    // - Cast point = 0
    // - No missile / effectively instant
    // - Uses Stunned (Pause)
    //
    // IMPORTANT: Do NOT register this ability below as a guarded stun.
    private constant integer DUMMY_STUN_ID = 'A000'

    // Warcraft III 3.0:
    // Gameplay Constant "CanInterruptByZeroDurationBuffs" should be FALSE.
    private constant real SUPPRESS_DURATION = 0.01

    // =========================================================================
    // INTERNAL
    // =========================================================================

    private hashtable HT = InitHashtable()

    private constant integer KEY_ACTIVE = 0
    private constant integer KEY_MODE   = 1
    private constant integer KEY_LEVEL  = 2
    private constant integer KEY_NORMAL = 3
    private constant integer KEY_HERO   = 4
    private constant integer KEY_GROUP  = 5

    private constant integer MODE_TARGET  = 1
    private constant integer MODE_AOE     = 2
    private constant integer MODE_PASSIVE = 3
endglobals


// =============================================================================
// CONFIGURATION: TARGETED STUNS
//
// These abilities have one explicit spell target.
// =============================================================================
private function IsTargetStun takes integer id returns boolean
    if id == 'AHtb' then // Storm Bolt
        return true
    endif

    // Add custom targeted stuns here:
    // if id == 'A001' then
    //     return true
    // endif

    return false
endfunction


// =============================================================================
// CONFIGURATION: AOE STUNS
//
// These have no GetSpellTargetUnit(), so affected units are enumerated.
// =============================================================================
private function IsAoEStun takes integer id returns boolean
    if id == 'AOws' then // War Stomp
        return true
    endif

    // Add custom AoE stuns here.

    return false
endfunction


// =============================================================================
// CONFIGURATION: PASSIVE ATTACK STUNS
//
// Returns the passive stun ability present on the attacker.
// Add custom Bash-based abilities here.
// =============================================================================
private function GetPassiveStunId takes unit u returns integer
    if GetUnitAbilityLevel(u, 'AHbh') > 0 then // Bash
        return 'AHbh'
    endif

    // Example:
    // if GetUnitAbilityLevel(u, 'A002') > 0 then
    //     return 'A002'
    // endif

    return 0
endfunction


// =============================================================================
// Returns whether the unit is already stunned.
// =============================================================================
private function IsStunned takes unit u returns boolean
    if u == null then
        return false
    endif

    return GetUnitAbilityLevel(u, STUN_BUFF) > 0
endfunction


// =============================================================================
// Default AoE target filter.
//
// This matches normal War Stomp reasonably closely.
//
// Adjust here if one of your custom AoE stun abilities can affect:
// - allies
// - flying units
// - structures
// - magic immune units
// =============================================================================
private function IsAoETarget takes unit caster, unit u returns boolean
    if u == null then
        return false
    endif

    if u == caster then
        return false
    endif

    if GetWidgetLife(u) <= 0.405 then
        return false
    endif

    if not IsUnitEnemy(u, GetOwningPlayer(caster)) then
        return false
    endif

    if IsUnitType(u, UNIT_TYPE_STRUCTURE) then
        return false
    endif

    if IsUnitType(u, UNIT_TYPE_FLYING) then
        return false
    endif

    if IsUnitType(u, UNIT_TYPE_MAGIC_IMMUNE) then
        return false
    endif

    return true
endfunction


// =============================================================================
// Restore an ability that StunGuard previously modified.
//
// If an unfinished AoE group exists it is discarded.
// =============================================================================
private function Restore takes ability a returns nothing
    local integer key
    local integer level
    local group g

    if a == null then
        return
    endif

    set key = GetHandleId(a)

    if not LoadBoolean(HT, key, KEY_ACTIVE) then
        return
    endif

    set level = LoadInteger(HT, key, KEY_LEVEL)

    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, level, LoadReal(HT, key, KEY_NORMAL))
    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, level, LoadReal(HT, key, KEY_HERO))

    set g = LoadGroupHandle(HT, key, KEY_GROUP)

    if g != null then
        call DestroyGroup(g)
    endif

    call FlushChildHashtable(HT, key)

    set g = null
endfunction


// =============================================================================
// Save the current duration fields and suppress them.
// =============================================================================
private function Suppress takes ability a, integer level, integer mode returns nothing
    local integer key

    if a == null then
        return
    endif

    call Restore(a)

    set key = GetHandleId(a)

    call SaveBoolean(HT, key, KEY_ACTIVE, true)
    call SaveInteger(HT, key, KEY_MODE, mode)
    call SaveInteger(HT, key, KEY_LEVEL, level)
    call SaveReal(HT, key, KEY_NORMAL, BlzGetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, level))
    call SaveReal(HT, key, KEY_HERO, BlzGetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, level))

    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, level, SUPPRESS_DURATION)
    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, level, SUPPRESS_DURATION)
endfunction


// =============================================================================
// Applies an independent stun.
//
// Used by AoE abilities after their native AoE stun has been suppressed.
// =============================================================================
private function ApplyDummyStun takes unit source, unit target, real duration returns nothing
    local unit dummy
    local ability a

    if source == null then
        return
    endif

    if target == null then
        return
    endif

    if duration <= 0.00 then
        return
    endif

    if GetWidgetLife(target) <= 0.405 then
        return
    endif

    // Something else may have stunned the unit between OnEffect and OnFinish.
    if IsStunned(target) then
        return
    endif

    set dummy = CreateUnit(GetOwningPlayer(source), DUMMY_ID, GetUnitX(target), GetUnitY(target), 0.00)

    call UnitAddAbility(dummy, DUMMY_STUN_ID)

    set a = BlzGetUnitAbility(dummy, DUMMY_STUN_ID)

    if a != null then
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, 0, duration)
        call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, 0, duration)
        call IssueTargetOrder(dummy, "thunderbolt", target)
    endif

    call UnitApplyTimedLife(dummy, 'BTLF', 1.00)

    set a = null
    set dummy = null
endfunction


// =============================================================================
// New spell begins.
//
// Restore any duration left suppressed from a previous targeted cast.
// =============================================================================
private function OnChannel takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer id = GetSpellAbilityId()
    local ability a

    if IsTargetStun(id) or IsAoEStun(id) then
        set a = BlzGetUnitAbility(caster, id)
        call Restore(a)
    endif

    set a = null
    set caster = null
endfunction


// =============================================================================
// TARGETED + AOE SPELL HANDLING
// =============================================================================
private function OnEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit target = GetSpellTargetUnit()
    local unit u
    local integer id = GetSpellAbilityId()
    local integer level
    local integer key
    local integer blocked
    local real aoe
    local ability a
    local group scan
    local group pending

    // =========================================================================
    // TARGETED STUN
    // =========================================================================
    if IsTargetStun(id) then
        if target != null then
            if IsStunned(target) then
                set a = BlzGetUnitAbility(caster, id)

                if a != null then
                    set level = GetUnitAbilityLevel(caster, id) - 1

                    call Suppress(a, level, MODE_TARGET)

                    if DEBUG then
                        call BJDebugMsg("|cffffcc00[StunGuard]|r Prevented targeted stun renewal")
                        call BJDebugMsg("  Target: |cff00ff00" + GetUnitName(target) + "|r")
                        call BJDebugMsg("  Ability: |cff00ccff" + GetObjectName(id) + "|r")
                        call BJDebugMsg("  Caster: " + GetUnitName(caster))
                    endif
                endif
            endif
        endif

    // =========================================================================
    // AOE STUN
    // =========================================================================
    elseif IsAoEStun(id) then
        set a = BlzGetUnitAbility(caster, id)

        if a != null then
            set level = GetUnitAbilityLevel(caster, id) - 1
            set aoe = BlzGetAbilityRealLevelField(a, ABILITY_RLF_AREA_OF_EFFECT, level)

            set scan = CreateGroup()
            set pending = CreateGroup()
            set blocked = 0

            call GroupEnumUnitsInRange(scan, GetUnitX(caster), GetUnitY(caster), aoe, null)

            loop
                set u = FirstOfGroup(scan)
                exitwhen u == null

                call GroupRemoveUnit(scan, u)

                if IsAoETarget(caster, u) then
                    if IsStunned(u) then
                        set blocked = blocked + 1

                        if DEBUG then
                            call BJDebugMsg("|cffffcc00[StunGuard]|r Prevented AoE stun renewal on |cff00ff00" + GetUnitName(u) + "|r")
                            call BJDebugMsg("  Ability: |cff00ccff" + GetObjectName(id) + "|r")
                        endif
                    else
                        call GroupAddUnit(pending, u)
                    endif
                endif
            endloop

            call DestroyGroup(scan)
            set scan = null

            // Only replace the native stun when at least one target needs
            // protection. Otherwise War Stomp runs completely normally.
            if blocked > 0 then
                call Suppress(a, level, MODE_AOE)

                set key = GetHandleId(a)
                call SaveGroupHandle(HT, key, KEY_GROUP, pending)

                if DEBUG then
                    call BJDebugMsg("|cffffcc00[StunGuard]|r " + GetObjectName(id) + " native AoE stun suppressed; protected units: " + I2S(blocked))
                endif
            else
                call DestroyGroup(pending)
            endif

            set pending = null
        endif
    endif

    set a = null
    set u = null
    set target = null
    set caster = null
endfunction


// =============================================================================
// AOE spell finished.
//
// Native stun has now been processed with duration 0.
// Restore the ability and stun only units which were not already stunned.
// =============================================================================
private function OnFinish takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local unit u
    local integer id = GetSpellAbilityId()
    local integer key
    local integer level
    local real normalDuration
    local real heroDuration
    local real duration
    local ability a
    local group pending

    if not IsAoEStun(id) then
        set caster = null
        return
    endif

    set a = BlzGetUnitAbility(caster, id)

    if a == null then
        set caster = null
        return
    endif

    set key = GetHandleId(a)

    if not LoadBoolean(HT, key, KEY_ACTIVE) then
        set a = null
        set caster = null
        return
    endif

    if LoadInteger(HT, key, KEY_MODE) != MODE_AOE then
        set a = null
        set caster = null
        return
    endif

    set level = LoadInteger(HT, key, KEY_LEVEL)
    set normalDuration = LoadReal(HT, key, KEY_NORMAL)
    set heroDuration = LoadReal(HT, key, KEY_HERO)
    set pending = LoadGroupHandle(HT, key, KEY_GROUP)

    // Restore OE values before applying triggered stuns.
    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_NORMAL, level, normalDuration)
    call BlzSetAbilityRealLevelField(a, ABILITY_RLF_DURATION_HERO, level, heroDuration)

    if pending != null then
        loop
            set u = FirstOfGroup(pending)
            exitwhen u == null

            call GroupRemoveUnit(pending, u)

            if IsAoETarget(caster, u) and not IsStunned(u) then
                if IsUnitType(u, UNIT_TYPE_HERO) or IsUnitType(u, UNIT_TYPE_RESISTANT) then
                    set duration = heroDuration
                else
                    set duration = normalDuration
                endif

                call ApplyDummyStun(caster, u, duration)
            endif
        endloop

        call DestroyGroup(pending)
    endif

    call FlushChildHashtable(HT, key)

    set pending = null
    set a = null
    set u = null
    set caster = null
endfunction


// =============================================================================
// Handles interrupted AoE casts.
//
// If SPELL_FINISH never happened, restore the ability and discard pending units.
// =============================================================================
private function OnEndCast takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer id = GetSpellAbilityId()
    local integer key
    local ability a

    if IsAoEStun(id) then
        set a = BlzGetUnitAbility(caster, id)

        if a != null then
            set key = GetHandleId(a)

            if LoadBoolean(HT, key, KEY_ACTIVE) then
                if LoadInteger(HT, key, KEY_MODE) == MODE_AOE then
                    call Restore(a)
                endif
            endif
        endif
    endif

    set a = null
    set caster = null
endfunction


// =============================================================================
// PASSIVE STUN - BEFORE ATTACK DAMAGE
//
// EVENT_PLAYER_UNIT_DAMAGING occurs at damage resolution, which is much better
// than EVENT_PLAYER_UNIT_ATTACKED for ranged units.
//
// If the victim is already stunned, Bash's stun duration is temporarily 0.
// Bash's normal proc chance / bonus damage remain native.
// =============================================================================
private function OnDamaging takes nothing returns nothing
    local unit source
    local unit target
    local integer id
    local integer level
    local ability a

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

    set id = GetPassiveStunId(source)

    if id == 0 then
        set source = null
        set target = null
        return
    endif

    set a = BlzGetUnitAbility(source, id)

    if a != null then
        // Safety: restore anything left behind by an attack which never reached
        // EVENT_PLAYER_UNIT_DAMAGED.
        call Restore(a)

        if IsStunned(target) then
            set level = GetUnitAbilityLevel(source, id) - 1

            call Suppress(a, level, MODE_PASSIVE)

            if DEBUG then
                call BJDebugMsg("|cffffcc00[StunGuard]|r Prevented passive stun renewal")
                call BJDebugMsg("  Target: |cff00ff00" + GetUnitName(target) + "|r")
                call BJDebugMsg("  Ability: |cff00ccff" + GetObjectName(id) + "|r")
                call BJDebugMsg("  Attacker: " + GetUnitName(source))
            endif
        endif
    endif

    set a = null
    set source = null
    set target = null
endfunction


// =============================================================================
// PASSIVE STUN - AFTER ATTACK DAMAGE
//
// Restore Bash immediately after this attack's damage resolution.
// =============================================================================
private function OnDamaged takes nothing returns nothing
    local unit source
    local integer id
    local integer key
    local ability a

    if not BlzGetEventIsAttack() then
        return
    endif

    set source = GetEventDamageSource()

    if source == null then
        return
    endif

    set id = GetPassiveStunId(source)

    if id != 0 then
        set a = BlzGetUnitAbility(source, id)

        if a != null then
            set key = GetHandleId(a)

            if LoadBoolean(HT, key, KEY_ACTIVE) then
                if LoadInteger(HT, key, KEY_MODE) == MODE_PASSIVE then
                    call Restore(a)
                endif
            endif
        endif
    endif

    set a = null
    set source = null
endfunction


// =============================================================================
private function Init takes nothing returns nothing
    local trigger channelTrigger = CreateTrigger()
    local trigger effectTrigger = CreateTrigger()
    local trigger finishTrigger = CreateTrigger()
    local trigger endCastTrigger = CreateTrigger()
    local trigger damagingTrigger = CreateTrigger()
    local trigger damagedTrigger = CreateTrigger()

    call TriggerRegisterAnyUnitEventBJ(channelTrigger, EVENT_PLAYER_UNIT_SPELL_CHANNEL)
    call TriggerRegisterAnyUnitEventBJ(effectTrigger, EVENT_PLAYER_UNIT_SPELL_EFFECT)
    call TriggerRegisterAnyUnitEventBJ(finishTrigger, EVENT_PLAYER_UNIT_SPELL_FINISH)
    call TriggerRegisterAnyUnitEventBJ(endCastTrigger, EVENT_PLAYER_UNIT_SPELL_ENDCAST)
    call TriggerRegisterAnyUnitEventBJ(damagingTrigger, EVENT_PLAYER_UNIT_DAMAGING)
    call TriggerRegisterAnyUnitEventBJ(damagedTrigger, EVENT_PLAYER_UNIT_DAMAGED)

    call TriggerAddAction(channelTrigger, function OnChannel)
    call TriggerAddAction(effectTrigger, function OnEffect)
    call TriggerAddAction(finishTrigger, function OnFinish)
    call TriggerAddAction(endCastTrigger, function OnEndCast)
    call TriggerAddAction(damagingTrigger, function OnDamaging)
    call TriggerAddAction(damagedTrigger, function OnDamaged)

    set channelTrigger = null
    set effectTrigger = null
    set finishTrigger = null
    set endCastTrigger = null
    set damagingTrigger = null
    set damagedTrigger = null
endfunction

endlibrary