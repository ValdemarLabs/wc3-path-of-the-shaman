# Companions / Pets JASS Migration To-Do

Last updated: 2.7.2026

This note tracks what was moved from the old GUI companion/pet triggers into `Companions.j` and `Pet.j`, what GUI state still remains intentionally shared, and what should wait for later AI and StatsBoard work.

## GUI Variables Still Used

These are still shared with old GUI systems or other JASS systems and should not be removed yet.

Companion party state:
- `udg_Companion_Group`
- `udg_CompanionFocusNazgrek`
- `udg_CompanionFocusZulkis`
- `udg_CompanionCount`
- `udg_CompanionUnit[]`
- `udg_CompanionIndex[]`
- `udg_CompanionIcon[]`
- `udg_Companion_GroupSize`
- `udg_CompanionUnitKicked`
- `udg_CompanionHiredUnitLevel[]`

Pet state:
- `udg_TamedUnits`
- `udg_TamedUnit`
- `udg_Shadowclaw`
- `udg_Pet_Dead`
- `udg_Pet_DeathPoint`
- `udg_ReviveTimerPet`
- `udg_TamedUnitKillCount`
- `udg_TamedUnitDeathCount`
- `udg_Pet_Renamed[]`
- `udg_Shadowclaw_hp_base`
- `udg_Shadowclaw_armor_base`
- `udg_Shadowclaw_dmg_base`
- `udg_Shadowclaw_hp`
- `udg_Shadowclaw_armor`
- `udg_Shadowclaw_dmg`

Tame Beast channel state:
- `udg_TM_Value`
- `udg_TM_Timer`
- `udg_TM_TimerFinished`
- `udg_Pet_Tamer[]`
- `udg_Pet_TamerChanneling[]`
- `udg_UDexUnits[]`

Shared map/system state:
- `udg_Nazgrek`
- `udg_Zulkis`
- `udg_Valeria`
- `udg_Aradion`
- `udg_InCinematic`
- `udg_IsUnitAlive[]`
- `udg_UnitMoving[]`
- `udg_GCSM_UnitInCombat[]`
- `udg_CompanionDialogueActive`
- `udg_CompanionUnitIdle[]`
- `udg_Stats_Hit[]`
- `udg_Stats_Crit[]`
- `udg_Stats_Dodge[]`
- `udg_Stats_Block[]`
- `udg_Stats_SpellPowerPct[]`
- `udg_Stats_SpellPowerFlat[]`
- `udg_UnitHider_ReferenceUnits[]`
- `udg_DamageEventTarget`
- `udg_DamageEventAmount`
- `gg_snd_GoodJob`
- `gg_snd_Rescue`
- `gg_snd_UpkeepRing`
- `gg_snd_Devour`
- `gg_rct_NazgrekIntroPoint`

Old multiboard hooks still called until `StatsBoardUI.j` replaces them:
- `gg_trg_MultiboardUpdate_Add_Companion`
- `gg_trg_MultiboardUpdate_Remove_Companion`
- `gg_trg_MultiboardUpdate_Add_Tamed`
- `gg_trg_MultiboardUpdate_Remove_Tamed`

## GUI Triggers That Can Be Disabled Now

Disable these old GUI triggers to avoid double orders, double add/remove, or duplicate pet state changes. Their core gameplay logic is now owned by `Companions.j` or `Pet.j`.

Companion control and follow state:
- `Companion Passive Mode` -Disabled 2.7.2026
- `Companion Passive Mode Active` -Disabled 2.7.2026
- `Companion Normal Mode` -Disabled 2.7.2026
- `Companion Normal Mode Active` -Disabled 2.7.2026
- `Companion Aggressive Mode` -Disabled 2.7.2026
- `Companion Aggressive Mode Active` -Disabled 2.7.2026
- `Companion Hold Position` -Disabled 2.7.2026
- `Companion Focus Set` -Disabled 2.7.2026

Companion add/remove and hired units:
- `Horde AI Companion Invite` -Disabled 2.7.2026
- `Horde AI Companion Kick` -Disabled 2.7.2026
- `Party Other Companion Invite` -Disabled 2.7.2026
- `Party Other Companion Dies` -Disabled 2.7.2026

Companion utility commands:
- `Companion Information` -Disabled 2.7.2026
- `Companion Idle or Move` -Disabled 2.7.2026
- `Companion Drop Items` -Disabled 2.7.2026

Pet and tame flow:
- `Shadowclaw Init` -Disabled 2.7.2026
- `Tame Beast I Start` -Disabled 2.7.2026
- `Tame Beast I Timer` -Disabled 2.7.2026
- `Tame Beast I Stop` -Disabled 2.7.2026
- `Tame Beast I Finish` -Disabled 2.7.2026
- `Tame Beast ExtraDmg` -Disabled 2.7.2026
- `Tame Beast Rename` -Disabled 2.7.2026
- `Tamed Unit Dies` -Disabled 2.7.2026
- `Tamed Unit Revival` -Disabled 2.7.2026
- `Tamed Unit Heal Event and items` -Disabled 2.7.2026

Notes:
- `Tame Beast II` and `Tame Beast III` were empty GUI exports. `Pet.j` now handles their ability rawcodes as higher-rank tame spells.
- The old Shadowclaw invite/kick branches inside `Horde AI Companion Invite` and `Horde AI Companion Kick` are handled by `Pet.j`.
- The old active mode triggers should stay disabled once the JASS libraries are active because `Companions.j` now owns companion/pet mode application and calls `FollowSystem.j` as the low-level follow-order helper.
- `FollowSystem.j` is not full companion AI parity by itself. Quest escort or strict-close-follow NPCs can use it directly, while normal companions/pets still need `Companions.j` for selected-unit mode control, combat posture, focus, idle/wander state, information output, and shared GUI globals.
- `Companion Idle or Move` chat calls are intentionally not ported here; only the idle/wander state maintenance was moved.

## GUI Triggers To Keep For Now

Keep these until their owning system is migrated.

- `Hired Units Init Shops`
  Shop stock/setup was not moved into `Companions.j`.
- `MultiboardUpdate Add Companion`
- `MultiboardUpdate Remove Companion`
- `MultiboardUpdate Add Tamed`
- `MultiboardUpdate Remove Tamed`
- Other old multiboard update triggers under `UI/MultiboardGUI`
  These stay until the later `StatsBoardUI.j` rewrite replaces the old GUI multiboard. `StatsBoardUI.j` may imitate the old multiboard data layout or move to frames, but that is separate work.
- `Horde NPC Chat ...` triggers
  These should move with the larger AI library update, not into `Companions.j` or `Pet.j`.

## Not Ported / Still To Do

AI and companion chatter:
- Move companion/pet bark selection to the future AI libraries.
- Old trigger-side chat calls were not copied: greet, passive, normal, aggressive, hold position, kick, drop items, idle, and moving barks.
- Old GUI variables like `Companion_Group_ChatUnit` and `PartyKickVoice` are not used by the new libraries.

Stats board / old multiboard:
- Replace the old multiboard triggers with `StatsBoardUI.j`.
- Decide whether `StatsBoardUI.j` consumes the existing `udg_CompanionUnit[]`, `udg_CompanionIcon[]`, `udg_CompanionIndex[]`, `udg_TamedUnit`, and pet kill/death globals, or whether it gets a cleaner JASS API.
- After `StatsBoardUI.j` is active, remove direct calls to `gg_trg_MultiboardUpdate_Add_Companion`, `gg_trg_MultiboardUpdate_Remove_Companion`, `gg_trg_MultiboardUpdate_Add_Tamed`, and `gg_trg_MultiboardUpdate_Remove_Tamed`.

Behavior parity checks:
- Validate that Passive, Normal, Aggressive, and Hold Position feel correct through `Companions.j`. The old GUI active triggers used periodic follow/right-click/attack-move orders; the new implementation applies mode selection in `Companions.j` and delegates low-level follow orders to `FollowSystem.j`.
- Validate the new selected-unit mode behavior: selected companion/pet gets the mode alone; no selected controlled unit applies the mode to the full companion/pet group.
- Validate the rebuilt `Companion Idle or Move` behavior in-game. `Companions.j` now adds/removes `Wander (Neutral)` and updates `udg_CompanionUnitIdle[]`; it also fixes the old GUI branch that cleared `CompanionUnitIdle[0]` instead of the picked unit custom value. Idle and moving chat barks still belong to the later AI library migration.
- Validate the rebuilt `Companion Information` output in-game. `Companions.j` now restores the old name/type/attack/faction/stats/abilities categories and adds current mode/focus/life/mana/damage/armor. Exact long ability description text was not restored because the old GUI export only preserves those lines in truncated form.
- Validate hired unit rawcodes and icon/level mappings in-game.

Pet-specific follow-up:
- Confirm the intended differences for `Tame Beast II` and `Tame Beast III`; old GUI files were empty, so the current JASS implementation uses higher tame-level caps.
- Confirm whether tame-channeling damage should also set a custom critical/feedback damage type. `Pet.j` currently preserves the old 1.75 damage multiplier but does not set the old `DamageTypeCriticalStrike` GUI value.
- Confirm whether `udg_UnitHider_ReferenceGroup` still needs pet additions. The new libraries update `udg_UnitHider_ReferenceUnits[]`, but the old tame finish trigger also added the tamed beast to a UnitHider reference group.
- Re-test Shadowclaw kick/reinvite, including the move back to `NazgrekIntroPoint`.
- Re-test pet fatigue/revive timing and old multiboard display while `ReviveTimerPet` is running.

Build/test follow-up:
- Run a full map compile once the generated map globals are available in the active build pipeline.
- In-game test all migrated spell rawcodes:
  `A622`, `A621`, `A61Z`, `A61X`, `A61S`, `A6DX`, `A6E9`, `A6DZ`, `A6E4`, `A6E5`, `A623`, `A625`, `A627`.
