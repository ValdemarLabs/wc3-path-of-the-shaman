/**
    IconQuery

    Author: Valdemar
    Version:

    Description:
    Centralized minimap icon and ping query scheduler for quest, travel, boss,
    place-of-interest, and optional companion/follower map markers. Registered
    icons are kept hidden and revealed one at a time to avoid map overlap.

    Credits:
    Blizzard campaign minimap icon helpers.

    How to install:
    Import this library before systems that register query icons. Replace old
    GUI minimap-icon toggle triggers with calls to the public registration API.

    API:
    call IconQuery_RegisterQuestGiverUnitIcon(unit u, integer style)
    call IconQuery_RegisterFlightMasterUnitIcon(unit u)
    call IconQuery_RegisterShipMasterUnitIcon(unit u)
    call IconQuery_RegisterFlightMasterPoint(real x, real y)
    call IconQuery_RegisterShipMasterPoint(real x, real y)
    call IconQuery_RegisterShipPathPoint(real x, real y)
    call IconQuery_RegisterBossUnitIcon(unit u)
    call IconQuery_RegisterPlaceOfInterest(real x, real y, integer style)
    call IconQuery_RegisterExistingIcon(minimapicon icon, real x, real y, integer category, integer style, boolean enablePing)
    call IconQuery_UnregisterIcon(minimapicon icon)
    call IconQuery_SetCategoryEnabled(integer category, boolean enabled)
    call IconQuery_SetAllEnabled(boolean enabled)
    call IconQuery_SetQueryTime(real seconds)
    call IconQuery_SetQueryRestTime(real seconds)
    call IconQuery_SetCategoryQueryTime(integer category, real seconds)
    call IconQuery_ClearCategoryQueryTime(integer category)
    call IconQuery_SetCategoryFrequency(integer category, integer everyRounds)
    call IconQuery_SetSecondaryCategoryFrequency(integer everyRounds)

**/
library IconQuery initializer Init requires Table
    globals
        // Public category IDs used by SettingsUI and GUI custom script bridges.
        constant integer ICONQUERY_CATEGORY_QUEST_GIVERS = 1
        constant integer ICONQUERY_CATEGORY_FLIGHT_MASTER = 2
        constant integer ICONQUERY_CATEGORY_BOSSES = 3
        constant integer ICONQUERY_CATEGORY_PLACES_OF_INTEREST = 4
        constant integer ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS = 5

        // Query timing configuration.
        private constant integer IQ_CATEGORY_COUNT = 5
        private constant integer IQ_MAX_ENTRIES = 2048
        private constant real IQ_QUERY_TIME_MIN = 0.50
        private constant real IQ_QUERY_TIME_MAX = 15.00
        private constant real IQ_QUERY_REST_MIN = 5.00
        private constant real IQ_QUERY_REST_MAX = 120.00
        private constant real IQ_START_DELAY = 0.03
        private constant real IQ_DEFAULT_QUERY_TIME = 4.00
        private constant real IQ_DEFAULT_QUERY_REST_TIME = 45.00
        private constant real IQ_PING_DURATION = 1.25
        private constant integer IQ_CATEGORY_FREQUENCY_MIN = 1
        private constant integer IQ_CATEGORY_FREQUENCY_MAX = 5

        private boolean IQ_Initialized = false
        private boolean IQ_AllEnabled = true
        private boolean IQ_TimerRunning = false
        private boolean IQ_QueryResting = false
        private boolean array IQ_CategoryEnabled

        private real IQ_QueryTime = IQ_DEFAULT_QUERY_TIME
        private real IQ_QueryRestTime = IQ_DEFAULT_QUERY_REST_TIME
        private timer IQ_QueryTimer = null
        private integer IQ_QueryCategory = ICONQUERY_CATEGORY_QUEST_GIVERS
        private integer array IQ_CategoryCursor
        private integer array IQ_CategoryRoundCounter
        private integer array IQ_CategoryFrequency
        private real array IQ_CategoryQueryTime
        private integer IQ_ActiveEntry = 0

        private integer IQ_EntryCount = 0
        private minimapicon array IQ_EntryIcon
        private unit array IQ_EntryUnit
        private boolean array IQ_EntryUsesUnit
        private real array IQ_EntryX
        private real array IQ_EntryY
        private integer array IQ_EntryCategory
        private integer array IQ_EntryStyle
        private boolean array IQ_EntryPing

        private Table IQ_IconIndex = 0
    endglobals

    private function IQ_ClampReal takes real value, real minValue, real maxValue returns real
        if value < minValue then
            return minValue
        endif
        if value > maxValue then
            return maxValue
        endif
        return value
    endfunction

    private function IQ_ClampInt takes integer value, integer minValue, integer maxValue returns integer
        if value < minValue then
            return minValue
        endif
        if value > maxValue then
            return maxValue
        endif
        return value
    endfunction

    private function IQ_IsCategoryValid takes integer category returns boolean
        return category >= ICONQUERY_CATEGORY_QUEST_GIVERS and category <= ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS
    endfunction

    private function IQ_GetCategoryQueryTime takes integer category returns real
        if IQ_IsCategoryValid(category) and IQ_CategoryQueryTime[category] > 0.00 then
            return IQ_CategoryQueryTime[category]
        endif
        return IQ_QueryTime
    endfunction

    private function IQ_GetEntryQueryTime takes integer entryIndex returns real
        if entryIndex > 0 and entryIndex <= IQ_EntryCount then
            return IQ_GetCategoryQueryTime(IQ_EntryCategory[entryIndex])
        endif
        return IQ_QueryTime
    endfunction

    private function IQ_ShouldScanCategory takes integer category returns boolean
        local integer frequency

        if not IQ_IsCategoryValid(category) then
            return false
        endif

        set frequency = IQ_CategoryFrequency[category]
        if frequency <= 1 then
            return true
        endif
        return ModuloInteger(IQ_CategoryRoundCounter[category], frequency) == 0
    endfunction

    private function IQ_MarkCategoryRoundComplete takes integer category returns nothing
        if not IQ_IsCategoryValid(category) then
            return
        endif
        set IQ_CategoryCursor[category] = 0
        set IQ_CategoryRoundCounter[category] = IQ_CategoryRoundCounter[category] + 1
        if IQ_CategoryRoundCounter[category] >= 100000 then
            set IQ_CategoryRoundCounter[category] = 0
        endif
    endfunction

    private function IQ_NextCategory takes integer category returns integer
        if category >= ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS then
            return ICONQUERY_CATEGORY_QUEST_GIVERS
        endif
        return category + 1
    endfunction

    private function IQ_IsUnitValid takes unit u returns boolean
        return u != null and GetUnitTypeId(u) != 0 and not IsUnitType(u, UNIT_TYPE_DEAD)
    endfunction

    private function IQ_GetPingRed takes integer style, integer category returns integer
        if style == bj_CAMPPINGSTYLE_BOSS or style == bj_CAMPPINGSTYLE_CONTROL_ENEMY or style == bj_CAMPPINGSTYLE_PRIMARY_RED then
            return 255
        endif
        if style == bj_CAMPPINGSTYLE_CONTROL_ALLY or style == bj_CAMPPINGSTYLE_PRIMARY_GREEN then
            return 0
        endif
        if category == ICONQUERY_CATEGORY_BOSSES then
            return 255
        endif
        if category == ICONQUERY_CATEGORY_FLIGHT_MASTER then
            return 0
        endif
        return 255
    endfunction

    private function IQ_GetPingGreen takes integer style, integer category returns integer
        if style == bj_CAMPPINGSTYLE_BOSS or style == bj_CAMPPINGSTYLE_CONTROL_ENEMY or style == bj_CAMPPINGSTYLE_PRIMARY_RED then
            return 0
        endif
        if style == bj_CAMPPINGSTYLE_CONTROL_ALLY or style == bj_CAMPPINGSTYLE_PRIMARY_GREEN then
            return 255
        endif
        if category == ICONQUERY_CATEGORY_FLIGHT_MASTER then
            return 255
        endif
        if category == ICONQUERY_CATEGORY_BOSSES then
            return 0
        endif
        return 255
    endfunction

    private function IQ_GetPingBlue takes integer style, integer category returns integer
        if style == bj_CAMPPINGSTYLE_CONTROL_NEUTRAL then
            return 255
        endif
        if category == ICONQUERY_CATEGORY_PLACES_OF_INTEREST then
            return 255
        endif
        return 0
    endfunction

    private function IQ_CreateUnitIcon takes unit u, integer style returns minimapicon
        call CampaignMinimapIconUnitBJ(u, style)
        return GetLastCreatedMinimapIcon()
    endfunction

    private function IQ_CreatePointIcon takes real x, real y, integer style returns minimapicon
        local location loc = Location(x, y)
        local minimapicon icon

        call CampaignMinimapIconLocBJ(loc, style)
        set icon = GetLastCreatedMinimapIcon()
        if icon != null then
            call SetMinimapIconOrphanDestroy(icon, true)
        endif
        call RemoveLocation(loc)
        set loc = null
        return icon
    endfunction

    private function IQ_SetEntryVisible takes integer entryIndex, boolean visible returns nothing
        if entryIndex > 0 and entryIndex <= IQ_EntryCount and IQ_EntryIcon[entryIndex] != null then
            call SetMinimapIconVisible(IQ_EntryIcon[entryIndex], visible)
        endif
    endfunction

    private function IQ_HideActive takes nothing returns nothing
        if IQ_ActiveEntry > 0 then
            call IQ_SetEntryVisible(IQ_ActiveEntry, false)
            set IQ_ActiveEntry = 0
        endif
    endfunction

    private function IQ_ResetCategoryCursors takes nothing returns nothing
        local integer category = ICONQUERY_CATEGORY_QUEST_GIVERS

        loop
            exitwhen category > ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS
            set IQ_CategoryCursor[category] = 0
            set category = category + 1
        endloop
        set IQ_QueryCategory = ICONQUERY_CATEGORY_QUEST_GIVERS
    endfunction

    private function IQ_IsEntryCandidate takes integer entryIndex returns boolean
        local integer category

        if entryIndex <= 0 or entryIndex > IQ_EntryCount then
            return false
        endif

        set category = IQ_EntryCategory[entryIndex]
        if not IQ_IsCategoryValid(category) or not IQ_CategoryEnabled[category] then
            return false
        endif
        if IQ_EntryIcon[entryIndex] == null then
            return false
        endif
        if IQ_EntryUsesUnit[entryIndex] and not IQ_IsUnitValid(IQ_EntryUnit[entryIndex]) then
            return false
        endif
        return true
    endfunction

    private function IQ_HasAnyQueryableEntry takes nothing returns boolean
        local integer i = 1

        if not IQ_AllEnabled then
            return false
        endif

        loop
            exitwhen i > IQ_EntryCount
            if IQ_IsEntryCandidate(i) then
                return true
            endif
            set i = i + 1
        endloop

        return false
    endfunction

    private function IQ_FindEntryInCategory takes integer category, integer startIndex returns integer
        local integer i = startIndex

        if i < 1 then
            set i = 1
        endif

        loop
            exitwhen i > IQ_EntryCount
            if IQ_EntryCategory[i] == category and IQ_IsEntryCandidate(i) then
                return i
            endif
            set i = i + 1
        endloop

        return 0
    endfunction

    private function IQ_FindNextForRound takes nothing returns integer
        local integer checked = 0
        local integer category = IQ_QueryCategory
        local integer entryIndex

        loop
            exitwhen checked >= IQ_CATEGORY_COUNT
            if IQ_IsCategoryValid(category) and IQ_CategoryEnabled[category] then
                if IQ_ShouldScanCategory(category) then
                    set entryIndex = IQ_FindEntryInCategory(category, IQ_CategoryCursor[category] + 1)
                    if entryIndex != 0 then
                        set IQ_QueryCategory = category
                        set IQ_CategoryCursor[category] = entryIndex
                        return entryIndex
                    endif
                endif
                call IQ_MarkCategoryRoundComplete(category)
            elseif IQ_IsCategoryValid(category) then
                set IQ_CategoryCursor[category] = 0
            endif

            set category = IQ_NextCategory(category)
            set IQ_QueryCategory = category
            set checked = checked + 1
        endloop

        return 0
    endfunction

    private function IQ_ShowEntry takes integer entryIndex returns nothing
        local real x
        local real y
        local integer category = IQ_EntryCategory[entryIndex]
        local integer style = IQ_EntryStyle[entryIndex]

        if not IQ_IsEntryCandidate(entryIndex) then
            return
        endif

        if IQ_EntryUsesUnit[entryIndex] then
            set x = GetUnitX(IQ_EntryUnit[entryIndex])
            set y = GetUnitY(IQ_EntryUnit[entryIndex])
        else
            set x = IQ_EntryX[entryIndex]
            set y = IQ_EntryY[entryIndex]
        endif

        set IQ_ActiveEntry = entryIndex
        call IQ_SetEntryVisible(entryIndex, true)
        if IQ_EntryPing[entryIndex] then
            call PingMinimapEx(x, y, IQ_PING_DURATION, IQ_GetPingRed(style, category), IQ_GetPingGreen(style, category), IQ_GetPingBlue(style, category), true)
        endif
    endfunction

    private function IQ_QueryTick takes nothing returns nothing
        local integer entryIndex

        set IQ_TimerRunning = false
        call IQ_HideActive()

        if not IQ_HasAnyQueryableEntry() then
            call IQ_ResetCategoryCursors()
            set IQ_QueryResting = false
            return
        endif

        set entryIndex = IQ_FindNextForRound()
        if entryIndex == 0 then
            call IQ_ResetCategoryCursors()
            set IQ_TimerRunning = true
            set IQ_QueryResting = true
            call TimerStart(IQ_QueryTimer, IQ_QueryRestTime, false, function IQ_QueryTick)
            return
        endif

        call IQ_ShowEntry(entryIndex)
        set IQ_TimerRunning = true
        set IQ_QueryResting = false
        call TimerStart(IQ_QueryTimer, IQ_GetEntryQueryTime(entryIndex), false, function IQ_QueryTick)
    endfunction

    private function IQ_StartTimer takes real delay returns nothing
        if IQ_QueryTimer == null then
            set IQ_QueryTimer = CreateTimer()
        endif
        if IQ_TimerRunning then
            return
        endif
        if not IQ_HasAnyQueryableEntry() then
            return
        endif
        set IQ_TimerRunning = true
        set IQ_QueryResting = false
        call TimerStart(IQ_QueryTimer, delay, false, function IQ_QueryTick)
    endfunction

    private function IQ_RefreshTimerState takes nothing returns nothing
        if not IQ_HasAnyQueryableEntry() then
            call IQ_HideActive()
            call IQ_ResetCategoryCursors()
            if IQ_QueryTimer != null then
                call PauseTimer(IQ_QueryTimer)
            endif
            set IQ_TimerRunning = false
            set IQ_QueryResting = false
            return
        endif

        call IQ_StartTimer(IQ_START_DELAY)
    endfunction

    private function IQ_RestartCurrentTimer takes nothing returns nothing
        if IQ_QueryTimer == null then
            set IQ_QueryTimer = CreateTimer()
        else
            call PauseTimer(IQ_QueryTimer)
        endif

        set IQ_TimerRunning = false
        if not IQ_HasAnyQueryableEntry() then
            call IQ_RefreshTimerState()
            return
        endif

        set IQ_TimerRunning = true
        if IQ_ActiveEntry > 0 then
            set IQ_QueryResting = false
            call TimerStart(IQ_QueryTimer, IQ_GetEntryQueryTime(IQ_ActiveEntry), false, function IQ_QueryTick)
        elseif IQ_QueryResting then
            call TimerStart(IQ_QueryTimer, IQ_QueryRestTime, false, function IQ_QueryTick)
        else
            call TimerStart(IQ_QueryTimer, IQ_START_DELAY, false, function IQ_QueryTick)
        endif
    endfunction

    private function IQ_RemoveEntryAt takes integer entryIndex returns nothing
        local integer lastIndex = IQ_EntryCount

        if entryIndex <= 0 or entryIndex > IQ_EntryCount then
            return
        endif

        if IQ_ActiveEntry == entryIndex then
            call IQ_HideActive()
        else
            call IQ_SetEntryVisible(entryIndex, false)
        endif

        if IQ_EntryIcon[entryIndex] != null then
            if IQ_IconIndex.has(GetHandleId(IQ_EntryIcon[entryIndex])) then
                call IQ_IconIndex.remove(GetHandleId(IQ_EntryIcon[entryIndex]))
            endif
            call DestroyMinimapIcon(IQ_EntryIcon[entryIndex])
        endif

        if entryIndex != lastIndex then
            set IQ_EntryIcon[entryIndex] = IQ_EntryIcon[lastIndex]
            set IQ_EntryUnit[entryIndex] = IQ_EntryUnit[lastIndex]
            set IQ_EntryUsesUnit[entryIndex] = IQ_EntryUsesUnit[lastIndex]
            set IQ_EntryX[entryIndex] = IQ_EntryX[lastIndex]
            set IQ_EntryY[entryIndex] = IQ_EntryY[lastIndex]
            set IQ_EntryCategory[entryIndex] = IQ_EntryCategory[lastIndex]
            set IQ_EntryStyle[entryIndex] = IQ_EntryStyle[lastIndex]
            set IQ_EntryPing[entryIndex] = IQ_EntryPing[lastIndex]
            if IQ_EntryIcon[entryIndex] != null then
                set IQ_IconIndex.integer[GetHandleId(IQ_EntryIcon[entryIndex])] = entryIndex
            endif
            if IQ_ActiveEntry == lastIndex then
                set IQ_ActiveEntry = entryIndex
            endif
        endif

        set IQ_EntryIcon[lastIndex] = null
        set IQ_EntryUnit[lastIndex] = null
        set IQ_EntryUsesUnit[lastIndex] = false
        set IQ_EntryX[lastIndex] = 0.00
        set IQ_EntryY[lastIndex] = 0.00
        set IQ_EntryCategory[lastIndex] = 0
        set IQ_EntryStyle[lastIndex] = 0
        set IQ_EntryPing[lastIndex] = false
        set IQ_EntryCount = lastIndex - 1

        call IQ_ResetCategoryCursors()
        call IQ_RefreshTimerState()
    endfunction

    private function IQ_AddEntry takes minimapicon icon, unit u, boolean usesUnit, real x, real y, integer category, integer style, boolean enablePing returns minimapicon
        local integer entryIndex

        if icon == null then
            return null
        endif
        if not IQ_IsCategoryValid(category) then
            call DestroyMinimapIcon(icon)
            return null
        endif
        if IQ_EntryCount >= IQ_MAX_ENTRIES then
            call DestroyMinimapIcon(icon)
            return null
        endif

        call SetMinimapIconVisible(icon, false)

        set entryIndex = IQ_EntryCount + 1
        set IQ_EntryCount = entryIndex
        set IQ_EntryIcon[entryIndex] = icon
        set IQ_EntryUnit[entryIndex] = u
        set IQ_EntryUsesUnit[entryIndex] = usesUnit
        set IQ_EntryX[entryIndex] = x
        set IQ_EntryY[entryIndex] = y
        set IQ_EntryCategory[entryIndex] = category
        set IQ_EntryStyle[entryIndex] = style
        set IQ_EntryPing[entryIndex] = enablePing
        set IQ_IconIndex.integer[GetHandleId(icon)] = entryIndex

        call IQ_RefreshTimerState()
        return icon
    endfunction

    public function RegisterUnitIcon takes unit u, integer category, integer style, boolean enablePing returns minimapicon
        if not IQ_IsUnitValid(u) then
            return null
        endif
        return IQ_AddEntry(IQ_CreateUnitIcon(u, style), u, true, 0.00, 0.00, category, style, enablePing)
    endfunction

    public function RegisterPointIcon takes real x, real y, integer category, integer style, boolean enablePing returns minimapicon
        return IQ_AddEntry(IQ_CreatePointIcon(x, y, style), null, false, x, y, category, style, enablePing)
    endfunction

    public function RegisterExistingIcon takes minimapicon icon, real x, real y, integer category, integer style, boolean enablePing returns minimapicon
        return IQ_AddEntry(icon, null, false, x, y, category, style, enablePing)
    endfunction

    public function RegisterTravelPoint takes real x, real y, integer style returns minimapicon
        return RegisterPointIcon(x, y, ICONQUERY_CATEGORY_FLIGHT_MASTER, style, true)
    endfunction

    public function RegisterQuestGiverUnitIcon takes unit u, integer style returns minimapicon
        return RegisterUnitIcon(u, ICONQUERY_CATEGORY_QUEST_GIVERS, style, true)
    endfunction

    public function RegisterFlightMasterUnitIcon takes unit u returns minimapicon
        return RegisterUnitIcon(u, ICONQUERY_CATEGORY_FLIGHT_MASTER, bj_CAMPPINGSTYLE_CONTROL_ALLY, true)
    endfunction

    public function RegisterShipMasterUnitIcon takes unit u returns minimapicon
        return RegisterUnitIcon(u, ICONQUERY_CATEGORY_FLIGHT_MASTER, bj_CAMPPINGSTYLE_CONTROL_NEUTRAL, true)
    endfunction

    public function RegisterFlightMasterPoint takes real x, real y returns minimapicon
        return RegisterTravelPoint(x, y, bj_CAMPPINGSTYLE_CONTROL_ALLY)
    endfunction

    public function RegisterShipMasterPoint takes real x, real y returns minimapicon
        return RegisterTravelPoint(x, y, bj_CAMPPINGSTYLE_CONTROL_NEUTRAL)
    endfunction

    public function RegisterShipPathPoint takes real x, real y returns minimapicon
        return RegisterTravelPoint(x, y, bj_CAMPPINGSTYLE_PRIMARY_GREEN)
    endfunction

    public function RegisterBossUnitIcon takes unit u returns minimapicon
        return RegisterUnitIcon(u, ICONQUERY_CATEGORY_BOSSES, bj_CAMPPINGSTYLE_BOSS, true)
    endfunction

    public function RegisterPlaceOfInterest takes real x, real y, integer style returns minimapicon
        return RegisterPointIcon(x, y, ICONQUERY_CATEGORY_PLACES_OF_INTEREST, style, true)
    endfunction

    public function RegisterCompanionFollowerUnitIcon takes unit u returns minimapicon
        return RegisterUnitIcon(u, ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS, bj_CAMPPINGSTYLE_CONTROL_ALLY, true)
    endfunction

    public function UnregisterIcon takes minimapicon icon returns nothing
        local integer entryIndex

        if icon == null then
            return
        endif
        if IQ_IconIndex.has(GetHandleId(icon)) then
            set entryIndex = IQ_IconIndex.integer[GetHandleId(icon)]
            call IQ_RemoveEntryAt(entryIndex)
        else
            call DestroyMinimapIcon(icon)
        endif
    endfunction

    public function UnregisterUnit takes unit u returns nothing
        local integer i = 1

        if u == null then
            return
        endif

        loop
            exitwhen i > IQ_EntryCount
            if IQ_EntryUsesUnit[i] and IQ_EntryUnit[i] == u then
                call IQ_RemoveEntryAt(i)
            else
                set i = i + 1
            endif
        endloop
    endfunction

    public function SetAllEnabled takes boolean enabled returns nothing
        set IQ_AllEnabled = enabled
        if not enabled then
            call IQ_ResetCategoryCursors()
        endif
        call IQ_RefreshTimerState()
    endfunction

    public function GetAllEnabled takes nothing returns boolean
        return IQ_AllEnabled
    endfunction

    public function SetCategoryEnabled takes integer category, boolean enabled returns nothing
        if not IQ_IsCategoryValid(category) then
            return
        endif

        set IQ_CategoryEnabled[category] = enabled
        set IQ_CategoryCursor[category] = 0
        if IQ_ActiveEntry > 0 and IQ_EntryCategory[IQ_ActiveEntry] == category then
            call IQ_HideActive()
        endif
        call IQ_RefreshTimerState()
        call IQ_RestartCurrentTimer()
    endfunction

    public function IsCategoryEnabled takes integer category returns boolean
        if not IQ_IsCategoryValid(category) then
            return false
        endif
        return IQ_CategoryEnabled[category]
    endfunction

    public function SetQueryTime takes real seconds returns nothing
        set IQ_QueryTime = IQ_ClampReal(seconds, IQ_QUERY_TIME_MIN, IQ_QUERY_TIME_MAX)
        call IQ_RestartCurrentTimer()
    endfunction

    public function GetQueryTime takes nothing returns real
        return IQ_QueryTime
    endfunction

    public function SetQueryRestTime takes real seconds returns nothing
        set IQ_QueryRestTime = IQ_ClampReal(seconds, IQ_QUERY_REST_MIN, IQ_QUERY_REST_MAX)
        call IQ_RestartCurrentTimer()
    endfunction

    public function GetQueryRestTime takes nothing returns real
        return IQ_QueryRestTime
    endfunction

    public function SetCategoryQueryTime takes integer category, real seconds returns nothing
        if not IQ_IsCategoryValid(category) then
            return
        endif
        set IQ_CategoryQueryTime[category] = IQ_ClampReal(seconds, IQ_QUERY_TIME_MIN, IQ_QUERY_TIME_MAX)
        call IQ_RestartCurrentTimer()
    endfunction

    public function GetCategoryQueryTime takes integer category returns real
        if not IQ_IsCategoryValid(category) then
            return 0.00
        endif
        return IQ_GetCategoryQueryTime(category)
    endfunction

    public function ClearCategoryQueryTime takes integer category returns nothing
        if not IQ_IsCategoryValid(category) then
            return
        endif
        set IQ_CategoryQueryTime[category] = 0.00
        call IQ_RestartCurrentTimer()
    endfunction

    public function SetCategoryFrequency takes integer category, integer everyRounds returns nothing
        if not IQ_IsCategoryValid(category) then
            return
        endif
        set IQ_CategoryFrequency[category] = IQ_ClampInt(everyRounds, IQ_CATEGORY_FREQUENCY_MIN, IQ_CATEGORY_FREQUENCY_MAX)
        set IQ_CategoryRoundCounter[category] = 0
        set IQ_CategoryCursor[category] = 0
        call IQ_RestartCurrentTimer()
    endfunction

    public function GetCategoryFrequency takes integer category returns integer
        if not IQ_IsCategoryValid(category) then
            return 0
        endif
        return IQ_CategoryFrequency[category]
    endfunction

    public function SetSecondaryCategoryFrequency takes integer everyRounds returns nothing
        call SetCategoryFrequency(ICONQUERY_CATEGORY_FLIGHT_MASTER, everyRounds)
        call SetCategoryFrequency(ICONQUERY_CATEGORY_BOSSES, everyRounds)
        call SetCategoryFrequency(ICONQUERY_CATEGORY_PLACES_OF_INTEREST, everyRounds)
    endfunction

    public function GetSecondaryCategoryFrequency takes nothing returns integer
        return IQ_CategoryFrequency[ICONQUERY_CATEGORY_PLACES_OF_INTEREST]
    endfunction

    public function GetCategoryName takes integer category returns string
        if category == ICONQUERY_CATEGORY_QUEST_GIVERS then
            return "Quest Givers"
        elseif category == ICONQUERY_CATEGORY_FLIGHT_MASTER then
            return "Flight/Ship Masters"
        elseif category == ICONQUERY_CATEGORY_BOSSES then
            return "Bosses"
        elseif category == ICONQUERY_CATEGORY_PLACES_OF_INTEREST then
            return "Places of Interest"
        elseif category == ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS then
            return "Companions/Followers"
        endif
        return "Unknown"
    endfunction

    public function GetRegisteredCount takes nothing returns integer
        return IQ_EntryCount
    endfunction

    private function Init takes nothing returns nothing
        if IQ_Initialized then
            return
        endif
        set IQ_Initialized = true

        set IQ_IconIndex = Table.create()
        set IQ_QueryTimer = CreateTimer()
        set IQ_CategoryEnabled[ICONQUERY_CATEGORY_QUEST_GIVERS] = true
        set IQ_CategoryEnabled[ICONQUERY_CATEGORY_FLIGHT_MASTER] = true
        set IQ_CategoryEnabled[ICONQUERY_CATEGORY_BOSSES] = true
        set IQ_CategoryEnabled[ICONQUERY_CATEGORY_PLACES_OF_INTEREST] = true
        set IQ_CategoryEnabled[ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS] = true
        set IQ_CategoryFrequency[ICONQUERY_CATEGORY_QUEST_GIVERS] = 1
        set IQ_CategoryFrequency[ICONQUERY_CATEGORY_FLIGHT_MASTER] = 3
        set IQ_CategoryFrequency[ICONQUERY_CATEGORY_BOSSES] = 3
        set IQ_CategoryFrequency[ICONQUERY_CATEGORY_PLACES_OF_INTEREST] = 3
        set IQ_CategoryFrequency[ICONQUERY_CATEGORY_COMPANIONS_AND_FOLLOWERS] = 1
        call IQ_ResetCategoryCursors()
    endfunction
endlibrary
