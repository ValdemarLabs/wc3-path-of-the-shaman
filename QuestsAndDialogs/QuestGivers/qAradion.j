library qAradion initializer Init requires QuestGiver, QuestMaster, DialogSystem, ExSound, CameraControl
//===========================================================================
// qAradion
// Quest giver dialog + quest flow for Aradion the Farseer.
//===========================================================================
globals
	private constant boolean DEBUG = true

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

	private constant integer ITEM_MANA_CRYSTAL = 'I000'
	private constant integer ITEM_WRAITH_ESSENCE = 'I001'
	private constant integer ITEM_TELANOR_ROD = 'I002'

	private constant real DIALOG_RANGE = 500.00
	private constant real VALERIA_RANGE = 1000.00
	private constant real DIALOG_COOLDOWN = 6.00
	private constant boolean REQUIRE_DIALOG_HERO = true
	private constant integer CINEMATIC_MOVE_MODE = 1  // 1 = All units,
	private constant real CINEMATIC_MOVE_OFFSET = 256.00  // Offset for cinematic positioning
	private constant real CINEMATIC_MOVE_ANGLE = 210.00   // Angle for cinematic positioning

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
	private boolean AradionInitWaitingLogged = false
	private integer AradionLastAcceptedQuest = 0

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
		call CinematicModeBJ(true, GetPlayersAll())
	endif
endfunction

private function ExitCinematicMode takes nothing returns nothing
	if CINEMATIC then
		call CinematicModeBJ(false, GetPlayersAll())
	endif
endfunction

//===========================================================================
// External state helpers
//===========================================================================
function SetBackstorySeen takes boolean flag returns nothing
	set AradionBackstorySeen = flag
endfunction

function SetRangerMissingReq1Complete takes boolean flag returns nothing
	set RangerMissingReq1Complete = flag
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

private function AddInProgressGreet takes integer seq returns boolean
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
			call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "I'll see if I come across her.", "Nazgrek_0337", true)
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
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "Your blood is not what I seek, elf. I walk the spirit path, not the path of slaughter.", "Nazgrek_0331", true)
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
	set handled = AddInProgressGreet(seq)
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
	// Clear the cooldown so dialog can be shown immediately
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		call QuestGiver_RefreshAvailabilityForGiver(Aradion)
	endif

	//call DialogSystem_StopDialogCamera(Player(0), 2.00, USE_DIALOG_CAMERA)
	// Reopen dialog after backstory
	set t = CreateTimer()
	call TimerStart(t, 2.00, false, function ReopenDialogAfterInfo)
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
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
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
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "You said... a witch deceived you?", "Nazgrek_0332", true)
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "Why did your kin trust this witch?", "Nazgrek_0333", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Her words promised glory - strength to rival Quel'Thalas itself. Her lies were sweet... and my people were starving for more.", "Aradion_0008", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But every promise was poison. Each draught of her 'gift' deepened the hunger, until the hunger itself consumed them.", "Aradion_0009", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now my people are twisted, their flesh withering, their souls bleeding into wraiths. Soon... nothing of them will remain.", "Aradion_0010", true)
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "The wraiths I see... they were once elves?", "Nazgrek_0334", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes. Once mothers, fathers, children. Now only hollow echoes bound to the Void by the magic that devoured them.", "Aradion_0011", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The wretched who remain will share the same fate - it is only a matter of time before they too dissolve into wraiths.", "Aradion_0012", true)
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "And you? How did you resist where others fell?", "Nazgrek_0336", true)
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
	local QuestData q
	if RangerMissingReq1Complete or not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		return
	endif
	call DebugMsg("Updating Quest: Ranger Missing")
	set RangerMissingReq1Complete = true
	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirementCompleted(q.id, 1, true)
		call QuestGiver_SetRequirement(q.id, 2, "Escort Valeria to safety")
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
endfunction

public function UpdateQuestRiftsCorruption takes nothing returns nothing
	local QuestData q
	local string reqText
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
	if q != 0 then
		call QuestGiver_SetRequirement(q.id, 1, reqText)
	endif
	if RiftsCorruptionCounter >= 3 then
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, 5)
	else
		call QuestMaster_SetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion, 3)
	endif
	call QuestGiver_UpdateQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
endfunction

//===========================================================================
// Exit fade sequence callbacks
//===========================================================================
private function ExitDialogCleanup takes nothing returns nothing
	local timer t = GetExpiredTimer()

	// Fade in over 1 second
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	
	// Perform cleanup sequence
	call QuestGiver_HandleSequenceEnd(Aradion, AradionDialogCooldown, DIALOG_COOLDOWN, true, 2.00, USE_DIALOG_CAMERA, false)
	call TriggerExecute(gg_trg_Cinematic_OFF)
	call ExitCinematicMode()
	call EnableUserControl(true)
	
	call DestroyTimer(t)
endfunction

private function StartExitFadeOut takes nothing returns nothing
	local timer t
	
	// Fade out over 1 second
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	
	// Wait 1 second then cleanup
	set t = CreateTimer()
	call TimerStart(t, 1.0, false, function ExitDialogCleanup)
endfunction

//===========================================================================
// Test quest handlers (simple accept/complete)
//===========================================================================
private function OnAcceptTestKill takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestKill takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_KILL, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestTalkTo takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestTalkTo takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_TALKTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestFindNPC takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestFindNPC takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_FINDNPC, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestGoTo takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestGoTo takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_GOTO, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestReputation takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestReputation takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_TEST_REPUTATION, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptTestInvestigate takes nothing returns nothing
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteTestInvestigate takes nothing returns nothing
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
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest1 takes nothing returns nothing
	local integer seq
	local unit hero
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest1End)
	
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)

	// Make Aradion and hero face each other
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 1.0)
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "In the chaos, when the wraiths struck, my beloved Valeria was torn from my side.", "Aradion_0035", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I have searched, but the shadows grow thick. If she still lives and you find her, bring her to me, shaman… before they claim her as well.", "Aradion_0036", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnFailQuest1 takes nothing returns nothing
	call EnableUserControl(false)
	call QuestGiver_FailQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion, "Valeria was lost.")
	call QuestGiver_AbandonQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	call StartExitFadeOut()
endfunction

private function OnCompleteQuest1End takes nothing returns nothing
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
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
	
	call EnableUserControl(false)
	
	// Mark requirement 2 as completed
	set q = QuestGiver_GetByNameAndGiver(QUEST_RANGER_MISSING, Aradion)
	if q != 0 then
		call QuestGiver_SetRequirementCompleted(q.id, 2, true)
	endif
	
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest1End)
	
	// Get hero for facing actions
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
	// Add quest-specific completion dialog with inline facing/looking
	// NOTE: Valeria existence validated above - these calls are now safe
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, Aradion, 0.50, 0.0)
	call DialogSystem_AddLookAtUnit(seq, Aradion, Valeria, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "Aradion… It is you! I thought I'd never see you again.", "Valeria_0023", true)
	call DialogSystem_AddLookAtUnit(seq, Aradion, Valeria, 0.5)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria? By the stars… you yet live!", "Aradion_0031", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I feared that I had lost you… forgive me for losing hope.", "Aradion_0032", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "This orc… he spoke your name, my love. It is the only reason I followed him.", "Valeria_0024", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Then I was right. You Nazgrek are no foe, but a seeker.", "Aradion_0033", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "You have given me back my heart, shaman. For this… I owe you more than I can say.", "Aradion_0034", true)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "…Do not think this earns my trust fully, orc. But… for Aradion's sake, I'm giving you a chance.", "Valeria_0025", true)
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
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest2End)
	
	// Get hero for facing actions
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "In the ruins of Elarindor, there are crystals… pulsing, alive with energy.", "Aradion_0041", true)
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "I have walked near them. Their song is some what… twisted, yet beautiful.", "Nazgrek_0366", true)
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
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest2End)
	
	// Get hero for facing actions
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yes… these shards still resonate with power, I can feel it... It is almost... mesmerizing.", "Aradion_0047", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "If we can bend the crystals energy to our control, it might reverse the damage of the wretched elves decay… Or only soothe for a fleeting moment.…", "Aradion_0048", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yet the pulse of these crystals seems odd... As if the crystals themselves cry out in pain.", "Aradion_0049", true)
	call DialogSystem_AddLookAtUnit(seq, Nazgrek, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "I can hear the spirits whisper caution. These crystals may feed hunger, not heal it.", "Nazgrek_0367", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "I must study these shards you brought me… very carefully", "Aradion_0050", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest3End takes nothing returns nothing
	set AradionLastAcceptedQuest = ARADION_QID_FADING
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_FADING_SPARKS, Aradion)
	call StartExitFadeOut()
endfunction

private function OnAcceptQuest3 takes nothing returns nothing
	local integer seq
	local unit hero
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest3End)
	
	// Make Aradion and hero face each other
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific lines
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The mana wraiths are what remain when the hunger wins.", "Aradion_0053", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Yet even in their twisted forms, I sense a faint light — echoes of the elves they once were.", "Aradion_0054", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "If we can gather those sparks, perhaps they hold some secret… some key we have overlooked.", "Aradion_0055", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Bring me their essences, shaman. Let us see if even wraiths may whisper truth.", "Aradion_0056", true)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "I will do this Aradion, but I see little hope in the shadows.", "Nazgrek_0371", true)
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
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest3End)
	
	// Make Aradion and hero face each other
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	if hero != null then
		call DialogSystem_MakeFaceEachOther(Aradion, hero, 0.50)
	endif
	
	// Add quest-specific completion dialog
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "So fragile… yet for a moment, I can feel all the memories.... everything they once were…", "Aradion_0060", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "But it all slips away, fading faster than breath. They are too far gone.", "Aradion_0061", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "…If even wraiths leave behind only ashes of the soul, then perhaps our people's fate is truly sealed... ", "Aradion_0062", true)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "Do not surrender to despair, Aradion. There may yet be an answer to all of it.", "Nazgrek_0372", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnAcceptQuest4End takes nothing returns nothing
	set AradionLastAcceptedQuest = ARADION_QID_RIFTS
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)
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
	
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuest4End)
	
	// Get hero for facing actions
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
	// Add quest-specific lines with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "The ancient pools of magic around the Vanguard Vale and Elarindor once flowed pure, binding our people to life and light.", "Aradion_0065", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Now they are transformed.... distorted by implosion of the mana hunger.... And in those rift-like pools, the wraiths are born anew.", "Aradion_0066", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Valeria and I will attempt to seal these rifts. It is perilous work, and we don't truly know what we are dealing with. I've begin to think that I should do this alone…", "Aradion_0067", true)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddLookAtUnit(seq, Valeria, Aradion, 0.5)
	call DialogSystem_AddLine(seq, Valeria, "Valeria", "We have planned this forever… I can handle it, my love. ", "Valeria_0060", true)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "The spirits whisper of broken currents here. I will see Valeria through this.", "Nazgrek_0377", true)
	call DialogSystem_AddLine(seq, Aradion, "Aradion the Farseer", "Stand with us, Nazgrek. Guard me while I close the rifts — and strike down whatever nightmares the rifts unleash. ", "Aradion_0068", true)
	call DialogSystem_PlaySequence(seq, Player(0), Aradion)
endfunction

private function OnCompleteQuest4End takes nothing returns nothing
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
	
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, Aradion, "Aradion the Farseer")
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuest4End)
	
	// Get hero for facing actions
	set hero = QuestGiver_GetAllowedHero(Aradion, DIALOG_RANGE, ALLOW_NAZGREK, ALLOW_ZULKIS)
	
	// Add quest-specific completion dialog with inline facing
	call DialogSystem_AddMakeFaceEachOther(seq, Aradion, hero, 0.50, 0.0)
	// NOTE: Valeria null check in DialogSystem - this will be skipped if Valeria is invalid
	call DialogSystem_AddMakeFaceEachOther(seq, Valeria, Aradion, 0.50, 0.0)
	call DialogSystem_AddLine(seq, Nazgrek, "Nazgrek", "The wound in the land is remedied… for now.", "Nazgrek_0378", true)
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
	call EnableUserControl(false)
	
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

	if AradionDialog == null then
		set AradionDialog = DialogSystem_CreateDialog("Aradion the Farseer")
	endif

	call DialogSystem_ClearDialog(AradionDialog)
	call DialogSystem_SetTitle(AradionDialog, "Aradion the Farseer")

	set b = DialogSystem_AddButtonInfo(AradionDialog, 1)
	call DialogSystem_BindButtonCode(b, function OnBackstory)

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
		if AradionBackstorySeen and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_RANGER_MISSING, Aradion) == QUEST_STATE_AVAILABLE then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_RANGER_MISSING, 2)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest1)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
			set b = DialogSystem_AddButtonQuestFailed(AradionDialog, QUEST_RANGER_MISSING, 3)
			call DialogSystem_BindButtonCode(b, function OnFailQuest1)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) then
			if RangerMissingReq1Complete and QuestGiver_IsUnitAlive(Valeria) and QuestGiver_IsWithinRange(Aradion, Valeria, VALERIA_RANGE) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_RANGER_MISSING, 4)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest1)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) then
		if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) == QUEST_STATE_AVAILABLE then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_CRYSTALS_HOPE, 5)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest2)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) then
			// QuestGiver/QuestMaster handles item tracking automatically
			// Verify items are still in inventory before showing completion button
			if QuestGiver_GetStateByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) == 5 and QuestGiver_ValidateItemRequirements(QuestGiver_GetByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion).id) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_CRYSTALS_HOPE, 6)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest2)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_FADING_SPARKS, Aradion) then
		if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_FADING_SPARKS, Aradion) == QUEST_STATE_AVAILABLE then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_FADING_SPARKS, 7)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest3)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_FADING_SPARKS, Aradion) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FADING_SPARKS, Aradion) then
			// QuestGiver/QuestMaster handles item tracking automatically
			// Verify items are still in inventory before showing completion button
			if QuestGiver_GetStateByNameAndGiver(QUEST_FADING_SPARKS, Aradion) == 5 and QuestGiver_ValidateItemRequirements(QuestGiver_GetByNameAndGiver(QUEST_FADING_SPARKS, Aradion).id) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_FADING_SPARKS, 8)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest3)
			endif
		endif
	endif

	if QuestGiver_QuestExistsByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
		if QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RANGER_MISSING, Aradion) and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_CRYSTALS_HOPE, Aradion) and QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_FADING_SPARKS, Aradion) then
			if ((not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)) or QuestGiver_IsQuestFailedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion)) and QuestGiver_GetStateByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(AradionDialog, QUEST_RIFTS_CORRUPTION, 9)
				call DialogSystem_BindButtonCode(b, function OnAcceptQuest4)
			elseif not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_RIFTS_CORRUPTION, Aradion) then
				set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_RIFTS_CORRUPTION, 10)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest4)
			endif
		endif
	endif

	// Test quests (simple accept/complete with auto-discovery)
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_KILL, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_KILL, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_KILL, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_KILL, 11)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestKill)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_KILL, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_KILL, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_KILL, 12)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestKill)
		endif
	endif
	
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_TALKTO, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_TALKTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_TALKTO, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_TALKTO, 13)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestTalkTo)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_TALKTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_TALKTO, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_TALKTO, 14)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestTalkTo)
		endif
	endif
	
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_FINDNPC, 15)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestFindNPC)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_FINDNPC, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_FINDNPC, 16)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestFindNPC)
		endif
	endif
	
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_GOTO, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_GOTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_GOTO, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_GOTO, 17)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestGoTo)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_GOTO, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_GOTO, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_GOTO, 18)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestGoTo)
		endif
	endif
	
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAccept(AradionDialog, QUEST_TEST_REPUTATION, 19)
			call DialogSystem_BindButtonCode(b, function OnAcceptTestReputation)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) and QuestGiver_GetStateByNameAndGiver(QUEST_TEST_REPUTATION, Aradion) == QUEST_STATE_READY_TURNIN then
			set b = DialogSystem_AddButtonQuestComplete(AradionDialog, QUEST_TEST_REPUTATION, 20)
			call DialogSystem_BindButtonCode(b, function OnCompleteTestReputation)
		endif
	endif
	
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_TEST_INVESTIGATE, Aradion) then
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
private function ContinueToDialog takes nothing returns nothing
	local unit hero = SelectedHero
	
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

private function FadeInAndContinue takes nothing returns nothing
	local timer t
	
	// Fade in over 1 second
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	
	// Wait 1 second then continue to dialog
	set t = CreateTimer()
	call TimerStart(t, 1.0, false, function ContinueToDialog)
endfunction

private function SetupCinematicAndFadeIn takes nothing returns nothing
	local timer t = GetExpiredTimer()
	
	// Set up cinematic movement and run Cinematic ON trigger
	set udg_CinematicTriggerUnit = Nazgrek
	set udg_CinematicMoveMode = CINEMATIC_MOVE_MODE
	set udg_CinematicMovePoint[1] = Location(GetUnitX(Aradion) + CINEMATIC_MOVE_OFFSET * Cos(CINEMATIC_MOVE_ANGLE * bj_DEGTORAD), GetUnitY(Aradion) + CINEMATIC_MOVE_OFFSET * Sin(CINEMATIC_MOVE_ANGLE * bj_DEGTORAD))
	set udg_CinematicMovePoint[2] = udg_CinematicMovePoint[1]
	call DialogSystem_StartDialogCamera(Player(0), Aradion, CAMERA_DIST, CAMERA_Z_OFFSET, CAMERA_ANGLE, CAMERA_ROT_OFFSET, CAMERA_FAR_Z, CAMERA_FOV, CAMERA_BLOCK_RADIUS, CAMERA_BLOCK_CHECK, USE_DIALOG_CAMERA)
	call RemoveLocation(udg_CinematicMovePoint[1])
	call DestroyTimer(t)
	
	// Start fade in immediately
	call FadeInAndContinue()
endfunction

private function StartFadeOut takes nothing returns nothing
	local timer t
	
	// Fade out over 1 second
	call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	
	// Wait 1 second then setup cinematic
	set t = CreateTimer()
	call TimerStart(t, 1.0, false, function SetupCinematicAndFadeIn)
endfunction

private function OnSelected takes nothing returns nothing
	local unit hero
	local boolean gateOk
	local boolean selectedOk
	local boolean heroOk
	local boolean rangeOk
	local real remaining
	local integer customValue

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
	call CameraControl_SetTargetUnit(Player(0), hero)
	
	// Enter cinematic mode and start fade sequence
	call EnterCinematicMode()
	call DebugMsg("Executing Cinematic ON trigger")
	call TriggerExecute(gg_trg_Cinematic_ON)
	call StartFadeOut()
endfunction

//===========================================================================
// Quest creation
//===========================================================================
private function CreateQuests takes nothing returns nothing
	local QuestData q
	local string giverName
	local string infoText
	local string info2Text

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
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	call QuestGiver_SetRequirements(q.id, "", "Find Valeria", "", "", "", "", "", "", "")

	set q = QuestGiver_CreateQuest(QUEST_CRYSTALS_HOPE, Aradion, "normal", 18, null)
	set q.title = "Crystals of Hope"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNINV_Misc_Gem_Crystal_01.blp"
	set q.description = "Aradion wants to study the mana crystals that can be found anywhere in Vanguard Vale.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	// Register automatic item tracking for Mana Crystals
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_MANA_CRYSTAL, 6)

	set q = QuestGiver_CreateQuest(QUEST_FADING_SPARKS, Aradion, "normal", 18, null)
	set q.title = "Fading Sparks"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNHeartOfAszune.blp"
	set q.description = "Aradion wants you to gather essences from the wraiths wandering around the Vanguard Vale. Use provided |cffffff00Tel'anor Rod|r when the wraith is at half health.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	// Register automatic item tracking for Wraith Essences
	call QuestGiver_RegisterItemRequirement(q.id, Aradion, 1, ITEM_WRAITH_ESSENCE, 10)

	set q = QuestGiver_CreateQuest(QUEST_RIFTS_CORRUPTION, Aradion, "normal", 18, null)
	set q.title = "Rifts of Corruption"
	set q.iconPath = "ReplaceableTextures\\CommandButtons\\BTNDizzy.blp"
	set q.description = "Find all rifts scattered around the Vanguard Vale and escort Valeria and Aradion to them. Guard Aradion while he will close the rifts. Both Aradion and Valeria must stay alive.\n\n"
	set q.infoText = infoText
	set q.info2Text = info2Text
	set q.requiredLevel = 15
	call q.setFaction("Elarindor")
	call q.setRewardParams(true, 0, true, 0, false, 0, true, 200, false)
	call q.setReceiverDisplayName(giverName)
	call QuestGiver_SetRequirements(q.id, "", "Find all rifts scattered around the Vanguard Vale and have Aradion close them (Rifts closed 0 / 3)", "Guard Aradion while he closes the rifts", "Both Aradion and Valeria must stay alive", "", "", "", "", "")

	// Test Quest 1: Kill
	/* Note:
	Here seems to be slightly redundant use / we shouldnt need to define similar things twice
	Also, it should be better practice to create quest using QuestGiver_CreateQuest and then apply template to it, 
	instead of using QuestMaster TemplateKill which creates quest internally - 
	this way we have more control and can avoid potential issues with double-creation or mismatched data
	*/
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
	// ORIGINAL (simple text-based):
	set q = QuestMaster_TemplateGoToPlace(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains")
	// set q = QuestMaster_TemplateGoToZone(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains", "", 0, true)
	
	// ENHANCED VERSION (with rect tracking and autocomplete):
	// Uncomment below and replace gg_rct_VerdantPlains with your actual rect name
	// set q = QuestMaster_TemplateGoToPlaceRect(QUEST_TEST_GOTO, Aradion, "normal", 1, "Verdant Plains", gg_rct_VerdantPlains, true)
	// Then add periodic check or region enter trigger to complete when hero enters rect
	// See: QuestMaster_GoToQuests_Guide.md for full examples
	
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
	call CreateQuests()
	call QuestGiver_RegisterSelectionHandler(Aradion, function OnSelected)
endfunction

private function Init takes nothing returns nothing
	set AradionDialogCooldown = CreateTimer()
	call TimerStart(AradionDialogCooldown, 0.00, false, function InitDelayed)
endfunction

//===========================================================================
// Public API for quest status updates and getters
//===========================================================================
public function TriggerRangerMissingUpdate takes nothing returns nothing
	call UpdateQuestRangerMissing()
endfunction

public function GetRiftsCorruptionCounter takes nothing returns integer
	return RiftsCorruptionCounter
endfunction

public function ResetRiftsCorruptionCounter takes nothing returns nothing
	set RiftsCorruptionCounter = 0
endfunction

endlibrary
