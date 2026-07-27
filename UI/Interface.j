/**
    Interface

    Author: Valdemar
    Version:

    Description:
    Central gateway for interface-related game feedback. UI libraries call the
    public notify functions when panels, map views, buttons, or similar
    interface actions happen. At this stage the library only plays configured
    sounds.

    Credits:

    How to install:
    Import this library before any UI library that calls it. The generated
    ExSoundEditorSounds registry supplies Sound Editor filepaths for fresh 3D
    playback from normal gg_snd_* entries. Configure overrides during map init
    with Interface_SetEventSound when needed.

    API:
    call Interface_SetEventSound(Interface_EVENT_UI_OPEN, gg_snd_Interface_UIOpen)
    call Interface_SetEventSound(Interface_EVENT_UI_CLOSE, gg_snd_Interface_UIClose)
    call Interface_ClearEventSound(Interface_EVENT_UI_OPEN)
    call Interface_PlayEventSound(Interface_EVENT_BUTTON_CLICK)
    call Interface_PlayEventSoundForPlayer(Interface_EVENT_UI_CLOSE, GetTriggerPlayer())
    call Interface_NotifyUnitSelected()
    call Interface_NotifyTargetSelectedByPlayer(GetTriggerPlayer(), GetTriggerUnit())
    call Interface_NotifyPlayerLevelUp()
    call Interface_NotifyUIOpened()
    call Interface_NotifyUIClosed()
    call Interface_NotifyInventoryOpened()
    call Interface_NotifyInventoryClosed()
    call Interface_NotifyMapOpened()
    call Interface_NotifyMapClosed()
    call Interface_NotifyMapModeChanged()
    call Interface_NotifyDialogButtonClicked()
    call Interface_NotifyDialogTradeButtonClicked()
    call Interface_NotifyDialogCloseButtonClicked()
    call Interface_NotifyQuestActivated()
    call Interface_NotifyQuestCompleted()
    call Interface_NotifyQuestLogClosed()
    call Interface_NotifyQuestWritten()
    call Interface_NotifyLootCoin()
    call Interface_NotifyHardWarning()
    call Interface_NotifyMiningHitOnUnit(GetTriggerUnit())
    call Interface_RefreshDefaultSounds()
    call Interface_ApplyProfessionCinematicVolumes(Player(0))
    call Interface_PlayProfessionSound(Interface_Profession_Blacksmithing_Start, "Tradeskill_BlacksmithStart", false)
    call Interface_PlayProfessionSoundOnUnit(Interface_Profession_Blacksmithing_Start, "Tradeskill_BlacksmithStart", GetTriggerUnit(), false, 1500.00)
    call Interface_PlayProfessionSoundPath(Interface_Profession_Blacksmithing_LoopPath, false)
    call Interface_PlayProfessionSoundPathOnUnit(Interface_Profession_Blacksmithing_LoopPath, GetTriggerUnit(), false, 1500.00)

**/
library Interface initializer AutoInit requires ExSound, ExSoundEditorSounds
    globals
        public constant integer EVENT_UNIT_SELECT = 1
        public constant integer EVENT_UI_OPEN = 2
        public constant integer EVENT_UI_CLOSE = 3
        public constant integer EVENT_MAP_OPEN = 4
        public constant integer EVENT_MAP_CLOSE = 5
        public constant integer EVENT_MENU_CLICK = 6
        public constant integer EVENT_BUTTON_CLICK = 7
        public constant integer EVENT_TAB_CHANGE = 8
        public constant integer EVENT_CONFIRM = 9
        public constant integer EVENT_CANCEL = 10
        public constant integer EVENT_ERROR = 11
        public constant integer EVENT_DIALOG_BUTTON_NORMAL = 12
        public constant integer EVENT_DIALOG_BUTTON_TRADE = 13
        public constant integer EVENT_DIALOG_BUTTON_CLOSE = 14
        public constant integer EVENT_SELECT_TARGET = 15
        public constant integer EVENT_PLAYER_LEVELUP = 16
        public constant integer EVENT_MAP_MODE = 17
        public constant integer EVENT_TRADESKILL_MINING_HIT_A = 18
        public constant integer EVENT_TRADESKILL_MINING_HIT_B = 19
        public constant integer EVENT_TRADESKILL_MINING_HIT_C = 20
        public constant integer EVENT_TRADESKILL_MINING_HIT_D = 21
        public constant integer EVENT_TRADESKILL_MINING_HIT_E = 22
        public constant integer EVENT_INVENTORY_OPEN = 23
        public constant integer EVENT_INVENTORY_CLOSE = 24
        public constant integer EVENT_QUEST_ACTIVATE = 25
        public constant integer EVENT_QUEST_COMPLETE = 26
        public constant integer EVENT_QUEST_LOG_CLOSE = 27
        public constant integer EVENT_QUEST_WRITE = 28
        public constant integer EVENT_LOOT_COIN = 29
        public constant integer EVENT_HARD_WARNING = 30
        public constant integer EVENT_TRADESKILL_HERB_PICK = 31

        private constant integer IUI_EVENT_MAX = 31
        private constant real IUI_MINING_SOUND_CUTOFF = 1500.00
        private constant real IUI_PROFESSION_SOUND_CUTOFF = 1500.00

        private boolean IUI_Initialized = false
        private boolean IUI_SoundsEnabled = true
        private boolean IUI_UnitSelectSoundEnabled = true

        // Event sounds are assigned during init and can be overridden through SetEventSound.
        private sound array IUI_EventSound

        // Profession station sounds are shared by Professions.j and its sublibraries.
        public sound Profession_Alchemy_Start = null
        public sound Profession_Alchemy_Loop = null
        public sound Profession_Alchemy_End = null
        public sound Profession_Blacksmithing_Start = null
        public sound Profession_Blacksmithing_Loop = null
        public sound Profession_Blacksmithing_End = null
        public sound Profession_Mining_Start = null
        public sound Profession_Mining_Loop = null
        public sound Profession_Mining_End = null
        public sound Profession_Leatherworking_Start = null
        public sound Profession_Leatherworking_Loop = null
        public sound Profession_Leatherworking_End = null
        public sound Profession_Cooking_Start = null
        public sound Profession_Cooking_Loop = null
        public sound Profession_Cooking_End = null
        public sound Profession_Enchanting_Start = null
        public sound Profession_Enchanting_Loop = null
        public sound Profession_Enchanting_End = null
        public sound Profession_Fishing_Start = null
        public sound Profession_Fishing_Loop = null
        public sound Profession_Fishing_End = null
        public sound Profession_Skinning_Start = null
        public sound Profession_Skinning_Loop = null
        public sound Profession_Skinning_End = null

        // Profession sound paths create fresh handles when code must choose 3D or normal playback.
        public string Profession_Alchemy_StartPath = ""
        public string Profession_Alchemy_LoopPath = ""
        public string Profession_Alchemy_EndPath = ""
        public string Profession_Blacksmithing_StartPath = ""
        public string Profession_Blacksmithing_LoopPath = ""
        public string Profession_Blacksmithing_EndPath = ""
        public string Profession_Mining_StartPath = ""
        public string Profession_Mining_LoopPath = ""
        public string Profession_Mining_EndPath = ""
        public string Profession_Leatherworking_StartPath = ""
        public string Profession_Leatherworking_LoopPath = ""
        public string Profession_Leatherworking_EndPath = ""
        public string Profession_Cooking_StartPath = ""
        public string Profession_Cooking_LoopPath = ""
        public string Profession_Cooking_EndPath = ""
        public string Profession_Enchanting_StartPath = ""
        public string Profession_Enchanting_LoopPath = ""
        public string Profession_Enchanting_EndPath = ""
        public string Profession_Fishing_StartPath = ""
        public string Profession_Fishing_LoopPath = ""
        public string Profession_Fishing_EndPath = ""
        public string Profession_Skinning_StartPath = ""
        public string Profession_Skinning_LoopPath = ""
        public string Profession_Skinning_EndPath = ""

        private trigger IUI_UnitSelectTrigger = null
        private trigger IUI_PlayerLevelUpTrigger = null
    endglobals

    private function IUI_IsValidEvent takes integer eventId returns boolean
        return eventId >= EVENT_UNIT_SELECT and eventId <= IUI_EVENT_MAX
    endfunction

    private function IUI_IsMiningHitEvent takes integer eventId returns boolean
        return eventId >= EVENT_TRADESKILL_MINING_HIT_A and eventId <= EVENT_TRADESKILL_MINING_HIT_E
    endfunction

    private function IUI_GetMiningHitSoundLabel takes integer eventId returns string
        if eventId == EVENT_TRADESKILL_MINING_HIT_A then
            return "Tradeskill_MiningHitA"
        elseif eventId == EVENT_TRADESKILL_MINING_HIT_B then
            return "Tradeskill_MiningHitB"
        elseif eventId == EVENT_TRADESKILL_MINING_HIT_C then
            return "Tradeskill_MiningHitC"
        elseif eventId == EVENT_TRADESKILL_MINING_HIT_D then
            return "Tradeskill_MiningHitD"
        elseif eventId == EVENT_TRADESKILL_MINING_HIT_E then
            return "Tradeskill_MiningHitE"
        endif

        return ""
    endfunction

    private function IUI_GetWorldEventSoundLabel takes integer eventId returns string
        if IUI_IsMiningHitEvent(eventId) then
            return IUI_GetMiningHitSoundLabel(eventId)
        elseif eventId == EVENT_TRADESKILL_HERB_PICK then
            return "Tradeskill_HerbPick"
        endif

        return ""
    endfunction

    private function IUI_IsBlankString takes string value returns boolean
        return value == null or value == ""
    endfunction

    private function IUI_PlaySound takes sound whichSound returns nothing
        if IUI_SoundsEnabled and whichSound != null then
            call ExSound_PlayHandle(whichSound)
        endif
    endfunction

    private function IUI_PlaySoundOnUnit takes sound whichSound, unit whichUnit returns nothing
        if IUI_SoundsEnabled and whichSound != null and whichUnit != null then
            call ExSound_PlayHandleOnUnitEx(whichSound, whichUnit, EXSOUND_3D_MIN_DISTANCE, IUI_PROFESSION_SOUND_CUTOFF)
        endif
    endfunction

    private function IUI_PlayMiningHitSoundOnUnit takes integer eventId, unit whichUnit returns nothing
        local string soundLabel
        local sound miningSound

        if not IUI_SoundsEnabled or whichUnit == null then
            return
        endif

        set soundLabel = IUI_GetMiningHitSoundLabel(eventId)
        if soundLabel != "" then
            set miningSound = ExSound_PlayLabelOnUnitEx(soundLabel, whichUnit, false, EXSOUND_3D_MIN_DISTANCE, IUI_MINING_SOUND_CUTOFF)
            if miningSound != null then
                set miningSound = null
                return
            endif
        endif

        set miningSound = IUI_EventSound[eventId]
        if miningSound != null then
            call ExSound_PlayHandleOnUnitEx(miningSound, whichUnit, EXSOUND_3D_MIN_DISTANCE, IUI_MINING_SOUND_CUTOFF)
            set miningSound = null
            return
        endif

        set miningSound = null
    endfunction

    private function IUI_PlayWorldEventSoundOnUnit takes integer eventId, unit whichUnit returns nothing
        local string soundLabel
        local sound eventSound

        if not IUI_SoundsEnabled or whichUnit == null then
            return
        endif

        set soundLabel = IUI_GetWorldEventSoundLabel(eventId)
        if soundLabel != "" then
            set eventSound = ExSound_PlayLabelOnUnitEx(soundLabel, whichUnit, false, EXSOUND_3D_MIN_DISTANCE, IUI_MINING_SOUND_CUTOFF)
            if eventSound != null then
                set eventSound = null
                return
            endif
        endif

        set eventSound = IUI_EventSound[eventId]
        if eventSound != null then
            call ExSound_PlayHandleOnUnitEx(eventSound, whichUnit, EXSOUND_3D_MIN_DISTANCE, IUI_MINING_SOUND_CUTOFF)
            set eventSound = null
            return
        endif

        set eventSound = null
    endfunction

    public function PlayProfessionSoundPathOnUnit takes string soundPath, unit whichUnit, boolean looping, real cutoff returns sound
        if not IUI_SoundsEnabled or whichUnit == null or soundPath == null or soundPath == "" then
            return null
        endif
        if cutoff <= 0.00 then
            set cutoff = IUI_PROFESSION_SOUND_CUTOFF
        endif

        return ExSound_PlayPathOnUnitEx(soundPath, whichUnit, looping, EXSOUND_3D_MIN_DISTANCE, cutoff)
    endfunction

    public function PlayProfessionSoundPath takes string soundPath, boolean looping returns sound
        if not IUI_SoundsEnabled or soundPath == null or soundPath == "" then
            return null
        endif

        return ExSound_PlayPath(soundPath, looping)
    endfunction

    public function PlayProfessionSoundOnUnit takes sound whichSound, string soundLabel, unit whichUnit, boolean looping, real cutoff returns sound
        local sound professionSound = null

        if not IUI_SoundsEnabled or whichUnit == null then
            return null
        endif
        if cutoff <= 0.00 then
            set cutoff = IUI_PROFESSION_SOUND_CUTOFF
        endif

        if soundLabel != null and soundLabel != "" then
            set professionSound = ExSound_PlayLabelOnUnitEx(soundLabel, whichUnit, looping, EXSOUND_3D_MIN_DISTANCE, cutoff)
            if professionSound != null then
                return professionSound
            endif
        endif

        if whichSound != null then
            return ExSound_PlayHandleOnUnitEx(whichSound, whichUnit, EXSOUND_3D_MIN_DISTANCE, cutoff)
        endif

        return null
    endfunction

    public function PlayProfessionSound takes sound whichSound, string soundLabel, boolean looping returns sound
        local sound professionSound = null

        if not IUI_SoundsEnabled then
            return null
        endif

        if whichSound != null then
            return ExSound_PlayHandle(whichSound)
        endif

        if soundLabel != null and soundLabel != "" then
            set professionSound = ExSound_PlayLabel(soundLabel, looping)
            if professionSound != null then
                return professionSound
            endif
        endif

        return null
    endfunction

    public function ApplyProfessionCinematicVolumes takes player whichPlayer returns nothing
        if whichPlayer == null then
            return
        endif

        // Profession craft feedback must stay audible during fullscreen craft sequences.
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_UNITSOUNDS, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_UI, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_COMBAT, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_SPELLS, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_FIRE, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_CINEMATIC_GENERAL, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_CINEMATIC_SOUND_EFFECTS_1, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_CINEMATIC_SOUND_EFFECTS_2, 1.00)
        call VolumeGroupSetVolumeForPlayerBJ(whichPlayer, SOUND_VOLUMEGROUP_CINEMATIC_SOUND_EFFECTS_3, 1.00)
    endfunction

    private function IUI_PlayEvent takes integer eventId returns nothing
        if IUI_IsValidEvent(eventId) then
            call IUI_PlaySound(IUI_EventSound[eventId])
        endif
    endfunction

    private function IUI_PlayEventOnUnit takes integer eventId, unit whichUnit returns nothing
        if IUI_IsMiningHitEvent(eventId) then
            call IUI_PlayMiningHitSoundOnUnit(eventId, whichUnit)
        elseif eventId == EVENT_TRADESKILL_HERB_PICK then
            call IUI_PlayWorldEventSoundOnUnit(eventId, whichUnit)
        elseif IUI_IsValidEvent(eventId) then
            call IUI_PlaySoundOnUnit(IUI_EventSound[eventId], whichUnit)
        endif
    endfunction

    private function IUI_ShouldPlaySelectTarget takes player selectingPlayer, unit selectedUnit returns boolean
        if not IUI_UnitSelectSoundEnabled then
            return false
        endif
        if selectingPlayer != Player(0) or GetLocalPlayer() != Player(0) then
            return false
        endif
        if selectedUnit == null then
            return false
        endif
        return GetOwningPlayer(selectedUnit) != selectingPlayer
    endfunction

    private function IUI_UnitSelectAction takes nothing returns nothing
        local player triggerPlayer = GetTriggerPlayer()
        local unit selectedUnit = GetTriggerUnit()

        if IUI_ShouldPlaySelectTarget(triggerPlayer, selectedUnit) then
            call IUI_PlayEvent(EVENT_SELECT_TARGET)
        endif

        set selectedUnit = null
        set triggerPlayer = null
    endfunction

    private function IUI_PlayerLevelUpAction takes nothing returns nothing
        local unit levelingUnit = GetTriggerUnit()

        if levelingUnit != null and GetOwningPlayer(levelingUnit) == Player(0) and GetLocalPlayer() == Player(0) then
            call IUI_PlayEvent(EVENT_PLAYER_LEVELUP)
        endif

        set levelingUnit = null
    endfunction

    private function IUI_RegisterUnitSelectEvents takes nothing returns nothing
        set IUI_UnitSelectTrigger = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(IUI_UnitSelectTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
        call TriggerAddAction(IUI_UnitSelectTrigger, function IUI_UnitSelectAction)
    endfunction

    private function IUI_RegisterPlayerLevelUpEvent takes nothing returns nothing
        set IUI_PlayerLevelUpTrigger = CreateTrigger()
        call TriggerRegisterPlayerUnitEvent(IUI_PlayerLevelUpTrigger, Player(0), EVENT_PLAYER_HERO_LEVEL, null)
        call TriggerAddAction(IUI_PlayerLevelUpTrigger, function IUI_PlayerLevelUpAction)
    endfunction

    private function IUI_InitDefaultSounds takes nothing returns nothing
        call ExSoundEditorSounds_RegisterAll()

        // Replace any remaining null entries with final World Editor sound globals when they exist. Commented ones are fyi.
        set IUI_EventSound[EVENT_UNIT_SELECT] = null                                            // Reserved for a future own-unit select sound.
        set IUI_EventSound[EVENT_UI_OPEN] = gg_snd_Interface_LeftGlueScreenPopUp                // gg_snd_Interface_MenuClick
        set IUI_EventSound[EVENT_UI_CLOSE] = gg_snd_Interface_LeftGlueScreenPopDown             // gg_snd_Interface_MenuClose
        set IUI_EventSound[EVENT_MAP_OPEN] = gg_snd_Interface_TurnPage                          // gg_snd_Interface_TurnPage
        set IUI_EventSound[EVENT_MAP_CLOSE] = gg_snd_Interface_MinimapClose                     // gg_snd_Interface_MinimapClose
        set IUI_EventSound[EVENT_MENU_CLICK] = gg_snd_Interface_MenuClick                       // gg_snd_Interface_MenuClick
        set IUI_EventSound[EVENT_BUTTON_CLICK] = gg_snd_Interface_IconDrop                      // gg_snd_Interface_ButtonClick
        set IUI_EventSound[EVENT_TAB_CHANGE] = gg_snd_Interface_TurnPage                        // gg_snd_Interface_TurnPage
        set IUI_EventSound[EVENT_CONFIRM] = gg_snd_Interface_BigButtonClick                     // gg_snd_Interface_ReadyCheck
        set IUI_EventSound[EVENT_CANCEL] = gg_snd_Interface_MenuClose                           // gg_snd_Interface_MenuClose
        set IUI_EventSound[EVENT_ERROR] = gg_snd_Error                                          // gg_snd_Interface_HardWarning
        set IUI_EventSound[EVENT_DIALOG_BUTTON_NORMAL] = gg_snd_Interface_MenuClick2            // gg_snd_Interface_MenuClick2
        set IUI_EventSound[EVENT_DIALOG_BUTTON_TRADE] = gg_snd_Interface_CharacterSheetOpen     // gg_snd_Interface_CharacterSheetOpen
        set IUI_EventSound[EVENT_DIALOG_BUTTON_CLOSE] = gg_snd_Interface_MenuClose              // gg_snd_Interface_MenuClose
        set IUI_EventSound[EVENT_SELECT_TARGET] = gg_snd_Interface_SelectTarget                 // gg_snd_Interface_SelectTarget
        set IUI_EventSound[EVENT_PLAYER_LEVELUP] = gg_snd_Interface_Levelup                     // gg_snd_Interface_Levelup
        set IUI_EventSound[EVENT_MAP_MODE] = gg_snd_Interface_MenuClick2                        // gg_snd_Interface_MenuClick2
        set IUI_EventSound[EVENT_TRADESKILL_MINING_HIT_A] = gg_snd_Tradeskill_MiningHitA        // gg_snd_Tradeskill_MiningHitA
        set IUI_EventSound[EVENT_TRADESKILL_MINING_HIT_B] = gg_snd_Tradeskill_MiningHitB        // gg_snd_Tradeskill_MiningHitB
        set IUI_EventSound[EVENT_TRADESKILL_MINING_HIT_C] = gg_snd_Tradeskill_MiningHitC        // gg_snd_Tradeskill_MiningHitC
        set IUI_EventSound[EVENT_TRADESKILL_MINING_HIT_D] = gg_snd_Tradeskill_MiningHitD        // gg_snd_Tradeskill_MiningHitD
        set IUI_EventSound[EVENT_TRADESKILL_MINING_HIT_E] = gg_snd_Tradeskill_MiningHitE        // gg_snd_Tradeskill_MiningHitE
        set IUI_EventSound[EVENT_INVENTORY_OPEN] = gg_snd_Interface_InventoryOpen               // gg_snd_Interface_InventoryOpen
        set IUI_EventSound[EVENT_INVENTORY_CLOSE] = gg_snd_Interface_InventoryClose             // gg_snd_Interface_InventoryClose
        set IUI_EventSound[EVENT_QUEST_ACTIVATE] = gg_snd_Interface_QuestActivate               // gg_snd_Interface_QuestActivate
        set IUI_EventSound[EVENT_QUEST_COMPLETE] = gg_snd_Interface_QuestComplete               // gg_snd_Interface_QuestComplete
        set IUI_EventSound[EVENT_QUEST_LOG_CLOSE] = gg_snd_Interface_QuestLogClose              // gg_snd_Interface_QuestLogClose
        set IUI_EventSound[EVENT_QUEST_WRITE] = gg_snd_Interface_QuestWrite                     // gg_snd_Interface_QuestWrite
        set IUI_EventSound[EVENT_LOOT_COIN] = gg_snd_Interface_LootCoin                         // gg_snd_Interface_LootCoin
        set IUI_EventSound[EVENT_HARD_WARNING] = gg_snd_Interface_HardWarning                   // gg_snd_Interface_HardWarning
        set IUI_EventSound[EVENT_TRADESKILL_HERB_PICK] = gg_snd_Tradeskill_HerbPick             // gg_snd_Tradeskill_HerbPick

        set Profession_Alchemy_Start = gg_snd_CauldronSound
        set Profession_Alchemy_Loop = gg_snd_CauldronSound
        set Profession_Alchemy_End = gg_snd_Tradeskill_AlchemyEnd
        set Profession_Blacksmithing_Start = gg_snd_Tradeskill_BlacksmithStart
        set Profession_Blacksmithing_Loop = gg_snd_Blacksmithing
        set Profession_Blacksmithing_End = gg_snd_Blacksmithing
        set Profession_Mining_Start = gg_snd_Smelting                                           // Use of forge for smelting ores
        set Profession_Mining_Loop = gg_snd_Smelting
        set Profession_Mining_End = gg_snd_Smelting
        set Profession_Leatherworking_Start = gg_snd_Tannery
        set Profession_Leatherworking_Loop = gg_snd_Tannery
        set Profession_Leatherworking_End = gg_snd_Tannery
        set Profession_Cooking_Start = gg_snd_CookingPrepareA
        set Profession_Cooking_Loop = gg_snd_CookingPrepareA
        set Profession_Cooking_End = gg_snd_CookingPrepareA
        set Profession_Enchanting_Start = null
        set Profession_Enchanting_Loop = null
        set Profession_Enchanting_End = null
        set Profession_Fishing_Start = null
        set Profession_Fishing_Loop = null
        set Profession_Fishing_End = gg_snd_Tradeskill_Fishing
        set Profession_Skinning_Start = gg_snd_Tradeskill_LeatherworkingPick
        set Profession_Skinning_Loop = gg_snd_Tradeskill_LeatherworkingPick
        set Profession_Skinning_End = gg_snd_Tradeskill_LeatherworkingPick

        if IUI_IsBlankString(Profession_Alchemy_StartPath) then
            set Profession_Alchemy_StartPath = ExSoundEditorSounds_GetPath("CauldronSound")
        endif
        if IUI_IsBlankString(Profession_Alchemy_LoopPath) then
            set Profession_Alchemy_LoopPath = ExSoundEditorSounds_GetPath("CauldronSound")
        endif
        if IUI_IsBlankString(Profession_Alchemy_EndPath) then
            set Profession_Alchemy_EndPath = ExSoundEditorSounds_GetPath("Tradeskill_AlchemyEnd")
        endif
        if IUI_IsBlankString(Profession_Blacksmithing_StartPath) then
            set Profession_Blacksmithing_StartPath = ExSoundEditorSounds_GetPath("Tradeskill_BlacksmithStart")
        endif
        if IUI_IsBlankString(Profession_Blacksmithing_LoopPath) then
            set Profession_Blacksmithing_LoopPath = ExSoundEditorSounds_GetPath("Blacksmithing")
        endif
        if IUI_IsBlankString(Profession_Blacksmithing_EndPath) then
            set Profession_Blacksmithing_EndPath = ExSoundEditorSounds_GetPath("Blacksmithing")
        endif
        if IUI_IsBlankString(Profession_Mining_StartPath) then
            set Profession_Mining_StartPath = ExSoundEditorSounds_GetPath("Smelting")            // Use of forge for smelting ores
        endif
        if IUI_IsBlankString(Profession_Mining_LoopPath) then
            set Profession_Mining_LoopPath = ExSoundEditorSounds_GetPath("Smelting")
        endif
        if IUI_IsBlankString(Profession_Mining_EndPath) then
            set Profession_Mining_EndPath = ExSoundEditorSounds_GetPath("Smelting")
        endif
        if IUI_IsBlankString(Profession_Leatherworking_StartPath) then
            set Profession_Leatherworking_StartPath = ExSoundEditorSounds_GetPath("Tannery")
        endif
        if IUI_IsBlankString(Profession_Leatherworking_LoopPath) then
            set Profession_Leatherworking_LoopPath = ExSoundEditorSounds_GetPath("Tannery")
        endif
        if IUI_IsBlankString(Profession_Leatherworking_EndPath) then
            set Profession_Leatherworking_EndPath = ExSoundEditorSounds_GetPath("Tannery")
        endif
        if IUI_IsBlankString(Profession_Cooking_StartPath) then
            set Profession_Cooking_StartPath = ExSoundEditorSounds_GetPath("CookingPrepareA")
        endif
        if IUI_IsBlankString(Profession_Cooking_LoopPath) then
            set Profession_Cooking_LoopPath = ExSoundEditorSounds_GetPath("CookingPrepareA")
        endif
        if IUI_IsBlankString(Profession_Cooking_EndPath) then
            set Profession_Cooking_EndPath = ExSoundEditorSounds_GetPath("CookingPrepareA")
        endif
        if IUI_IsBlankString(Profession_Fishing_EndPath) then
            set Profession_Fishing_EndPath = ExSoundEditorSounds_GetPath("Tradeskill_Fishing")
        endif
        if IUI_IsBlankString(Profession_Skinning_StartPath) then
            set Profession_Skinning_StartPath = ExSoundEditorSounds_GetPath("Tradeskill_LeatherworkingPick")
        endif
        if IUI_IsBlankString(Profession_Skinning_LoopPath) then
            set Profession_Skinning_LoopPath = ExSoundEditorSounds_GetPath("Tradeskill_LeatherworkingPick")
        endif
        if IUI_IsBlankString(Profession_Skinning_EndPath) then
            set Profession_Skinning_EndPath = ExSoundEditorSounds_GetPath("Tradeskill_LeatherworkingPick")
        endif
    endfunction

    public function RefreshDefaultSounds takes nothing returns nothing
        call IUI_InitDefaultSounds()
    endfunction

    public function SetSoundsEnabled takes boolean enabled returns nothing
        set IUI_SoundsEnabled = enabled
    endfunction

    public function AreSoundsEnabled takes nothing returns boolean
        return IUI_SoundsEnabled
    endfunction

    public function SetUnitSelectSoundEnabled takes boolean enabled returns nothing
        set IUI_UnitSelectSoundEnabled = enabled
    endfunction

    public function IsUnitSelectSoundEnabled takes nothing returns boolean
        return IUI_UnitSelectSoundEnabled
    endfunction

    public function SetEventSound takes integer eventId, sound whichSound returns nothing
        if IUI_IsValidEvent(eventId) then
            set IUI_EventSound[eventId] = whichSound
        endif
    endfunction

    public function ClearEventSound takes integer eventId returns nothing
        if IUI_IsValidEvent(eventId) then
            set IUI_EventSound[eventId] = null
        endif
    endfunction

    public function PlayEventSound takes integer eventId returns nothing
        call RefreshDefaultSounds()
        call IUI_PlayEvent(eventId)
    endfunction

    public function PlayEventSoundForPlayer takes integer eventId, player whichPlayer returns nothing
        if whichPlayer != null and GetLocalPlayer() == whichPlayer then
            call RefreshDefaultSounds()
            call IUI_PlayEvent(eventId)
        endif
    endfunction

    public function PlayEventSoundOnUnit takes integer eventId, unit whichUnit returns nothing
        call RefreshDefaultSounds()
        call IUI_PlayEventOnUnit(eventId, whichUnit)
    endfunction

    public function NotifyUnitSelected takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UNIT_SELECT)
    endfunction

    public function NotifyTargetSelectedByPlayer takes player selectingPlayer, unit selectedUnit returns nothing
        if IUI_ShouldPlaySelectTarget(selectingPlayer, selectedUnit) then
            call IUI_PlayEvent(EVENT_SELECT_TARGET)
        endif
    endfunction

    public function NotifyPlayerLevelUp takes nothing returns nothing
        call IUI_PlayEvent(EVENT_PLAYER_LEVELUP)
    endfunction

    public function NotifyUIOpened takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UI_OPEN)
    endfunction

    public function NotifyUIClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_UI_CLOSE)
    endfunction

    public function NotifyInventoryOpened takes nothing returns nothing
        call IUI_PlayEvent(EVENT_INVENTORY_OPEN)
    endfunction

    public function NotifyInventoryClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_INVENTORY_CLOSE)
    endfunction

    public function NotifyMapOpened takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MAP_OPEN)
    endfunction

    public function NotifyMapClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MAP_CLOSE)
    endfunction

    public function NotifyMapModeChanged takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MAP_MODE)
    endfunction

    public function NotifyMenuClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_MENU_CLICK)
    endfunction

    public function NotifyButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_BUTTON_CLICK)
    endfunction

    public function NotifyTabChanged takes nothing returns nothing
        call IUI_PlayEvent(EVENT_TAB_CHANGE)
    endfunction

    public function NotifyConfirmed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_CONFIRM)
    endfunction

    public function NotifyCancelled takes nothing returns nothing
        call IUI_PlayEvent(EVENT_CANCEL)
    endfunction

    public function NotifyError takes nothing returns nothing
        call IUI_PlayEvent(EVENT_ERROR)
    endfunction

    public function NotifyDialogButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_NORMAL)
    endfunction

    public function NotifyDialogTradeButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_TRADE)
    endfunction

    public function NotifyDialogCloseButtonClicked takes nothing returns nothing
        call IUI_PlayEvent(EVENT_DIALOG_BUTTON_CLOSE)
    endfunction

    public function NotifyQuestActivated takes nothing returns nothing
        call IUI_PlayEvent(EVENT_QUEST_ACTIVATE)
    endfunction

    public function NotifyQuestCompleted takes nothing returns nothing
        call IUI_PlayEvent(EVENT_QUEST_COMPLETE)
    endfunction

    public function NotifyQuestLogClosed takes nothing returns nothing
        call IUI_PlayEvent(EVENT_QUEST_LOG_CLOSE)
    endfunction

    public function NotifyQuestWritten takes nothing returns nothing
        call IUI_PlayEvent(EVENT_QUEST_WRITE)
    endfunction

    public function NotifyLootCoin takes nothing returns nothing
        call IUI_PlayEvent(EVENT_LOOT_COIN)
    endfunction

    public function NotifyHardWarning takes nothing returns nothing
        call IUI_PlayEvent(EVENT_HARD_WARNING)
    endfunction

    public function NotifyMiningHitOnUnit takes unit whichUnit returns nothing
        call RefreshDefaultSounds()
        call IUI_PlayEventOnUnit(EVENT_TRADESKILL_MINING_HIT_A + GetRandomInt(0, 4), whichUnit)
    endfunction

    public function NotifyHerbPickOnUnit takes unit whichUnit returns nothing
        call RefreshDefaultSounds()
        call IUI_PlayEventOnUnit(EVENT_TRADESKILL_HERB_PICK, whichUnit)
    endfunction

    public function Init takes nothing returns nothing
        if IUI_Initialized then
            return
        endif
        set IUI_Initialized = true

        call IUI_InitDefaultSounds()
        call IUI_RegisterUnitSelectEvents()
        call IUI_RegisterPlayerLevelUpEvent()
    endfunction

    public function AutoInit takes nothing returns nothing
        call Init()
    endfunction
endlibrary
