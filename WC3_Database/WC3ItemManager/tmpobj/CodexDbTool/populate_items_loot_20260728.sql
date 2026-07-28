CREATE TEMP TABLE codex_item_seed (
    item_code varchar(4) PRIMARY KEY,
    item_name text NOT NULL,
    type_id integer NOT NULL,
    rarity_id integer NOT NULL,
    class_id integer NOT NULL,
    item_level integer NOT NULL,
    item_level_unclassified integer,
    required_level integer NOT NULL,
    max_charges integer NOT NULL,
    max_stack integer NOT NULL,
    gold_cost integer NOT NULL,
    sell_value integer NOT NULL,
    icon_path text,
    model_path text,
    tooltip text,
    tooltip_body text,
    flavor text,
    base_id varchar(4) NOT NULL,
    wc3_classification text,
    wc3_abilities text,
    armor_type text,
    equipment_slot text,
    specific_drop_only boolean NOT NULL DEFAULT false
) ON COMMIT DROP;

INSERT INTO codex_item_seed (
    item_code, item_name, type_id, rarity_id, class_id, item_level, item_level_unclassified,
    required_level, max_charges, max_stack, gold_cost, sell_value, icon_path, model_path,
    tooltip, tooltip_body, flavor, base_id, wc3_classification, wc3_abilities,
    armor_type, equipment_slot, specific_drop_only
) VALUES
    ('j0a0', '|c009D9D9DFrayed Wolf Pelt|r', 6, 1, 60, 5, 5, 1, 1, 10, 12, 2, 'ReplaceableTextures\CommandButtons\BTNNagaArmorUp2.blp', 'war3campImported\D_Skin_WolfTimber.mdl', 'Frayed Wolf Pelt', '|cffC0C0C0Material|r|nA ragged strip of pelt useful for crude stitching.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a1', '|c009D9D9DCracked Boar Tusk|r', 7, 1, 23, 5, 5, 1, 1, 10, 9, 1, 'ReplaceableTextures\CommandButtons\BTNOrcMeleeUpOne.blp', NULL, 'Cracked Boar Tusk', '|cffC0C0C0Junk|r|nSplintered but still sharp enough to fetch a few coins.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0a2', '|c009D9D9DPolished Stag Antler|r', 6, 1, 60, 5, 5, 1, 1, 10, 18, 3, 'ReplaceableTextures\CommandButtons\BTNStag.blp', NULL, 'Polished Stag Antler', '|cffC0C0C0Material|r|nNaturally smooth antler prized by carvers and fletchers.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a3', '|c001EFF00Bear Grease|r', 6, 2, 60, 10, 10, 1, 1, 10, 45, 8, 'ReplaceableTextures\CommandButtons\BTNPotionOfOmniscience.blp', 'war3campImported\ITEMPotionGreenSmall.mdl', 'Bear Grease', '|cffC0C0C0Material|r|nA thick rendered fat used in salves and waterproofing.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a4', '|c009D9D9DGnoll Coin Pouch|r', 7, 1, 23, 5, 5, 1, 1, 5, 24, 5, 'ReplaceableTextures\CommandButtons\BTNChestOfGold.blp', 'Doodads\Dungeon\Props\JunkPile\JunkPile0.mdl', 'Gnoll Coin Pouch', '|cffC0C0C0Junk|r|nA greasy pouch with a few mismatched coins inside.', NULL, 'bzbe', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0a5', '|c009D9D9DBent Gnoll Dagger|r', 7, 1, 23, 6, 6, 1, 1, 5, 32, 6, 'ReplaceableTextures\CommandButtons\BTNDaggerOfEscape.blp', 'war3campImported\ITEMDaggerOfEscape.mdl', 'Bent Gnoll Dagger', '|cffC0C0C0Junk|r|nA warped blade with more threat than edge.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0a6', '|c009D9D9DMurloc Gill Slime|r', 6, 1, 60, 6, 6, 1, 1, 10, 20, 4, 'ReplaceableTextures\CommandButtons\BTNMurloc.blp', 'Abilities\Weapons\BansheeMissile\BansheeMissile.mdl', 'Murloc Gill Slime', '|cffC0C0C0Material|r|nA slick reagent that refuses to dry.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a7', '|c001EFF00Briny Murloc Scale|r', 6, 2, 60, 10, 10, 1, 1, 10, 60, 10, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp', 'war3campImported\D_Skin_LizardGreen.mdl', 'Briny Murloc Scale', '|cffC0C0C0Material|r|nA salt-crusted scale with a faint sea-glow.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a8', '|c001EFF00Makrura Chitin Plate|r', 6, 2, 60, 10, 10, 1, 1, 10, 75, 12, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp', 'war3campImported\ITEMCrate.mdl', 'Makrura Chitin Plate', '|cffC0C0C0Material|r|nHard chitin suitable for armor reinforcement.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0a9', '|c009D9D9DMakrura Claw|r', 7, 1, 23, 8, 8, 1, 1, 5, 36, 6, 'ReplaceableTextures\CommandButtons\BTNClawsOfAttack.blp', 'war3campImported\ITEMClawsOfAttack.mdl', 'Makrura Claw', '|cffC0C0C0Junk|r|nHeavy, serrated, and still smelling of tidewater.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0b0', '|c009D9D9DShed Snake Scale|r', 6, 1, 60, 5, 5, 1, 1, 10, 15, 3, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp', NULL, 'Shed Snake Scale', '|cffC0C0C0Material|r|nThin scale-skin that shimmers in firelight.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b1', '|c001EFF00Clouded Venom Fang|r', 6, 2, 60, 12, 12, 1, 1, 10, 90, 15, 'ReplaceableTextures\CommandButtons\BTNOrbOfVenom.blp', NULL, 'Clouded Venom Fang', '|cffC0C0C0Material|r|nThe venom has dulled, but alchemists can wake it again.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b2', '|c009D9D9DSticky Frog Mucus|r', 6, 1, 60, 5, 5, 1, 1, 10, 14, 2, 'ReplaceableTextures\CommandButtons\BTNCorrosiveBreath.blp', 'Abilities\Weapons\BansheeMissile\BansheeMissile.mdl', 'Sticky Frog Mucus', '|cffC0C0C0Material|r|nA clingy glob used in simple adhesives.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b3', '|c009D9D9DGlassy Frog Eye|r', 7, 1, 23, 5, 5, 1, 1, 5, 18, 3, 'ReplaceableTextures\CommandButtons\BTNGem.blp', NULL, 'Glassy Frog Eye', '|cffC0C0C0Junk|r|nIt seems to stare no matter where it lands.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0b4', '|c009D9D9DCracked Crawler Shell|r', 6, 1, 60, 6, 6, 1, 1, 10, 22, 4, 'ReplaceableTextures\CommandButtons\BTNCryptFiendCarapace.blp', NULL, 'Cracked Crawler Shell', '|cffC0C0C0Material|r|nBrittle shell that can still be ground into tempering grit.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b5', '|c001EFF00Sea-Salt Gland|r', 6, 2, 60, 10, 10, 1, 1, 10, 70, 12, 'ReplaceableTextures\CommandButtons\BTNNeutralManaShield.blp', NULL, 'Sea-Salt Gland', '|cffC0C0C0Material|r|nA mineral-rich gland from a shore crawler.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b6', '|c001EFF00Charred Whelp Horn|r', 6, 2, 60, 15, 15, 1, 1, 10, 110, 18, 'ReplaceableTextures\CommandButtons\BTNAdvancedCreatureCarapace.blp', NULL, 'Charred Whelp Horn', '|cffC0C0C0Material|r|nBlackened horn carrying a faint ember scent.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b7', '|c000070DDEmber-Warmed Scale|r', 6, 3, 60, 20, 20, 1, 1, 10, 240, 40, 'ReplaceableTextures\CommandButtons\BTNReinforcedHides.blp', 'war3campImported\D_Skin_LizardRed.mdl', 'Ember-Warmed Scale', '|cffC0C0C0Material|r|nHeat lingers within this scale long after death.', 'Rare dragon materials are sought by smiths for resilient heat-bound alloys.', 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b8', '|c009D9D9DGrave Moss|r', 6, 1, 60, 8, 8, 1, 1, 10, 30, 5, 'ReplaceableTextures\CommandButtons\BTNNightElfBuild.blp', NULL, 'Grave Moss', '|cffC0C0C0Material|r|nPale moss pulled from stone and bone.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0b9', '|c009D9D9DRotten Rib|r', 7, 1, 23, 8, 8, 1, 1, 5, 16, 2, 'ReplaceableTextures\CommandButtons\BTNBoneChimes.blp', NULL, 'Rotten Rib', '|cffC0C0C0Junk|r|nToo old for broth, too fresh to ignore.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0c0', '|c009D9D9DRagged Banner Scrap|r', 7, 1, 23, 8, 8, 1, 1, 5, 20, 4, 'ReplaceableTextures\CommandButtons\BTNBattleStations.blp', NULL, 'Ragged Banner Scrap', '|cffC0C0C0Junk|r|nA torn scrap marked by some minor warband.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0c1', '|c009D9D9DTarnished Button|r', 7, 1, 23, 5, 5, 1, 1, 5, 8, 1, 'ReplaceableTextures\CommandButtons\BTNGoldRing.blp', NULL, 'Tarnished Button', '|cffC0C0C0Junk|r|nA dull metal button from a ruined coat.', NULL, 'rst1', 'Miscellaneous', NULL, NULL, NULL, false),
    ('j0c2', '|c009D9D9DDull Copper Buckle|r', 6, 1, 60, 5, 5, 1, 1, 10, 28, 5, 'ReplaceableTextures\CommandButtons\BTNINV_Ingot_02.TGA', 'war3campImported\GoldIngot.mdl', 'Dull Copper Buckle', '|cffC0C0C0Material|r|nA serviceable copper buckle from battered gear.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0c3', '|c009D9D9DEmpty Vial|r', 6, 1, 60, 5, 5, 1, 1, 10, 12, 2, 'ReplaceableTextures\CommandButtons\BTNPotionGreenSmall.blp', 'war3campImported\ITEMPotionGreenSmall.mdl', 'Empty Vial', '|cffC0C0C0Material|r|nClean enough for a novice alchemist.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0c4', '|c009D9D9DCoarse Thread Spool|r', 6, 1, 60, 5, 5, 1, 1, 10, 18, 3, 'ReplaceableTextures\CommandButtons\BTNScroll.blp', 'war3campImported\ITEMScroll.mdl', 'Coarse Thread Spool', '|cffC0C0C0Material|r|nRough thread for field repairs.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0c5', '|c009D9D9DCampfire Ash|r', 6, 1, 60, 5, 5, 1, 1, 10, 10, 1, 'ReplaceableTextures\CommandButtons\BTNWallOfFire.blp', NULL, 'Campfire Ash', '|cffC0C0C0Material|r|nFine ash used to dry hides and darken dyes.', NULL, 'phea', 'Charged', NULL, NULL, NULL, false),
    ('j0c6', '|c001EFF00Smoked Wolf Jerky|r', 4, 2, 16, 10, 10, 1, 1, 5, 65, 10, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Smoked Wolf Jerky', '|cff87CEEBFood|r|nA tough strip of smoked meat for long walks.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),
    ('j0c7', '|c001EFF00Roasted Stag Haunch|r', 4, 2, 16, 10, 10, 1, 1, 5, 70, 12, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Roasted Stag Haunch', '|cff87CEEBFood|r|nLean roasted meat wrapped for travel.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),
    ('j0c8', '|c001EFF00Bear Fat Biscuit|r', 4, 2, 16, 12, 12, 1, 1, 5, 85, 14, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Bear Fat Biscuit', '|cff87CEEBFood|r|nDense camp bread enriched with rendered bear fat.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),
    ('j0c9', '|c001EFF00Boiled Makrura Claw|r', 4, 2, 16, 12, 12, 1, 1, 5, 90, 15, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Boiled Makrura Claw', '|cff87CEEBFood|r|nSalty claw meat cooked until tender.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),
    ('j0d0', '|c001EFF00Spiced Snake Strips|r', 4, 2, 16, 12, 12, 1, 1, 5, 75, 12, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Spiced Snake Strips', '|cff87CEEBFood|r|nThin slices of snake meat dried with pepper.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),
    ('j0d1', '|c001EFF00Fried Crawler Cake|r', 4, 2, 16, 12, 12, 1, 1, 5, 95, 16, 'ReplaceableTextures\PassiveButtons\PASBTNVampiricAura.blp', 'war3campImported\ITEMMonsterLure.mdl', 'Fried Crawler Cake', '|cff87CEEBFood|r|nCrisp shore meat pressed into a travel cake.', NULL, 'rej3', 'Charged', 'A60V', NULL, NULL, false),

    ('j1a0', '|c009D9D9DMistwoven Hood|r', 2, 1, 1, 110, 5, 1, 0, 0, 120, 24, 'ReplaceableTextures\CommandButtons\BTNHoodOfCunning.blp', NULL, 'Buy Mistwoven Hood', NULL, NULL, 'rst1', 'Permanent', 'A64X,A07E', 'Cloth', 'HEAD', false),
    ('j1a1', '|c009D9D9DMistwoven Mantle|r', 2, 1, 24, 210, 5, 1, 0, 0, 140, 28, 'ReplaceableTextures\CommandButtons\BTNINV_Shoulder_02.blp', NULL, 'Buy Mistwoven Mantle', NULL, NULL, 'bspd', 'Permanent', 'A64X,A07E,A07Z', 'Cloth', 'SHOULDERS', false),
    ('j1a2', '|c001EFF00Mistwoven Robe|r', 2, 2, 2, 310, 10, 1, 0, 0, 300, 60, 'ReplaceableTextures\CommandButtons\BTNRobeOfTheMagi.blp', NULL, 'Buy Mistwoven Robe', NULL, NULL, 'rst1', 'Permanent', 'A076,A644,A07Z', 'Cloth', 'CHEST', false),
    ('j1a3', '|c009D9D9DMistwoven Wraps|r', 2, 1, 26, 360, 5, 1, 0, 0, 100, 20, 'ReplaceableTextures\CommandButtons\BTNBracer_06.blp', NULL, 'Buy Mistwoven Wraps', NULL, NULL, 'rst1', 'Permanent', 'A074,A07E', 'Cloth', 'WRISTS', false),
    ('j1a4', '|c001EFF00Mistwoven Gloves|r', 2, 2, 5, 410, 10, 1, 0, 0, 260, 52, 'ReplaceableTextures\CommandButtons\BTNGauntlets_15.blp', NULL, 'Buy Mistwoven Gloves', NULL, NULL, 'rst1', 'Permanent', 'A075,A08Y', 'Cloth', 'HANDS', false),
    ('j1a5', '|c009D9D9DMistwoven Sash|r', 2, 1, 27, 460, 5, 1, 0, 0, 110, 22, 'ReplaceableTextures\CommandButtons\BTNBelt_02.blp', NULL, 'Buy Mistwoven Sash', NULL, NULL, 'rst1', 'Permanent', 'A64X,A66A', 'Cloth', 'BELT', false),
    ('j1a6', '|c001EFF00Mistwoven Trousers|r', 2, 2, 3, 510, 10, 1, 0, 0, 280, 56, 'ReplaceableTextures\WorldEditUI\Editor-Random-Item.blp', NULL, 'Buy Mistwoven Trousers', NULL, NULL, 'rst1', 'Permanent', 'A075,A644,A07Z', 'Cloth', 'LEGS', false),
    ('j1a7', '|c009D9D9DMistwoven Slippers|r', 2, 1, 4, 560, 5, 1, 0, 0, 130, 26, 'ReplaceableTextures\CommandButtons\BTNBoots_Cloth_02.blp', NULL, 'Buy Mistwoven Slippers', NULL, NULL, 'bspd', 'Permanent', 'A06Q,A64X,A08C', 'Cloth', 'FEET', false),

    ('j1a8', '|c009D9D9DTrailscarred Leather Coif|r', 2, 1, 1, 110, 10, 1, 0, 0, 180, 36, 'ReplaceableTextures\CommandButtons\BTNHelmet_02.blp', NULL, 'Buy Trailscarred Leather Coif', NULL, NULL, 'rst1', 'Permanent', 'A06S,A643,A07Z', 'Leather', 'HEAD', false),
    ('j1a9', '|c009D9D9DTrailscarred Leather Shoulders|r', 2, 1, 24, 210, 10, 1, 0, 0, 190, 38, 'ReplaceableTextures\CommandButtons\BTNINV_Shoulder_29.blp', NULL, 'Buy Trailscarred Leather Shoulders', NULL, NULL, 'bspd', 'Permanent', 'A669,A06S,A07Z', 'Leather', 'SHOULDERS', false),
    ('j1b0', '|c001EFF00Trailscarred Leather Jerkin|r', 2, 2, 2, 310, 15, 1, 0, 0, 420, 84, 'ReplaceableTextures\CommandButtons\BTNLeatherUpgradeOne.blp', NULL, 'Buy Trailscarred Leather Jerkin', NULL, NULL, 'rst1', 'Permanent', 'A06U,A643,A66A,A080', 'Leather', 'CHEST', false),
    ('j1b1', '|c009D9D9DTrailscarred Leather Bracers|r', 2, 1, 26, 360, 10, 1, 0, 0, 160, 32, 'ReplaceableTextures\CommandButtons\BTNBracer_03.blp', NULL, 'Buy Trailscarred Leather Bracers', NULL, NULL, 'rst1', 'Permanent', 'A06R,A64E,A07Z', 'Leather', 'WRISTS', false),
    ('j1b2', '|c001EFF00Trailscarred Leather Gloves|r', 2, 2, 5, 410, 15, 1, 0, 0, 390, 78, 'ReplaceableTextures\CommandButtons\BTNGauntlets_12.blp', NULL, 'Buy Trailscarred Leather Gloves', NULL, NULL, 'rst1', 'Permanent', 'A06T,A07P,A07Z', 'Leather', 'HANDS', false),
    ('j1b3', '|c009D9D9DTrailscarred Leather Belt|r', 2, 1, 27, 460, 10, 1, 0, 0, 170, 34, 'ReplaceableTextures\CommandButtons\BTNBelt_19.blp', NULL, 'Buy Trailscarred Leather Belt', NULL, NULL, 'rst1', 'Permanent', 'A06Y,A06R,A643', 'Leather', 'BELT', false),
    ('j1b4', '|c001EFF00Trailscarred Leather Legguards|r', 2, 2, 3, 510, 15, 1, 0, 0, 410, 82, 'ReplaceableTextures\WorldEditUI\Editor-Random-Item.blp', NULL, 'Buy Trailscarred Leather Legguards', NULL, NULL, 'rst1', 'Permanent', 'A06U,A643,A080', 'Leather', 'LEGS', false),
    ('j1b5', '|c009D9D9DTrailscarred Leather Boots|r', 2, 1, 4, 560, 10, 1, 0, 0, 180, 36, 'ReplaceableTextures\CommandButtons\BTNBootsOfSpeed.blp', 'war3campImported\ITEMBootsOfSpeed.mdl', 'Buy Trailscarred Leather Boots', NULL, NULL, 'bspd', 'Permanent', 'A06T,A08D,A07Z', 'Leather', 'FEET', false),

    ('j1b6', '|c001EFF00Stormlink Coif|r', 2, 2, 1, 110, 15, 1, 0, 0, 520, 104, 'ReplaceableTextures\CommandButtons\BTNHelmet_39.blp', NULL, 'Buy Stormlink Coif', NULL, NULL, 'rst1', 'Permanent', 'A070,A06R,A081', 'Mail', 'HEAD', false),
    ('j1b7', '|c001EFF00Stormlink Spaulders|r', 2, 2, 24, 210, 15, 1, 0, 0, 540, 108, 'ReplaceableTextures\CommandButtons\BTNINV_Shoulder_29.blp', NULL, 'Buy Stormlink Spaulders', NULL, NULL, 'bspd', 'Permanent', 'A06Z,A06S,A643,A081', 'Mail', 'SHOULDERS', false),
    ('j1b8', '|c000070DDStormlink Hauberk|r', 2, 3, 2, 310, 20, 1, 0, 0, 1200, 240, 'ReplaceableTextures\CommandButtons\BTNChest_Chain_13.blp', NULL, 'Buy Stormlink Hauberk', NULL, 'Links of darkened steel hum when storm clouds gather.', 'rst1', 'Permanent', 'A64V,A06T,A63Y,A083', 'Mail', 'CHEST', false),
    ('j1b9', '|c001EFF00Stormlink Wristguards|r', 2, 2, 26, 360, 15, 1, 0, 0, 430, 86, 'ReplaceableTextures\CommandButtons\BTNBracer_03.blp', NULL, 'Buy Stormlink Wristguards', NULL, NULL, 'rst1', 'Permanent', 'A06Y,A06T,A080', 'Mail', 'WRISTS', false),
    ('j1c0', '|c000070DDStormlink Grips|r', 2, 3, 5, 410, 20, 1, 0, 0, 1000, 200, 'ReplaceableTextures\CommandButtons\BTNGauntlets_12.blp', NULL, 'Buy Stormlink Grips', NULL, 'Fine chain is woven through the fingers to guide a killing strike.', 'rst1', 'Permanent', 'A071,A06U,A64F,A081', 'Mail', 'HANDS', false),
    ('j1c1', '|c001EFF00Stormlink Girdle|r', 2, 2, 27, 460, 15, 1, 0, 0, 460, 92, 'ReplaceableTextures\CommandButtons\BTNBelt_19.blp', NULL, 'Buy Stormlink Girdle', NULL, NULL, 'rst1', 'Permanent', 'A070,A63E,A080', 'Mail', 'BELT', false),
    ('j1c2', '|c000070DDStormlink Legguards|r', 2, 3, 3, 510, 20, 1, 0, 0, 1150, 230, 'ReplaceableTextures\WorldEditUI\Editor-Random-Item.blp', NULL, 'Buy Stormlink Legguards', NULL, 'Greaves for outriders who ride through bad weather by choice.', 'rst1', 'Permanent', 'A072,A06V,A63E,A082', 'Mail', 'LEGS', false),
    ('j1c3', '|c001EFF00Stormlink Sabatons|r', 2, 2, 4, 560, 15, 1, 0, 0, 480, 96, 'ReplaceableTextures\CommandButtons\BTNBoots_Chain_01.blp', NULL, 'Buy Stormlink Sabatons', NULL, NULL, 'bspd', 'Permanent', 'A070,A06T,A08D,A080', 'Mail', 'FEET', false),

    ('j1c4', '|c000070DDIronbound Greathelm|r', 2, 3, 1, 110, 20, 1, 0, 0, 1450, 290, 'ReplaceableTextures\CommandButtons\BTNThoriumArmor.blp', NULL, 'Buy Ironbound Greathelm', NULL, 'A heavy helm with an inner rim of hammered copper runes.', 'rst1', 'Permanent', 'A6D7,A63Z,A083,A07Z', 'Plate', 'HEAD', false),
    ('j1c5', '|c000070DDIronbound Pauldrons|r', 2, 3, 24, 210, 20, 1, 0, 0, 1420, 284, 'ReplaceableTextures\CommandButtons\BTNINV_Shoulder_29.blp', NULL, 'Buy Ironbound Pauldrons', NULL, 'Broad shoulders built to turn aside both claws and arrows.', 'bspd', 'Permanent', 'A64V,A63Y,A64K,A083', 'Plate', 'SHOULDERS', false),
    ('j1c6', '|c00A335EEIronbound Breastplate|r', 2, 4, 2, 310, 25, 1, 0, 0, 2600, 520, 'ReplaceableTextures\CommandButtons\BTNBerserkersArmor.blp', NULL, 'Buy Ironbound Breastplate', NULL, 'A rare plate cuirass tempered in coal-black oil and cooled under a storm sky.', 'rst1', 'Permanent', 'A6D4,A6D8,A083,A081,A0BK', 'Plate', 'CHEST', false),
    ('j1c7', '|c000070DDIronbound Vambraces|r', 2, 3, 26, 360, 20, 1, 0, 0, 1200, 240, 'ReplaceableTextures\CommandButtons\BTNBracer_06.blp', NULL, 'Buy Ironbound Vambraces', NULL, 'Fitted vambraces with reinforced blocking plates.', 'rst1', 'Permanent', 'A071,A63E,A64K,A082', 'Plate', 'WRISTS', false),
    ('j1c8', '|c000070DDIronbound Gauntlets|r', 2, 3, 5, 410, 20, 1, 0, 0, 1250, 250, 'ReplaceableTextures\CommandButtons\BTNGauntlets_31.blp', NULL, 'Buy Ironbound Gauntlets', NULL, 'The knuckles are worn smooth from old shield walls.', 'rst1', 'Permanent', 'A64V,A07P,A082', 'Plate', 'HANDS', false),
    ('j1c9', '|c000070DDIronbound Warbelt|r', 2, 3, 27, 460, 20, 1, 0, 0, 1180, 236, 'ReplaceableTextures\CommandButtons\BTNBelt_19.blp', NULL, 'Buy Ironbound Warbelt', NULL, 'A stern belt meant to hold plate in place through a charge.', 'rst1', 'Permanent', 'A64V,A63Y,A082', 'Plate', 'BELT', false),
    ('j1d0', '|c00A335EEIronbound Legplates|r', 2, 4, 3, 510, 25, 1, 0, 0, 2500, 500, 'ReplaceableTextures\WorldEditUI\Editor-Random-Item.blp', NULL, 'Buy Ironbound Legplates', NULL, 'Overlapping plates allow surprising movement for something this heavy.', 'rst1', 'Permanent', 'A6D7,A669,A6D8,A083,A080,A08C', 'Plate', 'LEGS', false),
    ('j1d1', '|c000070DDIronbound Greaves|r', 2, 3, 4, 560, 20, 1, 0, 0, 1320, 264, 'ReplaceableTextures\CommandButtons\BTNBoots_Chain_01.blp', NULL, 'Buy Ironbound Greaves', NULL, 'Heavy greaves balanced by clever strapping and copper pivots.', 'bspd', 'Permanent', 'A64V,A63Y,A083,A08C', 'Plate', 'FEET', false);

INSERT INTO items (
    item_code, item_name, type_id, rarity_id, class_id, item_level, required_level,
    max_charges, max_stack, gold_cost, sell_value,
    is_droppable, is_sellable, is_pawnable, is_powerup, drops_on_death,
    is_perishable, is_soulbound, is_unique, use_automatically, can_be_dropped_by_carrier,
    icon_path, model_path, tint_red, tint_green, tint_blue, tint_alpha, scale,
    tooltip, tooltip_extended, description, lore, cooldown_duration, priority,
    dinv_compatible, deq_compatible, custom_data, base_id, wc3_classification,
    wc3_abilities, armor_type, equipment_slot, original_modifications,
    copy_base_abilities, item_level_unclassified, specific_drop_only
)
SELECT
    item_code, item_name, type_id, rarity_id, class_id, item_level, required_level,
    max_charges, max_stack, gold_cost, sell_value,
    true, true, true, false, true,
    false, false, false, false, true,
    icon_path, model_path, 255, 255, 255, 255, 1.00,
    tooltip, tooltip_body, tooltip_body, NULL, 0, 0,
    true, (type_id = 2), '{}'::jsonb, base_id, wc3_classification,
    wc3_abilities, armor_type, equipment_slot, '{}'::jsonb,
    false, item_level_unclassified, specific_drop_only
FROM codex_item_seed
ON CONFLICT (item_code) DO UPDATE SET
    item_name = EXCLUDED.item_name,
    type_id = EXCLUDED.type_id,
    rarity_id = EXCLUDED.rarity_id,
    class_id = EXCLUDED.class_id,
    item_level = EXCLUDED.item_level,
    required_level = EXCLUDED.required_level,
    max_charges = EXCLUDED.max_charges,
    max_stack = EXCLUDED.max_stack,
    gold_cost = EXCLUDED.gold_cost,
    sell_value = EXCLUDED.sell_value,
    is_droppable = EXCLUDED.is_droppable,
    is_sellable = EXCLUDED.is_sellable,
    is_pawnable = EXCLUDED.is_pawnable,
    icon_path = EXCLUDED.icon_path,
    model_path = EXCLUDED.model_path,
    tooltip = EXCLUDED.tooltip,
    tooltip_extended = EXCLUDED.tooltip_extended,
    description = EXCLUDED.description,
    dinv_compatible = EXCLUDED.dinv_compatible,
    deq_compatible = EXCLUDED.deq_compatible,
    base_id = EXCLUDED.base_id,
    wc3_classification = EXCLUDED.wc3_classification,
    wc3_abilities = EXCLUDED.wc3_abilities,
    armor_type = EXCLUDED.armor_type,
    equipment_slot = EXCLUDED.equipment_slot,
    item_level_unclassified = EXCLUDED.item_level_unclassified,
    specific_drop_only = EXCLUDED.specific_drop_only,
    updated_at = NOW();

CREATE TEMP TABLE codex_stat_seed (
    item_code varchar(4) NOT NULL,
    stat_code text NOT NULL,
    stat_value numeric(10,2) NOT NULL,
    sort_order integer NOT NULL
) ON COMMIT DROP;

INSERT INTO codex_stat_seed (item_code, stat_code, stat_value, sort_order) VALUES
    ('j1a0','int',2,0), ('j1a0','mp',25,1),
    ('j1a1','int',2,0), ('j1a1','mp',25,1), ('j1a1','armor',1,2),
    ('j1a2','int',4,0), ('j1a2','mp',50,1), ('j1a2','armor',1,2),
    ('j1a3','int',1,0), ('j1a3','mp',25,1),
    ('j1a4','int',3,0), ('j1a4','spell_power',10,1),
    ('j1a5','int',2,0), ('j1a5','hp',25,1),
    ('j1a6','int',3,0), ('j1a6','mp',50,1), ('j1a6','armor',1,2),
    ('j1a7','agi',1,0), ('j1a7','int',2,1), ('j1a7','ms',2,2),
    ('j1a8','agi',4,0), ('j1a8','hp',50,1), ('j1a8','armor',1,2),
    ('j1a9','str',2,0), ('j1a9','agi',4,1), ('j1a9','armor',1,2),
    ('j1b0','agi',6,0), ('j1b0','hp',75,1), ('j1b0','armor',2,2),
    ('j1b1','agi',3,0), ('j1b1','crit',1,1), ('j1b1','armor',1,2),
    ('j1b2','agi',5,0), ('j1b2','dmg',5,1), ('j1b2','armor',1,2),
    ('j1b3','str',3,0), ('j1b3','agi',3,1), ('j1b3','hp',50,2),
    ('j1b4','agi',6,0), ('j1b4','hp',50,1), ('j1b4','armor',2,2),
    ('j1b5','agi',5,0), ('j1b5','ms',3,1), ('j1b5','armor',1,2),
    ('j1b6','str',5,0), ('j1b6','agi',3,1), ('j1b6','armor',3,2),
    ('j1b7','str',4,0), ('j1b7','agi',4,1), ('j1b7','hp',50,2), ('j1b7','armor',3,3),
    ('j1b8','str',8,0), ('j1b8','agi',5,1), ('j1b8','hp',150,2), ('j1b8','armor',5,3),
    ('j1b9','str',3,0), ('j1b9','agi',5,1), ('j1b9','armor',2,2),
    ('j1c0','str',6,0), ('j1c0','agi',6,1), ('j1c0','crit',2,2), ('j1c0','armor',3,3),
    ('j1c1','str',5,0), ('j1c1','hp',100,1), ('j1c1','armor',2,2),
    ('j1c2','str',7,0), ('j1c2','agi',7,1), ('j1c2','hp',100,2), ('j1c2','armor',4,3),
    ('j1c3','str',5,0), ('j1c3','agi',5,1), ('j1c3','ms',3,2), ('j1c3','armor',2,3),
    ('j1c4','str',10,0), ('j1c4','hp',200,1), ('j1c4','armor',6,2),
    ('j1c5','str',8,0), ('j1c5','hp',150,1), ('j1c5','block',2,2), ('j1c5','armor',5,3),
    ('j1c6','str',15,0), ('j1c6','hp',250,1), ('j1c6','armor',8,2), ('j1c6','armor_pct',5,3),
    ('j1c7','str',6,0), ('j1c7','hp',100,1), ('j1c7','block',2,2), ('j1c7','armor',4,3),
    ('j1c8','str',8,0), ('j1c8','dmg',5,1), ('j1c8','armor',4,2),
    ('j1c9','str',8,0), ('j1c9','hp',150,1), ('j1c9','armor',4,2),
    ('j1d0','str',12,0), ('j1d0','hp',250,1), ('j1d0','armor',7,2), ('j1d0','ms',2,3),
    ('j1d1','str',8,0), ('j1d1','hp',150,1), ('j1d1','armor',5,2), ('j1d1','ms',2,3);

DELETE FROM item_stat_values isv
USING items i
WHERE isv.item_id = i.id
  AND i.item_code IN (SELECT DISTINCT item_code FROM codex_stat_seed);

INSERT INTO item_stat_values (item_id, stat_id, stat_value, sort_order)
SELECT i.id, s.id, ss.stat_value, ss.sort_order
FROM codex_stat_seed ss
JOIN items i ON i.item_code = ss.item_code
JOIN item_stats s ON s.stat_code = ss.stat_code;

WITH armor_lines AS (
    SELECT
        ss.item_code,
        string_agg(
            '|cff' || replace(st.color_hex, '#', '') ||
            replace(st.display_format, '{value}', to_char(ss.stat_value, 'FM999999990.##')) ||
            ' ' || st.stat_name || '|r',
            '|n' ORDER BY ss.sort_order
        ) AS stat_lines
    FROM codex_stat_seed ss
    JOIN item_stats st ON st.stat_code = ss.stat_code
    GROUP BY ss.item_code
)
UPDATE items i
SET tooltip_extended =
    '[|cffC0C0C0' || c.class_name || '|r, |cff' || replace(r.color_code, '#', '') || r.rarity_name || '|r]|n' ||
    CASE WHEN seed.flavor IS NOT NULL THEN seed.flavor || '|n|n' ELSE '' END ||
    armor_lines.stat_lines,
    description = CASE WHEN seed.flavor IS NOT NULL THEN seed.flavor ELSE i.description END,
    updated_at = NOW()
FROM codex_item_seed seed
JOIN armor_lines ON armor_lines.item_code = seed.item_code
JOIN item_classes c ON c.id = seed.class_id
JOIN item_rarities r ON r.id = seed.rarity_id
WHERE i.item_code = seed.item_code;

CREATE TEMP TABLE codex_extra_loot_item_seed (
    table_name text NOT NULL,
    item_code varchar(4) NOT NULL,
    drop_chance integer NOT NULL,
    weight integer NOT NULL,
    quantity_min integer NOT NULL DEFAULT 1,
    quantity_max integer NOT NULL DEFAULT 1,
    notes text
) ON COMMIT DROP;

INSERT INTO codex_extra_loot_item_seed (table_name, item_code, drop_chance, weight, notes) VALUES
    ('Generic Level 1-5','I6AR',10000,80,'OldGUI wolf junk'),
    ('Generic Level 1-5','I614',10000,80,'OldGUI stag material'),
    ('Generic Level 1-5','I6AS',10000,65,'OldGUI stag junk'),
    ('Generic Level 1-5','I6AB',10000,45,'OldGUI bear tooth'),
    ('Generic Level 1-5','I622',10000,45,'OldGUI rabbit meat'),
    ('Generic Level 6-10','I6AE',10000,70,'OldGUI murloc fin'),
    ('Generic Level 6-10','I00S',10000,80,'OldGUI whelp scale'),
    ('Generic Level 6-10','I00X',10000,65,'OldGUI dragon claw'),
    ('Generic Level 6-10','I00V',10000,55,'OldGUI dragon sac'),
    ('Generic Level 6-10','I00W',10000,55,'OldGUI dragonhide'),
    ('Generic Level 6-10','I66P',10000,60,'OldGUI undead part'),
    ('Generic Level 6-10','I6A4',10000,45,'Gnoll junk'),
    ('Generic Level 11-15','j1b8',10000,35,'Rare mail armor'),
    ('Generic Level 11-15','j1c0',10000,35,'Rare mail armor'),
    ('Generic Level 16-20','j1c4',10000,28,'Rare plate armor'),
    ('Generic Level 16-20','j1c5',10000,28,'Rare plate armor'),
    ('Generic Level 16-20','j1c7',10000,28,'Rare plate armor'),
    ('Generic Level 16-20','j1c8',10000,28,'Rare plate armor'),
    ('Generic Level 16-20','j1c9',10000,28,'Rare plate armor'),
    ('Generic Level 21-25','j1c6',10000,10,'Epic plate armor'),
    ('Generic Level 21-25','j1d0',10000,10,'Epic plate armor'),
    ('Dragons','I00S',10000,120,'OldGUI dragon skinning'),
    ('Dragons','I00X',10000,90,'OldGUI dragon junk'),
    ('Dragons','I00V',10000,70,'OldGUI dragon reagent'),
    ('Dragons','I00W',10000,70,'OldGUI dragon hide'),
    ('Dragons','j0b6',10000,70,'New dragon material'),
    ('Dragons','j0b7',10000,35,'New rare dragon material'),
    ('Dragons','j1b8',10000,20,'Dragon category armor'),
    ('Dragons','j1c6',10000,8,'Dragon category armor'),
    ('Undead Minions','I66P',10000,120,'OldGUI undead part'),
    ('Undead Minions','j0b8',10000,70,'New undead material'),
    ('Undead Minions','j0b9',10000,70,'New undead junk'),
    ('Undead Minions','j1a2',10000,20,'Undead caster cloth'),
    ('Demons','j0b6',10000,60,'Scorched demon material'),
    ('Demons','j0b7',10000,25,'Rare ember material'),
    ('Demons','j1c4',10000,18,'Demon category plate'),
    ('Forest Trolls','j0c0',10000,90,'Warband junk'),
    ('Forest Trolls','j0c1',10000,70,'Humanoid junk'),
    ('Forest Trolls','j1b9',10000,20,'Humanoid mail armor'),
    ('Human Guards','j0c1',10000,90,'Humanoid junk'),
    ('Human Guards','j0c2',10000,70,'Humanoid material'),
    ('Human Guards','j1c7',10000,20,'Guard plate armor'),
    ('Boss Generic','j1c6',10000,12,'Boss epic plate'),
    ('Boss Generic','j1d0',10000,12,'Boss epic plate'),
    ('Boss Generic','j1b8',10000,25,'Boss rare mail'),
    ('Boss Generic','j1c4',10000,25,'Boss rare plate');

WITH generic_seed AS (
    SELECT
        CASE
            WHEN item_level_unclassified BETWEEN 1 AND 5 THEN 'Generic Level 1-5'
            WHEN item_level_unclassified BETWEEN 6 AND 10 THEN 'Generic Level 6-10'
            WHEN item_level_unclassified BETWEEN 11 AND 15 THEN 'Generic Level 11-15'
            WHEN item_level_unclassified BETWEEN 16 AND 20 THEN 'Generic Level 16-20'
            WHEN item_level_unclassified BETWEEN 21 AND 25 THEN 'Generic Level 21-25'
            WHEN item_level_unclassified BETWEEN 26 AND 30 THEN 'Generic Level 26-30'
            ELSE 'Generic Level 31+'
        END AS table_name,
        item_code,
        10000 AS drop_chance,
        CASE rarity_id WHEN 1 THEN 120 WHEN 2 THEN 80 WHEN 3 THEN 35 WHEN 4 THEN 12 WHEN 5 THEN 6 ELSE 3 END AS weight,
        1 AS quantity_min,
        1 AS quantity_max,
        'Codex 2026 new item generic pool'::text AS notes
    FROM codex_item_seed
    WHERE item_level_unclassified IS NOT NULL
),
all_table_items AS (
    SELECT * FROM generic_seed
    UNION ALL
    SELECT * FROM codex_extra_loot_item_seed
),
raw_resolved AS (
    SELECT lt.id AS loot_table_id, ati.item_code, ati.drop_chance, ati.weight,
           ati.quantity_min, ati.quantity_max, ati.notes
    FROM all_table_items ati
    JOIN loot_tables lt ON lt.name = ati.table_name
    JOIN items i ON i.item_code = ati.item_code
),
resolved AS (
    SELECT loot_table_id, item_code,
           MAX(drop_chance) AS drop_chance,
           MAX(weight) AS weight,
           MIN(quantity_min) AS quantity_min,
           MAX(quantity_max) AS quantity_max,
           string_agg(DISTINCT notes, '; ' ORDER BY notes) AS notes
    FROM raw_resolved
    GROUP BY loot_table_id, item_code
)
UPDATE loot_table_items lti
SET drop_chance = resolved.drop_chance,
    weight = resolved.weight,
    quantity_min = resolved.quantity_min,
    quantity_max = resolved.quantity_max,
    notes = resolved.notes
FROM resolved
WHERE lti.loot_table_id = resolved.loot_table_id
  AND lti.item_code = resolved.item_code;

WITH generic_seed AS (
    SELECT
        CASE
            WHEN item_level_unclassified BETWEEN 1 AND 5 THEN 'Generic Level 1-5'
            WHEN item_level_unclassified BETWEEN 6 AND 10 THEN 'Generic Level 6-10'
            WHEN item_level_unclassified BETWEEN 11 AND 15 THEN 'Generic Level 11-15'
            WHEN item_level_unclassified BETWEEN 16 AND 20 THEN 'Generic Level 16-20'
            WHEN item_level_unclassified BETWEEN 21 AND 25 THEN 'Generic Level 21-25'
            WHEN item_level_unclassified BETWEEN 26 AND 30 THEN 'Generic Level 26-30'
            ELSE 'Generic Level 31+'
        END AS table_name,
        item_code,
        10000 AS drop_chance,
        CASE rarity_id WHEN 1 THEN 120 WHEN 2 THEN 80 WHEN 3 THEN 35 WHEN 4 THEN 12 WHEN 5 THEN 6 ELSE 3 END AS weight,
        1 AS quantity_min,
        1 AS quantity_max,
        'Codex 2026 new item generic pool'::text AS notes
    FROM codex_item_seed
    WHERE item_level_unclassified IS NOT NULL
),
all_table_items AS (
    SELECT * FROM generic_seed
    UNION ALL
    SELECT * FROM codex_extra_loot_item_seed
),
raw_resolved AS (
    SELECT lt.id AS loot_table_id, ati.item_code, ati.drop_chance, ati.weight,
           ati.quantity_min, ati.quantity_max, ati.notes
    FROM all_table_items ati
    JOIN loot_tables lt ON lt.name = ati.table_name
    JOIN items i ON i.item_code = ati.item_code
),
resolved AS (
    SELECT loot_table_id, item_code,
           MAX(drop_chance) AS drop_chance,
           MAX(weight) AS weight,
           MIN(quantity_min) AS quantity_min,
           MAX(quantity_max) AS quantity_max,
           string_agg(DISTINCT notes, '; ' ORDER BY notes) AS notes
    FROM raw_resolved
    GROUP BY loot_table_id, item_code
)
INSERT INTO loot_table_items (
    loot_table_id, item_code, drop_chance, weight, is_guaranteed,
    quantity_min, quantity_max, notes
)
SELECT loot_table_id, item_code, drop_chance, weight, false,
       quantity_min, quantity_max, notes
FROM resolved r
WHERE NOT EXISTS (
    SELECT 1
    FROM loot_table_items lti
    WHERE lti.loot_table_id = r.loot_table_id
      AND lti.item_code = r.item_code
);

CREATE TEMP TABLE codex_unit_category (
    unit_code varchar(4) NOT NULL,
    category text NOT NULL
) ON COMMIT DROP;

INSERT INTO codex_unit_category (unit_code, category)
SELECT unit_code, 'wolf' FROM unit_types WHERE unit_name ILIKE '%Wolf%' OR editor_suffix ILIKE '%Wolf%'
UNION ALL SELECT unit_code, 'bear' FROM unit_types WHERE unit_name ILIKE '%Bear%' OR editor_suffix ILIKE '%Bear%'
UNION ALL SELECT unit_code, 'stag' FROM unit_types WHERE unit_name ILIKE '%Stag%' OR editor_suffix ILIKE '%Stag%'
UNION ALL SELECT unit_code, 'boar' FROM unit_types WHERE unit_name ILIKE '%Boar%' OR editor_suffix ILIKE '%Boar%' OR unit_name = 'npig' OR editor_suffix ILIKE '%Pig%'
UNION ALL SELECT unit_code, 'snake' FROM unit_types WHERE unit_name ILIKE '%Snake%' OR editor_suffix ILIKE '%Snake%'
UNION ALL SELECT unit_code, 'frog' FROM unit_types WHERE unit_name ILIKE '%Frog%' OR editor_suffix ILIKE '%Frog%'
UNION ALL SELECT unit_code, 'crawler' FROM unit_types WHERE unit_name ILIKE '%Crab%' OR unit_name ILIKE '%Crawler%' OR editor_suffix ILIKE '%Crab%' OR editor_suffix ILIKE '%Crawler%'
UNION ALL SELECT unit_code, 'murloc' FROM unit_types WHERE unit_name ILIKE '%Murloc%' OR unit_name IN ('Margul', 'Mur''gal') OR editor_suffix ILIKE '%Murloc%'
UNION ALL SELECT unit_code, 'makrura' FROM unit_types WHERE unit_name ILIKE '%Makrura%' OR editor_suffix ILIKE '%Makrura%'
UNION ALL SELECT unit_code, 'lizard' FROM unit_types WHERE unit_name ILIKE '%Lizard%' OR unit_name ILIKE '%Salamander%' OR unit_name ILIKE '%Storm Wyrm%' OR editor_suffix ILIKE '%Lizard%' OR editor_suffix ILIKE '%Salamander%'
UNION ALL SELECT unit_code, 'dragon' FROM unit_types WHERE unit_name ILIKE '%Dragon%' OR unit_name ILIKE '%Whelp%' OR editor_suffix ILIKE '%Dragon%' OR editor_suffix ILIKE '%Whelp%'
UNION ALL SELECT unit_code, 'gnoll' FROM unit_types WHERE unit_name ILIKE '%Gnoll%' OR unit_name = 'Deathlord Fel''Dok' OR editor_suffix ILIKE '%Gnoll%'
UNION ALL SELECT unit_code, 'undead' FROM unit_types WHERE unit_name ILIKE '%Zombie%' OR unit_name ILIKE '%Ghoul%' OR unit_name ILIKE '%Abomination%' OR unit_name ILIKE '%Skeleton%' OR unit_name ILIKE '%Skeletal%' OR editor_suffix ILIKE '%Skeleton%';

CREATE TEMP TABLE codex_drop_rule (
    category text NOT NULL,
    item_code varchar(4) NOT NULL,
    drop_chance numeric(5,2) NOT NULL,
    weight integer NOT NULL,
    notes text
) ON COMMIT DROP;

INSERT INTO codex_drop_rule (category, item_code, drop_chance, weight, notes) VALUES
    ('wolf','I61O',10.00,100,'OldGUI wolf meat'),
    ('wolf','I6AR',16.67,90,'OldGUI wolf jawbone'),
    ('wolf','I61F',16.67,90,'OldGUI wolf skin'),
    ('wolf','j0a0',12.00,70,'New wolf material'),
    ('wolf','j0c6',6.00,30,'Prepared wolf food'),
    ('bear','I61Q',10.00,100,'OldGUI bear meat'),
    ('bear','I61B',20.00,90,'Bear skin material'),
    ('bear','I6AB',20.00,80,'OldGUI bear tooth'),
    ('bear','j0a3',12.00,60,'New bear material'),
    ('bear','j0c8',6.00,30,'Prepared bear food'),
    ('stag','I61P',10.00,100,'OldGUI stag meat'),
    ('stag','I614',25.00,90,'OldGUI stag hair'),
    ('stag','I6AS',16.67,70,'OldGUI large hoof'),
    ('stag','j0a2',12.00,60,'New stag material'),
    ('stag','j0c7',6.00,30,'Prepared stag food'),
    ('boar','I620',10.00,100,'OldGUI boar meat'),
    ('boar','I61C',15.00,80,'Boar skin material'),
    ('boar','j0a1',18.00,70,'New boar junk'),
    ('crawler','I621',10.00,100,'OldGUI crawler meat'),
    ('crawler','j0b4',20.00,80,'New crawler material'),
    ('crawler','j0b5',12.00,60,'New crawler reagent'),
    ('crawler','j0d1',6.00,30,'Prepared crawler food'),
    ('frog','I615',25.00,100,'OldGUI frog slime'),
    ('frog','I61D',15.00,70,'Frog skin material'),
    ('frog','j0b2',18.00,80,'New frog material'),
    ('frog','j0b3',8.00,40,'New frog junk'),
    ('snake','I61Y',10.00,100,'OldGUI snake meat'),
    ('snake','j0b0',20.00,80,'New snake material'),
    ('snake','j0b1',10.00,50,'New snake reagent'),
    ('snake','j0d0',6.00,30,'Prepared snake food'),
    ('murloc','I61T',10.00,100,'OldGUI murloc meat'),
    ('murloc','I6AE',33.33,90,'OldGUI murloc fin'),
    ('murloc','I610',15.00,60,'OldGUI murloc head'),
    ('murloc','j0a6',14.00,70,'New murloc material'),
    ('murloc','j0a7',12.00,55,'New murloc material'),
    ('makrura','I61Z',10.00,100,'OldGUI makrura meat'),
    ('makrura','j0a8',20.00,80,'New makrura material'),
    ('makrura','j0a9',16.00,70,'New makrura junk'),
    ('makrura','j0c9',6.00,30,'Prepared makrura food'),
    ('lizard','I61R',10.00,100,'OldGUI lizard meat'),
    ('lizard','I61G',20.00,80,'Thunder lizard skin'),
    ('lizard','j0b7',8.00,35,'Rare lizard scale'),
    ('dragon','I00X',16.67,80,'OldGUI sharp claw'),
    ('dragon','I00V',16.67,70,'OldGUI small flame sac'),
    ('dragon','I00W',16.67,70,'OldGUI ruined dragonhide'),
    ('dragon','I00S',40.00,95,'OldGUI whelp scale'),
    ('dragon','j0b6',12.00,60,'New whelp horn'),
    ('dragon','j0b7',8.00,35,'New rare dragon scale'),
    ('gnoll','I69A',25.00,80,'OldGUI gnoll head'),
    ('gnoll','I6A4',16.00,70,'Gnoll pillage'),
    ('gnoll','j0a4',12.00,60,'New gnoll junk'),
    ('gnoll','j0a5',10.00,50,'New gnoll junk'),
    ('gnoll','j0c0',8.00,40,'New warband scrap'),
    ('gnoll','j1b1',4.00,20,'Gnoll leather armor'),
    ('gnoll','j1b9',3.00,12,'Gnoll mail armor'),
    ('undead','I66P',20.00,100,'OldGUI rotten part'),
    ('undead','j0b8',12.00,65,'New undead material'),
    ('undead','j0b9',12.00,65,'New undead junk'),
    ('undead','j1a3',3.00,15,'Undead cloth armor');

CREATE TEMP TABLE codex_direct_drop (
    unit_name text NOT NULL,
    editor_suffix text,
    item_code varchar(4) NOT NULL,
    drop_chance numeric(5,2) NOT NULL,
    is_guaranteed boolean NOT NULL,
    weight integer NOT NULL,
    notes text
) ON COMMIT DROP;

INSERT INTO codex_direct_drop (unit_name, editor_suffix, item_code, drop_chance, is_guaranteed, weight, notes) VALUES
    ('Mother Bear', NULL, 'I6AB', 100.00, true, 100, 'OldGUI Mother Bear guaranteed tooth'),
    ('Ferocious Bear', NULL, 'I6AB', 50.00, false, 100, 'OldGUI Ferocious Bear tooth'),
    ('Deathlord Fel''Dok', NULL, 'j1c6', 35.00, false, 100, 'Boss armor addition'),
    ('Deathlord Fel''Dok', NULL, 'j1c4', 35.00, false, 100, 'Boss armor addition'),
    ('Margul', NULL, 'j1b8', 30.00, false, 100, 'Boss mail addition'),
    ('Mur''gal', NULL, 'j1c0', 30.00, false, 100, 'Boss mail addition'),
    ('Unknown Entity', NULL, 'j1a4', 25.00, false, 100, 'Boss cloth addition'),
    ('Velaria', '(Succubus)', 'j1a2', 25.00, false, 100, 'Boss cloth addition'),
    ('Colossus', '(Level 15)', 'j1c6', 45.00, false, 100, 'Boss epic plate addition'),
    ('Colossus', '(Level 15)', 'j1d0', 45.00, false, 100, 'Boss epic plate addition'),
    ('Gollum', '(Level 13)', 'j1d1', 25.00, false, 100, 'Boss plate addition'),
    ('Sargoth', NULL, 'j1c4', 35.00, false, 100, 'Boss plate addition'),
    ('MordraxDummy', NULL, 'j1d0', 45.00, false, 100, 'Boss epic plate addition'),
    ('Mordrax the Desolator', '(Level 15)', 'j1d0', 45.00, false, 100, 'Boss epic plate addition'),
    ('Rol''jin', NULL, 'j1b9', 25.00, false, 100, 'Boss mail addition');

WITH category_candidates AS (
    SELECT uc.unit_code, dr.item_code, dr.drop_chance, false AS is_guaranteed, dr.weight, dr.notes
    FROM codex_unit_category uc
    JOIN codex_drop_rule dr ON dr.category = uc.category
),
direct_candidates AS (
    SELECT ut.unit_code, dd.item_code, dd.drop_chance, dd.is_guaranteed, dd.weight, dd.notes
    FROM codex_direct_drop dd
    JOIN unit_types ut ON ut.unit_name = dd.unit_name
     AND (dd.editor_suffix IS NULL OR ut.editor_suffix = dd.editor_suffix)
),
drop_candidates AS (
    SELECT * FROM category_candidates
    UNION ALL
    SELECT * FROM direct_candidates
),
resolved AS (
    SELECT dc.unit_code, dc.item_code,
           MAX(dc.drop_chance) AS drop_chance,
           BOOL_OR(dc.is_guaranteed) AS is_guaranteed,
           MAX(dc.weight) AS weight,
           string_agg(DISTINCT dc.notes, '; ' ORDER BY dc.notes) AS notes
    FROM drop_candidates dc
    JOIN unit_types ut ON ut.unit_code = dc.unit_code
    JOIN items i ON i.item_code = dc.item_code
    GROUP BY dc.unit_code, dc.item_code
)
UPDATE unit_specific_drops usd
SET drop_chance = GREATEST(usd.drop_chance, resolved.drop_chance),
    is_guaranteed = usd.is_guaranteed OR resolved.is_guaranteed,
    weight = GREATEST(usd.weight, resolved.weight),
    enabled = true,
    notes = resolved.notes
FROM resolved
WHERE usd.unit_code = resolved.unit_code
  AND usd.item_code = resolved.item_code;

WITH category_candidates AS (
    SELECT uc.unit_code, dr.item_code, dr.drop_chance, false AS is_guaranteed, dr.weight, dr.notes
    FROM codex_unit_category uc
    JOIN codex_drop_rule dr ON dr.category = uc.category
),
direct_candidates AS (
    SELECT ut.unit_code, dd.item_code, dd.drop_chance, dd.is_guaranteed, dd.weight, dd.notes
    FROM codex_direct_drop dd
    JOIN unit_types ut ON ut.unit_name = dd.unit_name
     AND (dd.editor_suffix IS NULL OR ut.editor_suffix = dd.editor_suffix)
),
drop_candidates AS (
    SELECT * FROM category_candidates
    UNION ALL
    SELECT * FROM direct_candidates
),
resolved AS (
    SELECT dc.unit_code, dc.item_code,
           MAX(dc.drop_chance) AS drop_chance,
           BOOL_OR(dc.is_guaranteed) AS is_guaranteed,
           MAX(dc.weight) AS weight,
           string_agg(DISTINCT dc.notes, '; ' ORDER BY dc.notes) AS notes
    FROM drop_candidates dc
    JOIN unit_types ut ON ut.unit_code = dc.unit_code
    JOIN items i ON i.item_code = dc.item_code
    GROUP BY dc.unit_code, dc.item_code
)
INSERT INTO unit_specific_drops (
    unit_code, item_code, drop_chance, min_quantity, max_quantity,
    is_guaranteed, weight, enabled, notes
)
SELECT unit_code, item_code, drop_chance, 1, 1,
       is_guaranteed, weight, true, notes
FROM resolved r
WHERE NOT EXISTS (
    SELECT 1
    FROM unit_specific_drops usd
    WHERE usd.unit_code = r.unit_code
      AND usd.item_code = r.item_code
);

WITH affected_units AS (
    SELECT DISTINCT unit_code FROM codex_unit_category
    UNION
    SELECT ut.unit_code
    FROM codex_direct_drop dd
    JOIN unit_types ut ON ut.unit_name = dd.unit_name
     AND (dd.editor_suffix IS NULL OR ut.editor_suffix = dd.editor_suffix)
)
UPDATE unit_types ut
SET loot_mode = CASE WHEN loot_mode = 'none' THEN 'specific' ELSE 'both' END,
    updated_at = NOW()
FROM affected_units au
WHERE ut.unit_code = au.unit_code;

UPDATE unit_types
SET is_boss = true,
    loot_mode = 'both',
    drop_count_min = GREATEST(drop_count_min, 1),
    drop_count_max = GREATEST(drop_count_max, 2),
    updated_at = NOW()
WHERE unit_name IN (
    'Deathlord Fel''Dok', 'Margul', 'Mur''gal', 'Unknown Entity', 'Velaria',
    'Colossus', 'Gollum', 'Sargoth', 'MordraxDummy', 'Mordrax the Desolator',
    'Rol''jin'
);

SELECT 'new_items' AS metric, COUNT(*)::text AS value
FROM items
WHERE item_code IN (SELECT item_code FROM codex_item_seed)
UNION ALL
SELECT 'new_armor_stat_rows', COUNT(*)::text
FROM item_stat_values isv
JOIN items i ON i.id = isv.item_id
WHERE i.item_code IN (SELECT item_code FROM codex_stat_seed)
UNION ALL
SELECT 'loot_table_rows_for_seed', COUNT(*)::text
FROM loot_table_items lti
WHERE lti.item_code IN (
    SELECT item_code FROM codex_item_seed
    UNION
    SELECT item_code FROM codex_extra_loot_item_seed
)
UNION ALL
SELECT 'unit_specific_rows_for_seed', COUNT(*)::text
FROM unit_specific_drops usd
WHERE usd.notes ILIKE '%OldGUI%'
   OR usd.notes ILIKE '%New %'
   OR usd.notes ILIKE '%Boss %'
   OR usd.item_code IN (SELECT item_code FROM codex_item_seed);
