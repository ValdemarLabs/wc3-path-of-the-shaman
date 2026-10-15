# Storm Idle Timer Gating Plan

## Metadata

- **Candidate ID:** PERF-005
- **Priority:** P2
- **Status:** planned; expected impact small and `NOT_MEASURED`
- **Bundle ID:** STORM-01
- **Prerequisite:** idle callback counter
- **Hard dependencies:** `EnvironmentSystems/Stormv2.j`
- **Behavioral dependencies:** WeatherSystem, FogSystem and ZoneEvent fog restoration
- **Shared files:** weather diagnostics only if a command is added
- **Can ship independently:** yes while the Storm public API remains unchanged

## Evidence and mechanism

`Stormv2.j:156` defines a 0.03125-second period. Its static timer and `ActiveStorms` are declared around lines 266-267. Creation increments `ActiveStorms` around line 439, destruction decrements it around lines 281-293, but `onInit` starts the repeating timer permanently at lines 445-446.

The periodic method reads local fog state and evaluates storm/fog transitions before looping active instances. When no storm exists this is a permanent high-frequency CPU callback, although the expected scene-level gain may be small.

Relevant active build 24342 contracts:

```jass
native TimerStart takes timer whichTimer, real timeout, boolean periodic, code handlerFunc returns nothing
native PauseTimer takes timer whichTimer returns nothing
```

## Minimal design

Preserve every public Storm function and storm/fog behavior.

1. Add private `TimerRunning` state next to the timer.
2. Add a private start helper that starts the timer only when transitioning from zero to one active storm.
3. Call the start helper after the new instance is fully initialized and added.
4. When destruction reduces `ActiveStorms` to zero, complete all current fog restoration/end-override work, then pause the timer and clear `TimerRunning`.
5. Do not start the periodic timer from `onInit`; initialize only stable state there.
6. Ensure a storm created after a fully idle period restarts the same timer.
7. Keep helper definitions before their first direct call or use private static methods in declaration-safe order.

Do not destroy and recreate the timer. Pausing retains a simple lifecycle and avoids timer-handle churn.

## Edge cases

- Two or more overlapping storms ending on different ticks.
- Destruction invoked from inside the timer callback.
- A new storm created immediately after the last one ends.
- Local and synchronized imitation variants.
- Fog override active when the final instance is removed.
- WeatherSystem disabling/re-enabling thunder or transitioning zones.

## Instrumentation and benchmark

Count total callbacks and callbacks with `ActiveStorms == 0`. Control should show idle callbacks; candidate must show zero after initialization and after the final storm cleanup.

Benchmark a CPU-bound idle scene for at least five minutes and separately exercise repeated storm start/end cycles. Do not accept solely because the callback count reaches zero; require a scene-level result outside measurement noise.

## Acceptance criteria

- Zero periodic callbacks while `ActiveStorms == 0` after cleanup.
- Storm animation, thunder, local sound and fog are identical during active storms.
- Fog override begins once and ends/restores once across overlapping storms.
- Repeated idle/start/stop cycles work without a missed restart.
- A measurable CPU-frame-time improvement is present in the idle stress capture; otherwise reject as a micro-optimization.

## Rollback

Restore the unconditional `TimerStart` in `onInit`, remove running state/helpers and confirm fog restoration after overlapping storms.

Suggested commit: `Pause the Storm timer while idle`.

