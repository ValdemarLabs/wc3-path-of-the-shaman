/**
    AbilityTrainerDialogs

    Author: Valdemar
    Version:

    Description:
    Dialog/cinematic entry layer for shaman ability trainers. Selecting a
    trainer starts the normal DialogInteraction cinematic transition, plays a short
    trainer greeting sequence, then opens a dialog with Learn and Farewell.
    Quest libraries can register dialog builders to add trainer quest buttons.

    Credits:

    How to install:
    Import after DialogInteraction, DialogSystem, DialogSystemPlayer, AbilitiesUI,
    AbilitiesPlayer, AbilityTrainerLines, Interface, and Events.

    API:
    - call AbilityTrainerDialogs_RegisterDialogBuilder(function MyBuilder)
    - set d = AbilityTrainerDialogs_GetDialog()
    - set trainer = AbilityTrainerDialogs_GetSelectedTrainer()
    - set hero = AbilityTrainerDialogs_GetSelectedHero()
    - set treeId = AbilityTrainerDialogs_GetSelectedTree()

**/
library AbilityTrainerDialogs initializer Init requires Table, DialogInteraction, DialogSystem, DialogSystemPlayer, AbilitiesPlayer, AbilitiesUI, AbilityTrainerLines, Interface, optional Events
    globals
        private constant real ATD_DIALOG_RANGE = 900.00
        private constant real ATD_DIALOG_COOLDOWN = 3.00
        private constant boolean ATD_REQUIRE_DIALOG_HERO = true
        private constant boolean ATD_ALLOW_NAZGREK = true
        private constant boolean ATD_ALLOW_ZULKIS = true
        private constant boolean ATD_USE_DIALOG_CAMERA = true
        private constant boolean ATD_CINEMATIC = true
        private constant integer ATD_CINEMATIC_MOVE_MODE = 1
        private constant real ATD_CINEMATIC_MOVE_OFFSET = 256.00
        private constant real ATD_CINEMATIC_MOVE_ANGLE = 210.00
        private constant real ATD_CAMERA_DIST = 950.00
        private constant real ATD_CAMERA_Z_OFFSET = 90.00
        private constant real ATD_CAMERA_ANGLE = 328.00
        private constant real ATD_CAMERA_ROT_OFFSET = 180.00
        private constant real ATD_CAMERA_FAR_Z = 10000.00
        private constant real ATD_CAMERA_FOV = 60.00
        private constant real ATD_CAMERA_BLOCK_RADIUS = 0.00
        private constant boolean ATD_CAMERA_BLOCK_CHECK = false
        private constant real ATD_CAMERA_RESET_TIME = 0.75

        private constant integer ATD_ACTION_LEARN = 1
        private constant integer ATD_ACTION_FAREWELL = 2
        private constant integer ATD_MAX_DIALOG_BUILDERS = 16

        private dialog ATD_Dialog = null
        private unit ATD_SelectedTrainer = null
        private unit ATD_SelectedHero = null
        private timer ATD_DialogCooldown = null
        private Table ATD_RegisteredTrainer = 0
        private trigger array ATD_DialogBuilderTrigger
        private integer ATD_DialogBuilderCount = 0
    endglobals

    public function GetDialog takes nothing returns dialog
        return ATD_Dialog
    endfunction

    public function GetSelectedTrainer takes nothing returns unit
        return ATD_SelectedTrainer
    endfunction

    public function GetSelectedHero takes nothing returns unit
        return ATD_SelectedHero
    endfunction

    public function GetSelectedTree takes nothing returns integer
        if ATD_SelectedTrainer == null then
            return AbilitiesPlayer_TREE_NONE
        endif
        return AbilitiesPlayer_GetTrainerTreeByUnitType(GetUnitTypeId(ATD_SelectedTrainer))
    endfunction

    public function RegisterDialogBuilder takes code builderFunc returns nothing
        local trigger builderTrigger

        if builderFunc == null or ATD_DialogBuilderCount >= ATD_MAX_DIALOG_BUILDERS then
            set builderTrigger = null
            return
        endif

        set ATD_DialogBuilderCount = ATD_DialogBuilderCount + 1
        set builderTrigger = CreateTrigger()
        call TriggerAddAction(builderTrigger, builderFunc)
        set ATD_DialogBuilderTrigger[ATD_DialogBuilderCount] = builderTrigger

        set builderTrigger = null
    endfunction

    private function ATD_IsSelectedContextValid takes nothing returns boolean
        return ATD_SelectedTrainer != null and ATD_SelectedHero != null and DialogInteraction_IsUnitAlive(ATD_SelectedTrainer) and DialogInteraction_IsUnitAlive(ATD_SelectedHero)
    endfunction

    private function ATD_AddRegisteredDialogButtons takes nothing returns nothing
        local integer builderIndex = 1
        local trigger builderTrigger

        loop
            exitwhen builderIndex > ATD_DialogBuilderCount
            set builderTrigger = ATD_DialogBuilderTrigger[builderIndex]
            if builderTrigger != null then
                call TriggerExecute(builderTrigger)
            endif
            set builderIndex = builderIndex + 1
        endloop

        set builderTrigger = null
    endfunction

    private function ATD_ReportSelectionFailure takes unit trainer returns nothing
        local string reason = DialogInteraction_GetLastSelectionBlockReason()

        if reason == "missing allowed hero" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080No player shaman hero found near the " + AbilityTrainerLines_GetTrainerName(trainer) + ".|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        elseif reason == "hero out of range" then
            call DisplayTextToPlayer(Player(0), 0.00, 0.00, "|cffff8080Move closer to the " + AbilityTrainerLines_GetTrainerName(trainer) + ".|r")
            call Interface_PlayEventSoundForPlayer(Interface_EVENT_ERROR, Player(0))
        endif
    endfunction

    private function ATD_CreateGreetSequence takes unit trainer, unit hero returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string trainerName = AbilityTrainerLines_GetTrainerName(trainer)
        local string heroName = DialogInteraction_GetHeroName(hero)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, trainer, trainerName)
        call DialogSystem_AddMakeFaceEachOther(seq, trainer, hero, 0.50, 0.00)

        call DialogSystem_PickGreetLine(trainer, trainerName)
        call DialogSystem_AddLine(seq, trainer, trainerName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        call DialogSystem_AddDelay(seq, 0.20)
        call DialogSystem_PickGreetTrainerLine(hero, heroName)
        call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function ATD_CreateFarewellSequence takes unit trainer, unit hero returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string trainerName = AbilityTrainerLines_GetTrainerName(trainer)
        local string heroName = DialogInteraction_GetHeroName(hero)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, trainer, trainerName)
        call DialogSystem_AddMakeFaceEachOther(seq, trainer, hero, 0.50, 0.00)

        call DialogSystem_PickFarewellTrainerLine(hero, heroName)
        call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        call DialogSystem_AddDelay(seq, 0.20)
        call DialogSystem_PickFarewellLine(trainer, trainerName)
        call DialogSystem_AddLine(seq, trainer, trainerName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function ATD_GetHeroCameraRotationOffset takes unit trainer, unit hero returns real
        local real dx
        local real dy

        if trainer == null or hero == null then
            return ATD_CAMERA_ROT_OFFSET
        endif

        set dx = GetUnitX(hero) - GetUnitX(trainer)
        set dy = GetUnitY(hero) - GetUnitY(trainer)
        if dx * dx + dy * dy < 1.00 then
            return ATD_CAMERA_ROT_OFFSET
        endif

        return (Atan2(dy, dx) * bj_RADTODEG + 180.00) - GetUnitFacing(trainer)
    endfunction

    private function ATD_ConfigureTrainerCamera takes unit trainer, unit hero returns nothing
        if trainer == null then
            return
        endif

        call DialogInteraction_ConfigureDialogTransition(trainer, ATD_CINEMATIC_MOVE_MODE, ATD_CINEMATIC_MOVE_OFFSET, ATD_CINEMATIC_MOVE_ANGLE, ATD_CAMERA_DIST, ATD_CAMERA_Z_OFFSET, ATD_CAMERA_ANGLE, ATD_GetHeroCameraRotationOffset(trainer, hero), ATD_CAMERA_FAR_Z, ATD_CAMERA_FOV, ATD_CAMERA_BLOCK_RADIUS, ATD_CAMERA_BLOCK_CHECK)
    endfunction

    private function ATD_StartTrainerCamera takes unit trainer, unit hero returns nothing
        if trainer == null then
            return
        endif

        call DialogSystem_StartDialogCamera(Player(0), trainer, ATD_CAMERA_DIST, ATD_CAMERA_Z_OFFSET, ATD_CAMERA_ANGLE, ATD_GetHeroCameraRotationOffset(trainer, hero), ATD_CAMERA_FAR_Z, ATD_CAMERA_FOV, ATD_CAMERA_BLOCK_RADIUS, ATD_CAMERA_BLOCK_CHECK, ATD_USE_DIALOG_CAMERA)
    endfunction

    private function ATD_EndTrainerDialog takes boolean startCooldown returns nothing
        local unit hero = ATD_SelectedHero

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(ATD_Dialog, Player(0))
        call DialogSystem_StopDialogCamera(Player(0), ATD_CAMERA_RESET_TIME, ATD_USE_DIALOG_CAMERA)
        call DialogInteraction_EndCinematicSequence(ATD_CINEMATIC)

        if startCooldown then
            set ATD_DialogCooldown = DialogInteraction_StartCooldown(ATD_DialogCooldown, ATD_DIALOG_COOLDOWN)
        endif
        if hero != null and DialogInteraction_IsUnitAlive(hero) then
            call ShowUnit(hero, true)
            call PauseUnit(hero, false)
            call SelectUnitForPlayerSingle(hero, Player(0))
        endif

        set hero = null
    endfunction

    private function ATD_OnLearn takes nothing returns nothing
        local unit trainer = ATD_SelectedTrainer
        local unit hero = ATD_SelectedHero

        call DialogSystem_ClearEscapeAction()
        call DialogSystem_HideDialog(ATD_Dialog, Player(0))

        if trainer != null and hero != null then
            call ShowUnit(hero, true)
            call AbilitiesUI_ShowForTrainer(trainer, hero)
        endif

        set trainer = null
        set hero = null
    endfunction

    private function ATD_OnFarewellEnd takes nothing returns nothing
        call ATD_EndTrainerDialog(true)
    endfunction

    private function ATD_OnFarewell takes nothing returns nothing
        local integer seq

        if not ATD_IsSelectedContextValid() then
            call ATD_EndTrainerDialog(true)
            return
        endif

        call DialogInteraction_BeginDialogSequence()
        set seq = ATD_CreateFarewellSequence(ATD_SelectedTrainer, ATD_SelectedHero)
        call DialogSystem_SetSequenceCallbacks(seq, null, function ATD_OnFarewellEnd)
        call DialogSystem_PlaySequence(seq, Player(0), ATD_SelectedTrainer)
    endfunction

    private function ATD_BuildDialog takes nothing returns nothing
        local button b
        local string trainerName

        if ATD_SelectedTrainer == null then
            set b = null
            return
        endif

        set trainerName = AbilityTrainerLines_GetTrainerName(ATD_SelectedTrainer)
        if ATD_Dialog == null then
            set ATD_Dialog = DialogSystem_CreateDialog(trainerName)
        endif

        call DialogSystem_ClearDialog(ATD_Dialog)
        call DialogSystem_SetTitle(ATD_Dialog, trainerName)

        set b = DialogSystem_AddButton(ATD_Dialog, "Learn", ATD_ACTION_LEARN)
        call DialogSystem_BindButtonCode(b, function ATD_OnLearn)

        call ATD_AddRegisteredDialogButtons()

        set b = DialogSystem_AddButton(ATD_Dialog, "Farewell", ATD_ACTION_FAREWELL)
        call DialogSystem_SetButtonInterfaceEvent(b, Interface_EVENT_DIALOG_BUTTON_CLOSE)
        call DialogSystem_BindButtonCode(b, function ATD_OnFarewell)

        set b = null
    endfunction

    public function ReopenFromAbilitiesUI takes nothing returns nothing
        if not ATD_IsSelectedContextValid() then
            call ATD_EndTrainerDialog(false)
            return
        endif

        call ATD_BuildDialog()
        call DialogInteraction_BeginCinematicSequence(ATD_CINEMATIC)
        call ATD_StartTrainerCamera(ATD_SelectedTrainer, ATD_SelectedHero)
        call DialogSystem_SetContext(ATD_SelectedTrainer, Player(0))
        call DialogSystem_ShowDialog(ATD_Dialog, Player(0))
    endfunction

    private function ATD_ShowDialogForSelection takes nothing returns nothing
        local integer seq

        if not ATD_IsSelectedContextValid() then
            call ATD_EndTrainerDialog(false)
            return
        endif

        call ATD_BuildDialog()
        set seq = ATD_CreateGreetSequence(ATD_SelectedTrainer, ATD_SelectedHero)
        call DialogInteraction_PlayGreetSequenceEx(seq, ATD_SelectedTrainer, Player(0), ATD_Dialog, ATD_CINEMATIC)
    endfunction

    public function ContinueToDialogAfterSelection takes nothing returns nothing
        call ATD_ShowDialogForSelection()
    endfunction

    private function ATD_OnSelected takes nothing returns nothing
        local unit trainer = DialogInteraction_GetSelectedUnit()
        local unit hero
        local boolean gateOk

        if trainer == null or not AbilitiesPlayer_IsTrainerUnitType(GetUnitTypeId(trainer)) then
            set trainer = null
            set hero = null
            return
        endif

        set hero = DialogInteraction_GetDialogSelectionHero(trainer, ATD_DIALOG_RANGE, ATD_ALLOW_NAZGREK, ATD_ALLOW_ZULKIS)
        set gateOk = DialogInteraction_PassDialogSelectionGate(trainer, hero, ATD_DIALOG_RANGE, ATD_DialogCooldown, ATD_REQUIRE_DIALOG_HERO, true, true, true, false, false)
        if not gateOk then
            call ATD_ReportSelectionFailure(trainer)
            set trainer = null
            set hero = null
            return
        endif

        set ATD_SelectedTrainer = trainer
        set ATD_SelectedHero = hero
        call ATD_ConfigureTrainerCamera(trainer, hero)
        call DialogInteraction_StartConfiguredDialogEntryTransition(trainer, hero, false, ATD_USE_DIALOG_CAMERA, ATD_CINEMATIC, "AbilityTrainerDialogs_ContinueToDialogAfterSelection")

        set trainer = null
        set hero = null
    endfunction

    private function ATD_RegisterTrainer takes unit trainer returns nothing
        local integer handleId

        if trainer == null or not DialogInteraction_IsUnitAlive(trainer) then
            return
        endif
        if not AbilitiesPlayer_IsTrainerUnitType(GetUnitTypeId(trainer)) then
            return
        endif

        set handleId = GetHandleId(trainer)
        if ATD_RegisteredTrainer.boolean[handleId] then
            return
        endif

        set ATD_RegisteredTrainer.boolean[handleId] = true
        call DialogInteraction_Register(trainer)
        call ATD_ConfigureTrainerCamera(trainer, null)
        call DialogInteraction_SetGreetOrder(trainer, DIALOGINTERACTION_GREET_NONE)
        call DialogInteraction_RegisterSelectionHandler(trainer, function ATD_OnSelected)
    endfunction

    private function ATD_RegisterExistingTrainers takes nothing returns nothing
        local group worldUnits = CreateGroup()
        local rect worldBounds = GetWorldBounds()
        local unit enumUnit

        call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
        loop
            set enumUnit = FirstOfGroup(worldUnits)
            exitwhen enumUnit == null
            call GroupRemoveUnit(worldUnits, enumUnit)
            call ATD_RegisterTrainer(enumUnit)
        endloop

        call DestroyGroup(worldUnits)
        call RemoveRect(worldBounds)
        set worldUnits = null
        set worldBounds = null
        set enumUnit = null
    endfunction

    private function ATD_OnUnitEnter takes nothing returns nothing
        call ATD_RegisterTrainer(GetTriggerUnit())
    endfunction

    private function ATD_InitDelayed takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()

        call ATD_RegisterExistingTrainers()
        static if LIBRARY_Events then
            call Events_RegisterUnitEnter(function ATD_OnUnitEnter)
        endif

        call DestroyTimer(expiredTimer)
        set expiredTimer = null
    endfunction

    private function Init takes nothing returns nothing
        local timer initTimer

        set ATD_DialogCooldown = CreateTimer()
        set ATD_RegisteredTrainer = Table.create()
        set initTimer = CreateTimer()
        call TimerStart(initTimer, 0.00, false, function ATD_InitDelayed)
        set initTimer = null
    endfunction
endlibrary
