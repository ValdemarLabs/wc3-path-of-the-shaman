# Modern PotS UI

`UI/_Modern` is the isolated design and implementation area for the newer
Path of the Shaman interface. Nothing in this folder affects the map until the
relevant libraries are imported through the normal World Editor/JassHelper
workflow.

## Player HUD direction

The first prototype is `ModernPlayerHUD.j`:

```text
       [upper-right minimap] [unit/minimap controls]
                            [icon shortcut rail]

             [ Health ] [Level] [ Mana ]
               [Earth Fire Water Air]
                     [ XP ]
       [custom action slots 13 through 24]
       [custom action slots  1 through 12]
```

### Isolated native-frame adapters

The command card remains behind the crash-free custom-only boundary established
in version 0.2.0. Two tests on Warcraft III 3.0.1 PTR build 24368 produced the
same native null-pointer crash when the earlier implementation moved several
engine-owned widgets together. Native elements are therefore integrated only
through separate, rollback-safe adapters rather than a shared origin-frame
layout pass.

`ModernAbilityActionBar.j` fills twenty-four custom slots in two rows with
learned ability icons, native-style radial cooldown sweeps, numerical cooldown
text, mana/readiness state, and custom tooltips. It hides
`ConsoleBottomBar`, `ConsoleBottomBarOverlay`, the native hero bar, and
`ConsoleUIBackdrop` with visibility calls only. The native animated portrait
adapter is disabled by default because repeated native reparenting produced
unstable animation and panel-transition behavior. The action bar currently
uses the selected hero's icon inside a dedicated portrait frame. The old
adapter remains behind `MAB_USE_NATIVE_PORTRAIT` for isolated testing, but it
is not part of the default HUD.

`ModernMinimapHUD.j` does not create a second minimap layout.
`DynamicMinimap.j` remains the sole owner of compact/enlarged map placement.
The adapter exposes the five native minimap controls and four custom
player/pet/companion selection buttons directly below the upper-right map.
The native hero buttons are hidden individually so their status icons cannot
remain over the modern bottom HUD.

`ModernShortcutRail.j` places icon-only Inventory, Abilities, Talents, Stats,
Stats overlay, and Threat overlay shortcuts below that minimap cluster. A
contextual Inspect icon appears only for a selected eligible friendly unit.
Every icon has a hover description; Stats and Threat overlay icons show an
active-state marker. These shortcuts call the same existing UI libraries as
the Game menu and do not create replacement inventory, talent, or stats
systems.

### True widescreen frame ownership

Calculating positions from `BlzGetLocalClientWidth` and
`BlzGetLocalClientHeight` is not enough. A non-simple frame parented to the
ordinary Game UI can render beyond the classic 0.000-to-0.800 range while its
mouse events still fail there. `UI/WidescreenFrameRoot.j` creates one hidden,
zero-sized Leaderboard frame and uses its `Leaderboard` frame as the shared
parent for interactive full-client UI.

The modern HUD controls, minimap, minimap buttons, shortcut rail,
`StatsLiteUI`, and `TargetUnitUI` now use this owner. Broad decorative HUD
parents are disabled
and clickable controls live under zero-sized sibling parents so neither the
world nor other custom frames are covered by an invisible hit area. At 4:3,
the calculated width clamps to 0.800; at wider aspect ratios, left/right
positions can use the full client width and still receive frame events.

The large black rectangle seen behind version 0.4.0 was the visible native
`ConsoleUIBackdrop`, not `PotSHUD.tga`. Its bounds are the same 0.10-to-0.70
screen span used by Warcraft's bottom console, which is why the rectangle was
much taller and wider than the custom art.

The HUD remains disabled until `FullscreenUI` no longer owns the intro
presentation and Nazgrek or Zul'kis is available. A normal selection event is
used when present; otherwise the enable timer falls back to the first valid
player hero after the intro. This prevents premature activation while the
preload-mode choice is still open. The HUD then enables on a later timer tick
and explicitly restores its shared Leaderboard-backed widescreen parent,
because Warcraft hides that parent when `ShowInterface(false)` starts the
intro presentation. The action bar performs the same restoration only after
native bottom-console suppression is complete; otherwise that later native
hide pass can immediately hide the freshly restored custom HUD again.

The Abilities shortcut opens the existing `AbilitiesLiteUI` for Nazgrek or
Zul'kis. Right-click a learned active ability in that list, then click an
action-bar slot (or press that slot's bound key) to assign it. The action bar
also derives a stable default layout and appends newly learned active abilities
to the first empty slot. Once full, it never displaces an existing assignment.
Newly learned active abilities are now attached directly to the hero instead
of through their old spellbook wrapper. Existing saves migrate an ability the
first time its modern action slot is used, preserving its learned rank. The
spellbook definitions remain only as compatibility data for old saves.

The first row keeps the default `1` through `=` bindings. The second row
starts unbound so it does not steal movement or command keys. Right-click an
action slot and click another slot to swap them. Shift-right-
click a slot and press one of `1-0`, `-`, `=`, `QWER`, `DF`, or
`ZXCV` to rebind it; if that key already belongs to another slot, the two
bindings swap. Loadout changes are synchronized. Keybindings are local
presentation preferences and currently last for the running session only.
`A` and `S` are deliberately excluded so Warcraft's Attack and Stop commands
continue to work.

The bottom HUD includes six PotS-owned quick-item slots backed by the hero's
normal inventory. Clicking a populated slot uses that item through synchronized
gameplay code without moving the crash-prone native item frames. When the
shortcut rail is imported after `DInventory` and `DEquipment`, its Inventory
icon opens the full bag and equipment views, while the contextual Inspect icon
opens the existing read-only inventory/equipment view for the
selected non-player-owned friendly or neutral eligible unit; hostile and
player-owned selections hide the Inspect control. Stealth and the
currently equipped Shield Block rank have dedicated contextual slots above the
bar, so neither ability consumes one of the twenty-four general slots.

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
elemental turquoise. The revised medallion uses four large, distinct Earth,
Fire, Water, and Air glyphs around a clean center and is used once for the
central level treatment. The icon portrait uses a neutral slot frame instead
of duplicating the medallion. Matching individual element
badges support the active-totem tracker without borrowing art from either
reference map.

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

The shared tick now performs only cached visibility checks while idle. A
two-second learned-ability check appends new abilities only while gameplay is
running; it does not rebuild slot presentation unless the loadout revision
changes. Mana
shading traverses the slots only when the hero's integer mana changes.
Cooldown natives are queried for every slot during a static rebuild and once
per second for discovery, then every presentation tick only for slots with an
active cooldown. The discovery pass catches engine or script cooldown changes
whose spell event was not observed by the HUD, including Stormstrike, without
returning to every-frame full-bar polling. Cooling slots drive Warcraft's
radial cooldown sprite in 100 steps and add a whole-second countdown; no
cooldown rectangle is resized every tick. All twenty-four slots share one
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
- `ModernAbilityLoadout.j` stores twenty-four synchronized slots independently for
  Nazgrek and Zul'kis. It accepts only learned active abilities and does not
  add, remove, hide, or change the level of an ability.
- `ModernAbilityTargeting.j` provides deterministic unit acquisition. It
  contains no local mouse handling and issues no orders.
- `ModernAbilityController.j` turns local slot clicks and world coordinates
  into validated synchronized orders. Immediate/self and melee-auto abilities
  cast without a second click; unit and ground abilities enter targeting mode.
  For Channel-backed point abilities, it applies the catalog's point-compatible
  `Ncl6` order to the runtime ability before issuing the synchronized point
  order. Ordinary abilities keep their actual base order instead of
  accidentally interpreting the Channel-only field.
- `ModernAbilityActionBar.j` renders the PotS-owned slots and hides the native
  bottom HUD after `FullscreenUI` releases the intro presentation.
- `ModernMinimapHUD.j` preserves the engine minimap and its five native
  control buttons while presenting them independently of the hidden console
  and native hero bar. If `DynamicMinimap` is present, its enlarged layout
  owns the map until it closes; the compact PotS placement is then restored.
- `ModernShortcutRail.j` supplies the upper-right icon shortcuts and hover
  descriptions while delegating each action to its existing UI library.

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

Summon Elemental opens a four-button Air, Water, Fire, and Earth flyout.
The selected child rawcode is synchronized and validated. The nine
Channel-backed totem abilities use distinct point-compatible catalog orders;
this avoids issuing the non-point `undeadbuild` order from a terrain click.
Their Object Editor base orders should be updated to the documented catalog
values as a matching World Editor follow-up.

| Ability | Channel base order |
| --- | --- |
| `A63F` | `ward` |
| `A63G` | `flamestrike` |
| `A63H` | `rainoffire` |
| `A63I` | `blizzard` |
| `A68J` | `deathanddecay` |
| `A68L` | `silence` |
| `A68F` | `clusterrockets` |
| `A68T` | `shockwave` |
| `A01U` | `carrionswarm` |

To configure the bar, right-click a learned active row in the Abilities book.
The book closes while retaining the pending ability; click any action slot to
assign it. Right-click a populated slot and click another slot to swap them.
Shift-right-click a slot and then press one of the registered action keys to
rebind it for the current session. Learned active abilities continue to fill
the first empty slot automatically. Save/load persistence is still a later
stage.

World targeting is armed on the next local input tick so the frame click that
opened targeting cannot be mistaken for a terrain click. Selecting an enemy,
ally, or inspect target no longer replaces the player hero displayed by the
resource HUD or action bar. Unit clicks synchronize the exact mouse-focus unit
index and only fall back to the nearby-point resolver when no valid focused
unit exists. After the target is captured, command selection returns to the
player hero while `TargetUnitUI` retains the explicit target.

## Import and validation

Import the modern ability foundation in this order:

1. `UI/WidescreenFrameRoot.j`
2. `Abilities/AbilitiesPlayer.j`
3. `Abilities/Shaman/ShamanCommon.j`
4. `UI/_Modern/ModernAbilityCatalog.j`
5. `UI/_Modern/ModernAbilityLoadout.j`
6. `UI/_Modern/ModernAbilityTargeting.j`
7. `UI/_Modern/ModernAbilityController.j`
8. `Abilities/Shaman/Totems.j`

`ModernPlayerHUD.j` remains after:

- `Events`
- `MasterUI`
- `AbilitiesLiteUI`
- `FullscreenUI`
- `WidescreenFrameRoot`

Finally import `UI/_Modern/ModernAbilityActionBar.j` after
`ModernPlayerHUD`, `ModernAbilityController`, and the dependencies above.
Then import `UI/_Modern/ModernTotemTracker.j` after `Totems`,
`ShamanCommon`, `FullscreenUI`, and `ModernPlayerHUD`.
Import `UI/_Modern/ModernMinimapHUD.j` after `FullscreenUI`,
`ModernPlayerHUD`, `WidescreenFrameRoot`, and the production
`DynamicMinimap` and `Companions` libraries when used.
Import `UI/_Modern/ModernShortcutRail.j` after `FullscreenUI`,
`ModernPlayerHUD`, `WidescreenFrameRoot`, `MasterUI`, and
`AbilitiesLiteUI`. Import it after `DInventory`, `DEquipment`,
`TalentsUI`, `StatsUI`, `StatsLiteUI`, and `TargetUnitUI` to enable
all shortcuts; those integrations remain optional at compile time.

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

No TOC or FDF import is required for this stage. `PotSHUD.tga` is a
2048x512 transparent chassis sized for both twelve-slot rows; the action-slot
frames remain separate, so adding or reordering slots does not stretch icons
or bake them into the background texture.

The four black squares reported in the first tracker test were inactive Earth,
Fire, Water, and Air badge frames. Version 1.3.0 hides inactive element slots
entirely. An element badge appears only while that element's totem is live,
with its whole-second countdown and lifetime bar.

Then compile through the current World Editor/JassHelper workflow. Test:

- Nazgrek and Zul'kis selection and switching;
- catalog classification for all 38 player ability entries;
- deterministic soft-friendly, soft-hostile, melee-auto, self, approximate
  point, and precise-point resolution in a two-client test harness;
- non-hero and enemy selection;
- inventory, quest, MasterUI, cinematic, and fullscreen UI transitions;
- the intro-to-gameplay transition without a native access violation;
- version 1.1.0 of the resource shell and version 1.3.0 of the action bar,
  confirming that learned icons, cooldowns, tooltips, and Abilities render;
- mouse clicks on action slots, Abilities, StatsLiteUI, Quest UI, MasterUI,
  world terrain, and units after the full-screen logical parents were removed;
- default `1` through `0`, minus, and equals activation, Shift-right-click
  rebinding, duplicate-key swapping, and session-local binding behavior;
- right-click ability-book assignment to an empty and occupied slot,
  right-click slot swapping, automatic first-empty-slot insertion after
  learning, and no displacement when all twenty-four slots are full;
- the single upper-right native minimap, compact/enlarged return placement,
  all five native minimap controls, four player/pet/companion selectors, and
  intro/fullscreen transitions;
- all upper-right shortcut icons, hover descriptions, Inventory/Abilities/
  Talents/Stats routing, Stats and Threat overlay toggles, contextual Inspect,
  and active-state markers;
- native bottom bar, command card, hero bar, and portrait hiding while the
  custom minimap remains visible, plus restoration after disabling the bar;
- direct self and melee-auto casting; soft friendly/hostile targeting; exact
  totem placement; and approximate area-spell placement;
- one-click entry into targeting, confirming that the opening frame click is
  ignored and the following terrain/unit click is the synchronized target;
- health and mana current/maximum plus percentage text, complete 100% fills,
  ten-segment XP progress, the six synchronized quick-item slots, and
  upper-right Inventory and contextual Inspect controls;
- all four Summon Elemental flyout choices, including mana, cooldown, channel,
  replacement of the active elemental, and two-client synchronization;
- all nine totem abilities through their distinct point-compatible Channel
  orders, including exact Earth and Windfury placement;
- Stormstrike and Whirlwind immediate casting, with Stormstrike's native
  cooldown shown as both radial sweep and countdown text;
- Escape cancelling an armed cast/assignment/rebind without enlarging the
  minimap;
- 16:9 and 21:9 clicks beyond x=0.800 for Inventory, Inspect, StatsLiteUI,
  TargetUnitUI, minimap controls, and companion selectors, plus 4:3 fallback;
- Inventory and Inspect against the selected hero and an inspectable selected
  unit; Stealth visibility and all three equipment-granted Shield Block ranks;
- Earth, Fire, Water, and Air tracker badges remaining hidden while inactive,
  then appearing with a decreasing whole-second label and lifetime bar
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
card. DynamicMinimap owns the single native minimap layout; the modern adapter
exposes its controls and custom unit selectors in the upper-right cluster.
The shortcut rail delegates to DInventory, DEquipment, AbilitiesLiteUI,
TalentsUI, StatsUI, StatsLiteUI, and TargetUnitUI while contextual
Stealth/Block, assignment, swapping, and session keybinding remain on the
bottom action HUD. The six engine-owned item buttons remain intentionally
unmoved because PotS supplies six custom quick-item buttons instead.

`ModernAbilityCompileTest.j` is a compile-only harness for the complete modern
HUD stack. Never import it into the production map.
