/**
    ShamanLightningShield

    Author: Valdemar
    Version:

    Description:
    Lightning Shield periodic damage system converted from old GUI arrays.

    Credits:
    - Old GUI "Lightning Shield Setup", "Lightning Shield Cast", and
      "Lightning Shield Loop" triggers

    How to install:
    Requires `Events` and `ShamanCommon`.

**/
library ShamanLightningShield initializer Init requires Events, ShamanCommon

globals
    private constant integer MAX_SHIELDS = 256
    private constant real PERIOD = 0.10
    private constant real DAMAGE_DELAY = 0.60
    private constant real DURATION = 20.00
    private constant real AOE = 160.00
    private constant real BUFF_REQUIRE_GRACE = 0.35
    private constant string EFFECT_SHIELD = "Abilities\\Spells\\Orc\\LightningShield\\LightningShieldTarget.mdl"
    private constant string EFFECT_DAMAGE = "Abilities\\Spells\\Orc\\LightningShield\\LightningShieldBuff.mdl"

    private timer ShieldTimer = null
    private group EnumGroup = null
    private unit array ShieldCaster
    private unit array ShieldTarget
    private effect array ShieldEffect
    private real array ShieldDamage
    private real array ShieldRemaining
    private real array ShieldDelay
    private real array ShieldAge
    private real array ShieldBuffGrace
    private integer ShieldCount = 0
endglobals

private function RemoveShieldAt takes integer index, boolean removeBuff returns nothing
    if index < 1 or index > ShieldCount then
        return
    endif
    if ShieldEffect[index] != null then
        call DestroyEffect(ShieldEffect[index])
    endif
    if removeBuff and ShieldTarget[index] != null and GetUnitAbilityLevel(ShieldTarget[index], ShamanCommon_BUFF_LIGHTNING_SHIELD) > 0 then
        call UnitRemoveAbility(ShieldTarget[index], ShamanCommon_BUFF_LIGHTNING_SHIELD)
    endif
    set ShieldCaster[index] = ShieldCaster[ShieldCount]
    set ShieldTarget[index] = ShieldTarget[ShieldCount]
    set ShieldEffect[index] = ShieldEffect[ShieldCount]
    set ShieldDamage[index] = ShieldDamage[ShieldCount]
    set ShieldRemaining[index] = ShieldRemaining[ShieldCount]
    set ShieldDelay[index] = ShieldDelay[ShieldCount]
    set ShieldAge[index] = ShieldAge[ShieldCount]
    set ShieldBuffGrace[index] = ShieldBuffGrace[ShieldCount]
    set ShieldCaster[ShieldCount] = null
    set ShieldTarget[ShieldCount] = null
    set ShieldEffect[ShieldCount] = null
    set ShieldBuffGrace[ShieldCount] = 0.00
    set ShieldCount = ShieldCount - 1
    if ShieldCount <= 0 then
        call PauseTimer(ShieldTimer)
    endif
endfunction

private function RemoveShieldForTarget takes unit target returns nothing
    local integer index = 1
    loop
        exitwhen index > ShieldCount
        if ShieldTarget[index] == target then
            call RemoveShieldAt(index, false)
        else
            set index = index + 1
        endif
    endloop
endfunction

private function HasRequiredBuff takes integer index returns boolean
    if ShieldBuffGrace[index] > 0.00 then
        return true
    endif
    return ShieldTarget[index] != null and GetUnitAbilityLevel(ShieldTarget[index], ShamanCommon_BUFF_LIGHTNING_SHIELD) > 0
endfunction

private function DamageNearbyUnits takes integer index returns nothing
    local unit target
    local unit shielded = ShieldTarget[index]
    local unit caster = ShieldCaster[index]
    call GroupClear(EnumGroup)
    call GroupEnumUnitsInRange(EnumGroup, GetUnitX(shielded), GetUnitY(shielded), AOE, null)
    loop
        set target = FirstOfGroup(EnumGroup)
        exitwhen target == null
        call GroupRemoveUnit(EnumGroup, target)
        if target != shielded and ShamanCommon_IsAlive(target) and IsUnitEnemy(target, GetOwningPlayer(caster)) and not IsUnitType(target, UNIT_TYPE_STRUCTURE) and not IsUnitType(target, UNIT_TYPE_MAGIC_IMMUNE) and not IsUnitType(target, UNIT_TYPE_MECHANICAL) and IsUnitType(target, UNIT_TYPE_GROUND) then
            call UnitDamageTarget(caster, target, ShieldDamage[index], true, true, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_MAGIC, null)
            if GetRandomInt(1, 5) <= 2 then
                call DestroyEffect(AddSpecialEffectTarget(EFFECT_DAMAGE, target, "origin"))
            endif
        endif
    endloop
    set caster = null
    set shielded = null
    set target = null
endfunction

private function TickShields takes nothing returns nothing
    local integer index = 1
    loop
        exitwhen index > ShieldCount
        set ShieldAge[index] = ShieldAge[index] + PERIOD
        if ShieldBuffGrace[index] > 0.00 then
            set ShieldBuffGrace[index] = ShieldBuffGrace[index] - PERIOD
            if ShieldBuffGrace[index] < 0.00 then
                set ShieldBuffGrace[index] = 0.00
            endif
        endif
        if not ShamanCommon_IsAlive(ShieldTarget[index]) or ShieldRemaining[index] <= 0.00 then
            call RemoveShieldAt(index, ShieldRemaining[index] <= 0.00)
        elseif not HasRequiredBuff(index) then
            call RemoveShieldAt(index, false)
        elseif ShieldDelay[index] >= PERIOD then
            set ShieldDelay[index] = ShieldDelay[index] - PERIOD
            set index = index + 1
        else
            set ShieldRemaining[index] = ShieldRemaining[index] - PERIOD
            call DamageNearbyUnits(index)
            set index = index + 1
        endif
    endloop
endfunction

private function ApplyShield takes unit caster, unit target returns nothing
    local integer rank
    local real damagePerSecond
    if caster == null or target == null or ShieldCount >= MAX_SHIELDS then
        return
    endif
    call RemoveShieldForTarget(target)
    set rank = ShamanCommon_GetAbilityRank(caster, ShamanCommon_ABILITY_LIGHTNING_SHIELD)
    set damagePerSecond = ShamanCommon_GetDamageAmount(caster, ShamanCommon_ABILITY_LIGHTNING_SHIELD, AbilitiesPlayerInit_VALUE_BASE, ShamanCommon_STAT_INTELLIGENCE, 0.65)
    set ShieldCount = ShieldCount + 1
    set ShieldCaster[ShieldCount] = caster
    set ShieldTarget[ShieldCount] = target
    set ShieldDamage[ShieldCount] = damagePerSecond * PERIOD
    set ShieldRemaining[ShieldCount] = DURATION
    set ShieldDelay[ShieldCount] = DAMAGE_DELAY
    set ShieldAge[ShieldCount] = 0.00
    set ShieldBuffGrace[ShieldCount] = BUFF_REQUIRE_GRACE
    set ShieldEffect[ShieldCount] = AddSpecialEffectTarget(EFFECT_SHIELD, target, "origin")
    call TimerStart(ShieldTimer, PERIOD, true, function TickShields)
endfunction

private function HandleSpellEffect takes nothing returns nothing
    if GetSpellAbilityId() == ShamanCommon_ABILITY_LIGHTNING_SHIELD then
        call ApplyShield(GetTriggerUnit(), GetSpellTargetUnit())
    endif
endfunction

private function Init takes nothing returns nothing
    set ShieldTimer = CreateTimer()
    set EnumGroup = CreateGroup()
    call Events_RegisterSpellEffect(function HandleSpellEffect)
endfunction

endlibrary
