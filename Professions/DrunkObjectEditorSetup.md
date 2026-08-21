# Drunk Object Editor setup

Create the integer array GUI variable `Stats_Drunk`. Its generated JASS name
must be `udg_Stats_Drunk[]`; `Drunk.j` treats values from 0 through 100 as the
authoritative MUI intoxication stat.

`Drunk.j` uses three map abilities for its visible status buffs:

- `S01M`: Drunk status aura. Base it on a hidden aura, target Self only, use a
  zero effective area, and assign the visible Drunk buff.
- `S01O`: Puking status aura. Base it on a hidden self-only aura and assign the
  visible Puking buff. Configure the buff tooltip to explain the hit and armor
  penalty; JASS applies the numeric penalty.
- `S01N`: Hangover status aura. Base it on a hidden self-only aura and assign
  the visible Hangover buff. The default JASS duration is five minutes.

Set all three abilities to zero mana cost, no command card position, no icon
command, and no acquisition targets beyond Self. `Drunk.j` hides abilities it
adds, so only their buffs should be visible.

Pass-out destinations are intentionally map-configured. Register preplaced
rects after map globals exist:

```jass
call Drunk_RegisterPassOutRect(gg_rct_HangoverWakeup01)
call Drunk_RegisterPassOutRect(gg_rct_HangoverWakeup02)
```

Warcraft III exposes no runtime animation-existence query. Sleep is the
default; register a fallback for models without it:

```jass
call Drunk_SetPassOutAnimation('H000', "death")
call Drunk_SetPassOutAnimation('O000', "decay")
```
