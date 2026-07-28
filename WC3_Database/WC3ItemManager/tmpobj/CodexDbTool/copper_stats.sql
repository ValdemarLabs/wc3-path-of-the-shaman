SELECT i.item_code, i.item_name, i.class_id, c.class_name, i.rarity_id, r.rarity_name,
       i.item_level, i.wc3_abilities, s.id AS stat_id, s.stat_code, s.stat_name,
       isv.stat_value, isv.sort_order
FROM items i
LEFT JOIN item_classes c ON c.id = i.class_id
LEFT JOIN item_rarities r ON r.id = i.rarity_id
LEFT JOIN item_stat_values isv ON isv.item_id = i.id
LEFT JOIN item_stats s ON s.id = isv.stat_id
WHERE i.item_code IN ('I68F','I68G','I68H','I68I','I68J','I68K','I68L','I68M',
                      'I65X','I65Y','I65Z','I660','I661','I662','I66F')
ORDER BY i.item_code, isv.sort_order, s.id;

SELECT item_code, item_name, type_id, rarity_id, class_id, item_level, required_level,
       max_charges, max_stack, gold_cost, sell_value, is_droppable, is_sellable,
       is_pawnable, is_perishable, dinv_compatible, deq_compatible, wc3_classification,
       item_level_unclassified, specific_drop_only, tooltip, tooltip_extended
FROM items
WHERE item_code IN ('I68F','I68G','I68H','I68I','I68J','I68K','I68L','I68M',
                    'I6AR','I61O','I614','I6AE','I69A','I00S')
ORDER BY item_code;
