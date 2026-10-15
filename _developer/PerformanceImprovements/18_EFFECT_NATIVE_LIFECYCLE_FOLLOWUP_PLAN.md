# Special-Effect Native and Lifecycle Follow-up Plan

## Metadata

- **Candidate ID:** PERF-009
- **Priority:** P3 conditional
- **Status:** planned; no broad conversion authorized without profiling
- **Bundle ID:** EFFECTS-01
- **Prerequisite:** effect-count and hot-callsite profile after higher-priority candidates
- **Hard dependencies:** `SpecialEffects/SpeciFX.j`; affected callers only if public behavior changes
- **Behavioral dependencies:** weather, combat abilities, projectiles, terrain alignment and attached effects
- **Shared files:** `SpeciFX.j` is widely consumed and must not be edited concurrently by multiple plans
- **Can ship independently:** yes only when the public API remains unchanged

## Current evidence

PotS already uses combined `BlzSetSpecialEffectPosition` in `SpeciFX` extended placement paths and `BlzSetSpecialEffectOrientation` in multiple active gameplay systems. There is no repository-wide opportunity to mechanically replace all component setters.

`SpeciFX_ConfigureEffect` around lines 850-865 can call yaw/pitch/yaw/roll setters separately, but it is configuration-oriented and not established as a hot path. It also supports partial updates through negative sentinel arguments, so a combined orientation call is not automatically equivalent.

Active build 24342 provides:

```jass
native BlzSetSpecialEffectAlpha takes effect whichEffect, integer alpha returns nothing
native BlzSetSpecialEffectPosition takes effect whichEffect, real x, real y, real z returns nothing
native BlzSetSpecialEffectOrientation takes effect whichEffect, real yaw, real pitch, real roll returns nothing
native DestroyEffect takes effect whichEffect returns nothing
native BlzRemoveEffect takes effect whichEffect returns nothing
```

The semantics and lifecycle differences of `BlzRemoveEffect` are unverified. It must not be substituted for `DestroyEffect` based on naming.

## Investigation gate

1. Count effect creation, destruction and transform calls by owning system in combat, village, weather and cinematic scenes.
2. Identify callsites that update the same effect multiple times per tick.
3. Rank by actual calls per second multiplied by active effect count.
4. Exclude one-time setup/configuration unless it causes a measured load spike.
5. Stop if no callsite meets the shared performance threshold when disabled or simplified.

## Allowed minimal changes

- Replace X/Y/Z clusters with `BlzSetSpecialEffectPosition` only when all three values are known together and semantics match.
- Replace yaw/pitch/roll clusters with `BlzSetSpecialEffectOrientation` only when all components are intentionally set together.
- Cache an unchanged transform only when measurement shows a genuinely hot repeated setter.
- Change lifecycle/pooling only for a single profiled effect family with deterministic cleanup and a direct A/B comparison.

Preserve the public SpeciFX API. If a public contract must change, update every affected caller in the same EFFECTS-01 bundle.

## Required micro-tests

- radians, axis order and orientation equivalence;
- terrain-aligned Z and local effect Z behavior;
- attached versus point effects;
- animation, scale, alpha and time state after combined transforms;
- `DestroyEffect` versus `BlzRemoveEffect` visual lifetime, handle validity, attachment cleanup and multiplayer behavior on 24342/24360.

## Acceptance criteria

- Exact visual and lifecycle parity for the selected effect family.
- No leaked handles or retained SpeciFX registry entries over a 30-minute soak.
- At least 5% CPU frame-time or 10% p99 improvement in the callsite-specific stress scene; a faster microbenchmark alone is insufficient.
- No mechanical repository-wide conversion.

## Rollback

Restore the original setters/lifecycle for the single candidate family and verify registry cleanup. Do not retain a compatibility wrapper that adds overhead after rejection.

Suggested commit: `Optimize profiled special-effect transforms`.

