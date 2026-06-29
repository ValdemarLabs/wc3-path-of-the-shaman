// ============================================================
// GatherNodes - Master Gathering Node System
// ============================================================
// Manages spawning and respawning of gatherable resources:
// - Item nodes (herbs, flowers, mushrooms)
// - Unit nodes (ore veins, crystal veins, fish pools, treasure chests)
//
// Integrates with Zones.j for zone-based spawning
// Supports fixed spawn points and random region spawns
//
// Dependencies:
//   - Zones.j (zone ID constants and region tracking)
//   - TimerUtils (timer recycling)
//   - Table (hashtable wrapper)
//   - Optional: GatherNodeItems.j, GatherNodeUnits.j
//
// ============================================================

library GatherNodes initializer Init requires ZonesCore, TimerUtils, Table

// ============================================================
// CONFIGURATION
// ============================================================
globals
    // Master enable/disable
    private boolean GN_SystemEnabled = true
    
    // Debug mode
    private boolean GN_DebugMode = false
    
    // Glow effect model path.
    // Use a stable built-in model here; the imported Glow.mdl did not clean up reliably.
    private constant string GN_GLOW_MODEL = "war3campImported\\Glow.mdl" 
    // Master safety switch for gather-node glow.
    private boolean GN_GlowEffectsEnabled = true
    
    // Alternative glow models:
    // "Abilities\\Spells\\NightElf\\FaerieDragon\\FaerieDragonMissile.mdl"
    // "Abilities\\Spells\\Human\\HolyBolt\\HolyBoltSpecialArt.mdl"
    // "Abilities\\Spells\\Items\\AIil\\AIilTarget.mdl"
    
    // Timer intervals
    private constant real GN_SPAWN_CHECK_INTERVAL = 5.0
    private constant real GN_RESPAWN_CHECK_INTERVAL = 1.0
    
    // Maximum nodes per zone (safety cap)
    constant integer GN_MAX_NODES_PER_ZONE = 100
    
    // Spawn attempt retries for random placement
    constant integer GN_RANDOM_SPAWN_ATTEMPTS = 10

    // Random spawn occupancy guards
    constant real GN_ITEM_SPAWN_BLOCK_RADIUS = 1000.0
    constant real GN_UNIT_SPAWN_BLOCK_RADIUS = 1000.0

    // Terrain types where gather nodes should never spawn
    private constant integer GN_BLOCKED_TERRAIN_LAVA_CRACKS = 'Dlvc'
    private constant integer GN_BLOCKED_TERRAIN_POISON = 'Cpos'

    // Safety cap for active-node iteration
    private constant integer GN_MAX_ACTIVE_TRACKED_NODES = 4096

    // Stagger debug pings so multiple spawns remain visible.
    private constant real GN_DEBUG_PING_INTERVAL = 0.15

endglobals

// ============================================================
// DATA STRUCTURES
// ============================================================
globals
    // Zone spawn tracking
    private Table GN_ZoneItemCount    // zone_id -> item count in zone
    private Table GN_ZoneUnitCount    // zone_id -> unit count in zone
    
    // Active node tracking
    private Table GN_ActiveItems      // item handle -> node definition id
    private Table GN_ActiveUnits      // unit handle -> node definition id
    private Table GN_ActiveItemProfession
    private Table GN_ActiveItemSkillRequired
    private Table GN_ActiveItemName
    private Table GN_ActiveUnitProfession
    private Table GN_ActiveUnitSkillRequired
    private Table GN_ActiveUnitName
    private item array GN_ActiveItemList
    private unit array GN_ActiveUnitList
    private integer GN_ActiveItemCount = 0
    private integer GN_ActiveUnitCount = 0
    
    // Respawn queue
    private timer array GN_RespawnTimers
    private integer GN_RespawnTimerCount = 0
    
    // Glow effects
    private Table GN_GlowEffects      // node handle -> effect handle
    
    // Zone enable/disable
    private Table GN_ZoneEnabled      // zone_id -> boolean (1=enabled, 0=disabled)

    // Debug ping queue
    private timer GN_DebugPingTimer = null
    private real array GN_DebugPingX
    private real array GN_DebugPingY
    private boolean array GN_DebugPingIsUnit
    private integer GN_DebugPingHead = 0
    private integer GN_DebugPingTail = 0
    private boolean GN_DebugPingActive = false
endglobals

// ============================================================
// UTILITY FUNCTIONS
// ============================================================

// BoolToString helper (must be before first use)
private function BoolToString takes boolean b returns string
    if b then
        return "ENABLED"
    endif
    return "DISABLED"
endfunction

// Get random real between min and max
function GN_GetRandomReal takes real minVal, real maxVal returns real
    return GetRandomReal(minVal, maxVal)
endfunction

// Get random point within a rect
function GN_GetRandomPointInRect takes rect r returns location
    local real x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
    local real y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
    return Location(x, y)
endfunction

// Get the main random-spawn rect for a zone from ZonesCore.
// Prefer the main zone/weather rect, with enter-rect fallback only if needed.
function GN_GetZoneSpawnRect takes integer zoneId returns rect
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    local rect r = null

    if z == 0 then
        return null
    endif

    if z.weatherRectCount > 0 then
        set r = z.weatherRects[0]
        if r != null then
            return r
        endif
    endif

    if z.enterRegionCount > 0 then
        set r = z.enterRegions[0]
        if r != null then
            return r
        endif
    endif

    return null
endfunction

function GN_IsPointInRestrictedRect takes integer zoneId, real x, real y, boolean unitNode returns boolean
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    local integer i = 0
    local rect r

    if z == 0 then
        return false
    endif

    if unitNode then
        loop
            exitwhen i >= z.nodeUnitRestrictRectCount
            set r = z.nodeUnitRestrictRects[i]
            if r != null and RectContainsCoords(r, x, y) then
                return true
            endif
            set i = i + 1
        endloop
        return false
    endif

    loop
        exitwhen i >= z.nodeItemRestrictRectCount
        set r = z.nodeItemRestrictRects[i]
        if r != null and RectContainsCoords(r, x, y) then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

function GN_IsPointInWaterIgnoreRect takes integer zoneId, real x, real y returns boolean
    local ZoneData z = ZonesCore_GetZoneData(zoneId)
    local integer i = 0
    local rect r

    if z == 0 then
        return false
    endif

    loop
        exitwhen i >= z.nodeWaterIgnoreRectCount
        set r = z.nodeWaterIgnoreRects[i]
        if r != null and RectContainsCoords(r, x, y) then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

// Check if a point is pathable (simple check)
function GN_IsPointPathable takes real x, real y returns boolean
    local item testItem = CreateItem('afac', x, y)
    local real newX = GetItemX(testItem)
    local real newY = GetItemY(testItem)
    local boolean pathable = (newX - x) * (newX - x) + (newY - y) * (newY - y) < 100.0

    if IsTerrainPathable(x, y, PATHING_TYPE_WALKABILITY) then
        set pathable = false
    endif

    call RemoveItem(testItem)
    set testItem = null
    return pathable
endfunction

function GN_IsWaterLikeTerrain takes real x, real y returns boolean
    // Use floatability as the safe water check here.
    // Amphibious pathing is too broad for this filter and can match normal land.
    return not IsTerrainPathable(x, y, PATHING_TYPE_FLOATABILITY)
endfunction

function GN_IsBlockedGatherTerrainType takes real x, real y returns boolean
    local integer terrainType = GetTerrainType(x, y)

    if terrainType == GN_BLOCKED_TERRAIN_LAVA_CRACKS then
        return true
    endif
    if terrainType == GN_BLOCKED_TERRAIN_POISON then
        return true
    endif

    return false
endfunction

function GN_IsTerrainAllowedForNode takes integer zoneId, real x, real y, boolean preventWaterSpawn, boolean ignoreWaterCheck returns boolean
    if GN_IsBlockedGatherTerrainType(x, y) then
        return false
    endif
    if not ignoreWaterCheck and preventWaterSpawn and not GN_IsPointInWaterIgnoreRect(zoneId, x, y) and GN_IsWaterLikeTerrain(x, y) then
        return false
    endif
    return true
endfunction

// Check whether a random item-node spawn location is clear of other active item nodes.
function GN_IsItemSpawnAreaClear takes real x, real y returns boolean
    local integer i = 0
    local real dx
    local real dy
    local real minDistSq = GN_ITEM_SPAWN_BLOCK_RADIUS * GN_ITEM_SPAWN_BLOCK_RADIUS

    loop
        exitwhen i >= GN_ActiveItemCount
        if GN_ActiveItemList[i] != null then
            set dx = GetItemX(GN_ActiveItemList[i]) - x
            set dy = GetItemY(GN_ActiveItemList[i]) - y
            if dx * dx + dy * dy < minDistSq then
                return false
            endif
        endif
        set i = i + 1
    endloop

    return true
endfunction

// Check whether a random unit-node spawn location is clear of other active unit nodes.
function GN_IsUnitSpawnAreaClear takes real x, real y returns boolean
    local integer i = 0
    local real dx
    local real dy
    local real minDistSq = GN_UNIT_SPAWN_BLOCK_RADIUS * GN_UNIT_SPAWN_BLOCK_RADIUS

    loop
        exitwhen i >= GN_ActiveUnitCount
        if GN_ActiveUnitList[i] != null then
            set dx = GetUnitX(GN_ActiveUnitList[i]) - x
            set dy = GetUnitY(GN_ActiveUnitList[i]) - y
            if dx * dx + dy * dy < minDistSq then
                return false
            endif
        endif
        set i = i + 1
    endloop

    return true
endfunction

private function RemoveActiveItemFromList takes item it returns nothing
    local integer i = 0

    loop
        exitwhen i >= GN_ActiveItemCount
        if GN_ActiveItemList[i] == it then
            set GN_ActiveItemCount = GN_ActiveItemCount - 1
            set GN_ActiveItemList[i] = GN_ActiveItemList[GN_ActiveItemCount]
            set GN_ActiveItemList[GN_ActiveItemCount] = null
            return
        endif
        set i = i + 1
    endloop
endfunction

private function RemoveActiveUnitFromList takes unit u returns nothing
    local integer i = 0

    loop
        exitwhen i >= GN_ActiveUnitCount
        if GN_ActiveUnitList[i] == u then
            set GN_ActiveUnitCount = GN_ActiveUnitCount - 1
            set GN_ActiveUnitList[i] = GN_ActiveUnitList[GN_ActiveUnitCount]
            set GN_ActiveUnitList[GN_ActiveUnitCount] = null
            return
        endif
        set i = i + 1
    endloop
endfunction

// ============================================================
// SYSTEM CONTROL API
// ============================================================

// Enable or disable the entire system
function GN_SetSystemEnabled takes boolean enabled returns nothing
    set GN_SystemEnabled = enabled
    if GN_DebugMode then
        if enabled then
            call BJDebugMsg("|cff00ff00[GatherNodes]|r System ENABLED")
        else
            call BJDebugMsg("|cffff0000[GatherNodes]|r System DISABLED")
        endif
    endif
endfunction

function GN_IsSystemEnabled takes nothing returns boolean
    return GN_SystemEnabled
endfunction

// Enable or disable debug messages
function GN_SetDebugMode takes boolean enabled returns nothing
    set GN_DebugMode = enabled
endfunction

function GN_IsDebugMode takes nothing returns boolean
    return GN_DebugMode
endfunction

// Enable or disable a specific zone
function GN_SetZoneEnabled takes integer zoneId, boolean enabled returns nothing
    if enabled then
        set GN_ZoneEnabled.integer[zoneId] = 1
    else
        set GN_ZoneEnabled.integer[zoneId] = 0
    endif
    
    if GN_DebugMode then
        call BJDebugMsg("|cff00ff00[GatherNodes]|r Zone " + I2S(zoneId) + " " + (BoolToString(enabled)))
    endif
endfunction

function GN_IsZoneEnabled takes integer zoneId returns boolean
    // Default to enabled if not explicitly set
    if not GN_ZoneEnabled.has(zoneId) then
        return true
    endif
    return GN_ZoneEnabled.integer[zoneId] == 1
endfunction

// ============================================================
// ZONE COUNT TRACKING
// ============================================================

function GN_GetZoneItemCount takes integer zoneId returns integer
    if GN_ZoneItemCount.has(zoneId) then
        return GN_ZoneItemCount.integer[zoneId]
    endif
    return 0
endfunction

function GN_SetZoneItemCount takes integer zoneId, integer count returns nothing
    set GN_ZoneItemCount.integer[zoneId] = count
endfunction

function GN_IncrementZoneItemCount takes integer zoneId returns nothing
    call GN_SetZoneItemCount(zoneId, GN_GetZoneItemCount(zoneId) + 1)
endfunction

function GN_DecrementZoneItemCount takes integer zoneId returns nothing
    local integer count = GN_GetZoneItemCount(zoneId) - 1
    if count < 0 then
        set count = 0
    endif
    call GN_SetZoneItemCount(zoneId, count)
endfunction

function GN_GetZoneUnitCount takes integer zoneId returns integer
    if GN_ZoneUnitCount.has(zoneId) then
        return GN_ZoneUnitCount.integer[zoneId]
    endif
    return 0
endfunction

function GN_SetZoneUnitCount takes integer zoneId, integer count returns nothing
    set GN_ZoneUnitCount.integer[zoneId] = count
endfunction

function GN_IncrementZoneUnitCount takes integer zoneId returns nothing
    call GN_SetZoneUnitCount(zoneId, GN_GetZoneUnitCount(zoneId) + 1)
endfunction

function GN_DecrementZoneUnitCount takes integer zoneId returns nothing
    local integer count = GN_GetZoneUnitCount(zoneId) - 1
    if count < 0 then
        set count = 0
    endif
    call GN_SetZoneUnitCount(zoneId, count)
endfunction

// ============================================================
// GLOW EFFECT SYSTEM
// ============================================================

function GN_CreatePointGlowEffect takes real x, real y, integer r, integer g, integer b, integer alpha, real scale, real heightOffset returns effect
    local effect eff
    local location loc
    local real z = 0.0

    if not GN_GlowEffectsEnabled then
        return null
    endif

    set eff = AddSpecialEffect(GN_GLOW_MODEL, x, y)

    if eff != null then
        call BlzSetSpecialEffectScale(eff, scale)
        call BlzSetSpecialEffectColor(eff, r, g, b)
        call BlzSetSpecialEffectAlpha(eff, alpha)
        set loc = Location(x, y)
        set z = GetLocationZ(loc)
        call RemoveLocation(loc)
        set loc = null
        call BlzSetSpecialEffectZ(eff, heightOffset + z)
    endif

    return eff
endfunction

function GN_AreGlowEffectsEnabled takes nothing returns boolean
    return GN_GlowEffectsEnabled
endfunction

function GN_SetGlowEffectsEnabled takes boolean enabled returns nothing
    set GN_GlowEffectsEnabled = enabled
endfunction

function GN_DestroyPointGlowEffect takes effect eff returns nothing
    if eff == null then
        return
    endif

    call DestroyEffect(eff)
endfunction

function GN_RemoveKnownGlowEffectByHandle takes handle h, effect knownEff returns nothing
    local integer handleId
    local effect trackedEff = null
    local boolean sameHandle = false

    if h == null then
        if knownEff != null then
            call GN_DestroyPointGlowEffect(knownEff)
        endif
        return
    endif

    set handleId = GetHandleId(h)
    if GN_GlowEffects.effect.has(handleId) then
        set trackedEff = GN_GlowEffects.effect[handleId]
        if trackedEff != null and knownEff != null and trackedEff == knownEff then
            set sameHandle = true
        endif
    endif

    if knownEff != null then
        call GN_DestroyPointGlowEffect(knownEff)
    endif

    if trackedEff != null and not sameHandle then
        call GN_DestroyPointGlowEffect(trackedEff)
    endif

    if GN_GlowEffects.effect.has(handleId) then
        call GN_GlowEffects.effect.remove(handleId)
    endif
endfunction

function GN_RemoveGlowFromHandle takes handle h returns nothing
    call GN_RemoveKnownGlowEffectByHandle(h, null)
endfunction

function GN_HasGlowOnHandle takes handle h returns boolean
    if h == null then
        return false
    endif
    return GN_GlowEffects.effect.has(GetHandleId(h))
endfunction

function GN_ApplyPointGlowToHandle takes handle h, real x, real y, integer r, integer g, integer b, integer alpha, real scale, real heightOffset returns effect
    local effect eff
    local integer handleId
    local effect oldEff = null

    if h == null then
        return null
    endif

    set handleId = GetHandleId(h)

    // Remove existing glow if present
    if GN_GlowEffects.effect.has(handleId) then
        set oldEff = GN_GlowEffects.effect[handleId]
        if oldEff != null then
            call GN_DestroyPointGlowEffect(oldEff)
            set oldEff = null
        endif
        call GN_GlowEffects.effect.remove(handleId)
    endif

    if not GN_GlowEffectsEnabled then
        return null
    endif
    
    // Create new glow at the node position instead of attaching it.
    set eff = GN_CreatePointGlowEffect(x, y, r, g, b, alpha, scale, heightOffset)
    if eff != null then        
        set GN_GlowEffects.effect[handleId] = eff
    endif

    return eff
endfunction

// Apply glow effect to a unit node
function GN_ApplyGlowEffect takes unit u, integer r, integer g, integer b, integer alpha, real scale, real heightOffset returns effect
    local effect eff

    set eff = GN_ApplyPointGlowToHandle(u, GetUnitX(u), GetUnitY(u), r, g, b, alpha, scale, heightOffset)

    if GN_DebugMode and eff != null then
        call BJDebugMsg("|cff00ff00[GatherNodes]|r Applied glow to " + GetUnitName(u))
    endif

    return eff
endfunction

private function GN_DebugPingCallback takes nothing returns nothing
    local integer index = GN_DebugPingHead

    if index >= GN_DebugPingTail then
        set GN_DebugPingHead = 0
        set GN_DebugPingTail = 0
        set GN_DebugPingActive = false
        return
    endif

    if GN_DebugPingIsUnit[index] then
        call PingMinimapEx(GN_DebugPingX[index], GN_DebugPingY[index], 15.00, 255, 180, 0, true)
    else
        call PingMinimapEx(GN_DebugPingX[index], GN_DebugPingY[index], 15.00, 0, 255, 80, true)
    endif

    set GN_DebugPingHead = index + 1

    if GN_DebugPingHead < GN_DebugPingTail then
        call TimerStart(GN_DebugPingTimer, GN_DEBUG_PING_INTERVAL, false, function GN_DebugPingCallback)
    else
        set GN_DebugPingHead = 0
        set GN_DebugPingTail = 0
        set GN_DebugPingActive = false
    endif
endfunction

function GN_DebugPingSpawn takes real x, real y, boolean isUnitNode returns nothing
    local integer index

    if not GN_DebugMode then
        return
    endif

    if GN_DebugPingTail >= GN_MAX_ACTIVE_TRACKED_NODES then
        if isUnitNode then
            call PingMinimapEx(x, y, 15.00, 255, 180, 0, true)
        else
            call PingMinimapEx(x, y, 15.00, 0, 255, 80, true)
        endif
        return
    endif

    set index = GN_DebugPingTail
    set GN_DebugPingX[index] = x
    set GN_DebugPingY[index] = y
    set GN_DebugPingIsUnit[index] = isUnitNode
    set GN_DebugPingTail = index + 1

    if not GN_DebugPingActive then
        set GN_DebugPingActive = true
        call TimerStart(GN_DebugPingTimer, 0.03, false, function GN_DebugPingCallback)
    endif
endfunction

// Remove glow effect from a unit
function GN_RemoveGlowEffect takes unit u returns nothing
    call GN_RemoveGlowFromHandle(u)
endfunction

// ============================================================
// NODE REGISTRATION
// ============================================================

// Register an item as an active gather node
function GN_RegisterActiveItem takes item it, integer nodeDefId, integer zoneId, integer professionId, integer skillRequired, string nodeName returns nothing
    local integer handleId = GetHandleId(it)
    set GN_ActiveItems.integer[handleId] = nodeDefId
    set GN_ActiveItemProfession.integer[handleId] = professionId
    set GN_ActiveItemSkillRequired.integer[handleId] = skillRequired
    set GN_ActiveItemName.string[handleId] = nodeName
    if GN_ActiveItemCount < GN_MAX_ACTIVE_TRACKED_NODES then
        set GN_ActiveItemList[GN_ActiveItemCount] = it
        set GN_ActiveItemCount = GN_ActiveItemCount + 1
    endif
    call GN_IncrementZoneItemCount(zoneId)
    
    if GN_DebugMode then
        call BJDebugMsg("|cff00ff00[GatherNodes]|r Registered item node in zone " + I2S(zoneId))
    endif
endfunction

// Register a unit as an active gather node
function GN_RegisterActiveUnit takes unit u, integer nodeDefId, integer zoneId, integer professionId, integer skillRequired, string nodeName returns nothing
    local integer handleId = GetHandleId(u)
    set GN_ActiveUnits.integer[handleId] = nodeDefId
    set GN_ActiveUnitProfession.integer[handleId] = professionId
    set GN_ActiveUnitSkillRequired.integer[handleId] = skillRequired
    set GN_ActiveUnitName.string[handleId] = nodeName
    if GN_ActiveUnitCount < GN_MAX_ACTIVE_TRACKED_NODES then
        set GN_ActiveUnitList[GN_ActiveUnitCount] = u
        set GN_ActiveUnitCount = GN_ActiveUnitCount + 1
    endif
    call GN_IncrementZoneUnitCount(zoneId)
    
    if GN_DebugMode then
        call BJDebugMsg("|cff00ff00[GatherNodes]|r Registered unit node in zone " + I2S(zoneId))
    endif
endfunction

// Unregister an item node 
function GN_UnregisterItem takes item it, integer zoneId returns nothing
    local integer handleId = GetHandleId(it)
    call GN_ActiveItems.remove(handleId)
    if GN_ActiveItemProfession.has(handleId) then
        call GN_ActiveItemProfession.remove(handleId)
    endif
    if GN_ActiveItemSkillRequired.has(handleId) then
        call GN_ActiveItemSkillRequired.remove(handleId)
    endif
    if GN_ActiveItemName.has(handleId) then
        call GN_ActiveItemName.remove(handleId)
    endif
    call RemoveActiveItemFromList(it)
    call GN_DecrementZoneItemCount(zoneId)
endfunction

// Unregister a unit node
function GN_UnregisterUnit takes unit u, integer zoneId returns nothing
    local integer handleId = GetHandleId(u)
    call GN_RemoveGlowEffect(u)
    call GN_ActiveUnits.remove(handleId)
    if GN_ActiveUnitProfession.has(handleId) then
        call GN_ActiveUnitProfession.remove(handleId)
    endif
    if GN_ActiveUnitSkillRequired.has(handleId) then
        call GN_ActiveUnitSkillRequired.remove(handleId)
    endif
    if GN_ActiveUnitName.has(handleId) then
        call GN_ActiveUnitName.remove(handleId)
    endif
    call RemoveActiveUnitFromList(u)
    call GN_DecrementZoneUnitCount(zoneId)
endfunction

// Check if an item is a gather node
function GN_IsGatherItem takes item it returns boolean
    return GN_ActiveItems.has(GetHandleId(it))
endfunction

// Check if a unit is a gather node
function GN_IsGatherUnit takes unit u returns boolean
    return GN_ActiveUnits.has(GetHandleId(u))
endfunction

function GN_GetGatherItemProfessionId takes item it returns integer
    local integer handleId = GetHandleId(it)
    if GN_ActiveItemProfession.has(handleId) then
        return GN_ActiveItemProfession.integer[handleId]
    endif
    return 0
endfunction

function GN_GetGatherItemSkillRequired takes item it returns integer
    local integer handleId = GetHandleId(it)
    if GN_ActiveItemSkillRequired.has(handleId) then
        return GN_ActiveItemSkillRequired.integer[handleId]
    endif
    return 0
endfunction

function GN_GetGatherItemName takes item it returns string
    local integer handleId = GetHandleId(it)
    if GN_ActiveItemName.has(handleId) then
        if GN_ActiveItemName.string[handleId] != null and GN_ActiveItemName.string[handleId] != "" then
            return GN_ActiveItemName.string[handleId]
        endif
    endif
    return GetItemName(it)
endfunction

function GN_GetGatherUnitProfessionId takes unit u returns integer
    local integer handleId = GetHandleId(u)
    if GN_ActiveUnitProfession.has(handleId) then
        return GN_ActiveUnitProfession.integer[handleId]
    endif
    return 0
endfunction

function GN_GetGatherUnitSkillRequired takes unit u returns integer
    local integer handleId = GetHandleId(u)
    if GN_ActiveUnitSkillRequired.has(handleId) then
        return GN_ActiveUnitSkillRequired.integer[handleId]
    endif
    return 0
endfunction

function GN_GetGatherUnitName takes unit u returns string
    local integer handleId = GetHandleId(u)
    if GN_ActiveUnitName.has(handleId) then
        if GN_ActiveUnitName.string[handleId] != null and GN_ActiveUnitName.string[handleId] != "" then
            return GN_ActiveUnitName.string[handleId]
        endif
    endif
    return GetUnitName(u)
endfunction

function GN_GetActiveItemCount takes nothing returns integer
    return GN_ActiveItemCount
endfunction

function GN_GetActiveItemByIndex takes integer index returns item
    if index < 0 or index >= GN_ActiveItemCount then
        return null
    endif
    return GN_ActiveItemList[index]
endfunction

function GN_GetActiveUnitCount takes nothing returns integer
    return GN_ActiveUnitCount
endfunction

function GN_GetActiveUnitByIndex takes integer index returns unit
    if index < 0 or index >= GN_ActiveUnitCount then
        return null
    endif
    return GN_ActiveUnitList[index]
endfunction

// ============================================================
// DEBUG COMMANDS
// ============================================================

// Print zone stats
function GN_PrintZoneStats takes integer zoneId returns nothing
    local string zoneName = ZonesCore_Zones_GetZoneName(zoneId)
    call BJDebugMsg("|cff00ff00[GatherNodes]|r Zone " + I2S(zoneId) + " (" + zoneName + ")")
    call BJDebugMsg("  Items: " + I2S(GN_GetZoneItemCount(zoneId)))
    call BJDebugMsg("  Units: " + I2S(GN_GetZoneUnitCount(zoneId)))
endfunction

// Print all active zone stats
function GN_PrintAllZoneStats takes nothing returns nothing
    local integer i = 1
    
    call BJDebugMsg("|cff00ff00[GatherNodes]|r === Zone Statistics ===")
    
    loop
        exitwhen i > 100 // Assume max 100 zones
        if GN_GetZoneItemCount(i) > 0 or GN_GetZoneUnitCount(i) > 0 then
            call GN_PrintZoneStats(i)
        endif
        set i = i + 1
    endloop
endfunction

// Force despawn all nodes in a zone
function GN_ClearZone takes integer zoneId returns nothing
    // This would need to iterate through all tracked nodes
    // Implementation depends on how we store zone->node mappings
    call BJDebugMsg("|cffff0000[GatherNodes]|r Clearing zone " + I2S(zoneId) + " - Not fully implemented")
    call GN_SetZoneItemCount(zoneId, 0)
    call GN_SetZoneUnitCount(zoneId, 0)
endfunction

// ============================================================
// INITIALIZATION
// ============================================================
private function Init takes nothing returns nothing
    set GN_ZoneItemCount = Table.create()
    set GN_ZoneUnitCount = Table.create()
    set GN_ActiveItems = Table.create()
    set GN_ActiveUnits = Table.create()
    set GN_ActiveItemProfession = Table.create()
    set GN_ActiveItemSkillRequired = Table.create()
    set GN_ActiveItemName = Table.create()
    set GN_ActiveUnitProfession = Table.create()
    set GN_ActiveUnitSkillRequired = Table.create()
    set GN_ActiveUnitName = Table.create()
    set GN_GlowEffects = Table.create()
    set GN_ZoneEnabled = Table.create()
    set GN_DebugPingTimer = CreateTimer()
    
    if GN_DebugMode then
        call BJDebugMsg("|cff00ff00[GatherNodes]|r System initialized")
    endif
endfunction

endlibrary
