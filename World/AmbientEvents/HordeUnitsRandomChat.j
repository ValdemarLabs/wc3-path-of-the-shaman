/**
    HordeUnitsRandomChat

    Author: Valdemar
    Version: 1.0.0

    Description:
    Restores the legacy one-shot Orc Grunt conversations at the western
    Horde scout base and southern mountain camp.

    Credits:
    - World/_oldGUI/Horde Units Random Chat

    How to install:
    Import after `AmbientEvents.j` and `Voicelines_OrcGrunt.j`. Keep
    HordeScoutBaseOrcs and HordeMountainCampSouth, then disable the three
    legacy Horde Units Random Chat GUI triggers. Call the mountain-chat API
    when Protect the Outpost completes.

    API:
    - HordeUnitsRandomChat_EnableMountainChat()

**/
library HordeUnitsRandomChat initializer Init requires AmbientEvents, VoicelinesOrcGrunt
    globals
        // Configuration
        private constant integer PLAYER_HORDE = 5
        private constant integer UNIT_ORC_GRUNT = 'ogru'
        private constant string SPEAKER_GRUNT = "Grunt"
        private constant real SCOUT_LINE_DURATION = 4.00
        private constant real MOUNTAIN_GREETING_DURATION = 1.50
        private constant real MOUNTAIN_GREETING_WAIT = 6.00
        private constant real MOUNTAIN_FOLLOWUP_DURATION = 4.00
        private constant real MOUNTAIN_FOLLOWUP_WAIT = 5.00

        private trigger ScoutChatTrigger = null
        private trigger MountainGreetingTrigger = null
        private trigger MountainFollowupTrigger = null
        private timer MountainFollowupEnableTimer = null
        private timer MountainSecondLineTimer = null
        private boolean MountainChatUnlocked = false
    endglobals

    private function PlayGruntLine takes rect sourceRect, string text, string soundKey, real duration returns nothing
        call AmbientEvents_PlayUnitTypeLine(bj_FORCE_ALL_PLAYERS, Player(PLAYER_HORDE), UNIT_ORC_GRUNT, SPEAKER_GRUNT, sourceRect, text, soundKey, duration)
    endfunction

    private function OnMountainSecondLine takes nothing returns nothing
        call PlayGruntLine(gg_rct_HordeMountainCampSouth, VL_ORCGRUNT_0004_TEXT, VL_ORCGRUNT_0004_KEY, MOUNTAIN_FOLLOWUP_DURATION)
    endfunction

    private function OnMountainFollowupEntered takes nothing returns nothing
        call PlayGruntLine(gg_rct_HordeMountainCampSouth, VL_ORCGRUNT_0003_TEXT, VL_ORCGRUNT_0003_KEY, MOUNTAIN_FOLLOWUP_DURATION)
        call TimerStart(MountainSecondLineTimer, MOUNTAIN_FOLLOWUP_DURATION + MOUNTAIN_FOLLOWUP_WAIT, false, function OnMountainSecondLine)
    endfunction

    private function EnableMountainFollowup takes nothing returns nothing
        call AmbientEvents_SetRegionEnterEnabled(MountainFollowupTrigger, true)
    endfunction

    private function OnMountainGreetingEntered takes nothing returns nothing
        call PlayGruntLine(gg_rct_HordeMountainCampSouth, VL_ORCGRUNT_0001_TEXT, VL_ORCGRUNT_0001_KEY, MOUNTAIN_GREETING_DURATION)
        call TimerStart(MountainFollowupEnableTimer, MOUNTAIN_GREETING_DURATION + MOUNTAIN_GREETING_WAIT, false, function EnableMountainFollowup)
    endfunction

    private function OnScoutChatEntered takes nothing returns nothing
        call PlayGruntLine(gg_rct_HordeScoutBaseOrcs, VL_ORCGRUNT_0002_TEXT, VL_ORCGRUNT_0002_KEY, SCOUT_LINE_DURATION)
    endfunction

    public function EnableMountainChat takes nothing returns nothing
        if MountainChatUnlocked then
            return
        endif
        set MountainChatUnlocked = true
        call AmbientEvents_SetRegionEnterEnabled(MountainGreetingTrigger, true)
    endfunction

    private function Init takes nothing returns nothing
        set MountainFollowupEnableTimer = CreateTimer()
        set MountainSecondLineTimer = CreateTimer()
        set ScoutChatTrigger = AmbientEvents_CreateOneShotRegionEnter(gg_rct_HordeScoutBaseOrcs, Player(0), function OnScoutChatEntered, true)
        set MountainGreetingTrigger = AmbientEvents_CreateOneShotRegionEnter(gg_rct_HordeMountainCampSouth, Player(0), function OnMountainGreetingEntered, false)
        set MountainFollowupTrigger = AmbientEvents_CreateOneShotRegionEnter(gg_rct_HordeMountainCampSouth, Player(0), function OnMountainFollowupEntered, false)
    endfunction
endlibrary
