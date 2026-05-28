# DInventory Bag Expansion System - Configuration Guide

## Summary

The DInventory system **already has all the functionality** needed for dynamic inventory expansion! The system has been configured with:

- **Initial inventory size**: 12 slots (3 rows × 4 columns)
- **Expandable capacity**: Can be increased at runtime by purchasing bags from vendors
- **Flexible paradigm support**: Works with both "1PerPlayer" and "1PerHero" inventory paradigms

---

## Configuration Files

### 1. DConfigurationArea.j

**Changes Made:**
- Set `InventoryColumns = 4` (was 5)
- Set `InventoryRows = 3` (was 5)
- Initial capacity is now 12 slots instead of 25 slots
- Added comprehensive documentation header explaining the bag system

**Key Configuration Values:**
```jass
integer InventoryPages = 1
integer InventoryColumns = 4
integer InventoryRows = 3
integer InventoryCapacityBase = 12  // (4 × 3 × 1)
```

---

## Available Functions

### For Vendors (Easy to Use)

These wrapper functions are designed for vendor/shop systems to call when players purchase bags:

#### `DInvAddSlotsForPlayerVendor(playerId, numberOfSlots)` → returns boolean
- Adds inventory slots for a player (works with "1PerPlayer" paradigm)
- Shows a confirmation message to the player
- **Returns**: `true` if successful, `false` if would exceed maximum capacity
- **Parameters:**
  - `playerId`: Player index (0-11)
  - `numberOfSlots`: Number of slots to add (e.g., 6, 12, 20)

**Example:**
```jass
if DInvAddSlotsForPlayerVendor(GetPlayerId(buyer), 12) then
    // Success! Deduct gold, play sound, etc.
else
    // Failed - inventory at max capacity
endif
```

#### `DInvAddSlotsForHeroVendor(heroUnit, numberOfSlots)` → returns boolean
- Adds inventory slots for a specific hero (works with "1PerHero" paradigm)
- Automatically detects paradigm and calls the appropriate function
- Shows a confirmation message to the player
- **Returns**: `true` if successful, `false` if would exceed maximum capacity
- **Parameters:**
  - `heroUnit`: The hero unit purchasing the bag
  - `numberOfSlots`: Number of slots to add (e.g., 6, 12, 20)

**Example:**
```jass
if DInvAddSlotsForHeroVendor(GetTriggerUnit(), 12) then
    // Success! Remove bag item, deduct gold
else
    // Failed - inventory at max capacity (don't remove bag)
endif
```

---

## System Limits

### Technical Limits

**Maximum slots per page: 340**
- This is a hard technical limit due to frame array size
- Frame arrays are declared as `framehandle array [8160]`
- With 24 players max: 8160 ÷ 24 = 340 slots per player per page

**What happens when full?**
- If you try to add slots that would exceed 340 × pages, the function returns `false`
- An error message is shown: "Cannot expand inventory - maximum capacity reached!"
- **No items are lost** - the purchase simply fails

**Multi-page support:**
- You can configure multiple pages: `integer InventoryPages = 2`
- With 2 pages: maximum 680 slots (340 × 2)
- With 3 pages: maximum 1020 slots (340 × 3)

### Practical Limits

With the current configuration:
- **Pages**: 1
- **Initial capacity**: 12 slots (3 rows × 4 columns)
- **Maximum with bags**: 340 slots
- **Available expansion**: 328 slots (340 - 12 = 328)

This means you could theoretically buy:
- 54 small bags (328 ÷ 6 = 54.6)
- 27 medium bags (328 ÷ 12 = 27.3)
- 16 large bags (328 ÷ 20 = 16.4)
- Or any combination that doesn't exceed 328 additional slots

---

## What Happens When Buying Bags?

### Scenario 1: Inventory is FULL (all current slots occupied)
**Answer**: Nothing bad happens! ✓

When you call `DInvAddSlotsForHeroVendor(hero, 12)`:
1. The system simply **adds 12 new empty slots** to the end
2. Your existing items stay exactly where they are
3. The new slots are available immediately for new items
4. If inventory UI is open, it refreshes automatically to show new slots

**Example:**
- Current: 12 slots (all full with items)
- Buy Medium Bag: +12 slots
- Result: 24 slots (first 12 full, last 12 empty)

### Scenario 2: Would exceed 340 slot limit
**Answer**: Purchase fails safely! ✓

When you try to buy a bag that would exceed the limit:
1. Function returns `false`
2. Error message shown: "Cannot expand inventory - maximum capacity reached!"
3. **No gold is deducted** (if you check return value first)
4. **Bag item is not consumed** (if you check return value first)
5. Player can sell the bag back or save it

**Example with proper error handling:**
```jass
if DInvAddSlotsForHeroVendor(hero, slotsToAdd) then
    call RemoveItem(bagItem)  // Only remove if successful
    call DeductGold(cost)      // Only charge if successful
else
    // Do nothing - bag stays in inventory, gold not taken
endif
```

### Scenario 3: Reducing inventory capacity (advanced)
If you ever need to shrink inventory (negative delta), the system handles overflow intelligently:
1. Items in removed slots are moved to free slots if available
2. If no free slots, items go to vanilla (6-slot) inventory
3. If vanilla inventory also full, items are dropped on ground
4. **No items are destroyed** - they always go somewhere

---

### Advanced Functions (Manual Control)

These functions give you more control but require understanding the paradigm:

#### `DInvDeltaAdditionalSlotsForPlayer(playerId, delta)`
- For "1PerPlayer" paradigm
- Changes the bag size for all heroes of a player
- Can be positive (expand) or negative (shrink)

#### `DInvDeltaAdditionalSlotsForUnit(unit, delta)`
- For "1PerHero" paradigm
- Changes the bag size for a specific hero
- Can be positive (expand) or negative (shrink)
- Handles overflow by moving items to vanilla inventory or dropping them

#### `DInvDeltaAdditionalSlotsForBID(bagId, delta)`
- For direct manipulation using Bag ID
- Most low-level control
- Can be positive (expand) or negative (shrink)

---

## How the Capacity System Works

The total inventory capacity is calculated as:

```
Total Capacity = InventoryCapacityBase + PlayerModifier + BagModifier
```

Where:
- **InventoryCapacityBase**: Set in `DConfigurationArea.j` (default: 12)
- **PlayerModifier**: Additional slots for the entire player (`DInvMaxSlotModifierForPlayer[pid]`)
- **BagModifier**: Additional slots for specific hero/bag (`BIDDB[bid][0].integer[1]`)

### Example Calculation:
- Base: 12 slots
- Player buys Medium Bag: +12 slots
- Player buys Large Bag: +20 slots
- **Total**: 12 + 12 + 20 = **44 slots**

---

## Suggested Bag Tiers

Here are suggested bag sizes for a balanced progression system:

| Bag Type | Slots Added | Cost (Gold) | Total Slots* |
|----------|-------------|-------------|--------------|
| Starting | 0           | 0           | 12           |
| Small Bag | +6         | 100         | 18           |
| Medium Bag | +12       | 300         | 30           |
| Large Bag | +20        | 750         | 50           |
| Massive Bag | +30      | 1500        | 80           |

\* Total slots shown if only that bag is purchased (cumulative)

---

## Implementation Examples

### Method 1: Item Usage (Consumable Bag Item)

Create bag items in the Object Editor, then use this trigger:

```jass
function BagItemUsed takes nothing returns nothing
    local item usedItem = GetManipulatedItem()
    local integer itemTypeId = GetItemTypeId(usedItem)
    local unit hero = GetTriggerUnit()
    local integer slotsToAdd = 0
    
    if itemTypeId == 'bag1' then
        set slotsToAdd = 6  // Small bag
    elseif itemTypeId == 'bag2' then
        set slotsToAdd = 12  // Medium bag
    endif
    
    if slotsToAdd > 0 then
        call RemoveItem(usedItem)
        call DInvAddSlotsForHeroVendor(hero, slotsToAdd)
    endif
    
    set usedItem = null
    set hero = null
endfunction
```

### Method 2: Vendor/Shop System

When a player purchases from a shop:

```jass
function VendorSellsBag takes unit buyer, integer bagSize, integer goldCost returns nothing
    local player p = GetOwningPlayer(buyer)
    
    if GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) >= goldCost then
        call SetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD, 
            GetPlayerState(p, PLAYER_STATE_RESOURCE_GOLD) - goldCost)
        call DInvAddSlotsForHeroVendor(buyer, bagSize)
    endif
    
    set p = null
    set buyer = null
endfunction
```

### Method 3: Chat Command (Testing)

```jass
// Type "-bag 12" in game to add 12 slots
function BagCommand takes nothing returns nothing
    local string cmd = GetEventPlayerChatString()
    local integer slots = S2I(SubString(cmd, 5, StringLength(cmd)))
    local unit hero = GetTriggerPlayerHero()
    
    if slots > 0 then
        call DInvAddSlotsForHeroVendor(hero, slots)
    endif
    
    set hero = null
endfunction
```

---

## How Shrinking Works (Advanced)

When you reduce inventory capacity (negative delta), the system intelligently handles overflow:

1. **Items in overflow slots** are moved to free slots if available
2. **If inventory is full**, items are:
   - First moved to the vanilla (6-slot) inventory
   - If vanilla inventory is also full, items are dropped on the ground

This ensures no items are lost when reducing capacity.

---

## Pages vs Slots

The current configuration uses **1 page** with **12 slots per page**.

You can alternatively configure multiple pages:
```jass
integer InventoryPages = 2
integer InventoryColumns = 3
integer InventoryRows = 2
// This would give 2 pages × 6 slots = 12 total slots
```

**Note:** Maximum slots per page is 340 (technical limitation).

---

## Testing the System

See the `EXAMPLE_BagVendor.j` file for a complete working example with:
- Item usage triggers
- Vendor purchase functions
- Chat command testing (type `-bag 1`, `-bag 2`, etc. in-game)

---

## Integration Checklist

- [x] Configure initial inventory size in `DConfigurationArea.j`
- [x] Add vendor wrapper functions to `SharedDInvLib.j`
- [ ] Create bag items in Object Editor (item IDs like 'bag1', 'bag2', etc.)
- [ ] Implement vendor trigger using one of the methods above
- [ ] Test with chat commands first (use EXAMPLE_BagVendor.j)
- [ ] Integrate with your actual shop/vendor system
- [ ] Balance bag costs and slot amounts for your game

---

## Notes

1. **No need to track bag counts**: The system automatically accumulates all purchases
2. **Works with both paradigms**: Vendor functions auto-detect "1PerPlayer" vs "1PerHero"
3. **Persistent across hero deaths**: Inventory capacity is tied to the player/bag, not the hero instance
4. **Visual update**: When capacity changes while inventory is open, the UI automatically refreshes
5. **Thread-safe**: All functions handle edge cases like negative capacity, full inventories, etc.

---

## Questions?

The original system documentation is available at:
https://docs.google.com/document/d/11v__wJNyUZ4i0gqzcspp4AOuQCyrS5Kb26GuHu4MHW0/edit?usp=sharing
