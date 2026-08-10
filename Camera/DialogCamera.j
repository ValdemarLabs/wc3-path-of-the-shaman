/**
    DialogCamera

    Author: Valdemar
    Version: 2.1.0

    Description:
    Focuses a player's camera on a dialogue unit, provides reusable cinematic
    presets, locks the camera target to the dialogue unit, and can rotate between
    presets during long conversations or UI interactions. Destructible and
    structure checks test several camera angles and points along the view path
    before selecting a shot.

    Credits:
    - Path of the Shaman CameraControl system

    How to install:
    Import after CameraControl.

    API:
    - call DialogCameraStart(...)
    - call DialogCameraStartInteractive(...)
    - call DialogCameraStartPreset(player, unit, presetId, baseRotationOffset, transitionTime, keyboardAdjustable)
    - call DialogCameraStartRandomPreset(player, unit, baseRotationOffset, transitionTime, keyboardAdjustable)
    - call DialogCameraStartRandomCycle(player, unit, baseRotationOffset, minInterval, maxInterval, keyboardAdjustable)
    - call DialogCameraStopRandomCycle(player)
    - call DialogCameraReset(player, duration)
    - call DialogCameraRegisterPreset(...)

    Default presets:
    - DialogCamera_PRESET_CLOSE_LEFT
    - DialogCamera_PRESET_CLOSE_RIGHT
    - DialogCamera_PRESET_SHOULDER
    - DialogCamera_PRESET_WIDE
    - DialogCamera_PRESET_ELEVATED

**/
library DialogCamera initializer Init requires CameraControl
    globals
        public constant integer PRESET_CLOSE_LEFT = 1
        public constant integer PRESET_CLOSE_RIGHT = 2
        public constant integer PRESET_SHOULDER = 3
        public constant integer PRESET_WIDE = 4
        public constant integer PRESET_ELEVATED = 5

        private constant integer MAX_PRESETS = 16
        private constant integer BLOCK_SAMPLE_COUNT = 3
        private constant integer BLOCK_ROTATION_CANDIDATE_COUNT = 8
        private constant real DEFAULT_DISTANCE = 1200.00
        private constant real DEFAULT_Z_OFFSET = 350.00
        private constant real DEFAULT_FOV = 60.00
        private constant real DEFAULT_FAR_Z = 1000.00
        private constant real DEFAULT_ANGLE = 340.00
        private constant real DEFAULT_NEAR_Z = 20.00
        private constant real DEFAULT_BLOCK_RADIUS = 180.00
        private constant real PRESET_TRANSITION_TIME = 4.50
        private constant real DEFAULT_CYCLE_MIN_INTERVAL = 16.00
        private constant real DEFAULT_CYCLE_MAX_INTERVAL = 26.00

        private boolean array DialogCamera_Active
        private boolean array DialogCamera_PresetConfigured
        private real array DialogCamera_PresetDistance
        private real array DialogCamera_PresetZOffset
        private real array DialogCamera_PresetAngle
        private real array DialogCamera_PresetRotationOffset
        private real array DialogCamera_PresetFarZ
        private real array DialogCamera_PresetFov
        private real array DialogCamera_PresetBlockRadius
        private integer DialogCamera_PresetCount = 0

        private real array DialogCamera_BlockRotationOffset
        private real DialogCamera_CheckX = 0.00
        private real DialogCamera_CheckY = 0.00
        private real DialogCamera_CheckRadius = 0.00
        private boolean DialogCamera_Blocked = false
        private group DialogCamera_BlockingUnits = null

        private timer array DialogCamera_CycleTimer
        private unit array DialogCamera_CycleTarget
        private real array DialogCamera_CycleBaseRotation
        private real array DialogCamera_CycleMinInterval
        private real array DialogCamera_CycleMaxInterval
        private boolean array DialogCamera_CycleKeyboardAdjustable
        private integer array DialogCamera_LastPreset
        private integer array DialogCamera_RandomState
    endglobals

    private function DialogCamera_CheckDestructable takes nothing returns nothing
        local destructable d = GetEnumDestructable()
        local real dx = GetDestructableX(d) - DialogCamera_CheckX
        local real dy = GetDestructableY(d) - DialogCamera_CheckY

        if GetDestructableLife(d) > 0.405 and GetDestructableOccluderHeight(d) > 0.00 and dx * dx + dy * dy < DialogCamera_CheckRadius * DialogCamera_CheckRadius then
            set DialogCamera_Blocked = true
        endif
        set d = null
    endfunction

    // Ignore the immediate NPC area and sample the middle and rear of the camera path.
    private function DialogCamera_IsBlocked takes real x, real y, real rotation, real distance, real radius returns boolean
        local integer sample = 1
        local real sampleDistance
        local rect scanRect = null
        local unit blockingUnit

        set DialogCamera_CheckRadius = radius
        loop
            exitwhen sample > BLOCK_SAMPLE_COUNT
            set sampleDistance = distance * (0.45 + 0.275 * I2R(sample - 1))
            set DialogCamera_CheckX = x - sampleDistance * Cos(rotation * bj_DEGTORAD)
            set DialogCamera_CheckY = y - sampleDistance * Sin(rotation * bj_DEGTORAD)
            set DialogCamera_Blocked = false
            set scanRect = Rect(DialogCamera_CheckX - radius, DialogCamera_CheckY - radius, DialogCamera_CheckX + radius, DialogCamera_CheckY + radius)
            call EnumDestructablesInRect(scanRect, null, function DialogCamera_CheckDestructable)
            call RemoveRect(scanRect)
            set scanRect = null
            call GroupEnumUnitsInRange(DialogCamera_BlockingUnits, DialogCamera_CheckX, DialogCamera_CheckY, radius, null)
            loop
                set blockingUnit = FirstOfGroup(DialogCamera_BlockingUnits)
                exitwhen blockingUnit == null
                call GroupRemoveUnit(DialogCamera_BlockingUnits, blockingUnit)
                if GetWidgetLife(blockingUnit) > 0.405 and IsUnitType(blockingUnit, UNIT_TYPE_STRUCTURE) then
                    set DialogCamera_Blocked = true
                endif
            endloop
            if DialogCamera_Blocked then
                set blockingUnit = null
                return true
            endif
            set sample = sample + 1
        endloop
        set blockingUnit = null
        return false
    endfunction

    private function DialogCamera_FindClearRotation takes real x, real y, real requestedRotation, real distance, real radius returns real
        local integer candidate = 1
        local real rotation

        loop
            exitwhen candidate > BLOCK_ROTATION_CANDIDATE_COUNT
            set rotation = requestedRotation + DialogCamera_BlockRotationOffset[candidate]
            if not DialogCamera_IsBlocked(x, y, rotation, distance, radius) then
                return rotation
            endif
            set candidate = candidate + 1
        endloop
        return requestedRotation
    endfunction

    private function DialogCamera_Start takes player p, unit u, real distance, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck, boolean keyboardAdjustable, real transitionTime returns nothing
        local integer pid
        local real x
        local real y
        local real finalRotation

        if p == null or u == null then
            return
        endif
        if distance <= 0.00 then
            set distance = DEFAULT_DISTANCE
        endif
        if zOffset <= 0.00 then
            set zOffset = DEFAULT_Z_OFFSET
        endif
        if angle == 0.00 then
            set angle = DEFAULT_ANGLE
        endif
        if farZ <= 0.00 then
            set farZ = DEFAULT_FAR_Z
        endif
        if fov <= 0.00 then
            set fov = DEFAULT_FOV
        endif
        if blockRadius <= 0.00 then
            set blockRadius = DEFAULT_BLOCK_RADIUS
        endif
        if transitionTime < 0.00 then
            set transitionTime = 0.00
        endif

        set pid = GetPlayerId(p)
        set x = GetUnitX(u)
        set y = GetUnitY(u)
        set finalRotation = GetUnitFacing(u) + rotationOffset
        if doBlockCheck then
            set finalRotation = DialogCamera_FindClearRotation(x, y, finalRotation, distance, blockRadius)
        endif

        set DialogCamera_Active[pid] = true
        if keyboardAdjustable then
            call CameraControl_SuspendInteractive(p, angle, finalRotation)
        else
            call CameraControl_Suspend(p)
        endif

        if GetLocalPlayer() == p then
            call CameraSetSmoothingFactor(1)
            call SetCameraTargetController(u, 0.00, 0.00, false)
        endif

        call PanCameraToTimedForPlayer(p, x, y, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_TARGET_DISTANCE, distance, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_FARZ, farZ, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_FIELD_OF_VIEW, fov, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_ANGLE_OF_ATTACK, angle, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_ROTATION, finalRotation, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_ZOFFSET, zOffset, transitionTime)
        call SetCameraFieldForPlayer(p, CAMERA_FIELD_NEARZ, DEFAULT_NEAR_Z, transitionTime)
    endfunction

    function DialogCameraRegisterPreset takes integer presetId, real distance, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius returns boolean
        if presetId <= 0 or presetId > MAX_PRESETS or presetId > DialogCamera_PresetCount + 1 then
            return false
        endif
        set DialogCamera_PresetConfigured[presetId] = true
        set DialogCamera_PresetDistance[presetId] = distance
        set DialogCamera_PresetZOffset[presetId] = zOffset
        set DialogCamera_PresetAngle[presetId] = angle
        set DialogCamera_PresetRotationOffset[presetId] = rotationOffset
        set DialogCamera_PresetFarZ[presetId] = farZ
        set DialogCamera_PresetFov[presetId] = fov
        set DialogCamera_PresetBlockRadius[presetId] = blockRadius
        if presetId > DialogCamera_PresetCount then
            set DialogCamera_PresetCount = presetId
        endif
        return true
    endfunction

    function DialogCameraGetPresetCount takes nothing returns integer
        return DialogCamera_PresetCount
    endfunction

    function DialogCameraStart takes player p, unit u, real distance, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck returns nothing
        call DialogCamera_Start(p, u, distance, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck, false, 0.00)
    endfunction

    function DialogCameraStartInteractive takes player p, unit u, real distance, real zOffset, real angle, real rotationOffset, real farZ, real fov, real blockRadius, boolean doBlockCheck returns nothing
        call DialogCamera_Start(p, u, distance, zOffset, angle, rotationOffset, farZ, fov, blockRadius, doBlockCheck, true, 0.00)
    endfunction

    function DialogCameraStartPreset takes player p, unit u, integer presetId, real baseRotationOffset, real transitionTime, boolean keyboardAdjustable returns nothing
        if presetId <= 0 or presetId > DialogCamera_PresetCount or not DialogCamera_PresetConfigured[presetId] then
            set presetId = PRESET_CLOSE_LEFT
        endif
        call DialogCamera_Start(p, u, DialogCamera_PresetDistance[presetId], DialogCamera_PresetZOffset[presetId], DialogCamera_PresetAngle[presetId], baseRotationOffset + DialogCamera_PresetRotationOffset[presetId], DialogCamera_PresetFarZ[presetId], DialogCamera_PresetFov[presetId], DialogCamera_PresetBlockRadius[presetId], true, keyboardAdjustable, transitionTime)
    endfunction

    // Cosmetic camera selection must not consume Warcraft's gameplay RNG stream.
    private function DialogCamera_NextRandom takes integer pid, integer limit returns integer
        if limit <= 1 then
            return 1
        endif
        set DialogCamera_RandomState[pid] = ModuloInteger(DialogCamera_RandomState[pid] * 73 + 41, 1000003)
        return ModuloInteger(DialogCamera_RandomState[pid], limit) + 1
    endfunction

    private function DialogCamera_GetNextInterval takes integer pid returns real
        local integer roll = DialogCamera_NextRandom(pid, 1001) - 1
        return DialogCamera_CycleMinInterval[pid] + (DialogCamera_CycleMaxInterval[pid] - DialogCamera_CycleMinInterval[pid]) * I2R(roll) / 1000.00
    endfunction

    function DialogCameraStartRandomPreset takes player p, unit u, real baseRotationOffset, real transitionTime, boolean keyboardAdjustable returns nothing
        local integer pid
        local integer presetId

        if p == null or u == null or DialogCamera_PresetCount <= 0 then
            return
        endif
        set pid = GetPlayerId(p)
        if DialogCamera_RandomState[pid] == 0 then
            set DialogCamera_RandomState[pid] = ModuloInteger(GetHandleId(u) + pid * 997 + 1, 1000003)
        endif
        set presetId = DialogCamera_NextRandom(pid, DialogCamera_PresetCount)
        if DialogCamera_PresetCount > 1 and presetId == DialogCamera_LastPreset[pid] then
            set presetId = presetId + 1
            if presetId > DialogCamera_PresetCount then
                set presetId = 1
            endif
        endif
        set DialogCamera_LastPreset[pid] = presetId
        call DialogCameraStartPreset(p, u, presetId, baseRotationOffset, transitionTime, keyboardAdjustable)
    endfunction

    private function DialogCamera_OnCycle takes nothing returns nothing
        local timer expiredTimer = GetExpiredTimer()
        local integer pid = 0
        local real interval

        loop
            exitwhen pid >= bj_MAX_PLAYER_SLOTS
            if DialogCamera_CycleTimer[pid] == expiredTimer then
                if DialogCamera_CycleTarget[pid] != null and GetUnitTypeId(DialogCamera_CycleTarget[pid]) != 0 and GetWidgetLife(DialogCamera_CycleTarget[pid]) > 0.405 then
                    call DialogCameraStartRandomPreset(Player(pid), DialogCamera_CycleTarget[pid], DialogCamera_CycleBaseRotation[pid], PRESET_TRANSITION_TIME, DialogCamera_CycleKeyboardAdjustable[pid])
                    set interval = DialogCamera_GetNextInterval(pid)
                    call TimerStart(expiredTimer, interval, false, function DialogCamera_OnCycle)
                else
                    set DialogCamera_CycleTarget[pid] = null
                endif
                set pid = bj_MAX_PLAYER_SLOTS
            else
                set pid = pid + 1
            endif
        endloop
        set expiredTimer = null
    endfunction

    function DialogCameraStopRandomCycle takes player p returns nothing
        local integer pid

        if p == null then
            return
        endif
        set pid = GetPlayerId(p)
        if DialogCamera_CycleTimer[pid] != null then
            call PauseTimer(DialogCamera_CycleTimer[pid])
        endif
        set DialogCamera_CycleTarget[pid] = null
        set DialogCamera_LastPreset[pid] = 0
    endfunction

    function DialogCameraStartRandomCycle takes player p, unit u, real baseRotationOffset, real minInterval, real maxInterval, boolean keyboardAdjustable returns nothing
        local integer pid

        if p == null or u == null then
            return
        endif
        if minInterval <= 0.00 then
            set minInterval = DEFAULT_CYCLE_MIN_INTERVAL
        endif
        if maxInterval <= 0.00 then
            set maxInterval = DEFAULT_CYCLE_MAX_INTERVAL
        endif
        if maxInterval < minInterval then
            set maxInterval = minInterval
        endif

        set pid = GetPlayerId(p)
        call DialogCameraStopRandomCycle(p)
        if DialogCamera_CycleTimer[pid] == null then
            set DialogCamera_CycleTimer[pid] = CreateTimer()
        endif
        set DialogCamera_CycleTarget[pid] = u
        set DialogCamera_CycleBaseRotation[pid] = baseRotationOffset
        set DialogCamera_CycleMinInterval[pid] = minInterval
        set DialogCamera_CycleMaxInterval[pid] = maxInterval
        set DialogCamera_CycleKeyboardAdjustable[pid] = keyboardAdjustable
        if DialogCamera_RandomState[pid] == 0 then
            set DialogCamera_RandomState[pid] = ModuloInteger(GetHandleId(u) + pid * 997 + 1, 1000003)
        endif
        call DialogCameraStartRandomPreset(p, u, baseRotationOffset, PRESET_TRANSITION_TIME, keyboardAdjustable)
        call TimerStart(DialogCamera_CycleTimer[pid], DialogCamera_GetNextInterval(pid), false, function DialogCamera_OnCycle)
    endfunction

    function DialogCameraReset takes player p, real duration returns nothing
        local integer pid
        local unit target

        if p == null then
            return
        endif
        set pid = GetPlayerId(p)
        call DialogCameraStopRandomCycle(p)
        if DialogCamera_Active[pid] then
            set DialogCamera_Active[pid] = false
            set target = CameraControl_GetTargetUnit(p)
            if GetLocalPlayer() == p then
                call CameraSetSmoothingFactor(1)
                if target != null then
                    call SetCameraTargetController(target, 0.00, 0.00, false)
                else
                    call ResetToGameCamera(duration)
                endif
            endif
            call CameraControl_ResumeWithDuration(p, duration)
        endif
        set target = null
    endfunction

    private function Init takes nothing returns nothing
        set DialogCamera_BlockingUnits = CreateGroup()
        set DialogCamera_BlockRotationOffset[1] = 0.00
        set DialogCamera_BlockRotationOffset[2] = 45.00
        set DialogCamera_BlockRotationOffset[3] = -45.00
        set DialogCamera_BlockRotationOffset[4] = 90.00
        set DialogCamera_BlockRotationOffset[5] = -90.00
        set DialogCamera_BlockRotationOffset[6] = 135.00
        set DialogCamera_BlockRotationOffset[7] = -135.00
        set DialogCamera_BlockRotationOffset[8] = 180.00

        // Keep dialogue cameras inside the 1000-range blocker scan and close to eye level.
        call DialogCameraRegisterPreset(PRESET_CLOSE_LEFT, 820.00, 82.00, 326.00, -24.00, 10000.00, 54.00, 165.00)
        call DialogCameraRegisterPreset(PRESET_CLOSE_RIGHT, 875.00, 96.00, 330.00, 30.00, 10000.00, 57.00, 175.00)
        call DialogCameraRegisterPreset(PRESET_SHOULDER, 840.00, 72.00, 322.00, -40.00, 10000.00, 55.00, 165.00)
        call DialogCameraRegisterPreset(PRESET_WIDE, 900.00, 108.00, 336.00, 45.00, 10000.00, 61.00, 190.00)
        call DialogCameraRegisterPreset(PRESET_ELEVATED, 860.00, 124.00, 340.00, 4.00, 10000.00, 58.00, 180.00)
    endfunction
endlibrary
