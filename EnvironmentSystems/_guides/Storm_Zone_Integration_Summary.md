# Storm System - Zone Integration Summary

## Changes Made

### Storm.j Library Modifications

1. **Added Fog Storage System**
   - Stores current fog settings before storm effects begin
   - Restores fog settings after all storms complete
   - Executes zone's DNC trigger (udg_ZoneTrigger[udg_ZoneCurrent]) to restore zone-specific day/night cycle

2. **Added Zone-Based Effect Filtering**
   - Storm effects (lightning, thunder, fog) only visible to players whose selected unit is in the storm's zone
   - Checks `udg_ZoneCurrent` to determine if local player should see effects
   - Zone ID 0 = global (visible to all players)
   - Zone ID > 0 = zone-specific (only visible if player is in that zone)

3. **New API Functions**
   ```jass
   // Zone-specific storm functions
   call Storm_ImitateLocalZone(variant, count, azimuth, zenith, localplayer, zoneId)
   call Storm_ImitateRandomLocalZone(variant, localplayer, zoneId)
   call Storm_ImitateZone(variant, count, azimuth, zenith, zoneId)
   call Storm_ImitateRandomZone(variant, zoneId)
   
   // Legacy functions (use current zone from udg_ZoneCurrent)
   call Storm_ImitateLocal(variant, count, azimuth, zenith, localplayer)
   call Storm_ImitateRandomLocal(variant, localplayer)
   call Storm_Imitate(variant, count, azimuth, zenith)
   call Storm_ImitateRandom(variant)
   ```

4. **DNC Restoration Mechanism**
   - After last storm ends, system calls `TriggerExecute(udg_ZoneTrigger[udg_ZoneCurrent])`
   - This allows each zone to restore its custom day/night cycle settings
   - Fog is restored to pre-storm state before triggering zone DNC

### WeatherSystem.j Modifications

1. **Added Zone ID Tracking**
   - New array: `MasterZoneID[]` - stores udg_ZoneCurrent value for each zone
   - Default value: 0 (global, backwards compatible)

2. **Updated Thunder System**
   - `ZoneThunderCallback()` now uses `Storm_ImitateRandomZone()` with zone ID
   - Thunder effects only visible to players in the zone
   - Updated debug messages to show zone ID

3. **New API Function**
   ```jass
   call WeatherSystem_SetZoneID(zoneName, zoneId)
   ```
   Sets the zone ID (udg_ZoneCurrent value) for thunder effect targeting.

4. **Zone ID Configuration**
   All zones configured with their udg_ZoneCurrent values:
   - Zone01_TwilightGrove: 1
   - Zone02_Serenaglade: 2
   - Zone03_EmperpeakHighlands: 3
   - Zone04_DragonfirePeaks: 4
   - Zone06_Thornwoods: 6
   - Zone0601_StonetoothCamp: 601
   - Zone0602_BloodtuskTribe: 602
   - Zone07_Havenwoods: 7
   - Zone08_BonecrushStronghold: 8
   - Zone09_VanguardVale: 9
   - Zone010_Riverbane: 10
   - Zone011_Deadwoods: 11
   - Zone012_FelfireBastion: 12
   - Zone013_Stormhaven: 13
   - Zone014_Sirensong: 14
   - Zone01401_Moknatha: 1401
   - Zone01402_Zulgarok: 1402
   - Zone01403_Urgmar: 1403
   - Zone01404_Serpentshore: 1404
   - Zone015_ZulGurak: 15
   - Zone017_VerdantPlains: 17
   - Zone01701_ChimairosRoost: 1701
   - Zone01702_WeepingHollow: 1702
   - Zone01703_RedwindPass: 1703
   - Zone01704_Settlement: 1704
   - Zone018_ColiseumOfAges: 18
   - Zone019_GhostwalkRidge: 19
   - Zone01901_IronspinePost: 1901
   - Zone020_Dawnhold: 20

## How It Works

### Normal Operation

1. **Storm Triggered in Zone**
   - WeatherSystem calls `Storm_ImitateRandomZone(variant, zoneId)`
   - Storm system checks `udg_ZoneCurrent` for local player
   - If player's zone matches storm's zone, show effects

2. **Visual/Audio Filtering**
   - Lightning effects only created if `IsLocalPlayerInZone(zoneId)` returns true
   - Thunder sounds only played if player is in zone
   - Fog effects only applied if player is in zone

3. **Fog Management**
   - First storm in any zone stores current fog settings
   - Storm applies its own fog effects (for players in zone)
   - Last storm restores fog settings and triggers zone DNC

### DNC Restoration Process

When last storm ends:
```jass
1. Restore fog settings (TF_*, colors, etc.)
2. Apply restored fog: SetTerrainFogEx() or ResetTerrainFog()
3. Execute zone DNC trigger: TriggerExecute(udg_ZoneTrigger[udg_ZoneCurrent])
```

This allows each zone to re-apply its custom day/night cycle settings.

## Requirements

- Global array: `udg_ZoneTrigger[]` - trigger array indexed by udg_ZoneCurrent
- Global integer: `udg_ZoneCurrent` - current zone ID for player
- Each zone must have a trigger that sets up its DNC when executed

## Benefits

1. **Immersive Experience**: Players only see storms in their current zone
2. **Performance**: Reduced effect overhead for players not in storm zones
3. **Flexibility**: Each zone can have different DNC settings that are preserved
4. **Backwards Compatible**: Legacy API functions still work (use current zone)

## Usage Examples

```jass
// Trigger storm in specific zone (visible only to players in that zone)
call Storm_ImitateRandomZone(2, 13)  // Storm in Stormhaven (zone 13)

// Use current zone (from udg_ZoneCurrent)
call Storm_ImitateRandom(2)  // Storm in whatever zone player is in

// Manual storm with zone
call Storm_ImitateZone(3, 4, 45, -60, 7)  // Storm in Havenwoods (zone 7)
```

## Testing Notes

- Ensure `udg_ZoneTrigger[zoneId]` exists and is properly initialized for each zone
- Test DNC restoration by:
  1. Setting zone-specific DNC (time of day, fog, etc.)
  2. Triggering thunder in that zone
  3. Verifying DNC restores after storm ends
- Test zone isolation by:
  1. Standing in one zone
  2. Triggering thunder in different zone
  3. Verifying no thunder/lightning effects appear
