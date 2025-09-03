/*
    Creep Respawn System - Creep Unit Assignment
    This script assigns the last created unit to a specific variable based on its unit type.

    This is part of the Creep Respawn System.

    Author: [Valdemar]

    How to use:
    - Call this function with the unit type ID (utype) of the last created unit.
    - The function will assign the unit to a global variable based on its type (udg_XXX).
    - Ensure that the global variables are defined in your map's variable editor.

    More on quest givers units / patrol units:

        QuestIconSystem:
        - call CreateDummyQuestIcon(unit u, string questType, integer questState)
        OR
        - call QuestIcon_RegisterQuest(unit u, integer questID, string questType, integer questState)
        OR
        - call QuestIcon_UpdateForNPC(u)  

        PatrolSystem
        - call PatrolSystem_Start(udg_TempUnit, 2, 10.00, 1, true)

*/
//===========================================================================

function CreepUnitAssignment takes integer utype returns nothing
    //===========================================================================
    // HORDE
    if utype == 'O606' then
        set udg_ThorkHellscream = bj_lastCreatedUnit
    elseif utype == 'o61L' then
        set udg_Ragno = bj_lastCreatedUnit
    elseif utype == 'o60A' then
        set udg_Garthork = bj_lastCreatedUnit
    elseif utype == 'o60F' then
        set udg_Granis = bj_lastCreatedUnit
    elseif utype == 'o608' then
        set udg_Krezgrel = bj_lastCreatedUnit
    elseif utype == 'o60C' then
        set udg_Grim = bj_lastCreatedUnit
    elseif utype == 'o62R' then
        set udg_Grum = bj_lastCreatedUnit
    elseif utype == 'o60X' then
        set udg_OutcastJinzun = bj_lastCreatedUnit
    elseif utype == 'o60D' then
        set udg_Drekthor = bj_lastCreatedUnit
    elseif utype == 'o612' then
        set udg_Ogmar = bj_lastCreatedUnit
    elseif utype == 'o61C' then
        set udg_Erduk = bj_lastCreatedUnit
    
    //===========================================================================

    //===========================================================================
    // GOBLINS
    elseif utype == 'n013' then
        set udg_BoomBrothers = bj_lastCreatedUnit
    elseif utype == 'n01A' then
        set udg_AtexBlix = bj_lastCreatedUnit
    elseif utype == 'n61E' then
        set udg_Kribugs = bj_lastCreatedUnit
    //===========================================================================

    //===========================================================================
    // SATYR
    elseif utype == 'n636' then
        set udg_Succubus = bj_lastCreatedUnit
    elseif utype == 'n62W' then
        set udg_Zaekolaerr = bj_lastCreatedUnit
    
    //===========================================================================

    //===========================================================================
    // HUMAN
    elseif utype == 'h60Z' then
        set udg_MysterWizard = bj_lastCreatedUnit
    endif
    
    //===========================================================================

    // MORE TYPES HERE
    
endfunction
//===========================================================================