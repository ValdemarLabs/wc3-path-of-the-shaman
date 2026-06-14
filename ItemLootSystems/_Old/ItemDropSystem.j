library ItemDropSystem requires ItemDropConfig, ItemDropCore, ItemDropSpecific, ItemDropBoss, ItemDropDestructible
//===========================================================================
/*
    ItemDropSystem 1.0
    
    Author: [Valdemar]
    
    Description:
    Main item drop system that ties together all subsystems.
    Handles unit death events and routes to appropriate drop handlers:
    - Boss drops (highest priority)
    - Unit-specific drops (medium priority)
    - Generic level-based drops (default)
    - Destructible drops (handled by ItemDropDestructible)
    
    Sub-Libraries:
    - ItemDropConfig: Configuration and data storage
    - ItemDropCore: Generic drop logic and algorithms
    - ItemDropSpecific: Unit-specific drops (wolves, dragons, etc.)
    - ItemDropBoss: Boss-specific drops
    - ItemDropDestructible: Destructible drops (crates, barrels)
    
    Usage:
    The system automatically initializes on map start. No manual setup required.
    All drop tables are configured in ItemDropConfig.
    
    API:
    - ItemDropSystem_RegisterBoss(unit u): Mark unit as boss (skips generic drops)
    - ItemDropSystem_UnregisterBoss(unit u): Remove boss flag
    
    Drop Priority:
    1. Check if boss → use ItemDropBoss
    2. Check if specific unit → use ItemDropSpecific
    3. Default → use ItemDropCore (generic drops)
*/
//===========================================================================
globals
    // Statistics (optional, for debugging)
    private integer TOTAL_DROPS = 0
    private integer BOSS_DROPS = 0
    private integer SPECIFIC_DROPS = 0
    private integer GENERIC_DROPS = 0
endglobals

//===========================================================================
// API: Register a unit as boss
// Boss units will only use ItemDropBoss for drops
// This adds boss metadata to the unit's Table entry
//===========================================================================
function ItemDropSystem_RegisterBoss takes unit u returns nothing
    set BossMetadataTable[GetHandleId(u)] = 1
endfunction

//===========================================================================
// API: Unregister a unit as boss
//===========================================================================
function ItemDropSystem_UnregisterBoss takes unit u returns nothing
    call BossMetadataTable.remove(GetHandleId(u))
endfunction

//===========================================================================
// HELPER: Check if unit is boss (registered manually or by unit type)
//===========================================================================
private function ItemDropSystem_IsBoss takes unit u returns boolean
    local integer unitTypeId = GetUnitTypeId(u)
    local integer lootType = UnitLootTypeTable[unitTypeId]
    
    // Check if manually registered as boss
    if BossMetadataTable.has(GetHandleId(u)) then
        return true
    endif
    
    // Check if unit type is a boss type
    if lootType >= BOSS_FELDOK and lootType <= BOSS_MORDRAX then
        return true
    endif
    
    return false
endfunction

//===========================================================================
// MAIN DROP HANDLER
// Routes to appropriate drop system based on unit type
//===========================================================================
private function ItemDropSystem_ProcessDrop takes unit u, location loc returns nothing
    local boolean processed = false
    
    // Skip if unit can't drop (check player, locust, illusion, etc.)
    if not ItemDropCore_CanDrop(u) then
        return
    endif
    
    // Skip if summoned unit
    if IsUnitType(u, UNIT_TYPE_SUMMONED) then
        return
    endif
    
    // Priority 1: Check if boss
    if ItemDropSystem_IsBoss(u) then
        set processed = ItemDropBoss_Process(u, loc)
        if processed then
            set BOSS_DROPS = BOSS_DROPS + 1
            set TOTAL_DROPS = TOTAL_DROPS + 1
            return
        endif
    endif
    
    // Priority 2: Check for unit-specific drops
    set processed = ItemDropSpecific_Process(u, loc)
    if processed then
        set SPECIFIC_DROPS = SPECIFIC_DROPS + 1
        set TOTAL_DROPS = TOTAL_DROPS + 1
        // Note: Unit-specific drops don't prevent generic drops
        // They happen in addition to generic drops
    endif
    
    // Priority 3: Generic level-based drops (always happens unless boss)
    if not ItemDropSystem_IsBoss(u) then
        call ItemDropCore_ProcessGenericDrop(u, loc)
        set GENERIC_DROPS = GENERIC_DROPS + 1
        set TOTAL_DROPS = TOTAL_DROPS + 1
    endif
endfunction

//===========================================================================
// EVENT: Unit dies
//===========================================================================
private function ItemDropSystem_OnUnitDeath takes nothing returns nothing
    local unit u = GetDyingUnit()
    local location loc = GetUnitLoc(u)
    
    // Process drop
    call ItemDropSystem_ProcessDrop(u, loc)
    
    // Cleanup
    call RemoveLocation(loc)
    set loc = null
    set u = null
endfunction

//===========================================================================
// API: Get drop statistics (for debugging)
//===========================================================================
function ItemDropSystem_GetStats takes nothing returns string
    return "Total Drops: " + I2S(TOTAL_DROPS) + " | Boss: " + I2S(BOSS_DROPS) + " | Specific: " + I2S(SPECIFIC_DROPS) + " | Generic: " + I2S(GENERIC_DROPS)
endfunction

//===========================================================================
// API: Reset statistics
//===========================================================================
function ItemDropSystem_ResetStats takes nothing returns nothing
    set TOTAL_DROPS = 0
    set BOSS_DROPS = 0
    set SPECIFIC_DROPS = 0
    set GENERIC_DROPS = 0
endfunction

//===========================================================================
// INITIALIZATION
//===========================================================================
private function ItemDropSystem_Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    
    // Initialize configuration (load all item arrays)
    call ItemDropConfig_Init()
    
    // Register unit death event for all players
    call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_DEATH)
    call TriggerAddAction(t, function ItemDropSystem_OnUnitDeath)
    
    // Initialize destructible drop system
    call ItemDropDestructible_Init()
    
    set t = null
    
    // Debug message (optional - remove in production)
    call DisplayTimedTextToForce(GetPlayersAll(), 10.0, "|cff00ff00ItemDropSystem initialized successfully!|r")
endfunction

//===========================================================================
// Auto-initialize when library loads
//===========================================================================
private module ItemDropSystemAutoInit
    private static method onInit takes nothing returns nothing
        call TimerStart(CreateTimer(), 1.0, false, function ItemDropSystem_Init)
    endmethod
endmodule

private struct ItemDropSystemInitializer extends array
    implement ItemDropSystemAutoInit
endstruct

//===========================================================================
endlibrary
//===========================================================================
