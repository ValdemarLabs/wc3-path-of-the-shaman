/**
    VoicelinesOrcPeon

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
    Global `VL_ORCPEON_*` constants.

**/
library VoicelinesOrcPeon requires Voicelines

globals
    constant string VL_ORCPEON_FOLDER = "Orc Peon"

    // Legacy Excel draft/reference rows.

    // Excel draft: Peon_lines | Excel file: Peon_0001 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0001_KEY = "OrcPeon_0001"
    constant string VL_ORCPEON_0001_TEXT = "Me need help, me can't find good trees for choppin!"

    // Excel draft: Peon_lines | Excel file: Peon_0002 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0002_KEY = "OrcPeon_0002"
    constant string VL_ORCPEON_0002_TEXT = "Trees, trees everywhere! Which one be good for choppin?"

    // Excel draft: Peon_lines | Excel file: Peon_0003 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0003_KEY = "OrcPeon_0003"
    constant string VL_ORCPEON_0003_TEXT = "Me axe be ready, but me eyes be failin'. Help me find da choicest trees!"

    // Excel draft: Peon_lines | Excel file: Peon_0004 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0004_KEY = "OrcPeon_0004"
    constant string VL_ORCPEON_0004_TEXT = "Me no see good, need someone sharp-eyed to guide me to de good trees."

    // Excel draft: Peon_lines | Excel file: Peon_0005 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0005_KEY = "OrcPeon_0005"
    constant string VL_ORCPEON_0005_TEXT = "Help a lumber orc out! Me need sharp eyes to spot da prime lumber!\""

    // Excel draft: Peon_lines | Excel file: Peon_0006 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0006_KEY = "OrcPeon_0006"
    constant string VL_ORCPEON_0006_TEXT = "Stickin' by ya, boss! Can't see much on me own."

    // Excel draft: Peon_lines | Excel file: Peon_0007 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0007_KEY = "OrcPeon_0007"
    constant string VL_ORCPEON_0007_TEXT = "Me right here! Ready to chop where ya say."

    // Excel draft: Peon_lines | Excel file: Peon_0008 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0008_KEY = "OrcPeon_0008"
    constant string VL_ORCPEON_0008_TEXT = "Watchin' where ya go! Me don't want to miss da good trees."

    // Excel draft: Peon_lines | Excel file: Peon_0009 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0009_KEY = "OrcPeon_0009"
    constant string VL_ORCPEON_0009_TEXT = "Choppin' away! Hope dis tree be good for lumber."

    // Excel draft: Peon_lines | Excel file: Peon_0010 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0010_KEY = "OrcPeon_0010"
    constant string VL_ORCPEON_0010_TEXT = "Feel da power of me swing! Chop, chop! Chop, chop!"

    // Excel draft: Peon_lines | Excel file: Peon_0011 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0011_KEY = "OrcPeon_0011"
    constant string VL_ORCPEON_0011_TEXT = "Hmm, dis lumber feel sturdy! Good chop, boss!"

    // Excel draft: Peon_lines | Excel file: Peon_0012 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0012_KEY = "OrcPeon_0012"
    constant string VL_ORCPEON_0012_TEXT = "Uh-oh, boss... bad wood."

    // Excel draft: Peon_lines | Excel file: Peon_0013 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0013_KEY = "OrcPeon_0013"
    constant string VL_ORCPEON_0013_TEXT = "Wood no good wood, boss. Sorry."

    // Excel draft: Peon_lines | Excel file: Peon_0014 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0014_KEY = "OrcPeon_0014"
    constant string VL_ORCPEON_0014_TEXT = "Eh... Uhhum... Wood no good, wood bad."

    // Excel draft: Peon_lines | Excel file: Peon_0015 | Quest: Bad vision lumber peon wood harvest | Done: X
    constant string VL_ORCPEON_0015_KEY = "OrcPeon_0015"
    constant string VL_ORCPEON_0015_TEXT = "Quest complete, boss! Me feelin' like da strong orc in da Horde!"

    // Excel draft: Peon_lines | Excel file: Peon_0016 | Quest: Bad vision lumber peon wood harvest | Event: First? | Done: X
    constant string VL_ORCPEON_0016_KEY = "OrcPeon_0016"
    constant string VL_ORCPEON_0016_TEXT = "Hello! Me can chop trees, but me no see good anymore."

    // Excel draft: Peon_lines | Excel file: Peon_0017
    constant string VL_ORCPEON_0017_KEY = "OrcPeon_0017"
    constant string VL_ORCPEON_0017_TEXT = "Me feel when da wood good. You help me go to woods and me chopety chop chop."

    // Excel draft: Peon_lines | Excel file: Peon_0020 | Event: Normal greet
    constant string VL_ORCPEON_0020_KEY = "OrcPeon_0020"
    constant string VL_ORCPEON_0020_TEXT = "Yes? What is it?"

    // Excel draft: Peon_lines | Excel file: Peon_0021 | Event: Normal farewell
    constant string VL_ORCPEON_0021_KEY = "OrcPeon_0021"
    constant string VL_ORCPEON_0021_TEXT = "Okay... Bye!"

    // Excel draft: Peon_lines | Excel file: Peon_0022 | Event: Bear tooth
    constant string VL_ORCPEON_0022_KEY = "OrcPeon_0022"
    constant string VL_ORCPEON_0022_TEXT = "Me want tooth of a big bear, but me can't kill beast of that size!"

    // Excel draft: Peon_lines | Excel file: Peon_0023 | Event: Bear tooth
    constant string VL_ORCPEON_0023_KEY = "OrcPeon_0023"
    constant string VL_ORCPEON_0023_TEXT = "Can you fetch me a bear tooth? I give reward!"

    // Excel draft: Peon_lines | Excel file: Peon_0024 | Event: Bear tooth
    constant string VL_ORCPEON_0024_KEY = "OrcPeon_0024"
    constant string VL_ORCPEON_0024_TEXT = "Kill a bear and remove its tooth. Preferably a mother bear or ferocious bear."

    // Excel draft: Peon_lines | Excel file: Peon_0025 | Event: Bear tooth
    constant string VL_ORCPEON_0025_KEY = "OrcPeon_0025"
    constant string VL_ORCPEON_0025_TEXT = "Oooh nice! You still alive and well! Thanks for the tooth!"
endglobals

endlibrary
