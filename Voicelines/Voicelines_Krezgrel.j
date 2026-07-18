/**
    VoicelinesKrezgrel

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
    Global `VL_KREZGREL_*` constants.

**/
library VoicelinesKrezgrel requires Voicelines

globals
    constant string VL_KREZGREL_FOLDER = "Krezgrel"

    // Legacy Excel draft/reference rows.

    // Excel draft: Krezgrel Lines | Event: Krezgrel / First Greet
    constant string VL_KREZGREL_0001_KEY = "Krezgrel_0001"
    constant string VL_KREZGREL_0001_TEXT = "Greetings, warrior! I am Krezgrel, commander of our fearsome orc grunts."
    constant string VL_KREZGREL_0002_KEY = "Krezgrel_0002"
    constant string VL_KREZGREL_0002_TEXT = "Looking for a taste of battle or perhaps just seeking some hearty conversation before you march into the fray? Either way, you've stumbled upon the right orc."

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Normal Greet
    constant string VL_KREZGREL_0006_KEY = "Krezgrel_0006"
    constant string VL_KREZGREL_0006_TEXT = "I see you approach with a face as serious as a dwarf in a library. What is it?"

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Normal Farewell
    constant string VL_KREZGREL_0007_KEY = "Krezgrel_0007"
    constant string VL_KREZGREL_0007_TEXT = "Well, it seems our time together has come to an end, at least for now."

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Rescue The Grunts / intro
    constant string VL_KREZGREL_0010_KEY = "Krezgrel_0010"
    constant string VL_KREZGREL_0010_TEXT = "I had some bad news... Murlocs have taken our grunts as their prisoners."
    constant string VL_KREZGREL_0011_KEY = "Krezgrel_0011"
    constant string VL_KREZGREL_0011_TEXT = "Rescue the grunts from the murloc waters to the south of here."

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Rescue The Grunts / acceptdecline
    constant string VL_KREZGREL_0012_KEY = "Krezgrel_0012"
    constant string VL_KREZGREL_0012_TEXT = "Hurry before they are drown or eaten! I heard that they keep them upside down in the water."

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Rescue The Grunts / accept
    constant string VL_KREZGREL_0013_KEY = "Krezgrel_0013"
    constant string VL_KREZGREL_0013_TEXT = "You've rescued our grunts from the murlocs! Sadly, not all survived..."
    constant string VL_KREZGREL_0014_KEY = "Krezgrel_0014"
    constant string VL_KREZGREL_0014_TEXT = "The warriors who you rescued are forever in your debt!"

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Murloc fins / intro
    constant string VL_KREZGREL_0020_KEY = "Krezgrel_0020"
    constant string VL_KREZGREL_0020_TEXT = "Our food offerings for the warriors are becoming duller. I guess the boar meat just gets repetitive."
    constant string VL_KREZGREL_0021_KEY = "Krezgrel_0021"
    constant string VL_KREZGREL_0021_TEXT = "So, I have an idea. Let's use murloc fins to create tasty soup. I'm sure that will taste different."

    // Excel draft: Krezgrel Lines | Event: Krezgrel / Murloc fins/ acceptdecline
    constant string VL_KREZGREL_0022_KEY = "Krezgrel_0022"
    constant string VL_KREZGREL_0022_TEXT = "Eh, at least it smells different than boar meat? Nice work!"
endglobals

endlibrary
