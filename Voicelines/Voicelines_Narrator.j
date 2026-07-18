/**
    VoicelinesNarrator

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
    Global `VL_NARRATOR_*` constants.

**/
library VoicelinesNarrator requires Voicelines

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
endglobals

endlibrary
