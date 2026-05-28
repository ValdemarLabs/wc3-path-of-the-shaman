# Unit Death Event - Centralized Event System

## The Problem

Warcraft 3 has internal limits on event registrations:
- **Maximum trigger registrations** across all systems
- **Event processing overhead** when many systems listen to the same event
- **Unreliable event firing** when limits are exceeded

### What Was Happening

Multiple systems were independently registering `EVENT_PLAYER_UNIT_DEATH`:
- **Reputation System**: Registered for all 24 players (24 registrations)
- **PatrolSystem**: Registered for all 24 players (24 registrations)  
- **UnitExperience**: Registered for all 24 players (24 registrations)
- **Other systems**: Additional registrations
- **GUI Triggers**: Even more registrations

**Total**: 100+ death event registrations overwhelming the engine!

## The Solution

Created `UnitDeathEvent.j` - a **centralized death event dispatcher**:

1. **Single Registration**: Only ONE death trigger registers for all 24 players (24 total registrations)
2. **Callback System**: Other systems register callback functions instead of event listeners
3. **Reliable Dispatch**: All registered callbacks are called when ANY unit dies
4. **Better Performance**: Reduced overhead and guaranteed event capture

## Architecture

```
Unit Dies
    ↓
[UnitDeathEvent] ← Single EVENT_PLAYER_UNIT_DEATH registration (all 24 players)
    ↓
Dispatches to registered callbacks:
    ├─→ Reputation_OnUnitDeath()
    ├─→ PatrolSystem OnDeath()
    ├─→ UnitExperience OnDeath()
    └─→ [Your System OnDeath()]
```

## Usage

### For New Systems

```jass
library YourSystem initializer Init requires UnitDeathEvent

private function OnUnitDeath takes nothing returns nothing
    local unit killer = GetKillingUnit()
    local unit victim = GetDyingUnit()
    
    // Your death handling logic here
endfunction

private function Init takes nothing returns nothing
    // Register with centralized death event
    call UnitDeathEvent_Register(function OnUnitDeath)
endfunction

endlibrary
```

### For Existing Systems

1. Add `UnitDeathEvent` to library requirements
2. Remove all `TriggerRegisterPlayerUnitEvent` calls for death
3. Replace with `call UnitDeathEvent_Register(function YourCallback)`

## Systems Updated

✅ **Reputation System** - Now uses centralized event  
✅ **PatrolSystem** - Now uses centralized event  
⚠️ **UnitExperience** - Needs update  
⚠️ **Other systems** - Check for `EVENT_PLAYER_UNIT_DEATH` and migrate

## Benefits

- ✅ **Reliability**: Events fire consistently
- ✅ **Performance**: Reduced event processing overhead
- ✅ **Scalability**: Can add unlimited callbacks (up to MAX_CALLBACKS = 50)
- ✅ **Maintainability**: Single point of control for death events
- ✅ **Debugging**: Easier to track death events with centralized logging

## Migration Checklist

- [ ] Find all `EVENT_PLAYER_UNIT_DEATH` registrations in your code
- [ ] Update each system to use `UnitDeathEvent_Register`
- [ ] Remove old trigger registrations
- [ ] Test that all death-dependent features still work
- [ ] Remove debug messages once confirmed working

## Debug Output

When enabled, you'll see:
```
[UnitDeathEvent] Centralized death event system initialized for all 24 players
[UnitDeathEvent] Registered callback #1 for unit death events
[UnitDeathEvent] Registered callback #2 for unit death events
[Reputation] Registered with centralized death event system.
[PatrolSystem] Initialized and registered with UnitDeathEvent
```

## Notes

- The centralized system MUST initialize before any system that depends on it
- Add `UnitDeathEvent` to library requirements to ensure proper initialization order
- Maximum 50 callbacks supported (increase MAX_CALLBACKS if needed)
- The public function `UnitDeathEvent_Register` can be called from anywhere
