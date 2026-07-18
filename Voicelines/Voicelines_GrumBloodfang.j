/**
    VoicelinesGrumBloodfang

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
    Global `VL_GRUMBLOODFANG_*` constants.

**/
library VoicelinesGrumBloodfang requires Voicelines

globals
    constant string VL_GRUMBLOODFANG_FOLDER = "GrumBloodfang"

    // Legacy Excel draft/reference rows.

    // Excel draft: GrumBloodfang Lines | Event: First time greet | Done: x
    constant string VL_GRUMBLOODFANG_0001_KEY = "GrumBloodfang_0001"
    constant string VL_GRUMBLOODFANG_0001_TEXT = "Be quiet you fool! We're trying to hunt dragons here!"
    constant string VL_GRUMBLOODFANG_0002_KEY = "GrumBloodfang_0002"
    constant string VL_GRUMBLOODFANG_0002_TEXT = "Their ears are sharper than any blade, and if they hear us, we're ash before you can even draw steel."
    constant string VL_GRUMBLOODFANG_0003_KEY = "GrumBloodfang_0003"
    constant string VL_GRUMBLOODFANG_0003_TEXT = "If you wish to prove your worth, there's work to be done - dangerous work."

    // Excel draft: GrumBloodfang Lines | Event: Goodbye | Done: x
    constant string VL_GRUMBLOODFANG_0004_KEY = "GrumBloodfang_0004"
    constant string VL_GRUMBLOODFANG_0004_TEXT = "Slay them all, warrior."
    constant string VL_GRUMBLOODFANG_0005_KEY = "GrumBloodfang_0005"
    constant string VL_GRUMBLOODFANG_0005_TEXT = "For the Horde."

    // Excel draft: GrumBloodfang Lines | Event: Normal Greet | Done: x
    constant string VL_GRUMBLOODFANG_0006_KEY = "GrumBloodfang_0006"
    constant string VL_GRUMBLOODFANG_0006_TEXT = "The Emperpeak Highland's skies grow darker each day..."
    constant string VL_GRUMBLOODFANG_0007_KEY = "GrumBloodfang_0007"
    constant string VL_GRUMBLOODFANG_0007_TEXT = "Still standing here? Then you're wasting both our time. Go make yourself useful."
    constant string VL_GRUMBLOODFANG_0008_KEY = "GrumBloodfang_0008"
    constant string VL_GRUMBLOODFANG_0008_TEXT = "The air smells of ash... dragons are never far."
    constant string VL_GRUMBLOODFANG_0009_KEY = "GrumBloodfang_0009"
    constant string VL_GRUMBLOODFANG_0009_TEXT = "You stand before Grum Bloodfang. Speak your purpose, or be gone."

    // Excel draft: GrumBloodfang Lines | Quest: Whelps of Destruction | Event: Intro | Done: x
    constant string VL_GRUMBLOODFANG_0020_KEY = "GrumBloodfang_0020"
    constant string VL_GRUMBLOODFANG_0020_TEXT = "You look like you have some fight in you, but do you have the courage to face a dragon's brood?"
    constant string VL_GRUMBLOODFANG_0021_KEY = "GrumBloodfang_0021"
    constant string VL_GRUMBLOODFANG_0021_TEXT = "The Emperpeak Highland has started to crawl with dragon whelps. They may be small now, but if we don't cull their numbers, they'll grow into full-fledged dragons and breathe fire upon us all!"
    constant string VL_GRUMBLOODFANG_0022_KEY = "GrumBloodfang_0022"
    constant string VL_GRUMBLOODFANG_0022_TEXT = "I need a warrior with the guts to take them down before they become a real threat."
    constant string VL_GRUMBLOODFANG_0023_KEY = "GrumBloodfang_0023"
    constant string VL_GRUMBLOODFANG_0023_TEXT = "The Emberpeak Highlands lies just ahead. Slay the whelps and bring back their scales as proof. Show no mercy!"

    // Excel draft: GrumBloodfang Lines | Quest: Whelps of Destruction | Event: Unfinished | Done: x
    constant string VL_GRUMBLOODFANG_0024_KEY = "GrumBloodfang_0024"
    constant string VL_GRUMBLOODFANG_0024_TEXT = "Fear of burning alive holding you back? Then perhaps you'd better gather herbs instead."
    constant string VL_GRUMBLOODFANG_0025_KEY = "GrumBloodfang_0025"
    constant string VL_GRUMBLOODFANG_0025_TEXT = "Still here? I thought you'd be slaying whelps by now. Get to it, before they grow stronger."

    // Excel draft: GrumBloodfang Lines | Quest: Whelps of Destruction | Event: Completion | Done: x
    constant string VL_GRUMBLOODFANG_0026_KEY = "GrumBloodfang_0026"
    constant string VL_GRUMBLOODFANG_0026_TEXT = "Hah! You return victorius. You've proven your strength. The Horde needs more warriors like you."
    constant string VL_GRUMBLOODFANG_0027_KEY = "GrumBloodfang_0027"
    constant string VL_GRUMBLOODFANG_0027_TEXT = "But this is just the beginning of our hunt..."

    // Excel draft: GrumBloodfang Lines | Quest: Dragon Egg Hunt | Event: Intro | Done: x
    constant string VL_GRUMBLOODFANG_0031_KEY = "GrumBloodfang_0031"
    constant string VL_GRUMBLOODFANG_0031_TEXT = "My hunters have spotted many dragon eggs around the highlands."
    constant string VL_GRUMBLOODFANG_0032_KEY = "GrumBloodfang_0032"
    constant string VL_GRUMBLOODFANG_0032_TEXT = "They must be taken, before they hatch."
    constant string VL_GRUMBLOODFANG_0033_KEY = "GrumBloodfang_0033"
    constant string VL_GRUMBLOODFANG_0033_TEXT = "Bring me the eggs you find, preferably unhatched."

    // Excel draft: GrumBloodfang Lines | Quest: Dragon Egg Hunt | Event: Unfinished | Done: x
    constant string VL_GRUMBLOODFANG_0034_KEY = "GrumBloodfang_0034"
    constant string VL_GRUMBLOODFANG_0034_TEXT = "Handle the eggs with care, fool!"
    constant string VL_GRUMBLOODFANG_0035_KEY = "GrumBloodfang_0035"
    constant string VL_GRUMBLOODFANG_0035_TEXT = "Do not ask questions you do not want answers to. Just bring the eggs."

    // Excel draft: GrumBloodfang Lines | Quest: Dragon Egg Hunt | Event: Completion | Done: x
    constant string VL_GRUMBLOODFANG_0036_KEY = "GrumBloodfang_0036"
    constant string VL_GRUMBLOODFANG_0036_TEXT = "Good. The eggs will be... taken where they must go."
    constant string VL_GRUMBLOODFANG_0037_KEY = "GrumBloodfang_0037"
    constant string VL_GRUMBLOODFANG_0037_TEXT = "I hope you didn't alert the mother dragon..."
    constant string VL_GRUMBLOODFANG_0038_KEY = "GrumBloodfang_0038"
    constant string VL_GRUMBLOODFANG_0038_TEXT = "Your reward. Take it. And forget all about the eggs..."

    // Excel draft: GrumBloodfang Lines | Quest: Drake Hunt | Event: Intro | Done: x
    constant string VL_GRUMBLOODFANG_0042_KEY = "GrumBloodfang_0042"
    constant string VL_GRUMBLOODFANG_0042_TEXT = "The whelps grow into drakes. Drakes grow into dragons. You see the problem?"
    constant string VL_GRUMBLOODFANG_0043_KEY = "GrumBloodfang_0043"
    constant string VL_GRUMBLOODFANG_0043_TEXT = "Hunt them down before they start to scorch our precious Thornwoods to ashes."

    // Excel draft: GrumBloodfang Lines | Quest: Drake Hunt | Event: Unfinished | Done: x
    constant string VL_GRUMBLOODFANG_0044_KEY = "GrumBloodfang_0044"
    constant string VL_GRUMBLOODFANG_0044_TEXT = "You've slain whelps, but now you must face their elder kin."
    constant string VL_GRUMBLOODFANG_0045_KEY = "GrumBloodfang_0045"
    constant string VL_GRUMBLOODFANG_0045_TEXT = "Beware, most drakes are mature enough to breathe devastating fire."

    // Excel draft: GrumBloodfang Lines | Quest: Drake Hunt | Event: Completion | Done: x
    constant string VL_GRUMBLOODFANG_0046_KEY = "GrumBloodfang_0046"
    constant string VL_GRUMBLOODFANG_0046_TEXT = "You've struck down the drakes with your eyebrowns still intact. Grum honors your acts."
    constant string VL_GRUMBLOODFANG_0047_KEY = "GrumBloodfang_0047"
    constant string VL_GRUMBLOODFANG_0047_TEXT = "You have earned this reward."

    // Excel draft: GrumBloodfang Lines | Quest: Desolator | Event: Intro | Done: x
    constant string VL_GRUMBLOODFANG_0051_KEY = "GrumBloodfang_0051"
    constant string VL_GRUMBLOODFANG_0051_TEXT = "The whelps, the eggs, the drakes... all of it leads to this."
    constant string VL_GRUMBLOODFANG_0052_KEY = "GrumBloodfang_0052"
    constant string VL_GRUMBLOODFANG_0052_TEXT = "There is one dragon that casts a shadow over them all: Mordrax the Desolator. Ancient. Cunning. Wrath incarnate."
    constant string VL_GRUMBLOODFANG_0053_KEY = "GrumBloodfang_0053"
    constant string VL_GRUMBLOODFANG_0053_TEXT = "Few who face him live to speak of it. But if you are the warrior you claim to be, you will slay him."
    constant string VL_GRUMBLOODFANG_0054_KEY = "GrumBloodfang_0054"
    constant string VL_GRUMBLOODFANG_0054_TEXT = "Do what I and my hunters have not accomplished; Bring me a piece of his shattered scale, proof of his end."

    // Excel draft: GrumBloodfang Lines | Quest: Desolator | Event: Unfinished | Done: x
    constant string VL_GRUMBLOODFANG_0055_KEY = "GrumBloodfang_0055"
    constant string VL_GRUMBLOODFANG_0055_TEXT = "Mordrax does not fear mortals... but perhaps he should."
    constant string VL_GRUMBLOODFANG_0056_KEY = "GrumBloodfang_0056"
    constant string VL_GRUMBLOODFANG_0056_TEXT = "Don't tell me you're hesitating. Mordraxs grows even stronger with each passing day."

    // Excel draft: GrumBloodfang Lines | Quest: Desolator | Event: Completion | Done: x
    constant string VL_GRUMBLOODFANG_0057_KEY = "GrumBloodfang_0057"
    constant string VL_GRUMBLOODFANG_0057_TEXT = "The great dragon Mordrax is dead, and his shadow lifts from the Highlands."
    constant string VL_GRUMBLOODFANG_0058_KEY = "GrumBloodfang_0058"
    constant string VL_GRUMBLOODFANG_0058_TEXT = "You are the dragonslayer. The Horde will remember your name!"
    constant string VL_GRUMBLOODFANG_0059_KEY = "GrumBloodfang_0059"
    constant string VL_GRUMBLOODFANG_0059_TEXT = "Take this reward. It may not match the glory of your deed, but know that Grum Bloodfang honors you."

    // Excel draft: GrumBloodfang Lines | Quest: Spearman | Event: Drake attacks | Done: x
    constant string VL_GRUMBLOODFANG_0062_KEY = "GrumBloodfang_0062"
    constant string VL_GRUMBLOODFANG_0062_TEXT = "Incoming drake!"

    // Excel draft: GrumBloodfang Lines | Quest: Grum | Event: Drake attacks | Done: x
    constant string VL_GRUMBLOODFANG_0063_KEY = "GrumBloodfang_0063"
    constant string VL_GRUMBLOODFANG_0063_TEXT = "Hah! Another drake to test our mettle. Kill it quickly!"

    // Excel draft: GrumBloodfang Lines | Quest: Spearman | Event: Drake attacks | Done: x
    constant string VL_GRUMBLOODFANG_0064_KEY = "GrumBloodfang_0064"
    constant string VL_GRUMBLOODFANG_0064_TEXT = "It's... too... powerful!"

    // Excel draft: GrumBloodfang Lines | Quest: Grum | Event: Drake attacks | Done: x
    constant string VL_GRUMBLOODFANG_0065_KEY = "GrumBloodfang_0065"
    constant string VL_GRUMBLOODFANG_0065_TEXT = "Bring the beast down!"
    constant string VL_GRUMBLOODFANG_0066_KEY = "GrumBloodfang_0066"
    constant string VL_GRUMBLOODFANG_0066_TEXT = "Stand your ground!"
endglobals

endlibrary
