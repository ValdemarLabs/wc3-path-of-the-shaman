library ExMusic initializer Init
//===========================================================================
/*
    ExMusic

    Author: [Valdemar]

    Description:
    A simple external music management system for Warcraft III that allows registering multiple music tracks,
    playing specific tracks, playing random tracks, and cycling through a playlist. It supports mp3 files located in the game's directory.
    The system ensures that only valid tracks are played and manages the current track state.

    API:
        call ExMusic_Init() - Initializes the music system and registers tracks.
        call ExMusic_PlayTrack(index) - Plays the track at the specified index.
        call ExMusic_PlayRandom() - Plays a random track from the registered tracks.
        call ExMusic_PlayNext() - Plays the next track in the playlist, looping back to the start if at the end.
        call ExSMusic_Stop() - Stops the currently playing music.

*/ 
//===========================================================================
// Globals
//=================================================================
globals

    private string array ms_MusicPaths[100]         // array to hold music file paths, // max 100 tracks
    private string ms_TempString = ""               // temporary string for file paths

    private integer ms_MusicCount = 95              // number of registered tracks
    private integer ms_CurrentTrack = -1            // currently playing track index

endglobals
//=================================================================

//=================================================================
// Preload all registered music tracks silently
//=================================================================
function ExMusic_PreloadAll takes nothing returns nothing
    local integer i = 0
    local string track

    call SetMusicVolume(0) // mute music for preload

    loop
        exitwhen i >= ms_MusicCount
        set track = ms_MusicPaths[i]
        if GetSoundFileDuration(track) > 0 then
            call PlayMusic(track)   // briefly plays track at volume 0
            call StopMusic(true)    // immediately stops
        endif
        set i = i + 1
    endloop

    call SetMusicVolume(100) // restore music volume
endfunction

//=================================================================
// Initialize the music system and register tracks
//=================================================================
private function Init takes nothing returns nothing
    // TRACKS
    set ms_MusicPaths[0] = "Pots\\Sound\\Music\\Music_5Orgrimmar.mp3"
    set ms_MusicPaths[1] = "Pots\\Sound\\Music\\Music_8Undercity.mp3"
    set ms_MusicPaths[2] = "Pots\\Sound\\Music\\Music_9Barrens.mp3"
    set ms_MusicPaths[3] = "Pots\\Sound\\Music\\Music_10CursedLandsPlaguelands.mp3"
    set ms_MusicPaths[4] = "Pots\\Sound\\Music\\Music_13EvilForestDuskwood.mp3"
    set ms_MusicPaths[5] = "Pots\\Sound\\Music\\Music_14ForestElwynnForest.mp3"
    set ms_MusicPaths[6] = "Pots\\Sound\\Music\\Music_15Ghost.mp3"
    set ms_MusicPaths[7] = "Pots\\Sound\\Music\\Music_16JungleStranglethornVale.mp3"
    set ms_MusicPaths[8] = "Pots\\Sound\\Music\\Music_17MountainDunMorogh.mp3"
    set ms_MusicPaths[9] = "Pots\\Sound\\Music\\Music_18PlainsWestfall.mp3"
    set ms_MusicPaths[10] = "Pots\\Sound\\Music\\Music_19PvPBattlegrounds.mp3"
    set ms_MusicPaths[11] = "Pots\\Sound\\Music\\Music_20SoggyPlaceDustwallowMarsh.mp3"
    set ms_MusicPaths[12] = "Pots\\Sound\\Music\\Music_21TavernAlliance.mp3"
    set ms_MusicPaths[13] = "Pots\\Sound\\Music\\Music_22TavernHorde.mp3"
    set ms_MusicPaths[14] = "Pots\\Sound\\Music\\Music_23VolcanicBlackrockMountain.mp3"
    set ms_MusicPaths[15] = "Pots\\Sound\\Music\\Music_24Angelic.mp3"
    set ms_MusicPaths[16] = "Pots\\Sound\\Music\\Music_25Gloomy.mp3"
    set ms_MusicPaths[17] = "Pots\\Sound\\Music\\Music_26Haunted.mp3"
    set ms_MusicPaths[18] = "Pots\\Sound\\Music\\Music_27Magic.mp3"
    set ms_MusicPaths[19] = "Pots\\Sound\\Music\\Music_30Spooky.mp3"
    set ms_MusicPaths[20] = "Pots\\Sound\\Music\\Music_34NaxxramasAbominationWing.mp3"
    set ms_MusicPaths[21] = "Pots\\Sound\\Music\\Music_35NaxxramasDeathknightWing.mp3"
    set ms_MusicPaths[22] = "Pots\\Sound\\Music\\Music_38NaxxramasSpiderWing.mp3"
    set ms_MusicPaths[23] = "Pots\\Sound\\Music\\Music_AmbianceRvp21.mp3"
    set ms_MusicPaths[24] = "Pots\\Sound\\Music\\Music_AmbianceRvp212.mp3"
    set ms_MusicPaths[25] = "Pots\\Sound\\Music\\Music_AmbianceRvp213.mp3"
    set ms_MusicPaths[26] = "Pots\\Sound\\Music\\Music_Army01Built.mp3"
    set ms_MusicPaths[27] = "Pots\\Sound\\Music\\Music_Army02Built.mp3"
    set ms_MusicPaths[28] = "Pots\\Sound\\Music\\Music_Bazantar3.mp3"
    set ms_MusicPaths[29] = "Pots\\Sound\\Music\\Music_Bazantartest01.mp3"
    set ms_MusicPaths[30] = "Pots\\Sound\\Music\\Music_Bazantartest2.mp3"
    set ms_MusicPaths[31] = "Pots\\Sound\\Music\\Music_Citadel01Rpvz.mp3"
    set ms_MusicPaths[32] = "Pots\\Sound\\Music\\Music_ClassicCalm.mp3"
    set ms_MusicPaths[33] = "Pots\\Sound\\Music\\Music_CrusaderBattlefield.mp3"
    set ms_MusicPaths[34] = "Pots\\Sound\\Music\\Music_DarkEra01Fairyforest.mp3"
    set ms_MusicPaths[35] = "Pots\\Sound\\Music\\Music_Darktune3.mp3"
    set ms_MusicPaths[36] = "Pots\\Sound\\Music\\Music_DayEvilForest01.mp3"
    set ms_MusicPaths[37] = "Pots\\Sound\\Music\\Music_DemonComingatMoonLight.mp3"
    set ms_MusicPaths[38] = "Pots\\Sound\\Music\\Music_DemoniacMarch.mp3"
    set ms_MusicPaths[39] = "Pots\\Sound\\Music\\Music_DemonNightManipulation.mp3"
    set ms_MusicPaths[40] = "Pots\\Sound\\Music\\Music_DemonTheme1.mp3"
    set ms_MusicPaths[41] = "Pots\\Sound\\Music\\Music_DemonTheme2.mp3"
    set ms_MusicPaths[42] = "Pots\\Sound\\Music\\Music_DemonTheme3.mp3"
    set ms_MusicPaths[43] = "Pots\\Sound\\Music\\Music_EchoesoftheForest.mp3"
    set ms_MusicPaths[44] = "Pots\\Sound\\Music\\Music_EtheraHordeFighter.mp3"
    set ms_MusicPaths[45] = "Pots\\Sound\\Music\\Music_EtherealRealm.mp3"
    set ms_MusicPaths[46] = "Pots\\Sound\\Music\\Music_Fanatism.mp3"
    set ms_MusicPaths[47] = "Pots\\Sound\\Music\\Music_haunted02.mp3"
    set ms_MusicPaths[48] = "Pots\\Sound\\Music\\Music_HerosJourney.mp3"
    set ms_MusicPaths[49] = "Pots\\Sound\\Music\\Music_Humanlands01.mp3"
    set ms_MusicPaths[50] = "Pots\\Sound\\Music\\Music_Humanlands02.mp3"
    set ms_MusicPaths[51] = "Pots\\Sound\\Music\\Music_Humanlands03.mp3"
    set ms_MusicPaths[52] = "Pots\\Sound\\Music\\Music_Humanlands04.mp3"
    set ms_MusicPaths[53] = "Pots\\Sound\\Music\\Music_HumanShort.mp3"
    set ms_MusicPaths[54] = "Pots\\Sound\\Music\\Music_HumanShort2.mp3"
    set ms_MusicPaths[55] = "Pots\\Sound\\Music\\Music_HumanShort3.mp3"
    set ms_MusicPaths[56] = "Pots\\Sound\\Music\\Music_HumanShort4.mp3"
    set ms_MusicPaths[57] = "Pots\\Sound\\Music\\Music_Kontakt01SweetNature.mp3"
    set ms_MusicPaths[58] = "Pots\\Sound\\Music\\Music_Lightamongtreesfemale.mp3"
    set ms_MusicPaths[59] = "Pots\\Sound\\Music\\Music_Majestica07GoodEndFirstEdition.mp3"
    set ms_MusicPaths[60] = "Pots\\Sound\\Music\\Music_MedievalcityWar3Edition.mp3"
    set ms_MusicPaths[61] = "Pots\\Sound\\Music\\Music_NightDesert01.mp3"
    set ms_MusicPaths[62] = "Pots\\Sound\\Music\\Music_NightEvilForest01.mp3"
    set ms_MusicPaths[63] = "Pots\\Sound\\Music\\Music_NightEvilForest03.mp3"
    set ms_MusicPaths[64] = "Pots\\Sound\\Music\\Music_NightForest01.mp3"
    set ms_MusicPaths[65] = "Pots\\Sound\\Music\\Music_Obliviontest.mp3"
    set ms_MusicPaths[66] = "Pots\\Sound\\Music\\Music_OrcFortressAnthem.mp3"
    set ms_MusicPaths[67] = "Pots\\Sound\\Music\\Music_OrcishDay.mp3"
    set ms_MusicPaths[68] = "Pots\\Sound\\Music\\Music_OrcNightThemeWar3.mp3"
    set ms_MusicPaths[69] = "Pots\\Sound\\Music\\Music_OrcPack22.mp3"
    set ms_MusicPaths[70] = "Pots\\Sound\\Music\\Music_OrcPack23.mp3"
    set ms_MusicPaths[71] = "Pots\\Sound\\Music\\Music_OrcPack24.mp3"
    set ms_MusicPaths[72] = "Pots\\Sound\\Music\\Music_Orcshort.mp3"
    set ms_MusicPaths[73] = "Pots\\Sound\\Music\\Music_OrcThemeWar3.mp3"
    set ms_MusicPaths[74] = "Pots\\Sound\\Music\\Music_PastGlory.mp3"
    set ms_MusicPaths[75] = "Pots\\Sound\\Music\\Music_ProjectSilverhand01CelticEra.mp3"
    set ms_MusicPaths[76] = "Pots\\Sound\\Music\\Music_ProjectSilverhand02Action.mp3"
    set ms_MusicPaths[77] = "Pots\\Sound\\Music\\Music_Prometheus01.mp3"
    set ms_MusicPaths[78] = "Pots\\Sound\\Music\\Music_RainAmbianceDream.mp3"
    set ms_MusicPaths[79] = "Pots\\Sound\\Music\\Music_S1InterludeouNight.mp3"
    set ms_MusicPaths[80] = "Pots\\Sound\\Music\\Music_S2MedievalTown.mp3"
    set ms_MusicPaths[81] = "Pots\\Sound\\Music\\Music_S3Peacefulflute.mp3"
    set ms_MusicPaths[82] = "Pots\\Sound\\Music\\Music_S4Lordatvillage.mp3"
    set ms_MusicPaths[83] = "Pots\\Sound\\Music\\Music_S5BigArrivaltest.mp3"
    set ms_MusicPaths[84] = "Pots\\Sound\\Music\\Music_S6UnholyStalker.mp3"
    set ms_MusicPaths[85] = "Pots\\Sound\\Music\\Music_S7UndeadCult.mp3"
    set ms_MusicPaths[86] = "Pots\\Sound\\Music\\Music_S9EvilWill.mp3"
    set ms_MusicPaths[87] = "Pots\\Sound\\Music\\Music_ScarletMarch.mp3"
    set ms_MusicPaths[88] = "Pots\\Sound\\Music\\Music_Short11.mp3"
    set ms_MusicPaths[89] = "Pots\\Sound\\Music\\Music_ShortRvP211Cymbals.mp3"
    set ms_MusicPaths[90] = "Pots\\Sound\\Music\\Music_ShortRvP212Cymbals.mp3"
    set ms_MusicPaths[91] = "Pots\\Sound\\Music\\Music_UndeadAmbience.mp3"
    set ms_MusicPaths[92] = "Pots\\Sound\\Music\\Music_Vikingvillage.mp3"
    set ms_MusicPaths[93] = "Pots\\Sound\\Music\\Music_War3Undeadtemplesacrifice.mp3"
    set ms_MusicPaths[94] = "Pots\\Sound\\Music\\Music_WarlodsShort.mp3"
    
    // Add more tracks as needed, ensuring the paths are correct and files exist + ms_musicCount is updated accordingly

    // preload all musics after 0.0s - Note: done manually in PoTS
    //call TimerStart(CreateTimer(), 0.0, false, function ExMusic_PreloadAll)

    //call BJDebugMsg("ExMusic Initialized")

endfunction

//=================================================================
// Play a track by index
//=================================================================
function ExMusic_PlayTrack takes integer index returns nothing
    if index < 0 or index >= ms_MusicCount then
        return
    endif

    set ms_TempString = ms_MusicPaths[index]
    
    if GetSoundFileDuration(ms_TempString) > 0 then
        call StopMusic(true)
        call PlayMusic(ms_TempString)
        set ms_CurrentTrack = index
    endif

endfunction

//=================================================================
// Play random track
//=================================================================
function ExMusic_PlayRandom takes nothing returns nothing
    local integer r = GetRandomInt(0, ms_MusicCount - 1)
    call ExMusic_PlayTrack(r)

endfunction

//=================================================================
// Play next track in playlist (loops)
//=================================================================
function ExMusic_PlayNext takes nothing returns nothing
    local integer next = ms_CurrentTrack + 1

    if next >= ms_MusicCount then
        set next = 0
    endif
    call ExMusic_PlayTrack(next)

endfunction
//=================================================================
// Stop currently playing music
//=================================================================
function ExSMusic_Stop takes nothing returns nothing
    call StopMusic(true)
    set ms_CurrentTrack = -1

endfunction
//=================================================================
endlibrary
