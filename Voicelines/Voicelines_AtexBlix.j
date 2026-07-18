/**
    VoicelinesAtexBlix

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
    Global `VL_ATEXBLIX_*` constants.

**/
library VoicelinesAtexBlix requires Voicelines

globals
    constant string VL_ATEXBLIX_FOLDER = "AtexBlix"

    // Legacy Excel draft/reference rows.

    // Excel draft: Risk Assessor Blix | Event: First time greet
    constant string VL_ATEXBLIX_0001_KEY = "AtexBlix_0001"
    constant string VL_ATEXBLIX_0001_TEXT = "Welcome! Please sign a visitor form and grab a safety helmet if you're about to enter the mine."

    // Excel draft: Risk Assessor Blix | Event: Goodbye
    constant string VL_ATEXBLIX_0004_KEY = "AtexBlix_0004"
    constant string VL_ATEXBLIX_0004_TEXT = "Shake hands with danger!"
    constant string VL_ATEXBLIX_0005_KEY = "AtexBlix_0005"
    constant string VL_ATEXBLIX_0005_TEXT = "You'll save yourself a minute, but you may damn well lose it all."

    // Excel draft: Risk Assessor Blix | Event: Normal Greet
    constant string VL_ATEXBLIX_0006_KEY = "AtexBlix_0006"
    constant string VL_ATEXBLIX_0006_TEXT = "Back again?"
    constant string VL_ATEXBLIX_0007_KEY = "AtexBlix_0007"
    constant string VL_ATEXBLIX_0007_TEXT = "Oh good, it's you."
    constant string VL_ATEXBLIX_0008_KEY = "AtexBlix_0008"
    constant string VL_ATEXBLIX_0008_TEXT = "I will teach these Boom Brothers a lesson or two..."

    // Excel draft: Risk Assessor Blix | Quest: Boomsite Compliance Inspection | Event: Pre | Done: x
    constant string VL_ATEXBLIX_0023_KEY = "AtexBlix_0023"
    constant string VL_ATEXBLIX_0023_TEXT = "Whoa! Unauthorized explosive transfer? Without my hazard analysis? You gobbos just love tempting fate, huh?"
    constant string VL_ATEXBLIX_0024_KEY = "AtexBlix_0024"
    constant string VL_ATEXBLIX_0024_TEXT = "Excellent delivery! Zero explosion rate. But now we've got a structural integrity nightmare. These tunnels are held up by dreams and termites!"

    // Excel draft: Risk Assessor Blix | Quest: Boomsite Compliance Inspection | Done: x
    constant string VL_ATEXBLIX_0025_KEY = "AtexBlix_0025"
    constant string VL_ATEXBLIX_0025_TEXT = "Wrong. According to Goblin Boom Safety Standard 6.9, subsection 'Splinters & Doom', we need quality timber to reinforce these shafts."
    constant string VL_ATEXBLIX_0026_KEY = "AtexBlix_0026"
    constant string VL_ATEXBLIX_0026_TEXT = "Incorrect. You will be working as Unofficial Assistant Safety Inspector under my supervision. No badge, just lots of walking."

    // Excel draft: Risk Assessor Blix | Event: Intro | Done: x
    constant string VL_ATEXBLIX_0027_KEY = "AtexBlix_0027"
    constant string VL_ATEXBLIX_0027_TEXT = "You'll need to obtain ten logs that meet Goblin Reinforcement Class-3B standards. That means: low sap, high tension, no mushrooms and not curved like banana."

    // Excel draft: Risk Assessor Blix | Quest: Boomsite Compliance Inspection | Done: x
    constant string VL_ATEXBLIX_0029_KEY = "AtexBlix_0029"
    constant string VL_ATEXBLIX_0029_TEXT = "Ah! This one seems fine, no warping and overall looks great."
    constant string VL_ATEXBLIX_0030_KEY = "AtexBlix_0030"
    constant string VL_ATEXBLIX_0030_TEXT = "Beautiful grains! No rot, no termites, barely any bite marks. This stuff screams safe detonation zone."

    // Excel draft: Risk Assessor Blix | Done: x
    constant string VL_ATEXBLIX_0031_KEY = "AtexBlix_0031"
    constant string VL_ATEXBLIX_0031_TEXT = "Nope. Too bendy. This would turn into a noodle during the first controlled detonation."
    constant string VL_ATEXBLIX_0032_KEY = "AtexBlix_0032"
    constant string VL_ATEXBLIX_0032_TEXT = "Did this come from kobolds? Either way, rejected!"
    constant string VL_ATEXBLIX_0033_KEY = "AtexBlix_0033"
    constant string VL_ATEXBLIX_0033_TEXT = "Ten logs of glory! This mine might not collapse now..."

    // Excel draft: Risk Assessor Blix | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Pre | Done: x
    constant string VL_ATEXBLIX_0036_KEY = "AtexBlix_0036"
    constant string VL_ATEXBLIX_0036_TEXT = "STOP! Before any kabooms commence - we need to address... airborne particle ignition risk."
    constant string VL_ATEXBLIX_0037_KEY = "AtexBlix_0037"
    constant string VL_ATEXBLIX_0037_TEXT = "Mine dust. It's everywhere. And it's flammable. One spark and we'll all be confetti with eyebrows."
    constant string VL_ATEXBLIX_0038_KEY = "AtexBlix_0038"
    constant string VL_ATEXBLIX_0038_TEXT = "Not a bad idea, actually. But first - we need proper ventilation and dust-clearing equipment."

    // Excel draft: Risk Assessor Blix | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Intro | Done: x
    constant string VL_ATEXBLIX_0039_KEY = "AtexBlix_0039"
    constant string VL_ATEXBLIX_0039_TEXT = "Before any sanctioned detonation, subsection 3-C of the Goblin Kaboom Safety Doctrine demands dust mitigation"
    constant string VL_ATEXBLIX_0040_KEY = "AtexBlix_0040"
    constant string VL_ATEXBLIX_0040_TEXT = "We need proper ventilation. Industrial-grade goblin dust mitigation tech: filters, blowers, and a vacuum tank that doesn't scream when powered."

    // Excel draft: Risk Assessor Blix | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Completion | Done: x
    constant string VL_ATEXBLIX_0041_KEY = "AtexBlix_0041"
    constant string VL_ATEXBLIX_0041_TEXT = "Filter's aligned... airflow steady... yep, still louder than a kodo stampede, but safe enough."
    constant string VL_ATEXBLIX_0042_KEY = "AtexBlix_0042"
    constant string VL_ATEXBLIX_0042_TEXT = "Excellent airflow! We've reduced spontaneous combustion risk by 82%. The air's still awful, but at least it won't ignite."
    constant string VL_ATEXBLIX_0043_KEY = "AtexBlix_0043"
    constant string VL_ATEXBLIX_0043_TEXT = "Not yet! Section 4-A of the Goblin Safety Manual - escape paths must be marked, cleared, and drill-tested."

    // Excel draft: Risk Assessor Blix | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Completion
    constant string VL_ATEXBLIX_0044_KEY = "AtexBlix_0044"
    constant string VL_ATEXBLIX_0044_TEXT = "Not yet! Section 4-A of the um.... Goblin Safety Manual - all mine workers must complete mandatory training!"

    // Excel draft: Risk Assessor Blix | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Completion | Done: x
    constant string VL_ATEXBLIX_0047_KEY = "AtexBlix_0047"
    constant string VL_ATEXBLIX_0047_TEXT = "Alright. Support beams secured. Dust under control. But what happens when something goes boom where it shouldn't?"

    // Excel draft: Risk Assessor Blix | Quest: Mandatory Training | Event: Intro | Done: x
    constant string VL_ATEXBLIX_0050_KEY = "AtexBlix_0050"
    constant string VL_ATEXBLIX_0050_TEXT = "Final safety compliance step!"
    constant string VL_ATEXBLIX_0051_KEY = "AtexBlix_0051"
    constant string VL_ATEXBLIX_0051_TEXT = "All boom-handlers and pit-grunts must attend formal explosive certification at the Kobold-run safety camp. It's... very official. Totally above board."
    constant string VL_ATEXBLIX_0052_KEY = "AtexBlix_0052"
    constant string VL_ATEXBLIX_0052_TEXT = "You my friend. Escord Fizzit and Sprokk and the crew to that kobold-run safety camp."
    constant string VL_ATEXBLIX_0053_KEY = "AtexBlix_0053"
    constant string VL_ATEXBLIX_0053_TEXT = "Driving away those pesky kobolds is minor inconvenience that can be seen as part of the physical training on top of the safety training."
    constant string VL_ATEXBLIX_0054_KEY = "AtexBlix_0054"
    constant string VL_ATEXBLIX_0054_TEXT = "However, your primary training objectives are outlined in the formal safety instructions I give you."

    // Excel draft: Risk Assessor Blix | Quest: Mandatory Training | Event: On returning | Done: x
    constant string VL_ATEXBLIX_0058_KEY = "AtexBlix_0058"
    constant string VL_ATEXBLIX_0058_TEXT = "You fools returned already."
    constant string VL_ATEXBLIX_0059_KEY = "AtexBlix_0059"
    constant string VL_ATEXBLIX_0059_TEXT = "The mine is now under my control. I am the hazard now."
    constant string VL_ATEXBLIX_0060_KEY = "AtexBlix_0060"
    constant string VL_ATEXBLIX_0060_TEXT = "Ahahaha!"
    constant string VL_ATEXBLIX_0061_KEY = "AtexBlix_0061"
    constant string VL_ATEXBLIX_0061_TEXT = "Fools! I will never give up the mine!"

    // Excel draft: Risk Assessor Blix | Done: x
    constant string VL_ATEXBLIX_0064_KEY = "AtexBlix_0064"
    constant string VL_ATEXBLIX_0064_TEXT = "This mine is now MINE! Get it? MINE!"
    constant string VL_ATEXBLIX_0065_KEY = "AtexBlix_0065"
    constant string VL_ATEXBLIX_0065_TEXT = "Welcome to your final hazard assessment!"
    constant string VL_ATEXBLIX_0066_KEY = "AtexBlix_0066"
    constant string VL_ATEXBLIX_0066_TEXT = "Welcome to your exit interview!"
    constant string VL_ATEXBLIX_0067_KEY = "AtexBlix_0067"
    constant string VL_ATEXBLIX_0067_TEXT = "I am the CEO of chaos!"
    constant string VL_ATEXBLIX_0068_KEY = "AtexBlix_0068"
    constant string VL_ATEXBLIX_0068_TEXT = "Let's see how many pieces I can turn you into!"
    constant string VL_ATEXBLIX_0069_KEY = "AtexBlix_0069"
    constant string VL_ATEXBLIX_0069_TEXT = "The Boom Brothers are out - Blix is in charge now!"
    constant string VL_ATEXBLIX_0070_KEY = "AtexBlix_0070"
    constant string VL_ATEXBLIX_0070_TEXT = "You're trespassing on BlixCorp™ property!"
    constant string VL_ATEXBLIX_0071_KEY = "AtexBlix_0071"
    constant string VL_ATEXBLIX_0071_TEXT = "I'll crush you into the walls!"
    constant string VL_ATEXBLIX_0072_KEY = "AtexBlix_0072"
    constant string VL_ATEXBLIX_0072_TEXT = "Down you go!"
    constant string VL_ATEXBLIX_0073_KEY = "AtexBlix_0073"
    constant string VL_ATEXBLIX_0073_TEXT = "Another one bites the mine!"
    constant string VL_ATEXBLIX_0074_KEY = "AtexBlix_0074"
    constant string VL_ATEXBLIX_0074_TEXT = "Out of my shaft!"
    constant string VL_ATEXBLIX_0075_KEY = "AtexBlix_0075"
    constant string VL_ATEXBLIX_0075_TEXT = "Guess you're not certified!"
    constant string VL_ATEXBLIX_0076_KEY = "AtexBlix_0076"
    constant string VL_ATEXBLIX_0076_TEXT = "Check this trick out!"
endglobals

endlibrary
