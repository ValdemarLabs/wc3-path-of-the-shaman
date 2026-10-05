/**
    FreeCamera

    Author: [Valdemar]
    Version: 1.0.0

    Description: Provides a local development fly camera for screenshots, videos, and world inspection.

    Credits: Blizzard Entertainment (Warcraft III 3.0 Editor Camera reference implementation)

    How to install:
    Import after CameraControl. Requires Warcraft III 3.0.0 or newer.

    API:
    call FreeCamera_Enable(whichPlayer)
    call FreeCamera_Disable(whichPlayer)
    call FreeCamera_Toggle(whichPlayer)
    call FreeCamera_IsEnabled(whichPlayer) returns boolean

**/
library FreeCamera initializer AutoInit requires CameraControl

globals
    // Camera type 1 permits the scripted camera fields used by the 3.0 Editor Camera.
    private constant integer FC_CAMERA_TYPE = 1
    private constant real FC_UPDATE_INTERVAL = 0.02
    private constant real FC_MOVE_SPEED = 20.00
    private constant real FC_SLOW_FACTOR = 0.25
    private constant real FC_MOUSE_SENSITIVITY = 0.15
    private constant integer FC_MAX_MOUSE_DELTA = 200
    private constant real FC_TARGET_DISTANCE = 5.00

    private boolean array FC_Enabled
    private boolean array FC_Rotating
    private boolean array FC_OwnsInputOwnership
    private integer array FC_PreviousMode
    private integer array FC_PreviousCameraType
    private integer array FC_MouseAnchorX
    private integer array FC_MouseAnchorY
    private real array FC_TargetX
    private real array FC_TargetY
    private real array FC_TargetZ
    private real array FC_Angle
    private real array FC_Rotation
    private timer FC_UpdateTimer = null
endglobals

private function FC_ClampInteger takes integer value, integer minValue, integer maxValue returns integer
    if value < minValue then
        return minValue
    endif
    if value > maxValue then
        return maxValue
    endif
    return value
endfunction

private function FC_NormalizeAngle takes real value returns real
    loop
        exitwhen value >= 0.00
        set value = value + 360.00
    endloop
    loop
        exitwhen value < 360.00
        set value = value - 360.00
    endloop
    return value
endfunction

private function FC_RestoreMode takes player whichPlayer, integer mode returns nothing
    if mode == CameraControl_CAMERA_MODE_ADVANCED then
        call CameraControl_SetModeAdvanced(whichPlayer)
    elseif mode == CameraControl_CAMERA_MODE_DEVELOPER then
        call CameraControl_SetModeDeveloper(whichPlayer)
    else
        call CameraControl_SetModeNormal(whichPlayer)
    endif
endfunction

private function FC_StopMouseLook takes integer pid returns nothing
    if FC_Rotating[pid] then
        set FC_Rotating[pid] = false
        call BlzEnableCursor(true)
    endif
endfunction

private function FC_UpdateMouseLook takes integer pid returns nothing
    local integer mouseX
    local integer mouseY
    local integer deltaX
    local integer deltaY

    if not BlzIsMouseButtonPressed(MOUSE_BUTTON_TYPE_RIGHT) then
        call FC_StopMouseLook(pid)
        return
    endif

    set mouseX = BlzGetMouseScreenPosX()
    set mouseY = BlzGetMouseScreenPosY()
    if not FC_Rotating[pid] then
        set FC_Rotating[pid] = true
        set FC_MouseAnchorX[pid] = mouseX
        set FC_MouseAnchorY[pid] = mouseY
        return
    endif

    set deltaX = FC_ClampInteger(mouseX - FC_MouseAnchorX[pid], -FC_MAX_MOUSE_DELTA, FC_MAX_MOUSE_DELTA)
    set deltaY = FC_ClampInteger(mouseY - FC_MouseAnchorY[pid], -FC_MAX_MOUSE_DELTA, FC_MAX_MOUSE_DELTA)
    if deltaX != 0 or deltaY != 0 then
        set FC_Rotation[pid] = FC_NormalizeAngle(FC_Rotation[pid] - I2R(deltaX) * FC_MOUSE_SENSITIVITY)
        set FC_Angle[pid] = FC_NormalizeAngle(FC_Angle[pid] + I2R(deltaY) * FC_MOUSE_SENSITIVITY)
        call BlzSetMousePos(FC_MouseAnchorX[pid], FC_MouseAnchorY[pid])
    endif
    call BlzEnableCursor(false)
endfunction

private function FC_UpdateMovement takes integer pid returns nothing
    local real speed = FC_MOVE_SPEED
    local real radiansRotation = FC_Rotation[pid] * bj_DEGTORAD
    local real radiansAngle = FC_Angle[pid] * bj_DEGTORAD
    local real forwardX = Cos(radiansRotation) * Cos(radiansAngle)
    local real forwardY = Sin(radiansRotation) * Cos(radiansAngle)
    local real forwardZ = Sin(radiansAngle)
    local real verticalX = -Cos(radiansRotation) * Sin(radiansAngle)
    local real verticalY = -Sin(radiansRotation) * Sin(radiansAngle)
    local real verticalZ = Cos(radiansAngle)

    if BlzIsMetaKeyPressed(METAKEY_SHIFT) then
        set speed = speed * FC_SLOW_FACTOR
    endif
    if BlzIsKeyPressed(OSKEY_W) then
        set FC_TargetX[pid] = FC_TargetX[pid] + forwardX * speed
        set FC_TargetY[pid] = FC_TargetY[pid] + forwardY * speed
        set FC_TargetZ[pid] = FC_TargetZ[pid] + forwardZ * speed
    endif
    if BlzIsKeyPressed(OSKEY_S) then
        set FC_TargetX[pid] = FC_TargetX[pid] - forwardX * speed
        set FC_TargetY[pid] = FC_TargetY[pid] - forwardY * speed
        set FC_TargetZ[pid] = FC_TargetZ[pid] - forwardZ * speed
    endif
    if BlzIsKeyPressed(OSKEY_A) then
        set FC_TargetX[pid] = FC_TargetX[pid] - Sin(radiansRotation) * speed
        set FC_TargetY[pid] = FC_TargetY[pid] + Cos(radiansRotation) * speed
    endif
    if BlzIsKeyPressed(OSKEY_D) then
        set FC_TargetX[pid] = FC_TargetX[pid] + Sin(radiansRotation) * speed
        set FC_TargetY[pid] = FC_TargetY[pid] - Cos(radiansRotation) * speed
    endif
    if BlzIsKeyPressed(OSKEY_E) then
        set FC_TargetX[pid] = FC_TargetX[pid] + verticalX * speed
        set FC_TargetY[pid] = FC_TargetY[pid] + verticalY * speed
        set FC_TargetZ[pid] = FC_TargetZ[pid] + verticalZ * speed
    endif
    if BlzIsKeyPressed(OSKEY_Q) then
        set FC_TargetX[pid] = FC_TargetX[pid] - verticalX * speed
        set FC_TargetY[pid] = FC_TargetY[pid] - verticalY * speed
        set FC_TargetZ[pid] = FC_TargetZ[pid] - verticalZ * speed
    endif
endfunction

private function FC_Apply takes integer pid returns nothing
    call SetCameraField(CAMERA_FIELD_ZABSOLUTE, FC_TargetZ[pid], 0.00)
    call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, FC_Angle[pid], 0.00)
    call SetCameraField(CAMERA_FIELD_ROTATION, FC_Rotation[pid], 0.00)
    call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, FC_TARGET_DISTANCE, 0.00)
    call SetCameraField(CAMERA_FIELD_LOCAL_YAW, 0.00, 0.00)
    call SetCameraField(CAMERA_FIELD_LOCAL_PITCH, 0.00, 0.00)
    call SetCameraField(CAMERA_FIELD_LOCAL_ROLL, 0.00, 0.00)
    call SetCameraPosition(FC_TargetX[pid], FC_TargetY[pid])
endfunction

private function FC_Update takes nothing returns nothing
    local player whichPlayer = GetLocalPlayer()
    local integer pid = GetPlayerId(whichPlayer)

    if FC_Enabled[pid] and BlzIsLocalClientActive() then
        call FC_UpdateMouseLook(pid)
        call FC_UpdateMovement(pid)
        call FC_Apply(pid)
    elseif FC_Enabled[pid] then
        call FC_StopMouseLook(pid)
    endif

    set whichPlayer = null
endfunction

public function IsEnabled takes player whichPlayer returns boolean
    return FC_Enabled[GetPlayerId(whichPlayer)]
endfunction

public function Enable takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)

    if GetLocalPlayer() != whichPlayer or FC_Enabled[pid] then
        return
    endif

    set FC_PreviousMode[pid] = CameraControl_GetMode(whichPlayer)
    set FC_PreviousCameraType[pid] = BlzCameraGetCameraType()
    set FC_OwnsInputOwnership[pid] = not CameraControl_IsExperimentalInputOwnershipEnabled(whichPlayer)
    set FC_TargetX[pid] = GetCameraEyePositionX()
    set FC_TargetY[pid] = GetCameraEyePositionY()
    set FC_TargetZ[pid] = GetCameraEyePositionZ()
    set FC_Angle[pid] = FC_NormalizeAngle(GetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK) * bj_RADTODEG)
    set FC_Rotation[pid] = FC_NormalizeAngle(GetCameraField(CAMERA_FIELD_ROTATION) * bj_RADTODEG)
    set FC_Enabled[pid] = true

    call CameraControl_SetModeDeveloper(whichPlayer)
    if FC_OwnsInputOwnership[pid] then
        call CameraControl_SetExperimentalInputOwnership(whichPlayer, true)
    endif
    call BlzCameraSetCameraType(FC_CAMERA_TYPE)
    call CameraSetSmoothingFactor(0)
    call FC_Apply(pid)
endfunction

public function Disable takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)

    if GetLocalPlayer() != whichPlayer or not FC_Enabled[pid] then
        return
    endif

    set FC_Enabled[pid] = false
    call FC_StopMouseLook(pid)
    call BlzCameraSetCameraType(FC_PreviousCameraType[pid])
    if FC_OwnsInputOwnership[pid] then
        call CameraControl_ResetExperimentalInputOwnership(whichPlayer)
        set FC_OwnsInputOwnership[pid] = false
    endif
    call FC_RestoreMode(whichPlayer, FC_PreviousMode[pid])
endfunction

public function Toggle takes player whichPlayer returns nothing
    if IsEnabled(whichPlayer) then
        call Disable(whichPlayer)
    else
        call Enable(whichPlayer)
    endif
endfunction

private function Init takes nothing returns nothing
    set FC_UpdateTimer = CreateTimer()
    call TimerStart(FC_UpdateTimer, FC_UPDATE_INTERVAL, true, function FC_Update)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
