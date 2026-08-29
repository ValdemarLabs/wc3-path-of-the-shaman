/**
    qZulkis

    Author: Valdemar
    Version: 1.1.1

    Description:

    Owns Zul'kis's compact parallel prologue: the Darkspear river arrival,
    first meeting with Chieftain Thork, destroyed landing, and Rescue the
    Brother in Bramblehide Village. The library stages the confirmed World
    Editor cameras, rects, and preplaced hero/brother variables directly.

    Credits:

    The final shore corpse layout is recovered from the legacy
    `Dead Darkspear Trolls` GUI trigger.

    How to install:

    Import after the listed quest, dialog, inventory, equipment, and
    voiceline libraries. Keep the confirmed IntroZulkis cameras and Zulkis,
    CorpseTroll, Bramblehide, captive, and Horde-stage rects in World Editor.
    Disable the legacy elapsed-time corpse trigger. Call
    qZulkis_StartPrologue() after Protect the Outpost.

    API:

    qZulkis_StartPrologue() begins the river arrival.
    qZulkis_IsPrologueActive() reports the separate playable section.
    qZulkis_IsAwaitingThorkMeeting() reports the Thork objective phase.
    qZulkis_HandleThorkSelection() consumes Thork selection during that phase.
    qZulkis_IsPrologueCompleted() gates Call of the Horde convergence.

**/
library qZulkis initializer Init requires QuestGiver, QuestMaster, DialogInteraction, DialogSystem, DInventory, DEquipment, VoicelinesZulkis, VoicelinesThork, VoicelinesZulkarak, VoicelinesGenericTroll, optional Pet
    globals
        // Quest and staging configuration
        public constant string QUEST_MEET_CHIEFTAIN_THORK = "Meet with Chieftain Thork"
        public constant string QUEST_RESCUE_BROTHER = "Rescue the Brother"

        private constant integer UNIT_DARKSPEAR_HEADHUNTER = 'ohun'
        private constant integer UNIT_DARKSPEAR_WITCH_DOCTOR = 'odoc'
        private constant integer UNIT_INTRO_SHIP = 'odes'
        private constant integer DARKSPEAR_PLAYER_ID = 1

        private constant integer STATE_DORMANT = 0
        private constant integer STATE_SHIP_ARRIVAL = 1
        private constant integer STATE_SHORE_INTRO = 2
        private constant integer STATE_MEET_THORK = 3
        private constant integer STATE_RETURN_TO_SHORE = 4
        private constant integer STATE_RESCUE_BROTHER = 5
        private constant integer STATE_COMPLETE = 6

        private constant real PROGRESS_PERIOD = 0.25
        private constant real SHIP_ARRIVAL_RANGE = 160.00
        private constant real SHIP_ARRIVAL_TIMEOUT = 14.00
        private constant real SHIP_CAMERA_START_DELAY = 0.10
        private constant real SHIP_CAMERA_PAN_DURATION = 10.00
        private constant real SHORE_RETURN_RANGE = 450.00
        private constant real THORK_INTERACTION_RANGE = 600.00
        private constant real ZULKARAK_RESCUE_RANGE = 350.00
        private constant real FADE_DURATION = 1.00
        private constant real WOUNDED_BLOOD_MIN_DELAY = 2.00
        private constant real WOUNDED_BLOOD_MAX_DELAY = 4.00
        private constant real WOUNDED_DEATH_DELAY = 1.50
        private constant string WOUNDED_BLOOD_EFFECT = "Objects\\Spawnmodels\\Orc\\OrcBlood\\OrcBloodGrunt.mdl"
        private constant string WOUNDED_DEATH_SOUND = "WitchDoctorDeath"
        private constant boolean DEBUG = false

        // Runtime state
        private unit Nazgrek = null
        private unit Zulkis = null
        private unit Zulkarak = null
        private unit Thork = null
        private unit IntroShip = null
        private unit array LandingTroll
        private effect array ShoreFire
        private QuestData MeetThorkQuest = 0
        private QuestData RescueBrotherQuest = 0
        private timer InitTimer = null
        private timer ProgressTimer = null
        private timer TransitionTimer = null
        private timer WoundedBloodTimer = null
        private timer WoundedDeathTimer = null
        private integer PrologueState = STATE_DORMANT
        private real ShipTravelElapsed = 0.00
        private real NazgrekSavedX = 0.00
        private real NazgrekSavedY = 0.00
        private real NazgrekSavedFacing = 0.00
        private player NazgrekSavedOwner = null
        private boolean NazgrekSavedInvulnerable = false
        private boolean NazgrekWasUnitHiderReference = false
        private boolean Initialized = false
        private boolean StartRequested = false
        private boolean PrologueStarted = false
        private boolean PrologueCompleted = false
        private boolean ScenePlaying = false
        private boolean BrokenLandingStaged = false
        private boolean BrokenLandingViewStaged = false
        private boolean InitWaitingLogged = false
    endglobals

private function DebugMsg takes string msg returns nothing
    if DEBUG then
        call BJDebugMsg("|cff88ccff[qZulkis]|r " + msg)
    endif
endfunction

private function SyncUnitReferences takes nothing returns nothing
    if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
        set Nazgrek = udg_Nazgrek
    endif
    if udg_Zulkis != null and udg_Zulkis != Zulkis then
        set Zulkis = udg_Zulkis
    endif
    if udg_Zulkarak != null and udg_Zulkarak != Zulkarak then
        set Zulkarak = udg_Zulkarak
    endif
    if udg_Thork != null and udg_Thork != Thork then
        set Thork = udg_Thork
    endif
endfunction

private function IsUnitNearPoint takes unit whichUnit, real x, real y, real range returns boolean
    local real dx
    local real dy

    if whichUnit == null or GetUnitTypeId(whichUnit) == 0 or GetWidgetLife(whichUnit) <= 0.405 then
        return false
    endif
    set dx = GetUnitX(whichUnit) - x
    set dy = GetUnitY(whichUnit) - y
    return dx * dx + dy * dy <= range * range
endfunction

private function IsUnitNearUnit takes unit first, unit second, real range returns boolean
    if second == null then
        return false
    endif
    return IsUnitNearPoint(first, GetUnitX(second), GetUnitY(second), range)
endfunction

private function RemoveLegacyCorpseEnum takes nothing returns nothing
    local unit u = GetEnumUnit()
    local integer unitTypeId = GetUnitTypeId(u)

    if GetWidgetLife(u) <= 0.405 and (unitTypeId == UNIT_DARKSPEAR_HEADHUNTER or unitTypeId == UNIT_DARKSPEAR_WITCH_DOCTOR) then
        call RemoveUnit(u)
    endif
    set u = null
endfunction

private function ClearLegacyCorpses takes rect whichRect returns nothing
    local group g = CreateGroup()

    call GroupEnumUnitsInRect(g, whichRect, null)
    call ForGroup(g, function RemoveLegacyCorpseEnum)
    call DestroyGroup(g)
    set g = null
endfunction

private function PrepareLivingTroll takes integer index, integer unitTypeId, rect whichRect returns nothing
    call ClearLegacyCorpses(whichRect)
    if LandingTroll[index] != null then
        call RemoveUnit(LandingTroll[index])
    endif
    set LandingTroll[index] = CreateUnit(Player(DARKSPEAR_PLAYER_ID), unitTypeId, GetRectCenterX(whichRect), GetRectCenterY(whichRect), GetRandomReal(0.00, 360.00))
    call SetUnitInvulnerable(LandingTroll[index], true)
    call PauseUnit(LandingTroll[index], true)
endfunction

private function StageLivingLandingParty takes nothing returns nothing
    call PrepareLivingTroll(1, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll01)
    call PrepareLivingTroll(2, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll02)
    call PrepareLivingTroll(3, UNIT_DARKSPEAR_WITCH_DOCTOR, gg_rct_CorpseTroll03)
    call PrepareLivingTroll(4, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll04)
    call PrepareLivingTroll(5, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll05)
    call PrepareLivingTroll(6, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll06)
endfunction

private function CreatePermanentCorpse takes integer index, integer unitTypeId, rect whichRect returns nothing
    local location corpsePoint = Location(GetRectCenterX(whichRect), GetRectCenterY(whichRect))

    set LandingTroll[index] = CreatePermanentCorpseLocBJ(bj_CORPSETYPE_FLESH, unitTypeId, Player(DARKSPEAR_PLAYER_ID), corpsePoint, GetRandomReal(0.00, 360.00))
    if LandingTroll[index] != null then
        call UnitSuspendDecay(LandingTroll[index], true)
    endif
    call RemoveLocation(corpsePoint)
    set corpsePoint = null
endfunction

private function ResumeLandingCorpseDecay takes nothing returns nothing
    local integer index = 1
    local unit corpse

    loop
        exitwhen index > 6
        set corpse = LandingTroll[index]
        if corpse != null and GetUnitTypeId(corpse) != 0 and GetWidgetLife(corpse) <= 0.405 then
            call UnitSuspendDecay(corpse, false)
            call SetUnitTimeScale(corpse, 1.00)
        endif
        set LandingTroll[index] = null
        set index = index + 1
    endloop
    set corpse = null
endfunction

private function ReplaceLandingTrollWithCorpse takes integer index, integer unitTypeId, rect whichRect returns nothing
    if LandingTroll[index] != null then
        call RemoveUnit(LandingTroll[index])
        set LandingTroll[index] = null
    endif
    call CreatePermanentCorpse(index, unitTypeId, whichRect)
endfunction

private function FinishWoundedTrollDeath takes boolean playDeathSound returns nothing
    local real deathX
    local real deathY

    if LandingTroll[3] == null or GetUnitTypeId(LandingTroll[3]) == 0 or GetWidgetLife(LandingTroll[3]) <= 0.405 then
        return
    endif
    call PauseTimer(WoundedBloodTimer)
    if playDeathSound then
        set deathX = GetUnitX(LandingTroll[3])
        set deathY = GetUnitY(LandingTroll[3])
        call ExSound_Stop()
        call ExSound_PlayLabelAtPoint(WOUNDED_DEATH_SOUND, deathX, deathY, false)
    endif
    call ReplaceLandingTrollWithCorpse(3, UNIT_DARKSPEAR_WITCH_DOCTOR, gg_rct_CorpseTroll03)
endfunction

private function RemoveIntroShip takes nothing returns nothing
    if IntroShip != null then
        call RemoveUnit(IntroShip)
        set IntroShip = null
    endif
endfunction

private function CleanupShoreFire takes nothing returns nothing
    if ShoreFire[1] != null then
        call DestroyEffect(ShoreFire[1])
        set ShoreFire[1] = null
    endif
    if ShoreFire[2] != null then
        call DestroyEffect(ShoreFire[2])
        set ShoreFire[2] = null
    endif
endfunction

private function StartMeetThorkQuest takes nothing returns nothing
    if MeetThorkQuest == 0 or MeetThorkQuest.completed then
        return
    endif

    set PrologueState = STATE_MEET_THORK
    if MeetThorkQuest.active then
        return
    endif
    call QuestGiver_AcceptQuest(MeetThorkQuest.id)
    call DebugMsg("Started Meet with Chieftain Thork.")
endfunction

private function OnShoreIntroSequenceEnd takes nothing returns nothing
    call DialogInteraction_EndCinematicSequence(true)
    call ResetToGameCameraForPlayer(Player(0), 0.00)
    call PauseUnit(Zulkis, false)
    call SelectUnitForPlayerSingle(Zulkis, Player(0))
    set ScenePlaying = false
    call StartMeetThorkQuest()
endfunction

private function PlayShoreIntroSequence takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Zulkarak, "Zul'karak")

    call DialogSystem_AddMakeFaceEachOther(seq, Zulkarak, Zulkis, 0.75, 0.00)
    call DialogSystem_AddLine(seq, Zulkarak, "Zul'karak", VL_ZULKARAK_0001_TEXT, VL_ZULKARAK_0001_KEY, true)
    call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0005_TEXT, VL_ZULKIS_0005_KEY, true)
    call DialogSystem_AddLine(seq, Zulkarak, "Zul'karak", VL_ZULKARAK_0002_TEXT, VL_ZULKARAK_0002_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, null, function OnShoreIntroSequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Zulkarak)
endfunction

private function StageShoreIntro takes nothing returns nothing
    call StageLivingLandingParty()
    call SetUnitPosition(Zulkis, GetRectCenterX(gg_rct_ZulkisStart), GetRectCenterY(gg_rct_ZulkisStart))
    call ShowUnit(Zulkis, true)
    call PauseUnit(Zulkis, true)
    call SetUnitOwner(Zulkarak, Player(DARKSPEAR_PLAYER_ID), true)
    call SetUnitInvulnerable(Zulkarak, true)
    call ShowUnit(Zulkarak, true)
    call PauseUnit(Zulkarak, true)
    call CameraSetupApplyForPlayer(true, gg_cam_IntroZulkisCam3, Player(0), 0.00)
    call CameraSetupApplyForPlayer(true, gg_cam_IntroZulkisCam4, Player(0), 8.00)
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call PlayShoreIntroSequence()
endfunction

private function OnShipArrivalFadeComplete takes nothing returns nothing
    if PrologueState == STATE_SHORE_INTRO then
        call StageShoreIntro()
    endif
endfunction

private function HandleShipArrival takes nothing returns nothing
    if PrologueState != STATE_SHIP_ARRIVAL then
        return
    endif
    set PrologueState = STATE_SHORE_INTRO
    call DialogSystem_ClearEscapeAction()
    call RemoveIntroShip()
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call TimerStart(TransitionTimer, FADE_DURATION, false, function OnShipArrivalFadeComplete)
endfunction

private function SkipShipArrival takes nothing returns nothing
    call HandleShipArrival()
endfunction

private function FinishThorkMeeting takes nothing returns nothing
    if MeetThorkQuest != 0 and MeetThorkQuest.active and not MeetThorkQuest.completed then
        call QuestGiver_SetRequirement(MeetThorkQuest.id, 2, "Return to the Darkspear landing")
        call QuestGiver_SetRequirementCompleted(MeetThorkQuest.id, 1, true)
        call MeetThorkQuest.removeReturnRequirement()
        call MeetThorkQuest.setState(QUEST_STATE_IN_PROGRESS)
        call MeetThorkQuest.refreshQuestLog()
    endif
    set PrologueState = STATE_RETURN_TO_SHORE
    set ScenePlaying = false
    call DialogInteraction_EndCinematicSequence(true)
    call PauseUnit(Zulkis, false)
    call SelectUnitForPlayerSingle(Zulkis, Player(0))
endfunction

private function OnThorkMeetingSequenceEnd takes nothing returns nothing
    call FinishThorkMeeting()
endfunction

private function OnThorkMeetingSequenceStart takes nothing returns nothing
    call DialogInteraction_BeginCinematicSequence(true)
    call IssueImmediateOrder(Zulkis, "stop")
endfunction

private function PlayThorkMeetingSequence takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Thork, "Chieftain Thork")

    call DialogSystem_AddMakeFaceEachOther(seq, Thork, Zulkis, 0.75, 0.00)
    call DialogSystem_AddLine(seq, Thork, "Chieftain Thork", VL_THORK_0013_TEXT, VL_THORK_0013_KEY, true)
    call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0006_TEXT, VL_ZULKIS_0006_KEY, true)
    call DialogSystem_AddLine(seq, Thork, "Chieftain Thork", VL_THORK_0014_TEXT, VL_THORK_0014_KEY, true)
    call DialogSystem_SetSequenceCallbacks(seq, function OnThorkMeetingSequenceStart, function OnThorkMeetingSequenceEnd)
    call DialogSystem_PlaySequence(seq, Player(0), Thork)
endfunction

private function StartRescueBrotherQuest takes nothing returns nothing
    if RescueBrotherQuest == 0 or RescueBrotherQuest.completed then
        return
    endif

    set PrologueState = STATE_RESCUE_BROTHER
    if RescueBrotherQuest.active then
        return
    endif
    call QuestGiver_AcceptQuest(RescueBrotherQuest.id)
    call DebugMsg("Started Rescue the Brother.")
endfunction

private function OnWoundedBlood takes nothing returns nothing
    local effect blood

    if BrokenLandingStaged and LandingTroll[3] != null and GetUnitTypeId(LandingTroll[3]) != 0 then
        set blood = AddSpecialEffectTarget(WOUNDED_BLOOD_EFFECT, LandingTroll[3], "chest")
        call DestroyEffect(blood)
        call TimerStart(WoundedBloodTimer, GetRandomReal(WOUNDED_BLOOD_MIN_DELAY, WOUNDED_BLOOD_MAX_DELAY), false, function OnWoundedBlood)
    endif
    set blood = null
endfunction

private function StageBrokenLanding takes nothing returns nothing
    local real shipX = GetRectCenterX(gg_rct_ZulkisShipWP2)
    local real shipY = GetRectCenterY(gg_rct_ZulkisShipWP2)

    if BrokenLandingStaged then
        return
    endif
    set BrokenLandingStaged = true
    call ReplaceLandingTrollWithCorpse(1, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll01)
    call ReplaceLandingTrollWithCorpse(2, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll02)
    call ReplaceLandingTrollWithCorpse(4, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll04)
    call ReplaceLandingTrollWithCorpse(5, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll05)
    call ReplaceLandingTrollWithCorpse(6, UNIT_DARKSPEAR_HEADHUNTER, gg_rct_CorpseTroll06)
    if LandingTroll[3] != null then
        call SetWidgetLife(LandingTroll[3], RMaxBJ(1.00, GetUnitState(LandingTroll[3], UNIT_STATE_MAX_LIFE) * 0.10))
        call SetUnitOwner(LandingTroll[3], Player(PLAYER_NEUTRAL_PASSIVE), true)
        call SetUnitInvulnerable(LandingTroll[3], true)
        call PauseUnit(LandingTroll[3], false)
        call IssueImmediateOrder(LandingTroll[3], "stop")
        call SetUnitAnimation(LandingTroll[3], "death")
        call SetUnitTimeScale(LandingTroll[3], 0.20)
        call TimerStart(WoundedBloodTimer, 0.50, false, function OnWoundedBlood)
    endif

    call SetUnitOwner(Zulkarak, Player(PLAYER_NEUTRAL_PASSIVE), true)
    call SetUnitPosition(Zulkarak, GetRectCenterX(gg_rct_ZulkarakCaptive), GetRectCenterY(gg_rct_ZulkarakCaptive))
    call SetUnitInvulnerable(Zulkarak, true)
    call PauseUnit(Zulkarak, true)
    call ShowUnit(Zulkarak, true)

    call CleanupShoreFire()
    set ShoreFire[1] = AddSpecialEffect("Doodads\\Cinematic\\TownBurningFireEmitter\\TownBurningFireEmitter.mdl", shipX - 96.00, shipY)
    set ShoreFire[2] = AddSpecialEffect("Doodads\\Cinematic\\TownBurningFireEmitter\\TownBurningFireEmitter.mdl", shipX + 96.00, shipY)
endfunction

private function StageBrokenLandingView takes nothing returns nothing
    call StageBrokenLanding()
    set BrokenLandingViewStaged = true
    call CameraSetupApplyForPlayer(true, gg_cam_IntroZulkisCam4, Player(0), 0.00)
endfunction

private function OnWoundedDeath takes nothing returns nothing
    call FinishWoundedTrollDeath(true)
endfunction

private function ScheduleWoundedDeath takes nothing returns nothing
    call TimerStart(WoundedDeathTimer, WOUNDED_DEATH_DELAY, false, function OnWoundedDeath)
endfunction

private function FinishBrokenLanding takes nothing returns nothing
    local boolean skippedBeforeStaging = not BrokenLandingViewStaged

    if skippedBeforeStaging then
        call StageBrokenLandingView()
    endif
    call PauseTimer(WoundedBloodTimer)
    call PauseTimer(WoundedDeathTimer)
    call FinishWoundedTrollDeath(false)
    if MeetThorkQuest != 0 and MeetThorkQuest.active and not MeetThorkQuest.completed then
        call QuestGiver_SetRequirementCompleted(MeetThorkQuest.id, 2, true)
        call QuestGiver_CompleteQuest(MeetThorkQuest.id)
    endif
    call StartRescueBrotherQuest()
    call DialogInteraction_EndCinematicSequence(true)
    call ResetToGameCameraForPlayer(Player(0), 0.00)
    if skippedBeforeStaging then
        call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    endif
    call PauseUnit(Zulkis, false)
    call SelectUnitForPlayerSingle(Zulkis, Player(0))
    set ScenePlaying = false
endfunction

private function OnBrokenLandingSequenceEnd takes nothing returns nothing
    call FinishBrokenLanding()
endfunction

private function OnBrokenLandingSequenceStart takes nothing returns nothing
    call DialogInteraction_BeginCinematicSequence(true)
    call IssueImmediateOrder(Zulkis, "stop")
endfunction

private function PlayBrokenLandingSequence takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(LandingTroll[3], "Darkspear Witch Doctor")
    local integer deathLine

    set BrokenLandingViewStaged = false
    call DialogSystem_SetSequenceCallbacks(seq, function OnBrokenLandingSequenceStart, function OnBrokenLandingSequenceEnd)
    call DialogSystem_AddFadeTransition(seq, FADE_DURATION, FADE_DURATION, function StageBrokenLandingView)
    call DialogSystem_AddDelay(seq, 0.50)
    call DialogSystem_AddLine(seq, LandingTroll[3], "Darkspear Witch Doctor", VL_GENERICTROLL_0001_TEXT, VL_GENERICTROLL_0001_KEY, true)
    call DialogSystem_AddLine(seq, LandingTroll[3], "Darkspear Witch Doctor", VL_GENERICTROLL_0002_TEXT, VL_GENERICTROLL_0002_KEY, true)
    set deathLine = DialogSystem_AddLine(seq, LandingTroll[3], "Darkspear Witch Doctor", VL_GENERICTROLL_0003_TEXT, VL_GENERICTROLL_0003_KEY, true)
    call DialogSystem_BindLineAction(seq, deathLine, function ScheduleWoundedDeath)
    call DialogSystem_PlaySequence(seq, Player(0), LandingTroll[3])
endfunction

private function CompletePrologue takes nothing returns nothing
    if RescueBrotherQuest != 0 and RescueBrotherQuest.active and not RescueBrotherQuest.completed then
        call QuestGiver_SetRequirementCompleted(RescueBrotherQuest.id, 1, true)
        call QuestGiver_CompleteQuest(RescueBrotherQuest.id)
    endif

    call CleanupShoreFire()
    call RemoveIntroShip()
    call PauseTimer(WoundedBloodTimer)
    call PauseTimer(WoundedDeathTimer)
    call ResumeLandingCorpseDecay()
    call DialogSystem_ClearEscapeAction()
    set PrologueState = STATE_COMPLETE
    set PrologueCompleted = true
    set ScenePlaying = false
    call PauseTimer(ProgressTimer)

    call SetUnitPosition(Zulkis, GetRectCenterX(gg_rct_ZulkisHordeStage), GetRectCenterY(gg_rct_ZulkisHordeStage))
    call SetUnitOwner(Zulkis, Player(PLAYER_NEUTRAL_PASSIVE), true)
    call SetUnitInvulnerable(Zulkis, true)
    call PauseUnit(Zulkis, true)
    call ShowUnit(Zulkis, true)

    call SetUnitPosition(Zulkarak, GetRectCenterX(gg_rct_ZulkarakHordeHome), GetRectCenterY(gg_rct_ZulkarakHordeHome))
    call SetUnitOwner(Zulkarak, Player(PLAYER_NEUTRAL_PASSIVE), true)
    call SetUnitInvulnerable(Zulkarak, true)
    call PauseUnit(Zulkarak, false)
    call ShowUnit(Zulkarak, true)

    call SetUnitPosition(Nazgrek, NazgrekSavedX, NazgrekSavedY)
    call SetUnitFacing(Nazgrek, NazgrekSavedFacing)
    if NazgrekSavedOwner == null then
        set NazgrekSavedOwner = Player(0)
    endif
    call SetUnitOwner(Nazgrek, NazgrekSavedOwner, true)
    call SetUnitInvulnerable(Nazgrek, NazgrekSavedInvulnerable)
    call ShowUnit(Nazgrek, true)
    call PauseUnit(Nazgrek, false)
    if NazgrekWasUnitHiderReference and udg_UnitHider_ReferenceGroup != null then
        call GroupAddUnit(udg_UnitHider_ReferenceGroup, Nazgrek)
    endif
    static if LIBRARY_Pet then
        call Pet_RestoreShadowclawAfterStory()
    endif
    call ResetToGameCameraForPlayer(Player(0), 0.00)
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call DialogInteraction_EndCinematicSequence(true)
    call SelectUnitForPlayerSingle(Nazgrek, Player(0))
    call ExecuteFunc("qChieftainThork_RefreshAvailability")
    call ExecuteFunc("qRagno_RefreshAvailability")
    call QuestMaster_RefreshUnitSpecificQuests()
    call DebugMsg("Completed Zul'kis prologue.")
endfunction

private function OnRescueSequenceEnd takes nothing returns nothing
    call CompletePrologue()
endfunction

private function OnRescueSequenceStart takes nothing returns nothing
    call DialogInteraction_BeginCinematicSequence(true)
    call IssueImmediateOrder(Zulkis, "stop")
endfunction

private function PlayRescueSequence takes nothing returns nothing
    local integer seq = DialogInteraction_CreateBaseSequence(Zulkarak, "Zul'karak")

    call DialogSystem_SetSequenceCallbacks(seq, function OnRescueSequenceStart, function OnRescueSequenceEnd)
    call DialogSystem_AddMakeFaceEachOther(seq, Zulkarak, Zulkis, 0.75, 0.00)
    call DialogSystem_AddLine(seq, Zulkarak, "Zul'karak", VL_ZULKARAK_0003_TEXT, VL_ZULKARAK_0003_KEY, true)
    call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0007_TEXT, VL_ZULKIS_0007_KEY, true)
    call DialogSystem_AddLine(seq, Zulkarak, "Zul'karak", VL_ZULKARAK_0004_TEXT, VL_ZULKARAK_0004_KEY, true)
    call DialogSystem_AddLine(seq, Zulkis, "Zul'kis", VL_ZULKIS_0008_TEXT, VL_ZULKIS_0008_KEY, true)
    call DialogSystem_AddFadeOut(seq, FADE_DURATION)
    call DialogSystem_PlaySequence(seq, Player(0), Zulkarak)
endfunction

private function OnProgress takes nothing returns nothing
    call SyncUnitReferences()

    if PrologueState == STATE_SHIP_ARRIVAL then
        set ShipTravelElapsed = ShipTravelElapsed + PROGRESS_PERIOD
        if IntroShip == null or IsUnitNearPoint(IntroShip, GetRectCenterX(gg_rct_ZulkisShipWP2), GetRectCenterY(gg_rct_ZulkisShipWP2), SHIP_ARRIVAL_RANGE) or ShipTravelElapsed >= SHIP_ARRIVAL_TIMEOUT then
            call HandleShipArrival()
        endif
    elseif PrologueState == STATE_RETURN_TO_SHORE then
        if not BrokenLandingStaged then
            call StageBrokenLanding()
        endif
        if not ScenePlaying and IsUnitNearPoint(Zulkis, GetRectCenterX(gg_rct_ZulkisStart), GetRectCenterY(gg_rct_ZulkisStart), SHORE_RETURN_RANGE) then
            set ScenePlaying = true
            call PlayBrokenLandingSequence()
        endif
    elseif PrologueState == STATE_RESCUE_BROTHER and not ScenePlaying and RectContainsUnit(gg_rct_BramblehideVillage, Zulkis) and IsUnitNearUnit(Zulkis, Zulkarak, ZULKARAK_RESCUE_RANGE) then
        set ScenePlaying = true
        call PlayRescueSequence()
    endif
endfunction

private function StartShipCameraPan takes nothing returns nothing
    if PrologueState == STATE_SHIP_ARRIVAL then
        call CameraSetupApplyForPlayer(true, gg_cam_IntroZulkisCam2, Player(0), SHIP_CAMERA_PAN_DURATION)
    endif
endfunction

private function StartShipArrival takes nothing returns nothing
    if PrologueState != STATE_SHIP_ARRIVAL then
        return
    endif
    call CameraSetupApplyForPlayer(true, gg_cam_IntroZulkisCam1, Player(0), 0.00)
    call RemoveIntroShip()
    set IntroShip = CreateUnit(Player(DARKSPEAR_PLAYER_ID), UNIT_INTRO_SHIP, GetRectCenterX(gg_rct_ZulkisShipWP1), GetRectCenterY(gg_rct_ZulkisShipWP1), bj_UNIT_FACING)
    call IssuePointOrder(IntroShip, "move", GetRectCenterX(gg_rct_ZulkisShipWP2), GetRectCenterY(gg_rct_ZulkisShipWP2))
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call TimerStart(TransitionTimer, SHIP_CAMERA_START_DELAY, false, function StartShipCameraPan)
    call TimerStart(ProgressTimer, PROGRESS_PERIOD, true, function OnProgress)
endfunction

private function StartPrologueInternal takes nothing returns nothing
    if PrologueStarted or PrologueCompleted or Zulkis == null or Zulkarak == null or Nazgrek == null or Thork == null then
        return
    endif

    set PrologueStarted = true
    set ScenePlaying = true
    set NazgrekSavedX = GetUnitX(Nazgrek)
    set NazgrekSavedY = GetUnitY(Nazgrek)
    set NazgrekSavedFacing = GetUnitFacing(Nazgrek)
    set NazgrekSavedOwner = GetOwningPlayer(Nazgrek)
    set NazgrekSavedInvulnerable = BlzIsUnitInvulnerable(Nazgrek)
    set NazgrekWasUnitHiderReference = udg_UnitHider_ReferenceGroup != null and IsUnitInGroup(Nazgrek, udg_UnitHider_ReferenceGroup)
    call PauseUnit(Nazgrek, true)
    call SetUnitInvulnerable(Nazgrek, true)
    call SetUnitOwner(Nazgrek, Player(PLAYER_NEUTRAL_PASSIVE), true)
    if udg_UnitHider_ReferenceGroup != null then
        call GroupRemoveUnit(udg_UnitHider_ReferenceGroup, Nazgrek)
    endif
    call ShowUnit(Nazgrek, false)
    static if LIBRARY_Pet then
        call Pet_HideShadowclawForStory()
    endif

    call SetUnitOwner(Zulkis, Player(0), true)
    call SetUnitInvulnerable(Zulkis, false)
    call PauseUnit(Zulkis, true)
    call ShowUnit(Zulkis, false)
    call InitializeDInventoryForUnit(Zulkis)
    call InitializeDEquipmentForUnit(Zulkis)

    call SetUnitInvulnerable(Zulkarak, true)
    call PauseUnit(Zulkarak, true)
    call ShowUnit(Zulkarak, false)
    set PrologueState = STATE_SHIP_ARRIVAL
    set ShipTravelElapsed = 0.00
    call DialogInteraction_BeginCinematicSequence(true)
    call DialogSystem_SetEscapeAction(function SkipShipArrival)
    call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, FADE_DURATION, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
    call TimerStart(TransitionTimer, FADE_DURATION, false, function StartShipArrival)
    call QuestMaster_RefreshUnitSpecificQuests()
    call DebugMsg("Started Zul'kis prologue.")
endfunction

private function CanOfferMeetThork takes nothing returns boolean
    return PrologueStarted
endfunction

private function CanOfferRescueBrother takes nothing returns boolean
    return MeetThorkQuest != 0 and MeetThorkQuest.completed
endfunction

private function CreateQuests takes nothing returns nothing
    local string infoText = "|cffffcc00Source:|r Zul'kis prologue\n|cffffcc00Zone:|r Thornwoods (6) and Havenwoods (7)\n"
    local trigger availabilityCondition

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_MEET_CHIEFTAIN_THORK, Zulkis) then
        set MeetThorkQuest = QuestGiver_CreateConfiguredQuest(QUEST_MEET_CHIEFTAIN_THORK, Zulkis, "normal", 1, Thork, QUEST_MEET_CHIEFTAIN_THORK, "ReplaceableTextures\\CommandButtons\\BTNOrcWarlock.blp", "Meet Chieftain Thork at the Horde base, then return to the Darkspear landing as ordered.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, true, false, true, "Horde", "Chieftain Thork")
        call QuestGiver_SetQuestRewards(MeetThorkQuest, false, 0, false, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(MeetThorkQuest, "story")
        call QuestGiver_SetRequirements(MeetThorkQuest.id, "", "Meet with Chieftain Thork", "", "", "", "", "", "", "")
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferMeetThork))
        call QuestGiver_SetQuestCustomCondition(MeetThorkQuest, availabilityCondition)
        call QuestGiver_SetStateByNameAndGiver(QUEST_MEET_CHIEFTAIN_THORK, Zulkis, QUEST_STATE_UNAVAILABLE)
    else
        set MeetThorkQuest = QuestGiver_GetByNameAndGiver(QUEST_MEET_CHIEFTAIN_THORK, Zulkis)
    endif
    call QuestGiver_SetQuestUnitSpecificHero(MeetThorkQuest, Zulkis)

    if not QuestGiver_QuestExistsByNameAndGiver(QUEST_RESCUE_BROTHER, Zulkis) then
        set RescueBrotherQuest = QuestGiver_CreateConfiguredQuest(QUEST_RESCUE_BROTHER, Zulkis, "normal", 1, null, QUEST_RESCUE_BROTHER, "ReplaceableTextures\\CommandButtons\\BTNBerserkForTrolls.blp", "Find and rescue Zul'karak from Bramblehide Village in Havenwoods.\n\n", infoText, "|cffffcc00Objective area:|r Bramblehide Village (701)\n\n", 1, true, false, true, "Darkspear Tribe", "")
        call QuestGiver_SetQuestRewards(RescueBrotherQuest, false, 0, false, 0, false, 0, false, 0, false)
        call QuestGiver_SetQuestCategory(RescueBrotherQuest, "story")
        call QuestGiver_SetRequirements(RescueBrotherQuest.id, "", "Rescue Zul'karak in Bramblehide Village", "", "", "", "", "", "", "")
        set availabilityCondition = CreateTrigger()
        call TriggerAddCondition(availabilityCondition, Condition(function CanOfferRescueBrother))
        call QuestGiver_SetQuestCustomCondition(RescueBrotherQuest, availabilityCondition)
        call QuestGiver_SetStateByNameAndGiver(QUEST_RESCUE_BROTHER, Zulkis, QUEST_STATE_UNAVAILABLE)
    else
        set RescueBrotherQuest = QuestGiver_GetByNameAndGiver(QUEST_RESCUE_BROTHER, Zulkis)
    endif
    call QuestGiver_SetQuestUnitSpecificHero(RescueBrotherQuest, Zulkis)

    set availabilityCondition = null
endfunction

private function InitDelayed takes nothing returns nothing
    local timer expiredTimer = GetExpiredTimer()

    call SyncUnitReferences()
    if Nazgrek == null or Zulkis == null or Zulkarak == null or Thork == null then
        if not InitWaitingLogged then
            call DebugMsg("Waiting for Nazgrek, Zul'kis, Zul'karak, and Chieftain Thork unit references.")
            set InitWaitingLogged = true
        endif
        call TimerStart(expiredTimer, 0.50, false, function InitDelayed)
        set expiredTimer = null
        return
    endif

    call QuestMaster_SetGiverIconsSuppressed(Zulkis, true)
    call CreateQuests()
    set PrologueCompleted = RescueBrotherQuest != 0 and RescueBrotherQuest.completed
    if PrologueCompleted then
        set PrologueState = STATE_COMPLETE
    else
        call SetUnitOwner(Zulkis, Player(PLAYER_NEUTRAL_PASSIVE), true)
        call SetUnitInvulnerable(Zulkis, true)
        call PauseUnit(Zulkis, true)
        call ShowUnit(Zulkis, false)
    endif
    set Initialized = true
    if StartRequested then
        call StartPrologueInternal()
    endif
    call DestroyTimer(expiredTimer)
    set InitTimer = null
    set expiredTimer = null
    call DebugMsg("Initialized.")
endfunction

private function Init takes nothing returns nothing
    set InitTimer = CreateTimer()
    set ProgressTimer = CreateTimer()
    set TransitionTimer = CreateTimer()
    set WoundedBloodTimer = CreateTimer()
    set WoundedDeathTimer = CreateTimer()
    call TimerStart(InitTimer, 0.00, false, function InitDelayed)
endfunction

public function StartPrologue takes nothing returns nothing
    set StartRequested = true
    if Initialized then
        call SyncUnitReferences()
        call StartPrologueInternal()
    endif
endfunction

public function IsPrologueActive takes nothing returns boolean
    return PrologueStarted and not PrologueCompleted
endfunction

public function IsAwaitingThorkMeeting takes nothing returns boolean
    return PrologueState == STATE_MEET_THORK and not ScenePlaying
endfunction

public function HandleThorkSelection takes nothing returns boolean
    call SyncUnitReferences()
    if PrologueState != STATE_MEET_THORK or ScenePlaying then
        return false
    endif
    if not IsUnitNearUnit(Zulkis, Thork, THORK_INTERACTION_RANGE) then
        call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 3.00, "Move Zul'kis closer to Chieftain Thork.")
        return true
    endif

    set ScenePlaying = true
    call PlayThorkMeetingSequence()
    return true
endfunction

public function IsPrologueCompleted takes nothing returns boolean
    if PrologueCompleted then
        return true
    endif
    return RescueBrotherQuest != 0 and RescueBrotherQuest.completed
endfunction
endlibrary
