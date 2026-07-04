/**
    AI_GenericCaster

    Author: Valdemar
    Version:

    Description:
    Configurable generic caster AI profile factory. Each profile can define one
    primary target spell by raw ability id and order string.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j` and `Table`.

    API:
    call AI_GenericCaster_RegisterProfile(unitTypeId, profileName, abilityId, order, cooldown, range, autonomous)
    call AI_GenericCaster_Configure(profileId, abilityId, order, cooldown, range)
    call AI_GenericCaster_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIGenericCaster initializer Init requires AI, Table

globals
    integer AI_GenericCaster_ClassId = 0
    private Table ProfileAbility = 0
    private Table ProfileOrder = 0
    private Table ProfileCooldown = 0
    private Table ProfileRange = 0
endglobals

private function EnsureState takes nothing returns nothing
    if ProfileAbility == 0 then
        set ProfileAbility = Table.create()
        set ProfileOrder = Table.create()
        set ProfileCooldown = Table.create()
        set ProfileRange = Table.create()
    endif
endfunction

private function IsTargetInRange takes unit caster, unit target, real range returns boolean
    local real dx
    local real dy
    if caster == null or target == null then
        return false
    endif
    if range <= 0.00 then
        return true
    endif
    set dx = GetUnitX(caster) - GetUnitX(target)
    set dy = GetUnitY(caster) - GetUnitY(target)
    return dx * dx + dy * dy <= range * range
endfunction

private function Think takes nothing returns nothing
    local unit caster = AI_EventUnit
    local unit target = AI_EventTarget
    local integer profileId = AI_EventProfileId
    local integer abilityId
    local string order
    local real cooldown
    local real range
    call EnsureState()
    if caster == null or target == null or profileId <= 0 then
        set caster = null
        set target = null
        return
    endif
    set abilityId = ProfileAbility[profileId]
    set order = ProfileOrder.string[profileId]
    set cooldown = ProfileCooldown.real[profileId]
    set range = ProfileRange.real[profileId]
    if order != "" and IsTargetInRange(caster, target, range) and AI_TryCastTarget(caster, target, abilityId, order, cooldown) then
        call AI_RequestBark(caster, AI_BARK_CASTING)
    else
        call IssueTargetOrder(caster, "attack", target)
    endif
    set caster = null
    set target = null
endfunction

public function Configure takes integer profileId, integer abilityId, string order, real cooldown, real range returns nothing
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set ProfileAbility[profileId] = abilityId
    set ProfileOrder.string[profileId] = order
    set ProfileCooldown.real[profileId] = cooldown
    set ProfileRange.real[profileId] = range
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName, integer abilityId, string order, real cooldown, real range, boolean autonomous returns integer
    local integer profileId
    call EnsureState()
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_GenericCaster_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, autonomous)
    call AI_SetProfileThinkCallback(profileId, function Think)
    call AI_GenericCaster_Configure(profileId, abilityId, order, cooldown, range)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    set AI_GenericCaster_ClassId = AI_RegisterClass("Generic Caster")
endfunction

endlibrary
