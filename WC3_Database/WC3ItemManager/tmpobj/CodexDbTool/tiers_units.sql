SELECT id, tier_name, min_unit_level, max_unit_level, drop_chance_base,
       common_weight, common_item_level,
       uncommon_weight, uncommon_item_level,
       rare_weight, rare_item_level,
       epic_weight, epic_item_level,
       legendary_weight, legendary_item_level,
       artifact_weight, artifact_item_level,
       enabled
FROM loot_tiers
ORDER BY min_unit_level, max_unit_level;

SELECT item_code, item_name
FROM items
WHERE lower(regexp_replace(item_name, '\|c[0-9A-Fa-f]{8}|\|r', '', 'g')) IN (
    'large hoof', 'sharp claw', 'small flame sac', 'ruined dragonhide',
    'phat lewt', 'rotten part', 'raw rabbit meat', 'rabbit foot',
    'makrura claw', 'cracked shell', 'lizard scale'
)
ORDER BY item_name;

SELECT unit_code, unit_name, editor_suffix, unit_level
FROM unit_types
WHERE unit_name ILIKE ANY (ARRAY[
    '%Timber Wolf%', '%Giant Wolf%', '%Dire Wolf%', '%Wolf%',
    '%Stag%', '%Rabbit%', '%Makrura%', '%Lizard%', '%Storm Wyrm%', '%Salamander%',
    '%Crab%', '%Crawler%', '%Murloc%', '%Mur''gal%', '%Margul%',
    '%Zombie%', '%Ghoul%', '%Abomination%', '%Skeleton%', '%Skeletal%',
    '%Gnoll%', '%Whelp%', '%Dragon%', '%Boar%', '%Pig%', '%Snake%', '%Frog%',
    '%Deathlord Fel%','%Colossus%','%Gollum%','%Mordrax%','%Sargoth%',
    '%Unknown Entity%','%Velaria%','%Rol''jin%'
])
ORDER BY unit_name, editor_suffix, unit_level;
