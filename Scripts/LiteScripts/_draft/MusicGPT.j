library ExternalMusic initializer init

/*

    API:
        call PlayExternalMusic(string path, boolean useFade) - plays the specified external music file, optionally fading in
        
            Example (Fade-in new track):
            call PlayExternalMusic("Pots\\Sound\\Music\\test1.mp3", true)

            Example (Play instantly (no fade)):
            call PlayExternalMusic("Pots\\Sound\\Music\\test1.mp3", false)

        call StopExternalMusic(true) - stops the current music, optionally fading out
        call StopExternalMusic(false) - stops the current music instantly

        call SetExternalMusicVolume(100) - sets the target volume (0–127); if music is playing, adjusts immediately

        (Note: Volume changes during fade-in/out will take effect after the fade completes) 
        (Note: Only one external track can be played at a time) 

*/ 

globals
    private sound currentMusic = null
    private real currentVolume = 127 // Warcraft’s max volume
    private real fadeStep = 5        // how much volume changes per tick
    private timer fadeTimer = CreateTimer()
    private boolean fadingIn = false
    private boolean fadingOut = false
endglobals

//=============================
// Core Music Control
//=============================

// Play external track (optionally fade in)
function PlayExternalMusic takes string path, boolean useFade returns nothing
    // stop previous
    call StopExternalMusic(true)

    // create new sound
    set currentMusic = CreateSound(path, false, false, false, 12700, 12700, "")
    if useFade then
        call SetSoundVolume(currentMusic, 0)
        set fadingIn = true
        set fadingOut = false
        call StartSound(currentMusic)
        call TimerStart(fadeTimer, 0.1, true, function FadeStep)
    else
        call SetSoundVolume(currentMusic, R2I(currentVolume))
        call StartSound(currentMusic)
    endif
endfunction

// Stop external track (with fade or instant)
function StopExternalMusic takes boolean fade returns nothing
    if currentMusic == null then
        return
    endif
    if fade then
        set fadingOut = true
        set fadingIn = false
        call TimerStart(fadeTimer, 0.1, true, function FadeStep)
    else
        call StopSound(currentMusic, true, false) // instant
        set currentMusic = null
    endif
endfunction

// Set target volume (0–127)
function SetExternalMusicVolume takes real vol returns nothing
    set currentVolume = vol
    if currentMusic != null and not fadingIn and not fadingOut then
        call SetSoundVolume(currentMusic, R2I(vol))
    endif
endfunction

//=============================
// Fade Handling
//=============================

private function FadeStep takes nothing returns nothing
    local integer curVol
    if currentMusic == null then
        call PauseTimer(fadeTimer)
        return
    endif

    set curVol = GetSoundVolume(currentMusic)

    if fadingIn then
        if curVol + R2I(fadeStep) < R2I(currentVolume) then
            call SetSoundVolume(currentMusic, curVol + R2I(fadeStep))
        else
            call SetSoundVolume(currentMusic, R2I(currentVolume))
            set fadingIn = false
            call PauseTimer(fadeTimer)
        endif

    elseif fadingOut then
        if curVol - R2I(fadeStep) > 0 then
            call SetSoundVolume(currentMusic, curVol - R2I(fadeStep))
        else
            call StopSound(currentMusic, true, false)
            set currentMusic = null
            set fadingOut = false
            call PauseTimer(fadeTimer)
        endif
    endif
endfunction

private function init takes nothing returns nothing
    // optional: initialize defaults
endfunction

endlibrary
