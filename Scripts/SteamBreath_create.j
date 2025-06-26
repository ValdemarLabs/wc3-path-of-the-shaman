//////////////////////////////////////////////////
globals
    integer MAX_UNITS = 1000
    unit array RandomUnits // Store affected units
    effect array SteamEffects // Store attached effects
endglobals
//////////////////////////////////////////////////
function AttachSteamEffects takes nothing returns nothing
    local group g = CreateGroup()
    local unit u
    local integer i = 0
    
    // Pick all units in the playable map area
    call GroupEnumUnitsInRect(g, bj_mapInitialPlayableArea, null)

    // Attach effects to random units (up to 1000)
    loop
        set u = FirstOfGroup(g)
        exitwhen u == null or i >= MAX_UNITS
        
        set RandomUnits[i] = u // Store unit reference
        set SteamEffects[i] = AddSpecialEffectTarget("SteamBreath_Small_Moderate.mdx", u, "head")

        call GroupRemoveUnit(g, u)
        set i = i + 1
    endloop

    call DestroyGroup(g)
endfunction