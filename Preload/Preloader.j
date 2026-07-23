/**
    Preloader

    Author: Valdemar
    Version:

    Description:
    Runs the map preload flow immediately after the loading screen. It keeps
    the intro/game start trigger from being executed until sound, music, and
    ability preloading have completed.

    Credits:

    How to install:
    Import after PreloadAbilities.j, ImagesUI.j, RegionTitlesLight.j,
    ExSound.j, ExMusic.j, and StatsLiteUI.j. Disable the old GUI preload
    triggers so this library owns the elapsed-time 0.00 preload flow. Game
    Start should not also fire from its own elapsed-time event; this library
    executes gg_trg_Game_Start when preloading is done. Ability preloading
    creates a temporary AbilityLoader unit from rawcode 'h60N' and removes it
    immediately after ability data is loaded. Saved-game loading runs
    sound/music preload only and does not execute Game Start.

    API:
    call Preloader_Start()
    call Preloader_StartLoadedGame()

**/
library Preloader initializer AutoInit requires ImagesUI, RegionTitles, ExSound, ExMusic, PreloadAbilities, StatsLiteUI
    globals
        // Timing between visible preload stages. Actual preload calls still run synchronously.
        private constant real PRL_START_MESSAGE_DELAY = 0.50
        private constant real PRL_RENDER_DELAY = 0.10
        private constant real PRL_STAGE_DELAY = 0.50
        private constant real PRL_SOUND_STAGE_DELAY = 1.00
        private constant real PRL_DONE_DELAY = 0.50
        private constant real PRL_TITLE_FADE_IN = 0.10
        private constant real PRL_TITLE_DURATION = 0.70
        private constant real PRL_TITLE_FADE_OUT = 0.25

        // Imported BLPs can be replaced without touching ImagesUI.j.
        private constant string PRL_IMAGE_START = "Art\\Pots_EmberpeakHighlands.blp"
        private constant string PRL_IMAGE_SOUNDS = "Art\\Pots_EmberpeakHighlands.blp"
        private constant string PRL_IMAGE_MUSIC = "Art\\Pots_Riverbane1.blp"
        private constant string PRL_IMAGE_ABILITIES = "Art\\Pots_Riverbane1.blp"
        private constant string PRL_IMAGE_DONE = "Art\\Pots_Logo.blp"
        private constant string PRL_TEXT_COLOR = "|cffffffff"
        private constant string PRL_TEXT_HIGHLIGHT = "|cffffcc00"
        private constant string PRL_TEXT_SUCCESS = "|cff32cd32"
        private constant string PRL_TEXT_END = "|r"
        private constant integer PRL_ABILITY_LOADER_UNIT_ID = 'h60N'
        private constant real PRL_ABILITY_LOADER_FACING = 270.00

        private trigger PRL_StartTrigger = null
        private trigger PRL_LoadedGameTrigger = null
        private timer PRL_Timer = null
        private integer PRL_Step = 0
        private boolean PRL_Started = false
        private boolean PRL_Finished = false
        private boolean PRL_RunGameStartOnFinish = true
        private boolean PRL_RunAbilityStage = true
        private boolean PRL_GameUIHidden = false
    endglobals

    private function PRL_BuildPreloadText takes string label returns string
        return PRL_TEXT_HIGHLIGHT + label + PRL_TEXT_END
    endfunction

    private function PRL_ShowStatus takes string texturePath, string message returns nothing
        call ImagesUI_ShowPreload(texturePath, "")
        call ShowPreloadTitle(PRL_TEXT_COLOR + "Preloading..." + PRL_TEXT_END, message, PRL_TITLE_FADE_IN, PRL_TITLE_DURATION, PRL_TITLE_FADE_OUT)
    endfunction

    private function PRL_ShowDoneStatus takes string texturePath returns nothing
        call ImagesUI_ShowPreload(texturePath, "")
        call ShowPreloadTitle(PRL_TEXT_COLOR + "Preload" + PRL_TEXT_END, PRL_TEXT_SUCCESS + "Successful" + PRL_TEXT_END, PRL_TITLE_FADE_IN, PRL_TITLE_DURATION, PRL_TITLE_FADE_OUT)
    endfunction

    private function PRL_HideGameUI takes nothing returns nothing
        call ShowInterface(false, 0.00)
        call BlzHideCinematicPanels(true)
        set PRL_GameUIHidden = true
    endfunction

    private function PRL_RestoreGameUI takes nothing returns nothing
        call BlzHideCinematicPanels(false)
        call ShowInterface(true, 0.00)
        set PRL_GameUIHidden = false
    endfunction

    private function PRL_CreateAbilityLoader takes nothing returns unit
        local unit abilityLoader = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), PRL_ABILITY_LOADER_UNIT_ID, GetRectCenterX(bj_mapInitialPlayableArea), GetRectCenterY(bj_mapInitialPlayableArea), PRL_ABILITY_LOADER_FACING)

        if abilityLoader != null then
            call PauseUnit(abilityLoader, true)
            call ShowUnit(abilityLoader, false)
        endif

        return abilityLoader
    endfunction

    private function PRL_PreloadAbilities takes nothing returns nothing
        local unit abilityLoader = PRL_CreateAbilityLoader()

        if abilityLoader == null or GetUnitTypeId(abilityLoader) == 0 then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Preloader: Could not create AbilityLoader unit 'h60N'.|r")
        else
            set udg_AbilityPreloader = abilityLoader
            call Preload_Abilities(abilityLoader)
            call RemoveUnit(abilityLoader)
            set udg_AbilityPreloader = null
        endif

        set abilityLoader = null
    endfunction

    private function PRL_Finish takes nothing returns nothing
        set PRL_Finished = true
        if PRL_Timer != null then
            call PauseTimer(PRL_Timer)
        endif

        if PRL_GameUIHidden then
            call PRL_RestoreGameUI()
        endif
        call HidePreloadTitle()
        call ImagesUI_HidePreload()

        if PRL_RunGameStartOnFinish then
            if gg_trg_Game_Start != null then
                call TriggerExecute(gg_trg_Game_Start)
            else
                call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Preloader: gg_trg_Game_Start is missing.|r")
                call EnableUserControl(true)
            endif
        else
            call EnableUserControl(true)
        endif

        if PRL_RunGameStartOnFinish then
            call StatsLiteUI_Init()
        endif
    endfunction

    private function PRL_RunStep takes nothing returns nothing
        if PRL_Finished then
            return
        endif

        if PRL_Step == 0 then
            if PRL_RunAbilityStage then
                call PRL_ShowStatus(PRL_IMAGE_ABILITIES, PRL_BuildPreloadText("Abilities"))
                set PRL_Step = 1
                call TimerStart(PRL_Timer, PRL_RENDER_DELAY, false, function PRL_RunStep)
            else
                set PRL_Step = 2
                call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
            endif
        elseif PRL_Step == 1 then
            call PRL_PreloadAbilities()
            set PRL_Step = 2
            call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 2 then
            call PRL_ShowStatus(PRL_IMAGE_SOUNDS, PRL_BuildPreloadText("Sounds"))
            set PRL_Step = 3
            call TimerStart(PRL_Timer, PRL_RENDER_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 3 then
            call ExSound_PreloadAll()
            set PRL_Step = 4
            call TimerStart(PRL_Timer, PRL_SOUND_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 4 then
            call PRL_ShowStatus(PRL_IMAGE_MUSIC, PRL_BuildPreloadText("Music"))
            set PRL_Step = 5
            call TimerStart(PRL_Timer, PRL_RENDER_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 5 then
            call ExMusic_PreloadAll()
            set PRL_Step = 6
            call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 6 then
            call PRL_ShowDoneStatus(PRL_IMAGE_DONE)
            set PRL_Step = 7
            call TimerStart(PRL_Timer, PRL_DONE_DELAY, false, function PRL_RunStep)
        else
            call PRL_Finish()
        endif
    endfunction

    private function PRL_StartMode takes boolean runGameStartOnFinish, boolean runAbilityStage returns nothing
        if PRL_Started and not PRL_Finished then
            if runGameStartOnFinish then
                return
            endif
            if PRL_Timer != null then
                call PauseTimer(PRL_Timer)
            endif
        endif

        set PRL_Started = true
        set PRL_Finished = false
        set PRL_Step = 0
        set PRL_RunGameStartOnFinish = runGameStartOnFinish
        set PRL_RunAbilityStage = runAbilityStage

        if PRL_Timer == null then
            set PRL_Timer = CreateTimer()
        endif

        call EnableUserControl(false)
        call PRL_HideGameUI()
        call PRL_ShowStatus(PRL_IMAGE_START, PRL_BuildPreloadText("Files"))
        call TimerStart(PRL_Timer, PRL_START_MESSAGE_DELAY, false, function PRL_RunStep)
    endfunction

    public function Start takes nothing returns nothing
        call PRL_StartMode(true, true)
    endfunction

    public function StartLoadedGame takes nothing returns nothing
        call PRL_StartMode(false, false)
    endfunction

    private function PRL_AutoStart takes nothing returns nothing
        call Start()
    endfunction

    private function PRL_OnLoadedGame takes nothing returns nothing
        call StartLoadedGame()
    endfunction

    private function AutoInit takes nothing returns nothing
        set PRL_StartTrigger = CreateTrigger()
        call TriggerRegisterTimerEvent(PRL_StartTrigger, 0.00, false)
        call TriggerAddAction(PRL_StartTrigger, function PRL_AutoStart)

        set PRL_LoadedGameTrigger = CreateTrigger()
        call TriggerRegisterGameEvent(PRL_LoadedGameTrigger, EVENT_GAME_LOADED)
        call TriggerAddAction(PRL_LoadedGameTrigger, function PRL_OnLoadedGame)
    endfunction
endlibrary
