/**
    VoicelinesSerenthia

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
    Global `VL_SERENTHIA_*` constants.

**/
library VoicelinesSerenthia requires Voicelines

globals
    constant string VL_SERENTHIA_FOLDER = "Serenthia"

    // Legacy Excel draft/reference rows.

    // Excel draft: Serenthia | Event: Normal Greet
    constant string VL_SERENTHIA_0001_KEY = "Serenthia_0001"
    constant string VL_SERENTHIA_0001_TEXT = "Ah... the shaman walks the threads of fate again. Tell me, orc - do you dream of light, or only the shadows that follow it?"
    constant string VL_SERENTHIA_0002_KEY = "Serenthia_0002"
    constant string VL_SERENTHIA_0002_TEXT = "You return. How curious. Few who've seen the veil between worlds ever come back willingly."
    constant string VL_SERENTHIA_0003_KEY = "Serenthia_0003"
    constant string VL_SERENTHIA_0003_TEXT = "The Vale whispers of you, Nazgrek. Even the dead are learning your name.\""

    // Excel draft: Serenthia | Event: Goodbye
    constant string VL_SERENTHIA_0004_KEY = "Serenthia_0004"
    constant string VL_SERENTHIA_0004_TEXT = "The world has more questions than I have patience."
    constant string VL_SERENTHIA_0005_KEY = "Serenthia_0005"
    constant string VL_SERENTHIA_0005_TEXT = "We all have parts to play, shaman. Try not to forget yours."
    constant string VL_SERENTHIA_0006_KEY = "Serenthia_0006"
    constant string VL_SERENTHIA_0006_TEXT = "Do not stray too far - even fate finds comfort in familiar company."

    // Excel draft: Serenthia | Event: XXX reserve
    constant string VL_SERENTHIA_0007_KEY = "Serenthia_0007"
    constant string VL_SERENTHIA_0007_TEXT = "You came, as I knew you would. Even distrust bends to necessity."
    constant string VL_SERENTHIA_0008_KEY = "Serenthia_0008"
    constant string VL_SERENTHIA_0008_TEXT = "Your spirit hums with conflict, Nazgrek. Let me still it - if only for a while."
    constant string VL_SERENTHIA_0009_KEY = "Serenthia_0009"
    constant string VL_SERENTHIA_0009_TEXT = "I see the doubt in your eyes. Good. Doubt is the first step toward truth."
    constant string VL_SERENTHIA_0010_KEY = "Serenthia_0010"
    constant string VL_SERENTHIA_0010_TEXT = "Ah, the shaman who saw beneath the mask. Tell me - do you miss the illusion?"
    constant string VL_SERENTHIA_0011_KEY = "Serenthia_0011"
    constant string VL_SERENTHIA_0011_TEXT = "You look upon me with fear now. Yet it was your trust that made me real."
    constant string VL_SERENTHIA_0012_KEY = "Serenthia_0012"
    constant string VL_SERENTHIA_0012_TEXT = "There's no need for hatred, Nazgrek. I am merely what the elves made me."
    constant string VL_SERENTHIA_0013_KEY = "Serenthia_0013"
    constant string VL_SERENTHIA_0013_TEXT = "So you return, little flame - ready to burn what you cannot understand?"

    // Excel draft: Serenthia
    constant string VL_SERENTHIA_0014_KEY = "Serenthia_0014"
    constant string VL_SERENTHIA_0014_TEXT = "Hatred suits you poorly, shaman. It clouds that clever mind of yours."
    constant string VL_SERENTHIA_0015_KEY = "Serenthia_0015"
    constant string VL_SERENTHIA_0015_TEXT = "When you strike me down, remember - your victory was written by the Void."
    constant string VL_SERENTHIA_0016_KEY = "Serenthia_0016"
    constant string VL_SERENTHIA_0016_TEXT = "There you are, my brave shaman. The world will curse your name... but I shall not."
    constant string VL_SERENTHIA_0017_KEY = "Serenthia_0017"
    constant string VL_SERENTHIA_0017_TEXT = "Together, we will weave a new pattern from the ashes. Let the elves mourn their past."
    constant string VL_SERENTHIA_0018_KEY = "Serenthia_0018"
    constant string VL_SERENTHIA_0018_TEXT = "You've stepped beyond salvation now. But oh... what wonders await us."
    constant string VL_SERENTHIA_0019_KEY = "Serenthia_0019"
    constant string VL_SERENTHIA_0019_TEXT = "The threads tighten, and yet - you still resist the pull. Admirable."
    constant string VL_SERENTHIA_0020_KEY = "Serenthia_0020"
    constant string VL_SERENTHIA_0020_TEXT = "Even in silence, the rift remembers us. Do you?"
    constant string VL_SERENTHIA_0021_KEY = "Serenthia_0021"
    constant string VL_SERENTHIA_0021_TEXT = "Every choice you make hums through the ley-lines. Can you hear it - the song of consequence?"
    constant string VL_SERENTHIA_0022_KEY = "Serenthia_0022"
    constant string VL_SERENTHIA_0022_TEXT = "Your eyes carry more light now... or is it just the reflection of what you've lost?"
    constant string VL_SERENTHIA_0023_KEY = "Serenthia_0023"
    constant string VL_SERENTHIA_0023_TEXT = "When all this ends, perhaps you'll finally understand - I never lied. I only showed you truth."
    constant string VL_SERENTHIA_0024_KEY = "Serenthia_0024"
    constant string VL_SERENTHIA_0024_TEXT = "One day, Nazgrek, you will thank me... though I doubt it will be in this lifetime."
    constant string VL_SERENTHIA_0025_KEY = "Serenthia_0025"
    constant string VL_SERENTHIA_0025_TEXT = "Ah... mortals, always chasing what they cannot touch."
    constant string VL_SERENTHIA_0026_KEY = "Serenthia_0026"
    constant string VL_SERENTHIA_0026_TEXT = "So fragile, the line between hunger and power... and yet so deliciously thin."
    constant string VL_SERENTHIA_0027_KEY = "Serenthia_0027"
    constant string VL_SERENTHIA_0027_TEXT = "Even the shadows obey me... but I grow tired of their obedience."
    constant string VL_SERENTHIA_0028_KEY = "Serenthia_0028"
    constant string VL_SERENTHIA_0028_TEXT = "Do you feel it, shaman? The world is listening... and it speaks in riddles."
    constant string VL_SERENTHIA_0029_KEY = "Serenthia_0029"
    constant string VL_SERENTHIA_0029_TEXT = "You draw near... how curious. Do you seek answers, or merely admire the illusion?"

    // Excel draft: Serenthia | Quest: The Witch's Smile | Event: First Encounter
    constant string VL_SERENTHIA_0033_KEY = "Serenthia_0033"
    constant string VL_SERENTHIA_0033_TEXT = "So... this is where the whispers lead. A witch cloaked in moonlight."
    constant string VL_SERENTHIA_0034_KEY = "Serenthia_0034"
    constant string VL_SERENTHIA_0034_TEXT = "The air bends around ye, like the world itself fears to touch."
    constant string VL_SERENTHIA_0035_KEY = "Serenthia_0035"
    constant string VL_SERENTHIA_0035_TEXT = "Lady Serenthis... or should I call ye by another name?"
    constant string VL_SERENTHIA_0036_KEY = "Serenthia_0036"
    constant string VL_SERENTHIA_0036_TEXT = "Names are fragile things, shaman. Speak one too often, and it loses its meaning."
    constant string VL_SERENTHIA_0037_KEY = "Serenthia_0037"
    constant string VL_SERENTHIA_0037_TEXT = "You are far from your kin, yet closer to truth than most. Tell me - do you seek wisdom... or absolution?"
    constant string VL_SERENTHIA_0038_KEY = "Serenthia_0038"
    constant string VL_SERENTHIA_0038_TEXT = "Do not fear the stillness. It is only the world remembering what it once was."
    constant string VL_SERENTHIA_0039_KEY = "Serenthia_0039"
    constant string VL_SERENTHIA_0039_TEXT = "Ye talk like the dead, but your eyes burn with hunger. What are ye, witch?"
    constant string VL_SERENTHIA_0040_KEY = "Serenthia_0040"
    constant string VL_SERENTHIA_0040_TEXT = "I came for answers, not riddles. Speak plain - what did you do to this place?"
    constant string VL_SERENTHIA_0041_KEY = "Serenthia_0041"
    constant string VL_SERENTHIA_0041_TEXT = "The spirits scream your name, yet ye stand calm. Why?"

    // Excel draft: Serenthia | Event: First Encounter
    constant string VL_SERENTHIA_0042_KEY = "Serenthia_0042"
    constant string VL_SERENTHIA_0042_TEXT = "Because they remember me. Once, I was their guide. Their savior."

    // Excel draft: Serenthia
    constant string VL_SERENTHIA_0043_KEY = "Serenthia_0043"
    constant string VL_SERENTHIA_0043_TEXT = "Elarindor fell not by my hand, but by their thirst - the same hunger that burns within your kind."
    constant string VL_SERENTHIA_0044_KEY = "Serenthia_0044"
    constant string VL_SERENTHIA_0044_TEXT = "You smell of mana and sorrow, shaman. I could teach you to master both."
    constant string VL_SERENTHIA_0045_KEY = "Serenthia_0045"
    constant string VL_SERENTHIA_0045_TEXT = "Yer smile hides venom, witch. I'll not be so easily swayed."
    constant string VL_SERENTHIA_0046_KEY = "Serenthia_0046"
    constant string VL_SERENTHIA_0046_TEXT = "Keep yer promises - I'll see truth with my own eyes, not through yours."
    constant string VL_SERENTHIA_0047_KEY = "Serenthia_0047"
    constant string VL_SERENTHIA_0047_TEXT = "Aradion must hear of this. Whatever ye are, ye ain't done with the Vale yet."

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Intro
    constant string VL_SERENTHIA_0052_KEY = "Serenthia_0052"
    constant string VL_SERENTHIA_0052_TEXT = "This place remembers what the elves have forgotten... the song of balance, broken by their own thirst."
    constant string VL_SERENTHIA_0053_KEY = "Serenthia_0053"
    constant string VL_SERENTHIA_0053_TEXT = "If I can reach the heart of the rift, I may yet weave its silence into harmony again."
    constant string VL_SERENTHIA_0054_KEY = "Serenthia_0054"
    constant string VL_SERENTHIA_0054_TEXT = "But we closed the rifts."

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Intro Scene - At the inactive rift
    constant string VL_SERENTHIA_0057_KEY = "Serenthia_0057"
    constant string VL_SERENTHIA_0057_TEXT = "Stand ready, shaman. The veil between hunger and healing is thin."
    constant string VL_SERENTHIA_0058_KEY = "Serenthia_0058"
    constant string VL_SERENTHIA_0058_TEXT = "Thin veils rip easy, witch. Tell me again - ye sure this will heal, not harm?"
    constant string VL_SERENTHIA_0059_KEY = "Serenthia_0059"
    constant string VL_SERENTHIA_0059_TEXT = "Trust is a fragile thing, Nazgrek. Hold yours, just a little longer."

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: During the Ritual (preparation and energy build-up)
    constant string VL_SERENTHIA_0060_KEY = "Serenthia_0060"
    constant string VL_SERENTHIA_0060_TEXT = "The pools of wisdom! I can feel them stirring beneath the stone!"
    constant string VL_SERENTHIA_0061_KEY = "Serenthia_0061"
    constant string VL_SERENTHIA_0061_TEXT = "Keep the spirits from me. If I falter, all our efforts are for nothing!"
    constant string VL_SERENTHIA_0062_KEY = "Serenthia_0062"
    constant string VL_SERENTHIA_0062_TEXT = "The air's twisting! Something dark stirs in the flow - what are ye callin', witch?"
    constant string VL_SERENTHIA_0063_KEY = "Serenthia_0063"
    constant string VL_SERENTHIA_0063_TEXT = "Not calling... revealing. The truth beneath the calm. Hold fast!"

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Corruption Surges - The rift destabilizes
    constant string VL_SERENTHIA_0064_KEY = "Serenthia_0064"
    constant string VL_SERENTHIA_0064_TEXT = "No... this power is not mine to command!"
    constant string VL_SERENTHIA_0065_KEY = "Serenthia_0065"
    constant string VL_SERENTHIA_0065_TEXT = "Something else sleeps beneath the Vale - something ancient... watching!"
    constant string VL_SERENTHIA_0066_KEY = "Serenthia_0066"
    constant string VL_SERENTHIA_0066_TEXT = "By the spirits- ye've torn it open again! Stop the ritual!"
    constant string VL_SERENTHIA_0067_KEY = "Serenthia_0067"
    constant string VL_SERENTHIA_0067_TEXT = "It's too late! The rift answers only to the Void now!"

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Void Entity Emerges - Her Illusion Flickers
    constant string VL_SERENTHIA_0068_KEY = "Serenthia_0068"
    constant string VL_SERENTHIA_0068_TEXT = "What trickery is this!? Yer face- it's changin'!"
    constant string VL_SERENTHIA_0069_KEY = "Serenthia_0069"
    constant string VL_SERENTHIA_0069_TEXT = "Ah... so you finally see me. The mask was only for your comfort."
    constant string VL_SERENTHIA_0070_KEY = "Serenthia_0070"
    constant string VL_SERENTHIA_0070_TEXT = "Did you truly think salvation would come without a price?"
    constant string VL_SERENTHIA_0071_KEY = "Serenthia_0071"
    constant string VL_SERENTHIA_0071_TEXT = "Ye lied to us all! The elves trusted ye - and I was fool enough to guard ye!"
    constant string VL_SERENTHIA_0072_KEY = "Serenthia_0072"
    constant string VL_SERENTHIA_0072_TEXT = "Lied? No, shaman. I merely promised hope. The meaning was yours to imagine"

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Rift Fully Opens - The Void Entity appears
    constant string VL_SERENTHIA_0073_KEY = "Serenthia_0073"
    constant string VL_SERENTHIA_0073_TEXT = "Beautiful, isn't it? A world unmade, pure of false light..."
    constant string VL_SERENTHIA_0074_KEY = "Serenthia_0074"
    constant string VL_SERENTHIA_0074_TEXT = "\"I... apologize for the inconvenience. Truly."
    constant string VL_SERENTHIA_0075_KEY = "Serenthia_0075"
    constant string VL_SERENTHIA_0075_TEXT = "Witch! Ye unleashed somethin' ye can't control!"
    constant string VL_SERENTHIA_0076_KEY = "Serenthia_0076"
    constant string VL_SERENTHIA_0076_TEXT = "Control? No, Nazgrek. Freedom. And now, you'll learn what the elves once did - the price of touching eternity."

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Departure (Serenthis teleports away)
    constant string VL_SERENTHIA_0077_KEY = "Serenthia_0077"
    constant string VL_SERENTHIA_0077_TEXT = "Farewell, shaman. Should you survive... perhaps then, we shall speak as equals."
    constant string VL_SERENTHIA_0078_KEY = "Serenthia_0078"
    constant string VL_SERENTHIA_0078_TEXT = "Coward! Ye can't just- Spirits damn it, she's gone!"
    constant string VL_SERENTHIA_0079_KEY = "Serenthia_0079"
    constant string VL_SERENTHIA_0079_TEXT = "So be it. If she birthed this horror, I'll be the one to end it!"

    // Excel draft: Serenthia | Quest: Ritual of Cleansing | Event: Aftermath (Post-fight or transition to "Mysteries of the Void")
    constant string VL_SERENTHIA_0080_KEY = "Serenthia_0080"
    constant string VL_SERENTHIA_0080_TEXT = "The Vale bleeds again... and the witch's promise turned to ash."
    constant string VL_SERENTHIA_0081_KEY = "Serenthia_0081"
    constant string VL_SERENTHIA_0081_TEXT = "I'll not let her curse devour what's left o' this land. Not while I still draw breath"

    // Excel draft: Serenthia | Quest: The Black Veil's Bargain | Event: Intro
    constant string VL_SERENTHIA_0088_KEY = "Serenthia_0088"
    constant string VL_SERENTHIA_0088_TEXT = "Ah... the little saviors of the dying race."
    constant string VL_SERENTHIA_0089_KEY = "Serenthia_0089"
    constant string VL_SERENTHIA_0089_TEXT = "Aradion still clings to hope? How delicious."
    constant string VL_SERENTHIA_0090_KEY = "Serenthia_0090"
    constant string VL_SERENTHIA_0090_TEXT = "But perhaps you, orc, have teeth enough to bite what the elves cannot."

    // Excel draft: Serenthia | Quest: The Black Veil's Bargain | Event: Intro | Comment: Nazgrek: "Your words smell of poison, witch. But I'll hear your terms.
    constant string VL_SERENTHIA_0091_KEY = "Serenthia_0091"
    constant string VL_SERENTHIA_0091_TEXT = "Help me, and I might just help them. Or not."

    // Excel draft: Serenthia | Quest: The Black Veil's Bargain | Event: Unfinished
    constant string VL_SERENTHIA_0092_KEY = "Serenthia_0092"
    constant string VL_SERENTHIA_0092_TEXT = "Still pondering, are you? Mortals are such slow thinkers."

    // Excel draft: Serenthia | Quest: The Black Veil's Bargain | Event: Completion
    constant string VL_SERENTHIA_0094_KEY = "Serenthia_0094"
    constant string VL_SERENTHIA_0094_TEXT = "So you do have some wit. How refreshing."
    constant string VL_SERENTHIA_0095_KEY = "Serenthia_0095"
    constant string VL_SERENTHIA_0095_TEXT = "We'll see if your actions match your courage, green one."

    // Excel draft: Serenthia | Quest: Ritual of Cleaning | Event: Intro
    constant string VL_SERENTHIA_0101_KEY = "Serenthia_0101"
    constant string VL_SERENTHIA_0101_TEXT = "We dance close to salvation, my sweet fool."
    constant string VL_SERENTHIA_0102_KEY = "Serenthia_0102"
    constant string VL_SERENTHIA_0102_TEXT = "Escort me to the rift, and perhaps I shall gift you redemption."

    // Excel draft: Serenthia | Quest: Ritual of Cleaning | Event: Intro | Comment: Nazgrek: "I've walked beside worse monsters... I think.
    constant string VL_SERENTHIA_0103_KEY = "Serenthia_0103"
    constant string VL_SERENTHIA_0103_TEXT = "Don't worry - I only bite when the moon's right."

    // Excel draft: Serenthia | Quest: Ritual of Cleaning | Event: Unfinished
    constant string VL_SERENTHIA_0104_KEY = "Serenthia_0104"
    constant string VL_SERENTHIA_0104_TEXT = "Patience, dear. Rituals require rhythm - and sacrifice."
    constant string VL_SERENTHIA_0105_KEY = "Serenthia_0105"
    constant string VL_SERENTHIA_0105_TEXT = "The rift calls, and yet you dawdle."

    // Excel draft: Serenthia | Event: Completion
    constant string VL_SERENTHIA_0106_KEY = "Serenthia_0106"
    constant string VL_SERENTHIA_0106_TEXT = "Oh... oops. Did I do that?"
    constant string VL_SERENTHIA_0107_KEY = "Serenthia_0107"
    constant string VL_SERENTHIA_0107_TEXT = "The Void says hello! My true face, dears - try not to scream."
    constant string VL_SERENTHIA_0108_KEY = "Serenthia_0108"
    constant string VL_SERENTHIA_0108_TEXT = "Farewell! I've enjoyed our little tragedy."
endglobals

endlibrary
