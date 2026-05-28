# DInventory: What Makes Items Show 0 Charges?

## Quick Answer

An item shows **"0"** charges when:
1. Item is marked as **stackable** (CHARGED/PURCHASABLE/POWERUP/CAMPAIGN type)
2. **AND** item has charges = 0 (or negative)

The charge number is **always displayed** for stackable items, even when 0.

---

## The Display Logic

### Location: `SharedDInvLib.j`, function `DInvSlotDataIntoFrame` (line ~1795)

```jass
if DInventoryIsItemStackable(it) == TRUE or GetItemCharges(it) > 0 then
    // Show the charge count
    call BlzFrameSetText(InventorySlotStacksFrame[frind], I2S(GetItemCharges(it)))
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], TRUE)
else
    // Hide the charge count
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], FALSE)
endif
```

### Decision Tree:

```
Is item stackable? (CHARGED/PURCHASABLE/POWERUP/CAMPAIGN)
├─ YES → ALWAYS show charges (even if 0) ✅
└─ NO → Is GetItemCharges(it) > 0?
    ├─ YES → Show charges ✅
    └─ NO → Hide charges ❌
```

---

## When You See "0" Charges

### Scenario 1: Stackable Item with 0 Charges
```jass
// Item type: ITEM_TYPE_CHARGED (like potions)
// Charges: 0
// Result: Shows "0" in corner
```

**Why:** Item is stackable, so charge display is always visible.

**Common causes:**
- Item consumed all charges
- Item created with 0 charges initially
- Bug in removal function left item at 0 charges instead of deleting it
- `SetItemCharges(item, 0)` was called

### Scenario 2: Non-Stackable Item with 0 Charges
```jass
// Item type: ITEM_TYPE_PERMANENT (like equipment)
// Charges: 0
// Result: No number shown (charges hidden)
```

**Why:** Item not stackable AND charges ≤ 0, so no display.

---

## What Makes an Item "Stackable"?

### Location: `SharedDInvLib.j`, function `DInventoryIsItemStackable` (line ~487)

```jass
function DInventoryIsItemStackable takes item it returns boolean
    local itemtype IT = GetItemType(it)
    if IT == ITEM_TYPE_CHARGED or 
       IT == ITEM_TYPE_PURCHASABLE or 
       IT == ITEM_TYPE_POWERUP or 
       IT == ITEM_TYPE_CAMPAIGN then
        return TRUE
    endif
    return FALSE
endfunction
```

### Stackable Types:
- ✅ **ITEM_TYPE_CHARGED** - Consumables like potions, scrolls
- ✅ **ITEM_TYPE_PURCHASABLE** - Shop items
- ✅ **ITEM_TYPE_POWERUP** - Powerups like tomes
- ✅ **ITEM_TYPE_CAMPAIGN** - Campaign-specific items

### Non-Stackable Types:
- ❌ **ITEM_TYPE_PERMANENT** - Equipment, artifacts
- ❌ **ITEM_TYPE_ARTIFACT** - Quest items, unique items
- ❌ **ITEM_TYPE_MISCELLANEOUS** - Misc items

---

## Why Items Get Stuck at 0 Charges

### 🔴 Bug #1: Partial Item Removal
**Before the fix on Oct 22, 2025:**

```jass
// RemoveDInvItemChargesByType was called
// Item has 3 charges, need to remove 3
set charges = GetItemCharges(it)  // = 3
if charges > remainingToRemove then  // 3 > 3 = FALSE
    // This branch skipped
else
    // Should delete item, but if there's a bug here...
    set remainingToRemove = remainingToRemove - charges  // = 0
    call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
    
    // If deletion fails or is interrupted, item stays with 0 charges!
endif
```

### 🔴 Bug #2: SetItemCharges Without Deletion
If code does:
```jass
call SetItemCharges(item, 0)
// But forgets to call RemoveItem(item)
```
Item will show "0" forever.

### 🔴 Bug #3: Stacking Gone Wrong
```jass
// Item A has 5 charges
// Item B has 3 charges
// Try to merge into Item A (max 5)

call SetItemCharges(ItemA, 5)  // Max reached
call SetItemCharges(ItemB, 3)  // Remainder... but what if this fails?

// If ItemB remains at 0 instead of being removed → shows "0"
```

---

## How to Fix "0 Charge" Items

### Option 1: Auto-Remove in Display Function

Add to `DInvSlotDataIntoFrame` before displaying:

```jass
if DInventoryIsItemStackable(it) == TRUE or GetItemCharges(it) > 0 then
    // SAFEGUARD: Remove items with 0 or negative charges
    if GetItemCharges(it) <= 0 and DInventoryIsItemStackable(it) == TRUE then
        call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
        call BlzFrameSetVisible(InventorySlotStacksFrame[frind], FALSE)
        return  // Exit early
    endif
    
    call BlzFrameSetText(InventorySlotStacksFrame[frind], I2S(GetItemCharges(it)))
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], TRUE)
else
    call BlzFrameSetVisible(InventorySlotStacksFrame[frind], FALSE)
endif
```

### Option 2: Cleanup Function

Create a cleanup function:
```jass
function CleanupZeroChargeItems takes unit u returns nothing
    local integer bid = BIDOfUnit(u)
    local integer slotId = 0
    local integer maxCap = MaxDInvCapacityOfUnit(u)
    local item it
    
    loop
        exitwhen slotId >= maxCap
        set it = DInventoryDB[bid].item[slotId]
        if it != null then
            if DInventoryIsItemStackable(it) == TRUE then
                if GetItemCharges(it) <= 0 then
                    call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                    // Don't increment - next item shifts down
                else
                    set slotId = slotId + 1
                endif
            else
                set slotId = slotId + 1
            endif
        else
            set slotId = slotId + 1
        endif
    endloop
    
    set it = null
endfunction
```

Call this periodically or after item operations.

### Option 3: Safeguard in RemoveDInvItemChargesByType

Already fixed on Oct 22! The loop now properly handles deletions.

---

## Debugging "0 Charge" Items

### Step 1: Enable Debug Messages

Uncomment these in `DInvSlotDataIntoFrame`:
```jass
call BJDebugMsg("DInvSlotDataIntoFrame thinks this is stackable")
call BJDebugMsg("DInvSlotDataIntoFrame thinks it charges: "+I2S(GetItemCharges(it)))
```

### Step 2: Check Item Properties

```jass
local item it = DInventoryDB[bid].item[slotId]
call BJDebugMsg("Item: " + GetItemName(it))
call BJDebugMsg("Type: " + I2S(GetItemType(it)))
call BJDebugMsg("Charges: " + I2S(GetItemCharges(it)))
call BJDebugMsg("Is Stackable: " + B2S(DInventoryIsItemStackable(it)))
```

### Step 3: Track When Charges Drop to 0

Add to any function that modifies charges:
```jass
if GetItemCharges(it) <= 0 then
    call BJDebugMsg("WARNING: Item " + GetItemName(it) + " has " + I2S(GetItemCharges(it)) + " charges!")
endif
```

---

## Summary

**Items show "0" when:**
1. They are stackable types (CHARGED/PURCHASABLE/POWERUP/CAMPAIGN)
2. AND they have 0 charges

**This happens because:**
- Stackable items ALWAYS show charge count
- Non-stackable items only show charges if > 0
- Items with 0 charges should normally be deleted but bugs can prevent this

**Solutions:**
1. ✅ Fix removal bugs (done Oct 22, 2025)
2. Add safeguard to auto-delete 0-charge stackable items
3. Create cleanup function for periodic maintenance
4. Enable debug logging to catch when charges hit 0

---

## Related Fixes

See also:
- `FIX_APPLIED_RemoveItems_Oct2025.md` - Loop increment bug
- `CRITICAL_BUGFIXES_Oct2025.md` - Swap/equip bugs
- `ITEM_LOSS_PREVENTION_GUIDE.md` - General troubleshooting
