`VendorCatalogs.j` registers these canonical names by unit rawcode, so vendor dialogue and quest-giver headings do not depend on Object Editor names. The `Name`, `Editor Suffix`, and `Gender` fields may still mirror this roster for clearer Object Editor entries. `Yes` in the quest-giver column means a matching `qVendorName.j` library exists; the parenthesized classification shows whether it registers daily, normal, or both quest types.

`Intended zone` is map-placement guidance derived from the regional assignments in the vendor faction libraries. It does not place or restrict the unit at runtime. A slash-separated value permits any of the listed zones, while `unspecified` means that no exact settlement or arena has been selected yet.

### Legacy building shops (do not use as dialogue vendors)

These Object Editor units are retained only as legacy building objects. They are deliberately absent from `VendorCatalogs`, `GeneralGoodsVendor`, and AI shop bindings: `nmrk` Marketplace, `ngme` Goblin Merchant, `n61F` Marketplace 2, `n608` Tavern, `n60N` Tome Merchant, `o60G` Armorsmith, `o60M` Orbs, `o60N` Rings, `o60K` Spirit Lodge, `o609` Voodoo Lounge, and `o60Q` Weaponsmith.

### Orc vendors

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `o011` | Kargun Ashblade | Weapons Vendor | Male | Dragonfire Peaks | Yes (Daily + Normal) | Yes |
| `o012` | Drokmar Ironhide | Armor Vendor | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o013` | Varok Emberwall | Shield Vendor | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00A` | Ghorak Bloodmark | Arena Quartermaster | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00B` | Rukgar Longroad | Travelling Merchant | Male | Thornwoods / Havenwoods / Sereneglade | Yes (Daily + Normal) | Yes |
| `o00C` | Nargash Tidehook | Fisher | Male | Sirensong | Yes (Daily) | Yes |
| `o00D` | Kazrum Deepdelver | Miner | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00E` | Hurgan Potbelly | Cook | Male | Thornwoods / Havenwoods / Sereneglade | Yes (Daily) | Yes |
| `o00F` | Zarkul Vialroot | Alchemy Supplier | Male | Sirensong | — | Yes |
| `o00G` | Brakkun Coalhand | Blacksmithing Supplier | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00H` | Dagrok Firekeeper | Cooking Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00I` | Velgor Runeleaf | Enchanting Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00J` | Mokrag Reedline | Fishing Supplier | Male | Sirensong | — | Yes |
| `o00K` | Kragmar Hidebinder | Leatherworking Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00L` | Thurgash Ore-Eye | Mining Supplier | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00M` | Lokruk Skinner | Skinning Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00N` | Garshan Manytools | Profession Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00O` | Korghan Greenbanner | Faction Quartermaster | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00P` | Snagrok Oddskeeper | Curiosity Merchant | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00Q` | Urgash Saltleaf | Reagent Merchant | Male | Sirensong | — | Yes |
| `o00R` | Grosh Fullbelly | Provisioner | Male | Verdant Plains | — | Yes |
| `o00S` | Mazgor Bitterbrew | Potion Seller | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00T` | Mordrak Cindercoin | Rare Goods Dealer | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o00U` | Dravok Trailwise | Expedition Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00V` | Korgul Barterhand | Trade Goods Merchant | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00W` | Brugar Beastfriend | Beastmaster Supplier | Male | Thornwoods / Havenwoods / Sereneglade | — | Yes |
| `o00X` | Rethgar Reefblade | Sirensong Weapons Vendor | Male | Sirensong | — | Yes |
| `o00Y` | Vrokan Scalehide | Sirensong Armor Vendor | Male | Sirensong | — | Yes |
| `o00Z` | Shargul Tidewall | Sirensong Shield Vendor | Male | Sirensong | — | Yes |
| `o010` | Krazhan Far-Sail | Sirensong Travelling Merchant | Male | Sirensong | — | Yes |
| `o014` | Gorthak Jungle Banner | Sirensong Quartermaster | Male | Sirensong | Yes (Normal) | Yes |
| `o01H` | Borug Foamaxe | Bartender | Male | Thornwoods / Havenwoods | — | No |
| `o01I` | Krogar Caskfire | Bartender | Male | Dragonfire Peaks | — | No |
| `o01J` | Zugrak Gemfang | Jewelcrafter | Male | Dragonfire Peaks | — | No |
| `o01K` | Drekhan Spiritbead | Shamanic Goods Vendor | Male | Sereneglade / Thornwoods | — | Yes |
| `o01L` | Vorgra Totemveil | Shamanic Goods Vendor | Male | Sirensong | — | Yes |
| `o01M` | Gulvar Ashsigil | Fel Curio Dealer | Male | Dragonfire Peaks | — | Yes |
| `o01N` | Morzun Felwhisper | Fel Curio Dealer | Male | Havenwoods / Thornwoods | — | Yes |

Notes:
- Ghorak is weird as arena quarmaster in dragonpeaks where there is no arena related stuff.
- Dagrok is placed with ogres, maybe ogres think he is eatable.

### Satyr vendors

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `n02Y` | Xyros Bloodwager | Arena Quartermaster | Male | Sereneglade / Weeping Hollow | Yes (Daily) | Yes |
| `n02Z` | Velyssra the Covetous | Rare Goods Dealer | Female | Sereneglade / Weeping Hollow | Yes (Daily + Normal) | Yes |
| `n030` | Malthera Duskmoss | Reagent Merchant | Female | Sereneglade / Weeping Hollow | Yes (Daily) | Yes |
| `n031` | Ithryssa Runehorn | Enchanting Supplier | Female | Sereneglade / Weeping Hollow | Yes (Daily) | Yes |
| `n032` | Zarethis Oddhoof | Curiosity Merchant | Male | Sereneglade / Weeping Hollow | — | Yes |
| `n033` | Selyth Venomcup | Potion Seller | Female | Sereneglade / Weeping Hollow | Yes (Daily) | Yes |
| `n034` | Krythos Thornblade | Weapons Vendor | Male | Weeping Hollow | — | Yes |
| `n036` | Velthyr Nighthide | Armor Vendor | Male | Weeping Hollow | — | Yes |
| `n037` | Ozyr Blackhorn | Shield Vendor | Male | Weeping Hollow | — | Yes |
| `n038` | Faelrix Wayhoof | Travelling Merchant | Male | Sereneglade / Weeping Hollow / travelling | Yes (Normal) | Yes |

### Human vendors

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `n035` | Garrick Holt | Riverbane Weapons Vendor | Male | Riverbane / outskirts | Yes (Daily + Normal) | No |
| `n039` | Edric Vale | Riverbane Armor Vendor | Male | Riverbane / outskirts | Yes (Daily) | No |
| `n03A` | Rowan Targe | Riverbane Shield Vendor | Male | Riverbane / outskirts | Yes (Daily) | No |
| `n03B` | Roderic Kane | Arena Quartermaster | Male | Dragonfire Peaks | — | No |
| `n03C` | Merrick Wayland | Travelling Merchant | Male | Havenwoods / Vanguard Vale / Sirensong / Ghostwalkridge / Dawnhold | Yes (Normal) | No |
| `n03D` | Silas Reed | Stormhaven Fisher | Male | Stormhaven / outskirts | Yes (Daily + Normal) | No |
| `n03E` | Tobin Slate | Riverbane Miner | Male | Riverbane / outskirts | Yes (Daily) | No |
| `n03F` | Owen Marlow | Stormhaven Cook | Male | Stormhaven / outskirts | Yes (Daily) | No |
| `n03G` | Aldren Voss | Riverbane Alchemy Supplier | Male | Riverbane / outskirts | — | Yes |
| `n03H` | Bram Calder | Riverbane Blacksmithing Supplier | Male | Riverbane / outskirts | — | Yes |
| `n03I` | Percy Bell | Stormhaven Cooking Supplier | Male | Stormhaven / outskirts | — | No |
| `n03J` | Lucan Wren | Stormhaven Enchanting Supplier | Male | Stormhaven / outskirts | — | No |
| `n03K` | Hollis Finn | Stormhaven Fishing Supplier | Male | Stormhaven / outskirts | — | No |
| `n03L` | Osric Tanner | Riverbane Leatherworking Supplier | Male | Riverbane / outskirts | — | No |
| `n03M` | Martin Greaves | Riverbane Mining Supplier | Male | Riverbane / outskirts | — | No |
| `n03N` | Corwin Hale | Riverbane Skinning Supplier | Male | Riverbane / outskirts | — | No |
| `n03O` | Alistair Crane | Profession Supplier | Male | Havenwoods | — | No |
| `n03P` | Cedran Pike | Riverbane Quartermaster | Male | Riverbane / outskirts | Yes (Daily) | No |
| `n03Q` | Jasper Quill | Curiosity Merchant | Male | Sirensong | — | No |
| `n03R` | Elias Moor | Stormhaven Reagent Merchant | Male | Stormhaven / outskirts | — | No |
| `n03S` | Walter Shore | Stormhaven Provisioner | Male | Stormhaven / outskirts | — | No |
| `n03T` | Edwin Harrow | Potion Seller | Male | Vanguard Vale | Yes (Daily) | No |
| `n03U` | Leander Crow | Rare Goods Dealer | Male | Ghostwalkridge / Dawnhold | — | No |
| `n03V` | Roland Mercer | Expedition Supplier | Male | Dragonfire Peaks | — | No |
| `n05C` | Duncan Cask | Stormhaven Bartender | Male | Stormhaven / outskirts | — | No |
| `n05K` | Arlen Wyrd | Stormhaven Arcanist | Male | Stormhaven / outskirts | — | No |
 
### Female Human vendor variants

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `n04O` | Mara Vane | Riverbane Weapons Vendor | Female | Riverbane / outskirts | — | No |
| `n04P` | Elayne Ward | Riverbane Armor Vendor | Female | Riverbane / outskirts | — | No |
| `n04Q` | Catrin Targe | Riverbane Shield Vendor | Female | Riverbane / outskirts | — | No |
| `n04R` | Nora Flint | Riverbane Miner | Female | Riverbane / outskirts | — | No |
| `n04S` | Elira Moss | Riverbane Alchemy Supplier | Female | Riverbane / outskirts | — | No |
| `n04T` | Hester Bellows | Riverbane Blacksmithing Supplier | Female | Riverbane / outskirts | — | No |
| `n04U` | Talia Tanner | Riverbane Leatherworking Supplier | Female | Riverbane / outskirts | — | No |
| `n04V` | Greta Stone | Riverbane Mining Supplier | Female | Riverbane / outskirts | — | No |
| `n04W` | Willa Hart | Riverbane Skinning Supplier | Female | Riverbane / outskirts | — | No |
| `n04X` | Sabine Pike | Riverbane Quartermaster | Female | Riverbane / outskirts | — | No |
| `n04Y` | Maren Tidewell | Stormhaven Fisher | Female | Stormhaven / outskirts | — | No |
| `n04Z` | Odette Hearth | Stormhaven Cook | Female | Stormhaven / outskirts | — | No |
| `n050` | Clara Bell | Stormhaven Cooking Supplier | Female | Stormhaven / outskirts | — | No |
| `n051` | Isolde Wren | Stormhaven Enchanting Supplier | Female | Stormhaven / outskirts | — | No |
| `n052` | Fenna Reed | Stormhaven Fishing Supplier | Female | Stormhaven / outskirts | — | No |
| `n053` | Mira Salt | Stormhaven Reagent Merchant | Female | Stormhaven / outskirts | — | No |
| `n054` | Adele Shore | Stormhaven Provisioner | Female | Stormhaven / outskirts | — | No |
| `n055` | Kessa Kane | Arena Quartermaster | Female | Dragonfire Peaks | — | No |
| `n056` | Elara Wayland | Travelling Merchant | Female | Havenwoods / Vanguard Vale / Sirensong / Ghostwalkridge / Dawnhold | — | No |
| `n057` | Petra Crane | Profession Supplier | Female | Havenwoods | — | No |
| `n058` | Vianne Quill | Curiosity Merchant | Female | Sirensong | — | No |
| `n059` | Celia Harrow | Potion Seller | Female | Vanguard Vale | — | No |
| `n05A` | Lenora Crow | Rare Goods Dealer | Female | Ghostwalkridge / Dawnhold | — | No |
| `n05B` | Roslyn Mercer | Expedition Supplier | Female | Dragonfire Peaks | — | No |
| `n05D` | Marta Vale | Riverbane Bartender | Female | Riverbane / outskirts | — | No |
| `n05E` | Ilyse Faircup | Neutral Bartender | Female | Havenwoods / Vanguard Vale / Sirensong | — | No |

### Goblin vendors

Goblin vendors placed as draft for testing mostly in sirensong zone currently.

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `n03W` | Nackle Quickdeal | Curiosity Merchant | Male | Sereneglade / Thornwoods / Havenwoods | Yes (Daily + Normal) | No |
| `n03X` | Rixit Roadcoin | Travelling Merchant | Male | Sirensong / Havenwoods | Yes (Daily + Normal) | No |
| `n03Y` | Giznak Edgeprice | Weapons Vendor | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `n03Z` | Brizzle Rivetcoat | Armor Vendor | Male | Emberpeak Highlands | — | No |
| `n040` | Skabbin Bucklesnap | Shield Vendor | Male | Thornwoods | — | No |
| `n041` | Fizzik Hookline | Fisher | Male | Sirensong | Yes (Daily) | No |
| `n042` | Krikzak Deepcut | Miner | Male | Dragonfire Peaks / Havenwoods | Yes (Daily) | No |
| `n043` | Nibbs Hotpan | Cook | Male | Sereneglade | Yes (Daily) | No |
| `n044` | Zabble Mixwell | Alchemy Supplier | Male | Sirensong | — | No |
| `n045` | Tinksy Multitool | Profession Supplier | Male | Havenwoods | — | No |
| `n046` | Grizzik Bloodbet | Arena Quartermaster | Male | Dragonfire Peaks | Yes (Normal) | No |
| `n047` | Snikka Sparkdust | Reagent Merchant | Male | Sirensong | — | No |
| `n048` | Poggle Snackstack | Provisioner | Male | Havenwoods | — | No |
| `n049` | Vexli Quickdose | Potion Seller | Male | Emberpeak Highlands | — | No |
| `n04A` | Razwick Goldglint | Rare Goods Dealer | Male | Sereneglade / Thornwoods / Havenwoods | Yes (Daily) | No |
| `n04B` | Bixby Packsmart | Expedition Supplier | Male | Dragonfire Peaks / Sirensong | — | No |
| `n04C` | Mogzik Cratecount | Trade Goods Merchant | Male | Havenwoods | — | No |
| `n04D` | Zippi Beastbits | Beastmaster Supplier | Male | Sirensong / Thornwoods | — | No |
| `n05F` | Kizzi Kegcoin | Bartender | Male | Sereneglade / Havenwoods | — | No |
| `n05I` | Jexxi Gemcut | Jewelcrafter | Male | Sereneglade / Sirensong / travelling | — | No |

### Bonecrusher Ogre vendors

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `n04E` | Mugrok Ironclub | Weapons Vendor | Male | Dragonfire Peaks | Yes (Daily + Normal) | Yes |
| `n04F` | Grumbar Thickhide | Armor Vendor | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `n04G` | Bolguk Broadwall | Shield Vendor | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `n04H` | Kragmog Skullstake | Arena Quartermaster | Male | Havenwoods / Bonecrush Stronghold | Yes (Daily) | Yes |
| `n04I` | Durgan Rockbite | Miner | Male | Dragonfire Peaks | — | Yes |
| `n04J` | Gubmog Stewpot | Cook | Male | Havenwoods / Bonecrush Stronghold | Yes (Normal) | Yes |
| `n04K` | Thrumgar Forgelug | Blacksmithing Supplier | Male | Havenwoods / Bonecrush Stronghold | — | Yes |
| `n04L` | Mogrum Manythings | Profession Supplier | Male | Havenwoods / Bonecrush Stronghold | — | Yes |
| `n04M` | Bargul Bonecount | Bonecrusher Quartermaster | Male | Bonecrush Stronghold | — | Yes |
| `n04N` | Grothak Heavytrade | Trade Goods Merchant | Male | Thornwoods | — | Yes |
| `n05G` | Brugrum Manymugs | Bartender | Male | Havenwoods / Bonecrush Stronghold | — | Yes |

### Elarindor vendors

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---|  
| `h00L` | Aerendir Sunblade | Elarindor Weapons Vendor | Male | Vanguard Vale / Vael'Anorath | Yes (Daily + Normal) | Yes |
| `h00P` | Lyssara Moonweave | Elarindor Armor Vendor | Female | Vanguard Vale / Vael'Anorath | — | Yes |
| `h00M` | Thaelion Spellward | Elarindor Shield Vendor | Male | Vanguard Vale / Vael'Anorath | — | Yes |
| `h00Q` | Elowen Starweaver | Elarindor Enchanting Supplier | Female | Vanguard Vale / Vael'Anorath | Yes (Daily) | Yes |
| `h00N` | Sylvaris Dewleaf | Elarindor Reagent Merchant | Male | Vanguard Vale / Vael'Anorath | — | Yes |
| `h00R` | Vaeriel Dawnflask | Elarindor Potion Seller | Female | Vanguard Vale / Vael'Anorath | Yes (Daily) | Yes |
| `h00O` | Arannis Wayfarer | Elarindor Expedition Supplier | Male | Vanguard Vale / Vael'Anorath | — | Yes |
| `h00S` | Maerith Silvercrest | Elarindor Quartermaster | Female | Vanguard Vale / Vael'Anorath | Yes (Daily + Normal) | Yes |
| `h011` | Saelira Gemwhisper | Elarindor Jewelcrafter | Female | Vanguard Vale / Vael'Anorath | — | Yes |
| `h012` | Caladren Starvault | Elarindor Magister | Male | Vanguard Vale / Vael'Anorath | — | Yes |

### Horde Tauren vendors

These rawcodes are explicitly bound to Horde reputation; placing them under the Horde owner (`Player(5)`) is still recommended for alliance behavior.

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---| 
| `o015` | Korak Ironhorn | Horde Weapons Vendor | Male | Dragonfire Peaks | — | Yes |
| `o016` | Bovan Earthhide | Horde Armor Vendor | Male | Ghostwalkridge / Ironspine Post | — | Yes |
| `o017` | Turog Stoneguard | Horde Shield Vendor | Male | Thornwoods | — | Yes |
| `o018` | Marn Thunderkettle | Horde Provisioner | Male | Sirensong | — | Yes |
| `o019` | Doran Plainstrider | Horde Beastmaster Supplier | Male | Thornwoods / Ghostwalkridge | — | Yes |
| `o01A` | Kargan Redtotem | Horde Quartermaster | Male | Ghostwalkridge / Ironspine Post | — | Yes |
| `o01B` | Boran Flintmane | Horde Blacksmithing Supplier | Male | Dragonfire Peaks | Yes (Daily) | Yes |
| `o01C` | Tawa Deepvein | Horde Miner | Male | Ghostwalkridge / Ironspine Post | Yes (Daily) | Yes |
| `o01D` | Koro Windpack | Horde Trade Goods Merchant | Male | Thornwoods / Sirensong | Yes (Daily) | Yes |
| `o01E` | Nara Stormhoof | Horde Travelling Merchant | Male | Dragonfire Peaks / Sirensong | Yes (Daily) | Yes |
| `o01F` | Harn Earthbrew | Horde Bartender | Male | Ghostwalkridge / Ironspine Post | — | Yes |
| `o01G` | Tobar Keghoof | Horde Bartender | Male | Sirensong | — | Yes |

Trade dialogue uses the `GenericTaurenMale1-3` reusable profiles. The four daily quests use `1001-1014` under the same profile assigned to each giver; missing recordings use text-duration fallback.

### Morgrim Clan Dwarf vendors

Use `Player(7)` as the Morgrim Clan owner. The vendor libraries also bind these rawcodes directly to Morgrim Clan reputation, so trade requirements remain correct during temporary test placement.

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---|
| `h00T` | Durnik Forgefather | Morgrim Blacksmith | Male | Dragonfire Peaks | — | Yes |
| `h00U` | Helgar Ironbraid | Morgrim Blacksmith | Male | Dragonfire Peaks | — | Yes |
| `h00V` | Torren Deepsteel | Morgrim Blacksmith | Male | Emberpeak Highlands | — | Yes |
| `h00W` | Bruni Axeledger | Morgrim Weapons Vendor | Male | Dragonfire Peaks | — | Yes |
| `h00X` | Hildrek Stoneplate | Morgrim Armor Vendor | Male | Havenwoods | — | Yes |
| `h00Y` | Keld Coalvein | Morgrim Blacksmithing Supplier | Male | Dragonfire Peaks | — | Yes |
| `h00Z` | Orin Deepdelver | Morgrim Miner | Male | Dragonfire Peaks | — | Yes |
| `h010` | Magdor Caskcoin | Morgrim Trade Goods Merchant | Male | Havenwoods | — | Yes |
| `h013` | Bromli Alethane | Morgrim Bartender | Male | Dragonfire Peaks | — | Yes |

All Morgrim Dwarf vendors are male. `VendorCatalogs.j` and `VendorDwarves.j` bind `h00T`-`h010` plus bartender `h013` directly. Morgrim trade dialogue uses the reusable `GenericDwarfMorgrimMale1` profile; missing recordings use text-duration fallback.

### Horde Troll vendors

Use Horde ownership where practical. `VendorTrolls.j` binds both rawcodes explicitly to Horde reputation and distributes them between `GenericTrollMale1` and `GenericTrollMale2`.

| Rawcode | Name | Editor suffix | Gender | Intended zone | Quest giver | Placed |
|---|---|---|---|---|---|---|
| `n05H` | Zanjin Gemeye | Horde Jewelcrafter | Male | Horde Lumber mill | — | Yes |
| `n05J` | Rokjin Hexsmoke | Horde Voodoo Merchant | Male | Sirensong | — | Yes |
