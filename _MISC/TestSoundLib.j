library TestSoundLib initializer Init

/*
    Simple test library to verify WE sound variable references
    
    Setup in World Editor:
    1. Open Trigger Editor (F4)
    2. Click Variables (Ctrl+B)
    3. Create a Sound variable named: TestSound
    4. Assign it any imported sound file
    
    This will create: gg_snd_TestSound
*/

private function TestPlaySound takes nothing returns nothing
    // Reference WE sound variable directly without storing it
    if gg_snd_TestSound != null then
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[TestSoundLib] Sound variable found - playing sound")
        call StartSound(gg_snd_TestSound)
    else
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[TestSoundLib] ERROR: Sound variable is null - assign a sound to 'TestSound' in WE Variables")
    endif
endfunction

private function Init takes nothing returns nothing
    local trigger t = CreateTrigger()
    
    call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, "[TestSoundLib] Initialized")
    
    // Test the sound after 5 seconds
    call TriggerRegisterTimerEvent(t, 5.0, false)
    call TriggerAddAction(t, function TestPlaySound)
    
    set t = null
endfunction

endlibrary

