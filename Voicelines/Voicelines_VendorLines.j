/**
    VoicelinesVendorLines

    Author: Valdemar
    Version: 2.4.0

    Description:
    Central source of truth for merchant greetings, trade chatter, transaction
    responses, farewells, regional dialogue profiles, reusable numbered voice
    types, and ExSound keys. Vendor libraries bind both profiles to units but
    do not own dialogue text.

    Credits:
    - Warcraft Wiki vendor categories, used as taxonomy inspiration.

    How to install:
    Import after VendorLines and before vendor catalogs or vendor-type files.

    API:
    - VL_VENDOR_PROFILE_* constants identify reusable voiced profiles.
    - VL_*_TYPE constants identify reusable FishAudio voice clones.
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
        constant string VL_VENDOR_PROFILE_HUMAN_RIVERBANE_BLACKSMITH_MALE = "Riverbane Human Blacksmith"
        constant string VL_VENDOR_PROFILE_TAUREN_HORDE_MALE = "Horde Tauren Male"
        constant string VL_VENDOR_PROFILE_DWARF_MORGRIM_MALE = "Morgrim Clan Dwarf Male"
        constant string VL_VENDOR_PROFILE_ELARINDOR_MALE = "Elarindor Male"
        constant string VL_VENDOR_PROFILE_ELARINDOR_FEMALE = "Elarindor Female"
        constant string VL_VENDOR_PROFILE_TROLL_HORDE_MALE = "Horde Troll Male"
        constant string VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE = "Fiery Mountain Orc"
        constant string VL_VENDOR_PROFILE_ORC_FOREST_MALE = "Forest Orc"
        constant string VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE = "Sirensong Jungle Orc"
        constant string VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_BLACKSMITH_MALE = "Fiery Mountain Orc Blacksmith"
        constant string VL_VENDOR_PROFILE_ORC_FOREST_SUPPLIES_MALE = "Forest Orc Supplies"
        constant string VL_VENDOR_PROFILE_SATYR_MALE = "Satyr Merchant"
        constant string VL_VENDOR_PROFILE_SATYR_FEMALE = "Satyr Female Merchant"
        constant string VL_VENDOR_PROFILE_OGRE_BONECRUSHER_MALE = "Bonecrusher Ogre"
        constant string VL_VENDOR_PROFILE_OGRE_BONECRUSHER_BAG_MERCHANT_MALE = "Bonecrusher Ogre Bag Merchant"
        constant string VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE = "Goblin Riverbane"
        constant string VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE = "Goblin Stormhaven"
        constant string VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE = "Goblin Sirensong"
        constant string VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE = "Goblin Travelling Merchant"
        constant string VL_VENDOR_PROFILE_GOBLIN_ARENA_MALE = "Goblin Arena Vendor"

        // Reusable FishAudio voice profiles. Vendor and quest dialogue share these keys.
        constant string VL_GENERIC_HUMAN_MALE_1_TYPE = "GenericHumanMale1_"
        constant string VL_GENERIC_HUMAN_MALE_2_TYPE = "GenericHumanMale2_"
        constant string VL_GENERIC_HUMAN_FEMALE_1_TYPE = "GenericHumanFemale1_"
        constant string VL_GENERIC_HUMAN_FEMALE_2_TYPE = "GenericHumanFemale2_"
        constant string VL_GENERIC_TAUREN_MALE_1_TYPE = "GenericTaurenMale1_"
        constant string VL_GENERIC_TAUREN_MALE_2_TYPE = "GenericTaurenMale2_"
        constant string VL_GENERIC_TAUREN_MALE_3_TYPE = "GenericTaurenMale3_"
        constant string VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE = "GenericDwarfMorgrimMale1_"
        constant string VL_GENERIC_ELARINDOR_MALE_1_TYPE = "GenericElarindorMale1_"
        constant string VL_GENERIC_ELARINDOR_MALE_2_TYPE = "GenericElarindorMale2_"
        constant string VL_GENERIC_ELARINDOR_FEMALE_1_TYPE = "GenericElarindorFemale1_"
        constant string VL_GENERIC_ELARINDOR_FEMALE_2_TYPE = "GenericElarindorFemale2_"
        constant string VL_GENERIC_TROLL_MALE_1_TYPE = "GenericTrollMale1_"
        constant string VL_GENERIC_TROLL_MALE_2_TYPE = "GenericTrollMale2_"
        constant string VL_GENERIC_ORC_MALE_1_TYPE = "GenericOrcMale1_"
        constant string VL_GENERIC_ORC_MALE_2_TYPE = "GenericOrcMale2_"
        constant string VL_GENERIC_ORC_MALE_3_TYPE = "GenericOrcMale3_"
        constant string VL_GENERIC_ORC_MALE_4_TYPE = "GenericOrcMale4_"
        constant string VL_GENERIC_ORC_MALE_5_TYPE = "GenericOrcMale5_"
        constant string VL_GENERIC_ORC_MALE_6_TYPE = "GenericOrcMale6_"
        constant string VL_GENERIC_ORC_MALE_7_TYPE = "GenericOrcMale7_"
        constant string VL_GENERIC_ORC_MALE_8_TYPE = "GenericOrcMale8_"
        constant string VL_GENERIC_ORC_MALE_9_TYPE = "GenericOrcMale9_"
        constant string VL_GENERIC_SATYR_MALE_1_TYPE = "GenericSatyrMale1_"
        constant string VL_GENERIC_SATYR_FEMALE_1_TYPE = "GenericSatyrFemale1_"
        constant string VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE = "GenericOgreBonecrusherMale1_"
        constant string VL_GENERIC_GOBLIN_MALE_1_TYPE = "GenericGoblinMale1_"
        constant string VL_GENERIC_GOBLIN_MALE_2_TYPE = "GenericGoblinMale2_"
        constant string VL_GENERIC_GOBLIN_MALE_3_TYPE = "GenericGoblinMale3_"
        constant string VL_GENERIC_GOBLIN_MALE_4_TYPE = "GenericGoblinMale4_"

        // Shared racial style for extra voiced trade outcomes.
        private constant integer VL_CULTURE_HUMAN = 1
        private constant integer VL_CULTURE_TAUREN = 2
        private constant integer VL_CULTURE_DWARF = 3
        private constant integer VL_CULTURE_ELARINDOR = 4
        private constant integer VL_CULTURE_TROLL = 5
        private constant integer VL_CULTURE_ORC = 6
        private constant integer VL_CULTURE_SATYR = 7
        private constant integer VL_CULTURE_OGRE = 8
        private constant integer VL_CULTURE_GOBLIN = 9

        private constant integer VL_VENDOR_CATALOG_LINE_COUNT = 19
        private hashtable VL_VendorCatalog = InitHashtable()
        private hashtable VL_VoiceFamily = InitHashtable()
        private integer VL_VendorCatalogCount = 0
    endglobals

    private function RegisterUnvoicedVariations takes string profileName returns nothing
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, "There is more stock here than the first glance reveals.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, "A wise purchase. I hope it serves you well.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, "Good choice. That belongs in capable hands.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, "I can put that back into useful circulation.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, "Fair value for something you no longer need.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, "A productive exchange for both of us.", "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, "Your pack changed, and my shelves did too. Good trade.", "")
    endfunction

    private function RegisterUnvoicedBasicProfile takes string profileName, string greetingA, string greetingB, string trade, string farewell, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterBasicLines(profileName, greetingA, greetingB, trade, farewell)
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
        call RegisterUnvoicedVariations(profileName)
    endfunction

    private function RegisterCatalogVariations takes string profileName, integer lineOffset returns nothing
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_CHATTER, lineOffset, "There is more stock here than the first glance reveals.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT, lineOffset + 1, "A wise purchase. I hope it serves you well.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT, lineOffset + 2, "Good choice. That belongs in capable hands.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_SOLD, lineOffset + 3, "I can put that back into useful circulation.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_SOLD, lineOffset + 4, "Fair value for something you no longer need.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, lineOffset + 5, "A productive exchange for both of us.")
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, lineOffset + 6, "Your pack changed, and my shelves did too. Good trade.")
        // Keep the final two offsets reserved so existing voice-catalog numbering does not shift.
    endfunction

    private function RegisterBasicProfile takes string profileName, string greetingA, string greetingB, string trade, string farewell, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        local integer lineOffset = VL_VendorCatalogCount * VL_VENDOR_CATALOG_LINE_COUNT

        set VL_VendorCatalogCount = VL_VendorCatalogCount + 1
        call SaveInteger(VL_VendorCatalog, StringHash(profileName), 0, VL_VendorCatalogCount)
        call VendorLines_RegisterCatalogBasicLines(profileName, lineOffset, greetingA, greetingB, trade, farewell)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_CHATTER, lineOffset + 4, chatterA)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_CHATTER, lineOffset + 5, chatterB)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT, lineOffset + 6, bought)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_SOLD, lineOffset + 7, sold)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, lineOffset + 8, exchanged)
        call VendorLines_RegisterCatalogLine(profileName, VendorLines_LINE_NO_TRANSACTION, lineOffset + 9, noTrade)
        call RegisterCatalogVariations(profileName, lineOffset + 10)
    endfunction

    private function RegisterCatalogBasicProfile takes string profileName, string greetingA, string greetingB, string trade, string farewell returns nothing
        local integer lineOffset = VL_VendorCatalogCount * VL_VENDOR_CATALOG_LINE_COUNT

        set VL_VendorCatalogCount = VL_VendorCatalogCount + 1
        call SaveInteger(VL_VendorCatalog, StringHash(profileName), 0, VL_VendorCatalogCount)
        call VendorLines_RegisterCatalogBasicLines(profileName, lineOffset, greetingA, greetingB, trade, farewell)
    endfunction

    private function RegisterProfile takes string profileName, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
        call RegisterUnvoicedVariations(profileName)
    endfunction

    private function RegisterVoicedVariationSet takes string profileName, integer firstLine, string chatter, string boughtA, string boughtB, string soldA, string soldB, string exchangedA, string exchangedB returns nothing
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_CHATTER, chatter, firstLine)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT, boughtA, firstLine + 1)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT, boughtB, firstLine + 2)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_SOLD, soldA, firstLine + 3)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_SOLD, soldB, firstLine + 4)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchangedA, firstLine + 5)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchangedB, firstLine + 6)
    endfunction

    private function RegisterNoTransactionVariations takes string profileName, integer firstLine, string noTradeA, string noTradeB returns nothing
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTradeA, firstLine + 7)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTradeB, firstLine + 8)
    endfunction

    private function RegisterCulturalVariations takes string profileName, integer firstLine, integer culture returns nothing
        if culture == VL_CULTURE_HUMAN then
            call RegisterVoicedVariationSet(profileName, firstLine, "Take your time. A careful buyer saves coin twice.", "A practical choice. You chose well.", "Good judgment. That should earn its keep.", "There is enough worth here for another owner.", "I know a market where this will be useful.", "Your pack is lighter and better supplied. Fair trade.", "Useful goods changed hands, as they should.")
            if profileName == VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE or profileName == VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE or profileName == VL_VENDOR_PROFILE_HUMAN_RIVERBANE_BLACKSMITH_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "Riverbane's roads will give you a reason to return.", "Keep the coin, then. The next caravan may change your mind.")
            elseif profileName == VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE or profileName == VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "No trade? The tide may bring better judgment.", "You inspected the whole stall and left the harbor no richer.")
            else
                call RegisterNoTransactionVariations(profileName, firstLine, "No agreement today. Neutral ground allows that.", "Keep your coin. Peace costs enough already.")
            endif
        elseif culture == VL_CULTURE_TAUREN then
            call RegisterVoicedVariationSet(profileName, firstLine, "Choose patiently. Good goods should outlast the road.", "A worthy choice. Carry it with purpose.", "May it lighten the burden ahead.", "Nothing useful should be left to waste.", "This will serve another traveler.", "What you no longer need will answer another's need.", "A balanced trade honors both sides.")
            call RegisterNoTransactionVariations(profileName, firstLine, "The road has not shown you a need yet.", "Keep your coin, then. Spend it when the need is true.")
        elseif culture == VL_CULTURE_DWARF then
            call RegisterVoicedVariationSet(profileName, firstLine, "Take a proper look. Sound craft survives scrutiny.", "Aye, that is worth every coin of its weight.", "Good choice. It was made for hard use.", "There is honest metal beneath the wear.", "A hammer and patience will give this new purpose.", "Old craft returned and stout work carried onward.", "Coin, steel, and no foolishness. A fine exchange.")
            call RegisterNoTransactionVariations(profileName, firstLine, "All that measuring and not a copper spent?", "The shelves passed inspection, then. Return when your purse does.")
        elseif culture == VL_CULTURE_ELARINDOR then
            call RegisterVoicedVariationSet(profileName, firstLine, "Look carefully. Fine work reveals itself to patient eyes.", "A discerning choice. May its craft endure.", "It has found hands worthy of its making.", "What remains can still be restored.", "Elarindor will remember the purpose held in this.", "Old craft returns so another piece may travel onward.", "A measured exchange, with nothing of value forgotten.")
            call RegisterNoTransactionVariations(profileName, firstLine, "Nothing called to you today? Then do not force the choice.", "Browse freely. Patience has preserved rarer things than coin.")
        elseif culture == VL_CULTURE_TROLL then
            call RegisterVoicedVariationSet(profileName, firstLine, "Take your time, mon. Good mojo do not rush.", "Good pick. Dis one travel well with you.", "A strong choice. The spirits nod.", "Old goods still got stories left in dem.", "I find dis one another path, no worry.", "Your pack change, my stock change, fortune keep moving.", "Goods and coin both find where dey belong.")
            call RegisterNoTransactionVariations(profileName, firstLine, "No coin moving today? The spirits still counting.", "Nothing catch your eye? Maybe your luck sleeping, mon.")
        elseif culture == VL_CULTURE_ORC then
            call RegisterVoicedVariationSet(profileName, firstLine, "Look well. Weak gear reveals itself before battle.", "Good. Put it to work.", "Strong choice. Do not shame it.", "I will beat some use back into this.", "Scrap for the forge. Nothing wasted.", "Old weight gone. Better gear carried.", "A clean trade. No haggling scars.")
            if profileName == VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE or profileName == VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_BLACKSMITH_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "You stared longer than a sentry and bought less.", "No coin spent? Stop blocking the forge heat.")
            elseif profileName == VL_VENDOR_PROFILE_ORC_FOREST_MALE or profileName == VL_VENDOR_PROFILE_ORC_FOREST_SUPPLIES_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "The leaves have more to say than your purse.", "Return when the wilds teach you what you forgot.")
            else
                call RegisterNoTransactionVariations(profileName, firstLine, "The jungle waits. My paying customers should not.", "No trade? Keep your coin dry on the road ahead.")
            endif
        elseif culture == VL_CULTURE_SATYR then
            call RegisterVoicedVariationSet(profileName, firstLine, "Linger if you wish. Desire ripens beautifully.", "An exquisite surrender to good judgment.", "At last, something proved more tempting than caution.", "Someone less restrained will adore this.", "How useful. Every discarded thing reveals its owner.", "We each leave with a different appetite satisfied.", "Possessions changed; temptation remains wonderfully constant.")
            call RegisterNoTransactionVariations(profileName, firstLine, "So much longing, and not one coin surrendered.", "Nothing tempted you? How unexpectedly disciplined.")
        elseif culture == VL_CULTURE_OGRE then
            call RegisterVoicedVariationSet(profileName, firstLine, "Take time. Both heads still deciding too.", "Good buy. Looks hard to break.", "Smart choice. Other head agrees.", "We fix this. Or sell pieces. Both good.", "Old thing still useful if you hit it right.", "You trade, we trade. Very advanced business.", "Pack different, shelves different. Both heads win.")
            call RegisterNoTransactionVariations(profileName, firstLine, "Looked at everything. Bought nothing. Strange plan.", "No coin? Come back when pockets stop hiding it.")
        elseif culture == VL_CULTURE_GOBLIN then
            call RegisterVoicedVariationSet(profileName, firstLine, "Take your time! Browsing becomes buying with proper encouragement.", "Excellent choice! My ledger agrees.", "A premium decision at a remarkably survivable price.", "I can improve the description and double the price.", "Used goods, fresh margin. Everybody wins eventually.", "Your inventory improves and my projections recover!", "Goods moved, coin moved, and no regulators moved. Perfect.")
            if profileName == VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "A full inspection and not one Riverbane coin moved!", "Browsing fee waived. Toll surcharge pending.")
            elseif profileName == VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "No sale? The harbor has suffered worse wrecks.", "Come back after payday, piracy, or both.")
            elseif profileName == VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "The mosquitoes browse longer, but at least they leave blood.", "No purchase? Jungle humidity must have swollen your purse shut.")
            elseif profileName == VL_VENDOR_PROFILE_GOBLIN_ARENA_MALE then
                call RegisterNoTransactionVariations(profileName, firstLine, "Spectating is cheaper, but far less profitable for me.", "No gear today? The arena sells regret at full price.")
            else
                call RegisterNoTransactionVariations(profileName, firstLine, "No deal? Fine. My cart and prices both move on.", "Next time you see me, browsing may cost extra.")
            endif
        endif
    endfunction

    private function RegisterVoicedProfile takes string profileName, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade, string soundType, integer firstLine, integer extraFirstLine, integer culture returns nothing
        call VendorLines_RegisterProfileSoundType(profileName, soundType)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_CHATTER, chatterA, firstLine)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_CHATTER, chatterB, firstLine + 1)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT, bought, firstLine + 2)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_SOLD, sold, firstLine + 3)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, firstLine + 4)
        call VendorLines_RegisterProfileVoiceLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, firstLine + 5)
        call RegisterCulturalVariations(profileName, extraFirstLine, culture)
    endfunction

    private function RegisterSatyrFemaleProfile takes nothing returns nothing
        call VendorLines_RegisterProfileSoundType(VL_VENDOR_PROFILE_SATYR_FEMALE, VL_GENERIC_SATYR_FEMALE_1_TYPE)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_CHATTER, "How brave of you to approach. Let us discover whether you are equally wealthy.", 1)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_CHATTER, "Everything here has a price. The clever discover it before paying.", 2)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT, "A lovely choice. It almost disguises your limitations.", 3)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_SOLD, "Oh, I can find a more deserving owner for this.", 4)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT_AND_SOLD, "You leave satisfied; I leave knowing precisely what satisfaction cost you.", 5)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_NO_TRANSACTION, "Leaving empty-handed? How disciplined. How terribly dull.", 6)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_CHATTER, "Take your time. Hesitation makes desire so easy to measure.", 7)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT, "At last, a purchase worthy of your better instincts.", 8)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT, "That one suits you. Deceptive at first glance.", 9)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_SOLD, "I can turn this little disappointment into someone else's temptation.", 10)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_SOLD, "Barely used, carelessly owned, and soon profitably forgotten.", 11)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT_AND_SOLD, "You traded certainty for possibility. I do adore optimists.", 12)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_BOUGHT_AND_SOLD, "Your pack is different; your weaknesses remain charmingly familiar.", 13)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_NO_TRANSACTION, "All that longing, and not one coin surrendered.", 14)
        call VendorLines_RegisterProfileVoiceLine(VL_VENDOR_PROFILE_SATYR_FEMALE, VendorLines_LINE_NO_TRANSACTION, "Nothing tempted you? Then I have underestimated your fear.", 15)
    endfunction

    private function RegisterVoiceFamily takes string soundType, integer catalogFirstLine, string folder returns nothing
        call SaveInteger(VL_VoiceFamily, StringHash(soundType), 0, catalogFirstLine)
        call SaveStr(VL_VoiceFamily, StringHash(soundType), 1, folder)
        call VendorLines_RegisterSoundTypeCatalogStart(soundType, catalogFirstLine)
    endfunction

    private function RegisterVoiceCatalog takes string soundType, string catalogName returns nothing
        local integer familyKey = StringHash(soundType)
        local integer catalogIndex = LoadInteger(VL_VendorCatalog, StringHash(catalogName), 0)
        local integer firstLine = LoadInteger(VL_VoiceFamily, familyKey, 0) + (catalogIndex - 1) * VL_VENDOR_CATALOG_LINE_COUNT
        local string folder = LoadStr(VL_VoiceFamily, familyKey, 1)

        if catalogIndex > 0 and folder != null and folder != "" then
            call ExSound_RegisterSequence(soundType, firstLine, firstLine + VL_VENDOR_CATALOG_LINE_COUNT - 1, folder)
        endif
    endfunction

    private function RegisterDefaultAndSpecialistLines takes nothing returns nothing
        call RegisterUnvoicedBasicProfile("Merchant", "Take a look. Fair prices today.", "If you have coin, I have goods.", "Let us see what changes hands.", "Come back when your purse is heavier.", "Take your time. Good goods do not fear inspection.", "If you need it for the road, I probably have it.", "A good purchase. May it serve you well.", "I can find a buyer for that.", "A fair exchange both ways.", "Nothing today? The stock will still be here.")
        call RegisterBasicProfile("Blacksmith", "Steel is honest. Coin should be too.", "Blades, mail, tools. All tested before they leave my forge.", "Pick it up if you mean to buy it.", "Keep the edge dry.", "A balanced weapon feels light before it ever strikes.", "Armor should stop a blade, not stop you walking.", "Good choice. I stand behind that work.", "I can melt that down or put a new edge on it.", "Old steel out, better steel in. Sensible.", "No sparks today? Come back when you need honest steel.")
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_RIVERBANE_BLACKSMITH_MALE, "Riverbane roads are hard on boots, buckles, and blades.", "Good steel earns its keep on every patrol.", "That will hold through a Riverbane winter.", "The lower forge can reclaim this metal.", "Worn steel out, Riverbane steel in.", "No work for the forge today? Keep your gear dry.", VL_GENERIC_HUMAN_MALE_1_TYPE, 46, 52, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_BLACKSMITH_MALE, "Mountain fire makes hard steel and harder smiths.", "If the edge chips, you struck like a human.", "Strong iron for a strong hand.", "I hammer this into something less embarrassing.", "Weak gear out. Mountain steel in.", "No trade? Then stop cooling my forge.", VL_GENERIC_ORC_MALE_4_TYPE, 19, 58, VL_CULTURE_ORC)
        call RegisterCatalogBasicProfile("Bag Merchant", "Strong bags. Strong price.", "A bigger pack saves longer walks.", "No bag to carry. I make your pack bigger now.", "Travel lighter, come back richer.")
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_OGRE_BONECRUSHER_BAG_MERCHANT_MALE, "Bonecrusher stitching. Even rocks stay inside.", "Tiny bag makes tiny loot. Graknar fixes.", "Bigger bag. Now bring bigger treasure.", "Graknar keeps this. Maybe sells twice.", "Pack changes, coin changes. Graknar approves.", "No bag? Then carry regret in pockets.", VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 7, 22, VL_CULTURE_OGRE)
        call RegisterBasicProfile("General Goods Merchant", "Supplies for the road, friend.", "A full pack keeps trouble small.", "Take what you need and leave the rest for someone poorer.", "Safe roads and steady coin.", "Rope, water, salves. Heroes always remember them one mile too late.", "The cheapest supply is the one that gets you home.", "Packed and ready. Try not to lose it.", "Used, perhaps. Useless, never.", "A lighter pack and better supplies. Good business.", "Window-shopping is free. My patience is nearly so.")
        call RegisterProfile("Goblin General Goods", "Guaranteed genuine until proven otherwise!", "Bulk discount starts immediately after you buy in bulk.", "No refunds, but compliments are always accepted.", "I know three people who will pay twice that.", "You leave supplied and I leave richer. Perfect balance!", "Not even one purchase? My projections are ruined!")
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ORC_FOREST_SUPPLIES_MALE, "Thornwoods punish travelers who pack poorly.", "A dry bedroll matters when the forest turns cold.", "Use it well, and return from the wilds.", "The clan will find another use for this.", "Good supplies traded without waste.", "Return when the forest teaches you what you forgot.", VL_GENERIC_ORC_MALE_3_TYPE, 25, 67, VL_CULTURE_ORC)
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
        call RegisterBasicProfile("Curiosity Merchant", "The selection changes whenever fortune stirs.", "Rare, odd, and occasionally useful.", "Let us see what changes hands.", "Safe roads until next time.", "Fortune turns the stock when its hour arrives.", "Certainty is expensive. Curiosity is profitable.", "A brave purchase.", "How wonderfully unexpected.", "Chance favored the exchange.", "Even fortune cannot tempt you today.")
        call RegisterBasicProfile("Reagent Merchant", "Reagents for practical and arcane work.", "Everything measured, labeled, and mostly stable.", "Let us see what changes hands.", "Safe roads until next time.", "Purity decides whether a spell sings or sputters.", "Keep crystals apart unless sparks are intended.", "Exactly what the formula calls for.", "I can refine this.", "Raw material traded for prepared stock.", "Return when the recipe demands it.")
        call RegisterBasicProfile("Provisioner", "Food and drink for the road.", "Fresh provisions, clean water.", "Let us see what changes hands.", "Safe roads until next time.", "Never begin a long road on an empty stomach.", "Water weighs less than regret.", "Packed for travel.", "Someone less particular will eat this.", "Old provisions out, fresh supplies in.", "Hunger will negotiate later.")
        call RegisterBasicProfile("Potion Seller", "Healing, mana, and restorative mixtures.", "Read the label before the emergency.", "Let us see what changes hands.", "Safe roads until next time.", "Potions work best before the final breath.", "Never mix two bottles because the colors match.", "Keep it within reach.", "The bottle is worth something, at least.", "Used stock traded for fresh remedies.", "May you remain healthy enough to reconsider.")
        call RegisterBasicProfile("Rare Goods Dealer", "Uncommon goods for uncommon customers.", "Limited stock, limited patience.", "Let us see what changes hands.", "Safe roads until next time.", "Rarity is supply arguing with demand.", "If you see it twice, buy it the second time.", "There may not be another.", "Interesting. I know a collector.", "One rarity replaces another.", "The rarest purchase is restraint.")
        call RegisterBasicProfile("Expedition Supplier", "Everything needed beyond the safe road.", "Prepare here or improvise badly later.", "Let us see what changes hands.", "Safe roads until next time.", "A campfire, salve, and proper tool solve many problems.", "Expeditions fail from small omissions.", "Your pack is better prepared now.", "I can equip another traveler with this.", "Old weight exchanged for useful supplies.", "The wilderness charges more than I do.")
        call RegisterBasicProfile("Trade Goods Merchant", "Materials bought and sold in useful quantities.", "Every craft begins with ordinary goods.", "Let us see what changes hands.", "Safe roads until next time.", "Common materials keep uncommon work moving.", "Markets are built one crate at a time.", "Useful stock for useful work.", "Another artisan will need this.", "Materials exchanged without waste.", "The warehouses remain patient.")
        call RegisterBasicProfile("Beastmaster Supplier", "Feed and field care for loyal beasts.", "A healthy companion fights longer.", "Let us see what changes hands.", "Safe roads until next time.", "Pack food for the beast before yourself.", "Good care earns loyalty no command can force.", "Your companion will approve.", "Another handler can use this.", "Fresh care supplies for old field goods.", "Your beast may have stronger opinions later.")
        call RegisterBasicProfile("Bartender", "Pull up a stool. What are you drinking?", "Ale, water, and something warm for the road.", "Name your drink and mind the mugs.", "Keep your feet steady out there.", "The common brew is common because it works.", "A warm meal keeps the drink from winning too quickly.", "A sound choice. Drink it before it gets warm.", "An unopened bottle always finds another table.", "Fresh drink in, empty pack out.", "No thirst today? That never lasts.")
        call RegisterBasicProfile("Jewelcrafter", "Rings, necklaces, and charms cut with care.", "Small pieces can carry remarkable power.", "Look closely. Fine work rewards patience.", "May it catch the light and turn misfortune.", "A clean setting matters as much as the stone.", "Every gem has a flaw; skill decides whether it shows.", "That piece suits a discerning owner.", "The setting can be reclaimed and shaped again.", "Old adornment out, finer craft in.", "Nothing caught your eye? Then I must polish harder.")
        call RegisterBasicProfile("Spirit Speaker", "The spirits leave signs for those who listen.", "Totems, crystals, and offerings for the old ways.", "Choose with respect; these are more than trinkets.", "Walk with the ancestors beside you.", "A quiet charm can speak louder than a war drum.", "Incense and crystal help impatient ears hear.", "The spirits approve of a prepared traveler.", "Its spirit is faint, but not silent.", "One sacred thing passes for another.", "The spirits counsel patience. I prefer customers.")
        call RegisterBasicProfile("Fel Curio Dealer", "Power always has a price. Mine is clearly marked.", "Ash, essence, and secrets for careful hands.", "Touch nothing unless you intend to own the consequence.", "Try not to summon anything on the road.", "The safest fel relic is the one someone else carries.", "Do not confuse a sealed vessel with a harmless one.", "A dangerous choice. I respect that.", "There is residue enough to interest another buyer.", "Power changes hands; the risk remains.", "Wisdom or cowardice? Either way, no sale.")
        call RegisterBasicProfile("Voodoo Merchant", "Charms, herbs, and spirits in bottles.", "Good mojo for coin. Bad mojo costs extra.", "Pick careful. Some things pick back.", "Keep the spirits amused, mon.", "A proper charm knows who carries it.", "Fresh herbs make friendlier hexes.", "Dis one brings strong fortune.", "Old mojo still got a little bite.", "Your luck changes, my stock changes.", "No deal? The spirits still watching.")
        call RegisterBasicProfile("Arcanist", "Crystals, essences, and disciplined arcana.", "Magic rewards preparation more than confidence.", "Examine the weave before choosing.", "May your formulas remain stable.", "A clean focus prevents a costly correction.", "Essence quality determines the shape of the spell.", "An exact choice for exacting work.", "I can distill what remains of its enchantment.", "Prepared reagents for spent arcana.", "No research today? The mysteries will wait.")
        call RegisterBasicProfile("Magister", "Elarindor's arcane craft endures.", "Relics and refined essences for worthy hands.", "Consider the history carried in each piece.", "May its light guide you back to us.", "A relic is memory given purpose.", "True refinement preserves power without diminishing grace.", "A fitting piece for an ally of discernment.", "Elarindor can restore what remains.", "One fragment of history exchanged for another.", "Patience has preserved these. It can preserve them longer.")
    endfunction

    private function RegisterRaceAndFactionLines takes nothing returns nothing
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_RIVERBANE_MALE, "Riverbane caravans bring new stock every week.", "Keep your purse close in the market quarter.", "A practical choice for Riverbane roads.", "Someone in the lower ward will want this.", "A tidy exchange. Riverbane prospers on trade.", "Another time, then. The market stays busy.", VL_GENERIC_HUMAN_MALE_1_TYPE, 1, 19, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_MALE, "Stormhaven workmanship travels farther than its banners.", "Salt air ruins cheap metal and cheaper cloth.", "Stormhaven quality. Treat it accordingly.", "I will see what the harbor buyers offer.", "Goods out, goods in. The harbor never rests.", "No trade? Enjoy the harbor while you are here.", VL_GENERIC_HUMAN_MALE_1_TYPE, 7, 28, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_NEUTRAL_MALE, "Coin has fewer loyalties than people do.", "I trade with anyone who keeps the peace.", "Fair coin for useful goods.", "No questions asked, within reason.", "That is how neutral ground stays prosperous.", "We can disagree about price another day.", VL_GENERIC_HUMAN_MALE_1_TYPE, 13, 37, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_RIVERBANE_FEMALE, "Riverbane's market wakes before the watch does.", "A careful buyer keeps coin and cargo equally close.", "A sound choice for the roads beyond the walls.", "The lower ward can give this a second life.", "Fair goods for fair coin. Riverbane moves forward.", "Another time. The next caravan may bring something new.", VL_GENERIC_HUMAN_FEMALE_1_TYPE, 1, 19, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_STORMHAVEN_FEMALE, "Stormhaven craft carries well beyond the harbor.", "Sea air tests every buckle, stitch, and blade.", "A fine choice. Keep it clear of the salt spray.", "The harbor buyers will find a use for this.", "One cargo exchanged for another. That is harbor life.", "Nothing today? The tide may bring you back.", VL_GENERIC_HUMAN_FEMALE_1_TYPE, 7, 28, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_HUMAN_NEUTRAL_FEMALE, "Trade travels farther when banners stay outside.", "Peaceful customers receive peaceful prices.", "Useful goods deserve useful hands.", "I know a buyer who values discretion.", "A balanced exchange keeps neutral ground stable.", "We can settle on a price another day.", VL_GENERIC_HUMAN_FEMALE_1_TYPE, 13, 37, VL_CULTURE_HUMAN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_TAUREN_HORDE_MALE, "The Horde's roads are long; choose supplies that endure.", "Earth, hide, and iron each reward patient hands.", "Carry it with strength and purpose.", "Nothing useful should be wasted.", "A fair exchange honors both sides.", "Walk in peace. Return when the road provides a need.", VL_GENERIC_TAUREN_MALE_1_TYPE, 1, 7, VL_CULTURE_TAUREN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_DWARF_MORGRIM_MALE, "Morgrim steel is shaped for mountains, not market shelves.", "A patient hammer leaves no weakness for the cold to find.", "Aye, that piece will earn its weight on the climb.", "There is useful metal beneath these scars.", "Good coin and honest craft; the clan prospers by both.", "Return when stone, steel, or the road gives you reason.", VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, 1, 7, VL_CULTURE_DWARF)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ELARINDOR_MALE, "Elarindor's forges burn softly, but they have not gone cold.", "Every restored relic returns a fragment of our home.", "May it serve you in Elarindor's defense.", "We will restore what usefulness remains.", "A measured exchange, worthy of trusted allies.", "Another time. Patience has preserved us this long.", VL_GENERIC_ELARINDOR_MALE_1_TYPE, 1, 7, VL_CULTURE_ELARINDOR)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ELARINDOR_FEMALE, "The arcane currents around Elarindor still bless careful craft.", "What survives the ruins deserves a discerning keeper.", "Carry it with the grace its makers intended.", "This may yet find purpose among our people.", "A fair exchange strengthens Elarindor.", "Browse as you wish. Memory has taught us patience.", VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, 1, 7, VL_CULTURE_ELARINDOR)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_TROLL_HORDE_MALE, "Horde roads carry good coin and better stories, mon.", "Every charm got a spirit, and every spirit got a price.", "Good choice. Dis one got strong mojo.", "I know where dis can find a second life.", "Goods move, coin moves, fortune moves with dem.", "No trade today? The spirits bring you back.", VL_GENERIC_TROLL_MALE_1_TYPE, 1, 7, VL_CULTURE_TROLL)

        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ORC_FIERY_MOUNTAIN_MALE, "Ash keeps weak steel honest.", "Mountain paths reward a well-packed warrior.", "Good. That belongs in a warrior's hands.", "I can hammer some use back into this.", "You leave better armed and less burdened.", "Then quit blocking the heat from my forge.", VL_GENERIC_ORC_MALE_1_TYPE, 1, 31, VL_CULTURE_ORC)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ORC_FOREST_MALE, "The Thornwoods take payment from careless travelers.", "Sereneglade herbs, Riverbane iron, orcish prices.", "Carry it with honor.", "The forest wastes nothing. Neither do I.", "A worthy exchange beneath the old trees.", "Listen to the leaves, then return with coin.", VL_GENERIC_ORC_MALE_1_TYPE, 7, 40, VL_CULTURE_ORC)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_ORC_SIRENSONG_MALE, "Jungle damp spoils anything packed badly.", "Sirensong paths hide teeth behind every leaf.", "Keep it dry and keep it close.", "The jungle will give this a second purpose.", "Better supplies for the green road ahead.", "The jungle waits even when customers do not.", VL_GENERIC_ORC_MALE_1_TYPE, 13, 49, VL_CULTURE_ORC)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_SATYR_MALE, "Desire makes every price seem reasonable.", "I acquire curios from paths mortals fear to walk.", "An indulgence well chosen.", "How charming. I know exactly who wants this.", "We have each surrendered something tempting.", "Restraint? How unexpectedly dull.", VL_GENERIC_SATYR_MALE_1_TYPE, 1, 7, VL_CULTURE_SATYR)
        call RegisterSatyrFemaleProfile()
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_OGRE_BONECRUSHER_MALE, "Bonecrusher goods survive Bonecrusher customers.", "Two eyes check stock. One eye checks coin.", "Good buy. Hard to break.", "We find use. Or lunch. Probably use.", "You get goods. We get goods. Very clever.", "No buy? Both heads disappointed.", VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1, 13, VL_CULTURE_OGRE)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_GOBLIN_RIVERBANE_MALE, "Riverbane tolls are included in the price. Mostly.", "Local goods, imported goods, plausibly acquired goods!", "Excellent investment! For me and possibly you.", "I already have a buyer with poor judgment.", "You traded up. I traded profitably.", "Browsing fee waived this time.", VL_GENERIC_GOBLIN_MALE_1_TYPE, 1, 31, VL_CULTURE_GOBLIN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_GOBLIN_STORMHAVEN_MALE, "Fresh off the ship, or at least near a ship recently.", "Harbor prices change with the wind and my mood.", "Seaworthy enough! Probably.", "Dockside buyers love mysterious provenance.", "Cargo exchanged and no customs officer in sight.", "Come back after payday or piracy.", VL_GENERIC_GOBLIN_MALE_1_TYPE, 7, 40, VL_CULTURE_GOBLIN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_GOBLIN_SIRENSONG_MALE, "Jungle-tested means it survived the walk to my stall.", "Nothing here bites unless you skip payment.", "A survival essential at a luxury margin.", "Jungle salvage! Very fashionable.", "Supplies rotate, profits accumulate.", "The mosquitoes browse longer than you.", VL_GENERIC_GOBLIN_MALE_1_TYPE, 13, 49, VL_CULTURE_GOBLIN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_GOBLIN_TRAVELLING_MALE, "My shop moves, so decide before it does.", "Every road has customers and unattended cargo.", "Portable, profitable, and now your problem.", "I will sell it three towns from here.", "A complete trade before the wheels cool.", "Next time you see me, the price may have legs.", VL_GENERIC_GOBLIN_MALE_1_TYPE, 19, 58, VL_CULTURE_GOBLIN)
        call RegisterVoicedProfile(VL_VENDOR_PROFILE_GOBLIN_ARENA_MALE, "Arena rules forbid refunds after dismemberment.", "Champions buy quality. Survivors buy replacements.", "That should improve the odds. Slightly.", "Blood washes off. Value remains.", "Old gear out, arena gear in. Bold strategy.", "Spectating is cheaper, but far less profitable for me.", VL_GENERIC_GOBLIN_MALE_1_TYPE, 25, 67, VL_CULTURE_GOBLIN)
    endfunction

    private function RegisterVoiceFamilies takes nothing returns nothing
        call RegisterVoiceFamily(VL_GENERIC_HUMAN_MALE_1_TYPE, 61, "Pots\\Sound\\Voicelines\\GenericHumanMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_HUMAN_MALE_2_TYPE, 61, "Pots\\Sound\\Voicelines\\GenericHumanMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_HUMAN_FEMALE_1_TYPE, 46, "Pots\\Sound\\Voicelines\\GenericHumanFemale1\\")
        call RegisterVoiceFamily(VL_GENERIC_HUMAN_FEMALE_2_TYPE, 46, "Pots\\Sound\\Voicelines\\GenericHumanFemale2\\")
        call RegisterVoiceFamily(VL_GENERIC_TAUREN_MALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericTaurenMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_TAUREN_MALE_2_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericTaurenMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_TAUREN_MALE_3_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericTaurenMale3\\")
        call RegisterVoiceFamily(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericDwarfMorgrimMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_ELARINDOR_MALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericElarindorMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_ELARINDOR_MALE_2_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericElarindorMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericElarindorFemale1\\")
        call RegisterVoiceFamily(VL_GENERIC_ELARINDOR_FEMALE_2_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericElarindorFemale2\\")
        call RegisterVoiceFamily(VL_GENERIC_TROLL_MALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericTrollMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_TROLL_MALE_2_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericTrollMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_1_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_2_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_3_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale3\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_4_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale4\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_5_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale5\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_6_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale6\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_7_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale7\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_8_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale8\\")
        call RegisterVoiceFamily(VL_GENERIC_ORC_MALE_9_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericOrcMale9\\")
        call RegisterVoiceFamily(VL_GENERIC_SATYR_MALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericSatyrMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_SATYR_FEMALE_1_TYPE, 16, "Pots\\Sound\\Voicelines\\GenericSatyrFemale1\\")
        call RegisterVoiceFamily(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 31, "Pots\\Sound\\Voicelines\\GenericOgreBonecrusherMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_GOBLIN_MALE_1_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericGoblinMale1\\")
        call RegisterVoiceFamily(VL_GENERIC_GOBLIN_MALE_2_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericGoblinMale2\\")
        call RegisterVoiceFamily(VL_GENERIC_GOBLIN_MALE_3_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericGoblinMale3\\")
        call RegisterVoiceFamily(VL_GENERIC_GOBLIN_MALE_4_TYPE, 76, "Pots\\Sound\\Voicelines\\GenericGoblinMale4\\")
    endfunction

    private function RegisterVoiceCatalogs takes nothing returns nothing
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Blacksmith")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Trade Goods Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, "Jewelcrafter")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, "Potion Seller")

        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_2_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_FEMALE_2_TYPE, "Faction Quartermaster")

        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_MALE_1_TYPE, "Magister")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_MALE_1_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_MALE_2_TYPE, "Expedition Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ELARINDOR_MALE_2_TYPE, "Shield Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Curiosity Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Expedition Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Profession Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Trade Goods Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Beastmaster Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Jewelcrafter")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Potion Seller")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_2_TYPE, "Travelling Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_3_TYPE, "Cook")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_3_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_3_TYPE, "Fisher")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_3_TYPE, "Shield Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_4_TYPE, "Alchemy Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_4_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_4_TYPE, "Provisioner")
        call RegisterVoiceCatalog(VL_GENERIC_GOBLIN_MALE_4_TYPE, "Rare Goods Dealer")

        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Alchemy Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Arena Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Cooking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Expedition Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Fisher")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Fishing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Leatherworking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Potion Seller")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Profession Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Provisioner")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Skinning Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Cook")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Curiosity Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Mining Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Rare Goods Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_FEMALE_2_TYPE, "Travelling Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Alchemy Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Arcanist")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Arena Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Blacksmith")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Cooking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Expedition Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Fisher")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Fishing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Leatherworking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Potion Seller")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Profession Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Provisioner")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Skinning Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Cook")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Curiosity Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Mining Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Rare Goods Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_HUMAN_MALE_2_TYPE, "Travelling Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Arena Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Cook")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Profession Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Trade Goods Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Curiosity Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Expedition Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Fisher")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Fishing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Rare Goods Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_1_TYPE, "Skinning Supplier")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_2_TYPE, "Arena Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_2_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_2_TYPE, "Bartender")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "General Goods Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Jewelcrafter")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Profession Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Trade Goods Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_3_TYPE, "Travelling Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Beastmaster Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Blacksmith")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Leatherworking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_4_TYPE, "Shield Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Cook")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Cooking Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Miner")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Mining Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_5_TYPE, "Provisioner")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_6_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_6_TYPE, "Fel Curio Dealer")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_7_TYPE, "Alchemy Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_7_TYPE, "Fel Curio Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_7_TYPE, "Potion Seller")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_8_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_8_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_8_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_8_TYPE, "Spirit Speaker")

        call RegisterVoiceCatalog(VL_GENERIC_ORC_MALE_9_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Arena Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Curiosity Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Potion Seller")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Rare Goods Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Reagent Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Travelling Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_SATYR_FEMALE_1_TYPE, "Enchanting Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_FEMALE_1_TYPE, "Potion Seller")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_FEMALE_1_TYPE, "Rare Goods Dealer")
        call RegisterVoiceCatalog(VL_GENERIC_SATYR_FEMALE_1_TYPE, "Reagent Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_1_TYPE, "Blacksmithing Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_1_TYPE, "Provisioner")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_1_TYPE, "Travelling Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_1_TYPE, "Weapons Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_2_TYPE, "Armor Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_2_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_2_TYPE, "Beastmaster Supplier")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_2_TYPE, "Miner")

        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_3_TYPE, "Bartender")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_3_TYPE, "Faction Quartermaster")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_3_TYPE, "Shield Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_TAUREN_MALE_3_TYPE, "Trade Goods Merchant")

        call RegisterVoiceCatalog(VL_GENERIC_TROLL_MALE_1_TYPE, "Bag Merchant")
        call RegisterVoiceCatalog(VL_GENERIC_TROLL_MALE_1_TYPE, "Jewelcrafter")

        call RegisterVoiceCatalog(VL_GENERIC_TROLL_MALE_2_TYPE, "Voodoo Merchant")
    endfunction

    private function Init takes nothing returns nothing
        call RegisterDefaultAndSpecialistLines()
        call RegisterCatalogRoleLines()
        call RegisterRaceAndFactionLines()
        call RegisterVoiceFamilies()
        call ExSound_RegisterSequence(VL_GENERIC_HUMAN_MALE_1_TYPE, 1, 60, "Pots\\Sound\\Voicelines\\GenericHumanMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_HUMAN_MALE_2_TYPE, 1, 60, "Pots\\Sound\\Voicelines\\GenericHumanMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_HUMAN_FEMALE_1_TYPE, 1, 45, "Pots\\Sound\\Voicelines\\GenericHumanFemale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_HUMAN_FEMALE_2_TYPE, 1, 45, "Pots\\Sound\\Voicelines\\GenericHumanFemale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_TAUREN_MALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericTaurenMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_TAUREN_MALE_2_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericTaurenMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_TAUREN_MALE_3_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericTaurenMale3\\")
        call ExSound_RegisterSequence(VL_GENERIC_DWARF_MORGRIM_MALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericDwarfMorgrimMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_ELARINDOR_MALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericElarindorMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_ELARINDOR_MALE_2_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericElarindorMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_ELARINDOR_FEMALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericElarindorFemale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_ELARINDOR_FEMALE_2_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericElarindorFemale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_TROLL_MALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericTrollMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_TROLL_MALE_2_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericTrollMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_1_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_2_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_3_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale3\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_4_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale4\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_5_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale5\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_6_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale6\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_7_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale7\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_8_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale8\\")
        call ExSound_RegisterSequence(VL_GENERIC_ORC_MALE_9_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericOrcMale9\\")
        call ExSound_RegisterSequence(VL_GENERIC_SATYR_MALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericSatyrMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_SATYR_FEMALE_1_TYPE, 1, 15, "Pots\\Sound\\Voicelines\\GenericSatyrFemale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_OGRE_BONECRUSHER_MALE_1_TYPE, 1, 30, "Pots\\Sound\\Voicelines\\GenericOgreBonecrusherMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_GOBLIN_MALE_1_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericGoblinMale1\\")
        call ExSound_RegisterSequence(VL_GENERIC_GOBLIN_MALE_2_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericGoblinMale2\\")
        call ExSound_RegisterSequence(VL_GENERIC_GOBLIN_MALE_3_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericGoblinMale3\\")
        call ExSound_RegisterSequence(VL_GENERIC_GOBLIN_MALE_4_TYPE, 1, 75, "Pots\\Sound\\Voicelines\\GenericGoblinMale4\\")
        call RegisterVoiceCatalogs()
    endfunction
endlibrary
