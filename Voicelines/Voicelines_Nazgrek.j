/**
    VoicelinesNazgrek

    Author: Valdemar
    Version: 1.1.0

    Description:
    Speaker-owned story and reusable generic quest voicelines for Nazgrek.
    This library owns their text, keys, sound registration, and generic
    quest reply variants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx
    - QuestsAndDialogs/QuestGivers/qAradion.j

    How to install:
    Import after `Voicelines.j` and `QuestsGeneric.j`. Consumers require this
    library directly.

    API:
    Global `VL_NAZGREK_####_*` and `VL_NAZGREK_GENERIC_####_*` constants.

**/
library VoicelinesNazgrek initializer Init requires Voicelines, QuestsGeneric

globals
    constant string VL_NAZGREK_FOLDER = "Nazgrek"
    constant string VL_NAZGREK_GENERIC_FOLDER = "NazgrekGeneric"
    constant string VL_NAZGREK_GENERIC_TYPE = "NazgrekGeneric_"

    // Reusable generic quest replies: accept.
    constant string VL_NAZGREK_GENERIC_0001_KEY = "NazgrekGeneric_0001"
    constant string VL_NAZGREK_GENERIC_0001_TEXT = "I will see it done."
    constant string VL_NAZGREK_GENERIC_0002_KEY = "NazgrekGeneric_0002"
    constant string VL_NAZGREK_GENERIC_0002_TEXT = "Understood. I will handle it."
    constant string VL_NAZGREK_GENERIC_0003_KEY = "NazgrekGeneric_0003"
    constant string VL_NAZGREK_GENERIC_0003_TEXT = "The spirits have shown me where to begin."
    constant string VL_NAZGREK_GENERIC_0004_KEY = "NazgrekGeneric_0004"
    constant string VL_NAZGREK_GENERIC_0004_TEXT = "Point me toward the task, and I will finish it."

    // Reusable generic quest replies: kill completion.
    constant string VL_NAZGREK_GENERIC_0005_KEY = "NazgrekGeneric_0005"
    constant string VL_NAZGREK_GENERIC_0005_TEXT = "The threat has been dealt with."
    constant string VL_NAZGREK_GENERIC_0006_KEY = "NazgrekGeneric_0006"
    constant string VL_NAZGREK_GENERIC_0006_TEXT = "The path is safe again."
    constant string VL_NAZGREK_GENERIC_0007_KEY = "NazgrekGeneric_0007"
    constant string VL_NAZGREK_GENERIC_0007_TEXT = "Those enemies will trouble us no longer."
    constant string VL_NAZGREK_GENERIC_0008_KEY = "NazgrekGeneric_0008"
    constant string VL_NAZGREK_GENERIC_0008_TEXT = "The spirits are quiet now. It is done."

    // Reusable generic quest replies: talk completion.
    constant string VL_NAZGREK_GENERIC_0009_KEY = "NazgrekGeneric_0009"
    constant string VL_NAZGREK_GENERIC_0009_TEXT = "I spoke with the one you named."
    constant string VL_NAZGREK_GENERIC_0010_KEY = "NazgrekGeneric_0010"
    constant string VL_NAZGREK_GENERIC_0010_TEXT = "Your message reached its destination."
    constant string VL_NAZGREK_GENERIC_0011_KEY = "NazgrekGeneric_0011"
    constant string VL_NAZGREK_GENERIC_0011_TEXT = "They heard your words and gave me their answer."
    constant string VL_NAZGREK_GENERIC_0012_KEY = "NazgrekGeneric_0012"
    constant string VL_NAZGREK_GENERIC_0012_TEXT = "The discussion is finished."

    // Reusable generic quest replies: fetch completion.
    constant string VL_NAZGREK_GENERIC_0013_KEY = "NazgrekGeneric_0013"
    constant string VL_NAZGREK_GENERIC_0013_TEXT = "I brought what you asked for."
    constant string VL_NAZGREK_GENERIC_0014_KEY = "NazgrekGeneric_0014"
    constant string VL_NAZGREK_GENERIC_0014_TEXT = "The delivery is complete."
    constant string VL_NAZGREK_GENERIC_0015_KEY = "NazgrekGeneric_0015"
    constant string VL_NAZGREK_GENERIC_0015_TEXT = "Everything you requested is here."
    constant string VL_NAZGREK_GENERIC_0016_KEY = "NazgrekGeneric_0016"
    constant string VL_NAZGREK_GENERIC_0016_TEXT = "I gathered the full amount."

    // Reusable generic quest replies: progress.
    constant string VL_NAZGREK_GENERIC_0017_KEY = "NazgrekGeneric_0017"
    constant string VL_NAZGREK_GENERIC_0017_TEXT = "What remains to be done?"
    constant string VL_NAZGREK_GENERIC_0018_KEY = "NazgrekGeneric_0018"
    constant string VL_NAZGREK_GENERIC_0018_TEXT = "I have not forgotten the task."
    constant string VL_NAZGREK_GENERIC_0019_KEY = "NazgrekGeneric_0019"
    constant string VL_NAZGREK_GENERIC_0019_TEXT = "Show me where I am still needed."
    constant string VL_NAZGREK_GENERIC_0020_KEY = "NazgrekGeneric_0020"
    constant string VL_NAZGREK_GENERIC_0020_TEXT = "Tell me what still stands unfinished."

    // Reusable generic quest replies: supply handoff.
    constant string VL_NAZGREK_GENERIC_0021_KEY = "NazgrekGeneric_0021"
    constant string VL_NAZGREK_GENERIC_0021_TEXT = "I was sent to collect the supplies you are holding."
    constant string VL_NAZGREK_GENERIC_0022_KEY = "NazgrekGeneric_0022"
    constant string VL_NAZGREK_GENERIC_0022_TEXT = "I am here for the parcel entrusted to you."
    constant string VL_NAZGREK_GENERIC_0023_KEY = "NazgrekGeneric_0023"
    constant string VL_NAZGREK_GENERIC_0023_TEXT = "You have supplies meant for my quest."
    constant string VL_NAZGREK_GENERIC_0024_KEY = "NazgrekGeneric_0024"
    constant string VL_NAZGREK_GENERIC_0024_TEXT = "Hand me the supplies, and I will see them delivered."

    // Reusable generic quest replies: quest purchase.
    constant string VL_NAZGREK_GENERIC_0025_KEY = "NazgrekGeneric_0025"
    constant string VL_NAZGREK_GENERIC_0025_TEXT = "I was told you carry the item needed for this commission."
    constant string VL_NAZGREK_GENERIC_0026_KEY = "NazgrekGeneric_0026"
    constant string VL_NAZGREK_GENERIC_0026_TEXT = "Show me the goods set aside for this task."
    constant string VL_NAZGREK_GENERIC_0027_KEY = "NazgrekGeneric_0027"
    constant string VL_NAZGREK_GENERIC_0027_TEXT = "This commission requires an item from your stock."
    constant string VL_NAZGREK_GENERIC_0028_KEY = "NazgrekGeneric_0028"
    constant string VL_NAZGREK_GENERIC_0028_TEXT = "I am here to purchase what the quest requires."

    // Legacy Excel draft/reference rows not yet wired to active code.

    // Excel draft: Nazgrek Lines | Quest: Nazgrek's Flask | Done: x
    constant string VL_NAZGREK_0001_KEY = "Nazgrek_0001"
    constant string VL_NAZGREK_0001_TEXT = "There should be plenty of stags and frogs around the forest to create my flask. Finding herbs will definitely be more challenging..."

    // Excel draft: Nazgrek Lines | Event: Kick party member | Done: x
    constant string VL_NAZGREK_0002_KEY = "Nazgrek_0002"
    constant string VL_NAZGREK_0002_TEXT = "Farewell for now, until we meet again"
    constant string VL_NAZGREK_0003_KEY = "Nazgrek_0003"
    constant string VL_NAZGREK_0003_TEXT = "It's been a pleasure to fight alongside you. May the elements guide on your path."
    constant string VL_NAZGREK_0004_KEY = "Nazgrek_0004"
    constant string VL_NAZGREK_0004_TEXT = "Until our paths cross again. Farewell!"

    // Excel draft: Nazgrek Lines | Quest: Horde Camp Intro | Event: Meeting with Thork | Done: x
    constant string VL_NAZGREK_0005_KEY = "Nazgrek_0005"
    constant string VL_NAZGREK_0005_TEXT = "What exactly is the reason you summoned me here, war chief?"

    // Excel draft: Nazgrek Lines | Event: Meeting with Thork | Done: x
    constant string VL_NAZGREK_0006_KEY = "Nazgrek_0006"
    constant string VL_NAZGREK_0006_TEXT = "With all due respect, you drive me away when I did not embrace the Fel like you did. When I remained loyal to the elements you, almost sacrificed me to your demon masters! Nevertheless, the Fel indirectly affected my skin and mind, like it did for you."

    // Excel draft: Nazgrek Lines | Event: Random | Done: x
    constant string VL_NAZGREK_0007_KEY = "Nazgrek_0007"
    constant string VL_NAZGREK_0007_TEXT = "You foul wretched!"

    // Excel draft: Nazgrek Lines | Quest: Nazgrek's Flask | Done: x
    constant string VL_NAZGREK_0008_KEY = "Nazgrek_0008"
    constant string VL_NAZGREK_0008_TEXT = "Hmmm... I forgot that I do not have empty flask in my stack. I need to search for a place that sells them. I could also use some other items like vials to create everyday potions."
    constant string VL_NAZGREK_0009_KEY = "Nazgrek_0009"
    constant string VL_NAZGREK_0009_TEXT = "I have finally gained enough energy to start gathering ingredients to create my own special flask. The power it grants will guarantee the success in the upcoming wolf hunt."

    // Excel draft: Nazgrek Lines | Quest: Outcast witch doctor | Event: First time greet | Done: x
    constant string VL_NAZGREK_0010_KEY = "Nazgrek_0010"
    constant string VL_NAZGREK_0010_TEXT = "Greetings witch doctor! Glad to see that I'm not the only outcast out here in the forest. Why are you here?"

    // Excel draft: Nazgrek Lines | Quest: Outcast witch doctor - unknown entity | Done: x
    constant string VL_NAZGREK_0011_KEY = "Nazgrek_0011"
    constant string VL_NAZGREK_0011_TEXT = "Unknown entity that came out of nowhere? Sounds like Burning Legion..."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt / Sargoth Ichor | Event: Intro | Done: x
    constant string VL_NAZGREK_0012_KEY = "Nazgrek_0012"
    constant string VL_NAZGREK_0012_TEXT = "Spiders?! I hate those eight legged foul creatures!"

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt / Sargoth Ichor | Done: x
    constant string VL_NAZGREK_0013_KEY = "Nazgrek_0013"
    constant string VL_NAZGREK_0013_TEXT = "Do you have any idea where can I find this beast you call Sargoth?"

    // Excel draft: Nazgrek Lines | Done: x
    constant string VL_NAZGREK_0014_KEY = "Nazgrek_0014"
    constant string VL_NAZGREK_0014_TEXT = "I will see what I can do. Farewell for now."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt / Sargoth Ichor | Event: Sargoth Ichor | Done: x
    constant string VL_NAZGREK_0015_KEY = "Nazgrek_0015"
    constant string VL_NAZGREK_0015_TEXT = "Ugh... Here is the ichor of Sargoth as promised, witch doctor."

    // Excel draft: Nazgrek Lines | Done: x
    constant string VL_NAZGREK_0016_KEY = "Nazgrek_0016"
    constant string VL_NAZGREK_0016_TEXT = "Greetings warrior! I am Nazgrek, a shaman."

    // Excel draft: Nazgrek Lines | Event: Alchemy creation | Done: x
    constant string VL_NAZGREK_0017_KEY = "Nazgrek_0017"
    constant string VL_NAZGREK_0017_TEXT = "I don't have all the ingredients!"

    // Excel draft: Nazgrek Lines | Event: Crossing river | Done: x
    constant string VL_NAZGREK_0018_KEY = "Nazgrek_0018"
    constant string VL_NAZGREK_0018_TEXT = "I should probably stay at this side of the river, for now."

    // Excel draft: Nazgrek Lines | Quest: Outcast witch doctor | Event: First time greet | Done: x
    constant string VL_NAZGREK_0019_KEY = "Nazgrek_0019"
    constant string VL_NAZGREK_0019_TEXT = "Greetings witch doctor! I am Nazgrek and I practice in the ways of the elementals like my ancestors."

    // Excel draft: Nazgrek Lines | Quest: Outcast witch doctor | Event: First time greet → Plauge Upon Trees | Done: x
    constant string VL_NAZGREK_0020_KEY = "Nazgrek_0020"
    constant string VL_NAZGREK_0020_TEXT = "Glad to see that I'm not the only outcast out here in the forest. Why are you here?"

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Intro
    constant string VL_NAZGREK_0022_KEY = "Nazgrek_0022"
    constant string VL_NAZGREK_0022_TEXT = "What is happening around the forest?"

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Intro | Done: x
    constant string VL_NAZGREK_0023_KEY = "Nazgrek_0023"
    constant string VL_NAZGREK_0023_TEXT = "Greetings, exalted one. What is happening around the forest?"
    constant string VL_NAZGREK_0024_KEY = "Nazgrek_0024"
    constant string VL_NAZGREK_0024_TEXT = "These are some troublesome news, Jin'Zun."
    constant string VL_NAZGREK_0025_KEY = "Nazgrek_0025"
    constant string VL_NAZGREK_0025_TEXT = "..."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0027_KEY = "Nazgrek_0027"
    constant string VL_NAZGREK_0027_TEXT = "Sounds simple enough. I can finish the recovery process of the trees you started."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Intro / decline
    constant string VL_NAZGREK_0029_KEY = "Nazgrek_0029"
    constant string VL_NAZGREK_0029_TEXT = "I really don't have time for this... futility."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Unfinished / need new wards | Done: x
    constant string VL_NAZGREK_0030_KEY = "Nazgrek_0030"
    constant string VL_NAZGREK_0030_TEXT = "It's a work in progress..."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Unfinished / new wards given | Done: x
    constant string VL_NAZGREK_0031_KEY = "Nazgrek_0031"
    constant string VL_NAZGREK_0031_TEXT = "I think... I think I lost the wards you gave me..."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Completion | Done: x
    constant string VL_NAZGREK_0033_KEY = "Nazgrek_0033"
    constant string VL_NAZGREK_0033_TEXT = "Yes, they are on top of the runes you enchanted. While I was placing the wards, there were some sort of cultists at each corrupted tree practicing some sort of dark rituals. I wasted no time, and I decimated them."

    // Excel draft: Nazgrek Lines | Quest: Plaguo Upon Trees | Event: Completion
    constant string VL_NAZGREK_0034_KEY = "Nazgrek_0034"
    constant string VL_NAZGREK_0034_TEXT = "Yeah... I should had interrogated them, but it's too late for that now. Anyways, we will get back on the matter. Farewell for now."

    // Excel draft: Nazgrek Lines | Quest: Unknown Entity | Event: Intro | Done: x
    constant string VL_NAZGREK_0037_KEY = "Nazgrek_0037"
    constant string VL_NAZGREK_0037_TEXT = "Hello, Jin. Why is your fishing pole cracked like that?"
    constant string VL_NAZGREK_0038_KEY = "Nazgrek_0038"
    constant string VL_NAZGREK_0038_TEXT = "Is this supposed to be a joke? Huh? No? Alrighty then. I guess it's just another day at the paradise."

    // Excel draft: Nazgrek Lines | Quest: Unknown Entity | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0040_KEY = "Nazgrek_0040"
    constant string VL_NAZGREK_0040_TEXT = "I will investigate the lake for the unknown entity."

    // Excel draft: Nazgrek Lines | Quest: Unknown Entity | Event: Intro / decline | Done: x
    constant string VL_NAZGREK_0041_KEY = "Nazgrek_0041"
    constant string VL_NAZGREK_0041_TEXT = "You sound like you are tripping on some voodoo stuff again or this is just another fishing tale. I won't bother with such a nonsense."

    // Excel draft: Nazgrek Lines | Quest: Unknown Entity | Event: Completion | Done: x
    constant string VL_NAZGREK_0042_KEY = "Nazgrek_0042"
    constant string VL_NAZGREK_0042_TEXT = "Yes, I found the thing you saw and incinerated it back to void."
    constant string VL_NAZGREK_0043_KEY = "Nazgrek_0043"
    constant string VL_NAZGREK_0043_TEXT = "This slime that I have on my bag pack is the only thing that's left of the thing. Are you interested in... --studying it whether it can be useful for alchemy?"
    constant string VL_NAZGREK_0044_KEY = "Nazgrek_0044"
    constant string VL_NAZGREK_0044_TEXT = "... Pleasure to restore peace... to the fishing spot. See you, Jin'Zun."

    // Excel draft: Nazgrek Lines | Quest: Unknown Entity | Event: Update | Done: x
    constant string VL_NAZGREK_0045_KEY = "Nazgrek_0045"
    constant string VL_NAZGREK_0045_TEXT = "I could try to lure the beast from the depths with a meat lure at the Jin'Zun's fishing spot..."
    constant string VL_NAZGREK_0046_KEY = "Nazgrek_0046"
    constant string VL_NAZGREK_0046_TEXT = "What a disgusting nightmarish creature..."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt / Sargoth Ichor | Event: Intro | Done: x
    constant string VL_NAZGREK_0047_KEY = "Nazgrek_0047"
    constant string VL_NAZGREK_0047_TEXT = "Hello again, Jin'Zun."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt | Event: Intro | Done: x
    constant string VL_NAZGREK_0048_KEY = "Nazgrek_0048"
    constant string VL_NAZGREK_0048_TEXT = "What is it that is lurking in the shadows?"
    constant string VL_NAZGREK_0049_KEY = "Nazgrek_0049"
    constant string VL_NAZGREK_0049_TEXT = "What levels? Ah, okay."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0051_KEY = "Nazgrek_0051"
    constant string VL_NAZGREK_0051_TEXT = "I will venture out and see what I can do."

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt | Event: Intro / decline | Done: x
    constant string VL_NAZGREK_0052_KEY = "Nazgrek_0052"
    constant string VL_NAZGREK_0052_TEXT = "This sounds like risky plan... Sargoth might devour me slowly while I'm hanging in her webs!"

    // Excel draft: Nazgrek Lines | Quest: Sargoth / Spider hunt | Event: Completion | Done: x
    constant string VL_NAZGREK_0053_KEY = "Nazgrek_0053"
    constant string VL_NAZGREK_0053_TEXT = "Here's the ichor, witch doctor! Take it away fast, I don't like the smell of it."
    constant string VL_NAZGREK_0054_KEY = "Nazgrek_0054"
    constant string VL_NAZGREK_0054_TEXT = "Thank you Jin'Zun. I will check the recipe. We'll see again!"

    // Excel draft: Nazgrek Lines | Event: Gnolls attack / Attack begins | Done: x
    constant string VL_NAZGREK_0057_KEY = "Nazgrek_0057"
    constant string VL_NAZGREK_0057_TEXT = "I must aid these warriors, and quickly!!!"

    // Excel draft: Nazgrek Lines | Event: Gnolls attack / Attack ends | Done: x
    constant string VL_NAZGREK_0058_KEY = "Nazgrek_0058"
    constant string VL_NAZGREK_0058_TEXT = "The pleasure was all mine. I only did what I had to."
    constant string VL_NAZGREK_0059_KEY = "Nazgrek_0059"
    constant string VL_NAZGREK_0059_TEXT = "Yes, that is my name. -Well if that was all, I'm continuing my hunt."
    constant string VL_NAZGREK_0060_KEY = "Nazgrek_0060"
    constant string VL_NAZGREK_0060_TEXT = "That sounds troublesome... but go-on."
    constant string VL_NAZGREK_0061_KEY = "Nazgrek_0061"
    constant string VL_NAZGREK_0061_TEXT = "To aid the Horde? I owe no debt for the Horde."
    constant string VL_NAZGREK_0062_KEY = "Nazgrek_0062"
    constant string VL_NAZGREK_0062_TEXT = "I guess the times have finally changed. Give me letter, warrior. I'll decide if I sign it or incinerate it."

    // Excel draft: Nazgrek Lines | Event: Meeting with Thork | Done: x
    constant string VL_NAZGREK_0063_KEY = "Nazgrek_0063"
    constant string VL_NAZGREK_0063_TEXT = "In the end, Grom saved us all. I respected your brother --and I respect you, Hellscream."
    constant string VL_NAZGREK_0064_KEY = "Nazgrek_0064"
    constant string VL_NAZGREK_0064_TEXT = "It's that all? Am I suppose to do your bidding by myself?"

    // Excel draft: Nazgrek Lines | Event: Starting with Zulkis | Done: x
    constant string VL_NAZGREK_0065_KEY = "Nazgrek_0065"
    constant string VL_NAZGREK_0065_TEXT = "I don't know. And I surely don't give a hell about someone's bad day. But, let's see."

    // Excel draft: Nazgrek Lines | Event: Meeting with Thork | Done: x
    constant string VL_NAZGREK_0066_KEY = "Nazgrek_0066"
    constant string VL_NAZGREK_0066_TEXT = "I will join with the Horde once again, but only to make sure that we as Horde stick to the path that is one of honor and glory."
    constant string VL_NAZGREK_0067_KEY = "Nazgrek_0067"
    constant string VL_NAZGREK_0067_TEXT = "Hellscream, you know as well as I do, that those were desperate times. Survival often requires choices we'd rather not make."

    // Excel draft: Nazgrek Lines | Event: Meeting with Thork
    constant string VL_NAZGREK_0068_KEY = "Nazgrek_0068"
    constant string VL_NAZGREK_0068_TEXT = "I will stand with the Horde once more-but not blindly. If I fight beneath its banner, it will be to ensure we walk a path of honor, not one paved with quiet betrayals."
    constant string VL_NAZGREK_0069_KEY = "Nazgrek_0069"
    constant string VL_NAZGREK_0069_TEXT = "Chieftain Thork... those were desperate times, yes. But desperation does not absolve us of what we become in order to survive."

    // Excel draft: Nazgrek Lines | Event: Garthork / First Greet | Done: x
    constant string VL_NAZGREK_0071_KEY = "Nazgrek_0071"
    constant string VL_NAZGREK_0071_TEXT = "N/A"
    constant string VL_NAZGREK_0072_KEY = "Nazgrek_0072"
    constant string VL_NAZGREK_0072_TEXT = "Lok'tar, Garthork! My name is Nazgrek. I walk with the elementals like you do."
    constant string VL_NAZGREK_0073_KEY = "Nazgrek_0073"
    constant string VL_NAZGREK_0073_TEXT = "What is your story Garthork?"
    constant string VL_NAZGREK_0074_KEY = "Nazgrek_0074"
    constant string VL_NAZGREK_0074_TEXT = "Yes... That is correct. Our clan fell under the influence of the demons. I was one of the few who did not drink the cursed blood of Mannoroth. To my knowledge, my clan is now almost eradicated. I don't know about the rest who stayed on Draenor."

    // Excel draft: Nazgrek Lines | Event: Garthork / First Greet
    constant string VL_NAZGREK_0075_KEY = "Nazgrek_0075"
    constant string VL_NAZGREK_0075_TEXT = "N/A"

    // Excel draft: Nazgrek Lines | Event: Garthork / Normal Greet | Done: x
    constant string VL_NAZGREK_0076_KEY = "Nazgrek_0076"
    constant string VL_NAZGREK_0076_TEXT = "Hello Garthork."

    // Excel draft: Nazgrek Lines | Event: Garthork / Farewell | Done: x
    constant string VL_NAZGREK_0077_KEY = "Nazgrek_0077"
    constant string VL_NAZGREK_0077_TEXT = "Dabu, friend. Until we meet again."

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / intro | Done: x
    constant string VL_NAZGREK_0080_KEY = "Nazgrek_0080"
    constant string VL_NAZGREK_0080_TEXT = "What are you talking about? Those fish creatures?"
    constant string VL_NAZGREK_0081_KEY = "Nazgrek_0081"
    constant string VL_NAZGREK_0081_TEXT = "What is this magical power you are telling me?"

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / acceptdecline
    constant string VL_NAZGREK_0082_KEY = "Nazgrek_0082"
    constant string VL_NAZGREK_0082_TEXT = "N/A"

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / accept | Done: x
    constant string VL_NAZGREK_0083_KEY = "Nazgrek_0083"
    constant string VL_NAZGREK_0083_TEXT = "That sounds intriguing... I'll search this... Mur'gal and do as you implied."

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / decline | Done: x
    constant string VL_NAZGREK_0084_KEY = "Nazgrek_0084"
    constant string VL_NAZGREK_0084_TEXT = "I apologize, but the fish creatures do not deserve such havoc upon them. I'll pass on this one."

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / unfinished | Done: x
    constant string VL_NAZGREK_0085_KEY = "Nazgrek_0085"
    constant string VL_NAZGREK_0085_TEXT = "I have not found this Mur'gal yet..."

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / completed
    constant string VL_NAZGREK_0086_KEY = "Nazgrek_0086"
    constant string VL_NAZGREK_0086_TEXT = "N/A"

    // Excel draft: Nazgrek Lines | Event: Garthork / Magical Eye / completed | Done: x
    constant string VL_NAZGREK_0087_KEY = "Nazgrek_0087"
    constant string VL_NAZGREK_0087_TEXT = "Poor murlocs though. I hope the eye will be more useful in death than it was in life."

    // Excel draft: Nazgrek Lines | Event: The Resurgence of The Dead | Done: x
    constant string VL_NAZGREK_0100_KEY = "Nazgrek_0100"
    constant string VL_NAZGREK_0100_TEXT = "Jin'Zun, you're screaming louder than a murloc in heat! What's troubling you this time?"
    constant string VL_NAZGREK_0101_KEY = "Nazgrek_0101"
    constant string VL_NAZGREK_0101_TEXT = "The forest is spreading rumors again, huh? But it seems that those cultists were up to no good, that's for sure."
    constant string VL_NAZGREK_0102_KEY = "Nazgrek_0102"
    constant string VL_NAZGREK_0102_TEXT = "I'm on it. Where can I find this crypt?"
    constant string VL_NAZGREK_0103_KEY = "Nazgrek_0103"
    constant string VL_NAZGREK_0103_TEXT = "Moving body part from a walking corpse?!"
    constant string VL_NAZGREK_0104_KEY = "Nazgrek_0104"
    constant string VL_NAZGREK_0104_TEXT = "Company, you say? Who are you suggesting, Jin'Zun? Maybe that old goblin who sells potions made from who knows what?"
    constant string VL_NAZGREK_0105_KEY = "Nazgrek_0105"
    constant string VL_NAZGREK_0105_TEXT = "To be fair, this matter does not really concern me."
    constant string VL_NAZGREK_0106_KEY = "Nazgrek_0106"
    constant string VL_NAZGREK_0106_TEXT = "Alright, I'll head to the southeast and check out this crypt in the Dead Woods."
    constant string VL_NAZGREK_0107_KEY = "Nazgrek_0107"
    constant string VL_NAZGREK_0107_TEXT = "Garr, you say? I'll be keeping an eye out."
    constant string VL_NAZGREK_0108_KEY = "Nazgrek_0108"
    constant string VL_NAZGREK_0108_TEXT = "Yes, disturbing as hell. Can you examine it?"

    // Excel draft: Nazgrek Lines | Event: The Resurgence of The Dead / PART II | Done: x
    constant string VL_NAZGREK_0115_KEY = "Nazgrek_0115"
    constant string VL_NAZGREK_0115_TEXT = "I'll gather my allies and prepare to face the minions of darkness."
    constant string VL_NAZGREK_0118_KEY = "Nazgrek_0118"
    constant string VL_NAZGREK_0118_TEXT = "A reward? Much appreciated. I'll keep that in mind for future adventures. Thanks, Jin'Zun."

    // Excel draft: Nazgrek Lines | Event: Granis / First Greet | Done: x
    constant string VL_NAZGREK_0130_KEY = "Nazgrek_0130"
    constant string VL_NAZGREK_0130_TEXT = "I was sent by Hellscream."

    // Excel draft: Nazgrek Lines | Event: Granis / Normal Greet | Done: x
    constant string VL_NAZGREK_0135_KEY = "Nazgrek_0135"
    constant string VL_NAZGREK_0135_TEXT = "Lok'tar!"

    // Excel draft: Nazgrek Lines | Event: Granis / Farewell | Done: x
    constant string VL_NAZGREK_0136_KEY = "Nazgrek_0136"
    constant string VL_NAZGREK_0136_TEXT = "Farewell."

    // Excel draft: Nazgrek Lines | Event: Granis / Roljin / accept | Done: x
    constant string VL_NAZGREK_0140_KEY = "Nazgrek_0140"
    constant string VL_NAZGREK_0140_TEXT = "The threat of the forest trolls have indeed become too unpredictable. I will do what I must."
    constant string VL_NAZGREK_0141_KEY = "Nazgrek_0141"
    constant string VL_NAZGREK_0141_TEXT = "I've faced countless dangers before. The trolls won't be an exception."

    // Excel draft: Nazgrek Lines | Event: Granis / Roljin / decline | Done: x
    constant string VL_NAZGREK_0142_KEY = "Nazgrek_0142"
    constant string VL_NAZGREK_0142_TEXT = "I have better things to do."

    // Excel draft: Nazgrek Lines | Event: Granis / Roljin / unfinished | Done: x
    constant string VL_NAZGREK_0143_KEY = "Nazgrek_0143"
    constant string VL_NAZGREK_0143_TEXT = "Rest assured, Rol'jin's days are numbered. I'll have his head soon enough."

    // Excel draft: Nazgrek Lines | Event: Granis / Roljin / completed | Done: x
    constant string VL_NAZGREK_0144_KEY = "Nazgrek_0144"
    constant string VL_NAZGREK_0144_TEXT = "Let the trolls tremble in fear, for their warlord has fallen!"

    // Excel draft: Nazgrek Lines | Event: Defense of Mountain Outpost
    constant string VL_NAZGREK_0153_KEY = "Nazgrek_0153"
    constant string VL_NAZGREK_0153_TEXT = "Count me in. I will lend my strength to the defense."
    constant string VL_NAZGREK_0154_KEY = "Nazgrek_0154"
    constant string VL_NAZGREK_0154_TEXT = "I'm sorry, but I cannot heed your call at this time. I have other matters that require my attention."
    constant string VL_NAZGREK_0163_KEY = "Nazgrek_0163"
    constant string VL_NAZGREK_0163_TEXT = "Though the battle may be won, we must remain vigilant against future threats."
    constant string VL_NAZGREK_0166_KEY = "Nazgrek_0166"
    constant string VL_NAZGREK_0166_TEXT = "The savage gnolls have been defeated. The mountain outpost is secured for now."

    // Excel draft: Nazgrek Lines | Event: Ragno / First Greet
    constant string VL_NAZGREK_0170_KEY = "Nazgrek_0170"
    constant string VL_NAZGREK_0170_TEXT = "Greetings warrior. You must be Ragno?"

    // Excel draft: Nazgrek Lines | Event: Succubus / chains of seduction | Done: x
    constant string VL_NAZGREK_0194_KEY = "Nazgrek_0194"
    constant string VL_NAZGREK_0194_TEXT = "Jin'Zun! Please... help... me. I am under a spell..."

    // Excel draft: Nazgrek Lines | Quest: Oh, sweet adventurer, are you lost in these woods? Or perhaps you've stumbled upon me intentionally, drawn by my irresistible allure. | Event...
    constant string VL_NAZGREK_0196_KEY = "Nazgrek_0196"
    constant string VL_NAZGREK_0196_TEXT = "I... I was just checking... the stone walls."

    // Excel draft: Nazgrek Lines | Quest: Oh, you're a curious one, aren't you? Or perhaps... adventurous? How about we make a deal, darling. | Event: Succubus | Done: x
    constant string VL_NAZGREK_0197_KEY = "Nazgrek_0197"
    constant string VL_NAZGREK_0197_TEXT = "What kind of a deal?"

    // Excel draft: Nazgrek Lines | Quest: Listen closely. I offer you power beyond your wildest dreams, but in return, you must pledge your loyalty to me. Are you willing to make such...
    constant string VL_NAZGREK_0198_KEY = "Nazgrek_0198"
    constant string VL_NAZGREK_0198_TEXT = "I accept your offer."

    // Excel draft: Nazgrek Lines | Quest: You've made your choice, and it's a foolish one. I don't worry, I know you'll come back... | Event: Succubus | Done: x
    constant string VL_NAZGREK_0201_KEY = "Nazgrek_0201"
    constant string VL_NAZGREK_0201_TEXT = "I think I will pass the offer this time."

    // Excel draft: Nazgrek Lines | Quest: Feel the chains of desire binding you to me!!! You will do now as I say. | Event: Succubus | Done: x
    constant string VL_NAZGREK_0202_KEY = "Nazgrek_0202"
    constant string VL_NAZGREK_0202_TEXT = "I am yours to command, oh queen of suffering."

    // Excel draft: Nazgrek Lines | Quest: Your first task is simple yet... delightful. Spread false rumor among your kin. Let the lies weave their web. | Event: Succubus
    constant string VL_NAZGREK_0203_KEY = "Nazgrek_0203"
    constant string VL_NAZGREK_0203_TEXT = "Speak (selec) any Player 6 unit → Nazgrek will tell some false information: I saw Ragno steal some of the gnoll pillage for himself."

    // Excel draft: Nazgrek Lines | Quest: Now let's make the rumor more effective. Steal the pillage and place it in that miserable orc's hut. | Event: Succubus | Done: x
    constant string VL_NAZGREK_0204_KEY = "Nazgrek_0204"
    constant string VL_NAZGREK_0204_TEXT = "Haha! Your plan is excellent, oh queen!"

    // Excel draft: Nazgrek Lines | Quest: This is too boring... Let's spice things up! Eliminate one of your own kind. | Event: Succubus | Done: x
    constant string VL_NAZGREK_0205_KEY = "Nazgrek_0205"
    constant string VL_NAZGREK_0205_TEXT = "They will die!"

    // Excel draft: Nazgrek Lines | Quest: Offer up your very soul to me, and together we shall rule over the realms of desire for eternity. Fear not the darkness, for in death, you sh...
    constant string VL_NAZGREK_0207_KEY = "Nazgrek_0207"
    constant string VL_NAZGREK_0207_TEXT = "I shall embrace... the darkness!"

    // Excel draft: Nazgrek Lines | Quest: Ah, my precious servant, how beautifully you have embraced the abyss. Your sacrifice has pleased me beyond measure. | Event: Succubus | Done: x
    constant string VL_NAZGREK_0208_KEY = "Nazgrek_0208"
    constant string VL_NAZGREK_0208_TEXT = "I serve only you, my queen!"

    // Excel draft: Nazgrek Lines | Quest: I bestow upon you the gift of unfathomable power. Let it fuel your every desire and bind you ever closer to my will. | Event: Succubus
    constant string VL_NAZGREK_0209_KEY = "Nazgrek_0209"
    constant string VL_NAZGREK_0209_TEXT = "What the hell just happened? Was I asleep?"

    // Excel draft: Nazgrek Lines | Quest: Jin'Zun's Fishing Pole | Event: Intro | Done: x
    constant string VL_NAZGREK_0220_KEY = "Nazgrek_0220"
    constant string VL_NAZGREK_0220_TEXT = "Good to see you, old friend. What's going on today?"
    constant string VL_NAZGREK_0222_KEY = "Nazgrek_0222"
    constant string VL_NAZGREK_0222_TEXT = "Satyrs are not to be taken lightly, but something tells me it's the kobolds who took it."

    // Excel draft: Nazgrek Lines | Quest: Jin'Zun's Fishing Pole | Event: Intro / decline | Done: x
    constant string VL_NAZGREK_0224_KEY = "Nazgrek_0224"
    constant string VL_NAZGREK_0224_TEXT = "Maybe another time, Jin'Zun. Gotta keep these hands ready for bigger battles."

    // Excel draft: Nazgrek Lines | Quest: Jin'Zun's Fishing Pole | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0225_KEY = "Nazgrek_0225"
    constant string VL_NAZGREK_0225_TEXT = "If those pests took what's yours, I'll make 'em regret it. Leave it to me!"

    // Excel draft: Nazgrek Lines | Quest: Jin'Zun's Fishing Pole | Event: Unfinished | Done: x
    constant string VL_NAZGREK_0226_KEY = "Nazgrek_0226"
    constant string VL_NAZGREK_0226_TEXT = "Still nothing... but I'll dig deeper. Kobolds are crafty, but I'll get to the bottom of this."

    // Excel draft: Nazgrek Lines | Quest: Jin'Zun's Fishing Pole | Event: Completion | Done: x
    constant string VL_NAZGREK_0227_KEY = "Nazgrek_0227"
    constant string VL_NAZGREK_0227_TEXT = "Jin'Zun! Look what I found! Your fishing pole is back where it belongs."

    // Excel draft: Nazgrek Lines | Quest: Seeds of Life | Event: Intro | Done: x
    constant string VL_NAZGREK_0230_KEY = "Nazgrek_0230"
    constant string VL_NAZGREK_0230_TEXT = "Jin'Zun, it's good to see ya again."
    constant string VL_NAZGREK_0232_KEY = "Nazgrek_0232"
    constant string VL_NAZGREK_0232_TEXT = "Hmmm... is there anything we can do?"
    constant string VL_NAZGREK_0234_KEY = "Nazgrek_0234"
    constant string VL_NAZGREK_0234_TEXT = "Sounds like just what we need."

    // Excel draft: Nazgrek Lines | Quest: Seeds of Life | Event: Intro / decline | Done: x
    constant string VL_NAZGREK_0236_KEY = "Nazgrek_0236"
    constant string VL_NAZGREK_0236_TEXT = "I'm afraid I can't right now."

    // Excel draft: Nazgrek Lines | Quest: Seeds of Life | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0237_KEY = "Nazgrek_0237"
    constant string VL_NAZGREK_0237_TEXT = "Of course, I'm on it. Give me those seeds."

    // Excel draft: Nazgrek Lines | Quest: Seeds of Life | Event: Unfinished | Done: x
    constant string VL_NAZGREK_0239_KEY = "Nazgrek_0239"
    constant string VL_NAZGREK_0239_TEXT = "You are right, I'll try move faster."

    // Excel draft: Nazgrek Lines | Quest: Intro | Done: x
    constant string VL_NAZGREK_0250_KEY = "Nazgrek_0250"
    constant string VL_NAZGREK_0250_TEXT = "Easy now, Shadowclaw."
    constant string VL_NAZGREK_0251_KEY = "Nazgrek_0251"
    constant string VL_NAZGREK_0251_TEXT = "We don't need to bother with them."
    constant string VL_NAZGREK_0252_KEY = "Nazgrek_0252"
    constant string VL_NAZGREK_0252_TEXT = "The rabbit hunt was a success, my old friend."
    constant string VL_NAZGREK_0253_KEY = "Nazgrek_0253"
    constant string VL_NAZGREK_0253_TEXT = "I am not so hungry right now, you can have it."
    constant string VL_NAZGREK_0254_KEY = "Nazgrek_0254"
    constant string VL_NAZGREK_0254_TEXT = "I sense something is amiss, but the spirits don't neither tell or show it fully. It's too much... discord."
    constant string VL_NAZGREK_0255_KEY = "Nazgrek_0255"
    constant string VL_NAZGREK_0255_TEXT = "I feel like I should start gathering ingredients to create a special flask."

    // Excel draft: Nazgrek Lines | Done: x
    constant string VL_NAZGREK_0256_KEY = "Nazgrek_0256"
    constant string VL_NAZGREK_0256_TEXT = "After I drink the flask, it should momentarily enhance my insight and make me stronger to prepare myself for what is yet to come..."

    // Excel draft: Nazgrek Lines | Quest: Explosive Crisis | Event: First time greet | Done: x
    constant string VL_NAZGREK_0260_KEY = "Nazgrek_0260"
    constant string VL_NAZGREK_0260_TEXT = "I seek no claim, goblins. I'm just looking around."

    // Excel draft: Nazgrek Lines | Quest: Explosive Crisis | Event: Intro / accept | Done: x
    constant string VL_NAZGREK_0262_KEY = "Nazgrek_0262"
    constant string VL_NAZGREK_0262_TEXT = "I'll find your barrels. If they explode on me, I'm sending the pieces back one at a time"

    // Excel draft: Nazgrek Lines | Quest: Explosive Crisis | Event: Completion | Done: x
    constant string VL_NAZGREK_0264_KEY = "Nazgrek_0264"
    constant string VL_NAZGREK_0264_TEXT = "I found your barrels. Don't let anyone steal them this time."

    // Excel draft: Nazgrek Lines | Quest: Boomsite Compliance Inspection
    constant string VL_NAZGREK_0265_KEY = "Nazgrek_0265"
    constant string VL_NAZGREK_0265_TEXT = "Let me guess. I'm now your certified log-hauler?"
    constant string VL_NAZGREK_0266_KEY = "Nazgrek_0266"
    constant string VL_NAZGREK_0266_TEXT = "Every time I help you goblins, I get roped into more work."
    constant string VL_NAZGREK_0267_KEY = "Nazgrek_0267"
    constant string VL_NAZGREK_0267_TEXT = "Got it."

    // Excel draft: Nazgrek Lines | Quest: Boomsite Compliance Inspection | Done: x
    constant string VL_NAZGREK_0269_KEY = "Nazgrek_0269"
    constant string VL_NAZGREK_0269_TEXT = "I don't want to know what that even means."
    constant string VL_NAZGREK_0270_KEY = "Nazgrek_0270"
    constant string VL_NAZGREK_0270_TEXT = "These logs should fulfill the requirements of your standards."

    // Excel draft: Nazgrek Lines | Quest: Dust Isn't Just Dirt - It's Combustible Culture | Done: x
    constant string VL_NAZGREK_0271_KEY = "Nazgrek_0271"
    constant string VL_NAZGREK_0271_TEXT = "You mean... sweeping?"
    constant string VL_NAZGREK_0272_KEY = "Nazgrek_0272"
    constant string VL_NAZGREK_0272_TEXT = "Of course. Can't blow things up 'til we've vacuumed the cave."

    // Excel draft: Nazgrek Lines | Quest: Mandatory Training | Done: x
    constant string VL_NAZGREK_0275_KEY = "Nazgrek_0275"
    constant string VL_NAZGREK_0275_TEXT = "What the hell we are supposed to do there? Those kobolds surely won't make the camp safer..."
    constant string VL_NAZGREK_0276_KEY = "Nazgrek_0276"
    constant string VL_NAZGREK_0276_TEXT = "Feels like nonsense. But fine. One last trip."
    constant string VL_NAZGREK_0277_KEY = "Nazgrek_0277"
    constant string VL_NAZGREK_0277_TEXT = "I couldn't agree more, let's go back."
    constant string VL_NAZGREK_0278_KEY = "Nazgrek_0278"
    constant string VL_NAZGREK_0278_TEXT = "I knew I smelled rat grease and betrayal!"

    // Excel draft: Nazgrek Lines | Quest: Boom Will Be Back | Event: Intro | Done: x
    constant string VL_NAZGREK_0282_KEY = "Nazgrek_0282"
    constant string VL_NAZGREK_0282_TEXT = "He played you like fools! I should've known..."
    constant string VL_NAZGREK_0283_KEY = "Nazgrek_0283"
    constant string VL_NAZGREK_0283_TEXT = "Blix picked the wrong orc to mess with."

    // Excel draft: Nazgrek Lines | Quest: Boom Will Be Back | Event: Completion | Done: x
    constant string VL_NAZGREK_0284_KEY = "Nazgrek_0284"
    constant string VL_NAZGREK_0284_TEXT = "Mad Blix is down. The mine is yours again and this time you may blast as you like."
    constant string VL_NAZGREK_0285_KEY = "Nazgrek_0285"
    constant string VL_NAZGREK_0285_TEXT = "Heh. I bet Mr. Explosive Risk Assessor Blix didn't assess that risk."

    // Excel draft: Nazgrek Lines | Quest: Be quiet you fool! We're trying to hunt dragons here! | Done: x
    constant string VL_NAZGREK_0288_KEY = "Nazgrek_0288"
    constant string VL_NAZGREK_0288_TEXT = "What are you hunters up to?"

    // Excel draft: Nazgrek Lines | Quest: You look like you have some fight in you, but do you have the courage to face a dragon's brood? | Event: Whelps of Destruction | Done: x
    constant string VL_NAZGREK_0290_KEY = "Nazgrek_0290"
    constant string VL_NAZGREK_0290_TEXT = "I do not rely purely on steel, for my powers comes from the skies."

    // Excel draft: Nazgrek Lines | Quest: I need a warrior with the guts to take them down before they become a real threat. | Event: Whelps of Destruction | Done: x
    constant string VL_NAZGREK_0292_KEY = "Nazgrek_0292"
    constant string VL_NAZGREK_0292_TEXT = "I can handle the dragon whelps."

    // Excel draft: Nazgrek Lines | Quest: Bring me the eggs you find, preferably unhatched. | Event: Dragon Egg Hunt | Done: x
    constant string VL_NAZGREK_0303_KEY = "Nazgrek_0303"
    constant string VL_NAZGREK_0303_TEXT = "Why wouldn't you just destroy the eggs?"

    // Excel draft: Nazgrek Lines | Quest: I hope you didn't alert the mother dragon... | Event: Dragon Egg Hunt | Done: x
    constant string VL_NAZGREK_0307_KEY = "Nazgrek_0307"
    constant string VL_NAZGREK_0307_TEXT = "What are you going to do with the eggs?"

    // Excel draft: Nazgrek Lines | Quest: You've struck down the drakes with your eyebrowns still intact. Grum honors your acts. | Event: Drake Hunt | Done: x
    constant string VL_NAZGREK_0316_KEY = "Nazgrek_0316"
    constant string VL_NAZGREK_0316_TEXT = "I've slain the drakes."

    // Excel draft: Nazgrek Lines | Quest: Few who face him live to speak of it. But if you are the warrior you claim to be, you will slay him. | Event: Desolator | Done: x
    constant string VL_NAZGREK_0323_KEY = "Nazgrek_0323"
    constant string VL_NAZGREK_0323_TEXT = "I've heard about Mordrax, she is very powerful dragon. It will not be an easy fight..."

    // Excel draft: Nazgrek Lines | Quest: The great dragon Mordrax is dead, and his shadow lifts from the Highlands. | Event: Desolator | Done: x
    constant string VL_NAZGREK_0327_KEY = "Nazgrek_0327"
    constant string VL_NAZGREK_0327_TEXT = "Here is the scale of mighty Mordrax."

    // qAradion first greet and lore questions.
    constant string VL_NAZGREK_0331_KEY = "Nazgrek_0331"
    constant string VL_NAZGREK_0331_TEXT = "Your blood is not what I seek, elf. I walk the spirit path, not the path of slaughter."
    constant string VL_NAZGREK_0332_KEY = "Nazgrek_0332"
    constant string VL_NAZGREK_0332_TEXT = "You said... a witch deceived you?"
    constant string VL_NAZGREK_0333_KEY = "Nazgrek_0333"
    constant string VL_NAZGREK_0333_TEXT = "Why did your kin trust this witch?"
    constant string VL_NAZGREK_0334_KEY = "Nazgrek_0334"
    constant string VL_NAZGREK_0334_TEXT = "The wraiths I see... they were once elves?"

    // Excel draft: Nazgrek Lines | Quest: First time greet | Event: Aradion The Farseer | Done: x
    constant string VL_NAZGREK_0335_KEY = "Nazgrek_0335"
    constant string VL_NAZGREK_0335_TEXT = "What binds them still to this world?"

    // qAradion first greet and lore follow-up.
    constant string VL_NAZGREK_0336_KEY = "Nazgrek_0336"
    constant string VL_NAZGREK_0336_TEXT = "And you? How did you resist where others fell?"
    constant string VL_NAZGREK_0337_KEY = "Nazgrek_0337"
    constant string VL_NAZGREK_0337_TEXT = "I'll see if I come across her."

    // qAradion Quest 1: Valeria encounter and negotiation.
    constant string VL_NAZGREK_0340_KEY = "Nazgrek_0340"
    constant string VL_NAZGREK_0340_TEXT = "You must be Valeria."
    constant string VL_NAZGREK_0341_KEY = "Nazgrek_0341"
    constant string VL_NAZGREK_0341_TEXT = "I am not your enemy..."
    constant string VL_NAZGREK_0344_KEY = "Nazgrek_0344"
    constant string VL_NAZGREK_0344_TEXT = "You are outmatched. Stand aside, or fall."
    constant string VL_NAZGREK_0345_KEY = "Nazgrek_0345"
    constant string VL_NAZGREK_0345_TEXT = "You have no right to stand in my way."
    constant string VL_NAZGREK_0346_KEY = "Nazgrek_0346"
    constant string VL_NAZGREK_0346_TEXT = "Enough! I'll make you listen by force."
    constant string VL_NAZGREK_0347_KEY = "Nazgrek_0347"
    constant string VL_NAZGREK_0347_TEXT = "I'm not like the other orcs."
    constant string VL_NAZGREK_0348_KEY = "Nazgrek_0348"
    constant string VL_NAZGREK_0348_TEXT = "You're wasting both our time. Stand down."
    constant string VL_NAZGREK_0349_KEY = "Nazgrek_0349"
    constant string VL_NAZGREK_0349_TEXT = "I'm just passing by."
    constant string VL_NAZGREK_0350_KEY = "Nazgrek_0350"
    constant string VL_NAZGREK_0350_TEXT = "I'll show you the power of the Earth Mother!"
    constant string VL_NAZGREK_0351_KEY = "Nazgrek_0351"
    constant string VL_NAZGREK_0351_TEXT = "I am not your enemy!"
    constant string VL_NAZGREK_0352_KEY = "Nazgrek_0352"
    constant string VL_NAZGREK_0352_TEXT = "I will not harm you."
    constant string VL_NAZGREK_0353_KEY = "Nazgrek_0353"
    constant string VL_NAZGREK_0353_TEXT = "I've spoken with Aradion. He told me to find you."

    // Excel draft: Nazgrek Lines | Quest: A Token of Love | Event: Intro | Done: x
    constant string VL_NAZGREK_0355_KEY = "Nazgrek_0355"
    constant string VL_NAZGREK_0355_TEXT = "I understand why you are cautious."
    constant string VL_NAZGREK_0356_KEY = "Nazgrek_0356"
    constant string VL_NAZGREK_0356_TEXT = "Orcs are not known for being friendly..."
    constant string VL_NAZGREK_0358_KEY = "Nazgrek_0358"
    constant string VL_NAZGREK_0358_TEXT = "I will return it safely to your hands."

    // Excel draft: Nazgrek Lines | Quest: A Token of Love | Event: Completion | Done: x
    constant string VL_NAZGREK_0361_KEY = "Nazgrek_0361"
    constant string VL_NAZGREK_0361_TEXT = "I've found your necklace."

    // qAradion Quest 2: crystal shards.
    constant string VL_NAZGREK_0366_KEY = "Nazgrek_0366"
    constant string VL_NAZGREK_0366_TEXT = "I have walked near them. Their song is some what… twisted, yet beautiful."
    constant string VL_NAZGREK_0367_KEY = "Nazgrek_0367"
    constant string VL_NAZGREK_0367_TEXT = "I can hear the spirits whisper caution. These crystals may feed hunger, not heal it."

    // Excel draft: Nazgrek Lines | Quest: Fading Sparks | Event: Intro | Done: x
    constant string VL_NAZGREK_0370_KEY = "Nazgrek_0370"
    constant string VL_NAZGREK_0370_TEXT = "I'm not so sure about this..."

    // qAradion Quest 3: fading sparks.
    constant string VL_NAZGREK_0371_KEY = "Nazgrek_0371"
    constant string VL_NAZGREK_0371_TEXT = "I will do this Aradion, but I see little hope in the shadows."
    constant string VL_NAZGREK_0372_KEY = "Nazgrek_0372"
    constant string VL_NAZGREK_0372_TEXT = "Do not surrender to despair, Aradion. There may yet be an answer to all of it."

    // Excel draft: Nazgrek Lines | Quest: Lost Supplies | Event: Intro | Done: x
    constant string VL_NAZGREK_0375_KEY = "Nazgrek_0375"
    constant string VL_NAZGREK_0375_TEXT = "I will try to see what I can find from the ruins."

    // qAradion Quest 4: rift sealing.
    constant string VL_NAZGREK_0377_KEY = "Nazgrek_0377"
    constant string VL_NAZGREK_0377_TEXT = "The spirits whisper of broken currents here. I will see Valeria through this."
    constant string VL_NAZGREK_0378_KEY = "Nazgrek_0378"
    constant string VL_NAZGREK_0378_TEXT = "The wound in the land is remedied… for now."

    // Excel draft: Nazgrek Lines | Quest: Concerned Observations / Remarks | Done: x
    constant string VL_NAZGREK_0381_KEY = "Nazgrek_0381"
    constant string VL_NAZGREK_0381_TEXT = "Are you alright?"
    constant string VL_NAZGREK_0382_KEY = "Nazgrek_0382"
    constant string VL_NAZGREK_0382_TEXT = "Something stirs in him... I feel it in the air."
    constant string VL_NAZGREK_0383_KEY = "Nazgrek_0383"
    constant string VL_NAZGREK_0383_TEXT = "Valeria, I am not certain how to say this... but watch him closely."
    constant string VL_NAZGREK_0384_KEY = "Nazgrek_0384"
    constant string VL_NAZGREK_0384_TEXT = "This place seems to have tendency to take a grip of even the kindest people..."
endglobals

private function RegisterGenericQuestLines takes nothing returns nothing
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0001_TEXT, 1)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0002_TEXT, 2)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0003_TEXT, 3)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ACCEPT, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0004_TEXT, 4)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0005_TEXT, 5)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0006_TEXT, 6)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0007_TEXT, 7)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_KILL, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0008_TEXT, 8)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0009_TEXT, 9)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0010_TEXT, 10)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0011_TEXT, 11)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_TALK, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0012_TEXT, 12)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0013_TEXT, 13)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0014_TEXT, 14)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0015_TEXT, 15)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_COMPLETE_FETCH, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0016_TEXT, 16)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0017_TEXT, 17)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0018_TEXT, 18)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0019_TEXT, 19)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_PROGRESS, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0020_TEXT, 20)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0021_TEXT, 21)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0022_TEXT, 22)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0023_TEXT, 23)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_REQUEST_SUPPLY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0024_TEXT, 24)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0025_TEXT, 25)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0026_TEXT, 26)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0027_TEXT, 27)
    call QuestsGeneric_RegisterHeroVoiceVariant(QuestsGeneric_HERO_LINE_ASK_TO_BUY, VL_NAZGREK_GENERIC_TYPE, VL_NAZGREK_GENERIC_0028_TEXT, 28)
endfunction

private function Init takes nothing returns nothing
    call ExSound_RegisterSequence(VL_NAZGREK_GENERIC_TYPE, 1, 28, "Pots\\Sound\\Voicelines\\Nazgrek\\NazgrekGeneric\\")
    call RegisterGenericQuestLines()
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0331_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0332_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0333_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0334_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0336_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0337_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0340_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0341_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0344_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0345_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0346_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0347_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0348_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0349_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0350_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0351_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0352_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0353_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0366_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0367_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0371_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0372_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0377_KEY)
    call Voicelines_RegisterKey(VL_NAZGREK_FOLDER, VL_NAZGREK_0378_KEY)
endfunction

endlibrary
