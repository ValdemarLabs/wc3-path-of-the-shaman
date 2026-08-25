# Generic and vendor quest roster

Import in this order: `QuestsGeneric.j`, `Voicelines_Quests.j`,
`QuestsVendor.j`, the desired `qVendorName.j` libraries, `VendorCatalogs.j`,
all `VendorFactions/Vendor*.j` libraries, and `VendorDialogs.j`.
`VendorDialogs.j` discovers placed vendor units and instantiates every quest
registered for their unit type.

Vendor quest acceptance/completion text, shared progress dialogue, sound-key
ranges, and daily random pools are controlled from
`Voicelines/Voicelines_Quests.j`. Nazgrek and Zul'kis generic reply text and
registration are owned by `Voicelines_Nazgrek.j` and `Voicelines_Zulkis.j`.
Reusable profile prefixes and external sound folders are registered by
`Voicelines/Voicelines_VendorLines.j`. Individual `qVendorName.j` libraries
reference authored text constants while using the same numbered voice profile
assigned to that NPC's vendor dialogue.

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
| `o011` | Kargun Ashblade | Ore for the Edge | Daily | `GenericOrcMale9_1001-1002` |
| `o011` | Kargun Ashblade | Steel Proven in Blood | Normal | `GenericOrcMale9_1025-1028` |
| `o012` | Drokmar Ironhide | Thin the Shadowdancers | Daily | `GenericOrcMale4_1003-1004` |
| `o013` | Varok Emberwall | Straps for the Line | Daily | `GenericOrcMale3_1005-1006` |
| `o00A` | Ghorak Bloodmark | A Worthy Warm-Up | Daily | `GenericOrcMale2_1007-1008` |
| `o00D` | Kazrum Deepdelver | The Deep Vein | Daily | `GenericOrcMale5_1009-1010` |
| `o00G` | Brakkun Coalhand | Keep the Forges Hot | Daily | `GenericOrcMale4_1011-1012` |
| `o00L` | Thurgash Ore-Eye | Tools from the Road | Daily | `GenericOrcMale5_1013-1014` |
| `o00T` | Mordrak Cindercoin | No Troll Toll | Daily | `GenericOrcMale1_1015-1016` |
| `o00B` | Rukgar Longroad | Quartermaster's Parcel | Daily | `GenericOrcMale3_1017-1018` |
| `o00B` | Rukgar Longroad | The Road Takes Its Due | Normal | `GenericOrcMale3_1029-1032` |
| `o00E` | Hurgan Potbelly | Meat for the Evening Pot | Daily | `GenericOrcMale5_1019-1020` |
| `o00C` | Nargash Tidehook | Jungle Catch | Daily | `GenericOrcMale1_1021-1022` |
| `o014` | Gorthak Jungle Banner | Secure the Coastal Stores | Normal | `GenericOrcMale8_1023-1024, 1033-1034` |
| `n02Y` | Xyros Bloodwager | Cull the Stalkers | Daily | `GenericSatyrMale1_1001-1002` |
| `n02Z` | Velyssra the Covetous | Crystals in the Gloom | Daily | `GenericSatyrFemale1_1003-1004` |
| `n02Z` | Velyssra the Covetous | A Collector's Price | Normal | `GenericSatyrFemale1_1013-1016` |
| `n030` | Malthera Duskmoss | Essence Without Questions | Daily | `GenericSatyrFemale1_1005-1006` |
| `n031` | Ithryssa Runehorn | A Sealed Flask | Daily | `GenericSatyrFemale1_1007-1008` |
| `n033` | Selyth Venomcup | Bitter Leaves | Daily | `GenericSatyrFemale1_1009-1010` |
| `n038` | Faelrix Wayhoof | Silence on the Old Path | Normal | `GenericSatyrMale1_1011-1012, 1017-1018` |
| `n035` | Garrick Holt | Riverbane Iron | Daily | `GenericHumanMale1_1001-1002` |
| `n035` | Garrick Holt | Riverbane's Reserve | Normal | `GenericHumanMale1_1019-1022` |
| `n039` | Edric Vale | Patches for the Watch | Daily | `GenericHumanMale2_1003-1004` |
| `n03A` | Rowan Targe | Gnolls at the Palisade | Daily | `GenericHumanMale1_1005-1006` |
| `n03D` | Silas Reed | Stormhaven Supper | Daily | `GenericHumanMale1_1007-1008` |
| `n03D` | Silas Reed | The Deepwater Table | Normal | `GenericHumanMale1_1023-1026` |
| `n03F` | Owen Marlow | Stock the Smokehouse | Daily | `GenericHumanMale2_1009-1010` |
| `n03E` | Tobin Slate | Lantern Fuel | Daily | `GenericHumanMale2_1011-1012` |
| `n03P` | Cedran Pike | The Travelling Manifest | Daily | `GenericHumanMale2_1013-1014` |
| `n03C` | Merrick Wayland | The Toll Road | Normal | `GenericHumanMale2_1015-1016, 1027-1028` |
| `n03T` | Edwin Harrow | Morning Herbs | Daily | `GenericHumanMale1_1017-1018` |
| `n03W` | Nackle Quickdeal | Essence Speculation | Daily | `GenericGoblinMale1_1001-1002` |
| `n03W` | Nackle Quickdeal | The Long Investment | Normal | `GenericGoblinMale1_1021-1024` |
| `n03X` | Rixit Roadcoin | A Favor Between Merchants | Daily | `GenericGoblinMale2_1003-1004` |
| `n03X` | Rixit Roadcoin | A Cart Worth Guarding | Normal | `GenericGoblinMale2_1017-1020` |
| `n03Y` | Giznak Edgeprice | Field-Tested Steel | Daily | `GenericGoblinMale1_1005-1006` |
| `n041` | Fizzik Hookline | Catch of the Minute | Daily | `GenericGoblinMale3_1007-1008` |
| `n042` | Krikzak Deepcut | Ore Futures | Daily | `GenericGoblinMale4_1009-1010` |
| `n043` | Nibbs Hotpan | Emergency Skewers | Daily | `GenericGoblinMale3_1011-1012` |
| `n046` | Grizzik Bloodbet | Prizefighter's Proof | Normal | `GenericGoblinMale3_1013-1014, 1025-1026` |
| `n04A` | Razwick Goldglint | Reagent on Credit | Daily | `GenericGoblinMale4_1015-1016` |
| `n04E` | Mugrok Ironclub | Break the Stalkers | Daily | `GenericOgreBonecrusherMale1_1001-1002` |
| `n04E` | Mugrok Ironclub | A Weapon's Reputation | Normal | `GenericOgreBonecrusherMale1_1011-1014` |
| `n04F` | Grumbar Thickhide | Thick Hide, Thick Armor | Daily | `GenericOgreBonecrusherMale1_1003-1004` |
| `n04G` | Bolguk Broadwall | Heavy Metal | Daily | `GenericOgreBonecrusherMale1_1005-1006` |
| `n04H` | Kragmog Skullstake | Pit Supplies | Daily | `GenericOgreBonecrusherMale1_1007-1008` |
| `n04J` | Gubmog Stewpot | The Bigger Stew | Normal | `GenericOgreBonecrusherMale1_1009-1010, 1015-1016` |
| `h00L` | Aerendir Sunblade | Wraiths at the Forge | Daily | `GenericElarindorMale1_1001-1002` |
| `h00L` | Aerendir Sunblade | Relics of the Fallen Forge | Normal | `GenericElarindorMale1_1009-1012` |
| `h00Q` | Elowen Starweaver | Fragments of Elarindor | Daily | `GenericElarindorFemale2_1003-1004` |
| `h00R` | Vaeriel Dawnflask | Dawn's Restorative | Daily | `GenericElarindorFemale1_1005-1006` |
| `h00S` | Maerith Silvercrest | A Precise Inventory | Daily | `GenericElarindorFemale2_1007-1008` |
| `h00S` | Maerith Silvercrest | The Quartermaster's Oath | Normal | `GenericElarindorFemale2_1013-1016` |
| `o01B` | Boran Flintmane | Fuel for the Warforge | Daily | `GenericTaurenMale1_1001-1002` |
| `o01C` | Tawa Deepvein | Stonebreaker's Measure | Daily | `GenericTaurenMale2_1003-1004` |
| `o01D` | Koro Windpack | Gnolls on the Supply Trail | Daily | `GenericTaurenMale3_1005-1006` |
| `o01E` | Nara Stormhoof | Shadow over the Long Road | Daily | `GenericTaurenMale1_1007-1008` |

External audio uses one folder per reusable profile, for example
`Pots\Sound\Voicelines\GenericOrcMale4\`, `GenericGoblinMale3\`, `GenericHumanMale2\`, or
`GenericElarindorFemale2\`. Shop and quest files for an NPC stay together in that
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
Nazgrek and Zul'kis use `NazgrekGeneric_0001-0028` and
`ZulkisGeneric_0001-0028`. Four randomized personality-specific replies are
registered for each accept, kill completion, talk completion, fetch completion,
progress, supply-handoff, and quest-purchase interaction.
Missing files fall back to ExSound's text-duration estimation until recordings
are imported.

## Named bag vendors

Graknar is both the original bag merchant and the owner of `Mistaken Kin` in
`qGraknar.j`. Rawcode `o61S` must therefore identify only the canonical
Graknar placed in World Editor. Replace any additional placed `o61S` bag
merchants with distinct unit rawcodes and names before importing qGraknar.

`VendorBags.j` currently binds the Graknar bag catalog by unit type. New bag
merchants should receive explicit catalog/name setup for their own rawcodes;
do not register another identity as `o61S`, because quest-giver assignment and
respawn restoration also use that rawcode.

## A Night To Remember witnesses

`qANightToRemember.j` selects three witnesses per hangover run. When active AI
company heroes are available, one or two are selected and the remaining slots
come from the 15-vendor Horde pool. Stored AI unit references remain valid if
the companion later leaves or is kicked, provided the unit remains alive and
non-hostile. The eligible qXXX libraries register Kargun, Drokmar, Varok,
Rukgar, Nargash, Hurgan, Brakkun, Mordrak, Gorthak, Boran, Tawa, Koro, Nara,
Zanjin, and Rokjin.

One or two witnesses may require a small kill, supply, or apology task before
the requirement completes. These use the same lightweight objective concepts
as generic/vendor quests, but remain staged inside the repeatable Night quest
to avoid creating conflicting child quests.

The shared profile reply pools use `1101-1107` for Orc and Tauren voices and
`1001-1007` for Troll voices: five personal recollections, one amends request,
and one forgiveness reply. Recollections share five story categories with
Nazgrek and Zul'kis response pools, so the hungover hero's next line answers
the event that the witness actually described. `qZanjinGemeye.j` and
`qRokjinHexsmoke.j` are registration-only libraries until those vendors
receive ordinary quests.
