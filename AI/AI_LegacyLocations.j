/**
    AI_LegacyLocations

    Author: Valdemar
    Version:

    Description:
    Map-specific binding for old GUI AI spawn, retreat, and shop arrays. The
    master AI profiles stay generic; this library maps the old generated rect
    and unit globals into profile Table state.

    Credits:
    - Old GUI AI Init Locations triggers

    How to install:
    Import after `AI.j` and the first-wave `AI_*` profile libraries. This file
    references generated map globals and should be compiled with the full map.

    API:
    Automatic initializer only.

**/
library AILegacyLocations initializer Init requires AI, AIWarrior, AIRogue, AIWarlock, AIRestoshaman, AIPaladin, AIEngineer, AIAveline

private function AddHordeSpawns takes integer profileId returns nothing
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace01)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace02)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace03)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace04)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace05)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace06)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace07)
    call AI_AddProfileSpawnRect(profileId, gg_rct_HordeWandererSpawningPlace08)
endfunction

private function AddHordeRetreats takes integer profileId returns nothing
    call AI_AddProfileRetreatRect(profileId, gg_rct_LeavedFromArena)
    call AI_AddProfileRetreatRect(profileId, gg_rct_HordeWandererSpawningPlace01)
    call AI_AddProfileRetreatRect(profileId, gg_rct_CannotGoThere03a)
    call AI_AddProfileRetreatRect(profileId, gg_rct_Forge002)
    call AI_AddProfileRetreatRect(profileId, gg_rct_HordeFarm)
    call AI_AddProfileRetreatRect(profileId, gg_rct_HordeMountainCamp)
    call AI_AddProfileRetreatRect(profileId, gg_rct_HordeFarm)
    call AI_AddProfileRetreatRect(profileId, gg_rct_ErdukMovingPosition02)
    call AI_AddProfileRetreatRect(profileId, gg_rct_Test02FelOrcAttackPoint)
    call AI_AddProfileRetreatRect(profileId, gg_rct_Graveyard)
    call AI_AddProfileRetreatRect(profileId, gg_rct_Graveyard02)
    call AI_AddProfileRetreatRect(profileId, gg_rct_Graveyard03)
endfunction

private function AddHordeShops takes integer profileId returns nothing
    call AI_AddProfileShopUnit(profileId, gg_unit_nmrk_1491)
    call AI_AddProfileShopUnit(profileId, gg_unit_o609_0021)
    call AI_AddProfileShopUnit(profileId, gg_unit_o62J_1931)
    call AI_AddProfileShopUnit(profileId, gg_unit_o61U_1278)
endfunction

private function AddRiverbaneSpawns takes integer profileId returns nothing
    call AI_AddProfileSpawnRect(profileId, gg_rct_RiverbaneHeroSpawn1)
    call AI_AddProfileSpawnRect(profileId, gg_rct_RiverbaneHeroSpawn2)
endfunction

private function AddRiverbaneRetreats takes integer profileId returns nothing
    call AI_AddProfileRetreatRect(profileId, gg_rct_RiverbaneRetreat1)
    call AI_AddProfileRetreatRect(profileId, gg_rct_RiverbaneRetreat2)
    call AI_AddProfileRetreatRect(profileId, gg_rct_RiverbaneRetreat3)
    call AI_AddProfileRetreatRect(profileId, gg_rct_RiverbaneRetreat4)
endfunction

private function AddNeutralSpawns takes integer profileId returns nothing
    call AI_AddProfileSpawnRect(profileId, gg_rct_NeutralHeroSpawn1)
    call AI_AddProfileSpawnRect(profileId, gg_rct_NeutralHeroSpawn2)
    call AI_AddProfileSpawnRect(profileId, gg_rct_NeutralHeroSpawn3)
endfunction

private function BindHordeProfile takes integer profileId returns nothing
    call AddHordeSpawns(profileId)
    call AddHordeRetreats(profileId)
    call AddHordeShops(profileId)
endfunction

private function BindNeutralProfile takes integer profileId returns nothing
    call AddNeutralSpawns(profileId)
    call AddHordeRetreats(profileId)
    call AddHordeShops(profileId)
endfunction

private function BindRiverbaneProfile takes integer profileId returns nothing
    call AddRiverbaneSpawns(profileId)
    call AddRiverbaneRetreats(profileId)
    call AddHordeShops(profileId)
endfunction

private function Init takes nothing returns nothing
    call BindHordeProfile(AI_Warrior_ProfileId)
    call BindHordeProfile(AI_Rogue_ProfileId)
    call BindHordeProfile(AI_Warlock_ProfileId)
    call BindHordeProfile(AI_Restoshaman_ProfileId)
    call BindRiverbaneProfile(AI_Paladin_ProfileId)
    call BindRiverbaneProfile(AI_Aveline_ProfileId)
    call BindNeutralProfile(AI_Engineer_ProfileId)
    call BindNeutralProfile(AI_Engineer_ShredderProfileId)
endfunction

endlibrary
