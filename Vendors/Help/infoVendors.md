# How the vendor files differ
File | Responsibility
---|---
Shop.j	| Core buying, selling, stock, reputation, zone filtering, and vendor lookup engine.
VendorCatalogs.j | Shared definitions for 27 reusable vendor roles. Many different racial units can use the same catalog.
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

All Morgrim Clan Dwarf vendors are male. Keep their Object Editor names aligned with `VendorsHelper.md` and use only the `Morgrim Clan Dwarf Male` profile and `VendorDwarfMorgrimMale_0001-0015` voice range; no female Dwarf vendor profile is defined.

ShopUI transaction outcomes are selected from the bought, sold, bought-and-sold, or no-transaction pools when its X button is pressed. The panel then returns to the vendor's dialogue choices. Choosing Exit there restores normal gameplay first and plays the vendor farewell outside cinematic mode.

QuestMaster instantiates no content on selection. Vendor quest templates are instantiated during the delayed vendor registration scan, availability is refreshed immediately on hero-level and reputation changes, and the five-second evaluation timer remains as a fallback for custom conditions. Shared incomplete dialogue reserves `QuestGeneric_0001-0012`, with three alternatives each for kill, fetch, talk, and purchase objectives.

Import `VendorCatalogs.j`, all eight `VendorFactions/Vendor*.j` libraries, and then `VendorDialogs.j`. The delayed world scan registers preplaced quest vendors, while the global selection listener also registers a valid mapped vendor on demand.

# For example:
o011
  → VendorOrcs
  → Weapons catalog
  → Fiery Mountain Orc voice profile
  → Shop backend
  → <Weapons> floating label
  
VendorBlacksmith.j is specialized and self-contained. VendorCatalogs.j is a shared catalog factory intended for many unit types. Also, a “Blacksmithing Supplier” sells crafting materials and tools, while the dedicated Blacksmith sells weapons, armor, shields, and special reputation stock.
