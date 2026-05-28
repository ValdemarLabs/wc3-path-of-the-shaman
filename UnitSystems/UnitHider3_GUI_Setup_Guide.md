# UnitHider3 - GUI Trigger Setup Guide

## ✅ **GOOD NEWS: System Auto-Starts!**

The library has `initializer Init` which means it **automatically starts** when the map loads.

You do **NOT** need to call `UnitHider_StartHideUnitsSystem()` (but you can if you want).

---

## 🎯 **What You MUST Do:**

### **Add Units to Reference Groups**

The system needs to know which units define the visibility range (usually heroes, camera units, etc.)

### **Option 1: GUI Trigger (Recommended for Beginners)**

Create a trigger like this in World Editor:

```
Trigger: UnitHider Setup
    Events:
        Map initialization
    Conditions:
    Actions:
        ---- Add your hero units to the reference group ----
        Unit Group - Add (Your Hero 0001 <gen>) to udg_UnitHider_ReferenceGroup
        Unit Group - Add (Player 1 (Red)'s hero) to udg_UnitHider_ReferenceGroup
        
        ---- Optional: Add units that should NEVER be hidden ----
        Unit Group - Add (Quest Giver NPC 0001 <gen>) to udg_UnitHider_IgnoredUnits
        
        ---- Optional: Enable debug to see performance ----
        Custom script: call UnitHider_SetDebugEnabled(true)
        
        ---- Optional: Change hiding distance (default is 5500) ----
        Custom script: call UnitHider_SetHidingDistance(4000.0)
```

### **Option 2: JASS Trigger**

```jass
function InitUnitHider takes nothing returns nothing
    // Add hero units as reference points
    call GroupAddUnit(udg_UnitHider_ReferenceGroup, gg_unit_Hamg_0001)
    call GroupAddUnit(udg_UnitHider_ReferenceGroup, udg_PlayerHero[1])
    
    // Add units that should never be hidden
    call GroupAddUnit(udg_UnitHider_IgnoredUnits, gg_unit_Hpal_0023)
    
    // Optional: Enable debug
    call UnitHider_SetDebugEnabled(true)
    
    // Optional: Change distance
    call UnitHider_SetHidingDistance(4000.0)
endfunction

function InitTrig_UnitHider_Setup takes nothing returns nothing
    local trigger t = CreateTrigger()
    call TriggerRegisterTimerEvent(t, 0.1, false)
    call TriggerAddAction(t, function InitUnitHider)
endfunction
```

---

## 📋 **Required Global Variables**

You must create these in World Editor → Trigger Editor → Variables:

### **1. udg_UnitHider_ReferenceGroup**
- **Type:** Unit Group
- **Initial Value:** Empty unit group
- **Purpose:** Units that define visibility (heroes, camera follows)
- **Array:** No

### **2. udg_UnitHider_IgnoredUnits**
- **Type:** Unit Group  
- **Initial Value:** Empty unit group
- **Purpose:** Units that should NEVER be hidden (quest NPCs, bosses, etc.)
- **Array:** No

---

## 🎮 **Complete Setup Example (GUI)**

### **Step 1: Create Variables**
In Trigger Editor → Variables (Ctrl+B):
1. New Variable → Name: `UnitHider_ReferenceGroup`, Type: `Unit Group`
2. New Variable → Name: `UnitHider_IgnoredUnits`, Type: `Unit Group`

### **Step 2: Create Initialization Trigger**
```
Trigger Name: Initialize UnitHider
    Events
        Map initialization
    Conditions
    Actions
        ---- Wait a moment for other systems ----
        Wait 0.10 seconds
        
        ---- Add heroes to reference group ----
        Unit Group - Add (Hero 0001 <gen>) to UnitHider_ReferenceGroup
        
        ---- If you create heroes dynamically, add them when created ----
        ---- For example, in your "Create Hero" trigger:
        ---- Unit Group - Add (Last created unit) to UnitHider_ReferenceGroup
        
        ---- Add important NPCs to ignored list ----
        Unit Group - Add (Quest NPC 0001 <gen>) to UnitHider_IgnoredUnits
        Unit Group - Add (Shop Keeper 0001 <gen>) to UnitHider_IgnoredUnits
        
        ---- Enable debug to verify it's working ----
        Custom script: call UnitHider_SetDebugEnabled(true)
        
        ---- Optional: Adjust distance ----
        Custom script: call UnitHider_SetHidingDistance(5500.0)
        
        Game - Display to (All players) the text: |cff00ff00UnitHider3 initialized!|r
```

### **Step 3: Add Dynamic Heroes**
If you create heroes during gameplay:
```
Trigger Name: Create Player Hero
    Events
        Unit - A unit enters (Playable map area)
    Conditions
        ((Triggering unit) is A Hero) Equal to True
    Actions
        ---- Add newly created hero to reference group ----
        Unit Group - Add (Triggering unit) to UnitHider_ReferenceGroup
```

---

## ⚙️ **Optional Configuration Functions**

You can call these from Custom Script actions in GUI:

### **Enable/Disable Debug**
```jass
call UnitHider_SetDebugEnabled(true)   // Show debug messages
call UnitHider_SetDebugEnabled(false)  // Hide debug messages
```

### **Change Hiding Distance**
```jass
call UnitHider_SetHidingDistance(3000.0)  // Smaller = hide more
call UnitHider_SetHidingDistance(8000.0)  // Larger = hide less
```

### **Enable/Disable System**
```jass
call UnitHider_SetSystemEnabled(true)   // Turn on
call UnitHider_SetSystemEnabled(false)  // Turn off (unhides all)
```

### **Manual Start (optional)**
```jass
call UnitHider_StartHideUnitsSystem()  // Not needed but doesn't hurt
```

---

## 🔍 **Verifying It Works**

### **Step 1: Enable Debug**
```jass
call UnitHider_SetDebugEnabled(true)
```

### **Step 2: Start Game**
You should see messages like:
```
[UnitHider3] Initialized - Interval: 0.50s, Distance: 5500.0
[UnitHider3] Starting visibility check...
[UnitHider3] Stats - Checked: 52 | Hidden: 8 | Shown: 3 | Total Hidden: 245
```

### **Step 3: Check Values**
- **Checked:** Should be 50-150 (NOT 400-500!)
- **Hidden:** Units hidden this cycle
- **Shown:** Units shown this cycle
- **Total Hidden:** Current count of hidden units

### **If You See Problems:**

#### **Problem:** "Checked: 0" or nothing happens
**Solution:** Reference group is empty!
```jass
// Make sure you added units:
call GroupAddUnit(udg_UnitHider_ReferenceGroup, yourHero)
```

#### **Problem:** "Checked: 500" (too many)
**Solution:** Reference group is empty! Filter can't work without reference units.

#### **Problem:** All units disappear
**Solution:** Reference units are in the reference group, right? Heroes should be there!

---

## 📝 **Minimal Working Example**

The **absolute minimum** you need:

```
Trigger: UnitHider Minimal Setup
    Events
        Map initialization
    Actions
        Wait 0.10 seconds
        Unit Group - Add (Your Hero) to UnitHider_ReferenceGroup
        Custom script: call UnitHider_SetDebugEnabled(true)
```

That's it! The system starts automatically, you just need to add hero units to the reference group.

---

## 🎓 **Understanding Reference vs Ignored Groups**

### **Reference Group (udg_UnitHider_ReferenceGroup)**
- **Purpose:** Defines WHERE units are visible
- **Example:** Hero units, camera follows
- **Effect:** Units within 5500 range of ANY reference unit will be visible

### **Ignored Group (udg_UnitHider_IgnoredUnits)**
- **Purpose:** Units that should NEVER be hidden
- **Example:** Quest NPCs, shop keepers, important story units
- **Effect:** These units stay visible regardless of distance

### **Example:**
```
Reference Group: [Hero 1] [Hero 2] [Camera Unit]
Ignored Group:   [Quest NPC] [Shop Keeper] [Final Boss]

Result:
- Units near Hero 1, Hero 2, or Camera Unit = Visible
- Quest NPC, Shop Keeper, Final Boss = Always Visible
- All other units far away = Hidden
```

---

## ⚡ **Quick Checklist**

- [ ] Created variable: `UnitHider_ReferenceGroup` (Unit Group)
- [ ] Created variable: `UnitHider_IgnoredUnits` (Unit Group)
- [ ] Created initialization trigger with Map Initialization event
- [ ] Added hero units to reference group
- [ ] (Optional) Added quest NPCs to ignored group
- [ ] (Optional) Enabled debug mode
- [ ] Tested in-game
- [ ] Verified "Checked" value is 50-150
- [ ] Verified units hide/show properly
- [ ] Disabled debug mode for release

---

## 🚀 **Advanced: Dynamic Reference Units**

If you want to add/remove reference units during gameplay:

### **Add Reference Unit**
```jass
call GroupAddUnit(udg_UnitHider_ReferenceGroup, newHero)
```

### **Remove Reference Unit**
```jass
call GroupRemoveUnit(udg_UnitHider_ReferenceGroup, oldHero)
```

### **Example: When Hero Dies**
```
Trigger: Hero Dies
    Events
        Unit - A unit Dies
    Conditions
        (Dying unit) is in UnitHider_ReferenceGroup Equal to True
    Actions
        ---- Remove dead hero from reference group ----
        Unit Group - Remove (Dying unit) from UnitHider_ReferenceGroup
```

### **Example: When Hero Revives**
```
Trigger: Hero Revives
    Events
        Unit - A unit Is revived
    Conditions
        ((Revived unit) is A Hero) Equal to True
    Actions
        ---- Add revived hero back to reference group ----
        Unit Group - Add (Revived unit) to UnitHider_ReferenceGroup
```

---

## 📊 **Performance Tips**

1. **Don't add too many reference units** (limit: 20 by default)
   - More references = more distance calculations
   - Usually 1-4 heroes is enough

2. **Use ignored group wisely**
   - Only add units that MUST always be visible
   - Don't add hundreds of units to ignored group

3. **Adjust distance based on your needs**
   - Smaller distance = hide more units = better performance
   - Larger distance = more visible units = worse performance

---

## ❓ **FAQ**

**Q: Do I need to call UnitHider_StartHideUnitsSystem()?**
A: No, it auto-starts. But calling it doesn't hurt.

**Q: When should I add units to reference group?**
A: At map init, or when you create/select heroes dynamically.

**Q: Can I change settings during gameplay?**
A: Yes! All UnitHider_Set* functions work at runtime.

**Q: What if I don't add ANY reference units?**
A: System will hide ALL units (filter can't work without references).

**Q: Can I use camera position instead of units?**
A: You'd need to create dummy units at camera position and add them to reference group.

---

**Bottom Line:** The system auto-starts. You just need to add hero units to `udg_UnitHider_ReferenceGroup` at map initialization!
