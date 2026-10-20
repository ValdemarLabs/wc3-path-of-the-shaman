# Modern PotS UI

`UI/_Modern` is the isolated design and implementation area for the newer
Path of the Shaman interface. Nothing in this folder affects the map until the
relevant libraries are imported through the normal World Editor/JassHelper
workflow.

## Player HUD direction

The first prototype is `ModernPlayerHUD.j`:

```text
             [ Health ] [Level] [ Mana ]
               [Earth Fire Water Air]
                     [ XP ]
       [custom action slots 1 through 12] [ability book]
```

### Custom-only direction

Version 0.6.0 keeps the crash-free custom-only boundary established in version
0.2.0. Two tests on Warcraft III 3.0.1 PTR build 24368 produced the same native
null-pointer crash when the first origin-frame layout moved engine-owned
widgets. The current path creates PotS-owned frames under
`ORIGIN_FRAME_GAME_UI`; it never moves, resizes, reparents, or clicks the native
command card or portrait.

`ModernAbilityActionBar.j` fills the twelve custom slots with learned
ability icons, cooldown shading, mana/readiness state, and custom tooltips. It
hides `ConsoleBottomBar`, `ConsoleBottomBarOverlay`, the native hero bar,
portrait, and `ConsoleUIBackdrop` with visibility calls only.
`StatsLiteUI.j` and `TargetUnitUI.j` now use `ORIGIN_FRAME_GAME_UI`
directly, so hiding the native console canvas no longer hides those PotS
overlays. The Game UI root remains only an invisible frame parent.

`ModernMinimapHUD.j` reparents only the native minimap into a compact
upper-left PotS shell and adds separate Nazgrek and Zul'kis selection buttons.
It does not move the native command card, portrait, or hero-bar controls that
caused the earlier unsafe-layout crash. The native hero buttons are hidden
individually so their status icons cannot remain over the modern bottom HUD.

The large black rectangle seen behind version 0.4.0 was the visible native
`ConsoleUIBackdrop`, not `PotSHUD.tga`. Its bounds are the same 0.10-to-0.70
screen span used by Warcraft's bottom console, which is why the rectangle was
much taller and wider than the custom art.

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

The current visual pass deliberately combines both references. Its narrow
centered action bar, portrait medallion, split health/mana treatment, and slot
rhythm follow the unpacked VideoRPG reference map in
`_developer/InventorySystemIdeas`. Its dark fantasy framing, restrained
gold accents, compact vertical footprint, and reduced native-console presence
follow the Forgotten Hollow direction. PotS keeps its own ability systems and
does not import either reference map's gameplay scripts.

Twelve original PotS texture files are staged in `UI/_Modern/Assets`. They were
created specifically for this HUD using a shared shamanic material language:
blackened iron, aged bronze, charcoal stone, leather bindings, and restrained
elemental turquoise. The medallion is an empty four-element ring so the
same asset can frame either a real hero portrait or the level text.
The revised medallion uses four large, distinct Earth, Fire, Water, and Air
glyphs around a clean center. Matching individual element badges support the
active-totem tracker without borrowing art from either reference map.

The current HUD creates its frames from vJASS, so these textures require no TOC
or FDF. Forgotten Hollow remains a mood/compactness reference. Forgotten Hollow TOC/FDF
components remain optional future sources only if their complete dependencies
and reuse rights are available. The action bar remains PotS-owned rather than
embedding native command-card buttons.

### Performance architecture

The HUD uses one 0.25-second presentation tick owned by
`ModernPlayerHUD.j`. `ModernAbilityActionBar.j` and
`ModernTotemTracker.j` register with that tick instead of creating additional
permanent timers. The tracker reads the existing `Totems` caster/element
registry, performs no unit enumeration, and reduces each lifetime bar to 20
geometry steps.

Version 0.6.0 removes the action bar's remaining expensive idle path. The old
fallback resolved each of twelve slots by rescanning as many as 42 ability
definitions every tick: up to 504 catalog/ability tests per tick, or 2,016 per
second before cooldown work. `ModernAbilityLoadout.j` now materializes that
derived default layout once per hero. Static slot data (rawcode, level, icon,
tooltip, mana cost, and readiness classification) is rebuilt only after hero
selection, an explicit refresh/loadout change, or a hero-skill event.

The shared tick now performs only cached visibility checks while idle. Mana
shading traverses the slots only when the hero's integer mana changes.
Cooldown natives are queried for every slot once during a static rebuild, then
only for slots marked active by a spell-effect event until their cooldown ends.
Cooldown height is limited to 20 geometry steps. All twelve slots share one
tooltip frame whose content is filled on hover.

Custom action bars are not inherently expensive. Repeated catalog scans,
cooldown-native polling, and frame geometry changes were the harmful work;
the modern HUD now bounds each of those operations. Runtime soak testing is
still required because Warcraft III frame performance cannot be established
by JassHelper compilation alone.

The action-bar and totem systems use tiny textureless logical parents. A
full-screen `FRAME` consumes mouse input even when it has no visible texture;
the earlier full-screen roots therefore blocked the action bar, StatsLiteUI,
Quest UI, MasterUI, and world clicks. Their children retain absolute screen
positions while the parent hit-test area is now effectively empty.

## Ability action architecture

The migration does not require rewriting the existing 38 player ability
implementations. Spellbooks can continue to expose learned abilities to the
old system while the modern HUD stores and invokes the real ability rawcodes.
Six focused libraries establish that boundary:

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
- `ModernMinimapHUD.j` preserves the engine minimap's interaction while
  presenting it independently of the hidden console and native hero bar.

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
7. `Abilities/Shaman/Totems.j`

`ModernPlayerHUD.j` remains after:

- `Events`
- `MasterUI`
- `AbilitiesLiteUI`
- `FullscreenUI`

Finally import `UI/_Modern/ModernAbilityActionBar.j` after
`ModernPlayerHUD`, `ModernAbilityController`, and the dependencies above.
Then import `UI/_Modern/ModernTotemTracker.j` after `Totems`,
`ShamanCommon`, `FullscreenUI`, and `ModernPlayerHUD`.
Import `UI/_Modern/ModernMinimapHUD.j` after `FullscreenUI` and
`ModernPlayerHUD`; it can otherwise sit beside the other Modern HUD modules.

Import these files with the exact custom paths shown:

- `UI\_Modern\Assets\PotSHUD.tga`
- `UI\_Modern\Assets\PotSActionSlot.tga`
- `UI\_Modern\Assets\PotSBarBack.tga`
- `UI\_Modern\Assets\PotSBarFrame.tga`
- `UI\_Modern\Assets\PotSMedallion.tga`
- `UI\_Modern\Assets\PotSHealth.tga`
- `UI\_Modern\Assets\PotSMana.tga`
- `UI\_Modern\Assets\PotSXP.tga`
- `UI\_Modern\Assets\PotSTotemEarth.tga`
- `UI\_Modern\Assets\PotSTotemFire.tga`
- `UI\_Modern\Assets\PotSTotemWater.tga`
- `UI\_Modern\Assets\PotSTotemAir.tga`

No TOC or FDF import is required for this stage.

The four black squares reported in the first tracker test were the inactive
Earth, Fire, Water, and Air badge frames. Ensure all four `PotSTotem*.tga`
files use the exact custom paths above. Version 1.2.0 also reduces the inactive
shade and displays E/F/W/A fallback labels, so a missing or incorrect texture
path is immediately identifiable instead of appearing as an unexplained row
of black rectangles.

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- catalog classification for all 38 player ability entries;
- deterministic soft-friendly, soft-hostile, melee-auto, self, approximate
  point, and precise-point resolution in a two-client test harness;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
- the intro-to-gameplay transition without a native access violation;
- version 0.6.0 of the resource shell and version 0.7.0 of the action bar,
  confirming that learned icons, cooldowns, tooltips, and Abilities render;
- mouse clicks on action slots, Abilities, StatsLiteUI, Quest UI, MasterUI,
  world terrain, and units after the full-screen logical parents were removed;
- `1` through `0`, minus, and equals activation for slots 1 through 12,
  including targeted abilities and the Summon Elemental flyout;
- the upper-left native minimap inside its custom shell, minimap interaction,
  Nazgrek/Zul'kis selector buttons, and intro/fullscreen transitions;
- native bottom bar, command card, hero bar, and portrait hiding while the
  custom minimap remains visible, plus restoration after disabling the bar;
- direct self and melee-auto casting; soft friendly/hostile targeting; exact
  totem placement; and approximate area-spell placement;
- all four Summon Elemental flyout choices, including mana, cooldown, channel,
  replacement of the active elemental, and two-client synchronization;
- Windfury Totem point placement through its corrected `undeadbuild` Channel
  order;
- Earth, Fire, Water, and Air tracker badges in their inactive state, then
  enlarged active state with a decreasing whole-second label and lifetime bar
  for base and specialized totems in each element slot;
- every shared-order collision pair, verifying that the selected ability casts
  and that its siblings remain usable afterward;
- UI scaling at 1080p, 1440p, and 4K;
- a ten-minute idle/combat soak while recording average FPS, minimum FPS, and
  frame-time behavior; compare the modern HUD enabled and disabled, and verify
  that idle time does not accumulate additional cost;
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

The current stage hides the shared native bottom HUD without moving its command
card or portrait. The minimap and hero selectors now have PotS-owned shells,
and the fixed `1` through `=` labels have matching keyboard input. Native
inventory access remains unavailable and still needs a PotS-owned replacement.

`ModernAbilityCompileTest.j` is a compile-only harness for the complete modern
HUD stack. Never import it into the production map.
