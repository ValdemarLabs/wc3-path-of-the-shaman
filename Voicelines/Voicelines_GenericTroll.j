/**
    VoicelinesGenericTroll

    Author: Valdemar
    Version: 1.1.0

    Description:

    Speaker-owned dialogue constants for unnamed troll story characters.

    Credits:

    How to install:

    Import after `Voicelines.j`. Audio files use the GenericTroll and
    ForestTroll directories under `Pots\Sound\Voicelines\`.

    API:

    Global `VL_GENERICTROLL_*` and `VL_FORESTTROLL_*` constants.

**/
library VoicelinesGenericTroll initializer Init requires Voicelines
    globals
        constant string VL_GENERICTROLL_FOLDER = "GenericTroll"

        constant string VL_GENERICTROLL_0001_KEY = "GenericTroll_0001"
        constant string VL_GENERICTROLL_0001_TEXT = "Zul'kis... dey came from da trees. Most of us never even saw dem."
        constant string VL_GENERICTROLL_0002_KEY = "GenericTroll_0002"
        constant string VL_GENERICTROLL_0002_TEXT = "Zul'karak still lives. Dey forest trolls dragged him to nearby village."
        constant string VL_GENERICTROLL_0003_KEY = "GenericTroll_0003"
        constant string VL_GENERICTROLL_0003_TEXT = "But da ones who struck da shore... dey were—"
        constant string VL_GENERICTROLL_0004_KEY = "GenericTroll_0004"
        constant string VL_GENERICTROLL_0004_TEXT = "Zul'kis... over here, mon..."

        constant string VL_FORESTTROLL_0001_KEY = "ForestTroll_0001"
        constant string VL_FORESTTROLL_0001_TEXT = "What's da meaning of dis? Who let dem through?"
        constant string VL_FORESTTROLL_0002_KEY = "ForestTroll_0002"
        constant string VL_FORESTTROLL_0002_TEXT = "Darkspear? Here? Sound da alarm!"
        constant string VL_FORESTTROLL_0003_KEY = "ForestTroll_0003"
        constant string VL_FORESTTROLL_0003_TEXT = "How did ya reach dis village? Cut dem down!"
    endglobals

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence("GenericTroll_", 1, 50, "Pots\\Sound\\Voicelines\\GenericTroll\\")
    call ExSound_RegisterSequence("ForestTroll_", 1, 20, "Pots\\Sound\\Voicelines\\ForestTroll\\")
endfunction
endlibrary
