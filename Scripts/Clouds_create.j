//===========================================================================
/*
    Clouds_create.j
    ----------------

    Author: [Queel]

    Description:
    This system creates cloud effects in the playable area of the map.
    Clouds are spawned at random locations with a specified height and scale.   

    API:
    -   call SpawnClouds() - Spawns a number of cloud effects at random locations in the playable area.
    -   call RemoveClouds() - Removes all cloud effects created by SpawnClouds.    

*/ 
//===========================================================================
//////////////////////////////////////////////////

//////////////////////////////////////////////////
globals
    integer CLOUD_COUNT = 20 // Number of clouds
    effect array CloudEffects // Store cloud effects for later removal
endglobals
//////////////////////////////////////////////////

function SpawnClouds takes nothing returns nothing
    local integer i = 0
    local real x
    local real y
    local real z
    local effect cloudEffect

    loop
        exitwhen i >= CLOUD_COUNT
        set x = GetRandomReal(GetRectMinX(bj_mapInitialPlayableArea), GetRectMaxX(bj_mapInitialPlayableArea))
        set y = GetRandomReal(GetRectMinY(bj_mapInitialPlayableArea), GetRectMaxY(bj_mapInitialPlayableArea))
        set z = GetRandomReal(200.0, 1000.0) // Random Z height between 1000 and 3000

        // Create the cloud effect
        set cloudEffect = AddSpecialEffect("war3mapImported\\Cloudx-blend.mdx", x, y)
        call BlzSetSpecialEffectScale(cloudEffect, 455.0)  // Set scale to 455
        call BlzSetSpecialEffectZ(cloudEffect, z)          // Set height (Z offset)

        // Store in array for later removal
        set CloudEffects[i] = cloudEffect

        set i = i + 1
    endloop
endfunction
