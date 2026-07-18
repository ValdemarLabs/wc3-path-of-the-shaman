library qAradion initializer Init requires QuestGiver, QuestMaster, DialogSystem, FollowSystem, PatrolSystem, UnitSpawn, Companions, IconQuery, ItemLootSystem, ZonesCore, Reputation, CreepRespawn, VoicelinesAradion, VoicelinesValeria, VoicelinesNazgrek
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
	private constant integer ITEM_TELANOR_ROD = 'i013'
	private constant integer ITEM_TELANOR_ROD_LEGACY = 'I013'
	private constant integer ABIL_TELANOR_ROD = 'A04W'
	private constant integer ABIL_RIFT_CLOSE = 'A04Z'
	private constant integer UNIT_VALERIA = 'n01W'
	private constant integer UNIT_MANA_WRAITH = 'n002' // Mana Wraith
	private constant integer UNIT_MANA_RIFT = 'n023'
	private constant integer UNIT_FADING_SPARKS_WRAITH_2 = 'n028' // Mana Devourer
	private constant integer UNIT_FADING_SPARKS_WRAITH_3 = 'n027' // Mana Spawn
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
	private constant integer LEFT_BEHIND_PING_TICKS = 3
	private constant integer LEFT_BEHIND_PING_STYLE = bj_MINIMAPPINGSTYLE_SIMPLE
	private constant integer LEFT_BEHIND_PING_RED = 255
	private constant integer LEFT_BEHIND_PING_GREEN = 255
	private constant integer LEFT_BEHIND_PING_BLUE = 0
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
	private constant integer REDWIND_PASS_ZONE_ID = 1703
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
	private constant real RIFTS_DIALOG_UNIT_RANGE = 500.00
	private constant real RIFTS_INTRO_VALERIA_OFFSET = 2200.00
	private constant real RANGER_VALERIA_BARK_MIN_DELAY = 18.00
	private constant real RANGER_VALERIA_BARK_MAX_DELAY = 34.00
	private constant real RANGER_VALERIA_BARK_BLOCKED_RETRY_DELAY = 5.00
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
	private boolean CompanionCommandBridgeRegistered = false
	private boolean ValeriaEncounterActive = false
	private boolean ValeriaEncounterResolved = false
	private boolean AradionInitWaitingLogged = false
	private boolean RangerMissingFailureInProgress = false
	private integer AradionLastAcceptedQuest = 0
	private rect RangerMissingEscortDestination = null
	private trigger RangerMissingValeriaDeathTrigger = null
	private trigger RangerMissingValeriaGlobalDeathTrigger = null
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
	private timer RangerMissingValeriaBarkTimer = null
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
	private boolean RiftsLeftFieldZoneNotified = false
	private boolean RiftsHasEnteredFieldZone = false
	private boolean RiftsRitualActive = false
	private trigger RiftsProximityTrigger = null
	private trigger FadingSparksSpellEffectTrigger = null
	private trigger FadingSparksSpellFinishTrigger = null
	private trigger FadingSparksSpellEndCastTrigger = null
	private unit RiftsCurrentRift = null
	private unit FadingSparksRodHero = null
	private unit FadingSparksCaster = null
	private unit FadingSparksTarget = null
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
	private minimapicon RiftsValeriaLeftBehindIcon = null
	private minimapicon RiftsAradionLeftBehindIcon = null
	private integer RiftsValeriaLeftBehindPingCycle = 0
	private integer RiftsAradionLeftBehindPingCycle = 0

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

private function GetPlayerQuestHero takes unit preferredHero returns unit
	call SyncUnitReferences()
	if preferredHero != null and QuestGiver_IsUnitAlive(preferredHero) then
		return preferredHero
	endif
	if SelectedHero != null and QuestGiver_IsUnitAlive(SelectedHero) then
		return SelectedHero
	endif
	if ALLOW_NAZGREK and Nazgrek != null and QuestGiver_IsUnitAlive(Nazgrek) then
		return Nazgrek
	endif
	if ALLOW_NAZGREK and udg_Nazgrek != null and QuestGiver_IsUnitAlive(udg_Nazgrek) then
		return udg_Nazgrek
	endif
	if ALLOW_ZULKIS and udg_Zulkis != null and QuestGiver_IsUnitAlive(udg_Zulkis) then
		return udg_Zulkis
	endif
	return null
endfunction

private function ResolveDialogHero takes nothing returns unit
	local unit hero = QuestGiver_ResolveDialogHero(SelectedHero, Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	if hero == null then
		set hero = GetPlayerQuestHero(null)
	endif
	return hero
endfunction

private function GetAradionFieldZoneListText takes nothing returns string
	return "Vanguard Vale, Verdant Plains, or Redwind Pass"
endfunction

private function GetFindValeriaFieldText takes nothing returns string
	return "Find Valeria in " + GetAradionFieldZoneListText()
endfunction

private function GetRiftsFieldObjectiveText takes nothing returns string
	return "Find all rifts scattered around " + GetAradionFieldZoneListText()
endfunction

private function GetRiftsReturnToFieldObjectiveText takes nothing returns string
	return "Return to " + GetAradionFieldZoneListText() + " to continue escorting Aradion and Valeria"
endfunction

private function GetRiftsReturnHomeObjectiveText takes nothing returns string
	return "Escort Aradion and Valeria to Aradion's place"
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
	if zoneId == REDWIND_PASS_ZONE_ID then
		return true
	endif
	return ZonesCore_IsChildZoneOf(zoneId, VERDANT_PLAINS_ZONE_ID)
endfunction

private function GetRiftsTrackingHero takes nothing returns unit
	local unit hero = GetPlayerQuestHero(null)
	if hero == null then
		set hero = ResolveDialogHero()
	endif
	return hero
endfunction

private function CanOfferRangerMissing takes nothing returns boolean
	return AradionBackstorySeen
endfunction

private function IsElarindorHostileForRifts takes nothing returns boolean
	local Faction f = Faction.getFaction("Elarindor")
	if Reputation_IsFactionTemporarilyHostile("Elarindor") then
		return true
	endif
	if f == 0 then
		return false
	endif
	return Reputation.getRep(Player(0), f) < Reputation_REP_UNFRIENDLY
endfunction

private function IsElarindorTemporarilyHostile takes nothing returns boolean
	return Reputation_IsFactionTemporarilyHostile("Elarindor")
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
		if Companions_IsControlled(follower) then
			call Companions_Suspend(follower)
		endif
	endif
endfunction

private function GetAradionHomeOwner takes nothing returns player
	if AradionHomeOwner != null then
		return AradionHomeOwner
	endif
	return Player(VALERIA_HOME_OWNER)
endfunction

private function RestoreValeriaFieldOwner takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitOwner(Valeria, Player(VALERIA_HOME_OWNER), true)
	endif
endfunction

private function RestoreAradionFieldOwner takes nothing returns nothing
	local player ownerP
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		set ownerP = GetAradionHomeOwner()
		call SetUnitOwner(Aradion, ownerP, true)
	endif
	set ownerP = null
endfunction

private function ClearRiftsLeftBehindUnitIcon takes boolean valeriaIcon returns nothing
	if valeriaIcon then
		if RiftsValeriaLeftBehindIcon != null then
			call IconQuery_UnregisterIcon(RiftsValeriaLeftBehindIcon)
			set RiftsValeriaLeftBehindIcon = null
		endif
		set RiftsValeriaLeftBehindPingCycle = 0
	else
		if RiftsAradionLeftBehindIcon != null then
			call IconQuery_UnregisterIcon(RiftsAradionLeftBehindIcon)
			set RiftsAradionLeftBehindIcon = null
		endif
		set RiftsAradionLeftBehindPingCycle = 0
	endif
endfunction

private function ClearRiftsLeftBehindIcons takes nothing returns nothing
	call ClearRiftsLeftBehindUnitIcon(true)
	call ClearRiftsLeftBehindUnitIcon(false)
endfunction

private function EnsureRiftsLeftBehindUnitIcon takes unit leftUnit, boolean valeriaIcon returns nothing
	if leftUnit == null then
		return
	endif
	if valeriaIcon then
		if RiftsValeriaLeftBehindIcon == null then
			set RiftsValeriaLeftBehindIcon = IconQuery_RegisterCompanionFollowerUnitIcon(leftUnit)
		endif
	else
		if RiftsAradionLeftBehindIcon == null then
			set RiftsAradionLeftBehindIcon = IconQuery_RegisterCompanionFollowerUnitIcon(leftUnit)
		endif
	endif
endfunction

private function PingRiftsLeftBehindUnitIfReady takes unit leftUnit, boolean valeriaIcon returns nothing
	local integer cycles
	local location pingLoc
	if leftUnit == null then
		return
	endif
	if valeriaIcon then
		set cycles = RiftsValeriaLeftBehindPingCycle + 1
	else
		set cycles = RiftsAradionLeftBehindPingCycle + 1
	endif
	if cycles >= LEFT_BEHIND_PING_TICKS then
		set pingLoc = Location(GetUnitX(leftUnit), GetUnitY(leftUnit))
		call PingMinimapLocForForceEx(GetPlayersAll(), pingLoc, 1.00, LEFT_BEHIND_PING_STYLE, LEFT_BEHIND_PING_RED, LEFT_BEHIND_PING_GREEN, LEFT_BEHIND_PING_BLUE)
		call RemoveLocation(pingLoc)
		set pingLoc = null
		set cycles = 0
	endif
	if valeriaIcon then
		set RiftsValeriaLeftBehindPingCycle = cycles
	else
		set RiftsAradionLeftBehindPingCycle = cycles
	endif
endfunction

private function UpdateRiftsLeftBehindUnitIcon takes unit leftUnit, unit hero, boolean valeriaIcon returns nothing
	if leftUnit == null or hero == null or not QuestGiver_IsUnitAlive(leftUnit) or not QuestGiver_IsUnitAlive(hero) then
		call ClearRiftsLeftBehindUnitIcon(valeriaIcon)
		return
	endif
	if QuestGiver_IsWithinRange(leftUnit, hero, FOLLOW_MAX_DISTANCE) then
		call ClearRiftsLeftBehindUnitIcon(valeriaIcon)
		return
	endif
	call EnsureRiftsLeftBehindUnitIcon(leftUnit, valeriaIcon)
	call PingRiftsLeftBehindUnitIfReady(leftUnit, valeriaIcon)
endfunction

private function UpdateRiftsLeftBehindIcons takes nothing returns nothing
	local unit hero = GetRiftsTrackingHero()
	call UpdateRiftsLeftBehindUnitIcon(Valeria, hero, true)
	call UpdateRiftsLeftBehindUnitIcon(Aradion, hero, false)
	set hero = null
endfunction

private function AddValeriaCompanion takes nothing returns nothing
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call SetUnitOwner(Valeria, Player(VALERIA_FRIENDLY_OWNER), true)
		call SetUnitCreepGuard(Valeria, false)
		call QuestGiver_AddCompanion(Valeria, VALERIA_COMPANION_ICON)
		call Companions_Add(Valeria, VALERIA_COMPANION_ICON, null, COMPANION_MODE_DEFEND)
		set ValeriaCompanionActive = true
	endif
endfunction

private function RemoveValeriaCompanion takes nothing returns nothing
	call StopFollow(Valeria)
	if Valeria != null then
		call Companions_Remove(Valeria)
		call RestoreValeriaFieldOwner()
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
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call SetUnitOwner(Aradion, Player(VALERIA_FRIENDLY_OWNER), true)
		call SetUnitCreepGuard(Aradion, false)
		call QuestGiver_AddCompanion(Aradion, ARADION_COMPANION_ICON)
		call Companions_Add(Aradion, ARADION_COMPANION_ICON, null, COMPANION_MODE_DEFEND)
		set AradionCompanionActive = true
	endif
endfunction

private function RemoveAradionCompanion takes nothing returns nothing
	call StopFollow(Aradion)
	if Aradion != null then
		call Companions_Remove(Aradion)
		call RestoreAradionFieldOwner()
	endif
	set AradionCompanionActive = false
endfunction

private function IsRiftsFieldCompanionStateBroken takes nothing returns boolean
	if ValeriaCompanionActive and (Valeria == null or not QuestGiver_IsUnitAlive(Valeria) or not Companions_IsControlled(Valeria)) then
		return true
	endif
	if AradionCompanionActive and (Aradion == null or not QuestGiver_IsUnitAlive(Aradion) or not Companions_IsControlled(Aradion)) then
		return true
	endif
	return false
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
	call SyncUnitReferences()
	if hero == null then
		set hero = GetRiftsTrackingHero()
	endif
	if hero == null then
		call BJDebugMsg("[qAradion] ERROR: Rifts companions could not join because no valid player hero was resolved.")
		return
	endif
	call ClearRiftsLeftBehindIcons()
	set RiftsLeftFieldZoneNotified = false
	call AddValeriaCompanion()
	call AddAradionCompanion()
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call Companions_SetFollowerBehavior(Valeria, true)
		call Companions_SetMode(Valeria, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Valeria, hero)
		call Companions_Resume(Valeria)
	endif
	if Aradion != null and QuestGiver_IsUnitAlive(Aradion) then
		call Companions_SetFollowerBehavior(Aradion, true)
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

private function StopRangerMissingValeriaBarkTimer takes nothing returns nothing
	if RangerMissingValeriaBarkTimer != null then
		call DestroyTimer(RangerMissingValeriaBarkTimer)
		set RangerMissingValeriaBarkTimer = null
	endif
endfunction

private function IsRangerMissingValeriaBarkStateActive takes nothing returns boolean
	return RangerMissingEscortActive and ValeriaCompanionActive and Valeria != null and QuestGiver_IsUnitAlive(Valeria) and QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

private function IsRangerMissingValeriaBarkBlocked takes nothing returns boolean
	return udg_InCinematic or DialogSystem_IsSequenceActive() or DialogSystem_IsDialogVisible() or DialogSystem_IsFieldLineQueueActive()
endfunction

private function PlayRangerMissingValeriaBark takes nothing returns nothing
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0021_KEY, VL_VALERIA_0021_TEXT)
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0022_KEY, VL_VALERIA_0022_TEXT)
	endif
endfunction

private function OnRangerMissingValeriaBarkTimer takes nothing returns nothing
	if not IsRangerMissingValeriaBarkStateActive() then
		call StopRangerMissingValeriaBarkTimer()
		return
	endif
	if IsRangerMissingValeriaBarkBlocked() then
		call TimerStart(RangerMissingValeriaBarkTimer, RANGER_VALERIA_BARK_BLOCKED_RETRY_DELAY, false, function OnRangerMissingValeriaBarkTimer)
		return
	endif
	call PlayRangerMissingValeriaBark()
	call TimerStart(RangerMissingValeriaBarkTimer, GetRandomReal(RANGER_VALERIA_BARK_MIN_DELAY, RANGER_VALERIA_BARK_MAX_DELAY), false, function OnRangerMissingValeriaBarkTimer)
endfunction

private function StartRangerMissingValeriaBarkTimer takes nothing returns nothing
	if not IsRangerMissingValeriaBarkStateActive() then
		return
	endif
	call StopRangerMissingValeriaBarkTimer()
	set RangerMissingValeriaBarkTimer = CreateTimer()
	call TimerStart(RangerMissingValeriaBarkTimer, GetRandomReal(RANGER_VALERIA_BARK_MIN_DELAY, RANGER_VALERIA_BARK_MAX_DELAY), false, function OnRangerMissingValeriaBarkTimer)
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
	call StopRangerMissingValeriaBarkTimer()
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
			call QuestGiver_UpdateRequirementText(q.id, 2, GetFindValeriaFieldText())
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
		call q.updateRequirementText(1, GetFindValeriaFieldText())
		call QuestGiver_SetRequirementCompleted(q.id, 2, false)
		call q.updateRequirementText(2, "")
		call q.removeReturnRequirement()
		call q.refreshQuestLog()
	endif
endfunction

private function ResetRangerMissingForValeriaKick takes nothing returns nothing
	local QuestData q

	set RangerMissingReq1Complete = false
	call StopRangerMissingEscortInternal()
	call ClearValeriaEncounterState()
	set ValeriaEncounterResolved = false

	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call q.updateRequirementText(1, GetFindValeriaFieldText())
		call q.markRequirementCompleted(1, false)
		call q.updateRequirementText(2, "")
		call q.markRequirementCompleted(2, false)
		call q.removeReturnRequirement()
		call q.refreshQuestLog()
		call QuestGiver_SetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion, QUEST_STATE_IN_PROGRESS)
		call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80a0ffObjective updated:|r " + GetFindValeriaFieldText() + ".")
	endif
endfunction

private function FailRangerMissingForRetry takes string reason returns nothing
	if RangerMissingFailureInProgress then
		return
	endif
	set RangerMissingFailureInProgress = true
	call StopRangerMissingEscortInternal()
	call QuestGiver_FailQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion, reason)
	call ResetRangerMissingQuestProgress()
	call QuestGiver_SetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion, QUEST_STATE_AVAILABLE)
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	set RangerMissingFailureInProgress = false
endfunction

private function ShouldFailRangerMissingForValeriaDeath takes nothing returns boolean
	local integer state
	if RangerMissingFailureInProgress or Valeria == null then
		return false
	endif
	if not QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		return false
	endif
	set state = QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	return state == QUEST_STATE_IN_PROGRESS or state == QUEST_STATE_READY_TURNIN
endfunction

private function OnRangerMissingValeriaDamaged takes nothing returns nothing
	local real life
	if Valeria == null or not ShouldFailRangerMissingForValeriaDeath() then
		return
	endif
	set life = GetWidgetLife(Valeria)
	if GetEventDamage() < life - 0.41 then
		return
	endif
	if life > 1.00 then
		call BlzSetEventDamage(life - 1.00)
	else
		call BlzSetEventDamage(0.00)
	endif
	call FailRangerMissingForRetry("Valeria was lost.")
endfunction

private function PlayAradionValeriaCompanionDiesLine takes unit dying returns nothing
	local unit survivor = null
	local string text = ""
	local string soundName = ""

	if RiftsQuestActive or RiftsFailureInProgress then
		return
	endif

	if dying == Valeria then
		set survivor = Aradion
		set text = VL_ARADION_0079_TEXT
		set soundName = VL_ARADION_0079_KEY
	elseif dying == Aradion then
		set survivor = Valeria
		set text = VL_VALERIA_0063_TEXT
		set soundName = VL_VALERIA_0063_KEY
	else
		return
	endif

	if survivor != null and QuestGiver_IsUnitAlive(survivor) and QuestGiver_IsWithinRange(survivor, dying, VALERIA_RANGE) then
		call DialogSystem_PlayLine(survivor, QuestGiver_GetUnitDisplayName(survivor), text, soundName, true)
	endif

	set survivor = null
endfunction

private function OnRangerMissingValeriaDeathGlobal takes nothing returns nothing
	local unit dying = GetDyingUnit()
	call SyncUnitReferences()
	call PlayAradionValeriaCompanionDiesLine(dying)
	if dying == Valeria and ShouldFailRangerMissingForValeriaDeath() then
		call FailRangerMissingForRetry("Valeria was lost.")
	endif
	set dying = null
endfunction

private function RegisterRangerMissingValeriaGlobalDeathTrigger takes nothing returns nothing
	local integer i = 0
	if RangerMissingValeriaGlobalDeathTrigger != null then
		return
	endif
	set RangerMissingValeriaGlobalDeathTrigger = CreateTrigger()
	loop
		exitwhen i >= bj_MAX_PLAYER_SLOTS
		call TriggerRegisterPlayerUnitEvent(RangerMissingValeriaGlobalDeathTrigger, Player(i), EVENT_PLAYER_UNIT_DEATH, null)
		set i = i + 1
	endloop
	call TriggerAddAction(RangerMissingValeriaGlobalDeathTrigger, function OnRangerMissingValeriaDeathGlobal)
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

private function RepairRangerMissingEscortRequirements takes QuestData q returns nothing
	if q == 0 then
		return
	endif
	call q.updateRequirementText(1, GetFindValeriaFieldText())
	call q.markRequirementCompleted(1, true)
	call q.setRequirement(2, "Escort Valeria to Aradion")
	call q.updateRequirementText(2, "Escort Valeria to Aradion")
	call q.markRequirementCompleted(2, false)
	call q.removeReturnRequirement()
	call q.refreshQuestLog()
	call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80ff80Objective completed:|r " + GetFindValeriaFieldText() + "\n|cff80a0ffObjective updated:|r Escort Valeria to Aradion.")
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

	set RangerMissingReq1Complete = true

	call UnitRemoveAbility(Valeria, ABIL_VALERIA_GHOST)
	call SetUnitCreepGuard(Valeria, false)
	call RepairRangerMissingEscortRequirements(q)
	call QuestGiver_UnregisterEscortRequirement(q.id, 2)
	call RemoveRangerMissingEscortDestination()
	set ax = GetUnitX(Aradion)
	set ay = GetUnitY(Aradion)
	set RangerMissingEscortDestination = Rect(ax - RANGER_ESCORT_DEST_RADIUS, ay - RANGER_ESCORT_DEST_RADIUS, ax + RANGER_ESCORT_DEST_RADIUS, ay + RANGER_ESCORT_DEST_RADIUS)
	call QuestGiver_RegisterEscortRequirement(q.id, Aradion, 2, Valeria, RangerMissingEscortDestination, "Aradion")
	call QuestGiver_SetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion, QUEST_STATE_IN_PROGRESS)

	set hero = ResolveDialogHero()
	call AddValeriaCompanion()
	call Reputation_ClearFactionTemporalHostility("Elarindor")
	if Valeria != null and QuestGiver_IsUnitAlive(Valeria) then
		call Companions_SetFollowerBehavior(Valeria, true)
		call Companions_SetMode(Valeria, COMPANION_MODE_DEFEND)
		call Companions_SetLeader(Valeria, hero)
		call Companions_Resume(Valeria)
	endif
	call EnableRangerMissingDeathTrigger()
	set RangerMissingEscortActive = true
	call StartRangerMissingValeriaBarkTimer()
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
		return VL_NAZGREK_0344_TEXT
	elseif lineId == 2 then
		return VL_NAZGREK_0345_TEXT
	elseif lineId == 3 then
		return VL_NAZGREK_0346_TEXT
	elseif lineId == 4 then
		return VL_NAZGREK_0347_TEXT
	elseif lineId == 5 then
		return VL_NAZGREK_0348_TEXT
	elseif lineId == 6 then
		return VL_NAZGREK_0349_TEXT
	elseif lineId == 7 then
		return VL_NAZGREK_0350_TEXT
	elseif lineId == 8 then
		return VL_NAZGREK_0351_TEXT
	elseif lineId == 9 then
		return VL_NAZGREK_0352_TEXT
	endif
	return VL_NAZGREK_0353_TEXT
endfunction

private function GetValeriaNegotiationHeroSound takes integer lineId returns string
	if lineId == 1 then
		return VL_NAZGREK_0344_KEY
	elseif lineId == 2 then
		return VL_NAZGREK_0345_KEY
	elseif lineId == 3 then
		return VL_NAZGREK_0346_KEY
	elseif lineId == 4 then
		return VL_NAZGREK_0347_KEY
	elseif lineId == 5 then
		return VL_NAZGREK_0348_KEY
	elseif lineId == 6 then
		return VL_NAZGREK_0349_KEY
	elseif lineId == 7 then
		return VL_NAZGREK_0350_KEY
	elseif lineId == 8 then
		return VL_NAZGREK_0351_KEY
	elseif lineId == 9 then
		return VL_NAZGREK_0352_KEY
	endif
	return VL_NAZGREK_0353_KEY
endfunction

private function GetValeriaNegotiationResponse takes integer lineId returns string
	if lineId == 1 then
		return VL_VALERIA_0005_TEXT
	elseif lineId == 2 then
		return VL_VALERIA_0006_TEXT
	elseif lineId == 3 then
		return VL_VALERIA_0007_TEXT
	elseif lineId == 4 then
		return VL_VALERIA_0008_TEXT
	elseif lineId == 5 then
		return VL_VALERIA_0009_TEXT
	elseif lineId == 6 then
		return VL_VALERIA_0010_TEXT
	elseif lineId == 7 then
		return VL_VALERIA_0011_TEXT
	elseif lineId == 8 then
		return VL_VALERIA_0012_TEXT
	elseif lineId == 9 then
		return VL_VALERIA_0013_TEXT
	endif
	return VL_VALERIA_0014_TEXT
endfunction

private function GetValeriaNegotiationResponseSound takes integer lineId returns string
	if lineId == 1 then
		return VL_VALERIA_0005_KEY
	elseif lineId == 2 then
		return VL_VALERIA_0006_KEY
	elseif lineId == 3 then
		return VL_VALERIA_0007_KEY
	elseif lineId == 4 then
		return VL_VALERIA_0008_KEY
	elseif lineId == 5 then
		return VL_VALERIA_0009_KEY
	elseif lineId == 6 then
		return VL_VALERIA_0010_KEY
	elseif lineId == 7 then
		return VL_VALERIA_0011_KEY
	elseif lineId == 8 then
		return VL_VALERIA_0012_KEY
	elseif lineId == 9 then
		return VL_VALERIA_0013_KEY
	endif
	return VL_VALERIA_0014_KEY
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
	call QuestGiver_BeginCinematicSequence(CINEMATIC)
	call QuestGiver_CloseActiveDialog()
	call ExecuteFunc("TasQuestBox_Hide")
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
	call QuestGiver_EndCinematicSequence(CINEMATIC)
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
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0014_TEXT, VL_VALERIA_0014_KEY, true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0015_TEXT, VL_VALERIA_0015_KEY, true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0019_TEXT, VL_VALERIA_0019_KEY, true)
	if hero != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
	endif
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0020_TEXT, VL_VALERIA_0020_KEY, true)
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
	call QuestGiver_BeginCinematicSequence(CINEMATIC)
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
	call QuestGiver_EndCinematicSequence(CINEMATIC)
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
	set ValeriaSuccessTransitionApplied = false
	if hero != null then
		set seq = DialogSystem_CreateSequence()
		call DialogSystem_SetSequenceDefaultSpeaker(seq, Valeria, "Valeria")
		call DialogSystem_SetSequenceCallbacks(seq, function BeginValeriaNegotiationSequence, function OnValeriaSuccessLeadInEnd)
		call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0353_TEXT, VL_NAZGREK_0353_KEY)
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
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0001_TEXT, VL_VALERIA_0001_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0340_TEXT, VL_NAZGREK_0340_KEY)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0341_TEXT, VL_NAZGREK_0341_KEY)
	call DialogSystem_AddDelay(seq, 1.50)
	call DialogSystem_AddDelay(seq, 1.00)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0002_TEXT, VL_VALERIA_0002_KEY, true)
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

private function OnCompanionCommand takes nothing returns nothing
	local unit eventUnit = Companions_EventUnit
	local integer rangerState
	local unit hero
	if eventUnit == null then
		set eventUnit = null
		return
	endif

	call SyncUnitReferences()
	if Companions_EventCommand == Companions_COMMAND_KICK and eventUnit == Valeria and IsRangerMissingInProgress() then
		call ResetRangerMissingForValeriaKick()
		call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
		set eventUnit = null
		return
	endif

	if Companions_EventCommand != Companions_COMMAND_INVITE then
		set eventUnit = null
		return
	endif

	if eventUnit == Valeria and IsRangerMissingInProgress() then
		set rangerState = QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
		if rangerState != QUEST_STATE_READY_TURNIN then
			call StartRangerMissingEscortInternal()
			call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
		endif
	endif

	if RiftsQuestActive and IsRiftsCorruptionInProgress() and not RiftsFailureInProgress and (eventUnit == Valeria or eventUnit == Aradion) then
		set hero = GetRiftsTrackingHero()
		call StartFieldCompanions(hero)
		call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	endif

	set hero = null
	set eventUnit = null
endfunction

private function RegisterCompanionCommandBridge takes nothing returns nothing
	if not CompanionCommandBridgeRegistered then
		call Companions_RegisterCommandEvent(function OnCompanionCommand)
		set CompanionCommandBridgeRegistered = true
	endif
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
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0037_TEXT, VL_ARADION_0037_KEY, true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0038_TEXT, VL_ARADION_0038_KEY, true)
		endif
		if GetRandomInt(1, 2) == 1 then
			call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0337_TEXT, VL_NAZGREK_0337_KEY)
		endif
		return true
	endif
	if questId == ARADION_QID_CRYSTALS then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0045_TEXT, VL_ARADION_0045_KEY, true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0046_TEXT, VL_ARADION_0046_KEY, true)
		endif
		return true
	endif
	if questId == ARADION_QID_FADING then
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0057_TEXT, VL_ARADION_0057_KEY, true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0058_TEXT, VL_ARADION_0058_KEY, true)
		endif
		return true
	endif
	if questId == ARADION_QID_RIFTS then
		if RiftsAwaitingReturnHome or RiftsReturnedHome then
			if roll == 1 then
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0085_TEXT, VL_ARADION_0085_KEY, true)
			else
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0084_TEXT, VL_ARADION_0084_KEY, true)
			endif
			return true
		endif
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0069_TEXT, VL_ARADION_0069_KEY, true)
		else
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0070_TEXT, VL_ARADION_0070_KEY, true)
		endif
		return true
	endif
	return false
endfunction

//===========================================================================
// Backstory sequence
//===========================================================================
private function PlayGreetFirstSequence takes unit hero returns nothing
	local integer seq
	set seq = QuestGiver_CreateGreetSequenceBase(Aradion, "Aradion the Farseer", hero, 1.00, 1.00, true)
	
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0001_TEXT, VL_ARADION_0001_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0331_TEXT, VL_NAZGREK_0331_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0002_TEXT, VL_ARADION_0002_KEY, true)
	call QuestGiver_PlayFirstGreetSequenceEx(Aradion, Player(0), AradionDialog, seq, CINEMATIC)
endfunction

private function PlayGreetNormalSequence takes unit hero returns nothing
	local integer seq
	local integer roll
	local boolean handled
	call DebugMsg("PlayGreetNormalSequence: Starting")
	set seq = QuestGiver_CreateGreetSequenceBase(Aradion, "Aradion the Farseer", hero, 1.00, 1.00, true)
	call DebugMsg("PlayGreetNormalSequence: Created sequence, seq=" + I2S(seq))
	set handled = AddInProgressGreet(seq, hero)
	if not handled then
		set roll = GetRandomInt(1, 4)
		if roll == 1 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0020_TEXT, VL_ARADION_0020_KEY, true)
		elseif roll == 2 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0021_TEXT, VL_ARADION_0021_KEY, true)
		elseif roll == 3 then
			call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0022_TEXT, VL_ARADION_0022_KEY, true)
		else
			// Only ask about Valeria if she is in range
			if QuestGiver_IsWithinRange(Aradion, Valeria, VALERIA_RANGE) then
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0023_TEXT, VL_ARADION_0023_KEY, true)
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0024_TEXT, VL_ARADION_0024_KEY, true)
			else
				call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0021_TEXT, VL_ARADION_0021_KEY, true)
			endif
		endif
	endif
	call DebugMsg("PlayGreetNormalSequence: About to call QuestGiver_PlayGreetSequence")
	call QuestGiver_PlayGreetSequenceEx(seq, Aradion, Player(0), AradionDialog, CINEMATIC)
	call DebugMsg("PlayGreetNormalSequence: Completed QuestGiver_PlayGreetSequence call")
endfunction

private function ShowDialog takes player p, unit hero returns nothing
	local boolean wasActive
	local boolean isActiveAfter
	call DebugMsg("ShowDialog: Starting")
	set wasActive = DialogSystem_IsSequenceActive()
	call DebugMsg("ShowDialog: wasActive=" + I2S(B2I(wasActive)))
	call QuestGiver_StartConfiguredDialogCamera(p, Aradion, USE_DIALOG_CAMERA)
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
private function OnInfoStart takes nothing returns nothing
	set AradionBackstorySeen = true
	call QuestGiver_CloseActiveDialog()
	set AradionDialogCooldown = QuestGiver_StartCooldown(AradionDialogCooldown, DIALOG_COOLDOWN)
	call QuestGiver_BeginCinematicSequence(CINEMATIC)
endfunction

private function OnInfoEnd takes nothing returns nothing
	call SyncUnitReferences()
	// Refresh quest state before rebuilding the dialog so Ranger Missing appears immediately.
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif

	// Reopen the dialog on the next tick; a long delay here caused the stale-info flow.
	call QuestGiver_QueueDialogReopen("qAradion_RebuildAndShowDialog", 0.05)
endfunction

private function BuildInfoSequence takes nothing returns integer
	local integer seq
	local unit hero
	local real facing
	local real x
	local real y
	set seq = QuestGiver_CreateInfoSequenceBase(Aradion, "Aradion the Farseer", function OnInfoStart, function OnInfoEnd)

	// Get hero for look-at actions
	set hero = ResolveDialogHero()

	// Calculate ruins position (400 units in front of Aradion)
	if Aradion != null then
		set facing = GetUnitFacing(Aradion) * bj_DEGTORAD
		set x = GetUnitX(Aradion) + 400.00 * Cos(facing)
		set y = GetUnitY(Aradion) + 400.00 * Sin(facing)
	endif

	call DialogSystem_AddLookAtUnit(seq, Aradion, hero, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0003_TEXT, VL_ARADION_0003_KEY, true)
	call DialogSystem_AddMakeUnitFacePoint(seq, Aradion, x, y, 0.25, 0.0)
	call DialogSystem_AddLookAtPoint(seq, Aradion, x, y, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0004_TEXT, VL_ARADION_0004_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0005_TEXT, VL_ARADION_0005_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0006_TEXT, VL_ARADION_0006_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0007_TEXT, VL_ARADION_0007_KEY, true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0332_TEXT, VL_NAZGREK_0332_KEY)
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0333_TEXT, VL_NAZGREK_0333_KEY)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0008_TEXT, VL_ARADION_0008_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0009_TEXT, VL_ARADION_0009_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0010_TEXT, VL_ARADION_0010_KEY, true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0334_TEXT, VL_NAZGREK_0334_KEY)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0011_TEXT, VL_ARADION_0011_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0012_TEXT, VL_ARADION_0012_KEY, true)
	if hero != null then
		call DialogSystem_AddLookAtUnit(seq, hero, Aradion, 0.5)
		call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0336_TEXT, VL_NAZGREK_0336_KEY)
	endif
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0013_TEXT, VL_ARADION_0013_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0014_TEXT, VL_ARADION_0014_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0015_TEXT, VL_ARADION_0015_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0016_TEXT, VL_ARADION_0016_KEY, true)

	set hero = null
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

private function PrepareRiftUnitRuntimeState takes unit riftUnit returns nothing
	if riftUnit == null then
		return
	endif
	call ShowUnit(riftUnit, true)
	call SetUnitCreepGuard(riftUnit, false)
	call CreepRespawn_DiscardUnit(riftUnit)
	set riftUnit = null
endfunction

private function PrepareRiftUnitsRuntimeState takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX
		if RiftsUnits[i] != null and QuestGiver_IsUnitAlive(RiftsUnits[i]) then
			call PrepareRiftUnitRuntimeState(RiftsUnits[i])
		endif
		set i = i + 1
	endloop
endfunction

private function CreateRiftUnitAtSlot takes integer index returns unit
	local rect r = GetRiftRect(index)
	local unit result = null
	local real x
	local real y
	if r == null then
		call BJDebugMsg("[qAradion] ERROR: gg_rct_ManaRift" + I2S(index) + " is null; Mana Rift was not created.")
		return null
	endif
	set x = GetRectCenterX(r)
	set y = GetRectCenterY(r)
	set result = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_MANA_RIFT, x, y, bj_UNIT_FACING)
	if result == null then
		call BJDebugMsg("[qAradion] ERROR: CreateUnit('n023') failed for Mana Rift slot " + I2S(index) + " at gg_rct_ManaRift" + I2S(index) + " (" + R2S(x) + ", " + R2S(y) + ").")
	endif
	set r = null
	return result
endfunction

private function TestSpawnManaRiftSlot takes integer index returns nothing
	local rect r = null
	local unit existing = null
	local unit spawned = null
	local real x = 0.00
	local real y = 0.00
	if index <= 0 or index > RIFTS_MAX then
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": invalid slot.")
		return
	endif
	set existing = RiftsUnits[index]
	if existing != null and QuestGiver_IsUnitAlive(existing) and GetUnitTypeId(existing) == UNIT_MANA_RIFT then
		set RiftsUnitTypeIds[index] = UNIT_MANA_RIFT
		set RiftsClosed[index] = false
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": already alive, handle=" + I2S(GetHandleId(existing)) + ", owner=" + I2S(GetPlayerId(GetOwningPlayer(existing))) + ", pos=(" + R2S(GetUnitX(existing)) + ", " + R2S(GetUnitY(existing)) + ").")
		set existing = null
		return
	endif
	if existing != null then
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": stored unit is not a live Mana Rift, oldType=" + I2S(GetUnitTypeId(existing)) + ". Trying direct CreateUnit.")
	endif
	set r = GetRiftRect(index)
	if r == null then
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": gg_rct_ManaRift" + I2S(index) + " is null.")
		set existing = null
		return
	endif
	set x = GetRectCenterX(r)
	set y = GetRectCenterY(r)
	call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": CreateUnit Neutral Passive 'n023' at gg_rct_ManaRift" + I2S(index) + " center (" + R2S(x) + ", " + R2S(y) + ").")
	set spawned = CreateUnit(Player(PLAYER_NEUTRAL_PASSIVE), UNIT_MANA_RIFT, x, y, bj_UNIT_FACING)
	if spawned == null then
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": CreateUnit returned null.")
	else
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": CreateUnit returned non-null, handle=" + I2S(GetHandleId(spawned)) + ".")
		set RiftsUnits[index] = spawned
		set RiftsUnitTypeIds[index] = UNIT_MANA_RIFT
		set RiftsClosed[index] = false
		call BJDebugMsg("[qAradion] TEST ManaRift" + I2S(index) + ": spawned, handle=" + I2S(GetHandleId(spawned)) + ", owner=" + I2S(GetPlayerId(GetOwningPlayer(spawned))) + ", type=" + I2S(GetUnitTypeId(spawned)) + ", pos=(" + R2S(GetUnitX(spawned)) + ", " + R2S(GetUnitY(spawned)) + ").")
	endif
	set r = null
	set existing = null
	set spawned = null
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
	local unit u = RiftsUnits[index]
	if index <= 0 or index > RIFTS_MAX or RiftsClosed[index] then
		return null
	endif
	if u != null and QuestGiver_IsUnitAlive(u) and GetUnitTypeId(u) == UNIT_MANA_RIFT then
		return u
	endif
	if u != null and GetUnitTypeId(u) != 0 then
		call RemoveUnit(u)
	endif
	set RiftsUnitTypeIds[index] = UNIT_MANA_RIFT
	set u = CreateRiftUnitAtSlot(index)
	set RiftsUnits[index] = u
	return u
endfunction

private function RegisterRiftUnits takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX
		if not RiftsClosed[i] then
			if EnsureRiftUnit(i) == null then
				call BJDebugMsg("[qAradion] ERROR: Mana Rift slot " + I2S(i) + " is missing after register.")
			endif
		else
			set RiftsUnits[i] = null
		endif
		set i = i + 1
	endloop
	call ExecuteFunc("qAradion_RegisterRiftsProximity")
endfunction

private function CreateInitialRiftUnits takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > RIFTS_MAX
		set RiftsUnitTypeIds[i] = UNIT_MANA_RIFT
		set RiftsClosed[i] = false
		if EnsureRiftUnit(i) == null then
			call BJDebugMsg("[qAradion] ERROR: Mana Rift slot " + I2S(i) + " is still null after init creation.")
		endif
		set i = i + 1
	endloop
endfunction

private function PrepareRiftsForQuestDiscovery takes nothing returns nothing
	local integer i = 1
	call ResetRiftsClosedState()
	loop
		exitwhen i > RIFTS_MAX
		set RiftsUnitTypeIds[i] = UNIT_MANA_RIFT
		set i = i + 1
	endloop
	call RegisterRiftUnits()
endfunction

private function PrepareValeriaForRiftsIntro takes unit hero returns nothing
	local real targetX
	local real targetY
	local real startX
	local real startY
	local real angle
	local real sideAngle
	local boolean valeriaAlreadyClose
	if Aradion == null or Valeria == null or not QuestGiver_IsUnitAlive(Aradion) or not QuestGiver_IsUnitAlive(Valeria) then
		set hero = null
		return
	endif
	call PauseUnit(Valeria, false)
	call SetUnitInvulnerable(Valeria, false)
	call StopFollow(Valeria)
	call StopValeriaPatrolInternal()
	set sideAngle = (GetUnitFacing(Aradion) + 90.00) * bj_DEGTORAD
	set targetX = GetUnitX(Aradion) + RIFTS_DIALOG_UNIT_RANGE * Cos(sideAngle)
	set targetY = GetUnitY(Aradion) + RIFTS_DIALOG_UNIT_RANGE * Sin(sideAngle)
	set valeriaAlreadyClose = QuestGiver_IsWithinRange(Aradion, Valeria, RIFTS_DIALOG_UNIT_RANGE)
	if valeriaAlreadyClose then
		call IssuePointOrder(Valeria, "move", targetX, targetY)
		set hero = null
		return
	endif
	if hero != null and QuestGiver_IsUnitAlive(hero) then
		set angle = (GetUnitFacing(hero) + 180.00) * bj_DEGTORAD
		set startX = GetUnitX(hero) + RIFTS_INTRO_VALERIA_OFFSET * Cos(angle)
		set startY = GetUnitY(hero) + RIFTS_INTRO_VALERIA_OFFSET * Sin(angle)
	else
		set angle = (GetUnitFacing(Aradion) + 180.00) * bj_DEGTORAD
		set startX = GetUnitX(Aradion) + RIFTS_INTRO_VALERIA_OFFSET * Cos(angle)
		set startY = GetUnitY(Aradion) + RIFTS_INTRO_VALERIA_OFFSET * Sin(angle)
	endif
	call SetUnitPosition(Valeria, startX, startY)
	call SetUnitFacing(Valeria, bj_RADTODEG * Atan2(targetY - startY, targetX - startX))
	call IssuePointOrder(Valeria, "move", targetX, targetY)
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
			if slotUnit == riftUnit then
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

private function CloseManaRiftUnit takes unit riftUnit returns nothing
	if riftUnit != null and GetUnitTypeId(riftUnit) == UNIT_MANA_RIFT then
		if GetWidgetLife(riftUnit) > 0.405 then
			call KillUnit(riftUnit)
		endif
		call RemoveUnit(riftUnit)
	endif
	set riftUnit = null
endfunction

private function GetRiftEffectX takes unit closedRift, unit slotRift, integer riftIndex returns real
	local rect r
	local real result
	if closedRift != null and GetUnitTypeId(closedRift) != 0 then
		set result = GetUnitX(closedRift)
	elseif slotRift != null and GetUnitTypeId(slotRift) != 0 then
		set result = GetUnitX(slotRift)
	else
		set r = GetRiftRect(riftIndex)
		if r != null then
			set result = GetRectCenterX(r)
		else
			set result = 0.00
		endif
	endif
	set closedRift = null
	set slotRift = null
	set r = null
	return result
endfunction

private function GetRiftEffectY takes unit closedRift, unit slotRift, integer riftIndex returns real
	local rect r
	local real result
	if closedRift != null and GetUnitTypeId(closedRift) != 0 then
		set result = GetUnitY(closedRift)
	elseif slotRift != null and GetUnitTypeId(slotRift) != 0 then
		set result = GetUnitY(slotRift)
	else
		set r = GetRiftRect(riftIndex)
		if r != null then
			set result = GetRectCenterY(r)
		else
			set result = 0.00
		endif
	endif
	set closedRift = null
	set slotRift = null
	set r = null
	return result
endfunction

private function PlayRiftsStartBarks takes nothing returns nothing
	local integer roll
	set roll = GetRandomInt(1, 2)
	if roll == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0074_KEY, VL_ARADION_0074_TEXT)
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0075_KEY, VL_ARADION_0075_TEXT)
	endif
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0072_KEY, VL_VALERIA_0072_TEXT)
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0073_KEY, VL_VALERIA_0073_TEXT)
	endif
endfunction

private function StartRiftsRitualInternal takes unit riftUnit, integer riftIndex, unit hero returns nothing
	if riftUnit == null or not QuestGiver_IsUnitAlive(riftUnit) or Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	if not IsAradionFieldZoneActive() then
		return
	endif
	if IsElarindorHostileForRifts() then
		call DebugMsg("Rift ritual blocked: Elarindor is hostile")
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
		call Companions_SetFollowerBehavior(Valeria, false)
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
	if IsElarindorHostileForRifts() then
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
	local integer registeredCount = 0
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
			set registeredCount = registeredCount + 1
		endif
		set riftUnit = null
		set i = i + 1
	endloop
	call TriggerAddAction(RiftsProximityTrigger, function OnRiftsProximity)
	call PrepareRiftUnitsRuntimeState()
	if registeredCount < RIFTS_MAX then
		call BJDebugMsg("[qAradion] WARNING: Rifts proximity registered " + I2S(registeredCount) + " / " + I2S(RIFTS_MAX) + " Mana Rift units.")
	endif
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
	call ClearRiftsLeftBehindIcons()
endfunction

private function StopRiftsFailResetTimer takes nothing returns nothing
	if RiftsFailResetTimer != null then
		call DestroyTimer(RiftsFailResetTimer)
		set RiftsFailResetTimer = null
	endif
endfunction

private function RequestRiftsElarindorHostilityFailure takes nothing returns nothing
	if RiftsRitualActive and not RiftsFailureInProgress then
		call ExecuteFunc("qAradion_FailRiftsForElarindorHostilityPublic")
	endif
endfunction

private function RequestRiftsCompanionStateFailure takes nothing returns nothing
	if RiftsQuestActive and not RiftsFailureInProgress then
		call ExecuteFunc("qAradion_FailRiftsForCompanionStatePublic")
	endif
endfunction

private function ResetRiftsObjectivesForNewRun takes QuestData q returns nothing
	if q == 0 then
		return
	endif
	call q.setRequirement(1, GetRiftsFieldObjectiveText())
	call q.updateRequirementText(1, GetRiftsFieldObjectiveText())
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
		return VL_VALERIA_0064_TEXT
	elseif failedUnit == Aradion then
		return VL_ARADION_0086_TEXT
	endif
	return ""
endfunction

private function GetRiftsFailurePrimarySound takes unit failedUnit returns string
	if failedUnit == Valeria then
		return VL_VALERIA_0064_KEY
	elseif failedUnit == Aradion then
		return VL_ARADION_0086_KEY
	endif
	return ""
endfunction

private function GetRiftsFailureReplyText takes unit failedUnit returns string
	if failedUnit == Valeria then
		return VL_ARADION_0079_TEXT
	elseif failedUnit == Aradion then
		return VL_VALERIA_0063_TEXT
	endif
	return ""
endfunction

private function GetRiftsFailureReplySound takes unit failedUnit returns string
	if failedUnit == Valeria then
		return VL_ARADION_0079_KEY
	elseif failedUnit == Aradion then
		return VL_VALERIA_0063_KEY
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
	call ClearRiftsLeftBehindIcons()
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
	call ReturnRiftsCompanionsHomeInternal()
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirement(q.id, 5, "Speak with Aradion")
		call q.markRequirementCompleted(5, true)
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_READY_TURNIN)
		call q.refreshQuestLog()
		call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80a0ffObjective updated:|r Speak with Aradion.")
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
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0061_KEY, VL_VALERIA_0061_TEXT)
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0062_KEY, VL_VALERIA_0062_TEXT)
	endif
endfunction

private function PlayRiftsCombatBark takes nothing returns nothing
	local integer roll
	if ShouldPlayRiftsOverwhelmedLine() then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0065_KEY, VL_VALERIA_0065_TEXT)
		return
	endif
	set roll = GetRandomInt(1, 3)
	if roll == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0076_KEY, VL_ARADION_0076_TEXT)
	elseif roll == 2 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0077_KEY, VL_ARADION_0077_TEXT)
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0078_KEY, VL_ARADION_0078_TEXT)
	endif
endfunction

private function PlayRiftsFinishBarks takes nothing returns nothing
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0080_KEY, VL_ARADION_0080_TEXT)
	else
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0082_KEY, VL_ARADION_0082_TEXT)
	endif
	if GetRandomInt(1, 2) == 1 then
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0066_KEY, VL_VALERIA_0066_TEXT)
	else
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0068_KEY, VL_VALERIA_0068_TEXT)
	endif
endfunction

private function PlayRiftsAllClosedBarks takes nothing returns nothing
	call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0084_KEY, VL_ARADION_0084_TEXT_ALT1)
	call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0070_KEY, VL_VALERIA_0070_TEXT)
	call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0085_KEY, VL_ARADION_0085_TEXT_ALT1)
	call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0071_KEY, VL_VALERIA_0071_TEXT)
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

private function RetargetRiftsWavesToAradion takes nothing returns nothing
	local integer i = 1
	if Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	loop
		exitwhen i > RiftsWaveIndex or i > RIFTS_MAX_WAVES
		if RiftsWaveHandles[i] != 0 and RiftsWaveHandles[i].getRemainingCount() > 0 then
			call RiftsWaveHandles[i].attackMove(GetUnitX(Aradion), GetUnitY(Aradion))
		endif
		set i = i + 1
	endloop
endfunction

private function OnRiftsCombatTick takes nothing returns nothing
	call RetargetRiftsWavesToAradion()
	call PlayRiftsCombatBark()
endfunction

private function OnRiftsCountdownTick takes nothing returns nothing
	local texttag tag
	if not RiftsRitualActive or Aradion == null or not QuestGiver_IsUnitAlive(Aradion) then
		return
	endif
	if IsElarindorHostileForRifts() then
		call RequestRiftsElarindorHostilityFailure()
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
	local unit hero
	call SyncUnitReferences()
	if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	if not IsRiftsCorruptionInProgress() then
		return
	endif
	if not RiftsAwaitingReturnHome and not RiftsReturnedHome and (not ValeriaCompanionActive or not AradionCompanionActive or IsRiftsFieldCompanionStateBroken()) then
		set RiftsQuestActive = true
		set hero = GetRiftsTrackingHero()
		call StartFieldCompanions(hero)
	endif
	set RiftsCorruptionCounter = RiftsCorruptionCounter + 1
	call DebugMsg("Updating Quest: Rifts of Corruption - Counter=" + I2S(RiftsCorruptionCounter))
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q == 0 then
		set hero = null
		return
	endif
	call QuestGiver_SetRequirement(q.id, 2, "Rifts closed " + I2S(RiftsCorruptionCounter) + " / 3")
	if RiftsCorruptionCounter >= 3 then
		call q.markRequirementCompleted(1, true)
		call q.markRequirementCompleted(2, true)
		call q.markRequirementCompleted(3, true)
		call q.markRequirementCompleted(4, true)
		call QuestGiver_AddRequirement(q.id, 5, GetRiftsReturnHomeObjectiveText())
		call q.markRequirementCompleted(5, false)
		call q.refreshQuestLog()
		set RiftsAwaitingReturnHome = true
		set RiftsReturnedHome = false
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_IN_PROGRESS)
	else
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, QUEST_STATE_IN_PROGRESS)
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	set hero = null
endfunction

private function FinishRiftsCurrentRitual takes nothing returns nothing
	local unit hero
	local unit closedRift = RiftsCurrentRift
	local unit slotRift = null
	local integer closedIndex = RiftsCurrentIndex
	local real closedRiftX = 0.00
	local real closedRiftY = 0.00
	call SyncUnitReferences()
	if not RiftsQuestActive then
		set closedRift = null
		set slotRift = null
		return
	endif
	call StopRiftsRuntimeTimers()
	call ClearRiftsWaveHandles()
	call DialogSystem_ClearFieldLineQueue()
	if closedIndex > 0 and closedIndex <= RIFTS_MAX then
		set slotRift = RiftsUnits[closedIndex]
		set RiftsClosed[closedIndex] = true
		set RiftsUnits[closedIndex] = null
	endif
	set closedRiftX = GetRiftEffectX(closedRift, slotRift, closedIndex)
	set closedRiftY = GetRiftEffectY(closedRift, slotRift, closedIndex)
	if closedRiftX != 0.00 or closedRiftY != 0.00 then
		call DestroyEffect(AddSpecialEffect("Objects\\Spawnmodels\\NightElf\\NECancelDeath\\NECancelDeath.mdl", closedRiftX, closedRiftY))
	endif
	call CloseManaRiftUnit(slotRift)
	if closedRift != slotRift then
		call CloseManaRiftUnit(closedRift)
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
		call DialogSystem_QueueFieldLine(Aradion, "Aradion the Farseer", VL_ARADION_0083_KEY, VL_ARADION_0083_TEXT)
		call DialogSystem_QueueFieldLine(Valeria, "Valeria", VL_VALERIA_0069_KEY, VL_VALERIA_0069_TEXT)
	endif
	set hero = null
	set closedRift = null
	set slotRift = null
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

private function UpdateRiftsObjectiveLog takes QuestData q, integer reqIndex, string text returns nothing
	if q == 0 then
		return
	endif
	call q.updateRequirementText(reqIndex, text)
	call q.refreshQuestLog()
endfunction

private function ShowRiftsLeftFieldUpdate takes QuestData q returns nothing
	local integer reqIndex = 1
	if q == 0 then
		return
	endif
	if RiftsAwaitingReturnHome then
		set reqIndex = 5
	endif
	call UpdateRiftsObjectiveLog(q, reqIndex, GetRiftsReturnToFieldObjectiveText())
	call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80a0ffObjective updated:|r Return to " + GetAradionFieldZoneListText() + " to continue escorting Aradion and Valeria.")
endfunction

private function ShowRiftsRejoinedFieldUpdate takes QuestData q returns nothing
	if q == 0 then
		return
	endif
	if RiftsAwaitingReturnHome then
		call UpdateRiftsObjectiveLog(q, 5, GetRiftsReturnHomeObjectiveText())
		call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80a0ffObjective updated:|r Aradion and Valeria have rejoined you. Continue escorting them home.")
	else
		call UpdateRiftsObjectiveLog(q, 1, GetRiftsFieldObjectiveText())
		call QuestMaster_ShowUpdateMessage(q.id, "|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n|cff80a0ffObjective updated:|r Aradion and Valeria have rejoined you. Continue searching for the rifts.")
	endif
endfunction

private function OnRiftsFieldTick takes nothing returns nothing
	local unit hero
	local QuestData q
	call SyncUnitReferences()
	if not RiftsQuestActive or RiftsFailureInProgress then
		return
	endif
	if IsRiftsFieldCompanionStateBroken() then
		call RequestRiftsCompanionStateFailure()
		return
	endif
	if IsElarindorHostileForRifts() then
		if RiftsRitualActive then
			call RequestRiftsElarindorHostilityFailure()
		endif
		return
	endif
	if not IsAradionFieldZoneActive() then
		if not RiftsHasEnteredFieldZone then
			return
		endif
		call StopFieldCompanions()
		call UpdateRiftsLeftBehindIcons()
		if not RiftsLeftFieldZoneNotified then
			set RiftsLeftFieldZoneNotified = true
			set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
			call ShowRiftsLeftFieldUpdate(q)
		endif
		set q = 0
		return
	endif
	set RiftsHasEnteredFieldZone = true
	if RiftsLeftFieldZoneNotified then
		set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
		set hero = GetRiftsTrackingHero()
		call StartFieldCompanions(hero)
		call ShowRiftsRejoinedFieldUpdate(q)
		set hero = null
		set q = 0
	else
		call ClearRiftsLeftBehindIcons()
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
	set RiftsLeftFieldZoneNotified = false
	set RiftsHasEnteredFieldZone = false
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
	call ReturnRiftsCompanionsHomeInternal()
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

public function FailRiftsForElarindorHostilityPublic takes nothing returns nothing
	call SyncUnitReferences()
	if RiftsRitualActive and not RiftsFailureInProgress then
		call HandleRiftsFailure("Elarindor turned hostile during the ritual.")
	endif
endfunction

public function FailRiftsForCompanionStatePublic takes nothing returns nothing
	call SyncUnitReferences()
	if RiftsQuestActive and not RiftsFailureInProgress then
		call HandleRiftsFailure("Aradion or Valeria left the party.")
	endif
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
	call QuestGiver_StartConfiguredDialogExitTransition(Aradion, SelectedHero, AradionDialogCooldown, DIALOG_COOLDOWN, USE_DIALOG_CAMERA, CINEMATIC)
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
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestKill takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestTalkTo takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestTalkTo takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestFindNPC takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestFindNPC takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestGoTo takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestGoTo takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestReputation takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestReputation takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestInvestigate takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestInvestigate takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
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
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
	
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)

	// Make Aradion and hero face each other
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0035_TEXT, VL_ARADION_0035_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0036_TEXT, VL_ARADION_0036_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0337_TEXT, VL_NAZGREK_0337_KEY)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFailQuest1 takes nothing returns nothing
	call QuestGiver_BeginDialogSequence()
	call FailRangerMissingForRetry("Valeria was lost.")
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest1FadeHomeReturn takes nothing returns nothing
	local timer t = GetExpiredTimer()
	call ExecuteFunc("qAradion_RecreateValeriaAtHomePublic")
	call StartValeriaHomePatrolInternal()
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
	set t = null
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
	
	call QuestGiver_BeginDialogSequence()
	
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
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0023_TEXT, VL_VALERIA_0023_KEY, true)
	if hero != null and Aradion != null then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Aradion, 0.75, 0.0)
	endif
	call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0031_TEXT, VL_ARADION_0031_KEY, true)
	call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, Aradion, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0032_TEXT, VL_ARADION_0032_KEY, true)
	if hero == Nazgrek then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
		call DialogSystem_AddDelay(seq, 1.00)
		call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0024_TEXT, VL_VALERIA_0024_KEY, true)
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
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0033_TEXT, VL_ARADION_0033_KEY, true)
	call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, Valeria, 0.75, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0034_TEXT, VL_ARADION_0034_KEY, true)
	if hero == Nazgrek then
		call DialogSystem_AddMakeUnitFaceUnit(seq, hero, Valeria, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Valeria, hero, 0.75, 0.0)
		call DialogSystem_AddMakeUnitFaceUnit(seq, Aradion, hero, 0.75, 0.0)
		call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0025_TEXT, VL_VALERIA_0025_KEY, true)
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
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest2End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0041_TEXT, VL_ARADION_0041_KEY, true)
	call QuestGiver_AddHeroLookAtLine(seq, hero, Aradion, VL_NAZGREK_0366_TEXT, VL_NAZGREK_0366_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0042_TEXT, VL_ARADION_0042_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0043_TEXT, VL_ARADION_0043_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0044_TEXT, VL_ARADION_0044_KEY, true)
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
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest2End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0047_TEXT, VL_ARADION_0047_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0048_TEXT, VL_ARADION_0048_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0049_TEXT, VL_ARADION_0049_KEY, true)
	call QuestGiver_AddHeroLookAtLine(seq, hero, Aradion, VL_NAZGREK_0367_TEXT, VL_NAZGREK_0367_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0050_TEXT, VL_ARADION_0050_KEY, true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function GetFadingSparksRodHero takes nothing returns unit
	return GetPlayerQuestHero(FadingSparksRodHero)
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
	set hero = GetFadingSparksRodHero()
	set SelectedHero = hero
	call QuestGiver_GiveUniqueQuestItemToHero(hero, ITEM_TELANOR_ROD, ITEM_TELANOR_ROD_LEGACY, "Tel'anor Rod")
	set FadingSparksRodHero = null
	call StartExitFadeOut()
	set hero = null
endfunction

private function OnRecoverTelanorRodEnd takes nothing returns nothing
	local unit hero
	set hero = GetFadingSparksRodHero()
	set SelectedHero = hero
	call QuestGiver_GiveUniqueQuestItemToHero(hero, ITEM_TELANOR_ROD, ITEM_TELANOR_ROD_LEGACY, "Tel'anor Rod")
	set FadingSparksRodHero = null
	call StartExitFadeOut()
	set hero = null
endfunction

private function OnRecoverTelanorRod takes nothing returns nothing
	local integer seq
	local unit hero
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnRecoverTelanorRodEnd)
	set hero = ResolveDialogHero()
	set SelectedHero = hero
	set FadingSparksRodHero = hero
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Take another rod of Tel'anor. Without it, the wraith essences will slip away before you can preserve them.", "", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
	set hero = null
endfunction

private function OnAcceptQuest3 takes nothing returns nothing
	local integer seq
	local unit hero
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest3End)
	
	// Make Aradion and hero face each other
	set hero = ResolveDialogHero()
	set SelectedHero = hero
	set FadingSparksRodHero = hero
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0053_TEXT, VL_ARADION_0053_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0054_TEXT, VL_ARADION_0054_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0055_TEXT, VL_ARADION_0055_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0056_TEXT, VL_ARADION_0056_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0371_TEXT, VL_NAZGREK_0371_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0063_TEXT, VL_ARADION_0063_KEY, true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest3End takes nothing returns nothing
	local QuestData q
	if HeroItemCheckBothAndRemove(ITEM_WRAITH_ESSENCE, 10) then
		call QuestGiver_RemoveQuestItemsEverywhereEither(ITEM_TELANOR_ROD, ITEM_TELANOR_ROD_LEGACY)
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
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest3End)
	
	// Make Aradion and hero face each other
	set hero = ResolveDialogHero()
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific completion dialog
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0060_TEXT, VL_ARADION_0060_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0061_TEXT, VL_ARADION_0061_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0062_TEXT, VL_ARADION_0062_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0372_TEXT, VL_NAZGREK_0372_KEY)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest4End takes nothing returns nothing
	local QuestData q
	set AradionLastAcceptedQuest = ARADION_QID_RIFTS
	set q = QuestGiver_GetByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	if q != 0 then
		call ResetRiftsObjectivesForNewRun(q)
	endif
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
	set RiftsQuestActive = true
	call StopValeriaPatrolInternal()
	set RiftsLeftFieldZoneNotified = false
	set RiftsHasEnteredFieldZone = false
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
	if Aradion != null then
		call SetUnitInvulnerable(Aradion, false)
	endif
	if Valeria != null then
		call SetUnitInvulnerable(Valeria, false)
	endif
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest4 takes nothing returns nothing
	local integer seq
	local unit hero
	
	if Valeria == null or not UnitAlive(Valeria) then
		call RecreateValeriaAtHome()
	endif

	// SAFETY CHECK: Verify Valeria exists for this quest dialogue
	// DialogSystem will skip null unit actions, but log warning for debugging
	if Valeria == null or not UnitAlive(Valeria) then
		call BJDebugMsg("[qAradion] WARNING: Valeria is null/dead in OnAcceptQuest4 - some dialogue actions will be skipped")
	endif
	
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest4End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	set SelectedHero = hero
	call PrepareValeriaForRiftsIntro(hero)
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0065_TEXT, VL_ARADION_0065_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0066_TEXT, VL_ARADION_0066_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0067_TEXT, VL_ARADION_0067_KEY, true)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddLookAtUnit(seq, Valeria, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", VL_VALERIA_0060_TEXT, VL_VALERIA_0060_KEY, true)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0377_TEXT, VL_NAZGREK_0377_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0068_TEXT, VL_ARADION_0068_KEY, true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest4End takes nothing returns nothing
	set RiftsQuestActive = false
	set RiftsLeftFieldZoneNotified = false
	set RiftsHasEnteredFieldZone = false
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
	
	call QuestGiver_BeginDialogSequence()
	set seq = QuestGiver_CreateBaseSequence(Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest4End)
	
	// Get hero for facing actions
	set hero = ResolveDialogHero()
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, Aradion, 0.50, 0.0)
	call QuestGiver_AddHeroLine(seq, hero, VL_NAZGREK_0378_TEXT, VL_NAZGREK_0378_KEY)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0071_TEXT, VL_ARADION_0071_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0072_TEXT, VL_ARADION_0072_KEY, true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", VL_ARADION_0073_TEXT, VL_ARADION_0073_KEY, true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFarewellEnd takes nothing returns nothing
	call StartExitFadeOut()
endfunction

private function OnFarewell takes nothing returns nothing
	local integer seq
	call QuestGiver_BeginDialogSequence()
	
	// Use QuestGiver helper to build farewell sequence
	set seq = QuestGiver_CreateFarewellSequence(Aradion, "Aradion the Farseer", null, "", DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnFarewellEnd)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

//===========================================================================
// Line registration
//===========================================================================
private function RegisterLines takes nothing returns nothing
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, VL_ARADION_0017_TEXT, VL_ARADION_0017_KEY, true)
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, VL_ARADION_0018_TEXT, VL_ARADION_0018_KEY, true)
	call DialogSystem_RegisterFarewellLineForUnit(Aradion, VL_ARADION_0019_TEXT, VL_ARADION_0019_KEY, true)
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
	call QuestGiver_AddQuestItemRecoveryButtonEither(AradionDialog, QUEST_FADING_SPARKS, Aradion, 23, ITEM_TELANOR_ROD, ITEM_TELANOR_ROD_LEGACY, 1, "Tel'anor Rod", function OnRecoverTelanorRod)

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
	call SyncUnitReferences()

	if IsElarindorTemporarilyHostile() then
		call DebugMsg("Select gate blocked: Elarindor temporarily hostile")
		return
	endif
	if RiftsRitualActive then
		call DebugMsg("Select gate blocked: rift ritual active")
		return
	endif
	set hero = QuestGiver_GetDialogSelectionHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	set gateOk = QuestGiver_PassDialogSelectionGate(Aradion, hero, DIALOG_RANGE, AradionDialogCooldown, REQUIRE_DIALOG_HERO, true, true, true, false, false)
	call DebugMsg("OnSelected: gateOk=" + I2S(B2I(gateOk)))
	if not gateOk then
		call DebugMsg("Select gate blocked: " + QuestGiver_GetLastSelectionBlockReason())
		set hero = null
		return
	endif
	call DebugMsg("OnSelected: Passed gate check")
	
	// Store hero for fade sequence
	set SelectedHero = hero
	call SyncRangerMissingReadyTurnIn()
	call QuestGiver_StartConfiguredDialogEntryTransition(Aradion, hero, true, USE_DIALOG_CAMERA, CINEMATIC, "qAradion_ContinueToDialogAfterSelection")
	set hero = null
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

	set q = QuestGiver_CreateConfiguredQuest(QUEST_RANGER_MISSING, Aradion, "normal", 18, null, "Ranger Missing", "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp", "Find Valeria somewhere in " + GetAradionFieldZoneListText() + ".\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call QuestGiver_SetQuestRequiredReputation(q, Reputation_REP_ENEMY)
	call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
	set availabilityCondition = CreateTrigger()
	call TriggerAddCondition(availabilityCondition, Condition(function CanOfferRangerMissing))
	call QuestGiver_SetQuestCustomCondition(q, availabilityCondition)
	call QuestGiver_SetRequirements(q.id, "", "Find Valeria", "", "", "", "", "", "", "")

	set q = QuestGiver_CreateConfiguredQuest(QUEST_CRYSTALS_HOPE, Aradion, "normal", 18, null, "Crystals of Hope", "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp", "Aradion wants to study the mana crystals that can be found anywhere in Vanguard Vale.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
	call QuestGiver_AddQuestPrerequisite(q, QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Mana Crystals
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_MANA_CRYSTAL, 6)

	set q = QuestGiver_CreateConfiguredQuest(QUEST_FADING_SPARKS, Aradion, "normal", 18, null, "Fading Sparks", "ReplaceableTextures\\CommandButtons\\BTNHeartOfAszune.blp", "Aradion wants you to gather essences from the wraiths wandering around the Vanguard Vale. Use provided |cffffff00Tel'anor Rod|r when the wraith is at half health.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
	call QuestGiver_AddQuestPrerequisite(q, QUEST_RANGER_MISSING, Aradion)
	// Register automatic item tracking for Wraith Essences
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_WRAITH_ESSENCE, 10)

	set q = QuestGiver_CreateConfiguredQuest(QUEST_RIFTS_CORRUPTION, Aradion, "normal", 18, null, "Rifts of Corruption", "ReplaceableTextures\\CommandButtons\\BTNDizzy.blp", GetRiftsFieldObjectiveText() + " and escort Valeria and Aradion to them. Guard Aradion while he will close the rifts. Both Aradion and Valeria must stay alive.\n\n", infoText, info2Text, 15, true, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
	call QuestGiver_SetQuestRewards(q, true, 0, true, 0, false, 0, true, 200, false)
	call QuestGiver_AddQuestPrerequisite(q, QUEST_RANGER_MISSING, Aradion)
	call QuestGiver_AddQuestPrerequisite(q, QUEST_CRYSTALS_HOPE, Aradion)
	call QuestGiver_AddQuestPrerequisite(q, QUEST_FADING_SPARKS, Aradion)
	call QuestGiver_SetRequirements(q.id, "", GetRiftsFieldObjectiveText(), "Rifts closed 0 / 3", "Guard Aradion while he closes the rifts", "Both Aradion and Valeria must stay alive", "", "", "", "")

	if ENABLE_TEST_QUESTS then
		// Test Quest 1: Kill
		set q = QuestMaster_TemplateKill(QUEST_TEST_KILL, Aradion, "normal", 1, 'ngno', 3)
		call QuestGiver_RegisterUnitKillRequirement(q.id, Aradion, 1, 'ngno', 3)
		call QuestGiver_ApplyQuestMetadata(q, "Test: Kill Quest", "ReplaceableTextures\\CommandButtons\\BTNFootman.blp", "Test quest for killing units.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 2: Talk To
		set q = QuestMaster_TemplateTalkTo(QUEST_TEST_TALKTO, Aradion, "normal", 1, "Valeria")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Talk To Quest", "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp", "Test quest for talking to NPC.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 3: Find NPC
		set q = QuestMaster_TemplateFindNPC(QUEST_TEST_FINDNPC, Aradion, "normal", 1, "Valeria")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Find NPC Quest", "ReplaceableTextures\\CommandButtons\\BTNHeroTaurenChieftain.blp", "Test quest for finding an NPC.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 4: Go To Place
		set q = QuestMaster_TemplateGoToPlace(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Go To Place Quest", "ReplaceableTextures\\CommandButtons\\BTNWaypoint.blp", "Test quest for going to a location.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 100, false)
		
		// Test Quest 5: Reputation
		set q = QuestMaster_TemplateReputation(QUEST_TEST_REPUTATION, Aradion, "normal", 1, "Elarindor", "Friendly")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Reputation Quest", "ReplaceableTextures\\CommandButtons\\BTNTome.blp", "Test quest for reputation gain.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 500, false)
		
		// Test Quest 6: Investigate
		set q = QuestMaster_TemplateInvestigate(QUEST_TEST_INVESTIGATE, Aradion, "normal", 1, "the strange ruins near the Vale")
		call QuestGiver_ApplyQuestMetadata(q, "Test: Investigate Quest", "ReplaceableTextures\\CommandButtons\\BTNAncientRelic.blp", "Test quest for investigating.\n\n", infoText, "|cffffcc00Recommended level:|r 1\n\n", 1, false, ALLOW_NAZGREK, ALLOW_ZULKIS, "Elarindor", giverName)
		call QuestGiver_SetQuestRewards(q, true, 0, true, 50, false, 0, true, 100, false)
	endif

	set availabilityCondition = null
endfunction

//===========================================================================
// Init
//===========================================================================
private function InitRiftsDelayed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	if t != null then
		call DestroyTimer(t)
	endif
	call CreateInitialRiftUnits()
	call RegisterRiftUnits()
	set t = null
endfunction

private function OnDelayedQuestDiscovered takes nothing returns nothing
	local unit hero
	call SyncUnitReferences()
	if not QuestGiver_IsEventQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		return
	endif
	call BJDebugMsg("[qAradion] Rifts delayed discovery event received.")
	if not RiftsQuestActive or RiftsFailureInProgress or RiftsAwaitingReturnHome or RiftsReturnedHome then
		call BJDebugMsg("[qAradion] Rifts delayed discovery setup skipped: active=" + I2S(B2I(RiftsQuestActive)) + ", failing=" + I2S(B2I(RiftsFailureInProgress)) + ", returning=" + I2S(B2I(RiftsAwaitingReturnHome)) + ", returned=" + I2S(B2I(RiftsReturnedHome)) + ".")
		return
	endif
	set hero = GetRiftsTrackingHero()
	if hero == null then
		call BJDebugMsg("[qAradion] ERROR: Rifts delayed discovery setup skipped because no valid player hero was resolved.")
		set hero = null
		return
	endif
	call PrepareRiftsForQuestDiscovery()
	call StopValeriaPatrolInternal()
	call StartFieldCompanions(hero)
	call EnableRiftsFailTriggers()
	call StartRiftsFieldMonitor()
	call BJDebugMsg("[qAradion] Rifts delayed discovery setup complete: ValeriaControlled=" + I2S(B2I(Valeria != null and Companions_IsControlled(Valeria))) + ", AradionControlled=" + I2S(B2I(Aradion != null and Companions_IsControlled(Aradion))) + ".")
	set hero = null
endfunction

private function InitDelayed takes nothing returns nothing
	local timer riftTimer
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
	call DebugMsg("Init Aradion giver id=" + I2S(GetHandleId(Aradion)))
	call QuestGiver_Register(Aradion)
	call QuestGiver_ConfigureDialogTransition(Aradion, CINEMATIC_MOVE_MODE, CINEMATIC_MOVE_OFFSET, CINEMATIC_MOVE_ANGLE, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK)
	call QuestGiver_SetGreetOrder(Aradion, QUESTGIVER_GREET_NAZGREK_THEN_NPC)
	call RegisterLines()
	call RegisterRangerMissingValeriaGlobalDeathTrigger()
	call RegisterValeriaEncounterProximityTrigger()
	call RegisterFadingSparksSpellTriggers()
	call CreateQuests()
	call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	call QuestGiver_RegisterSelectionHandler(Aradion, function OnSelected)
	call QuestGiver_AddDelayedDiscoveredAction(function OnDelayedQuestDiscovered)
	call RegisterCompanionCommandBridge()
	set riftTimer = CreateTimer()
	call TimerStart(riftTimer, 5.00, false, function InitRiftsDelayed)
	set riftTimer = null
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

public function TestSpawnManaRifts takes nothing returns nothing
	local integer i = 1
	call BJDebugMsg("[qAradion] TEST ManaRifts: direct spawn check begin.")
	loop
		exitwhen i > RIFTS_MAX
		call BJDebugMsg("[qAradion] TEST ManaRifts: slot " + I2S(i) + " begin.")
		call TestSpawnManaRiftSlot(i)
		call BJDebugMsg("[qAradion] TEST ManaRifts: slot " + I2S(i) + " end.")
		set i = i + 1
	endloop
	call RegisterRiftsProximityTrigger()
	call BJDebugMsg("[qAradion] TEST ManaRifts: direct spawn check end; proximity trigger refreshed.")
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
	if IsElarindorHostileForRifts() then
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
	if not RiftsQuestActive or not RiftsRitualActive then
		return
	endif
	call FinishRiftsCurrentRitual()
endfunction

public function FailRifts takes string reason returns nothing
	call HandleRiftsFailure(reason)
endfunction

public function ReturnRiftsCompanionsHome takes nothing returns nothing
	set RiftsQuestActive = false
	set RiftsLeftFieldZoneNotified = false
	set RiftsHasEnteredFieldZone = false
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
