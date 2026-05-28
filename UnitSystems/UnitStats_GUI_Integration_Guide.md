# UnitStats Integration Guide

## How to Integrate with Your GUI Trigger

### Your GUI Trigger: "Init 07 Unit Event Enters"

Add this action to your trigger:

```
Init 07 Unit Event Enters
    Events
        Unit - A unit enters (Playable map area)
    Conditions
    Actions
        -------- === CRITICAL!!! === --------
        -------- Absolutely only use this trigger to Run this event related triggers! --------
        -------- === EVENTS --------
        -------- ------------------  Creep Respawn System - Only run on map start to get all pre-placed units --------
        Trigger - Run Creep Init Respawn <gen> (checking conditions)
        -------- ------------------ Floating Texts Spell Events --------
        Trigger - Add to Floating Texts Spell Event <gen> the event (Unit - (Triggering unit) Starts the effect of an ability)
        -------- ------------------ UnitStats System (NEW!) --------
        Custom script: call UnitStats_ProcessUnit(GetTriggerUnit())
```

### Alternative: Create a Separate UnitStats Trigger

If you prefer to keep triggers organized:

```
UnitStats - Process Unit
    Events
        Unit - A unit enters (Playable map area)
    Conditions
    Actions
        Custom script: call UnitStats_ProcessUnit(GetTriggerUnit())
```

---

## What Changed

### Before (Internal Events):
- UnitStats.j registered its own unit spawn events
- Created its own triggers internally
- More complex initialization

### After (External Integration):
- UnitStats.j provides a simple function: `UnitStats_ProcessUnit(unit)`
- You call it from your existing spawn trigger
- Cleaner separation of concerns
- Better integration with your existing event system

---

## Function Reference

### Main Function (call from your trigger):
```jass
call UnitStats_ProcessUnit(GetTriggerUnit())
```
- Processes the unit's stats if it has the `Stats_Yes` ability
- Automatically skips if already processed
- Safe to call multiple times (won't duplicate stats)

### Optional Functions:

```jass
// Force reprocess a unit (if stats changed)
call UnitStats_RefreshUnit(unit)

// Enable debug messages
call UnitStats_SetDebugEnabled(true)

// Get count of processed units
local integer count = UnitStats_GetProcessedCount()

// Manually trigger initial scan (if needed)
call UnitStats_InitialScan()
```

---

## Automatic Processing

### Pre-placed Units:
The system automatically scans for pre-placed units with `Stats_Yes` ability 2 seconds after map initialization. No action needed!

### Spawned Units:
Just add the custom script call to your spawn trigger (shown above).

---

## Performance

### No Lag!
- ✅ No periodic scanning
- ✅ Each unit processed only once
- ✅ Instant processing on spawn
- ✅ Zero FPS impact after initialization

### Debug Verification:
Enable debug to see it working:
```jass
call UnitStats_SetDebugEnabled(true)
```

You'll see messages like:
```
[UnitStats] ===== OPTIMIZED SYSTEM INITIALIZED =====
[UnitStats] Event-driven processing (NO periodic lag!)
[UnitStats] Initial scan for pre-placed units in 2.0 seconds
[UnitStats] Processed unit #1: Grunt
[UnitStats] Processed unit #2: Footman
```

---

## Summary

**In your GUI trigger, just add:**
```
Custom script: call UnitStats_ProcessUnit(GetTriggerUnit())
```

That's it! The system handles everything else automatically.
