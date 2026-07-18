/**
    VoicelinesValeria

    Author: Valdemar
    Version:

    Description:
    Speaker-owned voiceline keys and text constants migrated from active
    qAradion dialog usage and AI profile barks. Active quest lines are
    registered here; the AI profile range is covered by ExSound sequence registration.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx
    - QuestsAndDialogs/QuestGivers/qAradion.j
    - AI/Specific/AI_Valeria.j

    How to install:
    Import after `Voicelines.j`. Consumers require this library directly.

    API:
    Global `VL_VALERIA_####_KEY` and `VL_VALERIA_####_TEXT` constants.

**/
library VoicelinesValeria initializer Init requires Voicelines

globals
    constant string VL_VALERIA_FOLDER = "Valeria"

    // Quest 1: Valeria encounter and negotiation.
    constant string VL_VALERIA_0001_KEY = "Valeria_0001"
    constant string VL_VALERIA_0001_TEXT = "Hold, intruder! Another step and you bleed where you stand!"
    constant string VL_VALERIA_0002_KEY = "Valeria_0002"
    constant string VL_VALERIA_0002_TEXT = "Filthy orc lies! I'll drop you where you stand!"
    constant string VL_VALERIA_0005_KEY = "Valeria_0005"
    constant string VL_VALERIA_0005_TEXT = "Then I shall fall, but so will you!"
    constant string VL_VALERIA_0006_KEY = "Valeria_0006"
    constant string VL_VALERIA_0006_TEXT = "This is my land - not yours!"
    constant string VL_VALERIA_0007_KEY = "Valeria_0007"
    constant string VL_VALERIA_0007_TEXT = "Try it, beast! My bow will show you force!"
    constant string VL_VALERIA_0008_KEY = "Valeria_0008"
    constant string VL_VALERIA_0008_TEXT = "Orc tongues are venom - I won't be deceived!"
    constant string VL_VALERIA_0009_KEY = "Valeria_0009"
    constant string VL_VALERIA_0009_TEXT = "Never! Not while I still draw breath!"
    constant string VL_VALERIA_0010_KEY = "Valeria_0010"
    constant string VL_VALERIA_0010_TEXT = "Then allow me to pass you to the Shadowlands!"
    constant string VL_VALERIA_0011_KEY = "Valeria_0011"
    constant string VL_VALERIA_0011_TEXT = "Warmonger!"
    constant string VL_VALERIA_0012_KEY = "Valeria_0012"
    constant string VL_VALERIA_0012_TEXT = "Silence, you bloodthirsty beast!"
    constant string VL_VALERIA_0013_KEY = "Valeria_0013"
    constant string VL_VALERIA_0013_TEXT = "Lies! All lies!"
    constant string VL_VALERIA_0014_KEY = "Valeria_0014"
    constant string VL_VALERIA_0014_TEXT = "...Aradion? He... lives?"
    constant string VL_VALERIA_0015_KEY = "Valeria_0015"
    constant string VL_VALERIA_0015_TEXT = "If he trusts you, then perhaps I must as well. For his word has never failed me."
    constant string VL_VALERIA_0019_KEY = "Valeria_0019"
    constant string VL_VALERIA_0019_TEXT = "If you speak the truth, then take me to him. Now."
    constant string VL_VALERIA_0020_KEY = "Valeria_0020"
    constant string VL_VALERIA_0020_TEXT = "But know this, orc - I'll be watching you."

    // Missing-Aradion barks and reunion.
    constant string VL_VALERIA_0021_KEY = "Valeria_0021"
    constant string VL_VALERIA_0021_TEXT = "Where is Aradion?"
    constant string VL_VALERIA_0022_KEY = "Valeria_0022"
    constant string VL_VALERIA_0022_TEXT = "I'm watching you carefully..."
    constant string VL_VALERIA_0023_KEY = "Valeria_0023"
    constant string VL_VALERIA_0023_TEXT = "Aradion… It is you! I thought I'd never see you again."
    constant string VL_VALERIA_0024_KEY = "Valeria_0024"
    constant string VL_VALERIA_0024_TEXT = "This orc… he spoke your name, my love. It is the only reason I followed him."
    constant string VL_VALERIA_0025_KEY = "Valeria_0025"
    constant string VL_VALERIA_0025_TEXT = "…Do not think this earns my trust fully, orc. But… for Aradion's sake, I'm giving you a chance."

    // Quest 4: rift ritual barks and failures.
    constant string VL_VALERIA_0060_KEY = "Valeria_0060"
    constant string VL_VALERIA_0060_TEXT = "We have planned this forever… I can handle it, my love. "
    constant string VL_VALERIA_0061_KEY = "Valeria_0061"
    constant string VL_VALERIA_0061_TEXT = "Hold your ground! Don't let them reach Aradion!"
    constant string VL_VALERIA_0062_KEY = "Valeria_0062"
    constant string VL_VALERIA_0062_TEXT = "The rift is pulling every wrath towards it - brace yourself!"
    constant string VL_VALERIA_0063_KEY = "Valeria_0063"
    constant string VL_VALERIA_0063_TEXT = "Aradion...? No!!!"
    constant string VL_VALERIA_0064_KEY = "Valeria_0064"
    constant string VL_VALERIA_0064_TEXT = "Forgive me... my love... I... have failed..."
    constant string VL_VALERIA_0065_KEY = "Valeria_0065"
    constant string VL_VALERIA_0065_TEXT = "They are too many! Drive them back!"
    constant string VL_VALERIA_0066_KEY = "Valeria_0066"
    constant string VL_VALERIA_0066_TEXT = "Great job, my love!"
    constant string VL_VALERIA_0068_KEY = "Valeria_0068"
    constant string VL_VALERIA_0068_TEXT = "You never cease to amaze me, my love."
    constant string VL_VALERIA_0069_KEY = "Valeria_0069"
    constant string VL_VALERIA_0069_TEXT = "Don't worry my love, we will be."
    constant string VL_VALERIA_0070_KEY = "Valeria_0070"
    constant string VL_VALERIA_0070_TEXT = "So, is it... over now? Is this the answer to our people's curse?"
    constant string VL_VALERIA_0071_KEY = "Valeria_0071"
    constant string VL_VALERIA_0071_TEXT = "Gladly."
    constant string VL_VALERIA_0072_KEY = "Valeria_0072"
    constant string VL_VALERIA_0072_TEXT = "We will handle them, just keep your focus on the rift!"
    constant string VL_VALERIA_0073_KEY = "Valeria_0073"
    constant string VL_VALERIA_0073_TEXT = "We stand ready to defend you!"

    // Legacy Excel draft/reference rows not yet wired to active code.

    // Excel draft: Valeria Lines | Quest: A Token of Love | Event: Intro | Done: x
    constant string VL_VALERIA_0028_KEY = "Valeria_0028"
    constant string VL_VALERIA_0028_TEXT = "Aradion may place his faith in you, but my bow remains drawn."
    constant string VL_VALERIA_0029_KEY = "Valeria_0029"
    constant string VL_VALERIA_0029_TEXT = "If you would prove your worth, then bring back what I lost."
    constant string VL_VALERIA_0030_KEY = "Valeria_0030"
    constant string VL_VALERIA_0030_TEXT = "In a rush I left my special necklace in the ruins what was once our beloved Elarindor."
    constant string VL_VALERIA_0031_KEY = "Valeria_0031"
    constant string VL_VALERIA_0031_TEXT = "Find my necklace and bring it to me. It would mean so much for me..."

    // Excel draft: Valeria Lines | Quest: A Token of Love | Event: Unfinished | Done: x
    constant string VL_VALERIA_0032_KEY = "Valeria_0032"
    constant string VL_VALERIA_0032_TEXT = "You return empty-handed. Do not think I'll be swayed with words alone."
    constant string VL_VALERIA_0033_KEY = "Valeria_0033"
    constant string VL_VALERIA_0033_TEXT = "The ruins still hold what I asked for. Find it."

    // Excel draft: Valeria Lines | Quest: A Token of Love | Event: Completion | Done: x
    constant string VL_VALERIA_0034_KEY = "Valeria_0034"
    constant string VL_VALERIA_0034_TEXT = "...You found it! After all this time... it warm as if it never left me."
    constant string VL_VALERIA_0035_KEY = "Valeria_0035"
    constant string VL_VALERIA_0035_TEXT = "I thought it was lost forever..."
    constant string VL_VALERIA_0036_KEY = "Valeria_0036"
    constant string VL_VALERIA_0036_TEXT = "Perhaps I was wrong about you, orc. It seems you are not like the rest of your kind."

    // Excel draft: Valeria Lines | Event: Normal Greet | Done: x
    constant string VL_VALERIA_0038_KEY = "Valeria_0038"
    constant string VL_VALERIA_0038_TEXT = "If you have news, speak it swiftly."
    constant string VL_VALERIA_0039_KEY = "Valeria_0039"
    constant string VL_VALERIA_0039_TEXT = "Every day we lose more to the void."
    constant string VL_VALERIA_0040_KEY = "Valeria_0040"
    constant string VL_VALERIA_0040_TEXT = "I still wonder why you walk among us."
    constant string VL_VALERIA_0041_KEY = "Valeria_0041"
    constant string VL_VALERIA_0041_TEXT = "Elarindor is but a shadow of what it once was."

    // Excel draft: Valeria Lines | Event: Friendly Greet | Done: x
    constant string VL_VALERIA_0042_KEY = "Valeria_0042"
    constant string VL_VALERIA_0042_TEXT = "Your presence steadies my heart."
    constant string VL_VALERIA_0043_KEY = "Valeria_0043"
    constant string VL_VALERIA_0043_TEXT = "Strange, that an orc calms this now wretched place."
    constant string VL_VALERIA_0044_KEY = "Valeria_0044"
    constant string VL_VALERIA_0044_TEXT = "You have done much for us. More than I would have believed."
    constant string VL_VALERIA_0045_KEY = "Valeria_0045"
    constant string VL_VALERIA_0045_TEXT = "More and more I begin to see why Aradion trusts you."

    // Excel draft: Valeria Lines | Event: Goodbye | Done: x
    constant string VL_VALERIA_0046_KEY = "Valeria_0046"
    constant string VL_VALERIA_0046_TEXT = "The shadows grow restless. Be swift, shaman."
    constant string VL_VALERIA_0047_KEY = "Valeria_0047"
    constant string VL_VALERIA_0047_TEXT = "Farewell, and return with more hope than you leave."
    constant string VL_VALERIA_0048_KEY = "Valeria_0048"
    constant string VL_VALERIA_0048_TEXT = "I will remain. Someone must keep watch."

    // Excel draft: Valeria Lines | Quest: Lost Supplies | Event: Intro | Done: x
    constant string VL_VALERIA_0051_KEY = "Valeria_0051"
    constant string VL_VALERIA_0051_TEXT = "When the first wraiths emerged, we fled with nothing but our lives."
    constant string VL_VALERIA_0052_KEY = "Valeria_0052"
    constant string VL_VALERIA_0052_TEXT = "But not all was lost. We hid supply caches throughout Elarindor in those desperate hours."
    constant string VL_VALERIA_0053_KEY = "Valeria_0053"
    constant string VL_VALERIA_0053_TEXT = "If you would like to aid us, orc. Recover what remains. Even scraps could keep us standing."

    // Excel draft: Valeria Lines | Quest: Lost Supplies | Event: Unfinished | Done: x
    constant string VL_VALERIA_0054_KEY = "Valeria_0054"
    constant string VL_VALERIA_0054_TEXT = "Without those supplies, our strength withers further."
    constant string VL_VALERIA_0055_KEY = "Valeria_0055"
    constant string VL_VALERIA_0055_TEXT = "Some of those supplies can be hard to find..."

    // Excel draft: Valeria Lines | Quest: Lost Supplies | Event: Completion | Done: x
    constant string VL_VALERIA_0056_KEY = "Valeria_0056"
    constant string VL_VALERIA_0056_TEXT = "You found them... this is more than I dared to hope for."
    constant string VL_VALERIA_0057_KEY = "Valeria_0057"
    constant string VL_VALERIA_0057_TEXT = "These rations may taste of dust, yet to me, they are sweeter than any feast."
    constant string VL_VALERIA_0058_KEY = "Valeria_0058"
    constant string VL_VALERIA_0058_TEXT = "Nazgrek, you give us another day. And another day means another chance to endure."

    // Excel draft: Valeria Lines | Quest: Rifts of Corruption | Event: Start | Done: x
    constant string VL_VALERIA_0067_KEY = "Valeria_0067"
    constant string VL_VALERIA_0067_TEXT = "Beware the wraiths we may encounter... they can be damaged only by magic and spells."
    constant string VL_VALERIA_0067_TEXT_ALT1 = "I've seen her face shimmering through the mists. Beautiful... but mischievous..."
    constant string VL_VALERIA_0067_TEXT_ALT2 = "We cannot stop them... not yet... not like this..."

    // Excel draft: Valeria Lines | Quest: Denial / Reassuring Lines | Done: x
    constant string VL_VALERIA_0074_KEY = "Valeria_0074"
    constant string VL_VALERIA_0074_TEXT = "If you worry so much, perhaps you should travel elsewhere for a while."
    constant string VL_VALERIA_0075_KEY = "Valeria_0075"
    constant string VL_VALERIA_0075_TEXT = "Stop whispering of curses and hunger. I will not hear such words."

    // AI profile bark lines.
    // AI profile greet barks.
    constant string VL_VALERIA_0181_KEY = "Valeria_0181"
    constant string VL_VALERIA_0181_TEXT = "Keep your hands where I can see them."
    constant string VL_VALERIA_0182_KEY = "Valeria_0182"
    constant string VL_VALERIA_0182_TEXT = "Do not test my patience, outsider."
    constant string VL_VALERIA_0183_KEY = "Valeria_0183"
    constant string VL_VALERIA_0183_TEXT = "Aradion may listen. I am not so naive."
    constant string VL_VALERIA_0184_KEY = "Valeria_0184"
    constant string VL_VALERIA_0184_TEXT = "You came back. That counts for something."
    constant string VL_VALERIA_0185_KEY = "Valeria_0185"
    constant string VL_VALERIA_0185_TEXT = "Is this event important to you?"
    constant string VL_VALERIA_0186_KEY = "Valeria_0186"
    constant string VL_VALERIA_0186_TEXT = "If you came to help, then speak."
    constant string VL_VALERIA_0187_KEY = "Valeria_0187"
    constant string VL_VALERIA_0187_TEXT = "I'm glad that you could make it back here."
    constant string VL_VALERIA_0188_KEY = "Valeria_0188"
    constant string VL_VALERIA_0188_TEXT = "Elarindor knows your steps now. So do I."
    constant string VL_VALERIA_0189_KEY = "Valeria_0189"
    constant string VL_VALERIA_0189_TEXT = "A trusted bow is waiting for you."
    constant string VL_VALERIA_0190_KEY = "Valeria_0190"
    constant string VL_VALERIA_0190_TEXT = "My bow is yours, friend of the Vale."
    constant string VL_VALERIA_0191_KEY = "Valeria_0191"
    constant string VL_VALERIA_0191_TEXT = "You are welcome beneath these trees."
    constant string VL_VALERIA_0192_KEY = "Valeria_0192"
    constant string VL_VALERIA_0192_TEXT = "Elarindor is safer when you return."

    // AI profile farewell barks.
    constant string VL_VALERIA_0193_KEY = "Valeria_0193"
    constant string VL_VALERIA_0193_TEXT = "Leave before the trees decide you lingered too long."
    constant string VL_VALERIA_0194_KEY = "Valeria_0194"
    constant string VL_VALERIA_0194_TEXT = "Go. I have watched strangers enough for one day."
    constant string VL_VALERIA_0195_KEY = "Valeria_0195"
    constant string VL_VALERIA_0195_TEXT = "Keep away from Aradion unless your word stays true."
    constant string VL_VALERIA_0196_KEY = "Valeria_0196"
    constant string VL_VALERIA_0196_TEXT = "Safe travels."
    constant string VL_VALERIA_0197_KEY = "Valeria_0197"
    constant string VL_VALERIA_0197_TEXT = "Stay clear of the old paths after dark."
    constant string VL_VALERIA_0198_KEY = "Valeria_0198"
    constant string VL_VALERIA_0198_TEXT = "Return with quiet steps, not trouble."
    constant string VL_VALERIA_0199_KEY = "Valeria_0199"
    constant string VL_VALERIA_0199_TEXT = "Go with my watch over you."
    constant string VL_VALERIA_0200_KEY = "Valeria_0200"
    constant string VL_VALERIA_0200_TEXT = "May the red leaves hide your trail."
    constant string VL_VALERIA_0201_KEY = "Valeria_0201"
    constant string VL_VALERIA_0201_TEXT = "Call if the Vale darkens again."
    constant string VL_VALERIA_0202_KEY = "Valeria_0202"
    constant string VL_VALERIA_0202_TEXT = "Return safely. Elarindor still needs its champions."
    constant string VL_VALERIA_0203_KEY = "Valeria_0203"
    constant string VL_VALERIA_0203_TEXT = "Walk with my trust, and come back alive."
    constant string VL_VALERIA_0204_KEY = "Valeria_0204"
    constant string VL_VALERIA_0204_TEXT = "The Vale will keep a path open for you."

    // AI profile passive barks.
    constant string VL_VALERIA_0205_KEY = "Valeria_0205"
    constant string VL_VALERIA_0205_TEXT = "I will lower my bow when I have reason."
    constant string VL_VALERIA_0206_KEY = "Valeria_0206"
    constant string VL_VALERIA_0206_TEXT = "I can wait. My arrow cannot."
    constant string VL_VALERIA_0207_KEY = "Valeria_0207"
    constant string VL_VALERIA_0207_TEXT = "Do not mistake restraint for trust."
    constant string VL_VALERIA_0208_KEY = "Valeria_0208"
    constant string VL_VALERIA_0208_TEXT = "I can hold my shot if you keep your word."
    constant string VL_VALERIA_0209_KEY = "Valeria_0209"
    constant string VL_VALERIA_0209_TEXT = "No needless blood today."
    constant string VL_VALERIA_0210_KEY = "Valeria_0210"
    constant string VL_VALERIA_0210_TEXT = "I will watch and let you lead."
    constant string VL_VALERIA_0211_KEY = "Valeria_0211"
    constant string VL_VALERIA_0211_TEXT = "No needless blood. We guard what remains."
    constant string VL_VALERIA_0212_KEY = "Valeria_0212"
    constant string VL_VALERIA_0212_TEXT = "I trust your caution here."
    constant string VL_VALERIA_0213_KEY = "Valeria_0213"
    constant string VL_VALERIA_0213_TEXT = "The Vale has suffered enough."
    constant string VL_VALERIA_0214_KEY = "Valeria_0214"
    constant string VL_VALERIA_0214_TEXT = "Peace, then. Your judgment has earned that."
    constant string VL_VALERIA_0215_KEY = "Valeria_0215"
    constant string VL_VALERIA_0215_TEXT = "If you call for restraint, I will honor it."
    constant string VL_VALERIA_0216_KEY = "Valeria_0216"
    constant string VL_VALERIA_0216_TEXT = "My bow rests while your word holds."

    // AI profile normal barks.
    constant string VL_VALERIA_0217_KEY = "Valeria_0217"
    constant string VL_VALERIA_0217_TEXT = "Walk where I can see you."
    constant string VL_VALERIA_0218_KEY = "Valeria_0218"
    constant string VL_VALERIA_0218_TEXT = "Stay ahead of my arrow, not behind it."
    constant string VL_VALERIA_0219_KEY = "Valeria_0219"
    constant string VL_VALERIA_0219_TEXT = "Eyes open."
    constant string VL_VALERIA_0220_KEY = "Valeria_0220"
    constant string VL_VALERIA_0220_TEXT = "Eyes forward. I will cover the flank."
    constant string VL_VALERIA_0221_KEY = "Valeria_0221"
    constant string VL_VALERIA_0221_TEXT = "Keep close and keep quiet."
    constant string VL_VALERIA_0222_KEY = "Valeria_0222"
    constant string VL_VALERIA_0222_TEXT = "I will take the high line."
    constant string VL_VALERIA_0223_KEY = "Valeria_0223"
    constant string VL_VALERIA_0223_TEXT = "Let's do this."
    constant string VL_VALERIA_0224_KEY = "Valeria_0224"
    constant string VL_VALERIA_0224_TEXT = "I know a safer trail. Follow my marks."
    constant string VL_VALERIA_0225_KEY = "Valeria_0225"
    constant string VL_VALERIA_0225_TEXT = "We move together, or not at all."
    constant string VL_VALERIA_0226_KEY = "Valeria_0226"
    constant string VL_VALERIA_0226_TEXT = "Lead on. My arrows will clear the path."
    constant string VL_VALERIA_0227_KEY = "Valeria_0227"
    constant string VL_VALERIA_0227_TEXT = "Your path is my path today."
    constant string VL_VALERIA_0228_KEY = "Valeria_0228"
    constant string VL_VALERIA_0228_TEXT = "The Vale bends kinder around trusted steps."

    // AI profile aggressive barks.
    constant string VL_VALERIA_0229_KEY = "Valeria_0229"
    constant string VL_VALERIA_0229_TEXT = "Finally. Something I am allowed to shoot."
    constant string VL_VALERIA_0230_KEY = "Valeria_0230"
    constant string VL_VALERIA_0230_TEXT = "Point me at the threat and stay out of my line."
    constant string VL_VALERIA_0231_KEY = "Valeria_0231"
    constant string VL_VALERIA_0231_TEXT = "If they move against us, they fall."
    constant string VL_VALERIA_0232_KEY = "Valeria_0232"
    constant string VL_VALERIA_0232_TEXT = "If they threaten the Vale, they fall."
    constant string VL_VALERIA_0233_KEY = "Valeria_0233"
    constant string VL_VALERIA_0233_TEXT = "Good. Let them learn why rangers keep distance."
    constant string VL_VALERIA_0234_KEY = "Valeria_0234"
    constant string VL_VALERIA_0234_TEXT = "I have been waiting for a clean target."
    constant string VL_VALERIA_0235_KEY = "Valeria_0235"
    constant string VL_VALERIA_0235_TEXT = "No mercy for those who ruin Elarindor."
    constant string VL_VALERIA_0236_KEY = "Valeria_0236"
    constant string VL_VALERIA_0236_TEXT = "For the Vale. Make every strike count."
    constant string VL_VALERIA_0237_KEY = "Valeria_0237"
    constant string VL_VALERIA_0237_TEXT = "The trees will hide us; my arrows will not."
    constant string VL_VALERIA_0238_KEY = "Valeria_0238"
    constant string VL_VALERIA_0238_TEXT = "Together, we strike before fear takes root."
    constant string VL_VALERIA_0239_KEY = "Valeria_0239"
    constant string VL_VALERIA_0239_TEXT = "For Elarindor, and for the friend who stood by it."
    constant string VL_VALERIA_0240_KEY = "Valeria_0240"
    constant string VL_VALERIA_0240_TEXT = "Let them learn what the Vale still protects."

    // AI profile hold-position barks.
    constant string VL_VALERIA_0241_KEY = "Valeria_0241"
    constant string VL_VALERIA_0241_TEXT = "I will hold this line, not your hand."
    constant string VL_VALERIA_0242_KEY = "Valeria_0242"
    constant string VL_VALERIA_0242_TEXT = "I can guard this ground. Do not make me regret it."
    constant string VL_VALERIA_0243_KEY = "Valeria_0243"
    constant string VL_VALERIA_0243_TEXT = "Nothing passes unless I choose."
    constant string VL_VALERIA_0244_KEY = "Valeria_0244"
    constant string VL_VALERIA_0244_TEXT = "This ground gives me a clean line."
    constant string VL_VALERIA_0245_KEY = "Valeria_0245"
    constant string VL_VALERIA_0245_TEXT = "I will hold here. Keep moving."
    constant string VL_VALERIA_0246_KEY = "Valeria_0246"
    constant string VL_VALERIA_0246_TEXT = "Leave this approach to me."
    constant string VL_VALERIA_0247_KEY = "Valeria_0247"
    constant string VL_VALERIA_0247_TEXT = "I will keep this pass sealed."
    constant string VL_VALERIA_0248_KEY = "Valeria_0248"
    constant string VL_VALERIA_0248_TEXT = "Trust the line. I will not let it break."
    constant string VL_VALERIA_0249_KEY = "Valeria_0249"
    constant string VL_VALERIA_0249_TEXT = "This is ranger ground now."
    constant string VL_VALERIA_0250_KEY = "Valeria_0250"
    constant string VL_VALERIA_0250_TEXT = "Nothing crosses while I breathe."
    constant string VL_VALERIA_0251_KEY = "Valeria_0251"
    constant string VL_VALERIA_0251_TEXT = "I will hold until you return."
    constant string VL_VALERIA_0252_KEY = "Valeria_0252"
    constant string VL_VALERIA_0252_TEXT = "I'll remain here with my bow, you go ahead!"

    // AI profile kicked barks.
    constant string VL_VALERIA_0253_KEY = "Valeria_0253"
    constant string VL_VALERIA_0253_TEXT = "Good. I prefer my own company."
    constant string VL_VALERIA_0254_KEY = "Valeria_0254"
    constant string VL_VALERIA_0254_TEXT = "Then I go back to my Aradion."
    constant string VL_VALERIA_0255_KEY = "Valeria_0255"
    constant string VL_VALERIA_0255_TEXT = "Fine. I was done watching your back."
    constant string VL_VALERIA_0256_KEY = "Valeria_0256"
    constant string VL_VALERIA_0256_TEXT = "Then I will watch from the trees."
    constant string VL_VALERIA_0257_KEY = "Valeria_0257"
    constant string VL_VALERIA_0257_TEXT = "Call if trouble finds you."
    constant string VL_VALERIA_0258_KEY = "Valeria_0258"
    constant string VL_VALERIA_0258_TEXT = "Go carefully. I will not be far."
    constant string VL_VALERIA_0259_KEY = "Valeria_0259"
    constant string VL_VALERIA_0259_TEXT = "Call when the Vale needs my bow again."
    constant string VL_VALERIA_0260_KEY = "Valeria_0260"
    constant string VL_VALERIA_0260_TEXT = "I will return to Aradion, but my watch remains."
    constant string VL_VALERIA_0261_KEY = "Valeria_0261"
    constant string VL_VALERIA_0261_TEXT = "You know where to find me."
    constant string VL_VALERIA_0262_KEY = "Valeria_0262"
    constant string VL_VALERIA_0262_TEXT = "I will be near if you need me."
    constant string VL_VALERIA_0263_KEY = "Valeria_0263"
    constant string VL_VALERIA_0263_TEXT = "Our paths part, not our trust."
    constant string VL_VALERIA_0264_KEY = "Valeria_0264"
    constant string VL_VALERIA_0264_TEXT = "Send word and I will come."

    // AI profile idle barks.
    constant string VL_VALERIA_0265_KEY = "Valeria_0265"
    constant string VL_VALERIA_0265_TEXT = "Do not mistake silence for trust."
    constant string VL_VALERIA_0266_KEY = "Valeria_0266"
    constant string VL_VALERIA_0266_TEXT = "Every path through Elarindor carries a memory I would rather forget."
    constant string VL_VALERIA_0267_KEY = "Valeria_0267"
    constant string VL_VALERIA_0267_TEXT = "It is not wise to stay still in Vanguard Vale..."
    constant string VL_VALERIA_0268_KEY = "Valeria_0268"
    constant string VL_VALERIA_0268_TEXT = "Atleast the mighty red trees have retained their beauty in this place."
    constant string VL_VALERIA_0269_KEY = "Valeria_0269"
    constant string VL_VALERIA_0269_TEXT = "The trees remember where the wraiths passed."
    constant string VL_VALERIA_0270_KEY = "Valeria_0270"
    constant string VL_VALERIA_0270_TEXT = "I was a ranger before the Vale broke. I remain one after."
    constant string VL_VALERIA_0271_KEY = "Valeria_0271"
    constant string VL_VALERIA_0271_TEXT = "Aradion tries his best to end our people's suffering."
    constant string VL_VALERIA_0272_KEY = "Valeria_0272"
    constant string VL_VALERIA_0272_TEXT = "I could use a real bath, but that lake can do."
    constant string VL_VALERIA_0273_KEY = "Valeria_0273"
    constant string VL_VALERIA_0273_TEXT = "Aradion blames himself for the events that lead to our people's demise too much."
    constant string VL_VALERIA_0274_KEY = "Valeria_0274"
    constant string VL_VALERIA_0274_TEXT = "For once, the Vale feels almost willing to heal."
    constant string VL_VALERIA_0275_KEY = "Valeria_0275"
    constant string VL_VALERIA_0275_TEXT = "I have watched my brother turn into a monster... and now he is gone."
    constant string VL_VALERIA_0276_KEY = "Valeria_0276"
    constant string VL_VALERIA_0276_TEXT = "Some mornings here almost feel like home again."

    // AI profile moving barks.
    constant string VL_VALERIA_0277_KEY = "Valeria_0277"
    constant string VL_VALERIA_0277_TEXT = "Stay ahead of my arrow, not behind it."
    constant string VL_VALERIA_0278_KEY = "Valeria_0278"
    constant string VL_VALERIA_0278_TEXT = "Do not wander into my line of fire."
    constant string VL_VALERIA_0279_KEY = "Valeria_0279"
    constant string VL_VALERIA_0279_TEXT = "Quiet. I heard something in the brush."
    constant string VL_VALERIA_0280_KEY = "Valeria_0280"
    constant string VL_VALERIA_0280_TEXT = "Quiet steps. Loose grip. Breathe."
    constant string VL_VALERIA_0281_KEY = "Valeria_0281"
    constant string VL_VALERIA_0281_TEXT = "Keep on moving!"
    constant string VL_VALERIA_0282_KEY = "Valeria_0282"
    constant string VL_VALERIA_0282_TEXT = "I will mark the safer path."
    constant string VL_VALERIA_0283_KEY = "Valeria_0283"
    constant string VL_VALERIA_0283_TEXT = "I know a safer path. Follow close."
    constant string VL_VALERIA_0284_KEY = "Valeria_0284"
    constant string VL_VALERIA_0284_TEXT = "I had a pet faerie dragon once. She was so beautiful."
    constant string VL_VALERIA_0285_KEY = "Valeria_0285"
    constant string VL_VALERIA_0285_TEXT = "Your steps have grown quieter."
    constant string VL_VALERIA_0286_KEY = "Valeria_0286"
    constant string VL_VALERIA_0286_TEXT = "With you, even these old paths feel less cursed."
    constant string VL_VALERIA_0287_KEY = "Valeria_0287"
    constant string VL_VALERIA_0287_TEXT = "Walk with me. I know where the Vale still breathes."
    constant string VL_VALERIA_0288_KEY = "Valeria_0288"
    constant string VL_VALERIA_0288_TEXT = "Where is this adventure going this time?"

    // AI profile drop-items barks.
    constant string VL_VALERIA_0289_KEY = "Valeria_0289"
    constant string VL_VALERIA_0289_TEXT = "Take it. I would rather keep my hands free."
    constant string VL_VALERIA_0290_KEY = "Valeria_0290"
    constant string VL_VALERIA_0290_TEXT = "Take this. It should serve you better."
    constant string VL_VALERIA_0291_KEY = "Valeria_0291"
    constant string VL_VALERIA_0291_TEXT = "Use it well. Elarindor has few gifts left."
    constant string VL_VALERIA_0292_KEY = "Valeria_0292"
    constant string VL_VALERIA_0292_TEXT = "A ranger shares what keeps an ally alive."

    // AI profile item-given barks.
    constant string VL_VALERIA_0293_KEY = "Valeria_0293"
    constant string VL_VALERIA_0293_TEXT = "I will use it if it serves the Vale."
    constant string VL_VALERIA_0294_KEY = "Valeria_0294"
    constant string VL_VALERIA_0294_TEXT = "Useful. I will not waste it."
    constant string VL_VALERIA_0295_KEY = "Valeria_0295"
    constant string VL_VALERIA_0295_TEXT = "You know a ranger's needs. Thank you."
    constant string VL_VALERIA_0296_KEY = "Valeria_0296"
    constant string VL_VALERIA_0296_TEXT = "A thoughtful gift from a trusted hand. I accept."

    // AI profile attacking barks.
    constant string VL_VALERIA_0297_KEY = "Valeria_0297"
    constant string VL_VALERIA_0297_TEXT = "Wrong step."
    constant string VL_VALERIA_0298_KEY = "Valeria_0298"
    constant string VL_VALERIA_0298_TEXT = "I have the shot."
    constant string VL_VALERIA_0299_KEY = "Valeria_0299"
    constant string VL_VALERIA_0299_TEXT = "For Elarindor."
    constant string VL_VALERIA_0300_KEY = "Valeria_0300"
    constant string VL_VALERIA_0300_TEXT = "Bal'a dash, malanore!"

    // AI profile casting barks.
    constant string VL_VALERIA_0301_KEY = "Valeria_0301"
    constant string VL_VALERIA_0301_TEXT = "Hold still."
    constant string VL_VALERIA_0302_KEY = "Valeria_0302"
    constant string VL_VALERIA_0302_TEXT = "This arrow finds its mark."
    constant string VL_VALERIA_0303_KEY = "Valeria_0303"
    constant string VL_VALERIA_0303_TEXT = "Let the old shadows bleed."
    constant string VL_VALERIA_0304_KEY = "Valeria_0304"
    constant string VL_VALERIA_0304_TEXT = "By leaf and oath, fall."

    // AI profile killing barks.
    constant string VL_VALERIA_0305_KEY = "Valeria_0305"
    constant string VL_VALERIA_0305_TEXT = "Stay down."
    constant string VL_VALERIA_0306_KEY = "Valeria_0306"
    constant string VL_VALERIA_0306_TEXT = "Threat ended."
    constant string VL_VALERIA_0307_KEY = "Valeria_0307"
    constant string VL_VALERIA_0307_TEXT = "One less scar on the Vale."
    constant string VL_VALERIA_0308_KEY = "Valeria_0308"
    constant string VL_VALERIA_0308_TEXT = "Anar'alah belore!"

    // AI profile companion-death barks.
    constant string VL_VALERIA_0309_KEY = "Valeria_0309"
    constant string VL_VALERIA_0309_TEXT = "No. Do not make this worse."
    constant string VL_VALERIA_0310_KEY = "Valeria_0310"
    constant string VL_VALERIA_0310_TEXT = "No. We do not fall here."
    constant string VL_VALERIA_0311_KEY = "Valeria_0311"
    constant string VL_VALERIA_0311_TEXT = "Hold! I will not lose another ally."
    constant string VL_VALERIA_0312_KEY = "Valeria_0312"
    constant string VL_VALERIA_0312_TEXT = "No! I swore you would leave this place alive."
endglobals

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0001_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0002_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0005_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0006_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0007_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0008_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0009_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0010_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0011_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0012_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0013_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0014_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0015_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0019_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0020_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0021_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0022_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0023_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0024_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0025_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0060_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0061_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0062_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0063_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0064_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0065_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0066_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0068_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0069_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0070_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0071_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0072_KEY)
    call Voicelines_RegisterKey(VL_VALERIA_FOLDER, VL_VALERIA_0073_KEY)
endfunction

endlibrary
