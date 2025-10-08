//TESH.scrollpos=0
//TESH.alwaysfold=0
library KeyboardSystem initializer Init
// Keyboard System by The_Witcher
// This System helps you to get rid of all the triggers
// you would need for creating an effective arrow key
// system.
// This system has aditionally the power to add a key twice press event to a trigger
// you just need to adjust this little variable:
globals
    // this is the time the player has to "double press" a key
    // if a key is pressed twice in this time the registered triggers are executed
    private constant real DELAY = 0.2
endglobals
// Use this function to see which keys are hold down:
//
//  IsKeyDown( key,   pl)   returns boolean
//           string player
//
//   key can be KEY_LEFT, KEY_RIGHT, KEY_UP or KEY_DOWN
//   pl is the player who is checked
//   if the function returns true the key is hold down by player pl
//
// And this 2 functions to register a double press event to a trigger
//
//   TriggerRegisterKeyDoublePressEvent(t, key)
//
//   TriggerRegisterPlayerKeyDoublePressEvent(t, key, pl)
//
//   TriggerRegisterKeyDoubleInterruptEvent(t, key)
//
//   TriggerRegisterPlayerKeyDoubleInterruptEvent(t, key, pl)
//
//   t is the trigger you want to register that event to
//   key is the pressed key (again can be KEY_LEFT, KEY_RIGHT, KEY_UP or KEY_DOWN)
//   pl is in the second function the player who has to press 
//      the keys to fire the trigger
//   the first function fires the trigger regardless of which player pressed the key
//
//
//--------------Don't edit anything below---------------------------
globals
    private timer array time[13]
    private trigger array TRIGGERS
    private trigger array TRIGGERS2
    private integer total = 0
    private integer total2 = 0
    private integer array PLAYER
    private integer array PLAYER2
    private string array KEY
    private string array KEY2
    constant string KEY_LEFT = "left"
    constant string KEY_RIGHT = "right"
    constant string KEY_UP = "up"
    constant string KEY_DOWN = "down"
    private hashtable h = InitHashtable()
endglobals

function IsKeyDown takes string key, player pl returns boolean
    return LoadBoolean(h,GetPlayerId(pl),StringHash(key))
endfunction

function TriggerRegisterKeyDoublePressEvent takes trigger t, string key returns nothing
    set TRIGGERS[total] = t
    set KEY[total] = key
    set PLAYER[total] = 100
    set total = total + 1
endfunction

function TriggerRegisterPlayerKeyDoublePressEvent takes trigger t, string key, player pl returns nothing
    set TRIGGERS[total] = t
    set KEY[total] = key
    set PLAYER[total] = GetPlayerId(pl)
    set total = total + 1
endfunction

function TriggerRegisterKeyDoubleInterruptEvent takes trigger t, string key returns nothing
    set TRIGGERS2[total2] = t
    set KEY2[total2] = key
    set PLAYER2[total2] = 100
    set total2 = total2 + 1
endfunction

function TriggerRegisterPlayerKeyDoubleInterruptEvent takes trigger t, string key, player pl returns nothing
    set TRIGGERS2[total2] = t
    set KEY2[total2] = key
    set PLAYER2[total2] = GetPlayerId(pl)
    set total2 = total2 + 1
endfunction

//! textmacro TriggerActions takes NAME, VarTrue, VarFalse
private function $NAME$press takes nothing returns nothing
    local integer i = GetPlayerId(GetTriggerPlayer())
    local integer x = 0
    call SaveBoolean(h,i,StringHash("$VarTrue$"),true)
    call SaveBoolean(h,i,StringHash("$VarFalse$"),false)
    if LoadStr(h,i,StringHash("LastKey")) != "$VarTrue$" then
        call TimerStart(time[i],0,false,null)
    endif
    if TimerGetRemaining(time[i]) > 0 and LoadStr(h,i,StringHash("LastKey")) == "$VarTrue$" then
        call SaveInteger(h,i,StringHash("Debug"),0)
        call SaveBoolean(h,i,StringHash("$VarTrue$Double"),true)
        loop
            exitwhen x >= total
            if TriggerEvaluate(TRIGGERS[x]) and KEY[x] == "$VarTrue$" and (PLAYER[x] == 100 or PLAYER[x] == i) then
                call TriggerExecute(TRIGGERS[x])
            endif
            set x = x + 1
        endloop
    endif
    if LoadInteger(h,i,StringHash("Debug")) == 1 then
        call TimerStart(time[i],DELAY,false,null)
    else
        call SaveInteger(h,i,StringHash("Debug"),1)
    endif
    call SaveStr(h,i,StringHash("LastKey"),"$VarTrue$")
endfunction

private function $NAME$release takes nothing returns nothing
    local integer i = GetPlayerId(GetTriggerPlayer())
    local integer x = 0
    call SaveBoolean(h,i,StringHash("$VarTrue$"),false)
    if LoadBoolean(h,i,StringHash("$VarTrue$Double")) then
        call SaveBoolean(h,i,StringHash("$VarTrue$Double"),false)
        loop
            exitwhen x >= total2
            if TriggerEvaluate(TRIGGERS2[x]) and KEY2[x] == "$VarTrue$" and (PLAYER2[x] == 100 or PLAYER2[x] == i) then
                call TriggerExecute(TRIGGERS2[x])
            endif
            set x = x + 1
        endloop
    endif    
endfunction
//! endtextmacro

//! runtextmacro TriggerActions("LEFT","left","right")
//! runtextmacro TriggerActions("RIGHT","right","left")
//! runtextmacro TriggerActions("UP","up","down")
//! runtextmacro TriggerActions("DOWN","down","up")

//! textmacro Initiate takes NAME
    set i = 0
    set t = CreateTrigger()
    set tt = CreateTrigger()
    call TriggerAddAction(t,function $NAME$press)
    call TriggerAddAction(tt,function $NAME$release)
    loop
        exitwhen i > 12
        call TriggerRegisterPlayerEvent(t,Player(i),EVENT_PLAYER_ARROW_$NAME$_DOWN)
        call TriggerRegisterPlayerEvent(tt,Player(i),EVENT_PLAYER_ARROW_$NAME$_UP)
        set i = i + 1
    endloop
//! endtextmacro

private function Init takes nothing returns nothing
    local trigger t
    local trigger tt
    local integer i
    //! runtextmacro Initiate("LEFT")
    //! runtextmacro Initiate("RIGHT")
    //! runtextmacro Initiate("UP")
    //! runtextmacro Initiate("DOWN")
    set i = 0
    loop
        exitwhen i > 12
        set time[i] = CreateTimer()
        set i = i + 1
    endloop
endfunction

endlibrary