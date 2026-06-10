library qAradion initializer Init requires QuestGiver, QuestMaster, DialogSystem, ExSound, FollowSystem, PatrolSystem, UnitSpawn
//===========================================================================
// qAradion
// Quest giver dialog + quest flow for Aradion the Farseer.
//===========================================================================
globals
	private constant boolean DEBUG = false
	private constant boolean ENABLE_TEST_QUESTS = false

	//===========================================================================
	// CONFIGURATION - Edit these to tweak quest details like names, item requirements, etc.
	private constant string QUEST_RANGER_MISSING = "Ranger Missing"
	private constant string QUEST_CRYSTALS_HOPE = "Crystals of Hope"
	private constant string QUEST_FADING_SPARKS = "Fading Sparks"
	private constant string QUEST_RIFTS_CORRUPTION = "Rifts of Corruption"
	
	// Test quests
	private constant string QUEST_TEST_KILL = "Test Kill Quest"
	private constant string QUEST_TEST_TALKTO = "Test Talk To Quest"
	private constant string QUEST_TEST_FINDNPC = "Test Find NPC Quest"
	private constant string QUEST_TEST_GOTO = "Test Go To Place Quest"
	private constant string QUEST_TEST_REPUTATION = "Test Reputation Quest"
	private constant string QUEST_TEST_INVESTIGATE = "Test Investigate Quest"

	private constant integer ITEM_MANA_CRYSTAL = 'I00Y'
	private constant integer ITEM_WRAITH_ESSENCE = 'I011'
	private constant integer ITEM_TELANOR_ROD = 'I013'

	private constant real DIALOG_RANGE = 500.00
	private constant real VALERIA_RANGE = 1000.00
	private constant real VALERIA_NEGOTIATION_MAX_DISTANCE = 1000.00
	private constant real VALERIA_ENCOUNTER_TRIGGER_RANGE = 900.00
	private constant real VALERIA_ENCOUNTER_RESET_DISTANCE = 1750.00
	private constant real VALERIA_ENCOUNTER_RANDOM_PERIOD = 10.00
	private constant real VALERIA_ENCOUNTER_RANDOM_MIN_OFFSET = 300.00
	private constant real VALERIA_ENCOUNTER_RANDOM_MAX_OFFSET = 700.00
	private constant real VALERIA_ENCOUNTER_SPEED_BOOST = 420.00
	private constant real VALERIA_ENCOUNTER_ARROW_DURATION = 5.00
	private constant real VALERIA_ENCOUNTER_RANGE_CHECK_PERIOD = 2.00
	private constant real VALERIA_ENCOUNTER_SPEED_RESET_DELAY = 3.00
	private constant real DIALOG_COOLDOWN = 6.00
	private constant real FOLLOW_MAX_DISTANCE = 2000.00
	private constant real RANGER_ESCORT_DEST_RADIUS = 256.00
	private constant boolean REQUIRE_DIALOG_HERO = true
	private constant integer CINEMATIC_MOVE_MODE = 1  // 1 = All units,
	private constant real CINEMATIC_MOVE_OFFSET = 256.00  // Offset for cinematic positioning
	private constant real CINEMATIC_MOVE_ANGLE = 210.00   // Angle for cinematic positioning
	private constant string VALERIA_COMPANION_ICON = "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp"
	private constant string ARADION_COMPANION_ICON = "ReplaceableTextures\\CommandButtons\\BTNHeroBloodElfPrince.blp"
	private constant integer VALERIA_HOSTILE_OWNER = 11
	private constant integer VALERIA_FRIENDLY_OWNER = 18
	private constant integer VALERIA_HOME_OWNER = 15
	private constant integer ABIL_VALERIA_COLD_ARROWS = 'ANca'
	private constant integer ABIL_VALERIA_GHOST = 'Agho'
	private constant integer RIFTS_MAX = 3
	private constant integer RIFTS_MAX_WAVES = 32
	private constant integer RIFTS_WAVE_OWNER = 11
	private constant real RIFTS_TRIGGER_RANGE = 900.00
	private constant real RIFTS_RITUAL_DURATION = 120.00
	private constant real RIFTS_WAVE_PERIOD = 30.00
	private constant real RIFTS_COMBAT_PERIOD = 40.00
	private constant real RIFTS_COUNTDOWN_PERIOD = 1.00
	private constant real RIFTS_ARADION_OFFSET = 500.00
	private constant real RIFTS_VALERIA_OFFSET = 200.00

	//===========================================================================
	// CONFIGURATION - Edit these to tweak dialog options, camera settings, etc.
	private boolean ALLOW_NAZGREK = true
	private boolean ALLOW_ZULKIS = true
	private boolean USE_DIALOG_CAMERA = true
	private boolean CINEMATIC = true  // Enable/disable cinematic mode for sequences
	private real CAMERA_DIST = 1050.00
	private real CAMERA_Z_OFFSET = 20.00
	private real CAMERA_ANGLE = 350.00
	private real CAMERA_ROT_OFFSET = 180.00
	private real CAMERA_FAR_Z = 10000.00
	private real CAMERA_FOV = 60.00
	private real CAMERA_BLOCK_RADIUS = 0.00
	private boolean CAMERA_BLOCK_CHECK = true
	private real CAMERA_CLOSE_DIST = 800.00
	private real CAMERA_CLOSE_Z_OFFSET = 40.00
	private real CAMERA_CLOSE_ANGLE = 15.00
	private real CAMERA_CLOSE_ROT_OFFSET = 180.00
	private real CAMERA_CLOSE_FAR_Z = 10000.00
	private real CAMERA_CLOSE_FOV = 65.00
	//===========================================================================

	// DONT EDIT BELOW
	private dialog AradionDialog = null
	private timer AradionDialogCooldown = null
	private unit Aradion = null							
	private unit Nazgrek = null							
	private unit Valeria = null							
	private integer AradionInfoSeq = 0					// Stores the info sequence ID for reuse (prevents rebuilding every time)
	private unit SelectedHero = null					// temp variable to track which hero is interacting

	private boolean AradionBackstorySeen = false
	private boolean RangerMissingReq1Complete = false
	private boolean RangerMissingEscortActive = false
	private boolean ValeriaCompanionActive = false
	private boolean AradionCompanionActive = false
	private boolean ValeriaEncounterActive = false
	private boolean ValeriaEncounterResolved = false
	private boolean AradionInitWaitingLogged = false
	private integer AradionLastAcceptedQuest = 0
	private rect RangerMissingEscortDestination = null
	private trigger RangerMissingValeriaDeathTrigger = null
	private trigger ValeriaEncounterDeathTrigger = null
	private trigger ValeriaEncounterProximityTrigger = null
	private trigger RiftsValeriaFailTrigger = null
	private trigger RiftsAradionFailTrigger = null
	private timer ValeriaEncounterRandomTimer = null
	private timer ValeriaEncounterRangeTimer = null
	private timer ValeriaEncounterArrowTimer = null
	private timer RiftsFieldTimer = null
	private timer RiftsCloseTimer = null
	private timer RiftsWaveTimer = null
	private timer RiftsCombatTimer = null
	private timer RiftsCountdownTimer = null
	private dialog ValeriaNegotiationDialog = null
	private button array ValeriaNegotiationButtons
	private integer array ValeriaNegotiationLineIds
	private integer ValeriaNegotiationButtonCount = 0
	private unit ValeriaEncounterHero = null
	private boolean ValeriaNegotiationPromptPending = false
	private boolean RiftsQuestActive = false
	private boolean RiftsRitualActive = false
	private trigger RiftsProximityTrigger = null
	private unit RiftsCurrentRift = null
	private unit array RiftsUnits
	private integer array RiftsUnitTypeIds
	private Wave array RiftsWaveHandles
	private integer RiftsWaveIndex = 0
	private integer RiftsNextWaveN = 1
	private integer RiftsCurrentIndex = 0
	private integer RiftsCountdownRemaining = 0
	private boolean RiftsAwaitingReturnHome = false
	private boolean RiftsReturnedHome = false

	private constant integer ARADION_QID_RANGER = 1
	private constant integer ARADION_QID_CRYSTALS = 2
	private constant integer ARADION_QID_FADING = 3
	private constant integer ARADION_QID_RIFTS = 4

	// Quest update state tracking
	private integer RiftsCorruptionCounter = 0
endglobals

//===========================================================================
// Debug helpers
//===========================================================================
private function DebugMsg takes string msg returns nothing
	if DEBUG then
		call BJDebugMsg("[qAradion] " + msg)
	endif
endfunction

//===========================================================================
// Cinematic mode helpers
// Note: Uses GUI triggers "Cinematic ON" and "Cinematic OFF"
// which handle unit movement, pausing, UI hiding, etc.
//===========================================================================
private function EnterCinematicMode takes nothing returns nothing
	if CINEMATIC then
		call ExecuteFunc("MasterUI_HideGameButton")
		call CinematicModeBJ(true, GetPlayersAll())
	endif
endfunction

private function ExitCinematicMode takes nothing returns nothing
	if CINEMATIC then
		call CinematicModeBJ(false, GetPlayersAll())
		call ExecuteFunc("MasterUI_ShowGameButton")
	endif
endfunction

//===========================================================================
// External state helpers
//===========================================================================
function SetBackstorySeen takes boolean flag returns nothing
	set AradionBackstorySeen = flag
	if Aradion != null and QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif
endfunction

function SetRangerMissingReq1Complete takes boolean flag returns nothing
	set RangerMissingReq1Complete = flag
endfunction

private function SyncUnitReferences takes nothing returns nothing
	if udg_Aradion != null and udg_Aradion != Aradion then
		set Aradion = udg_Aradion
	endif
	if udg_Nazgrek != null and udg_Nazgrek != Nazgrek then
		set Nazgrek = udg_Nazgrek
	endif
	if udg_Valeria != null and udg_Valeria != Valeria then
		set Valeria = udg_Valeria
	endif
endfunction

private function ResolveDialogHero takes nothing returns unit
	if SelectedHero != null and QuestGiver_IsUnitAlive(SelectedHero) then
		return SelectedHero
	endif
	return QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function CanOfferRangerMissing takes nothing returns boolean
	return AradionBackstorySeen
endfunction

private function GetDialogHeroName takes unit hero returns string
	return QuestGiver_GetHeroName(hero)
endfunction

private function AddHeroLine takes integer seq, unit hero, string text, string nazgrekSound returns nothing
	if hero == null then
		return
	endif
	if hero == Nazgrek then
		call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", text, nazgrekSound, true)
	else
		call DialogSystem_AddLine(seq, hero, GetDialogHeroName(hero), text, "", true)
	endif
endfunction

private function AddHeroLookAtAradionLine takes integer seq, unit hero, string text, string nazgrekSound returns nothing
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
	endif
	call AddHeroLine(seq, hero, text, nazgrekSound)
endfunction

private function RemoveRangerMissingEscortDestination takes nothing returns nothing
	if RangerMissingEscortDestination != null then
		call RemoveRect(RangerMissingEscortDestination)
		set RangerMissingEscortDestination = null
	endif
endfunction

private function StartValeriaDialogCameraSafe takes real rotationOffset, real fov returns nothing
	call DialogSystem_StartDialogCamera(Player(0), Valeria, 750.00, 50.00, 355.00, rotationOffset, CAMERA_CLOSE_FAR_Z, fov, 0.00, true, USE_DIALOG_CAMERA)
endfunction

private function StopFollow takes unit follower returns nothing
	if follower != null and QuestGiver_IsUnitAlive(follower) then
		call FollowSystem_RemoveUnit(follower)
	endif
endfunction

private function AddValeriaCompanion takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) and not ValeriaCompanionActive then
		call QuestGiver_AddCompanion(Valeria, VALERIA_COMPANION_ICON)
		set ValeriaCompanionActive = true
	endif
endfunction

private function RemoveValeriaCompanion takes nothing returns nothing
	if Valeria != null and ValeriaCompanionActive then
		call QuestGiver_RemoveCompanion(Valeria)
	endif
	set ValeriaCompanionActive = false
endfunction

private function PauseValeriaPatrolInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call PatrolSystem_Pause(Valeria)
	endif
endfunction

private function ContinueValeriaPatrolInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call PatrolSystem_Continue(Valeria)
	endif
endfunction

private function StopValeriaPatrolInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call PatrolSystem_Stop(Valeria)
	endif
endfunction

private function StartValeriaHomePatrolInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call ExecuteFunc("ValeriaMovementStart")
	endif
endfunction

private function PlaceValeriaNearAradion takes real offset returns nothing
	local real facing
	local real x
	local real y
	if Aradion == null or Valeria == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(Aradion) or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call StopFollow(Valeria)
	call StopValeriaPatrolInternal()
	set facing = GetUnitFacing(Aradion) * bj_DEGTORAD
	set x = GetUnitX(Aradion) + offset * Cos(facing)
	set y = GetUnitY(Aradion) + offset * Sin(facing)
	call SetUnitPosition(Valeria, x, y)
	call SetUnitFacing(Valeria, GetUnitFacing(Aradion))
	call IssueImmediateOrder(Valeria, "stop")
endfunction

private function MoveValeriaHomeInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitInvulnerable(Valeria, false)
		call IssuePointOrder(Valeria, "move", GetRectCenterX(gg_rct_ValeriaNewPos), GetRectCenterY(gg_rct_ValeriaNewPos))
	endif
endfunction

private function PlaceValeriaAtAmbushInternal takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitPosition(Valeria, GetRectCenterX(gg_rct_ValeriaAmbushPos), GetRectCenterY(gg_rct_ValeriaAmbushPos))
		call IssueImmediateOrder(Valeria, "stop")
	endif
endfunction

private function RemoveValeriaColdArrows takes nothing returns nothing
	local timer t = GetExpiredTimer()
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call UnitRemoveAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	endif
	if t == ValeriaEncounterArrowTimer then
		set ValeriaEncounterArrowTimer = null
	endif
	if t != null then
		call DestroyTimer(t)
	endif
endfunction

private function ActivateValeriaColdArrowsTemporary takes nothing returns nothing
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call UnitAddAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	call IssueImmediateOrder(Valeria, "coldarrows")
	if ValeriaEncounterArrowTimer != null then
		call DestroyTimer(ValeriaEncounterArrowTimer)
	endif
	set ValeriaEncounterArrowTimer = CreateTimer()
	call TimerStart(ValeriaEncounterArrowTimer, VALERIA_ENCOUNTER_ARROW_DURATION, false, function RemoveValeriaColdArrows)
endfunction

private function AddAradionCompanion takes nothing returns nothing
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) and not AradionCompanionActive then
		call QuestGiver_AddCompanion(Aradion, ARADION_COMPANION_ICON)
		set AradionCompanionActive = true
	endif
endfunction

private function RemoveAradionCompanion takes nothing returns nothing
	if Aradion != null and AradionCompanionActive then
		call QuestGiver_RemoveCompanion(Aradion)
	endif
	set AradionCompanionActive = false
endfunction

private function DisableRangerMissingDeathTrigger takes nothing returns nothing
	if RangerMissingValeriaDeathTrigger != null then
		call DestroyTrigger(RangerMissingValeriaDeathTrigger)
		set RangerMissingValeriaDeathTrigger = null
	endif
endfunction

private function DisableRiftsFailTriggers takes nothing returns nothing
	if RiftsValeriaFailTrigger != null then
		call DestroyTrigger(RiftsValeriaFailTrigger)
		set RiftsValeriaFailTrigger = null
	endif
	if RiftsAradionFailTrigger != null then
		call DestroyTrigger(RiftsAradionFailTrigger)
		set RiftsAradionFailTrigger = null
	endif
endfunction

private function StartFieldCompanions takes unit hero returns nothing
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	call AddValeriaCompanion()
	call AddAradionCompanion()
	if hero != null then
		if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
			call FollowSystem_SetFollow(Valeria, hero, FOLLOW_MAX_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
		endif
		if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
			call FollowSystem_SetFollow(Aradion, hero, FOLLOW_MAX_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
		endif
	endif
endfunction

private function StopFieldCompanions takes nothing returns nothing
	call StopFollow(Valeria)
	call StopFollow(Aradion)
	call RemoveValeriaCompanion()
	call RemoveAradionCompanion()
endfunction

private function StopRangerMissingEscortInternal takes nothing returns nothing
	local QuestData q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_UnregisterEscortRequirement(q.id, 2)
	endif
	call StopFollow(Valeria)
	call RemoveValeriaCompanion()
	call DisableRangerMissingDeathTrigger()
	call RemoveRangerMissingEscortDestination()
	set RangerMissingEscortActive = false
endfunction

private function RecreateValeriaAtHome takes nothing returns nothing
	local player ownerP
	local integer unitTypeId
	local real x
	local real y
	local real facing = 252.00
	local unit oldValeria

	if Valeria == null then
		return
	endif

	set oldValeria = Valeria
	set ownerP = Player(VALERIA_HOME_OWNER)
	set unitTypeId = GetUnitTypeId(oldValeria)
	set x = GetRectCenterX(gg_rct_ValeriaNewPos)
	set y = GetRectCenterY(gg_rct_ValeriaNewPos)

	call StopFollow(oldValeria)
	call RemoveValeriaCompanion()
	call RemoveUnit(oldValeria)

	set Valeria = CreateUnit(ownerP, unitTypeId, x, y, facing)
	set udg_Valeria = Valeria
	call ExecuteFunc("qAradion_RegisterValeriaEncounterProximity")
	call UnitAddAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	call IssueImmediateOrder(Valeria, "coldarrows")
	// TODO OLDGUI PARITY: add Valeria's post-reunion Dash ability here once its custom rawcode is identified in the JASS/object data pipeline.
	call StartValeriaHomePatrolInternal()
endfunction

private function RecreateValeriaAtAmbush takes nothing returns nothing
	local player ownerP
	local integer unitTypeId
	local real x
	local real y
	local real facing = 257.00
	local unit oldValeria

	if Valeria == null then
		return
	endif

	set oldValeria = Valeria
	set ownerP = Player(PLAYER_NEUTRAL_PASSIVE)
	set unitTypeId = GetUnitTypeId(oldValeria)
	set x = GetRectCenterX(gg_rct_ValeriaAmbushPos)
	set y = GetRectCenterY(gg_rct_ValeriaAmbushPos)

	call StopFollow(oldValeria)
	call RemoveValeriaCompanion()
	call RemoveUnit(oldValeria)

	set Valeria = CreateUnit(ownerP, unitTypeId, x, y, facing)
	set udg_Valeria = Valeria
	call UnitAddAbility(Valeria, ABIL_VALERIA_GHOST)
	call IssueImmediateOrder(Valeria, "stop")
	call ExecuteFunc("qAradion_RegisterValeriaEncounterProximity")
endfunction

private function ResetValeriaForRetryAtAmbush takes nothing returns nothing
	call SyncUnitReferences()
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call ExecuteFunc("qAradion_ResetValeriaEncounter")
	else
		call RecreateValeriaAtAmbush()
	endif
endfunction

private function StopValeriaEncounterTimers takes nothing returns nothing
	if ValeriaEncounterRandomTimer != null then
		call DestroyTimer(ValeriaEncounterRandomTimer)
		set ValeriaEncounterRandomTimer = null
	endif
	if ValeriaEncounterRangeTimer != null then
		call DestroyTimer(ValeriaEncounterRangeTimer)
		set ValeriaEncounterRangeTimer = null
	endif
	if ValeriaEncounterArrowTimer != null then
		call DestroyTimer(ValeriaEncounterArrowTimer)
		set ValeriaEncounterArrowTimer = null
	endif
endfunction

private function DisableValeriaEncounterDeathTrigger takes nothing returns nothing
	if ValeriaEncounterDeathTrigger != null then
		call DestroyTrigger(ValeriaEncounterDeathTrigger)
		set ValeriaEncounterDeathTrigger = null
	endif
endfunction

private function ClearValeriaEncounterState takes nothing returns nothing
	call StopValeriaEncounterTimers()
	call DisableValeriaEncounterDeathTrigger()
	call DialogSystem_ClearEscapeAction()
	if ValeriaNegotiationDialog != null then
		call DialogSystem_ClearDialog(ValeriaNegotiationDialog)
	endif
	set ValeriaNegotiationButtonCount = 0
	set ValeriaNegotiationPromptPending = false
	set ValeriaEncounterActive = false
	set ValeriaEncounterHero = null
endfunction

private function ResetRangerMissingQuestProgress takes nothing returns nothing
	local QuestData q

	set RangerMissingReq1Complete = false
	call StopRangerMissingEscortInternal()
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = false
	set ValeriaNegotiationPromptPending = false

	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirementCompleted(q.id, 1, false)
		call q.updateRequirementText(1, "Find Valeria")
		call QuestGiver_SetRequirementCompleted(q.id, 2, false)
		call q.updateRequirementText(2, "")
		call q.removeReturnRequirement()
		call q.refreshQuestLog()
	endif
endfunction

private function FailRangerMissingForRetry takes string reason returns nothing
	call StopRangerMissingEscortInternal()
	call QuestGiver_FailQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion, reason)
	call QuestGiver_AbandonQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	call ResetRangerMissingQuestProgress()
	call ResetValeriaForRetryAtAmbush()
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
endfunction

private function OnRangerMissingValeriaDamaged takes nothing returns nothing
	local real vx
	local real vy
	if not RangerMissingEscortActive or Valeria == null then
		return
	endif
	if QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_READY_TURNIN then
		call StopRangerMissingEscortInternal()
		if Aradion != null and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) then
			set vx = GetUnitX(Aradion) + 200.00 * Cos(GetUnitFacing(Aradion) * bj_DEGTORAD)
			set vy = GetUnitY(Aradion) + 200.00 * Sin(GetUnitFacing(Aradion) * bj_DEGTORAD)
			call IssuePointOrder(Valeria, "move", vx, vy)
		endif
		call BlzSetEventDamage(0.00)
		return
	endif
	if GetEventDamage() < GetWidgetLife(Valeria) - 0.41 then
		return
	endif
	call BlzSetEventDamage(GetWidgetLife(Valeria) - 1.00)
	call FailRangerMissingForRetry("Valeria was lost.")
endfunction

private function EnableRangerMissingDeathTrigger takes nothing returns nothing
	call DisableRangerMissingDeathTrigger()
	if Valeria == null then
		return
	endif
	set RangerMissingValeriaDeathTrigger = CreateTrigger()
	call TriggerRegisterUnitEvent(RangerMissingValeriaDeathTrigger, Valeria, EVENT_UNIT_DAMAGED)
	call TriggerAddAction(RangerMissingValeriaDeathTrigger, function OnRangerMissingValeriaDamaged)
endfunction

private function StartRangerMissingEscortInternal takes nothing returns nothing
	local QuestData q
	local unit hero
	local real ax
	local real ay

	call SyncUnitReferences()
	if Aradion == null or Valeria == null then
		return
	endif

	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q == 0 then
		return
	endif

	if not RangerMissingReq1Complete then
		set RangerMissingReq1Complete = true
		call QuestGiver_SetRequirementCompleted(q.id, 1, true)
	endif

	call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	call q.updateRequirementText(1, "Find Valeria")
	call q.setRequirement(2, "Escort Valeria to Aradion")
	call q.updateRequirementText(2, "Escort Valeria to Aradion")
	call q.removeReturnRequirement()
	call QuestGiver_UnregisterEscortRequirement(q.id, 2)
	call RemoveRangerMissingEscortDestination()
	set ax = GetUnitX(Aradion)
	set ay = GetUnitY(Aradion)
	set RangerMissingEscortDestination = Rect(ax - RANGER_ESCORT_DEST_RADIUS, ay - RANGER_ESCORT_DEST_RADIUS, ax + RANGER_ESCORT_DEST_RADIUS, ay + RANGER_ESCORT_DEST_RADIUS)
	call QuestGiver_RegisterEscortRequirement(q.id, Aradion, 2, Valeria, RangerMissingEscortDestination, "Aradion")
	call QuestGiver_SetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion, QUEST_STATE_IN_PROGRESS)
	call q.refreshQuestLog()

	set hero = ResolveDialogHero()
	call AddValeriaCompanion()
	if hero != null then
		call FollowSystem_SetFollow(Valeria, hero, FOLLOW_MAX_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
	endif
	call EnableRangerMissingDeathTrigger()
	set RangerMissingEscortActive = true
endfunction

//===========================================================================
// Valeria encounter ownership
//===========================================================================
private function IsValidValeriaEncounterHero takes unit hero returns boolean
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		return false
	endif
	if IsUnitType(hero, UNIT_TYPE_STRUCTURE) then
		return false
	endif
	if ALLOW_NAZGREK and hero == Nazgrek then
		return true
	endif
	if ALLOW_ZULKIS and hero == udg_Zulkis then
		return true
	endif
	return false
endfunction

private function IsRangerMissingQuestOpen takes nothing returns boolean
	return QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

private function GetValeriaEncounterHero takes nothing returns unit
	if ValeriaEncounterHero != null and QuestGiver_IsUnitAlive(ValeriaEncounterHero) then
		return ValeriaEncounterHero
	endif
	return ResolveDialogHero()
endfunction

private function ResetValeriaEncounterToAmbush takes nothing returns nothing
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = false
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call StopFollow(Valeria)
		call RemoveValeriaCompanion()
		call UnitAddAbility(Valeria, ABIL_VALERIA_GHOST)
		call UnitRemoveAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
		call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
		call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 2.00)
		call SetWidgetLife(Valeria, BlzGetUnitMaxHP(Valeria))
		call SetUnitOwner(Valeria, Player(PLAYER_NEUTRAL_PASSIVE), true)
		call PlaceValeriaAtAmbushInternal()
	endif
endfunction

private function FailValeriaEncounter takes string reason returns nothing
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = true
	if IsRangerMissingQuestOpen() then
		call FailRangerMissingForRetry(reason)
	else
		call ResetValeriaForRetryAtAmbush()
	endif
endfunction

private function RestoreValeriaEncounterMoveSpeed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
	endif
	if t != null then
		call DestroyTimer(t)
	endif
endfunction

private function OnValeriaEncounterRandomTick takes nothing returns nothing
	local real x
	local real y
	local real distance
	local real angle
	local timer t
	if not ValeriaEncounterActive or ValeriaEncounterResolved or Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set distance = GetRandomReal(VALERIA_ENCOUNTER_RANDOM_MIN_OFFSET, VALERIA_ENCOUNTER_RANDOM_MAX_OFFSET)
	set angle = GetRandomReal(0.00, 360.00) * bj_DEGTORAD
	set x = GetUnitX(Valeria) + distance * Cos(angle)
	set y = GetUnitY(Valeria) + distance * Sin(angle)
	call SetUnitMoveSpeed(Valeria, VALERIA_ENCOUNTER_SPEED_BOOST)
	call IssuePointOrder(Valeria, "move", x, y)
	call DestroyEffect(AddSpecialEffectTarget("Abilities\\Spells\\Items\\AIsp\\SpeedTarget.mdl", Valeria, "overhead"))
	set t = CreateTimer()
	call TimerStart(t, VALERIA_ENCOUNTER_SPEED_RESET_DELAY, false, function RestoreValeriaEncounterMoveSpeed)
endfunction

private function OnValeriaEncounterRangeTick takes nothing returns nothing
	local unit hero = GetValeriaEncounterHero()
	if not ValeriaEncounterActive or ValeriaEncounterResolved or Valeria == null or hero == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(Valeria) or not QuestGiver_IsUnitAlive(hero) then
		return
	endif
	if not QuestGiver_IsWithinRange(Valeria, hero, VALERIA_ENCOUNTER_RESET_DISTANCE) then
		call DisplayTextToForce(GetPlayersAll(), "|cffd45e19You've lost Valeria. She slips back into the ruins.|r")
		call ResetValeriaEncounterToAmbush()
	endif
endfunction

private function OnValeriaEncounterDeath takes nothing returns nothing
	if GetTriggerUnit() != Valeria then
		return
	endif
	call FailValeriaEncounter("Valeria was lost.")
endfunction

private function EnableValeriaEncounterDeathTrigger takes nothing returns nothing
	call DisableValeriaEncounterDeathTrigger()
	if Valeria == null then
		return
	endif
	set ValeriaEncounterDeathTrigger = CreateTrigger()
	call TriggerRegisterUnitEvent(ValeriaEncounterDeathTrigger, Valeria, EVENT_UNIT_DEATH)
	call TriggerAddAction(ValeriaEncounterDeathTrigger, function OnValeriaEncounterDeath)
endfunction

private function StartValeriaEncounterLoop takes nothing returns nothing
	call StopValeriaEncounterTimers()
	call EnableValeriaEncounterDeathTrigger()
	set ValeriaEncounterRandomTimer = CreateTimer()
	call TimerStart(ValeriaEncounterRandomTimer, VALERIA_ENCOUNTER_RANDOM_PERIOD, true, function OnValeriaEncounterRandomTick)
	set ValeriaEncounterRangeTimer = CreateTimer()
	call TimerStart(ValeriaEncounterRangeTimer, VALERIA_ENCOUNTER_RANGE_CHECK_PERIOD, true, function OnValeriaEncounterRangeTick)
endfunction

private function GetValeriaNegotiationPrompt takes integer lineId returns string
	if lineId == 1 then
		return "You are outmatched. Stand aside, or fall."
	elseif lineId == 2 then
		return "You have no right to stand in my way."
	elseif lineId == 3 then
		return "Enough! I'll make you listen by force."
	elseif lineId == 4 then
		return "I'm not like the other orcs."
	elseif lineId == 5 then
		return "You're wasting both our time. Stand down."
	elseif lineId == 6 then
		return "I'm just passing by."
	elseif lineId == 7 then
		return "I'll show you the power of the Earth Mother!"
	elseif lineId == 8 then
		return "I am not your enemy!"
	elseif lineId == 9 then
		return "I will not harm you."
	endif
	return "I've spoken with Aradion. He told me to find you."
endfunction

private function GetValeriaNegotiationHeroSound takes integer lineId returns string
	if lineId == 1 then
		return "Nazgrek_0344"
	elseif lineId == 2 then
		return "Nazgrek_0345"
	elseif lineId == 3 then
		return "Nazgrek_0346"
	elseif lineId == 4 then
		return "Nazgrek_0347"
	elseif lineId == 5 then
		return "Nazgrek_0348"
	elseif lineId == 6 then
		return "Nazgrek_0349"
	elseif lineId == 7 then
		return "Nazgrek_0350"
	elseif lineId == 8 then
		return "Nazgrek_0351"
	elseif lineId == 9 then
		return "Nazgrek_0352"
	endif
	return "Nazgrek_0353"
endfunction

private function GetValeriaNegotiationResponse takes integer lineId returns string
	if lineId == 1 then
		return "Then I shall fall, but so will you!"
	elseif lineId == 2 then
		return "This is my land - not yours!"
	elseif lineId == 3 then
		return "Try it, beast! My bow will show you force!"
	elseif lineId == 4 then
		return "Orc tongues are venom - I won't be deceived!"
	elseif lineId == 5 then
		return "Never! Not while I still draw breath!"
	elseif lineId == 6 then
		return "Then allow me to pass you to the Shadowlands!"
	elseif lineId == 7 then
		return "Warmonger!"
	elseif lineId == 8 then
		return "Silence, you bloodthirsty beast!"
	elseif lineId == 9 then
		return "Lies! All lies!"
	endif
	return "...Aradion? He... lives?"
endfunction

private function GetValeriaNegotiationResponseSound takes integer lineId returns string
	if lineId == 1 then
		return "Valeria_0005"
	elseif lineId == 2 then
		return "Valeria_0006"
	elseif lineId == 3 then
		return "Valeria_0007"
	elseif lineId == 4 then
		return "Valeria_0008"
	elseif lineId == 5 then
		return "Valeria_0009"
	elseif lineId == 6 then
		return "Valeria_0010"
	elseif lineId == 7 then
		return "Valeria_0011"
	elseif lineId == 8 then
		return "Valeria_0012"
	elseif lineId == 9 then
		return "Valeria_0013"
	endif
	return "Valeria_0014"
endfunction

private function RunValeriaNegotiationEscAction takes nothing returns nothing
	call ExecuteFunc("qAradion_TryOpenValeriaNegotiation")
endfunction

private function OnValeriaSequenceStart takes nothing returns nothing
	call EnableUserControl(false)
	call QuestGiver_CloseActiveDialog()
	call ExecuteFunc("TasQuestBox_Hide")
	call EnterCinematicMode()
endfunction

private function BeginValeriaNegotiationSequence takes nothing returns nothing
	call EnableUserControl(false)
	call QuestGiver_CloseActiveDialog()
	if ValeriaNegotiationDialog != null then
		call DialogSystem_HideDialog(ValeriaNegotiationDialog, Player(0))
	endif
	call ExecuteFunc("TasQuestBox_Hide")
	call ExecuteFunc("MasterUI_HideGameButton")
endfunction

private function QueueValeriaNegotiationPrompt takes nothing returns nothing
	set ValeriaNegotiationPromptPending = true
	call DialogSystem_SetEscapeAction(function RunValeriaNegotiationEscAction)
	call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 5.00, "|cffd45e19Press ESC to persuade Valeria.|r")
endfunction

private function OnValeriaEncounterProximity takes nothing returns nothing
	local unit hero = GetTriggerUnit()
	call SyncUnitReferences()
	if not IsValidValeriaEncounterHero(hero) then
		return
	endif
	if not IsRangerMissingQuestOpen() then
		return
	endif
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set ValeriaEncounterHero = hero
	call ExecuteFunc("qAradion_StartValeriaEncounterFromPendingHero")
endfunction

private function DestroyValeriaEncounterProximityTrigger takes nothing returns nothing
	if ValeriaEncounterProximityTrigger != null then
		call DestroyTrigger(ValeriaEncounterProximityTrigger)
		set ValeriaEncounterProximityTrigger = null
	endif
endfunction

private function RegisterValeriaEncounterProximityTrigger takes nothing returns nothing
	call DestroyValeriaEncounterProximityTrigger()
	call SyncUnitReferences()
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set ValeriaEncounterProximityTrigger = CreateTrigger()
	call TriggerRegisterUnitInRange(ValeriaEncounterProximityTrigger, Valeria, VALERIA_ENCOUNTER_TRIGGER_RANGE, null)
	call TriggerAddAction(ValeriaEncounterProximityTrigger, function OnValeriaEncounterProximity)
endfunction

private function RunValeriaNegotiationButton takes nothing returns nothing
	call ExecuteFunc("qAradion_HandleValeriaNegotiationButton")
endfunction

private function RunUpdateQuestRangerMissing takes nothing returns nothing
	call ExecuteFunc("qAradion_TriggerRangerMissingUpdate")
endfunction

private function TryOpenValeriaNegotiationInternal takes nothing returns nothing
	local integer i
	local integer swapIndex
	local integer temp
	local button b
	if not ValeriaEncounterActive or ValeriaEncounterResolved then
		return
	endif
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set ValeriaEncounterHero = GetValeriaEncounterHero()
	if ValeriaEncounterHero == null or not QuestGiver_IsWithinRange(Valeria, ValeriaEncounterHero, VALERIA_NEGOTIATION_MAX_DISTANCE) then
		call DisplayTextToForce(GetPlayersAll(), "|cffd45e19You must stay close to Valeria to persuade her.|r")
		return
	endif
	set ValeriaNegotiationPromptPending = false
	call DialogSystem_ClearEscapeAction()
	if ValeriaNegotiationDialog == null then
		set ValeriaNegotiationDialog = DialogSystem_CreateDialog("Persuade Valeria")
	endif
	call DialogSystem_ClearDialog(ValeriaNegotiationDialog)
	call DialogSystem_SetTitle(ValeriaNegotiationDialog, "Persuade Valeria")
	set i = 1
	loop
		exitwhen i > 10
		set ValeriaNegotiationLineIds[i] = i
		set i = i + 1
	endloop
	set i = 1
	loop
		exitwhen i > 10
		set swapIndex = GetRandomInt(i, 10)
		set temp = ValeriaNegotiationLineIds[i]
		set ValeriaNegotiationLineIds[i] = ValeriaNegotiationLineIds[swapIndex]
		set ValeriaNegotiationLineIds[swapIndex] = temp
		set i = i + 1
	endloop
	set ValeriaNegotiationButtonCount = 0
	set i = 1
	loop
		exitwhen i > 5
		set ValeriaNegotiationButtonCount = ValeriaNegotiationButtonCount + 1
		set b = DialogSystem_AddButton(ValeriaNegotiationDialog, GetValeriaNegotiationPrompt(ValeriaNegotiationLineIds[i]), 0)
		set ValeriaNegotiationButtons[ValeriaNegotiationButtonCount] = b
		call DialogSystem_BindButtonCode(b, function RunValeriaNegotiationButton)
		set i = i + 1
	endloop
	call DialogSystem_ShowDialog(ValeriaNegotiationDialog, Player(0))
endfunction

private function OnValeriaResponseEnd takes nothing returns nothing
	local unit hero = GetValeriaEncounterHero()
	call DialogSystem_StopDialogCamera(Player(0), 2.0, USE_DIALOG_CAMERA)
	call EnableUserControl(true)
	call ExecuteFunc("MasterUI_ShowGameButton")
	if hero != null and Valeria != null and QuestGiver_IsUnitAlive(hero) and QuestGiver_IsUnitAlive(Valeria) then
		call IssuePointOrder(Valeria, "attack", GetUnitX(hero), GetUnitY(hero))
	endif
	call QueueValeriaNegotiationPrompt()
endfunction

private function OnValeriaSuccessEnd takes nothing returns nothing
	call DialogSystem_StopDialogCamera(Player(0), 2.0, USE_DIALOG_CAMERA)
	call EnableUserControl(true)
	call ExecuteFunc("MasterUI_ShowGameButton")
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = true
	call RunUpdateQuestRangerMissing()
endfunction

private function OnValeriaIntroEnd takes nothing returns nothing
	local unit hero = GetValeriaEncounterHero()
	call DialogSystem_StopDialogCamera(Player(0), 2.0, USE_DIALOG_CAMERA)
	call ExitCinematicMode()
	call EnableUserControl(true)
	if not ValeriaEncounterActive or ValeriaEncounterResolved or Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call ResetUnitAnimation(Valeria)
	call SetUnitOwner(Valeria, Player(VALERIA_HOSTILE_OWNER), true)
	call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 200.00)
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		call IssuePointOrder(Valeria, "attack", GetUnitX(hero), GetUnitY(hero))
	endif
	call StartValeriaEncounterLoop()
	call QueueValeriaNegotiationPrompt()
endfunction

private function PlayValeriaNegotiationResponse takes integer lineId returns nothing
	local integer seq
	local unit hero = GetValeriaEncounterHero()
	call StartValeriaDialogCameraSafe(45.00, 60.00)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, function BeginValeriaNegotiationSequence, function OnValeriaResponseEnd)
	if hero != null then
		call DialogSystem_AddMakeFaceEachOther(seq, hero, Valeria, 0.50, 0.0)
		call AddHeroLine(seq, hero, GetValeriaNegotiationPrompt(lineId), GetValeriaNegotiationHeroSound(lineId))
	endif
	call DialogSystem_AddLine(seq, Valeria, "Valeria", GetValeriaNegotiationResponse(lineId), GetValeriaNegotiationResponseSound(lineId), true)
	call DialogSystem_PlaySequence(seq, Player(0), Valeria)
	call ActivateValeriaColdArrowsTemporary()
endfunction

private function PlayValeriaNegotiationSuccess takes nothing returns nothing
	local integer seq
	local unit hero = GetValeriaEncounterHero()
	local real x
	local real y
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call StopValeriaEncounterTimers()
	call DisableValeriaEncounterDeathTrigger()
	call IssueImmediateOrder(Valeria, "stop")
	call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
	call UnitRemoveAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 2.00)
	call SetWidgetLife(Valeria, BlzGetUnitMaxHP(Valeria))
	call SetUnitOwner(Valeria, Player(VALERIA_FRIENDLY_OWNER), true)
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		set x = GetUnitX(hero) + 400.00 * Cos(GetUnitFacing(hero) * bj_DEGTORAD)
		set y = GetUnitY(hero) + 400.00 * Sin(GetUnitFacing(hero) * bj_DEGTORAD)
		call IssuePointOrder(Valeria, "move", x, y)
	endif
	call StartValeriaDialogCameraSafe(45.00, 60.00)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, function BeginValeriaNegotiationSequence, function OnValeriaSuccessEnd)
	if hero != null then
		call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.50, 0.0)
		call AddHeroLine(seq, hero, "I've spoken with Aradion. He told me to find you.", "Nazgrek_0353")
	endif
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "...Aradion? He... lives?", "Valeria_0014", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "If he trusts you, then perhaps I must as well. For his word has never failed me.", "Valeria_0015", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "If you speak the truth, then take me to him. Now.", "Valeria_0019", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "But know this, orc - I'll be watching you.", "Valeria_0020", true)
	call DialogSystem_PlaySequence(seq, Player(0), Valeria)
endfunction

public function HandleValeriaNegotiationButton takes nothing returns nothing
	local integer i = 1
	local button clicked = DialogSystem_LastButton
	local integer lineId = 0
	set ValeriaNegotiationPromptPending = false
	loop
		exitwhen i > ValeriaNegotiationButtonCount
		if clicked == ValeriaNegotiationButtons[i] then
			set lineId = ValeriaNegotiationLineIds[i]
			set i = ValeriaNegotiationButtonCount + 1
		else
			set i = i + 1
		endif
	endloop
	if lineId == 0 then
		return
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call IssueImmediateOrder(Valeria, "stop")
	endif
	if lineId == 10 then
		call PlayValeriaNegotiationSuccess()
	else
		call PlayValeriaNegotiationResponse(lineId)
	endif
endfunction

private function StartValeriaEncounterInternal takes unit hero returns nothing
	local integer seq
	call SyncUnitReferences()
	if not IsRangerMissingQuestOpen() then
		return
	endif
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	if ValeriaEncounterResolved then
		return
	endif
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	if hero == null then
		return
	endif
	if ValeriaEncounterActive then
		set ValeriaEncounterHero = hero
		call TryOpenValeriaNegotiationInternal()
		return
	endif
	set SelectedHero = hero
	set ValeriaEncounterHero = hero
	set ValeriaEncounterActive = true
	set ValeriaEncounterResolved = false
	set ValeriaNegotiationPromptPending = false
	call DialogSystem_ClearEscapeAction()
	call StopFollow(Valeria)
	call RemoveValeriaCompanion()
	call StopValeriaPatrolInternal()
	call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
	call StartValeriaDialogCameraSafe(180.00, 70.00)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, function OnValeriaSequenceStart, function OnValeriaIntroEnd)
	call SetUnitAnimation(Valeria, "stand ready")
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, hero, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Hold, intruder! Another step and you bleed where you stand!", "Valeria_0001", true)
	call AddHeroLine(seq, hero, "You must be Valeria.", "Nazgrek_0340")
	call AddHeroLine(seq, hero, "I am not your enemy...", "Nazgrek_0341")
	call DialogSystem_AddDelay(seq, 1.50)
	call DialogSystem_AddDelay(seq, 1.00)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Filthy orc lies! I'll drop you where you stand!", "Valeria_0002", true)
	call DialogSystem_PlaySequence(seq, Player(0), Valeria)
endfunction

//===========================================================================
// In-progress greet helpers
//===========================================================================
private function IsRangerMissingInProgress takes nothing returns boolean
	return QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

private function IsCrystalsHopeInProgress takes nothing returns boolean
	return QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
endfunction

private function IsFadingSparksInProgress takes nothing returns boolean
	return QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
endfunction

private function IsRiftsCorruptionInProgress takes nothing returns boolean
	return QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
endfunction

private function GetInProgressQuestId takes nothing returns integer
	if AradionLastAcceptedQuest == ARADION_QID_RANGER and IsRangerMissingInProgress() then
		return ARADION_QID_RANGER
	endif
	if AradionLastAcceptedQuest == ARADION_QID_CRYSTALS and IsCrystalsHopeInProgress() then
		return ARADION_QID_CRYSTALS
	endif
	if AradionLastAcceptedQuest == ARADION_QID_FADING and IsFadingSparksInProgress() then
		return ARADION_QID_FADING
	endif
	if AradionLastAcceptedQuest == ARADION_QID_RIFTS and IsRiftsCorruptionInProgress() then
		return ARADION_QID_RIFTS
	endif

	if IsRangerMissingInProgress() then
		return ARADION_QID_RANGER
	endif
	if IsCrystalsHopeInProgress() then
		return ARADION_QID_CRYSTALS
	endif
	if IsFadingSparksInProgress() then
		return ARADION_QID_FADING
	endif
	if IsRiftsCorruptionInProgress() then
		return ARADION_QID_RIFTS
	endif

	return 0
endfunction

private function AddInProgressGreet takes integer seq, unit hero returns boolean
	local integer roll
	local integer questId = GetInProgressQuestId()
	if questId == 0 then
		return false
	endif
	set roll = GetRandomInt(1, 2)
	if questId == ARADION_QID_RANGER then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria is still missing... Tell me you have found her?", "Aradion_0037", true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "More and more wraiths are circling around Elarindor... please, do not let her be lost to them.", "Aradion_0038", true)
		endif
		if GetRandomInt(1, 2) == 1 then
			call AddHeroLine(seq, hero, "I'll see if I come across her.", "Nazgrek_0337")
		endif
		return true
	endif
	if questId == ARADION_QID_CRYSTALS then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Have you managed to obtain any crystal shards?", "Aradion_0045", true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Without those shards, the hope slips further from our grasp.", "Aradion_0046", true)
		endif
		return true
	endif
	if questId == ARADION_QID_FADING then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Our people's shades still drift through the Vale. You must claim their sparks...", "Aradion_0057", true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Do not let their torment go to waste. Bring me what little endures.", "Aradion_0058", true)
		endif
		return true
	endif
	if questId == ARADION_QID_RIFTS then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The rifts are still open. If they are not sealed, the Vale will never heal.", "Aradion_0069", true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Hold the line! Protect Valeria -- protect us both, shaman!", "Aradion_0070", true)
		endif
		return true
	endif
	return false
endfunction

//===========================================================================
// Backstory sequence
//===========================================================================
private function OnSequenceStart takes nothing returns nothing
	call EnableUserControl(false)
	// Enter cinematic mode to enable ESC skip via EVENT_PLAYER_END_CINEMATIC
	call EnterCinematicMode()
endfunction

private function OnSequenceEnd takes nothing returns nothing
	// Exit cinematic mode after greet sequence
	call ExitCinematicMode()
	// Re-enable user control (dialog system will show dialog after this)
	call EnableUserControl(true)
endfunction

private function PlayGreetFirstSequence takes unit hero returns nothing
	local integer seq
	local string heroName
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, function OnSequenceStart, function OnSequenceEnd)
	set heroName = QuestGiver_GetHeroName(hero)
	
	// Make units face each other before dialog starts
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.00)
	endif
	
	// Brief pause after cinematic mode starts (1 second)
	call DialogSystem_AddDelay(seq, 1.0)
	
	if hero != null then
		call DialogSystem_PickGreetLine(hero, heroName)
		call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
		// Pause before Aradion speaks (1 second)
		call DialogSystem_AddDelay(seq, 1.0)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "An… orc? Here? If you came for blood, take mine swiftly. I will not flee…", "Aradion_0001", true)
	call AddHeroLine(seq, hero, "Your blood is not what I seek, elf. I walk the spirit path, not the path of slaughter.", "Nazgrek_0331")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "…No. Orcs do not speak so. You… are different.", "Aradion_0002", true)
	call QuestGiver_PlayFirstGreetSequence(Aradion, Player(0), AradionDialog, seq)
endfunction

private function PlayGreetNormalSequence takes unit hero returns nothing
	local integer seq
	local integer roll
	local string heroName
	local boolean handled
	call DebugMsg("PlayGreetNormalSequence: Starting")
	set seq = DialogSystem_CreateSequence()
	call DebugMsg("PlayGreetNormalSequence: Created sequence, seq=" + I2S(seq))
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, function OnSequenceStart, function OnSequenceEnd)
	set heroName = QuestGiver_GetHeroName(hero)
	
	// Make units face each other before dialog starts
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.00)
	endif
	
	// Brief pause after cinematic mode starts (1 second)
	call DialogSystem_AddDelay(seq, 1.0)
	
	if hero != null then
		call DialogSystem_PickGreetLine(hero, heroName)
		call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
		// Pause before Aradion speaks (1 second)
		call DialogSystem_AddDelay(seq, 1.0)
	endif
	set handled = AddInProgressGreet(seq, hero)
	if not handled then
		set roll = GetRandomInt(1, 4)
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I did not expect company in these ruins.", "Aradion_0020", true)
		elseif roll == 2 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes, shaman?", "Aradion_0021", true)
		elseif roll == 3 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Hm? Ah, it's you.", "Aradion_0022", true)
		else
			// Only ask about Valeria if she is in range
			if QuestGiver_IsWithinRange(Aradion, Valeria, VALERIA_RANGE) then
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Have you seen Valeria?", "Aradion_0023", true)
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "She is always on the run...", "Aradion_0024", true)
			else
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes, shaman?", "Aradion_0021", true)
			endif
		endif
	endif
	call DebugMsg("PlayGreetNormalSequence: About to call QuestGiver_PlayGreetSequence")
	call QuestGiver_PlayGreetSequence(seq, Aradion, Player(0), AradionDialog)
	call DebugMsg("PlayGreetNormalSequence: Completed QuestGiver_PlayGreetSequence call")
endfunction

private function ShowDialog takes player p, unit hero returns nothing
	local boolean wasActive
	local boolean isActiveAfter
	call DebugMsg("ShowDialog: Starting")
	set wasActive = DialogSystem_IsSequenceActive()
	call DebugMsg("ShowDialog: wasActive=" + I2S(B2I(wasActive)))
	call DialogSystem_StartDialogCamera(Player(0), Aradion, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK, USE_DIALOG_CAMERA)
	call DebugMsg("ShowDialog: About to play greet sequence")
	call PlayGreetNormalSequence(hero)
	set isActiveAfter = DialogSystem_IsSequenceActive()
	call DebugMsg("ShowDialog: After greet, isActiveAfter=" + I2S(B2I(isActiveAfter)))
	if not wasActive and not isActiveAfter then
		if AradionDialog != null then
			call DebugMsg("Greet sequence failed to start; showing dialog directly")
			call DialogSystem_ShowDialog(AradionDialog, p)
		else
			call DebugMsg("ShowDialog: AradionDialog is null!")
		endif
	else
		call DebugMsg("ShowDialog: Not showing dialog directly (wasActive=" + I2S(B2I(wasActive)) + ", isActiveAfter=" + I2S(B2I(isActiveAfter)) + ")")
	endif
endfunction

//===========================================================================
// Info sequence callbacks
//===========================================================================
private function ReopenDialogAfterInfo takes nothing returns nothing
	local timer t = GetExpiredTimer()
	// Use ExecuteFunc with public wrapper to avoid forward reference
	call DebugMsg("ReopenDialogAfterInfo: Reopening dialog after info sequence") 
	call ExecuteFunc("qAradion_RebuildAndShowDialog")
	call DestroyTimer(t)
endfunction

private function OnInfoStart takes nothing returns nothing
	call EnableUserControl(false)
	set AradionBackstorySeen = true
	call QuestGiver_CloseActiveDialog()
	set AradionDialogCooldown = QuestGiver_StartCooldown(AradionDialogCooldown, DIALOG_COOLDOWN)
	// Enter cinematic mode for ESC skip
	call EnterCinematicMode()
endfunction

private function OnInfoEnd takes nothing returns nothing
	local timer t
	call SyncUnitReferences()
	// Refresh quest state before rebuilding the dialog so Ranger Missing appears immediately.
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif

	// Reopen the dialog on the next tick; a long delay here caused the stale-info flow.
	set t = CreateTimer()
	call TimerStart(t, 0.05, false, function ReopenDialogAfterInfo)
endfunction

private function BuildInfoSequence takes nothing returns integer
	local integer seq
	local unit hero
	local real facing
	local real x
	local real y
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, function OnInfoStart, function OnInfoEnd)

	// Get hero for look-at actions
	set hero = ResolveDialogHero()

	// Calculate ruins position (400 units in front of Aradion)
	if Aradion != null then
		set facing = GetUnitFacing(Aradion) * bj_DEGTORAD
		set x = GetUnitX(Aradion) + 400.00 * Cos(facing)
		set y = GetUnitY(Aradion) + 400.00 * Sin(facing)
	endif

	call DialogSystem_AddLookAtUnit(seq, Aradion, hero, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I see the truth in your eyes. You do not come as foe, but as seeker. Then hear me, shaman, and know the ruin of my people.", "Aradion_0003", true)
	call DialogSystem_AddMakeUnitFacePoint(seq, Aradion, x, y, 0.25, 0.0)
	call DialogSystem_AddLookAtPoint(seq, Aradion, x, y, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "This was once our home - Elarindor. Jewel of Vanguard Vale. A city that shone like a beacon from the light of the arcane energies.", "Aradion_0004", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Then she came... A magister called Lady Serenthia. Cloaked in grace and wisdom, she whispered promises of eternal prosperity. Many of my people heeded her call...", "Aradion_0005", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But all she was - was a lie. Her beauty and voice, the elven form were mere illusion. In truth, she was the witch Zerathis.", "Aradion_0006", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "My beloved Valeria and I begged our kin to turn away... but what are two voices against the choir of greed?", "Aradion_0007", true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call AddHeroLine(seq, hero, "You said... a witch deceived you?", "Nazgrek_0332")
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call AddHeroLine(seq, hero, "Why did your kin trust this witch?", "Nazgrek_0333")
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Her words promised glory - strength to rival Quel'Thalas itself. Her lies were sweet... and my people were starving for more.", "Aradion_0008", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But every promise was poison. Each draught of her 'gift' deepened the hunger, until the hunger itself consumed them.", "Aradion_0009", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now my people are twisted, their flesh withering, their souls bleeding into wraiths. Soon... nothing of them will remain.", "Aradion_0010", true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call AddHeroLine(seq, hero, "The wraiths I see... they were once elves?", "Nazgrek_0334")
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes. Once mothers, fathers, children. Now only hollow echoes bound to the Void by the magic that devoured them.", "Aradion_0011", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The wretched who remain will share the same fate - it is only a matter of time before they too dissolve into wraiths.", "Aradion_0012", true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call AddHeroLine(seq, hero, "And you? How did you resist where others fell?", "Nazgrek_0336")
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I resisted... because I feared. And because Valeria feared with me. Together we begged them to turn away. None listened.", "Aradion_0013", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The witch saw no worth in those who refused her. So she left us alive - to watch the slow death of our kin.", "Aradion_0014", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I have searched, shaman... searched for a cure, an answer, any salvation. But all I have found is despair.", "Aradion_0015", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yet perhaps the spirits you serve have sent you here, to answer the question I cannot solve alone.", "Aradion_0016", true)

	return seq
endfunction

private function PlayInfoSequence takes nothing returns nothing
	if AradionInfoSeq == 0 then
		set AradionInfoSeq = BuildInfoSequence()
	endif
	call DialogSystem_PlaySequence(AradionInfoSeq, Player(0), Aradion)
endfunction

//===========================================================================
// Quest update handlers
//===========================================================================
private function UpdateQuestRangerMissing takes nothing returns nothing
	call SyncUnitReferences()
	if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		return
	endif
	if not ValeriaEncounterResolved and not RangerMissingReq1Complete then
		return
	endif
	if RangerMissingEscortActive and RangerMissingReq1Complete then
		return
	endif
	call DebugMsg("Updating Quest: Ranger Missing")
	call StartRangerMissingEscortInternal()
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

private function ShowFieldLine takes unit speaker, string speakerName, string soundName, string text returns nothing
	if speaker == null or not QuestGiver_IsUnitAlive(speaker) then
		return
	endif
	if soundName != "" then
		call ExSound_Play(soundName, text)
	endif
	call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 5.00, speakerName + ": " + text)
endfunction

private function GetRiftRect takes integer index returns rect
	if index == 1 then
		return gg_rct_ManaRift1
	elseif index == 2 then
		return gg_rct_ManaRift2
	elseif index == 3 then
		return gg_rct_ManaRift3
	endif
	return null
endfunction

private function FindNeutralPassiveUnitInRect takes rect r returns unit
	local group g
	local unit u
	local unit found = null
	if r == null then
		return null
	endif
	set g = CreateGroup()
	call GroupEnumUnitsInRect(g, r, null)
	loop
		set u = FirstOfGroup(g)
		exitwhen u == null
		call GroupRemoveUnit(g, u)
		if GetOwningPlayer(u) == Player(PLAYER_NEUTRAL_PASSIVE) and QuestGiver_IsUnitAlive(u) then
			set found = u
			exitwhen true
		endif
	endloop
	call DestroyGroup(g)
	set g = null
	return found
endfunction

private function EnsureRiftUnit takes integer index returns unit
	local rect r = GetRiftRect(index)
	local unit u = RiftsUnits[index]
	if u != null and QuestGiver_IsUnitAlive(u) then
		return u
	endif
	set u = FindNeutralPassiveUnitInRect(r)
	if u != null then
		set RiftsUnits[index] = u
		set RiftsUnitTypeIds[index] = GetUnitTypeId(u)
		return u
	endif
	if r != null and RiftsUnitTypeIds[index] != 0 then
		set u = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), RiftsUnitTypeIds[index], GetRectCenterX(r), GetRectCenterY(r), bj_UNIT_FACING)
		set RiftsUnits[index] = u
		return u
	endif
	return null
endfunction

private function RegisterRiftUnits takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX
		call EnsureRiftUnit(i)
		set i = i + 1
	endloop
	call ExecuteFunc("qAradion_RegisterRiftsProximity")
endfunction

private function DestroyRiftsProximityTrigger takes nothing returns nothing
	if RiftsProximityTrigger != null then
		call DestroyTrigger(RiftsProximityTrigger)
		set RiftsProximityTrigger = null
	endif
endfunction

private function GetTriggeredRiftIndex takes unit hero returns integer
	local integer i = 1
	local unit riftUnit
	if hero == null then
		return 0
	endif
	loop
		exitwhen i > RIFTS_MAX
		set riftUnit = EnsureRiftUnit(i)
		if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) and QuestGiver_IsWithinRange(riftUnit, hero, RIFTS_TRIGGER_RANGE) then
			return i
		endif
		set i = i + 1
	endloop
	return 0
endfunction

private function PlayRiftsStartBarks takes nothing returns nothing
	local integer roll
	if Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	set roll = GetRandomInt(1, 2)
	if roll == 1 then
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0074", "Stand ready. Once I begin, this place can start to crawl with wraiths.")
	else
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0075", "I will attempt to close this rift. But I cannot fight and focus at once... you must protect me!")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		if GetRandomInt(1, 2) == 1 then
			call ShowFieldLine(Valeria, "Valeria", "Valeria_0072", "We will handle them, just keep your focus on the rift!")
		else
			call ShowFieldLine(Valeria, "Valeria", "Valeria_0073", "We stand ready to defend you!")
		endif
	endif
endfunction

private function StartRiftsRitualInternal takes unit riftUnit, integer riftIndex, unit hero returns nothing
	local real facing
	local real rx
	local real ry
	local real ax
	local real ay
	local real vx
	local real vy
	if riftUnit == null or not QuestGiver_IsUnitAlive(riftUnit) or Aradion == null then
		return
	endif
	set SelectedHero = hero
	set RiftsCurrentRift = riftUnit
	set RiftsCurrentIndex = riftIndex
	set RiftsRitualActive = true
	set RiftsNextWaveN = 1
	call StopFollow(Aradion)
	call StopFollow(Valeria)
	call RemoveAradionCompanion()
	set rx = GetUnitX(riftUnit)
	set ry = GetUnitY(riftUnit)
	set facing = GetUnitFacing(Aradion) * bj_DEGTORAD
	set ax = rx + RIFTS_ARADION_OFFSET * Cos(facing)
	set ay = ry + RIFTS_ARADION_OFFSET * Sin(facing)
	call SetUnitPosition(Aradion, ax, ay)
	call SetUnitFacing(Aradion, bj_RADTODEG * Atan2(ry - ay, rx - ax))
	call IssueImmediateOrder(Aradion, "stop")
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		set vx = ax + RIFTS_VALERIA_OFFSET * Cos(facing)
		set vy = ay + RIFTS_VALERIA_OFFSET * Sin(facing)
		call SetUnitPosition(Valeria, vx, vy)
		call SetUnitFacing(Valeria, GetUnitFacing(Aradion))
		call IssueImmediateOrder(Valeria, "stop")
	endif
	call PlayRiftsStartBarks()
	call IssuePointOrder(Aradion, "blizzard", rx, ry)
	call SetUnitAnimation(Aradion, "spell")
	call ExecuteFunc("qAradion_StartRiftsRuntimeTimersPublic")
endfunction

private function OnRiftsProximity takes nothing returns nothing
	local unit hero = GetTriggerUnit()
	local integer riftIndex
	local unit riftUnit
	call SyncUnitReferences()
	if not RiftsQuestActive or RiftsRitualActive or RiftsAwaitingReturnHome then
		return
	endif
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		return
	endif
	if hero != Nazgrek and hero != udg_Zulkis then
		return
	endif
	if (hero == Nazgrek and not ALLOW_NAZGREK) or (hero == udg_Zulkis and not ALLOW_ZULKIS) then
		return
	endif
	set riftIndex = GetTriggeredRiftIndex(hero)
	if riftIndex <= 0 then
		return
	endif
	set riftUnit = EnsureRiftUnit(riftIndex)
	if riftUnit != null then
		call StartRiftsRitualInternal(riftUnit, riftIndex, hero)
	endif
endfunction

private function RegisterRiftsProximityTrigger takes nothing returns nothing
	local integer i = 1
	local unit riftUnit
	call DestroyRiftsProximityTrigger()
	set RiftsProximityTrigger = CreateTrigger()
	loop
		exitwhen i > RIFTS_MAX
		set riftUnit = EnsureRiftUnit(i)
		if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) then
			call TriggerRegisterUnitInRange(RiftsProximityTrigger, riftUnit, RIFTS_TRIGGER_RANGE, null)
		endif
		set i = i + 1
	endloop
	call TriggerAddAction(RiftsProximityTrigger, function OnRiftsProximity)
endfunction

private function ClearRiftsWaveHandles takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RiftsWaveIndex or i > RIFTS_MAX_WAVES
		if RiftsWaveHandles[i] != 0 then
			call RiftsWaveHandles[i].killAllUnits()
			call RiftsWaveHandles[i].destroy()
			set RiftsWaveHandles[i] = 0
		endif
		set i = i + 1
	endloop
	set RiftsWaveIndex = 0
endfunction

private function StopRiftsRuntimeTimers takes nothing returns nothing
	if RiftsCloseTimer != null then
		call DestroyTimer(RiftsCloseTimer)
		set RiftsCloseTimer = null
	endif
	if RiftsWaveTimer != null then
		call DestroyTimer(RiftsWaveTimer)
		set RiftsWaveTimer = null
	endif
	if RiftsCombatTimer != null then
		call DestroyTimer(RiftsCombatTimer)
		set RiftsCombatTimer = null
	endif
	if RiftsCountdownTimer != null then
		call DestroyTimer(RiftsCountdownTimer)
		set RiftsCountdownTimer = null
	endif
endfunction

private function StopRiftsFieldMonitor takes nothing returns nothing
	if RiftsFieldTimer != null then
		call DestroyTimer(RiftsFieldTimer)
		set RiftsFieldTimer = null
	endif
endfunction

private function ResetRiftsObjectivesForNewRun takes QuestData q returns nothing
	if q == 0 then
		return
	endif
	call q.setRequirement(1, "Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed 0 / 3)")
	call q.updateRequirementText(1, "Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed 0 / 3)")
	call q.setRequirement(2, "Guard Aradion while he closes the rifts")
	call q.updateRequirementText(2, "Guard Aradion while he closes the rifts")
	call q.setRequirement(3, "Both Aradion and Valeria must stay alive")
	call q.updateRequirementText(3, "Both Aradion and Valeria must stay alive")
	call q.setRequirement(4, "")
	call q.updateRequirementText(4, "")
	call q.markRequirementCompleted(1, false)
	call q.markRequirementCompleted(2, false)
	call q.markRequirementCompleted(3, false)
	call q.markRequirementCompleted(4, false)
	call q.refreshQuestLog()
endfunction

private function ReturnRiftsCompanionsHomeInternal takes nothing returns nothing
	call StopFieldCompanions()
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call SetUnitInvulnerable(Aradion, false)
		call SetUnitPosition(Aradion, GetRectCenterX(gg_rct_AradionPos), GetRectCenterY(gg_rct_AradionPos))
		call SetUnitFacing(Aradion, 184.00)
		call IssueImmediateOrder(Aradion, "stop")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitInvulnerable(Valeria, false)
		call SetUnitPosition(Valeria, GetRectCenterX(gg_rct_ValeriaNewPos), GetRectCenterY(gg_rct_ValeriaNewPos))
		call SetUnitFacing(Valeria, 192.00)
		call StartValeriaHomePatrolInternal()
	endif
endfunction

private function HandleRiftsReturnedHome takes nothing returns nothing
	local QuestData q
	if not RiftsAwaitingReturnHome then
		return
	endif
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = true
	call StopRiftsFieldMonitor()
	call ReturnRiftsCompanionsHomeInternal()
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call q.markRequirementCompleted(4, true)
		call q.refreshQuestLog()
	endif
endfunction

private function GetAllowedRiftHeroInRange takes unit riftUnit returns unit
	local unit bestHero = null
	local integer bestLevel = -1
	local integer level
	if riftUnit == null then
		return null
	endif
	if ALLOW_NAZGREK and Nazgrek != null and QuestGiver_IsUnitAlive(Nazgrek) and QuestGiver_IsWithinRange(riftUnit, Nazgrek, RIFTS_TRIGGER_RANGE) then
		set bestHero = Nazgrek
		set bestLevel = GetHeroLevel(Nazgrek)
	endif
	if ALLOW_ZULKIS and udg_Zulkis != null and QuestGiver_IsUnitAlive(udg_Zulkis) and QuestGiver_IsWithinRange(riftUnit, udg_Zulkis, RIFTS_TRIGGER_RANGE) then
		set level = GetHeroLevel(udg_Zulkis)
		if bestHero == null or level > bestLevel then
			set bestHero = udg_Zulkis
			set bestLevel = level
		endif
	endif
	return bestHero
endfunction

private function PlayRiftsIncomingWaveBark takes nothing returns nothing
	local integer roll
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set roll = GetRandomInt(1, 3)
	if roll == 1 then
		call ShowFieldLine(Valeria, "Valeria", "Valeria_0061", "Hold your ground! Don't let them reach Aradion!")
	elseif roll == 2 then
		call ShowFieldLine(Valeria, "Valeria", "Valeria_0062", "The rift is pulling every wrath towards it - brace yourself!")
	else
		call ShowFieldLine(Valeria, "Valeria", "Valeria_0065", "They are too many! Drive them back!")
	endif
endfunction

private function PlayRiftsCombatBark takes nothing returns nothing
	local integer roll
	if Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	set roll = GetRandomInt(1, 3)
	if roll == 1 then
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0076", "Hold them back! Just a little longer!")
	elseif roll == 2 then
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0077", "The rift is still open - I need more time!")
	else
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0078", "Try to keep them away from me!")
	endif
endfunction

private function PlayRiftsFinishBarks takes nothing returns nothing
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		if GetRandomInt(1, 2) == 1 then
			call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0080", "It is done. This rift is sealed.")
		else
			call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0082", "I managed to close this rift.")
		endif
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		if GetRandomInt(1, 2) == 1 then
			call ShowFieldLine(Valeria, "Valeria", "Valeria_0066", "Great job, my love!")
		else
			call ShowFieldLine(Valeria, "Valeria", "Valeria_0068", "You never cease to amaze me, my love.")
		endif
	endif
endfunction

private function PlayRiftsAllClosedBarks takes nothing returns nothing
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0084", "I think this was the last of them. All rifts should now be closed.")
		call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0085", "In time, we will see... It's time to head back to our place.")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call ShowFieldLine(Valeria, "Valeria", "Valeria_0070", "So, is it... over now? Is this the answer to our people's curse?")
		call ShowFieldLine(Valeria, "Valeria", "Valeria_0071", "Gladly.")
	endif
endfunction

private function SpawnRiftsWave takes nothing returns nothing
	local location spawnLoc
	if not RiftsRitualActive or RiftsCurrentRift == null or not QuestGiver_IsUnitAlive(RiftsCurrentRift) then
		return
	endif
	if RiftsWaveIndex >= RIFTS_MAX_WAVES then
		return
	endif
	set spawnLoc = Location(GetUnitX(RiftsCurrentRift), GetUnitY(RiftsCurrentRift))
	set RiftsWaveIndex = RiftsWaveIndex + 1
	if RiftsNextWaveN == 1 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave1(Player(RIFTS_WAVE_OWNER), spawnLoc)
	elseif RiftsNextWaveN == 2 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave2(Player(RIFTS_WAVE_OWNER), spawnLoc)
	elseif RiftsNextWaveN == 3 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave3(Player(RIFTS_WAVE_OWNER), spawnLoc)
	else
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave4(Player(RIFTS_WAVE_OWNER), spawnLoc)
	endif
	set RiftsNextWaveN = GetRandomInt(1, 4)
	call RemoveLocation(spawnLoc)
	call PlayRiftsIncomingWaveBark()
endfunction

private function OnRiftsWaveTick takes nothing returns nothing
	call SpawnRiftsWave()
endfunction

private function OnRiftsCombatTick takes nothing returns nothing
	call PlayRiftsCombatBark()
endfunction

private function OnRiftsCountdownTick takes nothing returns nothing
	local texttag tag
	if not RiftsRitualActive or Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	if RiftsCountdownRemaining <= 0 then
		return
	endif
	set tag = CreateTextTagUnitBJ(I2S(RiftsCountdownRemaining) + "|cffff0000|r", Aradion, 75.00, 10.00, 100.00, 20.00, 20.00, 0.00)
	call SetTextTagVelocityBJ(tag, 0.00, 90.00)
	call SetTextTagPermanent(tag, false)
	call SetTextTagLifespan(tag, 1.00)
	call SetTextTagFadepoint(tag, 0.20)
	set RiftsCountdownRemaining = RiftsCountdownRemaining - 1
	set tag = null
endfunction

private function UpdateQuestRiftsCorruptionInternal takes nothing returns nothing
	local QuestData q
	local string reqText
	call SyncUnitReferences()
	if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	if not IsRiftsCorruptionInProgress() then
		return
	endif
	set RiftsCorruptionCounter = RiftsCorruptionCounter + 1
	set reqText = "Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed " + I2S(RiftsCorruptionCounter) + " / 3)"
	call DebugMsg("Updating Quest: Rifts of Corruption - Counter=" + I2S(RiftsCorruptionCounter))
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q == 0 then
		return
	endif
	call QuestGiver_SetRequirement(q.id, 1, reqText)
	if RiftsCorruptionCounter >= 3 then
		call q.markRequirementCompleted(1, true)
		call q.markRequirementCompleted(2, true)
		call q.markRequirementCompleted(3, true)
		call QuestGiver_AddRequirement(q.id, 4, "Escort both Aradion and Valeria back to Aradion")
		call q.markRequirementCompleted(4, false)
		call q.refreshQuestLog()
		set RiftsAwaitingReturnHome = true
		set RiftsReturnedHome = false
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_READY_TURNIN)
	else
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_IN_PROGRESS)
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
endfunction

private function FinishRiftsCurrentRitual takes nothing returns nothing
	local unit hero
	call SyncUnitReferences()
	if not RiftsQuestActive then
		return
	endif
	call StopRiftsRuntimeTimers()
	call ClearRiftsWaveHandles()
	if RiftsCurrentRift != null and QuestGiver_IsUnitAlive(RiftsCurrentRift) then
		call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl", GetUnitX(RiftsCurrentRift), GetUnitY(RiftsCurrentRift)))
		call KillUnit(RiftsCurrentRift)
	endif
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call SetUnitAnimation(Aradion, "stand")
	endif
	call AddAradionCompanion()
	call PlayRiftsFinishBarks()
	call UpdateQuestRiftsCorruptionInternal()
	set hero = ResolveDialogHero()
	if hero != null then
		if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
			call FollowSystem_SetFollow(Valeria, hero, FOLLOW_MAX_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
		endif
		if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
			call FollowSystem_SetFollow(Aradion, hero, FOLLOW_MAX_DISTANCE, false, 0.00, FOLLOW_STYLE_PASSIVE, true, true)
		endif
	endif
	if RiftsCorruptionCounter >= 3 then
		call PlayRiftsAllClosedBarks()
	else
		if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
			call ShowFieldLine(Aradion, "Aradion the Farseer", "Aradion_0083", "Let's head to the next one. Be on your guard.")
		endif
		if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
			call ShowFieldLine(Valeria, "Valeria", "Valeria_0069", "Don't worry my love, we will be.")
		endif
	endif
endfunction

private function OnRiftsRitualExpire takes nothing returns nothing
	call FinishRiftsCurrentRitual()
endfunction

private function StartRiftsRuntimeTimers takes nothing returns nothing
	call StopRiftsRuntimeTimers()
	set RiftsCountdownRemaining = R2I(RIFTS_RITUAL_DURATION)
	set RiftsCloseTimer = CreateTimer()
	call TimerStart(RiftsCloseTimer, RIFTS_RITUAL_DURATION, false, function OnRiftsRitualExpire)
	set RiftsWaveTimer = CreateTimer()
	call TimerStart(RiftsWaveTimer, RIFTS_WAVE_PERIOD, true, function OnRiftsWaveTick)
	set RiftsCombatTimer = CreateTimer()
	call TimerStart(RiftsCombatTimer, RIFTS_COMBAT_PERIOD, true, function OnRiftsCombatTick)
	set RiftsCountdownTimer = CreateTimer()
	call TimerStart(RiftsCountdownTimer, RIFTS_COUNTDOWN_PERIOD, true, function OnRiftsCountdownTick)
endfunction

public function StartRiftsRuntimeTimersPublic takes nothing returns nothing
	call StartRiftsRuntimeTimers()
endfunction

private function OnRiftsFieldTick takes nothing returns nothing
	local integer i = 1
	local unit hero
	local unit riftUnit
	if not RiftsQuestActive then
		return
	endif
	if RiftsAwaitingReturnHome then
		set hero = ResolveDialogHero()
		if hero != null and RectContainsUnit(gg_rct_AradionPlace, hero) then
			call HandleRiftsReturnedHome()
		endif
		return
	endif
	if RiftsRitualActive then
		return
	endif
	loop
		exitwhen i > RIFTS_MAX
		set riftUnit = EnsureRiftUnit(i)
		if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) then
			set hero = GetAllowedRiftHeroInRange(riftUnit)
			if hero != null then
				call StartRiftsRitualInternal(riftUnit, i, hero)
				return
			endif
		endif
		set i = i + 1
	endloop
endfunction

private function StartRiftsFieldMonitor takes nothing returns nothing
	call StopRiftsFieldMonitor()
	set RiftsFieldTimer = CreateTimer()
	call TimerStart(RiftsFieldTimer, 0.50, true, function OnRiftsFieldTick)
endfunction

private function HandleRiftsFailure takes string reason returns nothing
	local QuestData q
	call SyncUnitReferences()
	if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) or QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	set RiftsQuestActive = false
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	set RiftsCorruptionCounter = 0
	set RiftsWaveIndex = 0
	set RiftsNextWaveN = 1
	set RiftsCountdownRemaining = 0
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = false
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DisableRiftsFailTriggers()
	call ReturnRiftsCompanionsHomeInternal()
	call RegisterRiftUnits()
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call ResetRiftsObjectivesForNewRun(q)
	endif
	call QuestGiver_FailQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, reason)
	call QuestGiver_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_AVAILABLE)
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
endfunction

private function OnRiftsValeriaDamaged takes nothing returns nothing
	if not RiftsQuestActive or Valeria == null then
		return
	endif
	if GetEventDamage() < GetWidgetLife(Valeria) - 0.41 then
		return
	endif
	call BlzSetEventDamage(GetWidgetLife(Valeria) - 1.00)
	call HandleRiftsFailure("Valeria fell during the ritual.")
endfunction

private function OnRiftsAradionDamaged takes nothing returns nothing
	if not RiftsQuestActive or Aradion == null then
		return
	endif
	if GetEventDamage() < GetWidgetLife(Aradion) - 0.41 then
		return
	endif
	call BlzSetEventDamage(GetWidgetLife(Aradion) - 1.00)
	call HandleRiftsFailure("Aradion fell during the ritual.")
endfunction

private function EnableRiftsFailTriggers takes nothing returns nothing
	call DisableRiftsFailTriggers()
	if Valeria != null then
		set RiftsValeriaFailTrigger = CreateTrigger()
		call TriggerRegisterUnitEvent(RiftsValeriaFailTrigger, Valeria, EVENT_UNIT_DAMAGED)
		call TriggerAddAction(RiftsValeriaFailTrigger, function OnRiftsValeriaDamaged)
	endif
	if Aradion != null then
		set RiftsAradionFailTrigger = CreateTrigger()
		call TriggerRegisterUnitEvent(RiftsAradionFailTrigger, Aradion, EVENT_UNIT_DAMAGED)
		call TriggerAddAction(RiftsAradionFailTrigger, function OnRiftsAradionDamaged)
	endif
endfunction

public function UpdateQuestRiftsCorruption takes nothing returns nothing
	call UpdateQuestRiftsCorruptionInternal()
endfunction

private function StartExitFadeOut takes nothing returns nothing
	call QuestGiver_StartDialogExitTransition(Aradion, SelectedHero, AradionDialogCooldown, DIALOG_COOLDOWN, true, 2.00, USE_DIALOG_CAMERA, true, CINEMATIC)
endfunction

private function BeginQuestDialogSequence takes nothing returns nothing
	call EnableUserControl(false)
	call QuestGiver_CloseActiveDialog()
	call ExecuteFunc("TasQuestBox_Hide")
	call ExecuteFunc("MasterUI_HideGameButton")
endfunction

private function SyncRangerMissingReadyTurnIn takes nothing returns nothing
	local real vx
	local real vy
	call SyncUnitReferences()
	if not RangerMissingEscortActive then
		return
	endif
	if QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) != QUEST_STATE_READY_TURNIN then
		return
	endif
	call StopRangerMissingEscortInternal()
	if Aradion != null and Valeria != null and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) then
		set vx = GetUnitX(Aradion) + 200.00 * Cos(GetUnitFacing(Aradion) * bj_DEGTORAD)
		set vy = GetUnitY(Aradion) + 200.00 * Sin(GetUnitFacing(Aradion) * bj_DEGTORAD)
		call IssuePointOrder(Valeria, "move", vx, vy)
	endif
endfunction

//===========================================================================
// Test quest handlers (simple accept/complete)
//===========================================================================
private function OnAcceptTestKill takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestKill takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestTalkTo takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestTalkTo takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestFindNPC takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestFindNPC takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestGoTo takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestGoTo takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestReputation takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestReputation takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestInvestigate takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestInvestigate takes nothing returns nothing
	call BeginQuestDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion)
	call StartExitFadeOut()
endfunction

//===========================================================================
// Button actions
//===========================================================================
private function OnBackstory takes nothing returns nothing
	call EnableUserControl(false)
	call PlayInfoSequence()
endfunction

private function OnAcceptQuest1End takes nothing returns nothing
	set AradionLastAcceptedQuest = ARADION_QID_RANGER
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	endif
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest1 takes nothing returns nothing
	local integer seq
	local unit hero
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
	
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)

	// Make Aradion and hero face each other
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "In the chaos, when the wraiths struck, my beloved Valeria was torn from my side.", "Aradion_0035", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I have searched, but the shadows grow thick. If she still lives and you find her, bring her to me, shaman… before they claim her as well.", "Aradion_0036", true)
	call AddHeroLine(seq, hero, "I'll see if I come across her.", "Nazgrek_0337")
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFailQuest1 takes nothing returns nothing
	call BeginQuestDialogSequence()
	call FailRangerMissingForRetry("Valeria was lost.")
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest1End takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	call RecreateValeriaAtHome()
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest1 takes nothing returns nothing
	local integer seq
	local unit hero
	local QuestData q
	local real vx
	local real vy
	
	// CRITICAL SAFETY CHECK: Verify Valeria exists before proceeding
	if Valeria == null or not UnitAlive(Valeria) then
		call BJDebugMsg("[qAradion] ERROR: Cannot complete quest - Valeria is null or dead!")
		call EnableUserControl(true)
		return
	endif
	
	call BeginQuestDialogSequence()
	
	// Mark requirement 2 as completed
	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirementCompleted(q.id, 2, true)
	endif

	call StopRangerMissingEscortInternal()
	call IssueImmediateOrder(Valeria, "stop")
	set vx = GetUnitX(Aradion) + 200.00 * Cos(GetUnitFacing(Aradion) * bj_DEGTORAD)
	set vy = GetUnitY(Aradion) + 200.00 * Sin(GetUnitFacing(Aradion) * bj_DEGTORAD)
	call IssuePointOrder(Valeria, "move", vx, vy)
	
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest1End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific completion dialog with inline facing/looking
	// NOTE: Valeria existence validated above - these calls are now safe
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, Aradion, 0.50, 0.0)
	call DialogSystem_AddLookAtUnit(seq, Aradion, Valeria, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Aradion… It is you! I thought I'd never see you again.", "Valeria_0023", true)
	call DialogSystem_AddLookAtUnit(seq, Aradion, Valeria, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria? By the stars… you yet live!", "Aradion_0031", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I feared that I had lost you… forgive me for losing hope.", "Aradion_0032", true)
	if hero == Nazgrek then
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "This orc… he spoke your name, my love. It is the only reason I followed him.", "Valeria_0024", true)
	else
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "This outsider… spoke your name, my love. It is the only reason I followed.", "", true)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Then I was right. You are no foe, but a seeker.", "Aradion_0033", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "You have given me back my heart, shaman. For this… I owe you more than I can say.", "Aradion_0034", true)
	if hero == Nazgrek then
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "…Do not think this earns my trust fully, orc. But… for Aradion's sake, I'm giving you a chance.", "Valeria_0025", true)
	else
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "…Do not think this earns my trust fully. But for Aradion's sake, I'm giving you a chance.", "", true)
	endif
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest2End takes nothing returns nothing
	set AradionLastAcceptedQuest = ARADION_QID_CRYSTALS
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest2 takes nothing returns nothing
	local integer seq
	local unit hero
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest2End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "In the ruins of Elarindor, there are crystals… pulsing, alive with energy.", "Aradion_0041", true)
	call AddHeroLookAtAradionLine(seq, hero, "I have walked near them. Their song is some what… twisted, yet beautiful.", "Nazgrek_0366")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I believe they are remnants of our ancient magical pools, fractured when our people consumed too much magical energies.", "Aradion_0042", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "If their power can be harnessed, perhaps… perhaps they may quiet the hunger, even if only for a time.", "Aradion_0043", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Bring me shards of these crystals, shaman. Let us not forsake even the faintest hope.", "Aradion_0044", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest2End takes nothing returns nothing
	local QuestData q
	if HeroItemCheckBothAndRemove(ITEM_MANA_CRYSTAL, 6) then
		set q = QuestGiver_GetByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
		if q != 0 then
			call QuestGiver_CompleteItemRequirements(q.id)
		endif
		call QuestGiver_CompleteQuestByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
	endif
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest2 takes nothing returns nothing
	local integer seq
	local unit hero
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest2End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes… these shards still resonate with power, I can feel it... It is almost... mesmerizing.", "Aradion_0047", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "If we can bend the crystals energy to our control, it might reverse the damage of the wretched elves decay… Or only soothe for a fleeting moment.…", "Aradion_0048", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yet the pulse of these crystals seems odd... As if the crystals themselves cry out in pain.", "Aradion_0049", true)
	call AddHeroLookAtAradionLine(seq, hero, "I can hear the spirits whisper caution. These crystals may feed hunger, not heal it.", "Nazgrek_0367")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I must study these shards you brought me… very carefully", "Aradion_0050", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest3End takes nothing returns nothing
	local unit hero
	set AradionLastAcceptedQuest = ARADION_QID_FADING
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
	set hero = ResolveDialogHero()
	if hero != null then
		call UnitAddItemByIdSwapped(ITEM_TELANOR_ROD, hero)
	endif
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest3 takes nothing returns nothing
	local integer seq
	local unit hero
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest3End)
	
	// Make Aradion and hero face each other
	set hero = ResolveDialogHero()
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The mana wraiths are what remain when the hunger wins.", "Aradion_0053", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yet even in their twisted forms, I sense a faint light — echoes of the elves they once were.", "Aradion_0054", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "If we can gather those sparks, perhaps they hold some secret… some key we have overlooked.", "Aradion_0055", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Bring me their essences, shaman. Let us see if even wraiths may whisper truth.", "Aradion_0056", true)
	call AddHeroLine(seq, hero, "I will do this Aradion, but I see little hope in the shadows.", "Nazgrek_0371")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I'll give you the rod of Tel'anor which can be used to safely extract the essence of mana wraith when it is weakened enough.", "Aradion_0063", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest3End takes nothing returns nothing
	local QuestData q
	if HeroItemCheckBothAndRemove(ITEM_WRAITH_ESSENCE, 10) then
		call HeroItemCheckBothAndRemove(ITEM_TELANOR_ROD, 1)
		set q = QuestGiver_GetByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
		if q != 0 then
			call QuestGiver_CompleteItemRequirements(q.id)
		endif
		call QuestGiver_CompleteQuestByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
	endif
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest3 takes nothing returns nothing
	local integer seq
	local unit hero
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest3End)
	
	// Make Aradion and hero face each other
	set hero = ResolveDialogHero()
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific completion dialog
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "So fragile… yet for a moment, I can feel all the memories.... everything they once were…", "Aradion_0060", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But it all slips away, fading faster than breath. They are too far gone.", "Aradion_0061", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "…If even wraiths leave behind only ashes of the soul, then perhaps our people's fate is truly sealed... ", "Aradion_0062", true)
	call AddHeroLine(seq, hero, "Do not surrender to despair, Aradion. There may yet be an answer to all of it.", "Nazgrek_0372")
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest4End takes nothing returns nothing
	local unit hero
	local QuestData q
	set AradionLastAcceptedQuest = ARADION_QID_RIFTS
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call ResetRiftsObjectivesForNewRun(q)
	endif
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	set hero = ResolveDialogHero()
	set RiftsQuestActive = true
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	set RiftsCorruptionCounter = 0
	set RiftsWaveIndex = 0
	set RiftsNextWaveN = 1
	set RiftsCountdownRemaining = 0
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = false
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call RegisterRiftUnits()
	if Aradion != null then
		call SetUnitInvulnerable(Aradion, false)
	endif
	if Valeria != null then
		call SetUnitInvulnerable(Valeria, false)
	endif
	call EnableRiftsFailTriggers()
	call StopValeriaPatrolInternal()
	call PlaceValeriaNearAradion(RIFTS_VALERIA_OFFSET)
	call StartFieldCompanions(hero)
	call StartRiftsFieldMonitor()
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest4 takes nothing returns nothing
	local integer seq
	local unit hero
	
	// SAFETY CHECK: Verify Valeria exists for this quest dialogue
	// DialogSystem will skip null unit actions, but log warning for debugging
	if Valeria == null or not UnitAlive(Valeria) then
		call BJDebugMsg("[qAradion] WARNING: Valeria is null/dead in OnAcceptQuest4 - some dialogue actions will be skipped")
	endif
	
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest4End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	call PlaceValeriaNearAradion(RIFTS_VALERIA_OFFSET)
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The ancient pools of magic around the Vanguard Vale and Elarindor once flowed pure, binding our people to life and light.", "Aradion_0065", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now they are transformed.... distorted by implosion of the mana hunger.... And in those rift-like pools, the wraiths are born anew.", "Aradion_0066", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria and I will attempt to seal these rifts. It is perilous work, and we don't truly know what we are dealing with. I've begin to think that I should do this alone…", "Aradion_0067", true)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddLookAtUnit(seq, Valeria, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "We have planned this forever… I can handle it, my love. ", "Valeria_0060", true)
	call AddHeroLine(seq, hero, "The spirits whisper of broken currents here. I will see Valeria through this.", "Nazgrek_0377")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Stand with us, shaman. Guard me while I close the rifts — and strike down whatever nightmares the rifts unleash.", "Aradion_0068", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest4End takes nothing returns nothing
	set RiftsQuestActive = false
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	set RiftsWaveIndex = 0
	set RiftsNextWaveN = 1
	set RiftsCountdownRemaining = 0
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = false
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DisableRiftsFailTriggers()
	call ReturnRiftsCompanionsHomeInternal()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest4 takes nothing returns nothing
	local integer seq
	local unit hero
	
	// SAFETY CHECK: Verify Valeria exists for this quest dialogue
	// DialogSystem will skip null unit actions, but log warning for debugging
	if Valeria == null or not UnitAlive(Valeria) then
		call BJDebugMsg("[qAradion] WARNING: Valeria is null/dead in OnCompleteQuest4 - some dialogue actions will be skipped")
	endif
	
	call BeginQuestDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest4End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, Aradion, 0.50, 0.0)
	call AddHeroLine(seq, hero, "The wound in the land is remedied… for now.", "Nazgrek_0378")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The rifts… are sealed. For the first time in years, the air feels lighter in the Vale.", "Aradion_0071", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "You stood unbroken, my dear friend. Hope stirs again — faint, but alive.", "Aradion_0072", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Thank you, shaman. You have given us more than victory — you have given us belief.", "Aradion_0073", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFarewellEnd takes nothing returns nothing
	call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
	local integer seq
	call BeginQuestDialogSequence()
	
	// Use QuestGiver helper to build farewell sequence
	set seq = QuestGiver_CreateFarewellSequence(Aradion, "Aradion the Farseer", null, "", DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

//===========================================================================
// Line registration
//===========================================================================
private function RegisterLines takes nothing returns nothing
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, "Go then, shaman. May the spirits shield you.", "Aradion_0017", true)
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, "May your path carry more hope than mine.", "Aradion_0018", true)
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, "I hope our paths cross again.", "Aradion_0019", true)
endfunction

//===========================================================================
// Dialog building
//===========================================================================
private function BuildDialog takes nothing returns nothing
	local button b
	call SyncUnitReferences()
	call SyncRangerMissingReadyTurnIn()

	if AradionDialog == null then
		set AradionDialog = DialogSystem_CreateDialog("Aradion the Farseer")
	endif

	call DialogSystem_ClearDialog(AradionDialog)
	call DialogSystem_SetTitle(AradionDialog, "Aradion the Farseer")

	set b = DialogSystem_AddButtonInfo(AradionDialog, 1)
	call DialogSystem_BindButtonCode(b, function OnBackstory)

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		if CanOfferRangerMissing() and QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_AVAILABLE and ((not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion)) or QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion)) then
			set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_RANGER_MISSING, 2)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest1)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
			if QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_READY_TURNIN and QuestGiver_IsUnitAlive(Valeria) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_RANGER_MISSING, 4)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest1)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) == QUEST_STATE_AVAILABLE then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_CRYSTALS_HOPE, 5)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest2)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) then
			// QuestGiver/QuestMaster handles item tracking automatically
			// Verify items are still in inventory before showing completion button
			if QuestGiver_GetStateByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) == QUEST_STATE_READY_TURNIN and QuestGiver_ValidateItemRequirements(QuestGiver_GetByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion).id) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_CRYSTALS_HOPE, 6)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest2)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_FADING_SPARKS, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_FADING_SPARKS, Aradion) == QUEST_STATE_AVAILABLE then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_FADING_SPARKS, 7)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest3)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FADING_SPARKS, Aradion) then
			// QuestGiver/QuestMaster handles item tracking automatically
			// Verify items are still in inventory before showing completion button
			if QuestGiver_GetStateByNameAndGiver(QUEST_FADING_SPARKS, Aradion) == QUEST_STATE_READY_TURNIN and QuestGiver_ValidateItemRequirements(QuestGiver_GetByNameAndGiver(QUEST_FADING_SPARKS, Aradion).id) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_FADING_SPARKS, 8)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest3)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
			if ((not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)) or QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)) and QuestGiver_GetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_RIFTS_CORRUPTION, 9)
				call DialogSystem_BindButtonCode(b, function OnAcceptQuest4)
			elseif not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) == QUEST_STATE_READY_TURNIN and RiftsReturnedHome and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_RIFTS_CORRUPTION, 10)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest4)
			endif
	endif

	// Test quests (simple accept/complete with auto-discovery)
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_KILL, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_KILL, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_KILL, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_KILL, 11)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestKill)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_KILL, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_KILL, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_KILL, 12)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestKill)
		endif
	endif
	
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_TALKTO, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_TALKTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_TALKTO, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_TALKTO, 13)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestTalkTo)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_TALKTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_TALKTO, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_TALKTO, 14)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestTalkTo)
		endif
	endif
	
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_FINDNPC, 15)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestFindNPC)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_FINDNPC, 16)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestFindNPC)
		endif
	endif
	
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_GOTO, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_GOTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_GOTO, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_GOTO, 17)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestGoTo)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_GOTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_GOTO, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_GOTO, 18)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestGoTo)
		endif
	endif
	
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_REPUTATION, 19)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestReputation)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_REPUTATION, 20)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestReputation)
		endif
	endif
	
	if ENABLE_TEST_QUESTS and QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_INVESTIGATE, 21)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestInvestigate)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_INVESTIGATE, 22)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestInvestigate)
		endif
	endif

	set b = DialogSystem_AddFarewellButton(AradionDialog)
	call DialogSystem_BindButtonCode(b, function OnFarewell)
endfunction

// Public wrapper for dialog rebuild (used by ExecuteFunc)
public function RebuildAndShowDialog takes nothing returns nothing
	call EnableUserControl(true)
	call BuildDialog()
	call DebugMsg("Rebuilding and showing dialog")
	call DialogSystem_ShowDialog(AradionDialog, Player(0))
endfunction
//===========================================================================
// Selection entry - Fade sequence callbacks
//===========================================================================
private function ContinueToDialogInternal takes nothing returns nothing
	local unit hero = SelectedHero
	call SyncUnitReferences()
	
	// Continue with dialog logic
	if not QuestGiver_IsFirstGreetDone(Aradion) then
		if AradionDialog == null then
			call DebugMsg("Creating Aradion dialog")
			set AradionDialog = DialogSystem_CreateDialog("Aradion the Farseer")
			call BuildDialog()
		endif
		call DebugMsg("Playing first greet sequence")
		call PlayGreetFirstSequence(hero)
	else
		call DebugMsg("First greet done, proceeding with normal dialog")
		call BuildDialog()
		call DebugMsg("Calling ShowDialog")
		call ShowDialog(Player(0), hero)
	endif
endfunction

public function ContinueToDialogAfterSelection takes nothing returns nothing
	call ContinueToDialogInternal()
endfunction

private function OnSelected takes nothing returns nothing
	local unit hero
	local boolean gateOk
	local boolean selectedOk
	local boolean heroOk
	local boolean rangeOk
	local real remaining
	local integer customValue
	call SyncUnitReferences()

	if DialogSystem_IsSequenceActive() then
		call DebugMsg("Select gate blocked: dialog sequence active")
		return
	endif
	
	// Check if unit is casting or in combat
	set customValue = GetUnitUserData(Aradion)
	if udg_UnitIsCasting[customValue] or udg_GCSM_UnitInCombat[customValue] then
		call DebugMsg("Select gate blocked: unit is casting or in combat")
		return
	endif
	
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	if REQUIRE_DIALOG_HERO and hero == null then
		call DebugMsg("Select gate blocked: missing allowed hero in range")
		return
	endif
	set gateOk = QuestGiver_PassSelectionGate(Aradion, hero, DIALOG_RANGE, AradionDialogCooldown)
	call DebugMsg("OnSelected: gateOk=" + I2S(B2I(gateOk)))
	if not gateOk then
		set selectedOk = QuestGiver_GetSelectedUnit() == Aradion
		set heroOk = hero != null
		set rangeOk = heroOk
		set remaining = QuestGiver_GetCooldownRemaining(AradionDialogCooldown)
		call DebugMsg("Select gate blocked: selectedOk=" + I2S(B2I(selectedOk)) + ", heroOk=" + I2S(B2I(heroOk)) + ", rangeOk=" + I2S(B2I(rangeOk)) + ", cooldown=" + R2S(remaining))
		return
	endif
	call DebugMsg("OnSelected: Passed gate check")
	
	// Store hero for fade sequence
	set SelectedHero = hero
	call SyncRangerMissingReadyTurnIn()
	call QuestGiver_StartDialogEntryTransition(Aradion, hero, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, true, USE_DIALOG_CAMERA, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK, CINEMATIC, "qAradion_ContinueToDialogAfterSelection")
endfunction

//===========================================================================
// Quest creation
//===========================================================================
private function CreateQuests takes nothing returns nothing
	local QuestData q
	local string giverName
	local string infoText
	local string info2Text
	local trigger availabilityCondition

	call DebugMsg("Create quests")

	set giverName = QuestGiver_GetUnitDisplayName(Aradion)
	set infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
	set info2Text = "|cffffcc00Recommended level:|r 18\n\n"

	set q = QuestGiver_CreateQuest(QUEST_RANGER_MISSING, Aradion, "normal", 18, null)
	set q.title = "Ranger Missing"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp"
	set q.description = "Find Valeria somewhere in Vanguard Vale or Verdant Plains.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setAllowedHeroesForLevelCheck(ALLOW_NAZGREK, ALLOW_ZULKIS)
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	set availabilityCondition = CreateTrigger()
	call TriggerAddCondition(availabilityCondition, Condition(function CanOfferRangerMissing))
	call q.setCustomCondition(availabilityCondition)
	call QuestGiver_SetRequirements(q.id, "", "Find Valeria", "", "", "", "", "", "", "")

	set q = QuestGiver_CreateQuest(QUEST_CRYSTALS_HOPE, Aradion, "normal", 18, null)
	set q.title = "Crystals of Hope"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp"
	set q.description = "Aradion wants to study the mana crystals that can be found anywhere in Vanguard Vale.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setAllowedHeroesForLevelCheck(ALLOW_NAZGREK, ALLOW_ZULKIS)
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Mana Crystals
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_MANA_CRYSTAL, 6)

	set q = QuestGiver_CreateQuest(QUEST_FADING_SPARKS, Aradion, "normal", 18, null)
	set q.title = "Fading Sparks"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHeartOfAszune.blp"
	set q.description = "Aradion wants you to gather essences from the wraiths wandering around the Vanguard Vale. Use provided |cffffff00Tel'anor Rod|r when the wraith is at half health.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setAllowedHeroesForLevelCheck(ALLOW_NAZGREK, ALLOW_ZULKIS)
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Wraith Essences
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_WRAITH_ESSENCE, 10)

	set q = QuestGiver_CreateQuest(QUEST_RIFTS_CORRUPTION, Aradion, "normal", 18, null)
	set q.title = "Rifts of Corruption"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNDizzy.blp"
	set q.description = "Find all rifts scattered around the Vanguard Vale and escort Valeria and Aradion to them. Guard Aradion while he will close the rifts. Both Aradion and Valeria must stay alive.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setAllowedHeroesForLevelCheck(ALLOW_NAZGREK, ALLOW_ZULKIS)
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	call q.addRequiredCompletedQuest(QUEST_CRYSTALS_HOPE, Aradion)
	call q.addRequiredCompletedQuest(QUEST_FADING_SPARKS, Aradion)
	call QuestGiver_SetRequirements(q.id, "", "Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed 0 / 3)", "Guard Aradion while he closes the rifts", "Both Aradion and Valeria must stay alive", "", "", "", "", "")

	if ENABLE_TEST_QUESTS then
		// Test Quest 1: Kill
		set q = QuestMaster_TemplateKill(QUEST_TEST_KILL, Aradion, "normal", 1, 'ngno', 3)
		call QuestGiver_RegisterUnitKillRequirement(q.id, Aradion, 1, 'ngno', 3)
		set q.title = "Test: Kill Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNFootman.blp"
		set q.description = "Test quest for killing units.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		call q.setReceiverDisplayName(giverName)
		
		// Test Quest 2: Talk To
		set q = QuestMaster_TemplateTalkTo(QUEST_TEST_TALKTO, Aradion, "normal", 1, "Valeria")
		set q.title = "Test: Talk To Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp"
		set q.description = "Test quest for talking to NPC.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		call q.setReceiverDisplayName(giverName)
		
		// Test Quest 3: Find NPC
		set q = QuestMaster_TemplateFindNPC(QUEST_TEST_FINDNPC, Aradion, "normal", 1, "Valeria")
		set q.title = "Test: Find NPC Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.blp"
		set q.description = "Test quest for finding an NPC.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		call q.setReceiverDisplayName(giverName)
		
		// Test Quest 4: Go To Place
		set q = QuestMaster_TemplateGoToPlace(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains")
		set q.title = "Test: Go To Place Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp"
		set q.description = "Test quest for going to a location.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		call q.setReceiverDisplayName(giverName)
		
		// Test Quest 5: Reputation
		set q = QuestMaster_TemplateReputation(QUEST_TEST_REPUTATION, Aradion, "normal", 1, "Elarindor", "Friendly")
		set q.title = "Test: Reputation Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNTome.blp"
		set q.description = "Test quest for reputation gain.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 500, false)
		call q.setReceiverDisplayName(giverName)
		
		// Test Quest 6: Investigate
		set q = QuestMaster_TemplateInvestigate(QUEST_TEST_INVESTIGATE, Aradion, "normal", 1, "the strange ruins near the Vale")
		set q.title = "Test: Investigate Quest"
		set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNAncientRelic.blp"
		set q.description = "Test quest for investigating.\n\n"
		set q.infoText = infoText
		set q.info2Text = "|cffffcc00Recommended level:|r 1\n\n"
		set q.requiredLevel = 1
		call q.setFaction("Elarindor")
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		call q.setReceiverDisplayName(giverName)
	endif

endfunction

//===========================================================================
// Init
//===========================================================================
private function InitDelayed takes nothing returns nothing
	if udg_Aradion == null then
		if not AradionInitWaitingLogged then
			call DebugMsg("Waiting for udg_Aradion")
			set AradionInitWaitingLogged = true
		endif
		call TimerStart(AradionDialogCooldown, 0.50, false, function InitDelayed)
		return
	endif
	set Aradion = udg_Aradion
	set Nazgrek = udg_Nazgrek
	set Valeria = udg_Valeria
	call DebugMsg("Init Aradion giver id=" + I2S(GetHandleId(Aradion)))
	call QuestGiver_Register(Aradion)
	call QuestGiver_SetGreetOrder(Aradion, QUESTGIVER_GREET_NAZGREK_THEN_NPC)
	call RegisterLines()
	call RegisterValeriaEncounterProximityTrigger()
	call RegisterRiftUnits()
	call CreateQuests()
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	call QuestGiver_RegisterSelectionHandler(Aradion, function OnSelected)
endfunction

private function Init takes nothing returns nothing
	set AradionDialogCooldown = CreateTimer()
	call TimerStart(AradionDialogCooldown, 0.00, false, function InitDelayed)
endfunction

//===========================================================================
// Public API for quest status updates and getters
//===========================================================================
public function StartValeriaEncounter takes unit hero returns nothing
	call StartValeriaEncounterInternal(hero)
endfunction

public function StartValeriaEncounterFromPendingHero takes nothing returns nothing
	call StartValeriaEncounterInternal(ValeriaEncounterHero)
endfunction

public function RegisterValeriaEncounterProximity takes nothing returns nothing
	call RegisterValeriaEncounterProximityTrigger()
endfunction

public function RegisterRiftsProximity takes nothing returns nothing
	call RegisterRiftsProximityTrigger()
endfunction

public function TryOpenValeriaNegotiation takes nothing returns nothing
	call TryOpenValeriaNegotiationInternal()
endfunction

public function ResetValeriaEncounter takes nothing returns nothing
	call ResetValeriaEncounterToAmbush()
endfunction

public function PauseValeriaPatrol takes nothing returns nothing
	call PauseValeriaPatrolInternal()
endfunction

public function ContinueValeriaPatrol takes nothing returns nothing
	call ContinueValeriaPatrolInternal()
endfunction

public function StopValeriaPatrol takes nothing returns nothing
	call StopValeriaPatrolInternal()
endfunction

public function WalkValeriaHome takes nothing returns nothing
	call MoveValeriaHomeInternal()
endfunction

public function TriggerRangerMissingUpdate takes nothing returns nothing
	call UpdateQuestRangerMissing()
endfunction

public function StartRangerMissingEscort takes nothing returns nothing
	call StartRangerMissingEscortInternal()
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

public function FailRangerMissingEscort takes nothing returns nothing
	call FailRangerMissingForRetry("Valeria was lost.")
endfunction

public function BeginRiftsRitual takes unit riftUnit returns nothing
	local integer i = 1
	local unit hero
	call SyncUnitReferences()
	if not RiftsQuestActive then
		return
	endif
	set hero = GetAllowedRiftHeroInRange(riftUnit)
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	loop
		exitwhen i > RIFTS_MAX
		if RiftsUnits[i] == riftUnit then
			call StartRiftsRitualInternal(riftUnit, i, hero)
			return
		endif
		set i = i + 1
	endloop
	call StartRiftsRitualInternal(riftUnit, 0, hero)
endfunction

public function CompleteRiftsCurrentRitual takes nothing returns nothing
	call SyncUnitReferences()
	if not RiftsQuestActive then
		return
	endif
	call FinishRiftsCurrentRitual()
endfunction

public function FailRifts takes string reason returns nothing
	call HandleRiftsFailure(reason)
endfunction

public function ReturnRiftsCompanionsHome takes nothing returns nothing
	set RiftsQuestActive = false
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	set RiftsWaveIndex = 0
	set RiftsNextWaveN = 1
	set RiftsCountdownRemaining = 0
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = false
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call ReturnRiftsCompanionsHomeInternal()
endfunction

public function GetRiftsCorruptionCounter takes nothing returns integer
	return RiftsCorruptionCounter
endfunction

public function ResetRiftsCorruptionCounter takes nothing returns nothing
	set RiftsCorruptionCounter = 0
endfunction

endlibrary
