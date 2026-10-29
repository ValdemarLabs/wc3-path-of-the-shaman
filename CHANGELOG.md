> Upcoming preview: this documentation does not announce an available release.

# Path of the Shaman - Player Changelog

> **Unreleased development history:** These are dated development notes, not release dates or a list of features guaranteed to be in the current download. Later entries may replace earlier behavior. Check the officially distributed version for what is available to play.

This history covers player-visible development from 21 June 2025 through 27 October 2026. It retains gameplay changes, fixes, presentation work, and relevant unfinished work from the original notes. Tooling-only entries, repeated archive snapshots, private implementation details, and story outcomes are omitted. Older notes are condensed and rewritten for players.

[Project overview](README.md) | [Installation](INSTALLATION.md) | [FAQ](FAQ.md) | [Save and load](SAVELOAD.md) | [Credits](CREDITS.md)

## [27.10.2026]

- Replaced the companion controller hero with controls beside each companion's party bars and a whole-party command menu. Modes and focus are immediate; Attack and Move use Modern HUD targeting. Kick and Drop items remain individual commands, and eligible units offer Invite on their target frame before reputation/quest/level checks.

## [26.10.2026]

- Completed the compact party-interface redesign with floating Horde-styled portrait rows ordered as the other owned hero, pet, then companions. Rows now use role accents, clean stacked resource bars, concise status text, alert effects, and a selected-unit highlight without a large gameplay backdrop.
- Added a compact target frame above the Modern HUD mana side while keeping the controlled hero on the main HUD. It shows the selected target's portrait icon, name, level, health, mana, registered effects, and detailed combat/faction statistics on hover.
- Updated the target frame so Escape clears it, left-click commits an armed ability or Attack to that exact target, and right-click sends the controlled hero toward it without replacing the hero portrait.
- Smoothed action-button cooldown sweeps and countdowns, aligned the two action rows and resource bars, and fitted the animated hero portrait into the left wolf socket.
- Fixed right-click ability assignment and slot swapping, retained Shift-right-click key rebinding, made `A` resolve a clicked/nearby enemy before falling back to true attack-move, and made unconsumed Escape return selection to the controlled hero.
- Added a persistent HUD keybind mode to the right shortcut rail. While enabled, hovering an action slot and pressing an alphanumeric, minus, or equals key immediately rebinds it; Escape exits the mode, and `A`, `S`, and `I` remain reserved.
- Replaced disappearing inventory controls with six stable quick-item slots showing the hero's items and charges, with normal and targeted item use.
- Converted the center medallion into a grey inactive four-element totem tracker. Active elemental badges and lifetime timers now appear in their matching quadrants, and Earth uses a distinct moss-green badge.
- Restored animated speaker portraits during fullscreen dialogue; they remain visible only while the character is speaking.
- Fixed returning from the Abilities trainer interface leaving player control disabled.

## [25.10.2026]

- Fixed unused companion rows in the Stats window appearing as green placeholder icons.
- Added a slight hold delay before right-mouse camera orbit activates, preserving quick right-click movement and attack commands while held input still controls the camera.
- Made the Modern HUD Inventory, Abilities, Talents, Stats, overlay, and Inspect shortcuts close the interface they already have open.
- Restored item use through the six quick-item slots, reserved `A` for unit/ground Attack targeting, and reserved `S` for immediate Stop.
- Reintegrated the animated unit portrait into the left wolf endcap during gameplay while presenting it without the PotS chassis during cinematics and fullscreen presentation.
- Fixed totems failing to cast at the selected terrain point; Escape and right-click still cancel targeting.
- Added a violet normal XP bar and orange rested-XP bar, and revised the wolf HUD chassis with an opaque functional backing and recessed portrait socket.
- Added an `I` key label and open/close binding for Inventory, moved the six-slot quick inventory into a lower-right 2x3 grid, and retained normal item hotkeys and interactions.
- Reworked the compact party interface into selectable upper-left portrait rows ordered as the other owned hero, pet, then companions; moved target/threat details to the lower-left and removed the redundant minimap `UNITS` strip.
- Replaced the intermittent cooldown animation with a continuous clockwise radial overlay and a larger countdown that shows tenths below ten seconds.
- Restored cinematic speaker portraits so they appear during dialogue with the character's normal talking animation.
- Fixed conflicts between different totems when casting from the action bar.

## [24.10.2026]

- Restored the preplaced Spirit Healers' reveal after graveyard revival: they remain visible for 60 seconds, stay visible while their recovery dialogue is open, and then fade back into Ghost form.
- Fixed the Modern HUD disappearing immediately after its startup flash.
- Moved the compact minimap to the upper-right widescreen corner, with player, companion, and standard minimap controls grouped directly beneath it.
- Added an icon-only right-side shortcut rail for Inventory, Abilities, Talents, Stats, party monitor, and threat panel. Hovering an icon identifies its action, overlay shortcuts show when active, and Inspect appears contextually for eligible friendly selections.
- Removed the redundant text-based Abilities, Inventory, and Inspect buttons from the bottom HUD.
- Redesigned the Modern HUD art set with retained wolf-head endcaps, blackened Horde iron, rawhide lashings, tusk fittings, muted red cloth, angular runes, and storm-blue shamanic accents. The elemental medallion and totem badges now use clearer matching symbols, and the chassis center remains transparent for resource bars and action slots.
- Returning from Kribugs' Special Deal now reliably reopens his dialogue choices instead of leaving the player in cinematic mode.

## [23.10.2026]

- Expanded the Modern HUD action bar to twenty-four abilities in two rows. The first row keeps the `1` through `=` bindings, while second-row abilities start unbound and can use the existing slot-rebinding flow.
- Replaced rectangular cooldown shading with a Warcraft-style radial cooldown sweep and retained the numerical countdown over each cooling ability.
- Restored click handling for Abilities, Inventory, Inspect, and the six quick-item slots. Empty quick-item slots no longer display red cancel icons, and Inspect now appears only for a selected non-player-owned friendly or neutral unit.
- Removed the unexplained E/F/W/A placeholder squares. Element badges now appear only while the matching totem is active and continue to show its remaining duration.
- Moved the single compact minimap, unit selectors, and minimap controls to the real widescreen client edge. Reopening the compact minimap after enlargement now uses the same resolution-aware placement, and the selector strip supports the player hero, pet, and current companions.
- Replaced the duplicated portrait medallion with a neutral icon portrait frame, removed an unstable animated-portrait layout, removed the black trim above the resource bars, and added a taller transparent HUD chassis sized for both action-bar rows.
- Escape now cancels Modern HUD targeting, assignment, slot movement, rebinding, and the elemental flyout without also enlarging the minimap.

## [22.10.2026]

- Camera orbit with the Free-camera-style right mouse button now suppresses Warcraft III smart movement commands until the button is released.
- Fixed Modern HUD casting for existing saves and newly learned abilities, including melee attacks, unit-target spells, and ground-target spells.
- Unit-target actions now capture the exact unit under the cursor before falling back to nearby target selection. After targeting, command selection returns to the player hero while the compact target display retains the chosen unit and shows its level and resources.
- Restored Warcraft's default Attack and Stop hotkeys, repaired right-click slot assignment/swapping/rebinding, and made the Abilities, Inventory, and Inspect controls respond when clicked.
- Added six synchronized quick-item slots for the player hero's normal inventory, completed the 100% health/mana fills, enlarged the hero portrait treatment, and reduced the oversized target panel.
- Replaced the Modern HUD's static hero icon with Warcraft III's animated model portrait, with the icon retained as an automatic fallback.

## [21.10.2026]

- Fixed Modern HUD world targeting so the action-slot click no longer consumes the pending cast; the following terrain or unit click now supplies the target while the resource HUD remains bound to the player hero. Fixed Stormstrike and Whirlwind dispatch and restored Stormstrike's action-bar icon fallback.
- Refined the Modern HUD with flat-ended health, mana, and XP fills, current/maximum plus percentage resource text, ten XP progress segments, steadier manually controlled ability tooltips, and icon-backed Bag, Gear, and Look controls.
- Fixed Abilities-book assignment and bar editing input. Right-clicking a learned active ability now closes the book and waits for a destination slot; right-click slot swapping and Shift-right-click session key rebinding use the actual mouse input.
- Expanded the Modern HUD into a functional loadout interface. Learned abilities automatically fill empty slots; players can right-click an ability in the Abilities book and choose a bar slot, right-click two bar slots to swap them, or Shift-right-click a slot and press a supported key to rebind it for the session.
- Added Modern HUD Bag, Gear, and Look controls backed by the existing inventory, equipment, and read-only inspect systems. Stealth and equipment-granted Shield Block now appear in dedicated contextual slots instead of consuming general action-bar space.
- Restored standard minimap buttons in the compact view. Closing the enlarged map returns the minimap to its Modern HUD position.

## [20.10.2026]

- Restored Modern HUD mouse input and added working `1` through `=` action-slot hotkeys. Added a compact upper-left minimap shell with Nazgrek/Zul'kis selectors, improved inactive element-badge readability, aligned the health/mana fills inside their frame, and refined the Abilities button.
- Added a Camera setting for choosing Free-camera-style right-mouse orbit or middle-mouse drag. Free-camera style is now the default orbit input.
- Moved the Dynamic Far Z Auto toggle from Camera to Settings beside the Far Z profile. The Abilities panel Return button now returns to the Game menu when opened there and returns to Stats when opened from a hero's Stats panel.
- Updated the modern player HUD to remove the leftover black console backdrop and added four clear Earth, Fire, Water, and Air status badges. A placed totem now enlarges its element badge and shows its remaining lifetime as both seconds and a short progress bar.
- Added an Information panel to the Game menu. It shows the current 360-day seasonal calendar day, total days passed, season, selected player hero's current zone and weather, and a scrollable list of completed daily quests that unlock again the next day.

## [16.10.2026]

- Added a Talents entry to the main Game menu and a hero-only Talents button between Abilities and Professions in Stats. The talent panel now follows the currently selected player-owned Nazgrek or Zul'kis and returns to the panel that opened it.
- Split minimap marker controls into a dedicated Minimap Settings page. The main Settings page now groups difficulty, UI sounds, AI unit cap, Dynamic Far Z profile, doodad culling, and full/reduced weather detail controls.

## [14.10.2026]

- Failed startup loads now return to the `New Game` / `Load Saved` choice without advancing world startup. Unreadable or incompatible saves can retry another slot or continue as a new game; failures after loading has already changed the game remain locked and request a map restart.
- Escort NPCs now travel at a calmer 200 default speed and require the protecting hero to remain within a much closer 900-unit default range.
- Speaking or trading with an active escort pauses its route. After dialogue closes, it waits five seconds before moving again; the dialogue also offers Wait here / Let's move controls for voluntary stops.
- Nazgrek and Zul'kis now vary their reusable quest replies without immediately repeating the same line, with separate selection contexts for Kill, Fetch, Talk, and Escort quests.

## [13.10.2026]

- Escort NPCs now stop travelling whenever either the assigned player hero or escort NPC is attacked or remains in combat, and resume only after both are out of combat and the active ambush has ended.

## [12.10.2026]

- Escort NPCs now stop when attacked and resume their route only after combat or the active ambush has ended. Cedran Pike, Giznak Edgeprice, and Rixit Roadcoin retreat behind the protecting hero before waiting.
- Sirensong escort ambushes for Gorthak, Rixit, and Mugrok now draw jungle trolls or naga from the current zone instead of spawning unrelated satyrs.
- Updated the post-preload startup flow with a first `New Game` / `Load Saved` choice. New Game continues to the existing game-mode and difficulty choices, while Load Saved lists six local PotS slots before gameplay begins.
- Added a `Save / Load` entry to the Game menu. Party saves now preserve Nazgrek and an owned Zul'kis independently, including each hero's level/XP, learned persistent abilities, normal inventory, custom bag layout/items, equipped items, charges, base attributes, skill points, ability points, and vitals.

## [10.10.2026]

- Added automatic Far Z scaling to the Camera UI. Its end goal is to improve performance seamlessly by avoiding rendering distant parts of the world that the player is not looking toward. It can be disabled or run with Light, Medium, or Heavy profiles: steeper/top-down gameplay views reduce draw distance, while cameras tilted farther toward the horizon automatically gain the range needed to show more of the world; cinematic cameras retain their authored range, and enclosed dungeon profiles can impose tighter limits.
- Boom Mine and Gnoll Hideout now both allow the dungeon camera angle to be adjusted within the limited 270-295-degree range.
- Minimap quest icons now show active ongoing and ready-to-turn-in quests globally, while available quests are shown only when they are within 2000 range of the currently controlled hero. Nearby available quest icons can be disabled from the Settings UI.
- Updated shared escort quests so the escorted NPC walks toward its destination while the hero accompanies it, instead of requiring the player to discover the route by pulling a following NPC behind them.
- Escort NPCs now stop and mark their position when the accepting hero falls outside the route leash, then resume automatically when the hero returns.

## [9.10.2026]

- Updated vendor quest descriptions, supply targets, and voiced lines to use consistent vendor names.
- Revised reusable Kill, Fetch, and Talk replies to sound more natural, with additional Human, Morgrim Dwarf, Troll, and Tauren voices.
- Added character-specific Bonecrusher quest dialogue.

## [7.10.2026]

- Fixed distant map units remaining visible and disappearing in slow waves after the intro cinematic.
- Fixed Zul'kis's arrival ship being hidden during the camera handoff; the ship now reveals itself and nearby units before the first arrival shot.

## [4.10.2026]

- Dynamic minimap camera safety turns now happen only when a chunk-bounds update actually needs one, use a much shorter turn, and automatically return to the player's chosen camera rotation afterward.
- Initial aggro notices are disabled by default; later changes of the enemy's target remain visible.
- Fixed zone discovery and entered notifications not appearing while playing as Zul'kis after control transferred away from Nazgrek.

## [3.10.2026]

- Updated Copper, Tin, Silver, Bronze, Iron, Steel, Gold, Mithril, Arcanite, and Thorium Bar ground visuals so stacks of 1-5 use one rotating ingot, 6-10 use a rotating three-ingot pile, and 11-20 use a rotating six-ingot pile in the closest available metal color.

## [29.9.2026]

- Fixed failed vendor escort destination checks leaving the player in cinematic mode. The warning now names the missing configured destination before returning control.
- Fixed generic vendor quest effects appearing only after selecting the giver; overhead quest markers now receive a post-initialization rebuild while their existing minimap status remains intact.

## [28.9.2026]

- Fixed closing Camera settings leaving middle-mouse orbit permanently blocked.
- Fixed vendor escort destinations failing to resolve when the destination NPC is not a merchant or quest giver.
- Expanded five escort routes with repeated enemy attacks during travel.

## [25.9.2026]

- Improved open-world boss introductions, encounter resets, combat reactions, and sound playback.
- Fixed a completed Boom Mine story encounter being recreated by a later dungeon reset.

## [23.9.2026]

- Added camera controls for enabling mouse orbit and independently inverting its horizontal and vertical directions.
- Added target-panel settings, minimize/maximize and close controls, optional automatic opening during party combat, mana and aggro-text toggles, and clearer hero names. The panel now sits beside the hero icons.

## [21.9.2026]

- Added rare ambient wolf hunts in Twilight Grove, Sereneglade, Thornwoods, and Havenwoods. When a player or registered AI hero is nearby, idle wild wolves may form a local hunting pack for a stag or boar, with occasional temporary pack members.

## [19.9.2026]

- Fixed the minimap full-map toggle using the wrong camera-bounds transform, which could place units from the previous chunk incorrectly across the full-map image.
- Selecting an ordinary enemy with active threat opens a compact translucent threat view with the current aggro holder at the top. Enemies without threat do not replace the automatic boss display.

## [13.9.2026]

- Dungeon and exterior atmosphere now follows the selected player hero, allowing Nazgrek and Zul'kis to remain on opposite sides of a dungeon transition without applying the wrong zone settings.
- Dungeon transitions now move only companions and pets focused on the hero using the entrance or exit.
- In-progress conversations for Nara Stormhoof, Cedran Pike, and Selyth Venomcup's escorts now vary between three activity-specific vendor lines and three matching replies apiece for Nazgrek and Zul'kis.
- Added seven one-time vendor escorts: three Orc routes, two Goblin routes, one Bonecrusher Ogre route, and one Morgrim Dwarf route. Four require guarding the merchant both to a visit and back to the starting point.
- Five vendor escorts can now trigger route-specific enemy attacks during travel, while Kargun, Giznak, and Torren keep Trade locked until their relocation escort is turned in.

## [12.9.2026]

- Added the one-time Normal vendor escorts `A Road Beneath Open Sky`, `The Ledger Comes Home`, and `Bottles in the Gloom` for Nara Stormhoof, Cedran Pike, and Selyth Venomcup, with race-, trade-, and location-specific dialogue for Nazgrek, Zul'kis, and nearby AI companions.
- Updated Cedran Pike's `The Travelling Manifest` text to use the canonical Cedran Pike and Merrick Wayland identities.

## [11.9.2026]

- Restored Gnoll Head drops for Ragno's Gnoll Headcount quest: eligible gnolls have a 25% chance to drop a head while the quest is active.
- Fullscreen cinematics now keep scenery visible throughout the presentation.
- Improved scrolling performance in merchant item lists.
- Fixed Horde Restoration Shamans incorrectly appearing as bag merchants.
- Changed death item loss by difficulty: Story drops nothing, Normal drops only quick-inventory items, and Hard drops equipped gear, stored bag items, and quick-inventory items.
- Restored voiced dialogue for Mistaken Kin with matching Nazgrek and Zul'kis responses.
- Added rain-impact effects on water and land, scaled to rainfall intensity.
- Fixed the Lumberjack Duties peon ignoring eligible Pine Trees.
- Companion Move and Attack commands now return each companion and pet to its saved Passive, Normal, or Aggressive mode when finished or after 15 seconds.
- Fixed a late quest objective failing to complete and improved the associated character's appearance.
- Corrected the Enhancement Master's farewell subtitle to match the spoken audio.

## [10.9.2026]

- Fixed the Lumberjack Duties peon failing to harvest when Zul'kis accepted the quest; he now follows the accepting hero.
- Corrected graveyard selection when gameplay returns to Nazgrek.
- Fixed a quest follower getting stuck or falling too far behind.
- Removed lingering steam-breath effects from dead units.
- Made terrain-fog transitions slower and more gradual.
- Restored Zul'kis's missing companion-command voices and two item-error sounds.

## [8.9.2026]

- Removed obsolete decline choices from Outcast Jin'Zun's quest dialogue and kept him stationary until dialogue cinematics fully finish.
- Nazgrek's companions temporarily leave the active companion roster during Zul'kis's intro, so hidden companions no longer consume Zul'kis's party capacity or appear in his companion count; their previous status returns silently with Nazgrek.
- Companion details in Stats panel now show Rested when their assigned player-hero leader is rested.
- Fixed the vendor camera becoming freely movable when shop panel changed to another automatic camera angle.
- Fixed Aerendyl and seven other non-canonical or legacy unit types being automatically treated as current vendors.
- Diversified vendor chatter and transaction reactions across Humans, Tauren, Morgrim Dwarves, Elarindor, Trolls, Orcs, Satyrs, Bonecrusher Ogres, and Goblins. Vendors now retain their racial or faction character when the player buys, sells, exchanges goods, browses, or leaves without trading instead of repeatedly falling back to the same generic remarks.
- Fixed companions and active pets continuing toward autonomous random destinations after a cinematic or dialogue sequence began. Normal mode now stays with the focused hero instead of issuing random nearby attack-moves, and controlled pets no longer receive Neutral Wander while idle.
- Fixed Sirensong-Ashfang wind riders detouring through the Horde Scout Base and added Ironspine Post flights to Sirensong, Ashfang Outpost, and the Scout Base.
- Added a two-way zeppelin route between the Horde Scout Base and Horde Front Base.
- Restored interaction and travel-point discovery at every Wind Rider Master, including Ironspine.
- Travel passenger selection now shows each unit's proper name, class, hero/companion/pet role, and unit icon, with centered sprite borders marking selected destinations and travelers.
- Drunk status messages now use hero proper names. Nearby companions react to puking and passing out, pass-out fades are slower, and companion participation in A Night To Remember is more consistent.

## [7.9.2026]

- Updated the Satyr vendor quests `Cull the Stalkers` and `Silence on the Old Path` so Xyros and Faelrix no longer ask the player to kill Satyr units; their targets are now Gnolls and Ironjaw Basilisks, respectively.
- Corrected further Satyr quest requests so their tasks no longer target their own faction.
- Reworked the affected quest descriptions and Satyr vendor lines to name the concrete threats, routes, and consequences instead of relying on generic kill-task wording.
- minimap now anticipates nearby chunk borders and gently moves unsafe gameplay rotation toward the nearest legal angle without overriding held player rotation controls. Fullscreen cinematics suspend the correction and all minimap chunk activity before taking camera control.

## [5.9.2026]

- Fixed Graknar's bag shop retaining the previous merchant's Trade Goods display on its first frame and Back leaving the player in cinematic mode instead of restoring Graknar's quest/trade choices.

## [4.9.2026]

- Added `/unstuck` for moving selected Nazgrek and/or Zul'kis to the safe Traveler's Journal arrival point at Nazgrek's Hut. Each hero has a five-minute cooldown; using it also starts that hero's normal Journal cooldown.
- Fixed Emberpeak and Dragonfire Peaks dragons becoming permanently idle.
- Corrected quest-discovery timing and party visibility around the transition between the two heroes' opening sections.
- Fixed the opening river ship beginning its movement too late.
- Made automatic minimap camera corrections gentler and limited them to the nearest safe viewing angle.
- Corrected Nazgrek's initial graveyard selection; changing graveyards now reports the surrounding zone name.
- Restored missing shield-vendor voices.
- Vendor-type labels now remain hidden during fullscreen conversations.
- Fixed available quests becoming unavailable when a quest-giver conversation begins.
- Zone, weather, day/night, and post-storm fog changes now smoothly transition both color and viewing distance.

## [3.9.2026]

- Fixed Graknar's bag shop displaying placeholder icons, obscured item details, or the previous merchant's goods, and failing to return to an Escape-closeable conversation.
- Corrected Ragno's quest marker when a quest involves another NPC.
- Fixed Escape skipping through quest-giver entry sequences into an invisible dialogue menu.
- Ability trainer panels now keep the camera locked while allowing mouse interaction.
- Fixed cinematic cameras slowly travelling across minimap sections instead of cutting directly to the intended shot.
- Improved narrator presentation, character staging, and uninterrupted camera transitions in the opening story.
- Companions in Normal mode now remember their focused hero's attack target and assist when idle. Improved follow behavior and reduced repeated attack orders.

## [31.8.2026]

- Fixed empty quest menus after an NPC respawn and recovered quests that were discovered but could not be selected.
- Fixed a single Escape press skipping dialogue and immediately closing the next menu, leaving the camera locked.
- Quest updates now show the completed objective before announcing the next one.
- Fixed quest givers hiding quests below Neutral reputation when those quests have no reputation requirement.
- Escape now consistently advances entry transitions, skips spoken lines, closes choices, and completes dialogue exits.
- Fixed the rotating death camera remaining at the old location after revival.
- Restored missing follow-up quest availability after the opening defense sequence.
- Kept the camera locked while learning or resetting abilities.
- Added voiced Zul'kis replies for trainers, information requests, trading, following, accepting, declining, and farewells.
- Improved opening-story camera cuts, character movement, faction colors, narrator delivery, animation continuity, and pauses between dialogue.
- Corrected graveyard indicators and restoration of the player's selected graveyard between hero sections.
- Fixed expired companion bodies standing up to repeat their death animation.
- Corrected a quest-completion trigger firing before nearby combat had ended and added more varied combat reactions.

## [30.8.2026]

- Quest completions now display before their follow-up notifications, with five-second pauses; follow-up objectives stay hidden until their reveal.
- New-objective messages now show only the objective that changed.
- Fixed Ragno's Escape handling and missing follow-up dialogue after completing the opening defense.
- Restored one-time Orc Grunt conversations at the scout base and mountain camp.
- Added the Elemental Master's ordered Summon Elemental covenant quests for Air, Earth, Fire, and Water. Return each essence to the trainer who assigned that rank; Stormcaller remains required, and Greater Elementals remain the final ability-point upgrade.
- Added matching elemental-essence drops.
- Added Erduk's one-time Heads of the Murlocs quest, requiring 40 heads and rewarding experience, gold, and Horde reputation.
- Improved the opening defense's dialogue pacing, enemy attack behavior, and companion staging.
- Fixed Hint notifications obscuring or repeatedly dimming the Game button; it now briefly displays `Game!`.
- Improved the two heroes' introductory cameras, narrator timing, conversation markers, party composition, combat reactions, and transitions back to gameplay.
- Added a companion-support hint explaining patrol modes, group orders, and healing/support roles.
- Fixed death-camera movement continuing after revival.
- Fixed Graknar and Kribugs leaving the player stuck in fullscreen dialogue when exiting trade.

## [29.8.2026]

- Corrected revival and graveyard selection during transitions between the heroes' opening sections.
- Added Zul'kis's starter loadout: Shadowcaster's Scepter, eight modest Darkspear travel pieces, two Mana Potions, one Healing Potion, and Purified Water. Equipment bonuses remain small.
- Corrected the Game-button Hint alert and unread marker.
- Fixed missing follow-up quests and Escape leaving Ragno's conversation without choices.
- Restored an opening-defense warning and corrected camera control after its introduction finishes or is skipped.
- Improved introductory camera cuts, narrator lines, character animation continuity, and overlapping greetings.
- Kept the Inspect button hidden during fullscreen cinematics.
- Fixed placed Traveler's Journals failing to provide a replacement or bind a new home.
- Selecting a world Journal now opens a dedicated binding view with Take Journal, Set Home, and Cancel actions.

## [28.8.2026]

- Added Quinx's level-5 Shredder Fuel side quest and periodic tree-harvesting behavior.
- Specialized goblin explosives and reagent merchants now sell Goblin Rocket Fuel for 150 gold, stocking four canisters and replenishing one every five minutes.
- Revised selected hero and companion reactions to drunkenness; reactions now follow the visible action instead of playing too early.
- Human patrol activity now varies between one and two groups, with separate Sereneglade-Twilight Grove and Havenwoods routes.
- Improved pass-out fades and party recovery on waking; active boss and arena encounters are interrupted.

## [27.8.2026]

- Corrected scenic Sirensong?Ashfang wyvern routes through the Horde Scout Base.
- Added a recurring Mok'natha battlefield with small orc and ogre forces attacking along varied routes.
- Added coordinated human patrols in Twilight Grove, Sereneglade, and Havenwoods, including temporary camps and occasional scouting by Captain Maelhood.
- Fixed Hint-button flashes and persistent unread indicators.
- Improved opening-quest discovery timing so objectives appear after the relevant cinematics.
- Added Nazgrek's opening Wolf Hunt I and flask-making quest progression; the flask can be crafted from Alchemy 0.
- Added Zul'kis's parallel opening adventure and improved transitions between the two heroes.
- Removed inappropriate quest-giver markers from the player heroes and hid hero-specific markers when the required hero is unavailable.
- Improved party isolation and restoration when control switches between heroes.
- Corrected character positioning, follow-up quest availability, and fullscreen dialogue exits in the opening story.
- Added Bramblehide Village as a Havenwoods subzone.
- Improved the visual feedback for a temporary quest-related charm.

## [26.8.2026]

- Added the voiced five-part Boom Brothers and Atex Blix quest chain, including Boom Mine content.
- Added limited, slowly replenishing explosives stock to Snikka Sparkdust as an alternative quest-supply source.
- Improved Hint timing with a notification queue, shorter messages, and persistent unread effects.
- Added contextual hints for revival, graveyards, Journals, quests, return flights, progression points, specializations, Spirit Shards, companions, pet fatigue, reputation, and explosives.
- Added a quest-related Deadwoods boss encounter.
- Added the Traveler's Journal home system: bind a shared home, inspect each hero's Journal and cooldown, ping home, and channel a nearby-party return.
- Added Traveler's Journal to the main menu.

## [25.8.2026]

- Added new story quests involving Velyssara, Grum Bloodfang, and Kaelthir, with voiced dialogue and quest-specific interactions.
- Added destination-zone icons to the travel window, with subzones inheriting their parent zone's icon where needed.
- Added Graknar's level-2 Mistaken Kin recovery-and-escort quest, with retries after failure.
- Replaced Graknar's time-limited trade window with a persistent bag shop.
- Added Grim's Big Bear Tooth daily quest.
- Fixed Escape and greeting completion failing to reveal Granis, Garthork, and Krezgrel's dialogue choices.
- Restored Garthork's introductory conversation.
- Fixed a quest giver's greeting, negotiation choices, missing hero replies, audio, and cinematic positioning.
- Corrected an arena-related quest objective so progress is reported only after the required challenge succeeds.

## [24.8.2026]

- Added Granis's quest and a nine-wave outpost-defense follow-up with defender survival conditions, support-item drops, failure cleanup, and retries.
- Added Garthork's story quest.
- Added Krezgrel's Murloc Fins and Rescue The Grunts daily quests, including randomized rescue targets.

## [23.8.2026]

- Split each custom quest-journal entry into Details, Description, Objectives, and Rewards tabs; item rewards now display their item icon and extended tooltip.
- Added live question-mark markers to current talk-objective targets, including `A Night To Remember` witnesses, supply handoffs, apology targets, and forgiveness returns.
- Alcohol now absorbs one Drunk point at a time before natural decay begins, while repeatable puke and pass-out checks rise steeply at high intoxication instead of occurring only when a drink is consumed.
- Puking now has a three-second stagger and animation, followed by ten seconds of reduced accuracy and armor.
- Player pass-outs now hide the game menu and quest-log controls until the wake-up camera finishes, then display dialogue after the cinematic interface closes.
- Player pass-outs now hold the black screen for five seconds, begin their sleeping camera at a closer distance, and let one or two nearby companions or the other player hero react before the hungover hero wakes.
- Nazgrek and Zul'kis now each choose from four urgent reactions when the other player hero passes out; these remain separate from the passed-out hero's Hangover wake-up lines.
- Nazgrek's fourth Zul'kis pass-out reaction now asks how many drinks he has had.
- After a player pass-out relocation, the other player hero, the full active companion party, and the active pet now appear nearby and move toward the sleeping hero during the fade-in cinematic.
- Travel ships, wyverns, and zeppelins now update zone music, ambience, fog, lighting, and effects as their carrier crosses into a new zone.
- Configured Sirensong-Scout Base and Scout Base-Ashfang Outpost wyvern routes now validate their full scenic waypoint sequence instead of silently falling back to direct travel.

## [22.8.2026]

- Fixed Outcast Jin'Zun randomly walking away during dialogue.
- Updated all 40 cooking foods and 15 drinks with explicit Well Fed or Well Hydrated durations, balanced alcoholic drinks around repeated consumption, and removed their shared item cooldown restriction.
- Wyvern flights between Sirensong, Horde Scout Base, and Ashfang Outpost now follow the first configured scenic waypoint routes in both directions.

## [21.8.2026]

- Added a persistent 0?100 Drunk stat, party-only intoxication notices, gradual sobering, visible sickness effects, and a staged pass-out camera with protection while sleeping.
- Added clearer zone hints and varied hero questions to a repeatable quest involving the previous night's events.
- Fixed travel skip and drop-out prompts so choices remain clickable and Escape preserves the player's camera settings.
- Reorganized quest-journal details into Details, Description, Objectives, and Rewards, with clearer contacts and empty states.
- Replaced the standard quest list with a custom journal featuring live progress, Normal/Daily/Repeatable filters, and Story/Dungeon/Class/Profession categories.
- Expanded the repeatable quest's companion participation, varied errands, location-specific dialogue, and matching Nazgrek/Zul'kis replies.

## [20.8.2026]

- Expanded intoxication effects with escalating sickness and pass-out chances, temporary hit/armor penalties, witness reactions, waking sequences, and five-minute Hangovers.
- Added the repeatable quest A Night To Remember.
- Updated the Satyr rare-goods, reagent, enchanting, and potion merchants with distinct identities and a shared female Satyr voice style.
- Added four personality-specific Nazgrek and Zul'kis replies for generic quest acceptance, completion, progress, supply handoffs, and purchases.

## [18.8.2026]

- Human, Orc, Troll, Goblin, Tauren, Satyr, Morgrim Dwarf, Elarindor, and Bonecrusher voices now offer more varied speakers within each race and gender.
- Vendors now distribute regional and role-appropriate voice profiles across their roster, and quest-giving vendors retain the same voice while trading and giving quests.
- Nazgrek and Zul'kis now have twelve additional reusable generic quest replies each.

## [16.8.2026]

- Crafting cameras now remain locked to the active crafting unit during normal and repeated query crafting.
- Ship-travel cameras now target above the vehicle origin, keeping the deck centered instead of framing the hull and waterline.
- Nazgrek and Zul'kis ship proxies now use standing character effects with separately tuned neutral-ship and orc-frigate deck positions.
- Human, goblin, Bonecrusher ogre, Elarindor, and Tauren vendor quests now play their generated race and gender voice files for introductions, completions, and daily follow-up dialogue.
- Nazgrek and Zul'kis now use their own voiced replies when accepting, progressing, completing, collecting, or purchasing for vendor quests.

## [15.8.2026]

- Fixed Aveline's retained fallen pose so her custom model plays its full death animation before the corpse is frozen.
- Gnoll Hideout now allows camera rotation with a limited 270-295-degree angle range.
- Travel-point discovery now reads "New travel point" in white while keeping the discovered destination name green.
- Fullscreen crafting and travel cameras now keep arrow-key control available; travel ESC and intermediate-stop choices stay in fullscreen and use a dedicated travel panel prompt.
- Wyvern and AI flight arrivals now finish reliably after landing instead of remaining stuck when Warcraft does not update the carrier's reported fly height.
- Goblin vendors in Riverbane, Stormhaven, Sirensong, travelling routes, and the arena now have distinct voiced trade dialogue profiles ready for their shared goblin voice set.
- Fiery Mountain, forest, and Sirensong orc vendors, satyr merchants, Bonecrusher ogres, Graknar's bag shop, and the regional human/orc blacksmiths now have voiced transaction profiles ready for their matching voice sets.
- Vendor greetings, shop-open lines, catalog chatter, transaction responses, and farewells now use each vendor's bound race and gender voice, including Tauren bartenders and Elarindor quartermasters.
- Missing vendor audio now preserves dialogue timing based on the displayed text.
- Restyled the crafting panel to match shop panel, with a darker inset backdrop, clearer text hierarchy, larger recipe rows and icons, a framed profession line, and cleaner detail and action-button spacing.
- Kribugs' dialogue now distinguishes the goblin Kribugs from his ogre carrier Mogsnort even though they share one composite unit, with situational Mogsnort interjections and the original ogre grunts, growls, hunger complaint, and fart laugh.
- Kribugs' normal shop now has a clear Back control, reliably returns to his dialogue choices, and uses unique trade chatter and transaction reactions with occasional Mogsnort interruptions.
- Expanded wyvern travel to Verdant Plains, Ashfang Outpost, and Sirensong, with all six flight points requiring player discovery and Verdant Plains also supporting a quest/event unlock.
- Added gradual takeoff and landing height transitions for wyvern and bat travel, plus physical zeppelin travel for AI heroes that treats every flight point as discovered.
- Added the scheduled neutral Ship A route between Sirensong, Dawnhold, and Stormhaven, including Dawnhold drop-out prompts and direction-aware destination choices.
- Travel-point discovery now uses the region-title presentation, a green destination name, and the zone-discovery sound.
- Enabled Mok'natha, Frontbase, and Ironspine as Ship B boarding points and added configured Nazgrek and Zul'kis deck models for ship journeys.

## [14.8.2026]

- Jin'Zun's quests no longer have hidden hero-level requirements. Displayed levels remain recommendations, and prerequisite quests still apply.
- Added configurable wyvern, zeppelin, neutral-ship, and orcish-ship travel with a shop panel-styled destination/passenger panel, fullscreen vehicle camera, paid ESC skipping, ship stop drop-out prompts, party fare accounting, and physical AI wyvern journeys.
- Wyvern and zeppelin routes now require both endpoint travel masters to be discovered before use; ship routes can remain available without endpoint discovery.
- Travel now fades before changing units or camera mode, uses a closer adjustable vehicle camera, shows working ESC confirmation dialogs, and keeps the game menu Game button hidden when configured.
- Added Sirensong as a discoverable wyvern station connected to the three existing Horde stations.
- Vendors now refuse conversations while either participant is in combat, and vendor dialogue, trade UI, camera transitions, and active voicelines end immediately when the hero or vendor attacks, is attacked, dies, or enters combat.

## [13.8.2026]

- Increased grouped dungeon boss and creep respawns from five minutes to thirty minutes; independently selected random-respawn creeps retain their shorter individual timers.

## [12.8.2026]

- Crafting cameras now accept arrow-key angle and rotation changes while staying focused on the crafter.
- Kribugs' Special Deal now has a clearer offer layout. Previous and close reliably return to his dialogue, and gold or inventory errors stay visible in the panel.
- Fixed Ragno's level-one Neutral-Horde quest availability and Protect the Outpost completion staging so Ragno walks into a close conversation position and cinematic units only move while the screen is fully faded out.

## [11.8.2026]

- Dungeon bosses and grouped enemies now respawn together after thirty minutes; some ordinary enemies can return independently after 120?320 seconds.
- Revived AI hero companions now return toward their focused hero's active dungeon entrance; changing focus restores normal behavior, and a companion still outside after two minutes is brought inside.
- Restored party transitions at the Gnoll Hideout, Crypt, and Boom Mine entrances and exits.
- Restored multiple dungeon and open-world boss encounters, trap behavior, warning effects, loot, combat lines, and encounter cleanup.
- Restored Outcast Jin'Zun's quest chain, optional interactions, roaming dialogue, and world interactions. His quests no longer grant Horde reputation.
- Restored Kribugs' six quests, patrol behavior, unique dialogue, and merchant access.
- Kribugs' normal shop now has its own adventuring stock. His separate 1000-gold Special Deal awards a random mystery item and restores player control correctly.
- Added merchant support for bartenders, jewelcrafters, spirit speakers, fel-curio dealers, a voodoo merchant, an arcanist, and a magister, with themed stock.
- Horde Troll merchants now use Horde reputation and their own dialogue voice.
- Autonomous heroes now shop at nearby suitable merchants, limit purchase frequency and duplicate consumables, and choose goods appropriate to the player's progression.
- Fixed starting quest availability, defense-wave presentation, missing quest drops, and the Lumberjack Duties harvesting flow.

## [10.8.2026]

- Companion Attack commands now use the Aggressive mode voice lines, while Move commands use the Normal mode voice lines.
- Forest Trolls now grant Horde reputation using their actual Thornwoods unit types, and killing the Riverbane Bandit Lord now grants Riverbane reputation.
- AI heroes, including Aveline, now use selectable retained fallen bodies and return normally when their automatic revival completes.
- Nazgrek's starting Healing Salve and Spring Water now begin in his standard six-slot inventory instead of inventory.
- Vendor cameras now remain near an 850-range view and drift slowly between low-height, obstacle-checked compositions instead of snapping through distant or excessively elevated shots.
- Closing Trade UI now plays the correct bought, sold, bought-and-sold, or no-transaction response and returns to the vendor's dialogue choices; choosing Exit restores gameplay before the farewell line.
- Fixed Morgrim Clan merchants failing to respond when selected.
- Selecting a vendor below its faction reputation requirement now reports that faction immediately instead of entering a conversation that cannot trade.
- Quest dialogue buttons now use shared state markers, and incomplete generic quests draw from objective-specific kill, fetch, talk, and purchase responses.
- All Morgrim Clan Dwarf vendors now use male names and the dedicated male Dwarf merchant voice profile.
- Vendor dialogue and Trade UI cameras now remain locked to the active vendor until the interaction fully exits.
- Vendor quest availability now updates independently of vendor selection using the higher player-owned Nazgrek or Zulkis level and the giver faction's Neutral reputation requirement.
- Quest giver overhead markers now remain stable when an availability check leaves every quest in the same state.

## [9.8.2026]

- Killing Murlocs and Forest Trolls now grants Horde reputation, Bandits grant Riverbane reputation, mana aberrations grant Elarindor reputation, and Fel Orc kills share the existing Fel Orc reputation behavior.
- The Path of the Shaman logo now remains behind game mode and difficulty selection and disappears only when the selected run starts.
- Nazgrek's complete starter equipment, including Ancestral Charm in a trinket slot, now equips without overflowing the starting bag.
- Restored The True Horde's dedicated Reputation UI description while retaining the separate Morgrim Clan Dwarf faction.
- Fixed registered merchants failing to open dialogue when selected.
- Vendor dialogue and active trade now rotate through five cinematic camera compositions, selecting alternate angles when destructibles obstruct the requested view.
- Companion Move and Attack commands now remain in control after reaching their destination and bypass normal companion and AI behaviors until another companion mode or command replaces them; Hold Position units continue to ignore both commands.
- Profession failure barks now require actual companion-group membership and proximity to a player hero; autonomous AI chatter uses a reduced 2000 range.
- Under-skilled AI gatherers now remember rejected nodes and move away instead of repeatedly trying to harvest them; autonomous wandering uses Move rather than Attack-Move so hostile resource nodes are not acquired incidentally.
- Aveline now uses the retained fallen flow while preserving her AI revive timer.
- Hired non-hero companions now remain as revivable fallen units for 60 seconds, appear dead in Stats UI, and receive a real death with normal cleanup and decay if no Spirit Shard revives them.
- Spirit Shards can now revive fatigued pets as well as other fallen party units, restoring the selected unit to exactly 50% health and 50% mana.
- Game mode and difficulty selection now render in front of the retained Path of the Shaman logo.
- Pressing ESC now closes the active game menu panel through a shared handler.

## [6.8.2026]

- Continued attacks or kills against a temporarily hostile reputation faction now restart its hostility timer, preventing the faction from becoming peaceful while combat is still ongoing.
- Cooking recipes now display the crafted item's item icon consistently with the other professions.
- Opening any crafting station now closes the crafter owner's inventory and equipment panels.
- Raised the crafting camera and restored arrow-key pitch and rotation control while a player craft is in progress.
- Removed the duplicate crafting-start announcement; the crafted-item completion message remains.
- Vendor conversations and quests can now open regardless of faction standing; attempting to enter Trade still rejects insufficient reputation with an on-screen warning.
- Randomized-goods catalogs now retain their inventory between trade sessions and reroll on a configurable internal timer, initially set to fifteen minutes.
- Added eight Morgrim Clan Dwarf vendors covering blacksmithing, weapons, armor, mining supplies, and trade goods.
- Added four Horde Tauren vendors and daily kill or gathering quests for Boran Flintmane, Tawa Deepvein, Koro Windpack, and Nara Stormhoof.
- Added companion Move and Attack commands for unit or point targets; companions in Hold Position ignore both commands.
- Corrected AI hero revival, including Spirit Shards stored in inventory, and made AI heroes use better stored equipment without downgrading their current slot.
- AI heroes can move stored potions, food, drinks, and other active-use consumables into their normal inventory when they need to use them.
- Player death item loss now follows difficulty: Story drops nothing, Normal drops equipped gear, and Hard drops equipped gear plus carried inventory items.
- Spirit Healers now use the preplaced graveyard units and open the shared fullscreen dialogue flow when restoring lost items.

## [5.8.2026]

- Improved delayed respawning for enemies and respawn-managed NPCs.

## [3.8.2026]

- **Hero revival fix:** Fallen heroes now retain visible bodies for revival instead of fading away. Party displays, cameras, quests, inventory, and other gameplay systems consistently recognize them as dead.
- Selecting a vendor now immediately explains insufficient faction reputation, while valid vendors no longer fail silently because of stale NPC casting or combat flags. Other blocked selection states also report their reason.
- Centered pooled vendor-type floating labels over their units instead of anchoring each label's left edge to the unit origin.
- Generic vendor commissions are now presented as Daily quests, Repeatable quests, or Quests instead of the misleading Vendor quest category.
- Added ten one-time vendor quests for Kargun Ashblade, Rukgar Longroad, Vaelith the Covetous, Garrick Holt, Silas Reed, Rixit Roadcoin, Nackle Quickdeal, Mugrok Ironclub, Aerendir Sunblade, and Maerith Silvercrest.
- All fifteen normal vendor quests now include an additional voiced giver line after acceptance and completion. Daily quests add one randomized objective- and culture-specific follow-up after the hero accepts.

## [2.8.2026]

- Lethal hero damage now leaves a visible frozen body without entering Warcraft III's dissipate state. Player, companion, and AI heroes remain available for revival, while other hero bodies are removed after one minute.
- Cooked food and beverages now consume their charges correctly and grant the matching Well Fed or Well Hydrated effect.
- Shops now use item-specific maximum stock and replenishment intervals, restoring one item per interval unless a merchant has different stock settings.
- Fixed vendor floating text exhausting Warcraft III's shared text-tag capacity, restoring reliable totem labels, dropped-item names, casting text, and damage numbers while retaining camera-visible vendor-type labels.
- Reputation faction entries now display a live standing badge over their faction emblem, using distinct Enemy through Exalted textures and a Hostile badge during temporary aggression.
- Added support for eight named Elarindor vendors covering weapons, armor, shields, enchanting supplies, reagents, potions, expedition supplies, and faction-quartermaster goods.
- Elarindor merchants now have faction-specific trade chatter and purchase, sale, exchange, and no-transaction responses with separate male and female voice sets.
- Aerendir Sunblade, Elowen Starweaver, Vaeriel Dawnflask, and Maerith Silvercrest now offer daily Elarindor quests with gold and faction-reputation rewards.
- Vendor quests now use cinematic NPC-and-hero dialogue sequences for acceptance, progress checks, and completion, committing quest events when the sequence finishes.
- Added support for six Horde Tauren vendors covering weapons, armor, shields, provisions, beast supplies, and quartermaster goods.
- Added female Human variants for all 24 Riverbane, Stormhaven, neutral, and travelling Human vendor roles.
- Every merchant voice profile and vendor role now has at least three randomized active-trade lines and three responses for each purchase, sale, mixed-trade, and no-transaction exit outcome.
- Cross-vendor supply quests now require an explicit quest dialogue choice at the target merchant instead of advancing when the merchant is merely selected. Some commissions continue directly into trade and require buying and returning the requested stock item.

## [1.8.2026]

- inventory now has fixed sequential bag tiers from the 12-slot Starting Bag through the 80-slot Bottomless Bag, shows used/total bag space, and sizes partial pages to their occupied rows.
- Shops now show the selected hero's used/total bag space, set purchases to the advertised total capacity, and require Small, Medium, Large, Traveler's, Explorer's, Adventurer's, and Bottomless upgrades in order.
- Opening the game menu now closes inventory and equipment, and the unit Inspect/Close button has been moved upward to avoid the game UI intercepting clicks.
- Shop vendors now require Neutral reputation with their faction by default, while individual goods can require higher standings and remain hidden until unlocked.
- Limited vendor stock now shows its remaining supply, turns grey when sold out, and can replenish after a vendor-defined delay.
- Item charges are now shown on merchant, buyback, inventory/equipment, and quick inventory item icons, and buyback items preserve their sold charge count.
- Shop inventory source labels now distinguish `Inventory` from `Quick inventory`.
- Shop resource text now displays the `Gold` label in yellow and `Arena Marks` in red, with both resource values in white.
- Vendor cinematic transmissions now identify the unit by name or hero proper name followed by its vendor type, such as `Graknar (Bags)`.
- Vendors now speak randomized trade chatter every 60-120 seconds by default and react when a trade closes after purchases, sales, both, or no transaction.
- Blacksmith, general-goods, and bag merchants now have larger role-specific line pools, with reusable human, orc, satyr, Bonecrusher ogre, and regional goblin voice profiles available for future vendors.
- Added 26 ready-to-use merchant catalogs covering weapons, armor, shields, arena rewards, travelling trade, profession supplies, quartermasters, rare goods, provisions, potions, reagents, and other specialized stock.
- Travelling and specialty merchants can now change their stock and dialogue according to their current zone, while curiosity merchants reroll randomized goods whenever a new trade begins.
- Ninety-three new Orc, Satyr, Human, Goblin, and Bonecrusher Ogre vendor unit types now have assigned merchant roles and combine their racial or regional personality with role-specific trade dialogue.
- Vendors now display their merchant type as gold floating text while inside the local player's current camera view, with all active labels hidden during cinematics.
- Forty Orc, Satyr, Human, Goblin, and Bonecrusher vendor NPC types now offer generic kill, gathering, and cross-vendor supply quests alongside trading; thirty-five of these quests can be completed again after each new dawn.
- Camp fires now last five minutes instead of one minute.
- Crafting recipe details now include the crafted item's extended tooltip below the recipe description.
- Shields now grant their matching 50%, 75%, or 100% Shield Block ability while equipped and remove that equipment-granted ability when unequipped.
- The Inventory Inspect/Close button has been moved slightly farther upward.
- Well Fed and Well Hydrated recipe abilities no longer occupy visible unit command-card slots while their status buffs are active.
- Drunken vision now follows the active Nazgrek/Zulkis camera target instead of being removed when another unit is merely selected.
- Higher drunkenness now produces stronger irregular camera sway and increasingly frequent mishaps, including sudden stops, facing changes, and accidental casts from learned Shaman abilities.
- Cooking navigation now stays on the selected tier, Food/Beverages group, and recipe screen without reopening an earlier selection layer when a recipe is clicked.
- Opening a different profession workstation now clears the previous profession's selected recipe, preventing Alchemy or other recipe details from carrying into Cooking.
- Reduced lag when navigating Cooking categories and recipes.
- Dead campfires and other destroyed profession stations can no longer start or complete crafting.
- All active pets now become fatigued and revive after lethal damage instead of ordinary tamed beasts dying permanently.
- Fallen player, companion, and AI heroes now remain at their death location without decaying or dissipating, and a Spirit Shard's three-second Revive cast can restore the nearest allied fallen hero within 250 range.
- Nazgrek and Zulkis now revive at the selected graveyard after 30 seconds, where a temporary Spirit Healer or Spirit Walker can recover items left at their death site.
- A fallen active player hero now receives the rotating death camera until revival; switching the camera to the other living player hero ends the death view immediately.
- Kicked pets now return to Shadowclaw's home and can be invited back later, automatically replacing the current pet. The roster holds two ordinary tamed pets in addition to Shadowclaw.
- Taming a third ordinary pet now opens a choice dialog that dismisses one of the two older pets while keeping the newly tamed pet active; dismissed pets leave their carried items at home.

## [30.7.2026]

- Shop category buttons now use smaller shared label text so longer categories such as `Consumables` and `Food and Drink` fit without resizing the buttons.
- Added Graknar as a bag-space merchant selling direct inventory upgrades for +6, +12, and +20 slots, starting at 1000 gold for the +6 upgrade.
- AI heroes now start with a limited 16-slot inventory allowance and cannot buy bag-space upgrades from vendors.
- Crafting UI recipe lists now use more of the available panel height, so Cooking tier recipe lists fit without unnecessary extra pages.
- Cooking tier subcategories now move directly from `Food` or `Beverages` into the actual recipe list instead of showing a duplicate-looking Food/Beverages category screen.
- Added the first arena system pass.
  - Arena masters can now open an arena dialog with Waves, Team Deathmatch, Capture the Flag, and Duel entries.
  - Waves mode supports Easy, Medium, and Hard difficulties, delayed wave starts, inter-wave recovery, final-wave boss spawns, random health/mana powerups, and Arena Mark rewards.
  - Team Deathmatch starts immediately against a generated opposing team and rewards Arena Marks on victory.
  - Capture the Flag and Duel are registered but currently fail cleanly with setup messages until their dedicated AI/opponent-selection passes are implemented.

## [29.7.2026]

- Added the first PotS merchant shop system draft.
  - Vendors can now expose shop stock through a dedicated shop panel.
  - The shop panel has a shared `Merchant` / `You` mode button for switching between vendor goods and the player's sellable items.
  - The `You` view combines inventory, equipment, and quick inventory items into one list.
  - Equipped equipment items are shown with an `Equipt` label and are blocked from normal selling until unequipped.
  - Merchant stock can now be filtered through category buttons such as `Shields`, with `All` as the default category.
  - Sold items now appear under each vendor's capped `Recent` category so players can buy back mistakes across later visits until the item is bought back or older entries are evicted.
  - Vendor trade entry now uses the same fullscreen fade/camera presentation as ability trainers and exits if the buyer or vendor is attacked, dies, or the shop UI is closed.
  - Shop item selection now uses a normal menu-click sound, while successful buying and selling use distinct gold sounds.
  - The shop panel now shows the player's current `Gold` and `Arena Marks` beneath the transaction message.
  - Quest/campaign items are now marked as unsellable in the shop and cannot be sold from inventory, quick inventory, or AI sell paths.
  - Added starter General Goods and Blacksmith vendor templates with conservative early-game stock.

## [25.7.2026]

- Shaman abilities now use hero attributes more meaningfully:
  - Enhancement melee-focused abilities lean more on Strength and Agility.
  - Elemental and Restoration caster abilities lean more on Intelligence.
  - Frost Shock, Nature Shock, Lightning Strike, and Lightning Shield now gain Intelligence-based damage scaling.
  - Stormstrike, Whirlwind, Ghost Wolf Bite, Primal Force, Feral Spirits, and Bloodlust now include Strength/Agility or hybrid attribute scaling where appropriate.

- Summon Elemental and Feral Spirits summons now behave more like temporary controlled companions:
  - Summoned elementals and spirit wolves are included in the companion follow/idle update flow.
  - They appear in party monitor and Stats panel as tracked companion-style rows.
  - They still do not consume normal companion party slots.

- Ability trainer cameras now wait for the conversation fade instead of snapping immediately to the trainer.

- Ability trainer interactions now provide voiced/text trainer feedback when:
  - The player successfully learns an ability.
  - The player resets abilities, specialization, or talents.
  - The player cannot learn or reset because of missing points, missing requirements, or invalid state.

- Added specialization requirements for higher shaman progression abilities:
  - Summon Elemental requires Stormcaller.
  - Ghost Wolf / Spirit Wolf requires Earthwarden and still keeps its initial Spirit Wolf quest-training lock.
  - Reincarnation requires Spiritmender.
  - Totem Master requires Totemist.

- Ghost Wolf now keeps Nazgrek/Zul'kis focused companions and pets following the active wolf form, then retargets them back to the normal hero form when shifting out.

- Improved Ancestral Ward's orbiting shield visuals:
  - Restored three orbiting Faerie Dragon missile segments around the shielded unit.
  - Restored positioned hit flare behavior for absorbed damage.
  - Added safer target fallback for direct casts.

- Added the first Fishing profession gameplay flow:
  - Fish pools can be selected and fished by a tracked hero carrying a registered fishing pole.
  - Fish pools can spawn in non-walkable shallow or deep water.
  - All configured fishing poles can qualify for fishing, with stronger poles contributing their Fishing item-stat bonus.
  - Fishing now uses a compact WoW-style fishing interface cast bar with a random bite window and Reel button.
  - fishing interface was moved higher on screen so it no longer covers the bottom unit portrait/command UI.
  - fishing interface status text now sits under the fishing bar instead of overlapping the action buttons.
  - Missing the reel window fails the attempt with "Fish went away".
  - Moving too far away from the fish pool now interrupts fishing.
  - fishing interface bait selection now uses the strongest usable bait found in quick inventory or inventory.
  - Baits with Fishing skill requirements cannot be applied until the fisher meets the requirement.
  - Fishing skill, fishing pole bonuses, and temporary bait bonuses can affect success against the selected pool's required fishing level.

- Added the first Skinning profession gameplay flow:
  - The Skinning Knife's Skin ability can now skin nearby dead beast corpses while the corpse still exists.
  - Skinning requires a Skinning Knife in normal inventory, inventory, or equipped in equipment main hand.
  - Skinning takes 1.5 seconds and is interrupted by new orders, attacks, death, moving away, losing the knife, or corpse invalidation.
  - Successful skinning marks the corpse as skinned until respawn and creates the configured skin item at the corpse location.

- Equipment now fits its intended slots more reliably:
  - `Stave` items are treated as two-handed main-hand weapons.
  - Trinkets now have two visible equipment slots.
  - Fixed equipment-slot recognition for items such as the Skinning Knife.
  - Fixed equipment stat bonuses being applied twice.
  - equipment and inventory custom tooltips no longer show internal stat/dummy ability object names above the normal item tooltip text.

- Profession bonuses on equipment now contribute to the skill values displayed and used in-game.

## [23.7.2026]

- Ability-point and talent-point gains now give immediate feedback.
- Each shaman talent tree now has its own background artwork.
- Restored non-totem Elemental, Enhancement, and Restoration ability behavior.
- Summoned elementals and spirit wolves now follow and defend like temporary companions without consuming party slots.
- Ghost Wolf shifting now preserves hero progression, inventory, ability ranks, health, mana, and item pickup behavior.
- Ancestral Ward and Water Shield now absorb incoming damage consistently; Water Shield restores mana from absorbed damage.

## [22.7.2026]

- Added a startup loading presentation with widescreen artwork and separate ability, sound, music, and completion phases. Loading a saved game refreshes audio without restarting the introduction.
- Shaman trainers now greet Nazgrek and Zul'kis before opening training, with distinct personalities for Enhancement, Elemental, Restoration, and Totemic teachers.
- Added Learn and Farewell choices, success/error sounds, permanent learned abilities, and a quest requirement for the initial Ghost Wolf rank.
- Added separate talent-tree tabs with ranks, locked states, dependency links, tooltips, and previews of missing requirements and available points.
- Talent allocations can be added, removed, confirmed, or cancelled; effects apply only after confirmation. One talent point is earned per qualifying hero level from level 2.
- Talents can be allocated anywhere; resets require a trainer.
- Improved crafting sound playback, hid the Game button during crafting cinematics, and gave smelting a distinct sound.
- The Stats panel now shows Rested status. Dying removes Rested, and sleeping in a tent can renew it.

## [21.7.2026]

- Restored profession crafting sounds for player and AI crafts.
- Reduced AI crafting interruptions while travelling to a workstation; combat can still interrupt crafting.
- Added positional sound feedback when picking herbs.

## [20.7.2026]

- Campfires now grant rested-experience progress to nearby heroes even when their Warmth effect is not displayed.
- Fixed Rested status producing unintended combat events.
- Tent resting now begins through the Sleep ability and requires Nazgrek or Zul'kis inside; the other hero is safely suspended during the rest.
- Fixed dismantling a tent returning duplicate Tent items.

## [19.7.2026]

- Added a crafting panel for cauldrons, anvils, forges, and tanneries, with campfire cooking support prepared for recipes.
- Recipe lists show required skill, available materials, crafting time, and whether a recipe can be used.
- Player crafting now reserves the station, positions the crafting hero with a short fade, and returns to the recipe panel afterward.
- Added occasional workstation use and working night camps for eligible AI characters.
- Stopped AI gatherers repeatedly attempting resources they lack the skill, tools, or inventory space to use.
- Restored crafting and mining sound feedback, improved crafting cameras and work animations, and added cauldron lighting.
- Crafted items enter the custom inventory first, then quick inventory, then drop at the workstation if there is no room.
- Grouped Alchemy recipes into Basic Alchemy, Basic Potions, Utility Potions, and Flasks.
- Added Copper Chain armor and Reinforced Leather equipment recipes.
- Added smelting for Copper, Tin, Silver, Iron, Gold, Mithril, Arcanite, and Thorium; Bronze uses Copper and Tin, and Steel uses Iron and Coal.

## [8.7.2026]

- `AI` and `Companions`
  Improved AI logic e.g., item pickup
- `Stats panel` / `party monitor`
  Stats panel and party monitor now show companion party status as current/max companions, with an info button explaining the level ranges used for the companion cap.
  party monitor now behaves more like an upper-right party monitor: transparent background, improved icon/name spacing, engineering-icon configuration button, and state-preserving maximize/minimize behavior when opening Stats panel and returning.
  Stats panel now shows unit faction, always-visible ability points, and XP as current/required for pets, companions, and heroes.
- `Companions`
  Companion-controlled AI units with matching profession profiles can try nearby mining veins or herb nodes when they are not in combat, Passive mode, or Hold Position mode.

## [7.7.2026]

- `party monitor`
  Added a compact frame-based party monitor for player heroes, the active pet, and current companions, with maximize/minimize controls, HP/mana bars, level/status display toggles, and a quick button into the full Stats panel.
  Companion and pet status now uses the new party and Stats panels.
- `AI professions`
  AI heroes with profession behavior should no longer get stuck repeatedly trying to mine or gather nodes they cannot actually use because of missing tools, blocked inventory space, insufficient skill, or rejected gather orders.
  Profession failure chatter is now limited to companion-controlled AI units that are close enough to player-owned Nazgrek or Zulkis, preventing distant autonomous AI units from commenting on failed mining/gather attempts.

## [6.7.2026]

- AI heroes with suitable professions can now gather nearby ore, herbs, and other supported resources while idle.
- Added brief social interactions between nearby friendly AI characters and expanded the active wandering-hero population.
- Added Aveline as a unique Riverbane Warrior.
- Limited ambient AI chatter to nearby player heroes and reduced overly frequent Rogue surprise attacks.
- Pets and companions now keep their intended hero focus when that hero falls, instead of silently switching leaders.
- Horde AI companions can now be invited at Friendly reputation; quest companions remain restricted to their relevant quest phases.
- Corrected quest objectives when a quest companion is dismissed.
- Quest-update messages now appear after a short five-second delay.

## [5.7.2026]

- Newly invited or re-invited companions now resume following promptly and refresh their map indicators.
- Reduced overlapping or distant AI chatter and separated Orc and Undead Warlock voice sets.
- Fixed re-inviting quest companions failing to refresh the appropriate objectives or restore their party behavior.
- Improved quest encounter targeting, completion cleanup, and follow-up objective updates.

## [4.7.2026]

- Added support for multiple independent wandering heroes of each class and for heroes temporarily travelling away and returning.
- Limited active population and improved a quest companion's combat behavior.
- Corrected Shadowclaw's description to Wolf.
- Pet ability inspection now opens the Abilities panel.
- Improved map indicators for fatigued pets and restored companion-command feedback sounds.
- Fixed reputation requirements incorrectly blocking re-invitation of active quest companions.

## [3.7.2026]

- Fixed companion controls after invitation or re-invitation, including modes, focus, kick, information, and item dropping.
- Improved Shadowclaw's initial focus, introduction behavior, and return home after dismissal.
- Improved pet fatigue, revival, and movement with the party through dungeon and zone transitions.
- Added an Always setting for companion and pet map icons, including distant units holding position.
- Fixed stale pet entries after dismissal and improved party names, icons, class, type, ability, and fallen-status information.
- Improved quest-companion return behavior, failure handling, and movement during introductory scenes.
- Quest followers now pause outside their permitted areas, show clearer left-behind indicators, and resume when the player returns.
- Standardized floating names on dropped items.
- Made wind weather shorter and less frequent.

## [2.7.2026]

- Continued Vanguard Vale terrain and pathing improvements.
- Improved quest-companion placement after completion.
- Made multi-location quest encounters start and finish more reliably, with better enemy-wave pacing, dialogue timing, and follower behavior.
- Fixed item-name text after transferring items between inventories and dropping them.
- Removed steam-breath effects from dead units.
- Improved companion follow and Hold Position behavior, and made Kick Companion work on the selected party member.

## [1.7.2026]

- Improved quest negotiation timing, retry handling, companion state, and return-objective detection.
- Added clearer visual and sound warnings before enemies arrive in a quest encounter.
- Improved multi-location objective completion and cleanup.
- Collection quests now recognize items already carried and avoid counting the same item twice across inventories.
- Map-icon timing changes now take effect immediately. Added Query, On, and Off settings per category, an option to disable pings, and clearer companion/travel icon priority.
- Added Story, Normal, and Hard difficulty profiles affecting combat, rewards, and revival pacing.

## [30.6.2026]

- Previewed a Poison Nova ability and visual effect for a boss encounter.

## [28.6.2026]

- `Map icons / Settings`
  Added a Settings panel to the in-game `Game` menu with controls for quest/travel/boss/place/companion icon query categories, query timing, rest timing, and a map difficulty placeholder.

## [26.6.2026]

- Improved quest-negotiation prompts so choices do not reopen while dialogue is still playing.
- Improved quest-item extraction feedback and multi-location encounter handling.
- Added floating names to custom-inventory drops and quest-created items, visible only near the player.
- Improved camera resets and fast transitions into caves and other subzones.
- Quest rewards now arrive with the delayed quest-completion presentation.

## [14.6.2026]

- Improved quest turn-in interactions, negotiation timing, character facing, and fade transitions.
- Improved quest-companion combat and follow behavior, encounter cleanup, dialogue queues, failure messages, and retry presentation.
- Fixed quest-item extraction completing inconsistently.
- Mouse-wheel camera reset now returns to the active camera mode, and teleports update the camera target promptly.
- Restored Shadowclaw's proper name and icon in party information.
- Fixed dropped powerup labels remaining after the item disappears.

## [13.6.2026]

- Fixed floating item labels lingering after powerups are consumed.
- Restored Shadowclaw's name and icon and improved quest-companion icons in party information.
- Camera reset controls now immediately restore the intended view; distant cave/interior transitions move the camera directly to the hero.
- Improved quest-negotiation cameras, response timing, and completion transitions.
- Improved multi-stage quest tracking, objective wording, follower combat behavior, and encounter dialogue.
- Restored the two-second quest-item extraction flow and its resulting item drop.

## [11.6.2026]

- Improved quest-negotiation camera framing and Escape prompts.
- Fixed combat continuing after a successful conversation choice.
- Corrected missing escort objectives and inappropriate visibility effects after quest progression.
- Improved quest-companion staging and stopped patrol behavior interfering with an active quest.

## [10.6.2026]

- Negotiation choices now open with Escape after the introductory exchange.
- Softened a close-up quest camera that could clip below terrain.
- Fixed escort completion failing to advance the next objective.
- Failed quest attempts can now return to a usable retry state.

## [8.6.2026]

- `Camera / Zones`
  Entering Boom Mine now switches to a dedicated zone camera profile, and leaving it returns cleanly to the player's previous stored camera mode and settings.
  Boom Mine camera can now be adjusted with the same keyboard rotation / angle controls as normal mode, but with a tighter maximum downward angle suited for that area.
- `Camera / Cinematics`
- Improved camera restoration after cinematics and reduced unexpected camera snaps toward Nazgrek.

## [7.6.2026]

- `Camera / UI`
  Normal camera mode now handles blocker-heavy corridors, tunnels, and terrain-height differences much closer to advanced camera behavior while still respecting the stored normal camera rotation.
  The camera panel now lets players toggle `Safe Camera` on or off directly, and the wounded low-health camera effect now stays visibly active with slower heartbeat-style pulsing instead of brief flickering flashes.
  Duplicate dialog or cinematic camera suspend / resume calls should now be much less likely to restart camera return timing or fight over the current camera state.
- `Abilities panel`
  Player shaman ability trees can now be expanded or collapsed by clicking the specialization rows, and the panel currently starts with all trees closed by default.
  Unlearned abilities are now easier to read at a glance because their icons use a clearer gray unavailable overlay in both the list and detail view.
  Scrolling the abilities list should now be noticeably smoother after the visible-row refresh path was cached.
- `Camera / Cinematics`
- Improved camera restoration after cinematics and reduced unexpected camera snaps toward Nazgrek.

## [6.6.2026]

- `Professions panel`
  Leaving the professions panel open, switching tracked gatherers, and scrolling both panes should now produce much less long-session UI-side FPS decay than before.
- `Camera / Dialog`
  Dialog and quest camera transitions should now return smoothly to the correct stored player camera and interacting hero, and unwanted normal-mode camera drift from page up/down or mouse wheel should immediately reset back to the intended view.

## [5.6.2026]

- `Sirensong`
  Continued terraining work in the `Sirensong` zone, focused mostly on the river route and the troll-side areas.

## [3.6.2026]

- Fixed menu scrollbars moving in the wrong direction or showing when there is nothing to scroll; resolved the known slider-drag/click instability.
- Added matching submenu icons and adjusted spacing in the Game menu.
- Kept lava and fel-damage effects closer to the affected unit's scale.

## [2.6.2026]

- `Terraining`
  Continued terraining work in the `Sirensong` area, focused mostly on the `Panthera` miniboss entrance area.
- `Abilities panel`, `Reputation panel`
  The left-side scrollbars were adjusted so their thumb position should now better match the visible scrollbar art and start from the top instead of the bottom.
  In practice, this slider pass did not yet produce a real improvement and the UI scrollbars still behave incorrectly.

## [1.6.2026]

- `Abilities panel`
  Player shamans now expose a broader real ability list with names/icons/tooltips  instead of only a few placeholder definitions.
  Ability names and specialization labels are being presented in a cleaner format that better matches the intended class/spec display.
  Ability details now show mana cost where available, use a better-sized description area, and make unlearned abilities easier to distinguish visually.
- `Game` menu
  The `Game` menu now includes direct access to `Abilities`, with the panel opening for the currently selected main shaman hero when possible.
  The `Game` button can now be hidden during cinematics and restored afterward through the newer cinematic trigger flow.
- `Camera`
  Advanced camera mode now restores working arrow-key movement instead of only changing the camera view.
- Sirensong small terraining
- Dragonpeak Mountain high mountain terraining

## [31.5.2026]

- Added Abilities to the main Game menu.
- Expanded the shaman ability list beyond the earlier sample entries.
- The panel now follows the selected main hero, defaulting to Nazgrek when neither is selected.

## [30.5.2026]

- `Stats panel`
  The stats panel now shows fuller unit information through the new frame layout, including expanded summary fields and broader derived stats.
  Unit details are now meant to follow the row selected inside the stats UI itself rather than depending on the current world selection.
- `Abilities panel`
  Units opened through `Stats panel` now have a separate ability list and description view, with player shamans showing richer specialization-style text.
- `Reputations`
  Reputation display is now intended to use the frame UI instead of the old multiboard presentation.

## [26.5.2026]

- `Game` menu
  The `Game` menu continues to become a cleaner hub for newer systems.
  Menu presentation is now tighter and more readable as the grouped multi-column layout is refined.
  The main menu title and button presentation are being tuned toward a more polished in-game menu feel.
- Discovery / collection feedback
  Hints now pop with a matching hint sound and cleaner popup formatting.
  Unfound secrets no longer spoil their title or icon in the secrets list.
  Achievements and secrets now give their own unlock sounds when earned/found.

## [25.5.2026]

- Expanded the Game menu with camera controls, hints, achievements, secrets, and command information in a compact grouped layout.
- Continued improving camera restoration after cinematics.

## [24.5.2026]

- Reorganized Zones, Professions, Reputations, and Stats around a central Game menu.
- Investigated severe early-game slowdown associated with the professions interface; validation remained ongoing.

## [23.5.2026]

- Gathering skill increases now show clearer feedback, failed attempts identify the required node, and low-level resources grant slower progression as the character outlevels them.

## [22.5.2026]

- Began separate gathering progression for Nazgrek and Zul'kis, with profession and skill requirements for resource nodes.
- Mining rewards now support a primary material and optional bonus drops.

## [20.5.2026]

- Corrected resource placement failures and excessive clustering. Expired gathering nodes can respawn in freshly chosen locations.
- Added bridges that remain open for direct crossing without switching to an underpass mode.

## [19.5.2026]

- Continued investigating a loading-screen crash associated with resource-node appearance effects; the exact cause remained unconfirmed.

## [18.5.2026]

- Improved placement of randomly spawned herbs and mineral veins within their intended zones.

## [17.5.2026]

- Continued gathering-resource placement and balancing work; herb coverage and placement still needed refinement.

## [16.5.2026]

- Bridge crossings now align units more closely with the entrance center.
- Creature respawn delays now vary independently for each death within the existing 80?240-second range.

## [15.5.2026]

- Reduced patrol pauses and backtracking at bridges, and made recovery from stuck crossings safer.
- Expanded Dragonfire Peaks subzone groundwork.
- Removed rain from Dragonfire Peaks and Emberpeak Highlands in favor of wind and limited snow.
- Corrected terrain-hazard immunity and made lava and fel effects intensify while a unit remains exposed.

## [14.5.2026]

- Improved bridge safety for companions and recovery when a unit dies or gets stuck while crossing.
- Added another bridge and improved movement around cliffs.
- Continued Dragonfire Peaks outpost, dragon-graveyard, and dwarven-mine areas.
- More fire creatures now correctly ignore terrain hazards.
- Halved the attack-speed and defense bonuses granted by Agility.

## [13.5.2026]

- Improved bridge shadows and patrol direction after crossing, and added another bridge.
- Dead bodies no longer take terrain damage; remaining hazard effects play quieter sounds.
- Reduced redundant fog changes and improved fog-distance updates.

## [12.5.2026]

- Reduced bridge state conflicts and patrol backtracking.
- Fixed terrain hazards continuing to damage dead units.
- Temporarily hostile neutral creatures now respawn with their original allegiance.

## [11.5.2026]

- Improved bridge shadow handling, patrol movement, crossing protection, and stuck-unit recovery.
- Reduced terrain-hazard processing overhead and excluded dead units.
- Fixed neutral creatures failing to respawn or returning with the wrong allegiance.

## [10.5.2026]

- Improved neutral-creature recognition and bridge traffic above and below crossings.
- Terrain hazards now apply independently to each exposed unit, with varied sound pitch and more reliable immunity checks. Further bridge testing was still needed.

## [2.5.2026]

- Reworked bridge traffic to coordinate crossings above and below the bridge, reduce collision problems, and recover units stuck in conflicting orders.
- Extended bridge handling beyond previously restricted unit types.

## [1.5.2026]

- Improved bridge activation, crossing protection, and cleanup when units leave unexpectedly or teleport away.
- Units crossing a bridge no longer take damage from the terrain below.

## [26.4.2026]

- Continued lava, rock, and traversal work around Wyrmhold Sanctum.

## [25.4.2026]

- Added terrain hazards that damage exposed units on surfaces such as lava.
- Continued lava and pathing work in Wyrmhold Sanctum.

## [15.4.2026]

- Added the first gathering-node framework, with herbs and mineral veins, skill requirements, resource limits, and respawn timing.

## [13.4.2026]

- Began testing revised loot drops and floating item-name labels; item-creation issues remained under investigation.

## [23.3.2026]

- Continued Wyrmhold Sanctum terrain work.

## [19.3.2026]

- Corrected equipment initialization and Dodge naming.
- Prepared additional mineral veins and herb varieties; their world spawning was still unfinished.

## [18.3.2026]

- Fixed items failing to equip in their intended slots, corrected Cleave descriptions, and restored potion use and charge consumption.
- Item stats now recalculate when a hero stores an item in the bag.
- Continued Sirensong terrain work.

## [17.3.2026]

- Expanded item-stat support for spell power, regeneration, melee and ranged damage, cleave, lifesteal, reflected damage, defenses, and movement speed.

## [16.3.2026]

- Expanded item bonuses and updated hero stat recalculation when picking up or dropping quick-inventory items, alongside the custom equipment system.

## [11.3.2026]

- Continued terrain and vegetation work in Vanguard Vale, Havenwoods, the Stormhaven surroundings, and Deadwoods.

## [1.3.2026]

- Continued cave terrain work and transitions between indoor and outdoor areas.

## [28.2.2026]

- Corrected Nazgrek's cape textures; shield attachment issues still needed work.
- Disabled outdoor weather in dungeons and adjusted dungeon fog and mountain lighting.
- Continued Wyrmhold Sanctum and smaller cave areas.

## [27.2.2026]

- Continued cave-layout drafting and investigation of shield attachment problems.

## [26.2.2026]

- Temporarily disabled clouds and water ripples for performance work.
- Updated Deadwoods lighting and continued work on Havenwoods, Firelands, Sirensong, and Stormhaven scenery.

## [25.2.2026]

- Continued investigating Crypt performance problems and sky-texture quality.
- Added draft small interior areas; Firelands still needed better separation from neighboring scenery.

## [24.2.2026]

- Continued drafting Wyrmhold Sanctum and refining Thornwoods scenery. Crypt performance issues remained under investigation.

## [23.2.2026]

- Continued terrain and dragon-encounter area drafting.

## [22.2.2026]

- Continued Havenwoods, Stormhaven surroundings, and Emberpeak Highlands terrain work.

## [15.2.2026]

- Quest return instructions and markers now update together more consistently.
- Continued terrain work in Vanguard Vale, Verdant Plains, Havenwoods, and Stormhaven.
- **Historical limitation:** The quest-system replacement temporarily disabled most existing quest givers and several quest chains while they awaited conversion.

## [14.2.2026]

- Quest item checks now include the six-slot quick inventory.
- Expanded support for separate quest turn-in NPCs, escorting, conversations, exploration, reputation goals, and investigations.
- Investigated random crashes; missing assets were corrected in the test map, but the broader cause remained uncertain.

## [13.2.2026]

- Improved quest-dialogue staging, character facing, and quest messages.
- Continued Stormhaven and Havenwoods terrain work.

## [10.2.2026]

- Expanded conversation sequences and Nazgrek's responses to trading, accepting or declining quests, following, stopping, and leaving. Further in-game checks remained necessary.

## [9.2.2026]

- Began rebuilding Aradion's quest interactions; dialogue, rewards, and several content details were still incomplete.

## [7.2.2026]

- Expanded Stormhaven and continued Havenwoods terrain work.
- Began a major quest-system overhaul, including requirements, rewards, quest markers, and clearer progress and failure messages.

## [4.2.2026]

- Investigated weather that failed to stop correctly; unresolved issues required returning to the earlier weather implementation.

## [1.2.2026]

- Corrected the recorded weather state when weather stops.
- Began Stormhaven terrain work.

## [24.1.2026]

- Varied thunder effects and made snow appear and disappear more gradually according to intensity.
- **Known issue at the time:** Storm fog could remain active after the storm ended.

## [23.1.2026]

- Continued terrain and vegetation work in Verdant Plains, Thornwoods, and Emberpeak Highlands.

## [22.1.2026]

- Continued zone-specific weather and fog setup in Twilight Grove and Sereneglade; restoring normal lighting after storms remained unresolved.

## [19.1.2026]

- Corrected nighttime zone settings and continued matching fog to active weather.

## [18.1.2026]

- Corrected zone effects to distinguish day and night more reliably.

## [17.1.2026]

- Added zone icons and continued Havenwoods and gnoll-camp scenery in Thornwoods and Sereneglade.
- Corrected a Crypt model associated with severe lag.

## [15.1.2026]

- Added clearer pet-level-up and hero-death announcements.
- Continued Havenwoods terrain work and investigation of casting-bar and storm-effect problems.

## [13.1.2026]

- Added sounds when opening and closing the enlarged minimap; minimap alignment work remained ongoing.
- Improved zone discovery and entry titles, sounds, and descriptions.
- Hid the zone panel during cinematics and improved hero-level-up presentation.
- Raised clouds to reduce clipping through terrain.

## [12.1.2026]

- Fixed zone-entry behavior interrupted by music transitions and improved fades between tracks.
- Continued correcting minimap alignment near map edges.

## [11.1.2026]

- Updated zone descriptions and lighting. Weather sounds, zone-entry feedback, and restoration after storms still required further work.

## [10.1.2026]

- Improved zone and dungeon activation and began a new zone-description panel and location-title presentation.

## [8.1.2026]

- Corrected minimap bounds, unreliable enlarged-map visibility, and Escape handling after chat.
- Refined localized storms and accompanying rain, and increased snow coverage in Twilight Grove, Sereneglade, Thornwoods, and Havenwoods.

## [7.1.2026]

- Isolated a camera-rotation/minimap interaction causing crashes and tested a safer minimap update.
- Adjusted clouds and snow duration and density according to weather intensity.
- Continued localized thunder, lightning, fog restoration, and terrain work in Deadwoods and Verdant Plains.

## [6.1.2026]

- Temporarily disabled the dynamic minimap and weather while investigating crashes after the introduction.
- Continued terrain work in Deadwoods, Vanguard Vale, and Verdant Plains.

## [5.1.2026]

- Corrected a minimap scaling mismatch that misplaced units relative to the world.

## [4.1.2026]

- Added rain ripples over water and adjusted cloud density by area size.
- Introduced a detailed minimap with local sections and an enlarged view; further testing was required.

## [3.1.2026]

- Fixed the wrong follower being assigned during Lumberjack Duties and corrected creature respawn exclusions.
- Began a broader seasonal weather system incorporating snow, clouds, and cold-weather breath effects.

## [1.1.2026]

- Improved follower handling for Mistaken Kin and Lumberjack Duties, and corrected Valeria's respawn allegiance.
- Investigated stalled patrol and pet movement during the introduction.

## [31.12.2025]

- Fixed a repeatable quest-failure dialogue choice in Ranger Missing.
- Adjusted Mistaken Kin's escort distance, enemy reactions, text, and ending positions.
- Continued investigating Chimairo's venom ability.

## [30.12.2025]

- Added a new escort-following behavior and expanded Ranger Missing's failure handling.
- Began improving item and equipment transfers during hero replacement or transformation.
- Cinematic revival handling still required fixes.

## [29.12.2025]

- Reworked casting bars and improved their visibility tracking.
- Continued correcting temporary cinematic revival and preservation of revival timers.
- Suppressed floating healing numbers for passive regeneration and continued quest-marker restoration work.

## [28.12.2025]

- Improved Crypt pathing and updated Vanguard Vale's sky.
- Expanded Valeria's combat abilities and companion revival support.
- Added revival-location pings and death/revival notifications; fixed companion status rows.
- Updated Chimairo's appearance and venom effects while continuing encounter work.
- Expanded quest failure and retry handling. Crypt performance issues remained unresolved.

## [27.12.2025]

- Improved character shading, dungeon portals, and Chimairo's appearance; its combat abilities remained in development.
- Corrected cleanup that could remove items stored in the custom bag.
- Continued Crypt and Vanguard Vale/Verdant Plains terrain work; Crypt lag remained under investigation.

## [24.12.2025]

- Added clearer markers for unavailable quests and continued Sirensong terrain work.
- Investigated Crypt entrance lag and inconsistent dark-area lighting.

## [12.12.2025]

- Continued Verdant Plains scenery work and dark-area lighting experiments.

## [7.12.2025]

- Continued Crypt interior repairs and lighting work; severe performance problems remained unresolved.

## [3.12.2025]

- Reworked Crypt entrance and interior geometry to reduce disappearing scenery. Missing walls, ceilings, and inconsistent lighting still needed follow-up.

## [30.11.2025]

- Quest markers now react to level and reputation requirements and disappear when a quest is unavailable.
- Continued Sirensong, Sereneglade, and Crypt scenery work.

## [16.11.2025]

- Investigated missing quest availability markers and tested alternative skies for several zones.

## [14.11.2025]

- Continued improving automatic quest availability and initial markers.

## [13.11.2025]

- Added automatic quest-availability checks for level, reputation, and event requirements, with distinct available and unavailable markers and fewer duplicate icons.

## [1.11.2025]

- Improved shared faction allegiances and restored dismissed AI companions to their original faction.

## [31.10.2025]

- The reputation display now shows temporary hostility and its remaining time.
- Companion abilities can affect eligible neutral units.
- Patrols now engage attackers without repeatedly stopping.

## [30.10.2025]

- Attacking friendly or neutral faction members can now make the faction temporarily hostile; companions follow the player's faction relations.
- Updated faction icons and continued companion allegiance and creature respawn work.
- Continued Vanguard Vale terrain work.

## [29.10.2025]

- Improved group patrol routes and added faction and standing icons.
- Faction relations now follow reputation more consistently.

## [27.10.2025]

- Fixed reputation changes failing after kills and corrected creature respawn settings. Group patrol movement still needed work.

## [26.10.2025]

- Items picked up in Ghost Wolf form now transfer back to the hero.
- Fixed bag stacks splitting into individual items after the first stack filled.
- Improved companion invitations, patrol respawning, and Elarindor creature respawns.
- Corrected quest-failure cleanup and character return positions.

## [25.10.2025]

- Adjusted spell-power bonuses for healing.
- Set the starting bag to twelve slots and added purchasable bag expansions.
- Fixed linked-faction reputation and missing standing-change messages.
- Added a wandering mountain giant near Redwind Pass and began an outcast-ogre encounter in Thornwoods.
- Improved patrol speed restoration and group patrol support.

## [24.10.2025]

- Fixed a healing-processing bug associated with severe lag spikes and reduced concentrated healing overhead.
- Corrected quest item checks that could consume the wrong hero's items.
- Refined reputation tiers and their effects on access to merchants and companions.
- Improved failed-quest dialogue and retry handling.

## [23.10.2025]

- Quest item searches and turn-ins now use both the custom bag and quick inventory, with safer charge removal.
- Totems no longer leave blood splats.
- Reduced severe periodic stat-processing lag.
- Corrected companion list cleanup, quest dialogue and progress checks, and continued Vanguard Vale terrain work.

## [22.10.2025]

- Fixed incorrect item removal, misleading charge counts, and checks for nonstacking quest items.
- Corrected quest titles, descriptions, dialogue, and companion staging.
- Cinematics no longer pull distant companions and pets into the scene.

## [19.10.2025]

- Fixed item loss during bag swaps, equipment transfers, and item stacking.
- Added mana-crystal mining with a chance of unstable crystals exploding.
- Continued Aradion and Valeria quest implementation and Vanguard Vale terrain work.
- Corrected encounter range checks and investigated a Crypt trap crash.

## [18.10.2025]

- Continued revising Vanguard Vale quest dialogue and Crypt trap behavior.

## [15.10.2025]

- Continued Crypt wall and trap work and Elarindor scenery.

## [14.10.2025]

- Continued Boom Brothers quest presentation and added the Mandatory Training instruction item.
- Removed misleading healing text and prevented newly tracked creatures from immediately gaining unintended levels.
- Tested Dragonpeaks fog.

## [13.10.2025]

- Increased damage taken while taming by 75% and corrected newly tamed pet registration.
- Continued fixing pet death animations, mineral-vein glow height, and Deadwoods terrain.

## [12.10.2025]

- Expanded creature-specific pet stat growth and initial pet-stat display.
- Began replacing the old bag follower with the custom inventory.
- Completed an introduction presentation pass and began updating Boom Brothers dialogue.
- World-unit hiding remained disabled because of lag and visibility problems.

## [11.10.2025]

- Corrected Shadowclaw's vulnerability when rejoining and expanded pet combat statistics and revival information.
- Pet experience processing remained broken during this development pass.

## [10.10.2025]

- Corrected premature resets during the Scorchion encounter.
- Expanded pet level-up stats and continued taming and pet-animation work.
- Continued Vanguard Vale terrain work; pet progression still needed testing.

## [9.10.2025]

- Corrected pet ownership focus, names, level display, and experience handling when joining or leaving the party.
- Restored Shadowclaw invitations and improved reputation tracking.
- Prepared faction reputation rewards for quests.

## [8.10.2025]

- Fixed missing pet experience gains and allowed Shadowclaw to rejoin when no other pet is active.
- Improved floating pet-death text and added Mordrax's defeat animation.
- Continued testing the revised reputation display.

## [7.10.2025]

- Fixed newly tamed pet registration and party displays; dismissed pets pause experience gains until rejoining.
- Updated Nazgrek's appearance, mineral-vein glow, and Mordrax combat dialogue.
- **Historical limitation:** Moving voices to external audio temporarily left many older conversations and cinematics without working sound.

## [6.10.2025]

- All tamed pets now recover after defeat instead of dying permanently; revival animations still needed refinement.
- Added pet level display and `/pet rename <name>`.
- Corrected companion and pet placement around cinematics.

## [5.10.2025]

- Began loot drops from breakable crates.
- Improved encounter patrol speeds and reduced unwanted quest-character movement.
- Continued cinematic party placement and terrain work in Vanguard Vale and Sirensong.

## [4.10.2025]

- Added Morthun as a wandering Verdant Plains miniboss.
- Continued experience and floating-text fixes, mineral-vein glow repairs, and Vanguard Vale terrain work.

## [3.10.2025]

- Continued experience and floating-text corrections and began improving party placement and restoration around cinematics.

## [2.10.2025]

- Reduced lag from floating spell-name text and continued correcting its presentation.

## [1.10.2025]

- Improved quest item counting and consumption for both heroes, including Grum's quests.
- Fixed quest minimap markers and prevented day/night changes from repeating zone-entry announcements.
- Continued Zul'kis inventory setup and music-transition performance work.

## [30.9.2025]

- Enabled automatic item stacking and improved equipment stat names, colors, and tooltips.
- Added flat and percentage Spell Power bonuses for damage and healing.
- Corrected Shield Block preventing 25% of damage when it should prevent 75%.
- Began pet experience progression and added glow effects to mineral veins.

## [29.9.2025]

- Fixed items disappearing when splitting stacks; split items move into the custom bag.
- Added stack limits and clearer equipment-slot and percentage-stat displays.
- Continued healing-bonus and music-transition work.

## [28.9.2025]

- Added item-stack splitting and improved quest item charge recognition.
- Suppressed inappropriate blood splats, loot drops, and regeneration text from noncombat effects.

## [27.9.2025]

- Fixed repeated Void Entity dialogue and Scorchion remaining invulnerable after an encounter reset.
- Improved boss recovery between attempts and quest progress recognition for collected items.

## [26.9.2025]

- Added encounter dialogue and corrected cinematic camera interference.
- Fixed an AI targeting problem associated with severe periodic lag.

## [25.9.2025]

- Disabled a conflicting item-stacking system and began further Void Entity encounter work.

## [23.9.2025]

- AI heroes now spawn after the introduction.
- Floating combat text no longer displays distant events outside the relevant view.
- Began custom equipment testing; severe AI-related slowdown was still under investigation.

## [22.9.2025]

- Continued inventory and equipment testing after correcting lag and pathing problems.
- Improved Valeria's quest behavior and post-quest patrol, added unit-level display, and continued Vanguard Vale terrain work.
- Music preloading remained incomplete.

## [21.9.2025]

- Expanded quest dialogue and restored extra inventory availability after cinematics.
- Continued investigating Stealth leaving the hero stuck in an attack animation.

## [20.9.2025]

- Improved quest cameras and character movement, expanded Valeria's side quests, and included pets in cinematic party placement.
- Stealth no longer breaks simply from standing close behind an enemy.
- Added terrain variation; extra inventory handling remained under test.

## [19.9.2025]

- Improved Grum's quest behavior and allowed incoming attacks to interrupt his dialogue.
- Added party-position restoration after cinematics and continued Ranger Missing dialogue and staging.
- Corrected creature respawns, updated Nazgrek's appearance, and continued Vanguard Vale terrain work.

## [18.9.2025]

- Removed an inventory prototype that broke the game during testing.
- Corrected Mana Wraith physical immunity accidentally affecting other creatures.
- Expanded quest dialogue and Nazgrek greetings.

## [17.9.2025]

- Renamed Lirael to Valeria and updated related dialogue.
- Continued item-stacking tests and physical-damage immunity for Mana Wraiths.

## [16.9.2025]

- Began more Vanguard Vale quest interactions and added Wretched creatures.
- Continued refining Mana Wraith defenses.
- Fixed Grum's dialogue playing when the player was far away.

## [15.9.2025]

- Expanded Mana Wraith abilities and Grum's encounter dialogue.
- Adjusted introduction setup timing.

## [12.9.2025]

- Added external zone music and `/music current` and `/music random` commands.
- Continued hero-death animation and introduction movement fixes.
- Updated Mana Wraith defenses and removed inappropriate blood effects.

## [10.9.2025]

- Removed unwanted drum sounds from creatures using the Kodo sound set.
- Began configuring destructible revival.

## [9.9.2025]

- Updated Grum's voiced dialogue and restored ship travel.
- Corrected Mordrax encounter resets and flight height.
- Investigated duplicate quest updates when collecting required items.

## [8.9.2025]

- Added dialogue-duration fallback when audio is unavailable.
- Corrected Grum's quest creation, adjusted drake attack frequency, and fixed quest text.
- Temporarily hid ship passengers while their onboard presentation was being corrected.

## [7.9.2025]

- Added Mordrax patrol and encounter behavior, updated whelp loot, and added Salamander combat sounds.
- Began external voice and ambience support.

## [6.9.2025]

- Continued Grum's encounter and quest progress work, added dragon-related drops, and adjusted nearby defender levels.
- Continued Thornwoods and Emberpeak Highlands terrain work and external music testing.

## [5.9.2025]

- Added Grum's voiced quest interactions and began cinematic ship-travel presentation.

## [4.9.2025]

- Improved ship routes, docking, speed, turning, and shipmaster dialogue.
- Corrected shovel appearance and mine explosion positioning.
- Improved goblin return behavior and continued Grum's quest development.

## [3.9.2025]

- Restored zone-entry messages in Twilight Grove and Sereneglade.
- Improved quest item recognition and handling of items left at recovery locations.
- Began ship-route rebuilding and added shipmasters and flight-point markers.

## [2.9.2025]

- Expanded Kribugs' quests and dialogue and corrected quest availability and item checks.
- Added obstacle checks to dialogue cameras.
- Continued mine encounters and interface sound work.

## [1.9.2025]

- Adjusted the death camera and item-recovery marker, expanded bounty rewards, and continued battle-wave and mine behavior fixes.

## [31.8.2025]

- Adjusted dialogue cameras and continued Boom Brothers Mine terrain work.

## [29.8.2025]

- Continued dialogue-camera and mine encounter work.
- Began interface sounds and zone ambience, including level-up and menu feedback; ambience cleanup still needed work.

## [27.8.2025]

- Continued dialogue- and death-camera adjustments and draft mine encounters; repeated encounter triggering still needed safeguards.

## [26.8.2025]

- Updated patrol behavior for Jin'Zun and Kribugs; an additional pass corrected patrols failing to stop when attacked or paused.
- Began reusable dialogue cameras, expanded Kribugs' quests and trading, and increased his movement speed.
- Dialogue selection, camera framing, death-camera control, and some sound behavior still needed fixes.

## [25.8.2025]

- Improved patrol pausing and resuming from the previous destination; broader testing remained necessary.

## [23.8.2025]

- Continued investigating patrol pause, stop, and incorrect-destination behavior.

## [22.8.2025]

- Began configurable NPC patrol routes; incorrect destinations still needed correction.
- Continued Boom Brothers Mine terrain and pathing work.

## [15.8.2025]

- Removed cold-breath effects from dying units and improved revival presentation.
- Set AI hero revival to sixty seconds and player hero revival to thirty seconds.
- Added a rotating death camera when no player hero remains active.
- Improved quest markers, escort following, mine cameras, and quest-completion choices.

## [14.8.2025]

- Corrected revival ability text and continued quest-marker and respawn handling work.
- **Known issues at the time:** Some quests updated twice, escorts stopped following, mine exit atmosphere failed to reset, and cold-breath effects persisted incorrectly.
- Continued investigating AI-related slowdown and day/night transitions.

## [13.8.2025]

- Improved quest text spacing and follow-up quest markers.
- Continued correcting turn-in states, zone-entry messages, and day/night atmosphere; several inconsistencies remained.

## [11.8.2025]

- Fixed Boom Brothers dialogue and following after quest completion, restored a missing completion choice, and improved mine movement.
- Corrected quest progress and availability markers and continued mine terrain work.

## [10.8.2025]

- Reworked quest icons and corrected bridge activation in Sirensong.
- Continued mine terrain work; quest-state display, escort behavior, and AI-related stuttering remained unresolved.

## [9.8.2025]

- Continued correcting quest markers after discovery and completion and consolidated quest reward handling.

## [8.8.2025]

- Began a unified quest-marker system; map-marker errors still prevented reliable use.

## [6.8.2025]

- Improved quest requirement formatting and prevented nonhero utility units from gaining experience after cinematics.

## [5.8.2025]

- Improved quest reward and completion text and mine quest staging.
- Added escort distance checks, Follow and Hold Position choices, and goblin combat assistance.
- Continued correcting mine cameras and return behavior; these changes still needed testing.

## [2.8.2025]

- Added support for item and Arena Mark quest rewards; reward descriptions still needed formatting work.

## [1.8.2025]

- Continued quest-reward testing and text cleanup.
- Narrowed major slowdown to AI activity, with some remaining performance spikes.

## [31.7.2025]

- Continued performance investigation, quest reward presentation, and mine terrain work.
- Corrected the wrong quest being discovered during Mandatory Training and attempted to fix its escort following.

## [30.7.2025]

- Improved Rogue, Warlock, and Warrior AI reactions to inventory changes, trading, and nighttime camping.

## [29.7.2025]

- Added healing-event support and reduced resource leaks in AI camping and shopping.
- Investigated duplicate experience notifications.

## [28.7.2025]

- Continued performance investigation and cleanup of weather, item, resource, and AI behavior; wandering hostile NPCs were temporarily disabled.

## [27.7.2025]

- Adjusted cinematic character allegiances to reduce unwanted attacks during scenes.
- Continued mine-related quest development.

## [26.7.2025]

- Continued dialogue and mine terrain work while investigating performance issues.

## [25.7.2025]

- Added coastal crabs, turtles, and a turtle miniboss with combat and death sounds.
- Continued Sirensong and Verdant Plains zone work, goblin quest dialogue, and the unfinished Boom Brothers Mine.

## [22.7.2025]

- Corrected several goblin quest dialogue and progression issues and continued the More Hazard Mitigation quest.

## [21.7.2025]

- Continued goblin quest progression and camera troubleshooting.
- Added combat sounds for big cats and deer and tested new skies.

## [20.7.2025]

- Fixed a moving quest giver becoming unavailable for conversation and expanded goblin follow-up quests.
- Continued Sirensong terrain, wildlife levels, and creature sounds.
- Planned a single-player focus with Zul'kis as a second controllable hero instead of a second human player.

## [19.7.2025]

- Corrected goblin quest selection and added unstable explosive barrels that can damage their carrier.
- Investigated NPC movement, camera locking after the Warcraft III update, and AI-related lag.

## [18.7.2025]

- Began restoring quest-giver interactions after respawn.
- Continued goblin dialogue and Sirensong terrain work.

## [10.7.2025]

- Began a goblin quest involving unstable explosives near an old mine.

## [6.7.2025]

- Improved blood effects, added big-cat and devilsaur boss variants, and continued Sirensong terrain work.

## [5.7.2025]

- Added ground blood effects for wounded and dying creatures.

## [4.7.2025]

- Continued southern Sirensong terrain and early undead encounter ability tests.
- Added low-health bleeding effects.

## [1.7.2025]

- Continued Sirensong coastal terrain and bridge adjustments.
- Improved floating spell-name text; cinematic camera input could still leave the camera stuck.

## [30.6.2025]

- Began floating spell-name and ability-level text; filtering and display details still needed work.
- Continued Sirensong development.

## [27.6.2025]

- Continued southern Sirensong coastal terrain work.

## [25.6.2025]

- Continued Sirensong coastal terrain work and investigation of black or flickering building textures and increasing gameplay lag.

## [24.6.2025]

- Investigated scenery-related crashes and persistent performance spikes, and adjusted a flying character model toward ground movement.

## [21.6.2025]

- Added creature and boss variants and continued Dragonfire Peaks and Sirensong scenery.
- Reverted a unit-visibility experiment that worsened lag. Texture problems and progressive slowdown remained under investigation.
