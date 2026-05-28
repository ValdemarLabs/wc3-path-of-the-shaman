library SRS initializer ini
    /*****************************************************************************************************/
    /**                                                                                                 **/
    /**                                 'Safe Revive System v1.6'                                       **/
    /**                                                     *****                                       **/
    /**                                                by Dalvengyr aka .....                           **/
    /**                                                                                                 **/
    /*  Why safe? This revive system allows you to revive any organic non-Hero units without recreating  */
    /*  them. In the demo map there will be shown floating shits that shows units handle that is not     */
    /*  changed after revived. What are the advantages of using this system? This method is faster than  */
    /*  recreating new unit, and save spaces in memory. The only thing you need to do is set units death */
    /*  type to 'can raise, does decay'.                                                                 */
    /*                                                                                                   */
    /*  Requirement:                                                                                     */
    /*      - JNGP                                                                                       */
    /*                                                                                                   */
    /*  Disadvantages:                                                                                   */
    /*      - None                                                                                       */
    /*                                                                                                   */
    /*  Implementation:                                                                                  */
    /*      1. Copy SRS folder into your map                                                             */
    /*      2. Copy dummy unit and spell into your map                                                   */
    /*      3. Make sure dummy and spell id below is the same with their rawcode at OE                   */
    /*      4. If you have dummy.mdx in your map, then open OE, set dummy units file model to that       */
    /*         dummy.mdx is better                                                                       */
    /*      5. Nuff said. Done.                                                                          */
    /*                                                                                                   */
    /*  APIs:                                                                                            */
    /*  1. Revive any unit you want at their current position                                            */
    /*                                                                                                   */
    /*  function ReviveUnit takes unit whichUnit returns boolean                                         */
    /*                                                                                                   */
    /*  2. Revive any unit you want at certain point                                                     */
    /*     Set boolean flag to true to check target point pathability                                    */
    /*     Keep in mind that checking pathability is always slower than not                              */
    /*                                                                                                   */
    /*  function ReviveUnitAtPoint takes unit whichUnit, real x, real y, boolean flag returns boolean    */
    /**                                                                                                 **/
    /*****************************************************************************************************/
    /*****************************************************************************************************/
    
    globals
    
    /* 'CONFIGURATIONS
       1. Dummy Id */
        private constant    integer     DUMMY_ID     = 'e000'
        
    /* 2. Spell Id */
        private constant    integer     SPELL_ID     = 'A00O'
        
    /* 3. Ressurection Order Id */
        private constant    integer     ORDER_ID     = 852094
        
    /* 'END-OF-CONFIGURATIONS' */
    
        private             unit        DUMMY
        
    endglobals

    private constant function FilterUnits takes unit u returns boolean
        return not(IsUnitType(u, UNIT_TYPE_STRUCTURE) or IsUnitType(u, UNIT_TYPE_MECHANICAL)) and not IsUnitType(u, UNIT_TYPE_HERO)
    endfunction

    private function ini takes nothing returns nothing
        set DUMMY = CreateUnit(Player(15), DUMMY_ID, 0.0, 0.0, 270.0)
        call UnitAddAbility(DUMMY, SPELL_ID)
    endfunction

   /*' APIs '*/
    function ReviveUnit takes unit whichUnit returns boolean
        if FilterUnits(whichUnit) then
            if IsUnitType(whichUnit, UNIT_TYPE_DEAD) and GetUnitTypeId(whichUnit) != 0 then
                call SetUnitOwner(DUMMY, GetOwningPlayer(whichUnit), false)
                call SetUnitX(DUMMY, GetUnitX(whichUnit))
                call SetUnitY(DUMMY, GetUnitY(whichUnit))
                call IssueImmediateOrderById(DUMMY, ORDER_ID)
                return true
            endif
        endif
        return false
    endfunction

    function ReviveUnitAtPoint takes unit whichUnit, real x, real y, boolean flag returns boolean        
        if ReviveUnit(whichUnit) then
            if flag then
                call SetUnitPosition(whichUnit, x, y)
            else
                call SetUnitX(whichUnit, x)
                call SetUnitY(whichUnit, y)
            endif
            return true
        endif
        return false
    endfunction
endlibrary