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
    public constant integer CAMERA_SPECIAL_MODE_NONE = 0
    public constant integer CAMERA_SPECIAL_MODE_BOOMMINE = 1
    // Add more special camera mode ids here as needed.
    // Keep them unique and then define their preset values in CC_InitSpecialModeConfigs().
    public constant integer CAMERA_SPECIAL_MODE_TEMPLATE01 = 101
    public constant integer CAMERA_SPECIAL_MODE_TEMPLATE02 = 102

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
    private constant real CAMERA_NORMAL_TRACE_ACCURACY = 50.00
    private constant real CAMERA_NORMAL_TRACE_FINE_ACCURACY = 10.00
    private constant real CAMERA_NORMAL_TRACE_ITEM_RANGE = 1.00
    private constant real CAMERA_NORMAL_TRACE_MIN_DISTANCE = 400.00
    private constant real CAMERA_NORMAL_TRACE_MIN_DISTANCE_FACTOR = 0.65
    private constant real CAMERA_NORMAL_TRACE_IGNORE_END_DISTANCE = 250.00
    private constant real CAMERA_NORMAL_TRACE_MAX_REDUCTION = 300.00
    private constant real CAMERA_NORMAL_TRACE_MAX_REDUCTION_FACTOR = 0.18
    private constant real CAMERA_NORMAL_TRACE_POSITION_THRESHOLD = 24.00
    private constant real CAMERA_NORMAL_TRACE_ROTATION_THRESHOLD = 0.50
    private constant real CAMERA_NORMAL_TRACE_DISTANCE_THRESHOLD = 1.00
    private constant real CAMERA_NORMAL_TRACE_CORRECTION_DURATION = 0.25
    private constant real CAMERA_RESUME_DURATION = 2.00
    private constant real CAMERA_WOUNDED_THRESHOLD = 0.25
    private constant real CAMERA_WOUNDED_ENTRY_DURATION = 1.00
    private constant real CAMERA_WOUNDED_BASE_TRANSPARENCY = 50.00
    private constant real CAMERA_WOUNDED_PULSE_TRANSPARENCY_DELTA = 18.00
    private constant real CAMERA_WOUNDED_PULSE_DECAY = 0.92
    private constant integer CAMERA_WOUNDED_SECOND_BEAT_DELAY_TICKS = 7
    private constant integer CAMERA_WOUNDED_BEAT_MIN_TICKS = 34
    private constant integer CAMERA_WOUNDED_BEAT_MAX_TICKS = 48
    private constant string CAMERA_WOUNDED_FILTER_TEXTURE = "ReplaceableTextures\\CameraMasks\\DiagonalSlash_mask.blp"
    private constant string CAMERA_WOUNDED_HEARTBEAT_SOUND = "war3mapImported\\Heartbeat.mp3"
    private constant integer CC_MAX_SPECIAL_CAMERA_RECTS = 16

    private boolean CC_Initialized = false
    private boolean CC_UpdateLoopActive = false

    private integer array CC_Mode
    private integer array CC_SpecialMode
    private integer array CC_RectSpecialMode
    private string array CC_SpecialModeLabel
    private boolean array CC_SpecialModeKeyboardAdjustable
    private real array CC_SpecialModeDistanceConfig
    private real array CC_SpecialModeFarZConfig
    private real array CC_SpecialModeAngleConfig
    private real array CC_SpecialModeRotationConfig
    private real array CC_SpecialModeFovConfig
    private real array CC_SpecialModeAngleMaxConfig
    private real array CC_Distance
    private real array CC_FarZ
    private real array CC_Angle
    private real array CC_Rotation
    private real array CC_Fov
    private real array CC_NormalEffectiveDistance
    private real array CC_NormalEffectiveAngle
    private real array CC_NormalTraceX
    private real array CC_NormalTraceY
    private real array CC_NormalTraceRotation
    private real array CC_NormalTraceDistance
    private real array CC_SpecialAngle
    private real array CC_SpecialRotation
    private integer array CC_NormalTraceTargetHandle
    private boolean array CC_NormalTraceEnabled
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
    private boolean array CC_WoundedActive
    private timer array CC_ResumeTimer
    private integer array CC_WoundedSeed
    private integer array CC_WoundedNextBeatTicks
    private integer array CC_WoundedSecondBeatTicks
    private real array CC_WoundedPulse

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
    private item CC_PathingProbe = null
    private rect CC_PathingProbeRect = null
    private item array CC_HiddenPathItems
    private integer CC_HiddenPathItemCount = 0
    private location CC_TerrainLoc = null
    private integer CC_SpecialCameraRectCount = 0
    private rect array CC_SpecialCameraRects
    private integer array CC_SpecialCameraRectModes
    private trigger array CC_SpecialCameraEnterTriggers
    private trigger array CC_SpecialCameraLeaveTriggers
    private trigger CC_ChatResetTrigger = null
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

private function CC_NormalizeAngle takes real value returns real
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

private function CC_IsPointPathableRaw takes real x, real y returns boolean
    local real dx
    local real dy

    call SetItemVisible(CC_PathingProbe, true)
    call SetItemPosition(CC_PathingProbe, x, y)
    set dx = GetItemX(CC_PathingProbe) - x
    set dy = GetItemY(CC_PathingProbe) - y
    call SetItemVisible(CC_PathingProbe, false)

    return dx < CAMERA_NORMAL_TRACE_ITEM_RANGE and dx > -CAMERA_NORMAL_TRACE_ITEM_RANGE and dy < CAMERA_NORMAL_TRACE_ITEM_RANGE and dy > -CAMERA_NORMAL_TRACE_ITEM_RANGE
endfunction

private function CC_HideBlockingItems takes nothing returns nothing
    if IsItemVisible(GetEnumItem()) then
        set CC_HiddenPathItems[CC_HiddenPathItemCount] = GetEnumItem()
        call SetItemVisible(CC_HiddenPathItems[CC_HiddenPathItemCount], false)
        set CC_HiddenPathItemCount = CC_HiddenPathItemCount + 1
    endif
endfunction

private function CC_RestoreHiddenPathItems takes nothing returns nothing
    loop
        exitwhen CC_HiddenPathItemCount == 0
        set CC_HiddenPathItemCount = CC_HiddenPathItemCount - 1
        call SetItemVisible(CC_HiddenPathItems[CC_HiddenPathItemCount], true)
    endloop
endfunction

private function CC_IsPointPathable takes real x, real y returns boolean
    if CC_IsPointPathableRaw(x, y) then
        return true
    endif

    set CC_HiddenPathItemCount = 0
    call MoveRectTo(CC_PathingProbeRect, x, y)
    call EnumItemsInRect(CC_PathingProbeRect, null, function CC_HideBlockingItems)
    if CC_IsPointPathableRaw(x, y) then
        call CC_RestoreHiddenPathItems()
        return true
    endif
    call CC_RestoreHiddenPathItems()
    return false
endfunction

private function CC_GetTerrainZ takes real x, real y returns real
    call MoveLocation(CC_TerrainLoc, x, y)
    return GetLocationZ(CC_TerrainLoc)
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

private function CC_GetCurrentCameraUnit takes player whichPlayer returns unit
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if CC_Mode[pid] == CAMERA_MODE_DEVELOPER or CC_Suspended[pid] then
        return null
    endif
    return CC_GetFallbackTarget(whichPlayer)
endfunction

private function CC_GetLifeRatio takes unit whichUnit returns real
    local real maxLife
    if whichUnit == null or GetHandleId(whichUnit) == 0 or GetWidgetLife(whichUnit) <= 0.405 then
        return 0.00
    endif
    set maxLife = GetUnitState(whichUnit, UNIT_STATE_MAX_LIFE)
    if maxLife <= 0.00 then
        return 0.00
    endif
    return GetUnitState(whichUnit, UNIT_STATE_LIFE) / maxLife
endfunction

private function CC_ResetWoundedState takes integer pid, player whichPlayer returns nothing
    local boolean hadVisual = CC_WoundedActive[pid] or CC_WoundedPulse[pid] > 0.00
    set CC_WoundedActive[pid] = false
    set CC_WoundedNextBeatTicks[pid] = 0
    set CC_WoundedSecondBeatTicks[pid] = 0
    set CC_WoundedPulse[pid] = 0.00
    if hadVisual and GetLocalPlayer() == whichPlayer then
        call DisplayCineFilter(false)
    endif
endfunction

private function CC_GetNextWoundedBeatTicks takes integer pid, real lifeRatio returns integer
    local integer minTicks = CAMERA_WOUNDED_BEAT_MIN_TICKS
    local integer maxTicks = CAMERA_WOUNDED_BEAT_MAX_TICKS
    local integer range
    set CC_WoundedSeed[pid] = ModuloInteger(CC_WoundedSeed[pid] * 73 + 19, 997)
    set maxTicks = maxTicks - R2I((CAMERA_WOUNDED_THRESHOLD - lifeRatio) * 32.00)
    if maxTicks < minTicks + 4 then
        set maxTicks = minTicks + 4
    endif
    set range = maxTicks - minTicks + 1
    return minTicks + ModuloInteger(CC_WoundedSeed[pid], range)
endfunction

private function CC_PlayWoundedHeartbeatSound takes player whichPlayer returns nothing
    local sound s
    if GetLocalPlayer() == whichPlayer then
        set s = CreateSound(CAMERA_WOUNDED_HEARTBEAT_SOUND, false, false, false, 10, 10, "")
        call StartSound(s)
        call KillSoundWhenDone(s)
        set s = null
    endif
endfunction

private function CC_GetCineFilterAlphaFromTransparency takes real transparency returns integer
    return R2I(255.00 * (100.00 - CC_Clamp(transparency, 0.00, 100.00)) / 100.00)
endfunction

private function CC_ShowWoundedFilter takes player whichPlayer, real transparency, boolean entering returns nothing
    local integer alphaInt = CC_GetCineFilterAlphaFromTransparency(transparency)
    if GetLocalPlayer() == whichPlayer then
        call SetCineFilterTexture(CAMERA_WOUNDED_FILTER_TEXTURE)
        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterStartUV(0.00, 0.00, 1.00, 1.00)
        call SetCineFilterEndUV(0.00, 0.00, 1.00, 1.00)
        if entering then
            call SetCineFilterStartColor(255, 255, 255, 0)
            call SetCineFilterEndColor(255, 0, 0, alphaInt)
            call SetCineFilterDuration(CAMERA_WOUNDED_ENTRY_DURATION)
        else
            call SetCineFilterStartColor(255, 0, 0, alphaInt)
            call SetCineFilterEndColor(255, 0, 0, alphaInt)
            call SetCineFilterDuration(0.00)
        endif
        call DisplayCineFilter(true)
    endif
endfunction

private function CC_UpdateWoundedState takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local unit whichUnit = CC_GetCurrentCameraUnit(whichPlayer)
    local real lifeRatio

    if whichUnit == null then
        call CC_ResetWoundedState(pid, whichPlayer)
        set whichUnit = null
        return
    endif

    set lifeRatio = CC_GetLifeRatio(whichUnit)
    if lifeRatio <= 0.00 or lifeRatio > CAMERA_WOUNDED_THRESHOLD then
        call CC_ResetWoundedState(pid, whichPlayer)
        set whichUnit = null
        return
    endif

    if not CC_WoundedActive[pid] then
        set CC_WoundedActive[pid] = true
        set CC_WoundedSeed[pid] = 137 + pid*41
        set CC_WoundedNextBeatTicks[pid] = 1
        set CC_WoundedSecondBeatTicks[pid] = 0
        set CC_WoundedPulse[pid] = 0.00
        call CC_ShowWoundedFilter(whichPlayer, CAMERA_WOUNDED_BASE_TRANSPARENCY, true)
    endif

    if CC_WoundedSecondBeatTicks[pid] > 0 then
        set CC_WoundedSecondBeatTicks[pid] = CC_WoundedSecondBeatTicks[pid] - 1
        if CC_WoundedSecondBeatTicks[pid] == 0 then
            set CC_WoundedPulse[pid] = CC_WoundedPulse[pid] + 0.55
            if CC_WoundedPulse[pid] > 1.20 then
                set CC_WoundedPulse[pid] = 1.20
            endif
            call CC_PlayWoundedHeartbeatSound(whichPlayer)
        endif
    endif

    if CC_WoundedNextBeatTicks[pid] > 0 then
        set CC_WoundedNextBeatTicks[pid] = CC_WoundedNextBeatTicks[pid] - 1
    endif
    if CC_WoundedNextBeatTicks[pid] <= 0 then
        set CC_WoundedPulse[pid] = 1.00
        set CC_WoundedSecondBeatTicks[pid] = CAMERA_WOUNDED_SECOND_BEAT_DELAY_TICKS
        set CC_WoundedNextBeatTicks[pid] = CC_GetNextWoundedBeatTicks(pid, lifeRatio)
        call CC_PlayWoundedHeartbeatSound(whichPlayer)
    endif

    set CC_WoundedPulse[pid] = CC_WoundedPulse[pid] * CAMERA_WOUNDED_PULSE_DECAY
    if CC_WoundedPulse[pid] < 0.02 then
        set CC_WoundedPulse[pid] = 0.00
    endif
    call CC_ShowWoundedFilter(whichPlayer, CAMERA_WOUNDED_BASE_TRANSPARENCY - CAMERA_WOUNDED_PULSE_TRANSPARENCY_DELTA * CC_WoundedPulse[pid], false)

    set whichUnit = null
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

private function CC_GetResolvedSpecialMode takes integer pid returns integer
    if CC_RectSpecialMode[pid] != CAMERA_SPECIAL_MODE_NONE then
        return CC_RectSpecialMode[pid]
    endif
    return CC_SpecialMode[pid]
endfunction

private function CC_DefineSpecialMode takes integer specialMode, string label, real distance, real farZ, real angle, real rotation, real fov, boolean keyboardAdjustable, real angleMax returns nothing
    // keyboardAdjustable controls whether arrow keys can change this special mode's angle/rotation.
    // - true  = this mode uses CC_SpecialAngle / CC_SpecialRotation and arrow-key updates stay active.
    // - false = this mode uses the fixed angle/rotation values defined here.
    // angleMax only matters when keyboardAdjustable=true.
    if specialMode == CAMERA_SPECIAL_MODE_NONE then
        return
    endif
    set CC_SpecialModeLabel[specialMode] = label
    set CC_SpecialModeDistanceConfig[specialMode] = distance
    set CC_SpecialModeFarZConfig[specialMode] = farZ
    set CC_SpecialModeAngleConfig[specialMode] = angle
    set CC_SpecialModeRotationConfig[specialMode] = rotation
    set CC_SpecialModeFovConfig[specialMode] = fov
    set CC_SpecialModeKeyboardAdjustable[specialMode] = keyboardAdjustable
    if angleMax < CAMERA_ANGLE_MIN then
        set CC_SpecialModeAngleMaxConfig[specialMode] = CAMERA_ANGLE_MAX
    else
        set CC_SpecialModeAngleMaxConfig[specialMode] = angleMax
    endif
endfunction

private function CC_InitSpecialModeConfigs takes nothing returns nothing
    // Adding a new special camera mode:
    // 1. Add a new CAMERA_SPECIAL_MODE_* id in globals above.
    // 2. Add one CC_DefineSpecialMode(...) line here with the mode's label and camera values.
    // 3. Decide if arrow-key camera control should be active for that mode:
    //    - keyboardAdjustable=true  => left/right rotate and up/down change angle for this special mode.
    //    - keyboardAdjustable=false => the mode keeps its fixed configured angle/rotation only.
    //    Give an angleMax when keyboardAdjustable=true.
    // 4. If the mode should activate from a camera-local rect, register that rect in CC_RegisterBuiltInSpecialCameraRects().
    // 5. Leave ZoneEvent-owned zone camera switching in ZoneEvent.
    call CC_DefineSpecialMode(CAMERA_SPECIAL_MODE_BOOMMINE, "Boom Mine", 1600.00, 5000.00, 270.00, 90.00, 70.00, true, 295.00)
    call CC_DefineSpecialMode(CAMERA_SPECIAL_MODE_TEMPLATE01, "Template 01", 1800.00, 6000.00, 285.00, 90.00, 70.00, false, CAMERA_ANGLE_MAX)
    call CC_DefineSpecialMode(CAMERA_SPECIAL_MODE_TEMPLATE02, "Template 02", 1400.00, 4500.00, 300.00, 180.00, 65.00, false, CAMERA_ANGLE_MAX)
endfunction

private function CC_IsSpecialModeKeyboardAdjustable takes integer specialMode returns boolean
    // Central per-special-mode switch for arrow-key camera control.
    return specialMode != CAMERA_SPECIAL_MODE_NONE and CC_SpecialModeKeyboardAdjustable[specialMode]
endfunction

private function CC_IsResolvedSpecialModeKeyboardAdjustable takes integer pid returns boolean
    return CC_IsSpecialModeKeyboardAdjustable(CC_GetResolvedSpecialMode(pid))
endfunction

private function CC_GetConfiguredSpecialModeAngle takes integer specialMode returns real
    if specialMode == CAMERA_SPECIAL_MODE_NONE then
        return CAMERA_DEFAULT_ANGLE
    endif
    return CC_SpecialModeAngleConfig[specialMode]
endfunction

private function CC_GetConfiguredSpecialModeRotation takes integer specialMode returns real
    if specialMode == CAMERA_SPECIAL_MODE_NONE then
        return CAMERA_DEFAULT_ROTATION
    endif
    return CC_SpecialModeRotationConfig[specialMode]
endfunction

private function CC_GetConfiguredSpecialModeAngleMax takes integer specialMode returns real
    if specialMode == CAMERA_SPECIAL_MODE_NONE or CC_SpecialModeAngleMaxConfig[specialMode] <= 0.00 then
        return CAMERA_ANGLE_MAX
    endif
    return CC_SpecialModeAngleMaxConfig[specialMode]
endfunction

private function CC_HasSpecialMode takes integer pid returns boolean
    return CC_GetResolvedSpecialMode(pid) != CAMERA_SPECIAL_MODE_NONE
endfunction

private function CC_IsKeyboardModeActive takes player whichPlayer returns boolean
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if CC_Suspended[pid] or CC_ResumePending[pid] then
        return false
    endif
    // Special modes opt into arrow-key control through CC_DefineSpecialMode(..., keyboardAdjustable, ...).
    if CC_IsResolvedSpecialModeKeyboardAdjustable(pid) then
        return true
    endif
    return CC_Mode[pid] == CAMERA_MODE_NORMAL and not CC_HasSpecialMode(pid)
endfunction

private function CC_IsNativeResetProtectionActive takes player whichPlayer returns boolean
    return false
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

private function CC_InvalidateNormalTraceCache takes integer pid returns nothing
    set CC_NormalTraceTargetHandle[pid] = 0
    set CC_NormalTraceX[pid] = 0.00
    set CC_NormalTraceY[pid] = 0.00
    set CC_NormalTraceRotation[pid] = 0.00
    set CC_NormalTraceDistance[pid] = 0.00
endfunction

private function CC_IsPlayerKeyboardAdjusting takes integer pid returns boolean
    return CC_PressingLeft[pid] or CC_PressingRight[pid] or CC_PressingUp[pid] or CC_PressingDown[pid] or CC_MoveLeft[pid] or CC_MoveRight[pid] or CC_MoveUp[pid] or CC_MoveDown[pid]
endfunction

private function CC_GetSpecialDistance takes integer pid returns real
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if specialMode != CAMERA_SPECIAL_MODE_NONE then
        return CC_SpecialModeDistanceConfig[specialMode]
    endif
    return CC_Distance[pid]
endfunction

private function CC_GetSpecialFarZ takes integer pid returns real
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if specialMode != CAMERA_SPECIAL_MODE_NONE then
        return CC_SpecialModeFarZConfig[specialMode]
    endif
    return CC_FarZ[pid]
endfunction

private function CC_GetSpecialAngle takes integer pid returns real
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if CC_IsSpecialModeKeyboardAdjustable(specialMode) then
        return CC_SpecialAngle[pid]
    elseif specialMode != CAMERA_SPECIAL_MODE_NONE then
        return CC_SpecialModeAngleConfig[specialMode]
    endif
    return CC_Angle[pid]
endfunction

private function CC_GetSpecialRotation takes integer pid returns real
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if CC_IsSpecialModeKeyboardAdjustable(specialMode) then
        return CC_SpecialRotation[pid]
    elseif specialMode != CAMERA_SPECIAL_MODE_NONE then
        return CC_SpecialModeRotationConfig[specialMode]
    endif
    return CC_Rotation[pid]
endfunction

private function CC_GetSpecialFov takes integer pid returns real
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if specialMode != CAMERA_SPECIAL_MODE_NONE then
        return CC_SpecialModeFovConfig[specialMode]
    endif
    return CC_Fov[pid]
endfunction

private function CC_GetSpecialModeName takes integer pid returns string
    local integer specialMode = CC_GetResolvedSpecialMode(pid)
    if specialMode != CAMERA_SPECIAL_MODE_NONE and CC_SpecialModeLabel[specialMode] != "" then
        return CC_SpecialModeLabel[specialMode]
    endif
    return ""
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

private function CC_UpdateNormalEffectiveDistance takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local unit target = CC_GetFallbackTarget(whichPlayer)
    local integer targetHandle = 0
    local real baseX
    local real baseY
    local real x
    local real y
    local real angle
    local real maxDistance = CC_Distance[pid]
    local real distanceDone = 0.00
    local real checkDistance = CAMERA_NORMAL_TRACE_ACCURACY
    local real terrainBaseAngle = CC_Angle[pid] - 324.00
    local real baseTerrainZ
    local real sampledTerrainZ
    local real minDistance
    local real maxReduction
    local real rz = 0.00
    local integer check = 1

    if not CC_NormalTraceEnabled[pid] then
        set CC_NormalEffectiveDistance[pid] = maxDistance
        set CC_NormalEffectiveAngle[pid] = CC_Angle[pid]
        call CC_InvalidateNormalTraceCache(pid)
        set target = null
        return
    endif

    if target == null or IsUnitType(target, UNIT_TYPE_FLYING) then
        set CC_NormalEffectiveDistance[pid] = maxDistance
        set CC_NormalEffectiveAngle[pid] = CC_Angle[pid]
        call CC_InvalidateNormalTraceCache(pid)
        set target = null
        return
    endif

    set targetHandle = GetHandleId(target)
    set baseX = GetUnitX(target)
    set baseY = GetUnitY(target)
    if CC_NormalTraceTargetHandle[pid] == targetHandle and CC_Abs(baseX - CC_NormalTraceX[pid]) <= CAMERA_NORMAL_TRACE_POSITION_THRESHOLD and CC_Abs(baseY - CC_NormalTraceY[pid]) <= CAMERA_NORMAL_TRACE_POSITION_THRESHOLD and CC_GetRotationDelta(CC_Rotation[pid], CC_NormalTraceRotation[pid]) <= CAMERA_NORMAL_TRACE_ROTATION_THRESHOLD and CC_Abs(maxDistance - CC_NormalTraceDistance[pid]) <= CAMERA_NORMAL_TRACE_DISTANCE_THRESHOLD then
        set target = null
        return
    endif

    set x = baseX
    set y = baseY
    set angle = (CC_Rotation[pid] - 180.00)*bj_DEGTORAD
    set baseTerrainZ = CC_GetTerrainZ(baseX, baseY)
    set minDistance = maxDistance * CAMERA_NORMAL_TRACE_MIN_DISTANCE_FACTOR
    set maxReduction = maxDistance * CAMERA_NORMAL_TRACE_MAX_REDUCTION_FACTOR
    if maxReduction < CAMERA_NORMAL_TRACE_MAX_REDUCTION then
        set maxReduction = CAMERA_NORMAL_TRACE_MAX_REDUCTION
    endif
    if minDistance < CAMERA_NORMAL_TRACE_MIN_DISTANCE then
        set minDistance = CAMERA_NORMAL_TRACE_MIN_DISTANCE
    endif
    if minDistance < maxDistance - maxReduction then
        set minDistance = maxDistance - maxReduction
    endif
    if minDistance > maxDistance then
        set minDistance = maxDistance
    endif

    loop
        exitwhen distanceDone >= maxDistance
        if distanceDone + checkDistance > maxDistance then
            set checkDistance = maxDistance - distanceDone
            if checkDistance <= 0.00 then
                exitwhen true
            endif
        endif

        set x = x + checkDistance * Cos(angle)
        set y = y + checkDistance * Sin(angle)
        set distanceDone = distanceDone + checkDistance
        set sampledTerrainZ = CC_GetTerrainZ(x, y)
        if distanceDone <= maxDistance * 0.50 and CC_Abs(sampledTerrainZ) > CC_Abs(rz) then
            set rz = sampledTerrainZ
        endif

        if not CC_IsPointPathable(x, y) then
            if distanceDone >= maxDistance - CAMERA_NORMAL_TRACE_IGNORE_END_DISTANCE then
                set distanceDone = maxDistance
                exitwhen true
            endif
            set check = 0
        endif
        if check == 0 and checkDistance == CAMERA_NORMAL_TRACE_ACCURACY then
            set distanceDone = distanceDone - checkDistance
            set x = x - checkDistance * Cos(angle)
            set y = y - checkDistance * Sin(angle)
            set check = 1
            set checkDistance = CAMERA_NORMAL_TRACE_FINE_ACCURACY
        endif
        exitwhen (check == 0 and checkDistance == CAMERA_NORMAL_TRACE_FINE_ACCURACY) or distanceDone > maxDistance
    endloop

    if distanceDone < minDistance then
        set distanceDone = minDistance
    endif
    set CC_NormalTraceTargetHandle[pid] = targetHandle
    set CC_NormalTraceX[pid] = baseX
    set CC_NormalTraceY[pid] = baseY
    set CC_NormalTraceRotation[pid] = CC_Rotation[pid]
    set CC_NormalTraceDistance[pid] = maxDistance
    set CC_NormalEffectiveDistance[pid] = distanceDone
    loop
        exitwhen baseTerrainZ - rz < 180.00
        set baseTerrainZ = baseTerrainZ - 180.00
    endloop
    set CC_NormalEffectiveAngle[pid] = CC_NormalizeAngle(Atan2(baseTerrainZ - rz, 200.00) * bj_RADTODEG + terrainBaseAngle + 324.00)
    set target = null
endfunction

private function CC_ApplySharedFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_FARZ, CC_FarZ[pid], duration)
        call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, CC_Fov[pid], duration)
    endif
endfunction

private function CC_ApplySpecialFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_FARZ, CC_GetSpecialFarZ(pid), duration)
        call SetCameraField(CAMERA_FIELD_FIELD_OF_VIEW, CC_GetSpecialFov(pid), duration)
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_GetSpecialDistance(pid), duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_GetSpecialAngle(pid), duration)
        call SetCameraField(CAMERA_FIELD_ROTATION, CC_GetSpecialRotation(pid), duration)
    endif
endfunction

private function CC_ApplyNormalFields takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    call CC_ApplySharedFields(whichPlayer, duration)
    if GetLocalPlayer() == whichPlayer then
        call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, CC_NormalEffectiveDistance[pid], duration)
        call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, CC_NormalEffectiveAngle[pid], duration)
        call SetCameraField(CAMERA_FIELD_ROTATION, CC_Rotation[pid], duration)
    endif
endfunction

private function CC_UpdateAndApplyNormalFields takes player whichPlayer, real duration returns nothing
    call CC_UpdateNormalEffectiveDistance(whichPlayer)
    call CC_ApplyNormalFields(whichPlayer, duration)
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
    if CC_IsResolvedSpecialModeKeyboardAdjustable(pid) then
        call CC_ApplySpecialFields(whichPlayer, CAMERA_KEYBOARD_FIELD_DURATION)
    else
        call CC_UpdateAndApplyNormalFields(whichPlayer, CAMERA_KEYBOARD_FIELD_DURATION)
    endif
endfunction

private function CC_BindNormalMode takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_TargetUnit[pid] = CC_GetFallbackTarget(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
    if GetLocalPlayer() == whichPlayer then
        call CameraSetSmoothingFactor(1)
    endif
    if CC_TargetUnit[pid] != null then
        call FCL_Lock(CC_TargetUnit[pid], whichPlayer)
    endif
endfunction

private function CC_BindSpecialMode takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_TargetUnit[pid] = CC_GetFallbackTarget(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
    if GetLocalPlayer() == whichPlayer then
        call CameraSetSmoothingFactor(1)
    endif
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
    if GetLocalPlayer() == whichPlayer then
        call CameraSetSmoothingFactor(0)
    endif
    call FCL_Release(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
endfunction

private function CC_ApplyNormalMode takes player whichPlayer returns nothing
    call CC_BindNormalMode(whichPlayer)
    call CC_UpdateAndApplyNormalFields(whichPlayer, 0.00)
endfunction

private function CC_ApplySpecialMode takes player whichPlayer returns nothing
    call CC_BindSpecialMode(whichPlayer)
    call CC_ApplySpecialFields(whichPlayer, 0.00)
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

    if CC_HasSpecialMode(pid) then
        call CC_ApplySpecialFields(whichPlayer, duration)
    elseif CC_Mode[pid] == CAMERA_MODE_ADVANCED then
        call CC_ApplyAdvancedResumePreviewFields(whichPlayer, duration)
    elseif CC_Mode[pid] == CAMERA_MODE_NORMAL then
        call CC_ApplyNormalFields(whichPlayer, duration)
    else
        call CC_ApplyDirectFields(whichPlayer, duration)
    endif
endfunction


private function CC_StartSmoothResumeVisual takes player whichPlayer returns nothing
    call CC_StartSmoothResumeVisualWithDuration(whichPlayer, CAMERA_RESUME_DURATION)
endfunction

private function CC_UpdateKeyboardCamera takes nothing returns nothing
    local integer i = 0
    local integer specialMode
    local real specialAngleMax

    loop
        exitwhen i >= bj_MAX_PLAYERS
        set specialMode = CC_GetResolvedSpecialMode(i)
        if CC_IsSpecialModeKeyboardAdjustable(specialMode) and not CC_Suspended[i] then
            set specialAngleMax = CC_GetConfiguredSpecialModeAngleMax(specialMode)
            if CC_MoveDown[i] then
                set CC_SpecialAngle[i] = CC_SpecialAngle[i] + CAMERA_KEYBOARD_VERTICAL_SPEED
                if CC_SpecialAngle[i] > specialAngleMax then
                    set CC_SpecialAngle[i] = specialAngleMax
                endif
            elseif CC_MoveUp[i] then
                set CC_SpecialAngle[i] = CC_SpecialAngle[i] - CAMERA_KEYBOARD_VERTICAL_SPEED
                if CC_SpecialAngle[i] < CAMERA_ANGLE_MIN then
                    set CC_SpecialAngle[i] = CAMERA_ANGLE_MIN
                endif
            endif

            if CC_MoveRight[i] then
                set CC_SpecialRotation[i] = CC_SpecialRotation[i] + CAMERA_KEYBOARD_HORIZONTAL_SPEED
                if CC_SpecialRotation[i] >= 360.00 then
                    set CC_SpecialRotation[i] = CC_SpecialRotation[i] - 360.00
                endif
            elseif CC_MoveLeft[i] then
                set CC_SpecialRotation[i] = CC_SpecialRotation[i] - CAMERA_KEYBOARD_HORIZONTAL_SPEED
                if CC_SpecialRotation[i] <= 0.00 then
                    set CC_SpecialRotation[i] = CC_SpecialRotation[i] + 360.00
                endif
            endif

            call CC_ApplyKeyboardFields(Player(i))
        elseif CC_Mode[i] == CAMERA_MODE_NORMAL and not CC_Suspended[i] and not CC_HasSpecialMode(i) then
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
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if CC_HasSpecialMode(pid) then
        call CC_ApplySpecialFields(whichPlayer, CAMERA_NORMAL_TRACE_CORRECTION_DURATION)
    elseif CC_Mode[pid] == CAMERA_MODE_ADVANCED then
        call CC_ApplyAdvancedDriftFields(whichPlayer, 0.00)
    elseif CC_Mode[pid] == CAMERA_MODE_NORMAL then
        call CC_ApplyNormalFields(whichPlayer, CAMERA_NORMAL_TRACE_CORRECTION_DURATION)
    else
        call CC_ApplyDirectFields(whichPlayer, 0.00)
    endif
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
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local integer mode = CC_Mode[pid]

    if CC_IsSuspended(whichPlayer) then
        return
    endif
    if CC_HasSpecialMode(pid) then
        // Preserve held arrow-key state for special modes that are intentionally keyboard-adjustable.
        if not CC_IsResolvedSpecialModeKeyboardAdjustable(pid) then
            call CC_ClearKeyState(whichPlayer)
        endif
        call CC_UpdateLoopState()
        call CC_ApplySpecialMode(whichPlayer)
    elseif mode == CAMERA_MODE_ADVANCED then
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

private function CC_GetSpecialRectModeForUnit takes unit whichUnit returns integer
    local integer i = CC_SpecialCameraRectCount
    local real x
    local real y
    if whichUnit == null or GetHandleId(whichUnit) == 0 or GetWidgetLife(whichUnit) <= 0.405 then
        return CAMERA_SPECIAL_MODE_NONE
    endif
    set x = GetUnitX(whichUnit)
    set y = GetUnitY(whichUnit)
    loop
        exitwhen i <= 0
        if CC_SpecialCameraRects[i] != null and RectContainsCoords(CC_SpecialCameraRects[i], x, y) then
            return CC_SpecialCameraRectModes[i]
        endif
        set i = i - 1
    endloop
    return CAMERA_SPECIAL_MODE_NONE
endfunction

private function CC_GetTrackedSpecialModeForPlayer takes player whichPlayer returns integer
    local unit target = CC_GetFallbackTarget(whichPlayer)
    local integer mode = CAMERA_SPECIAL_MODE_NONE
    if IsTrackedCameraUnit(target) and GetOwningPlayer(target) == whichPlayer then
        set mode = CC_GetSpecialRectModeForUnit(target)
        if mode != CAMERA_SPECIAL_MODE_NONE then
            set target = null
            return mode
        endif
    endif
    if udg_Nazgrek != target and IsTrackedCameraUnit(udg_Nazgrek) and GetOwningPlayer(udg_Nazgrek) == whichPlayer then
        set mode = CC_GetSpecialRectModeForUnit(udg_Nazgrek)
        if mode != CAMERA_SPECIAL_MODE_NONE then
            set target = null
            return mode
        endif
    endif
    if udg_Zulkis != target and IsTrackedCameraUnit(udg_Zulkis) and GetOwningPlayer(udg_Zulkis) == whichPlayer then
        set mode = CC_GetSpecialRectModeForUnit(udg_Zulkis)
        if mode != CAMERA_SPECIAL_MODE_NONE then
            set target = null
            return mode
        endif
    endif
    set target = null
    return CAMERA_SPECIAL_MODE_NONE
endfunction

private function CC_RefreshSpecialRectState takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local integer oldResolvedMode = CC_GetResolvedSpecialMode(pid)
    local integer newRectMode = CC_GetTrackedSpecialModeForPlayer(whichPlayer)
    if CC_RectSpecialMode[pid] == newRectMode then
        return
    endif
    set CC_RectSpecialMode[pid] = newRectMode
    if oldResolvedMode != CC_GetResolvedSpecialMode(pid) then
        call CC_ClearKeyState(whichPlayer)
        call CC_UpdateLoopState()
        if not CC_Suspended[pid] and not CC_ResumePending[pid] then
            call CC_InvalidateNormalTraceCache(pid)
            call CC_ApplyMode(whichPlayer)
        endif
    endif
endfunction

private function CC_OnSpecialCameraRectEvent takes nothing returns nothing
    local unit whichUnit = GetTriggerUnit()
    local player whichPlayer
    if not IsTrackedCameraUnit(whichUnit) then
        set whichUnit = null
        return
    endif
    set whichPlayer = GetOwningPlayer(whichUnit)
    call CC_RefreshSpecialRectState(whichPlayer)
    set whichPlayer = null
    set whichUnit = null
endfunction

private function CC_RegisterSpecialCameraRect takes rect whichRect, integer specialMode returns nothing
    local integer index
    if whichRect == null or specialMode == CAMERA_SPECIAL_MODE_NONE then
        return
    endif
    if CC_SpecialCameraRectCount >= CC_MAX_SPECIAL_CAMERA_RECTS then
        return
    endif
    set CC_SpecialCameraRectCount = CC_SpecialCameraRectCount + 1
    set index = CC_SpecialCameraRectCount
    set CC_SpecialCameraRects[index] = whichRect
    set CC_SpecialCameraRectModes[index] = specialMode
    set CC_SpecialCameraEnterTriggers[index] = CreateTrigger()
    set CC_SpecialCameraLeaveTriggers[index] = CreateTrigger()
    call TriggerRegisterEnterRectSimple(CC_SpecialCameraEnterTriggers[index], whichRect)
    call TriggerRegisterLeaveRectSimple(CC_SpecialCameraLeaveTriggers[index], whichRect)
    call TriggerAddAction(CC_SpecialCameraEnterTriggers[index], function CC_OnSpecialCameraRectEvent)
    call TriggerAddAction(CC_SpecialCameraLeaveTriggers[index], function CC_OnSpecialCameraRectEvent)
endfunction

private function CC_RegisterBuiltInSpecialCameraRects takes nothing returns nothing
    // Internal non-zone special camera rects can be registered here.
    // Leave ZoneEvent-owned zone cameras there; use this only for camera-local rect behavior.
    //
    // Example template registrations:
    call CC_RegisterSpecialCameraRect(gg_rct_camtest1, CAMERA_SPECIAL_MODE_TEMPLATE01)
    // call CC_RegisterSpecialCameraRect(gg_rct_xxx, CAMERA_SPECIAL_MODE_TEMPLATE02)
    //
    // Special camera preset values are configured centrally in CC_InitSpecialModeConfigs().
    // To add another rect-driven mode:
    // - Define the mode in CC_InitSpecialModeConfigs().
    // - Register one or more gg_rct_* here to activate it.
    // - Leaving the rect automatically restores the previously resolved camera mode.
endfunction

private function CC_CheckCameraDrift takes nothing returns nothing
    local integer i = 0
    local player whichPlayer

    loop
        exitwhen i >= bj_MAX_PLAYERS
        set whichPlayer = Player(i)
        call CC_RefreshSpecialRectState(whichPlayer)
        call CC_UpdateWoundedState(whichPlayer)
        set whichPlayer = null
        set i = i + 1
    endloop
endfunction

private function CC_ResetStoredCameraState takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)

    if CC_HasSpecialMode(pid) or CC_Mode[pid] != CAMERA_MODE_NORMAL then
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

public function GetSpecialMode takes player whichPlayer returns integer
    return CC_GetResolvedSpecialMode(CC_GetPlayerIndex(whichPlayer))
endfunction

public function GetModeName takes player whichPlayer returns string
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local integer mode = CC_Mode[pid]
    if CC_HasSpecialMode(pid) then
        return CC_GetSpecialModeName(pid)
    endif
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

public function IsNormalTraceEnabled takes player whichPlayer returns boolean
    return false
endfunction

public function SetDistance takes player whichPlayer, real value returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_Distance[pid] = CC_Clamp(value, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)
    call CC_InvalidateNormalTraceCache(pid)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetFarZ takes player whichPlayer, real value returns nothing
    set CC_FarZ[CC_GetPlayerIndex(whichPlayer)] = CC_Clamp(value, CAMERA_FARZ_MIN, CAMERA_FARZ_MAX)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetAngle takes player whichPlayer, real value returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_Angle[pid] = CC_Clamp(value, CAMERA_ANGLE_MIN, CAMERA_ANGLE_MAX)
    call CC_InvalidateNormalTraceCache(pid)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetRotation takes player whichPlayer, real value returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    set CC_Rotation[pid] = CC_Clamp(value, CAMERA_ROTATION_MIN, CAMERA_ROTATION_MAX)
    call CC_InvalidateNormalTraceCache(pid)
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
    call CC_InvalidateNormalTraceCache(pid)
    call CC_ApplyMode(whichPlayer)
endfunction

public function SetNormalTraceEnabled takes player whichPlayer, boolean flag returns nothing
endfunction

private function CC_OnChatResetKey takes nothing returns nothing
    local player whichPlayer = GetTriggerPlayer()
    call CC_ClearKeyState(whichPlayer)
    call CC_UpdateLoopState()
    set whichPlayer = null
endfunction

public function SetSpecialMode takes player whichPlayer, integer specialMode returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if CC_SpecialMode[pid] == specialMode then
        return
    endif
    set CC_SpecialMode[pid] = specialMode
    // Keyboard-adjustable special modes get their own live angle/rotation state here.
    // Fixed special modes ignore CC_SpecialAngle / CC_SpecialRotation and keep the preset values from CC_DefineSpecialMode().
    if CC_IsSpecialModeKeyboardAdjustable(specialMode) then
        set CC_SpecialAngle[pid] = CC_GetConfiguredSpecialModeAngle(specialMode)
        set CC_SpecialRotation[pid] = CC_GetConfiguredSpecialModeRotation(specialMode)
    endif
    call CC_InvalidateNormalTraceCache(pid)
    call CC_ApplyMode(whichPlayer)
endfunction

public function ClearSpecialMode takes player whichPlayer returns nothing
    call SetSpecialMode(whichPlayer, CAMERA_SPECIAL_MODE_NONE)
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
    if CC_Suspended[pid] then
        if CC_ResumePending[pid] then
            set CC_ResumePending[pid] = false
            call PauseTimer(CC_ResumeTimer[pid])
            call CC_ClearKeyState(whichPlayer)
            call CC_UpdateLoopState()
        endif
        return
    endif
    set CC_Suspended[pid] = true
    set CC_ResumePending[pid] = false
    call PauseTimer(CC_ResumeTimer[pid])
    call CC_ClearKeyState(whichPlayer)
    call CC_UpdateLoopState()
    if GetLocalPlayer() == whichPlayer then
        call CameraSetSmoothingFactor(0)
    endif
    call FCL_Release(whichPlayer)
    call ReleaseCameraUnit(whichPlayer)
    call ReleaseMovementUnit(whichPlayer)
endfunction

public function ResumeQuick takes player whichPlayer returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    if CC_ResumePending[pid] or not CC_Suspended[pid] then
        return
    endif
    set CC_ResumePending[pid] = false
    set CC_Suspended[pid] = false
    call CC_ApplyMode(whichPlayer)
endfunction

public function ResumeWithDuration takes player whichPlayer, real duration returns nothing
    local integer pid = CC_GetPlayerIndex(whichPlayer)
    local integer mode = CC_Mode[pid]

    if CC_ResumePending[pid] or not CC_Suspended[pid] then
        return
    endif

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
    call CC_InitSpecialModeConfigs()

    loop
        exitwhen i >= bj_MAX_PLAYERS
        set CC_Mode[i] = CAMERA_MODE_NORMAL
        set CC_SpecialMode[i] = CAMERA_SPECIAL_MODE_NONE
        set CC_RectSpecialMode[i] = CAMERA_SPECIAL_MODE_NONE
        set CC_Distance[i] = CAMERA_DEFAULT_DISTANCE
        set CC_FarZ[i] = CAMERA_DEFAULT_FARZ
        set CC_Angle[i] = CAMERA_DEFAULT_ANGLE
        set CC_Rotation[i] = CAMERA_DEFAULT_ROTATION
        set CC_Fov[i] = CAMERA_DEFAULT_FOV
        set CC_SpecialAngle[i] = CC_GetConfiguredSpecialModeAngle(CAMERA_SPECIAL_MODE_BOOMMINE)
        set CC_SpecialRotation[i] = CC_GetConfiguredSpecialModeRotation(CAMERA_SPECIAL_MODE_BOOMMINE)
        set CC_NormalEffectiveDistance[i] = CAMERA_DEFAULT_DISTANCE
        set CC_NormalEffectiveAngle[i] = CAMERA_DEFAULT_ANGLE
        set CC_NormalTraceEnabled[i] = false
        call CC_InvalidateNormalTraceCache(i)
        set CC_TargetUnit[i] = null
        set CC_WoundedActive[i] = false
        set CC_WoundedSeed[i] = 137 + i*41
        set CC_WoundedNextBeatTicks[i] = 0
        set CC_WoundedSecondBeatTicks[i] = 0
        set CC_WoundedPulse[i] = 0.00
        set CC_ResumeTimer[i] = CreateTimer()
        set i = i + 1
    endloop

    set CC_UpdateTimer = CreateTimer()
    set CC_DriftTimer = CreateTimer()
    call TimerStart(CC_DriftTimer, CAMERA_DRIFT_CHECK_INTERVAL, true, function CC_CheckCameraDrift)
    set CC_PathingProbe = CreateItem('wolg', 0.00, 0.00)
    call SetItemVisible(CC_PathingProbe, false)
    set CC_PathingProbeRect = Rect(0.00, 0.00, CAMERA_NORMAL_TRACE_ACCURACY*2.00, CAMERA_NORMAL_TRACE_ACCURACY*2.00)
    set CC_TerrainLoc = Location(0.00, 0.00)

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
    set CC_ChatResetTrigger = CreateTrigger()
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
        call BlzTriggerRegisterPlayerKeyEvent(CC_ChatResetTrigger, Player(i), OSKEY_RETURN, 0, true)
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
    call TriggerAddAction(CC_ChatResetTrigger, function CC_OnChatResetKey)

    set gameUI = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
    if gameUI != null then
        call BlzTriggerRegisterFrameEvent(CC_WheelResetTrigger, gameUI, FRAMEEVENT_MOUSE_WHEEL)
    endif

    set worldFrame = BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0)
    if worldFrame != null then
        call BlzTriggerRegisterFrameEvent(CC_WheelResetTrigger, worldFrame, FRAMEEVENT_MOUSE_WHEEL)
    endif

    call TriggerAddAction(CC_WheelResetTrigger, function CC_PageResetAction)
    call CC_RegisterBuiltInSpecialCameraRects()

    set gameUI = null
    set worldFrame = null
endfunction

public function AutoInit takes nothing returns nothing
    call Init()
endfunction

endlibrary
