/**
    VoicelinesDrunk

    Author: Valdemar
    Version: 2.2.0

    Description:
    Randomized hero, AI companion, wake-up, and Horde vendor lines used by
    Drunk and A Night To Remember.

    Credits:
    - Fish Audio

    How to install:
    Import after Voicelines and VoicelinesVendorLines.

    API:
    call VoicelinesDrunk_PickHeroReaction(speaker, passOut)
    call VoicelinesDrunk_PickLastNightQuestion(speaker)
    call VoicelinesDrunk_PickHeroNightReply(speaker)
    call VoicelinesDrunk_PickNightHeroResponse(speaker, storyIndex)
    call VoicelinesDrunk_PickAIReaction(speaker, passOut)
    call VoicelinesDrunk_PickAINightReply(speaker)
    call VoicelinesDrunk_PickAITaskRequest(speaker)
    call VoicelinesDrunk_PickAIForgiveness(speaker)
    call VoicelinesDrunk_PickWakeLine(speaker)
    call VoicelinesDrunk_PickVendorLine(voiceType, firstIndex)
    call VoicelinesDrunk_PickVendorTaskRequest(voiceType, firstIndex)
    call VoicelinesDrunk_PickVendorForgiveness(voiceType, firstIndex)
    Read VoicelinesDrunk_PickedText and VoicelinesDrunk_PickedKey.
    Read VoicelinesDrunk_PickedNightIndex after a LastNight picker.

**/
library VoicelinesDrunk initializer Init requires Voicelines, VoicelinesVendorLines

globals
    string VoicelinesDrunk_PickedText = ""
    string VoicelinesDrunk_PickedKey = ""
    integer VoicelinesDrunk_PickedNightIndex = 0

    // Folder declarations also drive tools/voicelines.ps1.
    constant string VL_NAZGREKDRUNK_FOLDER = "Nazgrek"
    constant string VL_ZULKISDRUNK_FOLDER = "Zulkis"
    constant string VL_HEROENGINEERDRUNK_FOLDER = "HeroEngineer"
    constant string VL_HEROPALADINDRUNK_FOLDER = "HeroPaladin"
    constant string VL_HEROSHAMANDRUNK_FOLDER = "HeroRestoshaman"
    constant string VL_HEROROGUEDRUNK_FOLDER = "HeroRogue"
    constant string VL_HEROWARLOCKDRUNK_FOLDER = "HeroWarlock"
    constant string VL_HEROWARRIORDRUNK_FOLDER = "HeroWarrior"
    constant string VL_AVELINEDRUNK_FOLDER = "Aveline"

    // Nazgrek reactions and wake-up lines.
    constant string VL_NAZGREKDRUNK_PUKE1_KEY = "Nazgrek_DrunkPuke1"
    constant string VL_NAZGREKDRUNK_PUKE1_TEXT = "Easy there. The mug is not your enemy."
    constant string VL_NAZGREKDRUNK_PUKE2_KEY = "Nazgrek_DrunkPuke2"
    constant string VL_NAZGREKDRUNK_PUKE2_TEXT = "You should drink that stuff more carefully."
    constant string VL_NAZGREKDRUNK_PASSOUT1_KEY = "Nazgrek_DrunkPassOut1"
    constant string VL_NAZGREKDRUNK_PASSOUT1_TEXT = "Zul'kis! Wake up, you reckless troll!"
    constant string VL_NAZGREKDRUNK_PASSOUT2_KEY = "Nazgrek_DrunkPassOut2"
    constant string VL_NAZGREKDRUNK_PASSOUT2_TEXT = "Zul'kis? Spirits, what have you done?"
    constant string VL_NAZGREKDRUNK_WAKE1_KEY = "Nazgrek_HangoverWake1"
    constant string VL_NAZGREKDRUNK_WAKE1_TEXT = "My skull feels like a kodo drum."
    constant string VL_NAZGREKDRUNK_WAKE2_KEY = "Nazgrek_HangoverWake2"
    constant string VL_NAZGREKDRUNK_WAKE2_TEXT = "The elements are far too loud this morning."
    constant string VL_NAZGREKDRUNK_WAKE3_KEY = "Nazgrek_HangoverWake3"
    constant string VL_NAZGREKDRUNK_WAKE3_TEXT = "Where am I, and why do I smell like a brewery?"
    constant string VL_NAZGREKDRUNK_QUESTION1_KEY = "Nazgrek_LastNightQuestion1"
    constant string VL_NAZGREKDRUNK_QUESTION1_TEXT = "What happened last night?"
    constant string VL_NAZGREKDRUNK_QUESTION2_KEY = "Nazgrek_LastNightQuestion2"
    constant string VL_NAZGREKDRUNK_QUESTION2_TEXT = "Tell me plainly. What did I do last night?"
    constant string VL_NAZGREKDRUNK_NIGHT1_KEY = "Nazgrek_LastNight1"
    constant string VL_NAZGREKDRUNK_NIGHT1_TEXT = "You called me a windbag in front of half the market, then asked the vendors to vote on it. They did."
    constant string VL_NAZGREKDRUNK_NIGHT2_KEY = "Nazgrek_LastNight2"
    constant string VL_NAZGREKDRUNK_NIGHT2_TEXT = "You borrowed my cloak to mop up your ale, lost it, and returned wearing a grain sack as a war banner."
    constant string VL_NAZGREKDRUNK_NIGHT3_KEY = "Nazgrek_LastNight3"
    constant string VL_NAZGREKDRUNK_NIGHT3_TEXT = "You tried to race the mountain giant through Redwind Pass. I dragged you from the ledge while you accused the wind of cheating."
    constant string VL_NAZGREKDRUNK_NIGHT4_KEY = "Nazgrek_LastNight4"
    constant string VL_NAZGREKDRUNK_NIGHT4_TEXT = "You stole a gryphon-feed sack because you swore it held a chimera egg. We ran from the guards until you passed out in my arms."
    constant string VL_NAZGREKDRUNK_NIGHT5_KEY = "Nazgrek_LastNight5"
    constant string VL_NAZGREKDRUNK_NIGHT5_TEXT = "You appointed a tavern stool as our new chieftain and demanded I swear loyalty. I will remember that humiliation for years."
    constant string VL_NAZGREKDRUNK_RESPONSE1_KEY = "Nazgrek_LastNightResponse1"
    constant string VL_NAZGREKDRUNK_RESPONSE1_TEXT = "I said that before the whole market? I owe you more than a quiet apology."
    constant string VL_NAZGREKDRUNK_RESPONSE2_KEY = "Nazgrek_LastNightResponse2"
    constant string VL_NAZGREKDRUNK_RESPONSE2_TEXT = "Then I damaged something that mattered to you. Tell me what must be replaced."
    constant string VL_NAZGREKDRUNK_RESPONSE3_KEY = "Nazgrek_LastNightResponse3"
    constant string VL_NAZGREKDRUNK_RESPONSE3_TEXT = "You risked your neck getting me out alive. I will not dismiss that debt."
    constant string VL_NAZGREKDRUNK_RESPONSE4_KEY = "Nazgrek_LastNightResponse4"
    constant string VL_NAZGREKDRUNK_RESPONSE4_TEXT = "I stole it? Spirits preserve me. Tell me where it belongs before the guards find me."
    constant string VL_NAZGREKDRUNK_RESPONSE5_KEY = "Nazgrek_LastNightResponse5"
    constant string VL_NAZGREKDRUNK_RESPONSE5_TEXT = "There is no honorable defense for that. Perhaps surviving the shame will teach me restraint."

    // Zul'kis reactions and wake-up lines.
    constant string VL_ZULKISDRUNK_PUKE1_KEY = "Zulkis_DrunkPuke1"
    constant string VL_ZULKISDRUNK_PUKE1_TEXT = "Slow down, mon. Da cup not be runnin' away."
    constant string VL_ZULKISDRUNK_PUKE2_KEY = "Zulkis_DrunkPuke2"
    constant string VL_ZULKISDRUNK_PUKE2_TEXT = "Ya supposed ta drink it, not fight it."
    constant string VL_ZULKISDRUNK_PASSOUT1_KEY = "Zulkis_DrunkPassOut1"
    constant string VL_ZULKISDRUNK_PASSOUT1_TEXT = "Nazgrek?! What ya doin', mon? Wake up!"
    constant string VL_ZULKISDRUNK_PASSOUT2_KEY = "Zulkis_DrunkPassOut2"
    constant string VL_ZULKISDRUNK_PASSOUT2_TEXT = "Nazgrek, dis not be a good place for a nap!"
    constant string VL_ZULKISDRUNK_WAKE1_KEY = "Zulkis_HangoverWake1"
    constant string VL_ZULKISDRUNK_WAKE1_TEXT = "Da spirits be whisperin'. Could dey whisper softer?"
    constant string VL_ZULKISDRUNK_WAKE2_KEY = "Zulkis_HangoverWake2"
    constant string VL_ZULKISDRUNK_WAKE2_TEXT = "My head be hurtin' in three different languages."
    constant string VL_ZULKISDRUNK_WAKE3_KEY = "Zulkis_HangoverWake3"
    constant string VL_ZULKISDRUNK_WAKE3_TEXT = "I remember a barrel, a song, and den nothin'."
    constant string VL_ZULKISDRUNK_QUESTION1_KEY = "Zulkis_LastNightQuestion1"
    constant string VL_ZULKISDRUNK_QUESTION1_TEXT = "What happened last night, mon?"
    constant string VL_ZULKISDRUNK_QUESTION2_KEY = "Zulkis_LastNightQuestion2"
    constant string VL_ZULKISDRUNK_QUESTION2_TEXT = "Tell me true. What did I do last night?"
    constant string VL_ZULKISDRUNK_NIGHT1_KEY = "Zulkis_LastNight1"
    constant string VL_ZULKISDRUNK_NIGHT1_TEXT = "Ya told everyone my finest hex was just fancy smoke, den made me prove it on ya hat."
    constant string VL_ZULKISDRUNK_NIGHT2_KEY = "Zulkis_LastNight2"
    constant string VL_ZULKISDRUNK_NIGHT2_TEXT = "Ya used my ritual cloth ta wrap a leaking keg. Da cloth be ruined, and da keg still leaked."
    constant string VL_ZULKISDRUNK_NIGHT3_KEY = "Zulkis_LastNight3"
    constant string VL_ZULKISDRUNK_NIGHT3_TEXT = "I carried ya outta Twilight Grove while ya sang love songs ta dat giant dead tree. Every wolf in da forest followed us home."
    constant string VL_ZULKISDRUNK_NIGHT4_KEY = "Zulkis_LastNight4"
    constant string VL_ZULKISDRUNK_NIGHT4_TEXT = "Ya stole a chimera egg, mon. When da mother came, ya passed out and left me ta run while carryin' both you and da egg."
    constant string VL_ZULKISDRUNK_NIGHT5_KEY = "Zulkis_LastNight5"
    constant string VL_ZULKISDRUNK_NIGHT5_TEXT = "Ya invited a scarecrow into da company and argued with me when it refused ta march. Dat argument lasted an hour."
    constant string VL_ZULKISDRUNK_RESPONSE1_KEY = "Zulkis_LastNightResponse1"
    constant string VL_ZULKISDRUNK_RESPONSE1_TEXT = "I said dat where everyone could hear? I owe ya a proper apology, mon."
    constant string VL_ZULKISDRUNK_RESPONSE2_KEY = "Zulkis_LastNightResponse2"
    constant string VL_ZULKISDRUNK_RESPONSE2_TEXT = "Den I be replacin' what I ruined. Tell me what ya need."
    constant string VL_ZULKISDRUNK_RESPONSE3_KEY = "Zulkis_LastNightResponse3"
    constant string VL_ZULKISDRUNK_RESPONSE3_TEXT = "Ya carried me through all dat? Dat debt be mine now."
    constant string VL_ZULKISDRUNK_RESPONSE4_KEY = "Zulkis_LastNightResponse4"
    constant string VL_ZULKISDRUNK_RESPONSE4_TEXT = "I stole it? Loa help me. Tell me where ta put it back before anyone notices."
    constant string VL_ZULKISDRUNK_RESPONSE5_KEY = "Zulkis_LastNightResponse5"
    constant string VL_ZULKISDRUNK_RESPONSE5_TEXT = "Dat sounded wiser in my empty head. I got no defense for it now, mon."

    // AI companion reactions and A Night To Remember replies.
    constant string VL_HEROENGINEERDRUNK_PUKE1_KEY = "HeroEngineer_DrunkPuke1"
    constant string VL_HEROENGINEERDRUNK_PUKE1_TEXT = "That intake exceeded every safe operating tolerance."
    constant string VL_HEROENGINEERDRUNK_PUKE2_KEY = "HeroEngineer_DrunkPuke2"
    constant string VL_HEROENGINEERDRUNK_PUKE2_TEXT = "Next time, install a regulator between the bottle and your mouth."
    constant string VL_HEROENGINEERDRUNK_NIGHT1_KEY = "HeroEngineer_LastNight1"
    constant string VL_HEROENGINEERDRUNK_NIGHT1_TEXT = "You introduced me as the fool who builds toys, then invited the whole tavern to laugh at my life's work."
    constant string VL_HEROENGINEERDRUNK_NIGHT2_KEY = "HeroEngineer_LastNight2"
    constant string VL_HEROENGINEERDRUNK_NIGHT2_TEXT = "You dismantled my pressure regulator to make a bottle opener. The keg exploded, and so did my prototype."
    constant string VL_HEROENGINEERDRUNK_NIGHT3_KEY = "HeroEngineer_LastNight3"
    constant string VL_HEROENGINEERDRUNK_NIGHT3_TEXT = "Your rocket-cart shortcut launched us across Ashfang Falls. I pulled you from a lava shelf while fire elementals tested my repairs."
    constant string VL_HEROENGINEERDRUNK_NIGHT4_KEY = "HeroEngineer_LastNight4"
    constant string VL_HEROENGINEERDRUNK_NIGHT4_TEXT = "You stole a cannon fuse to light your pipe. I spent the night convincing the artillery crew we were not saboteurs."
    constant string VL_HEROENGINEERDRUNK_NIGHT5_KEY = "HeroEngineer_LastNight5"
    constant string VL_HEROENGINEERDRUNK_NIGHT5_TEXT = "You proposed marriage to my repair construct and tried to feed it wedding cake through an exhaust pipe."
    constant string VL_HEROENGINEERDRUNK_TASK_KEY = "HeroEngineer_HangoverTask"
    constant string VL_HEROENGINEERDRUNK_TASK_TEXT = "Repair the damage you caused, and I may revise my incident report."
    constant string VL_HEROENGINEERDRUNK_FORGIVE_KEY = "HeroEngineer_HangoverForgive"
    constant string VL_HEROENGINEERDRUNK_FORGIVE_TEXT = "Repairs verified. I will classify the disaster as educational."
    constant string VL_HEROPALADINDRUNK_PUKE1_KEY = "HeroPaladin_DrunkPuke1"
    constant string VL_HEROPALADINDRUNK_PUKE1_TEXT = "Temperance would spare you this indignity."
    constant string VL_HEROPALADINDRUNK_PUKE2_KEY = "HeroPaladin_DrunkPuke2"
    constant string VL_HEROPALADINDRUNK_PUKE2_TEXT = "Drink water before you challenge another keg."
    constant string VL_HEROPALADINDRUNK_NIGHT1_KEY = "HeroPaladin_LastNight1"
    constant string VL_HEROPALADINDRUNK_NIGHT1_TEXT = "You interrupted my warning about temperance by calling me Saint Sourface before the entire tavern."
    constant string VL_HEROPALADINDRUNK_NIGHT2_KEY = "HeroPaladin_LastNight2"
    constant string VL_HEROPALADINDRUNK_NIGHT2_TEXT = "You used my order's banner as a tablecloth, soaked it in ale, and signed your tab across the crest."
    constant string VL_HEROPALADINDRUNK_NIGHT3_KEY = "HeroPaladin_LastNight3"
    constant string VL_HEROPALADINDRUNK_NIGHT3_TEXT = "You climbed the Stormhaven wall to enter the tavern secretly. I dragged you past the guards while you loudly explained our disguise."
    constant string VL_HEROPALADINDRUNK_NIGHT4_KEY = "HeroPaladin_LastNight4"
    constant string VL_HEROPALADINDRUNK_NIGHT4_TEXT = "You stole the chapel bell's clapper as a souvenir. I returned it while the watch chased you through the graveyard."
    constant string VL_HEROPALADINDRUNK_NIGHT5_KEY = "HeroPaladin_LastNight5"
    constant string VL_HEROPALADINDRUNK_NIGHT5_TEXT = "You knighted a goat with my mace and ordered it to arrest the bartender. The goat showed better judgment."
    constant string VL_HEROPALADINDRUNK_TASK_KEY = "HeroPaladin_HangoverTask"
    constant string VL_HEROPALADINDRUNK_TASK_TEXT = "Make restitution for the harm you caused before asking forgiveness."
    constant string VL_HEROPALADINDRUNK_FORGIVE_KEY = "HeroPaladin_HangoverForgive"
    constant string VL_HEROPALADINDRUNK_FORGIVE_TEXT = "You have made amends. Let wisdom outlast the headache."
    constant string VL_HEROSHAMANDRUNK_PUKE1_KEY = "HeroShaman_DrunkPuke1"
    constant string VL_HEROSHAMANDRUNK_PUKE1_TEXT = "Your body is rejecting what your judgment welcomed."
    constant string VL_HEROSHAMANDRUNK_PUKE2_KEY = "HeroShaman_DrunkPuke2"
    constant string VL_HEROSHAMANDRUNK_PUKE2_TEXT = "The water spirits recommend water next time."
    constant string VL_HEROSHAMANDRUNK_NIGHT1_KEY = "HeroShaman_LastNight1"
    constant string VL_HEROSHAMANDRUNK_NIGHT1_TEXT = "You mocked my spirit dance before the whole camp, then fell into the fire trying to demonstrate the proper steps."
    constant string VL_HEROSHAMANDRUNK_NIGHT2_KEY = "HeroShaman_LastNight2"
    constant string VL_HEROSHAMANDRUNK_NIGHT2_TEXT = "You fed my sacred herbs to a kodo because you said its breath needed healing. Those herbs took a month to gather."
    constant string VL_HEROSHAMANDRUNK_NIGHT3_KEY = "HeroShaman_LastNight3"
    constant string VL_HEROSHAMANDRUNK_NIGHT3_TEXT = "You followed a storm spirit onto a cliff. I caught your ankle after you stepped into the air to shake its hand."
    constant string VL_HEROSHAMANDRUNK_NIGHT4_KEY = "HeroShaman_LastNight4"
    constant string VL_HEROSHAMANDRUNK_NIGHT4_TEXT = "You stole an offering from the river shrine. The spirits chased us with lightning until you dropped it and passed out."
    constant string VL_HEROSHAMANDRUNK_NIGHT5_KEY = "HeroShaman_LastNight5"
    constant string VL_HEROSHAMANDRUNK_NIGHT5_TEXT = "You challenged my water elemental to a drinking contest. It won, which should not have surprised anyone."
    constant string VL_HEROSHAMANDRUNK_TASK_KEY = "HeroShaman_HangoverTask"
    constant string VL_HEROSHAMANDRUNK_TASK_TEXT = "Restore the balance you disturbed, then return to me."
    constant string VL_HEROSHAMANDRUNK_FORGIVE_KEY = "HeroShaman_HangoverForgive"
    constant string VL_HEROSHAMANDRUNK_FORGIVE_TEXT = "Balance is restored. Try not to offend it again tonight."
    constant string VL_HEROROGUEDRUNK_PUKE1_KEY = "HeroRogue_DrunkPuke1"
    constant string VL_HEROROGUEDRUNK_PUKE1_TEXT = "Subtle. No one will ever know you were drinking."
    constant string VL_HEROROGUEDRUNK_PUKE2_KEY = "HeroRogue_DrunkPuke2"
    constant string VL_HEROROGUEDRUNK_PUKE2_TEXT = "Try stealing smaller sips next time."
    constant string VL_HEROROGUEDRUNK_NIGHT1_KEY = "HeroRogue_LastNight1"
    constant string VL_HEROROGUEDRUNK_NIGHT1_TEXT = "You announced every alias I have ever used to a room full of merchants, then asked which one sounded most criminal."
    constant string VL_HEROROGUEDRUNK_NIGHT2_KEY = "HeroRogue_LastNight2"
    constant string VL_HEROROGUEDRUNK_NIGHT2_TEXT = "You used my lockpicks as tavern darts. Three snapped, one vanished, and the last is still in the ceiling."
    constant string VL_HEROROGUEDRUNK_NIGHT3_KEY = "HeroRogue_LastNight3"
    constant string VL_HEROROGUEDRUNK_NIGHT3_TEXT = "Your secret route into Riverbane Inn ended in its cellar. I carried you past three bandits after you forgot how legs work."
    constant string VL_HEROROGUEDRUNK_NIGHT4_KEY = "HeroRogue_LastNight4"
    constant string VL_HEROROGUEDRUNK_NIGHT4_TEXT = "You stole a chimera egg because it matched my hood. We ran from its mother while you asked whether it knew any shortcuts."
    constant string VL_HEROROGUEDRUNK_NIGHT5_KEY = "HeroRogue_LastNight5"
    constant string VL_HEROROGUEDRUNK_NIGHT5_TEXT = "You hid from the tavern bill inside my cloak while I was wearing it. Somehow you believed no one could see either of us."
    constant string VL_HEROROGUEDRUNK_TASK_KEY = "HeroRogue_HangoverTask"
    constant string VL_HEROROGUEDRUNK_TASK_TEXT = "Clean up your trail, and perhaps I forget what I saw."
    constant string VL_HEROROGUEDRUNK_FORGIVE_KEY = "HeroRogue_HangoverForgive"
    constant string VL_HEROROGUEDRUNK_FORGIVE_TEXT = "Good enough. As far as I know, nothing happened."
    constant string VL_HEROWARLOCKDRUNK_PUKE1_KEY = "HeroWarlock_DrunkPuke1"
    constant string VL_HEROWARLOCKDRUNK_PUKE1_TEXT = "Even demons show more restraint at a feast."
    constant string VL_HEROWARLOCKDRUNK_PUKE2_KEY = "HeroWarlock_DrunkPuke2"
    constant string VL_HEROWARLOCKDRUNK_PUKE2_TEXT = "A curse would have been cleaner than this."
    constant string VL_HEROWARLOCKDRUNK_NIGHT1_KEY = "HeroWarlock_LastNight1"
    constant string VL_HEROWARLOCKDRUNK_NIGHT1_TEXT = "You called my demons party tricks before the whole tavern. The imp is still demanding permission to avenge my honor."
    constant string VL_HEROWARLOCKDRUNK_NIGHT2_KEY = "HeroWarlock_LastNight2"
    constant string VL_HEROWARLOCKDRUNK_NIGHT2_TEXT = "You poured ale into my summoning circle to see whether demons prefer dark brew. The scorch marks answer your question."
    constant string VL_HEROWARLOCKDRUNK_NIGHT3_KEY = "HeroWarlock_LastNight3"
    constant string VL_HEROWARLOCKDRUNK_NIGHT3_TEXT = "You tried to ride an infernal through the city gate. I banished it and dragged you away while your trousers were still smoking."
    constant string VL_HEROWARLOCKDRUNK_NIGHT4_KEY = "HeroWarlock_LastNight4"
    constant string VL_HEROWARLOCKDRUNK_NIGHT4_TEXT = "You stole a cultist's grimoire and signed my name in it. They chased me for miles while you slept in a wheelbarrow."
    constant string VL_HEROWARLOCKDRUNK_NIGHT5_KEY = "HeroWarlock_LastNight5"
    constant string VL_HEROWARLOCKDRUNK_NIGHT5_TEXT = "You offered your soul to my imp for another drink. It refused and has been insufferably proud ever since."
    constant string VL_HEROWARLOCKDRUNK_TASK_KEY = "HeroWarlock_HangoverTask"
    constant string VL_HEROWARLOCKDRUNK_TASK_TEXT = "Undo your little catastrophe before I become creative."
    constant string VL_HEROWARLOCKDRUNK_FORGIVE_KEY = "HeroWarlock_HangoverForgive"
    constant string VL_HEROWARLOCKDRUNK_FORGIVE_TEXT = "The debt is settled. Disappointingly, no curse is required."
    constant string VL_HEROWARRIORDRUNK_PUKE1_KEY = "HeroWarrior_DrunkPuke1"
    constant string VL_HEROWARRIORDRUNK_PUKE1_TEXT = "Hold your ground. And your stomach."
    constant string VL_HEROWARRIORDRUNK_PUKE2_KEY = "HeroWarrior_DrunkPuke2"
    constant string VL_HEROWARRIORDRUNK_PUKE2_TEXT = "You fought that drink bravely. The drink won."
    constant string VL_HEROWARRIORDRUNK_NIGHT1_KEY = "HeroWarrior_LastNight1"
    constant string VL_HEROWARRIORDRUNK_NIGHT1_TEXT = "You told the whole barracks I fight like a sleepy peon, then lost an arm-wrestling match to that sleepy peon."
    constant string VL_HEROWARRIORDRUNK_NIGHT2_KEY = "HeroWarrior_LastNight2"
    constant string VL_HEROWARRIORDRUNK_NIGHT2_TEXT = "You used my sword to open a keg and chipped the blade. Then you blamed the keg for poor defensive form."
    constant string VL_HEROWARRIORDRUNK_NIGHT3_KEY = "HeroWarrior_LastNight3"
    constant string VL_HEROWARRIORDRUNK_NIGHT3_TEXT = "You entered the Circle of Blood without armor and challenged both teams. I carried you out under one arm and fought with the other."
    constant string VL_HEROWARRIORDRUNK_NIGHT4_KEY = "HeroWarrior_LastNight4"
    constant string VL_HEROWARRIORDRUNK_NIGHT4_TEXT = "You stole the guard captain's shield and painted your face on it. We were still running when you decided to take a nap."
    constant string VL_HEROWARRIORDRUNK_NIGHT5_KEY = "HeroWarrior_LastNight5"
    constant string VL_HEROWARRIORDRUNK_NIGHT5_TEXT = "You challenged a chimera to honorable combat, bowed, and passed out. I had to finish the negotiation with my axe."
    constant string VL_HEROWARRIORDRUNK_TASK_KEY = "HeroWarrior_HangoverTask"
    constant string VL_HEROWARRIORDRUNK_TASK_TEXT = "Set things right. A warrior owns every blow, even drunken ones."
    constant string VL_HEROWARRIORDRUNK_FORGIVE_KEY = "HeroWarrior_HangoverForgive"
    constant string VL_HEROWARRIORDRUNK_FORGIVE_TEXT = "You faced the consequences. We are square."
    constant string VL_AVELINEDRUNK_PUKE1_KEY = "Aveline_DrunkPuke1"
    constant string VL_AVELINEDRUNK_PUKE1_TEXT = "That is why soldiers pace their drinks."
    constant string VL_AVELINEDRUNK_PUKE2_KEY = "Aveline_DrunkPuke2"
    constant string VL_AVELINEDRUNK_PUKE2_TEXT = "Clean yourself up before something smells weakness."
    constant string VL_AVELINEDRUNK_NIGHT1_KEY = "Aveline_LastNight1"
    constant string VL_AVELINEDRUNK_NIGHT1_TEXT = "You called my discipline adorable in front of the company, then ordered them to salute your mug instead of me."
    constant string VL_AVELINEDRUNK_NIGHT2_KEY = "Aveline_LastNight2"
    constant string VL_AVELINEDRUNK_NIGHT2_TEXT = "You turned my field map into a drinking-game board and used my helmet as the penalty cup."
    constant string VL_AVELINEDRUNK_NIGHT3_KEY = "Aveline_LastNight3"
    constant string VL_AVELINEDRUNK_NIGHT3_TEXT = "Your brilliant adventure over the Stormhaven wall ended with me dragging you past every human guard back to the forest."
    constant string VL_AVELINEDRUNK_NIGHT4_KEY = "Aveline_LastNight4"
    constant string VL_AVELINEDRUNK_NIGHT4_TEXT = "At Chimairo's Roost you stole a chimera egg. We ran from its mother, and I carried you because you chose that moment to pass out."
    constant string VL_AVELINEDRUNK_NIGHT5_KEY = "Aveline_LastNight5"
    constant string VL_AVELINEDRUNK_NIGHT5_TEXT = "You attempted to enlist the tavern furniture. The table refused orders, so you charged it with insubordination."
    constant string VL_AVELINEDRUNK_TASK_KEY = "Aveline_HangoverTask"
    constant string VL_AVELINEDRUNK_TASK_TEXT = "Correct the damage, report back, and do not make me repeat myself."
    constant string VL_AVELINEDRUNK_FORGIVE_KEY = "Aveline_HangoverForgive"
    constant string VL_AVELINEDRUNK_FORGIVE_TEXT = "The matter is resolved. Consider this your only warning."

    private constant integer VD_AI_ENGINEER = 1
    private constant integer VD_AI_PALADIN = 2
    private constant integer VD_AI_SHAMAN = 3
    private constant integer VD_AI_ROGUE = 4
    private constant integer VD_AI_WARLOCK = 5
    private constant integer VD_AI_WARRIOR = 6
    private constant integer VD_AI_AVELINE = 7

    private integer VD_VendorVoiceCount = 0
    private string array VD_VendorVoiceType
    private integer array VD_VendorFirstIndex
    private string array VD_VendorText1
    private string array VD_VendorText2
    private string array VD_VendorText3
    private string array VD_VendorText4
    private string array VD_VendorText5
    private string array VD_VendorTaskText
    private string array VD_VendorForgiveText
endglobals

private function SetPicked takes string text, string key returns nothing
    set VoicelinesDrunk_PickedText = text
    set VoicelinesDrunk_PickedKey = key
endfunction

private function PickTwo takes string text1, string key1, string text2, string key2 returns nothing
    if GetRandomInt(1, 2) == 1 then
        call SetPicked(text1, key1)
    else
        call SetPicked(text2, key2)
    endif
endfunction

private function PickFive takes string text1, string key1, string text2, string key2, string text3, string key3, string text4, string key4, string text5, string key5 returns nothing
    set VoicelinesDrunk_PickedNightIndex = GetRandomInt(1, 5)
    if VoicelinesDrunk_PickedNightIndex == 1 then
        call SetPicked(text1, key1)
    elseif VoicelinesDrunk_PickedNightIndex == 2 then
        call SetPicked(text2, key2)
    elseif VoicelinesDrunk_PickedNightIndex == 3 then
        call SetPicked(text3, key3)
    elseif VoicelinesDrunk_PickedNightIndex == 4 then
        call SetPicked(text4, key4)
    else
        call SetPicked(text5, key5)
    endif
endfunction

public function PickHeroReaction takes unit speaker, boolean passOut returns nothing
    if speaker == udg_Nazgrek then
        if passOut then
            call PickTwo(VL_NAZGREKDRUNK_PASSOUT1_TEXT, VL_NAZGREKDRUNK_PASSOUT1_KEY, VL_NAZGREKDRUNK_PASSOUT2_TEXT, VL_NAZGREKDRUNK_PASSOUT2_KEY)
        else
            call PickTwo(VL_NAZGREKDRUNK_PUKE1_TEXT, VL_NAZGREKDRUNK_PUKE1_KEY, VL_NAZGREKDRUNK_PUKE2_TEXT, VL_NAZGREKDRUNK_PUKE2_KEY)
        endif
    elseif passOut then
        call PickTwo(VL_ZULKISDRUNK_PASSOUT1_TEXT, VL_ZULKISDRUNK_PASSOUT1_KEY, VL_ZULKISDRUNK_PASSOUT2_TEXT, VL_ZULKISDRUNK_PASSOUT2_KEY)
    else
        call PickTwo(VL_ZULKISDRUNK_PUKE1_TEXT, VL_ZULKISDRUNK_PUKE1_KEY, VL_ZULKISDRUNK_PUKE2_TEXT, VL_ZULKISDRUNK_PUKE2_KEY)
    endif
    set speaker = null
endfunction

public function PickLastNightQuestion takes unit speaker returns nothing
    if speaker == udg_Nazgrek then
        call PickTwo(VL_NAZGREKDRUNK_QUESTION1_TEXT, VL_NAZGREKDRUNK_QUESTION1_KEY, VL_NAZGREKDRUNK_QUESTION2_TEXT, VL_NAZGREKDRUNK_QUESTION2_KEY)
    else
        call PickTwo(VL_ZULKISDRUNK_QUESTION1_TEXT, VL_ZULKISDRUNK_QUESTION1_KEY, VL_ZULKISDRUNK_QUESTION2_TEXT, VL_ZULKISDRUNK_QUESTION2_KEY)
    endif
    set speaker = null
endfunction

public function PickWakeLine takes unit speaker returns nothing
    local integer roll = GetRandomInt(1, 3)
    if speaker == udg_Nazgrek then
        if roll == 1 then
            call SetPicked(VL_NAZGREKDRUNK_WAKE1_TEXT, VL_NAZGREKDRUNK_WAKE1_KEY)
        elseif roll == 2 then
            call SetPicked(VL_NAZGREKDRUNK_WAKE2_TEXT, VL_NAZGREKDRUNK_WAKE2_KEY)
        else
            call SetPicked(VL_NAZGREKDRUNK_WAKE3_TEXT, VL_NAZGREKDRUNK_WAKE3_KEY)
        endif
    elseif roll == 1 then
        call SetPicked(VL_ZULKISDRUNK_WAKE1_TEXT, VL_ZULKISDRUNK_WAKE1_KEY)
    elseif roll == 2 then
        call SetPicked(VL_ZULKISDRUNK_WAKE2_TEXT, VL_ZULKISDRUNK_WAKE2_KEY)
    else
        call SetPicked(VL_ZULKISDRUNK_WAKE3_TEXT, VL_ZULKISDRUNK_WAKE3_KEY)
    endif
    set speaker = null
endfunction

public function PickHeroNightReply takes unit speaker returns nothing
    if speaker == udg_Nazgrek then
        call PickFive(VL_NAZGREKDRUNK_NIGHT1_TEXT, VL_NAZGREKDRUNK_NIGHT1_KEY, VL_NAZGREKDRUNK_NIGHT2_TEXT, VL_NAZGREKDRUNK_NIGHT2_KEY, VL_NAZGREKDRUNK_NIGHT3_TEXT, VL_NAZGREKDRUNK_NIGHT3_KEY, VL_NAZGREKDRUNK_NIGHT4_TEXT, VL_NAZGREKDRUNK_NIGHT4_KEY, VL_NAZGREKDRUNK_NIGHT5_TEXT, VL_NAZGREKDRUNK_NIGHT5_KEY)
    else
        call PickFive(VL_ZULKISDRUNK_NIGHT1_TEXT, VL_ZULKISDRUNK_NIGHT1_KEY, VL_ZULKISDRUNK_NIGHT2_TEXT, VL_ZULKISDRUNK_NIGHT2_KEY, VL_ZULKISDRUNK_NIGHT3_TEXT, VL_ZULKISDRUNK_NIGHT3_KEY, VL_ZULKISDRUNK_NIGHT4_TEXT, VL_ZULKISDRUNK_NIGHT4_KEY, VL_ZULKISDRUNK_NIGHT5_TEXT, VL_ZULKISDRUNK_NIGHT5_KEY)
    endif
    set speaker = null
endfunction

public function PickNightHeroResponse takes unit speaker, integer storyIndex returns nothing
    if storyIndex < 1 or storyIndex > 5 then
        set storyIndex = 5
    endif
    if speaker == udg_Nazgrek then
        if storyIndex == 1 then
            call SetPicked(VL_NAZGREKDRUNK_RESPONSE1_TEXT, VL_NAZGREKDRUNK_RESPONSE1_KEY)
        elseif storyIndex == 2 then
            call SetPicked(VL_NAZGREKDRUNK_RESPONSE2_TEXT, VL_NAZGREKDRUNK_RESPONSE2_KEY)
        elseif storyIndex == 3 then
            call SetPicked(VL_NAZGREKDRUNK_RESPONSE3_TEXT, VL_NAZGREKDRUNK_RESPONSE3_KEY)
        elseif storyIndex == 4 then
            call SetPicked(VL_NAZGREKDRUNK_RESPONSE4_TEXT, VL_NAZGREKDRUNK_RESPONSE4_KEY)
        else
            call SetPicked(VL_NAZGREKDRUNK_RESPONSE5_TEXT, VL_NAZGREKDRUNK_RESPONSE5_KEY)
        endif
    elseif storyIndex == 1 then
        call SetPicked(VL_ZULKISDRUNK_RESPONSE1_TEXT, VL_ZULKISDRUNK_RESPONSE1_KEY)
    elseif storyIndex == 2 then
        call SetPicked(VL_ZULKISDRUNK_RESPONSE2_TEXT, VL_ZULKISDRUNK_RESPONSE2_KEY)
    elseif storyIndex == 3 then
        call SetPicked(VL_ZULKISDRUNK_RESPONSE3_TEXT, VL_ZULKISDRUNK_RESPONSE3_KEY)
    elseif storyIndex == 4 then
        call SetPicked(VL_ZULKISDRUNK_RESPONSE4_TEXT, VL_ZULKISDRUNK_RESPONSE4_KEY)
    else
        call SetPicked(VL_ZULKISDRUNK_RESPONSE5_TEXT, VL_ZULKISDRUNK_RESPONSE5_KEY)
    endif
    set speaker = null
endfunction

private function GetAIKind takes unit speaker returns integer
    local integer unitTypeId = GetUnitTypeId(speaker)
    if unitTypeId == 'N64O' or unitTypeId == 'N661' then
        return VD_AI_ENGINEER
    elseif unitTypeId == 'H60Y' then
        return VD_AI_PALADIN
    elseif unitTypeId == 'O61H' then
        return VD_AI_SHAMAN
    elseif unitTypeId == 'O631' then
        return VD_AI_ROGUE
    elseif unitTypeId == 'O61K' or unitTypeId == 'H60X' then
        return VD_AI_WARLOCK
    elseif unitTypeId == 'O009' then
        return VD_AI_AVELINE
    endif
    return VD_AI_WARRIOR
endfunction

public function PickAIReaction takes unit speaker, boolean passOut returns nothing
    local integer aiKind = GetAIKind(speaker)
    if aiKind == VD_AI_ENGINEER then
        call PickTwo(VL_HEROENGINEERDRUNK_PUKE1_TEXT, VL_HEROENGINEERDRUNK_PUKE1_KEY, VL_HEROENGINEERDRUNK_PUKE2_TEXT, VL_HEROENGINEERDRUNK_PUKE2_KEY)
    elseif aiKind == VD_AI_PALADIN then
        call PickTwo(VL_HEROPALADINDRUNK_PUKE1_TEXT, VL_HEROPALADINDRUNK_PUKE1_KEY, VL_HEROPALADINDRUNK_PUKE2_TEXT, VL_HEROPALADINDRUNK_PUKE2_KEY)
    elseif aiKind == VD_AI_SHAMAN then
        call PickTwo(VL_HEROSHAMANDRUNK_PUKE1_TEXT, VL_HEROSHAMANDRUNK_PUKE1_KEY, VL_HEROSHAMANDRUNK_PUKE2_TEXT, VL_HEROSHAMANDRUNK_PUKE2_KEY)
    elseif aiKind == VD_AI_ROGUE then
        call PickTwo(VL_HEROROGUEDRUNK_PUKE1_TEXT, VL_HEROROGUEDRUNK_PUKE1_KEY, VL_HEROROGUEDRUNK_PUKE2_TEXT, VL_HEROROGUEDRUNK_PUKE2_KEY)
    elseif aiKind == VD_AI_WARLOCK then
        call PickTwo(VL_HEROWARLOCKDRUNK_PUKE1_TEXT, VL_HEROWARLOCKDRUNK_PUKE1_KEY, VL_HEROWARLOCKDRUNK_PUKE2_TEXT, VL_HEROWARLOCKDRUNK_PUKE2_KEY)
    elseif aiKind == VD_AI_AVELINE then
        call PickTwo(VL_AVELINEDRUNK_PUKE1_TEXT, VL_AVELINEDRUNK_PUKE1_KEY, VL_AVELINEDRUNK_PUKE2_TEXT, VL_AVELINEDRUNK_PUKE2_KEY)
    else
        call PickTwo(VL_HEROWARRIORDRUNK_PUKE1_TEXT, VL_HEROWARRIORDRUNK_PUKE1_KEY, VL_HEROWARRIORDRUNK_PUKE2_TEXT, VL_HEROWARRIORDRUNK_PUKE2_KEY)
    endif
    set speaker = null
endfunction

public function PickAINightReply takes unit speaker returns nothing
    local integer aiKind = GetAIKind(speaker)
    if aiKind == VD_AI_ENGINEER then
        call PickFive(VL_HEROENGINEERDRUNK_NIGHT1_TEXT, VL_HEROENGINEERDRUNK_NIGHT1_KEY, VL_HEROENGINEERDRUNK_NIGHT2_TEXT, VL_HEROENGINEERDRUNK_NIGHT2_KEY, VL_HEROENGINEERDRUNK_NIGHT3_TEXT, VL_HEROENGINEERDRUNK_NIGHT3_KEY, VL_HEROENGINEERDRUNK_NIGHT4_TEXT, VL_HEROENGINEERDRUNK_NIGHT4_KEY, VL_HEROENGINEERDRUNK_NIGHT5_TEXT, VL_HEROENGINEERDRUNK_NIGHT5_KEY)
    elseif aiKind == VD_AI_PALADIN then
        call PickFive(VL_HEROPALADINDRUNK_NIGHT1_TEXT, VL_HEROPALADINDRUNK_NIGHT1_KEY, VL_HEROPALADINDRUNK_NIGHT2_TEXT, VL_HEROPALADINDRUNK_NIGHT2_KEY, VL_HEROPALADINDRUNK_NIGHT3_TEXT, VL_HEROPALADINDRUNK_NIGHT3_KEY, VL_HEROPALADINDRUNK_NIGHT4_TEXT, VL_HEROPALADINDRUNK_NIGHT4_KEY, VL_HEROPALADINDRUNK_NIGHT5_TEXT, VL_HEROPALADINDRUNK_NIGHT5_KEY)
    elseif aiKind == VD_AI_SHAMAN then
        call PickFive(VL_HEROSHAMANDRUNK_NIGHT1_TEXT, VL_HEROSHAMANDRUNK_NIGHT1_KEY, VL_HEROSHAMANDRUNK_NIGHT2_TEXT, VL_HEROSHAMANDRUNK_NIGHT2_KEY, VL_HEROSHAMANDRUNK_NIGHT3_TEXT, VL_HEROSHAMANDRUNK_NIGHT3_KEY, VL_HEROSHAMANDRUNK_NIGHT4_TEXT, VL_HEROSHAMANDRUNK_NIGHT4_KEY, VL_HEROSHAMANDRUNK_NIGHT5_TEXT, VL_HEROSHAMANDRUNK_NIGHT5_KEY)
    elseif aiKind == VD_AI_ROGUE then
        call PickFive(VL_HEROROGUEDRUNK_NIGHT1_TEXT, VL_HEROROGUEDRUNK_NIGHT1_KEY, VL_HEROROGUEDRUNK_NIGHT2_TEXT, VL_HEROROGUEDRUNK_NIGHT2_KEY, VL_HEROROGUEDRUNK_NIGHT3_TEXT, VL_HEROROGUEDRUNK_NIGHT3_KEY, VL_HEROROGUEDRUNK_NIGHT4_TEXT, VL_HEROROGUEDRUNK_NIGHT4_KEY, VL_HEROROGUEDRUNK_NIGHT5_TEXT, VL_HEROROGUEDRUNK_NIGHT5_KEY)
    elseif aiKind == VD_AI_WARLOCK then
        call PickFive(VL_HEROWARLOCKDRUNK_NIGHT1_TEXT, VL_HEROWARLOCKDRUNK_NIGHT1_KEY, VL_HEROWARLOCKDRUNK_NIGHT2_TEXT, VL_HEROWARLOCKDRUNK_NIGHT2_KEY, VL_HEROWARLOCKDRUNK_NIGHT3_TEXT, VL_HEROWARLOCKDRUNK_NIGHT3_KEY, VL_HEROWARLOCKDRUNK_NIGHT4_TEXT, VL_HEROWARLOCKDRUNK_NIGHT4_KEY, VL_HEROWARLOCKDRUNK_NIGHT5_TEXT, VL_HEROWARLOCKDRUNK_NIGHT5_KEY)
    elseif aiKind == VD_AI_AVELINE then
        call PickFive(VL_AVELINEDRUNK_NIGHT1_TEXT, VL_AVELINEDRUNK_NIGHT1_KEY, VL_AVELINEDRUNK_NIGHT2_TEXT, VL_AVELINEDRUNK_NIGHT2_KEY, VL_AVELINEDRUNK_NIGHT3_TEXT, VL_AVELINEDRUNK_NIGHT3_KEY, VL_AVELINEDRUNK_NIGHT4_TEXT, VL_AVELINEDRUNK_NIGHT4_KEY, VL_AVELINEDRUNK_NIGHT5_TEXT, VL_AVELINEDRUNK_NIGHT5_KEY)
    else
        call PickFive(VL_HEROWARRIORDRUNK_NIGHT1_TEXT, VL_HEROWARRIORDRUNK_NIGHT1_KEY, VL_HEROWARRIORDRUNK_NIGHT2_TEXT, VL_HEROWARRIORDRUNK_NIGHT2_KEY, VL_HEROWARRIORDRUNK_NIGHT3_TEXT, VL_HEROWARRIORDRUNK_NIGHT3_KEY, VL_HEROWARRIORDRUNK_NIGHT4_TEXT, VL_HEROWARRIORDRUNK_NIGHT4_KEY, VL_HEROWARRIORDRUNK_NIGHT5_TEXT, VL_HEROWARRIORDRUNK_NIGHT5_KEY)
    endif
    set speaker = null
endfunction

public function PickAITaskRequest takes unit speaker returns nothing
    local integer aiKind = GetAIKind(speaker)
    if aiKind == VD_AI_ENGINEER then
        call SetPicked(VL_HEROENGINEERDRUNK_TASK_TEXT, VL_HEROENGINEERDRUNK_TASK_KEY)
    elseif aiKind == VD_AI_PALADIN then
        call SetPicked(VL_HEROPALADINDRUNK_TASK_TEXT, VL_HEROPALADINDRUNK_TASK_KEY)
    elseif aiKind == VD_AI_SHAMAN then
        call SetPicked(VL_HEROSHAMANDRUNK_TASK_TEXT, VL_HEROSHAMANDRUNK_TASK_KEY)
    elseif aiKind == VD_AI_ROGUE then
        call SetPicked(VL_HEROROGUEDRUNK_TASK_TEXT, VL_HEROROGUEDRUNK_TASK_KEY)
    elseif aiKind == VD_AI_WARLOCK then
        call SetPicked(VL_HEROWARLOCKDRUNK_TASK_TEXT, VL_HEROWARLOCKDRUNK_TASK_KEY)
    elseif aiKind == VD_AI_AVELINE then
        call SetPicked(VL_AVELINEDRUNK_TASK_TEXT, VL_AVELINEDRUNK_TASK_KEY)
    else
        call SetPicked(VL_HEROWARRIORDRUNK_TASK_TEXT, VL_HEROWARRIORDRUNK_TASK_KEY)
    endif
    set speaker = null
endfunction

public function PickAIForgiveness takes unit speaker returns nothing
    local integer aiKind = GetAIKind(speaker)
    if aiKind == VD_AI_ENGINEER then
        call SetPicked(VL_HEROENGINEERDRUNK_FORGIVE_TEXT, VL_HEROENGINEERDRUNK_FORGIVE_KEY)
    elseif aiKind == VD_AI_PALADIN then
        call SetPicked(VL_HEROPALADINDRUNK_FORGIVE_TEXT, VL_HEROPALADINDRUNK_FORGIVE_KEY)
    elseif aiKind == VD_AI_SHAMAN then
        call SetPicked(VL_HEROSHAMANDRUNK_FORGIVE_TEXT, VL_HEROSHAMANDRUNK_FORGIVE_KEY)
    elseif aiKind == VD_AI_ROGUE then
        call SetPicked(VL_HEROROGUEDRUNK_FORGIVE_TEXT, VL_HEROROGUEDRUNK_FORGIVE_KEY)
    elseif aiKind == VD_AI_WARLOCK then
        call SetPicked(VL_HEROWARLOCKDRUNK_FORGIVE_TEXT, VL_HEROWARLOCKDRUNK_FORGIVE_KEY)
    elseif aiKind == VD_AI_AVELINE then
        call SetPicked(VL_AVELINEDRUNK_FORGIVE_TEXT, VL_AVELINEDRUNK_FORGIVE_KEY)
    else
        call SetPicked(VL_HEROWARRIORDRUNK_FORGIVE_TEXT, VL_HEROWARRIORDRUNK_FORGIVE_KEY)
    endif
    set speaker = null
endfunction

private function RegisterVendorVoice takes string voiceType, integer firstIndex, string folder, string text1, string text2, string text3, string text4, string text5, string taskText, string forgiveText returns nothing
    set VD_VendorVoiceCount = VD_VendorVoiceCount + 1
    set VD_VendorVoiceType[VD_VendorVoiceCount] = voiceType
    set VD_VendorFirstIndex[VD_VendorVoiceCount] = firstIndex
    set VD_VendorText1[VD_VendorVoiceCount] = text1
    set VD_VendorText2[VD_VendorVoiceCount] = text2
    set VD_VendorText3[VD_VendorVoiceCount] = text3
    set VD_VendorText4[VD_VendorVoiceCount] = text4
    set VD_VendorText5[VD_VendorVoiceCount] = text5
    set VD_VendorTaskText[VD_VendorVoiceCount] = taskText
    set VD_VendorForgiveText[VD_VendorVoiceCount] = forgiveText
    call ExSound_RegisterSequence(voiceType, firstIndex, firstIndex + 6, "Pots\\Sound\\Voicelines\\" + folder + "\\")
endfunction

public function PickVendorLine takes string voiceType, integer firstIndex returns nothing
    local integer index = 1
    local integer roll = GetRandomInt(1, 5)
    set VoicelinesDrunk_PickedNightIndex = roll
    loop
        exitwhen index > VD_VendorVoiceCount
        if VD_VendorVoiceType[index] == voiceType and VD_VendorFirstIndex[index] == firstIndex then
            if roll == 1 then
                call SetPicked(VD_VendorText1[index], voiceType + I2S(firstIndex))
            elseif roll == 2 then
                call SetPicked(VD_VendorText2[index], voiceType + I2S(firstIndex + 1))
            elseif roll == 3 then
                call SetPicked(VD_VendorText3[index], voiceType + I2S(firstIndex + 2))
            elseif roll == 4 then
                call SetPicked(VD_VendorText4[index], voiceType + I2S(firstIndex + 3))
            else
                call SetPicked(VD_VendorText5[index], voiceType + I2S(firstIndex + 4))
            endif
            return
        endif
        set index = index + 1
    endloop
    set VoicelinesDrunk_PickedNightIndex = 1
    call SetPicked("I remember enough to know you owe someone an apology.", "")
endfunction

public function PickVendorTaskRequest takes string voiceType, integer firstIndex returns nothing
    local integer index = 1
    loop
        exitwhen index > VD_VendorVoiceCount
        if VD_VendorVoiceType[index] == voiceType and VD_VendorFirstIndex[index] == firstIndex then
            call SetPicked(VD_VendorTaskText[index], voiceType + I2S(firstIndex + 5))
            return
        endif
        set index = index + 1
    endloop
    call SetPicked("Set right what you damaged, then come back.", "")
endfunction

public function PickVendorForgiveness takes string voiceType, integer firstIndex returns nothing
    local integer index = 1
    loop
        exitwhen index > VD_VendorVoiceCount
        if VD_VendorVoiceType[index] == voiceType and VD_VendorFirstIndex[index] == firstIndex then
            call SetPicked(VD_VendorForgiveText[index], voiceType + I2S(firstIndex + 6))
            return
        endif
        set index = index + 1
    endloop
    call SetPicked("You made amends. We will call it settled.", "")
endfunction

private function Init takes nothing returns nothing
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PASSOUT1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_PASSOUT2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_WAKE3_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_QUESTION1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_QUESTION2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_RESPONSE1_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_RESPONSE2_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_RESPONSE3_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_RESPONSE4_KEY)
    call Voicelines_RegisterKey(VL_NAZGREKDRUNK_FOLDER, VL_NAZGREKDRUNK_RESPONSE5_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PASSOUT1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_PASSOUT2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_WAKE3_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_QUESTION1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_QUESTION2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_RESPONSE1_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_RESPONSE2_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_RESPONSE3_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_RESPONSE4_KEY)
    call Voicelines_RegisterKey(VL_ZULKISDRUNK_FOLDER, VL_ZULKISDRUNK_RESPONSE5_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROENGINEERDRUNK_FOLDER, VL_HEROENGINEERDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROPALADINDRUNK_FOLDER, VL_HEROPALADINDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROSHAMANDRUNK_FOLDER, VL_HEROSHAMANDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROROGUEDRUNK_FOLDER, VL_HEROROGUEDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROWARLOCKDRUNK_FOLDER, VL_HEROWARLOCKDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_HEROWARRIORDRUNK_FOLDER, VL_HEROWARRIORDRUNK_FORGIVE_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_PUKE1_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_PUKE2_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_NIGHT1_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_NIGHT2_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_NIGHT3_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_NIGHT4_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_NIGHT5_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_TASK_KEY)
    call Voicelines_RegisterKey(VL_AVELINEDRUNK_FOLDER, VL_AVELINEDRUNK_FORGIVE_KEY)

    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_1_TYPE, 1101, "GenericOrcMale1", "You told every customer my catch was sewer bait, then asked me for a discount because you had improved its reputation.", "You opened three fish barrels looking for more ale and left my entire morning catch spoiling in the sun.", "You fell from my pier chasing a moonfish. I hauled you out twice while you complained that the river was cheating.", "You stole my best net to capture a guard's horse. I cut you free before the patrol decided we were both thieves.", "You crowned a lobster king of the market and made me announce its royal prices until it escaped.", "Set right what you damaged, then come back and we will talk.", "You did the work. We will call the debt settled.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_3_TYPE, 1101, "GenericOrcMale3", "You called me a lost old road-sign in front of my customers, then asked me which direction led back to my dignity.", "You borrowed my pack cart for a keg race and returned one wheel, half a harness, and no explanation.", "You followed an ogre caravan into Bonecrush Stronghold because their lanterns looked friendly. I dragged you into the Havenwoods before they noticed.", "You stole a border sign and planted it beside my stall, so three caravans spent the night arguing over where the kingdom ended.", "You tried to hire my pack mule as your navigator. The mule refused, and you got lost following it anyway.", "Repair your trail of mistakes before asking me to forget it.", "The road is clear and so is your debt.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_4_TYPE, 1101, "GenericOrcMale4", "You told a crowd my blades were dull enough for children, then cut your belt demonstrating how harmless they were.", "You used my best hammer to tap a keg and cracked its haft, my anvil stand, and somehow the keg beside it.", "You climbed into my forge to prove fire respected you. I pulled you out before your boots became part of the floor.", "You stole a ceremonial axe from my wall and challenged the Dark Horde at the Maw of Cinders. I recovered the axe; they kept your dignity.", "You ordered a full suit of armor for a barrel and insisted I measure it while you introduced it as your cousin.", "Fix the damage properly, not with another drunken invention.", "The repair holds. I have no further complaint.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_5_TYPE, 1101, "GenericOrcMale5", "You announced my stew tasted like boot water before eating four bowls and asking the customers why they trusted your opinion.", "You emptied my spice chest into one pot, ruined tomorrow's stock, and tried to fix it by adding your left boot.", "You set the kitchen awning alight while toasting bread on a torch. I carried you out while you demanded dessert.", "You stole a roasting boar from Havenwoods Inn. We escaped through the murloc quarter while you tried to carve it on the run.", "You slept in my flour sack, and when customers arrived you claimed to be a rare dumpling I was saving for winter.", "Replace what you ruined and keep your boots out of my stew.", "Supplies replaced. Stay sober near my cooking pot.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_8_TYPE, 1101, "GenericOrcMale8", "You mocked my tide ritual before the fishers, then slipped into the water while demonstrating how the sea should bow to you.", "You broke my carved totem using it as a stool, then blamed the spirit inside for failing to hold your weight.", "You followed ghost-lights onto the sea cliffs. I caught you at the edge while you invited the horizon to another round.", "You stole a hydra offering from the Ruins of Zul'Garok. I spent the night leading angry trolls and angrier spirits away from you.", "You argued with your own shadow for leaving early. The shadow showed more wisdom than either of us.", "Calm the trouble you stirred, then the spirits may forgive you.", "The disturbance has passed. Walk more carefully next time.")
    call RegisterVendorVoice(VL_GENERIC_ORC_MALE_9_TYPE, 1101, "GenericOrcMale9", "You called my finest edge a butter knife before every buyer, then asked me to shave your tongue with it.", "You sharpened bottle caps on my whetstone until it cracked and scattered half my display across the road.", "You challenged the ore lift at Morgrim's Claim to a duel. I pulled you free before the machinery or the dwarves finished you.", "You stole a captain's sword and traded it for a keg. I recovered the sword while you guarded the keg with your life.", "You declared war on an empty bottle and appointed my customers as reinforcements. None volunteered.", "Prove you can clean up a mess as well as you can make one.", "Your edge is restored. Keep it away from the ale.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_1_TYPE, 1101, "GenericTaurenMale1", "You imitated my voice for the whole trading post and asked whether all tauren sound wiser simply because we have horns.", "You tried to race my windmill, crashed through the fence, and left three frightened kodos scattered across the plain.", "You wandered onto a cliff following what you called the singing wind. I dragged you back while you tried to sing with it.", "You stole a caravan's kodo bell because it knew your favorite song. The guards followed the ringing straight to us.", "You offered a solemn toast to a hitching post and became angry when it would not drink with you.", "Restore what your careless steps disturbed, then return.", "You have restored the balance between us.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_2_TYPE, 1101, "GenericTaurenMale2", "You told every miner my veins were imaginary, then spent an hour digging my doorstep to prove it.", "You used my best pick to open a keg, snapped the head, and spilled ale through an entire crate of blasting powder.", "You rode a mine cart into a sealed tunnel. I crawled through the collapse and carried you out while you slept.", "You stole blasting powder from Morgrim's Claim to make fireworks above Ironspine Post. I stopped you before both outposts declared war.", "You slept beneath my counter and told customers they had discovered a new underground tavern.", "Replace the materials you scattered before we settle this.", "The stores are whole again. The matter is finished.")
    call RegisterVendorVoice(VL_GENERIC_TAUREN_MALE_3_TYPE, 1101, "GenericTaurenMale3", "You opened my private letters before a crowd and performed each one in a different voice. None of the voices were flattering.", "You scattered a week's deliveries to make a paper trail home, then forgot which end of the trail was mine.", "You climbed onto a moving caravan and passed out between its wheels. I stopped the team with one hand and pulled you free with the other.", "You stole a Riverbane courier seal and stamped free-ale orders across the harbor. The bandits traced every one back to my satchel.", "You wrapped yourself as a parcel addressed to tomorrow morning and demanded that I guarantee same-day delivery.", "Correct your foolish delivery before asking my forgiveness.", "The errand is complete. I forgive the confusion.")
    call RegisterVendorVoice(VL_GENERIC_TROLL_MALE_1_TYPE, 1001, "GenericTrollMale1", "Ya told all my buyers da gems were colored gravel, den begged me ta cut one shaped like ya magnificent head.", "Ya danced on my display case till it shattered and scattered two weeks of careful work through da mud.", "Ya climbed da ruins of Zul'Garok huntin' temple jewels. I dragged ya past da priests while ya shouted where we be hidin'.", "Ya stole a noble's ruby because it winked at ya. I swapped it back while ya distracted da watch by passin' out.", "Ya proposed marriage to my carved stone idol and blamed me when it kept a stony silence, mon.", "Fix what ya broke, mon, den maybe we be even.", "Ya made it right. We be even now.")
    call RegisterVendorVoice(VL_GENERIC_TROLL_MALE_2_TYPE, 1001, "GenericTrollMale2", "Ya called my remedies swamp water before da whole market, den drank da sample bowl and asked why da floor be movin'.", "Ya mixed every herb on my shelf into one cure for sobriety. It cured three insects and ruined all my stock.", "Ya followed bad mojo into da forest and nearly walked into a satyr camp. I carried ya out under a rain of arrows.", "Ya stole a serpent charm from Serpentshore. I returned it while ya loudly explained ta da naga how invisible we were.", "Ya tried ta trap smoke in ya pockets for later. Now every coat in my shop smell like ya bad decisions.", "Clean up ya bad mojo and come back when it done.", "Da bad mojo gone. I forgive ya this time.")
endfunction

endlibrary
