# Modern HUD original textures

These twelve textures were created specifically for Path of the Shaman and
then cropped, resized, and converted to RGBA TGA files for Warcraft III.

The shared art direction uses blackened iron, aged bronze, charcoal stone,
leather bindings, and restrained elemental turquoise:

- `PotSHUD.tga`: simplified wide bottom action-bar shell, 2048x256.
- `PotSActionSlot.tga`: simplified transparent ability-slot bezel, 128x128.
- `PotSBarBack.tga`: dark resource-bar trough, 1024x64.
- `PotSBarFrame.tga`: restrained transparent split-bar overlay, 1024x64.
- `PotSMedallion.tga`: four-element ring with no character artwork and a
  transparent center, 128x128.
- `PotSTotemEarth.tga`: clear ochre mountain/stone tracker badge, 128x128.
- `PotSTotemFire.tga`: clear ember-flame tracker badge, 128x128.
- `PotSTotemWater.tga`: clear three-wave tracker badge, 128x128.
- `PotSTotemAir.tga`: clear white-cyan wind tracker badge, 128x128.
- `PotSHealth.tga`: red spirit-energy fill, 1024x64.
- `PotSMana.tga`: blue water/storm-energy fill, 1024x64.
- `PotSXP.tga`: thin amber/turquoise spirit-energy fill, 2048x32.

They are loaded directly by `ModernPlayerHUD.j`,
`ModernAbilityActionBar.j`, and `ModernTotemTracker.j`; no TOC or FDF is
required.

