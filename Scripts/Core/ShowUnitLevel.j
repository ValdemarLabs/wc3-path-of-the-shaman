library ShowUnitLevel initializer Init requires optional FrameLoader
// ShowUnitLevel V1.2 by Tasyen
// Display unit Level for non creeps

// requires 
// war3mapImported\ShowUnitLevel.fdf
// war3mapImported\ShowUnitLevel.toc
globals
    private group Group
    private race RaceCreep = ConvertRace(8)
    private unit Unit
endglobals

    private function FilterFunc takes nothing returns boolean
        return not IsUnitType(Unit, UNIT_TYPE_STRUCTURE) and not IsHeroUnitId(GetUnitTypeId(Unit)) and GetUnitRace(Unit) != RaceCreep
    endfunction
    private function Update takes nothing returns nothing
        local string text = ""
        call GroupEnumUnitsSelected(Group, GetLocalPlayer(), null)
        set Unit = FirstOfGroup(Group)
        call GroupClear(Group)

        if FilterFunc() then
            // display custom
            call BlzFrameSetAlpha(BlzGetFrameByName("SimpleUnitStatsPanel", 0), 0)
            if BlzFrameGetText(BlzGetFrameByName("SimpleClassValue", 0)) != " " then
                set text = BlzFrameGetText(BlzGetFrameByName("SimpleClassValue", 0)) + " "
            endif
            set text =  text + GetLocalizedString("LEVEL") + " " + I2S(GetUnitLevel(Unit))
            call BlzFrameSetText(BlzGetFrameByName("CustomSimpleClassValue", 0), text)
        else
            // reset
            call BlzFrameSetAlpha(BlzGetFrameByName("SimpleUnitStatsPanel", 0), 255)
            call BlzFrameSetText(BlzGetFrameByName("CustomSimpleClassValue", 0), "")
        endif
        set Unit = null
    endfunction
    private function InitFrames takes nothing returns nothing
        call TimerStart(GetExpiredTimer(), 0.02, true, function Update)
        // load in the frame blueprint
        call BlzLoadTOCFile("war3mapImported/ShowUnitLevel.toc")

        // reserve handleIds for this frames that are used in async manner
        call BlzGetFrameByName("SimpleUnitStatsPanel", 0)
        call BlzGetFrameByName("SimpleClassValue", 0)

        // create custom Level display
        call BlzCreateSimpleFrame("CustomSimpleUnitStatsPanel", BlzGetFrameByName("SimpleInfoPanelUnitDetail", 0), 0)
        // reserve handleId, async manner
        call BlzGetFrameByName("CustomSimpleClassValue", 0)     
    endfunction
    private function Init takes nothing returns nothing
        set Group = CreateGroup()
        call TimerStart(CreateTimer(), 0.0, false, function InitFrames)

        static if LIBRARY_FrameLoader then
            call FrameLoaderAdd(function InitFrames)
        endif
    endfunction
endlibrary
