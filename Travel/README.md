# Travel system integration

Import `TravelSystem.j` after its required core libraries, followed by
`TravelUI.j` and the method libraries. Import `TravelAI.j` after both `AI.j`
and `TravelWyvern.j`.

## Discovery policy

Discovery is configured independently from the travel method:

```jass
set stopId = TravelSystem_RegisterStop(methodId, name, zoneId, master, boardingArea, x, y, true)
set routeId = TravelSystem_RegisterRoute(methodId, startStop, endStop, fare, skipFee)
call TravelSystem_SetRouteDiscoveryRequirements(routeId, true, true)
```

The last two booleans require the start and end travel points respectively.
Wyvern and zeppelin wrappers set both to `true`. Ship wrappers set both to
`false`, but an individual ship route can override that policy.

Approaching or selecting a discoverable master calls
`TravelSystem_DiscoverStop`. Use `TravelSystem_IsStopDiscovered` and
`TravelSystem_SetStopDiscovered` to save and restore discovery state; resolve
stable configured names with `TravelSystem_GetStopIdByName` when loading. A flight
master is registered with `IconQuery` only after discovery; ship masters are
registered immediately unless their stop is configured as discoverable.

`Init Travel Units` should only assign the `WindRiderMaster`, `FlightMaster`,
`Shipmaster`, ship, and zeppelin GUI variables. Do not call `IconQuery` there:
`TravelSystem` owns icon registration so discovery cannot create duplicate or
premature master icons. Method libraries access these units only through the
shared getters documented in `TravelSystem.j`.

## Existing map content

- `TravelWyvern.j` binds `udg_WindRiderMaster[1..3]`, the three legacy boarding
  areas, and `gg_rct_FlyHere01..03`. All six directed fares are registered.
- `TravelShipB.j` binds the Mok'natha master, owns the Orc Frigate's recovered
  87-point PatrolSystem route, and starts it after the original 45-second delay.
  The detached `TravelShipB_MovementStart` trigger is no longer required.
- `TravelZeppelin.j` binds `FlightMaster[1]` at Sereneglade,
  `FlightMaster[2]` at Sirensong, both endpoint zeppelins, and the two
  `Zeppelin*Area` regions automatically. Zeppelin A departs Sereneglade and
  Zeppelin B departs Sirensong; each returns to its home point behind the arrival
  fade. Default fares are currently zero and are configured in `TravelZeppelin.j`.
- `TravelShipA.j` remains inactive until its stops, vehicle, fares, and
  waypoints are registered; no legacy Ship A patrol definition was recovered.

Ship B hero proxies intentionally use empty model paths initially. Call
`TravelShipB_ConfigureHeroModels` after the correct Nazgrek and Zul'kis model
paths are known. Passenger visuals are special effects attached by relative
position; `UnitAttachment.j` and dummy passenger units are not used.

## Travel presentation

Travel units for wyvern and zeppelin routes are owned by `Player(5)` and made
invulnerable so neutral-passive guard-position behavior cannot pull them home.
The travel camera uses a 750 distance and 80-degree field of view while arrow
keys remain available for rotation and angle changes.

`TRAVEL_HIDE_MASTER_UI_GAME_BUTTON` in `TravelSystem.j` controls whether the
MasterUI Game button is hidden for the journey. ESC and intermediate-stop
dialogs temporarily leave fullscreen mode so native dialog buttons remain
visible, then restore fullscreen mode when the player continues.
