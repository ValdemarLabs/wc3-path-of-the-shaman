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
    // Nazgrek Event lines
    call ExSound_Register("Nazgrek_Farewell1", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell1.mp3")
    call ExSound_Register("Nazgrek_Farewell2", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell2.mp3")
    call ExSound_Register("Nazgrek_Farewell3", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell3.mp3")
    call ExSound_Register("Nazgrek_Farewell4", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell4.mp3")
    call ExSound_Register("Nazgrek_Farewell5", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell5.mp3")   
    call ExSound_Register("Nazgrek_Farewell6", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell6.mp3") 
    call ExSound_Register("Nazgrek_Farewell7", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell7.mp3")    
    call ExSound_Register("Nazgrek_Farewell8", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell8.mp3")    
    call ExSound_Register("Nazgrek_Farewell9", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell9.mp3") 
    call ExSound_Register("Nazgrek_Farewell10", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Farewell10.mp3") 
    call ExSound_Register("Nazgrek_Greet1", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet1.mp3")
    call ExSound_Register("Nazgrek_Greet2", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet2.mp3")
    call ExSound_Register("Nazgrek_Greet3", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet3.mp3")
    call ExSound_Register("Nazgrek_Greet4", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet4.mp3")
    call ExSound_Register("Nazgrek_Greet5", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet5.mp3")
    call ExSound_Register("Nazgrek_Greet6", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet6.mp3")
    call ExSound_Register("Nazgrek_Greet7", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet7.mp3")
    call ExSound_Register("Nazgrek_Greet8", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_Greet8.mp3")
    call ExSound_Register("Nazgrek_GeneralError1", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_GeneralError1.mp3")
    call ExSound_Register("Nazgrek_GeneralError2", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_GeneralError2.mp3")
    call ExSound_Register("Nazgrek_ItemError2HShield", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemError2HShield.mp3")
    call ExSound_Register("Nazgrek_ItemError2Any", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemErrorAny.mp3")
    call ExSound_Register("Nazgrek_ItemErrorGeneral", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemErrorGeneral.mp3")   
    call ExSound_Register("Nazgrek_ItemErrorGenera2", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemErrorGenera2.mp3")    
    call ExSound_Register("Nazgrek_ItemErrorRings", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemErrorRings.mp3")   
    call ExSound_Register("Nazgrek_ItemErrorWeapons", "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekEventLines\\Nazgrek_ItemErrorWeapons.mp3")     

    //=================================================================
    // Zulkis Event lines
    call ExSound_Register("Zulkis_Greet1", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Greet1.mp3")
    call ExSound_Register("Zulkis_Greet2", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Greet2.mp3")
    call ExSound_Register("Zulkis_Greet3", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Greet3.mp3")
    call ExSound_Register("Zulkis_Greet4", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Greet4.mp3")
    call ExSound_Register("Zulkis_Farewell1", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Farewell1.mp3")
    call ExSound_Register("Zulkis_Farewell2", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Farewell2.mp3")
    call ExSound_Register("Zulkis_Farewell3", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Farewell3.mp3")
    call ExSound_Register("Zulkis_Farewell4", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_Farewell4.mp3")
    call ExSound_Register("Zulkis_GeneralError1", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_GeneralError1.mp3")
    call ExSound_Register("Zulkis_GeneralError2", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_GeneralError2.mp3")
    call ExSound_Register("Zulkis_ItemError2HShield", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemError2HShield.mp3")
    call ExSound_Register("Zulkis_ItemError2Any", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemErrorAny.mp3")
    call ExSound_Register("Zulkis_ItemErrorGeneral", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemErrorGeneral.mp3")
    call ExSound_Register("Zulkis_ItemErrorGenera2", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemErrorGenera2.mp3")
    call ExSound_Register("Zulkis_ItemErrorRings", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemErrorRings.mp3")
    call ExSound_Register("Zulkis_ItemErrorWeapons", "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisEventLines\\Zulkis_ItemErrorWeapons.mp3")

    //=================================================================
    // HeroEngineer Event/chat lines
    call ExSound_Register("HeroEngineer_Aggressive1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Aggressive1.mp3")
    call ExSound_Register("HeroEngineer_Aggressive2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Aggressive2.mp3")

    call ExSound_Register("HeroEngineer_Attacking1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Attacking1.mp3")
    call ExSound_Register("HeroEngineer_Attacking2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Attacking2.mp3")
    call ExSound_Register("HeroEngineer_Attacking3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Attacking3.mp3")

    call ExSound_Register("HeroEngineer_Casting1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Casting1.mp3")
    call ExSound_Register("HeroEngineer_Casting2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Casting2.mp3")
    call ExSound_Register("HeroEngineer_Casting3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Casting3.mp3")

    call ExSound_Register("HeroEngineer_CompanionDies1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_CompanionDies1.mp3")
    call ExSound_Register("HeroEngineer_CompanionDies2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_CompanionDies2.mp3")

    call ExSound_Register("HeroEngineer_DropItems1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_DropItems1.mp3")
    call ExSound_Register("HeroEngineer_DropItems2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_DropItems2.mp3")

    call ExSound_Register("HeroEngineer_Farewell1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Farewell1.mp3")
    call ExSound_Register("HeroEngineer_Farewell2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Farewell2.mp3")
    call ExSound_Register("HeroEngineer_Farewell3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Farewell3.mp3")

    call ExSound_Register("HeroEngineer_GiveItem1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_GiveItem1.mp3")
    call ExSound_Register("HeroEngineer_GiveItem2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_GiveItem2.mp3")
    call ExSound_Register("HeroEngineer_GiveItem3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_GiveItem3.mp3")

    call ExSound_Register("HeroEngineer_Greet1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Greet1.mp3")
    call ExSound_Register("HeroEngineer_Greet2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Greet2.mp3")
    call ExSound_Register("HeroEngineer_Greet3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Greet3.mp3")

    call ExSound_Register("HeroEngineer_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_HoldPositions1.mp3")
    call ExSound_Register("HeroEngineer_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_HoldPositions2.mp3")

    call ExSound_Register("HeroEngineer_Idle1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Idle1.mp3")
    call ExSound_Register("HeroEngineer_Idle2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Idle2.mp3")

    call ExSound_Register("HeroEngineer_Kicked1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Kicked1.mp3")
    call ExSound_Register("HeroEngineer_Kicked2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Kicked2.mp3")

    call ExSound_Register("HeroEngineer_Moving1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Moving1.mp3")
    call ExSound_Register("HeroEngineer_Moving2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Moving2.mp3")
    call ExSound_Register("HeroEngineer_Moving3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Moving3.mp3")

    call ExSound_Register("HeroEngineer_Normal1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Normal1.mp3")
    call ExSound_Register("HeroEngineer_Normal2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Normal2.mp3")
    call ExSound_Register("HeroEngineer_Normal3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Normal3.mp3")

    call ExSound_Register("HeroEngineer_Passive1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Passive1.mp3")
    call ExSound_Register("HeroEngineer_Passive2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Passive2.mp3")
    call ExSound_Register("HeroEngineer_Passive3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_Passive3.mp3") 

    call ExSound_Register("HeroEngineer_UnitDies1", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_UnitDies1.mp3")   
    call ExSound_Register("HeroEngineer_UnitDies2", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_UnitDies2.mp3")
    call ExSound_Register("HeroEngineer_UnitDies3", "Pots\\Sound\\Voicelines\\HeroEngineer\\HeroEngineer_UnitDies3.mp3") 

    call ExSound_Register("HeroEngineer_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral1.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral2.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral3.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral4.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral5.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral6.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatGeneral7.mp3")

    call ExSound_Register("HeroEngineer_ChatPaladin1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatPaladin1.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatPaladin2.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatPaladin3.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatPaladin4.mp3")

    call ExSound_Register("HeroEngineer_ChatRogue1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatRogue1.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatRogue2.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatRogue3.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatRogue4.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue5", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatRogue5.mp3")

    call ExSound_Register("HeroEngineer_ChatShaman1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatShaman1.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatShaman2.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatShaman3.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatShaman4.mp3")

    call ExSound_Register("HeroEngineer_ChatWarlock1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarlock1.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarlock2.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarlock3.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarlock4.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock5", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarlock5.mp3")

    call ExSound_Register("HeroEngineer_ChatWarrior1", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarrior1.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior2", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarrior2.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior3", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarrior3.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior4", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarrior4.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior5", "Pots\\Sound\\Voicelines\\HeroEngineer\\ChatLines\\HeroEngineer_ChatWarrior5.mp3")

    //=================================================================
    // HeroPaladin Event/chat lines
    call ExSound_Register("HeroPaladin_Aggressive1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Aggressive1.mp3")
    call ExSound_Register("HeroPaladin_Aggressive2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Aggressive2.mp3")
    call ExSound_Register("HeroPaladin_Aggressive3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Aggressive3.mp3")

    call ExSound_Register("HeroPaladin_Attack1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Attack1.mp3")
    call ExSound_Register("HeroPaladin_Attack2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Attack2.mp3")
    call ExSound_Register("HeroPaladin_Attack3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Attack3.mp3")

    call ExSound_Register("HeroPaladin_Casting1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Casting1.mp3")
    call ExSound_Register("HeroPaladin_Casting2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Casting2.mp3")

    call ExSound_Register("HeroPaladin_CompanionDies1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_CompanionDies1.mp3")
    call ExSound_Register("HeroPaladin_CompanionDies2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_CompanionDies2.mp3")

    call ExSound_Register("HeroPaladin_DropItems1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_DropItems1.mp3")
    call ExSound_Register("HeroPaladin_DropItems2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_DropItems2.mp3")
    call ExSound_Register("HeroPaladin_DropItems3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_DropItems3.mp3")

    call ExSound_Register("HeroPaladin_Farewell1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Farewell1.mp3")
    call ExSound_Register("HeroPaladin_Farewell2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Farewell2.mp3")
    call ExSound_Register("HeroPaladin_Farewell3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Farewell3.mp3")

    call ExSound_Register("HeroPaladin_GiveItem1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_GiveItem1.mp3")
    call ExSound_Register("HeroPaladin_GiveItem2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_GiveItem2.mp3")
    call ExSound_Register("HeroPaladin_GiveItem3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_GiveItem3.mp3")

    call ExSound_Register("HeroPaladin_Greet1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Greet1.mp3")
    call ExSound_Register("HeroPaladin_Greet2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Greet2.mp3")
    call ExSound_Register("HeroPaladin_Greet3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Greet3.mp3")

    call ExSound_Register("HeroPaladin_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_HoldPositions1.mp3")
    call ExSound_Register("HeroPaladin_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_HoldPositions2.mp3")

    call ExSound_Register("HeroPaladin_Idle1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Idle1.mp3")
    call ExSound_Register("HeroPaladin_Idle2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Idle2.mp3")

    call ExSound_Register("HeroPaladin_Kicked1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Kicked1.mp3")
    call ExSound_Register("HeroPaladin_Kicked2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Kicked2.mp3")

    call ExSound_Register("HeroPaladin_Moving1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Moving1.mp3")
    call ExSound_Register("HeroPaladin_Moving2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Moving2.mp3")
    call ExSound_Register("HeroPaladin_Moving3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Moving3.mp3")

    call ExSound_Register("HeroPaladin_Normal1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Normal1.mp3")
    call ExSound_Register("HeroPaladin_Normal2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Normal2.mp3")
    call ExSound_Register("HeroPaladin_Normal3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Normal3.mp3")

    call ExSound_Register("HeroPaladin_Passive1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Passive1.mp3")
    call ExSound_Register("HeroPaladin_Passive2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Passive2.mp3")
    call ExSound_Register("HeroPaladin_Passive3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_Passive3.mp3")

    call ExSound_Register("HeroPaladin_UnitKilled1", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_UnitKilled1.mp3")
    call ExSound_Register("HeroPaladin_UnitKilled2", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_UnitKilled2.mp3")
    call ExSound_Register("HeroPaladin_UnitKilled3", "Pots\\Sound\\Voicelines\\HeroPaladin\\HeroPaladin_UnitKilled3.mp3")

    call ExSound_Register("HeroPaladin_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatEngineer1.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatEngineer2.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatEngineer3.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatEngineer4.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatEngineer5.mp3")

    call ExSound_Register("HeroPaladin_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral1.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral2.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral3.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral4.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral5.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral6", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral6.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral7", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatGeneral7.mp3")

    call ExSound_Register("HeroPaladin_ChatRogue1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatRogue1.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatRogue2.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatRogue3.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatRogue4.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatRogue5.mp3")

    call ExSound_Register("HeroPaladin_ChatShaman1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatShaman1.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatShaman2.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatShaman3.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatShaman4.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatShaman5.mp3")

    call ExSound_Register("HeroPaladin_ChatWarlock1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarlock1.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarlock2.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarlock3.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarlock4.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarlock5.mp3")

    call ExSound_Register("HeroPaladin_ChatWarrior1", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarrior1.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior2", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarrior2.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior3", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarrior3.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior4", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarrior4.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior5", "Pots\\Sound\\Voicelines\\HeroPaladin\\ChatLines\\HeroPaladin_ChatWarrior5.mp3")


    //=================================================================
    // HeroRestoshaman Event/chat lines  
    call ExSound_Register("HeroRestoshaman_Aggressive1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Aggressive1.mp3")
    call ExSound_Register("HeroRestoshaman_Aggressive2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Aggressive2.mp3")
    call ExSound_Register("HeroRestoshaman_Attacking1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Attacking1.mp3")
    call ExSound_Register("HeroRestoshaman_Attacking2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Attacking2.mp3")
    call ExSound_Register("HeroRestoshaman_Casting1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Casting1.mp3")
    call ExSound_Register("HeroRestoshaman_Casting2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Casting2.mp3")
    call ExSound_Register("HeroRestoshaman_CompanionDies1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_CompanionDies1.mp3")
    call ExSound_Register("HeroRestoshaman_DropItems1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_DropItems1.mp3")
    call ExSound_Register("HeroRestoshaman_DropItems2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_DropItems2.mp3")
    call ExSound_Register("HeroRestoshaman_Farewell1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Farewell1.mp3")
    call ExSound_Register("HeroRestoshaman_Farewell2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Farewell2.mp3")
    call ExSound_Register("HeroRestoshaman_GiveItem1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_GiveItem1.mp3")
    call ExSound_Register("HeroRestoshaman_GiveItem2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_GiveItem2.mp3")
    call ExSound_Register("HeroRestoshaman_Greet1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Greet1.mp3")
    call ExSound_Register("HeroRestoshaman_Greet2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Greet2.mp3")
    call ExSound_Register("HeroRestoshaman_Greet3", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Greet3.mp3")
    call ExSound_Register("HeroRestoshaman_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_HoldPositions1.mp3")
    call ExSound_Register("HeroRestoshaman_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_HoldPositions2.mp3")
    call ExSound_Register("HeroRestoshaman_Idle1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Idle1.mp3")
    call ExSound_Register("HeroRestoshaman_Idle2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Idle2.mp3")
    call ExSound_Register("HeroRestoshaman_Kicked1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Kicked1.mp3")
    call ExSound_Register("HeroRestoshaman_Kicked2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Kicked2.mp3")
    call ExSound_Register("HeroRestoshaman_Moving1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Moving1.mp3")
    call ExSound_Register("HeroRestoshaman_Moving2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Moving2.mp3")
    call ExSound_Register("HeroRestoshaman_Normal1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Normal1.mp3")
    call ExSound_Register("HeroRestoshaman_Normal2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Normal2.mp3")
    call ExSound_Register("HeroRestoshaman_Normal3", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Normal3.mp3")
    call ExSound_Register("HeroRestoshaman_Passive1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Passive1.mp3")
    call ExSound_Register("HeroRestoshaman_Passive2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_Passive2.mp3")
    call ExSound_Register("HeroRestoshaman_UnitDies1", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_UnitDies1.mp3")
    call ExSound_Register("HeroRestoshaman_UnitDies2", "Pots\\Sound\\Voicelines\\HeroShaman\\HeroRestoshaman_UnitDies2.mp3")

    call ExSound_Register("HeroShaman_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatEngineer1.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatEngineer2.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatEngineer3.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatEngineer4.mp3")

    call ExSound_Register("HeroShaman_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral1.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral2.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral3.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral4.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral5.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatGeneral6.mp3")

    call ExSound_Register("HeroShaman_ChatPaladin1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatPaladin1.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatPaladin2.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatPaladin3.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatPaladin4.mp3")

    call ExSound_Register("HeroShaman_ChatRogue1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatRogue1.mp3")
    call ExSound_Register("HeroShaman_ChatRogue2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatRogue2.mp3")
    call ExSound_Register("HeroShaman_ChatRogue3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatRogue3.mp3")
    call ExSound_Register("HeroShaman_ChatRogue4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatRogue4.mp3")
    call ExSound_Register("HeroShaman_ChatRogue5", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatRogue5.mp3")

    call ExSound_Register("HeroShaman_ChatWarlock1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarlock1.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarlock2.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarlock3.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarlock4.mp3")

    call ExSound_Register("HeroShaman_ChatWarrior1", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarrior1.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior2", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarrior2.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior3", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarrior3.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior4", "Pots\\Sound\\Voicelines\\HeroShaman\\ChatLines\\HeroShaman_ChatWarrior4.mp3")
  

    //=================================================================
    // HeroRogue Event/chat lines  
    call ExSound_Register("HeroRogue_Aggressive1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Aggressive1.mp3")
    call ExSound_Register("HeroRogue_Aggressive2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Aggressive2.mp3")
    call ExSound_Register("HeroRogue_Aggressive3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Aggressive3.mp3")

    call ExSound_Register("HeroRogue_Attacking1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Attacking1.mp3")
    call ExSound_Register("HeroRogue_Attacking2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Attacking2.mp3")
    call ExSound_Register("HeroRogue_Attacking3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Attacking3.mp3")

    call ExSound_Register("HeroRogue_Casting1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Casting1.mp3")
    call ExSound_Register("HeroRogue_Casting2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Casting2.mp3")
    call ExSound_Register("HeroRogue_Casting3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Casting3.mp3")

    call ExSound_Register("HeroRogue_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_ChatEngineer1.mp3")

    call ExSound_Register("HeroRogue_DropItems1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_DropItems1.mp3")
    call ExSound_Register("HeroRogue_DropItems2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_DropItems2.mp3")
    call ExSound_Register("HeroRogue_DropItems3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_DropItems3.mp3")

    call ExSound_Register("HeroRogue_Farewell1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Farewell1.mp3")
    call ExSound_Register("HeroRogue_Farewell2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Farewell2.mp3")
    call ExSound_Register("HeroRogue_Farewell3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Farewell3.mp3")
    call ExSound_Register("HeroRogue_Farewell4", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Farewell4.mp3")

    call ExSound_Register("HeroRogue_Greet1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Greet1.mp3")
    call ExSound_Register("HeroRogue_Greet2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Greet2.mp3")
    call ExSound_Register("HeroRogue_Greet3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Greet3.mp3")
    call ExSound_Register("HeroRogue_Greet4", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Greet4.mp3")

    call ExSound_Register("HeroRogue_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_HoldPositions1.mp3")
    call ExSound_Register("HeroRogue_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_HoldPositions2.mp3")

    call ExSound_Register("HeroRogue_Idle1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Idle1.mp3")
    call ExSound_Register("HeroRogue_Idle2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Idle2.mp3")

    call ExSound_Register("HeroRogue_Item1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Item1.mp3")
    call ExSound_Register("HeroRogue_Item2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Item2.mp3")
    call ExSound_Register("HeroRogue_Item3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Item3.mp3")

    call ExSound_Register("HeroRogue_Kicked1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Kicked1.mp3")
    call ExSound_Register("HeroRogue_Kicked2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Kicked2.mp3")
    call ExSound_Register("HeroRogue_Kicked3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Kicked3.mp3")

    call ExSound_Register("HeroRogue_Killing1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Killing1.mp3")
    call ExSound_Register("HeroRogue_Killing2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Killing2.mp3")
    call ExSound_Register("HeroRogue_Killing3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Killing3.mp3")

    call ExSound_Register("HeroRogue_Moving1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Moving1.mp3")
    call ExSound_Register("HeroRogue_Moving2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Moving2.mp3")
    call ExSound_Register("HeroRogue_Moving3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Moving3.mp3")

    call ExSound_Register("HeroRogue_Normal1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Normal1.mp3")
    call ExSound_Register("HeroRogue_Normal2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Normal2.mp3")

    call ExSound_Register("HeroRogue_Passive1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Passive1.mp3")
    call ExSound_Register("HeroRogue_Passive2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_Passive2.mp3")

    call ExSound_Register("HeroRogue_UnitDies1", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_UnitDies1.mp3")
    call ExSound_Register("HeroRogue_UnitDies2", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_UnitDies2.mp3")
    call ExSound_Register("HeroRogue_UnitDies3", "Pots\\Sound\\Voicelines\\HeroRogue\\HeroRogue_UnitDies3.mp3")

    call ExSound_Register("HeroRogue_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatEngineer1.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatEngineer2.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer3", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatEngineer3.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer4", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatEngineer4.mp3")

    call ExSound_Register("HeroRogue_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatGeneral1.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatGeneral2.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatGeneral4.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatGeneral5.mp3")

    call ExSound_Register("HeroRogue_ChatPaladin1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatPaladin1.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatPaladin2.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin3", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatPaladin3.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin5", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatPaladin5.mp3")

    call ExSound_Register("HeroRogue_ChatShaman1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatShaman1.mp3")
    call ExSound_Register("HeroRogue_ChatShaman2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatShaman2.mp3")
    call ExSound_Register("HeroRogue_ChatShaman3", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatShaman3.mp3")
    call ExSound_Register("HeroRogue_ChatShaman4", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatShaman4.mp3")

    call ExSound_Register("HeroRogue_ChatWarlock1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarlock1.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarlock2.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock3", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarlock3.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock4", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarlock4.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock5", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarlock5.mp3")

    call ExSound_Register("HeroRogue_ChatWarrior1", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarrior1.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior2", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarrior2.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior3", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarrior3.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior4", "Pots\\Sound\\Voicelines\\HeroRogue\\ChatOther\\HeroRogue_ChatWarrior4.mp3")

    //=================================================================
    // HeroWarlock Event/chat lines
    call ExSound_Register("HeroWarlock_Aggressive1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Aggressive1.mp3")
    call ExSound_Register("HeroWarlock_Aggressive2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Aggressive2.mp3")
    call ExSound_Register("HeroWarlock_Aggressive3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Aggressive3.mp3")

    call ExSound_Register("HeroWarlock_Attacking1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Attacking1.mp3")
    call ExSound_Register("HeroWarlock_Attacking2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Attacking2.mp3")
    call ExSound_Register("HeroWarlock_Attacking3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Attacking3.mp3")

    call ExSound_Register("HeroWarlock_Casting1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Casting1.mp3")
    call ExSound_Register("HeroWarlock_Casting2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Casting2.mp3")
    call ExSound_Register("HeroWarlock_Casting3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Casting3.mp3")

    call ExSound_Register("HeroWarlock_DropItems1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_DropItems1.mp3")
    call ExSound_Register("HeroWarlock_DropItems2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_DropItems2.mp3")
    call ExSound_Register("HeroWarlock_DropItems3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_DropItems3.mp3")

    call ExSound_Register("HeroWarlock_Farewell1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Farewell1.mp3")
    call ExSound_Register("HeroWarlock_Farewell2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Farewell2.mp3")

    call ExSound_Register("HeroWarlock_Greet1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Greet1.mp3")
    call ExSound_Register("HeroWarlock_Greet2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Greet2.mp3")
    call ExSound_Register("HeroWarlock_Greet3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Greet3.mp3")
    call ExSound_Register("HeroWarlock_Greet4", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Greet4.mp3")

    call ExSound_Register("HeroWarlock_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_HoldPositions1.mp3")
    call ExSound_Register("HeroWarlock_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_HoldPositions2.mp3")

    call ExSound_Register("HeroWarlock_Idle1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Idle1.mp3")
    call ExSound_Register("HeroWarlock_Idle2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Idle2.mp3")

    call ExSound_Register("HeroWarlock_ItemGiven1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_ItemGiven1.mp3")
    call ExSound_Register("HeroWarlock_ItemGiven2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_ItemGiven2.mp3")
    call ExSound_Register("HeroWarlock_ItemGiven3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_ItemGiven3.mp3")
    call ExSound_Register("HeroWarlock_ItemGiven4", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_ItemGiven4.mp3")

    call ExSound_Register("HeroWarlock_Kicked1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Kicked1.mp3")

    call ExSound_Register("HeroWarlock_Killing1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Killing1.mp3")
    call ExSound_Register("HeroWarlock_Killing2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Killing2.mp3")
    call ExSound_Register("HeroWarlock_Killing3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Killing3.mp3")

    call ExSound_Register("HeroWarlock_Moving1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Moving1.mp3")
    call ExSound_Register("HeroWarlock_Moving2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Moving2.mp3")
    call ExSound_Register("HeroWarlock_Moving3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Moving3.mp3")

    call ExSound_Register("HeroWarlock_Normal1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Normal1.mp3")
    call ExSound_Register("HeroWarlock_Normal2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Normal2.mp3")
    call ExSound_Register("HeroWarlock_Normal3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Normal3.mp3")

    call ExSound_Register("HeroWarlock_OtherDies1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_OtherDies1.mp3")
    call ExSound_Register("HeroWarlock_OtherDies2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_OtherDies2.mp3")
    call ExSound_Register("HeroWarlock_OtherDies3", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_OtherDies3.mp3")

    call ExSound_Register("HeroWarlock_Passive1", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Passive1.mp3")
    call ExSound_Register("HeroWarlock_Passive2", "Pots\\Sound\\Voicelines\\HeroWarlock\\HeroWarlock_Passive2.mp3")

    call ExSound_Register("HeroWarlock_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatEngineer1.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatEngineer2.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatEngineer3.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatEngineer4.mp3")

    call ExSound_Register("HeroWarlock_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral1.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral2.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral3.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral4.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral5.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral6.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatGeneral7.mp3")

    call ExSound_Register("HeroWarlock_ChatPaladin1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin1.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin2.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin3.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin4.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin5", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin5.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin6", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatPaladin6.mp3")

    call ExSound_Register("HeroWarlock_ChatRogue1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatRogue1.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatRogue2.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatRogue3.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatRogue4.mp3")

    call ExSound_Register("HeroWarlock_ChatShaman1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatShaman1.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatShaman2.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatShaman3.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatShaman4.mp3")

    call ExSound_Register("HeroWarlock_ChatWarrior1", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatWarrior1.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior2", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatWarrior2.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior3", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatWarrior3.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior4", "Pots\\Sound\\Voicelines\\HeroWarlock\\ChatOther\\HeroWarlock_ChatWarrior4.mp3")

    //=================================================================
    // HeroWarrior Event/chat lines
    call ExSound_Register("HeroWarrior_Aggressive1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Aggressive1.mp3")
    call ExSound_Register("HeroWarrior_Aggressive2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Aggressive2.mp3")

    call ExSound_Register("HeroWarrior_Attack1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Attack1.mp3")
    call ExSound_Register("HeroWarrior_Attack2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Attack2.mp3")

    call ExSound_Register("HeroWarrior_Casting1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Casting1.mp3")
    call ExSound_Register("HeroWarrior_Casting2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Casting2.mp3")

    call ExSound_Register("HeroWarrior_CompanionDies1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_CompanionDies1.mp3")
    call ExSound_Register("HeroWarrior_CompanionDies2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_CompanionDies2.mp3")

    call ExSound_Register("HeroWarrior_DropItems1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_DropItems1.mp3")
    call ExSound_Register("HeroWarrior_DropItems2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_DropItems2.mp3")

    call ExSound_Register("HeroWarrior_Farewell1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Farewell1.mp3")
    call ExSound_Register("HeroWarrior_Farewell2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Farewell2.mp3")

    call ExSound_Register("HeroWarrior_GiveItem1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_GiveItem1.mp3")
    call ExSound_Register("HeroWarrior_GiveItem2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_GiveItem2.mp3")
    call ExSound_Register("HeroWarrior_GiveItem3", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_GiveItem3.mp3")

    call ExSound_Register("HeroWarrior_Greet1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Greet1.mp3")
    call ExSound_Register("HeroWarrior_Greet2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Greet2.mp3")

    call ExSound_Register("HeroWarrior_HoldPositions1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_HoldPositions1.mp3")
    call ExSound_Register("HeroWarrior_HoldPositions2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_HoldPositions2.mp3")

    call ExSound_Register("HeroWarrior_Idle1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Idle1.mp3")
    call ExSound_Register("HeroWarrior_Idle2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Idle2.mp3")

    call ExSound_Register("HeroWarrior_Kicked1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Kicked1.mp3")
    call ExSound_Register("HeroWarrior_Kicked2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Kicked2.mp3")

    call ExSound_Register("HeroWarrior_Moving1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Moving1.mp3")
    call ExSound_Register("HeroWarrior_Moving2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Moving2.mp3")

    call ExSound_Register("HeroWarrior_Normal1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Normal1.mp3")
    call ExSound_Register("HeroWarrior_Normal2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Normal2.mp3")

    call ExSound_Register("HeroWarrior_Passive1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Passive1.mp3")
    call ExSound_Register("HeroWarrior_Passive2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_Passive2.mp3")

    call ExSound_Register("HeroWarrior_UnitDies1", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_UnitDies1.mp3")
    call ExSound_Register("HeroWarrior_UnitDies2", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_UnitDies2.mp3")
    call ExSound_Register("HeroWarrior_UnitDies3", "Pots\\Sound\\Voicelines\\HeroWarrior\\HeroWarrior_UnitDies3.mp3")

    call ExSound_Register("HeroWarrior_ChatEngineer1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatEngineer1.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatEngineer2.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatEngineer3.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatEngineer4.mp3")

    call ExSound_Register("HeroWarrior_ChatGeneral1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral1.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral2.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral3.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral4.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral5.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatGeneral6.mp3")

    call ExSound_Register("HeroWarrior_ChatPaladin1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatPaladin1.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatPaladin2.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatPaladin3.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatPaladin4.mp3")

    call ExSound_Register("HeroWarrior_ChatRogue1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatRogue1.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatRogue2.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatRogue3.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatRogue4.mp3")

    call ExSound_Register("HeroWarrior_ChatShaman1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatShaman1.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatShaman2.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatShaman3.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatShaman4.mp3")

    call ExSound_Register("HeroWarrior_ChatWarlock1", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatWarlock1.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock2", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatWarlock2.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock3", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatWarlock3.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock4", "Pots\\Sound\\Voicelines\\HeroWarrior\\ChatLines\\HeroWarrior_ChatWarlock4.mp3")

    //=================================================================
    // Hero Reply Lines - Engineer
    call ExSound_Register("HeroPaladin_ChatEngineer1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatEngineer1Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatEngineer2Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatEngineer3Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatEngineer4Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatEngineer5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatEngineer5Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatGeneral1Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatGeneral2Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatGeneral3Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatGeneral4Engineer.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroPaladin_ChatGeneral5Engineer.mp3")

    call ExSound_Register("HeroRogue_ChatEngineer1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatEngineer1Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatEngineer2Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatEngineer3Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatEngineer4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatEngineer4Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatGeneral1Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatGeneral2Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatGeneral3Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatGeneral4Engineer.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroRogue_ChatGeneral5Engineer.mp3")

    call ExSound_Register("HeroShaman_ChatEngineer1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatEngineer1Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatEngineer2Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatEngineer3Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatEngineer4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatEngineer4Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral1Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral2Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral3Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral4Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral5Engineer.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroShaman_ChatGeneral6Engineer.mp3")

    call ExSound_Register("HeroWarlock_ChatEngineer1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatEngineer1Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatEngineer2Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatEngineer3Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatEngineer4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatEngineer4Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral1Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral2Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral3Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral4Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral5Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral6Engineer.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarlock_ChatGeneral7Engineer.mp3")

    call ExSound_Register("HeroWarrior_ChatEngineer1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatEngineer1Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatEngineer2Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatEngineer3Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatEngineer4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatEngineer4Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral1Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral1Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral2Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral3Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral4Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral5Engineer.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6Engineer", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroEngineerReplyLines\\HeroWarrior_ChatGeneral6Engineer.mp3")

    //=================================================================
    // Hero Reply Lines - Paladin    
    call ExSound_Register("HeroEngineer_ChatGeneral1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral1Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral2Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral3Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral4Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral5Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral6Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatGeneral7Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatPaladin1Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatPaladin2Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatPaladin3Paladin.mp3")
    call ExSound_Register("HeroEngineer_ChatPaladin4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroEngineer_ChatPaladin4Paladin.mp3")

    call ExSound_Register("HeroRogue_ChatGeneral1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatGeneral1Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatGeneral2Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatGeneral3Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatGeneral4Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatGeneral5Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatPaladin1Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatPaladin2Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatPaladin3Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatPaladin4Paladin.mp3")
    call ExSound_Register("HeroRogue_ChatPaladin5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroRogue_ChatPaladin5Paladin.mp3")

    call ExSound_Register("HeroShaman_ChatGeneral1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral1Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral2Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral3Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral4Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral5Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatGeneral6Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatPaladin1Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatPaladin2Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatPaladin3Paladin.mp3")
    call ExSound_Register("HeroShaman_ChatPaladin4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroShaman_ChatPaladin4Paladin.mp3")

    call ExSound_Register("HeroWarlock_ChatGeneral1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral1Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral2Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral3Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral4Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral5Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral6Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatGeneral7Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin1Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin2Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin3Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin4Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin5Paladin.mp3")
    call ExSound_Register("HeroWarlock_ChatPaladin6Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarlock_ChatPaladin6Paladin.mp3")

    call ExSound_Register("HeroWarrior_ChatGeneral1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral1Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral2Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral3Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral4Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral5Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatGeneral6Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin1Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatPaladin1Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin2Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatPaladin2Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin3Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatPaladin3Paladin.mp3")
    call ExSound_Register("HeroWarrior_ChatPaladin4Paladin", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroPaladinReplyLines\\HeroWarrior_ChatPaladin4Paladin.mp3")

    //=================================================================
    // Hero Reply Lines - Rogue
    call ExSound_Register("HeroEngineer_ChatGeneral1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral1Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral2Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral3Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral4Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral5Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral6Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatGeneral7Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatRogue1Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatRogue2Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatRogue3Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatRogue4Rogue.mp3")
    call ExSound_Register("HeroEngineer_ChatRogue5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroEngineer_ChatRogue5Rogue.mp3")

    call ExSound_Register("HeroPaladin_ChatGeneral1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral1Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral2Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral3Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral4Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral5Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral6Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral6Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral7Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatGeneral7Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatRogue1Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatRogue2Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatRogue3Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatRogue4Rogue.mp3")
    call ExSound_Register("HeroPaladin_ChatRogue5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroPaladin_ChatRogue5Rogue.mp3")

    call ExSound_Register("HeroShaman_ChatGeneral1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral1Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral2Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral3Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral4Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral5Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatGeneral6Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatRogue1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatRogue1Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatRogue2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatRogue2Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatRogue3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatRogue3Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatRogue4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatRogue4Rogue.mp3")
    call ExSound_Register("HeroShaman_ChatRogue5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroShaman_ChatRogue5Rogue.mp3")

    call ExSound_Register("HeroWarlock_ChatGeneral1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral1Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral2Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral3Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral4Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral5Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral6Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatGeneral7Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatRogue1Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatRogue2Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatRogue3Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatRogue4Rogue.mp3")
    call ExSound_Register("HeroWarlock_ChatRogue5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarlock_ChatRogue5Rogue.mp3")

    call ExSound_Register("HeroWarrior_ChatGeneral1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral1Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral2Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral3Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral4Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral5Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatGeneral6Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue1Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatRogue1Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue2Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatRogue2Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue3Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatRogue3Rogue.mp3")
    call ExSound_Register("HeroWarrior_ChatRogue4Rogue", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroRogueReplyLines\\HeroWarrior_ChatRogue4Rogue.mp3")

    //=================================================================
    // Hero Reply Lines - Shaman
    call ExSound_Register("HeroEngineer_ChatGeneral1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral1Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral2Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral3Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral4Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral5Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral6Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatGeneral7Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatShaman1Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatShaman2Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatShaman3Shaman.mp3")
    call ExSound_Register("HeroEngineer_ChatShaman4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroEngineer_ChatShaman4Shaman.mp3")

    call ExSound_Register("HeroPaladin_ChatGeneral1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral1Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral2Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral3Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral4Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral5Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral6Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral6Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral7Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatGeneral7Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatShaman1Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatShaman2Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatShaman3Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatShaman4Shaman.mp3")
    call ExSound_Register("HeroPaladin_ChatShaman5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroPaladin_ChatShaman5Shaman.mp3")

    call ExSound_Register("HeroRogue_ChatGeneral1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatGeneral1Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatGeneral2Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatGeneral3Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatGeneral4Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatGeneral5Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatShaman1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatShaman1Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatShaman2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatShaman2Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatShaman3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatShaman3Shaman.mp3")
    call ExSound_Register("HeroRogue_ChatShaman4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroRogue_ChatShaman4Shaman.mp3")

    call ExSound_Register("HeroWarlock_ChatGeneral1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral1Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral2Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral3Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral4Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral5Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral6Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatGeneral7Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatShaman1Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatShaman2Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatShaman3Shaman.mp3")
    call ExSound_Register("HeroWarlock_ChatShaman4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarlock_ChatShaman4Shaman.mp3")

    call ExSound_Register("HeroWarrior_ChatGeneral1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral1Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral2Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral3Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral4Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral5Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatGeneral6Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman1Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatShaman1Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman2Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatShaman2Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman3Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatShaman3Shaman.mp3")
    call ExSound_Register("HeroWarrior_ChatShaman4Shaman", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroShamanReplyLines\\HeroWarrior_ChatShama43Shaman.mp3")
    
    //=================================================================
    // Hero Reply Lines - Warlock
    call ExSound_Register("HeroEngineer_ChatGeneral1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral1Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral2Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral3Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral4Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral5Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral6Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatGeneral7Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatWarlock1Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatWarlock2Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatWarlock3Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatWarlock4Warlock.mp3")
    call ExSound_Register("HeroEngineer_ChatWarlock5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroEngineer_ChatWarlock5Warlock.mp3")

    call ExSound_Register("HeroPaladin_ChatGeneral1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral1Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral2Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral3Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral4Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral5Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral6Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral6Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral7Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatGeneral7Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatWarlock1Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatWarlock2Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatWarlock3Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatWarlock4Warlock.mp3")
    call ExSound_Register("HeroPaladin_ChatWarlock5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroPaladin_ChatWarlock5Warlock.mp3")

    call ExSound_Register("HeroRogue_ChatGeneral1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatGeneral1Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatGeneral2Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatGeneral3Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatGeneral4Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatGeneral5Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatWarlock1Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatWarlock2Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatWarlock3Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatWarlock4Warlock.mp3")
    call ExSound_Register("HeroRogue_ChatWarlock5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroRogue_ChatWarlock5Warlock.mp3")

    call ExSound_Register("HeroShaman_ChatGeneral1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral1Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral2Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral3Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral4Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral5Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatGeneral6Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatWarlock1Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatWarlock2Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatWarlock3Warlock.mp3")
    call ExSound_Register("HeroShaman_ChatWarlock4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroShaman_ChatWarlock4Warlock.mp3")

    call ExSound_Register("HeroWarrior_ChatGeneral1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral1Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral2Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral3Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral4Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral5Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral5Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatGeneral6Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatGeneral6Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock1Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatWarlock1Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock2Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatWarlock2Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock3Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatWarlock3Warlock.mp3")
    call ExSound_Register("HeroWarrior_ChatWarlock4Warlock", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarlockReplyLines\\HeroWarrior_ChatWarlock4Warlock.mp3")
    
    //=================================================================
    // Hero Reply Lines - Warrior    
    call ExSound_Register("HeroEngineer_ChatGeneral1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral1Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral2Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral3Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral4Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral5Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral6Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral6Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatGeneral7Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatGeneral7Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatWarrior1Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatWarrior2Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatWarrior3Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatWarrior4Warrior.mp3")
    call ExSound_Register("HeroEngineer_ChatWarrior5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroEngineer_ChatWarrior5Warrior.mp3")

    call ExSound_Register("HeroPaladin_ChatGeneral1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral1Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral2Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral3Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral4Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral5Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral6Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral6Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatGeneral7Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatGeneral7Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatWarrior1Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatWarrior2Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatWarrior3Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatWarrior4Warrior.mp3")
    call ExSound_Register("HeroPaladin_ChatWarrior5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroPaladin_ChatWarrior5Warrior.mp3")

    call ExSound_Register("HeroRogue_ChatGeneral1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatGeneral1Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatGeneral2Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatGeneral3Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatGeneral4Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatGeneral5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatGeneral5Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatWarrior1Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatWarrior2Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatWarrior3Warrior.mp3")
    call ExSound_Register("HeroRogue_ChatWarrior4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroRogue_ChatWarrior4Warrior.mp3")

    call ExSound_Register("HeroShaman_ChatGeneral1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral1Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral2Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral3Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral4Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral5Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatGeneral6Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatGeneral6Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatWarrior1Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatWarrior2Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatWarrior3Warrior.mp3")
    call ExSound_Register("HeroShaman_ChatWarrior4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroShaman_ChatWarrior4Warrior.mp3")

    call ExSound_Register("HeroWarlock_ChatGeneral1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral1Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral2Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral3Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral4Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral5Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral5Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral6Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral6Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatGeneral7Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatGeneral7Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior1Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatWarrior1Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior2Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatWarrior2Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior3Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatWarrior3Warrior.mp3")
    call ExSound_Register("HeroWarlock_ChatWarrior4Warrior", "Pots\\Sound\\Voicelines\\HeroReplyLines\\HeroWarriorReplyLines\\HeroWarlock_ChatWarrior4Warrior.mp3")

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
