/**
    VoicelinesZulkarak

    Author: Valdemar
    Version:

    Description:

    Speaker-owned dialogue constants for Zul'karak, Zul'kis's older brother.

    Credits:

    How to install:

    Import after `Voicelines.j`. Audio files use the
    `Pots\Sound\Voicelines\Zulkarak\` directory.

    API:

    Global `VL_ZULKARAK_*` constants.

**/
library VoicelinesZulkarak initializer Init requires Voicelines
    globals
        constant string VL_ZULKARAK_FOLDER = "Zulkarak"

        constant string VL_ZULKARAK_0001_KEY = "Zulkarak_0001"
        constant string VL_ZULKARAK_0001_TEXT = "I don't like dis, brother. Humans be crawlin' through these woods more every day."
        constant string VL_ZULKARAK_0002_KEY = "Zulkarak_0002"
        constant string VL_ZULKARAK_0002_TEXT = "Stay on ya guard. I be protectin' da ship and our people till ya return."
        constant string VL_ZULKARAK_0003_KEY = "Zulkarak_0003"
        constant string VL_ZULKARAK_0003_TEXT = "Took ya long enough, little brother. Bramblehide been askin' questions I got no answers for."
        constant string VL_ZULKARAK_0004_KEY = "Zulkarak_0004"
        constant string VL_ZULKARAK_0004_TEXT = "Good. I had enough of their hospitality."
    endglobals

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence("Zulkarak_", 1, 50, "Pots\\Sound\\Voicelines\\Zulkarak\\")
endfunction
endlibrary
