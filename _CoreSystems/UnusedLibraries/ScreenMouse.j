//===========================================================================
//
//  Screen Mouse v1.0.2
//  by loktar
//  -------------------------------------------------------------------------
// * Track mouse movement relative to screen
// * Note that map coordinates go from east to west (X) and south to north (Y)
//  -------------------------------------------------------------------------
//
//    -------
//    * API *
//    -------
//  *    boolean ScreenMouseRegisterPlayer(trigger buttonTrigger, trigger moveTrigger, player plr, boolean left, boolean right, boolean both)
//          - Register mouse button and mouse move events
//          - Register for left button, right button and/or both together
//          - Disables moveTrigger
//          - Returns false if trigger(s) are already registered, otherwise returns true
//
//  *    boolean SMIsLeftDown(integer playerNumber), SMIsRightDown(integer playerNumber)
//          - Mouse button state for player
//
//  *    real SMGetDifX(integer playerNumber), SMGetDifY(integer playerNumber)
//          - Difference with previous mouse position for player
//          - Changes each time EVENT_PLAYER_MOUSE_MOVE is fired
//
//  *    real SMGetDifXs(integer playerNumber), SMGetDifYs(integer playerNumber)
//          - Same as difX/difY, but only compensates for Target Distance and Field of View
//
//  *    real SM_distMpl
//          - Multiplier for Target Distance compensation
//          - Only applied if larger than current Target Distance
//          - Difference/Distance*SM_distMpl
//          - Default: 800
//
//  *    real SM_fovMpl
//          - Multiplier for Field of View compensation (in Radians!)
//          - Only applied if larger than current Field of View
//          - Difference/FoV*SM_fovMpl
//          - Default: Deg2Rad(70)
//
//  *    real SM_minX, SM_maxX, SM_minY, SM_maxY
//          - Mouse position bounds
//          - Default: Camera Bounds
//
//===========================================================================

library ScreenMouse initializer InitScreenMouse

static if not USE_MEMORY_HACK then
    globals
        private constant real R90 = Deg2Rad(90)
       
        private hashtable htbTriggers = InitHashtable()
        private constant key X
        private constant key Y
        private constant key DIFX
        private constant key DIFY
        private constant key DIFX_S
        private constant key DIFY_S
        private constant key LEFT_DOWN
        private constant key RIGHT_DOWN
        private constant key DO_LEFT
        private constant key DO_RIGHT
        private constant key DO_BOTH
       
        real SM_minX // GetCameraBound cannot be called at init
        real SM_maxX
        real SM_minY
        real SM_maxY
        real SM_distMpl = 800
        real SM_fovMpl  = Deg2Rad(70)
    endglobals
//===============================================================================
//===============================================================================

//===============================================================================
//==== MOUSE FUNCS ==============================================================
//===============================================================================
    //==== Mouse Move ====
    private function MouseMoveCndAcn takes nothing returns boolean
        local real newX
        local real newY
        local real realTmp
        local real realTmp2
        local trigger trg = GetTriggeringTrigger()
        local integer pId = LoadInteger(htbTriggers, GetHandleId(trg), 0)
       
//call BJDebugMsg("update")
        call DisableTrigger(trg)
           
        //if LoadBoolean(htbTriggers, pId, LEFT_DOWN) or LoadBoolean(htbTriggers, pId, RIGHT_DOWN) then
            set newX = BlzGetTriggerPlayerMouseX()
            set newY = BlzGetTriggerPlayerMouseY()
       
            //if (newX != 0 or newY != 0) and newX >= SM_minX and newX <= SM_maxX and newY >= SM_minY and newY <= SM_maxY then // Mouse on UI gives (0, 0)
                set realTmp = LoadReal(htbTriggers, pId, X)-newX
                set realTmp2 = LoadReal(htbTriggers, pId, Y)-newY
                call SaveReal(htbTriggers, pId, X, newX)
                call SaveReal(htbTriggers, pId, Y, newY)
                set newX = realTmp
                set newY = realTmp2
               
                // Compensate Distance
                set realTmp = GetCameraField(CAMERA_FIELD_TARGET_DISTANCE)
                if realTmp > SM_distMpl then
                    set newX = newX/realTmp*SM_distMpl
                    set newY = newY/realTmp*SM_distMpl
                endif
               
                // Compensate FoV
                set realTmp = GetCameraField(CAMERA_FIELD_FIELD_OF_VIEW)
                if realTmp > SM_fovMpl then
                    set newX = newX/realTmp*SM_fovMpl
                    set newY = newY/realTmp*SM_fovMpl
                endif
               
                call SaveReal(htbTriggers, pId, DIFX_S, newX)
                call SaveReal(htbTriggers, pId, DIFY_S, newY)
               
                // Compensate Rotation
                set realTmp = GetCameraField(CAMERA_FIELD_ROTATION)
                set realTmp2 = newX // Save original newX for newY calculation
                set newX = Cos(realTmp-R90)*(newX) + Sin(realTmp-R90)*(newY)
                set newY = Cos(realTmp+R90)*(-newY) - Sin(realTmp+R90)*(-realTmp2)
               
                // Compensate Roll
                set realTmp = GetCameraField(CAMERA_FIELD_ROLL)
                set realTmp2 = newX // Save original newX for newY calculation
                set newX = Sin(realTmp-R90)*(-newX) + Cos(realTmp-R90)*(-newY)
                set newY = Sin(realTmp+R90)*(newY) - Cos(realTmp+R90)*(realTmp2)
                   
                // Compensate AoA
                set newY = Sin(-GetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK))*newY
               
                call SaveReal(htbTriggers, pId, DIFX, newX)
                call SaveReal(htbTriggers, pId, DIFY, newY)
            //endif
       
            call EnableTrigger(trg)
        //endif
       
        set trg = null
       
        return true
    endfunction
    //========
   
    //==== Mouse Button ====
    private function MouseBtnCndAcn takes nothing returns boolean
        local mousebuttontype mouseBtn = BlzGetTriggerPlayerMouseButton()
        local integer pId = GetHandleId(GetTriggeringTrigger())
        local trigger moveTrg = LoadTriggerHandle(htbTriggers, pId, 1)
        local boolean enable
       
        set pId = LoadInteger(htbTriggers, pId, 0)
       
        if GetTriggerEventId() == EVENT_PLAYER_MOUSE_DOWN then
            // MOUSE_BUTTON_TYPE_MIDDLE does not fire this event as of 1.30.4
            if mouseBtn == MOUSE_BUTTON_TYPE_LEFT then
                call SaveBoolean(htbTriggers, pId, LEFT_DOWN, true)
            elseif mouseBtn == MOUSE_BUTTON_TYPE_RIGHT then
                call SaveBoolean(htbTriggers, pId, RIGHT_DOWN, true)
            endif
        elseif mouseBtn == MOUSE_BUTTON_TYPE_LEFT then
            call SaveBoolean(htbTriggers, pId, LEFT_DOWN, false)
        elseif mouseBtn == MOUSE_BUTTON_TYPE_RIGHT then
            call SaveBoolean(htbTriggers, pId, RIGHT_DOWN, false)
        endif
           
        set enable = LoadBoolean(htbTriggers, pId, RIGHT_DOWN)
        if LoadBoolean(htbTriggers, pId, LEFT_DOWN) then
            set enable = (enable and LoadBoolean(htbTriggers, pId, DO_BOTH)) or (not enable and LoadBoolean(htbTriggers, pId, DO_LEFT))
        else
            set enable = enable and LoadBoolean(htbTriggers, pId, DO_RIGHT)
        endif
           
        if enable then
            if not IsTriggerEnabled(moveTrg) then
                call SaveReal(htbTriggers, pId, X, BlzGetTriggerPlayerMouseX())
                call SaveReal(htbTriggers, pId, Y, BlzGetTriggerPlayerMouseY())
                //call EnableTrigger(moveTrg)
            endif
        else
            //call DisableTrigger(moveTrg)
        endif
       
        set moveTrg = null
       
        return true
    endfunction
    //===========================================================================
    //===========================================================================
//===============================================================================
//===============================================================================

//===============================================================================
//==== API FUNCS ================================================================
//===============================================================================
    //==== Register events to trigger/player ====
    function ScreenMouseRegisterPlayer takes trigger btnTrg, trigger moveTrg, player plr, boolean left, boolean right, boolean both returns boolean
        local integer hIdBtn = GetHandleId(btnTrg)
        local integer hIdMove = GetHandleId(moveTrg)
        local integer pId = GetPlayerId(plr)
       
        if HaveSavedInteger(htbTriggers, hIdBtn, 0) or HaveSavedInteger(htbTriggers, hIdMove, 0) then
            return false // trigger(s) already registered
        else
            call SaveInteger(htbTriggers, hIdBtn, 0, pId)
            call SaveTriggerHandle(htbTriggers, hIdBtn, 1, moveTrg)
            call SaveInteger(htbTriggers, hIdMove, 0, pId)
            call SaveBoolean(htbTriggers, pId, LEFT_DOWN, false)
            call SaveBoolean(htbTriggers, pId, RIGHT_DOWN, false)
            call SaveBoolean(htbTriggers, pId, DO_LEFT, left)
            call SaveBoolean(htbTriggers, pId, DO_RIGHT, right)
            call SaveBoolean(htbTriggers, pId, DO_BOTH, both)
           
            //call DisableTrigger(moveTrg)
            call TriggerRegisterPlayerEvent(moveTrg, plr, EVENT_PLAYER_MOUSE_MOVE)
            call TriggerAddCondition(moveTrg, function MouseMoveCndAcn)
           
            call TriggerRegisterPlayerEvent(btnTrg, plr, EVENT_PLAYER_MOUSE_DOWN)
            call TriggerRegisterPlayerEvent(btnTrg, plr, EVENT_PLAYER_MOUSE_UP)
            call TriggerAddCondition(btnTrg, function MouseBtnCndAcn)
           
            return true
        endif
    endfunction
    //========
   
    //==== Get Left Down ====
    function SMIsLeftDown takes integer playerId returns boolean
        return LoadBoolean(htbTriggers, playerId, LEFT_DOWN)
    endfunction
    //========
   
    //==== Get Right Down ====
    function SMIsRightDown takes integer playerId returns boolean
        return LoadBoolean(htbTriggers, playerId, RIGHT_DOWN)
    endfunction
    //========
   
    // ==== Get difX ====
    function SMGetDifX takes integer playerId returns real
        return LoadReal(htbTriggers, playerId, DIFX)
    endfunction
    //========
   
    // ==== Get difY ====
    function SMGetDifY takes integer playerId returns real
        return LoadReal(htbTriggers, playerId, DIFY)
    endfunction
    //========
   
    // ==== Get difXs ====
    function SMGetDifXs takes integer playerId returns real
        return LoadReal(htbTriggers, playerId, DIFX_S)
    endfunction
    //========
   
    // ==== Get difYs ====
    function SMGetDifYs takes integer playerId returns real
        return LoadReal(htbTriggers, playerId, DIFY_S)
    endfunction
    //===========================================================================
    //===========================================================================
//===============================================================================
//===============================================================================

//===============================================================================
//==== INITIALIZER ==============================================================
//===============================================================================
    private function InitScreenMouse takes nothing returns nothing
        call TriggerSleepAction(0) // For GetCameraBound
       
        // Get map bounds
        set SM_minX = GetCameraBoundMinX()
        set SM_maxX = GetCameraBoundMaxX()
        set SM_minY = GetCameraBoundMinY()
        set SM_maxY = GetCameraBoundMaxY()
    endfunction
//===============================================================================
//===============================================================================

endif
endlibrary