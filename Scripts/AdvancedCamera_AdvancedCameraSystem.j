library AdvancedCameraSystem initializer Init
    // Advanced Camera System by The_Witcher
    //
    // This is a very advanced advanced camera system which adjusts the camera 
    // distance to the target so the camera isn't looking through houses/trees/...
    // and the cameras angle of attack so the view isn't blocked because of hills...
    //
    // useful for RPGs and that stuff
    //
    // To bind the camera to a unit for a player use
    //   SetCameraUnit(  unit, player )
    //
    // if you want to have your normal camera again use
    //   ReleaseCameraUnit(  player  )
    //
    // in case you want to know which unit is bound to the camera for player xy use
    //   GetCameraUnit(  player  )
    //
    // to change the AngleOfAttack of a player ingame use
    //   SetCamDefaultAngleOfAttack(  Player, NewValue  )
    //
    // to change the maximal camera target distance of a player ingame use
    //   SetCamMaxDistance(  Player, NewValue  )
    //
    // to change the maximal distance behind the target, the z-offset is checked (for z-angle), of a player ingame use
    //   SetCamMaxZCheckDistance(  Player, NewValue  )
    //
    //   SETUP PART
    globals
        // The max. distance the camera can have to the target
        private real DEFAULT_MAX_DISTANCE = 1000
    
        // The max. distance the zOffset behind the unit is checked (for zAngle)
        private real DEFAULT_MAX_Z_CHECK_DISTANCE = 500
    
        // the camera angle of attack correction after the zAngle calculation
        private real DEFAULT_ANGLE_OF_ATTACK = -20
    
        // the timer interval (0.01 is best but can lagg in huge maps with many of these short intervals)
        private constant real INTERVAL = 0.03
    
        // the time the camera will need to adjust
        private constant real DELAY = 0.25
    
        // the standart z of the camera
        private constant real NORMAL_HEIGHT = 100
    
        // the accuracy increases if the value gets smaller
        private constant real ACCURACY = 50
    
        // the secondary accruracy when the camera reaches a barricade (just leave at this amount)
        private constant real EXTREME_ACCURACY = 10
    endglobals
    //  SETUP END

    // don't modify the code below!

    globals 
        private item ite
        private real array Aoa[15]
        private real array Dist[15]
        private real array CheckDist[15]
        private unit array CamUnit[15]
        private timer tim = CreateTimer()
        private location loc = Location(0,0)
        private integer active = 0
        private hashtable h = InitHashtable()
    endglobals

    private function IsCoordPathable takes real x, real y returns boolean
        call SetItemVisible(ite,true)
        call SetItemPosition(ite,x,y)
        set x = GetItemX( ite) - x
        set y = GetItemY( ite) - y
        call SetItemVisible(ite,false)
        if x < 1 and x > -1 and  y < 1 and y > -1 then
            return true
        endif
        return false
    endfunction    

    private function HideAllItems takes nothing returns nothing
        if IsItemVisible(GetEnumItem()) then
            call SaveInteger(h,GetHandleId(GetEnumItem()),0,1)
        endif
        call SetItemVisible(GetEnumItem(),false)
    endfunction

    private function ShowAllItems takes nothing returns nothing
        if LoadInteger(h,GetHandleId(GetEnumItem()),0) == 1 then
            call SetItemVisible(GetEnumItem(),true)
            call FlushChildHashtable(h,GetHandleId(GetEnumItem()))      
        endif
    endfunction

    private function Actions takes nothing returns nothing
        local real x
        local real y
        local real angle
        local real rz
        local real z
        local integer i = 0
        local integer Check
        local real CheckDistance
        local real DistanceDone
        local rect rec
        loop
            exitwhen i >= bj_MAX_PLAYERS
            if CamUnit[i] != null then
                set DistanceDone = 0
                set rz = 0
                set x = GetUnitX(CamUnit[i])
                set y = GetUnitY(CamUnit[i])
                set Check = 1
                set angle = (GetUnitFacing(CamUnit[i]) - 180)*bj_DEGTORAD
                set CheckDistance = ACCURACY
                set z = DEFAULT_ANGLE_OF_ATTACK
                if not IsUnitType(CamUnit[i], UNIT_TYPE_FLYING) then
                    loop
                        set x = x + CheckDistance * Cos(angle)
                        set y = y + CheckDistance * Sin(angle)
                        set DistanceDone = DistanceDone + CheckDistance
                        call MoveLocation(loc,x,y)
                        set z = GetLocationZ(loc)
                        if RAbsBJ(z) > RAbsBJ(rz) and DistanceDone <= CheckDist[i] then
                            set rz = z
                        endif
                        if not IsCoordPathable(x,y)then
                            set rec = Rect(x-ACCURACY,y-ACCURACY,x+ACCURACY,y+ACCURACY)
                            call EnumItemsInRect(rec,null, function HideAllItems)
                            if not IsCoordPathable(x,y)then
                                set Check = 0
                            endif
                            call RemoveRect(rec)
                        endif
                        if Check == 0 and CheckDistance == ACCURACY then
                            set DistanceDone = DistanceDone - CheckDistance
                            set x = x - CheckDistance * Cos(angle)
                            set y = y - CheckDistance * Sin(angle)
                            set Check = 1
                            set CheckDistance = EXTREME_ACCURACY
                        endif
                        exitwhen (Check == 0 and CheckDistance == EXTREME_ACCURACY) or DistanceDone > Dist[i]
                    endloop          
                else
                    set DistanceDone = Dist[i]
                endif
                call MoveLocation(loc,GetUnitX(CamUnit[i]),GetUnitY(CamUnit[i]))
                set x = GetLocationZ(loc)     
                loop
                    exitwhen x - rz < 180
                    set x = x - 180
                endloop               
                set z = Atan2(x-rz,200) * bj_RADTODEG + Aoa[i]
                if IsUnitType(CamUnit[i], UNIT_TYPE_FLYING) then
                    set z = Aoa[i]
                endif
                if GetLocalPlayer() == Player(i) then
                    call CameraSetSmoothingFactor(1)
                    call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, DistanceDone, DELAY)
                    call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, z, DELAY)
                    call SetCameraField(CAMERA_FIELD_ZOFFSET,GetCameraField(CAMERA_FIELD_ZOFFSET)+x+GetUnitFlyHeight(CamUnit[i])+NORMAL_HEIGHT-GetCameraTargetPositionZ(),DELAY)
                    call SetCameraField(CAMERA_FIELD_ROTATION, angle*bj_RADTODEG+180, DELAY)
                    call SetCameraTargetController(CamUnit[i],0,0,false)
                endif
            endif
            set i = i + 1
        endloop
        call EnumItemsInRect(bj_mapInitialPlayableArea,null, function ShowAllItems)  
        set rec = null
    endfunction

    function ReleaseCameraUnit takes player p returns nothing
        if CamUnit[GetPlayerId(p)] != null then
            set CamUnit[GetPlayerId(p)] = null
            call ResetToGameCameraForPlayer(p,0)
            if GetLocalPlayer() == p then
                call CameraSetSmoothingFactor(0)
            endif
            set active = active - 1
            if active == 0 then
                call PauseTimer(tim)
            endif
        endif
    endfunction

    function SetCameraUnit takes unit u, player owner returns nothing
        if CamUnit[GetPlayerId(owner)] != null then
            call ReleaseCameraUnit(owner)
        endif
        set CamUnit[GetPlayerId(owner)] = u
        set active = active + 1
        if active == 1 then
            call TimerStart(tim,INTERVAL,true,function Actions)
        endif
    endfunction

    function SetCamDefaultAngleOfAttack takes player p, real a returns nothing
        set Aoa[GetPlayerId(p)] = a
    endfunction

    function SetCamMaxDistance takes player p, real d returns nothing
        set Dist[GetPlayerId(p)] = d
    endfunction

    function SetCamMaxZCheckDistance takes player p, real d returns nothing
        set CheckDist[GetPlayerId(p)] = d
    endfunction

    function GetCameraUnit takes player pl returns unit
        return CamUnit[GetPlayerId(pl)]
    endfunction 

    private function Init takes nothing returns nothing
        local integer i = 0                   
        loop
            exitwhen i >= bj_MAX_PLAYERS
            set CamUnit[i] = null
            set Aoa[i] = DEFAULT_ANGLE_OF_ATTACK
            set Dist[i] = DEFAULT_MAX_DISTANCE
            set CheckDist[i] = DEFAULT_MAX_Z_CHECK_DISTANCE
            set i = i + 1
        endloop
        set ite = CreateItem( 'wolg', 0,0 )
        call SetItemVisible(ite,false)
    endfunction

endlibrary