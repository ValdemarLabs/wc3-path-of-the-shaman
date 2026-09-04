library FogSystem initializer Init
//===========================================================================
/*
    FogSystem
    
    Author: [Valdemar]
    
    Description:
    Smoothly transitions terrain-fog distance and color for individual players.

    Credits: 
	- Refactored from The_Flood (Flood @ hiveworkshop) system
	- Ideas from Bribe's RetroFade library

    How to install:
    Import this library before ZoneEvent and systems that temporarily override terrain fog.

    API:
    - AddFogForPlayer(start, end, red, green, blue, whichPlayer)
    - FogSystem_BeginOverride() / FogSystem_EndOverride()
    - FogSystem_GetCurrentStart/End/Red/Green/Blue(whichPlayer)
*/
//===========================================================================
//===========================================================================
// GLOBALS
//===========================================================================
globals
	// Configurable constants
	private constant real FOG_FADE_PERIOD = 0.03 // Time in seconds between fog updates
	private constant real FOG_COLOR_EPSILON = 1.0
	private constant real FOG_DISTANCE_EPSILON = 1.0
	private constant integer MAX_PLAYERS = 24
	private constant boolean DEBUG = true
    // Fog data arrays
	boolean array Fog_Player_FogFading
	real array Fog_Player_CurrentFogZ_Start
	real array Fog_Player_CurrentFogZ_End
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
	private boolean FogFadeTimerRunning = false
	private integer FogOverrideCount = 0
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

private function ApplyCurrentFog takes integer index returns nothing
	local player p = Player(index - 1)

	if FogOverrideCount == 0 and GetLocalPlayer() == p then
		call SetTerrainFogEx(0, Fog_Player_CurrentFogZ_Start[index], Fog_Player_CurrentFogZ_End[index], 0, Fog_Player_CurrentFogRed[index]*0.01, Fog_Player_CurrentFogGreen[index]*0.01, Fog_Player_CurrentFogBlue[index]*0.01)
	endif
	set p = null
endfunction

//===========================================================================
// FUNCTION: FogFade
// Gradually adjusts the fog color for each player towards their target values.
//===========================================================================
private function FogFade takes nothing returns nothing
	local real red
	local real green
	local real blue
	local integer i = 1
	local integer check
	local player p
	local integer activeCount = 0

	loop
		exitwhen i > MAX_PLAYERS
		set check = 0
		if Fog_Player_FogFading[i] then
			set p = Player(i-1)
			// FOG START DISTANCE
			if Fog_Player_CurrentFogZ_Start[i] == Fog_Player_FogZ_Start[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogZ_Start[i] = Fog_Player_CurrentFogZ_Start[i] + (Fog_Player_FogZ_Start[i] - Fog_Player_CurrentFogZ_Start[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogZ_Start[i] - Fog_Player_FogZ_Start[i]) < FOG_DISTANCE_EPSILON then
					set Fog_Player_CurrentFogZ_Start[i] = Fog_Player_FogZ_Start[i]
				endif
			endif
			// FOG END DISTANCE
			if Fog_Player_CurrentFogZ_End[i] == Fog_Player_FogZ_End[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogZ_End[i] = Fog_Player_CurrentFogZ_End[i] + (Fog_Player_FogZ_End[i] - Fog_Player_CurrentFogZ_End[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogZ_End[i] - Fog_Player_FogZ_End[i]) < FOG_DISTANCE_EPSILON then
					set Fog_Player_CurrentFogZ_End[i] = Fog_Player_FogZ_End[i]
				endif
			endif
			// BLUE (RetroFade style)
			if Fog_Player_CurrentFogBlue[i] == Fog_Player_FogBlue[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogBlue[i] = Fog_Player_CurrentFogBlue[i] + (Fog_Player_FogBlue[i] - Fog_Player_CurrentFogBlue[i]) * Fog_ChangeSpeed
				// Snap to target if close
				if AbsBJ(Fog_Player_CurrentFogBlue[i] - Fog_Player_FogBlue[i]) < FOG_COLOR_EPSILON then
					set Fog_Player_CurrentFogBlue[i] = Fog_Player_FogBlue[i]
				endif
			endif
			// GREEN (RetroFade style)
			if Fog_Player_CurrentFogGreen[i] == Fog_Player_FogGreen[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogGreen[i] = Fog_Player_CurrentFogGreen[i] + (Fog_Player_FogGreen[i] - Fog_Player_CurrentFogGreen[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogGreen[i] - Fog_Player_FogGreen[i]) < FOG_COLOR_EPSILON then
					set Fog_Player_CurrentFogGreen[i] = Fog_Player_FogGreen[i]
				endif
			endif
			// RED (RetroFade style)
			if Fog_Player_CurrentFogRed[i] == Fog_Player_FogRed[i] then
				set check = check + 1
			else
				set Fog_Player_CurrentFogRed[i] = Fog_Player_CurrentFogRed[i] + (Fog_Player_FogRed[i] - Fog_Player_CurrentFogRed[i]) * Fog_ChangeSpeed
				if AbsBJ(Fog_Player_CurrentFogRed[i] - Fog_Player_FogRed[i]) < FOG_COLOR_EPSILON then
					set Fog_Player_CurrentFogRed[i] = Fog_Player_FogRed[i]
				endif
			endif

			if check >= 5 then
				set Fog_Player_FogFading[i] = false
				call ApplyCurrentFog(i)
			else
				set red = Fog_Player_CurrentFogRed[i]
				set green = Fog_Player_CurrentFogGreen[i]
				set blue = Fog_Player_CurrentFogBlue[i]
				if FogOverrideCount == 0 and GetLocalPlayer() == p then
					call SetTerrainFogEx(0, Fog_Player_CurrentFogZ_Start[i], Fog_Player_CurrentFogZ_End[i], 0, red*0.01, green*0.01, blue*0.01)
				endif
				set activeCount = activeCount + 1
			endif
		endif
		set i = i + 1
	endloop
	// Optionally, turn off the timer if no players are fading
	if activeCount == 0 and FogFadeTimer != null then
		call PauseTimer(FogFadeTimer)
		set FogFadeTimerRunning = false
	endif
	set p = null
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
	local boolean sameCurrentFog

    if Fog_Player_FogZ_Start[idx] == start and Fog_Player_FogZ_End[idx] == end and Fog_Player_FogRed[idx] == Red and Fog_Player_FogGreen[idx] == Green and Fog_Player_FogBlue[idx] == Blue then
        return
    endif

	set sameCurrentFog = Fog_Player_CurrentFogZ_Start[idx] == start and Fog_Player_CurrentFogZ_End[idx] == end and Fog_Player_CurrentFogRed[idx] == Red and Fog_Player_CurrentFogGreen[idx] == Green and Fog_Player_CurrentFogBlue[idx] == Blue

	set Fog_Player_FogZ_Start[idx] = start
	set Fog_Player_FogZ_End[idx] = end
	set Fog_Player_FogRed[idx] = Red
	set Fog_Player_FogBlue[idx] = Blue
	set Fog_Player_FogGreen[idx] = Green

	if sameCurrentFog then
		set Fog_Player_FogFading[idx] = false
		call ApplyCurrentFog(idx)
	else
		set Fog_Player_FogFading[idx] = true
		if not FogFadeTimerRunning then
			call TimerStart(FogFadeTimer, FOG_FADE_PERIOD, true, function Periodic)
			set FogFadeTimerRunning = true
		endif
    endif
    call Debug("Fog set for player " + I2S(GetPlayerId(whichplayer)))

endfunction

public function BeginOverride takes nothing returns nothing
	set FogOverrideCount = FogOverrideCount + 1
endfunction

public function EndOverride takes nothing returns nothing
	local integer i = 1

	if FogOverrideCount > 0 then
		set FogOverrideCount = FogOverrideCount - 1
	endif
	if FogOverrideCount == 0 then
		loop
			exitwhen i > MAX_PLAYERS
			if Fog_Player[i] != null then
				call ApplyCurrentFog(i)
			endif
			set i = i + 1
		endloop
	endif
endfunction

public function GetCurrentStart takes player whichPlayer returns real
	return Fog_Player_CurrentFogZ_Start[GetPlayerId(whichPlayer) + 1]
endfunction

public function GetCurrentEnd takes player whichPlayer returns real
	return Fog_Player_CurrentFogZ_End[GetPlayerId(whichPlayer) + 1]
endfunction

public function GetCurrentRed takes player whichPlayer returns real
	return Fog_Player_CurrentFogRed[GetPlayerId(whichPlayer) + 1]*0.01
endfunction

public function GetCurrentGreen takes player whichPlayer returns real
	return Fog_Player_CurrentFogGreen[GetPlayerId(whichPlayer) + 1]*0.01
endfunction

public function GetCurrentBlue takes player whichPlayer returns real
	return Fog_Player_CurrentFogBlue[GetPlayerId(whichPlayer) + 1]*0.01
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
			set Fog_Player_CurrentFogZ_Start[i] = 400.00
			set Fog_Player_CurrentFogZ_End[i] = 5000.00
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
