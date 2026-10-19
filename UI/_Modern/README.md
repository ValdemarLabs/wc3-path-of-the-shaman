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

### PTR crash-isolation state

Version 0.1.3 keeps native command-button relocation and native portrait
relocation disabled by default. Two tests on Warcraft III 3.0.1 PTR build
24368 produced the identical native null-pointer crash as soon as the first
origin-frame layout was applied, including after intro/selection timing was
deferred. The custom health, mana, level, XP, and ability-book frames remain
enabled so they can establish a crash-free baseline without touching
engine-owned origin frames.

The first custom-only test no longer crashed, confirming that one of the
native-origin mutation paths is responsible. That test rendered the custom HUD
behind the restored native bottom console because its parent was
`ConsoleUIBackdrop`. Version 0.1.3 parents only the custom HUD to
`ORIGIN_FRAME_GAME_UI` and gives its root an explicit level. It also falls
back to Nazgrek or Zul'kis after the intro if no new selection event is raised.
These changes do not move, resize, hide, or reparent native frames.

The source contains separate `MHUD_RELOCATE_COMMAND_BUTTONS` and
`MHUD_RELOCATE_PORTRAIT` configuration flags. Keep both false for the next
test. If that test is stable, enable command buttons only in a dedicated test
build; test portrait relocation separately only after command-bar behavior is
known.

The intended twelve action slots reuse Warcraft III's native command-button frames.
This is deliberate: native buttons already own the targeting cursor, autocast,
cooldown shading, mana validation, tooltips, hotkeys, disabled state, and order
dispatch. A row of imitation frames would need to reproduce all of that and
would be much more likely to break abilities or multiplayer synchronization.

Relocating the command buttons removes them from the normal four-by-three
ability grid. This first pass does not hide the shared native console parent,
because that would also hide the engine-owned buttons. Any remaining command
card decoration should be suppressed only after its exact child frames have
been verified in the current client.

The HUD remains disabled until `FullscreenUI` no longer owns the intro
presentation and Nazgrek or Zul'kis is available. A normal selection event is
used when present; otherwise the enable timer falls back to the first valid
player hero after the intro. This prevents premature activation while the
preload-mode choice is still open. The HUD then enables on a later timer tick.
Selection events likewise defer native
command-button positioning until Warcraft has finished rebuilding the command
card; origin frames must not be cleared and resized inside the selection event
itself.

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
- `FullscreenUI`

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- targeted, point-target, immediate, autocast, channelled, and Spell Book
  abilities from the rearranged native buttons;
- cooldown, mana, disabled-state, tooltip, and hotkey presentation;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
- the intro-to-gameplay transition without a native access violation;
- version 0.1.3 with both native-relocation flags false, confirming that the
  custom resource HUD is visible above the native bottom console;
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

The prototype intentionally leaves the shared native console parent visible.
Consequently, the normal command card and native HUD artwork remain visible
beside the crash-isolation HUD. A Warcraft III 2.0+ frame-hierarchy change
places the command bar under `ConsoleBottomBar`; hiding that parent also hides
its native command buttons. Reparenting and decorative-frame suppression must
be tested separately after the crash source is isolated.
