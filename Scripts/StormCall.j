function CallStormImitate takes nothing returns nothing
    local integer v = GetRandomInt(1, Storm_VAR_COUNT) // Replace with your own logic for picking v
    call Storm_ImitateRandomLocal(v, GetLocalPlayer() == GetTriggerPlayer())
endfunction