globals
    integer snowUnitCount2 = 0
    unit array snowUnits2
endglobals


// Creates random "h000" units around the configured region
function CreateRandomSnowDebug takes nothing returns nothing
    local rect snowRegion = udg_SnowRegion	// Configurable snow region
    local integer snowCount = udg_SnowAmount   // Configurable number of snow units
    local real minX = GetRectMinX(snowRegion)
    local real maxX = GetRectMaxX(snowRegion)
    local real minY = GetRectMinY(snowRegion)
    local real maxY = GetRectMaxY(snowRegion)
    local integer i = 0
    local real x
    local real y
    local unit snow

    loop
        exitwhen i >= snowCount

        set x = GetRandomReal(minX, maxX)
        set y = GetRandomReal(minY, maxY)

        // Create a snow unit ("h000") at the random location
        set snow = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), 'h006', x, y, 0)

        // Store the unit in the global array for later cleanup
        set snowUnits[snowUnitCount2] = snow
        set snowUnitCount2 = snowUnitCount2 + 1

        set i = i + 1
    endloop
endfunction

// Removes all created snow units
function DestroySnowDebug takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= snowUnitCount2
        
        // Remove the unit from the game
        call RemoveUnit(snowUnits[i])
        set i = i + 1
    endloop

    // Reset the counter
    set snowUnitCount2 = 0
endfunction
