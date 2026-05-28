library FogSystem initializer Init
//===========================================================================
/*
    FogSystem
    
    Author: [Valdemar]
    
    Description:
    This library provides a system to smoothly transition fog colors for individual players over time.
    It allows you to set target fog colors and handles the gradual fading effect.

    Credits: 
	- Refactored from The_Flood (Flood @ hiveworkshop) system
	- Ideas from Bribe's RetroFade library
*/
//===========================================================================
//===========================================================================
// GLOBALS
//===========================================================================
globals
	// Configurable constants
	private constant real FOG_FADE_PERIOD = 0.03 // Time in seconds between fog updates
	private constant integer MAX_PLAYERS = 24
	private constant boolean DEBUG = true
    // Fog data arrays
	boolean array Fog_Player_FogFading
	real array Fog_Player_CurrentFogRed
	real array Fog_Player_CurrentFogGreen
	real array Fog_Player_CurrentFogBlue
	real array Fog_Player_FogRed
	real array Fog_Player_FogGreen
	real array Fog_Player_FogBlue
	real array Fog_Player_FogZ_Start
	real array Fog_Player_FogZ_End
	player array Fog_Player
	real Fog_ChangeSpeed = 0.03 // Lower value for smoother fade
	timer FogFadeTimer = null
endglobals

// Debug output
private function Debug takes string msg returns nothing
    if DEBUG then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[FogSystem] " + msg)
    endif
endfunction

// Helper: Absolute value (since AbsBJ may not be declared)
function AbsBJ takes real x returns real
	if x >= 0.0 then
		return x
	endif
	return -x
endfunction

//===========================================================================
// FUNCTION: FogFade
// Gradually adjusts the fog color for each player towards their target values.
//===========================================================================
private function FogFade takes nothing returns nothing
	local real red
	local real green
	local real blue
	local real startZ
	local real endZ
	local integer i = 1
	local integer check
	local player p
	local integer activeCount = 0

	loop
		exitwhen i > MAX_PLAYERS
		set check = 0
		if Fog_Player_FogFading[i] then
			set p = Player(i-1)
			// BLUE (RetroFade style)
			if Fog_Player_CurrentFogBlue[i] == Fog_Player_FogBlue[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogBlue[i] = Fog_Player_CurrentFogBlue[i] + (Fog_Player_FogBlue[i] - Fog_Player_CurrentFogBlue[i]) * Fog_ChangeSpeed
				// Snap to target if close
				if AbsBJ(Fog_Player_CurrentFogBlue[i] - Fog_Player_FogBlue[i]) < 1.0 then
					set Fog_Player_CurrentFogBlue[i] = Fog_Player_FogBlue[i]
				endif
			endif
			// GREEN (RetroFade style)
			if Fog_Player_CurrentFogGreen[i] == Fog_Player_FogGreen[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogGreen[i] = Fog_Player_CurrentFogGreen[i] + (Fog_Player_FogGreen[i] - Fog_Player_CurrentFogGreen[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogGreen[i] - Fog_Player_FogGreen[i]) < 1.0 then
					set Fog_Player_CurrentFogGreen[i] = Fog_Player_FogGreen[i]
				endif
			endif
			// RED (RetroFade style)
			if Fog_Player_CurrentFogRed[i] == Fog_Player_FogRed[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogRed[i] = Fog_Player_CurrentFogRed[i] + (Fog_Player_FogRed[i] - Fog_Player_CurrentFogRed[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogRed[i] - Fog_Player_FogRed[i]) < 1.0 then
					set Fog_Player_CurrentFogRed[i] = Fog_Player_FogRed[i]
				endif
			endif

			if check >= 3 then
				set Fog_Player_FogFading[i] = false
			else
				set red = Fog_Player_CurrentFogRed[i]
				set green = Fog_Player_CurrentFogGreen[i]
				set blue = Fog_Player_CurrentFogBlue[i]
				set startZ = Fog_Player_FogZ_Start[i]
				set endZ = Fog_Player_FogZ_End[i]
				if GetLocalPlayer() == p then
					call SetTerrainFogEx(0, startZ, endZ, 0, red*0.01, green*0.01, blue*0.01)
				endif
				set activeCount = activeCount + 1
			endif
		endif
		set i = i + 1
	endloop
	// Optionally, turn off the timer if no players are fading
	if activeCount == 0 and FogFadeTimer != null then
		call PauseTimer(FogFadeTimer)
	endif
endfunction

//===========================================================================
// FUNCTION: Periodic
// Timer callback to handle periodic fog fading.
//===========================================================================
private function Periodic takes nothing returns nothing
	call FogFade()
endfunction

//===========================================================================
// FUNCTION: AddFogForPlayer
// Adds fog settings for a specific player and initiates fading if necessary.
//===========================================================================
function AddFogForPlayer takes real start, real end, real Red, real Green, real Blue, player whichplayer returns nothing
	local integer idx = GetPlayerId(whichplayer) + 1
	local boolean sameCurrentColor

    if Fog_Player_FogZ_Start[idx] == start and Fog_Player_FogZ_End[idx] == end and Fog_Player_FogRed[idx] == Red and Fog_Player_FogGreen[idx] == Green and Fog_Player_FogBlue[idx] == Blue then
        return
    endif

    set sameCurrentColor = Fog_Player_CurrentFogRed[idx] == Red and Fog_Player_CurrentFogGreen[idx] == Green and Fog_Player_CurrentFogBlue[idx] == Blue

	set Fog_Player_FogZ_Start[idx] = start
	set Fog_Player_FogZ_End[idx] = end
	set Fog_Player_FogRed[idx] = Red
	set Fog_Player_FogBlue[idx] = Blue
	set Fog_Player_FogGreen[idx] = Green

    if sameCurrentColor then
        set Fog_Player_FogFading[idx] = false
        if GetLocalPlayer() == whichplayer then
            call SetTerrainFogEx(0, start, end, 0, Red*0.01, Green*0.01, Blue*0.01)
        endif
    else
		set Fog_Player_FogFading[idx] = true
		// Start the fade timer only if not already running
		if FogFadeTimer == null or TimerGetRemaining(FogFadeTimer) <= 0.0 then
			call TimerStart(FogFadeTimer, FOG_FADE_PERIOD, true, function Periodic)
		endif
    endif
    call Debug("Fog set for player " + I2S(GetPlayerId(whichplayer)))

endfunction

//===========================================================================
// FUNCTION: Init
// Initializes the fog system and starts the periodic timer.
//===========================================================================
private function Init takes nothing returns nothing
	local integer i = 1
	local player p

    set FogFadeTimer = CreateTimer()

	// Initialize fog values for each user player
	loop
		exitwhen i > MAX_PLAYERS
		set p = Player(i-1)
		if (GetPlayerController(p) == MAP_CONTROL_USER) and (GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING) then
			set Fog_Player[i] = p
			set Fog_Player_CurrentFogBlue[i] = 50.00
			set Fog_Player_CurrentFogGreen[i] = 50.00
			set Fog_Player_CurrentFogRed[i] = 50.00
			set Fog_Player_FogZ_Start[i] = 400.00
			set Fog_Player_FogZ_End[i] = 5000.00
			// Set initial fog for player
			call AddFogForPlayer(400, 3000, 100, 100, 100, p)
		endif
		set i = i + 1
	endloop
	// Timer will be started only when a fade is requested
endfunction
endlibrary
