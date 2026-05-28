//===========================================================================
/*
    CloudsSystem.j
    ----------------

    Author: [Valdemar]

    Description:
    This system creates cloud effects in the playable area of the map.
    Clouds are spawned at random locations with a specified height and scale.   

    API:
    -   call SpawnClouds() - Spawns a number of cloud effects at random locations in the playable area.
    -   call RemoveClouds() - Removes all cloud effects created by SpawnClouds.    

*/ 
//===========================================================================

library CloudsSystem

globals
    private constant integer MAX_CLOUDS_PER_REGION = 20 // Maximum clouds that can spawn in one region
    private constant integer MAX_REGIONS = 100 // Must match WeatherSystem MAX_REGIONS
    private constant real CLOUD_AREA_THRESHOLD = 500000.0 // Area per cloud (500x1000 or ~707x707)
    private effect array CloudEffects // Store cloud effects [regionIndex * MAX_CLOUDS_PER_REGION + cloudIndex]
    private integer array RegionCloudCount // Track clouds per region
endglobals

// Calculate number of clouds based on region size
private function CalculateCloudCount takes rect whichRegion returns integer
    local real width = GetRectMaxX(whichRegion) - GetRectMinX(whichRegion)
    local real height = GetRectMaxY(whichRegion) - GetRectMinY(whichRegion)
    local real area = width * height
    local integer cloudCount = R2I(area / CLOUD_AREA_THRESHOLD)
    
    // Ensure at least 1 cloud, max MAX_CLOUDS_PER_REGION
    if cloudCount < 1 then
        set cloudCount = 1
    elseif cloudCount > MAX_CLOUDS_PER_REGION then
        set cloudCount = MAX_CLOUDS_PER_REGION
    endif
    
    return cloudCount
endfunction

// Remove clouds from a specific region
function RemoveCloudsInRegion takes integer regionIndex returns nothing
    local integer i = 0
    local integer baseIndex
    
    if regionIndex < 0 or regionIndex >= MAX_REGIONS then
        return
    endif
    
    set baseIndex = regionIndex * MAX_CLOUDS_PER_REGION
    
    loop
        exitwhen i >= RegionCloudCount[regionIndex]
        if CloudEffects[baseIndex + i] != null then
            call DestroyEffect(CloudEffects[baseIndex + i])
            set CloudEffects[baseIndex + i] = null
        endif
        set i = i + 1
    endloop
    
    set RegionCloudCount[regionIndex] = 0
endfunction

// Spawn clouds in a specific region
function SpawnCloudsInRegion takes rect whichRegion, integer regionIndex returns nothing
    local integer i = 0
    local real x
    local real y
    local real z
    local real terrainZ
    local real cloudHeightOffset = 2200.0  // Height above terrain
    local effect cloudEffect
    local real minX
    local real minY
    local real maxX
    local real maxY
    local integer baseIndex
    local integer cloudCount
    local location tempLoc
    
    if whichRegion == null or regionIndex < 0 or regionIndex >= MAX_REGIONS then
        return
    endif
    
    // Remove existing clouds in this region first
    call RemoveCloudsInRegion(regionIndex)
    
    set minX = GetRectMinX(whichRegion)
    set minY = GetRectMinY(whichRegion)
    set maxX = GetRectMaxX(whichRegion)
    set maxY = GetRectMaxY(whichRegion)
    set baseIndex = regionIndex * MAX_CLOUDS_PER_REGION
    set cloudCount = CalculateCloudCount(whichRegion)

    loop
        exitwhen i >= cloudCount
        set x = GetRandomReal(minX, maxX)
        set y = GetRandomReal(minY, maxY)

        // Get terrain elevation at this position
        set tempLoc = Location(x, y)
        set terrainZ = GetLocationZ(tempLoc)
        call RemoveLocation(tempLoc)
        set tempLoc = null
        
        // Calculate cloud height: terrain height + offset
        // GetZ location disabled
        //set z = terrainZ + cloudHeightOffset

        set z = cloudHeightOffset  // Use fixed height

        // Create the cloud effect at terrain-relative height
        set cloudEffect = AddSpecialEffect("war3mapImported\\Cloudx-blend.mdx", x, y)
        call BlzSetSpecialEffectScale(cloudEffect, 455.0)  // Set scale to 455
        call BlzSetSpecialEffectZ(cloudEffect, z)          // Set height relative to terrain

        // Store in array for later removal
        set CloudEffects[baseIndex + i] = cloudEffect

        set i = i + 1
    endloop
    
    set RegionCloudCount[regionIndex] = cloudCount
endfunction

// Legacy function - spawns clouds globally (deprecated)
function SpawnClouds takes nothing returns nothing
    local integer i = 0
    local real x
    local real y
    local real z = 200.0
    local effect cloudEffect
    local integer cloudCount = 20

    loop
        exitwhen i >= cloudCount
        set x = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
        set y = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))

        set cloudEffect = AddSpecialEffect("war3mapImported\\Cloudx-blend.mdx", x, y)
        call BlzSetSpecialEffectScale(cloudEffect, 455.0)
        call BlzSetSpecialEffectZ(cloudEffect, z)
        set CloudEffects[i] = cloudEffect

        set i = i + 1
    endloop
endfunction

// Legacy function - removes global clouds (deprecated)
function RemoveClouds takes nothing returns nothing
    local integer i = 0
    local integer maxClouds = 20
    loop
        exitwhen i >= maxClouds
        if CloudEffects[i] != null then
            call DestroyEffect(CloudEffects[i])
            set CloudEffects[i] = null
        endif
        set i = i + 1
    endloop
endfunction

endlibrary
