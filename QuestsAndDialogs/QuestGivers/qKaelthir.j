/**
    qKaelthir

    Author: Valdemar
    Version:

    Description:
    Converts Kaelthir's legacy Struggle and Hunger quests to the current
    quest and dialog systems. Hunger preserves its three mutually exclusive
    outcomes: mercy, feeding Kaelthir a mana crystal, or taking him to Aradion.

    Credits:
    Converted from QuestsAndDialogs/OLDGUI/Kaelthir and the current
    VoicelinesKaelthir constants.

    How to install:
    Import after the required quest, dialog, hero-item, companion, and
    voiceline libraries. Keep placed Kaelthir unit `n01X`, the Aradion and
    hero GUI unit globals, and gg_rct_AradionPlace available.

    API:
    - qKaelthir_GetHungerOutcome()
    - qKaelthir_RefreshAvailability()
    - qKaelthir_RefreshRespawnedUnitHooks()

**/
library qKaelthir initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, VoicelinesKaelthir

globals
    private constant boolean DEBUG = false

    public constant string QUEST_STRUGGLE = "Kaelthir's Struggle"
    public constant string QUEST_HUNGER = "Kaelthir's Hunger"

    public constant integer HUNGER_OUTCOME_NONE = 0
    public constant integer HUNGER_OUTCOME_MERCY = 1
    public constant integer HUNGER_OUTCOME_WRAITH = 2
    public constant integer HUNGER_OUTCOME_ARADION = 3

    private constant string KAELTHIR_NAME = "Kaelthir"
    private constant string ARADION_NAME = "Aradion the Farseer"
    private constant integer UNIT_KAELTHIR = 'n01X'
    private constant integer ITEM_MANA_CRYSTAL = 'I00Y'
    private constant integer UNIT_MANA_WRAITH = 'n002'
    private constant integer HOSTILE_OWNER = 11

    private constant real DIALOG_RANGE = 500.00
    private constant real DIALOG_COOLDOWN = 6.00
    private constant real DIALOG_FADE_OUT = 1.00
    private constant real DIALOG_FADE_IN = 1.00
    private constant integer CINEMATIC_MOVE_MODE = 0
    private constant real CINEMATIC_MOVE_OFFSET = 0.00
    private constant real CINEMATIC_MOVE_ANGLE = 0.00

    private constant boolean ALLOW_NAZGREK = true
    private constant boolean ALLOW_ZULKIS = false
    private constant boolean USE_DIALOG_CAMERA = true
    private constant boolean CINEMATIC = true
    private constant real CAMERA_DIST = 850.00
    private constant real CAMERA_Z_OFFSET = 20.00
    private constant real CAMERA_ANGLE = 350.00
    private constant real CAMERA_ROT_OFFSET = 180.00
    private constant real CAMERA_FAR_Z = 10000.00
    private constant real CAMERA_FOV = 60.00
    private constant real CAMERA_BLOCK_RADIUS = 0.00
    private constant boolean CAMERA_BLOCK_CHECK = true

    private constant string KAELTHIR_COMPANION_ICON = "ReplaceableTextures\\CommandButtons\\BTNSpellBreaker.blp"

    private unit Kaelthir = null
    private unit Nazgrek = null
    private unit Zulkis = null
    private unit Aradion = null
    private unit SelectedHero = null
    private dialog KaelthirDialog = null
    private timer KaelthirDialogCooldown = null
    private timer HungerEscortTimer = null
    private timer KaelthirInitTimer = null
    private boolean HungerEscortActive = false
    private boolean HungerAradionSequenceActive = false
    private boolean KaelthirInitWaitingLogged = false
endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qKaelthir]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    local unit found = null
    if not DialogInteraction_IsUnitAlive(Kaelthir) then
        set found = QuestGiver_FindPreferredUnitInRect(bj_mapInitialPlayableArea, UNIT_KAELTHIR, null, null, null, null, null, false)
        if found != null and GetUnitTypeId(found) == UNIT_KAELTHIR then
            if Kaelthir != null then
                call QuestGiver_UpdateGiverUnitReference(Kaelthir, found)
            endif
            set Kaelthir = found
        endif
    endif
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
    if udg_Aradion != null and udg_Aradion != Aradion then
        set Aradion = udg_Aradion
    endif
    set found = null
endfunction

private function ResolveDialogHero takes nothing returns unit
    call SyncUnitReferences()
    return DialogInteraction_ResolveDialogHero(SelectedHero, Kaelthir, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function GetStruggleQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Kaelthir == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_STRUGGLE, Kaelthir)
endfunction

private function GetHungerQuest takes nothing returns QuestData
    call SyncUnitReferences()
    if Kaelthir == null then
        return 0
    endif
    return QuestGiver_GetByNameAndGiver(QUEST_HUNGER, Kaelthir)
endfunction

private function StartExitFadeOut takes nothing returns nothing
    call DialogInteraction_StartConfiguredDialogExitTransition(Kaelthir, SelectedHero, KaelthirDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
endfunction

private function CompleteHungerChoice takes integer requirementIndex returns nothing
    local QuestData q = GetHungerQuest()
    if q != 0 and q.active and not q.completed and not q.failed then
        call q.markRequirementCompleted(requirementIndex, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_HUNGER, Kaelthir)
    endif
    set q = 0
endfunction

private function StopHungerEscort takes nothing returns nothing
    local QuestData q = GetHungerQuest()
    if HungerEscortTimer != null then
        call PauseTimer(HungerEscortTimer)
    endif
    if q != 0 then
        call QuestGiver_UnregisterEscortRequirement(q.id, 3)
    endif
    if HungerEscortActive and Kaelthir != null then
        call QuestGiver_RemoveCompanion(Kaelthir)
        call SetUnitInvulnerable(Kaelthir, false)
    endif
    set HungerEscortActive = false
    set q = 0
endfunction

private function OnAcceptStruggleEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_STRUGGLE, Kaelthir)
    call StartExitFadeOut()
endfunction

private function OnAcceptStruggle takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0009_TEXT, VL_KAELTHIR_0009_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0010_TEXT, VL_KAELTHIR_0010_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0011_TEXT, VL_KAELTHIR_0011_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0016_TEXT, VL_KAELTHIR_0016_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptStruggleEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function OnCompleteStruggleEnd takes nothing returns nothing
    local QuestData q = GetStruggleQuest()
    if q != 0 and q.active and not q.completed and HeroItemCheckBoth(ITEM_MANA_CRYSTAL, 1) then
        call QuestGiver_RemoveHeroItemsEither(ITEM_MANA_CRYSTAL, 0, 1)
        call q.markRequirementCompleted(1, true)
        call QuestGiver_CompleteQuestByNameAndGiver(QUEST_STRUGGLE, Kaelthir)
        call QuestGiver_RefreshAvailabilityForGiver(Kaelthir)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnCompleteStruggle takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0014_TEXT, VL_KAELTHIR_0014_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0015_TEXT, VL_KAELTHIR_0015_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteStruggleEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function OnAcceptHungerEnd takes nothing returns nothing
    call QuestGiver_AcceptQuestByNameAndGiver(QUEST_HUNGER, Kaelthir)
    call StartExitFadeOut()
endfunction

private function OnAcceptHunger takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0018_TEXT, VL_KAELTHIR_0018_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0019_TEXT, VL_KAELTHIR_0019_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0020_TEXT, VL_KAELTHIR_0020_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptHungerEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function OnMercyEnd takes nothing returns nothing
    call CompleteHungerChoice(HUNGER_OUTCOME_MERCY)
    call StartExitFadeOut()
    if DialogInteraction_IsUnitAlive(Kaelthir) then
        call KillUnit(Kaelthir)
    endif
endfunction

private function OnChooseMercy takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0023_TEXT, VL_KAELTHIR_0023_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnMercyEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function OnFeedManaEnd takes nothing returns nothing
    local real x
    local real y
    local real facing
    local unit wraith = null
    local player owner = null
    if HeroItemCheckBoth(ITEM_MANA_CRYSTAL, 1) then
        set x = GetUnitX(Kaelthir)
        set y = GetUnitY(Kaelthir)
        set facing = GetUnitFacing(Kaelthir)
        call QuestGiver_RemoveHeroItemsEither(ITEM_MANA_CRYSTAL, 0, 1)
        call CompleteHungerChoice(HUNGER_OUTCOME_WRAITH)
        call StartExitFadeOut()
        set owner = Player(HOSTILE_OWNER)
        set wraith = CreateUnit(owner, UNIT_MANA_WRAITH, x, y, facing)
        call RemoveUnit(Kaelthir)
    else
        call StartExitFadeOut()
    endif
    set wraith = null
    set owner = null
endfunction

private function OnChooseFeedMana takes nothing returns nothing
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0024_TEXT, VL_KAELTHIR_0024_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFeedManaEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function OnAradionOutcomeEnd takes nothing returns nothing
    local QuestData q = GetHungerQuest()
    if q != 0 then
        call q.removeReturnRequirement()
    endif
    call CompleteHungerChoice(HUNGER_OUTCOME_ARADION)
    call StartExitFadeOut()
    set HungerAradionSequenceActive = false
    if DialogInteraction_IsUnitAlive(Kaelthir) then
        call KillUnit(Kaelthir)
    endif
    set q = 0
endfunction

private function PlayAradionOutcome takes nothing returns nothing
    local integer seq
    if HungerAradionSequenceActive then
        return
    endif
    set HungerAradionSequenceActive = true
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Kaelthir, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogInteraction_BeginDialogSequence()
    call DialogSystem_MakeFaceEachOther(Kaelthir, Aradion, 0.00)
    set seq = DialogInteraction_CreateBaseSequence(Kaelthir, KAELTHIR_NAME)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0025_TEXT, VL_KAELTHIR_0025_KEY, true)
    call DialogSystem_AddLine(seq, Aradion, ARADION_NAME, VL_KAELTHIR_0031_TEXT, VL_KAELTHIR_0031_KEY, true)
    call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0026_TEXT, VL_KAELTHIR_0026_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnAradionOutcomeEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
endfunction

private function CheckHungerEscort takes nothing returns nothing
    local QuestData q = GetHungerQuest()
    call SyncUnitReferences()
    if not HungerEscortActive then
        set q = 0
        return
    endif
    if q == 0 or not q.active or q.completed or q.failed then
        call StopHungerEscort()
        set q = 0
        return
    endif
    if DialogInteraction_IsUnitAlive(Kaelthir) and DialogInteraction_IsUnitAlive(Aradion) and RectContainsUnit(gg_rct_AradionPlace, Kaelthir) then
        call q.markRequirementCompleted(HUNGER_OUTCOME_ARADION, true)
        call StopHungerEscort()
        call PlayAradionOutcome()
    endif
    set q = 0
endfunction

private function OnChooseAradion takes nothing returns nothing
    local QuestData q = GetHungerQuest()
    call SyncUnitReferences()
    if q != 0 and q.active and not q.completed and not q.failed and not HungerEscortActive and DialogInteraction_IsUnitAlive(Aradion) then
        set HungerEscortActive = true
        call QuestGiver_AddCompanion(Kaelthir, KAELTHIR_COMPANION_ICON)
        call SetUnitInvulnerable(Kaelthir, true)
        call QuestGiver_RegisterEscortRequirement(q.id, Kaelthir, HUNGER_OUTCOME_ARADION, Kaelthir, gg_rct_AradionPlace, ARADION_NAME)
        call TimerStart(HungerEscortTimer, 0.25, true, function CheckHungerEscort)
    endif
    call StartExitFadeOut()
    set q = 0
endfunction

private function OnFarewellEnd takes nothing returns nothing
    call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
    local unit hero = ResolveDialogHero()
    local integer seq
    call DialogInteraction_BeginDialogSequence()
    set seq = DialogInteraction_CreateFarewellSequence(Kaelthir, KAELTHIR_NAME, hero, DialogInteraction_GetHeroName(hero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Kaelthir)
    set hero = null
endfunction

private function BuildDialog takes nothing returns nothing
    local QuestData hunger
    local button b = null
    if KaelthirDialog == null then
        set KaelthirDialog = DialogSystem_CreateDialog(KAELTHIR_NAME)
    endif
    call QuestGiver_RefreshAvailabilityForGiver(Kaelthir)
    call DialogSystem_ClearDialog(KaelthirDialog)
    call DialogSystem_SetTitle(KaelthirDialog, KAELTHIR_NAME)
    call QuestGiver_AddAvailableQuestAcceptButton(KaelthirDialog, QUEST_STRUGGLE, Kaelthir, 1, function OnAcceptStruggle, true, false)
    call QuestGiver_AddReadyQuestCompleteButton(KaelthirDialog, QUEST_STRUGGLE, Kaelthir, 2, function OnCompleteStruggle, true)
    call QuestGiver_AddAvailableQuestAcceptButton(KaelthirDialog, QUEST_HUNGER, Kaelthir, 3, function OnAcceptHunger, true, false)

    set hunger = GetHungerQuest()
    if hunger != 0 and hunger.active and not hunger.completed and not hunger.failed and not HungerEscortActive then
        set b = DialogSystem_AddButton(KaelthirDialog, "Kaelthir's Hunger: grant mercy", 4)
        call DialogSystem_BindButtonCode(b, function OnChooseMercy)
        set b = null
        if HeroItemCheckBoth(ITEM_MANA_CRYSTAL, 1) then
            set b = DialogSystem_AddButton(KaelthirDialog, "Kaelthir's Hunger: feed mana crystal", 5)
            call DialogSystem_BindButtonCode(b, function OnChooseFeedMana)
            set b = null
        endif
        if DialogInteraction_IsUnitAlive(Aradion) then
            set b = DialogSystem_AddButton(KaelthirDialog, "Kaelthir's Hunger: seek Aradion's aid", 6)
            call DialogSystem_BindButtonCode(b, function OnChooseAradion)
            set b = null
        endif
    endif

    set b = DialogSystem_AddFarewellButton(KaelthirDialog)
    call DialogSystem_BindButtonCode(b, function OnFarewell)
    set b = null
    set hunger = 0
endfunction

private function AddPreDialogBark takes integer seq returns nothing
    local QuestData struggle = GetStruggleQuest()
    local QuestData hunger = GetHungerQuest()
    local integer roll
    if struggle != 0 and struggle.active and struggle.state != QUEST_STATE_READY_TURNIN then
        set roll = GetRandomInt(1, 2)
        if roll == 1 then
            call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0012_TEXT, VL_KAELTHIR_0012_KEY, true)
        else
            call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0013_TEXT, VL_KAELTHIR_0013_KEY, true)
        endif
    elseif hunger != 0 and hunger.active then
        call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0020_TEXT, VL_KAELTHIR_0020_KEY, true)
    else
        set roll = GetRandomInt(1, 3)
        if roll == 1 then
            call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0001_TEXT, VL_KAELTHIR_0001_KEY, true)
        elseif roll == 2 then
            call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0002_TEXT, VL_KAELTHIR_0002_KEY, true)
        else
            call DialogSystem_AddLine(seq, Kaelthir, KAELTHIR_NAME, VL_KAELTHIR_0004_TEXT, VL_KAELTHIR_0004_KEY, true)
        endif
    endif
    set struggle = 0
    set hunger = 0
endfunction

private function PlayDialogGreeting takes unit hero returns nothing
    local integer seq = DialogInteraction_CreateGreetSequenceBase(Kaelthir, KAELTHIR_NAME, hero, DIALOG_FADE_OUT, DIALOG_FADE_IN, true)
    call AddPreDialogBark(seq)
    call DialogInteraction_PlayGreetSequenceEx(seq, Kaelthir, Player(0), KaelthirDialog, CINEMATIC)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
    local unit hero
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Kaelthir) then
        call StartExitFadeOut()
        set hero = null
        return
    endif
    set hero = ResolveDialogHero()
    if hero == null then
        call StartExitFadeOut()
        set hero = null
        return
    endif
    call BuildDialog()
    call PlayDialogGreeting(hero)
    set hero = null
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
    call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
    call SyncUnitReferences()
    if not DialogInteraction_IsUnitAlive(Kaelthir) then
        return
    endif
    set SelectedHero = DialogInteraction_GetDialogSelectionHero(Kaelthir, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
    if not DialogInteraction_PassDialogSelectionGate(Kaelthir, SelectedHero, DIALOG_RANGE, KaelthirDialogCooldown, true, true, true, true, false, false) then
        call DebugMsg("Selection blocked: " + DialogInteraction_GetLastSelectionBlockReason())
        set SelectedHero = null
        return
    endif
    call DialogInteraction_StartConfiguredDialogEntryTransition(Kaelthir, SelectedHero, true, USE_DIALOG_CAMERA, CINEMATIC, "qKaelthir_ContinueToDialogAfterSelection")
endfunction

private function CreateQuests takes nothing returns nothing
    local QuestData q
    local string infoText = "|cffffcc00Quest giver:|r " + KAELTHIR_NAME + "\n|cffffcc00Zone:|r Vanguard Vale (9)\n"
    local string info2Text = "|cffffcc00Recommended level:|r 18\n\n"

    // The Struggle metadata export was overwritten by a duplicate Hunger export;
    // its one-crystal objective survives in the dialog and completion triggers.
    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_STRUGGLE, Kaelthir) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_STRUGGLE, Kaelthir, "normal", 18, null, QUEST_STRUGGLE, "ReplaceableTextures\\CommandButtons\\BTNDevourMagic.blp", "Kaelthir is resisting the magical hunger consuming Elarindor's wretched. Bring him a mana crystal before he loses himself.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", KAELTHIR_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "", "Bring 1 Mana Crystal to Kaelthir", "", "", "", "", "", "", "")
        call QuestGiver_RegisterItemRequirement(q.id, Kaelthir, 1, ITEM_MANA_CRYSTAL, 1)
    endif

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_HUNGER, Kaelthir) then
        set q = QuestGiver_CreateConfiguredQuest(QUEST_HUNGER, Kaelthir, "normal", 18, null, QUEST_HUNGER, "ReplaceableTextures\\CommandButtons\\BTNDevourMagic.blp", "Kaelthir's condition has become desperate. Decide whether to grant him mercy, feed his hunger, or seek Aradion's aid.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", KAELTHIR_NAME)
        call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(q, "story")
        call QuestGiver_SetRequirements(q.id, "Choose one outcome", "Option 1: Mercy kill Kaelthir", "Option 2: Feed a Mana Crystal to Kaelthir", "Option 3: Bring Kaelthir to Aradion", "", "", "", "", "")
        call QuestGiver_AddQuestPrerequisite(q, QUEST_STRUGGLE, Kaelthir)
    endif
    set q = 0
endfunction

private function RegisterDialogLines takes nothing returns nothing
    call DialogSystem_RegisterFarewellLineForUnit(Kaelthir, VL_KAELTHIR_0005_TEXT, VL_KAELTHIR_0005_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(Kaelthir, VL_KAELTHIR_0006_TEXT, VL_KAELTHIR_0006_KEY, true)
    call DialogSystem_RegisterFarewellLineForUnit(Kaelthir, VL_KAELTHIR_0007_TEXT, VL_KAELTHIR_0007_KEY, true)
endfunction

private function InitDelayed takes nothing returns nothing
    call SyncUnitReferences()
    if Kaelthir == null or Nazgrek == null then
        if not KaelthirInitWaitingLogged then
            call DebugMsg("Waiting for Kaelthir and Nazgrek.")
            set KaelthirInitWaitingLogged = true
        endif
        call TimerStart(KaelthirInitTimer, 0.50, false, function InitDelayed)
        return
    endif
    call PauseTimer(KaelthirInitTimer)
    call DestroyTimer(KaelthirInitTimer)
    set KaelthirInitTimer = null
    call QuestGiver_Register(Kaelthir)
    call DialogInteraction_ConfigureDialogTransition(Kaelthir, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
    call CreateQuests()
    call RegisterDialogLines()
    call DialogInteraction_RegisterSelectionHandler(Kaelthir, function OnSelected)
    call QuestGiver_RefreshAvailabilityForGiver(Kaelthir)
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set KaelthirDialogCooldown = CreateTimer()
    set HungerEscortTimer = CreateTimer()
    set KaelthirInitTimer = CreateTimer()
    call TimerStart(KaelthirInitTimer, 0.00, false, function InitDelayed)
endfunction

public function GetHungerOutcome takes nothing returns integer
    local QuestData q = GetHungerQuest()
    local integer outcome = HUNGER_OUTCOME_NONE
    if q != 0 and q.completed then
        if q.req1Completed then
            set outcome = HUNGER_OUTCOME_MERCY
        elseif q.req2Completed then
            set outcome = HUNGER_OUTCOME_WRAITH
        elseif q.req3Completed then
            set outcome = HUNGER_OUTCOME_ARADION
        endif
    endif
    set q = 0
    return outcome
endfunction

public function RefreshAvailability takes nothing returns nothing
    call SyncUnitReferences()
    if Kaelthir != null then
        call QuestGiver_RefreshAvailabilityForGiver(Kaelthir)
    endif
endfunction

public function RefreshRespawnedUnitHooks takes nothing returns nothing
    call SyncUnitReferences()
    if Kaelthir != null and DialogInteraction_IsUnitAlive(Kaelthir) then
        call QuestGiver_Register(Kaelthir)
        call DialogInteraction_ConfigureDialogTransition(Kaelthir, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(Kaelthir, function OnSelected)
        call RefreshAvailability()
    endif
endfunction

endlibrary
