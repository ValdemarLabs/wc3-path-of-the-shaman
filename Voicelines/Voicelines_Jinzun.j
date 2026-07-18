/**
    VoicelinesJinzun

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
    Global `VL_JINZUN_*` constants.

**/
library VoicelinesJinzun requires Voicelines

globals
    constant string VL_JINZUN_FOLDER = "Jinzun"

    // Legacy Excel draft/reference rows.

    // Excel draft: OUTCAST JINZUN | Event: First time greet | Done: x
    constant string VL_JINZUN_0001_KEY = "Jinzun_0001"
    constant string VL_JINZUN_0001_TEXT = "Greetings, mon! Jin'Zun be here, wise in da ways of da spirits and da ancient arts."

    // Excel draft: OUTCAST JINZUN | Event: Goodbye | Done: x
    constant string VL_JINZUN_0002_KEY = "Jinzun_0002"
    constant string VL_JINZUN_0002_TEXT = "Safe travels, mon! May da spirits watch over ya, and may yer journey be filled with adventure and good fortune. Don't forget, Jin'Zun be here if ya ever need a friendly word or a bit of troll wisdom."

    // Excel draft: OUTCAST JINZUN | Event: Normal Greet | Done: x
    constant string VL_JINZUN_0003_KEY = "Jinzun_0003"
    constant string VL_JINZUN_0003_TEXT = "Farewell shaman. I be keepin' an eye on da forest."

    // Excel draft: OUTCAST JINZUN | Event: Random when near Jinzun | Done: x
    constant string VL_JINZUN_0005_KEY = "Jinzun_0005"
    constant string VL_JINZUN_0005_TEXT = "Hmmm... Where in da spirits' names did I be puttin' dose frog legs?! Da soup gonna taste like orc's ass without dem."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Intro | Done: x
    constant string VL_JINZUN_0012_KEY = "Jinzun_0012"
    constant string VL_JINZUN_0012_TEXT = "Nazgrek. Dis be an ancient forest, once mighty an' full o' life. But now, it be sufferin' from a dark plague, rotting away like a corpse in the sun."
    constant string VL_JINZUN_0013_KEY = "Jinzun_0013"
    constant string VL_JINZUN_0013_TEXT = "Trees I found... once standin' tall an' proud are now be twisted an' corrupted by some foul magic."
    constant string VL_JINZUN_0014_KEY = "Jinzun_0014"
    constant string VL_JINZUN_0014_TEXT = "But ya see, I be a voodoo shaman with a heart for healin', a healer of spirits an' a guardian of nature. I would be mendin' these trees meself, but me ol' back be screamin' louder than a murloc in heat. Too much trollin' in me younger days, ya know?"

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0015_KEY = "Jinzun_0015"
    constant string VL_JINZUN_0015_TEXT = "So, I devised a plan. I placed these magical runes near the trees, an' I've crafted potent Healing Wards to aid in their recovery. They be workin' wonders if placed at the runes."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0016_KEY = "Jinzun_0016"
    constant string VL_JINZUN_0016_TEXT = "Take dese wards, young shaman. Place 'em near the runes, an' watch as the magic mends the wounds of the forest. We need to halt this plague's advance before it spreads like wildfire."
    constant string VL_JINZUN_0017_KEY = "Jinzun_0017"
    constant string VL_JINZUN_0017_TEXT = "Remember, --the spirits be watchin', an' the forest be relyin' on us."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0018_KEY = "Jinzun_0018"
    constant string VL_JINZUN_0018_TEXT = "Ya be refusin' to lend a hand, eh? Well, suit yerself, Nazgrek. --But mark me words, dis plague be spreadin' like wildfire, and da spirits won't be pleased with a blind eye turned."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Unfinished / need new wards | Done: x
    constant string VL_JINZUN_0019_KEY = "Jinzun_0019"
    constant string VL_JINZUN_0019_TEXT = "Ah, Nazgrek, ya be back, eh? But where be da mended aura of da forest, mon? Da trees still be sufferin'."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Unfinished / new wards given | Done: x
    constant string VL_JINZUN_0020_KEY = "Jinzun_0020"
    constant string VL_JINZUN_0020_TEXT = "Time be tickin', Nazgrek. If ya still got dat itch to be a hero, go place dose Healing Wards by da runes near da trees. We can't be lettin' the plague take root deeper in our precious forest. The spirits be watchin', and so am I."

    // Excel draft: OUTCAST JINZUN | Quest: Plaguo Upon Trees | Event: Completion | Done: x
    constant string VL_JINZUN_0021_KEY = "Jinzun_0021"
    constant string VL_JINZUN_0021_TEXT = "Ah, Nazgrek! I be feelin' da shift in da spirits, a healin' energy in da air. Did ya place dem Healing Wards like Jin'Zun suggested? Me old bones be tellin' me ya brought balance back to da forest."
    constant string VL_JINZUN_0022_KEY = "Jinzun_0022"
    constant string VL_JINZUN_0022_TEXT = "What's dat ya say? Ya spotted some weird cultists lurkin' 'round da trees? Performing dark rituals, ya say? Now dat be troublin' news, indeed."
    constant string VL_JINZUN_0023_KEY = "Jinzun_0023"
    constant string VL_JINZUN_0023_TEXT = "We be needin' to investigate dis matter further. Together, we'll uncover da shadows and solve da mystery."

    // Excel draft: OUTCAST JINZUN | Quest: Unknown Entity | Event: Intro | Done: x
    constant string VL_JINZUN_0030_KEY = "Jinzun_0030"
    constant string VL_JINZUN_0030_TEXT = "Ah, Nazgrek! Dere be trouble brewin' at da heart of da lake. Jin'Zun was out fishin', enjoyin' da serenity, when out of nowhere, disgustin' tentacles shot up from da water like a hungry sea serpent's jaws."
    constant string VL_JINZUN_0031_KEY = "Jinzun_0031"
    constant string VL_JINZUN_0031_TEXT = "Nearly got me, they did! But Jin'Zun be quick with his staff, givin' 'em a taste of trollish might. Now, dere be an unknown entity, somethin' alien and unnatural, lurkin' in da depths."

    // Excel draft: OUTCAST JINZUN | Quest: Unknown Entity | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0032_KEY = "Jinzun_0032"
    constant string VL_JINZUN_0032_TEXT = "Investigate dat center of da lake, discover what be lurkin' there, and return with information... An' whether I can go fish some tasty fish in ma favorite spot, mon."

    // Excel draft: OUTCAST JINZUN | Quest: Unknown Entity | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0033_KEY = "Jinzun_0033"
    constant string VL_JINZUN_0033_TEXT = "I trust ya can handle whatever dark forces be at play. Be cautious, mon, and may da spirits guide yer steps. For da safety of da forest, for da balance, and for da sake of Jin'Zun's favorite fishin' spot! Off ya go!"

    // Excel draft: OUTCAST JINZUN | Quest: Unknown Entity | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0034_KEY = "Jinzun_0034"
    constant string VL_JINZUN_0034_TEXT = "Ya be turnin' yer back on Jin'Zun's plea to investigate da disturbance at da lake, eh? If ya change yer mind, come back and join me for a fishin' trip. Just remember, when da tentacles start givin' me grief, I'll be blamin' it on your lack of trollish camaraderie."

    // Excel draft: OUTCAST JINZUN | Quest: Unknown Entity | Event: Completion | Done: x
    constant string VL_JINZUN_0035_KEY = "Jinzun_0035"
    constant string VL_JINZUN_0035_TEXT = "Did ya put an end to whatever foul creature be lurkin' in da lake? Me stomach be itching for som tasty fishy!"
    constant string VL_JINZUN_0036_KEY = "Jinzun_0036"
    constant string VL_JINZUN_0036_TEXT = "Oooh... Good work, Nazgrek! Ya showed dat entity da might of a troll with voodoo in his veins. Now, da lake be free from its foul grasp, and da spirits be singin' a song of gratitude."
    constant string VL_JINZUN_0037_KEY = "Jinzun_0037"
    constant string VL_JINZUN_0037_TEXT = "Disgustin' slime, ya say? Well, better dat than tentacles pokin' out when I'm tryin' to enjoy me favorite fishin' spot! Jin'Zun be promisin' to study it, unravel its mysteries, and glean any knowledge dat can aid us anyway. Fear not, young shaman, this troll be da best at mixin' brews and decipherin' da language of da spirits. This slime be holdin' a tale, and I'll make sure to read every drop of it!"

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt / Sargoth Ichor | Event: Intro | Done: x
    constant string VL_JINZUN_0046_KEY = "Jinzun_0046"
    constant string VL_JINZUN_0046_TEXT = "The trees, dey be whisperin' tales of nasty spiders, crafty and deadly, lurkin' in every nook and cranny."

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt | Event: Intro | Done: x
    constant string VL_JINZUN_0047_KEY = "Jinzun_0047"
    constant string VL_JINZUN_0047_TEXT = "Spiders, mon! Dey be weavin' webs in the trees, venomous fangs ready to strike. Dey be guardians of ancient knowledge, protectors of the unseen. Beware, for dis be no ordinary woods."
    constant string VL_JINZUN_0048_KEY = "Jinzun_0048"
    constant string VL_JINZUN_0048_TEXT = "Sargoth, mon, she be more than just a spider. Her ichor, da essence of her bein', is a potent elixir. Drink it, and ya shall feel the surge of troll power, boostin' yer levels beyond imagination.\""

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0049_KEY = "Jinzun_0049"
    constant string VL_JINZUN_0049_TEXT = "Will ya dare to face da tangled shadows, confront the venomous spiders, and claim the ichor of Sargoth?"

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0050_KEY = "Jinzun_0050"
    constant string VL_JINZUN_0050_TEXT = "Ah, dat be da spirit, hero! Brave and bold, ready to dance with da shadows."

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0051_KEY = "Jinzun_0051"
    constant string VL_JINZUN_0051_TEXT = "Hmmm... so ya choose to walk away, eh? Maybe dis path be too twisted for yer likin'. Perhaps one day, ya may find da courage to face da tangled web dat awaits."

    // Excel draft: OUTCAST JINZUN | Quest: Sargoth / Spider hunt | Event: Completion | Done: x
    constant string VL_JINZUN_0052_KEY = "Jinzun_0052"
    constant string VL_JINZUN_0052_TEXT = "It is you shaman! I sense da power in ya steps. Ya managed to dance with da spiders, face Sargoth, and emerge victorious. Show me dat ichor, let me gaze upon da essence of true mojo elixir!"
    constant string VL_JINZUN_0053_KEY = "Jinzun_0053"
    constant string VL_JINZUN_0053_TEXT = "I be sharin' ya a recipe for a mighty flask, mon. One of da ingredients be spider's ichor. But mind ya, ya gonna need a well-preserved sample for dat flask to pack a punch. Farewell for now, young shaman"

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead | Event: Intro | Done: x
    constant string VL_JINZUN_0069_KEY = "Jinzun_0069"
    constant string VL_JINZUN_0069_TEXT = "Hey Nazgrek! Nazgrek!"
    constant string VL_JINZUN_0070_KEY = "Jinzun_0070"
    constant string VL_JINZUN_0070_TEXT = "Nazgrek, da forest be whisperin' me a rumor, mon. Dere be an old crypt where da dead ain't stayin' dead no more. Dem cultists ya slain, dey likely be playin' a part in dis... monstrosity."
    constant string VL_JINZUN_0071_KEY = "Jinzun_0071"
    constant string VL_JINZUN_0071_TEXT = "If da rumors be true mon, dere be no tellin' what horrors await deep in da halls of da dead."
    constant string VL_JINZUN_0072_KEY = "Jinzun_0072"
    constant string VL_JINZUN_0072_TEXT = "Only ting I be askin' from ya, young shaman, is dat ya check for signs of da livin' dead. A movin' body part from a walkin' corpse could do, ya know, as long as it be still itchin'."

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0073_KEY = "Jinzun_0073"
    constant string VL_JINZUN_0073_TEXT = "Ya might wanna bring some company wit' ya if ya goin' deeper into dem catacombs, mon."

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0074_KEY = "Jinzun_0074"
    constant string VL_JINZUN_0074_TEXT = "I be knowin' it all soundin' frightenin', but ya be prob'ly our only hope, mon. I'd go myself if I wasn't so... elder, ya know."

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0075_KEY = "Jinzun_0075"
    constant string VL_JINZUN_0075_TEXT = "Da crypt be sittin' in da south-east of here. In da Dead Woods, dey be sayin'..."
    constant string VL_JINZUN_0076_KEY = "Jinzun_0076"
    constant string VL_JINZUN_0076_TEXT = "When ya tread into da cursed forest of Dead Woods, watch out for da wanderin' dark goliath Garr! Unda any circumstance, mon, don't be crossin' its path... Dat beast be reckless!"

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead | Event: Completion | Done: x
    constant string VL_JINZUN_0077_KEY = "Jinzun_0077"
    constant string VL_JINZUN_0077_TEXT = "Yikes! Dis bloody ting... IT IS still kickin' and breathin', even though it be rotten to da core!"
    constant string VL_JINZUN_0078_KEY = "Jinzun_0078"
    constant string VL_JINZUN_0078_TEXT = "I see... I be feelin'... argh!!! Agony and torment! Da crypt be swarmin' wit' undead. Dark rituals and necromancy! De place needs to be purged!"

    // Excel draft: OUTCAST JINZUN | Quest: The Resurgence of The Dead / PART II | Done: x
    constant string VL_JINZUN_0084_KEY = "Jinzun_0084"
    constant string VL_JINZUN_0084_TEXT = "Gather ya allies! Gather ya strength! Face da evil within da Crypt and free da poor souls from their misery. I be grantin' my blessin' to aid ya in ya battle!"
    constant string VL_JINZUN_0085_KEY = "Jinzun_0085"
    constant string VL_JINZUN_0085_TEXT = "Spirits around me! Grant ya sacred blessin' to Nazgrek and his allies!"
    constant string VL_JINZUN_0086_KEY = "Jinzun_0086"
    constant string VL_JINZUN_0086_TEXT = "Dere be no words to describe da achievement ya pulled off, Nazgrek! Not only did ya prevent evil necromancy and corruption from spreadin', but ya also laid da crypt into proper rest."
    constant string VL_JINZUN_0087_KEY = "Jinzun_0087"
    constant string VL_JINZUN_0087_TEXT = "Here be ya reward. Ya can come back to me anytime if ya be needin' my blessin' for da adventures to come."

    // Excel draft: OUTCAST JINZUN | Quest: Succubus / chains of seduction | Event: dispel | Done: x
    constant string VL_JINZUN_0100_KEY = "Jinzun_0100"
    constant string VL_JINZUN_0100_TEXT = "By de spirits! What foul magic grips ya, mon!"
    constant string VL_JINZUN_0101_KEY = "Jinzun_0101"
    constant string VL_JINZUN_0101_TEXT = "I'll dispel dis curse dat binds ya, but ya best be handlin' the succubus behind ya."

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Intro | Done: x
    constant string VL_JINZUN_0110_KEY = "Jinzun_0110"
    constant string VL_JINZUN_0110_TEXT = "Ahhh, dere ya are, mi friend! Good to see ya, an' I know ya always got a minute for ol' Jin'Zun!"
    constant string VL_JINZUN_0111_KEY = "Jinzun_0111"
    constant string VL_JINZUN_0111_TEXT = "Remember da time ya helped chase dem foul creatures from me fishin' spot? Well, now another trouble's come... Me favorite fishin' pole is missin'!"
    constant string VL_JINZUN_0112_KEY = "Jinzun_0112"
    constant string VL_JINZUN_0112_TEXT = "Now, I got me eye on dem sneaky kobolds by the old mine; dey always be snatchin' anything shiny or smellin' like fish. But... could be dat trickster satyr again! Can't trust a creature with hooves an' a laugh like dat, ya know?"

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0113_KEY = "Jinzun_0113"
    constant string VL_JINZUN_0113_TEXT = "Either way, me pole is gone, an' I need it back! Can't catch a single fish wit'out it, and me hands gettin' twitchy! So, if ya don't mind, bring it back for ol' Jin'Zun... before I start fishin' with me hat, an' dat ain't a good look for me!"

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0114_KEY = "Jinzun_0114"
    constant string VL_JINZUN_0114_TEXT = "Aww, come on now, mon!"

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0115_KEY = "Jinzun_0115"
    constant string VL_JINZUN_0115_TEXT = "Ahhh, dat's da spirit, mi friend! I knew I could count on ya! Ya check da mine where da kobolds be... but don't forget, dem satyrs might be up to somethin' too!"

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Unfinished | Done: x
    constant string VL_JINZUN_0116_KEY = "Jinzun_0116"
    constant string VL_JINZUN_0116_TEXT = "Hmm... Still no pole, mon? Ya sure dem kobolds ain't playin' tricks on ya?"

    // Excel draft: OUTCAST JINZUN | Quest: Jin'Zun's Fishing Pole | Event: Completion | Done: x
    constant string VL_JINZUN_0117_KEY = "Jinzun_0117"
    constant string VL_JINZUN_0117_TEXT = "Ahhh, dere it is! Me precious pole! Ya done it again, mi friend! Dis one be special, I tell ya! I can already feel da fish beggin' to be caught."
    constant string VL_JINZUN_0118_KEY = "Jinzun_0118"
    constant string VL_JINZUN_0118_TEXT = "Here's somethin' nice for ya-don't be shy, take it! I be takin' me pole to da Jin'Zun's favorite fish spot now, so if ya need me, ya know where to find me."

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Intro | Done: x
    constant string VL_JINZUN_0120_KEY = "Jinzun_0120"
    constant string VL_JINZUN_0120_TEXT = "Ahh, Nazgrek."
    constant string VL_JINZUN_0121_KEY = "Jinzun_0121"
    constant string VL_JINZUN_0121_TEXT = "Even wit' all we done to heal dem mighty dead trees, dere still be work left, mon."
    constant string VL_JINZUN_0122_KEY = "Jinzun_0122"
    constant string VL_JINZUN_0122_TEXT = "Da Healing Wards stopped da plague from spreadin', but da blight clings stubbornly to da land like a leech to a beast."
    constant string VL_JINZUN_0123_KEY = "Jinzun_0123"
    constant string VL_JINZUN_0123_TEXT = "While ya was away, Nazgrek, I stumbled on some strange seeds, filled wit' da spirit's power, mon."
    constant string VL_JINZUN_0124_KEY = "Jinzun_0124"
    constant string VL_JINZUN_0124_TEXT = "Dese seeds, dey got da power to revive da dead trees an' purify da blight for good."

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Intro / help yes or no | Done: x
    constant string VL_JINZUN_0125_KEY = "Jinzun_0125"
    constant string VL_JINZUN_0125_TEXT = "But me ol' back still ain't what it used to be, so I need ya to do da plantin', mon. What say ya, Nazgrek? Will ya help dis old fool once again?"

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Intro / decline | Done: x
    constant string VL_JINZUN_0126_KEY = "Jinzun_0126"
    constant string VL_JINZUN_0126_TEXT = "When ya ready to answer da call, come back to Jin'Zun. Dis forest, it needs ya."

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Intro / accept | Done: x
    constant string VL_JINZUN_0128_KEY = "Jinzun_0128"
    constant string VL_JINZUN_0128_TEXT = "Good good! Plant da seeds deep in da earth. Watch as da land comes alive again."

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Unfinished | Done: x
    constant string VL_JINZUN_0129_KEY = "Jinzun_0129"
    constant string VL_JINZUN_0129_TEXT = "Da seeds, Nazgrek-they ain't gonna last forever, mon. Who knows how old dey be? Could have a best-before date... Act quick, or we might lose da chance to save da forest!"

    // Excel draft: OUTCAST JINZUN | Quest: Seeds of Life | Event: Completion | Done: x
    constant string VL_JINZUN_0130_KEY = "Jinzun_0130"
    constant string VL_JINZUN_0130_TEXT = "Ya done good, mon, real good. Da blight, it fades, and da spirits sing praise for ya efforts"
    constant string VL_JINZUN_0131_KEY = "Jinzun_0131"
    constant string VL_JINZUN_0131_TEXT = "But... somethin' still lingers, a shadow creepin' far from da forest. Could be connected to dem cultists ya mentioned before. Jin'Zun gonna investigate..."
endglobals

endlibrary
