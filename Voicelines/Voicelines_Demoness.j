/**
    VoicelinesDemoness

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
    Global `VL_DEMONESS_*` constants.

**/
library VoicelinesDemoness requires Voicelines

globals
    constant string VL_DEMONESS_FOLDER = "Demoness"

    // Legacy Excel draft/reference rows.

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Intro
    constant string VL_DEMONESS_0001_KEY = "Demoness_0001"
    constant string VL_DEMONESS_0001_TEXT = "Oh Prince, let me feast on this mortal orc..."
    constant string VL_DEMONESS_0002_KEY = "Demoness_0002"
    constant string VL_DEMONESS_0002_TEXT = "Oh Prince, let me pulverize this orc into the void..."
    constant string VL_DEMONESS_0003_KEY = "Demoness_0003"
    constant string VL_DEMONESS_0003_TEXT = "Prince, why are we even listening to this... ...Orc? Let's just end him where he stands!"

    // Excel draft: Satyr_Demoness Lines | Quest: Satyr Negotiations | Event: Dialog: Negoations - arena
    constant string VL_DEMONESS_0004_KEY = "Demoness_0004"
    constant string VL_DEMONESS_0004_TEXT = "If you return defeated, I'll rip you apart by myself, and I'll make sure I enjoy it while you scream with your guts out!"

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Intro | Done: x
    constant string VL_DEMONESS_0020_KEY = "Demoness_0020"
    constant string VL_DEMONESS_0020_TEXT = "Oh, sweet adventurer, are you lost in these woods? Or perhaps you've stumbled upon me intentionally, drawn by my irresistible allure."
    constant string VL_DEMONESS_0021_KEY = "Demoness_0021"
    constant string VL_DEMONESS_0021_TEXT = "Oh, you're a curious one, aren't you? Or perhaps... adventurous? How about we make a deal, darling."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Intro / accept / Decline? | Done: x
    constant string VL_DEMONESS_0022_KEY = "Demoness_0022"
    constant string VL_DEMONESS_0022_TEXT = "Listen closely. I offer you power beyond your wildest dreams, but in return, you must pledge your loyalty to me. Are you willing to make such a deliciously wicked bargain?"

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Intro / Accept | Done: x
    constant string VL_DEMONESS_0023_KEY = "Demoness_0023"
    constant string VL_DEMONESS_0023_TEXT = "Come closer, my dear. Let me whisper secrets in your ear, temptations that will lead you down a path you never knew existed."
    constant string VL_DEMONESS_0024_KEY = "Demoness_0024"
    constant string VL_DEMONESS_0024_TEXT = "I sense a hunger within you, a hunger for power, for forbidden knowledge. How deliciously sinful."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Intro / Decline | Done: x
    constant string VL_DEMONESS_0025_KEY = "Demoness_0025"
    constant string VL_DEMONESS_0025_TEXT = "You've made your choice, and it's a foolish one. I don't worry, I know you'll come back..."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Intro / Accept | Done: x
    constant string VL_DEMONESS_0026_KEY = "Demoness_0026"
    constant string VL_DEMONESS_0026_TEXT = "Feel the chains of desire binding you to me!!! You will do now as I say."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 1 | Done: x
    constant string VL_DEMONESS_0027_KEY = "Demoness_0027"
    constant string VL_DEMONESS_0027_TEXT = "Your first task is simple yet... delightful. Spread false rumor among your kin. Let the lies weave their web."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 2 | Done: x
    constant string VL_DEMONESS_0028_KEY = "Demoness_0028"
    constant string VL_DEMONESS_0028_TEXT = "Now let's make the rumor more effective. Steal the pillage and place it in that miserable orc's hut."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 3 | Done: x
    constant string VL_DEMONESS_0029_KEY = "Demoness_0029"
    constant string VL_DEMONESS_0029_TEXT = "This is too boring... Let's spice things up! Eliminate one of your own kind."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Done: x
    constant string VL_DEMONESS_0030_KEY = "Demoness_0030"
    constant string VL_DEMONESS_0030_TEXT = "One final task to seal our pact, my devoted servant."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 4 | Done: x
    constant string VL_DEMONESS_0031_KEY = "Demoness_0031"
    constant string VL_DEMONESS_0031_TEXT = "Offer up your very soul to me, and together we shall rule over the realms of desire for eternity. Fear not the darkness, for in death, you shall find rebirth, and in rebirth, you shall find favor in my eyes."
    constant string VL_DEMONESS_0032_KEY = "Demoness_0032"
    constant string VL_DEMONESS_0032_TEXT = "Ah, my precious servant, how beautifully you have embraced the abyss. Your sacrifice has pleased me beyond measure."
    constant string VL_DEMONESS_0033_KEY = "Demoness_0033"
    constant string VL_DEMONESS_0033_TEXT = "I bestow upon you the gift of unfathomable power. Let it fuel your every desire and bind you ever closer to my will."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 1 | Done: x
    constant string VL_DEMONESS_0035_KEY = "Demoness_0035"
    constant string VL_DEMONESS_0035_TEXT = "Ah, such sweet obedience."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 2 | Done: x
    constant string VL_DEMONESS_0036_KEY = "Demoness_0036"
    constant string VL_DEMONESS_0036_TEXT = "How thrilling it is to watch you bend to my will."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 4 | Done: x
    constant string VL_DEMONESS_0037_KEY = "Demoness_0037"
    constant string VL_DEMONESS_0037_TEXT = "Embrace the shadows, my sweet servant."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Task 3 | Done: x
    constant string VL_DEMONESS_0038_KEY = "Demoness_0038"
    constant string VL_DEMONESS_0038_TEXT = "Uuh... such devotion. So enchanting."

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Dispelled | Done: x
    constant string VL_DEMONESS_0039_KEY = "Demoness_0039"
    constant string VL_DEMONESS_0039_TEXT = "Foolish orc! I will make sure regret your actions as I tear your apart!"

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Other | Done: x
    constant string VL_DEMONESS_0040_KEY = "Demoness_0040"
    constant string VL_DEMONESS_0040_TEXT = "You are blind to not see the power that awaits you..."
    constant string VL_DEMONESS_0041_KEY = "Demoness_0041"
    constant string VL_DEMONESS_0041_TEXT = "Now I'll make you suffer! Your pain shall bring me satisfaction!"

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Dispelled | Done: x
    constant string VL_DEMONESS_0042_KEY = "Demoness_0042"
    constant string VL_DEMONESS_0042_TEXT = "Foolish orc! I will make sure you regret your actions as I tear your apart!"

    // Excel draft: Satyr_Demoness Lines | Quest: Succubus | Event: Other | Done: x
    constant string VL_DEMONESS_0043_KEY = "Demoness_0043"
    constant string VL_DEMONESS_0043_TEXT = "You will obey me!"
    constant string VL_DEMONESS_0044_KEY = "Demoness_0044"
    constant string VL_DEMONESS_0044_TEXT = "Wait until you see what my master has planned for you!"
    constant string VL_DEMONESS_0045_KEY = "Demoness_0045"
    constant string VL_DEMONESS_0045_TEXT = "Submit your life to me!"
endglobals

endlibrary
