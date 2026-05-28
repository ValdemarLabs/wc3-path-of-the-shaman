library UIUtils requires LinkedListModule
    /*********************************************************************************
    *
    *            UI Utils v1.05
    *
    *    Create and manage user interface in highly convenient and intuitive way!
    *
    *    Check for update at: https://www.hiveworkshop.com/threads/320005/
    *
    *    Features:
    *        • Includes several primitive frame types (texture, text, slider, etc.)
    *        • Compatible with custom frame definition
    *        • Uses pixel as measurement unit
    *        • Friendly UI native wrappers
    *        • Custom hierarchy system with in-depth inheritance control
    *        • Automatically prevents non-simple frame from going out of the 4:3 bounds
    *        • Enhanced frame pivot & anchor point feature for all-resolution support
    *        • Automatic create context handling
    *        • Extra security measures (prevents UI native related crashes out of the box)
    *        • Customizable full-screen mode
    *        • Essential default/original frames container
    *        • Includes all available built-in fdf files
    *
    *    I.  System requirements:
    *        • LinkedListModule            : http://hiveworkshop.com/threads/snippet-linkedlistmodule.206552/
    *        • Warcraft III version 1.31+
    *
    *    II. Installation:
    *        • Import LinkedListModule
    *        • Copy UIUtils trigger to your map
    *        • Go to Import Manager and import following files to your map:
    *            - UIUtils.toc
    *            - UIUtils.fdf
    *        • Configure the system below
    *        • For true fullscreen you might need to manually remove the inventory cover texture
    *
    *    III. Credits:
    *        • Tasyen   | UI tutorials & researches
    *        • Dirac    | LinkedListModule
    *
    *    IV. API - (Complete manual: https://www.hiveworkshop.com/threads/320046/)
    *
    *           struct UIFrame                                                                                                                                                                                                                                                                            */static if FOLD then /*
               
                1. Ctor & dtor
                    - Let "isSimple" be "true" if it is a simple frame type
                        | static method create takes boolean isSimple, string frameType, UIFrame parent, real x, real y, integer level returns UIFrame
                       
                    - Dispose the frame
                        | method destroy takes nothing returns nothing
                   
                2. Wrappers
                    - Set & get frame's textures
                        • Might not be compatible with custom frame definition
                        • Some only work for specific type of primitive frames
                        • Some might not work properly just yet (blizzard limitation)
                        > Default main texture
                            | method operator texture= takes string filePath returns nothing
                            | method operator texture  takes nothing returns string
                        > Texture displayed when frame is disabled
                            | method operator disabledTexture= takes string filePath returns nothing
                            | method operator disabledTexture  takes nothing returns string
                        > Highlighter texture
                            | method operator highlightTexture= takes string filePath returns nothing
                            | method operator highlightTexture  takes nothing returns string
                        > Texture displayed when frame is pressed
                            | method operator pushedTexture= takes string filePath returns nothing
                            | method operator pushedTexture  takes nothing returns string
                        > Background texture for the frame
                            | method operator backgroundTexture= takes string filePath returns nothing
                            | method operator backgroundTexture  takes nothing returns string
                        > Border texture for the frame
                            | method operator borderTexture= takes string filePath returns nothing
                            | method operator borderTexture  takes nothing returns string
                   
                    - Set & get frame's parent
                        | method operator parent= takes UIFrame frame returns nothing
                        | method operator parent  takes nothing returns UIFrame
                       
                    - Get frame's screen space position
                        • Values might be affected by frame's parent anchor point
                            | method operator screenPosX takes nothing returns real
                            | method operator screenPosY takes nothing returns real
                   
                    - Get frame's bounds
                            | method operator left   takes nothing returns real
                            | method operator right  takes nothing returns real
                            | method operator top    takes nothing returns real
                            | method operator bottom takes nothing returns real
                           
                    - Get frame's true (scaled) size in pixel
                        | method operator width  takes nothing returns real
                        | method operator height takes nothing returns real
                       
                    - Set & get frame's scale factor
                        > Frame's independent scale factor
                            | method operator localScale= takes real r returns nothing
                            | method operator localScale  takes nothing returns real
                        > Frame's true scale
                            | method operator scale takes nothing returns real
                       
                    - Set & get frame's visibility state
                        | method operator visible= takes boolean state returns nothing
                        | method operator visible  takes nothing returns boolean
                       
                    - Set & get frame's transparency (0-255)
                        | method operator opacity= takes integer amount returns nothing
                        | method operator opacity  takes nothing returns integer
                       
                    - Set & get enable state of the frame
                        | method operator enabled= takes boolean state returns nothing
                        | method operator enabled  takes nothing returns boolean
                       
                    - Set & get frame's self sorting/layering order
                        | method operator level= takes integer level returns nothing
                        | method operator level  takes nothing returns integer
                        > Get frame's actual sorting/layering order
                            | method operator trueLevel takes nothing returns integer
                           
                    - Set & get frame's text content
                        | method operator text= takes string str returns nothing
                        | method operator text  takes nothing returns string
                       
                    - Set & get frame's text content length limit
                        | method operator maxLength= takes integer length returns nothing
                        | method operator maxLength  takes nothing returns integer
                       
                    - Set frame's text color
                        > Use "BlzConvertColor" function to convert ARGB color
                            | method operator textColor= takes integer color returns nothing
                       
                    - Set & get frame's model file
                        | method operator model= takes string filePath returns nothing
                        | method operator model  takes nothing returns string
                       
                    - Set vertex color of the model frame
                        > Use "BlzConvertColor" function to convert ARGB color
                            | method operator vertexColor= takes integer color returns nothing
                       
                    - Set & get value of slider frame
                        | method operator value= takes real r  returns nothing
                        | method operator value  takes nothing returns real
                       
                    - Step size is increment of slider bar relative to its min max value
                        | method operator stepSize= takes real r  returns nothing
                        | method operator stepSize  takes nothing returns real
                       
                    - Set & get tooltips frame
                        | method operator tooltips= takes UIFrame frame returns nothing
                        | method operator tooltips  takes nothing returns UIFrame
                       
                    - Get sub-frame handle based on passed name
                        • Usage: tempFrame.subFrame["tempFrameText"] => returns subframe handle of "tempFrame" by name of "tempFrameText"
                            | method operator subFrame[] takes string name returns framehandle
                       
                    - Register any event happen to the frame (click, mouse enter/leave, etc.)
                        • Use "UIFrame.TriggerComponent" to get the triggering frame
                        • Use "BlzGetTriggerFrameEvent()" function to get the event type
                            | method operator onAnyEvent= takes code func returns triggercondition
                   
                2. Methods
                    - Iterates through all child frames of the frame
                        • Use "UIFrame.EnumChild" to get the iterated child frame
                            | method forEachChild takes code func returns nothing
                       
                    - Set frame's text properties
                        | method setTextAlignment takes textaligntype vertical, textaligntype horizontal returns nothing
                        | method setFont takes string fontType, real fontSize, integer flags returns nothing
                   
                    - Set slider min max values
                        | method setMinMaxValue takes real min, real max returns nothing
                   
                    - Animate frame texture
                        | method setSpriteAnimate takes integer primaryProp, integer flags returns nothing
                       
                    - Give focus to the frame
                        | method setFocus takes boolean state returns nothing
                   
                    - Cage mouse inside the frame's boundaries
                        | method cageMouse takes boolean state returns nothing
                   
                    - Emulate click on the frame
                        | method click takes nothing returns nothing
                       
                    - Force update the frame
                        | method refresh takes nothing returns nothing
                       
                    - Modify frame's position
                        > Set frame's local position
                            | method move takes real x, real y returns nothing
                        > Set frame's screen position (ignores parent position)
                            | method moveEx takes real x, real y returns nothing
                        > Set frame position relative to other specified frame
                            | method relate takes UIFrame relative, real x, real y returns nothing
                           
                    - Set dimension of the frame
                        | method setSize takes real width, real height returns nothing
                       
                    - Set frame's anchor & pivot point
                        | method setPivotPoint  takes real x, real y returns nothing
                        | method setAnchorPoint takes real x, real y returns nothing
                   
                3. Members
                    - Main frame handle
                        | readonly framehandle frame

                    - Set & get frame's name
                        | string name

                    - Set & get property inheritance
                        • Frame refresh is recommended after modifying inheritance
                            | boolean inheritScale
                            | boolean inheritOpacity
                            | boolean inheritVisibility
                            | boolean inheritEnableState
                            | boolean inheritPosition
                            | boolean inheritLevel
                            | boolean scalePosition

                    - Frame's type name
                        | readonly string frameType
                       
                    - Frame's local space position
                        | readonly real localPosX
                        | readonly real localPosY
                       
                    - Frame's anchor & pivot points
                        | readonly real anchorX
                        | readonly real anchorY
                        | readonly real pivotX
                        | readonly real pivotY
                       
                    - Frame's unscaled size
                        | readonly real unscaledWidth
                        | readonly real unscaledHeight
                       
                    - Get frame text font properties
                        | readonly integer fontFlags
                        | readonly real    fontSize
                        | readonly string  fontType
                       
                    - Slider frame's min max value
                        | readonly real valueMin
                        | readonly real valueMax
                       
                    - Create context index of the frame
                        | readonly integer context
                       
                    - Local states of the frame
                        | readonly boolean visibleSelf
                        | readonly boolean enabledSelf
                       
                    - Is the frame a simple frame type or not
                        | readonly boolean isSimple
                       
                    - Local transparency of the frame
                        | readonly integer localOpacity
                       
                4. Static Members
                    - Representation for null frame
                        | readonly static UIFrame Null
                       
                    - Currently iterated frame of "forEachChild" method
                        | readonly static UIFrame EnumChild
                       
                    - Triggerer of the "onAnyEvent"
                        | readonly static UIFrame TriggerComponent

                    - Primitive frame names
                        | readonly static string TYPE_TEXT
                        | readonly static string TYPE_SIMPLE_TEXT
                        | readonly static string TYPE_TEXTURE
                        | readonly static string TYPE_SIMPLE_TEXTURE
                        | readonly static string TYPE_BUTTON
                        | readonly static string TYPE_SIMPLE_BUTTON
                        | readonly static string TYPE_BAR
                        | readonly static string TYPE_H_SLIDER
                        | readonly static string TYPE_V_SLIDER
                                                                                                                                                                                                                                                                                                        */
                                                                                                                                                                                                                                                                                                        endif
   /*           struct UIUtils                                                                                                                                                                                                                                                                            */static if FOLD then /*
   
                1. Static Methods
                    - Calculate aspect ratio height
                        | static method CalcAspectRatio takes real w, real h, real aspectWidth returns integer
                       
                    - Convert pixel unit to DPI and vice versa
                        • Usage: [value]*UIUtils.PXTODPI
                                 [value]*UIUtils.DPITOPX
                            | static method operator PXTODPI takes nothing returns real
                            | static method operator DPITOPX takes nothing returns real
                           
                    - Width of the 4:3 bound
                        | static method operator FrameBoundWidth takes nothing returns real
       
                    - Convert from pixel to screen x/y coordinate (in DPI unit)
                        | static method GetScreenPosX takes real x returns real
                        | static method GetScreenPosY takes real y returns real
                       
                    - Force update default frames
                        | static method RefreshDefaultFrames takes nothing returns nothing
                       
                    - Force update resolution
                        | static method RefreshResolution takes nothing returns nothing
                       
                    - Resolution change event
                        | static method RegisterOnResolutionChangeEvent takes code func returns triggercondition
                        | static method RemoveOnResolutionChangeEvent   takes triggercondition cond returns nothing
                       
                2. Static Members
                    - Updated after resolution change event
                        • Values might be async between clients
                            | readonly static integer ResolutionWidth
                            | readonly static integer ResolutionHeight
                            | readonly static integer AspectWidth
                            | readonly static integer AspectHeight
                                                                                                                                                                                                                                                                                                        */
                                                                                                                                                                                                                                                                                                        endif
   /*           struct DefaultFrame (singleton)                                                                                                                                                                                                                                                            */static if FOLD then /*
                    - Origin frames
                        | readonly static framehandle         Game
                        | readonly static framehandle         World
                        | readonly static framehandle         HeroBar
                        | readonly static framehandle array   HeroButton        [0 - 6]
                        | readonly static framehandle array   HeroHPBar         [0 - 6]
                        | readonly static framehandle array   HeroMPBar         [0 - 6]
                        | readonly static framehandle array   HeroIndicator     [0 - 6]
                        | readonly static framehandle array   ItemButton        [0 - 5]
                        | readonly static framehandle array   CommandButton     [0 - 11]
                        | readonly static framehandle array   SystemButton      [0 - 3]
                        | readonly static framehandle         Portrait
                        | readonly static framehandle         Minimap
                        | readonly static framehandle array   MinimapButton     [0 - 4]
                        | readonly static framehandle         Tooltip
                        | readonly static framehandle         UberTooltip
                        | readonly static framehandle         ChatMsg
                        | readonly static framehandle         UnitMsg
                        | readonly static framehandle         TopMsg
             
                    - Other frames
                        | readonly static framehandle         Console
                        | readonly static framehandle         GoldText
                        | readonly static framehandle         LumberText
                        | readonly static framehandle         FoodText
                        | readonly static framehandle         UnitNameText
                        | readonly static framehandle         ResourceBar
                        | readonly static framehandle         UpperButtonBar
                                                                                                                                                                                                                                                                                                        */
                                                                                                                                                                                                                                                                                                        endif
   /*
    *    V. Configurations
    *                                                                                                                                                                                                                                                                                                    */globals
        // 1. TOC file path
            private constant string TOC_FILE = "war3mapimported\\UIUtils.toc"
           
        // 2. Temporary cache name
            private constant string CACHE_NAME = "UIUtils.w3v"
           
        // 3. Resolution change detection interval
            private constant real RESOLUTION_CHECK_INTERVAL = 0.1
           
        // 4. true : hides console frames on map init (full screen)
            private constant boolean HIDE_CONSOLE_FRAME = true

        // 5. true : frame's properties will be retained when it changes parent
            private constant boolean PERSISTENT_CHILD_PROPERTIES = true
           
        // 6. true : helps to prevent non-simple frame from going beyond the 4:3 bounds
            private constant boolean REFRAIN_NON_SIMPLE_FRAME = true

        // 7. Reference resolution, as which is used to design the interface
            public constant integer RESOLUTION_WIDTH  = 1360
            public constant integer RESOLUTION_HEIGHT = 768
       
        // 8. Configure in-game message frame
            private constant boolean MESSAGE_FRAME_VISIBLE  = true
            private constant real    MESSAGE_FRAME_ANCHOR_X = 0.5
            private constant real    MESSAGE_FRAME_ANCHOR_Y = 0.5
            private constant real    MESSAGE_FRAME_PIVOT_X  = 0.5
            private constant real    MESSAGE_FRAME_PIVOT_Y  = 0.5
            private constant real    MESSAGE_FRAME_POS_X    = 0.0
            private constant real    MESSAGE_FRAME_POS_Y    = 0.0
           
        // 9. Configure in-game chat frame
            private constant boolean CHAT_FRAME_VISIBLE  = true
            private constant real    CHAT_FRAME_ANCHOR_X = 0.0
            private constant real    CHAT_FRAME_ANCHOR_Y = 0.0
            private constant real    CHAT_FRAME_PIVOT_X  = 0.0
            private constant real    CHAT_FRAME_PIVOT_Y  = 0.0
            private constant real    CHAT_FRAME_POS_X    = 10.0
            private constant real    CHAT_FRAME_POS_Y    = 100.0
           
        // 10. Configure tooltips frame
            private constant boolean TOOLTIPS_FRAME_VISIBLE  = true
            private constant real    TOOLTIPS_FRAME_ANCHOR_X = 1.0
            private constant real    TOOLTIPS_FRAME_ANCHOR_Y = 0.0
            private constant real    TOOLTIPS_FRAME_PIVOT_X  = 1.0
            private constant real    TOOLTIPS_FRAME_PIVOT_Y  = 0.0
            private constant real    TOOLTIPS_FRAME_POS_X    = -50.0
            private constant real    TOOLTIPS_FRAME_POS_Y    = 0.0
           
        // 11. Configure minimap frame
            private constant boolean MINIMAP_FRAME_VISIBLE  = false
            private constant real    MINIMAP_FRAME_ANCHOR_X = 1.0
            private constant real    MINIMAP_FRAME_ANCHOR_Y = 1.0
            private constant real    MINIMAP_FRAME_PIVOT_X  = 1.0
            private constant real    MINIMAP_FRAME_PIVOT_Y  = 1.0
            private constant real    MINIMAP_FRAME_POS_X    = 0.0
            private constant real    MINIMAP_FRAME_POS_Y    = 0.0
           
        // 12. Configure unit portrait frame
            private constant boolean PORTRAIT_FRAME_VISIBLE  = false
            private constant real    PORTRAIT_FRAME_ANCHOR_X = 0.0
            private constant real    PORTRAIT_FRAME_ANCHOR_Y = 0.0
            private constant real    PORTRAIT_FRAME_PIVOT_X  = 0.0
            private constant real    PORTRAIT_FRAME_PIVOT_Y  = 0.0
            private constant real    PORTRAIT_FRAME_POS_X    = 0.0
            private constant real    PORTRAIT_FRAME_POS_Y    = 0.0
           
        // 13. Configure other frame visibility
            private constant boolean RESOURCE_FRAME_VISIBLE   = false
            private constant boolean CMD_BUTTON_FRAME_VISIBLE = false
                                                                                                                                                                                                                                                                                                            endglobals
   /*
    *    END OF DOCUMENT ----- Modify following codes on your own risk
    *
    *********************************************************************************/
   
    private module DefaultFrameInit
        private static method onInit takes nothing returns nothing
            local integer i

            set Game        = BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0)
            set World       = BlzGetOriginFrame(ORIGIN_FRAME_WORLD_FRAME, 0)
            set HeroBar     = BlzGetOriginFrame(ORIGIN_FRAME_HERO_BAR, 0)
            set Portrait    = BlzGetOriginFrame(ORIGIN_FRAME_PORTRAIT, 0)
            set Minimap     = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP, 0)
            set Tooltip     = BlzGetOriginFrame(ORIGIN_FRAME_TOOLTIP, 0)
            set UberTooltip = BlzGetOriginFrame(ORIGIN_FRAME_UBERTOOLTIP, 0)
            set ChatMsg     = BlzGetOriginFrame(ORIGIN_FRAME_CHAT_MSG, 0)
            set UnitMsg     = BlzGetOriginFrame(ORIGIN_FRAME_UNIT_MSG, 0)
            set TopMsg      = BlzGetOriginFrame(ORIGIN_FRAME_TOP_MSG, 0)

            set i = 0
            loop
                exitwhen i > 11
                set HeroButton[i]    = BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON, i)
                set HeroHPBar[i]     = BlzGetOriginFrame(ORIGIN_FRAME_HERO_HP_BAR, i)
                set HeroMPBar[i]     = BlzGetOriginFrame(ORIGIN_FRAME_HERO_MANA_BAR, i)
                set HeroIndicator[i] = BlzGetOriginFrame(ORIGIN_FRAME_HERO_BUTTON_INDICATOR, i)
                set ItemButton[i]    = BlzGetOriginFrame(ORIGIN_FRAME_ITEM_BUTTON, i)
                set CommandButton[i] = BlzGetOriginFrame(ORIGIN_FRAME_COMMAND_BUTTON, i)
                set SystemButton[i]  = BlzGetOriginFrame(ORIGIN_FRAME_SYSTEM_BUTTON, i)
                set MinimapButton[i] = BlzGetOriginFrame(ORIGIN_FRAME_MINIMAP_BUTTON, i)
                set i = i + 1
            endloop
   
            set Console    = BlzGetFrameByName("ConsoleUI", 0)
            set GoldText   = BlzGetFrameByName("ResourceBarGoldText", 0)
            set LumberText = BlzGetFrameByName("ResourceBarLumberText", 0)
            set FoodText   = BlzGetFrameByName("ResourceBarSupplyText", 0)
            set ResourceBar = BlzGetFrameByName("ResourceBarFrame", 0)
            set UnitNameText = BlzGetFrameByName("SimpleNameValue", 0)
            set UpperButtonBar = BlzGetFrameByName("UpperButtonBarFrame", 0)

        endmethod
    endmodule

    private module UIUtilsInit
        private static method onInit takes nothing returns nothing
            local integer i
           
            call RefreshResolution()
            static if HIDE_CONSOLE_FRAME then
                call BlzEnableUIAutoPosition(false)
                call BlzFrameClearAllPoints(DefaultFrame.World)
                call BlzFrameClearAllPoints(DefaultFrame.Console)
                call BlzFrameSetAllPoints(DefaultFrame.World, DefaultFrame.Game)
                call BlzFrameSetAbsPoint(DefaultFrame.Console, FRAMEPOINT_TOPRIGHT, -999.0, -999.0)
                call RefreshDefaultFrames()
                static if not RESOURCE_FRAME_VISIBLE then
                    call BlzFrameClearAllPoints(DefaultFrame.GoldText)
                    call BlzFrameSetAbsPoint(DefaultFrame.GoldText, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
                    call BlzFrameClearAllPoints(DefaultFrame.LumberText)
                    call BlzFrameSetAbsPoint(DefaultFrame.LumberText, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
                    call BlzFrameClearAllPoints(DefaultFrame.FoodText)
                    call BlzFrameSetAbsPoint(DefaultFrame.FoodText, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
                    call BlzFrameClearAllPoints(DefaultFrame.ResourceBar)
                    call BlzFrameSetAbsPoint(DefaultFrame.ResourceBar, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
                endif
                static if not CMD_BUTTON_FRAME_VISIBLE then
                    set i = 0
                    loop
                        exitwhen DefaultFrame.CommandButton[i] == null
                        call BlzFrameClearAllPoints(DefaultFrame.CommandButton[i])
                        call BlzFrameSetAbsPoint(DefaultFrame.CommandButton[i], FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
                        set i = i + 1
                    endloop
                endif
            endif
            call TimerStart(CreateTimer(), RESOLUTION_CHECK_INTERVAL, true, function thistype.CheckResolution)
        endmethod
    endmodule
   
    struct DefaultFrame extends array
        readonly static framehandle         Game            = null
        readonly static framehandle         World           = null
        readonly static framehandle         HeroBar         = null
        readonly static framehandle array   HeroButton
        readonly static framehandle array   HeroHPBar
        readonly static framehandle array   HeroMPBar
        readonly static framehandle array   HeroIndicator
        readonly static framehandle array   ItemButton
        readonly static framehandle array   CommandButton
        readonly static framehandle array   SystemButton
        readonly static framehandle         Portrait        = null
        readonly static framehandle         Minimap         = null
        readonly static framehandle array   MinimapButton
        readonly static framehandle         Tooltip         = null
        readonly static framehandle         UberTooltip     = null
        readonly static framehandle         ChatMsg         = null
        readonly static framehandle         UnitMsg         = null
        readonly static framehandle         TopMsg          = null

        readonly static framehandle         Console         = null
        readonly static framehandle         GoldText        = null
        readonly static framehandle         LumberText      = null
        readonly static framehandle         FoodText        = null
        readonly static framehandle         UnitNameText    = null
        readonly static framehandle         ResourceBar     = null
        readonly static framehandle         UpperButtonBar  = null
       
        implement DefaultFrameInit
    endstruct
   
    private keyword AllComponents

    struct UIUtils extends array
        readonly static integer ResolutionWidth  = RESOLUTION_WIDTH
        readonly static integer ResolutionHeight = RESOLUTION_HEIGHT
        
        readonly static real ScaleFactor = 1
       
        private static trigger resolutionChangeTrigg = CreateTrigger()

        static method CalcAspectRatio takes real w, real h, real aspectWidth returns integer
            return R2I(aspectWidth*h/w+0.5)
        endmethod
       
        static method operator PXTODPI takes nothing returns real
            return 0.6/ResolutionHeight
        endmethod
       
        static method operator DPITOPX takes nothing returns real
            return ResolutionHeight/0.6
        endmethod
       
        static method operator FrameBoundWidth takes nothing returns real
            return (ResolutionWidth-ResolutionHeight/600.*800.)/2.
        endmethod
       
        static method GetScreenPosX takes real x returns real
            return (-FrameBoundWidth+x)*PXTODPI
        endmethod
       
        static method GetScreenPosY takes real y returns real
            return y*PXTODPI
        endmethod
       
        static method RefreshDefaultFrames takes nothing returns nothing
            static if MESSAGE_FRAME_VISIBLE then
                call BlzFrameClearAllPoints(DefaultFrame.UnitMsg)
                call BlzFrameSetAbsPoint(DefaultFrame.UnitMsg, FRAMEPOINT_BOTTOMLEFT,/*
                */ GetScreenPosX(MESSAGE_FRAME_POS_X+ResolutionWidth*MESSAGE_FRAME_ANCHOR_X-BlzFrameGetWidth(DefaultFrame.UnitMsg)*DPITOPX*MESSAGE_FRAME_PIVOT_X),/*
                */ GetScreenPosY(MESSAGE_FRAME_POS_Y+ResolutionHeight*MESSAGE_FRAME_ANCHOR_Y-BlzFrameGetHeight(DefaultFrame.UnitMsg)*DPITOPX*MESSAGE_FRAME_PIVOT_Y))
            endif
           
            static if CHAT_FRAME_VISIBLE then
                call BlzFrameSetAbsPoint(DefaultFrame.ChatMsg, FRAMEPOINT_BOTTOMLEFT,/*
                */ GetScreenPosX(CHAT_FRAME_POS_X+ResolutionWidth*CHAT_FRAME_ANCHOR_X-BlzFrameGetWidth(DefaultFrame.ChatMsg)*DPITOPX*CHAT_FRAME_PIVOT_X),/*
                */ GetScreenPosY(CHAT_FRAME_POS_Y+ResolutionHeight*CHAT_FRAME_ANCHOR_Y-BlzFrameGetHeight(DefaultFrame.ChatMsg)*DPITOPX*CHAT_FRAME_PIVOT_Y))
            endif

            static if TOOLTIPS_FRAME_VISIBLE then
                call BlzFrameClearAllPoints(DefaultFrame.UberTooltip)
                call BlzFrameSetAbsPoint(DefaultFrame.UberTooltip, FRAMEPOINT_BOTTOMLEFT,/*
                */ GetScreenPosX(TOOLTIPS_FRAME_POS_X+ResolutionWidth*TOOLTIPS_FRAME_ANCHOR_X-BlzFrameGetWidth(DefaultFrame.UberTooltip)*DPITOPX*TOOLTIPS_FRAME_PIVOT_X),/*
                */ GetScreenPosY(TOOLTIPS_FRAME_POS_Y+ResolutionHeight*TOOLTIPS_FRAME_ANCHOR_Y-BlzFrameGetHeight(DefaultFrame.UberTooltip)*DPITOPX*TOOLTIPS_FRAME_PIVOT_Y))
            endif
           
            call BlzFrameClearAllPoints(DefaultFrame.Minimap)
            static if MINIMAP_FRAME_VISIBLE then
                call BlzFrameSetAbsPoint(DefaultFrame.Minimap, FRAMEPOINT_BOTTOMLEFT,/*
                */ GetScreenPosX(MINIMAP_FRAME_POS_X+ResolutionWidth*MINIMAP_FRAME_ANCHOR_X-BlzFrameGetWidth(DefaultFrame.Minimap)*DPITOPX*MINIMAP_FRAME_PIVOT_X),/*
                */ GetScreenPosY(MINIMAP_FRAME_POS_Y+ResolutionHeight*MINIMAP_FRAME_ANCHOR_Y-BlzFrameGetHeight(DefaultFrame.Minimap)*DPITOPX*MINIMAP_FRAME_PIVOT_Y))
            else
                call BlzFrameSetAbsPoint(DefaultFrame.Minimap, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
		call BlzFrameSetSize(DefaultFrame.Minimap, 0.0001, 0.0001)
            endif

            call BlzFrameClearAllPoints(DefaultFrame.Portrait)
            static if PORTRAIT_FRAME_VISIBLE then
                call BlzFrameSetAbsPoint(DefaultFrame.Portrait, FRAMEPOINT_BOTTOMLEFT,/*
                */ GetScreenPosX(PORTRAIT_FRAME_POS_X+ResolutionWidth*PORTRAIT_FRAME_ANCHOR_X-BlzFrameGetWidth(DefaultFrame.Portrait)*DPITOPX*PORTRAIT_FRAME_PIVOT_X),/*
                */ GetScreenPosY(PORTRAIT_FRAME_POS_Y+ResolutionHeight*PORTRAIT_FRAME_ANCHOR_Y-BlzFrameGetHeight(DefaultFrame.Portrait)*DPITOPX*PORTRAIT_FRAME_PIVOT_Y))
            else
                call BlzFrameSetAbsPoint(DefaultFrame.Portrait, FRAMEPOINT_BOTTOMLEFT, -999.0, -999.0)
		call BlzFrameSetSize(DefaultFrame.Portrait, 0.0001, 0.0001)
            endif
        endmethod
       
        static method RefreshResolution takes nothing returns nothing
            local AllComponents node
           
            set ResolutionWidth  = BlzGetLocalClientWidth()
            set ResolutionHeight = BlzGetLocalClientHeight()
            set ScaleFactor  = I2R(ResolutionHeight)/I2R(RESOLUTION_HEIGHT)
            set node = AllComponents.base.next
            loop
                exitwhen node.head or node == 0
                if UIFrame(node).parent == UIFrame.Null then
                    call UIFrame(node).refresh()
                endif
                set node = node.next
            endloop
        endmethod

        private static method CheckResolution takes nothing returns nothing
            if BlzGetLocalClientWidth() != ResolutionWidth or BlzGetLocalClientHeight() != ResolutionHeight then
                call RefreshResolution()
                call RefreshDefaultFrames()
                call TriggerEvaluate(resolutionChangeTrigg)
            endif
        endmethod
       
        static method RegisterOnResolutionChangeEvent takes code func returns triggercondition
            return TriggerAddCondition(resolutionChangeTrigg, Condition(func))
        endmethod
       
        static method RemoveOnResolutionChangeEvent takes triggercondition cond returns nothing
            call TriggerRemoveCondition(resolutionChangeTrigg, cond)
        endmethod

        implement UIUtilsInit
    endstruct
   
    private struct UISubFrame
        static UIFrame frame = 0
        method operator [] takes string s returns framehandle
            return BlzGetFrameByName(s, frame.context)
        endmethod
    endstruct
   
    struct UIFrame extends array
        implement LinkedList

        string  name
        boolean inheritScale
        boolean inheritOpacity
        boolean inheritVisibility
        boolean inheritEnableState
        boolean inheritPosition
        boolean inheritLevel
        boolean scalePosition
        boolean alwaysRefresh

        readonly string  frameType
        readonly real    localPosX
        readonly real    localPosY
        readonly real    anchorX
        readonly real    anchorY
        readonly real    pivotX
        readonly real    pivotY
        readonly real    unscaledWidth
        readonly real    unscaledHeight
        readonly real    valueMin
        readonly real    valueMax
        readonly real    fontSize
        readonly string  fontType
        readonly integer fontFlags
        readonly integer context
        readonly boolean isSimple
        readonly boolean visibleSelf
        readonly boolean enabledSelf
        readonly integer localOpacity
       
        private real     m_localScale
        private real     m_stepSize
        private integer  m_level
        private thistype m_parent
        private thistype m_childs
        private thistype m_tooltips
       
        private string  mainTextureFile
        private string  disabledTextureFile
        private string  pushedTextureFile
        private string  highlightTextureFile
        private string  backgroundTextureFile
        private string  borderTextureFile
        private string  modelFile
        private trigger anyEventTrigg

        readonly framehandle frame
        private  framehandle textFrameH
        private  framehandle modelFrameH
        private  framehandle mainTextureH
        private  framehandle disabledTextureH
        private  framehandle pushedTextureH
        private  framehandle highlightTextureH
        private  framehandle backgroundTextureH
        private  framehandle borderTextureH

        readonly static thistype Null = 0
        readonly static thistype EnumChild = 0
        readonly static thistype TriggerComponent = 0
       
        readonly static string TYPE_TEXT            = "UIUtilsText"
        readonly static string TYPE_SIMPLE_TEXT     = "UIUtilsSimpleText"
        readonly static string TYPE_TEXTURE         = "UIUtilsTexture"
        readonly static string TYPE_SIMPLE_TEXTURE  = "UIUtilsSimpleTexture"
        readonly static string TYPE_BUTTON          = "UIUtilsButton"
        readonly static string TYPE_SIMPLE_BUTTON   = "UIUtilsSimpleButton"
        readonly static string TYPE_BAR             = "UIUtilsBar"
        readonly static string TYPE_H_SLIDER        = "UIUtilsSliderH"
        readonly static string TYPE_V_SLIDER        = "UIUtilsSliderV"

        private static trigger ExecTrigg = CreateTrigger()
        private static gamecache GC
        private static hashtable HT

        private static method IsSimple takes string frameType, boolean isSimple returns boolean
            return frameType == TYPE_SIMPLE_TEXT or frameType == TYPE_SIMPLE_TEXTURE or frameType == TYPE_BAR or isSimple and not (frameType == TYPE_TEXT or frameType == TYPE_TEXTURE or frameType == TYPE_BUTTON or frameType == TYPE_H_SLIDER or frameType == TYPE_V_SLIDER)
        endmethod

        private static method GetTriggerComponent takes nothing returns boolean
            set TriggerComponent = LoadInteger(HT, GetHandleId(BlzGetTriggerFrame()), 0)
            return false
        endmethod
       
        method operator subFrame takes nothing returns UISubFrame
            set UISubFrame.frame = this
            return 0
        endmethod

        method operator onAnyEvent= takes code func returns triggercondition
            local integer i
   
            if .anyEventTrigg == null then
                set .anyEventTrigg = CreateTrigger()
                set i = 1
                loop
                    exitwhen i > 16
                    call BlzTriggerRegisterFrameEvent(.anyEventTrigg, .frame, ConvertFrameEventType(i))
                    set i = i + 1
                endloop
                call TriggerAddCondition(.anyEventTrigg, Condition(function thistype.GetTriggerComponent))
            endif
   
            return TriggerAddCondition(.anyEventTrigg, Condition(func))
        endmethod

        method operator parent= takes thistype frm returns nothing
            if frm != Null then
                if .m_parent != frm then
                    call .removeNode()
                endif
                call frm.m_childs.insertNode(this)
            endif
            static if not PERSISTENT_CHILD_PROPERTIES then
                if .m_parent != Null then
                    set .localScale = .localScale*.m_parent.localScale
                endif
                set .localPosX = .screenPosX - frm.screenPosX
                set .localPosY = .screenPosY - frm.screenPosY
            endif
            set .m_parent = frm
            call refresh()
        endmethod

        method operator parent takes nothing returns thistype
            return .m_parent
        endmethod

        method operator text= takes string str returns nothing
            call BlzFrameSetText(.textFrameH, str)
        endmethod

        method operator text takes nothing returns string
            return BlzFrameGetText(.textFrameH)
        endmethod

        method operator maxLength= takes integer length returns nothing
            call BlzFrameSetTextSizeLimit(.textFrameH, length)
        endmethod

        method operator maxLength takes nothing returns integer
            return BlzFrameGetTextSizeLimit(.textFrameH)
        endmethod

        method operator textColor= takes integer color returns nothing
            call BlzFrameSetTextColor(.textFrameH, color)
        endmethod

        method operator texture= takes string filePath returns nothing
            set .mainTextureFile = filePath
            call BlzFrameSetTexture(.mainTextureH, filePath, 0, true)
            if StringLength(.disabledTextureFile) == 0 then
                set .disabledTexture = filePath
            endif
            if StringLength(.pushedTextureFile) == 0 then
                set .pushedTexture = filePath
            endif
        endmethod

        method operator texture takes nothing returns string
            return .mainTextureFile
        endmethod

        method operator disabledTexture= takes string filePath returns nothing
            set .disabledTextureFile = filePath
            call BlzFrameSetTexture(.disabledTextureH, filePath, 0, true)
        endmethod

        method operator disabledTexture takes nothing returns string
            return .disabledTextureFile
        endmethod

        method operator highlightTexture= takes string filePath returns nothing
            set .highlightTextureFile = filePath
            call BlzFrameSetTexture(.highlightTextureH, filePath, 0, true)
        endmethod

        method operator highlightTexture takes nothing returns string
            return .highlightTextureFile
        endmethod

        method operator pushedTexture= takes string filePath returns nothing
            set .pushedTextureFile = filePath
            call BlzFrameSetTexture(.pushedTextureH, filePath, 0, true)
        endmethod

        method operator pushedTexture takes nothing returns string
            return .pushedTextureFile
        endmethod

        method operator backgroundTexture= takes string filePath returns nothing
            set .backgroundTextureFile = filePath
            call BlzFrameSetTexture(.backgroundTextureH, filePath, 0, true)
        endmethod

        method operator backgroundTexture takes nothing returns string
            return .backgroundTextureFile
        endmethod

        method operator borderTexture= takes string filePath returns nothing
            set .borderTextureFile = filePath
            call BlzFrameSetTexture(.borderTextureH, filePath, 0, true)
        endmethod

        method operator borderTexture takes nothing returns string
            return .borderTextureFile
        endmethod

        method operator model= takes string filePath returns nothing
            set .modelFile = filePath
            call BlzFrameSetModel(.modelFrameH, filePath, 0)
        endmethod

        method operator model takes nothing returns string
            return .modelFile
        endmethod
       
        method operator width takes nothing returns real
            return .unscaledWidth*.scale
        endmethod
       
        method operator height takes nothing returns real
            return .unscaledHeight*.scale
        endmethod

        method operator localScale= takes real r returns nothing
            local thistype node = .m_childs.next

            set .m_localScale = RMaxBJ(r, 0.0001)
            call setSize(.unscaledWidth, .unscaledHeight)
            call setFont(.fontType, .fontSize, .fontFlags)
            call move(.localPosX, .localPosY)
            loop
                exitwhen node.head or node == 0
                set node.localScale = node.localScale
                call node.calcScreenPos()
                set node = node.next
            endloop
        endmethod

        method operator localScale takes nothing returns real
            return .m_localScale
        endmethod

        method operator scale takes nothing returns real
            if .parent == Null or not .inheritScale then
                return .localScale
            else
                return .localScale*.parent.scale
            endif
        endmethod

        method operator opacity= takes integer amount returns nothing
            local thistype node = .m_childs.next

            set .localOpacity = amount
            call BlzFrameSetAlpha(.frame, .opacity)
            loop
                exitwhen node.head or node == 0
                set node.opacity = node.localOpacity
                set node = node.next
            endloop
        endmethod

        method operator opacity takes nothing returns integer
            if .parent == Null or not .inheritOpacity then
                return .localOpacity
            else
                return R2I(I2R(.localOpacity)*I2R(.parent.opacity)/255.)
            endif
        endmethod

        method operator level= takes integer level returns nothing
            local thistype node = .m_childs.next

            set .m_level = level
            call BlzFrameSetLevel(.frame, .trueLevel)
            loop
                exitwhen node.head or node == 0
                set node.level = node.m_level
                set node = node.next
            endloop
        endmethod

        method operator level takes nothing returns integer
            return .m_level
        endmethod

        method operator trueLevel takes nothing returns integer
            if .parent == Null or not .inheritLevel then
                return .m_level
            else
                return .m_level+.parent.level
            endif
        endmethod

        method operator visible= takes boolean state returns nothing
            local thistype node = .m_childs.next

            set .visibleSelf = state
            call BlzFrameSetVisible(.frame, .visible)
            loop
                exitwhen node.head or node == 0
                set node.visible = node.visibleSelf
                set node = node.next
            endloop
        endmethod

        method operator visible takes nothing returns boolean
            if .parent == Null or not .inheritVisibility then
                return .visibleSelf
            else
                return .visibleSelf and .parent.visible
            endif
        endmethod

        method operator enabled= takes boolean state returns nothing
            local thistype node = .m_childs.next

            set .enabledSelf = state
            call BlzFrameSetEnable(.frame, .enabled)
            loop
                exitwhen node.head or node == 0
                set node.enabled = node.enabledSelf
                set node = node.next
            endloop
        endmethod

        method operator enabled takes nothing returns boolean
            if .parent == Null or not .inheritEnableState then
                return .enabledSelf
            else
                return .enabledSelf and .parent.enabled
            endif
        endmethod

        method operator vertexColor= takes integer color returns nothing
            call BlzFrameSetVertexColor(.modelFrameH, color)
        endmethod

        method operator value= takes real r returns nothing
            call BlzFrameSetValue(.frame, r)
        endmethod

        method operator value takes nothing returns real
            return BlzFrameGetValue(.frame)
        endmethod

        method operator stepSize= takes real r returns nothing
            set .m_stepSize = RMaxBJ(r, 0.0001)
            call BlzFrameSetStepSize(.frame, .m_stepSize)
        endmethod

        method operator stepSize takes nothing returns real
            return .m_stepSize
        endmethod

        method operator tooltips= takes thistype frame returns nothing
            set .m_tooltips = frame
            call BlzFrameSetTooltip(.frame, frame.frame)
        endmethod

        method operator tooltips takes nothing returns thistype
            return .m_tooltips
        endmethod
       
        method operator left takes nothing returns real
            return .screenPosX-.width*.pivotX
        endmethod
       
        method operator right takes nothing returns real
            return .left+.width
        endmethod
       
        method operator bottom takes nothing returns real
            return .screenPosY-.height*.pivotY
        endmethod
       
        method operator top takes nothing returns real
            return .bottom+.height
        endmethod
       
        private real m_screenPosX
        method operator screenPosX takes nothing returns real
            return .m_screenPosX
        endmethod
       
        private real m_screenPosY
        method operator screenPosY takes nothing returns real
            return .m_screenPosY
        endmethod
       
        private method normalizePosX takes real x returns real
            return RMinBJ(RMaxBJ(x, UIUtils.FrameBoundWidth+.width*.pivotX), UIUtils.ResolutionWidth-UIUtils.FrameBoundWidth-.width*(1.-.pivotX))
        endmethod
       
        private method normalizeScaledPosX takes real x returns real
            return RMinBJ(RMaxBJ(x, UIUtils.FrameBoundWidth+.width*.pivotX*UIUtils.ScaleFactor), UIUtils.ResolutionWidth-UIUtils.FrameBoundWidth-.width*(1.-.pivotX)*UIUtils.ScaleFactor)
        endmethod
       
        private method operator scaledLeft takes nothing returns real
            return .scaledScreenPosX-.width*.pivotX*UIUtils.ScaleFactor
        endmethod
       
        private method operator scaledBottom takes nothing returns real
            return .scaledScreenPosY-.height*.pivotY*UIUtils.ScaleFactor
        endmethod
       
        private real m_scaledScreenPosX
        private method operator scaledScreenPosX takes nothing returns real
            return .m_scaledScreenPosX
        endmethod
       
        private real m_scaledScreenPosY
        private method operator scaledScreenPosY takes nothing returns real
            return .m_scaledScreenPosY
        endmethod
        
        private method calcScreenPos takes nothing returns nothing
            if .parent == Null or not .inheritPosition then
                if not .isSimple then
                    set .m_screenPosX = normalizePosX(.localPosX+UIUtils.ResolutionWidth*.anchorX)
                    set .m_scaledScreenPosX = normalizeScaledPosX(.localPosX*UIUtils.ScaleFactor+UIUtils.ResolutionWidth*.anchorX)
                else
                    set .m_screenPosX = .localPosX+UIUtils.ResolutionWidth*.anchorX
                    set .m_scaledScreenPosX = .localPosX*UIUtils.ScaleFactor+UIUtils.ResolutionWidth*.anchorX
                endif
                set .m_screenPosY = .localPosY+UIUtils.ResolutionHeight*.anchorY
                set .m_scaledScreenPosY = .localPosY*UIUtils.ScaleFactor+UIUtils.ResolutionHeight*.anchorY
            elseif .scalePosition then
                set .m_screenPosX = .parent.left+.parent.width*.anchorX+.localPosX*.parent.scale
                set .m_screenPosY = .parent.bottom+.parent.height*.anchorY+.localPosY*.parent.scale
                set .m_scaledScreenPosX = .parent.scaledLeft+(.parent.width*.anchorX+.localPosX*.parent.scale)*UIUtils.ScaleFactor
                set .m_scaledScreenPosY = .parent.scaledBottom+(.parent.height*.anchorY+.localPosY*.parent.scale)*UIUtils.ScaleFactor
            else
                set .m_screenPosX = .parent.left+.parent.width*.anchorX+.localPosX
                set .m_screenPosY = .parent.bottom+.parent.height*.anchorY+.localPosY
                set .m_scaledScreenPosX = .parent.scaledLeft+(.parent.width*.anchorX+.localPosX)*UIUtils.ScaleFactor
                set .m_scaledScreenPosY = .parent.scaledBottom+(.parent.height*.anchorY+.localPosY)*UIUtils.ScaleFactor
            endif
        endmethod

        method setAnchorPoint takes real x, real y returns nothing
            set .anchorX = x
            set .anchorY = y
            call calcScreenPos()
            call move(.localPosX, .localPosY)
        endmethod

        method setPivotPoint takes real x, real y returns nothing
            set .pivotX = x
            set .pivotY = y
            call move(.localPosX, .localPosY)
        endmethod

        method setSize takes real width, real height returns nothing
            set .unscaledWidth  = RMaxBJ(width,  0)
            set .unscaledHeight = RMaxBJ(height, 0)
            call calcScreenPos()
            call BlzFrameSetSize(frame, .width*UIUtils.ScaleFactor*UIUtils.PXTODPI, .height*UIUtils.ScaleFactor*UIUtils.PXTODPI)
            if .pivotX + .pivotY + .anchorX + .anchorY != 0 then
                call move(.localPosX, .localPosY)
            endif
        endmethod

        method move takes real x, real y returns nothing
            local thistype node = .m_childs.next

            if not .alwaysRefresh and (not .visible or .opacity <= 0) then
                return
            endif

            set .localPosX = x
            set .localPosY = y
            call calcScreenPos()
            if not .isSimple then
                set x = normalizeScaledPosX(.scaledScreenPosX-.width*.pivotX*UIUtils.ScaleFactor)
            else
                set x = .scaledScreenPosX-.width*.pivotX*UIUtils.ScaleFactor
            endif
            call BlzFrameSetAbsPoint(.frame, FRAMEPOINT_BOTTOMLEFT, UIUtils.GetScreenPosX(x), UIUtils.GetScreenPosY(.scaledScreenPosY-.height*.pivotY*UIUtils.ScaleFactor))
            loop
                exitwhen node.head or node == 0
                call node.move(node.localPosX, node.localPosY)
                set node = node.next
            endloop
        endmethod

        method moveEx takes real x, real y returns nothing
            if .parent == Null or not .inheritPosition then
                call move(x, y)
            else
                call move((x-.parent.screenPosX)/.parent.localScale, (y-.parent.screenPosY)/.parent.localScale)
            endif
        endmethod

        method relate takes thistype relative, real x, real y returns nothing
            if .parent == Null then
                call move(relative.screenPosX+x, relative.screenPosY+y)
            else
                call moveEx(relative.screenPosX+x, relative.screenPosY+y)
            endif
        endmethod
       
        method refresh takes nothing returns nothing
            set .visible = .visibleSelf
            set .enabled = .enabledSelf
            set .opacity = .localOpacity
            set .level   = .m_level
            set .localScale = .localScale
            call setFont(.fontType, .fontSize, .fontFlags)
        endmethod

        method click takes nothing returns nothing
            call BlzFrameClick(.frame)
        endmethod

        method cageMouse takes boolean state returns nothing
            call BlzFrameCageMouse(.frame, state)
        endmethod

        method setFocus takes boolean state returns nothing
            call BlzFrameSetFocus(.frame, state)
        endmethod

        method setSpriteAnimate takes integer primaryProp, integer flags returns nothing
            call BlzFrameSetSpriteAnimate(.frame, primaryProp, flags)
        endmethod

        method setMinMaxValue takes real min, real max returns nothing
            set .valueMin = min
            set .valueMax = max
            call BlzFrameSetMinMaxValue(.frame, min, max)
        endmethod

        method setFont takes string fontType, real fontSize, integer flags returns nothing
            set .fontSize = fontSize
            set .fontType = fontType
            set .fontFlags = flags
            if .frameType == TYPE_SIMPLE_TEXT then
                call BlzFrameSetFont(.textFrameH, fontType, fontSize*.scale, flags)
            endif
        endmethod

        method setTextAlignment takes textaligntype vertical, textaligntype horizontal returns nothing
            call BlzFrameSetTextAlignment(.textFrameH, vertical, horizontal)
        endmethod

        private method getSubFrame takes string name returns framehandle
            local framehandle h = BlzGetFrameByName(name, .context)
           
            if h == null then
                return .frame
            else
                return h
            endif
        endmethod

        method forEachChild takes code func returns nothing
            local thistype node = .m_childs.next

            call TriggerAddAction(ExecTrigg, func)
            loop
                exitwhen node.head or node == 0
                set EnumChild = node
                call TriggerExecute(ExecTrigg)
                set node = node.next
            endloop
            call TriggerClearActions(ExecTrigg)
        endmethod

        method destroy takes nothing returns nothing
            local thistype node = .m_childs.next
   
            loop
                exitwhen node.head or node == 0
                call node.destroy()
                set node = node.next
            endloop
            call BlzDestroyFrame(.frame)
            call DestroyTrigger(.anyEventTrigg)
            call StoreInteger(GC, name, I2S(.context), GetStoredInteger(GC, name, "0"))
            call StoreInteger(GC, name, "0", .context)
            call AllComponents.remove(this)
            call .m_childs.flushNode()
            call removeNode()
            call deallocate()

            set .anyEventTrigg      = null
            set .mainTextureH       = null
            set .disabledTextureH   = null
            set .highlightTextureH  = null
            set .pushedTextureH     = null
            set .backgroundTextureH = null
            set .borderTextureH     = null
            set .textFrameH         = null
            set .modelFrameH        = null
            set .frame              = null
            set .name               = null
            set .frameType          = null
            set .m_parent           = Null
            set .m_childs           = 0
        endmethod

        static method create takes boolean isSimple, string frameType, thistype parent, real x, real y, integer level returns thistype
            local thistype this = allocate()
            local integer tempInt
   
            set .context = GetStoredInteger(GC, frameType, "0")
            set tempInt  = GetStoredInteger(GC, frameType, I2S(context))
            if tempInt == 0 then
                call StoreInteger(GC, frameType, "0", context+1)
            else
                call StoreInteger(GC, frameType, "0", tempInt)
            endif
   
            set .parent             = parent
            set .m_childs           = createNode()
            set .isSimple           = IsSimple(frameType, isSimple)
            if .isSimple then
                set .frame          = BlzCreateSimpleFrame(frameType, DefaultFrame.Game, .context)
            else
                set .frame          = BlzCreateFrame(frameType, DefaultFrame.Game, 0, .context)
            endif
            set .mainTextureH       = getSubFrame(frameType + "Texture")
            set .disabledTextureH   = getSubFrame(frameType + "Disabled")
            set .highlightTextureH  = getSubFrame(frameType + "Highlight")
            set .pushedTextureH     = getSubFrame(frameType + "Pushed")
            set .backgroundTextureH = getSubFrame(frameType + "Background")
            set .borderTextureH     = getSubFrame(frameType + "Border")
            set .textFrameH         = getSubFrame(frameType + "Text")
            set .modelFrameH        = getSubFrame(frameType + "Model")

            set .inheritScale       = true
            set .inheritOpacity     = true
            set .inheritVisibility  = true
            set .inheritEnableState = true
            set .inheritPosition    = true
            set .inheritLevel       = true
            set .scalePosition      = true
            set .alwaysRefresh      = true
   
            set .unscaledWidth      = BlzFrameGetWidth(.frame)*(RESOLUTION_HEIGHT/0.6)
            set .unscaledHeight     = BlzFrameGetHeight(.frame)*(RESOLUTION_HEIGHT/0.6)
            set .frameType          = frameType
            set .name               = frameType + I2S(.context)
            set .level              = level
            set .visibleSelf        = true
            set .enabledSelf        = true
            set .fontType           = "Fonts\\FRIZQT__.TTF"
            set .fontSize           = 0.013
            set .fontFlags          = 0
            set .value              = 0.0
            set .localScale         = 1.0
            set .anchorX            = 0.0
            set .anchorY            = 0.0
            set .pivotX             = 0.0
            set .pivotY             = 0.0
            set .opacity            = 255
   
            set .mainTextureFile       = ""
            set .disabledTextureFile   = ""
            set .pushedTextureFile     = ""
            set .highlightTextureFile  = ""
            set .backgroundTextureFile = ""
            set .borderTextureFile     = ""
            set .modelFile             = ""
   
            call move(x, y)
            call setMinMaxValue(0.0, 1.0)
            call AllComponents.add(this)
            call SaveInteger(HT, GetHandleId(.frame), 0, this)

            return this
        endmethod

        private static method onInit takes nothing returns nothing
            set HT = InitHashtable()
            set GC = InitGameCache(CACHE_NAME)
            call BlzLoadTOCFile(TOC_FILE)
        endmethod
    endstruct

    private struct AllComponents extends array
        implement LinkedList

        static method add takes thistype this returns nothing
            call base.insertNode(this)
        endmethod

        static method remove takes thistype this returns nothing
            call removeNode()
        endmethod
    endstruct
   
endlibrary