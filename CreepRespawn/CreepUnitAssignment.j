library CreepUnitAssignmentSystem requires QuestGiver, Table

/*
    Creep Respawn System - Creep Unit Assignment
    This script assigns the last created unit to a specific variable based on its unit type.

    This is part of the Creep Respawn System.

    Author: [Valdemar]

    How to use:
    - Call this function with the unit type ID (utype) of the last created unit.
    - The function will assign the unit to a global variable based on its type (udg_XXX).
    - Ensure that the global variables are defined in your map's variable editor.

    Quest System Integration:
    - When a quest giver unit respawns, this system automatically triggers quest restoration
    - QuestGiver/QuestMaster system will transfer quest data from old unit to new unit
    - Unit type ID is used to identify which quest giver respawned
    - Quest icons and availability are refreshed after unit reference update

    More on quest givers units / patrol units:

        QuestGiver:
        - call QuestGiver_Register(unit u)
        - call QuestGiver_UpdateGiverUnitReferenceByType(unitTypeId, newUnit)
        - call QuestGiver_RefreshAvailabilityForGiver(u)

        PatrolSystem
        - call PatrolSystem_Start(udg_TempUnit, 2, 10.00, 1, true)

*/

//===========================================================================
// Globals
//===========================================================================
globals
    private Table QuestRestorationTable
endglobals

//===========================================================================
// Helper function to trigger quest evaluation for respawned NPCs
//===========================================================================
private function TriggerQuestEvaluation_Delayed takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local unit newUnit = QuestRestorationTable.unit[GetHandleId(t)]
    local integer unitTypeId = QuestRestorationTable[GetHandleId(t)]
    
    // Update quest giver unit reference from old to new unit
    // This transfers all quest data, icons, and requirement tracking
    call QuestGiver_UpdateGiverUnitReferenceByType(unitTypeId, newUnit)
    
    // Refresh quest availability and icons for the new unit
    call QuestGiver_RefreshAvailabilityForGiver(newUnit)
    
    // Cleanup
    call QuestRestorationTable.unit.remove(GetHandleId(t))
    call QuestRestorationTable.remove(GetHandleId(t))
    call DestroyTimer(t)
    set t = null
    set newUnit = null
endfunction

private function TriggerQuestEvaluation takes unit u returns nothing
    local timer t = CreateTimer()
    local integer unitTypeId = GetUnitTypeId(u)
    
    // Store both unit reference and unit type ID
    set QuestRestorationTable.unit[GetHandleId(t)] = u
    set QuestRestorationTable[GetHandleId(t)] = unitTypeId
    
    // Delay quest restoration by 0.1 second to ensure unit is fully initialized
    call TimerStart(t, 0.1, false, function TriggerQuestEvaluation_Delayed)
    set t = null
endfunction

//===========================================================================
function CreepUnitAssignment takes integer utype returns nothing
    //===========================================================================
    // HORDE
    if utype == 'O606' then
        set udg_Thork = bj_lastCreatedUnit
    elseif utype == 'o61L' then
        set udg_Ragno = bj_lastCreatedUnit
    elseif utype == 'o60A' then
        set udg_Garthork = bj_lastCreatedUnit
    elseif utype == 'o60F' then
        set udg_Granis = bj_lastCreatedUnit
    elseif utype == 'o608' then
        set udg_Krezgrel = bj_lastCreatedUnit
        call TriggerQuestEvaluation(bj_lastCreatedUnit)
    elseif utype == 'o60C' then
        set udg_Grim = bj_lastCreatedUnit
    elseif utype == 'o62R' then
        set udg_Grum = bj_lastCreatedUnit
        call TriggerQuestEvaluation(bj_lastCreatedUnit)
    elseif utype == 'o60X' then
        set udg_OutcastJinzun = bj_lastCreatedUnit
        call TriggerQuestEvaluation(bj_lastCreatedUnit)
        // Start patrol movement
        call TriggerExecute(gg_trg_Outcast_Jinzun_Movement_Start)    
    elseif utype == 'o60D' then
        set udg_Drekthor = bj_lastCreatedUnit
    elseif utype == 'o612' then
        set udg_Ogmar = bj_lastCreatedUnit
    elseif utype == 'o61C' then
        set udg_Erduk = bj_lastCreatedUnit
    elseif utype == 'o61S' then
        set udg_Graknar = bj_lastCreatedUnit 
    elseif utype == 'o008' then
        set udg_KodoGrak = bj_lastCreatedUnit 
        // Start follow movement (if quest active)
        // Todo note >> use new Quest systems functions to check quest state and manage follow system!
        if IsQuestDiscovered(udg_QuestMistakenKin) and not IsQuestCompleted(udg_QuestMistakenKin) then
            set udg_FollowSystem_Source = udg_KodoGrak
            set udg_FollowSystem_Target = udg_Nazgrek
            call FollowSystem_SetFollow(udg_FollowSystem_Source, udg_FollowSystem_Target, 800.0, true, 5.0, FOLLOW_STYLE_PASSIVE, true, true)
        endif
    //===========================================================================
    // GOBLINS
    elseif utype == 'n013' then
        set udg_BoomBrothers = bj_lastCreatedUnit
        call TriggerQuestEvaluation(bj_lastCreatedUnit)
    elseif utype == 'n01A' then
        set udg_AtexBlix = bj_lastCreatedUnit
    elseif utype == 'n61E' then
        set udg_Kribugs = bj_lastCreatedUnit
        call TriggerQuestEvaluation(bj_lastCreatedUnit)
        // Start patrol movement
        call TriggerExecute(gg_trg_Kribugs_Movement_Start)        
    //===========================================================================
    // SATYR
    elseif utype == 'n636' then
        set udg_Succubus = bj_lastCreatedUnit
    elseif utype == 'n62W' then
        set udg_Zaekolaerr = bj_lastCreatedUnit
    //===========================================================================
    // HUMAN
    elseif utype == 'h60Z' then
        set udg_MysterWizard = bj_lastCreatedUnit
    //===========================================================================
    // BOSS
    elseif utype == 'n645' then
        set udg_BossMordrax = bj_lastCreatedUnit
        // Start patrol movement
        call TriggerExecute(gg_trg_Mordrax_Movement_Start)     
    elseif utype == 'n020' then
        set udg_BossMorthun = bj_lastCreatedUnit
        // Start patrol movement
        call TriggerExecute(gg_trg_Morthun_Movement_Start)     
    elseif utype == 'e002' then
        set udg_BossMountainGiant = bj_lastCreatedUnit
        // Start patrol movement
        call TriggerExecute(gg_trg_MountainGiant_Movement_Start)            
    //===========================================================================
    // ELVES
    elseif utype == 'h00A' then
        set udg_Aradion = bj_lastCreatedUnit
    elseif utype == 'n01W' then
        set udg_Valeria = bj_lastCreatedUnit
    //==========================================================
    //===========================================================================
    endif
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================
private function Init takes nothing returns nothing
    set QuestRestorationTable = Table.create()
endfunction

endlibrary