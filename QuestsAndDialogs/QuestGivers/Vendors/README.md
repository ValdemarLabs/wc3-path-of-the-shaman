# Generic and vendor quest roster

Import in this order: `QuestsGeneric.j`, `Voicelines_Quests.j`,
`QuestsVendor.j`, the desired `qVendorName.j` libraries, `VendorCatalogs.j`,
all `VendorFactions/Vendor*.j` libraries, and `VendorDialogs.j`.
`VendorDialogs.j` discovers placed vendor units and instantiates every quest
registered for their unit type.

All spoken acceptance/completion text, shared progress dialogue, sound-key
ranges, and daily random pools are controlled from
`Voicelines/Voicelines_Quests.j`. Reusable profile prefixes and external sound
folders are registered by `Voicelines/Voicelines_VendorLines.j`. Individual
`qVendorName.j` libraries reference authored text constants while using the
same numbered voice profile assigned to that NPC's vendor dialogue.

`QuestsGeneric.j` has no Shop or Vendor dependency. Non-vendor NPCs can use its
kill, fetch, and talk registration APIs directly, then supply an explicit
display name when registering a placed unit. `QuestsVendor.j` only adds the
shop-specific handoff and purchase flows.

Cross-vendor supply objectives are resolved through a quest-specific choice in
the target vendor's normal dialog; selecting that vendor alone does not advance
the quest. `A Favor Between Merchants` and `Reagent on Credit` continue from
that choice into trade and require the requested catalog item to be purchased
and returned. Other supply quests use a dialogue handoff and can replace their
quest item through the same choice if it was lost before turn-in.

The canonical vendor names below come from `VendorCatalogs.j` and match the
quest-library filenames and library identifiers. Object Editor names may remain
unchanged.

| Rawcode | Canonical vendor name | Quest | Type | Voice keys |
|---|---|---|---|---|
| `o011` | Kargun Ashblade | Ore for the Edge | Daily | `OrcMale9_1001-1002` |
| `o011` | Kargun Ashblade | Steel Proven in Blood | Normal | `OrcMale9_1025-1028` |
| `o012` | Drokmar Ironhide | Thin the Shadowdancers | Daily | `OrcMale4_1003-1004` |
| `o013` | Varok Emberwall | Straps for the Line | Daily | `OrcMale3_1005-1006` |
| `o00A` | Ghorak Bloodmark | A Worthy Warm-Up | Daily | `OrcMale2_1007-1008` |
| `o00D` | Kazrum Deepdelver | The Deep Vein | Daily | `OrcMale5_1009-1010` |
| `o00G` | Brakkun Coalhand | Keep the Forges Hot | Daily | `OrcMale4_1011-1012` |
| `o00L` | Thurgash Ore-Eye | Tools from the Road | Daily | `OrcMale5_1013-1014` |
| `o00T` | Mordrak Cindercoin | No Troll Toll | Daily | `OrcMale1_1015-1016` |
| `o00B` | Rukgar Longroad | Quartermaster's Parcel | Daily | `OrcMale3_1017-1018` |
| `o00B` | Rukgar Longroad | The Road Takes Its Due | Normal | `OrcMale3_1029-1032` |
| `o00E` | Hurgan Potbelly | Meat for the Evening Pot | Daily | `OrcMale5_1019-1020` |
| `o00C` | Nargash Tidehook | Jungle Catch | Daily | `OrcMale1_1021-1022` |
| `o014` | Gorthak Jungle Banner | Secure the Coastal Stores | Normal | `OrcMale8_1023-1024, 1033-1034` |
| `n02Y` | Xyros Bloodwager | Cull the Stalkers | Daily | `SatyrMale1_1001-1002` |
| `n02Z` | Vaelith the Covetous | Crystals in the Gloom | Daily | `SatyrMale1_1003-1004` |
| `n02Z` | Vaelith the Covetous | A Collector's Price | Normal | `SatyrMale1_1013-1016` |
| `n030` | Sythren Duskmoss | Essence Without Questions | Daily | `SatyrMale1_1005-1006` |
| `n031` | Malyr Runehorn | A Sealed Flask | Daily | `SatyrMale1_1007-1008` |
| `n033` | Nymor Vialtongue | Bitter Leaves | Daily | `SatyrMale1_1009-1010` |
| `n038` | Faelrix Wayhoof | Silence on the Old Path | Normal | `SatyrMale1_1011-1012, 1017-1018` |
| `n035` | Garrick Holt | Riverbane Iron | Daily | `HumanMale1_1001-1002` |
| `n035` | Garrick Holt | Riverbane's Reserve | Normal | `HumanMale1_1019-1022` |
| `n039` | Edric Vale | Patches for the Watch | Daily | `HumanMale2_1003-1004` |
| `n03A` | Rowan Targe | Gnolls at the Palisade | Daily | `HumanMale1_1005-1006` |
| `n03D` | Silas Reed | Stormhaven Supper | Daily | `HumanMale1_1007-1008` |
| `n03D` | Silas Reed | The Deepwater Table | Normal | `HumanMale1_1023-1026` |
| `n03F` | Owen Marlow | Stock the Smokehouse | Daily | `HumanMale2_1009-1010` |
| `n03E` | Tobin Slate | Lantern Fuel | Daily | `HumanMale2_1011-1012` |
| `n03P` | Cedran Pike | The Travelling Manifest | Daily | `HumanMale2_1013-1014` |
| `n03C` | Merrick Wayland | The Toll Road | Normal | `HumanMale2_1015-1016, 1027-1028` |
| `n03T` | Edwin Harrow | Morning Herbs | Daily | `HumanMale1_1017-1018` |
| `n03W` | Nackle Quickdeal | Essence Speculation | Daily | `GoblinMale1_1001-1002` |
| `n03W` | Nackle Quickdeal | The Long Investment | Normal | `GoblinMale1_1021-1024` |
| `n03X` | Rixit Roadcoin | A Favor Between Merchants | Daily | `GoblinMale2_1003-1004` |
| `n03X` | Rixit Roadcoin | A Cart Worth Guarding | Normal | `GoblinMale2_1017-1020` |
| `n03Y` | Giznak Edgeprice | Field-Tested Steel | Daily | `GoblinMale1_1005-1006` |
| `n041` | Fizzik Hookline | Catch of the Minute | Daily | `GoblinMale3_1007-1008` |
| `n042` | Krikzak Deepcut | Ore Futures | Daily | `GoblinMale4_1009-1010` |
| `n043` | Nibbs Hotpan | Emergency Skewers | Daily | `GoblinMale3_1011-1012` |
| `n046` | Grizzik Bloodbet | Prizefighter's Proof | Normal | `GoblinMale3_1013-1014, 1025-1026` |
| `n04A` | Razwick Goldglint | Reagent on Credit | Daily | `GoblinMale4_1015-1016` |
| `n04E` | Mugrok Ironclub | Break the Stalkers | Daily | `OgreBonecrusherMale1_1001-1002` |
| `n04E` | Mugrok Ironclub | A Weapon's Reputation | Normal | `OgreBonecrusherMale1_1011-1014` |
| `n04F` | Grumbar Thickhide | Thick Hide, Thick Armor | Daily | `OgreBonecrusherMale1_1003-1004` |
| `n04G` | Bolguk Broadwall | Heavy Metal | Daily | `OgreBonecrusherMale1_1005-1006` |
| `n04H` | Kragmog Skullstake | Pit Supplies | Daily | `OgreBonecrusherMale1_1007-1008` |
| `n04J` | Gubmog Stewpot | The Bigger Stew | Normal | `OgreBonecrusherMale1_1009-1010, 1015-1016` |
| `h00L` | Aerendir Sunblade | Wraiths at the Forge | Daily | `ElarindorMale1_1001-1002` |
| `h00L` | Aerendir Sunblade | Relics of the Fallen Forge | Normal | `ElarindorMale1_1009-1012` |
| `h00Q` | Elowen Starweaver | Fragments of Elarindor | Daily | `ElarindorFemale2_1003-1004` |
| `h00R` | Vaeriel Dawnflask | Dawn's Restorative | Daily | `ElarindorFemale1_1005-1006` |
| `h00S` | Maerith Silvercrest | A Precise Inventory | Daily | `ElarindorFemale2_1007-1008` |
| `h00S` | Maerith Silvercrest | The Quartermaster's Oath | Normal | `ElarindorFemale2_1013-1016` |
| `o01B` | Boran Flintmane | Fuel for the Warforge | Daily | `TaurenMale1_1001-1002` |
| `o01C` | Tawa Deepvein | Stonebreaker's Measure | Daily | `TaurenMale2_1003-1004` |
| `o01D` | Koro Windpack | Gnolls on the Supply Trail | Daily | `TaurenMale3_1005-1006` |
| `o01E` | Nara Stormhoof | Shadow over the Long Road | Daily | `TaurenMale1_1007-1008` |

External audio uses one folder per reusable profile, for example
`Pots\Sound\Voicelines\OrcMale4\`, `GoblinMale3\`, `HumanMale2\`, or
`ElarindorFemale2\`. Shop and quest files for an NPC stay together in that
profile folder. Nazgrek and Zul'kis use their nested character folders:

- `Pots\Sound\Voicelines\Nazgrek\NazgrekGeneric\`
- `Pots\Sound\Voicelines\Zulkis\ZulkisGeneric\`

Each original quest pair uses the odd-numbered key for acceptance and the
following even-numbered key for completion. Every normal quest additionally
uses an acceptance extension and completion extension. Vendor-quest dialogue
uses the `1001+` range of the assigned reusable profile. Daily quests select
one follow-up from a three-line objective/voice pool: Orc `1035-1043`, Satyr
`1019-1027`, Human `1029-1037`, Goblin `1027-1035`, Bonecrusher `1017-1025`,
Elarindor male/female `1017-1025`, and Tauren `1009-1014`.
Nazgrek and Zul'kis use `NazgrekGeneric_0001-0019` and
`ZulkisGeneric_0001-0019`; the first seven cover the current vendor-quest
flows and the remaining replies are reusable by other generic quests.
Missing files fall back to ExSound's text-duration estimation until recordings
are imported.
