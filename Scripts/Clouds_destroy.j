function RemoveClouds takes nothing returns nothing
    local integer i = 0
    loop
        exitwhen i >= CLOUD_COUNT
        if CloudEffects[i] != null then
            call DestroyEffect(CloudEffects[i])
            set CloudEffects[i] = null
        endif
        set i = i + 1
    endloop
endfunction