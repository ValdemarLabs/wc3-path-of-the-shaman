/**
    ShamanBoneArmor

    Author: Valdemar
    Version:

    Description:
    Lightweight reusable Bone Armor style shield core for Restoration shaman
    shields. A tracked shield absorbs incoming damage before life damage;
    Ancestral Ward uses orbiting Bone Armor segments, while Water Shield mode
    restores mana equal to absorbed shield life.

    Credits:
    - Spellweaver/The_Spellweaver BAmr concept used by the old GUI triggers
    - Old GUI Ancestral Ward and Water Shield BAmr trigger copies

    How to install:
    Requires `Table`, `DamageEngine`, and `ShamanCommon`.

    API:
    - call ShamanBoneArmor_ApplyShield(source, target, buffId, amount, mode, requireBuff, duration)
    - call ShamanBoneArmor_RemoveShield(target, showBreakEffect)
    - set amount = ShamanBoneArmor_GetRemaining(target)

**/
library ShamanBoneArmor initializer Init requires Table, DamageEngine, ShamanCommon

globals
    public constant integer MODE_ANCESTRAL_WARD = 1
    public constant integer MODE_WATER_SHIELD = 2

    private constant integer MAX_TRACKED_SHIELDS = 512
    private constant real PERIOD = 0.05
    private constant real BUFF_REQUIRE_GRACE = 0.35
    private constant real FLARE_OFFSET = 85.00
    private constant real FLARE_SCALE = 0.90
    private constant real FLARE_HEIGHT = 65.00
    private constant real FLARE_TIME_SCALE = 7.50
    private constant integer FLARE_ALPHA = 255
    private constant integer ANCESTRAL_SEGMENT_COUNT = 3
    private constant real ANCESTRAL_SEGMENT_ORBIT_OFFSET = 60.00
    private constant real ANCESTRAL_SEGMENT_SPAWN_OFFSET = 120.00
    private constant real ANCESTRAL_SEGMENT_HEIGHT = 65.00
    private constant real ANCESTRAL_SEGMENT_ORBIT_SPEED = 1.70
    private constant real ANCESTRAL_SEGMENT_SCALE = 1.00

    private constant string EFFECT_ANCESTRAL_APPLY = "Abilities\\Spells\\Orc\\AncestralSpirit\\AncestralSpiritCaster.mdl"
    private constant string EFFECT_ANCESTRAL_BREAK = "Abilities\\Spells\\Other\\HealingSpray\\HealBottleMissile.mdl"
    private constant string EFFECT_ANCESTRAL_SEGMENT = "Abilities\\Weapons\\FaerieDragonMissile\\FaerieDragonMissile.mdl"
    private constant string EFFECT_WATER_APPLY = "Abilities\\Spells\\Other\\CrushingWave\\CrushingWaveDamage.mdl"
    private constant string EFFECT_WATER_BREAK = "Abilities\\Spells\\Other\\CrushingWave\\CrushingWaveDamage.mdl"
    private constant string EFFECT_WATER_PERSIST = "Abilities\\Spells\\Human\\ManaShield\\ManaShieldCaster.mdl"
    private constant string EFFECT_HIT_FLARE = "BoneArmorCasterTC.mdx"
    private constant string EFFECT_MANA = "Abilities\\Spells\\Items\\AIma\\AImaTarget.mdl"

    private Table ShieldHealthByHandle = 0
    private Table ShieldMaxByHandle = 0
    private Table ShieldModeByHandle = 0
    private Table ShieldBuffByHandle = 0
    private Table ShieldDurationByHandle = 0
    private Table ShieldRequireBuffByHandle = 0
    private Table ShieldBuffGraceByHandle = 0
    private Table ShieldTrackedByHandle = 0
    private Table ShieldIndexByHandle = 0
    private Table ShieldEffectByHandle = 0
    private Table ShieldOrbitByHandle = 0
    private Table ShieldSegmentEffectByKey = 0
    private unit array ActiveShieldUnits
    private integer ActiveShieldCount = 0
    private timer PeriodicTimer = null
    private location TerrainLocation = null
endglobals

private function EnsureState takes nothing returns nothing
    if ShieldHealthByHandle == 0 then
        set ShieldHealthByHandle = Table.create()
        set ShieldMaxByHandle = Table.create()
        set ShieldModeByHandle = Table.create()
        set ShieldBuffByHandle = Table.create()
        set ShieldDurationByHandle = Table.create()
        set ShieldRequireBuffByHandle = Table.create()
        set ShieldBuffGraceByHandle = Table.create()
        set ShieldTrackedByHandle = Table.create()
        set ShieldIndexByHandle = Table.create()
        set ShieldEffectByHandle = Table.create()
        set ShieldOrbitByHandle = Table.create()
        set ShieldSegmentEffectByKey = Table.create()
    endif
    if TerrainLocation == null then
        set TerrainLocation = Location(0.00, 0.00)
    endif
endfunction

private function GetApplyEffectPath takes integer mode returns string
    if mode == MODE_WATER_SHIELD then
        return EFFECT_WATER_APPLY
    endif
    return EFFECT_ANCESTRAL_APPLY
endfunction

private function GetBreakEffectPath takes integer mode returns string
    if mode == MODE_WATER_SHIELD then
        return EFFECT_WATER_BREAK
    endif
    return EFFECT_ANCESTRAL_BREAK
endfunction

private function GetPersistEffectPath takes integer mode returns string
    if mode == MODE_WATER_SHIELD then
        return EFFECT_WATER_PERSIST
    endif
    return ""
endfunction

private function AddActive takes unit target returns nothing
    local integer handleId = GetHandleId(target)
    if ShieldTrackedByHandle.boolean[handleId] or ActiveShieldCount >= MAX_TRACKED_SHIELDS then
        return
    endif
    set ActiveShieldCount = ActiveShieldCount + 1
    set ActiveShieldUnits[ActiveShieldCount] = target
    set ShieldTrackedByHandle.boolean[handleId] = true
    set ShieldIndexByHandle.integer[handleId] = ActiveShieldCount
endfunction

private function RemoveActive takes unit target returns nothing
    local integer handleId = GetHandleId(target)
    local integer index = ShieldIndexByHandle.integer[handleId]
    local unit moved
    if index <= 0 then
        return
    endif
    set moved = ActiveShieldUnits[ActiveShieldCount]
    set ActiveShieldUnits[index] = moved
    set ActiveShieldUnits[ActiveShieldCount] = null
    set ActiveShieldCount = ActiveShieldCount - 1
    if moved != null and moved != target then
        set ShieldIndexByHandle.integer[GetHandleId(moved)] = index
    endif
    call ShieldTrackedByHandle.boolean.remove(handleId)
    call ShieldIndexByHandle.integer.remove(handleId)
    set moved = null
endfunction

private function PlayTargetEffect takes string effectPath, unit target, string attachPoint returns nothing
    if effectPath != "" and target != null then
        call DestroyEffect(AddSpecialEffectTarget(effectPath, target, attachPoint))
    endif
endfunction

private function GetTerrainZAt takes real x, real y returns real
    call EnsureState()
    call MoveLocation(TerrainLocation, x, y)
    return GetLocationZ(TerrainLocation)
endfunction

private function GetEffectZForUnit takes unit target, real x, real y, real height returns real
    if target == null then
        return GetTerrainZAt(x, y) + height
    endif
    return GetTerrainZAt(x, y) + GetUnitFlyHeight(target) + height
endfunction

private function GetSegmentKey takes integer handleId, integer segmentIndex returns integer
    return handleId * 8 + segmentIndex
endfunction

private function CreateAncestralSegments takes unit source, unit target, integer handleId returns nothing
    local integer index = 1
    local real baseX = GetUnitX(target)
    local real baseY = GetUnitY(target)
    local real angle
    local real x
    local real y
    local effect sfx

    if source != null then
        set baseX = GetUnitX(source)
        set baseY = GetUnitY(source)
    endif

    loop
        exitwhen index > ANCESTRAL_SEGMENT_COUNT
        set angle = (360.00 / I2R(ANCESTRAL_SEGMENT_COUNT)) * I2R(index - 1)
        set x = ShamanCommon_PolarX(baseX, ANCESTRAL_SEGMENT_SPAWN_OFFSET, angle)
        set y = ShamanCommon_PolarY(baseY, ANCESTRAL_SEGMENT_SPAWN_OFFSET, angle)
        set sfx = AddSpecialEffect(EFFECT_ANCESTRAL_SEGMENT, x, y)
        if sfx != null then
            call BlzSetSpecialEffectScale(sfx, ANCESTRAL_SEGMENT_SCALE)
            call BlzSetSpecialEffectPosition(sfx, x, y, GetEffectZForUnit(target, x, y, ANCESTRAL_SEGMENT_HEIGHT))
            call BlzSetSpecialEffectYaw(sfx, (angle + 90.00) * bj_DEGTORAD)
            set ShieldSegmentEffectByKey.effect[GetSegmentKey(handleId, index)] = sfx
        endif
        set index = index + 1
    endloop

    set ShieldOrbitByHandle.real[handleId] = 0.00
    set sfx = null
endfunction

private function UpdateAncestralSegments takes unit target, integer handleId returns nothing
    local integer index = 1
    local real orbit = ShieldOrbitByHandle.real[handleId] + ANCESTRAL_SEGMENT_ORBIT_SPEED
    local real angle
    local real x
    local real y
    local effect sfx

    if orbit >= 360.00 then
        set orbit = orbit - 360.00
    endif
    set ShieldOrbitByHandle.real[handleId] = orbit

    loop
        exitwhen index > ANCESTRAL_SEGMENT_COUNT
        set sfx = ShieldSegmentEffectByKey.effect[GetSegmentKey(handleId, index)]
        if sfx != null then
            set angle = orbit + (360.00 / I2R(ANCESTRAL_SEGMENT_COUNT)) * I2R(index - 1)
            set x = ShamanCommon_PolarX(GetUnitX(target), ANCESTRAL_SEGMENT_ORBIT_OFFSET, angle)
            set y = ShamanCommon_PolarY(GetUnitY(target), ANCESTRAL_SEGMENT_ORBIT_OFFSET, angle)
            call BlzSetSpecialEffectPosition(sfx, x, y, GetEffectZForUnit(target, x, y, ANCESTRAL_SEGMENT_HEIGHT))
            call BlzSetSpecialEffectYaw(sfx, (angle + 90.00) * bj_DEGTORAD)
        endif
        set index = index + 1
    endloop

    set sfx = null
endfunction

private function DestroyAncestralSegments takes integer handleId returns nothing
    local integer index = 1
    local integer key
    local effect sfx

    loop
        exitwhen index > ANCESTRAL_SEGMENT_COUNT
        set key = GetSegmentKey(handleId, index)
        set sfx = ShieldSegmentEffectByKey.effect[key]
        if sfx != null then
            call DestroyEffect(sfx)
            call ShieldSegmentEffectByKey.effect.remove(key)
        endif
        set index = index + 1
    endloop

    call ShieldOrbitByHandle.real.remove(handleId)
    set sfx = null
endfunction

private function PlayHitFlare takes unit source, unit target returns nothing
    local real angle = GetUnitFacing(target)
    local real x
    local real y
    local effect sfx
    if source != null then
        set angle = ShamanCommon_AngleBetweenCoordinates(GetUnitX(target), GetUnitY(target), GetUnitX(source), GetUnitY(source))
    endif
    set x = ShamanCommon_PolarX(GetUnitX(target), FLARE_OFFSET, angle)
    set y = ShamanCommon_PolarY(GetUnitY(target), FLARE_OFFSET, angle)
    set sfx = AddSpecialEffect(EFFECT_HIT_FLARE, x, y)
    if sfx != null then
        call BlzSetSpecialEffectScale(sfx, FLARE_SCALE)
        call BlzSetSpecialEffectTimeScale(sfx, FLARE_TIME_SCALE)
        call BlzSetSpecialEffectAlpha(sfx, FLARE_ALPHA)
        call BlzSetSpecialEffectPosition(sfx, x, y, GetEffectZForUnit(target, x, y, FLARE_HEIGHT))
        call BlzSetSpecialEffectYaw(sfx, angle * bj_DEGTORAD)
        call DestroyEffect(sfx)
    endif
    set sfx = null
endfunction

private function CleanupShield takes unit target, boolean showBreakEffect returns nothing
    local integer handleId
    local integer mode
    local integer buffId
    local effect persistEffect

    if target == null then
        return
    endif

    set handleId = GetHandleId(target)
    if not ShieldTrackedByHandle.boolean[handleId] then
        return
    endif

    set mode = ShieldModeByHandle.integer[handleId]
    set buffId = ShieldBuffByHandle.integer[handleId]
    set persistEffect = ShieldEffectByHandle.effect[handleId]

    if persistEffect != null then
        call DestroyEffect(persistEffect)
    endif
    if mode == MODE_ANCESTRAL_WARD then
        call DestroyAncestralSegments(handleId)
    endif
    if showBreakEffect and target != null then
        call PlayTargetEffect(GetBreakEffectPath(mode), target, "origin")
    endif
    if buffId != 0 and target != null and GetUnitAbilityLevel(target, buffId) > 0 then
        call UnitRemoveAbility(target, buffId)
    endif

    call ShieldHealthByHandle.real.remove(handleId)
    call ShieldMaxByHandle.real.remove(handleId)
    call ShieldModeByHandle.integer.remove(handleId)
    call ShieldBuffByHandle.integer.remove(handleId)
    call ShieldDurationByHandle.real.remove(handleId)
    call ShieldRequireBuffByHandle.boolean.remove(handleId)
    call ShieldBuffGraceByHandle.real.remove(handleId)
    call ShieldEffectByHandle.effect.remove(handleId)
    call RemoveActive(target)

    set persistEffect = null
endfunction

private function ShieldRequiresMissingBuff takes unit target, integer handleId returns boolean
    local integer buffId = ShieldBuffByHandle.integer[handleId]
    return ShieldRequireBuffByHandle.boolean[handleId] and buffId != 0 and GetUnitAbilityLevel(target, buffId) <= 0 and ShieldBuffGraceByHandle.real[handleId] <= 0.00
endfunction

private function TickShields takes nothing returns nothing
    local integer index = 1
    local unit target
    local integer handleId
    local integer mode
    local real duration
    local real buffGrace
    loop
        exitwhen index > ActiveShieldCount
        set target = ActiveShieldUnits[index]
        set handleId = GetHandleId(target)
        if not ShamanCommon_IsAlive(target) then
            call CleanupShield(target, false)
        else
            set buffGrace = ShieldBuffGraceByHandle.real[handleId]
            if buffGrace > 0.00 then
                set buffGrace = buffGrace - PERIOD
                if buffGrace < 0.00 then
                    set buffGrace = 0.00
                endif
                set ShieldBuffGraceByHandle.real[handleId] = buffGrace
            endif
            if ShieldRequiresMissingBuff(target, handleId) then
                call CleanupShield(target, false)
            else
                set mode = ShieldModeByHandle.integer[handleId]
                if mode == MODE_ANCESTRAL_WARD then
                    call UpdateAncestralSegments(target, handleId)
                endif
                set duration = ShieldDurationByHandle.real[handleId]
                if duration > 0.00 then
                    set duration = duration - PERIOD
                    if duration <= 0.00 then
                        call CleanupShield(target, true)
                    else
                        set ShieldDurationByHandle.real[handleId] = duration
                        set index = index + 1
                    endif
                else
                    set index = index + 1
                endif
            endif
        endif
    endloop
    set target = null
endfunction

private function HandleDamageModifier takes nothing returns nothing
    local unit source = udg_DamageEventSource
    local unit target = udg_DamageEventTarget
    local integer handleId = GetHandleId(target)
    local integer mode
    local real incoming = udg_DamageEventAmount
    local real remaining
    local real absorbed

    if target == null or incoming <= 0.00 or not ShieldTrackedByHandle.boolean[handleId] then
        set source = null
        set target = null
        return
    endif

    if ShieldRequiresMissingBuff(target, handleId) then
        call CleanupShield(target, false)
        set source = null
        set target = null
        return
    endif

    set remaining = ShieldHealthByHandle.real[handleId]
    set mode = ShieldModeByHandle.integer[handleId]
    if remaining <= 0.00 then
        call CleanupShield(target, true)
        set source = null
        set target = null
        return
    endif

    if incoming < remaining then
        set absorbed = incoming
        set remaining = remaining - incoming
        set udg_DamageEventAmount = 0.00
        set ShieldHealthByHandle.real[handleId] = remaining
    else
        set absorbed = remaining
        set udg_DamageEventAmount = incoming - remaining
        set remaining = 0.00
        set ShieldHealthByHandle.real[handleId] = 0.00
        call CleanupShield(target, true)
    endif

    if absorbed > 0.00 then
        call PlayHitFlare(source, target)
        if mode == MODE_WATER_SHIELD then
            call ShamanCommon_AddMana(target, absorbed)
            call PlayTargetEffect(EFFECT_MANA, target, "origin")
        endif
    endif

    set source = null
    set target = null
endfunction

public function ApplyShield takes unit source, unit target, integer buffId, real amount, integer mode, boolean requireBuff, real duration returns nothing
    local integer handleId
    local effect persistEffect = null

    if target == null or amount <= 0.00 then
        return
    endif

    call EnsureState()
    set handleId = GetHandleId(target)
    if ShieldTrackedByHandle.boolean[handleId] then
        call CleanupShield(target, false)
    endif

    set ShieldHealthByHandle.real[handleId] = amount
    set ShieldMaxByHandle.real[handleId] = amount
    set ShieldModeByHandle.integer[handleId] = mode
    set ShieldBuffByHandle.integer[handleId] = buffId
    set ShieldDurationByHandle.real[handleId] = duration
    set ShieldRequireBuffByHandle.boolean[handleId] = requireBuff
    set ShieldBuffGraceByHandle.real[handleId] = BUFF_REQUIRE_GRACE
    if mode == MODE_ANCESTRAL_WARD then
        call CreateAncestralSegments(source, target, handleId)
    else
        set persistEffect = AddSpecialEffectTarget(GetPersistEffectPath(mode), target, "origin")
    endif
    set ShieldEffectByHandle.effect[handleId] = persistEffect
    call AddActive(target)
    call PlayTargetEffect(GetApplyEffectPath(mode), target, "origin")

    set persistEffect = null
    set source = null
endfunction

public function RemoveShield takes unit target, boolean showBreakEffect returns nothing
    call CleanupShield(target, showBreakEffect)
endfunction

public function GetRemaining takes unit target returns real
    if target == null then
        return 0.00
    endif
    return ShieldHealthByHandle.real[GetHandleId(target)]
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    set PeriodicTimer = CreateTimer()
    call TimerStart(PeriodicTimer, PERIOD, true, function TickShields)
    call RegisterDamageEngine(function HandleDamageModifier, "", 4.00)
endfunction

endlibrary
