library MouseUtils
static if not USE_MEMORY_HACK then
/*
    -------------------
        MouseUtils
         - MyPad
        
         1.0.2.0
    -------------------
   
    ----------------------------------------------------------------------------
        A simple snippet that allows one to
        conveniently use the mouse natives
        as they were meant to be...
       
     -------------------
    |    API            |
     -------------------
   
        struct UserMouse extends array
            static method operator [] (player p) -> thistype
                - Returns the player's id + 1
               
            static method getCurEventType() -> integer
                - Returns the custom event that got executed.
               
            method operator player -> player
                - Returns Player(this - 1)
               
            readonly real mouseX
            readonly real mouseY
                - Returns the current mouse coordinates.
               
            readonly method operator isMouseClicked -> boolean
                - Determines whether any mouse key has been clicked,
                  and will return true on the first mouse key.
                 
            method isMouseButtonClicked(mousebuttontype mouseButton)
                - Returns true if the mouse button hasn't been
                  released yet.
                 
            static method registerCode(code c, integer ev) -> triggercondition
                - Lets code run upon the execution of a certain event.
                - Returns a triggercondition that can be removed later.
               
            static method unregisterCallback(triggercondition trgHndl, integer ev)
                - Removes a generated triggercondition from the trigger.
               
        functions:
            GetPlayerMouseX(player p) -> real
            GetPlayerMouseY(player p) -> real
                - Returns the coordinates of the mouse of the player.
               
            OnMouseEvent(code func, integer eventId) -> triggercondition
                - See UserMouse.registerCode
               
            GetMouseEventType() -> integer
                - See UserMouse.getCurEventType
               
            UnregisterMouseCallback(triggercondition t, integer eventId)
                - See UserMouse.unregisterCallback
               
     -------------------
    |    Credits        |
     -------------------
    
        -   Pyrogasm for pointing out a comparison logic flaw
            in operator isMouseClicked.
           
        -   Illidan(Evil)X for the useful enum handles that
            grant more functionality to this snippet.
       
        -   TriggerHappy for the suggestion to include
            associated events and callbacks to this snippet.
           
    ----------------------------------------------------------------------------
*/
//  Arbitrary constants
globals
    constant integer EVENT_MOUSE_UP     = 1024
    constant integer EVENT_MOUSE_DOWN   = 2048
    constant integer EVENT_MOUSE_MOVE   = 3072
endglobals
private module Init
    private static method onInit takes nothing returns nothing
        call thistype.init()
    endmethod
endmodule
struct UserMouse extends array
    //  Determines the minimum interval that a mouse move event detector
    //  will be deactivated. (Globally-based)
    //  You can configure it to any amount you like.
    private static constant real INTERVAL           = 0.03125
   
    //  Determines how many times a mouse move event detector can fire
    //  before being deactivated. (locally-based)
    //  You can configure this to any integer value. (Preferably positive)
    private static constant integer MOUSE_COUNT_MAX = 16
   
    private static integer currentEventType         = 0
    private static integer updateCount              = 0
    private static timer resetTimer                 = null
    private static trigger stateDetector            = null
   
    private static trigger array evTrigger
   
    private static integer array mouseButtonStack
   
    private integer  mouseEventCount
   
    private thistype next
    private thistype prev
   
    private thistype resetNext
    private thistype resetPrev
    private trigger posDetector
    private integer mouseClickCount
   
    readonly real mouseX
    readonly real mouseY
   
    //  Converts the enum type mousebuttontype into an integer
    private static method toIndex takes mousebuttontype mouseButton returns integer
        return GetHandleId(mouseButton)
    endmethod
   
    static method getCurEventType takes nothing returns integer
        return currentEventType
    endmethod
   
    static method operator [] takes player p returns thistype
        if thistype(GetPlayerId(p) + 1).posDetector != null then
            return GetPlayerId(p) + 1
        endif
        return 0
    endmethod
       
    method operator player takes nothing returns player
        return Player(this - 1)
    endmethod
    method operator isMouseClicked takes nothing returns boolean
        return .mouseClickCount > 0
    endmethod
   
    method isMouseButtonClicked takes mousebuttontype mouseButton returns boolean
        return UserMouse.mouseButtonStack[(this - 1)*3 + UserMouse.toIndex(mouseButton)] > 0
    endmethod
    private static method onMouseUpdateListener takes nothing returns nothing
        local thistype this = thistype(0).resetNext
        set updateCount     = 0
       
        loop
            exitwhen this == 0
            set updateCount = updateCount + 1
                       
            set this.mouseEventCount = 0
            call EnableTrigger(this.posDetector)
           
            set this.resetNext.resetPrev = this.resetPrev
            set this.resetPrev.resetNext = this.resetNext
           
            set this                     = this.resetNext
        endloop
        if updateCount <= 0 then
            call PauseTimer(resetTimer)
        endif
    endmethod
   
    private static method onMouseUpOrDown takes nothing returns nothing
        local thistype this = thistype[GetTriggerPlayer()]
        local integer index = (this - 1)*3 + UserMouse.toIndex(BlzGetTriggerPlayerMouseButton())
        if GetTriggerEventId() == EVENT_PLAYER_MOUSE_DOWN then
            set this.mouseClickCount    = this.mouseClickCount + 1
            set UserMouse.mouseButtonStack[index]  = UserMouse.mouseButtonStack[index] + 1
          
            set currentEventType = EVENT_MOUSE_DOWN
            call TriggerEvaluate(evTrigger[EVENT_MOUSE_DOWN])
        else       
            set this.mouseClickCount = IMaxBJ(this.mouseClickCount - 1, 0)
            set UserMouse.mouseButtonStack[index]  = IMaxBJ(UserMouse.mouseButtonStack[index] - 1, 0)
            set currentEventType = EVENT_MOUSE_UP
            call TriggerEvaluate(evTrigger[EVENT_MOUSE_UP])
        endif
    endmethod
   
    private static method onMouseMove takes nothing returns nothing
        local thistype this = thistype[GetTriggerPlayer()]
	local real x = BlzGetTriggerPlayerMouseX()
	local real y = BlzGetTriggerPlayerMouseY()
               
	if x != 0 or y != 0 then
        	set this.mouseX     = x
        	set this.mouseY     = y
	endif
               
        set this.mouseEventCount = this.mouseEventCount + 1
        set currentEventType = EVENT_MOUSE_MOVE
        call TriggerEvaluate(evTrigger[EVENT_MOUSE_MOVE])
        if this.mouseEventCount >= thistype.MOUSE_COUNT_MAX then
            call DisableTrigger(this.posDetector)                 
       
            if thistype(0).resetNext == 0 then
                call TimerStart(resetTimer, INTERVAL, true, function thistype.onMouseUpdateListener)
            endif
           
            set this.resetNext              = 0
            set this.resetPrev              = this.resetNext.resetPrev
            set this.resetPrev.resetNext    = this
            set this.resetNext.resetPrev    = this 
        endif
    endmethod
       
    private static method init takes nothing returns nothing
        local thistype this = 1
        local player p      = this.player
       
        set resetTimer      = CreateTimer()
        set stateDetector   = CreateTrigger()
       
        set evTrigger[EVENT_MOUSE_UP]   = CreateTrigger()
        set evTrigger[EVENT_MOUSE_DOWN] = CreateTrigger()
        set evTrigger[EVENT_MOUSE_MOVE] = CreateTrigger()
       
        call TriggerAddCondition( stateDetector, Condition(function thistype.onMouseUpOrDown))
        loop
            exitwhen integer(this) > bj_MAX_PLAYER_SLOTS
           
            if GetPlayerController(p) == MAP_CONTROL_USER and GetPlayerSlotState(p) == PLAYER_SLOT_STATE_PLAYING then
                set this.next             = 0
                set this.prev             = thistype(0).prev
                set thistype(0).prev.next = this
                set thistype(0).prev      = this
               
                set this.posDetector         = CreateTrigger()
                call TriggerRegisterPlayerEvent( this.posDetector, p, EVENT_PLAYER_MOUSE_MOVE )
                call TriggerAddCondition( this.posDetector, Condition(function thistype.onMouseMove))               
               
                call TriggerRegisterPlayerEvent( stateDetector, p, EVENT_PLAYER_MOUSE_UP )
                call TriggerRegisterPlayerEvent( stateDetector, p, EVENT_PLAYER_MOUSE_DOWN )
            endif
           
            set this = this + 1
            set p    = this.player
        endloop
    endmethod
   
    static method registerCode takes code handlerFunc, integer eventId returns triggercondition
        return TriggerAddCondition(evTrigger[eventId], Condition(handlerFunc))
    endmethod
   
    static method unregisterCallback takes triggercondition whichHandler, integer eventId returns nothing
        call TriggerRemoveCondition(evTrigger[eventId], whichHandler)
    endmethod
   
    implement Init
endstruct

function GetPlayerMouseX takes player p returns real
    return UserMouse[p].mouseX
endfunction
function GetPlayerMouseY takes player p returns real
    return UserMouse[p].mouseY
endfunction
function OnMouseEvent takes code func, integer eventId returns triggercondition
    return UserMouse.registerCode(func, eventId)
endfunction
function GetMouseEventType takes nothing returns integer
    return UserMouse.getCurEventType()
endfunction
function UnregisterMouseCallback takes triggercondition whichHandler, integer eventId returns nothing
    call UserMouse.unregisterCallback(whichHandler, eventId)
endfunction
endif
endlibrary