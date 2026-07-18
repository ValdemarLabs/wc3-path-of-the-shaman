/**
    VoicelinesKribugs

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
    Global `VL_KRIBUGS_*` constants.

**/
library VoicelinesKribugs requires Voicelines

globals
    constant string VL_KRIBUGS_FOLDER = "Kribugs"

    // Legacy Excel draft/reference rows.

    // Excel draft: Kribugs | Event: First time greet
    constant string VL_KRIBUGS_0001_KEY = "Kribugs_0001"
    constant string VL_KRIBUGS_0001_TEXT = "Welcome, welcome! Kribugs got wares, and Ogre got muscle!"

    // Excel draft: Kribugs | Event: Normal Greet
    constant string VL_KRIBUGS_0004_KEY = "Kribugs_0004"
    constant string VL_KRIBUGS_0004_TEXT = "Step right up! Don't mind the smell, that's just him."
    constant string VL_KRIBUGS_0005_KEY = "Kribugs_0005"
    constant string VL_KRIBUGS_0005_TEXT = "Shiny coin for shiny goods, eh? Kribugs likes you already."
    constant string VL_KRIBUGS_0006_KEY = "Kribugs_0006"
    constant string VL_KRIBUGS_0006_TEXT = "You want to trade?"

    // Excel draft: Kribugs | Event: Farewell
    constant string VL_KRIBUGS_0007_KEY = "Kribugs_0007"
    constant string VL_KRIBUGS_0007_TEXT = "Spend again soon, or Kribugs gets sad."
    constant string VL_KRIBUGS_0008_KEY = "Kribugs_0008"
    constant string VL_KRIBUGS_0008_TEXT = "Goodbye, come back richer, yes?"
    constant string VL_KRIBUGS_0009_KEY = "Kribugs_0009"
    constant string VL_KRIBUGS_0009_TEXT = "Safe travels!"

    // Excel draft: Kribugs | Event: Random talk
    constant string VL_KRIBUGS_0010_KEY = "Kribugs_0010"
    constant string VL_KRIBUGS_0010_TEXT = "No, Ogre, you can't eat the customer!"
    constant string VL_KRIBUGS_0011_KEY = "Kribugs_0011"
    constant string VL_KRIBUGS_0011_TEXT = "Hey, hey-stop drooling on the merchandise!"
    constant string VL_KRIBUGS_0012_KEY = "Kribugs_0012"
    constant string VL_KRIBUGS_0012_TEXT = "Business is booming... well, kinda dribbling."
    constant string VL_KRIBUGS_0013_KEY = "Kribugs_0013"
    constant string VL_KRIBUGS_0013_TEXT = "Kribugs talks, Ogre carries, everybody happy!"
    constant string VL_KRIBUGS_0014_KEY = "Kribugs_0014"
    constant string VL_KRIBUGS_0014_TEXT = "He's big, I'm smart. ...Mostly smart."

    // Excel draft: Kribugs | Quest: Ogre lost his sandwich | Event: Intro | Done: x
    constant string VL_KRIBUGS_0018_KEY = "Kribugs_0018"
    constant string VL_KRIBUGS_0018_TEXT = "Ogre sad... he lost his sandwich. Big sandwich. Huge. Maybe fell off on our travel road, huh?"
    constant string VL_KRIBUGS_0019_KEY = "Kribugs_0019"
    constant string VL_KRIBUGS_0019_TEXT = "No sandwich, no smile. Ogre won't move if belly grumbles. You find it, yes?"
    constant string VL_KRIBUGS_0020_KEY = "Kribugs_0020"
    constant string VL_KRIBUGS_0020_TEXT = "He dropped it somewhere... Kribugs heard 'plop!' on the way. Find it before it grows legs!"

    // Excel draft: Kribugs | Quest: Ogre lost his sandwich | Event: Completion | Done: x
    constant string VL_KRIBUGS_0022_KEY = "Kribugs_0022"
    constant string VL_KRIBUGS_0022_TEXT = "Sandwich! You found it! Ogre happy, Kribugs happy, everybody happy!"
    constant string VL_KRIBUGS_0023_KEY = "Kribugs_0023"
    constant string VL_KRIBUGS_0023_TEXT = "Look at his face-he smiling! That's worth more than gold. ...Not really, but close."
    constant string VL_KRIBUGS_0024_KEY = "Kribugs_0024"
    constant string VL_KRIBUGS_0024_TEXT = "Mmm, smells worse than before... but Ogre don't care!"

    // Excel draft: Kribugs | Quest: Kribugs lost his satchel | Event: Intro | Done: x
    constant string VL_KRIBUGS_0026_KEY = "Kribugs_0026"
    constant string VL_KRIBUGS_0026_TEXT = "My satchel! My precious satchel, gone! Poof! I bet those gnoll dogs took it."
    constant string VL_KRIBUGS_0027_KEY = "Kribugs_0027"
    constant string VL_KRIBUGS_0027_TEXT = "Satchel's got shiny things, important things! Kribugs feels naked without it!"
    constant string VL_KRIBUGS_0028_KEY = "Kribugs_0028"
    constant string VL_KRIBUGS_0028_TEXT = "Ogre no help-he think satchel is pillow! You help instead, eh?"

    // Excel draft: Kribugs | Quest: Kribugs lost his satchel | Event: Completion | Done: x
    constant string VL_KRIBUGS_0030_KEY = "Kribugs_0030"
    constant string VL_KRIBUGS_0030_TEXT = "Yes-yes! Kribugs' satchel back where it belongs: on my greedy little hands!"
    constant string VL_KRIBUGS_0031_KEY = "Kribugs_0031"
    constant string VL_KRIBUGS_0031_TEXT = "Did gnolls chew on it? Bah, no matter-treasures safe!"
    constant string VL_KRIBUGS_0032_KEY = "Kribugs_0032"
    constant string VL_KRIBUGS_0032_TEXT = "Good work, friend! Ogre didn't even notice it was gone..."

    // Excel draft: Kribugs | Quest: Ogre is very thirsty | Event: Intro | Done: x
    constant string VL_KRIBUGS_0034_KEY = "Kribugs_0034"
    constant string VL_KRIBUGS_0034_TEXT = "Ogre thirsty. Very thirsty. He drink swamp water-bad idea! Now he green... greener than usual."
    constant string VL_KRIBUGS_0035_KEY = "Kribugs_0035"
    constant string VL_KRIBUGS_0035_TEXT = "Need good water! Crystal water, shiny, sparkly, makes belly whole again."
    constant string VL_KRIBUGS_0036_KEY = "Kribugs_0036"
    constant string VL_KRIBUGS_0036_TEXT = "Without water, Ogre fall down... and then who carry Kribugs, huh?"

    // Excel draft: Kribugs | Quest: Ogre is very thirsty | Event: Completion | Done: x
    constant string VL_KRIBUGS_0038_KEY = "Kribugs_0038"
    constant string VL_KRIBUGS_0038_TEXT = "Ahhh, see? Ogre drinks crystal water, Ogre happy, Kribugs rides again!"
    constant string VL_KRIBUGS_0039_KEY = "Kribugs_0039"
    constant string VL_KRIBUGS_0039_TEXT = "He slurp-sluuuurp... never seen him this cheerful since sandwich time."
    constant string VL_KRIBUGS_0040_KEY = "Kribugs_0040"
    constant string VL_KRIBUGS_0040_TEXT = "Good water! Strong water! Ogre burp loud enough to scare the gnolls away!"

    // Excel draft: Kribugs | Quest: Meat for the Ogre | Event: Intro | Done: x
    constant string VL_KRIBUGS_0043_KEY = "Kribugs_0043"
    constant string VL_KRIBUGS_0043_TEXT = "Ogre's belly rumbles louder than thunder! He wants meat, BIG meat."
    constant string VL_KRIBUGS_0044_KEY = "Kribugs_0044"
    constant string VL_KRIBUGS_0044_TEXT = "Find something tasty-beast, boar, even a cow if you fast. Ogre not picky."
    constant string VL_KRIBUGS_0045_KEY = "Kribugs_0045"
    constant string VL_KRIBUGS_0045_TEXT = "No meat, no move. Ogre too hungry to carry Kribugs!"

    // Excel draft: Kribugs | Quest: Meat for the Ogre | Event: Completion | Done: x
    constant string VL_KRIBUGS_0046_KEY = "Kribugs_0046"
    constant string VL_KRIBUGS_0046_TEXT = "Yes-yes! Ogre chomps, Kribugs rides again!"
    constant string VL_KRIBUGS_0047_KEY = "Kribugs_0047"
    constant string VL_KRIBUGS_0047_TEXT = "Look at him-chewing like happy troll. Good work!"

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Intro | Done: x
    constant string VL_KRIBUGS_0050_KEY = "Kribugs_0050"
    constant string VL_KRIBUGS_0050_TEXT = "Ugh... Ogre ate too many swamp shrooms. Now he makes... noises."
    constant string VL_KRIBUGS_0051_KEY = "Kribugs_0051"
    constant string VL_KRIBUGS_0051_TEXT = "He groans, he moans, and Kribugs can't sell wares like this!"
    constant string VL_KRIBUGS_0052_KEY = "Kribugs_0052"
    constant string VL_KRIBUGS_0052_TEXT = "Find herbs, potion, something to make belly stop bubbling!"

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Failed attempt | Done: x
    constant string VL_KRIBUGS_0053_KEY = "Kribugs_0053"
    constant string VL_KRIBUGS_0053_TEXT = "Um... Well that didn't work!"

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Completion | Done: x
    constant string VL_KRIBUGS_0054_KEY = "Kribugs_0054"
    constant string VL_KRIBUGS_0054_TEXT = "Ahhh, Ogre smiling again! ...Oh no, he burp."
    constant string VL_KRIBUGS_0055_KEY = "Kribugs_0055"
    constant string VL_KRIBUGS_0055_TEXT = "Herbs worked! Ogre not green anymore. Well... not extra green."
    constant string VL_KRIBUGS_0056_KEY = "Kribugs_0056"
    constant string VL_KRIBUGS_0056_TEXT = "Thank you, thank you! Now Kribugs' shop smells less deadly."

    // Excel draft: Kribugs | Quest: Kribugs' 'Special Deal' | Event: Intro | Done: x
    constant string VL_KRIBUGS_0059_KEY = "Kribugs_0059"
    constant string VL_KRIBUGS_0059_TEXT = "Psst! Special deal, just for you. Kribugs guarantees value... probably."
    constant string VL_KRIBUGS_0060_KEY = "Kribugs_0060"
    constant string VL_KRIBUGS_0060_TEXT = "One-of-a-kind treasure! Could be shiny, could be stinky-who knows!"
    constant string VL_KRIBUGS_0061_KEY = "Kribugs_0061"
    constant string VL_KRIBUGS_0061_TEXT = "Pay gold, get surprise. Ogre calls it 'gamble,' Kribugs calls it 'business.'"

    // Excel draft: Kribugs | Quest: Kribugs' 'Special Deal' | Event: Paid | Done: x
    constant string VL_KRIBUGS_0062_KEY = "Kribugs_0062"
    constant string VL_KRIBUGS_0062_TEXT = "Heh-heh! You paid, you played, now enjoy your... thing."
    constant string VL_KRIBUGS_0063_KEY = "Kribugs_0063"
    constant string VL_KRIBUGS_0063_TEXT = "See? Totally worth it! Maybe. Don't ask for refund."
    constant string VL_KRIBUGS_0064_KEY = "Kribugs_0064"
    constant string VL_KRIBUGS_0064_TEXT = "Lucky you! Or unlucky you. Kribugs already spent your coin."

    // Excel draft: Kribugs | Quest: Angry Customers | Event: Intro | Done: x
    constant string VL_KRIBUGS_0067_KEY = "Kribugs_0067"
    constant string VL_KRIBUGS_0067_TEXT = "Eh-heh... small problem. Some past customers... not happy with Kribugs."
    constant string VL_KRIBUGS_0068_KEY = "Kribugs_0068"
    constant string VL_KRIBUGS_0068_TEXT = "They say 'bad deals.' I say 'business!' Now they come with pointy sticks."
    constant string VL_KRIBUGS_0069_KEY = "Kribugs_0069"
    constant string VL_KRIBUGS_0069_TEXT = "Help chase 'em off before Ogre squishes wrong people!"

    // Excel draft: Kribugs | Quest: Angry Customers | Event: Completion | Done: x
    constant string VL_KRIBUGS_0070_KEY = "Kribugs_0070"
    constant string VL_KRIBUGS_0070_TEXT = "Safe again! Customers gone, business open!"
    constant string VL_KRIBUGS_0071_KEY = "Kribugs_0071"
    constant string VL_KRIBUGS_0071_TEXT = "See? They angry, you smash, Kribugs happy!"
    constant string VL_KRIBUGS_0072_KEY = "Kribugs_0072"
    constant string VL_KRIBUGS_0072_TEXT = "Now everyone remembers rule one: no refunds!"
endglobals

endlibrary
