library CombinedCameraSliderSystem
   
    //----------------------------------------------\\
    //                                              \\
    //  Version 1.2                                 \\
    //  Written by Sabe / Sabeximus#2923            \\
    //                                              \\
    //----------------------------------------------\\
   
   
    globals
        private framehandle      sliderDistance
        private framehandle      sliderDistanceLabel
        private framehandle      sliderAngleOfAttack
        private framehandle      sliderAngleOfAttackLabel
        private framehandle      sliderRotation
        private framehandle      sliderRotationLabel
        private framehandle      sliderHeight
        private framehandle      sliderHeightLabel
        private framehandle      resetButton
        private framehandle      sliderAbove
       
        private framepointtype   framepointVerticalMain
        private framepointtype   framepointVerticalSecondary
        private framepointtype   framepointCornerMain
       
        private framepointtype   framepointCheckboxMain
        private framepointtype   framepointCheckboxSecondary
       
        private boolean  array   leftArrowIsDown
        private boolean  array   upArrowIsDown
        private boolean  array   downArrowIsDown
        private boolean  array   rightArrowIsDown
        private boolean  array   wKeyIsDown
        private boolean  array   aKeyIsDown
        private boolean  array   sKeyIsDown
        private boolean  array   dKeyIsDown
        private boolean  array   xKeyIsDown
        private real     array   horizontalChange
        private real     array   verticalChange

        private real     array   xTarget
        private real     array   yTarget
        private real     array   forward
        private real     array   sideways
        private real     array   orderDelay
        private real     array   fullTurnDelay
        private boolean          debugMode                    = false
    endglobals
   
    private function LoadToc takes string s returns nothing
        if not BlzLoadTOCFile(s) then
            call BJDebugMsg("|cffff0000Failed to Load: " + s + "|r \nYou need to import the |cffffcc00templates.toc|r file.")
        endif   
    endfunction

    private function UpdateCam takes nothing returns nothing
        local integer i = GetPlayerId(GetEnumPlayer())
        local unit u = udg_CCSS_TargetUnit[i + 1]
        local real facing = GetUnitFacing(u)
        local real moveSpeed = GetUnitMoveSpeed(u)
        local real x = GetUnitX(u)
        local real y = GetUnitY(u)
        local real hDir = 0
        local real vDir = 0
        call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_TARGET_DISTANCE, BlzFrameGetValue(sliderDistance), udg_CCSS_CamUpdateInterval)
       
        if (udg_CCSS_3rdPersonCamMode) then // Check if Third Person Camera mode is enabled
            if (((udg_CCSS_UseWASDKeys) or (udg_CCSS_UseNumpadKeys)) and (u != null)) then // Unit WASD control. Obviously, run these only if the WASD keys are enabled and there is a Target Unit
                if (wKeyIsDown[i]) then
                    set forward[i] = 1
                else
                    set forward[i] = 0
                endif

                if (aKeyIsDown[i]) then
                    set sideways[i] = sideways[i] - 1
                endif

                if (dKeyIsDown[i]) then
                    set sideways[i] = sideways[i] + 1
                endif

                set xTarget[i] = x
                set yTarget[i] = y

                if ((moveSpeed / udg_CCSS_WASDMoveSpeedModifier) < udg_CCSS_WASDMoveMinDistance) then
                    set moveSpeed = udg_CCSS_WASDMoveMinDistance
                else
                    set moveSpeed = moveSpeed / udg_CCSS_WASDMoveSpeedModifier
                endif

                if (forward[i] == 1) then
                    set xTarget[i] = xTarget[i] + Cos(Deg2Rad(facing)) * (moveSpeed)
                    set yTarget[i] = yTarget[i] + Sin(Deg2Rad(facing)) * (moveSpeed)

                    if (sideways[i] < 0) then
                        set xTarget[i] = xTarget[i] + Cos(Deg2Rad(facing + 90)) * udg_CCSS_WASDTurnSpeed
                        set yTarget[i] = yTarget[i] + Sin(Deg2Rad(facing + 90)) * udg_CCSS_WASDTurnSpeed
                        call IssuePointOrder(u, "move", xTarget[i], yTarget[i])
                        set sideways[i] = 0
                    endif
               
                    if (sideways[i] > 0) then
                        set xTarget[i] = xTarget[i] + Cos(Deg2Rad(facing + 270)) * udg_CCSS_WASDTurnSpeed
                        set yTarget[i] = yTarget[i] + Sin(Deg2Rad(facing + 270)) * udg_CCSS_WASDTurnSpeed
                        call IssuePointOrder(u, "move", xTarget[i], yTarget[i])
                        set sideways[i] = 0
                    endif
                else
                    if (sideways[i] == -1) then
                        call SetUnitFacing(u, facing + (udg_CCSS_WASDStationaryTurnSpeed))
                        set sideways[i] = 0
                    endif

                    if (sideways[i] == 1) then
                        call SetUnitFacing(u, facing - (udg_CCSS_WASDStationaryTurnSpeed))
                        set sideways[i] = 0
                    endif

                    if (udg_CCSS_SButtonOrder != "") then
                        if (sKeyIsDown[i]) then
                            call IssueImmediateOrder(u, udg_CCSS_SButtonOrder)
                        endif
                    endif

                    set fullTurnDelay[i] = fullTurnDelay[i] - udg_CCSS_CamUpdateInterval
                    if (fullTurnDelay[i] <= 0) then
                        if (udg_CCSS_SButton180Turn) then
                            if (sKeyIsDown[i]) then
                                set fullTurnDelay[i] = udg_CCSS_CamUpdateInterval * 10
                                call SetUnitFacing(u, facing - 180)
                            endif
                        endif

                        if (udg_CCSS_XButton180Turn) then
                            if (xKeyIsDown[i]) then
                                set fullTurnDelay[i] = udg_CCSS_CamUpdateInterval * 10
                                call SetUnitFacing(u, facing - 180)
                            endif
                        endif
                    endif
                endif

                set orderDelay[i] = orderDelay[i] - udg_CCSS_WASDMoveOrderInterval
                if (orderDelay[i] <= 0) then
                    set orderDelay[i] = 1
                    if ((forward[i] != 0) or (sideways[i] != 0)) then
                        call IssuePointOrder(u, "move", xTarget[i], yTarget[i])
                        set sideways[i] = 0
                    endif
                endif
            endif

            if (udg_CCSS_UseArrowKeys) then // Only run these if the Arrow Keys are used
               
                // Horizontal Key Register
                if (leftArrowIsDown[i]) then
                    if (udg_CCSS_InvertHorizontalMovement) then
                        if (horizontalChange[i] + (udg_CCSS_HorizontalSpeed * 3) > -udg_CCSS_HorizontalArrowMoveLimit) then
                            set hDir = hDir - 1
                        endif
                    else
                        if (horizontalChange[i] - (udg_CCSS_HorizontalSpeed * 3) < udg_CCSS_HorizontalArrowMoveLimit) then
                            set hDir = hDir + 1
                        endif
                    endif
                endif
                if (rightArrowIsDown[i]) then
                    if (udg_CCSS_InvertHorizontalMovement) then
                        if (horizontalChange[i] - (udg_CCSS_HorizontalSpeed * 3) < udg_CCSS_HorizontalArrowMoveLimit) then
                            set hDir = hDir + 1
                        endif
                    else
                        if (horizontalChange[i] + (udg_CCSS_HorizontalSpeed * 3) > -udg_CCSS_HorizontalArrowMoveLimit) then
                            set hDir = hDir - 1
                        endif
                    endif
                endif
               
                set horizontalChange[i] = horizontalChange[i] + (hDir * udg_CCSS_HorizontalSpeed)
                if ((hDir == 0) and (horizontalChange[i] != 0)) then
                    if (horizontalChange[i] > 0) then
                        set horizontalChange[i] = horizontalChange[i] - (udg_CCSS_HorizontalSpeed * udg_CCSS_HorizontalReturnSpeed)
                        if (horizontalChange[i] < udg_CCSS_HorizontalSpeed) then
                            set horizontalChange[i] = 0
                        endif
                    else
                        set horizontalChange[i] = horizontalChange[i] + (udg_CCSS_HorizontalSpeed * udg_CCSS_HorizontalReturnSpeed)
                        if (horizontalChange[i] > udg_CCSS_HorizontalSpeed) then
                            set horizontalChange[i] = 0
                        endif
                    endif
                endif

                // Vertical Key Register
                if (upArrowIsDown[i]) then
                    if (udg_CCSS_InvertVerticalMovement) then
                        if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i] + (udg_CCSS_HorizontalSpeed * 2)) > (udg_CCSS_AngleOfAttackMin)) then
                            set vDir = vDir - 1
                        endif
                    else
                        if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i] - (udg_CCSS_HorizontalSpeed * 2)) < (udg_CCSS_AngleOfAttackMax)) then // Don't allow the number to grow if camera had stopped at the limit
                            set vDir = vDir + 1
                        endif
                    endif
                endif
                if (downArrowIsDown[i]) then
                    if (udg_CCSS_InvertVerticalMovement) then
                        if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i] - (udg_CCSS_HorizontalSpeed * 2)) < (udg_CCSS_AngleOfAttackMax)) then
                            set vDir = vDir + 1
                        endif
                    else
                        if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i] + (udg_CCSS_HorizontalSpeed * 2)) > (udg_CCSS_AngleOfAttackMin)) then
                            set vDir = vDir - 1
                        endif
                    endif
                endif

                set verticalChange[i] = verticalChange[i] + (vDir * udg_CCSS_VerticalSpeed)
                if ((vDir == 0) and (verticalChange[i] != 0)) then
                    if (verticalChange[i] > 0) then
                        set verticalChange[i] = verticalChange[i] - (udg_CCSS_VerticalSpeed * udg_CCSS_VerticalReturnSpeed)
                        if (verticalChange[i] < udg_CCSS_VerticalSpeed) then
                            set verticalChange[i] = 0
                        endif
                    else
                        set verticalChange[i] = verticalChange[i] + (udg_CCSS_VerticalSpeed * udg_CCSS_VerticalReturnSpeed)
                        if (verticalChange[i] > udg_CCSS_VerticalSpeed) then
                            set verticalChange[i] = 0
                        endif
                    endif
                endif

               
            endif
           
            // Apply arrow key changes
            if (u != null) then // Check if our player has a Target Unit
                // Horizontal
                if (horizontalChange[i] > udg_CCSS_HorizontalArrowMoveLimit) then
                    call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ROTATION, facing + udg_CCSS_HorizontalArrowMoveLimit, udg_CCSS_CamUpdateInterval) // Prevent camera from rolling around the unit forever
                else
                    if (horizontalChange[i] < -udg_CCSS_HorizontalArrowMoveLimit) then
                        call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ROTATION, facing - udg_CCSS_HorizontalArrowMoveLimit, udg_CCSS_CamUpdateInterval)
                    else
                        call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ROTATION, facing + horizontalChange[i], udg_CCSS_CamUpdateInterval)
                    endif
                endif
               
                if (GetLocalPlayer() == Player(i)) then // Lock the rotation bar. Purely cosmetic, can be removed if, for example, causes desync problems. (The bar won't affect rotation even if not locked)
                     call BlzFrameSetEnable(sliderRotation, false) 
                endif

                // Vertical
                if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i]) > (udg_CCSS_AngleOfAttackMax)) then // Prevent camera from overstepping angle of attack slider maximum and minimum.
                    call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ANGLE_OF_ATTACK, udg_CCSS_AngleOfAttackMax, udg_CCSS_CamUpdateInterval)
                else
                    if ((BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i]) < (udg_CCSS_AngleOfAttackMin)) then
                        call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ANGLE_OF_ATTACK, udg_CCSS_AngleOfAttackMin, udg_CCSS_CamUpdateInterval)
                    else
                        call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ANGLE_OF_ATTACK, BlzFrameGetValue(sliderAngleOfAttack) + verticalChange[i], udg_CCSS_CamUpdateInterval)
                    endif
                endif

                // Add Unit Height to Camera
                if (udg_CCSS_AddUnitHeightToCamera) then
                    call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ZOFFSET, BlzFrameGetValue(sliderHeight) + GetUnitFlyHeight(u), udg_CCSS_CamUpdateInterval)
                endif

            else                // If doesn't have Target Unit
                // Horizontal
                call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ROTATION, BlzFrameGetValue(sliderRotation) + 90, udg_CCSS_CamUpdateInterval) // +90 Because I want the default rotation angle (90) to be zero for simplicity's sake
               
                if ((GetLocalPlayer() == GetEnumPlayer()) and (udg_CCSS_RotationEnabled)) then
                    call BlzFrameSetEnable(sliderRotation, true)
                endif

                // Vertical
                call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ANGLE_OF_ATTACK, BlzFrameGetValue(sliderAngleOfAttack), udg_CCSS_CamUpdateInterval)

                // Height
                call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ZOFFSET, BlzFrameGetValue(sliderHeight), udg_CCSS_CamUpdateInterval)
            endif
        else // Only run this if 3rdPC mode is not used
            call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ROTATION, BlzFrameGetValue(sliderRotation) + 90, udg_CCSS_CamUpdateInterval) // +90 so that 0 on the slider is the default WC3 angle
            call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ANGLE_OF_ATTACK, BlzFrameGetValue(sliderAngleOfAttack), udg_CCSS_CamUpdateInterval)
            call SetCameraFieldForPlayer(Player(i), CAMERA_FIELD_ZOFFSET, BlzFrameGetValue(sliderHeight), udg_CCSS_CamUpdateInterval)
        endif

        set u = null
    endfunction

    private function HumanPlayersPlaying takes nothing returns boolean
        if (GetPlayerController(GetFilterPlayer()) == MAP_CONTROL_USER) and (GetPlayerSlotState(GetFilterPlayer()) == PLAYER_SLOT_STATE_PLAYING) then
            return true
        else
            return false
        endif
    endfunction

    private function PreUpdateCam takes nothing returns nothing
        local force f = GetPlayersMatching(Condition(function HumanPlayersPlaying)) // No point in picking computer players
        call BlzFrameSetEnable(sliderDistance, udg_CCSS_DistanceEnabled)
        call BlzFrameSetEnable(sliderAngleOfAttack, udg_CCSS_AngleOfAttackEnabled)
        call BlzFrameSetEnable(sliderRotation, udg_CCSS_DistanceEnabled)
        call BlzFrameSetEnable(sliderHeight, udg_CCSS_HeightEnabled)
       
        if (udg_CCSS_ShowValues) then
            call BlzFrameSetText(sliderDistanceLabel, "Distance: " + R2SW(BlzFrameGetValue(sliderDistance), 1, 1))
            call BlzFrameSetText(sliderAngleOfAttackLabel, "Angle: " + R2SW(BlzFrameGetValue(sliderAngleOfAttack), 1, 1))
            call BlzFrameSetText(sliderRotationLabel, "Rotation: " + R2SW(BlzFrameGetValue(sliderRotation), 1, 1))
            call BlzFrameSetText(sliderHeightLabel, "Height: " + R2SW(BlzFrameGetValue(sliderHeight), 1, 1))
        else
            call BlzFrameSetText(sliderDistanceLabel, "Distance")
            call BlzFrameSetText(sliderAngleOfAttackLabel, "Angle")
            call BlzFrameSetText(sliderRotationLabel, "Rotation")
            call BlzFrameSetText(sliderHeightLabel, "Height")
        endif
       
        call ForForce(f, function UpdateCam)
        call DestroyForce(f)
    endfunction

    private function CreateSliders takes nothing returns nothing
        local real labelGap
        set sliderDistance = BlzCreateFrame("EscMenuSliderTemplate",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        set sliderDistanceLabel = BlzCreateFrame("EscMenuLabelTextTemplate",  sliderDistance, 0, 0)
        set sliderAngleOfAttack = BlzCreateFrame("EscMenuSliderTemplate",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 1)
        set sliderAngleOfAttackLabel = BlzCreateFrame("EscMenuLabelTextTemplate",  sliderAngleOfAttack, 0, 0)
        set sliderRotation = BlzCreateFrame("EscMenuSliderTemplate",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 2)
        set sliderRotationLabel = BlzCreateFrame("EscMenuLabelTextTemplate",  sliderRotation, 0, 0)
        set sliderHeight = BlzCreateFrame("EscMenuSliderTemplate",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 3)
        set sliderHeightLabel = BlzCreateFrame("EscMenuLabelTextTemplate",  sliderHeight, 0, 0)
        set sliderAbove = null
       
        if (udg_CCSS_PositionSlidersX >= 8) then
            set udg_CCSS_PositionSlidersX = 0.8
        else
            if (udg_CCSS_PositionSlidersX < 0) then
                set udg_CCSS_PositionSlidersX = 0
            else
                set udg_CCSS_PositionSlidersX = udg_CCSS_PositionSlidersX / 10 // GUI only allows 2 decimals for reals, so this way I can get 3 decimals for JASS
            endif
        endif

        if (udg_CCSS_PositionSlidersY >= 6) then
            set udg_CCSS_PositionSlidersY = 0.6
        else
            if (udg_CCSS_PositionSlidersY < 0) then
                set udg_CCSS_PositionSlidersY = 0
            else
                set udg_CCSS_PositionSlidersY = udg_CCSS_PositionSlidersY / 10
            endif
        endif
       
        set udg_CCSS_SliderGap = udg_CCSS_SliderGap / 10
       
        if (udg_CCSS_AlignmentLeft) then
            set framepointVerticalMain = FRAMEPOINT_LEFT
            set framepointVerticalSecondary = FRAMEPOINT_RIGHT
            set framepointCornerMain = FRAMEPOINT_TOPLEFT
            set labelGap = 0.005
        else
            set framepointVerticalMain = FRAMEPOINT_RIGHT
            set framepointVerticalSecondary = FRAMEPOINT_LEFT
            set framepointCornerMain = FRAMEPOINT_TOPRIGHT
            set labelGap = -0.005
        endif

        //Distance Slider options
        call BlzFrameSetAbsPoint(sliderDistance, framepointVerticalMain, udg_CCSS_PositionSlidersX, udg_CCSS_PositionSlidersY)
        call BlzFrameSetPoint(sliderDistanceLabel, framepointVerticalMain, sliderDistance, framepointVerticalSecondary, labelGap, 0)
        call BlzFrameSetMinMaxValue(sliderDistance, udg_CCSS_DistanceMin, udg_CCSS_DistanceMax)
        call BlzFrameSetValue(sliderDistance, udg_CCSS_DistanceDefault)
        call BlzFrameSetStepSize(sliderDistance, udg_CCSS_DistanceStep)
        call BlzFrameSetEnable(sliderDistance, udg_CCSS_DistanceEnabled)
        if (udg_CCSS_DistanceShow) then
            set sliderAbove = sliderDistance
        endif
        call BlzFrameSetVisible(sliderDistance, false)

        //Angle of Attack Slider options
        if (sliderAbove != null) then
            call BlzFrameSetPoint(sliderAngleOfAttack, FRAMEPOINT_TOPLEFT, sliderAbove, FRAMEPOINT_BOTTOMLEFT, 0, -udg_CCSS_SliderGap)
        else
            call BlzFrameSetAbsPoint(sliderAngleOfAttack, framepointVerticalMain, udg_CCSS_PositionSlidersX, udg_CCSS_PositionSlidersY)
        endif
        call BlzFrameSetPoint(sliderAngleOfAttackLabel, framepointVerticalMain, sliderAngleOfAttack, framepointVerticalSecondary, labelGap, 0)
        call BlzFrameSetMinMaxValue(sliderAngleOfAttack, udg_CCSS_AngleOfAttackMin, udg_CCSS_AngleOfAttackMax)
        call BlzFrameSetValue(sliderAngleOfAttack, udg_CCSS_AngleOfAttackDefault)
        call BlzFrameSetStepSize(sliderAngleOfAttack, udg_CCSS_AngleOfAttackStep)
        call BlzFrameSetEnable(sliderAngleOfAttack, udg_CCSS_AngleOfAttackEnabled)
        if (udg_CCSS_AngleOfAttackShow) then
            set sliderAbove = sliderAngleOfAttack
        endif
        call BlzFrameSetVisible(sliderAngleOfAttack, false)
       
        //Rotation Slider options
        if (sliderAbove != null) then
            call BlzFrameSetPoint(sliderRotation, FRAMEPOINT_TOPLEFT, sliderAbove, FRAMEPOINT_BOTTOMLEFT, 0, -udg_CCSS_SliderGap)
        else
            call BlzFrameSetAbsPoint(sliderRotation, framepointVerticalMain, udg_CCSS_PositionSlidersX, udg_CCSS_PositionSlidersY)
        endif
        call BlzFrameSetPoint(sliderRotationLabel, framepointVerticalMain, sliderRotation, framepointVerticalSecondary, labelGap, 0)
        call BlzFrameSetMinMaxValue(sliderRotation, udg_CCSS_RotationMin, udg_CCSS_RotationMax)
        call BlzFrameSetValue(sliderRotation, udg_CCSS_RotationDefault)
        call BlzFrameSetStepSize(sliderRotation, udg_CCSS_RotationStep)
        call BlzFrameSetEnable(sliderRotation, udg_CCSS_RotationEnabled)
        if (udg_CCSS_RotationShow) then
            set sliderAbove = sliderRotation
        endif
        call BlzFrameSetVisible(sliderRotation, false)
       
        //Height Slider options
        if (sliderAbove != null) then
            call BlzFrameSetPoint(sliderHeight, FRAMEPOINT_TOPLEFT, sliderAbove, FRAMEPOINT_BOTTOMLEFT, 0, -udg_CCSS_SliderGap)
        else
            call BlzFrameSetAbsPoint(sliderHeight, framepointVerticalMain, udg_CCSS_PositionSlidersX, udg_CCSS_PositionSlidersY)
        endif
        call BlzFrameSetPoint(sliderHeightLabel, framepointVerticalMain, sliderHeight, framepointVerticalSecondary, labelGap, 0)
        call BlzFrameSetMinMaxValue(sliderHeight, udg_CCSS_HeightMin, udg_CCSS_HeightMax)
        call BlzFrameSetValue(sliderHeight, udg_CCSS_HeightDefault)
        call BlzFrameSetStepSize(sliderHeight, udg_CCSS_HeightStep)
        call BlzFrameSetEnable(sliderHeight, udg_CCSS_HeightEnabled)
        if (udg_CCSS_HeightShow) then
            set sliderAbove = sliderHeight
        endif
        call BlzFrameSetVisible(sliderHeight, false)
    endfunction

    private function ResetSliders takes nothing returns nothing
        if GetLocalPlayer() == GetTriggerPlayer() then
            call BlzFrameSetValue(sliderDistance, udg_CCSS_DistanceDefault)
            call BlzFrameSetValue(sliderAngleOfAttack, udg_CCSS_AngleOfAttackDefault)
            call BlzFrameSetValue(sliderRotation, udg_CCSS_RotationDefault)
            call BlzFrameSetValue(sliderHeight, udg_CCSS_HeightDefault)
        endif
       
        call BlzFrameSetEnable(BlzGetTriggerFrame(), false)
        call BlzFrameSetEnable(BlzGetTriggerFrame(), true)
    endfunction

    private function CreateResetButton takes nothing returns nothing
        local trigger t = CreateTrigger()
        set resetButton = BlzCreateFrame("ScriptDialogButton",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        set udg_CCSS_ResetButtonSizeX = udg_CCSS_ResetButtonSizeX / 10
        set udg_CCSS_ResetButtonSizeY = udg_CCSS_ResetButtonSizeY / 10
       
        if (sliderAbove != null) then
            call BlzFrameSetPoint(resetButton, framepointCornerMain, sliderAbove, framepointVerticalMain, 0, -(udg_CCSS_SliderGap * 2))
        else
            call BlzFrameSetAbsPoint(resetButton, framepointVerticalMain, udg_CCSS_PositionSlidersX, udg_CCSS_PositionSlidersY)
        endif
        call BlzFrameSetSize(resetButton, udg_CCSS_ResetButtonSizeX, udg_CCSS_ResetButtonSizeY) 
        call BlzFrameSetText(resetButton, udg_CCSS_ResetButtonText)
        call BlzFrameSetVisible(resetButton, false)
       
        call TriggerAddAction(t, function ResetSliders)
        call BlzTriggerRegisterFrameEvent(t, resetButton, FRAMEEVENT_CONTROL_CLICK) 
    endfunction

    private function CheckBoxLockSliders takes nothing returns nothing
        local boolean b = (BlzGetTriggerFrameEvent() == FRAMEEVENT_CHECKBOX_CHECKED)
        if GetLocalPlayer() == GetTriggerPlayer() then
            if (udg_CCSS_DistanceShow) then
                call BlzFrameSetVisible(sliderDistance, b)
            endif
            if (udg_CCSS_AngleOfAttackShow) then
                call BlzFrameSetVisible(sliderAngleOfAttack, b)
            endif
            if (udg_CCSS_RotationShow) then
                call BlzFrameSetVisible(sliderRotation, b)
            endif
            if (udg_CCSS_HeightShow) then
                call BlzFrameSetVisible(sliderHeight, b)
            endif
            call BlzFrameSetVisible(resetButton, b)
        endif   
    endfunction

    private function CreateCheckbox takes nothing returns nothing
        local trigger t = CreateTrigger()
        local framehandle fh = BlzCreateFrame("QuestCheckBox",  BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), 0, 0)
        local framehandle label = BlzCreateFrame("EscMenuLabelTextTemplate",  fh, 0, 0)
        local real labelGap
       
        if (udg_CCSS_PositionCheckBoxX >= 8) then
            set udg_CCSS_PositionCheckBoxX = 0.8
        else
            if (udg_CCSS_PositionCheckBoxX < 0) then
                set udg_CCSS_PositionCheckBoxX = 0
            else
                set udg_CCSS_PositionCheckBoxX = udg_CCSS_PositionCheckBoxX / 10
            endif
        endif

        if (udg_CCSS_PositionCheckBoxY >= 6) then
            set udg_CCSS_PositionCheckBoxY = 0.6
        else
            if (udg_CCSS_PositionCheckBoxY < 0) then
                set udg_CCSS_PositionCheckBoxY = 0
            else
                set udg_CCSS_PositionCheckBoxY = udg_CCSS_PositionCheckBoxY / 10
            endif
        endif
       
        if (udg_CCSS_CheckBoxTextOnLeft) then
            set framepointCheckboxMain = FRAMEPOINT_RIGHT
            set framepointCheckboxSecondary = FRAMEPOINT_LEFT
            set labelGap = -0.005
        else
            set framepointCheckboxMain = FRAMEPOINT_LEFT
            set framepointCheckboxSecondary = FRAMEPOINT_RIGHT
            set labelGap = 0.005
        endif
       
        call BlzFrameSetPoint(label, framepointCheckboxMain, fh, framepointCheckboxSecondary, labelGap, 0)
        call BlzFrameSetAbsPoint(fh, framepointCheckboxMain, udg_CCSS_PositionCheckBoxX, udg_CCSS_PositionCheckBoxY)   
        call BlzFrameSetText(label, udg_CCSS_CheckBoxText)
        call BlzFrameSetVisible(fh, udg_CCSS_CheckBoxShow)
       
        call TriggerAddAction(t, function CheckBoxLockSliders)
        call BlzTriggerRegisterFrameEvent(t, fh, FRAMEEVENT_CHECKBOX_CHECKED)
        call BlzTriggerRegisterFrameEvent(t, fh, FRAMEEVENT_CHECKBOX_UNCHECKED)
    endfunction
   
    // Arrow keys
   
    private function LeftArrowPress takes nothing returns nothing
        set leftArrowIsDown[GetPlayerId(GetTriggerPlayer())] = true
    endfunction
   
    private function LeftArrowRelease takes nothing returns nothing
        set leftArrowIsDown[GetPlayerId(GetTriggerPlayer())] = false
    endfunction
   
    private function UpArrowPress takes nothing returns nothing
        set upArrowIsDown[GetPlayerId(GetTriggerPlayer())] = true
    endfunction
   
    private function UpArrowRelease takes nothing returns nothing
        set upArrowIsDown[GetPlayerId(GetTriggerPlayer())] = false
    endfunction
   
    private function DownArrowPress takes nothing returns nothing
        set downArrowIsDown[GetPlayerId(GetTriggerPlayer())] = true
    endfunction
   
    private function DownArrowRelease takes nothing returns nothing
        set downArrowIsDown[GetPlayerId(GetTriggerPlayer())] = false
    endfunction
   
    private function RightArrowPress takes nothing returns nothing
        set rightArrowIsDown[GetPlayerId(GetTriggerPlayer())] = true
    endfunction
   
    private function RightArrowRelease takes nothing returns nothing
        set rightArrowIsDown[GetPlayerId(GetTriggerPlayer())] = false
    endfunction

    private function ArrowKeyListeners takes nothing returns nothing
        local trigger tLp = CreateTrigger()
        local trigger tUp = CreateTrigger()
        local trigger tDp = CreateTrigger()
        local trigger tRp = CreateTrigger()
        local trigger tLr = CreateTrigger()
        local trigger tUr = CreateTrigger()
        local trigger tDr = CreateTrigger()
        local trigger tRr = CreateTrigger()
        local integer i
       
        set i = 0
        loop
            call TriggerRegisterPlayerKeyEventBJ(tLp, Player(i), bj_KEYEVENTTYPE_DEPRESS, bj_KEYEVENTKEY_LEFT)
            call TriggerRegisterPlayerKeyEventBJ(tLr, Player(i), bj_KEYEVENTTYPE_RELEASE, bj_KEYEVENTKEY_LEFT)
            call TriggerRegisterPlayerKeyEventBJ(tUp, Player(i), bj_KEYEVENTTYPE_DEPRESS, bj_KEYEVENTKEY_UP)
            call TriggerRegisterPlayerKeyEventBJ(tUr, Player(i), bj_KEYEVENTTYPE_RELEASE, bj_KEYEVENTKEY_UP)
            call TriggerRegisterPlayerKeyEventBJ(tDp, Player(i), bj_KEYEVENTTYPE_DEPRESS, bj_KEYEVENTKEY_DOWN)
            call TriggerRegisterPlayerKeyEventBJ(tDr, Player(i), bj_KEYEVENTTYPE_RELEASE, bj_KEYEVENTKEY_DOWN)
            call TriggerRegisterPlayerKeyEventBJ(tRp, Player(i), bj_KEYEVENTTYPE_DEPRESS, bj_KEYEVENTKEY_RIGHT)
            call TriggerRegisterPlayerKeyEventBJ(tRr, Player(i), bj_KEYEVENTTYPE_RELEASE, bj_KEYEVENTKEY_RIGHT)
            set i = i + 1
            exitwhen i > bj_MAX_PLAYER_SLOTS
        endloop
       
        call TriggerAddAction(tLp, function LeftArrowPress)
        call TriggerAddAction(tLr, function LeftArrowRelease)
        call TriggerAddAction(tUp, function UpArrowPress)
        call TriggerAddAction(tUr, function UpArrowRelease)
        call TriggerAddAction(tDp, function DownArrowPress)
        call TriggerAddAction(tDr, function DownArrowRelease)
        call TriggerAddAction(tRp, function RightArrowPress)
        call TriggerAddAction(tRr, function RightArrowRelease)
    endfunction

    // WASD keys

    private function WKey takes nothing returns nothing
        set wKeyIsDown[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        if (debugMode) then
            if BlzGetTriggerPlayerIsKeyDown() then
                call BJDebugMsg("W is pressed")
            else
                call BJDebugMsg("W is released")
            endif
        endif
    endfunction
   
    private function AKey takes nothing returns nothing
        set aKeyIsDown[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        if (debugMode) then
            if BlzGetTriggerPlayerIsKeyDown() then
                call BJDebugMsg("A is pressed")
            else
                call BJDebugMsg("A is released")
            endif
        endif
    endfunction
   
    private function SKey takes nothing returns nothing
        set sKeyIsDown[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        if (debugMode) then
            if BlzGetTriggerPlayerIsKeyDown() then
                call BJDebugMsg("S is pressed")
            else
                call BJDebugMsg("S is released")
            endif
        endif
    endfunction
   
    private function DKey takes nothing returns nothing
        set dKeyIsDown[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        if (debugMode) then
            if BlzGetTriggerPlayerIsKeyDown() then
                call BJDebugMsg("D is pressed")
            else
                call BJDebugMsg("D is released")
            endif
        endif
    endfunction

    private function XKey takes nothing returns nothing
        set xKeyIsDown[GetPlayerId(GetTriggerPlayer())] = BlzGetTriggerPlayerIsKeyDown()
        if (debugMode) then
            if BlzGetTriggerPlayerIsKeyDown() then
                call BJDebugMsg("X is pressed")
            else
                call BJDebugMsg("X is released")
            endif
        endif
    endfunction

    private function WASDKeyListeners takes nothing returns nothing
        local trigger tWp = CreateTrigger()
        local trigger tAp = CreateTrigger()
        local trigger tSp = CreateTrigger()
        local trigger tDp = CreateTrigger()
        local trigger tWr = CreateTrigger()
        local trigger tAr = CreateTrigger()
        local trigger tSr = CreateTrigger()
        local trigger tDr = CreateTrigger()
        local trigger tXp = CreateTrigger()
        local trigger tXr = CreateTrigger()
        local integer i
       
        set i = 0
        loop
            if (udg_CCSS_UseNumpadKeys) then
                call BlzTriggerRegisterPlayerKeyEvent(tWp, Player(i), OSKEY_NUMPAD8, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tWr, Player(i), OSKEY_NUMPAD8, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tAp, Player(i), OSKEY_NUMPAD4, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tAr, Player(i), OSKEY_NUMPAD4, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tSp, Player(i), OSKEY_NUMPAD5, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tSr, Player(i), OSKEY_NUMPAD5, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tDp, Player(i), OSKEY_NUMPAD6, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tDr, Player(i), OSKEY_NUMPAD6, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tXp, Player(i), OSKEY_NUMPAD2, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tXr, Player(i), OSKEY_NUMPAD2, 0, false)
            else
                call BlzTriggerRegisterPlayerKeyEvent(tWp, Player(i), OSKEY_W, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tWr, Player(i), OSKEY_W, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tAp, Player(i), OSKEY_A, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tAr, Player(i), OSKEY_A, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tSp, Player(i), OSKEY_S, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tSr, Player(i), OSKEY_S, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tDp, Player(i), OSKEY_D, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tDr, Player(i), OSKEY_D, 0, false)
                call BlzTriggerRegisterPlayerKeyEvent(tXp, Player(i), OSKEY_X, 0, true)
                call BlzTriggerRegisterPlayerKeyEvent(tXr, Player(i), OSKEY_X, 0, false)
            endif

            set orderDelay[i] = 0
            set fullTurnDelay[i] = 0
            set i = i + 1
            exitwhen i > bj_MAX_PLAYER_SLOTS
        endloop
       
        call TriggerAddAction(tWp, function WKey)
        call TriggerAddAction(tWr, function WKey)
        call TriggerAddAction(tAp, function AKey)
        call TriggerAddAction(tAr, function AKey)
        call TriggerAddAction(tSp, function SKey)
        call TriggerAddAction(tSr, function SKey)
        call TriggerAddAction(tDp, function DKey)
        call TriggerAddAction(tDr, function DKey)
        call TriggerAddAction(tXp, function XKey)
        call TriggerAddAction(tXr, function XKey)
    endfunction
   
   
//=============================================================================
    function CreateCamControl takes nothing returns nothing
        call LoadToc("war3mapimported\\templates.toc")
        call CreateSliders()
        call CreateCheckbox()
        call CreateResetButton()
        if ((udg_CCSS_3rdPersonCamMode) and (udg_CCSS_UseArrowKeys)) then // If 3rd Person Cam and Arrow keys aren't enabled, don't bother to create triggers for listening the keys
            call ArrowKeyListeners()
        endif
        if ((udg_CCSS_3rdPersonCamMode) and ((udg_CCSS_UseWASDKeys) or (udg_CCSS_UseNumpadKeys))) then
            call WASDKeyListeners()
        endif
        call TimerStart(CreateTimer(), udg_CCSS_CamUpdateInterval, true, function PreUpdateCam)

        set debugMode = false // Turn true for testing purposes
    endfunction
endlibrary