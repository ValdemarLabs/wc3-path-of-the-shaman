/**
    ExampleEscortQuest

    Author: Valdemar
    Version: 1.0.0

    Description:
    Example of a custom QuestGiver escort whose NPC leads the player toward a
    destination, waits when the hero falls behind, and may use simple waypoints.

    Credits:

    How to install:
    Copy the relevant pattern into an owning qXXX library after QuestGiver,
    QuestMaster, DialogSystem, and EscortMovement. Replace all example handles.

    API:
    Example only; no reusable public API.

    Workflow:
    1. Register the escort requirement when the quest is accepted.
    2. Use EscortMovement to send the NPC toward its destination.
    3. QuestGiver detects when the NPC reaches the destination region.
    4. Stop movement and unregister the requirement on every exit path.

**/

library ExampleEscortQuest initializer Init requires QuestGiver, QuestMaster, DialogSystem, EscortMovement
globals
	private constant boolean DEBUG = true
	
	// Quest configuration
	private constant string QUEST_SAFE_PASSAGE = "Safe Passage"
	private constant real DIALOG_RANGE = 500.00
	private constant real ESCORT_MAX_DISTANCE = 2000.00  // Wait if hero falls too far behind
	
	// Units and regions
	private unit QuestGiver_NPC = null
	private unit EscortNPC = null
	private rect EscortDestination = null
	
	// Quest data
	private dialog QuestDialog = null
	private timer DialogCooldown = null
	private QuestData SafePassageQuest = 0
endglobals

//===========================================================================
// Debug helpers
//===========================================================================
private function DebugMsg takes string msg returns nothing
	if DEBUG then
		call BJDebugMsg("[ExampleEscort] " + msg)
	endif
endfunction

//===========================================================================
// Quest Accept - Start Escort
//===========================================================================
private function OnAcceptQuestEnd takes nothing returns nothing
	call DebugMsg("Quest accepted, starting escort behavior")
	
	// Accept the quest
	call QuestGiver_AcceptQuestByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC)
	
	// Register escort requirement (NPC must reach destination region)
	// Parameters: questId, questGiver, requirementIndex, escortUnit, destinationRect, destinationName
	call QuestGiver_RegisterEscortRequirement(SafePassageQuest.id, QuestGiver_NPC, 1, EscortNPC, EscortDestination, "Safety Zone")
	
	// Make the escort NPC lead the player toward the destination.
	call EscortMovement_Begin(EscortNPC, udg_Nazgrek, ESCORT_MAX_DISTANCE)
	// Optional road point before Start:
	// call EscortMovement_AddWaypoint(EscortNPC, waypointX, waypointY, 160.00)
	call EscortMovement_Start(EscortNPC, GetRectCenterX(EscortDestination), GetRectCenterY(EscortDestination), 160.00)
	
	call EnableUserControl(true)
endfunction

private function OnAcceptQuest takes nothing returns nothing
	local integer seq
	local unit hero
	
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, QuestGiver_NPC, GetUnitName(QuestGiver_NPC))
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnAcceptQuestEnd)
	
	set hero = QuestGiver_GetAvailableHero(QuestGiver_NPC, DIALOG_RANGE)
	
	// Add dialogue for quest acceptance
	call DialogSystem_AddLine(seq, QuestGiver_NPC, GetUnitName(QuestGiver_NPC), "Please escort me to safety! The roads are dangerous.", "", true)
	call DialogSystem_AddLine(seq, hero, QuestGiver_GetHeroName(hero), "I will protect you on the journey.", "", true)
	
	call DialogSystem_PlaySequence(seq, Player(0), QuestGiver_NPC)
endfunction

//===========================================================================
// Quest Complete - End Escort
//===========================================================================
private function OnCompleteQuestEnd takes nothing returns nothing
	call DebugMsg("Quest completed, stopping escort behavior")
	
	// Complete the quest
	call QuestGiver_CompleteQuestByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC)
	
	// Unregister escort requirement
	call QuestGiver_UnregisterEscortRequirement(SafePassageQuest.id, 1)
	
	// Stop autonomous escort movement
	call EscortMovement_Stop(EscortNPC)
	
	call EnableUserControl(true)
endfunction

private function OnCompleteQuest takes nothing returns nothing
	local integer seq
	local unit hero
	
	call EnableUserControl(false)
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, QuestGiver_NPC, GetUnitName(QuestGiver_NPC))
	call DialogSystem_SetSequenceCallbacks(seq, null, function OnCompleteQuestEnd)
	
	set hero = QuestGiver_GetAvailableHero(QuestGiver_NPC, DIALOG_RANGE)
	
	// Add dialogue for quest completion
	call DialogSystem_AddLine(seq, EscortNPC, GetUnitName(EscortNPC), "Thank you for bringing me here safely!", "", true)
	call DialogSystem_AddLine(seq, hero, QuestGiver_GetHeroName(hero), "You're safe now. All is well.", "", true)
	
	call DialogSystem_PlaySequence(seq, Player(0), QuestGiver_NPC)
endfunction

//===========================================================================
// Quest Fail - Cancel Escort
//===========================================================================
private function OnFailQuest takes nothing returns nothing
	call DebugMsg("Quest failed, canceling escort")
	
	// Fail the quest
	call QuestGiver_FailQuestByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC, "Escort NPC died")
	
	// Unregister escort requirement
	call QuestGiver_UnregisterEscortRequirement(SafePassageQuest.id, 1)
	
	// Stop escort NPC movement and clean route state.
	if EscortNPC != null then
		call EscortMovement_Stop(EscortNPC)
	endif
endfunction

//===========================================================================
// Dialog Building
//===========================================================================
private function BuildDialog takes nothing returns nothing
	local button b
	
	if QuestDialog == null then
		set QuestDialog = DialogSystem_CreateDialog(GetUnitName(QuestGiver_NPC))
	endif
	
	call DialogSystem_ClearDialog(QuestDialog)
	call DialogSystem_SetTitle(QuestDialog, GetUnitName(QuestGiver_NPC))
	
	// Quest accept button
	if QuestGiver_QuestExistsByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) then
		if not QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) and QuestGiver_GetStateByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) == QUEST_STATE_AVAILABLE then
			set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(QuestDialog, QUEST_SAFE_PASSAGE, 1)
			call DialogSystem_BindButtonCode(b, function OnAcceptQuest)
		// Quest complete button (appears when escort reaches destination)
		elseif QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) then
			if QuestGiver_GetStateByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) == QUEST_STATE_READY_TURNIN then
				set b = DialogSystem_AddButtonQuestComplete(QuestDialog, QUEST_SAFE_PASSAGE, 2)
				call DialogSystem_BindButtonCode(b, function OnCompleteQuest)
			endif
		endif
	endif
	
	// Farewell button
	set b = DialogSystem_AddFarewellButton(QuestDialog)
endfunction

//===========================================================================
// Quest Creation
//===========================================================================
private function CreateQuests takes nothing returns nothing
	local string giverName
	local string infoText
	
	call DebugMsg("Creating escort quest")
	set giverName = QuestGiver_GetUnitDisplayName(QuestGiver_NPC)
	set infoText = "|cffffcc00Quest giver:|r " + giverName + "\n"
	
	set SafePassageQuest = QuestGiver_CreateQuest(QUEST_SAFE_PASSAGE, QuestGiver_NPC, "normal", 10)
	set SafePassageQuest.title = "Safe Passage"
	set SafePassageQuest.iconPath = "ReplaceableTextures\\CommandButtons\\BTNPeasant.blp"
	set SafePassageQuest.description = "Escort the NPC to the safety zone.\n\n"
	set SafePassageQuest.infoText = infoText
	set SafePassageQuest.requiredLevel = 1
	call SafePassageQuest.setFaction("Neutral")
	call SafePassageQuest.setRewardParams(true, 0, true, 0, false, 0, true, 100, false)
	
	// Requirement will be registered dynamically when quest is accepted
	// This allows quest text to show escort unit name which may vary
	call QuestGiver_SetRequirements(SafePassageQuest.id, "", "Escort to destination (placeholder)", "", "", "", "", "", "", "")
endfunction

//===========================================================================
// Monitor Escort NPC Death (Auto-fail quest if escort dies)
//===========================================================================
private function OnEscortDeath takes nothing returns nothing
	if GetTriggerUnit() == EscortNPC then
		if QuestGiver_IsQuestDiscoveredByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) and not QuestGiver_IsQuestCompletedByNameAndGiver(QUEST_SAFE_PASSAGE, QuestGiver_NPC) then
			call DebugMsg("Escort NPC died - failing quest")
			call OnFailQuest()
		endif
	endif
endfunction

//===========================================================================
// Init
//===========================================================================
private function InitDelayed takes nothing returns nothing
	local trigger deathTrigger
	
	// Initialize references (replace with your actual units/regions)
	// In a real implementation, these would come from GUI variables
	// set QuestGiver_NPC = udg_YourQuestGiver
	// set EscortNPC = udg_YourEscortNPC
	// set EscortDestination = gg_rct_YourDestinationRegion
	
	if QuestGiver_NPC == null then
		call DebugMsg("ERROR: Quest giver not initialized!")
		return
	endif
	
	if EscortNPC == null then
		call DebugMsg("ERROR: Escort NPC not initialized!")
		return
	endif
	
	if EscortDestination == null then
		call DebugMsg("ERROR: Destination region not initialized!")
		return
	endif
	
	// Register quest giver
	call QuestGiver_Register(QuestGiver_NPC)
	
	// Create quest
	call CreateQuests()
	
	// Set up escort death detection
	set deathTrigger = CreateTrigger()
	call TriggerRegisterUnitEvent(deathTrigger, EscortNPC, EVENT_UNIT_DEATH)
	call TriggerAddAction(deathTrigger, function OnEscortDeath)
	
	call DebugMsg("Initialization complete")
endfunction

private function Init takes nothing returns nothing
	call TimerStart(CreateTimer(), 0.01, false, function InitDelayed)
endfunction

endlibrary
