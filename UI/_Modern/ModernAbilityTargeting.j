/**
    ModernAbilityTargeting

    Author: Valdemar
    Version: 0.2.0

    Description:
    Resolves deterministic soft unit targets for the modern action bar. A
    clicked world point may select a nearby hostile or friendly unit, while
    melee-auto actions acquire around the caster. Precise-point policies are
    intentionally not snapped and must preserve the original mouse position.

    Credits:
    - Blizzard Entertainment, Warcraft III group and unit APIs

    How to install:
    Import after ShamanCommon and ModernAbilityCatalog. Use the resolver only
    from synchronized order-dispatch code; local mouse coordinates must first
    be transferred through a validated sync event.

    API:
    - set target = ModernAbilityTargeting_ResolveUnit(caster, abilityId, x, y)
    - set target = ModernAbilityTargeting_ResolveUnitWithHint(caster, abilityId, x, y, hintedUnit)
    - set target = ModernAbilityTargeting_ResolveMeleeUnit(caster, abilityId)
    - set precise = ModernAbilityTargeting_UsesPrecisePoint(abilityId)

**/
library ModernAbilityTargeting requires ShamanCommon, ModernAbilityCatalog

globals
    private constant real MAT_SELF_CLICK_RADIUS = 96.00
    private constant real MAT_DISTANCE_EPSILON = 0.01

    private group MAT_SearchGroup = CreateGroup()
endglobals

private function MAT_DistanceSquared takes real ax, real ay, real bx, real by returns real
    local real dx = ax - bx
    local real dy = ay - by

    return dx * dx + dy * dy
endfunction

private function MAT_IsGeneralCandidate takes unit candidate returns boolean
    return candidate != null and ShamanCommon_IsAlive(candidate) and not IsUnitHidden(candidate) and not IsUnitType(candidate, UNIT_TYPE_STRUCTURE) and GetUnitAbilityLevel(candidate, 'Aloc') == 0
endfunction

private function MAT_IsPolicyCandidate takes unit caster, unit candidate, integer targetPolicy returns boolean
    local player owner
    local boolean valid = false

    if caster == null or not MAT_IsGeneralCandidate(candidate) then
        return false
    endif

    set owner = GetOwningPlayer(caster)
    if targetPolicy == ModernAbilityCatalog_TARGET_SOFT_FRIENDLY then
        set valid = IsUnitAlly(candidate, owner)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SOFT_HOSTILE or targetPolicy == ModernAbilityCatalog_TARGET_MELEE_AUTO then
        set valid = IsUnitEnemy(candidate, owner)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SELF then
        set valid = candidate == caster
    endif
    set owner = null
    return valid
endfunction

private function MAT_IsBetterCandidate takes unit candidate, unit current, real pointX, real pointY, boolean preferWounded returns boolean
    local real candidateDistance
    local real currentDistance
    local real candidateLife = 1.00
    local real currentLife = 1.00
    local integer candidateIndex
    local integer currentIndex

    if current == null then
        return true
    endif

    set candidateDistance = MAT_DistanceSquared(GetUnitX(candidate), GetUnitY(candidate), pointX, pointY)
    set currentDistance = MAT_DistanceSquared(GetUnitX(current), GetUnitY(current), pointX, pointY)
    if candidateDistance + MAT_DISTANCE_EPSILON < currentDistance then
        return true
    elseif currentDistance + MAT_DISTANCE_EPSILON < candidateDistance then
        return false
    endif

    if preferWounded then
        if BlzGetUnitMaxHP(candidate) > 0 then
            set candidateLife = GetWidgetLife(candidate) / I2R(BlzGetUnitMaxHP(candidate))
        endif
        if BlzGetUnitMaxHP(current) > 0 then
            set currentLife = GetWidgetLife(current) / I2R(BlzGetUnitMaxHP(current))
        endif
        if candidateLife + MAT_DISTANCE_EPSILON < currentLife then
            return true
        elseif currentLife + MAT_DISTANCE_EPSILON < candidateLife then
            return false
        endif
    endif

    set candidateIndex = GetUnitUserData(candidate)
    set currentIndex = GetUnitUserData(current)
    return candidateIndex > 0 and (currentIndex <= 0 or candidateIndex < currentIndex)
endfunction

private function MAT_FindUnit takes unit caster, real pointX, real pointY, real radius, boolean friendly returns unit
    local player owner
    local unit candidate
    local unit best = null

    if caster == null or radius <= 0.00 then
        return null
    endif

    set owner = GetOwningPlayer(caster)
    call GroupEnumUnitsInRange(MAT_SearchGroup, pointX, pointY, radius, null)
    loop
        set candidate = FirstOfGroup(MAT_SearchGroup)
        exitwhen candidate == null
        call GroupRemoveUnit(MAT_SearchGroup, candidate)

        if MAT_IsGeneralCandidate(candidate) then
            if friendly and IsUnitAlly(candidate, owner) and MAT_IsBetterCandidate(candidate, best, pointX, pointY, true) then
                set best = candidate
            elseif not friendly and IsUnitEnemy(candidate, owner) and MAT_IsBetterCandidate(candidate, best, pointX, pointY, false) then
                set best = candidate
            endif
        endif
    endloop

    set owner = null
    set candidate = null
    return best
endfunction

public function ResolveUnit takes unit caster, integer abilityId, real pointX, real pointY returns unit
    local integer targetPolicy = ModernAbilityCatalog_GetTargetPolicy(abilityId)
    local real radius = ModernAbilityCatalog_GetAcquireRadius(abilityId)
    local unit result = null

    if caster == null then
        return null
    endif

    if targetPolicy == ModernAbilityCatalog_TARGET_SOFT_FRIENDLY then
        if ModernAbilityCatalog_AllowsSelfFallback(abilityId) and MAT_DistanceSquared(GetUnitX(caster), GetUnitY(caster), pointX, pointY) <= MAT_SELF_CLICK_RADIUS * MAT_SELF_CLICK_RADIUS then
            return caster
        endif
        set result = MAT_FindUnit(caster, pointX, pointY, radius, true)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SOFT_HOSTILE then
        set result = MAT_FindUnit(caster, pointX, pointY, radius, false)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_MELEE_AUTO then
        set result = MAT_FindUnit(caster, GetUnitX(caster), GetUnitY(caster), radius, false)
    elseif targetPolicy == ModernAbilityCatalog_TARGET_SELF then
        set result = caster
    endif

    return result
endfunction

public function ResolveUnitWithHint takes unit caster, integer abilityId, real pointX, real pointY, unit hintedUnit returns unit
    local integer targetPolicy = ModernAbilityCatalog_GetTargetPolicy(abilityId)
    local unit result = null

    if MAT_IsPolicyCandidate(caster, hintedUnit, targetPolicy) then
        set result = hintedUnit
    else
        set result = ResolveUnit(caster, abilityId, pointX, pointY)
    endif

    set hintedUnit = null
    return result
endfunction

public function ResolveMeleeUnit takes unit caster, integer abilityId returns unit
    if caster == null then
        return null
    endif
    return ResolveUnit(caster, abilityId, GetUnitX(caster), GetUnitY(caster))
endfunction

public function UsesPrecisePoint takes integer abilityId returns boolean
    return ModernAbilityCatalog_GetTargetPolicy(abilityId) == ModernAbilityCatalog_TARGET_PRECISE_POINT
endfunction

endlibrary
