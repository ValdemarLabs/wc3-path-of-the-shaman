# Critical Bug Fixes for DInventory/DEquipment System
## Date: October 19, 2025

## Summary
Fixed critical bugs causing items to disappear or lose charges in the DInventory/DEquipment system.

---

## Bug #1: Item Handle DB Not Updated During Swaps (CRITICAL)
**File:** `DInventory.j`, lines ~857-865  
**Severity:** CRITICAL - Causes item loss

### Problem:
When swapping items in inventory slots, the system moved items in the `DInventoryDB` array but **never updated** the `DInvItemHandleDB` which tracks which slot each item is in. This caused:
- Later operations to access wrong slots
- Items being deleted from incorrect positions
- Item loss when equipping/unequipping

### Fix Applied:
```jass
// When moving to empty slot:
set DInventoryDB[bid].item[slotId] = DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]]
set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[2] = slotId
call DInventoryDB[bid].item.remove(SourceDItemSlotIdActive[pid])

// When swapping two items:
set auxit = DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]]
set DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]] = DInventoryDB[bid].item[slotId]
set DInventoryDB[bid].item[slotId] = auxit
// Update BOTH item slot references
set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[slotId])].integer[2] = slotId
set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[SourceDItemSlotIdActive[pid]])].integer[2] = SourceDItemSlotIdActive[pid]
```

---

## Bug #2: Accessing Deleted Item Reference (CRITICAL)
**File:** `SharedDInvLib.j`, line ~4831  
**Severity:** CRITICAL - Corrupts item database

### Problem:
In `EquipDInvItemToDEqSlot`, the code tried to access an item **AFTER** it was already removed from inventory:
```jass
set DInvItemHandleDB[GetHandleId(DInventoryDB[bid].item[dInvSlotId])].integer[4] = deqslot
call DInventoryDB[bid].item.remove(dInvSlotId)  // Item removed HERE
```
This accessed the wrong item or null, corrupting the database.

### Fix Applied:
```jass
// Store handle ID BEFORE removing item
set auxi = GetHandleId(it)
set DInvItemHandleDB[auxi].integer[4] = deqslot
call DInventoryDB[bid].item.remove(dInvSlotId)
```

---

## Bug #3: Missing Slot ID Storage (CRITICAL)
**File:** `SharedDInvLib.j`, lines ~3680, ~3788  
**Severity:** CRITICAL - Breaks slot tracking

### Problem:
When storing items via `StoreItemForPIDBID`, the system set:
- `integer[0]` = player ID
- `integer[1]` = bag ID  
- `integer[6]` = equipment ID

But **NEVER** set `integer[2]` = slot ID. This meant the system had no reliable way to find which slot an item was in.

### Fix Applied (in both new and old code paths):
```jass
set DInventoryDB[bid].item[targetSlot] = it
set DInvItemHandleDB[ihndl].integer[0] = pid + 1
set DInvItemHandleDB[ihndl].integer[1] = bid
set DInvItemHandleDB[ihndl].integer[2] = targetSlot  // ADDED: Store slot ID
set DInvItemHandleDB[ihndl].integer[6] = eqid
```

---

## How These Bugs Caused Your Issue

### Scenario: Spring Water Disappearing from Slot 3

1. **You pick up items** → Items stored in slots 1, 2, 3 (Spring Water)
2. **You swap items around** → Items move in inventory array
   - ❌ **BUG #1**: Slot IDs in handle DB NOT updated
   - System still thinks Spring Water is in old position
3. **You equip/unequip equipment** → Triggers item transfers
   - ❌ **BUG #2**: Accesses wrong item due to corrupted references
   - ❌ **BUG #3**: Can't find items due to missing slot IDs
4. **System deletes "empty" slot** → Actually deletes Spring Water
   - Result: **ITEM LOST** ❌

---

## Testing Recommendations

After applying these fixes, test the following scenarios:

1. ✅ **Swap items multiple times** - Verify items stay in correct slots
2. ✅ **Equip and unequip items repeatedly** - Verify no items disappear
3. ✅ **Pick up stackable items** (potions, scrolls) - Verify charges preserved
4. ✅ **Fill inventory, then swap** - Verify no corruption at capacity
5. ✅ **Switch between equipment and inventory** - Verify items track correctly
6. ✅ **Save and load game** - Verify item positions persist

---

## Additional Notes

### What is DInvItemHandleDB.integer[2]?
This field stores the **slot ID** (0-N) where an item is located in a bag. It's critical for:
- Finding items quickly
- Updating UI correctly
- Preventing slot mismatches during operations

### What is DInvItemHandleDB.integer[4]?
This field stores the **equipment slot ID** (1-20) if item is equipped, or 0 if not equipped.

### Pre-existing Errors
The compilation errors shown (related to Table2DT/Table3DT syntax) are pre-existing issues in the codebase and not caused by these fixes. They appear to be related to a custom table library implementation.

---

## Files Modified

1. ✅ `DInventory.j` - Fixed item swap handle DB updates
2. ✅ `SharedDInvLib.j` - Fixed equipment transfer reference + slot ID storage (3 locations)

---

## Version History

- **Oct 19, 2025**: Initial critical bug fixes applied
  - Fixed item swap slot tracking
  - Fixed equipment transfer item access
  - Added slot ID storage in all code paths
