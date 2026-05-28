# Fix Applied: HeroItemCheck Now Works for Single/No Charge Items

## Date: October 22, 2025

---

## The Problems

### Problem 1: Counting Items with 0 Charges
`GetDInvItemChargesByTypeThreshold` and related functions didn't count items with 0 charges:

```jass
// Quest Key item (charges = 0)
set totalCharges = totalCharges + GetItemCharges(it)  // adds 0
// Result: Item not counted! ❌
```

### Problem 2: Removing Items with 0 Charges
`RemoveDInvItemChargesByType` had a critical bug with 0-charge items:

```jass
set charges = GetItemCharges(it)  // = 0 for quest items
set remainingToRemove = remainingToRemove - charges  // -= 0 (no change!)
call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
// Loop continues removing MORE items because remainingToRemove never decreased! ❌
```

**Result:** Trying to remove 1 quest item would delete ALL items of that type!

---

## Understanding Item Charges

### Items with Charges (Stackable):
```
Health Potion:
- Type: ITEM_TYPE_CHARGED
- Level: 5 (max stack)
- Charges: 3 (current count)
- GetItemCharges() = 3 ✅
```

### Items WITHOUT Charges (Non-Stackable):
```
Quest Key:
- Type: ITEM_TYPE_CAMPAIGN
- Level: 0 (not stackable)
- Charges: 0 (no charge system)
- GetItemCharges() = 0 ❌

Magic Sword:
- Type: ITEM_TYPE_PERMANENT
- Level: 10 (item power, not stacking)
- Charges: 0
- GetItemCharges() = 0 ❌
```

**Key Issue:** Non-stackable items return `GetItemCharges() = 0`, but they should count as **1 item**.

---

## The Fixes

### Fix 1: GetDInvItemChargesByType
Now counts items with 0 charges as 1 item:

```jass
function GetDInvItemChargesByType takes unit u, integer itemTypeId returns integer
    local integer totalCharges = 0
    local integer charges
    
    loop
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set charges = GetItemCharges(it)
            
            // CRITICAL FIX: Count items with 0 charges as 1 item
            if charges <= 0 then
                set totalCharges = totalCharges + 1  // Count as 1 item ✅
            else
                set totalCharges = totalCharges + charges
            endif
        endif
        set slotId = slotId + 1
    endloop
    
    return totalCharges
endfunction
```

### Fix 2: GetDInvItemChargesByTypeThreshold
Same fix for the threshold checking function:

```jass
function GetDInvItemChargesByTypeThreshold takes unit u, integer itemTypeId, integer threshold returns boolean
    local integer totalCharges = 0
    local integer charges
    
    loop
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set charges = GetItemCharges(it)
            
            // CRITICAL FIX: Count items with 0 charges as 1 item
            if charges <= 0 then
                set totalCharges = totalCharges + 1  // Count as 1 item ✅
            else
                set totalCharges = totalCharges + charges
            endif
        endif
        set slotId = slotId + 1
    endloop
    
    return totalCharges >= threshold
endfunction
```

### Fix 3: RemoveDInvItemChargesByType
Treats items with 0 charges as 1 item for removal:

```jass
function RemoveDInvItemChargesByType takes unit u, integer itemTypeId, integer amountToRemove returns nothing
    local integer remainingToRemove = amountToRemove
    local integer charges
    
    loop
        set it = DInventoryDB[bid].item[slotId]
        if it != null and GetItemTypeId(it) == itemTypeId then
            set charges = GetItemCharges(it)
            
            // CRITICAL FIX: Treat items with 0 charges as 1 item
            if charges <= 0 then
                set charges = 1  // ✅ Fixed!
            endif
            
            if charges > remainingToRemove then
                call SetItemCharges(it, charges - remainingToRemove)
                set remainingToRemove = 0
                set slotId = slotId + 1
            else
                set remainingToRemove = remainingToRemove - charges  // Now properly decrements! ✅
                call DeleteBIDSlotIdItemFromDInventory(bid, slotId)
                // Don't increment - next item shifts into this slot
            endif
        else
            set slotId = slotId + 1
        endif
    endloop
endfunction
```

---

## How HeroItemCheck Now Works

### Checking for Quest Items (0 Charges):

**Before Fix:**
```jass
// Hero has: 2x Quest Key (charges = 0 each)
if HeroItemCheck(hero, 'QKEY', 2) then  // Check for 2 keys
    // Never triggers! ❌
    // GetItemCharges() = 0, so totalCharges = 0
    // 0 >= 2 is false
endif
```

**After Fix:**
```jass
// Hero has: 2x Quest Key (charges = 0 each)
if HeroItemCheck(hero, 'QKEY', 2) then  // Check for 2 keys
    // Now triggers! ✅
    // Each item counts as 1, so totalCharges = 2
    // 2 >= 2 is true
endif
```

### Checking for Potions (With Charges):

**Works both before and after:**
```jass
// Hero has: 5x Potion (charges = 5), 3x Potion (charges = 3)
if HeroItemCheck(hero, 'HPOT', 8) then
    // Triggers! ✅
    // totalCharges = 5 + 3 = 8
    // 8 >= 8 is true
endif
```

### Mixed Inventory:

**After Fix:**
```jass
// Hero has:
// - 1x Quest Key (charges = 0)
// - 1x Quest Key (charges = 0)
// - 5x Potion (charges = 5)

// Check for Quest Keys:
HeroItemCheck(hero, 'QKEY', 2)  // Returns TRUE ✅ (counts as 2)

// Check for Potions:
HeroItemCheck(hero, 'HPOT', 5)  // Returns TRUE ✅ (counts as 5)
```

---

## Removing Items Now Works Correctly

### Example 1: Remove Quest Items (0 Charges)

**Before Fix:**
```jass
// Hero has: 3x Quest Key, 2x Other Item
call RemoveDInvItemChargesByType(hero, 'QKEY', 1)  // Remove 1 key

// What happened:
// - Finds 1st Key (charges = 0)
// - remainingToRemove = 1 - 0 = 1 (still needs to remove!)
// - Deletes 1st Key
// - Finds 2nd Key (charges = 0)
// - remainingToRemove = 1 - 0 = 1 (STILL needs to remove!)
// - Deletes 2nd Key
// - Finds 3rd Key...
// - ALL QUEST KEYS DELETED! ❌
```

**After Fix:**
```jass
// Hero has: 3x Quest Key, 2x Other Item
call RemoveDInvItemChargesByType(hero, 'QKEY', 1)  // Remove 1 key

// What happens:
// - Finds 1st Key (charges = 0, treated as 1)
// - remainingToRemove = 1 - 1 = 0 ✅
// - Deletes 1st Key
// - Loop exits (remainingToRemove = 0)
// - 2 Quest Keys remain ✅ CORRECT!
```

### Example 2: Remove Multiple Quest Items

```jass
// Hero has: 5x Quest Key (charges = 0 each)
call RemoveDInvItemChargesByType(hero, 'QKEY', 3)  // Remove 3

// After Fix:
// - Removes exactly 3 Quest Keys
// - 2 Quest Keys remain ✅
```

### Example 3: Mixed Stackable/Non-Stackable

```jass
// Hero has:
// - 2x Quest Key (charges = 0)
// - 5x Potion (charges = 5)
// - 3x Potion (charges = 3)

call RemoveDInvItemChargesByType(hero, 'QKEY', 1)
// Removes 1 Quest Key ✅

call RemoveDInvItemChargesByType(hero, 'HPOT', 6)
// Removes 5 from first stack, then 1 from second stack
// Result: 2x Potion remain ✅
```

---

## Complete Usage Example

### Quest Trigger:
```jass
function QuestTurnInCondition takes nothing returns boolean
    // Check if player has 3 Quest Keys
    return HeroItemCheckBoth('QKEY', 3)
endfunction

function QuestTurnInActions takes nothing returns nothing
    // udg_DInvUnit is set by HeroItemCheckBoth to the hero that has the items
    
    // Remove the 3 Quest Keys
    call RemoveDInvItemChargesByType(udg_DInvUnit, 'QKEY', 3)
    
    // Give reward
    call CreateItemLoc('RWRD', GetUnitLoc(udg_DInvUnit))
    
    // Display message
    call DisplayTextToPlayer(GetOwningPlayer(udg_DInvUnit), 0, 0, "Quest completed!")
endfunction
```

### Works For All Item Types:
```jass
// Non-stackable quest items (charges = 0)
if HeroItemCheck(hero, 'QKEY', 5) then
    call RemoveDInvItemChargesByType(hero, 'QKEY', 5)  // Removes exactly 5 ✅
endif

// Stackable potions (charges > 0)
if HeroItemCheck(hero, 'HPOT', 10) then
    call RemoveDInvItemChargesByType(hero, 'HPOT', 10)  // Removes 10 charges ✅
endif

// Equipment (charges = 0, typically)
if HeroItemCheck(hero, 'SWRD', 1) then
    call RemoveDInvItemChargesByType(hero, 'SWRD', 1)  // Removes 1 sword ✅
endif
```

---

## Summary of Changes

### Functions Modified:

1. ✅ **GetDInvItemChargesByType**
   - Now counts 0-charge items as 1 item

2. ✅ **GetDInvItemChargesByTypeThreshold**
   - Now counts 0-charge items as 1 item

3. ✅ **RemoveDInvItemChargesByType**
   - Now treats 0-charge items as 1 item for removal
   - Prevents infinite removal loop

### Logic Change:

```jass
// OLD: Ignored items with 0 charges
if charges > 0 then
    count += charges
endif

// NEW: Counts all items
if charges <= 0 then
    count += 1  // Non-stackable items count as 1
else
    count += charges  // Stackable items count by charges
endif
```

---

## Testing Checklist

Test these scenarios:

1. ✅ **Single quest item (0 charges)**
   - Check for 1 → Returns true
   - Remove 1 → Removes exactly 1

2. ✅ **Multiple quest items**
   - Check for 3 → Returns true if 3+
   - Remove 2 → Removes exactly 2

3. ✅ **Stackable potions**
   - Check for 10 → Counts all charges correctly
   - Remove 7 → Removes 7 charges correctly

4. ✅ **Mixed inventory**
   - Quest keys + potions
   - Each counted correctly
   - Each removed correctly

5. ✅ **Edge case: Remove more than available**
   - Have 2 keys, remove 5
   - Should remove all 2, then stop ✅

---

## Files Modified

- ✅ `SharedDInvLib.j` - 3 functions updated:
  - `GetDInvItemChargesByType` (line ~4910)
  - `GetDInvItemChargesByTypeThreshold` (line ~4940)
  - `RemoveDInvItemChargesByType` (line ~2050)

---

## Related Documentation

- `FIX_APPLIED_RemoveItems_Oct2025.md` - Loop increment fix
- `FIX_APPLIED_Campaign_Item_Charges_Oct2025.md` - Campaign item display fix
- `CRITICAL_BUGFIXES_Oct2025.md` - Original swap/equip fixes
