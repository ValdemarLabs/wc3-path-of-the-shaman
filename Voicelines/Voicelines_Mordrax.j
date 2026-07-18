/**
    VoicelinesMordrax

    Author: Valdemar
    Version:

    Description:
    Speaker-owned voiceline key/text constants migrated from legacy
    Excel draft/reference rows. Runtime consumers require this
    library directly when they need these constants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after `Voicelines.j`. Add runtime registration when a
    consumer starts using these constants.

    API:
    Global `VL_MORDRAX_*` constants.

**/
library VoicelinesMordrax requires Voicelines

globals
    constant string VL_MORDRAX_FOLDER = "Mordrax"

    // Legacy Excel draft/reference rows.

    // Excel draft: Mordrax | Event: Attacked | Done: x
    constant string VL_MORDRAX_0001_KEY = "Mordrax_0001"
    constant string VL_MORDRAX_0001_TEXT = "Who dares to challenge mighty Mordrax?!"

    // Excel draft: Mordrax | Event: Attacking | Done: x
    constant string VL_MORDRAX_0002_KEY = "Mordrax_0002"
    constant string VL_MORDRAX_0002_TEXT = "The skies shall burn by my wrath!"
    constant string VL_MORDRAX_0003_KEY = "Mordrax_0003"
    constant string VL_MORDRAX_0003_TEXT = "I will destroy you!"
    constant string VL_MORDRAX_0004_KEY = "Mordrax_0004"
    constant string VL_MORDRAX_0004_TEXT = "Pathetic weaklings!"

    // Excel draft: Mordrax | Event: Casting | Done: x
    constant string VL_MORDRAX_0005_KEY = "Mordrax_0005"
    constant string VL_MORDRAX_0005_TEXT = "Everything shall burn!"
    constant string VL_MORDRAX_0006_KEY = "Mordrax_0006"
    constant string VL_MORDRAX_0006_TEXT = "I will turn you to cinder!"

    // Excel draft: Mordrax | Event: Killing hero | Done: x
    constant string VL_MORDRAX_0007_KEY = "Mordrax_0007"
    constant string VL_MORDRAX_0007_TEXT = "You are entertaining."
    constant string VL_MORDRAX_0008_KEY = "Mordrax_0008"
    constant string VL_MORDRAX_0008_TEXT = "How amusing."

    // Excel draft: Mordrax | Event: LowHP | Done: x
    constant string VL_MORDRAX_0009_KEY = "Mordrax_0009"
    constant string VL_MORDRAX_0009_TEXT = "No... I have endured for centuries - I will not fall!"

    // Excel draft: Mordrax | Event: Death | Done: x
    constant string VL_MORDRAX_0010_KEY = "Mordrax_0010"
    constant string VL_MORDRAX_0010_TEXT = "I have failed... my Queen..."
endglobals

endlibrary
