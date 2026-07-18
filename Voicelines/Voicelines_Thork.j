/**
    VoicelinesThork

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
    Global `VL_THORK_*` constants.

**/
library VoicelinesThork requires Voicelines

globals
    constant string VL_THORK_FOLDER = "Thork"

    // Legacy Excel draft/reference rows.

    // Excel draft: Thork Lines | Done: x
    constant string VL_THORK_0001_KEY = "Thork_0001"
    constant string VL_THORK_0001_TEXT = "Once you were an outcast-perhaps deservedly. But the past is ash now. What matters is what stands before us. Humans have grown bold, and our lands feel their eyes. Trolls and murlocs harass our hunters and watchtowers. Seek Granis and Garthork. They will set you upon the path. Lok'tar ogar, shaman."
    constant string VL_THORK_0001_TEXT_ALT1 = "You were an outcast, and maybe for good reason. But now past is past and now we need to focus on present matters at hand. The humans have become aware of our presence. Trolls and murlocs are causing havoc at our hunters and watch towers. Seek out Granis and Garthork. They will guide you forward. Lok-Tar Ogar shaman!"
    constant string VL_THORK_0002_KEY = "Thork_0002"
    constant string VL_THORK_0002_TEXT = "You were summoned, because the Horde has use for your shamanistic strength!"
    constant string VL_THORK_0002_TEXT_ALT1 = "You were brought here, because the Horde needs your shamanistic powers!"
    constant string VL_THORK_0003_KEY = "Thork_0003"
    constant string VL_THORK_0003_TEXT = "The witch doctors of the Darkspear have sent their shadow hunter-Zul'kis-to walk beside you. He serves my cause... and so will you."
    constant string VL_THORK_0003_TEXT_ALT1 = "The witchdoctors of Darkspear tribe have sent this Shadow hunter, Zul'kis to aid you in your path for the glory and honor of the Horde!"
    constant string VL_THORK_0004_KEY = "Thork_0004"
    constant string VL_THORK_0004_TEXT = "If you get along, he will heal you in battle and curse your enemies so they are slain more easily, haha haha!"
    constant string VL_THORK_0005_KEY = "Thork_0005"
    constant string VL_THORK_0005_TEXT = "Remember this, shaman: death by the axe among our kin is more honorable than surviving alone as an outcast in some forgotten forest. Now go."
    constant string VL_THORK_0005_TEXT_ALT1 = "You do what you do, but remember this shaman: Death by axe is more glorious than loneliness of being outcast in some corner of the forest. Now, go!"
    constant string VL_THORK_0006_KEY = "Thork_0006"
    constant string VL_THORK_0006_TEXT = "During the Second War, many of us were blind-too eager, too trusting. Gul'dan's poison ran deep. I remember those who warned us... and those who paid for it in blood. Survival always has a cost."
    constant string VL_THORK_0006_TEXT_ALT1 = "At the time, we did not realize Gul'Dan's betrayal. We should have listened to you and the other like-minded orcs, like Durotan... My brother paid the ultimate price with his sacrifice at the Kalimdor..."

    // Excel draft: Thork Lines | Done: x | Comment: This or 0001
    constant string VL_THORK_0007_KEY = "Thork_0007"
    constant string VL_THORK_0007_TEXT = "You were an outcast, and we all made choices we must now live with. But the present calls. Humans press closer, and trolls and murlocs weaken our hold on these lands. Seek Granis and Garthork. They will instruct what needs to be done."
    constant string VL_THORK_0007_TEXT_ALT1 = "You were an outcast and we made a deal with the devil, but now we need to focus on present matters at hand. The humans have become aware of our presence. Trolls and murlocs are causing havoc at our hunters and watch towers. Seek out Granis and Garthork. They will guide you forward."

    // Excel draft: Thork Lines | Done: x
    constant string VL_THORK_0008_KEY = "Thork_0008"
    constant string VL_THORK_0008_TEXT = "Indeed. The threat can no longer be ignored. Hunters vanish. Watchtowers burn. Granis and Garthork will prepare you for what comes next."
    constant string VL_THORK_0008_TEXT_ALT1 = "Indeed... but now we need to focus on present matters at hand. The humans have become aware of our presence. Trolls and murlocs are causing havoc at our hunters and the threat they pose can no longer be ignored. Seek out Granis and Garthork. They will guide you forward."

    // Excel draft: Thork Lines
    constant string VL_THORK_0010_KEY = "Thork_0010"
    constant string VL_THORK_0010_TEXT = "So... you came. I was uncertain you would answer my call, Nazgrek."
    constant string VL_THORK_0010_TEXT_ALT1 = "So, you've arrived... I didn't expect you to accept my summon."
    constant string VL_THORK_0011_KEY = "Thork_0011"
    constant string VL_THORK_0011_TEXT = "Where is the blood? Words are wind. Commitment is carved in flesh. Without sacrifice, trust means nothing."
    constant string VL_THORK_0011_TEXT_ALT1 = "Where's the blood? You know how it goes, Nazgrek. I don't know if you are trustworthy if you don't commit yourself with a blood pact!"
    constant string VL_THORK_0012_KEY = "Thork_0012"
    constant string VL_THORK_0012_TEXT = "You stand before me still breathing-good. Tell me, Nazgrek... have your battles hardened you, or merely sharpened your rage?"
    constant string VL_THORK_0012_TEXT_ALT1 = "Ahh, Nazgrek. Have you been victorious in battles?"
endglobals

endlibrary
