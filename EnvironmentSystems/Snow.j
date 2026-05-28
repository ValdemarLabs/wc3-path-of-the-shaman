library SnowSystem initializer Init
//===========================================================================
/*
    Snow System 1.0

    Author: [Valdemar]

    Description:
    This system manages snow units in multiple zones, allowing for random snow generation and gradual destruction.

    API:
    -   call CreateRandomSnow(integer zone)
    -   call DestroySnow(integer zone)
    -   call StartGradualDestroy(integer zone)

*/ 
//===========================================================================

globals
    private constant boolean DEBUG_MODE = true

    private integer MAX_SNOW_ZONES = 10    // Max number of snow zones
    private integer array snowUnitCount    // Tracks how many snow units exist per zone
    private unit array snowUnits           // Stores snow units (supports multiple zones)
    private timer array SnowDestroyTimer   // Timer for gradual snow destruction per zone
    private integer array SnowDestructionAmount // Number of units to remove per tick per zone
    private real array SnowDestroyInterval // Interval between destruction ticks per zone
endglobals
//===========================================================================
// Debug output
private function Debug takes string msg returns nothing
    if DEBUG_MODE then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[SnowSystem] " + msg)
    endif
endfunction

//===========================================================================
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

//===========================================================================
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

//===========================================================================
// GRADUAL SNOW DESTROY
function GradualDestroySnow takes nothing returns nothing
    local integer zone = 0
    local integer index
    local integer n
    local integer removeCount
    local integer i
    // Find which zone's timer expired
    set i = 0
    loop
        exitwhen i >= MAX_SNOW_ZONES
        if GetExpiredTimer() == SnowDestroyTimer[i] then
            set zone = i
            exitwhen true
        endif
        set i = i + 1
    endloop
    set n = 0
    set removeCount = SnowDestructionAmount[zone]
    if snowUnitCount[zone] > 0 then
        loop
            exitwhen n >= removeCount or snowUnitCount[zone] <= 0
            set index = GetRandomInt(0, snowUnitCount[zone] - 1)
            call Debug("Removing random snow unit " + I2S(index) + " from zone " + I2S(zone))
            call RemoveUnit(snowUnits[zone * 100 + index])
            // Move the last unit into the removed slot to keep the array compact
            if index != snowUnitCount[zone] - 1 then
                set snowUnits[zone * 100 + index] = snowUnits[zone * 100 + snowUnitCount[zone] - 1]
            endif
            set snowUnits[zone * 100 + snowUnitCount[zone] - 1] = null
            set snowUnitCount[zone] = snowUnitCount[zone] - 1
            set n = n + 1
        endloop
        // Restart timer if more units remain
        if snowUnitCount[zone] > 0 then
            call TimerStart(SnowDestroyTimer[zone], SnowDestroyInterval[zone], false, function GradualDestroySnow)
        else
            call PauseTimer(SnowDestroyTimer[zone])
            call Debug("Snow destruction complete for zone " + I2S(zone))
        endif
    else
        // Destruction complete, stop the timer
        call PauseTimer(SnowDestroyTimer[zone])
        call Debug("Snow destruction complete for zone " + I2S(zone))
    endif
endfunction

//===========================================================================
function StartGradualDestroy takes integer zone, real destroyInterval returns nothing
    set SnowDestructionAmount[zone] = 1 // Default to 1 if not set (for backward compatibility)
    set SnowDestroyInterval[zone] = destroyInterval
    if SnowDestroyTimer[zone] == null then
        set SnowDestroyTimer[zone] = CreateTimer()
    endif
    call TimerStart(SnowDestroyTimer[zone], SnowDestroyInterval[zone], false, function GradualDestroySnow)
    call Debug("Started gradual snow destruction for zone " + I2S(zone) + ", total units: " + I2S(snowUnitCount[zone]) + ", per tick: " + I2S(SnowDestructionAmount[zone]))
endfunction

// Overloaded version to allow specifying amount per tick
function StartGradualDestroyEx takes integer zone, real destroyInterval, integer amount returns nothing
    set SnowDestructionAmount[zone] = amount
    set SnowDestroyInterval[zone] = destroyInterval
    if SnowDestroyTimer[zone] == null then
        set SnowDestroyTimer[zone] = CreateTimer()
    endif
    call TimerStart(SnowDestroyTimer[zone], SnowDestroyInterval[zone], false, function GradualDestroySnow)
    call Debug("Started gradual snow destruction for zone " + I2S(zone) + ", total units: " + I2S(snowUnitCount[zone]) + ", per tick: " + I2S(amount))
endfunction

//===========================================================================
private function Init takes nothing returns nothing
    // No need to create timers here; they are created per zone as needed
endfunction


endlibrary

