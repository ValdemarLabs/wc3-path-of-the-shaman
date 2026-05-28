# Quick Reference: Item Loss Prevention

## What Was Fixed?

### 🔴 CRITICAL Bug #1: Item Swapping Lost Track of Items
**Problem:** Swapping items updated their positions but not their internal tracking  
**Result:** System thought items were in wrong slots → deleted wrong items  
**Fixed:** Now updates `DInvItemHandleDB[].integer[2]` after every swap

### 🔴 CRITICAL Bug #2: Equipment System Accessed Deleted Items  
**Problem:** Code tried to read item data after removing it from inventory  
**Result:** Corrupted database, unpredictable item loss  
**Fixed:** Now stores item handle ID before deletion

### 🔴 CRITICAL Bug #3: New Items Never Got Slot IDs
**Problem:** When storing items, slot ID field was never set  
**Result:** System couldn't reliably find items later  
**Fixed:** Now sets `DInvItemHandleDB[].integer[2] = targetSlot` when storing

---

## Understanding DInvItemHandleDB Structure

Each item has a handle ID. For that handle ID, the system stores:

```jass
DInvItemHandleDB[itemHandleId].integer[0] = pid + 1  // Player ID + 1
DInvItemHandleDB[itemHandleId].integer[1] = bid      // Bag ID (which inventory)
DInvItemHandleDB[itemHandleId].integer[2] = slotId   // Slot 0-N (which slot in bag) ⚠️ WAS MISSING
DInvItemHandleDB[itemHandleId].integer[3] = lock     // Transfer lock/semaphore
DInvItemHandleDB[itemHandleId].integer[4] = eqSlot   // Equipment slot (1-20) or 0
DInvItemHandleDB[itemHandleId].integer[6] = eqid     // Equipment ID
```

**integer[2] is the KEY** - Without it, the system can't reliably locate items!

---

## How to Debug Item Issues in Future

### 1. Enable Debug Messages
Uncomment these lines to see what's happening:
```jass
//call BJDebugMsg("...")  → call BJDebugMsg("...")
```

### 2. Check Item Handle Data
Add this to verify item tracking:
```jass
local integer ihndl = GetHandleId(it)
call BJDebugMsg("Item: " + GetItemName(it))
call BJDebugMsg("  Stored Slot: " + I2S(DInvItemHandleDB[ihndl].integer[2]))
call BJDebugMsg("  Actual Slot: " + I2S(GetDInvSlotIdOfItem(it)))
```

### 3. Verify After Operations
After swap/equip/unequip, check:
```jass
// After swap - both items should have correct slot IDs
// After equip - item should have integer[4] = equipment slot
// After unequip - item should have integer[4] = 0
```

---

## What Could Still Cause Item Loss?

Even with these fixes, items can still be lost if:

1. **External scripts** manipulate items without using DInventory functions
2. **RemoveItem()** called directly instead of through system
3. **Unit dies** with items in DInventory (check death handlers)
4. **Memory leaks** in other systems corrupt the hashtables
5. **Stacking edge cases** with charges = 0 or negative

---

## Best Practices Going Forward

### ✅ DO:
- Use `DInvUnitAddItem()` to give items to units
- Use system functions for all item manipulation
- Test swap + equip + unequip combinations thoroughly
- Keep slot tracking up to date in any custom modifications

### ❌ DON'T:
- Use `UnitAddItem()` directly for DInventory units
- Call `RemoveItem()` on items in DInventory without system functions
- Modify `DInventoryDB[]` without updating `DInvItemHandleDB[]`
- Assume items are where you last saw them - always verify!

---

## If Items Still Disappear After Fixes

1. **Check if item is auto-pickup**: `BlzGetItemBooleanField(it, 'ipow')`
2. **Verify item not in exclusion list**: Check `IsItemStoreableForPIDBID()`
3. **Look for duplicate item events**: Pickup event firing multiple times?
4. **Check for item usage**: Items with charges might be consumed on use
5. **Verify inventory not full**: `IsBIDInventoryFull()` preventing storage?

---

## Emergency Item Recovery

If players lose items, you can manually restore them:

```jass
// Give item to unit's DInventory
local item recovered = CreateItem('I000', 0, 0)  // Your item ID
call DInvUnitAddItem(yourUnit, recovered)

// Set charges if needed
call SetItemCharges(recovered, 5)
```

---

## Testing Checklist

Before considering this fully fixed, test:

- [ ] Swap items in slots 1 ↔ 3
- [ ] Equip item from slot 3
- [ ] Unequip back to slot 5
- [ ] Pick up 10 potions (stacking)
- [ ] Swap stacked potions with other items
- [ ] Fill entire inventory then swap items
- [ ] Equip + unequip 20 times rapidly
- [ ] Save game, swap items, load game
- [ ] Multiple heroes swapping items simultaneously

---

## Contact & Support

If issues persist:
1. Enable ALL debug messages in the system
2. Record exact sequence of actions that causes loss
3. Check which function last accessed the lost item
4. Verify all three bug fixes are properly applied
