# Modern PotS UI

`UI/_Modern` is the isolated design and implementation area for the newer
Path of the Shaman interface. Nothing in this folder affects the map until the
relevant libraries are imported through the normal World Editor/JassHelper
workflow.

## Player HUD direction

The first prototype is `ModernPlayerHUD.j`:

```text
             [ Health ] [Level] [ Mana ]
                     [ XP ]
       [custom action slots 1 through 12] [ability book]
```

### Custom-only direction

Version 0.3.0 keeps the crash-free custom-only boundary established in version
0.2.0. Two tests on Warcraft III 3.0.1 PTR build 24368 produced the same native
null-pointer crash when the first origin-frame layout moved engine-owned
widgets. The current path creates PotS-owned frames under
`ORIGIN_FRAME_GAME_UI`; it never moves, resizes, reparents, or clicks the native
command card or portrait.

`ModernAbilityActionBar.j` now fills the twelve custom slots with learned
ability icons, cooldown shading, mana/readiness state, and custom tooltips. It
hides `ConsoleBottomBar`, `ConsoleBottomBarOverlay`, the native hero bar,
minimap, and portrait with visibility calls only. It deliberately leaves
`ConsoleUIBackdrop` alive because existing PotS interfaces use it as a parent.
The Game UI root remains only an invisible frame parent.

The HUD remains disabled until `FullscreenUI` no longer owns the intro
presentation and Nazgrek or Zul'kis is available. A normal selection event is
used when present; otherwise the enable timer falls back to the first valid
player hero after the intro. This prevents premature activation while the
preload-mode choice is still open. The HUD then enables on a later timer tick.

The Abilities button opens the existing `AbilitiesLiteUI` for Nazgrek or
Zul'kis. Until row-to-slot assignment is added, the action bar derives a stable
default layout from the hero's learned active abilities. Once the player makes
an explicit assignment, that synchronized loadout becomes authoritative. The
old spellbooks remain compatible but are no longer the modern HUD presentation.

## Forgotten Hollow inspiration and reuse

The Warcraft III map Forgotten Hollow is a principal visual and technical
inspiration for modernizing the Path of the Shaman interface. Its compact
lower HUD, broad resource bars, action-slot presentation, and reduced native
console footprint are useful references for the PotS player HUD. PotS should
adapt those ideas to its two-hero RPG structure rather than reproduce the
Forgotten Hollow interface unchanged.

Parts of the Forgotten Hollow UI package may be reusable if the complete
source assets and permission to use them are available:

- Its TOC structure can inform or supply a PotS load list for selected custom
  frame definitions.
- FDF templates such as `MyBar`, `BoxedText`, and `CustomTextureFrame` can
  potentially be imported or adapted for resource bars, framed tooltips, and
  decorative HUD textures.
- Compatible DDS textures, fonts, models, and sounds can potentially provide
  the visual skin after their paths, dependencies, credits, and usage rights
  have been verified.

A TOC is only a manifest and is not sufficient by itself. The referenced FDF
files and every asset used by those frame definitions must also be imported.
The Forgotten Hollow reference additionally relies on a Lua utility framework;
PotS uses vJASS, so behavioral Lua code must be rewritten or replaced by
existing PotS systems. Reused frame names should be namespaced for PotS to
avoid collisions with other imported UI packages.

`ModernPlayerHUD.j` therefore begins with built-in Warcraft frame templates
and textures already proven by `TargetUnitUI`. No FDF, TOC, or new imported
art is required for the first prototype. A later visual pass may introduce a
small PotS-specific TOC/FDF package derived from compatible Forgotten Hollow
components. The finished action bar remains PotS-owned rather than embedding
native command-card buttons.

## Ability action architecture

The migration does not require rewriting the existing 38 player ability
implementations. Spellbooks can continue to expose learned abilities to the
old system while the modern HUD stores and invokes the real ability rawcodes.
Five focused libraries establish that boundary:

- `ModernAbilityCatalog.j` classifies every Elemental, Enhancement,
  Restoration, and Totemic ability as passive, immediate, unit, point, or
  submenu and assigns a targeting policy.
- `ModernAbilityLoadout.j` stores twelve synchronized slots independently for
  Nazgrek and Zul'kis. It accepts only learned active abilities and does not
  add, remove, hide, or change the level of an ability.
- `ModernAbilityTargeting.j` provides deterministic unit acquisition. It
  contains no local mouse handling and issues no orders.
- `ModernAbilityController.j` turns local slot clicks and world coordinates
  into validated synchronized orders. Immediate/self and melee-auto abilities
  cast without a second click; unit and ground abilities enter targeting mode.
- `ModernAbilityActionBar.j` renders the PotS-owned slots and hides the native
  bottom HUD after `FullscreenUI` releases the intro presentation.

The targeting policies are:

- Soft hostile: clicking near an enemy resolves the closest living hostile
  within 180 range.
- Soft friendly: clicking near an ally resolves the closest living ally;
  equal-distance candidates prefer the more wounded unit. Clicking within 96
  range of the caster selects self. Clicking empty ground does not silently
  self-cast.
- Melee auto: Stormstrike and Whirlwind cast immediately around the caster and
  require no second target click. The resolver also supports nearest-hostile
  acquisition for future melee abilities that use a unit-target base.
- Approximate point: area spells such as Lightning Strike retain the clicked
  point and can present their natural area indicator.
- Precise point: all totem placement retains the exact clicked coordinates and
  must never snap to a nearby unit.

The resolver uses UnitIndexer IDs to break equal-distance ties, so synchronized
clients choose the same unit. Local frame clicks and mouse coordinates must be
sent through a validated `BlzSendSyncData` flow before resolving a target or
changing a loadout. No synchronized game state may be changed directly inside
a local frame event.

Several existing abilities share the same engine order string. The dispatcher
isolates a selected learned ability by synchronously disabling other learned
abilities with that order only while the order is issued, then restoring them.
This requires current-client and two-client tests for the `firebolt`,
`thunderbolt`, and `innerfire` collision groups. The Ability Insight reference
also confirms that Channel-based abilities need unique base orders when they
must coexist; future Object Editor cleanup should prefer unique orders over the
temporary isolation path.

Summon Elemental now opens a four-button Air, Water, Fire, and Earth flyout.
The selected child rawcode is synchronized and validated, while its current
Channel `Ncl6` order is read from the hero's ability at runtime. Windfury Totem
uses the corrected `undeadbuild` Channel base order and is enabled on the
modern bar. The next implementation stage is ability-book row-to-slot
assignment, followed by save/load persistence and custom inventory/minimap
replacements.

## Import and validation

Import the modern ability foundation in this order:

1. `Abilities/AbilitiesPlayer.j`
2. `Abilities/Shaman/ShamanCommon.j`
3. `UI/_Modern/ModernAbilityCatalog.j`
4. `UI/_Modern/ModernAbilityLoadout.j`
5. `UI/_Modern/ModernAbilityTargeting.j`
6. `UI/_Modern/ModernAbilityController.j`

`ModernPlayerHUD.j` remains after:

- `Events`
- `MasterUI`
- `AbilitiesLiteUI`
- `FullscreenUI`

Finally import `UI/_Modern/ModernAbilityActionBar.j` after
`ModernPlayerHUD`, `ModernAbilityController`, and the dependencies above. No
new TOC, FDF, or texture import is required for this functional stage.

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- catalog classification for all 38 player ability entries;
- deterministic soft-friendly, soft-hostile, melee-auto, self, approximate
  point, and precise-point resolution in a two-client test harness;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
- the intro-to-gameplay transition without a native access violation;
- version 0.3.0, confirming that the custom resource HUD, learned ability
  icons, cooldowns, tooltips, and Abilities control render after the intro;
- native bottom bar, command card, hero bar, minimap, and portrait visibility
  while the modern action bar is active, plus restoration after disabling it;
- direct self and melee-auto casting; soft friendly/hostile targeting; exact
  totem placement; and approximate area-spell placement;
- all four Summon Elemental flyout choices, including mana, cooldown, channel,
  replacement of the active elemental, and two-client synchronization;
- Windfury Totem point placement through its corrected `undeadbuild` Channel
  order;
- every shared-order collision pair, verifying that the selected ability casts
  and that its siblings remain usable afterward;
- UI scaling at 1080p, 1440p, and 4K;
- enable/disable restoration;
- two-client frame and selection behavior.

The current Spell Book research was last tested by its source on Warcraft III
1.29.2. PotS targets the local Warcraft III 3.0.0 API snapshot, so runtime
validation on the current client remains mandatory.

If Forgotten Hollow components are adopted later, import the selected TOC,
FDF, and supporting assets before `ModernPlayerHUD.j`, then repeat the full UI
scaling, Reforged/Classic presentation, cinematic, and multiplayer validation
matrix. Do not import the entire Forgotten Hollow UI package without first
removing unused definitions and resolving global frame-name collisions.

The current stage hides the shared native bottom HUD without moving or
reparenting its children. Because this also removes native minimap and inventory
access, those functions are temporarily unavailable from the gameplay HUD and
must receive PotS-owned replacements. The fixed `1` through `=` labels are
presentation-only in this stage; clicking works, but keyboard activation waits
until it can be added without double-firing native hotkeys.

`ModernAbilityCompileTest.j` is a compile-only harness for the complete modern
HUD stack. Never import it into the production map.
