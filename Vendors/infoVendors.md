# How the vendor files differ
File | Responsibility
Shop.j	| Core buying, selling, stock, reputation, zone filtering, and vendor lookup engine.
VendorCatalogs.j | Shared definitions for 26 reusable vendor roles. Many different racial units can use the same catalog.
VendorOrcs.j, etc. | Connect Object Editor unit rawcodes to a catalog and racial/regional voice profile.
VendorBlacksmith.j | A bespoke vendor implementation with its own vendor ID, stock, AI weights, reputation items, unit bindings, and dialogue.
VendorFloatingText.j |Presentation layer that displays the final registered vendor type above units.
VendorQuests.j | Adds quest buttons to the existing vendor dialogue and instantiates separate `qVendorName.j` quest templates by vendor unit rawcode.

# For example:
o011
  → VendorOrcs
  → Weapons catalog
  → Fiery Mountain Orc voice profile
  → Shop backend
  → <Weapons> floating label
  
VendorBlacksmith.j is specialized and self-contained. VendorCatalogs.j is a shared catalog factory intended for many unit types. Also, a “Blacksmithing Supplier” sells crafting materials and tools, while the dedicated Blacksmith sells weapons, armor, shields, and special reputation stock.
