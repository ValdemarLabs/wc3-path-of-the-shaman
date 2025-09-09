local sound s1 = CreateSound("Music\\Track-01.mp3", ...
local sound s2 = CreateSound("DefaultMusic.mp3", ...

// Then this code will run locally
if GetSoundFileDuration(s1) > 0 then // if the sound file exists
    call StartSound(s1)
endif