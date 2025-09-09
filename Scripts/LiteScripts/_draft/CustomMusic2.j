library meh
    function pft takes nothing returns nothing
    local sound s = CreateSound("Musics\\Test-01.mp3", false, false, false, 12700, 12700, "")
        call BJDebugMsg("init")
        call TriggerSleepAction(1)
        call BJDebugMsg("start")
        call StartSound(s)
    endfunction
endlibrary