local cloneref = (cloneref or clonereference or function(instance: any)
    return instance
end)
local CoreGui: CoreGui = cloneref(game:GetService("CoreGui"))
local Players: Players = cloneref(game:GetService("Players"))
local RunService: RunService = cloneref(game:GetService("RunService"))
local SoundService: SoundService = cloneref(game:GetService("SoundService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))
local Teams: Teams = cloneref(game:GetService("Teams"))
local TweenService: TweenService = cloneref(game:GetService("TweenService"))

local getgenv = getgenv or function()
    return shared
end
local setclipboard = setclipboard or nil
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui or function()
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local Labels = {}
local Buttons = {}
local Toggles = {}
local Options = {} 

local Library = {
    LocalPlayer = LocalPlayer,
    DevicePlatform = nil,
    IsMobile = false,
    IsRobloxFocused = true,

    ScreenGui = nil,

    SearchText = "",
    Searching = false,
    LastSearchTab = nil,

    ActiveTab = nil,
    Tabs = {},
    DependencyBoxes = {},

    KeybindFrame = nil,
    KeybindContainer = nil,
    KeybindToggles = {},

    Notifications = {},

    ToggleKeybind = Enum.KeyCode.RightControl,
    TweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    NotifyTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    Toggled = false,
    Unloaded = false,

    Labels = Labels,
    Buttons = Buttons,
    Toggles = Toggles,
    Options = Options,

    NotifySide = "Right",
    ShowCustomCursor = false,
    ForceCheckbox = false,
    ShowToggleFrameInKeybinds = true,
    NotifyOnError = false,

    CantDragForced = false,

    Signals = {},
    UnloadSignals = {},

    MinSize = Vector2.new(480, 360),
    DPIScale = 1,
    CornerRadius = 4,

    IsLightTheme = false,
    Scheme = {
        BackgroundColor = Color3.fromRGB(15, 15, 15),
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(125, 85, 255),
        OutlineColor = Color3.fromRGB(40, 40, 40),
        FontColor = Color3.new(1, 1, 1),
        Font = Font.fromEnum(Enum.Font.Code),

        Red = Color3.fromRGB(255, 50, 50),
        Dark = Color3.new(0, 0, 0),
        White = Color3.new(1, 1, 1),
    },

    Registry = {},
    DPIRegistry = {},
}

local ObsidianImageManager = {
    Assets = {
        TransparencyTexture = {
            RobloxId = 139785960036434,
            Path = "Obsidian/assets/TransparencyTexture.png",

            Id = nil
        },
        
        SaturationMap = {
            RobloxId = 4155801252,
            Path = "Obsidian/assets/SaturationMap.png",

            Id = nil
        }
    }
}
do
    local BaseURL = "https://raw.githubusercontent.com/9kkinc-sudo/ui_lib/main/"

    local function RecursiveCreatePath(Path: string, IsFile: boolean?)
        if not isfolder or not makefolder then return end

        local Segments = Path:split("/")
        local TraversedPath = ""

        if IsFile then
            table.remove(Segments, #Segments)
        end

        for _, Segment in ipairs(Segments) do
            if not isfolder(TraversedPath .. Segment) then
                makefolder(TraversedPath .. Segment)
            end

            TraversedPath = TraversedPath .. Segment .. "/"
        end

        return TraversedPath
    end

    function ObsidianImageManager.GetAsset(AssetName: string)
        if not ObsidianImageManager.Assets[AssetName] then
            return nil
        end

        local AssetData = ObsidianImageManager.Assets[AssetName]
        if AssetData.Id then
            return AssetData.Id
        end

        local AssetID = `rbxassetid://{AssetData.RobloxId}`

        if getcustomasset then
            local Success, NewID = pcall(getcustomasset, AssetData.Path)

            if Success and NewID then
                AssetID = NewID
            end
        end

        AssetData.Id = AssetID
        return AssetID
    end

    function ObsidianImageManager.DownloadAsset(AssetPath: string)
        if not getcustomasset or not writefile or not isfile then
            return
        end

        RecursiveCreatePath(AssetPath, true)

        if isfile(AssetPath) then
            return
        end

        --local URLPath = AssetPath:gsub("Obsidian/", "")
        local URLPath = AssetPath:match("[^/]+$")
        writefile(AssetPath, game:HttpGet(`{BaseURL}{URLPath}`))
    end

    for _, Data in ObsidianImageManager.Assets do
        ObsidianImageManager.DownloadAsset(Data.Path)
    end
end

if RunService:IsStudio() then
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        Library.IsMobile = true
        Library.MinSize = Vector2.new(480, 240)
    else
        Library.IsMobile = false
        Library.MinSize = Vector2.new(480, 360)
    end
else
    pcall(function()
        Library.DevicePlatform = UserInputService:GetPlatform()
    end)
    Library.IsMobile = (Library.DevicePlatform == Enum.Platform.Android or Library.DevicePlatform == Enum.Platform.IOS)
    Library.MinSize = Library.IsMobile and Vector2.new(480, 240) or Vector2.new(480, 360)
end

local Templates = {
    --// UI \\-
    Frame = {
        BorderSizePixel = 0,
    },
    ImageLabel = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    },
    ImageButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
    },
    ScrollingFrame = {
        BorderSizePixel = 0,
    },
    TextLabel = {
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextButton = {
        AutoButtonColor = false,
        BorderSizePixel = 0,
        FontFace = "Font",
        RichText = true,
        TextColor3 = "FontColor",
    },
    TextBox = {
        BorderSizePixel = 0,
        FontFace = "Font",
        PlaceholderColor3 = function()
            local H, S, V = Library.Scheme.FontColor:ToHSV()
            return Color3.fromHSV(H, S, V / 2)
        end,
        Text = "",
        TextColor3 = "FontColor",
    },
    UIListLayout = {
        SortOrder = Enum.SortOrder.LayoutOrder,
    },
    UIStroke = {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    },

    --// Library \\--
    Window = {
        Title = "No Title",
        Footer = "No Footer",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(720, 600),
        IconSize = UDim2.fromOffset(30, 30),
        AutoShow = true,
        Center = true,
        Resizable = true,
        SearchbarSize = UDim2.fromScale(1, 1),
        CornerRadius = 4,
        NotifySide = "Right",
        ShowCustomCursor = false,
        Font = Enum.Font.Code,
        ToggleKeybind = Enum.KeyCode.RightControl,
        MobileButtonsSide = "Left",
    },
    Toggle = {
        Text = "Toggle",
        Default = false,

        Callback = function() end,
        Changed = function() end,

        Risky = false,
        Disabled = false,
        Visible = true,
    },
    Input = {
        Text = "Input",
        Default = "",
        Finished = false,
        Numeric = false,
        ClearTextOnFocus = true,
        Placeholder = "",
        AllowEmpty = true,
        EmptyReset = "---",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Slider = {
        Text = "Slider",
        Default = 0,
        Min = 0,
        Max = 100,
        Rounding = 0,

        Prefix = "",
        Suffix = "",

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Dropdown = {
        Values = {},
        DisabledValues = {},
        Multi = false,
        MaxVisibleDropdownItems = 8,

        Callback = function() end,
        Changed = function() end,

        Disabled = false,
        Visible = true,
    },
    Viewport = {
        Object = nil,
        Camera = nil,
        Clone = true,
        AutoFocus = true,
        Interactive = false,
        Height = 200,
        Visible = true,
    },
    Image = {
        Image = "",
        Transparency = 0,
        Color = Color3.new(1, 1, 1),
        RectOffset = Vector2.zero,
        RectSize = Vector2.zero,
        ScaleType = Enum.ScaleType.Fit,
        Height = 200,
        Visible = true,
    },

    --// Addons \\-
    KeyPicker = {
        Text = "KeyPicker",
        Default = "None",
        Mode = "Toggle",
        Modes = { "Always", "Toggle", "Hold" },
        SyncToggleState = false,

        Callback = function() end,
        ChangedCallback = function() end,
        Changed = function() end,
        Clicked = function() end,
    },
    ColorPicker = {
        Default = Color3.new(1, 1, 1),

        Callback = function() end,
        Changed = function() end,
    },
}

local Places = {
    Bottom = { 0, 1 },
    Right = { 1, 0 },
}
local Sizes = {
    Left = { 0.5, 1 },
    Right = { 0.5, 1 },
}

--// Basic Functions \\--
local function ApplyDPIScale(Dimension, ExtraOffset)
    if typeof(Dimension) == "UDim" then
        return UDim.new(Dimension.Scale, Dimension.Offset * Library.DPIScale)
    end

    if ExtraOffset then
        return UDim2.new(
            Dimension.X.Scale,
            (Dimension.X.Offset * Library.DPIScale) + (ExtraOffset[1] * Library.DPIScale),
            Dimension.Y.Scale,
            (Dimension.Y.Offset * Library.DPIScale) + (ExtraOffset[2] * Library.DPIScale)
        )
    end

    return UDim2.new(
        Dimension.X.Scale,
        Dimension.X.Offset * Library.DPIScale,
        Dimension.Y.Scale,
        Dimension.Y.Offset * Library.DPIScale
    )
end
local function ApplyTextScale(TextSize)
    return TextSize * Library.DPIScale
end

local function WaitForEvent(Event, Timeout, Condition)
    local Bindable = Instance.new("BindableEvent")
    local Connection = Event:Once(function(...)
        if not Condition or typeof(Condition) == "function" and Condition(...) then
            Bindable:Fire(true)
        else
            Bindable:Fire(false)
        end
    end)
    task.delay(Timeout, function()
        Connection:Disconnect()
        Bindable:Fire(false)
    end)

    local Result = Bindable.Event:Wait()
    Bindable:Destroy()

    return Result
end

local function IsMouseInput(Input: InputObject, IncludeM2: boolean?)
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or (IncludeM2 == true and Input.UserInputType == Enum.UserInputType.MouseButton2)
        or Input.UserInputType == Enum.UserInputType.Touch
end
local function IsClickInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and Input.UserInputState == Enum.UserInputState.Begin
        and Library.IsRobloxFocused
end
local function IsHoverInput(Input: InputObject)
    return (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
        and Input.UserInputState == Enum.UserInputState.Change
end
local function IsDragInput(Input: InputObject, IncludeM2: boolean?)
    return IsMouseInput(Input, IncludeM2)
        and (Input.UserInputState == Enum.UserInputState.Begin or Input.UserInputState == Enum.UserInputState.Change)
        and Library.IsRobloxFocused
end

local function GetTableSize(Table: { [any]: any })
    local Size = 0

    for _, _ in pairs(Table) do
        Size += 1
    end

    return Size
end
local function StopTween(Tween: TweenBase)
    if not (Tween and Tween.PlaybackState == Enum.PlaybackState.Playing) then
        return
    end

    Tween:Cancel()
end
local function Trim(Text: string)
    return Text:match("^%s*(.-)%s*$")
end
local function Round(Value, Rounding)
    assert(Rounding >= 0, "Invalid rounding number.")

    if Rounding == 0 then
        return math.floor(Value)
    end

    return tonumber(string.format("%." .. Rounding .. "f", Value))
end

local function GetPlayers(ExcludeLocalPlayer: boolean?)
    local PlayerList = Players:GetPlayers()

    if ExcludeLocalPlayer then
        local Idx = table.find(PlayerList, LocalPlayer)
        if Idx then
            table.remove(PlayerList, Idx)
        end
    end

    table.sort(PlayerList, function(Player1, Player2)
        return Player1.Name:lower() < Player2.Name:lower()
    end)

    return PlayerList
end
local function GetTeams()
    local TeamList = Teams:GetTeams()

    table.sort(TeamList, function(Team1, Team2)
        return Team1.Name:lower() < Team2.Name:lower()
    end)

    return TeamList
end

function Library:UpdateKeybindFrame()
    if not Library.KeybindFrame then
        return
    end

    local XSize = 0
    for _, KeybindToggle in pairs(Library.KeybindToggles) do
        if not KeybindToggle.Holder.Visible then
            continue
        end

        local FullSize = KeybindToggle.Label.Size.X.Offset + KeybindToggle.Label.Position.X.Offset
        if FullSize > XSize then
            XSize = FullSize
        end
    end

    Library.KeybindFrame.Size = UDim2.fromOffset(XSize + 18 * Library.DPIScale, 0)
end
function Library:UpdateDependencyBoxes()
    for _, Depbox in pairs(Library.DependencyBoxes) do
        Depbox:Update(true)
    end

    if Library.Searching then
        Library:UpdateSearch(Library.SearchText)
    end
end

local function GetSearchElementVisibility(ElementInfo)
    if typeof(ElementInfo.Visible) == "boolean" then
        return ElementInfo.Visible
    end

    return true
end

local function SearchElementMatches(Value, Search)
    return typeof(Value) == "string" and Value:lower():find(Search, 1, true) ~= nil
end

local function CheckDepbox(Box, Search)
    local VisibleElements = 0

    for _, ElementInfo in pairs(Box.Elements) do
        if ElementInfo.Type == "Divider" then
            ElementInfo.Holder.Visible = false
            continue
        elseif ElementInfo.SubButton then
            --// Check if any of the Buttons Name matches with Search
            local Visible = false

            --// Check if Search matches Element's Name and if Element is Visible
            if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                Visible = true
            else
                ElementInfo.Base.Visible = false
            end
            if SearchElementMatches(ElementInfo.SubButton.Text, Search) and ElementInfo.SubButton.Visible then
                Visible = true
            else
                ElementInfo.SubButton.Base.Visible = false
            end
            ElementInfo.Holder.Visible = Visible
            if Visible then
                VisibleElements += 1
            end

            continue
        end

        --// Check if Search matches Element's Name and if Element is Visible
        if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
            ElementInfo.Holder.Visible = true
            VisibleElements += 1
        else
            ElementInfo.Holder.Visible = false
        end
    end

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        VisibleElements += CheckDepbox(Depbox, Search)
    end

    return VisibleElements
end
local function RestoreDepbox(Box)
    for _, ElementInfo in pairs(Box.Elements) do
        ElementInfo.Holder.Visible = GetSearchElementVisibility(ElementInfo)

        if ElementInfo.SubButton then
            ElementInfo.Base.Visible = ElementInfo.Visible
            ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
        end
    end

    Box:Resize()
    Box.Holder.Visible = true

    for _, Depbox in pairs(Box.DependencyBoxes) do
        if not Depbox.Visible then
            continue
        end

        RestoreDepbox(Depbox)
    end
end

function Library:UpdateSearch(SearchText)
    Library.SearchText = SearchText

    --// Reset Elements Visibility in Last Tab Searched
    if Library.LastSearchTab then
        for _, Groupbox in pairs(Library.LastSearchTab.Groupboxes) do
            for _, ElementInfo in pairs(Groupbox.Elements) do
                ElementInfo.Holder.Visible = GetSearchElementVisibility(ElementInfo)

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(Groupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            Groupbox:Resize()
            Groupbox.Holder.Visible = true
        end

        for _, Tabbox in pairs(Library.LastSearchTab.Tabboxes) do
            for _, Tab in pairs(Tabbox.Tabs) do
                for _, ElementInfo in pairs(Tab.Elements) do
                    ElementInfo.Holder.Visible = GetSearchElementVisibility(ElementInfo)

                    if ElementInfo.SubButton then
                        ElementInfo.Base.Visible = ElementInfo.Visible
                        ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                    end
                end

                for _, Depbox in pairs(Tab.DependencyBoxes) do
                    if not Depbox.Visible then
                        continue
                    end

                    RestoreDepbox(Depbox)
                end

                Tab.ButtonHolder.Visible = true
            end

            Tabbox.ActiveTab:Resize()
            Tabbox.Holder.Visible = true
        end

        for _, DepGroupbox in pairs(Library.LastSearchTab.DependencyGroupboxes) do
            if not DepGroupbox.Visible then
                continue
            end

            for _, ElementInfo in pairs(DepGroupbox.Elements) do
                ElementInfo.Holder.Visible = GetSearchElementVisibility(ElementInfo)

                if ElementInfo.SubButton then
                    ElementInfo.Base.Visible = ElementInfo.Visible
                    ElementInfo.SubButton.Base.Visible = ElementInfo.SubButton.Visible
                end
            end

            for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                RestoreDepbox(Depbox)
            end

            DepGroupbox:Resize()
            DepGroupbox.Holder.Visible = true
        end
    end

    --// Cancel Search if Search Text is empty
    local Search = SearchText:lower()
    if Trim(Search) == "" or Library.ActiveTab.IsKeyTab then
        Library.Searching = false
        Library.LastSearchTab = nil
        return
    end

    Library.Searching = true

    --// Loop through Groupboxes to get Elements Info
    for _, Groupbox in pairs(Library.ActiveTab.Groupboxes) do
        local VisibleElements = 0

        for _, ElementInfo in pairs(Groupbox.Elements) do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if SearchElementMatches(ElementInfo.SubButton.Text, Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in pairs(Groupbox.DependencyBoxes) do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            Groupbox:Resize()
        end
        Groupbox.Holder.Visible = VisibleElements > 0
    end

    for _, Tabbox in pairs(Library.ActiveTab.Tabboxes) do
        local VisibleTabs = 0
        local VisibleElements = {}

        for _, Tab in pairs(Tabbox.Tabs) do
            VisibleElements[Tab] = 0

            for _, ElementInfo in pairs(Tab.Elements) do
                if ElementInfo.Type == "Divider" then
                    ElementInfo.Holder.Visible = false
                    continue
                elseif ElementInfo.SubButton then
                    --// Check if any of the Buttons Name matches with Search
                    local Visible = false

                    --// Check if Search matches Element's Name and if Element is Visible
                    if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                        Visible = true
                    else
                        ElementInfo.Base.Visible = false
                    end
                    if SearchElementMatches(ElementInfo.SubButton.Text, Search) and ElementInfo.SubButton.Visible then
                        Visible = true
                    else
                        ElementInfo.SubButton.Base.Visible = false
                    end
                    ElementInfo.Holder.Visible = Visible
                    if Visible then
                        VisibleElements[Tab] += 1
                    end

                    continue
                end

                --// Check if Search matches Element's Name and if Element is Visible
                if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                    ElementInfo.Holder.Visible = true
                    VisibleElements[Tab] += 1
                else
                    ElementInfo.Holder.Visible = false
                end
            end

            for _, Depbox in pairs(Tab.DependencyBoxes) do
                if not Depbox.Visible then
                    continue
                end

                VisibleElements[Tab] += CheckDepbox(Depbox, Search)
            end
        end

        for Tab, Visible in pairs(VisibleElements) do
            Tab.ButtonHolder.Visible = Visible > 0
            if Visible > 0 then
                VisibleTabs += 1

                if Tabbox.ActiveTab == Tab then
                    Tab:Resize()
                elseif VisibleElements[Tabbox.ActiveTab] == 0 then
                    Tab:Show()
                end
            end
        end

        --// Update Tabbox Visibility if any visible
        Tabbox.Holder.Visible = VisibleTabs > 0
    end

    for _, DepGroupbox in pairs(Library.ActiveTab.DependencyGroupboxes) do
        if not DepGroupbox.Visible then
            continue
        end

        local VisibleElements = 0

        for _, ElementInfo in pairs(DepGroupbox.Elements) do
            if ElementInfo.Type == "Divider" then
                ElementInfo.Holder.Visible = false
                continue
            elseif ElementInfo.SubButton then
                --// Check if any of the Buttons Name matches with Search
                local Visible = false

                --// Check if Search matches Element's Name and if Element is Visible
                if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                    Visible = true
                else
                    ElementInfo.Base.Visible = false
                end
                if SearchElementMatches(ElementInfo.SubButton.Text, Search) and ElementInfo.SubButton.Visible then
                    Visible = true
                else
                    ElementInfo.SubButton.Base.Visible = false
                end
                ElementInfo.Holder.Visible = Visible
                if Visible then
                    VisibleElements += 1
                end

                continue
            end

            --// Check if Search matches Element's Name and if Element is Visible
            if SearchElementMatches(ElementInfo.Text, Search) and ElementInfo.Visible then
                ElementInfo.Holder.Visible = true
                VisibleElements += 1
            else
                ElementInfo.Holder.Visible = false
            end
        end

        for _, Depbox in pairs(DepGroupbox.DependencyBoxes) do
            if not Depbox.Visible then
                continue
            end

            VisibleElements += CheckDepbox(Depbox, Search)
        end

        --// Update Groupbox Size and Visibility if found any element
        if VisibleElements > 0 then
            DepGroupbox:Resize()
        end
        DepGroupbox.Holder.Visible = VisibleElements > 0
    end

    --// Set Last Tab to Current One
    Library.LastSearchTab = Library.ActiveTab
end

function Library:AddToRegistry(Instance, Properties)
    Library.Registry[Instance] = Properties
end

function Library:RemoveFromRegistry(Instance)
    Library.Registry[Instance] = nil
end

function Library:UpdateColorsUsingRegistry()
    for Instance, Properties in pairs(Library.Registry) do
        for Property, ColorIdx in pairs(Properties) do
            if typeof(ColorIdx) == "string" then
                Instance[Property] = Library.Scheme[ColorIdx]
            elseif typeof(ColorIdx) == "function" then
                Instance[Property] = ColorIdx()
            end
        end
    end
end

function Library:UpdateDPI(Instance, Properties)
    if not Library.DPIRegistry[Instance] then
        return
    end

    for Property, Value in pairs(Properties) do
        Library.DPIRegistry[Instance][Property] = Value and Value or nil
    end
end

function Library:SetDPIScale(DPIScale: number)
    Library.DPIScale = DPIScale / 100
    Library.MinSize *= Library.DPIScale

    for Instance, Properties in pairs(Library.DPIRegistry) do
        for Property, Value in pairs(Properties) do
            if Property == "DPIExclude" or Property == "DPIOffset" then
                continue
            elseif Property == "TextSize" then
                Instance[Property] = ApplyTextScale(Value)
            else
                Instance[Property] = ApplyDPIScale(Value, Properties["DPIOffset"][Property])
            end
        end
    end

    for _, Tab in pairs(Library.Tabs) do
        if Tab.IsKeyTab then
            continue
        end

        Tab:Resize(true)
        for _, Groupbox in pairs(Tab.Groupboxes) do
            Groupbox:Resize()
        end
        for _, Tabbox in pairs(Tab.Tabboxes) do
            for _, SubTab in pairs(Tabbox.Tabs) do
                SubTab:Resize()
            end
        end
    end

    for _, Option in pairs(Options) do
        if Option.Type == "Dropdown" then
            Option:RecalculateListSize()
        elseif Option.Type == "KeyPicker" then
            Option:Update()
        end
    end

    Library:UpdateKeybindFrame()
    for _, Notification in pairs(Library.Notifications) do
        Notification:Resize()
    end
    
    if Library.ActiveTab and Library.ActiveTab.Show then Library.ActiveTab:Show() end
end

function Library:GiveSignal(Connection: RBXScriptConnection)
    table.insert(Library.Signals, Connection)
    return Connection
end

local FetchIcons, Icons = pcall(function()
    local Lucide = {}

local IS_GETCUSTOMASSET_BROKEN = false

if writefile and isfolder and makefolder and getcustomasset then
	if not isfolder("lucide-icons") then
		makefolder("lucide-icons")
	end

	if not isfile("lucide-icons/version.txt") then
		writefile("lucide-icons/version.txt", "2026-07-28T16:19:09.520892841+00:00")
	end

	local ShouldUpdate = readfile("lucide-icons/version.txt") ~= "2026-07-28T16:19:09.520892841+00:00"

	if ShouldUpdate then
		writefile("lucide-icons/version.txt", "2026-07-28T16:19:09.520892841+00:00")
	end

	for spritesheet = 1, 2 do
		if isfile(`lucide-icons/{spritesheet}.png`) and not ShouldUpdate then
			continue
		end

		writefile(
			`lucide-icons/{spritesheet}.png`,
			game:HttpGet(
				`https://raw.githubusercontent.com/9kkinc-sudo/ui_lib/main/{spritesheet}.png`
			)
		)
	end

	local Success, _Error = pcall(function()
		return getcustomasset("lucide-icons/1.png")
	end)

	IS_GETCUSTOMASSET_BROKEN = not Success
end

local icons = {{"align-vertical-distribute-center","chevron-down","list-restart","table-cells-split","gavel","dna-off","refresh-ccw-dot","venus","bean","circle-question-mark","folder-code","bolt","heater","feather","align-horizontal-distribute-center","grip-vertical","pill-bottle","person-standing","badge-swiss-franc","between-horizontal-end","file-braces-corner","rotate-cw","house-plus","bus-front","shield-ellipsis","between-vertical-end","globe-lock","tags","concierge-bell","bookmark-minus","file-down","picture-in-picture","messages-square","scissors","file-check-corner","phone-call","anchor","hand-helping","text-wrap","birdhouse","wifi-off","cloud-alert","message-square","cloud-download","folder-plus","cctv-off","mirror-round","user-round","pointer","between-horizontal-start","chevrons-up-down","brush","message-circle-more","parentheses","book-up-2","flame","chevrons-up","square-dashed","square-mouse-pointer","superscript","signal","wifi-cog","hexagon","navigation-2-off","eye-off","arrows-up-from-line","file-code-corner","square-centerline-dashed-horizontal","panels-right-bottom","scaling","hash","arrow-left-from-line","ship","ticket-percent","calendar-clock","x","non-binary","voicemail","presentation","tree-palm","badge","captions-off","align-vertical-justify-center","download","mouse-right","lens-convex","focus","diamond-percent","arrow-big-up","volume-x","mouse-pointer-click","origami","hard-drive","grid-2x2-x","package-minus","cloud","pipette","corner-left-down","badge-cent","cloud-lightning","user-round-pen","arrow-left-to-line","book-open-text","monitor-cloud","parking-meter","cat","heart-handshake","dam","trees","ham","circle-pause","chess-king","bean-off","rat","separator-horizontal","ambulance","signal-zero","citrus","phone-missed","calendar-off","chart-column","battery-medium","square-minus","star-check","decimals-arrow-left","folder-output","menu","image-down","terminal","angry","circle-dot-dashed","medal","cake-slice","git-graph","armchair","tickets","qr-code","copy","goal","trending-down","creative-commons","ev-charger","user-star","road","nfc","align-center-horizontal","car","notebook-tabs","ear","videotape","sun-moon","chart-scatter","podium","toolbox","calendar","calendar-cog","gallery-horizontal","clipboard-x","list-sort-ascending","book-open","circle-pile","rectangle-ellipsis","badge-plus","badge-info","file-headphone","bow-arrow","clipboard-pen-line","user-round-key","folder-search","utensils-crossed","arrow-up","arrow-up-from-dot","align-vertical-justify-start","layers-minus","pause","shrub","flag","biceps-flexed","align-horizontal-distribute-end","donut","calendar-plus-2","move-vertical","file-pen-line","badge-russian-ruble","radius","pilcrow","corner-left-up","georgian-lari","cable","book-user","square-arrow-down","circle-plus","view","cctv","circle-arrow-left","square-off","octagon-alert","panel-bottom-dashed","book-a","align-end-vertical","thumbs-up","globe","rabbit","layers-plus","banknote-arrow-down","message-square-off","dice-4","message-circle-x","folder-x","message-circle-warning","map","move","arrow-up-left","award","arrow-down-wide-narrow","unfold-horizontal","lens-concave","motorbike","music-4","shield-x","file-volume","disc-3","file-signal","columns-4","archive-x","square-dashed-kanban","mouse-pointer-2","clock-arrow-up","clock-fading","pencil-sparkles","vegan","star-plus","message-circle-plus","fast-forward","user-pen","chess-knight","wifi-pen","files","send-to-back","alarm-clock","shopping-basket","send","brush-cleaning","skip-back","book-audio","file-scan","message-square-dashed","chevrons-left","umbrella","skip-forward","clipboard-copy","map-pin-off","arrow-up-from-line","circle-chevron-up","circle-small","align-vertical-space-between","lamp-desk","circle-arrow-up","zap","beaker","paintbrush","broccoli","chevron-up","pen-tool","database-check","form","pencil-ruler","dna","arrow-big-down-dash","chart-area","bug-off","card-sim","map-pin-search","eye-dashed","ellipse","spell-check","popcorn","blocks","washing-machine","microchip","badge-minus","cloud-sun","circle","shield-alert","map-minus","separator-vertical","scan-square","ampersands","user-search","fence","square-user-round","sunrise","strikethrough","calendar-days","folder-bookmark","banknote-arrow-up","dollar-sign","message-square-quote","list-minus","cloud-hail","eye-closed","app-window-mac","ellipsis","copy-check","satellite","bookmark-plus","folder-key","coffee","circle-power","hourglass","tickets-plane","folder-git","bomb","layers-2","battery-full","user-minus","chart-gantt","folder-tree","command","badge-dollar-sign","align-start-vertical","briefcase-conveyor-belt","message-circle-question-mark","bluetooth-off","square-square","cannabis","book","grip-horizontal","circle-minus","audio-waveform","moon-star","arrow-down-narrow-wide","database-backup","wand","receipt-turkish-lira","calendar-minus-2","copy-minus","folder-input","book-image","mouse-left","tag-plus","shirt","server-off","move-up","plug-2","chess-rook","brackets","calendar-heart","list-ordered","star-x","mic-off","arrow-big-left","square-split-horizontal","clover","sun-snow","sofa","funnel-x","clock-2","calendar-fold","fish-off","baby","database-x","fold-vertical","hop","paperclip","cigarette","minus","smile-plus","diamond-plus","file-chart-column","triangle-dashed","git-pull-request-closed","badge-check","zoom-out","zoom-in","zodiac-virgo","plug-zap","heading-4","chess-queen","graduation-cap","grid-3x2","zodiac-sagittarius","list-music","square-dashed-bottom-code","clock-7","ethernet-port","scan-text","file-up","shower-head","equal-not","zodiac-pisces","move-down","clock-arrow-down","ticket-slash","ruler","tornado","zodiac-libra","circle-user-round","zodiac-leo","zodiac-gemini","list-filter","map-pin-check","egg-off","square-kanban","cog","dog","folder-closed","swords","spotlight","panel-right-dashed","zodiac-aries","paper-bag","truck-electric","zodiac-aquarius","check-line","save","bubbles","bot","chart-bar-increasing","x-line-top","trash-2","air-vent","swiss-franc","dot","sprout","worm","file-symlink","clipboard-paste","chevron-last","book-heart","workflow","circle-parking","globe-check","cloud-check","panel-left","circle-chevron-right","wine-off","wine","squares-unite","arrow-down-up","git-fork","forward","brain-circuit","between-vertical-start","database","panel-right","wind-arrow-down","message-square-diff","popsicle","log-out","git-branch-plus","clipboard-minus","file-text","wifi-sync","bell-off","wifi-high","table-rows-split","milk-off","tv-minimal","cloud-upload","banknote","wifi","webcam-off","drumstick","wheat-off","calendar-search","wheat","weight-tilde","bell-ring","circle-chevron-left","weight","arrow-down","arrow-up-down","folder-dot","fingerprint-pattern","folder-up","whole-word","monitor","disc-2","trending-up-down","webcam","user-shield","waypoints","tv-minimal-play","circle-stop","align-vertical-space-around","waves-vertical","waves-ladder","waves-horizontal","arrow-big-down","circle-parking-off","calendar-x-2","user-plus","move-diagonal-2","bandage","gallery-horizontal-end","panel-top-dashed","octagon-minus","waves-arrow-down","tram-front","watch","indian-rupee","wand-sparkles","audio-lines","wallpaper","wallet-minimal","wallet-cards","flip-vertical-2","rocket","wallet","ear-off","vote","save-check","volume-off","shield-half","printer","megaphone-off","volume-1","arrow-big-right","section","file-clock","volume","toy-brick","square-chevron-down","dice-1","drill","app-window","shield-check","hand-metal","volleyball","spell-check-2","umbrella-off","video","list-plus","sun-dim","rotate-ccw-key","vibrate","chart-pie","venus-and-mars","cloud-backup","copy-slash","wind","vault","layout-panel-left","badge-x","circle-percent","van","circle-arrow-out-down-right","square-x","italic","chart-column-increasing","utility-pole","step-forward","utensils","a-arrow-down","container","sticker","users-round","users","user-x","user-round-x","user-round-search","log-in","import","badge-turkish-lira","square-terminal","file-music","mic-vocal","beef","route-off","file-user","user-round-cog","square-radical","user-round-check","image-upscale","book-type","smile","signpost-big","user-round-arrow-left","cloudy","user-lock","square-percent","user-key","navigation-off","arrow-left","car-taxi-front","square-play","sparkle","chevrons-right-left","user","map-pin-plus","upload","unplug","square-code","unlink","university","square-pause","align-end-horizontal","ungroup","equal","megaphone","calendar-x","unfold-vertical","lamp-ceiling","egg","undo-2","undo","underline","circle-pound-sterling","video-off","japanese-yen","type-outline","fuel","file-search-corner","library","file-terminal","circle-chevron-down","accessibility","folder-lock","square-library","amphora","turntable","tally-2","turkish-lira","truck","trophy","gamepad-directional","sheet","circle-check-big","triangle-alert","triangle","map-pinned","corner-down-left","circuit-board","trending-up","train-front-tunnel","tree-deciduous","school","folder-open-dot","book-dashed","transgender","chevron-left","bluetooth","tree-pine","receipt-indian-rupee","monitor-stop","traffic-cone","tractor","tower-control","replace-all","touchpad-off","flask-conical","touchpad","funnel","square-star","folder-sync","torus","zodiac-ophiuchus","tool-case","toilet","arrow-up-narrow-wide","fishing-hook","text-quote","toggle-left","timer-reset","frame","calendar-arrow-down","clock-12","star-minus","radar","timer","images","lollipop","book-text","timeline","lamp-floor","file-plus-corner","image","ticket-x","badge-euro","bike","squares-exclude","list-checks","send-horizontal","dices","panel-left-dashed","thermometer-sun","thermometer-snowflake","option","banknote-check","scroll-text","server-plus","thermometer","theater","message-circle-off","toggle-right","pc-case","ferris-wheel","camera-off","text-cursor-input","text-cursor","info","text-align-justify","text-align-end","group","text-align-center","battery","test-tubes","tent-tree","test-tube-diagonal","rectangle-horizontal","bug","tent","telescope","bitcoin","lamp","battery-plus","database-search","tangent","file-diff","phone-off","link","tally-3","spline-pointer","circle-alert","axis-3d","shell","tag","binoculars","tablets","tablet-smartphone","screen-share","rose","table-properties","mail-minus","table-of-contents","table-columns-split","table-cells-merge","table-2","clipboard-pen","bottle-wine","alarm-clock-off","table","list","syringe","square-arrow-right","rotate-ccw-clock","badge-pound-sterling","bookmark-check","switch-camera","wrench-off","square-arrow-out-down-left","a-arrow-up","clock-check","sunset","sun-medium","vibrate-off","mail-check","zodiac-cancer","file-chart-column-increasing","file-code","subscript","chart-column-big","stretch-vertical","stretch-horizontal","cassette-tape","battery-low","monitor-pause","stone","signpost","image-plus","calendar-arrow-up","landmark","fish-symbol","sticky-note-x","loader","bold","dice-2","file-type","clipboard-clock","beer","lectern","chart-bar-stacked","file-check","git-pull-request-create","binary","move-diagonal","sticky-note-check","door-closed","sticky-note","layout-template","stethoscope","step-back","star-off","bookmark-off","hand-heart","scroll","scan-qr-code","message-square-check","star","stamp","squirrel","brain","folder","squircle","snail","key","clock-11","earth-lock","ticket-plus","arrow-up-0-1","bell-electric","square-user","heading","book-open-check","panel-top-close","lasso-select","move-left","square-stack","square-split-vertical","square-slash","bus","square-sigma","bed-single","chart-no-axes-gantt","file-spreadsheet","square-scissors","clipboard-list","square-round-corner","contact-round","leaf","keyboard-off","square-plus","file-badge","battery-warning","mail-question-mark","arrow-down-from-line","briefcase","biohazard","rectangle-circle","braces","scale-3d","panel-top-bottom-dashed","mail-x","square-dashed-mouse-pointer","user-cog","lock-open","square-pilcrow","pizza","list-indent-decrease","arrow-up-wide-narrow","square-pi","clock-5","mouse-pointer","rotate-ccw","align-horizontal-justify-center","database-arrow-down","antenna","memory-stick","scan-eye","square-parking","square-check","heart-plus","receipt-russian-ruble","map-pin-minus-inside","git-merge","gallery-vertical-end","square-m","hand-coins","zodiac-capricorn","wifi-low","square-equal","clock","file-pen","git-compare-arrows","cloud-sun-rain","align-horizontal-justify-start","square-dot","square-divide","square-arrow-right-enter","calendar-plus","square-bottom-dashed-scissors","arrow-down-z-a","bath","square-dashed-bottom","unlink-2","square-chevron-up","pin","folder-check","square-chevron-left","book-key","ribbon","microwave","saudi-riyal","gallery-vertical","square-chart-gantt","square-centerline-dashed-vertical","square-dashed-text","map-pin-pen","move-up-left","square-asterisk","folder-heart","square-arrow-up-right","shield-cog-corner","circle-play","arrow-up-a-z","square-arrow-right-exit","square-dashed-top-solid","square-arrow-out-up-right","square-arrow-out-up-left","circle-ellipsis","swatch-book","receipt-cent","spool","folder-archive","folder-symlink","columns-3","ban","message-square-x","paint-roller","soup","archive","square-arrow-down-right","construction","building-2","circle-slash-2","package","cake","cloud-rain","chart-bar","square","wrench","spray-can","sport-shoe","smartphone","flag-triangle-right","receipt-euro","speech","bell","speaker","sparkles","music-3","chart-bar-big","user-check","proportions","spade","plane","webhook-off","carrot","square-arrow-left","file-cog","circle-dashed","solar-panel","soap-dispenser-droplet","snowflake","mailbox","squares-subtract","smartphone-nfc","chevrons-left-right-ellipsis","split","list-sort-descending","sliders-vertical","forklift","sliders-horizontal","alarm-clock-minus","heart-x","eraser","book-marked","package-search","bluetooth-connected","rotate-ccw-square","chart-no-axes-column","cannabis-off","folder-kanban","message-square-plus","mars-stroke","skull","siren","signature","file-box","signal-medium","paint-bucket","glass-water","signal-low","glasses","piggy-bank","maximize-2","cuboid","cloud-off","check-check","activity","axe","plane-takeoff","sigma","cloud-rain-wind","flower","expand","copy-x","file-axis-3d","radical","chart-column-decreasing","shrimp","bug-play","align-vertical-distribute-start","highlighter","waves-arrow-up","tally-5","shopping-bag","ship-wheel","shield-user","circle-divide","shield-question-mark","shield-plus","shield-off","life-buoy","hard-hat","shield-keyhole","volume-2","battery-charging","russian-ruble","square-arrow-up-left","brick-wall-shield","footprints","shield-cog","building","shield-ban","shield","shelving-unit","tag-x","book-alert","link-2","astroid","bell-minus","image-up","closed-caption","drum","arrow-up-z-a","sun","share","shapes","file-key","settings-2","settings","scissors-line-dashed","server-crash","server-cog","server","ticket-check","combine","search-x","search-slash","mountain","mars","picture-in-picture-2","radio-off","flower-2","search-code","squares-intersect","search-alert","search","keyboard-music","star-half","screen-share-off","code-xml","pencil-line","mails","brain-cog","tablet","loader-circle","pi","trash","book-down","hdmi-port","scan-search","case-upper","circle-fading-arrow-up","redo","croissant","move-down-right","scan-face","barcode","scan-box","scan-barcode","bed","scan","divide","grape","remove-formatting","party-popper","file-chart-pie","save-plus","file-braces","dice-6","save-off","blender","image-minus","zap-off","square-check-big","satellite-dish","sandwich","salad","laptop-minimal","sailboat","monitor-check","map-pin-minus","file-minus-corner","chart-spline","message-square-more","rows-4","chart-candlestick","rows-3","arrow-down-a-z","rows-2","router","move-horizontal","file-sliders","frown","route","cup-soda","rewind","rotate-cw-fading-clock","sword","rotate-3d","roller-coaster","earth","slice","dice-3","milk","mouse-pointer-ban","crown","circle-slash","circle-star","rotate-cw-square","atom","package-x","bed-double","list-chevrons-up-down","circle-dot","file-exclamation-point","hand-fist","message-circle-code","folder-git-2","message-square-code","reply","towel-rack","replace","arrow-big-left-dash","repeat-off","dumbbell","repeat-2","repeat-1","repeat","scale","regex","flashlight","panel-top-open","refrigerator","refresh-cw-off","notebook","redo-2","refresh-cw","square-menu","brick-wall","monitor-smartphone","laptop","scan-line","clock-4","square-arrow-up","book-minus","file-question-mark","rectangle-vertical","rectangle-goggles","save-pen","arrow-down-to-line","receipt-swiss-franc","refresh-ccw","venetian-mask","calendar-check-2","receipt-japanese-yen","spline","banknote-x","git-pull-request-create-arrow","pound-sterling","circle-check","ratio","rainbow","phone","radio-receiver","radio","radiation","timer-off","arrow-big-right-dash","quote","pyramid","puzzle","backpack","projector","list-check","printer-check","power-off","mic-signal","arrow-down-right","power","receipt","wifi-zero","folder-minus","list-collapse","plus","plug","image-off","play-off","play","plane-landing","pin-off","square-chevron-right","mail-search","pill","bone-fracture","microscope","pilcrow-left","pickaxe","piano","tally-1","ampersand","ad","shopping-cart","align-vertical-justify-end","phone-incoming","alarm-smoke","phone-forwarded","file-input","clock-8","hand-grab","cloud-cog","blend","hd","radio-tower","list-tree","droplet","grid-2x2","eye","phi","percent","banana","gpu","pentagon","pencil-off","circle-equal","delete","pen-off","pen-line","headset","text-initial","arrow-up-right","move-right","leafy-green","message-square-dot","file-chart-line","columns-3-cog","parasol","calendar-minus","minimize-2","panels-left-bottom","panel-top","cone","panel-right-open","file-image","panel-right-close","palette","barrel","gallery-thumbnails","panel-left-right-dashed","cpu","panel-left-open","thumbs-down","merge","hamburger","bird","hat-glasses","code","helicopter","panel-bottom-close","panel-bottom","panda","file-video-camera","paintbrush-vertical","kanban","bone","apple","rocking-chair","bot-off","package-plus","package-open","diameter","circle-arrow-out-up-left","package-2","cable-car","arrow-down-left","square-activity","orbit","cigarette-off","omega","message-circle","circle-arrow-out-up-right","locate-fixed","octagon-pause","fold-horizontal","shovel","calendar-1","cloud-moon","square-arrow-out-down-right","nut-off","clock-plus","circle-euro","cloud-snow","anvil","arrow-big-up-dash","nut","notepad-text-dashed","notepad-text","list-video","monitor-off","newspaper","chevrons-down-up","clipboard-plus","circle-x","list-end","network","navigation-2","chevrons-right","navigation","message-square-reply","corner-down-right","music-2","summary","lamp-wall-down","move-up-right","paw-print","ellipsis-vertical","globe-off","square-stop","arrow-up-1-0","align-horizontal-justify-end","scan-heart","align-vertical-distribute-end","heart-crack","airplay","move-down-left","move-3d","message-square-share","monitor-x","bell-check","database-minus","square-pen","mouse-off","lasso","dice-5","octagon","ticket","moon","monitor-up","train-front","bookmark","monitor-speaker","album","monitor-play","chart-bar-decreasing","database-plus","calendar-sync","funnel-plus","store","circle-arrow-down","notebook-pen","egg-fried","message-circle-heart","monitor-dot","corner-right-up","monitor-cog","ruler-dimension-line","user-round-plus","panel-left-close","milestone","pilcrow-right","user-round-minus","mic-audio-lines","mic","mail-plus","case-sensitive","message-square-warning","message-square-text","mouse-pointer-2-off","drone","slash","message-square-lock","aperture","arrow-right-left","message-square-heart","vector-square","circle-gauge","gem","check","text-search","arrow-down-to-dot","monitor-down","message-circle-dashed","chef-hat","message-circle-check","meh","file-archive","signal-high","inbox","flip-horizontal-2","maximize","image-play","align-horizontal-space-between","kayak","calendar-check","database-zap","droplets","calendar-range","map-pin-x-inside","map-pin-x","layout-list","file-search","heart","alarm-clock-plus","circle-dollar-sign","usb","house","receipt-pound-sterling","file-digit","map-pin","id-card","mouse","minimize","mail","magnet","circle-arrow-right","logs","book-x","mirror-rectangular","lock-keyhole-open","lock-keyhole","lock","headphone-off","asterisk","calculator","octagon-x","languages","locate","alarm-clock-check","guitar","loader-pinwheel","beer-off","scooter","square-parking-off","notebook-text","arrow-right-to-line","ticket-minus","tally-4","zodiac-taurus","list-indent-increase","door-open","flag-triangle-left","grid-3x3","file","keyboard","pocket-knife","book-copy","castle","car-front","clock-alert","reply-all","cloud-moon-rain","clipboard-type","list-chevrons-down-up","list-todo","printer-x","link-2-off","list-start","line-style","a-large-small","line-squiggle","line-dot-right-horizontal","map-plus","lightbulb","ligature","library-big","database-arrow-up","arrow-right-from-line","flame-kindling","square-power","layout-panel-top","bring-to-front","layout-grid","layout-freeform","bell-plus","layout-dashboard","layers","laugh","folders","mail-warning","book-plus","land-plot","lamp-wall-up","chevrons-left-right","chart-line","file-lock","cast","circle-fading-plus","clock-10","undo-dot","target","list-filter-plus","key-square","drama","file-type-corner","baseline","martini","contrast","joystick","candy-off","iteration-cw","book-check","iteration-ccw","book-lock","inspection-panel","briefcase-medical","calendars","text-align-start","infinity","hop-off","warehouse","sticky-notes","drafting-compass","save-all","id-card-lanyard","ice-cream-cone","ice-cream-bowl","house-wifi","house-plug","fishing-rod","book-headphones","credit-card","house-heart","hotel","hospital","shredder","panel-bottom-open","heart-pulse","heart-off","heart-minus","balloon","map-pin-plus-inside","bookmark-x","badge-question-mark","pen","file-stack","candy-cane","heading-6","heading-5","gamepad-2","heading-3","heading-2","heading-1","haze","shield-minus","circle-off","dessert","eclipse","church","hard-drive-upload","cylinder","badge-japanese-yen","hard-drive-download","receipt-text","handbag","hand-platter","hand","hammer","file-output","disc-album","grip","arrow-down-0-1","captions","flashlight-off","grid-2x2-check","philippine-peso","badge-alert","globe-x","folder-pen","cross","git-pull-request-draft","chevron-right","sticky-note-minus","square-arrow-down-left","share-2","git-merge-conflict","git-compare","git-commit-vertical","git-commit-horizontal","clipboard","git-branch","chess-pawn","gift","briefcase-business","ghost","message-circle-reply","gauge","triangle-right","folder-clock","gamepad","fullscreen","type","webhook","folder-search-2","align-horizontal-distribute-start","folder-root","folder-open","pointer-off","turtle","camera","compass","folder-cog","git-pull-request","bluetooth-searching","arrow-up-to-line","squircle-dashed","clock-3","badge-percent","shuffle","flask-round","flask-conical-off","grid-2x2-plus","flag-off","box","fish","clock-1","file-heart","fire-extinguisher","space","film","file-x-corner","file-x","corner-up-left","clock-6","zodiac-scorpio","key-round","headphones","tv","contact","file-play","rss","file-minus","at-sign","map-pin-check-inside","sticky-note-off","music","handshake","fan","circle-user","copy-plus","factory","external-link","shrink","euro","equal-approximately","search-check","clipboard-check","columns-2","droplet-off","cloud-sync","align-center-vertical","dock","disc","diff","cloud-fog","mosque","diamond-minus","map-pin-house","package-check","chevron-first","pencil","component","list-x","currency","crosshair","corner-up-right","crop","clock-arrow-left","corner-right-down","copyright","badge-indian-rupee","copyleft","redo-dot","cookie","align-start-horizontal","chart-column-stacked","file-plus","git-pull-request-arrow","computer","decimals-arrow-right","bell-dot","folder-down","coins","club","align-horizontal-space-around","door-closed-locked","cloud-drizzle","diamond","blinds","clock-arrow-right","clock-9","book-search","git-branch-minus","clapperboard","recycle","mountain-snow","luggage","circle-arrow-out-down-left","bot-message-square","phone-outgoing","smartphone-charging","chevrons-down","train-track","chess-bishop","cherry","sticky-note-plus","chart-no-axes-column-increasing","chart-no-axes-column-decreasing","chart-network","chart-no-axes-combined","metronome","case-lower","arrow-down-1-0","caravan","candy","arrow-left-right","lightbulb-off","panels-top-left","beef-off","locate-off","annoyed","test-tube","brick-wall-fire","cooking-pot","boxes","boom-box","book-up","laptop-minimal-check","mail-open","square-function","baggage-claim","variable","arrow-right","archive-restore"},{if getcustomasset and not IS_GETCUSTOMASSET_BROKEN then getcustomasset("lucide-icons/1.png") else "rbxassetid://83730601400444",if getcustomasset and not IS_GETCUSTOMASSET_BROKEN then getcustomasset("lucide-icons/2.png") else "rbxassetid://113171075404217"},{[48]={{1,{24,24},{150,25}},{1,{24,24},{275,350}},{1,{24,24},{400,650}},{1,{24,24},{975,725}},{1,{24,24},{175,750}},{1,{24,24},{300,500}},{1,{24,24},{450,850}},{2,{24,24},{200,100}},{1,{24,24},{75,325}},{1,{24,24},{275,400}},{1,{24,24},{400,500}},{1,{24,24},{75,375}},{1,{24,24},{50,925}},{1,{24,24},{825,25}},{1,{24,24},{25,100}},{1,{24,24},{150,800}},{1,{24,24},{650,600}},{1,{24,24},{375,850}},{1,{24,24},{325,50}},{1,{24,24},{125,300}},{1,{24,24},{650,200}},{1,{24,24},{400,925}},{1,{24,24},{775,225}},{1,{24,24},{0,525}},{1,{24,24},{975,450}},{1,{24,24},{75,350}},{1,{24,24},{525,425}},{1,{24,24},{950,775}},{1,{24,24},{425,325}},{1,{24,24},{325,175}},{1,{24,24},{300,550}},{1,{24,24},{775,475}},{1,{24,24},{750,375}},{1,{24,24},{700,675}},{1,{24,24},{500,350}},{1,{24,24},{300,925}},{1,{24,24},{75,125}},{1,{24,24},{875,100}},{1,{24,24},{825,950}},{1,{24,24},{350,100}},{2,{24,24},{275,100}},{1,{24,24},{575,150}},{1,{24,24},{775,350}},{1,{24,24},{475,250}},{1,{24,24},{0,900}},{1,{24,24},{525,75}},{1,{24,24},{325,800}},{2,{24,24},{25,225}},{1,{24,24},{925,350}},{1,{24,24},{100,325}},{1,{24,24},{625,25}},{1,{24,24},{175,350}},{1,{24,24},{500,600}},{1,{24,24},{800,425}},{1,{24,24},{475,25}},{1,{24,24},{850,50}},{1,{24,24},{600,50}},{1,{24,24},{975,575}},{1,{24,24},{725,825}},{1,{24,24},{900,775}},{1,{24,24},{825,625}},{2,{24,24},{350,25}},{1,{24,24},{0,975}},{1,{24,24},{800,375}},{1,{24,24},{75,750}},{1,{24,24},{200,125}},{1,{24,24},{425,425}},{1,{24,24},{925,600}},{1,{24,24},{925,300}},{1,{24,24},{425,925}},{1,{24,24},{625,350}},{1,{24,24},{50,225}},{1,{24,24},{700,725}},{1,{24,24},{975,850}},{1,{24,24},{275,275}},{2,{24,24},{350,50}},{1,{24,24},{625,550}},{2,{24,24},{25,275}},{1,{24,24},{775,500}},{2,{24,24},{50,50}},{1,{24,24},{250,125}},{1,{24,24},{275,300}},{1,{24,24},{75,100}},{1,{24,24},{50,750}},{1,{24,24},{475,675}},{1,{24,24},{125,900}},{1,{24,24},{600,300}},{1,{24,24},{700,100}},{1,{24,24},{100,150}},{2,{24,24},{250,75}},{1,{24,24},{525,625}},{1,{24,24},{200,975}},{1,{24,24},{675,300}},{1,{24,24},{275,675}},{1,{24,24},{925,275}},{1,{24,24},{100,625}},{1,{24,24},{550,700}},{1,{24,24},{750,25}},{1,{24,24},{250,100}},{1,{24,24},{375,350}},{2,{24,24},{125,125}},{1,{24,24},{0,275}},{1,{24,24},{100,375}},{1,{24,24},{275,850}},{1,{24,24},{775,450}},{1,{24,24},{550,50}},{1,{24,24},{225,750}},{1,{24,24},{300,475}},{2,{24,24},{0,100}},{1,{24,24},{50,900}},{1,{24,24},{450,225}},{1,{24,24},{400,225}},{1,{24,24},{100,300}},{1,{24,24},{975,325}},{1,{24,24},{900,500}},{1,{24,24},{175,25}},{1,{24,24},{850,600}},{1,{24,24},{0,675}},{1,{24,24},{975,275}},{1,{24,24},{100,450}},{1,{24,24},{200,400}},{1,{24,24},{225,175}},{1,{24,24},{750,800}},{1,{24,24},{650,950}},{1,{24,24},{25,750}},{1,{24,24},{50,850}},{1,{24,24},{650,450}},{1,{24,24},{600,400}},{1,{24,24},{925,825}},{1,{24,24},{50,150}},{1,{24,24},{50,600}},{1,{24,24},{775,325}},{1,{24,24},{475,75}},{1,{24,24},{825,125}},{1,{24,24},{25,200}},{1,{24,24},{975,875}},{1,{24,24},{575,700}},{1,{24,24},{75,675}},{1,{24,24},{425,525}},{2,{24,24},{125,0}},{1,{24,24},{575,200}},{1,{24,24},{200,625}},{2,{24,24},{250,25}},{1,{24,24},{700,625}},{1,{24,24},{650,525}},{1,{24,24},{125,0}},{1,{24,24},{175,400}},{1,{24,24},{575,600}},{1,{24,24},{600,225}},{2,{24,24},{75,225}},{1,{24,24},{700,950}},{1,{24,24},{600,25}},{1,{24,24},{975,300}},{1,{24,24},{975,925}},{1,{24,24},{500,75}},{1,{24,24},{250,300}},{1,{24,24},{375,550}},{1,{24,24},{425,275}},{1,{24,24},{375,675}},{1,{24,24},{75,400}},{1,{24,24},{400,275}},{1,{24,24},{650,650}},{1,{24,24},{25,325}},{1,{24,24},{125,225}},{1,{24,24},{250,600}},{1,{24,24},{75,425}},{1,{24,24},{525,175}},{2,{24,24},{175,75}},{1,{24,24},{875,50}},{2,{24,24},{125,150}},{1,{24,24},{225,100}},{1,{24,24},{75,225}},{1,{24,24},{25,150}},{1,{24,24},{475,550}},{1,{24,24},{725,500}},{1,{24,24},{450,975}},{1,{24,24},{900,0}},{1,{24,24},{25,400}},{1,{24,24},{0,125}},{1,{24,24},{175,625}},{1,{24,24},{75,475}},{1,{24,24},{950,225}},{1,{24,24},{0,850}},{1,{24,24},{350,25}},{1,{24,24},{325,950}},{1,{24,24},{675,575}},{1,{24,24},{725,50}},{1,{24,24},{125,800}},{1,{24,24},{500,50}},{1,{24,24},{425,75}},{1,{24,24},{800,700}},{1,{24,24},{350,325}},{2,{24,24},{50,250}},{1,{24,24},{500,100}},{1,{24,24},{450,200}},{1,{24,24},{700,850}},{1,{24,24},{400,775}},{1,{24,24},{600,600}},{1,{24,24},{475,0}},{1,{24,24},{50,75}},{1,{24,24},{875,925}},{1,{24,24},{450,500}},{1,{24,24},{525,750}},{1,{24,24},{450,575}},{1,{24,24},{100,275}},{1,{24,24},{975,150}},{1,{24,24},{550,250}},{1,{24,24},{350,750}},{1,{24,24},{750,175}},{1,{24,24},{375,725}},{1,{24,24},{925,175}},{1,{24,24},{925,250}},{1,{24,24},{25,275}},{1,{24,24},{25,300}},{1,{24,24},{125,150}},{2,{24,24},{125,75}},{1,{24,24},{150,875}},{1,{24,24},{725,425}},{1,{24,24},{850,325}},{1,{24,24},{775,650}},{1,{24,24},{375,500}},{1,{24,24},{400,400}},{1,{24,24},{675,200}},{1,{24,24},{575,175}},{1,{24,24},{75,150}},{1,{24,24},{625,900}},{1,{24,24},{575,575}},{1,{24,24},{725,0}},{1,{24,24},{675,50}},{1,{24,24},{475,750}},{2,{24,24},{275,25}},{1,{24,24},{925,700}},{1,{24,24},{450,650}},{1,{24,24},{850,0}},{2,{24,24},{25,200}},{1,{24,24},{375,250}},{2,{24,24},{250,125}},{1,{24,24},{275,600}},{1,{24,24},{950,450}},{1,{24,24},{50,50}},{1,{24,24},{625,800}},{1,{24,24},{925,475}},{1,{24,24},{200,325}},{1,{24,24},{700,750}},{1,{24,24},{425,50}},{1,{24,24},{750,125}},{1,{24,24},{250,850}},{1,{24,24},{25,600}},{2,{24,24},{25,150}},{1,{24,24},{675,775}},{1,{24,24},{625,75}},{1,{24,24},{275,800}},{1,{24,24},{50,250}},{1,{24,24},{150,500}},{1,{24,24},{200,475}},{1,{24,24},{200,0}},{1,{24,24},{850,175}},{1,{24,24},{300,350}},{2,{24,24},{300,100}},{1,{24,24},{125,275}},{1,{24,24},{700,500}},{1,{24,24},{225,300}},{1,{24,24},{150,475}},{1,{24,24},{600,625}},{1,{24,24},{200,575}},{1,{24,24},{625,300}},{1,{24,24},{500,725}},{1,{24,24},{275,525}},{1,{24,24},{0,225}},{1,{24,24},{475,125}},{1,{24,24},{125,400}},{1,{24,24},{125,450}},{1,{24,24},{175,900}},{1,{24,24},{100,725}},{1,{24,24},{425,400}},{1,{24,24},{600,875}},{1,{24,24},{900,375}},{1,{24,24},{225,225}},{2,{24,24},{0,325}},{1,{24,24},{575,550}},{1,{24,24},{75,275}},{1,{24,24},{175,550}},{1,{24,24},{50,625}},{1,{24,24},{525,875}},{1,{24,24},{425,650}},{1,{24,24},{875,525}},{1,{24,24},{825,550}},{1,{24,24},{125,75}},{2,{24,24},{0,250}},{1,{24,24},{800,50}},{1,{24,24},{950,650}},{1,{24,24},{950,725}},{1,{24,24},{825,825}},{1,{24,24},{225,325}},{1,{24,24},{500,400}},{1,{24,24},{75,300}},{1,{24,24},{200,600}},{1,{24,24},{925,200}},{1,{24,24},{500,550}},{1,{24,24},{400,325}},{1,{24,24},{125,700}},{1,{24,24},{175,50}},{1,{24,24},{375,450}},{1,{24,24},{200,550}},{1,{24,24},{675,675}},{1,{24,24},{275,225}},{1,{24,24},{175,725}},{1,{24,24},{725,25}},{1,{24,24},{300,375}},{1,{24,24},{850,150}},{1,{24,24},{850,975}},{1,{24,24},{275,625}},{1,{24,24},{50,400}},{1,{24,24},{500,525}},{1,{24,24},{275,125}},{2,{24,24},{50,175}},{1,{24,24},{175,425}},{1,{24,24},{800,125}},{1,{24,24},{525,225}},{1,{24,24},{200,150}},{1,{24,24},{175,0}},{1,{24,24},{325,200}},{1,{24,24},{425,675}},{1,{24,24},{175,275}},{1,{24,24},{675,900}},{1,{24,24},{300,275}},{1,{24,24},{375,125}},{1,{24,24},{175,775}},{1,{24,24},{550,125}},{1,{24,24},{50,275}},{1,{24,24},{800,350}},{1,{24,24},{250,25}},{1,{24,24},{225,550}},{2,{24,24},{50,275}},{1,{24,24},{725,575}},{1,{24,24},{150,400}},{1,{24,24},{175,575}},{1,{24,24},{225,675}},{1,{24,24},{250,225}},{1,{24,24},{650,500}},{1,{24,24},{750,950}},{1,{24,24},{675,750}},{1,{24,24},{800,600}},{1,{24,24},{975,200}},{1,{24,24},{375,875}},{1,{24,24},{300,325}},{1,{24,24},{525,0}},{1,{24,24},{175,375}},{1,{24,24},{450,600}},{1,{24,24},{900,725}},{1,{24,24},{675,450}},{1,{24,24},{200,50}},{1,{24,24},{725,850}},{1,{24,24},{50,675}},{1,{24,24},{675,975}},{1,{24,24},{850,625}},{1,{24,24},{450,475}},{1,{24,24},{275,425}},{1,{24,24},{200,350}},{1,{24,24},{175,700}},{1,{24,24},{325,25}},{1,{24,24},{100,675}},{1,{24,24},{550,350}},{1,{24,24},{925,75}},{1,{24,24},{850,375}},{1,{24,24},{525,125}},{1,{24,24},{375,750}},{1,{24,24},{975,500}},{1,{24,24},{675,125}},{1,{24,24},{575,275}},{2,{24,24},{25,100}},{1,{24,24},{725,225}},{1,{24,24},{225,125}},{2,{24,24},{375,50}},{2,{24,24},{400,25}},{2,{24,24},{425,0}},{1,{24,24},{350,900}},{1,{24,24},{425,550}},{1,{24,24},{325,300}},{1,{24,24},{375,575}},{1,{24,24},{225,725}},{2,{24,24},{50,350}},{1,{24,24},{475,575}},{1,{24,24},{675,850}},{1,{24,24},{150,550}},{1,{24,24},{250,575}},{1,{24,24},{800,575}},{1,{24,24},{450,425}},{1,{24,24},{550,875}},{1,{24,24},{325,500}},{2,{24,24},{75,325}},{1,{24,24},{300,850}},{1,{24,24},{50,650}},{1,{24,24},{925,900}},{1,{24,24},{825,525}},{1,{24,24},{950,950}},{2,{24,24},{125,275}},{1,{24,24},{125,550}},{2,{24,24},{150,250}},{2,{24,24},{175,225}},{1,{24,24},{575,475}},{1,{24,24},{375,700}},{1,{24,24},{475,350}},{1,{24,24},{850,700}},{1,{24,24},{700,50}},{1,{24,24},{225,575}},{1,{24,24},{425,475}},{1,{24,24},{775,900}},{1,{24,24},{950,550}},{1,{24,24},{375,825}},{2,{24,24},{250,150}},{1,{24,24},{875,350}},{2,{24,24},{100,50}},{2,{24,24},{275,125}},{1,{24,24},{525,100}},{1,{24,24},{500,850}},{1,{24,24},{150,375}},{1,{24,24},{125,375}},{1,{24,24},{400,200}},{2,{24,24},{375,25}},{2,{24,24},{0,75}},{1,{24,24},{75,0}},{1,{24,24},{850,825}},{1,{24,24},{75,725}},{1,{24,24},{900,600}},{2,{24,24},{25,350}},{1,{24,24},{575,300}},{1,{24,24},{550,150}},{1,{24,24},{225,400}},{1,{24,24},{275,200}},{2,{24,24},{50,325}},{1,{24,24},{475,200}},{1,{24,24},{550,400}},{1,{24,24},{525,200}},{1,{24,24},{425,775}},{1,{24,24},{175,475}},{2,{24,24},{100,275}},{2,{24,24},{75,300}},{1,{24,24},{775,825}},{1,{24,24},{150,125}},{1,{24,24},{850,100}},{1,{24,24},{600,325}},{1,{24,24},{500,25}},{1,{24,24},{50,375}},{1,{24,24},{50,725}},{1,{24,24},{325,875}},{2,{24,24},{150,225}},{1,{24,24},{225,875}},{1,{24,24},{875,400}},{1,{24,24},{825,250}},{1,{24,24},{25,900}},{1,{24,24},{575,125}},{1,{24,24},{525,350}},{2,{24,24},{225,150}},{1,{24,24},{225,200}},{2,{24,24},{325,50}},{1,{24,24},{875,825}},{1,{24,24},{475,650}},{2,{24,24},{150,25}},{1,{24,24},{125,600}},{1,{24,24},{0,375}},{2,{24,24},{175,200}},{2,{24,24},{175,175}},{1,{24,24},{675,150}},{2,{24,24},{25,325}},{1,{24,24},{0,550}},{2,{24,24},{0,350}},{2,{24,24},{75,275}},{1,{24,24},{175,250}},{1,{24,24},{200,450}},{2,{24,24},{50,300}},{1,{24,24},{75,200}},{1,{24,24},{100,200}},{1,{24,24},{350,550}},{1,{24,24},{225,650}},{1,{24,24},{775,150}},{2,{24,24},{375,0}},{1,{24,24},{825,325}},{1,{24,24},{425,375}},{2,{24,24},{100,25}},{2,{24,24},{150,200}},{2,{24,24},{275,0}},{2,{24,24},{200,150}},{2,{24,24},{175,0}},{1,{24,24},{150,525}},{1,{24,24},{0,175}},{2,{24,24},{225,125}},{2,{24,24},{250,100}},{2,{24,24},{275,75}},{1,{24,24},{250,0}},{1,{24,24},{500,175}},{1,{24,24},{550,25}},{2,{24,24},{0,225}},{1,{24,24},{400,750}},{1,{24,24},{125,250}},{1,{24,24},{400,525}},{1,{24,24},{250,950}},{1,{24,24},{375,800}},{2,{24,24},{325,25}},{2,{24,24},{50,25}},{2,{24,24},{350,0}},{1,{24,24},{325,675}},{2,{24,24},{75,250}},{1,{24,24},{75,250}},{2,{24,24},{100,225}},{2,{24,24},{150,175}},{2,{24,24},{175,150}},{1,{24,24},{675,225}},{1,{24,24},{675,650}},{2,{24,24},{125,200}},{1,{24,24},{625,200}},{2,{24,24},{200,125}},{1,{24,24},{600,750}},{2,{24,24},{275,50}},{1,{24,24},{950,475}},{1,{24,24},{700,575}},{1,{24,24},{750,350}},{2,{24,24},{325,0}},{1,{24,24},{150,100}},{1,{24,24},{400,975}},{1,{24,24},{450,400}},{2,{24,24},{225,100}},{2,{24,24},{25,0}},{1,{24,24},{800,725}},{1,{24,24},{625,175}},{1,{24,24},{825,0}},{1,{24,24},{150,75}},{1,{24,24},{475,925}},{1,{24,24},{850,125}},{2,{24,24},{0,300}},{1,{24,24},{625,850}},{2,{24,24},{50,125}},{2,{24,24},{100,200}},{1,{24,24},{425,625}},{1,{24,24},{750,900}},{1,{24,24},{525,800}},{2,{24,24},{150,150}},{1,{24,24},{625,0}},{2,{24,24},{225,75}},{1,{24,24},{550,175}},{1,{24,24},{125,625}},{2,{24,24},{125,250}},{2,{24,24},{0,275}},{1,{24,24},{300,725}},{1,{24,24},{275,100}},{1,{24,24},{425,250}},{2,{24,24},{50,225}},{1,{24,24},{400,250}},{1,{24,24},{900,700}},{1,{24,24},{225,775}},{1,{24,24},{250,350}},{2,{24,24},{75,200}},{1,{24,24},{825,800}},{2,{24,24},{100,175}},{1,{24,24},{0,0}},{1,{24,24},{300,450}},{1,{24,24},{775,850}},{2,{24,24},{175,100}},{2,{24,24},{150,125}},{2,{24,24},{225,50}},{2,{24,24},{50,200}},{2,{24,24},{75,175}},{1,{24,24},{850,225}},{1,{24,24},{375,625}},{1,{24,24},{300,75}},{1,{24,24},{975,625}},{1,{24,24},{50,800}},{1,{24,24},{625,500}},{1,{24,24},{400,25}},{1,{24,24},{375,950}},{1,{24,24},{425,450}},{2,{24,24},{200,50}},{1,{24,24},{850,725}},{2,{24,24},{225,25}},{1,{24,24},{450,550}},{1,{24,24},{500,0}},{1,{24,24},{950,525}},{1,{24,24},{775,675}},{2,{24,24},{250,0}},{1,{24,24},{75,650}},{2,{24,24},{75,150}},{1,{24,24},{575,975}},{2,{24,24},{100,125}},{1,{24,24},{750,425}},{1,{24,24},{300,0}},{1,{24,24},{200,375}},{1,{24,24},{925,650}},{1,{24,24},{725,750}},{1,{24,24},{0,625}},{2,{24,24},{200,75}},{1,{24,24},{200,875}},{2,{24,24},{200,25}},{2,{24,24},{225,0}},{1,{24,24},{700,825}},{2,{24,24},{0,200}},{2,{24,24},{50,150}},{1,{24,24},{625,925}},{1,{24,24},{75,50}},{2,{24,24},{75,125}},{1,{24,24},{300,525}},{1,{24,24},{725,375}},{1,{24,24},{525,50}},{2,{24,24},{100,100}},{1,{24,24},{875,150}},{1,{24,24},{450,375}},{2,{24,24},{200,0}},{2,{24,24},{150,50}},{2,{24,24},{0,175}},{1,{24,24},{325,350}},{2,{24,24},{125,175}},{1,{24,24},{150,850}},{2,{24,24},{100,75}},{1,{24,24},{525,400}},{1,{24,24},{725,150}},{1,{24,24},{75,950}},{1,{24,24},{550,325}},{1,{24,24},{225,425}},{1,{24,24},{50,0}},{1,{24,24},{150,750}},{1,{24,24},{825,725}},{1,{24,24},{100,100}},{2,{24,24},{25,125}},{1,{24,24},{900,825}},{2,{24,24},{50,100}},{2,{24,24},{75,75}},{2,{24,24},{125,25}},{1,{24,24},{250,675}},{1,{24,24},{600,800}},{1,{24,24},{275,375}},{2,{24,24},{50,75}},{2,{24,24},{150,0}},{1,{24,24},{975,125}},{1,{24,24},{0,750}},{1,{24,24},{25,650}},{2,{24,24},{75,50}},{2,{24,24},{25,25}},{2,{24,24},{75,25}},{1,{24,24},{750,625}},{1,{24,24},{100,800}},{1,{24,24},{350,125}},{2,{24,24},{25,50}},{1,{24,24},{200,425}},{1,{24,24},{125,325}},{2,{24,24},{25,75}},{1,{24,24},{875,425}},{1,{24,24},{900,250}},{2,{24,24},{50,0}},{2,{24,24},{0,25}},{2,{24,24},{0,0}},{1,{24,24},{850,475}},{1,{24,24},{975,950}},{1,{24,24},{750,150}},{1,{24,24},{950,975}},{1,{24,24},{425,500}},{1,{24,24},{625,950}},{1,{24,24},{825,100}},{1,{24,24},{925,975}},{2,{24,24},{100,300}},{1,{24,24},{900,975}},{1,{24,24},{925,950}},{1,{24,24},{0,300}},{1,{24,24},{100,775}},{1,{24,24},{875,900}},{1,{24,24},{975,900}},{1,{24,24},{900,950}},{1,{24,24},{575,350}},{1,{24,24},{375,175}},{1,{24,24},{300,400}},{1,{24,24},{975,650}},{1,{24,24},{500,775}},{1,{24,24},{875,975}},{1,{24,24},{400,600}},{1,{24,24},{775,300}},{1,{24,24},{0,475}},{1,{24,24},{950,900}},{1,{24,24},{825,200}},{1,{24,24},{825,50}},{1,{24,24},{425,575}},{1,{24,24},{900,925}},{1,{24,24},{175,175}},{1,{24,24},{0,425}},{1,{24,24},{850,750}},{1,{24,24},{725,325}},{1,{24,24},{975,425}},{1,{24,24},{475,325}},{1,{24,24},{500,700}},{1,{24,24},{950,850}},{1,{24,24},{975,825}},{1,{24,24},{250,925}},{1,{24,24},{50,325}},{1,{24,24},{600,775}},{1,{24,24},{775,625}},{1,{24,24},{925,875}},{1,{24,24},{800,975}},{1,{24,24},{475,625}},{1,{24,24},{950,925}},{1,{24,24},{675,550}},{1,{24,24},{775,75}},{1,{24,24},{450,125}},{1,{24,24},{950,825}},{1,{24,24},{925,850}},{1,{24,24},{275,725}},{1,{24,24},{775,975}},{1,{24,24},{800,950}},{1,{24,24},{100,850}},{1,{24,24},{825,925}},{1,{24,24},{150,250}},{1,{24,24},{850,900}},{1,{24,24},{975,775}},{1,{24,24},{900,850}},{1,{24,24},{600,700}},{1,{24,24},{75,450}},{1,{24,24},{950,800}},{1,{24,24},{750,975}},{1,{24,24},{325,125}},{1,{24,24},{750,275}},{1,{24,24},{200,200}},{1,{24,24},{125,650}},{1,{24,24},{800,925}},{1,{24,24},{350,500}},{1,{24,24},{950,300}},{1,{24,24},{775,275}},{1,{24,24},{875,850}},{1,{24,24},{575,900}},{1,{24,24},{500,150}},{1,{24,24},{350,0}},{1,{24,24},{575,825}},{1,{24,24},{975,750}},{1,{24,24},{425,25}},{1,{24,24},{775,925}},{1,{24,24},{825,875}},{1,{24,24},{625,750}},{1,{24,24},{600,725}},{1,{24,24},{900,800}},{1,{24,24},{675,400}},{1,{24,24},{925,775}},{1,{24,24},{950,750}},{1,{24,24},{700,975}},{1,{24,24},{725,950}},{1,{24,24},{500,200}},{1,{24,24},{100,400}},{1,{24,24},{100,0}},{1,{24,24},{850,850}},{1,{24,24},{200,850}},{1,{24,24},{750,925}},{1,{24,24},{600,900}},{1,{24,24},{550,775}},{1,{24,24},{0,350}},{1,{24,24},{350,150}},{1,{24,24},{825,850}},{2,{24,24},{0,375}},{1,{24,24},{750,750}},{1,{24,24},{25,0}},{1,{24,24},{700,25}},{1,{24,24},{925,750}},{1,{24,24},{725,925}},{2,{24,24},{175,125}},{1,{24,24},{700,375}},{2,{24,24},{225,175}},{1,{24,24},{600,250}},{1,{24,24},{400,450}},{1,{24,24},{800,850}},{1,{24,24},{300,300}},{1,{24,24},{850,800}},{1,{24,24},{875,775}},{1,{24,24},{0,575}},{1,{24,24},{250,150}},{1,{24,24},{150,975}},{1,{24,24},{925,725}},{1,{24,24},{750,700}},{1,{24,24},{500,500}},{1,{24,24},{350,200}},{1,{24,24},{700,325}},{1,{24,24},{150,725}},{1,{24,24},{650,975}},{1,{24,24},{125,925}},{1,{24,24},{100,350}},{1,{24,24},{600,200}},{1,{24,24},{475,400}},{1,{24,24},{650,50}},{1,{24,24},{350,75}},{1,{24,24},{175,850}},{1,{24,24},{375,225}},{1,{24,24},{475,375}},{1,{24,24},{675,275}},{1,{24,24},{450,0}},{1,{24,24},{375,775}},{1,{24,24},{750,875}},{1,{24,24},{125,675}},{1,{24,24},{975,675}},{1,{24,24},{250,775}},{1,{24,24},{800,825}},{1,{24,24},{850,775}},{1,{24,24},{950,675}},{1,{24,24},{300,200}},{1,{24,24},{900,75}},{1,{24,24},{575,800}},{1,{24,24},{875,500}},{1,{24,24},{300,800}},{1,{24,24},{875,750}},{1,{24,24},{675,925}},{1,{24,24},{700,900}},{1,{24,24},{450,75}},{1,{24,24},{725,200}},{1,{24,24},{725,875}},{1,{24,24},{925,550}},{1,{24,24},{975,50}},{1,{24,24},{325,375}},{1,{24,24},{575,250}},{1,{24,24},{950,875}},{1,{24,24},{175,125}},{1,{24,24},{275,150}},{1,{24,24},{925,675}},{1,{24,24},{350,625}},{1,{24,24},{125,350}},{1,{24,24},{275,925}},{1,{24,24},{575,450}},{1,{24,24},{250,900}},{1,{24,24},{650,925}},{1,{24,24},{700,875}},{1,{24,24},{750,825}},{1,{24,24},{550,0}},{1,{24,24},{775,800}},{1,{24,24},{25,375}},{1,{24,24},{0,600}},{1,{24,24},{625,250}},{1,{24,24},{800,775}},{1,{24,24},{600,100}},{1,{24,24},{825,750}},{1,{24,24},{350,400}},{1,{24,24},{225,800}},{1,{24,24},{925,100}},{1,{24,24},{900,675}},{1,{24,24},{700,150}},{1,{24,24},{175,225}},{1,{24,24},{600,475}},{1,{24,24},{0,250}},{1,{24,24},{275,250}},{1,{24,24},{400,50}},{1,{24,24},{675,625}},{1,{24,24},{0,500}},{1,{24,24},{475,875}},{1,{24,24},{300,900}},{1,{24,24},{525,550}},{1,{24,24},{600,925}},{2,{24,24},{125,100}},{1,{24,24},{900,175}},{1,{24,24},{950,625}},{1,{24,24},{525,725}},{1,{24,24},{550,500}},{1,{24,24},{275,50}},{1,{24,24},{975,600}},{1,{24,24},{200,500}},{1,{24,24},{500,650}},{1,{24,24},{475,850}},{1,{24,24},{125,25}},{1,{24,24},{275,500}},{1,{24,24},{0,200}},{1,{24,24},{675,425}},{1,{24,24},{975,400}},{1,{24,24},{650,900}},{1,{24,24},{825,700}},{1,{24,24},{150,825}},{1,{24,24},{800,500}},{1,{24,24},{325,750}},{1,{24,24},{775,175}},{1,{24,24},{325,600}},{1,{24,24},{800,750}},{1,{24,24},{975,0}},{2,{24,24},{200,200}},{2,{24,24},{300,75}},{1,{24,24},{900,650}},{1,{24,24},{625,100}},{1,{24,24},{875,0}},{1,{24,24},{900,50}},{1,{24,24},{200,525}},{1,{24,24},{75,75}},{1,{24,24},{925,625}},{1,{24,24},{950,600}},{1,{24,24},{650,850}},{1,{24,24},{50,500}},{1,{24,24},{950,575}},{1,{24,24},{100,175}},{1,{24,24},{325,75}},{1,{24,24},{650,875}},{2,{24,24},{25,175}},{1,{24,24},{725,800}},{1,{24,24},{575,675}},{1,{24,24},{475,425}},{1,{24,24},{775,750}},{1,{24,24},{225,250}},{1,{24,24},{725,600}},{1,{24,24},{525,600}},{1,{24,24},{650,700}},{1,{24,24},{300,625}},{1,{24,24},{875,650}},{1,{24,24},{900,625}},{1,{24,24},{575,950}},{1,{24,24},{250,825}},{1,{24,24},{200,950}},{1,{24,24},{975,550}},{1,{24,24},{250,650}},{1,{24,24},{550,950}},{1,{24,24},{450,950}},{1,{24,24},{375,300}},{1,{24,24},{125,175}},{1,{24,24},{625,875}},{1,{24,24},{550,975}},{1,{24,24},{675,825}},{1,{24,24},{700,800}},{1,{24,24},{0,650}},{1,{24,24},{875,800}},{1,{24,24},{925,375}},{1,{24,24},{500,975}},{1,{24,24},{525,375}},{1,{24,24},{850,75}},{1,{24,24},{600,150}},{1,{24,24},{175,200}},{1,{24,24},{800,325}},{1,{24,24},{750,450}},{1,{24,24},{800,675}},{1,{24,24},{50,175}},{1,{24,24},{825,675}},{1,{24,24},{375,375}},{1,{24,24},{50,475}},{1,{24,24},{250,425}},{1,{24,24},{800,400}},{1,{24,24},{450,100}},{1,{24,24},{250,475}},{1,{24,24},{350,250}},{1,{24,24},{875,725}},{2,{24,24},{400,0}},{1,{24,24},{925,575}},{1,{24,24},{975,525}},{1,{24,24},{475,975}},{1,{24,24},{0,875}},{1,{24,24},{900,400}},{1,{24,24},{650,825}},{1,{24,24},{150,275}},{1,{24,24},{675,800}},{1,{24,24},{700,775}},{1,{24,24},{875,300}},{1,{24,24},{450,150}},{2,{24,24},{150,75}},{1,{24,24},{650,625}},{1,{24,24},{750,725}},{1,{24,24},{450,800}},{2,{24,24},{125,225}},{1,{24,24},{100,475}},{1,{24,24},{775,725}},{1,{24,24},{375,475}},{1,{24,24},{125,525}},{1,{24,24},{825,650}},{1,{24,24},{875,600}},{1,{24,24},{900,575}},{1,{24,24},{475,600}},{1,{24,24},{800,800}},{1,{24,24},{500,950}},{1,{24,24},{75,550}},{1,{24,24},{525,950}},{1,{24,24},{350,700}},{1,{24,24},{550,900}},{1,{24,24},{650,275}},{1,{24,24},{575,875}},{1,{24,24},{0,75}},{1,{24,24},{100,875}},{1,{24,24},{275,550}},{1,{24,24},{175,300}},{1,{24,24},{850,350}},{1,{24,24},{200,250}},{1,{24,24},{500,825}},{1,{24,24},{50,550}},{1,{24,24},{325,250}},{1,{24,24},{200,700}},{1,{24,24},{950,175}},{1,{24,24},{900,200}},{1,{24,24},{650,800}},{1,{24,24},{725,725}},{1,{24,24},{800,650}},{1,{24,24},{675,175}},{1,{24,24},{875,575}},{1,{24,24},{775,425}},{1,{24,24},{600,350}},{1,{24,24},{900,550}},{1,{24,24},{575,375}},{1,{24,24},{750,500}},{1,{24,24},{825,275}},{1,{24,24},{400,375}},{1,{24,24},{300,425}},{1,{24,24},{550,75}},{1,{24,24},{25,25}},{1,{24,24},{0,325}},{1,{24,24},{475,775}},{1,{24,24},{950,500}},{1,{24,24},{275,450}},{1,{24,24},{625,275}},{1,{24,24},{175,650}},{1,{24,24},{100,650}},{1,{24,24},{725,125}},{1,{24,24},{450,825}},{1,{24,24},{275,325}},{1,{24,24},{500,925}},{1,{24,24},{100,425}},{1,{24,24},{100,75}},{1,{24,24},{975,25}},{2,{24,24},{300,50}},{1,{24,24},{825,900}},{1,{24,24},{650,775}},{1,{24,24},{725,700}},{1,{24,24},{800,625}},{1,{24,24},{100,550}},{1,{24,24},{825,600}},{1,{24,24},{850,575}},{1,{24,24},{875,550}},{1,{24,24},{50,975}},{1,{24,24},{650,325}},{1,{24,24},{925,500}},{2,{24,24},{300,25}},{1,{24,24},{300,100}},{1,{24,24},{800,550}},{1,{24,24},{575,925}},{1,{24,24},{400,125}},{1,{24,24},{675,250}},{1,{24,24},{425,975}},{1,{24,24},{25,500}},{1,{24,24},{500,900}},{1,{24,24},{750,675}},{1,{24,24},{550,850}},{1,{24,24},{725,975}},{1,{24,24},{450,25}},{1,{24,24},{800,250}},{1,{24,24},{150,175}},{1,{24,24},{250,175}},{1,{24,24},{475,525}},{1,{24,24},{600,125}},{1,{24,24},{700,125}},{1,{24,24},{250,75}},{1,{24,24},{975,700}},{1,{24,24},{625,775}},{1,{24,24},{675,725}},{1,{24,24},{150,700}},{1,{24,24},{725,675}},{1,{24,24},{700,700}},{1,{24,24},{725,650}},{1,{24,24},{825,575}},{1,{24,24},{850,550}},{1,{24,24},{750,650}},{1,{24,24},{850,950}},{1,{24,24},{550,200}},{1,{24,24},{450,925}},{1,{24,24},{475,900}},{1,{24,24},{675,475}},{1,{24,24},{875,225}},{1,{24,24},{800,450}},{1,{24,24},{425,850}},{1,{24,24},{650,250}},{1,{24,24},{500,875}},{1,{24,24},{825,775}},{1,{24,24},{550,825}},{1,{24,24},{425,950}},{1,{24,24},{950,75}},{1,{24,24},{625,975}},{1,{24,24},{650,725}},{1,{24,24},{0,725}},{1,{24,24},{550,675}},{1,{24,24},{450,625}},{1,{24,24},{475,50}},{1,{24,24},{800,900}},{1,{24,24},{175,875}},{1,{24,24},{875,375}},{2,{24,24},{100,0}},{1,{24,24},{325,150}},{1,{24,24},{525,450}},{1,{24,24},{850,525}},{1,{24,24},{25,550}},{1,{24,24},{625,50}},{1,{24,24},{475,825}},{1,{24,24},{525,250}},{1,{24,24},{325,825}},{1,{24,24},{950,425}},{1,{24,24},{400,0}},{1,{24,24},{375,975}},{1,{24,24},{400,950}},{1,{24,24},{0,400}},{1,{24,24},{775,600}},{1,{24,24},{325,475}},{1,{24,24},{350,600}},{1,{24,24},{975,350}},{1,{24,24},{750,475}},{1,{24,24},{525,325}},{1,{24,24},{525,825}},{1,{24,24},{625,225}},{1,{24,24},{500,300}},{1,{24,24},{575,775}},{1,{24,24},{275,175}},{1,{24,24},{575,425}},{2,{24,24},{325,75}},{1,{24,24},{850,675}},{1,{24,24},{700,650}},{1,{24,24},{725,625}},{1,{24,24},{750,600}},{1,{24,24},{625,400}},{1,{24,24},{775,575}},{1,{24,24},{300,825}},{1,{24,24},{300,775}},{1,{24,24},{100,750}},{1,{24,24},{575,50}},{1,{24,24},{125,975}},{1,{24,24},{900,450}},{1,{24,24},{325,275}},{1,{24,24},{925,425}},{1,{24,24},{25,225}},{1,{24,24},{950,400}},{1,{24,24},{975,375}},{1,{24,24},{275,875}},{1,{24,24},{650,225}},{1,{24,24},{550,375}},{1,{24,24},{350,975}},{1,{24,24},{375,400}},{1,{24,24},{750,575}},{1,{24,24},{450,875}},{1,{24,24},{800,875}},{1,{24,24},{575,750}},{1,{24,24},{625,700}},{1,{24,24},{550,275}},{1,{24,24},{600,850}},{1,{24,24},{575,225}},{1,{24,24},{450,675}},{1,{24,24},{550,600}},{1,{24,24},{425,350}},{1,{24,24},{225,450}},{1,{24,24},{175,500}},{1,{24,24},{425,900}},{1,{24,24},{100,225}},{1,{24,24},{825,375}},{1,{24,24},{50,350}},{1,{24,24},{675,375}},{1,{24,24},{25,625}},{1,{24,24},{275,575}},{1,{24,24},{950,25}},{1,{24,24},{575,525}},{1,{24,24},{300,600}},{1,{24,24},{275,825}},{1,{24,24},{775,550}},{1,{24,24},{975,975}},{1,{24,24},{825,500}},{1,{24,24},{225,25}},{1,{24,24},{900,425}},{1,{24,24},{650,175}},{1,{24,24},{925,400}},{1,{24,24},{950,375}},{1,{24,24},{875,450}},{1,{24,24},{450,900}},{1,{24,24},{325,975}},{1,{24,24},{800,100}},{1,{24,24},{225,975}},{1,{24,24},{350,950}},{1,{24,24},{400,900}},{1,{24,24},{525,650}},{1,{24,24},{525,775}},{1,{24,24},{375,925}},{1,{24,24},{775,775}},{1,{24,24},{375,150}},{1,{24,24},{950,200}},{1,{24,24},{600,425}},{1,{24,24},{900,475}},{1,{24,24},{225,475}},{1,{24,24},{525,975}},{1,{24,24},{150,325}},{1,{24,24},{775,100}},{1,{24,24},{575,725}},{1,{24,24},{625,675}},{1,{24,24},{550,800}},{1,{24,24},{175,100}},{1,{24,24},{775,525}},{1,{24,24},{425,875}},{2,{24,24},{250,50}},{1,{24,24},{325,225}},{1,{24,24},{850,450}},{1,{24,24},{550,925}},{1,{24,24},{25,350}},{1,{24,24},{700,250}},{1,{24,24},{850,425}},{1,{24,24},{250,400}},{1,{24,24},{950,350}},{1,{24,24},{300,975}},{1,{24,24},{900,350}},{1,{24,24},{400,875}},{1,{24,24},{350,925}},{1,{24,24},{475,800}},{1,{24,24},{925,925}},{1,{24,24},{175,75}},{1,{24,24},{550,725}},{1,{24,24},{600,675}},{1,{24,24},{625,650}},{1,{24,24},{300,50}},{1,{24,24},{675,600}},{1,{24,24},{750,300}},{1,{24,24},{750,525}},{1,{24,24},{825,450}},{1,{24,24},{650,475}},{1,{24,24},{225,50}},{1,{24,24},{800,475}},{1,{24,24},{700,600}},{2,{24,24},{200,175}},{1,{24,24},{125,775}},{1,{24,24},{650,400}},{1,{24,24},{300,950}},{1,{24,24},{325,925}},{1,{24,24},{550,450}},{1,{24,24},{425,825}},{1,{24,24},{400,850}},{1,{24,24},{500,750}},{1,{24,24},{600,650}},{1,{24,24},{750,775}},{1,{24,24},{575,500}},{1,{24,24},{625,625}},{1,{24,24},{25,425}},{1,{24,24},{550,575}},{1,{24,24},{725,525}},{1,{24,24},{825,425}},{1,{24,24},{850,400}},{1,{24,24},{925,800}},{1,{24,24},{150,50}},{1,{24,24},{0,50}},{1,{24,24},{600,825}},{1,{24,24},{50,125}},{1,{24,24},{250,975}},{1,{24,24},{25,75}},{1,{24,24},{275,950}},{1,{24,24},{175,675}},{1,{24,24},{125,575}},{1,{24,24},{925,50}},{1,{24,24},{500,225}},{1,{24,24},{300,150}},{1,{24,24},{550,425}},{1,{24,24},{375,900}},{1,{24,24},{275,775}},{1,{24,24},{750,75}},{1,{24,24},{250,700}},{1,{24,24},{50,775}},{1,{24,24},{350,875}},{1,{24,24},{400,825}},{1,{24,24},{150,225}},{1,{24,24},{400,550}},{1,{24,24},{425,800}},{1,{24,24},{525,700}},{1,{24,24},{675,0}},{1,{24,24},{800,0}},{1,{24,24},{625,600}},{1,{24,24},{650,575}},{1,{24,24},{275,700}},{1,{24,24},{900,875}},{1,{24,24},{325,0}},{1,{24,24},{225,925}},{1,{24,24},{200,825}},{1,{24,24},{200,900}},{1,{24,24},{550,300}},{1,{24,24},{625,125}},{1,{24,24},{825,400}},{1,{24,24},{125,425}},{1,{24,24},{425,700}},{1,{24,24},{950,275}},{1,{24,24},{975,250}},{1,{24,24},{400,350}},{1,{24,24},{350,850}},{1,{24,24},{200,650}},{1,{24,24},{400,800}},{1,{24,24},{675,525}},{1,{24,24},{375,25}},{1,{24,24},{350,575}},{1,{24,24},{450,750}},{1,{24,24},{600,175}},{1,{24,24},{475,725}},{1,{24,24},{900,900}},{1,{24,24},{625,475}},{1,{24,24},{25,925}},{1,{24,24},{375,75}},{1,{24,24},{600,375}},{1,{24,24},{750,0}},{1,{24,24},{25,950}},{1,{24,24},{625,575}},{1,{24,24},{550,650}},{1,{24,24},{650,550}},{1,{24,24},{400,475}},{1,{24,24},{725,475}},{1,{24,24},{100,900}},{1,{24,24},{0,450}},{1,{24,24},{125,100}},{1,{24,24},{650,675}},{1,{24,24},{150,350}},{1,{24,24},{875,325}},{1,{24,24},{900,300}},{1,{24,24},{750,50}},{1,{24,24},{375,275}},{1,{24,24},{975,225}},{1,{24,24},{525,25}},{1,{24,24},{275,0}},{1,{24,24},{875,625}},{1,{24,24},{225,950}},{1,{24,24},{550,100}},{1,{24,24},{275,900}},{1,{24,24},{325,775}},{1,{24,24},{350,300}},{1,{24,24},{100,950}},{1,{24,24},{350,825}},{1,{24,24},{575,325}},{1,{24,24},{575,850}},{1,{24,24},{400,150}},{1,{24,24},{325,400}},{1,{24,24},{725,775}},{1,{24,24},{450,725}},{1,{24,24},{650,75}},{1,{24,24},{650,25}},{1,{24,24},{225,500}},{1,{24,24},{225,0}},{1,{24,24},{125,125}},{1,{24,24},{425,750}},{1,{24,24},{500,675}},{1,{24,24},{475,700}},{1,{24,24},{250,800}},{1,{24,24},{175,950}},{1,{24,24},{675,500}},{1,{24,24},{125,500}},{1,{24,24},{475,225}},{1,{24,24},{75,600}},{1,{24,24},{625,425}},{1,{24,24},{700,475}},{1,{24,24},{775,400}},{1,{24,24},{650,0}},{1,{24,24},{725,450}},{1,{24,24},{900,225}},{1,{24,24},{775,0}},{1,{24,24},{900,275}},{1,{24,24},{775,875}},{1,{24,24},{800,225}},{1,{24,24},{175,975}},{1,{24,24},{700,525}},{1,{24,24},{400,425}},{1,{24,24},{500,450}},{1,{24,24},{600,975}},{1,{24,24},{150,150}},{1,{24,24},{100,50}},{1,{24,24},{925,450}},{1,{24,24},{125,50}},{1,{24,24},{250,725}},{1,{24,24},{50,25}},{1,{24,24},{350,800}},{1,{24,24},{425,725}},{1,{24,24},{875,250}},{1,{24,24},{850,300}},{1,{24,24},{325,100}},{1,{24,24},{175,600}},{1,{24,24},{600,950}},{1,{24,24},{625,525}},{1,{24,24},{550,475}},{1,{24,24},{525,275}},{1,{24,24},{300,875}},{1,{24,24},{875,950}},{1,{24,24},{775,375}},{1,{24,24},{875,275}},{2,{24,24},{0,50}},{1,{24,24},{225,275}},{1,{24,24},{925,225}},{1,{24,24},{0,100}},{1,{24,24},{975,175}},{1,{24,24},{425,175}},{1,{24,24},{150,625}},{1,{24,24},{575,0}},{1,{24,24},{475,450}},{1,{24,24},{900,750}},{1,{24,24},{475,175}},{1,{24,24},{600,575}},{1,{24,24},{500,325}},{1,{24,24},{525,575}},{1,{24,24},{225,900}},{1,{24,24},{675,100}},{1,{24,24},{250,875}},{1,{24,24},{850,500}},{2,{24,24},{100,150}},{1,{24,24},{525,675}},{1,{24,24},{500,625}},{1,{24,24},{700,550}},{2,{24,24},{150,100}},{1,{24,24},{700,425}},{1,{24,24},{600,525}},{1,{24,24},{625,450}},{1,{24,24},{50,525}},{1,{24,24},{825,300}},{1,{24,24},{850,275}},{1,{24,24},{600,550}},{1,{24,24},{800,25}},{1,{24,24},{625,825}},{1,{24,24},{150,950}},{1,{24,24},{200,25}},{1,{24,24},{250,50}},{1,{24,24},{175,925}},{2,{24,24},{300,0}},{1,{24,24},{575,100}},{1,{24,24},{150,775}},{1,{24,24},{500,125}},{1,{24,24},{850,925}},{1,{24,24},{200,75}},{1,{24,24},{200,925}},{1,{24,24},{550,550}},{1,{24,24},{475,150}},{1,{24,24},{600,500}},{1,{24,24},{700,400}},{1,{24,24},{750,100}},{1,{24,24},{925,525}},{1,{24,24},{350,650}},{1,{24,24},{700,200}},{1,{24,24},{800,300}},{1,{24,24},{525,475}},{1,{24,24},{25,125}},{1,{24,24},{75,925}},{1,{24,24},{300,250}},{1,{24,24},{75,700}},{1,{24,24},{725,100}},{1,{24,24},{25,525}},{1,{24,24},{150,925}},{1,{24,24},{125,950}},{1,{24,24},{325,700}},{1,{24,24},{700,175}},{1,{24,24},{75,900}},{1,{24,24},{75,25}},{1,{24,24},{75,575}},{2,{24,24},{175,50}},{1,{24,24},{725,275}},{1,{24,24},{825,475}},{1,{24,24},{325,525}},{1,{24,24},{100,975}},{1,{24,24},{625,375}},{1,{24,24},{450,700}},{1,{24,24},{400,725}},{1,{24,24},{500,575}},{1,{24,24},{725,350}},{1,{24,24},{325,325}},{1,{24,24},{800,275}},{1,{24,24},{400,100}},{1,{24,24},{350,775}},{1,{24,24},{950,125}},{1,{24,24},{925,150}},{1,{24,24},{875,200}},{1,{24,24},{325,650}},{1,{24,24},{175,150}},{1,{24,24},{425,125}},{1,{24,24},{325,850}},{1,{24,24},{675,350}},{1,{24,24},{975,100}},{1,{24,24},{25,50}},{1,{24,24},{75,875}},{1,{24,24},{150,900}},{1,{24,24},{375,50}},{1,{24,24},{675,700}},{1,{24,24},{675,875}},{1,{24,24},{550,625}},{1,{24,24},{225,75}},{1,{24,24},{825,975}},{1,{24,24},{850,875}},{2,{24,24},{0,400}},{1,{24,24},{525,525}},{1,{24,24},{100,700}},{1,{24,24},{25,850}},{1,{24,24},{200,750}},{1,{24,24},{300,575}},{1,{24,24},{900,125}},{1,{24,24},{275,975}},{1,{24,24},{375,100}},{1,{24,24},{575,25}},{1,{24,24},{225,350}},{1,{24,24},{75,625}},{1,{24,24},{800,525}},{1,{24,24},{350,375}},{1,{24,24},{450,250}},{1,{24,24},{700,350}},{1,{24,24},{300,750}},{1,{24,24},{725,550}},{1,{24,24},{825,225}},{1,{24,24},{325,725}},{1,{24,24},{850,200}},{1,{24,24},{0,25}},{1,{24,24},{875,175}},{1,{24,24},{900,150}},{1,{24,24},{950,150}},{1,{24,24},{925,125}},{1,{24,24},{975,75}},{1,{24,24},{100,925}},{1,{24,24},{250,525}},{1,{24,24},{275,25}},{1,{24,24},{875,25}},{1,{24,24},{875,700}},{1,{24,24},{275,750}},{1,{24,24},{250,275}},{1,{24,24},{350,675}},{1,{24,24},{375,650}},{1,{24,24},{200,225}},{1,{24,24},{400,625}},{1,{24,24},{425,600}},{1,{24,24},{525,500}},{1,{24,24},{700,225}},{1,{24,24},{550,525}},{1,{24,24},{50,425}},{1,{24,24},{725,300}},{1,{24,24},{775,250}},{1,{24,24},{50,575}},{1,{24,24},{150,450}},{1,{24,24},{125,725}},{1,{24,24},{600,0}},{1,{24,24},{600,75}},{1,{24,24},{350,350}},{2,{24,24},{175,25}},{1,{24,24},{775,950}},{1,{24,24},{600,450}},{1,{24,24},{25,975}},{1,{24,24},{0,800}},{1,{24,24},{500,375}},{1,{24,24},{350,50}},{1,{24,24},{850,250}},{1,{24,24},{275,475}},{1,{24,24},{125,875}},{1,{24,24},{375,200}},{1,{24,24},{175,825}},{1,{24,24},{400,75}},{1,{24,24},{200,800}},{1,{24,24},{200,275}},{1,{24,24},{250,750}},{1,{24,24},{300,225}},{1,{24,24},{475,100}},{1,{24,24},{975,800}},{1,{24,24},{300,700}},{1,{24,24},{950,50}},{2,{24,24},{25,300}},{1,{24,24},{950,700}},{1,{24,24},{25,775}},{1,{24,24},{625,725}},{1,{24,24},{650,350}},{1,{24,24},{675,325}},{1,{24,24},{700,300}},{1,{24,24},{750,250}},{1,{24,24},{800,200}},{1,{24,24},{75,800}},{1,{24,24},{300,175}},{1,{24,24},{550,225}},{1,{24,24},{825,175}},{1,{24,24},{875,125}},{1,{24,24},{900,100}},{1,{24,24},{525,900}},{1,{24,24},{575,625}},{1,{24,24},{125,850}},{1,{24,24},{175,800}},{1,{24,24},{200,775}},{1,{24,24},{200,175}},{1,{24,24},{225,850}},{1,{24,24},{250,250}},{1,{24,24},{375,0}},{1,{24,24},{575,650}},{1,{24,24},{600,275}},{1,{24,24},{400,175}},{1,{24,24},{375,600}},{1,{24,24},{400,575}},{1,{24,24},{275,650}},{1,{24,24},{450,525}},{1,{24,24},{475,500}},{1,{24,24},{500,475}},{1,{24,24},{575,400}},{1,{24,24},{900,525}},{1,{24,24},{525,150}},{1,{24,24},{775,25}},{1,{24,24},{525,300}},{1,{24,24},{575,75}},{1,{24,24},{700,275}},{1,{24,24},{325,450}},{1,{24,24},{100,250}},{1,{24,24},{725,250}},{1,{24,24},{750,550}},{1,{24,24},{775,200}},{1,{24,24},{825,150}},{1,{24,24},{800,175}},{1,{24,24},{0,950}},{1,{24,24},{25,825}},{1,{24,24},{375,425}},{1,{24,24},{125,825}},{1,{24,24},{75,175}},{1,{24,24},{250,325}},{1,{24,24},{825,75}},{1,{24,24},{325,625}},{1,{24,24},{325,900}},{1,{24,24},{275,75}},{1,{24,24},{475,475}},{1,{24,24},{25,875}},{1,{24,24},{475,300}},{1,{24,24},{650,300}},{1,{24,24},{175,450}},{1,{24,24},{725,900}},{1,{24,24},{850,650}},{1,{24,24},{650,750}},{1,{24,24},{800,150}},{1,{24,24},{875,75}},{1,{24,24},{925,25}},{1,{24,24},{950,0}},{1,{24,24},{400,300}},{1,{24,24},{0,925}},{1,{24,24},{350,275}},{1,{24,24},{75,850}},{1,{24,24},{350,175}},{1,{24,24},{100,825}},{1,{24,24},{400,700}},{1,{24,24},{200,725}},{2,{24,24},{0,125}},{1,{24,24},{450,450}},{1,{24,24},{225,700}},{1,{24,24},{500,425}},{2,{24,24},{75,100}},{2,{24,24},{100,250}},{1,{24,24},{900,25}},{1,{24,24},{150,0}},{1,{24,24},{925,0}},{1,{24,24},{75,825}},{1,{24,24},{950,325}},{2,{24,24},{0,150}},{1,{24,24},{425,150}},{1,{24,24},{500,250}},{1,{24,24},{375,525}},{1,{24,24},{625,325}},{1,{24,24},{150,300}},{1,{24,24},{300,25}},{1,{24,24},{750,850}},{1,{24,24},{250,450}},{1,{24,24},{50,300}},{1,{24,24},{975,475}},{1,{24,24},{725,175}},{1,{24,24},{775,125}},{1,{24,24},{300,650}},{1,{24,24},{50,825}},{1,{24,24},{50,450}},{1,{24,24},{125,750}},{1,{24,24},{375,325}},{1,{24,24},{225,625}},{1,{24,24},{200,675}},{1,{24,24},{775,700}},{1,{24,24},{250,625}},{1,{24,24},{350,525}},{1,{24,24},{325,550}},{1,{24,24},{650,125}},{1,{24,24},{175,525}},{2,{24,24},{25,375}},{1,{24,24},{50,950}},{1,{24,24},{300,675}},{2,{24,24},{125,50}},{1,{24,24},{325,425}},{1,{24,24},{850,25}},{1,{24,24},{875,475}},{1,{24,24},{75,775}},{1,{24,24},{125,200}},{1,{24,24},{400,675}},{1,{24,24},{700,925}},{1,{24,24},{825,350}},{1,{24,24},{750,225}},{1,{24,24},{0,825}},{1,{24,24},{100,575}},{1,{24,24},{150,600}},{1,{24,24},{25,800}},{1,{24,24},{150,675}},{1,{24,24},{475,950}},{1,{24,24},{225,600}},{1,{24,24},{350,475}},{1,{24,24},{525,850}},{1,{24,24},{675,25}},{1,{24,24},{650,100}},{1,{24,24},{775,50}},{1,{24,24},{150,575}},{1,{24,24},{100,25}},{1,{24,24},{250,550}},{1,{24,24},{350,450}},{1,{24,24},{450,350}},{1,{24,24},{425,300}},{1,{24,24},{750,400}},{1,{24,24},{725,75}},{1,{24,24},{350,725}},{1,{24,24},{950,250}},{1,{24,24},{250,375}},{1,{24,24},{450,775}},{1,{24,24},{475,275}},{1,{24,24},{225,825}},{1,{24,24},{350,425}},{1,{24,24},{450,325}},{1,{24,24},{625,150}},{1,{24,24},{500,275}},{1,{24,24},{25,675}},{1,{24,24},{700,75}},{1,{24,24},{25,725}},{1,{24,24},{150,200}},{1,{24,24},{50,700}},{1,{24,24},{500,800}},{1,{24,24},{250,500}},{1,{24,24},{0,150}},{1,{24,24},{225,375}},{1,{24,24},{800,75}},{1,{24,24},{750,200}},{1,{24,24},{450,300}},{1,{24,24},{0,775}},{1,{24,24},{300,125}},{1,{24,24},{325,575}},{1,{24,24},{675,75}},{1,{24,24},{25,700}},{1,{24,24},{50,100}},{1,{24,24},{150,650}},{1,{24,24},{450,275}},{1,{24,24},{650,150}},{1,{24,24},{250,200}},{1,{24,24},{0,700}},{1,{24,24},{100,600}},{1,{24,24},{25,450}},{1,{24,24},{50,875}},{1,{24,24},{700,0}},{1,{24,24},{550,750}},{1,{24,24},{700,450}},{1,{24,24},{750,325}},{1,{24,24},{425,225}},{1,{24,24},{175,325}},{1,{24,24},{925,325}},{1,{24,24},{525,925}},{1,{24,24},{100,525}},{2,{24,24},{75,0}},{1,{24,24},{425,200}},{1,{24,24},{450,175}},{1,{24,24},{675,950}},{1,{24,24},{75,525}},{1,{24,24},{100,500}},{1,{24,24},{125,475}},{1,{24,24},{25,575}},{1,{24,24},{725,400}},{1,{24,24},{75,500}},{1,{24,24},{50,200}},{1,{24,24},{150,425}},{1,{24,24},{350,225}},{1,{24,24},{25,250}},{1,{24,24},{950,100}},{1,{24,24},{900,325}},{1,{24,24},{425,0}},{1,{24,24},{75,975}},{1,{24,24},{25,175}},{1,{24,24},{875,875}},{1,{24,24},{425,100}},{1,{24,24},{225,525}},{1,{24,24},{25,475}},{1,{24,24},{200,300}},{1,{24,24},{450,50}},{1,{24,24},{650,375}},{1,{24,24},{650,425}},{1,{24,24},{875,675}},{1,{24,24},{225,150}},{2,{24,24},{25,250}},{1,{24,24},{200,100}},{1,{24,24},{100,125}}}}}
local iconIndices: { string } = icons[1]
local idIndices: { string } = icons[2]
local iconRegistry: { [number]: { number | { number } } } = icons[3]

Lucide.Icons = iconIndices
function Lucide.GetAsset(name: string)
	local size = 48

	local iconIndex = table.find(iconIndices, name)

	if not iconIndex then
		return nil
	end

	local currentDifference = math.huge
	local currentSize = size

	for registrySize, _ in iconRegistry do
		local diff = math.abs(size - registrySize)

		if diff < currentDifference then
			currentDifference = diff
			currentSize = registrySize
		end
	end

	local icon = iconRegistry[currentSize][iconIndex]
	if icon then
		return {
			IconName = name,
			Url = idIndices[icon[1]],
			ImageRectSize = Vector2.new(icon[2][1], icon[2][2]),
			ImageRectOffset = Vector2.new(icon[3][1], icon[3][2]),
		}
	end

	return nil
end

return Lucide

    return Lucide
end)
-- function Library:GetIcon(IconName: string)
--     if not FetchIcons then
--         return
--     end
--     local Success, Icon = pcall(Icons.GetAsset, IconName)
--     if not Success then
--         return
--     end
--     return Icon
-- end


function Library:GetIcon(IconName: string)
    if not FetchIcons or type(Icons) ~= "table" or type(Icons.GetAsset) ~= "function" then
        return
    end

    local Success, Icon = pcall(Icons.GetAsset, IconName)
    if not Success then
        return
    end

    return Icon
end

function Library:Validate(Table: { [string]: any }, Template: { [string]: any }): { [string]: any }
    if typeof(Table) ~= "table" then
        return Template
    end

    for k, v in pairs(Template) do
        if typeof(k) == "number" then
            continue
        end

        if typeof(v) == "table" then
            Table[k] = Library:Validate(Table[k], v)
        elseif Table[k] == nil then
            Table[k] = v
        end
    end

    return Table
end

--// Creator Functions \\--
local function FillInstance(Table: { [string]: any }, Instance: GuiObject)
    local ThemeProperties = Library.Registry[Instance] or {}
    local DPIProperties = Library.DPIRegistry[Instance] or {}

    local DPIExclude = DPIProperties["DPIExclude"] or Table["DPIExclude"] or {}
    local DPIOffset = DPIProperties["DPIOffset"] or Table["DPIOffset"] or {}

    for k, v in pairs(Table) do
        if k == "DPIExclude" or k == "DPIOffset" then
            continue
        elseif ThemeProperties[k] then
            ThemeProperties[k] = nil
        elseif k ~= "Text" and (Library.Scheme[v] or typeof(v) == "function") then
            -- me when Red in dropdowns break things (temp fix - or perm idk if deivid will do something about this)
            ThemeProperties[k] = v
            Instance[k] = Library.Scheme[v] or v()
            continue
        end

        if not DPIExclude[k] then
            if k == "Position" or k == "Size" or k:match("Padding") then
                DPIProperties[k] = v
                v = ApplyDPIScale(v, DPIOffset[k])
            elseif k == "TextSize" then
                DPIProperties[k] = v
                v = ApplyTextScale(v)
            end
        end

        Instance[k] = v
    end

    if GetTableSize(ThemeProperties) > 0 then
        Library.Registry[Instance] = ThemeProperties
    end
    if GetTableSize(DPIProperties) > 0 then
        DPIProperties["DPIExclude"] = DPIExclude
        DPIProperties["DPIOffset"] = DPIOffset
        Library.DPIRegistry[Instance] = DPIProperties
    end
end

local function New(ClassName: string, Properties: { [string]: any }): any
    local Instance = Instance.new(ClassName)

    if Templates[ClassName] then
        FillInstance(Templates[ClassName], Instance)
    end
    FillInstance(Properties, Instance)

    if Properties["Parent"] and not Properties["ZIndex"] then
        pcall(function()
            Instance.ZIndex = Properties.Parent.ZIndex
        end)
    end

    return Instance
end 
--// Main Instances \\-
 local PlayerGui = Library.LocalPlayer:WaitForChild("PlayerGui", math.huge)

local function SafeParentUI(UI: Instance)
    local success, err = pcall(function()
        UI.Parent = PlayerGui
    end)

    if not success then
        warn("[EXO UI] Failed to parent UI to PlayerGui:", err)
        return false
    end

    return true
end

local function ParentUI(UI: Instance, _SkipHiddenUI: boolean?)
    return SafeParentUI(UI)
end
 
local ScreenGui = New("ScreenGui", {
    Name = "Obsidian",
    DisplayOrder = 2147483647,
    ResetOnSpawn = false,
})
ParentUI(ScreenGui)
Library.ScreenGui = ScreenGui
ScreenGui.DescendantRemoving:Connect(function(Instance)
    Library:RemoveFromRegistry(Instance)
    Library.DPIRegistry[Instance] = nil
end)

local ModalScreenGui = New("ScreenGui", {
    Name = "ObsidanModal",
    DisplayOrder = 2147483647,
    ResetOnSpawn = false,
})
ParentUI(ModalScreenGui, true)

local ModalElement = New("TextButton", {
    BackgroundTransparency = 1,
    Modal = false,
    Size = UDim2.fromScale(0, 0),
    Text = "",
    ZIndex = -999,
    Parent = ModalScreenGui,
})

--// Cursor
local Cursor
do
    Cursor = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Size = UDim2.fromOffset(9, 1),
        Visible = false,
        ZIndex = 999,
        Parent = ScreenGui,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = Cursor,
    })

    local CursorV = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "White",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1, 9),
        Parent = Cursor,
    })
    New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "Dark",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, 2, 1, 2),
        ZIndex = 998,
        Parent = CursorV,
    })
end

--// Notification
local NotificationArea
local NotificationList
do
    NotificationArea = New("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -6, 0, 6),
        Size = UDim2.new(0, 300, 1, -6),
        Parent = ScreenGui,
    })
    NotificationList = New("UIListLayout", {
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Padding = UDim.new(0, 6),
        Parent = NotificationArea,
    })
end

--// Lib Functions \\--
function Library:GetBetterColor(Color: Color3, Add: number): Color3
    Add = Add * (Library.IsLightTheme and -4 or 2)
    return Color3.fromRGB(
        math.clamp(Color.R * 255 + Add, 0, 255),
        math.clamp(Color.G * 255 + Add, 0, 255),
        math.clamp(Color.B * 255 + Add, 0, 255)
    )
end

function Library:GetDarkerColor(Color: Color3): Color3
    local H, S, V = Color:ToHSV()
    return Color3.fromHSV(H, S, V / 2)
end

function Library:GetKeyString(KeyCode: Enum.KeyCode)
    if KeyCode.EnumType == Enum.KeyCode and KeyCode.Value > 33 and KeyCode.Value < 127 then
        return string.char(KeyCode.Value)
    end

    return KeyCode.Name
end

-- function Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?): (number, number)
--     local Params = Instance.new("GetTextBoundsParams")
--     Params.Text = Text
--     Params.RichText = true
--     Params.Font = Font
--     Params.Size = Size
--     Params.Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

--     local Bounds = TextService:GetTextBoundsAsync(Params)
--     return Bounds.X, Bounds.Y
-- end


function Library:GetTextBounds(Text, FontObj, Size, Width)
    Text = tostring(Text or "")
    Size = tonumber(Size) or 16
    Width = Width or workspace.CurrentCamera.ViewportSize.X - 32

    -- Try modern API
    local ok, Bounds = pcall(function()
        local Params = Instance.new("GetTextBoundsParams")
        Params.Text = Text
        Params.RichText = true
        Params.Size = Size
        Params.Width = Width

        -- try setting font safely
        if FontObj then
            Params.Font = FontObj
        else
            Params.Font = Font.fromEnum(Enum.Font.Gotham)
        end

        return TextService:GetTextBoundsAsync(Params)
    end)

    if ok and Bounds then
        return Bounds.X, Bounds.Y
    end

    -- 🔁 fallback to old API (MOST IMPORTANT for Delta)
    local fallbackFont = Enum.Font.Gotham

    -- try to convert FontObj → Enum.Font if possible
    pcall(function()
        if typeof(FontObj) == "EnumItem" then
            fallbackFont = FontObj
        elseif typeof(FontObj) == "Font" then
            -- ignore, not supported in fallback
        end
    end)

    local ok2, size = pcall(function()
        return TextService:GetTextSize(
            Text,
            Size,
            fallbackFont,
            Vector2.new(Width, math.huge)
        )
    end)

    if ok2 and size then
        return size.X, size.Y
    end

    -- 🧠 final fallback (estimate)
    return #Text * Size * 0.55, Size
end


function Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2): boolean
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize
    return Mouse.X >= AbsPos.X
        and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y
        and Mouse.Y <= AbsPos.Y + AbsSize.Y
end

function Library:SafeCallback(Func: (...any) -> ...any, ...: any)
    if not (Func and typeof(Func) == "function") then
        return
    end

    local Result = table.pack(xpcall(Func, function(Error)
        task.defer(error, debug.traceback(Error, 2))
        if Library.NotifyOnError then
            Library:Notify(Error)
        end

        return Error
    end, ...))

    if not Result[1] then
        return nil
    end

    return table.unpack(Result, 2, Result.n)
end

function Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)
    local StartPos
    local FramePos
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) or IsMainWindow and Library.CantDragForced then
            return
        end

        StartPos = Input.Position
        FramePos = UI.Position
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if
            (not IgnoreToggled and not Library.Toggled)
            or (IsMainWindow and Library.CantDragForced)
            or not (ScreenGui and ScreenGui.Parent)
        then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Position =
                UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
        end
    end))
end

function Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: () -> ()?)
    local StartPos
    local FrameSize
    local Dragging = false
    local Changed
    DragFrame.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        StartPos = Input.Position
        FrameSize = UI.Size
        Dragging = true

        Changed = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end
        end)
    end)
    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not UI.Visible or not (ScreenGui and ScreenGui.Parent) then
            Dragging = false
            if Changed and Changed.Connected then
                Changed:Disconnect()
                Changed = nil
            end

            return
        end

        if Dragging and IsHoverInput(Input) then
            local Delta = Input.Position - StartPos
            UI.Size = UDim2.new(
                FrameSize.X.Scale,
                math.clamp(FrameSize.X.Offset + Delta.X, Library.MinSize.X, math.huge),
                FrameSize.Y.Scale,
                math.clamp(FrameSize.Y.Offset + Delta.Y, Library.MinSize.Y, math.huge)
            )
            if Callback then
                Library:SafeCallback(Callback)
            end
        end
    end))
end

function Library:MakeCover(Holder: GuiObject, Place: string)
    local Pos = Places[Place] or { 0, 0 }
    local Size = Sizes[Place] or { 1, 0.5 }

    local Cover = New("Frame", {
        AnchorPoint = Vector2.new(Pos[1], Pos[2]),
        BackgroundColor3 = Holder.BackgroundColor3,
        Position = UDim2.fromScale(Pos[1], Pos[2]),
        Size = UDim2.fromScale(Size[1], Size[2]),
        Parent = Holder,
    })

    return Cover
end

function Library:MakeLine(Frame: GuiObject, Info)
    local Line = New("Frame", {
        AnchorPoint = Info.AnchorPoint or Vector2.zero,
        BackgroundColor3 = "OutlineColor",
        Position = Info.Position,
        Size = Info.Size,
        Parent = Frame,
    })

    return Line
end

function Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)
    local Holder = New("Frame", {
        BackgroundColor3 = "Dark",
        Position = UDim2.fromOffset(-2, -2),
        Size = UDim2.new(1, 4, 1, 4),
        ZIndex = ZIndex,
        Parent = Frame,
    })

    local Outline = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        ZIndex = ZIndex,
        Parent = Holder,
    })

    if Corner and Corner > 0 then
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner + 1),
            Parent = Holder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Corner),
            Parent = Outline,
        })
    end

    return Holder
end

function Library:AddDraggableButton(Text: string, Func)
    local Table = {}

    local Button = New("TextButton", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(6, 6),
        TextSize = 16,
        ZIndex = 10,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
        },
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Button,
    })
    Library:MakeOutline(Button, Library.CornerRadius, 9)

    Table.Button = Button
    Button.MouseButton1Click:Connect(function()
        Library:SafeCallback(Func, Table)
    end)
    Library:MakeDraggable(Button, Button, true)

    function Table:SetText(NewText: string)
        local X, Y = Library:GetTextBounds(NewText, Library.Scheme.Font, 16)

        Button.Text = NewText
        Button.Size = UDim2.fromOffset(X * Library.DPIScale * 2, Y * Library.DPIScale * 2)
        Library:UpdateDPI(Button, {
            Size = UDim2.fromOffset(X * 2, Y * 2),
        })
    end
    Table:SetText(Text)

    return Table
end

function Library:AddDraggableMenu(Name: string)
    local Background = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = UDim2.fromOffset(6, 6)
    Background.Size = UDim2.fromOffset(0, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
    Library:MakeLine(Holder, {
        Position = UDim2.fromOffset(0, 34),
        Size = UDim2.new(1, 0, 0, 1),
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 34),
        Text = Name,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = Label,
    })

    local Container = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 35),
        Size = UDim2.new(1, 0, 1, -35),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        Parent = Container,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 7),
        Parent = Container,
    })

    Library:MakeDraggable(Background, Label, true)
    return Background, Container
end

--// Watermark \\--
do
    local WatermarkBackground = Library:MakeOutline(ScreenGui, Library.CornerRadius, 10)
    WatermarkBackground.AutomaticSize = Enum.AutomaticSize.Y
    --WatermarkBackground.Position = UDim2.fromOffset(6, 6)
    -- 1 (X Scale): Go 100% across the screen's width (to the right edge).
    -- -6 (X Offset): Move left by 6 pixels (creating your margin).
    -- 0 (Y Scale): Go 0% down the screen's height.
    -- 6 (Y Offset): Move down by 6 pixels (the top margi
    WatermarkBackground.AnchorPoint = Vector2.new(1, 0)
    WatermarkBackground.Position = UDim2.new(1, -50, 0, -50)
    WatermarkBackground.Size = UDim2.fromOffset(0, 0)
    WatermarkBackground.Visible = false

    Library:UpdateDPI(WatermarkBackground, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = WatermarkBackground,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })

    local WatermarkLabel = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.fromOffset(0, -8 * Library.DPIScale + 7),
        Text = "",
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = WatermarkLabel,
    })

    Library:MakeDraggable(WatermarkBackground, WatermarkLabel, true)

    local function ResizeWatermark()
        local X, Y = Library:GetTextBounds(WatermarkLabel.Text, Library.Scheme.Font, 15)
        WatermarkBackground.Size = UDim2.fromOffset((12 + X + 12 + 4) * Library.DPIScale, Y * Library.DPIScale * 2 + 4)
        Library:UpdateDPI(WatermarkBackground, {
            Size = UDim2.fromOffset(12 + X + 12 + 4, Y * 2 + 4),
        })
    end

    function Library:SetWatermarkVisibility(Visible: boolean)
        WatermarkBackground.Visible = Visible
        if Visible then
            ResizeWatermark()
        end
    end

    function Library:SetWatermark(Text: string)
        WatermarkLabel.Text = Text
        ResizeWatermark()
    end
end

--// Context Menu \\--
local CurrentMenu
function Library:AddContextMenu(
    Holder: GuiObject,
    Size: UDim2 | () -> (),
    Offset: { [number]: number } | () -> {},
    List: number?,
    ActiveCallback: (Active: boolean) -> ()?
)
    local Menu
    if List then
        Menu = New("ScrollingFrame", {
            AutomaticCanvasSize = List == 2 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            AutomaticSize = List == 1 and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = List == 2 and 2 or 0,
            Size = typeof(Size) == "function" and Size() or Size,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    else
        Menu = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = typeof(Size) == "function" and Size() or Size,
            Visible = false,
            ZIndex = 10,
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
    end

    local Table = {
        Active = false,
        Holder = Holder,
        Menu = Menu,
        List = nil,
        Signal = nil,

        Size = Size,
    }

    if List then
        Table.List = New("UIListLayout", {
            Parent = Menu,
        })
    end

    function Table:Open()
        if CurrentMenu == Table then
            return
        elseif CurrentMenu then
            CurrentMenu:Close()
        end

        CurrentMenu = Table
        Table.Active = true

        if typeof(Offset) == "function" then
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset()[2])
            )
        else
            Menu.Position = UDim2.fromOffset(
                math.floor(Holder.AbsolutePosition.X + Offset[1]),
                math.floor(Holder.AbsolutePosition.Y + Offset[2])
            )
        end
        if typeof(Table.Size) == "function" then
            Menu.Size = Table.Size()
        else
            Menu.Size = ApplyDPIScale(Table.Size)
        end
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, true)
        end

        Menu.Visible = true

        Table.Signal = Holder:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if typeof(Offset) == "function" then
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset()[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset()[2])
                )
            else
                Menu.Position = UDim2.fromOffset(
                    math.floor(Holder.AbsolutePosition.X + Offset[1]),
                    math.floor(Holder.AbsolutePosition.Y + Offset[2])
                )
            end
        end)
    end

    function Table:Close()
        if CurrentMenu ~= Table then
            return
        end
        Menu.Visible = false

        if Table.Signal then
            Table.Signal:Disconnect()
            Table.Signal = nil
        end
        Table.Active = false
        CurrentMenu = nil
        if typeof(ActiveCallback) == "function" then
            Library:SafeCallback(ActiveCallback, false)
        end
    end

    function Table:Toggle()
        if Table.Active then
            Table:Close()
        else
            Table:Open()
        end
    end

    function Table:SetSize(Size)
        Table.Size = Size
        Menu.Size = typeof(Size) == "function" and Size() or Size
    end

    return Table
end

Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
    if IsClickInput(Input, true) then
        local Location = Input.Position

        if
            CurrentMenu
            and not (
                Library:MouseIsOverFrame(CurrentMenu.Menu, Location)
                or Library:MouseIsOverFrame(CurrentMenu.Holder, Location)
            )
        then
            CurrentMenu:Close()
        end
    end
end))








--// Popup Dialog \\--
--// Popup Dialog (fixed clickable version) \\--
local ActiveDialog

local function DialogToVector2(value, fallback)
    if typeof(value) == "Vector2" then
        return Vector2.new(value.X, value.Y)
    elseif typeof(value) == "table" then
        local x = tonumber(value.X or value[1])
        local y = tonumber(value.Y or value[2])
        if x and y then
            return Vector2.new(x, y)
        end
    end
    return fallback
end

function Library:Dialog(DialogInfo)
    DialogInfo = Library:Validate(DialogInfo, {
        Type = "confirm", -- "confirm" | "info"
        Title = "Confirm",
        Description = "Are you sure?",
        ConfirmText = "Confirm",
        CancelText = "Cancel",
        OkText = "OK",

        Risky = true,      -- confirm button red by default
        AllowEscape = true,
        Wait = false,
        Scale = nil,       -- optional Vector2 scale override

        Callback = function() end, -- function(accepted:boolean, reason:string)
        OnConfirm = function() end,
        OnCancel = function() end,
        OnClose = function() end,
    })

    local isInfo = string.lower(tostring(DialogInfo.Type or "confirm")) == "info"

    if ActiveDialog then
        ActiveDialog:Close(false, "replaced")
    end

    local resultEvent = DialogInfo.Wait and Instance.new("BindableEvent") or nil
    local closed = false
    local connections = {}
    local previousModal = ModalElement.Modal
    ModalElement.Modal = true

    local function hook(conn)
        table.insert(connections, conn)
        return conn
    end

    local function getViewport()
        local v = (Library.ScreenGui and Library.ScreenGui.AbsoluteSize) or Vector2.zero
        if v.X <= 0 or v.Y <= 0 then
            v = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        end
        return v
    end

    local blocker = New("TextButton", {
        Name = "DialogBlocker",
        Active = true,
        AutoButtonColor = false,
        BackgroundColor3 = "Dark",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Modal = true,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        TextTransparency = 1,
        ZIndex = 118,
        Parent = Library.ScreenGui,

        DPIExclude = {
            Size = true,
        },
    })

    local popup = New("Frame", {
        Name = "DialogPopup",
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.58, 0.42),
        ZIndex = 130,
        Parent = Library.ScreenGui,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 4),
        Parent = popup,
    })

    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1.2,
        Transparency = 0.1,
        Color = Library.Scheme.OutlineColor:Lerp(Library.Scheme.AccentColor, 0.25),
        Parent = popup,
    })

    local headerBg = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderSizePixel = 0,
        ZIndex = 130,
        Parent = popup,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 4),
        Parent = headerBg,
    })

    local headerLine = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        ZIndex = 131,
        Parent = popup,
    })

    local body = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        ZIndex = 131,
        Parent = popup,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 2),
        Parent = body,
    })

    local header = New("Frame", {
        Active = true,
        BackgroundTransparency = 1,
        ZIndex = 132,
        Parent = popup,
    })

    local title = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(DialogInfo.Title),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 133,
        Parent = header,
    })

    local descScroll = New("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = "OutlineColor",
        ScrollBarThickness = 3,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        ZIndex = 133,
        Parent = body,
    })

    local desc = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(DialogInfo.Description),
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextTransparency = 0.1,
        ZIndex = 133,
        Parent = descScroll,
    })

    local buttonsHolder = New("Frame", {
        BackgroundTransparency = 1,
        ZIndex = 133,
        Parent = body,
    })
local function makeButton(text, kind)
    local btn = New("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BorderSizePixel = 1,
        BorderColor3 = "OutlineColor",
        Text = text,
        TextTransparency = 0,
        ZIndex = 134,
        Parent = buttonsHolder,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 1),
        Parent = btn,
    })

    local stroke = New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.15,
        Parent = btn,
    })

    local idleTextTransparency = 0.05

    if kind == "confirm" then
        local bg = DialogInfo.Risky and Library.Scheme.Red or Library.Scheme.AccentColor
        btn.BackgroundColor3 = bg
        btn.TextColor3 = Library.Scheme.White
        btn.TextStrokeColor3 = Library.Scheme.Dark
        btn.TextStrokeTransparency = 0.78
        stroke.Color = bg:Lerp(Library.Scheme.White, 0.22)
        stroke.Transparency = 0.08
        idleTextTransparency = 0.02
    else
        btn.BackgroundColor3 = Library.Scheme.MainColor
        btn.TextColor3 = Library.Scheme.White
        btn.TextStrokeColor3 = Library.Scheme.Dark
        btn.TextStrokeTransparency = 0.85
        stroke.Color = Library.Scheme.OutlineColor:Lerp(Library.Scheme.White, 0.06)
        stroke.Transparency = 0.14
        idleTextTransparency = 0.08
    end

    btn.TextTransparency = idleTextTransparency

    local hoverTween
    hook(btn.MouseEnter:Connect(function()
        StopTween(hoverTween)
        hoverTween = TweenService:Create(btn, Library.TweenInfo, {
            TextTransparency = 0,
        })
        hoverTween:Play()
    end))

    hook(btn.MouseLeave:Connect(function()
        StopTween(hoverTween)
        hoverTween = TweenService:Create(btn, Library.TweenInfo, {
            TextTransparency = idleTextTransparency,
        })
        hoverTween:Play()
    end))

    return btn
end

    local confirmBtn = makeButton(isInfo and tostring(DialogInfo.OkText) or tostring(DialogInfo.ConfirmText), "confirm")
    local cancelBtn = nil
    if not isInfo then
        cancelBtn = makeButton(tostring(DialogInfo.CancelText), "cancel")
    end

    local scaleX, scaleY
    do
        local v = getViewport()
        local portrait = v.Y > v.X or v.X < 760

        local defaultScale = isInfo
            and (portrait and Vector2.new(0.92, 0.46) or Vector2.new(0.50, 0.32))
            or (portrait and Vector2.new(0.92, 0.62) or Vector2.new(0.58, 0.42))

        local chosen = defaultScale
        if typeof(DialogInfo.Scale) == "Vector2" then
            chosen = DialogInfo.Scale
        elseif typeof(DialogInfo.Scale) == "table" then
            local sx = tonumber(DialogInfo.Scale.X or DialogInfo.Scale[1])
            local sy = tonumber(DialogInfo.Scale.Y or DialogInfo.Scale[2])
            if sx and sy then
                chosen = Vector2.new(sx, sy)
            end
        end

        scaleX, scaleY = chosen.X, chosen.Y
    end

    local function applyLayout()
        local v = getViewport()
        local portrait = v.Y > v.X or v.X < 760
        local stacked = portrait and not isInfo

        local minW, maxW = (portrait and 0.80 or 0.42), (portrait and 0.96 or 0.72)
        local minH, maxH = (portrait and 0.42 or 0.28), (portrait and 0.76 or 0.62)

        scaleX = math.clamp(scaleX, minW, maxW)
        scaleY = math.clamp(scaleY, minH, maxH)
        popup.Size = UDim2.fromScale(scaleX, scaleY)

        local w, h = popup.AbsoluteSize.X, popup.AbsoluteSize.Y
        local padX = math.max(12, math.floor(w * 0.04))
        local padY = math.max(10, math.floor(h * 0.05))
        local gap = math.max(8, math.floor(h * 0.03))
        local headerH = math.max(32, math.floor(h * 0.19))
        local btnH = math.max(32, math.floor(h * 0.13))

        local titleSize = math.clamp(math.floor(h * 0.1), 14, 22)
        local descSize = math.clamp(math.floor(h * 0.08), 13, 18)
        local btnText = math.clamp(math.floor(h * 0.08), 13, 18)

        header.Position = UDim2.fromOffset(padX, padY)
        header.Size = UDim2.new(1, -(padX * 2), 0, headerH)
        title.Size = UDim2.fromScale(1, 1)
        title.TextSize = titleSize

        headerBg.Position = UDim2.fromOffset(0, 0)
        headerBg.Size = UDim2.new(1, 0, 0, padY + headerH + math.floor(gap * 0.5))
        headerLine.Position = UDim2.fromOffset(0, padY + headerH + math.floor(gap * 0.5))
        headerLine.Size = UDim2.new(1, 0, 0, 1)

        local bodyTop = padY + headerH + gap + 2
        body.Position = UDim2.fromOffset(padX, bodyTop)
        body.Size = UDim2.new(1, -(padX * 2), 1, -(bodyTop + padY))

        local innerX = math.max(10, math.floor(padX * 0.75))
        local innerY = math.max(10, math.floor(padY * 0.75))
        local footerH = isInfo and btnH or (stacked and (btnH * 2 + gap) or btnH)

        buttonsHolder.Size = UDim2.new(1, -(innerX * 2), 0, footerH)
        buttonsHolder.Position = UDim2.new(0, innerX, 1, -(innerY + footerH))

        confirmBtn.TextSize = btnText
        if cancelBtn then
            cancelBtn.TextSize = btnText
        end

        if isInfo then
            local bw = math.max(110, math.floor(buttonsHolder.AbsoluteSize.X * 0.5))
            confirmBtn.Size = UDim2.fromOffset(bw, btnH)
            confirmBtn.Position = UDim2.new(0.5, -math.floor(bw / 2), 0, 0)
        elseif stacked then
            confirmBtn.Size = UDim2.new(1, 0, 0, btnH)
            confirmBtn.Position = UDim2.fromOffset(0, 0)
            cancelBtn.Size = UDim2.new(1, 0, 0, btnH)
            cancelBtn.Position = UDim2.fromOffset(0, btnH + gap)
        else
            local totalW = buttonsHolder.AbsoluteSize.X
            local bw = math.max(96, math.floor((totalW - gap) / 2))
            confirmBtn.Size = UDim2.fromOffset(bw, btnH)
            confirmBtn.Position = UDim2.fromOffset(0, 0)
            cancelBtn.Size = UDim2.fromOffset(bw, btnH)
            cancelBtn.Position = UDim2.new(1, -bw, 0, 0)
        end

        local descY = innerY
        local descH = body.AbsoluteSize.Y - (innerY + footerH + gap + innerY)
        descH = math.max(54, descH)

        descScroll.Position = UDim2.fromOffset(innerX, descY)
        descScroll.Size = UDim2.new(1, -(innerX * 2), 0, descH)
        desc.TextSize = descSize
        desc.Size = UDim2.new(1, -6, 0, 0)

        local tx, ty = Library:GetTextBounds(desc.Text, desc.FontFace, desc.TextSize, math.max(16, descScroll.AbsoluteSize.X - 8))
        desc.Size = UDim2.fromOffset(math.max(0, math.ceil(tx)), math.max(descH, math.ceil(ty)))
        descScroll.CanvasSize = UDim2.fromOffset(0, math.ceil(ty))
        descScroll.CanvasPosition = Vector2.zero
    end

    local Dialog = {}
    ActiveDialog = Dialog

    local function finalize(accepted, reason)
        if closed then return end
        closed = true

        if ActiveDialog == Dialog then
            ActiveDialog = nil
        end

        for i = #connections, 1, -1 do
            local c = connections[i]
            if c and c.Connected then
                c:Disconnect()
            end
            connections[i] = nil
        end

        ModalElement.Modal = previousModal

        if resultEvent then
            resultEvent:Fire(accepted, reason)
        end

        task.defer(function()
            if accepted then
                Library:SafeCallback(DialogInfo.OnConfirm, reason)
            else
                Library:SafeCallback(DialogInfo.OnCancel, reason)
            end
            Library:SafeCallback(DialogInfo.Callback, accepted, reason)
            Library:SafeCallback(DialogInfo.OnClose, accepted, reason)
        end)

        TweenService:Create(blocker, Library.TweenInfo, {
            BackgroundTransparency = 1,
        }):Play()

        task.delay(Library.TweenInfo.Time, function()
            if popup and popup.Parent then popup:Destroy() end
            if blocker and blocker.Parent then blocker:Destroy() end
            if resultEvent then
                resultEvent:Destroy()
                resultEvent = nil
            end
        end)
    end

    function Dialog:Close(accepted, reason)
        finalize(accepted == true, reason or "manual")
    end

    hook(confirmBtn.Activated:Connect(function()
        finalize(true, isInfo and "ok" or "confirm")
    end))

    if cancelBtn then
        hook(cancelBtn.Activated:Connect(function()
            finalize(false, "cancel")
        end))
    end

    hook(UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter then
            finalize(true, isInfo and "ok" or "confirm")
            return
        end

        if DialogInfo.AllowEscape and input.KeyCode == Enum.KeyCode.Escape then
            finalize(false, "escape")
            return
        end
    end))

    if Library.ScreenGui then
        hook(Library.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyLayout))
    end

    applyLayout()

    pcall(function()
        Library:MakeDraggable(popup, header, true, false)
    end)

    TweenService:Create(blocker, Library.TweenInfo, {
        BackgroundTransparency = 0.52,
    }):Play()

    if DialogInfo.Wait and resultEvent then
        local accepted, reason = resultEvent.Event:Wait()
        return accepted, reason
    end

    return Dialog
end

function Library:Confirm(...)
    local first = select(1, ...)
    local info = typeof(first) == "table" and first or {
        Title = first or "Confirm",
        Description = select(2, ...) or "",
        Callback = select(3, ...),
    }

    info.Type = "confirm"
    return Library:Dialog(info)
end

function Library:InfoPopup(...)
    local first = select(1, ...)
    local info = typeof(first) == "table" and first or {
        Title = first or "Info",
        Description = select(2, ...) or "",
        Callback = select(3, ...),
    }

    info.Type = "info"
    return Library:Dialog(info)
end
















--// Tooltip \\--
local TooltipLabel = New("TextLabel", {
    BackgroundColor3 = "BackgroundColor",
    BorderColor3 = "OutlineColor",
    BorderSizePixel = 1,
    TextSize = 14,
    TextWrapped = true,
    Visible = false,
    ZIndex = 20,
    Parent = ScreenGui,
})
TooltipLabel:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
    local X, Y = Library:GetTextBounds(
        TooltipLabel.Text,
        TooltipLabel.FontFace,
        TooltipLabel.TextSize,
        workspace.CurrentCamera.ViewportSize.X - TooltipLabel.AbsolutePosition.X - 4
    )

    TooltipLabel.Size = UDim2.fromOffset(X + 8 * Library.DPIScale, Y + 4 * Library.DPIScale)
    Library:UpdateDPI(TooltipLabel, {
        Size = UDim2.fromOffset(X, Y),
        DPIOffset = {
            Size = { 8, 4 },
        },
    })
end)

local CurrentHoverInstance
function Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)
    local TooltipTable = {
        Disabled = false,
        Hovering = false,
        Signals = {},
    }

    local function DoHover()
        if
            CurrentHoverInstance == HoverInstance
            or (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
            or (TooltipTable.Disabled and typeof(DisabledInfoStr) ~= "string")
            or (not TooltipTable.Disabled and typeof(InfoStr) ~= "string")
        then
            return
        end
        CurrentHoverInstance = HoverInstance

        TooltipLabel.Text = TooltipTable.Disabled and DisabledInfoStr or InfoStr
        TooltipLabel.Visible = true

        while
            Library.Toggled
            and Library:MouseIsOverFrame(HoverInstance, Mouse)
            and not (CurrentMenu and Library:MouseIsOverFrame(CurrentMenu.Menu, Mouse))
        do
            TooltipLabel.Position = UDim2.fromOffset(
                Mouse.X + (Library.ShowCustomCursor and 8 or 14),
                Mouse.Y + (Library.ShowCustomCursor and 8 or 12)
            )

            RunService.RenderStepped:Wait()
        end

        TooltipLabel.Visible = false
        CurrentHoverInstance = nil
    end

    table.insert(TooltipTable.Signals, HoverInstance.MouseEnter:Connect(DoHover))
    table.insert(TooltipTable.Signals, HoverInstance.MouseMoved:Connect(DoHover))
    table.insert(
        TooltipTable.Signals,
        HoverInstance.MouseLeave:Connect(function()
            if CurrentHoverInstance ~= HoverInstance then
                return
            end

            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end)
    )

    function TooltipTable:Destroy()
        for Index = #TooltipTable.Signals, 1, -1 do
            local Connection = table.remove(TooltipTable.Signals, Index)
            Connection:Disconnect()
        end

        if CurrentHoverInstance == HoverInstance then
            TooltipLabel.Visible = false
            CurrentHoverInstance = nil
        end
    end

    return TooltipTable
end

function Library:OnUnload(Callback)
    table.insert(Library.UnloadSignals, Callback)
end

function Library:Unload()
    for Index = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Index)
        Connection:Disconnect()
    end

    for _, Callback in pairs(Library.UnloadSignals) do
        Library:SafeCallback(Callback)
    end

    Library.Unloaded = true
    ScreenGui:Destroy()
    ModalScreenGui:Destroy()
    getgenv().Library = nil
end

local CheckIcon = Library:GetIcon("check")
local ArrowIcon = Library:GetIcon("chevron-up")
local ResizeIcon = Library:GetIcon("move-diagonal-2")
local KeyIcon = Library:GetIcon("key")

local BaseAddons = {}
do
    local Funcs = {}

    function Funcs:AddKeyPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.KeyPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local KeyPicker = {
            Text = Info.Text,
            Value = Info.Default,
            Toggled = false,
            Mode = Info.Mode,
            SyncToggleState = Info.SyncToggleState,

            Callback = Info.Callback,
            ChangedCallback = Info.ChangedCallback,
            Changed = Info.Changed,
            Clicked = Info.Clicked,

            Type = "KeyPicker",
        }

        if KeyPicker.Mode == "Press" then
            assert(ParentObj.Type == "Label", "KeyPicker with the mode 'Press' can be only applied on Labels.")
            
            KeyPicker.SyncToggleState = false
            Info.Modes = { "Press" }
            Info.Mode = "Press"
        end

        if KeyPicker.SyncToggleState then
            Info.Modes = { "Toggle" }
            Info.Mode = "Toggle"
        end

        local SpecialKeys = {
            ["MB1"] = Enum.UserInputType.MouseButton1,
            ["MB2"] = Enum.UserInputType.MouseButton2,
            ["MB3"] = Enum.UserInputType.MouseButton3
        }

        local SpecialKeysInput = {
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3"
        }

        local Picker = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = KeyPicker.Value,
            TextSize = 14,
            Parent = ToggleLabel,
        })

        local KeybindsToggle = { Normal = KeyPicker.Mode ~= "Toggle" }; do
            local Holder = New("TextButton", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 16),
                Text = "",
                Visible = not Info.NoUI,
                Parent = Library.KeybindContainer,
            })

            local Label = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = Holder,

                DPIExclude = {
                    Size = true,
                },
            })

            local Checkbox = New("Frame", {
                BackgroundColor3 = "MainColor",
                Size = UDim2.fromOffset(14, 14),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = Holder,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius / 2),
                Parent = Checkbox,
            })
            New("UIStroke", {
                Color = "OutlineColor",
                Parent = Checkbox,
            })

            local CheckImage = New("ImageLabel", {
                Image = CheckIcon and CheckIcon.Url or "",
                ImageColor3 = "FontColor",
                ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
                ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
                ImageTransparency = 1,
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Checkbox,
            })

            function KeybindsToggle:Display(State)
                Label.TextTransparency = State and 0 or 0.5
                CheckImage.ImageTransparency = State and 0 or 1
            end

            function KeybindsToggle:SetText(Text)
                local X = Library:GetTextBounds(Text, Label.FontFace, Label.TextSize)
                Label.Text = Text
                Label.Size = UDim2.new(0, X, 1, 0)
            end

            function KeybindsToggle:SetVisibility(Visibility)
                Holder.Visible = Visibility
            end

            function KeybindsToggle:SetNormal(Normal)
                KeybindsToggle.Normal = Normal

                Holder.Active = not Normal
                Label.Position = Normal and UDim2.fromOffset(0, 0) or UDim2.fromOffset(22 * Library.DPIScale, 0)
                Checkbox.Visible = not Normal
            end

            Holder.MouseButton1Click:Connect(function()
                if KeybindsToggle.Normal then
                    return
                end

                KeyPicker.Toggled = not KeyPicker.Toggled
                KeyPicker:DoClick()
            end)

            KeybindsToggle.Holder = Holder
            KeybindsToggle.Label = Label
            KeybindsToggle.Checkbox = Checkbox
            KeybindsToggle.Loaded = true
            table.insert(Library.KeybindToggles, KeybindsToggle)
        end

        local MenuTable = Library:AddContextMenu(Picker, UDim2.fromOffset(62, 0), function()
            return { Picker.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        KeyPicker.Menu = MenuTable

        local ModeButtons = {}
        for _, Mode in pairs(Info.Modes) do
            local ModeButton = {}

            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 21),
                Text = Mode,
                TextSize = 14,
                TextTransparency = 0.5,
                Parent = MenuTable.Menu,
            })

            function ModeButton:Select()
                for _, Button in pairs(ModeButtons) do
                    Button:Deselect()
                end

                KeyPicker.Mode = Mode

                Button.BackgroundTransparency = 0
                Button.TextTransparency = 0

                MenuTable:Close()
            end

            function ModeButton:Deselect()
                KeyPicker.Mode = nil

                Button.BackgroundTransparency = 1
                Button.TextTransparency = 0.5
            end

            Button.MouseButton1Click:Connect(function()
                ModeButton:Select()
            end)

            if KeyPicker.Mode == Mode then
                ModeButton:Select()
            end

            ModeButtons[Mode] = ModeButton
        end

        function KeyPicker:Display()
            if Library.Unloaded then
                return
            end

            local X, Y =
                Library:GetTextBounds(KeyPicker.Value, Picker.FontFace, Picker.TextSize, ToggleLabel.AbsoluteSize.X)
            Picker.Text = KeyPicker.Value
            Picker.Size = UDim2.fromOffset(X + 9 * Library.DPIScale, Y + 4 * Library.DPIScale)
        end

        function KeyPicker:Update()
            KeyPicker:Display()

            if Info.NoUI then
                return
            end

            if KeyPicker.Mode == "Toggle" and ParentObj.Type == "Toggle" and ParentObj.Disabled then
                KeybindsToggle:SetVisibility(false)
                return
            end

            local State = KeyPicker:GetState()
            local ShowToggle = Library.ShowToggleFrameInKeybinds and KeyPicker.Mode == "Toggle"

            if KeybindsToggle.Loaded then
                if ShowToggle then
                    KeybindsToggle:SetNormal(false)
                else
                    KeybindsToggle:SetNormal(true)
                end

                KeybindsToggle:SetText(("[%s] %s (%s)"):format(KeyPicker.Value, KeyPicker.Text, KeyPicker.Mode))
                KeybindsToggle:SetVisibility(true)
                KeybindsToggle:Display(State)
            end

            Library:UpdateKeybindFrame()
        end

        function KeyPicker:GetState()
            if KeyPicker.Mode == "Always" then
                return true
            elseif KeyPicker.Mode == "Hold" then
                local Key = KeyPicker.Value
                if Key == "None" then
                    return false
                end

                if SpecialKeys[Key] ~= nil then
                    return UserInputService:IsMouseButtonPressed(SpecialKeys[Key]) and not UserInputService:GetFocusedTextBox();
                else
                    return UserInputService:IsKeyDown(Enum.KeyCode[Key]) and not UserInputService:GetFocusedTextBox();
                end;
            else
                return KeyPicker.Toggled;
            end
        end

        function KeyPicker:OnChanged(Func)
            KeyPicker.Changed = Func
        end

        function KeyPicker:OnClick(Func)
            KeyPicker.Clicked = Func
        end

        function KeyPicker:DoClick()
            if KeyPicker.Mode == "Press" then
                if KeyPicker.Toggled and Info.WaitForCallback == true then
                    return
                end

                KeyPicker.Toggled = true
            end

            if ParentObj.Type == "Toggle" and KeyPicker.SyncToggleState then
                ParentObj:SetValue(KeyPicker.Toggled)
            end

            Library:SafeCallback(KeyPicker.Callback, KeyPicker.Toggled)
            Library:SafeCallback(KeyPicker.Changed, KeyPicker.Toggled)

            if KeyPicker.Mode == "Press" then
                KeyPicker.Toggled = false
            end
        end

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2]

            KeyPicker.Value = Key
            if ModeButtons[Mode] then
                ModeButtons[Mode]:Select()
            end

            KeyPicker:Update()
        end

        function KeyPicker:SetText(Text)
            KeybindsToggle:SetText(Text)
            KeyPicker:Update()
        end

        local Picking = false
        Picker.MouseButton1Click:Connect(function()
            if Picking then
                return
            end

            Picking = true

            Picker.Text = "..."
            Picker.Size = UDim2.fromOffset(29 * Library.DPIScale, 18 * Library.DPIScale)

            local Input = UserInputService.InputBegan:Wait()
            local Key = "Unknown"

            if SpecialKeysInput[Input.UserInputType] ~= nil then
                Key = SpecialKeysInput[Input.UserInputType];

            elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                Key = Input.KeyCode == Enum.KeyCode.Escape and "None" or Input.KeyCode.Name
            end

            KeyPicker.Value = Key
            KeyPicker:Update()

            Library:SafeCallback(
                KeyPicker.ChangedCallback,
                Input.KeyCode == Enum.KeyCode.Unknown and Input.UserInputType or Input.KeyCode
            )
            Library:SafeCallback(
                KeyPicker.Changed,
                Input.KeyCode == Enum.KeyCode.Unknown and Input.UserInputType or Input.KeyCode
            )

            RunService.RenderStepped:Wait()
            Picking = false
        end)
        Picker.MouseButton2Click:Connect(MenuTable.Toggle)

        Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
            if
                KeyPicker.Mode == "Always"
                or KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            local Key = KeyPicker.Value
            local HoldingKey = false

            if 
                Key and (
                    SpecialKeysInput[Input.UserInputType] == Key or 
                    (Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Key)
                ) 
            then
                HoldingKey = true
            end

            if KeyPicker.Mode == "Toggle" then
                if HoldingKey then
                    KeyPicker.Toggled = not KeyPicker.Toggled
                    KeyPicker:DoClick()
                end

            elseif KeyPicker.Mode == "Press" then
                if HoldingKey then
                    KeyPicker:DoClick()
                end
            end

            KeyPicker:Update()
        end))

        Library:GiveSignal(UserInputService.InputEnded:Connect(function()
            if
                KeyPicker.Value == "Unknown"
                or KeyPicker.Value == "None"
                or Picking
                or UserInputService:GetFocusedTextBox()
            then
                return
            end

            KeyPicker:Update()
        end))

        KeyPicker:Update()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        Options[Idx] = KeyPicker

        return self
    end

    local HueSequenceTable = {}
    for Hue = 0, 1, 0.1 do
        table.insert(HueSequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)))
    end
    function Funcs:AddColorPicker(Idx, Info)
        Info = Library:Validate(Info, Templates.ColorPicker)

        local ParentObj = self
        local ToggleLabel = ParentObj.TextLabel

        local ColorPicker = {
            Value = Info.Default,
            Transparency = Info.Transparency or 0,
            Title = Info.Title,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Type = "ColorPicker",
        }
        ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = ColorPicker.Value:ToHSV()

        local Holder = New("TextButton", {
            BackgroundColor3 = ColorPicker.Value,
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value),
            BorderSizePixel = 1,
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            Parent = ToggleLabel,
        })

        local HolderTransparency = New("ImageLabel", {
            Image = ObsidianImageManager.GetAsset("TransparencyTexture"),
            ImageTransparency = (1 - ColorPicker.Transparency),
            ScaleType = Enum.ScaleType.Tile,
            Size = UDim2.fromScale(1, 1),
            TileSize = UDim2.fromOffset(9, 9),
            Parent = Holder,
        })

        --// Color Menu \\--
        local ColorMenu = Library:AddContextMenu(
            Holder,
            UDim2.fromOffset(Info.Transparency and 256 or 234, 0),
            function()
                return { 0.5, Holder.AbsoluteSize.Y + 1.5 }
            end,
            1
        )
        ColorMenu.List.Padding = UDim.new(0, 8)
        ColorPicker.ColorMenu = ColorMenu

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 6),
            Parent = ColorMenu.Menu,
        })

        if typeof(ColorPicker.Title) == "string" then
            New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 8),
                Text = ColorPicker.Title,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = ColorMenu.Menu,
            })
        end

        local ColorHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 200),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            Parent = ColorHolder,
        })

        --// Sat Map
        local SatVipMap = New("ImageButton", {
            BackgroundColor3 = ColorPicker.Value,
            Image = ObsidianImageManager.GetAsset("SaturationMap"),
            Size = UDim2.fromOffset(200, 200),
            Parent = ColorHolder,
        })

        local SatVibCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            Size = UDim2.fromOffset(6, 6),
            Parent = SatVipMap,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SatVibCursor,
        })
        New("UIStroke", {
            Color = "Dark",
            Parent = SatVibCursor,
        })

        --// Hue
        local HueSelector = New("TextButton", {
            Size = UDim2.fromOffset(16, 200),
            Text = "",
            Parent = ColorHolder,
        })
        New("UIGradient", {
            Color = ColorSequence.new(HueSequenceTable),
            Rotation = 90,
            Parent = HueSelector,
        })

        local HueCursor = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "White",
            BorderColor3 = "Dark",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, ColorPicker.Hue),
            Size = UDim2.new(1, 2, 0, 1),
            Parent = HueSelector,
        })

        --// Alpha
        local TransparencySelector, TransparencyColor, TransparencyCursor
        if Info.Transparency then
            TransparencySelector = New("ImageButton", {
                Image = ObsidianImageManager.GetAsset("TransparencyTexture"),
                ScaleType = Enum.ScaleType.Tile,
                Size = UDim2.fromOffset(16, 200),
                TileSize = UDim2.fromOffset(8, 8),
                Parent = ColorHolder,
            })

            TransparencyColor = New("Frame", {
                BackgroundColor3 = ColorPicker.Value,
                Size = UDim2.fromScale(1, 1),
                Parent = TransparencySelector,
            })
            New("UIGradient", {
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Parent = TransparencyColor,
            })

            TransparencyCursor = New("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = "White",
                BorderColor3 = "Dark",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(0.5, ColorPicker.Transparency),
                Size = UDim2.new(1, 2, 0, 1),
                Parent = TransparencySelector,
            })
        end

        local InfoHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            Parent = ColorMenu.Menu,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 8),
            Parent = InfoHolder,
        })

        local HueBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "#??????",
            TextSize = 14,
            Parent = InfoHolder,
        })

        local RgbBox = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = false,
            Size = UDim2.fromScale(1, 1),
            Text = "?, ?, ?",
            TextSize = 14,
            Parent = InfoHolder,
        })

        --// Context Menu \\--
        local ContextMenu = Library:AddContextMenu(Holder, UDim2.fromOffset(93, 0), function()
            return { Holder.AbsoluteSize.X + 1.5, 0.5 }
        end, 1)
        ColorPicker.ContextMenu = ContextMenu
        do
            local function CreateButton(Text, Func)
                local Button = New("TextButton", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 21),
                    Text = Text,
                    TextSize = 14,
                    Parent = ContextMenu.Menu,
                })

                Button.MouseButton1Click:Connect(function()
                    Library:SafeCallback(Func)
                    ContextMenu:Close()
                end)
            end

            CreateButton("Copy color", function()
                Library.CopiedColor = { ColorPicker.Value, ColorPicker.Transparency }
            end)

            CreateButton("Paste color", function()
                ColorPicker:SetValueRGB(Library.CopiedColor[1], Library.CopiedColor[2])
            end)

            if setclipboard then
                CreateButton("Copy Hex", function()
                    setclipboard(tostring(ColorPicker.Value:ToHex()))
                end)
                CreateButton("Copy RGB", function()
                    setclipboard(table.concat({
                        math.floor(ColorPicker.Value.R * 255),
                        math.floor(ColorPicker.Value.G * 255),
                        math.floor(ColorPicker.Value.B * 255),
                    }, ", "))
                end)
            end
        end

        --// End \\--

        function ColorPicker:SetHSVFromRGB(Color)
            ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
        end

        function ColorPicker:Display()
            if Library.Unloaded then
                return
            end

            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib)

            Holder.BackgroundColor3 = ColorPicker.Value
            Holder.BorderColor3 = Library:GetDarkerColor(ColorPicker.Value)
            HolderTransparency.ImageTransparency = (1 - ColorPicker.Transparency)

            SatVipMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1)
            if TransparencyColor then
                TransparencyColor.BackgroundColor3 = ColorPicker.Value
            end

            SatVibCursor.Position = UDim2.fromScale(ColorPicker.Sat, 1 - ColorPicker.Vib)
            HueCursor.Position = UDim2.fromScale(0.5, ColorPicker.Hue)
            if TransparencyCursor then
                TransparencyCursor.Position = UDim2.fromScale(0.5, ColorPicker.Transparency)
            end

            HueBox.Text = "#" .. ColorPicker.Value:ToHex()
            RgbBox.Text = table.concat({
                math.floor(ColorPicker.Value.R * 255),
                math.floor(ColorPicker.Value.G * 255),
                math.floor(ColorPicker.Value.B * 255),
            }, ", ")
        end

        function ColorPicker:Update()
            ColorPicker:Display()

            Library:SafeCallback(ColorPicker.Callback, ColorPicker.Value)
            Library:SafeCallback(ColorPicker.Changed, ColorPicker.Value)
        end

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func
        end

        function ColorPicker:SetValue(HSV, Transparency)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3])

            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        function ColorPicker:SetValueRGB(Color, Transparency)
            ColorPicker.Transparency = Info.Transparency and Transparency or 0
            ColorPicker:SetHSVFromRGB(Color)
            ColorPicker:Update()
        end

        Holder.MouseButton1Click:Connect(ColorMenu.Toggle)
        Holder.MouseButton2Click:Connect(ContextMenu.Toggle)

        SatVipMap.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local MinX = SatVipMap.AbsolutePosition.X
                local MaxX = MinX + SatVipMap.AbsoluteSize.X
                local LocationX = math.clamp(Mouse.X, MinX, MaxX)

                local MinY = SatVipMap.AbsolutePosition.Y
                local MaxY = MinY + SatVipMap.AbsoluteSize.Y
                local LocationY = math.clamp(Mouse.Y, MinY, MaxY)

                local OldSat = ColorPicker.Sat
                local OldVib = ColorPicker.Vib
                ColorPicker.Sat = (LocationX - MinX) / (MaxX - MinX)
                ColorPicker.Vib = 1 - ((LocationY - MinY) / (MaxY - MinY))

                if ColorPicker.Sat ~= OldSat or ColorPicker.Vib ~= OldVib then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        HueSelector.InputBegan:Connect(function(Input: InputObject)
            while IsDragInput(Input) do
                local Min = HueSelector.AbsolutePosition.Y
                local Max = Min + HueSelector.AbsoluteSize.Y
                local Location = math.clamp(Mouse.Y, Min, Max)

                local OldHue = ColorPicker.Hue
                ColorPicker.Hue = (Location - Min) / (Max - Min)

                if ColorPicker.Hue ~= OldHue then
                    ColorPicker:Update()
                end

                RunService.RenderStepped:Wait()
            end
        end)
        if TransparencySelector then
            TransparencySelector.InputBegan:Connect(function(Input: InputObject)
                while IsDragInput(Input) do
                    local Min = TransparencySelector.AbsolutePosition.Y
                    local Max = TransparencySelector.AbsolutePosition.Y + TransparencySelector.AbsoluteSize.Y
                    local Location = math.clamp(Mouse.Y, Min, Max)

                    local OldTransparency = ColorPicker.Transparency
                    ColorPicker.Transparency = (Location - Min) / (Max - Min)

                    if ColorPicker.Transparency ~= OldTransparency then
                        ColorPicker:Update()
                    end

                    RunService.RenderStepped:Wait()
                end
            end)
        end

        HueBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local Success, Color = pcall(Color3.fromHex, HueBox.Text)
            if Success and typeof(Color) == "Color3" then
                ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib = Color:ToHSV()
            end

            ColorPicker:Update()
        end)
        RgbBox.FocusLost:Connect(function(Enter)
            if not Enter then
                return
            end

            local R, G, B = RgbBox.Text:match("(%d+),%s*(%d+),%s*(%d+)")
            if R and G and B then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(R, G, B))
            end

            ColorPicker:Update()
        end)

        ColorPicker:Display()

        if ParentObj.Addons then
            table.insert(ParentObj.Addons, ColorPicker)
        end

        Options[Idx] = ColorPicker

        return self
    end

    BaseAddons.__index = Funcs
    BaseAddons.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

local BaseGroupbox = {}
do
    local Funcs = {}

    function Funcs:AddDividerx()
        local Groupbox = self
        local Container = Groupbox.Container

        local Holder = New("Frame", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Size = UDim2.new(1, 0, 0, 2),
            Parent = Container,
        })

        Groupbox:Resize()

        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })
    end
    
    
    -- THIS IS THE NEW, CORRECTED CODE
    function Funcs:AddDivider()
        local Groupbox = self
        local Container = Groupbox.Container
    
        local Holder = New("Frame", {
            BackgroundColor3 = "OutlineColor", -- Use the background as the line color
            BorderSizePixel = 0,               -- Remove the non-scaling border
            Size = UDim2.new(1, 0, 0, 1),      -- Set height to 1px, which will be scaled
            Parent = Container,
        })
    
        Groupbox:Resize()
    
        table.insert(Groupbox.Elements, {
            Holder = Holder,
            Type = "Divider",
        })
    end
    
    
    function Funcs:AddSpacer(Height)
        -- Default to 20px height if no value is provided
        Height = (typeof(Height) == "number" and Height) or 20

        local Groupbox = self
        local Container = Groupbox.Container

        -- Create a simple, invisible frame to act as the spacer
        local SpacerFrame = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Height), -- Full width, specified height
            Parent = Container,
        })

        -- Update the groupbox's size to include the new spacer
        Groupbox:Resize()

        -- Add it to the elements list for layout consistency
        table.insert(Groupbox.Elements, {
            Holder = SpacerFrame,
            Type = "Spacer",
            Visible = true,
        })

        return self -- Return the groupbox to allow for method chaining
    end

    function Funcs:AddLabel(...)
        local Data = {}
        local Addons = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Data.Text = Params.Text or ""
            Data.DoesWrap = Params.DoesWrap or false
            Data.Size = Params.Size or 14
            Data.Visible = Params.Visible or true
            Data.Idx = typeof(Second) == "table" and First or nil
        else
            Data.Text = First or ""
            Data.DoesWrap = Second or false
            Data.Size = 14
            Data.Visible = true
            Data.Idx = select(3, ...) or nil
        end

        local Groupbox = self
        local Container = Groupbox.Container

        local Label = {
            Text = Data.Text,
            DoesWrap = Data.DoesWrap,

            Addons = Addons,

            Visible = Data.Visible,
            Type = "Label",
        }

        local TextLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = Label.Text,
            TextSize = Data.Size,
            TextWrapped = Label.DoesWrap,
            TextXAlignment = Groupbox.IsKeyTab and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
            Parent = Container,
        })

        function Label:SetVisible(Visible: boolean)
            Label.Visible = Visible

            TextLabel.Visible = Label.Visible
            Groupbox:Resize()
        end

        function Label:SetText(Text: string)
            Label.Text = Text
            TextLabel.Text = Text

            if Label.DoesWrap then
                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
            end

            Groupbox:Resize()
        end

        if Label.DoesWrap then
            local _, Y =
                Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
            TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)
        else
            New("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 6),
                Parent = TextLabel,
            })
        end

        if Data.DoesWrap then
            local Last = TextLabel.AbsoluteSize

            TextLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if TextLabel.AbsoluteSize == Last then
                    return
                end

                local _, Y =
                    Library:GetTextBounds(Label.Text, TextLabel.FontFace, TextLabel.TextSize, TextLabel.AbsoluteSize.X)
                TextLabel.Size = UDim2.new(1, 0, 0, Y + 4 * Library.DPIScale)

                Last = TextLabel.AbsoluteSize
                Groupbox:Resize()
            end)
        end

        Groupbox:Resize()

        Label.TextLabel = TextLabel
        Label.Container = Container
        if not Data.DoesWrap then
            setmetatable(Label, BaseAddons)
        end

        Label.Holder = TextLabel
        table.insert(Groupbox.Elements, Label)

        if Data.Idx then
            Labels[Data.Idx] = Label
        else
            table.insert(Labels, Label)
        end

        return Label
    end
    
    
    function Funcs:AddButtonxx(...)
    local function GetInfo(...)
        local Info = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Info.Text = Params.Text or ""
            Info.Func = Params.Func or function() end
            Info.DoubleClick = Params.DoubleClick

            Info.Tooltip = Params.Tooltip
            Info.DisabledTooltip = Params.DisabledTooltip

            Info.Risky = Params.Risky or false
            Info.Disabled = Params.Disabled or false
            Info.Visible = Params.Visible or true
            Info.Idx = typeof(Second) == "table" and First or nil
        else
            Info.Text = First or ""
            Info.Func = Second or function() end
            Info.DoubleClick = false

            Info.Tooltip = nil
            Info.DisabledTooltip = nil

            Info.Risky = false
            Info.Disabled = false
            Info.Visible = true
            Info.Idx = select(3, ...) or nil
        end

        return Info
    end

    local Info = GetInfo(...)
    local Groupbox = self
    local Container = Groupbox.Container
    local Registry = Library.Registry

    local function EnsureRegistry(Obj)
        if not Registry then
            return nil
        end

        Registry[Obj] = Registry[Obj] or {}
        return Registry[Obj]
    end

    local function SetRegistry(Reg, Prop, Value)
        if Reg then
            Reg[Prop] = Value
        end
    end

    local function StopBtnTween(Btn)
        if Btn.Tween then
            StopTween(Btn.Tween)
            Btn.Tween = nil
        end
        if Btn.LabelTween then
            StopTween(Btn.LabelTween)
            Btn.LabelTween = nil
        end
        if Btn.StrokeTween then
            StopTween(Btn.StrokeTween)
            Btn.StrokeTween = nil
        end
        if Btn.AccentTween then
            StopTween(Btn.AccentTween)
            Btn.AccentTween = nil
        end
    end

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Padding = UDim.new(0, 6),
        Parent = Holder,
    })

    local function CreateButton(Btn)
        local Base = New("TextButton", {
            Active = not Btn.Disabled,
            AutoButtonColor = false,
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = Btn.Disabled and 0.80 or 0.38,
            Size = UDim2.new(1, 0, 0, 20),
            Text = "",
            Visible = Btn.Visible,
            Parent = Holder,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = Base,
        })

        New("UISizeConstraint", {
            MinSize = Vector2.new(0, 20),
            Parent = Base,
        })

        local Stroke = New("UIStroke", {
            Color = "OutlineColor",
            Transparency = Btn.Disabled and 0.70 or 0.25,
            Parent = Base,
        })

        local Accent = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = "AccentColor",
            BackgroundTransparency = Btn.Disabled and 0.92 or 0.45,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 0.5, 0),
            Size = UDim2.fromOffset(2, 10),
            ZIndex = 2,
            Parent = Base,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Accent,
        })

        local Label = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 3),
            Size = UDim2.new(1, -16, 0, 0),
            Text = Btn.Text,
            TextColor3 = Btn.Risky and Library.Scheme.Red or Library.Scheme.FontColor,
            TextSize = 14,
            TextTransparency = Btn.Disabled and 0.8 or 0.4,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = Base,
        })

        local function UpdateHeight()
            local h = math.max(Label.AbsoluteSize.Y + 6, 20)
            Base.Size = UDim2.new(1, 0, 0, h)
            Groupbox:Resize()
        end

        Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateHeight)
        task.defer(UpdateHeight)

        Btn.BaseReg = EnsureRegistry(Base)
        Btn.StrokeReg = EnsureRegistry(Stroke)
        Btn.AccentReg = EnsureRegistry(Accent)
        Btn.LabelReg = EnsureRegistry(Label)

        SetRegistry(Btn.BaseReg, "BackgroundColor3", Btn.Disabled and "BackgroundColor" or "MainColor")
        SetRegistry(Btn.StrokeReg, "Color", "OutlineColor")
        SetRegistry(Btn.AccentReg, "BackgroundColor3", "AccentColor")
        SetRegistry(Btn.LabelReg, "TextColor3", Btn.Risky and "Red" or "FontColor")

        return Base, Stroke, Accent, Label
    end

    local function ApplyVisual(Btn, Instant)
        if Library.Unloaded then
            return
        end

        StopBtnTween(Btn)

        local Hovering = Btn.Hovering and not Btn.Disabled and not Btn.Locked

        local TargetBgColor = Btn.Disabled and Library.Scheme.BackgroundColor or Library.Scheme.MainColor
        local TargetBgTransparency = Btn.Disabled and 0.80 or (Hovering and 0.22 or 0.38)
        local TargetTextTransparency = Btn.Disabled and 0.8 or (Hovering and 0 or 0.4)
        local TargetStrokeTransparency = Btn.Disabled and 0.70 or (Hovering and 0.10 or 0.25)
        local TargetAccentTransparency = Btn.Disabled and 0.92 or (Hovering and 0.10 or 0.45)

        Btn.Base.Active = not Btn.Disabled
        Btn.Base.BackgroundColor3 = TargetBgColor
        Btn.Stroke.Color = Library.Scheme.OutlineColor

        if Btn.Accent then
            Btn.Accent.BackgroundTransparency = TargetAccentTransparency
        end

        if not Btn.Locked then
            Btn.Label.TextColor3 = Btn.Risky and Library.Scheme.Red or Library.Scheme.FontColor
            SetRegistry(Btn.LabelReg, "TextColor3", Btn.Risky and "Red" or "FontColor")
        end

        SetRegistry(Btn.BaseReg, "BackgroundColor3", Btn.Disabled and "BackgroundColor" or "MainColor")
        SetRegistry(Btn.StrokeReg, "Color", "OutlineColor")

        if Instant or Btn.Disabled then
            Btn.Base.BackgroundTransparency = TargetBgTransparency
            Btn.Label.TextTransparency = TargetTextTransparency
            Btn.Stroke.Transparency = TargetStrokeTransparency
            return
        end

        Btn.Tween = TweenService:Create(Btn.Base, Library.TweenInfo, {
            BackgroundTransparency = TargetBgTransparency,
        })
        Btn.LabelTween = TweenService:Create(Btn.Label, Library.TweenInfo, {
            TextTransparency = TargetTextTransparency,
        })
        Btn.StrokeTween = TweenService:Create(Btn.Stroke, Library.TweenInfo, {
            Transparency = TargetStrokeTransparency,
        })

        Btn.Tween:Play()
        Btn.LabelTween:Play()
        Btn.StrokeTween:Play()

        if Btn.Accent then
            Btn.AccentTween = TweenService:Create(Btn.Accent, Library.TweenInfo, {
                BackgroundTransparency = TargetAccentTransparency,
            })
            Btn.AccentTween:Play()
        end
    end

    local function InitEvents(Btn)
        Btn.Base.MouseEnter:Connect(function()
            Btn.Hovering = true
            ApplyVisual(Btn, false)
        end)

        Btn.Base.MouseLeave:Connect(function()
            Btn.Hovering = false
            if Btn.Locked then
                return
            end
            ApplyVisual(Btn, false)
        end)

        Btn.Base.MouseButton1Click:Connect(function()
            if Btn.Disabled or Btn.Locked then
                return
            end

            if Btn.DoubleClick then
                Btn.Locked = true
                StopBtnTween(Btn)

                Btn.Label.Text = "Are you sure?"
                Btn.Label.TextColor3 = Library.Scheme.AccentColor
                SetRegistry(Btn.LabelReg, "TextColor3", "AccentColor")

                local Clicked = WaitForEvent(Btn.Base.MouseButton1Click, 0.5)

                Btn.Label.Text = Btn.Text
                Btn.Locked = false
                ApplyVisual(Btn, true)

                if Clicked then
                    Library:SafeCallback(Btn.Func)
                end

                RunService.RenderStepped:Wait()
                return
            end

            Library:SafeCallback(Btn.Func)
        end)
    end

    local Button = {
        Text = Info.Text,
        Func = Info.Func,
        DoubleClick = Info.DoubleClick,

        Tooltip = Info.Tooltip,
        DisabledTooltip = Info.DisabledTooltip,
        TooltipTable = nil,

        Risky = Info.Risky,
        Disabled = Info.Disabled,
        Visible = Info.Visible,

        Tween = nil,
        LabelTween = nil,
        StrokeTween = nil,
        AccentTween = nil,
        Hovering = false,
        Locked = false,
        Type = "Button",
    }

    Button.Base, Button.Stroke, Button.Accent, Button.Label = CreateButton(Button)
    InitEvents(Button)

    function Button:AddButton(...)
        local SubInfo = GetInfo(...)

        local SubButton = {
            Text = SubInfo.Text,
            Func = SubInfo.Func,
            DoubleClick = SubInfo.DoubleClick,

            Tooltip = SubInfo.Tooltip,
            DisabledTooltip = SubInfo.DisabledTooltip,
            TooltipTable = nil,

            Risky = SubInfo.Risky,
            Disabled = SubInfo.Disabled,
            Visible = SubInfo.Visible,

            Tween = nil,
            LabelTween = nil,
            StrokeTween = nil,
            AccentTween = nil,
            Hovering = false,
            Locked = false,
            Type = "SubButton",
        }

        Button.SubButton = SubButton
        SubButton.Base, SubButton.Stroke, SubButton.Accent, SubButton.Label = CreateButton(SubButton)
        InitEvents(SubButton)

        function SubButton:UpdateColors()
            ApplyVisual(SubButton, true)
        end

        function SubButton:SetDisabled(Disabled: boolean)
            SubButton.Disabled = Disabled

            if SubButton.TooltipTable then
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            ApplyVisual(SubButton, true)
        end

        function SubButton:SetVisible(Visible: boolean)
            SubButton.Visible = Visible
            SubButton.Base.Visible = SubButton.Visible
            Groupbox:Resize()
        end

        function SubButton:SetText(Text: string)
            SubButton.Text = Text
            SubButton.Label.Text = Text
        end

        if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
            SubButton.TooltipTable = Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
            SubButton.TooltipTable.Disabled = SubButton.Disabled
        end

        SubButton:UpdateColors()

        if SubInfo.Idx then
            Buttons[SubInfo.Idx] = SubButton
        else
            table.insert(Buttons, SubButton)
        end

        return SubButton
    end

    function Button:UpdateColors()
        ApplyVisual(Button, true)
    end

    function Button:SetDisabled(Disabled: boolean)
        Button.Disabled = Disabled

        if Button.TooltipTable then
            Button.TooltipTable.Disabled = Button.Disabled
        end

        ApplyVisual(Button, true)
    end

    function Button:SetVisible(Visible: boolean)
        Button.Visible = Visible
        Holder.Visible = Button.Visible
        Groupbox:Resize()
    end

    function Button:SetText(Text: string)
        Button.Text = Text
        Button.Label.Text = Text
    end

    if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
        Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
        Button.TooltipTable.Disabled = Button.Disabled
    end

    Button:UpdateColors()
    Groupbox:Resize()

    Button.Holder = Holder
    table.insert(Groupbox.Elements, Button)

    if Info.Idx then
        Buttons[Info.Idx] = Button
    else
        table.insert(Buttons, Button)
    end

    return Button
end

 

    
    function Funcs:AddButton(...)
    local function GetInfo(...)
        local Info = {}

        local First = select(1, ...)
        local Second = select(2, ...)

        if typeof(First) == "table" or typeof(Second) == "table" then
            local Params = typeof(First) == "table" and First or Second

            Info.Text = Params.Text or ""
            Info.Func = Params.Func or function() end
            Info.DoubleClick = Params.DoubleClick

            Info.Tooltip = Params.Tooltip
            Info.DisabledTooltip = Params.DisabledTooltip

            Info.Risky = Params.Risky or false
            Info.Disabled = Params.Disabled or false
            Info.Visible = Params.Visible or true
            Info.Idx = typeof(Second) == "table" and First or nil
        else
            Info.Text = First or ""
            Info.Func = Second or function() end
            Info.DoubleClick = false

            Info.Tooltip = nil
            Info.DisabledTooltip = nil

            Info.Risky = false
            Info.Disabled = false
            Info.Visible = true
            Info.Idx = select(3, ...) or nil
        end

        return Info
    end
    local Info = GetInfo(...)

    local Groupbox = self
    local Container = Groupbox.Container

    local Button = {
        Text = Info.Text,
        Func = Info.Func,
        DoubleClick = Info.DoubleClick,

        Tooltip = Info.Tooltip,
        DisabledTooltip = Info.DisabledTooltip,
        TooltipTable = nil,

        Risky = Info.Risky,
        Disabled = Info.Disabled,
        Visible = Info.Visible,

        Tween = nil,
        Type = "Button",
    }

    local Holder = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Container,
    })

    New("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Padding = UDim.new(0, 9),
        Parent = Holder,
    })

       local function CreateButton(Btn)
            local Base = New("TextButton", {
                Active = not Btn.Disabled,
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Btn.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.new(1, 0, 0, 0),
                Text = Btn.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                TextWrapped = true,
                Visible = Btn.Visible,
                Parent = Holder,
            })
        
            New("UICorner", {
                CornerRadius = UDim.new(0, 6),
                Parent = Base,
            })
        
            New("UIPadding", {
                PaddingTop = UDim.new(0, 7),
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 9),
                PaddingRight = UDim.new(0, 9),
                Parent = Base,
            })
        
            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Btn.Disabled and 0.6 or 0.2,  -- slightly softer stroke
                Thickness = 1,
                Parent = Base,
            })
        
            Base:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                Groupbox:Resize()
            end)
        
            return Base, Stroke
        end

    local function InitEvents(Btn)
        Btn.Base.MouseEnter:Connect(function()
            if Btn.Disabled then return end
            Btn.Tween = TweenService:Create(Btn.Base, Library.TweenInfo, {
                TextTransparency = 0,
            })
            Btn.Tween:Play()
        end)

        Btn.Base.MouseLeave:Connect(function()
            if Btn.Disabled then return end
            Btn.Tween = TweenService:Create(Btn.Base, Library.TweenInfo, {
                TextTransparency = 0.4,
            })
            Btn.Tween:Play()
        end)

        Btn.Base.MouseButton1Click:Connect(function()
            if Btn.Disabled or Btn.Locked then return end

            if Btn.DoubleClick then
                Btn.Locked = true

                Btn.Base.Text = "Are you sure?"
                Btn.Base.TextColor3 = Library.Scheme.AccentColor
                Library.Registry[Btn.Base].TextColor3 = "AccentColor"

                local Clicked = WaitForEvent(Btn.Base.MouseButton1Click, 0.5)

                Btn.Base.Text = Btn.Text
                Btn.Base.TextColor3 = Btn.Risky and Library.Scheme.Red or Library.Scheme.FontColor
                Library.Registry[Btn.Base].TextColor3 = Btn.Risky and "Red" or "FontColor"

                if Clicked then
                    Library:SafeCallback(Btn.Func)
                end

                RunService.RenderStepped:Wait()
                Btn.Locked = false
                return
            end

            Library:SafeCallback(Btn.Func)
        end)
    end

    Button.Base, Button.Stroke = CreateButton(Button)
    InitEvents(Button)

    function Button:AddButton(...)
        local Info = GetInfo(...)

        local SubButton = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "SubButton",
        }

        Button.SubButton = SubButton
        SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
        InitEvents(SubButton)

        function SubButton:UpdateColors()
            if Library.Unloaded then return end

            StopTween(SubButton.Tween)

            SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
            SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

            Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                or "MainColor"
        end

        function SubButton:SetDisabled(Disabled: boolean)
            SubButton.Disabled = Disabled

            if SubButton.TooltipTable then
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            SubButton.Base.Active = not SubButton.Disabled
            SubButton:UpdateColors()
        end

        function SubButton:SetVisible(Visible: boolean)
            SubButton.Visible = Visible
            SubButton.Base.Visible = SubButton.Visible
            Groupbox:Resize()
        end

        function SubButton:SetText(Text: string)
            SubButton.Text = Text
            SubButton.Base.Text = Text
            -- AbsoluteSize signal will fire and trigger Groupbox:Resize() automatically
        end

        if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
            SubButton.TooltipTable =
                Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
            SubButton.TooltipTable.Disabled = SubButton.Disabled
        end

        if SubButton.Risky then
            SubButton.Base.TextColor3 = Library.Scheme.Red
            Library.Registry[SubButton.Base].TextColor3 = "Red"
        end

        SubButton:UpdateColors()

        if Info.Idx then
            Buttons[Info.Idx] = SubButton
        else
            table.insert(Buttons, SubButton)
        end

        return SubButton
    end

    function Button:UpdateColors()
        if Library.Unloaded then return end

        StopTween(Button.Tween)

        Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
            or Library.Scheme.MainColor
        Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
        Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

        Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
    end

    function Button:SetDisabled(Disabled: boolean)
        Button.Disabled = Disabled

        if Button.TooltipTable then
            Button.TooltipTable.Disabled = Button.Disabled
        end

        Button.Base.Active = not Button.Disabled
        Button:UpdateColors()
    end

    function Button:SetVisible(Visible: boolean)
        Button.Visible = Visible
        Holder.Visible = Button.Visible
        Groupbox:Resize()
    end

    function Button:SetText(Text: string)
        Button.Text = Text
        Button.Base.Text = Text
        -- AbsoluteSize signal will fire and trigger Groupbox:Resize() automatically
    end

    if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
        Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
        Button.TooltipTable.Disabled = Button.Disabled
    end

    if Button.Risky then
        Button.Base.TextColor3 = Library.Scheme.Red
        Library.Registry[Button.Base].TextColor3 = "Red"
    end

    Button:UpdateColors()
    Groupbox:Resize()

    Button.Holder = Holder
    table.insert(Groupbox.Elements, Button)

    if Info.Idx then
        Buttons[Info.Idx] = Button
    else
        table.insert(Buttons, Button)
    end

    return Button
end
    

    function Funcs:AddButton_original(...)
        local function GetInfo(...)
            local Info = {}

            local First = select(1, ...)
            local Second = select(2, ...)

            if typeof(First) == "table" or typeof(Second) == "table" then
                local Params = typeof(First) == "table" and First or Second

                Info.Text = Params.Text or ""
                Info.Func = Params.Func or function() end
                Info.DoubleClick = Params.DoubleClick

                Info.Tooltip = Params.Tooltip
                Info.DisabledTooltip = Params.DisabledTooltip

                Info.Risky = Params.Risky or false
                Info.Disabled = Params.Disabled or false
                Info.Visible = Params.Visible or true
                Info.Idx = typeof(Second) == "table" and First or nil
            else
                Info.Text = First or ""
                Info.Func = Second or function() end
                Info.DoubleClick = false

                Info.Tooltip = nil
                Info.DisabledTooltip = nil

                Info.Risky = false
                Info.Disabled = false
                Info.Visible = true
                Info.Idx = select(3, ...) or nil
            end

            return Info
        end
        local Info = GetInfo(...)

        local Groupbox = self
        local Container = Groupbox.Container

        local Button = {
            Text = Info.Text,
            Func = Info.Func,
            DoubleClick = Info.DoubleClick,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Tween = nil,
            Type = "Button",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 21),
            Parent = Container,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalFlex = Enum.UIFlexAlignment.Fill,
            Padding = UDim.new(0, 9),
            Parent = Holder,
        })

        local function CreateButton(Button)
            local Base = New("TextButton", {
                Active = not Button.Disabled,
                BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor",
                Size = UDim2.fromScale(1, 1),
                Text = Button.Text,
                TextSize = 14,
                TextTransparency = 0.4,
                Visible = Button.Visible,
                Parent = Holder,
            })

            local Stroke = New("UIStroke", {
                Color = "OutlineColor",
                Transparency = Button.Disabled and 0.5 or 0,
                Parent = Base,
            })

            return Base, Stroke
        end

        local function InitEvents(Button)
            Button.Base.MouseEnter:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0,
                })
                Button.Tween:Play()
            end)
            Button.Base.MouseLeave:Connect(function()
                if Button.Disabled then
                    return
                end

                Button.Tween = TweenService:Create(Button.Base, Library.TweenInfo, {
                    TextTransparency = 0.4,
                })
                Button.Tween:Play()
            end)

            Button.Base.MouseButton1Click:Connect(function()
                if Button.Disabled or Button.Locked then
                    return
                end

                if Button.DoubleClick then
                    Button.Locked = true

                    Button.Base.Text = "Are you sure?"
                    Button.Base.TextColor3 = Library.Scheme.AccentColor
                    Library.Registry[Button.Base].TextColor3 = "AccentColor"

                    local Clicked = WaitForEvent(Button.Base.MouseButton1Click, 0.5)

                    Button.Base.Text = Button.Text
                    Button.Base.TextColor3 = Button.Risky and Library.Scheme.Red or Library.Scheme.FontColor
                    Library.Registry[Button.Base].TextColor3 = Button.Risky and "Red" or "FontColor"

                    if Clicked then
                        Library:SafeCallback(Button.Func)
                    end

                    RunService.RenderStepped:Wait() --// Mouse Button fires without waiting (i hate roblox)
                    Button.Locked = false
                    return
                end

                Library:SafeCallback(Button.Func)
            end)
        end

        Button.Base, Button.Stroke = CreateButton(Button)
        InitEvents(Button)

        function Button:AddButton(...)
            local Info = GetInfo(...)

            local SubButton = {
                Text = Info.Text,
                Func = Info.Func,
                DoubleClick = Info.DoubleClick,

                Tooltip = Info.Tooltip,
                DisabledTooltip = Info.DisabledTooltip,
                TooltipTable = nil,

                Risky = Info.Risky,
                Disabled = Info.Disabled,
                Visible = Info.Visible,

                Tween = nil,
                Type = "SubButton",
            }

            Button.SubButton = SubButton
            SubButton.Base, SubButton.Stroke = CreateButton(SubButton)
            InitEvents(SubButton)

            function SubButton:UpdateColors()
                if Library.Unloaded then
                    return
                end

                StopTween(SubButton.Tween)

                SubButton.Base.BackgroundColor3 = SubButton.Disabled and Library.Scheme.BackgroundColor
                    or Library.Scheme.MainColor
                SubButton.Base.TextTransparency = SubButton.Disabled and 0.8 or 0.4
                SubButton.Stroke.Transparency = SubButton.Disabled and 0.5 or 0

                Library.Registry[SubButton.Base].BackgroundColor3 = SubButton.Disabled and "BackgroundColor"
                    or "MainColor"
            end

            function SubButton:SetDisabled(Disabled: boolean)
                SubButton.Disabled = Disabled

                if SubButton.TooltipTable then
                    SubButton.TooltipTable.Disabled = SubButton.Disabled
                end

                SubButton.Base.Active = not SubButton.Disabled
                SubButton:UpdateColors()
            end

            function SubButton:SetVisible(Visible: boolean)
                SubButton.Visible = Visible

                SubButton.Base.Visible = SubButton.Visible
                Groupbox:Resize()
            end

            function SubButton:SetText(Text: string)
                SubButton.Text = Text
                SubButton.Base.Text = Text
            end

            if typeof(SubButton.Tooltip) == "string" or typeof(SubButton.DisabledTooltip) == "string" then
                SubButton.TooltipTable =
                    Library:AddTooltip(SubButton.Tooltip, SubButton.DisabledTooltip, SubButton.Base)
                SubButton.TooltipTable.Disabled = SubButton.Disabled
            end

            if SubButton.Risky then
                SubButton.Base.TextColor3 = Library.Scheme.Red
                Library.Registry[SubButton.Base].TextColor3 = "Red"
            end

            SubButton:UpdateColors()

            if Info.Idx then
                Buttons[Info.Idx] = SubButton
            else
                table.insert(Buttons, SubButton)
            end

            return SubButton
        end

        function Button:UpdateColors()
            if Library.Unloaded then
                return
            end

            StopTween(Button.Tween)

            Button.Base.BackgroundColor3 = Button.Disabled and Library.Scheme.BackgroundColor
                or Library.Scheme.MainColor
            Button.Base.TextTransparency = Button.Disabled and 0.8 or 0.4
            Button.Stroke.Transparency = Button.Disabled and 0.5 or 0

            Library.Registry[Button.Base].BackgroundColor3 = Button.Disabled and "BackgroundColor" or "MainColor"
        end

        function Button:SetDisabled(Disabled: boolean)
            Button.Disabled = Disabled

            if Button.TooltipTable then
                Button.TooltipTable.Disabled = Button.Disabled
            end

            Button.Base.Active = not Button.Disabled
            Button:UpdateColors()
        end

        function Button:SetVisible(Visible: boolean)
            Button.Visible = Visible

            Holder.Visible = Button.Visible
            Groupbox:Resize()
        end

        function Button:SetText(Text: string)
            Button.Text = Text
            Button.Base.Text = Text
        end

        if typeof(Button.Tooltip) == "string" or typeof(Button.DisabledTooltip) == "string" then
            Button.TooltipTable = Library:AddTooltip(Button.Tooltip, Button.DisabledTooltip, Button.Base)
            Button.TooltipTable.Disabled = Button.Disabled
        end

        if Button.Risky then
            Button.Base.TextColor3 = Library.Scheme.Red
            Library.Registry[Button.Base].TextColor3 = "Red"
        end

        Button:UpdateColors()
        Groupbox:Resize()

        Button.Holder = Holder
        table.insert(Groupbox.Elements, Button)

        if Info.Idx then
            Buttons[Info.Idx] = Button
        else
            table.insert(Buttons, Button)
        end

        return Button
    end

    function Funcs:AddCheckbox(Idx, Info)
        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(26, 0),
            Size = UDim2.new(1, -26, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Checkbox = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius / 2),
            Parent = Checkbox,
        })

        local CheckboxStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Checkbox,
        })

        local CheckImage = New("ImageLabel", {
            Image = CheckIcon and CheckIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = CheckIcon and CheckIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = CheckIcon and CheckIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 1,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = Checkbox,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            CheckboxStroke.Transparency = Toggle.Disabled and 0.5 or 0

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                CheckImage.ImageTransparency = Toggle.Value and 0.8 or 1

                Checkbox.BackgroundColor3 = Library.Scheme.BackgroundColor
                Library.Registry[Checkbox].BackgroundColor3 = "BackgroundColor"

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(CheckImage, Library.TweenInfo, {
                ImageTransparency = Toggle.Value and 0 or 1,
            }):Play()

            Checkbox.BackgroundColor3 = Library.Scheme.MainColor
            Library.Registry[Checkbox].BackgroundColor3 = "MainColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggles[Idx] = Toggle

        return Toggle
    end
    
    
  function Funcs:AddToggle(Idx, Info)
    if Library.ForceCheckbox then
        return Funcs.AddCheckbox(self, Idx, Info)
    end

    Info = Library:Validate(Info, Templates.Toggle)

    local Groupbox = self
    local Container = Groupbox.Container
    local Registry = Library.Registry

    local function EnsureRegistry(Obj)
        if not Registry then
            return nil
        end
        Registry[Obj] = Registry[Obj] or {}
        return Registry[Obj]
    end

    local Toggle = {
        Text = Info.Text,
        Value = Info.Default,

        Tooltip = Info.Tooltip,
        DisabledTooltip = Info.DisabledTooltip,
        TooltipTable = nil,

        Callback = Info.Callback,
        Changed = Info.Changed,

        Risky = Info.Risky,
        Disabled = Info.Disabled,
        Visible = Info.Visible,
        Addons = {},

        Type = "Toggle",
    }

    local Button = New("TextButton", {
        Active = not Toggle.Disabled,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        Text = "",
        Visible = Toggle.Visible,
        Parent = Container,
    })

    local Row = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        BackgroundTransparency = 0.6,
        Size = UDim2.new(1, 0, 0, 0),
        Parent = Button,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = Row,
    })
    local RowStroke = New("UIStroke", {
        Color = "OutlineColor",
        Transparency = 0.6,
        Parent = Row,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = Row,
    })

    local Switch = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = "MainColor",
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(36, 20),
        Parent = Row,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Switch,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
        PaddingTop = UDim.new(0, 2),
        Parent = Switch,
    })
    local SwitchStroke = New("UIStroke", {
        Color = "OutlineColor",
        Parent = Switch,
    })

    local Ball = New("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromScale(1, 1),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Parent = Switch,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = Ball,
    })

    local Label = New("TextLabel", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -44, 0, 0),
        Text = Toggle.Text,
        TextSize = 14,
        TextTransparency = 0.4,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = Row,
    })

    New("UISizeConstraint", {
        MinSize = Vector2.new(0, 20),
        Parent = Row,
    })

    Label:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local h = math.max(Label.AbsoluteSize.Y, 20)
        Row.Size = UDim2.new(1, 0, 0, h)
        Groupbox:Resize()
    end)

    local SwitchReg = EnsureRegistry(Switch)
    local SwitchStrokeReg = EnsureRegistry(SwitchStroke)
    local BallReg = EnsureRegistry(Ball)
    local LabelReg = EnsureRegistry(Label)

    function Toggle:UpdateColors()
        Toggle:Display()
    end

    function Toggle:Display()
        if Library.Unloaded then return end

        local Offset = Toggle.Value and 1 or 0

        Row.BackgroundTransparency = Toggle.Disabled and 0.8 or 0.6
        RowStroke.Transparency = Toggle.Disabled and 0.8 or 0.6

        Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
        SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

        Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
        SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

        if SwitchReg then
            SwitchReg.BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
        end
        if SwitchStrokeReg then
            SwitchStrokeReg.Color = Toggle.Value and "AccentColor" or "OutlineColor"
        end

        if Toggle.Disabled then
            Label.TextTransparency = 0.8
            Ball.AnchorPoint = Vector2.new(Offset, 0)
            Ball.Position = UDim2.fromScale(Offset, 0)

            Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
            if BallReg then
                BallReg.BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end
            end
            return
        end

        TweenService:Create(Label, Library.TweenInfo, {
            TextTransparency = Toggle.Value and 0 or 0.4,
        }):Play()
        TweenService:Create(Ball, Library.TweenInfo, {
            AnchorPoint = Vector2.new(Offset, 0),
            Position = UDim2.fromScale(Offset, 0),
        }):Play()
        TweenService:Create(Switch, Library.TweenInfo, {
            BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor,
        }):Play()

        Ball.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        if BallReg then
            BallReg.BackgroundColor3 = function()
                return Color3.fromRGB(255, 255, 255)
            end
        end
    end

    function Toggle:OnChanged(Func)
        Toggle.Changed = Func
    end

    function Toggle:SetValue(Value)
        if Toggle.Disabled then return end

        Toggle.Value = Value
        Toggle:Display()

        for _, Addon in pairs(Toggle.Addons) do
            if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                Addon.Toggled = Toggle.Value
                Addon:Update()
            end
        end

        Library:SafeCallback(Toggle.Callback, Toggle.Value)
        Library:SafeCallback(Toggle.Changed, Toggle.Value)
        Library:UpdateDependencyBoxes()
    end

    function Toggle:SetDisabled(Disabled: boolean)
        Toggle.Disabled = Disabled

        if Toggle.TooltipTable then
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        for _, Addon in pairs(Toggle.Addons) do
            if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                Addon:Update()
            end
        end

        Button.Active = not Toggle.Disabled
        Toggle:Display()
    end

    function Toggle:SetVisible(Visible: boolean)
        Toggle.Visible = Visible
        Button.Visible = Toggle.Visible
        Groupbox:Resize()
    end

    function Toggle:SetText(Text: string)
        Toggle.Text = Text
        Label.Text = Text
    end

    Button.MouseButton1Click:Connect(function()
        if Toggle.Disabled then return end
        Toggle:SetValue(not Toggle.Value)
    end)

    if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
        Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
        Toggle.TooltipTable.Disabled = Toggle.Disabled
    end

    if Toggle.Risky then
        Label.TextColor3 = Library.Scheme.Red
        if LabelReg then
            LabelReg.TextColor3 = "Red"
        end
    end

    Toggle:Display()
    Groupbox:Resize()

    Toggle.TextLabel = Label
    Toggle.Container = Container
    setmetatable(Toggle, BaseAddons)

    Toggle.Holder = Button
    table.insert(Groupbox.Elements, Toggle)

    Toggles[Idx] = Toggle

    return Toggle
end

    function Funcs:AddToggle_org(Idx, Info)
        if Library.ForceCheckbox then
            return Funcs.AddCheckbox(self, Idx, Info)
        end

        Info = Library:Validate(Info, Templates.Toggle)

        local Groupbox = self
        local Container = Groupbox.Container

        local Toggle = {
            Text = Info.Text,
            Value = Info.Default,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Risky = Info.Risky,
            Disabled = Info.Disabled,
            Visible = Info.Visible,
            Addons = {},

            Type = "Toggle",
        }

        local Button = New("TextButton", {
            Active = not Toggle.Disabled,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 18),
            Text = "",
            Visible = Toggle.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            Text = Toggle.Text,
            TextSize = 14,
            TextTransparency = 0.4,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Button,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            Padding = UDim.new(0, 6),
            Parent = Label,
        })

        local Switch = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = "MainColor",
            Position = UDim2.fromScale(1, 0),
            Size = UDim2.fromOffset(32, 18),
            Parent = Button,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Switch,
        })
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 2),
            PaddingLeft = UDim.new(0, 2),
            PaddingRight = UDim.new(0, 2),
            PaddingTop = UDim.new(0, 2),
            Parent = Switch,
        })
        local SwitchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Parent = Switch,
        })

        local Ball = New("Frame", {
            BackgroundColor3 = "FontColor",
            Size = UDim2.fromScale(1, 1),
            SizeConstraint = Enum.SizeConstraint.RelativeYY,
            Parent = Switch,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = Ball,
        })

        function Toggle:UpdateColors()
            Toggle:Display()
        end

        function Toggle:Display()
            if Library.Unloaded then
                return
            end

            local Offset = Toggle.Value and 1 or 0

            Switch.BackgroundTransparency = Toggle.Disabled and 0.75 or 0
            SwitchStroke.Transparency = Toggle.Disabled and 0.75 or 0

            Switch.BackgroundColor3 = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.MainColor
            SwitchStroke.Color = Toggle.Value and Library.Scheme.AccentColor or Library.Scheme.OutlineColor

            Library.Registry[Switch].BackgroundColor3 = Toggle.Value and "AccentColor" or "MainColor"
            Library.Registry[SwitchStroke].Color = Toggle.Value and "AccentColor" or "OutlineColor"

            if Toggle.Disabled then
                Label.TextTransparency = 0.8
                Ball.AnchorPoint = Vector2.new(Offset, 0)
                Ball.Position = UDim2.fromScale(Offset, 0)

                Ball.BackgroundColor3 = Library:GetDarkerColor(Library.Scheme.FontColor)
                Library.Registry[Ball].BackgroundColor3 = function()
                    return Library:GetDarkerColor(Library.Scheme.FontColor)
                end

                return
            end

            TweenService:Create(Label, Library.TweenInfo, {
                TextTransparency = Toggle.Value and 0 or 0.4,
            }):Play()
            TweenService:Create(Ball, Library.TweenInfo, {
                AnchorPoint = Vector2.new(Offset, 0),
                Position = UDim2.fromScale(Offset, 0),
            }):Play()

            Ball.BackgroundColor3 = Library.Scheme.FontColor
            Library.Registry[Ball].BackgroundColor3 = "FontColor"
        end

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func
        end

        function Toggle:SetValue(Value)
            if Toggle.Disabled then
                return
            end

            Toggle.Value = Value
            Toggle:Display()

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon.Toggled = Toggle.Value
                    Addon:Update()
                end
            end

            Library:SafeCallback(Toggle.Callback, Toggle.Value)
            Library:SafeCallback(Toggle.Changed, Toggle.Value)
            Library:UpdateDependencyBoxes()
        end

        function Toggle:SetDisabled(Disabled: boolean)
            Toggle.Disabled = Disabled

            if Toggle.TooltipTable then
                Toggle.TooltipTable.Disabled = Toggle.Disabled
            end

            for _, Addon in pairs(Toggle.Addons) do
                if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
                    Addon:Update()
                end
            end

            Button.Active = not Toggle.Disabled
            Toggle:Display()
        end

        function Toggle:SetVisible(Visible: boolean)
            Toggle.Visible = Visible

            Button.Visible = Toggle.Visible
            Groupbox:Resize()
        end

        function Toggle:SetText(Text: string)
            Toggle.Text = Text
            Label.Text = Text
        end

        Button.MouseButton1Click:Connect(function()
            if Toggle.Disabled then
                return
            end

            Toggle:SetValue(not Toggle.Value)
        end)

        if typeof(Toggle.Tooltip) == "string" or typeof(Toggle.DisabledTooltip) == "string" then
            Toggle.TooltipTable = Library:AddTooltip(Toggle.Tooltip, Toggle.DisabledTooltip, Button)
            Toggle.TooltipTable.Disabled = Toggle.Disabled
        end

        if Toggle.Risky then
            Label.TextColor3 = Library.Scheme.Red
            Library.Registry[Label].TextColor3 = "Red"
        end

        Toggle:Display()
        Groupbox:Resize()

        Toggle.TextLabel = Label
        Toggle.Container = Container
        setmetatable(Toggle, BaseAddons)

        Toggle.Holder = Button
        table.insert(Groupbox.Elements, Toggle)

        Toggles[Idx] = Toggle

        return Toggle
    end

    function Funcs:AddInput_old(Idx, Info)
        Info = Library:Validate(Info, Templates.Input)

        local Groupbox = self
        local Container = Groupbox.Container

        local Input = {
            Text = Info.Text,
            Value = Info.Default,
            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Input",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 39),
            Visible = Input.Visible,
            Parent = Container,
        })

        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Input.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 21),
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        function Input:UpdateColors()
            if Library.Unloaded then
                return
            end

            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end

        function Input:OnChanged(Func)
            Input.Changed = Func
        end

        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end

            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end

            if Input.Numeric then
                if #Text > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end

            Input.Value = Text
            Box.Text = Text

            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end

        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled

            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end

            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end

        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible

            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end

        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end

        if Input.Finished then
            Box.FocusLost:Connect(function(Enter)
                if not Enter then
                    return
                end

                Input:SetValue(Box.Text)
            end)
        else
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Input:SetValue(Box.Text)
            end)
        end

        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end

        Groupbox:Resize()

        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)

        Options[Idx] = Input

        return Input
    end



 


     
    function Funcs:AddInput(Idx, Info)
        Info = Library:Validate(Info, Templates.Input)
    
        local Groupbox = self
        local Container = Groupbox.Container
    
        local Input = {
            Text = Info.Text,
            Value = Info.Default,
            Finished = Info.Finished,
            Numeric = Info.Numeric,
            ClearTextOnFocus = Info.ClearTextOnFocus,
            Placeholder = Info.Placeholder,
            AllowEmpty = Info.AllowEmpty,
            EmptyReset = Info.EmptyReset,
    
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,
    
            Callback = Info.Callback,
            Changed = Info.Changed,
    
            Disabled = Info.Disabled,
            Visible = Info.Visible,
    
            Type = "Input",
        }
    
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48), -- Kept larger holder size
            Visible = Input.Visible,
            Parent = Container,
        })
    
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14), -- Reverted to original 14
            Text = Input.Text,
            TextSize = 14, -- Reverted to original 14
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        local Box = New("TextBox", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderSizePixel = 0,
            ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus,
            PlaceholderText = Input.Placeholder,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 30), -- Adjusted to 30 to fill the space
            Text = Input.Value,
            TextEditable = not Input.Disabled,
            TextScaled = false,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
        
        local Underline = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            Position = UDim2.new(0, 0, 1, 0),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = Box,
        })
    
        local AccentLine = New("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = "AccentColor",
            Position = UDim2.fromScale(0.5, 0),
            Size = UDim2.new(0, 0, 1, 0),
            Parent = Underline,
        })
    
        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })
    
        Box.Focused:Connect(function()
            TweenService:Create(AccentLine, Library.TweenInfo, {
                Size = UDim2.fromScale(1, 1)
            }):Play()
        end)
        
        Box.FocusLost:Connect(function(Enter)
            TweenService:Create(AccentLine, Library.TweenInfo, {
                Size = UDim2.fromScale(0, 1)
            }):Play()
            
            if not Enter then
                return
            end
    
            if Input.Finished then
                Input:SetValue(Box.Text)
            end
        end)
    
        function Input:UpdateColors()
            if Library.Unloaded then return end
            Label.TextTransparency = Input.Disabled and 0.8 or 0
            Box.TextTransparency = Input.Disabled and 0.8 or 0
        end
    
        function Input:OnChanged(Func)
            Input.Changed = Func
        end
    
        function Input:SetValue(Text)
            if not Input.AllowEmpty and Trim(Text) == "" then
                Text = Input.EmptyReset
            end
    
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength)
            end
    
            if Input.Numeric then
                if #Text > 0 and not tonumber(Text) then
                    Text = Input.Value
                end
            end
    
            Input.Value = Text
            Box.Text = Text
    
            if not Input.Disabled then
                Library:SafeCallback(Input.Callback, Input.Value)
                Library:SafeCallback(Input.Changed, Input.Value)
            end
        end
    
        function Input:SetDisabled(Disabled: boolean)
            Input.Disabled = Disabled
    
            if Input.TooltipTable then
                Input.TooltipTable.Disabled = Input.Disabled
            end
    
            Box.ClearTextOnFocus = not Input.Disabled and Input.ClearTextOnFocus
            Box.TextEditable = not Input.Disabled
            Input:UpdateColors()
        end
    
        function Input:SetVisible(Visible: boolean)
            Input.Visible = Visible
            Holder.Visible = Input.Visible
            Groupbox:Resize()
        end
    
        function Input:SetText(Text: string)
            Input.Text = Text
            Label.Text = Text
        end
    
        if not Input.Finished then
            Box:GetPropertyChangedSignal("Text"):Connect(function()
                Input:SetValue(Box.Text)
            end)
        end
    
        if typeof(Input.Tooltip) == "string" or typeof(Input.DisabledTooltip) == "string" then
            Input.TooltipTable = Library:AddTooltip(Input.Tooltip, Input.DisabledTooltip, Box)
            Input.TooltipTable.Disabled = Input.Disabled
        end
    
        Groupbox:Resize()
    
        Input.Holder = Holder
        table.insert(Groupbox.Elements, Input)
        Options[Idx] = Input
    
        return Input
    end
    

























    function Funcs:AddSlider(Idx, Info)
        Info = Library:Validate(Info, Templates.Slider)

        local Groupbox = self
        local Container = Groupbox.Container

        local Slider = {
            Text = Info.Text,
            Value = Info.Default,
            Min = Info.Min,
            Max = Info.Max,

            Prefix = Info.Prefix,
            Suffix = Info.Suffix,
            Compact = Info.Compact,
            Rounding = Info.Rounding,

            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,

            Callback = Info.Callback,
            Changed = Info.Changed,

            Disabled = Info.Disabled,
            Visible = Info.Visible,

            Type = "Slider",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Compact and 13 or 31),
            Visible = Slider.Visible,
            Parent = Container,
        })

        local SliderLabel
        if not Info.Compact then
            SliderLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 14),
                Text = Slider.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
        end

        local Bar = New("TextButton", {
            Active = not Slider.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 13),
            Text = "",
            Parent = Holder,
        })

        local DisplayLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            TextSize = 14,
            ZIndex = 2,
            Parent = Bar,
        })
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
            Color = "Dark",
            LineJoinMode = Enum.LineJoinMode.Miter,
            Parent = DisplayLabel,
        })

        local Fill = New("Frame", {
            BackgroundColor3 = "AccentColor",
            Size = UDim2.fromScale(0.5, 1),
            Parent = Bar,

            DPIExclude = {
                Size = true,
            },
        })

        function Slider:UpdateColors()
            if Library.Unloaded then
                return
            end

            if SliderLabel then
                SliderLabel.TextTransparency = Slider.Disabled and 0.8 or 0
            end
            DisplayLabel.TextTransparency = Slider.Disabled and 0.8 or 0

            Fill.BackgroundColor3 = Slider.Disabled and Library.Scheme.OutlineColor or Library.Scheme.AccentColor
            Library.Registry[Fill].BackgroundColor3 = Slider.Disabled and "OutlineColor" or "AccentColor"
        end

        function Slider:Display()
            if Library.Unloaded then
                return
            end

            local CustomDisplayText = nil
            if Info.FormatDisplayValue then
                CustomDisplayText = Info.FormatDisplayValue(Slider, Slider.Value)
            end

            if CustomDisplayText then
                DisplayLabel.Text = tostring(CustomDisplayText)
            else
                if Info.Compact then
                    DisplayLabel.Text = string.format("%s: %s%s%s", Slider.Text, Slider.Prefix, Slider.Value, Slider.Suffix)
                elseif Info.HideMax then
                    DisplayLabel.Text = string.format("%s%s%s", Slider.Prefix, Slider.Value, Slider.Suffix)
                else
                    DisplayLabel.Text = string.format(
                        "%s%s%s/%s%s%s",
                        Slider.Prefix,
                        Slider.Value,
                        Slider.Suffix,
                        Slider.Prefix,
                        Slider.Max,
                        Slider.Suffix
                    )
                end
            end

            local X = (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min)
            Fill.Size = UDim2.fromScale(X, 1)
        end

        function Slider:OnChanged(Func)
            Slider.Changed = Func
        end

        function Slider:SetMax(Value)
            assert(Value > Slider.Min, "Max value cannot be less than the current min value.")

            Slider.Value = math.clamp(Slider.Value, Slider.Min, Value)
            Slider.Max = Value
            Slider:Display()
        end

        function Slider:SetMin(Value)
            assert(Value < Slider.Max, "Min value cannot be greater than the current max value.")

            Slider.Value = math.clamp(Slider.Value, Value, Slider.Max)
            Slider.Min = Value
            Slider:Display()
        end

        function Slider:SetValue(Str)
            if Slider.Disabled then
                return
            end

            local Num = tonumber(Str)
            if not Num then
                return
            end

            Num = math.clamp(Num, Slider.Min, Slider.Max)

            Slider.Value = Num
            Slider:Display()

            Library:SafeCallback(Slider.Callback, Slider.Value)
            Library:SafeCallback(Slider.Changed, Slider.Value)
        end

        function Slider:SetDisabled(Disabled: boolean)
            Slider.Disabled = Disabled

            if Slider.TooltipTable then
                Slider.TooltipTable.Disabled = Slider.Disabled
            end

            Bar.Active = not Slider.Disabled
            Slider:UpdateColors()
        end

        function Slider:SetVisible(Visible: boolean)
            Slider.Visible = Visible

            Holder.Visible = Slider.Visible
            Groupbox:Resize()
        end

        function Slider:SetText(Text: string)
            Slider.Text = Text
            if SliderLabel then
                SliderLabel.Text = Text
                return
            end
            Slider:Display()
        end

        function Slider:SetPrefix(Prefix: string)
            Slider.Prefix = Prefix
            Slider:Display()
        end

        function Slider:SetSuffix(Suffix: string)
            Slider.Suffix = Suffix
            Slider:Display()
        end

        Bar.InputBegan:Connect(function(Input: InputObject)
            if not IsClickInput(Input) or Slider.Disabled then
                return
            end

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = false
            end

            while IsDragInput(Input) do
                local Location = Mouse.X
                local Scale = math.clamp((Location - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)

                local OldValue = Slider.Value
                Slider.Value = Round(Slider.Min + ((Slider.Max - Slider.Min) * Scale), Slider.Rounding)

                Slider:Display()
                if Slider.Value ~= OldValue then
                    Library:SafeCallback(Slider.Callback, Slider.Value)
                    Library:SafeCallback(Slider.Changed, Slider.Value)
                end

                RunService.RenderStepped:Wait()
            end

            for _, Side in pairs(Library.ActiveTab.Sides) do
                Side.ScrollingEnabled = true
            end
        end)

        if typeof(Slider.Tooltip) == "string" or typeof(Slider.DisabledTooltip) == "string" then
            Slider.TooltipTable = Library:AddTooltip(Slider.Tooltip, Slider.DisabledTooltip, Bar)
            Slider.TooltipTable.Disabled = Slider.Disabled
        end

        Slider:UpdateColors()
        Slider:Display()
        Groupbox:Resize()

        Slider.Holder = Holder
        table.insert(Groupbox.Elements, Slider)

        Options[Idx] = Slider

        return Slider
    end
    
 
 --[[
    AddValueDropdown guide

    This is the label/value version of AddDropdown. Use it when the text shown
    to the user should be different from the value saved in settings or returned
    to Callback/Changed. This is a separate function, so normal AddDropdown
    calls keep the old behavior.

    Old array behavior still works:

        Values = {
            "Honey Seed",
            "Bee Balm",
        }

    Label/value options:

        Values = {
            { Text = "<font color=\"#ffd166\">Honey Seed</font>", Value = "Honey Seed" },
            { Text = "<b>Bee Balm</b>", Value = "Bee Balm" },
            { Text = "<font color=\"#ff66cc\">Huge Pet</font>", Value = "pet-uuid-123" },
        }

    Map style also works, but array style above is better because it keeps order:

        Values = {
            ["<b>Honey Seed</b>"] = "Honey Seed",
            ["<font color=\"#ff66cc\">Huge Pet</font>"] = "pet-uuid-123",
        }

    In Multi mode, Callback and SetValue use the Value keys, not the Text:

        Callback = function(Values)
            FSettings.honey_incubator_seeds = Values
            SaveData()
        end

        ddhoneyseeds:SetValues({
            { Text = "<font color=\"#ffd166\">Honey Seed</font>", Value = "Honey Seed" },
            { Text = "<b>Bee Balm</b>", Value = "Bee Balm" },
        })

        ddhoneyseeds:SetValue(FSettings.honey_incubator_seeds or {})

    The saved table stays friendly for loops:

        if FSettings.honey_incubator_seeds[seedName] then
            -- selected
        end
]]
function Funcs:AddValueDropdown(Idx, Info)
    Info = Library:Validate(Info, Templates.Dropdown)
    Info.LabelValueDropdown = true

    local Groupbox = self
    local Container = Groupbox.Container

    if Info.SpecialType == "Player" then
        Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
        Info.AllowNull = true
    elseif Info.SpecialType == "Team" then
        Info.Values = GetTeams()
        Info.AllowNull = true
    end

    local UseValueOptions = Info.LabelValueDropdown == true

    local function NormalizeDropdownValues(Values)
        if not UseValueOptions then
            return Values, nil, nil, nil
        end

        local NormalizedValues = {}
        local NormalizedOptions = {}
        local OptionByValue = {}
        local ValueLookup = {}

        local function AddOption(Text, Value, Raw)
            if Value == nil then
                return
            end

            if Text == nil then
                Text = Value
            end

            local Option = {
                Text = Text,
                Value = Value,
                Raw = Raw,
            }

            table.insert(NormalizedOptions, Option)
            table.insert(NormalizedValues, Value)

            OptionByValue[Value] = Option
            ValueLookup[Value] = true
        end

        if typeof(Values) ~= "table" then
            return NormalizedValues, NormalizedOptions, OptionByValue, ValueLookup
        end

        for _, Item in ipairs(Values) do
            if typeof(Item) == "table" and (Item.Value ~= nil or Item.Text ~= nil or Item.Title ~= nil or Item.Label ~= nil or Item.Name ~= nil) then
                local Text = Item.Text or Item.Title or Item.Label or Item.Name or Item[1] or Item.Value
                local Value = Item.Value

                if Value == nil then
                    if Item[2] ~= nil then
                        Value = Item[2]
                    else
                        Value = Text
                    end
                end

                AddOption(Text, Value, Item)
            else
                AddOption(Item, Item, Item)
            end
        end

        local MapOptions = {}
        for Text, Value in pairs(Values) do
            if typeof(Text) ~= "number" then
                table.insert(MapOptions, {
                    Text = Text,
                    Value = Value,
                })
            end
        end

        table.sort(MapOptions, function(A, B)
            return tostring(A.Text):lower() < tostring(B.Text):lower()
        end)

        for _, Option in ipairs(MapOptions) do
            AddOption(Option.Text, Option.Value, Option)
        end

        return NormalizedValues, NormalizedOptions, OptionByValue, ValueLookup
    end

    local InitialValues, InitialOptions, InitialOptionByValue, InitialValueLookup = NormalizeDropdownValues(Info.Values)

    local Dropdown = {
        Text = typeof(Info.Text) == "string" and Info.Text or nil,
        Value = Info.Multi and {} or nil,
        Values = InitialValues,
        RawValues = Info.Values,
        ValueOptions = InitialOptions,
        OptionByValue = InitialOptionByValue,
        ValueLookup = InitialValueLookup,
        DisabledValues = Info.DisabledValues,
        Multi = Info.Multi,

        SpecialType = Info.SpecialType,
        ExcludeLocalPlayer = Info.ExcludeLocalPlayer,

        Tooltip = Info.Tooltip,
        DisabledTooltip = Info.DisabledTooltip,
        TooltipTable = nil,

        Callback = Info.Callback,
        Changed = Info.Changed,

        Disabled = Info.Disabled,
        Visible = Info.Visible,

        Type = "Dropdown",
    }

    local Holder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, Dropdown.Text and 46 or 28),
        Visible = Dropdown.Visible,
        Parent = Container,
    })

    local Label = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 14),
        Text = Dropdown.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = not not Info.Text,
        Parent = Holder,
    })

    local Display = New("TextButton", {
        Active = not Dropdown.Disabled,
        AnchorPoint = Vector2.new(0, 1),
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.new(1, 0, 0, 28),
        Text = "---",
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Holder,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius),
        Parent = Display,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 4),
        Parent = Display,
    })

    local ArrowImage = New("ImageLabel", {
        AnchorPoint = Vector2.new(1, 0.5),
        Image = ArrowIcon and ArrowIcon.Url or "",
        ImageColor3 = "FontColor",
        ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
        ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
        ImageTransparency = 0.5,
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        Parent = Display,
    })

    local ClickBlocker = New("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BackgroundColor3 = "Dark",
        BackgroundTransparency = 0.5, -- 50% dim
        BorderSizePixel = 0,
        Modal = true,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        Visible = false,
        ZIndex = 119,
        Parent = Library.ScreenGui,
    })

    local Popup = New("Frame", {
        Active = true,
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.56, 0.76),
        Visible = false,
        ZIndex = 120,
        Parent = Library.ScreenGui,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 4),
        Parent = Popup,
    })

    New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1.2,
        Transparency = 0.15,
        Color = Library.Scheme.OutlineColor:Lerp(Library.Scheme.AccentColor, 0.28),
        Parent = Popup,
    })

    local PopupHeaderBg = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderSizePixel = 0,
        ZIndex = 120,
        Parent = Popup,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 4),
        Parent = PopupHeaderBg,
    })

    local PopupHeaderDivider = New("Frame", {
        BackgroundColor3 = "OutlineColor",
        BorderSizePixel = 0,
        ZIndex = 121,
        Parent = Popup,
    })

    local PopupBody = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        ZIndex = 121,
        Parent = Popup,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 2),
        Parent = PopupBody,
    })

    local Header = New("Frame", {
        Active = true,
        BackgroundTransparency = 1,
        ZIndex = 122,
        Parent = Popup,
    })

    local Title = New("TextLabel", {
        BackgroundTransparency = 1,
        Text = Dropdown.Text or "Select",
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 123,
        Parent = Header,
    })

    local CloseButton = New("TextButton", {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Text = Info.Multi and "Done" or "Close",
        ZIndex = 123,
        Parent = Header,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 1),
        Parent = CloseButton,
    })

    local CloseButtonStroke = New("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = 1,
        Transparency = 0.25,
        Parent = CloseButton,
    })

    local SearchInput = New("TextBox", {
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        PlaceholderText = "Search items...",
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = Info.Searchable == true,
        ZIndex = 123,
        Parent = PopupBody,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 1),
        Parent = SearchInput,
    })

    New("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
        Parent = SearchInput,
    })

    local List = New("ScrollingFrame", {
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarImageColor3 = "OutlineColor",
        ScrollBarThickness = 4,
        TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
        ZIndex = 123,
        Parent = PopupBody,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius + 1),
        Parent = List,
    })

    local ListLayout = New("UIListLayout", {
        Parent = List,
    })

    local ResizeHandle = New("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        AutoButtonColor = false,
        BackgroundColor3 = "MainColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromScale(1, 1),
        Size = UDim2.fromOffset(18, 18),
        Text = "",
        ZIndex = 124,
        Parent = Popup,
    })

    New("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = ResizeHandle,
    })

    local Buttons = {}
    local MenuState = { Active = false, Menu = Popup }
    local PopupScale = { W = 0.56, H = 0.76 }
    local CurrentRowHeight = 40
    local CurrentOptionTextSize = 14
    local RenderVirtualRows
    local VirtualState = {
        Active = false,
        Values = {},
        DisabledLookup = {},
        Rows = {},
        RowCount = 0,
        LastFirstIndex = -1,
    }
    local VirtualDropdownThreshold = tonumber(Info.VirtualDropdownThreshold) or 80
    local VirtualDropdownBuffer = tonumber(Info.VirtualDropdownBuffer) or 8
    
    local function ClearDropdownList()
        VirtualState.Active = false
        VirtualState.Values = {}
        VirtualState.DisabledLookup = {}
        VirtualState.RowCount = 0
        VirtualState.LastFirstIndex = -1

        for Button, _ in pairs(Buttons) do
            if Button then
                Button:Destroy()
            end
        end

        table.clear(Buttons)
        table.clear(VirtualState.Rows)

        ListLayout.Parent = List
        List.AutomaticCanvasSize = Enum.AutomaticSize.Y
        List.CanvasSize = UDim2.fromOffset(0, 0)
        List.CanvasPosition = Vector2.zero
    end

    local function StripRichText(Text)
        return tostring(Text or ""):gsub("<[^<>]->", "")
    end

    local function ContainsValue(Value)
        if UseValueOptions then
            return Dropdown.ValueLookup and Dropdown.ValueLookup[Value] == true
        end

        return table.find(Dropdown.Values, Value) ~= nil
    end

    local function ResolveOptionValue(Value)
        if UseValueOptions and typeof(Value) == "table" and Value.Value ~= nil then
            return Value.Value
        end

        return Value
    end

    local function GetOptionText(Value)
        if UseValueOptions then
            local Option = Dropdown.OptionByValue and Dropdown.OptionByValue[Value]
            if Option and Option.Text ~= nil then
                return Option.Text
            end
        end

        return Value
    end

    local function GetDisplayText(Value)
        if UseValueOptions then
            local Option = Dropdown.OptionByValue and Dropdown.OptionByValue[Value]
            local Text = Option and Option.Text or Value

            if Info.FormatDisplayValue then
                return Info.FormatDisplayValue(Value, Text, Option)
            end

            return Text
        end

        return Info.FormatDisplayValue and Info.FormatDisplayValue(Value) or Value
    end

    local function GetSearchText(Value)
        if UseValueOptions then
            return (StripRichText(GetOptionText(Value)) .. " " .. tostring(Value)):lower()
        end

        return tostring(Value):lower()
    end

    local function IsSelected(Value)
        if Info.Multi then
            return Dropdown.Value[Value] == true
        end
        return Dropdown.Value == Value
    end

    local function UpdateCloseButtonStyle()
        if Info.Multi then
            CloseButton.Text = "Done"
            CloseButton.BackgroundColor3 = Library.Scheme.AccentColor:Lerp(Library.Scheme.MainColor, 0.2)
            CloseButtonStroke.Color = Library.Scheme.AccentColor:Lerp(Library.Scheme.White, 0.2)
            CloseButtonStroke.Transparency = 0.2
        else
            CloseButton.Text = "Close"
            CloseButton.BackgroundColor3 = Library.Scheme.MainColor
            CloseButtonStroke.Color = Library.Scheme.OutlineColor
            CloseButtonStroke.Transparency = 0.35
        end
    end

    local function GetPopupMetrics()
        local viewport = Library.ScreenGui and Library.ScreenGui.AbsoluteSize or Vector2.new(1280, 720)
        local isPortrait = viewport.Y > viewport.X

        local minWScale = isPortrait and 0.78 or 0.42
        local maxWScale = isPortrait and 0.96 or 0.82
        local minHScale = isPortrait and 0.48 or 0.52
        local maxHScale = 0.90

        PopupScale.W = math.clamp(PopupScale.W, minWScale, maxWScale)
        PopupScale.H = math.clamp(PopupScale.H, minHScale, maxHScale)

        local width = viewport.X * PopupScale.W
        local height = viewport.Y * PopupScale.H

        local padX = width * 0.036
        local padY = height * 0.03
        local headerH = height * 0.08
        local searchH = height * 0.085
        local gap = height * 0.018

        local titleText = math.clamp(math.floor(height * 0.038), 13, 22)
        local inputText = math.clamp(math.floor(height * 0.031), 12, 18)

        -- ~10% smaller rows/buttons than previous
        local optionText = math.clamp(math.floor(height * 0.027), 12, 17)
        local rowH = math.clamp(height * 0.078, 30, 52)

        return {
            width = width,
            height = height,
            padX = padX,
            padY = padY,
            headerH = headerH,
            searchH = searchH,
            gap = gap,
            titleText = titleText,
            inputText = inputText,
            optionText = optionText,
            rowH = rowH,
        }
    end

    local function ApplyPopupLayout()
        local M = GetPopupMetrics()
        local closeH = math.floor(M.headerH * 0.72)
        local closeW = math.max(78, math.floor(closeH * 2.05))
        local bodyTop, innerPadX, innerPadY, listTop

        Popup.Size = UDim2.fromScale(PopupScale.W, PopupScale.H)

        Header.Position = UDim2.fromOffset(M.padX, M.padY)
        Header.Size = UDim2.new(1, -M.padX * 2, 0, M.headerH)

        Title.Position = UDim2.fromOffset(0, 0)
        Title.Size = UDim2.new(1, -(closeW + 12), 1, 0)
        Title.TextSize = M.titleText

        CloseButton.Size = UDim2.fromOffset(closeW, closeH)
        CloseButton.Position = UDim2.new(1, -closeW, 0.5, -math.floor(closeH / 2))
        CloseButton.TextSize = math.max(12, M.inputText - 1)

        PopupHeaderBg.Position = UDim2.fromOffset(0, 0)
        PopupHeaderBg.Size = UDim2.new(1, 0, 0, M.padY + M.headerH + M.gap * 0.65)

        PopupHeaderDivider.Position = UDim2.fromOffset(0, math.floor(M.padY + M.headerH + M.gap * 0.65))
        PopupHeaderDivider.Size = UDim2.new(1, 0, 0, 1)

        bodyTop = math.floor(M.padY + M.headerH + M.gap + 2)
        PopupBody.Position = UDim2.fromOffset(M.padX, bodyTop)
        PopupBody.Size = UDim2.new(1, -M.padX * 2, 1, -(bodyTop + M.padY))

        innerPadX = math.max(10, math.floor(M.padX * 0.7))
        innerPadY = math.max(10, math.floor(M.padY * 0.65))

        if SearchInput.Visible then
            SearchInput.Position = UDim2.fromOffset(innerPadX, innerPadY)
            SearchInput.Size = UDim2.new(1, -(innerPadX * 2), 0, M.searchH)
            SearchInput.TextSize = M.inputText

            listTop = innerPadY + M.searchH + M.gap
            List.Position = UDim2.fromOffset(innerPadX, listTop)
            List.Size = UDim2.new(1, -(innerPadX * 2), 1, -(listTop + innerPadY))
        else
            List.Position = UDim2.fromOffset(innerPadX, innerPadY)
            List.Size = UDim2.new(1, -(innerPadX * 2), 1, -(innerPadY * 2))
        end

        CurrentRowHeight = M.rowH
        CurrentOptionTextSize = M.optionText
        ListLayout.Padding = UDim.new(0, math.max(4, math.floor(M.gap * 0.45)))

        for _, Entry in pairs(Buttons) do
            Entry.Button.Size = UDim2.new(1, -8, 0, CurrentRowHeight)
            Entry.Button.TextSize = CurrentOptionTextSize
        end

        if RenderVirtualRows then
            RenderVirtualRows(true)
        end
    end

    local function UpdateEntry(Entry)
        local selected = IsSelected(Entry.Value)

        Entry.Button.BackgroundColor3 = Library.Scheme.MainColor:Lerp(Library.Scheme.AccentColor, 0.15)
        Entry.Button.BackgroundTransparency = selected and 0.5 or 1 
        Entry.Button.TextTransparency = Entry.Disabled and 0.8 or (selected and 0.04 or 0.45)
        Entry.Button.Text = tostring(GetOptionText(Entry.Value))
    end

    local function RefreshButtons()
        for _, Entry in pairs(Buttons) do
            UpdateEntry(Entry)
        end
    end

    local function ClosePopup()
        if not MenuState.Active then
            return
        end

        MenuState.Active = false
        ClickBlocker.Visible = false
        Popup.Visible = false
        
        ClearDropdownList()

        if UserInputService:GetFocusedTextBox() == SearchInput then
            pcall(function()
                SearchInput:ReleaseFocus()
            end)
        end

        Dropdown:UpdateColors()
    end

    local function BuildOrderedValues(Query: string, PrioritizeSelected: boolean)
        local Selected = {}
        local Unselected = {}

        for _, Value in pairs(Dropdown.Values or {}) do
            if Query ~= "" then
                local SearchText = GetSearchText(Value)

                if UseValueOptions then
                    if not SearchText:find(Query, 1, true) then
                        continue
                    end
                elseif not SearchText:find(Query, 1, true) then
                    continue
                end
            end

            if PrioritizeSelected and IsSelected(Value) then
                table.insert(Selected, Value)
            else
                table.insert(Unselected, Value)
            end
        end

        if not PrioritizeSelected then
            return Unselected
        end

        for i = 1, #Unselected do
            table.insert(Selected, Unselected[i])
        end

        return Selected
    end

    local function ApplySelection(Value)
        local wasSelected = IsSelected(Value)
        local nextSelected = not wasSelected

        if Dropdown:GetActiveValues() == 1 and not nextSelected and not Info.AllowNull then
            return
        end

        if Info.Multi then
            Dropdown.Value[Value] = nextSelected and true or nil
        else
            Dropdown.Value = nextSelected and Value or nil
        end

        Dropdown:Display()
        RefreshButtons()

        Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
        Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
        Library:UpdateDependencyBoxes()

        if not Info.Multi then
            ClosePopup()
        end
    end

    local function CreateDropdownButton(LayoutOrder)
        local Button = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BackgroundTransparency = 1,
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 0,
            LayoutOrder = LayoutOrder or 0,
            Size = UDim2.new(1, -8, 0, CurrentRowHeight),
            Text = "",
            TextSize = CurrentOptionTextSize,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 123,
            Parent = List,
        })

        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 1),
            Parent = Button,
        })

        New("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 10),
            Parent = Button,
        })

        Button.MouseButton1Click:Connect(function()
            local Entry = Buttons[Button]
            if not Entry or Entry.Disabled or Dropdown.Disabled then
                return
            end

            ApplySelection(Entry.Value)
        end)

        return Button
    end

    RenderVirtualRows = function(Force)
        if not MenuState.Active or not VirtualState.Active then
            return
        end

        local values = VirtualState.Values or {}
        local total = #values
        local rowHeight = math.max(CurrentRowHeight, 1)

        if total <= 0 then
            return
        end

        local firstIndex = math.floor((List.CanvasPosition.Y or 0) / rowHeight) + 1
        firstIndex = math.clamp(firstIndex, 1, total)

        if not Force and firstIndex == VirtualState.LastFirstIndex then
            return
        end

        VirtualState.LastFirstIndex = firstIndex

        for row = 1, VirtualState.RowCount do
            local button = VirtualState.Rows[row]

            if not button then
                button = CreateDropdownButton(row)
                button.AnchorPoint = Vector2.zero
                VirtualState.Rows[row] = button
            end

            local index = firstIndex + row - 1
            local value = values[index]

            if value == nil then
                Buttons[button] = nil
                button.Visible = false
                continue
            end

            local entry = Buttons[button] or { Button = button }
            entry.Value = value
            entry.Disabled = VirtualState.DisabledLookup[value] == true
            Buttons[button] = entry

            button.Visible = true
            button.LayoutOrder = index
            button.Position = UDim2.fromOffset(4, (index - 1) * rowHeight)
            button.Size = UDim2.new(1, -8, 0, rowHeight)
            button.TextSize = CurrentOptionTextSize

            UpdateEntry(entry)
        end
    end

    function Dropdown:BuildDropdownList(PrioritizeSelected)
        if not MenuState.Active then
            ClearDropdownList()
            Dropdown:Display()
            return
        end

        local query = SearchInput.Visible and (SearchInput.Text or ""):lower() or ""
        local orderedValues = BuildOrderedValues(query, PrioritizeSelected == true)
        local disabledLookup = {}

        for _, Value in pairs(Dropdown.DisabledValues or {}) do
            disabledLookup[ResolveOptionValue(Value)] = true
        end

        ClearDropdownList()

        if #orderedValues > VirtualDropdownThreshold then
            ListLayout.Parent = nil
            List.AutomaticCanvasSize = Enum.AutomaticSize.None

            VirtualState.Active = true
            VirtualState.Values = orderedValues
            VirtualState.DisabledLookup = disabledLookup
            VirtualState.RowCount = math.min(#orderedValues, math.max(8, math.floor((tonumber(Info.MaxVisibleDropdownItems) or 8) + VirtualDropdownBuffer)))
            VirtualState.LastFirstIndex = -1

            ApplyPopupLayout()
            List.CanvasSize = UDim2.fromOffset(0, math.ceil(#orderedValues * CurrentRowHeight))
            List.CanvasPosition = Vector2.zero
            RenderVirtualRows(true)
            Dropdown:Display()
            return
        end

        ListLayout.Parent = List
        List.AutomaticCanvasSize = Enum.AutomaticSize.Y

        for i = 1, #orderedValues do
            local Value = orderedValues[i]
            local IsDisabled = disabledLookup[Value] == true
            local Button = CreateDropdownButton(i)
            local Entry = {
                Button = Button,
                Value = Value,
                Disabled = IsDisabled,
            }

            Buttons[Button] = Entry
            UpdateEntry(Entry)
        end

        List.CanvasPosition = Vector2.zero
        ApplyPopupLayout()
        Dropdown:Display()
    end

    function Dropdown:BuildDropdownListNew()
        Dropdown:BuildDropdownList(true)
    end

    function Dropdown:RecalculateListSize(_)
    end

    function Dropdown:UpdateColors()
        if Library.Unloaded then
            return
        end

        Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
        Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
        ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or (MenuState.Active and 0 or 0.5)
        ArrowImage.Rotation = MenuState.Active and 180 or 0
    end

    function Dropdown:Display()
        if Library.Unloaded then
            return
        end

        local Str = ""

        if Info.Multi then
            local Parts = {}
            local SelectedCount = 0
            local DisplayLength = 0
            local MaxDisplayItems = math.clamp(Info.MaxDisplayItems or 10, 0, 10)
            local MaxDisplayCharacters = Info.MaxDisplayCharacters or 1200

            for _, Value in pairs(Dropdown.Values) do
                if Dropdown.Value[Value] then
                    SelectedCount = SelectedCount + 1

                    if #Parts < MaxDisplayItems then
                        local Text = tostring(GetDisplayText(Value))
                        local NextLength = DisplayLength + #Text + (#Parts > 0 and 2 or 0)

                        if NextLength <= MaxDisplayCharacters then
                            table.insert(Parts, Text)
                            DisplayLength = NextLength
                        end
                    end
                end
            end

            if SelectedCount == 0 then
                Str = ""
            elseif #Parts == SelectedCount then
                Str = table.concat(Parts, ", ")
            elseif #Parts == 0 then
                Str = tostring(SelectedCount) .. " selected"
            else
                Str = table.concat(Parts, ", ") .. " +" .. tostring(SelectedCount - #Parts) .. " more"
            end
        else
            if UseValueOptions then
                Str = Dropdown.Value ~= nil and tostring(GetDisplayText(Dropdown.Value)) or ""
            else
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end
        end

        Display.Text = (Str == "" and "---" or Str)
    end

    function Dropdown:OnChanged(Func)
        Dropdown.Changed = Func
    end

    function Dropdown:GetActiveValues()
        if Info.Multi then
            local Table = {}
            for Value, _ in pairs(Dropdown.Value) do
                table.insert(Table, Value)
            end
            return Table
        end
        if UseValueOptions then
            return Dropdown.Value ~= nil and 1 or 0
        end

        return Dropdown.Value and 1 or 0
    end

    function Dropdown:SetValue(Value, suppressCallback)
        if Info.Multi then
            local Table = {}

            for Val, Active in pairs(Value or {}) do
                if Active == true and ContainsValue(Val) then
                    Table[Val] = true
                elseif UseValueOptions and ContainsValue(Active) then
                    Table[Active] = true
                end
            end

            Dropdown.Value = Table
        else
            if ContainsValue(Value) then
                Dropdown.Value = Value
            elseif (UseValueOptions and Value == nil) or (not UseValueOptions and not Value) then
                Dropdown.Value = nil
            end
        end

        Dropdown:Display()
        RefreshButtons()

        if not Dropdown.Disabled then
            Library:UpdateDependencyBoxes()
            if not suppressCallback then
                Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            end
        end
    end

    function Dropdown:SetValues(Values)
        if UseValueOptions then
            local ValuesList, ValueOptions, OptionByValue, ValueLookup = NormalizeDropdownValues(Values)

            Dropdown.RawValues = Values or {}
            Dropdown.Values = ValuesList
            Dropdown.ValueOptions = ValueOptions
            Dropdown.OptionByValue = OptionByValue
            Dropdown.ValueLookup = ValueLookup

            if Info.Multi then
                for Value, _ in pairs(Dropdown.Value) do
                    if not ContainsValue(Value) then
                        Dropdown.Value[Value] = nil
                    end
                end
            elseif Dropdown.Value ~= nil and not ContainsValue(Dropdown.Value) then
                Dropdown.Value = nil
            end
        else
            Dropdown.Values = Values
        end

        Dropdown:BuildDropdownList(MenuState.Active)
    end

    function Dropdown:AddValues(Values)
        if UseValueOptions then
            if typeof(Dropdown.RawValues) ~= "table" then
                Dropdown.RawValues = {}
            end

            if typeof(Values) == "table" then
                for Key, Value in pairs(Values) do
                    if typeof(Key) == "number" then
                        table.insert(Dropdown.RawValues, Value)
                    else
                        Dropdown.RawValues[Key] = Value
                    end
                end
            elseif Values ~= nil then
                table.insert(Dropdown.RawValues, Values)
            else
                return
            end

            Dropdown:SetValues(Dropdown.RawValues)
            return
        end

        if typeof(Values) == "table" then
            for _, val in pairs(Values) do
                table.insert(Dropdown.Values, val)
            end
        elseif typeof(Values) == "string" then
            table.insert(Dropdown.Values, Values)
        else
            return
        end

        Dropdown:BuildDropdownList(MenuState.Active)
    end

    function Dropdown:SetDisabledValues(DisabledValues)
        Dropdown.DisabledValues = DisabledValues
        Dropdown:BuildDropdownList(MenuState.Active)
    end

    function Dropdown:AddDisabledValues(DisabledValues)
        if typeof(DisabledValues) == "table" then
            for _, val in pairs(DisabledValues) do
                table.insert(Dropdown.DisabledValues, val)
            end
        elseif typeof(DisabledValues) == "string" then
            table.insert(Dropdown.DisabledValues, DisabledValues)
        elseif UseValueOptions and DisabledValues ~= nil then
            table.insert(Dropdown.DisabledValues, DisabledValues)
        else
            return
        end

        Dropdown:BuildDropdownList(MenuState.Active)
    end

    function Dropdown:SetDisabled(Disabled: boolean)
        Dropdown.Disabled = Disabled

        if Dropdown.TooltipTable then
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end

        ClosePopup()
        Display.Active = not Dropdown.Disabled
        Dropdown:UpdateColors()
    end

    function Dropdown:SetVisible(Visible: boolean)
        Dropdown.Visible = Visible
        Holder.Visible = Dropdown.Visible
        Groupbox:Resize()
    end

    function Dropdown:SetText(Text: string)
        Dropdown.Text = Text
        Holder.Size = UDim2.new(1, 0, 0, (Text and 46 or 28) * Library.DPIScale)

        Label.Text = Text and Text or ""
        Label.Visible = not not Text
        Title.Text = Text or "Select"
    end

    -- function MenuState:Open_old()
    --     if MenuState.Active or Dropdown.Disabled then
    --         return
    --     end

    --     MenuState.Active = true
    --     ClickBlocker.Visible = true
    --     Popup.Visible = true
    --     Title.Text = Dropdown.Text or "Select"
    --     UpdateCloseButtonStyle()

    --     if SearchInput.Visible then
    --         SearchInput.Text = ""
    --     end

    --     Dropdown:BuildDropdownList(true)
    --     Dropdown:UpdateColors()
    -- end
    
    function MenuState:Open()
        if MenuState.Active or Dropdown.Disabled then
            return
        end
    
        if SearchInput.Visible and SearchInput.Text ~= "" then
            SearchInput.Text = ""
        end
    
        MenuState.Active = true
        ClickBlocker.Visible = true
        Popup.Visible = true
        Title.Text = Dropdown.Text or "Select"
        UpdateCloseButtonStyle()
    
        Dropdown:BuildDropdownList(true)
        Dropdown:UpdateColors()
    end

    function MenuState:Close()
        ClosePopup()
    end

    function MenuState:Toggle()
        if MenuState.Active then
            ClosePopup()
        else
            MenuState:Open()
        end
    end

    Display.MouseButton1Click:Connect(function()
        if Dropdown.Disabled then
            return
        end
        MenuState:Toggle()
    end)

    CloseButton.MouseButton1Click:Connect(ClosePopup)

    Library:GiveSignal(List:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if VirtualState.Active and RenderVirtualRows then
            RenderVirtualRows(false)
        end
    end))

    if SearchInput.Visible then
        SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
            Dropdown:BuildDropdownList(true)
        end)
    end

    if Library.ScreenGui then
        Library:GiveSignal(Library.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            ApplyPopupLayout()
        end))
    end

    pcall(function()
        Library:MakeDraggable(Popup, Header, false, true)
    end)

    pcall(function()
        Library:MakeResizable(Popup, ResizeHandle, function()
            local viewport = Library.ScreenGui and Library.ScreenGui.AbsoluteSize or Vector2.new(1280, 720)
            if viewport.X > 0 and viewport.Y > 0 then
                PopupScale.W = Popup.AbsoluteSize.X / viewport.X
                PopupScale.H = Popup.AbsoluteSize.Y / viewport.Y
            end
            ApplyPopupLayout()
        end)
    end)

    local Defaults = {}
    local function AddDefaultValue(Value)
        local Index = table.find(Dropdown.Values, Value)
        if Index then
            table.insert(Defaults, Index)
        end
    end

    if typeof(Info.Default) == "string" then
        AddDefaultValue(Info.Default)
    elseif typeof(Info.Default) == "table" then
        for Key, Value in next, Info.Default do
            if UseValueOptions and Value == true then
                AddDefaultValue(Key)
            elseif not (UseValueOptions and Value == false) then
                AddDefaultValue(Value)
            end
        end
    elseif Dropdown.Values[Info.Default] ~= nil then
        table.insert(Defaults, Info.Default)
    elseif UseValueOptions then
        AddDefaultValue(Info.Default)
    end

    if next(Defaults) then
        for i = 1, #Defaults do
            local Index = Defaults[i]
            if Info.Multi then
                Dropdown.Value[Dropdown.Values[Index]] = true
            else
                Dropdown.Value = Dropdown.Values[Index]
            end

            if not Info.Multi then
                break
            end
        end
    end

    if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
        Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
        Dropdown.TooltipTable.Disabled = Dropdown.Disabled
    end

    UpdateCloseButtonStyle()
    Dropdown.Menu = MenuState
    Dropdown:UpdateColors()
    Dropdown:Display()
    Dropdown:BuildDropdownList(false)
    ApplyPopupLayout()
    Groupbox:Resize()

    Dropdown.Holder = Holder
    table.insert(Groupbox.Elements, Dropdown)

    Options[Idx] = Dropdown
    return Dropdown
end

 

    
    function Funcs:AddDropdown(Idx, Info)
        Info = Library:Validate(Info, Templates.Dropdown)
    
        local Groupbox = self
        local Container = Groupbox.Container
    
        if Info.SpecialType == "Player" then
            Info.Values = GetPlayers(Info.ExcludeLocalPlayer)
            Info.AllowNull = true
        elseif Info.SpecialType == "Team" then
            Info.Values = GetTeams()
            Info.AllowNull = true
        end
    
        local Dropdown = {
            Text = typeof(Info.Text) == "string" and Info.Text or nil,
            Value = Info.Multi and {} or nil,
            Values = Info.Values,
            DisabledValues = Info.DisabledValues,
            Multi = Info.Multi,
    
            SpecialType = Info.SpecialType,
            ExcludeLocalPlayer = Info.ExcludeLocalPlayer,
    
            Tooltip = Info.Tooltip,
            DisabledTooltip = Info.DisabledTooltip,
            TooltipTable = nil,
    
            Callback = Info.Callback,
            Changed = Info.Changed,
    
            Disabled = Info.Disabled,
            Visible = Info.Visible,
    
            Type = "Dropdown",
        }
    
        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Dropdown.Text and 46 or 28),
            Visible = Dropdown.Visible,
            Parent = Container,
        })
    
        local Label = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            Text = Dropdown.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = not not Info.Text,
            Parent = Holder,
        })
    
        local Display = New("TextButton", {
            Active = not Dropdown.Disabled,
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 28),
            Text = "---",
            TextSize = 12,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = Holder,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius),
            Parent = Display,
        })
    
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 4),
            Parent = Display,
        })
    
        local ArrowImage = New("ImageLabel", {
            AnchorPoint = Vector2.new(1, 0.5),
            Image = ArrowIcon and ArrowIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ArrowIcon and ArrowIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ArrowIcon and ArrowIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(16, 16),
            Parent = Display,
        })
    
        local ClickBlocker = New("TextButton", {
            Active = true,
            AutoButtonColor = false,
            BackgroundColor3 = "Dark",
            BackgroundTransparency = 0.5, -- 50% dim
            BorderSizePixel = 0,
            Modal = true,
            Size = UDim2.fromScale(1, 1),
            Text = "",
            Visible = false,
            ZIndex = 119,
            Parent = Library.ScreenGui,
        })
    
        local Popup = New("Frame", {
            Active = true,
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(0.56, 0.76),
            Visible = false,
            ZIndex = 120,
            Parent = Library.ScreenGui,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 4),
            Parent = Popup,
        })
    
        New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1.2,
            Transparency = 0.15,
            Color = Library.Scheme.OutlineColor:Lerp(Library.Scheme.AccentColor, 0.28),
            Parent = Popup,
        })
    
        local PopupHeaderBg = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderSizePixel = 0,
            ZIndex = 120,
            Parent = Popup,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 4),
            Parent = PopupHeaderBg,
        })
    
        local PopupHeaderDivider = New("Frame", {
            BackgroundColor3 = "OutlineColor",
            BorderSizePixel = 0,
            ZIndex = 121,
            Parent = Popup,
        })
    
        local PopupBody = New("Frame", {
            BackgroundColor3 = "BackgroundColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            ZIndex = 121,
            Parent = Popup,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 2),
            Parent = PopupBody,
        })
    
        local Header = New("Frame", {
            Active = true,
            BackgroundTransparency = 1,
            ZIndex = 122,
            Parent = Popup,
        })
    
        local Title = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Dropdown.Text or "Select",
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 123,
            Parent = Header,
        })
    
        local CloseButton = New("TextButton", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Text = Info.Multi and "Done" or "Close",
            ZIndex = 123,
            Parent = Header,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 1),
            Parent = CloseButton,
        })
    
        local CloseButtonStroke = New("UIStroke", {
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Thickness = 1,
            Transparency = 0.25,
            Parent = CloseButton,
        })
    
        local SearchInput = New("TextBox", {
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            PlaceholderText = "Search items...",
            TextXAlignment = Enum.TextXAlignment.Left,
            Visible = Info.Searchable == true,
            ZIndex = 123,
            Parent = PopupBody,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 1),
            Parent = SearchInput,
        })
    
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 8),
            Parent = SearchInput,
        })
    
        local List = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            CanvasSize = UDim2.fromOffset(0, 0),
            ScrollBarImageColor3 = "OutlineColor",
            ScrollBarThickness = 4,
            TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
            ZIndex = 123,
            Parent = PopupBody,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, Library.CornerRadius + 1),
            Parent = List,
        })
    
        local ListLayout = New("UIListLayout", {
            Parent = List,
        })
    
        local ResizeHandle = New("TextButton", {
            AnchorPoint = Vector2.new(1, 1),
            AutoButtonColor = false,
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(1, 1),
            Size = UDim2.fromOffset(18, 18),
            Text = "",
            ZIndex = 124,
            Parent = Popup,
        })
    
        New("UICorner", {
            CornerRadius = UDim.new(0, 4),
            Parent = ResizeHandle,
        })
    
        local Buttons = {}
        local MenuState = { Active = false, Menu = Popup }
        local PopupScale = { W = 0.56, H = 0.76 }
        local CurrentRowHeight = 40
        local CurrentOptionTextSize = 14
        local RenderVirtualRows
        local VirtualState = {
            Active = false,
            Values = {},
            DisabledLookup = {},
            Rows = {},
            RowCount = 0,
            LastFirstIndex = -1,
        }
        local VirtualDropdownThreshold = tonumber(Info.VirtualDropdownThreshold) or 80
        local VirtualDropdownBuffer = tonumber(Info.VirtualDropdownBuffer) or 8
        
        local function ClearDropdownList()
            VirtualState.Active = false
            VirtualState.Values = {}
            VirtualState.DisabledLookup = {}
            VirtualState.RowCount = 0
            VirtualState.LastFirstIndex = -1

            for Button, _ in pairs(Buttons) do
                if Button then
                    Button:Destroy()
                end
            end
        
            table.clear(Buttons)
            table.clear(VirtualState.Rows)

            ListLayout.Parent = List
            List.AutomaticCanvasSize = Enum.AutomaticSize.Y
            List.CanvasSize = UDim2.fromOffset(0, 0)
            List.CanvasPosition = Vector2.zero
        end
    
        local function IsSelected(Value)
            if Info.Multi then
                return Dropdown.Value[Value] == true
            end
            return Dropdown.Value == Value
        end
    
        local function UpdateCloseButtonStyle()
            if Info.Multi then
                CloseButton.Text = "Done"
                CloseButton.BackgroundColor3 = Library.Scheme.AccentColor:Lerp(Library.Scheme.MainColor, 0.2)
                CloseButtonStroke.Color = Library.Scheme.AccentColor:Lerp(Library.Scheme.White, 0.2)
                CloseButtonStroke.Transparency = 0.2
            else
                CloseButton.Text = "Close"
                CloseButton.BackgroundColor3 = Library.Scheme.MainColor
                CloseButtonStroke.Color = Library.Scheme.OutlineColor
                CloseButtonStroke.Transparency = 0.35
            end
        end
    
        local function GetPopupMetrics()
            local viewport = Library.ScreenGui and Library.ScreenGui.AbsoluteSize or Vector2.new(1280, 720)
            local isPortrait = viewport.Y > viewport.X
    
            local minWScale = isPortrait and 0.78 or 0.42
            local maxWScale = isPortrait and 0.96 or 0.82
            local minHScale = isPortrait and 0.48 or 0.52
            local maxHScale = 0.90
    
            PopupScale.W = math.clamp(PopupScale.W, minWScale, maxWScale)
            PopupScale.H = math.clamp(PopupScale.H, minHScale, maxHScale)
    
            local width = viewport.X * PopupScale.W
            local height = viewport.Y * PopupScale.H
    
            local padX = width * 0.036
            local padY = height * 0.03
            local headerH = height * 0.08
            local searchH = height * 0.085
            local gap = height * 0.018
    
            local titleText = math.clamp(math.floor(height * 0.038), 13, 22)
            local inputText = math.clamp(math.floor(height * 0.031), 12, 18)
    
            -- ~10% smaller rows/buttons than previous
            local optionText = math.clamp(math.floor(height * 0.027), 12, 17)
            local rowH = math.clamp(height * 0.078, 30, 52)
    
            return {
                width = width,
                height = height,
                padX = padX,
                padY = padY,
                headerH = headerH,
                searchH = searchH,
                gap = gap,
                titleText = titleText,
                inputText = inputText,
                optionText = optionText,
                rowH = rowH,
            }
        end
    
        local function ApplyPopupLayout()
            local M = GetPopupMetrics()
            local closeH = math.floor(M.headerH * 0.72)
            local closeW = math.max(78, math.floor(closeH * 2.05))
            local bodyTop, innerPadX, innerPadY, listTop
    
            Popup.Size = UDim2.fromScale(PopupScale.W, PopupScale.H)
    
            Header.Position = UDim2.fromOffset(M.padX, M.padY)
            Header.Size = UDim2.new(1, -M.padX * 2, 0, M.headerH)
    
            Title.Position = UDim2.fromOffset(0, 0)
            Title.Size = UDim2.new(1, -(closeW + 12), 1, 0)
            Title.TextSize = M.titleText
    
            CloseButton.Size = UDim2.fromOffset(closeW, closeH)
            CloseButton.Position = UDim2.new(1, -closeW, 0.5, -math.floor(closeH / 2))
            CloseButton.TextSize = math.max(12, M.inputText - 1)
    
            PopupHeaderBg.Position = UDim2.fromOffset(0, 0)
            PopupHeaderBg.Size = UDim2.new(1, 0, 0, M.padY + M.headerH + M.gap * 0.65)
    
            PopupHeaderDivider.Position = UDim2.fromOffset(0, math.floor(M.padY + M.headerH + M.gap * 0.65))
            PopupHeaderDivider.Size = UDim2.new(1, 0, 0, 1)
    
            bodyTop = math.floor(M.padY + M.headerH + M.gap + 2)
            PopupBody.Position = UDim2.fromOffset(M.padX, bodyTop)
            PopupBody.Size = UDim2.new(1, -M.padX * 2, 1, -(bodyTop + M.padY))
    
            innerPadX = math.max(10, math.floor(M.padX * 0.7))
            innerPadY = math.max(10, math.floor(M.padY * 0.65))
    
            if SearchInput.Visible then
                SearchInput.Position = UDim2.fromOffset(innerPadX, innerPadY)
                SearchInput.Size = UDim2.new(1, -(innerPadX * 2), 0, M.searchH)
                SearchInput.TextSize = M.inputText
    
                listTop = innerPadY + M.searchH + M.gap
                List.Position = UDim2.fromOffset(innerPadX, listTop)
                List.Size = UDim2.new(1, -(innerPadX * 2), 1, -(listTop + innerPadY))
            else
                List.Position = UDim2.fromOffset(innerPadX, innerPadY)
                List.Size = UDim2.new(1, -(innerPadX * 2), 1, -(innerPadY * 2))
            end
    
            CurrentRowHeight = M.rowH
            CurrentOptionTextSize = M.optionText
            ListLayout.Padding = UDim.new(0, math.max(4, math.floor(M.gap * 0.45)))
    
            for _, Entry in pairs(Buttons) do
                Entry.Button.Size = UDim2.new(1, -8, 0, CurrentRowHeight)
                Entry.Button.TextSize = CurrentOptionTextSize
            end

            if RenderVirtualRows then
                RenderVirtualRows(true)
            end
        end
    
        local function UpdateEntry(Entry)
            local selected = IsSelected(Entry.Value)
    
            Entry.Button.BackgroundColor3 = Library.Scheme.MainColor:Lerp(Library.Scheme.AccentColor, 0.15)
            Entry.Button.BackgroundTransparency = selected and 0.5 or 1 
            Entry.Button.TextTransparency = Entry.Disabled and 0.8 or (selected and 0.04 or 0.45)
            Entry.Button.Text = tostring(Entry.Value)
        end
    
        local function RefreshButtons()
            for _, Entry in pairs(Buttons) do
                UpdateEntry(Entry)
            end
        end
    
        local function ClosePopup()
            if not MenuState.Active then
                return
            end
    
            MenuState.Active = false
            ClickBlocker.Visible = false
            Popup.Visible = false
            
            ClearDropdownList()
    
            if UserInputService:GetFocusedTextBox() == SearchInput then
                pcall(function()
                    SearchInput:ReleaseFocus()
                end)
            end
    
            Dropdown:UpdateColors()
        end
    
        local function BuildOrderedValues(Query: string, PrioritizeSelected: boolean)
            local Selected = {}
            local Unselected = {}
    
            for _, Value in pairs(Dropdown.Values or {}) do
                if Query ~= "" and not tostring(Value):lower():find(Query, 1, true) then
                    continue
                end
    
                if PrioritizeSelected and IsSelected(Value) then
                    table.insert(Selected, Value)
                else
                    table.insert(Unselected, Value)
                end
            end
    
            if not PrioritizeSelected then
                return Unselected
            end
    
            for i = 1, #Unselected do
                table.insert(Selected, Unselected[i])
            end
    
            return Selected
        end
    
        local function ApplySelection(Value)
            local wasSelected = IsSelected(Value)
            local nextSelected = not wasSelected
    
            if Dropdown:GetActiveValues() == 1 and not nextSelected and not Info.AllowNull then
                return
            end
    
            if Info.Multi then
                Dropdown.Value[Value] = nextSelected and true or nil
            else
                Dropdown.Value = nextSelected and Value or nil
            end
    
            Dropdown:Display()
            RefreshButtons()
    
            Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
            Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
            Library:UpdateDependencyBoxes()
    
            if not Info.Multi then
                ClosePopup()
            end
        end
    
        local function CreateDropdownButton(LayoutOrder)
            local Button = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 0,
                LayoutOrder = LayoutOrder or 0,
                Size = UDim2.new(1, -8, 0, CurrentRowHeight),
                Text = "",
                TextSize = CurrentOptionTextSize,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 123,
                Parent = List,
            })

            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius + 1),
                Parent = Button,
            })

            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 10),
                Parent = Button,
            })

            Button.MouseButton1Click:Connect(function()
                local Entry = Buttons[Button]
                if not Entry or Entry.Disabled or Dropdown.Disabled then
                    return
                end

                ApplySelection(Entry.Value)
            end)

            return Button
        end

        RenderVirtualRows = function(Force)
            if not MenuState.Active or not VirtualState.Active then
                return
            end

            local values = VirtualState.Values or {}
            local total = #values
            local rowHeight = math.max(CurrentRowHeight, 1)

            if total <= 0 then
                return
            end

            local firstIndex = math.floor((List.CanvasPosition.Y or 0) / rowHeight) + 1
            firstIndex = math.clamp(firstIndex, 1, total)

            if not Force and firstIndex == VirtualState.LastFirstIndex then
                return
            end

            VirtualState.LastFirstIndex = firstIndex

            for row = 1, VirtualState.RowCount do
                local button = VirtualState.Rows[row]

                if not button then
                    button = CreateDropdownButton(row)
                    button.AnchorPoint = Vector2.zero
                    VirtualState.Rows[row] = button
                end

                local index = firstIndex + row - 1
                local value = values[index]

                if value == nil then
                    Buttons[button] = nil
                    button.Visible = false
                    continue
                end

                local entry = Buttons[button] or { Button = button }
                entry.Value = value
                entry.Disabled = VirtualState.DisabledLookup[value] == true
                Buttons[button] = entry

                button.Visible = true
                button.LayoutOrder = index
                button.Position = UDim2.fromOffset(4, (index - 1) * rowHeight)
                button.Size = UDim2.new(1, -8, 0, rowHeight)
                button.TextSize = CurrentOptionTextSize

                UpdateEntry(entry)
            end
        end

        function Dropdown:BuildDropdownList(PrioritizeSelected)
            if not MenuState.Active then
                ClearDropdownList()
                Dropdown:Display()
                return
            end

            local query = SearchInput.Visible and (SearchInput.Text or ""):lower() or ""
            local orderedValues = BuildOrderedValues(query, PrioritizeSelected == true)
            local disabledLookup = {}
    
            for _, Value in pairs(Dropdown.DisabledValues or {}) do
                disabledLookup[Value] = true
            end
    
            ClearDropdownList()

            if #orderedValues > VirtualDropdownThreshold then
                ListLayout.Parent = nil
                List.AutomaticCanvasSize = Enum.AutomaticSize.None

                VirtualState.Active = true
                VirtualState.Values = orderedValues
                VirtualState.DisabledLookup = disabledLookup
                VirtualState.RowCount = math.min(#orderedValues, math.max(8, math.floor((tonumber(Info.MaxVisibleDropdownItems) or 8) + VirtualDropdownBuffer)))
                VirtualState.LastFirstIndex = -1

                ApplyPopupLayout()
                List.CanvasSize = UDim2.fromOffset(0, math.ceil(#orderedValues * CurrentRowHeight))
                List.CanvasPosition = Vector2.zero
                RenderVirtualRows(true)
                Dropdown:Display()
                return
            end

            ListLayout.Parent = List
            List.AutomaticCanvasSize = Enum.AutomaticSize.Y
    
            for i = 1, #orderedValues do
                local Value = orderedValues[i]
                local IsDisabled = disabledLookup[Value] == true
                local Button = CreateDropdownButton(i)
                local Entry = {
                    Button = Button,
                    Value = Value,
                    Disabled = IsDisabled,
                }
    
                Buttons[Button] = Entry
                UpdateEntry(Entry)
            end
    
            List.CanvasPosition = Vector2.zero
            ApplyPopupLayout()
            Dropdown:Display()
        end
    
        function Dropdown:BuildDropdownListNew()
            Dropdown:BuildDropdownList(true)
        end
    
        function Dropdown:RecalculateListSize(_)
        end
    
        function Dropdown:UpdateColors()
            if Library.Unloaded then
                return
            end
    
            Label.TextTransparency = Dropdown.Disabled and 0.8 or 0
            Display.TextTransparency = Dropdown.Disabled and 0.8 or 0
            ArrowImage.ImageTransparency = Dropdown.Disabled and 0.8 or (MenuState.Active and 0 or 0.5)
            ArrowImage.Rotation = MenuState.Active and 180 or 0
        end
    
        function Dropdown:Display()
            if Library.Unloaded then
                return
            end
    
            local Str = ""
    
            if Info.Multi then
                for _, Value in pairs(Dropdown.Values) do
                    if Dropdown.Value[Value] then
                        Str = Str .. (Info.FormatDisplayValue and tostring(Info.FormatDisplayValue(Value)) or tostring(Value)) .. ", "
                    end
                end
                Str = Str:sub(1, #Str - 2)
            else
                Str = Dropdown.Value and tostring(Dropdown.Value) or ""
                if Str ~= "" and Info.FormatDisplayValue then
                    Str = tostring(Info.FormatDisplayValue(Str))
                end
            end
    
            Display.Text = (Str == "" and "---" or Str)
        end
    
        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func
        end
    
        function Dropdown:GetActiveValues()
            if Info.Multi then
                local Table = {}
                for Value, _ in pairs(Dropdown.Value) do
                    table.insert(Table, Value)
                end
                return Table
            end
            return Dropdown.Value and 1 or 0
        end
    
        function Dropdown:SetValue(Value, suppressCallback)
            if Info.Multi then
                local Table = {}
    
                for Val, Active in pairs(Value or {}) do
                    if Active and table.find(Dropdown.Values, Val) then
                        Table[Val] = true
                    end
                end
    
                Dropdown.Value = Table
            else
                if table.find(Dropdown.Values, Value) then
                    Dropdown.Value = Value
                elseif not Value then
                    Dropdown.Value = nil
                end
            end
    
            Dropdown:Display()
            RefreshButtons()
    
            if not Dropdown.Disabled then
                Library:UpdateDependencyBoxes()
                if not suppressCallback then
                    Library:SafeCallback(Dropdown.Callback, Dropdown.Value)
                    Library:SafeCallback(Dropdown.Changed, Dropdown.Value)
                end
            end
        end
    
        function Dropdown:SetValues(Values)
            Dropdown.Values = Values
            Dropdown:BuildDropdownList(MenuState.Active)
        end
    
        function Dropdown:AddValues(Values)
            if typeof(Values) == "table" then
                for _, val in pairs(Values) do
                    table.insert(Dropdown.Values, val)
                end
            elseif typeof(Values) == "string" then
                table.insert(Dropdown.Values, Values)
            else
                return
            end
    
            Dropdown:BuildDropdownList(MenuState.Active)
        end
    
        function Dropdown:SetDisabledValues(DisabledValues)
            Dropdown.DisabledValues = DisabledValues
            Dropdown:BuildDropdownList(MenuState.Active)
        end
    
        function Dropdown:AddDisabledValues(DisabledValues)
            if typeof(DisabledValues) == "table" then
                for _, val in pairs(DisabledValues) do
                    table.insert(Dropdown.DisabledValues, val)
                end
            elseif typeof(DisabledValues) == "string" then
                table.insert(Dropdown.DisabledValues, DisabledValues)
            else
                return
            end
    
            Dropdown:BuildDropdownList(MenuState.Active)
        end
    
        function Dropdown:SetDisabled(Disabled: boolean)
            Dropdown.Disabled = Disabled
    
            if Dropdown.TooltipTable then
                Dropdown.TooltipTable.Disabled = Dropdown.Disabled
            end
    
            ClosePopup()
            Display.Active = not Dropdown.Disabled
            Dropdown:UpdateColors()
        end
    
        function Dropdown:SetVisible(Visible: boolean)
            Dropdown.Visible = Visible
            Holder.Visible = Dropdown.Visible
            Groupbox:Resize()
        end
    
        function Dropdown:SetText(Text: string)
            Dropdown.Text = Text
            Holder.Size = UDim2.new(1, 0, 0, (Text and 46 or 28) * Library.DPIScale)
    
            Label.Text = Text and Text or ""
            Label.Visible = not not Text
            Title.Text = Text or "Select"
        end
    
        -- function MenuState:Open_old()
        --     if MenuState.Active or Dropdown.Disabled then
        --         return
        --     end
    
        --     MenuState.Active = true
        --     ClickBlocker.Visible = true
        --     Popup.Visible = true
        --     Title.Text = Dropdown.Text or "Select"
        --     UpdateCloseButtonStyle()
    
        --     if SearchInput.Visible then
        --         SearchInput.Text = ""
        --     end
    
        --     Dropdown:BuildDropdownList(true)
        --     Dropdown:UpdateColors()
        -- end
        
        function MenuState:Open()
            if MenuState.Active or Dropdown.Disabled then
                return
            end
        
            if SearchInput.Visible and SearchInput.Text ~= "" then
                SearchInput.Text = ""
            end
        
            MenuState.Active = true
            ClickBlocker.Visible = true
            Popup.Visible = true
            Title.Text = Dropdown.Text or "Select"
            UpdateCloseButtonStyle()
        
            Dropdown:BuildDropdownList(true)
            Dropdown:UpdateColors()
        end
    
        function MenuState:Close()
            ClosePopup()
        end
    
        function MenuState:Toggle()
            if MenuState.Active then
                ClosePopup()
            else
                MenuState:Open()
            end
        end
    
        Display.MouseButton1Click:Connect(function()
            if Dropdown.Disabled then
                return
            end
            MenuState:Toggle()
        end)
    
        CloseButton.MouseButton1Click:Connect(ClosePopup)
    
        Library:GiveSignal(List:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if VirtualState.Active and RenderVirtualRows then
                RenderVirtualRows(false)
            end
        end))

        if SearchInput.Visible then
            SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
                Dropdown:BuildDropdownList(true)
            end)
        end
    
        if Library.ScreenGui then
            Library:GiveSignal(Library.ScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                ApplyPopupLayout()
            end))
        end
    
        pcall(function()
            Library:MakeDraggable(Popup, Header, false, true)
        end)
    
        pcall(function()
            Library:MakeResizable(Popup, ResizeHandle, function()
                local viewport = Library.ScreenGui and Library.ScreenGui.AbsoluteSize or Vector2.new(1280, 720)
                if viewport.X > 0 and viewport.Y > 0 then
                    PopupScale.W = Popup.AbsoluteSize.X / viewport.X
                    PopupScale.H = Popup.AbsoluteSize.Y / viewport.Y
                end
                ApplyPopupLayout()
            end)
        end)
    
        local Defaults = {}
        if typeof(Info.Default) == "string" then
            local Index = table.find(Dropdown.Values, Info.Default)
            if Index then
                table.insert(Defaults, Index)
            end
        elseif typeof(Info.Default) == "table" then
            for _, Value in next, Info.Default do
                local Index = table.find(Dropdown.Values, Value)
                if Index then
                    table.insert(Defaults, Index)
                end
            end
        elseif Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end
    
        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index]
                end
    
                if not Info.Multi then
                    break
                end
            end
        end
    
        if typeof(Dropdown.Tooltip) == "string" or typeof(Dropdown.DisabledTooltip) == "string" then
            Dropdown.TooltipTable = Library:AddTooltip(Dropdown.Tooltip, Dropdown.DisabledTooltip, Display)
            Dropdown.TooltipTable.Disabled = Dropdown.Disabled
        end
    
        UpdateCloseButtonStyle()
        Dropdown.Menu = MenuState
        Dropdown:UpdateColors()
        Dropdown:Display()
        Dropdown:BuildDropdownList(false)
        ApplyPopupLayout()
        Groupbox:Resize()
    
        Dropdown.Holder = Holder
        table.insert(Groupbox.Elements, Dropdown)
    
        Options[Idx] = Dropdown
        return Dropdown
    end
    

 
   

    function Funcs:AddViewport(Idx, Info)
        Info = Library:Validate(Info, Templates.Viewport)

        local Groupbox = self
        local Container = Groupbox.Container

        local Dragging, Pinching = false, false
        local LastMousePos, LastPinchDist = nil, 0

        local Viewport = {
            Object = if Info.Clone then Info.Object:Clone() else Info.Object,
            Camera = if not Info.Camera then Instance.new("Camera") else Info.Camera,
            Interactive = Info.Interactive,
            AutoFocus = Info.AutoFocus,
            Visible = Info.Visible,
            Type = "Viewport",
        }

        assert(
            typeof(Viewport.Object) == "Instance" and (Viewport.Object:IsA("BasePart") or Viewport.Object:IsA("Model")),
            "Instance must be a BasePart or Model."
        )

        assert(
            typeof(Viewport.Camera) == "Instance" and Viewport.Camera:IsA("Camera"),
            "Camera must be a valid Camera instance."
        )

        local function GetModelSize(model)
            if model:IsA("BasePart") then
                return model.Size
            end

            return select(2, model:GetBoundingBox())
        end

        local function FocusCamera()
            local ModelSize = GetModelSize(Viewport.Object)
            local MaxExtent = math.max(ModelSize.X, ModelSize.Y, ModelSize.Z)
            local CameraDistance = MaxExtent * 2
            local ModelPosition = Viewport.Object:GetPivot().Position

            Viewport.Camera.CFrame =
                CFrame.new(ModelPosition + Vector3.new(0, MaxExtent / 2, CameraDistance), ModelPosition)
        end

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Viewport.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ViewportFrame = New("ViewportFrame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Parent = Box,
            CurrentCamera = Viewport.Camera,
            Active = Viewport.Interactive,
        })

        ViewportFrame.MouseEnter:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = false
            end
        end)

        ViewportFrame.MouseLeave:Connect(function()
            if not Viewport.Interactive then
                return
            end

            for _, Side in pairs(Groupbox.Tab.Sides) do
                Side.ScrollingEnabled = true
            end
        end)

        ViewportFrame.InputBegan:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = true
                LastMousePos = input.Position
            elseif input.UserInputType == Enum.UserInputType.Touch and not Pinching then
                Dragging = true
                LastMousePos = input.Position
            end
        end)

        Library:GiveSignal(UserInputService.InputEnded:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                Dragging = false
            elseif input.UserInputType == Enum.UserInputType.Touch then
                Dragging = false
            end
        end))

        Library:GiveSignal(UserInputService.InputChanged:Connect(function(input)
            if not Viewport.Interactive or not Dragging or Pinching then
                return
            end

            if
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            then
                local MouseDelta = input.Position - LastMousePos
                LastMousePos = input.Position

                local Position = Viewport.Object:GetPivot().Position
                local Camera = Viewport.Camera

                local RotationY = CFrame.fromAxisAngle(Vector3.new(0, 1, 0), -MouseDelta.X * 0.01)
                Camera.CFrame = CFrame.new(Position) * RotationY * CFrame.new(-Position) * Camera.CFrame

                local RotationX = CFrame.fromAxisAngle(Camera.CFrame.RightVector, -MouseDelta.Y * 0.01)
                local PitchedCFrame = CFrame.new(Position) * RotationX * CFrame.new(-Position) * Camera.CFrame

                if PitchedCFrame.UpVector.Y > 0.1 then
                    Camera.CFrame = PitchedCFrame
                end
            end
        end))

        ViewportFrame.InputChanged:Connect(function(input)
            if not Viewport.Interactive then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseWheel then
                local ZoomAmount = input.Position.Z * 2
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * ZoomAmount
            end
        end)

        Library:GiveSignal(UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
            if not Viewport.Interactive or not Library:MouseIsOverFrame(ViewportFrame, touchPositions[1]) then
                return
            end

            if state == Enum.UserInputState.Begin then
                Pinching = true
                Dragging = false
                LastPinchDist = (touchPositions[1] - touchPositions[2]).Magnitude
            elseif state == Enum.UserInputState.Change then
                local currentDist = (touchPositions[1] - touchPositions[2]).Magnitude
                local delta = (currentDist - LastPinchDist) * 0.1
                LastPinchDist = currentDist
                Viewport.Camera.CFrame += Viewport.Camera.CFrame.LookVector * delta
            elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
                Pinching = false
            end
        end))

        Viewport.Object.Parent = ViewportFrame
        if Viewport.AutoFocus then
            FocusCamera()
        end

        function Viewport:SetObject(Object: Instance, Clone: boolean?)
            assert(Object, "Object cannot be nil.")

            if Clone then
                Object = Object:Clone()
            end

            if Viewport.Object then
                Viewport.Object:Destroy()
            end

            Viewport.Object = Object
            Viewport.Object.Parent = ViewportFrame

            Groupbox:Resize()
        end

        function Viewport:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Viewport:Focus()
            if not Viewport.Object then
                return
            end

            FocusCamera()
        end

        function Viewport:SetCamera(Camera: Instance)
            assert(
                Camera and typeof(Camera) == "Instance" and Camera:IsA("Camera"),
                "Camera must be a valid Camera instance."
            )

            Viewport.Camera = Camera
            ViewportFrame.CurrentCamera = Camera
        end

        function Viewport:SetInteractive(Interactive: boolean)
            Viewport.Interactive = Interactive
            ViewportFrame.Active = Interactive
        end

        function Viewport:SetVisible(Visible: boolean)
            Viewport.Visible = Visible

            Holder.Visible = Viewport.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Viewport.Holder = Holder
        table.insert(Groupbox.Elements, Viewport)

        Options[Idx] = Viewport

        return Viewport
    end

    function Funcs:AddImage(Idx, Info)
        Info = Library:Validate(Info, Templates.Image)

        local Groupbox = self
        local Container = Groupbox.Container

        local Image = {
            Image = Info.Image,
            Color = Info.Color,
            RectOffset = Info.RectOffset,
            RectSize = Info.RectSize,
            Height = Info.Height,
            ScaleType = Info.ScaleType,
            Transparency = Info.Transparency,

            Visible = Info.Visible,
            Type = "Image",
        }

        local Holder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, Info.Height),
            Visible = Image.Visible,
            Parent = Container,
        })

        local Box = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = "MainColor",
            BorderColor3 = "OutlineColor",
            BorderSizePixel = 1,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.fromScale(1, 1),
            Parent = Holder,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 3),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 4),
            Parent = Box,
        })

        local ImageProperties = {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Image = Image.Image,
            ImageTransparency = Image.Transparency,
            ImageColor3 = Image.Color,
            ImageRectOffset = Image.RectOffset,
            ImageRectSize = Image.RectSize,
            ScaleType = Image.ScaleType,
            Parent = Box,
        }

        if
            not (
                ImageProperties.Image:match("rbxasset")
                or ImageProperties.Image:match("roblox%.com/asset/%?id=")
                or ImageProperties.Image:match("rbxthumb://type=AvatarHeadShot")
            )
        then
            local Icon = Library:GetIcon(ImageProperties.Image)
            assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

            ImageProperties.Image = Icon.Url
            ImageProperties.ImageRectOffset = Icon.ImageRectOffset
            ImageProperties.ImageRectSize = Icon.ImageRectSize
        end

        local ImageLabel = New("ImageLabel", ImageProperties)

        function Image:SetHeight(Height: number)
            assert(Height > 0, "Height must be greater than 0.")

            Image.Height = Height
            Holder.Size = UDim2.new(1, 0, 0, Height)
            Groupbox:Resize()
        end

        function Image:SetImage(NewImage: string)
            assert(typeof(NewImage) == "string", "Image must be a string.")

            if
                not (
                    NewImage:match("rbxasset")
                    or NewImage:match("roblox%.com/asset/%?id=")
                    or NewImage:match("rbxthumb://type=AvatarHeadShot")
                )
            then
                local Icon = Library:GetIcon(NewImage)
                assert(Icon, "Image must be a valid Roblox asset or a valid URL or a valid lucide icon.")

                NewImage = Icon.Url
                Image.RectOffset = Icon.ImageRectOffset
                Image.RectSize = Icon.ImageRectSize
            end

            ImageLabel.Image = NewImage
            Image.Image = NewImage
        end

        function Image:SetColor(Color: Color3)
            assert(typeof(Color) == "Color3", "Color must be a Color3 value.")

            ImageLabel.ImageColor3 = Color
            Image.Color = Color
        end

        function Image:SetRectOffset(RectOffset: Vector2)
            assert(typeof(RectOffset) == "Vector2", "RectOffset must be a Vector2 value.")

            ImageLabel.ImageRectOffset = RectOffset
            Image.RectOffset = RectOffset
        end

        function Image:SetRectSize(RectSize: Vector2)
            assert(typeof(RectSize) == "Vector2", "RectSize must be a Vector2 value.")

            ImageLabel.ImageRectSize = RectSize
            Image.RectSize = RectSize
        end

        function Image:SetScaleType(ScaleType: Enum.ScaleType)
            assert(
                typeof(ScaleType) == "EnumItem" and ScaleType:IsA("ScaleType"),
                "ScaleType must be a valid Enum.ScaleType."
            )

            ImageLabel.ScaleType = ScaleType
            Image.ScaleType = ScaleType
        end

        function Image:SetTransparency(Transparency: number)
            assert(typeof(Transparency) == "number", "Transparency must be a number between 0 and 1.")
            assert(Transparency >= 0 and Transparency <= 1, "Transparency must be between 0 and 1.")

            ImageLabel.ImageTransparency = Transparency
            Image.Transparency = Transparency
        end

        function Image:SetVisible(Visible: boolean)
            Image.Visible = Visible

            Holder.Visible = Image.Visible
            Groupbox:Resize()
        end

        Groupbox:Resize()

        Image.Holder = Holder
        table.insert(Groupbox.Elements, Image)

        Options[Idx] = Image

        return Image
    end

    function Funcs:AddDependencyBox()
        local Groupbox = self
        local Container = Groupbox.Container

        local DepboxContainer
        local DepboxList

        do
            DepboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            DepboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepboxContainer,
            })
        end

        local Depbox = {
            Visible = false,
            Dependencies = {},

            Holder = DepboxContainer,
            Container = DepboxContainer,

            Elements = {},
            DependencyBoxes = {},
        }

        function Depbox:Resize()
            DepboxContainer.Size = UDim2.new(1, 0, 0, DepboxList.AbsoluteContentSize.Y * Library.DPIScale)
            Groupbox:Resize()
        end

        function Depbox:Update(CancelSearch)
            for _, Dependency in pairs(Depbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    DepboxContainer.Visible = false
                    Depbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            DepboxContainer.Visible = false
                            Depbox.Visible = false
                            return
                        end
                    end
                end
            end

            Depbox.Visible = true
            DepboxContainer.Visible = true
            if not Library.Searching then
                Depbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Depbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            Depbox.Dependencies = Dependencies
            Depbox:Update()
        end

        DepboxContainer:GetPropertyChangedSignal("Visible"):Connect(function()
            Depbox:Resize()
        end)

        setmetatable(Depbox, BaseGroupbox)

        table.insert(Groupbox.DependencyBoxes, Depbox)
        table.insert(Library.DependencyBoxes, Depbox)

        return Depbox
    end

    function Funcs:AddDependencyGroupbox()
        local Groupbox = self
        local Tab = Groupbox.Tab
        local BoxHolder = Groupbox.BoxHolder

        local Background = Library:MakeOutline(BoxHolder, Library.CornerRadius)
        Background.Size = UDim2.fromScale(1, 0)
        Background.Visible = false
        Library:UpdateDPI(Background, {
            Size = false,
        })

        local DepGroupboxContainer
        local DepGroupboxList

        do
            DepGroupboxContainer = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Background,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, Library.CornerRadius - 1),
                Parent = DepGroupboxContainer,
            })

            DepGroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = DepGroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = DepGroupboxContainer,
            })
        end

        local DepGroupbox = {
            Visible = false,
            Dependencies = {},

            BoxHolder = BoxHolder,
            Holder = Background,
            Container = DepGroupboxContainer,

            Tab = Tab,
            Elements = {},
            DependencyBoxes = {},
        }

        function DepGroupbox:Resize()
            Background.Size = UDim2.new(1, 0, 0, DepGroupboxList.AbsoluteContentSize.Y + 18 * Library.DPIScale)
        end

        function DepGroupbox:Update(CancelSearch)
            for _, Dependency in pairs(DepGroupbox.Dependencies) do
                local Element = Dependency[1]
                local Value = Dependency[2]

                if Element.Type == "Toggle" and Element.Value ~= Value then
                    Background.Visible = false
                    DepGroupbox.Visible = false
                    return
                elseif Element.Type == "Dropdown" then
                    if typeof(Element.Value) == "table" then
                        if not Element.Value[Value] then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    else
                        if Element.Value ~= Value then
                            Background.Visible = false
                            DepGroupbox.Visible = false
                            return
                        end
                    end
                end
            end

            DepGroupbox.Visible = true
            if not Library.Searching then
                Background.Visible = true
                DepGroupbox:Resize()
            elseif not CancelSearch then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function DepGroupbox:SetupDependencies(Dependencies)
            for _, Dependency in pairs(Dependencies) do
                assert(typeof(Dependency) == "table", "Dependency should be a table.")
                assert(Dependency[1] ~= nil, "Dependency is missing element.")
                assert(Dependency[2] ~= nil, "Dependency is missing expected value.")
            end

            DepGroupbox.Dependencies = Dependencies
            DepGroupbox:Update()
        end

        setmetatable(DepGroupbox, BaseGroupbox)

        table.insert(Tab.DependencyGroupboxes, DepGroupbox)
        table.insert(Library.DependencyBoxes, DepGroupbox)

        return DepGroupbox
    end

    BaseGroupbox.__index = Funcs
    BaseGroupbox.__namecall = function(_, Key, ...)
        return Funcs[Key](...)
    end
end

function Library:SetFont(FontFace)
    if typeof(FontFace) == "EnumItem" then
        FontFace = Font.fromEnum(FontFace)
    end

    Library.Scheme.Font = FontFace
    Library:UpdateColorsUsingRegistry()
end

function Library:SetNotifySide(Side: string)
    Library.NotifySide = Side

    if Side:lower() == "left" then
        NotificationArea.AnchorPoint = Vector2.new(0, 0)
        NotificationArea.Position = UDim2.fromOffset(6, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    else
        NotificationArea.AnchorPoint = Vector2.new(1, 0)
        NotificationArea.Position = UDim2.new(1, -6, 0, 6)
        NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    end
end

function Library:Notify(...)
    local Data = {}
    local Info = select(1, ...)

    if typeof(Info) == "table" then
        Data.Title = tostring(Info.Title)
        Data.Description = tostring(Info.Description)
        Data.Time = Info.Time or 5
        Data.SoundId = Info.SoundId
        Data.Steps = Info.Steps
        Data.Persist = Info.Persist
    else
        Data.Description = tostring(Info)
        Data.Time = select(2, ...) or 5
        Data.SoundId = select(3, ...)
    end
    Data.Destroyed = false

    local DeletedInstance = false
    local DeleteConnection = nil
    if typeof(Data.Time) == "Instance" then
        DeleteConnection = Data.Time.Destroying:Connect(function()
            DeletedInstance = true

            DeleteConnection:Disconnect()
            DeleteConnection = nil
        end)
    end

    local FakeBackground = New("Frame", {
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 0),
        Visible = false,
        Parent = NotificationArea,

        DPIExclude = {
            Size = true,
        },
    })

    local Background = Library:MakeOutline(FakeBackground, Library.CornerRadius, 5)
    Background.AutomaticSize = Enum.AutomaticSize.Y
    Background.Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2)
    Background.Size = UDim2.fromScale(1, 0)
    Library:UpdateDPI(Background, {
        Position = false,
        Size = false,
    })

    local Holder = New("Frame", {
        BackgroundColor3 = "MainColor",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        Parent = Background,
    })
    New("UICorner", {
        CornerRadius = UDim.new(0, Library.CornerRadius - 1),
        Parent = Holder,
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 4),
        Parent = Holder,
    })
    New("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        Parent = Holder,
    })

    local Title
    local Desc
    local TitleX = 0
    local DescX = 0

    local TimerFill

    if Data.Title then
        Title = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Title,
            TextSize = 15,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    if Data.Description then
        Desc = New("TextLabel", {
            BackgroundTransparency = 1,
            Text = Data.Description,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
            Parent = Holder,

            DPIExclude = {
                Size = true,
            },
        })
    end

    function Data:Resize()
        if Title then
            local X, Y = Library:GetTextBounds(
                Title.Text,
                Title.FontFace,
                Title.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Title.Size = UDim2.fromOffset(math.ceil(X), Y)
            TitleX = X
        end

        if Desc then
            local X, Y = Library:GetTextBounds(
                Desc.Text,
                Desc.FontFace,
                Desc.TextSize,
                NotificationArea.AbsoluteSize.X - (24 * Library.DPIScale)
            )
            Desc.Size = UDim2.fromOffset(math.ceil(X), Y)
            DescX = X
        end

        FakeBackground.Size = UDim2.fromOffset((TitleX > DescX and TitleX or DescX) + (24 * Library.DPIScale), 0)
    end

    function Data:ChangeTitle(NewText)
        if Title then
            Data.Title = tostring(NewText)
            Title.Text = Data.Title
            Data:Resize()
        end
    end

    function Data:ChangeDescription(NewText)
        if Desc then
            Data.Description = tostring(NewText)
            Desc.Text = Data.Description
            Data:Resize()
        end
    end

    function Data:ChangeStep(NewStep)
        if TimerFill and Data.Steps then
            NewStep = math.clamp(NewStep or 0, 0, Data.Steps)
            TimerFill.Size = UDim2.fromScale(NewStep / Data.Steps, 1)
        end
    end

    function Data:Destroy()
        Data.Destroyed = true
        if DeleteConnection then
            DeleteConnection:Disconnect()
        end

        TweenService
            :Create(Background, Library.NotifyTweenInfo, {
                Position = Library.NotifySide:lower() == "left" and UDim2.new(-1, -6, 0, -2) or UDim2.new(1, 6, 0, -2),
            })
            :Play()
        task.delay(Library.NotifyTweenInfo.Time, function()
            Library.Notifications[FakeBackground] = nil
            FakeBackground:Destroy()
        end)
    end

    Data:Resize()

    local TimerHolder = New("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 7),
        Visible = (Data.Persist ~= true and typeof(Data.Time) ~= "Instance") or typeof(Data.Steps) == "number",
        Parent = Holder,
    })
    local TimerBar = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BorderColor3 = "OutlineColor",
        BorderSizePixel = 1,
        Position = UDim2.fromOffset(0, 3),
        Size = UDim2.new(1, 0, 0, 2),
        Parent = TimerHolder,
    })
    TimerFill = New("Frame", {
        BackgroundColor3 = "AccentColor",
        Size = UDim2.fromScale(1, 1),
        Parent = TimerBar,
    })

    if typeof(Data.Time) == "Instance" then
        TimerFill.Size = UDim2.fromScale(0, 1)
    end
    if Data.SoundId then
        local SoundId = Data.SoundId
        if typeof(SoundId) == "number" then
            SoundId = `rbxassetid://{SoundId}`
        end

        New("Sound", {
            SoundId = SoundId,
            Volume = 3,
            PlayOnRemove = true,
            Parent = SoundService,
        }):Destroy()
    end

    Library.Notifications[FakeBackground] = Data

    FakeBackground.Visible = true
    TweenService:Create(Background, Library.NotifyTweenInfo, {
        Position = UDim2.fromOffset(-2, -2),
    }):Play()

    task.delay(Library.NotifyTweenInfo.Time, function()
        if Data.Persist then
            return
        elseif typeof(Data.Time) == "Instance" then
            repeat
                task.wait()
            until DeletedInstance or Data.Destroyed
        else
            TweenService
                :Create(TimerFill, TweenInfo.new(Data.Time, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
                    Size = UDim2.fromScale(0, 1),
                })
                :Play()
            task.wait(Data.Time)
        end

        if not Data.Destroyed then
            Data:Destroy()
        end
    end)

    return Data
end

function Library:CreateWindow(WindowInfo)
    WindowInfo = Library:Validate(WindowInfo, Templates.Window)
    local ViewportSize: Vector2 = workspace.CurrentCamera.ViewportSize
    if RunService:IsStudio() and ViewportSize.X <= 5 and ViewportSize.Y <= 5 then
        repeat
            ViewportSize = workspace.CurrentCamera.ViewportSize
            task.wait()
        until ViewportSize.X > 5 and ViewportSize.Y > 5
    end

    local MaxX = ViewportSize.X - 64
    local MaxY = ViewportSize.Y - 64

    Library.MinSize = Vector2.new(math.min(Library.MinSize.X, MaxX), math.min(Library.MinSize.Y, MaxY))
    WindowInfo.Size = UDim2.fromOffset(
        math.clamp(WindowInfo.Size.X.Offset, Library.MinSize.X, MaxX),
        math.clamp(WindowInfo.Size.Y.Offset, Library.MinSize.Y, MaxY)
    )
    if typeof(WindowInfo.Font) == "EnumItem" then
        WindowInfo.Font = Font.fromEnum(WindowInfo.Font)
    end

    Library.CornerRadius = WindowInfo.CornerRadius
   -- Library:SetNotifySide(WindowInfo.NotifySide)
    
    local notifySideOk, notifySideErr = pcall(function()
        Library:SetNotifySide(WindowInfo.NotifySide)
    end)
    
    if not notifySideOk then
        warn("[EXO UI] SetNotifySide failed:", notifySideErr)
    end
    
    Library.ShowCustomCursor = WindowInfo.ShowCustomCursor
    Library.Scheme.Font = WindowInfo.Font
    Library.ToggleKeybind = WindowInfo.ToggleKeybind

    local IsDefaultSearchbarSize = WindowInfo.SearchbarSize == UDim2.fromScale(1, 1)
    local MainFrame
    local SearchHolder
    local SearchBox
    local SearchStroke
    local SearchClearButton
    local SearchResultButton
    local GlobalSearchMatches = {}
    local GlobalSearchIndex = 0
    local CurrentTabInfo
    local CurrentTabLabel
    local CurrentTabDescription
    local ResizeButton
    local Tabs
    local Container
    local FooterLabel
    do
        Library.KeybindFrame, Library.KeybindContainer = Library:AddDraggableMenu("Keybinds")
        Library.KeybindFrame.AnchorPoint = Vector2.new(0, 0.5)
        Library.KeybindFrame.Position = UDim2.new(0, 6, 0.5, 0)
        Library.KeybindFrame.Visible = false
        Library:UpdateDPI(Library.KeybindFrame, {
            Position = false,
            Size = false,
        })

        MainFrame = New("Frame", { 
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, -1)
            end,
            Name = "Main",
            Position = WindowInfo.Position,
            Size = WindowInfo.Size,
            Visible = false,
            Active = true, -- added
            Parent = ScreenGui,

            DPIExclude = {
                Position = true,
            },
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = MainFrame,
        })
        do
            local Lines = {
                {
                    Position = UDim2.fromOffset(0, 48),
                    Size = UDim2.new(1, 0, 0, 1),
                },
                {
                    Position = UDim2.fromScale(0.3, 0),
                    Size = UDim2.new(0, 1, 1, -21),
                },
                {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, -20),
                    Size = UDim2.new(1, 0, 0, 1),
                },
            }
            for _, Info in pairs(Lines) do
                Library:MakeLine(MainFrame, Info)
            end
            Library:MakeOutline(MainFrame, WindowInfo.CornerRadius, 0)
        end

        if WindowInfo.BackgroundImage then
            New("ImageLabel", {
                Image = WindowInfo.BackgroundImage,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                ScaleType = Enum.ScaleType.Stretch,
                ZIndex = 999,
                BackgroundTransparency = 1,
                ImageTransparency = 0.75,
                Parent = MainFrame,
            })
        end

        if WindowInfo.Center then
            MainFrame.Position = UDim2.new(0.5, -MainFrame.Size.X.Offset / 2, 0.5, -MainFrame.Size.Y.Offset / 2)
        end

        --// Top Bar \\-
        local TopBar = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 48),
            Parent = MainFrame,
        })
        Library:MakeDraggable(MainFrame, TopBar, false, true)

        --// Title
        local TitleHolder = New("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(0.3, 1),
            Parent = TopBar,
        })
        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            Parent = TitleHolder,
        })

        if WindowInfo.Icon then
            New("ImageLabel", {
                Image = if tonumber(WindowInfo.Icon) then `rbxassetid://{WindowInfo.Icon}` else WindowInfo.Icon,
                Size = WindowInfo.IconSize,
                Parent = TitleHolder,
            })
        end

        local X = Library:GetTextBounds(
            WindowInfo.Title,
            Library.Scheme.Font,
            20,
            TitleHolder.AbsoluteSize.X - (WindowInfo.Icon and WindowInfo.IconSize.X.Offset + 6 or 0) - 12
        )
        New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, X, 1, 0),
            Text = WindowInfo.Title,
            TextSize = 20,
            Parent = TitleHolder,
        })

        --// Top Right Bar
        local RightWrapper = New("Frame", {
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0.3, 8, 0.5, 0),
            Size = UDim2.new(0.7, -57, 1, -16),
            Parent = TopBar,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 8),
            Parent = RightWrapper,
        })

        CurrentTabInfo = New("Frame", {
            Size = UDim2.fromScale(WindowInfo.DisableSearch and 1 or 0.5, 1),
            Visible = false,
            BackgroundTransparency = 1,
            Parent = RightWrapper,
        })

        New("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Parent = CurrentTabInfo,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 8),
            Parent = CurrentTabInfo,
        })

        CurrentTabLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = CurrentTabInfo,
        })

        CurrentTabDescription = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            Text = "",
            TextWrapped = true,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTransparency = 0.5,
            Parent = CurrentTabInfo,
        })

        SearchHolder = New("Frame", {
            BackgroundColor3 = "MainColor",
            Size = WindowInfo.SearchbarSize,
            Visible = not (WindowInfo.DisableSearch or false),
            Parent = RightWrapper,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, math.max(WindowInfo.CornerRadius + 4, 8)),
            Parent = SearchHolder,
        })
        SearchStroke = New("UIStroke", {
            Color = "OutlineColor",
            Thickness = 1,
            Transparency = 0.15,
            Parent = SearchHolder,
        })

        local SearchIcon = Library:GetIcon("search")
        if SearchIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0, 0.5),
                Image = SearchIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchIcon.ImageRectOffset,
                ImageRectSize = SearchIcon.ImageRectSize,
                ImageTransparency = 0.45,
                Position = UDim2.new(0, 11, 0.5, 0),
                Size = UDim2.fromOffset(16, 16),
                Parent = SearchHolder,
            })
        end

        SearchBox = New("TextBox", {
            BackgroundTransparency = 1,
            ClearTextOnFocus = false,
            PlaceholderText = "Search all settings...",
            Position = UDim2.fromOffset(36, 0),
            Size = UDim2.new(1, -116, 1, 0),
            TextScaled = false,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = SearchHolder,
        })

        SearchResultButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.MainColor, 4)
            end,
            Position = UDim2.new(1, -35, 0.5, 0),
            Size = UDim2.fromOffset(42, 22),
            Text = "",
            TextSize = 12,
            Visible = false,
            Parent = SearchHolder,
        })
        New("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = SearchResultButton,
        })

        SearchClearButton = New("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(20, 20),
            Text = "×",
            TextSize = 18,
            TextTransparency = 0.35,
            Visible = false,
            Parent = SearchHolder,
        })

        local SearchClearIcon = Library:GetIcon("x")
        if SearchClearIcon then
            SearchClearButton.Text = ""
            New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Image = SearchClearIcon.Url,
                ImageColor3 = "FontColor",
                ImageRectOffset = SearchClearIcon.ImageRectOffset,
                ImageRectSize = SearchClearIcon.ImageRectSize,
                ImageTransparency = 0.35,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(13, 13),
                Parent = SearchClearButton,
            })
        end

        local MoveIcon = Library:GetIcon("move")
        if MoveIcon then
            New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                Image = MoveIcon.Url,
                ImageColor3 = "OutlineColor",
                ImageRectOffset = MoveIcon.ImageRectOffset,
                ImageRectSize = MoveIcon.ImageRectSize,
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(28, 28),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Parent = TopBar,
            })
        end

        --// Bottom Bar \\--
        local BottomBar = New("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
            end,
            Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 20),
            Parent = MainFrame,
        })
        do
            local Cover = Library:MakeCover(BottomBar, "Top")
            Library:AddToRegistry(Cover, {
                BackgroundColor3 = function()
                    return Library:GetBetterColor(Library.Scheme.BackgroundColor, 4)
                end,
            })
        end
        New("UICorner", {
            CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
            Parent = BottomBar,
        })

        --// Footer
        FooterLabel = New("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            Text = WindowInfo.Footer,
            TextSize = 14,
            TextTransparency = 0.5,
            Parent = BottomBar,
        })

        --// Resize Button
        if WindowInfo.Resizable then
            ResizeButton = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundTransparency = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.fromScale(1, 1),
                SizeConstraint = Enum.SizeConstraint.RelativeYY,
                Text = "",
                Parent = BottomBar,
            })

            Library:MakeResizable(MainFrame, ResizeButton, function()
                for _, Tab in pairs(Library.Tabs) do
                    Tab:Resize(true)
                end
            end)
        end

        New("ImageLabel", {
            Image = ResizeIcon and ResizeIcon.Url or "",
            ImageColor3 = "FontColor",
            ImageRectOffset = ResizeIcon and ResizeIcon.ImageRectOffset or Vector2.zero,
            ImageRectSize = ResizeIcon and ResizeIcon.ImageRectSize or Vector2.zero,
            ImageTransparency = 0.5,
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 1, -4),
            Parent = ResizeButton,
        })

        --// Tabs \\--
        Tabs = New("ScrollingFrame", {
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = "BackgroundColor",
            CanvasSize = UDim2.fromScale(0, 0),
            Position = UDim2.fromOffset(0, 49),
            ScrollBarThickness = 0,
            Size = UDim2.new(0.3, 0, 1, -70),
            Parent = MainFrame,
        })

        New("UIListLayout", {
            Parent = Tabs,
        })
 
        --// Container \\--
        Container = New("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            BackgroundColor3 = function()
                return Library:GetBetterColor(Library.Scheme.BackgroundColor, 1)
            end,
            Name = "Container",
            Position = UDim2.new(1, 0, 0, 49),
            Size = UDim2.new(0.7, -1, 1, -70),
            Parent = MainFrame,
        })

        New("UIPadding", {
            PaddingBottom = UDim.new(0, 0),
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 0),
            Parent = Container,
        })
    end

    --// Window Table \\--
    local Window = {}

    local function SearchBoxContainsMatch(Box, Search)
        for _, ElementInfo in pairs(Box.Elements or {}) do
            if ElementInfo.Type ~= "Divider" and ElementInfo.Visible ~= false then
                if SearchElementMatches(ElementInfo.Text, Search) then
                    return true
                end
                if ElementInfo.SubButton
                    and ElementInfo.SubButton.Visible ~= false
                    and SearchElementMatches(ElementInfo.SubButton.Text, Search)
                then
                    return true
                end
            end
        end

        for _, Depbox in pairs(Box.DependencyBoxes or {}) do
            if Depbox.Visible ~= false and SearchBoxContainsMatch(Depbox, Search) then
                return true
            end
        end

        return false
    end

    local function TabContainsGlobalSearchMatch(Tab, Search)
        for _, Groupbox in pairs(Tab.Groupboxes or {}) do
            if SearchBoxContainsMatch(Groupbox, Search) then
                return true
            end
        end

        for _, Tabbox in pairs(Tab.Tabboxes or {}) do
            for _, SubTab in pairs(Tabbox.Tabs or {}) do
                if SearchBoxContainsMatch(SubTab, Search) then
                    return true
                end
            end
        end

        for _, Groupbox in pairs(Tab.DependencyGroupboxes or {}) do
            if Groupbox.Visible ~= false and SearchBoxContainsMatch(Groupbox, Search) then
                return true
            end
        end

        return false
    end

    local function ShowGlobalSearchMatch(MatchIndex)
        local MatchCount = #GlobalSearchMatches
        if MatchCount == 0 then
            GlobalSearchIndex = 0
            SearchResultButton.Text = "0"
            return false
        end

        GlobalSearchIndex = ((MatchIndex - 1) % MatchCount) + 1
        local Match = GlobalSearchMatches[GlobalSearchIndex]
        SearchResultButton.Text = string.format("%d/%d", GlobalSearchIndex, MatchCount)

        if Match.Tab ~= Library.ActiveTab then
            local SearchWasActive = Library.Searching
            Match.Tab:Show()
            if not SearchWasActive then
                Library:UpdateSearch(SearchBox.Text)
            end
        else
            Library:UpdateSearch(SearchBox.Text)
        end

        return true
    end

    local function UpdateGlobalSearch(SearchText)
        local Search = Trim(tostring(SearchText or "")):lower()
        local HasSearch = Search ~= ""
        SearchClearButton.Visible = HasSearch
        SearchResultButton.Visible = HasSearch

        if not HasSearch then
            GlobalSearchMatches = {}
            GlobalSearchIndex = 0
            SearchResultButton.Text = ""
            return
        end

        local Matches = {}
        for TabName, Tab in pairs(Library.Tabs) do
            if not Tab.IsKeyTab and TabContainsGlobalSearchMatch(Tab, Search) then
                Matches[#Matches + 1] = {
                    Name = tostring(TabName),
                    Tab = Tab,
                }
            end
        end

        table.sort(Matches, function(LeftMatch, RightMatch)
            return LeftMatch.Name:lower() < RightMatch.Name:lower()
        end)

        GlobalSearchMatches = Matches
        local ActiveMatchIndex = 1
        for MatchIndex, Match in ipairs(GlobalSearchMatches) do
            if Match.Tab == Library.ActiveTab then
                ActiveMatchIndex = MatchIndex
                break
            end
        end

        ShowGlobalSearchMatch(ActiveMatchIndex)
    end
    
    function Window:SetFooterText(NewText)
        if FooterLabel then
            FooterLabel.Text = tostring(NewText or "")
            return true
        end
    
        return false
    end

    function Window:AddTab(...)
        local Name = nil
        local Icon = nil
        local Description = nil

        if select("#", ...) == 1 and typeof(...) == "table" then
            local Info = select(1, ...)
            Name = Info.Name or "Tab"
            Icon = Info.Icon
            Description = Info.Description
        else
            Name = select(1, ...)
            Icon = select(2, ...)
            Description = select(3, ...)
        end

        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer
        local TabLeft
        local TabRight
		
        local WarningBox
        local WarningBoxScrollingFrame
        local WarningTitle
        local WarningText
        local WarningStroke

        Icon = Library:GetIcon(Icon)
        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })

            New("UIPadding", {
                PaddingBottom = UDim.new(0, 11),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TabButton,
            })

            if Icon then
                TabIcon = New("ImageLabel", {
                    Image = Icon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = Icon.ImageRectOffset,
                    ImageRectSize = Icon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            --// Tab Container \\--
            TabContainer = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })

            TabLeft = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabLeft,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabLeft,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabLeft,
                })

                TabLeft.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabLeft, { Size = TabLeft.Size })
            end

            TabRight = New("ScrollingFrame", {
                AnchorPoint = Vector2.new(1, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                Position = UDim2.fromScale(1, 0),
                ScrollBarThickness = 0,
                Parent = TabContainer,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = TabRight,
            })
            do
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = -1,
                    Parent = TabRight,
                })
                New("Frame", {
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    Parent = TabRight,
                })

                TabRight.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, 0)
                Library:UpdateDPI(TabRight, { Size = TabRight.Size })
            end

            --// Warning Box \\--
            WarningBox = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(127, 0, 0),
                BorderColor3 = Color3.fromRGB(255, 50, 50),
                BorderMode = Enum.BorderMode.Inset,
                BorderSizePixel = 1,
                Position = UDim2.fromOffset(0, 6),
                Size = UDim2.fromScale(1, 0),
                Visible = false,
                Parent = TabContainer,
            })

            WarningBoxScrollingFrame = New("ScrollingFrame", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, -3),
                Size = UDim2.new(1, 0, 1, -3),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                Parent = WarningBox,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                PaddingTop = UDim.new(0, 4),
                Parent = WarningBoxScrollingFrame,
            })

            WarningTitle = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -4, 0, 14),
                Text = "",
                TextColor3 = Color3.fromRGB(255, 50, 50),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = WarningBoxScrollingFrame,
            })
            WarningStroke = New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = Color3.fromRGB(169, 0, 0),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningTitle,
            })

            WarningText = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 16),
                Size = UDim2.new(1, -4, 0, 0),
                Text = "",
                TextSize = 14,
                TextWrapped = true,
                Parent = WarningBoxScrollingFrame,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
            })
            New("UIStroke", {
                ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
                Color = "Dark",
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = WarningText,
            })
        end

        --// Tab Table \\--
        local Tab = {
        TabLabel = TabLabel, -- <--- ADD THIS LINE HERE!
            Groupboxes = {},
            Tabboxes = {}, 
            DependencyGroupboxes = {},
            Sides = {
                TabLeft,
                TabRight,
            },
            WarningBox = {
                IsNormal = false,
                LockSize = false,
                Visible = false,
                Title = "WARNING",
                Text = ""
            }
        }

        function Tab:UpdateWarningBox(Info)
            if typeof(Info.IsNormal) == "boolean"   then Tab.WarningBox.IsNormal    = Info.IsNormal end
            if typeof(Info.LockSize) == "boolean"   then Tab.WarningBox.LockSize    = Info.LockSize end
            if typeof(Info.Visible) == "boolean"    then Tab.WarningBox.Visible     = Info.Visible end
            if typeof(Info.Title) == "string"       then Tab.WarningBox.Title       = Info.Title end
            if typeof(Info.Text) == "string"        then Tab.WarningBox.Text        = Info.Text end

            WarningBox.Visible = Tab.WarningBox.Visible
            WarningTitle.Text = Tab.WarningBox.Title
            WarningText.Text = Tab.WarningBox.Text
            Tab:Resize(true)

            WarningBox.BackgroundColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            WarningBox.BorderColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            WarningTitle.TextColor3 = Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            WarningStroke.Color = Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)

            if not Library.Registry[WarningBox] then
                Library:AddToRegistry(WarningBox, {})
            end
            if not Library.Registry[WarningTitle] then
                Library:AddToRegistry(WarningTitle, {})
            end
            if not Library.Registry[WarningStroke] then
                Library:AddToRegistry(WarningStroke, {})
            end

            Library.Registry[WarningBox].BackgroundColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.BackgroundColor or Color3.fromRGB(127, 0, 0)
            end

            Library.Registry[WarningBox].BorderColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningTitle].TextColor3 = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.FontColor or Color3.fromRGB(255, 50, 50)
            end

            Library.Registry[WarningStroke].Color = function()
                return Tab.WarningBox.IsNormal == true and Library.Scheme.OutlineColor or Color3.fromRGB(169, 0, 0)
            end
        end

        function Tab:Resize(ResizeWarningBox: boolean?)
            if ResizeWarningBox then
                local MaximumSize = math.floor(TabContainer.AbsoluteSize.Y / 3.25)
                local _, YText = Library:GetTextBounds(
                    WarningText.Text,
                    Library.Scheme.Font,
                    WarningText.TextSize,
                    WarningText.AbsoluteSize.X
                )

                local YBox = 24 + YText
                if Tab.WarningBox.LockSize == true and YBox >= MaximumSize then
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, YBox)
                    YBox = MaximumSize
                else
                    WarningBoxScrollingFrame.CanvasSize = UDim2.fromOffset(0, 0)
                end

                WarningText.Size = UDim2.new(1, -4, 0, YText)
                Library:UpdateDPI(WarningText, { Size = WarningText.Size })

                WarningBox.Size = UDim2.new(1, 0, 0, YBox)
                Library:UpdateDPI(WarningBox, { Size = WarningBox.Size })
            end

            local Offset = WarningBox.Visible and WarningBox.AbsoluteSize.Y + 6 or 0
            for _, Side in pairs(Tab.Sides) do
                Side.Position = UDim2.new(Side.Position.X.Scale, 0, 0, Offset)
                Side.Size = UDim2.new(0, math.floor(TabContainer.AbsoluteSize.X / 2) - 3, 1, -Offset)
                Library:UpdateDPI(Side, {
                    Position = Side.Position,
                    Size = Side.Size,
                })
            end
        end
        
        
    function Tab:AddGroupbox(Info)
        if type(Info) ~= "table" then
            Info = {}
        end

        local function getGroupboxNumber(value, fallback)
            value = tonumber(value)
            if value == nil then
                return fallback
            end

            return value
        end

        local groupboxSide = 1
        if Info.Side == 2 then
            groupboxSide = 2
        end

        local boxName = tostring(Info.Name or "Groupbox")
        local description = nil
        if Info.Description ~= nil then
            description = tostring(Info.Description)
            if description == "" then
                description = nil
            end
        end

        Tab.Groupboxes = Tab.Groupboxes or {}

        local parentColumn = TabLeft
        if groupboxSide == 2 then
            parentColumn = TabRight
        end
        if parentColumn == nil then
            parentColumn = TabLeft or TabRight
        end
        if parentColumn == nil then
            warn(("[Library] AddGroupbox('%s') skipped: missing TabLeft/TabRight"):format(boxName))
            return nil
        end

        local configuredCornerRadius = 8
        if WindowInfo then
            configuredCornerRadius = getGroupboxNumber(WindowInfo.CornerRadius, 8)
        end

        local cardCornerRadius = math.max(12, configuredCornerRadius)
        local surfaceCornerRadius = math.max(10, cardCornerRadius - 2)
        local contentCornerRadius = math.max(10, cardCornerRadius - 2)
        local surfaceInset = 1
        local headerHorizontalPadding = 11
        local headerVerticalPadding = 7
        local headerIconSize = 28
        local headerIconImageSize = 14
        local headerIconGap = 9
        local headerMinHeight = headerIconSize + (headerVerticalPadding * 2)
        local headerArrowSize = 15
        local headerArrowRightPadding = 13
        local headerRightReserve = headerArrowRightPadding + headerArrowSize + 10
        local headerTextGap = 2
        local contentOuterInset = 5
        local contentSpacing = 8
        local contentPadding = 6
        local contentPaddingBottom = 10
        local tapMoveThreshold = 4
        local arrowTransparency = 0.18
        local collapsedArrowRotation = 90
        local expandedArrowRotation = 180
        local groupboxTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local groupboxShellTargetColor = Color3.fromRGB(12, 12, 13)
        local groupboxSurfaceTargetColor = Color3.fromRGB(17, 17, 19)
        local groupboxContentTargetColor = Color3.fromRGB(11, 11, 12)
        local groupboxIconTargetColor = Color3.fromRGB(23, 23, 25)
        local groupboxBorderTargetColor = Color3.fromRGB(72, 72, 72)
        local groupboxInnerBorderTargetColor = Color3.fromRGB(42, 42, 42)

        local function scaleGroupboxPixels(value)
            return math.max(0, math.floor((value * Library.DPIScale) + 0.5))
        end

        local function getGroupboxShellColor()
            return Library.Scheme.BackgroundColor:Lerp(groupboxShellTargetColor, 0.96)
        end

        local function getGroupboxSurfaceColor()
            return Library.Scheme.BackgroundColor:Lerp(groupboxSurfaceTargetColor, 0.94)
        end

        local function getGroupboxContentColor()
            return Library.Scheme.BackgroundColor:Lerp(groupboxContentTargetColor, 0.92)
        end

        local function getGroupboxIconColor()
            return Library.Scheme.BackgroundColor:Lerp(groupboxIconTargetColor, 0.9)
        end

        local function getGroupboxBorderColor()
            return Library.Scheme.OutlineColor:Lerp(groupboxBorderTargetColor, 0.68)
        end

        local function getGroupboxInnerBorderColor()
            return Library.Scheme.OutlineColor:Lerp(groupboxInnerBorderTargetColor, 0.74)
        end

        local BoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Parent = parentColumn,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = BoxHolder,
        })

        local Background = New("Frame", {
            BackgroundColor3 = getGroupboxBorderColor(),
            ClipsDescendants = true,
            Size = UDim2.fromScale(1, 0),
            Parent = BoxHolder,

            DPIExclude = {
                Size = true,
            },
        })
        Library:AddToRegistry(Background, {
            BackgroundColor3 = function()
                return getGroupboxBorderColor()
            end,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, cardCornerRadius),
            Parent = Background,
        })

        local ShellFrame = New("Frame", {
            BackgroundColor3 = getGroupboxShellColor(),
            Position = UDim2.fromOffset(surfaceInset, surfaceInset),
            Size = UDim2.new(1, -(surfaceInset * 2), 1, -(surfaceInset * 2)),
            Parent = Background,

            DPIExclude = {
                Position = true,
                Size = true,
            },
        })
        Library:AddToRegistry(ShellFrame, {
            BackgroundColor3 = function()
                return getGroupboxShellColor()
            end,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, surfaceCornerRadius),
            Parent = ShellFrame,
        })

        local SurfaceFrame = New("Frame", {
            BackgroundColor3 = getGroupboxSurfaceColor(),
            ClipsDescendants = true,
            Position = UDim2.fromOffset(surfaceInset, surfaceInset),
            Size = UDim2.new(1, -(surfaceInset * 2), 1, -(surfaceInset * 2)),
            Parent = ShellFrame,

            DPIExclude = {
                Position = true,
                Size = true,
            },
        })
        Library:AddToRegistry(SurfaceFrame, {
            BackgroundColor3 = function()
                return getGroupboxSurfaceColor()
            end,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, surfaceCornerRadius),
            Parent = SurfaceFrame,
        })
        local SurfaceStroke = New("UIStroke", {
            Color = getGroupboxInnerBorderColor(),
            Thickness = 1,
            Transparency = 0.12,
            Parent = SurfaceFrame,
        })
        Library:AddToRegistry(SurfaceStroke, {
            Color = function()
                return getGroupboxInnerBorderColor()
            end,
        })

        local HeaderFrame = New("Frame", {
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            Parent = SurfaceFrame,

            DPIExclude = {
                Size = true,
            },
        })

        local BoxIcon = nil
        if Info.IconName ~= nil and Library.GetIcon then
            local iconSuccess, iconResult = pcall(function()
                return Library:GetIcon(Info.IconName)
            end)
            if iconSuccess then
                BoxIcon = iconResult
            end
        end

        local leftTextOffset = headerHorizontalPadding
        if BoxIcon then
            local IconCard = New("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = getGroupboxIconColor(),
                Position = UDim2.new(0, headerHorizontalPadding, 0.5, 0),
                Size = UDim2.fromOffset(headerIconSize, headerIconSize),
                Parent = HeaderFrame,
            })
            Library:AddToRegistry(IconCard, {
                BackgroundColor3 = function()
                    return getGroupboxIconColor()
                end,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, math.max(10, contentCornerRadius - 2)),
                Parent = IconCard,
            })
            local IconCardStroke = New("UIStroke", {
                Color = getGroupboxInnerBorderColor(),
                Thickness = 1,
                Transparency = 0.5,
                Parent = IconCard,
            })
            Library:AddToRegistry(IconCardStroke, {
                Color = function()
                    return getGroupboxInnerBorderColor()
                end,
            })

            local IconImage = New("ImageLabel", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Image = BoxIcon.Url,
                ImageColor3 = Library.Scheme.AccentColor,
                ImageRectOffset = BoxIcon.ImageRectOffset,
                ImageRectSize = BoxIcon.ImageRectSize,
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(headerIconImageSize, headerIconImageSize),
                Parent = IconCard,
            })
            Library:AddToRegistry(IconImage, {
                ImageColor3 = "AccentColor",
            })

            leftTextOffset = headerHorizontalPadding + headerIconSize + headerIconGap
        end

        local HeaderTextStack = New("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, leftTextOffset, 0.5, 0),
            Size = UDim2.new(1, -(leftTextOffset + headerRightReserve), 0, 0),
            Parent = HeaderFrame,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, headerTextGap),
            Parent = HeaderTextStack,
        })

        local GroupboxLabel = New("TextLabel", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamMedium,
            Size = UDim2.new(1, 0, 0, 0),
            Text = boxName,
            TextColor3 = Library.Scheme.FontColor,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = HeaderTextStack,
        })
        Library:AddToRegistry(GroupboxLabel, {
            TextColor3 = "FontColor",
        })

        if description then
            local GroupboxDescription = New("TextLabel", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Font = Enum.Font.Gotham,
                Size = UDim2.new(1, 0, 0, 0),
                Text = description,
                TextColor3 = Library.Scheme.FontColor,
                TextSize = 10,
                TextTransparency = 0.4,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                Parent = HeaderTextStack,
            })
            Library:AddToRegistry(GroupboxDescription, {
                TextColor3 = "FontColor",
            })
        end

        local ToggleIcon = nil
        if ArrowIcon then
            ToggleIcon = New("ImageLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Image = ArrowIcon.Url,
                ImageColor3 = Library.Scheme.FontColor,
                ImageRectOffset = ArrowIcon.ImageRectOffset,
                ImageRectSize = ArrowIcon.ImageRectSize,
                ImageTransparency = arrowTransparency,
                Position = UDim2.new(1, -headerArrowRightPadding, 0.5, 0),
                Rotation = collapsedArrowRotation,
                Size = UDim2.fromOffset(headerArrowSize, headerArrowSize),
                Parent = HeaderFrame,
            })
            Library:AddToRegistry(ToggleIcon, {
                ImageColor3 = "FontColor",
            })
        else
            collapsedArrowRotation = 0
            expandedArrowRotation = 90
            ToggleIcon = New("TextLabel", {
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamMedium,
                Position = UDim2.new(1, -headerArrowRightPadding, 0.5, 0),
                Rotation = collapsedArrowRotation,
                Size = UDim2.fromOffset(headerArrowSize + 2, headerArrowSize + 2),
                Text = "›",
                TextColor3 = Library.Scheme.FontColor,
                TextSize = 19,
                TextTransparency = arrowTransparency,
                Parent = HeaderFrame,
            })
            Library:AddToRegistry(ToggleIcon, {
                TextColor3 = "FontColor",
            })
        end

        local HeaderDivider = New("Frame", {
            BackgroundColor3 = getGroupboxInnerBorderColor(),
            BackgroundTransparency = 0.18,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.new(1, 0, 0, 0),
            Visible = false,
            Parent = SurfaceFrame,

            DPIExclude = {
                Position = true,
                Size = true,
            },
        })
        Library:AddToRegistry(HeaderDivider, {
            BackgroundColor3 = function()
                return getGroupboxInnerBorderColor()
            end,
        })

        local GroupboxContainer = New("Frame", {
            BackgroundColor3 = getGroupboxContentColor(),
            ClipsDescendants = true,
            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromOffset(0, 0),
            Parent = SurfaceFrame,

            DPIExclude = {
                Position = true,
                Size = true,
            },
        })
        Library:AddToRegistry(GroupboxContainer, {
            BackgroundColor3 = function()
                return getGroupboxContentColor()
            end,
        })
        New("UICorner", {
            CornerRadius = UDim.new(0, contentCornerRadius),
            Parent = GroupboxContainer,
        })
        local GroupboxList = New("UIListLayout", {
            Padding = UDim.new(0, contentSpacing),
            Parent = GroupboxContainer,
        })
        New("UIPadding", {
            PaddingTop = UDim.new(0, contentPadding),
            PaddingBottom = UDim.new(0, contentPaddingBottom),
            PaddingLeft = UDim.new(0, contentPadding),
            PaddingRight = UDim.new(0, contentPadding),
            Parent = GroupboxContainer,
        })

        local Groupbox = {
            BoxHolder = BoxHolder,
            Holder = Background,
            Container = GroupboxContainer,
            ToggleIcon = ToggleIcon,
            Tab = Tab,
            DependencyBoxes = {},
            Elements = {},
        }

        local collapsed = true
        if Info.StartCollapsed ~= nil then
            collapsed = Info.StartCollapsed == true
        end

        local activeSizeTween = nil
        local activeArrowTween = nil
        local touchInputObject = nil
        local touchStartPosition = nil
        local connections = {}

        local function getHeaderHeight()
            local textHeight = HeaderTextStack.AbsoluteSize.Y
            local paddedTextHeight = textHeight + scaleGroupboxPixels(headerVerticalPadding * 2)
            return math.max(scaleGroupboxPixels(headerMinHeight), paddedTextHeight)
        end

        local function updateGroupboxLayout()
            local headerHeight = getHeaderHeight()
            local scaledContentInset = scaleGroupboxPixels(contentOuterInset)
            local contentTop = headerHeight + scaledContentInset
            local contentHeight = GroupboxList.AbsoluteContentSize.Y + scaleGroupboxPixels(contentPadding + contentPaddingBottom)

            HeaderFrame.Size = UDim2.new(1, 0, 0, headerHeight)
            HeaderDivider.Position = UDim2.fromOffset(scaledContentInset, headerHeight)
            HeaderDivider.Size = UDim2.new(1, -(scaledContentInset * 2), 0, math.max(1, scaleGroupboxPixels(1)))
            GroupboxContainer.Position = UDim2.fromOffset(scaledContentInset, contentTop)
            GroupboxContainer.Size = UDim2.new(1, -(scaledContentInset * 2), 0, contentHeight)

            if collapsed then
                return headerHeight
            end

            return contentTop + contentHeight + scaledContentInset
        end

        local function updateArrow(animated)
            local rotation = expandedArrowRotation
            if collapsed then
                rotation = collapsedArrowRotation
            end

            if activeArrowTween then
                activeArrowTween:Cancel()
                activeArrowTween = nil
            end

            if animated then
                activeArrowTween = TweenService:Create(ToggleIcon, groupboxTweenInfo, {
                    Rotation = rotation,
                })
                activeArrowTween:Play()
            else
                ToggleIcon.Rotation = rotation
                if ToggleIcon:IsA("ImageLabel") then
                    ToggleIcon.ImageTransparency = arrowTransparency
                else
                    ToggleIcon.TextTransparency = arrowTransparency
                end
            end
        end

        function Groupbox:Resize_old()
            self:Resize(false)
        end

        function Groupbox:Resize(animated)
            if Background.Parent == nil then
                return
            end

            local targetHeight = math.max(0, updateGroupboxLayout())
            local targetSize = UDim2.new(1, 0, 0, targetHeight)

            if activeSizeTween then
                activeSizeTween:Cancel()
                activeSizeTween = nil
            end

            if animated then
                activeSizeTween = TweenService:Create(Background, groupboxTweenInfo, {
                    Size = targetSize,
                })
                activeSizeTween:Play()
            else
                Background.Size = targetSize
            end
        end

        local function toggleGroupbox()
            collapsed = not collapsed
            HeaderDivider.Visible = not collapsed

            if not collapsed then
                GroupboxContainer.Visible = true
            end

            updateArrow(true)
            Groupbox:Resize(true)

            if collapsed then
                task.delay(groupboxTweenInfo.Time, function()
                    if collapsed and GroupboxContainer.Parent then
                        GroupboxContainer.Visible = false
                    end
                end)
            end
        end

        local function connectGroupboxSignal(signal, callback)
            if signal == nil then
                return
            end

            local connectSuccess, connection = pcall(function()
                return signal:Connect(callback)
            end)
            if connectSuccess and connection then
                connections[#connections + 1] = connection
            end
        end

        connectGroupboxSignal(HeaderFrame.InputBegan, function(input)
            if input == nil then
                return
            end

            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggleGroupbox()
            elseif input.UserInputType == Enum.UserInputType.Touch then
                touchInputObject = input
                touchStartPosition = input.Position
            end
        end)

        connectGroupboxSignal(UserInputService.InputChanged, function(input)
            if input ~= touchInputObject or touchStartPosition == nil then
                return
            end

            local delta = input.Position - touchStartPosition
            if math.abs(delta.X) > tapMoveThreshold or math.abs(delta.Y) > tapMoveThreshold then
                touchInputObject = nil
                touchStartPosition = nil
            end
        end)

        connectGroupboxSignal(UserInputService.InputEnded, function(input)
            if input ~= touchInputObject then
                return
            end

            toggleGroupbox()
            touchInputObject = nil
            touchStartPosition = nil
        end)

        connectGroupboxSignal(HeaderTextStack:GetPropertyChangedSignal("AbsoluteSize"), function()
            Groupbox:Resize(false)
        end)

        connectGroupboxSignal(GroupboxList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            if not collapsed then
                Groupbox:Resize(false)
            end
        end)

        connectGroupboxSignal(BoxHolder.AncestryChanged, function(_, newParent)
            if newParent ~= nil then
                return
            end

            if activeSizeTween then
                activeSizeTween:Cancel()
            end
            if activeArrowTween then
                activeArrowTween:Cancel()
            end

            for index = 1, #connections do
                local connection = connections[index]
                if connection and connection.Connected then
                    connection:Disconnect()
                end
            end
        end)

        if type(BaseGroupbox) == "table" then
            setmetatable(Groupbox, BaseGroupbox)
        end

        HeaderDivider.Visible = not collapsed
        GroupboxContainer.Visible = not collapsed
        updateArrow(false)
        Groupbox:Resize(false)
        Tab.Groupboxes[boxName] = Groupbox

        return Groupbox
    end
    function Tab:AddGroupbox_org(Info)
        local BoxHolder = New("Frame", {
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 0),
            Parent = Info.Side == 1 and TabLeft or TabRight,
        })
        New("UIListLayout", {
            Padding = UDim.new(0, 6),
            Parent = BoxHolder,
        })
    
        local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
        Background.Size = UDim2.fromScale(1, 0)
        Library:UpdateDPI(Background, { Size = false })
    
        local GroupboxHolder, GroupboxLabel, GroupboxContainer, GroupboxList, ToggleIcon, HeaderFrame
    
        do
            GroupboxHolder = New("Frame", {
                BackgroundColor3 = "BackgroundColor",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 1, -4),
                Parent = Background,
            })
            New("UICorner", {
                CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                Parent = GroupboxHolder,
            })
            Library:MakeLine(GroupboxHolder, {
                Position = UDim2.fromOffset(0, 34),
                Size = UDim2.new(1, 0, 0, 1),
            })
    
            HeaderFrame = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = GroupboxHolder,
            })
    
            local BoxIcon = Library:GetIcon(Info.IconName)
            if BoxIcon then
                New("ImageLabel", {
                    Image = BoxIcon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = BoxIcon.ImageRectOffset,
                    ImageRectSize = BoxIcon.ImageRectSize,
                    Position = UDim2.fromOffset(6, 6),
                    Size = UDim2.fromOffset(22, 22),
                    Parent = HeaderFrame,
                })
            end
    
            GroupboxLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(BoxIcon and 24 or 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                Text = Info.Name,
                TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = HeaderFrame,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 28),
                Parent = GroupboxLabel,
            })
    
            ToggleIcon = New("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, -24, 0, 7),
                TextColor3 = Color3.fromRGB(200, 200, 200),
                TextSize = 14,
                Font = Enum.Font.Code,
                Parent = HeaderFrame,
            })
    
            GroupboxContainer = New("Frame", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(0, 35),
                Size = UDim2.new(1, 0, 1, -35),
                Parent = GroupboxHolder,
            })
    
            GroupboxList = New("UIListLayout", {
                Padding = UDim.new(0, 8),
                Parent = GroupboxContainer,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 7),
                PaddingLeft = UDim.new(0, 7),
                PaddingRight = UDim.new(0, 7),
                PaddingTop = UDim.new(0, 7),
                Parent = GroupboxContainer,
            })
        end
    
        local Groupbox = {
            BoxHolder = BoxHolder,
            Holder = Background,
            Container = GroupboxContainer,
            ToggleIcon = ToggleIcon,
    
            Tab = Tab,
            DependencyBoxes = {},
            Elements = {},
        }
    
        local collapsed = true
        if Info.StartCollapsed ~= nil then
            collapsed = Info.StartCollapsed
        end
    
        GroupboxContainer.Visible = not collapsed
        ToggleIcon.Text = collapsed and ">" or "˅"
    
        function Groupbox:Resize_old()
            if not collapsed then
                Background.Size = UDim2.new(1, 0, 0,
                    (GroupboxList.AbsoluteContentSize.Y + 53) * Library.DPIScale
                )
            else
                Background.Size = UDim2.new(1, 0, 0, 34)
            end
        end
    
        function Groupbox:Resize()
            if not collapsed then
                local totalHeight = GroupboxList.AbsoluteContentSize.Y + (53 * Library.DPIScale)
                Background.Size = UDim2.new(1, 0, 0, totalHeight)
            else
                Background.Size = UDim2.new(1, 0, 0, 34 * Library.DPIScale)
            end
        end
    
        local function Toggle()
            collapsed = not collapsed
            GroupboxContainer.Visible = not collapsed
            ToggleIcon.Text = collapsed and ">" or "˅"
            Groupbox:Resize()
        end
    
        local touchInputObj = nil
        local touchStartPos = nil
        local MAX_TAP_MOVE = 4
    
        HeaderFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                Toggle()
            elseif input.UserInputType == Enum.UserInputType.Touch then
                touchInputObj = input
                touchStartPos = input.Position
            end
        end)
    
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input ~= touchInputObj then return end
            local delta = input.Position - touchStartPos
            if math.abs(delta.X) > MAX_TAP_MOVE or math.abs(delta.Y) > MAX_TAP_MOVE then
                touchInputObj = nil
                touchStartPos = nil
            end
        end)
    
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input ~= touchInputObj then return end
            Toggle()
            touchInputObj = nil
            touchStartPos = nil
        end)
    
        setmetatable(Groupbox, BaseGroupbox)
    
        Groupbox:Resize()
        Tab.Groupboxes[Info.Name] = Groupbox
    
        return Groupbox
    end




        function Tab:AddLeftGroupbox(Name, IconName, StartCollapsed)
            return Tab:AddGroupbox({
                Side = 1,
                Name = Name,
                IconName = IconName,
                StartCollapsed = StartCollapsed -- pass through
            })
        end
        
        function Tab:AddRightGroupbox(Name, IconName, StartCollapsed)
            return Tab:AddGroupbox({
                Side = 2,
                Name = Name,
                IconName = IconName,
                StartCollapsed = StartCollapsed
            })
        end

        function Tab:AddTabbox(Info)
            local BoxHolder = New("Frame", {
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 0),
                Parent = Info.Side == 1 and TabLeft or TabRight,
            })
            New("UIListLayout", {
                Padding = UDim.new(0, 6),
                Parent = BoxHolder,
            })

            local Background = Library:MakeOutline(BoxHolder, WindowInfo.CornerRadius)
            Background.Size = UDim2.fromScale(1, 0)
            Library:UpdateDPI(Background, {
                Size = false,
            })

            local TabboxHolder
            local TabboxButtons

            do
                TabboxHolder = New("Frame", {
                    BackgroundColor3 = "BackgroundColor",
                    Position = UDim2.fromOffset(2, 2),
                    Size = UDim2.new(1, -4, 1, -4),
                    Parent = Background,
                })
                New("UICorner", {
                    CornerRadius = UDim.new(0, WindowInfo.CornerRadius - 1),
                    Parent = TabboxHolder,
                })

                TabboxButtons = New("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 34),
                    Parent = TabboxHolder,
                })
                New("UIListLayout", {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Parent = TabboxButtons,
                })
            end

            local Tabbox = {
                ActiveTab = nil,

                BoxHolder = BoxHolder,
                Holder = Background,
                Tabs = {},
            }

            function Tabbox:AddTab(Name)
                local Button = New("TextButton", {
                    BackgroundColor3 = "MainColor",
                    BackgroundTransparency = 0,
                    Size = UDim2.fromOffset(0, 34),
                    Text = Name,
                    TextSize = 15,
                    TextTransparency = 0.5,
                    Parent = TabboxButtons,
                })

                local Line = Library:MakeLine(Button, {
                    AnchorPoint = Vector2.new(0, 1),
                    Position = UDim2.new(0, 0, 1, 1),
                    Size = UDim2.new(1, 0, 0, 1),
                })

                local Container = New("Frame", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(0, 35),
                    Size = UDim2.new(1, 0, 1, -35),
                    Visible = false,
                    Parent = TabboxHolder,
                })
                local List = New("UIListLayout", {
                    Padding = UDim.new(0, 8),
                    Parent = Container,
                })
                New("UIPadding", {
                    PaddingBottom = UDim.new(0, 7),
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 7),
                    Parent = Container,
                })

                local Tab = {
                    ButtonHolder = Button,
                    Container = Container,

                    Tab = Tab,
                    Elements = {},
                    DependencyBoxes = {},
                }

                function Tab:Show()
                    if Tabbox.ActiveTab then
                        Tabbox.ActiveTab:Hide()
                    end

                    Button.BackgroundTransparency = 1
                    Button.TextTransparency = 0
                    Line.Visible = false

                    Container.Visible = true

                    Tabbox.ActiveTab = Tab
                    Tab:Resize()
                end

                function Tab:Hide()
                    Button.BackgroundTransparency = 0
                    Button.TextTransparency = 0.5
                    Line.Visible = true
                    Container.Visible = false

                    Tabbox.ActiveTab = nil
                end

                function Tab:Resize()
                    if Tabbox.ActiveTab ~= Tab then
                        return
                    end
                    Background.Size = UDim2.new(1, 0, 0, List.AbsoluteContentSize.Y + 53 * Library.DPIScale)
                end

                --// Execution \\--
                if not Tabbox.ActiveTab then
                    Tab:Show()
                end

                Button.MouseButton1Click:Connect(Tab.Show)

                setmetatable(Tab, BaseGroupbox)

                Tabbox.Tabs[Name] = Tab

                return Tab
            end

            if Info.Name then
                Tab.Tabboxes[Info.Name] = Tabbox
            else
                table.insert(Tab.Tabboxes, Tabbox)
            end

            return Tabbox
        end

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Side = 1, Name = Name })
        end

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Side = 2, Name = Name })
        end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end

            if Description then
                CurrentTabInfo.Visible = true
                
                if IsDefaultSearchbarSize then
                    SearchHolder.Size = UDim2.fromScale(0.5, 1)
                end

                CurrentTabLabel.Text = Name
                CurrentTabDescription.Text = Description
            end

            TabContainer.Visible = true

            Library.ActiveTab = Tab
            if Library.Searching then
                Library:UpdateSearch(Library.SearchText)
            end
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            if IsDefaultSearchbarSize then
                SearchHolder.Size = UDim2.fromScale(1, 1)
            end
            
            CurrentTabInfo.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Library.Tabs[Name] = Tab

        return Tab
    end

    function Window:AddKeyTab(Name)
        local TabButton: TextButton
        local TabLabel
        local TabIcon

        local TabContainer

        do
            TabButton = New("TextButton", {
                BackgroundColor3 = "MainColor",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 40),
                Text = "",
                Parent = Tabs,
            })
            New("UIPadding", {
                PaddingBottom = UDim.new(0, 11),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
                PaddingTop = UDim.new(0, 11),
                Parent = TabButton,
            })

            TabLabel = New("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(30, 0),
                Size = UDim2.new(1, -30, 1, 0),
                Text = Name,
                TextSize = 16,
                TextTransparency = 0.5,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = TabButton,
            })

            if KeyIcon then
                TabIcon = New("ImageLabel", {
                    Image = KeyIcon.Url,
                    ImageColor3 = "AccentColor",
                    ImageRectOffset = KeyIcon.ImageRectOffset,
                    ImageRectSize = KeyIcon.ImageRectSize,
                    ImageTransparency = 0.5,
                    Size = UDim2.fromScale(1, 1),
                    SizeConstraint = Enum.SizeConstraint.RelativeYY,
                    Parent = TabButton,
                })
            end

            --// Tab Container \\--
            TabContainer = New("ScrollingFrame", {
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                CanvasSize = UDim2.fromScale(0, 0),
                ScrollBarThickness = 0,
                Size = UDim2.fromScale(1, 1),
                Visible = false,
                Parent = Container,
            })
            New("UIListLayout", {
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
                Padding = UDim.new(0, 8),
                VerticalAlignment = Enum.VerticalAlignment.Center,
                Parent = TabContainer,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                Parent = TabContainer,
            })
        end

        --// Tab Table \\--
        local Tab = {
            Elements = {},
            IsKeyTab = true,
        }

        function Tab:AddKeyBox(...)
            local Data = {}

            local First = select(1, ...)

            if typeof(First) == "function" then
                Data.Callback = First
            else
                Data.ExpectedKey = First
                Data.Callback = select(2, ...)
            end

            local Holder = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0.75, 0, 0, 21),
                Parent = TabContainer,
            })

            local Box = New("TextBox", {
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                PlaceholderText = "Key",
                Size = UDim2.new(1, -71, 1, 0),
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Holder,
            })
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
                Parent = Box,
            })

            local Button = New("TextButton", {
                AnchorPoint = Vector2.new(1, 0),
                BackgroundColor3 = "MainColor",
                BorderColor3 = "OutlineColor",
                BorderSizePixel = 1,
                Position = UDim2.fromScale(1, 0),
                Size = UDim2.new(0, 63, 1, 0),
                Text = "Execute",
                TextSize = 14,
                Parent = Holder,
            })

            Button.MouseButton1Click:Connect(function()
                if Data.ExpectedKey and Box.Text ~= Data.ExpectedKey then
                    Data.Callback(false, Box.Text)
                    return
                end

                Data.Callback(true, Box.Text)
            end)
        end

        function Tab:Resize() end

        function Tab:Hover(Hovering)
            if Library.ActiveTab == Tab then
                return
            end

            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = Hovering and 0.25 or 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = Hovering and 0.25 or 0.5,
                }):Play()
            end
        end

        function Tab:Show()
            if Library.ActiveTab then
                Library.ActiveTab:Hide()
            end

            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 0,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0,
                }):Play()
            end
            TabContainer.Visible = true

            Library.ActiveTab = Tab
        end

        function Tab:Hide()
            TweenService:Create(TabButton, Library.TweenInfo, {
                BackgroundTransparency = 1,
            }):Play()
            TweenService:Create(TabLabel, Library.TweenInfo, {
                TextTransparency = 0.5,
            }):Play()
            if TabIcon then
                TweenService:Create(TabIcon, Library.TweenInfo, {
                    ImageTransparency = 0.5,
                }):Play()
            end
            TabContainer.Visible = false

            Library.ActiveTab = nil
        end

        --// Execution \\--
        if not Library.ActiveTab then
            Tab:Show()
        end

        TabButton.MouseEnter:Connect(function()
            Tab:Hover(true)
        end)
        TabButton.MouseLeave:Connect(function()
            Tab:Hover(false)
        end)
        TabButton.MouseButton1Click:Connect(Tab.Show)

        Tab.Container = TabContainer
        setmetatable(Tab, BaseGroupbox)

        Library.Tabs[Name] = Tab

        return Tab
    end

    local UpdateHubToggleButtonVisual = function() end

    function Library:Toggle(Value: boolean?)
        if typeof(Value) == "boolean" then
            Library.Toggled = Value
        else
            Library.Toggled = not Library.Toggled
        end

        MainFrame.Visible = Library.Toggled
        UpdateHubToggleButtonVisual()
        
        -- Do not enable Modal for the normal window.
        -- It traps the mouse when the GUI is parented to PlayerGui.
        ModalElement.Modal = false

        if Library.Toggled and not Library.IsMobile then
            local OldMouseIconEnabled = UserInputService.MouseIconEnabled
            pcall(function()
                RunService:UnbindFromRenderStep("ShowCursor")
            end)
            RunService:BindToRenderStep("ShowCursor", Enum.RenderPriority.Last.Value, function()
                UserInputService.MouseIconEnabled = not Library.ShowCustomCursor

                Cursor.Position = UDim2.fromOffset(Mouse.X, Mouse.Y)
                Cursor.Visible = Library.ShowCustomCursor

                if not (Library.Toggled and ScreenGui and ScreenGui.Parent) then
                    UserInputService.MouseIconEnabled = OldMouseIconEnabled
                    Cursor.Visible = false
                    RunService:UnbindFromRenderStep("ShowCursor")
                end
            end)
        elseif not Library.Toggled then
            TooltipLabel.Visible = false
            for _, Option in pairs(Library.Options) do
                if Option.Type == "ColorPicker" then
                    Option.ColorMenu:Close()
                    Option.ContextMenu:Close()
                elseif Option.Type == "Dropdown" or Option.Type == "KeyPicker" then
                    Option.Menu:Close()
                end
            end
        end
    end

    local HubToggleScreenSizeScale = 0.085
    local HubToggleTopLeftPosition = UDim2.fromScale(0.008, 0.014)
    local HubToggleDragThresholdScale = 0.12
    local HubToggleInactiveColor = Color3.fromRGB(255, 145, 55)
    local HubToggleActiveDotColor = Color3.fromRGB(94, 255, 151)
    local HubToggleTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

    local function GetHubToggleStateColor()
        if Library.Toggled then
            return Library.Scheme.AccentColor
        end

        return HubToggleInactiveColor
    end

    local function GetHubToggleStatusColor()
        if Library.Toggled then
            return HubToggleActiveDotColor
        end

        return HubToggleInactiveColor
    end

    local HubToggleButton = New("TextButton", {
        Name = "ExoticHubToggleButton",
        Active = true,
        AnchorPoint = Vector2.zero,
        BackgroundTransparency = 1,
        Position = HubToggleTopLeftPosition,
        Size = UDim2.fromScale(HubToggleScreenSizeScale, HubToggleScreenSizeScale),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Text = "",
        ZIndex = 20,
        Parent = ScreenGui,

        DPIExclude = {
            Position = true,
            Size = true,
        },
    })

    local HubToggleShadow = New("Frame", {
        BackgroundColor3 = "Dark",
        BackgroundTransparency = 0.55,
        Position = UDim2.fromScale(0.083, 0.083),
        Size = UDim2.fromScale(1, 1),
        ZIndex = 20,
        Parent = HubToggleButton,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = HubToggleShadow,
    })

    local HubToggleSurface = New("Frame", {
        BackgroundColor3 = "BackgroundColor",
        BackgroundTransparency = 0.08,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 21,
        Parent = HubToggleButton,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = HubToggleSurface,
    })

    local HubToggleStroke = New("UIStroke", {
        Color = GetHubToggleStateColor,
        Thickness = 2,
        Transparency = 0.08,
        Parent = HubToggleSurface,
    })
    local HubToggleInteractionScale = New("UIScale", {
        Scale = 1,
        Parent = HubToggleButton,
    })

    local HubToggleInner = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = "MainColor",
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromScale(0.72, 0.72),
        ZIndex = 22,
        Parent = HubToggleButton,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = HubToggleInner,
    })

    local HubToggleBrand = New("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "E",
        TextScaled = true,
        ZIndex = 23,
        Parent = HubToggleInner,
    })
    HubToggleBrand.FontFace = Font.fromEnum(Enum.Font.GothamBlack)
    HubToggleBrand.TextColor3 = GetHubToggleStateColor()
    Library:AddToRegistry(HubToggleBrand, {
        TextColor3 = GetHubToggleStateColor,
    })

    local HubToggleHighlight = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = "White",
        BackgroundTransparency = 0.38,
        Position = UDim2.fromScale(0.5, 0.11),
        Size = UDim2.fromScale(0.28, 0.055),
        ZIndex = 24,
        Parent = HubToggleButton,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = HubToggleHighlight,
    })

    local HubToggleStatusDot = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = GetHubToggleStatusColor,
        Position = UDim2.fromScale(0.82, 0.82),
        Size = UDim2.fromScale(0.183, 0.183),
        ZIndex = 25,
        Parent = HubToggleButton,
    })
    New("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = HubToggleStatusDot,
    })
    New("UIStroke", {
        Color = "BackgroundColor",
        Thickness = 2,
        Parent = HubToggleStatusDot,
    })

    local HubToggleHovered = false
    local HubToggleDragging = false
    local HubToggleMoved = false
    local HubToggleDragStart = Vector2.zero
    local HubToggleStartPosition = HubToggleButton.Position
    local HubToggleInputChangedConnection: RBXScriptConnection?

    local function PlayHubToggleTween(Instance, Properties)
        TweenService:Create(Instance, HubToggleTweenInfo, Properties):Play()
    end

    local function UpdateHubToggleInteractionScale()
        local TargetScale = 1
        if HubToggleHovered then
            TargetScale = 1.07
        end

        PlayHubToggleTween(HubToggleInteractionScale, { Scale = TargetScale })
    end

    UpdateHubToggleButtonVisual = function()
        local BrandRotation = -180
        local BrandTransparency = 0.08
        local SurfaceTransparency = 0.08
        local StrokeTransparency = 0.12
        local StatusTransparency = 0.45

        if Library.Toggled then
            BrandRotation = 0
            BrandTransparency = 0
            SurfaceTransparency = 0.02
            StrokeTransparency = 0.05
            StatusTransparency = 0
        end
        if HubToggleHovered then
            StrokeTransparency = 0
        end

        local StateColor = GetHubToggleStateColor()
        PlayHubToggleTween(HubToggleBrand, {
            Rotation = BrandRotation,
            TextColor3 = StateColor,
            TextTransparency = BrandTransparency,
        })
        PlayHubToggleTween(HubToggleSurface, { BackgroundTransparency = SurfaceTransparency })
        PlayHubToggleTween(HubToggleStroke, {
            Color = StateColor,
            Transparency = StrokeTransparency,
        })
        PlayHubToggleTween(HubToggleStatusDot, {
            BackgroundColor3 = GetHubToggleStatusColor(),
            BackgroundTransparency = StatusTransparency,
        })
    end

    HubToggleButton.MouseEnter:Connect(function()
        HubToggleHovered = true
        UpdateHubToggleInteractionScale()
        UpdateHubToggleButtonVisual()
    end)
    HubToggleButton.MouseLeave:Connect(function()
        HubToggleHovered = false
        if not HubToggleDragging then
            UpdateHubToggleInteractionScale()
        end
        UpdateHubToggleButtonVisual()
    end)
    HubToggleButton.InputBegan:Connect(function(Input: InputObject)
        if not IsClickInput(Input) then
            return
        end

        HubToggleDragging = true
        HubToggleMoved = false
        HubToggleDragStart = Input.Position
        HubToggleStartPosition = HubToggleButton.Position
        PlayHubToggleTween(HubToggleInteractionScale, { Scale = 0.92 })

        if HubToggleInputChangedConnection and HubToggleInputChangedConnection.Connected then
            HubToggleInputChangedConnection:Disconnect()
        end
        HubToggleInputChangedConnection = Input.Changed:Connect(function()
            if Input.UserInputState ~= Enum.UserInputState.End then
                return
            end

            HubToggleDragging = false
            if HubToggleInputChangedConnection and HubToggleInputChangedConnection.Connected then
                HubToggleInputChangedConnection:Disconnect()
                HubToggleInputChangedConnection = nil
            end

            UpdateHubToggleInteractionScale()
            if not HubToggleMoved then
                Library:Toggle()
            end
        end)
    end)

    Library:GiveSignal(UserInputService.InputChanged:Connect(function(Input: InputObject)
        if not HubToggleDragging or not IsHoverInput(Input) or not (ScreenGui and ScreenGui.Parent) then
            return
        end

        local DragDelta = Input.Position - HubToggleDragStart
        local DragThreshold = HubToggleButton.AbsoluteSize.Y * HubToggleDragThresholdScale
        if DragDelta.Magnitude >= DragThreshold then
            HubToggleMoved = true
        end

        HubToggleButton.Position = UDim2.new(
            HubToggleStartPosition.X.Scale,
            HubToggleStartPosition.X.Offset + DragDelta.X,
            HubToggleStartPosition.Y.Scale,
            HubToggleStartPosition.Y.Offset + DragDelta.Y
        )
    end))

    UpdateHubToggleButtonVisual()
    if WindowInfo.AutoShow then
        task.spawn(function()
            Library:Toggle(true)
        end)
    end

    --// Execution \\--
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Library:UpdateSearch(SearchBox.Text)
        UpdateGlobalSearch(SearchBox.Text)
    end)

    SearchBox.Focused:Connect(function()
        TweenService:Create(SearchStroke, Library.TweenInfo, {
            Color = Library.Scheme.AccentColor,
            Transparency = 0,
        }):Play()
    end)

    SearchBox.FocusLost:Connect(function(EnterPressed)
        TweenService:Create(SearchStroke, Library.TweenInfo, {
            Color = Library.Scheme.OutlineColor,
            Transparency = 0.15,
        }):Play()

        if EnterPressed and #GlobalSearchMatches > 1 then
            ShowGlobalSearchMatch(GlobalSearchIndex + 1)
        end
    end)

    SearchResultButton.Activated:Connect(function()
        ShowGlobalSearchMatch(GlobalSearchIndex + 1)
    end)

    SearchClearButton.Activated:Connect(function()
        SearchBox.Text = ""
        SearchBox:CaptureFocus()
    end)

    Library:GiveSignal(UserInputService.InputBegan:Connect(function(Input: InputObject)
        if UserInputService:GetFocusedTextBox() then
            return
        end

        if
            (
                typeof(Library.ToggleKeybind) == "table"
                and Library.ToggleKeybind.Type == "KeyPicker"
                and Input.KeyCode.Name == Library.ToggleKeybind.Value
            ) or Input.KeyCode == Library.ToggleKeybind
        then
            Library.Toggle()
        end
    end))

    Library:GiveSignal(UserInputService.WindowFocused:Connect(function()
        Library.IsRobloxFocused = true
    end))
    Library:GiveSignal(UserInputService.WindowFocusReleased:Connect(function()
        Library.IsRobloxFocused = false
    end))

    return Window
end

local function OnPlayerChange()
    local PlayerList, ExcludedPlayerList = GetPlayers(), GetPlayers(true)

    for _, Dropdown in pairs(Options) do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Player" then
            Dropdown:SetValues(Dropdown.ExcludeLocalPlayer and ExcludedPlayerList or PlayerList)
        end
    end
end
local function OnTeamChange()
    local TeamList = GetTeams()

    for _, Dropdown in pairs(Options) do
        if Dropdown.Type == "Dropdown" and Dropdown.SpecialType == "Team" then
            Dropdown:SetValues(TeamList)
        end
    end
end

Library:GiveSignal(Players.PlayerAdded:Connect(OnPlayerChange))
Library:GiveSignal(Players.PlayerRemoving:Connect(OnPlayerChange))

Library:GiveSignal(Teams.ChildAdded:Connect(OnTeamChange))
Library:GiveSignal(Teams.ChildRemoved:Connect(OnTeamChange))

getgenv().Library = Library
return Library
