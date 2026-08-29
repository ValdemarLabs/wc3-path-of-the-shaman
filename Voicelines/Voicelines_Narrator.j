/**
    VoicelinesNarrator

    Author: Valdemar
    Version: 1.0.3

    Description:
    Speaker-owned narrator voiceline key/text constants for story
    introductions, including migrated legacy Excel draft/reference rows.
    Runtime consumers require this library directly.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after `Voicelines.j`. Audio files use the
    `Pots\Sound\Voicelines\Narrator\` directory.

    API:
    Global `VL_NARRATOR_*` constants.

**/
library VoicelinesNarrator initializer Init requires Voicelines

globals
    constant string VL_NARRATOR_FOLDER = "Narrator"

    // Legacy Excel draft/reference rows.

    // Excel draft: NARRATOR | Event: INTRO | Done: x
    constant string VL_NARRATOR_0001_KEY = "Narrator_0001"
    constant string VL_NARRATOR_0001_TEXT = "In the forest of Serenaglade, an outcast shaman wanders alone with his loyal companion Shadowclaw."

    // Excel draft: NARRATOR | Done: X
    constant string VL_NARRATOR_0002_KEY = "Narrator_0002"
    constant string VL_NARRATOR_0002_TEXT = "Nazgrek, once counted among the proud enhancement shamans of his clan, turned his back on his people when they committed the ultimate deed: drinking the blood of Mannoroth, accepting Fel into their hearts and became weapons of the Legion."
    constant string VL_NARRATOR_0003_KEY = "Narrator_0003"
    constant string VL_NARRATOR_0003_TEXT = "Disgusted by the corruption and haunted by the path they had chosen, Nazgrek left behind his kin and the taste of war."
    constant string VL_NARRATOR_0004_KEY = "Narrator_0004"
    constant string VL_NARRATOR_0004_TEXT = "Now, the forest is his sanctuary, a place where he can learn from the spirits and find purpose within the harmony of nature."
    constant string VL_NARRATOR_0005_KEY = "Narrator_0005"
    constant string VL_NARRATOR_0005_TEXT = "But as the sun rises over Serenaglade. He senses something amiss. Today's hunt may hold more than prey, for destiny never lets a shaman stray for long..."

    constant string VL_NARRATOR_0006_KEY = "Narrator_0006"
    constant string VL_NARRATOR_0006_TEXT = "Answering Chieftain Thork's call, Zul'kis of the Darkspear tribe is arriving on the eastern river of Havenwoods to aid the orcish clan."
    constant string VL_NARRATOR_0007_KEY = "Narrator_0007"
    constant string VL_NARRATOR_0007_TEXT = "At his side sails his elder brother, Zul'karak."
endglobals

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence("Narrator_", 1, 50, "Pots\\Sound\\Voicelines\\Narrator\\")
endfunction

endlibrary
