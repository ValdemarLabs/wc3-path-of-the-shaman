library ExSound initializer Init
//===========================================================================
/*
    ExSound

    Author: [Valdemar]

    Description:
    External sound management system for Warcraft III.
    - Sounds are registered with string keys ("Nazgrek_0001")
    - Supports global, unit, and point playback
    - Auto-register helpers for sequential dialog files
    - Exposes udg_SoundDuration for last played sound

    Globals (GUI accessible):
        udg_ExSoundDuration : real   -> duration in seconds of last played sound - to be used in waits/timers/cinematics
        udg_ExSoundRegion   : region -> region for ambience playback
        udg_ExSoundPoint    : point  -> point for sound playback
        udg_ExSoundUnit     : unit   -> unit for sound playback
        udg_ExSoundString   : string -> string used to pass dialog text for duration estimation and also to pass to Cinematic Transmission subtitles

    API:
    Init / preload sound functions:
        call ExSound_Register(key, path)
        call ExSound_RegisterSequence("Nazgrek_", 1, 50, "Pots\\Sound\\Dialogs\\")

    Playback functions:
        call ExSound_Play("Nazgrek_0001", "Hello there!")                                   // with dialog text for duration estimation
        call ExSound_Play("Nazgrek_0001", "")                                               // with empty dialog text to force fallback duration

        call ExSound_PlayAtUnit("Nazgrek_0002", udg_Hero, "How are you?")                   // at unit
        call ExSound_PlayAtUnit("Nazgrek_0002", udg_Hero, "")                               // at unit, empty dialog text

        call ExSound_PlayAtPoint("Nazgrek_0003", udg_ExSoundPoint, "Yes, I see it!")        // at point
        call ExSound_PlayAtPoint("Nazgrek_0003", udg_ExSoundPoint, "")                      // at point, empty dialog text

        call ExSound_Stop()

        call ExSound_PlayAmbience(udg_ExSoundRegion, "ForestAmbience")
        call ExSound_StopAmbience(udg_ExSoundRegion)

*/ 
//===========================================================================
// GLOBALS
//===========================================================================
globals
    private hashtable       es_Table = InitHashtable()          // key -> path mapping
    private integer         es_CurrentHash = 0                  // hash of currently playing sound key

    private sound array     es_CurrentSound[128]                // currently playing sounds (max 128 simultaneous)
    private integer         es_CurrentSoundCount = 0            // active sound count

    private sound array     es_AmbienceByRect[8192]             // map each region index to its sound

    private string array    es_KeyList                          // list of registered keys for preload
    private integer         es_KeyCount = 0                     // number of registered keys    

    constant real           EXSOUND_FALLBACK_DURATION = 5.0     // seconds if sound duration cannot be determined
    constant real           EXSOUND_CHARSPERSECOND = 3.5        // for text duration estimation
    constant real           EXSOUND_MIN_DURATION = 50           // minimum valid sound duration in ms
    
endglobals
//===========================================================================

//=================================================================
// Register single sound by key
//=================================================================
function ExSound_Register takes string key, string path returns nothing
    call SaveStr(es_Table, StringHash(key), 0, path)

    // store key for preload
    set es_KeyList[es_KeyCount] = key
    set es_KeyCount = es_KeyCount + 1

    //call BJDebugMsg("Registered sound: " + key + " -> " + path)

endfunction

//=================================================================
// Register sequence: baseName + padded numbers
// Example: ExSound_RegisterSequence("Nazgrek_", 1, 50, "Pots\\Sound\\Dialogs\\")
//   → "Nazgrek_0001", "Nazgrek_0002", ..., "Nazgrek_0050"
//=================================================================
function ExSound_RegisterSequence takes string base, integer first, integer last, string folder returns nothing
    local integer i = first
    local string key
    local string path
    loop
        exitwhen i > last
        if i < 10 then
            set key = base + "000" + I2S(i)
        elseif i < 100 then
            set key = base + "00" + I2S(i)
        elseif i < 1000 then
            set key = base + "0" + I2S(i)
        else
            set key = base + I2S(i)
        endif
        set path = folder + key + ".mp3"
        call ExSound_Register(key, path) // handles preload list
        set i = i + 1
    endloop

    //call BJDebugMsg("Registered sequence: " + base + I2S(first) + " -> " + I2S(last))
    
endfunction

//=================================================================
// Preload all registered sounds
//=================================================================
function ExSound_PreloadAll takes nothing returns nothing
    local integer i = 0
    local string key
    local string path
    local sound s

    loop
        exitwhen i >= es_KeyCount
        set key = es_KeyList[i]
        set path = LoadStr(es_Table, StringHash(key), 0)

        if path != null and path != "" then
            set s = CreateSound(path, false, false, false, 12700, 12700, "")
            call SetSoundVolume(s, 0) // mute preload
            call StartSound(s)
            call StopSound(s, true, false)
            call KillSoundWhenDone(s)
            //call BJDebugMsg("Preloaded sound: " + key)
        endif

        set i = i + 1
    endloop
endfunction

//=================================================================
// Initialization – add sound path registrations here
//=================================================================
private function Init takes nothing returns nothing
    // Example: single manual registration
    // call ExSound_Register("Nazgrek_0001", "Pots\\Sound\\Voicelines\\Nazgrek\\Nazgrek_0001.mp3")
    // call ExSound_Register("GrumBloodfang_0001", "Pots\\Sound\\Voicelines\\GrumBloodfang\\GrumBloodfang_0001.mp3")

    //=================================================================
    // Batch registration

    call ExSound_RegisterSequence("AtexBlix_", 1, 80, "Pots\\Sound\\Voicelines\\AtexBlix\\")    
    call ExSound_RegisterSequence("BoomBrothers_", 1, 100, "Pots\\Sound\\Voicelines\\BoomBrothers\\")    
    call ExSound_RegisterSequence("Demoness_", 1, 50, "Pots\\Sound\\Voicelines\\Demoness\\")   
    call ExSound_RegisterSequence("Garthork_", 1, 50, "Pots\\Sound\\Voicelines\\Garthork\\")   
    call ExSound_RegisterSequence("Granis_", 1, 50, "Pots\\Sound\\Voicelines\\Granis\\")   
    call ExSound_RegisterSequence("GrumBloodfang_", 1, 70, "Pots\\Sound\\Voicelines\\GrumBloodfang\\")
    call ExSound_RegisterSequence("HumanFemale1_", 1, 50, "Pots\\Sound\\Voicelines\\HumanFemale1\\")
    call ExSound_RegisterSequence("Jinzun_", 1, 150, "Pots\\Sound\\Voicelines\\Jinzun\\")
    call ExSound_RegisterSequence("Krezgrel_", 1, 50, "Pots\\Sound\\Voicelines\\Krezgrel\\")
    call ExSound_RegisterSequence("Narrator_", 1, 25, "Pots\\Sound\\Voicelines\\Narrator\\")
    call ExSound_RegisterSequence("Nazgrek_", 1, 500, "Pots\\Sound\\Voicelines\\Nazgrek\\")
    call ExSound_RegisterSequence("OrcGrunt_", 1, 150, "Pots\\Sound\\Voicelines\\OrcGrunt\\")
    call ExSound_RegisterSequence("OrcPeon_", 1, 50, "Pots\\Sound\\Voicelines\\OrcPeon\\")
    call ExSound_RegisterSequence("Satyr_", 1, 100, "Pots\\Sound\\Voicelines\\Satyr\\")
    call ExSound_RegisterSequence("Shipmaster_", 1, 50, "Pots\\Sound\\Voicelines\\Shipmaster\\")
    call ExSound_RegisterSequence("Thork_", 1, 50, "Pots\\Sound\\Voicelines\\Thork\\")    
    call ExSound_RegisterSequence("Zulkis_", 1, 300, "Pots\\Sound\\Voicelines\\Zulkis\\")  
    call ExSound_RegisterSequence("Aradion_", 1, 300, "Pots\\Sound\\Voicelines\\AradionFarseer\\")    
    call ExSound_RegisterSequence("Valeria_", 1, 300, "Pots\\Sound\\Voicelines\\Valeria\\")   
    call ExSound_RegisterSequence("Kaelthir_", 1, 300, "Pots\\Sound\\Voicelines\\Kaelthir\\")  
    call ExSound_RegisterSequence("Zerathis_", 1, 300, "Pots\\Sound\\Voicelines\\Zerathis\\")  
    call ExSound_RegisterSequence("VoidEntity_", 1, 33, "Pots\\Sound\\Voicelines\\VoidEntity\\")  
    call ExSound_RegisterSequence("DarkShaman_", 1, 30, "Pots\\Sound\\Voicelines\\DarkShaman\\")  
    call ExSound_RegisterSequence("Mordrax_", 1, 30, "Pots\\Sound\\Voicelines\\Mordrax\\")  
  

    // preload all sounds after 0.0s - Note: done manually in PoTS
    // call TimerStart(CreateTimer(), 0.0, false, function ExSound_PreloadAll)

    // call BJDebugMsg("ExSound Initialized")

endfunction

//=================================================================
// Helper to remove a sound from the array by index
//=================================================================
private function RemoveSoundFromArray takes integer idx returns nothing
    local integer i = idx

    loop
        exitwhen i >= es_CurrentSoundCount - 1
        set es_CurrentSound[i] = es_CurrentSound[i + 1]
        set i = i + 1
    endloop
    set es_CurrentSound[es_CurrentSoundCount - 1] = null
    set es_CurrentSoundCount = es_CurrentSoundCount - 1
endfunction

//=================================================================
// Remove finished sounds to free slots
//=================================================================
private function CleanupFinished takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= es_CurrentSoundCount
        if es_CurrentSound[i] != null then
            call KillSoundWhenDone(es_CurrentSound[i])
            call RemoveSoundFromArray(i)                
            // do not increment i, because array shifted left
            set i = i - 1
        endif
        set i = i + 1
    endloop

endfunction

//=================================================================
// Estimate duration from text length (for fallback if sound duration is unknown)
//=================================================================
private function EstimateDurationFromText takes string dialogtext returns real
    local integer len = StringLength(dialogtext)
    local real charsPerSecond = EXSOUND_CHARSPERSECOND    
    return I2R(len) / charsPerSecond
endfunction

//=================================================================
// Stop current sound
//=================================================================
function ExSound_Stop takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= es_CurrentSoundCount
        if es_CurrentSound[i] != null then
            call StopSound(es_CurrentSound[i], false, false)
        endif
        set i = i + 1
    endloop
    set es_CurrentSoundCount = 0
    set udg_ExSoundDuration = 0.0
    //call BJDebugMsg("Stopped all current sounds")

endfunction

//=================================================================
// Internal play helper
//=================================================================
private function ExSound_PlayInternal takes string key, boolean is3D, real x, real y, unit u, string dialogtext returns nothing
    local string path = LoadStr(es_Table, StringHash(key), 0)
    local sound s
    local integer durMS
    
    if path == null or path == "" then
        //call BJDebugMsg("ExSound ERROR: key '" + key + "' not registered.")
    endif

    // Cleanup finished sounds
    call CleanupFinished()

    // Create new sound
    set s = CreateSound(path, false, false, is3D, 12700, 12700, "")
    set es_CurrentSound[es_CurrentSoundCount] = s
    set es_CurrentSoundCount = es_CurrentSoundCount + 1
    set es_CurrentHash = StringHash(key)
    
    if is3D then
        if u != null then
            call AttachSoundToUnit(s, u)
        else
            call SetSoundPosition(s, x, y, 0)
        endif
        call SetSoundDistances(s, 0.0, 3000.0)
        call SetSoundDistanceCutoff(s, 3000.0)
    endif
    
    // Duration
    // Try to get actual sound duration
    set durMS = GetSoundDuration(s)

    if durMS > EXSOUND_MIN_DURATION then
        set udg_ExSoundDuration = I2R(durMS) / 1000.0

    elseif dialogtext != null then
        // Estimate from dialog text if available
        set udg_ExSoundDuration = EstimateDurationFromText(dialogtext)
        call BJDebugMsg("ExSound WARNING: '" + key + "' missing, estimated from text: " + R2S(udg_ExSoundDuration) + "s")

    // Fallback to constant duration - UNUSED, because sound and/or dialogtext should always be provided
    //elseif dialogtext == null then
        // Fallback to constant if no dialog text provided
    //    set udg_ExSoundDuration = EXSOUND_FALLBACK_DURATION
    //    call BJDebugMsg("ExSound WARNING: '" + key + "' missing, using constant fallback: " + R2S(udg_ExSoundDuration) + "s")

    endif

    //call BJDebugMsg("Play: " + key + " (" + R2S(udg_ExSoundDuration) + "s)")

    call StartSound(s)

endfunction

//=================================================================
// Public API
//=================================================================
function ExSound_Play takes string key, string dialogtext returns nothing
    call ExSound_PlayInternal(key, false, 0, 0, null, dialogtext)
    //call BJDebugMsg("ExSound_Play called: " + key)
endfunction

function ExSound_PlayAtUnit takes string key, unit u, string dialogtext returns nothing
    call ExSound_PlayInternal(key, true, 0, 0, u, dialogtext)
    //call BJDebugMsg("ExSound_PlayAtUnit called: " + key)
endfunction

function ExSound_PlayAtPoint takes string key, location soundpoint, string dialogtext returns nothing
    local real x = GetLocationX(soundpoint)
    local real y = GetLocationY(soundpoint)

    call ExSound_PlayInternal(key, true, x, y, null, dialogtext)
    //call BJDebugMsg("ExSound_PlayAtPoint called at point: " + R2S(x) + "," + R2S(y) + " -> " + key)
endfunction

//=================================================================
// Ambience
//=================================================================
// Plays ambience for a specific region
function ExSound_PlayAmbience takes rect r, string key returns nothing
    local sound s
    local string path
    local integer idx

    // Load the path from registration table
    set path = LoadStr(es_Table, StringHash(key), 0)
    if path == null or path == "" then
        //call BJDebugMsg("ExSound ERROR: key '" + key + "' not registered for ambience.")
        return
    endif

    // Stop and destroy previous ambience for this rect if exists
    set idx = GetHandleId(r)
    if es_AmbienceByRect[idx] != null then
        call SetStackedSoundBJ(false, es_AmbienceByRect[idx], r)
        set es_AmbienceByRect[idx] = null
    endif

    // Create new sound
    set s = CreateSound(path, true, true, true, 12700, 12700, "")
    
    // Add sound to rect
    call SetStackedSoundBJ(true, s, r)

    // Store reference by rect handle
    set es_AmbienceByRect[idx] = s

    //call BJDebugMsg("Playing ambience: " + key + " in rect id " + I2S(idx))
endfunction

// Stops ambience in a specific rect
function ExSound_StopAmbience takes rect r returns nothing
    local integer idx = GetHandleId(r)
    local sound s = es_AmbienceByRect[idx]

    if es_AmbienceByRect[idx] != null then

        // Detach from rect
        call SetStackedSoundBJ(false, s, r)

        // Explicitly stop it
        call StopSound(s, true, true)

        // Kill handle
        call KillSoundWhenDone(s)

        // Clear reference
        set es_AmbienceByRect[idx] = null

        call BJDebugMsg("Stopped and destroyed ambience in rect id " + I2S(idx))


    endif

endfunction

//=================================================================
endlibrary
