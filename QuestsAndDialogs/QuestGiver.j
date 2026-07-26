library QuestGiver initializer Init requires QuestMaster, DialogInteraction, DialogSystem, HeroItemCheck, SharedDInvLib, Table
//===========================================================================
// QuestGiver
// Quest data/actions plus compatibility wrappers for DialogInteraction helpers.
//===========================================================================

globals
	private constant boolean DEBUG = false

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
	private integer QuestGiver_RemoveItemTypeId = 0
	private integer QuestGiver_RemoveFallbackItemTypeId = 0
	private integer QuestGiver_RemovedQuestItemCount = 0
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

public function RegisterSelectionHandler takes unit u, code handler returns nothing
	call DialogInteraction_RegisterSelectionHandler(u, handler)
endfunction

//===========================================================================
// Registration
//===========================================================================
public function SetFirstGreetDone takes unit u, boolean flag returns nothing
	call DialogInteraction_SetFirstGreetDone(u, flag)
endfunction

public function SuppressNextGreet takes unit u returns nothing
	call DialogInteraction_SuppressNextGreet(u)
endfunction

//===========================================================================
// Companion management
//
// Generic functions for adding/removing companion units to player's party.
// These functions interface with shared GUI variables defined in World Editor.
//
// IMPORTANT: Uses udg_CompanionCount directly (no local copy) to prevent state mismatch
//            between old GUI globals and JASS code. This keeps companion adds
//            visible to current frame UIs and older systems still reading globals.
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
//   - gg_snd_Rescue (sound)
//
// StatsUI and StatsLiteUI read the shared companion globals directly.
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
			set udg_CompanionIndex[GetUnitUserData(companionUnit)] = i
			set udg_UnitHider_ReferenceUnits[GetUnitUserData(companionUnit)] = companionUnit
			if companionIcon != "" then
				set udg_CompanionIcon[i] = companionIcon
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
	set udg_CompanionIndex[customValue] = udg_CompanionCount
	set udg_UnitHider_ReferenceUnits[customValue] = companionUnit
	
	// Store icon path
	if CompanionIcon != 0 and companionIcon != "" then
		set CompanionIcon.string[udg_CompanionCount] = companionIcon
	endif
	if companionIcon != "" then
		set udg_CompanionIcon[udg_CompanionCount] = companionIcon
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
			set udg_CompanionIcon[foundIndex] = udg_CompanionIcon[foundIndex + 1]
			if udg_CompanionUnit[foundIndex] != null and CompanionIndex != 0 then
				set movedCustomValue = GetUnitUserData(udg_CompanionUnit[foundIndex])
				set CompanionIndex.integer[movedCustomValue] = foundIndex
				set udg_CompanionIndex[movedCustomValue] = foundIndex
			endif
			set foundIndex = foundIndex + 1
		endloop

		set CompanionUnit[lastIndex] = null
		set udg_CompanionUnit[lastIndex] = null
		if CompanionIcon != 0 then
			set CompanionIcon.string[lastIndex] = ""
		endif
		set udg_CompanionIcon[lastIndex] = ""
		set udg_CompanionCount = udg_CompanionCount - 1
	endif

	if CompanionIndex != 0 then
		set CompanionIndex.integer[GetUnitUserData(companionUnit)] = 0
	endif
	set udg_CompanionIndex[GetUnitUserData(companionUnit)] = 0
	
	call DebugMsg("Removed companion: " + GetUnitName(companionUnit))
endfunction

public function Register takes unit u returns nothing
	call DebugMsg("Register giver id=" + I2S(GetHandleId(u)))
	call QuestMaster_RegisterGiver(u)
	call DialogInteraction_Register(u)
endfunction

public function Unregister takes unit u returns nothing
	call DebugMsg("Unregister giver id=" + I2S(GetHandleId(u)))
	call QuestMaster_UnregisterGiver(u)
	call DialogInteraction_Unregister(u)
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
	return DialogInteraction_IsUnitAlive(u)
endfunction

public function FindPreferredUnitInRect takes rect searchRect, integer expectedTypeId, player preferredOwner, unit excludeA, unit excludeB, unit excludeC, unit excludeD, boolean excludeHeroes returns unit
	local group g
	local unit u
	local unit bestExact = null
	local unit bestPreferred = null
	local unit bestFallback = null
	local real centerX
	local real centerY
	local real dx
	local real dy
	local real distSq
	local real bestExactDistSq = 999999999.00
	local real bestPreferredDistSq = 999999999.00
	local real bestFallbackDistSq = 999999999.00
	if searchRect == null then
		return null
	endif
	set centerX = GetRectCenterX(searchRect)
	set centerY = GetRectCenterY(searchRect)
	set g = CreateGroup()
	call GroupEnumUnitsInRect(g, searchRect, null)
	loop
		set u = FirstOfGroup(g)
		exitwhen u == null
		call GroupRemoveUnit(g, u)
		if IsUnitAlive(u) and u != excludeA and u != excludeB and u != excludeC and u != excludeD and (not excludeHeroes or not IsUnitType(u, UNIT_TYPE_HERO)) then
			set dx = GetUnitX(u) - centerX
			set dy = GetUnitY(u) - centerY
			set distSq = dx * dx + dy * dy
			if expectedTypeId != 0 and GetUnitTypeId(u) == expectedTypeId and distSq < bestExactDistSq then
				set bestExact = u
				set bestExactDistSq = distSq
			endif
			if preferredOwner != null and GetOwningPlayer(u) == preferredOwner and distSq < bestPreferredDistSq then
				set bestPreferred = u
				set bestPreferredDistSq = distSq
			endif
			if distSq < bestFallbackDistSq then
				set bestFallback = u
				set bestFallbackDistSq = distSq
			endif
		endif
	endloop
	call DestroyGroup(g)
	set g = null
	set u = null
	if bestExact != null then
		return bestExact
	endif
	if bestPreferred != null then
		return bestPreferred
	endif
	return bestFallback
endfunction

public function ReuseOrCreateUnitAtPoint takes unit existingUnit, player ownerP, integer defaultUnitTypeId, real x, real y, real facing, boolean disableCreepGuard returns unit
	local integer unitTypeId = defaultUnitTypeId
	local unit result = existingUnit
	if result != null and GetUnitTypeId(result) != 0 then
		set unitTypeId = GetUnitTypeId(result)
		if ownerP == null then
			set ownerP = GetOwningPlayer(result)
		endif
	endif
	if ownerP == null or unitTypeId == 0 then
		set result = null
		return null
	endif
	if result != null and IsUnitAlive(result) then
		call SetUnitOwner(result, ownerP, true)
		call SetUnitPosition(result, x, y)
		call SetUnitFacing(result, facing)
	else
		if result != null then
			call RemoveUnit(result)
		endif
		set result = CreateUnit(ownerP, unitTypeId, x, y, facing)
	endif
	if result != null then
		if disableCreepGuard then
			call SetUnitCreepGuard(result, false)
		endif
		call IssueImmediateOrder(result, "stop")
	endif
	return result
endfunction

public function ResetFieldUnitAtPoint takes unit u, player ownerP, real x, real y, real facing, boolean healToFull returns nothing
	if u == null or GetUnitTypeId(u) == 0 then
		return
	endif
	call PauseUnit(u, false)
	call SetUnitTimeScale(u, 1.00)
	call SetUnitInvulnerable(u, false)
	if ownerP != null then
		call SetUnitOwner(u, ownerP, true)
	endif
	if healToFull then
		call SetWidgetLife(u, BlzGetUnitMaxHP(u))
	endif
	call ResetUnitAnimation(u)
	call SetUnitAnimation(u, "stand")
	call SetUnitPosition(u, x, y)
	call SetUnitFacing(u, facing)
	call IssueImmediateOrder(u, "stop")
endfunction


public function IsWithinRange takes unit a, unit b, real range returns boolean
	return DialogInteraction_IsWithinRange(a, b, range)
endfunction

public function GetAvailableHero takes unit giver, real range returns unit
	return DialogInteraction_GetAvailableHero(giver, range)
endfunction

public function GetAllowedHero takes unit giver, real range, boolean allowNazgrek, boolean allowZulkis returns unit
	return DialogInteraction_GetAllowedHero(giver, range, allowNazgrek, allowZulkis)
endfunction

public function ResolveDialogHero takes unit selectedHero, unit giver, real range, boolean allowNazgrek, boolean allowZulkis returns unit
	return DialogInteraction_ResolveDialogHero(selectedHero, giver, range, allowNazgrek, allowZulkis)
endfunction

public function GetHeroName takes unit hero returns string
	return DialogInteraction_GetHeroName(hero)
endfunction

public function AddHeroLine takes integer seq, unit hero, string text, string nazgrekSound returns nothing
	call DialogInteraction_AddHeroLine(seq, hero, text, nazgrekSound)
endfunction

public function AddHeroLookAtLine takes integer seq, unit hero, unit lookTarget, string text, string nazgrekSound returns nothing
	call DialogInteraction_AddHeroLookAtLine(seq, hero, lookTarget, text, nazgrekSound)
endfunction

public function GetUnitDisplayName takes unit u returns string
	return DialogInteraction_GetUnitDisplayName(u)
endfunction

public function BeginCinematicSequence takes boolean useCinematicMode returns nothing
	call DialogInteraction_BeginCinematicSequence(useCinematicMode)
endfunction

public function EndCinematicSequence takes boolean useCinematicMode returns nothing
	call DialogInteraction_EndCinematicSequence(useCinematicMode)
endfunction

public function CreateGreetSequenceBase takes unit giver, string giverName, unit hero, real startDelay, real heroReplyDelay, boolean faceEachOther returns integer
	return DialogInteraction_CreateGreetSequenceBase(giver, giverName, hero, startDelay, heroReplyDelay, faceEachOther)
endfunction

public function CreateInfoSequenceBase takes unit giver, string giverName, code onStart, code onEnd returns integer
	return DialogInteraction_CreateInfoSequenceBase(giver, giverName, onStart, onEnd)
endfunction

public function QueueDialogReopen takes string rebuildFuncName, real delay returns nothing
	call DialogInteraction_QueueDialogReopen(rebuildFuncName, delay)
endfunction

public function ShowDialog takes unit npc, player p, dialog d returns nothing
	call DialogInteraction_ShowDialog(npc, p, d)
endfunction

public function PlayFirstGreetSequenceEx takes unit npc, player p, dialog d, integer seqId, boolean useCinematicMode returns nothing
	call DialogInteraction_PlayFirstGreetSequenceEx(npc, p, d, seqId, useCinematicMode)
endfunction

public function PlayFirstGreetSequence takes unit npc, player p, dialog d, integer seqId returns nothing
	call DialogInteraction_PlayFirstGreetSequence(npc, p, d, seqId)
endfunction

public function PlayGreetSequenceEx takes integer seqId, unit npc, player p, dialog d, boolean useCinematicMode returns nothing
	call DialogInteraction_PlayGreetSequenceEx(seqId, npc, p, d, useCinematicMode)
endfunction

public function PlayGreetSequence takes integer seqId, unit npc, player p, dialog d returns nothing
	call DialogInteraction_PlayGreetSequence(seqId, npc, p, d)
endfunction

public function SetGreetOrder takes unit u, integer order returns nothing
	call DialogInteraction_SetGreetOrder(u, order)
endfunction

public function IsFirstGreetDone takes unit u returns boolean
	return DialogInteraction_IsFirstGreetDone(u)
endfunction

public function HideDialog takes dialog d, player p returns nothing
	call DialogInteraction_HideDialog(d, p)
endfunction

public function CloseActiveDialog takes nothing returns nothing
	call DialogInteraction_CloseActiveDialog()
endfunction

public function BeginDialogSequence takes nothing returns nothing
	call DialogInteraction_BeginDialogSequence()
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

public function GetCooldownRemaining takes timer t returns real
	return DialogInteraction_GetCooldownRemaining(t)
endfunction

public function IsCooldownActive takes timer t returns boolean
	return DialogInteraction_IsCooldownActive(t)
endfunction

public function StartCooldown takes timer t, real duration returns timer
	return DialogInteraction_StartCooldown(t, duration)
endfunction

public function GetSelectedUnit takes nothing returns unit
	return DialogInteraction_GetSelectedUnit()
endfunction

public function PassSelectionGate takes unit giver, unit hero, real range, timer cooldown returns boolean
	return DialogInteraction_PassSelectionGate(giver, hero, range, cooldown)
endfunction

public function IsUnitCasting takes unit whichUnit returns boolean
	return DialogInteraction_IsUnitCasting(whichUnit)
endfunction

public function IsUnitInCombat takes unit whichUnit returns boolean
	return DialogInteraction_IsUnitInCombat(whichUnit)
endfunction

public function GetDialogSelectionHero takes unit giver, real range, boolean allowNazgrek, boolean allowZulkis returns unit
	return DialogInteraction_GetDialogSelectionHero(giver, range, allowNazgrek, allowZulkis)
endfunction

public function GetLastSelectionBlockReason takes nothing returns string
	return DialogInteraction_GetLastSelectionBlockReason()
endfunction

public function PassDialogSelectionGate takes unit giver, unit hero, real range, timer cooldown, boolean requireHero, boolean blockSequenceActive, boolean blockGiverCasting, boolean blockGiverCombat, boolean blockHeroCasting, boolean blockHeroCombat returns boolean
	return DialogInteraction_PassDialogSelectionGate(giver, hero, range, cooldown, requireHero, blockSequenceActive, blockGiverCasting, blockGiverCombat, blockHeroCasting, blockHeroCombat)
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

public function AddDelayedDiscoveredAction takes code actionFunc returns nothing
	call QuestMaster_AddDelayedDiscoveredAction(actionFunc)
endfunction

public function GetEventQuestId takes nothing returns integer
	return QuestMaster_EventQuestId
endfunction

public function GetEventQuestState takes nothing returns integer
	return QuestMaster_EventState
endfunction

public function IsEventQuestByNameAndGiver takes string questName, unit questGiver returns boolean
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return false
	endif
	return QuestMaster_EventQuestId == q.id
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

public function CreateConfiguredQuest takes string questName, unit questGiver, string questType, integer questLevel, unit questReceiver, string title, string iconPath, string description, string infoText, string info2Text, integer requiredLevel, boolean useAllowedHeroesForLevelCheck, boolean allowNazgrek, boolean allowZulkis, string faction, string receiverDisplayName returns QuestData
	local QuestData q = CreateQuest(questName, questGiver, questType, questLevel, questReceiver)
	call ApplyQuestMetadata(q, title, iconPath, description, infoText, info2Text, requiredLevel, useAllowedHeroesForLevelCheck, allowNazgrek, allowZulkis, faction, receiverDisplayName)
	return q
endfunction

public function SetQuestRewards takes QuestData q, boolean xpActive, integer xpAdjust, boolean goldActive, integer goldAdjust, boolean arenaActive, integer arenaAdjust, boolean repActive, integer repAdjust, boolean repLinked returns nothing
	if q == 0 then
		return
	endif
	call q.setRewardParams(xpActive, xpAdjust, goldActive, goldAdjust, arenaActive, arenaAdjust, repActive, repAdjust, repLinked)
endfunction

public function SetQuestRequiredReputation takes QuestData q, integer reputation returns nothing
	if q == 0 then
		return
	endif
	call q.setRequiredReputation(reputation)
endfunction

public function SetQuestCustomCondition takes QuestData q, trigger conditionTrigger returns nothing
	if q == 0 then
		return
	endif
	call q.setCustomCondition(conditionTrigger)
endfunction

public function AddQuestPrerequisite takes QuestData q, string prereqQuestName, unit prereqQuestGiver returns nothing
	if q == 0 then
		return
	endif
	call q.addRequiredCompletedQuest(prereqQuestName, prereqQuestGiver)
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

public function IsQuestActiveByNameAndGiver takes string questName, unit questGiver returns boolean
	local QuestData q = QuestMaster_GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return false
	endif
	return q.discovered and not q.completed and not q.failed and q.state != QUEST_STATE_COMPLETE
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
	call DialogInteraction_HandleSequenceEnd(giver, cooldownTimer, cooldownDuration, stopCamera, cameraStopDuration, useCamera, reopenDialog)
endfunction

public function StartDialogExitTransition takes unit giver, unit restoreHero, timer cooldownTimer, real cooldownDuration, boolean stopCamera, real cameraStopDuration, boolean useCamera, boolean runCinematicTrigger, boolean useCinematicMode returns nothing
	call DialogInteraction_StartDialogExitTransition(giver, restoreHero, cooldownTimer, cooldownDuration, stopCamera, cameraStopDuration, useCamera, runCinematicTrigger, useCinematicMode)
endfunction

public function StartConfiguredDialogExitTransition takes unit giver, unit restoreHero, timer cooldownTimer, real cooldownDuration, boolean useCamera, boolean useCinematicMode returns nothing
	call DialogInteraction_StartConfiguredDialogExitTransition(giver, restoreHero, cooldownTimer, cooldownDuration, useCamera, useCinematicMode)
endfunction

public function StartDialogEntryTransition takes unit giver, unit hero, integer moveMode, real moveOffset, real moveAngle, boolean runCinematicTrigger, boolean useCamera, real cameraDist, real cameraZOffset, real cameraAngle, real cameraRotOffset, real cameraFarZ, real cameraFov, real cameraBlockRadius, boolean cameraBlockCheck, boolean useCinematicMode, string continueFuncName returns nothing
	call DialogInteraction_StartDialogEntryTransition(giver, hero, moveMode, moveOffset, moveAngle, runCinematicTrigger, useCamera, cameraDist, cameraZOffset, cameraAngle, cameraRotOffset, cameraFarZ, cameraFov, cameraBlockRadius, cameraBlockCheck, useCinematicMode, continueFuncName)
endfunction

public function ConfigureDialogTransition takes unit giver, integer moveMode, real moveOffset, real moveAngle, real cameraDist, real cameraZOffset, real cameraAngle, real cameraRotOffset, real cameraFarZ, real cameraFov, real cameraBlockRadius, boolean cameraBlockCheck returns nothing
	call DialogInteraction_ConfigureDialogTransition(giver, moveMode, moveOffset, moveAngle, cameraDist, cameraZOffset, cameraAngle, cameraRotOffset, cameraFarZ, cameraFov, cameraBlockRadius, cameraBlockCheck)
endfunction

public function HasDialogTransitionConfig takes unit giver returns boolean
	return DialogInteraction_HasDialogTransitionConfig(giver)
endfunction

public function StartConfiguredDialogCamera takes player p, unit giver, boolean useCamera returns nothing
	call DialogInteraction_StartConfiguredDialogCamera(p, giver, useCamera)
endfunction

public function StartConfiguredDialogEntryTransition takes unit giver, unit hero, boolean runCinematicTrigger, boolean useCamera, boolean useCinematicMode, string continueFuncName returns nothing
	call DialogInteraction_StartConfiguredDialogEntryTransition(giver, hero, runCinematicTrigger, useCamera, useCinematicMode, continueFuncName)
endfunction

//===========================================================================
// Generic accept/complete sequence builders
//===========================================================================
public function CreateBaseSequence takes unit giver, string giverName returns integer
	return DialogInteraction_CreateBaseSequence(giver, giverName)
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
	return DialogInteraction_CreateFarewellSequence(giver, giverName, hero, heroName, dialogRange, allowNazgrek, allowZulkis)
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

private function IsQuestItemTypeEither takes integer itemTypeId, integer primaryItemTypeId, integer fallbackItemTypeId returns boolean
	if itemTypeId == 0 then
		return false
	endif
	if itemTypeId == primaryItemTypeId then
		return true
	endif
	return fallbackItemTypeId != 0 and fallbackItemTypeId != primaryItemTypeId and itemTypeId == fallbackItemTypeId
endfunction

public function HasHeroItemEither takes integer itemTypeId, integer fallbackItemTypeId, integer itemAmount returns boolean
	if itemAmount <= 0 then
		set itemAmount = 1
	endif
	if itemTypeId != 0 and HeroItemCheckBoth(itemTypeId, itemAmount) then
		return true
	endif
	if fallbackItemTypeId != 0 and fallbackItemTypeId != itemTypeId and HeroItemCheckBoth(fallbackItemTypeId, itemAmount) then
		return true
	endif
	return false
endfunction

private function RemoveQuestItemTypeInventory takes unit whichUnit, integer itemTypeId, integer fallbackItemTypeId returns nothing
	local integer slot = 0
	local integer inventorySize
	local item slotItem
	if whichUnit == null then
		return
	endif
	set inventorySize = UnitInventorySize(whichUnit)
	loop
		exitwhen slot >= inventorySize
		set slotItem = UnitItemInSlot(whichUnit, slot)
		if slotItem != null and IsQuestItemTypeEither(GetItemTypeId(slotItem), itemTypeId, fallbackItemTypeId) then
			call RemoveItem(slotItem)
			set QuestGiver_RemovedQuestItemCount = QuestGiver_RemovedQuestItemCount + 1
		endif
		set slot = slot + 1
	endloop
	set slotItem = null
	set whichUnit = null
endfunction

private function RemoveQuestItemTypeDInventory takes unit whichUnit, integer itemTypeId, integer fallbackItemTypeId returns nothing
	local integer pid
	local integer bid
	local integer slot = 0
	local integer maxCapacity
	local boolean removedAny = false
	local item slotItem
	if whichUnit == null then
		return
	endif
	set bid = BIDOfUnit(whichUnit)
	if bid < 1 then
		set whichUnit = null
		return
	endif
	set maxCapacity = MaxDInvCapacityOfUnit(whichUnit)
	loop
		exitwhen slot >= maxCapacity
		set slotItem = DInventoryDB[bid].item[slot]
		if slotItem != null and IsQuestItemTypeEither(GetItemTypeId(slotItem), itemTypeId, fallbackItemTypeId) then
			call DeleteBIDSlotIdItemFromDInventory(bid, slot)
			call RemoveItem(slotItem)
			set QuestGiver_RemovedQuestItemCount = QuestGiver_RemovedQuestItemCount + 1
			set removedAny = true
		endif
		set slot = slot + 1
	endloop
	if removedAny then
		set pid = GetPlayerId(GetOwningPlayer(whichUnit))
		if pid >= 0 and pid < 24 then
			call UnitDInventoryDBIntoDInventoryFrames(pid, bid)
		endif
	endif
	set slotItem = null
	set whichUnit = null
endfunction

private function RemoveQuestItemTypeFromEnumUnit takes nothing returns nothing
	local unit enumUnit = GetEnumUnit()
	call RemoveQuestItemTypeInventory(enumUnit, QuestGiver_RemoveItemTypeId, QuestGiver_RemoveFallbackItemTypeId)
	call RemoveQuestItemTypeDInventory(enumUnit, QuestGiver_RemoveItemTypeId, QuestGiver_RemoveFallbackItemTypeId)
	set enumUnit = null
endfunction

private function RemoveQuestItemTypeFromEnumItem takes nothing returns nothing
	local item enumItem = GetEnumItem()
	if enumItem != null and IsQuestItemTypeEither(GetItemTypeId(enumItem), QuestGiver_RemoveItemTypeId, QuestGiver_RemoveFallbackItemTypeId) then
		call RemoveItem(enumItem)
		set QuestGiver_RemovedQuestItemCount = QuestGiver_RemovedQuestItemCount + 1
	endif
	set enumItem = null
endfunction

public function RemoveQuestItemsEverywhereEither takes integer itemTypeId, integer fallbackItemTypeId returns integer
	local group worldUnits
	local rect worldBounds
	local integer removedCount
	if itemTypeId == 0 and fallbackItemTypeId == 0 then
		return 0
	endif
	set QuestGiver_RemoveItemTypeId = itemTypeId
	set QuestGiver_RemoveFallbackItemTypeId = fallbackItemTypeId
	set QuestGiver_RemovedQuestItemCount = 0
	set worldUnits = CreateGroup()
	set worldBounds = GetWorldBounds()
	call GroupEnumUnitsInRect(worldUnits, worldBounds, null)
	call ForGroup(worldUnits, function RemoveQuestItemTypeFromEnumUnit)
	call EnumItemsInRect(worldBounds, null, function RemoveQuestItemTypeFromEnumItem)
	set removedCount = QuestGiver_RemovedQuestItemCount
	call DestroyGroup(worldUnits)
	call RemoveRect(worldBounds)
	set QuestGiver_RemoveItemTypeId = 0
	set QuestGiver_RemoveFallbackItemTypeId = 0
	set QuestGiver_RemovedQuestItemCount = 0
	set worldUnits = null
	set worldBounds = null
	return removedCount
endfunction

public function RemoveHeroItemsEither takes integer itemTypeId, integer fallbackItemTypeId, integer maxToRemove returns nothing
	local group playerUnits = null
	local integer guard = 0
	if itemTypeId == 0 and fallbackItemTypeId == 0 then
		return
	endif
	if maxToRemove <= 0 then
		set maxToRemove = 64
	endif
	if itemTypeId != 0 then
		loop
			exitwhen guard >= maxToRemove or not HeroItemCheckBothAndRemove(itemTypeId, 1)
			set guard = guard + 1
		endloop
	endif
	if fallbackItemTypeId != 0 and fallbackItemTypeId != itemTypeId then
		set guard = 0
		loop
			exitwhen guard >= maxToRemove or not HeroItemCheckBothAndRemove(fallbackItemTypeId, 1)
			set guard = guard + 1
		endloop
	endif
	set QuestGiver_RemoveItemTypeId = itemTypeId
	set QuestGiver_RemoveFallbackItemTypeId = fallbackItemTypeId
	set playerUnits = CreateGroup()
	call GroupEnumUnitsOfPlayer(playerUnits, Player(0), null)
	call ForGroup(playerUnits, function RemoveQuestItemTypeFromEnumUnit)
	call DestroyGroup(playerUnits)
	set QuestGiver_RemoveItemTypeId = 0
	set QuestGiver_RemoveFallbackItemTypeId = 0
	set playerUnits = null
endfunction

public function CreateQuestItem takes integer itemTypeId, integer fallbackItemTypeId, real x, real y returns item
	local item questItem = null
	if itemTypeId != 0 then
		set questItem = CreateItem(itemTypeId, x, y)
	endif
	if questItem == null and fallbackItemTypeId != 0 and fallbackItemTypeId != itemTypeId then
		set questItem = CreateItem(fallbackItemTypeId, x, y)
	endif
	return questItem
endfunction

public function GiveQuestItemToHero takes unit hero, integer itemTypeId, integer fallbackItemTypeId, string itemName returns boolean
	local item questItem
	local real x
	local real y
	if hero == null or not IsUnitAlive(hero) then
		call BJDebugMsg("[QuestGiver] ERROR: Quest item grant skipped because no valid player hero was resolved.")
		set hero = null
		return false
	endif
	if itemTypeId == 0 and fallbackItemTypeId == 0 then
		call BJDebugMsg("[QuestGiver] ERROR: Quest item grant skipped because no item rawcode was provided.")
		set hero = null
		return false
	endif
	set x = GetUnitX(hero)
	set y = GetUnitY(hero)
	set questItem = CreateQuestItem(itemTypeId, fallbackItemTypeId, x, y)
	if questItem == null then
		call BJDebugMsg("[QuestGiver] ERROR: Quest item grant failed because CreateItem returned null.")
		set hero = null
		return false
	endif
	if itemName == "" then
		set itemName = GetItemName(questItem)
	endif
	if UnitAddItem(hero, questItem) then
		set questItem = null
		set hero = null
		return true
	endif
	call SetItemVisible(questItem, true)
	call SetItemPosition(questItem, x, y)
	call BJDebugMsg("[QuestGiver] " + itemName + " inventory grant failed; left a visible ground item at the hero.")
	set questItem = null
	set hero = null
	return false
endfunction

public function GiveUniqueQuestItemToHero takes unit hero, integer itemTypeId, integer fallbackItemTypeId, string itemName returns boolean
	call RemoveQuestItemsEverywhereEither(itemTypeId, fallbackItemTypeId)
	return GiveQuestItemToHero(hero, itemTypeId, fallbackItemTypeId, itemName)
endfunction

public function AddQuestItemRecoveryButtonEither takes dialog d, string questName, unit questGiver, integer actionId, integer itemTypeId, integer fallbackItemTypeId, integer itemAmount, string itemName, code actionFunc returns boolean
	local button b = null
	local integer displayItemTypeId = itemTypeId
	if itemTypeId == 0 and fallbackItemTypeId == 0 then
		return false
	endif
	if not IsQuestActiveByNameAndGiver(questName, questGiver) then
		return false
	endif
	if itemAmount <= 0 then
		set itemAmount = 1
	endif
	if HasHeroItemEither(itemTypeId, fallbackItemTypeId, itemAmount) then
		return false
	endif
	if itemName == "" then
		if displayItemTypeId == 0 then
			set displayItemTypeId = fallbackItemTypeId
		endif
		set itemName = GetObjectName(displayItemTypeId)
	endif
	set b = DialogSystem_AddButtonQuestItemRecovery(d, itemName, actionId)
	if b == null then
		return false
	endif
	call DialogSystem_BindButtonCode(b, actionFunc)
	set b = null
	return true
endfunction

public function AddQuestItemRecoveryButton takes dialog d, string questName, unit questGiver, integer actionId, integer itemTypeId, integer itemAmount, string itemName, code actionFunc returns boolean
	return AddQuestItemRecoveryButtonEither(d, questName, questGiver, actionId, itemTypeId, 0, itemAmount, itemName, actionFunc)
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
	set CompanionIndex = Table.create()
	set CompanionIcon = Table.create()

	// Register with centralized death event system at map start
	call UnitDeathEvent_Register(function OnUnitDeath)
	
	// Map GUI variables to library variables (if they exist in the map)
	// For reference types (groups, sounds), we store the reference
	// For value types (integers), we use udg_ variables directly in the code to avoid state mismatch
	set Companion_Group = udg_Companion_Group
	set CompanionFocusNazgrek = udg_CompanionFocusNazgrek
	set CompanionFocusZulkis = udg_CompanionFocusZulkis
	// Note: udg_CompanionCount is used directly in functions (no local copy)
	set RescueSound = gg_snd_Rescue
	
	// Note: CompanionUnit[] array is maintained separately from udg_CompanionUnit[]
	// CompanionIndex and CompanionIcon use Tables for efficient lookup
endfunction

endlibrary
