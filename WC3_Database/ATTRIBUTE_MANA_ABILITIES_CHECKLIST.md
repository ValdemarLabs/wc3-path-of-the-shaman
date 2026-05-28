# WC3 Item Stat Abilities Creation Checklist (Vanilla Inventory)

## Overview
For **vanilla WC3 inventory system**, items need invisible passive abilities for all stat bonuses. When a hero picks up an item, WC3 automatically applies the abilities. When dropped, abilities are removed.

**Total Abilities to Create: ~70+** (varies based on stat variety)

---

## 🎯 Stats Classification for Vanilla Inventory

### ✅ Already Complete (1-100% coverage via abilities)
- Hit Chance (1-100%) - A649-A64B series + existing
- Crit Chance (1-100%) - A64E-A64I series + existing
- Block Chance (1-100%) - A64J-A64N, A64T + existing
- Dodge/Evasion (1-100%) - A64O-A64S series + existing
- Spell Power (1-100%) - A06M-A06P + A6F1-A01E series

### ⚠️ NEEDS ABILITIES - Attribute Bonuses
**Base Ability Type**: Item Attribute Bonus (`AIxx`)
- **Strength 1-9** (7 abilities needed: 1, 3-7, 9)
- **Agility 1-9** (7 abilities needed: 1, 3-7, 9)
- **Intelligence 1-9** (7 abilities needed: 1, 3-7, 9)

### ⚠️ NEEDS ABILITIES - Resource Bonuses
**Base Ability Types**: Item Mana Bonus (`AImx`), Item Health Bonus (`AIhx`)
- **Mana +1 to +100** (5 abilities: 1, 5, 10, 25, 100)
- **HP +1 to +100** (varies - depends on your items)

### ⚠️ NEEDS ABILITIES - Offensive Stats
**Base Ability Types**: Various item abilities
- **Damage Bonus** (`AIat`) - flat damage (1-50+)
- **Attack Speed %** (`AIsx`) - attack speed bonus (1-50%)
- **Lifesteal %** (`AIsv`) - heal from damage (1-20%)
- **Critical Damage %** - requires custom ability (50-300%)

### ⚠️ NEEDS ABILITIES - Defensive Stats
**Base Ability Types**: Various item abilities
- **Armor Bonus** (`AIde`) - flat armor (1-20)
- **Movement Speed** (`AIms`) - flat MS bonus (10-100)
- **Movement Speed %** - requires custom or orb effect

### ℹ️ Stats Applied by Existing WC3 Abilities
Some stats use built-in item abilities:
- **Regeneration** - Item Regeneration ability
- **Mana Regeneration** - Item Mana Regeneration ability
- **Vision** - Item True Sight or Sight Range bonus

### ⚠️ Custom JASS Required (Not pure abilities)
These need detection systems:
- Cleave %, Cleave Area
- Thorns damage
- Damage % modifiers (melee/ranged/spell)
- Damage Taken modifiers
- HP/Mana Regen %

---

## 📊 Current Coverage Analysis

### Strength
- ✅ Existing: 15, 10, 8, 2
- ❌ **Missing: 1, 3, 4, 5, 6, 7, 9**
- **Create: 7 abilities**

### Agility
- ✅ Existing: 8, 2
- ❌ **Missing: 1, 3, 4, 5, 6, 7, 9**
- **Create: 7 abilities**

### Intelligence
- ✅ Existing: 20, 15, 8, 2
- ❌ **Missing: 1, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 16, 17, 18, 19**
- **Create: 16 abilities** (or just 1-9 for simplicity = 7 abilities)

### Mana
- ✅ Existing: 500, 250, 150, 50
- ❌ **Missing: 1, 5, 10, 25, 100**
- **Create: 5 abilities**

---

## 📝 Creation Checklist

### STRENGTH ABILITIES (7 new)
Base Ability: Item Attribute Bonus (`AIxx`)

- [ ] **Strength +1** - Code: _______ - Set Strength Bonus = 1
- [ ] **Strength +3** - Code: _______ - Set Strength Bonus = 3
- [ ] **Strength +4** - Code: _______ - Set Strength Bonus = 4
- [ ] **Strength +5** - Code: _______ - Set Strength Bonus = 5
- [ ] **Strength +6** - Code: _______ - Set Strength Bonus = 6
- [ ] **Strength +7** - Code: _______ - Set Strength Bonus = 7
- [ ] **Strength +9** - Code: _______ - Set Strength Bonus = 9

### AGILITY ABILITIES (7 new)
Base Ability: Item Attribute Bonus (`AIxx`)

- [ ] **Agility +1** - Code: _______ - Set Agility Bonus = 1
- [ ] **Agility +3** - Code: _______ - Set Agility Bonus = 3
- [ ] **Agility +4** - Code: _______ - Set Agility Bonus = 4
- [ ] **Agility +5** - Code: _______ - Set Agility Bonus = 5
- [ ] **Agility +6** - Code: _______ - Set Agility Bonus = 6
- [ ] **Agility +7** - Code: _______ - Set Agility Bonus = 7
- [ ] **Agility +9** - Code: _______ - Set Agility Bonus = 9

### INTELLIGENCE ABILITIES (7 new)
Base Ability: Item Attribute Bonus (`AIxx`)

- [ ] **Intelligence +1** - Code: _______ - Set Intelligence Bonus = 1
- [ ] **Intelligence +3** - Code: _______ - Set Intelligence Bonus = 3
- [ ] **Intelligence +4** - Code: _______ - Set Intelligence Bonus = 4
- [ ] **Intelligence +5** - Code: _______ - Set Intelligence Bonus = 5
- [ ] **Intelligence +6** - Code: _______ - Set Intelligence Bonus = 6
- [ ] **Intelligence +7** - Code: _______ - Set Intelligence Bonus = 7
- [ ] **Intelligence +9** - Code: _______ - Set Intelligence Bonus = 9

### MANA ABILITIES (5 new)
Base Ability: Item Mana Bonus (`AImx`)

- [ ] **Mana +1** - Code: _______ - Set Mana Bonus = 1
- [ ] **Mana +5** - Code: _______ - Set Mana Bonus = 5
- [ ] **Mana +10** - Code: _______ - Set Mana Bonus = 10
- [ ] **Mana +25** - Code: _______ - Set Mana Bonus = 25
- [ ] **Mana +100** - Code: _______ - Set Mana Bonus = 100

### HEALTH/HP ABILITIES (Optional - depends on item values)
Base Ability: Item Health Bonus (`AIhx` - rarely used, usually handled via Strength)

- [ ] **HP +10** - Code: _______ - Set HP Bonus = 10
- [ ] **HP +25** - Code: _______ - Set HP Bonus = 25**Item abilities**
2. **Find base ability** to use as template:
   - **Attributes**: Find Item Attribute Bonus (look for `AIxx` abilities or your existing A669)
   - **Mana**: Find Item Mana Bonus (`AImx`)
   - **HP**: Find Item Health Bonus (`AIhx`) or create from Item Attribute Bonus
   - **Damage**: Find Item Attack Bonus (`AIat`)
   - **Armor**: Find Item Defense Bonus (`AIde` or `AIdf`)
   - **Attack Speed**: Find Item Attack Speed Bonus (`AIsx`)
   - **Movement Speed**: Find Item Move Speed Bonus (`AIms`)
   - **Lifesteal**: Find Attack | Life Steal (`AIsv`)
   - **Regeneration**: Find Item Regeneration (`AIre`), Item Mana Regeneration (`AIrm`)
3. **Right-click** → Copy
4. **Right-click in list** → Paste
5. **Edit the new ability**:
   - Change **Name** field (e.g., "Item Bonus Damage +5")
   - Change **Stats/Combat** field values (e.g., Attack Bonus = 5)
   - Set **Art - Button Position (X)** = 0, **Art - Button Position (Y)** = 0 (hides icon)
   - Set **Data - Levels** = 1 (important!)
   - Note the 4-character **ability code** (e.g., A06Q)
6. **Repeat** for each ability
7. **Save map** and **export w3a** file

**Tip**: Copy existing abilities instead of creating from neutral abilities - keeps field structure consistent.Set Attack Bonus = 15
- [ ] **Damage +20** - Code: _______ - Set Attack Bonus = 20
- [ ] **Damage +25** - Code: _______ - Set Attack Bonus = 25
- [ ] **Damage +50** - Code: _______ - Set Attack Bonus = 50

### ARMOR ABILITIES (Recommended)
Base Ability: Item Defense Bonus (`AIde`)

- [ ] **Armor +1** - Code: _______ - Set Defense Bonus = 1
- [ ] **Armor +2** - Code: _______ - Set Defense Bonus = 2
- [ ] **Armor +3** - Code: _______ - Set Defense Bonus = 3
- [ ] **Armor +5** - Code: _______ - Set Defense Bonus = 5
- [ ] **Armor +10** - Code: _______ - Set Defense Bonus = 10
- [ ] **Armor +15** - Code: _______ - Set Defense Bonus = 15
- [ ] **Armor +20** - Code: _______ - Set Defense Bonus = 20

### ATTACK SPEED ABILITIES (Recommended)
Base Ability: Item Attack Speed Bonus (`AIsx`)

- [ ] **Attack Speed +1%** - Code: _______ - Set Attack Speed Increase = 0.01
- [ ] **Attack Speed +2%** - Code: _______ - Set Attack Speed Increase = 0.02
- [ ] **Attack Speed +3%** - Code: _______ - Set Attack Speed Increase = 0.03
- [ ] **Attack Speed +5%** - Code: _______ - Set Attack Speed Increase = 0.05
- [ ] **Attack Speed +10%** - Code: _______ - Set Attack Speed Increase = 0.10
- [ ] **Attack Speed +15%** - Code: _______ - Set Attack Speed Increase = 0.15
- [ ] **Attack Speed +20%** - Code: _______ - Set Attack Speed Increase = 0.20
- [ ] **Attack Speed +25%** - Code: _______ - Set Attack Speed Increase = 0.25
- [ ] **Attack Speed +50%** - Code: _______ - Set Attack Speed Increase = 0.50

### MOVEMENT SPEED ABILITIES (Recommended)
Base Ability: Item Move Speed Bonus (`AIms`)

- [ ] **Movement Speed +5** - Code: _______ - Set Movement Speed Bonus = 5
- [ ] **Movement Speed +10** - Code: _______ - Set Movement Speed Bonus = 10
- [ ] **Movement Speed +15** - Code: _______ - Set Movement Speed Bonus = 15
- [ ] **Movement Speed +20** - Code: _______ - Set Movement Speed Bonus = 20
- [ ] **Movement Speed +25** - Code: _______ - Set Movement Speed Bonus = 25
- [ ] **Movement Speed +50** - Code: _______ - Set Movement Speed Bonus = 50

### LIFESTEAL ABILITIES (If items use this stat)
Base Ability: Item Lifesteal (`AIsv` - Attack | Life Steal)

- [ ] **Lifesteal +1%** - Code: _______ - Set Life Steal Amount = 0.01
- [ ] **Lifesteal +2%** - Code: _______ - Set Life Steal Amount = 0.02
- [ ] **Lifesteal +3%** - Code: _______ - Set Life Steal Amount = 0.03
- [ ] **Lifesteal +5%** - Code: _______ - Set Life Steal Amount = 0.05
- [ ] **Lifesteal +10%** - Code: _______ - Set Life Steal Amount = 0.10
- [ ] **Lifesteal +15%** - Code: _______ - Set Life Steal Amount = 0.15
- [ ] **Lifesteal +20%** - Code: _______ - Set Life Steal Amount = 0.20

### HP/MANA REGENERATION ABILITIES (If items use these)
Base Abilities: Item Regeneration (`AIre`), Item Mana Regeneration (`AIrm`)

- [ ] **HP Regen +0.5** - Code: _______ - Set Hit Points Regenerated = 0.5
- [ ] **HP Regen +1** - Code: _______ - Set Hit Points Regenerated = 1
- [ ] **HP Regen +2** - Code: _______ - Set Hit Points Regenerated = 2
- [ ] **HP Regen +5** - Code: _______ - Set Hit Points Regenerated = 5
- [ ] **Mana Regen +0.5** - Code: _______ - Set Mana Regenerated = 0.5
- [ ] **Mana Regen +1** - Code: _______ - Set Mana Regenerated = 1
- [ ] **Mana Regen +2** - Code: _______ - Set Mana Regenerated = 2
- [ ] **Mana Regen +5** - Code: _______ - Set Mana Regenerated = 5

---

## 🔧 Creation Steps (WE Object Editor)

1. **Open World Editor** → F6 (Object Editor) → Abilities tab → Item abilities
2. **Find existing ability** to use as template:
   - For Str/Agi/Int: Find your existing A669 (Str +2) or similar
   - For Mana: Find your existing A644 (Mana +50) or similar
3. **Right-click** → Copy
4. **Right-click in list** → Paste
5. **Edit the new ability**:
   - Change **Name** field (e.g., "Item Bonus Strength +1")
   - Change **Stats - Bonus** field (e.g., set Strength Bonus to 1)
   - Ensure **Art - Button Position (X)** = 0 and **Art - Button Position (Y)** = 0 (makes icon hidden)
   - Note the 4-character **ability code** (e.g., A06Q)
6. **Repeat** for each ability
7. **Save map** and **export w3a** file

---

## 📤 After Creation

1. **Fill in ability codes** above (the 4-character codes like A06Q, A06R, etc.)
2. **Export w3a** from World Editor
3. **Import w3a** in ItemManager (📥 Import WC3 Abilities button)
4. **Update StatAbilityMapper.cs** with new ability codes
5. **Rebuild ItemManager**
6. **Test auto-generation** with items that need precise values (e.g., 13 Strength, 47 Mana)

---

## 💡 Extended Coverage (for building ANY value)

If you want to build ANY value efficiently:

### Intelligence Extended (Optional - 9 more abilities)
- [ ] Intelligence +10 - Code: _______
- [ ] Intelligence +11 - Code: _______
- [ ] Intelligence +12 - Code: _______
- [ ] Intelligence +13 - Code: _______
- [ ] Intelligence +14 - Code: _______
- [ ] Intelligence +16 - Code: _______
- [ ] Intelligence +17 - Code: _______
- [ ] Intelligence +18 - Code: _______
- [ ] Intelligence +19 - Code: _______
Phase 1 - Core Attributes (Required):**
- [ ] Strength abilities (7)
- [ ] Agility abilities (7)
- [ ] Intelligence abilities (7)
- [ ] Mana abilities (5)
- **Subtotal: 26 abilities**

**Phase 2 - Combat Stats (Recommended):**
- [ ] Damage abilities (9)
- [ ] Armor abilities (7)
- [ ] Attack Speed abilities (9)
- **Subtotal: 25 abilities**

**Phase 3 - Utility Stats (Recommended):**
- [ ] Movement Speed abilities (6)
- [ ] HP bonus abilities (4)
- **Subtotal: 10 abilities**

**Phase 4 - Advanced Stats (Optional):**
- [ ] Lifesteal abilities (7)
- [ ] HP Regen abilities (4)
- [ ] Mana Regen abilities (4)
- **Subtotal: 15 abilities**

**Integration:**
- [ ] Ability codes documented
- [ ] w3a exported and imported to database
- [ ] StatAbilityMapper.cs updated with all new abilities
- [ ] ItemManager rebuilt
- [ ] Auto-generation tested
- [ ] Test in-game: create item, add to hero inventory, verify stats apply

**Total Progress: 0/26 Phase 1** | 0/25 Phase 2 | 0/10 Phase 3 | 0/15 Phase 4

**Grand Total: ~76 abilities** (26 core + 50 extended
- **Optional Subtotal: 14 abilities**

**Integration:**
- [ ] Ability codes documented
- [ ] w3a exported and imported to database
- [ ] StatAbilityMapper.cs updated
- [ ] ItemManager rebuilt
- [ ] Auto-generation tested

**Total Progress: 0/26 core abilities created** (+0/14 optional)
