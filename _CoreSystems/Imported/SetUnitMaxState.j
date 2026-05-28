//////////////////////////////////////////////////////////////////////////////////////////
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@ SetUnitMaxState
//@=======================================================================================
//@ Credits:
//@---------------------------------------------------------------------------------------
//@ Written by:
//@ Earth-Fury
//@ Based on the work of:
//@ Blade.dk
//@
//@ If you use this system, please credit all of the people mentioned above in your map.
//@=======================================================================================
//@ SetUnitMaxState Readme
//@---------------------------------------------------------------------------------------
//@
//@ SetUnitMaxState() is a function origionally written by Blade.dk. It takes advantage of
//@ a bug which was introduced in one of the patches: Bonus life and mana abilitys will
//@ only ever add the bonus ammount for level 1. However, when removed, they will remove
//@ the ammount they should have added at their current level. This allows you to change a
//@ units maximum life and mana, without adding a perminent ability to the unit.
//@
//@---------------------------------------------------------------------------------------
//@ Adding SetUnitMaxState to your map:
//@
//@ Simply copy this library in to a trigger which has been converted to custom text.
//@ After that, you must copy over the abilitys. This is made easy by the ObjectMerger in
//@ JASS NewGen. Distributed with this system are //! external calls to the ObjectMerger.
//@ Simply copy both of them in to your map, save your map, close and reopen your map in
//@ the editor, and remove the external calls. (Or otherwise disable them. Removing the !
//@ after the // works.)
//@
//@---------------------------------------------------------------------------------------
//@ Using SetUnitMaxState:
//@
//@ nothing SetUnitMaxState(unit <target>, unitstate <state>, real <new value>)
//@
//@ This function changes <target>'s unitstate <state> to be eqal to <new value>. Note
//@ that the only valid unitstates this function will use are UNIT_STATE_MAX_MAN and
//@ UNIT_STATE_MAX_LIFE. Use SetUnitState() to change other unitstates.
//@
//@ nothing AddUnitMaxState(unit <target>, unitstate <state>, real <add value>)
//@
//@ This function adds <add value> to <target>'s <state> unitstate. <add value> can be
//@ less than 0, making this function reduce the specified unitstate. This function will
//@ only work with the unitstates UNIT_STATE_MAX_LIFE and UNIT_STATE_MAX_MANA.
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//////////////////////////////////////////////////////////////////////////////////////////
library SetUnitMaxState initializer Initialize
    globals
//========================================================================================
// Configuration
//========================================================================================

        // The rawcode of the life ability:
        private constant integer MAX_STATE_LIFE_ABILITY = 'A6FB'

        // The rawcode of the mana ability:
        private constant integer MAX_STATE_MANA_ABILITY = 'A6FC'

        // The maximum power of two the abilitys use:
        private constant integer MAX_STATE_MAX_POWER = 8
        
        //The dummy unit of your map
        private constant integer DUMMY_ID = 'h60N'

//========================================================================================
// System Code
//----------------------------------------------------------------------------------------
// Do not edit below this line unless you wish to change the way the system works.
//========================================================================================
    endglobals


    globals
        private integer array PowersOf2
    endglobals

    function SetUnitMaxState takes unit u, unitstate state, real newValue returns nothing
        local integer stateAbility
        local integer newVal = R2I(newValue)
        local integer i = MAX_STATE_MAX_POWER
        local integer offset

        if state == UNIT_STATE_MAX_LIFE then
            set stateAbility = MAX_STATE_LIFE_ABILITY
        elseif state == UNIT_STATE_MAX_MANA then
            set stateAbility = MAX_STATE_MANA_ABILITY
        else
            debug call BJDebugMsg("SetUnitMaxState Error: Invalid unitstate")
            return
        endif

        set newVal = newVal - R2I(GetUnitState(u, state))

        if newVal > 0 then
            set offset = MAX_STATE_MAX_POWER + 3
        elseif newVal < 0 then
            set offset = 2
            set newVal = -newVal
        else
            return
        endif

        loop
            exitwhen newVal == 0 or i < 0
            if newVal >= PowersOf2[i] then
                call UnitAddAbility(u, stateAbility)
                call SetUnitAbilityLevel(u, stateAbility, offset + i)
                call UnitRemoveAbility(u, stateAbility)
                set newVal = newVal - PowersOf2[i]
            else
                set i = i - 1
            endif
        endloop
    endfunction

    function AddUnitMaxState takes unit u, unitstate state, real addValue returns nothing
        call SetUnitMaxState(u, state, GetUnitState(u, state) + addValue)
    endfunction

    private function Initialize takes nothing returns nothing
        local integer i = 1

        set PowersOf2[0] = 1
        loop
            set PowersOf2[i] = PowersOf2[i - 1] * 2
            set i = i + 1
            exitwhen i == MAX_STATE_MAX_POWER + 3
        endloop
        
        set bj_lastCreatedUnit = CreateUnit( Player( PLAYER_NEUTRAL_PASSIVE ), DUMMY_ID, 0., 0., 0. )
        call UnitAddAbility( bj_lastCreatedUnit, MAX_STATE_LIFE_ABILITY )
        call UnitAddAbility( bj_lastCreatedUnit, MAX_STATE_MANA_ABILITY )
        call KillUnit( bj_lastCreatedUnit )
    endfunction
endlibrary