/**
    Preloader

    Author: Valdemar
    Version:

    Description:
    Asks the player to choose a normal preload or a fast developer check
    immediately after the loading screen. It keeps player start setup from
    being executed until the selected preload stages have completed.

    Credits:

    How to install:
    Import after PreloadAbilities.j, ImagesUI.j, RegionTitlesLight.j,
    ExSound.j, ExMusic.j, StatsLiteUI.j, and GameMode.j. Disable the old GUI
    preload triggers so this library owns the elapsed-time 0.00 preload flow.
    The old Game Start GUI trigger should not also fire from its own
    elapsed-time event; this library shows GameMode when preloading is done.
    GameMode calls Start_Start() after mode and difficulty are selected.
    Ability preloading creates a temporary AbilityLoader unit from
    rawcode 'h60N' and removes it immediately after ability data is loaded.
    Fast developer checks still preload abilities but bypass the sound and
    music preload stages. Saved-game loading repeats those stages only when
    the normal option was selected and never executes player start setup.

    API:
    call Preloader_Start()
    call Preloader_StartLoadedGame()

**/
library Preloader initializer AutoInit requires ImagesUI, RegionTitles, ExSound, ExMusic, PreloadAbilities, StatsLiteUI, FullscreenUI, GameMode
    globals
        // Timing between visible preload stages. Actual preload calls still run synchronously.
        private constant real PRL_START_MESSAGE_DELAY = 5.00
        private constant real PRL_RENDER_DELAY = 1.00
        private constant real PRL_STAGE_DELAY = 5.00
        private constant real PRL_SOUND_STAGE_DELAY = 5.00
        private constant real PRL_DONE_DELAY = 5.00
        private constant real PRL_TITLE_FADE_IN = 0.10
        private constant real PRL_TITLE_DURATION = 5.00
        private constant real PRL_TITLE_FADE_OUT = 0.25

        // Imported BLPs can be replaced without touching ImagesUI.j.
        private constant string PRL_IMAGE_START = "Art\\Pots_EmberpeakHighlands.blp"
        private constant string PRL_IMAGE_SOUNDS = "Art\\Pots_EmberpeakHighlands.blp"
        private constant string PRL_IMAGE_MUSIC = "Art\\Pots_Riverbane1.blp"
        private constant string PRL_IMAGE_ABILITIES = "Art\\Pots_Riverbane1.blp"
        private constant string PRL_IMAGE_DONE = "Art\\Pots_Logo.blp"
        private constant string PRL_TEXT_COLOR = "|cffffffff"
        private constant string PRL_TEXT_HIGHLIGHT = "|cffffcc00"
        private constant string PRL_TEXT_END = "|r"
        private constant integer PRL_CONTROL_PLAYER_ID = 0
        private constant integer PRL_ABILITY_LOADER_UNIT_ID = 'h60N'
        private constant real PRL_ABILITY_LOADER_FACING = 270.00

        private trigger PRL_StartTrigger = null
        private trigger PRL_LoadedGameTrigger = null
        private trigger PRL_ChoiceTrigger = null
        private timer PRL_Timer = null
        private dialog PRL_ChoiceDialog = null
        private button PRL_FastCheckButton = null
        private integer PRL_Step = 0
        private boolean PRL_Started = false
        private boolean PRL_Finished = false
        private boolean PRL_RunGameStartOnFinish = true
        private boolean PRL_RunAbilityStage = true
        private boolean PRL_RunSoundAndMusicStages = true
        private boolean PRL_ChoiceResolved = false
        private boolean PRL_GameUIHidden = false
    endglobals

    private function PRL_BuildPreloadText takes string label returns string
        return PRL_TEXT_HIGHLIGHT + label + PRL_TEXT_END
    endfunction

    private function PRL_ShowStatus takes string texturePath, string message returns nothing
        call ImagesUI_ShowPreload(texturePath, "")
        call ShowPreloadTitle(PRL_TEXT_COLOR + "Preloading..." + PRL_TEXT_END, message, PRL_TITLE_FADE_IN, PRL_TITLE_DURATION, PRL_TITLE_FADE_OUT)
    endfunction

    private function PRL_ShowDoneImage takes nothing returns nothing
        call ImagesUI_ShowPreload(PRL_IMAGE_DONE, "")
        call HidePreloadTitle()
        call ExMusic_PlayTrack(35)
    endfunction

    private function PRL_HideGameUI takes nothing returns nothing
        call FullscreenUI_SetEnabled(true)
        set PRL_GameUIHidden = true
    endfunction

    private function PRL_RestoreGameUI takes nothing returns nothing
        // Keep the game UI fullscreen for now
        // call FullscreenUI_SetEnabled(false)
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

        if PRL_RunGameStartOnFinish then
            // Retain the completed logo beneath GameMode until the run starts.
            call ImagesUI_SetPreloadText("")
            call GameMode_Show()
        else
            call ImagesUI_HidePreload()
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
            if PRL_RunSoundAndMusicStages then
                call PRL_ShowStatus(PRL_IMAGE_SOUNDS, PRL_BuildPreloadText("Sounds"))
                set PRL_Step = 3
                call TimerStart(PRL_Timer, PRL_RENDER_DELAY, false, function PRL_RunStep)
            else
                call PRL_ShowDoneImage()
                set PRL_Step = 7
                call TimerStart(PRL_Timer, PRL_DONE_DELAY, false, function PRL_RunStep)
            endif
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
            call PRL_ShowDoneImage()
            set PRL_Step = 7
            call TimerStart(PRL_Timer, PRL_DONE_DELAY, false, function PRL_RunStep)
        else
            call PRL_Finish()
        endif
    endfunction

    private function PRL_StartMode takes boolean runGameStartOnFinish, boolean runAbilityStage, boolean runSoundAndMusicStages returns nothing
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
        set PRL_RunSoundAndMusicStages = runSoundAndMusicStages

        if PRL_Timer == null then
            set PRL_Timer = CreateTimer()
        endif

        call EnableUserControl(false)
        call PRL_HideGameUI()
        call PRL_ShowStatus(PRL_IMAGE_START, PRL_BuildPreloadText("Files"))
        call TimerStart(PRL_Timer, PRL_START_MESSAGE_DELAY, false, function PRL_RunStep)
    endfunction

    private function PRL_DestroyChoiceDialog takes nothing returns nothing
        if PRL_ChoiceDialog != null then
            call DialogDisplay(Player(PRL_CONTROL_PLAYER_ID), PRL_ChoiceDialog, false)
        endif
        if PRL_ChoiceTrigger != null then
            call DisableTrigger(PRL_ChoiceTrigger)
            call DestroyTrigger(PRL_ChoiceTrigger)
            set PRL_ChoiceTrigger = null
        endif
        if PRL_ChoiceDialog != null then
            call DialogDestroy(PRL_ChoiceDialog)
            set PRL_ChoiceDialog = null
        endif
        set PRL_FastCheckButton = null
    endfunction

    private function PRL_OnPreloadChoice takes nothing returns nothing
        local button clickedButton = GetClickedButton()

        set PRL_RunSoundAndMusicStages = clickedButton != PRL_FastCheckButton
        set PRL_ChoiceResolved = true
        call PRL_DestroyChoiceDialog()
        call PRL_StartMode(true, true, PRL_RunSoundAndMusicStages)

        set clickedButton = null
    endfunction

    private function PRL_ShowPreloadChoice takes nothing returns nothing
        if PRL_ChoiceDialog == null then
            set PRL_ChoiceDialog = DialogCreate()
            set PRL_ChoiceTrigger = CreateTrigger()
            call TriggerRegisterDialogEvent(PRL_ChoiceTrigger, PRL_ChoiceDialog)
            call TriggerAddAction(PRL_ChoiceTrigger, function PRL_OnPreloadChoice)
        endif

        call DialogClear(PRL_ChoiceDialog)
        call DialogSetMessage(PRL_ChoiceDialog, "Choose preload mode")
        call DialogAddButton(PRL_ChoiceDialog, "Normal - preload sounds and music", 0)
        set PRL_FastCheckButton = DialogAddButton(PRL_ChoiceDialog, "Fast check - skip audio preload", 0)
        call DialogDisplay(Player(PRL_CONTROL_PLAYER_ID), PRL_ChoiceDialog, true)
    endfunction

    public function Start takes nothing returns nothing
        if PRL_ChoiceResolved then
            call PRL_StartMode(true, true, PRL_RunSoundAndMusicStages)
        else
            call PRL_ShowPreloadChoice()
        endif
    endfunction

    public function StartLoadedGame takes nothing returns nothing
        if PRL_RunSoundAndMusicStages then
            call PRL_StartMode(false, false, true)
        endif
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
