////////////////////////////////////////////////////////
//Guhun's Combat State Manager v1.0.0
////////////////////////////////////////////////////////

//This function engages both specified units in combat, adding each to the other's combat group
function GCSM_UnitEnterCombat takes unit target, unit source returns nothing
    local integer targetID = GetUnitUserData(target)
    local integer sourceID = GetUnitUserData(source)
    
    set udg_GCSM_UnitInCombat[targetID] = true
    set udg_GCSM_UnitInCombat[sourceID] = true
    
    call GroupAddUnit(udg_GCSM_CombatGroups[targetID], source)
    call GroupAddUnit(udg_GCSM_CombatGroups[sourceID], target)
endfunction

//This is function is for a ForGroup loop (not part of API)
function GCSM_Grp_EngageSupport takes nothing returns nothing
    call GCSM_UnitEnterCombat(udg_GCSM_Target, GetEnumUnit())
endfunction

//This function engages the supporter unit in combat with all units that are in combat with the target unit
function GCSM_UnitAidCombat takes unit target, unit supporter returns boolean
    local integer targetID = GetUnitUserData(target)
    if udg_GCSM_UnitInCombat[targetID] then
        set udg_GCSM_UnitInCombat[GetUnitUserData(supporter)] = true
        set udg_GCSM_Target = supporter
        call ForGroup(udg_GCSM_CombatGroups[targetID], function GCSM_Grp_EngageSupport)
        return true
    endif
    return false
endfunction

//This is function is for a ForGroup loop (not part of API)
function GCSM_Grp_RemoveFromGroup takes nothing returns nothing
    call GroupRemoveUnit(udg_GCSM_CombatGroups[GetUnitUserData(GetEnumUnit())], udg_GCSM_Target)
endfunction

//This function removes a unit from combat, removing it from the combat groups of units in combat with it
//and cleaing its own combat group.
function GCSM_UnitLeaveCombat takes unit target returns nothing
    local integer targetID = GetUnitUserData(target)
    set udg_GCSM_UnitInCombat[targetID] = false
    set udg_GCSM_Target = target
    call ForGroup(udg_GCSM_CombatGroups[targetID], function GCSM_Grp_RemoveFromGroup)
    call GroupClear(udg_GCSM_CombatGroups[targetID])
endfunction

//This function removes the speacified units form eachother's combat groups
function GCSM_UnitLeaveCombatWith takes unit target, unit source returns nothing
    call GroupRemoveUnit(udg_GCSM_CombatGroups[GetUnitUserData(target)], source)
    call GroupRemoveUnit(udg_GCSM_CombatGroups[GetUnitUserData(source)], target)
endfunction


//Returns whether a unit is in combat
function GCSM_UnitInCombat takes unit target returns boolean
    return udg_GCSM_UnitInCombat[GetUnitUserData(target)]
endfunction

//Returns whether the target unit is in the source unit's combat group
function GCSM_UnitInCombatWith takes unit target, unit source returns boolean
    return IsUnitInGroup(target, udg_GCSM_CombatGroups[GetUnitUserData(source)])
endfunction

////////////////////////////////////////////////////////
//End of Combat State Manager
////////////////////////////////////////////////////////


//=======
//Functions for GUI API
//=======

function Trig_GCSM_Main_Actions takes nothing returns nothing
    call GCSM_UnitEnterCombat(udg_GCSM_Target, udg_GCSM_Source)
endfunction

function Trig_GCSM_Main_Conditions takes nothing returns boolean
    if udg_GCSM_Source == null then
        call GCSM_UnitLeaveCombat(udg_GCSM_Target)
    else
        call GCSM_UnitAidCombat(udg_GCSM_Target, udg_GCSM_Source)
    endif
    return false
endfunction



//===========================================================================
function InitTrig_GCSM_Main takes nothing returns nothing
    set gg_trg_GCSM_Main = CreateTrigger(  )
    call TriggerAddAction( gg_trg_GCSM_Main, function Trig_GCSM_Main_Actions )
    call TriggerAddCondition( gg_trg_GCSM_Main, Condition(function Trig_GCSM_Main_Conditions) )
endfunction

