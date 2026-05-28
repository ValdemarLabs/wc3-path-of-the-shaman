//===========================================================================
// ItemLootDestructibles.j
// Extension library for item drops from destructibles
// Provides level-based generic drops and specific container drops
//
// Dependencies: ItemLootSystem, DestructibleDeathEngine
//
// Usage:
//   1. Include ItemLootSystem first
//   2. Include this library
//   3. Include ItemLootDefinitionsDestructible.j (generated)
//   4. The system auto-initializes and hooks destructible death events
//
// Destructible Types:
//   - Level-based: Uses generic tier system (same as units)
//   - Specific: Container-specific drops (like chests/crates)
//
//===========================================================================

library ItemLootDestructibles initializer Init requires ItemLootSystem, DestructibleDeathEngine

    // =========================================================================
    // CONFIGURATION
    // =========================================================================
    
    globals
        // Configuration
        private constant boolean DEBUG_MODE = false    // Enable debug messages
        private constant real DROP_OFFSET = 80.0       // Item drop offset from destructible
        
        // Drop count range for destructibles (can be overridden per destructible)
        private constant integer DEFAULT_DROP_MIN = 1
        private constant integer DEFAULT_DROP_MAX = 1
    endglobals
    
    // =========================================================================
    // DATA STRUCTURES
    // =========================================================================
    
    globals
        // === DESTRUCTIBLE LEVEL LOOKUP ===
        // For generic drops: destructible type -> level
        private Table destructibleLevel           // destructible_type_id -> level (0 = no drops)
        
        // === SPECIFIC DROPS (Container Drops) ===
        private Table destHasSpecificDrops        // destructible_type_id -> 0/1
        private Table destSpecificFirst           // destructible_type_id -> first_entry_index
        private Table destSpecificCount           // destructible_type_id -> count
        private Table destSpecificNext            // entry_index -> next_entry_index
        private Table destSpecificItemType        // entry_index -> item_type_id
        private Table destSpecificDropChance      // entry_index -> drop_chance (0-10000)
        private Table destSpecificIsGuaranteed    // entry_index -> 0/1
        private Table destSpecificWeight          // entry_index -> weight
        private integer destSpecificEntryCount = 0
        
        // Initialization flag
        private boolean destInitialized = false
    endglobals
    
    // =========================================================================
    // HELPER: Boolean to Integer conversion for Table storage
    // =========================================================================
    
    private function B2I takes boolean b returns integer
        if b then
            return 1
        endif
        return 0
    endfunction
    
    // =========================================================================
    // REGISTRATION API
    // =========================================================================
    
    // Register a destructible's level for generic drops
    // destructibleTypeId: WC3 destructible type rawcode
    // level: Level for tier-based drops (0 = no generic drops)
    function RegisterDestructibleLevel takes integer destructibleTypeId, integer level returns nothing
        set destructibleLevel[destructibleTypeId] = level
        
        if DEBUG_MODE then
            call BJDebugMsg("Registered destructible " + I2S(destructibleTypeId) + " level: " + I2S(level))
        endif
    endfunction
    
    // Register a specific drop for a destructible (container drops)
    // destructibleTypeId: WC3 destructible type rawcode
    // itemTypeId: WC3 item type rawcode
    // dropChance: Drop chance (0-10000 = 0-100.00%)
    // isGuaranteed: If true, always drops
    // weight: Relative weight for weighted selection
    function RegisterDestructibleDrop takes integer destructibleTypeId, integer itemTypeId, integer dropChance, boolean isGuaranteed, integer weight returns nothing
        local integer entryIndex = destSpecificEntryCount
        local integer firstEntry
        
        // Store drop data
        set destSpecificItemType[entryIndex] = itemTypeId
        set destSpecificDropChance[entryIndex] = dropChance
        set destSpecificIsGuaranteed[entryIndex] = B2I(isGuaranteed)
        set destSpecificWeight[entryIndex] = weight
        
        // Mark destructible as having specific drops
        set destHasSpecificDrops[destructibleTypeId] = 1
        
        // Add to linked list for this destructible
        if destSpecificFirst.has(destructibleTypeId) then
            set firstEntry = destSpecificFirst[destructibleTypeId]
            set destSpecificNext[entryIndex] = firstEntry
        else
            set destSpecificNext[entryIndex] = -1
            set destSpecificCount[destructibleTypeId] = 0
        endif
        
        set destSpecificFirst[destructibleTypeId] = entryIndex
        set destSpecificCount[destructibleTypeId] = destSpecificCount[destructibleTypeId] + 1
        set destSpecificEntryCount = destSpecificEntryCount + 1
        
        if DEBUG_MODE then
            call BJDebugMsg("Registered destructible drop: dest " + I2S(destructibleTypeId) + " -> item " + I2S(itemTypeId))
        endif
    endfunction
    
    // =========================================================================
    // DROP LOGIC
    // =========================================================================
    
    // Get drop position with offset (returns via bj_ globals for simplicity)
    private function GetDropOffset takes real x, real y, integer index, boolean isX returns real
        local real angle = (index * 45.0) * bj_DEGTORAD  // 8 positions around center
        if isX then
            return x + DROP_OFFSET * Cos(angle)
        endif
        return y + DROP_OFFSET * Sin(angle)
    endfunction
    
    // Check if can drop at location (terrain walkable)
    private function CanDropAtLocation takes real x, real y returns boolean
        return IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) == false
    endfunction
    
    // Process specific drops for a destructible
    private function ProcessSpecificDrops takes integer destTypeId, real x, real y returns nothing
        local integer entryIndex
        local integer itemType
        local integer dropChance
        local integer roll
        local integer dropIndex = 0
        local real dropX
        local real dropY
        local item it
        
        // Check if destructible has specific drops
        if not destHasSpecificDrops.has(destTypeId) then
            return
        endif
        
        if destHasSpecificDrops[destTypeId] != 1 then
            return
        endif
        
        // Iterate through specific drops
        set entryIndex = destSpecificFirst[destTypeId]
        
        loop
            exitwhen entryIndex < 0
            
            set itemType = destSpecificItemType[entryIndex]
            set dropChance = destSpecificDropChance[entryIndex]
            
            // Check if guaranteed or roll for drop
            if destSpecificIsGuaranteed[entryIndex] == 1 then
                // Guaranteed drop
                set dropX = GetDropOffset(x, y, dropIndex, true)
                set dropY = GetDropOffset(x, y, dropIndex, false)
                
                if CanDropAtLocation(dropX, dropY) then
                    set it = CreateItem(itemType, dropX, dropY)
                    if DEBUG_MODE then
                        call BJDebugMsg("Dropped guaranteed item: " + I2S(itemType))
                    endif
                    set dropIndex = dropIndex + 1
                endif
            else
                // Random drop based on chance
                set roll = GetRandomInt(1, 10000)
                if roll <= dropChance then
                    set dropX = GetDropOffset(x, y, dropIndex, true)
                    set dropY = GetDropOffset(x, y, dropIndex, false)
                    
                    if CanDropAtLocation(dropX, dropY) then
                        set it = CreateItem(itemType, dropX, dropY)
                        if DEBUG_MODE then
                            call BJDebugMsg("Dropped random item: " + I2S(itemType) + " (rolled " + I2S(roll) + " <= " + I2S(dropChance) + ")")
                        endif
                        set dropIndex = dropIndex + 1
                    endif
                endif
            endif
            
            // Move to next entry
            set entryIndex = destSpecificNext[entryIndex]
        endloop
        
        set it = null
    endfunction
    
    // Process generic drops for a destructible based on level
    // This calls into ItemLootSystem's generic drop logic
    private function ProcessGenericDrops takes integer destTypeId, real x, real y returns nothing
        local integer level
        
        // Check if destructible has a level registered
        if not destructibleLevel.has(destTypeId) then
            return
        endif
        
        set level = destructibleLevel[destTypeId]
        if level <= 0 then
            return
        endif
        
        // Call ItemLootSystem's public generic drop function
        call RollGenericDrop(level, x, y)
        
        if DEBUG_MODE then
            call BJDebugMsg("Generic drop rolled for level " + I2S(level) + " destructible")
        endif
    endfunction
    
    // =========================================================================
    // EVENT HANDLER
    // =========================================================================
    
    // Called when a destructible dies (via DestructibleDeathEngine)
    // Mirrors the working GUI trigger pattern:
    //   Game - udg_DestructibleDeathEvent becomes Equal to 1.00
    private function OnDestructibleDeath takes nothing returns nothing
        local destructable d = udg_DestructibleDeathTarget
        local integer destTypeId
        local real x
        local real y
        
        if d == null then
            return
        endif
        
        set destTypeId = GetDestructableTypeId(d)
        set x = GetDestructableX(d)
        set y = GetDestructableY(d)
        
        // Process specific drops (containers)
        call ProcessSpecificDrops(destTypeId, x, y)
        
        // Process generic drops (level-based)
        call ProcessGenericDrops(destTypeId, x, y)
        
        set d = null
    endfunction
    
    // =========================================================================
    // INITIALIZATION
    // =========================================================================
    
    private function InitTables takes nothing returns nothing
        set destructibleLevel = Table.create()
        set destHasSpecificDrops = Table.create()
        set destSpecificFirst = Table.create()
        set destSpecificCount = Table.create()
        set destSpecificNext = Table.create()
        set destSpecificItemType = Table.create()
        set destSpecificDropChance = Table.create()
        set destSpecificIsGuaranteed = Table.create()
        set destSpecificWeight = Table.create()
    endfunction
    
    private function Init takes nothing returns nothing
        local trigger t
        
        if destInitialized then
            return
        endif
        
        // Initialize data structures
        call InitTables()
        
        // Register the same way as the known-good GUI trigger:
        //   Game - udg_DestructibleDeathEvent becomes Equal to 1.00
        set t = CreateTrigger()
        call TriggerRegisterVariableEvent(t, "udg_DestructibleDeathEvent", EQUAL, 1.00)
        call TriggerAddAction(t, function OnDestructibleDeath)
        
        set destInitialized = true
        
        if DEBUG_MODE then
            call BJDebugMsg("ItemLootDestructibles initialized")
        endif
    endfunction

endlibrary
