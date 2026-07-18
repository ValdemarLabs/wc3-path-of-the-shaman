/**
    VoicelinesKaelthir

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
    Global `VL_KAELTHIR_*` constants.

**/
library VoicelinesKaelthir requires Voicelines

globals
    constant string VL_KAELTHIR_FOLDER = "Kaelthir"

    // Legacy Excel draft/reference rows.

    // Excel draft: Kaelthir Lines | Event: Normal Greet | Done: x
    constant string VL_KAELTHIR_0001_KEY = "Kaelthir_0001"
    constant string VL_KAELTHIR_0001_TEXT = "Be careful... I'm still somewhat sane, but the others are not."
    constant string VL_KAELTHIR_0002_KEY = "Kaelthir_0002"
    constant string VL_KAELTHIR_0002_TEXT = "I can feel it eating what little I have left."

    // Excel draft: Kaelthir Lines | Event: Normal Greet
    constant string VL_KAELTHIR_0003_KEY = "Kaelthir_0003"
    constant string VL_KAELTHIR_0003_TEXT = "Every moment... I slip closer..."

    // Excel draft: Kaelthir Lines | Event: Normal Greet | Done: x
    constant string VL_KAELTHIR_0004_KEY = "Kaelthir_0004"
    constant string VL_KAELTHIR_0004_TEXT = "I can feel the void..."

    // Excel draft: Kaelthir Lines | Event: Farewell | Done: x
    constant string VL_KAELTHIR_0005_KEY = "Kaelthir_0005"
    constant string VL_KAELTHIR_0005_TEXT = "Please... come back!"
    constant string VL_KAELTHIR_0006_KEY = "Kaelthir_0006"
    constant string VL_KAELTHIR_0006_TEXT = "Don't leave me here!"
    constant string VL_KAELTHIR_0007_KEY = "Kaelthir_0007"
    constant string VL_KAELTHIR_0007_TEXT = "Must... resist... the darkness!"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Struggle | Event: Intro
    constant string VL_KAELTHIR_0009_KEY = "Kaelthir_0009"
    constant string VL_KAELTHIR_0009_TEXT = "Please... someone... I can feel it clawing at me. I am not ready... not yet."
    constant string VL_KAELTHIR_0010_KEY = "Kaelthir_0010"
    constant string VL_KAELTHIR_0010_TEXT = "I don't want to become like them."
    constant string VL_KAELTHIR_0011_KEY = "Kaelthir_0011"
    constant string VL_KAELTHIR_0011_TEXT = "Help me, orc. I can still remember who I was. But time is running out."

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Struggle | Event: Unfinished
    constant string VL_KAELTHIR_0012_KEY = "Kaelthir_0012"
    constant string VL_KAELTHIR_0012_TEXT = "Do not return empty-handed! I can feel it... gnawing!"
    constant string VL_KAELTHIR_0013_KEY = "Kaelthir_0013"
    constant string VL_KAELTHIR_0013_TEXT = "The hunger for magic is growing. Hurry... please, hurry!"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Struggle | Event: Completion
    constant string VL_KAELTHIR_0014_KEY = "Kaelthir_0014"
    constant string VL_KAELTHIR_0014_TEXT = "...Ah... it eases... just a little. I can still think... still feel..."
    constant string VL_KAELTHIR_0015_KEY = "Kaelthir_0015"
    constant string VL_KAELTHIR_0015_TEXT = "Thank you. For this moment... for what little comfort you could bring."

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Struggle | Event: Intro
    constant string VL_KAELTHIR_0016_KEY = "Kaelthir_0016"
    constant string VL_KAELTHIR_0016_TEXT = "Bring me any mana crystals you can find!"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger | Event: Intro
    constant string VL_KAELTHIR_0018_KEY = "Kaelthir_0018"
    constant string VL_KAELTHIR_0018_TEXT = "I can't resist any much longer..."
    constant string VL_KAELTHIR_0019_KEY = "Kaelthir_0019"
    constant string VL_KAELTHIR_0019_TEXT = "Every heartbeat... every breath... it drags me closer."

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger
    constant string VL_KAELTHIR_0020_KEY = "Kaelthir_0020"
    constant string VL_KAELTHIR_0020_TEXT = "It burns. Do something, anything!"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger | Event: Mercy Kill
    constant string VL_KAELTHIR_0023_KEY = "Kaelthir_0023"
    constant string VL_KAELTHIR_0023_TEXT = "Thank you... for ending it quickly... I can rest... at last."

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger | Event: Feed mana crystal (becomes wraith)
    constant string VL_KAELTHIR_0024_KEY = "Kaelthir_0024"
    constant string VL_KAELTHIR_0024_TEXT = "Yes... YES... give me more! MORE!"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger | Event: Bring to Aradion (Attempted Cure)
    constant string VL_KAELTHIR_0025_KEY = "Kaelthir_0025"
    constant string VL_KAELTHIR_0025_TEXT = "Great farseer Aradion... can you still... save me?"

    // Excel draft: Kaelthir Lines | Quest: Kaelthir's Hunger | Event: death
    constant string VL_KAELTHIR_0026_KEY = "Kaelthir_0026"
    constant string VL_KAELTHIR_0026_TEXT = "Aaaaarrgh!"

    // Excel draft: Kaelthir Lines
    constant string VL_KAELTHIR_0031_KEY = "Kaelthir_0031"
    constant string VL_KAELTHIR_0031_TEXT = "Hold still, Kaelthir. I can... no. No, it's too late!"
endglobals

endlibrary
