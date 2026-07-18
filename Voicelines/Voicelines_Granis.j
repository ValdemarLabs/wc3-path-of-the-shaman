/**
    VoicelinesGranis

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
    Global `VL_GRANIS_*` constants.

**/
library VoicelinesGranis requires Voicelines

globals
    constant string VL_GRANIS_FOLDER = "Granis"

    // Legacy Excel draft/reference rows.

    // Excel draft: Granis lines | Event: Granis / First Greet | Done: X
    constant string VL_GRANIS_0001_KEY = "Granis_0001"
    constant string VL_GRANIS_0001_TEXT = "Lok'tar! What brings you to Granis?"

    // Excel draft: Granis lines | Event: Granis / Normal Greet | Done: x
    constant string VL_GRANIS_0006_KEY = "Granis_0006"
    constant string VL_GRANIS_0006_TEXT = "Yes? What is it?"

    // Excel draft: Granis lines | Event: Granis / Farewell | Done: X
    constant string VL_GRANIS_0007_KEY = "Granis_0007"
    constant string VL_GRANIS_0007_TEXT = "Victory or death!"

    // Excel draft: Granis lines | Event: Granis / Roljin / intro | Done: X
    constant string VL_GRANIS_0010_KEY = "Granis_0010"
    constant string VL_GRANIS_0010_TEXT = "Hear me, brave warrior! The forest trolls grow bolder with each passing day. Our scouts venture into the woods, only to meet their demise at the hands of those vile creatures."
    constant string VL_GRANIS_0011_KEY = "Granis_0011"
    constant string VL_GRANIS_0011_TEXT = "The trolls gather strength under the leadership of Rol'jin, their fearsome warlord. His very name strikes fear into the hearts of our kin."

    // Excel draft: Granis lines | Event: Granis / Roljin / acceptdecline | Done: X
    constant string VL_GRANIS_0012_KEY = "Granis_0012"
    constant string VL_GRANIS_0012_TEXT = "I've seen too many of our own fall to the trolls' ambushes. It is time to put an end to this madness. Rol'jin must be stopped."

    // Excel draft: Granis lines | Event: Granis / Roljin / accept | Done: X
    constant string VL_GRANIS_0013_KEY = "Granis_0013"
    constant string VL_GRANIS_0013_TEXT = "Venture into the heart of the forest, seek out Rol'jin, and bring me his head as proof of his demise."
    constant string VL_GRANIS_0014_KEY = "Granis_0014"
    constant string VL_GRANIS_0014_TEXT = "Do not underestimate the danger that awaits you, for Rol'jin is a formidable foe. He commands the loyalty of his kin, and they will fight fiercely to protect their leader. Be prepared for a battle like no other."

    // Excel draft: Granis lines | Event: Granis / Roljin / decline | Done: X
    constant string VL_GRANIS_0015_KEY = "Granis_0015"
    constant string VL_GRANIS_0015_TEXT = "The threat of Rol'jin and his trolls cannot be ignored. Should you decide to aid us in this endeavor, you will earn the gratitude of the Horde."

    // Excel draft: Granis lines | Event: Granis / Roljin / unfinished | Done: X
    constant string VL_GRANIS_0016_KEY = "Granis_0016"
    constant string VL_GRANIS_0016_TEXT = "I see no trophy of victory in your hands, no sign of Rol'jin's defeat."

    // Excel draft: Granis lines | Event: Granis / Roljin / completed | Done: X
    constant string VL_GRANIS_0017_KEY = "Granis_0017"
    constant string VL_GRANIS_0017_TEXT = "Ah, you return, victorious! The head of Rol'jin, proof of his demise. The forest trolls will tremble at the news of their leader's fall and we shall vanquish the rest of them!"

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Intro / Granis
    constant string VL_GRANIS_0025_KEY = "Granis_0025"
    constant string VL_GRANIS_0025_TEXT = "Our scouts have returned with information of potential gnoll attack on our mountain outpost."
    constant string VL_GRANIS_0026_KEY = "Granis_0026"
    constant string VL_GRANIS_0026_TEXT = "We must prepare ourselves for this imminent threat."

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Acceptdecline / Granis
    constant string VL_GRANIS_0027_KEY = "Granis_0027"
    constant string VL_GRANIS_0027_TEXT = "Make haste to meet with Ragno, our seasoned warrior, and aid in the defense."

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Accept / Granis
    constant string VL_GRANIS_0028_KEY = "Granis_0028"
    constant string VL_GRANIS_0028_TEXT = "Time is of the essence, survival of the mountain outpost is crucial."

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Decline / Granis
    constant string VL_GRANIS_0029_KEY = "Granis_0029"
    constant string VL_GRANIS_0029_TEXT = "I understand if you are unable to join the defense, but know that every able body counts in this battle."

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Unfinished / Granis
    constant string VL_GRANIS_0040_KEY = "Granis_0040"
    constant string VL_GRANIS_0040_TEXT = "The gnolls have become more vile in recent years. I wonder what are they up to..."

    // Excel draft: Granis lines | Quest: Defense of Mountain Outpost | Event: Completed / Granis
    constant string VL_GRANIS_0041_KEY = "Granis_0041"
    constant string VL_GRANIS_0041_TEXT = "Well performed Nazgrek. Though the battle was won, I wonder what the gnolls are planning next..."
    constant string VL_GRANIS_0042_KEY = "Granis_0042"
    constant string VL_GRANIS_0042_TEXT = "Here is your well earned reward!"
endglobals

endlibrary
