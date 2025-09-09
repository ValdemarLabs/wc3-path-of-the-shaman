library EMS /* v.1.5 */ initializer Init /*
******************************************************************************************
*
*     EMS by Arad MNK
*     https://www.hiveworkshop.com/threads/external-music-system-v-1-5.274585/
*
******************************************************************************************
*
*     EMS
*
*        EMS is the External Music System which is a GUI-Friendly system. You Can
*        use this system both with JASS and GUI (other things are supported too!)
*        You can control the music playing from other external folders with this system.
*
*           Notes:
*            - Changing the .mp3 files in the middle of when system is on is NOT supported.
*            - Only works with .mp3 files. .wav file formats and others are basically avoided.
*
******************************************************************************************
*/
//! novjass

//*      API

        function StartSoundtrack takes string path, string filePrefix returns nothing
//*         - Most important Function. Initializes the system with any GUI event, with the according folder and file prefix.

        function EMSSetVolume takes player p, integer vol returns nothing
//*       - Set a player's music volume to an integer.

        function EMSPlayCustomTrack takes integer track returns boolean
//*         - Play a custom track while the system is running.

        function EMSGetTrackNum takes player p returns integer
//*         - The number of tracks player p has.

        function EMSGetTrackNumLocal takes nothing returns integer
//*         - The number of tracks the player has. It's a local integer.

        function EMSGetCurrentTrack takes nothing returns integer
//*         - Current track running. Local integer.

//! endnovjass

/*
*
*
******************************************************************************************
*
*      Credits
*          Zwiebelchen - He helped me at some critical points. Also the main idea drives from him.
*
******************************************************************************************
*/

    globals
        private integer array TrackNum // Global how many tracks you have.
        private integer TrackNumLocal // Local how many tracks you have.
        private sound array Track // The sound handles of tracks.
        private integer CurrTrackNum // Current track playing number, i.e MusicFolder\Test-CurrTrackNum.mp3
        private boolean Allowed = true // Should the system run or it's not allowed?
        private string SoundtrackFilePrefix = "NULL" // These two NULLs are used in
        private string SoundtrackPath = "NULL"       //   the function Message.
        private timer SystemTimer = CreateTimer()
        private boolean FirstCall = false
    endglobals

//********************************************//
//*************/Message Function/*************//
//********************************************//
    private function Message takes string s returns nothing //Debug messages
        debug call DisplayTextToPlayer(Player(0), 0, 0, "|c00FFFF00EMS:|r " + s + "\n|c00FF0000ID:|r " + SoundtrackPath +" " + SoundtrackFilePrefix)
    endfunction

//*******************************//
//*************/API/*************//
//*******************************//

    function EMSSetVolume takes player p, integer vol returns nothing
        local integer i = 1

        if FirstCall then
            loop
                exitwhen i == TrackNum[GetPlayerId(p)] + 1
                if GetLocalPlayer() == p then
                    call SetSoundVolume(Track[i], vol)
                endif
                set i = i + 1
            endloop
        
            call Message("New Volume: " + I2S(vol))
        else
            call Message("System is not initialized for the first time yet...")
        endif
    endfunction

    function EMSPlayCustomTrack takes integer track returns boolean //The boolean means that the track exists or not
        local boolean b = track <= TrackNumLocal and FirstCall

        if b then
            set Allowed = false //Does not allow the core to detect the stopped sound and restart
            call StopSound(Track[CurrTrackNum], false, false)
            call Message("Custom Track Playing: " + I2S(track))
            set CurrTrackNum = track - 1
            call StartSound(Track[CurrTrackNum])
            set Allowed = true
        else
            call Message("Invalid Track.")
        endif

        return b
    endfunction

    function EMSGetTrackNum takes player p returns integer
        if FirstCall then
            return TrackNum[GetPlayerId(p)]
        else
            call Message("System is not initialized for the first time yet...")
            return 0
        endif
    endfunction

    function EMSGetTrackNumLocal takes nothing returns integer
        if FirstCall then
            return TrackNumLocal
        else
            call Message("System is not initialized for the first time yet...")
            return 0
        endif
    endfunction

    function EMSGetCurrentTrack takes nothing returns integer
        if FirstCall then
            return CurrTrackNum
        else
            call Message("System is not initialized for the first time yet...")
            return 0
        endif
    endfunction

//*********************************************************//
//*************/Functions used by the system./*************//
//*********************************************************//

    private function CreateTrackLocation takes integer i returns string
        local string s
        local string smsg

        if udg_MS_Use0 and i < 10 then
            set s = "0"
        else
            set s = ""
        endif

        set smsg = SoundtrackPath + "\\" + SoundtrackFilePrefix + "-" + s + I2S(i) + ".mp3"
        call Message("Track path generated: " + smsg)
        set s = null

        return smsg
    endfunction
    
    private function NumOfTracksLocal takes nothing returns integer
        local integer i = 1
        local integer i2 = 1

        loop
            exitwhen i != i2
            if GetSoundFileDuration(CreateTrackLocation(i)) > 0 then
                set i2 = i2 + 1
            endif
            set i = i + 1
        endloop

        return i2 - 1
    endfunction

    private function NumOfTracksLimitLocal takes integer limit returns integer
        local integer i = 1
        local integer i2 = 1

        loop
            exitwhen i == udg_MS_ForLoop or i != i2
            if GetSoundFileDuration(CreateTrackLocation(i)) > 0 then
                set i2 = i2 + 1
            endif
            set i = i + 1
        endloop

        return i2 - 1
    endfunction

    private function NumOfTracks takes player p returns integer
        local integer i = 1
        local integer i2 = 1

        loop
            exitwhen i != i2
            if GetLocalPlayer() == p then
            if GetSoundFileDuration(CreateTrackLocation(i)) > 0 then
                set i2 = i2 + 1
            endif
            endif
            set i = i + 1
        endloop
            return i2 - 1
    endfunction
    
    private function NumOfTracksLimit takes player p, integer limit returns integer
        local integer i = 1
        local integer i2 = 1
        loop
            exitwhen i == udg_MS_ForLoop or i != i2
            if GetLocalPlayer() == p then
            if GetSoundFileDuration(CreateTrackLocation(i)) > 0 then
                set i2 = i2 + 1
            endif
            endif
            set i = i + 1
        endloop

        return i2 - 1
    endfunction

    private function Core takes nothing returns nothing
        if not(GetSoundIsLoading(Track[CurrTrackNum]) or GetSoundIsPlaying(Track[CurrTrackNum])) and Allowed then
            call StopSound(Track[CurrTrackNum], false, false)
            if udg_MS_PlayingIsRandom then
                set CurrTrackNum = GetRandomInt(1, TrackNumLocal)
                call Message("Random Track: " + I2S(CurrTrackNum))
            else
                if CurrTrackNum != TrackNumLocal + 1 then
                    set CurrTrackNum = CurrTrackNum + 1
                elseif CurrTrackNum == TrackNumLocal + 1 then
                    set CurrTrackNum = 1 //start from beginning
                endif
            call Message("Next Track: " + I2S(CurrTrackNum))
            endif
            call StartSound(Track[CurrTrackNum])
        endif
    endfunction

    private function Init takes nothing returns nothing
        call Message("Initialized.\nDebug mode is on.")
    endfunction

//****************************************************************************//
//*************/Most Important user function, starts the system./*************//
//****************************************************************************//

    function StartSoundtrack takes string path, string filePrefix returns nothing
        local integer i = 1

        set Allowed = false
        set SoundtrackPath = path
        set SoundtrackFilePrefix = filePrefix

        if FirstCall then
            call Message("Not first call, Stopping music.")
            call Message("Track stopped: " + I2S(CurrTrackNum))
            call StopSound(Track[CurrTrackNum], false, false) //Stopping the music playing if called when a soundtrack is on

            loop
                exitwhen i == TrackNumLocal
                call KillSoundWhenDone(Track[i])
                call Message("Track destroyed. Track Number:" + I2S(i))
                set i = i + 1
            endloop
        else
            set FirstCall = true
            call Message("First call.")
        endif

        set CurrTrackNum = 1
        set i = 1
        call Message("Starting soundtrack: " + path + "\\" + filePrefix)

        if udg_MS_ForLoop == 0 then
            set TrackNumLocal = NumOfTracksLocal()
        elseif udg_MS_ForLoop > 0 then
            set TrackNumLocal = NumOfTracksLimitLocal(udg_MS_ForLoop)
        endif

        loop
            exitwhen i == TrackNumLocal
            set Track[i] = CreateSound(CreateTrackLocation(i), false, false, false, 12700, 12700, "")
            call Message("Track created. Track Number:" + I2S(i))
            set i = i + 1
        endloop

        call StartSound(Track[1])
        call TimerStart(SystemTimer, 1 / udg_MS_Timeout, true, function Core)
        set Allowed = true
    endfunction
endlibrary