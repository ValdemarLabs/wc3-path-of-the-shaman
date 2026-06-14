//===========================================================================
// ItemLootSystem.j
// Main library for item drops from units
// Provides generic level-based drops and specific boss drops
//
// Dependencies: Table (TableV6), UnitDeathEvent
//
// Usage:
//   1. Include this library
//   2. Include ItemLootDefinitionsGeneric.j (generated)
//   3. Include ItemLootDefinitionsSpecific.j (generated)
//   4. The system auto-initializes and hooks unit death events
//
//===========================================================================

library ItemLootSystem initializer Init requires Table, UnitDeathEvent

    // =========================================================================
    // CONFIGURATION
    // =========================================================================
    
    globals
        // Rarity constants (must match database item_rarities.rarity_id values)
        // Named ITEM_RARITY_* to avoid conflict with Blizzard's RARITY_RARE
        constant integer ITEM_RARITY_COMMON    = 0
        constant integer ITEM_RARITY_UNCOMMON  = 1
        constant integer ITEM_RARITY_RARE      = 2
        constant integer ITEM_RARITY_EPIC      = 3
        constant integer ITEM_RARITY_LEGENDARY = 4
        constant integer ITEM_RARITY_ARTIFACT  = 5
        
        // Configuration
        private constant boolean DEBUG_MODE = false    // Enable debug messages
        private constant real DROP_OFFSET = 120.0      // Item drop offset from unit (increased to spread items)
        
        // Floating text configuration
        private constant real FLOAT_TEXT_DURATION = 30.0    // How long text stays visible (seconds)
        private constant real FLOAT_TEXT_SIZE = 4.7         // Text size (10.0 is default)
        private constant real FLOAT_TEXT_HEIGHT = 90.0      // Height above item
        private constant real FLOAT_TEXT_FADE_START = 25.0  // When to start fading (seconds before end)
        private constant real FLOAT_TEXT_CHAR_WIDTH = 5.0   // World units per character for centering (tune this value)    
            // Increase (e.g. 8.0, 9.0) → Text shifts more left → Use if text appears shifted right of item
            // Decrease (e.g. 5.0, 6.0) → Text shifts less left → Use if text appears shifted left of item
        
        // Hover animation config
        private constant real FLOAT_HOVER_AMPLITUDE = 15.0      // How far up/down to hover (units)
        private constant real FLOAT_HOVER_SPEED = 0.50          // Oscillation speed (cycles per second)
        private constant real FLOAT_HOVER_INTERVAL = 0.05       // Update interval (seconds)
    endglobals
    
    // =========================================================================
    // DATA STRUCTURES
    // =========================================================================
    
    globals
        // === TIER SYSTEM (Generic Drops) ===
        private Table tierMinLevel            // tier_id -> min_unit_level
        private Table tierMaxLevel            // tier_id -> max_unit_level  
        private Table tierDropChance          // tier_id -> base_drop_chance (0-10000)
        private integer tierCount = 0
        
        // Rarity item levels per tier: tierRarityItemLevel[tier_id * 10 + rarity_id] = item_level
        private Table tierRarityItemLevel     // tier_rarity_key -> item_level for that rarity
        private Table tierRarityWeight        // tier_rarity_key -> weight for rarity roll
        
        // Item lookup by (item_level, rarity) -> item pool (linked list)
        private Table itemPoolFirst           // (item_level * 100 + rarity_id) -> first_entry_index
        private Table itemPoolCount           // (item_level * 100 + rarity_id) -> count in pool
        private Table itemPoolNext            // entry_index -> next_entry_index (-1 if end)
        private Table itemPoolItemType        // entry_index -> item_type_id
        private Table itemPoolWeight          // entry_index -> weight
        private integer itemPoolEntryCount = 0
        
        // Unique item tracking (items that can only drop once per game)
        // Stored as integers: 0 = false, 1 = true (Table requires integer values)
        private Table uniqueItemDropped       // item_type_id -> 0/1 (has dropped this game)
        private Table itemIsUnique            // item_type_id -> 0/1 (from database)
        
        // === SPECIFIC DROPS (Boss/Unique) ===
        private Table unitHasSpecificDrops    // unit_type_id -> 0/1
        private Table unitSpecificFirst       // unit_type_id -> first_entry_index
        private Table unitSpecificCount       // unit_type_id -> count
        private Table specificNext            // entry_index -> next_entry_index
        private Table specificItemType        // entry_index -> item_type_id
        private Table specificDropChance      // entry_index -> drop_chance (0-10000)
        private Table specificIsGuaranteed    // entry_index -> 0/1
        private Table specificWeight          // entry_index -> weight
        private integer specificEntryCount = 0
        
        // Initialization flag
        private boolean initialized = false
        
        // === DROP QUEUE (prevents rapid CreateItem failures) ===
        private constant integer DROP_QUEUE_MAX = 64
        private integer array dropQueueItemType
        private real array dropQueueX
        private real array dropQueueY
        private integer dropQueueHead = 0
        private integer dropQueueTail = 0
        private timer dropQueueTimer = null
        private constant real DROP_QUEUE_INTERVAL = 0.25  // 250ms between drops (for stability)
        
        // For item verification
        private item array lastCreatedItems
        private integer lastCreatedCount = 0
        
        // Sequential drop positioning (spreads items in circle)
        private integer dropPositionIndex = 0
        
        // === FLOATING TEXT SYSTEM ===
        // Rarity lookup for items (set during RegisterItemToPool)
        private Table itemRarity              // item_type_id -> rarity_id
        
        // Queue rarity tracking (parallel to dropQueue arrays)
        private integer array dropQueueRarity
        
        // Floating text enabled per rarity (0 = disabled, 1 = enabled)
        // Configure in InitFloatingTextConfig()
        private integer array floatTextEnabled
        
        // Rarity colors (RGB 0-255)
        private integer array rarityColorR
        private integer array rarityColorG
        private integer array rarityColorB
        
        // === HOVER ANIMATION SYSTEM ===
        private constant integer HOVER_MAX = 32           // Max concurrent hovering texts
        private texttag array hoverTextTag                // The texttag handle
        private item array hoverItem                      // Associated item (for pickup detection)
        private real array hoverBaseX                     // X position
        private real array hoverBaseY                     // Y position
        private real array hoverBaseZ                     // Base Z height
        private real array hoverPhase                     // Current phase in oscillation
        private real array hoverExpireTime                // When this text expires
        private integer hoverCount = 0                    // Current number of hovering texts
        private timer hoverTimer = null                   // Animation timer
        
        // Item handle to hover index lookup
        private Table itemToHoverIndex                    // item_handle_id -> hover_array_index + 1 (0 = not tracked)
        
        // === DELAYED DROP TEXT (for OnItemDrop) ===
        private item pendingDropItem = null               // Item waiting for position finalization
        private integer pendingDropRarity = 0             // Rarity of pending item
        private timer pendingDropTimer = null             // Timer for delayed text creation
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
    // FLOATING TEXT CONFIGURATION
    // Customize colors and which rarities show floating text
    // =========================================================================
    
    private function InitFloatingTextConfig takes nothing returns nothing
        // Enable floating text per rarity (1 = enabled, 0 = disabled)
        // By default: Common disabled, all others enabled
        set floatTextEnabled[ITEM_RARITY_COMMON]    = 0  // Common - no floating text
        set floatTextEnabled[ITEM_RARITY_UNCOMMON]  = 1  // Uncommon - enabled
        set floatTextEnabled[ITEM_RARITY_RARE]      = 1  // Rare - enabled
        set floatTextEnabled[ITEM_RARITY_EPIC]      = 1  // Epic - enabled
        set floatTextEnabled[ITEM_RARITY_LEGENDARY] = 1  // Legendary - enabled
        set floatTextEnabled[ITEM_RARITY_ARTIFACT]  = 1  // Artifact - enabled
        
        // Rarity colors (RGB 0-255)
        // Common: White
        set rarityColorR[ITEM_RARITY_COMMON] = 255
        set rarityColorG[ITEM_RARITY_COMMON] = 255
        set rarityColorB[ITEM_RARITY_COMMON] = 255
        
        // Uncommon: Green
        set rarityColorR[ITEM_RARITY_UNCOMMON] = 30
        set rarityColorG[ITEM_RARITY_UNCOMMON] = 255
        set rarityColorB[ITEM_RARITY_UNCOMMON] = 0
        
        // Rare: Blue
        set rarityColorR[ITEM_RARITY_RARE] = 0
        set rarityColorG[ITEM_RARITY_RARE] = 112
        set rarityColorB[ITEM_RARITY_RARE] = 255
        
        // Epic: Purple
        set rarityColorR[ITEM_RARITY_EPIC] = 163
        set rarityColorG[ITEM_RARITY_EPIC] = 53
        set rarityColorB[ITEM_RARITY_EPIC] = 238
        
        // Legendary: Orange
        set rarityColorR[ITEM_RARITY_LEGENDARY] = 255
        set rarityColorG[ITEM_RARITY_LEGENDARY] = 128
        set rarityColorB[ITEM_RARITY_LEGENDARY] = 0
        
        // Artifact: Red/Gold
        set rarityColorR[ITEM_RARITY_ARTIFACT] = 255
        set rarityColorG[ITEM_RARITY_ARTIFACT] = 50
        set rarityColorB[ITEM_RARITY_ARTIFACT] = 50
    endfunction
    
    // =========================================================================
    // HOVER ANIMATION SYSTEM
    // =========================================================================
    
    // Remove expired texttags and compact array
    private function CleanupExpiredHoverTexts takes nothing returns nothing
        local integer i = 0
        local integer writeIndex = 0
        local integer itemHandleId
        
        loop
            exitwhen i >= hoverCount
            // Check if texttag is still valid (it auto-destroys after lifespan)
            if hoverExpireTime[i] > 0 then
                // Still valid, keep it
                if writeIndex != i then
                    // Update item lookup table if item exists
                    if hoverItem[i] != null then
                        set itemHandleId = GetHandleId(hoverItem[i])
                        set itemToHoverIndex[itemHandleId] = writeIndex + 1
                    endif
                    
                    set hoverTextTag[writeIndex] = hoverTextTag[i]
                    set hoverItem[writeIndex] = hoverItem[i]
                    set hoverBaseX[writeIndex] = hoverBaseX[i]
                    set hoverBaseY[writeIndex] = hoverBaseY[i]
                    set hoverBaseZ[writeIndex] = hoverBaseZ[i]
                    set hoverPhase[writeIndex] = hoverPhase[i]
                    set hoverExpireTime[writeIndex] = hoverExpireTime[i]
                endif
                set writeIndex = writeIndex + 1
            else
                // Expired - remove from item lookup
                if hoverItem[i] != null then
                    set itemHandleId = GetHandleId(hoverItem[i])
                    call itemToHoverIndex.remove(itemHandleId)
                    set hoverItem[i] = null
                endif
            endif
            set i = i + 1
        endloop
        
        set hoverCount = writeIndex
        
        // Stop timer if no more texts
        if hoverCount == 0 then
            call PauseTimer(hoverTimer)
        endif
    endfunction
    
    // Timer callback to animate hovering texts
    private function UpdateHoverAnimation takes nothing returns nothing
        local integer i = 0
        local real phase
        local real zOffset
        
        loop
            exitwhen i >= hoverCount
            
            // Decrement expire time
            set hoverExpireTime[i] = hoverExpireTime[i] - FLOAT_HOVER_INTERVAL
            
            if hoverItem[i] != null and GetItemTypeId(hoverItem[i]) == 0 then
                call DestroyTextTag(hoverTextTag[i])
                set hoverTextTag[i] = null
                set hoverItem[i] = null
                set hoverExpireTime[i] = 0
            elseif hoverExpireTime[i] > 0 then
                // Update phase
                set hoverPhase[i] = hoverPhase[i] + (FLOAT_HOVER_SPEED * 2.0 * 3.14159 * FLOAT_HOVER_INTERVAL)
                
                // Calculate vertical offset using sine wave
                set zOffset = FLOAT_HOVER_AMPLITUDE * Sin(hoverPhase[i])
                
                // Update texttag position
                call SetTextTagPos(hoverTextTag[i], hoverBaseX[i], hoverBaseY[i], hoverBaseZ[i] + zOffset)
            endif
            
            set i = i + 1
        endloop
        
        // Periodically clean up expired texts
        if hoverCount > 0 then
            call CleanupExpiredHoverTexts()
        endif
    endfunction
    
    // Register a texttag for hover animation
    private function RegisterHoverText takes texttag tt, item it, real x, real y, real z returns nothing
        local integer itemHandleId
        
        if hoverCount >= HOVER_MAX then
            // Array full, oldest will naturally expire
            return
        endif
        
        set hoverTextTag[hoverCount] = tt
        set hoverItem[hoverCount] = it
        set hoverBaseX[hoverCount] = x
        set hoverBaseY[hoverCount] = y
        set hoverBaseZ[hoverCount] = z
        set hoverPhase[hoverCount] = 0.0
        set hoverExpireTime[hoverCount] = FLOAT_TEXT_DURATION
        
        // Track item -> index mapping for pickup detection
        if it != null then
            set itemHandleId = GetHandleId(it)
            set itemToHoverIndex[itemHandleId] = hoverCount + 1  // +1 so 0 means "not found"
        endif
        
        set hoverCount = hoverCount + 1
        
        // Start timer if not running
        call TimerStart(hoverTimer, FLOAT_HOVER_INTERVAL, true, function UpdateHoverAnimation)
    endfunction
    
    // Remove floating text for a specific item (called on pickup)
    private function RemoveItemFloatingText takes item it returns nothing
        local integer itemHandleId = GetHandleId(it)
        local integer hoverIndex
        
        if not itemToHoverIndex.has(itemHandleId) then
            return
        endif
        
        set hoverIndex = itemToHoverIndex[itemHandleId] - 1  // -1 because we stored index+1
        
        if hoverIndex >= 0 and hoverIndex < hoverCount then
            // Destroy the texttag immediately
            call DestroyTextTag(hoverTextTag[hoverIndex])
            set hoverTextTag[hoverIndex] = null
            set hoverItem[hoverIndex] = null
            set hoverExpireTime[hoverIndex] = 0  // Mark for cleanup
        endif
        
        // Remove from lookup
        call itemToHoverIndex.remove(itemHandleId)
    endfunction
    
    // Item pickup/use handler - removes floating text
    private function OnItemPickup takes nothing returns nothing
        local item it = GetManipulatedItem()
        
        if it != null then
            call RemoveItemFloatingText(it)
        endif
        
        set it = null
    endfunction

    private function OnItemUse takes nothing returns nothing
        local item it = GetManipulatedItem()
        
        if it != null then
            call RemoveItemFloatingText(it)
        endif
        
        set it = null
    endfunction
    
    // Create floating text above an item with rarity-based color (internal)
    private function CreateItemFloatingTextInternal takes item it, string itemName, real x, real y, integer rarityId returns nothing
        local texttag tt
        local real textWidth
        local real centeredX
        
        // Check if floating text is enabled for this rarity
        if floatTextEnabled[rarityId] == 0 then
            return
        endif
        
        // Estimate text width for centering (linear: chars * width per char)
        set textWidth = I2R(StringLength(itemName)) * FLOAT_TEXT_CHAR_WIDTH
        set centeredX = x - (textWidth / 2.0)
        
        set tt = CreateTextTag()
        call SetTextTagText(tt, itemName, FLOAT_TEXT_SIZE * 0.023 / 10.0)
        call SetTextTagPos(tt, centeredX, y, FLOAT_TEXT_HEIGHT)
        call SetTextTagColor(tt, rarityColorR[rarityId], rarityColorG[rarityId], rarityColorB[rarityId], 255)
        call SetTextTagPermanent(tt, false)
        call SetTextTagLifespan(tt, FLOAT_TEXT_DURATION)
        call SetTextTagFadepoint(tt, FLOAT_TEXT_FADE_START)
        call SetTextTagVelocity(tt, 0.0, 0.0)
        call SetTextTagVisibility(tt, true)
        
        // Register for hover animation with item tracking
        call RegisterHoverText(tt, it, centeredX, y, FLOAT_TEXT_HEIGHT)
    endfunction
    
    // Timer callback for delayed floating text creation (item position finalized)
    private function OnItemDropDelayed takes nothing returns nothing
        local item it = pendingDropItem
        local integer rarityId = pendingDropRarity
        
        if it != null then
            // Now item position is finalized - use actual item coordinates
            call CreateItemFloatingTextInternal(it, GetItemName(it), GetItemX(it), GetItemY(it), rarityId)
        endif
        
        set pendingDropItem = null
    endfunction
    
    // Item drop handler - creates floating text when unit drops item
    private function OnItemDrop takes nothing returns nothing
        local item it = GetManipulatedItem()
        local integer itemTypeId
        local integer rarityId
        
        if it == null then
            return
        endif
        
        set itemTypeId = GetItemTypeId(it)
        
        // Look up rarity from registered items, default to Common
        if itemRarity.has(itemTypeId) then
            set rarityId = itemRarity[itemTypeId]
        else
            set rarityId = ITEM_RARITY_COMMON
        endif
        
        // Store pending item data and use 0.0 delay to let engine finalize item position
        set pendingDropItem = it
        set pendingDropRarity = rarityId
        call TimerStart(pendingDropTimer, 0.0, false, function OnItemDropDelayed)
        
        set it = null
    endfunction
    
    // =========================================================================
    // PUBLIC API - For external systems to create floating text
    // =========================================================================
    
    // Create floating text for any item (called by external systems)
    // rarityId: Use ITEM_RARITY_* constants, or -1 for white text
    function ItemLoot_CreateFloatingText takes item it, integer rarityId returns nothing
        local integer itemTypeId
        local real x
        local real y
        local integer actualRarity
        
        if it == null then
            return
        endif
        
        set itemTypeId = GetItemTypeId(it)
        set x = GetItemX(it)
        set y = GetItemY(it)
        
        // If rarityId is -1, try to look up from registered items, default to Common
        if rarityId < 0 then
            if itemRarity.has(itemTypeId) then
                set actualRarity = itemRarity[itemTypeId]
            else
                set actualRarity = ITEM_RARITY_COMMON
            endif
        else
            set actualRarity = rarityId
        endif
        
        call CreateItemFloatingTextInternal(it, GetItemName(it), x, y, actualRarity)
    endfunction
    
    // Create floating text with custom name and color (for special items)
    function ItemLoot_CreateFloatingTextCustom takes item it, string customName, integer r, integer g, integer b returns nothing
        local texttag tt
        local real textWidth
        local real centeredX
        local real x
        local real y
        
        if it == null then
            return
        endif
        
        set x = GetItemX(it)
        set y = GetItemY(it)
        
        set textWidth = I2R(StringLength(customName)) * FLOAT_TEXT_CHAR_WIDTH
        set centeredX = x - (textWidth / 2.0)
        
        set tt = CreateTextTag()
        call SetTextTagText(tt, customName, FLOAT_TEXT_SIZE * 0.023 / 10.0)
        call SetTextTagPos(tt, centeredX, y, FLOAT_TEXT_HEIGHT)
        call SetTextTagColor(tt, r, g, b, 255)
        call SetTextTagPermanent(tt, false)
        call SetTextTagLifespan(tt, FLOAT_TEXT_DURATION)
        call SetTextTagFadepoint(tt, FLOAT_TEXT_FADE_START)
        call SetTextTagVelocity(tt, 0.0, 0.0)
        call SetTextTagVisibility(tt, true)
        
        call RegisterHoverText(tt, it, centeredX, y, FLOAT_TEXT_HEIGHT)
    endfunction
    
    // Verify items still exist (debug helper)
    private function VerifyItems takes nothing returns nothing
        local integer i = 0
        local item it
        local timer t = GetExpiredTimer()
        
        loop
            exitwhen i >= lastCreatedCount
            set it = lastCreatedItems[i]
            if it != null then
                if GetItemTypeId(it) == 0 then
                    call BJDebugMsg("[VERIFY] Item " + I2S(i) + " was DESTROYED!")
                else
                    call BJDebugMsg("[VERIFY] Item " + I2S(i) + ": " + GetItemName(it) + " exists at " + I2S(R2I(GetItemX(it))) + "," + I2S(R2I(GetItemY(it))))
                endif
            else
                call BJDebugMsg("[VERIFY] Item " + I2S(i) + " handle is null!")
            endif
            set lastCreatedItems[i] = null
            set i = i + 1
        endloop
        set lastCreatedCount = 0
        
        call DestroyTimer(t)
        set t = null
    endfunction
    
    // =========================================================================
    // DROP QUEUE SYSTEM (prevents rapid CreateItem failures)
    // WC3 engine can fail to create items when called too rapidly
    // =========================================================================

    private function TryCreateQueuedItem takes integer itemTypeId, real x, real y, real offsetX, real offsetY returns item
        local item it = null

        // Preferred spread position
        set it = CreateItem(itemTypeId, x + offsetX, y + offsetY)
        if it != null then
            return it
        endif

        // Center fallback - mirrors classic destructible-drop behavior
        set it = CreateItem(itemTypeId, x, y)
        if it != null then
            return it
        endif

        // Nearby fallback positions for blocked/pathing-heavy doodad areas
        set it = CreateItem(itemTypeId, x + 64.0, y)
        if it != null then
            return it
        endif

        set it = CreateItem(itemTypeId, x - 64.0, y)
        if it != null then
            return it
        endif

        set it = CreateItem(itemTypeId, x, y + 64.0)
        if it != null then
            return it
        endif

        set it = CreateItem(itemTypeId, x, y - 64.0)
        return it
    endfunction
    
    private function ProcessDropQueue takes nothing returns nothing
        local integer itemTypeId
        local real x
        local real y
        local integer rarityId
        local item droppedItem
        local real actualX
        local real actualY
        local integer charges
        local real angle
        local real offsetX
        local real offsetY
        
        // Check if queue is empty
        if dropQueueHead == dropQueueTail then
            call PauseTimer(dropQueueTimer)
            return
        endif
        
        // Get next item from queue
        set itemTypeId = dropQueueItemType[dropQueueHead]
        set x = dropQueueX[dropQueueHead]
        set y = dropQueueY[dropQueueHead]
        set rarityId = dropQueueRarity[dropQueueHead]
        
        // Advance head (circular buffer)
        set dropQueueHead = dropQueueHead + 1
        if dropQueueHead >= DROP_QUEUE_MAX then
            set dropQueueHead = 0
        endif
        
        // Calculate position in a circle (spread items evenly)
        set angle = dropPositionIndex * 1.2566  // ~72 degrees per item (5 items per circle)
        set offsetX = DROP_OFFSET * Cos(angle)
        set offsetY = DROP_OFFSET * Sin(angle)
        set dropPositionIndex = dropPositionIndex + 1
        if dropPositionIndex >= 8 then
            set dropPositionIndex = 0
        endif
        
        // Create the item directly at final position
        set actualX = x + offsetX
        set actualY = y + offsetY
        set droppedItem = TryCreateQueuedItem(itemTypeId, x, y, offsetX, offsetY)
        
        if droppedItem != null then
            set actualX = GetItemX(droppedItem)
            set actualY = GetItemY(droppedItem)

            // Ensure item has charges (some items need this to be visible)
            set charges = GetItemCharges(droppedItem)
            if charges == 0 then
                call SetItemCharges(droppedItem, 1)
            endif
            
            // Force visibility
            call SetItemVisible(droppedItem, true)
            
            // Create floating text above the item
            call CreateItemFloatingTextInternal(droppedItem, GetItemName(droppedItem), actualX, actualY, rarityId)
            
            // Mark unique as dropped
            if itemIsUnique[itemTypeId] != 0 then
                set uniqueItemDropped[itemTypeId] = 1
            endif
            
            if DEBUG_MODE then
                call BJDebugMsg("[Drop] " + GetItemName(droppedItem) + " @ " + I2S(R2I(actualX)) + "," + I2S(R2I(actualY)))
                
                // Store for verification
                set lastCreatedItems[lastCreatedCount] = droppedItem
                set lastCreatedCount = lastCreatedCount + 1
            endif
        else
            if DEBUG_MODE then
                call BJDebugMsg("[Drop] FAILED: " + I2S(itemTypeId))
            endif
        endif
        
        set droppedItem = null
        
        // If queue is now empty, pause timer and verify items
        if dropQueueHead == dropQueueTail then
            call PauseTimer(dropQueueTimer)
            if DEBUG_MODE and lastCreatedCount > 0 then
                // Verify items still exist after a delay
                call TimerStart(CreateTimer(), 1.0, false, function VerifyItems)
            endif
        endif
    endfunction
    
    private function QueueDrop takes integer itemTypeId, real x, real y, integer rarityId returns nothing
        local integer nextTail
        
        // Calculate next tail position (circular buffer)
        set nextTail = dropQueueTail + 1
        if nextTail >= DROP_QUEUE_MAX then
            set nextTail = 0
        endif
        
        // Check if queue is full
        if nextTail == dropQueueHead then
            if DEBUG_MODE then
                call BJDebugMsg("[DropQueue] WARNING: Queue full, dropping item " + I2S(itemTypeId))
            endif
            return
        endif
        
        // Add to queue
        set dropQueueItemType[dropQueueTail] = itemTypeId
        set dropQueueX[dropQueueTail] = x
        set dropQueueY[dropQueueTail] = y
        set dropQueueRarity[dropQueueTail] = rarityId
        set dropQueueTail = nextTail
        
        if DEBUG_MODE then
            call BJDebugMsg("[DropQueue] Queued item " + I2S(itemTypeId) + " at (" + R2S(x) + ", " + R2S(y) + ")")
        endif
        
        // Start timer if not already running
        call TimerStart(dropQueueTimer, DROP_QUEUE_INTERVAL, true, function ProcessDropQueue)
    endfunction
    
    // =========================================================================
    // REGISTRATION API (Called by generated libraries)
    // =========================================================================
    
    // Register a loot tier
    // tierId: Unique tier identifier (1-based)
    // minLevel/maxLevel: Unit level range for this tier
    // dropChance: Base drop chance (0-10000 = 0-100.00%)
    function RegisterLootTier takes integer tierId, integer minLevel, integer maxLevel, integer dropChance returns nothing
        set tierMinLevel[tierId] = minLevel
        set tierMaxLevel[tierId] = maxLevel
        set tierDropChance[tierId] = dropChance
        
        if tierId > tierCount then
            set tierCount = tierId
        endif
        
        if DEBUG_MODE then
            call BJDebugMsg("Registered tier " + I2S(tierId) + ": levels " + I2S(minLevel) + "-" + I2S(maxLevel))
        endif
    endfunction
    
    // Register a rarity configuration for a tier
    // tierId: Tier to configure
    // rarityId: Rarity constant (ITEM_RARITY_COMMON, etc.)
    // itemLevel: Item level that drops at this rarity in this tier
    // weight: Relative weight for rarity roll
    function RegisterTierRarity takes integer tierId, integer rarityId, integer itemLevel, integer weight returns nothing
        local integer key = tierId * 10 + rarityId
        
        set tierRarityItemLevel[key] = itemLevel
        set tierRarityWeight[key] = weight
        
        if DEBUG_MODE then
            call BJDebugMsg("Tier " + I2S(tierId) + " rarity " + I2S(rarityId) + ": iLvl " + I2S(itemLevel) + " weight " + I2S(weight))
        endif
    endfunction
    
    // Register an item to a drop pool
    // itemTypeId: WC3 item type rawcode
    // itemLevel: Item's level for pool matching
    // rarityId: Item's rarity
    // weight: Relative weight in pool
    // isUnique: If true, can only drop once per game
    function RegisterItemToPool takes integer itemTypeId, integer itemLevel, integer rarityId, integer weight, boolean isUnique returns nothing
        local integer poolKey = itemLevel * 100 + rarityId
        local integer entryIndex = itemPoolEntryCount
        local integer firstEntry
        
        // Store item data
        set itemPoolItemType[entryIndex] = itemTypeId
        set itemPoolWeight[entryIndex] = weight
        set itemIsUnique[itemTypeId] = B2I(isUnique)
        set itemRarity[itemTypeId] = rarityId  // Store rarity for floating text
        
        // Add to linked list
        if itemPoolFirst.has(poolKey) then
            // Insert at beginning of list
            set firstEntry = itemPoolFirst[poolKey]
            set itemPoolNext[entryIndex] = firstEntry
        else
            // First entry in this pool
            set itemPoolNext[entryIndex] = -1
            set itemPoolCount[poolKey] = 0
        endif
        
        set itemPoolFirst[poolKey] = entryIndex
        set itemPoolCount[poolKey] = itemPoolCount[poolKey] + 1
        set itemPoolEntryCount = itemPoolEntryCount + 1
        
        if DEBUG_MODE then
            call BJDebugMsg("Registered item " + I2S(itemTypeId) + " to pool (lvl=" + I2S(itemLevel) + ", rarity=" + I2S(rarityId) + ")")
        endif
    endfunction
    
    // Register a specific drop for a unit (boss drops)
    // unitTypeId: WC3 unit type rawcode
    // itemTypeId: WC3 item type rawcode
    // dropChance: Drop chance (0-10000 = 0-100.00%)
    // isGuaranteed: If true, always drops
    // weight: Relative weight for weighted selection
    function RegisterSpecificDrop takes integer unitTypeId, integer itemTypeId, integer dropChance, boolean isGuaranteed, integer weight returns nothing
        local integer entryIndex = specificEntryCount
        local integer firstEntry
        
        // Store drop data
        set specificItemType[entryIndex] = itemTypeId
        set specificDropChance[entryIndex] = dropChance
        set specificIsGuaranteed[entryIndex] = B2I(isGuaranteed)
        set specificWeight[entryIndex] = weight
        
        // Mark unit as having specific drops
        set unitHasSpecificDrops[unitTypeId] = 1
        
        // Add to linked list for this unit
        if unitSpecificFirst.has(unitTypeId) then
            set firstEntry = unitSpecificFirst[unitTypeId]
            set specificNext[entryIndex] = firstEntry
        else
            set specificNext[entryIndex] = -1
            set unitSpecificCount[unitTypeId] = 0
        endif
        
        set unitSpecificFirst[unitTypeId] = entryIndex
        set unitSpecificCount[unitTypeId] = unitSpecificCount[unitTypeId] + 1
        set specificEntryCount = specificEntryCount + 1
        
        if DEBUG_MODE then
            call BJDebugMsg("Registered specific drop: unit " + I2S(unitTypeId) + " -> item " + I2S(itemTypeId))
        endif
    endfunction
    
    // =========================================================================
    // CORE LOGIC
    // =========================================================================
    
    // Get tier for a unit level
    private function GetTierForUnitLevel takes integer unitLevel returns integer
        local integer i = 1
        
        loop
            exitwhen i > tierCount
            if unitLevel >= tierMinLevel[i] and unitLevel <= tierMaxLevel[i] then
                return i
            endif
            set i = i + 1
        endloop
        
        // Default to last tier if level exceeds all
        return tierCount
    endfunction
    
    // Roll rarity based on tier weights
    private function RollRarityForTier takes integer tierId returns integer
        local integer totalWeight = 0
        local integer roll
        local integer cumulative = 0
        local integer r = ITEM_RARITY_COMMON
        local integer key
        
        // Sum weights for available rarities in this tier
        loop
            exitwhen r > ITEM_RARITY_ARTIFACT
            set key = tierId * 10 + r
            set totalWeight = totalWeight + tierRarityWeight[key]
            set r = r + 1
        endloop
        
        if totalWeight == 0 then
            return -1 // No drops available
        endif
        
        set roll = GetRandomInt(1, totalWeight)
        set r = ITEM_RARITY_COMMON
        loop
            exitwhen r > ITEM_RARITY_ARTIFACT
            set key = tierId * 10 + r
            set cumulative = cumulative + tierRarityWeight[key]
            if roll <= cumulative then
                return r
            endif
            set r = r + 1
        endloop
        
        return ITEM_RARITY_COMMON
    endfunction
    
    // Get a random item from a pool (item_level + rarity)
    private function GetRandomItemFromPool takes integer itemLevel, integer rarityId returns integer
        local integer poolKey = itemLevel * 100 + rarityId
        local integer count
        local integer totalWeight = 0
        local integer roll
        local integer cumulative = 0
        local integer entryIndex
        local integer itemTypeId
        
        if not itemPoolFirst.has(poolKey) then
            return 0 // No items in pool
        endif
        
        // Calculate total weight
        set entryIndex = itemPoolFirst[poolKey]
        loop
            exitwhen entryIndex < 0
            set totalWeight = totalWeight + itemPoolWeight[entryIndex]
            set entryIndex = itemPoolNext[entryIndex]
        endloop
        
        if totalWeight == 0 then
            return 0
        endif
        
        // Weighted random selection
        set roll = GetRandomInt(1, totalWeight)
        set entryIndex = itemPoolFirst[poolKey]
        loop
            exitwhen entryIndex < 0
            set cumulative = cumulative + itemPoolWeight[entryIndex]
            if roll <= cumulative then
                set itemTypeId = itemPoolItemType[entryIndex]
                
                // Check unique item restriction (stored as 0/1 integer)
                if itemIsUnique[itemTypeId] != 0 and uniqueItemDropped[itemTypeId] != 0 then
                    // Skip this item, try next
                    set entryIndex = itemPoolNext[entryIndex]
                else
                    return itemTypeId
                endif
            else
                set entryIndex = itemPoolNext[entryIndex]
            endif
        endloop
        
        return 0
    endfunction
    
    // Process generic drop based on level (used by units and destructibles)
    // level: Unit or destructible level to determine tier
    // x, y: Drop position
    function RollGenericDrop takes integer level, real x, real y returns nothing
        local integer tierId = GetTierForUnitLevel(level)
        local integer dropChance
        local integer rarity
        local integer itemLevel
        local integer itemTypeId
        
        if tierId <= 0 then
            return
        endif
        
        set dropChance = tierDropChance[tierId]
        
        // Roll drop chance first
        if GetRandomInt(0, 10000) > dropChance then
            return
        endif
        
        // Step 1: Roll rarity
        set rarity = RollRarityForTier(tierId)
        if rarity < 0 then
            return // No rarities available for this tier
        endif
        
        // Step 2: Get item level for this tier+rarity combo
        set itemLevel = tierRarityItemLevel[tierId * 10 + rarity]
        if itemLevel == 0 then
            return
        endif
        
        // Step 3: Get random item from pool
        set itemTypeId = GetRandomItemFromPool(itemLevel, rarity)
        if itemTypeId == 0 then
            return
        endif
        
        // Step 4: Check unique item restriction (stored as 0/1 integer)
        if itemIsUnique[itemTypeId] != 0 and uniqueItemDropped[itemTypeId] != 0 then
            return
        endif
        
        // Step 5: Queue item for creation (prevents rapid CreateItem failures)
        // Pre-mark unique as dropped to prevent duplicates in queue
        if itemIsUnique[itemTypeId] != 0 then
            set uniqueItemDropped[itemTypeId] = 1
        endif
        
        // Pass raw coordinates - ProcessDropQueue handles circular positioning
        call QueueDrop(itemTypeId, x, y, rarity)
        
        if DEBUG_MODE then
            call BJDebugMsg("Queued generic drop (tier " + I2S(tierId) + ", rarity " + I2S(rarity) + ")")
        endif
    endfunction
    
    // Process specific drops for a unit
    private function RollSpecificDrops takes integer unitTypeId, real x, real y returns nothing
        local integer entryIndex
        local integer itemTypeId
        local integer dropChance
        local boolean isGuaranteed
        
        if unitHasSpecificDrops[unitTypeId] == 0 then
            return
        endif
        
        set entryIndex = unitSpecificFirst[unitTypeId]
        
        loop
            exitwhen entryIndex < 0
            
            set itemTypeId = specificItemType[entryIndex]
            set dropChance = specificDropChance[entryIndex]
            set isGuaranteed = specificIsGuaranteed[entryIndex] != 0
            
            if DEBUG_MODE then
                call BJDebugMsg("[SpecDrop] Entry=" + I2S(entryIndex) + " ItemId=" + I2S(itemTypeId) + " Chance=" + I2S(dropChance))
            endif
            
            // Check unique restriction (stored as 0/1 integer)
            if not (itemIsUnique[itemTypeId] != 0 and uniqueItemDropped[itemTypeId] != 0) then
                // Roll drop
                if isGuaranteed or GetRandomInt(0, 10000) <= dropChance then
                    // Pre-mark unique as dropped to prevent duplicates in queue
                    if itemIsUnique[itemTypeId] != 0 then
                        set uniqueItemDropped[itemTypeId] = 1
                    endif
                    
                    // Pass raw coordinates - ProcessDropQueue handles circular positioning
                    // Look up rarity from item registry for floating text
                    call QueueDrop(itemTypeId, x, y, itemRarity[itemTypeId])
                    
                    if DEBUG_MODE then
                        call BJDebugMsg("[SpecDrop] QUEUED: " + I2S(itemTypeId))
                    endif
                else
                    if DEBUG_MODE then
                        call BJDebugMsg("[SpecDrop] Roll FAILED for " + I2S(itemTypeId))
                    endif
                endif
            else
                if DEBUG_MODE then
                    call BJDebugMsg("[SpecDrop] SKIPPED (unique already dropped): " + I2S(itemTypeId))
                endif
            endif
            
            set entryIndex = specificNext[entryIndex]
        endloop
    endfunction
    
    // =========================================================================
    // EVENT HANDLERS
    // =========================================================================
    
    // PRIVATE - used with centralized death event system (UnitDeathEvent)
    private function OnUnitDeathHandler takes nothing returns nothing
        local unit dying = GetDyingUnit()
        local integer unitTypeId
        local integer unitLevel
        local real x
        local real y
        
        if dying == null then
            return
        endif
        
        // Only process non-hero units
        if IsUnitType(dying, UNIT_TYPE_HERO) then
            set dying = null
            return
        endif
        
        set unitTypeId = GetUnitTypeId(dying)
        set unitLevel = GetUnitLevel(dying)
        set x = GetUnitX(dying)
        set y = GetUnitY(dying)
        
        // Process specific drops first (for bosses)
        if unitHasSpecificDrops[unitTypeId] != 0 then
            call RollSpecificDrops(unitTypeId, x, y)
        endif
        
        // Process generic drops (for all non-hero units)
        call RollGenericDrop(unitLevel, x, y)
        
        set dying = null
    endfunction
    
    // =========================================================================
    // INITIALIZATION
    // =========================================================================
    
    private function InitTables takes nothing returns nothing
        // Initialize all Tables
        set tierMinLevel = Table.create()
        set tierMaxLevel = Table.create()
        set tierDropChance = Table.create()
        
        set tierRarityItemLevel = Table.create()
        set tierRarityWeight = Table.create()
        
        set itemPoolFirst = Table.create()
        set itemPoolCount = Table.create()
        set itemPoolNext = Table.create()
        set itemPoolItemType = Table.create()
        set itemPoolWeight = Table.create()
        
        set uniqueItemDropped = Table.create()
        set itemIsUnique = Table.create()
        set itemRarity = Table.create()  // For floating text color lookup
        
        set unitHasSpecificDrops = Table.create()
        set unitSpecificFirst = Table.create()
        set unitSpecificCount = Table.create()
        set specificNext = Table.create()
        set specificItemType = Table.create()
        set specificDropChance = Table.create()
        set specificIsGuaranteed = Table.create()
        set specificWeight = Table.create()
        
        // Create drop queue timer (will be started/paused as needed)
        set dropQueueTimer = CreateTimer()
        
        // Create hover animation timer (will be started/paused as needed)
        set hoverTimer = CreateTimer()
        
        // Create pending drop timer (for delayed floating text on item drop)
        set pendingDropTimer = CreateTimer()
        
        // Create item-to-hover lookup table
        set itemToHoverIndex = Table.create()
        
        set initialized = true
        
        if DEBUG_MODE then
            call BJDebugMsg("ItemLootSystem tables initialized")
        endif
    endfunction
    
    private function Init takes nothing returns nothing
        local trigger pickupTrig
        local trigger dropTrig
        local trigger useTrig
        
        call InitTables()
        call InitFloatingTextConfig()
        
        // Register with centralized death event system
        call UnitDeathEvent_Register(function OnUnitDeathHandler)
        
        // Register item pickup trigger (to remove floating text when item picked up)
        set pickupTrig = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(pickupTrig, EVENT_PLAYER_UNIT_PICKUP_ITEM)
        call TriggerAddAction(pickupTrig, function OnItemPickup)

        // Register item use trigger (powerups can be consumed immediately on pickup)
        set useTrig = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(useTrig, EVENT_PLAYER_UNIT_USE_ITEM)
        call TriggerAddAction(useTrig, function OnItemUse)
        
        // Register item drop trigger (to create floating text when unit drops item)
        set dropTrig = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(dropTrig, EVENT_PLAYER_UNIT_DROP_ITEM)
        call TriggerAddAction(dropTrig, function OnItemDrop)
        
        if DEBUG_MODE then
            call BJDebugMsg("ItemLootSystem initialized")
        endif
    endfunction

endlibrary
