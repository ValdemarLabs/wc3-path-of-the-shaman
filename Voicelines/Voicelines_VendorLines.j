/**
    VoicelinesVendorLines

    Author: Valdemar
    Version: 1.0.0

    Description:
    Central source of truth for merchant greetings, trade chatter, transaction
    responses, farewells, profile names, and ExSound keys. Vendor libraries
    bind units to these profiles but do not own dialogue text.

    Credits:
    - Warcraft Wiki vendor categories, used as taxonomy inspiration.

    How to install:
    Import after VendorLines and before vendor catalogs or vendor-type files.

    API:
    - VL_VENDOR_PROFILE_* constants identify reusable voiced profiles.
    - Dialogue content is registered automatically during initialization.

**/
library VoicelinesVendorLines initializer Init requires VendorLines, ExSound
    globals
        constant string VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE = "Riverbane Human Male"
        constant string VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE = "Stormhaven Human Male"
        constant string VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE = "Neutral Human Male"
        constant string VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE = "Riverbane Human Female"
        constant string VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE = "Stormhaven Human Female"
        constant string VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE = "Neutral Human Female"
        constant string VL_VENDOR_PROFILE_TAUREN_HORDE_MALE = "Horde Tauren Male"
        constant string VL_VENDOR_PROFILE_ELARINDOR_MALE = "Elarindor Male"
        constant string VL_VENDOR_PROFILE_ELARINDOR_FEMALE = "Elarindor Female"

        constant string VL_VENDOR_HUMAN_MALE_TYPE = "VendorHumanMale_"
        constant string VL_VENDOR_HUMAN_FEMALE_TYPE = "VendorHumanFemale_"
        constant string VL_VENDOR_TAUREN_MALE_TYPE = "VendorTaurenMale_"
        constant string VL_VENDOR_ELARINDOR_MALE_TYPE = "VendorElarindorMale_"
        constant string VL_VENDOR_ELARINDOR_FEMALE_TYPE = "VendorElarindorFemale_"
    endglobals

    private function FormatSoundKey takes string soundType, integer lineIndex returns string
        if lineIndex < 10 then
            return soundType + "000" + I2S(lineIndex)
        elseif lineIndex < 100 then
            return soundType + "00" + I2S(lineIndex)
        elseif lineIndex < 1000 then
            return soundType + "0" + I2S(lineIndex)
        endif
        return soundType + I2S(lineIndex)
    endfunction

    private function RegisterBasicProfile takes string profileName, string greetingA, string greetingB, string trade, string farewell, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterBasicLines(profileName, greetingA, greetingB, trade, farewell)
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
    endfunction

    private function RegisterProfile takes string profileName, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
    endfunction

    private function RegisterVoicedProfile takes string profileName, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade, string soundType, integer firstLine returns nothing
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, FormatSoundKey(soundType, firstLine))
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, FormatSoundKey(soundType, firstLine + 1))
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, FormatSoundKey(soundType, firstLine + 2))
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, FormatSoundKey(soundType, firstLine + 3))
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, FormatSoundKey(soundType, firstLine + 4))
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, FormatSoundKey(soundType, firstLine + 5))
    endfunction

    private function RegisterDefaultAndSpecialistLines takes nothing returns nothing
        call RegisterBasicProfile("Merchant", "Take a look. Fair prices today.", "If you have coin, I have goods.", "Let us see what changes hands.", "Come back when your purse is heavier.", "Take your time. Good goods do not fear inspection.", "If you need it for the road, I probably have it.", "A good purchase. May it serve you well.", "I can find a buyer for that.", "A fair exchange both ways.", "Nothing today? The stock will still be here.")
        call RegisterBasicProfile("Blacksmith", "Steel is honest. Coin should be too.", "Blades, mail, tools. All tested before they leave my forge.", "Pick it up if you mean to buy it.", "Keep the edge dry.", "A balanced weapon feels light before it ever strikes.", "Armor should stop a blade, not stop you walking.", "Good choice. I stand behind that work.", "I can melt that down or put a new edge on it.", "Old steel out, better steel in. Sensible.", "No sparks today? Come back when you need honest steel.")
        call VendorLines_RegisterLine("Riverbane Human Blacksmith", VendorLines_LINE_CHATTER, "Riverbane roads are hard on boots, buckles, and blades.", "")
        call VendorLines_RegisterLine("Riverbane Human Blacksmith", VendorLines_LINE_BOUGHT, "That will hold through a Riverbane winter.", "")
        call VendorLines_RegisterLine("Fiery Mountain Orc Blacksmith", VendorLines_LINE_CHATTER, "Mountain fire makes hard steel and harder smiths.", "")
        call VendorLines_RegisterLine("Fiery Mountain Orc Blacksmith", VendorLines_LINE_CHATTER, "If the edge chips, you struck like a human.", "")
        call VendorLines_RegisterLine("Fiery Mountain Orc Blacksmith", VendorLines_LINE_BOUGHT, "Strong iron for a strong hand.", "")
        call VendorLines_RegisterBasicLines("Graknar", "Strong bags. Strong price.", "A bigger pack saves longer walks.", "No bag to carry. I make your pack bigger now.", "Travel lighter, come back richer.")
        call RegisterProfile("Bonecrusher Ogre Bag Merchant", "Bonecrusher stitching. Even rocks stay inside.", "Tiny bag makes tiny loot. Graknar fixes.", "Bigger bag. Now bring bigger treasure.", "Graknar keeps this. Maybe sells twice.", "Pack changes, coin changes. Graknar approves.", "No bag? Then carry regret in pockets.")
        call RegisterBasicProfile("General Goods Merchant", "Supplies for the road, friend.", "A full pack keeps trouble small.", "Take what you need and leave the rest for someone poorer.", "Safe roads and steady coin.", "Rope, water, salves. Heroes always remember them one mile too late.", "The cheapest supply is the one that gets you home.", "Packed and ready. Try not to lose it.", "Used, perhaps. Useless, never.", "A lighter pack and better supplies. Good business.", "Window-shopping is free. My patience is nearly so.")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_CHATTER, "Guaranteed genuine until proven otherwise!", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_CHATTER, "Bulk discount starts immediately after you buy in bulk.", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_BOUGHT, "No refunds, but compliments are always accepted.", "")
        call VendorLines_RegisterLine("Goblin General Goods", VendorLines_LINE_SOLD, "I know three people who will pay twice that.", "")
        call VendorLines_RegisterLine("Forest Orc Supplies", VendorLines_LINE_CHATTER, "Thornwoods punish travelers who pack poorly.", "")
        call VendorLines_RegisterLine("Forest Orc Supplies", VendorLines_LINE_BOUGHT, "Use it well, and return from the wilds.", "")
    endfunction

    private function RegisterCatalogRoleLines takes nothing returns nothing
        call RegisterBasicProfile("Weapons Merchant", "Looking for a proper weapon?", "Steel for every fighting style.", "Let us see what changes hands.", "Safe roads until next time.", "A weapon should suit the hand before it suits the eye.", "Edges, hafts, balance. Choose all three wisely.", "That one is ready for battle.", "I can put a new edge on this.", "Old weapon out, stronger weapon in.", "No blade today? Trouble rarely waits.")
        call RegisterBasicProfile("Armor Merchant", "Armor for road or war.", "Protection is cheaper than recovery.", "Let us see what changes hands.", "Safe roads until next time.", "Good armor bends where it should and nowhere else.", "Mail for movement, plate for confidence.", "A sound choice. Wear it well.", "This can be patched and sold again.", "Less burden, better protection.", "Come back before the next battle, not after.")
        call RegisterBasicProfile("Shield Merchant", "A shield keeps tomorrow possible.", "Round, broad, light, or reinforced.", "Let us see what changes hands.", "Safe roads until next time.", "A shield is only useful when raised in time.", "Mind the straps; they matter more than decoration.", "That will turn a hard blow.", "The face is scarred, but the frame is useful.", "A stronger wall for your shield arm.", "Planning to block with your face instead?")
        call RegisterBasicProfile("Arena Quartermaster", "Marks and coin buy an edge here.", "Champions need equipment worthy of the sand.", "Let us see what changes hands.", "Safe roads until next time.", "Arena gear is tested under very direct conditions.", "The crowd remembers victories, not repair bills.", "Take it into the ring and earn its price.", "Someone else may fight better with this.", "A champion's exchange.", "Spectating remains the inexpensive option.")
        call RegisterBasicProfile("Travelling Merchant", "My road brought me here at the right time.", "The cart moves, but the bargains linger.", "Let us see what changes hands.", "Safe roads until next time.", "Local stock changes at every stop.", "Buy now; the next road may carry me elsewhere.", "One less thing to haul onward.", "I know a market down the road for this.", "A profitable stop for both of us.", "Then I will save the cart space.")
        call RegisterBasicProfile("Fisher", "Fresh catch and sound tackle.", "The water always has another secret.", "Let us see what changes hands.", "Safe roads until next time.", "Good line catches fish; patience catches stories.", "Never trust a calm pool without testing it.", "May the next cast repay you.", "Fresh enough for stew.", "Tackle out, catch in.", "The fish are browsing more eagerly.")
        call RegisterBasicProfile("Miner", "Tools and ore from honest stone.", "The mountain charges in sweat.", "Let us see what changes hands.", "Safe roads until next time.", "Listen before you swing; stone warns the careful.", "A dull pick makes a long tunnel.", "That should bite cleanly into rock.", "There is metal left in this yet.", "Ore and tools, fairly exchanged.", "The mountain will still be there tomorrow.")
        call RegisterBasicProfile("Cook", "Hungry travelers make sensible customers.", "Sit, eat, and face the road stronger.", "Let us see what changes hands.", "Safe roads until next time.", "A full stomach improves nearly every plan.", "Fresh ingredients need very little boasting.", "Eat it while it is worth eating.", "I can make use of that in the kitchen.", "Provisions traded and appetites answered.", "Come back when hunger wins.")
        call RegisterBasicProfile("Alchemy Supplier", "Measured reagents, clean bottles.", "Do not taste anything without asking.", "Let us see what changes hands.", "Safe roads until next time.", "Alchemy rewards precision and punishes optimism.", "Fresh water matters as much as rare herbs.", "Keep the stopper tight.", "Useful material, once properly cleaned.", "A balanced exchange, unlike some mixtures.", "No experiments today? Sensible, perhaps.")
        call RegisterBasicProfile("Blacksmithing Supplier", "Coal, ore, and proper smithing tools.", "A forge is only as good as its fuel.", "Let us see what changes hands.", "Safe roads until next time.", "Cheap coal wastes expensive metal.", "Keep a second hammer near the anvil.", "Your forge is ready for work.", "Scrap becomes stock with enough heat.", "Fuel in, salvage out.", "The forge can wait, but rust will not.")
        call RegisterBasicProfile("Cooking Supplier", "Ingredients and camp tools here.", "Good meals begin before the fire is lit.", "Let us see what changes hands.", "Safe roads until next time.", "Pack dry fuel and fresher meat.", "A cook's knife should never be an afterthought.", "That belongs over a steady flame.", "I can season or preserve this.", "A lighter pantry, a better meal.", "No supplies means a cold supper.")
        call RegisterBasicProfile("Enchanting Supplier", "Crystals and essences, carefully handled.", "Magic leaves residue. I sell the useful kind.", "Let us see what changes hands.", "Safe roads until next time.", "Every enchantment begins with something being consumed.", "Do not store volatile essences beside lunch.", "May the magic hold true.", "This still carries a trace worth keeping.", "Old magic becomes new work.", "The mundane life has its admirers.")
        call RegisterBasicProfile("Fishing Supplier", "Poles for streams, coast, and deep water.", "Strong line costs less than lost fish.", "Let us see what changes hands.", "Safe roads until next time.", "Match the pole to the water, not your pride.", "Salt ruins tackle faster than monsters do.", "A fine choice for the next pool.", "I can salvage the fittings.", "Old tackle traded for a better cast.", "The water will wait.")
        call RegisterBasicProfile("Leatherworking Supplier", "Leather, hides, and cutting tools.", "Good leather remembers careful hands.", "Let us see what changes hands.", "Safe roads until next time.", "Work with the grain, never against it.", "Dry hides slowly if you want them strong.", "That will take a clean stitch.", "I can trim useful pieces from this.", "Fresh material for worn gear.", "No stitching today, then.")
        call RegisterBasicProfile("Mining Supplier", "Picks, coal, and workable ore.", "Everything here was earned one strike at a time.", "Let us see what changes hands.", "Safe roads until next time.", "Carry wedges when the stone turns stubborn.", "Rich veins punish careless miners first.", "A reliable tool for hard ground.", "I will sort the metal from the waste.", "Tools and ore exchanged cleanly.", "Return when the rock starts calling.")
        call RegisterBasicProfile("Skinning Supplier", "Knives and hides for practiced hands.", "A clean cut preserves the value.", "Let us see what changes hands.", "Safe roads until next time.", "Keep the blade short, sharp, and controlled.", "The wilds provide if nothing is wasted.", "That edge should serve you well.", "This hide can still be worked.", "Tools out, useful hides in.", "The beasts will not skin themselves.")
        call RegisterBasicProfile("Profession Supplier", "Tools for every useful trade.", "One stall, many crafts.", "Let us see what changes hands.", "Safe roads until next time.", "A missing tool can stop an entire expedition.", "Professionals buy spares before they need them.", "That should keep your work moving.", "Another craft will find a use for this.", "Many trades, one fair exchange.", "Come back when work creates a need.")
        call RegisterBasicProfile("Faction Quartermaster", "Standing earns access to the best stores.", "Service is remembered here.", "Let us see what changes hands.", "Safe roads until next time.", "Trusted allies see stock others do not.", "Reputation opens storerooms coin cannot.", "Your service has earned this.", "The faction can reclaim value from it.", "Supplies exchanged among trusted hands.", "More service may reveal better stock.")
        call RegisterBasicProfile("Curiosity Merchant", "The selection changes whenever fortune stirs.", "Rare, odd, and occasionally useful.", "Let us see what changes hands.", "Safe roads until next time.", "Close the stall and open it again; fate may restock it.", "Certainty is expensive. Curiosity is profitable.", "A brave purchase.", "How wonderfully unexpected.", "Chance favored the exchange.", "Even fortune cannot tempt you today.")
        call RegisterBasicProfile("Reagent Merchant", "Reagents for practical and arcane work.", "Everything measured, labeled, and mostly stable.", "Let us see what changes hands.", "Safe roads until next time.", "Purity decides whether a spell sings or sputters.", "Keep crystals apart unless sparks are intended.", "Exactly what the formula calls for.", "I can refine this.", "Raw material traded for prepared stock.", "Return when the recipe demands it.")
        call RegisterBasicProfile("Provisioner", "Food and drink for the road.", "Fresh provisions, clean water.", "Let us see what changes hands.", "Safe roads until next time.", "Never begin a long road on an empty stomach.", "Water weighs less than regret.", "Packed for travel.", "Someone less particular will eat this.", "Old provisions out, fresh supplies in.", "Hunger will negotiate later.")
        call RegisterBasicProfile("Potion Seller", "Healing, mana, and restorative mixtures.", "Read the label before the emergency.", "Let us see what changes hands.", "Safe roads until next time.", "Potions work best before the final breath.", "Never mix two bottles because the colors match.", "Keep it within reach.", "The bottle is worth something, at least.", "Used stock traded for fresh remedies.", "May you remain healthy enough to reconsider.")
        call RegisterBasicProfile("Rare Goods Dealer", "Uncommon goods for uncommon customers.", "Limited stock, limited patience.", "Let us see what changes hands.", "Safe roads until next time.", "Rarity is supply arguing with demand.", "If you see it twice, buy it the second time.", "There may not be another.", "Interesting. I know a collector.", "One rarity replaces another.", "The rarest purchase is restraint.")
        call RegisterBasicProfile("Expedition Supplier", "Everything needed beyond the safe road.", "Prepare here or improvise badly later.", "Let us see what changes hands.", "Safe roads until next time.", "A campfire, salve, and proper tool solve many problems.", "Expeditions fail from small omissions.", "Your pack is better prepared now.", "I can equip another traveler with this.", "Old weight exchanged for useful supplies.", "The wilderness charges more than I do.")
        call RegisterBasicProfile("Trade Goods Merchant", "Materials bought and sold in useful quantities.", "Every craft begins with ordinary goods.", "Let us see what changes hands.", "Safe roads until next time.", "Common materials keep uncommon work moving.", "Markets are built one crate at a time.", "Useful stock for useful work.", "Another artisan will need this.", "Materials exchanged without waste.", "The warehouses remain patient.")
        call RegisterBasicProfile("Beastmaster Supplier", "Feed and field care for loyal beasts.", "A healthy companion fights longer.", "Let us see what changes hands.", "Safe roads until next time.", "Pack food for the beast before yourself.", "Good care earns loyalty no command can force.", "Your companion will approve.", "Another handler can use this.", "Fresh care supplies for old field goods.", "Your beast may have stronger opinions later.")
    endfunction

    private function RegisterRaceAndFactionLines takes nothing returns nothing
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE, "Riverbane caravans bring new stock every week.", "Keep your purse close in the market quarter.", "A practical choice for Riverbane roads.", "Someone in the lower ward will want this.", "A tidy exchange. Riverbane prospers on trade.", "Another time, then. The market stays busy.", VL_VENDOR_HUMAN_MALE_TYPE, 1)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE, "Stormhaven workmanship travels farther than its banners.", "Salt air ruins cheap metal and cheaper cloth.", "Stormhaven quality. Treat it accordingly.", "I will see what the harbor buyers offer.", "Goods out, goods in. The harbor never rests.", "No trade? Enjoy the harbor while you are here.", VL_VENDOR_HUMAN_MALE_TYPE, 7)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE, "Coin has fewer loyalties than people do.", "I trade with anyone who keeps the peace.", "Fair coin for useful goods.", "No questions asked, within reason.", "That is how neutral ground stays prosperous.", "We can disagree about price another day.", VL_VENDOR_HUMAN_MALE_TYPE, 13)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE, "Riverbane's market wakes before the watch does.", "A careful buyer keeps coin and cargo equally close.", "A sound choice for the roads beyond the walls.", "The lower ward can give this a second life.", "Fair goods for fair coin. Riverbane moves forward.", "Another time. The next caravan may bring something new.", VL_VENDOR_HUMAN_FEMALE_TYPE, 1)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE, "Stormhaven craft carries well beyond the harbor.", "Sea air tests every buckle, stitch, and blade.", "A fine choice. Keep it clear of the salt spray.", "The harbor buyers will find a use for this.", "One cargo exchanged for another. That is harbor life.", "Nothing today? The tide may bring you back.", VL_VENDOR_HUMAN_FEMALE_TYPE, 7)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE, "Trade travels farther when banners stay outside.", "Peaceful customers receive peaceful prices.", "Useful goods deserve useful hands.", "I know a buyer who values discretion.", "A balanced exchange keeps neutral ground stable.", "We can settle on a price another day.", VL_VENDOR_HUMAN_FEMALE_TYPE, 13)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_TAUREN_HORDE_MALE, "The Horde's roads are long; choose supplies that endure.", "Earth, hide, and iron each reward patient hands.", "Carry it with strength and purpose.", "Nothing useful should be wasted.", "A fair exchange honors both sides.", "Walk in peace. Return when the road provides a need.", VL_VENDOR_TAUREN_MALE_TYPE, 1)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ELARINDOR_MALE, "Elarindor's forges burn softly, but they have not gone cold.", "Every restored relic returns a fragment of our home.", "May it serve you in Elarindor's defense.", "We will restore what usefulness remains.", "A measured exchange, worthy of trusted allies.", "Another time. Patience has preserved us this long.", VL_VENDOR_ELARINDOR_MALE_TYPE, 1)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ELARINDOR_FEMALE, "The arcane currents around Elarindor still bless careful craft.", "What survives the ruins deserves a discerning keeper.", "Carry it with the grace its makers intended.", "This may yet find purpose among our people.", "A fair exchange strengthens Elarindor.", "Browse as you wish. Memory has taught us patience.", VL_VENDOR_ELARINDOR_FEMALE_TYPE, 1)

        call RegisterProfile("Fiery Mountain Orc", "Ash keeps weak steel honest.", "Mountain paths reward a well-packed warrior.", "Good. That belongs in a warrior's hands.", "I can hammer some use back into this.", "You leave better armed and less burdened.", "Then quit blocking the heat from my forge.")
        call RegisterProfile("Forest Orc", "The Thornwoods take payment from careless travelers.", "Sereneglade herbs, Riverbane iron, orcish prices.", "Carry it with honor.", "The forest wastes nothing. Neither do I.", "A worthy exchange beneath the old trees.", "Listen to the leaves, then return with coin.")
        call RegisterProfile("Sirensong Jungle Orc", "Jungle damp spoils anything packed badly.", "Sirensong paths hide teeth behind every leaf.", "Keep it dry and keep it close.", "The jungle will give this a second purpose.", "Better supplies for the green road ahead.", "The jungle waits even when customers do not.")
        call RegisterProfile("Satyr Merchant", "Desire makes every price seem reasonable.", "I acquire curios from paths mortals fear to walk.", "An indulgence well chosen.", "How charming. I know exactly who wants this.", "We have each surrendered something tempting.", "Restraint? How unexpectedly dull.")
        call RegisterProfile("Bonecrusher Ogre", "Bonecrusher goods survive Bonecrusher customers.", "Two eyes check stock. One eye checks coin.", "Good buy. Hard to break.", "We find use. Or lunch. Probably use.", "You get goods. We get goods. Very clever.", "No buy? Both heads disappointed.")
        call RegisterProfile("Goblin Riverbane", "Riverbane tolls are included in the price. Mostly.", "Local goods, imported goods, plausibly acquired goods!", "Excellent investment! For me and possibly you.", "I already have a buyer with poor judgment.", "You traded up. I traded profitably.", "Browsing fee waived this time.")
        call RegisterProfile("Goblin Stormhaven", "Fresh off the ship, or at least near a ship recently.", "Harbor prices change with the wind and my mood.", "Seaworthy enough! Probably.", "Dockside buyers love mysterious provenance.", "Cargo exchanged and no customs officer in sight.", "Come back after payday or piracy.")
        call RegisterProfile("Goblin Sirensong", "Jungle-tested means it survived the walk to my stall.", "Nothing here bites unless you skip payment.", "A survival essential at a luxury margin.", "Jungle salvage! Very fashionable.", "Supplies rotate, profits accumulate.", "The mosquitoes browse longer than you.")
        call RegisterProfile("Goblin Travelling Merchant", "My shop moves, so decide before it does.", "Every road has customers and unattended cargo.", "Portable, profitable, and now your problem.", "I will sell it three towns from here.", "A complete trade before the wheels cool.", "Next time you see me, the price may have legs.")
        call RegisterProfile("Goblin Arena Vendor", "Arena rules forbid refunds after dismemberment.", "Champions buy quality. Survivors buy replacements.", "That should improve the odds. Slightly.", "Blood washes off. Value remains.", "Old gear out, arena gear in. Bold strategy.", "Spectating is cheaper, but far less profitable for me.")
    endfunction

    private function Init takes nothing returns nothing
        call ExSound_RegisterSequence(VL_VENDOR_HUMAN_MALE_TYPE, 1, 18, "Pots\\Sound\\Voicelines\\VendorHumanMale\\")
        call ExSound_RegisterSequence(VL_VENDOR_HUMAN_FEMALE_TYPE, 1, 18, "Pots\\Sound\\Voicelines\\VendorHumanFemale\\")
        call ExSound_RegisterSequence(VL_VENDOR_TAUREN_MALE_TYPE, 1, 6, "Pots\\Sound\\Voicelines\\VendorTaurenMale\\")
        call ExSound_RegisterSequence(VL_VENDOR_ELARINDOR_MALE_TYPE, 1, 6, "Pots\\Sound\\Voicelines\\VendorElarindorMale\\")
        call ExSound_RegisterSequence(VL_VENDOR_ELARINDOR_FEMALE_TYPE, 1, 6, "Pots\\Sound\\Voicelines\\VendorElarindorFemale\\")
        call RegisterDefaultAndSpecialistLines()
        call RegisterCatalogRoleLines()
        call RegisterRaceAndFactionLines()
    endfunction
endlibrary
