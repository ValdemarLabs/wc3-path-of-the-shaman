/**
    VoicelinesZulkis

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
    Global `VL_ZULKIS_*` constants.

**/
library VoicelinesZulkis requires Voicelines

globals
    constant string VL_ZULKIS_FOLDER = "Zulkis"

    // Legacy Excel draft/reference rows.

    // Excel draft: Zulkis lines | Event: Meeting with Thork | Done: x
    constant string VL_ZULKIS_0001_KEY = "Zulkis_0001"
    constant string VL_ZULKIS_0001_TEXT = "Hey mon, it be lookin' like we both into shamanism, ya? I reckon we gonna get along jus' fine."
    constant string VL_ZULKIS_0002_KEY = "Zulkis_0002"
    constant string VL_ZULKIS_0002_TEXT = "I be sensin' ya leanin' towards da elementals' fury, mon. My restorative abilities mixed wit' yours gonna make a real nice show out there!"

    // Excel draft: Zulkis lines | Event: Starting with Zulkis | Done: x
    constant string VL_ZULKIS_0003_KEY = "Zulkis_0003"
    constant string VL_ZULKIS_0003_TEXT = "Well, Nazgrek, my man. Where we startin', eh? Psst. I be knowin' Garthork havin' a real bad day, ya know... Maybe we should go meet up wit' Granis first, ya? He might be in good vibes."

    // Excel draft: Zulkis lines
    constant string VL_ZULKIS_0004_KEY = "Zulkis_0004"
    constant string VL_ZULKIS_0004_TEXT = "I be hearin' dat them murlocs, dey be puttin' their victims in da water for weeks, limitin' their breath supply. Keep 'em alive, ya know. And when dem victims be all soaked and ready, dat's when dem murlocs feast, eatin' 'em alive. A gruesome business, mon."

    // Excel draft: Zulkis lines | Quest: Magical Eye | Event: Random discussion | Done: x
    constant string VL_ZULKIS_0044_KEY = "Zulkis_0044"
    constant string VL_ZULKIS_0044_TEXT = "\"I be hearin' dat them murlocs, dey be puttin' their victims in da water for weeks, limitin' their breath supply. Keep 'em alive, ya know. And when dem victims be all soaked and ready, dat's when dem murlocs feast, eatin' 'em alive. A gruesome business, mon."
endglobals

endlibrary
