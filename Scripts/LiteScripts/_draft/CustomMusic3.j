library meh
    function pft1 takes nothing returns nothing
    local sound s = CreateSound("Pots\\Sound\\Music\\26. Haunted.mp3", false, false, false, 12700, 12700, "")
        call BJDebugMsg("init")
        call TriggerSleepAction(1)
        call BJDebugMsg("start")
        call StartSound(s)
    endfunction

    function pft2 takes nothing returns nothing
    local sound s = CreateSound("Pots\\Sound\\Music\\Music_Past Glory.mp3", false, false, false, 12700, 12700, "")
        call BJDebugMsg("init")
        call TriggerSleepAction(1)
        call BJDebugMsg("start")
        call StartSound(s)
    endfunction

    function pft3 takes nothing returns nothing
    local sound s = CreateSound("Pots\\Sound\\Music\\test1.mp3", false, false, false, 12700, 12700, "")
        call BJDebugMsg("init")
        call TriggerSleepAction(1)
        call BJDebugMsg("start")
        call StartSound(s)
    endfunction

endlibrary