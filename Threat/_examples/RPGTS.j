library RPGTS initializer onInit uses GetClosestWidget, Table, UnitIndexer, optional TimerUtils

    /************************************************************************************
    *                                                                                   *
    *                           RPG Threat System v3.2c                                 *
    *                                         *****                                     *
    *                                       by: Quilnez                                 *
    *                                                                                   *
    *  This system generates special behavior to creep units. Gives some brains to        *
    *  those shrimp-head creeps. They can flee, they have artificial sight area            *
    *  (you can sneak behind them), they are able to help each other, they become        *
    *  aggressive or not aggressive as well. And many more!                             *
    *                                                                                   *
    *  External dependencies:                                                           *
    *   (required)                                                                      *
    *     - Table                                                                       *
    *     - UnitIndexer                                                                 *
    *     - GetClosestWidget                                                            *
    *     - Any DDS                                                                     *
    *   (optional)                                                                      *
    *     - TimerUtils                                                                  *
    *                                                                                   *
    *  Implementation:                                                                  *
    *     - Copy paste RPG Threat System folder into your map                            *
    *     - Give two player slots for passive and aggresive player, better just         *
    *       leave'em as empty player slot                                               *
    *     - Configure the system & start defining your creep behavior                    *
    *     - Done.                                                                       *
    *                                                                                   *
    *  Credits:                                                                         *
    *     - GDD by Weep                                                                 *
    *     - GetClosestWidget by Bannar                                                  *
    *     - UnitIndexer by Nestharus                                                    *
    *     - TimerUtils by Vexorian                                                      *
    *     - Table by Bribe                                                              *
    *                                                                                   *
    *   (You can read more info at READ ME trigger)                                     *
    *                                                                                   *
    *************************************************************************************
    *                                                                                   *
    *                                CONFIGURATION                                      */
    globals
        // Owner of passive creeps
        private constant    player      PASSIVE             = Player(10)
     
        // Owner of active creeps
        private constant    player      AGGRESSIVE          = Player(11)
     
        // If true, creeps will use PASSIVE's player color
        private constant    boolean     COLOR               = true
     
        // Behavior generation area (distance from generator units)
        private constant    real        DISTANCE            = 2400.0
     
        // Created sfx when creeps are sleeping
        private constant    string      SLEEP_SFX           = "Abilities\\Spells\\Undead\\Sleep\\SleepTarget.mdl"
        private constant    string      SLEEP_SFX_PT        = "overhead"
     
        // Order Ids
        private constant    integer     ATTACK_ORDER_ID     = 851983
        private constant    integer     MOVE_ORDER_ID       = 851986
        private constant    integer     STOP_ORDER_ID       = 851972
     
        // Total seconds in a day (can be found in gameplay constants)
        private constant    real        SECONDS_IN_A_DAY    = 480
     
        // If true, all units owned by PASSIVE and AGGRESSIVE will be
        // registered automatically on unit indexing event
        private constant    boolean     AUTO_REGISTER       = true
     
        // Just leave it alone
        private constant    real        INTERVAL            = 0.03125
     
        // Don't touch this
        private group CreepGroup = CreateGroup()
    endglobals
 
    // Damage event of your DDS
    private function addEvent takes trigger t returns nothing
        call TriggerRegisterVariableEvent(t, "udg_GDD_Event", EQUAL, 0.0)
    endfunction
 
    // Damage source of your DDS
    private constant function getSource takes nothing returns unit
        return udg_GDD_DamageSource
    endfunction
 
    // Damage target of your DDS
    private constant function getTarget takes nothing returns unit
        return udg_GDD_DamagedUnit
    endfunction
 
    // Set classifications of affected creeps
    private function creepFilter takes unit u returns boolean
 
        // For safety, just keep this format
        if IsUnitType(u, UNIT_TYPE_HERO) or IsUnitType(u, UNIT_TYPE_STRUCTURE) then
            return false
        endif
     
    /*                                END OF CONFIGURATION                              *
    *                                                                                   *
    ************************************************************************************/
 
        if IsUnitInGroup(u, CreepGroup) then
            return false
        endif
        call GroupAddUnit(CreepGroup, u)
     
        return true
    endfunction
 
    struct SCDataLib
        private static thistype Dex
        private static Table LibIndex
     
        //! textmacro CREEP_DATA_TYPE takes VAR_NAME,VAL_TYPE
        readonly $VAL_TYPE$ $VAR_NAME$Var
        static method operator $VAR_NAME$= takes $VAL_TYPE$ value returns nothing
            set Dex.$VAR_NAME$Var = value
        endmethod
     
        //! endtextmacro
        //! runtextmacro CREEP_DATA_TYPE( "maxHelp",         "integer" )
        //! runtextmacro CREEP_DATA_TYPE( "helpType",        "integer" )
        //! runtextmacro CREEP_DATA_TYPE( "resetTimer",      "boolean" )
        //! runtextmacro CREEP_DATA_TYPE( "canFlee",         "boolean" )
        //! runtextmacro CREEP_DATA_TYPE( "isTamed",         "boolean" )
        //! runtextmacro CREEP_DATA_TYPE( "seekHelp",        "boolean" )
        //! runtextmacro CREEP_DATA_TYPE( "callHelp",        "boolean" )
        //! runtextmacro CREEP_DATA_TYPE( "seekRadius",      "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "callRadius",      "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "sightRadius",     "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "sleepTime",       "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "sleepDur",        "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "lowHealth",       "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "acquisitionRange","real"    )
        //! runtextmacro CREEP_DATA_TYPE( "ambushDelay",     "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "combatDuration",  "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "wanderDelay",     "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "wanderVariant",   "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "wanderDist",      "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "fleeDist",        "real"    )
        //! runtextmacro CREEP_DATA_TYPE( "nestArea",        "real"    )
     
        static method getIndex takes integer unitId returns integer
            return LibIndex.integer[unitId]
        endmethod
     
        static method add takes integer unitId returns nothing
            if LibIndex.integer[unitId] == 0 then
                set Dex = allocate()
                set LibIndex.integer[unitId] = Dex
            endif
        endmethod
     
        static method end takes nothing returns nothing
            set Dex = 0
        endmethod
     
        static method onInit takes nothing returns nothing
            set LibIndex = Table.create()
        endmethod
    endstruct
 
    // Container for creep data
    private struct CreepData
 
        boolean isSleep
        integer helpCount
        effect  sleepSfx
     
        unit    target
        timer   sleepTimer
        real    wanderDelay
     
        real    nestX
        real    nestY
        real    combatDur
     
        real    combatDly
        real    unitX
        real    unitY
     
    endstruct
 
    globals
        private boolean Move          = false
        private group PickGroup       = CreateGroup()
        private group TempGroup       = CreateGroup()
        private integer DummyType
        private integer Total         = -1
        private integer GenTotal      = 0
        private integer array GenDex
        private real array Real
        private timer Timer           = CreateTimer()
        private trigger array Handler
        private unit TempUnit
        private unit EventUnit        = null
        private unit EventThreat      = null
        private unit array GenUnit
        private CreepData array Data
     
        // Real array indexes
        private constant integer R_X             = 0
        private constant integer R_Y             = 1
        private constant integer R_TOD           = 2
        private constant integer R_WAKE          = 3
        private constant integer R_DISTANCE      = 4
        private constant integer R_FACING        = 5
        private constant integer R_DURATION      = 6
     
        // Event constants
        constant integer EVENT_CREEP_SLEEP       = 0
        constant integer EVENT_CREEP_AWAKE       = 1
        constant integer EVENT_CREEP_WANDER      = 2
        constant integer EVENT_CREEP_FLEE        = 3
        constant integer EVENT_CREEP_THREAT      = 4
        constant integer EVENT_CREEP_UNTHREAT    = 5
        constant integer EVENT_CREEP_ATTACK      = 6
        constant integer EVENT_CREEP_CALL_HELP   = 7
        constant integer EVENT_CREEP_SEEK_HELP   = 8
        constant integer EVENT_CREEP_GIVE_HELP   = 9
        constant integer EVENT_CREEP_LOW_HEALTH  = 10
        constant integer EVENT_CREEP_DEAL_DAMAGE = 11
        constant integer EVENT_CREEP_TAKE_DAMAGE = 12
        constant integer EVENT_CREEP_UNATTACK    = 13
    endglobals
 
    native UnitAlive takes unit id returns boolean
 
    // API functions
    function SetGenUnit takes unit u, boolean b returns nothing
 
        local integer uDex = GetUnitUserData(u)
 
        if b then
            if GenDex[uDex] == 0 then
                set GenTotal = GenTotal + 1
                set GenUnit[GenTotal] = u
                set GenDex[uDex] = GenTotal
            endif
        elseif GenDex[uDex] > 0 then
            set GenDex[GetUnitUserData(GenUnit[GenTotal])] = GenDex[uDex]
            set GenUnit[GenDex[uDex]] = GenUnit[GenTotal]
            set GenUnit[GenTotal] = null
            set GenTotal = GenTotal - 1
            set GenDex[uDex] = 0
        endif
     
    endfunction
 
    function AddCreepEventHandler takes integer whichEvent, boolexpr func returns nothing
        call TriggerAddCondition(Handler[whichEvent], func)
    endfunction
 
    function GetTriggerCreep takes nothing returns unit
        return EventUnit
    endfunction
 
    function GetTriggerThreat takes nothing returns unit
        return EventThreat
    endfunction
 
    function GetCreepNestX takes unit u returns real
        return Data[GetUnitUserData(u)].nestX
    endfunction
 
    function GetCreepNestY takes unit u returns real
        return Data[GetUnitUserData(u)].nestY
    endfunction
 
    function IsCreepSleeping takes unit u returns boolean
        return Data[GetUnitUserData(u)].isSleep
    endfunction
 
    function IsCreepMoving takes unit u returns boolean
        local integer uDex = GetUnitUserData(u)
        return GetUnitCurrentOrder(u) == MOVE_ORDER_ID or GetUnitX(u) != Data[uDex].unitX or GetUnitY(u) != Data[uDex].unitY
    endfunction
 
    // Get distance between points
    private function getDistance takes real x, real y, real xt, real yt returns real
        return SquareRoot((xt-x)*(xt-x)+(yt-y)*(yt-y))
    endfunction
 
    // Get angle between points
    private function getAngle takes real x, real y, real xt, real yt returns real
        return Atan2(yt-y, xt-x) * bj_RADTODEG
    endfunction
 
    // Get circular difference between two angles
    private function circularDifference takes real a, real b returns real
 
        local real r = RAbsBJ(a-b)
     
        if r <= 180 then
            return r
        else
            return 180 - r
        endif
     
    endfunction
 
    // Filter enemy units around creep
    private function targetFilter takes nothing returns boolean
 
        local unit u       = GetFilterUnit()
        local player p     = GetOwningPlayer(u)
        local SCDataLib lDex = SCDataLib.getIndex(GetUnitTypeId(TempUnit))
        local real a       = getAngle(GetUnitX(TempUnit), GetUnitY(TempUnit), GetUnitX(u), GetUnitY(u))
        local boolean b    = circularDifference(GetUnitFacing(TempUnit), a) < lDex.sightRadiusVar/4
     
        set b = b and (p != PASSIVE and p != AGGRESSIVE and UnitAlive(u))
        set b = b and (IsUnitVisible(u, PASSIVE) or IsUnitVisible(u, AGGRESSIVE))
        set u = null
     
        return b
    endfunction
 
    // Filter possible helper for creep
    private function helperFilter takes nothing returns boolean
 
        local unit    u    = GetFilterUnit()
        local integer id   = GetUnitTypeId(u)
        local integer uDex = GetUnitUserData(u)
        local SCDataLib lDex = SCDataLib.getIndex(id)
        local boolean b    = (lDex.helpTypeVar != 1 or id == DummyType) and lDex.helpTypeVar >= 1
     
        set b = b and (GetOwningPlayer(u) == PASSIVE and not lDex.isTamedVar)
        set b = b and not IsCreepSleeping(u)
        set u = null
     
        return b
    endfunction
 
    private function fireEvent takes integer whichEvent, unit u, unit t returns nothing
     
        local unit tu   = EventUnit
        local unit tt   = EventThreat
     
        set EventUnit   = u
        set EventThreat = t
     
        call TriggerEvaluate(Handler[whichEvent])
     
        set EventUnit   = tu
        set EventThreat = tt
     
        set tu = null
        set tt = null
     
    endfunction
 
    // Seek for nearby helpers
    private function pickHelper takes unit u, unit t, integer uDex, SCDataLib lDex returns nothing
     
        local integer i = 0
        local SCDataLib lDex2
        local integer uDex2
        local unit h
     
        loop
            exitwhen Data[uDex].helpCount == lDex.maxHelpVar
            set h = GetClosestUnitInRange(Data[uDex].unitX, Data[uDex].unitY, lDex.callRadiusVar, Filter(function helperFilter))
            exitwhen h == null
         
            call SetUnitOwner(h, AGGRESSIVE, not COLOR)
            set uDex2 = GetUnitUserData(h)
            set lDex2 = SCDataLib.getIndex(GetUnitTypeId(h))
         
            set Data[uDex2].combatDur = lDex2.combatDurationVar
            set Data[uDex2].target    = t
         
            call IssueTargetOrderById(h, ATTACK_ORDER_ID, t)
            call fireEvent(EVENT_CREEP_GIVE_HELP, h, null)
            set Data[uDex].helpCount = Data[uDex].helpCount + 1
        endloop
        set h = null
     
    endfunction
 
    // Filter creeps around generators
    private function pickFilter takes nothing returns boolean
     
        local unit u = GetFilterUnit()
     
        if not IsUnitInGroup(u, PickGroup) and IsUnitInGroup(u, CreepGroup) then
            call GroupAddUnit(PickGroup, u)
        endif
        set u = null
     
        return false
    endfunction
 
    private function onLoop takes nothing returns nothing
 
        local unit u
        local unit t
        local SCDataLib lDex
        local integer uDex
        local integer i = 1
     
        // Collect creeps around generator units' positions
        loop
            exitwhen i > GenTotal
            call GroupEnumUnitsInRange(TempGroup, GetUnitX(GenUnit[i]), GetUnitY(GenUnit[i]), DISTANCE, function pickFilter)
            set i = i + 1
        endloop
     
        loop
            set u = FirstOfGroup(PickGroup)
            exitwhen u == null
            call GroupRemoveUnit(PickGroup, u)
         
            set uDex = GetUnitUserData(u)
            if GetUnitTypeId(u) != 0 then
                if UnitAlive(u) then
                    set lDex = SCDataLib.getIndex(GetUnitTypeId(u))
                    // Determine whether the creep is moving atm or not
                    set Move = IsCreepMoving(u)
                    if Move then
                        set Data[uDex].unitX = GetUnitX(u)
                        set Data[uDex].unitY = GetUnitY(u)
                    endif
                 
                    if GetOwningPlayer(u) == PASSIVE then
                        if Data[uDex].combatDly < 0 then
                            // If the creep is able to sleep
                            if lDex.sleepDurVar > 0 then
                                // Gather sleep time datas
                                set Real[R_TOD]  = GetFloatGameState(GAME_STATE_TIME_OF_DAY)
                                set Real[R_WAKE] = lDex.sleepTimeVar + lDex.sleepDurVar
                                if  Real[R_TOD] <= Real[R_WAKE] - 24 then
                                    set Real[R_TOD] = Real[R_TOD] + 24
                                endif
                             
                                // Check sleep time
                                if Real[R_TOD] >= lDex.sleepTimeVar and Real[R_TOD] < Real[R_WAKE] and not Data[uDex].isSleep then
                                    if not Move and not(IsUnitType(u, UNIT_TYPE_STUNNED) or IsUnitPaused(u)) then
                                        set Data[uDex].isSleep  = true
                                        set Data[uDex].sleepSfx = AddSpecialEffectTarget(SLEEP_SFX, u, SLEEP_SFX_PT)
                                        if Data[uDex].sleepTimer == null then
                                            static if LIBRARY_TimerUtils then
                                                set Data[uDex].sleepTimer = NewTimer()
                                            else
                                                set Data[uDex].sleepTimer = CreateTimer()
                                            endif
                                            // Calculate sleep duration
                                            set Real[R_DURATION] = (SECONDS_IN_A_DAY/86400)*((lDex.sleepDurVar-(Real[R_TOD]-lDex.sleepTimeVar))*3600)/GetTimeOfDayScale()
                                            call TimerStart(Data[uDex].sleepTimer, Real[R_DURATION], false, null)
                                        endif
                                        call fireEvent(EVENT_CREEP_SLEEP, u, null)
                                    endif
                                endif
                            endif
                         
                            if Data[uDex].isSleep then
                                // Wake up time
                                if TimerGetRemaining(Data[uDex].sleepTimer) <= 0 then
                                    call DestroyEffect(Data[uDex].sleepSfx)
                                    static if LIBRARY_TimerUtils then
                                        call ReleaseTimer(Data[uDex].sleepTimer)
                                    else
                                        call DestroyTimer(Data[uDex].sleepTimer)
                                    endif
                                 
                                    set Data[uDex].isSleep    = false
                                    set Data[uDex].sleepTimer = null
                                    set Data[uDex].sleepSfx   = null
                                 
                                    call fireEvent(EVENT_CREEP_AWAKE, u, null)
                                endif
                            else
                                // Check if wandering or not
                                if lDex.wanderDelayVar > 0 then
                                    if Data[uDex].wanderDelay > INTERVAL then
                                        set Data[uDex].wanderDelay = Data[uDex].wanderDelay - INTERVAL
                                    else
                                        set Real[R_DISTANCE] = GetRandomReal(lDex.wanderDistVar, lDex.nestAreaVar)
                                        set Real[R_FACING]   = GetRandomReal(0,bj_PI*2)
                                     
                                        // Reset wander delay
                                        set Data[uDex].wanderDelay = lDex.wanderDelayVar + GetRandomReal(-lDex.wanderVariantVar, lDex.wanderVariantVar)/2
                                     
                                        set Real[R_X] = Data[uDex].nestX + Real[R_DISTANCE] * Cos(Real[R_FACING])
                                        set Real[R_Y] = Data[uDex].nestY + Real[R_DISTANCE] * Sin(Real[R_FACING])
                                     
                                        call IssuePointOrderById(u, MOVE_ORDER_ID, Real[R_X], Real[R_Y])
                                        call fireEvent(EVENT_CREEP_WANDER, u, null)
                                    endif
                                endif
                             
                                // If the creep is aggressive
                                if lDex.acquisitionRangeVar > 0 then
                                    // If is around it's nest area
                                    if getDistance(Data[uDex].unitX, Data[uDex].unitY, Data[uDex].nestX, Data[uDex].nestY) <= lDex.nestAreaVar then
                                        set TempUnit = u
                                        set t = GetClosestUnitInRange(Data[uDex].unitX, Data[uDex].unitY, lDex.acquisitionRangeVar, Filter(function targetFilter))
                                        if t != null then
                                            set Data[uDex].target    = t
                                            set Data[uDex].combatDly = lDex.ambushDelayVar
                                            call IssueImmediateOrderById(u, STOP_ORDER_ID)
                                            call fireEvent(EVENT_CREEP_THREAT, u, t)
                                            set t = null
                                        endif
                                    endif
                                endif
                            endif
                        else
                            set Real[R_X] = GetUnitX(Data[uDex].target)
                            set Real[R_Y] = GetUnitY(Data[uDex].target)
                            call SetUnitFacing(u, getAngle(Data[uDex].unitX, Data[uDex].unitY, Real[R_X], Real[R_Y]))
                         
                            // If target has fleed
                            if getDistance(Data[uDex].unitX, Data[uDex].unitY, Real[R_X], Real[R_Y]) > lDex.acquisitionRangeVar then
                                set Data[uDex].combatDly = -1
                                set Data[uDex].target    = null
                                call fireEvent(EVENT_CREEP_UNTHREAT, u, Data[uDex].target)
                            else
                                if Data[uDex].combatDly > INTERVAL then
                                    set Data[uDex].combatDly = Data[uDex].combatDly - INTERVAL
                                else
                                    set Data[uDex].combatDur = lDex.combatDurationVar
                                    call SetUnitOwner(u, AGGRESSIVE, not COLOR)
                                    call IssueTargetOrderById(u, ATTACK_ORDER_ID, Data[uDex].target)
                                    call fireEvent(EVENT_CREEP_ATTACK, u, Data[uDex].target)
                                endif
                            endif
                        endif
                    else
                        // Calm down if the combat timer is up or if the target has died
                        if Data[uDex].combatDur > INTERVAL and UnitAlive(Data[uDex].target) then
                            set Data[uDex].combatDur = Data[uDex].combatDur - INTERVAL
                        else
                            call SetUnitOwner(u, PASSIVE, not COLOR)
                            set Data[uDex].helpCount = 0
                         
                            // Order to move away
                            set Real[R_DISTANCE] = GetRandomReal(0, lDex.nestAreaVar)
                            set Real[R_FACING]   = GetRandomReal(0, bj_PI*2)
                         
                            set Real[R_X] = Data[uDex].nestX + Real[R_DISTANCE] * Cos(Real[R_FACING])
                            set Real[R_Y] = Data[uDex].nestY + Real[R_DISTANCE] * Sin(Real[R_FACING])
                         
                            call IssuePointOrderById(u, MOVE_ORDER_ID, Real[R_X], Real[R_Y])
                            call fireEvent(EVENT_CREEP_UNATTACK, u, Data[uDex].target)
                            set Data[uDex].target = null
                        endif
                    endif
                endif
            else
                call Data[uDex].destroy()
                set  Data[uDex].sleepTimer = null
                set  Data[uDex].sleepSfx   = null
                set  Data[uDex].target     = null
     
                set Total = Total - 1
                if Total < 0 then
                    call PauseTimer(Timer)
                endif
            endif
        endloop
     
    endfunction

    private function onHit takes nothing returns boolean
 
        local SCDataLib lDex
        local integer uDex
        local integer i
        local integer ix
        local unit t = getTarget()
        local unit s = getSource()
        local unit h
     
        if GetOwningPlayer(s) == AGGRESSIVE and IsUnitInGroup(s, CreepGroup) then
            set DummyType = GetUnitTypeId(s)
            set uDex = GetUnitUserData(s)
            set lDex = SCDataLib.getIndex(DummyType)
            call fireEvent(EVENT_CREEP_DEAL_DAMAGE, s, t)
         
            if lDex.resetTimerVar then
                if getDistance(Data[uDex].unitX, Data[uDex].unitY, Data[uDex].nestX, Data[uDex].nestY) <= lDex.nestAreaVar then
                    set Data[uDex].combatDur = lDex.combatDurationVar
                endif
            endif
         
            // If call for help when attacking
            if lDex.maxHelpVar > 0 and lDex.callHelpVar then
                call pickHelper(s, t, uDex, lDex)
                call fireEvent(EVENT_CREEP_CALL_HELP, s, null)
            endif
         
        elseif IsUnitInGroup(t, CreepGroup) then
            set DummyType = GetUnitTypeId(t)
            set uDex = GetUnitUserData(t)
            set lDex = SCDataLib.getIndex(DummyType)
            set Data[uDex].combatDur = lDex.combatDurationVar
            call fireEvent(EVENT_CREEP_TAKE_DAMAGE, t, s)
         
            // If the creep is currently sleeping
            if Data[uDex].isSleep then
                call DestroyEffect(Data[uDex].sleepSfx)
                set Data[uDex].sleepSfx = null
                set Data[uDex].isSleep  = false
                call fireEvent(EVENT_CREEP_AWAKE, t, null)
            endif
         
            if lDex.canFleeVar and lDex.fleeDistVar > 0 then
                // If still around it's nest area
                if getDistance(Data[uDex].unitX, Data[uDex].unitY, Data[uDex].nestX, Data[uDex].nestY) < lDex.nestAreaVar then
                    set Real[R_FACING] = getAngle(GetUnitX(s), GetUnitY(s), Data[uDex].unitX, Data[uDex].unitY) * bj_DEGTORAD
                    set Real[R_X] = Data[uDex].unitX + lDex.fleeDistVar * Cos(Real[R_FACING])
                    set Real[R_Y] = Data[uDex].unitY + lDex.fleeDistVar * Sin(Real[R_FACING])
                else
                    set Real[R_FACING] = GetRandomReal(0, bj_PI*2)
                    set Real[R_X] = Data[uDex].nestX + lDex.fleeDistVar * Cos(Real[R_FACING])
                    set Real[R_Y] = Data[uDex].nestY + lDex.fleeDistVar * Sin(Real[R_FACING])
                endif
                call IssuePointOrderById(t, MOVE_ORDER_ID, Real[R_X], Real[R_Y])
                call fireEvent(EVENT_CREEP_FLEE, t, null)
            endif
         
            if GetOwningPlayer(t) == PASSIVE then
                set Data[uDex].target = s
                // If not tamed
                if not lDex.isTamedVar then
                    call SetUnitOwner(t, AGGRESSIVE, not COLOR)
                    call IssueTargetOrderById(t, ATTACK_ORDER_ID, s)
                endif
             
                if lDex.maxHelpVar > 0 then
                    call pickHelper(t, s, uDex, lDex)
                    call fireEvent(EVENT_CREEP_CALL_HELP, t, s)
                endif
            endif
         
            if GetWidgetLife(t) <= lDex.lowHealthVar then
                call fireEvent(EVENT_CREEP_LOW_HEALTH, t, null)
                // If able to seek help
                if lDex.seekHelpVar and lDex.maxHelpVar > 0 then
                    set h = GetClosestUnitInRange(Data[uDex].unitX,Data[uDex].unitY,lDex.seekRadiusVar,Filter(function helperFilter))
                    // Order to move to helper's position
                    if h != null then
                        call IssuePointOrderById(t, MOVE_ORDER_ID, GetUnitX(h), GetUnitY(h))
                        set h = null
                    endif
                    call fireEvent(EVENT_CREEP_SEEK_HELP, t, null)
                endif
            endif
        endif
        set t = null
        set s = null
     
        return false
    endfunction
 
    private function onDeath takes nothing returns boolean
     
        local integer uDex
        local SCDataLib lDex
        local player  p = GetTriggerPlayer()
        local unit u
     
        if p == PASSIVE or p == AGGRESSIVE then
            set u    = GetTriggerUnit()
            set uDex = GetUnitUserData(u)
            set lDex = SCDataLib.getIndex(GetUnitTypeId(u))
         
            call SetUnitOwner(u, PASSIVE, not COLOR)
            set Data[uDex].wanderDelay = lDex.wanderDelayVar + GetRandomReal(-lDex.wanderVariantVar, lDex.wanderVariantVar)/2
            set Data[uDex].combatDur   = -1
         
            set Data[uDex].combatDly   = -1
            set Data[uDex].helpCount   = 0
            set Data[uDex].isSleep     = false
         
            set u = null
        endif
     
        return false
    endfunction

    function EnableCreepBehavior takes unit u, boolean b returns nothing
 
        local SCDataLib lDex
        local integer uDex
        local player p = GetOwningPlayer(u)
     
        if b then
            if p == PASSIVE or p == AGGRESSIVE then
                if p == AGGRESSIVE then
                    call SetUnitOwner(u, PASSIVE, false)
                    static if COLOR then
                        call SetUnitColor(u, GetPlayerColor(PASSIVE))
                    endif
                else
                    static if not COLOR then
                        call SetUnitColor(u, GetPlayerColor(AGGRESSIVE))
                    endif
                endif
             
                if creepFilter(u) then
                    set Total = Total + 1
                    set uDex  = GetUnitUserData(u)
                    set lDex  = SCDataLib.getIndex(GetUnitTypeId(u))
                 
                    set Data[uDex] = CreepData.create()
                    set Data[uDex].helpCount = 0
                    set Data[uDex].isSleep   = false
                 
                    set Data[uDex].wanderDelay = GetRandomReal(0, lDex.wanderDelayVar)
                    set Data[uDex].nestX = GetUnitX(u)
                    set Data[uDex].nestY = GetUnitY(u)
                 
                    set Data[uDex].combatDly = -1
                    set Data[uDex].unitX = 0
                    set Data[uDex].unitY = 0
                 
                    if Total == 0 then
                        call TimerStart(Timer, INTERVAL, true, function onLoop)
                    endif
                endif
            endif
        elseif IsUnitInGroup(u, CreepGroup) then
            call GroupRemoveUnit(CreepGroup, u)
        endif
     
    endfunction

    private function onIndex takes nothing returns boolean
        call EnableCreepBehavior(GetIndexedUnit(), true)
        return false
    endfunction

    private function setAlliance takes nothing returns nothing
 
        local player p = GetEnumPlayer()
     
        if p != PASSIVE and p != AGGRESSIVE then
            // Aggressive player threats others as enemies
            call SetPlayerAlliance(AGGRESSIVE, p, ALLIANCE_PASSIVE, false)
            // Passive player threats other players as allies
            call SetPlayerAlliance(PASSIVE, p, ALLIANCE_PASSIVE, true)
        endif
     
    endfunction

    private function onInit takes nothing returns nothing
 
        local player  p  = GetLocalPlayer()
        local trigger t1 = CreateTrigger()
        local trigger t2 = CreateTrigger()
     
        static if AUTO_REGISTER then
            call RegisterUnitIndexEvent(Condition(function onIndex), UnitIndexer.INDEX)
        endif
     
        call addEvent(t1)
        call TriggerAddCondition(t1, Condition(function onHit))
     
        call TriggerRegisterAnyUnitEventBJ(t2, EVENT_PLAYER_UNIT_DEATH)
        call TriggerAddCondition(t2, Condition(function onDeath))
     
        // Alliance setting
        call SetPlayerAlliance(PASSIVE, AGGRESSIVE, ALLIANCE_PASSIVE, true)
        call SetPlayerAlliance(AGGRESSIVE, PASSIVE, ALLIANCE_PASSIVE, true)
        call ForForce(bj_FORCE_ALL_PLAYERS, function setAlliance)
     
        // Give global sight for both player
        if p == AGGRESSIVE or p == PASSIVE then
            call FogEnable(false)
            call FogMaskEnable(false)
        endif
     
        set t1 = null
        set t2 = null
     
    endfunction
 
endlibrary