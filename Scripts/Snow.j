
//===========================================================================
/*
    Snow System 1.0

    Author: [Queel]

    Description:
    This system manages snow units in multiple zones, allowing for random snow generation and gradual destruction.

    API:
    -   call CreateRandomSnow(integer zone)
    -   call DestroySnow(integer zone)
    -   call StartGradualDestroy(integer zone)

*/ 
//===========================================================================
globals
    integer MAX_SNOW_ZONES = 10    // Max number of snow zones
    integer array snowUnitCount    // Tracks how many snow units exist per zone
    unit array snowUnits           // Stores snow units (supports multiple zones)
endglobals


function CreateRandomSnow takes integer zone returns nothing
    local rect snowRegion = udg_SnowRegions[zone]   // Get the region for this zone
    local integer snowCount = udg_SnowAmounts[zone] // Get the configured snow amount
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

        // Store the unit in the correct zone's storage
        set snowUnits[zone * 100 + snowUnitCount[zone]] = snow
        set snowUnitCount[zone] = snowUnitCount[zone] + 1

        set i = i + 1
    endloop
endfunction

// IMMEDIATE SNOW DESTROY
function DestroySnow takes integer zone returns nothing
    local integer i = snowUnitCount[zone] - 1 // Start from last created unit

    loop
        exitwhen i < 0  // Stop when no more units exist

        call RemoveUnit(snowUnits[zone * 100 + i]) // Remove last-created unit
        set i = i - 1 // Move to the previous unit
    endloop

    // Reset the counter for this zone
    set snowUnitCount[zone] = 0
endfunction

// GRADUAL SNOW DESTROY
function GradualDestroySnow takes nothing returns nothing
    local integer zone = udg_SnowDestructionZone // Zone being processed
    local integer index

    if snowUnitCount[zone] > 0 then
        set index = snowUnitCount[zone] - 1 // Get the last unit index
        call RemoveUnit(snowUnits[zone * 100 + index]) // Remove last unit
        set snowUnitCount[zone] = index // Decrease the count

        // Restart timer if more units remain
        call TimerStart(udg_SnowDestroyTimer, 1.0, false, function GradualDestroySnow)
    else
        // Destruction complete, stop the timer
        call DestroyTimer(udg_SnowDestroyTimer)
    endif
endfunction

function StartGradualDestroy takes integer zone returns nothing
    set udg_SnowDestructionZone = zone // Store zone being destroyed
    call TimerStart(udg_SnowDestroyTimer, 1.0, false, function GradualDestroySnow)
endfunction

