# Cross-System Regression and Rollback Matrix

## Purpose

This matrix is mandatory after a candidate passes its isolated test and again after combining accepted candidates. A hard-bundle change compiles and ships atomically; a behavioral dependency may keep separate source commits but cannot skip joint testing.

## Global build gates

- Recheck cited current-source locations before editing.
- Compile the focused test map through World Editor/JassHelper.
- Compile the full map through the normal import/load order.
- Do not use standalone pjass as the compatibility decision.
- Confirm minimum Warcraft version 3.0.1.24342 and run the relevant PTR 24360 compatibility pass.
- Keep `_MISC/war3map.wts`, Object Editor exports and placed World Editor data read-only.
- Record import-order changes, new public functions and manual World Editor steps.

## Hard-bundle matrix

| Bundle | Producers changed atomically | Mandatory consumers/tests |
|---|---|---|
| FOUNDATION-01 | benchmark metadata; eventual `AGENTS.md` baseline correction | every native-dependent plan |
| DIAGNOSTICS-01 | owning system diagnostic getters plus DebugCommands/test harness calls | focused compile and full-map compile |
| DESTRUCTABLE-01 | DestructibleHider implementation and its diagnostics | direct `ShowDestructable` users, gates, quests, harvest/death/resurrection |
| CAMERA-01 | DynamicFarZ and CameraControl | CameraUI, DialogCamera, FreeCamera, DynamicMinimap, special contexts, local multiplayer cameras |
| DOODAD-01 | DoodadManager and DoodadRender when contracts change | Warcraft300TestHarness, DebugCommands, weather/seasonal visuals, cinematics |
| UNIT-HIDER-01 | UnitHider internals and diagnostics | AI, AIRoutines, companions, quest references, cinematics, direct GUI globals |
| STORM-01 | Storm internal timer lifecycle | WeatherSystem, FogSystem, ZoneEvent, local/synchronized storm variants |
| WEATHER-01 | WeatherSystem plus every changed Storm/SteamBreath/SpeciFX interface | zones, seasonal weather, camera-local effects, multiplayer |
| ASSET-01 | one World Editor asset/model experiment | hiding/animation/effect systems for that object type; SD/DE rendering |
| AI-LOD-01 | AIRoutines API plus every opted-in routine definition | AI, UnitHider behavior, quests, patrols, escorts, vendors, zone activation |
| EFFECTS-01 | SpeciFX internals or API plus every affected caller | weather, abilities, projectiles, terrain alignment, cleanup |

## Functional regression matrix

| Area | Required scenarios | Failure condition |
|---|---|---|
| Graphics | SD, DE, 4K, 1440p, Rebirth on/off where available | missing/incorrect model, clipping, unexpected quality change |
| Multiplayer | two clients with different cameras/settings | desync, divergent synchronized handles/state, remote visual corruption |
| Camera | normal, orbit, free/developer, horizon, special area, dialog camera | lost input, wrong Far Z, abrupt restore, cinematic override |
| Unit visibility | bootstrap, move, teleport, cinematic, disable/enable, reference changes | wrong hidden set, quest/companion/vendor disappearance |
| Doodads | AREA/INDEXED/disabled, seasonal animation, teleport, cinematic restore | stuck hidden, lost animation, incompatible rawcode |
| Destructables | map edges, gates, harvest, death, resurrection, registration | wrong visibility, interaction/pathing change |
| Weather | rain, snow, storm, steam, clouds, thunder, zone transition | stale effect, wrong intensity, fog not restored, handle growth |
| AI | combat, ambient routine, patrol, escort, vendor, quest receiver | missed progression, order burst, state drift, frozen critical NPC |
| Effects | attached/point, terrain aligned, timed destroy, removal by tag | leak, dead handle, wrong transform/animation/alpha |
| UI | CameraUI, menu, tooltip, inventory, minimap and mouse focus | hidden work still running where gated, broken focus/input/text |
| Persistence | save/load or supported state restoration, map-version transition | saved volatile index, unreconstructed group/cache, visibility drift |
| Soak | 30+ minutes plus repeated reveal/hide/storm/cinematic cycles | rising handles, increasing frame time, timer not stopping/restarting |

## Performance integration matrix

After isolated acceptance, create one combined build in rollout order. Compare it against the original control and against the arithmetic expectation from isolated candidates.

- If combined improvement is materially smaller, rerun pairs to detect interaction or shifted bottlenecks.
- If a candidate improves CPU but worsens GPU or visual quality, report both and apply its own acceptance rule.
- Do not attribute combined gains to individual candidates without their isolated captures.
- Re-run the open-terrain control to detect fixed idle overhead.

## Rollback procedure

1. Stop rollout when a correctness, synchronization or visual failure appears.
2. Identify the smallest candidate/bundle that introduced the failure using its isolated control build.
3. Revert the entire atomic bundle, including diagnostics, consumers, configuration and manual World Editor changes.
4. Rebuild focused and full maps.
5. Repeat the failing functional case and a short control capture.
6. Mark the index status `rolled back` with build identifiers and the reason.
7. Do not retain unused public APIs, timers, groups, effects, saved fields or debug commands from the rejected bundle.

For asset work, rollback occurs through World Editor by restoring the original imported model/object assignment. For native-dependent work, rollback restores the previous code path rather than changing `_Blizzard/common.j`.

## Combined release gate

- Every included candidate is `accepted` with raw captures referenced.
- All hard-bundle consumers compile together.
- The complete functional matrix passes in retail 24342.
- Applicable PTR 24360 and multiplayer tests pass.
- A 30-minute combined soak shows stable handles, timers and frame-time distribution.
- Changelog identifies updated libraries and any remaining validation gaps.

