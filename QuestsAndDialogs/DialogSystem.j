library DialogSystem initializer Init requires Table, ExSound, DialogCamera
//===========================================================================
// DialogSystem
// Lightweight dialog creation + button routing for quest givers.
// 
// This system allows you to create dialogs with buttons that have associated action IDs and triggers. 
// When a button is clicked, the system looks up the action ID and trigger for that button and executes the trigger.
//===========================================================================
globals
	private Table DialogButtonAction = 0
	private Table DialogButtonTrigger = 0
	private Table DialogButtonDialog = 0
	private Table DialogButtonLineAction = 0
	private trigger DialogSystem_ClickTrigger = null
	private trigger DialogSystem_SkipTrigger = null
	private trigger DialogSystem_EscapeActionTrigger = null
	private trigger DialogSystem_EscapeActionExecutingTrigger = null
	private boolean DialogSystem_EscapeActionExecuting = false

	private Table DialogSequenceStore = 0
	private integer DialogSequenceNextId = 1
	private timer DialogSequenceTimer = null
	private integer DialogSequenceActiveId = 0
	private integer DialogSequenceActiveIndex = 0
	private boolean DialogSequenceFastForward = false
	private boolean DialogSequenceSkipping = false

	private Table DialogSystem_GreetLines = 0
	private Table DialogSystem_FarewellLines = 0
	private Table DialogSystem_TradeLines = 0
	private Table DialogSystem_ExitLines = 0
	private Table DialogSystem_FollowLines = 0
	private Table DialogSystem_StopLines = 0
	private Table DialogSystem_DeclineLines = 0
	private Table DialogSystem_AcceptLines = 0
	private Table DialogSystem_InfoLines = 0
	private Table DialogSystem_LookAtTimerUnit = 0

	private constant integer DIALOG_SEQ_LINE_COUNT_KEY = 0
	private constant integer DIALOG_SEQ_ONSTART_KEY = 1
	private constant integer DIALOG_SEQ_ONFINISH_KEY = 2
	private constant integer DIALOG_SEQ_DEFAULT_SPEAKER_KEY = 3
	private constant integer DIALOG_SEQ_DEFAULT_NAME_KEY = 4
	private constant integer DIALOG_SEQ_ALLOW_SKIP_KEY = 5

	private constant integer DIALOG_LINE_TEXT_KEY = 1
	private constant integer DIALOG_LINE_SOUND_KEY = 2
	private constant integer DIALOG_LINE_SPEAKER_KEY = 3
	private constant integer DIALOG_LINE_SPEAKER_NAME_KEY = 4
	private constant integer DIALOG_LINE_ACTION_KEY = 5
	private constant integer DIALOG_LINE_SOUND_AT_UNIT_KEY = 6
	private constant integer DIALOG_LINE_DELAY_ONLY_KEY = 7
	private constant integer DIALOG_LINE_CUSTOM_DURATION_KEY = 8
	private constant integer DIALOG_LINE_ACTION_TYPE_KEY = 9
	private constant integer DIALOG_LINE_ACTION_UNIT1_KEY = 10
	private constant integer DIALOG_LINE_ACTION_UNIT2_KEY = 11
	private constant integer DIALOG_LINE_ACTION_X_KEY = 12
	private constant integer DIALOG_LINE_ACTION_Y_KEY = 13
	private constant integer DIALOG_LINE_ACTION_DURATION_KEY = 14

	private constant integer DIALOG_LIST_COUNT_KEY = 0
	private constant integer DIALOG_LIST_TEXT_KEY = 1
	private constant integer DIALOG_LIST_SOUND_KEY = 2
	private constant integer DIALOG_LIST_SOUND_AT_UNIT_KEY = 3

	private constant real DIALOGSYSTEM_TEXT_CPS = 13.0
	private constant real DIALOGSYSTEM_MIN_DURATION = 1.25
	private constant real DIALOGSYSTEM_FAST_FORWARD_DURATION = 0.10
	private constant real DIALOGSYSTEM_FACE_RANDOM_MIN = 0.30
	private constant real DIALOGSYSTEM_FACE_RANDOM_MAX = 1.00
	private constant real DIALOGSYSTEM_LOOK_THRESHOLD = 45.00
	private constant real DIALOGSYSTEM_LOOK_FACE_DURATION = 0.25
	private constant real DIALOGSYSTEM_LOOK_HEAD_DURATION = 1.50
	private constant string DIALOGSYSTEM_LOOK_BONE = "head"

	private constant integer DIALOG_LINE_ACTION_NONE = 0
	private constant integer DIALOG_LINE_ACTION_TRADE = 1
	private constant integer DIALOG_LINE_ACTION_EXIT = 2
	private constant integer DIALOG_LINE_ACTION_FOLLOW = 3
	private constant integer DIALOG_LINE_ACTION_STOP = 4
	private constant integer DIALOG_LINE_ACTION_DECLINE = 5
	private constant integer DIALOG_LINE_ACTION_ACCEPT = 6

	// Sequence action types for facing/looking
	private constant integer SEQ_ACTION_TYPE_NONE = 0
	private constant integer SEQ_ACTION_TYPE_FACE_EACH_OTHER = 1
	private constant integer SEQ_ACTION_TYPE_FACE_UNIT = 2
	private constant integer SEQ_ACTION_TYPE_FACE_POINT = 3
	private constant integer SEQ_ACTION_TYPE_LOOK_AT_UNIT = 4
	private constant integer SEQ_ACTION_TYPE_LOOK_AT_POINT = 5
	private constant integer SEQ_ACTION_TYPE_RESET_LOOK_AT = 6

	string DialogSystem_PickedText = ""
	string DialogSystem_PickedSound = ""
	boolean DialogSystem_PickedSoundAtUnit = false

	private string array DialogSystem_RandomOptTextA
	private string array DialogSystem_RandomOptSoundA
	private string array DialogSystem_RandomOptTextB
	private string array DialogSystem_RandomOptSoundB

	private constant integer DIALOGSYSTEM_FIELD_LINE_QUEUE_MAX = 16
	private timer DialogSystem_FieldLineQueueTimer = null
	private unit array DialogSystem_FieldLineQueueSpeakers
	private string array DialogSystem_FieldLineQueueSpeakerNames
	private string array DialogSystem_FieldLineQueueSoundNames
	private string array DialogSystem_FieldLineQueueTexts
	private integer DialogSystem_FieldLineQueueCount = 0
	private boolean DialogSystem_FieldLineQueueBusy = false

	integer DialogSystem_LastAction = 0
	button DialogSystem_LastButton = null
	dialog DialogSystem_LastDialog = null
	unit DialogSystem_ActiveNPC = null
	player DialogSystem_ActivePlayer = null
endglobals

//===========================================================================
// Dialog sequence helpers
//===========================================================================
private function EstimateDuration takes string text returns real
	local integer len
	local real duration
	if text == null then
		return DIALOGSYSTEM_MIN_DURATION
	endif
	set len = StringLength(text)
	set duration = I2R(len) / DIALOGSYSTEM_TEXT_CPS
	if duration < DIALOGSYSTEM_MIN_DURATION then
		set duration = DIALOGSYSTEM_MIN_DURATION
	endif
	return duration
endfunction

private function GetUnitDisplayName takes unit u returns string
	if u == null then
		return ""
	endif
	if IsUnitType(u, UNIT_TYPE_HERO) then
		return GetHeroProperName(u)
	endif
	return GetUnitName(u)
endfunction

//===========================================================================
// Unit facing and looking helpers (declared before PlayNextLine)
//===========================================================================
public function GetAngleBetweenUnits takes unit source, unit target returns real
	local real dx
	local real dy
	if source == null or target == null then
		return 0.00
	endif
	set dx = GetUnitX(target) - GetUnitX(source)
	set dy = GetUnitY(target) - GetUnitY(source)
	return bj_RADTODEG * Atan2(dy, dx)
endfunction

public function GetAngleBetweenUnitAndPoint takes unit source, real targetX, real targetY returns real
	local real dx
	local real dy
	if source == null then
		return 0.00
	endif
	set dx = targetX - GetUnitX(source)
	set dy = targetY - GetUnitY(source)
	return bj_RADTODEG * Atan2(dy, dx)
endfunction

private function NormalizeAngle takes real angle returns real
	loop
		exitwhen angle >= 0.00 and angle < 360.00
		if angle < 0.00 then
			set angle = angle + 360.00
		else
			set angle = angle - 360.00
		endif
	endloop
	return angle
endfunction

private function GetSignedAngleDelta takes real fromAngle, real toAngle returns real
	local real delta
	set delta = NormalizeAngle(toAngle - fromAngle)
	if delta > 180.00 then
		set delta = delta - 360.00
	endif
	return delta
endfunction

public function MakeUnitFaceUnit takes unit source, unit target, real duration returns nothing
	local real angle
	if source == null or target == null then
		return
	endif
	set angle = GetAngleBetweenUnits(source, target)
	call SetUnitFacingTimed(source, angle, duration)
endfunction

public function MakeUnitFacePoint takes unit source, real targetX, real targetY, real duration returns nothing
	local real angle
	if source == null then
		return
	endif
	set angle = GetAngleBetweenUnitAndPoint(source, targetX, targetY)
	call SetUnitFacingTimed(source, angle, duration)
endfunction

public function MakeFaceEachOther takes unit unit1, unit unit2, real duration returns nothing
	// If duration is <= 0, use a random duration for each unit to avoid unnatural synchronized movement
	local real actualDurationA
	local real actualDurationB
	if unit1 == null or unit2 == null then
		return
	endif
	if duration <= 0.00 then
		set actualDurationA = GetRandomReal(DIALOGSYSTEM_FACE_RANDOM_MIN, DIALOGSYSTEM_FACE_RANDOM_MAX)
		set actualDurationB = GetRandomReal(DIALOGSYSTEM_FACE_RANDOM_MIN, DIALOGSYSTEM_FACE_RANDOM_MAX)
	else
		set actualDurationA = duration
		set actualDurationB = duration
	endif
	call MakeUnitFaceUnit(unit1, unit2, actualDurationA)
	call MakeUnitFaceUnit(unit2, unit1, actualDurationB)
endfunction

private function LookAtTimerExpire takes nothing returns nothing
	local timer t = GetExpiredTimer()
	local integer id = GetHandleId(t)
	local unit u = DialogSystem_LookAtTimerUnit.unit[id]
	if u != null then
		call ResetUnitLookAt(u)
	endif
	set DialogSystem_LookAtTimerUnit.unit[id] = null
	call DestroyTimer(t)
endfunction

public function ResetLookAt takes unit source returns nothing
	if source != null then
		call ResetUnitLookAt(source)
	endif
endfunction

public function LookAtUnitWithFacingEx takes unit source, unit target, string bone, real angleThreshold, real faceDuration, real headDuration returns nothing
	local real targetAngle
	local real currentFacing
	local real delta
	local real newFacing
	local timer t
	if source == null or target == null then
		return
	endif
	set targetAngle = GetAngleBetweenUnits(source, target)
	set currentFacing = NormalizeAngle(GetUnitFacing(source))
	set delta = GetSignedAngleDelta(currentFacing, targetAngle)
	if delta > angleThreshold or delta < -angleThreshold then
		if delta > 0.00 then
			set newFacing = NormalizeAngle(targetAngle - angleThreshold)
		else
			set newFacing = NormalizeAngle(targetAngle + angleThreshold)
		endif
		call SetUnitFacingTimed(source, newFacing, faceDuration)
	endif
	call SetUnitLookAt(source, bone, target, 0.00, 0.00, 0.00)
	if headDuration > 0.00 then
		set t = CreateTimer()
		set DialogSystem_LookAtTimerUnit.unit[GetHandleId(t)] = source
		call TimerStart(t, headDuration, false, function LookAtTimerExpire)
	endif
endfunction

public function LookAtPointWithFacingEx takes unit source, real targetX, real targetY, string bone, real angleThreshold, real faceDuration, real headDuration returns nothing
	local real targetAngle
	local real currentFacing
	local real delta
	local real newFacing
	local timer t
	if source == null then
		return
	endif
	set targetAngle = GetAngleBetweenUnitAndPoint(source, targetX, targetY)
	set currentFacing = NormalizeAngle(GetUnitFacing(source))
	set delta = GetSignedAngleDelta(currentFacing, targetAngle)
	if delta > angleThreshold or delta < -angleThreshold then
		if delta > 0.00 then
			set newFacing = NormalizeAngle(targetAngle - angleThreshold)
		else
			set newFacing = NormalizeAngle(targetAngle + angleThreshold)
		endif
		call SetUnitFacingTimed(source, newFacing, faceDuration)
	endif
	call SetUnitLookAt(source, bone, null, targetX, targetY, 0.00)
	if headDuration > 0.00 then
		set t = CreateTimer()
		set DialogSystem_LookAtTimerUnit.unit[GetHandleId(t)] = source
		call TimerStart(t, headDuration, false, function LookAtTimerExpire)
	endif
endfunction

public function LookAtUnitWithFacing takes unit source, unit target returns nothing
	call LookAtUnitWithFacingEx(source, target, DIALOGSYSTEM_LOOK_BONE, DIALOGSYSTEM_LOOK_THRESHOLD, DIALOGSYSTEM_LOOK_FACE_DURATION, DIALOGSYSTEM_LOOK_HEAD_DURATION)
endfunction

public function LookAtPointWithFacing takes unit source, real targetX, real targetY returns nothing
	call LookAtPointWithFacingEx(source, targetX, targetY, DIALOGSYSTEM_LOOK_BONE, DIALOGSYSTEM_LOOK_THRESHOLD, DIALOGSYSTEM_LOOK_FACE_DURATION, DIALOGSYSTEM_LOOK_HEAD_DURATION)
endfunction

private function EndSequence takes boolean callFinish returns nothing
	local Table seqTable
	local trigger onFinish
	if DialogSequenceActiveId == 0 then
		return
	endif
	set seqTable = DialogSequenceStore[DialogSequenceActiveId]
	if callFinish and seqTable != 0 then
		set onFinish = seqTable.trigger[DIALOG_SEQ_ONFINISH_KEY]
		if onFinish != null then
			call TriggerExecute(onFinish)
		endif
	endif
	set DialogSequenceActiveId = 0
	set DialogSequenceActiveIndex = 0
	set DialogSequenceFastForward = false
	set DialogSequenceSkipping = false
endfunction

private function PlayNextLine takes nothing returns nothing
	local Table seqTable
	local integer count
	local integer base
	local string text
	local string soundKey
	local string speakerName
	local unit speaker
	local trigger lineAction
	local boolean soundAtUnit
	local boolean delayOnly
	local real duration
	local real customDuration
	local integer actionType
	local unit actionUnit1
	local unit actionUnit2
	local real actionX
	local real actionY
	local real actionDuration
	if DialogSequenceActiveId == 0 then
		return
	endif
	if DialogSequenceSkipping then
		call EndSequence(true)
		return
	endif
	set seqTable = DialogSequenceStore[DialogSequenceActiveId]
	if seqTable == 0 then
		call EndSequence(false)
		return
	endif
	set count = seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY]
	set DialogSequenceActiveIndex = DialogSequenceActiveIndex + 1
	if DialogSequenceActiveIndex > count then
		call EndSequence(true)
		return
	endif
	set base = DialogSequenceActiveIndex * 10
	set text = seqTable.string[base + DIALOG_LINE_TEXT_KEY]
	set soundKey = seqTable.string[base + DIALOG_LINE_SOUND_KEY]
	set speaker = seqTable.unit[base + DIALOG_LINE_SPEAKER_KEY]
	set speakerName = seqTable.string[base + DIALOG_LINE_SPEAKER_NAME_KEY]
	set lineAction = seqTable.trigger[base + DIALOG_LINE_ACTION_KEY]
	set soundAtUnit = seqTable.boolean[base + DIALOG_LINE_SOUND_AT_UNIT_KEY]
	set delayOnly = seqTable.boolean[base + DIALOG_LINE_DELAY_ONLY_KEY]
	set customDuration = seqTable.real[base + DIALOG_LINE_CUSTOM_DURATION_KEY]

	if speaker == null then
		set speaker = seqTable.unit[DIALOG_SEQ_DEFAULT_SPEAKER_KEY]
	endif
	if speaker == null then
		set speaker = DialogSystem_ActiveNPC
	endif
	if speakerName == "" then
		set speakerName = seqTable.string[DIALOG_SEQ_DEFAULT_NAME_KEY]
	endif
	if speakerName == "" and speaker != null then
		set speakerName = GetUnitDisplayName(speaker)
	endif

	if lineAction != null then
		call TriggerExecute(lineAction)
	endif

	// Execute sequence actions (facing/looking) if specified
	set actionType = seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY]
	
	if actionType != SEQ_ACTION_TYPE_NONE then
		set actionUnit1 = seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY]
		set actionUnit2 = seqTable.unit[base + DIALOG_LINE_ACTION_UNIT2_KEY]
		set actionX = seqTable.real[base + DIALOG_LINE_ACTION_X_KEY]
		set actionY = seqTable.real[base + DIALOG_LINE_ACTION_Y_KEY]
		set actionDuration = seqTable.real[base + DIALOG_LINE_ACTION_DURATION_KEY]
		
		if actionType == SEQ_ACTION_TYPE_FACE_EACH_OTHER then
			call MakeFaceEachOther(actionUnit1, actionUnit2, actionDuration)
		elseif actionType == SEQ_ACTION_TYPE_FACE_UNIT then
			call MakeUnitFaceUnit(actionUnit1, actionUnit2, actionDuration)
		elseif actionType == SEQ_ACTION_TYPE_FACE_POINT then
			call MakeUnitFacePoint(actionUnit1, actionX, actionY, actionDuration)
		elseif actionType == SEQ_ACTION_TYPE_LOOK_AT_UNIT then
			call LookAtUnitWithFacing(actionUnit1, actionUnit2)
		elseif actionType == SEQ_ACTION_TYPE_LOOK_AT_POINT then
			call LookAtPointWithFacing(actionUnit1, actionX, actionY)
		elseif actionType == SEQ_ACTION_TYPE_RESET_LOOK_AT then
			call ResetLookAt(actionUnit1)
		endif
	endif

	// Check if this is a delay-only line (no dialogue display)
	if delayOnly then
		if customDuration > 0.0 then
			set duration = customDuration
		else
			set duration = DIALOGSYSTEM_MIN_DURATION
		endif
	else
		// Normal line with dialogue display
		if soundKey != "" then
			if soundAtUnit and speaker != null then
				call ExSound_PlayAtUnit(soundKey, speaker, text)
			else
				call ExSound_Play(soundKey, text)
			endif
			set duration = udg_ExSoundDuration
			if duration <= 0.00 then
				set duration = EstimateDuration(text)
			endif
		else
			set duration = EstimateDuration(text)
		endif

		if speaker != null then
			call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, speaker, speakerName, null, text, bj_TIMETYPE_SET, duration, false)
		else
			call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, duration, text)
		endif

		if customDuration > 0.0 then
			set duration = customDuration
		endif
	endif

	if DialogSequenceFastForward then
		set duration = DIALOGSYSTEM_FAST_FORWARD_DURATION
	endif
	if duration < 0.01 then
		set duration = 0.01
	endif
	call TimerStart(DialogSequenceTimer, duration, false, function PlayNextLine)
endfunction

//===========================================================================
// Single-line helper
//===========================================================================
public function PlayLine takes unit speaker, string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	local real duration
	if speaker == null then
		set speaker = DialogSystem_ActiveNPC
	endif
	if speakerName == "" and speaker != null then
		set speakerName = GetUnitDisplayName(speaker)
	endif

	if soundKey != "" then
		if soundAtUnit and speaker != null then
			call ExSound_PlayAtUnit(soundKey, speaker, text)
		else
			call ExSound_Play(soundKey, text)
		endif
		set duration = udg_ExSoundDuration
		if duration <= 0.00 then
			set duration = EstimateDuration(text)
		endif
	else
		set duration = EstimateDuration(text)
	endif

	if speaker != null then
		call TransmissionFromUnitWithNameBJ(bj_FORCE_ALL_PLAYERS, speaker, speakerName, null, text, bj_TIMETYPE_SET, duration, false)
	else
		call DisplayTimedTextToForce(bj_FORCE_ALL_PLAYERS, duration, text)
	endif
endfunction

private function IsFieldLineSpeakerAlive takes unit speaker returns boolean
	if speaker == null then
		return false
	endif
	return GetUnitTypeId(speaker) != 0 and not IsUnitType(speaker, UNIT_TYPE_DEAD)
endfunction

public function EstimateFieldLineDuration takes string text returns real
	local real duration = 1.80 + I2R(StringLength(text)) * 0.05
	if duration < 2.50 then
		set duration = 2.50
	elseif duration > 7.50 then
		set duration = 7.50
	endif
	return duration
endfunction

private function ShowFieldLine takes unit speaker, string speakerName, string soundName, string text returns nothing
	if not IsFieldLineSpeakerAlive(speaker) then
		return
	endif
	call PlayLine(speaker, speakerName, text, soundName, true)
endfunction

public function ClearFieldLineQueue takes nothing returns nothing
	local integer i = 1
	if DialogSystem_FieldLineQueueTimer != null then
		call DestroyTimer(DialogSystem_FieldLineQueueTimer)
		set DialogSystem_FieldLineQueueTimer = null
	endif
	loop
		exitwhen i > DIALOGSYSTEM_FIELD_LINE_QUEUE_MAX
		set DialogSystem_FieldLineQueueSpeakers[i] = null
		set DialogSystem_FieldLineQueueSpeakerNames[i] = ""
		set DialogSystem_FieldLineQueueSoundNames[i] = ""
		set DialogSystem_FieldLineQueueTexts[i] = ""
		set i = i + 1
	endloop
	set DialogSystem_FieldLineQueueCount = 0
	set DialogSystem_FieldLineQueueBusy = false
endfunction

private function PlayNextFieldLine takes nothing returns nothing
	local real delay
	local integer i
	if DialogSystem_FieldLineQueueCount <= 0 then
		set DialogSystem_FieldLineQueueBusy = false
		if DialogSystem_FieldLineQueueTimer != null then
			call DestroyTimer(DialogSystem_FieldLineQueueTimer)
			set DialogSystem_FieldLineQueueTimer = null
		endif
		return
	endif
	set DialogSystem_FieldLineQueueBusy = true
	call ShowFieldLine(DialogSystem_FieldLineQueueSpeakers[1], DialogSystem_FieldLineQueueSpeakerNames[1], DialogSystem_FieldLineQueueSoundNames[1], DialogSystem_FieldLineQueueTexts[1])
	if IsFieldLineSpeakerAlive(DialogSystem_FieldLineQueueSpeakers[1]) and DialogSystem_FieldLineQueueSoundNames[1] != "" and udg_ExSoundDuration > 0.00 then
		set delay = udg_ExSoundDuration
	else
		set delay = EstimateFieldLineDuration(DialogSystem_FieldLineQueueTexts[1])
	endif
	set i = 1
	loop
		exitwhen i >= DialogSystem_FieldLineQueueCount
		set DialogSystem_FieldLineQueueSpeakers[i] = DialogSystem_FieldLineQueueSpeakers[i + 1]
		set DialogSystem_FieldLineQueueSpeakerNames[i] = DialogSystem_FieldLineQueueSpeakerNames[i + 1]
		set DialogSystem_FieldLineQueueSoundNames[i] = DialogSystem_FieldLineQueueSoundNames[i + 1]
		set DialogSystem_FieldLineQueueTexts[i] = DialogSystem_FieldLineQueueTexts[i + 1]
		set i = i + 1
	endloop
	set DialogSystem_FieldLineQueueSpeakers[DialogSystem_FieldLineQueueCount] = null
	set DialogSystem_FieldLineQueueSpeakerNames[DialogSystem_FieldLineQueueCount] = ""
	set DialogSystem_FieldLineQueueSoundNames[DialogSystem_FieldLineQueueCount] = ""
	set DialogSystem_FieldLineQueueTexts[DialogSystem_FieldLineQueueCount] = ""
	set DialogSystem_FieldLineQueueCount = DialogSystem_FieldLineQueueCount - 1
	if DialogSystem_FieldLineQueueTimer == null then
		set DialogSystem_FieldLineQueueTimer = CreateTimer()
	endif
	call TimerStart(DialogSystem_FieldLineQueueTimer, delay, false, function PlayNextFieldLine)
endfunction

public function QueueFieldLine takes unit speaker, string speakerName, string soundName, string text returns nothing
	if not IsFieldLineSpeakerAlive(speaker) then
		return
	endif
	if DialogSystem_FieldLineQueueCount >= DIALOGSYSTEM_FIELD_LINE_QUEUE_MAX then
		return
	endif
	set DialogSystem_FieldLineQueueCount = DialogSystem_FieldLineQueueCount + 1
	set DialogSystem_FieldLineQueueSpeakers[DialogSystem_FieldLineQueueCount] = speaker
	set DialogSystem_FieldLineQueueSpeakerNames[DialogSystem_FieldLineQueueCount] = speakerName
	set DialogSystem_FieldLineQueueSoundNames[DialogSystem_FieldLineQueueCount] = soundName
	set DialogSystem_FieldLineQueueTexts[DialogSystem_FieldLineQueueCount] = text
	if not DialogSystem_FieldLineQueueBusy then
		call PlayNextFieldLine()
	endif
endfunction

//===========================================================================
// Registration helpers for NPC-specific lines
//===========================================================================
private function RegisterLineInternal takes Table linesTable, string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	local Table listTable
	local integer count
	local integer base
	if linesTable == 0 or speakerName == "" then
		return
	endif
	set listTable = linesTable.link(StringHash(speakerName))
	set count = listTable.integer[DIALOG_LIST_COUNT_KEY] + 1
	set listTable.integer[DIALOG_LIST_COUNT_KEY] = count
	set base = count * 10
	set listTable.string[base + DIALOG_LIST_TEXT_KEY] = text
	set listTable.string[base + DIALOG_LIST_SOUND_KEY] = soundKey
	set listTable.boolean[base + DIALOG_LIST_SOUND_AT_UNIT_KEY] = soundAtUnit
endfunction

private function PlayRegisteredLine takes Table linesTable, unit speaker, string speakerName returns boolean
	local Table listTable
	local integer count
	local integer pick
	local integer base
	local string text
	local string soundKey
	local boolean soundAtUnit
	if linesTable == 0 or speakerName == "" then
		return false
	endif
	if not linesTable.has(StringHash(speakerName)) then
		return false
	endif
	set listTable = linesTable[StringHash(speakerName)]
	set count = listTable.integer[DIALOG_LIST_COUNT_KEY]
	if count <= 0 then
		return false
	endif
	set pick = GetRandomInt(1, count)
	set base = pick * 10
	set text = listTable.string[base + DIALOG_LIST_TEXT_KEY]
	set soundKey = listTable.string[base + DIALOG_LIST_SOUND_KEY]
	set soundAtUnit = listTable.boolean[base + DIALOG_LIST_SOUND_AT_UNIT_KEY]
	if text == "" and soundKey == "" then
		return false
	endif
	call PlayLine(speaker, speakerName, text, soundKey, soundAtUnit)
	return true
endfunction

private function PickRegisteredLineData takes Table linesTable, string speakerName returns boolean
	local Table listTable
	local integer count
	local integer pick
	local integer base
	if linesTable == 0 or speakerName == "" then
		return false
	endif
	if not linesTable.has(StringHash(speakerName)) then
		return false
	endif
	set listTable = linesTable[StringHash(speakerName)]
	set count = listTable.integer[DIALOG_LIST_COUNT_KEY]
	if count <= 0 then
		return false
	endif
	set pick = GetRandomInt(1, count)
	set base = pick * 10
	set DialogSystem_PickedText = listTable.string[base + DIALOG_LIST_TEXT_KEY]
	set DialogSystem_PickedSound = listTable.string[base + DIALOG_LIST_SOUND_KEY]
	set DialogSystem_PickedSoundAtUnit = listTable.boolean[base + DIALOG_LIST_SOUND_AT_UNIT_KEY]
	if DialogSystem_PickedText == "" and DialogSystem_PickedSound == "" then
		return false
	endif
	return true
endfunction

//===========================================================================
// Public API
//===========================================================================
// Sets the context for dialog button actions. This is automatically set when showing a dialog, but can be manually set if needed.
public function SetContext takes unit npc, player p returns nothing
	set DialogSystem_ActiveNPC = npc
	set DialogSystem_ActivePlayer = p
endfunction

public function StartDialogCamera takes player p, unit u, real dist, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck, boolean useCamera returns nothing
	if not useCamera or p == null or u == null then
		return
	endif
	call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck)
endfunction

public function ChangeDialogCamera takes player p, unit u, real dist, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck, boolean useCamera returns nothing
	if not useCamera or p == null or u == null then
		return
	endif
	call DialogCameraStart(p, u, dist, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck)
endfunction

public function StopDialogCamera takes player p, real duration, boolean useCamera returns nothing
	if not useCamera or p == null then
		return
	endif
	call DialogCameraReset(p, duration)
endfunction

public function ClearDialog takes dialog d returns nothing
	if d == null then
		return
	endif
	call DialogClear(d)
endfunction

public function SetTitle takes dialog d, string title returns nothing
	if d == null then
		return
	endif
	call DialogSetMessage(d, title)
endfunction

public function AddButton takes dialog d, string label, integer actionId returns button
	local button b
	if d == null then
		return null
	endif
	set b = DialogAddButton(d, label, 0)
	set DialogButtonAction.integer[GetHandleId(b)] = actionId
	set DialogButtonDialog.dialog[GetHandleId(b)] = d
	return b
endfunction

public function AddFarewellButton takes dialog d returns button
	return AddButton(d, "- Farewell", 0)
endfunction

public function AddButtonNext takes dialog d, integer actionId returns button
	return AddButton(d, "Next", actionId)
endfunction

public function AddButtonPrevious takes dialog d, integer actionId returns button
	return AddButton(d, "- Previous", actionId)
endfunction

public function AddButtonQuestAccept takes dialog d, string questName, integer actionId returns button
	local button b = AddButton(d, questName + " (Accept)", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_ACCEPT
	endif
	return b
endfunction

public function AddButtonQuestAcceptNoAutoPlay takes dialog d, string questName, integer actionId returns button
	return AddButton(d, questName + " (Accept)", actionId)
endfunction

public function AddButtonQuestFailed takes dialog d, string questName, integer actionId returns button
	return AddButton(d, questName + " (Failed)", actionId)
endfunction

public function AddButtonQuestComplete takes dialog d, string questName, integer actionId returns button
	return AddButton(d, questName + " (Completion)", actionId)
endfunction

public function AddButtonQuestSubComplete takes dialog d, string questName, integer actionId returns button
	return AddButton(d, questName + " (Sub-Complete)", actionId)
endfunction

public function AddButtonDecline takes dialog d, integer actionId returns button
	local button b = AddButton(d, "Decline", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_DECLINE
	endif
	return b
endfunction

public function AddButtonExit takes dialog d, integer actionId returns button
	local button b = AddButton(d, "Exit", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_EXIT
	endif
	return b
endfunction

public function AddButtonStart takes dialog d, integer actionId returns button
	return AddButton(d, "Start", actionId)
endfunction

public function AddButtonTrade takes dialog d, integer actionId returns button
	local button b = AddButton(d, "Trade", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_TRADE
	endif
	return b
endfunction

public function AddButtonSpecial takes dialog d, integer actionId returns button
	return AddButton(d, "Special", actionId)
endfunction

public function AddButtonFollow takes dialog d, integer actionId returns button
	local button b = AddButton(d, "Follow", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_FOLLOW
	endif
	return b
endfunction

public function AddButtonStop takes dialog d, integer actionId returns button
	local button b = AddButton(d, "Stop", actionId)
	if b != null then
		set DialogButtonLineAction.integer[GetHandleId(b)] = DIALOG_LINE_ACTION_STOP
	endif
	return b
endfunction

public function AddButtonInfo takes dialog d, integer actionId returns button
	return AddButton(d, "Info", actionId)
endfunction

public function BindButtonTrigger takes button b, trigger t returns nothing
	if b == null or t == null then
		return
	endif
	set DialogButtonTrigger.trigger[GetHandleId(b)] = t
endfunction

public function BindButtonCode takes button b, code actionFunc returns nothing
	local trigger t
	if b == null or actionFunc == null then
		return
	endif
	set t = CreateTrigger()
	call TriggerAddAction(t, actionFunc)
	set DialogButtonTrigger.trigger[GetHandleId(b)] = t
endfunction

public function ShowDialog takes dialog d, player p returns nothing
	if d == null or p == null then
		return
	endif
	call EnableUserControl(true)
	set DialogSystem_ActivePlayer = p
	call DialogDisplay(p, d, true)
endfunction

public function HideDialog takes dialog d, player p returns nothing
	if d == null or p == null then
		return
	endif
	call DialogDisplay(p, d, false)
endfunction

//===========================================================================
// Sequence API
//===========================================================================
public function CreateSequence takes nothing returns integer
	local integer seqId = DialogSequenceNextId
	local Table seqTable
	set DialogSequenceNextId = DialogSequenceNextId + 1
	set seqTable = Table.create()
	set DialogSequenceStore[seqId] = seqTable
	set seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY] = 0
	set seqTable.boolean[DIALOG_SEQ_ALLOW_SKIP_KEY] = true
	return seqId
endfunction

public function ClearSequence takes integer seqId returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	if seqTable == 0 then
		return
	endif
	call seqTable.destroy()
	call DialogSequenceStore.remove(seqId)
endfunction

public function SetSequenceDefaultSpeaker takes integer seqId, unit speaker, string speakerName returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	if seqTable == 0 then
		return
	endif
	// Safety: Allow null speaker for narrator mode
	// Only store non-null speakers to prevent ACCESS_VIOLATION
	if speaker != null then
		set seqTable.unit[DIALOG_SEQ_DEFAULT_SPEAKER_KEY] = speaker
	endif
	set seqTable.string[DIALOG_SEQ_DEFAULT_NAME_KEY] = speakerName
endfunction

public function SetSequenceSkippable takes integer seqId, boolean flag returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	if seqTable == 0 then
		return
	endif
	set seqTable.boolean[DIALOG_SEQ_ALLOW_SKIP_KEY] = flag
endfunction

public function SetSequenceCallbacks takes integer seqId, code onStart, code onFinish returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	local trigger t
	if seqTable == 0 then
		return
	endif
	if onStart != null then
		set t = CreateTrigger()
		call TriggerAddAction(t, onStart)
		set seqTable.trigger[DIALOG_SEQ_ONSTART_KEY] = t
	endif
	if onFinish != null then
		set t = CreateTrigger()
		call TriggerAddAction(t, onFinish)
		set seqTable.trigger[DIALOG_SEQ_ONFINISH_KEY] = t
	endif
endfunction

public function AddLine takes integer seqId, unit speaker, string speakerName, string text, string soundKey, boolean soundAtUnit returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	if seqTable == 0 then
		return 0
	endif
	// Safety: Check sequence size to prevent hashtable overflow/corruption
	// When base index gets too large, hashtable operations can crash with ACCESS_VIOLATION
	set index = seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY] + 1
	if index > 100 then
		call BJDebugMsg("[DialogSystem] ERROR: Sequence " + I2S(seqId) + " has too many lines (" + I2S(index) + ")! This may cause ACCESS_VIOLATION.")
		return 0
	endif
	set base = index * 10
	set seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY] = index
	
	// Safety: Allow null speaker for narrator lines or when speaker is not available
	// Storing null in Table.unit[] causes ACCESS_VIOLATION, so skip speaker storage
	if speaker == null then
		// Still add the line, but with null speaker (dialogue can play without animation)
		// Skip: set seqTable.unit[base + DIALOG_LINE_SPEAKER_KEY] = speaker
		set seqTable.string[base + DIALOG_LINE_SPEAKER_NAME_KEY] = speakerName
		set seqTable.string[base + DIALOG_LINE_TEXT_KEY] = text
		set seqTable.string[base + DIALOG_LINE_SOUND_KEY] = soundKey
		set seqTable.boolean[base + DIALOG_LINE_SOUND_AT_UNIT_KEY] = soundAtUnit
		return index
	endif
	set seqTable.unit[base + DIALOG_LINE_SPEAKER_KEY] = speaker
	set seqTable.string[base + DIALOG_LINE_SPEAKER_NAME_KEY] = speakerName
	set seqTable.string[base + DIALOG_LINE_TEXT_KEY] = text
	set seqTable.string[base + DIALOG_LINE_SOUND_KEY] = soundKey
	set seqTable.boolean[base + DIALOG_LINE_SOUND_AT_UNIT_KEY] = soundAtUnit
	return index
endfunction

public function AddLineNoSound takes integer seqId, unit speaker, string speakerName, string text returns integer
	return AddLine(seqId, speaker, speakerName, text, "", false)
endfunction

public function AddDelay takes integer seqId, real duration returns integer
	local Table seqTable
	local integer count
	local integer index
	local integer base

	if seqId <= 0 or seqId >= DialogSequenceNextId then
		return 0
	endif
	set seqTable = DialogSequenceStore[seqId]
	if seqTable == 0 then
		return 0
	endif
	set count = seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY]
	set index = count + 1
	set count = index
	set seqTable.integer[DIALOG_SEQ_LINE_COUNT_KEY] = count
	set base = index * 10

	// Set delay-only flag and custom duration
	set seqTable.boolean[base + DIALOG_LINE_DELAY_ONLY_KEY] = true
	if duration > 0.0 then
		set seqTable.real[base + DIALOG_LINE_CUSTOM_DURATION_KEY] = duration
	else
		set seqTable.real[base + DIALOG_LINE_CUSTOM_DURATION_KEY] = DIALOGSYSTEM_MIN_DURATION
	endif

	// Set empty values for other fields
	set seqTable.unit[base + DIALOG_LINE_SPEAKER_KEY] = null
	set seqTable.string[base + DIALOG_LINE_SPEAKER_NAME_KEY] = ""
	set seqTable.string[base + DIALOG_LINE_TEXT_KEY] = ""
	set seqTable.string[base + DIALOG_LINE_SOUND_KEY] = ""
	set seqTable.boolean[base + DIALOG_LINE_SOUND_AT_UNIT_KEY] = false

	return index
endfunction

private function AddLineIfPresent takes integer seqId, unit speaker, string speakerName, string text, string soundKey returns nothing
	if text == "" and soundKey == "" then
		return
	endif
	call AddLine(seqId, speaker, speakerName, text, soundKey, true)
endfunction

public function ClearRandomOptions takes nothing returns nothing
	local integer i = 1
	loop
		exitwhen i > 4
		set DialogSystem_RandomOptTextA[i] = ""
		set DialogSystem_RandomOptSoundA[i] = ""
		set DialogSystem_RandomOptTextB[i] = ""
		set DialogSystem_RandomOptSoundB[i] = ""
		set i = i + 1
	endloop
endfunction

public function SetRandomOption takes integer index, string textA, string soundA, string textB, string soundB returns nothing
	if index < 1 or index > 4 then
		return
	endif
	set DialogSystem_RandomOptTextA[index] = textA
	set DialogSystem_RandomOptSoundA[index] = soundA
	set DialogSystem_RandomOptTextB[index] = textB
	set DialogSystem_RandomOptSoundB[index] = soundB
endfunction

// Creates a sequence with 2 lines, where the line text and sound are randomly picked from predefined options
// The options are defined using SetRandomOption, and up to optionCount will be used (max 4). 
// If optionCount is less than 4, only the first optionCount entries will be considered for random selection.
public function CreateRandomSequence2LinesWithOptions takes unit speaker, string speakerName, integer optionCount returns integer
	local integer seqId
	local integer roll
	if optionCount <= 0 then
		return 0
	endif
	if optionCount > 4 then
		set optionCount = 4
	endif
	set seqId = CreateSequence()
	call SetSequenceDefaultSpeaker(seqId, speaker, speakerName)
	set roll = GetRandomInt(1, optionCount)
	call AddLineIfPresent(seqId, speaker, speakerName, DialogSystem_RandomOptTextA[roll], DialogSystem_RandomOptSoundA[roll])
	call AddLineIfPresent(seqId, speaker, speakerName, DialogSystem_RandomOptTextB[roll], DialogSystem_RandomOptSoundB[roll])
	return seqId
endfunction

// Binds a trigger to execute when a specific line in the sequence is reached. The trigger will be executed before displaying the line.
public function BindLineAction takes integer seqId, integer lineIndex, code actionFunc returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	local integer base
	local trigger t
	if seqTable == 0 or lineIndex <= 0 or actionFunc == null then
		return
	endif
	set base = lineIndex * 10
	set t = CreateTrigger()
	call TriggerAddAction(t, actionFunc)
	set seqTable.trigger[base + DIALOG_LINE_ACTION_KEY] = t
endfunction

// Binds a facing/looking action to a specific line in the sequence. The action will be executed before displaying the line.
public function PlaySequence takes integer seqId, player p, unit npc returns nothing
	local Table seqTable = DialogSequenceStore[seqId]
	local trigger onStart
	if seqTable == 0 then
		return
	endif
	if DialogSequenceActiveId != 0 then
		call EndSequence(false)
	endif
	if DialogSequenceTimer == null then
		set DialogSequenceTimer = CreateTimer()
	endif
	set DialogSequenceActiveId = seqId
	set DialogSequenceActiveIndex = 0
	set DialogSequenceFastForward = false
	set DialogSequenceSkipping = false
	call SetContext(npc, p)
	set onStart = seqTable.trigger[DIALOG_SEQ_ONSTART_KEY]
	if onStart != null then
		call TriggerExecute(onStart)
	endif
	call PlayNextLine()
endfunction

public function IsSequenceActive takes nothing returns boolean
	return DialogSequenceActiveId != 0
endfunction

public function GetActiveSequenceId takes nothing returns integer
	return DialogSequenceActiveId
endfunction

public function SkipActiveSequence takes nothing returns nothing
	local Table seqTable
	if DialogSequenceActiveId == 0 then
		return
	endif
	set seqTable = DialogSequenceStore[DialogSequenceActiveId]
	if seqTable == 0 then
		call EndSequence(false)
		return
	endif
	if seqTable.boolean[DIALOG_SEQ_ALLOW_SKIP_KEY] then
		set DialogSequenceSkipping = true
		// Stop the timer to prevent interference with callback execution
		if DialogSequenceTimer != null then
			call PauseTimer(DialogSequenceTimer)
		endif
		// Clear any active transmission immediately
		call ClearTextMessages()
		call EndSequence(true)
	endif
endfunction

public function FastForwardActiveSequence takes boolean flag returns nothing
	set DialogSequenceFastForward = flag
endfunction

public function ClearEscapeAction takes nothing returns nothing
	if DialogSystem_EscapeActionTrigger != null then
		if DialogSystem_EscapeActionExecuting and DialogSystem_EscapeActionTrigger == DialogSystem_EscapeActionExecutingTrigger then
			set DialogSystem_EscapeActionTrigger = null
			return
		endif
		call DestroyTrigger(DialogSystem_EscapeActionTrigger)
		set DialogSystem_EscapeActionTrigger = null
	endif
endfunction

public function SetEscapeAction takes code actionFunc returns nothing
	local trigger t
	call ClearEscapeAction()
	set t = CreateTrigger()
	call TriggerAddAction(t, actionFunc)
	set DialogSystem_EscapeActionTrigger = t
endfunction

// ESC skip handler
private function OnSkipKey takes nothing returns nothing
	local trigger escTrigger
	if DialogSystem_ActivePlayer != null and GetTriggerPlayer() != DialogSystem_ActivePlayer then
		return
	endif
	if DialogSequenceActiveId != 0 then
		call SkipActiveSequence()
	elseif DialogSystem_EscapeActionTrigger != null then
		set escTrigger = DialogSystem_EscapeActionTrigger
		set DialogSystem_EscapeActionExecuting = true
		set DialogSystem_EscapeActionExecutingTrigger = escTrigger
		call TriggerExecute(escTrigger)
		set DialogSystem_EscapeActionExecuting = false
		if DialogSystem_EscapeActionExecutingTrigger != null and DialogSystem_EscapeActionExecutingTrigger != DialogSystem_EscapeActionTrigger then
			call DestroyTrigger(DialogSystem_EscapeActionExecutingTrigger)
		endif
		set DialogSystem_EscapeActionExecutingTrigger = null
	endif
endfunction

//===========================================================================
// Generic greet/farewell lines
//===========================================================================
public function PlayGreet takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_GreetLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Hello."
	elseif roll == 2 then
		set text = "Well met."
	elseif roll == 3 then
		set text = "Greetings."
	elseif roll == 4 then
		set text = "Hi."
	else
		set text = "Hello there."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PickGreetLine takes unit speaker, string speakerName returns boolean
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	set DialogSystem_PickedText = ""
	set DialogSystem_PickedSound = ""
	set DialogSystem_PickedSoundAtUnit = true
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if lookupName != "" and PickRegisteredLineData(DialogSystem_GreetLines, lookupName) then
		return true
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Hello."
	elseif roll == 2 then
		set text = "Well met."
	elseif roll == 3 then
		set text = "Greetings."
	elseif roll == 4 then
		set text = "Hi."
	else
		set text = "Hello there."
	endif
	set soundKey = ""
	set DialogSystem_PickedText = text
	set DialogSystem_PickedSound = soundKey
	set DialogSystem_PickedSoundAtUnit = true
	return true
endfunction

public function PickFarewellLine takes unit speaker, string speakerName returns boolean
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	set DialogSystem_PickedText = ""
	set DialogSystem_PickedSound = ""
	set DialogSystem_PickedSoundAtUnit = true
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if lookupName != "" and PickRegisteredLineData(DialogSystem_FarewellLines, lookupName) then
		return true
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Farewell."
	elseif roll == 2 then
		set text = "Goodbye."
	elseif roll == 3 then
		set text = "Until next time."
	elseif roll == 4 then
		set text = "Safe travels."
	else
		set text = "May your path be clear."
	endif
	set soundKey = ""
	set DialogSystem_PickedText = text
	set DialogSystem_PickedSound = soundKey
	set DialogSystem_PickedSoundAtUnit = true
	return true
endfunction

public function PlayFarewell takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_FarewellLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Farewell."
	elseif roll == 2 then
		set text = "Goodbye."
	elseif roll == 3 then
		set text = "Until next time."
	elseif roll == 4 then
		set text = "Safe travels."
	else
		set text = "May your path be clear."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function RegisterGreetLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_GreetLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterFarewellLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_FarewellLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterFarewellLineForUnit takes unit u, string text, string soundKey, boolean soundAtUnit returns nothing
	if u == null then
		return
	endif
	call RegisterLineInternal(DialogSystem_FarewellLines, GetUnitDisplayName(u), text, soundKey, soundAtUnit)
endfunction

public function RegisterTradeLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_TradeLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterExitLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_ExitLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterFollowLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_FollowLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterStopLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_StopLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterDeclineLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_DeclineLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterAcceptLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_AcceptLines, speakerName, text, soundKey, soundAtUnit)
endfunction

public function RegisterInfoLine takes string speakerName, string text, string soundKey, boolean soundAtUnit returns nothing
	call RegisterLineInternal(DialogSystem_InfoLines, speakerName, text, soundKey, soundAtUnit)
endfunction

//===========================================================================
// Generic action lines
//===========================================================================
public function PlayTrade takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_TradeLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Let's trade."
	elseif roll == 2 then
		set text = "Show me what you have."
	elseif roll == 3 then
		set text = "Let's see your wares."
	elseif roll == 4 then
		set text = "Got anything for sale?"
	else
		set text = "Let us trade."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayExit takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_ExitLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Farewell."
	elseif roll == 2 then
		set text = "Goodbye."
	elseif roll == 3 then
		set text = "Until next time."
	elseif roll == 4 then
		set text = "Safe travels."
	else
		set text = "May your path be clear."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayFollow takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_FollowLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Follow me."
	elseif roll == 2 then
		set text = "Stay close."
	elseif roll == 3 then
		set text = "Come with me."
	elseif roll == 4 then
		set text = "Move out."
	else
		set text = "Let's go."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayStop takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_StopLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Stay here."
	elseif roll == 2 then
		set text = "Hold position."
	elseif roll == 3 then
		set text = "Wait here."
	elseif roll == 4 then
		set text = "Stand your ground."
	else
		set text = "Stay."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayDecline takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_DeclineLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "No."
	elseif roll == 2 then
		set text = "Not now."
	elseif roll == 3 then
		set text = "I cannot."
	elseif roll == 4 then
		set text = "I must decline."
	else
		set text = "Perhaps another time."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayAccept takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_AcceptLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "Yes."
	elseif roll == 2 then
		set text = "I accept."
	elseif roll == 3 then
		set text = "Consider it done."
	elseif roll == 4 then
		set text = "Very well."
	else
		set text = "Agreed."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

public function PlayInfo takes unit speaker, string speakerName, string overrideText, string overrideSoundKey returns nothing
	local integer roll
	local string text
	local string soundKey
	local string lookupName
	if overrideText != "" or overrideSoundKey != "" then
		set text = overrideText
		set soundKey = overrideSoundKey
		call PlayLine(speaker, speakerName, text, soundKey, true)
		return
	endif
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if PlayRegisteredLine(DialogSystem_InfoLines, speaker, lookupName) then
		return
	endif
	set roll = GetRandomInt(1, 5)
	if roll == 1 then
		set text = "What can you tell me about this?"
	elseif roll == 2 then
		set text = "Do you know anything about this?"
	elseif roll == 3 then
		set text = "What's your knowledge of this?"
	elseif roll == 4 then
		set text = "Can you explain what happened?"
	else
		set text = "Help me understand."
	endif
	set soundKey = ""
	call PlayLine(speaker, speakerName, text, soundKey, true)
endfunction

//===========================================================================
// Internal handler
//===========================================================================
// This function is called when any dialog button is clicked. It looks up the action and trigger associated with the button and executes it.
public function OnClicked takes nothing returns nothing
	local button b = GetClickedButton()
	local integer id = GetHandleId(b)
	local trigger t
	local integer lineAction

	set DialogSystem_LastButton = b
	set DialogSystem_LastAction = DialogButtonAction.integer[id]
	set DialogSystem_LastDialog = DialogButtonDialog.dialog[id]
	set lineAction = DialogButtonLineAction.integer[id]
	if lineAction != DIALOG_LINE_ACTION_NONE then
		if lineAction == DIALOG_LINE_ACTION_TRADE then
			call PlayTrade(DialogSystem_ActiveNPC, "", "", "")
		elseif lineAction == DIALOG_LINE_ACTION_EXIT then
			call PlayExit(DialogSystem_ActiveNPC, "", "", "")
		elseif lineAction == DIALOG_LINE_ACTION_FOLLOW then
			call PlayFollow(DialogSystem_ActiveNPC, "", "", "")
		elseif lineAction == DIALOG_LINE_ACTION_STOP then
			call PlayStop(DialogSystem_ActiveNPC, "", "", "")
		elseif lineAction == DIALOG_LINE_ACTION_DECLINE then
			call PlayDecline(DialogSystem_ActiveNPC, "", "", "")
		elseif lineAction == DIALOG_LINE_ACTION_ACCEPT then
			call PlayAccept(DialogSystem_ActiveNPC, "", "", "")
		endif
	endif

	set t = DialogButtonTrigger.trigger[id]
	if t != null then
		call TriggerExecute(t)
	endif
endfunction

// Creates a dialog with the specified title. Buttons can be added with DialogSystem_AddButton.
public function CreateDialog takes string title returns dialog
	local dialog d = DialogCreate()
	if DialogSystem_ClickTrigger == null then
		set DialogSystem_ClickTrigger = CreateTrigger()
		call TriggerAddAction(DialogSystem_ClickTrigger, function OnClicked)
	endif
	call TriggerRegisterDialogEvent(DialogSystem_ClickTrigger, d)
	call DialogSetMessage(d, title)
	return d
endfunction

//===========================================================================
// Init
//===========================================================================
private function Init takes nothing returns nothing
	set DialogButtonAction = Table.create()
	set DialogButtonTrigger = Table.create()
	set DialogButtonDialog = Table.create()
	set DialogButtonLineAction = Table.create()
	set DialogSequenceStore = Table.create()
	set DialogSystem_GreetLines = Table.create()
	set DialogSystem_FarewellLines = Table.create()
	set DialogSystem_TradeLines = Table.create()
	set DialogSystem_ExitLines = Table.create()
	set DialogSystem_FollowLines = Table.create()
	set DialogSystem_StopLines = Table.create()
	set DialogSystem_DeclineLines = Table.create()
	set DialogSystem_AcceptLines = Table.create()
	set DialogSystem_LookAtTimerUnit = Table.create()
	set DialogSystem_SkipTrigger = CreateTrigger()
	// Register ESC key for normal mode
	call BlzTriggerRegisterPlayerKeyEvent(DialogSystem_SkipTrigger, Player(0), OSKEY_ESCAPE, 0, true)
	// Register cinematic skip event for when EnableUserControl(false) is active
	call TriggerRegisterPlayerEvent(DialogSystem_SkipTrigger, Player(0), EVENT_PLAYER_END_CINEMATIC)
	call TriggerAddAction(DialogSystem_SkipTrigger, function OnSkipKey)
endfunction

//===========================================================================
// Get Registered Dialog Lines (without playing)
// Returns text/sound in DialogSystem_Picked* variables
//===========================================================================
private function GetRegisteredLine takes Table linesTable, string speakerName returns boolean
	local Table listTable
	local integer count
	local integer pick
	local integer base
	if linesTable == 0 or speakerName == "" then
		set DialogSystem_PickedText = ""
		set DialogSystem_PickedSound = ""
		set DialogSystem_PickedSoundAtUnit = false
		return false
	endif
	if not linesTable.has(StringHash(speakerName)) then
		set DialogSystem_PickedText = ""
		set DialogSystem_PickedSound = ""
		set DialogSystem_PickedSoundAtUnit = false
		return false
	endif
	set listTable = linesTable[StringHash(speakerName)]
	set count = listTable.integer[DIALOG_LIST_COUNT_KEY]
	if count <= 0 then
		set DialogSystem_PickedText = ""
		set DialogSystem_PickedSound = ""
		set DialogSystem_PickedSoundAtUnit = false
		return false
	endif
	set pick = GetRandomInt(1, count)
	set base = pick * 10
	set DialogSystem_PickedText = listTable.string[base + DIALOG_LIST_TEXT_KEY]
	set DialogSystem_PickedSound = listTable.string[base + DIALOG_LIST_SOUND_KEY]
	set DialogSystem_PickedSoundAtUnit = listTable.boolean[base + DIALOG_LIST_SOUND_AT_UNIT_KEY]
	if DialogSystem_PickedText == "" and DialogSystem_PickedSound == "" then
		return false
	endif
	return true
endfunction

public function PickAcceptLine takes unit speaker, string speakerName returns nothing
	local string lookupName
	set lookupName = speakerName
	if lookupName == "" and speaker != null then
		set lookupName = GetUnitDisplayName(speaker)
	endif
	if GetRegisteredLine(DialogSystem_AcceptLines, lookupName) then
		return
	endif
	set DialogSystem_PickedText = "I accept."
	set DialogSystem_PickedSound = ""
	set DialogSystem_PickedSoundAtUnit = false
endfunction

//===========================================================================
// Sequence Building Blocks - Facing and Looking Actions
//===========================================================================
// These functions add facing/looking actions as delay-only lines with automatic execution
// They combine the action with a delay, making sequences more readable and convenient

// Makes two units face each other
// If faceDuration <= 0, uses random duration for natural movement
// delay is the time to wait after initiating the facing action
public function AddMakeFaceEachOther takes integer seqId, unit unit1, unit unit2, real faceDuration, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	
	// Safety: validate sequence and units exist
	if seqTable == 0 then
		return 0
	endif
	if unit1 == null or unit2 == null then
		// Skip action if units are invalid
		return 0
	endif
	
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_FACE_EACH_OTHER
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = unit1
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT2_KEY] = unit2
	set seqTable.real[base + DIALOG_LINE_ACTION_DURATION_KEY] = faceDuration
	return index
endfunction

// Makes source unit face target unit
public function AddMakeUnitFaceUnit takes integer seqId, unit source, unit target, real faceDuration, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	
	// Safety: validate sequence and units exist
	if seqTable == 0 then
		return 0
	endif
	if source == null or target == null then
		// Skip action if units are invalid
		return 0
	endif
	
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_FACE_UNIT
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = source
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT2_KEY] = target
	set seqTable.real[base + DIALOG_LINE_ACTION_DURATION_KEY] = faceDuration
	return index
endfunction

// Makes source unit face a point
public function AddMakeUnitFacePoint takes integer seqId, unit source, real x, real y, real faceDuration, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	if seqTable == 0 then
		return 0
	endif
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_FACE_POINT
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = source
	set seqTable.real[base + DIALOG_LINE_ACTION_X_KEY] = x
	set seqTable.real[base + DIALOG_LINE_ACTION_Y_KEY] = y
	set seqTable.real[base + DIALOG_LINE_ACTION_DURATION_KEY] = faceDuration
	return index
endfunction

// Makes source unit look at target unit (with automatic facing adjustment)
// Uses default settings from DIALOGSYSTEM_LOOK_* constants
public function AddLookAtUnit takes integer seqId, unit source, unit target, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	
	// Safety: validate sequence and units exist (CRITICAL: prevents ACCESS_VIOLATION)
	if seqTable == 0 then
		return 0
	endif
	if source == null or target == null then
		// Skip action if units are invalid - storing null unit in Table causes crash
		return 0
	endif
	
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_LOOK_AT_UNIT
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = source
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT2_KEY] = target
	return index
endfunction

// Makes source unit look at a point (with automatic facing adjustment)
// Uses default settings from DIALOGSYSTEM_LOOK_* constants
public function AddLookAtPoint takes integer seqId, unit source, real x, real y, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	
	// Safety: validate sequence and unit exists
	if seqTable == 0 then
		return 0
	endif
	if source == null then
		// Skip action if unit is invalid
		return 0
	endif
	
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_LOOK_AT_POINT
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = source
	set seqTable.real[base + DIALOG_LINE_ACTION_X_KEY] = x
	set seqTable.real[base + DIALOG_LINE_ACTION_Y_KEY] = y
	return index
endfunction

// Resets unit look at (useful after AddLookAtUnit/AddLookAtPoint)
public function AddResetLookAt takes integer seqId, unit source, real delay returns integer
	local Table seqTable = DialogSequenceStore[seqId]
	local integer index
	local integer base
	
	// Safety: validate sequence and unit exists
	if seqTable == 0 then
		return 0
	endif
	if source == null then
		// Skip action if unit is invalid
		return 0
	endif
	
	set index = AddDelay(seqId, delay)
	set base = index * 10
	set seqTable.integer[base + DIALOG_LINE_ACTION_TYPE_KEY] = SEQ_ACTION_TYPE_RESET_LOOK_AT
	set seqTable.unit[base + DIALOG_LINE_ACTION_UNIT1_KEY] = source
	return index
endfunction

endlibrary
