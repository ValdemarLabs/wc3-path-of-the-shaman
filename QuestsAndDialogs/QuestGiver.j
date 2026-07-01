library QuestGiver initializer Init requires QuestMaster, DialogSystem, HeroItemCheck, CameraControl, Table
//===========================================================================
// QuestGiver
// Base utilities for quest givers and dialog entry helpers.
//===========================================================================

globals
	private constant boolean DEBUG = false
	private Table QuestGiver_SelectHandlers = 0
	private trigger QuestGiver_SelectTrigger = null
	private Table QuestGiver_FirstGreetDone = 0
	private Table QuestGiver_SkipNextGreet = 0
	private Table QuestGiver_GreetOrder = 0
	private dialog QuestGiver_PendingDialog = null
	private player QuestGiver_PendingPlayer = null
	private unit QuestGiver_PendingNPC = null
	private integer QuestGiver_PendingSeq = 0
	unit QuestGiver_SelectedUnit = null
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

	constant integer QUESTGIVER_GREET_DEFAULT = 0
	constant integer QUESTGIVER_GREET_NAZGREK_THEN_NPC = 1
	constant integer QUESTGIVER_GREET_NPC_THEN_NAZGREK = 2
	constant integer QUESTGIVER_GREET_NPC_ONLY = 3
	constant integer QUESTGIVER_GREET_NAZGREK_ONLY = 4
	constant integer QUESTGIVER_GREET_NONE = 5

	// Item requirement tracking
	private constant integer MAX_ITEM_REQUIREMENTS = 100
	private integer ItemReqCount = 0
	private integer array ItemReqQuestId
	private integer array ItemReqIndex
	private integer array ItemReqItemType
	private integer array ItemReqAmount
	private integer array ItemReqCurrent
	private unit array ItemReqGiver
	private trigger ItemPickupTrigger = null
	private integer ItemDropCheckType = 0  // Item type to check after drop delay
	private constant real ITEM_REQUIREMENT_SCAN_INTERVAL = 0.50
	private timer ItemRequirementScanTimer = null

	// Unit kill requirement tracking
	private constant integer MAX_UNIT_REQUIREMENTS = 100
	private integer UnitReqCount = 0
	private integer array UnitReqQuestId
	private integer array UnitReqIndex
	private integer array UnitReqUnitType
	private integer array UnitReqAmount
	private integer array UnitReqCurrent
	private unit array UnitReqGiver
	//private trigger UnitDeathTrigger = null  // No longer needed; handled by UnitDeathEvent

	// Escort requirement tracking
	private constant integer MAX_ESCORT_REQUIREMENTS = 50
	private integer EscortReqCount = 0
	private integer array EscortReqQuestId
	private integer array EscortReqIndex
	private unit array EscortReqUnit          // Unit to escort
	private rect array EscortReqDestination   // Destination region
	private unit array EscortReqGiver
	private boolean array EscortReqComplete
	private trigger EscortRegionTrigger = null
	private constant real ESCORT_CHECK_INTERVAL = 1.00  // How often to check escort progress
	private timer EscortCheckTimer = null

	// TalkTo requirement tracking (manually triggered)
	private constant integer MAX_TALKTO_REQUIREMENTS = 50
	private integer TalkToReqCount = 0
	private integer array TalkToReqQuestId
	private integer array TalkToReqIndex
	private unit array TalkToReqNPC
	private unit array TalkToReqGiver
	private boolean array TalkToReqComplete

	// FindNPC requirement tracking (proximity-based)
	private constant integer MAX_FINDNPC_REQUIREMENTS = 50
	private integer FindNPCReqCount = 0
	private integer array FindNPCReqQuestId
	private integer array FindNPCReqIndex
	private unit array FindNPCReqNPC
	private unit array FindNPCReqGiver
	private boolean array FindNPCReqComplete
	private constant real FINDNPC_CHECK_INTERVAL = 2.00
	private constant real FINDNPC_DISCOVERY_RANGE = 600.00
	private timer FindNPCCheckTimer = null

	// GoToPlace requirement tracking (region-based)
	private constant integer MAX_GOTOPLACE_REQUIREMENTS = 50
	private integer GoToPlaceReqCount = 0
	private integer array GoToPlaceReqQuestId
	private integer array GoToPlaceReqIndex
	private rect array GoToPlaceReqRegion
	private string array GoToPlaceReqName
	private unit array GoToPlaceReqGiver
	private boolean array GoToPlaceReqComplete
	private constant real GOTOPLACE_CHECK_INTERVAL = 1.00
	private timer GoToPlaceCheckTimer = null

	// Reputation requirement tracking
	private constant integer MAX_REP_REQUIREMENTS = 50
	private integer RepReqCount = 0
	private integer array RepReqQuestId
	private integer array RepReqIndex
	private string array RepReqFaction
	private integer array RepReqLevel
	private unit array RepReqGiver
	private boolean array RepReqComplete
	private constant real REP_CHECK_INTERVAL = 5.00
	private timer RepCheckTimer = null

	// Investigate requirement tracking (manually triggered)
	private constant integer MAX_INVESTIGATE_REQUIREMENTS = 50
	private integer InvestigateReqCount = 0
	private integer array InvestigateReqQuestId
	private integer array InvestigateReqIndex
	private string array InvestigateReqDesc
	private unit array InvestigateReqGiver
	private boolean array InvestigateReqComplete
	
	// Companion management - GUI variable mapping
	// These map to GUI variables defined in the World Editor
	// NOTE: Groups are reference types (both variables point to same object)
	//       For value types (integers), we use udg_ variables directly to avoid state mismatch
	private group Companion_Group = null              // Reference to udg_Companion_Group
	private group CompanionFocusNazgrek = null        // Reference to udg_CompanionFocusNazgrek  
	private group CompanionFocusZulkis = null         // Reference to udg_CompanionFocusZulkis
	// CompanionCount: Use udg_CompanionCount directly (no local copy to avoid mismatch)
	private unit array CompanionUnit                  // Separate tracking (not synced with GUI array)
	private Table CompanionIndex = 0                  // Separate tracking (by custom value)
	private Table CompanionIcon = 0                   // Separate tracking (by count index)
	private trigger MultiboardUpdateAddCompanion = null    // Reference to gg_trg_MultiboardUpdate_Add_Companion
	private trigger MultiboardUpdateRemoveCompanion = null // Reference to gg_trg_MultiboardUpdate_Remove_Companion
	private sound RescueSound = null                  // Reference to gg_snd_Rescue
endglobals

//===========================================================================
// Debug helpers
//===========================================================================
private function DebugMsg takes string msg returns nothing
	if DEBUG then
		call BJDebugMsg("[QuestGiver] " + msg)
	endif
endfunction

//===========================================================================
// Selection dispatch
//===========================================================================
private function OnUnitSelected takes nothing returns nothing
	local unit u = GetTriggerUnit()
	local trigger t

	set QuestGiver_SelectedUnit = u
	if u != null and QuestGiver_SelectHandlers != 0 then
		set t = QuestGiver_SelectHandlers.trigger[GetHandleId(u)]
		if t != null then
			call TriggerExecute(t)
		endif
	endif
	set QuestGiver_SelectedUnit = null
endfunction

private function EnsureSelectTrigger takes nothing returns nothing
	if QuestGiver_SelectTrigger == null then
		set QuestGiver_SelectTrigger = CreateTrigger()
		call TriggerRegisterPlayerUnitEvent(QuestGiver_SelectTrigger, Player(0), EVENT_PLAYER_UNIT_SELECTED, null)
		call TriggerAddAction(QuestGiver_SelectTrigger, function OnUnitSelected)
	endif
endfunction

public function RegisterSelectionHandler takes unit u, code handler returns nothing
	local trigger t
	if u == null or handler == null then
		return
	endif
	call EnsureSelectTrigger()
	if QuestGiver_SelectHandlers == 0 then
		set QuestGiver_SelectHandlers = Table.create()
	endif
	set t = QuestGiver_SelectHandlers.trigger[GetHandleId(u)]
	if t != null then
		call DestroyTrigger(t)
	endif
	set t = CreateTrigger()
	call TriggerAddAction(t, handler)
	set QuestGiver_SelectHandlers.trigger[GetHandleId(u)] = t
endfunction

//===========================================================================
// Registration
//===========================================================================
public function SetFirstGreetDone takes unit u, boolean flag returns nothing
	local integer id
	if u == null then
		call DebugMsg("SetFirstGreetDone: u is null!")
		return
	endif
	if QuestGiver_FirstGreetDone == 0 then
		set QuestGiver_FirstGreetDone = Table.create()
	endif
	set id = GetHandleId(u)
	set QuestGiver_FirstGreetDone.integer[id] = B2I(flag)
	call DebugMsg("SetFirstGreetDone: id=" + I2S(id) + ", flag=" + I2S(B2I(flag)))
endfunction

public function SuppressNextGreet takes unit u returns nothing
	local integer id
	if u == null then
		return
	endif
	if QuestGiver_SkipNextGreet == 0 then
		set QuestGiver_SkipNextGreet = Table.create()
	endif
	set id = GetHandleId(u)
	set QuestGiver_SkipNextGreet.boolean[id] = true
endfunction

//===========================================================================
// Companion management
//
// Generic functions for adding/removing companion units to player's party.
// These functions interface with GUI variables and triggers defined in World Editor.
//
// IMPORTANT: Uses udg_CompanionCount directly (no local copy) to prevent state mismatch
//            between GUI triggers and JASS code. This ensures both old GUI-based
//            companion adds and new JASS-based adds work correctly together.
//
// Usage from quest sublibrary (e.g., qValeria.j):
//   call QuestGiver_AddCompanion(udg_Valeria, "ReplaceableTextures\\CommandButtons\\BTNHighElvenArcher.blp")
//   call QuestGiver_RemoveCompanion(udg_Valeria)
//
// Required GUI variables (defined in World Editor):
//   - udg_Companion_Group (unit group)
//   - udg_CompanionFocusNazgrek (unit group)
//   - udg_CompanionFocusZulkis (unit group)
//   - udg_CompanionCount (integer) - used directly, no local copy
//   - gg_trg_MultiboardUpdate_Add_Companion (trigger)
//   - gg_trg_MultiboardUpdate_Remove_Companion (trigger)
//   - gg_snd_Rescue (sound)
//===========================================================================
public function AddCompanion takes unit companionUnit, string companionIcon returns nothing
	local integer customValue
	local integer i = 1
	
	if companionUnit == null then
		return
	endif

	loop
		exitwhen i > udg_CompanionCount
		if udg_CompanionUnit[i] == companionUnit then
			if CompanionIndex != 0 then
				set CompanionIndex.integer[GetUnitUserData(companionUnit)] = i
			endif
			if CompanionIcon != 0 and companionIcon != "" then
				set CompanionIcon.string[i] = companionIcon
			endif
			call DebugMsg("AddCompanion skipped duplicate: " + GetUnitName(companionUnit))
			return
		endif
		set i = i + 1
	endloop
	
	// Play rescue sound if available
	if RescueSound != null then
		call StartSound(RescueSound)
	endif
	
	// Add to companion groups
	if Companion_Group != null then
		call GroupAddUnit(Companion_Group, companionUnit)
	endif
	if CompanionFocusNazgrek != null then
		call GroupAddUnit(CompanionFocusNazgrek, companionUnit)
	endif
	if CompanionFocusZulkis != null then
		call GroupAddUnit(CompanionFocusZulkis, companionUnit)
	endif
	
	// Display join message
	call DisplayTextToForce(bj_FORCE_ALL_PLAYERS, GetUnitName(companionUnit) + " has joined the party!")
	
	// Update companion tracking (use udg_CompanionCount directly to avoid state mismatch)
	set udg_CompanionCount = udg_CompanionCount + 1
	set CompanionUnit[udg_CompanionCount] = companionUnit
	set udg_CompanionUnit[udg_CompanionCount] = companionUnit
	
	// Store index by custom value
	set customValue = GetUnitUserData(companionUnit)
	if CompanionIndex != 0 then
		set CompanionIndex.integer[customValue] = udg_CompanionCount
	endif
	
	// Store icon path
	if CompanionIcon != 0 and companionIcon != "" then
		set CompanionIcon.string[udg_CompanionCount] = companionIcon
	endif
	
	// Trigger multiboard update
	if MultiboardUpdateAddCompanion != null then
		call TriggerExecute(MultiboardUpdateAddCompanion)
	endif
	
	call DebugMsg("Added companion: " + GetUnitName(companionUnit) + " (count=" + I2S(udg_CompanionCount) + ", icon=" + companionIcon + ")")
endfunction

public function GetCompanionIcon takes unit companionUnit returns string
	local integer index = 0
	local integer i = 1

	if companionUnit == null then
		return ""
	endif

	if CompanionIndex != 0 then
		set index = CompanionIndex.integer[GetUnitUserData(companionUnit)]
		if index > 0 and index <= udg_CompanionCount and udg_CompanionUnit[index] == companionUnit then
			if CompanionIcon != 0 then
				return CompanionIcon.string[index]
			endif
			return ""
		endif
	endif

	loop
		exitwhen i > udg_CompanionCount
		if udg_CompanionUnit[i] == companionUnit then
			if CompanionIcon != 0 then
				return CompanionIcon.string[i]
			endif
			return ""
		endif
		set i = i + 1
	endloop

	return ""
endfunction

public function RemoveCompanion takes unit companionUnit returns nothing
	local integer i = 1
	local integer foundIndex = 0
	local integer lastIndex
	local integer movedCustomValue
	if companionUnit == null then
		return
	endif
	
	// Order unit to stop
	call IssueImmediateOrder(companionUnit, "stop")
	
	// Remove from all companion groups
	if Companion_Group != null then
		call GroupRemoveUnit(Companion_Group, companionUnit)
	endif
	if CompanionFocusNazgrek != null then
		call GroupRemoveUnit(CompanionFocusNazgrek, companionUnit)
	endif
	if CompanionFocusZulkis != null then
		call GroupRemoveUnit(CompanionFocusZulkis, companionUnit)
	endif

	set udg_CompanionUnitKicked = companionUnit
	loop
		exitwhen i > udg_CompanionCount
		if udg_CompanionUnit[i] == companionUnit or CompanionUnit[i] == companionUnit then
			set foundIndex = i
			exitwhen true
		endif
		set i = i + 1
	endloop

	if foundIndex > 0 then
		set lastIndex = udg_CompanionCount
		loop
			exitwhen foundIndex >= lastIndex
			set CompanionUnit[foundIndex] = CompanionUnit[foundIndex + 1]
			set udg_CompanionUnit[foundIndex] = udg_CompanionUnit[foundIndex + 1]
			if CompanionIcon != 0 then
				set CompanionIcon.string[foundIndex] = CompanionIcon.string[foundIndex + 1]
			endif
			if udg_CompanionUnit[foundIndex] != null and CompanionIndex != 0 then
				set movedCustomValue = GetUnitUserData(udg_CompanionUnit[foundIndex])
				set CompanionIndex.integer[movedCustomValue] = foundIndex
			endif
			set foundIndex = foundIndex + 1
		endloop

		set CompanionUnit[lastIndex] = null
		set udg_CompanionUnit[lastIndex] = null
		if CompanionIcon != 0 then
			set CompanionIcon.string[lastIndex] = ""
		endif
		set udg_CompanionCount = udg_CompanionCount - 1
	endif

	if CompanionIndex != 0 then
		set CompanionIndex.integer[GetUnitUserData(companionUnit)] = 0
	endif
	
	// Trigger multiboard update
	if MultiboardUpdateRemoveCompanion != null then
		call TriggerExecute(MultiboardUpdateRemoveCompanion)
	endif
	
	call DebugMsg("Removed companion: " + GetUnitName(companionUnit))
endfunction

public function Register takes unit u returns nothing
	call DebugMsg("Register giver id=" + I2S(GetHandleId(u)))
	call QuestMaster_RegisterGiver(u)
	call SetFirstGreetDone(u, false)
endfunction

public function Unregister takes unit u returns nothing
	call DebugMsg("Unregister giver id=" + I2S(GetHandleId(u)))
	call QuestMaster_UnregisterGiver(u)
endfunction

public function UpdateGiverUnitReference takes unit oldUnit, unit newUnit returns nothing
	local integer i
	
	// Update QuestMaster data structures first
	call QuestMaster_UpdateGiverUnitReference(oldUnit, newUnit)
	
	// Update requirement tracking arrays
	set i = 1
	loop
		exitwhen i > ItemReqCount
		if ItemReqGiver[i] == oldUnit then
			set ItemReqGiver[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > UnitReqCount
		if UnitReqGiver[i] == oldUnit then
			set UnitReqGiver[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > EscortReqCount
		if EscortReqGiver[i] == oldUnit then
			set EscortReqGiver[i] = newUnit
		endif
		// Also update escort unit in case the respawned unit is being escorted
		if EscortReqUnit[i] == oldUnit then
			set EscortReqUnit[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > TalkToReqCount
		if TalkToReqGiver[i] == oldUnit then
			set TalkToReqGiver[i] = newUnit
		endif
		// Also update NPC in case the respawned unit is the talk target
		if TalkToReqNPC[i] == oldUnit then
			set TalkToReqNPC[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > FindNPCReqCount
		if FindNPCReqGiver[i] == oldUnit then
			set FindNPCReqGiver[i] = newUnit
		endif
		// Also update NPC in case the respawned unit is the find target
		if FindNPCReqNPC[i] == oldUnit then
			set FindNPCReqNPC[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > GoToPlaceReqCount
		if GoToPlaceReqGiver[i] == oldUnit then
			set GoToPlaceReqGiver[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > RepReqCount
		if RepReqGiver[i] == oldUnit then
			set RepReqGiver[i] = newUnit
		endif
		set i = i + 1
	endloop
	
	set i = 1
	loop
		exitwhen i > InvestigateReqCount
		if InvestigateReqGiver[i] == oldUnit then
			set InvestigateReqGiver[i] = newUnit
		endif
		set i = i + 1
	endloop
endfunction

public function UpdateGiverUnitReferenceByType takes integer unitTypeId, unit newUnit returns nothing
	// First update QuestMaster data structures by type
	call QuestMaster_UpdateGiverUnitReferenceByType(unitTypeId, newUnit)
	
	// Note: Cannot update requirement arrays without old unit reference
	// This is acceptable since most requirements are checked by quest state,
	// and the quest data has been updated by QuestMaster
endfunction

//===========================================================================
// Dialog helpers
//===========================================================================
public function IsUnitAlive takes unit u returns boolean
	if u == null then
		return false
	endif
	return GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD)
endfunction


public function IsWithinRange takes unit a, unit b, real range returns boolean
	local real dx
	local real dy
	if a == null or b == null then
		return false
	endif
	set dx = GetUnitX(a) - GetUnitX(b)
	set dy = GetUnitY(a) - GetUnitY(b)
	return dx*dx + dy*dy <= range*range
endfunction

public function GetAvailableHero takes unit giver, real range returns unit
    local boolean nazgrekOk = false
    local boolean zulkisOk = false
    if udg_Nazgrek != null and IsUnitAlive(udg_Nazgrek) then
        if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
			set nazgrekOk = true
		endif
	endif
    if udg_Zulkis != null and IsUnitAlive(udg_Zulkis) then
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
    if allowZulkis and udg_Zulkis != null and IsUnitAlive(udg_Zulkis) and IsUnitSelected(udg_Zulkis, Player(0)) then
        if range <= 0.00 or IsWithinRange(giver, udg_Zulkis, range) then
            return udg_Zulkis
        endif
    endif
    if allowNazgrek and udg_Nazgrek != null and IsUnitAlive(udg_Nazgrek) and IsUnitSelected(udg_Nazgrek, Player(0)) then
        if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
            return udg_Nazgrek
        endif
    endif
    if allowNazgrek and udg_Nazgrek != null and IsUnitAlive(udg_Nazgrek) then
        if range <= 0.00 or IsWithinRange(giver, udg_Nazgrek, range) then
            return udg_Nazgrek
        endif
    endif
	if allowZulkis and udg_Zulkis != null and IsUnitAlive(udg_Zulkis) then
		if range <= 0.00 or IsWithinRange(giver, udg_Zulkis, range) then
			return udg_Zulkis
		endif
	endif
	return null
endfunction

public function ResolveDialogHero takes unit selectedHero, unit giver, real range, boolean allowNazgrek, boolean allowZulkis returns unit
	if selectedHero != null and IsUnitAlive(selectedHero) then
		return selectedHero
	endif
	return GetAllowedHero(giver, range, allowNazgrek, allowZulkis)
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

private function OnGreetSequenceEnd takes nothing returns nothing
	if QuestGiver_PendingDialog != null and QuestGiver_PendingPlayer != null then
		call DialogSystem_ShowDialog(QuestGiver_PendingDialog, QuestGiver_PendingPlayer)
	endif
	if QuestGiver_PendingSeq != 0 then
		call DialogSystem_ClearSequence(QuestGiver_PendingSeq)
		set QuestGiver_PendingSeq = 0
	endif
	set QuestGiver_PendingDialog = null
	set QuestGiver_PendingPlayer = null
	set QuestGiver_PendingNPC = null
endfunction

public function ShowDialog takes unit npc, player p, dialog d returns nothing
	local integer id
	local boolean skipGreet = false
	local integer seq = 0
	local integer greetOrder = QUESTGIVER_GREET_DEFAULT
	local unit hero
	local string heroName
	if DialogSystem_IsSequenceActive() or QuestGiver_PendingDialog != null then
		call DebugMsg("Show dialog ignored: sequence active or pending")
		return
	endif
	call DebugMsg("Show dialog for giver id=" + I2S(GetHandleId(npc)))
	call DialogSystem_SetContext(npc, p)
	if npc != null and QuestGiver_SkipNextGreet != 0 then
		set id = GetHandleId(npc)
		if QuestGiver_SkipNextGreet.boolean[id] then
			set skipGreet = true
			set QuestGiver_SkipNextGreet.boolean[id] = false
		endif
	endif
	if npc != null and QuestGiver_GreetOrder != 0 and QuestGiver_GreetOrder.has(GetHandleId(npc)) then
		set greetOrder = QuestGiver_GreetOrder.integer[GetHandleId(npc)]
	endif
	if greetOrder == QUESTGIVER_GREET_DEFAULT then
		set greetOrder = QUESTGIVER_GREET_NAZGREK_THEN_NPC
	endif
	if greetOrder == QUESTGIVER_GREET_NONE then
		set skipGreet = true
	endif
	set hero = GetAvailableHero(npc, 0.00)
	set heroName = GetHeroName(hero)
	if not skipGreet and (greetOrder == QUESTGIVER_GREET_NAZGREK_THEN_NPC or greetOrder == QUESTGIVER_GREET_NAZGREK_ONLY) then
		if hero != null then
			call DialogSystem_PickGreetLine(hero, heroName)
			set seq = DialogSystem_CreateSequence()
			call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, GetUnitName(npc))
			call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
		endif
	endif
	if not skipGreet and (greetOrder == QUESTGIVER_GREET_NPC_THEN_NAZGREK or greetOrder == QUESTGIVER_GREET_NPC_ONLY or greetOrder == QUESTGIVER_GREET_NAZGREK_THEN_NPC) then
		call DialogSystem_PickGreetLine(npc, "")
		if seq == 0 then
			set seq = DialogSystem_CreateSequence()
			call DialogSystem_SetSequenceDefaultSpeaker(seq, npc, GetUnitName(npc))
		endif
		call DialogSystem_AddLine(seq, null, "", DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
	endif
	if not skipGreet and (greetOrder == QUESTGIVER_GREET_NPC_THEN_NAZGREK or greetOrder == QUESTGIVER_GREET_NAZGREK_ONLY) then
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
		set QuestGiver_PendingDialog = d
		set QuestGiver_PendingPlayer = p
		set QuestGiver_PendingNPC = npc
		set QuestGiver_PendingSeq = seq
		call DialogSystem_SetSequenceCallbacks(seq, null, function OnGreetSequenceEnd)
		call DialogSystem_PlaySequence(seq, p, npc)
		return
	endif
	call DialogSystem_ShowDialog(d, p)
endfunction

	private function OnFirstGreetSequenceEnd takes nothing returns nothing
	local unit npc = QuestGiver_PendingNPC
	local dialog d = QuestGiver_PendingDialog
	local player p = QuestGiver_PendingPlayer
	call DebugMsg("OnFirstGreetSequenceEnd: callback fired, npc=" + I2S(B2I(npc != null)) + ", dialog=" + I2S(B2I(d != null)))
	if npc != null then
		call SetFirstGreetDone(npc, true)
		call SuppressNextGreet(npc)
		call DebugMsg("OnFirstGreetSequenceEnd: marked as greeted")
	endif
	if npc != null and d != null and p != null then
		call DebugMsg("OnFirstGreetSequenceEnd: showing dialog")
		call DialogSystem_SetContext(npc, p)
		call DialogSystem_ShowDialog(d, p)
	else
		call DebugMsg("OnFirstGreetSequenceEnd: skipping dialog show")
	endif
	set QuestGiver_PendingDialog = null
	set QuestGiver_PendingPlayer = null
	set QuestGiver_PendingNPC = null
endfunction



public function PlayFirstGreetSequence takes unit npc, player p, dialog d, integer seqId returns nothing
	call DebugMsg("PlayFirstGreetSequence: npc=" + I2S(B2I(npc != null)) + ", seqId=" + I2S(seqId))
	if seqId == 0 or npc == null or p == null or d == null then
		return
	endif
	set QuestGiver_PendingNPC = npc
	set QuestGiver_PendingDialog = d
	set QuestGiver_PendingPlayer = p
	set QuestGiver_PendingSeq = seqId
	call DialogSystem_SetSequenceCallbacks(seqId, null, function OnFirstGreetSequenceEnd)
	call DialogSystem_PlaySequence(seqId, p, npc)
endfunction

public function PlayGreetSequence takes integer seqId, unit npc, player p, dialog d returns nothing
	if seqId == 0 or npc == null or p == null or d == null then
		return
	endif
	set QuestGiver_PendingNPC = npc
	set QuestGiver_PendingDialog = d
	set QuestGiver_PendingPlayer = p
	set QuestGiver_PendingSeq = seqId
	call DialogSystem_SetSequenceCallbacks(seqId, null, function OnGreetSequenceEnd)
	call DialogSystem_PlaySequence(seqId, p, npc)
endfunction

public function SetGreetOrder takes unit u, integer order returns nothing
	local integer id
	if u == null then
		return
	endif
	if QuestGiver_GreetOrder == 0 then
		set QuestGiver_GreetOrder = Table.create()
	endif
	set id = GetHandleId(u)
	set QuestGiver_GreetOrder.integer[id] = order
endfunction

public function IsFirstGreetDone takes unit u returns boolean
	local integer id
	local integer result
	if u == null then
		call DebugMsg("IsFirstGreetDone: u is null!")
		return false
	endif
	if QuestGiver_FirstGreetDone == 0 then
		call DebugMsg("IsFirstGreetDone: Table not created!")
		return false
	endif
	set id = GetHandleId(u)
	if not QuestGiver_FirstGreetDone.has(id) then
		call DebugMsg("IsFirstGreetDone: key not in table, id=" + I2S(id))
		return false
	endif
	set result = QuestGiver_FirstGreetDone.integer[id]
	call DebugMsg("IsFirstGreetDone: id=" + I2S(id) + ", result=" + I2S(result))
	return result == 1
endfunction

public function HideDialog takes dialog d, player p returns nothing
	call DebugMsg("Hide dialog")
	call DialogSystem_HideDialog(d, p)
endfunction

public function CloseActiveDialog takes nothing returns nothing
	if DialogSystem_LastDialog == null or DialogSystem_ActivePlayer == null then
		return
	endif
	call DebugMsg("Close active dialog")
	call DialogSystem_HideDialog(DialogSystem_LastDialog, DialogSystem_ActivePlayer)
endfunction

public function BeginDialogSequence takes nothing returns nothing
	call EnableUserControl(false)
	call CloseActiveDialog()
	call ExecuteFunc("TasQuestBox_Hide")
	call ExecuteFunc("MasterUI_HideGameButton")
endfunction

//===========================================================================
// Availability refresh
//===========================================================================
public function RefreshAvailability takes nothing returns nothing
	call DebugMsg("Refresh availability (all givers)")
	call QuestMaster_RefreshAvailability()
endfunction

public function RefreshAvailabilityForGiver takes unit u returns nothing
	call DebugMsg("Refresh availability for giver id=" + I2S(GetHandleId(u)))
	call QuestMaster_RefreshAvailabilityForGiver(u)
endfunction

//===========================================================================
// Common gating helpers
//===========================================================================
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
	return QuestGiver_SelectedUnit
endfunction

public function PassSelectionGate takes unit giver, unit hero, real range, timer cooldown returns boolean
// hero/range checks are optional: 
// if hero is null it skips hero/range validation, and it only checks range when range > 0.00. 
// That makes it flexible per quest giver without changing the call signature.
	if GetSelectedUnit() != giver then
		return false
	endif
	if hero != null then
		if range > 0.00 and not IsWithinRange(giver, hero, range) then
			return false
		endif
	endif
	if cooldown != null and TimerGetRemaining(cooldown) > 0.00 then
		return false
	endif
	return true
endfunction

//===========================================================================
// Quest action wrappers
//===========================================================================
public function AcceptQuest takes integer questId returns nothing
	call DebugMsg("Accept quest id=" + I2S(questId))
	call QuestMaster_Accept(questId)
endfunction

public function DiscoverQuest takes integer questId returns nothing
	call DebugMsg("Discover quest id=" + I2S(questId))
	call QuestMaster_Discover(questId)
endfunction

public function UpdateQuest takes integer questId returns nothing
	call DebugMsg("Update quest id=" + I2S(questId))
	call QuestMaster_Update(questId)
endfunction

public function CompleteQuest takes integer questId returns nothing
	call DebugMsg("Complete quest id=" + I2S(questId))
	call QuestMaster_Complete(questId)
endfunction

public function FailQuest takes integer questId, string reason returns nothing
	call DebugMsg("Fail quest id=" + I2S(questId) + " reason=" + reason)
	call QuestMaster_Fail(questId, reason)
endfunction

public function TurnInQuest takes integer questId returns nothing
	call DebugMsg("Turn in quest id=" + I2S(questId))
	call QuestMaster_TurnIn(questId)
endfunction

public function AbandonQuest takes integer questId returns nothing
	call DebugMsg("Abandon quest id=" + I2S(questId))
	call QuestMaster_Abandon(questId)
endfunction

public function AcceptQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call AcceptQuest(q.id)
	endif
endfunction

public function DiscoverQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call DiscoverQuest(q.id)
	endif
endfunction

public function UpdateQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call UpdateQuest(q.id)
	endif
endfunction

public function CompleteQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call CompleteQuest(q.id)
	endif
endfunction

public function FailQuestByNameAndGiver takes string questName, unit questGiver, string reason returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call FailQuest(q.id, reason)
	endif
endfunction

public function TurnInQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call TurnInQuest(q.id)
	endif
endfunction

public function AbandonQuestByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call AbandonQuest(q.id)
	endif
endfunction

//===========================================================================
// Quest creation + setup wrappers
//===========================================================================
public function CreateQuest takes string questName, unit questGiver, string questType, integer questLevel, unit questReceiver returns QuestData
	return QuestMaster_Create(questName, questGiver, questType, questLevel, questReceiver)
endfunction

public function ApplyQuestMetadata takes QuestData q, string title, string iconPath, string description, string infoText, string info2Text, integer requiredLevel, boolean useAllowedHeroesForLevelCheck, boolean allowNazgrek, boolean allowZulkis, string faction, string receiverDisplayName returns nothing
	if q == 0 then
		return
	endif
	set q.title = title
	set q.iconPath = iconPath
	set q.description = description
	set q.infoText = infoText
	set q.info2Text = info2Text
	call q.setRequiredLevel(requiredLevel)
	if useAllowedHeroesForLevelCheck then
		call q.setAllowedHeroesForLevelCheck(allowNazgrek, allowZulkis)
	endif
	if faction != "" then
		call q.setFaction(faction)
	endif
	if receiverDisplayName != "" then
		call q.setReceiverDisplayName(receiverDisplayName)
	endif
endfunction

public function SetRequirements takes integer questId, string heading, string r1, string r2, string r3, string r4, string r5, string r6, string r7, string r8 returns nothing
	call QuestMaster_SetRequirements(questId, heading, r1, r2, r3, r4, r5, r6, r7, r8)
endfunction

public function SetRequirement takes integer questId, integer index, string text returns nothing
	call QuestMaster_SetRequirement(questId, index, text)
endfunction

public function AddRequirement takes integer questId, integer index, string text returns nothing
	call QuestMaster_AddRequirement(questId, index, text)
endfunction

public function SetRequirementCompleted takes integer questId, integer index, boolean flag returns nothing
	call QuestMaster_SetRequirementCompleted(questId, index, flag)
endfunction

public function UpdateRequirementText takes integer questId, integer index, string text returns nothing
	call QuestMaster_UpdateRequirementText(questId, index, text)
endfunction

public function MarkReturnRequirementCompleted takes integer questId returns nothing
	call QuestMaster_MarkReturnRequirementCompleted(questId)
endfunction

public function MarkReturnRequirementCompletedByNameAndGiver takes string questName, unit questGiver returns nothing
	call QuestMaster_MarkReturnRequirementCompletedByNameAndGiver(questName, questGiver)
endfunction

public function SetGiverDisplayName takes integer questId, string displayName returns nothing
	call QuestMaster_SetGiverDisplayName(questId, displayName)
endfunction

public function SetReceiverDisplayName takes integer questId, string displayName returns nothing
	call QuestMaster_SetReceiverDisplayName(questId, displayName)
endfunction

public function SetGiverDisplayNameByNameAndGiver takes string questName, unit questGiver, string displayName returns nothing
	call QuestMaster_SetGiverDisplayNameByNameAndGiver(questName, questGiver, displayName)
endfunction

public function SetReceiverDisplayNameByNameAndGiver takes string questName, unit questGiver, string displayName returns nothing
	call QuestMaster_SetReceiverDisplayNameByNameAndGiver(questName, questGiver, displayName)
endfunction

public function SetAllowedHeroesForLevelCheck takes integer questId, boolean allowNazgrek, boolean allowZulkis returns nothing
	call QuestMaster_SetAllowedHeroesForLevelCheck(questId, allowNazgrek, allowZulkis)
endfunction

public function SetAllowedHeroesForLevelCheckByNameAndGiver takes string questName, unit questGiver, boolean allowNazgrek, boolean allowZulkis returns nothing
	call QuestMaster_SetAllowedHeroesForLevelCheckByNameAndGiver(questName, questGiver, allowNazgrek, allowZulkis)
endfunction

public function AddRequiredCompletedQuest takes integer questId, string prereqQuestName, unit prereqQuestGiver returns nothing
	call QuestMaster_AddRequiredCompletedQuest(questId, prereqQuestName, prereqQuestGiver)
endfunction

public function AddRequiredCompletedQuestByNameAndGiver takes string questName, unit questGiver, string prereqQuestName, unit prereqQuestGiver returns nothing
	call QuestMaster_AddRequiredCompletedQuestByNameAndGiver(questName, questGiver, prereqQuestName, prereqQuestGiver)
endfunction

//===========================================================================
// Quest lookup/state wrappers
//===========================================================================
public function GetByNameAndGiver takes string questName, unit questGiver returns QuestData
	return QuestMaster_GetByNameAndGiver(questName, questGiver)
endfunction

public function QuestExistsByNameAndGiver takes string questName, unit questGiver returns boolean
	return QuestMaster_GetByNameAndGiver(questName, questGiver) != 0
endfunction

public function IsQuestDiscoveredByNameAndGiver takes string questName, unit questGiver returns boolean
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return false
	endif
	return q.discovered
endfunction

public function IsQuestCompletedByNameAndGiver takes string questName, unit questGiver returns boolean
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return false
	endif
	return q.completed
endfunction

public function IsQuestFailedByNameAndGiver takes string questName, unit questGiver returns boolean
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return false
	endif
	return q.failed
endfunction

public function GetStateByNameAndGiver takes string questName, unit questGiver returns integer
	return QuestMaster_GetStateByNameAndGiver(questName, questGiver)
endfunction

public function SetStateByNameAndGiver takes string questName, unit questGiver, integer newState returns nothing
	call QuestMaster_SetStateByNameAndGiver(questName, questGiver, newState)
endfunction

//===========================================================================
// Quest icon wrappers
//===========================================================================
public function CreateDummyQuestIcon takes unit u, string questType, integer questState returns nothing
	call QuestMaster_CreateDummyQuestIcon(u, questType, questState)
endfunction

public function RemoveDummyQuestIcon takes unit u returns nothing
	call QuestMaster_RemoveDummyQuestIcon(u)
endfunction

//===========================================================================
// Generic sequence-end handler builder
//===========================================================================
public function HandleSequenceEnd takes unit giver, timer cooldownTimer, real cooldownDuration, boolean stopCamera, real cameraStopDuration, boolean useCamera, boolean reopenDialog returns nothing
	// Generic handler for end of quest accept/complete/fail/farewell sequences
	call CloseActiveDialog()
	
	if cooldownTimer != null and cooldownDuration > 0.00 then
		call StartCooldown(cooldownTimer, cooldownDuration)
	endif
	
	if stopCamera and useCamera then
		call DialogSystem_StopDialogCamera(Player(0), cameraStopDuration, true)
	endif
	
	// Note: reopenDialog would require storing additional context; 
	// for now this is a placeholder for future enhancement
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

private function FinishDialogExitTransition takes nothing returns nothing
	local timer t = GetExpiredTimer()

	call CinematicFadeBJ(bj_CINEFADETYPE_FADEIN, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	call HandleSequenceEnd(TransitionGiver, TransitionCooldownTimer, TransitionCooldownDuration, TransitionStopCamera, TransitionCameraStopDuration, TransitionUseCamera, false)
	if TransitionRunCinematicTrigger then
		call TriggerExecute(gg_trg_Cinematic_OFF)
	endif
	if TransitionUseCinematicMode then
		call CinematicModeBJ(false, GetPlayersAll())
	endif
	if TransitionRunCinematicTrigger or TransitionUseCinematicMode then
		call ExecuteFunc("MasterUI_ShowGameButton")
	endif
	call EnableUserControl(true)
	if TransitionHero != null and GetWidgetLife(TransitionHero) > 0.405 and not IsUnitType(TransitionHero, UNIT_TYPE_DEAD) then
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

	call DestroyTimer(t)
	set t = null
	call TimerStart(nextTimer, 1.0, false, function FinishDialogExitTransition)
	set nextTimer = null
endfunction

public function StartDialogExitTransition takes unit giver, unit restoreHero, timer cooldownTimer, real cooldownDuration, boolean stopCamera, real cameraStopDuration, boolean useCamera, boolean runCinematicTrigger, boolean useCinematicMode returns nothing
	local timer t = CreateTimer()

	set TransitionGiver = giver
	set TransitionHero = restoreHero
	set TransitionCooldownTimer = cooldownTimer
	set TransitionCooldownDuration = cooldownDuration
	set TransitionStopCamera = stopCamera
	set TransitionCameraStopDuration = cameraStopDuration
	set TransitionUseCamera = useCamera
	set TransitionRunCinematicTrigger = runCinematicTrigger
	set TransitionUseCinematicMode = useCinematicMode

	call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	call TimerStart(t, 1.0, false, function ContinueDialogExitTransition)
	set t = null
endfunction

private function ExecuteDialogEntryContinue takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local string continueFuncName = TransitionContinueFuncName

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
endfunction

public function StartDialogEntryTransition takes unit giver, unit hero, integer moveMode, real moveOffset, real moveAngle, boolean runCinematicTrigger, boolean useCamera, real cameraDist, real cameraZOffset, real cameraAngle, real cameraRotOffset, real cameraFarZ, real cameraFov, real cameraBlockRadius, boolean cameraBlockCheck, boolean useCinematicMode, string continueFuncName returns nothing
	local timer t = CreateTimer()

	set TransitionGiver = giver
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
		call ExecuteFunc("MasterUI_HideGameButton")
	endif
	if useCinematicMode then
		call CinematicModeBJ(true, GetPlayersAll())
	endif

	call CinematicFadeBJ(bj_CINEFADETYPE_FADEOUT, 1.0, "ReplaceableTextures\\CameraMasks\\Black_mask.blp", 0, 0, 0, 0)
	call TimerStart(t, 1.0, false, function ContinueDialogEntryTransition)
	set t = null
endfunction

//===========================================================================
// Generic accept/complete sequence builders
//===========================================================================
public function CreateBaseSequence takes unit giver, string giverName returns integer
	local integer seq
	set seq = DialogSystem_CreateSequence()
	call DialogSystem_SetSequenceDefaultSpeaker(seq, giver, giverName)
	return seq
endfunction

public function CreateAcceptSequence takes unit giver, string giverName, unit hero, string heroName, real dialogRange, boolean allowNazgrek, boolean allowZulkis returns integer
	local integer seq
	set seq = CreateBaseSequence(giver, giverName)
	
	// Auto-resolve hero if not provided
	if hero == null then
		set hero = GetAllowedHero(giver, dialogRange, allowNazgrek, allowZulkis)
		set heroName = GetHeroName(hero)
	endif
	
	// 1) Player hero accepts
	if hero != null then
		call DialogSystem_PickAcceptLine(hero, heroName)
		call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
	endif
	
	// 2) NPC quest giver responds
	call DialogSystem_PickAcceptLine(giver, giverName)
	call DialogSystem_AddLine(seq, giver, giverName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
	
	return seq
endfunction

public function CreateCompleteSequence takes unit giver, string giverName returns integer
	return CreateBaseSequence(giver, giverName)
endfunction

public function CreateFarewellSequence takes unit giver, string giverName, unit hero, string heroName, real dialogRange, boolean allowNazgrek, boolean allowZulkis returns integer
	local integer seq
	set seq = CreateBaseSequence(giver, giverName)
	
	// Auto-resolve hero if not provided
	if hero == null then
		set hero = GetAllowedHero(giver, dialogRange, allowNazgrek, allowZulkis)
		set heroName = GetHeroName(hero)
	endif
	
	// 1) Player hero says farewell
	if hero != null then
		call DialogSystem_PickFarewellLine(hero, heroName)
		call DialogSystem_AddLine(seq, hero, heroName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
	endif
	
	// 2) NPC responds
	call DialogSystem_PickFarewellLine(giver, "")
	call DialogSystem_AddLine(seq, giver, giverName, DialogSystem_PickedText, DialogSystem_PickedSound, DialogSystem_PickedSoundAtUnit)
	
	return seq
endfunction

//===========================================================================
// Item requirement tracking
//===========================================================================
private function CheckItemProgress takes integer itemTypeId returns nothing
	local integer i = 1
	local integer current
	local QuestData q
	local string reqText
	local boolean foundMatch = false

	call DebugMsg("CheckItemProgress: Checking item type " + I2S(itemTypeId) + " (" + GetObjectName(itemTypeId) + ")")
	call DebugMsg("CheckItemProgress: Total registered item requirements: " + I2S(ItemReqCount))

	loop
		exitwhen i > ItemReqCount
		if ItemReqItemType[i] == itemTypeId then
			set foundMatch = true
			call DebugMsg("CheckItemProgress: Found matching requirement at index " + I2S(i))
			call DebugMsg("CheckItemProgress: QuestId=" + I2S(ItemReqQuestId[i]) + ", ReqIndex=" + I2S(ItemReqIndex[i]) + ", Amount=" + I2S(ItemReqAmount[i]))
			
			set q = QuestMaster_GetById(ItemReqQuestId[i])
			if q == 0 then
				call DebugMsg("CheckItemProgress: ERROR - Quest not found for id " + I2S(ItemReqQuestId[i]))
			elseif not q.active then
				call DebugMsg("CheckItemProgress: Quest '" + q.name + "' exists but is NOT active (discovered=" + I2S(B2I(q.discovered)) + ", active=" + I2S(B2I(q.active)) + ")")
			elseif q.completed or q.failed then
				// Don't track items for already completed or failed quests
				call DebugMsg("CheckItemProgress: Quest '" + q.name + "' already completed/failed, skipping tracking")
			elseif QuestMaster_GetStateByNameAndGiver(q.name, ItemReqGiver[i]) == QUEST_STATE_READY_TURNIN and HeroItemCheckBoth(itemTypeId, ItemReqAmount[i]) then
				// Don't track if requirement is already complete (quest ready for turn-in with all items present)
				call DebugMsg("CheckItemProgress: Quest '" + q.name + "' requirement already complete, skipping tracking")
			else
				call DebugMsg("CheckItemProgress: Quest '" + q.name + "' is active, checking progress...")
				// Use GetDInvItemChargesByType for progress count (handles both vanilla + DInventory)
				set current = GetDInvItemChargesByType(udg_Nazgrek, itemTypeId) + GetDInvItemChargesByType(udg_Zulkis, itemTypeId)
				call DebugMsg("CheckItemProgress: Current count=" + I2S(current) + ", Previous count=" + I2S(ItemReqCurrent[i]) + ", Required=" + I2S(ItemReqAmount[i]))
				
				if current != ItemReqCurrent[i] then
					call DebugMsg("CheckItemProgress: Count changed! Updating requirement text and quest log...")
					set ItemReqCurrent[i] = current
					set reqText = "Gather " + I2S(ItemReqAmount[i]) + " " + GetObjectName(itemTypeId) + " (" + I2S(current) + "/" + I2S(ItemReqAmount[i]) + ")"
					call DebugMsg("CheckItemProgress: New requirement text: '" + reqText + "'")
					call QuestMaster_UpdateRequirementText(ItemReqQuestId[i], ItemReqIndex[i], reqText)
					call DebugMsg("CheckItemProgress: UpdateRequirementText called")
					
					// Use HeroItemCheckBoth for completion check (tested, atomic operation)
					if HeroItemCheckBoth(itemTypeId, ItemReqAmount[i]) then
						call DebugMsg("CheckItemProgress: Requirement COMPLETE! Setting quest to ready for turn-in")
						call QuestMaster_SetRequirementCompleted(ItemReqQuestId[i], ItemReqIndex[i], true)
						call QuestMaster_SetStateByNameAndGiver(q.name, ItemReqGiver[i], QUEST_STATE_READY_TURNIN)
						// Add "Return to questgiver" requirement when quest complete
						call q.addReturnRequirement()
					else
						// If quest was previously ready for turn-in, revert to IN_PROGRESS
						// Don't call SetRequirementCompleted(false) as it triggers "failed" messages
						if QuestMaster_GetStateByNameAndGiver(q.name, ItemReqGiver[i]) == QUEST_STATE_READY_TURNIN then
							call DebugMsg("CheckItemProgress: Items dropped below requirement - reverting quest to IN_PROGRESS")
							call QuestMaster_SetStateByNameAndGiver(q.name, ItemReqGiver[i], QUEST_STATE_IN_PROGRESS)
							// Mark "Return to questgiver" requirement as incomplete using native function (no message)
							if q.hasReturnReq and q.returnReqIndex > 0 then
								if q.returnReqIndex == 1 and q.req1 != null then
									call QuestItemSetCompleted(q.req1, false)
								elseif q.returnReqIndex == 2 and q.req2 != null then
									call QuestItemSetCompleted(q.req2, false)
								elseif q.returnReqIndex == 3 and q.req3 != null then
									call QuestItemSetCompleted(q.req3, false)
								elseif q.returnReqIndex == 4 and q.req4 != null then
									call QuestItemSetCompleted(q.req4, false)
								elseif q.returnReqIndex == 5 and q.req5 != null then
									call QuestItemSetCompleted(q.req5, false)
								elseif q.returnReqIndex == 6 and q.req6 != null then
									call QuestItemSetCompleted(q.req6, false)
								elseif q.returnReqIndex == 7 and q.req7 != null then
									call QuestItemSetCompleted(q.req7, false)
								elseif q.returnReqIndex == 8 and q.req8 != null then
									call QuestItemSetCompleted(q.req8, false)
								endif
							endif
						else
							call DebugMsg("CheckItemProgress: Requirement still in progress (" + I2S(current) + "/" + I2S(ItemReqAmount[i]) + ")")
						endif
					endif
				else
					call DebugMsg("CheckItemProgress: Count unchanged, skipping update")
				endif
			endif
		endif
		set i = i + 1
	endloop
	
	if not foundMatch then
		call DebugMsg("CheckItemProgress: No registered requirements found for item type " + I2S(itemTypeId))
	endif
endfunction

private function RefreshAllItemRequirements takes nothing returns nothing
	local integer i = 1

	loop
		exitwhen i > ItemReqCount
		call CheckItemProgress(ItemReqItemType[i])
		set i = i + 1
	endloop
endfunction

public function RefreshItemRequirementsForQuest takes integer questId returns nothing
	local integer i = 1

	loop
		exitwhen i > ItemReqCount
		if ItemReqQuestId[i] == questId then
			call CheckItemProgress(ItemReqItemType[i])
		endif
		set i = i + 1
	endloop
endfunction

private function OnItemRequirementScan takes nothing returns nothing
	if ItemReqCount <= 0 then
		if ItemRequirementScanTimer != null then
			call PauseTimer(ItemRequirementScanTimer)
		endif
		return
	endif
	call RefreshAllItemRequirements()
endfunction

private function StartItemRequirementScan takes nothing returns nothing
	if ItemRequirementScanTimer == null then
		set ItemRequirementScanTimer = CreateTimer()
	endif
	call TimerStart(ItemRequirementScanTimer, ITEM_REQUIREMENT_SCAN_INTERVAL, true, function OnItemRequirementScan)
endfunction

private function StopItemRequirementScanIfEmpty takes nothing returns nothing
	if ItemReqCount <= 0 and ItemRequirementScanTimer != null then
		call PauseTimer(ItemRequirementScanTimer)
	endif
endfunction

private function OnItemPickup takes nothing returns nothing
	local item pickedItem
	local integer itemTypeId

	if GetTriggerEventId() != EVENT_PLAYER_UNIT_PICKUP_ITEM then
		call DebugMsg("OnItemPickup: wrong event")
		return
	endif
	if GetOwningPlayer(GetManipulatingUnit()) != Player(0) then
		call DebugMsg("OnItemPickup: not player 0, player=" + I2S(GetPlayerId(GetOwningPlayer(GetManipulatingUnit()))))
		return
	endif

	set pickedItem = GetManipulatedItem()
	if pickedItem == null then
		call DebugMsg("OnItemPickup: no item found in trigger") 
		return
	endif

	set itemTypeId = GetItemTypeId(pickedItem)
	call DebugMsg("OnItemPickup: Player picked up item type " + I2S(itemTypeId) + " (" + GetObjectName(itemTypeId) + "), calling CheckItemProgress...")
	call CheckItemProgress(itemTypeId)
	call DebugMsg("OnItemPickup: CheckItemProgress completed")
endfunction

private function OnItemDropDelayed takes nothing returns nothing
	local timer t = GetExpiredTimer()
	call DebugMsg("OnItemDropDelayed: Checking item type " + I2S(ItemDropCheckType) + " after drop delay")
	call CheckItemProgress(ItemDropCheckType)
	call DebugMsg("OnItemDropDelayed: CheckItemProgress completed")
	call DestroyTimer(t)
	set t = null
endfunction

private function OnItemDrop takes nothing returns nothing
	local item droppedItem
	local integer itemTypeId
	local timer t

	if GetTriggerEventId() != EVENT_PLAYER_UNIT_DROP_ITEM then
		call DebugMsg("OnItemDrop: wrong event")
		return
	endif
	if GetOwningPlayer(GetManipulatingUnit()) != Player(0) then
		call DebugMsg("OnItemDrop: not player 0, player=" + I2S(GetPlayerId(GetOwningPlayer(GetManipulatingUnit()))))
		return
	endif

	set droppedItem = GetManipulatedItem()
	if droppedItem == null then
		call DebugMsg("OnItemDrop: no item found in trigger")
		return
	endif

	set itemTypeId = GetItemTypeId(droppedItem)
	call DebugMsg("OnItemDrop: Player dropped item type " + I2S(itemTypeId) + " (" + GetObjectName(itemTypeId) + "), scheduling delayed check...")
	
	// Delay the check by 0.01 seconds to allow the game engine to remove the item from inventory
	set ItemDropCheckType = itemTypeId
	set t = CreateTimer()
	call TimerStart(t, 0.01, false, function OnItemDropDelayed)
	set t = null
endfunction

public function RegisterItemRequirement takes integer questId, unit questGiver, integer reqIndex, integer itemTypeId, integer amount returns nothing
	local string reqText
	local QuestData q

	if ItemReqCount >= MAX_ITEM_REQUIREMENTS then
		call DebugMsg("RegisterItemRequirement: Max item requirements reached!")
		return
	endif

	set ItemReqCount = ItemReqCount + 1
	set ItemReqQuestId[ItemReqCount] = questId
	set ItemReqGiver[ItemReqCount] = questGiver
	set ItemReqIndex[ItemReqCount] = reqIndex
	set ItemReqItemType[ItemReqCount] = itemTypeId
	set ItemReqAmount[ItemReqCount] = amount
	set ItemReqCurrent[ItemReqCount] = 0

	set reqText = "Gather " + I2S(amount) + " " + GetObjectName(itemTypeId) + " (0/" + I2S(amount) + ")"
	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.updateRequirementText(reqIndex, reqText)
	endif

	if ItemPickupTrigger == null then
		set ItemPickupTrigger = CreateTrigger()
		call TriggerRegisterPlayerUnitEvent(ItemPickupTrigger, Player(0), EVENT_PLAYER_UNIT_PICKUP_ITEM, null)
		call TriggerRegisterPlayerUnitEvent(ItemPickupTrigger, Player(0), EVENT_PLAYER_UNIT_DROP_ITEM, null)
		call TriggerAddAction(ItemPickupTrigger, function OnItemPickup)
		call TriggerAddAction(ItemPickupTrigger, function OnItemDrop)
	endif

	call DebugMsg("Registered item requirement: quest=" + I2S(questId) + ", item=" + GetObjectName(itemTypeId) + ", amount=" + I2S(amount))
	call StartItemRequirementScan()
	call RefreshItemRequirementsForQuest(questId)
endfunction

public function UnregisterItemRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1
	local integer j

	loop
		exitwhen i > ItemReqCount
		if ItemReqQuestId[i] == questId and ItemReqIndex[i] == reqIndex then
			// Shift remaining requirements down
			set j = i
			loop
				exitwhen j >= ItemReqCount
				set ItemReqQuestId[j] = ItemReqQuestId[j + 1]
				set ItemReqGiver[j] = ItemReqGiver[j + 1]
				set ItemReqIndex[j] = ItemReqIndex[j + 1]
				set ItemReqItemType[j] = ItemReqItemType[j + 1]
				set ItemReqAmount[j] = ItemReqAmount[j + 1]
				set ItemReqCurrent[j] = ItemReqCurrent[j + 1]
				set j = j + 1
			endloop
			set ItemReqCount = ItemReqCount - 1
			call StopItemRequirementScanIfEmpty()
			return
		endif
		set i = i + 1
	endloop
endfunction

public function ValidateItemRequirements takes integer questId returns boolean
	// Validates that all item requirements for a quest are currently met
	// Returns true if all requirements satisfied, false otherwise
	local integer i = 1
	local boolean allMet = true
	local integer foundReqs = 0
	
	loop
		exitwhen i > ItemReqCount
		if ItemReqQuestId[i] == questId then
			set foundReqs = foundReqs + 1
			// Check if this specific requirement is met
			if not HeroItemCheckBoth(ItemReqItemType[i], ItemReqAmount[i]) then
				call DebugMsg("ValidateItemRequirements: Quest " + I2S(questId) + " requirement " + I2S(ItemReqIndex[i]) + " NOT met (need " + I2S(ItemReqAmount[i]) + " " + GetObjectName(ItemReqItemType[i]) + ")")
				set allMet = false
			endif
		endif
		set i = i + 1
	endloop
	
	if foundReqs > 0 then
		call DebugMsg("ValidateItemRequirements: Quest " + I2S(questId) + " has " + I2S(foundReqs) + " item requirements, all met: " + I2S(B2I(allMet)))
	endif
	
	return allMet
endfunction

public function AddAvailableQuestAcceptButton takes dialog d, string questName, unit questGiver, integer actionId, code actionFunc, boolean noAutoPlay, boolean allowFailedRetry returns boolean
	local button b = null
	if not QuestExistsByNameAndGiver(questName, questGiver) then
		return false
	endif
	if GetStateByNameAndGiver(questName, questGiver) != QUEST_STATE_AVAILABLE then
		return false
	endif
	if IsQuestDiscoveredByNameAndGiver(questName, questGiver) and not (allowFailedRetry and IsQuestFailedByNameAndGiver(questName, questGiver)) then
		return false
	endif
	if noAutoPlay then
		set b = DialogSystem_AddButtonQuestAcceptNoAutoPlay(d, questName, actionId)
	else
		set b = DialogSystem_AddButtonQuestAccept(d, questName, actionId)
	endif
	if b == null then
		return false
	endif
	call DialogSystem_BindButtonCode(b, actionFunc)
	set b = null
	return true
endfunction

public function AddFailedQuestButton takes dialog d, string questName, unit questGiver, integer actionId, code actionFunc returns boolean
	local button b = null
	if not QuestExistsByNameAndGiver(questName, questGiver) then
		return false
	endif
	if not IsQuestDiscoveredByNameAndGiver(questName, questGiver) or not IsQuestFailedByNameAndGiver(questName, questGiver) then
		return false
	endif
	set b = DialogSystem_AddButtonQuestFailed(d, questName, actionId)
	if b == null then
		return false
	endif
	call DialogSystem_BindButtonCode(b, actionFunc)
	set b = null
	return true
endfunction

public function AddReadyQuestCompleteButton takes dialog d, string questName, unit questGiver, integer actionId, code actionFunc, boolean validateItems returns boolean
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	local button b = null
	if q == 0 then
		return false
	endif
	if not q.discovered or q.completed or q.state != QUEST_STATE_READY_TURNIN then
		return false
	endif
	if validateItems and not ValidateItemRequirements(q.id) then
		return false
	endif
	set b = DialogSystem_AddButtonQuestComplete(d, questName, actionId)
	if b == null then
		return false
	endif
	call DialogSystem_BindButtonCode(b, actionFunc)
	set b = null
	return true
endfunction

public function CompleteItemRequirements takes integer questId returns nothing
	// Marks all item requirements for a quest as complete
	// Call this when removing items during quest completion
	local integer i = 1
	local integer completed = 0
	
	loop
		exitwhen i > ItemReqCount
		if ItemReqQuestId[i] == questId then
			call DebugMsg("CompleteItemRequirements: Marking requirement " + I2S(ItemReqIndex[i]) + " as complete for quest " + I2S(questId))
			call QuestMaster_SetRequirementCompleted(questId, ItemReqIndex[i], true)
			set completed = completed + 1
		endif
		set i = i + 1
	endloop
	
	if completed > 0 then
		call DebugMsg("CompleteItemRequirements: Marked " + I2S(completed) + " item requirements as complete for quest " + I2S(questId))
	endif
endfunction

//===========================================================================
// Unit kill requirement tracking
//===========================================================================
private function CheckUnitKillProgress takes integer unitTypeId returns nothing
	local integer i = 1
	local QuestData q
	local string reqText

	loop
		exitwhen i > UnitReqCount
		if UnitReqUnitType[i] == unitTypeId then
			set q = QuestMaster_GetById(UnitReqQuestId[i])
			if q != 0 and q.active then
				set UnitReqCurrent[i] = UnitReqCurrent[i] + 1
				set reqText = "Kill " + I2S(UnitReqAmount[i]) + " " + GetObjectName(unitTypeId) + " (" + I2S(UnitReqCurrent[i]) + "/" + I2S(UnitReqAmount[i]) + ")"
				call QuestMaster_UpdateRequirementText(UnitReqQuestId[i], UnitReqIndex[i], reqText)
				if UnitReqCurrent[i] >= UnitReqAmount[i] then
					call QuestMaster_SetRequirementCompleted(UnitReqQuestId[i], UnitReqIndex[i], true)
					call QuestMaster_SetStateByNameAndGiver(q.name, UnitReqGiver[i], QUEST_STATE_READY_TURNIN)
					// Add "Return to questgiver" requirement when quest complete
					call q.addReturnRequirement()
				endif
			endif
		endif
		set i = i + 1
	endloop
endfunction

private function OnUnitDeath takes nothing returns nothing
	local unit killed
	local integer unitTypeId

	if GetTriggerEventId() != EVENT_PLAYER_UNIT_DEATH then
		return
	endif

	set killed = GetTriggerUnit()
	if killed == null then
		return
	endif

	set unitTypeId = GetUnitTypeId(killed)
	call CheckUnitKillProgress(unitTypeId)
endfunction

public function RegisterUnitKillRequirement takes integer questId, unit questGiver, integer reqIndex, integer unitTypeId, integer amount returns nothing
	local string reqText
	local QuestData q

	if UnitReqCount >= MAX_UNIT_REQUIREMENTS then
		call DebugMsg("RegisterUnitKillRequirement: Max unit requirements reached!")
		return
	endif

	set UnitReqCount = UnitReqCount + 1
	set UnitReqQuestId[UnitReqCount] = questId
	set UnitReqGiver[UnitReqCount] = questGiver
	set UnitReqIndex[UnitReqCount] = reqIndex
	set UnitReqUnitType[UnitReqCount] = unitTypeId
	set UnitReqAmount[UnitReqCount] = amount
	set UnitReqCurrent[UnitReqCount] = 0

	set reqText = "Kill " + I2S(amount) + " " + GetObjectName(unitTypeId) + " (0/" + I2S(amount) + ")"
	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	call DebugMsg("Registered unit kill requirement: quest=" + I2S(questId) + ", unit=" + GetObjectName(unitTypeId) + ", amount=" + I2S(amount))
endfunction

public function UnregisterUnitKillRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1
	local integer j

	loop
		exitwhen i > UnitReqCount
		if UnitReqQuestId[i] == questId and UnitReqIndex[i] == reqIndex then
			// Shift remaining requirements down
			set j = i
			loop
				exitwhen j >= UnitReqCount
				set UnitReqQuestId[j] = UnitReqQuestId[j + 1]
				set UnitReqGiver[j] = UnitReqGiver[j + 1]
				set UnitReqIndex[j] = UnitReqIndex[j + 1]
				set UnitReqUnitType[j] = UnitReqUnitType[j + 1]
				set UnitReqAmount[j] = UnitReqAmount[j + 1]
				set UnitReqCurrent[j] = UnitReqCurrent[j + 1]
				set j = j + 1
			endloop
			set UnitReqCount = UnitReqCount - 1
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// Escort requirement tracking
//===========================================================================
private function CheckEscortProgress takes nothing returns nothing
	local integer i = 1
	local QuestData q
	local string reqText
	local unit escortUnit
	local real ux
	local real uy
	
	call DebugMsg("CheckEscortProgress: Checking " + I2S(EscortReqCount) + " escort requirements")
	
	loop
		exitwhen i > EscortReqCount
		if not EscortReqComplete[i] then
			set escortUnit = EscortReqUnit[i]
			set q = QuestMaster_GetById(EscortReqQuestId[i])
			
			if q != 0 and q.active then
				// Check if escort unit exists and is alive
				if escortUnit != null and UnitAlive(escortUnit) then
					set ux = GetUnitX(escortUnit)
					set uy = GetUnitY(escortUnit)
					
					// Check if unit is in destination region
					if EscortReqDestination[i] != null and RectContainsCoords(EscortReqDestination[i], ux, uy) then
						call DebugMsg("CheckEscortProgress: Escort reached destination!")
						set EscortReqComplete[i] = true
						set reqText = q.getRequirementText(EscortReqIndex[i])
						if reqText == "" then
							set reqText = "Escort " + GetUnitName(escortUnit) + " to destination"
						endif
						call QuestMaster_UpdateRequirementText(EscortReqQuestId[i], EscortReqIndex[i], reqText)
						call QuestMaster_SetRequirementCompleted(EscortReqQuestId[i], EscortReqIndex[i], true)
						call QuestMaster_SetStateByNameAndGiver(q.name, EscortReqGiver[i], QUEST_STATE_READY_TURNIN)
						call q.addReturnRequirement()
					endif
				else
					call DebugMsg("CheckEscortProgress: Escort unit null or dead - quest may need to fail")
				endif
			endif
		endif
		set i = i + 1
	endloop
endfunction

private function OnEscortCheck takes nothing returns nothing
	call CheckEscortProgress()
endfunction

public function RegisterEscortRequirement takes integer questId, unit questGiver, integer reqIndex, unit escortUnit, rect destination, string destName returns nothing
	local string reqText
	local QuestData q

	if EscortReqCount >= MAX_ESCORT_REQUIREMENTS then
		call DebugMsg("RegisterEscortRequirement: Max escort requirements reached!")
		return
	endif

	set EscortReqCount = EscortReqCount + 1
	set EscortReqQuestId[EscortReqCount] = questId
	set EscortReqGiver[EscortReqCount] = questGiver
	set EscortReqIndex[EscortReqCount] = reqIndex
	set EscortReqUnit[EscortReqCount] = escortUnit
	set EscortReqDestination[EscortReqCount] = destination
	set EscortReqComplete[EscortReqCount] = false

	if destName == "" then
		set reqText = "Escort " + GetUnitName(escortUnit) + " to destination"
	else
		set reqText = "Escort " + GetUnitName(escortUnit) + " to " + destName
	endif
	
	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	// Start escort checking timer if not already running
	if EscortCheckTimer == null then
		set EscortCheckTimer = CreateTimer()
		call TimerStart(EscortCheckTimer, ESCORT_CHECK_INTERVAL, true, function OnEscortCheck)
	endif

	call DebugMsg("Registered escort requirement: quest=" + I2S(questId) + ", unit=" + GetUnitName(escortUnit) + ", dest=" + destName)
endfunction

public function UnregisterEscortRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1
	local integer j

	loop
		exitwhen i > EscortReqCount
		if EscortReqQuestId[i] == questId and EscortReqIndex[i] == reqIndex then
			// Shift remaining requirements down
			set j = i
			loop
				exitwhen j >= EscortReqCount
				set EscortReqQuestId[j] = EscortReqQuestId[j + 1]
				set EscortReqGiver[j] = EscortReqGiver[j + 1]
				set EscortReqIndex[j] = EscortReqIndex[j + 1]
				set EscortReqUnit[j] = EscortReqUnit[j + 1]
				set EscortReqDestination[j] = EscortReqDestination[j + 1]
				set EscortReqComplete[j] = EscortReqComplete[j + 1]
				set j = j + 1
			endloop
			set EscortReqCount = EscortReqCount - 1
			
			// Stop timer if no more escort requirements
			if EscortReqCount == 0 and EscortCheckTimer != null then
				call PauseTimer(EscortCheckTimer)
				call DestroyTimer(EscortCheckTimer)
				set EscortCheckTimer = null
			endif
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// TalkTo requirement tracking (manually completed)
//===========================================================================
public function RegisterTalkToRequirement takes integer questId, unit questGiver, integer reqIndex, unit targetNPC, string npcName returns nothing
	local string reqText
	local QuestData q

	if TalkToReqCount >= MAX_TALKTO_REQUIREMENTS then
		call DebugMsg("RegisterTalkToRequirement: Max TalkTo requirements reached!")
		return
	endif

	set TalkToReqCount = TalkToReqCount + 1
	set TalkToReqQuestId[TalkToReqCount] = questId
	set TalkToReqGiver[TalkToReqCount] = questGiver
	set TalkToReqIndex[TalkToReqCount] = reqIndex
	set TalkToReqNPC[TalkToReqCount] = targetNPC
	set TalkToReqComplete[TalkToReqCount] = false

	if npcName == "" and targetNPC != null then
		set npcName = GetUnitName(targetNPC)
	endif
	set reqText = "Talk to " + npcName

	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	call DebugMsg("Registered TalkTo requirement: quest=" + I2S(questId) + ", npc=" + npcName)
endfunction

public function CompleteTalkToRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1
	local QuestData q

	loop
		exitwhen i > TalkToReqCount
		if TalkToReqQuestId[i] == questId and TalkToReqIndex[i] == reqIndex and not TalkToReqComplete[i] then
			set TalkToReqComplete[i] = true
			set q = QuestMaster_GetById(questId)
			if q != 0 then
				call QuestMaster_SetRequirementCompleted(questId, reqIndex, true)
				call QuestMaster_SetStateByNameAndGiver(q.name, TalkToReqGiver[i], QUEST_STATE_READY_TURNIN)
				call q.addReturnRequirement()
				call DebugMsg("CompleteTalkToRequirement: Marked complete for quest " + I2S(questId))
			endif
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// FindNPC requirement tracking (proximity-based)
//===========================================================================
private function StopFindNPCCheckTimerIfIdle takes nothing returns nothing
	if FindNPCReqCount == 0 and FindNPCCheckTimer != null then
		call PauseTimer(FindNPCCheckTimer)
		call DestroyTimer(FindNPCCheckTimer)
		set FindNPCCheckTimer = null
	endif
endfunction

private function RemoveFindNPCRequirementAt takes integer index returns nothing
	local integer j = index

	loop
		exitwhen j >= FindNPCReqCount
		set FindNPCReqQuestId[j] = FindNPCReqQuestId[j + 1]
		set FindNPCReqGiver[j] = FindNPCReqGiver[j + 1]
		set FindNPCReqIndex[j] = FindNPCReqIndex[j + 1]
		set FindNPCReqNPC[j] = FindNPCReqNPC[j + 1]
		set FindNPCReqComplete[j] = FindNPCReqComplete[j + 1]
		set j = j + 1
	endloop

	set FindNPCReqQuestId[FindNPCReqCount] = 0
	set FindNPCReqGiver[FindNPCReqCount] = null
	set FindNPCReqIndex[FindNPCReqCount] = 0
	set FindNPCReqNPC[FindNPCReqCount] = null
	set FindNPCReqComplete[FindNPCReqCount] = false
	set FindNPCReqCount = FindNPCReqCount - 1

	call StopFindNPCCheckTimerIfIdle()
endfunction

private function CheckFindNPCProgress takes nothing returns nothing
	local integer i = 1
	local QuestData q
	local string reqText
	local unit npc
	local boolean removeReq

	loop
		exitwhen i > FindNPCReqCount
		set removeReq = false
		if not FindNPCReqComplete[i] then
			set npc = FindNPCReqNPC[i]
			set q = QuestMaster_GetById(FindNPCReqQuestId[i])

			if q != 0 and q.active and npc != null and UnitAlive(npc) then
				// Check if any hero is within discovery range
				if (udg_Nazgrek != null and IsWithinRange(udg_Nazgrek, npc, FINDNPC_DISCOVERY_RANGE)) or (udg_Zulkis != null and IsWithinRange(udg_Zulkis, npc, FINDNPC_DISCOVERY_RANGE)) then
					set FindNPCReqComplete[i] = true
					set reqText = "Find " + GetUnitName(npc) + " (Complete)"
					call QuestMaster_UpdateRequirementText(FindNPCReqQuestId[i], FindNPCReqIndex[i], reqText)
					call QuestMaster_SetRequirementCompleted(FindNPCReqQuestId[i], FindNPCReqIndex[i], true)
					call QuestMaster_SetStateByNameAndGiver(q.name, FindNPCReqGiver[i], QUEST_STATE_READY_TURNIN)
					call q.addReturnRequirement()
					call DebugMsg("CheckFindNPCProgress: Found " + GetUnitName(npc))
					set removeReq = true
				endif
			endif
		else
			set removeReq = true
		endif

		if removeReq then
			call RemoveFindNPCRequirementAt(i)
		else
			set i = i + 1
		endif
	endloop

	set npc = null
endfunction

private function OnFindNPCCheck takes nothing returns nothing
	call CheckFindNPCProgress()
endfunction

public function RegisterFindNPCRequirement takes integer questId, unit questGiver, integer reqIndex, unit targetNPC, string npcName returns nothing
	local string reqText
	local QuestData q

	if FindNPCReqCount >= MAX_FINDNPC_REQUIREMENTS then
		call DebugMsg("RegisterFindNPCRequirement: Max FindNPC requirements reached!")
		return
	endif

	set FindNPCReqCount = FindNPCReqCount + 1
	set FindNPCReqQuestId[FindNPCReqCount] = questId
	set FindNPCReqGiver[FindNPCReqCount] = questGiver
	set FindNPCReqIndex[FindNPCReqCount] = reqIndex
	set FindNPCReqNPC[FindNPCReqCount] = targetNPC
	set FindNPCReqComplete[FindNPCReqCount] = false

	if npcName == "" and targetNPC != null then
		set npcName = GetUnitName(targetNPC)
	endif
	set reqText = "Find " + npcName

	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	// Start checking timer if not already running
	if FindNPCCheckTimer == null then
		set FindNPCCheckTimer = CreateTimer()
		call TimerStart(FindNPCCheckTimer, FINDNPC_CHECK_INTERVAL, true, function OnFindNPCCheck)
	endif

	call DebugMsg("Registered FindNPC requirement: quest=" + I2S(questId) + ", npc=" + npcName)
endfunction

public function UnregisterFindNPCRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1

	loop
		exitwhen i > FindNPCReqCount
		if FindNPCReqQuestId[i] == questId and FindNPCReqIndex[i] == reqIndex then
			call RemoveFindNPCRequirementAt(i)
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// GoToPlace requirement tracking (region-based)
//===========================================================================
private function StopGoToPlaceCheckTimerIfIdle takes nothing returns nothing
	if GoToPlaceReqCount == 0 and GoToPlaceCheckTimer != null then
		call PauseTimer(GoToPlaceCheckTimer)
		call DestroyTimer(GoToPlaceCheckTimer)
		set GoToPlaceCheckTimer = null
	endif
endfunction

private function RemoveGoToPlaceRequirementAt takes integer index returns nothing
	local integer j = index

	loop
		exitwhen j >= GoToPlaceReqCount
		set GoToPlaceReqQuestId[j] = GoToPlaceReqQuestId[j + 1]
		set GoToPlaceReqGiver[j] = GoToPlaceReqGiver[j + 1]
		set GoToPlaceReqIndex[j] = GoToPlaceReqIndex[j + 1]
		set GoToPlaceReqRegion[j] = GoToPlaceReqRegion[j + 1]
		set GoToPlaceReqName[j] = GoToPlaceReqName[j + 1]
		set GoToPlaceReqComplete[j] = GoToPlaceReqComplete[j + 1]
		set j = j + 1
	endloop

	set GoToPlaceReqQuestId[GoToPlaceReqCount] = 0
	set GoToPlaceReqGiver[GoToPlaceReqCount] = null
	set GoToPlaceReqIndex[GoToPlaceReqCount] = 0
	set GoToPlaceReqRegion[GoToPlaceReqCount] = null
	set GoToPlaceReqName[GoToPlaceReqCount] = ""
	set GoToPlaceReqComplete[GoToPlaceReqCount] = false
	set GoToPlaceReqCount = GoToPlaceReqCount - 1

	call StopGoToPlaceCheckTimerIfIdle()
endfunction

private function CheckGoToPlaceProgress takes nothing returns nothing
	local integer i = 1
	local QuestData q
	local string reqText
	local real nx
	local real ny
	local real zx
	local real zy
	local boolean removeReq

	loop
		exitwhen i > GoToPlaceReqCount
		set removeReq = false
		if not GoToPlaceReqComplete[i] then
			set q = QuestMaster_GetById(GoToPlaceReqQuestId[i])

			if q != 0 and q.active and GoToPlaceReqRegion[i] != null then
				// Check if any hero is in the region
				if udg_Nazgrek != null then
					set nx = GetUnitX(udg_Nazgrek)
					set ny = GetUnitY(udg_Nazgrek)
					if RectContainsCoords(GoToPlaceReqRegion[i], nx, ny) then
						set GoToPlaceReqComplete[i] = true
						set reqText = "Go to " + GoToPlaceReqName[i] + " (Complete)"
						call QuestMaster_UpdateRequirementText(GoToPlaceReqQuestId[i], GoToPlaceReqIndex[i], reqText)
						call QuestMaster_SetRequirementCompleted(GoToPlaceReqQuestId[i], GoToPlaceReqIndex[i], true)
						call QuestMaster_SetStateByNameAndGiver(q.name, GoToPlaceReqGiver[i], QUEST_STATE_READY_TURNIN)
						call q.addReturnRequirement()
						call DebugMsg("CheckGoToPlaceProgress: Reached " + GoToPlaceReqName[i])
						set removeReq = true
					endif
				endif
				if not GoToPlaceReqComplete[i] and udg_Zulkis != null then
					set zx = GetUnitX(udg_Zulkis)
					set zy = GetUnitY(udg_Zulkis)
					if RectContainsCoords(GoToPlaceReqRegion[i], zx, zy) then
						set GoToPlaceReqComplete[i] = true
						set reqText = "Go to " + GoToPlaceReqName[i] + " (Complete)"
						call QuestMaster_UpdateRequirementText(GoToPlaceReqQuestId[i], GoToPlaceReqIndex[i], reqText)
						call QuestMaster_SetRequirementCompleted(GoToPlaceReqQuestId[i], GoToPlaceReqIndex[i], true)
						call QuestMaster_SetStateByNameAndGiver(q.name, GoToPlaceReqGiver[i], QUEST_STATE_READY_TURNIN)
						call q.addReturnRequirement()
						call DebugMsg("CheckGoToPlaceProgress: Reached " + GoToPlaceReqName[i])
						set removeReq = true
					endif
				endif
			endif
		else
			set removeReq = true
		endif

		if removeReq then
			call RemoveGoToPlaceRequirementAt(i)
		else
			set i = i + 1
		endif
	endloop
endfunction

private function OnGoToPlaceCheck takes nothing returns nothing
	call CheckGoToPlaceProgress()
endfunction

public function RegisterGoToPlaceRequirement takes integer questId, unit questGiver, integer reqIndex, rect targetRegion, string placeName returns nothing
	local string reqText
	local QuestData q

	if GoToPlaceReqCount >= MAX_GOTOPLACE_REQUIREMENTS then
		call DebugMsg("RegisterGoToPlaceRequirement: Max GoToPlace requirements reached!")
		return
	endif

	set GoToPlaceReqCount = GoToPlaceReqCount + 1
	set GoToPlaceReqQuestId[GoToPlaceReqCount] = questId
	set GoToPlaceReqGiver[GoToPlaceReqCount] = questGiver
	set GoToPlaceReqIndex[GoToPlaceReqCount] = reqIndex
	set GoToPlaceReqRegion[GoToPlaceReqCount] = targetRegion
	set GoToPlaceReqName[GoToPlaceReqCount] = placeName
	set GoToPlaceReqComplete[GoToPlaceReqCount] = false

	set reqText = "Go to " + placeName

	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	// Start checking timer if not already running
	if GoToPlaceCheckTimer == null then
		set GoToPlaceCheckTimer = CreateTimer()
		call TimerStart(GoToPlaceCheckTimer, GOTOPLACE_CHECK_INTERVAL, true, function OnGoToPlaceCheck)
	endif

	call DebugMsg("Registered GoToPlace requirement: quest=" + I2S(questId) + ", place=" + placeName)
endfunction

public function UnregisterGoToPlaceRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1

	loop
		exitwhen i > GoToPlaceReqCount
		if GoToPlaceReqQuestId[i] == questId and GoToPlaceReqIndex[i] == reqIndex then
			call RemoveGoToPlaceRequirementAt(i)
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// Reputation requirement tracking
//===========================================================================

// Helper function to get current reputation value with a faction
private function GetReputationLevel takes string factionName returns integer
	local Faction f = Faction.getFaction(factionName)
	local integer repValue = 0
	if f != 0 then
		set repValue = Reputation.getRep(Player(0), f)
	endif
	return repValue
endfunction

// Helper function to get reputation level name from value
private function GetReputationLevelName takes integer repValue returns string
	if repValue >= Reputation_REP_EXALTED then
		return "Exalted"
	elseif repValue >= Reputation_REP_COVENANT then
		return "Covenant"
	elseif repValue >= Reputation_REP_FRIENDLY then
		return "Friendly"
	elseif repValue >= Reputation_REP_NEUTRAL then
		return "Neutral"
	elseif repValue >= Reputation_REP_UNFRIENDLY then
		return "Unfriendly"
	elseif repValue >= Reputation_REP_HOSTILE then
		return "Hostile"
	else
		return "Enemy"
	endif
endfunction

private function StopRepCheckTimerIfIdle takes nothing returns nothing
	if RepReqCount == 0 and RepCheckTimer != null then
		call PauseTimer(RepCheckTimer)
		call DestroyTimer(RepCheckTimer)
		set RepCheckTimer = null
	endif
endfunction

private function RemoveReputationRequirementAt takes integer index returns nothing
	local integer j = index

	loop
		exitwhen j >= RepReqCount
		set RepReqQuestId[j] = RepReqQuestId[j + 1]
		set RepReqGiver[j] = RepReqGiver[j + 1]
		set RepReqIndex[j] = RepReqIndex[j + 1]
		set RepReqFaction[j] = RepReqFaction[j + 1]
		set RepReqLevel[j] = RepReqLevel[j + 1]
		set RepReqComplete[j] = RepReqComplete[j + 1]
		set j = j + 1
	endloop

	set RepReqQuestId[RepReqCount] = 0
	set RepReqGiver[RepReqCount] = null
	set RepReqIndex[RepReqCount] = 0
	set RepReqFaction[RepReqCount] = ""
	set RepReqLevel[RepReqCount] = 0
	set RepReqComplete[RepReqCount] = false
	set RepReqCount = RepReqCount - 1

	call StopRepCheckTimerIfIdle()
endfunction

private function CheckReputationProgress takes nothing returns nothing
	local integer i = 1
	local QuestData q
	local string reqText
	local integer currentRep
	local boolean removeReq

	loop
		exitwhen i > RepReqCount
		set removeReq = false
		if not RepReqComplete[i] then
			set q = QuestMaster_GetById(RepReqQuestId[i])

			if q != 0 and q.active then
				// Get current reputation value with the faction
				set currentRep = GetReputationLevel(RepReqFaction[i])
				
				if currentRep >= RepReqLevel[i] then
					set RepReqComplete[i] = true
					set reqText = "Gain " + GetReputationLevelName(RepReqLevel[i]) + " with " + RepReqFaction[i] + " (Complete)"
					call QuestMaster_UpdateRequirementText(RepReqQuestId[i], RepReqIndex[i], reqText)
					call QuestMaster_SetRequirementCompleted(RepReqQuestId[i], RepReqIndex[i], true)
					call QuestMaster_SetStateByNameAndGiver(q.name, RepReqGiver[i], QUEST_STATE_READY_TURNIN)
					call q.addReturnRequirement()
					call DebugMsg("CheckReputationProgress: Reached " + GetReputationLevelName(RepReqLevel[i]) + " with " + RepReqFaction[i])
					set removeReq = true
				endif
			endif
		else
			set removeReq = true
		endif

		if removeReq then
			call RemoveReputationRequirementAt(i)
		else
			set i = i + 1
		endif
	endloop
endfunction

private function OnRepCheck takes nothing returns nothing
	call CheckReputationProgress()
endfunction

public function RegisterReputationRequirement takes integer questId, unit questGiver, integer reqIndex, string faction, integer requiredLevel, string levelName returns nothing
	local string reqText
	local QuestData q

	if RepReqCount >= MAX_REP_REQUIREMENTS then
		call DebugMsg("RegisterReputationRequirement: Max Reputation requirements reached!")
		return
	endif

	set RepReqCount = RepReqCount + 1
	set RepReqQuestId[RepReqCount] = questId
	set RepReqGiver[RepReqCount] = questGiver
	set RepReqIndex[RepReqCount] = reqIndex
	set RepReqFaction[RepReqCount] = faction
	set RepReqLevel[RepReqCount] = requiredLevel
	set RepReqComplete[RepReqCount] = false

	set reqText = "Gain " + levelName + " with " + faction

	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	// Start checking timer if not already running
	if RepCheckTimer == null then
		set RepCheckTimer = CreateTimer()
		call TimerStart(RepCheckTimer, REP_CHECK_INTERVAL, true, function OnRepCheck)
	endif

	call DebugMsg("Registered Reputation requirement: quest=" + I2S(questId) + ", faction=" + faction + ", level=" + levelName)
endfunction

public function UnregisterReputationRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1

	loop
		exitwhen i > RepReqCount
		if RepReqQuestId[i] == questId and RepReqIndex[i] == reqIndex then
			call RemoveReputationRequirementAt(i)
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// Investigate requirement tracking (manually completed)
//===========================================================================
public function RegisterInvestigateRequirement takes integer questId, unit questGiver, integer reqIndex, string description returns nothing
	local string reqText
	local QuestData q

	if InvestigateReqCount >= MAX_INVESTIGATE_REQUIREMENTS then
		call DebugMsg("RegisterInvestigateRequirement: Max Investigate requirements reached!")
		return
	endif

	set InvestigateReqCount = InvestigateReqCount + 1
	set InvestigateReqQuestId[InvestigateReqCount] = questId
	set InvestigateReqGiver[InvestigateReqCount] = questGiver
	set InvestigateReqIndex[InvestigateReqCount] = reqIndex
	set InvestigateReqDesc[InvestigateReqCount] = description
	set InvestigateReqComplete[InvestigateReqCount] = false

	set reqText = "Investigate " + description

	set q = QuestMaster_GetById(questId)
	if q != 0 then
		call q.setRequirement(reqIndex, reqText)
	endif

	call DebugMsg("Registered Investigate requirement: quest=" + I2S(questId) + ", desc=" + description)
endfunction

public function CompleteInvestigateRequirement takes integer questId, integer reqIndex returns nothing
	local integer i = 1
	local QuestData q

	loop
		exitwhen i > InvestigateReqCount
		if InvestigateReqQuestId[i] == questId and InvestigateReqIndex[i] == reqIndex and not InvestigateReqComplete[i] then
			set InvestigateReqComplete[i] = true
			set q = QuestMaster_GetById(questId)
			if q != 0 then
				call QuestMaster_SetRequirementCompleted(questId, reqIndex, true)
				call QuestMaster_SetStateByNameAndGiver(q.name, InvestigateReqGiver[i], QUEST_STATE_READY_TURNIN)
				call q.addReturnRequirement()
				call DebugMsg("CompleteInvestigateRequirement: Marked complete for quest " + I2S(questId))
			endif
			return
		endif
		set i = i + 1
	endloop
endfunction

//===========================================================================
// Init
//===========================================================================
private function Init takes nothing returns nothing
	set QuestGiver_SelectHandlers = Table.create()
	set QuestGiver_FirstGreetDone = Table.create()
	set QuestGiver_SkipNextGreet = Table.create()
	set QuestGiver_GreetOrder = Table.create()
	set CompanionIndex = Table.create()
	set CompanionIcon = Table.create()

	// Register with centralized death event system at map start
	call UnitDeathEvent_Register(function OnUnitDeath)
	
	// Map GUI variables to library variables (if they exist in the map)
	// For reference types (groups, triggers, sounds), we store the reference
	// For value types (integers), we use udg_ variables directly in the code to avoid state mismatch
	set Companion_Group = udg_Companion_Group
	set CompanionFocusNazgrek = udg_CompanionFocusNazgrek
	set CompanionFocusZulkis = udg_CompanionFocusZulkis
	// Note: udg_CompanionCount is used directly in functions (no local copy)
	set MultiboardUpdateAddCompanion = gg_trg_MultiboardUpdate_Add_Companion
	set MultiboardUpdateRemoveCompanion = gg_trg_MultiboardUpdate_Remove_Companion
	set RescueSound = gg_snd_Rescue
	
	// Note: CompanionUnit[] array is maintained separately from udg_CompanionUnit[]
	// CompanionIndex and CompanionIcon use Tables for efficient lookup
endfunction

endlibrary
