# Power Level Comparison Guide

## Quick Reference Table

| Power Level | Multiplier | Bonus Stats | Abilities | Flavor Text | Use Case |
|-------------|-----------|-------------|-----------|-------------|----------|
| **Minimal** | 0.3x | -1 | None | None | Vendor trash, consumables |
| **Weak** | 0.6x | 0 | None | None | Early game drops |
| **Normal** | 1.0x | 0 | None | None | Standard gameplay |
| **Strong** | 1.5x | +1 | 0-1 | None | Boss drops, quest rewards |
| **Powerful** | 2.5x | +2 | 1-2 | Origin | Raid loot, epic encounters |
| **Godlike** | 5.0x | +4 | 2-3 | Epic multi-line | Final bosses, campaign end |

## Same Item at Different Power Levels

**Example: Epic Two-Hand Weapon, Item Level 300**

### Minimal (0.3x)
```
Stats (2 total):
  +36 Damage
  +18 Strength

Abilities: None
Description: (empty)

Total Power: ~54 stat points
```

### Weak (0.6x)
```
Stats (3 total):
  +73 Damage
  +36 Strength
  +21 Attack Speed

Abilities: None
Description: (empty)

Total Power: ~130 stat points
```

### Normal (1.0x) - DEFAULT
```
Stats (3 total):
  +122 Damage
  +60 Strength
  +36 Attack Speed

Abilities: None
Description: (empty)

Total Power: ~218 stat points
```

### Strong (1.5x)
```
Stats (4 total):
  +183 Damage
  +91 Strength
  +54 Attack Speed
  +54 Critical Damage

Abilities: Cleaving Attack

Description: (empty)

Total Power: ~382 stat points
```

### Powerful (2.5x)
```
Stats (5 total):
  +305 Damage
  +152 Strength
  +91 Attack Speed
  +91 Critical Damage
  +45 Lifesteal

Abilities: Bash, Orb of Lightning

Description: "Forged in the depths of ancient dragons."

Total Power: ~684 stat points
```

### Godlike (5.0x)
```
Stats (11 total):
  +610 Damage
  +305 Strength
  +183 Attack Speed
  +183 Critical Damage
  +91 Lifesteal
  +91 HP Regen
  +101 Fire Resistance
  +101 Cold Resistance
  +101 Lightning Resistance
  +101 Poison Resistance
  +91 Movement Speed

Abilities: Critical Strike, Life Drain, Vampiric Aura

Description: "Wielded by the legendary titan kings. Reality bends to its will."

Total Power: ~1,958 stat points
```

## Power Scaling Comparison

### Level 1 vs Level 500 (Normal Power)

**Common Ring, Level 1:**
```
+3 Strength
+3 Agility
+3 Intelligence

Total: 9 stat points
```

**Common Ring, Level 500:**
```
+18 Strength
+18 Agility
+18 Intelligence

Total: 54 stat points (6x stronger)
```

### Rarity Comparison at Level 300 (Normal Power)

**Common Chest Armor:**
```
+200 Health
+12 Armor
+20 Strength

Total: 3 stats, ~232 effective points
```

**Legendary Chest Armor:**
```
+900 Health
+54 Armor
+90 Strength
+27 HP Regen
+40 Fire Resistance

Total: 5 stats, ~1,111 effective points (4.5x stronger)
```

### The "Godlike" Difference

**Normal Legendary vs Godlike Legendary (Level 300)**

**Normal:**
- 5-6 stats
- Standard values
- No abilities
- No flavor text
- Total multiplier: 4.5x (rarity only)

**Godlike:**
- 9-10 stats
- MASSIVE values
- 2-3 powerful abilities
- Epic flavor text
- Total multiplier: 22.5x (4.5 rarity × 5.0 power)
- +ALL resistances guaranteed
- +Movement Speed guaranteed

## Recommended Usage by Content Type

### Campaign Progression
- **Act 1 (Levels 1-100)**: Minimal → Weak
- **Act 2 (Levels 101-200)**: Weak → Normal
- **Act 3 (Levels 201-300)**: Normal → Strong
- **Act 4 (Levels 301-400)**: Strong → Powerful
- **Final Boss (Level 500)**: Godlike

### Drop Rates Suggestion
- **Minimal**: 40% of drops
- **Weak**: 35% of drops
- **Normal**: 20% of drops
- **Strong**: 4% of drops
- **Powerful**: 0.9% of drops
- **Godlike**: 0.1% of drops (unique bosses only)

### Quest Rewards by Difficulty
- **Tutorial Quests**: Minimal
- **Side Quests**: Weak - Normal
- **Main Quests**: Normal - Strong
- **Epic Quests**: Strong - Powerful
- **Legendary Quests**: Godlike

## Multiplier Stacking Examples

### Combined Multiplier Formula
```
final = power_mult × rarity_mult × (1 + level/100)
```

**Godlike Legendary Level 500:**
```
5.0 × 4.5 × (1 + 500/100) = 5.0 × 4.5 × 6.0 = 135x base value
```

**Minimal Common Level 1:**
```
0.3 × 1.0 × (1 + 1/100) = 0.3 × 1.0 × 1.01 = 0.303x base value
```

**Power Difference:** Godlike Legendary is **445x stronger** than Minimal Common!

## Testing Recommendations

### Balance Testing Checklist
- [ ] Minimal items feel weak but usable for level 1-10
- [ ] Normal items appropriate for intended level range
- [ ] Strong items noticeable upgrade over Normal
- [ ] Powerful items feel "epic" but not game-breaking
- [ ] Godlike items powerful enough to be memorable
- [ ] No power level allows trivializing content
- [ ] Abilities on Strong+ items trigger correctly
- [ ] Flavor text displays properly in tooltips

### Common Issues
1. **Godlike Too Weak**: Increase base stat values or add more bonus stats
2. **Minimal Too Strong**: Check if level scaling is too aggressive
3. **Abilities Not Working**: Verify WC3 ability codes match your map
4. **Text Overflow**: Reduce flavor text length for narrow tooltips
5. **Balance Broken**: Consider reducing Godlike multiplier to 3.5x or 4.0x

## Advanced: Custom Power Levels

If you want to add custom power levels, modify the `powerMultiplier` switch statement:

```csharp
decimal powerMultiplier = powerLevel switch
{
    "Minimal" => 0.3m,
    "Weak" => 0.6m,
    "Normal" => 1.0m,
    "Strong" => 1.5m,
    "Powerful" => 2.5m,
    "Godlike" => 5.0m,
    "CUSTOM" => 10.0m,  // Add your custom level here
    _ => 1.0m
};
```

Then add "CUSTOM" to the dropdown items in `SetupStatsTab()`.
