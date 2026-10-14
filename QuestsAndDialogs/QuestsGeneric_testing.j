/**
    QuestsGenericTest

    Author: Valdemar
    Version: 2.0.2

    Description:
    Focused manual test harness for standalone non-vendor NPCs and notice
    boards. It covers a separate receiver plus combined kill, gather, and find
    objectives without Shop or vendor dependencies.

    Credits:

    How to install:
    Import after QuestsGenericDialog in a test map only.

    API:
    - QuestsGenericTest_RegisterNPC(giver, displayName) creates the test quest.
    - QuestsGenericTest_RegisterNoticeBoardScenario(...) creates the combined
      notice-board test and registers its remote receiver and find target.

**/
library QuestsGenericTest requires QuestsGenericDialog
    globals
        private boolean QGT_TemplateRegistered = false
    endglobals

    public function RegisterNPC takes unit giver, string displayName returns nothing
        local integer definitionId

        if giver == null then
            set giver = null
            return
        endif
        if not QGT_TemplateRegistered then
            set definitionId = QuestsGeneric_RegisterKillQuest(GetUnitTypeId(giver), "Generic Quest Test", "normal", 1, "Generic Quest Test", "ReplaceableTextures\\CommandButtons\\BTNGnoll.blp", "Defeat one gnoll for a non-vendor quest giver.", 'ngno', 1, 1, "", 0, "One gnoll is troubling the road. Deal with it.", "The road is quiet again.")
            call QuestsGeneric_SetExtendedDialogue(definitionId, "Return when the path is safe.", 0, "You have proven the generic quest path works.", 0)
            set QGT_TemplateRegistered = true
        endif
        call QuestsGenericDialog_RegisterNPC(giver, displayName)
        set giver = null
    endfunction

    public function RegisterNoticeBoardScenario takes unit noticeBoard, string boardName, unit receiver, string receiverName, unit missingPerson, string missingPersonName returns nothing
        local integer definitionId

        if noticeBoard == null or receiver == null or missingPerson == null then
            set noticeBoard = null
            set receiver = null
            set missingPerson = null
            return
        endif
        if GetUnitTypeId(noticeBoard) != QuestsGenericDialog_WANTED_POST_UNIT_TYPE then
            set noticeBoard = null
            set receiver = null
            set missingPerson = null
            return
        endif
        set definitionId = QuestsGeneric_RegisterKillQuest(QuestsGenericDialog_WANTED_POST_UNIT_TYPE, "Notice Board Combination Test", "normal", 1, "Missing Gatherer", "ReplaceableTextures\\CommandButtons\\BTNScroll.blp", "Clear the road, gather the requested flowers, and find the missing gatherer before reporting elsewhere.", 'ngno', 2, 1, "", 0, "The notice lists a dangerous road, four flowers, and a missing gatherer.", "The work described on the notice is complete.")
        call QuestsGeneric_SetGiverUnit(definitionId, noticeBoard)
        call QuestsGeneric_AddFetchObjective(definitionId, 'I60Y', 4)
        call QuestsGeneric_AddFindObjective(definitionId, GetUnitTypeId(missingPerson), missingPersonName)
        call QuestsGeneric_SetObjectiveTargetUnit(definitionId, 3, missingPerson)
        call QuestsGeneric_SetReceiverUnit(definitionId, receiver, receiverName)
        call QuestsGeneric_SetReceiverDialogue(definitionId, "", 0, "You handled every request on that notice. Here is the promised reward.")
        call QuestsGeneric_RegisterUnit(missingPerson, missingPersonName)
        call QuestsGenericDialog_RegisterNPC(receiver, receiverName)
        call QuestsGenericDialog_RegisterWantedPost(noticeBoard, boardName)
        set noticeBoard = null
        set receiver = null
        set missingPerson = null
    endfunction
endlibrary
