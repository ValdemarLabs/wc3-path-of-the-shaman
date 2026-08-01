# Vendor quest roster

Import `VendorQuests.j`, `Voicelines_VendorQuests.j`, and the desired
`qVendorName.j` libraries. `VendorDialogs.j` discovers placed vendor units and
instantiates every quest registered for their unit type.

The canonical vendor names below come from `VendorCatalogs.j` and match the
quest-library filenames and library identifiers. Object Editor names may remain
unchanged.

| Rawcode | Canonical vendor name | Quest | Type | Voice keys |
|---|---|---|---|---|
| `o011` | Kargun Ashblade | Ore for the Edge | Daily | `VendorQuestOrc_0001-0002` |
| `o012` | Drokmar Ironhide | Thin the Shadowdancers | Daily | `VendorQuestOrc_0003-0004` |
| `o013` | Varok Emberwall | Straps for the Line | Daily | `VendorQuestOrc_0005-0006` |
| `o00A` | Ghorak Bloodmark | A Worthy Warm-Up | Daily | `VendorQuestOrc_0007-0008` |
| `o00D` | Kazrum Deepdelver | The Deep Vein | Daily | `VendorQuestOrc_0009-0010` |
| `o00G` | Brakkun Coalhand | Keep the Forges Hot | Daily | `VendorQuestOrc_0011-0012` |
| `o00L` | Thurgash Ore-Eye | Tools from the Road | Daily | `VendorQuestOrc_0013-0014` |
| `o00T` | Mordrak Cindercoin | No Troll Toll | Daily | `VendorQuestOrc_0015-0016` |
| `o00B` | Rukgar Longroad | Quartermaster's Parcel | Daily | `VendorQuestOrc_0017-0018` |
| `o00E` | Hurgan Potbelly | Meat for the Evening Pot | Daily | `VendorQuestOrc_0019-0020` |
| `o00C` | Nargash Tidehook | Jungle Catch | Daily | `VendorQuestOrc_0021-0022` |
| `o014` | Gorthak Jungle Banner | Secure the Coastal Stores | Normal | `VendorQuestOrc_0023-0024` |
| `n02Y` | Xyros Bloodwager | Cull the Stalkers | Daily | `VendorQuestSatyr_0001-0002` |
| `n02Z` | Vaelith the Covetous | Crystals in the Gloom | Daily | `VendorQuestSatyr_0003-0004` |
| `n030` | Sythren Duskmoss | Essence Without Questions | Daily | `VendorQuestSatyr_0005-0006` |
| `n031` | Malyr Runehorn | A Sealed Flask | Daily | `VendorQuestSatyr_0007-0008` |
| `n033` | Nymor Vialtongue | Bitter Leaves | Daily | `VendorQuestSatyr_0009-0010` |
| `n038` | Faelrix Wayhoof | Silence on the Old Path | Normal | `VendorQuestSatyr_0011-0012` |
| `n035` | Garrick Holt | Riverbane Iron | Daily | `VendorQuestHuman_0001-0002` |
| `n039` | Edric Vale | Patches for the Watch | Daily | `VendorQuestHuman_0003-0004` |
| `n03A` | Rowan Targe | Gnolls at the Palisade | Daily | `VendorQuestHuman_0005-0006` |
| `n03D` | Silas Reed | Stormhaven Supper | Daily | `VendorQuestHuman_0007-0008` |
| `n03F` | Owen Marlow | Stock the Smokehouse | Daily | `VendorQuestHuman_0009-0010` |
| `n03E` | Tobin Slate | Lantern Fuel | Daily | `VendorQuestHuman_0011-0012` |
| `n03P` | Cedran Pike | The Travelling Manifest | Daily | `VendorQuestHuman_0013-0014` |
| `n03C` | Merrick Wayland | The Toll Road | Normal | `VendorQuestHuman_0015-0016` |
| `n03T` | Edwin Harrow | Morning Herbs | Daily | `VendorQuestHuman_0017-0018` |
| `n03W` | Nackle Quickdeal | Essence Speculation | Daily | `VendorQuestGoblin_0001-0002` |
| `n03X` | Rixit Roadcoin | A Favor Between Merchants | Daily | `VendorQuestGoblin_0003-0004` |
| `n03Y` | Giznak Edgeprice | Field-Tested Steel | Daily | `VendorQuestGoblin_0005-0006` |
| `n041` | Fizzik Hookline | Catch of the Minute | Daily | `VendorQuestGoblin_0007-0008` |
| `n042` | Krikzak Deepcut | Ore Futures | Daily | `VendorQuestGoblin_0009-0010` |
| `n043` | Nibbs Hotpan | Emergency Skewers | Daily | `VendorQuestGoblin_0011-0012` |
| `n046` | Grizzik Bloodbet | Prizefighter's Proof | Normal | `VendorQuestGoblin_0013-0014` |
| `n04A` | Razwick Goldglint | Reagent on Credit | Daily | `VendorQuestGoblin_0015-0016` |
| `n04E` | Mugrok Ironclub | Break the Stalkers | Daily | `VendorQuestBonecrusher_0001-0002` |
| `n04F` | Grumbar Thickhide | Thick Hide, Thick Armor | Daily | `VendorQuestBonecrusher_0003-0004` |
| `n04G` | Bolguk Broadwall | Heavy Metal | Daily | `VendorQuestBonecrusher_0005-0006` |
| `n04H` | Kragmog Skullstake | Pit Supplies | Daily | `VendorQuestBonecrusher_0007-0008` |
| `n04J` | Gubmog Stewpot | The Bigger Stew | Normal | `VendorQuestBonecrusher_0009-0010` |

Expected external sound folders:

- `Pots\Sound\Voicelines\VendorQuestOrc\`
- `Pots\Sound\Voicelines\VendorQuestSatyr\`
- `Pots\Sound\Voicelines\VendorQuestHuman\`
- `Pots\Sound\Voicelines\VendorQuestGoblin\`
- `Pots\Sound\Voicelines\VendorQuestBonecrusher\`

Each quest uses the odd-numbered key for acceptance and the following
even-numbered key for completion. Missing files fall back to ExSound's text
duration estimation until recordings are imported.
