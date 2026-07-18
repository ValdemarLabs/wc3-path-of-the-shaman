/**
    VoicelinesAradion

    Author: Valdemar
    Version:

    Description:
    Speaker-owned voiceline keys and text constants migrated from active
    qAradion dialog usage and AI profile barks. Active quest lines are
    registered here; the AI profile range is covered by ExSound sequence registration.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx
    - QuestsAndDialogs/QuestGivers/qAradion.j
    - AI/Specific/AI_Aradion.j

    How to install:
    Import after `Voicelines.j`. Consumers require this library directly.

    API:
    Global `VL_ARADION_####_KEY` and `VL_ARADION_####_TEXT` constants.

**/
library VoicelinesAradion initializer Init requires Voicelines

globals
    constant string VL_ARADION_FOLDER = "AradionFarseer"

    // qAradion first greet and Elarindor history.
    constant string VL_ARADION_0001_KEY = "Aradion_0001"
    constant string VL_ARADION_0001_TEXT = "An… orc? Here? If you came for blood, take mine swiftly. I will not flee…"
    constant string VL_ARADION_0002_KEY = "Aradion_0002"
    constant string VL_ARADION_0002_TEXT = "…No. Orcs do not speak so. You… are different."
    constant string VL_ARADION_0003_KEY = "Aradion_0003"
    constant string VL_ARADION_0003_TEXT = "I see the truth in your eyes. You do not come as foe, but as seeker. Then hear me, shaman, and know the ruin of my people."
    constant string VL_ARADION_0004_KEY = "Aradion_0004"
    constant string VL_ARADION_0004_TEXT = "This was once our home - Elarindor. Jewel of Vanguard Vale. A city that shone like a beacon from the light of the arcane energies."
    constant string VL_ARADION_0005_KEY = "Aradion_0005"
    constant string VL_ARADION_0005_TEXT = "Then she came... A magister called Lady Serenthia. Cloaked in grace and wisdom, she whispered promises of eternal prosperity. Many of my people heeded her call..."
    constant string VL_ARADION_0006_KEY = "Aradion_0006"
    constant string VL_ARADION_0006_TEXT = "But all she was - was a lie. Her beauty and voice, the elven form were mere illusion. In truth, she was the witch Zerathis."
    constant string VL_ARADION_0007_KEY = "Aradion_0007"
    constant string VL_ARADION_0007_TEXT = "My beloved Valeria and I begged our kin to turn away... but what are two voices against the choir of greed?"
    constant string VL_ARADION_0008_KEY = "Aradion_0008"
    constant string VL_ARADION_0008_TEXT = "Her words promised glory - strength to rival Quel'Thalas itself. Her lies were sweet... and my people were starving for more."
    constant string VL_ARADION_0009_KEY = "Aradion_0009"
    constant string VL_ARADION_0009_TEXT = "But every promise was poison. Each draught of her 'gift' deepened the hunger, until the hunger itself consumed them."
    constant string VL_ARADION_0010_KEY = "Aradion_0010"
    constant string VL_ARADION_0010_TEXT = "Now my people are twisted, their flesh withering, their souls bleeding into wraiths. Soon... nothing of them will remain."
    constant string VL_ARADION_0011_KEY = "Aradion_0011"
    constant string VL_ARADION_0011_TEXT = "Yes. Once mothers, fathers, children. Now only hollow echoes bound to the Void by the magic that devoured them."
    constant string VL_ARADION_0012_KEY = "Aradion_0012"
    constant string VL_ARADION_0012_TEXT = "The wretched who remain will share the same fate - it is only a matter of time before they too dissolve into wraiths."
    constant string VL_ARADION_0013_KEY = "Aradion_0013"
    constant string VL_ARADION_0013_TEXT = "I resisted... because I feared. And because Valeria feared with me. Together we begged them to turn away. None listened."
    constant string VL_ARADION_0014_KEY = "Aradion_0014"
    constant string VL_ARADION_0014_TEXT = "The witch saw no worth in those who refused her. So she left us alive - to watch the slow death of our kin."
    constant string VL_ARADION_0015_KEY = "Aradion_0015"
    constant string VL_ARADION_0015_TEXT = "I have searched, shaman... searched for a cure, an answer, any salvation. But all I have found is despair."
    constant string VL_ARADION_0016_KEY = "Aradion_0016"
    constant string VL_ARADION_0016_TEXT = "Yet perhaps the spirits you serve have sent you here, to answer the question I cannot solve alone."

    // Farewell and normal greet lines.
    constant string VL_ARADION_0017_KEY = "Aradion_0017"
    constant string VL_ARADION_0017_TEXT = "Go then, shaman. May the spirits shield you."
    constant string VL_ARADION_0018_KEY = "Aradion_0018"
    constant string VL_ARADION_0018_TEXT = "May your path carry more hope than mine."
    constant string VL_ARADION_0019_KEY = "Aradion_0019"
    constant string VL_ARADION_0019_TEXT = "I hope our paths cross again."
    constant string VL_ARADION_0020_KEY = "Aradion_0020"
    constant string VL_ARADION_0020_TEXT = "I did not expect company in these ruins."
    constant string VL_ARADION_0021_KEY = "Aradion_0021"
    constant string VL_ARADION_0021_TEXT = "Yes, shaman?"
    constant string VL_ARADION_0022_KEY = "Aradion_0022"
    constant string VL_ARADION_0022_TEXT = "Hm? Ah, it's you."
    constant string VL_ARADION_0023_KEY = "Aradion_0023"
    constant string VL_ARADION_0023_TEXT = "Have you seen Valeria?"
    constant string VL_ARADION_0024_KEY = "Aradion_0024"
    constant string VL_ARADION_0024_TEXT = "She is always on the run..."

    // Quest 1: Valeria rescue and reunion.
    constant string VL_ARADION_0031_KEY = "Aradion_0031"
    constant string VL_ARADION_0031_TEXT = "Valeria? By the stars… you yet live!"
    constant string VL_ARADION_0032_KEY = "Aradion_0032"
    constant string VL_ARADION_0032_TEXT = "I feared that I had lost you… forgive me for losing hope."
    constant string VL_ARADION_0033_KEY = "Aradion_0033"
    constant string VL_ARADION_0033_TEXT = "Then I was right. You are no foe, but a seeker."
    constant string VL_ARADION_0034_KEY = "Aradion_0034"
    constant string VL_ARADION_0034_TEXT = "You have given me back my heart, shaman. For this… I owe you more than I can say."
    constant string VL_ARADION_0035_KEY = "Aradion_0035"
    constant string VL_ARADION_0035_TEXT = "In the chaos, when the wraiths struck, my beloved Valeria was torn from my side."
    constant string VL_ARADION_0036_KEY = "Aradion_0036"
    constant string VL_ARADION_0036_TEXT = "I have searched, but the shadows grow thick. If she still lives and you find her, bring her to me, shaman… before they claim her as well."
    constant string VL_ARADION_0037_KEY = "Aradion_0037"
    constant string VL_ARADION_0037_TEXT = "Valeria is still missing... Tell me you have found her?"
    constant string VL_ARADION_0038_KEY = "Aradion_0038"
    constant string VL_ARADION_0038_TEXT = "More and more wraiths are circling around Elarindor... please, do not let her be lost to them."

    // Quest 2: crystal shards.
    constant string VL_ARADION_0041_KEY = "Aradion_0041"
    constant string VL_ARADION_0041_TEXT = "In the ruins of Elarindor, there are crystals… pulsing, alive with energy."
    constant string VL_ARADION_0042_KEY = "Aradion_0042"
    constant string VL_ARADION_0042_TEXT = "I believe they are remnants of our ancient magical pools, fractured when our people consumed too much magical energies."
    constant string VL_ARADION_0043_KEY = "Aradion_0043"
    constant string VL_ARADION_0043_TEXT = "If their power can be harnessed, perhaps… perhaps they may quiet the hunger, even if only for a time."
    constant string VL_ARADION_0044_KEY = "Aradion_0044"
    constant string VL_ARADION_0044_TEXT = "Bring me shards of these crystals, shaman. Let us not forsake even the faintest hope."
    constant string VL_ARADION_0045_KEY = "Aradion_0045"
    constant string VL_ARADION_0045_TEXT = "Have you managed to obtain any crystal shards?"
    constant string VL_ARADION_0046_KEY = "Aradion_0046"
    constant string VL_ARADION_0046_TEXT = "Without those shards, the hope slips further from our grasp."
    constant string VL_ARADION_0047_KEY = "Aradion_0047"
    constant string VL_ARADION_0047_TEXT = "Yes… these shards still resonate with power, I can feel it... It is almost... mesmerizing."
    constant string VL_ARADION_0048_KEY = "Aradion_0048"
    constant string VL_ARADION_0048_TEXT = "If we can bend the crystals energy to our control, it might reverse the damage of the wretched elves decay… Or only soothe for a fleeting moment.…"
    constant string VL_ARADION_0049_KEY = "Aradion_0049"
    constant string VL_ARADION_0049_TEXT = "Yet the pulse of these crystals seems odd... As if the crystals themselves cry out in pain."
    constant string VL_ARADION_0050_KEY = "Aradion_0050"
    constant string VL_ARADION_0050_TEXT = "I must study these shards you brought me… very carefully"

    // Quest 3: fading sparks.
    constant string VL_ARADION_0053_KEY = "Aradion_0053"
    constant string VL_ARADION_0053_TEXT = "The mana wraiths are what remain when the hunger wins."
    constant string VL_ARADION_0054_KEY = "Aradion_0054"
    constant string VL_ARADION_0054_TEXT = "Yet even in their twisted forms, I sense a faint light — echoes of the elves they once were."
    constant string VL_ARADION_0055_KEY = "Aradion_0055"
    constant string VL_ARADION_0055_TEXT = "If we can gather those sparks, perhaps they hold some secret… some key we have overlooked."
    constant string VL_ARADION_0056_KEY = "Aradion_0056"
    constant string VL_ARADION_0056_TEXT = "Bring me their essences, shaman. Let us see if even wraiths may whisper truth."
    constant string VL_ARADION_0057_KEY = "Aradion_0057"
    constant string VL_ARADION_0057_TEXT = "Our people's shades still drift through the Vale. You must claim their sparks..."
    constant string VL_ARADION_0058_KEY = "Aradion_0058"
    constant string VL_ARADION_0058_TEXT = "Do not let their torment go to waste. Bring me what little endures."
    constant string VL_ARADION_0060_KEY = "Aradion_0060"
    constant string VL_ARADION_0060_TEXT = "So fragile… yet for a moment, I can feel all the memories.... everything they once were…"
    constant string VL_ARADION_0061_KEY = "Aradion_0061"
    constant string VL_ARADION_0061_TEXT = "But it all slips away, fading faster than breath. They are too far gone."
    constant string VL_ARADION_0062_KEY = "Aradion_0062"
    constant string VL_ARADION_0062_TEXT = "…If even wraiths leave behind only ashes of the soul, then perhaps our people's fate is truly sealed... "
    constant string VL_ARADION_0063_KEY = "Aradion_0063"
    constant string VL_ARADION_0063_TEXT = "I'll give you the rod of Tel'anor which can be used to safely extract the essence of mana wraith when it is weakened enough."

    // Quest 4: rift sealing.
    constant string VL_ARADION_0065_KEY = "Aradion_0065"
    constant string VL_ARADION_0065_TEXT = "The ancient pools of magic around the Vanguard Vale and Elarindor once flowed pure, binding our people to life and light."
    constant string VL_ARADION_0066_KEY = "Aradion_0066"
    constant string VL_ARADION_0066_TEXT = "Now they are transformed.... distorted by implosion of the mana hunger.... And in those rift-like pools, the wraiths are born anew."
    constant string VL_ARADION_0067_KEY = "Aradion_0067"
    constant string VL_ARADION_0067_TEXT = "Valeria and I will attempt to seal these rifts. It is perilous work, and we don't truly know what we are dealing with. I've begin to think that I should do this alone…"
    constant string VL_ARADION_0068_KEY = "Aradion_0068"
    constant string VL_ARADION_0068_TEXT = "Stand with us, shaman. Guard me while I close the rifts — and strike down whatever nightmares the rifts unleash."
    constant string VL_ARADION_0069_KEY = "Aradion_0069"
    constant string VL_ARADION_0069_TEXT = "The rifts are still open. If they are not sealed, the Vale will never heal."
    constant string VL_ARADION_0070_KEY = "Aradion_0070"
    constant string VL_ARADION_0070_TEXT = "Hold the line! Protect Valeria -- protect us both, shaman!"
    constant string VL_ARADION_0071_KEY = "Aradion_0071"
    constant string VL_ARADION_0071_TEXT = "The rifts… are sealed. For the first time in years, the air feels lighter in the Vale."
    constant string VL_ARADION_0072_KEY = "Aradion_0072"
    constant string VL_ARADION_0072_TEXT = "You stood unbroken, my dear friend. Hope stirs again — faint, but alive."
    constant string VL_ARADION_0073_KEY = "Aradion_0073"
    constant string VL_ARADION_0073_TEXT = "Thank you, shaman. You have given us more than victory — you have given us belief."

    // Rift ritual barks, return-home variants, and failure lines.
    constant string VL_ARADION_0074_KEY = "Aradion_0074"
    constant string VL_ARADION_0074_TEXT = "Stand ready Nazgrek. Once I begin, this place can start to crawl with wraiths."
    constant string VL_ARADION_0075_KEY = "Aradion_0075"
    constant string VL_ARADION_0075_TEXT = "I will attempt to close this rift. But I cannot fight and focus at once... you must protect me!"
    constant string VL_ARADION_0076_KEY = "Aradion_0076"
    constant string VL_ARADION_0076_TEXT = "Hold them back! Just a little longer!"
    constant string VL_ARADION_0077_KEY = "Aradion_0077"
    constant string VL_ARADION_0077_TEXT = "The rift is still open - I need more time!"
    constant string VL_ARADION_0078_KEY = "Aradion_0078"
    constant string VL_ARADION_0078_TEXT = "Try to keep them away from me!"
    constant string VL_ARADION_0079_KEY = "Aradion_0079"
    constant string VL_ARADION_0079_TEXT = "Valeria!"
    constant string VL_ARADION_0080_KEY = "Aradion_0080"
    constant string VL_ARADION_0080_TEXT = "It is done. This rift is sealed."
    constant string VL_ARADION_0082_KEY = "Aradion_0082"
    constant string VL_ARADION_0082_TEXT = "I managed to close this rift."
    constant string VL_ARADION_0083_KEY = "Aradion_0083"
    constant string VL_ARADION_0083_TEXT = "Let's head to the next one. Be on your guard."
    constant string VL_ARADION_0084_KEY = "Aradion_0084"
    constant string VL_ARADION_0084_TEXT = "The last rift is sealed. Escort us back to our place."
    constant string VL_ARADION_0084_TEXT_ALT1 = "I think this was the last of them. All rifts should now be closed."
    constant string VL_ARADION_0085_KEY = "Aradion_0085"
    constant string VL_ARADION_0085_TEXT = "We should return to our place before we speak further."
    constant string VL_ARADION_0085_TEXT_ALT1 = "In time, we will see... It's time to head back to our place."
    constant string VL_ARADION_0086_KEY = "Aradion_0086"
    constant string VL_ARADION_0086_TEXT = "The current was... too strong... I..."

    // Legacy Excel draft/reference rows not yet wired to active code.

    // Excel draft: Aradion Lines | Event: Friendly Greet | Done: x
    constant string VL_ARADION_0025_KEY = "Aradion_0025"
    constant string VL_ARADION_0025_TEXT = "It eases me to see you again, shaman."
    constant string VL_ARADION_0026_KEY = "Aradion_0026"
    constant string VL_ARADION_0026_TEXT = "Your steps bring solace to this broken place."
    constant string VL_ARADION_0027_KEY = "Aradion_0027"
    constant string VL_ARADION_0027_TEXT = "Strange... I never thought I would trust an orc, yet here we stand."
    constant string VL_ARADION_0028_KEY = "Aradion_0028"
    constant string VL_ARADION_0028_TEXT = "Nazgrek, the spirits must walk closely with you. You are most welcomed visitor."

    // Excel draft: Aradion Lines | Quest: Fading Sparks | Event: Completion | Done: x
    constant string VL_ARADION_0059_KEY = "Aradion_0059"
    constant string VL_ARADION_0059_TEXT = "These essences... they flicker like dying stars."

    // Excel draft: Aradion Lines | Quest: Rifts of Corruption | Event: Start | Done: x
    constant string VL_ARADION_0081_KEY = "Aradion_0081"
    constant string VL_ARADION_0081_TEXT = "Let's go and search one of those rifts."

    // Excel draft: Aradion Lines | Quest: The Witch's Smile | Event: Intro
    constant string VL_ARADION_0087_KEY = "Aradion_0087"
    constant string VL_ARADION_0087_TEXT = "Find her, Nazgrek. If she is friend, we may yet learn salvation... if foe, we must know her before she knows us."
    constant string VL_ARADION_0087_TEXT_ALT1 = "Every step must be careful... she is patient, and her deception knows no bounds."

    // Excel draft: Aradion Lines | Quest: The Witch's Smile | Event: Unfinished
    constant string VL_ARADION_0088_KEY = "Aradion_0088"
    constant string VL_ARADION_0088_TEXT = "Have you found the witch yet?"
    constant string VL_ARADION_0089_KEY = "Aradion_0089"
    constant string VL_ARADION_0089_TEXT = "We cannot fight what we do not understand. Find the witch."

    // Excel draft: Aradion Lines | Quest: The Witch's Smile | Event: Completion
    constant string VL_ARADION_0090_KEY = "Aradion_0090"
    constant string VL_ARADION_0090_TEXT = "So... she lives. Then the whispers were true."
    constant string VL_ARADION_0091_KEY = "Aradion_0091"
    constant string VL_ARADION_0091_TEXT = "Her charm veils corruption - I can feel it gnawing at the edges of my mind."
    constant string VL_ARADION_0092_KEY = "Aradion_0092"
    constant string VL_ARADION_0092_TEXT = "You have done well. If she is what I fear... this meeting will mark the turning of our fate."

    // Excel draft: Aradion Lines | Event: Intro
    constant string VL_ARADION_0094_KEY = "Aradion_0094"
    constant string VL_ARADION_0094_TEXT = "I searched for hope, shaman, but hope has fled these halls. Still... if you would walk beside me, perhaps together we might find what remains"
    constant string VL_ARADION_0095_KEY = "Aradion_0095"
    constant string VL_ARADION_0095_TEXT = "The witch's trail leads north into the Verdant Plain. She holds the answers I could never seize."
    constant string VL_ARADION_0096_KEY = "Aradion_0096"
    constant string VL_ARADION_0096_TEXT = "Seek her. Demand the cure she promised my people. If it exists, you may yet save them."
    constant string VL_ARADION_0097_KEY = "Aradion_0097"
    constant string VL_ARADION_0097_TEXT = "If it does not... then we must face a darker truth."

    // Excel draft: Aradion Lines | Event: Unfinished
    constant string VL_ARADION_0098_KEY = "Aradion_0098"
    constant string VL_ARADION_0098_TEXT = "The lies of the witch still bind my people."
    constant string VL_ARADION_0099_KEY = "Aradion_0099"
    constant string VL_ARADION_0099_TEXT = "Do not falter, shaman. My people's time runs short - every breath draws them closer to wraithdom."

    // AI profile bark lines.
    // AI profile greet barks.
    constant string VL_ARADION_0181_KEY = "Aradion_0181"
    constant string VL_ARADION_0181_TEXT = "Greetings! I am magister Aradion, but they also call me as the Farseer."
    constant string VL_ARADION_0182_KEY = "Aradion_0182"
    constant string VL_ARADION_0182_TEXT = "Welcome, traveler. Please forgive the tension in this place."
    constant string VL_ARADION_0183_KEY = "Aradion_0183"
    constant string VL_ARADION_0183_TEXT = "Come gently. Nowadays, the Elarindor startles one easily."
    constant string VL_ARADION_0184_KEY = "Aradion_0184"
    constant string VL_ARADION_0184_TEXT = "It is good to see a familiar face in Elarindor."
    constant string VL_ARADION_0185_KEY = "Aradion_0185"
    constant string VL_ARADION_0185_TEXT = "Ah, you return."
    constant string VL_ARADION_0186_KEY = "Aradion_0186"
    constant string VL_ARADION_0186_TEXT = "You are most welcome here."
    constant string VL_ARADION_0187_KEY = "Aradion_0187"
    constant string VL_ARADION_0187_TEXT = "Friend, your presence steadies more than my wards."
    constant string VL_ARADION_0188_KEY = "Aradion_0188"
    constant string VL_ARADION_0188_TEXT = "Elarindor knows you now, and so do I."
    constant string VL_ARADION_0189_KEY = "Aradion_0189"
    constant string VL_ARADION_0189_TEXT = "Valeria trusts you more than she likes to admit."
    constant string VL_ARADION_0190_KEY = "Aradion_0190"
    constant string VL_ARADION_0190_TEXT = "My friend, Elarindor still stands because you refused to abandon it."
    constant string VL_ARADION_0191_KEY = "Aradion_0191"
    constant string VL_ARADION_0191_TEXT = "You bring hope with you. I had almost forgotten the feeling of it..."
    constant string VL_ARADION_0192_KEY = "Aradion_0192"
    constant string VL_ARADION_0192_TEXT = "Come, dear friend. The Vale feels lighter when you are near."

    // AI profile farewell barks.
    constant string VL_ARADION_0193_KEY = "Aradion_0193"
    constant string VL_ARADION_0193_TEXT = "Go carefully. I don't want to lose possible ally."
    constant string VL_ARADION_0194_KEY = "Aradion_0194"
    constant string VL_ARADION_0194_TEXT = "May your path avoid the hungrier shadows."
    constant string VL_ARADION_0195_KEY = "Aradion_0195"
    constant string VL_ARADION_0195_TEXT = "Leave with caution. The void can temp you."
    constant string VL_ARADION_0196_KEY = "Aradion_0196"
    constant string VL_ARADION_0196_TEXT = "May your path find kinder answers than mine."
    constant string VL_ARADION_0197_KEY = "Aradion_0197"
    constant string VL_ARADION_0197_TEXT = "Travel safely. Hope is fragile here."
    constant string VL_ARADION_0198_KEY = "Aradion_0198"
    constant string VL_ARADION_0198_TEXT = "I hope our paths cross again."
    constant string VL_ARADION_0199_KEY = "Aradion_0199"
    constant string VL_ARADION_0199_TEXT = "Elarindor is safer for every step you take."
    constant string VL_ARADION_0200_KEY = "Aradion_0200"
    constant string VL_ARADION_0200_TEXT = "Go with my gratitude, and Valeria's watch."
    constant string VL_ARADION_0201_KEY = "Aradion_0201"
    constant string VL_ARADION_0201_TEXT = "Return when you can. We will be here."
    constant string VL_ARADION_0202_KEY = "Aradion_0202"
    constant string VL_ARADION_0202_TEXT = "Return safely. Valeria and I will keep a light for you."
    constant string VL_ARADION_0203_KEY = "Aradion_0203"
    constant string VL_ARADION_0203_TEXT = "May the Vale itself guard your road."
    constant string VL_ARADION_0204_KEY = "Aradion_0204"
    constant string VL_ARADION_0204_TEXT = "Farewell, my friend. Come back to visit us soon."

    // AI profile passive barks.
    constant string VL_ARADION_0205_KEY = "Aradion_0205"
    constant string VL_ARADION_0205_TEXT = "I will conserve what strength remains to me."
    constant string VL_ARADION_0206_KEY = "Aradion_0206"
    constant string VL_ARADION_0206_TEXT = "Let us avoid waste. Elarindor has endured enough."
    constant string VL_ARADION_0207_KEY = "Aradion_0207"
    constant string VL_ARADION_0207_TEXT = "I prefer not to stir more ghosts."
    constant string VL_ARADION_0208_KEY = "Aradion_0208"
    constant string VL_ARADION_0208_TEXT = "Peace gives old wounds a moment to close."
    constant string VL_ARADION_0209_KEY = "Aradion_0209"
    constant string VL_ARADION_0209_TEXT = "Restraint may serve us better than fire."
    constant string VL_ARADION_0210_KEY = "Aradion_0210"
    constant string VL_ARADION_0210_TEXT = "I can hold my spell, if you can hold the line."
    constant string VL_ARADION_0211_KEY = "Aradion_0211"
    constant string VL_ARADION_0211_TEXT = "Let restraint be our proof that we are not lost."
    constant string VL_ARADION_0212_KEY = "Aradion_0212"
    constant string VL_ARADION_0212_TEXT = "Good. We protect what remains."
    constant string VL_ARADION_0213_KEY = "Aradion_0213"
    constant string VL_ARADION_0213_TEXT = "Mercy is harder than magic, and more needed."
    constant string VL_ARADION_0214_KEY = "Aradion_0214"
    constant string VL_ARADION_0214_TEXT = "Peace suits the Vale better than fear."
    constant string VL_ARADION_0215_KEY = "Aradion_0215"
    constant string VL_ARADION_0215_TEXT = "If you choose mercy, I will stand by it."
    constant string VL_ARADION_0216_KEY = "Aradion_0216"
    constant string VL_ARADION_0216_TEXT = "The old wards rest easier when blades stay low."

    // AI profile normal barks.
    constant string VL_ARADION_0217_KEY = "Aradion_0217"
    constant string VL_ARADION_0217_TEXT = "Let us proceed carefully. These ruins punish certainty."
    constant string VL_ARADION_0218_KEY = "Aradion_0218"
    constant string VL_ARADION_0218_TEXT = "Step softly. Broken magic loves careless feet."
    constant string VL_ARADION_0219_KEY = "Aradion_0219"
    constant string VL_ARADION_0219_TEXT = "I will follow your command."
    constant string VL_ARADION_0220_KEY = "Aradion_0220"
    constant string VL_ARADION_0220_TEXT = "There is still work before despair earns its rest."
    constant string VL_ARADION_0221_KEY = "Aradion_0221"
    constant string VL_ARADION_0221_TEXT = "Keep steady. Panic feeds this place."
    constant string VL_ARADION_0222_KEY = "Aradion_0222"
    constant string VL_ARADION_0222_TEXT = "I can guide us past the worst of the old currents."
    constant string VL_ARADION_0223_KEY = "Aradion_0223"
    constant string VL_ARADION_0223_TEXT = "Together, perhaps we can solve these problems."
    constant string VL_ARADION_0224_KEY = "Aradion_0224"
    constant string VL_ARADION_0224_TEXT = "Your courage gives shape to my plans."
    constant string VL_ARADION_0225_KEY = "Aradion_0225"
    constant string VL_ARADION_0225_TEXT = "Let us move before doubt finds me again."
    constant string VL_ARADION_0226_KEY = "Aradion_0226"
    constant string VL_ARADION_0226_TEXT = "Lead on. My counsel and my magic are yours."
    constant string VL_ARADION_0227_KEY = "Aradion_0227"
    constant string VL_ARADION_0227_TEXT = "With you ahead, even failure feels less certain."
    constant string VL_ARADION_0228_KEY = "Aradion_0228"
    constant string VL_ARADION_0228_TEXT = "The Vale has waited long enough. Let us continue."

    // AI profile aggressive barks.
    constant string VL_ARADION_0229_KEY = "Aradion_0229"
    constant string VL_ARADION_0229_TEXT = "If battle is forced on us, so shall it be."
    constant string VL_ARADION_0230_KEY = "Aradion_0230"
    constant string VL_ARADION_0230_TEXT = "I will help, though I wish we had more time."
    constant string VL_ARADION_0231_KEY = "Aradion_0231"
    constant string VL_ARADION_0231_TEXT = "Very well."
    constant string VL_ARADION_0232_KEY = "Aradion_0232"
    constant string VL_ARADION_0232_TEXT = "Stand with me!"
    constant string VL_ARADION_0233_KEY = "Aradion_0233"
    constant string VL_ARADION_0233_TEXT = "My magic may falter, but not my intent."
    constant string VL_ARADION_0234_KEY = "Aradion_0234"
    constant string VL_ARADION_0234_TEXT = "Let us end this before fear spreads."
    constant string VL_ARADION_0235_KEY = "Aradion_0235"
    constant string VL_ARADION_0235_TEXT = "For the Vale, and for the lives I failed to protect."
    constant string VL_ARADION_0236_KEY = "Aradion_0236"
    constant string VL_ARADION_0236_TEXT = "Old power, answer a better purpose."
    constant string VL_ARADION_0237_KEY = "Aradion_0237"
    constant string VL_ARADION_0237_TEXT = "We fight so Elarindor may breathe again."
    constant string VL_ARADION_0238_KEY = "Aradion_0238"
    constant string VL_ARADION_0238_TEXT = "Let Elarindor remember courage today."
    constant string VL_ARADION_0239_KEY = "Aradion_0239"
    constant string VL_ARADION_0239_TEXT = "No more stolen futures."
    constant string VL_ARADION_0240_KEY = "Aradion_0240"
    constant string VL_ARADION_0240_TEXT = "For every soul the Void has claimed!"

    // AI profile hold-position barks.
    constant string VL_ARADION_0241_KEY = "Aradion_0241"
    constant string VL_ARADION_0241_TEXT = "I can hold this warded ground."
    constant string VL_ARADION_0242_KEY = "Aradion_0242"
    constant string VL_ARADION_0242_TEXT = "If my calculations hold, so will this place."
    constant string VL_ARADION_0243_KEY = "Aradion_0243"
    constant string VL_ARADION_0243_TEXT = "I will keep the ward steady. Mostly steady."
    constant string VL_ARADION_0244_KEY = "Aradion_0244"
    constant string VL_ARADION_0244_TEXT = "This circle should hold if I do not miscalculate."
    constant string VL_ARADION_0245_KEY = "Aradion_0245"
    constant string VL_ARADION_0245_TEXT = "I will anchor here. Try not to make me improvise."
    constant string VL_ARADION_0246_KEY = "Aradion_0246"
    constant string VL_ARADION_0246_TEXT = "This ground remembers old protections."
    constant string VL_ARADION_0247_KEY = "Aradion_0247"
    constant string VL_ARADION_0247_TEXT = "I will anchor the ward. Trust the line."
    constant string VL_ARADION_0248_KEY = "Aradion_0248"
    constant string VL_ARADION_0248_TEXT = "Go. I can hold this point."
    constant string VL_ARADION_0249_KEY = "Aradion_0249"
    constant string VL_ARADION_0249_TEXT = "My wards are stronger with allies nearby."
    constant string VL_ARADION_0250_KEY = "Aradion_0250"
    constant string VL_ARADION_0250_TEXT = "I will hold this ground as if it were the heart of the Vale."
    constant string VL_ARADION_0251_KEY = "Aradion_0251"
    constant string VL_ARADION_0251_TEXT = "Nothing breaks this circle while I draw breath."
    constant string VL_ARADION_0252_KEY = "Aradion_0252"
    constant string VL_ARADION_0252_TEXT = "Trust me here. I will not fail you."

    // AI profile kicked barks.
    constant string VL_ARADION_0253_KEY = "Aradion_0253"
    constant string VL_ARADION_0253_TEXT = "Then I return to my studies."
    constant string VL_ARADION_0254_KEY = "Aradion_0254"
    constant string VL_ARADION_0254_TEXT = "Very well. I have notes enough to keep me occupied."
    constant string VL_ARADION_0255_KEY = "Aradion_0255"
    constant string VL_ARADION_0255_TEXT = "Perhaps distance is wise for now."
    constant string VL_ARADION_0256_KEY = "Aradion_0256"
    constant string VL_ARADION_0256_TEXT = "I will wait with Valeria. She worries better than I do."
    constant string VL_ARADION_0257_KEY = "Aradion_0257"
    constant string VL_ARADION_0257_TEXT = "Call if you need counsel, or a flawed spell."
    constant string VL_ARADION_0258_KEY = "Aradion_0258"
    constant string VL_ARADION_0258_TEXT = "Go carefully. I will remain near the wards."
    constant string VL_ARADION_0259_KEY = "Aradion_0259"
    constant string VL_ARADION_0259_TEXT = "Go on. I will keep the researching."
    constant string VL_ARADION_0260_KEY = "Aradion_0260"
    constant string VL_ARADION_0260_TEXT = "You know where to find us."
    constant string VL_ARADION_0261_KEY = "Aradion_0261"
    constant string VL_ARADION_0261_TEXT = "I will be ready when you needs us again, my friend."
    constant string VL_ARADION_0262_KEY = "Aradion_0262"
    constant string VL_ARADION_0262_TEXT = "I understand. Our bond does not need orders."
    constant string VL_ARADION_0263_KEY = "Aradion_0263"
    constant string VL_ARADION_0263_TEXT = "Take care, my friend. Valeria and I will be here."
    constant string VL_ARADION_0264_KEY = "Aradion_0264"
    constant string VL_ARADION_0264_TEXT = "Send word, and I will come as quickly as I can."

    // AI profile idle barks.
    constant string VL_ARADION_0265_KEY = "Aradion_0265"
    constant string VL_ARADION_0265_TEXT = "A failed magister can still read the shape of a disaster."
    constant string VL_ARADION_0266_KEY = "Aradion_0266"
    constant string VL_ARADION_0266_TEXT = "The arcane energies hum everywhere around this corner of the world."
    constant string VL_ARADION_0267_KEY = "Aradion_0267"
    constant string VL_ARADION_0267_TEXT = "I mistook caution for cowardice once. The cost taught me otherwise."
    constant string VL_ARADION_0268_KEY = "Aradion_0268"
    constant string VL_ARADION_0268_TEXT = "Perhaps it's not too late to save the Elarindor."
    constant string VL_ARADION_0269_KEY = "Aradion_0269"
    constant string VL_ARADION_0269_TEXT = "Wisdom came too late to save Elarindor. I keep it anyway."
    constant string VL_ARADION_0270_KEY = "Aradion_0270"
    constant string VL_ARADION_0270_TEXT = "Valeria kept her aim steady when my faith broke."
    constant string VL_ARADION_0271_KEY = "Aradion_0271"
    constant string VL_ARADION_0271_TEXT = "You have good heart."
    constant string VL_ARADION_0272_KEY = "Aradion_0272"
    constant string VL_ARADION_0272_TEXT = "Valeria says I apologize to stones. She is not entirely wrong."
    constant string VL_ARADION_0273_KEY = "Aradion_0273"
    constant string VL_ARADION_0273_TEXT = "If the Vale heals, it will be because someone refused to abandon it."
    constant string VL_ARADION_0274_KEY = "Aradion_0274"
    constant string VL_ARADION_0274_TEXT = "For the first time in years, I can imagine tomorrow."
    constant string VL_ARADION_0275_KEY = "Aradion_0275"
    constant string VL_ARADION_0275_TEXT = "Hope feels strange after so long. I am learning it again."
    constant string VL_ARADION_0276_KEY = "Aradion_0276"
    constant string VL_ARADION_0276_TEXT = "Valeria smiles more when you are near. I pretend not to notice."

    // AI profile moving barks.
    constant string VL_ARADION_0277_KEY = "Aradion_0277"
    constant string VL_ARADION_0277_TEXT = "Careful. Unstable arcane energies are flowing everywhere here."
    constant string VL_ARADION_0278_KEY = "Aradion_0278"
    constant string VL_ARADION_0278_TEXT = "The old paths twist where memory refuses to fade."
    constant string VL_ARADION_0279_KEY = "Aradion_0279"
    constant string VL_ARADION_0279_TEXT = "Most of our kin is consumed by the Void."
    constant string VL_ARADION_0280_KEY = "Aradion_0280"
    constant string VL_ARADION_0280_TEXT = "Careful. Disturbed magic does not sleep deeply."
    constant string VL_ARADION_0281_KEY = "Aradion_0281"
    constant string VL_ARADION_0281_TEXT = "I know enough of this road to fear it properly."
    constant string VL_ARADION_0282_KEY = "Aradion_0282"
    constant string VL_ARADION_0282_TEXT = "The old paths twist where memory refuses to fade."
    constant string VL_ARADION_0283_KEY = "Aradion_0283"
    constant string VL_ARADION_0283_TEXT = "I've walked this path many times. It doesn't have the same beauty as it used to have."
    constant string VL_ARADION_0284_KEY = "Aradion_0284"
    constant string VL_ARADION_0284_TEXT = "I know this route. I wish I had known it sooner."
    constant string VL_ARADION_0285_KEY = "Aradion_0285"
    constant string VL_ARADION_0285_TEXT = "The currents pull left here. Trust me on that."
    constant string VL_ARADION_0286_KEY = "Aradion_0286"
    constant string VL_ARADION_0286_TEXT = "Valeria says I should smile more. Despite the circumstances... maybe she is right."
    constant string VL_ARADION_0287_KEY = "Aradion_0287"
    constant string VL_ARADION_0287_TEXT = "With friends beside me, these ruins feel less final."
    constant string VL_ARADION_0288_KEY = "Aradion_0288"
    constant string VL_ARADION_0288_TEXT = "Come. There is still a path worth walking."

    // AI profile drop-items barks.
    constant string VL_ARADION_0289_KEY = "Aradion_0289"
    constant string VL_ARADION_0289_TEXT = "Take this. It may serve you better than my shelves."
    constant string VL_ARADION_0290_KEY = "Aradion_0290"
    constant string VL_ARADION_0290_TEXT = "Please, take it. I have carried enough regrets."
    constant string VL_ARADION_0291_KEY = "Aradion_0291"
    constant string VL_ARADION_0291_TEXT = "This belongs in capable hands. Yours."
    constant string VL_ARADION_0292_KEY = "Aradion_0292"
    constant string VL_ARADION_0292_TEXT = "Take it with my gratitude, not my sorrow."

    // AI profile item-given barks.
    constant string VL_ARADION_0293_KEY = "Aradion_0293"
    constant string VL_ARADION_0293_TEXT = "Curious. I will examine it carefully."
    constant string VL_ARADION_0294_KEY = "Aradion_0294"
    constant string VL_ARADION_0294_TEXT = "Thank you. I will put it to careful use."
    constant string VL_ARADION_0295_KEY = "Aradion_0295"
    constant string VL_ARADION_0295_TEXT = "You remembered what my work requires. That means much."
    constant string VL_ARADION_0296_KEY = "Aradion_0296"
    constant string VL_ARADION_0296_TEXT = "A gift from a trusted friend. I will treasure it."

    // AI profile attacking barks.
    constant string VL_ARADION_0297_KEY = "Aradion_0297"
    constant string VL_ARADION_0297_TEXT = "Back, shade."
    constant string VL_ARADION_0298_KEY = "Aradion_0298"
    constant string VL_ARADION_0298_TEXT = "Arcane magic is needed for this one!"
    constant string VL_ARADION_0299_KEY = "Aradion_0299"
    constant string VL_ARADION_0299_TEXT = "You can't defeat me!"
    constant string VL_ARADION_0300_KEY = "Aradion_0300"
    constant string VL_ARADION_0300_TEXT = "This ends now!"

    // AI profile casting barks.
    constant string VL_ARADION_0301_KEY = "Aradion_0301"
    constant string VL_ARADION_0301_TEXT = "Begone you spawn of Void!"
    constant string VL_ARADION_0302_KEY = "Aradion_0302"
    constant string VL_ARADION_0302_TEXT = "Anar'ethil, selama arcanum!"
    constant string VL_ARADION_0303_KEY = "Aradion_0303"
    constant string VL_ARADION_0303_TEXT = "Felo'melorn, ash'al diel!"
    constant string VL_ARADION_0304_KEY = "Aradion_0304"
    constant string VL_ARADION_0304_TEXT = "Belore, shael en'theran!"

    // AI profile killing barks.
    constant string VL_ARADION_0305_KEY = "Aradion_0305"
    constant string VL_ARADION_0305_TEXT = "Another echo put to rest."
    constant string VL_ARADION_0306_KEY = "Aradion_0306"
    constant string VL_ARADION_0306_TEXT = "A small mercy for Elarindor."
    constant string VL_ARADION_0307_KEY = "Aradion_0307"
    constant string VL_ARADION_0307_TEXT = "May that be the last shadow here."
    constant string VL_ARADION_0308_KEY = "Aradion_0308"
    constant string VL_ARADION_0308_TEXT = "Rest now."

    // AI profile companion-death barks.
    constant string VL_ARADION_0309_KEY = "Aradion_0309"
    constant string VL_ARADION_0309_TEXT = "No. I will not lose another soul to this ruin."
    constant string VL_ARADION_0310_KEY = "Aradion_0310"
    constant string VL_ARADION_0310_TEXT = "No. Stay with us."
    constant string VL_ARADION_0311_KEY = "Aradion_0311"
    constant string VL_ARADION_0311_TEXT = "No. Not you. Not after all this."
    constant string VL_ARADION_0312_KEY = "Aradion_0312"
    constant string VL_ARADION_0312_TEXT = "No! I was meant to protect you."
endglobals

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0001_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0002_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0003_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0004_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0005_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0006_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0007_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0008_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0009_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0010_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0011_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0012_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0013_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0014_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0015_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0016_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0017_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0018_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0019_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0020_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0021_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0022_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0023_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0024_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0031_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0032_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0033_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0034_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0035_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0036_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0037_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0038_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0041_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0042_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0043_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0044_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0045_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0046_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0047_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0048_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0049_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0050_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0053_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0054_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0055_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0056_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0057_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0058_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0060_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0061_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0062_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0063_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0065_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0066_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0067_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0068_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0069_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0070_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0071_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0072_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0073_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0074_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0075_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0076_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0077_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0078_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0079_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0080_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0082_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0083_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0084_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0085_KEY)
    call Voicelines_RegisterKey(VL_ARADION_FOLDER, VL_ARADION_0086_KEY)
endfunction

endlibrary
