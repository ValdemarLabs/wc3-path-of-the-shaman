# FishAudio voice reference IDs

These reference IDs are not API secrets. Keep the FishAudio API key only in
the local `FISH_API_KEY` environment variable. `tools/voicelines.ps1` derives a
speaker-specific environment variable by uppercasing the key prefix, for
example `VendorQuestHuman_0001` uses
`FISH_REFERENCE_ID_VENDORQUESTHUMAN`.

| PotS key prefix / speaker filter | FishAudio voice | Reference ID | Used for |
|---|---|---|---|
| `VendorHumanMale` | Vendor human male | `ffa580e4304440e2b78bf2a02d493942` | Human male vendors |
| `VendorQuestHuman` | Vendor human male | `ffa580e4304440e2b78bf2a02d493942` | Human vendor quests |
| `VendorHumanFemale` | Vendor human female | `550c2688c6794111858bc5d625a73a95` | Human female vendors |
| `VendorTaurenMale`, `VendorQuestTauren` | Vendor Tauren male | `8be8a11dd4524e6a813ac34ce1580008` | Tauren vendors and vendor quests |
| `VendorDwarfMorgrimMale` | Vendor dwarf Morgrim male | `c090db335e8f4fef8427ac98572978c9` | Morgrim dwarf vendors |
| `VendorElarindorMale`, `VendorQuestElarindorMale` | Vendor Elarindor male | `34a5f0dfbce3461180f1f8c788d3b7c0` | Elarindor male vendors and vendor quests |
| `VendorElarindorFemale`, `VendorQuestElarindorFemale` | Vendor Elarindor female | `eefc6b82be3d4907bf419c640d021b0b` | Elarindor female vendors and vendor quests |
| `VendorGoblinMale`, `VendorQuestGoblin` | Vendor goblin male | `b3e77482cd444ad09b04a33fe6817c32` | Goblin vendors and vendor quests |
| `VendorOgreBonecrusherMale`, `VendorQuestBonecrusher` | Vendor ogre Bonecrusher male | `065c2be6b4814fe59916ece73d6660b3` | Bonecrusher vendors and vendor quests |
| `Nazgrek`, `VendorQuestNazgrek` | Nazgrek2 | `82895e2c2e62463bb023c0c858a55b9d` | Nazgrek dialogue and vendor-quest replies |
| `Zulkis`, `VendorQuestZulkis` | Shadowhunter | `139c8b251a2f4a97a2dbce510e1f94cf` | Zul'kis dialogue and vendor-quest replies |

Vendor-quest hero reply files retain their `VendorQuestNazgrek_XXXX` and
`VendorQuestZulkis_XXXX` keys, but use the shared character generic folders:

- `Pots\Sound\Voicelines\Nazgrek\NazgrekGeneric\`
- `Pots\Sound\Voicelines\Zulkis\ZulkisGeneric\`

No suitable FishAudio reference ID is currently configured for these families:

- `VendorOrcMale`, `VendorQuestOrc`
- `VendorTrollMale`
- `VendorSatyrMale`, `VendorQuestSatyr`

Example generation command:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\voicelines.ps1 `
    -Mode Generate `
    -Speaker VendorQuestHuman `
    -ReferenceId ffa580e4304440e2b78bf2a02d493942
```
