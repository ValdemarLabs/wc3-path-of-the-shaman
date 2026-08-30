/**
    VoicelinesZulkis

    Author: Valdemar
    Version: 1.1.3

    Description:
    Speaker-owned story and reusable generic quest voicelines for Zul'kis.
    This library owns their text, keys, sound registration, and generic
    quest reply variants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after `Voicelines.j` and `QuestsGeneric.j`. Consumers require this
    library directly.

    API:
    Global `VL_ZULKIS_*` and `VL_ZULKIS_GENERIC_####_*` constants.

**/
library VoicelinesZulkis initializer Init requires Voicelines, QuestsGeneric

globals
    constant string VL_ZULKIS_FOLDER = "Zulkis"
    constant string VL_ZULKIS_GENERIC_FOLDER = "ZulkisGeneric"
    constant string VL_ZULKIS_GENERIC_TYPE = "ZulkisGeneric_"

    // Reusable generic quest replies: accept.
    constant string VL_ZULKIS_GENERIC_0001_KEY = "ZulkisGeneric_0001"
    constant string VL_ZULKIS_GENERIC_0001_TEXT = "I be seein' it done, mon."
    constant string VL_ZULKIS_GENERIC_0002_KEY = "ZulkisGeneric_0002"
    constant string VL_ZULKIS_GENERIC_0002_TEXT = "Understood. I be handlin' it."
    constant string VL_ZULKIS_GENERIC_0003_KEY = "ZulkisGeneric_0003"
    constant string VL_ZULKIS_GENERIC_0003_TEXT = "Da spirits showed me where to begin."
    constant string VL_ZULKIS_GENERIC_0004_KEY = "ZulkisGeneric_0004"
    constant string VL_ZULKIS_GENERIC_0004_TEXT = "Point da way, mon. I take care of da rest."

    // Reusable generic quest replies: kill completion.
    constant string VL_ZULKIS_GENERIC_0005_KEY = "ZulkisGeneric_0005"
    constant string VL_ZULKIS_GENERIC_0005_TEXT = "Da threat be dealt with."
    constant string VL_ZULKIS_GENERIC_0006_KEY = "ZulkisGeneric_0006"
    constant string VL_ZULKIS_GENERIC_0006_TEXT = "Da road be safe again, mon."
    constant string VL_ZULKIS_GENERIC_0007_KEY = "ZulkisGeneric_0007"
    constant string VL_ZULKIS_GENERIC_0007_TEXT = "Dem enemies not be troublin' us again."
    constant string VL_ZULKIS_GENERIC_0008_KEY = "ZulkisGeneric_0008"
    constant string VL_ZULKIS_GENERIC_0008_TEXT = "Da spirits be calm now. It be done."

    // Reusable generic quest replies: talk completion.
    constant string VL_ZULKIS_GENERIC_0009_KEY = "ZulkisGeneric_0009"
    constant string VL_ZULKIS_GENERIC_0009_TEXT = "I spoke wit' da one ya named."
    constant string VL_ZULKIS_GENERIC_0010_KEY = "ZulkisGeneric_0010"
    constant string VL_ZULKIS_GENERIC_0010_TEXT = "Ya message reached where it needed to go."
    constant string VL_ZULKIS_GENERIC_0011_KEY = "ZulkisGeneric_0011"
    constant string VL_ZULKIS_GENERIC_0011_TEXT = "Dey heard ya words and gave me an answer."
    constant string VL_ZULKIS_GENERIC_0012_KEY = "ZulkisGeneric_0012"
    constant string VL_ZULKIS_GENERIC_0012_TEXT = "Da talk be finished, mon."

    // Reusable generic quest replies: fetch completion.
    constant string VL_ZULKIS_GENERIC_0013_KEY = "ZulkisGeneric_0013"
    constant string VL_ZULKIS_GENERIC_0013_TEXT = "I brought what ya asked for."
    constant string VL_ZULKIS_GENERIC_0014_KEY = "ZulkisGeneric_0014"
    constant string VL_ZULKIS_GENERIC_0014_TEXT = "Da delivery be complete."
    constant string VL_ZULKIS_GENERIC_0015_KEY = "ZulkisGeneric_0015"
    constant string VL_ZULKIS_GENERIC_0015_TEXT = "Everythin' ya requested be right here."
    constant string VL_ZULKIS_GENERIC_0016_KEY = "ZulkisGeneric_0016"
    constant string VL_ZULKIS_GENERIC_0016_TEXT = "I gathered da whole lot, mon."

    // Reusable generic quest replies: progress.
    constant string VL_ZULKIS_GENERIC_0017_KEY = "ZulkisGeneric_0017"
    constant string VL_ZULKIS_GENERIC_0017_TEXT = "What still be needin' done?"
    constant string VL_ZULKIS_GENERIC_0018_KEY = "ZulkisGeneric_0018"
    constant string VL_ZULKIS_GENERIC_0018_TEXT = "I ain't forgotten da task, mon."
    constant string VL_ZULKIS_GENERIC_0019_KEY = "ZulkisGeneric_0019"
    constant string VL_ZULKIS_GENERIC_0019_TEXT = "Show me where I still be needed."
    constant string VL_ZULKIS_GENERIC_0020_KEY = "ZulkisGeneric_0020"
    constant string VL_ZULKIS_GENERIC_0020_TEXT = "Tell me what still be unfinished."

    // Reusable generic quest replies: supply handoff.
    constant string VL_ZULKIS_GENERIC_0021_KEY = "ZulkisGeneric_0021"
    constant string VL_ZULKIS_GENERIC_0021_TEXT = "I was sent for da supplies ya be holdin'."
    constant string VL_ZULKIS_GENERIC_0022_KEY = "ZulkisGeneric_0022"
    constant string VL_ZULKIS_GENERIC_0022_TEXT = "I be here for da parcel left in ya care."
    constant string VL_ZULKIS_GENERIC_0023_KEY = "ZulkisGeneric_0023"
    constant string VL_ZULKIS_GENERIC_0023_TEXT = "Ya got supplies meant for my quest, mon."
    constant string VL_ZULKIS_GENERIC_0024_KEY = "ZulkisGeneric_0024"
    constant string VL_ZULKIS_GENERIC_0024_TEXT = "Pass me da supplies. I see dem delivered."

    // Reusable generic quest replies: quest purchase.
    constant string VL_ZULKIS_GENERIC_0025_KEY = "ZulkisGeneric_0025"
    constant string VL_ZULKIS_GENERIC_0025_TEXT = "I be told ya carry da item needed for dis commission."
    constant string VL_ZULKIS_GENERIC_0026_KEY = "ZulkisGeneric_0026"
    constant string VL_ZULKIS_GENERIC_0026_TEXT = "Show me da goods set aside for dis task."
    constant string VL_ZULKIS_GENERIC_0027_KEY = "ZulkisGeneric_0027"
    constant string VL_ZULKIS_GENERIC_0027_TEXT = "Dis commission needs somethin' from ya stock."
    constant string VL_ZULKIS_GENERIC_0028_KEY = "ZulkisGeneric_0028"
    constant string VL_ZULKIS_GENERIC_0028_TEXT = "I be here to buy what da quest requires."

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

    // Darkspear landing and rescue prologue.
    constant string VL_ZULKIS_0005_KEY = "Zulkis_0005"
    constant string VL_ZULKIS_0005_TEXT = "Don't worry, Zul'karak. Da orc chieftain promised this meetin' be quick."
    constant string VL_ZULKIS_0006_KEY = "Zulkis_0006"
    constant string VL_ZULKIS_0006_TEXT = "Da rest of my tribe be waitin' at da river with my brother, Zul'karak."
    constant string VL_ZULKIS_0007_KEY = "Zulkis_0007"
    constant string VL_ZULKIS_0007_TEXT = "Save ya strength, brother. We be gettin' out of here."
    constant string VL_ZULKIS_0008_KEY = "Zulkis_0008"
    constant string VL_ZULKIS_0008_TEXT = "Come. Da Horde camp be safer than these woods."
    constant string VL_ZULKIS_0009_KEY = "Zulkis_0009"
    constant string VL_ZULKIS_0009_TEXT = "Forest trolls took my brother. I be findin' him before dey finish what dey started."
    constant string VL_ZULKIS_0010_KEY = "Zulkis_0010"
    constant string VL_ZULKIS_0010_TEXT = "No... Spirits, no. My people..."
    constant string VL_ZULKIS_0011_KEY = "Zulkis_0011"
    constant string VL_ZULKIS_0011_TEXT = "Zul'karak! Brother, where are ya?"
    constant string VL_ZULKIS_0012_KEY = "Zulkis_0012"
    constant string VL_ZULKIS_0012_TEXT = "What happened here? Where be my brother? Tell me!"
    constant string VL_ZULKIS_0013_KEY = "Zulkis_0013"
    constant string VL_ZULKIS_0013_TEXT = "Zul'karak! Spirits preserve ya... Can ya stand?"
    constant string VL_ZULKIS_0014_KEY = "Zulkis_0014"
    constant string VL_ZULKIS_0014_TEXT = "Hail, Chieftain Thork. I be Zul'kis of da Darkspear."

    // Excel draft: Zulkis lines | Quest: Magical Eye | Event: Random discussion | Done: x
    constant string VL_ZULKIS_0044_KEY = "Zulkis_0044"
    constant string VL_ZULKIS_0044_TEXT = "\"I be hearin' dat them murlocs, dey be puttin' their victims in da water for weeks, limitin' their breath supply. Keep 'em alive, ya know. And when dem victims be all soaked and ready, dat's when dem murlocs feast, eatin' 'em alive. A gruesome business, mon."
endglobals

private function RegisterGenericQuestLines takes nothing returns nothing
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0001_TEXT, 1)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0002_TEXT, 2)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0003_TEXT, 3)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0004_TEXT, 4)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0005_TEXT, 5)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0006_TEXT, 6)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0007_TEXT, 7)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0008_TEXT, 8)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0009_TEXT, 9)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0010_TEXT, 10)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0011_TEXT, 11)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0012_TEXT, 12)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0013_TEXT, 13)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0014_TEXT, 14)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0015_TEXT, 15)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0016_TEXT, 16)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0017_TEXT, 17)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0018_TEXT, 18)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0019_TEXT, 19)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0020_TEXT, 20)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0021_TEXT, 21)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0022_TEXT, 22)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0023_TEXT, 23)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0024_TEXT, 24)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0025_TEXT, 25)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0026_TEXT, 26)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0027_TEXT, 27)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_ZULKIS_GENERIC_TYPE, VL_ZULKIS_GENERIC_0028_TEXT, 28)
endfunction

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence(VL_ZULKIS_GENERIC_TYPE, 1, 28, "Pots\\Sound\\Voicelines\\Zulkis\\ZulkisGeneric\\")
    call RegisterGenericQuestLines()
endfunction

endlibrary
