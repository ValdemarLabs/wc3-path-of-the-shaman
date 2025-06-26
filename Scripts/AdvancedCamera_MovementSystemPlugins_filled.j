//TESH.scrollpos=0
//TESH.alwaysfold=0
library ArrowKeyMovementPlugins

    // code your own plugins for my Arrow key movement system!
    //   how you do that is explained in detail in the "How to use the Movement System Plugins"
    //   comment included in this map
    //
    //
    // the plugins I coded for the test map are:
    //      1. running fast/dashing when double pressing up
    //      2. turning around (180°) when double pressing down
    //      3. moving left without changing face direction when double pressing left
    //      4. moving right without changing face direction when double pressing right
        
    //! textmacro Init_ArrowKeyMovement_Plugins
        local trigger t
        // This is the initialization for turning around on double down press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleDownPress)
        call TriggerRegisterKeyDoublePressEvent(t,KEY_DOWN)
        
        // This is the initialization for dashing on double up press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleUpPress)
        call TriggerRegisterKeyDoublePressEvent(t,KEY_UP)
        
        // This is the initialization for sliding left on double left press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleLeftPress)
        call TriggerRegisterKeyDoublePressEvent(t,KEY_LEFT)
        
        // This is the initialization for sliding right on double right press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleRightPress)
        call TriggerRegisterKeyDoublePressEvent(t,KEY_RIGHT)
        
        // This is the initialization for stoping the dash of double up press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleUpRelease)
        call TriggerRegisterKeyDoubleInterruptEvent(t,KEY_UP)
        
        // This is the initialization for stoping slide of double left press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleLeftRelease)
        call TriggerRegisterKeyDoubleInterruptEvent(t,KEY_LEFT)
        
        // This is the initialization for stoping slide of double right press
        set t = CreateTrigger()
        call TriggerAddAction(t, function OnDoubleRightRelease)
        call TriggerRegisterKeyDoubleInterruptEvent(t,KEY_RIGHT)
    //! endtextmacro
    
    
    //! textmacro ArrowKeyMovement_Plugins_Functions
    
        // This is the function for turning around on double down press
        private function OnDoubleDownPress takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = false
            call SetUnitFacing(mov.u,GetUnitFacing(mov.u)-180)
        endfunction
    
        // This is the function for dashing on double up press
        private function OnDoubleUpPress takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = false
            set mov.SpeedFactor = 2
        endfunction
    
        // This is the function for sliding left on double left press
        private function OnDoubleLeftPress takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = true
            set mov.SpecialDirection = GetUnitFacing(mov.u) + 90
            set mov.SpeedFactor = 0.6
        endfunction
    
        // This is the function for sliding right on double right press
        private function OnDoubleRightPress takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = true
            set mov.SpecialDirection = GetUnitFacing(mov.u) - 90
            set mov.SpeedFactor = 0.6
        endfunction
    
        // This is the function for stoping the dash of double up press
        private function OnDoubleUpRelease takes nothing returns nothing
            set ArrowKeyMovement[GetTriggerPlayer()].SpeedFactor = 1
        endfunction
    
        // This is the function for stoping slide of double left press
        private function OnDoubleLeftRelease takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = false
            set mov.SpeedFactor = 1
        endfunction
    
        // This is the function for stoping slide of double right press
        private function OnDoubleRightRelease takes nothing returns nothing
            local ArrowKeyMovement mov = ArrowKeyMovement[GetTriggerPlayer()]
            set mov.SpecialDirectionActive = false
            set mov.SpeedFactor = 1
        endfunction
    
    //! endtextmacro
    
    endlibrary