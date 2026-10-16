# DE Performance Implementation Index

This index splits the read-only DE performance audit into isolated, reversible implementation plans. The source specification remains `PotS_DE_Performance_Optimization_Audit_Plan.json`; do not edit it while executing these plans.

No candidate is considered successful until its isolated benchmark passes. Algorithmic work reduction is evidence for testing, not proof of an FPS improvement.

## Status vocabulary

- `planned`: design is ready; no source implementation or runtime result exists.
- `implemented`: source exists, but compile, correctness, or performance acceptance gates remain pending.
- `experimenting`: an isolated branch/build is under measurement.
- `accepted`: correctness gates and the candidate's performance threshold passed.
- `rejected`: measured benefit was insufficient or correctness/visual gates failed.
- `rolled back`: an accepted change was removed after integration regression.
- `blocked`: required source, tooling, or external validation is unavailable.

## Plan register

| Order | Candidate | Priority | Status | Bundle | Independently shippable | Plan |
|---:|---|---|---|---|---|---|
| 0 | Shared benchmark protocol | P0 | planned | FOUNDATION-01 | No; prerequisite | [01_SHARED_BENCHMARK_PROTOCOL.md](01_SHARED_BENCHMARK_PROTOCOL.md) |
| 0 | Active API baseline correction | P0 | planned | FOUNDATION-01 | Yes | [02_ACTIVE_API_BASELINE_24342_PLAN.md](02_ACTIVE_API_BASELINE_24342_PLAN.md) |
| 0 | Performance diagnostics harness | P0 enabling | planned | DIAGNOSTICS-01 | Yes, but extend atomically with consumers | [03_PERFORMANCE_DIAGNOSTICS_HARNESS_PLAN.md](03_PERFORMANCE_DIAGNOSTICS_HARNESS_PLAN.md) |
| 1 | PERF-001 Destructable differential updates | P0 | implemented; `NOT_MEASURED` | DESTRUCTABLE-01 | Yes | [10_DESTRUCTIBLE_HIDER_DIFFERENTIAL_PLAN.md](10_DESTRUCTIBLE_HIDER_DIFFERENTIAL_PLAN.md) |
| 2 | PERF-002 Dynamic Far Z ceilings | P1 | implemented; `NOT_MEASURED` | CAMERA-01 | Yes as a complete camera bundle | [11_DYNAMIC_FARZ_PROFILE_CEILINGS_PLAN.md](11_DYNAMIC_FARZ_PROFILE_CEILINGS_PLAN.md) |
| 3 | PERF-004 Doodad backend evaluation | P1 experiment | planned | DOODAD-01 | Yes as a complete doodad bundle | [13_DOODAD_RENDER_BACKEND_EVALUATION_PLAN.md](13_DOODAD_RENDER_BACKEND_EVALUATION_PLAN.md) |
| 4 | PERF-003 UnitHider fast group copying | P1 | implemented; `NOT_MEASURED` | UNIT-HIDER-01 | Yes | [12_UNIT_HIDER_FAST_GROUP_COPY_PLAN.md](12_UNIT_HIDER_FAST_GROUP_COPY_PLAN.md) |
| 5 | PERF-005 Storm idle timer gating | P2 | planned | STORM-01 | Yes while public behavior is unchanged | [14_STORM_IDLE_TIMER_GATING_PLAN.md](14_STORM_IDLE_TIMER_GATING_PLAN.md) |
| 6 | PERF-006 Weather rain-effect budget | P2 conditional | planned | WEATHER-01 | Yes as a complete weather bundle | [15_WEATHER_RAIN_EFFECT_BUDGET_PLAN.md](15_WEATHER_RAIN_EFFECT_BUDGET_PLAN.md) |
| 7 | PERF-007 Rebirth asset complexity | P2 research | planned | ASSET-01 | Yes; World Editor work is manual | [16_REBIRTH_ASSET_COMPLEXITY_PLAN.md](16_REBIRTH_ASSET_COMPLEXITY_PLAN.md) |
| 8 | PERF-008 hidden AIRoutines policy | P3 conditional | planned | AI-LOD-01 | Yes as a complete AI bundle | [17_AI_HIDDEN_ROUTINE_POLICY_PLAN.md](17_AI_HIDDEN_ROUTINE_POLICY_PLAN.md) |
| 9 | PERF-009 effect native/lifecycle follow-up | P3 conditional | planned | EFFECTS-01 | Yes only with unchanged public API | [18_EFFECT_NATIVE_LIFECYCLE_FOLLOWUP_PLAN.md](18_EFFECT_NATIVE_LIFECYCLE_FOLLOWUP_PLAN.md) |

Shared references:

- [90_CONFIRMED_NON_OPPORTUNITIES.md](90_CONFIRMED_NON_OPPORTUNITIES.md)
- [91_CROSS_SYSTEM_REGRESSION_AND_ROLLBACK.md](91_CROSS_SYSTEM_REGRESSION_AND_ROLLBACK.md)

## Atomic dependency policy

Each implementation starts from a clean candidate branch/build and changes one performance mechanism. A changed public function, constant contract, diagnostic getter, or library requirement must be updated in every producer and consumer in the same commit and full-map compile.

### Hard bundles

- **CAMERA-01:** `UI/DynamicFarZ.j` and `UI/CameraControl.j` change together when effective-Far-Z behavior changes. `UI/CameraUI.j`, `Camera/DialogCamera.j`, `Camera/FreeCamera.j`, special camera contexts, and the camera test harness are mandatory consumers to compile and test.
- **DOODAD-01:** `DoodadHider/DoodadManager.j`, `DoodadHider/DoodadRender.j`, and matching test-harness calls change together when backend configuration, distance configuration, or diagnostics change.
- **WEATHER-01:** `EnvironmentSystems/WeatherSystemV4.j` and any changed `Storm`, `SteamBreathSystem`, or `SpeciFX` interface change together. An internal Storm timer change remains STORM-01 when it preserves all public behavior.
- **EFFECTS-01:** a public `SpeciFX` change requires simultaneous updates to all affected callers. Prefer internal substitutions that preserve the API.
- **DIAGNOSTICS-01:** a debug command or harness call lands with the getter or control it invokes. Never leave the repository with a harness referencing a function that is not present.

### Behavioral dependencies

Behavioral dependencies do not force unrelated source edits, but they do force the joint regression tests in `91_CROSS_SYSTEM_REGRESSION_AND_ROLLBACK.md`:

- DestructableHider with quests and systems that call `ShowDestructable` directly.
- UnitHider with AI, AIRoutines, cinematics, companions, quest NPCs, and direct users of its GUI globals.
- AIRoutines hidden policy with UnitHider and the engine `IsUnitHidden` state.
- Camera/Far Z with DoodadRender, UnitHider, and DestructableHider when comparing visibility distances.
- Weather with DoodadRender, local camera behavior, seasonal transitions, and cinematics.
- Rebirth asset changes with the script system that hides, animates, attaches effects to, or replaces the affected object type.

## Rollout rules

1. Complete FOUNDATION-01 before measuring a candidate.
2. Add only the diagnostics required by the current candidate.
3. Run one candidate per map build and reload between A/B variants.
4. Record raw capture filenames, settings, results, failures, and the decision in the candidate document.
5. Set the candidate status to `accepted`, `rejected`, `rolled back`, or `blocked` before starting the next candidate.
6. Do not combine accepted changes until every isolated result is complete.
7. Run the complete cross-system matrix and a 30-minute soak on the combined build.

## Shared-file coordination

`Debug/DebugCommands.j`, `Debug/Warcraft300TestHarness.j`, `_Blizzard/common.j`, `_Blizzard/blizzard.j`, and `_Changelogs/PotS Changelog.md` are shared coordination points. Do not implement plans that edit the same shared file concurrently. The active Blizzard declaration files are references and must not be modified for an optimization.

## Documentation definition of done

- The candidate document contains evidence, exact native contracts, minimal design, tests, acceptance threshold, rollback, dependencies, and a commit-message suggestion.
- Current line references are rechecked immediately before implementation because later source changes can move them.
- JASS changes compile through the normal World Editor/JassHelper flow and then through the full map.
- World Editor-only work is reported as manual follow-up; `_MISC/war3map.wts` remains read-only.

