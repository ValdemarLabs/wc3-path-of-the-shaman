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

## Existing map content

- `TravelWyvern.j` binds `udg_WindRiderMaster[1..3]`, the three legacy boarding
  areas, and `gg_rct_FlyHere01..03`. All six directed fares are registered.
- `TravelShipB.j` binds the Mok'natha master and observes the existing
  `udg_TravelShipB` PatrolSystem route. Do not duplicate or remove the 87-point
  patrol during initial integration.
- `TravelZeppelin.j` remains inactive until `TravelZeppelin_Bind` receives the
  Sirensong/Sereneglade masters, boarding areas, arrival points, vehicle, and
  fares.
- `TravelShipA.j` remains inactive until its stops, vehicle, fares, and
  waypoints are registered.

Ship B hero proxies intentionally use empty model paths initially. Call
`TravelShipB_ConfigureHeroModels` after the correct Nazgrek and Zul'kis model
paths are known. Passenger visuals are special effects attached by relative
position; `UnitAttachment.j` and dummy passenger units are not used.
