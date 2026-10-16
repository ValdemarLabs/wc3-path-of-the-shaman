# Save and Load Guide

Path of the Shaman provides custom character saves alongside Warcraft III's normal **Save Game** feature. Native saves can still be used, but Warcraft III engine limitations may make them incompatible after the map is updated to a newer version. The custom system is designed to restore supported progress across compatible map updates.

## Saving and loading

- Open **Menu (F10)** and choose the Save / Load option during play.
- Choose one of the six local save slots and wait for the save-completed message.
- To continue later, choose **Load Saved** on the first menu and select the slot.
- Saves are stored locally on the computer that created them, in Warcraft III's permitted custom-map storage under the `Path of the Shaman` folder.

## What is restored

- Nazgrek and, if unlocked and saved, Zul'kis.
- Hero level, experience, attributes, and available skill or ability points.
- Learned permanent abilities.
- Normal inventory items, item slots, and charges.
- Custom bag items and equipped items, including their slots and charges.
- Gold and lumber.
- Current health and mana percentages.
- Completed supported quests.

After loading, the player party and companions begin at Nazgrek's hut. The current map version then continues normally.

## What is not restored

- The exact old map state, hero location, enemies, loose world items, or destroyed objects.
- Quests that were still in progress. Only completed supported quests are restored.
- Temporary abilities, active buffs, timers, or temporary scene state.
- Stash or bank contents and unsupported custom item properties such as affixes.
- Private story state that is not tracked by the quest system.

New content and current map defaults remain active after loading an older save.

## Loading saves after a map update

Older saves should normally continue to work after terrain changes, new content, balance updates, and script changes. They are not tied to Warcraft III's native map checksum.

An older save may not work when:

- The Warcraft III player/profile name is different.
- The save file is missing, moved, truncated, edited, or corrupted.
- The save-system key or code version changed.
- A saved hero, ability, or item was removed or renamed without a compatibility migration.
- An ability's maximum level or available inventory capacity was reduced below the saved state.
- The save was created by a newer, unsupported save format.

If loading fails before anything is restored, return to the first menu and choose another slot or **New Game**. If the game reports that loading failed after applying part of the save, restart the map before trying again.
