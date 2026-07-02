library qAradion initializer Init requires QuestGiver, QuestMaster, DialogSystem, ExSound, FollowSystem, PatrolSystem, UnitSpawn, Companions, ItemLootSystem, ZonesCore
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
	private constant integer ABIL_TELANOR_ROD = 'A04W'
	private constant integer ABIL_RIFT_CLOSE = 'A04Z'
	private constant integer UNIT_VALERIA = 'n01W'
	private constant integer UNIT_MANA_WRAITH = 'n002'
	private constant integer UNIT_MANA_RIFT = 'n023'
	private constant integer UNIT_FADING_SPARKS_WRAITH_2 = 0
	private constant integer UNIT_FADING_SPARKS_WRAITH_3 = 0
	private constant integer UNIT_FADING_SPARKS_WRAITH_4 = 0

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
	private constant real VALERIA_ENCOUNTER_RANGE_CHECK_PERIOD = 0.25
	private constant real VALERIA_ENCOUNTER_SPEED_RESET_DELAY = 3.00
	private constant real DIALOG_COOLDOWN = 6.00
	private constant real FOLLOW_MAX_DISTANCE = 2000.00
	private constant real RANGER_ESCORT_DEST_RADIUS = 500.00
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
	private constant integer VANGUARD_VALE_ZONE_ID = 9
	private constant integer VERDANT_PLAINS_ZONE_ID = 17
	private constant string RIFTS_WAVE_PRE_SPAWN_EFFECT = "vortex1.mdx"
	private constant string RIFTS_WAVE_PRE_SPAWN_CREATE_SOUND = "Sound/Ambient/DoodadEffects/ShimmeringPortalBirth"
	private constant string RIFTS_WAVE_PRE_SPAWN_DESTROY_SOUND = "Sound/Ambient/DoodadEffects/ShimmeringPortalDeath"
	private constant string RIFTS_WAVE_SPAWN_EFFECT = ""
	private constant real RIFTS_WAVE_PRE_SPAWN_DELAY = 2.00
	private constant real RIFTS_WAVE_PRE_SPAWN_EFFECT_DURATION = 4.00
	private constant real RIFTS_WAVE_SPAWN_EFFECT_DURATION = 0.00
	private constant real RIFTS_TRIGGER_RANGE = 1200.00
	private constant real RIFTS_RITUAL_DURATION = 120.00
	private constant real RIFTS_WAVE_PERIOD = 20.00
	private constant real RIFTS_COMBAT_PERIOD = 20.00
	private constant real RIFTS_COUNTDOWN_PERIOD = 1.00
	private constant real RIFTS_WAVE_END_BUFFER = 10.00
	private constant real RIFTS_OVERWHELMED_WAVE_AGE = 25.00
	private constant real RIFTS_FAIL_RESET_DELAY = 30.00
	private constant real RIFTS_ARADION_OFFSET = 500.00
	private constant real RIFTS_VALERIA_OFFSET = 200.00
	private constant real RIFTS_INTRO_VALERIA_OFFSET = 2200.00
	private constant real FADING_SPARKS_CHANNEL_TIME = 2.00
	private constant real FADING_SPARKS_HEALTH_THRESHOLD = 50.00
	private constant real FADING_SPARKS_DAMAGE = 6000.00

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
	private player AradionHomeOwner = null
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
	private timer ValeriaNegotiationPromptTimer = null
	private timer RangerMissingZoneTimer = null
	private timer RiftsFieldTimer = null
	private timer RiftsCloseTimer = null
	private timer RiftsWaveTimer = null
	private timer RiftsCombatTimer = null
	private timer RiftsCountdownTimer = null
	private timer RiftsFailResetTimer = null
	private timer FadingSparksTimer = null
	private dialog ValeriaNegotiationDialog = null
	private button array ValeriaNegotiationButtons
	private integer array ValeriaNegotiationLineIds
	private integer ValeriaNegotiationButtonCount = 0
	private unit ValeriaEncounterHero = null
	private boolean ValeriaNegotiationPromptPending = false
	private boolean ValeriaNegotiationSequenceBusy = false
	private boolean ValeriaSuccessTransitionApplied = false
	private boolean RiftsQuestActive = false
	private boolean RiftsRitualActive = false
	private trigger RiftsProximityTrigger = null
	private trigger FadingSparksSpellEffectTrigger = null
	private trigger FadingSparksSpellFinishTrigger = null
	private trigger FadingSparksSpellEndCastTrigger = null
	private unit RiftsCurrentRift = null
	private unit FadingSparksCaster = null
	private unit FadingSparksTarget = null
	private unit array PlacedManaRifts
	private unit array RiftsUnits
	private integer array RiftsUnitTypeIds
	private Wave array RiftsWaveHandles
	private integer array RiftsWaveSpawnCountdown
	private integer RiftsWaveIndex = 0
	private integer RiftsNextWaveN = 1
	private integer RiftsCurrentIndex = 0
	private integer RiftsCountdownRemaining = 0
	private boolean RiftsAwaitingReturnHome = false
	private boolean RiftsReturnedHome = false
	private boolean FadingSparksFinished = false
	private boolean RiftsFailureInProgress = false
	private boolean array RiftsClosed
	private string RiftsPendingFailReason = ""
	private unit RiftsFailedUnit = null
	private unit RiftsFailureSurvivor = null

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
public function SetBackstorySeen takes boolean flag returns nothing
	set AradionBackstorySeen = flag
	if Aradion != null and QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif
endfunction

public function SetRangerMissingReq1Complete takes boolean flag returns nothing
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
	return QuestGiver_ResolveDialogHero(SelectedHero, Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
endfunction

private function IsAradionFieldZoneActive takes nothing returns boolean
	local integer zoneId = ZonesCore_GetCurrentZone()
	if zoneId == VANGUARD_VALE_ZONE_ID then
		return true
	endif
	if ZonesCore_IsChildZoneOf(zoneId, VANGUARD_VALE_ZONE_ID) then
		return true
	endif
	if zoneId == VERDANT_PLAINS_ZONE_ID then
		return true
	endif
	return ZonesCore_IsChildZoneOf(zoneId, VERDANT_PLAINS_ZONE_ID)
endfunction

private function CanOfferRangerMissing takes nothing returns boolean
	return AradionBackstorySeen
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

private function StartValeriaHeroDialogCamera takes nothing returns nothing
	local unit hero = ValeriaEncounterHero
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = ResolveDialogHero()
	endif
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		call DialogSystem_StartDialogCamera(Player(0), hero, 750.00, 50.00, 355.00, 45.00, CAMERA_CLOSE_FAR_Z, 60.00, 0.00, true, USE_DIALOG_CAMERA)
	endif
endfunction

private function MoveValeriaBehindHeroForStandoff takes nothing returns nothing
	local unit hero = ValeriaEncounterHero
	local real facing
	local real x
	local real y
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = ResolveDialogHero()
	endif
	if hero == null or Valeria == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(hero) or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set facing = GetUnitFacing(hero) * bj_DEGTORAD
	set x = GetUnitX(hero) - 400.00 * Cos(facing)
	set y = GetUnitY(hero) - 400.00 * Sin(facing)
	call IssuePointOrder(Valeria, "move", x, y)
endfunction

private function StopValeriaAtStandoff takes nothing returns nothing
	local unit hero = ValeriaEncounterHero
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = ResolveDialogHero()
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call IssueImmediateOrder(Valeria, "stop")
		call SetUnitAnimation(Valeria, "stand ready")
		if hero != null and QuestGiver_IsUnitAlive(hero) then
			call DialogSystem_MakeFaceEachOther(Valeria, hero, 0.75)
		endif
	endif
endfunction

private function StopFollow takes unit follower returns nothing
	if follower != null then
		call FollowSystem_RemoveUnit(follower)
	endif
endfunction

private function AddValeriaCompanion takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) and not ValeriaCompanionActive then
		call Companions_Add(Valeria, VALERIA_COMPANION_ICON, null, COMPANION_MODE_DEFEND)
		set ValeriaCompanionActive = true
	endif
endfunction

private function RemoveValeriaCompanion takes nothing returns nothing
	call StopFollow(Valeria)
	if Valeria != null then
		call Companions_Remove(Valeria)
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

private function PlaceValeriaNearHeroFront takes unit hero, real offset returns nothing
	local real facing
	local real x
	local real y
	if hero == null or Valeria == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(hero) or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set facing = GetUnitFacing(hero) * bj_DEGTORAD
	set x = GetUnitX(hero) + offset * Cos(facing)
	set y = GetUnitY(hero) + offset * Sin(facing)
	call SetUnitPosition(Valeria, x, y)
	call DialogSystem_MakeUnitFaceUnit(Valeria, hero, 0.75)
	call DialogSystem_MakeUnitFaceUnit(hero, Valeria, 0.75)
	call IssueImmediateOrder(Valeria, "stop")
endfunction

private function ForceUnitsFaceEachOther takes unit leftUnit, unit rightUnit returns nothing
	local real leftFacing
	local real rightFacing
	if leftUnit == null or rightUnit == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(leftUnit) or not QuestGiver_IsUnitAlive(rightUnit) then
		return
	endif
	set leftFacing = bj_RADTODEG * Atan2(GetUnitY(rightUnit) - GetUnitY(leftUnit), GetUnitX(rightUnit) - GetUnitX(leftUnit))
	set rightFacing = bj_RADTODEG * Atan2(GetUnitY(leftUnit) - GetUnitY(rightUnit), GetUnitX(leftUnit) - GetUnitX(rightUnit))
	call SetUnitFacing(leftUnit, leftFacing)
	call SetUnitFacing(rightUnit, rightFacing)
endfunction

private function ForceValeriaNegotiationFacing takes nothing returns nothing
	local unit hero = ValeriaEncounterHero
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = ResolveDialogHero()
	endif
	if hero != null and Valeria != null then
		call ForceUnitsFaceEachOther(hero, Valeria)
	endif
	set hero = null
endfunction

private function IssueValeriaSuccessApproach takes nothing returns nothing
	local unit hero = ValeriaEncounterHero
	local real facing
	local real x
	local real y
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = ResolveDialogHero()
	endif
	if hero == null or Valeria == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(hero) or not QuestGiver_IsUnitAlive(Valeria) then
		set hero = null
		return
	endif
	set facing = GetUnitFacing(hero) * bj_DEGTORAD
	set x = GetUnitX(hero) + 400.00 * Cos(facing)
	set y = GetUnitY(hero) + 400.00 * Sin(facing)
	call IssuePointOrder(Valeria, "move", x, y)
	set hero = null
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
		call Companions_Add(Aradion, ARADION_COMPANION_ICON, null, COMPANION_MODE_DEFEND)
		set AradionCompanionActive = true
	endif
endfunction

private function RemoveAradionCompanion takes nothing returns nothing
	call StopFollow(Aradion)
	if Aradion != null then
		call Companions_Remove(Aradion)
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
	if not IsAradionFieldZoneActive() then
		return
	endif
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	call AddValeriaCompanion()
	call AddAradionCompanion()
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call Companions_SetMode(Valeria, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Valeria, hero)
		call Companions_Resume(Valeria)
	endif
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call Companions_SetMode(Aradion, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Aradion, hero)
		call Companions_Resume(Aradion)
	endif
endfunction

private function StopFieldCompanions takes nothing returns nothing
	call StopFollow(Valeria)
	call StopFollow(Aradion)
	call RemoveValeriaCompanion()
	call RemoveAradionCompanion()
endfunction

private function StopRangerMissingZoneMonitor takes nothing returns nothing
	if RangerMissingZoneTimer != null then
		call DestroyTimer(RangerMissingZoneTimer)
		set RangerMissingZoneTimer = null
	endif
endfunction

private function StopRangerMissingEscortInternal takes nothing returns nothing
	local QuestData q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	call StopRangerMissingZoneMonitor()
	if q != 0 then
		call QuestGiver_UnregisterEscortRequirement(q.id, 2)
	endif
	call StopFollow(Valeria)
	call RemoveValeriaCompanion()
	call DisableRangerMissingDeathTrigger()
	call RemoveRangerMissingEscortDestination()
	set RangerMissingEscortActive = false
endfunction

private function OnRangerMissingZoneTick takes nothing returns nothing
	local QuestData q
	if not RangerMissingEscortActive then
		call StopRangerMissingZoneMonitor()
		return
	endif
	if not IsAradionFieldZoneActive() then
		set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
		call StopRangerMissingEscortInternal()
		if q != 0 then
			call q.setRequirement(2, "Find Valeria in Vanguard Vale or Verdant Plains")
			call q.updateRequirementText(2, "Find Valeria in Vanguard Vale or Verdant Plains")
			call q.refreshQuestLog()
		endif
		if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
			call IssueImmediateOrder(Valeria, "stop")
		endif
	endif
endfunction

private function StartRangerMissingZoneMonitor takes nothing returns nothing
	call StopRangerMissingZoneMonitor()
	set RangerMissingZoneTimer = CreateTimer()
	call TimerStart(RangerMissingZoneTimer, 1.00, true, function OnRangerMissingZoneTick)
endfunction

private function RecreateValeriaAtHome takes nothing returns nothing
	local player ownerP
	local real x
	local real y
	local real facing = 252.00
	local unit oldValeria

	set oldValeria = Valeria
	set ownerP = Player(VALERIA_HOME_OWNER)
	set x = GetRectCenterX(gg_rct_ValeriaNewPos)
	set y = GetRectCenterY(gg_rct_ValeriaNewPos)

	if oldValeria != null and QuestGiver_IsUnitAlive(oldValeria) then
		call StopFollow(oldValeria)
		call Companions_Remove(oldValeria)
		set ValeriaCompanionActive = false
	endif
	set Valeria = QuestGiver_ReuseOrCreateUnitAtPoint(oldValeria, ownerP, UNIT_VALERIA, x, y, facing, true)
	if Valeria == null then
		set oldValeria = null
		set ownerP = null
		return
	endif
	set udg_Valeria = Valeria
	call QuestGiver_ResetFieldUnitAtPoint(Valeria, ownerP, x, y, facing, true)
	call ExecuteFunc("qAradion_RegisterValeriaEncounterProximity")
	call UnitAddAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	call IssueImmediateOrder(Valeria, "coldarrows")
	// TODO: add Valeria's post-reunion Dash ability here once its custom rawcode is identified in the JASS/object data pipeline.
	set oldValeria = null
	set ownerP = null
endfunction

private function RecreateValeriaAtAmbush takes nothing returns nothing
	local player ownerP
	local real x
	local real y
	local real facing = 257.00
	local unit oldValeria

	set oldValeria = Valeria
	set ownerP = Player(PLAYER_NEUTRAL_PASSIVE)
	set x = GetRectCenterX(gg_rct_ValeriaAmbushPos)
	set y = GetRectCenterY(gg_rct_ValeriaAmbushPos)

	if oldValeria != null and QuestGiver_IsUnitAlive(oldValeria) then
		call StopFollow(oldValeria)
		call Companions_Remove(oldValeria)
		set ValeriaCompanionActive = false
	endif
	set Valeria = QuestGiver_ReuseOrCreateUnitAtPoint(oldValeria, ownerP, UNIT_VALERIA, x, y, facing, true)
	if Valeria == null then
		set oldValeria = null
		set ownerP = null
		return
	endif
	set udg_Valeria = Valeria
	call ExecuteFunc("qAradion_RegisterValeriaEncounterProximity")
	set oldValeria = null
	set ownerP = null
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

private function StopValeriaNegotiationPromptTimer takes nothing returns nothing
	if ValeriaNegotiationPromptTimer != null then
		call DestroyTimer(ValeriaNegotiationPromptTimer)
		set ValeriaNegotiationPromptTimer = null
	endif
endfunction

private function ClearValeriaEncounterState takes nothing returns nothing
	call StopValeriaEncounterTimers()
	call DisableValeriaEncounterDeathTrigger()
	call StopValeriaNegotiationPromptTimer()
	call DialogSystem_ClearEscapeAction()
	if ValeriaNegotiationDialog != null then
		call DialogSystem_ClearDialog(ValeriaNegotiationDialog)
	endif
	set ValeriaNegotiationButtonCount = 0
	set ValeriaNegotiationPromptPending = false
	set ValeriaNegotiationSequenceBusy = false
	set ValeriaSuccessTransitionApplied = false
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
	call ResetRangerMissingQuestProgress()
	call QuestGiver_SetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion, QUEST_STATE_AVAILABLE)
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
	if not IsAradionFieldZoneActive() then
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
	call SetUnitCreepGuard(Valeria, false)
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
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call Companions_SetMode(Valeria, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Valeria, hero)
		call Companions_Resume(Valeria)
	endif
	call EnableRangerMissingDeathTrigger()
	set RangerMissingEscortActive = true
	call StartRangerMissingZoneMonitor()
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
		call UnitRemoveAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
		call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
		call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 2.00)
		call SetWidgetLife(Valeria, BlzGetUnitMaxHP(Valeria))
		call SetUnitOwner(Valeria, Player(PLAYER_NEUTRAL_PASSIVE), true)
		call SetUnitCreepGuard(Valeria, false)
		call PlaceValeriaAtAmbushInternal()
		set udg_Valeria = Valeria
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
	set t = null
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
	set t = null
endfunction

private function OnValeriaEncounterRangeTick takes nothing returns nothing
	local unit hero = GetValeriaEncounterHero()
	if not ValeriaEncounterActive or ValeriaEncounterResolved or Valeria == null or hero == null then
		set hero = null
		return
	endif
	if not QuestGiver_IsUnitAlive(Valeria) or not QuestGiver_IsUnitAlive(hero) then
		set hero = null
		return
	endif
	if ValeriaNegotiationPromptPending then
		call ForceUnitsFaceEachOther(hero, Valeria)
	endif
	if not QuestGiver_IsWithinRange(Valeria, hero, VALERIA_ENCOUNTER_RESET_DISTANCE) then
		call DisplayTextToForce(GetPlayersAll(), "|cffd45e19You've lost Valeria. She slips back into the ruins.|r")
		call ResetValeriaEncounterToAmbush()
	endif
	set hero = null
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
	if not ValeriaNegotiationPromptPending then
		return
	endif
	if ValeriaNegotiationSequenceBusy then
		return
	endif
	if DialogSystem_IsSequenceActive() then
		return
	endif
	if not ValeriaEncounterActive or ValeriaEncounterResolved then
		return
	endif
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call ExecuteFunc("qAradion_TryOpenValeriaNegotiation")
endfunction

private function OnValeriaSequenceStart takes nothing returns nothing
	set ValeriaNegotiationSequenceBusy = true
	set ValeriaNegotiationPromptPending = false
	call DialogSystem_ClearEscapeAction()
	call EnableUserControl(false)
	call QuestGiver_CloseActiveDialog()
	call ExecuteFunc("TasQuestBox_Hide")
	call EnterCinematicMode()
endfunction

private function BeginValeriaNegotiationSequence takes nothing returns nothing
	set ValeriaNegotiationSequenceBusy = true
	set ValeriaNegotiationPromptPending = false
	call DialogSystem_ClearEscapeAction()
	if ValeriaNegotiationDialog != null then
		call DialogSystem_HideDialog(ValeriaNegotiationDialog, Player(0))
	endif
endfunction

private function ApplyValeriaNegotiationSuccessState takes nothing returns nothing
	if ValeriaSuccessTransitionApplied then
		return
	endif
	set ValeriaSuccessTransitionApplied = true
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call IssueImmediateOrder(Valeria, "stop")
	call SetUnitMoveSpeed(Valeria, GetUnitDefaultMoveSpeed(Valeria))
	call UnitRemoveAbility(Valeria, ABIL_VALERIA_COLD_ARROWS)
	call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 2.00)
	call SetWidgetLife(Valeria, BlzGetUnitMaxHP(Valeria))
	call SetUnitOwner(Valeria, Player(VALERIA_FRIENDLY_OWNER), true)
	call SetUnitCreepGuard(Valeria, false)
	set udg_Valeria = Valeria
endfunction

private function QueueValeriaNegotiationPromptDelayed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	if t == ValeriaNegotiationPromptTimer then
		set ValeriaNegotiationPromptTimer = null
	endif
	call ExecuteFunc("qAradion_QueueValeriaNegotiationPromptPublic")
	if t != null then
		call DestroyTimer(t)
	endif
	set t = null
endfunction

private function StartValeriaNegotiationPromptTimer takes real delay returns nothing
	call StopValeriaNegotiationPromptTimer()
	set ValeriaNegotiationPromptTimer = CreateTimer()
	call TimerStart(ValeriaNegotiationPromptTimer, delay, false, function QueueValeriaNegotiationPromptDelayed)
endfunction

private function QueueValeriaNegotiationPrompt takes nothing returns nothing
	if ValeriaNegotiationSequenceBusy or DialogSystem_IsSequenceActive() then
		call StartValeriaNegotiationPromptTimer(0.25)
		return
	endif
	if not ValeriaEncounterActive or ValeriaEncounterResolved then
		return
	endif
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	call StopValeriaNegotiationPromptTimer()
	set ValeriaNegotiationPromptPending = true
	call ForceValeriaNegotiationFacing()
	call DialogSystem_SetEscapeAction(function RunValeriaNegotiationEscAction)
	call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 5.00, "|cffd45e19Press ESC to persuade Valeria.|r")
endfunction

public function QueueValeriaNegotiationPromptPublic takes nothing returns nothing
	call QueueValeriaNegotiationPrompt()
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
	if ValeriaNegotiationSequenceBusy or DialogSystem_IsSequenceActive() then
		return
	endif
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
	call IssueImmediateOrder(ValeriaEncounterHero, "stop")
	call IssueImmediateOrder(Valeria, "stop")
	set ValeriaNegotiationPromptPending = false
	call StopValeriaNegotiationPromptTimer()
	call DialogSystem_ClearEscapeAction()
	call ForceValeriaNegotiationFacing()
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
	set ValeriaNegotiationSequenceBusy = false
	if hero != null and Valeria != null and QuestGiver_IsUnitAlive(hero) and QuestGiver_IsUnitAlive(Valeria) then
		call IssuePointOrder(Valeria, "attack", GetUnitX(hero), GetUnitY(hero))
	endif
	call StartValeriaNegotiationPromptTimer(0.25)
	set hero = null
endfunction

private function OnValeriaSuccessEnd takes nothing returns nothing
	set ValeriaNegotiationSequenceBusy = false
	call DialogSystem_StopDialogCamera(Player(0), 2.0, USE_DIALOG_CAMERA)
	call ExitCinematicMode()
	call EnableUserControl(true)
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = true
	call RunUpdateQuestRangerMissing()
endfunction

private function BeginValeriaSuccessDialog takes nothing returns nothing
	local integer seq
	local unit hero = GetValeriaEncounterHero()
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		call OnValeriaSuccessEnd()
		set hero = null
		return
	endif
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnValeriaSuccessEnd)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "...Aradion? He... lives?", "Valeria_0014", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "If he trusts you, then perhaps I must as well. For his word has never failed me.", "Valeria_0015", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "If you speak the truth, then take me to him. Now.", "Valeria_0019", true)
	if hero != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
	endif
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "But know this, orc - I'll be watching you.", "Valeria_0020", true)
	call DialogSystem_PlaySequence(seq, Player(0), Valeria)
	set hero = null
endfunction

private function BeginValeriaSuccessDialogDelayed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	call BeginValeriaSuccessDialog()
	if t != null then
		call DestroyTimer(t)
	endif
	set t = null
endfunction

private function FinishValeriaSuccessTransition takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local timer nextTimer = CreateTimer()
	call ForceValeriaNegotiationFacing()
	call IssueValeriaSuccessApproach()
	call StartValeriaDialogCameraSafe(45.00, 60.00)
	if t != null then
		call DestroyTimer(t)
	endif
	call TimerStart(nextTimer, 1.00, false, function BeginValeriaSuccessDialogDelayed)
	set nextTimer = null
	set t = null
endfunction

private function ContinueValeriaSuccessTransition takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local timer nextTimer = CreateTimer()
	call ForceValeriaNegotiationFacing()
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	if t != null then
		call DestroyTimer(t)
	endif
	call TimerStart(nextTimer, 1.00, false, function FinishValeriaSuccessTransition)
	set nextTimer = null
	set t = null
endfunction

private function StartValeriaSuccessTransitionDelayed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local timer nextTimer = CreateTimer()
	call EnableUserControl(false)
	call EnterCinematicMode()
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	if t != null then
		call DestroyTimer(t)
	endif
	call TimerStart(nextTimer, 1.00, false, function ContinueValeriaSuccessTransition)
	set nextTimer = null
	set t = null
endfunction

private function OnValeriaSuccessLeadInEnd takes nothing returns nothing
	local timer t = CreateTimer()
	call ApplyValeriaNegotiationSuccessState()
	call ForceValeriaNegotiationFacing()
	call TimerStart(t, 1.00, false, function StartValeriaSuccessTransitionDelayed)
	set t = null
endfunction

private function OnValeriaIntroEnd takes nothing returns nothing
	local unit hero = GetValeriaEncounterHero()
	call DialogSystem_StopDialogCamera(Player(0), 2.0, USE_DIALOG_CAMERA)
	call ExitCinematicMode()
	call EnableUserControl(true)
	set ValeriaNegotiationSequenceBusy = false
	if not ValeriaEncounterActive or ValeriaEncounterResolved or Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		set hero = null
		return
	endif
	call ResetUnitAnimation(Valeria)
	call SetUnitOwner(Valeria, Player(VALERIA_HOSTILE_OWNER), true)
	call BlzSetUnitRealField(Valeria, UNIT_RF_HIT_POINTS_REGENERATION_RATE, 200.00)
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		call IssuePointOrder(Valeria, "attack", GetUnitX(hero), GetUnitY(hero))
	endif
	call StartValeriaEncounterLoop()
	call StartValeriaNegotiationPromptTimer(2.00)
	set hero = null
endfunction

private function PlayValeriaNegotiationResponse takes integer lineId returns nothing
	local integer seq
	local unit hero = GetValeriaEncounterHero()
	set ValeriaNegotiationPromptPending = false
	set ValeriaNegotiationSequenceBusy = true
	call DialogSystem_ClearEscapeAction()
	if hero != null then
		call IssueImmediateOrder(hero, "stop")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call IssueImmediateOrder(Valeria, "stop")
	endif
	if hero != null then
		call DialogSystem_MakeFaceEachOther(hero, Valeria, 0.50)
	endif
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, function BeginValeriaNegotiationSequence, function OnValeriaResponseEnd)
	if hero != null then
		call QuestGiver_AddHeroLine(seq, hero, GetValeriaNegotiationPrompt(lineId), GetValeriaNegotiationHeroSound(lineId))
	endif
	call DialogSystem_AddLine(seq, Valeria, "Valeria", GetValeriaNegotiationResponse(lineId), GetValeriaNegotiationResponseSound(lineId), true)
	call DialogSystem_PlaySequence(seq, Player(0), Valeria)
	call ActivateValeriaColdArrowsTemporary()
	set hero = null
endfunction

private function PlayValeriaNegotiationSuccess takes nothing returns nothing
	local integer seq
	local unit hero = GetValeriaEncounterHero()
	if Valeria == null or not QuestGiver_IsUnitAlive(Valeria) then
		return
	endif
	set ValeriaNegotiationPromptPending = false
	set ValeriaNegotiationSequenceBusy = true
	call DialogSystem_ClearEscapeAction()
	if hero != null then
		call IssueImmediateOrder(hero, "stop")
	endif
	call IssueImmediateOrder(Valeria, "stop")
	call StopValeriaEncounterTimers()
	call DisableValeriaEncounterDeathTrigger()
	set ValeriaSuccessTransitionApplied = false
	if hero != null then
		set seq = DialogSystem_CreateSequence()
		call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
		call DialogSystem_SetSequenceCallbacks(seq, function BeginValeriaNegotiationSequence, function OnValeriaSuccessLeadInEnd)
		call QuestGiver_AddHeroLine(seq, hero, "I've spoken with Aradion. He told me to find you.", "Nazgrek_0353")
		call DialogSystem_PlaySequence(seq, Player(0), Valeria)
	else
		call BeginValeriaNegotiationSequence()
		call OnValeriaSuccessLeadInEnd()
	endif
	set hero = null
endfunction

public function HandleValeriaNegotiationButton takes nothing returns nothing
	local integer i = 1
	local button clicked = DialogSystem_LastButton
	local integer lineId = 0
	set ValeriaNegotiationPromptPending = false
	call DialogSystem_ClearEscapeAction()
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
	call IssueImmediateOrder(hero, "stop")
	call ForceUnitsFaceEachOther(hero, Valeria)
	call DialogSystem_MakeFaceEachOther(Valeria, hero, 0.75)
	call StartValeriaDialogCameraSafe(180.00, 70.00)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
	call DialogSystem_SetSequenceCallbacks(seq, function OnValeriaSequenceStart, function OnValeriaIntroEnd)
	call SetUnitAnimation(Valeria, "stand ready")
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Hold, intruder! Another step and you bleed where you stand!", "Valeria_0001", true)
	call QuestGiver_AddHeroLine(seq, hero, "You must be Valeria.", "Nazgrek_0340")
	call QuestGiver_AddHeroLine(seq, hero, "I am not your enemy...", "Nazgrek_0341")
	call DialogSystem_AddDelay(seq, 1.50)
	call DialogSystem_AddDelay(seq, 1.00)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Filthy orc lies! I'll drop you where you stand!", "Valeria_0002", true)
	call DialogSystem_BindLineAction(seq, 1, function ForceValeriaNegotiationFacing)
	call DialogSystem_BindLineAction(seq, 2, function ForceValeriaNegotiationFacing)
	call DialogSystem_BindLineAction(seq, 3, function ForceValeriaNegotiationFacing)
	call DialogSystem_BindLineAction(seq, 3, function StartValeriaHeroDialogCamera)
	call DialogSystem_BindLineAction(seq, 4, function MoveValeriaBehindHeroForStandoff)
	call DialogSystem_BindLineAction(seq, 5, function StopValeriaAtStandoff)
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
			call QuestGiver_AddHeroLine(seq, hero, "I'll see if I come across her.", "Nazgrek_0337")
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
		if RiftsAwaitingReturnHome or RiftsReturnedHome then
			if roll == 1 then
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "We should return to our place before we speak further.", "Aradion_0085", true)
			else
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The last rift is sealed. Escort us back to our place.", "Aradion_0084", true)
			endif
			return true
		endif
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
	call QuestGiver_AddHeroLine(seq, hero, "Your blood is not what I seek, elf. I walk the spirit path, not the path of slaughter.", "Nazgrek_0331")
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
		call QuestGiver_AddHeroLine(seq, hero, "You said... a witch deceived you?", "Nazgrek_0332")
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, "Why did your kin trust this witch?", "Nazgrek_0333")
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Her words promised glory - strength to rival Quel'Thalas itself. Her lies were sweet... and my people were starving for more.", "Aradion_0008", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But every promise was poison. Each draught of her 'gift' deepened the hunger, until the hunger itself consumed them.", "Aradion_0009", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now my people are twisted, their flesh withering, their souls bleeding into wraiths. Soon... nothing of them will remain.", "Aradion_0010", true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, "The wraiths I see... they were once elves?", "Nazgrek_0334")
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes. Once mothers, fathers, children. Now only hollow echoes bound to the Void by the magic that devoured them.", "Aradion_0011", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The wretched who remain will share the same fate - it is only a matter of time before they too dissolve into wraiths.", "Aradion_0012", true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, "And you? How did you resist where others fell?", "Nazgrek_0336")
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

private function BindPlacedRiftUnitSlot takes integer index returns nothing
	local unit u = PlacedManaRifts[index]
	local rect r = GetRiftRect(index)
	if u != null and QuestGiver_IsUnitAlive(u) and (RiftsUnitTypeIds[index] == 0 or GetUnitTypeId(u) == RiftsUnitTypeIds[index]) then
		set RiftsUnits[index] = u
		set RiftsUnitTypeIds[index] = GetUnitTypeId(u)
		return
	endif
	set u = QuestGiver_FindPreferredUnitInRect(r, RiftsUnitTypeIds[index], Player(PLAYER_NEUTRAL_PASSIVE), Nazgrek, udg_Zulkis, Aradion, Valeria, true)
	if u != null then
		set RiftsUnits[index] = u
		set RiftsUnitTypeIds[index] = GetUnitTypeId(u)
	endif
endfunction

private function ResetRiftsClosedState takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX
		set RiftsClosed[i] = false
		set i = i + 1
	endloop
endfunction

private function EnsureRiftUnit takes integer index returns unit
	local rect r = GetRiftRect(index)
	local unit u = RiftsUnits[index]
	if index <= 0 or index > RIFTS_MAX or RiftsClosed[index] then
		return null
	endif
	if u != null and QuestGiver_IsUnitAlive(u) then
		return u
	endif
	set RiftsUnits[index] = null
	call BindPlacedRiftUnitSlot(index)
	set u = RiftsUnits[index]
	if u != null and QuestGiver_IsUnitAlive(u) then
		return u
	endif
	set u = QuestGiver_FindPreferredUnitInRect(r, RiftsUnitTypeIds[index], Player(PLAYER_NEUTRAL_PASSIVE), Nazgrek, udg_Zulkis, Aradion, Valeria, true)
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
		if not RiftsClosed[i] then
			call EnsureRiftUnit(i)
		else
			set RiftsUnits[i] = null
		endif
		set i = i + 1
	endloop
	call ExecuteFunc("qAradion_RegisterRiftsProximity")
endfunction

private function PrepareValeriaForRiftsIntro takes unit hero returns nothing
	local real facing
	local real startX
	local real startY
	if Aradion == null or Valeria == null or not QuestGiver_IsUnitAlive(Aradion) or not QuestGiver_IsUnitAlive(Valeria) then
		set hero = null
		return
	endif
	call StopFollow(Valeria)
	call StopValeriaPatrolInternal()
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		set facing = (GetUnitFacing(hero) + 180.00) * bj_DEGTORAD
		set startX = GetUnitX(hero) + RIFTS_INTRO_VALERIA_OFFSET * Cos(facing)
		set startY = GetUnitY(hero) + RIFTS_INTRO_VALERIA_OFFSET * Sin(facing)
	else
		set facing = GetUnitFacing(Aradion) * bj_DEGTORAD
		set startX = GetUnitX(Aradion) + RIFTS_INTRO_VALERIA_OFFSET * Cos(facing)
		set startY = GetUnitY(Aradion) + RIFTS_INTRO_VALERIA_OFFSET * Sin(facing)
	endif
	call SetUnitPosition(Valeria, startX, startY)
	call SetUnitFacing(Valeria, 192.00)
	call IssuePointOrder(Valeria, "move", GetRectCenterX(gg_rct_ValeriaNewPos), GetRectCenterY(gg_rct_ValeriaNewPos))
	set hero = null
endfunction

private function OrderAradionToChannelCurrentRift takes nothing returns nothing
	local real rx
	local real ry
	if not RiftsRitualActive or Aradion == null or RiftsCurrentRift == null then
		return
	endif
	if not QuestGiver_IsUnitAlive(Aradion) or not QuestGiver_IsUnitAlive(RiftsCurrentRift) then
		return
	endif
	if GetUnitAbilityLevel(Aradion, ABIL_RIFT_CLOSE) == 0 then
		call UnitAddAbility(Aradion, ABIL_RIFT_CLOSE)
	endif
	set rx = GetUnitX(RiftsCurrentRift)
	set ry = GetUnitY(RiftsCurrentRift)
	call ResetUnitAnimation(Aradion)
	call IssuePointOrder(Aradion, "blizzard", rx, ry)
endfunction

private function DestroyRiftsProximityTrigger takes nothing returns nothing
	if RiftsProximityTrigger != null then
		call DestroyTrigger(RiftsProximityTrigger)
		set RiftsProximityTrigger = null
	endif
endfunction

private function GetRiftIndexForUnit takes unit riftUnit returns integer
	local integer i = 1
	local unit slotUnit
	local rect r
	if riftUnit == null or GetUnitTypeId(riftUnit) == 0 then
		return 0
	endif
	loop
		exitwhen i > RIFTS_MAX
		if not RiftsClosed[i] then
			set slotUnit = EnsureRiftUnit(i)
			if slotUnit == riftUnit or PlacedManaRifts[i] == riftUnit then
				set slotUnit = null
				set r = null
				return i
			endif
			set r = GetRiftRect(i)
			if r != null and RectContainsCoords(r, GetUnitX(riftUnit), GetUnitY(riftUnit)) and (RiftsUnitTypeIds[i] == 0 or GetUnitTypeId(riftUnit) == RiftsUnitTypeIds[i]) then
				set slotUnit = null
				set r = null
				return i
			endif
		endif
		set slotUnit = null
		set r = null
		set i = i + 1
	endloop
	return 0
endfunction

private function GetPointRectDistanceSq takes rect r, real x, real y returns real
	local real closestX
	local real closestY
	local real dx
	local real dy
	if r == null then
		return 999999999.00
	endif
	set closestX = x
	set closestY = y
	if closestX < GetRectMinX(r) then
		set closestX = GetRectMinX(r)
	elseif closestX > GetRectMaxX(r) then
		set closestX = GetRectMaxX(r)
	endif
	if closestY < GetRectMinY(r) then
		set closestY = GetRectMinY(r)
	elseif closestY > GetRectMaxY(r) then
		set closestY = GetRectMaxY(r)
	endif
	set dx = x - closestX
	set dy = y - closestY
	return dx * dx + dy * dy
endfunction

private function IsUnitNearRiftIndex takes unit u, integer index returns boolean
	local rect r
	local unit riftUnit
	local real rangeSq = RIFTS_TRIGGER_RANGE * RIFTS_TRIGGER_RANGE
	local boolean result = false
	if u == null or not QuestGiver_IsUnitAlive(u) or index <= 0 or index > RIFTS_MAX or RiftsClosed[index] then
		set u = null
		return false
	endif
	set riftUnit = RiftsUnits[index]
	if riftUnit == null or not QuestGiver_IsUnitAlive(riftUnit) then
		set riftUnit = EnsureRiftUnit(index)
	endif
	if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) and QuestGiver_IsWithinRange(riftUnit, u, RIFTS_TRIGGER_RANGE) then
		set result = true
	endif
	if not result then
		set r = GetRiftRect(index)
		if r != null and GetPointRectDistanceSq(r, GetUnitX(u), GetUnitY(u)) <= rangeSq then
			set result = true
		endif
	endif
	set r = null
	set riftUnit = null
	set u = null
	return result
endfunction

private function GetTriggeredRiftIndex takes unit hero returns integer
	local integer i = 1
	local integer result = 0
	local real bestDistSq = 999999999.00
	local real rangeSq = RIFTS_TRIGGER_RANGE * RIFTS_TRIGGER_RANGE
	local real distSq
	local unit riftUnit
	local rect r
	local real hx
	local real hy
	local real rx
	local real ry
	if hero == null then
		return 0
	endif
	set hx = GetUnitX(hero)
	set hy = GetUnitY(hero)
	loop
		exitwhen i > RIFTS_MAX
		if not RiftsClosed[i] then
			set riftUnit = EnsureRiftUnit(i)
			set distSq = 999999999.00
			if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) then
				set rx = GetUnitX(riftUnit)
				set ry = GetUnitY(riftUnit)
				set distSq = (hx - rx) * (hx - rx) + (hy - ry) * (hy - ry)
			endif
			set r = GetRiftRect(i)
			if r != null then
				if RectContainsCoords(r, hx, hy) then
					set distSq = 0.00
				elseif GetPointRectDistanceSq(r, hx, hy) < distSq then
					set distSq = GetPointRectDistanceSq(r, hx, hy)
				endif
			endif
			if distSq <= rangeSq and distSq < bestDistSq then
				set bestDistSq = distSq
				set result = i
			endif
		endif
		set riftUnit = null
		set r = null
		set i = i + 1
	endloop
	return result
endfunction

private function KillManaRiftUnit takes unit riftUnit returns nothing
	if riftUnit != null and GetUnitTypeId(riftUnit) == UNIT_MANA_RIFT then
		if GetWidgetLife(riftUnit) > 0.405 then
			call KillUnit(riftUnit)
		endif
	endif
	set riftUnit = null
endfunction

private function GetRiftEffectX takes unit closedRift, unit placedRift, integer riftIndex returns real
	local rect r
	local real result
	if closedRift != null and GetUnitTypeId(closedRift) != 0 then
		set result = GetUnitX(closedRift)
	elseif placedRift != null and GetUnitTypeId(placedRift) != 0 then
		set result = GetUnitX(placedRift)
	else
		set r = GetRiftRect(riftIndex)
		if r != null then
			set result = GetRectCenterX(r)
		else
			set result = 0.00
		endif
	endif
	set closedRift = null
	set placedRift = null
	set r = null
	return result
endfunction

private function GetRiftEffectY takes unit closedRift, unit placedRift, integer riftIndex returns real
	local rect r
	local real result
	if closedRift != null and GetUnitTypeId(closedRift) != 0 then
		set result = GetUnitY(closedRift)
	elseif placedRift != null and GetUnitTypeId(placedRift) != 0 then
		set result = GetUnitY(placedRift)
	else
		set r = GetRiftRect(riftIndex)
		if r != null then
			set result = GetRectCenterY(r)
		else
			set result = 0.00
		endif
	endif
	set closedRift = null
	set placedRift = null
	set r = null
	return result
endfunction

private function PlayRiftsStartBarks takes nothing returns nothing
	local integer roll
	set roll = GetRandomInt(1, 2)
	if roll == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0074", "Stand ready. Once I begin, this place can start to crawl with wraiths.")
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0075", "I will attempt to close this rift. But I cannot fight and focus at once... you must protect me!")
	endif
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0072", "We will handle them, just keep your focus on the rift!")
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0073", "We stand ready to defend you!")
	endif
endfunction

private function StartRiftsRitualInternal takes unit riftUnit, integer riftIndex, unit hero returns nothing
	if riftUnit == null or not QuestGiver_IsUnitAlive(riftUnit) or Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	if not IsAradionFieldZoneActive() then
		return
	endif
	if riftIndex <= 0 or riftIndex > RIFTS_MAX or RiftsClosed[riftIndex] then
		return
	endif
	if RiftsRitualActive or RiftsFailureInProgress then
		return
	endif
	set SelectedHero = hero
	set RiftsCurrentRift = riftUnit
	set RiftsCurrentIndex = riftIndex
	set RiftsUnits[riftIndex] = riftUnit
	set RiftsRitualActive = true
	set RiftsNextWaveN = 1
	call DialogSystem_ClearFieldLineQueue()
	call DestroyRiftsProximityTrigger()
	call Companions_Suspend(Aradion)
	call StopValeriaPatrolInternal()
	call IssueImmediateOrder(Aradion, "stop")
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call AddValeriaCompanion()
		call Companions_SetMode(Valeria, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Valeria, hero)
		call Companions_Resume(Valeria)
	endif
	call PlayRiftsStartBarks()
	call OrderAradionToChannelCurrentRift()
	call ExecuteFunc("qAradion_StartRiftsRuntimeTimersPublic")
endfunction

private function TryStartRiftsRitualForHero takes unit hero returns boolean
	local integer riftIndex
	local unit riftUnit
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		return false
	endif
	if not IsAradionFieldZoneActive() then
		return false
	endif
	set riftIndex = GetTriggeredRiftIndex(hero)
	if riftIndex <= 0 then
		return false
	endif
	if not IsUnitNearRiftIndex(Aradion, riftIndex) then
		return false
	endif
	set riftUnit = EnsureRiftUnit(riftIndex)
	if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) then
		call StartRiftsRitualInternal(riftUnit, riftIndex, hero)
		set riftUnit = null
		return true
	endif
	set riftUnit = null
	return false
endfunction

private function OnRiftsProximity takes nothing returns nothing
	local unit hero = GetTriggerUnit()
	call SyncUnitReferences()
	if not RiftsQuestActive or RiftsRitualActive or RiftsAwaitingReturnHome or RiftsFailureInProgress then
		set hero = null
		return
	endif
	if hero == null or not QuestGiver_IsUnitAlive(hero) then
		set hero = null
		return
	endif
	if hero != Nazgrek and hero != udg_Zulkis then
		set hero = null
		return
	endif
	if (hero == Nazgrek and not ALLOW_NAZGREK) or (hero == udg_Zulkis and not ALLOW_ZULKIS) then
		set hero = null
		return
	endif
	call TryStartRiftsRitualForHero(hero)
	set hero = null
endfunction

private function RegisterRiftsProximityTrigger takes nothing returns nothing
	local integer i = 1
	local unit riftUnit
	call DestroyRiftsProximityTrigger()
	set RiftsProximityTrigger = CreateTrigger()
	loop
		exitwhen i > RIFTS_MAX
		if not RiftsClosed[i] then
			set riftUnit = EnsureRiftUnit(i)
		else
			set riftUnit = null
		endif
		if riftUnit != null and QuestGiver_IsUnitAlive(riftUnit) then
			call TriggerRegisterUnitInRange(RiftsProximityTrigger, riftUnit, RIFTS_TRIGGER_RANGE, null)
		endif
		set riftUnit = null
		set i = i + 1
	endloop
	call TriggerAddAction(RiftsProximityTrigger, function OnRiftsProximity)
endfunction

private function ClearRiftsWaveHandles takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX_WAVES
		if RiftsWaveHandles[i] != 0 then
			call RiftsWaveHandles[i].killAllUnits()
			call RiftsWaveHandles[i].destroy()
			set RiftsWaveHandles[i] = 0
		endif
		set RiftsWaveSpawnCountdown[i] = 0
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

private function StopRiftsFailResetTimer takes nothing returns nothing
	if RiftsFailResetTimer != null then
		call DestroyTimer(RiftsFailResetTimer)
		set RiftsFailResetTimer = null
	endif
endfunction

private function ResetRiftsObjectivesForNewRun takes QuestData q returns nothing
	if q == 0 then
		return
	endif
	call q.setRequirement(1, "Find all rifts scattered around the Vanguard Vale")
	call q.updateRequirementText(1, "Find all rifts scattered around the Vanguard Vale")
	call q.setRequirement(2, "Rifts closed 0 / 3")
	call q.updateRequirementText(2, "Rifts closed 0 / 3")
	call q.setRequirement(3, "Guard Aradion while he closes the rifts")
	call q.updateRequirementText(3, "Guard Aradion while he closes the rifts")
	call q.setRequirement(4, "Both Aradion and Valeria must stay alive")
	call q.updateRequirementText(4, "Both Aradion and Valeria must stay alive")
	call q.setRequirement(5, "")
	call q.updateRequirementText(5, "")
	call q.markRequirementCompleted(1, false)
	call q.markRequirementCompleted(2, false)
	call q.markRequirementCompleted(3, false)
	call q.markRequirementCompleted(4, false)
	call q.markRequirementCompleted(5, false)
	call q.refreshQuestLog()
endfunction

private function GetRiftsFailurePrimaryText takes unit failedUnit returns string
	if failedUnit == Valeria then
		return "Forgive me... my love... I... have failed..."
	elseif failedUnit == Aradion then
		return "The current was... too strong... I..."
	endif
	return ""
endfunction

private function GetRiftsFailurePrimarySound takes unit failedUnit returns string
	if failedUnit == Valeria then
		return "Valeria_0064"
	elseif failedUnit == Aradion then
		return "Aradion_0086"
	endif
	return ""
endfunction

private function GetRiftsFailureReplyText takes unit failedUnit returns string
	if failedUnit == Valeria then
		return "Valeria!"
	elseif failedUnit == Aradion then
		return "Aradion...? No!!!"
	endif
	return ""
endfunction

private function GetRiftsFailureReplySound takes unit failedUnit returns string
	if failedUnit == Valeria then
		return "Aradion_0079"
	elseif failedUnit == Aradion then
		return "Valeria_0063"
	endif
	return ""
endfunction

private function FreezeRiftsFailedUnit takes nothing returns nothing
	local timer t = GetExpiredTimer()
	if RiftsFailedUnit != null and GetUnitTypeId(RiftsFailedUnit) != 0 then
		call SetUnitTimeScale(RiftsFailedUnit, 0.00)
	endif
	if t != null then
		call DestroyTimer(t)
	endif
	set t = null
endfunction

private function PrepareRiftsFailedUnit takes unit failedUnit returns nothing
	local timer t
	local real deathTime
	if failedUnit == null or not QuestGiver_IsUnitAlive(failedUnit) then
		return
	endif
	call SetUnitInvulnerable(failedUnit, true)
	call SetUnitOwner(failedUnit, Player(PLAYER_NEUTRAL_PASSIVE), true)
	call IssueImmediateOrder(failedUnit, "stop")
	call SetUnitAnimation(failedUnit, "death")
	call PauseUnit(failedUnit, true)
	set deathTime = BlzGetUnitRealField(failedUnit, UNIT_RF_DEATH_TIME)
	if deathTime <= 0.00 then
		set deathTime = 1.50
	endif
	set t = CreateTimer()
	call TimerStart(t, deathTime, false, function FreezeRiftsFailedUnit)
	set t = null
endfunction

private function StopRiftsCompanionsAtHomeInternal takes nothing returns nothing
	call StopFieldCompanions()
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call SetUnitInvulnerable(Aradion, false)
		call IssueImmediateOrder(Aradion, "stop")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitInvulnerable(Valeria, false)
		call IssueImmediateOrder(Valeria, "stop")
	endif
endfunction

private function ReturnRiftsCompanionsHomeInternal takes nothing returns nothing
	local player aradionOwner = AradionHomeOwner
	call StopFieldCompanions()
	if aradionOwner == null and Aradion != null then
		set aradionOwner = GetOwningPlayer(Aradion)
	endif
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call QuestGiver_ResetFieldUnitAtPoint(Aradion, aradionOwner, GetRectCenterX(gg_rct_AradionPos), GetRectCenterY(gg_rct_AradionPos), 184.00, true)
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call QuestGiver_ResetFieldUnitAtPoint(Valeria, Player(VALERIA_HOME_OWNER), GetRectCenterX(gg_rct_ValeriaNewPos), GetRectCenterY(gg_rct_ValeriaNewPos), 192.00, true)
		call StartValeriaHomePatrolInternal()
	endif
	set aradionOwner = null
endfunction

private function HandleRiftsReturnedHome takes nothing returns nothing
	local QuestData q
	if not RiftsAwaitingReturnHome then
		return
	endif
	set RiftsAwaitingReturnHome = false
	set RiftsReturnedHome = true
	call StopRiftsFieldMonitor()
	call StopRiftsCompanionsAtHomeInternal()
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call q.markRequirementCompleted(5, true)
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_READY_TURNIN)
		call q.refreshQuestLog()
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
endfunction

private function GetAllowedRiftHeroInRange takes unit riftUnit returns unit
	local integer bestHero = 0
	local integer bestLevel = -1
	local integer level
	if riftUnit == null then
		set riftUnit = null
		return null
	endif
	if ALLOW_NAZGREK and Nazgrek != null and QuestGiver_IsUnitAlive(Nazgrek) and QuestGiver_IsWithinRange(riftUnit, Nazgrek, RIFTS_TRIGGER_RANGE) then
		set bestHero = 1
		set bestLevel = GetHeroLevel(Nazgrek)
	endif
	if ALLOW_ZULKIS and udg_Zulkis != null and QuestGiver_IsUnitAlive(udg_Zulkis) and QuestGiver_IsWithinRange(riftUnit, udg_Zulkis, RIFTS_TRIGGER_RANGE) then
		set level = GetHeroLevel(udg_Zulkis)
		if bestHero == 0 or level > bestLevel then
			set bestHero = 2
			set bestLevel = level
		endif
	endif
	set riftUnit = null
	if bestHero == 1 then
		return Nazgrek
	elseif bestHero == 2 then
		return udg_Zulkis
	endif
	return null
endfunction

private function GetAllowedRiftHeroForIndex takes integer index returns unit
	local unit riftUnit = EnsureRiftUnit(index)
	local unit nearbyHero = null
	local integer bestHero = 0
	local integer bestLevel = -1
	local integer level
	if index <= 0 or index > RIFTS_MAX or RiftsClosed[index] then
		set riftUnit = null
		set nearbyHero = null
		return null
	endif
	if riftUnit != null then
		set nearbyHero = GetAllowedRiftHeroInRange(riftUnit)
		if nearbyHero == Nazgrek then
			set nearbyHero = null
			set riftUnit = null
			return Nazgrek
		elseif nearbyHero == udg_Zulkis then
			set nearbyHero = null
			set riftUnit = null
			return udg_Zulkis
		endif
		set nearbyHero = null
	endif
	if ALLOW_NAZGREK and IsUnitNearRiftIndex(Nazgrek, index) then
		set bestHero = 1
		set bestLevel = GetHeroLevel(Nazgrek)
	endif
	if ALLOW_ZULKIS and IsUnitNearRiftIndex(udg_Zulkis, index) then
		set level = GetHeroLevel(udg_Zulkis)
		if bestHero == 0 or level > bestLevel then
			set bestHero = 2
			set bestLevel = level
		endif
	endif
	set nearbyHero = null
	set riftUnit = null
	if bestHero == 1 then
		return Nazgrek
	elseif bestHero == 2 then
		return udg_Zulkis
	endif
	return null
endfunction

private function GetRiftsLiveWaveCount takes nothing returns integer
	local integer i = 1
	local integer count = 0
	loop
		exitwhen i > RiftsWaveIndex or i > RIFTS_MAX_WAVES
		if RiftsWaveHandles[i] != 0 and RiftsWaveHandles[i].getRemainingCount() > 0 then
			set count = count + 1
		endif
		set i = i + 1
	endloop
	return count
endfunction

private function HasOldRiftsWaveAlive takes nothing returns boolean
	local integer i = 1
	loop
		exitwhen i > RiftsWaveIndex or i > RIFTS_MAX_WAVES
		if RiftsWaveHandles[i] != 0 and RiftsWaveHandles[i].getRemainingCount() > 0 and I2R(RiftsWaveSpawnCountdown[i] - RiftsCountdownRemaining) >= RIFTS_OVERWHELMED_WAVE_AGE then
			return true
		endif
		set i = i + 1
	endloop
	return false
endfunction

private function ShouldPlayRiftsOverwhelmedLine takes nothing returns boolean
	return GetRiftsLiveWaveCount() > 1 or HasOldRiftsWaveAlive()
endfunction

private function PlayRiftsIncomingWaveBark takes nothing returns nothing
	local integer roll
	set roll = GetRandomInt(1, 2)
	if roll == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0061", "Hold your ground! Don't let them reach Aradion!")
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0062", "The rift is pulling every wrath towards it - brace yourself!")
	endif
endfunction

private function PlayRiftsCombatBark takes nothing returns nothing
	local integer roll
	if ShouldPlayRiftsOverwhelmedLine() then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0065", "They are too many! Drive them back!")
		return
	endif
	set roll = GetRandomInt(1, 3)
	if roll == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0076", "Hold them back! Just a little longer!")
	elseif roll == 2 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0077", "The rift is still open - I need more time!")
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0078", "Try to keep them away from me!")
	endif
endfunction

private function PlayRiftsFinishBarks takes nothing returns nothing
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0080", "It is done. This rift is sealed.")
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0082", "I managed to close this rift.")
	endif
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0066", "Great job, my love!")
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0068", "You never cease to amaze me, my love.")
	endif
endfunction

private function PlayRiftsAllClosedBarks takes nothing returns nothing
	call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0084", "I think this was the last of them. All rifts should now be closed.")
	call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0070", "So, is it... over now? Is this the answer to our people's curse?")
	call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0085", "In time, we will see... It's time to head back to our place.")
	call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0071", "Gladly.")
endfunction

private function SpawnRiftsWave takes nothing returns nothing
	local location spawnLoc
	local rect r
	local real spawnX
	local real spawnY
	if not RiftsRitualActive then
		return
	endif
	if not IsAradionFieldZoneActive() then
		return
	endif
	if RiftsWaveIndex >= RIFTS_MAX_WAVES then
		return
	endif
	if I2R(RiftsCountdownRemaining) <= RIFTS_WAVE_END_BUFFER then
		return
	endif
	if RiftsCurrentRift != null and QuestGiver_IsUnitAlive(RiftsCurrentRift) then
		set spawnX = GetUnitX(RiftsCurrentRift)
		set spawnY = GetUnitY(RiftsCurrentRift)
	else
		set r = GetRiftRect(RiftsCurrentIndex)
		if r == null then
			return
		endif
		set spawnX = GetRectCenterX(r)
		set spawnY = GetRectCenterY(r)
	endif
	set spawnLoc = Location(spawnX, spawnY)
	set RiftsWaveIndex = RiftsWaveIndex + 1
	set RiftsWaveSpawnCountdown[RiftsWaveIndex] = RiftsCountdownRemaining
	if RiftsNextWaveN == 1 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave1DelayedSoundEx(Player(RIFTS_WAVE_OWNER), spawnLoc, RIFTS_WAVE_PRE_SPAWN_EFFECT, RIFTS_WAVE_PRE_SPAWN_DELAY, RIFTS_WAVE_PRE_SPAWN_EFFECT_DURATION, RIFTS_WAVE_PRE_SPAWN_CREATE_SOUND, RIFTS_WAVE_PRE_SPAWN_DESTROY_SOUND, RIFTS_WAVE_SPAWN_EFFECT, RIFTS_WAVE_SPAWN_EFFECT_DURATION, true)
	elseif RiftsNextWaveN == 2 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave2DelayedSoundEx(Player(RIFTS_WAVE_OWNER), spawnLoc, RIFTS_WAVE_PRE_SPAWN_EFFECT, RIFTS_WAVE_PRE_SPAWN_DELAY, RIFTS_WAVE_PRE_SPAWN_EFFECT_DURATION, RIFTS_WAVE_PRE_SPAWN_CREATE_SOUND, RIFTS_WAVE_PRE_SPAWN_DESTROY_SOUND, RIFTS_WAVE_SPAWN_EFFECT, RIFTS_WAVE_SPAWN_EFFECT_DURATION, true)
	elseif RiftsNextWaveN == 3 then
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave3DelayedSoundEx(Player(RIFTS_WAVE_OWNER), spawnLoc, RIFTS_WAVE_PRE_SPAWN_EFFECT, RIFTS_WAVE_PRE_SPAWN_DELAY, RIFTS_WAVE_PRE_SPAWN_EFFECT_DURATION, RIFTS_WAVE_PRE_SPAWN_CREATE_SOUND, RIFTS_WAVE_PRE_SPAWN_DESTROY_SOUND, RIFTS_WAVE_SPAWN_EFFECT, RIFTS_WAVE_SPAWN_EFFECT_DURATION, true)
	else
		set RiftsWaveHandles[RiftsWaveIndex] = WavesRiftWraits_Wave4DelayedSoundEx(Player(RIFTS_WAVE_OWNER), spawnLoc, RIFTS_WAVE_PRE_SPAWN_EFFECT, RIFTS_WAVE_PRE_SPAWN_DELAY, RIFTS_WAVE_PRE_SPAWN_EFFECT_DURATION, RIFTS_WAVE_PRE_SPAWN_CREATE_SOUND, RIFTS_WAVE_PRE_SPAWN_DESTROY_SOUND, RIFTS_WAVE_SPAWN_EFFECT, RIFTS_WAVE_SPAWN_EFFECT_DURATION, true)
	endif
	if RiftsWaveHandles[RiftsWaveIndex] != 0 and Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call RiftsWaveHandles[RiftsWaveIndex].attackMove(GetUnitX(Aradion), GetUnitY(Aradion))
	endif
	set RiftsNextWaveN = GetRandomInt(1, 4)
	call RemoveLocation(spawnLoc)
	set r = null
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
	if RiftsCurrentRift != null and QuestGiver_IsUnitAlive(RiftsCurrentRift) and GetUnitCurrentOrder(Aradion) != OrderId("blizzard") then
		call OrderAradionToChannelCurrentRift()
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
	call SyncUnitReferences()
	if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	if not IsRiftsCorruptionInProgress() then
		return
	endif
	set RiftsCorruptionCounter = RiftsCorruptionCounter + 1
	call DebugMsg("Updating Quest: Rifts of Corruption - Counter=" + I2S(RiftsCorruptionCounter))
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q == 0 then
		return
	endif
	call QuestGiver_SetRequirement(q.id, 2, "Rifts closed " + I2S(RiftsCorruptionCounter) + " / 3")
	if RiftsCorruptionCounter >= 3 then
		call q.markRequirementCompleted(1, true)
		call q.markRequirementCompleted(2, true)
		call q.markRequirementCompleted(3, true)
		call q.markRequirementCompleted(4, true)
		call QuestGiver_AddRequirement(q.id, 5, "Escort Aradion and Valeria to Aradion's place")
		call q.markRequirementCompleted(5, false)
		call q.refreshQuestLog()
		set RiftsAwaitingReturnHome = true
		set RiftsReturnedHome = false
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_IN_PROGRESS)
	else
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_IN_PROGRESS)
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
endfunction

private function FinishRiftsCurrentRitual takes nothing returns nothing
	local unit hero
	local unit closedRift = RiftsCurrentRift
	local unit placedRift = null
	local integer closedIndex = RiftsCurrentIndex
	local real closedRiftX = 0.00
	local real closedRiftY = 0.00
	call SyncUnitReferences()
	if not RiftsQuestActive then
		set closedRift = null
		set placedRift = null
		return
	endif
	call StopRiftsRuntimeTimers()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	if closedIndex > 0 and closedIndex <= RIFTS_MAX then
		set placedRift = PlacedManaRifts[closedIndex]
		set RiftsClosed[closedIndex] = true
		set RiftsUnits[closedIndex] = null
		set PlacedManaRifts[closedIndex] = null
	endif
	set closedRiftX = GetRiftEffectX(closedRift, placedRift, closedIndex)
	set closedRiftY = GetRiftEffectY(closedRift, placedRift, closedIndex)
	if closedRiftX != 0.00 or closedRiftY != 0.00 then
		call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl", closedRiftX, closedRiftY))
	endif
	if placedRift != null then
		call KillManaRiftUnit(placedRift)
	else
		call KillManaRiftUnit(closedRift)
	endif
	set RiftsRitualActive = false
	set RiftsCurrentRift = null
	set RiftsCurrentIndex = 0
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call IssueImmediateOrder(Aradion, "stop")
		call UnitRemoveAbility(Aradion, ABIL_RIFT_CLOSE)
		call SetUnitAnimation(Aradion, "stand")
	endif
	call PlayRiftsFinishBarks()
	call UpdateQuestRiftsCorruptionInternal()
	set hero = ResolveDialogHero()
	call StartFieldCompanions(hero)
	call RegisterRiftUnits()
	if RiftsCorruptionCounter >= 3 then
		call PlayRiftsAllClosedBarks()
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", "Aradion_0083", "Let's head to the next one. Be on your guard.")
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", "Valeria_0069", "Don't worry my love, we will be.")
	endif
	set hero = null
	set closedRift = null
	set placedRift = null
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
	local unit hero
	call SyncUnitReferences()
	if not RiftsQuestActive or RiftsFailureInProgress then
		return
	endif
	if not IsAradionFieldZoneActive() then
		call StopFieldCompanions()
		return
	endif
	if RiftsAwaitingReturnHome then
		set hero = ResolveDialogHero()
		if hero != null and RectContainsUnit(gg_rct_AradionPlace, hero) and Aradion != null and Valeria != null and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) and RectContainsUnit(gg_rct_AradionPlace, Aradion) and RectContainsUnit(gg_rct_AradionPlace, Valeria) then
			call HandleRiftsReturnedHome()
		endif
		set hero = null
		return
	endif
	if RiftsRitualActive then
		return
	endif
	if ALLOW_NAZGREK and Nazgrek != null and TryStartRiftsRitualForHero(Nazgrek) then
		return
	endif
	if ALLOW_ZULKIS and udg_Zulkis != null and TryStartRiftsRitualForHero(udg_Zulkis) then
		return
	endif
	set hero = null
endfunction

private function StartRiftsFieldMonitor takes nothing returns nothing
	call StopRiftsFieldMonitor()
	set RiftsFieldTimer = CreateTimer()
	call TimerStart(RiftsFieldTimer, 0.50, true, function OnRiftsFieldTick)
endfunction

private function OrderRiftsSurvivorToFallenCompanion takes nothing returns nothing
	local unit survivor = null
	local unit fallen = null
	local real x
	local real y
	if RiftsFailedUnit == Aradion and Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		set survivor = Valeria
		set fallen = Aradion
	elseif RiftsFailedUnit == Valeria and Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		set survivor = Aradion
		set fallen = Valeria
	elseif Aradion != null and Valeria != null and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) then
		if GetWidgetLife(Aradion) <= 1.05 then
			set survivor = Valeria
			set fallen = Aradion
		elseif GetWidgetLife(Valeria) <= 1.05 then
			set survivor = Aradion
			set fallen = Valeria
		endif
	endif
	if survivor != null and fallen != null then
		set x = GetUnitX(fallen)
		set y = GetUnitY(fallen)
		call SetUnitInvulnerable(survivor, true)
		call IssuePointOrder(survivor, "move", x, y)
	endif
	set RiftsFailureSurvivor = survivor
	set survivor = null
	set fallen = null
endfunction

private function FinalizeRiftsFailureReset takes nothing returns nothing
	local QuestData q
	local timer t = GetExpiredTimer()
	call SyncUnitReferences()
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
	set RiftsFailureInProgress = false
	set RiftsUnitTypeIds[1] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[2] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[3] = UNIT_MANA_RIFT
	call ResetRiftsClosedState()
	call ReturnRiftsCompanionsHomeInternal()
	call RegisterRiftUnits()
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call ResetRiftsObjectivesForNewRun(q)
	endif
	call QuestGiver_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_AVAILABLE)
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	set RiftsPendingFailReason = ""
	set RiftsFailedUnit = null
	set RiftsFailureSurvivor = null
	if t == RiftsFailResetTimer then
		set RiftsFailResetTimer = null
	endif
	if t != null then
		call DestroyTimer(t)
	endif
	set q = 0
	set t = null
endfunction

private function PlayRiftsFailureSurvivorLine takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local string text
	local string soundName
	if RiftsFailureSurvivor != null and RiftsFailedUnit != null and QuestGiver_IsUnitAlive(RiftsFailureSurvivor) then
		set text = GetRiftsFailureReplyText(RiftsFailedUnit)
		set soundName = GetRiftsFailureReplySound(RiftsFailedUnit)
		call DialogSystem_PlayLine(RiftsFailureSurvivor, QuestGiver_GetUnitDisplayName(RiftsFailureSurvivor), text, soundName, true)
	endif
	call QuestGiver_FailQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, RiftsPendingFailReason)
	call StopRiftsFailResetTimer()
	set RiftsFailResetTimer = CreateTimer()
	call TimerStart(RiftsFailResetTimer, RIFTS_FAIL_RESET_DELAY, false, function FinalizeRiftsFailureReset)
	if t != null then
		call DestroyTimer(t)
	endif
	set t = null
endfunction

private function HandleRiftsFailure takes string reason returns nothing
	local timer t
	local string text
	local string soundName
	local real delay
	call SyncUnitReferences()
	if RiftsFailureInProgress or not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) or QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	set RiftsFailureInProgress = true
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	call DisableRiftsFailTriggers()
	call DestroyRiftsProximityTrigger()
	call StopRiftsFailResetTimer()
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call IssueImmediateOrder(Aradion, "stop")
		call UnitRemoveAbility(Aradion, ABIL_RIFT_CLOSE)
		call SetUnitAnimation(Aradion, "stand")
	endif
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call IssueImmediateOrder(Valeria, "stop")
	endif
	call StopFieldCompanions()
	if RiftsFailedUnit != null and QuestGiver_IsUnitAlive(RiftsFailedUnit) then
		call PrepareRiftsFailedUnit(RiftsFailedUnit)
	endif
	call OrderRiftsSurvivorToFallenCompanion()
	set RiftsPendingFailReason = reason
	if RiftsFailedUnit == null then
		call QuestGiver_FailQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, RiftsPendingFailReason)
		call StopRiftsFailResetTimer()
		set RiftsFailResetTimer = CreateTimer()
		call TimerStart(RiftsFailResetTimer, RIFTS_FAIL_RESET_DELAY, false, function FinalizeRiftsFailureReset)
		return
	endif
	set text = GetRiftsFailurePrimaryText(RiftsFailedUnit)
	set soundName = GetRiftsFailurePrimarySound(RiftsFailedUnit)
	if text != "" then
		call DialogSystem_PlayLine(RiftsFailedUnit, QuestGiver_GetUnitDisplayName(RiftsFailedUnit), text, soundName, true)
		if udg_ExSoundDuration > 0.00 then
			set delay = udg_ExSoundDuration
		else
			set delay = DialogSystem_EstimateFieldLineDuration(text)
		endif
	else
		set delay = 0.50
	endif
	set t = CreateTimer()
	call TimerStart(t, delay, false, function PlayRiftsFailureSurvivorLine)
	set t = null
endfunction

private function StopFadingSparksTimer takes nothing returns nothing
	if FadingSparksTimer != null then
		call DestroyTimer(FadingSparksTimer)
		set FadingSparksTimer = null
	endif
endfunction

private function ClearFadingSparksState takes nothing returns nothing
	call StopFadingSparksTimer()
	set FadingSparksFinished = false
	set FadingSparksCaster = null
	set FadingSparksTarget = null
endfunction

private function OnFadingSparksTimerExpire takes nothing returns nothing
	local timer t = GetExpiredTimer()
	set FadingSparksFinished = true
	if t == FadingSparksTimer then
		set FadingSparksTimer = null
	endif
	set t = null
endfunction

private function IsFadingSparksWraithType takes integer unitTypeId returns boolean
	if unitTypeId == UNIT_MANA_WRAITH then
		return true
	endif
	if UNIT_FADING_SPARKS_WRAITH_2 != 0 and unitTypeId == UNIT_FADING_SPARKS_WRAITH_2 then
		return true
	endif
	if UNIT_FADING_SPARKS_WRAITH_3 != 0 and unitTypeId == UNIT_FADING_SPARKS_WRAITH_3 then
		return true
	endif
	if UNIT_FADING_SPARKS_WRAITH_4 != 0 and unitTypeId == UNIT_FADING_SPARKS_WRAITH_4 then
		return true
	endif
	return false
endfunction

private function OnFadingSparksSpellEffect takes nothing returns nothing
	local unit caster = GetTriggerUnit()
	local unit target = GetSpellTargetUnit()
	if GetSpellAbilityId() != ABIL_TELANOR_ROD then
		set caster = null
		set target = null
		return
	endif
	call ClearFadingSparksState()
	if not IsFadingSparksInProgress() or caster == null or target == null then
		set caster = null
		set target = null
		return
	endif
	if not IsFadingSparksWraithType(GetUnitTypeId(target)) then
		set caster = null
		set target = null
		return
	endif
	set FadingSparksCaster = caster
	set FadingSparksTarget = target
	call IssuePointOrder(target, "attack", GetUnitX(caster), GetUnitY(caster))
	if GetWidgetLife(target) > BlzGetUnitMaxHP(target) * FADING_SPARKS_HEALTH_THRESHOLD * 0.01 then
		call DisplayTimedTextToPlayer(Player(0), 0.00, 0.00, 4.00, "|cffd45e19The target must be weakened below half health before the rod can extract its essence.|r")
		call ClearFadingSparksState()
		set caster = null
		set target = null
		return
	endif
	set FadingSparksTimer = CreateTimer()
	call TimerStart(FadingSparksTimer, FADING_SPARKS_CHANNEL_TIME, false, function OnFadingSparksTimerExpire)
	set caster = null
	set target = null
endfunction

private function OnFadingSparksSpellFinish takes nothing returns nothing
	local real x
	local real y
	local item essence
	if GetSpellAbilityId() != ABIL_TELANOR_ROD then
		set essence = null
		return
	endif
	if not FadingSparksFinished or FadingSparksCaster == null or FadingSparksTarget == null then
		call ClearFadingSparksState()
		set essence = null
		return
	endif
	set x = GetUnitX(FadingSparksTarget)
	set y = GetUnitY(FadingSparksTarget)
	call UnitDamageTarget(FadingSparksCaster, FadingSparksTarget, FADING_SPARKS_DAMAGE, true, false, ATTACK_TYPE_MAGIC, DAMAGE_TYPE_NORMAL, WEAPON_TYPE_WHOKNOWS)
	if QuestGiver_IsUnitAlive(FadingSparksTarget) then
		call KillUnit(FadingSparksTarget)
	endif
	set essence = CreateItem(ITEM_WRAITH_ESSENCE, x, y)
	if essence != null then
		call ItemLoot_CreateFloatingTextCustom(essence, GetItemName(essence), 255, 255, 255)
	endif
	call ClearFadingSparksState()
	set essence = null
endfunction

private function OnFadingSparksSpellEndCast takes nothing returns nothing
	if GetSpellAbilityId() != ABIL_TELANOR_ROD then
		return
	endif
	call ClearFadingSparksState()
endfunction

private function RegisterFadingSparksSpellTriggers takes nothing returns nothing
	local integer i = 0
	if FadingSparksSpellEffectTrigger != null or FadingSparksSpellFinishTrigger != null or FadingSparksSpellEndCastTrigger != null then
		return
	endif
	set FadingSparksSpellEffectTrigger = CreateTrigger()
	set FadingSparksSpellFinishTrigger = CreateTrigger()
	set FadingSparksSpellEndCastTrigger = CreateTrigger()
	loop
		exitwhen i >= bj_MAX_PLAYER_SLOTS
		call TriggerRegisterPlayerUnitEvent(FadingSparksSpellEffectTrigger, Player(i), EVENT_PLAYER_UNIT_SPELL_EFFECT, null)
		call TriggerRegisterPlayerUnitEvent(FadingSparksSpellFinishTrigger, Player(i), EVENT_PLAYER_UNIT_SPELL_FINISH, null)
		call TriggerRegisterPlayerUnitEvent(FadingSparksSpellEndCastTrigger, Player(i), EVENT_PLAYER_UNIT_SPELL_ENDCAST, null)
		set i = i + 1
	endloop
	call TriggerAddAction(FadingSparksSpellEffectTrigger, function OnFadingSparksSpellEffect)
	call TriggerAddAction(FadingSparksSpellFinishTrigger, function OnFadingSparksSpellFinish)
	call TriggerAddAction(FadingSparksSpellEndCastTrigger, function OnFadingSparksSpellEndCast)
endfunction

private function OnRiftsValeriaDamaged takes nothing returns nothing
	if not RiftsQuestActive or RiftsFailureInProgress or Valeria == null then
		return
	endif
	if GetEventDamage() < GetWidgetLife(Valeria) - 0.41 then
		return
	endif
	call BlzSetEventDamage(GetWidgetLife(Valeria) - 1.00)
	set RiftsFailedUnit = Valeria
	if RiftsRitualActive then
		call HandleRiftsFailure("Valeria fell during the ritual.")
	else
		call HandleRiftsFailure("Valeria has died.")
	endif
endfunction

private function OnRiftsAradionDamaged takes nothing returns nothing
	if not RiftsQuestActive or RiftsFailureInProgress or Aradion == null then
		return
	endif
	if GetEventDamage() < GetWidgetLife(Aradion) - 0.41 then
		return
	endif
	call BlzSetEventDamage(GetWidgetLife(Aradion) - 1.00)
	set RiftsFailedUnit = Aradion
	if RiftsRitualActive then
		call HandleRiftsFailure("Aradion fell during the ritual.")
	else
		call HandleRiftsFailure("Aradion has died.")
	endif
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
	call QuestGiver_BeginDialogSequence()
endfunction

private function SyncRangerMissingReadyTurnIn takes nothing returns nothing
	local real vx
	local real vy
	local QuestData q
	call SyncUnitReferences()
	if not RangerMissingEscortActive then
		return
	endif
	if QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) != QUEST_STATE_READY_TURNIN then
		return
	endif
	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call q.setRequirement(2, "Speak with Aradion The Farseer")
		call q.updateRequirementText(2, "Speak with Aradion The Farseer")
		call q.refreshQuestLog()
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
	call ResetValeriaForRetryAtAmbush()
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
	call QuestGiver_AddHeroLine(seq, hero, "I'll see if I come across her.", "Nazgrek_0337")
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFailQuest1 takes nothing returns nothing
	call BeginQuestDialogSequence()
	call FailRangerMissingForRetry("Valeria was lost.")
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest1FadeHomeReturn takes nothing returns nothing
	local timer t = GetExpiredTimer()
	call ExecuteFunc("qAradion_RecreateValeriaAtHomePublic")
	if t != null then
		call DestroyTimer(t)
	endif
	set t = null
endfunction

private function OnCompleteQuest1End takes nothing returns nothing
	local timer t
	call StopRangerMissingEscortInternal()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	call StartExitFadeOut()
	set t = CreateTimer()
	call TimerStart(t, 1.00, false, function OnCompleteQuest1FadeHomeReturn)
endfunction

private function OnCompleteQuest1 takes nothing returns nothing
	local integer seq
	local unit hero
	local QuestData q
	
	if Valeria == null or not UnitAlive(Valeria) then
		call BJDebugMsg("[qAradion] ERROR: Cannot complete quest - Valeria is null or dead!")
		call EnableUserControl(true)
		return
	endif
	
	call BeginQuestDialogSequence()
	
	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirementCompleted(q.id, 2, true)
	endif

	call StopRangerMissingEscortInternal()
	call SetUnitOwner(Valeria, Player(VALERIA_FRIENDLY_OWNER), true)
	call SetUnitCreepGuard(Valeria, false)
	call PlaceValeriaNearAradion(200.00)
	call IssueImmediateOrder(Valeria, "stop")
	
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest1End)
	set hero = ResolveDialogHero()
	if Aradion != null and Valeria != null then
		call ForceUnitsFaceEachOther(Aradion, Valeria)
	endif
	if hero != null and Aradion != null then
		call ForceUnitsFaceEachOther(hero, Aradion)
	endif
	
	if hero != null and Valeria != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
	endif
	call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, Valeria, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Aradion… It is you! I thought I'd never see you again.", "Valeria_0023", true)
	if hero != null and Aradion != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Aradion, 0.75, 0.0)
	endif
	call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria? By the stars… you yet live!", "Aradion_0031", true)
	call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I feared that I had lost you… forgive me for losing hope.", "Aradion_0032", true)
	if hero == Nazgrek then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
		call DialogSystem_AddDelay(seq, 1.00)
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "This orc… he spoke your name, my love. It is the only reason I followed him.", "Valeria_0024", true)
	else
		if hero != null then
			call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
			call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
			call DialogSystem_AddDelay(seq, 1.00)
		endif
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "This outsider… spoke your name, my love. It is the only reason I followed.", "", true)
	endif
	if hero != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, hero, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Aradion, 0.75, 0.0)
		call DialogSystem_AddDelay(seq, 2.00)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Then I was right. You are no foe, but a seeker.", "Aradion_0033", true)
	call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, Valeria, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "You have given me back my heart, shaman. For this… I owe you more than I can say.", "Aradion_0034", true)
	if hero == Nazgrek then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, hero, 0.75, 0.0)
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "…Do not think this earns my trust fully, orc. But… for Aradion's sake, I'm giving you a chance.", "Valeria_0025", true)
	else
		if hero != null then
			call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
			call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
			call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, hero, 0.75, 0.0)
		endif
		call DialogSystem_AddLine(seq, Valeria, "Valeria", "…Do not think this earns my trust fully. But for Aradion's sake, I'm giving you a chance.", "", true)
	endif
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

public function StartDirectRangerMissingTurnInPublic takes nothing returns nothing
	call OnCompleteQuest1()
endfunction

private function OnAcceptQuest2End takes nothing returns nothing
	local QuestData q
	set AradionLastAcceptedQuest = ARADION_QID_CRYSTALS
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
	set q = QuestGiver_GetByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion)
	if q != 0 then
		call QuestGiver_RefreshItemRequirementsForQuest(q.id)
	endif
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
	call QuestGiver_AddHeroLookAtLine(seq, hero, Aradion, "I have walked near them. Their song is some what… twisted, yet beautiful.", "Nazgrek_0366")
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
	call QuestGiver_AddHeroLookAtLine(seq, hero, Aradion, "I can hear the spirits whisper caution. These crystals may feed hunger, not heal it.", "Nazgrek_0367")
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I must study these shards you brought me… very carefully", "Aradion_0050", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest3End takes nothing returns nothing
	local unit hero
	local QuestData q
	set AradionLastAcceptedQuest = ARADION_QID_FADING
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
	set q = QuestGiver_GetByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
	if q != 0 then
		call QuestGiver_RefreshItemRequirementsForQuest(q.id)
	endif
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
	call QuestGiver_AddHeroLine(seq, hero, "I will do this Aradion, but I see little hope in the shadows.", "Nazgrek_0371")
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
	call QuestGiver_AddHeroLine(seq, hero, "Do not surrender to despair, Aradion. There may yet be an answer to all of it.", "Nazgrek_0372")
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
	set RiftsFailureInProgress = false
	set RiftsFailedUnit = null
	set RiftsFailureSurvivor = null
	set RiftsPendingFailReason = ""
	set RiftsUnitTypeIds[1] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[2] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[3] = UNIT_MANA_RIFT
	call StopRiftsFailResetTimer()
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	call ResetRiftsClosedState()
	call RegisterRiftUnits()
	if Aradion != null then
		call SetUnitInvulnerable(Aradion, false)
	endif
	if Valeria != null then
		call SetUnitInvulnerable(Valeria, false)
	endif
	call EnableRiftsFailTriggers()
	call StopValeriaPatrolInternal()
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
	call PrepareValeriaForRiftsIntro(hero)
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The ancient pools of magic around the Vanguard Vale and Elarindor once flowed pure, binding our people to life and light.", "Aradion_0065", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now they are transformed.... distorted by implosion of the mana hunger.... And in those rift-like pools, the wraiths are born anew.", "Aradion_0066", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria and I will attempt to seal these rifts. It is perilous work, and we don't truly know what we are dealing with. I've begin to think that I should do this alone…", "Aradion_0067", true)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddLookAtUnit(seq, Valeria, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "We have planned this forever… I can handle it, my love. ", "Valeria_0060", true)
	call QuestGiver_AddHeroLine(seq, hero, "The spirits whisper of broken currents here. I will see Valeria through this.", "Nazgrek_0377")
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
	set RiftsFailureInProgress = false
	set RiftsFailedUnit = null
	set RiftsFailureSurvivor = null
	set RiftsPendingFailReason = ""
	call StopRiftsFailResetTimer()
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	call DisableRiftsFailTriggers()
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call IssueImmediateOrder(Aradion, "stop")
		call UnitRemoveAbility(Aradion, ABIL_RIFT_CLOSE)
	endif
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
	call QuestGiver_AddHeroLine(seq, hero, "The wound in the land is remedied… for now.", "Nazgrek_0378")
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

	if CanOfferRangerMissing() then
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_RANGER_MISSING, Aradion, 2, function OnAcceptQuest1, true, true)
	endif
	// Completion is triggered directly from Aradion selection once Valeria is escorted home.

	call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_CRYSTALS_HOPE, Aradion, 5, function OnAcceptQuest2, true, false)
	call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_CRYSTALS_HOPE, Aradion, 6, function OnCompleteQuest2, true)

	call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_FADING_SPARKS, Aradion, 7, function OnAcceptQuest3, true, false)
	call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_FADING_SPARKS, Aradion, 8, function OnCompleteQuest3, true)

	call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_RIFTS_CORRUPTION, Aradion, 9, function OnAcceptQuest4, true, true)
	if RiftsReturnedHome and QuestGiver_IsUnitAlive(Aradion) and QuestGiver_IsUnitAlive(Valeria) then
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_RIFTS_CORRUPTION, Aradion, 10, function OnCompleteQuest4, false)
	endif

	// Test quests (simple accept/complete with auto-discovery)
	if ENABLE_TEST_QUESTS then
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_KILL, Aradion, 11, function OnAcceptTestKill, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_KILL, Aradion, 12, function OnCompleteTestKill, false)
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_TALKTO, Aradion, 13, function OnAcceptTestTalkTo, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_TALKTO, Aradion, 14, function OnCompleteTestTalkTo, false)
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_FINDNPC, Aradion, 15, function OnAcceptTestFindNPC, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_FINDNPC, Aradion, 16, function OnCompleteTestFindNPC, false)
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_GOTO, Aradion, 17, function OnAcceptTestGoTo, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_GOTO, Aradion, 18, function OnCompleteTestGoTo, false)
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_REPUTATION, Aradion, 19, function OnAcceptTestReputation, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_REPUTATION, Aradion, 20, function OnCompleteTestReputation, false)
		call QuestGiver_AddAvailableQuestAcceptButton(AradionDialog, QUEST_TEST_INVESTIGATE, Aradion, 21, function OnAcceptTestInvestigate, false, false)
		call QuestGiver_AddReadyQuestCompleteButton(AradionDialog, QUEST_TEST_INVESTIGATE, Aradion, 22, function OnCompleteTestInvestigate, false)
	endif

	set b = DialogSystem_AddFarewellButton(AradionDialog)
	call DialogSystem_BindButtonCode(b, function OnFarewell)
	set b = null
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
private function ShouldDirectCompleteRangerMissing takes nothing returns boolean
	return QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_READY_TURNIN and QuestGiver_IsUnitAlive(Valeria)
endfunction

private function ContinueToDialogInternal takes nothing returns nothing
	local unit hero = SelectedHero
	call SyncUnitReferences()
	call SyncRangerMissingReadyTurnIn()

	if ShouldDirectCompleteRangerMissing() then
		call ExecuteFunc("qAradion_StartDirectRangerMissingTurnInPublic")
		return
	endif
	
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
	if RiftsRitualActive then
		call DebugMsg("Select gate blocked: rift ritual active")
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
	call QuestGiver_ApplyQuestMetadata(q, "Ranger Missing", "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp", "Find Valeria somewhere in Vanguard Vale or Verdant Plains.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	set availabilityCondition = CreateTrigger()
	call TriggerAddCondition(availabilityCondition, Condition(function CanOfferRangerMissing))
	call q.setCustomCondition(availabilityCondition)
	call QuestGiver_SetRequirements(q.id, "", "Find Valeria", "", "", "", "", "", "", "")

	set q = QuestGiver_CreateQuest(QUEST_CRYSTALS_HOPE, Aradion, "normal", 18, null)
	call QuestGiver_ApplyQuestMetadata(q, "Crystals of Hope", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp", "Aradion wants to study the mana crystals that can be found anywhere in Vanguard Vale.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Mana Crystals
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_MANA_CRYSTAL, 6)

	set q = QuestGiver_CreateQuest(QUEST_FADING_SPARKS, Aradion, "normal", 18, null)
	call QuestGiver_ApplyQuestMetadata(q, "Fading Sparks", "ReplaceableTextures\\CommandButtons\\BTNHeartOfAszune.blp", "Aradion wants you to gather essences from the wraiths wandering around the Vanguard Vale. Use provided |cffffff00Tel'anor Rod|r when the wraith is at half health.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Wraith Essences
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_WRAITH_ESSENCE, 10)

	set q = QuestGiver_CreateQuest(QUEST_RIFTS_CORRUPTION, Aradion, "normal", 18, null)
	call QuestGiver_ApplyQuestMetadata(q, "Rifts of Corruption", "ReplaceableTextures\\CommandButtons\\BTNDizzy.blp", "Find all rifts scattered around the Vanguard Vale and escort Valeria and Aradion to them. Guard Aradion while he will close the rifts. Both Aradion and Valeria must stay alive.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.addRequiredCompletedQuest(QUEST_RANGER_MISSING, Aradion)
	call q.addRequiredCompletedQuest(QUEST_CRYSTALS_HOPE, Aradion)
	call q.addRequiredCompletedQuest(QUEST_FADING_SPARKS, Aradion)
	call QuestGiver_SetRequirements(q.id, "", "Find all rifts scattered around the Vanguard Vale", "Rifts closed 0 / 3", "Guard Aradion while he closes the rifts", "Both Aradion and Valeria must stay alive", "", "", "", "")

	if ENABLE_TEST_QUESTS then
		// Test Quest 1: Kill
		set q = QuestMaster_TemplateKill(QUEST_TEST_KILL, Aradion, "normal", 1, 'ngno', 3)
		call QuestGiver_RegisterUnitKillRequirement(q.id, Aradion, 1, 'ngno', 3)
		call QuestGiver_ApplyQuestMetadata(q, "Test: Kill Quest", "ReplaceableTextures\\CommandButtons\\BTNFootman.blp", "Test quest for killing units.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 2: Talk To
		set q = QuestMaster_TemplateTalkTo(QUEST_TEST_TALKTO, Aradion, "normal", 1, "Valeria")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Talk To Quest", "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp", "Test quest for talking to NPC.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 3: Find NPC
		set q = QuestMaster_TemplateFindNPC(QUEST_TEST_FINDNPC, Aradion, "normal", 1, "Valeria")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Find NPC Quest", "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.blp", "Test quest for finding an NPC.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 4: Go To Place
		set q = QuestMaster_TemplateGoToPlace(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Go To Place Quest", "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp", "Test quest for going to a location.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 5: Reputation
		set q = QuestMaster_TemplateReputation(QUEST_TEST_REPUTATION, Aradion, "normal", 1, "Elarindor", "Friendly")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Reputation Quest", "ReplaceableTextures\\CommandButtons\\BTNTome.blp", "Test quest for reputation gain.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 500, false)
		
		// Test Quest 6: Investigate
		set q = QuestMaster_TemplateInvestigate(QUEST_TEST_INVESTIGATE, Aradion, "normal", 1, "the strange ruins near the Vale")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Investigate Quest", "ReplaceableTextures\\CommandButtons\\BTNAncientRelic.blp", "Test quest for investigating.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call q.setRewardParams(true, 0, true, 50, false, 0, true, 100, false)
	endif

	set availabilityCondition = null
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
	set AradionHomeOwner = GetOwningPlayer(Aradion)
	set PlacedManaRifts[1] = gg_unit_n023_0971
	set PlacedManaRifts[2] = gg_unit_n023_1093
	set PlacedManaRifts[3] = gg_unit_n023_1092
	set RiftsUnitTypeIds[1] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[2] = UNIT_MANA_RIFT
	set RiftsUnitTypeIds[3] = UNIT_MANA_RIFT
	call DebugMsg("Init Aradion giver id=" + I2S(GetHandleId(Aradion)))
	call QuestGiver_Register(Aradion)
	call QuestGiver_SetGreetOrder(Aradion, QUESTGIVER_GREET_NAZGREK_THEN_NPC)
	call RegisterLines()
	call RegisterValeriaEncounterProximityTrigger()
	call RegisterRiftUnits()
	call RegisterFadingSparksSpellTriggers()
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

public function RefreshRespawnedUnitHooks takes nothing returns nothing
	call SyncUnitReferences()
	if Aradion != null then
		call QuestGiver_RegisterSelectionHandler(Aradion, function OnSelected)
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif
	call RegisterValeriaEncounterProximityTrigger()
	if RiftsQuestActive and not RiftsFailureInProgress then
		call EnableRiftsFailTriggers()
		call RegisterRiftUnits()
	endif
endfunction

public function RecreateValeriaAtHomePublic takes nothing returns nothing
	call RecreateValeriaAtHome()
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
	local integer i = 0
	local unit hero
	call SyncUnitReferences()
	if not RiftsQuestActive then
		set riftUnit = null
		return
	endif
	if RiftsRitualActive or RiftsAwaitingReturnHome or RiftsFailureInProgress then
		set riftUnit = null
		return
	endif
	set hero = GetAllowedRiftHeroInRange(riftUnit)
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	set i = GetRiftIndexForUnit(riftUnit)
	if i > 0 then
		if hero != null and GetTriggeredRiftIndex(hero) == i and IsUnitNearRiftIndex(Aradion, i) then
			set riftUnit = EnsureRiftUnit(i)
			if riftUnit != null then
				call StartRiftsRitualInternal(riftUnit, i, hero)
			endif
			set hero = null
			set riftUnit = null
			return
		endif
	endif
	if not TryStartRiftsRitualForHero(hero) then
		if ALLOW_NAZGREK and Nazgrek != null then
			call TryStartRiftsRitualForHero(Nazgrek)
		endif
		if not RiftsRitualActive and ALLOW_ZULKIS and udg_Zulkis != null then
			call TryStartRiftsRitualForHero(udg_Zulkis)
		endif
	endif
	set hero = null
	set riftUnit = null
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
	set RiftsFailureInProgress = false
	set RiftsFailedUnit = null
	set RiftsFailureSurvivor = null
	set RiftsPendingFailReason = ""
	call StopRiftsFailResetTimer()
	call StopRiftsRuntimeTimers()
	call StopRiftsFieldMonitor()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	call DisableRiftsFailTriggers()
	call DestroyRiftsProximityTrigger()
	call ReturnRiftsCompanionsHomeInternal()
endfunction

public function GetRiftsCorruptionCounter takes nothing returns integer
	return RiftsCorruptionCounter
endfunction

public function ResetRiftsCorruptionCounter takes nothing returns nothing
	set RiftsCorruptionCounter = 0
endfunction

endlibrary
