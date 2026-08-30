/**
    VoicelinesOrcGrunt

    Author: Valdemar
    Version: 1.1.2

    Description:
    Speaker-owned voiceline key/text constants migrated from legacy
    dialogue and voice reference data. Runtime consumers require this
    library directly when they need these constants.

    Credits:
    - Voicelines/_oldExcel/VoicelinesMaster.xlsx
    - Legacy World Editor dialogue and string exports

    How to install:
    Import after `Voicelines.j`. Add runtime registration when a
    consumer starts using these constants.

    API:
    Global `VL_ORCGRUNT_*` constants.

**/
library VoicelinesOrcGrunt requires Voicelines

globals
    constant string VL_ORCGRUNT_FOLDER = "Orc Grunt"

    // Normal grunt voicelines.

    constant string VL_ORCGRUNT_0001_KEY = "OrcGrunt_0001"
    constant string VL_ORCGRUNT_0001_TEXT = "Well met, shaman."
    constant string VL_ORCGRUNT_0002_KEY = "OrcGrunt_0002"
    constant string VL_ORCGRUNT_0002_TEXT = "Hey you there! I have not seen you for a while. Aren't you Nazgrek or does my memory serve correct?"
    constant string VL_ORCGRUNT_0003_KEY = "OrcGrunt_0003"
    constant string VL_ORCGRUNT_0003_TEXT = "Bah! This place is so boring. Only stupid wolves and slimy frogs that taste like poo-poo."
    constant string VL_ORCGRUNT_0004_KEY = "OrcGrunt_0004"
    constant string VL_ORCGRUNT_0004_TEXT = "I need some real challenge. Like back in the old times."

    // Call of the Horde voicelines.

    constant string VL_ORCGRUNT_0005_KEY = "OrcGrunt_0005"
    constant string VL_ORCGRUNT_0005_TEXT = "The warchief has issued you to aid the Horde once again."
    constant string VL_ORCGRUNT_0006_KEY = "OrcGrunt_0006"
    constant string VL_ORCGRUNT_0006_TEXT = "If you accept his summon, sign this letter with blood and go meet our chieftain face to face in the outpost to the east."
    constant string VL_ORCGRUNT_0007_KEY = "OrcGrunt_0007"
    constant string VL_ORCGRUNT_0007_TEXT = "He would not summon you if the matters where not so severe. I'll leave you to think this through... Remember the blood sign of the letter - that is if you make the right call..."

    // Protect the Outpost voicelines.

    constant string VL_ORCGRUNT_0012_KEY = "OrcGrunt_0012"
    constant string VL_ORCGRUNT_0012_TEXT = "The gnolls are attacking! Crush them in the name of the Horde!"
    constant string VL_ORCGRUNT_0013_KEY = "OrcGrunt_0013"
    constant string VL_ORCGRUNT_0013_TEXT = "They are too many! We're outnumbered! Lok'tar Ogar!!!"
    constant string VL_ORCGRUNT_0014_KEY = "OrcGrunt_0014"
    constant string VL_ORCGRUNT_0014_TEXT = "Thank you, shaman! Without your assistance, the gnolls would've surely outnumbered us."
    constant string VL_ORCGRUNT_0015_KEY = "OrcGrunt_0015"
    constant string VL_ORCGRUNT_0015_TEXT = "Hey you! You must be that shaman from the forest nearby. Aren't you Nazgrek or does my memory serve correct?"
    constant string VL_ORCGRUNT_0016_KEY = "OrcGrunt_0016"
    constant string VL_ORCGRUNT_0016_TEXT = "Wait! I knew you looked familiar. I was issued a task related to you shaman."
    constant string VL_ORCGRUNT_0017_KEY = "OrcGrunt_0017"
    constant string VL_ORCGRUNT_0017_TEXT = "Your days at exile have come to an end. If, you so decide..."

    // Mountain Defense voicelines.

    constant string VL_ORCGRUNT_0055_KEY = "OrcGrunt_0055"
    constant string VL_ORCGRUNT_0055_TEXT = "I've been expecting you. The situation is dire. The gnolls gather their forces, ready to strike at our outpost. We shall stand firm and repel their advance. Together, we shall emerge victorious!"
    constant string VL_ORCGRUNT_0056_KEY = "OrcGrunt_0056"
    constant string VL_ORCGRUNT_0056_TEXT = "We must prepare our defenses before the attack commences."

    constant string VL_ORCGRUNT_0063_KEY = "OrcGrunt_0063"
    constant string VL_ORCGRUNT_0063_TEXT = "The gnoll attack is ceased! We stand victorious!"
    constant string VL_ORCGRUNT_0064_KEY = "OrcGrunt_0064"
    constant string VL_ORCGRUNT_0064_TEXT = "Yes, I fear that this was just the beginning. Nazgrek, your aid in the defense was invaluable. Tell Granis what happened here."

    // Ragno-specific voicelines.

    constant string VL_ORCGRUNT_0085_KEY = "OrcGrunt_0085"
    constant string VL_ORCGRUNT_0085_TEXT = "Hail Nazgrek! I sense the weight of a turbulent past upon your shoulders. Sit, and let us share stories of trials endured."
    constant string VL_ORCGRUNT_0088_KEY = "OrcGrunt_0088"
    constant string VL_ORCGRUNT_0088_TEXT = "If you are interested, I've got some tasks that require some attention."
    constant string VL_ORCGRUNT_0089_KEY = "OrcGrunt_0089"
    constant string VL_ORCGRUNT_0089_TEXT = "What do you have in mind?"
    constant string VL_ORCGRUNT_0090_KEY = "OrcGrunt_0090"
    constant string VL_ORCGRUNT_0090_TEXT = "Lok'tar, my friend."
    constant string VL_ORCGRUNT_0091_KEY = "OrcGrunt_0091"
    constant string VL_ORCGRUNT_0091_TEXT = "Strength and honor."
    constant string VL_ORCGRUNT_0094_KEY = "OrcGrunt_0094"
    constant string VL_ORCGRUNT_0094_TEXT = "The stench of gnolls fouls our air..."
    constant string VL_ORCGRUNT_0097_KEY = "OrcGrunt_0097"
    constant string VL_ORCGRUNT_0097_TEXT = "Our settlements are in dire need of quality lumber."
    constant string VL_ORCGRUNT_0098_KEY = "OrcGrunt_0098"
    constant string VL_ORCGRUNT_0098_TEXT = "Grab a peon and get him to collect wood. The peon's got a few loose screws, but he can swing an axe. Make sure he brings back decent timber!"

    constant string VL_ORCGRUNT_0101_KEY = "OrcGrunt_0101"
    constant string VL_ORCGRUNT_0101_TEXT = "The woods are about to be in turmoil, and it's all cause of the satyrs. You're gonna march over there and talk some sense into them. Otherwise, we will bring the fight to their doorstep!"
    constant string VL_ORCGRUNT_0102_KEY = "OrcGrunt_0102"
    constant string VL_ORCGRUNT_0102_TEXT = "You made it back! I was starting to think you got tangled up in vines out there. So, spill it. Did you convince them satyrs to see reason?"
    constant string VL_ORCGRUNT_0103_KEY = "OrcGrunt_0103"
    constant string VL_ORCGRUNT_0103_TEXT = "Ha, I knew I could count on you. Nice work."
    constant string VL_ORCGRUNT_0104_KEY = "OrcGrunt_0104"
    constant string VL_ORCGRUNT_0104_TEXT = "Kobolds dared to trespass and loot our treasures, again… Go forth, vanquish their leader, and reclaim what's rightfully ours."
    constant string VL_ORCGRUNT_0106_KEY = "OrcGrunt_0106"
    constant string VL_ORCGRUNT_0106_TEXT = "You've returned, battle-worn. Crushed the kobolds and secured what's rightfully ours."

    // Rescue the Grunts voicelines.

    constant string VL_ORCGRUNT_0120_KEY = "OrcGrunt_0120"
    constant string VL_ORCGRUNT_0120_TEXT = "Well, that was horrible!"
    constant string VL_ORCGRUNT_0121_KEY = "OrcGrunt_0121"
    constant string VL_ORCGRUNT_0121_TEXT = "I would not have been saved without you!"
    constant string VL_ORCGRUNT_0122_KEY = "OrcGrunt_0122"
    constant string VL_ORCGRUNT_0122_TEXT = "These damn murlocs!"

    // Ragno-specific voicelines.

    constant string VL_ORCGRUNT_0160_KEY = "OrcGrunt_0160"
    constant string VL_ORCGRUNT_0160_TEXT = "They are growing stronger around the outpost and their attacks on this outpost are increasing."
    constant string VL_ORCGRUNT_0161_KEY = "OrcGrunt_0161"
    constant string VL_ORCGRUNT_0161_TEXT = "Slay any gnoll you encounter and bring me their heads!"
    constant string VL_ORCGRUNT_0162_KEY = "OrcGrunt_0162"
    constant string VL_ORCGRUNT_0162_TEXT = "Ah, back already? Let me see those disgusting gnoll heads..."
    constant string VL_ORCGRUNT_0163_KEY = "OrcGrunt_0163"
    constant string VL_ORCGRUNT_0163_TEXT = "Excellent work! Your victory shall be celebrated!"
    constant string VL_ORCGRUNT_0164_KEY = "OrcGrunt_0164"
    constant string VL_ORCGRUNT_0164_TEXT = "Well look at you!"
    constant string VL_ORCGRUNT_0165_KEY = "OrcGrunt_0165"
    constant string VL_ORCGRUNT_0165_TEXT = "Not only did you manage to bring back quality wood, but you also didn't lose our nearly-blind peon in the process."
    constant string VL_ORCGRUNT_0166_KEY = "OrcGrunt_0166"
    constant string VL_ORCGRUNT_0166_TEXT = "I suppose that deserves some recognition."

    // Zul'kis prologue patrol.

    constant string VL_ORCGRUNT_0167_KEY = "OrcGrunt_0167"
    constant string VL_ORCGRUNT_0167_TEXT = "Hold there! We heard shouting by the river. What happened here?"
    constant string VL_ORCGRUNT_0168_KEY = "OrcGrunt_0168"
    constant string VL_ORCGRUNT_0168_TEXT = "Then our patrol goes with you. We'll break the forest trolls' line; you keep us on our feet."
endglobals

endlibrary
