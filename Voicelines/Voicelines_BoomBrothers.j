/**
    VoicelinesBoomBrothers

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
    Global `VL_BOOMBROTHERS_*` constants.

**/
library VoicelinesBoomBrothers requires Voicelines

globals
    constant string VL_BOOMBROTHERS_FOLDER = "BoomBrothers"

    // Legacy Excel draft/reference rows.

    // Excel draft: Boomer Brothers | Event: First time greet | Done: x
    constant string VL_BOOMBROTHERS_0001_KEY = "Boomers_0001"
    constant string VL_BOOMBROTHERS_0001_TEXT = "Whoa there, big green! You're about to trespass on Boom Brothers Mining & Mayhem™ property!"
    constant string VL_BOOMBROTHERS_0002_KEY = "Boomers_0002"
    constant string VL_BOOMBROTHERS_0002_TEXT = "This here mine is ours! Claimed fair and square with sweat, soot, and slightly unstable explosives!"
    constant string VL_BOOMBROTHERS_0003_KEY = "Boomers_0003"
    constant string VL_BOOMBROTHERS_0003_TEXT = "And if you're here to steal our claim, think again - we sleep on the fuse pile!"

    // Excel draft: Boomer Brothers | Event: Goodbye | Done: x
    constant string VL_BOOMBROTHERS_0004_KEY = "Boomers_0004"
    constant string VL_BOOMBROTHERS_0004_TEXT = "Tick-tock, muscle-head. Time's blowin' away!"
    constant string VL_BOOMBROTHERS_0005_KEY = "Boomers_0005"
    constant string VL_BOOMBROTHERS_0005_TEXT = "If we're not here when you get back... look for the crater."

    // Excel draft: Boomer Brothers | Event: Normal Greet | Done: x
    constant string VL_BOOMBROTHERS_0006_KEY = "Boomers_0006"
    constant string VL_BOOMBROTHERS_0006_TEXT = "Still here? Good. We need all the boom-friendly muscles we can get!"
    constant string VL_BOOMBROTHERS_0007_KEY = "Boomers_0007"
    constant string VL_BOOMBROTHERS_0007_TEXT = "You look like a walking accident - just our type!"

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Intro | Done: x
    constant string VL_BOOMBROTHERS_0010_KEY = "Boomers_0010"
    constant string VL_BOOMBROTHERS_0010_TEXT = "Our precious boom barrels are gone, stolen right out from under our soot-covered noses during the night!"
    constant string VL_BOOMBROTHERS_0011_KEY = "Boomers_0011"
    constant string VL_BOOMBROTHERS_0011_TEXT = "We can't leave the mine to chase 'em down - if we do, someone else'll stake a claim before sunrise!"

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Intro / help yes or no | Done: x
    constant string VL_BOOMBROTHERS_0012_KEY = "Boomers_0012"
    constant string VL_BOOMBROTHERS_0012_TEXT = "You look tough and possibly reckless. Find our missing barrels... or bring us new ones. Either way, we need boom, fast!"

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Intro / decline | Done: x
    constant string VL_BOOMBROTHERS_0013_KEY = "Boomers_0013"
    constant string VL_BOOMBROTHERS_0013_TEXT = "Fine. Just leave us here to rot in a mine with no bang left in it.."
    constant string VL_BOOMBROTHERS_0014_KEY = "Boomers_0014"
    constant string VL_BOOMBROTHERS_0014_TEXT = "Maybe we should start tossing rocks instead. You hear that, Sprokk? We're rock goblins now..."

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Intro / accept | Done: x
    constant string VL_BOOMBROTHERS_0015_KEY = "Boomers_0015"
    constant string VL_BOOMBROTHERS_0015_TEXT = "That's the spirit! Just remember - the barrels are unstable. Don't smack 'em, shake 'em, or think too hard near 'em!"
    constant string VL_BOOMBROTHERS_0016_KEY = "Boomers_0016"
    constant string VL_BOOMBROTHERS_0016_TEXT = "Find the thieves, check shady traders, maybe shake a kobold or two. Just bring us our boom back!"

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Unfinished | Done: x
    constant string VL_BOOMBROTHERS_0017_KEY = "Boomers_0017"
    constant string VL_BOOMBROTHERS_0017_TEXT = "Any sign of our barrels? Or did you just come back to look explosive?"
    constant string VL_BOOMBROTHERS_0018_KEY = "Boomers_0018"
    constant string VL_BOOMBROTHERS_0018_TEXT = "No pressure, but without those barrels, this mine's just a damp hole full of dreams and disappointment."

    // Excel draft: Boomer Brothers | Quest: Explosive Crisis | Event: Completion | Done: x
    constant string VL_BOOMBROTHERS_0019_KEY = "Boomers_0019"
    constant string VL_BOOMBROTHERS_0019_TEXT = "Yes! Our beautiful barrels! Still tickin' too... oh wait-NO don't touch that fuse-!\""
    constant string VL_BOOMBROTHERS_0020_KEY = "Boomers_0020"
    constant string VL_BOOMBROTHERS_0020_TEXT = "You've got the guts and the muscle. If we blow open the next shaft, you're gettin' a cut!"

    // Excel draft: Boomer Brothers | Quest: Boomsite Compliance Inspection | Event: After Explosive Quest | Done: x
    constant string VL_BOOMBROTHERS_0025_KEY = "Boomers_0025"
    constant string VL_BOOMBROTHERS_0025_TEXT = "Now we can finally blast Shaft B open!"
    constant string VL_BOOMBROTHERS_0026_KEY = "Boomers_0026"
    constant string VL_BOOMBROTHERS_0026_TEXT = "Relax, Blix! He barely dropped any barrels!"
    constant string VL_BOOMBROTHERS_0027_KEY = "Boomers_0027"
    constant string VL_BOOMBROTHERS_0027_TEXT = "Come on, Blix! That support beam only creaks if you sneeze directly at it."
    constant string VL_BOOMBROTHERS_0028_KEY = "Boomers_0028"
    constant string VL_BOOMBROTHERS_0028_TEXT = "Besides, wood's wood. Oak, pine, rotted fence post-it's all the same underground."

    // Excel draft: Boomer Brothers | Quest: Boomsite Compliance Inspection | Event: Accepted wood | Done: x
    constant string VL_BOOMBROTHERS_0029_KEY = "Boomers_0029"
    constant string VL_BOOMBROTHERS_0029_TEXT = "Tastes like real wood, too!"
    constant string VL_BOOMBROTHERS_0030_KEY = "Boomers_0030"
    constant string VL_BOOMBROTHERS_0030_TEXT = "Fizzit, stop licking the support beams!"

    // Excel draft: Boomer Brothers | Quest: Boomsite Compliance Inspection | Event: Accepted wood
    constant string VL_BOOMBROTHERS_0031_KEY = "Boomers_0031"
    constant string VL_BOOMBROTHERS_0031_TEXT = "So... we're good to blast now?"

    // Excel draft: Boomer Brothers | Quest: Boomsite Compliance Inspection | Event: Upon Turning in All 10 Good Logs
    constant string VL_BOOMBROTHERS_0032_KEY = "Boomers_0032"
    constant string VL_BOOMBROTHERS_0032_TEXT = "We're actually following safety regs? What's next, unionizing!?"

    // Excel draft: Boomer Brothers | Quest: Boomsite Compliance Inspection | Done: x
    constant string VL_BOOMBROTHERS_0033_KEY = "Boomers_0033"
    constant string VL_BOOMBROTHERS_0033_TEXT = "Don't say a thing anymore or else we will keep doing these stupid things forever..."
    constant string VL_BOOMBROTHERS_0034_KEY = "Boomers_0034"
    constant string VL_BOOMBROTHERS_0034_TEXT = "Not until we carve the logs into support beams, wedge 'em in, and perform a full safety dance."
    constant string VL_BOOMBROTHERS_0035_KEY = "Boomers_0035"
    constant string VL_BOOMBROTHERS_0035_TEXT = "Can we explode things now? Please?"
    constant string VL_BOOMBROTHERS_0036_KEY = "Boomers_0036"
    constant string VL_BOOMBROTHERS_0036_TEXT = "Let's create the support columns first, perhaps we can then start blasting...."

    // Excel draft: Boomer Brothers | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Pre | Done: x
    constant string VL_BOOMBROTHERS_0040_KEY = "Boomers_0040"
    constant string VL_BOOMBROTHERS_0040_TEXT = "Logs secured? Ohhh yes. It's boom-time, baby!"
    constant string VL_BOOMBROTHERS_0041_KEY = "Boomers_0041"
    constant string VL_BOOMBROTHERS_0041_TEXT = "Quick! Let's light it up before Blix shows up with another-"
    constant string VL_BOOMBROTHERS_0042_KEY = "Boomers_0042"
    constant string VL_BOOMBROTHERS_0042_TEXT = "...The what?"
    constant string VL_BOOMBROTHERS_0043_KEY = "Boomers_0043"
    constant string VL_BOOMBROTHERS_0043_TEXT = "This again. We can't even sneeze without a safety seminar."
    constant string VL_BOOMBROTHERS_0044_KEY = "Boomers_0044"
    constant string VL_BOOMBROTHERS_0044_TEXT = "Next he'll make us wear full-face anti-static sniff masks!"

    // Excel draft: Boomer Brothers | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Intro | Done: x
    constant string VL_BOOMBROTHERS_0045_KEY = "Boomers_0045"
    constant string VL_BOOMBROTHERS_0045_TEXT = "He's not joking. Last time we skipped this, Sprokk's eyebrows caught fire for a week."
    constant string VL_BOOMBROTHERS_0046_KEY = "Boomers_0046"
    constant string VL_BOOMBROTHERS_0046_TEXT = "Still smelled better than the soup Fizzit made that night."

    // Excel draft: Boomer Brothers | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Outro | Done: x
    constant string VL_BOOMBROTHERS_0047_KEY = "Boomers_0047"
    constant string VL_BOOMBROTHERS_0047_TEXT = "NOW we can blast, right?! My boom finger's twitching!!!"
    constant string VL_BOOMBROTHERS_0048_KEY = "Boomers_0048"
    constant string VL_BOOMBROTHERS_0048_TEXT = "Are you serious???"
    constant string VL_BOOMBROTHERS_0052_KEY = "Boomers_0052"
    constant string VL_BOOMBROTHERS_0052_TEXT = "We run. Screaming. It's tradition!"

    // Excel draft: Boomer Brothers | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Event: Outro
    constant string VL_BOOMBROTHERS_0053_KEY = "Boomers_0053"
    constant string VL_BOOMBROTHERS_0053_TEXT = "Usually in circles. Once Fizzit even drilled a hole just by running around."

    // Excel draft: Boomer Brothers | Quest: Dust Isn't Just Dirt - It's Combustible Culture
    constant string VL_BOOMBROTHERS_0054_KEY = "Boomers_0054"
    constant string VL_BOOMBROTHERS_0054_TEXT = "So... we panic out here, instead of in there? Feels weird, but okay!"

    // Excel draft: Boomer Brothers | Quest: Mandatory Training | Event: Intro | Done: x
    constant string VL_BOOMBROTHERS_0056_KEY = "Boomers_0056"
    constant string VL_BOOMBROTHERS_0056_TEXT = "Haven't we done this million times already?"
    constant string VL_BOOMBROTHERS_0057_KEY = "Boomers_0057"
    constant string VL_BOOMBROTHERS_0057_TEXT = "Kobolds? They tried to eat my pants last time"
    constant string VL_BOOMBROTHERS_0058_KEY = "Boomers_0058"
    constant string VL_BOOMBROTHERS_0058_TEXT = "Listen up boys! We're moving to the safety camp!"
    constant string VL_BOOMBROTHERS_0059_KEY = "Boomers_0059"
    constant string VL_BOOMBROTHERS_0059_TEXT = "And afterwards... it's BLASTING TIME, BABY!"

    // Excel draft: Boomer Brothers | Quest: Mandatory Training | Event: On quest | Done: x
    constant string VL_BOOMBROTHERS_0060_KEY = "Boomers_0060"
    constant string VL_BOOMBROTHERS_0060_TEXT = "You sure this is the right way?"
    constant string VL_BOOMBROTHERS_0061_KEY = "Boomers_0061"
    constant string VL_BOOMBROTHERS_0061_TEXT = "Are we going to get snacks when we get there?"
    constant string VL_BOOMBROTHERS_0062_KEY = "Boomers_0062"
    constant string VL_BOOMBROTHERS_0062_TEXT = "Yes! We can grill some kobold meat with dynamite."
    constant string VL_BOOMBROTHERS_0063_KEY = "Boomers_0063"
    constant string VL_BOOMBROTHERS_0063_TEXT = "Can we unionize against safety? Is that a thing?"
    constant string VL_BOOMBROTHERS_0064_KEY = "Boomers_0064"
    constant string VL_BOOMBROTHERS_0064_TEXT = "Sometimes you just got to play along."
    constant string VL_BOOMBROTHERS_0065_KEY = "Boomers_0065"
    constant string VL_BOOMBROTHERS_0065_TEXT = "I brought my lucky detonator. You know, in case the training gets boring."
    constant string VL_BOOMBROTHERS_0066_KEY = "Boomers_0066"
    constant string VL_BOOMBROTHERS_0066_TEXT = "That's the one that blew off your eyebrows last week."
    constant string VL_BOOMBROTHERS_0067_KEY = "Boomers_0067"
    constant string VL_BOOMBROTHERS_0067_TEXT = "Exactly! Super lucky. My lucky charm."
    constant string VL_BOOMBROTHERS_0068_KEY = "Boomers_0068"
    constant string VL_BOOMBROTHERS_0068_TEXT = "Hehee, I passed explosives handling exam just by drawing a stick figure with dynamines on his hands. True story."
    constant string VL_BOOMBROTHERS_0069_KEY = "Boomers_0069"
    constant string VL_BOOMBROTHERS_0069_TEXT = "Explains a lot."
    constant string VL_BOOMBROTHERS_0070_KEY = "Boomers_0070"
    constant string VL_BOOMBROTHERS_0070_TEXT = "Remind me again why we're trusting the guy named Blix? That name sounds like a fuse already halfway lit."
    constant string VL_BOOMBROTHERS_0071_KEY = "Boomers_0071"
    constant string VL_BOOMBROTHERS_0071_TEXT = "Didn't you say that he is your cousin's good friend and trustworthy?"
    constant string VL_BOOMBROTHERS_0072_KEY = "Boomers_0072"
    constant string VL_BOOMBROTHERS_0072_TEXT = "I don't remember how he ended up joining our crew... He just popped up!"
    constant string VL_BOOMBROTHERS_0073_KEY = "Boomers_0073"
    constant string VL_BOOMBROTHERS_0073_TEXT = "Hmmm..."

    // Excel draft: Boomer Brothers | Quest: Mandatory Training | Event: On kobold mine | Done: x
    constant string VL_BOOMBROTHERS_0074_KEY = "Boomers_0074"
    constant string VL_BOOMBROTHERS_0074_TEXT = "Gentlemen! We have arrived at our destination!"
    constant string VL_BOOMBROTHERS_0075_KEY = "Boomers_0075"
    constant string VL_BOOMBROTHERS_0075_TEXT = "Okay, we are not really doing this \"training\" stuff, its ridiculous."
    constant string VL_BOOMBROTHERS_0076_KEY = "Boomers_0076"
    constant string VL_BOOMBROTHERS_0076_TEXT = "Let's just put check mark on all the objectives on the list to please Blix and head back."

    // Excel draft: Boomer Brothers | Quest: Mandatory Training | Event: On returning | Done: x
    constant string VL_BOOMBROTHERS_0077_KEY = "Boomers_0077"
    constant string VL_BOOMBROTHERS_0077_TEXT = "Hey! Where's Blix? And what are those turrets doing at the entrance?"
    constant string VL_BOOMBROTHERS_0078_KEY = "Boomers_0078"
    constant string VL_BOOMBROTHERS_0078_TEXT = "We have been deceived. All this safety non-sense was all just to distract us!"
    constant string VL_BOOMBROTHERS_0079_KEY = "Boomers_0079"
    constant string VL_BOOMBROTHERS_0079_TEXT = "You will regret this, Mad Blix!"

    // Excel draft: Boomer Brothers | Quest: Boom Will Be Back | Event: Intro | Done: x
    constant string VL_BOOMBROTHERS_0083_KEY = "Boomers_0083"
    constant string VL_BOOMBROTHERS_0083_TEXT = "He stole OUR MINE?!"
    constant string VL_BOOMBROTHERS_0084_KEY = "Boomers_0084"
    constant string VL_BOOMBROTHERS_0084_TEXT = "Nobody betrays the Boom Brothers and lives to file about it."
    constant string VL_BOOMBROTHERS_0085_KEY = "Boomers_0085"
    constant string VL_BOOMBROTHERS_0085_TEXT = "We're about to file a complaint... with DYNAMITE."
    constant string VL_BOOMBROTHERS_0086_KEY = "Boomers_0086"
    constant string VL_BOOMBROTHERS_0086_TEXT = "I know it's a lot asked, but you must defeat Mad Blix and reclaim the mine back for us!"
    constant string VL_BOOMBROTHERS_0087_KEY = "Boomers_0087"
    constant string VL_BOOMBROTHERS_0087_TEXT = "We will support you with explosives."
    constant string VL_BOOMBROTHERS_0088_KEY = "Boomers_0088"
    constant string VL_BOOMBROTHERS_0088_TEXT = "Blast the heck out of that ...troublemaker! Haha!"

    // Excel draft: Boomer Brothers | Quest: Boom Will Be Back | Event: Unfinished | Done: x
    constant string VL_BOOMBROTHERS_0089_KEY = "Boomers_0089"
    constant string VL_BOOMBROTHERS_0089_TEXT = "Be careful, his goons have probably rigged the tunnels with turrets and traps!"
    constant string VL_BOOMBROTHERS_0090_KEY = "Boomers_0090"
    constant string VL_BOOMBROTHERS_0090_TEXT = "Sprokk, can I go into the mine to blast these infiltrators?!"
    constant string VL_BOOMBROTHERS_0091_KEY = "Boomers_0091"
    constant string VL_BOOMBROTHERS_0091_TEXT = "No Fizzit, let him do the job, we will support - 100 %."

    // Excel draft: Boomer Brothers | Quest: Boom Will Be Back | Event: Completion | Done: x
    constant string VL_BOOMBROTHERS_0092_KEY = "Boomers_0092"
    constant string VL_BOOMBROTHERS_0092_TEXT = "That'll teach him to mess with demolition experts!"
    constant string VL_BOOMBROTHERS_0093_KEY = "Boomers_0093"
    constant string VL_BOOMBROTHERS_0093_TEXT = "Nicey nice! You are our hero!"
    constant string VL_BOOMBROTHERS_0094_KEY = "Boomers_0094"
    constant string VL_BOOMBROTHERS_0094_TEXT = "We are forever in your debt and so therefore as reward, you may anytime go inside the mine and gather ore or what ever you'll find!"

    // Excel draft: Boomer Brothers | Event: Normal greet 2 | Done: x
    constant string VL_BOOMBROTHERS_0096_KEY = "Boomers_0096"
    constant string VL_BOOMBROTHERS_0096_TEXT = "Everything is back how it should be - thanks to you!"
    constant string VL_BOOMBROTHERS_0097_KEY = "Boomers_0097"
    constant string VL_BOOMBROTHERS_0097_TEXT = "I'm now head of kaboom logistics. Self-promoted."
    constant string VL_BOOMBROTHERS_0098_KEY = "Boomers_0098"
    constant string VL_BOOMBROTHERS_0098_TEXT = "Hey Nazgrek - want to help dig a hot tub tunnel? No reason..."
    constant string VL_BOOMBROTHERS_0099_KEY = "Boomers_0099"
    constant string VL_BOOMBROTHERS_0099_TEXT = "Have you found any rare ore vein from the mine yet?"
endglobals

endlibrary
