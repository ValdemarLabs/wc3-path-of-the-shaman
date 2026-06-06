library CameraControl initializer AutoInit requires FixedCameraLock, AdvancedCameraSystem, ArrowKeyMovement
/**
    CameraControl
    
    Author: [Valdemar]
    Version: 1.0

    Description: Keeps each player's camera behavior consistent, including modes, target tracking, and basic movement controls.

    Credits: Tasyen (TasQuestBox as inspiration), Rahko, Sabe

**/
globals
    public constant integer CAMERA_MODE_NORMAL = 1
    public constant integer CAMERA_MODE_ADVANCED = 2
    public constant integer CAMERA_MODE_DEVELOPER = 3

    public constant real CAMERA_DISTANCE_MIN = 500.00
    public constant real CAMERA_DISTANCE_MAX = 4000.00
    public constant real CAMERA_FARZ_MIN = 0.00
    public constant real CAMERA_FARZ_MAX = 10000.00
    public constant real CAMERA_ANGLE_MIN = 270.00
    public constant real CAMERA_ANGLE_MAX = 350.00
    public constant real CAMERA_ROTATION_MIN = 0.00
    public constant real CAMERA_ROTATION_MAX = 360.00
    public constant real CAMERA_FOV_MIN = 20.00
    public constant real CAMERA_FOV_MAX = 120.00

    private constant real CAMERA_DEFAULT_DISTANCE = 1650.00
    private constant real CAMERA_DEFAULT_FARZ = 10000.00
    private constant real CAMERA_DEFAULT_ANGLE = 304.00
    private constant real CAMERA_DEFAULT_ROTATION = 90.00
    private constant real CAMERA_DEFAULT_FOV = 70.00
    private constant integer CAMERA_ADVANCED_WALK_ANIMATION = 5
    private constant real CAMERA_KEYBOARD_UPDATE_INTERVAL = 0.03
    private constant real CAMERA_KEYBOARD_FIELD_DURATION = 0.10
    private constant real CAMERA_KEYBOARD_HORIZONTAL_SPEED = 1.50
    private constant real CAMERA_KEYBOARD_VERTICAL_SPEED = 1.50
    private constant real CAMERA_DRIFT_CHECK_INTERVAL = 0.03
    private constant real CAMERA_FIELD_TOLERANCE = 0.75
    private constant real CAMERA_RESUME_DURATION = 2.00

    private boolean CC_Initialized = false
    private boolean CC_UpdateLoopActive = false

    private integer array CC_Mode
    private real array CC_Distance
    private real array CC_FarZ
    private real array CC_Angle
    private real array CC_Rotation
    private real array CC_Fov
    private unit array CC_TargetUnit
    private boolean array CC_Suspended
    private boolean array CC_PressingLeft
    private boolean array CC_PressingRight
    private boolean array CC_PressingUp
    private boolean array CC_PressingDown
    private boolean array CC_MoveLeft
    private boolean array CC_MoveRight
    private boolean array CC_MoveUp
    private boolean array CC_MoveDown
    private boolean array CC_ResumePending
    private timer array CC_ResumeTimer

    private trigger CC_SelectTrigger = null
    private trigger CC_LeftDownTrigger = null
    private trigger CC_LeftUpTrigger = null
    private trigger CC_RightDownTrigger = null
    private trigger CC_RightUpTrigger = null
    private trigger CC_UpDownTrigger = null
    private trigger CC_UpUpTrigger = null
    private trigger CC_DownDownTrigger = null
    private trigger CC_DownUpTrigger = null
    private trigger CC_PageResetTrigger = null
    private trigger CC_WheelResetTrigger = null
    private timer CC_UpdateTimer = null
    private timer CC_DriftTimer = null
endglobals

private function CC_GetPlayerIndex takes player whichPlayer returns integer
    return GetPlayerId(whichPlayer)
endfunction

private function CC_Clamp takes real value, real minValue, real maxValue returns real
    if value < minValue then
        return minValue
    endif
    if value > maxValue then
        return maxValue
    endif
    return value
endfunction

private function CC_Abs takes real value returns real
    if value < 0.00 then
        return -value
    endif
    return value
endfunction

private function CC_GetRotationDelta takes real a, real b returns real
    local real delta = a - b

    if delta < 0.00 then
        set delta = -delta
    endif
    if delta > 180.00 then
        set delta = 360.00 - delta
    endif
    return delta
endfunction

private function CC_IsSuspended takes player whichPlayer returns boolean
    return CC_Suspended[CC_GetPlayerIndex(whichPlayer)]
endfunction

private function CC_FindResumeTimerPlayer takes timer whichTimer returns integer
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        if CC_ResumeTimer[i] == whichTimer then
            return i
        endif
        set i = i + 1
    endloop

    return -1
endfunction

private function CC_IsKeyboardModeActive takes player whichPlayer returns boolean
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    return (not CC_Suspended[pid]) and (not CC_ResumePending[pid]) and CC_Mode[pid] == CAMERA_MODE_NORMAL
endfunction

private function CC_IsNativeResetProtectionActive takes player whichPlayer returns boolean
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    return (not CC_Suspended[pid]) and (not CC_ResumePending[pid]) and CC_Mode[pid] == CAMERA_MODE_NORMAL
endfunction

private function CC_ClearKeyState takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingLeft[pid] = false
    set CC_PressingRight[pid] = false
    set CC_PressingUp[pid] = false
    set CC_PressingDown[pid] = false
    set CC_MoveLeft[pid] = false
    set CC_MoveRight[pid] = false
    set CC_MoveUp[pid] = false
    set CC_MoveDown[pid] = false
endfunction

private function CC_IsAnyKeyPressed takes nothing returns boolean
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        if CC_PressingLeft[i] or CC_PressingRight[i] or CC_PressingUp[i] or CC_PressingDown[i] then
            return true
        endif
        set i = i + 1
    endloop

    return false
endfunction

public function IsTrackedCameraUnit takes unit u returns boolean
    return u != null and (u == udg_Nazgrek or u == udg_Zulkis)
endfunction

private function CC_GetFallbackTarget takes player whichPlayer returns unit
    local unit u = CC_TargetUnit[CC_GetPlayerIndex(whichPlayer)]

    if IsTrackedCameraUnit(u) and GetHandleId(u) != 0 and GetWidgetLife(u) > 0.405 then
        return u
    endif

    if IsTrackedCameraUnit(udg_Nazgrek) and GetHandleId(udg_Nazgrek) != 0 and GetWidgetLife(udg_Nazgrek) > 0.405 then
        return udg_Nazgrek
    endif
    if IsTrackedCameraUnit(udg_Zulkis) and GetHandleId(udg_Zulkis) != 0 and GetWidgetLife(udg_Zulkis) > 0.405 then
        return udg_Zulkis
    endif
    return null
endfunction

private function CC_GetAdvancedAngle takes player whichPlayer returns real
    return CC_Angle[CC_GetPlayerIndex(whichPlayer)] - 324.00
endfunction

private function CC_GetAdvancedResumeRotation takes player whichPlayer returns real
    local unit target = CC_GetFallbackTarget(whichPlayer)
    if target != null then
        return GetUnitFacing(target)
    endif
    return CC_Rotation[CC_GetPlayerIndex(whichPlayer)]
endfunction

private function CC_ApplySharedFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_FARZ, CC_FarZ[pid], duration)
        call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, CC_Fov[pid], duration)
    endif
endfunction

private function CC_ApplyDirectFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call CC_ApplySharedFields(whichPlayer, duration)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_Distance[pid], duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_Angle[pid], duration)
        call SetCameraField(CAMERA_FIELD_ROTATION, CC_Rotation[pid], duration)
    endif
endfunction

private function CC_ApplyAdvancedFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call CC_ApplySharedFields(whichPlayer, duration)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_Distance[pid], duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_GetAdvancedAngle(whichPlayer), duration)
        call SetCameraField(CAMERA_FIELD_ROTATION, CC_Rotation[pid], duration)
    endif
endfunction

private function CC_ApplyAdvancedDriftFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call CC_ApplySharedFields(whichPlayer, duration)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_Distance[pid], duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_GetAdvancedAngle(whichPlayer), duration)
    endif
endfunction

private function CC_ApplyAdvancedResumePreviewFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call CC_ApplySharedFields(whichPlayer, duration)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_Distance[pid], duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_GetAdvancedAngle(whichPlayer), duration)
        call SetCameraField(CAMERA_FIELD_ROTATION, CC_GetAdvancedResumeRotation(whichPlayer), duration)
    endif
endfunction

private function CC_ApplyKeyboardFields takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call SetCameraFieldForPlayer(whichPlayer, CAMERA_FIELD_ANGLE_OF_ATTACK, CC_Angle[pid], CAMERA_KEYBOARD_FIELD_DURATION)
    call SetCameraFieldForPlayer(whichPlayer, CAMERA_FIELD_ROTATION, CC_Rotation[pid], CAMERA_KEYBOARD_FIELD_DURATION)
endfunction

private function CC_BindNormalMode takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_TargetUnit[pid] = CC_GetFallbackTarget(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
    if CC_TargetUnit[pid] != null then
        call FCL_Lock(CC_TargetUnit[pid], whichPlayer)
    endif
endfunction

private function CC_BindAdvancedMode takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_TargetUnit[pid] = CC_GetFallbackTarget(whichPlayer)
    call FCL_Release(whichPlayer)
    if CC_TargetUnit[pid] != null then
        call SetCameraUnit(CC_TargetUnit[pid], whichPlayer)
        call SetMovementUnit(CC_TargetUnit[pid], whichPlayer, CAMERA_ADVANCED_WALK_ANIMATION)
    else
        call ReleaseCameraUnit(whichPlayer)
        call ReleaseMovementUnit(whichPlayer)
    endif
    call SetCamMaxDistance(whichPlayer, CC_Distance[pid])
    call SetCamMaxZCheckDistance(whichPlayer, CC_Distance[pid] * 0.50)
    call SetCamDefaultAngleOfAttack(whichPlayer, CC_GetAdvancedAngle(whichPlayer))
endfunction

private function CC_BindDeveloperMode takes player whichPlayer returns nothing
    call FCL_Release(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
endfunction

private function CC_ApplyNormalMode takes player whichPlayer returns nothing
    call CC_BindNormalMode(whichPlayer)
    call CC_ApplyDirectFields(whichPlayer, 0.00)
endfunction

private function CC_ApplyAdvancedMode takes player whichPlayer returns nothing
    call CC_BindAdvancedMode(whichPlayer)
    call CC_ApplyAdvancedFields(whichPlayer, 0.00)
endfunction

private function CC_ApplyDeveloperMode takes player whichPlayer returns nothing
    call CC_BindDeveloperMode(whichPlayer)
    call CC_ApplyDirectFields(whichPlayer, 0.00)
endfunction

private function CC_StartSmoothResumeVisualWithDuration takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local unit target = CC_GetFallbackTarget(whichPlayer)

    if GetLocalPlayer() == whichPlayer and target != null then
        call PanCameraToTimed(GetUnitX(target), GetUnitY(target), duration)
    endif

    if CC_Mode[pid] == CAMERA_MODE_ADVANCED then
        call CC_ApplyAdvancedResumePreviewFields(whichPlayer, duration)
    else
        call CC_ApplyDirectFields(whichPlayer, duration)
    endif
endfunction


private function CC_StartSmoothResumeVisual takes player whichPlayer returns nothing
    call CC_StartSmoothResumeVisualWithDuration(whichPlayer, CAMERA_RESUME_DURATION)
endfunction

private function CC_UpdateKeyboardCamera takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        if CC_Mode[i] == CAMERA_MODE_NORMAL and not CC_Suspended[i] then
            if CC_MoveDown[i] then
                set CC_Angle[i] = CC_Angle[i] + CAMERA_KEYBOARD_VERTICAL_SPEED
                if CC_Angle[i] > CAMERA_ANGLE_MAX then
                    set CC_Angle[i] = CAMERA_ANGLE_MAX
                endif
            elseif CC_MoveUp[i] then
                set CC_Angle[i] = CC_Angle[i] - CAMERA_KEYBOARD_VERTICAL_SPEED
                if CC_Angle[i] < CAMERA_ANGLE_MIN then
                    set CC_Angle[i] = CAMERA_ANGLE_MIN
                endif
            endif

            if CC_MoveRight[i] then
                set CC_Rotation[i] = CC_Rotation[i] + CAMERA_KEYBOARD_HORIZONTAL_SPEED
                if CC_Rotation[i] >= 360.00 then
                    set CC_Rotation[i] = CC_Rotation[i] - 360.00
                endif
            elseif CC_MoveLeft[i] then
                set CC_Rotation[i] = CC_Rotation[i] - CAMERA_KEYBOARD_HORIZONTAL_SPEED
                if CC_Rotation[i] <= 0.00 then
                    set CC_Rotation[i] = CC_Rotation[i] + 360.00
                endif
            endif

            call CC_ApplyKeyboardFields(Player(i))
        endif
        set i = i + 1
    endloop
endfunction

private function CC_ReapplyStoredFields takes player whichPlayer returns nothing
    if CC_Mode[CC_GetPlayerIndex(whichPlayer)] == CAMERA_MODE_ADVANCED then
        call CC_ApplyAdvancedDriftFields(whichPlayer, 0.00)
    else
        call CC_ApplyDirectFields(whichPlayer, 0.00)
    endif
endfunction

private function CC_CheckCameraDrift takes nothing returns nothing
    local integer i = 0
    local player whichPlayer
    local real expectedAngle
    local boolean drifted

    loop
        exitwhen i >= bj_MAX_PLAYERS
        if CC_Mode[i] == CAMERA_MODE_NORMAL and not CC_Suspended[i] and not CC_ResumePending[i] then
            set whichPlayer = Player(i)
            if GetLocalPlayer() == whichPlayer then
                set expectedAngle = CC_Angle[i]
                set drifted = false

                if CC_Abs(GetCameraField(CAMERA_FIELD_TARGET_DISTANCE) - CC_Distance[i]) > CAMERA_FIELD_TOLERANCE or CC_Abs(GetCameraField(CAMERA_FIELD_FARZ) - CC_FarZ[i]) > CAMERA_FIELD_TOLERANCE or CC_Abs(GetCameraField(CAMERA_FIELD_FIELD_OF_VIEW) - CC_Fov[i]) > CAMERA_FIELD_TOLERANCE or CC_Abs(GetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK) - expectedAngle) > CAMERA_FIELD_TOLERANCE then
                    set drifted = true
                endif
                if CC_GetRotationDelta(GetCameraField(CAMERA_FIELD_ROTATION), CC_Rotation[i]) > CAMERA_FIELD_TOLERANCE then
                    set drifted = true
                endif

                if drifted then
                    call CC_ReapplyStoredFields(whichPlayer)
                endif
            endif
            set whichPlayer = null
        endif
        set i = i + 1
    endloop
endfunction

private function CC_UpdateLoopState takes nothing returns nothing
    if CC_UpdateTimer == null then
        return
    endif

    if CC_IsAnyKeyPressed() then
        if not CC_UpdateLoopActive then
            set CC_UpdateLoopActive = true
            call TimerStart(CC_UpdateTimer, CAMERA_KEYBOARD_UPDATE_INTERVAL, true, function CC_UpdateKeyboardCamera)
        endif
    else
        set CC_UpdateLoopActive = false
        call PauseTimer(CC_UpdateTimer)
    endif
endfunction

private function CC_ApplyMode takes player whichPlayer returns nothing
    local integer mode = CC_Mode[CC_GetPlayerIndex(whichPlayer)]

    if CC_IsSuspended(whichPlayer) then
        return
    endif
    if mode == CAMERA_MODE_ADVANCED then
        call CC_ClearKeyState(whichPlayer)
        call CC_UpdateLoopState()
        call CC_ApplyAdvancedMode(whichPlayer)
    elseif mode == CAMERA_MODE_DEVELOPER then
        call CC_ClearKeyState(whichPlayer)
        call CC_UpdateLoopState()
        call CC_ApplyDeveloperMode(whichPlayer)
    else
        call CC_ApplyNormalMode(whichPlayer)
    endif
endfunction

private function CC_ResetStoredCameraState takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)

    if CC_Mode[pid] != CAMERA_MODE_NORMAL then
        return
    endif

    if CC_ResumePending[pid] then
        set CC_ResumePending[pid] = false
        set CC_Suspended[pid] = false
        call PauseTimer(CC_ResumeTimer[pid])
    elseif CC_Suspended[pid] then
        return
    endif

    call CC_ApplyMode(whichPlayer)
endfunction

private function CC_FinishSmoothResume takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_ResumePending[pid] = false
    set CC_Suspended[pid] = false
    call CC_ApplyMode(whichPlayer)
endfunction

private function CC_OnResumeTimer takes nothing returns nothing
    local integer pid = CC_FindResumeTimerPlayer(GetExpiredTimer())
    if pid >= 0 then
        call CC_FinishSmoothResume(Player(pid))
    endif
endfunction

public function RefreshTarget takes player whichPlayer returns nothing
    set CC_TargetUnit[CC_GetPlayerIndex(whichPlayer)] = CC_GetFallbackTarget(whichPlayer)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetTargetUnit takes player whichPlayer, unit whichUnit returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)

    if IsTrackedCameraUnit(whichUnit) and GetHandleId(whichUnit) != 0 and GetWidgetLife(whichUnit) > 0.405 then
        set CC_TargetUnit[pid] = whichUnit
        if not CC_Suspended[pid] and not CC_ResumePending[pid] then
            call CC_ApplyMode(whichPlayer)
        endif
        return
    endif

    set CC_TargetUnit[pid] = null
endfunction

public function UpdateTargetCache takes player whichPlayer returns nothing
    set CC_TargetUnit[CC_GetPlayerIndex(whichPlayer)] = CC_GetFallbackTarget(whichPlayer)
endfunction

public function GetTargetUnit takes player whichPlayer returns unit
    return CC_GetFallbackTarget(whichPlayer)
endfunction

public function GetTargetName takes player whichPlayer returns string
    local unit u = CC_GetFallbackTarget(whichPlayer)
    if u == null then
        return "No target"
    endif
    if IsUnitType(u, UNIT_TYPE_HERO) then
        return GetHeroProperName(u)
    endif
    return GetUnitName(u)
endfunction

public function GetMode takes player whichPlayer returns integer
    return CC_Mode[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function GetModeName takes player whichPlayer returns string
    local integer mode = GetMode(whichPlayer)
    if mode == CAMERA_MODE_ADVANCED then
        return "Advanced"
    elseif mode == CAMERA_MODE_DEVELOPER then
        return "Developer"
    endif
    return "Normal"
endfunction

public function GetDistance takes player whichPlayer returns real
    return CC_Distance[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function GetFarZ takes player whichPlayer returns real
    return CC_FarZ[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function GetAngle takes player whichPlayer returns real
    return CC_Angle[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function GetRotation takes player whichPlayer returns real
    return CC_Rotation[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function GetFov takes player whichPlayer returns real
    return CC_Fov[CC_GetPlayerIndex(whichPlayer)]
endfunction

public function SetDistance takes player whichPlayer, real value returns nothing
    set CC_Distance[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetFarZ takes player whichPlayer, real value returns nothing
    set CC_FarZ[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_FARZ_MIN, CAMERA_FARZ_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetAngle takes player whichPlayer, real value returns nothing
    set CC_Angle[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_ANGLE_MIN, CAMERA_ANGLE_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetRotation takes player whichPlayer, real value returns nothing
    set CC_Rotation[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_ROTATION_MIN, CAMERA_ROTATION_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetFov takes player whichPlayer, real value returns nothing
    set CC_Fov[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function ResetDefaults takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_Distance[pid] = CAMERA_DEFAULT_DISTANCE
    set CC_FarZ[pid] = CAMERA_DEFAULT_FARZ
    set CC_Angle[pid] = CAMERA_DEFAULT_ANGLE
    set CC_Rotation[pid] = CAMERA_DEFAULT_ROTATION
    set CC_Fov[pid] = CAMERA_DEFAULT_FOV
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetModeNormal takes player whichPlayer returns nothing
    set CC_Mode[CC_GetPlayerIndex(whichPlayer)] = CAMERA_MODE_NORMAL
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetModeAdvanced takes player whichPlayer returns nothing
    set CC_Mode[CC_GetPlayerIndex(whichPlayer)] = CAMERA_MODE_ADVANCED
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetModeDeveloper takes player whichPlayer returns nothing
    set CC_Mode[CC_GetPlayerIndex(whichPlayer)] = CAMERA_MODE_DEVELOPER
    call CC_ApplyMode(whichPlayer)
endfunction

public function Suspend takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_Suspended[pid] = true
    set CC_ResumePending[pid] = false
    call PauseTimer(CC_ResumeTimer[pid])
    call CC_ClearKeyState(whichPlayer)
    call CC_UpdateLoopState()
    call FCL_Release(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
endfunction

public function ResumeQuick takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_ResumePending[pid] = false
    set CC_Suspended[pid] = false
    call CC_ApplyMode(whichPlayer)
endfunction

public function ResumeWithDuration takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local integer mode = CC_Mode[pid]

    if duration <= 0.00 then
        call ResumeQuick(whichPlayer)
        return
    endif

    set CC_ResumePending[pid] = false
    call PauseTimer(CC_ResumeTimer[pid])
    call CC_ClearKeyState(whichPlayer)
    call CC_UpdateLoopState()

    if mode == CAMERA_MODE_ADVANCED then
        set CC_ResumePending[pid] = true
        call CC_StartSmoothResumeVisualWithDuration(whichPlayer, duration)
        call TimerStart(CC_ResumeTimer[pid], duration, false, function CC_OnResumeTimer)
    elseif mode == CAMERA_MODE_DEVELOPER then
        set CC_Suspended[pid] = false
        call CC_BindDeveloperMode(whichPlayer)
        call CC_ApplyDirectFields(whichPlayer, duration)
    else
        set CC_ResumePending[pid] = true
        call CC_StartSmoothResumeVisualWithDuration(whichPlayer, duration)
        call TimerStart(CC_ResumeTimer[pid], duration, false, function CC_OnResumeTimer)
    endif
endfunction

public function Resume takes player whichPlayer returns nothing
    call ResumeWithDuration(whichPlayer, CAMERA_RESUME_DURATION)
endfunction

public function SuspendAll takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        call Suspend(Player(i))
        set i = i + 1
    endloop
endfunction

public function ResumeAll takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        call Resume(Player(i))
        set i = i + 1
    endloop
endfunction

public function ResumeAllQuick takes nothing returns nothing
    local integer i = 0

    loop
        exitwhen i >= bj_MAX_PLAYERS
        call ResumeQuick(Player(i))
        set i = i + 1
    endloop
endfunction

public function IsSuspended takes player whichPlayer returns boolean
    return CC_IsSuspended(whichPlayer)
endfunction

private function CC_OnLeftDown takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingLeft[pid] = true
    set CC_MoveRight[pid] = false
    set CC_MoveLeft[pid] = true
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnLeftUp takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingLeft[pid] = false
    set CC_MoveLeft[pid] = false
    if CC_PressingRight[pid] then
        set CC_MoveRight[pid] = true
    endif
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnRightDown takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingRight[pid] = true
    set CC_MoveLeft[pid] = false
    set CC_MoveRight[pid] = true
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnRightUp takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingRight[pid] = false
    set CC_MoveRight[pid] = false
    if CC_PressingLeft[pid] then
        set CC_MoveLeft[pid] = true
    endif
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnUpDown takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingUp[pid] = true
    set CC_MoveDown[pid] = false
    set CC_MoveUp[pid] = true
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnUpUp takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingUp[pid] = false
    set CC_MoveUp[pid] = false
    if CC_PressingDown[pid] then
        set CC_MoveDown[pid] = true
    endif
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnDownDown takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingDown[pid] = true
    set CC_MoveUp[pid] = false
    set CC_MoveDown[pid] = true
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_OnDownUp takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid

    if not CC_IsKeyboardModeActive(whichPlayer) then
        set whichPlayer = null
        return
    endif

    set pid = CC_GetPlayerIndex(whichPlayer)
    set CC_PressingDown[pid] = false
    set CC_MoveDown[pid] = false
    if CC_PressingUp[pid] then
        set CC_MoveUp[pid] = true
    endif
    call CC_UpdateLoopState()

    set whichPlayer = null
endfunction

private function CC_SelectAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if IsTrackedCameraUnit(GetTriggerUnit()) then
        if not CC_Suspended[pid] and not CC_ResumePending[pid] then
            set CC_TargetUnit[pid] = GetTriggerUnit()
            call CC_ApplyMode(whichPlayer)
        endif
    endif
    set whichPlayer = null
endfunction

private function CC_PageResetAction takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()

    if CC_IsNativeResetProtectionActive(whichPlayer) then
        call CC_ResetStoredCameraState(whichPlayer)
    endif

    set whichPlayer = null
endfunction

public function Init takes nothing returns nothing
    local integer i = 0
    local framehandle gameUI
    local framehandle worldFrame
    if CC_Initialized then
        return
    endif
    set CC_Initialized = true

    loop
        exitwhen i >= bj_MAX_PLAYERS
        set CC_Mode[i] = CAMERA_MODE_NORMAL
        set CC_Distance[i] = CAMERA_DEFAULT_DISTANCE
        set CC_FarZ[i] = CAMERA_DEFAULT_FARZ
        set CC_Angle[i] = CAMERA_DEFAULT_ANGLE
        set CC_Rotation[i] = CAMERA_DEFAULT_ROTATION
        set CC_Fov[i] = CAMERA_DEFAULT_FOV
        set CC_TargetUnit[i] = null
        set CC_ResumeTimer[i] = CreateTimer()
        set i = i + 1
    endloop

    set CC_UpdateTimer = CreateTimer()
    set CC_DriftTimer = CreateTimer()
    call TimerStart(CC_DriftTimer, CAMERA_DRIFT_CHECK_INTERVAL, true, function CC_CheckCameraDrift)

    set CC_SelectTrigger = CreateTrigger()
    set CC_LeftDownTrigger = CreateTrigger()
    set CC_LeftUpTrigger = CreateTrigger()
    set CC_RightDownTrigger = CreateTrigger()
    set CC_RightUpTrigger = CreateTrigger()
    set CC_UpDownTrigger = CreateTrigger()
    set CC_UpUpTrigger = CreateTrigger()
    set CC_DownDownTrigger = CreateTrigger()
    set CC_DownUpTrigger = CreateTrigger()
    set CC_PageResetTrigger = CreateTrigger()
    set CC_WheelResetTrigger = CreateTrigger()
    set i = 0
    loop
        exitwhen i >= bj_MAX_PLAYERS
        call TriggerRegisterPlayerUnitEvent(CC_SelectTrigger, Player(i), EVENT_PLAYER_UNIT_SELECTED, null)
        call TriggerRegisterPlayerEvent(CC_LeftDownTrigger, Player(i), EVENT_PLAYER_ARROW_LEFT_DOWN)
        call TriggerRegisterPlayerEvent(CC_LeftUpTrigger, Player(i), EVENT_PLAYER_ARROW_LEFT_UP)
        call TriggerRegisterPlayerEvent(CC_RightDownTrigger, Player(i), EVENT_PLAYER_ARROW_RIGHT_DOWN)
        call TriggerRegisterPlayerEvent(CC_RightUpTrigger, Player(i), EVENT_PLAYER_ARROW_RIGHT_UP)
        call TriggerRegisterPlayerEvent(CC_UpDownTrigger, Player(i), EVENT_PLAYER_ARROW_UP_DOWN)
        call TriggerRegisterPlayerEvent(CC_UpUpTrigger, Player(i), EVENT_PLAYER_ARROW_UP_UP)
        call TriggerRegisterPlayerEvent(CC_DownDownTrigger, Player(i), EVENT_PLAYER_ARROW_DOWN_DOWN)
        call TriggerRegisterPlayerEvent(CC_DownUpTrigger, Player(i), EVENT_PLAYER_ARROW_DOWN_UP)
        call BlzTriggerRegisterPlayerKeyEvent(CC_PageResetTrigger, Player(i), OSKEY_PAGEUP, 0, true)
        call BlzTriggerRegisterPlayerKeyEvent(CC_PageResetTrigger, Player(i), OSKEY_PAGEUP, 0, false)
        call BlzTriggerRegisterPlayerKeyEvent(CC_PageResetTrigger, Player(i), OSKEY_PAGEDOWN, 0, true)
        call BlzTriggerRegisterPlayerKeyEvent(CC_PageResetTrigger, Player(i), OSKEY_PAGEDOWN, 0, false)
        set i = i + 1
    endloop
    call TriggerAddAction(CC_SelectTrigger, function CC_SelectAction)
    call TriggerAddAction(CC_LeftDownTrigger, function CC_OnLeftDown)
    call TriggerAddAction(CC_LeftUpTrigger, function CC_OnLeftUp)
    call TriggerAddAction(CC_RightDownTrigger, function CC_OnRightDown)
    call TriggerAddAction(CC_RightUpTrigger, function CC_OnRightUp)
    call TriggerAddAction(CC_UpDownTrigger, function CC_OnUpDown)
    call TriggerAddAction(CC_UpUpTrigger, function CC_OnUpUp)
    call TriggerAddAction(CC_DownDownTrigger, function CC_OnDownDown)
    call TriggerAddAction(CC_DownUpTrigger, function CC_OnDownUp)
    call TriggerAddAction(CC_PageResetTrigger, function CC_PageResetAction)

    set gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    if gameUI != null then
        call BlzTriggerRegisterFrameEvent(CC_WheelResetTrigger, gameUI, FRAMEEVENT_MOUSE_WHEEL)
    endif

    set worldFrame = BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0)
    if worldFrame != null then
        call BlzTriggerRegisterFrameEvent(CC_WheelResetTrigger, worldFrame, FRAMEEVENT_MOUSE_WHEEL)
    endif

    call TriggerAddAction(CC_WheelResetTrigger, function CC_PageResetAction)

    set gameUI = null
    set worldFrame = null
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
