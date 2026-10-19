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

Version 0.2.0 permanently removes the prototype paths that moved Warcraft III
command buttons or the native portrait. Two tests on Warcraft III 3.0.1 PTR
build 24368 produced the same native null-pointer crash when the first
origin-frame layout was applied. The crash-free path creates only PotS-owned
frames under `ORIGIN_FRAME_GAME_UI`; it does not move, resize, reparent, or
use native command buttons or portrait widgets.

The twelve visible boxes are custom action-slot placeholders. They are not
copies of the command card and do not issue orders yet. The final modern HUD
will render its own icons, cooldowns, costs, hotkeys, disabled states, and
tooltips from the synchronized loadout. The native console can be hidden only
after those controls and all required inventory/menu replacements are usable.
The Game UI root may remain as an invisible frame parent; that does not make a
native HUD widget part of the modern interface.

The HUD remains disabled until `FullscreenUI` no longer owns the intro
presentation and Nazgrek or Zul'kis is available. A normal selection event is
used when present; otherwise the enable timer falls back to the first valid
player hero after the intro. This prevents premature activation while the
preload-mode choice is still open. The HUD then enables on a later timer tick.

The Abilities button opens the existing `AbilitiesLiteUI` for Nazgrek or
Zul'kis. The prototype does not yet connect an ability-list row to a slot; the
loadout and targeting foundation below owns that state independently of the old
spellbook presentation.

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
Three new libraries establish that boundary:

- `ModernAbilityCatalog.j` classifies every Elemental, Enhancement,
  Restoration, and Totemic ability as passive, immediate, unit, point, or
  submenu and assigns a targeting policy.
- `ModernAbilityLoadout.j` stores twelve synchronized slots independently for
  Nazgrek and Zul'kis. It accepts only learned active abilities and does not
  add, remove, hide, or change the level of an ability.
- `ModernAbilityTargeting.j` provides deterministic unit acquisition. It
  contains no local mouse handling and issues no orders.

The targeting policies are:

- Soft hostile: clicking near an enemy resolves the closest living hostile
  within 180 range.
- Soft friendly: clicking near an ally resolves the closest living ally;
  equal-distance candidates prefer the more wounded unit. Clicking within 96
  range of the caster selects self. Clicking empty ground does not silently
  self-cast.
- Melee auto: Stormstrike and Whirlwind acquire around the caster within 250
  range and require no second target click.
- Approximate point: area spells such as Lightning Strike retain the clicked
  point and can present their natural area indicator.
- Precise point: all totem placement retains the exact clicked coordinates and
  must never snap to a nearby unit.

The resolver uses UnitIndexer IDs to break equal-distance ties, so synchronized
clients choose the same unit. Local frame clicks and mouse coordinates must be
sent through a validated `BlzSendSyncData` flow before resolving a target or
changing a loadout. No synchronized game state may be changed directly inside
a local frame event.

The next implementation stage is the custom order dispatcher and action-slot
renderer, followed by ability-book slot assignment and save/load persistence.
Summon Elemental needs a custom flyout, and the Windfury Totem base-order
configuration must be verified in the current Object Editor export before
either special case is enabled.

## Import and validation

Import the modern ability foundation in this order:

1. `Abilities/AbilitiesPlayer.j`
2. `Abilities/Shaman/ShamanCommon.j`
3. `UI/_Modern/ModernAbilityCatalog.j`
4. `UI/_Modern/ModernAbilityLoadout.j`
5. `UI/_Modern/ModernAbilityTargeting.j`

`ModernPlayerHUD.j` remains after:

- `Events`
- `MasterUI`
- `AbilitiesLiteUI`
- `FullscreenUI`

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- catalog classification for all 38 player ability entries;
- deterministic soft-friendly, soft-hostile, melee-auto, self, approximate
  point, and precise-point resolution in a two-client test harness;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
- the intro-to-gameplay transition without a native access violation;
- version 0.2.0, confirming that the custom resource HUD and twelve custom
  empty slots are visible above the unchanged native bottom console;
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

The prototype intentionally leaves the shared native console visible until the
custom action bar, inventory access, and required menu controls are functional.
This is transitional only: the final interface must hide the native console
without moving or reparenting its children. A Warcraft III 2.0+ hierarchy
change places the command bar under `ConsoleBottomBar`; hiding that parent
also hides its native buttons, which is acceptable only after the PotS-owned
dispatcher is complete.
