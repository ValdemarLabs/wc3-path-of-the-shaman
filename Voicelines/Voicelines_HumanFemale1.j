/**
    VoicelinesHumanFemale1

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
    Global `VL_HUMANFEMALE1_*` constants.

**/
library VoicelinesHumanFemale1 requires Voicelines

globals
    constant string VL_HUMANFEMALE1_FOLDER = "HumanFemale1"

    // Legacy Excel draft/reference rows.

    // Excel draft: HumanFemale1 Lines | Quest: The Human Threat | Event: Choice: Kill or spare | Done: x
    constant string VL_HUMANFEMALE1_0001_KEY = "HumanFemale1_0001"
    constant string VL_HUMANFEMALE1_0001_TEXT = "Please, orc stranger! Spare us! We're innocent folk just trying to live in peace!"

    // Excel draft: HumanFemale1 Lines | Quest: The Human Threat | Done: X
    constant string VL_HUMANFEMALE1_0002_KEY = "HumanFemale1_0002"
    constant string VL_HUMANFEMALE1_0002_TEXT = "The real troublemakers are the bandits who've been terrorizing everyone!"
    constant string VL_HUMANFEMALE1_0003_KEY = "HumanFemale1_0003"
    constant string VL_HUMANFEMALE1_0003_TEXT = "They took over our village and homes and killed most of our folk without mercy..."

    // Excel draft: HumanFemale1 Lines | Done: X
    constant string VL_HUMANFEMALE1_0004_KEY = "HumanFemale1_0004"
    constant string VL_HUMANFEMALE1_0004_TEXT = "If you can help us to defeat the bandits, we'll aid you in any way we can and we will swear that we will never enter your lands!"
    constant string VL_HUMANFEMALE1_0005_KEY = "HumanFemale1_0005"
    constant string VL_HUMANFEMALE1_0005_TEXT = "Thank you, brave warrior! You've saved our homes and our lives."
    constant string VL_HUMANFEMALE1_0006_KEY = "HumanFemale1_0006"
    constant string VL_HUMANFEMALE1_0006_TEXT = "You ruthless murderer!!!"
    constant string VL_HUMANFEMALE1_0007_KEY = "HumanFemale1_0007"
    constant string VL_HUMANFEMALE1_0007_TEXT = "Run for your lives!"
endglobals

endlibrary
