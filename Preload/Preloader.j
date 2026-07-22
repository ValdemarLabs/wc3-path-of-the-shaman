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
    Import after PreloadAbilities.j, ImagesUI.j, ExSound.j, ExMusic.j, and
    StatsLiteUI.j. Disable the old GUI preload triggers so this library owns
    the elapsed-time 0.00 preload flow. Game Start should not also fire from
    its own elapsed-time event; this library executes gg_trg_Game_Start when
    preloading is done. The placed AbilityLoader unit is expected to be
    AbilityLoader 1870 <gen>, generated as gg_unit_h60N_1870. Saved-game
    loading runs sound/music preload only and does not execute Game Start.

    API:
    call Preloader_Start()
    call Preloader_StartLoadedGame()

**/
library Preloader initializer AutoInit requires ImagesUI, ExSound, ExMusic, PreloadAbilities, StatsLiteUI
    globals
        // Timing between visible preload stages. Actual preload calls still run synchronously.
        private constant real PRL_START_MESSAGE_DELAY = 0.50
        private constant real PRL_STAGE_DELAY = 0.50
        private constant real PRL_SOUND_STAGE_DELAY = 1.00
        private constant real PRL_DONE_DELAY = 0.50

        // Imported BLPs can be replaced without touching ImagesUI.j.
        private constant string PRL_IMAGE_START = "war3mapImported\\PreloadStart.blp"
        private constant string PRL_IMAGE_SOUNDS = "war3mapImported\\PreloadSounds.blp"
        private constant string PRL_IMAGE_MUSIC = "war3mapImported\\PreloadMusic.blp"
        private constant string PRL_IMAGE_ABILITIES = "war3mapImported\\PreloadAbilities.blp"
        private constant string PRL_IMAGE_DONE = "war3mapImported\\PreloadDone.blp"

        private trigger PRL_StartTrigger = null
        private trigger PRL_LoadedGameTrigger = null
        private timer PRL_Timer = null
        private integer PRL_Step = 0
        private boolean PRL_Started = false
        private boolean PRL_Finished = false
        private boolean PRL_RunGameStartOnFinish = true
        private boolean PRL_RunAbilityStage = true
        private boolean PRL_DisableUserControl = true
    endglobals

    private function PRL_ShowStatus takes string texturePath, string message returns nothing
        call ImagesUI_ShowPreload(texturePath, message)
        call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, message)
    endfunction

    private function PRL_GetAbilityLoader takes nothing returns unit
        if udg_AbilityPreloader != null and GetUnitTypeId(udg_AbilityPreloader) != 0 then
            return udg_AbilityPreloader
        endif

        return gg_unit_h60N_1870
    endfunction

    private function PRL_PreloadAbilities takes nothing returns nothing
        local unit abilityLoader = PRL_GetAbilityLoader()

        if abilityLoader == null or GetUnitTypeId(abilityLoader) == 0 then
            call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, "|cffff8080Preloader: AbilityLoader 1870 <gen> is missing.|r")
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
            call PRL_ShowStatus(PRL_IMAGE_START, "Preloading files . ...")
            set PRL_Step = 1
            call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 1 then
            call PRL_ShowStatus(PRL_IMAGE_SOUNDS, "==== Sounds")
            call ExSound_PreloadAll()
            set PRL_Step = 2
            call TimerStart(PRL_Timer, PRL_SOUND_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 2 then
            call PRL_ShowStatus(PRL_IMAGE_MUSIC, "==== Music")
            call ExMusic_PreloadAll()
            if PRL_RunAbilityStage then
                set PRL_Step = 3
                call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
            else
                set PRL_Step = 4
                call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
            endif
        elseif PRL_Step == 3 then
            call PRL_ShowStatus(PRL_IMAGE_ABILITIES, "==== Abilities")
            call PRL_PreloadAbilities()
            set PRL_Step = 4
            call TimerStart(PRL_Timer, PRL_STAGE_DELAY, false, function PRL_RunStep)
        elseif PRL_Step == 4 then
            call PRL_ShowStatus(PRL_IMAGE_DONE, "Preload successful.")
            set PRL_Step = 5
            call TimerStart(PRL_Timer, PRL_DONE_DELAY, false, function PRL_RunStep)
        else
            call PRL_Finish()
        endif
    endfunction

    private function PRL_StartMode takes boolean runGameStartOnFinish, boolean runAbilityStage, boolean disableUserControl returns nothing
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
        set PRL_DisableUserControl = disableUserControl

        if PRL_Timer == null then
            set PRL_Timer = CreateTimer()
        endif

        if PRL_DisableUserControl then
            call EnableUserControl(false)
        endif
        call ImagesUI_ShowPreload(PRL_IMAGE_START, "")
        call TimerStart(PRL_Timer, PRL_START_MESSAGE_DELAY, false, function PRL_RunStep)
    endfunction

    public function Start takes nothing returns nothing
        call PRL_StartMode(true, true, true)
    endfunction

    public function StartLoadedGame takes nothing returns nothing
        call PRL_StartMode(false, false, false)
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
