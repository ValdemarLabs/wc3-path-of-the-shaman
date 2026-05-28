# Auto-Generate Stats Feature

## Overview
The auto-generate stats button allows you to quickly create appropriate stats, abilities, and flavor text for items based on their **Class**, **Rarity**, **Item Level**, and **Power Level**.

## Location
**Stats & Bonuses** tab → Select **Power Level** dropdown → Click "🎲 Auto-Generate Stats" button

## Requirements
Before clicking the button, ensure:
1. **Item Class** is selected (e.g., Head Armor, Weapon)
2. **Rarity** is selected (e.g., Common, Legendary)
3. **Item Level** is set
4. **Power Level** is selected (Minimal to Godlike)

## Power Levels

### Minimal (0.3x multiplier)
- **Stats**: Reduced count (-1), very weak values
- **Use case**: Starter items, vendor trash
- **Abilities**: None
- **Flavor text**: None

### Weak (0.6x multiplier)
- **Stats**: Normal count, low values  
- **Use case**: Early game items
- **Abilities**: None
- **Flavor text**: None

### Normal (1.0x multiplier) - DEFAULT
- **Stats**: Standard count, balanced values
- **Use case**: Standard gameplay items
- **Abilities**: None
- **Flavor text**: None

### Strong (1.5x multiplier)
- **Stats**: +1 bonus stat, increased values
- **Use case**: Notable upgrades, quest rewards
- **Abilities**: 0-1 random abilities (Bash, Cleaving Attack, Devotion Aura, etc.)
- **Flavor text**: None

### Powerful (2.5x multiplier)
- **Stats**: +2 bonus stats, high values
- **Use case**: Epic encounters, raid loot
- **Abilities**: 1-2 random abilities
- **Flavor text**: Origin story ("Forged in the depths of ancient dragons", etc.)

### Godlike (5.0x multiplier)
- **Stats**: +4 bonus stats, extreme values, ALL resistances, movement speed
- **Use case**: Final bosses, campaign rewards, legendary artifacts
- **Abilities**: 2-3 random abilities
- **Flavor text**: Multi-line epic description with power warnings

## Algorithm

### Stat Count by Rarity
- **Common**: 2-3 stats (Minimal: 1-2)
- **Uncommon**: 3 stats (Minimal: 2)
- **Rare**: 4 stats
- **Epic**: 5 stats
- **Legendary**: 6+ stats

Plus bonus stats from Power Level.

### Combined Multipliers
```
final_multiplier = power_multiplier × rarity_multiplier × (1 + item_level / 100)
```

**Power Multipliers:**
- Minimal: 0.3x
- Weak: 0.6x
- Normal: 1.0x
- Strong: 1.5x
- Powerful: 2.5x
- Godlike: 5.0x

**Rarity Multipliers:**
- Common: 1.0x
- Uncommon: 1.5x
- Rare: 2.0x
- Epic: 3.0x
- Legendary: 4.5x

### Stat Selection by Item Type

#### Armor (Head, Chest, Legs, Feet, Hands, Shoulders, Bracers, Belt)
- **Primary**: HP (50 base), Armor (3 base)
- **Secondary**: Random attribute (Str, Agi, or Int)
- **Strong+**: +HP Regen, +Dodge
- **Epic/Legendary**: +MP Regen or Movement Speed
- **Godlike**: +ALL Elemental Resistances + Movement Speed

#### Weapons (1h Weapon, 2h Weapon, Stave)
- **Primary**: Damage (10 base)
- **Secondary**: Primary attribute (Str for melee, Int for staves)
- **Tertiary**: Attack Speed OR Critical Chance
- **Strong+**: +Critical Damage, +Lifesteal

#### Shields (Off Hand, Shield)
- **Primary**: Armor (5 base), HP (40 base)
- **Secondary**: Block chance
- **Strong+**: +HP Regen

#### Jewelry (Ring, Amulet, Neck, Trinket)
- **Balanced**: All attributes (Str, Agi, Int)
- **Uncommon+**: Special stat (Crit, Lifesteal, or Spell Power)
- **Powerful+**: +Mana, +Mana Regen
- **Godlike**: +Resistances

### Abilities (Strong/Powerful/Godlike only)

**Weapon Abilities:**
- Cleaving Attack
- Bash
- Critical Strike
- Orb of Fire/Lightning/Poison
- Life Drain
- Mana Break

**Armor Abilities:**
- Devotion Aura
- Endurance Aura
- Thorns
- Hardened Skin
- Spell Shield
- Evasion
- Unholy Aura
- Brilliance Aura

**Universal Abilities:**
- Vampiric Aura
- Trueshot Aura
- Command Aura
- Regeneration

### Flavor Text (Powerful/Godlike only)

**Powerful Origins:**
- "Forged in the depths of ancient dragons."
- "Blessed by the fallen gods."
- "Infused with the essence of eternal flames."
- "Wielded by the legendary titan kings."

**Godlike Warnings:**
- "Its power knows no bounds."
- "Reality bends to its will."
- "Legends speak of its terror."
- "None who face it survive."

## Example Output

### Minimal Common Ring (Level 50)
```
+2 Strength
+2 Agility
```

### Normal Legendary Head Armor (Level 340)
```
+686 Health
+41 Armor
+66 Strength
+19 HP Regen
+29 Fire Resistance
```

### Powerful Epic Two-Hand Weapon (Level 305)
```
Stats:
  +915 Damage       (10 × 2.5 × 3.0 × 4.05)
  +152 Strength     (5 × 2.5 × 3.0 × 4.05)
  +91 Attack Speed  (3 × 2.5 × 3.0 × 4.05)
  +91 Critical Damage
  +45 Lifesteal
  +45 HP Regen

Abilities:
  Cleaving Attack, Orb of Lightning

Description:
  "Forged in the depths of the void itself."
```

### Godlike Legendary Chest Armor (Level 500)
```
Stats:
  +2,250 Health
  +135 Armor
  +225 Strength
  +67 HP Regen
  +67 Dodge
  +67 MP Regen
  +101 Fire Resistance
  +101 Cold Resistance
  +101 Lightning Resistance
  +101 Poison Resistance
  +67 Movement Speed

Abilities:
  Devotion Aura, Thorns, Brilliance Aura

Description:
  "Sacred relic of the celestial realm. Reality bends to its will."
```

## Workflow
1. Fill in **Basic Info**: Name, Class, Rarity
2. Item Level auto-sets to minimum
3. Select **Power Level** from dropdown (default: Normal)
4. Navigate to **Stats & Bonuses** tab
5. Click **🎲 Auto-Generate Stats**
6. Confirm replacement if stats already exist
7. Review generated:
   - Stats in the picker grid
   - Abilities in Abilities field (if applicable)
   - Flavor text in Description field (if applicable)
8. Customize as needed using stat picker controls
9. Save item

## Customization After Generation
- **Remove** unwanted stats using ❌ button
- **Reorder** using ↑ ↓ buttons
- **Add more** using the stat picker dropdown
- **Edit values** directly in the grid
- **Modify abilities** in the Abilities text field
- **Edit flavor text** in the Description field

## Tips & Best Practices

### Power Level Selection Guide
- **Minimal**: Consumables, temporary buffs, level 1-10 items
- **Weak**: Common drops, level 10-50 items
- **Normal**: Standard gameplay, level 50-200 items
- **Strong**: Boss drops, level 200-300 items
- **Powerful**: Raid bosses, level 300-400 items
- **Godlike**: Final bosses, campaign completion, max level content

### Balance Considerations
- **Testing**: Always test Godlike items in-game to ensure they don't break balance
- **Progression**: Use power levels to create clear item progression tiers
- **Abilities**: Check that generated abilities work with your item system
- **Stacking**: Multiple Godlike items might create overpowered combinations

### Performance Impact
- Each generation creates unique combinations using randomization
- Clicking multiple times creates different stat/ability combinations
- Abilities are appended if the field already has content

## Integration with Other Features
- Works with **Item Level Ranges**: Level validated before generation
- Compatible with **Unit Level Mappings**: Generate after selecting unit level range
- Outputs to **WC3 Tooltips**: Stats/abilities appear in proper WC3 format
- Supports **Stat Reordering**: Generated stats maintain custom sort order
- Exports to **W3T**: All generated data included in export files

## Technical Details

### Randomization
- Uses `System.Random()` for variety
- Each click generates different combinations
- Abilities selected randomly from appropriate pools
- Flavor text combines random prefixes and suffixes

### Text Field Handling
- **Abilities**: Appends to existing content with comma separator
- **Description**: Appends to existing content with space separator
- **Empty fields**: Replaces with new content
- **Duplicate prevention**: Uses `.Distinct()` for abilities

### Stat Calculations
All values rounded to nearest integer using `(int)` cast.
Base values scaled by: Power × Rarity × (1 + Level/100)
