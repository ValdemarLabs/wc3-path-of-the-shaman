library FixedCameraLock initializer Init
    /*
    =============================================================================================================================================================
                                                                     Fixed Camera Lock
                                                                        by Antares

                                    Locks the camera to a unit while dynamically adjusting the z-offset to disable awfulness.
                            
    =============================================================================================================================================================
                                                                          A P I
    =============================================================================================================================================================

    FCL_Lock(whichUnit, whichPlayer)            Locks the camera of the specified player to the specified unit.
    FCL_Release(whichPlayer)                    Releases the camera of the specified player.

    =============================================================================================================================================================
                                                                        C O N F I G
    =============================================================================================================================================================
    */

    globals
        private real ADJUSTMENT_INTERVAL           = 0.1
        private real ADJUSTMENT_STRENGTH_UP        = 1.0
        //The adjustment strength when the camera target is below the unit. This type of camera shift is always awful and I recommend a value of 1.
        private real ADJUSTMENT_STRENGTH_DOWN      = 1.0
        //The adjustment strength when the camera target is above the unit. This type of camera shift is actually useful, so you can disable it if you want to.

        //=======================================================================================================================================================

        private timer MASTER_TIMER = CreateTimer()
        private unit anchor
        private boolean lockEnabled = false
        private location moveableLoc = Location(0, 0)
		private trigger array relockTrigger
    endglobals

    private function GetLocZ takes real x, real y returns real
        call MoveLocation(moveableLoc, x, y)
        return GetLocationZ(moveableLoc)
    endfunction

    function FCL_Lock takes unit whichUnit, player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
			call EnableTrigger(relockTrigger[GetPlayerId(whichPlayer)])
            call SetCameraTargetController(whichUnit, 0, 0, false)
            set lockEnabled = true
            set anchor = whichUnit
        endif
    endfunction

    function FCL_Release takes player whichPlayer returns nothing
        if GetLocalPlayer() == whichPlayer then
			call DisableTrigger(relockTrigger[GetPlayerId(whichPlayer)])
            call ResetToGameCamera(0)
            set lockEnabled = false
        endif
    endfunction

    private function AdjustCameraHeight takes nothing returns nothing
        local real dz
        if lockEnabled then
            set dz = GetLocZ(GetUnitX(anchor), GetUnitY(anchor)) + GetUnitFlyHeight(anchor) - (GetCameraTargetPositionZ() - GetCameraField(CAMERA_FIELD_ZOFFSET))
            if dz > 0 then
                call SetCameraField(CAMERA_FIELD_ZOFFSET, ADJUSTMENT_STRENGTH_UP*dz, ADJUSTMENT_INTERVAL)
            else
                call SetCameraField(CAMERA_FIELD_ZOFFSET, ADJUSTMENT_STRENGTH_DOWN*dz, ADJUSTMENT_INTERVAL)
            endif
        endif
    endfunction
	
    private function RelockCamera takes nothing returns nothing
        if GetLocalPlayer() == GetTriggerPlayer() then
            call SetCameraTargetController(anchor, 0, 0, false)
        endif
    endfunction

    private function Init takes nothing returns nothing
		local player whichPlayer
		local integer i = 0
        call TimerStart(MASTER_TIMER, ADJUSTMENT_INTERVAL, true, function AdjustCameraHeight)

        loop
			exitwhen i > 23
            set whichPlayer = Player(i)
            if GetPlayerSlotState(whichPlayer) == PLAYER_SLOT_STATE_PLAYING and GetPlayerController(whichPlayer) == MAP_CONTROL_USER then
                set relockTrigger[i] = CreateTrigger()
                call BlzTriggerRegisterPlayerKeyEvent(relockTrigger[i], whichPlayer, OSKEY_C, 4, true)
                call TriggerAddAction(relockTrigger[i], function RelockCamera)
                call DisableTrigger(relockTrigger[i])
            endif
			set i = i + 1
        endloop
    endfunction
endlibrary