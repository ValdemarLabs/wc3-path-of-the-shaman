/**
    VoicelinesKribugs

    Author: Valdemar
    Version: 1.5.0

    Description:
    Speaker-owned voiceline key/text constants migrated from legacy
    Excel draft/reference rows. Runtime consumers require this
    library directly when they need these constants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx
    - Warcraft III Ogre unit responses and legacy Kribugs GUI triggers.

    How to install:
    Import after `Voicelines.j`. Import Kribugs audio under
    `Pots\Sound\Voicelines\Kribugs\` and Mogsnort audio under
    `Pots\Sound\Voicelines\Mogsnort\`.

    API:
    Global `VL_KRIBUGS_*` and `VL_MOGSNORT_*` constants.

**/
library VoicelinesKribugs initializer Init requires Voicelines

globals
    constant string VL_KRIBUGS_FOLDER = "Kribugs"
    constant string VL_MOGSNORT_FOLDER = "Mogsnort"

    // Legacy Excel draft/reference rows.

    // Excel draft: Kribugs | Event: First time greet
    constant string VL_KRIBUGS_0001_KEY = "Kribugs_0001"
    constant string VL_KRIBUGS_0001_TEXT = "Welcome, welcome! Kribugs got wares, and Ogre got muscle!"

    // Excel draft: Kribugs | Event: Normal Greet
    constant string VL_KRIBUGS_0004_KEY = "Kribugs_0004"
    constant string VL_KRIBUGS_0004_TEXT = "Step right up! Don't mind the smell, that's just him."
    constant string VL_KRIBUGS_0005_KEY = "Kribugs_0005"
    constant string VL_KRIBUGS_0005_TEXT = "Shiny coin for shiny goods, eh?"
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
    constant string VL_KRIBUGS_0010_TEXT = "Mogsnorty! You can't eat the customer!"
    constant string VL_KRIBUGS_0011_KEY = "Kribugs_0011"
    constant string VL_KRIBUGS_0011_TEXT = "Hey, hey-stop drooling on the merchandise!"
    constant string VL_KRIBUGS_0012_KEY = "Kribugs_0012"
    constant string VL_KRIBUGS_0012_TEXT = "Business is booming... well, kinda dribbling."
    constant string VL_KRIBUGS_0013_KEY = "Kribugs_0013"
    constant string VL_KRIBUGS_0013_TEXT = "Kribugs talks, Ogre carries, everybody happy!"
    constant string VL_KRIBUGS_0014_KEY = "Kribugs_0014"
    constant string VL_KRIBUGS_0014_TEXT = "He's big, I'm smart. ...Mostly smart."

    // Paired exchange: Kribugs_0010, then Mogsnort_0010.
    constant string VL_MOGSNORT_0010_KEY = "Mogsnort_0010"
    constant string VL_MOGSNORT_0010_TEXT = "But he look like meat?"
    constant string VL_MOGSNORT_0011_KEY = "Mogsnort_0011"
    constant string VL_MOGSNORT_0011_TEXT = "Mogsnort not drool. Goods make own wet."

    // Existing Sound Editor cues. These retain their map labels because they
    // play the original Warcraft III ogre responses rather than authored audio.
    constant string VL_MOGSNORT_LEGACY_HUNGRY_KEY = "KribugsOgreHungry"
    constant string VL_MOGSNORT_LEGACY_HUNGRY_TEXT = "So angry! So hungry."
    constant string VL_MOGSNORT_LEGACY_FART_KEY = "KribugsOgreFart"
    constant string VL_MOGSNORT_LEGACY_FART_TEXT = "(Farts, then laughs.)"
    constant string VL_MOGSNORT_LEGACY_WHAT_3_KEY = "KribugsOgreWhat3"
    constant string VL_MOGSNORT_LEGACY_WHAT_3_TEXT = "Huh?"
    constant string VL_MOGSNORT_LEGACY_WHAT_4_KEY = "KribugsOgreWhat4"
    constant string VL_MOGSNORT_LEGACY_WHAT_4_TEXT = "Rrrhmm?"
    constant string VL_MOGSNORT_LEGACY_YES_1_KEY = "KribugsOgreYes1"
    constant string VL_MOGSNORT_LEGACY_YES_1_TEXT = "(Moan.)"
    constant string VL_MOGSNORT_LEGACY_YES_3_KEY = "KribugsOgreYes3"
    constant string VL_MOGSNORT_LEGACY_YES_3_TEXT = "Okay."
    constant string VL_MOGSNORT_LEGACY_YES_4_KEY = "KribugsOgreYes4"
    constant string VL_MOGSNORT_LEGACY_YES_4_TEXT = "(Grunt.)"
    constant string VL_MOGSNORT_LEGACY_ATTACK_3_KEY = "KribugsOgreAttack3"
    constant string VL_MOGSNORT_LEGACY_ATTACK_3_TEXT = "(Growl.)"

    // Kribugs' unique VendorLines profile and trade outcomes.
    constant string VL_KRIBUGS_VENDOR_PROFILE = "Kribugs"
    constant string VL_KRIBUGS_VENDOR_BOUGHT_KEY = "Kribugs_0073"
    constant string VL_KRIBUGS_VENDOR_BOUGHT_TEXT = "Excellent choice! Kribugs would have charged more, but you were too quick."
    constant string VL_KRIBUGS_VENDOR_SOLD_KEY = "Kribugs_0074"
    constant string VL_KRIBUGS_VENDOR_SOLD_TEXT = "Kribugs knows three people who will pay twice that!"
    constant string VL_KRIBUGS_VENDOR_EXCHANGED_KEY = "Kribugs_0075"
    constant string VL_KRIBUGS_VENDOR_EXCHANGED_TEXT = "... and that's a deal!"
    constant string VL_KRIBUGS_VENDOR_NO_TRADE_KEY = "Kribugs_0076"
    constant string VL_KRIBUGS_VENDOR_NO_TRADE_TEXT = "Not even one purchase?"
    constant string VL_MOGSNORT_VENDOR_CHATTER_KEY = "Mogsnort_0077"
    constant string VL_MOGSNORT_VENDOR_CHATTER_TEXT = "Mogsnort guard goods. Goods not run away yet."
    constant string VL_MOGSNORT_VENDOR_BOUGHT_KEY = "Mogsnort_0078"
    constant string VL_MOGSNORT_VENDOR_BOUGHT_TEXT = "Coin tiny and taste bad."
    constant string VL_MOGSNORT_VENDOR_NO_TRADE_KEY = "Mogsnort_0079"
    constant string VL_MOGSNORT_VENDOR_NO_TRADE_TEXT = "Customer no buy. Mogsnort eat customer now?"

    // Excel draft: Kribugs | Quest: Ogre lost his sandwich | Event: Intro | Done: x
    constant string VL_KRIBUGS_0018_KEY = "Kribugs_0018"
    constant string VL_KRIBUGS_0018_TEXT = "Ogre is sad... he lost his sandwich. Big sandwich. Huge. Maybe fell off on our travel road, huh?"
    constant string VL_KRIBUGS_0019_KEY = "Kribugs_0019"
    constant string VL_KRIBUGS_0019_TEXT = "No sandwich, no smile. Ogre won't move if belly grumbles. You find it, yes?"
    constant string VL_KRIBUGS_0020_KEY = "Kribugs_0020"
    constant string VL_KRIBUGS_0020_TEXT = "He dropped it somewhere... Kribugs heard 'plop!' on the way. Find it before it grows legs!"
    constant string VL_MOGSNORT_0019_KEY = "Mogsnort_0019"
    constant string VL_MOGSNORT_0019_TEXT = "Belly eating belly. Mogsnort need sandwich."

    // Excel draft: Kribugs | Quest: Ogre lost his sandwich | Event: Completion | Done: x
    constant string VL_KRIBUGS_0022_KEY = "Kribugs_0022"
    constant string VL_KRIBUGS_0022_TEXT = "Sandwich! You found it! Ogre happy, Kribugs happy, everybody happy!"
    constant string VL_KRIBUGS_0023_KEY = "Kribugs_0023"
    constant string VL_KRIBUGS_0023_TEXT = "Look at his face-he smiling! That's worth more than gold. ...Not really, but close."
    constant string VL_KRIBUGS_0024_KEY = "Kribugs_0024"
    constant string VL_KRIBUGS_0024_TEXT = "Mmm, smells worse than before... but Ogre don't care!"
    constant string VL_MOGSNORT_0022_KEY = "Mogsnort_0022"
    constant string VL_MOGSNORT_0022_TEXT = "Sandwich come home! Mogsnort forgive sandwich."

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
    constant string VL_KRIBUGS_0032_TEXT = "Nice work, friend! Mogsnort didn't even notice it was gone..."

    // Excel draft: Kribugs | Quest: Ogre is very thirsty | Event: Intro | Done: x
    constant string VL_KRIBUGS_0034_KEY = "Kribugs_0034"
    constant string VL_KRIBUGS_0034_TEXT = "Ogre is thirsty. Very thirsty. He drink swamp water-bad idea! Now he green... greener than usual."
    constant string VL_KRIBUGS_0035_KEY = "Kribugs_0035"
    constant string VL_KRIBUGS_0035_TEXT = "He needs good water! Crystal water, shiny, sparkly, makes belly whole again."
    constant string VL_KRIBUGS_0036_KEY = "Kribugs_0036"
    constant string VL_KRIBUGS_0036_TEXT = "Without water, Ogre fall down... and then who carry Kribugs, huh?"
    constant string VL_MOGSNORT_0035_KEY = "Mogsnort_0035"
    constant string VL_MOGSNORT_0035_TEXT = "Mogsnort no like bones in water."

    // Excel draft: Kribugs | Quest: Ogre is very thirsty | Event: Completion | Done: x
    constant string VL_KRIBUGS_0038_KEY = "Kribugs_0038"
    constant string VL_KRIBUGS_0038_TEXT = "Ahhh, see? Ogre drinks crystal water, Ogre is happy, Kribugs rides again!"
    constant string VL_KRIBUGS_0039_KEY = "Kribugs_0039"
    constant string VL_KRIBUGS_0039_TEXT = "He slurp-sluuuurp... never seen him this cheerful since sandwich time."
    constant string VL_KRIBUGS_0040_KEY = "Kribugs_0040"
    constant string VL_KRIBUGS_0040_TEXT = "That's some strong water! Ogre burp loud enough to scare the gnolls away!"

    // Excel draft: Kribugs | Quest: Meat for the Ogre | Event: Intro | Done: x
    constant string VL_KRIBUGS_0043_KEY = "Kribugs_0043"
    constant string VL_KRIBUGS_0043_TEXT = "Ogre's belly rumbles louder than thunder! He wants meat, BIG meat."
    constant string VL_KRIBUGS_0044_KEY = "Kribugs_0044"
    constant string VL_KRIBUGS_0044_TEXT = "Find something tasty-beast, boar, snake, I don't know and I don't know - whatever. Ogre not picky."
    constant string VL_KRIBUGS_0045_KEY = "Kribugs_0045"
    constant string VL_KRIBUGS_0045_TEXT = "Hmm... No meat, no move, no sales! Ogre seems to be too hungry to carry Kribugs!"
    constant string VL_MOGSNORT_0043_KEY = "Mogsnort_0043"
    constant string VL_MOGSNORT_0043_TEXT = "Mogsnort eat big meat. Maybe meat carrying smaller meat."

    // Excel draft: Kribugs | Quest: Meat for the Ogre | Event: Completion | Done: x
    constant string VL_KRIBUGS_0046_KEY = "Kribugs_0046"
    constant string VL_KRIBUGS_0046_TEXT = "Yes! Ogre chomps, Kribugs rides again!"
    constant string VL_KRIBUGS_0047_KEY = "Kribugs_0047"
    constant string VL_KRIBUGS_0047_TEXT = "Look at him-chewing like happy troll. Good work!"

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Intro | Done: x
    constant string VL_KRIBUGS_0050_KEY = "Kribugs_0050"
    constant string VL_KRIBUGS_0050_TEXT = "Ogre ate too many swamp shrooms. Now he makes... noises."
    constant string VL_KRIBUGS_0051_KEY = "Kribugs_0051"
    constant string VL_KRIBUGS_0051_TEXT = "He groans, he moans, and Kribugs can't sell wares like this!"
    constant string VL_KRIBUGS_0052_KEY = "Kribugs_0052"
    constant string VL_KRIBUGS_0052_TEXT = "Find herbs, potion, something to make belly stop bubbling!"
    constant string VL_MOGSNORT_0050_KEY = "Mogsnort_0050"
    constant string VL_MOGSNORT_0050_TEXT = "Shrooms fight in belly. Belly losing."

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Failed attempt | Done: x
    constant string VL_KRIBUGS_0053_KEY = "Kribugs_0053"
    constant string VL_KRIBUGS_0053_TEXT = "Um... Well that didn't work!"

    // Excel draft: Kribugs | Quest: The Ogre Ate Too Much | Event: Completion | Done: x
    constant string VL_KRIBUGS_0054_KEY = "Kribugs_0054"
    constant string VL_KRIBUGS_0054_TEXT = "Ogre smiling again! ...Oh no, he burp."
    constant string VL_KRIBUGS_0055_KEY = "Kribugs_0055"
    constant string VL_KRIBUGS_0055_TEXT = "Herbs worked! Ogre not green anymore. Well... not extra green."
    constant string VL_KRIBUGS_0056_KEY = "Kribugs_0056"
    constant string VL_KRIBUGS_0056_TEXT = "Thank you, thank you! Now Kribugs' shop smells less deadly."
    constant string VL_MOGSNORT_0055_KEY = "Mogsnort_0055"
    constant string VL_MOGSNORT_0055_TEXT = "Mogsnort fixed. Burp still good."

    // Excel draft: Kribugs | Quest: Kribugs' 'Special Deal' | Event: Intro | Done: x
    constant string VL_KRIBUGS_0059_KEY = "Kribugs_0059"
    constant string VL_KRIBUGS_0059_TEXT = "Psst! Special deal, just for you. Kribugs guarantees value... probably."
    constant string VL_KRIBUGS_0060_KEY = "Kribugs_0060"
    constant string VL_KRIBUGS_0060_TEXT = "One-of-a-kind treasure! Could be shiny, could be stinky-who knows!"
    constant string VL_KRIBUGS_0061_KEY = "Kribugs_0061"
    constant string VL_KRIBUGS_0061_TEXT = "Pay gold, get surprise. Ogre calls it 'gamble,' Kribugs calls it 'business.'"

    // Excel draft: Kribugs | Quest: Kribugs' 'Special Deal' | Event: Paid | Done: x
    constant string VL_KRIBUGS_0062_KEY = "Kribugs_0062"
    constant string VL_KRIBUGS_0062_TEXT = "Heh-heh! You paid, you played, now enjoy your... whatever that is."
    constant string VL_KRIBUGS_0063_KEY = "Kribugs_0063"
    constant string VL_KRIBUGS_0063_TEXT = "See? Totally worth it! Maybe. But don't ask for refund."
    constant string VL_KRIBUGS_0064_KEY = "Kribugs_0064"
    constant string VL_KRIBUGS_0064_TEXT = "Lucky you! Or unlucky you."

    // Excel draft: Kribugs | Quest: Angry Customers | Event: Intro | Done: x
    constant string VL_KRIBUGS_0067_KEY = "Kribugs_0067"
    constant string VL_KRIBUGS_0067_TEXT = "Eh-heh... small problem. Some past customers... not happy with Kribugs."
    constant string VL_KRIBUGS_0068_KEY = "Kribugs_0068"
    constant string VL_KRIBUGS_0068_TEXT = "They say 'bad deals.' I say 'business!' Now they come with pointy sticks."
    constant string VL_KRIBUGS_0069_KEY = "Kribugs_0069"
    constant string VL_KRIBUGS_0069_TEXT = "Help chase 'em off before Ogre squishes wrong people!"
    constant string VL_MOGSNORT_0068_KEY = "Mogsnort_0068"
    constant string VL_MOGSNORT_0068_TEXT = "Pointy people crunchy. Mogsnort smash them!."

    // Excel draft: Kribugs | Quest: Angry Customers | Event: Completion | Done: x
    constant string VL_KRIBUGS_0070_KEY = "Kribugs_0070"
    constant string VL_KRIBUGS_0070_TEXT = "Safe again! But customers gone, business plan open!"
    constant string VL_KRIBUGS_0071_KEY = "Kribugs_0071"
    constant string VL_KRIBUGS_0071_TEXT = "See? They angry, you smash, Kribugs happy!"
    constant string VL_KRIBUGS_0072_KEY = "Kribugs_0072"
    constant string VL_KRIBUGS_0072_TEXT = "Now everyone remembers rule one: no refunds!"
endglobals

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0001_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0004_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0005_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0006_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0007_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0008_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0009_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0010_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0011_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0012_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0013_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0014_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0018_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0019_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0020_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0022_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0023_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0024_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0026_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0027_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0028_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0030_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0031_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0032_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0034_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0035_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0036_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0038_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0039_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0040_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0043_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0044_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0045_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0046_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0047_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0050_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0051_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0052_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0053_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0054_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0055_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0056_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0059_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0060_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0061_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0062_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0063_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0064_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0067_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0068_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0069_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0070_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0071_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_0072_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_VENDOR_BOUGHT_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_VENDOR_SOLD_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_VENDOR_EXCHANGED_KEY)
    call Voicelines_RegisterKey(VL_KRIBUGS_FOLDER, VL_KRIBUGS_VENDOR_NO_TRADE_KEY)

    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0010_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0011_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0019_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0022_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0035_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0043_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0050_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0055_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_0068_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_VENDOR_CHATTER_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_VENDOR_BOUGHT_KEY)
    call Voicelines_RegisterKey(VL_MOGSNORT_FOLDER, VL_MOGSNORT_VENDOR_NO_TRADE_KEY)
endfunction

endlibrary
