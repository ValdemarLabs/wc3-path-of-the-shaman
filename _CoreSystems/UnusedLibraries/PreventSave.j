library PreventSave initializer onInit
//====================================
//  by TriggerHappy
//====================================
//
//  This library allows you to enable or disable game saving. 
//  It works by showing a dialog instantly before a game is saved which interrupts it.
//  It does nothing visually to the game that I've noticed.
//
//  You can toggle saving for a specific player with the PreventSave function.
//  Example:
//      call PreventSave(Player(0), true) - disables saving for player 0
//
//  You also can toggle for everybody by setting
//  GameAllowSave to true, or false.
//
//====================================
// Import Instructions
//====================================
//
//  Decide whether you want GUI or vJASS, then copy the triggers or script over to your map.
//  This script requires JassHelper which is included in JassNewGenPack.
//
//====================================
    
    globals
        boolean GameAllowSave = false
    endglobals
    
//====================================
// Do not edit below this line
//====================================
    
    globals
        private dialog Dialog = DialogCreate()
        private timer  Timer  = CreateTimer()
        private player localplayer
    endglobals
    
    function PreventSave takes player p, boolean flag returns nothing
        if (p == localplayer) then
            set GameAllowSave = not flag
        endif
    endfunction
    
    private function Exit takes nothing returns nothing
        call DialogDisplay(localplayer, Dialog, false)
    endfunction
    
    private function StopSave takes nothing returns boolean
        if not GameAllowSave then
            call DialogDisplay(localplayer, Dialog, true)
        endif
        call TimerStart(Timer, 0.00, false, function Exit)
        return false
    endfunction
    
    private function onInit takes nothing returns nothing
        local trigger t = CreateTrigger()
        set localplayer = GetLocalPlayer()
        
        call TriggerRegisterGameEvent(t, EVENT_GAME_SAVE)
        call TriggerAddCondition(t, function StopSave)
    endfunction

endlibrary