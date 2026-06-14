library QuestMaster initializer Init requires Table, SpeciFX, Reputation
//===========================================================================
// QuestMaster
// Core quest data and API scaffolding. Implementation will be expanded.
//===========================================================================
globals
	// Configurable limits
	private constant integer QUEST_MAX = 500

	// Debug
	private constant boolean DEBUG = false

	// Quest states
	constant integer QUEST_STATE_UNAVAILABLE = 1
	constant integer QUEST_STATE_AVAILABLE = 2
	constant integer QUEST_STATE_IN_PROGRESS = 3
	constant integer QUEST_STATE_COMPLETE = 4
	constant integer QUEST_STATE_READY_TURNIN = 5

	// Auto-increment quest ID
	private integer QuestNextId = 1

	// Debug toggle
	private constant boolean QUEST_DEBUG = false

	// Reward defaults (OLDGUI-aligned)
	private constant real REWARD_XP_MULT_DEF = 50.00
	private constant real REWARD_GOLD_MULT_DEF = 50.00
	private constant real REWARD_ARENA_MULT_DEF = 50.00
	private constant real REWARD_REP_MULT_DEF = 1.00

	// Storage tables (TableV6)
	private Table QuestById = 0
	private Table QuestByNameGiver = 0
	private Table QuestByHandle = 0
	private Table QuestSaveTable = 0
	private Table QuestGiverIndex = 0
	private Table QuestGiverTable = 0
	private Table QuestIconTable = 0
	private Table QuestGiverByType = 0  // Maps unit type ID to last registered unit handle ID

	// Quest registry
	private integer QuestCount = 0
	private integer array QuestIdList

	// Quest giver registry and quest lists
	private integer QuestGiverCount = 0
	private unit array QuestGiverList

	// Availability evaluation
	private constant real QUEST_EVAL_INTERVAL = 5.00
	private timer QuestEvalTimer = null
	private boolean array QuestEventFlags
	
	// Quest update message queue
	private constant integer QUEST_UPDATE_QUEUE_MAX = 32
	private constant real QUEST_UPDATE_MESSAGE_GAP = 3.00
	private constant real QUEST_DISCOVERED_DELAY = 5.00
	private constant real QUEST_COMPLETED_DELAY = 5.00
	private constant string QUEST_UPDATE_COLOR_OBJECTIVE_COMPLETE = "|cff80ff80"
	private constant string QUEST_UPDATE_COLOR_OBJECTIVE_UPDATE = "|cff80a0ff"
	private constant string QUEST_UPDATE_COLOR_OBJECTIVE_FAIL = "|cffff4040"
	private constant string QUEST_UPDATE_COLOR_NEW_OBJECTIVE = "|cffffdd00"
	private timer QuestUpdateQueueTimer = null
	private integer QuestUpdateQueueHead = 0
	private integer QuestUpdateQueueTail = 0
	private integer QuestUpdateQueueSize = 0
	private string array QuestUpdateQueue
	private boolean QuestUpdateQueueActive = false
	private Table QuestDiscoveredTimerData = 0
	private Table QuestCompletedTimerData = 0

	// Quest save keys (handle id based)
	private constant integer QUEST_SAVE_ID_KEY = 0
	private constant integer QUEST_SAVE_TYPE_KEY = 1
	private constant integer QUEST_SAVE_GIVER_KEY = 2
	private constant integer QUEST_SAVE_STATE_KEY = 3

	private integer QuestRewardCurrentXP = 0
	private unit QuestRewardPrimaryHero = null

	// Quest icon system (embedded)

	// Model paths
	private constant string QUEST_ICON_MODEL_YELLOW_EXCLAMATION = "war3campImported\\ExcMark_Gold_NonrepeatableQuest.mdl"
	private constant string QUEST_ICON_MODEL_BLUE_EXCLAMATION = "war3campImported\\ExcMark_Blue_RepetableQuest.mdl"
	private constant string QUEST_ICON_MODEL_YELLOW_QUESTION = "war3campImported\\Completed_Quest.mdl"
	private constant string QUEST_ICON_MODEL_BLUE_QUESTION = "war3campImported\\Completed_Quest_Daily.mdl"
	private constant string QUEST_ICON_MODEL_GRAY_QUESTION = "war3campImported\\Completed_Quest_NOT.mdl"
	private constant string QUEST_ICON_MODEL_GRAY_EXCLAMATION = "war3campImported\\ExcMark_Grey_UnavailableQuest.mdl"

	private integer QUEST_ICON_EFFECT_ID = StringHash("effect")
	private integer QUEST_ICON_MINIMAP_ID = StringHash("minimaps")
	private integer QUEST_ICON_QUESTS_ID = StringHash("quests")

	private minimapicon array QuestIconMapPing
	private integer MinimapIconIndex = 0

	// Per-unit quest list key offsets
	integer QUEST_ID_KEY = 1
	integer QUEST_TYPE_KEY = 2
	integer QUEST_STATE_KEY = 3
	integer NPC_QUEST_COUNT_KEY = 4

	constant integer QUEST_PRIORITY_STATE_5 = 5
	constant integer QUEST_PRIORITY_STATE_2 = 4
	constant integer QUEST_PRIORITY_STATE_3 = 3
	constant integer QUEST_PRIORITY_STATE_1 = 2
	constant integer QUEST_PRIORITY_STATE_4 = 1

	constant integer QUEST_DUMMY_OFFSET = 1000

	// State change event bridge
	trigger QuestMaster_OnStateChanged = null
	integer QuestMaster_EventQuestId = 0
	integer QuestMaster_EventState = 0
endglobals

//===========================================================================
// Debug helpers
//===========================================================================
private function DebugMsg takes string msg returns nothing
	if DEBUG then
		call BJDebugMsg("[QuestMaster] " + msg)
	endif
endfunction

private function AwardCompanionRewardXPEnum takes nothing returns nothing
	local unit u = GetEnumUnit()
	if QuestRewardCurrentXP <= 0 then
		set u = null
		return
	endif
	if u != null and IsUnitType(u, UNIT_TYPE_HERO) then
		call AddHeroXP(u, QuestRewardCurrentXP, true)
		if QuestRewardPrimaryHero == null then
			set QuestRewardPrimaryHero = u
		endif
	endif
	set u = null
endfunction

//===========================================================================
// Quest update message queue
//===========================================================================
private function ShowDelayedQuestDiscovered takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local integer tId = GetHandleId(t)
	local QuestData q = QuestDiscoveredTimerData[tId]
	local string msg
	local string objectives
	
	// Safety: validate quest data exists and is discovered
	if q != 0 and q.discovered and q.title != "" then
		// Update icons now (delayed to match message)
		call q.updateIcons()
		
		set msg = "|cffffcc00QUEST DISCOVERED|r\n" + q.title
		set objectives = q.formatObjectivesList()
		if objectives != "" then
			set msg = msg + "\n\n" + objectives
		endif
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_DISCOVERED, msg)
		call FlashQuestDialogButtonBJ()
	endif
	
	// Clean up timer data
	if QuestDiscoveredTimerData.has(tId) then
		call QuestDiscoveredTimerData.remove(tId)
	endif
	call DestroyTimer(t)
	set t = null
endfunction

private function ShowDelayedQuestCompleted takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local integer tId = GetHandleId(t)
	local QuestData q = QuestCompletedTimerData[tId]
	
	// Safety: validate quest data exists and is completed
	if q != 0 and q.completed and q.title != "" then
		// Update icons now (delayed to match message)
		call q.updateIcons()
		
		call q.showCompletedMessage()
	endif
	
	// Clean up timer data
	if QuestCompletedTimerData.has(tId) then
		call QuestCompletedTimerData.remove(tId)
	endif
	call DestroyTimer(t)
	set t = null
endfunction

private function ShowNextQuestUpdate takes nothing returns nothing
	local string msg
	
	// Safety: validate queue state
	if QuestUpdateQueueSize <= 0 or QuestUpdateQueueHead <= 0 or QuestUpdateQueueHead > QUEST_UPDATE_QUEUE_MAX then
		set QuestUpdateQueueActive = false
		return
	endif
	
	set msg = QuestUpdateQueue[QuestUpdateQueueHead]
	set QuestUpdateQueue[QuestUpdateQueueHead] = "" // Clear after reading
	
	set QuestUpdateQueueHead = QuestUpdateQueueHead + 1
	if QuestUpdateQueueHead > QUEST_UPDATE_QUEUE_MAX then
		set QuestUpdateQueueHead = 1
	endif
	set QuestUpdateQueueSize = QuestUpdateQueueSize - 1
	
	// Safety: only show non-empty messages
	if msg != "" then
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_UPDATED, msg)
		call FlashQuestDialogButtonBJ()
	endif
	
	if QuestUpdateQueueSize > 0 then
		if QuestUpdateQueueTimer == null then
			set QuestUpdateQueueTimer = CreateTimer()
		endif
		call TimerStart(QuestUpdateQueueTimer, QUEST_UPDATE_MESSAGE_GAP, false, function ShowNextQuestUpdate)
	else
		set QuestUpdateQueueActive = false
	endif
endfunction

private function EnqueueQuestUpdateMessage takes string msg returns nothing
	// Safety: validate message and queue bounds
	if msg == "" then
		return
	endif
	if QuestUpdateQueueSize >= QUEST_UPDATE_QUEUE_MAX then
		// Queue full - drop oldest message or skip
		return
	endif
	
	// Initialize queue indices if needed
	if QuestUpdateQueueHead == 0 then
		set QuestUpdateQueueHead = 1
		set QuestUpdateQueueTail = 0
	endif
	
	// If queue is not active, show message immediately without delay
	// This provides instant feedback for item pickups and unit kills
	if not QuestUpdateQueueActive then
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_UPDATED, msg)
		call FlashQuestDialogButtonBJ()
		set QuestUpdateQueueActive = true
		// Start timer for next message (if any arrive)
		if QuestUpdateQueueTimer == null then
			set QuestUpdateQueueTimer = CreateTimer()
		endif
		call TimerStart(QuestUpdateQueueTimer, QUEST_UPDATE_MESSAGE_GAP, false, function ShowNextQuestUpdate)
		return
	endif
	
	// Queue is active - add to queue for delayed display
	// Advance tail pointer with wraparound
	set QuestUpdateQueueTail = QuestUpdateQueueTail + 1
	if QuestUpdateQueueTail > QUEST_UPDATE_QUEUE_MAX then
		set QuestUpdateQueueTail = 1
	endif
	
	// Safety: validate tail index before writing
	if QuestUpdateQueueTail < 1 or QuestUpdateQueueTail > QUEST_UPDATE_QUEUE_MAX then
		return
	endif
	
	set QuestUpdateQueue[QuestUpdateQueueTail] = msg
	set QuestUpdateQueueSize = QuestUpdateQueueSize + 1
endfunction

//===========================================================================
// Key helpers
//===========================================================================
private function NameGiverKey takes string questName, unit questGiver returns integer
	local integer giverId = 0
	if questGiver != null then
		set giverId = GetHandleId(questGiver)
	endif
	return StringHash(questName + "#" + I2S(giverId))
endfunction

//===========================================================================
// Quest giver registry helpers
//===========================================================================
private function RegisterGiverInternal takes unit u returns nothing
	local integer id
	local integer index
	local integer unitTypeId

	if u == null then
		return
	endif
	set id = GetHandleId(u)
	set index = QuestGiverIndex.integer[id]
	if index != 0 then
		return
	endif

	set QuestGiverCount = QuestGiverCount + 1
	set QuestGiverList[QuestGiverCount] = u
	set QuestGiverIndex.integer[id] = QuestGiverCount
	
	// Track unit type ID to handle ID mapping for respawn support
	set unitTypeId = GetUnitTypeId(u)
	if unitTypeId != 0 then
		set QuestGiverByType.integer[unitTypeId] = id
	endif
endfunction

private function UnregisterGiverInternal takes unit u returns nothing
	local integer id
	local integer index
	local integer lastIndex
	local unit lastUnit
	local Table giverTable

	if u == null then
		return
	endif
	set id = GetHandleId(u)
	set index = QuestGiverIndex.integer[id]
	if index == 0 then
		return
	endif

	set lastIndex = QuestGiverCount
	if lastIndex > 0 and index != lastIndex then
		set lastUnit = QuestGiverList[lastIndex]
		set QuestGiverList[index] = lastUnit
		set QuestGiverIndex.integer[GetHandleId(lastUnit)] = index
	endif
	set QuestGiverList[lastIndex] = null
	set QuestGiverCount = QuestGiverCount - 1
	set QuestGiverIndex.integer[id] = 0
	if QuestGiverTable.has(id) then
		set giverTable = QuestGiverTable[id]
		call giverTable.destroy()
		call QuestGiverTable.remove(id)
	endif
endfunction

private function AddQuestToGiverList takes unit u, integer questId returns nothing
	local integer id
	local integer count
	local integer i = 1
	local Table giverTable

	if u == null then
		return
	endif
	call RegisterGiverInternal(u)
	set id = GetHandleId(u)
	set giverTable = QuestGiverTable.link(id)
	set count = giverTable.integer[0]
	loop
		exitwhen i > count
		if giverTable.integer[i] == questId then
			return
		endif
		set i = i + 1
	endloop

	set count = count + 1
	set giverTable.integer[0] = count
	set giverTable.integer[count] = questId
endfunction

private function GetGiverQuestCountInternal takes unit u returns integer
	local integer id
	if u == null then
		return 0
	endif
	set id = GetHandleId(u)
	if not QuestGiverTable.has(id) then
		return 0
	endif
	return QuestGiverTable[id].integer[0]
endfunction

private function GetGiverQuestIdByIndexInternal takes unit u, integer index returns integer
	local integer id
	if u == null or index <= 0 then
		return 0
	endif
	set id = GetHandleId(u)
	if not QuestGiverTable.has(id) then
		return 0
	endif
	return QuestGiverTable[id].integer[index]
endfunction

//===========================================================================
// Quest icon helpers (embedded)
//===========================================================================
public function GetById takes integer questId returns QuestData
	return QuestById.integer[ questId ]
endfunction

public function StoreQuestMinimapIcon takes unit u, minimapicon mi returns nothing
	local Table iconTable
	if u == null then
		return
	endif
	set iconTable = QuestIconTable.link(GetHandleId(u))
	if mi != null then
		set QuestIconMapPing[MinimapIconIndex] = mi
		set iconTable.integer[QUEST_ICON_MINIMAP_ID] = MinimapIconIndex
		set MinimapIconIndex = MinimapIconIndex + 1
	endif
endfunction

private function GetQuestMinimapIcon takes unit u returns minimapicon
	local integer index
	local integer id
	if u == null then
		return null
	endif
	set id = GetHandleId(u)
	if not QuestIconTable.has(id) then
		return null
	endif
	set index = QuestIconTable[id].integer[QUEST_ICON_MINIMAP_ID]
	if index >= 0 and index < MinimapIconIndex then
		return QuestIconMapPing[index]
	endif
	return null
endfunction

private function RemoveOldMapPing takes unit u returns nothing
	local integer index
	local integer id
	local Table iconTable
	if u == null then
		return
	endif
	set id = GetHandleId(u)
	if not QuestIconTable.has(id) then
		return
	endif
	set iconTable = QuestIconTable[id]
	set index = iconTable.integer[QUEST_ICON_MINIMAP_ID]
	if index >= 0 and index < MinimapIconIndex then
		call DestroyMinimapIcon(QuestIconMapPing[index])
		set QuestIconMapPing[index] = null
		call iconTable.integer.remove(QUEST_ICON_MINIMAP_ID)
	endif
endfunction

private function CreateMapPingForUnit takes unit u, integer style returns nothing
	local minimapicon qi

	call RemoveOldMapPing(u)
	call CampaignMinimapIconUnitBJ(u, style)
	set qi = GetLastCreatedMinimapIcon()
	if qi != null then
		call StoreQuestMinimapIcon(u, qi)
	endif
endfunction

private function RemoveOldEffect takes unit u returns nothing
	local integer id = GetHandleId(u)
	local effect old
	local Table iconTable
	if not QuestIconTable.has(id) then
		return
	endif
	set iconTable = QuestIconTable[id]
	set old = iconTable.effect[QUEST_ICON_EFFECT_ID]
	if old != null then
		call DestroyEffect(old)
		set iconTable.effect[QUEST_ICON_EFFECT_ID] = null
	endif
endfunction

public function IconRefresh takes unit u, integer questID, string questType, integer questState returns nothing
	local string model = ""
	local effect e
	local integer pingStyle = -1
	local Table iconTable

	call RemoveOldEffect(u)
	call RemoveOldMapPing(u)

	if questState == QUEST_STATE_UNAVAILABLE then
		set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
		set pingStyle = -1
	elseif questState == QUEST_STATE_AVAILABLE then
		if questType == "daily" or questType == "repeatable" then
			set model = QUEST_ICON_MODEL_BLUE_EXCLAMATION
		elseif questType == "normal" or questType == "dungeon" then
			set model = QUEST_ICON_MODEL_YELLOW_EXCLAMATION
		else
			set model = QUEST_ICON_MODEL_GRAY_EXCLAMATION
		endif
		set pingStyle = bj_CAMPPINGSTYLE_BONUS
	elseif questState == QUEST_STATE_IN_PROGRESS then
		set model = QUEST_ICON_MODEL_GRAY_QUESTION
		set pingStyle = bj_CAMPPINGSTYLE_BONUS
	elseif questState == QUEST_STATE_READY_TURNIN then
		if questType == "daily" or questType == "repeatable" then
			set model = QUEST_ICON_MODEL_BLUE_QUESTION
		elseif questType == "normal" or questType == "dungeon" then
			set model = QUEST_ICON_MODEL_YELLOW_QUESTION
		else
			set model = QUEST_ICON_MODEL_GRAY_QUESTION
		endif
		set pingStyle = bj_CAMPPINGSTYLE_TURNIN
	endif

	if model != "" then
		set e = AddSpecialEffectTarget(model, u, "overhead")
		call SpeciFX_MarkAsExcluded(e)
		set iconTable = QuestIconTable.link(GetHandleId(u))
		set iconTable.effect[QUEST_ICON_EFFECT_ID] = e
	endif

	if pingStyle != -1 then
		call CreateMapPingForUnit(u, pingStyle)
	endif
endfunction

private function IconStatePriority takes integer state returns integer
	if state == QUEST_STATE_READY_TURNIN then
		return QUEST_PRIORITY_STATE_5
	elseif state == QUEST_STATE_IN_PROGRESS then
		return QUEST_PRIORITY_STATE_2
	elseif state == QUEST_STATE_AVAILABLE then
		return QUEST_PRIORITY_STATE_3
	elseif state == QUEST_STATE_UNAVAILABLE then
		return QUEST_PRIORITY_STATE_1
	endif
	return QUEST_PRIORITY_STATE_4
endfunction

private function IconTypePriority takes string questType returns integer
	if questType == "normal" or questType == "dungeon" then
		return 3
	elseif questType == "daily" or questType == "repeatable" then
		return 2
	endif
	return 1
endfunction

public function IconUpdateForNPC takes unit u returns nothing
	local integer questID
	local integer questCount
	local integer i = 0
	local integer bestState = QUEST_STATE_COMPLETE
	local string bestType = ""
	local integer statePriority
	local integer typePriority
	local integer bestStatePriority = 0
	local integer bestTypePriority = 0
	local integer id = GetHandleId(u)
	local integer curState = QUEST_STATE_COMPLETE
	local string curType = ""
	local Table iconTable
	local QuestData q
	if QuestIconTable.has(id) then
		set iconTable = QuestIconTable[id]
		set questCount = iconTable.integer[NPC_QUEST_COUNT_KEY]
		loop
			exitwhen i >= questCount
			set questID = iconTable.integer[i*100 + QUEST_ID_KEY]
			set curState = iconTable.integer[i*100 + QUEST_STATE_KEY]
			set curType = iconTable.string[i*100 + QUEST_TYPE_KEY]
			set statePriority = IconStatePriority(curState)
			set typePriority = IconTypePriority(curType)
			if statePriority > bestStatePriority or (statePriority == bestStatePriority and typePriority > bestTypePriority) then
				set bestStatePriority = statePriority
				set bestTypePriority = typePriority
				set bestState = curState
				set bestType = curType
			endif
			set i = i + 1
		endloop
	else
		set questCount = 0
	endif

	if questCount == 0 then
		set questCount = GetGiverQuestCountInternal(u)
		set i = 1
		loop
			exitwhen i > questCount
			set questID = GetGiverQuestIdByIndexInternal(u, i)
			if questID != 0 then
				set q = GetById(questID)
				if q != 0 then
					set curState = q.state
					set curType = q.questType
				set statePriority = IconStatePriority(curState)
				set typePriority = IconTypePriority(curType)
				if statePriority > bestStatePriority or (statePriority == bestStatePriority and typePriority > bestTypePriority) then
					set bestStatePriority = statePriority
					set bestTypePriority = typePriority
					set bestState = curState
					set bestType = curType
				endif
				endif
			endif
			set i = i + 1
		endloop
	endif

	if bestState != QUEST_STATE_COMPLETE then
		call IconRefresh(u, -1, bestType, bestState)
	else
		call RemoveOldEffect(u)
		call RemoveOldMapPing(u)
	endif
endfunction

public function IconRegisterQuest takes unit u, integer questID, string questType, integer questState returns nothing
	local integer id = GetHandleId(u)
	local Table iconTable = QuestIconTable.link(id)
	local integer count = iconTable.integer[NPC_QUEST_COUNT_KEY]
	local integer i = 0
	local integer existingQuestID = 0
	local boolean updated = false

	loop
		exitwhen i >= count
		set existingQuestID = iconTable.integer[i*100 + QUEST_ID_KEY]
		if existingQuestID == questID then
			set iconTable.string[i*100 + QUEST_TYPE_KEY] = questType
			set iconTable.integer[i*100 + QUEST_STATE_KEY] = questState
			set updated = true
			exitwhen true
		endif
		set i = i + 1
	endloop

	if not updated then
		set iconTable.integer[count*100 + QUEST_ID_KEY] = questID
		set iconTable.string[count*100 + QUEST_TYPE_KEY] = questType
		set iconTable.integer[count*100 + QUEST_STATE_KEY] = questState
		set iconTable.integer[NPC_QUEST_COUNT_KEY] = count + 1
	endif

	call IconUpdateForNPC(u)
endfunction

public function IconRemoveQuest takes unit u, integer questID returns nothing
	local integer id = GetHandleId(u)
	local Table iconTable
	local integer count
	local integer i = 0
	local integer j = 0
	local integer foundIndex = -1
	local integer curID = 0
	if not QuestIconTable.has(id) then
		return
	endif
	set iconTable = QuestIconTable[id]
	set count = iconTable.integer[NPC_QUEST_COUNT_KEY]

	loop
		exitwhen i >= count
		set curID = iconTable.integer[i*100 + QUEST_ID_KEY]
		if curID == questID then
			set foundIndex = i
			exitwhen true
		endif
		set i = i + 1
	endloop

	if foundIndex == -1 then
		return
	endif

	set j = foundIndex
	loop
		exitwhen j >= count - 1
		set iconTable.integer[j*100 + QUEST_ID_KEY] = iconTable.integer[(j+1)*100 + QUEST_ID_KEY]
		set iconTable.string[j*100 + QUEST_TYPE_KEY] = iconTable.string[(j+1)*100 + QUEST_TYPE_KEY]
		set iconTable.integer[j*100 + QUEST_STATE_KEY] = iconTable.integer[(j+1)*100 + QUEST_STATE_KEY]
		set j = j + 1
	endloop

	call iconTable.integer.remove((count-1)*100 + QUEST_ID_KEY)
	call iconTable.string.remove((count-1)*100 + QUEST_TYPE_KEY)
	call iconTable.integer.remove((count-1)*100 + QUEST_STATE_KEY)
	set iconTable.integer[NPC_QUEST_COUNT_KEY] = count - 1

	call IconUpdateForNPC(u)
endfunction

public function CreateDummyQuestIcon takes unit u, string questType, integer questState returns nothing
	if u == null then
		return
	endif
	call IconRegisterQuest(u, QUEST_DUMMY_OFFSET + GetHandleId(u), questType, questState)
endfunction

public function RemoveDummyQuestIcon takes unit u returns nothing
	if u == null then
		return
	endif
	call IconRemoveQuest(u, QUEST_DUMMY_OFFSET + GetHandleId(u))
endfunction

public function StateChanged takes integer questId, integer newState returns nothing
	// Notify listeners (e.g., QuestIconsv2) about quest state changes.
	if QuestMaster_OnStateChanged == null then
		return
	endif
	set QuestMaster_EventQuestId = questId
	set QuestMaster_EventState = newState
	call TriggerExecute(QuestMaster_OnStateChanged)
endfunction

public function AddStateChangedAction takes code actionFunc returns nothing
	// Register a listener to react to quest state changes without coupling to QuestMaster.
	// Usage: call AddStateChangedAction(function YourStateChangedHandler)
	if QuestMaster_OnStateChanged == null then
		return
	endif
	call TriggerAddAction(QuestMaster_OnStateChanged, actionFunc)
endfunction

//===========================================================================
// QuestData struct
//===========================================================================
struct QuestData
	integer id
	string name
	string questType
	unit giver
	unit receiver
	integer questLevel
	integer giverLevel
	integer requiredLevel
	boolean useAllowedHeroesForLevelCheck
	boolean levelCheckAllowNazgrek
	boolean levelCheckAllowZulkis
	string faction
	integer requiredReputation
	trigger customCondition
	integer eventFlagIndex
	integer requiredCompletedQuestCount
	string requiredCompletedQuest1
	string requiredCompletedQuest2
	string requiredCompletedQuest3
	string requiredCompletedQuest4
	unit requiredCompletedQuestGiver1
	unit requiredCompletedQuestGiver2
	unit requiredCompletedQuestGiver3
	unit requiredCompletedQuestGiver4
	integer lastEvalState
	string failReasonText

	// Quest log data
	string title
	string description
	string iconPath
	string infoText
	string info2Text
	string rewardsHeading
	string rewardsText
	string requirementHeading

	string requirement1
	string requirement2
	string requirement3
	string requirement4
	string requirement5
	string requirement6
	string requirement7
	string requirement8

	string rewardLine1
	string rewardLine2
	string rewardLine3
	string rewardLine4
	string rewardLine5

	quest wcQuest
	questitem req1
	questitem req2
	questitem req3
	questitem req4
	questitem req5
	questitem req6
	questitem req7
	questitem req8

	// Requirement completion tracking
	boolean req1Completed
	boolean req2Completed
	boolean req3Completed
	boolean req4Completed
	boolean req5Completed
	boolean req6Completed
	boolean req7Completed
	boolean req8Completed

	// State flags
	boolean discovered
	boolean active
	boolean completed
	boolean failed

	integer state

	// Return requirement tracking
	integer returnReqIndex
	boolean hasReturnReq

	// Autocomplete support (quest completes without returning to giver)
	boolean autoCompletes

	// GoToPlace/GoToZone tracking
	rect targetRect
	integer targetZoneId

	// Display names for quest giver and receiver (for quest log and return requirements)
	string giverDisplayName
	string receiverDisplayName

	// Reward parameters (values computed on create)
	integer rewardXP
	integer rewardGold
	integer rewardArena
	integer rewardRep
	boolean rewardRepLinked
	integer rewardItemType
	string rewardItemText

	boolean rewardXPActive
	boolean rewardGoldActive
	boolean rewardArenaActive
	boolean rewardRepActive
	boolean rewardItemActive

	integer rewardXPAdjust
	integer rewardGoldAdjust
	integer rewardArenaAdjust
	integer rewardRepAdjust

	real rewardXPMult
	real rewardGoldMult
	real rewardArenaMult
	real rewardRepMult

	static method create takes string questName, unit questGiver, string qType, integer qLevel, unit questReceiver returns thistype
		local thistype this = thistype.allocate()

		set this.id = QuestNextId
		set QuestNextId = QuestNextId + 1

		set this.name = questName
		set this.giver = questGiver
		// If no questReceiver provided, default to questGiver
		if questReceiver == null then
			set this.receiver = questGiver
		else
			set this.receiver = questReceiver
		endif
		set this.questType = qType
		set this.questLevel = qLevel
		if questGiver != null then
			set this.giverLevel = GetHeroLevel(questGiver)
		else
			set this.giverLevel = 0
		endif

		set this.discovered = false
		set this.active = false
		set this.completed = false
		set this.failed = false
		set this.state = QUEST_STATE_UNAVAILABLE
		set this.lastEvalState = QUEST_STATE_UNAVAILABLE
		set this.requiredCompletedQuestCount = 0
		set this.requiredCompletedQuest1 = ""
		set this.requiredCompletedQuest2 = ""
		set this.requiredCompletedQuest3 = ""
		set this.requiredCompletedQuest4 = ""
		set this.requiredCompletedQuestGiver1 = null
		set this.requiredCompletedQuestGiver2 = null
		set this.requiredCompletedQuestGiver3 = null
		set this.requiredCompletedQuestGiver4 = null

		set this.title = ""
		set this.description = ""
		set this.iconPath = ""
		set this.infoText = ""
		set this.info2Text = ""
		set this.rewardsHeading = ""
		set this.rewardsText = ""
		set this.requirementHeading = ""

		set this.requirement1 = ""
		set this.requirement2 = ""
		set this.requirement3 = ""
		set this.requirement4 = ""
		set this.requirement5 = ""
		set this.requirement6 = ""
		set this.requirement7 = ""
		set this.requirement8 = ""

		set this.rewardLine1 = ""
		set this.rewardLine2 = ""
		set this.rewardLine3 = ""
		set this.rewardLine4 = ""
		set this.rewardLine5 = ""

		set this.wcQuest = null
		set this.req1 = null
		set this.req2 = null
		set this.req3 = null
		set this.req4 = null
		set this.req5 = null
		set this.req6 = null
		set this.req7 = null
		set this.req8 = null

		set this.req1Completed = false
		set this.req2Completed = false
		set this.req3Completed = false
		set this.req4Completed = false
		set this.req5Completed = false
		set this.req6Completed = false
		set this.req7Completed = false
		set this.req8Completed = false

		set this.rewardXP = 0
		set this.rewardGold = 0
		set this.rewardArena = 0
		set this.rewardRep = 0
		set this.rewardRepLinked = false
		set this.rewardItemType = 0
		set this.rewardItemText = ""

		set this.rewardXPActive = false
		set this.rewardGoldActive = false
		set this.rewardArenaActive = false
		set this.rewardRepActive = false
		set this.rewardItemActive = false

		set this.rewardXPAdjust = 0
		set this.rewardGoldAdjust = 0
		set this.rewardArenaAdjust = 0
		set this.rewardRepAdjust = 0

		set this.rewardXPMult = REWARD_XP_MULT_DEF
		set this.rewardGoldMult = REWARD_GOLD_MULT_DEF
		set this.rewardArenaMult = REWARD_ARENA_MULT_DEF
		set this.rewardRepMult = REWARD_REP_MULT_DEF

		set this.requiredLevel = 0
		set this.useAllowedHeroesForLevelCheck = false
		set this.levelCheckAllowNazgrek = true
		set this.levelCheckAllowZulkis = true
		set this.faction = ""
		set this.requiredReputation = 0
		set this.customCondition = null
		set this.eventFlagIndex = 0
		set this.failReasonText = ""
		set this.returnReqIndex = 0
		set this.hasReturnReq = false
		set this.autoCompletes = false
		set this.targetRect = null
		set this.targetZoneId = 0
		set this.giverDisplayName = ""
		set this.receiverDisplayName = ""

		// TODO: compute rewards, requirements, and text data

		// Register by id/name/giver
		set QuestById.integer[ this.id ] = this
		set QuestByNameGiver.integer[ NameGiverKey(questName, questGiver) ] = this
		set QuestCount = QuestCount + 1
		set QuestIdList[QuestCount] = this.id
		if questGiver != null then
			call AddQuestToGiverList(questGiver, this.id)
		endif

		if questGiver != null then
			call IconRegisterQuest(questGiver, this.id, this.questType, this.state)
		endif

		return this
	endmethod

	method setRequirement takes integer index, string text returns nothing
		if index == 1 then
			set this.requirement1 = text
		elseif index == 2 then
			set this.requirement2 = text
		elseif index == 3 then
			set this.requirement3 = text
		elseif index == 4 then
			set this.requirement4 = text
		elseif index == 5 then
			set this.requirement5 = text
		elseif index == 6 then
			set this.requirement6 = text
		elseif index == 7 then
			set this.requirement7 = text
		elseif index == 8 then
			set this.requirement8 = text
		endif
	endmethod

	method getRequirementText takes integer index returns string
		if index == 1 then
			return this.requirement1
		elseif index == 2 then
			return this.requirement2
		elseif index == 3 then
			return this.requirement3
		elseif index == 4 then
			return this.requirement4
		elseif index == 5 then
			return this.requirement5
		elseif index == 6 then
			return this.requirement6
		elseif index == 7 then
			return this.requirement7
		elseif index == 8 then
			return this.requirement8
		endif
		return ""
	endmethod

	method createQuestLog takes nothing returns nothing
		if this.wcQuest != null then
			return
		endif
		set this.wcQuest = CreateQuest()
		set QuestByHandle.integer[ GetHandleId(this.wcQuest) ] = this.id
		call QuestSetTitle(this.wcQuest, this.title)
		call QuestSetDescription(this.wcQuest, this.formatQuestDescription())
		call QuestSetIconPath(this.wcQuest, this.iconPath)
		call QuestSetRequired(this.wcQuest, true)
		call QuestSetDiscovered(this.wcQuest, false)
		call QuestSetFailed(this.wcQuest, false)
	endmethod

	method applyRequirementsToLog takes nothing returns nothing
		if this.requirement1 != "" then
			call this.addRequirement(1, this.requirement1)
		endif
		if this.requirement2 != "" then
			call this.addRequirement(2, this.requirement2)
		endif
		if this.requirement3 != "" then
			call this.addRequirement(3, this.requirement3)
		endif
		if this.requirement4 != "" then
			call this.addRequirement(4, this.requirement4)
		endif
		if this.requirement5 != "" then
			call this.addRequirement(5, this.requirement5)
		endif
		if this.requirement6 != "" then
			call this.addRequirement(6, this.requirement6)
		endif
		if this.requirement7 != "" then
			call this.addRequirement(7, this.requirement7)
		endif
		if this.requirement8 != "" then
			call this.addRequirement(8, this.requirement8)
		endif
	endmethod

	method setDiscovered takes boolean flag returns nothing
		if this.wcQuest == null then
			call this.createQuestLog()
		endif
		call QuestSetDiscovered(this.wcQuest, flag)
		set this.discovered = flag
	endmethod

	method setCompleted takes boolean flag returns nothing
		if this.wcQuest == null then
			call this.createQuestLog()
		endif
		call QuestSetCompleted(this.wcQuest, flag)
		set this.completed = flag
	endmethod

	method refreshQuestLog takes nothing returns nothing
		if this.wcQuest == null then
			return
		endif
		call QuestSetTitle(this.wcQuest, this.title)
		call QuestSetDescription(this.wcQuest, this.formatQuestDescription())
		call QuestSetIconPath(this.wcQuest, this.iconPath)
	endmethod

	method addRequirement takes integer index, string text returns nothing
		local questitem qi
		if this.wcQuest == null then
			call this.createQuestLog()
		endif
		if index == 1 then
			if this.req1 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req1 = qi
			else
				set qi = this.req1
			endif
		elseif index == 2 then
			if this.req2 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req2 = qi
			else
				set qi = this.req2
			endif
		elseif index == 3 then
			if this.req3 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req3 = qi
			else
				set qi = this.req3
			endif
		elseif index == 4 then
			if this.req4 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req4 = qi
			else
				set qi = this.req4
			endif
		elseif index == 5 then
			if this.req5 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req5 = qi
			else
				set qi = this.req5
			endif
		elseif index == 6 then
			if this.req6 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req6 = qi
			else
				set qi = this.req6
			endif
		elseif index == 7 then
			if this.req7 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req7 = qi
			else
				set qi = this.req7
			endif
		elseif index == 8 then
			if this.req8 == null then
				set qi = QuestCreateItem(this.wcQuest)
				set this.req8 = qi
			else
				set qi = this.req8
			endif
		endif
		if qi != null then
			call QuestItemSetDescription(qi, text)
		elseif text != "" then
			call this.addRequirement(index, text)
		endif
	endmethod

	method markRequirementCompleted takes integer index, boolean flag returns nothing
		if index == 1 and this.req1 != null then
			call QuestItemSetCompleted(this.req1, flag)
			set this.req1Completed = flag
		elseif index == 2 and this.req2 != null then
			call QuestItemSetCompleted(this.req2, flag)
			set this.req2Completed = flag
		elseif index == 3 and this.req3 != null then
			call QuestItemSetCompleted(this.req3, flag)
			set this.req3Completed = flag
		elseif index == 4 and this.req4 != null then
			call QuestItemSetCompleted(this.req4, flag)
			set this.req4Completed = flag
		elseif index == 5 and this.req5 != null then
			call QuestItemSetCompleted(this.req5, flag)
			set this.req5Completed = flag
		elseif index == 6 and this.req6 != null then
			call QuestItemSetCompleted(this.req6, flag)
			set this.req6Completed = flag
		elseif index == 7 and this.req7 != null then
			call QuestItemSetCompleted(this.req7, flag)
			set this.req7Completed = flag
		elseif index == 8 and this.req8 != null then
			call QuestItemSetCompleted(this.req8, flag)
			set this.req8Completed = flag
		endif
	endmethod

	method updateRequirementText takes integer index, string text returns nothing
		local questitem qi = null
		if index == 1 then
			set this.requirement1 = text
			set qi = this.req1
		elseif index == 2 then
			set this.requirement2 = text
			set qi = this.req2
		elseif index == 3 then
			set this.requirement3 = text
			set qi = this.req3
		elseif index == 4 then
			set this.requirement4 = text
			set qi = this.req4
		elseif index == 5 then
			set this.requirement5 = text
			set qi = this.req5
		elseif index == 6 then
			set this.requirement6 = text
			set qi = this.req6
		elseif index == 7 then
			set this.requirement7 = text
			set qi = this.req7
		elseif index == 8 then
			set this.requirement8 = text
			set qi = this.req8
		endif
		if qi != null then
			call QuestItemSetDescription(qi, text)
		elseif text != "" then
			call this.addRequirement(index, text)
		endif
	endmethod

	method setRewardLine takes integer index, string text returns nothing
		if index == 1 then
			set this.rewardLine1 = text
		elseif index == 2 then
			set this.rewardLine2 = text
		elseif index == 3 then
			set this.rewardLine3 = text
		elseif index == 4 then
			set this.rewardLine4 = text
		elseif index == 5 then
			set this.rewardLine5 = text
		endif
		call this.buildRewardsText()
	endmethod

	method buildRewardsText takes nothing returns nothing
		set this.rewardsText = this.rewardLine1 + this.rewardLine2 + this.rewardLine3 + this.rewardLine4 + this.rewardLine5
		if this.rewardsText != "" then
			if this.rewardsHeading == "" then
				set this.rewardsHeading = "|cffffcc00Rewards:|r\n"
			endif
		else
			set this.rewardsHeading = ""
		endif
	endmethod

	method addReturnRequirement takes nothing returns nothing
		local string reqText
		local string giverName
		local integer targetIndex = 0
		
		// Don't add if already present
		if this.hasReturnReq then
			return
		endif
		
		// Find first empty requirement slot (1-8)
		if this.requirement1 == "" then
			set targetIndex = 1
		elseif this.requirement2 == "" then
			set targetIndex = 2
		elseif this.requirement3 == "" then
			set targetIndex = 3
		elseif this.requirement4 == "" then
			set targetIndex = 4
		elseif this.requirement5 == "" then
			set targetIndex = 5
		elseif this.requirement6 == "" then
			set targetIndex = 6
		elseif this.requirement7 == "" then
			set targetIndex = 7
		elseif this.requirement8 == "" then
			set targetIndex = 8
		else
			// All slots full - use index 8 anyway
			set targetIndex = 8
		endif
		
		if targetIndex > 0 then
			// Build return text using stored receiver display name
			if this.receiverDisplayName != "" then
				set giverName = this.receiverDisplayName
			elseif this.receiver != null then
				// Fallback to GetUnitName if display name not set
				set giverName = GetUnitName(this.receiver)
			else
				set giverName = "quest giver"
			endif
			set reqText = "Return to " + giverName
			
			// Add the requirement (NOT completed yet - player must return to NPC)
			call this.setRequirement(targetIndex, reqText)
			call this.addRequirement(targetIndex, reqText)
			call this.refreshQuestLog()
			
			// Track it
			set this.returnReqIndex = targetIndex
			set this.hasReturnReq = true
			
			// Show quest update message with new return objective
			if this.title != "" then
				call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + this.title + "\n\n" + QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objective:|r " + reqText)
			endif
			
			call DebugMsg("Added return requirement at index " + I2S(targetIndex) + ": " + reqText)
		endif
	endmethod

	method removeReturnRequirement takes nothing returns nothing
		// Only remove if present
		if not this.hasReturnReq or this.returnReqIndex <= 0 then
			return
		endif
		
		// Clear the requirement text and questitem
		call this.setRequirement(this.returnReqIndex, "")
		call this.markRequirementCompleted(this.returnReqIndex, false)
		
		// If we have the questitem, destroy it to remove from quest log
		// Note there are no native functions to Destroy/remove quest requirements
		if this.returnReqIndex == 1 and this.req1 != null then
			set this.req1 = null
		elseif this.returnReqIndex == 2 and this.req2 != null then
			set this.req2 = null
		elseif this.returnReqIndex == 3 and this.req3 != null then
			set this.req3 = null
		elseif this.returnReqIndex == 4 and this.req4 != null then
			set this.req4 = null
		elseif this.returnReqIndex == 5 and this.req5 != null then
			set this.req5 = null
		elseif this.returnReqIndex == 6 and this.req6 != null then
			set this.req6 = null
		elseif this.returnReqIndex == 7 and this.req7 != null then
			set this.req7 = null
		elseif this.returnReqIndex == 8 and this.req8 != null then
			set this.req8 = null
		endif
		
		// Refresh quest log to reflect changes
		call this.refreshQuestLog()
		
		// Clear tracking
		set this.hasReturnReq = false
		set this.returnReqIndex = 0
		
		call DebugMsg("Removed return requirement")
	endmethod

	method buildRewardTextFromFlags takes nothing returns nothing
		if this.rewardXPActive then
			set this.rewardLine1 = "|cff8080ffXP: |r" + I2S(this.rewardXP) + "\n"
		else
			set this.rewardLine1 = ""
		endif
		if this.rewardGoldActive then
			set this.rewardLine2 = "|cffffff00Gold: |r" + I2S(this.rewardGold) + "\n"
		else
			set this.rewardLine2 = ""
		endif
		if this.rewardArenaActive then
			set this.rewardLine3 = "|cffff0000Arena Marks: |r" + I2S(this.rewardArena) + "\n"
		else
			set this.rewardLine3 = ""
		endif
		if this.rewardRepActive then
			set this.rewardLine4 = "|cff8080ffReputation: |r" + I2S(this.rewardRep)
			if this.faction != "" then
				set this.rewardLine4 = this.rewardLine4 + " [" + this.faction + "]"
			endif
			set this.rewardLine4 = this.rewardLine4 + "\n"
		else
			set this.rewardLine4 = ""
		endif
		if this.rewardItemActive and this.rewardItemType != 0 then
			set this.rewardItemText = GetObjectName(this.rewardItemType)
			set this.rewardLine5 = "\n|cff00ffffItem: |r" + this.rewardItemText + "\n"
		else
			set this.rewardLine5 = ""
		endif
		call this.buildRewardsText()
	endmethod

	method formatQuestDescription takes nothing returns string
		return this.description + this.infoText + this.info2Text + this.rewardsHeading + this.rewardsText
	endmethod

	method formatObjectivesList takes nothing returns string
		local string msg = ""
		local boolean hasObjectives = false

		if this.requirement1 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement1 + "\n"
		endif
		if this.requirement2 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement2 + "\n"
		endif
		if this.requirement3 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement3 + "\n"
		endif
		if this.requirement4 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement4 + "\n"
		endif
		if this.requirement5 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement5 + "\n"
		endif
		if this.requirement6 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement6 + "\n"
		endif
		if this.requirement7 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement7 + "\n"
		endif
		if this.requirement8 != "" then
			if not hasObjectives then
				set msg = "|cffffcc00Objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement8 + "\n"
		endif

		return msg
	endmethod

	method formatActiveObjectivesList takes nothing returns string
		local string msg = ""
		local boolean hasObjectives = false

		if this.requirement1 != "" and not this.req1Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement1 + "\n"
		endif
		if this.requirement2 != "" and not this.req2Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement2 + "\n"
		endif
		if this.requirement3 != "" and not this.req3Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement3 + "\n"
		endif
		if this.requirement4 != "" and not this.req4Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement4 + "\n"
		endif
		if this.requirement5 != "" and not this.req5Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement5 + "\n"
		endif
		if this.requirement6 != "" and not this.req6Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement6 + "\n"
		endif
		if this.requirement7 != "" and not this.req7Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement7 + "\n"
		endif
		if this.requirement8 != "" and not this.req8Completed then
			if not hasObjectives then
				set msg = QUEST_UPDATE_COLOR_NEW_OBJECTIVE + "New objectives:|r\n"
				set hasObjectives = true
			endif
			set msg = msg + "- " + this.requirement8 + "\n"
		endif

		return msg
	endmethod

	method formatDiscoverMessage takes nothing returns string
		local string msg = "|cffffcc00QUEST|r\n" + this.title + "\n\n"

		if this.requirement1 != "" then
			set msg = msg + "- " + this.requirement1 + "\n"
		endif
		if this.requirement2 != "" then
			set msg = msg + "- " + this.requirement2 + "\n"
		endif
		if this.requirement3 != "" then
			set msg = msg + "- " + this.requirement3 + "\n"
		endif
		if this.requirement4 != "" then
			set msg = msg + "- " + this.requirement4 + "\n"
		endif
		if this.requirement5 != "" then
			set msg = msg + "- " + this.requirement5 + "\n"
		endif
		if this.requirement6 != "" then
			set msg = msg + "- " + this.requirement6 + "\n"
		endif
		if this.requirement7 != "" then
			set msg = msg + "- " + this.requirement7 + "\n"
		endif
		if this.requirement8 != "" then
			set msg = msg + "- " + this.requirement8 + "\n"
		endif

		return msg
	endmethod

	method formatCompleteMessage takes nothing returns string
		local string title = this.title
		
		// Safety: handle empty title
		if title == "" then
			set title = "Quest"
		endif
		
		return "|cffffcc00QUEST COMPLETED|r\n" + title
	endmethod

	method formatFailedMessage takes nothing returns string
		local string msg
		local string title = this.title
		
		// Safety: handle empty title
		if title == "" then
			set title = "Quest"
		endif
		
		set msg = "|cffffcc00QUEST FAILED|r\n" + title
		if this.failReasonText != "" then
			set msg = msg + "\n" + this.failReasonText
		endif
		return msg
	endmethod

	method showDiscoveredMessage takes nothing returns nothing
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_DISCOVERED, this.formatDiscoverMessage())
		call FlashQuestDialogButtonBJ()
	endmethod

	method showUpdatedMessage takes string msg returns nothing
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_UPDATED, msg)
		call FlashQuestDialogButtonBJ()
	endmethod

	method showCompletedMessage takes nothing returns nothing
		local string msg
		local string rewardMsg
		
		// Safety: validate title exists
		if this.title == "" then
			return
		endif
		
		set msg = this.formatCompleteMessage()
		
		// Append rewards directly to completion message instead of queueing separately
		if this.rewardsHeading != "" or this.rewardsText != "" then
			set rewardMsg = this.rewardsHeading + this.rewardsText
			if rewardMsg != "" then
				set msg = msg + "\n\n" + rewardMsg
			endif
		endif
		
		if msg != "" then
			call ClearTextMessages()
			call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_COMPLETED, msg)
			call FlashQuestDialogButtonBJ()
		endif
	endmethod

	method showFailedMessage takes nothing returns nothing
		call ClearTextMessages()
		call QuestMessageBJ(bj_FORCE_ALL_PLAYERS, bj_QUESTMESSAGE_FAILED, this.formatFailedMessage())
		call FlashQuestDialogButtonBJ()
	endmethod

	method clampNonNegative takes integer value returns integer
		if value < 0 then
			return 0
		endif
		return value
	endmethod

	method computeRewards takes nothing returns nothing
		if this.rewardXPActive then
			set this.rewardXP = this.clampNonNegative(R2I(this.questLevel * this.rewardXPMult) + this.rewardXPAdjust)
		else
			set this.rewardXP = 0
		endif

		if this.rewardGoldActive then
			set this.rewardGold = this.clampNonNegative(R2I(this.questLevel * this.rewardGoldMult) + this.rewardGoldAdjust)
		else
			set this.rewardGold = 0
		endif

		if this.rewardArenaActive then
			set this.rewardArena = this.clampNonNegative(R2I(this.questLevel * this.rewardArenaMult) + this.rewardArenaAdjust)
		else
			set this.rewardArena = 0
		endif

		if this.rewardRepActive then
			set this.rewardRep = this.clampNonNegative(R2I(this.questLevel * this.rewardRepMult) + this.rewardRepAdjust)
		else
			set this.rewardRep = 0
		endif

		call this.buildRewardTextFromFlags()
	endmethod

	method setRewardParams takes boolean xpActive, integer xpAdjust, boolean goldActive, integer goldAdjust, boolean arenaActive, integer arenaAdjust, boolean repActive, integer repAdjust, boolean repLinked returns nothing
		set this.rewardXPActive = xpActive
		set this.rewardXPAdjust = xpAdjust
		set this.rewardGoldActive = goldActive
		set this.rewardGoldAdjust = goldAdjust
		set this.rewardArenaActive = arenaActive
		set this.rewardArenaAdjust = arenaAdjust
		set this.rewardRepActive = repActive
		set this.rewardRepAdjust = repAdjust
		set this.rewardRepLinked = repLinked

		call this.computeRewards()
	endmethod

	method setRewardItemType takes integer itemType returns nothing
		set this.rewardItemType = itemType
		if itemType != 0 then
			set this.rewardItemActive = true
		else
			set this.rewardItemActive = false
		endif
		call this.computeRewards()
	endmethod

	method setRequiredLevel takes integer level returns nothing
		set this.requiredLevel = level
	endmethod

	method setAllowedHeroesForLevelCheck takes boolean allowNazgrek, boolean allowZulkis returns nothing
		set this.useAllowedHeroesForLevelCheck = true
		set this.levelCheckAllowNazgrek = allowNazgrek
		set this.levelCheckAllowZulkis = allowZulkis
	endmethod

	method setFaction takes string factionName returns nothing
		set this.faction = factionName
	endmethod

	method setRequiredReputation takes integer reputation returns nothing
		set this.requiredReputation = reputation
	endmethod

	method setCustomCondition takes trigger conditionTrigger returns nothing
		set this.customCondition = conditionTrigger
	endmethod

	method setEventFlagIndex takes integer index returns nothing
		set this.eventFlagIndex = index
	endmethod

	method addRequiredCompletedQuest takes string questName, unit questGiver returns nothing
		if questName == "" then
			return
		endif
		if questGiver == null then
			set questGiver = this.giver
		endif
		if this.requiredCompletedQuestCount == 0 then
			set this.requiredCompletedQuest1 = questName
			set this.requiredCompletedQuestGiver1 = questGiver
		elseif this.requiredCompletedQuestCount == 1 then
			set this.requiredCompletedQuest2 = questName
			set this.requiredCompletedQuestGiver2 = questGiver
		elseif this.requiredCompletedQuestCount == 2 then
			set this.requiredCompletedQuest3 = questName
			set this.requiredCompletedQuestGiver3 = questGiver
		elseif this.requiredCompletedQuestCount == 3 then
			set this.requiredCompletedQuest4 = questName
			set this.requiredCompletedQuestGiver4 = questGiver
		else
			return
		endif
		set this.requiredCompletedQuestCount = this.requiredCompletedQuestCount + 1
	endmethod

	method setGiverDisplayName takes string displayName returns nothing
		set this.giverDisplayName = displayName
	endmethod

	method setReceiverDisplayName takes string displayName returns nothing
		set this.receiverDisplayName = displayName
	endmethod

	method setAutoComplete takes boolean flag returns nothing
		set this.autoCompletes = flag
	endmethod

	method setTargetRect takes rect r returns nothing
		set this.targetRect = r
	endmethod

	method setTargetZone takes integer zoneId returns nothing
		set this.targetZoneId = zoneId
	endmethod

	method awardRewards takes nothing returns nothing
		local group g
		local unit u
		local unit hero = null
		local item it
		local boolean awardedNazgrek = false
		local boolean awardedZulkis = false

		if DEBUG then
			call DebugMsg("awardRewards: " + this.title + " xp=" + I2S(this.rewardXP) + " gold=" + I2S(this.rewardGold) + " arena=" + I2S(this.rewardArena) + " rep=" + I2S(this.rewardRep) + " faction=" + this.faction)
		endif

		if this.rewardXP > 0 then
			set g = GetUnitsOfPlayerAll(Player(0))
			loop
				set u = FirstOfGroup(g)
				exitwhen u == null
				call GroupRemoveUnit(g, u)
				if IsUnitType(u, UNIT_TYPE_HERO) then
					call AddHeroXP(u, this.rewardXP, true)
					if hero == null then
						set hero = u
					endif
					if u == udg_Nazgrek then
						set awardedNazgrek = true
					elseif u == udg_Zulkis then
						set awardedZulkis = true
					endif
				endif
			endloop
			call DestroyGroup(g)
			if udg_Nazgrek != null and IsUnitType(udg_Nazgrek, UNIT_TYPE_HERO) and not awardedNazgrek then
				call AddHeroXP(udg_Nazgrek, this.rewardXP, true)
				if hero == null then
					set hero = udg_Nazgrek
				endif
			endif
			if udg_Zulkis != null and IsUnitType(udg_Zulkis, UNIT_TYPE_HERO) and not awardedZulkis then
				call AddHeroXP(udg_Zulkis, this.rewardXP, true)
				if hero == null then
					set hero = udg_Zulkis
				endif
			endif
			set QuestRewardCurrentXP = this.rewardXP
			set QuestRewardPrimaryHero = hero
			if udg_Companion_Group != null then
				call ForGroup(udg_Companion_Group, function AwardCompanionRewardXPEnum)
			endif
			set hero = QuestRewardPrimaryHero
			set QuestRewardCurrentXP = 0
			set QuestRewardPrimaryHero = null
		else
			set hero = null
		endif

		if this.rewardGold > 0 then
			call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_GOLD) + this.rewardGold)
		endif

		if this.rewardArena > 0 then
			call SetPlayerState(Player(0), PLAYER_STATE_RESOURCE_LUMBER, GetPlayerState(Player(0), PLAYER_STATE_RESOURCE_LUMBER) + this.rewardArena)
		endif

		if this.faction != "" then
			if this.rewardRepLinked then
				call AddReputationLinked(Player(0), this.faction, this.rewardRep)
			else
				call AddReputation(Player(0), this.faction, this.rewardRep)
			endif
		endif

		if this.rewardItemActive and this.rewardItemType != 0 then
			if hero == null then
				set g = GetUnitsOfPlayerAll(Player(0))
				loop
					set u = FirstOfGroup(g)
					exitwhen u == null
					call GroupRemoveUnit(g, u)
					if IsUnitType(u, UNIT_TYPE_HERO) then
						set hero = u
						exitwhen true
					endif
				endloop
				call DestroyGroup(g)
			endif
			if hero != null then
				set it = CreateItem(this.rewardItemType, GetUnitX(hero), GetUnitY(hero))
				call UnitAddItem(hero, it)
			endif
		endif
		set g = null
		set u = null
		set hero = null
		set it = null
	endmethod

	method accept takes nothing returns nothing
		local timer t
		
		// Safety: prevent double-accept or accepting already active quests
		if this.active or this.completed then
			return
		endif
		
		// Safety: validate quest has required data
		if this.title == "" then
			return
		endif
		if this.failed then
			set this.failed = false
			set this.failReasonText = ""
		endif
		
		set this.active = true
		call this.setDiscovered(true)
		call QuestSetFailed(this.wcQuest, false)
		call this.refreshQuestLog()
		
		// Apply requirements to quest log if not already applied
		// (Check if first requirement exists but hasn't been added to quest log yet)
		if this.requirement1 != "" and this.req1 == null then
			call this.applyRequirementsToLog()
		endif
		
		// Set state without updating icons - icons will update when message is shown
		call this.setStateNoIcons(QUEST_STATE_IN_PROGRESS)
		
		// Delay quest discovered message by 5 seconds (icons will update at the same time)
		set t = CreateTimer()
		set QuestDiscoveredTimerData[GetHandleId(t)] = this
		call TimerStart(t, QUEST_DISCOVERED_DELAY, false, function ShowDelayedQuestDiscovered)
		set t = null
	endmethod

	method update takes nothing returns nothing
		call this.refreshQuestLog()
		// TODO: update objectives and text
	endmethod

	method complete takes nothing returns nothing
		local timer t
		local integer tId
		
		// Safety: prevent double-completion
		if this.completed or this.state == QUEST_STATE_COMPLETE then
			return
		endif
		
		// Mark return requirement as completed (if present) before completing quest
		// Skip if quest auto-completes (no return needed)
		if this.hasReturnReq and this.returnReqIndex > 0 and not this.autoCompletes then
			call this.markRequirementCompleted(this.returnReqIndex, true)
		endif
		
		set this.failed = false
		set this.failReasonText = ""
		set this.completed = true
		set this.active = false
		call this.setCompleted(true)
		call QuestSetFailed(this.wcQuest, false)
		// Set state without updating icons - icons will update when message is shown
		call this.setStateNoIcons(QUEST_STATE_COMPLETE)
		if DEBUG then
			call DebugMsg("complete: " + this.title + " giver=" + this.giverDisplayName)
		endif
		call this.awardRewards()
		
		// Show completion message after 5 second delay (icons will update at the same time)
		set t = CreateTimer()
		set tId = GetHandleId(t)
		set QuestCompletedTimerData[tId] = this
		call TimerStart(t, QUEST_COMPLETED_DELAY, false, function ShowDelayedQuestCompleted)
	endmethod

	method fail takes string reason returns nothing
		if this.completed or this.state == QUEST_STATE_COMPLETE then
			return
		endif
		if this.wcQuest == null then
			call this.createQuestLog()
		endif
		set this.failed = true
		set this.active = false
		set this.failReasonText = reason
		call QuestSetDiscovered(this.wcQuest, true)
		call QuestSetCompleted(this.wcQuest, false)
		call QuestSetFailed(this.wcQuest, true)
		call this.showFailedMessage()
		call this.setState(QUEST_STATE_IN_PROGRESS)
	endmethod

	method turnIn takes nothing returns nothing
		set this.active = false
		call this.setState(QUEST_STATE_COMPLETE)
	endmethod

	method resetAfterFail takes nothing returns nothing
		set this.failed = false
		set this.failReasonText = ""
		if this.wcQuest != null then
			call QuestSetFailed(this.wcQuest, false)
		endif
		call this.setState(QUEST_STATE_AVAILABLE)
	endmethod

	method abandon takes nothing returns nothing
		set this.active = false
		if this.wcQuest != null then
			call QuestSetFailed(this.wcQuest, false)
		endif
		call this.refreshQuestLog()
		call this.setState(QUEST_STATE_AVAILABLE)
		// TODO: reset state to undiscovered if needed
	endmethod

	method updateIcons takes nothing returns nothing
		local integer currentState = this.state
		
		// Register icon with giver (shows available/in-progress states)
		if this.giver != null then
			// Show turn-in icon on giver only if giver == receiver
			if currentState == QUEST_STATE_READY_TURNIN and this.receiver != null and this.giver != this.receiver then
				call IconRegisterQuest(this.giver, this.id, this.questType, QUEST_STATE_IN_PROGRESS)
			else
				call IconRegisterQuest(this.giver, this.id, this.questType, currentState)
			endif
		endif
		
		// Register icon with receiver (shows turn-in state when different from giver)
		if this.receiver != null and this.receiver != this.giver then
			if currentState == QUEST_STATE_READY_TURNIN then
				call IconRegisterQuest(this.receiver, this.id, this.questType, QUEST_STATE_READY_TURNIN)
			elseif currentState == QUEST_STATE_COMPLETE or currentState == QUEST_STATE_AVAILABLE or currentState == QUEST_STATE_UNAVAILABLE then
				// Clear icon from receiver when quest completes or resets
				call IconRemoveQuest(this.receiver, this.id)
			endif
		endif
	endmethod
	
	method setStateNoIcons takes integer newState returns nothing
		// Set state without updating icons (icons will be updated later with delay)
		if this.state == newState then
			return
		endif
		set this.state = newState
		set this.lastEvalState = newState
		call StateChanged(this.id, newState)
	endmethod
	
	method setState takes integer newState returns nothing
		if this.state == newState then
			return
		endif
		set this.state = newState
		set this.lastEvalState = newState
		call this.updateIcons()
		call StateChanged(this.id, newState)
	endmethod
endstruct

//===========================================================================
// API functions (scaffolding)
//===========================================================================
public function Create takes string questName, unit questGiver, string questType, integer questLevel, unit questReceiver returns QuestData
	return QuestData.create(questName, questGiver, questType, questLevel, questReceiver)
endfunction

public function GetByName takes string questName returns QuestData
	local integer i = 1
	local integer questId
	local QuestData q
	if questName == "" then
		return 0
	endif
	loop
		exitwhen i > QuestCount
		set questId = QuestIdList[i]
		set q = QuestById.integer[ questId ]
		if q != 0 and q.name == questName then
			return q
		endif
		set i = i + 1
	endloop
	return 0
endfunction

public function GetByGiver takes unit questGiver returns QuestData
	local integer questId
	if questGiver == null then
		return 0
	endif
	set questId = GetGiverQuestIdByIndexInternal(questGiver, 1)
	if questId == 0 then
		return 0
	endif
	return GetById(questId)
endfunction

public function GetByNameAndGiver takes string questName, unit questGiver returns QuestData
	return QuestByNameGiver.integer[ NameGiverKey(questName, questGiver) ]
endfunction

public function AddRequiredCompletedQuest takes integer questId, string prereqQuestName, unit prereqQuestGiver returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.addRequiredCompletedQuest(prereqQuestName, prereqQuestGiver)
	endif
endfunction

public function AddRequiredCompletedQuestByNameAndGiver takes string questName, unit questGiver, string prereqQuestName, unit prereqQuestGiver returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.addRequiredCompletedQuest(prereqQuestName, prereqQuestGiver)
	endif
endfunction

public function Accept takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.accept()
	endif
endfunction

public function Discover takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setDiscovered(true)
		call q.refreshQuestLog()
		call q.applyRequirementsToLog()
		call q.showDiscoveredMessage()
		if q.state == QUEST_STATE_UNAVAILABLE then
			call q.setState(QUEST_STATE_AVAILABLE)
		endif
	endif
endfunction

public function Update takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.update()
	endif
endfunction

public function Complete takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.complete()
	endif
endfunction

public function Fail takes integer questId, string reason returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.fail(reason)
	endif
endfunction

public function TurnIn takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.turnIn()
	endif
endfunction

public function Abandon takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.abandon()
	endif
endfunction

public function SetState takes integer questId, integer newState returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setState(newState)
	endif
endfunction

public function GetStateByNameAndGiver takes string questName, unit questGiver returns integer
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q == 0 then
		return 0
	endif
	return q.state
endfunction

public function SetStateByNameAndGiver takes string questName, unit questGiver, integer newState returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setState(newState)
	endif
endfunction

public function SetRequirements takes integer questId, string heading, string r1, string r2, string r3, string r4, string r5, string r6, string r7, string r8 returns nothing
	local QuestData q = GetById(questId)
	if q == 0 then
		return
	endif
	set q.requirementHeading = heading
	set q.requirement1 = r1
	set q.requirement2 = r2
	set q.requirement3 = r3
	set q.requirement4 = r4
	set q.requirement5 = r5
	set q.requirement6 = r6
	set q.requirement7 = r7
	set q.requirement8 = r8
	call q.applyRequirementsToLog()
endfunction

public function SetRequirement takes integer questId, integer index, string text returns nothing
	local QuestData q = GetById(questId)
	local string objectivesList
	
	if q != 0 and q.title != "" then
		call q.setRequirement(index, text)
		call q.updateRequirementText(index, text)
		call q.refreshQuestLog()
		if text != "" then
			set objectivesList = q.formatActiveObjectivesList()
			if objectivesList != "" then
				call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + objectivesList)
			endif
		endif
	endif
endfunction

public function AddRequirement takes integer questId, integer index, string text returns nothing
	local QuestData q = GetById(questId)
	local string objectivesList
	
	if q != 0 and q.title != "" then
		call q.setRequirement(index, text)
		call q.addRequirement(index, text)
		call q.refreshQuestLog()
		if text != "" then
			set objectivesList = q.formatActiveObjectivesList()
			if objectivesList != "" then
				call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + objectivesList)
			endif
		endif
	endif
endfunction

public function SetRequirementCompleted takes integer questId, integer index, boolean flag returns nothing
	local QuestData q = GetById(questId)
	local string reqText
	
	if q != 0 and q.title != "" then
		call q.markRequirementCompleted(index, flag)
		call q.refreshQuestLog()
		if flag then
			set reqText = q.getRequirementText(index)
			if reqText != "" then
				call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + QUEST_UPDATE_COLOR_OBJECTIVE_COMPLETE + "Objective completed:|r " + reqText)
			endif
		else
			set reqText = q.getRequirementText(index)
			if reqText != "" then
				call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + QUEST_UPDATE_COLOR_OBJECTIVE_FAIL + "Objective failed:|r " + reqText)
			endif
		endif
	endif
endfunction

public function RegisterGiver takes unit u returns nothing
	call RegisterGiverInternal(u)
endfunction

public function UnregisterGiver takes unit u returns nothing
	call UnregisterGiverInternal(u)
endfunction

public function UpdateGiverUnitReference takes unit oldUnit, unit newUnit returns nothing
	local integer oldId
	local integer newId
	local integer index
	local Table oldGiverTable
	local integer i = 1
	local integer questId
	local QuestData q
	
	if oldUnit == null or newUnit == null then
		return
	endif
	
	set oldId = GetHandleId(oldUnit)
	set newId = GetHandleId(newUnit)
	set index = QuestGiverIndex.integer[oldId]
	
	// Skip if old unit is not registered or new unit is already registered
	if index == 0 or QuestGiverIndex.integer[newId] != 0 then
		return
	endif
	
	// Update QuestGiverList
	set QuestGiverList[index] = newUnit
	
	// Update QuestGiverIndex
	set QuestGiverIndex.integer[newId] = index
	set QuestGiverIndex.integer[oldId] = 0
	
	// Transfer QuestGiverTable from old ID to new ID
	if QuestGiverTable.has(oldId) then
		set oldGiverTable = QuestGiverTable[oldId]
		set QuestGiverTable[newId] = oldGiverTable
		call QuestGiverTable.remove(oldId)
	endif
	
	// Update all quests that reference this unit as giver or receiver
	loop
		exitwhen i > QuestCount
		set questId = QuestIdList[i]
		set q = QuestById.integer[questId]
		if q != 0 then
			if q.giver == oldUnit then
				set q.giver = newUnit
			endif
			if q.receiver == oldUnit then
				set q.receiver = newUnit
			endif
		endif
		set i = i + 1
	endloop
	
	// Update QuestByNameGiver table entries
	set i = 1
	loop
		exitwhen i > QuestCount
		set questId = QuestIdList[i]
		set q = QuestById.integer[questId]
		if q != 0 and (q.giver == newUnit or q.receiver == newUnit) then
			// Remove old key and add new key
			call QuestByNameGiver.remove(NameGiverKey(q.name, oldUnit))
			set QuestByNameGiver.integer[NameGiverKey(q.name, newUnit)] = q
		endif
		set i = i + 1
	endloop
endfunction

private function UpdateGiverUnitReferenceByHandleId takes integer oldId, unit newUnit returns nothing
	local integer newId
	local integer index
	local Table oldGiverTable
	local integer i = 1
	local integer questId
	local QuestData q
	
	if oldId == 0 or newUnit == null then
		return
	endif
	
	set newId = GetHandleId(newUnit)
	set index = QuestGiverIndex.integer[oldId]
	
	// Skip if old ID is not registered or new unit is already registered
	if index == 0 or QuestGiverIndex.integer[newId] != 0 then
		return
	endif
	
	// Update QuestGiverList
	set QuestGiverList[index] = newUnit
	
	// Update QuestGiverIndex
	set QuestGiverIndex.integer[newId] = index
	set QuestGiverIndex.integer[oldId] = 0
	
	// Transfer QuestGiverTable from old ID to new ID
	if QuestGiverTable.has(oldId) then
		set oldGiverTable = QuestGiverTable[oldId]
		set QuestGiverTable[newId] = oldGiverTable
		call QuestGiverTable.remove(oldId)
	endif
	
	// Update all quests that reference this handle ID as giver or receiver
	// Note: Cannot update unit references directly without old unit, but Table entries are fixed
	loop
		exitwhen i > QuestCount
		set questId = QuestIdList[i]
		set q = QuestById.integer[questId]
		if q != 0 then
			// Check if this quest's giver handle matches old ID
			if GetHandleId(q.giver) == oldId then
				set q.giver = newUnit
			endif
			if GetHandleId(q.receiver) == oldId then
				set q.receiver = newUnit
			endif
		endif
		set i = i + 1
	endloop
	
	// Note: QuestByNameGiver table cannot be updated without old unit reference
	// This is acceptable since quest lookups by name+giver will naturally point to new unit
endfunction

public function UpdateGiverUnitReferenceByType takes integer unitTypeId, unit newUnit returns nothing
	local integer oldId
	local unit oldUnit = null
	
	if unitTypeId == 0 or newUnit == null then
		return
	endif
	
	// Look up the old unit handle ID by unit type
	set oldId = QuestGiverByType.integer[unitTypeId]
	if oldId == 0 then
		return
	endif
	
	// Try to get the old unit (may be null if unit was removed from game)
	// We can still proceed with handle ID alone
	set oldUnit = QuestGiverList[QuestGiverIndex.integer[oldId]]
	
	// If old unit is null or has different handle, use direct handle ID transfer
	if oldUnit == null or GetHandleId(oldUnit) != oldId then
		call UpdateGiverUnitReferenceByHandleId(oldId, newUnit)
	else
		call UpdateGiverUnitReference(oldUnit, newUnit)
	endif
	
	// Update the type mapping to point to new unit
	set QuestGiverByType.integer[unitTypeId] = GetHandleId(newUnit)
endfunction

public function GetGiverQuestCount takes unit u returns integer
	return GetGiverQuestCountInternal(u)
endfunction

public function GetGiverQuestIdByIndex takes unit u, integer index returns integer
	return GetGiverQuestIdByIndexInternal(u, index)
endfunction

public function SetEventFlag takes integer index, boolean value returns nothing
	if index <= 0 then
		return
	endif
	set QuestEventFlags[index] = value
endfunction

public function GetEventFlag takes integer index returns boolean
	if index <= 0 then
		return false
	endif
	return QuestEventFlags[index]
endfunction

public function UpdateRequirementText takes integer questId, integer index, string text returns nothing
	local QuestData q = GetById(questId)
	
	if q != 0 and q.title != "" then
		call q.updateRequirementText(index, text)
		call q.refreshQuestLog()
		if text != "" then
			call EnqueueQuestUpdateMessage("|cffffcc00QUEST UPDATED|r\n" + q.title + "\n\n" + QUEST_UPDATE_COLOR_OBJECTIVE_UPDATE + "Objective updated:|r " + text)
		endif
	endif
endfunction

public function ShowUpdateMessage takes integer questId, string msg returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.showUpdatedMessage(msg)
	endif
endfunction

public function ShowFailMessage takes integer questId, string reason returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		set q.failReasonText = reason
		call q.showFailedMessage()
	endif
endfunction

public function MarkReturnRequirementCompleted takes integer questId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 and q.hasReturnReq and q.returnReqIndex > 0 then
		call q.markRequirementCompleted(q.returnReqIndex, true)
		call q.refreshQuestLog()
	endif
endfunction

public function MarkReturnRequirementCompletedByNameAndGiver takes string questName, unit questGiver returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 and q.hasReturnReq and q.returnReqIndex > 0 then
		call q.markRequirementCompleted(q.returnReqIndex, true)
		call q.refreshQuestLog()
	endif
endfunction

public function SetGiverDisplayName takes integer questId, string displayName returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setGiverDisplayName(displayName)
	endif
endfunction

public function SetReceiverDisplayName takes integer questId, string displayName returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setReceiverDisplayName(displayName)
	endif
endfunction

public function SetGiverDisplayNameByNameAndGiver takes string questName, unit questGiver, string displayName returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setGiverDisplayName(displayName)
	endif
endfunction

public function SetReceiverDisplayNameByNameAndGiver takes string questName, unit questGiver, string displayName returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setReceiverDisplayName(displayName)
	endif
endfunction

public function SetAutoComplete takes integer questId, boolean flag returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setAutoComplete(flag)
	endif
endfunction

public function SetAutoCompleteByNameAndGiver takes string questName, unit questGiver, boolean flag returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setAutoComplete(flag)
	endif
endfunction

public function SetTargetRect takes integer questId, rect r returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setTargetRect(r)
	endif
endfunction

public function SetTargetRectByNameAndGiver takes string questName, unit questGiver, rect r returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setTargetRect(r)
	endif
endfunction

public function SetTargetZone takes integer questId, integer zoneId returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setTargetZone(zoneId)
	endif
endfunction

public function SetTargetZoneByNameAndGiver takes string questName, unit questGiver, integer zoneId returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setTargetZone(zoneId)
	endif
endfunction

public function SetAllowedHeroesForLevelCheck takes integer questId, boolean allowNazgrek, boolean allowZulkis returns nothing
	local QuestData q = GetById(questId)
	if q != 0 then
		call q.setAllowedHeroesForLevelCheck(allowNazgrek, allowZulkis)
	endif
endfunction

public function SetAllowedHeroesForLevelCheckByNameAndGiver takes string questName, unit questGiver, boolean allowNazgrek, boolean allowZulkis returns nothing
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 then
		call q.setAllowedHeroesForLevelCheck(allowNazgrek, allowZulkis)
	endif
endfunction

public function CheckHeroInTargetRect takes integer questId, unit hero returns boolean
	local QuestData q = GetById(questId)
	if q != 0 and q.targetRect != null then
		return RectContainsUnit(q.targetRect, hero)
	endif
	return false
endfunction

public function CheckHeroInTargetRectByNameAndGiver takes string questName, unit questGiver, unit hero returns boolean
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 and q.targetRect != null then
		return RectContainsUnit(q.targetRect, hero)
	endif
	return false
endfunction

public function CheckHeroInTargetZone takes integer questId, integer currentZoneId returns boolean
	local QuestData q = GetById(questId)
	if q != 0 and q.targetZoneId > 0 then
		return currentZoneId == q.targetZoneId
	endif
	return false
endfunction

public function CheckHeroInTargetZoneByNameAndGiver takes string questName, unit questGiver, integer currentZoneId returns boolean
	local QuestData q = GetByNameAndGiver(questName, questGiver)
	if q != 0 and q.targetZoneId > 0 then
		return currentZoneId == q.targetZoneId
	endif
	return false
endfunction

public function Save takes integer questId returns nothing
	local QuestData q = GetById(questId)
	local integer handleId
	if q == 0 or q.wcQuest == null then
		return
	endif
	set handleId = GetHandleId(q.wcQuest)
	set QuestSaveTable.integer[ handleId*10 + QUEST_SAVE_ID_KEY ] = q.id
	set QuestSaveTable.string[ handleId*10 + QUEST_SAVE_TYPE_KEY ] = q.questType
	set QuestSaveTable.integer[ handleId*10 + QUEST_SAVE_GIVER_KEY ] = GetHandleId(q.giver)
	set QuestSaveTable.integer[ handleId*10 + QUEST_SAVE_STATE_KEY ] = q.state
endfunction

public function Load takes quest q returns integer
	local integer handleId = GetHandleId(q)
	return QuestSaveTable.integer[ handleId*10 + QUEST_SAVE_ID_KEY ]
endfunction

public function TemplateKill takes string questName, unit questGiver, string questType, integer questLevel, integer targetUnitTypeId, integer count returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Kill " + I2S(count) + " " + GetObjectName(targetUnitTypeId))
	// NOTE: Registration for kill tracking must be done by the caller (e.g., QuestGiver), not by QuestMaster.
	return q
endfunction

public function TemplateGatherItems takes string questName, unit questGiver, string questType, integer questLevel, integer itemTypeId, integer count returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Gather " + I2S(count) + " " + GetObjectName(itemTypeId))
	// NOTE: Registration for item tracking must be done by the caller (e.g., QuestGiver), not by QuestMaster.
	return q
endfunction

public function TemplateKillGatherItems takes string questName, unit questGiver, string questType, integer questLevel, integer unitTypeId, integer unitCount, integer itemTypeId, integer itemCount returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Kill " + I2S(unitCount) + " " + GetObjectName(unitTypeId))
	call q.setRequirement(2, "Gather " + I2S(itemCount) + " " + GetObjectName(itemTypeId))
	// NOTE: Registration for kill/item tracking must be done by the caller (e.g., QuestGiver), not by QuestMaster.
	return q
endfunction

public function TemplateTalkTo takes string questName, unit questGiver, string questType, integer questLevel, string npcName returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Talk to " + npcName)
	return q
endfunction

public function TemplateFindNPC takes string questName, unit questGiver, string questType, integer questLevel, string npcName returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Find " + npcName)
	return q
endfunction

public function TemplateGoToPlace takes string questName, unit questGiver, string questType, integer questLevel, string placeName returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Go to " + placeName)
	return q
endfunction

public function TemplateGoToPlaceRect takes string questName, unit questGiver, string questType, integer questLevel, string placeName, rect targetRect, boolean autoComplete returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Go to " + placeName)
	call q.setTargetRect(targetRect)
	call q.setAutoComplete(autoComplete)
	return q
endfunction

public function TemplateGoToZone takes string questName, unit questGiver, string questType, integer questLevel, string zoneName, integer zoneId, boolean autoComplete returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Go to " + zoneName)
	call q.setTargetZone(zoneId)
	call q.setAutoComplete(autoComplete)
	return q
endfunction

public function TemplateReputation takes string questName, unit questGiver, string questType, integer questLevel, string factionName, string levelName returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Gain " + levelName + " with " + factionName)
	return q
endfunction

public function TemplateInvestigate takes string questName, unit questGiver, string questType, integer questLevel, string description returns QuestData
	local QuestData q = Create(questName, questGiver, questType, questLevel, null)
	call q.setRequirement(1, "Investigate " + description)
	return q
endfunction

//===========================================================================
// Availability evaluation
//===========================================================================
private function GetHighestHeroLevel takes nothing returns integer
	local group g = GetUnitsOfPlayerAll(Player(0))
	local unit u
	local integer bestLevel = 0
	local integer level

	loop
		set u = FirstOfGroup(g)
		exitwhen u == null
		call GroupRemoveUnit(g, u)
		if IsUnitType(u, UNIT_TYPE_HERO) then
			set level = GetHeroLevel(u)
			if level > bestLevel then
				set bestLevel = level
			endif
		endif
	endloop

	call DestroyGroup(g)
	return bestLevel
endfunction

private function GetHighestAllowedHeroLevel takes QuestData q returns integer
	local integer bestLevel = 0
	local integer level

	if q == 0 or not q.useAllowedHeroesForLevelCheck then
		return GetHighestHeroLevel()
	endif

	if q.levelCheckAllowNazgrek and udg_Nazgrek != null and IsUnitType(udg_Nazgrek, UNIT_TYPE_HERO) then
		set level = GetHeroLevel(udg_Nazgrek)
		if level > bestLevel then
			set bestLevel = level
		endif
	endif

	if q.levelCheckAllowZulkis and udg_Zulkis != null and IsUnitType(udg_Zulkis, UNIT_TYPE_HERO) then
		set level = GetHeroLevel(udg_Zulkis)
		if level > bestLevel then
			set bestLevel = level
		endif
	endif

	return bestLevel
endfunction

private function HasCompletedRequiredQuest takes string questName, unit questGiver returns boolean
	local QuestData q
	if questName == "" then
		return true
	endif
	set q = QuestByNameGiver.integer[ NameGiverKey(questName, questGiver) ]
	if q == 0 then
		return false
	endif
	return q.completed
endfunction

private function PassesRequirements takes QuestData q returns boolean
	local integer heroLevel
	local Faction f

	if q.requiredLevel > 0 then
		set heroLevel = GetHighestAllowedHeroLevel(q)
		if heroLevel < q.requiredLevel then
			return false
		endif
	endif

	if q.faction != "" then
		set f = Faction.getFaction(q.faction)
		if f == 0 then
			return false
		endif
		if Reputation.getRep(Player(0), f) < q.requiredReputation then
			return false
		endif
	endif

	if q.eventFlagIndex > 0 then
		if not QuestEventFlags[q.eventFlagIndex] then
			return false
		endif
	endif

	if q.requiredCompletedQuestCount >= 1 then
		if not HasCompletedRequiredQuest(q.requiredCompletedQuest1, q.requiredCompletedQuestGiver1) then
			return false
		endif
	endif
	if q.requiredCompletedQuestCount >= 2 then
		if not HasCompletedRequiredQuest(q.requiredCompletedQuest2, q.requiredCompletedQuestGiver2) then
			return false
		endif
	endif
	if q.requiredCompletedQuestCount >= 3 then
		if not HasCompletedRequiredQuest(q.requiredCompletedQuest3, q.requiredCompletedQuestGiver3) then
			return false
		endif
	endif
	if q.requiredCompletedQuestCount >= 4 then
		if not HasCompletedRequiredQuest(q.requiredCompletedQuest4, q.requiredCompletedQuestGiver4) then
			return false
		endif
	endif

	if q.customCondition != null then
		if not TriggerEvaluate(q.customCondition) then
			return false
		endif
	endif

	return true
endfunction

private function EvaluateQuest takes QuestData q returns nothing
	local boolean available

	if q == 0 then
		return
	endif
	if q.completed then
		call q.setState(QUEST_STATE_COMPLETE)
		return
	endif
	if q.active then
		return
	endif

	set available = PassesRequirements(q)
	if available then
		call q.setState(QUEST_STATE_AVAILABLE)
	else
		call q.setState(QUEST_STATE_UNAVAILABLE)
	endif
endfunction

public function RefreshAvailabilityForGiver takes unit u returns nothing
	local integer count
	local integer i = 1
	local integer questId

	if u == null then
		return
	endif
	set count = GetGiverQuestCountInternal(u)
	loop
		exitwhen i > count
		set questId = GetGiverQuestIdByIndexInternal(u, i)
		call EvaluateQuest(GetById(questId))
		set i = i + 1
	endloop
endfunction

public function RefreshAvailability takes nothing returns nothing
	local integer i = 1
	local unit u

	loop
		exitwhen i > QuestGiverCount
		set u = QuestGiverList[i]
		call RefreshAvailabilityForGiver(u)
		set i = i + 1
	endloop
endfunction

private function EvalTimerTick takes nothing returns nothing
	call RefreshAvailability()
endfunction

//===========================================================================
// Init
//===========================================================================
private function Init takes nothing returns nothing
	set QuestById = Table.create()
	set QuestByNameGiver = Table.create()
	set QuestByHandle = Table.create()
	set QuestSaveTable = Table.create()
	set QuestGiverIndex = Table.create()
	set QuestGiverTable = Table.create()
	set QuestGiverByType = Table.create()
	set QuestIconTable = Table.create()
	set QuestDiscoveredTimerData = Table.create()
	set QuestCompletedTimerData = Table.create()
	set QuestMaster_OnStateChanged = CreateTrigger()
	set QuestEvalTimer = CreateTimer()
	call TimerStart(QuestEvalTimer, QUEST_EVAL_INTERVAL, true, function EvalTimerTick)
endfunction

endlibrary
