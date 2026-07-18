/**
    VoicelinesVoidEntity

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
    Global `VL_VOIDENTITY_*` constants.

**/
library VoicelinesVoidEntity requires Voicelines

globals
    constant string VL_VOIDENTITY_FOLDER = "VoidEntity"

    // Legacy Excel draft/reference rows.

    // Excel draft: VoidEntity | Event: Encounter / Start | Done: x
    constant string VL_VOIDENTITY_0001_KEY = "VoidEntity_0001"
    constant string VL_VOIDENTITY_0001_TEXT = "It is too late... for me."
    constant string VL_VOIDENTITY_0002_KEY = "VoidEntity_0002"
    constant string VL_VOIDENTITY_0002_TEXT = "You should not have come..."
    constant string VL_VOIDENTITY_0003_KEY = "VoidEntity_0003"
    constant string VL_VOIDENTITY_0003_TEXT = "Help... me...."

    // Excel draft: VoidEntity | Event: Random Combat Lines | Done: x
    constant string VL_VOIDENTITY_0005_KEY = "VoidEntity_0005"
    constant string VL_VOIDENTITY_0005_TEXT = "Your fear... feeding me..."
    constant string VL_VOIDENTITY_0006_KEY = "VoidEntity_0006"
    constant string VL_VOIDENTITY_0006_TEXT = "Relinquish... yourself..."
    constant string VL_VOIDENTITY_0007_KEY = "VoidEntity_0007"
    constant string VL_VOIDENTITY_0007_TEXT = "Every strike... unravels you."
    constant string VL_VOIDENTITY_0008_KEY = "VoidEntity_0008"
    constant string VL_VOIDENTITY_0008_TEXT = "This will... consume you..."
    constant string VL_VOIDENTITY_0009_KEY = "VoidEntity_0009"
    constant string VL_VOIDENTITY_0009_TEXT = "It is futile... to resist..."
    constant string VL_VOIDENTITY_0010_KEY = "VoidEntity_0010"
    constant string VL_VOIDENTITY_0010_TEXT = "There is nowhere... to run."

    // Excel draft: VoidEntity | Event: When Party Unit Dies | Done: x
    constant string VL_VOIDENTITY_0012_KEY = "VoidEntity_0012"
    constant string VL_VOIDENTITY_0012_TEXT = "Welcome... to the other side..."
    constant string VL_VOIDENTITY_0013_KEY = "VoidEntity_0013"
    constant string VL_VOIDENTITY_0013_TEXT = "Feel the void..."
    constant string VL_VOIDENTITY_0014_KEY = "VoidEntity_0014"
    constant string VL_VOIDENTITY_0014_TEXT = "You will see... darkness..."

    // Excel draft: VoidEntity | Event: Casting Regular Ability | Done: x
    constant string VL_VOIDENTITY_0017_KEY = "VoidEntity_0017"
    constant string VL_VOIDENTITY_0017_TEXT = "Unmake."
    constant string VL_VOIDENTITY_0018_KEY = "VoidEntity_0018"
    constant string VL_VOIDENTITY_0018_TEXT = "Despair."
    constant string VL_VOIDENTITY_0019_KEY = "VoidEntity_0019"
    constant string VL_VOIDENTITY_0019_TEXT = "Surrender."
    constant string VL_VOIDENTITY_0020_KEY = "VoidEntity_0020"
    constant string VL_VOIDENTITY_0020_TEXT = "You... will fail..."
    constant string VL_VOIDENTITY_0021_KEY = "VoidEntity_0021"
    constant string VL_VOIDENTITY_0021_TEXT = "Unravel."

    // Excel draft: VoidEntity | Event: Casting Ultimate Ability | Done: x
    constant string VL_VOIDENTITY_0023_KEY = "VoidEntity_0023"
    constant string VL_VOIDENTITY_0023_TEXT = "Your light... fades..."
    constant string VL_VOIDENTITY_0024_KEY = "VoidEntity_0024"
    constant string VL_VOIDENTITY_0024_TEXT = "No light remains."
    constant string VL_VOIDENTITY_0025_KEY = "VoidEntity_0025"
    constant string VL_VOIDENTITY_0025_TEXT = "Your end... begins..."

    // Excel draft: VoidEntity | Event: Low Health / Phase Shift | Done: x
    constant string VL_VOIDENTITY_0028_KEY = "VoidEntity_0028"
    constant string VL_VOIDENTITY_0028_TEXT = "There is only... absorption."
    constant string VL_VOIDENTITY_0029_KEY = "VoidEntity_0029"
    constant string VL_VOIDENTITY_0029_TEXT = "Finish it..."

    // Excel draft: VoidEntity
    constant string VL_VOIDENTITY_0030_KEY = "VoidEntity_0030"
    constant string VL_VOIDENTITY_0030_TEXT = "Soon... it's over..."

    // Excel draft: VoidEntity | Event: Death | Done: x
    constant string VL_VOIDENTITY_0032_KEY = "VoidEntity_0032"
    constant string VL_VOIDENTITY_0032_TEXT = "I see... nothing...?"
    constant string VL_VOIDENTITY_0033_KEY = "VoidEntity_0033"
    constant string VL_VOIDENTITY_0033_TEXT = "At last... I am free..."
endglobals

endlibrary
