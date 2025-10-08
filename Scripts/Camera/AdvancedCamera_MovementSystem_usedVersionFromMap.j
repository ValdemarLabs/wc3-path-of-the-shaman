//TESH.scrollpos=0
//TESH.alwaysfold=0
library ArrowKeyMovement initializer Init requires KeyboardSystem, ArrowKeyMovementPlugins

    // Arrow key movement by The_Witcher
    //   this system allows each player to control 1 unit 
    //   with his arrow keys even if he doesn't own the unit!
    //   It features turning on the left and right arrow, walking foreward 
    //   by pressing the up arrow and walking backwards by pressing the down arrow...
    //
    // You can improve this system with plugins but you need vJass knowledge for that!
    //
    //  --> The TurnRate of a unit inside the object editor STILL influences the turn rate from this system <--
    //
    // Included functions:
    //
    //      SetMovementUnit ( whichunit, forWhichPlayer, walkAnimationIndex )
    //                          unit         player            integer
    //            this gives the player the arrow key movement control over the unit
    //            while the unit moves the animation of the given index is played
    //            (just try around to find the index... start at 0 and increase 
    //             by 1 until you find the walk index of that unit)
    //
    //
    //      ReleaseMovementUnit ( fromWhichPlayer )
    //                                player
    //            this function removes the control from a player
    //
    //
    //      GetMovementUnit ( fromWhichPlayer )    returns unit
    //                            player
    //            I think its self explaining...
    //
    //
    //      SetMovementUnitAnimation ( fromWhichPlayer, animation )
    //                                    player         integer
    //            this function allows ingame changing of the played animation of a unit


    // ------- SETUP PART ---------
    globals
        // the timer interval... increase if laggy
        private constant real INTERVAL = 0.01
    
        // the facing change in degrees each interval (must be a positive value)
        private constant real DEFAULT_VIEW_CHANGE = 4
    
        // when you move backwards you move slower than normal...
        private constant real BACKWARDS_MOVING_FACTOR = 0.7      
    
        // if the unit turns it will turn faster the longer it does...
        // some people may need that but then it should be 1.02 (1.0 means disabled)
        private constant real TURN_ACCELERATION = 1
    
        // (can only be 1 or -1) if you walk backwards you have 2 ways of turning
        //  1. way: pressing left will make the char turn left
        //  2. way: pressing left will make the char turn so he moves to the left                                                                 
        private constant integer REVERSED_BACKWARDS_MOVING = 1
    endglobals                            

    // whenever this function returns false for a unit it won't be moved even if the player
    //  presses the keys! change to create your own "No Movement" conditions
    private function MoveConditions takes unit u returns boolean
        return not IsUnitType(u,UNIT_TYPE_SLEEPING) and not IsUnitType(u,UNIT_TYPE_STUNNED) and not (IsUnitType(u,UNIT_TYPE_DEAD) or GetUnitTypeId(u) == 0 )
    endfunction

    //   --------- don't modify anything below this line ------------
    struct ArrowKeyMovement
        private static ArrowKeyMovement array all [12]       // = bj_MAX_PLAYERS
        private static timer tim
        
        
        integer walking
        unit u
        integer animation
        real SpeedFactor
        real ViewChange
        real SpecialDirection
        boolean SpecialDirectionActive
        
        static method operator [] takes player p returns ArrowKeyMovement
            local integer i = GetPlayerId(p)
            if .all[i] == 0 then
                set .all[i] = ArrowKeyMovement.create()
                set .all[i].SpeedFactor = 1
                set .all[i].SpecialDirection = 0
                set .all[i].SpecialDirectionActive = false
                set .all[i].ViewChange = DEFAULT_VIEW_CHANGE
            endif
            return .all[i]
        endmethod

        private static method Walking takes nothing returns nothing
            local integer i = 0
            local real x
            local real y
            local real X
            local real Y
            local boolean boolX
            local boolean boolY
            local boolean left
            local boolean right
            local boolean up
            local boolean down
            local ArrowKeyMovement mov
            loop
                exitwhen i >= 12              // = bj_MAX_PLAYERS
                set mov = .all[i]
                if mov.u != null and MoveConditions(mov.u) then
                    // special movement <-- plugins
                    if mov.SpecialDirectionActive then
                        if mov.walking != 1 then
                            call SetUnitTimeScale(mov.u,mov.SpeedFactor)
                            call SetUnitAnimationByIndex(mov.u,mov.animation)
                            set mov.walking = 1
                        else
                            call SetUnitTimeScale(mov.u,mov.SpeedFactor)
                        endif
                        set x = GetUnitX(mov.u)
                        set y = GetUnitY(mov.u)
                        set X = x + GetUnitMoveSpeed(mov.u)*INTERVAL * Cos(mov.SpecialDirection*bj_DEGTORAD) * mov.SpeedFactor
                        set Y = y + GetUnitMoveSpeed(mov.u)*INTERVAL * Sin(mov.SpecialDirection*bj_DEGTORAD) * mov.SpeedFactor
                        call SetUnitPosition(mov.u,X,Y)
                        if (RAbsBJ(GetUnitX(mov.u)-X)>0.5)or(RAbsBJ(GetUnitY(mov.u)-Y)>0.5)then
                            call SetUnitPosition(mov.u,X,y)
                            set boolX = RAbsBJ(GetUnitX(mov.u)-X)<=0.5
                            call SetUnitPosition(mov.u,x,Y)
                            set boolY = RAbsBJ(GetUnitY(mov.u)-Y)<=0.5
                            if boolX then
                                call SetUnitPosition(mov.u,X,y)
                            elseif boolY then
                                call SetUnitPosition(mov.u,x,Y)
                            else
                                call SetUnitPosition(mov.u,x,y)
                            endif
                        endif
                    else
                        // Normal movement
                        set left = IsKeyDown(KEY_LEFT,Player(i))
                        set right = IsKeyDown(KEY_RIGHT,Player(i))
                        set up = IsKeyDown(KEY_UP,Player(i))
                        set down = IsKeyDown(KEY_DOWN,Player(i))
                        //right down
                        if right then
                            if down then
                                call SetUnitFacing(mov.u,GetUnitFacing(mov.u)-mov.ViewChange * -REVERSED_BACKWARDS_MOVING)
                            else
                                call SetUnitFacing(mov.u,GetUnitFacing(mov.u)-mov.ViewChange)
                            endif
                            set mov.ViewChange = mov.ViewChange * TURN_ACCELERATION
                        elseif not left then
                            set mov.ViewChange = DEFAULT_VIEW_CHANGE
                        endif
                        //left down
                        if left then
                            if down then
                                call SetUnitFacing(mov.u,GetUnitFacing(mov.u)+mov.ViewChange * -REVERSED_BACKWARDS_MOVING)
                            else
                                call SetUnitFacing(mov.u,GetUnitFacing(mov.u)+mov.ViewChange)
                            endif
                            set mov.ViewChange = mov.ViewChange * TURN_ACCELERATION
                        elseif not right then
                            set mov.ViewChange = DEFAULT_VIEW_CHANGE
                        endif
                        if mov.ViewChange > 179 then
                            set mov.ViewChange = 179
                        endif
                        //up down
                        if up then
                            if mov.walking != 1 then
                                call SetUnitTimeScale(mov.u,mov.SpeedFactor)
                                call SetUnitAnimationByIndex(mov.u,mov.animation)
                                set mov.walking = 1
                            else
                                call SetUnitTimeScale(mov.u,mov.SpeedFactor)
                            endif
                            set x = GetUnitX(mov.u)
                            set y = GetUnitY(mov.u)
                            set X = x + GetUnitMoveSpeed(mov.u)*INTERVAL * Cos(GetUnitFacing(mov.u)*bj_DEGTORAD) * mov.SpeedFactor
                            set Y = y + GetUnitMoveSpeed(mov.u)*INTERVAL * Sin(GetUnitFacing(mov.u)*bj_DEGTORAD) * mov.SpeedFactor
                            //down down
                        elseif down then
                            if mov.walking != 2 then
                                call SetUnitTimeScale(mov.u,-BACKWARDS_MOVING_FACTOR * mov.SpeedFactor)
                                call SetUnitAnimationByIndex(mov.u,mov.animation)
                                set mov.walking = 2
                            else
                                call SetUnitTimeScale(mov.u,-BACKWARDS_MOVING_FACTOR * mov.SpeedFactor)
                            endif
                            set x = GetUnitX(mov.u)
                            set y = GetUnitY(mov.u)
                            set X = x - GetUnitMoveSpeed(mov.u) * INTERVAL * Cos(GetUnitFacing(mov.u)*bj_DEGTORAD) * BACKWARDS_MOVING_FACTOR * mov.SpeedFactor
                            set Y = y - GetUnitMoveSpeed(mov.u) * INTERVAL * Sin(GetUnitFacing(mov.u)*bj_DEGTORAD) * BACKWARDS_MOVING_FACTOR * mov.SpeedFactor
                        endif
                        //move
                        if down or up then
                            call SetUnitPosition(mov.u,X,Y)
                            if (RAbsBJ(GetUnitX(mov.u)-X)>0.5)or(RAbsBJ(GetUnitY(mov.u)-Y)>0.5)then
                                call SetUnitPosition(mov.u,X,y)
                                set boolX = RAbsBJ(GetUnitX(mov.u)-X)<=0.5
                                call SetUnitPosition(mov.u,x,Y)
                                set boolY = RAbsBJ(GetUnitY(mov.u)-Y)<=0.5
                                if boolX then
                                    call SetUnitPosition(mov.u,X,y)
                                elseif boolY then
                                    call SetUnitPosition(mov.u,x,Y)
                                else
                                    call SetUnitPosition(mov.u,x,y)
                                endif
                            endif
                        else
                            if mov.walking != 0 then
                                call SetUnitAnimation(mov.u,"stand")
                                call SetUnitTimeScale(mov.u,1)
                                set mov.walking = 0
                            endif
                        endif
                    endif
                endif
                set i = i + 1
            endloop
        endmethod
        
        static method onInit takes nothing returns nothing
            set .tim = CreateTimer()
            call TimerStart(.tim,INTERVAL,true,function ArrowKeyMovement.Walking)
        endmethod
    
    endstruct

    function GetMovementUnit takes player p returns unit
        return ArrowKeyMovement[p].u
    endfunction

    function SetMovementUnitAnimation takes player p, integer animation returns nothing
        set ArrowKeyMovement[p].animation = animation
    endfunction

    function ReleaseMovementUnit takes player p returns nothing
        if ArrowKeyMovement[p].u != null then 
            set ArrowKeyMovement[p].walking = 0
            call SetUnitAnimation(ArrowKeyMovement[p].u,"stand")
            call SetUnitTimeScale(ArrowKeyMovement[p].u,1)
            set ArrowKeyMovement[p].u = null
        endif
    endfunction

    function SetMovementUnit takes unit u, player p, integer anim returns nothing
        if u == null then
            call ReleaseMovementUnit(p)
            return
        endif
        if ArrowKeyMovement[p].u != null then
            call ReleaseMovementUnit(p)
        endif
        call SetUnitAnimation(ArrowKeyMovement[p].u,"stand")
        set ArrowKeyMovement[p].u = u
        set ArrowKeyMovement[p].animation = anim
    endfunction

    //! runtextmacro ArrowKeyMovement_Plugins_Functions()

    private function Init takes nothing returns nothing
        //! runtextmacro Init_ArrowKeyMovement_Plugins()
    endfunction

endlibrary
