/**
    DialogInteraction

    Author: Valdemar
    Version:

    Description:
    Generic selectable-NPC dialog interaction layer. This owns NPC selection
    handlers, dialog hero resolution, range/cooldown gates, cinematic dialog
    entry/exit transitions, configured dialog camera data, and generic greet
    playback wrappers.

    Credits:

    How to install:
    Import after DialogSystem, CameraControl, Table, and FullscreenUI. Quest
    systems can keep using QuestGiver for quest data, while non-quest NPCs can
    depend on this library directly.

    API:
    - call DialogInteraction_Register(unit npc)
    - call DialogInteraction_RegisterSelectionHandler(unit npc, function OnSelected)
    - call DialogInteraction_RegisterAnySelectionHandler(function OnAnySelected)
    - call DialogInteraction_ConfigureDialogTransition(...)
    - call DialogInteraction_StartConfiguredDialogEntryTransition(...)
    - call DialogInteraction_CancelActiveTransition()
    - call DialogInteraction_PlayGreetSequenceEx(...)
    - call DialogInteraction_BeginCombatSensitiveInteraction(npc, hero, onInterrupt)
    - call DialogInteraction_BeginCombatSensitiveInteractionEx(npc, hero, onInterrupt, endOnCombat)
    - call DialogInteraction_EndCombatSensitiveInteraction()

**/
library DialogInteraction initializer Init requires Table, DialogSystem, CameraControl, FullscreenUI, FallenHeroState
    globals
        private constant boolean DEBUG = false

        private Table DialogInteraction_SelectHandlers = 0
        private trigger DialogInteraction_SelectTrigger = null
        private trigger DialogInteraction_AnySelectHandlers = null
        private Table DialogInteraction_FirstGreetDone = 0
        private Table DialogInteraction_SkipNextGreet = 0
        private Table DialogInteraction_GreetOrder = 0
        private Table DialogInteraction_DialogTransitionConfig = 0

        private dialog DialogInteraction_PendingDialog = null
        private player DialogInteraction_PendingPlayer = null
        private unit DialogInteraction_PendingNPC = null
        private integer DialogInteraction_PendingSeq = 0
        private boolean DialogInteraction_PendingSequenceCinematic = false
        private string DialogInteraction_ReopenDialogFuncName = ""
        private string DialogInteraction_LastSelectionBlockReason = ""
        unit DialogInteraction_SelectedUnit = null

        private unit TransitionGiver = null
        private unit TransitionHero = null
        private timer TransitionCooldownTimer = null
        private real TransitionCooldownDuration = 0.00
        private boolean TransitionStopCamera = false
        private real TransitionCameraStopDuration = 0.00
        private boolean TransitionUseCamera = false
        private boolean TransitionRunCinematicTrigger = false
        private boolean TransitionUseCinematicMode = false
        private integer TransitionMoveMode = 0
        private real TransitionMoveOffset = 0.00
        private real TransitionMoveAngle = 0.00
        private real TransitionCameraDist = 0.00
        private real TransitionCameraZOffset = 0.00
        private real TransitionCameraAngle = 0.00
        private real TransitionCameraRotOffset = 0.00
        private real TransitionCameraFarZ = 0.00
        private real TransitionCameraFov = 0.00
        private real TransitionCameraBlockRadius = 0.00
        private boolean TransitionCameraBlockCheck = false
        private string TransitionContinueFuncName = ""
        private timer TransitionTimer = null

        private constant real DIALOGINTERACTION_COMBAT_CHECK_INTERVAL = 0.10
        private trigger DialogInteraction_CombatAttackTrigger = null
        private trigger DialogInteraction_CombatInterruptHandler = null
        private timer DialogInteraction_CombatCheckTimer = null
        private unit DialogInteraction_CombatNPC = null
        private unit DialogInteraction_CombatHero = null
        private boolean DialogInteraction_CombatGuardActive = false

        private constant integer DIALOGINTERACTION_TRANSITION_CONFIGURED = 1
        private constant integer DIALOGINTERACTION_TRANSITION_MOVE_MODE = 2
        private constant integer DIALOGINTERACTION_TRANSITION_MOVE_OFFSET = 3
        private constant integer DIALOGINTERACTION_TRANSITION_MOVE_ANGLE = 4
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_DIST = 5
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_Z_OFFSET = 6
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_ANGLE = 7
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_ROT_OFFSET = 8
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_FAR_Z = 9
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_FOV = 10
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_RADIUS = 11
        private constant integer DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_CHECK = 12

        private constant integer DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_MODE = 1
        private constant real DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_OFFSET = 256.00
        private constant real DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_ANGLE = 210.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_DIST = 1050.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_Z_OFFSET = 20.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_ANGLE = 350.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_ROT_OFFSET = 180.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_FAR_Z = 10000.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_FOV = 60.00
        private constant real DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_RADIUS = 0.00
        private constant boolean DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_CHECK = true

        constant integer DIALOGINTERACTION_GREET_DEFAULT = 0
        constant integer DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC = 1
        constant integer DIALOGINTERACTION_GREET_NPC_THEN_NAZGREK = 2
        constant integer DIALOGINTERACTION_GREET_NPC_ONLY = 3
        constant integer DIALOGINTERACTION_GREET_NAZGREK_ONLY = 4
        constant integer DIALOGINTERACTION_GREET_NONE = 5
    endglobals

    private function DebugMsg takes string msg returns nothing
        if DEBUG then
            call BJDebugMsg("[DialogInteraction] " + msg)
        endif
    endfunction

    private function OnUnitSelected takes nothing returns nothing
        local unit u = GetTriggerUnit()
        local trigger t

        set DialogInteraction_SelectedUnit = u
        if u != null and DialogInteraction_SelectHandlers != 0 then
            set t = DialogInteraction_SelectHandlers.trigger[GetHandleId(u)]
            if t != null then
                call TriggerExecute(t)
            endif
        endif
        if u != null and DialogInteraction_AnySelectHandlers != null then
            call TriggerExecute(DialogInteraction_AnySelectHandlers)
        endif
        set DialogInteraction_SelectedUnit = null
        set t = null
        set u = null
    endfunction

    private function EnsureSelectTrigger takes nothing returns nothing
        if DialogInteraction_SelectTrigger == null then
            set DialogInteraction_SelectTrigger = CreateTrigger()
            call TriggerRegisterPlayerUnitEvent(DialogInteraction_SelectTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
            call TriggerAddAction(DialogInteraction_SelectTrigger, function OnUnitSelected)
        endif
    endfunction

    public function RegisterSelectionHandler takes unit u, code handler returns nothing
        local trigger t
        if u == null or handler == null then
            set t = null
            return
        endif
        call EnsureSelectTrigger()
        if DialogInteraction_SelectHandlers == 0 then
            set DialogInteraction_SelectHandlers = Table.create()
        endif
        set t = DialogInteraction_SelectHandlers.trigger[GetHandleId(u)]
        if t != null then
            call DestroyTrigger(t)
        endif
        set t = CreateTrigger()
        call TriggerAddAction(t, handler)
        set DialogInteraction_SelectHandlers.trigger[GetHandleId(u)] = t
        set t = null
    endfunction

    public function RegisterAnySelectionHandler takes code handler returns nothing
        if handler == null then
            return
        endif
        call EnsureSelectTrigger()
        if DialogInteraction_AnySelectHandlers == null then
            set DialogInteraction_AnySelectHandlers = CreateTrigger()
        endif
        call TriggerAddAction(DialogInteraction_AnySelectHandlers, handler)
    endfunction

    public function SetFirstGreetDone takes unit u, boolean flag returns nothing
        local integer id
        if u == null then
            call DebugMsg("SetFirstGreetDone: u is null")
            return
        endif
        if DialogInteraction_FirstGreetDone == 0 then
            set DialogInteraction_FirstGreetDone = Table.create()
        endif
        set id = GetHandleId(u)
        set DialogInteraction_FirstGreetDone.boolean[id] = flag
    endfunction

    public function SuppressNextGreet takes unit u returns nothing
        local integer id
        if u == null then
            return
        endif
        if DialogInteraction_SkipNextGreet == 0 then
            set DialogInteraction_SkipNextGreet = Table.create()
        endif
        set id = GetHandleId(u)
        set DialogInteraction_SkipNextGreet.boolean[id] = true
    endfunction

    public function Register takes unit u returns nothing
        if u == null then
            return
        endif
        call DebugMsg("Register dialog npc id=" + I2S(GetHandleId(u)))
        call SetFirstGreetDone(u, false)
    endfunction

    public function Unregister takes unit u returns nothing
        local integer id
        local trigger t
        if u == null then
            set t = null
            return
        endif
        set id = GetHandleId(u)
        if DialogInteraction_SelectHandlers != 0 then
            set t = DialogInteraction_SelectHandlers.trigger[id]
            if t != null then
                call DestroyTrigger(t)
                call DialogInteraction_SelectHandlers.trigger.remove(id)
            endif
        endif
        if DialogInteraction_FirstGreetDone != 0 then
            set DialogInteraction_FirstGreetDone.boolean[id] = false
        endif
        if DialogInteraction_SkipNextGreet != 0 then
            set DialogInteraction_SkipNextGreet.boolean[id] = false
        endif
        set t = null
    endfunction

    public function IsUnitAlive takes unit u returns boolean
        if u == null then
            return false
        endif
        return FallenHeroState_IsAlive(u)
    endfunction

    public function IsWithinRange takes unit a, unit b, real range returns boolean
        local real dx
        local real dy
        if a == null or b == null then
            return false
        endif
        set dx = GetUnitX(a) - GetUnitX(b)
        set dy = GetUnitY(a) - GetUnitY(b)
        return dx * dx + dy * dy <= range * range
    endfunction

    private function IsLiveDialogHero takes unit hero returns boolean
        return hero != null and IsUnitAlive(hero)
    endfunction

    public function GetAvailableHero takes unit giver, real range returns unit
        local boolean nazgrekOk = false
        local boolean zulkisOk = false

        if IsLiveDialogHero(udg_Nazgrek) then
            if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
                set nazgrekOk = true
            endif
        endif
        if IsLiveDialogHero(udg_Zulkis) then
            if range <= 0.00 or IsWithinRange(giver, udg_Zulkis, range) then
                set zulkisOk = true
            endif
        endif
        if zulkisOk and IsUnitSelected(udg_Zulkis, Player(0)) then
            return udg_Zulkis
        endif
        if nazgrekOk and IsUnitSelected(udg_Nazgrek, Player(0)) then
            return udg_Nazgrek
        endif
        if nazgrekOk then
            return udg_Nazgrek
        endif
        if zulkisOk then
            return udg_Zulkis
        endif
        return null
    endfunction

    public function GetAllowedHero takes unit giver, real range, boolean allowNazgrek, boolean allowZulkis returns unit
        if allowZulkis and IsLiveDialogHero(udg_Zulkis) and IsUnitSelected(udg_Zulkis, Player(0)) then
            if range <= 0.00 or IsWithinRange(giver, udg_Zulkis, range) then
                return udg_Zulkis
            endif
        endif
        if allowNazgrek and IsLiveDialogHero(udg_Nazgrek) and IsUnitSelected(udg_Nazgrek, Player(0)) then
            if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
                return udg_Nazgrek
            endif
        endif
        if allowNazgrek and IsLiveDialogHero(udg_Nazgrek) then
            if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
                return udg_Nazgrek
            endif
        endif
        if allowZulkis and IsLiveDialogHero(udg_Zulkis) then
            if range <= 0.00 or IsWithinRange(giver, udg_Zulkis, range) then
                return udg_Zulkis
            endif
        endif
        return null
    endfunction

    public function ResolveDialogHero takes unit selectedHero, unit npc, real range, boolean allowNazgrek, boolean allowZulkis returns unit
        if IsLiveDialogHero(selectedHero) then
            return selectedHero
        endif
        return GetAllowedHero(npc, range, allowNazgrek, allowZulkis)
    endfunction

    public function GetHeroName takes unit hero returns string
        if hero == null then
            return ""
        endif
        if hero == udg_Nazgrek then
            return "Nazgrek"
        endif
        if hero == udg_Zulkis then
            return "Zulkis"
        endif
        return GetUnitName(hero)
    endfunction

    public function AddHeroLine takes integer seq, unit hero, string text, string nazgrekSound returns nothing
        if hero == null then
            return
        endif
        if hero == udg_Nazgrek then
            call DialogSystem_AddLine(seq, hero, "Nazgrek", text, nazgrekSound, true)
        else
            call DialogSystem_AddLine(seq, hero, GetHeroName(hero), text, "", true)
        endif
    endfunction

    public function AddHeroLookAtLine takes integer seq, unit hero, unit lookTarget, string text, string nazgrekSound returns nothing
        if hero != null and lookTarget != null then
            call DialogSystem_AddLookAtUnit(seq, hero, lookTarget, 0.50)
        endif
        call AddHeroLine(seq, hero, text, nazgrekSound)
    endfunction

    public function GetUnitDisplayName takes unit u returns string
        if u == null then
            return ""
        endif
        if IsUnitType(u, UNIT_TYPE_HERO) then
            return GetHeroProperName(u)
        endif
        return GetUnitName(u)
    endfunction

    public function BeginCinematicSequence takes boolean useCinematicMode returns nothing
        call EnableUserControl(false)
        if useCinematicMode then
            call ExecuteFunc("MasterUI_HideGameButton")
            call FullscreenUI_SetEnabled(true)
        endif
    endfunction

    public function EndCinematicSequence takes boolean useCinematicMode returns nothing
        if useCinematicMode then
            call FullscreenUI_SetEnabled(false)
            call ExecuteFunc("MasterUI_ShowGameButton")
        endif
        call EnableUserControl(true)
    endfunction

    private function BeginPendingGreetSequence takes nothing returns nothing
        call BeginCinematicSequence(DialogInteraction_PendingSequenceCinematic)
    endfunction

    private function EndPendingGreetSequenceControl takes nothing returns nothing
        call EndCinematicSequence(DialogInteraction_PendingSequenceCinematic)
        set DialogInteraction_PendingSequenceCinematic = false
    endfunction

    private function ReleasePendingGreetSequenceToDialog takes nothing returns nothing
        set DialogInteraction_PendingSequenceCinematic = false
    endfunction

    public function CreateBaseSequence takes unit npc, string npcName returns integer
        local integer seq = DialogSystem_CreateSequence()
        call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, npcName)
        return seq
    endfunction

    public function CreateGreetSequenceBase takes unit npc, string npcName, unit hero, real startDelay, real heroReplyDelay, boolean faceEachOther returns integer
        local integer seq = DialogSystem_CreateSequence()
        local string heroName = GetHeroName(hero)

        call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, npcName)
        if hero != null and faceEachOther then
            call DialogSystem_MakeFaceEachOther(npc, hero, 0.00)
        endif
        if startDelay > 0.00 then
            call DialogSystem_AddDelay(seq, startDelay)
        endif
        if hero != null then
            call DialogSystem_PickGreetLine(hero, heroName)
            call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
            if heroReplyDelay > 0.00 then
                call DialogSystem_AddDelay(seq, heroReplyDelay)
            endif
        endif
        return seq
    endfunction

    public function CreateInfoSequenceBase takes unit npc, string npcName, code onStart, code onEnd returns integer
        local integer seq = DialogSystem_CreateSequence()
        call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, npcName)
        call DialogSystem_SetSequenceCallbacks(seq, onStart, onEnd)
        return seq
    endfunction

    public function CreateFarewellSequence takes unit npc, string npcName, unit hero, string heroName, real dialogRange, boolean allowNazgrek, boolean allowZulkis returns integer
        local integer seq = CreateBaseSequence(npc, npcName)

        if hero == null then
            set hero = GetAllowedHero(npc, dialogRange, allowNazgrek, allowZulkis)
            set heroName = GetHeroName(hero)
        endif
        if hero != null then
            call DialogSystem_PickFarewellLine(hero, heroName)
            call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        endif

        call DialogSystem_PickFarewellLine(npc, "")
        call DialogSystem_AddLine(seq, npc, npcName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)

        return seq
    endfunction

    private function ReopenDialogTimerExpired takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local string funcName = DialogInteraction_ReopenDialogFuncName

        call DestroyTimer(t)
        set t = null
        set DialogInteraction_ReopenDialogFuncName = ""
        if funcName != "" then
            call ExecuteFunc(funcName)
        endif
    endfunction

    public function QueueDialogReopen takes string rebuildFuncName, real delay returns nothing
        local timer t
        if rebuildFuncName == "" then
            set t = null
            return
        endif
        if delay < 0.00 then
            set delay = 0.00
        endif
        set DialogInteraction_ReopenDialogFuncName = rebuildFuncName
        set t = CreateTimer()
        call TimerStart(t, delay, false, function ReopenDialogTimerExpired)
        set t = null
    endfunction

    private function OnGreetSequenceEnd takes nothing returns nothing
        local unit npc = DialogInteraction_PendingNPC
        local dialog d = DialogInteraction_PendingDialog
        local player p = DialogInteraction_PendingPlayer

        if d != null and p != null then
            call ReleasePendingGreetSequenceToDialog()
            if npc != null then
                call DialogSystem_SetContext(npc, p)
            endif
            call DialogSystem_ShowDialog(d, p)
        else
            call EndPendingGreetSequenceControl()
        endif
        if DialogInteraction_PendingSeq != 0 then
            call DialogSystem_ClearSequence(DialogInteraction_PendingSeq)
            set DialogInteraction_PendingSeq = 0
        endif
        set DialogInteraction_PendingDialog = null
        set DialogInteraction_PendingPlayer = null
        set DialogInteraction_PendingNPC = null
        set npc = null
        set d = null
        set p = null
    endfunction

    public function ShowDialog takes unit npc, player p, dialog d returns nothing
        local integer id
        local boolean skipGreet = false
        local integer seq = 0
        local integer greetOrder = DIALOGINTERACTION_GREET_DEFAULT
        local unit hero
        local string heroName

        if DialogSystem_IsSequenceActive() or DialogInteraction_PendingDialog != null then
            call DebugMsg("Show dialog ignored: sequence active or pending")
            set hero = null
            return
        endif
        call DialogSystem_SetContext(npc, p)
        if npc != null and DialogInteraction_SkipNextGreet != 0 then
            set id = GetHandleId(npc)
            if DialogInteraction_SkipNextGreet.boolean[id] then
                set skipGreet = true
                set DialogInteraction_SkipNextGreet.boolean[id] = false
            endif
        endif
        if npc != null and DialogInteraction_GreetOrder != 0 and DialogInteraction_GreetOrder.has(GetHandleId(npc)) then
            set greetOrder = DialogInteraction_GreetOrder.integer[GetHandleId(npc)]
        endif
        if greetOrder == DIALOGINTERACTION_GREET_DEFAULT then
            set greetOrder = DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC
        endif
        if greetOrder == DIALOGINTERACTION_GREET_NONE then
            set skipGreet = true
        endif

        set hero = GetAvailableHero(npc, 0.00)
        set heroName = GetHeroName(hero)
        if not skipGreet and (greetOrder == DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC or greetOrder == DIALOGINTERACTION_GREET_NAZGREK_ONLY) then
            if hero != null then
                call DialogSystem_PickGreetLine(hero, heroName)
                set seq = DialogSystem_CreateSequence()
                call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, GetUnitName(npc))
                call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
            endif
        endif
        if not skipGreet and (greetOrder == DIALOGINTERACTION_GREET_NPC_THEN_NAZGREK or greetOrder == DIALOGINTERACTION_GREET_NPC_ONLY or greetOrder == DIALOGINTERACTION_GREET_NAZGREK_THEN_NPC) then
            call DialogSystem_PickGreetLine(npc, "")
            if seq == 0 then
                set seq = DialogSystem_CreateSequence()
                call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, GetUnitName(npc))
            endif
            call DialogSystem_AddLine(seq, null, "", DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
        endif
        if not skipGreet and (greetOrder == DIALOGINTERACTION_GREET_NPC_THEN_NAZGREK or greetOrder == DIALOGINTERACTION_GREET_NAZGREK_ONLY) then
            if hero != null then
                call DialogSystem_PickGreetLine(hero, heroName)
                if seq == 0 then
                    set seq = DialogSystem_CreateSequence()
                    call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, GetUnitName(npc))
                endif
                call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
            endif
        endif
        if seq != 0 then
            set DialogInteraction_PendingDialog = d
            set DialogInteraction_PendingPlayer = p
            set DialogInteraction_PendingNPC = npc
            set DialogInteraction_PendingSeq = seq
            call DialogSystem_SetSequenceCallbacks(seq, null, function OnGreetSequenceEnd)
            call DialogSystem_PlaySequence(seq, p, npc)
            set hero = null
            return
        endif
        call DialogSystem_ShowDialog(d, p)
        set hero = null
    endfunction

    private function OnFirstGreetSequenceEnd takes nothing returns nothing
        local unit npc = DialogInteraction_PendingNPC
        local dialog d = DialogInteraction_PendingDialog
        local player p = DialogInteraction_PendingPlayer

        if npc != null then
            call SetFirstGreetDone(npc, true)
            call SuppressNextGreet(npc)
        endif
        if npc != null and d != null and p != null then
            call ReleasePendingGreetSequenceToDialog()
            call DialogSystem_SetContext(npc, p)
            call DialogSystem_ShowDialog(d, p)
        else
            call EndPendingGreetSequenceControl()
        endif
        if DialogInteraction_PendingSeq != 0 then
            call DialogSystem_ClearSequence(DialogInteraction_PendingSeq)
            set DialogInteraction_PendingSeq = 0
        endif
        set DialogInteraction_PendingDialog = null
        set DialogInteraction_PendingPlayer = null
        set DialogInteraction_PendingNPC = null
        set npc = null
        set d = null
        set p = null
    endfunction

    public function PlayFirstGreetSequenceEx takes unit npc, player p, dialog d, integer seqId, boolean useCinematicMode returns nothing
        if seqId == 0 or npc == null or p == null or d == null then
            return
        endif
        set DialogInteraction_PendingNPC = npc
        set DialogInteraction_PendingDialog = d
        set DialogInteraction_PendingPlayer = p
        set DialogInteraction_PendingSeq = seqId
        set DialogInteraction_PendingSequenceCinematic = useCinematicMode
        call DialogSystem_SetSequenceCallbacks(seqId, function BeginPendingGreetSequence, function OnFirstGreetSequenceEnd)
        call DialogSystem_PlaySequence(seqId, p, npc)
    endfunction

    public function PlayFirstGreetSequence takes unit npc, player p, dialog d, integer seqId returns nothing
        call PlayFirstGreetSequenceEx(npc, p, d, seqId, false)
    endfunction

    public function PlayGreetSequenceEx takes integer seqId, unit npc, player p, dialog d, boolean useCinematicMode returns nothing
        if seqId == 0 or npc == null or p == null or d == null then
            return
        endif
        set DialogInteraction_PendingNPC = npc
        set DialogInteraction_PendingDialog = d
        set DialogInteraction_PendingPlayer = p
        set DialogInteraction_PendingSeq = seqId
        set DialogInteraction_PendingSequenceCinematic = useCinematicMode
        call DialogSystem_SetSequenceCallbacks(seqId, function BeginPendingGreetSequence, function OnGreetSequenceEnd)
        call DialogSystem_PlaySequence(seqId, p, npc)
    endfunction

    public function PlayGreetSequence takes integer seqId, unit npc, player p, dialog d returns nothing
        call PlayGreetSequenceEx(seqId, npc, p, d, false)
    endfunction

    public function SetGreetOrder takes unit u, integer order returns nothing
        local integer id
        if u == null then
            return
        endif
        if DialogInteraction_GreetOrder == 0 then
            set DialogInteraction_GreetOrder = Table.create()
        endif
        set id = GetHandleId(u)
        set DialogInteraction_GreetOrder.integer[id] = order
    endfunction

    public function IsFirstGreetDone takes unit u returns boolean
        local integer id
        if u == null or DialogInteraction_FirstGreetDone == 0 then
            return false
        endif
        set id = GetHandleId(u)
        return DialogInteraction_FirstGreetDone.boolean[id]
    endfunction

    public function HideDialog takes dialog d, player p returns nothing
        call DialogSystem_HideDialog(d, p)
    endfunction

    public function CloseActiveDialog takes nothing returns nothing
        if DialogSystem_LastDialog == null or DialogSystem_ActivePlayer == null then
            return
        endif
        call DialogSystem_HideDialog(DialogSystem_LastDialog, DialogSystem_ActivePlayer)
    endfunction

    public function BeginDialogSequence takes nothing returns nothing
        call EnableUserControl(false)
        call CloseActiveDialog()
        call ExecuteFunc("TasQuestBox_Hide")
        call ExecuteFunc("MasterUI_HideGameButton")
    endfunction

    private function CooldownEnd takes nothing returns nothing
    endfunction

    public function GetCooldownRemaining takes timer t returns real
        if t == null then
            return 0.00
        endif
        return TimerGetRemaining(t)
    endfunction

    public function IsCooldownActive takes timer t returns boolean
        return GetCooldownRemaining(t) > 0.00
    endfunction

    public function StartCooldown takes timer t, real duration returns timer
        if t == null then
            set t = CreateTimer()
        endif
        call TimerStart(t, duration, false, function CooldownEnd)
        return t
    endfunction

    public function GetSelectedUnit takes nothing returns unit
        return DialogInteraction_SelectedUnit
    endfunction

    public function PassSelectionGate takes unit npc, unit hero, real range, timer cooldown returns boolean
        if GetSelectedUnit() != npc then
            return false
        endif
        if hero != null then
            if range > 0.00 and not IsWithinRange(npc, hero, range) then
                return false
            endif
        endif
        if cooldown != null and TimerGetRemaining(cooldown) > 0.00 then
            return false
        endif
        return true
    endfunction

    public function IsUnitCasting takes unit whichUnit returns boolean
        local integer customValue
        if whichUnit == null then
            return false
        endif
        set customValue = GetUnitUserData(whichUnit)
        if customValue <= 0 then
            return false
        endif
        return udg_UnitIsCasting[customValue]
    endfunction

    public function IsUnitInCombat takes unit whichUnit returns boolean
        local integer customValue
        if whichUnit == null then
            return false
        endif
        set customValue = GetUnitUserData(whichUnit)
        if customValue <= 0 then
            return false
        endif
        return udg_GCSM_UnitInCombat[customValue]
    endfunction

    public function GetDialogSelectionHero takes unit npc, real range, boolean allowNazgrek, boolean allowZulkis returns unit
        return GetAllowedHero(npc, range, allowNazgrek, allowZulkis)
    endfunction

    public function GetLastSelectionBlockReason takes nothing returns string
        return DialogInteraction_LastSelectionBlockReason
    endfunction

    public function PassDialogSelectionGate takes unit npc, unit hero, real range, timer cooldown, boolean requireHero, boolean blockSequenceActive, boolean blockNpcCasting, boolean blockNpcCombat, boolean blockHeroCasting, boolean blockHeroCombat returns boolean
        set DialogInteraction_LastSelectionBlockReason = ""
        if npc == null then
            set DialogInteraction_LastSelectionBlockReason = "missing npc"
            return false
        endif
        if GetSelectedUnit() != npc then
            set DialogInteraction_LastSelectionBlockReason = "selected unit mismatch"
            return false
        endif
        if blockSequenceActive and DialogSystem_IsSequenceActive() then
            set DialogInteraction_LastSelectionBlockReason = "dialog sequence active"
            return false
        endif
        if DialogSystem_IsInteractionReserved() then
            set DialogInteraction_LastSelectionBlockReason = "dialog interaction reserved"
            return false
        endif
        if requireHero and hero == null then
            set DialogInteraction_LastSelectionBlockReason = "missing allowed hero"
            return false
        endif
        if hero != null then
            if range > 0.00 and not IsWithinRange(npc, hero, range) then
                set DialogInteraction_LastSelectionBlockReason = "hero out of range"
                return false
            endif
            if blockHeroCasting and IsUnitCasting(hero) then
                set DialogInteraction_LastSelectionBlockReason = "hero is casting"
                return false
            endif
            if blockHeroCombat and IsUnitInCombat(hero) then
                set DialogInteraction_LastSelectionBlockReason = "hero is in combat"
                return false
            endif
        endif
        if cooldown != null and TimerGetRemaining(cooldown) > 0.00 then
            set DialogInteraction_LastSelectionBlockReason = "cooldown active"
            return false
        endif
        if blockNpcCasting and IsUnitCasting(npc) then
            set DialogInteraction_LastSelectionBlockReason = "npc is casting"
            return false
        endif
        if blockNpcCombat and IsUnitInCombat(npc) then
            set DialogInteraction_LastSelectionBlockReason = "npc is in combat"
            return false
        endif
        return true
    endfunction

    public function HandleSequenceEnd takes unit npc, timer cooldownTimer, real cooldownDuration, boolean stopCamera, real cameraStopDuration, boolean useCamera, boolean reopenDialog returns nothing
        call CloseActiveDialog()
        if cooldownTimer != null and cooldownDuration > 0.00 then
            call StartCooldown(cooldownTimer, cooldownDuration)
        endif
        if stopCamera and useCamera then
            call DialogSystem_StopDialogCamera(Player(0), cameraStopDuration, true)
        endif
    endfunction

    private function ClearTransitionState takes nothing returns nothing
        set TransitionGiver = null
        set TransitionHero = null
        set TransitionCooldownTimer = null
        set TransitionCooldownDuration = 0.00
        set TransitionStopCamera = false
        set TransitionCameraStopDuration = 0.00
        set TransitionUseCamera = false
        set TransitionRunCinematicTrigger = false
        set TransitionUseCinematicMode = false
        set TransitionMoveMode = 0
        set TransitionMoveOffset = 0.00
        set TransitionMoveAngle = 0.00
        set TransitionCameraDist = 0.00
        set TransitionCameraZOffset = 0.00
        set TransitionCameraAngle = 0.00
        set TransitionCameraRotOffset = 0.00
        set TransitionCameraFarZ = 0.00
        set TransitionCameraFov = 0.00
        set TransitionCameraBlockRadius = 0.00
        set TransitionCameraBlockCheck = false
        set TransitionContinueFuncName = ""
    endfunction

    private function StopTransitionTimer takes nothing returns nothing
        if TransitionTimer != null then
            call PauseTimer(TransitionTimer)
            call DestroyTimer(TransitionTimer)
            set TransitionTimer = null
        endif
    endfunction

    public function CancelActiveTransition takes nothing returns nothing
        local boolean wasActive = TransitionTimer != null

        call StopTransitionTimer()
        call ClearTransitionState()
        if wasActive then
            call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 0.25, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        endif
    endfunction

    private function FinishDialogExitTransition takes nothing returns nothing
        local timer t = GetExpiredTimer()

        if t == TransitionTimer then
            set TransitionTimer = null
        endif

        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        call HandleSequenceEnd(TransitionGiver, TransitionCooldownTimer, TransitionCooldownDuration, TransitionStopCamera, TransitionCameraStopDuration, TransitionUseCamera, false)
        if TransitionRunCinematicTrigger then
            call TriggerExecute(gg_trg_Cinematic_OFF)
        endif
        if TransitionUseCinematicMode and not TransitionRunCinematicTrigger then
            call FullscreenUI_SetEnabled(false)
        endif
        if TransitionRunCinematicTrigger or TransitionUseCinematicMode then
            call ExecuteFunc("MasterUI_ShowGameButton")
        endif
        call EnableUserControl(true)
        if FallenHeroState_IsAlive(TransitionHero) then
            call CameraControl_SetTargetUnit(Player(0), TransitionHero)
            call SelectUnitForPlayerSingle(TransitionHero, Player(0))
        endif

        call ClearTransitionState()
        call DestroyTimer(t)
        set t = null
    endfunction

    private function ContinueDialogExitTransition takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local timer nextTimer = CreateTimer()

        if t == TransitionTimer then
            set TransitionTimer = null
        endif
        call DestroyTimer(t)
        set t = null
        set TransitionTimer = nextTimer
        call TimerStart(nextTimer, 1.0, false, function FinishDialogExitTransition)
        set nextTimer = null
    endfunction

    public function StartDialogExitTransition takes unit npc, unit restoreHero, timer cooldownTimer, real cooldownDuration, boolean stopCamera, real cameraStopDuration, boolean useCamera, boolean runCinematicTrigger, boolean useCinematicMode returns nothing
        local timer t = CreateTimer()

        call StopTransitionTimer()
        set TransitionGiver = npc
        set TransitionHero = restoreHero
        set TransitionCooldownTimer = cooldownTimer
        set TransitionCooldownDuration = cooldownDuration
        set TransitionStopCamera = stopCamera
        set TransitionCameraStopDuration = cameraStopDuration
        set TransitionUseCamera = useCamera
        set TransitionRunCinematicTrigger = runCinematicTrigger
        set TransitionUseCinematicMode = useCinematicMode

        call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        set TransitionTimer = t
        call TimerStart(t, 1.0, false, function ContinueDialogExitTransition)
        set t = null
    endfunction

    public function StartConfiguredDialogExitTransition takes unit npc, unit restoreHero, timer cooldownTimer, real cooldownDuration, boolean useCamera, boolean useCinematicMode returns nothing
        call StartDialogExitTransition(npc, restoreHero, cooldownTimer, cooldownDuration, true, 2.00, useCamera, true, useCinematicMode)
    endfunction

    private function ExecuteDialogEntryContinue takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local string continueFuncName = TransitionContinueFuncName

        if t == TransitionTimer then
            set TransitionTimer = null
        endif
        call DestroyTimer(t)
        set t = null
        set TransitionContinueFuncName = ""
        if continueFuncName != "" then
            call ExecuteFunc(continueFuncName)
        endif
    endfunction

    private function FinishDialogEntryTransition takes nothing returns nothing
        local timer t = CreateTimer()

        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        set TransitionTimer = t
        call TimerStart(t, 1.0, false, function ExecuteDialogEntryContinue)
        set t = null
    endfunction

    private function ContinueDialogEntryTransition takes nothing returns nothing
        local timer t = GetExpiredTimer()
        local location p1
        local location p2
        local unit hero = TransitionHero
        local real x
        local real y

        if t == TransitionTimer then
            set TransitionTimer = null
        endif
        call DestroyTimer(t)
        set t = null

        if hero == null then
            set hero = TransitionGiver
        endif

        if TransitionRunCinematicTrigger and TransitionGiver != null then
            set udg_CinematicTriggerUnit = hero
            set udg_CinematicMoveMode = TransitionMoveMode
            set x = GetUnitX(TransitionGiver) + TransitionMoveOffset * Cos(TransitionMoveAngle * bj_DEGTORAD)
            set y = GetUnitY(TransitionGiver) + TransitionMoveOffset * Sin(TransitionMoveAngle * bj_DEGTORAD)
            set p1 = Location(x, y)
            set p2 = Location(x, y)
            set udg_CinematicMovePoint[1] = p1
            set udg_CinematicMovePoint[2] = p2
            call TriggerExecute(gg_trg_Cinematic_ON)
            call RemoveLocation(p1)
            call RemoveLocation(p2)
            set p1 = null
            set p2 = null
        endif

        if TransitionGiver != null then
            call DialogSystem_StartDialogCamera(Player(0), TransitionGiver, TransitionCameraDist, TransitionCameraZOffset, TransitionCameraAngle, TransitionCameraRotOffset, TransitionCameraFarZ, TransitionCameraFov, TransitionCameraBlockRadius, TransitionCameraBlockCheck, TransitionUseCamera)
        endif

        call FinishDialogEntryTransition()
        set p1 = null
        set p2 = null
        set hero = null
    endfunction

    public function StartDialogEntryTransition takes unit npc, unit hero, integer moveMode, real moveOffset, real moveAngle, boolean runCinematicTrigger, boolean useCamera, real cameraDist, real cameraZOffset, real cameraAngle, real cameraRotOffset, real cameraFarZ, real cameraFov, real cameraBlockRadius, boolean cameraBlockCheck, boolean useCinematicMode, string continueFuncName returns nothing
        local timer t = CreateTimer()

        call StopTransitionTimer()
        set TransitionGiver = npc
        set TransitionHero = hero
        set TransitionMoveMode = moveMode
        set TransitionMoveOffset = moveOffset
        set TransitionMoveAngle = moveAngle
        set TransitionRunCinematicTrigger = runCinematicTrigger
        set TransitionUseCamera = useCamera
        set TransitionCameraDist = cameraDist
        set TransitionCameraZOffset = cameraZOffset
        set TransitionCameraAngle = cameraAngle
        set TransitionCameraRotOffset = cameraRotOffset
        set TransitionCameraFarZ = cameraFarZ
        set TransitionCameraFov = cameraFov
        set TransitionCameraBlockRadius = cameraBlockRadius
        set TransitionCameraBlockCheck = cameraBlockCheck
        set TransitionUseCinematicMode = useCinematicMode
        set TransitionContinueFuncName = continueFuncName

        if hero != null then
            call CameraControl_SetTargetUnit(Player(0), hero)
        endif
        if runCinematicTrigger or useCinematicMode then
            call EnableUserControl(false)
        endif
        if runCinematicTrigger or useCinematicMode then
            call ExecuteFunc("MasterUI_HideGameButton")
        endif
        if useCinematicMode and not runCinematicTrigger then
            call FullscreenUI_SetEnabled(true)
        endif

        call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
        set TransitionTimer = t
        call TimerStart(t, 1.0, false, function ContinueDialogEntryTransition)
        set t = null
    endfunction

    private function GetDialogTransitionKey takes unit npc, integer fieldId returns integer
        return GetHandleId(npc) * 100 + fieldId
    endfunction

    private function EnsureDialogTransitionConfig takes nothing returns nothing
        if DialogInteraction_DialogTransitionConfig == 0 then
            set DialogInteraction_DialogTransitionConfig = Table.create()
        endif
    endfunction

    public function ConfigureDialogTransition takes unit npc, integer moveMode, real moveOffset, real moveAngle, real cameraDist, real cameraZOffset, real cameraAngle, real cameraRotOffset, real cameraFarZ, real cameraFov, real cameraBlockRadius, boolean cameraBlockCheck returns nothing
        if npc == null then
            return
        endif
        call EnsureDialogTransitionConfig()
        set DialogInteraction_DialogTransitionConfig.boolean[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CONFIGURED)] = true
        set DialogInteraction_DialogTransitionConfig.integer[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_MODE)] = moveMode
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_OFFSET)] = moveOffset
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_ANGLE)] = moveAngle
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_DIST)] = cameraDist
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_Z_OFFSET)] = cameraZOffset
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ANGLE)] = cameraAngle
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ROT_OFFSET)] = cameraRotOffset
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FAR_Z)] = cameraFarZ
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FOV)] = cameraFov
        set DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_RADIUS)] = cameraBlockRadius
        set DialogInteraction_DialogTransitionConfig.boolean[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_CHECK)] = cameraBlockCheck
    endfunction

    public function HasDialogTransitionConfig takes unit npc returns boolean
        if npc == null or DialogInteraction_DialogTransitionConfig == 0 then
            return false
        endif
        return DialogInteraction_DialogTransitionConfig.boolean[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CONFIGURED)]
    endfunction

    public function StartConfiguredDialogCamera takes player p, unit npc, boolean useCamera returns nothing
        local real cameraDist = DIALOGINTERACTION_DEFAULT_CAMERA_DIST
        local real cameraZOffset = DIALOGINTERACTION_DEFAULT_CAMERA_Z_OFFSET
        local real cameraAngle = DIALOGINTERACTION_DEFAULT_CAMERA_ANGLE
        local real cameraRotOffset = DIALOGINTERACTION_DEFAULT_CAMERA_ROT_OFFSET
        local real cameraFarZ = DIALOGINTERACTION_DEFAULT_CAMERA_FAR_Z
        local real cameraFov = DIALOGINTERACTION_DEFAULT_CAMERA_FOV
        local real cameraBlockRadius = DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_RADIUS
        local boolean cameraBlockCheck = DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_CHECK

        if npc == null then
            return
        endif
        if HasDialogTransitionConfig(npc) then
            set cameraDist = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_DIST)]
            set cameraZOffset = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_Z_OFFSET)]
            set cameraAngle = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ANGLE)]
            set cameraRotOffset = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ROT_OFFSET)]
            set cameraFarZ = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FAR_Z)]
            set cameraFov = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FOV)]
            set cameraBlockRadius = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_RADIUS)]
            set cameraBlockCheck = DialogInteraction_DialogTransitionConfig.boolean[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_CHECK)]
        endif
        call DialogSystem_StartDialogCamera(p, npc, cameraDist, cameraZOffset, cameraAngle, cameraRotOffset, cameraFarZ, cameraFov, cameraBlockRadius, cameraBlockCheck, useCamera)
    endfunction

    public function StartConfiguredDialogEntryTransition takes unit npc, unit hero, boolean runCinematicTrigger, boolean useCamera, boolean useCinematicMode, string continueFuncName returns nothing
        local integer moveMode = DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_MODE
        local real moveOffset = DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_OFFSET
        local real moveAngle = DIALOGINTERACTION_DEFAULT_CINEMATIC_MOVE_ANGLE
        local real cameraDist = DIALOGINTERACTION_DEFAULT_CAMERA_DIST
        local real cameraZOffset = DIALOGINTERACTION_DEFAULT_CAMERA_Z_OFFSET
        local real cameraAngle = DIALOGINTERACTION_DEFAULT_CAMERA_ANGLE
        local real cameraRotOffset = DIALOGINTERACTION_DEFAULT_CAMERA_ROT_OFFSET
        local real cameraFarZ = DIALOGINTERACTION_DEFAULT_CAMERA_FAR_Z
        local real cameraFov = DIALOGINTERACTION_DEFAULT_CAMERA_FOV
        local real cameraBlockRadius = DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_RADIUS
        local boolean cameraBlockCheck = DIALOGINTERACTION_DEFAULT_CAMERA_BLOCK_CHECK

        if HasDialogTransitionConfig(npc) then
            set moveMode = DialogInteraction_DialogTransitionConfig.integer[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_MODE)]
            set moveOffset = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_OFFSET)]
            set moveAngle = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_MOVE_ANGLE)]
            set cameraDist = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_DIST)]
            set cameraZOffset = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_Z_OFFSET)]
            set cameraAngle = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ANGLE)]
            set cameraRotOffset = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_ROT_OFFSET)]
            set cameraFarZ = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FAR_Z)]
            set cameraFov = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_FOV)]
            set cameraBlockRadius = DialogInteraction_DialogTransitionConfig.real[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_RADIUS)]
            set cameraBlockCheck = DialogInteraction_DialogTransitionConfig.boolean[GetDialogTransitionKey(npc, DIALOGINTERACTION_TRANSITION_CAMERA_BLOCK_CHECK)]
        endif
        call StartDialogEntryTransition(npc, hero, moveMode, moveOffset, moveAngle, runCinematicTrigger, useCamera, cameraDist, cameraZOffset, cameraAngle, cameraRotOffset, cameraFarZ, cameraFov, cameraBlockRadius, cameraBlockCheck, useCinematicMode, continueFuncName)
    endfunction

    private function ClearPendingDialogState takes nothing returns nothing
        if DialogInteraction_PendingSeq != 0 then
            call DialogSystem_ClearSequence(DialogInteraction_PendingSeq)
        endif
        set DialogInteraction_PendingDialog = null
        set DialogInteraction_PendingPlayer = null
        set DialogInteraction_PendingNPC = null
        set DialogInteraction_PendingSeq = 0
        set DialogInteraction_PendingSequenceCinematic = false
        set DialogInteraction_ReopenDialogFuncName = ""
    endfunction

    private function ClearCombatGuardState takes nothing returns nothing
        set DialogInteraction_CombatGuardActive = false
        set DialogInteraction_CombatNPC = null
        set DialogInteraction_CombatHero = null
        if DialogInteraction_CombatCheckTimer != null then
            call PauseTimer(DialogInteraction_CombatCheckTimer)
        endif
    endfunction

    public function EndCombatSensitiveInteraction takes nothing returns nothing
        local trigger handler = DialogInteraction_CombatInterruptHandler

        set DialogInteraction_CombatInterruptHandler = null
        call ClearCombatGuardState()
        if handler != null then
            call DestroyTrigger(handler)
        endif
        set handler = null
    endfunction

    private function InterruptCombatSensitiveInteraction takes nothing returns nothing
        local trigger handler

        if not DialogInteraction_CombatGuardActive then
            set handler = null
            return
        endif
        set handler = DialogInteraction_CombatInterruptHandler
        set DialogInteraction_CombatInterruptHandler = null
        call ClearCombatGuardState()
        call CancelActiveTransition()
        call DialogSystem_CancelActiveSpeech()
        call ClearPendingDialogState()
        call CloseActiveDialog()
        if handler != null then
            call TriggerExecute(handler)
            call DestroyTrigger(handler)
        endif
        set handler = null
    endfunction

    private function CombatGuardTimerAction takes nothing returns nothing
        if not DialogInteraction_CombatGuardActive then
            return
        endif
        if (DialogInteraction_CombatNPC != null and (not IsUnitAlive(DialogInteraction_CombatNPC) or IsUnitInCombat(DialogInteraction_CombatNPC))) or (DialogInteraction_CombatHero != null and (not IsUnitAlive(DialogInteraction_CombatHero) or IsUnitInCombat(DialogInteraction_CombatHero))) then
            call InterruptCombatSensitiveInteraction()
        endif
    endfunction

    private function CombatGuardAttackAction takes nothing returns nothing
        local unit target = GetTriggerUnit()
        local unit attacker = GetAttacker()

        if DialogInteraction_CombatGuardActive and (target == DialogInteraction_CombatNPC or target == DialogInteraction_CombatHero or attacker == DialogInteraction_CombatNPC or attacker == DialogInteraction_CombatHero) then
            call InterruptCombatSensitiveInteraction()
        endif

        set target = null
        set attacker = null
    endfunction

    public function BeginCombatSensitiveInteractionEx takes unit npc, unit hero, code onInterrupt, boolean endOnCombat returns boolean
        local trigger handler = null

        call EndCombatSensitiveInteraction()
        if not endOnCombat then
            set npc = null
            set hero = null
            set handler = null
            return true
        endif
        if npc == null and hero == null then
            set npc = null
            set hero = null
            set handler = null
            return false
        endif
        if (npc != null and (not IsUnitAlive(npc) or IsUnitInCombat(npc))) or (hero != null and (not IsUnitAlive(hero) or IsUnitInCombat(hero))) then
            set npc = null
            set hero = null
            set handler = null
            return false
        endif

        if onInterrupt != null then
            set handler = CreateTrigger()
            call TriggerAddAction(handler, onInterrupt)
        endif
        set DialogInteraction_CombatNPC = npc
        set DialogInteraction_CombatHero = hero
        set DialogInteraction_CombatInterruptHandler = handler
        set DialogInteraction_CombatGuardActive = true
        call TimerStart(DialogInteraction_CombatCheckTimer, DIALOGINTERACTION_COMBAT_CHECK_INTERVAL, true, function CombatGuardTimerAction)

        set npc = null
        set hero = null
        set handler = null
        return true
    endfunction

    public function BeginCombatSensitiveInteraction takes unit npc, unit hero, code onInterrupt returns boolean
        return BeginCombatSensitiveInteractionEx(npc, hero, onInterrupt, true)
    endfunction

    private function Init takes nothing returns nothing
        set DialogInteraction_SelectHandlers = Table.create()
        set DialogInteraction_FirstGreetDone = Table.create()
        set DialogInteraction_SkipNextGreet = Table.create()
        set DialogInteraction_GreetOrder = Table.create()
        set DialogInteraction_DialogTransitionConfig = Table.create()
        set DialogInteraction_CombatCheckTimer = CreateTimer()
        set DialogInteraction_CombatAttackTrigger = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(DialogInteraction_CombatAttackTrigger, EVENT_PLAYER_UNIT_ATTACKED)
        call TriggerAddAction(DialogInteraction_CombatAttackTrigger, function CombatGuardAttackAction)
    endfunction
endlibrary
