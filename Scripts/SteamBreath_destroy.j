function RemoveSteamEffects takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= MAX_UNITS
        if SteamEffects[i] != null then
            call DestroyEffect(SteamEffects[i])
            set SteamEffects[i] = null
        endif
        set i = i + 1
    endloop
endfunction