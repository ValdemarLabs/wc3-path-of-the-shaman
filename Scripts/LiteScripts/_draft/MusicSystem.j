library ExMusicSystem initializer Init
//===========================================================================
/*
    ExMusicSystem 

    Author: [Valdemar]

    Description:
    A simple external music management system for Warcraft III that allows registering multiple music tracks,
    playing specific tracks, playing random tracks, and cycling through a playlist. It supports mp3 files located in the game's directory.
    The system ensures that only valid tracks are played and manages the current track state.

    API:
        call MusicSystem_Init() - Initializes the music system and registers tracks.
        call MusicSystem_PlayTrack(index) - Plays the track at the specified index.
        call MusicSystem_PlayRandom() - Plays a random track from the registered tracks.
        call MusicSystem_PlayNext() - Plays the next track in the playlist, looping back to the start if at the end.

*/ 
//=================================================================
// Globals
//=================================================================
globals

    private string array ms_MusicPaths          // array to hold music file paths
    private string ms_TempString = ""           // temporary string for file paths

    private integer ms_MusicCount = 0           // number of registered tracks
    private integer ms_CurrentTrack = -1        // currently playing track index

endglobals

//=================================================================
// Initialize the music system and register tracks
//=================================================================
private function Init takes nothing returns nothing
    set ms_MusicCount = 0

    // TRACKS
    set ms_MusicPaths[0] = "Pots\\Sound\\Music\\09 Orgrimmar.mp3"
    set ms_MusicPaths[1] = "Pots\\Sound\\Music\\34. Naxxramas (Abomination Wing).mp3"
    set ms_MusicPaths[2] = "Pots\\Sound\\Music\\test1.mp3"

    // Add more tracks as needed, ensuring the paths are correct and files exist

    set ms_MusicCount = 3

endfunction

//=================================================================
// Play a track by index
//=================================================================
function MusicSystem_PlayTrack takes integer index returns nothing
    if index < 0 or index >= ms_MusicCount then
        return
    endif

    set ms_TempString = ms_MusicPaths[index]

    if GetSoundFileDuration(ms_TempString) > 0 then
        call PlayMusic(ms_TempString)
        set ms_CurrentTrack = index
    endif

endfunction

//=================================================================
// Play random track
//=================================================================
function MusicSystem_PlayRandom takes nothing returns nothing
    local integer r = GetRandomInt(0, ms_MusicCount - 1)
    call MusicSystem_PlayTrack(r)

endfunction

//=================================================================
// Play next track in playlist (loops)
//=================================================================
function MusicSystem_PlayNext takes nothing returns nothing
    local integer next = ms_CurrentTrack + 1

    if next >= ms_MusicCount then
        set next = 0
    endif
    call MusicSystem_PlayTrack(next)

endfunction
//===========================================================================
endlibrary
