library CustomMusic initializer init
/*
    Credits: Zwiebelchen

*/
globals
    private constant integer MAX_TRACKS = 99 //defines how many custom tracks the player can have in the folder
    private constant string EMPTY = "Sound\\Units\\Human\\Rifleman\\RiflemanDeath.wav"
    //this is a random default sound file that it used as a placeholder to make sure CreateSound always creates a proper sound handle

    private string array Track[MAX_TRACKS]
    private string array Default[MAX_TRACKS]
    private sound array TrackSnd[MAX_TRACKS]
    private integer currentTrack = 0 //we are working local anyway, so we don't need an array
endglobals

private function SetupTracks takes nothing returns nothing //register the names for the files here
    set Track[0] = "CustomMusic\\Track-01.mp3"
    set Track[1] = "CustomMusic\\Track-02.mp3"
    //... you can also loop and increment the track numbers via string concatenation, but I thought it's better to actually have descriptive names for these files
    set Default[0] = "Music\\SomeDefaultWC3musicInMPQ.mp3"
    set Default[1] = "Music\\SomeDefaultWC3musicInMPQ.mp3"
    //... these are the defaults that play if the user doesn't have any sounds in the folder
endfunction

private function update takes nothing returns nothing
    if not (GetSoundIsPlaying(TrackSnd[currentTrack]) or GetSoundIsLoading(TrackSnd[currentTrack])) then
        //track has finished playing, start the next one
        loop
            set currentTrack = currentTrack + 1
            if currentTrack >= MAX_TRACKS then
                set currentTrack = 0 //start again from the top
            endif
            if Track[currentTrack] != EMPTY or Default[currentTrack] != EMPTY then
                call StartSound(TrackSnd[currentTrack])
                exitwhen true
            endif
        endloop
    endif
endfunction

private function initCallback takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer i = 0
    local string s = EMPTY

    call TimerStart(t, 1, true, function update)
    set t = null

    call SetupTracks()

    loop
        exitwhen i >= MAX_TRACKS
        if GetSoundFileDuration(Track[i]) > 0 then
            set s = Track[i]
        elseif GetSoundFileDuration(Default[i]) > 0 then
            set s = Default[i]
        endif
        set TrackSnd[i] = CreateSound(s, false, false, false, 12700, 12700, "")
        set i = i + 1
    endloop

    //start the first track on map initialization
    if Track[currentTrack] != EMPTY or Default[currentTrack] != EMPTY then
        call StartSound(TrackSnd[currentTrack])
    else
        call update()
    endif
endfunction

private function init takes nothing returns nothing
    call TimerStart(CreateTimer(), 0, false, initCallback)
endfunction