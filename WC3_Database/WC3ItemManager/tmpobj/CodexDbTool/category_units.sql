SELECT unit_code, unit_name, editor_suffix, unit_level
FROM unit_types
WHERE unit_name ILIKE ANY (ARRAY[
    '%Bear%', '%Crab%', '%Crawler%', '%Rabbit%', '%Makrura%', '%Murloc%',
    '%Mur''gal%', '%Margul%', '%Lizard%', '%Storm Wyrm%', '%Salamander%',
    '%Boar%', '%Pig%', '%Frog%', '%Stag%', '%Wolf%', '%Gnoll%',
    '%Zombie%', '%Ghoul%', '%Abomination%', '%Skeleton%', '%Skeletal%',
    '%Whelp%', '%Dragon%', '%Snake%'
])
   OR editor_suffix ILIKE ANY (ARRAY[
    '%Bear%', '%Crab%', '%Crawler%', '%Rabbit%', '%Makrura%', '%Murloc%',
    '%Lizard%', '%Boar%', '%Pig%', '%Frog%', '%Stag%', '%Wolf%', '%Gnoll%',
    '%Zombie%', '%Ghoul%', '%Abomination%', '%Skeleton%', '%Whelp%', '%Dragon%', '%Snake%'
])
ORDER BY unit_name, editor_suffix, unit_level;
