/**
    VoicelinesOrcGrunt

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
    Global `VL_ORCGRUNT_*` constants.

**/
library VoicelinesOrcGrunt requires Voicelines

globals
    constant string VL_ORCGRUNT_FOLDER = "Orc Grunt"

    // No Excel draft rows were mapped to this speaker yet.
endglobals

endlibrary
