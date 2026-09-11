/**
    VoicelinesGraknar

    Author: Valdemar
    Version: 1.0.0

    Description:
    Speaker-owned voiceline keys and text for Graknar's Mistaken Kin quest.

    Credits:
    - QuestsAndDialogs/QuestGivers/Orcs/qGraknar.j

    How to install:
    Import after `Voicelines.j`. Consumers require this library directly.

    API:
    Global `VL_GRAKNAR_####_*` constants.

**/
library VoicelinesGraknar initializer Init requires Voicelines

globals
    constant string VL_GRAKNAR_FOLDER = "Graknar"

    // Mistaken Kin quest dialogue.
    constant string VL_GRAKNAR_0001_KEY = "Graknar_0001"
    constant string VL_GRAKNAR_0001_TEXT = "Graknar lost Kodo near the salamanders. Find Kodo. Bring Kodo back."
    constant string VL_GRAKNAR_0002_KEY = "Graknar_0002"
    constant string VL_GRAKNAR_0002_TEXT = "Kodo gone, but Graknar knows where another wandered. Try again."
    constant string VL_GRAKNAR_0003_KEY = "Graknar_0003"
    constant string VL_GRAKNAR_0003_TEXT = "Kodo back. Good. Graknar carries bags again."
    constant string VL_GRAKNAR_0004_KEY = "Graknar_0004"
    constant string VL_GRAKNAR_0004_TEXT = "Kodo was lost. Graknar can show you where to search again."
    constant string VL_GRAKNAR_0005_KEY = "Graknar_0005"
    constant string VL_GRAKNAR_0005_TEXT = "Kodo home! Graknar sees."
    constant string VL_GRAKNAR_0006_KEY = "Graknar_0006"
    constant string VL_GRAKNAR_0006_TEXT = "Bring Kodo back. Kodo carries Graknar's best bags."
    constant string VL_GRAKNAR_0007_KEY = "Graknar_0007"
    constant string VL_GRAKNAR_0007_TEXT = "Kodo still lost near salamanders."
    constant string VL_GRAKNAR_0008_KEY = "Graknar_0008"
    constant string VL_GRAKNAR_0008_TEXT = "Strong bags. Strong price."
endglobals

private function Init takes nothing returns nothing
    call Voicelines_RegisterPaddedSequence(VL_GRAKNAR_FOLDER, "Graknar_", 1, 8)
endfunction

endlibrary
