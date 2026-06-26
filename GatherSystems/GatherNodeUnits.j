// ============================================================
// GatherNodeUnits - Unit Node Spawning Subsystem
// ============================================================
// Handles spawning and timed re-spawning of unit-based gather nodes:
// - Ore Veins (copper, iron, gold, etc.)
// - Crystal Veins (gems, crystals)
// - Rich Veins (high-yield nodes)
// - Fish Pools
// - Treasure Chests
// - Rare Spawns
//
// Units spawn at fixed spawn points or random regions
// When killed/looted, a fresh spawn attempt is scheduled
// Supports vein glow effects for visibility
//
// Dependencies:
//   - GatherNodes.j (master system)
//   - Zones.j (zone tracking)
//   - TimerUtils (timer recycling)
//   - Table (hashtable wrapper)
//
// ============================================================

library GatherNodeUnits initializer Init requires GatherNodes, GatherNodeSkills, DamageEngine, ZonesCore, TimerUtils, Table

// ============================================================
// CONFIGURATION
// ============================================================
globals
    // Maximum unit node definitions
    private constant integer GNU_MAX_DEFINITIONS = 200
    
    // Maximum zone assignments per definition
    private constant integer GNU_MAX_ZONE_ASSIGNMENTS = 100
    
    // Maximum spawn points per zone
    private constant integer GNU_MAX_SPAWN_POINTS = 100
    
    // Default owner player for nodes (Neutral Passive)
    private constant integer GNU_DEFAULT_OWNER = 24
    
    // Fixed spawn points are also blocked by any nearby unit, not only other gather nodes.
    private constant real GNU_SPAWN_POINT_UNIT_BLOCK_RADIUS = 128.0

    // Maximum shared category pools
    private constant integer GNU_MAX_SHARED_POOLS = 512

    // Maximum reward rows
    private constant integer GNU_MAX_DROPS = 2000

    private constant integer GNU_SPECIAL_BEHAVIOR_NONE = 0
    private constant integer GNU_SPECIAL_BEHAVIOR_MANA_CRYSTAL_EXPLOSION = 1
    private constant integer GNU_MINING_PICK_ITEM_CODE = 'I672'
    private constant real GNU_MANA_CRYSTAL_EXPLOSION_RADIUS = 300.0
    private constant real GNU_MANA_CRYSTAL_EXPLOSION_DAMAGE = 400.0
    private constant real GNU_MANA_CRYSTAL_MANA_DRAIN_FACTOR = 0.30
    private constant string GNU_MANA_CRYSTAL_EXPLOSION_EFFECT = "Abilities\\Weapons\\DragonHawkMissile\\DragonHawkMissile.mdl"
    private constant real GNU_LIFETIME_CHECK_INTERVAL = 1.00
endglobals

// ============================================================
// UNIT NODE DEFINITION STRUCT
// ============================================================
globals
    // Definition arrays
    private integer array GNU_DefUnitCode        // Raw code of unit to spawn
    private string array GNU_DefNodeName         // Display name
    private integer array GNU_DefCategoryId      // Category for grouping
    private integer array GNU_DefSpawnWeight     // Weight for random selection
    private real array GNU_DefRespawnMin         // Min respawn time
    private real array GNU_DefRespawnMax         // Max respawn time
    private integer array GNU_DefMaxPerZone      // Max instances per zone
    private integer array GNU_DefSkillRequired   // Required skill level
    private integer array GNU_DefProfessionId    // Profession required for gathering
    private integer array GNU_DefHarvestYieldMin // Min successful gathers before depletion
    private integer array GNU_DefHarvestYieldMax // Max successful gathers before depletion
    private integer array GNU_DefGatherChancePct // Success chance per gather hit
    private integer array GNU_DefMainDropGroupChancePct
    private integer array GNU_DefSecondaryDropGroupChancePct
    private integer array GNU_DefSpecialBehaviorId // Special scripted behavior
    private integer array GNU_DefSpecialChancePct // Chance for special behavior after success
    private integer array GNU_DefOwnerPlayer     // Owner player ID
    private boolean array GNU_DefPreventWaterSpawn // Do not spawn in water/amphibious terrain
    private boolean array GNU_DefGlowEffect      // Show glow effect?
    private integer array GNU_DefGlowR           // Glow red
    private integer array GNU_DefGlowG           // Glow green
    private integer array GNU_DefGlowB           // Glow blue
    private integer array GNU_DefGlowAlpha       // Glow alpha
    private real array GNU_DefGlowScale          // Glow scale
    private real array GNU_DefGlowHeight         // Glow height offset
    private boolean array GNU_DefIsRare          // Rare spawn?
    private boolean array GNU_DefEnabled         // Is enabled?
    
    private integer GNU_DefinitionCount = 0
    
    // Zone assignments
    private integer array GNU_ZoneDefId          // Definition ID
    private integer array GNU_ZoneId             // Zone ID
    private integer array GNU_ZoneSpawnMode      // 0=random, 1=spawn group, 2=group+random fallback
    private integer array GNU_ZoneSpawnGroupId   // Spawn group id (-1 = none)
    private integer array GNU_ZoneWeightOverride // Override weight (-1 = use default)
    private integer array GNU_ZoneMaxOverride    // Override max (-1 = use default)
    private integer array GNU_ZoneSharedMaxOverride // Shared category max (-1 = use default)
    private integer array GNU_ZoneSharedPoolId   // Shared pool id (-1 = none)
    private integer array GNU_ZoneActiveCount    // Active spawned count for this assignment
    private boolean array GNU_ZoneEnabled        // Zone assignment enabled?
    
    private integer GNU_ZoneAssignmentCount = 0
    
    // Fixed spawn points
    private real array GNU_SpawnPointX
    private real array GNU_SpawnPointY
    private real array GNU_SpawnPointFacing
    private integer array GNU_SpawnPointZoneId
    private integer array GNU_SpawnPointGroupId
    private integer array GNU_SpawnPointDefId    // Specific definition (-1 = any)
    private integer array GNU_SpawnPointNodeType // Category filter (-1 = any)
    private boolean array GNU_SpawnPointOccupied
    private unit array GNU_SpawnPointUnit        // Currently spawned unit
    
    private integer GNU_SpawnPointCount = 0
    
    // Random spawn regions per zone
    private rect array GNU_SpawnRegions
    private integer array GNU_SpawnRegionZoneId
    private integer GNU_SpawnRegionCount = 0
    
    // Active unit tracking
    private Table GNU_UnitToDefId       // unit handle -> definition id
    private Table GNU_UnitToZoneId      // unit handle -> zone id
    private Table GNU_UnitToAssignId    // unit handle -> zone assignment id
    private Table GNU_UnitToSpawnPoint  // unit handle -> spawn point id (-1 if random)
    private Table GNU_UnitLifetimeTimer // unit handle -> absolute despawn time
    private Table GNU_UnitHarvestCount  // unit handle -> gathered count
    private Table GNU_UnitHarvestTotal  // unit handle -> total yield
    
    // Respawn timer data
    private Table GNU_TimerDefId        // timer handle -> definition id
    private Table GNU_TimerZoneId       // timer handle -> zone id
    private Table GNU_TimerAssignId     // timer handle -> zone assignment id
    private Table GNU_TimerGeneration   // timer handle -> refresh generation
    private Table GNU_LifetimeTimerUnit // timer handle -> unit handle
    private Table GNU_LifetimeTimerGeneration // timer handle -> refresh generation
    
    // Death trigger
    private trigger GNU_DeathTrigger = null
    private trigger GNU_FreshSpawnTrigger = null
    private trigger GNU_LifetimeExpireTrigger = null
    private trigger GNU_HarvestTrigger = null
    private trigger GNU_ValidationTrigger = null
    private timer GNU_LifetimeCheckTimer = null

    // Shared category pools
    private integer array GNU_SharedPoolCategoryId
    private integer array GNU_SharedPoolZoneId
    private integer array GNU_SharedPoolGroupId
    private integer array GNU_SharedPoolMax
    private integer array GNU_SharedPoolCount
    private integer GNU_SharedPoolCountTotal = 0

    // Refresh generation invalidates old respawn timers
    private integer GNU_RefreshGeneration = 0
    private integer GNU_PendingFreshAssignId = -1
    private constant real GNU_VALIDATION_INTERVAL = 15.00
    private timer GNU_ClockTimer = null

    // Reward rows
    private integer array GNU_DropDefId
    private integer array GNU_DropGroupKey
    private integer array GNU_DropItemCode
    private integer array GNU_DropChancePct
    private integer array GNU_DropWeight
    private integer array GNU_DropMinQty
    private integer array GNU_DropMaxQty
    private boolean array GNU_DropEnabled
    private integer GNU_DropCount = 0
endglobals

// ============================================================
// DEFINITION REGISTRATION
// ============================================================

private function GNU_TriggerFreshSpawn takes integer assignId returns nothing
    if assignId >= 0 then
        set GNU_PendingFreshAssignId = assignId
        call TriggerExecute(GNU_FreshSpawnTrigger)
        set GNU_PendingFreshAssignId = -1
    endif
endfunction

private function GNU_NoOp takes nothing returns nothing
endfunction

private function GNU_GetNow takes nothing returns real
    if GNU_ClockTimer == null then
        return 0.0
    endif
    return TimerGetElapsed(GNU_ClockTimer)
endfunction

private function GNU_CancelLifetimeTimer takes unit u returns nothing
    local integer handleId = GetHandleId(u)

    if GNU_UnitLifetimeTimer.real.has(handleId) then
        call GNU_UnitLifetimeTimer.real.remove(handleId)
    endif
endfunction

// Register a new unit node definition
function GNU_RegisterDefinition takes integer unitCode, string nodeName, integer categoryId, integer spawnWeight, real respawnMin, real respawnMax, integer maxPerZone, integer skillRequired, integer professionId, integer harvestYieldMin, integer harvestYieldMax, integer gatherChancePct, integer mainDropGroupChancePct, integer secondaryDropGroupChancePct, integer specialBehaviorId, integer specialChancePct, integer ownerPlayer, boolean preventWaterSpawn, boolean glowEffect, integer glowR, integer glowG, integer glowB, integer glowAlpha, real glowScale, real glowHeight, boolean isRare returns integer
    local integer defId = GNU_DefinitionCount
    
    if defId >= GNU_MAX_DEFINITIONS then
        call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ERROR: Max definitions reached!")
        return -1
    endif
    
    set GNU_DefUnitCode[defId] = unitCode
    set GNU_DefNodeName[defId] = nodeName
    set GNU_DefCategoryId[defId] = categoryId
    set GNU_DefSpawnWeight[defId] = spawnWeight
    set GNU_DefRespawnMin[defId] = respawnMin
    set GNU_DefRespawnMax[defId] = respawnMax
    set GNU_DefMaxPerZone[defId] = maxPerZone
    set GNU_DefSkillRequired[defId] = skillRequired
    set GNU_DefProfessionId[defId] = professionId
    set GNU_DefHarvestYieldMin[defId] = harvestYieldMin
    set GNU_DefHarvestYieldMax[defId] = harvestYieldMax
    set GNU_DefGatherChancePct[defId] = gatherChancePct
    set GNU_DefMainDropGroupChancePct[defId] = mainDropGroupChancePct
    set GNU_DefSecondaryDropGroupChancePct[defId] = secondaryDropGroupChancePct
    set GNU_DefSpecialBehaviorId[defId] = specialBehaviorId
    set GNU_DefSpecialChancePct[defId] = specialChancePct
    set GNU_DefOwnerPlayer[defId] = ownerPlayer
    set GNU_DefPreventWaterSpawn[defId] = preventWaterSpawn
    set GNU_DefGlowEffect[defId] = glowEffect
    set GNU_DefGlowR[defId] = glowR
    set GNU_DefGlowG[defId] = glowG
    set GNU_DefGlowB[defId] = glowB
    set GNU_DefGlowAlpha[defId] = glowAlpha
    set GNU_DefGlowScale[defId] = glowScale
    set GNU_DefGlowHeight[defId] = glowHeight
    set GNU_DefIsRare[defId] = isRare
    set GNU_DefEnabled[defId] = true
    
    set GNU_DefinitionCount = GNU_DefinitionCount + 1
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Registered: " + nodeName + " (ID: " + I2S(defId) + ")")
    endif
    
    return defId
endfunction

function GNU_GetDefinitionIdByUnitCode takes integer unitCode returns integer
    local integer i = 0

    loop
        exitwhen i >= GNU_DefinitionCount
        if GNU_DefUnitCode[i] == unitCode then
            return i
        endif
        set i = i + 1
    endloop

    return -1
endfunction

function GNU_RegisterDrop takes integer defId, string groupName, integer itemCode, integer dropChancePct, integer weight, integer minQty, integer maxQty, boolean enabled returns integer
    local integer dropId = GNU_DropCount

    if defId < 0 or defId >= GNU_DefinitionCount then
        return -1
    endif
    if dropId >= GNU_MAX_DROPS then
        call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ERROR: Max reward rows reached!")
        return -1
    endif

    set GNU_DropDefId[dropId] = defId
    set GNU_DropGroupKey[dropId] = StringHash(groupName)
    set GNU_DropItemCode[dropId] = itemCode
    set GNU_DropChancePct[dropId] = dropChancePct
    set GNU_DropWeight[dropId] = weight
    set GNU_DropMinQty[dropId] = minQty
    set GNU_DropMaxQty[dropId] = maxQty
    set GNU_DropEnabled[dropId] = enabled
    set GNU_DropCount = GNU_DropCount + 1

    return dropId
endfunction

private function GNU_EnsureSharedPool takes integer defId, integer zoneId, integer groupId, integer sharedMax returns integer
    local integer i = 0
    local integer categoryId = GNU_DefCategoryId[defId]

    loop
        exitwhen i >= GNU_SharedPoolCountTotal
        if GNU_SharedPoolCategoryId[i] == categoryId and GNU_SharedPoolZoneId[i] == zoneId and GNU_SharedPoolGroupId[i] == groupId then
            if sharedMax >= 0 and sharedMax < GNU_SharedPoolMax[i] then
                set GNU_SharedPoolMax[i] = sharedMax
            endif
            return i
        endif
        set i = i + 1
    endloop

    if GNU_SharedPoolCountTotal >= GNU_MAX_SHARED_POOLS then
        call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ERROR: Max shared pools reached!")
        return -1
    endif

    set i = GNU_SharedPoolCountTotal
    set GNU_SharedPoolCategoryId[i] = categoryId
    set GNU_SharedPoolZoneId[i] = zoneId
    set GNU_SharedPoolGroupId[i] = groupId
    set GNU_SharedPoolMax[i] = sharedMax
    set GNU_SharedPoolCount[i] = 0
    set GNU_SharedPoolCountTotal = GNU_SharedPoolCountTotal + 1

    return i
endfunction

// Register a zone assignment
function GNU_RegisterZoneAssignment takes integer defId, integer zoneId, integer spawnMode, integer spawnGroupId, integer weightOverride, integer maxOverride, integer sharedMaxOverride returns integer
    local integer assignId = GNU_ZoneAssignmentCount
    
    if assignId >= GNU_MAX_DEFINITIONS * GNU_MAX_ZONE_ASSIGNMENTS then
        call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ERROR: Max zone assignments reached!")
        return -1
    endif
    
    set GNU_ZoneDefId[assignId] = defId
    set GNU_ZoneId[assignId] = zoneId
    set GNU_ZoneSpawnMode[assignId] = spawnMode
    set GNU_ZoneSpawnGroupId[assignId] = spawnGroupId
    set GNU_ZoneWeightOverride[assignId] = weightOverride
    set GNU_ZoneMaxOverride[assignId] = maxOverride
    set GNU_ZoneSharedMaxOverride[assignId] = sharedMaxOverride
    set GNU_ZoneSharedPoolId[assignId] = -1
    set GNU_ZoneActiveCount[assignId] = 0
    set GNU_ZoneEnabled[assignId] = true

    if sharedMaxOverride >= 0 then
        set GNU_ZoneSharedPoolId[assignId] = GNU_EnsureSharedPool(defId, zoneId, spawnGroupId, sharedMaxOverride)
    endif
    
    set GNU_ZoneAssignmentCount = GNU_ZoneAssignmentCount + 1
    
    return assignId
endfunction

// Register a fixed spawn point
function GNU_RegisterSpawnPoint takes integer groupId, integer zoneId, real x, real y, real facing, integer defId, integer nodeType returns integer
    local integer spawnId = GNU_SpawnPointCount
    
    if spawnId >= GNU_MAX_SPAWN_POINTS * 100 then
        call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ERROR: Max spawn points reached!")
        return -1
    endif
    
    set GNU_SpawnPointX[spawnId] = x
    set GNU_SpawnPointY[spawnId] = y
    set GNU_SpawnPointFacing[spawnId] = facing
    set GNU_SpawnPointZoneId[spawnId] = zoneId
    set GNU_SpawnPointGroupId[spawnId] = groupId
    set GNU_SpawnPointDefId[spawnId] = defId      // -1 means any
    set GNU_SpawnPointNodeType[spawnId] = nodeType // -1 means any
    set GNU_SpawnPointOccupied[spawnId] = false
    set GNU_SpawnPointUnit[spawnId] = null
    
    set GNU_SpawnPointCount = GNU_SpawnPointCount + 1
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Registered spawn point " + I2S(spawnId) + " at (" + R2S(x) + ", " + R2S(y) + ")")
    endif
    
    return spawnId
endfunction

// Register a random spawn region for a zone
function GNU_RegisterSpawnRegion takes integer zoneId, rect r returns integer
    local integer regionId = GNU_SpawnRegionCount
    
    set GNU_SpawnRegions[regionId] = r
    set GNU_SpawnRegionZoneId[regionId] = zoneId
    
    set GNU_SpawnRegionCount = GNU_SpawnRegionCount + 1
    
    return regionId
endfunction

// ============================================================
// GLOW EFFECT HELPERS
// ============================================================

// Apply glow effect to a unit node
private function ApplyGlowEffect takes unit u, integer defId returns nothing
    if not GNU_DefGlowEffect[defId] then
        return
    endif

    // Unit-node glow is tracked only by the master gather system to avoid drift.
    call GN_ApplyGlowEffect(u, GNU_DefGlowR[defId], GNU_DefGlowG[defId], GNU_DefGlowB[defId], GNU_DefGlowAlpha[defId], GNU_DefGlowScale[defId], GNU_DefGlowHeight[defId])
endfunction

// Remove glow effect
private function RemoveGlowEffect takes unit u returns nothing
    call GN_RemoveGlowEffect(u)
endfunction

private function IsAnyUnitNearSpawnPoint takes integer spawnPointId returns boolean
    local group g
    local unit nearby
    local real x
    local real y

    if spawnPointId < 0 or spawnPointId >= GNU_SpawnPointCount then
        return true
    endif

    set x = GNU_SpawnPointX[spawnPointId]
    set y = GNU_SpawnPointY[spawnPointId]
    set g = CreateGroup()
    call GroupEnumUnitsInRange(g, x, y, GNU_SPAWN_POINT_UNIT_BLOCK_RADIUS, null)

    loop
        set nearby = FirstOfGroup(g)
        exitwhen nearby == null
        call GroupRemoveUnit(g, nearby)
        if GetWidgetLife(nearby) > 0.405 and not IsUnitType(nearby, UNIT_TYPE_DEAD) then
            call DestroyGroup(g)
            set g = null
            set nearby = null
            return true
        endif
    endloop

    call DestroyGroup(g)
    set g = null
    return false
endfunction

private function GNU_UnitHasMiningPick takes unit u returns boolean
    local integer slot = 0
    local item it

    if u == null then
        return false
    endif

    loop
        exitwhen slot >= bj_MAX_INVENTORY
        set it = UnitItemInSlot(u, slot)
        if it != null and GetItemTypeId(it) == GNU_MINING_PICK_ITEM_CODE then
            set it = null
            return true
        endif
        set slot = slot + 1
    endloop

    set it = null
    return false
endfunction

private function GNU_ClearHarvestState takes unit u returns nothing
    local integer handleId = GetHandleId(u)

    if GNU_UnitHarvestCount.has(handleId) then
        call GNU_UnitHarvestCount.remove(handleId)
    endif
    if GNU_UnitHarvestTotal.has(handleId) then
        call GNU_UnitHarvestTotal.remove(handleId)
    endif
endfunction

private function GNU_EnsureHarvestState takes unit u, integer defId returns nothing
    local integer handleId = GetHandleId(u)

    if not GNU_UnitHarvestTotal.has(handleId) then
        set GNU_UnitHarvestCount.integer[handleId] = 0
        set GNU_UnitHarvestTotal.integer[handleId] = GetRandomInt(GNU_DefHarvestYieldMin[defId], GNU_DefHarvestYieldMax[defId])
    endif
endfunction

private function GNU_CreateRewardItems takes unit gatherer, integer itemCode, integer minQty, integer maxQty, integer maxAvailable returns integer
    local integer amount
    local integer i = 0

    if gatherer == null or itemCode == 0 then
        return 0
    endif

    if minQty <= 0 then
        set minQty = 1
    endif
    if maxQty < minQty then
        set maxQty = minQty
    endif

    set amount = GetRandomInt(minQty, maxQty)
    if maxAvailable >= 0 and amount > maxAvailable then
        set amount = maxAvailable
    endif
    if amount <= 0 then
        return 0
    endif
    loop
        exitwhen i >= amount
        call UnitAddItemByIdSwapped(itemCode, gatherer)
        set i = i + 1
    endloop
    return amount
endfunction

private function GNU_RollHarvestRewardGroup takes unit gatherer, integer defId, integer groupKey, integer groupChancePct, integer maxAvailable, boolean capToAvailable returns integer
    local integer array candidateDropIds
    local integer array candidateWeights
    local integer candidateCount = 0
    local integer j
    local integer weight
    local integer totalWeight
    local integer roll
    local integer selectedDropId

    set j = 0
    set totalWeight = 0

    if groupChancePct <= 0 or GetRandomInt(1, 100) > groupChancePct then
        return 0
    endif

    loop
        exitwhen j >= GNU_DropCount
        if GNU_DropEnabled[j] and GNU_DropDefId[j] == defId and GNU_DropGroupKey[j] == groupKey then
            set weight = GNU_DropWeight[j]
            if weight <= 0 then
                set weight = 1
            endif
            set candidateDropIds[candidateCount] = j
            set candidateWeights[candidateCount] = weight
            set candidateCount = candidateCount + 1
            set totalWeight = totalWeight + weight
        endif
        set j = j + 1
    endloop

    if totalWeight <= 0 or candidateCount <= 0 then
        return 0
    endif

    set roll = GetRandomInt(1, totalWeight)
    set selectedDropId = -1
    set j = 0
    loop
        exitwhen j >= candidateCount
        set roll = roll - candidateWeights[j]
        if roll <= 0 then
            set selectedDropId = candidateDropIds[j]
            exitwhen true
        endif
        set j = j + 1
    endloop

    if selectedDropId >= 0 and GetRandomInt(1, 100) <= GNU_DropChancePct[selectedDropId] then
        if capToAvailable then
            return GNU_CreateRewardItems(gatherer, GNU_DropItemCode[selectedDropId], GNU_DropMinQty[selectedDropId], GNU_DropMaxQty[selectedDropId], maxAvailable)
        endif
        return GNU_CreateRewardItems(gatherer, GNU_DropItemCode[selectedDropId], GNU_DropMinQty[selectedDropId], GNU_DropMaxQty[selectedDropId], -1)
    endif

    return 0
endfunction

private function GNU_RollHarvestRewards takes unit gatherer, integer defId, integer remainingPool returns integer
    local integer mainAwarded

    set mainAwarded = GNU_RollHarvestRewardGroup(gatherer, defId, StringHash("Main"), GNU_DefMainDropGroupChancePct[defId], remainingPool, true)

    if mainAwarded > 0 and remainingPool - mainAwarded > 0 then
        call GNU_RollHarvestRewardGroup(gatherer, defId, StringHash("Secondary"), GNU_DefSecondaryDropGroupChancePct[defId], -1, false)
    endif

    return mainAwarded
endfunction

private function GNU_TriggerManaCrystalExplosion takes unit node returns nothing
    local group g
    local unit target
    local real x
    local real y
    local effect eff

    if node == null then
        return
    endif

    set x = GetUnitX(node)
    set y = GetUnitY(node)
    set eff = AddSpecialEffect(GNU_MANA_CRYSTAL_EXPLOSION_EFFECT, x, y)
    set g = CreateGroup()
    call GroupEnumUnitsInRange(g, x, y, GNU_MANA_CRYSTAL_EXPLOSION_RADIUS, null)

    loop
        set target = FirstOfGroup(g)
        exitwhen target == null
        call GroupRemoveUnit(g, target)
        if target != node and GetWidgetLife(target) > 0.405 and not IsUnitType(target, UNIT_TYPE_DEAD) then
            call UnitDamageTarget(node, target, GNU_MANA_CRYSTAL_EXPLOSION_DAMAGE, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_MAGIC, WEAPON_TYPE_WHOKNOWS)
            call SetUnitState(target, UNIT_STATE_MANA, GetUnitState(target, UNIT_STATE_MANA) * (1.00 - GNU_MANA_CRYSTAL_MANA_DRAIN_FACTOR))
        endif
    endloop

    if eff != null then
        call DestroyEffect(eff)
    endif
    call DestroyGroup(g)
    set g = null
    set target = null
    set eff = null
endfunction

private function GNU_ShouldTriggerSpecialBehavior takes integer defId returns boolean
    if GNU_DefSpecialBehaviorId[defId] == GNU_SPECIAL_BEHAVIOR_NONE then
        return false
    endif

    return GetRandomInt(1, 100) <= GNU_DefSpecialChancePct[defId]
endfunction

// ============================================================
// SPAWNING FUNCTIONS
// ============================================================

// Get the random-in-zone rect directly from ZonesCore.
private function GetZoneSpawnRect takes integer zoneId returns rect
    return GN_GetZoneSpawnRect(zoneId)
endfunction

// Find an unoccupied spawn point for a definition in a zone
private function FindAvailableSpawnPoint takes integer defId, integer zoneId, integer groupId returns integer
    local integer i = 0
    local integer categoryId = GNU_DefCategoryId[defId]
    local integer array validPoints
    local integer count = 0
    
    loop
        exitwhen i >= GNU_SpawnPointCount
        
        if GNU_SpawnPointZoneId[i] == zoneId and not GNU_SpawnPointOccupied[i] then
            if groupId < 0 or GNU_SpawnPointGroupId[i] == groupId then
            // Check if spawn point accepts this definition
            if GNU_SpawnPointDefId[i] == -1 or GNU_SpawnPointDefId[i] == defId then
                // Check node type filter
                if (GNU_SpawnPointNodeType[i] == -1 or GNU_SpawnPointNodeType[i] == categoryId) and not IsAnyUnitNearSpawnPoint(i) then
                    set validPoints[count] = i
                    set count = count + 1
                endif
            endif
            endif
        endif
        
        set i = i + 1
    endloop
    
    if count == 0 then
        return -1
    endif
    
    return validPoints[GetRandomInt(0, count - 1)]
endfunction

private function GetEffectiveMax takes integer assignId returns integer
    if GNU_ZoneMaxOverride[assignId] >= 0 then
        return GNU_ZoneMaxOverride[assignId]
    endif
    return GNU_DefMaxPerZone[GNU_ZoneDefId[assignId]]
endfunction

private function GetEffectiveWeight takes integer assignId returns integer
    if GNU_ZoneWeightOverride[assignId] > 0 then
        return GNU_ZoneWeightOverride[assignId]
    endif
    return GNU_DefSpawnWeight[GNU_ZoneDefId[assignId]]
endfunction

private function CanSpawnAssignment takes integer assignId returns boolean
    local integer sharedPoolId

    if assignId < 0 or assignId >= GNU_ZoneAssignmentCount then
        return false
    endif
    if not GNU_ZoneEnabled[assignId] then
        return false
    endif
    if not GNU_DefEnabled[GNU_ZoneDefId[assignId]] then
        return false
    endif
    if GNU_ZoneActiveCount[assignId] >= GetEffectiveMax(assignId) then
        return false
    endif

    set sharedPoolId = GNU_ZoneSharedPoolId[assignId]
    if sharedPoolId >= 0 and GNU_SharedPoolCount[sharedPoolId] >= GNU_SharedPoolMax[sharedPoolId] then
        return false
    endif

    return true
endfunction

private function IncrementAssignmentCount takes integer assignId returns nothing
    local integer sharedPoolId = GNU_ZoneSharedPoolId[assignId]
    set GNU_ZoneActiveCount[assignId] = GNU_ZoneActiveCount[assignId] + 1
    if sharedPoolId >= 0 then
        set GNU_SharedPoolCount[sharedPoolId] = GNU_SharedPoolCount[sharedPoolId] + 1
    endif
endfunction

private function DecrementAssignmentCount takes integer assignId returns nothing
    local integer sharedPoolId = GNU_ZoneSharedPoolId[assignId]
    set GNU_ZoneActiveCount[assignId] = GNU_ZoneActiveCount[assignId] - 1
    if GNU_ZoneActiveCount[assignId] < 0 then
        set GNU_ZoneActiveCount[assignId] = 0
    endif
    if sharedPoolId >= 0 then
        set GNU_SharedPoolCount[sharedPoolId] = GNU_SharedPoolCount[sharedPoolId] - 1
        if GNU_SharedPoolCount[sharedPoolId] < 0 then
            set GNU_SharedPoolCount[sharedPoolId] = 0
        endif
    endif
endfunction

// ============================================================
// DEATH HANDLING & FRESH SPAWN SCHEDULING
// ============================================================

// Timer callback for scheduling a fresh spawn attempt
private function RespawnTimerCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer handleId = GetHandleId(t)
    local integer zoneId
    local integer assignId
    local integer poolId
    local integer timerGeneration = -1

    if GNU_TimerGeneration.has(handleId) then
        set timerGeneration = GNU_TimerGeneration.integer[handleId]
    endif
    
    if GNU_TimerAssignId.has(handleId) then
        set assignId = GNU_TimerAssignId.integer[handleId]
        set zoneId = GNU_ZoneId[assignId]
        
        // Trigger a fresh spawn attempt if the system and zone are enabled.
        if timerGeneration == GNU_RefreshGeneration and GN_IsSystemEnabled() and GN_IsZoneEnabled(zoneId) then
            call GNU_TriggerFreshSpawn(assignId)
        endif
        
        // Cleanup timer data
        call GNU_TimerDefId.remove(handleId)
        call GNU_TimerZoneId.remove(handleId)
        call GNU_TimerAssignId.remove(handleId)
        if GNU_TimerGeneration.has(handleId) then
            call GNU_TimerGeneration.remove(handleId)
        endif
    endif
    
    call ReleaseTimer(t)
    set t = null
endfunction

// Schedule a fresh spawn attempt
function GNU_ScheduleRespawn takes integer assignId returns nothing
    local timer t
    local real respawnTime
    local integer handleId
    local integer defId
    
    if assignId < 0 or assignId >= GNU_ZoneAssignmentCount then
        return
    endif

    set defId = GNU_ZoneDefId[assignId]
    
    set respawnTime = GN_GetRandomReal(GNU_DefRespawnMin[defId], GNU_DefRespawnMax[defId])
    set t = NewTimer()
    set handleId = GetHandleId(t)
    
    set GNU_TimerDefId.integer[handleId] = defId
    set GNU_TimerZoneId.integer[handleId] = GNU_ZoneId[assignId]
    set GNU_TimerAssignId.integer[handleId] = assignId
    set GNU_TimerGeneration.integer[handleId] = GNU_RefreshGeneration
    
    call TimerStart(t, respawnTime, false, function RespawnTimerCallback)
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Scheduled new category spawn attempt in zone " + I2S(GNU_ZoneId[assignId]) + " in " + R2S(respawnTime) + "s")
    endif
endfunction

private function GNU_HandleLifetimeExpire takes unit u returns nothing
    local integer unitHandleId
    local integer defId
    local integer zoneId
    local integer assignId
    local integer spawnPointId

    if u == null then
        return
    endif

    set unitHandleId = GetHandleId(u)
    if GNU_UnitLifetimeTimer.real.has(unitHandleId) and GNU_UnitToDefId.has(unitHandleId) then
        set defId = GNU_UnitToDefId.integer[unitHandleId]
        set zoneId = GNU_UnitToZoneId.integer[unitHandleId]
        if GNU_UnitToAssignId.has(unitHandleId) then
            set assignId = GNU_UnitToAssignId.integer[unitHandleId]
        else
            set assignId = -1
        endif
        set spawnPointId = GNU_UnitToSpawnPoint.integer[unitHandleId]

        call GNU_UnitLifetimeTimer.real.remove(unitHandleId)
        call RemoveGlowEffect(u)
        call GNU_ClearHarvestState(u)
        call GN_UnregisterUnit(u, zoneId)
        call GNU_UnitToDefId.remove(unitHandleId)
        call GNU_UnitToZoneId.remove(unitHandleId)
        if GNU_UnitToAssignId.has(unitHandleId) then
            call GNU_UnitToAssignId.remove(unitHandleId)
        endif
        call GNU_UnitToSpawnPoint.remove(unitHandleId)
        if assignId >= 0 then
            call DecrementAssignmentCount(assignId)
        endif
        if spawnPointId >= 0 then
            set GNU_SpawnPointOccupied[spawnPointId] = false
            set GNU_SpawnPointUnit[spawnPointId] = null
        endif
        call RemoveUnit(u)

        if assignId >= 0 and GN_IsSystemEnabled() and GN_IsZoneEnabled(zoneId) then
            call GNU_ScheduleRespawn(assignId)
        endif

        if GN_IsDebugMode() then
            call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r " + GNU_DefNodeName[defId] + " despawned, scheduling new spawn attempt")
        endif
    endif
endfunction

private function GNU_CheckExpiredUnits takes nothing returns nothing
    local integer index = GN_GetActiveUnitCount() - 1
    local unit u
    local integer handleId
    local real now = GNU_GetNow()

    loop
        exitwhen index < 0
        set u = GN_GetActiveUnitByIndex(index)
        if u != null then
            set handleId = GetHandleId(u)
            if GNU_UnitToDefId.has(handleId) and GNU_UnitLifetimeTimer.real.has(handleId) and GNU_UnitLifetimeTimer.real[handleId] <= now then
                call GNU_HandleLifetimeExpire(u)
            endif
        endif
        set index = index - 1
    endloop
    set u = null
endfunction

private function GNU_StartLifetimeTimer takes unit u, integer defId returns nothing
    local integer handleId = GetHandleId(u)
    local real lifeTime = GN_GetRandomReal(GNU_DefRespawnMin[defId], GNU_DefRespawnMax[defId])

    call GNU_CancelLifetimeTimer(u)

    set GNU_UnitLifetimeTimer.real[handleId] = GNU_GetNow() + lifeTime

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r " + GNU_DefNodeName[defId] + " will despawn in " + R2S(lifeTime) + "s")
    endif
endfunction

// Spawn a unit at specific coordinates
function GNU_SpawnUnitAt takes integer defId, real x, real y, real facing, integer zoneId, integer spawnPointId, integer assignId returns unit
    local unit u
    local integer unitCode
    local player owner
    local integer handleId
    
    if defId < 0 or defId >= GNU_DefinitionCount then
        return null
    endif
    
    if not GNU_DefEnabled[defId] then
        return null
    endif
    
    set unitCode = GNU_DefUnitCode[defId]
    set owner = Player(GNU_DefOwnerPlayer[defId])
    
    if not GN_IsTerrainAllowedForNode(zoneId, x, y, GNU_DefPreventWaterSpawn[defId], spawnPointId >= 0) then
        set owner = null
        return null
    endif

    set u = CreateUnit(owner, unitCode, x, y, facing)
    
    if u != null then
        set handleId = GetHandleId(u)
        
        // Register with master system
        call GN_RegisterActiveUnit(u, defId, zoneId, GNU_DefProfessionId[defId], GNU_DefSkillRequired[defId], GNU_DefNodeName[defId])
        
        // Track locally
        set GNU_UnitToDefId.integer[handleId] = defId
        set GNU_UnitToZoneId.integer[handleId] = zoneId
        call GNU_ClearHarvestState(u)
        if assignId >= 0 then
            set GNU_UnitToAssignId.integer[handleId] = assignId
            call IncrementAssignmentCount(assignId)
        endif
        set GNU_UnitToSpawnPoint.integer[handleId] = spawnPointId
        
        // Mark spawn point as occupied
        if spawnPointId >= 0 then
            set GNU_SpawnPointOccupied[spawnPointId] = true
            set GNU_SpawnPointUnit[spawnPointId] = u
        endif

        call GN_DebugPingSpawn(x, y, true)
        
        // Apply glow effect
        call ApplyGlowEffect(u, defId)
        call GNU_StartLifetimeTimer(u, defId)
        
        if GN_IsDebugMode() then
            call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Spawned " + GNU_DefNodeName[defId] + " at (" + R2S(x) + ", " + R2S(y) + ")")
        endif
    endif
    
    set owner = null
    return u
endfunction

// Spawn at a fixed spawn point
function GNU_SpawnUnitAtPoint takes integer defId, integer spawnPointId, integer assignId returns unit
    if spawnPointId < 0 or spawnPointId >= GNU_SpawnPointCount then
        return null
    endif
    
    if GNU_SpawnPointOccupied[spawnPointId] then
        return null
    endif
    
    return GNU_SpawnUnitAt(defId, GNU_SpawnPointX[spawnPointId], GNU_SpawnPointY[spawnPointId], GNU_SpawnPointFacing[spawnPointId], GNU_SpawnPointZoneId[spawnPointId], spawnPointId, assignId)
endfunction

// Spawn in random location within zone
function GNU_SpawnUnitInZone takes integer defId, integer zoneId, integer assignId returns unit
    local rect r = GetZoneSpawnRect(zoneId)
    local real x
    local real y
    local integer attempts = 0
    local unit u = null
    
    if r == null then
        if GN_IsDebugMode() then
            call BJDebugMsg("|cffff8800[GatherNodeUnits]|r No zone spawn rect configured in ZonesCore for zone " + I2S(zoneId))
        endif
        return null
    endif
    
    loop
        exitwhen attempts >= GN_RANDOM_SPAWN_ATTEMPTS or u != null
        
        set x = GetRandomReal(GetRectMinX(r), GetRectMaxX(r))
        set y = GetRandomReal(GetRectMinY(r), GetRectMaxY(r))
        
        if not GN_IsPointInRestrictedRect(zoneId, x, y, true) and GN_IsPointPathable(x, y) and GN_IsUnitSpawnAreaClear(x, y) then
            set u = GNU_SpawnUnitAt(defId, x, y, GetRandomReal(0, 360), zoneId, -1, assignId)
        endif
        
        set attempts = attempts + 1
    endloop
    
    return u
endfunction

// Smart spawn: use fixed point if available, else random
function GNU_SmartSpawnUnit takes integer defId, integer zoneId, integer groupId, integer assignId returns unit
    local integer spawnPoint = FindAvailableSpawnPoint(defId, zoneId, groupId)
    
    if spawnPoint >= 0 then
        return GNU_SpawnUnitAtPoint(defId, spawnPoint, assignId)
    else
        return GNU_SpawnUnitInZone(defId, zoneId, assignId)
    endif
endfunction

private function PickSharedPoolAssignment takes integer poolId returns integer
    local integer i = 0
    local integer totalWeight = 0
    local integer roll
    local integer weight

    loop
        exitwhen i >= GNU_ZoneAssignmentCount
        if GNU_ZoneSharedPoolId[i] == poolId and CanSpawnAssignment(i) then
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
        exitwhen i >= GNU_ZoneAssignmentCount
        if GNU_ZoneSharedPoolId[i] == poolId and CanSpawnAssignment(i) then
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

private function GNU_SpawnUnitForAssignment takes integer assignId returns unit
    local integer defId
    local integer zoneId
    local integer spawnMode
    local integer spawnGroupId
    local integer spawnPointId

    if not CanSpawnAssignment(assignId) then
        return null
    endif

    set defId = GNU_ZoneDefId[assignId]
    set zoneId = GNU_ZoneId[assignId]
    set spawnMode = GNU_ZoneSpawnMode[assignId]
    set spawnGroupId = GNU_ZoneSpawnGroupId[assignId]

    if spawnMode == 1 then
        set spawnPointId = FindAvailableSpawnPoint(defId, zoneId, spawnGroupId)
        if spawnPointId >= 0 then
            return GNU_SpawnUnitAtPoint(defId, spawnPointId, assignId)
        endif
        return null
    elseif spawnMode == 2 then
        return GNU_SmartSpawnUnit(defId, zoneId, spawnGroupId, assignId)
    endif

    return GNU_SpawnUnitInZone(defId, zoneId, assignId)
endfunction

private function SpawnSharedPoolUnit takes integer poolId returns unit
    local integer assignId
    local unit u = null

    if poolId < 0 then
        return null
    endif

    loop
        exitwhen GNU_SharedPoolCount[poolId] >= GNU_SharedPoolMax[poolId] or u != null
        set assignId = PickSharedPoolAssignment(poolId)
        if assignId < 0 then
            return null
        endif
        set u = GNU_SpawnUnitForAssignment(assignId)
        if u == null then
            return null
        endif
    endloop

    return u
endfunction

private function GNU_PickReplacementAssignment takes integer sourceAssignId returns integer
    local integer i = 0
    local integer totalWeight = 0
    local integer roll
    local integer weight
    local integer sourceZoneId
    local integer sourceGroupId
    local integer sourceCategoryId

    if sourceAssignId < 0 or sourceAssignId >= GNU_ZoneAssignmentCount then
        return -1
    endif

    set sourceZoneId = GNU_ZoneId[sourceAssignId]
    set sourceGroupId = GNU_ZoneSpawnGroupId[sourceAssignId]
    set sourceCategoryId = GNU_DefCategoryId[GNU_ZoneDefId[sourceAssignId]]

    loop
        exitwhen i >= GNU_ZoneAssignmentCount
        if GNU_ZoneId[i] == sourceZoneId and GNU_ZoneSpawnGroupId[i] == sourceGroupId and GNU_DefCategoryId[GNU_ZoneDefId[i]] == sourceCategoryId and CanSpawnAssignment(i) then
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
        exitwhen i >= GNU_ZoneAssignmentCount
        if GNU_ZoneId[i] == sourceZoneId and GNU_ZoneSpawnGroupId[i] == sourceGroupId and GNU_DefCategoryId[GNU_ZoneDefId[i]] == sourceCategoryId and CanSpawnAssignment(i) then
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

private function GNU_DoTriggerFreshSpawn takes nothing returns nothing
    local integer assignId = GNU_PendingFreshAssignId
    local integer replacementAssignId

    if assignId >= 0 then
        set replacementAssignId = GNU_PickReplacementAssignment(assignId)
        if replacementAssignId >= 0 then
            call GNU_SpawnUnitForAssignment(replacementAssignId)
        endif
    endif
endfunction

private function GNU_OnHarvestDamage takes nothing returns nothing
    local unit gatherer = udg_DamageEventSource
    local unit node = udg_DamageEventTarget
    local integer handleId
    local integer defId
    local integer gatheredCount
    local integer totalYield
    local integer remainingPool
    local integer mainAwarded

    if gatherer == null or node == null or not GN_IsGatherUnit(node) then
        return
    endif

    set handleId = GetHandleId(node)
    if not GNU_UnitToDefId.has(handleId) then
        return
    endif

    if GNS_ShouldBlockGatherUnit(gatherer, node) then
        set udg_DamageEventAmount = 0.0
        call IssueImmediateOrder(gatherer, "stop")
        return
    endif

    if not GNU_UnitHasMiningPick(gatherer) then
        set udg_DamageEventAmount = 0.0
        call IssueImmediateOrder(gatherer, "stop")
        return
    endif

    set udg_DamageEventAmount = 0.0
    set defId = GNU_UnitToDefId.integer[handleId]

    call GNU_EnsureHarvestState(node, defId)
    set gatheredCount = GNU_UnitHarvestCount.integer[handleId]
    set totalYield = GNU_UnitHarvestTotal.integer[handleId]
    if totalYield <= 0 then
        set totalYield = 1
        set GNU_UnitHarvestTotal.integer[handleId] = totalYield
    endif
    set remainingPool = totalYield - gatheredCount
    if remainingPool <= 0 then
        call KillUnit(node)
        return
    endif

    if GetRandomInt(1, 100) > GNU_DefGatherChancePct[defId] then
        return
    endif

    set mainAwarded = GNU_RollHarvestRewards(gatherer, defId, remainingPool)
    if mainAwarded <= 0 then
        return
    endif
    call GNS_OnSuccessfulMining(gatherer, node)

    set gatheredCount = gatheredCount + mainAwarded
    set GNU_UnitHarvestCount.integer[handleId] = gatheredCount

    if GNU_ShouldTriggerSpecialBehavior(defId) then
        if GNU_DefSpecialBehaviorId[defId] == GNU_SPECIAL_BEHAVIOR_MANA_CRYSTAL_EXPLOSION then
            call GNU_TriggerManaCrystalExplosion(node)
            call KillUnit(node)
            return
        endif
    endif

    if gatheredCount >= totalYield then
        call KillUnit(node)
    endif
endfunction

// Death event handler
function GNU_OnUnitDeath takes nothing returns boolean
    local unit u = GetTriggerUnit()
    local integer handleId = GetHandleId(u)
    local integer defId
    local integer zoneId
    local integer assignId
    local integer spawnPointId
    
    if not GNU_UnitToDefId.has(handleId) then
        set u = null
        return false // Not a gather node
    endif
    
    set defId = GNU_UnitToDefId.integer[handleId]
    set zoneId = GNU_UnitToZoneId.integer[handleId]
    if GNU_UnitToAssignId.has(handleId) then
        set assignId = GNU_UnitToAssignId.integer[handleId]
    else
        set assignId = -1
    endif
    set spawnPointId = GNU_UnitToSpawnPoint.integer[handleId]
    
    call GNU_CancelLifetimeTimer(u)

    // Remove glow effect
    call RemoveGlowEffect(u)
    call GNU_ClearHarvestState(u)
    
    // Unregister from master system
    call GN_UnregisterUnit(u, zoneId)
    
    // Clear local tracking
    call GNU_UnitToDefId.remove(handleId)
    call GNU_UnitToZoneId.remove(handleId)
    if GNU_UnitToAssignId.has(handleId) then
        call GNU_UnitToAssignId.remove(handleId)
    endif
    call GNU_UnitToSpawnPoint.remove(handleId)
    if assignId >= 0 then
        call DecrementAssignmentCount(assignId)
    endif
    
    // Free up spawn point
    if spawnPointId >= 0 then
        set GNU_SpawnPointOccupied[spawnPointId] = false
        set GNU_SpawnPointUnit[spawnPointId] = null
    endif
    
    // Schedule a fresh spawn attempt
    if assignId >= 0 then
        call GNU_ScheduleRespawn(assignId)
    endif
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r " + GNU_DefNodeName[defId] + " died, scheduling new spawn attempt")
    endif
    
    set u = null
    return false
endfunction

// ============================================================
// INITIAL SPAWN FOR ZONES
// ============================================================

// Spawn initial nodes in a zone
function GNU_SpawnInitialInZone takes integer zoneId returns nothing
    local integer i = 0
    local integer spawned
    local integer poolId
    local integer array processedPools
    
    if not GN_IsZoneEnabled(zoneId) then
        return
    endif
    
    // Loop through zone assignments
    loop
        exitwhen i >= GNU_ZoneAssignmentCount
        
        if GNU_ZoneId[i] == zoneId and GNU_ZoneEnabled[i] then
            if GNU_DefEnabled[GNU_ZoneDefId[i]] then
                set spawned = 0
                set poolId = GNU_ZoneSharedPoolId[i]

                if poolId >= 0 then
                    if processedPools[poolId] == 0 then
                        loop
                            exitwhen GNU_SharedPoolCount[poolId] >= GNU_SharedPoolMax[poolId]
                            if SpawnSharedPoolUnit(poolId) == null then
                                exitwhen true
                            endif
                            set spawned = spawned + 1
                        endloop
                        set processedPools[poolId] = 1
                    endif
                else
                    loop
                        exitwhen not CanSpawnAssignment(i)
                        if GNU_SpawnUnitForAssignment(i) == null then
                            exitwhen true
                        endif
                        set spawned = spawned + 1
                    endloop
                endif

                if GN_IsDebugMode() and spawned > 0 then
                    call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Spawned " + I2S(spawned) + " " + GNU_DefNodeName[GNU_ZoneDefId[i]] + " in zone " + I2S(zoneId))
                endif
            endif
        endif
        
        set i = i + 1
    endloop
endfunction

// Spawn initial nodes in all zones
function GNU_SpawnInitialAll takes nothing returns nothing
    local integer zoneId = 1
    
    loop
        exitwhen zoneId > 100 // Assume max 100 zones
        call GNU_SpawnInitialInZone(zoneId)
        set zoneId = zoneId + 1
    endloop
endfunction

function GNU_DebugRefreshAll takes nothing returns nothing
    local unit u
    local integer handleId
    local integer zoneId
    local integer assignId
    local integer spawnPointId

    set GNU_RefreshGeneration = GNU_RefreshGeneration + 1

    loop
        exitwhen GN_GetActiveUnitCount() <= 0
        set u = GN_GetActiveUnitByIndex(GN_GetActiveUnitCount() - 1)
        if u == null then
            exitwhen true
        endif

        set handleId = GetHandleId(u)
        if GNU_UnitToDefId.has(handleId) then
            set zoneId = GNU_UnitToZoneId.integer[handleId]
            if GNU_UnitToAssignId.has(handleId) then
                set assignId = GNU_UnitToAssignId.integer[handleId]
            else
                set assignId = -1
            endif
            set spawnPointId = GNU_UnitToSpawnPoint.integer[handleId]

            call GNU_CancelLifetimeTimer(u)
            call RemoveGlowEffect(u)
            call GNU_ClearHarvestState(u)
            call GN_UnregisterUnit(u, zoneId)
            call GNU_UnitToDefId.remove(handleId)
            call GNU_UnitToZoneId.remove(handleId)
            if GNU_UnitToAssignId.has(handleId) then
                call GNU_UnitToAssignId.remove(handleId)
            endif
            call GNU_UnitToSpawnPoint.remove(handleId)
            if assignId >= 0 then
                call DecrementAssignmentCount(assignId)
            endif
            if spawnPointId >= 0 then
                set GNU_SpawnPointOccupied[spawnPointId] = false
                set GNU_SpawnPointUnit[spawnPointId] = null
            endif
            call RemoveUnit(u)
        else
            exitwhen true
        endif
    endloop

    call GNU_SpawnInitialAll()

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Debug refresh complete")
    endif

    set u = null
endfunction

// ============================================================
// QUERY FUNCTIONS
// ============================================================

function GNU_GetDefinitionCount takes nothing returns integer
    return GNU_DefinitionCount
endfunction

function GNU_GetDefinitionName takes integer defId returns string
    if defId < 0 or defId >= GNU_DefinitionCount then
        return ""
    endif
    return GNU_DefNodeName[defId]
endfunction

function GNU_GetDefinitionUnitCode takes integer defId returns integer
    if defId < 0 or defId >= GNU_DefinitionCount then
        return 0
    endif
    return GNU_DefUnitCode[defId]
endfunction

function GNU_GetDefinitionSkillRequired takes integer defId returns integer
    if defId < 0 or defId >= GNU_DefinitionCount then
        return 0
    endif
    return GNU_DefSkillRequired[defId]
endfunction

function GNU_GetDefinitionProfessionId takes integer defId returns integer
    if defId < 0 or defId >= GNU_DefinitionCount then
        return 0
    endif
    return GNU_DefProfessionId[defId]
endfunction

function GNU_IsDefinitionRare takes integer defId returns boolean
    if defId < 0 or defId >= GNU_DefinitionCount then
        return false
    endif
    return GNU_DefIsRare[defId]
endfunction

function GNU_GetSpawnPointCount takes nothing returns integer
    return GNU_SpawnPointCount
endfunction

function GNU_GetSpawnPointZoneId takes integer spawnId returns integer
    if spawnId < 0 or spawnId >= GNU_SpawnPointCount then
        return -1
    endif
    return GNU_SpawnPointZoneId[spawnId]
endfunction

function GNU_IsSpawnPointOccupied takes integer spawnId returns boolean
    if spawnId < 0 or spawnId >= GNU_SpawnPointCount then
        return true
    endif
    return GNU_SpawnPointOccupied[spawnId]
endfunction

// ============================================================
// ENABLE/DISABLE
// ============================================================

function GNU_SetDefinitionEnabled takes integer defId, boolean enabled returns nothing
    if defId >= 0 and defId < GNU_DefinitionCount then
        set GNU_DefEnabled[defId] = enabled
    endif
endfunction

function GNU_IsDefinitionEnabled takes integer defId returns boolean
    if defId < 0 or defId >= GNU_DefinitionCount then
        return false
    endif
    return GNU_DefEnabled[defId]
endfunction

private function GNU_IsTrackedUnitMissing takes unit u returns boolean
    if u == null then
        return true
    endif
    if GetUnitTypeId(u) == 0 then
        return true
    endif
    if GetWidgetLife(u) <= 0.405 or IsUnitType(u, UNIT_TYPE_DEAD) then
        return true
    endif
    return false
endfunction

private function GNU_HandleExternalUnitRemoval takes unit u returns nothing
    local integer handleId
    local integer zoneId
    local integer assignId
    local integer spawnPointId
    local integer defId

    if u == null then
        return
    endif

    set handleId = GetHandleId(u)
    if not GNU_UnitToDefId.has(handleId) then
        return
    endif

    set defId = GNU_UnitToDefId.integer[handleId]
    set zoneId = GNU_UnitToZoneId.integer[handleId]
    if GNU_UnitToAssignId.has(handleId) then
        set assignId = GNU_UnitToAssignId.integer[handleId]
    else
        set assignId = -1
    endif
    set spawnPointId = GNU_UnitToSpawnPoint.integer[handleId]

    call GNU_CancelLifetimeTimer(u)
    call RemoveGlowEffect(u)
    call GNU_ClearHarvestState(u)
    call GN_UnregisterUnit(u, zoneId)
    call GNU_UnitToDefId.remove(handleId)
    call GNU_UnitToZoneId.remove(handleId)
    if GNU_UnitToAssignId.has(handleId) then
        call GNU_UnitToAssignId.remove(handleId)
    endif
    call GNU_UnitToSpawnPoint.remove(handleId)
    if assignId >= 0 then
        call DecrementAssignmentCount(assignId)
    endif
    if spawnPointId >= 0 then
        set GNU_SpawnPointOccupied[spawnPointId] = false
        set GNU_SpawnPointUnit[spawnPointId] = null
    endif

    if assignId >= 0 and GN_IsSystemEnabled() and GN_IsZoneEnabled(zoneId) then
        call GNU_ScheduleRespawn(assignId)
    endif

    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r " + GNU_DefNodeName[defId] + " was removed externally, scheduling new spawn attempt")
    endif
endfunction

private function GNU_ValidateTrackedUnits takes nothing returns nothing
    local integer index = GN_GetActiveUnitCount() - 1
    local unit u

    loop
        exitwhen index < 0
        set u = GN_GetActiveUnitByIndex(index)
        if u != null and GNU_UnitToDefId.has(GetHandleId(u)) and GNU_IsTrackedUnitMissing(u) then
            call GNU_HandleExternalUnitRemoval(u)
        endif
        set index = index - 1
    endloop

    set u = null
endfunction

// ============================================================
// FORCE SPAWN (for debugging/quests)
// ============================================================

// Force spawn a specific node at a location
function GNU_ForceSpawn takes integer defId, real x, real y, integer zoneId returns unit
    return GNU_SpawnUnitAt(defId, x, y, GetRandomReal(0, 360), zoneId, -1, -1)
endfunction

// Force despawn all nodes of a definition in a zone
function GNU_ForceDespawnInZone takes integer defId, integer zoneId returns integer
    local integer i = 0
    local integer count = 0
    local integer handleId
    local unit u
    
    // This would need iteration through all active units
    // For now, just log
    call BJDebugMsg("|cffff0000[GatherNodeUnits]|r ForceDespawnInZone not fully implemented")
    
    return count
endfunction

// ============================================================
// INITIALIZATION
// ============================================================
private function Init takes nothing returns nothing
    local integer playerIndex = 0

    set GNU_UnitToDefId = Table.create()
    set GNU_UnitToZoneId = Table.create()
    set GNU_UnitToAssignId = Table.create()
    set GNU_UnitToSpawnPoint = Table.create()
    set GNU_UnitLifetimeTimer = Table.create()
    set GNU_UnitHarvestCount = Table.create()
    set GNU_UnitHarvestTotal = Table.create()
    set GNU_TimerDefId = Table.create()
    set GNU_TimerZoneId = Table.create()
    set GNU_TimerAssignId = Table.create()
    set GNU_TimerGeneration = Table.create()
    set GNU_LifetimeTimerUnit = Table.create()
    set GNU_LifetimeTimerGeneration = Table.create()
    
    // Create death and dispatcher triggers
    set GNU_DeathTrigger = CreateTrigger()
    set GNU_FreshSpawnTrigger = CreateTrigger()
    set GNU_LifetimeExpireTrigger = CreateTrigger()
    set GNU_HarvestTrigger = CreateTrigger()
    set GNU_ValidationTrigger = CreateTrigger()
    set GNU_ClockTimer = CreateTimer()
    set GNU_LifetimeCheckTimer = CreateTimer()

    loop
        exitwhen playerIndex >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(GNU_DeathTrigger, Player(playerIndex), EVENT_PLAYER_UNIT_DEATH, null)
        set playerIndex = playerIndex + 1
    endloop

    call TimerStart(GNU_ClockTimer, 999999.0, false, function GNU_NoOp)
    call TriggerAddCondition(GNU_DeathTrigger, Condition(function GNU_OnUnitDeath))
    call TriggerAddAction(GNU_FreshSpawnTrigger, function GNU_DoTriggerFreshSpawn)
    call TimerStart(GNU_LifetimeCheckTimer, GNU_LIFETIME_CHECK_INTERVAL, true, function GNU_CheckExpiredUnits)
    call TriggerRegisterVariableEvent(GNU_HarvestTrigger, "udg_DamageModifierEvent", EQUAL, 1.00)
    call TriggerAddAction(GNU_HarvestTrigger, function GNU_OnHarvestDamage)
    call TriggerRegisterTimerEventPeriodic(GNU_ValidationTrigger, GNU_VALIDATION_INTERVAL)
    call TriggerAddAction(GNU_ValidationTrigger, function GNU_ValidateTrackedUnits)
    
    if GN_IsDebugMode() then
        call BJDebugMsg("|cff00ff00[GatherNodeUnits]|r Subsystem initialized")
    endif
endfunction

endlibrary
