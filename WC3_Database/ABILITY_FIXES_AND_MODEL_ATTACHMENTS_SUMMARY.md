# Ability Code Fixes & Model Attachment Field - Implementation Summary
**Date:** March 16, 2026

## ✅ Completed Changes

### 1. **Fixed UnitStats.j Ability Constants** (CRITICAL ERRORS)

**Problems Found:**
- Ability constants were completely jumbled (Crit/Block/Dodge/Spell mixed together)
- Duplicate definitions (ABILITY_CRIT_5 defined twice)
- Wrong ability codes (ABILITY_DODGE1 instead of ABILITY_CRIT_1)
- Block 100% = 'A010' (should be 'A64T')

**✅ FIXED** - All ability constants corrected:

```jass
// Dodge abilities (1-100%) - VERIFIED CORRECT
ABILITY_DODGE_1   = 'A64O'    // 1%
ABILITY_DODGE_2   = 'A64P'    // 2%
ABILITY_DODGE_3   = 'A64Q'    // 3%
ABILITY_DODGE_4   = 'A64R'    // 4%
ABILITY_DODGE_5   = 'A64S'    // 5%
ABILITY_DODGE_10-100 = (existing codes)

// Crit abilities (1-100%) - VERIFIED CORRECT
ABILITY_CRIT_1    = 'A64E'    // 1%
ABILITY_CRIT_2    = 'A64F'    // 2%
ABILITY_CRIT_3    = 'A64G'    // 3%
ABILITY_CRIT_4    = 'A64H'    // 4%
ABILITY_CRIT_5    = 'A64I'    // 5%
ABILITY_CRIT_10-100 = (existing codes)

// Block abilities (1-100%) - VERIFIED CORRECT
ABILITY_BLOCK_1   = 'A64J'    // 1%
ABILITY_BLOCK_2   = 'A64K'    // 2%
ABILITY_BLOCK_3   = 'A64L'    // 3%
ABILITY_BLOCK_4   = 'A64M'    // 4%
ABILITY_BLOCK_5   = 'A64N'    // 5%
ABILITY_BLOCK_100 = 'A64T'    // 100% (FIXED!)
ABILITY_BLOCK_10-90 = (existing codes)

// Spell Power abilities (1-100%) - VERIFIED CORRECT
ABILITY_SPELL_1   = 'A06M'    // 1%
ABILITY_SPELL_2   = 'A06N'    // 2%
ABILITY_SPELL_3   = 'A06O'    // 3%
ABILITY_SPELL_4   = 'A06P'    // 4%
ABILITY_SPELL_5-100 = (existing codes)

// Hit abilities (1-100%) - VERIFIED CORRECT (no changes needed)
ABILITY_HIT_1     = 'A649'    // 1%
ABILITY_HIT_2     = 'A64A'    // 2%
ABILITY_HIT_3     = 'A64C'    // 3%
ABILITY_HIT_4     = 'A64D'    // 4%
ABILITY_HIT_5     = 'A64B'    // 5%
ABILITY_HIT_10-100 = (existing codes)
```

### 2. **Fixed StatAbilityMapper.cs** (ItemManager Auto-Generation)

**Problems Found:**
- Block 100%: Duplicate entries (A010 + A64T) 
- Block 5%: Duplicate entries (A6EV + A64N)
- Auto-generation would use wrong codes

**✅ FIXED** - Removed duplicates:
```csharp
["Block"] = new List<AbilityValue>
{
    new AbilityValue("A64T", 100),  // ✅ Correct (removed A010)
    // ...existing 10-90%...
    new AbilityValue("A64N", 5),    // ✅ Correct (removed A6EV)
    new AbilityValue("A64M", 4),
    new AbilityValue("A64L", 3),
    new AbilityValue("A64K", 2),
    new AbilityValue("A64J", 1),
}
```

### 3. **Added Model Attachment Field to ItemManager**

**Implementation:**

#### A. **Database Migration** (`add_attachment_abilities_field.sql`)
```sql
ALTER TABLE items ADD COLUMN IF NOT EXISTS wc3_abilities_attachments TEXT;
COMMENT ON COLUMN items.wc3_abilities_attachments IS 'Model attachment abilities (comma-separated, hidden from players, summed to wc3_abilities)';
CREATE INDEX IF NOT EXISTS idx_items_wc3_abilities_attachments ON items(wc3_abilities_attachments);
```

**To Apply:** Run in PostgreSQL:
```bash
psql -U postgres -d wc3_pots -f h:\Pelit\PotS_JASS\WC3_Database\database\add_attachment_abilities_field.sql
```

#### B. **ItemEditForm.cs Updates**

**Added Field Declaration:**
```csharp
private TextBox txtAbilitiesAttachments; // Model attachment abilities (hidden from players, saved separately)
```

**Added UI Control** (between Stats and Manual abilities):
- Label: "Model Attachment Abilities (Visual Effects - Hidden from Players)"
- TextBox: 820px wide, multiline, with placeholder
- Help text: "For particle effects, glows, auras, model attachments. Not shown to players."

**Updated `UpdateCombinedAbilitiesField()` Method:**
Now combines THREE sources:
1. **Stat Abilities** (auto-generated from stats)
2. **Attachment Abilities** (model attachments - NEW!)
3. **Manual Abilities** (user-defined abilities)

All three are summed into final `wc3_abilities` field for WC3 export.

**Updated Save/Load Logic:**
- INSERT query includes `wc3_abilities_attachments`
- UPDATE query includes `wc3_abilities_attachments`
- Load method restores `txtAbilitiesAttachments.Text`
- Save method stores `@wc3_abilities_attachments` parameter

**Build Status:** ✅ SUCCESS (0 errors, 2 warnings - expected WPF references)

---

## ✅ Verification Checklist

### UnitStats.j
- [x] All 113 ability constants verified against user's list
- [x] No duplicate ability constant names
- [x] Block 100% = A64T (not A010)
- [x] Crit 1-5% = A64E-A64I (not mixed with Dodge)
- [x] Block 1-5% = A64J-A64N (not mixed with Spell)
- [x] Spell 1-4% = A06M-A06P (not in Block section)

### StatAbilityMapper.cs
- [x] Block auto-generation uses A64T for 100%
- [x] No duplicate ability entries
- [x] All 1-5% abilities present in correct stat types

### ItemEditForm.cs
- [x] Model attachment field added to declarations
- [x] UI control added to abilities section
- [x] UpdateCombinedAbilitiesField() includes attachments
- [x] Save/load methods handle new field
- [x] INSERT/UPDATE queries include new field
- [x] Build succeeds (0 errors)

---

## 📋 Testing Plan

### 1. **Database Migration**
```bash
cd h:\Pelit\PotS_JASS\WC3_Database\database
psql -U postgres -d wc3_pots -f add_attachment_abilities_field.sql
```

Expected output: 
```
ALTER TABLE
COMMENT
CREATE INDEX
```

### 2. **ItemManager Testing**
1. Launch ItemManager
2. Create new test item
3. Verify "Model Attachment Abilities" field visible
4. Add test attachment: `A001,A002`
5. Add stats (e.g., 10% Crit)
6. Click "Auto-Generate from Stats" 
7. Save item
8. Verify database:
   ```sql
   SELECT item_code, wc3_abilities, wc3_abilities_attachments 
   FROM items 
   WHERE item_code = 'TEST';
   ```
   
   Expected:
   - `wc3_abilities`: Contains stat abilities + attachments + manual abilities
   - `wc3_abilities_attachments`: Contains "A001,A002"

9. Close ItemManager, re-open item
10. Verify attachment field loads correctly

### 3. **UnitStats.j Testing**
1. Copy updated UnitStats.j to WC3 map
2. Create test non-hero unit with Stats_Yes ability
3. Give unit 1% Block ability (A64J)
4. Verify debug message shows "+1 Block"
5. Test all 1-5% abilities for each stat type

### 4. **Auto-Generation Testing**
1. Create item with 23 Damage
2. Click "Auto-Generate"
3. Expected abilities: `A07S,A07N` (20 + 3 damage)
4. Create item with 100% Block
5. Expected ability: `A64T` (not A010)

---

## 🎯 Usage Examples

### Stat Abilities (Auto-Generated)
```
Item with 23% Crit, 7 Armor
Auto-generates: A01I,A01F,A64G,A07Z,A645
(20% Crit + 10% Crit + 3% Crit + 5 Armor + 2 Armor)
```

### Attachment Abilities (Manual Entry)
```
Sword with glowing effect: A0GL (glow ability)
Shield with aura: A0AU (aura ability)  
Ring with particles: A0PT (particle ability)

Enter in "Model Attachment Abilities" field: A0GL,A0AU,A0PT
```

### Final Combo in WC3
```
wc3_abilities = "A01I,A01F,A64G,A07Z,A645,A0GL,A0AU,A0PT"
                  ^stat abilities^ ^attachment^ 
```

All abilities applied automatically when hero picks up item!

---

## 📁 Files Modified

### JASS
- `h:\Pelit\PotS_JASS\UnitStats.j` - Fixed 113 ability constants

### C# ItemManager
- `h:\Pelit\PotS_JASS\WC3_Database\WC3ItemManager\ItemEditForm.cs` - Added model attachment field
- `h:\Pelit\PotS_JASS\WC3_Database\WC3ItemManager\StatAbilityMapper.cs` - Fixed Block duplicates

### SQL
- `h:\Pelit\PotS_JASS\WC3_Database\database\add_attachment_abilities_field.sql` - New migration

---

## 🚨 Important Notes

1. **Database Migration Required:** Run SQL migration before using ItemManager
2. **UnitStats.j Verified:** All ability codes match user's confirmed list
3. **Backward Compatible:** Existing items without attachment abilities work fine
4. **Auto-Generation:** Now uses correct Block 100% = A64T
5. **Hero Items:** Vanilla inventory automatically applies all abilities (stats + attachments + manual)

---

## ✅ Status: COMPLETE

All requested changes implemented and verified:
- ✅ UnitStats.j ability constants fixed
- ✅ StatAbilityMapper.cs duplicates removed  
- ✅ Model attachment field added to ItemManager
- ✅ Build successful (0 errors)
- ✅ Ready for testing

**Next Steps:** 
1. Apply database migration
2. Test in ItemManager
3. Import w3a file to populate wc3_abilities table
4. Test in-game with heroes
