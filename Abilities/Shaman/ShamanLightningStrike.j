/**
    ShamanLightningStrike

    Author: Valdemar
    Version:

    Description:
    Lightning Strike damage, lightning dummy visuals, and knockback converted
    from the old GUI triggers.

    Credits:
    - Old GUI "Lightning Strike", "Cast A Knockback", and "GetKnockback" triggers

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanLightningStrike initializer Init requires Events, ShamanCommon

globals
    private constant integer MAX_KNOCKBACKS = 128
    private constant real STRIKE_RADIUS = 250.00
    private constant real KNOCKBACK_PERIOD = 0.02
    private constant real KNOCKBACK_SPEED = 9.00
    private constant real KNOCKBACK_DISTANCE_PER_LEVEL = 100.00
    private constant real LIGHTNING_START_OFFSET = 400.00
    private constant string EFFECT_THUNDER = "Abilities\\Spells\\Human\\ThunderClap\\ThunderClapCaster.mdl"
    private constant string EFFECT_FARSEER = "Abilities\\Weapons\\FarseerMissile\\FarseerMissile.mdl"
    private constant string EFFECT_FLAK = "Abilities\\Spells\\Human\\FlakCannons\\FlakTarget.mdl"

    private timer KnockbackTimer = null
    private group EnumGroup = null
    private unit array KnockbackUnit
    private real array KnockbackAngle
    private real array KnockbackMaxDistance
    private real array KnockbackReachedDistance
    private real array KnockbackReduceSpeed
    private real array KnockbackSpecificSpeed
    private integer KnockbackCount = 0
endglobals

private function RemoveKnockbackAt takes integer index returns nothing
    if index < 1 or index > KnockbackCount then
        return
    endif
    set KnockbackUnit[index] = KnockbackUnit[KnockbackCount]
    set KnockbackAngle[index] = KnockbackAngle[KnockbackCount]
    set KnockbackMaxDistance[index] = KnockbackMaxDistance[KnockbackCount]
    set KnockbackReachedDistance[index] = KnockbackReachedDistance[KnockbackCount]
    set KnockbackReduceSpeed[index] = KnockbackReduceSpeed[KnockbackCount]
    set KnockbackSpecificSpeed[index] = KnockbackSpecificSpeed[KnockbackCount]
    set KnockbackUnit[KnockbackCount] = null
    set KnockbackCount = KnockbackCount - 1
    if KnockbackCount <= 0 then
        call PauseTimer(KnockbackTimer)
    endif
endfunction

private function RemoveExistingKnockback takes unit target returns nothing
    local integer index = 1
    loop
        exitwhen index > KnockbackCount
        if KnockbackUnit[index] == target then
            call RemoveKnockbackAt(index)
        else
            set index = index + 1
        endif
    endloop
endfunction

private function TickKnockback takes nothing returns nothing
    local integer index = 1
    local unit target
    local real reduced
    local real step
    local real x
    local real y
    loop
        exitwhen index > KnockbackCount
        set target = KnockbackUnit[index]
        if not ShamanCommon_IsAlive(target) or KnockbackReachedDistance[index] >= KnockbackMaxDistance[index] then
            call RemoveKnockbackAt(index)
        else
            set reduced = (KnockbackSpecificSpeed[index] / KnockbackMaxDistance[index]) * KnockbackReachedDistance[index]
            set KnockbackReduceSpeed[index] = reduced - (KnockbackReduceSpeed[index] * 0.10)
            set step = (KnockbackSpecificSpeed[index] - KnockbackReduceSpeed[index]) * 2.00
            set x = GetUnitX(target)
            set y = GetUnitY(target)
            if GetRandomInt(1, 5) == 1 then
                call DestroyEffect(AddSpecialEffect(EFFECT_FLAK, x, y))
            endif
            if GetRandomInt(1, 7) == 1 then
                call DestroyEffect(AddSpecialEffect(EFFECT_FARSEER, x, y))
            endif
            call SetUnitPosition(target, ShamanCommon_PolarX(x, step, KnockbackAngle[index]), ShamanCommon_PolarY(y, step, KnockbackAngle[index]))
            set KnockbackReachedDistance[index] = KnockbackReachedDistance[index] + step
            set index = index + 1
        endif
    endloop
    set target = null
endfunction

private function StartKnockback takes unit target, real startX, real startY, integer rank returns nothing
    if target == null or KnockbackCount >= MAX_KNOCKBACKS then
        return
    endif
    call RemoveExistingKnockback(target)
    set KnockbackCount = KnockbackCount + 1
    set KnockbackUnit[KnockbackCount] = target
    set KnockbackAngle[KnockbackCount] = ShamanCommon_AngleBetweenCoordinates(startX, startY, GetUnitX(target), GetUnitY(target))
    set KnockbackMaxDistance[KnockbackCount] = KNOCKBACK_DISTANCE_PER_LEVEL * I2R(rank)
    set KnockbackReachedDistance[KnockbackCount] = 0.00
    set KnockbackReduceSpeed[KnockbackCount] = 0.00
    set KnockbackSpecificSpeed[KnockbackCount] = KNOCKBACK_SPEED
    call TimerStart(KnockbackTimer, KNOCKBACK_PERIOD, true, function TickKnockback)
endfunction

private function CreateLightningVisuals takes unit caster, real x, real y returns nothing
    local real casterX = GetUnitX(caster)
    local real casterY = GetUnitY(caster)
    local real angle = ShamanCommon_AngleBetweenCoordinates(x, y, casterX, casterY)
    local unit downDummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_LIGHTNING_STRIKE_DOWN, x, y, bj_UNIT_FACING, 0.50)
    local unit lightningDummy
    local integer index = 1
    call SetUnitExploded(downDummy, true)
    loop
        exitwhen index > 3
        set lightningDummy = ShamanCommon_CreateTimedDummy(GetOwningPlayer(caster), ShamanCommon_DUMMY_LIGHTNING_STRIKE, ShamanCommon_PolarX(x, LIGHTNING_START_OFFSET, angle), ShamanCommon_PolarY(y, LIGHTNING_START_OFFSET, angle), bj_UNIT_FACING, 0.50)
        call IssueTargetOrder(lightningDummy, "fingerofdeath", downDummy)
        call SetUnitExploded(lightningDummy, true)
        set index = index + 1
    endloop
    set lightningDummy = null
    set downDummy = null
endfunction

private function DamageStrikeTargets takes unit caster, real x, real y, real amount, integer rank returns nothing
    local unit target
    call GroupClear(EnumGroup)
    call GroupEnumUnitsInRange(EnumGroup, x, y, STRIKE_RADIUS, null)
    loop
        set target = FirstOfGroup(EnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(EnumGroup, target)
        if ShamanCommon_IsHostileGroundTarget(caster, target, false) then
            call UnitDamageTarget(caster, target, amount, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_NORMAL, null)
            call StartKnockback(target, x, y, rank)
        endif
    endloop
    set target = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local unit caster = GetTriggerUnit()
    local integer rank
    local real x
    local real y
    local real amount
    if GetSpellAbilityId() == ShamanCommon_ABILITY_LIGHTNING_STRIKE then
        set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_LIGHTNING_STRIKE)
        set x = GetSpellTargetX()
        set y = GetSpellTargetY()
        set amount = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_LIGHTNING_STRIKE, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 1.50)
        call ShamanCommon_PlaySoundLabelOnUnit("LightningStrike", caster)
        call CreateLightningVisuals(caster, x, y)
        call DestroyEffect(AddSpecialEffect(EFFECT_THUNDER, x, y))
        call DestroyEffect(AddSpecialEffect(EFFECT_FARSEER, x, y))
        call DamageStrikeTargets(caster, x, y, amount, rank)
        call ShamanCommon_ApplyCooldownReduction(caster, ShamanCommon_ABILITY_LIGHTNING_STRIKE)
    endif
    set caster = null
endfunction

private function Init takes nothing returns nothing
    set KnockbackTimer = CreateTimer()
    set EnumGroup = CreateGroup()
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
