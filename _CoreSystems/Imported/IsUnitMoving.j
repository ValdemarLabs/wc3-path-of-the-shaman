function IsUnitMovementTracked takes integer i returns boolean
    return udg_UMovPrev[i] != 0 or udg_UMovNext[0] == i
endfunction

function UnitMovementRegister takes nothing returns boolean
    local integer i = udg_UDex
    if not IsUnitMovementTracked(i) and TriggerEvaluate(gg_trg_Is_Unit_Moving_Config) then
        set udg_UMovPrev[udg_UMovNext[0]] = i
        set udg_UMovNext[i] = udg_UMovNext[0]
        set udg_UMovNext[0] = i
        set udg_UnitMovingX[i] = GetUnitX(udg_UDexUnits[i])
        set udg_UnitMovingY[i] = GetUnitY(udg_UDexUnits[i])
    endif
    return false
endfunction

function UnitMovementUnregister takes nothing returns boolean
    local integer i = udg_UDex
    if IsUnitMovementTracked(i) then
        set udg_UnitMoving[i] = false
        set udg_UMovNext[udg_UMovPrev[i]] = udg_UMovNext[i]
        set udg_UMovPrev[udg_UMovNext[i]] = udg_UMovPrev[i]
        set udg_UMovPrev[i] = 0
    endif
    return false
endfunction

function RunUnitMovementEvent takes integer i, real e returns nothing
    local integer pdex = udg_UDex
    if e == 1.00 then
        set udg_UnitMoving[i] = true
    else
        set udg_UnitMoving[i] = false
    endif
    set udg_UDex = i
    set udg_UnitMovingEvent = e
    set udg_UnitMovingEvent = 0.00
    set udg_UDex = pdex
endfunction

//===========================================================================
// This function runs periodically to check if units are actually moving.
// 
function UnitMovementTracker takes nothing returns nothing
    local integer i = 0
    local integer n
    local real x
    local real y
    loop
        set i = udg_UMovNext[i]
        exitwhen i == 0
        set x = GetUnitX(udg_UDexUnits[i])
        set y = GetUnitY(udg_UDexUnits[i])
        if x != udg_UnitMovingX[i] or y != udg_UnitMovingY[i] then
            set udg_UnitMovingX[i] = x
            set udg_UnitMovingY[i] = y
            if not udg_UnitMoving[i] then
                if GetUnitTypeId(udg_UDexUnits[i]) != 0 then
                    call RunUnitMovementEvent(i, 1.00)
                else
                    set n = udg_UDex
                    set udg_UDex = i
                    set i = udg_UMovPrev[i] //avoid skipping checks
                    call UnitMovementUnregister()
                    set udg_UDex = n
                endif
            endif
        elseif udg_UnitMoving[i] then
            call RunUnitMovementEvent(i, 2.00)
        endif
    endloop
endfunction

//===========================================================================
function InitTrig_Is_Unit_Moving takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterVariableEvent(t, "udg_UnitIndexEvent", EQUAL, 1.00)
    call TriggerAddCondition(t, Filter(function UnitMovementRegister))
    
    set t = CreateTrigger()
    call TriggerRegisterVariableEvent(t, "udg_UnitIndexEvent", EQUAL, 2.00)
    call TriggerAddCondition(t, Filter(function UnitMovementUnregister))
    
    if gg_trg_Is_Unit_Moving_Config != null then
        call TriggerExecute(gg_trg_Is_Unit_Moving_Config)
    else
        call ExecuteFunc("Trig_Is_Unit_Moving_Config_Actions")
    endif
    call TimerStart(CreateTimer(), udg_UnitMovementInterval, true, function UnitMovementTracker)
endfunction