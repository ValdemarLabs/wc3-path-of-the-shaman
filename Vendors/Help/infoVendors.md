# How the vendor files differ
File | Responsibility
---|---
Shop.j	| Core buying, selling, stock, reputation, zone filtering, and vendor lookup engine.
VendorCatalogs.j | Shared definitions for 34 reusable vendor roles. Many different racial units can use the same catalog.
VendorOrcs.j, VendorElarindor.j, VendorTauren.j, VendorDwarves.j, etc. | Connect Object Editor unit rawcodes to a catalog, explicit reputation faction, and racial, regional, gendered, or faction voice profile.
VendorDialogs.j | Opens dialogue through the shared global selection listener, returns ShopUI's X button to the vendor choices, and requires every vendor-family binding so missing catalogs fail at compile time instead of silently producing inert units.
VendorBlacksmith.j | A bespoke vendor implementation with its own vendor ID, stock, AI weights, reputation items, unit bindings, and dialogue.
VendorFloatingText.j | Presentation layer that displays the final registered vendor type above units.
QuestsAndDialogs/QuestsGeneric.j | Reusable kill, fetch, talk, and purchase quest templates, requirements, rewards, status-marked dialogue buttons, daily acceptance variants, and generic incomplete-objective lines for any NPC.
QuestsAndDialogs/QuestsVendor.j | Adapts generic quests to vendor dialogue and retains shop-only handoffs, purchase objectives, stock detection, and ShopUI continuation.
Voicelines_VendorLines.j | Single source of truth for merchant greetings, chatter, transaction responses, farewells, voice profiles, sound keys, and sound folders.
Voicelines_Quests.j | Single source of truth for shared quest dialogue, daily variants, normal-quest extensions, and sound registration.
VendorVoiceProfiles.j | Compatibility wrapper for older import lists; new dialogue belongs in `Voicelines_VendorLines.j`.

To change spoken vendor content, edit `Voicelines_VendorLines.j`; to change generic quest dialogue, edit `Voicelines_Quests.j`. Vendor faction, catalog, and `qVendorName.j` files only bind or reference those centralized definitions.

All Morgrim Clan Dwarf vendors are male. Keep their Object Editor names aligned with `VendorsHelper.md` and use the `Morgrim Clan Dwarf Male` dialogue profile with the reusable `GenericDwarfMorgrimMale1` voice; no female Dwarf profile is defined.

ShopUI transaction outcomes are selected from the bought, sold, bought-and-sold, or no-transaction pools when its X button is pressed. The panel then returns to the vendor's dialogue choices. Choosing Exit there restores normal gameplay first and plays the vendor farewell outside cinematic mode.

Autonomous AI heroes discover live Vendor-system units within 6500 range when considering a shop action; catalog vendors do not need manual `AI_AddProfileShopUnitType` bindings. The AI rejects hostile faction links and below-Neutral faction reputation, stays inside profile-restricted zones, prefers closer vendors with affordable useful stock, and weights food, drink, potion, or mystical catalogs more strongly when health or mana is low. Each trip buys at most one item, duplicate consumables are capped at two, and the affordable price ceiling scales from the highest Player(0)-owned hero level rather than the AI hero's level.

QuestMaster instantiates no content on selection. `QuestsVendor.j` performs its own delayed world scan after quest definitions initialize, so placed vendor quest givers exist independently of VendorDialogs and selection. Availability uses the higher level of Player(0)-owned Nazgrek or Zulkis, requires at least Neutral standing with the giver's registered faction, refreshes immediately on hero-level and reputation changes, and retains the five-second evaluation timer as a custom-condition fallback. Shared incomplete dialogue reserves `GenericQuest_0001-0012`, with three alternatives each for kill, fetch, talk, and purchase objectives.

Import `VendorCatalogs.j`, all nine `VendorFactions/Vendor*.j` libraries including `VendorTrolls.j`, and then `VendorDialogs.j`. The delayed world scan registers preplaced quest vendors, while the global selection listener also registers a valid mapped vendor on demand.

Legacy building shops (`nmrk`, `ngme`, `n61F`, `n608`, `n60N`, `o60G`, `o60M`, `o60N`, `o60K`, `o609`, and `o60Q`) are not dialogue vendors. Their Object Editor definitions may remain for old map content, but do not bind them through Shop, VendorCatalogs, GeneralGoodsVendor, or AI shop profiles.

# For example:
o011
  → VendorOrcs
  → Weapons catalog
  → Fiery Mountain Orc voice profile
  → Shop backend
  → <Weapons> floating label
  
VendorBlacksmith.j is specialized and self-contained. VendorCatalogs.j is a shared catalog factory intended for many unit types. Also, a “Blacksmithing Supplier” sells crafting materials and tools, while the dedicated Blacksmith sells weapons, armor, shields, and special reputation stock.
