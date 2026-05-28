// ============================================================
// GatherNodeItems - Item Node Spawning Subsystem
// ============================================================
// Handles spawning and timed re-spawning of item-based gather nodes:
// - Herbs
// - Flowers
// - Mushrooms
// - Other gatherable items
//
// Items spawn in zones at random locations within spawn regions
// When picked up, a fresh spawn attempt is scheduled
//
// Dependencies:
//   - GatherNodes.j (master system)
//   - Zones.j (zone tracking)
//   - TimerUtils (timer recycling)
//   - Table (hashtable wrapper)
//
// ============================================================

library GatherNodeItems initializer Init requires GatherNodes, GatherNodeSkills, ZonesCore, TimerUtils, Table, optional SharedDInvLib


// ============================================================
// CONFIGURATION
// ============================================================
globals
    // Maximum item node definitions
    private constant integer GNI_MAX_DEFINITIONS = 200
     
    // Maximum zone assignments per definition
    private constant integer GNI_MAX_ZONE_ASSIGNMENTS = 100
    
    // Maximum spawn regions per zone
    private constant integer GNI_MAX_SPAWN_REGIONS = 20
    
    // Pickup detection interval
    private constant real GNI_PICKUP_CHECK_INTERVAL = 0.5
    private constant real GNI_VALIDATION_INTERVAL = 15.00
    private constant real GNI_LIFETIME_CHECK_INTERVAL = 1.00

    // Maximum shared category pools
    private constant integer GNI_MAX_SHARED_POOLS = 512
endglobals

// ============================================================
// ITEM NODE DEFINITION STRUCT
// ============================================================
globals
    // Definition arrays
    private integer array GNI_DefItemCode        // Raw code of item to spawn
    private string array GNI_DefNodeName         // Display name
    private integer array GNI_DefCategoryId      // Category for grouping
    private integer array GNI_DefSpawnWeight     // Weight for random selection
    private real array GNI_DefRespawnMin         // Min respawn time
    private real array GNI_DefRespawnMax         // Max respawn time
    private integer array GNI_DefMaxPerZone      // Max instances per zone
    private integer array GNI_DefSkillRequired   // Required skill level
    private integer array GNI_DefProfessionId    // Profession required for gathering
    private boolean array GNI_DefPreventWaterSpawn // Do not spawn in water/amphibious terrain
    private boolean array GNI_DefGlowEffect      // Show glow effect?
    private integer array GNI_DefGlowR           // Glow red
    private integer array GNI_DefGlowG           // Glow green
    private integer array GNI_DefGlowB           // Glow blue
    private integer array GNI_DefGlowAlpha       // Glow alpha
    private real array GNI_DefGlowScale          // Glow scale
    private real array GNI_DefGlowHeight         // Glow height offset
    private boolean array GNI_DefIsRare          // Rare spawn?
    private boolean array GNI_DefEnabled         // Is enabled?
    
    private integer GNI_DefinitionCount = 0
    
    // Zone assignments [defId * GNI_MAX_ZONE_ASSIGNMENTS + index]
    private integer array GNI_ZoneDefId          // Definition ID for this zone assignment
    private integer array GNI_ZoneId             // Zone ID
    private integer array GNI_ZoneSpawnMode      // 0=random, 1=spawn group, 2=group+random fallback
    private integer array GNI_ZoneSpawnGroupId   // Spawn group id (-1 = none)
    private integer array GNI_ZoneWeightOverride // Override weight (-1 = use default)
    private integer array GNI_ZoneMaxOverride    // Override max (-1 = use default)
    private integer array GNI_ZoneSharedMaxOverride // Shared category max (-1 = use default)
    private integer array GNI_ZoneSharedPoolId   // Shared pool id (-1 = none)
    private integer array GNI_ZoneActiveCount    // Active spawned count for this assignment
    private boolean array GNI_ZoneEnabled        // Zone assignment enabled?
    
    private integer GNI_ZoneAssignmentCount = 0
    
    // Spawn regions per zone [zoneId * GNI_MAX_SPAWN_REGIONS + index]
    private rect array GNI_SpawnRegions
    private integer array GNI_SpawnRegionZoneId
    private integer GNI_SpawnRegionCount = 0

    // Spawn regions by explicit spawn group
    private rect array GNI_GroupRegions
    private integer array GNI_GroupRegionGroupId
    private integer GNI_GroupRegionCount = 0
    
    // Active item tracking
    private Table GNI_ItemToDefId      // item handle -> definition id
    private Table GNI_ItemToZoneId     // item handle -> zone id
    private Table GNI_ItemToAssignId   // item handle -> zone assignment id
    private Table GNI_ItemLocation     // item handle -> spawn location handle
    private Table GNI_ItemSpawnX       // item handle -> original spawn x
    private Table GNI_ItemSpawnY       // item handle -> original spawn y
    private Table GNI_ItemLifetimeTimer // item handle -> absolute despawn time
    
    // Respawn timer data
    private Table GNI_TimerDefId       // timer handle -> definition id
    private Table GNI_TimerZoneId      // timer handle -> zone id
    private Table GNI_TimerAssignId    // timer handle -> zone assignment id
    private Table GNI_TimerRegion      // timer handle -> region handle
    private Table GNI_TimerGeneration  // timer handle -> refresh generation
    private Table GNI_LifetimeTimerItem // timer handle -> item handle
    private Table GNI_LifetimeTimerGeneration // timer handle -> refresh generation

    // Pickup trigger
    private trigger GNI_PickupTrigger = null
    private trigger GNI_FreshSpawnTrigger = null
    private trigger GNI_LifetimeExpireTrigger = null
    private trigger GNI_ValidationTrigger = null
    private timer GNI_LifetimeCheckTimer = null

    // Shared category pools
    private integer array GNI_SharedPoolCategoryId
    private integer array GNI_SharedPoolZoneId
    private integer array GNI_SharedPoolGroupId
    private integer array GNI_SharedPoolMax
    private integer array GNI_SharedPoolCount
    private integer GNI_SharedPoolCountTotal = 0

    // Refresh generation invalidates old respawn timers
    private integer GNI_RefreshGeneration = 0
    private integer GNI_PendingFreshAssignId = -1
    private timer GNI_ClockTimer = null
endglobals

// ============================================================
// PICKUP DETECTION
// ============================================================

private function TriggerFreshSpawn takes integer assignId returns nothing
    if assignId >= 0 then
        set GNI_PendingFreshAssignId = assignId
        call TriggerExecute(GNI_FreshSpawnTrigger)
        set GNI_PendingFreshAssignId = -1
    endif
endfunction

private function GNI_NoOp takes nothing returns nothing
endfunction

private function GNI_GetNow takes nothing returns real
    if GNI_ClockTimer == null then
        return 0.0
    endif
    return TimerGetElapsed(GNI_ClockTimer)
endfunction

private function CancelLifetimeTimer takes item it returns nothing
    local integer handleId = GetHandleId(it)

    if GNI_ItemLifetimeTimer.has(handleId) then
        call GNI_ItemLifetimeTimer.remove(handleId)
    endif
endfunction

// DEFINITION REGISTRATION (Called from exported JASS)
// ============================================================

// Register a new item node definition
function GNI_RegisterDefinition takes integer itemCode, string nodeName, integer categoryId, integer spawnWeight, real respawnMin, real respawnMax, integer maxPerZone, integer skillRequired, integer professionId, boolean preventWaterSpawn, boolean glowEffect, integer glowR, integer glowG, integer glowB, integer glowAlpha, real glowScale, real glowHeight, boolean isRare returns integer
    local integer defId = GNI_DefinitionCount
    
    if defId >= GNI_MAX_DEFINITIONS then
        call BJDebugMsg("|cffff0000[GatherNodeItems]|r ERROR: Max definitions reached!")
        return -1
    endif
    
    set GNI_DefItemCode[defId] = itemCode
    set GNI_DefNodeName[defId] = nodeName
    set GNI_DefCategoryId[defId] = categoryId
    set GNI_DefSpawnWeight[defId] = spawnWeight
    set GNI_DefRespawnMin[defId] = respawnMin
    set GNI_DefRespawnMax[defId] = respawnMax
    set GNI_DefMaxPerZone[defId] = maxPerZone
    set GNI_DefSkillRequired[defId] = skillRequired
    set GNI_DefProfessionId[defId] = professionId
    set GNI_DefPreventWaterSpawn[defId] = preventWaterSpawn
    set GNI_DefGlowEffect[defId] = glowEffect
    set GNI_DefGlowR[defId] = glowR
    set GNI_DefGlowG[defId] = glowG
    set GNI_DefGlowB[defId] = glowB
    set GNI_DefGlowAlpha[defId] = glowAlpha
    set GNI_DefGlowScale[defId] = glowScale
    set GNI_DefGlowHeight[defId] = glowHeight
    set GNI_DefIsRare[defId] = isRare
    set GNI_DefEnabled[defId] = true
    
    set GNI_DefinitionCount = GNI_DefinitionCount + 1
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Registered: " + nodeName + " (ID: " + I2S(defId) + ")")
    endif
    
    return defId
endfunction

private function EnsureSharedPool takes integer defId, integer zoneId, integer groupId, integer sharedMax returns integer
    local integer i = 0
    local integer categoryId = GNI_DefCategoryId[defId]

    loop
        exitwhen i >= GNI_SharedPoolCountTotal
        if GNI_SharedPoolCategoryId[i] == categoryId and GNI_SharedPoolZoneId[i] == zoneId and GNI_SharedPoolGroupId[i] == groupId then
            if sharedMax >= 0 and sharedMax < GNI_SharedPoolMax[i] then
                set GNI_SharedPoolMax[i] = sharedMax
            endif
            return i
        endif
        set i = i + 1
    endloop

    if GNI_SharedPoolCountTotal >= GNI_MAX_SHARED_POOLS then
        call BJDebugMsg("|cffff0000[GatherNodeItems]|r ERROR: Max shared pools reached!")
        return -1
    endif

    set i = GNI_SharedPoolCountTotal
    set GNI_SharedPoolCategoryId[i] = categoryId
    set GNI_SharedPoolZoneId[i] = zoneId
    set GNI_SharedPoolGroupId[i] = groupId
    set GNI_SharedPoolMax[i] = sharedMax
    set GNI_SharedPoolCount[i] = 0
    set GNI_SharedPoolCountTotal = GNI_SharedPoolCountTotal + 1

    return i
endfunction

// Register a zone assignment for a definition
function GNI_RegisterZoneAssignment takes integer defId, integer zoneId, integer spawnMode, integer spawnGroupId, integer weightOverride, integer maxOverride, integer sharedMaxOverride returns integer
    local integer assignId = GNI_ZoneAssignmentCount
    
    if assignId >= GNI_MAX_DEFINITIONS * GNI_MAX_ZONE_ASSIGNMENTS then
        call BJDebugMsg("|cffff0000[GatherNodeItems]|r ERROR: Max zone assignments reached!")
        return -1
    endif
    
    set GNI_ZoneDefId[assignId] = defId
    set GNI_ZoneId[assignId] = zoneId
    set GNI_ZoneSpawnMode[assignId] = spawnMode
    set GNI_ZoneSpawnGroupId[assignId] = spawnGroupId
    set GNI_ZoneWeightOverride[assignId] = weightOverride
    set GNI_ZoneMaxOverride[assignId] = maxOverride
    set GNI_ZoneSharedMaxOverride[assignId] = sharedMaxOverride
    set GNI_ZoneSharedPoolId[assignId] = -1
    set GNI_ZoneActiveCount[assignId] = 0
    set GNI_ZoneEnabled[assignId] = true

    if sharedMaxOverride >= 0 then
        set GNI_ZoneSharedPoolId[assignId] = EnsureSharedPool(defId, zoneId, spawnGroupId, sharedMaxOverride)
    endif

    set GNI_ZoneAssignmentCount = GNI_ZoneAssignmentCount + 1
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Zone " + I2S(zoneId) + " assigned to def " + I2S(defId))
    endif
    
    return assignId
endfunction

// Register a spawn region for a zone
function GNI_RegisterSpawnRegion takes integer zoneId, rect r returns integer
    local integer regionId = GNI_SpawnRegionCount
    
    if regionId >= GNI_MAX_SPAWN_REGIONS * 100 then
        call BJDebugMsg("|cffff0000[GatherNodeItems]|r ERROR: Max spawn regions reached!")
        return -1
    endif
    
    set GNI_SpawnRegions[regionId] = r
    set GNI_SpawnRegionZoneId[regionId] = zoneId
    
    set GNI_SpawnRegionCount = GNI_SpawnRegionCount + 1
    
    return regionId
endfunction

function GNI_RegisterGroupRegion takes integer groupId, rect r returns integer
    local integer regionId = GNI_GroupRegionCount

    set GNI_GroupRegions[regionId] = r
    set GNI_GroupRegionGroupId[regionId] = groupId
    set GNI_GroupRegionCount = GNI_GroupRegionCount + 1

    return regionId
endfunction

// ============================================================
// SPAWNING FUNCTIONS
// ============================================================

// Get the random-in-zone rect directly from ZonesCore.
private function GetZoneSpawnRect takes integer zoneId returns rect
    return GN_GetZoneSpawnRect(zoneId)
endfunction

private function GetRandomGroupRegion takes integer groupId returns rect
    local integer i = 0
    local integer count = 0
    local integer array validRegions

    loop
        exitwhen i >= GNI_GroupRegionCount
        if GNI_GroupRegionGroupId[i] == groupId then
            set validRegions[count] = i
            set count = count + 1
        endif
        set i = i + 1
    endloop

    if count == 0 then
        return null
    endif

    return GNI_GroupRegions[validRegions[GetRandomInt(0, count - 1)]]
endfunction

private function GetEffectiveMax takes integer assignId returns integer
    if GNI_ZoneMaxOverride[assignId] >= 0 then
        return GNI_ZoneMaxOverride[assignId]
    endif
    return GNI_DefMaxPerZone[GNI_ZoneDefId[assignId]]
endfunction

private function GetEffectiveWeight takes integer assignId returns integer
    if GNI_ZoneWeightOverride[assignId] > 0 then
        return GNI_ZoneWeightOverride[assignId]
    endif
    return GNI_DefSpawnWeight[GNI_ZoneDefId[assignId]]
endfunction

private function CanSpawnAssignment takes integer assignId returns boolean
    local integer sharedPoolId

    if assignId < 0 or assignId >= GNI_ZoneAssignmentCount then
        return false
    endif
    if not GNI_ZoneEnabled[assignId] then
        return false
    endif
    if not GNI_DefEnabled[GNI_ZoneDefId[assignId]] then
        return false
    endif
    if GNI_ZoneActiveCount[assignId] >= GetEffectiveMax(assignId) then
        return false
    endif

    set sharedPoolId = GNI_ZoneSharedPoolId[assignId]
    if sharedPoolId >= 0 and GNI_SharedPoolCount[sharedPoolId] >= GNI_SharedPoolMax[sharedPoolId] then
        return false
    endif

    return true
endfunction

private function IncrementAssignmentCount takes integer assignId returns nothing
    local integer sharedPoolId = GNI_ZoneSharedPoolId[assignId]
    set GNI_ZoneActiveCount[assignId] = GNI_ZoneActiveCount[assignId] + 1
    if sharedPoolId >= 0 then
        set GNI_SharedPoolCount[sharedPoolId] = GNI_SharedPoolCount[sharedPoolId] + 1
    endif
endfunction

private function DecrementAssignmentCount takes integer assignId returns nothing
    local integer sharedPoolId = GNI_ZoneSharedPoolId[assignId]
    set GNI_ZoneActiveCount[assignId] = GNI_ZoneActiveCount[assignId] - 1
    if GNI_ZoneActiveCount[assignId] < 0 then
        set GNI_ZoneActiveCount[assignId] = 0
    endif
    if sharedPoolId >= 0 then
        set GNI_SharedPoolCount[sharedPoolId] = GNI_SharedPoolCount[sharedPoolId] - 1
        if GNI_SharedPoolCount[sharedPoolId] < 0 then
            set GNI_SharedPoolCount[sharedPoolId] = 0
        endif
    endif
endfunction

private function ApplyGlowEffect takes item it, integer defId returns nothing
    if not GNI_DefGlowEffect[defId] then
        return
    endif

    call GN_ApplyPointGlowToHandle(it, GetItemX(it), GetItemY(it), GNI_DefGlowR[defId], GNI_DefGlowG[defId], GNI_DefGlowB[defId], GNI_DefGlowAlpha[defId], GNI_DefGlowScale[defId], GNI_DefGlowHeight[defId])
endfunction

private function RemoveGlowEffect takes item it returns nothing
    call GN_RemoveGlowFromHandle(it)
endfunction

private function PickReplacementAssignment takes integer sourceAssignId returns integer
    local integer i = 0
    local integer totalWeight = 0
    local integer roll
    local integer weight
    local integer sourceZoneId
    local integer sourceGroupId
    local integer sourceCategoryId

    if sourceAssignId < 0 or sourceAssignId >= GNI_ZoneAssignmentCount then
        return -1
    endif

    set sourceZoneId = GNI_ZoneId[sourceAssignId]
    set sourceGroupId = GNI_ZoneSpawnGroupId[sourceAssignId]
    set sourceCategoryId = GNI_DefCategoryId[GNI_ZoneDefId[sourceAssignId]]

    loop
        exitwhen i >= GNI_ZoneAssignmentCount
        if GNI_ZoneId[i] == sourceZoneId and GNI_ZoneSpawnGroupId[i] == sourceGroupId and GNI_DefCategoryId[GNI_ZoneDefId[i]] == sourceCategoryId and CanSpawnAssignment(i) then
            set totalWeight = totalWeight + GetEffectiveWeight(i)
        endif
        set i = i + 1
    endloop

    if totalWeight <= 0 then
        return -1
    endif

    set roll = GetRandomInt(1, totalWeight)
    set i = 0
    loop
        exitwhen i >= GNI_ZoneAssignmentCount
        if GNI_ZoneId[i] == sourceZoneId and GNI_ZoneSpawnGroupId[i] == sourceGroupId and GNI_DefCategoryId[GNI_ZoneDefId[i]] == sourceCategoryId and CanSpawnAssignment(i) then
            set weight = GetEffectiveWeight(i)
            set roll = roll - weight
            if roll <= 0 then
                return i
            endif
        endif
        set i = i + 1
    endloop

    return -1
endfunction

// Timer callback for scheduling a fresh spawn attempt
private function RespawnTimerCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer handleId = GetHandleId(t)
    local integer assignId
    local integer poolId
    local integer timerGeneration = -1

    if GNI_TimerGeneration.has(handleId) then
        set timerGeneration = GNI_TimerGeneration.integer[handleId]
    endif
    
    if GNI_TimerAssignId.has(handleId) then
        set assignId = GNI_TimerAssignId.integer[handleId]
        
        // Trigger a fresh spawn attempt if the system and zone are enabled.
        if timerGeneration == GNI_RefreshGeneration and GN_IsSystemEnabled() and GN_IsZoneEnabled(GNI_ZoneId[assignId]) then
            call TriggerFreshSpawn(assignId)
        endif
        
        // Cleanup timer data
        call GNI_TimerDefId.remove(handleId)
        call GNI_TimerZoneId.remove(handleId)
        call GNI_TimerAssignId.remove(handleId)
        if GNI_TimerRegion.has(handleId) then
            call GNI_TimerRegion.remove(handleId)
        endif
        if GNI_TimerGeneration.has(handleId) then
            call GNI_TimerGeneration.remove(handleId)
        endif
    endif
    
    call ReleaseTimer(t)
    set t = null
endfunction

// Schedule a fresh spawn attempt
function GNI_ScheduleRespawn takes integer assignId returns nothing
    local timer t
    local real respawnTime
    local integer handleId
    local integer defId
    
    if assignId < 0 or assignId >= GNI_ZoneAssignmentCount then
        return
    endif

    set defId = GNI_ZoneDefId[assignId]
    
    set respawnTime = GN_GetRandomReal(GNI_DefRespawnMin[defId], GNI_DefRespawnMax[defId])
    set t = NewTimer()
    set handleId = GetHandleId(t)
    
    set GNI_TimerDefId.integer[handleId] = defId
    set GNI_TimerZoneId.integer[handleId] = GNI_ZoneId[assignId]
    set GNI_TimerAssignId.integer[handleId] = assignId
    set GNI_TimerGeneration.integer[handleId] = GNI_RefreshGeneration
    
    call TimerStart(t, respawnTime, false, function RespawnTimerCallback)
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Scheduled new category spawn attempt in zone " + I2S(GNI_ZoneId[assignId]) + " in " + R2S(respawnTime) + "s")
    endif
endfunction

private function GNI_HandleLifetimeExpire takes item it returns nothing
    local integer itemHandleId
    local integer defId
    local integer zoneId
    local integer assignId

    if it == null then
        return
    endif

    set itemHandleId = GetHandleId(it)
    if GNI_ItemLifetimeTimer.has(itemHandleId) and GNI_ItemToDefId.has(itemHandleId) then
        set defId = GNI_ItemToDefId.integer[itemHandleId]
        set zoneId = GNI_ItemToZoneId.integer[itemHandleId]
        if GNI_ItemToAssignId.has(itemHandleId) then
            set assignId = GNI_ItemToAssignId.integer[itemHandleId]
        else
            set assignId = -1
        endif

        call GNI_ItemLifetimeTimer.remove(itemHandleId)
        call RemoveGlowEffect(it)
        call GN_UnregisterItem(it, zoneId)
        call GNI_ItemToDefId.remove(itemHandleId)
        call GNI_ItemToZoneId.remove(itemHandleId)
        if GNI_ItemToAssignId.has(itemHandleId) then
            call GNI_ItemToAssignId.remove(itemHandleId)
        endif
        if GNI_ItemLocation.has(itemHandleId) then
            call GNI_ItemLocation.remove(itemHandleId)
        endif
        if GNI_ItemSpawnX.has(itemHandleId) then
            call GNI_ItemSpawnX.remove(itemHandleId)
        endif
        if GNI_ItemSpawnY.has(itemHandleId) then
            call GNI_ItemSpawnY.remove(itemHandleId)
        endif
        if assignId >= 0 then
            call DecrementAssignmentCount(assignId)
        endif
        call RemoveItem(it)

        if assignId >= 0 and GN_IsSystemEnabled() and GN_IsZoneEnabled(zoneId) then
            call GNI_ScheduleRespawn(assignId)
        endif

        if GN_IsDebugMode() then
            call BJDebugMsg("|cff00ff00[GatherNodeItems]|r " + GNI_DefNodeName[defId] + " despawned, scheduling new spawn attempt")
        endif
    endif
endfunction

private function GNI_CheckExpiredItems takes nothing returns nothing
    local integer index = GN_GetActiveItemCount() - 1
    local item it
    local integer handleId
    local real now = GNI_GetNow()

    loop
        exitwhen index < 0
        set it = GN_GetActiveItemByIndex(index)
        if it != null then
            set handleId = GetHandleId(it)
            if GNI_ItemToDefId.has(handleId) and GNI_ItemLifetimeTimer.has(handleId) and GNI_ItemLifetimeTimer.real[handleId] <= now then
                call GNI_HandleLifetimeExpire(it)
            endif
        endif
        set index = index - 1
    endloop
    set it = null
endfunction

private function StartLifetimeTimer takes item it, integer defId returns nothing
    local integer handleId = GetHandleId(it)
    local real lifeTime = GN_GetRandomReal(GNI_DefRespawnMin[defId], GNI_DefRespawnMax[defId])

    call CancelLifetimeTimer(it)

    set GNI_ItemLifetimeTimer.real[handleId] = GNI_GetNow() + lifeTime

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r " + GNI_DefNodeName[defId] + " will despawn in " + R2S(lifeTime) + "s")
    endif
endfunction

// Spawn an item at a specific location
function GNI_SpawnItemAt takes integer defId, real x, real y, integer zoneId, integer assignId returns item
    local item it
    local integer itemCode
    
    if defId < 0 or defId >= GNI_DefinitionCount then
        return null
    endif
    
    if not GNI_DefEnabled[defId] then
        return null
    endif
    
    set itemCode = GNI_DefItemCode[defId]
    if not GN_IsTerrainAllowedForNode(zoneId, x, y, GNI_DefPreventWaterSpawn[defId], false) then
        return null
    endif

    set it = CreateItem(itemCode, x, y)
    
    if it != null then
        // Register with master system
        call GN_RegisterActiveItem(it, defId, zoneId, GNI_DefProfessionId[defId], GNI_DefSkillRequired[defId], GNI_DefNodeName[defId])
        
        // Track locally
        set GNI_ItemToDefId.integer[GetHandleId(it)] = defId
        set GNI_ItemToZoneId.integer[GetHandleId(it)] = zoneId
        if assignId >= 0 then
            set GNI_ItemToAssignId.integer[GetHandleId(it)] = assignId
            call IncrementAssignmentCount(assignId)
        endif
        set GNI_ItemSpawnX.real[GetHandleId(it)] = x
        set GNI_ItemSpawnY.real[GetHandleId(it)] = y

        call ApplyGlowEffect(it, defId)
        call StartLifetimeTimer(it, defId)

        call GN_DebugPingSpawn(x, y, false)
        
        if GN_IsDebugMode() then
            call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Spawned " + GNI_DefNodeName[defId] + " at (" + R2S(x) + ", " + R2S(y) + ")")
        endif
    endif
    
    return it
endfunction

// Spawn an item in a random location within a zone
function GNI_SpawnItemInZone takes integer defId, integer zoneId, integer assignId returns item
    local rect r = GetZoneSpawnRect(zoneId)
    local real x
    local real y
    local integer attempts = 0
    local item it = null
    
    if r == null then
        if GN_IsDebugMode() then
            call BJDebugMsg("|cffff8800[GatherNodeItems]|r No zone spawn rect configured in ZonesCore for zone " + I2S(zoneId))
        endif
        return null
    endif
    
    // Try to find a pathable spawn point
    loop
        exitwhen attempts >= GN_RANDOM_SPAWN_ATTEMPTS or it != null
        
        set x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
        set y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
        
        if not GN_IsPointInRestrictedRect(zoneId, x, y, false) and GN_IsPointPathable(x, y) and GN_IsItemSpawnAreaClear(x, y) then
            set it = GNI_SpawnItemAt(defId, x, y, zoneId, assignId)
        endif
        
        set attempts = attempts + 1
    endloop
    
    return it
endfunction

function GNI_SpawnItemInGroup takes integer defId, integer zoneId, integer groupId, integer assignId returns item
    local rect r = GetRandomGroupRegion(groupId)
    local real x
    local real y
    local integer attempts = 0
    local item it = null

    if r == null then
        if GN_IsDebugMode() then
            call BJDebugMsg("|cffff8800[GatherNodeItems]|r No spawn regions for group " + I2S(groupId))
        endif
        return null
    endif

    loop
        exitwhen attempts >= GN_RANDOM_SPAWN_ATTEMPTS or it != null

        set x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
        set y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))

        if GN_IsPointPathable(x, y) and GN_IsItemSpawnAreaClear(x, y) then
            set it = GNI_SpawnItemAt(defId, x, y, zoneId, assignId)
        endif

        set attempts = attempts + 1
    endloop

    return it
endfunction

private function PickSharedPoolAssignment takes integer poolId returns integer
    local integer i = 0
    local integer totalWeight = 0
    local integer roll
    local integer weight

    loop
        exitwhen i >= GNI_ZoneAssignmentCount
        if GNI_ZoneSharedPoolId[i] == poolId and CanSpawnAssignment(i) then
            set totalWeight = totalWeight + GetEffectiveWeight(i)
        endif
        set i = i + 1
    endloop

    if totalWeight <= 0 then
        return -1
    endif

    set roll = GetRandomInt(1, totalWeight)
    set i = 0

    loop
        exitwhen i >= GNI_ZoneAssignmentCount
        if GNI_ZoneSharedPoolId[i] == poolId and CanSpawnAssignment(i) then
            set weight = GetEffectiveWeight(i)
            set roll = roll - weight
            if roll <= 0 then
                return i
            endif
        endif
        set i = i + 1
    endloop

    return -1
endfunction

private function GNI_SpawnItemForAssignment takes integer assignId returns item
    local item it = null
    local integer defId
    local integer zoneId
    local integer spawnMode
    local integer spawnGroupId

    if not CanSpawnAssignment(assignId) then
        return null
    endif

    set defId = GNI_ZoneDefId[assignId]
    set zoneId = GNI_ZoneId[assignId]
    set spawnMode = GNI_ZoneSpawnMode[assignId]
    set spawnGroupId = GNI_ZoneSpawnGroupId[assignId]

    if spawnMode == 1 then
        if spawnGroupId >= 0 then
            return GNI_SpawnItemInGroup(defId, zoneId, spawnGroupId, assignId)
        endif
        return null
    elseif spawnMode == 2 then
        if spawnGroupId >= 0 then
            set it = GNI_SpawnItemInGroup(defId, zoneId, spawnGroupId, assignId)
            if it != null then
                return it
            endif
        endif
        return GNI_SpawnItemInZone(defId, zoneId, assignId)
    endif

    return GNI_SpawnItemInZone(defId, zoneId, assignId)
endfunction

private function GNI_DoTriggerFreshSpawn takes nothing returns nothing
    local integer assignId = GNI_PendingFreshAssignId
    local integer replacementAssignId

    if assignId >= 0 then
        set replacementAssignId = PickReplacementAssignment(assignId)
        if replacementAssignId >= 0 then
            call GNI_SpawnItemForAssignment(replacementAssignId)
        endif
    endif
endfunction

private function SpawnSharedPoolItem takes integer poolId returns item
    local integer assignId
    local item it = null

    if poolId < 0 then
        return null
    endif

    loop
        exitwhen GNI_SharedPoolCount[poolId] >= GNI_SharedPoolMax[poolId] or it != null
        set assignId = PickSharedPoolAssignment(poolId)
        if assignId < 0 then
            return null
        endif
        set it = GNI_SpawnItemForAssignment(assignId)
        if it == null then
            return null
        endif
    endloop

    return it
endfunction

private function GNI_HandleItemPickup takes item it, unit picker returns nothing
    local integer handleId = GetHandleId(it)
    local integer defId
    local integer zoneId
    local integer assignId
    local real originalX
    local real originalY
    local boolean wasInDInv = false
    
    if not GNI_ItemToDefId.has(handleId) then
        return
    endif
    
    set defId = GNI_ItemToDefId.integer[handleId]
    set zoneId = GNI_ItemToZoneId.integer[handleId]
    if GNI_ItemToAssignId.has(handleId) then
        set assignId = GNI_ItemToAssignId.integer[handleId]
    else
        set assignId = -1
    endif

    if GNI_ItemSpawnX.has(handleId) then
        set originalX = GNI_ItemSpawnX.real[handleId]
        set originalY = GNI_ItemSpawnY.real[handleId]
    else
        set originalX = GetItemX(it)
        set originalY = GetItemY(it)
    endif

    if GNS_ShouldBlockItemPickup(picker, it) then
        set wasInDInv = GetPIDOfItem(it) >= 0
        call IssueImmediateOrder(picker, "stop")
        call UnitRemoveItem(picker, it)
        if wasInDInv or GetPIDOfItem(it) >= 0 then
            call FromItemHeavenToGround(it, originalX, originalY)
            call DeleteItemFromDInventory(it)
        else
            call SetItemPosition(it, originalX, originalY)
        endif
        if GN_IsDebugMode() then
            call BJDebugMsg("|cffff8800[GatherNodeItems]|r Blocked " + GetUnitName(picker) + " from gathering " + GNI_DefNodeName[defId])
        endif
        return
    endif

    call GNS_OnSuccessfulItemGather(picker, it)

    call CancelLifetimeTimer(it)
    call RemoveGlowEffect(it)
    call GN_UnregisterItem(it, zoneId)
    call GNI_ItemToDefId.remove(handleId)
    call GNI_ItemToZoneId.remove(handleId)
    if GNI_ItemToAssignId.has(handleId) then
        call GNI_ItemToAssignId.remove(handleId)
    endif
    if GNI_ItemLocation.has(handleId) then
        call GNI_ItemLocation.remove(handleId)
    endif
    if GNI_ItemSpawnX.has(handleId) then
        call GNI_ItemSpawnX.remove(handleId)
    endif
    if GNI_ItemSpawnY.has(handleId) then
        call GNI_ItemSpawnY.remove(handleId)
    endif
    if assignId >= 0 then
        call DecrementAssignmentCount(assignId)
        call GNI_ScheduleRespawn(assignId)
    endif
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r " + GetUnitName(picker) + " picked up " + GNI_DefNodeName[defId])
    endif
endfunction

private function GNI_OnPickupEvent takes nothing returns boolean
    call GNI_HandleItemPickup(GetManipulatedItem(), GetTriggerUnit())
    return false
endfunction

// External wrapper for item pickup handling
function GNI_OnItemPickup takes item it, unit picker returns nothing
    call GNI_HandleItemPickup(it, picker)
endfunction

// ============================================================
// INITIAL SPAWN FOR ZONES
// ============================================================

// Spawn initial nodes in a zone
function GNI_SpawnInitialInZone takes integer zoneId returns nothing
    local integer i = 0
    local integer spawned
    local integer poolId
    local integer array processedPools
    
    if not GN_IsZoneEnabled(zoneId) then
        return
    endif
    
    // Loop through zone assignments
    loop
        exitwhen i >= GNI_ZoneAssignmentCount
        
        if GNI_ZoneId[i] == zoneId and GNI_ZoneEnabled[i] then
            if GNI_DefEnabled[GNI_ZoneDefId[i]] then
                set poolId = GNI_ZoneSharedPoolId[i]
                set spawned = 0

                if poolId >= 0 then
                    if processedPools[poolId] == 0 then
                        loop
                            exitwhen GNI_SharedPoolCount[poolId] >= GNI_SharedPoolMax[poolId]
                            if SpawnSharedPoolItem(poolId) != null then
                                set spawned = spawned + 1
                            else
                                exitwhen true
                            endif
                        endloop
                        set processedPools[poolId] = 1
                    endif
                else
                    loop
                        exitwhen not CanSpawnAssignment(i)
                        if GNI_SpawnItemForAssignment(i) != null then
                            set spawned = spawned + 1
                        else
                            exitwhen true
                        endif
                    endloop
                endif

                if GN_IsDebugMode() and spawned > 0 then
                    call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Spawned " + I2S(spawned) + " " + GNI_DefNodeName[GNI_ZoneDefId[i]] + " in zone " + I2S(zoneId))
                endif
            endif
        endif
        
        set i = i + 1
    endloop
endfunction

// Spawn initial nodes in all zones
function GNI_SpawnInitialAll takes nothing returns nothing
    local integer zoneId = 1
    
    loop
        exitwhen zoneId > 100 // Assume max 100 zones
        call GNI_SpawnInitialInZone(zoneId)
        set zoneId = zoneId + 1
    endloop
endfunction

function GNI_DebugRefreshAll takes nothing returns nothing
    local item it
    local integer handleId
    local integer zoneId
    local integer assignId

    set GNI_RefreshGeneration = GNI_RefreshGeneration + 1

    loop
        exitwhen GN_GetActiveItemCount() <= 0
        set it = GN_GetActiveItemByIndex(GN_GetActiveItemCount() - 1)
        if it == null then
            exitwhen true
        endif

        set handleId = GetHandleId(it)
        if GNI_ItemToDefId.has(handleId) then
            set zoneId = GNI_ItemToZoneId.integer[handleId]
            if GNI_ItemToAssignId.has(handleId) then
                set assignId = GNI_ItemToAssignId.integer[handleId]
            else
                set assignId = -1
            endif

            call CancelLifetimeTimer(it)
            call RemoveGlowEffect(it)
            call GN_UnregisterItem(it, zoneId)
            call GNI_ItemToDefId.remove(handleId)
            call GNI_ItemToZoneId.remove(handleId)
            if GNI_ItemToAssignId.has(handleId) then
                call GNI_ItemToAssignId.remove(handleId)
            endif
            if GNI_ItemLocation.has(handleId) then
                call GNI_ItemLocation.remove(handleId)
            endif
            if GNI_ItemSpawnX.has(handleId) then
                call GNI_ItemSpawnX.remove(handleId)
            endif
            if GNI_ItemSpawnY.has(handleId) then
                call GNI_ItemSpawnY.remove(handleId)
            endif
            if assignId >= 0 then
                call DecrementAssignmentCount(assignId)
            endif
            call RemoveItem(it)
        else
            exitwhen true
        endif
    endloop

    call GNI_SpawnInitialAll()

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Debug refresh complete")
    endif

    set it = null
endfunction

// ============================================================
// QUERY FUNCTIONS
// ============================================================

function GNI_GetDefinitionCount takes nothing returns integer
    return GNI_DefinitionCount
endfunction

function GNI_GetDefinitionName takes integer defId returns string
    if defId < 0 or defId >= GNI_DefinitionCount then
        return ""
    endif
    return GNI_DefNodeName[defId]
endfunction

function GNI_GetDefinitionItemCode takes integer defId returns integer
    if defId < 0 or defId >= GNI_DefinitionCount then
        return 0
    endif
    return GNI_DefItemCode[defId]
endfunction

function GNI_GetDefinitionSkillRequired takes integer defId returns integer
    if defId < 0 or defId >= GNI_DefinitionCount then
        return 0
    endif
    return GNI_DefSkillRequired[defId]
endfunction

function GNI_GetDefinitionProfessionId takes integer defId returns integer
    if defId < 0 or defId >= GNI_DefinitionCount then
        return 0
    endif
    return GNI_DefProfessionId[defId]
endfunction

function GNI_IsDefinitionRare takes integer defId returns boolean
    if defId < 0 or defId >= GNI_DefinitionCount then
        return false
    endif
    return GNI_DefIsRare[defId]
endfunction

// ============================================================
// ENABLE/DISABLE
// ============================================================

function GNI_SetDefinitionEnabled takes integer defId, boolean enabled returns nothing
    if defId >= 0 and defId < GNI_DefinitionCount then
        set GNI_DefEnabled[defId] = enabled
    endif
endfunction

function GNI_IsDefinitionEnabled takes integer defId returns boolean
    if defId < 0 or defId >= GNI_DefinitionCount then
        return false
    endif
    return GNI_DefEnabled[defId]
endfunction

private function GNI_IsTrackedItemMissing takes item it returns boolean
    if it == null then
        return true
    endif
    if GetItemTypeId(it) == 0 then
        return true
    endif
    if GetWidgetLife(it) <= 0.405 then
        return true
    endif
    return false
endfunction

private function GNI_HandleExternalItemRemoval takes item it returns nothing
    local integer handleId
    local integer zoneId
    local integer assignId
    local integer defId

    if it == null then
        return
    endif

    set handleId = GetHandleId(it)
    if not GNI_ItemToDefId.has(handleId) then
        return
    endif

    set defId = GNI_ItemToDefId.integer[handleId]
    set zoneId = GNI_ItemToZoneId.integer[handleId]
    if GNI_ItemToAssignId.has(handleId) then
        set assignId = GNI_ItemToAssignId.integer[handleId]
    else
        set assignId = -1
    endif

    call CancelLifetimeTimer(it)
    call RemoveGlowEffect(it)
    call GN_UnregisterItem(it, zoneId)
    call GNI_ItemToDefId.remove(handleId)
    call GNI_ItemToZoneId.remove(handleId)
    if GNI_ItemToAssignId.has(handleId) then
        call GNI_ItemToAssignId.remove(handleId)
    endif
    if GNI_ItemLocation.has(handleId) then
        call GNI_ItemLocation.remove(handleId)
    endif
    if GNI_ItemSpawnX.has(handleId) then
        call GNI_ItemSpawnX.remove(handleId)
    endif
    if GNI_ItemSpawnY.has(handleId) then
        call GNI_ItemSpawnY.remove(handleId)
    endif
    if assignId >= 0 then
        call DecrementAssignmentCount(assignId)
        if GN_IsSystemEnabled() and GN_IsZoneEnabled(zoneId) then
            call GNI_ScheduleRespawn(assignId)
        endif
    endif

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r " + GNI_DefNodeName[defId] + " was removed externally, scheduling new spawn attempt")
    endif
endfunction

private function GNI_ValidateTrackedItems takes nothing returns nothing
    local integer index = GN_GetActiveItemCount() - 1
    local item it

    loop
        exitwhen index < 0
        set it = GN_GetActiveItemByIndex(index)
        if it != null and GNI_ItemToDefId.has(GetHandleId(it)) and GNI_IsTrackedItemMissing(it) then
            call GNI_HandleExternalItemRemoval(it)
        endif
        set index = index - 1
    endloop

    set it = null
endfunction

// ============================================================
// INITIALIZATION
// ============================================================
private function Init takes nothing returns nothing
    local integer playerIndex = 0

    set GNI_ItemToDefId = Table.create()
    set GNI_ItemToZoneId = Table.create()
    set GNI_ItemToAssignId = Table.create()
    set GNI_ItemLocation = Table.create()
    set GNI_ItemSpawnX = Table.create()
    set GNI_ItemSpawnY = Table.create()
    set GNI_ItemLifetimeTimer = Table.create()
    set GNI_TimerDefId = Table.create()
    set GNI_TimerZoneId = Table.create()
    set GNI_TimerAssignId = Table.create()
    set GNI_TimerRegion = Table.create()
    set GNI_TimerGeneration = Table.create()
    set GNI_LifetimeTimerItem = Table.create()
    set GNI_LifetimeTimerGeneration = Table.create()

    set GNI_PickupTrigger = CreateTrigger()
    set GNI_FreshSpawnTrigger = CreateTrigger()
    set GNI_LifetimeExpireTrigger = CreateTrigger()
    set GNI_ValidationTrigger = CreateTrigger()
    set GNI_ClockTimer = CreateTimer()
    set GNI_LifetimeCheckTimer = CreateTimer()
    loop
        exitwhen playerIndex >= 24
        call TriggerRegisterPlayerUnitEvent(GNI_PickupTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
        set playerIndex = playerIndex + 1
    endloop
    call TimerStart(GNI_ClockTimer, 999999.0, false, function GNI_NoOp)
    call TriggerRegisterTimerEventPeriodic(GNI_ValidationTrigger, GNI_VALIDATION_INTERVAL)
    call TimerStart(GNI_LifetimeCheckTimer, GNI_LIFETIME_CHECK_INTERVAL, true, function GNI_CheckExpiredItems)
    call TriggerAddCondition(GNI_PickupTrigger, Condition(function GNI_OnPickupEvent))
    call TriggerAddAction(GNI_FreshSpawnTrigger, function GNI_DoTriggerFreshSpawn)
    call TriggerAddAction(GNI_ValidationTrigger, function GNI_ValidateTrackedItems)
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeItems]|r Subsystem initialized")
    endif
endfunction

endlibrary
