/**
    VoicelinesGenericTroll

    Author: Valdemar
    Version: 1.2.0

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
        constant string VL_FORESTTROLL_0004_KEY = "ForestTroll_0004"
        constant string VL_FORESTTROLL_0004_TEXT = "Kill da outsiders! Leave none standin'!"
        constant string VL_FORESTTROLL_0005_KEY = "ForestTroll_0005"
        constant string VL_FORESTTROLL_0005_TEXT = "Drive dem from our village!"
        constant string VL_FORESTTROLL_0006_KEY = "ForestTroll_0006"
        constant string VL_FORESTTROLL_0006_TEXT = "Dey brought orcs into our home! Tear dem apart!"
        constant string VL_FORESTTROLL_0007_KEY = "ForestTroll_0007"
        constant string VL_FORESTTROLL_0007_TEXT = "Orcs? Why are ya turnin' your axes on us?"
        constant string VL_FORESTTROLL_0008_KEY = "ForestTroll_0008"
        constant string VL_FORESTTROLL_0008_TEXT = "What is dis madness? Da Horde attacks our village?"
        constant string VL_FORESTTROLL_0009_KEY = "ForestTroll_0009"
        constant string VL_FORESTTROLL_0009_TEXT = "Why do da orcs shield Darkspear? Drive dem all out!"
    endglobals

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence("GenericTroll_", 1, 50, "Pots\\Sound\\Voicelines\\GenericTroll\\")
    call ExSound_RegisterSequence("ForestTroll_", 1, 20, "Pots\\Sound\\Voicelines\\ForestTroll\\")
endfunction
endlibrary
