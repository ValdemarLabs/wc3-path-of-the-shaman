////////////////////////////////////////////////////////
//Guhun's Timer System version 1.0
////////////////////////////////////////////////////////
//Hashtable adresses:
//-3: Trigger
//-2: Execution Counter
//-1: User Data
////////////////////////////////////////////////////////

//This function executes when a timer expires, running the correct trigger while checking conditions and if it is enabled
function GTS_DestroyTimer takes timer t returns nothing
    call PauseTimer(t)
    call DestroyTimer(t)
    call FlushChildHashtable(udg_GTS_Hashtable, GetHandleId(t))
endfunction

function GTS_ExecuteTimer takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer tId = GetHandleId(t)
    local integer counter = LoadInteger(udg_GTS_Hashtable, tId, -2) + 1 //Increase counter
    local trigger trig = LoadTriggerHandle(udg_GTS_Hashtable, tId, -3)

    set udg_GTS_CustomValue = LoadInteger(udg_GTS_Hashtable, tId, -1)
    set udg_GTS_ExecutionCounter = counter
    
    if IsTriggerEnabled(trig) and TriggerEvaluate(trig) then
        call TriggerExecute(trig)
    endif

    if udg_GTS_DestroyTimer then
        call PauseTimer(t)
        call DestroyTimer(t)
        call FlushChildHashtable(udg_GTS_Hashtable, tId)
        set udg_GTS_DestroyTimer = false //User must manually specify if timer should be destroyed
    else
        call SaveInteger(udg_GTS_Hashtable, tId, -2, counter)
    endif
    set t = null
    set trig = null
endfunction

function GTS_RestartTimer takes timer t, real timeout returns nothing
    call TimerStart(t, timeout, true, function GTS_ExecuteTimer)
endfunction

//Creates a new timer, starts it and stores relevant data in hashtable
function GTS_StartTimer takes timer t, real timeout, trigger whichTrigger, boolean useHandleId, integer userData returns nothing
    local integer tId = GetHandleId(t)
    
    call TimerStart(t, timeout, true, function GTS_ExecuteTimer)    

    if useHandleId then
        call SaveInteger(udg_GTS_Hashtable, tId, -1, tId)
        set udg_GTS_CustomValue = tId
    else
        call SaveInteger(udg_GTS_Hashtable, tId, -1, userData)
    endif
    
    call SaveTriggerHandle(udg_GTS_Hashtable, tId, -3, whichTrigger)
endfunction

//Creates a new timer and sets GTS_Timer to it, then starts the timer
function GTS_CreateTimer takes real timeout, trigger whichTrigger, boolean useHandleId, integer userData returns nothing
    set udg_GTS_Timer = CreateTimer()
    call GTS_StartTimer(udg_GTS_Timer, timeout, whichTrigger, useHandleId, userData)
endfunction
////////////////////////////////////////////////////////
//End of Guhun's Timer System
////////////////////////////////////////////////////////

function Trig_GTS_Main_Actions takes nothing returns nothing
    if udg_GTS_TimeOut >= 0 then
        call GTS_CreateTimer(udg_GTS_TimeOut, udg_GTS_Trigger, false, udg_GTS_CustomValue)
    else
        call GTS_DestroyTimer(udg_GTS_Timer)
        set udg_GTS_Timer = null
    endif
endfunction

function Trig_GTS_Main_Conditions takes nothing returns boolean
    if udg_GTS_TimeOut >= 0 then
        call GTS_CreateTimer(udg_GTS_TimeOut, udg_GTS_Trigger, true, 0)
    else
        call GTS_RestartTimer(udg_GTS_Timer, -udg_GTS_TimeOut)
    endif
    return false
endfunction


//===========================================================================
function InitTrig_GTS_Main takes nothing returns nothing
    set gg_trg_GTS_Main = CreateTrigger()
    set udg_GTS_Hashtable = InitHashtable()
    call TriggerAddAction( gg_trg_GTS_Main, function Trig_GTS_Main_Actions )
    call TriggerAddCondition(gg_trg_GTS_Main, Condition(function Trig_GTS_Main_Conditions))
endfunction

