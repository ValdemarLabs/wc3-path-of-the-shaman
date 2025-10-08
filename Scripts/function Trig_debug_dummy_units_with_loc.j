function Trig_debug_dummy_units_with_locust_Conditions takes nothing returns boolean
    if ( not ( GetUnitAbilityLevelSwapped('Aloc', GetTriggerUnit()) > 0 ) ) then
        return false
        call BJDebugMsg("Locust unit died: " + GetUnitName(u))
        call BJDebugMsg("Owner: " + GetPlayerName(GetOwningPlayer(u)))
        call BJDebugMsg("X: " + R2S(GetUnitX(u)))
        call BJDebugMsg("Y: " + R2S(GetUnitY(u)))

    endif
    return true
endfunction

function Trig_debug_dummy_units_with_locust_Actions takes nothing returns nothing
endfunction

//===========================================================================
function InitTrig_debug_dummy_units_with_locust takes nothing returns nothing
    set gg_trg_debug_dummy_units_with_locust = CreateTrigger(  )
    call TriggerRegisterAnyUnitEventBJ( gg_trg_debug_dummy_units_with_locust, EVENT_PLAYER_UNIT_DEATH )
    call TriggerAddCondition( gg_trg_debug_dummy_units_with_locust, Condition( function Trig_debug_dummy_units_with_locust_Conditions ) )
    call TriggerAddAction( gg_trg_debug_dummy_units_with_locust, function Trig_debug_dummy_units_with_locust_Actions )
endfunction

