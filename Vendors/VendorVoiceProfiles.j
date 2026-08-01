/**
    VendorVoiceProfiles

    Author: Valdemar
    Version:

    Description:
    Reusable race, region, and faction voice profiles for PotS vendors. Stock
    libraries bind these profiles to known unit types; map-specific vendors can
    bind individual units without duplicating dialogue data.

    Credits:
    - World of Warcraft vendor categories, used as taxonomy inspiration.

    How to install:
    Import after VendorLines. Bind a profile with
    VendorLines_BindUnitTypeProfile or VendorLines_BindUnitProfile.

    API:
    - Data-only library; use the VendorLines profile binding API.

**/
library VendorVoiceProfiles initializer Init requires VendorLines
    private function RegisterProfile takes string profileName, string chatterA, string chatterB, string bought, string sold, string exchanged, string noTrade returns nothing
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterA, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_CHATTER, chatterB, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT, bought, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_SOLD, sold, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_BOUGHT_AND_SOLD, exchanged, "")
        call VendorLines_RegisterLine(profileName, VendorLines_LINE_NO_TRANSACTION, noTrade, "")
    endfunction

    private function Init takes nothing returns nothing
        call RegisterProfile("Riverbane Human", "Riverbane caravans bring new stock every week.", "Keep your purse close in the market quarter.", "A practical choice for Riverbane roads.", "Someone in the lower ward will want this.", "A tidy exchange. Riverbane prospers on trade.", "Another time, then. The market stays busy.")
        call RegisterProfile("Stormhaven Human", "Stormhaven workmanship travels farther than its banners.", "Salt air ruins cheap metal and cheaper cloth.", "Stormhaven quality. Treat it accordingly.", "I will see what the harbor buyers offer.", "Goods out, goods in. The harbor never rests.", "No trade? Enjoy the harbor while you are here.")
        call RegisterProfile("Neutral Human", "Coin has fewer loyalties than people do.", "I trade with anyone who keeps the peace.", "Fair coin for useful goods.", "No questions asked, within reason.", "That is how neutral ground stays prosperous.", "We can disagree about price another day.")

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
endlibrary
