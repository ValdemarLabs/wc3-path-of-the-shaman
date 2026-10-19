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
[portrait] [command buttons 1 through 12] [ability book]
```

The twelve action slots reuse Warcraft III's native command-button frames.
This is deliberate: native buttons already own the targeting cursor, autocast,
cooldown shading, mana validation, tooltips, hotkeys, disabled state, and order
dispatch. A row of imitation frames would need to reproduce all of that and
would be much more likely to break abilities or multiplayer synchronization.

Relocating the command buttons removes them from the normal four-by-three
ability grid. This first pass does not hide the shared native console parent,
because that would also hide the engine-owned buttons. Any remaining command
card decoration should be suppressed only after its exact child frames have
been verified in the current client.

The Abilities button opens the existing `AbilitiesLiteUI` for Nazgrek or
Zul'kis. The prototype does not yet assign an ability-list entry to a specific
slot; it establishes the HUD and native command-button layout that the loadout
system will use.

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
components while retaining native command buttons for engine-owned targeting,
cooldowns, tooltips, hotkeys, and order dispatch.

## Ability loadout plan

The current PotS W3A export confirms that player abilities reuse command-card
coordinates and that several groups are presented through Spell Book
abilities. The next stage should:

1. Store a synchronized slot loadout separately for Nazgrek and Zul'kis.
2. Add an assignment mode to a modern ability-book panel that lists only
   learned active abilities.
3. Give slotted abilities unique command-card positions and hide unslotted
   active abilities from the native command card without removing them from
   the unit.
4. Refresh the command card after a loadout change and preserve the selected
   ability ranks, cooldowns, buffs, and permanent-ability behavior.
5. Save and restore both hero loadouts through the normal PotS save system.

`BlzUnitHideAbility` and the per-unit `ABILITY_IF_BUTTON_POSITION_NORMAL_X/Y`
fields are available in the current Warcraft III 3.0 API snapshot, but their
refresh behavior must be proven in the current client before the loadout layer
is accepted. Spell Book itself is not sufficient for arbitrary one-click
slots: it auto-orders its contents and opens a submenu.

## Import and validation

Import `ModernPlayerHUD.j` after:

- `Events`
- `MasterUI`
- `AbilitiesLiteUI`

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- targeted, point-target, immediate, autocast, channelled, and Spell Book
  abilities from the rearranged native buttons;
- cooldown, mana, disabled-state, tooltip, and hotkey presentation;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
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
