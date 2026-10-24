# Modern HUD original textures

These twelve textures were created specifically for Path of the Shaman and
then cropped, resized, and converted to RGBA TGA files for Warcraft III.

The shared art direction uses brutal hand-forged black iron, rawhide and dark
leather bindings, controlled bone/tusk fittings, muted Horde-red cloth,
angular orange-red runes, and restrained storm-blue shamanic energy:

- `PotSHUD.tga`: wide transparent bottom action-bar chassis with symmetrical
  outward-facing wolf-head endcaps, transparent runtime interior, iron rails,
  hide lashings, and small elemental accents,
  2048x512.
- `PotSActionSlot.tga`: transparent tusk-cornered action-slot bezel, 128x128.
- `PotSBarBack.tga`: dark leather and black-iron resource trough, 1024x64.
- `PotSBarFrame.tga`: transparent split-bar iron overlay with a central
  medallion opening, 1024x64.
- `PotSMedallion.tga`: Horde-styled four-element ring with no character
  artwork, 128x128.
- `PotSTotemEarth.tga`: clear ochre mountain/stone tracker badge, 128x128.
- `PotSTotemFire.tga`: clear ember-flame tracker badge, 128x128.
- `PotSTotemWater.tga`: clear three-wave tracker badge, 128x128.
- `PotSTotemAir.tga`: clear white-cyan wind tracker badge, 128x128.
- `PotSHealth.tga`: blood-red spirit-energy fill, 1024x64.
- `PotSMana.tga`: electric storm-blue energy fill, 1024x64.
- `PotSXP.tga`: burnt amber-orange spirit-energy fill, 1024x64.

They are loaded directly by `ModernPlayerHUD.j`,
`ModernAbilityActionBar.j`, `ModernTotemTracker.j`, and
`ModernMinimapHUD.j`; no TOC or FDF is required.

