/**
    Voicelines

    Author: Valdemar
    Version:

    Description:
    Shared voiceline helpers for PotS speaker-specific libraries. Speaker
    libraries own their text/key constants and require this base library for
    sound path registration.

    Credits:
    - PotS voiceline workflow

    How to install:
    Import before `Voicelines_*.j` speaker libraries. Requires `ExSound.j`.

    API:
    call Voicelines_RegisterKey(speakerFolder, key)
    call Voicelines_RegisterKeyInSubfolder(speakerFolder, subfolder, key)
    call Voicelines_RegisterPaddedSequence(speakerFolder, base, first, last)
    call Voicelines_RegisterUnpaddedSequence(speakerFolder, subfolder, base, first, last)

**/
library Voicelines requires ExSound

globals
    constant string VOICELINES_GAME_ROOT = "Pots\\Sound\\Voicelines\\"
endglobals

public function RegisterKey takes string speakerFolder, string key returns nothing
    call ExSound_RegisterKeyInFolder(key, VOICELINES_GAME_ROOT + speakerFolder + "\\")
endfunction

public function RegisterKeyInSubfolder takes string speakerFolder, string subfolder, string key returns nothing
    call ExSound_RegisterKeyInFolder(key, VOICELINES_GAME_ROOT + speakerFolder + "\\" + subfolder + "\\")
endfunction

public function RegisterPaddedSequence takes string speakerFolder, string base, integer first, integer last returns nothing
    call ExSound_RegisterSequence(base, first, last, VOICELINES_GAME_ROOT + speakerFolder + "\\")
endfunction

public function RegisterUnpaddedSequence takes string speakerFolder, string subfolder, string base, integer first, integer last returns nothing
    call ExSound_RegisterUnpaddedSequence(base, first, last, VOICELINES_GAME_ROOT + speakerFolder + "\\" + subfolder + "\\")
endfunction

endlibrary
