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
New travel points use the RegionTitles presentation and the zone-discovery
sound, with the discovered travel-point name shown in green. Verdant Plains can
also be unlocked by a quest or event with
`TravelWyvern_DiscoverVerdantPlains(true)`; the request is retained if it runs
before the wyvern library finishes initializing.

`Init Travel Units` should only assign the `WindRiderMaster`, `FlightMaster`,
`Shipmaster`, ship, and zeppelin GUI variables. Do not call `IconQuery` there:
`TravelSystem` owns icon registration so discovery cannot create duplicate or
premature master icons. Method libraries access these units only through the
shared getters documented in `TravelSystem.j`.

## Existing map content

- `TravelWyvern.j` binds all six `WindRiderMaster` units. Masters 4, 5, and 6
  are Verdant Plains, Ashfang Outpost, and Sirensong respectively and use their
  placed unit positions. All 30 directed routes between the six stations are
  registered; destination discovery remains required for player travel.
- `TravelShipA.j` owns the 64-point Sirensong-Dawnhold-Stormhaven neutral-ship
  loop. It pauses at both passes through `gg_rct_SirensongShip012`, and uses the
  supplied dock, boarding, and deck rects for all three harbours. Adjacent fares
  are configured as 100 gold and full Sirensong-Stormhaven travel as 175 gold.
- `TravelShipB.j` binds Mok'natha, Ironspine, and Frontbase shipmasters, owns the
  Orc Frigate's recovered 87-point PatrolSystem route, and starts it after the
  original 45-second delay. Frontbase and Dawnhold only offer destinations in
  the ship's current direction.
  The detached `TravelShipB_MovementStart` trigger is no longer required.
- `TravelZeppelin.j` binds `FlightMaster[1]` at Sereneglade,
  `FlightMaster[2]` at Sirensong, both endpoint zeppelins, and the two
  `Zeppelin*Area` regions automatically. Zeppelin A departs Sereneglade and
  Zeppelin B departs Sirensong; each returns to its home point behind the arrival
  fade. Default fares are currently zero and are configured in `TravelZeppelin.j`.
Ship passenger proxies use `nazgrek2_shieldAttachment.mdl` for Nazgrek and
`war3campImported\TrollMale.mdl` for Zul'kis. Their model paths, scale, and
facing offsets are configured centrally in `TravelSystem.j`. Passenger visuals
are reusable special effects that play their normal stand animation and follow
the ship without `UnitAttachment.j` or dummy passenger units. `TravelShipA.j`
and `TravelShipB.j` configure separate local X/Y/height values for their two
deck slots through `TravelSystem_SetRouteDeckSlotXY`.

## Travel presentation

Travel units for wyvern and zeppelin routes are owned by `Player(5)` and made
invulnerable so neutral-passive guard-position behavior cannot pull them home.
The travel camera uses a 750 distance and 80-degree field of view while arrow
keys remain available for rotation and angle changes. Fullscreen presentation
keeps user control enabled for those camera key events.
Ship journeys lock 300 height units above the ship origin so the deck, rather
than the hull or waterline, stays near the center of the view. Flight travel
continues to target the flying vehicle origin.
Temporary wyvern and bat carriers use gradual Mordrax-style fly-height changes:
they climb during takeoff, descend on final approach, and complete the arrival
after reaching landing height. A bounded descent fallback also completes the
arrival if Warcraft fails to report the carrier's changing fly height.

`TRAVEL_HIDE_MASTER_UI_GAME_BUTTON` in `TravelSystem.j` controls whether the
MasterUI Game button is hidden for the journey. ESC and intermediate-stop
choices use a compact TravelUI frame and remain inside fullscreen mode.

## Route construction

Wyvern and zeppelin travel uses directed routes: each direction is a separate
route with its own start stop, end stop, fare, vehicle configuration, and ordered
waypoint list. `TravelSystem_AddWaypoint` appends middle points; the final point
is normally the destination drop position. Reusable coordinates can be created
once with `TravelSystem_RegisterWaypoint` and attached to any number of routes
with `TravelSystem_AddRegisteredWaypoint`; all six wyvern destinations use this
shared-point API. Wyvern routes create temporary
Player(5) flying carriers. Zeppelin routes use the placed Zeppelin A/B units.
AI route selection includes both methods and deliberately does not read player
discovery state; AI heroes therefore treat every configured flight point as
available.
