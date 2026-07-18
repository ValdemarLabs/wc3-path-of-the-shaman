/**
    VoicelinesOrcQGiver

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
    Global `VL_ORCQGIVER_*` constants.

**/
library VoicelinesOrcQGiver requires Voicelines

globals
    constant string VL_ORCQGIVER_FOLDER = "OrcQGiver"

    // Legacy Excel draft/reference rows.

    // Excel draft: OrcQGiver Lines | Quest: The Human Threat | Done: x
    constant string VL_ORCQGIVER_0001_KEY = "XXX_0001"
    constant string VL_ORCQGIVER_0001_TEXT = "Listen up, maggots! We've got ourselves a little problem in the Riverbane!"
    constant string VL_ORCQGIVER_0002_KEY = "XXX_0002"
    constant string VL_ORCQGIVER_0002_TEXT = "Those puny humans think they can raid our settlements without consequences!"
    constant string VL_ORCQGIVER_0003_KEY = "XXX_0003"
    constant string VL_ORCQGIVER_0003_TEXT = "We're gonna show 'em the might of the orcish war machine! Fire and fury!"
    constant string VL_ORCQGIVER_0004_KEY = "XXX_0004"
    constant string VL_ORCQGIVER_0004_TEXT = "If you want to be worthy, go to the catapults and use them to destroy the human settlements!"
    constant string VL_ORCQGIVER_0005_KEY = "XXX_0005"
    constant string VL_ORCQGIVER_0005_TEXT = "We need torches to get these fiery catapults roaring! Fetch 'em quick!"
endglobals

endlibrary
