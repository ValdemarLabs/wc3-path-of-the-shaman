# Ability Debug Display Feature

## Feature Overview

Added a debug display in the Item Edit window to show ability names alongside their codes, helping verify that auto-generated abilities are correct.

## UI Changes

### Before (without debug display):
```
Abilities (comma-separated):
┌────────────────────────────────────────────────────────────┐
│ A04K, A01H, A6D7                                           │
└────────────────────────────────────────────────────────────┘
Example: AIx2,AId1 | Note: Stat abilities are AUTO-GENERATED...
```

### After (with debug toggle):
```
Abilities (comma-separated):  [🔄 Auto-Generate] [🔍 Show Ability Names]
┌────────────────────────────────────────────────────────────┐
│ A04K, A01H, A6D7                                           │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐ (when toggled)
│ 📋 Debug: 3 abilities                                      │
│ ────────────────────────────────────────────────────────── │
│ ✓  A04K   → Stats_Hit                         (20 %)      │
│ ✓  A01H   → Stats_Crit                        (15 %)      │
│ ✓  A6D7   → (No Name)                    (+10 Strength)   │
└────────────────────────────────────────────────────────────┘

Example: AIx2,AId1 | Note: Stat abilities are AUTO-GENERATED...
```

## Features

### ✅ Real-time Updates
- Debug display updates automatically when ability codes change
- No manual refresh needed

### 🎨 Color-Coded Status
- **Green ✓**: Ability found in database
- **Orange ⚠**: Ability found but has no name
- **Red ❌**: Ability code NOT FOUND in database

### 🔍 Detailed Information
Shows for each ability:
- **Code**: The 4-character ability code (e.g., A04K)
- **Name**: Ability name from database (e.g., Stats_Hit)
- **Suffix**: Editor suffix showing the value (e.g., (20 %))

### 🔘 Toggle On/Off
- Checkbox: "🔍 Show Ability Names (Debug)"
- Unchecked (default): Debug panel hidden, clean UI
- Checked: Debug panel visible, shows all ability details

## Use Cases

### 1. Verify Auto-Generated Abilities
After clicking "Auto-Generate from Stats":
```
Stats: Hit 25%, Crit 15%, Str +10
↓ [Auto-Generate]
Abilities: A04L, A01H, A6D7
↓ [Toggle Debug]
✓  A04L   → Stats_Hit    (25 %)  ← Correct!
✓  A01H   → Stats_Crit   (15 %)  ← Correct!
✓  A6D7   → (No Name)    (+10 Strength) ← Correct!
```

### 2. Debug Typos
```
Abilities: A04K, A01Z, ABCD  ← User made typo

Debug displays:
✓  A04K   → Stats_Hit (20 %)
❌ A01Z   → ⚠ NOT FOUND  ← Error! Should be A01H
❌ ABCD   → ⚠ NOT FOUND  ← Invalid code
```

### 3. Check Ability Values
Quickly verify what bonus each ability provides without switching windows:
```
✓  A04K   → Stats_Hit         (20 %)  ← This gives 20% hit
✓  A04L   → Stats_Hit         (25 %)  ← This gives 25% hit
✓  A01I   → Stats_Crit        (20 %)  ← This gives 20% crit
```

## Technical Implementation

### Database Query
For each ability code, queries:
```sql
SELECT ability_name, editor_suffix 
FROM wc3_abilities 
WHERE ability_code = @code
```

### Performance
- Queries run only when debug panel is visible
- Efficient: Only queries codes that are actually in the text field
- Cached display until abilities change

### Safety
- Read-only display (cannot accidentally modify)
- Handles missing/invalid codes gracefully
- No impact on save operation (debug display is visual only)

## Workflow Example

```
1. User opens Item Edit window
2. User adds stats:
   - Hit Chance: 20
   - Critical Strike: 15
   
3. User clicks "🔄 Auto-Generate from Stats"
   → Abilities field populated: A04K, A01H
   
4. User checks "🔍 Show Ability Names (Debug)"
   → Debug panel appears:
      ✓  A04K   → Stats_Hit    (20 %)
      ✓  A01H   → Stats_Crit   (15 %)
   
5. User verifies abilities are correct
   
6. User unchecks debug toggle (optional)
   → Panel hides, clean UI
   
7. User saves item
   → Abilities stored in database
```

## Benefits

✅ **Instant Verification**: No need to look up ability codes manually  
✅ **Error Detection**: Immediately spot invalid or typo'd codes  
✅ **Learning Tool**: See what each ability code actually does  
✅ **Non-Intrusive**: Toggle on/off to keep UI clean  
✅ **Production Safe**: Debug display has no effect on item data  

## Layout Details

### Positioning
- **Checkbox**: Top-right of abilities section, next to auto-generate button
- **Debug Panel**: Directly below abilities text field
- **Height**: 80px (shows ~4-5 abilities without scrolling)
- **Background**: Light yellow (#FAFAD2) to distinguish from normal fields
- **Font**: Monospace for aligned columns

### Size Adjustments
- Reduced abilities text field from 100px to 60px height
- Added 80px debug panel (hidden by default)
- Total height increase: ~25px when visible (compressed abilities field)

## Files Modified

- ✅ `ItemEditForm.cs`: Added checkbox, debug panel, update method
- ✅ Compiles successfully with 0 errors
- ✅ All existing functionality preserved
