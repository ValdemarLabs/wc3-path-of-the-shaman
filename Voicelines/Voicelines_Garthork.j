/**
    VoicelinesGarthork

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
    Global `VL_GARTHORK_*` constants.

**/
library VoicelinesGarthork requires Voicelines

globals
    constant string VL_GARTHORK_FOLDER = "Garthork"

    // Legacy Excel draft/reference rows.

    // Excel draft: Garthork lines | Event: Garthork / First Greet | Done: x
    constant string VL_GARTHORK_0001_KEY = "Garthork_0001"
    constant string VL_GARTHORK_0001_TEXT = "Greetings, fellow shaman. I am Garthork."
    constant string VL_GARTHORK_0002_KEY = "Garthork_0002"
    constant string VL_GARTHORK_0002_TEXT = "Greetings, fellow shaman. The spirits are telling me you are the one who Hellscream spoke about. I am Garthork, survivor of the Second War and keeper of the old ways."
    constant string VL_GARTHORK_0003_KEY = "Garthork_0003"
    constant string VL_GARTHORK_0003_TEXT = "I once stood by Ner'zhul's side as an apprentice in the Shadowmoon Clan. When the Dark Portal beckoned, our paths diverged. I ventured through its ominous gateway, while Ner'zhul remained behind on Draenor. I never knew what happened to my master after the portal closed..."
    constant string VL_GARTHORK_0004_KEY = "Garthork_0004"
    constant string VL_GARTHORK_0004_TEXT = "You Nazgrek, were a member of the once mighty Thunderlord Clan, am I right?"
    constant string VL_GARTHORK_0005_KEY = "Garthork_0005"
    constant string VL_GARTHORK_0005_TEXT = "You and I show the rest of the Horde as shamans and spiritual guiders that even the mightiest trees weather storms. In times of trial, call upon the spirits, and let the elements be your allies. The strength of an orc lies not just in the swing of a weapon, but in the harmony with nature."

    // Excel draft: Garthork lines | Event: Garthork / Normal Greet | Done: x
    constant string VL_GARTHORK_0006_KEY = "Garthork_0006"
    constant string VL_GARTHORK_0006_TEXT = "Greetings, fellow shaman."

    // Excel draft: Garthork lines | Event: Garthork / Farewell | Done: x
    constant string VL_GARTHORK_0007_KEY = "Garthork_0007"
    constant string VL_GARTHORK_0007_TEXT = "May the ancestors watch over you from the thunderous sky!"

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / intro | Done: x
    constant string VL_GARTHORK_0010_KEY = "Garthork_0010"
    constant string VL_GARTHORK_0010_TEXT = "I sense a great potential in the murlocs dwelling here - untapped, dormant magic."
    constant string VL_GARTHORK_0011_KEY = "Garthork_0011"
    constant string VL_GARTHORK_0011_TEXT = "The murlocs don't embrace the magic they are naturally gifted with. It could be due to their low intelligence or the lack of it. We could harness this power for the benefit of the Horde."

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / acceptdecline | Done: x
    constant string VL_GARTHORK_0012_KEY = "Garthork_0012"
    constant string VL_GARTHORK_0012_TEXT = "The magical power lies within their eyes. Not just any murloc will do, as their levels of power differ from another. You have to venture out deep into the murloc swamp where you will discover murloc called Mur'gal. This murloc is more powerful than the ordinary murlocs you will encounter on the river banks. Kill the Mur'gal and take his eye out. This eye is source of the magic and the power. Bring the eye to me and we shall study it to harness it's power."

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / accept | Done: x
    constant string VL_GARTHORK_0013_KEY = "Garthork_0013"
    constant string VL_GARTHORK_0013_TEXT = "You'll find the Mur'gal to the south of here. Be careful not to damage the eye."

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / decline | Done: x
    constant string VL_GARTHORK_0014_KEY = "Garthork_0014"
    constant string VL_GARTHORK_0014_TEXT = "Your choice is respected, but know that the Horde could benefit greatly from the murlocs' hidden magic. The offer remains should you change your mind."

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / unfinished | Done: x
    constant string VL_GARTHORK_0015_KEY = "Garthork_0015"
    constant string VL_GARTHORK_0015_TEXT = "The magic within the Mur'gal's eye beckons. Do not tarry; the Horde's future strength depends on your success."

    // Excel draft: Garthork lines | Event: Garthork / Magical Eye / completed | Done: x
    constant string VL_GARTHORK_0016_KEY = "Garthork_0016"
    constant string VL_GARTHORK_0016_TEXT = "You have returned victorious! And the eye is still intact. It pulsates with raw magic, I can sense it like a heartbeat. The Horde shall benefit greatly from your bravery."
    constant string VL_GARTHORK_0017_KEY = "Garthork_0017"
    constant string VL_GARTHORK_0017_TEXT = "Here is a reward for the effort you made."
endglobals

endlibrary
