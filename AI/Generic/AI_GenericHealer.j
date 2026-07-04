/**
    AI_GenericHealer

    Author: Valdemar
    Version:

    Description:
    Configurable generic healer/support AI profile factory. Each profile can
    define one ally heal/support spell by raw ability id and order string.

    Credits:
    - PotS AI JASS migration

    How to install:
    Requires `AI.j` and `Table`.

    API:
    call AI_GenericHealer_RegisterProfile(unitTypeId, profileName, abilityId, order, cooldown, range, threshold, autonomous)
    call AI_GenericHealer_Configure(profileId, abilityId, order, cooldown, range, threshold)
    call AI_GenericHealer_RegisterUnit(whichUnit, profileId, uniqueId)

**/
library AIGenericHealer initializer Init requires AI, Table

globals
    integer AI_GenericHealer_ClassId = 0
    private Table ProfileAbility = 0
    private Table ProfileOrder = 0
    private Table ProfileCooldown = 0
    private Table ProfileRange = 0
    private Table ProfileThreshold = 0
endglobals

private function EnsureState takes nothing returns nothing
    if ProfileAbility == 0 then
        set ProfileAbility = Table.create()
        set ProfileOrder = Table.create()
        set ProfileCooldown = Table.create()
        set ProfileRange = Table.create()
        set ProfileThreshold = Table.create()
    endif
endfunction

private function Think takes nothing returns nothing
    local unit healer = AI_EventUnit
    local unit target = AI_EventTarget
    local unit ally = null
    local integer profileId = AI_EventProfileId
    local integer abilityId
    local string order
    local real cooldown
    local real range
    local real threshold
    call EnsureState()
    if healer == null or profileId <= 0 then
        set healer = null
        set target = null
        set ally = null
        return
    endif
    set abilityId = ProfileAbility[profileId]
    set order = ProfileOrder.string[profileId]
    set cooldown = ProfileCooldown.real[profileId]
    set range = ProfileRange.real[profileId]
    set threshold = ProfileThreshold.real[profileId]
    if range <= 0.00 then
        set range = 700.00
    endif
    if threshold <= 0.00 then
        set threshold = 65.00
    endif
    set ally = AI_FindLowestHealthAlly(healer, range, true)
    if ally != null and order != "" and AI_GetUnitLifePercent(ally) <= threshold and AI_TryCastTarget(healer, ally, abilityId, order, cooldown) then
        call AI_RequestBark(healer, AI_BARK_CASTING)
    elseif target != null then
        call IssueTargetOrder(healer, "attack", target)
    endif
    set healer = null
    set target = null
    set ally = null
endfunction

public function Configure takes integer profileId, integer abilityId, string order, real cooldown, real range, real threshold returns nothing
    call EnsureState()
    if profileId <= 0 then
        return
    endif
    set ProfileAbility[profileId] = abilityId
    set ProfileOrder.string[profileId] = order
    set ProfileCooldown.real[profileId] = cooldown
    set ProfileRange.real[profileId] = range
    set ProfileThreshold.real[profileId] = threshold
endfunction

public function RegisterProfile takes integer unitTypeId, string profileName, integer abilityId, string order, real cooldown, real range, real threshold, boolean autonomous returns integer
    local integer profileId
    call EnsureState()
    if unitTypeId == 0 or profileName == "" then
        return 0
    endif
    set profileId = AI_RegisterProfile(AI_GenericHealer_ClassId, unitTypeId, profileName)
    call AI_SetProfileAutonomous(profileId, autonomous)
    call AI_SetProfileThinkCallback(profileId, function Think)
    call AIGenericHealer_Configure(profileId, abilityId, order, cooldown, range, threshold)
    return profileId
endfunction

public function RegisterUnit takes unit whichUnit, integer profileId, integer uniqueId returns integer
    return AI_RegisterUnit(whichUnit, profileId, uniqueId)
endfunction

private function Init takes nothing returns nothing
    call EnsureState()
    set AI_GenericHealer_ClassId = AI_RegisterClass("Generic Healer")
endfunction

endlibrary
