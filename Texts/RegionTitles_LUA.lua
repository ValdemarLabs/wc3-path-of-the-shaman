if Debug then Debug.beginFile "RegionTitles" end
do
    --[[
    =============================================================================================================================================================
                                                                       Region Titles
                                                                        by Antares

                Shows the names of map regions in a WoW-like style as the player enters them. Suited for an rpg map with a locked camera.

                                Requires:
                                TotalInitialization			    https://www.hiveworkshop.com/threads/.317099/
                                ALICE                           https://www.hiveworkshop.com/threads/.353126/
                                Camera CAT                      Included in ALICE.
                                Rects CAT                       Included in ALICE.
                                RegionTitle.fdf                 Included in Test Map.
                                RegionTitle.toc                 Included in Test Map.

    =============================================================================================================================================================

    To import, copy this script and its requirements. Import the RegionTitle.fdf and RegionTitle.toc without a subpath.

    To create titled regions, add their names to the REGIONS table. Then, create rects with the World Editor that determine the extents of those regions. Creating
    rects with code before RegionTitles initializes also works. Another option are tables with the minX, minY, maxX, and maxY fields. The variables must be globals
    with names equal to the regions' names, but with all special characters and color codes removed, and formatting converted to camelCase. Example:

    King's Plaza -> kingsPlaza
    |cffff0000Throne of Ash-Gazhur|r -> throneOfAshGazhur

    The name is followed by an integer if there are multiple rects for one titled region (kingsPlaza1, kingsPlaza2 etc.).

    Titled regions have priorities. Within the REGIONS table, you add regions in ascending order of priority. If two regions are intersecting, the one with the
    higher priority overshadows the other. This means that you can create a region that encompasses the entire map, call it, for example, "Kalimdor", and put it
    at the first position in the table. Now, whenever the player is in no other region, "Kalimdor" will pop up.

    This system is DISABLED BY DEFAULT. Enable it with EnableRegionTitles(). If necessary, disable it for cinematics with EnableRegionTitles(false).

    To change font size, edit the FrameFont field in the RegionTitle.fdf file.

    =============================================================================================================================================================
                                                                        C O N F I G
    =============================================================================================================================================================
    ]]

    local TITLE_Y                       = 0.45          ---@constant number

    local TITLE_FADE_IN_TIME            = 1.2           ---@constant number
    local TITLE_DURATION                = 1.5           ---@constant number
    local TITLE_FADE_OUT_TIME           = 3.0           ---@constant number

    local REGIONS = {                                   ---@constant string[]
        "|cff00ff00King's Plaza|r",
        "|cffffcc00Deren's Crossing|r",
        "|cffffcc00North Road|r",
        "|cffff0000The Veiled Path|r",
        "|cffffcc00East Road|r",
        "|cff00ff00The Drunken Murloc"
    }

    local ON_REGION_ENTER
    local ON_REGION_LEAVE

    local function InitZoneTriggers()
        --RUNS ASYNCHRONOUSLY!!! Functions that are executed when a player enters a titled region. The keys are the converted region names. You can use the other keyword
        --to denote a function that is executed for each region that isn't specifically listed. In multiplayer maps, only run async-safe code within the functions (such as
        --playing music, showing frames etc.)
        ON_REGION_ENTER = {                           ---@constant table<string,function>
            theDrunkenMurloc = PlayTavernMusic,
            other = nil
        }

        --RUNS ASYNCHRONOUSLY!!! Same as ON_REGION_ENTER, but is executed when a player leaves a titled region.
        ON_REGION_LEAVE = {                           ---@constant table<string,function>
            theDrunkenMurloc = ResetMusic,
            other = nil
        }
    end

    --[[
    =============================================================================================================================================================
                                                                  E N D   O F   C O N F I G
    =============================================================================================================================================================
    ]]

    local REGION_PRIORITY = {}              ---@type table<string,integer>

    local currentRegion                     ---@type string | nil
    local numRectsOfRegion = {}             ---@type table<string,integer>
    local titleFrame                        ---@type framehandle
    local titleFrameChildren = {}           ---@type framehandle[]
    local titleTime                         ---@type number
    local isFirstRegion = true              ---@type boolean
    local regionTitlesEnabled = false       ---@type boolean
    local lastPopup = nil                   ---@type string
    local fadeActive = nil                  ---@type boolean

    local function ToUpperCase(__, letter)
        return letter:upper()
    end

    local function ToCamelCase(whichString)
        whichString = whichString:gsub("|[cC]\x25x\x25x\x25x\x25x\x25x\x25x\x25x\x25x", "")
        whichString = whichString:gsub("|[rR]", "")
        whichString = whichString:gsub("[^\x25w]", "")
        whichString = whichString:gsub("\x25s(\x25d)", "\x251")
        whichString = whichString:gsub("(\x25s)(\x25a)", ToUpperCase)
        return string.lower(whichString:sub(1,1)) .. string.sub(whichString,2)
    end

    local function FadeTitle()
        titleTime = titleTime + ALICE_Config.MIN_INTERVAL
        if titleTime < TITLE_FADE_IN_TIME then
            BlzFrameSetAlpha(titleFrame, (255*(titleTime/TITLE_FADE_IN_TIME)^2) // 1)
        elseif titleTime < TITLE_FADE_IN_TIME + TITLE_DURATION then
            BlzFrameSetAlpha(titleFrame, 255)
        elseif titleTime < TITLE_FADE_IN_TIME + TITLE_DURATION + TITLE_FADE_OUT_TIME then
            BlzFrameSetAlpha(titleFrame, (255*(1 - (titleTime - TITLE_FADE_IN_TIME - TITLE_DURATION)/TITLE_FADE_OUT_TIME)^2) // 1)
        else
            BlzFrameSetVisible(titleFrame, false)
            ALICE_DisableCallback()
            fadeActive = false
        end
    end

    local function TitledRegionOnEnter(regionChecker, titledRegion)
        numRectsOfRegion[titledRegion.name] = (numRectsOfRegion[titledRegion.name] or 0) + 1
    end

    local function TitledRegionPeriodic(regionChecker, titledRegion)
        if currentRegion == nil or REGION_PRIORITY[titledRegion.name] > REGION_PRIORITY[currentRegion] then
            currentRegion = titledRegion.name
            if isFirstRegion then
                isFirstRegion = false
                return
            end

            if not regionTitlesEnabled then
                return
            end

            local func = ON_REGION_ENTER[ToCamelCase(currentRegion)] or ON_REGION_ENTER.other
            if func then
                func(currentRegion)
            end

            if lastPopup == currentRegion then
                return
            end

            titleTime = 0
            for __, frame in ipairs(titleFrameChildren) do
                BlzFrameSetText(frame, currentRegion)
            end
            BlzFrameSetVisible(titleFrame, true)
            BlzFrameSetAlpha(titleFrame, 0)
            if not fadeActive then
                ALICE_CallPeriodic(FadeTitle)
                fadeActive = true
            end
            lastPopup = currentRegion
        end
    end

    local function TitledRegionOnLeave(regionChecker, titledRegion)
        numRectsOfRegion[titledRegion.name] = (numRectsOfRegion[titledRegion.name] or 0) - 1
        if numRectsOfRegion[titledRegion.name] == 0 and currentRegion == titledRegion.name then
            currentRegion = nil
            local func = ON_REGION_LEAVE[ToCamelCase(titledRegion.name)] or ON_REGION_LEAVE.other
            if func then
                func(titledRegion.name)
            end
        end
    end

    local function AfterAliceInit()
        Require "ALICE"
        Require "CAT_Camera"

        if not BlzLoadTOCFile("RegionTitle.toc") then
            error("|cffff0000Warning:|r RegionTitle.toc failed to load.")
            return
        end

        InitZoneTriggers()

        titleFrame = BlzCreateFrame("RegionTitle", BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0), 0, 0)
        BlzFrameSetAbsPoint(titleFrame, FRAMEPOINT_CENTER, 0.4, TITLE_Y)
        BlzFrameSetEnable(titleFrame, false)
        BlzFrameSetSize(titleFrame, 0.4, 0.1)
        for i = 1, 4 do
            titleFrameChildren[i] = BlzFrameGetChild(titleFrame, i - 1)
            BlzFrameSetTextAlignment(titleFrameChildren[i], TEXT_JUSTIFY_MIDDLE, TEXT_JUSTIFY_CENTER)
            BlzFrameSetEnable(titleFrameChildren[i], false)
        end

        local i, rect, rectName
        for index, region in ipairs(REGIONS) do
            REGION_PRIORITY[region] = index

            rectName = ToCamelCase(region)
            rect = _G["gg_rct_" .. rectName .. 1] or _G["gg_rct_" .. rectName] or _G[rectName .. 1] or _G[rectName]

            if not rect then
                print("|cffff0000Warning:|r No rects found for " .. region .. ". Expected rect name is " .. rectName .. ".")
            end

            local titledRegion = {
                identifier = "titledRegion",
                onEnter = TitledRegionOnEnter,
                onLeave = TitledRegionOnLeave,
                onPeriodic = TitledRegionPeriodic,
                interval = 0.2,
                name = region
            }

            i = 1
            while rect do
                CAT_CreateFromRect(rect, titledRegion)
                i = i + 1
                rect = _G["gg_rct_" .. rectName .. i] or _G[rectName .. i]
            end
        end

        local regionChecker = {
            identifier = "regionChecker",
            interactions = {titledRegion = CAT_RectCheck},
            anchor = CAT_Camera,
            radius = 0
        }

        ALICE_Create(regionChecker)
    end

    OnInit.final("RegionTitles", AfterAliceInit)

    --===========================================================================================================================================================
    --API
    --===========================================================================================================================================================

    ---@param enable? boolean
    function EnableRegionTitles(enable)
        regionTitlesEnabled = enable ~= false
    end
end