# AIRoutines Hidden-Unit Policy Plan

## Metadata

- **Candidate ID:** PERF-008
- **Priority:** P3 conditional
- **Status:** planned; blocked on AIRoutines isolation showing material CPU cost
- **Bundle ID:** AI-LOD-01
- **Prerequisite:** isolated AI/AIRoutines benchmark and routine classification
- **Hard dependencies:** `AI/AIRoutines.j`, `AI/AI.j` only if shared contracts change
- **Behavioral dependencies:** UnitHider, quests, patrols, escorts, ambient NPC definitions and World Editor registrations
- **Shared files:** AI diagnostics and all routine definitions opting in
- **Can ship independently:** yes as a complete AI-LOD-01 bundle

## Evidence and scope

AIRoutines uses a 0.50-second tick (`AIR_TICK_INTERVAL` near line 185) and already starts/stops its timer based on active registrations around lines 355-424. The periodic loop at lines 1805-1814 processes every active unit. `AIR_ProcessUnit` skips missing, dead, leaving, paused and sleeping units but does not generally skip units hidden by UnitHider.

Main `AI.j` already rejects hidden units in important processing paths, including the heavy and lightweight instance loops around lines 6863 and 7070. A broad AI rewrite is therefore out of scope.

This plan may reduce ambient simulation/order CPU work. Hiding alone does not prove that pausing a routine is safe or that Warcraft pathfinding/animation cost has stopped.

Relevant active build 24342 contract:

```jass
constant native IsUnitHidden takes unit whichUnit returns boolean
```

## Gate 1: measure and classify

1. Capture AIRoutines enabled/disabled in an ambient-NPC stress scene using separate reloads.
2. Count units processed, hidden units processed, step transitions, orders and callbacks.
3. Inventory every production routine and classify it:
   - decorative and safely pausable;
   - must advance time but can suppress visual work;
   - gameplay/quest/patrol/escort/persistent and never pausable;
   - unknown, defaulting to never pausable.
4. Stop if the isolated cost does not meet the shared threshold.

## Minimal opt-in design

Only after Gate 1 passes:

1. Add a per-routine boolean such as `pauseWhileHidden`, default false.
2. Add one public setter for authors; do not change existing routine creation signatures.
3. In `AIR_ProcessUnit`, skip step advancement only when the owning routine opted in and `IsUnitHidden(whichUnit)` is true.
4. On reveal, resume from the previously stored next-time/step state. Do not replay missed callbacks or batch orders.
5. Keep sleep behavior separate: AIRoutines itself may hide sleeping units and already records their prior hidden state.
6. Do not add a direct UnitHider library requirement, avoiding a dependency cycle; use engine hidden state and joint regression tests.

If a routine must preserve elapsed timing, it is not eligible for this first implementation.

## Safety tests

- Decorative villagers pause/reveal without order storms.
- Shopkeepers, quest receivers, patrols, escorts, callbacks and managed turnover remain default false.
- Combat, attacked-unit wake behavior, death/removal, sleep and zone activation.
- UnitHider disable/enable, cinematic begin/end and teleport reveal.
- Save/load or map transition state where routines persist.
- Two-client routine progression and visible unit positions remain synchronized.

## Acceptance criteria

- Only explicitly classified decorative routines opt in.
- No gameplay-critical routine, callback or turnover timer is delayed.
- Reveal produces no burst of missed orders or callbacks.
- At least 5% CPU frame-time or 1%-low improvement in the hidden ambient-NPC stress scene.
- Default behavior for every existing routine is byte-for-byte equivalent at the API level and functionally unchanged.

## Rollback

Remove all opt-ins, setter and hidden check; because default is false, a staged rollback may first disable every opt-in before reverting source.

Suggested commit: `Pause opted-in ambient routines while hidden`.

