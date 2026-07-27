/**
    GameMode

    Author: Valdemar
    Version:

    Description:
    Shows the pre-start game mode and difficulty selection UI. The selected
    mode is stored as startup configuration for story, free roam, and developer
    flows before Start_Start() begins the player start phases.

    Credits:

    How to install:
    Import before Preloader.j and after Difficulty.j, Start.j, and Interface.j.
    Preloader.j calls GameMode_Show() after preload; this library applies the
    selected difficulty and then calls Start_Start().

    API:
    call GameMode_Show()
    call GameMode_Hide()
    call GameMode_GetMode()
    call GameMode_GetDifficulty()
    call GameMode_IsStoryEnabled()
    call GameMode_IsDeveloperMode()
    call GameMode_AreAllQuestsAvailableOnStart()
    call GameMode_AreAbilityRequirementsEnabled()

**/
library GameMode initializer AutoInit requires Difficulty, Start, Interface
    globals
        constant integer GAME_MODE_STORY = 1
        constant integer GAME_MODE_FREE_ROAM = 2
        constant integer GAME_MODE_DEVELOPER = 3

        constant integer GAME_MODE_QUEST_REVEAL_NORMAL = 0
        constant integer GAME_MODE_QUEST_REVEAL_AVAILABLE = 1
        constant integer GAME_MODE_QUEST_REVEAL_ALL = 2

        // Configuration
        // Set false for release builds when developer mode should not be visible.
        private constant boolean GM_SHOW_DEVELOPER_MODE = true

        private constant boolean GM_STORY_STORY_ENABLED = true
        private constant boolean GM_STORY_RUN_INTRO_CINEMATIC = true
        private constant boolean GM_STORY_QUEST_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_QUEST_LEVEL_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_QUEST_REPUTATION_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_QUEST_EVENT_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_QUEST_CUSTOM_CONDITIONS_ENABLED = true
        private constant boolean GM_STORY_ALL_QUESTS_AVAILABLE_ON_START = false
        private constant boolean GM_STORY_ABILITY_REQUIREMENTS_ENABLED = true
        private constant boolean GM_STORY_ABILITY_PREREQUISITES_ENABLED = true
        private constant boolean GM_STORY_ABILITY_QUEST_LOCKS_ENABLED = true
        private constant boolean GM_STORY_ABILITY_POINT_COSTS_ENABLED = true
        private constant integer GM_STORY_QUEST_REVEAL_MODE = GAME_MODE_QUEST_REVEAL_NORMAL
        private constant integer GM_STORY_STARTING_GOLD_BONUS = 0

        private constant boolean GM_FREE_ROAM_STORY_ENABLED = false
        private constant boolean GM_FREE_ROAM_RUN_INTRO_CINEMATIC = false
        private constant boolean GM_FREE_ROAM_QUEST_REQUIREMENTS_ENABLED = true
        private constant boolean GM_FREE_ROAM_QUEST_LEVEL_REQUIREMENTS_ENABLED = true
        private constant boolean GM_FREE_ROAM_QUEST_REPUTATION_REQUIREMENTS_ENABLED = true
        private constant boolean GM_FREE_ROAM_QUEST_EVENT_REQUIREMENTS_ENABLED = false
        private constant boolean GM_FREE_ROAM_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED = false
        private constant boolean GM_FREE_ROAM_QUEST_CUSTOM_CONDITIONS_ENABLED = false
        private constant boolean GM_FREE_ROAM_ALL_QUESTS_AVAILABLE_ON_START = false
        private constant boolean GM_FREE_ROAM_ABILITY_REQUIREMENTS_ENABLED = true
        private constant boolean GM_FREE_ROAM_ABILITY_PREREQUISITES_ENABLED = true
        private constant boolean GM_FREE_ROAM_ABILITY_QUEST_LOCKS_ENABLED = false
        private constant boolean GM_FREE_ROAM_ABILITY_POINT_COSTS_ENABLED = true
        private constant integer GM_FREE_ROAM_QUEST_REVEAL_MODE = GAME_MODE_QUEST_REVEAL_AVAILABLE
        private constant integer GM_FREE_ROAM_STARTING_GOLD_BONUS = 0

        private constant boolean GM_DEVELOPER_STORY_ENABLED = false
        private constant boolean GM_DEVELOPER_RUN_INTRO_CINEMATIC = false
        private constant boolean GM_DEVELOPER_QUEST_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_QUEST_LEVEL_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_QUEST_REPUTATION_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_QUEST_EVENT_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_QUEST_CUSTOM_CONDITIONS_ENABLED = false
        private constant boolean GM_DEVELOPER_ALL_QUESTS_AVAILABLE_ON_START = true
        private constant boolean GM_DEVELOPER_ABILITY_REQUIREMENTS_ENABLED = false
        private constant boolean GM_DEVELOPER_ABILITY_PREREQUISITES_ENABLED = false
        private constant boolean GM_DEVELOPER_ABILITY_QUEST_LOCKS_ENABLED = false
        private constant boolean GM_DEVELOPER_ABILITY_POINT_COSTS_ENABLED = false
        private constant integer GM_DEVELOPER_QUEST_REVEAL_MODE = GAME_MODE_QUEST_REVEAL_ALL
        private constant integer GM_DEVELOPER_STARTING_GOLD_BONUS = 0

        private constant real GM_PANEL_LEFT = 0.170
        private constant real GM_PANEL_RIGHT = 0.630
        private constant real GM_PANEL_TOP = 0.520
        private constant real GM_PANEL_BOTTOM = 0.185
        private constant real GM_BUTTON_WIDTH = 0.135
        private constant real GM_BUTTON_HEIGHT = 0.034

        // Runtime state
        private boolean GM_Initialized = false
        private boolean GM_Visible = false
        private integer GM_SelectedMode = GAME_MODE_STORY
        private integer GM_SelectedDifficulty = DIFFICULTY_NORMAL
        private boolean GM_StoryEnabled = GM_STORY_STORY_ENABLED
        private boolean GM_RunIntroCinematic = GM_STORY_RUN_INTRO_CINEMATIC
        private boolean GM_QuestRequirementsEnabled = GM_STORY_QUEST_REQUIREMENTS_ENABLED
        private boolean GM_QuestLevelRequirementsEnabled = GM_STORY_QUEST_LEVEL_REQUIREMENTS_ENABLED
        private boolean GM_QuestReputationRequirementsEnabled = GM_STORY_QUEST_REPUTATION_REQUIREMENTS_ENABLED
        private boolean GM_QuestEventRequirementsEnabled = GM_STORY_QUEST_EVENT_REQUIREMENTS_ENABLED
        private boolean GM_QuestPrerequisiteRequirementsEnabled = GM_STORY_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED
        private boolean GM_QuestCustomConditionsEnabled = GM_STORY_QUEST_CUSTOM_CONDITIONS_ENABLED
        private boolean GM_AllQuestsAvailableOnStart = GM_STORY_ALL_QUESTS_AVAILABLE_ON_START
        private boolean GM_AbilityRequirementsEnabled = GM_STORY_ABILITY_REQUIREMENTS_ENABLED
        private boolean GM_AbilityPrerequisitesEnabled = GM_STORY_ABILITY_PREREQUISITES_ENABLED
        private boolean GM_AbilityQuestLocksEnabled = GM_STORY_ABILITY_QUEST_LOCKS_ENABLED
        private boolean GM_AbilityPointCostsEnabled = GM_STORY_ABILITY_POINT_COSTS_ENABLED
        private integer GM_QuestRevealMode = GM_STORY_QUEST_REVEAL_MODE
        private integer GM_StartingGoldBonus = GM_STORY_STARTING_GOLD_BONUS

        private framehandle GM_Parent = null
        private framehandle GM_Title = null
        private framehandle GM_Body = null
        private framehandle GM_Footer = null
        private framehandle GM_BackButton = null
        private framehandle array GM_ModeButton
        private framehandle array GM_DifficultyButton

        private trigger GM_ModeTrigger = null
        private trigger GM_DifficultyTrigger = null
        private trigger GM_BackTrigger = null
        private trigger GM_ClearFocusTrigger = null
    endglobals

    private function GM_SetFrameVisible takes framehandle frame, boolean visible returns nothing
        if frame != null then
            call BlzFrameSetVisible(frame, visible)
        endif
    endfunction

    private function GM_SetModeButtonsVisible takes boolean visible returns nothing
        call GM_SetFrameVisible(GM_ModeButton[GAME_MODE_STORY], visible)
        call GM_SetFrameVisible(GM_ModeButton[GAME_MODE_FREE_ROAM], visible)
        call GM_SetFrameVisible(GM_ModeButton[GAME_MODE_DEVELOPER], visible and GM_SHOW_DEVELOPER_MODE)
    endfunction

    private function GM_SetDifficultyButtonsVisible takes boolean visible returns nothing
        call GM_SetFrameVisible(GM_DifficultyButton[DIFFICULTY_STORY], visible)
        call GM_SetFrameVisible(GM_DifficultyButton[DIFFICULTY_NORMAL], visible)
        call GM_SetFrameVisible(GM_DifficultyButton[DIFFICULTY_HARD], visible)
        call GM_SetFrameVisible(GM_BackButton, visible)
    endfunction

    private function GM_SetStoryConfig takes nothing returns nothing
        set GM_StoryEnabled = GM_STORY_STORY_ENABLED
        set GM_RunIntroCinematic = GM_STORY_RUN_INTRO_CINEMATIC
        set GM_QuestRequirementsEnabled = GM_STORY_QUEST_REQUIREMENTS_ENABLED
        set GM_QuestLevelRequirementsEnabled = GM_STORY_QUEST_LEVEL_REQUIREMENTS_ENABLED
        set GM_QuestReputationRequirementsEnabled = GM_STORY_QUEST_REPUTATION_REQUIREMENTS_ENABLED
        set GM_QuestEventRequirementsEnabled = GM_STORY_QUEST_EVENT_REQUIREMENTS_ENABLED
        set GM_QuestPrerequisiteRequirementsEnabled = GM_STORY_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED
        set GM_QuestCustomConditionsEnabled = GM_STORY_QUEST_CUSTOM_CONDITIONS_ENABLED
        set GM_AllQuestsAvailableOnStart = GM_STORY_ALL_QUESTS_AVAILABLE_ON_START
        set GM_AbilityRequirementsEnabled = GM_STORY_ABILITY_REQUIREMENTS_ENABLED
        set GM_AbilityPrerequisitesEnabled = GM_STORY_ABILITY_PREREQUISITES_ENABLED
        set GM_AbilityQuestLocksEnabled = GM_STORY_ABILITY_QUEST_LOCKS_ENABLED
        set GM_AbilityPointCostsEnabled = GM_STORY_ABILITY_POINT_COSTS_ENABLED
        set GM_QuestRevealMode = GM_STORY_QUEST_REVEAL_MODE
        set GM_StartingGoldBonus = GM_STORY_STARTING_GOLD_BONUS
    endfunction

    private function GM_SetFreeRoamConfig takes nothing returns nothing
        set GM_StoryEnabled = GM_FREE_ROAM_STORY_ENABLED
        set GM_RunIntroCinematic = GM_FREE_ROAM_RUN_INTRO_CINEMATIC
        set GM_QuestRequirementsEnabled = GM_FREE_ROAM_QUEST_REQUIREMENTS_ENABLED
        set GM_QuestLevelRequirementsEnabled = GM_FREE_ROAM_QUEST_LEVEL_REQUIREMENTS_ENABLED
        set GM_QuestReputationRequirementsEnabled = GM_FREE_ROAM_QUEST_REPUTATION_REQUIREMENTS_ENABLED
        set GM_QuestEventRequirementsEnabled = GM_FREE_ROAM_QUEST_EVENT_REQUIREMENTS_ENABLED
        set GM_QuestPrerequisiteRequirementsEnabled = GM_FREE_ROAM_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED
        set GM_QuestCustomConditionsEnabled = GM_FREE_ROAM_QUEST_CUSTOM_CONDITIONS_ENABLED
        set GM_AllQuestsAvailableOnStart = GM_FREE_ROAM_ALL_QUESTS_AVAILABLE_ON_START
        set GM_AbilityRequirementsEnabled = GM_FREE_ROAM_ABILITY_REQUIREMENTS_ENABLED
        set GM_AbilityPrerequisitesEnabled = GM_FREE_ROAM_ABILITY_PREREQUISITES_ENABLED
        set GM_AbilityQuestLocksEnabled = GM_FREE_ROAM_ABILITY_QUEST_LOCKS_ENABLED
        set GM_AbilityPointCostsEnabled = GM_FREE_ROAM_ABILITY_POINT_COSTS_ENABLED
        set GM_QuestRevealMode = GM_FREE_ROAM_QUEST_REVEAL_MODE
        set GM_StartingGoldBonus = GM_FREE_ROAM_STARTING_GOLD_BONUS
    endfunction

    private function GM_SetDeveloperConfig takes nothing returns nothing
        set GM_StoryEnabled = GM_DEVELOPER_STORY_ENABLED
        set GM_RunIntroCinematic = GM_DEVELOPER_RUN_INTRO_CINEMATIC
        set GM_QuestRequirementsEnabled = GM_DEVELOPER_QUEST_REQUIREMENTS_ENABLED
        set GM_QuestLevelRequirementsEnabled = GM_DEVELOPER_QUEST_LEVEL_REQUIREMENTS_ENABLED
        set GM_QuestReputationRequirementsEnabled = GM_DEVELOPER_QUEST_REPUTATION_REQUIREMENTS_ENABLED
        set GM_QuestEventRequirementsEnabled = GM_DEVELOPER_QUEST_EVENT_REQUIREMENTS_ENABLED
        set GM_QuestPrerequisiteRequirementsEnabled = GM_DEVELOPER_QUEST_PREREQUISITE_REQUIREMENTS_ENABLED
        set GM_QuestCustomConditionsEnabled = GM_DEVELOPER_QUEST_CUSTOM_CONDITIONS_ENABLED
        set GM_AllQuestsAvailableOnStart = GM_DEVELOPER_ALL_QUESTS_AVAILABLE_ON_START
        set GM_AbilityRequirementsEnabled = GM_DEVELOPER_ABILITY_REQUIREMENTS_ENABLED
        set GM_AbilityPrerequisitesEnabled = GM_DEVELOPER_ABILITY_PREREQUISITES_ENABLED
        set GM_AbilityQuestLocksEnabled = GM_DEVELOPER_ABILITY_QUEST_LOCKS_ENABLED
        set GM_AbilityPointCostsEnabled = GM_DEVELOPER_ABILITY_POINT_COSTS_ENABLED
        set GM_QuestRevealMode = GM_DEVELOPER_QUEST_REVEAL_MODE
        set GM_StartingGoldBonus = GM_DEVELOPER_STARTING_GOLD_BONUS
    endfunction

    private function GM_ApplyModeConfig takes integer mode returns nothing
        set GM_SelectedMode = mode
        if mode == GAME_MODE_FREE_ROAM then
            call GM_SetFreeRoamConfig()
        elseif mode == GAME_MODE_DEVELOPER then
            call GM_SetDeveloperConfig()
        else
            call GM_SetStoryConfig()
        endif
    endfunction

    private function GM_ShowModeView takes nothing returns nothing
        if GM_Parent == null then
            return
        endif
        call BlzFrameSetText(GM_Title, "|cffffe4a3Game Mode|r")
        call BlzFrameSetText(GM_Body, "|cffffcc00Story|r|nNormal quest and story progression.|n|n|cffffcc00Free Roam|r|nExploration setup with story gates disabled.|n|n|cffffcc00Developer|r|nTesting setup with quest and ability requirements disabled.")
        call BlzFrameSetText(GM_Footer, "|cffbfbfbfSelect how the run should start.|r")
        call GM_SetDifficultyButtonsVisible(false)
        call GM_SetModeButtonsVisible(true)
    endfunction

    private function GM_ShowDifficultyView takes nothing returns nothing
        if GM_Parent == null then
            return
        endif
        call BlzFrameSetText(GM_Title, "|cffffe4a3Difficulty|r")
        call BlzFrameSetText(GM_Body, "|cffffcc00Story|r|nLower enemy pressure and easier progression profile.|n|n|cffffcc00Normal|r|nDefault combat and reward profile.|n|n|cffffcc00Hard|r|nStronger hostile units and stricter reward profile.")
        call BlzFrameSetText(GM_Footer, "|cffbfbfbfDifficulty is applied through Difficulty.j before player start.|r")
        call GM_SetModeButtonsVisible(false)
        call GM_SetDifficultyButtonsVisible(true)
    endfunction

    private function GM_HideInternal takes nothing returns nothing
        if GM_Parent != null and BlzFrameIsVisible(GM_Parent) then
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, Player(0))
        endif
        call GM_SetFrameVisible(GM_Parent, false)
        set GM_Visible = false
    endfunction

    private function GM_ClearFocusAction takes nothing returns nothing
        if GetTriggerPlayer() == GetLocalPlayer() then
            call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
            call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
            call StopCamera()
        endif
    endfunction

    private function GM_BackAction takes nothing returns nothing
        if GetTriggerPlayer() != Player(0) then
            return
        endif
        call Interface_PlayEventSoundForPlayer(Interface_EVENT_CANCEL, GetTriggerPlayer())
        call GM_ShowModeView()
    endfunction

    private function GM_ModeAction takes nothing returns nothing
        local framehandle clicked = BlzGetTriggerFrame()
        local player triggerPlayer = GetTriggerPlayer()

        if triggerPlayer != Player(0) then
            set clicked = null
            set triggerPlayer = null
            return
        endif

        if clicked == GM_ModeButton[GAME_MODE_FREE_ROAM] then
            call GM_ApplyModeConfig(GAME_MODE_FREE_ROAM)
        elseif clicked == GM_ModeButton[GAME_MODE_DEVELOPER] and GM_SHOW_DEVELOPER_MODE then
            call GM_ApplyModeConfig(GAME_MODE_DEVELOPER)
        else
            call GM_ApplyModeConfig(GAME_MODE_STORY)
        endif

        call Interface_PlayEventSoundForPlayer(Interface_EVENT_BUTTON_CLICK, triggerPlayer)
        call GM_ShowDifficultyView()

        set clicked = null
        set triggerPlayer = null
    endfunction

    private function GM_StartSelectedMode takes integer difficulty returns nothing
        set GM_SelectedDifficulty = difficulty
        call Difficulty_SetDifficulty(difficulty)
        call Start_SetRunIntroCinematic(GM_RunIntroCinematic)
        call Start_SetStartingGoldBonus(GM_StartingGoldBonus)
        call GM_HideInternal()
        call EnableUserControl(false)
        call Start_Start()
    endfunction

    private function GM_DifficultyAction takes nothing returns nothing
        local framehandle clicked = BlzGetTriggerFrame()
        local player triggerPlayer = GetTriggerPlayer()

        if triggerPlayer != Player(0) then
            set clicked = null
            set triggerPlayer = null
            return
        endif

        call Interface_PlayEventSoundForPlayer(Interface_EVENT_CONFIRM, triggerPlayer)
        if clicked == GM_DifficultyButton[DIFFICULTY_STORY] then
            call GM_StartSelectedMode(DIFFICULTY_STORY)
        elseif clicked == GM_DifficultyButton[DIFFICULTY_HARD] then
            call GM_StartSelectedMode(DIFFICULTY_HARD)
        else
            call GM_StartSelectedMode(DIFFICULTY_NORMAL)
        endif

        set clicked = null
        set triggerPlayer = null
    endfunction

    private function GM_CreateModeButton takes integer index, string label, real x returns nothing
        set GM_ModeButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "GameModeModeButton" + I2S(index), GM_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(GM_ModeButton[index], GM_BUTTON_WIDTH, GM_BUTTON_HEIGHT)
        call BlzFrameSetPoint(GM_ModeButton[index], FRAMEPOINT_BOTTOMLEFT, GM_Parent, FRAMEPOINT_BOTTOMLEFT, x, 0.060)
        call BlzFrameSetText(GM_ModeButton[index], label)
        call BlzTriggerRegisterFrameEvent(GM_ModeTrigger, GM_ModeButton[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GM_ClearFocusTrigger, GM_ModeButton[index], FRAMEEVENT_CONTROL_CLICK)
    endfunction

    private function GM_CreateDifficultyButton takes integer index, string label, real x returns nothing
        set GM_DifficultyButton[index] = BlzCreateFrameByType("GLUETEXTBUTTON", "GameModeDifficultyButton" + I2S(index), GM_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(GM_DifficultyButton[index], GM_BUTTON_WIDTH, GM_BUTTON_HEIGHT)
        call BlzFrameSetPoint(GM_DifficultyButton[index], FRAMEPOINT_BOTTOMLEFT, GM_Parent, FRAMEPOINT_BOTTOMLEFT, x, 0.060)
        call BlzFrameSetText(GM_DifficultyButton[index], label)
        call BlzTriggerRegisterFrameEvent(GM_DifficultyTrigger, GM_DifficultyButton[index], FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GM_ClearFocusTrigger, GM_DifficultyButton[index], FRAMEEVENT_CONTROL_CLICK)
    endfunction

    private function GM_CreateFrames takes nothing returns nothing
        set GM_Parent = BlzCreateFrameByType("BACKDROP", "GameModePanel", BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "EscMenuBackdrop", 0)
        call BlzFrameSetAbsPoint(GM_Parent, FRAMEPOINT_TOPLEFT, GM_PANEL_LEFT, GM_PANEL_TOP)
        call BlzFrameSetAbsPoint(GM_Parent, FRAMEPOINT_BOTTOMRIGHT, GM_PANEL_RIGHT, GM_PANEL_BOTTOM)

        set GM_Title = BlzCreateFrameByType("TEXT", "GameModeTitle", GM_Parent, "", 0)
        call BlzFrameSetPoint(GM_Title, FRAMEPOINT_TOPLEFT, GM_Parent, FRAMEPOINT_TOPLEFT, 0.024, -0.024)
        call BlzFrameSetSize(GM_Title, 0.300, 0.024)
        call BlzFrameSetTextAlignment(GM_Title, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GM_Title, 1.18)
        call BlzFrameSetEnable(GM_Title, false)

        set GM_Body = BlzCreateFrameByType("TEXT", "GameModeBody", GM_Parent, "", 0)
        call BlzFrameSetPoint(GM_Body, FRAMEPOINT_TOPLEFT, GM_Title, FRAMEPOINT_BOTTOMLEFT, 0.000, -0.018)
        call BlzFrameSetSize(GM_Body, 0.395, 0.174)
        call BlzFrameSetTextAlignment(GM_Body, TEXT_JUSTIFY_TOP, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetEnable(GM_Body, false)

        set GM_Footer = BlzCreateFrameByType("TEXT", "GameModeFooter", GM_Parent, "", 0)
        call BlzFrameSetPoint(GM_Footer, FRAMEPOINT_BOTTOMLEFT, GM_Parent, FRAMEPOINT_BOTTOMLEFT, 0.024, 0.026)
        call BlzFrameSetSize(GM_Footer, 0.395, 0.018)
        call BlzFrameSetTextAlignment(GM_Footer, TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_LEFT)
        call BlzFrameSetScale(GM_Footer, 0.90)
        call BlzFrameSetEnable(GM_Footer, false)

        call GM_CreateModeButton(GAME_MODE_STORY, "Story", 0.026)
        call GM_CreateModeButton(GAME_MODE_FREE_ROAM, "Free Roam", 0.164)
        call GM_CreateModeButton(GAME_MODE_DEVELOPER, "Developer", 0.302)

        call GM_CreateDifficultyButton(DIFFICULTY_STORY, "Story", 0.026)
        call GM_CreateDifficultyButton(DIFFICULTY_NORMAL, "Normal", 0.164)
        call GM_CreateDifficultyButton(DIFFICULTY_HARD, "Hard", 0.302)

        set GM_BackButton = BlzCreateFrameByType("GLUETEXTBUTTON", "GameModeBackButton", GM_Parent, "ScriptDialogButton", 0)
        call BlzFrameSetSize(GM_BackButton, 0.070, 0.030)
        call BlzFrameSetPoint(GM_BackButton, FRAMEPOINT_TOPRIGHT, GM_Parent, FRAMEPOINT_TOPRIGHT, -0.016, -0.016)
        call BlzFrameSetText(GM_BackButton, "Back")
        call BlzTriggerRegisterFrameEvent(GM_BackTrigger, GM_BackButton, FRAMEEVENT_CONTROL_CLICK)
        call BlzTriggerRegisterFrameEvent(GM_ClearFocusTrigger, GM_BackButton, FRAMEEVENT_CONTROL_CLICK)

        call GM_ShowModeView()
        call BlzFrameSetVisible(GM_Parent, false)
    endfunction

    public function Init takes nothing returns nothing
        if GM_Initialized then
            return
        endif
        set GM_Initialized = true

        set GM_ModeTrigger = CreateTrigger()
        call TriggerAddAction(GM_ModeTrigger, function GM_ModeAction)

        set GM_DifficultyTrigger = CreateTrigger()
        call TriggerAddAction(GM_DifficultyTrigger, function GM_DifficultyAction)

        set GM_BackTrigger = CreateTrigger()
        call TriggerAddAction(GM_BackTrigger, function GM_BackAction)

        set GM_ClearFocusTrigger = CreateTrigger()
        call TriggerAddAction(GM_ClearFocusTrigger, function GM_ClearFocusAction)
    endfunction

    public function Show takes nothing returns nothing
        if not GM_Initialized then
            call Init()
        endif
        if GM_Parent == null then
            call GM_CreateFrames()
        endif
        call EnableUserControl(true)
        call GM_ApplyModeConfig(GAME_MODE_STORY)
        call GM_ShowModeView()
        if GM_Parent != null then
            if not BlzFrameIsVisible(GM_Parent) then
                call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_OPEN, Player(0))
            endif
            call BlzFrameSetVisible(GM_Parent, true)
            set GM_Visible = true
        endif
    endfunction

    public function Hide takes nothing returns nothing
        call GM_HideInternal()
    endfunction

    public function IsVisible takes nothing returns boolean
        return GM_Visible
    endfunction

    public function GetMode takes nothing returns integer
        return GM_SelectedMode
    endfunction

    public function GetDifficulty takes nothing returns integer
        return GM_SelectedDifficulty
    endfunction

    public function IsStoryEnabled takes nothing returns boolean
        return GM_StoryEnabled
    endfunction

    public function ShouldRunIntroCinematic takes nothing returns boolean
        return GM_RunIntroCinematic
    endfunction

    public function IsFreeRoamMode takes nothing returns boolean
        return GM_SelectedMode == GAME_MODE_FREE_ROAM
    endfunction

    public function IsDeveloperMode takes nothing returns boolean
        return GM_SelectedMode == GAME_MODE_DEVELOPER
    endfunction

    public function AreQuestRequirementsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled
    endfunction

    public function AreQuestLevelRequirementsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled and GM_QuestLevelRequirementsEnabled
    endfunction

    public function AreQuestReputationRequirementsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled and GM_QuestReputationRequirementsEnabled
    endfunction

    public function AreQuestEventRequirementsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled and GM_QuestEventRequirementsEnabled
    endfunction

    public function AreQuestPrerequisiteRequirementsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled and GM_QuestPrerequisiteRequirementsEnabled
    endfunction

    public function AreQuestCustomConditionsEnabled takes nothing returns boolean
        return GM_QuestRequirementsEnabled and GM_QuestCustomConditionsEnabled
    endfunction

    public function AreAllQuestsAvailableOnStart takes nothing returns boolean
        return GM_AllQuestsAvailableOnStart
    endfunction

    public function AreAbilityRequirementsEnabled takes nothing returns boolean
        return GM_AbilityRequirementsEnabled
    endfunction

    public function AreAbilityPrerequisitesEnabled takes nothing returns boolean
        return GM_AbilityRequirementsEnabled and GM_AbilityPrerequisitesEnabled
    endfunction

    public function AreAbilityQuestLocksEnabled takes nothing returns boolean
        return GM_AbilityRequirementsEnabled and GM_AbilityQuestLocksEnabled
    endfunction

    public function AreAbilityPointCostsEnabled takes nothing returns boolean
        return GM_AbilityPointCostsEnabled
    endfunction

    public function GetQuestRevealMode takes nothing returns integer
        return GM_QuestRevealMode
    endfunction

    public function GetStartingGoldBonus takes nothing returns integer
        return GM_StartingGoldBonus
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
