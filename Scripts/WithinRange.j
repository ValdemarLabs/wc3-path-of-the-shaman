//UnitWithinRange 1.5
//	By Tasyen

//Allows to register specific Units to throw events when an unit enters a wanted range.
//Inside this Events you have access to the entered unit, the enteringUnit and the Range this was registered on.


//How UnitWithinRange works?
//UnitWithinRange generateds for any Unit Registered an own Trigger handling Unit comes in Range of x.
//By Connecting Unit/Trigger with Hashtabels under their HandleID
// All units using this are inside the Group udg_WithinRangeUsers.

//=========================================================================================================
// Event
//=========================================================================================================
// udg_WithinRangeEvent tells you what happens
	// udg_WithinRangeEvent = 1 	Enters
	// udg_WithinRangeEvent = -1 	AutoClean Cause of Death/Remove/Replaced of the registered Unit
	
// udg_WithinRangeUnit is the Unit who was Registered
// udg_WithinRangeEnteringUnit is the Unit who came in Range
// udg_WithinRangeRange is the Range under which this was registered (it is not the distance between 2 units, the distance function will bve from the center of each unit while the range detecions includes colisionsizes).

//=========================================================================================================
//Jass API
//=========================================================================================================
//	function RegisterUnitWithinRangeEvent takes unit u, real range, code filter, real eventValue returns boolean
//		- more simple usage of super: no trigger, destroyFilterWhenDone=true, cleanOnKilled = true
//	function RegisterUnitWithinRangeTrigger takes unit u, real range, code filter, trigger execution returns boolean
//		- more simple usage of super: no Event Thrown, destroyFilterWhenDone=true, cleanOnKilled = true
//	function RegisterUnitWithinRangeSuper takes unit u, real range, boolean cleanOnKilled, boolexpr filter, trigger execution, real eventValue, boolean destroyFilterWhenDone returns boolean
//		- inside the filter you can only access the entering Unit with GetTriggerUnit()
//		- Start the detection for this Unit with this range
//		- can not register twice the same range (main number 800.0 and 800.1 are now allowed) onto 1 unit.
//		- cleanOnKilled will generate an trigger which will execute DeRegisterUnitWithinRangeUnit as soon the unit dies.
//		- cleanOnKilled creates 1 Trigger for each Unit registered.
//	function RegisterUnitWithinRangeEx takes unit u, real range, boolean cleanOnKilled, boolexpr filter returns boolean
//		-backwards comptatible, wrapper for super
//	function RegisterUnitWithinRange takes unit u, real range, boolean cleanOnKilled returns boolean
//		-backwards comptatible, wrapper for super

//	function DeRegisterUnitWithinRange takes unit u, real range returns boolean
//		Destroys the range detection with this specific Range and Unit.

//	function DeRegisterUnitWithinRangeUnit takes unit u returns boolean
//		Destroys all Triggers used by the unit from UnitWithinRange.
//=========================================================================================================
//Hashtable Indexes:
//=========================================================================================================

// unitId
//	-1 = Auto Clean Trigger
//	0 = amount of range triggers used
//	1+ = Range-Detecion Triggers
//	range = index of the trigger controlling that range.

// trigId
//	-1 = TriggerAction (For remove usage)
//	0 = Registered Unit
//	0 = Range Detected
//	0 = destroyFilterWhenDone
//	1 = EventValue
//	1 = ExecutionTrigger
//	3 = filter (boolexpr)
//=========================================================================================================
//changes 1.5
//=========================================================================================================
// One can now choose the EventValue thrown.
// One can now choose a trigger beeing executed (including conditions) when a unit enters.
// ^^ included for GUI with Wanted_Event/Wanted_Trigger.
// The Filters are now supported by the GUI usage.
// Implemented Autodestorying of the filters, if the range detection ends .
//	RegisterUnitWithinRangeSuper allows you to choose, the others allways destory the filter.
//=========================================================================================================
constant function UnitWithinRangeDefaultEvent takes nothing returns real
	return 1.0
endfunction

//helper function destroys a trigger, its action, and clears the used table space.
function DestroyUnitWhithinTrigger takes trigger trig returns nothing
	local integer trigId = GetHandleId(trig)
	if LoadBoolean(udg_WithinRangeHash, trigId,0) then
		call DestroyBoolExpr(LoadBooleanExprHandle(udg_WithinRangeHash,trigId,3))
	endif
	call TriggerRemoveAction(trig, LoadTriggerActionHandle(udg_WithinRangeHash,trigId,-1))
	call FlushChildHashtable(udg_WithinRangeHash, trigId)
	call DestroyTrigger(trig)
endfunction

//Destroys all Triggers used by the unit from UnitWithinRange.
function DeRegisterUnitWithinRangeUnit takes unit u returns boolean
	local integer unitId = GetHandleId(u)
	local integer size = LoadInteger(udg_WithinRangeHash,unitId,0)
	local integer LoopA = 1
	//is there a cleanOnKilled Trigger?
	if LoadTriggerHandle(udg_WithinRangeHash,unitId,-1) != null then
		call DestroyUnitWhithinTrigger(LoadTriggerHandle(udg_WithinRangeHash,unitId,-1))
	endif
	loop 
		exitwhen LoopA > size
		call DestroyUnitWhithinTrigger(LoadTriggerHandle(udg_WithinRangeHash,unitId,LoopA))
		set LoopA = LoopA + 1
	endloop
	call FlushChildHashtable(udg_WithinRangeHash, unitId)
	call GroupRemoveUnit(udg_WithinRangeUsers, u)
	return true
endfunction

//Destroys the Trigger form this unit having this specific Range.
//Triggers are unique based on Range & Unit.
function DeRegisterUnitWithinRange takes unit u, real range returns boolean
	local trigger trig
	local integer trigId
	local integer unitId = GetHandleId(u)
	local integer size = LoadInteger(udg_WithinRangeHash,unitId,0)
	local integer rangeAsInt = R2I(range)
	local integer index
	//Range smaller equal 0 does not make sense, skip it or has nothing registered.
	if range <= 0 or size <= 0 or not HaveSavedInteger(udg_WithinRangeHash,unitId,rangeAsInt) then
		return false
	endif
	set index = LoadInteger(udg_WithinRangeHash,unitId,rangeAsInt)
	set trig = LoadTriggerHandle(udg_WithinRangeHash,unitId,index)
	set trigId = GetHandleId(trig)
	
	//destroy and clean it.
	call RemoveSavedInteger(udg_WithinRangeHash, unitId, rangeAsInt)
	call RemoveSavedHandle(udg_WithinRangeHash, unitId, index)
	call DestroyUnitWhithinTrigger(trig)
	
	//Redindex, when not last?
	if index != size then
		set trig =  LoadTriggerHandle(udg_WithinRangeHash, unitId, size)
		set trigId = GetHandleId(trig)
		call SaveTriggerHandle(udg_WithinRangeHash,unitId,index, trig )
		set rangeAsInt = R2I( LoadReal(udg_WithinRangeHash, trigId, 0) )
		call SaveInteger(udg_WithinRangeHash,unitId,rangeAsInt,index)
	endif
	
	set trig = null
	call SaveInteger(udg_WithinRangeHash,unitId,0,size - 1)
	//if the last trigger was removed, remove it from users.
	if size == 1 then
		//is there a cleanOnKilled Trigger?
		if LoadTriggerHandle(udg_WithinRangeHash,unitId,-1) != null then
			call RemoveSavedHandle(udg_WithinRangeHash, unitId, -1)
			call DestroyUnitWhithinTrigger(LoadTriggerHandle(udg_WithinRangeHash,unitId,-1))
		endif
		call GroupRemoveUnit(udg_WithinRangeUsers, u)
		call FlushChildHashtable(udg_WithinRangeHash, unitId)
	endif
	
	set trig = null
	return true
endfunction


//This is called when someone comes in Range.
function ActionUnitWithinRange takes nothing returns nothing
	local integer trigId = GetHandleId(GetTriggeringTrigger ())
	local real eventValue = LoadReal(udg_WithinRangeHash, trigId, 1)
	local trigger execution = LoadTriggerHandle(udg_WithinRangeHash, trigId, 1)
	set udg_WithinRangeUnit = LoadUnitHandle(udg_WithinRangeHash,trigId,0)
	set udg_WithinRangeEnteringUnit = GetTriggerUnit()
	set udg_WithinRangeRange = LoadReal(udg_WithinRangeHash, trigId, 0)
	if eventValue != 0.0 then
		set udg_WithinRangeEvent = eventValue
		set udg_WithinRangeEvent = 0.0
	endif
	if execution != null then
		call ConditionalTriggerExecute(execution)
	endif
	set execution = null
endfunction

//This Action is called on Death/Remove/Replaced, if wanted on creation.
// Will throw an -1 Event after the DeRegistering was done.
function ActionUnitWithinCleanOnKilled takes nothing returns nothing
	call DeRegisterUnitWithinRangeUnit (GetTriggerUnit())
	set udg_WithinRangeUnit = GetTriggerUnit()
	set udg_WithinRangeEvent = -1
	set udg_WithinRangeEvent = 0
endfunction

//Registers an Unit comes within Range around Unit event.
//Uses for each Unit a own Trigger.
//Each Range can only be registered one time on each unit
//if cleanOnKilled = true an Trigger will be generated, if not existing which will DeRegister as soon the unit dies.
function RegisterUnitWithinRangeSuper takes unit u, real range, boolean cleanOnKilled, boolexpr filter, trigger execution, real eventValue, boolean destroyFilterWhenDone returns boolean
	local trigger trig
	local integer trigId
	local integer unitId = GetHandleId(u)
	local integer size = LoadInteger(udg_WithinRangeHash,unitId,0)
	local integer rangeAsInt = R2I(range)
	//Range smaller equal 0 does not make sense, skip it.
	if range <= 0 then
		return false
	endif
	//is the cleanOnKilled Trigger already existing?
	if LoadTriggerHandle(udg_WithinRangeHash,unitId,-1) == null and cleanOnKilled then
		set trig = CreateTrigger()
		set trigId = GetHandleId(trig)
		call SaveTriggerHandle(udg_WithinRangeHash,unitId,-1,trig)
		call SaveTriggerActionHandle(udg_WithinRangeHash,trigId,-1, TriggerAddAction(trig, function ActionUnitWithinCleanOnKilled))

		// This will trigger if the unit is removed/killed
		call TriggerRegisterUnitStateEvent(trig, u, UNIT_STATE_LIFE, LESS_THAN_OR_EQUAL, 0.405)
		set trig = null
	endif
	//Was this Range already Registered?
	if HaveSavedInteger(udg_WithinRangeHash, unitId, rangeAsInt) then
		return false
	endif
	
	//New Unique Range for this unit; create an new Trigger handling this range.
	set trig = CreateTrigger()
	set trigId = GetHandleId(trig)
	set size = size + 1
	call SaveTriggerHandle(udg_WithinRangeHash,unitId,size,trig)
	call SaveUnitHandle(udg_WithinRangeHash,trigId,0,u)
	call SaveReal(udg_WithinRangeHash,trigId,0,range)
	call SaveTriggerActionHandle(udg_WithinRangeHash,trigId,-1, TriggerAddAction(trig, function ActionUnitWithinRange))
	call SaveInteger(udg_WithinRangeHash,unitId,0,size)
	call SaveInteger(udg_WithinRangeHash,unitId,rangeAsInt,size)
	call SaveBoolean(udg_WithinRangeHash,trigId,0,destroyFilterWhenDone)
	call SaveBooleanExprHandle(udg_WithinRangeHash,trigId,3,filter)
	call SaveTriggerHandle(udg_WithinRangeHash,trigId,1,execution)
	call SaveReal(udg_WithinRangeHash,trigId,1,eventValue)
	call TriggerRegisterUnitInRange(trig, u, range, filter)
	
	set trig = null
	call GroupAddUnit(udg_WithinRangeUsers, u)
	return true
endfunction
//Backwards compatible to 1.4
function RegisterUnitWithinRangeEx takes unit u, real range, boolexpr filter returns boolean
	return RegisterUnitWithinRangeSuper(u,range,true,filter, null, 1.0,true)
endfunction
//added 1.5
function RegisterUnitWithinRangeEvent takes unit u, real range, code filter, real eventValue returns boolean
	return RegisterUnitWithinRangeSuper(u,range,true,Condition(filter), null, eventValue, true)
endfunction
//added 1.5
function RegisterUnitWithinRangeTrigger takes unit u, real range, code filter, trigger execution returns boolean
	return RegisterUnitWithinRangeSuper(u,range,true, Condition(filter), execution, 0.0, true)
endfunction
//Backwards compatible to below 1.4
function RegisterUnitWithinRange takes unit u, real range, boolean cleanOnKilled returns boolean
	return RegisterUnitWithinRangeSuper(u,range,cleanOnKilled,null, null, 1.0,false)
endfunction

function WithinRangeGUIRegister takes nothing returns nothing
	call RegisterUnitWithinRangeSuper( udg_WithinRangeUnit, udg_WithinRangeRange, true, udg_WithinRangeWanted_Filter, udg_WithinRangeWanted_Trigger, udg_WithinRangeWanted_Event, true)
	if not udg_WithinRangeWanted_Keep then
		set udg_WithinRangeWanted_Trigger = null
		set udg_WithinRangeWanted_Event = UnitWithinRangeDefaultEvent()
		set udg_WithinRangeWanted_Filter = null
	endif	
endfunction

function WithinRangeGUIDeRegister takes nothing returns nothing
	//When called with Range 0 or below all Ranges will be removed.
	if udg_WithinRangeRange <= 0 then
		call DeRegisterUnitWithinRangeUnit( udg_WithinRangeUnit)
	else
		call DeRegisterUnitWithinRange( udg_WithinRangeUnit, udg_WithinRangeRange)
	endif
endfunction
//===========================================================================
function InitTrig_WithinRange takes nothing returns nothing
	set udg_WithinRangeHash = InitHashtable()
	set udg_WithinRangeWanted_Event = UnitWithinRangeDefaultEvent()
	set gg_trg_WithinRange = CreateTrigger()
	set udg_WithinRange__DeRegister = CreateTrigger()
	call TriggerAddAction(gg_trg_WithinRange, function WithinRangeGUIRegister)
	call TriggerAddAction(udg_WithinRange__DeRegister, function WithinRangeGUIDeRegister)
endfunction
