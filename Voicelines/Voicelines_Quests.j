/**
    VoicelinesQuests

    Author: Valdemar
    Version: 3.1.0

    Description:
    Central source of truth for reusable and vendor quest dialogue, random
    daily acceptance pools, normal-quest extensions, and ExSound registration.

    Credits:

    How to install:
    Import after QuestsGeneric and ExSound.

    API:
    - VL_VENDORQUEST_* constants contain authored vendor quest dialogue.
    - Daily objective and voice variants register automatically.

**/
library VoicelinesQuests initializer Init requires QuestsGeneric, ExSound
    globals
        constant string VL_VENDORQUEST_ORC_TYPE = "VendorQuestOrc_"
        constant string VL_VENDORQUEST_SATYR_TYPE = "VendorQuestSatyr_"
        constant string VL_VENDORQUEST_HUMAN_TYPE = "VendorQuestHuman_"
        constant string VL_VENDORQUEST_GOBLIN_TYPE = "VendorQuestGoblin_"
        constant string VL_VENDORQUEST_BONECRUSHER_TYPE = "VendorQuestBonecrusher_"
        constant string VL_VENDORQUEST_ELARINDOR_TYPE = "VendorQuestElarindor_"
        constant string VL_VENDORQUEST_TAUREN_TYPE = "VendorQuestTauren_"

        // Shared unvoiced hero and progress dialogue.
        constant string VL_QUEST_HERO_ACCEPT = "I will see it done."
        constant string VL_QUEST_HERO_COMPLETE_KILL = "The threat has been dealt with."
        constant string VL_QUEST_HERO_COMPLETE_TALK = "I spoke with the one you named."
        constant string VL_QUEST_HERO_COMPLETE_FETCH = "I brought what you asked for."
        constant string VL_QUEST_HERO_PROGRESS = "What remains to be done?"
        constant string VL_QUEST_GIVER_PROGRESS = "I am still waiting on "
        constant string VL_QUEST_HERO_REQUEST_SUPPLY = "I was sent to collect the supplies you are holding."
        constant string VL_QUEST_HERO_ASK_TO_BUY = "I was told you carry the item needed for this commission."
        constant string VL_QUEST_VENDOR_HANDOFF = "It is ready. Take it back to the one who sent you."
        constant string VL_QUEST_VENDOR_ALREADY_HANDED_OFF = "I already gave you the parcel. Keep it safe until you deliver it."
        constant string VL_QUEST_VENDOR_PURCHASE = "It is in my regular stock. Buy it through trade, then return it to your quest giver."

        // Horde Tauren quest dialogue.
        constant string VL_VENDORQUEST_TAUREN_0001 = "The warforge needs eight bundles of clean fuel before the evening hammers begin."
        constant string VL_VENDORQUEST_TAUREN_0002 = "The fire will burn steadily. Every weapon shaped tonight carries part of your labor."
        constant string VL_VENDORQUEST_TAUREN_0003 = "Bring six pieces of dense ore from stone that has not been weakened by corruption."
        constant string VL_VENDORQUEST_TAUREN_0004 = "Good weight and a clean grain. The mountain yielded honestly to you."
        constant string VL_VENDORQUEST_TAUREN_0005 = "Eight gnolls are circling the supply trail. Clear them before another pack animal is lost."
        constant string VL_VENDORQUEST_TAUREN_0006 = "The trail breathes freely again. The next caravan will pass beneath a quieter sky."
        constant string VL_VENDORQUEST_TAUREN_0007 = "Shadowdancers stalk the long road ahead. Defeat eight before they learn our travelling rhythm."
        constant string VL_VENDORQUEST_TAUREN_0008 = "Their shadows have withdrawn. The road remembers the strength of your steps."

        // Bonecrusher Ogre quest dialogue.
        constant string VL_VENDORQUEST_BONECRUSHER_0001 = "Stalkers scratch weapon carts. Break seven stalkers. Carts stop scratching."
        constant string VL_VENDORQUEST_BONECRUSHER_0002 = "Good breaking. Mugrak's carts roll safe now."
        constant string VL_VENDORQUEST_BONECRUSHER_0003 = "Dorga needs six thick hides. Thin hide tears when ogre sneezes."
        constant string VL_VENDORQUEST_BONECRUSHER_0004 = "Thick enough. Dorga makes armor that survives two sneezes."
        constant string VL_VENDORQUEST_BONECRUSHER_0005 = "Krunn needs five heavy rocks with metal inside. Shield must be heavier than Krunn."
        constant string VL_VENDORQUEST_BONECRUSHER_0006 = "Good metal. Shield will fall over before it breaks."
        constant string VL_VENDORQUEST_BONECRUSHER_0007 = "Borlug has pit supplies. Bring crate here. Do not eat crate."
        constant string VL_VENDORQUEST_BONECRUSHER_0008 = "Crate full. Fighters eat contents. Maybe crate later."
        constant string VL_VENDORQUEST_BONECRUSHER_0009 = "Pot is big. Stew is small. Bring ten meats and make stew big."
        constant string VL_VENDORQUEST_BONECRUSHER_0010 = "Now stew is big. Hukka knew pot was not problem."
        constant string VL_VENDORQUEST_BONECRUSHER_0011 = "A weapon earns its name by surviving what should break it. Crush twelve stalkers with Bonecrusher steel."
        constant string VL_VENDORQUEST_BONECRUSHER_0012 = "Twelve broken stalkers. Weapon has good name now."
        constant string VL_VENDORQUEST_BONECRUSHER_0013 = "Bring it back when bigger enemy scratches it. Mugrok wants to see."
        constant string VL_VENDORQUEST_BONECRUSHER_0014 = "Mugrok remembers strong hands. Strong hands get strong steel."
        constant string VL_VENDORQUEST_BONECRUSHER_0015 = "This is not one-night stew. This is stew people remember after winter."
        constant string VL_VENDORQUEST_BONECRUSHER_0016 = "Hukka saves best bowl for you. Maybe second-best. Hukka still hungry."

        // Elarindor quest dialogue.
        constant string VL_VENDORQUEST_ELARINDOR_0001 = "The wraiths circle closer whenever the forge burns. Destroy six before their hunger reaches the anvils."
        constant string VL_VENDORQUEST_ELARINDOR_0002 = "The forge-light holds steady again. Elarindor owes you a quieter night."
        constant string VL_VENDORQUEST_ELARINDOR_0003 = "Five stable mana crystals should be enough to renew the outer wards. Handle them gently; they remember every careless touch."
        constant string VL_VENDORQUEST_ELARINDOR_0004 = "Their light is clean and steady. These fragments will guard living memories, not merely ruins."
        constant string VL_VENDORQUEST_ELARINDOR_0005 = "The wardens have exhausted yesterday's draughts. Bring eight fresh herbs before the morning dew leaves them."
        constant string VL_VENDORQUEST_ELARINDOR_0006 = "These still carry the dawn's strength. The wardens will stand easier because of you."
        constant string VL_VENDORQUEST_ELARINDOR_0007 = "Sylvaris has completed the reagent inventory. Bring the sealed ledger here before another emergency changes the count."
        constant string VL_VENDORQUEST_ELARINDOR_0008 = "Every measure accounted for. Order may be modest, but it is how Elarindor begins again."
        constant string VL_VENDORQUEST_ELARINDOR_0009 = "Seven mana crystals remain buried among the fallen forge-stones. Recover them before the wraiths drain their memory."
        constant string VL_VENDORQUEST_ELARINDOR_0010 = "Their light still carries the forge's old cadence. You have returned more than mere crystal."
        constant string VL_VENDORQUEST_ELARINDOR_0011 = "Each fragment will be set where the first smiths once worked, so their craft may guide ours again."
        constant string VL_VENDORQUEST_ELARINDOR_0012 = "When the forge burns tonight, its flame will remember your part in its restoration."
        constant string VL_VENDORQUEST_ELARINDOR_0013 = "Ten wraiths have learned the paths between our supply wards. End them before they turn scarcity into disaster."
        constant string VL_VENDORQUEST_ELARINDOR_0014 = "The ward paths are quiet. Our people can move what they need without feeding the dead."
        constant string VL_VENDORQUEST_ELARINDOR_0015 = "A quartermaster counts more than crates; she counts every life those crates must sustain."
        constant string VL_VENDORQUEST_ELARINDOR_0016 = "Elarindor will remember that its stores remained open because you stood between duty and ruin."

        // Goblin quest dialogue.
        constant string VL_VENDORQUEST_GOBLIN_0001 = "Essence prices are about to explode! Bring me five measures before everyone else notices."
        constant string VL_VENDORQUEST_GOBLIN_0002 = "Perfect timing. If anyone asks, I predicted this weeks ago."
        constant string VL_VENDORQUEST_GOBLIN_0003 = "Tink owes me a trade bundle. Collect it, and do not agree to any extra fees."
        constant string VL_VENDORQUEST_GOBLIN_0004 = "You paid no surprise fee? Hah! Tink must be losing his edge."
        constant string VL_VENDORQUEST_GOBLIN_0005 = "My blades are guaranteed against nine gnolls or your effort back. Go test the claim."
        constant string VL_VENDORQUEST_GOBLIN_0006 = "Nine gnolls and no complaint from the blade. Another satisfied demonstration!"
        constant string VL_VENDORQUEST_GOBLIN_0007 = "A buyer wants nine fish immediately, which means I wanted them five minutes ago!"
        constant string VL_VENDORQUEST_GOBLIN_0008 = "Still wet and only slightly late. That counts as premium service."
        constant string VL_VENDORQUEST_GOBLIN_0009 = "Eight pieces of iron ore and I can close a very profitable future sale."
        constant string VL_VENDORQUEST_GOBLIN_0010 = "Excellent! Now I only need the future buyer to actually exist."
        constant string VL_VENDORQUEST_GOBLIN_0011 = "The skewers sold out! Bring seven cuts of meat before customers discover patience."
        constant string VL_VENDORQUEST_GOBLIN_0012 = "Back in business. Nothing improves appetite like limited supply."
        constant string VL_VENDORQUEST_GOBLIN_0013 = "Ten shadowdancers. Beat that number and I will call you marketable."
        constant string VL_VENDORQUEST_GOBLIN_0014 = "Marketable, dangerous, and still alive. That is a profitable combination."
        constant string VL_VENDORQUEST_GOBLIN_0015 = "Fizzik has one crystal shipment marked for me. Ignore anything he says about interest."
        constant string VL_VENDORQUEST_GOBLIN_0016 = "The right shipment and no scorch marks. A remarkably clean transaction."
        constant string VL_VENDORQUEST_GOBLIN_0017 = "My best cart route is full of shadowdancers. Remove twelve and I can call it a premium guarded road."
        constant string VL_VENDORQUEST_GOBLIN_0018 = "Twelve fewer ambushers means twelve fewer insurance claims. Outstanding work!"
        constant string VL_VENDORQUEST_GOBLIN_0019 = "Keep this up and I might name a surcharge after you."
        constant string VL_VENDORQUEST_GOBLIN_0020 = "The cart rolls tomorrow, and every safe wheel-turn is profit we can count."
        constant string VL_VENDORQUEST_GOBLIN_0021 = "Eight measures of essence today could be worth a fortune next season. Secure my long investment."
        constant string VL_VENDORQUEST_GOBLIN_0022 = "Excellent! Now patience does the work while I take the credit."
        constant string VL_VENDORQUEST_GOBLIN_0023 = "Short trades buy dinner. Long investments buy the restaurant."
        constant string VL_VENDORQUEST_GOBLIN_0024 = "When this pays off, remember who generously allowed you to help."
        constant string VL_VENDORQUEST_GOBLIN_0025 = "The arena remembers spectacle longer than mercy. Give the crowd a story worth repeating."
        constant string VL_VENDORQUEST_GOBLIN_0026 = "Your name sells tickets now. I consider that a successful partnership."

        // Human quest dialogue.
        constant string VL_VENDORQUEST_HUMAN_0001 = "The patrols have bent half my stock. Six pieces of iron ore will put us ahead again."
        constant string VL_VENDORQUEST_HUMAN_0002 = "Good ore. I can turn this into something the patrols might not ruin immediately."
        constant string VL_VENDORQUEST_HUMAN_0003 = "The watch returned with more holes than armor. Bring seven pieces of leather for patches."
        constant string VL_VENDORQUEST_HUMAN_0004 = "These will hold. At least until the watch finds another briar patch."
        constant string VL_VENDORQUEST_HUMAN_0005 = "Gnolls keep clawing at the test palisade. Remove seven before they damage the new shields."
        constant string VL_VENDORQUEST_HUMAN_0006 = "The palisade is quiet, and the dents now come from proper testing."
        constant string VL_VENDORQUEST_HUMAN_0007 = "Stormhaven expects fish on every table tonight. Bring me eight from a clean catch."
        constant string VL_VENDORQUEST_HUMAN_0008 = "Fresh and firm. The innkeepers will stop shouting for an hour."
        constant string VL_VENDORQUEST_HUMAN_0009 = "The smokehouse has room for six more cuts. Bring them while the coals are ready."
        constant string VL_VENDORQUEST_HUMAN_0010 = "Perfect timing. These can go straight onto the hooks."
        constant string VL_VENDORQUEST_HUMAN_0011 = "Seven bundles of fuel should keep the lower galleries lit through the shift."
        constant string VL_VENDORQUEST_HUMAN_0012 = "Dry and tightly packed. Nobody gets lost in the dark today."
        constant string VL_VENDORQUEST_HUMAN_0013 = "Elias has today's travelling manifest. Bring the sealed copy back to me."
        constant string VL_VENDORQUEST_HUMAN_0014 = "The figures match our ledger. That is rarer than it ought to be."
        constant string VL_VENDORQUEST_HUMAN_0015 = "Nine dark trolls have turned my best road into their private toll gate. Clear it."
        constant string VL_VENDORQUEST_HUMAN_0016 = "The road is open. Trade will follow, and trouble will follow trade."
        constant string VL_VENDORQUEST_HUMAN_0017 = "I need eight fresh herbs before their morning potency fades."
        constant string VL_VENDORQUEST_HUMAN_0018 = "Still fragrant and full of sap. These will brew beautifully."
        constant string VL_VENDORQUEST_HUMAN_0019 = "Riverbane needs ten pieces of dense ore held in reserve for the day the palisade truly breaks."
        constant string VL_VENDORQUEST_HUMAN_0020 = "This is the kind of reserve that lets a smith promise tomorrow's weapons today."
        constant string VL_VENDORQUEST_HUMAN_0021 = "Storehouses win sieges before the first horn sounds. I intend ours to be ready."
        constant string VL_VENDORQUEST_HUMAN_0022 = "Riverbane can sleep easier knowing this steel waits beneath lock and key."
        constant string VL_VENDORQUEST_HUMAN_0023 = "The deepwater tables expect twelve storm fish, not excuses from captains who stayed near shore."
        constant string VL_VENDORQUEST_HUMAN_0024 = "A true deepwater catch. Stormhaven will taste the difference tonight."
        constant string VL_VENDORQUEST_HUMAN_0025 = "Bring them in cold and clean; a good table honors the water that filled it."
        constant string VL_VENDORQUEST_HUMAN_0026 = "The harbor cooks will speak of this catch long after the platters are empty."
        constant string VL_VENDORQUEST_HUMAN_0027 = "A safe road is a promise renewed by every traveler who reaches home."
        constant string VL_VENDORQUEST_HUMAN_0028 = "Trade returns first, then families. You have given both a reason to trust this road."

        // Orc quest dialogue.
        constant string VL_VENDORQUEST_ORC_0001 = "A sharp blade starts with honest ore. Bring me five pieces before the forge cools."
        constant string VL_VENDORQUEST_ORC_0002 = "Good weight, clean grain. These will make blades worth carrying."
        constant string VL_VENDORQUEST_ORC_0003 = "Shadowdancers keep cutting apart my caravans. Cut down six of them first."
        constant string VL_VENDORQUEST_ORC_0004 = "That should buy my haulers a quiet road for one more night."
        constant string VL_VENDORQUEST_ORC_0005 = "A shield without good straps is just a dinner plate. Bring me six pieces of leather."
        constant string VL_VENDORQUEST_ORC_0006 = "Strong enough to hold when the whole line gets hit. Well done."
        constant string VL_VENDORQUEST_ORC_0007 = "The ring has no room for stiff fighters. Warm up on eight gnolls and come back standing."
        constant string VL_VENDORQUEST_ORC_0008 = "Blood moving, eyes clear. Now you might survive a real bout."
        constant string VL_VENDORQUEST_ORC_0009 = "The shallow rock is picked clean. I need four chunks from a deeper vein."
        constant string VL_VENDORQUEST_ORC_0010 = "Heavy, dark, and full of promise. This is proper mountain ore."
        constant string VL_VENDORQUEST_ORC_0011 = "Every forge is hungry today. Bring eight bundles of fuel before the flames gutter."
        constant string VL_VENDORQUEST_ORC_0012 = "Good. The hammers can keep singing until morning."
        constant string VL_VENDORQUEST_ORC_0013 = "Rukha carries a tool crate meant for me. Fetch one from the road merchant and bring it back."
        constant string VL_VENDORQUEST_ORC_0014 = "No cracks in the haft and the head is straight. Exactly what I ordered."
        constant string VL_VENDORQUEST_ORC_0015 = "Dark trolls are charging a toll on my best route. Answer with seven broken toll collectors."
        constant string VL_VENDORQUEST_ORC_0016 = "The road belongs to paying customers again. Here is your cut."
        constant string VL_VENDORQUEST_ORC_0017 = "Vargan has a parcel for my next run. Pick it up before he puts it back on the shelf."
        constant string VL_VENDORQUEST_ORC_0018 = "Still sealed. Good work keeping curious hands out of it."
        constant string VL_VENDORQUEST_ORC_0019 = "The evening pot is all broth and no bite. Bring six cuts of meat."
        constant string VL_VENDORQUEST_ORC_0020 = "Fresh enough. By sunset this will feed every hungry guard."
        constant string VL_VENDORQUEST_ORC_0021 = "The smoke racks are empty. Bring eight good fish before the jungle heat spoils them."
        constant string VL_VENDORQUEST_ORC_0022 = "Fine catch. These will travel farther than most merchants do."
        constant string VL_VENDORQUEST_ORC_0023 = "Satyr raiders found the coastal stores. Kill ten before they learn what we keep there."
        constant string VL_VENDORQUEST_ORC_0024 = "The stores are safe and the clan's supplies stay in clan hands."
        constant string VL_VENDORQUEST_ORC_0025 = "Steel proves nothing on an anvil alone. Spill twelve dark trolls and let this blade earn its temper."
        constant string VL_VENDORQUEST_ORC_0026 = "The edge held and the trolls did not. That is steel worth naming."
        constant string VL_VENDORQUEST_ORC_0027 = "Carry the lesson: a weapon is finished only after battle answers the smith."
        constant string VL_VENDORQUEST_ORC_0028 = "Kargun will remember who gave this steel its first true scars."
        constant string VL_VENDORQUEST_ORC_0029 = "Gnolls have taken ten bites from my longest route. Take the road's payment back in blood."
        constant string VL_VENDORQUEST_ORC_0030 = "The road is open and my wheels will not slow for scavengers again."
        constant string VL_VENDORQUEST_ORC_0031 = "A merchant remembers every mile bought by another warrior's courage."
        constant string VL_VENDORQUEST_ORC_0032 = "When my caravan crosses safely, your work travels with every crate."
        constant string VL_VENDORQUEST_ORC_0033 = "Coastal stores feed warriors far beyond the jungle. Guarding them guards the whole line."
        constant string VL_VENDORQUEST_ORC_0034 = "The clan will eat, march, and fight because those stores still stand."

        // Satyr quest dialogue.
        constant string VL_VENDORQUEST_SATYR_0001 = "Six stalkers have mistaken themselves for champions. Correct their delusion."
        constant string VL_VENDORQUEST_SATYR_0002 = "Their silence is more convincing than their boasting ever was."
        constant string VL_VENDORQUEST_SATYR_0003 = "My clients demand five flawless crystals and dislike being kept waiting."
        constant string VL_VENDORQUEST_SATYR_0004 = "Acceptable clarity. Their origins are no concern of yours."
        constant string VL_VENDORQUEST_SATYR_0005 = "Bring four measures of essence. Curiosity will not increase your payment."
        constant string VL_VENDORQUEST_SATYR_0006 = "You brought the essence and spared me questions. A rare combination."
        constant string VL_VENDORQUEST_SATYR_0007 = "Selyth holds a sealed flask for my runes. Bring it here without tasting it."
        constant string VL_VENDORQUEST_SATYR_0008 = "The seal remains intact. Perhaps you possess restraint after all."
        constant string VL_VENDORQUEST_SATYR_0009 = "Seven bitter leaves. Green, unbruised, and preferably not covered in orc fingerprints."
        constant string VL_VENDORQUEST_SATYR_0010 = "The leaves survived your handling. An unexpectedly pleasant result."
        constant string VL_VENDORQUEST_SATYR_0011 = "Soulstealers have made the old path tiresome. Remove eight and I may travel it again."
        constant string VL_VENDORQUEST_SATYR_0012 = "The path feels almost civilized now. Do not expect that feeling to last."
        constant string VL_VENDORQUEST_SATYR_0013 = "Eight water crystals would complete a collection whose final purpose need not trouble you."
        constant string VL_VENDORQUEST_SATYR_0014 = "Beautiful clarity. Their value will only grow once their former owners discover the loss."
        constant string VL_VENDORQUEST_SATYR_0015 = "A collector's price is measured as much in discretion as in coin."
        constant string VL_VENDORQUEST_SATYR_0016 = "You have shown admirable restraint by returning every crystal. Almost suspicious restraint."
        constant string VL_VENDORQUEST_SATYR_0017 = "Some roads deserve silence, especially when one has profitable secrets to move along them."
        constant string VL_VENDORQUEST_SATYR_0018 = "The old path belongs to whispers again, as every useful road should."
    endglobals

    private function RegisterDailySet takes string voiceType, integer objectiveType, integer firstLine, string lineA, string lineB, string lineC returns nothing
        call QuestsGeneric_RegisterDailyAcceptanceVariant(voiceType, objectiveType, lineA, firstLine)
        call QuestsGeneric_RegisterDailyAcceptanceVariant(voiceType, objectiveType, lineB, firstLine + 1)
        call QuestsGeneric_RegisterDailyAcceptanceVariant(voiceType, objectiveType, lineC, firstLine + 2)
    endfunction

    private function RegisterDailyDialogue takes nothing returns nothing
        call RegisterDailySet(VL_VENDORQUEST_ORC_TYPE, QuestsGeneric_OBJECTIVE_KILL, 35, "Do not count blows. Count enemies that do not rise.", "Strike hard enough that tomorrow's work stays quiet.", "Return with proof in your eyes, not boasts on your tongue.")
        call RegisterDailySet(VL_VENDORQUEST_ORC_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 38, "Bring solid goods. I have no use for cracked scraps.", "Take only what is needed, but bring every piece promised.", "The work waits on your hands now. Move quickly.")
        call RegisterDailySet(VL_VENDORQUEST_ORC_TYPE, QuestsGeneric_OBJECTIVE_TALK, 41, "Speak plainly and keep the parcel sealed.", "The other merchant knows the bargain. Make them honor it.", "Bring back the goods, not a tale about where they went.")

        call RegisterDailySet(VL_VENDORQUEST_SATYR_TYPE, QuestsGeneric_OBJECTIVE_KILL, 19, "Try to make their end less tedious than their life.", "A little terror before the final blow improves the lesson.", "Do return with something more interesting than remorse.")
        call RegisterDailySet(VL_VENDORQUEST_SATYR_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 22, "Quality first. Quantity is merely the minimum price of admission.", "Handle everything delicately; replacement costs offend me.", "Bring precisely what I requested and nothing that asks questions.")
        call RegisterDailySet(VL_VENDORQUEST_SATYR_TYPE, QuestsGeneric_OBJECTIVE_TALK, 25, "Use my name sparingly. It has value in the right ears.", "Accept the parcel and decline every invitation to inspect it.", "Courtesy is useful, but silence is indispensable.")

        call RegisterDailySet(VL_VENDORQUEST_HUMAN_TYPE, QuestsGeneric_OBJECTIVE_KILL, 29, "Keep the road clear and give civilians room to breathe.", "Do the work carefully; we need safety, not another problem.", "Return when the threat is truly ended, not merely scattered.")
        call RegisterDailySet(VL_VENDORQUEST_HUMAN_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 32, "Check every piece before you bring it back.", "Good preparation saves twice the labor at the workshop.", "Take care on the road. Useful cargo attracts desperate hands.")
        call RegisterDailySet(VL_VENDORQUEST_HUMAN_TYPE, QuestsGeneric_OBJECTIVE_TALK, 35, "Give them my name and wait for a clear answer.", "Keep the delivery dry, sealed, and accounted for.", "A simple errand stays simple when everyone keeps their word.")

        call RegisterDailySet(VL_VENDORQUEST_GOBLIN_TYPE, QuestsGeneric_OBJECTIVE_KILL, 27, "Every enemy removed improves the market! Especially my market.", "Be efficient. Heroic flourishes are expensive to insure.", "If they drop anything valuable, remember who sponsored the trip.")
        call RegisterDailySet(VL_VENDORQUEST_GOBLIN_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 30, "Bring the good pieces first. I can sell the ugly ones later.", "Time is money, and right now you are spending mine.", "Count twice before returning. Short shipments hurt friendships.")
        call RegisterDailySet(VL_VENDORQUEST_GOBLIN_TYPE, QuestsGeneric_OBJECTIVE_PURCHASE, 33, "Buy only the marked stock. Substitutions ruin the margins.", "Pay the listed price, then let me complain about it afterward.", "Keep the receipt, the parcel, and especially your fingers.")

        call RegisterDailySet(VL_VENDORQUEST_BONECRUSHER_TYPE, QuestsGeneric_OBJECTIVE_KILL, 17, "Hit enemies until counting becomes easy.", "Broken enemies do not bother carts. Good system.", "Come back standing. Standing heroes carry more loot.")
        call RegisterDailySet(VL_VENDORQUEST_BONECRUSHER_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 20, "Bring all pieces. Ogre counting uses both hands.", "If it breaks on road, it was not good enough anyway.", "Heavy goods are best goods. Means more goods.")
        call RegisterDailySet(VL_VENDORQUEST_BONECRUSHER_TYPE, QuestsGeneric_OBJECTIVE_TALK, 23, "Ask merchant. Take crate. Do not eat crate.", "Other head says check seal. This head says check snacks.", "Bring parcel back before someone makes it lighter.")

        call RegisterDailySet(VL_VENDORQUEST_ELARINDOR_TYPE, QuestsGeneric_OBJECTIVE_KILL, 17, "Let precision guide you where anger would waste strength.", "Each fallen threat buys another quiet hour for our people.", "Return safely. Elarindor has buried enough brave souls.")
        call RegisterDailySet(VL_VENDORQUEST_ELARINDOR_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 20, "Choose intact pieces; damaged magic remembers the wound.", "Carry them gently and let no careless hand disturb them.", "What you recover today may preserve a century tomorrow.")
        call RegisterDailySet(VL_VENDORQUEST_ELARINDOR_TYPE, QuestsGeneric_OBJECTIVE_TALK, 23, "Speak the agreed phrase and accept only the sealed parcel.", "Treat the exchange with patience; trust is our rarest supply.", "Return by the warded road, even if the longer path tempts you.")

        call RegisterDailySet(VL_VENDORQUEST_TAUREN_TYPE, QuestsGeneric_OBJECTIVE_KILL, 9, "Walk with purpose and let no threat follow you home.", "Strength is measured by what your journey protects.", "Return beneath an open sky when the trail is safe.")
        call RegisterDailySet(VL_VENDORQUEST_TAUREN_TYPE, QuestsGeneric_OBJECTIVE_FETCH, 12, "Take only what the earth offers freely, and waste nothing.", "Choose sound materials; patient work begins with honest substance.", "Carry the burden evenly and the road will feel shorter.")
    endfunction

    private function Init takes nothing returns nothing
        call QuestsGeneric_ConfigureSharedDialogue(VL_QUEST_HERO_ACCEPT, VL_QUEST_HERO_COMPLETE_KILL, VL_QUEST_HERO_COMPLETE_FETCH, VL_QUEST_HERO_COMPLETE_TALK, VL_QUEST_HERO_PROGRESS, VL_QUEST_GIVER_PROGRESS)
        call ExSound_RegisterSequence(VL_VENDORQUEST_ORC_TYPE, 1, 43, "Pots\\Sound\\Voicelines\\VendorQuestOrc\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_SATYR_TYPE, 1, 27, "Pots\\Sound\\Voicelines\\VendorQuestSatyr\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_HUMAN_TYPE, 1, 37, "Pots\\Sound\\Voicelines\\VendorQuestHuman\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_GOBLIN_TYPE, 1, 35, "Pots\\Sound\\Voicelines\\VendorQuestGoblin\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_BONECRUSHER_TYPE, 1, 25, "Pots\\Sound\\Voicelines\\VendorQuestBonecrusher\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_ELARINDOR_TYPE, 1, 25, "Pots\\Sound\\Voicelines\\VendorQuestElarindor\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_TAUREN_TYPE, 1, 14, "Pots\\Sound\\Voicelines\\VendorQuestTauren\\")
        call RegisterDailyDialogue()
    endfunction
endlibrary
