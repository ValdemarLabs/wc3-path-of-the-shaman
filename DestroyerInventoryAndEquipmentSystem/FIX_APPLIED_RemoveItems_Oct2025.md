# Fix Applied: RemoveDInvItemChargesByType Slot Skipping Bug

## Date: October 22, 2025

---

## ✅ CRITICAL BUG FIXED

### The Problem

When `RemoveDInvItemChargesByType` deleted items from inventory, it would:
1. Delete an item from slot N
2. All items after slot N shift down (slot N+1 → N, slot N+2 → N+1, etc.)
3. **BUG**: Loop counter always incremented, skipping the next item
4. **RESULT**: Random items skipped during deletion → wrong items removed or left behind

### Example:
**Inventory:** Gold(0), Water(1), Potion(2), Water(3), Mana(4)

**Remove 6 Water:**
- ❌ OLD: Delete slot 1 → increment to 2 → check Potion → **SKIP Water at new slot 2**
- ✅ NEW: Delete slot 1 → stay at 1 → check Water (now at slot 1) → correct!

---

## The Fix

**File:** `SharedDInvLib.j`, function `RemoveDInvItemChargesByType`

### Changed Logic:
```jass
// OLD CODE - ALWAYS INCREMENTED
loop
    set it = DInventoryDB[bid].item[slotId]
    if it != null and GetItemTypeId(it) == itemTypeId then
        if charges > remainingToRemove then
            call SetItemCharges(it, charges - remainingToRemove)
            set remainingToRemove = 0
        else
            call DeleteBIDSlotIdItemFromDInventory(bid, slotId)  // ❌ DELETES
        endif
    endif
    set slotId = slotId + 1  // ❌ ALWAYS INCREMENTS - SKIPS NEXT ITEM!
endloop

// NEW CODE - CONDITIONAL INCREMENT
loop
    set it = DInventoryDB[bid].item[slotId]
    if it != null and GetItemTypeId(it) == itemTypeId then
        if charges > remainingToRemove then
            call SetItemCharges(it, charges - remainingToRemove)
            set remainingToRemove = 0
            set slotId = slotId + 1  // ✅ Only increment when NOT deleting
        else
            call DeleteBIDSlotIdItemFromDInventory(bid, slotId)  // ✅ DELETES
            // ✅ DON'T INCREMENT - next item shifts into this slot
        endif
    else
        set slotId = slotId + 1  // ✅ Increment when skipping non-matching items
    endif
endloop
```

---

## Why This Fixes Your HeroItemCheck Issues

### Your Function Chain:
1. `HeroItemCheckBoth()` → calls `HeroItemCheck()`
2. `HeroItemCheck()` → calls `GetDInvItemChargesByTypeThreshold()`
3. `GetDInvItemChargesByTypeThreshold()` → **ONLY CHECKS, doesn't remove** ✅

### But If You Have GUI Triggers:
If GUI triggers watch `udg_DInvUnit`, `udg_DInvItemType`, or `udg_DInvItemAmount` and call removal functions, they were triggering the bug.

### Now Fixed:
- Items are removed in correct order
- No items skipped during removal
- Inventory stays consistent

---

## What GetDInvItemChargesByTypeThreshold Does

**Good News:** This function is **READ-ONLY**:

```jass
function GetDInvItemChargesByTypeThreshold takes unit u, integer itemTypeId, integer threshold returns boolean
    // Counts total charges of matching items
    return totalCharges >= threshold  // Just returns true/false
endfunction
```

It **NEVER removes items**. So `HeroItemCheck` itself is safe!

---

## Remaining Potential Issues

### 1. Slot ID Desync After Deletion
When items are deleted, items shift down but their stored slot IDs in `DInvItemHandleDB[].integer[2]` are NOT updated.

**Impact:** Minor - most functions search through the array directly, not by stored slot ID.

**If problems persist:** We can add slot ID updates to `DeleteBIDSlotIdItemFromDInventory`.

### 2. Check for Removal Triggers
Search your project for:
- Triggers that call `RemoveDInvItemChargesByType`
- GUI triggers watching `udg_DInv*` variables
- Quest completion triggers that consume items

---

## Testing Checklist

Test these scenarios after the fix:

1. ✅ **Remove stacked items**
   - Give hero: 5x Potion, 3x Scroll, 5x Potion
   - Remove 8x Potion
   - Verify: Scroll still there, correct potions removed

2. ✅ **Remove partial stacks**
   - Give hero: 10x Water
   - Remove 7x Water
   - Verify: 3x Water remains

3. ✅ **Remove from multiple heroes**
   - Give Nazgrek: 5x Item A
   - Give Zulkis: 5x Item A
   - Call `HeroItemCheckBoth()`
   - Verify: No items disappear from either hero

4. ✅ **Quest item consumption**
   - If you have quests that consume items
   - Complete quest
   - Verify: Only required items removed, others intact

---

## Files Modified

1. ✅ `SharedDInvLib.j` - Fixed `RemoveDInvItemChargesByType` loop logic

---

## Summary

**Problem:** Loop counter incremented even after deleting items, causing slot skips  
**Solution:** Only increment when NOT deleting or when skipping non-matches  
**Result:** Items removed in correct order, no random disappearances

Your `HeroItemCheck` function is safe (read-only), but any code calling `RemoveDInvItemChargesByType` was triggering this bug.

---

## Need More Help?

If items still disappear after this fix:
1. Enable debug messages in `RemoveDInvItemChargesByType`
2. Check for other triggers that manipulate inventory
3. Verify the earlier swap/equip fixes are also applied
4. Search for direct `RemoveItem()` calls bypassing the system
