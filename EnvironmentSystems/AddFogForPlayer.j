library FogSystem

function AddFogForPlayer takes real start, real end, real Red, real Green, real Blue, player whichplayer returns nothing
    local integer i = 0

    if (udg_Fog_Player_CurrentFogRed[GetPlayerId(whichplayer) + 1] == Red) then
        set i = i + 1
    endif
          
    if (udg_Fog_Player_CurrentFogGreen[GetPlayerId(whichplayer) + 1] == Green) then
        set i = i + 1
    endif

    if (udg_Fog_Player_CurrentFogBlue[GetPlayerId(whichplayer) + 1] == Blue) then
        set i = i + 1
    endif

    if (i < 3) then
        set udg_Fog_Player_FogZ_Start[GetPlayerId(whichplayer) + 1] = start
        set udg_Fog_Player_FogZ_End[GetPlayerId(whichplayer) + 1] = end
        set udg_Fog_Player_FogRed[GetPlayerId(whichplayer) + 1] = Red
        set udg_Fog_Player_FogBlue[GetPlayerId(whichplayer) + 1] = Blue
        set udg_Fog_Player_FogGreen[GetPlayerId(whichplayer) + 1] = Green
        set udg_Fog_Player_FogFading[GetPlayerId(whichplayer) + 1] = true
   
        call EnableTrigger( gg_trg_Fog_Fade_System )
    endif
endfunction

endlibrary