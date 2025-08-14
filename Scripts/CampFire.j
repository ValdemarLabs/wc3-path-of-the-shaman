library CampFire initializer InitCampFireBuffSystem
//===========================================================================
/*
    CampFire Buff System 1.0

    Author: [Valdemar]

    Description:
    This system adds a "Rested" buff to hero units that remain near a campfire for 15 seconds.
    It requires a unit indexer (uses GetUnitUserData for indexing) and a dummy unit with an ability to apply the rested buff via Acid Bomb (or similar).    
    The system tracks campfires, applies buffs, and manages timers for heroes.

    Adds a "Rested" buff to hero units that remain near a campfire for 15 seconds
    Requires:
    - Unit indexer (uses GetUnitUserData for indexing)
    - Dummy unit with ability to apply rested buff via Acid Bomb (or similar)

    API:
    -   call AddCampfire(unit u) - Adds a new campfire to the system    
    -   call RemoveCampfire(unit u) - Removes a campfire from the system
    -   call InitCampFireBuffSystem() - Initializes the system and sets up the main loop
    -   call CampFireBuffLoop() - Main loop that checks for heroes near campfires and applies buffs 
    -   call ApplyRestedBuff() - Callback function that applies the rested buff when the timer expires
    -   call FilterRestedHeroes() - Filters for nearby hero units that can receive the rested buff
*/ 
//===========================================================================
//////////////////////////////////////////////////
//===========================================================================
globals
    // === CONSTANTS ===
    constant integer ABIL_ID_WARMTH     = 'B607'  // Buff indicating hero is near campfire
    constant integer ABIL_ID_RESTED     = 'B611'  // Buff to be applied after 15 seconds
    constant integer DUMMY_RESTED_ID    = 'n63H'  // Dummy caster unit type for buff application
    constant integer CAMPFIRE_UNIT_ID   = 'n61C'  // Campfire unit ID (if needed for validation)
    constant real CAMPFIRE_RADIUS       = 300.00  // Detection radius around campfires
    constant real RESTED_DELAY          = 15.00   // Time to stay near fire for rested buff
    constant integer MAX_CAMPFIRES      = 128         // Max number of active campfires
    constant integer CAMPFIRES_PER_TICK = 4           // Number of campfires to process per tick

    // Arrays to track buff timers and states
    unit array RestedUnitByIndex                  // Hero waiting to receive rested buff
    timer array RestedTimerByIndex                // Timer for delayed rested buff
    boolean array NeedsRestedByIndex              // Prevents duplicate timers per hero

    // Working group and timer
    group gTemp = null                            // Temporary group used for hero scans
    timer tMain = null                            // Repeating timer for the main loop

    // Campfire tracking
    unit array gCampfireList                      // Stores active campfire units
    integer campfireCount = 0                     // Current number of campfires
    integer campfireScanIndex = 0                 // Current index of campfire being scanned
endglobals

//===========================================================================
// FilterRestedHeroes
// Filters for nearby units (heroes only, alive)
//===========================================================================
function FilterRestedHeroes takes nothing returns boolean
    local unit u = GetFilterUnit()
    return IsUnitType(u, UNIT_TYPE_HERO) and GetUnitState(u, UNIT_STATE_LIFE) > 0.405
endfunction

//===========================================================================
// ApplyRestedBuff
// Called when a unit has waited long enough near a fire to receive the buff
// Callback when 15-second timer expires — applies rested buff
//===========================================================================
function ApplyRestedBuff takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    local unit hero
    local unit dummy

     // Find which hero this timer was for
    loop
        exitwhen i >= bj_MAX_PLAYERS * 12
        if RestedTimerByIndex[i] == t then
            set hero = RestedUnitByIndex[i]
            set RestedTimerByIndex[i] = null
            set RestedUnitByIndex[i] = null
            set NeedsRestedByIndex[i] = false
            exitwhen true
        endif
        set i = i + 1
    endloop

    // Apply the rested buff using dummy caster
    if hero != null and GetUnitAbilityLevel(hero, ABIL_ID_WARMTH) > 0 and GetUnitAbilityLevel(hero, ABIL_ID_RESTED) == 0 then
        set dummy = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), DUMMY_RESTED_ID, GetUnitX(hero), GetUnitY(hero), 0)
        call UnitApplyTimedLife(dummy, 'BTLF', 1.0)
        call IssueTargetOrder(dummy, "acidbomb", hero)
        call DisplayTextToPlayer(GetOwningPlayer(hero), 0, 0, "|cFFFFCC00" + GetHeroProperName(hero) + " is now Rested!|r")
    endif

    call DestroyTimer(t)
endfunction

//===========================================================================
// CampFireBuffLoop
// Runs periodically while campfires exist
// Checks nearby units and starts timers for resting
// Main looping function — processes a few campfires per tick
//===========================================================================
function CampFireBuffLoop takes nothing returns nothing
    local integer i = 0
    local unit fire
    local unit hero
    local real x
    local real y
    local integer index
    local timer newTimer
    local integer endIndex

    // Stop if no campfires
    if campfireCount == 0 then
        call PauseTimer(tMain)
        return
    endif

    // Set range of campfires to process this tick
    set endIndex = campfireScanIndex + CAMPFIRES_PER_TICK
    if endIndex > campfireCount then
        set endIndex = campfireCount
    endif

    // Process each campfire in range
    loop
        exitwhen campfireScanIndex >= endIndex
        set fire = gCampfireList[campfireScanIndex]
        set x = GetUnitX(fire)
        set y = GetUnitY(fire)

        // Pick nearby valid heroes
        call GroupEnumUnitsInRange(gTemp, x, y, CAMPFIRE_RADIUS, Condition(function FilterRestedHeroes))

        loop
            set hero = FirstOfGroup(gTemp)
            exitwhen hero == null
            call GroupRemoveUnit(gTemp, hero)

            // If hero has Warmth and not yet Rested, start delay timer
            if GetUnitAbilityLevel(hero, ABIL_ID_WARMTH) > 0 and GetUnitAbilityLevel(hero, ABIL_ID_RESTED) == 0 then
                set index = GetUnitUserData(hero)
                if not NeedsRestedByIndex[index] then
                    set NeedsRestedByIndex[index] = true
                    set RestedUnitByIndex[index] = hero
                    set newTimer = CreateTimer()
                    set RestedTimerByIndex[index] = newTimer
                    call TimerStart(newTimer, RESTED_DELAY, false, function ApplyRestedBuff)
                endif
            endif
        endloop

        set campfireScanIndex = campfireScanIndex + 1
    endloop

    // Reset index if end reached
    if campfireScanIndex >= campfireCount then
        set campfireScanIndex = 0
    endif
endfunction

//===========================================================================
// AddCampfire
// Adds a new campfire to the system and starts the loop if it's the first one
// Adds a campfire unit to the scan list
//===========================================================================
function AddCampfire takes unit u returns nothing
    if campfireCount < MAX_CAMPFIRES then
        set gCampfireList[campfireCount] = u
        set campfireCount = campfireCount + 1
        if campfireCount == 1 then
            call TimerStart(tMain, 1.0, true, function CampFireBuffLoop)
        endif
    endif
endfunction

//===========================================================================
// RemoveCampfire
// Removes a campfire and stops the loop if none remain
// Removes a campfire unit from the scan list
//===========================================================================
function RemoveCampfire takes unit u returns nothing
    local integer i = 0
    loop
        exitwhen i >= campfireCount
        if gCampfireList[i] == u then
            set gCampfireList[i] = gCampfireList[campfireCount - 1]
            set gCampfireList[campfireCount - 1] = null
            set campfireCount = campfireCount - 1

             // Stop timer if none left
            if campfireCount <= 0 then
                call PauseTimer(tMain)
                set campfireCount = 0
            endif
            return
        endif
        set i = i + 1
    endloop
endfunction

//===========================================================================
// InitCampFireBuffSystem
// Initialization of globals and timer
//===========================================================================
function InitCampFireBuffSystem takes nothing returns nothing
    set gTemp = CreateGroup()
    set tMain = CreateTimer()
endfunction

endlibrary
