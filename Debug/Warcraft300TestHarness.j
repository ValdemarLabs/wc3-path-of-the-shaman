/**
    Warcraft300TestHarness

    Author: Valdemar
    Version: 0.3.1

    Description:
    Provides explicit Warcraft III 3.0 diagnostics and resettable camera, fog,
    and doodad probes inside the complete PotS map. No probe runs at startup.

    Credits:

    How to install:
    Import CameraControl, FogSystem, DoodadManager, and Ascii before this
    library, then import this library before DebugCommands.

    API:
    - Warcraft300TestHarness_Execute(player, command) -> boolean
    - /debug wc3 help

**/
library Warcraft300TestHarness requires CameraControl, FogSystem, DoodadManager, Ascii
    globals
        private constant string W3T_PREFIX = "|cff80dfff[WC3 3.0]|r "
        private constant string W3T_GAME_BUILD = "3.0.0.24268"
        private constant integer W3T_DOODAD_SCAN_BATCH_SIZE = 256
        private constant real W3T_DOODAD_SCAN_PERIOD = 0.03

        // Fog probes keep one complete target-state snapshot per player.
        private boolean array W3T_FogSnapshotValid
        private boolean array W3T_FogSnapshotExtended
        private boolean array W3T_FogSnapshotDrawOverSky
        private integer array W3T_FogSnapshotStyle
        private real array W3T_FogSnapshotZStart
        private real array W3T_FogSnapshotZEnd
        private real array W3T_FogSnapshotDensity
        private real array W3T_FogSnapshotHeightStart
        private real array W3T_FogSnapshotHeightEnd
        private real array W3T_FogSnapshotLinearStart
        private real array W3T_FogSnapshotLinearEnd
        private real array W3T_FogSnapshotMaxLinearDensity
        private real array W3T_FogSnapshotRed
        private real array W3T_FogSnapshotGreen
        private real array W3T_FogSnapshotBlue

        // Doodad scans are batched to avoid a single-frame pass over ~50k placements.
        private timer W3T_DoodadScanTimer = null
        private timer W3T_DoodadScanClock = null
        private player W3T_DoodadScanPlayer = null
        private boolean W3T_DoodadScanActive = false
        private integer W3T_DoodadScanIndex = 0
        private integer W3T_DoodadScanCount = 0
        private integer W3T_DoodadScanInvalid = 0
        private integer W3T_DoodadScanModelAxes = 0
        private integer W3T_DoodadScanRotated = 0
        private integer W3T_DoodadScanNonUniformScale = 0
        private integer W3T_DoodadScanIdChecksum = 0
        private integer W3T_DoodadScanPositionChecksum = 0
        private integer W3T_DoodadProbeIndex = -1
    endglobals

    private function W3T_BooleanText takes boolean value returns string
        if value then
            return "true"
        endif
        return "false"
    endfunction

    private function W3T_StartsWith takes string source, string prefix returns boolean
        local integer length = StringLength(prefix)
        return StringLength(source) >= length and SubString(source, 0, length) == prefix
    endfunction

    private function W3T_IsDigit takes string character returns boolean
        return character == "0" or character == "1" or character == "2" or character == "3" or character == "4" or character == "5" or character == "6" or character == "7" or character == "8" or character == "9"
    endfunction

    private function W3T_IsUnsignedInteger takes string value returns boolean
        local integer index = 0
        local integer length = StringLength(value)

        if length == 0 then
            return false
        endif
        loop
            exitwhen index >= length
            if not W3T_IsDigit(SubString(value, index, index + 1)) then
                return false
            endif
            set index = index + 1
        endloop
        return true
    endfunction

    private function W3T_Message takes player whichPlayer, string message returns nothing
        call DisplayTextToPlayer(whichPlayer, 0.00, 0.00, W3T_PREFIX + message)
    endfunction

    private function W3T_RawCodeText takes integer rawCode returns string
        if rawCode == 0 then
            return "0000"
        endif
        return A2S(rawCode)
    endfunction

    private function W3T_ShowHelp takes player whichPlayer returns nothing
        call W3T_Message(whichPlayer, "Baseline: status | selftest | camera | fog | doodads")
        call W3T_Message(whichPlayer, "Camera: camera orbit on|off | camera ownership on|off")
        call W3T_Message(whichPlayer, "Camera type: camera type | camera type set <0-16> | camera type reset")
        call W3T_Message(whichPlayer, "Fog: fog test parity|height|exp | fog reset")
        call W3T_Message(whichPlayer, "Doodads: doodads scan|cancel | doodads inspect <index> | doodads probe hide <index>|reset")
        call W3T_Message(whichPlayer, "P2: effects help")
    endfunction

    private function W3T_ShowCamera takes player whichPlayer returns nothing
        local integer mouseX
        local integer mouseY

        // Screen, mouse, and camera queries are local presentation state.
        if GetLocalPlayer() == whichPlayer then
            set mouseX = BlzGetMouseScreenPosX()
            set mouseY = BlzGetMouseScreenPosY()
            call W3T_Message(whichPlayer, "Camera: mode=" + CameraControl_GetModeName(whichPlayer) + ", type=" + I2S(BlzCameraGetCameraType()) + ", suspended=" + W3T_BooleanText(CameraControl_IsSuspended(whichPlayer)))
            call W3T_Message(whichPlayer, "Orbit: enabled=" + W3T_BooleanText(CameraControl_IsMouseOrbitEnabled(whichPlayer)) + ", blocked=" + W3T_BooleanText(CameraControl_IsMouseOrbitBlocked(whichPlayer)) + ", dragging=" + W3T_BooleanText(CameraControl_IsMouseOrbitDragging(whichPlayer)))
            call W3T_Message(whichPlayer, "Stored: distance=" + R2S(CameraControl_GetDistance(whichPlayer)) + ", angle=" + R2S(CameraControl_GetAngle(whichPlayer)) + ", rotation=" + R2S(CameraControl_GetRotation(whichPlayer)))
            call W3T_Message(whichPlayer, "Stored: farZ=" + R2S(CameraControl_GetFarZ(whichPlayer)) + ", fov=" + R2S(CameraControl_GetFov(whichPlayer)) + ", target=" + CameraControl_GetTargetName(whichPlayer))
            call W3T_Message(whichPlayer, "Client: active=" + W3T_BooleanText(BlzIsLocalClientActive()) + ", size=" + I2S(BlzGetLocalClientWidth()) + "x" + I2S(BlzGetLocalClientHeight()))
            call W3T_Message(whichPlayer, "Mouse: pixels=" + I2S(mouseX) + "," + I2S(mouseY) + ", frame=" + R2S(BlzPixelToFrameX(mouseX)) + "," + R2S(BlzPixelToFrameY(mouseY)) + ", middle=" + W3T_BooleanText(BlzIsMouseButtonPressed(MOUSE_BUTTON_TYPE_MIDDLE)))
            call W3T_Message(whichPlayer, "Input ownership: enabled=" + W3T_BooleanText(CameraControl_IsExperimentalInputOwnershipEnabled(whichPlayer)) + ", applied=" + W3T_BooleanText(CameraControl_IsExperimentalInputOwnershipApplied(whichPlayer)))
            call W3T_Message(whichPlayer, "Engine input: distance=" + W3T_BooleanText(GetCameraFieldControlledByInput(CAMERA_FIELD_TARGET_DISTANCE)) + ", farZ=" + W3T_BooleanText(GetCameraFieldControlledByInput(CAMERA_FIELD_FARZ)) + ", angle=" + W3T_BooleanText(GetCameraFieldControlledByInput(CAMERA_FIELD_ANGLE_OF_ATTACK)) + ", fov=" + W3T_BooleanText(GetCameraFieldControlledByInput(CAMERA_FIELD_FIELD_OF_VIEW)) + ", rotation=" + W3T_BooleanText(GetCameraFieldControlledByInput(CAMERA_FIELD_ROTATION)))
        endif
    endfunction

    private function W3T_SetCameraOrbit takes player whichPlayer, boolean enabled returns nothing
        if GetLocalPlayer() == whichPlayer then
            call CameraControl_SetMouseOrbitEnabled(whichPlayer, enabled)
            call W3T_Message(whichPlayer, "Bounded middle-mouse orbit enabled=" + W3T_BooleanText(enabled) + ".")
        endif
    endfunction

    private function W3T_SetCameraInputOwnership takes player whichPlayer, boolean enabled returns nothing
        if GetLocalPlayer() == whichPlayer then
            call CameraControl_SetExperimentalInputOwnership(whichPlayer, enabled)
            if enabled then
                call W3T_Message(whichPlayer, "Camera input ownership applied=" + W3T_BooleanText(CameraControl_IsExperimentalInputOwnershipApplied(whichPlayer)) + ".")
            else
                call W3T_Message(whichPlayer, "Camera input ownership snapshot restored.")
            endif
        endif
    endfunction

    private function W3T_SetCameraType takes player whichPlayer, integer cameraType returns nothing
        local boolean accepted

        if GetLocalPlayer() == whichPlayer then
            set accepted = CameraControl_SetExperimentalCameraType(whichPlayer, cameraType)
            call W3T_Message(whichPlayer, "Camera type request=" + I2S(cameraType) + ", readback=" + I2S(BlzCameraGetCameraType()) + ", accepted=" + W3T_BooleanText(accepted) + ".")
        endif
    endfunction

    private function W3T_ResetCameraType takes player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
            call CameraControl_ResetExperimentalCameraType(whichPlayer)
            call W3T_Message(whichPlayer, "Camera type restored; readback=" + I2S(BlzCameraGetCameraType()) + ".")
        endif
    endfunction

    private function W3T_ShowFog takes player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
            call W3T_Message(whichPlayer, "Fog: extended=" + W3T_BooleanText(FogSystem_IsCurrentExtended(whichPlayer)) + ", style=" + I2S(FogSystem_GetCurrentStyle(whichPlayer)) + ", overrideDepth=" + I2S(FogSystem_GetOverrideDepth()) + ", fading=" + W3T_BooleanText(FogSystem_IsFading(whichPlayer)))
            call W3T_Message(whichPlayer, "Current: z=" + R2S(FogSystem_GetCurrentStart(whichPlayer)) + ".." + R2S(FogSystem_GetCurrentEnd(whichPlayer)) + ", density=" + R2S(FogSystem_GetCurrentDensity(whichPlayer)) + ", rgb=" + R2S(FogSystem_GetCurrentRed(whichPlayer)) + "," + R2S(FogSystem_GetCurrentGreen(whichPlayer)) + "," + R2S(FogSystem_GetCurrentBlue(whichPlayer)))
            call W3T_Message(whichPlayer, "Current 3.0: height=" + R2S(FogSystem_GetCurrentHeightStart(whichPlayer)) + ".." + R2S(FogSystem_GetCurrentHeightEnd(whichPlayer)) + ", linear=" + R2S(FogSystem_GetCurrentLinearStart(whichPlayer)) + ".." + R2S(FogSystem_GetCurrentLinearEnd(whichPlayer)) + ", max=" + R2S(FogSystem_GetCurrentMaxLinearDensity(whichPlayer)) + ", sky=" + W3T_BooleanText(FogSystem_GetCurrentDrawOverSky(whichPlayer)))
            call W3T_Message(whichPlayer, "Target: extended=" + W3T_BooleanText(FogSystem_IsTargetExtended(whichPlayer)) + ", style=" + I2S(FogSystem_GetTargetStyle(whichPlayer)) + ", z=" + R2S(FogSystem_GetTargetStart(whichPlayer)) + ".." + R2S(FogSystem_GetTargetEnd(whichPlayer)) + ", density=" + R2S(FogSystem_GetTargetDensity(whichPlayer)))
        endif
    endfunction

    private function W3T_CaptureFogSnapshot takes player whichPlayer returns nothing
        local integer pid = GetPlayerId(whichPlayer)

        if W3T_FogSnapshotValid[pid] then
            return
        endif
        set W3T_FogSnapshotValid[pid] = true
        set W3T_FogSnapshotExtended[pid] = FogSystem_IsTargetExtended(whichPlayer)
        set W3T_FogSnapshotStyle[pid] = FogSystem_GetTargetStyle(whichPlayer)
        set W3T_FogSnapshotDrawOverSky[pid] = FogSystem_GetTargetDrawOverSky(whichPlayer)
        set W3T_FogSnapshotZStart[pid] = FogSystem_GetTargetStart(whichPlayer)
        set W3T_FogSnapshotZEnd[pid] = FogSystem_GetTargetEnd(whichPlayer)
        set W3T_FogSnapshotDensity[pid] = FogSystem_GetTargetDensity(whichPlayer)
        set W3T_FogSnapshotHeightStart[pid] = FogSystem_GetTargetHeightStart(whichPlayer)
        set W3T_FogSnapshotHeightEnd[pid] = FogSystem_GetTargetHeightEnd(whichPlayer)
        set W3T_FogSnapshotLinearStart[pid] = FogSystem_GetTargetLinearStart(whichPlayer)
        set W3T_FogSnapshotLinearEnd[pid] = FogSystem_GetTargetLinearEnd(whichPlayer)
        set W3T_FogSnapshotMaxLinearDensity[pid] = FogSystem_GetTargetMaxLinearDensity(whichPlayer)
        set W3T_FogSnapshotRed[pid] = FogSystem_GetTargetRed(whichPlayer)
        set W3T_FogSnapshotGreen[pid] = FogSystem_GetTargetGreen(whichPlayer)
        set W3T_FogSnapshotBlue[pid] = FogSystem_GetTargetBlue(whichPlayer)
    endfunction

    private function W3T_ApplyFogTest takes player whichPlayer, string testName returns nothing
        call W3T_CaptureFogSnapshot(whichPlayer)
        if testName == "parity" then
            call FogSystem_SetPresetForPlayer(0, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 0.00, 0.00, 0.00, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 1.00, false, FogSystem_GetTargetRed(whichPlayer), FogSystem_GetTargetGreen(whichPlayer), FogSystem_GetTargetBlue(whichPlayer), whichPlayer)
        elseif testName == "height" then
            call FogSystem_SetPresetForPlayer(3, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 0.00, 0.00, 1000.00, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 0.85, false, FogSystem_GetTargetRed(whichPlayer), FogSystem_GetTargetGreen(whichPlayer), FogSystem_GetTargetBlue(whichPlayer), whichPlayer)
        elseif testName == "exp" then
            call FogSystem_SetPresetForPlayer(4, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 0.0015, 0.00, 0.00, FogSystem_GetTargetStart(whichPlayer), FogSystem_GetTargetEnd(whichPlayer), 1.00, false, FogSystem_GetTargetRed(whichPlayer), FogSystem_GetTargetGreen(whichPlayer), FogSystem_GetTargetBlue(whichPlayer), whichPlayer)
        else
            call W3T_Message(whichPlayer, "Unknown fog test. Use parity, height, or exp.")
            return
        endif
        call W3T_Message(whichPlayer, "Applied fog test '" + testName + "'. Use /debug wc3 fog reset before changing zones.")
    endfunction

    private function W3T_ResetFogTest takes player whichPlayer returns nothing
        local integer pid = GetPlayerId(whichPlayer)

        if not W3T_FogSnapshotValid[pid] then
            call W3T_Message(whichPlayer, "No fog test snapshot is active.")
            return
        endif
        if W3T_FogSnapshotExtended[pid] then
            call FogSystem_SetPresetForPlayer(W3T_FogSnapshotStyle[pid], W3T_FogSnapshotZStart[pid], W3T_FogSnapshotZEnd[pid], W3T_FogSnapshotDensity[pid], W3T_FogSnapshotHeightStart[pid], W3T_FogSnapshotHeightEnd[pid], W3T_FogSnapshotLinearStart[pid], W3T_FogSnapshotLinearEnd[pid], W3T_FogSnapshotMaxLinearDensity[pid], W3T_FogSnapshotDrawOverSky[pid], W3T_FogSnapshotRed[pid], W3T_FogSnapshotGreen[pid], W3T_FogSnapshotBlue[pid], whichPlayer)
        else
            call AddFogForPlayer(W3T_FogSnapshotZStart[pid], W3T_FogSnapshotZEnd[pid], W3T_FogSnapshotRed[pid]*100.00, W3T_FogSnapshotGreen[pid]*100.00, W3T_FogSnapshotBlue[pid]*100.00, whichPlayer)
        endif
        set W3T_FogSnapshotValid[pid] = false
        call W3T_Message(whichPlayer, "Fog test snapshot restored.")
    endfunction

    private function W3T_IsManagedDoodad takes integer doodadId returns boolean
        local integer index = 1

        loop
            exitwhen index > DoodadManager_GetTypeCount()
            if DoodadManager_GetTypeId(index) == doodadId then
                return true
            endif
            set index = index + 1
        endloop
        return false
    endfunction

    private function W3T_ShowDoodads takes player whichPlayer returns nothing
        call W3T_Message(whichPlayer, "Doodads: native count=" + I2S(BlzGetNumDoodads()) + ", scanActive=" + W3T_BooleanText(W3T_DoodadScanActive) + ", activeProbe=" + I2S(W3T_DoodadProbeIndex) + ".")
    endfunction

    private function W3T_FinishDoodadScan takes nothing returns nothing
        local real elapsed = TimerGetElapsed(W3T_DoodadScanClock)

        call PauseTimer(W3T_DoodadScanTimer)
        set W3T_DoodadScanActive = false
        call W3T_Message(W3T_DoodadScanPlayer, "Doodad scan complete: count=" + I2S(W3T_DoodadScanCount) + ", invalidIds=" + I2S(W3T_DoodadScanInvalid) + ", elapsed=" + R2S(elapsed) + "s.")
        call W3T_Message(W3T_DoodadScanPlayer, "Flags: modelAxes=" + I2S(W3T_DoodadScanModelAxes) + ", pitch/roll=" + I2S(W3T_DoodadScanRotated) + ", nonUniformScale=" + I2S(W3T_DoodadScanNonUniformScale) + ".")
        call W3T_Message(W3T_DoodadScanPlayer, "Fingerprint: ids=" + I2S(W3T_DoodadScanIdChecksum) + ", positions=" + I2S(W3T_DoodadScanPositionChecksum) + ". Compare across clients/rebuilds.")
        set W3T_DoodadScanPlayer = null
    endfunction

    private function W3T_DoodadScanPeriodic takes nothing returns nothing
        local integer stopIndex = W3T_DoodadScanIndex + W3T_DOODAD_SCAN_BATCH_SIZE
        local integer doodadId
        local real scaleX
        local real scaleY
        local real scaleZ

        if stopIndex > W3T_DoodadScanCount then
            set stopIndex = W3T_DoodadScanCount
        endif
        loop
            exitwhen W3T_DoodadScanIndex >= stopIndex
            set doodadId = BlzGetDoodadId(W3T_DoodadScanIndex)
            if doodadId == 0 then
                set W3T_DoodadScanInvalid = W3T_DoodadScanInvalid + 1
            endif
            if BlzGetDoodadIsUsingModelAxes(W3T_DoodadScanIndex) then
                set W3T_DoodadScanModelAxes = W3T_DoodadScanModelAxes + 1
            endif
            if RAbsBJ(BlzGetDoodadPitch(W3T_DoodadScanIndex)) > 0.001 or RAbsBJ(BlzGetDoodadRoll(W3T_DoodadScanIndex)) > 0.001 then
                set W3T_DoodadScanRotated = W3T_DoodadScanRotated + 1
            endif
            set scaleX = BlzGetDoodadScaleX(W3T_DoodadScanIndex)
            set scaleY = BlzGetDoodadScaleY(W3T_DoodadScanIndex)
            set scaleZ = BlzGetDoodadScaleZ(W3T_DoodadScanIndex)
            if RAbsBJ(scaleX - scaleY) > 0.001 or RAbsBJ(scaleX - scaleZ) > 0.001 then
                set W3T_DoodadScanNonUniformScale = W3T_DoodadScanNonUniformScale + 1
            endif
            set W3T_DoodadScanIdChecksum = W3T_DoodadScanIdChecksum + doodadId
            set W3T_DoodadScanPositionChecksum = W3T_DoodadScanPositionChecksum + R2I(BlzGetDoodadX(W3T_DoodadScanIndex)) + R2I(BlzGetDoodadY(W3T_DoodadScanIndex)) + R2I(BlzGetDoodadZ(W3T_DoodadScanIndex))
            set W3T_DoodadScanIndex = W3T_DoodadScanIndex + 1
        endloop

        if W3T_DoodadScanIndex >= W3T_DoodadScanCount then
            call W3T_FinishDoodadScan()
        endif
    endfunction

    private function W3T_StartDoodadScan takes player whichPlayer returns nothing
        if W3T_DoodadScanActive then
            call W3T_Message(whichPlayer, "A doodad scan is already active for " + GetPlayerName(W3T_DoodadScanPlayer) + ".")
            return
        endif
        if W3T_DoodadScanTimer == null then
            set W3T_DoodadScanTimer = CreateTimer()
            set W3T_DoodadScanClock = CreateTimer()
        endif
        set W3T_DoodadScanPlayer = whichPlayer
        set W3T_DoodadScanActive = true
        set W3T_DoodadScanIndex = 0
        set W3T_DoodadScanCount = BlzGetNumDoodads()
        set W3T_DoodadScanInvalid = 0
        set W3T_DoodadScanModelAxes = 0
        set W3T_DoodadScanRotated = 0
        set W3T_DoodadScanNonUniformScale = 0
        set W3T_DoodadScanIdChecksum = 0
        set W3T_DoodadScanPositionChecksum = 0
        call TimerStart(W3T_DoodadScanClock, 86400.00, false, null)
        call TimerStart(W3T_DoodadScanTimer, W3T_DOODAD_SCAN_PERIOD, true, function W3T_DoodadScanPeriodic)
        call W3T_Message(whichPlayer, "Started read-only doodad scan in batches of " + I2S(W3T_DOODAD_SCAN_BATCH_SIZE) + ".")
    endfunction

    private function W3T_CancelDoodadScan takes player whichPlayer returns nothing
        if not W3T_DoodadScanActive then
            call W3T_Message(whichPlayer, "No doodad scan is active.")
            return
        endif
        call PauseTimer(W3T_DoodadScanTimer)
        set W3T_DoodadScanActive = false
        set W3T_DoodadScanPlayer = null
        call W3T_Message(whichPlayer, "Doodad scan cancelled at index " + I2S(W3T_DoodadScanIndex) + ".")
    endfunction

    private function W3T_InspectDoodad takes player whichPlayer, integer index returns nothing
        local integer count = BlzGetNumDoodads()
        local integer doodadId

        if index < 0 or index >= count then
            call W3T_Message(whichPlayer, "Doodad index must be between 0 and " + I2S(count - 1) + ".")
            return
        endif
        set doodadId = BlzGetDoodadId(index)
        call W3T_Message(whichPlayer, "Doodad[" + I2S(index) + "]=" + W3T_RawCodeText(doodadId) + ", variation=" + I2S(BlzGetDoodadVariation(index)) + ", managed=" + W3T_BooleanText(W3T_IsManagedDoodad(doodadId)) + ".")
        call W3T_Message(whichPlayer, "Position=" + R2S(BlzGetDoodadX(index)) + "," + R2S(BlzGetDoodadY(index)) + "," + R2S(BlzGetDoodadZ(index)) + "; scale=" + R2S(BlzGetDoodadScaleX(index)) + "," + R2S(BlzGetDoodadScaleY(index)) + "," + R2S(BlzGetDoodadScaleZ(index)) + ".")
        call W3T_Message(whichPlayer, "Yaw/pitch/roll=" + R2S(BlzGetDoodadYaw(index)) + "," + R2S(BlzGetDoodadPitch(index)) + "," + R2S(BlzGetDoodadRoll(index)) + "; modelAxes=" + W3T_BooleanText(BlzGetDoodadIsUsingModelAxes(index)) + ".")
    endfunction

    private function W3T_ResetDoodadProbe takes player whichPlayer returns nothing
        if W3T_DoodadProbeIndex < 0 then
            call W3T_Message(whichPlayer, "No doodad animation probe is active.")
            return
        endif
        call BlzSetSingleDoodadAnimation(W3T_DoodadProbeIndex, "show", false)
        call W3T_Message(whichPlayer, "Reset doodad probe index " + I2S(W3T_DoodadProbeIndex) + " with the show animation.")
        set W3T_DoodadProbeIndex = -1
    endfunction

    private function W3T_HideDoodadProbe takes player whichPlayer, integer index returns nothing
        local integer count = BlzGetNumDoodads()
        local integer doodadId

        if index < 0 or index >= count then
            call W3T_Message(whichPlayer, "Doodad index must be between 0 and " + I2S(count - 1) + ".")
            return
        endif
        set doodadId = BlzGetDoodadId(index)
        if W3T_IsManagedDoodad(doodadId) then
            call W3T_Message(whichPlayer, "Probe rejected: " + W3T_RawCodeText(doodadId) + " is owned by DoodadRender.")
            return
        endif
        if W3T_DoodadProbeIndex >= 0 then
            call W3T_ResetDoodadProbe(whichPlayer)
        endif
        set W3T_DoodadProbeIndex = index
        call BlzSetSingleDoodadAnimation(index, "hide", false)
        call W3T_Message(whichPlayer, "Hidden doodad index " + I2S(index) + ". Use /debug wc3 doodads probe reset.")
    endfunction

    private function W3T_ShowStatus takes player whichPlayer returns nothing
        call W3T_Message(whichPlayer, "Harness 0.3.1 for game build " + W3T_GAME_BUILD + "; every mutation requires an explicit command.")
        call W3T_ShowCamera(whichPlayer)
        call W3T_ShowFog(whichPlayer)
        call W3T_ShowDoodads(whichPlayer)
    endfunction

    private function W3T_ReportCheck takes player whichPlayer, string label, boolean passed returns integer
        if passed then
            call W3T_Message(whichPlayer, "PASS: " + label)
            return 1
        endif
        call W3T_Message(whichPlayer, "FAIL: " + label)
        return 0
    endfunction

    private function W3T_IsNormalizedColor takes real value returns boolean
        return value >= 0.00 and value <= 1.00
    endfunction

    private function W3T_RunSelfTest takes player whichPlayer returns nothing
        local integer passed = 0
        local integer total = 0
        local integer cameraType

        // All queried camera and client values are local presentation state.
        if GetLocalPlayer() == whichPlayer then
            set cameraType = BlzCameraGetCameraType()
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "local client dimensions are available", BlzGetLocalClientWidth() > 0 and BlzGetLocalClientHeight() > 0)
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "camera type is in the probed 0-16 range", cameraType >= 0 and cameraType <= 16)
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "fog override depth is non-negative", FogSystem_GetOverrideDepth() >= 0)
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "current fog color is normalized", W3T_IsNormalizedColor(FogSystem_GetCurrentRed(whichPlayer)) and W3T_IsNormalizedColor(FogSystem_GetCurrentGreen(whichPlayer)) and W3T_IsNormalizedColor(FogSystem_GetCurrentBlue(whichPlayer)))
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "target fog color is normalized", W3T_IsNormalizedColor(FogSystem_GetTargetRed(whichPlayer)) and W3T_IsNormalizedColor(FogSystem_GetTargetGreen(whichPlayer)) and W3T_IsNormalizedColor(FogSystem_GetTargetBlue(whichPlayer)))
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "full PotS map exposes doodad instances", BlzGetNumDoodads() > 0)
            set total = total + 1
            set passed = passed + W3T_ReportCheck(whichPlayer, "enabled camera ownership remains applied", not CameraControl_IsExperimentalInputOwnershipEnabled(whichPlayer) or CameraControl_IsExperimentalInputOwnershipApplied(whichPlayer))
            call W3T_Message(whichPlayer, "Self-test result: " + I2S(passed) + "/" + I2S(total) + " checks passed; no state was changed.")
        endif
    endfunction

    public function Execute takes player whichPlayer, string command returns boolean
        local string lowerCommand = StringCase(command, false)
        local string argument

        if lowerCommand == "wc3" or lowerCommand == "wc3 help" then
            call W3T_ShowHelp(whichPlayer)
        elseif lowerCommand == "wc3 status" then
            call W3T_ShowStatus(whichPlayer)
        elseif lowerCommand == "wc3 selftest" then
            call W3T_RunSelfTest(whichPlayer)
        elseif lowerCommand == "wc3 camera" or lowerCommand == "wc3 camera status" then
            call W3T_ShowCamera(whichPlayer)
        elseif lowerCommand == "wc3 camera orbit on" then
            call W3T_SetCameraOrbit(whichPlayer, true)
        elseif lowerCommand == "wc3 camera orbit off" then
            call W3T_SetCameraOrbit(whichPlayer, false)
        elseif lowerCommand == "wc3 camera ownership on" then
            call W3T_SetCameraInputOwnership(whichPlayer, true)
        elseif lowerCommand == "wc3 camera ownership off" or lowerCommand == "wc3 camera ownership reset" then
            call W3T_SetCameraInputOwnership(whichPlayer, false)
        elseif lowerCommand == "wc3 camera type" then
            call W3T_ShowCamera(whichPlayer)
        elseif W3T_StartsWith(lowerCommand, "wc3 camera type set ") then
            set argument = SubString(lowerCommand, StringLength("wc3 camera type set "), StringLength(lowerCommand))
            if W3T_IsUnsignedInteger(argument) then
                call W3T_SetCameraType(whichPlayer, S2I(argument))
            else
                call W3T_Message(whichPlayer, "Camera type must be an integer from 0 through 16.")
            endif
        elseif lowerCommand == "wc3 camera type reset" then
            call W3T_ResetCameraType(whichPlayer)
        elseif lowerCommand == "wc3 fog" or lowerCommand == "wc3 fog status" then
            call W3T_ShowFog(whichPlayer)
        elseif W3T_StartsWith(lowerCommand, "wc3 fog test ") then
            set argument = SubString(lowerCommand, StringLength("wc3 fog test "), StringLength(lowerCommand))
            call W3T_ApplyFogTest(whichPlayer, argument)
        elseif lowerCommand == "wc3 fog reset" then
            call W3T_ResetFogTest(whichPlayer)
        elseif lowerCommand == "wc3 doodads" or lowerCommand == "wc3 doodad" or lowerCommand == "wc3 doodads status" then
            call W3T_ShowDoodads(whichPlayer)
        elseif lowerCommand == "wc3 doodads scan" then
            call W3T_StartDoodadScan(whichPlayer)
        elseif lowerCommand == "wc3 doodads scan cancel" or lowerCommand == "wc3 doodads cancel" then
            call W3T_CancelDoodadScan(whichPlayer)
        elseif W3T_StartsWith(lowerCommand, "wc3 doodads inspect ") then
            set argument = SubString(lowerCommand, StringLength("wc3 doodads inspect "), StringLength(lowerCommand))
            if W3T_IsUnsignedInteger(argument) then
                call W3T_InspectDoodad(whichPlayer, S2I(argument))
            else
                call W3T_Message(whichPlayer, "Doodad index must be a non-negative integer.")
            endif
        elseif W3T_StartsWith(lowerCommand, "wc3 doodads probe hide ") then
            set argument = SubString(lowerCommand, StringLength("wc3 doodads probe hide "), StringLength(lowerCommand))
            if W3T_IsUnsignedInteger(argument) then
                call W3T_HideDoodadProbe(whichPlayer, S2I(argument))
            else
                call W3T_Message(whichPlayer, "Doodad index must be a non-negative integer.")
            endif
        elseif lowerCommand == "wc3 doodads probe reset" then
            call W3T_ResetDoodadProbe(whichPlayer)
        else
            return false
        endif

        return true
    endfunction
endlibrary
