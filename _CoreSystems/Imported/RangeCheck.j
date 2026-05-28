library RangeCheck

    //===========================================================================
    // RangeCheck Library
    // Author: [Valdemar]
    // 
    // Provides functions to check the range from a unit or point to the closest
    // unit owned by a specified player.
    //
    // API:
    //   - RangeCheck_Unit(unit target, player p) -> real
    //       Returns the distance to the closest unit owned by player p from target unit
    //       Returns -1.0 if no unit found
    //
    //   - RangeCheck_Point(real x, real y, player p) -> real
    //       Returns the distance to the closest unit owned by player p from the point
    //       Returns -1.0 if no unit found
    //===========================================================================

    globals
        private group tempGroup = CreateGroup()
    endglobals

    //===========================================================================
    // Returns the distance to the closest unit owned by player p from target unit
    // Returns -1.0 if no unit is found
    //===========================================================================
    function RangeCheck_Unit takes unit target, player p returns real
        local real x = GetUnitX(target)
        local real y = GetUnitY(target)
        local real minDist = -1.0
        local real dist
        local unit u
        
        call GroupEnumUnitsOfPlayer(tempGroup, p, null)
        
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            call GroupRemoveUnit(tempGroup, u)
            
            // Skip the target unit itself if it belongs to player p
            if u != target then
                set dist = SquareRoot((GetUnitX(u) - x) * (GetUnitX(u) - x) + (GetUnitY(u) - y) * (GetUnitY(u) - y))
                
                if minDist < 0.0 or dist < minDist then
                    set minDist = dist
                endif
            endif
        endloop
        
        return minDist
    endfunction

    //===========================================================================
    // Returns the distance to the closest unit owned by player p from the point (x, y)
    // Returns -1.0 if no unit is found
    //===========================================================================
    function RangeCheck_Point takes real x, real y, player p returns real
        local real minDist = -1.0
        local real dist
        local unit u
        
        call GroupEnumUnitsOfPlayer(tempGroup, p, null)
        
        loop
            set u = FirstOfGroup(tempGroup)
            exitwhen u == null
            call GroupRemoveUnit(tempGroup, u)
            
            set dist = SquareRoot((GetUnitX(u) - x) * (GetUnitX(u) - x) + (GetUnitY(u) - y) * (GetUnitY(u) - y))
            
            if minDist < 0.0 or dist < minDist then
                set minDist = dist
            endif
        endloop
        
        return minDist
    endfunction

endlibrary
