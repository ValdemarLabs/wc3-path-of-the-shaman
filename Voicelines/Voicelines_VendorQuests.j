/**
    VoicelinesVendorQuests

    Author: Valdemar
    Version: 2.1.0

    Description:
    Central source of truth for generic vendor quest dialogue text and shared
    ExSound key-prefix policy. Quest libraries select a voice type and a pair
    of numbered text constants without owning spoken dialogue.

    Credits:

    How to install:
    Import after ExSound. Matching sequences are registered in ExSound.j.

    API:
    - VL_VENDORQUEST_*_TYPE constants select shared ExSound sequences.
    - VL_VENDORQUEST_*_NNNN constants contain acceptance/completion text.

**/
library VoicelinesVendorQuests initializer Init requires ExSound
    globals
        constant string VL_VENDORQUEST_ORC_TYPE = "VendorQuestOrc_"
        constant string VL_VENDORQUEST_SATYR_TYPE = "VendorQuestSatyr_"
        constant string VL_VENDORQUEST_HUMAN_TYPE = "VendorQuestHuman_"
        constant string VL_VENDORQUEST_GOBLIN_TYPE = "VendorQuestGoblin_"
        constant string VL_VENDORQUEST_BONECRUSHER_TYPE = "VendorQuestBonecrusher_"
        constant string VL_VENDORQUEST_ELARINDOR_TYPE = "VendorQuestElarindor_"

        // Shared unvoiced hero and progress dialogue.
        constant string VL_VENDORQUEST_HERO_ACCEPT = "I will see it done."
        constant string VL_VENDORQUEST_HERO_COMPLETE_KILL = "The threat has been dealt with."
        constant string VL_VENDORQUEST_HERO_COMPLETE_SUPPLY = "I collected the supplies you requested."
        constant string VL_VENDORQUEST_HERO_COMPLETE_FETCH = "I brought what you asked for."
        constant string VL_VENDORQUEST_HERO_PROGRESS = "What remains to be done?"
        constant string VL_VENDORQUEST_VENDOR_PROGRESS = "I am still waiting on "
        constant string VL_VENDORQUEST_HERO_REQUEST_SUPPLY = "I was sent to collect the supplies you are holding."
        constant string VL_VENDORQUEST_HERO_ASK_TO_BUY = "I was told you carry the item needed for this commission."
        constant string VL_VENDORQUEST_VENDOR_HANDOFF = "It is ready. Take it back to the one who sent you."
        constant string VL_VENDORQUEST_VENDOR_ALREADY_HANDED_OFF = "I already gave you the parcel. Keep it safe until you deliver it."
        constant string VL_VENDORQUEST_VENDOR_PURCHASE = "It is in my regular stock. Buy it through trade, then return it to your quest giver."

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

        // Elarindor quest dialogue.
        constant string VL_VENDORQUEST_ELARINDOR_0001 = "The wraiths circle closer whenever the forge burns. Destroy six before their hunger reaches the anvils."
        constant string VL_VENDORQUEST_ELARINDOR_0002 = "The forge-light holds steady again. Elarindor owes you a quieter night."
        constant string VL_VENDORQUEST_ELARINDOR_0003 = "Five stable mana crystals should be enough to renew the outer wards. Handle them gently; they remember every careless touch."
        constant string VL_VENDORQUEST_ELARINDOR_0004 = "Their light is clean and steady. These fragments will guard living memories, not merely ruins."
        constant string VL_VENDORQUEST_ELARINDOR_0005 = "The wardens have exhausted yesterday's draughts. Bring eight fresh herbs before the morning dew leaves them."
        constant string VL_VENDORQUEST_ELARINDOR_0006 = "These still carry the dawn's strength. The wardens will stand easier because of you."
        constant string VL_VENDORQUEST_ELARINDOR_0007 = "Sylvaris has completed the reagent inventory. Bring the sealed ledger here before another emergency changes the count."
        constant string VL_VENDORQUEST_ELARINDOR_0008 = "Every measure accounted for. Order may be modest, but it is how Elarindor begins again."

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
    endglobals

    private function Init takes nothing returns nothing
        call ExSound_RegisterSequence(VL_VENDORQUEST_ORC_TYPE, 1, 24, "Pots\\Sound\\Voicelines\\VendorQuestOrc\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_SATYR_TYPE, 1, 12, "Pots\\Sound\\Voicelines\\VendorQuestSatyr\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_HUMAN_TYPE, 1, 18, "Pots\\Sound\\Voicelines\\VendorQuestHuman\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_GOBLIN_TYPE, 1, 16, "Pots\\Sound\\Voicelines\\VendorQuestGoblin\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_BONECRUSHER_TYPE, 1, 10, "Pots\\Sound\\Voicelines\\VendorQuestBonecrusher\\")
        call ExSound_RegisterSequence(VL_VENDORQUEST_ELARINDOR_TYPE, 1, 8, "Pots\\Sound\\Voicelines\\VendorQuestElarindor\\")
    endfunction
endlibrary
