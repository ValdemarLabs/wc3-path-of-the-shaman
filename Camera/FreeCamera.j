/**
    FreeCamera

    Author: [Valdemar]
    Version: 1.2.0

    Description: Provides a local development fly camera for screenshots, videos, and world inspection.

    Credits: Blizzard Entertainment (Warcraft III 3.0 Editor Camera reference implementation)

    How to install:
    Import after CameraControl and FullscreenUI. Requires Warcraft III 3.0.0 or newer.

    API:
    call FreeCamera_Enable(whichPlayer)
    call FreeCamera_Disable(whichPlayer)
    call FreeCamera_Toggle(whichPlayer)
    call FreeCamera_IsEnabled(whichPlayer) returns boolean

**/
library FreeCamera initializer AutoInit requires CameraControl, FullscreenUI, optional DynamicMinimap

globals
    // Camera type 1 permits the scripted camera fields used by the 3.0 Editor Camera.
    private constant integer FC_CAMERA_TYPE = 1
    private constant real FC_UPDATE_INTERVAL = 0.02
    private constant real FC_MOVE_SPEED = 20.00
    private constant real FC_SLOW_FACTOR = 0.25
    private constant real FC_MOUSE_SENSITIVITY = 0.15
    private constant integer FC_MAX_MOUSE_DELTA = 200
    private constant real FC_TARGET_DISTANCE = 5.00
    private constant real FC_MINIMAP_SAFE_ROTATION = 90.00
    private constant string FC_SYNC_SEIZE = "POTS_FREE_CAMERA_ON"
    private constant string FC_SYNC_RESTORE = "POTS_FREE_CAMERA_OFF"

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
    private unit array FC_ControlledUnit
    private player array FC_ControlledUnitOwner
    private boolean array FC_ControlledUnitWasPaused
    private boolean array FC_ControlledUnitWasInvulnerable
    private boolean array FC_DynamicMinimapWasFullMap
    private boolean array FC_FullscreenWasEnabled
    private timer FC_UpdateTimer = null
    private trigger FC_UnitSeizeTrigger = null
    private trigger FC_UnitRestoreTrigger = null
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

private function FC_SeizeControlledUnit takes unit controlledUnit, integer pid returns nothing
    set FC_ControlledUnit[pid] = controlledUnit
    if controlledUnit != null then
        set FC_ControlledUnitOwner[pid] = GetOwningPlayer(controlledUnit)
        set FC_ControlledUnitWasPaused[pid] = IsUnitPaused(controlledUnit)
        set FC_ControlledUnitWasInvulnerable[pid] = BlzIsUnitInvulnerable(controlledUnit)
        if GetLocalPlayer() == Player(pid) then
            call SelectUnit(controlledUnit, false)
        endif
        call IssueImmediateOrder(controlledUnit, "stop")
        call SetUnitInvulnerable(controlledUnit, true)
        call PauseUnit(controlledUnit, true)
        call SetUnitOwner(controlledUnit, Player(PLAYER_NEUTRAL_PASSIVE), false)
    endif

endfunction

private function FC_RestoreControlledUnit takes integer pid returns nothing
    local unit controlledUnit = FC_ControlledUnit[pid]

    if controlledUnit != null and GetUnitTypeId(controlledUnit) != 0 then
        call SetUnitOwner(controlledUnit, FC_ControlledUnitOwner[pid], false)
        call SetUnitInvulnerable(controlledUnit, FC_ControlledUnitWasInvulnerable[pid])
        call PauseUnit(controlledUnit, FC_ControlledUnitWasPaused[pid])
    endif

    set FC_ControlledUnit[pid] = null
    set FC_ControlledUnitOwner[pid] = null
    set controlledUnit = null
endfunction

private function FC_GetSyncedControlledUnit takes integer handleId returns unit
    if udg_Nazgrek != null and GetHandleId(udg_Nazgrek) == handleId then
        return udg_Nazgrek
    endif
    if udg_Zulkis != null and GetHandleId(udg_Zulkis) == handleId then
        return udg_Zulkis
    endif
    return null
endfunction

private function FC_OnUnitSeizeSync takes nothing returns nothing
    local integer pid = GetPlayerId(GetTriggerPlayer())
    local unit controlledUnit = FC_GetSyncedControlledUnit(S2I(BlzGetTriggerSyncData()))

    call FC_SeizeControlledUnit(controlledUnit, pid)

    set controlledUnit = null
endfunction

private function FC_OnUnitRestoreSync takes nothing returns nothing
    call FC_RestoreControlledUnit(GetPlayerId(GetTriggerPlayer()))
endfunction

private function FC_FixDynamicMinimap takes integer pid returns nothing
    static if LIBRARY_DynamicMinimap then
        if pid == 0 then
            set FC_DynamicMinimapWasFullMap[pid] = DynamicMinimap_GetFullMapMode()
            if not FC_DynamicMinimapWasFullMap[pid] then
                call SetCameraField(CAMERA_FIELD_ROTATION, FC_MINIMAP_SAFE_ROTATION, 0.00)
                call DynamicMinimap_SetFullMapMode(true)
            endif
            call DynamicMinimap_SuspendForScriptedCamera()
            call SetCameraField(CAMERA_FIELD_ROTATION, FC_Rotation[pid], 0.00)
        endif
    endif
endfunction

private function FC_RestoreDynamicMinimap takes integer pid returns nothing
    static if LIBRARY_DynamicMinimap then
        if pid == 0 then
            call DynamicMinimap_ResumeAfterScriptedCamera()
            if not FC_DynamicMinimapWasFullMap[pid] then
                call DynamicMinimap_SetFullMapMode(false)
            endif
        endif
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
        set FC_Angle[pid] = FC_NormalizeAngle(FC_Angle[pid] - I2R(deltaY) * FC_MOUSE_SENSITIVITY)
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
    if BlzIsKeyPressed(OSKEY_Q) then
        set FC_TargetZ[pid] = FC_TargetZ[pid] + speed
    endif
    if BlzIsKeyPressed(OSKEY_E) then
        set FC_TargetZ[pid] = FC_TargetZ[pid] - speed
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
    local unit controlledUnit = null

    if GetLocalPlayer() != whichPlayer or FC_Enabled[pid] then
        return
    endif

    set controlledUnit = CameraControl_GetTargetUnit(whichPlayer)
    set FC_PreviousMode[pid] = CameraControl_GetMode(whichPlayer)
    set FC_PreviousCameraType[pid] = BlzCameraGetCameraType()
    set FC_OwnsInputOwnership[pid] = not CameraControl_IsExperimentalInputOwnershipEnabled(whichPlayer)
    set FC_TargetX[pid] = GetCameraEyePositionX()
    set FC_TargetY[pid] = GetCameraEyePositionY()
    set FC_TargetZ[pid] = GetCameraEyePositionZ()
    set FC_Angle[pid] = FC_NormalizeAngle(GetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK) * bj_RADTODEG)
    set FC_Rotation[pid] = FC_NormalizeAngle(GetCameraField(CAMERA_FIELD_ROTATION) * bj_RADTODEG)
    set FC_FullscreenWasEnabled[pid] = FullscreenUI_IsEnabled()
    set FC_Enabled[pid] = true

    call CameraControl_SetModeDeveloper(whichPlayer)
    if controlledUnit != null then
        call BlzSendSyncData(FC_SYNC_SEIZE, I2S(GetHandleId(controlledUnit)))
    endif
    call FC_FixDynamicMinimap(pid)
    call FullscreenUI_SetEnabled(true)
    if FC_OwnsInputOwnership[pid] then
        call CameraControl_SetExperimentalInputOwnership(whichPlayer, true)
    endif
    call BlzCameraSetCameraType(FC_CAMERA_TYPE)
    call CameraSetSmoothingFactor(100)
    call FC_Apply(pid)
    set controlledUnit = null
endfunction

public function Disable takes player whichPlayer returns nothing
    local integer pid = GetPlayerId(whichPlayer)

    if GetLocalPlayer() != whichPlayer or not FC_Enabled[pid] then
        return
    endif

    set FC_Enabled[pid] = false
    call BlzSendSyncData(FC_SYNC_RESTORE, "1")
    call FC_StopMouseLook(pid)
    call BlzCameraSetCameraType(FC_PreviousCameraType[pid])
    if FC_OwnsInputOwnership[pid] then
        call CameraControl_ResetExperimentalInputOwnership(whichPlayer)
        set FC_OwnsInputOwnership[pid] = false
    endif
    call FC_RestoreMode(whichPlayer, FC_PreviousMode[pid])
    call FC_RestoreDynamicMinimap(pid)
    if not FC_FullscreenWasEnabled[pid] then
        call FullscreenUI_SetEnabled(false)
    endif
endfunction

public function Toggle takes player whichPlayer returns nothing
    if IsEnabled(whichPlayer) then
        call Disable(whichPlayer)
    else
        call Enable(whichPlayer)
    endif
endfunction

private function Init takes nothing returns nothing
    local integer i = 0

    set FC_UnitSeizeTrigger = CreateTrigger()
    set FC_UnitRestoreTrigger = CreateTrigger()
    loop
        exitwhen i >= bj_MAX_PLAYERS
        call BlzTriggerRegisterPlayerSyncEvent(FC_UnitSeizeTrigger, Player(i), FC_SYNC_SEIZE, false)
        call BlzTriggerRegisterPlayerSyncEvent(FC_UnitRestoreTrigger, Player(i), FC_SYNC_RESTORE, false)
        set i = i + 1
    endloop
    call TriggerAddAction(FC_UnitSeizeTrigger, function FC_OnUnitSeizeSync)
    call TriggerAddAction(FC_UnitRestoreTrigger, function FC_OnUnitRestoreSync)

    set FC_UpdateTimer = CreateTimer()
    call TimerStart(FC_UpdateTimer, FC_UPDATE_INTERVAL, true, function FC_Update)
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
