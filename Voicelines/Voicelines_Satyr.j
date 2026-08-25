/**
    VoicelinesSatyr

    Author: Valdemar
    Version:

    Description:
    Speaker-owned voiceline key/text constants and sound registration
    migrated from legacy Excel draft/reference rows. Runtime consumers
    require this library directly when they need these constants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx

    How to install:
    Import after `Voicelines.j`.

    API:
    Global `VL_SATYR_*` constants.

**/
library VoicelinesSatyr initializer Init requires Voicelines

globals
    constant string VL_SATYR_FOLDER = "Satyr"

    // Legacy Excel draft/reference rows.

    // Excel draft: Satyr_Demoness Lines | Event: First meet / Zaekolaerr | Done: x
    constant string VL_SATYR_0001_KEY = "Satyr_0001"
    constant string VL_SATYR_0001_TEXT = "Ah, mortal orc. You have come seeking an audience with the Prince Zaekolaerr of the Sereneglade. Speak your purpose, but tread lightly, for my patience wears thin like the morning mist."
    constant string VL_SATYR_0002_KEY = "Satyr_0002"
    constant string VL_SATYR_0002_TEXT = "Hmmm... what have we here? Ahaa! An orc, straying into our domain? Speak, creature, and make it quick. I have little patience for your kind."
    constant string VL_SATYR_0003_KEY = "Satyr_0003"
    constant string VL_SATYR_0003_TEXT = "What manner of orcish filth dares to trespass in my domain?! Speak quickly, orc, and explain your presence before I decide to rid the forest of your disgusting stench."
    constant string VL_SATYR_0004_KEY = "Satyr_0004"
    constant string VL_SATYR_0004_TEXT = "Your words may spare you for now, orc shaman. But remember this: tread lightly in my domain, or face the consequences!"

    // Excel draft: Satyr_Demoness Lines | Event: Greet / Zaekolaerr | Done: x
    constant string VL_SATYR_0013_KEY = "Satyr_0013"
    constant string VL_SATYR_0013_TEXT = "Oh, it's you again. What do you want now? Speak quickly, and do not waste my time with your petty concerns."
    constant string VL_SATYR_0014_KEY = "Satyr_0014"
    constant string VL_SATYR_0014_TEXT = "Look who decided to grace us with their presence. What do you want this time? Spit it out before I lose what little patience I have left."
    constant string VL_SATYR_0015_KEY = "Satyr_0015"
    constant string VL_SATYR_0015_TEXT = "Oh, it's you... What misfortune brings you here today? Don't make me regret allowing you to speak."
    constant string VL_SATYR_0016_KEY = "Satyr_0016"
    constant string VL_SATYR_0016_TEXT = "Hmph... you again. What bothersome task do you have for me now? Make it quick, I have better things to do than entertain the likes of you."
    constant string VL_SATYR_0017_KEY = "Satyr_0017"
    constant string VL_SATYR_0017_TEXT = "You dare to stand before me once more? What insolence. Speak your business and be gone, lest you wish to feel the sting of my wrath."

    // Excel draft: Satyr_Demoness Lines | Event: Farewell / Zaekolaerr | Done: x
    constant string VL_SATYR_0020_KEY = "Satyr_0020"
    constant string VL_SATYR_0020_TEXT = "Leave, and do not return until you have something of value to offer. And be grateful I haven't turned you into toadstools for wasting my time."
    constant string VL_SATYR_0021_KEY = "Satyr_0021"
    constant string VL_SATYR_0021_TEXT = "Fine, go then. But don't expect a warm welcome next time you darken my doorstep. Off with you, before I decide to make you regret ever setting foot in my domain."
    constant string VL_SATYR_0022_KEY = "Satyr_0022"
    constant string VL_SATYR_0022_TEXT = "Get out of my sight before I decide to make an example out of you. And don't bother coming back unless you plan to actually accomplish something useful."
    constant string VL_SATYR_0023_KEY = "Satyr_0023"
    constant string VL_SATYR_0023_TEXT = "Leave, and take your incompetence with you. I have no time for fools who can't even complete a simple task. Off you go, before I lose my temper."
    constant string VL_SATYR_0024_KEY = "Satyr_0024"
    constant string VL_SATYR_0024_TEXT = "Begone from my presence, and take your pitiful excuses with you. If you ever return, you'd better come bearing something of actual value, or else suffer the consequences."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Intro | Done: x
    constant string VL_SATYR_0026_KEY = "Satyr_0026"
    constant string VL_SATYR_0026_TEXT = "So, an orc dares to come crawling into my domain seeking peace? Pathetic."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Intro
    constant string VL_SATYR_0027_KEY = "Satyr_0027"
    constant string VL_SATYR_0027_TEXT = "So, you come crawling to Zaekolaerr seeking peace? Ha! Peace is for the weak!"

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Intro | Done: x
    constant string VL_SATYR_0028_KEY = "Satyr_0028"
    constant string VL_SATYR_0028_TEXT = "And what would you know of our ways, little orc? Your kind has always thrived on conflict."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: dialog choices appear | Done: x
    constant string VL_SATYR_0029_KEY = "Satyr_0029"
    constant string VL_SATYR_0029_TEXT = "Coexist? With your kind? Haha haha! You're delusional, but funny. Fine, speak your piece. I'll humor you."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Dialog: Negoations - arena | Done: x
    constant string VL_SATYR_0031_KEY = "Satyr_0031"
    constant string VL_SATYR_0031_TEXT = "Negotiations? Ha! We shall see if you are truly committed to peace. Prove your worth in the arena of Coliseum of Ages, and perhaps then we shall consider your proposal."
    constant string VL_SATYR_0032_KEY = "Satyr_0032"
    constant string VL_SATYR_0032_TEXT = "We shall see if you are truly committed to peace. Prove your worth in the arena of Coliseum of Ages, and perhaps then we shall consider your proposal."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Dialog: Betray orcs | Done: x
    constant string VL_SATYR_0036_KEY = "Satyr_0036"
    constant string VL_SATYR_0036_TEXT = "Befriend us? By turning against your own kind? Interesting proposition. Perhaps there is hope for you yet, orc."
    constant string VL_SATYR_0037_KEY = "Satyr_0037"
    constant string VL_SATYR_0037_TEXT = "Turning against your own kind, are you? Pathetic. But perhaps it's the only chance you have."

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Dialog: Angering satyr | Done: x
    constant string VL_SATYR_0043_KEY = "Satyr_0043"
    constant string VL_SATYR_0043_TEXT = "What foolishness is this?! You seek peace by provoking the very beings you wish to appease?"
    constant string VL_SATYR_0044_KEY = "Satyr_0044"
    constant string VL_SATYR_0044_TEXT = "Now prepare for the consequences... Kill the orc!"

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Intro | Done: x
    constant string VL_SATYR_0047_KEY = "Satyr_0047"
    constant string VL_SATYR_0047_TEXT = "Silence! Let's hear what the orc has to say."
endglobals

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0001_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0002_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0003_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0004_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0013_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0014_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0015_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0016_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0017_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0020_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0021_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0022_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0023_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0024_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0026_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0027_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0028_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0029_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0031_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0032_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0036_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0037_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0043_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0044_KEY)
    call Voicelines_RegisterKey(VL_SATYR_FOLDER, VL_SATYR_0047_KEY)
endfunction

endlibrary
