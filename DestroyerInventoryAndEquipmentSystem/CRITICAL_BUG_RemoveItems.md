# 🔴 CRITICAL BUG FOUND: RemoveDInvItemChargesByType Slot Corruption

## Date: October 22, 2025

---

## THE CRITICAL BUG

### Location: `SharedDInvLib.j`, function `RemoveDInvItemChargesByType` (lines ~2033-2062)

### The Problem:

When removing items from the inventory loop, the function **deletes items WITHOUT adjusting the loop counter**, causing it to **SKIP THE NEXT SLOT** after every deletion!

```jass
loop
    exitwhen slotId >= maxCapacity or remainingToRemove <= 0
    set it = DInventoryDB[bid].item[slotId]
    if it != null and GetItemTypeId(it) == itemTypeId then
        set charges = GetItemCharges(it)
        if charges > remainingToRemove then
            call SetItemCharges(it, charges - remainingToRemove)
            set remainingToRemove = 0
        else
            set remainingToRemove = remainingToRemove - charges
            call DeleteBIDSlotIdItemFromDInventory(bid, slotId)  // ⚠️ DELETES ITEM
        endif
    endif
    set slotId = slotId + 1  // ⚠️ ALWAYS INCREMENTS, EVEN AFTER DELETION!
endloop
```

---

## How This Causes Random Item Loss

### Example Scenario:
Your inventory has:
- **Slot 0**: Gold Coin (5)
- **Slot 1**: Spring Water (3) ← TARGET
- **Slot 2**: Health Potion (10)
- **Slot 3**: Spring Water (3) ← TARGET
- **Slot 4**: Mana Potion (5)

### When you call: `RemoveDInvItemChargesByType(hero, 'WATR', 6)`  // Remove 6 Spring Water

**What SHOULD happen:**
1. Check slot 0: Not Spring Water, skip
2. Check slot 1: Spring Water (3), remove it, need 3 more
3. Check slot 2: Not Spring Water, skip  
4. Check slot 3: Spring Water (3), remove it, done

**What ACTUALLY happens:**
1. `slotId = 0`: Gold Coin → skip → `slotId = 1`
2. `slotId = 1`: Spring Water (3) → **DELETE SLOT 1** → `slotId = 2`
3. ⚠️ **Inventory shifts!** What was slot 2 is now slot 1, slot 3 is now slot 2, etc.
4. `slotId = 2`: Now checking what was **ORIGINALLY SLOT 3** (Spring Water)
   - But we **SKIPPED** what was originally slot 2 (Health Potion now in slot 1)!
5. If there are more Spring Waters, they might be skipped or checked at wrong positions

### Result:
- ✅ Some Spring Waters removed correctly
- ❌ **Health Potion at wrong slot** (was slot 2, now slot 1, but system thinks it's still at slot 2)
- ❌ **Other Spring Waters might be SKIPPED** due to index shift
- ❌ **Handle DB now has WRONG SLOT IDs** for all items after deletion

---

## Why Your `HeroItemCheck` Triggers This

Your `HeroItemCheck.j` sets these variables:
```jass
set udg_DInvUnit = whichHero
set udg_DInvItemType = itemId
set udg_DInvItemAmount = requiredAmount
```

**IF** you have GUI triggers listening to these variable changes that call `RemoveDInvItemChargesByType`, then:
1. You check if hero has Spring Water
2. Some trigger fires and removes items
3. **Bug triggers → Random items skipped/corrupted**

---

## The Secondary Problem: DeleteBIDSlotIdItemFromDInventory

When an item is deleted from a slot:
1. It removes item from `DInventoryDB[bid].item[slotId]`
2. This causes all subsequent items to **shift down** in the array
3. But **NO OTHER ITEMS' SLOT IDs ARE UPDATED** in the handle database!

### Result:
After deleting slot 1:
- What was in slot 2 → now in slot 1 (but handle DB still says slot 2) ❌
- What was in slot 3 → now in slot 2 (but handle DB still says slot 3) ❌
- What was in slot 4 → now in slot 3 (but handle DB still says slot 4) ❌
- ...and so on

**Every item after the deletion point has the WRONG slot ID stored!**

---

## Additional Issue: GetDInvItemChargesByTypeThreshold

Good news: This function is **READ-ONLY** - it does NOT remove items!

```jass
function GetDInvItemChargesByTypeThreshold takes unit u, integer itemTypeId, integer threshold returns boolean
    // ... just counts charges ...
    return totalCharges >= threshold
endfunction
```

So `HeroItemCheck` itself is safe. But if there's another trigger responding to the variable changes...

---

## THE REAL CULPRIT

**Question:** Do you have **GUI triggers** that:
1. Watch for changes to `udg_DInvUnit`, `udg_DInvItemType`, or `udg_DInvItemAmount`?
2. Actually call `RemoveDInvItemChargesByType` to consume quest items?

If YES → That's where the bug triggers!

---

## CRITICAL FIX #1: RemoveDInvItemChargesByType Loop

The loop must NOT increment when an item is deleted:

```jass
function RemoveDInvItemChargesByType takes unit u, integer itemTypeId, integer amountToRemove returns nothing
    local integer remainingToRemove = amountToRemove
    local integer slotId = 0
    local integer bid = BIDOfUnit(u)
    local integer maxCapacity = MaxDInvCapacityOfUnit(u)
    local item it
    local integer charges

    if bid == -1 then
        return
    endif

    loop
        exitwhen slotId >= maxCapacity or remainingToRemove <= 0
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set charges = GetItemCharges(it)
            if charges > remainingToRemove then
                // Deduct charges and stop
                call SetItemCharges(it, charges - remainingToRemove)
                set remainingToRemove = 0
                set slotId = slotId + 1  // ✅ ONLY increment when NOT deleting
            else
                // Remove the item and deduct its charges
                set remainingToRemove = remainingToRemove - charges
                call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                // ✅ DON'T INCREMENT! Item deleted, next item shifted down to this slot
            endif
        else
            set slotId = slotId + 1  // ✅ Increment when skipping
        endif
    endloop
endfunction
```

---

## CRITICAL FIX #2: Update Slot IDs After Deletion

After deleting an item, ALL items in higher slots need their handle DB updated:

```jass
function DeleteBIDSlotIdItemFromDInventory takes integer bid, integer slotId returns nothing
    local integer ihndl = GetHandleId(DInventoryDB[bid].item[slotId])
    local integer i = slotId + 1
    local integer maxCap = 500  // Or use actual capacity
    local item tempItem
    
    // Clear deleted item's handle data
    set DInvItemHandleDB[ihndl].integer[0] = 0
    set DInvItemHandleDB[ihndl].integer[1] = 0
    set DInvItemHandleDB[ihndl].integer[2] = 0
    set DInvItemHandleDB[ihndl].integer[3] = 0
    set DInvItemHandleDB[ihndl].integer[4] = 0
    set DInvItemHandleDB[ihndl].integer[6] = 0
    
    // Remove item from array (this shifts all higher items down)
    call DInventoryDB[bid].item.remove(slotId)
    
    // ✅ UPDATE ALL ITEMS AFTER THIS SLOT
    loop
        exitwhen i >= maxCap
        set tempItem = DInventoryDB[bid].item[i]
        if tempItem != null then
            // Item is now in slot (i-1) after the shift
            set DInvItemHandleDB[GetHandleId(tempItem)].integer[2] = i
        else
            exitwhen true  // No more items
        endif
        set i = i + 1
    endloop
    
    set tempItem = null
endfunction
```

**BUT WAIT** - This is expensive! Better solution...

---

## OPTIMAL FIX: Don't Increment After Deletion

The simpler fix is **Fix #1** - just don't increment the loop counter after deletion!

When you delete slot 3:
- Items shift: slot 4→3, slot 5→4, etc.
- Next iteration checks slot 3 again (which is now what was slot 4)
- No items are skipped! ✅

The handle DB slot IDs will still be wrong, but as long as you always search through the array directly (not by stored slot ID), it works.

---

## RECOMMENDED SOLUTION

Apply **Fix #1** (don't increment after deletion) - it's simpler and safer.

Consider adding defensive code to UI refresh functions to handle slight desync.

---

## ACTION ITEMS

1. ✅ Apply Fix #1 to `RemoveDInvItemChargesByType`
2. 🔍 Search for GUI triggers that call this function
3. 🔍 Check if any triggers respond to `udg_DInv*` variable changes
4. ⚠️ If you need accurate slot tracking, apply Fix #2 as well
5. 🧪 Test: Remove items, check if inventory stays consistent

---

## How to Test

```jass
// Setup
// Give hero: 5x Potion A, 3x Potion B, 5x Potion A, 2x Potion C

// Test 1: Remove 8x Potion A
call RemoveDInvItemChargesByType(hero, 'potA', 8)
// Expected: Both Potion A stacks removed, Potion B and C remain
// Bug behavior: Potion B might disappear, C moves to wrong slot

// Test 2: Check inventory consistency
// All remaining items should be at correct slots
// No items should have disappeared unexpectedly
```
