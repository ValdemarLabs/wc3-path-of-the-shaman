/**
    QuestsGenericDialog

    Author: Valdemar
    Version: 1.0.2

    Description:
    Provides a standalone selection dialog for non-vendor QuestsGeneric NPCs
    and notice-board units. Wanted posts are preplaced World Editor units
    registered by exact handle; this library never creates or discovers them.
    It intentionally has no Shop dependency. Register only units that do not
    already own a bespoke selection handler.

    Credits:

    How to install:
    Import after QuestsGeneric, DialogInteraction, DialogSystem, and Table.
    Register preplaced giver and receiver units after their definitions exist.
    Custom qXXX dialogs should call QuestsGeneric_AddDialogButtons and the
    matching action APIs instead of registering through this library.

    API:
    - QuestsGenericDialog_WANTED_POST_UNIT_TYPE
    - QuestsGenericDialog_RegisterNPC(unit, displayName)
    - QuestsGenericDialog_RegisterNoticeBoard(unit, displayName)
    - QuestsGenericDialog_RegisterWantedPost(unit, displayName)
    - QuestsGenericDialog_GetSelectedUnit()
    - QuestsGenericDialog_GetSelectedHero()

**/
library QuestsGenericDialog initializer Init requires QuestsGeneric, DialogInteraction, DialogSystem, Table
    globals
        public constant integer WANTED_POST_UNIT_TYPE = 'n05N'

        private constant real DIALOG_RANGE = 900.00
        private constant real DIALOG_COOLDOWN = 3.00
        private constant boolean ALLOW_NAZGREK = true
        private constant boolean ALLOW_ZULKIS = true
        private constant boolean USE_DIALOG_CAMERA = true
        private constant boolean CINEMATIC = true
        private constant integer CINEMATIC_MOVE_MODE = 1
        private constant real CINEMATIC_MOVE_OFFSET = 256.00
        private constant real CINEMATIC_MOVE_ANGLE = 210.00
        private constant real CAMERA_DIST = 950.00
        private constant real CAMERA_Z_OFFSET = 60.00
        private constant real CAMERA_ANGLE = 340.00
        private constant real CAMERA_ROT_OFFSET = 180.00
        private constant real CAMERA_FAR_Z = 10000.00
        private constant real CAMERA_FOV = 60.00
        private constant real CAMERA_BLOCK_RADIUS = 160.00
        private constant boolean CAMERA_BLOCK_CHECK = true

        private constant integer ACTION_EXIT = 1

        private dialog QuestDialog = null
        private timer DialogCooldown = null
        private timer DeferredEndTimer = null
        private Table RegisteredUnit = 0
        private Table NoticeBoard = 0
        private Table DisplayName = 0
        private unit SelectedUnit = null
        private unit SelectedHero = null
        private boolean DeferredEndStartsCooldown = false
    endglobals

    private function GetDisplayName takes unit whichUnit returns string
        local string displayName

        if whichUnit == null then
            return "Quest giver"
        endif
        set displayName = DisplayName.string[GetHandleId(whichUnit)]
        if displayName == null or displayName == "" then
            set displayName = GetUnitName(whichUnit)
        endif
        set whichUnit = null
        return displayName
    endfunction

    private function IsSelectedContextValid takes nothing returns boolean
        return SelectedUnit != null and SelectedHero != null and DialogInteraction_IsUnitAlive(SelectedUnit) and DialogInteraction_IsUnitAlive(SelectedHero)
    endfunction

    private function EndDialog takes boolean startCooldown returns nothing
        local unit hero = SelectedHero

        call DialogInteraction_EndCombatSensitiveInteraction()
        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(QuestDialog, Player(0))
        call DialogSystem_StopDialogCamera(Player(0), 0.75, USE_DIALOG_CAMERA)
        call DialogInteraction_EndCinematicSequence(CINEMATIC)
        if startCooldown then
            set DialogCooldown = DialogInteraction_StartCooldown(DialogCooldown, DIALOG_COOLDOWN)
        endif
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, GetOwningPlayer(hero))
        endif
        set SelectedUnit = null
        set SelectedHero = null
        set hero = null
    endfunction

    private function EndDialogDeferred takes nothing returns nothing
        if SelectedUnit != null or SelectedHero != null then
            call EndDialog(DeferredEndStartsCooldown)
        endif
        set DeferredEndStartsCooldown = false
    endfunction

    private function QueueEndDialog takes boolean startCooldown returns nothing
        set DeferredEndStartsCooldown = startCooldown
        call TimerStart(DeferredEndTimer, 0.01, false, function EndDialogDeferred)
    endfunction

    private function InterruptDialog takes nothing returns nothing
        if SelectedUnit == null and SelectedHero == null then
            return
        endif
        call DialogSystem_CancelActiveSpeech()
        call QuestsGeneric_CancelPendingAction()
        call EndDialog(true)
    endfunction

    private function OnQuestSequenceEnd takes nothing returns nothing
        call QuestsGeneric_FinishPendingAction()
        call EndDialog(true)
    endfunction

    private function OnQuestAction takes nothing returns nothing
        local integer seq

        if not IsSelectedContextValid() then
            call EndDialog(true)
            return
        endif
        set seq = QuestsGeneric_BeginAction(DialogSystem_LastAction, SelectedUnit, GetDisplayName(SelectedUnit), SelectedHero)
        if seq > 0 then
            call DialogInteraction_BeginDialogSequence()
            call DialogSystem_SetSequenceCallbacks(seq, null, function OnQuestSequenceEnd)
            call DialogSystem_PlaySequence(seq, GetOwningPlayer(SelectedHero), SelectedUnit)
        else
            call QuestsGeneric_CancelPendingAction()
            call QueueEndDialog(true)
        endif
    endfunction

    private function OnFarewellEnd takes nothing returns nothing
        call EndDialog(true)
    endfunction

    private function OnEscape takes nothing returns nothing
        call QuestsGeneric_CancelPendingAction()
        call QueueEndDialog(true)
    endfunction

    private function OnFarewell takes nothing returns nothing
        local integer seq

        if not IsSelectedContextValid() then
            call EndDialog(true)
            return
        endif
        if NoticeBoard.boolean[GetHandleId(SelectedUnit)] then
            call QueueEndDialog(true)
            return
        endif
        set seq = DialogInteraction_CreateFarewellSequence(SelectedUnit, GetDisplayName(SelectedUnit), SelectedHero, DialogInteraction_GetHeroName(SelectedHero), DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        call DialogInteraction_BeginDialogSequence()
        call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
        call DialogSystem_PlaySequence(seq, GetOwningPlayer(SelectedHero), SelectedUnit)
    endfunction

    private function BuildDialog takes nothing returns nothing
        local button b
        local string title

        if SelectedUnit == null then
            set b = null
            return
        endif
        set title = GetDisplayName(SelectedUnit)
        if QuestDialog == null then
            set QuestDialog = DialogSystem_CreateDialog(title)
        endif
        call QuestGiver_RefreshAvailabilityForGiver(SelectedUnit)
        call DialogSystem_ClearDialog(QuestDialog)
        call DialogSystem_SetTitle(QuestDialog, title)
        call QuestsGeneric_AddDialogButtons(QuestDialog, SelectedUnit, function OnQuestAction)
        set b = DialogSystem_AddButtonExit(QuestDialog, ACTION_EXIT)
        call DialogSystem_BindButtonCode(b, function OnFarewell)
        set b = null
    endfunction

    private function CreateGreetSequence takes nothing returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string speakerName = GetDisplayName(SelectedUnit)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, SelectedUnit, speakerName)
        if NoticeBoard.boolean[GetHandleId(SelectedUnit)] then
            call DialogSystem_AddLineNoSound(seq, SelectedUnit, speakerName, "Several requests and bounties are posted here.")
        else
            call DialogSystem_AddMakeFaceEachOther(seq, SelectedUnit, SelectedHero, 0.45, 0.00)
            if DialogSystem_PickGreetLine(SelectedUnit, speakerName) then
                call DialogSystem_AddLine(seq, SelectedUnit, speakerName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
            else
                call DialogSystem_AddLineNoSound(seq, SelectedUnit, speakerName, "What do you need?")
            endif
        endif
        return seq
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        local integer seq

        if not IsSelectedContextValid() then
            call EndDialog(false)
            return
        endif
        call BuildDialog()
        call DialogSystem_SetEscapeAction(function OnEscape)
        set seq = CreateGreetSequence()
        call DialogInteraction_PlayGreetSequenceEx(seq, SelectedUnit, GetOwningPlayer(SelectedHero), QuestDialog, CINEMATIC)
    endfunction

    private function OnSelected takes nothing returns nothing
        local unit whichUnit = DialogInteraction_GetSelectedUnit()
        local unit hero

        if whichUnit == null or not RegisteredUnit.boolean[GetHandleId(whichUnit)] then
            set whichUnit = null
            set hero = null
            return
        endif
        set hero = DialogInteraction_GetDialogSelectionHero(whichUnit, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
        if not DialogInteraction_PassDialogSelectionGate(whichUnit, hero, DIALOG_RANGE, DialogCooldown, true, true, false, false, false, true) then
            set whichUnit = null
            set hero = null
            return
        endif
        set SelectedUnit = whichUnit
        set SelectedHero = hero
        if not DialogInteraction_BeginCombatSensitiveInteractionEx(whichUnit, hero, function InterruptDialog, true) then
            set SelectedUnit = null
            set SelectedHero = null
            set whichUnit = null
            set hero = null
            return
        endif
        call DialogInteraction_StartConfiguredDialogEntryTransition(whichUnit, hero, false, USE_DIALOG_CAMERA, CINEMATIC, "QuestsGenericDialog_ContinueToDialogAfterSelection")
        set whichUnit = null
        set hero = null
    endfunction

    private function Register takes unit whichUnit, string displayName, boolean isNoticeBoard returns nothing
        local integer handleId

        if whichUnit == null or not DialogInteraction_IsUnitAlive(whichUnit) then
            set whichUnit = null
            return
        endif
        set handleId = GetHandleId(whichUnit)
        set RegisteredUnit.boolean[handleId] = true
        set NoticeBoard.boolean[handleId] = isNoticeBoard
        set DisplayName.string[handleId] = displayName
        call QuestsGeneric_RegisterUnit(whichUnit, displayName)
        call DialogInteraction_ConfigureDialogTransition(whichUnit, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
        call DialogInteraction_RegisterSelectionHandler(whichUnit, function OnSelected)
        set whichUnit = null
    endfunction

    public function RegisterNPC takes unit whichUnit, string displayName returns nothing
        call Register(whichUnit, displayName, false)
        set whichUnit = null
    endfunction

    public function RegisterNoticeBoard takes unit whichUnit, string displayName returns nothing
        call Register(whichUnit, displayName, true)
        set whichUnit = null
    endfunction

    public function RegisterWantedPost takes unit whichUnit, string displayName returns nothing
        if whichUnit == null or GetUnitTypeId(whichUnit) != WANTED_POST_UNIT_TYPE then
            set whichUnit = null
            return
        endif
        call Register(whichUnit, displayName, true)
        set whichUnit = null
    endfunction

    public function GetSelectedUnit takes nothing returns unit
        return SelectedUnit
    endfunction

    public function GetSelectedHero takes nothing returns unit
        return SelectedHero
    endfunction

    private function Init takes nothing returns nothing
        set DialogCooldown = CreateTimer()
        set DeferredEndTimer = CreateTimer()
        set RegisteredUnit = Table.create()
        set NoticeBoard = Table.create()
        set DisplayName = Table.create()
    endfunction
endlibrary
