/**
    StormhavenCity

    Author: Valdemar
    Version:

    Description:
    Ambient AIRoutines setup for Stormhaven citizens. AIRoutines creates and
    manages thirty Player(8) city units in zone 13, using a weighted random
    unit-type pool and several non-harvest city routines for street walking,
    market idling, and social movement.

    Credits:
    - PotS AI JASS migration

    How to install:
    Import after `AIRoutines.j` and `Reputation.j`. The map must provide
    `gg_rct_013Stormhaven`.

    API:
    call StormhavenCity_Refresh()

**/
library StormhavenCity initializer Init requires AIRoutines, Reputation

globals
    // Configuration
    private constant integer SHC_OWNER_PLAYER_ID = 8
    private constant integer SHC_ROUTINE_ZONE_ID = 13
    private constant integer SHC_STREET_COUNT = 12
    private constant integer SHC_MARKET_COUNT = 10
    private constant integer SHC_SOCIAL_COUNT = 8
    private constant real SHC_RESPAWN_DELAY = 45.00
    private constant real SHC_RANDOM_FACING = -1.00
    private constant real SHC_TURNOVER_MIN = 240.00
    private constant real SHC_TURNOVER_MAX = 620.00
    private constant real SHC_TURNOVER_REMOVE_DELAY = 12.00
    private constant string SHC_FACTION_NAME = "Stormhaven"

    private integer SHC_StreetRoutineId = 0
    private integer SHC_MarketRoutineId = 0
    private integer SHC_SocialRoutineId = 0
    private integer SHC_StreetGroupId = 0
    private integer SHC_MarketGroupId = 0
    private integer SHC_SocialGroupId = 0
endglobals

private function RandomCityPointOrder takes unit whichUnit, string order returns nothing
    local real x
    local real y
    if whichUnit == null then
        return
    endif

    set x = GetRandomReal(GetRectMinX(gg_rct_013Stormhaven), GetRectMaxX(gg_rct_013Stormhaven))
    set y = GetRandomReal(GetRectMinY(gg_rct_013Stormhaven), GetRectMaxY(gg_rct_013Stormhaven))
    call IssuePointOrder(whichUnit, order, x, y)
endfunction

private function PlayCityIdle takes unit whichUnit, integer action returns nothing
    if whichUnit == null then
        return
    endif

    call IssueImmediateOrder(whichUnit, "stop")
    if action == 1 then
        call SetUnitAnimation(whichUnit, "stand")
    elseif action == 2 then
        call SetUnitAnimation(whichUnit, "stand work")
    elseif action == 3 then
        call SetUnitAnimation(whichUnit, "stand ready")
    elseif action == 4 then
        call SetUnitAnimation(whichUnit, "spell")
    elseif action == 5 then
        call SetUnitAnimation(whichUnit, "stand victory")
    else
        call SetUnitAnimation(whichUnit, "attack")
    endif
endfunction

private function StreetAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    set action = GetRandomInt(1, 7)
    if action <= 4 then
        call PlayCityIdle(whichUnit, action)
    elseif action == 5 then
        call RandomCityPointOrder(whichUnit, "move")
    elseif action == 6 then
        call IssueImmediateOrder(whichUnit, "holdposition")
        call SetUnitAnimation(whichUnit, "stand")
    else
        call PlayCityIdle(whichUnit, 6)
    endif

    set whichUnit = null
endfunction

private function MarketAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    set action = GetRandomInt(1, 6)
    if action <= 3 then
        call PlayCityIdle(whichUnit, 2)
    elseif action == 4 then
        call PlayCityIdle(whichUnit, 4)
    elseif action == 5 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, 1)
    endif

    set whichUnit = null
endfunction

private function SocialAction takes nothing returns nothing
    local unit whichUnit = AIRoutines_EventUnit
    local integer action
    if whichUnit == null then
        return
    endif

    set action = GetRandomInt(1, 6)
    if action == 1 then
        call PlayCityIdle(whichUnit, 5)
    elseif action == 2 then
        call PlayCityIdle(whichUnit, 3)
    elseif action == 3 then
        call PlayCityIdle(whichUnit, 4)
    elseif action == 4 then
        call RandomCityPointOrder(whichUnit, "move")
    else
        call PlayCityIdle(whichUnit, 1)
    endif

    set whichUnit = null
endfunction

private function CreateStreetRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Streets")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 7.00, 15.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 9.00, function StreetAction)
    call AIRoutines_AddWaitStep(routineId, 2.00, 5.00)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 8.00, 18.00)
    call AIRoutines_AddStandStep(routineId, "stand", 3.00, 8.00)
    return routineId
endfunction

private function CreateMarketRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Market Citizens")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 5.00, 12.00)
    call AIRoutines_AddCallbackStep(routineId, 8.00, 18.00, function MarketAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 7.00)
    call AIRoutines_AddCallbackStep(routineId, 5.00, 12.00, function StreetAction)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 6.00, 14.00)
    return routineId
endfunction

private function CreateSocialRoutine takes nothing returns integer
    local integer routineId = AIRoutines_CreateRoutine("Stormhaven Social Citizens")
    if routineId <= 0 then
        return 0
    endif

    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 6.00, 14.00)
    call AIRoutines_AddCallbackStep(routineId, 6.00, 16.00, function SocialAction)
    call AIRoutines_AddWaitStep(routineId, 3.00, 8.00)
    call AIRoutines_AddCallbackStep(routineId, 4.00, 10.00, function MarketAction)
    call AIRoutines_AddWanderStep(routineId, gg_rct_013Stormhaven, 5.00, 12.00)
    return routineId
endfunction

private function AddCitizenType takes integer unitTypeId, integer weight returns nothing
    if SHC_StreetGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_StreetGroupId, unitTypeId, weight)
    endif
    if SHC_MarketGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_MarketGroupId, unitTypeId, weight)
    endif
    if SHC_SocialGroupId > 0 then
        call AIRoutines_AddManagedUnitGroupType(SHC_SocialGroupId, unitTypeId, weight)
    endif
    call Reputation_RegisterUnitTypeFaction(unitTypeId, SHC_FACTION_NAME)
endfunction

private function RegisterCitizenTypes takes nothing returns nothing
    call AddCitizenType('n65M', 4)
    call AddCitizenType('n65N', 4)
    call AddCitizenType('n65O', 4)
    call AddCitizenType('n65P', 4)
    call AddCitizenType('n65Q', 4)
    call AddCitizenType('N65R', 3)
    call AddCitizenType('nvlw', 4)
    call AddCitizenType('nvlk', 2)
    call AddCitizenType('nvk2', 2)
endfunction

private function CreateCitizenGroup takes integer routineId, integer count returns integer
    local integer spawnGroupId
    if routineId <= 0 then
        return 0
    endif

    set spawnGroupId = AIRoutines_CreateManagedRandomUnitGroupInZone(Player(SHC_OWNER_PLAYER_ID), gg_rct_013Stormhaven, routineId, count, SHC_RESPAWN_DELAY, SHC_RANDOM_FACING, SHC_ROUTINE_ZONE_ID)
    if spawnGroupId > 0 then
        call AIRoutines_SetManagedUnitGroupTurnover(spawnGroupId, SHC_TURNOVER_MIN, SHC_TURNOVER_MAX, gg_rct_013Stormhaven, SHC_TURNOVER_REMOVE_DELAY)
    endif
    return spawnGroupId
endfunction

public function Refresh takes nothing returns nothing
    call AIRoutines_RefillManagedUnitGroup(SHC_StreetGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_MarketGroupId)
    call AIRoutines_RefillManagedUnitGroup(SHC_SocialGroupId)
endfunction

private function Init takes nothing returns nothing
    set SHC_StreetRoutineId = CreateStreetRoutine()
    set SHC_MarketRoutineId = CreateMarketRoutine()
    set SHC_SocialRoutineId = CreateSocialRoutine()

    set SHC_StreetGroupId = CreateCitizenGroup(SHC_StreetRoutineId, SHC_STREET_COUNT)
    set SHC_MarketGroupId = CreateCitizenGroup(SHC_MarketRoutineId, SHC_MARKET_COUNT)
    set SHC_SocialGroupId = CreateCitizenGroup(SHC_SocialRoutineId, SHC_SOCIAL_COUNT)

    call RegisterCitizenTypes()
    call Refresh()
endfunction

endlibrary
