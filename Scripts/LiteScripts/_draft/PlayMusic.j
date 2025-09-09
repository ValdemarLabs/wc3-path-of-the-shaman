function PlayExMusic takes string path returns nothing
    call StopMusic(true) //Stops the currently playing music
    call PlayMusic(path)
endfunction

Set TempString = "MyExternalFolder\\MyMusic.mp3"
Custom Script: if GetSoundFileDuration(udg_TempString) > 0 then
Custom Script: call PlayMusic(udg_TempString)
Custom Script: endif
Custom Script: endif