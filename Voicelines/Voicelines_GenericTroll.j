/**
    VoicelinesGenericTroll

    Author: Valdemar
    Version:

    Description:

    Speaker-owned dialogue constants for unnamed troll story characters.

    Credits:

    How to install:

    Import after `Voicelines.j`. Audio files use the
    `Pots\Sound\Voicelines\GenericTroll\` directory.

    API:

    Global `VL_GENERICTROLL_*` constants.

**/
library VoicelinesGenericTroll initializer Init requires Voicelines
    globals
        constant string VL_GENERICTROLL_FOLDER = "GenericTroll"

        constant string VL_GENERICTROLL_0001_KEY = "GenericTroll_0001"
        constant string VL_GENERICTROLL_0001_TEXT = "Zul'kis... dey came from da trees. Most of us never even saw dem."
        constant string VL_GENERICTROLL_0002_KEY = "GenericTroll_0002"
        constant string VL_GENERICTROLL_0002_TEXT = "Zul'karak still lives. Dey dragged him toward Bramblehide Village."
        constant string VL_GENERICTROLL_0003_KEY = "GenericTroll_0003"
        constant string VL_GENERICTROLL_0003_TEXT = "But da ones who struck da shore... dey were—"
    endglobals

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence("GenericTroll_", 1, 50, "Pots\\Sound\\Voicelines\\GenericTroll\\")
endfunction
endlibrary
