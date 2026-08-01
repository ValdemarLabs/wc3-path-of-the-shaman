/**
    AbilityShieldBlock

    Author: Valdemar
    Version: 1.0.0

    Description:
    Handles the 50%, 75%, and 100% Shield Block abilities. Casting one adds
    its block bonus for five seconds and removes that exact bonus afterward.

    Credits:
    - Old GUI Shield Block triggers

    How to install:
    Import after TimerUtils and UnitStats. Disable the old GUI Shield Block
    trigger folder; DEquipment now owns shield ability add/remove behavior.

    API:
    - AbilityShieldBlock_ABILITY_50
    - AbilityShieldBlock_ABILITY_75
    - AbilityShieldBlock_ABILITY_100
    - set abilityId = AbilityShieldBlock_GetAbilityId(blockAmount)

**/
library AbilityShieldBlock initializer Init requires TimerUtils, UnitStats

globals
    constant integer AbilityShieldBlock_ABILITY_50 = 'A6AD'
    constant integer AbilityShieldBlock_ABILITY_75 = 'A6AE'
    constant integer AbilityShieldBlock_ABILITY_100 = 'A6AF'

    private constant real BLOCK_DURATION = 5.00
    private hashtable ShieldBlockTimerData = InitHashtable()
endglobals

function AbilityShieldBlock_GetAbilityId takes integer blockAmount returns integer
    if blockAmount == 75 then
        return AbilityShieldBlock_ABILITY_75
    elseif blockAmount == 100 then
        return AbilityShieldBlock_ABILITY_100
    endif
    return AbilityShieldBlock_ABILITY_50
endfunction

private function GetBlockAmount takes integer abilityId returns integer
    if abilityId == AbilityShieldBlock_ABILITY_50 then
        return 50
    elseif abilityId == AbilityShieldBlock_ABILITY_75 then
        return 75
    elseif abilityId == AbilityShieldBlock_ABILITY_100 then
        return 100
    endif
    return 0
endfunction

private function RemoveBlockBonus takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()
    local integer timerId = GetHandleId(expiredTimer)
    local unit caster = LoadUnitHandle(ShieldBlockTimerData, timerId, 0)
    local integer blockAmount = LoadInteger(ShieldBlockTimerData, timerId, 1)
    local integer unitId = 0

    if caster != null and GetUnitTypeId(caster) != 0 then
        set unitId = GetUnitUserData(caster)
        if unitId > 0 then
            set udg_Stats_Block[unitId] = udg_Stats_Block[unitId] - blockAmount
        endif
    endif

    call FlushChildHashtable(ShieldBlockTimerData, timerId)
    call ReleaseTimer(expiredTimer)
    set caster = null
    set expiredTimer = null
endfunction

private function HandleSpellEffect takes nothing returns nothing
    local integer abilityId = GetSpellAbilityId()
    local integer blockAmount = GetBlockAmount(abilityId)
    local unit caster
    local integer unitId
    local timer durationTimer
    local integer timerId

    if blockAmount > 0 then
        set caster = GetTriggerUnit()
        set unitId = GetUnitUserData(caster)
        if unitId > 0 then
            set udg_Stats_Block[unitId] = udg_Stats_Block[unitId] + blockAmount
            set durationTimer = NewTimer()
            set timerId = GetHandleId(durationTimer)
            call SaveUnitHandle(ShieldBlockTimerData, timerId, 0, caster)
            call SaveInteger(ShieldBlockTimerData, timerId, 1, blockAmount)
            call TimerStart(durationTimer, BLOCK_DURATION, false, function RemoveBlockBonus)
        endif
    endif

    set durationTimer = null
    set caster = null
endfunction

private function HandleSpellFinish takes nothing returns nothing
    if GetBlockAmount(GetSpellAbilityId()) > 0 then
        call SetUnitAnimation(GetTriggerUnit(), "attack slam")
        call QueueUnitAnimation(GetTriggerUnit(), "stand")
    endif
endfunction

private function Init takes nothing returns nothing
    local trigger effectTrigger = CreateTrigger()
    local trigger finishTrigger = CreateTrigger()
    local integer playerId = 0

    loop
        exitwhen playerId >= bj_MAX_PLAYER_SLOTS
        call TriggerRegisterPlayerUnitEvent(effectTrigger, Player(playerId), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
        call TriggerRegisterPlayerUnitEvent(finishTrigger, Player(playerId), EVENT_PLAYER_UNIT_SPELL_FINISH, null)
        set playerId = playerId + 1
    endloop
    call TriggerAddAction(effectTrigger, function HandleSpellEffect)
    call TriggerAddAction(finishTrigger, function HandleSpellFinish)

    set effectTrigger = null
    set finishTrigger = null
endfunction

endlibrary
