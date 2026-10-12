/**
    PotSWorldProgression

    Author: Valdemar
    Version: 2.0.0

    Description:
    Persists bounded QuestMaster completion flags by stable quest-name hash
    and giver unit type, then overlays them on the current map's quest data.

    Credits:
    - StateSaver by Tomotz, current-world restoration concept

    How to install:
    Import after PotSStateData. QuestMaster is optional and must initialize its
    quest catalog before a save or load request.

    API:
    - PotSWorldProgression_Scan()
    - PotSWorldProgression_Preflight()
    - PotSWorldProgression_Apply()
    - PotSWorldProgression_GetSkippedCount()

**/
library PotSWorldProgression requires PotSSaveConfig, PotSStateData, optional QuestMaster
    globals
        private integer PWP_SkippedCount = 0
    endglobals

    static if LIBRARY_QuestMaster then
        private function PWP_GetGiverType takes QuestData q returns integer
            if q.giver == null then
                return 0
            endif
            return GetUnitTypeId(q.giver)
        endfunction

        private function PWP_FindCurrentQuest takes integer nameHash, integer giverType returns QuestData
            local integer i = 1
            local integer questId
            local QuestData q
            local QuestData result = 0

            loop
                exitwhen i > QuestMaster_GetQuestCount()
                set questId = QuestMaster_GetQuestIdByIndex(i)
                set q = QuestMaster_GetById(questId)
                if q != 0 and StringHash(q.name) == nameHash and PWP_GetGiverType(q) == giverType then
                    if result != 0 then
                        return 0
                    endif
                    set result = q
                endif
                set i = i + 1
            endloop
            return result
        endfunction
    endif

    public function GetSkippedCount takes nothing returns integer
        return PWP_SkippedCount
    endfunction

    public function Scan takes nothing returns boolean
        static if LIBRARY_QuestMaster then
            local integer i = 1
            local integer questId
            local QuestData q

            loop
                exitwhen i > QuestMaster_GetQuestCount()
                set questId = QuestMaster_GetQuestIdByIndex(i)
                set q = QuestMaster_GetById(questId)
                if q != 0 and (q.completed or q.state == QUEST_STATE_COMPLETE) then
                    if not PotSStateData_AddWorldFlagSorted(StringHash(q.name), PWP_GetGiverType(q), PotSSaveConfig_WORLD_FLAG_COMPLETED) then
                        return false
                    endif
                endif
                set i = i + 1
            endloop
        endif
        return true
    endfunction

    public function Preflight takes nothing returns boolean
        static if LIBRARY_QuestMaster then
            local integer i = 0
            local QuestData q

            set PWP_SkippedCount = 0
            loop
                exitwhen i >= PotSStateData_GetWorldCount()
                set q = PWP_FindCurrentQuest(PotSStateData_GetWorldNameHash(i), PotSStateData_GetWorldGiverType(i))
                if q == 0 then
                    set PWP_SkippedCount = PWP_SkippedCount + 1
                elseif PotSStateData_GetWorldState(i) != PotSSaveConfig_WORLD_FLAG_COMPLETED then
                    return false
                endif
                set i = i + 1
            endloop
        else
            set PWP_SkippedCount = PotSStateData_GetWorldCount()
        endif
        return true
    endfunction

    public function Apply takes nothing returns nothing
        static if LIBRARY_QuestMaster then
            local integer i = 0
            local QuestData q

            loop
                exitwhen i >= PotSStateData_GetWorldCount()
                set q = PWP_FindCurrentQuest(PotSStateData_GetWorldNameHash(i), PotSStateData_GetWorldGiverType(i))
                if q != 0 then
                    set q.discovered = true
                    set q.discoveryPending = false
                    set q.active = false
                    set q.completed = true
                    set q.failed = false
                    set q.state = QUEST_STATE_COMPLETE
                    set q.lastEvalState = QUEST_STATE_COMPLETE
                    if q.wcQuest != null then
                        call QuestSetDiscovered(q.wcQuest, true)
                        call QuestSetCompleted(q.wcQuest, true)
                    endif
                    call q.refreshQuestLog()
                    call q.updateIcons()
                endif
                set i = i + 1
            endloop
        endif
    endfunction
endlibrary
