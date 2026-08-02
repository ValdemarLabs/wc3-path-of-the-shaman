/**
    QuestsGenericTest

    Author: Valdemar
    Version: 1.0.0

    Description:
    Focused manual test harness proving that a non-vendor NPC can register and
    instantiate a QuestsGeneric template without Shop or vendor dependencies.

    Credits:

    How to install:
    Import after QuestsGeneric in a test map only. Call
    QuestsGenericTest_RegisterNPC with a placed non-vendor unit.

    API:
    - QuestsGenericTest_RegisterNPC(giver, displayName) creates the test quest.

**/
library QuestsGenericTest requires QuestsGeneric
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
        call QuestsGeneric_RegisterUnit(giver, displayName)
        set giver = null
    endfunction
endlibrary
