# Global NPC Object Profile Audit — 20.9.2026

## Scope and invariants

This review matches these World Editor exports:

- `WC3_Export/fromWC3/POTS_UnitData-2026-09-20-1351.w3u`
- `WC3_Export/fromWC3/POTS_AbilitySettings-2026-09-20-1351.w3a`

The W3U v3 file contains 123 modified stock objects and 717 custom objects
(840 total). The W3A v3 file contains 21 modified stock abilities and 1,209
custom abilities (1,230 total). Both files parsed to their declared object
counts and exact file ends (W3U 221,238/221,238 bytes; W3A
814,886/814,886 bytes). A missing custom field means “inherit from the base
object”; it is not evidence for a zero/empty value.

The automatic global-NPC rules are deliberately conservative:

1. An existing unit instance or foreign/specific unit-type default wins.
2. An explicit `AIRegister` role wins over automatic manager configuration.
3. A reviewed specialist mapping is realized only on the unit's first combat
   event and only if that exact instance still has the mapped ability.
4. An uncertain attack-capable NPC receives lazy `AIGeneric`.
5. A unit without an enabled attack receives no automatic AI profile.
6. Object data alone cannot prove guard/patrol intent, so this audit creates no
   automatic guard profiles.

Manager and specialist configuration is side-effect-free: setting or clearing a
selection does not scan the map, reset `AIRegister`, or take units from bosses,
quests, vendors, routines, companions, heroes, or manually registered systems.

## Approved lazy specialist mappings

The cooldown column is the lightweight AI's minimum cast-attempt interval. The
engine still enforces the ability's own cooldown, mana, range, and targets.

| Unit | Export evidence | Profile | Order | Attempt cooldown | Search range |
|---|---|---|---|---:|---:|
| `n00L` Naga Sorceress | unit lists `A6EN`; `A6EN` is based on `ACfb`, 700 range, 1.5 s cast point, enemy organic targets | caster | `firebolt` | 2 s | 700 |
| `n01O` Ogre Warlock level-12 variant | unit lists `ACdc`, `ACrd`, and direct enemy debuff `ACcr`; the simple profile uses only the unambiguous Cripple target order | caster | `cripple` | 10 s | 600 |
| `n027` Mana Spawn | unit lists `A03C`; Arcane Bolt is based on `ACfb`, with 700 range and a 2 s cast point | caster | `firebolt` | 2 s | 700 |
| `n60K` Gnoll Curser (Elite) | unit lists `Acrs`, `ACcr`, and `ACps`; `ACcr` is the creep Cripple variant and supplies a direct enemy-unit debuff | caster | `cripple` | 10 s | 600 |
| `n60V` Ogre Warlock | unit lists `ACdc`, `ACrd`, and direct enemy debuff `ACcr`; the simple profile uses only the unambiguous Cripple target order | caster | `cripple` | 10 s | 600 |
| `n61H` Fire Spawn | unit lists stock `ACfb` Firebolt | caster | `firebolt` | 2 s | 700 |
| `n640` Lava Basilisk | unit lists `A6AK`; it is based on `ACfb`, with 500 damage, 15 s cooldown, 1.5 s cast point, and 1,500 range | caster | `firebolt` | 15 s | 1,500 |
| `n65V` Ogre Magi level-5 variant | unit lists `A6EM`; Neutral Frost Bolt is based on `ACfb`, with 700 range and a 1.5 s cast point | caster | `firebolt` | 2 s | 700 |
| `n65W` Ogre Magi level-10 variant | unit lists `A6EN`; Neutral Frost Bolt is based on `ACfb`, with 700 range and a 1.5 s cast point | caster | `firebolt` | 2 s | 700 |
| `n00P` Naga Siren level-12 variant | unit lists `A02S`; Neutral Healing Wave is based on `AHhb`, has a 2 s cast point, heals 500 at the active level, and targets friendly organic units | healer | `holybolt` | 3 s | 700; heal below 65% |
| `n62A` Murloc Sorcerer | unit lists healing spells `AChv` and `ACrj`; the simple profile uses the direct friendly-unit Rejuvenation order and spaces attempts to avoid refreshing its heal-over-time too often | healer | `rejuvenation` | 10 s | 600; heal below 70% |
| `o01O` Restoration Shaman | unit lists `A00D` and `A00E`; `A00D` is the already reviewed `AHhb`-based direct heal, while the class/companion Restoration Shaman uses the separate hero rawcode `O61H` | healer | `holybolt` | 3 s | 700; heal below 65% |

`ACfb` and its derived abilities share the Firebolt order. `A02S` and `A00D`
keep the Holy Light base order despite their custom Healing Wave display names.
`ACcr` and `ACrj` are the creep variants of Cripple and Rejuvenation and retain
those direct target orders. The Firebolt/Holy Light choices were cross-checked
against existing PotS order usage; the Cripple/Rejuvenation choices use their
base order names and were checked against the repository's Ability Insight
targeting notes. Its latest observations for these abilities are from 1.28.5,
so runtime validation in the current 3.0 client remains required. Holy Light
also has hardcoded living-versus-undead/demon target semantics beyond its
Targets Allowed field; validate `n00P` and `o01O` with any unusual undead or
demon allies.

All twelve entries still pass the common runtime attack check. If an instance is
missing its mapped spell, has already been claimed, is summoned, is a hero or
structure, is user-controlled, or is explicitly excluded, automatic specialist
registration does nothing. A missing-spell instance of a reviewed specialist
type deliberately fails closed instead of creating a competing type-wide generic
profile; a later correctly equipped instance can still establish the reviewed
specialist profile.

## Deferred and rejected candidates

| Unit/candidate | Decision | Reason |
|---|---|---|
| `n028` Mana Devourer | defer to generic/explicit owner | Mixed kit: `A04Y` Death and Decay, `A03C` Arcane Bolt, and `A6FG` Rogue Shadowstep. It is reused by arena/quest content; one generic caster order would not safely represent ownership or targeting. |
| `n00I` Dark Shaman | defer to explicit script | Mixed summon/Firebolt kit (`A02O`, `A02L`) and Scorchion boss scripting owns its orders. `BossScorchion` now explicitly excludes each created or adopted shaman from global AI. |
| `u604` Skeleton Mage | defer to generic | Its Frost Bolt is the stock `ACcb` variant, but this quick pass did not add an order mapping without a current-version runtime check. |
| Stat-derived melee/ranged “guards” | reject | Attack range, owner, armor, acquisition range, and model do not prove a stationary guard, patrol, aggressive creep, or quest role. Unknown attackers therefore use `AIGeneric`. |
| Units with attack disabled at runtime | reject | Passive creatures, vendors, quest helpers, and decorative units should not receive automatic combat AI merely because they take damage. |

## Wildlife rawcode safety

The ambient wolf hunt uses instance rules, never a wolf unit-type profile.

Eligible wild wolf rawcodes are only stock `nwlt` (Timber Wolf), `nwlg` (Giant
Wolf), and `nwld` (Dire Wolf). Those same rawcodes are also reused by Shaman
spirit-wolf and tameable-pet systems, so rawcode alone is insufficient. A wolf
must be an alive, visible, idle neutral-hostile instance inside the selected
zone, with no AI instance, no combat state, no `AIRegister` exclusion, and no
membership in `udg_TamedUnits` or `udg_Companion_Group`. Actual summon events
are tracked per instance and rejected; the broad `UNIT_TYPE_SUMMONED`
classification is not used because it can also exist on preplaced custom units.

Eligible prey rawcodes reuse `PetDefinitions`:

- stags: `nder`, `n63A`, `n63B`;
- boars: `n63C`, `n63U`.

Prey must be an idle visible neutral-passive instance, hostile to the wolf
owner, near an eligible hero, and free of AI/script/tame/companion ownership.

Explicit exclusions include `n655` Shadowclaw, `n64B` Alpha Wolf, `n648` Wolf
Mother, quest wolves `o600`/`o601`/`o602`, wolf mount `n61B`, ghost/worgen/fel
variants, and every rawcode outside the three exact stock wolf IDs. `npig` is
not treated as a wolf because it is also a boar base/rawcode in current data.
The stale `n61T` Spirit Wolf constant is also excluded; current object data uses
that rawcode for an Imp. `n02L`, an unnamed custom level-9 Timber Wolf variant,
is deferred because no current `PetDefinitions` or repository-role evidence
establishes it as ordinary ambient wildlife.

## Required map validation

- Compile through the normal World Editor/JassHelper full-map path.
- Exercise all twelve specialist types and verify the first-combat profile,
  order, target, range, cooldown behavior, death/deindex cleanup, and idle
  combat-gated processing.
- For one reviewed rawcode, test one instance without the mapped spell and one
  with it. The stripped instance must remain unregistered and must not prevent
  the correctly equipped instance from establishing the specialist profile.
- Confirm explicit class/boss/vendor/quest/routine/manual profiles always win,
  including two units sharing a rawcode while only one is routine-controlled.
- Promote an inferred caster/healer with an explicit same-role registration and
  confirm the supplied configuration replaces the inferred values and restores
  eager periodic behavior.
- Damage an attack-disabled NPC and confirm it receives no AI instance.
- Confirm unit-index/sold hooks do not instantiate inferred profiles, `none`
  blocks future automatic instances without deleting a current one, and Lava
  Basilisk target acquisition honors its reviewed 1,500 range.
- Compare a non-summoned `n61H` Fire Spawn with an instance created by a summon:
  only the non-summoned instance is eligible for the reviewed global profile.
- Test wolf hunting in Twilight Grove, Sereneglade, Thornwoods, and Havenwoods,
  both inside and outside the 10,000 hero gate, including taming/summoning and
  UnitHider transitions. Confirm taming or transferring a temporary spawned
  wolf cancels its timed life and releases its per-instance AI exclusion.
