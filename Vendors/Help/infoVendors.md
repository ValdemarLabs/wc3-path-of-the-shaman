# How the vendor files differ
File | Responsibility
---|---
Shop.j	| Core buying, selling, stock, reputation, zone filtering, and vendor lookup engine.
VendorCatalogs.j | Shared definitions for 26 reusable vendor roles. Many different racial units can use the same catalog.
VendorOrcs.j, VendorElarindor.j, VendorTauren.j, etc. | Connect Object Editor unit rawcodes to a catalog and racial, regional, gendered, or faction voice profile.
VendorBlacksmith.j | A bespoke vendor implementation with its own vendor ID, stock, AI weights, reputation items, unit bindings, and dialogue.
VendorFloatingText.j | Presentation layer that displays the final registered vendor type above units.
VendorQuests.j | Adds quest buttons to the existing vendor dialogue and instantiates separate `qVendorName.j` quest templates by vendor unit rawcode.
Voicelines_VendorLines.j | Single source of truth for merchant greetings, chatter, transaction responses, farewells, voice profiles, sound keys, and sound folders.
Voicelines_VendorQuests.j | Single source of truth for all generic vendor-quest acceptance, progress, and completion dialogue plus sound registration.
VendorVoiceProfiles.j | Compatibility wrapper for older import lists; new dialogue belongs in `Voicelines_VendorLines.j`.

To change spoken vendor content, edit the two files under `Voicelines/`. Vendor faction, catalog, and `qVendorName.j` files now only bind or reference those centralized definitions.

# For example:
o011
  → VendorOrcs
  → Weapons catalog
  → Fiery Mountain Orc voice profile
  → Shop backend
  → <Weapons> floating label
  
VendorBlacksmith.j is specialized and self-contained. VendorCatalogs.j is a shared catalog factory intended for many unit types. Also, a “Blacksmithing Supplier” sells crafting materials and tools, while the dedicated Blacksmith sells weapons, armor, shields, and special reputation stock.
