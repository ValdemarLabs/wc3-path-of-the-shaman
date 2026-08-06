# How the vendor files differ
File | Responsibility
---|---
Shop.j	| Core buying, selling, stock, reputation, zone filtering, and vendor lookup engine.
VendorCatalogs.j | Shared definitions for 27 reusable vendor roles. Many different racial units can use the same catalog.
VendorOrcs.j, VendorElarindor.j, VendorTauren.j, VendorDwarves.j, etc. | Connect Object Editor unit rawcodes to a catalog, explicit reputation faction, and racial, regional, gendered, or faction voice profile.
VendorBlacksmith.j | A bespoke vendor implementation with its own vendor ID, stock, AI weights, reputation items, unit bindings, and dialogue.
VendorFloatingText.j | Presentation layer that displays the final registered vendor type above units.
QuestsAndDialogs/QuestsGeneric.j | Reusable kill, fetch, and talk quest templates, requirements, rewards, dialogue sequences, and daily acceptance variants for any NPC.
QuestsAndDialogs/QuestsVendor.j | Adapts generic quests to vendor dialogue and retains shop-only handoffs, purchase objectives, stock detection, and ShopUI continuation.
Voicelines_VendorLines.j | Single source of truth for merchant greetings, chatter, transaction responses, farewells, voice profiles, sound keys, and sound folders.
Voicelines_Quests.j | Single source of truth for shared quest dialogue, daily variants, normal-quest extensions, and sound registration.
VendorVoiceProfiles.j | Compatibility wrapper for older import lists; new dialogue belongs in `Voicelines_VendorLines.j`.

To change spoken vendor content, edit `Voicelines_VendorLines.j`; to change generic quest dialogue, edit `Voicelines_Quests.j`. Vendor faction, catalog, and `qVendorName.j` files only bind or reference those centralized definitions.

# For example:
o011
  → VendorOrcs
  → Weapons catalog
  → Fiery Mountain Orc voice profile
  → Shop backend
  → <Weapons> floating label
  
VendorBlacksmith.j is specialized and self-contained. VendorCatalogs.j is a shared catalog factory intended for many unit types. Also, a “Blacksmithing Supplier” sells crafting materials and tools, while the dedicated Blacksmith sells weapons, armor, shields, and special reputation stock.
