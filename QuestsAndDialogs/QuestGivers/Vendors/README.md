# Vendor quest roster

Import `VendorQuests.j`, `Voicelines_VendorQuests.j`, and the desired
`qVendorName.j` libraries. `VendorDialogs.j` discovers placed vendor units and
instantiates every quest registered for their unit type.

The suggested Object Editor unit names below match the quest-library names and
the cross-vendor objective text.

| Rawcode | Suggested unit name | Quest | Type | Voice keys |
|---|---|---|---|---|
| `o011` | Ghorak Ironjaw | Ore for the Edge | Daily | `VendorQuestOrc_0001-0002` |
| `o012` | Mazgura Stonehide | Thin the Shadowdancers | Daily | `VendorQuestOrc_0003-0004` |
| `o013` | Brakka Bulwark | Straps for the Line | Daily | `VendorQuestOrc_0005-0006` |
| `o00A` | Kargul Bloodring | A Worthy Warm-Up | Daily | `VendorQuestOrc_0007-0008` |
| `o00D` | Drogun Deepdelver | The Deep Vein | Daily | `VendorQuestOrc_0009-0010` |
| `o00G` | Thrag Forgehand | Keep the Forges Hot | Daily | `VendorQuestOrc_0011-0012` |
| `o00L` | Mokkar Orekeeper | Tools from the Road | Daily | `VendorQuestOrc_0013-0014` |
| `o00T` | Zagrim Cindercoin | No Troll Toll | Daily | `VendorQuestOrc_0015-0016` |
| `o00B` | Rukha Trailhoof | Quartermaster's Parcel | Daily | `VendorQuestOrc_0017-0018` |
| `o00E` | Graasha Emberpot | Meat for the Evening Pot | Daily | `VendorQuestOrc_0019-0020` |
| `o00C` | Nokta Wildhook | Jungle Catch | Daily | `VendorQuestOrc_0021-0022` |
| `o014` | Vargan Warstock | Secure the Coastal Stores | Normal | `VendorQuestOrc_0023-0024` |
| `n02Y` | Vaelthorn Red Arena | Cull the Stalkers | Daily | `VendorQuestSatyr_0001-0002` |
| `n02Z` | Xyraphos Gloamtrade | Crystals in the Gloom | Daily | `VendorQuestSatyr_0003-0004` |
| `n030` | Maltheris Essencebroker | Essence Without Questions | Daily | `VendorQuestSatyr_0005-0006` |
| `n031` | Ithryx Runebinder | A Sealed Flask | Daily | `VendorQuestSatyr_0007-0008` |
| `n033` | Selyth Venomcup | Bitter Leaves | Daily | `VendorQuestSatyr_0009-0010` |
| `n038` | Vezrakar Wayfarer | Silence on the Old Path | Normal | `VendorQuestSatyr_0011-0012` |
| `n035` | Garrick Holt | Riverbane Iron | Daily | `VendorQuestHuman_0001-0002` |
| `n039` | Elayne Ward | Patches for the Watch | Daily | `VendorQuestHuman_0003-0004` |
| `n03A` | Cedric Vale | Gnolls at the Palisade | Daily | `VendorQuestHuman_0005-0006` |
| `n03D` | Maren Tidewell | Stormhaven Supper | Daily | `VendorQuestHuman_0007-0008` |
| `n03F` | Odette Hearth | Stock the Smokehouse | Daily | `VendorQuestHuman_0009-0010` |
| `n03E` | Bram Stone | Lantern Fuel | Daily | `VendorQuestHuman_0011-0012` |
| `n03P` | Marshal Rowan | The Travelling Manifest | Daily | `VendorQuestHuman_0013-0014` |
| `n03C` | Elias Roam | The Toll Road | Normal | `VendorQuestHuman_0015-0016` |
| `n03T` | Mira Voss | Morning Herbs | Daily | `VendorQuestHuman_0017-0018` |
| `n03W` | Zizzik Quickdeal | Essence Speculation | Daily | `VendorQuestGoblin_0001-0002` |
| `n03X` | Brakko Roadcoin | A Favor Between Merchants | Daily | `VendorQuestGoblin_0003-0004` |
| `n03Y` | Razzik Sharpsale | Field-Tested Steel | Daily | `VendorQuestGoblin_0005-0006` |
| `n041` | Nibbs Netcaster | Catch of the Minute | Daily | `VendorQuestGoblin_0007-0008` |
| `n042` | Grizzle Drillbit | Ore Futures | Daily | `VendorQuestGoblin_0009-0010` |
| `n043` | Bimble Sizzlepot | Emergency Skewers | Daily | `VendorQuestGoblin_0011-0012` |
| `n046` | Wixx Prizebroker | Prizefighter's Proof | Normal | `VendorQuestGoblin_0013-0014` |
| `n04A` | Krikzak Raregear | Reagent on Credit | Daily | `VendorQuestGoblin_0015-0016` |
| `n04E` | Mugrak Boneedge | Break the Stalkers | Daily | `VendorQuestBonecrusher_0001-0002` |
| `n04F` | Dorga Ironbelly | Thick Hide, Thick Armor | Daily | `VendorQuestBonecrusher_0003-0004` |
| `n04G` | Krunn Broadshield | Heavy Metal | Daily | `VendorQuestBonecrusher_0005-0006` |
| `n04H` | Gromm Pitmaster | Pit Supplies | Daily | `VendorQuestBonecrusher_0007-0008` |
| `n04J` | Hukka Potstir | The Bigger Stew | Normal | `VendorQuestBonecrusher_0009-0010` |

Expected external sound folders:

- `Pots\Sound\Voicelines\VendorQuestOrc\`
- `Pots\Sound\Voicelines\VendorQuestSatyr\`
- `Pots\Sound\Voicelines\VendorQuestHuman\`
- `Pots\Sound\Voicelines\VendorQuestGoblin\`
- `Pots\Sound\Voicelines\VendorQuestBonecrusher\`

Each quest uses the odd-numbered key for acceptance and the following
even-numbered key for completion. Missing files fall back to ExSound's text
duration estimation until recordings are imported.
