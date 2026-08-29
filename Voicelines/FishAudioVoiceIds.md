# FishAudio voice reference IDs

These reference IDs are not API secrets. Keep the FishAudio API key only in
the local `FISH_API_KEY` environment variable. `tools/voicelines.ps1` derives a
speaker-specific environment variable from the key prefix, for example
`GenericGoblinMale3_0001` uses `FISH_REFERENCE_ID_GENERICGOBLINMALE3`.

The prefixes below describe reusable character voices, not vendor-only voices.
Vendor chatter, catalog dialogue, and generic quest dialogue can use the same
profile. Vendor quest lines occupy indices `1001+`, allowing the giver to keep
the same voice profile used by their shop dialogue.

| PotS key prefix / speaker filter | FishAudio name | Description | Reference ID | Current use |
|---|---|---|---|---|
| `GenericHumanMale1` | HumanPaladin | Generic human male | `ffa580e4304440e2b78bf2a02d493942` | Alternating Riverbane, Stormhaven, Havenwoods/neutral male vendors and their quests |
| `GenericHumanMale2` | HumanCommander / HumanMale2 | Commander or normal human male; both FishAudio labels resolve to this reference | `9f479b87ab104589affd84b3a31d8362` | Alternating Riverbane, Stormhaven, Havenwoods/neutral male vendors and their quests |
| `GenericHumanFemale1` | HumanFemale1 | Generic human female | `550c2688c6794111858bc5d625a73a95` | Alternating Riverbane, Stormhaven, and neutral female vendors |
| `GenericHumanFemale2` | HumanFemale2 | Generic human female | `cf65d0a5aa184eb7bbb394cbfb26ae93` | Alternating Riverbane, Stormhaven, and neutral female vendors |
| `GenericOrcMale1` | HeroRogue | Agile generic orc male | `6f5776ec9e67431b9aee2ed1f17f902d` | Fiery Mountain rare goods; forest/Sirensong hunters, fishers, and opportunists |
| `GenericOrcMale2` | Kilrogg | Hostile, battle-worn orc male | `d5a4cf05a9c8427e8e9fb6e6de640833` | Fiery Mountain arena/bartender and Sirensong armor |
| `GenericOrcMale3` | Varok | Wise orc male | `b29f7aa78b9c42098b08a3fab7adbe9f` | Fiery Mountain shields; forest/Sirensong travelling, quartermaster, trade, and profession roles |
| `GenericOrcMale4` | OrcGrunt | Orc grunt | `7f2e1215df0444af865febb74d324593` | Armor, shields, blacksmithing, leatherworking, beast supplies, and blacksmiths |
| `GenericOrcMale5` | OrcPeon | Orc peon | `f21002b6d17b4819b0c9ad5107bff001` | Mining, cooking, provisions, and forest bartender roles |
| `GenericOrcMale6` | Orc (Drakthul) | Orc warlock | `c0a73a35c26949b3bc8e9f7501644ae9` | Forest enchanting and Fiery Mountain fel curios |
| `GenericOrcMale7` | Orc (Guldan) | Orc warlock | `5eb0665ce6974a92a38ca309f331d19c` | Sirensong alchemy and forest fel/potion roles |
| `GenericOrcMale8` | Shaman | Orc shaman | `dab87e7b8c7549d691a90076609bc317` | Forest/Sirensong spirit speakers, reagents, and Sirensong quartermaster |
| `GenericOrcMale9` | Shaman (fighter) | Orc fighter | `90a80ffccde247c69af75edf5d66cad2` | Fiery Mountain and Sirensong weapons merchants |
| `GenericTrollMale1` | TrollMale1 | Troll male | `749a792a18654ac19c8668fe9ceb6a31` | Horde Troll jeweller |
| `GenericTroll` / `GenericTrollMale2` | Troll Witch Doctor | Troll witch doctor | `11573f63b7cb42cd919a0ebd0f74aa84` | Darkspear wounded-survivor testimony and Horde Troll voodoo merchant |
| `GenericGoblinMale1` | Goblin2 | Goblin male | `b3e77482cd444ad09b04a33fe6817c32` | Riverbane weapons/professions, travelling trade, reagents, and expedition supplies |
| `GenericGoblinMale2` | Goblin1 | Goblin male | `c8fe49fa32b245c786a26ad2a28e771f` | Riverbane armor/potions, travelling trade, Stormhaven bartender, Sirensong beast supplies |
| `GenericGoblinMale3` | Goblin3 | Goblin male | `7bd87fcdbe1c430a9618e2b5d2bea58d` | Riverbane shields, Stormhaven fishing, Sirensong cooking, and arena quartermaster |
| `GenericGoblinMale4` | Goblin4 | Goblin male | `95394ac5223a4c7bb8314f937c22172e` | Riverbane mining, Sirensong alchemy, Stormhaven provisions, and travelling rare goods |
| `GenericTaurenMale1` | HeroWarrior | Tauren male | `8be8a11dd4524e6a813ac34ce1580008` | Weapons, provisions, blacksmithing, and travelling; matched vendor quests |
| `GenericTaurenMale2` | Furbolg | Deep Tauren-compatible male | `a12406c85a944d7bae13e9164517f920` | Armor, beast supplies, mining, and bartender; matched vendor quests |
| `GenericTaurenMale3` | Tauren Spirit Walker | Tauren spirit walker | `7fa831b0ab1646b58dc7571a65550662` | Shields, quartermaster, trade goods, and bartender; matched vendor quests |
| `GenericSatyrFemale1` | Demoness | Mean, cunning Satyr/demon female | `a168d04c08e042c49311278cb7558473` | Velyssra, Malthera, Ithryssa, and Selyth vendor dialogue, matched vendor quests, and reusable generic quests |
| `GenericSatyrMale1` | SatyrGeneric3 | Satyr male | `3c8c373ad71a46cab3d95f491cfff368` | Current male Satyr vendors and their quests |
| `GenericDwarfMorgrimMale1` | DwarfMale1 | Morgrim dwarf male | `c090db335e8f4fef8427ac98572978c9` | Morgrim vendors and reusable Morgrim dialogue |
| `GenericElarindorMale1` | Human (Emissary) | Elarindor male | `34a5f0dfbce3461180f1f8c788d3b7c0` | Weapons, reagents, and magister; matched vendor quests |
| `GenericElarindorMale2` | ElfMale | Elarindor male | `772caa672ad846a49d7ea5c68648c6a8` | Shields and expedition supplies; matched vendor quests |
| `GenericElarindorFemale1` | Elf (VereesaWindrunner) | Elarindor female | `eefc6b82be3d4907bf419c640d021b0b` | Armor, potions, and jewellery; matched vendor quests |
| `GenericElarindorFemale2` | BloodElfFemale | Elarindor female | `b02accf6560f41419210b67f9431fd5f` | Enchanting and quartermaster; matched vendor quests |
| `GenericOgreBonecrusherMale1` | OgreMale | Bonecrusher ogre male | `065c2be6b4814fe59916ece73d6660b3` | Bonecrusher vendors, bag merchant, and generic quests |
| `NazgrekGeneric` | Nazgrek2 | Nazgrek reusable replies | `82895e2c2e62463bb023c0c858a55b9d` | Generic quests plus matched LastNight responses |
| `Zulkis` / `ZulkisGeneric` | Shadowhunter | Zul'kis story voice and reusable replies | `139c8b251a2f4a97a2dbce510e1f94cf` | Story dialogue, generic quests, and matched LastNight responses |
| `Thork` | Thork | Chieftain Thork | `da8c8f301eea4e9fab1fdd64557e109d` | Chieftain Thork story and quest dialogue |
| `Zulkarak` | TrollMale1 | Zul'karak story voice; shared TrollMale1 profile | `749a792a18654ac19c8668fe9ceb6a31` | Darkspear landing and Rescue the Brother dialogue |
| `Narrator` | Narrator | Story narrator | `df07a1c2278e4fba9fa6a43c424855ac` | Nazgrek and Zul'kis prologue narration |
| `HeroEngineer` | HeroEngineer | Engineer AI hero | `b901bbbb4b3748e5ae04a4defaf7a3c9` | Drunk reaction lines and AI companion dialogue |
| `HeroPaladin` | HeroPaladin | Paladin AI hero | `ffa580e4304440e2b78bf2a02d493942` | Drunk reaction lines and AI companion dialogue |
| `HeroShaman` / `HeroRestoshaman` | HeroRestoshaman | Restoration shaman AI hero | `2f5da025973948bea9c3d21b09a73d8f` | Drunk reaction lines and AI companion dialogue |
| `HeroRogue` | HeroRogue | Rogue AI hero | `6f5776ec9e67431b9aee2ed1f17f902d` | Drunk reaction lines and AI companion dialogue |
| `HeroWarlock` | HeroWarlock | Warlock AI hero | `06209f0d44a146b08ba67d5a8d121f74` | Drunk reaction lines and AI companion dialogue |
| `HeroWarrior` | HeroWarrior | Warrior AI hero | `8be8a11dd4524e6a813ac34ce1580008` | Drunk reaction lines and AI companion dialogue |
| `Aveline` | AI_Aveline | Aveline AI hero | `829032b867d447ebbabc6c30ebba911c` | Drunk reactions, last-night witness lines, amends tasks, and forgiveness replies |

Nazgrek and Zul'kis each register 28 generic lines: four randomized replies
for acceptance, kill completion, talk completion, fetch completion, progress,
supply handoff, and quest purchase. Their text, keys, and sound registration
are owned by `Voicelines_Nazgrek.j` and `Voicelines_Zulkis.j`.

The submitted profile list contained duplicate labels. The two Human male
labels shared one reference ID and are represented by `GenericHumanMale2`. The
two different submitted entries labelled `OrcMale6` were normalized to
`GenericOrcMale6` (Drakthul) and `GenericOrcMale7` (Gul'dan); the following
Shaman/fighter entries consequently use `GenericOrcMale8` and
`GenericOrcMale9`.

`GenericHumanFemale1` avoids colliding with the existing story speaker prefix
`HumanFemale1`. Nazgrek and Zul'kis generic files are stored in:

- `Pots\Sound\Voicelines\Nazgrek\NazgrekGeneric\`
- `Pots\Sound\Voicelines\Zulkis\ZulkisGeneric\`

Example generation command:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\voicelines.ps1 `
    -Mode Generate `
    -Speaker GenericGoblinMale3 `
    -ReferenceId 7bd87fcdbe1c430a9618e2b5d2bea58d
```

Tagged narrator review generations use `Voicelines/FishAudioNarratorTts.csv`
with `tools/generate_fish_audio_register_barks.ps1`. The manifest keeps FishAudio
delivery and pause cues separate from the clean text displayed in game.
