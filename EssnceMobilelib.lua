local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

local Library = {}
Library.__index = Library

local FONT = Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.SourceSansBold
local CURRENT_FONT_FACE = nil
local DEFAULT_ACCENT = Color3.fromHex("#CF00FF")

local THEME = {
	WindowBgTop       = Color3.fromRGB(24, 10, 29),
	WindowBgBottom    = Color3.fromRGB(13, 6, 17),
	CardBgTop         = Color3.fromRGB(25, 12, 31),
	CardBgBottom      = Color3.fromRGB(15, 7, 20),
	HeaderTrough      = Color3.fromRGB(16, 8, 21),
	ElementBgTop      = Color3.fromRGB(27, 13, 33),
	ElementBgBottom   = Color3.fromRGB(17, 8, 22),
	BorderMain        = Color3.fromRGB(175, 40, 215),
	BorderCard        = Color3.fromRGB(58, 22, 72),
	BorderElement     = Color3.fromRGB(72, 28, 88),
	BorderTabActive   = Color3.fromRGB(125, 45, 155),
	AccentLilacLight  = Color3.fromRGB(207, 0, 255),
	AccentLilacMid    = Color3.fromRGB(165, 0, 210),
	AccentLilacDeep   = Color3.fromRGB(120, 0, 160),
	SliderFillLeft    = Color3.fromRGB(207, 0, 255),
	SliderFillRight   = Color3.fromRGB(165, 0, 210),
	DropListTop       = Color3.fromRGB(38, 16, 48),
	DropListMid       = Color3.fromRGB(25, 10, 32),
	DropListBottom    = Color3.fromRGB(15, 6, 19),
	TextSelectedWhite = Color3.fromRGB(255, 255, 255),
	TextPrimary       = Color3.fromRGB(240, 235, 245),
	TextSecondary     = Color3.fromRGB(170, 150, 185),
	TextMuted         = Color3.fromRGB(125, 105, 135),
}

local ThemedRegistry = {
	WindowGradients       = {},
	CardGradients         = {},
	ElementGradients      = {},
	SubTabActiveGradients = {},
	TabActiveGradients    = {},
	AccentLineGradients   = {},
	SliderGradients       = {},
	DropListGradients     = {},
	MainStrokes           = {},
	CardStrokes           = {},
	ElementStrokes        = {},
	TabActiveStrokes      = {},
	AccentHighlights      = {},
	AccentTexts           = {},
	AccentImages          = {},
	Scrollbars            = {},
	ToggleCheckboxes      = {},
	PrimaryTexts          = {},
	SecondaryTexts        = {},
	MutedTexts            = {},
	DropdownLabels        = {},
}

local activeDropdownClose = nil
local activeSliderBar = nil
local activeSliderInput = nil

local function getIcon(url, name)
	if not url or url == "" then return "" end
	local customAsset = getcustomasset or getsynasset
	if customAsset and writefile and isfile then
		local fileName = name or (url:match("([^/]+)$") or "icon.png")
		if not isfile(fileName) then
			pcall(function()
				writefile(fileName, game:HttpGet(url))
			end)
		end
		if isfile(fileName) then
			return customAsset(fileName)
		end
	end
	return url
end

local customTahomaFont = nil
pcall(function()
	if writefile and isfile and getcustomasset then
		local assetFolder = "EssncePw_Assets"
		if not isfolder(assetFolder) then
			pcall(function() makefolder(assetFolder) end)
		end
		local ttfPath = assetFolder .. "/windows-xp-tahoma.ttf"
		local jsonPath = assetFolder .. "/windows-xp-tahoma.json"

		if not isfile(ttfPath) then
			pcall(function()
				writefile(ttfPath, game:HttpGet("https://github.com/sametexe001/luas/raw/refs/heads/main/fonts/windows-xp-tahoma.ttf"))
			end)
		end
		if not isfile(jsonPath) and isfile(ttfPath) then
			local fontData = {
				name = "Windows-XP-Tahoma",
				faces = { {
					name = "Regular",
					weight = 200,
					style = "Regular",
					assetId = getcustomasset(ttfPath)
				} }
			}
			pcall(function()
				writefile(jsonPath, HttpService:JSONEncode(fontData))
			end)
		end
		if isfile(jsonPath) then
			customTahomaFont = Font.new(getcustomasset(jsonPath))
		end
	end
end)

if customTahomaFont then
	CURRENT_FONT_FACE = customTahomaFont
end

local FontOptionsMap = {
	["SourceSans"] = { Regular = Enum.Font.SourceSans, Bold = Enum.Font.SourceSansBold },
	["Roboto"]     = { Regular = Enum.Font.Roboto, Bold = Enum.Font.RobotoCondensed },
	["Gotham"]     = { Regular = Enum.Font.Gotham, Bold = Enum.Font.GothamBold },
	["Ubuntu"]     = { Regular = Enum.Font.Ubuntu, Bold = Enum.Font.Ubuntu },
	["Arial"]      = { Regular = Enum.Font.Arial, Bold = Enum.Font.ArialBold },
	["Tahoma"]     = { Regular = Enum.Font.SourceSans, Bold = Enum.Font.SourceSansBold, IsCustom = true },
}

local function applyFontToObject(obj)
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) then return end
	if CURRENT_FONT_FACE then
		pcall(function()
			obj.FontFace = CURRENT_FONT_FACE
		end)
	else
		pcall(function()
			if obj.Font == Enum.Font.SourceSansBold or obj.Font == Enum.Font.GothamBold or obj.Font == Enum.Font.RobotoCondensed or obj.Font == Enum.Font.ArialBold then
				obj.Font = FONT_BOLD
			else
				obj.Font = FONT
			end
		end)
	end
end

local function applyGlobalFont(screenGui, fontName)
	local cfg = FontOptionsMap[fontName]
	if not cfg then return end

	if cfg.IsCustom and customTahomaFont then
		CURRENT_FONT_FACE = customTahomaFont
	else
		CURRENT_FONT_FACE = nil
		FONT = cfg.Regular
		FONT_BOLD = cfg.Bold
	end

	for _, obj in ipairs(screenGui:GetDescendants()) do
		applyFontToObject(obj)
	end
end

local function enableDrag(handle, targetFrame)
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Library:CreateWindow(config)
	config = config or {}
	local titleName = config.Name or config.Title or "EssncePw"
	local cfgFolder = config.ConfigFolder or "EssncePw_Configs"
	local defaultAccent = config.Accent or DEFAULT_ACCENT

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = titleName
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 2147483647

	pcall(function()
		ScreenGui.Parent = (gethui and gethui()) or CoreGui
	end)
	if not ScreenGui.Parent then
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	ScreenGui.DescendantAdded:Connect(function(obj)
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			applyFontToObject(obj)
			task.defer(function()
				if obj and obj.Parent then
					applyFontToObject(obj)
				end
			end)
		end
	end)

	local ConfigFeatureEntries = {}
	local FallbackConfigStore = {}
	local selectedConfigFileName = "default.json"
	local refreshConfigListDisplay

	local function ensureConfigFolder()
		if makefolder and isfolder then
			if not isfolder(cfgFolder) then
				pcall(function() makefolder(cfgFolder) end)
			end
		end
	end
	ensureConfigFolder()

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Size = UDim2.new(0, 740, 0, 640)
	MainFrame.Position = UDim2.new(0.5, 0, 0.42, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = false
	MainFrame.ZIndex = 10
	MainFrame.Parent = ScreenGui

	enableDrag(MainFrame, MainFrame)

	local mainGradient = Instance.new("UIGradient")
	mainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.WindowBgTop),
		ColorSequenceKeypoint.new(1, THEME.WindowBgBottom)
	})
	mainGradient.Rotation = 90
	mainGradient.Parent = MainFrame
	table.insert(ThemedRegistry.WindowGradients, mainGradient)

	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = THEME.BorderMain
	MainStroke.Thickness = 1.4
	MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MainStroke.Parent = MainFrame
	table.insert(ThemedRegistry.MainStrokes, MainStroke)

	local UiScale = Instance.new("UIScale")
	UiScale.Parent = MainFrame

	local function updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			local vp = camera.ViewportSize
			local scaleX = (vp.X - 16) / 740
			local scaleY = (vp.Y - 16) / 640
			UiScale.Scale = math.clamp(math.min(scaleX, scaleY, 1.25), 0.50, 1.35)
		end
	end
	updateScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	local TopTitle = Instance.new("TextLabel")
	TopTitle.Text = titleName
	TopTitle.Font = FONT
	TopTitle.TextSize = 14
	TopTitle.TextColor3 = THEME.TextSecondary
	TopTitle.TextXAlignment = Enum.TextXAlignment.Left
	TopTitle.BackgroundTransparency = 1
	TopTitle.Position = UDim2.new(0, 14, 0, 8)
	TopTitle.Size = UDim2.new(1, -28, 0, 16)
	TopTitle.ZIndex = 5
	TopTitle.Parent = MainFrame
	enableDrag(TopTitle, MainFrame)
	table.insert(ThemedRegistry.SecondaryTexts, TopTitle)

	local TabsHolder = Instance.new("Frame")
	TabsHolder.BackgroundTransparency = 1
	TabsHolder.Position = UDim2.new(0, 14, 0, 28)
	TabsHolder.Size = UDim2.new(1, -28, 0, 28)
	TabsHolder.Parent = MainFrame

	local TabsLayout = Instance.new("UIListLayout")
	TabsLayout.FillDirection = Enum.FillDirection.Horizontal
	TabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabsLayout.Padding = UDim.new(0, 4)
	TabsLayout.Parent = TabsHolder

	local SubHeaderBar = Instance.new("Frame")
	SubHeaderBar.BackgroundColor3 = Color3.fromRGB(15, 11, 20)
	SubHeaderBar.BorderSizePixel = 0
	SubHeaderBar.Position = UDim2.new(0, 14, 0, 62)
	SubHeaderBar.Size = UDim2.new(1, -28, 0, 44)
	SubHeaderBar.ClipsDescendants = true
	SubHeaderBar.Parent = MainFrame

	local subBarGrad = Instance.new("UIGradient")
	subBarGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
		ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
	})
	subBarGrad.Rotation = 90
	subBarGrad.Parent = SubHeaderBar
	table.insert(ThemedRegistry.ElementGradients, subBarGrad)

	local subBarStroke = Instance.new("UIStroke")
	subBarStroke.Color = THEME.BorderCard
	subBarStroke.Thickness = 1
	subBarStroke.Parent = SubHeaderBar
	table.insert(ThemedRegistry.CardStrokes, subBarStroke)

	local SubTab1Btn = Instance.new("TextButton")
	SubTab1Btn.Size = UDim2.new(0.5, -3, 1, -6)
	SubTab1Btn.Position = UDim2.new(0, 2, 0, 3)
	SubTab1Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SubTab1Btn.BorderSizePixel = 0
	SubTab1Btn.Text = ""
	SubTab1Btn.AutoButtonColor = false
	SubTab1Btn.ClipsDescendants = true
	SubTab1Btn.Parent = SubHeaderBar

	local subTab1BaseGrad = Instance.new("UIGradient")
	subTab1BaseGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.CardBgTop),
		ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
	})
	subTab1BaseGrad.Rotation = 90
	subTab1BaseGrad.Parent = SubTab1Btn
	table.insert(ThemedRegistry.CardGradients, subTab1BaseGrad)

	local subTab1ActiveOverlay = Instance.new("Frame")
	subTab1ActiveOverlay.Size = UDim2.new(1, 0, 1, 0)
	subTab1ActiveOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	subTab1ActiveOverlay.BorderSizePixel = 0
	subTab1ActiveOverlay.BackgroundTransparency = 0
	subTab1ActiveOverlay.ZIndex = 2
	subTab1ActiveOverlay.Parent = SubTab1Btn

	local subTab1ActiveGrad = Instance.new("UIGradient")
	subTab1ActiveGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 36, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 18, 33))
	})
	subTab1ActiveGrad.Rotation = 90
	subTab1ActiveGrad.Parent = subTab1ActiveOverlay
	table.insert(ThemedRegistry.SubTabActiveGradients, subTab1ActiveGrad)

	local subTab1Stroke = Instance.new("UIStroke")
	subTab1Stroke.Color = THEME.BorderTabActive
	subTab1Stroke.Thickness = 1
	subTab1Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	subTab1Stroke.Parent = SubTab1Btn

	local subTab1Highlight = Instance.new("Frame")
	subTab1Highlight.AnchorPoint = Vector2.new(0.5, 0)
	subTab1Highlight.Position = UDim2.new(0.5, 0, 0, 0)
	subTab1Highlight.Size = UDim2.new(1, 0, 0, 1)
	subTab1Highlight.BackgroundColor3 = THEME.AccentLilacLight
	subTab1Highlight.BorderSizePixel = 0
	subTab1Highlight.ZIndex = 5
	subTab1Highlight.Parent = SubTab1Btn

	local subTab1Icon = Instance.new("ImageLabel")
	subTab1Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	subTab1Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	subTab1Icon.Size = UDim2.new(0, 24, 0, 24)
	subTab1Icon.BackgroundTransparency = 1
	subTab1Icon.Image = ""
	subTab1Icon.ImageColor3 = THEME.AccentLilacLight
	subTab1Icon.ZIndex = 4
	subTab1Icon.Parent = SubTab1Btn

	local subTab1Label = Instance.new("TextLabel")
	subTab1Label.Text = "❖"
	subTab1Label.Font = FONT_BOLD
	subTab1Label.TextSize = 22
	subTab1Label.TextColor3 = THEME.AccentLilacLight
	subTab1Label.BackgroundTransparency = 1
	subTab1Label.AnchorPoint = Vector2.new(0.5, 0.5)
	subTab1Label.Position = UDim2.new(0.5, 0, 0.5, 0)
	subTab1Label.Size = UDim2.new(1, 0, 1, 0)
	subTab1Label.ZIndex = 4
	subTab1Label.Visible = true
	subTab1Label.Parent = SubTab1Btn

	subTab1Icon:GetPropertyChangedSignal("Image"):Connect(function()
		subTab1Label.Visible = (subTab1Icon.Image == "")
	end)

	local SubTab2Btn = Instance.new("TextButton")
	SubTab2Btn.Size = UDim2.new(0.5, -3, 1, -6)
	SubTab2Btn.Position = UDim2.new(0.5, 1, 0, 3)
	SubTab2Btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SubTab2Btn.BorderSizePixel = 0
	SubTab2Btn.Text = ""
	SubTab2Btn.AutoButtonColor = false
	SubTab2Btn.ClipsDescendants = true
	SubTab2Btn.Parent = SubHeaderBar

	local subTab2BaseGrad = Instance.new("UIGradient")
	subTab2BaseGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.CardBgTop),
		ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
	})
	subTab2BaseGrad.Rotation = 90
	subTab2BaseGrad.Parent = SubTab2Btn
	table.insert(ThemedRegistry.CardGradients, subTab2BaseGrad)

	local subTab2ActiveOverlay = Instance.new("Frame")
	subTab2ActiveOverlay.Size = UDim2.new(1, 0, 1, 0)
	subTab2ActiveOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	subTab2ActiveOverlay.BorderSizePixel = 0
	subTab2ActiveOverlay.BackgroundTransparency = 1
	subTab2ActiveOverlay.ZIndex = 2
	subTab2ActiveOverlay.Parent = SubTab2Btn

	local subTab2ActiveGrad = Instance.new("UIGradient")
	subTab2ActiveGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 36, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 18, 33))
	})
	subTab2ActiveGrad.Rotation = 90
	subTab2ActiveGrad.Parent = subTab2ActiveOverlay
	table.insert(ThemedRegistry.SubTabActiveGradients, subTab2ActiveGrad)

	local subTab2Stroke = Instance.new("UIStroke")
	subTab2Stroke.Color = THEME.BorderCard
	subTab2Stroke.Thickness = 1
	subTab2Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	subTab2Stroke.Parent = SubTab2Btn

	local subTab2Highlight = Instance.new("Frame")
	subTab2Highlight.AnchorPoint = Vector2.new(0.5, 0)
	subTab2Highlight.Position = UDim2.new(0.5, 0, 0, 0)
	subTab2Highlight.Size = UDim2.new(0, 0, 0, 1)
	subTab2Highlight.BackgroundColor3 = THEME.AccentLilacLight
	subTab2Highlight.BorderSizePixel = 0
	subTab2Highlight.BackgroundTransparency = 1
	subTab2Highlight.ZIndex = 5
	subTab2Highlight.Parent = SubTab2Btn

	local subTab2Icon = Instance.new("ImageLabel")
	subTab2Icon.AnchorPoint = Vector2.new(0.5, 0.5)
	subTab2Icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	subTab2Icon.Size = UDim2.new(0, 20, 0, 20)
	subTab2Icon.BackgroundTransparency = 1
	subTab2Icon.Image = ""
	subTab2Icon.ImageColor3 = THEME.TextSecondary
	subTab2Icon.ZIndex = 4
	subTab2Icon.Parent = SubTab2Btn

	local subTab2Label = Instance.new("TextLabel")
	subTab2Label.Text = "☁"
	subTab2Label.Font = FONT_BOLD
	subTab2Label.TextSize = 22
	subTab2Label.TextColor3 = THEME.TextSecondary
	subTab2Label.BackgroundTransparency = 1
	subTab2Label.AnchorPoint = Vector2.new(0.5, 0.5)
	subTab2Label.Position = UDim2.new(0.5, 0, 0.5, 0)
	subTab2Label.Size = UDim2.new(1, 0, 1, 0)
	subTab2Label.ZIndex = 4
	subTab2Label.Visible = true
	subTab2Label.Parent = SubTab2Btn

	subTab2Icon:GetPropertyChangedSignal("Image"):Connect(function()
		subTab2Label.Visible = (subTab2Icon.Image == "")
	end)

	local ContentArea = Instance.new("Frame")
	ContentArea.BackgroundTransparency = 1
	ContentArea.Position = UDim2.new(0, 14, 0, 114)
	ContentArea.Size = UDim2.new(1, -28, 0, 512)
	ContentArea.ClipsDescendants = false
	ContentArea.Parent = MainFrame

	local currentMainTab = nil
	local currentSubIndex = 1
	local TabButtons = {}
	local TabPages = {}
	local TabSubConfig = {}
	local savedSubTabs = {}

	local subAnimInfo = TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function updateActiveSubTabVisual()
		local isFirst = (currentSubIndex == 1)
		subTab1Stroke.Color = isFirst and THEME.BorderTabActive or THEME.BorderCard
		subTab1Highlight.BackgroundColor3 = THEME.AccentLilacLight
		subTab1Label.TextColor3 = isFirst and THEME.AccentLilacLight or THEME.TextSecondary
		subTab1Icon.ImageColor3 = isFirst and THEME.AccentLilacLight or THEME.TextSecondary

		subTab2Stroke.Color = (not isFirst) and THEME.BorderTabActive or THEME.BorderCard
		subTab2Highlight.BackgroundColor3 = THEME.AccentLilacLight
		subTab2Label.TextColor3 = (not isFirst) and THEME.AccentLilacLight or THEME.TextSecondary
		subTab2Icon.ImageColor3 = (not isFirst) and THEME.AccentLilacLight or THEME.TextSecondary
	end

	local function applyAccentColor(chosenColor)
		local h, s, v = chosenColor:ToHSV()
		if s < 0.04 then
			if v < 0.08 then
				THEME.AccentLilacLight = Color3.fromRGB(90, 90, 90)
				THEME.AccentLilacMid   = Color3.fromRGB(60, 60, 60)
				THEME.AccentLilacDeep  = Color3.fromRGB(40, 40, 40)
				THEME.SliderFillLeft   = Color3.fromRGB(90, 90, 90)
				THEME.SliderFillRight  = Color3.fromRGB(50, 50, 50)
				THEME.BorderMain       = Color3.fromRGB(75, 75, 75)
				THEME.BorderTabActive  = Color3.fromRGB(55, 55, 55)
				THEME.BorderElement    = Color3.fromRGB(40, 40, 40)
				THEME.BorderCard       = Color3.fromRGB(30, 30, 30)
				THEME.WindowBgTop      = Color3.fromRGB(18, 18, 18)
				THEME.WindowBgBottom   = Color3.fromRGB(10, 10, 10)
				THEME.CardBgTop        = Color3.fromRGB(20, 20, 20)
				THEME.CardBgBottom     = Color3.fromRGB(12, 12, 12)
				THEME.ElementBgTop     = Color3.fromRGB(22, 22, 22)
				THEME.ElementBgBottom  = Color3.fromRGB(14, 14, 14)
				THEME.DropListTop      = Color3.fromRGB(24, 24, 24)
				THEME.DropListMid      = Color3.fromRGB(16, 16, 16)
				THEME.DropListBottom   = Color3.fromRGB(10, 10, 10)
				THEME.TextPrimary      = Color3.fromRGB(240, 240, 240)
				THEME.TextSecondary    = Color3.fromRGB(160, 160, 160)
				THEME.TextMuted        = Color3.fromRGB(115, 115, 115)
			else
				THEME.AccentLilacLight = Color3.fromRGB(255, 255, 255)
				THEME.AccentLilacMid   = Color3.fromRGB(215, 215, 215)
				THEME.AccentLilacDeep  = Color3.fromRGB(170, 170, 170)
				THEME.SliderFillLeft   = Color3.fromRGB(255, 255, 255)
				THEME.SliderFillRight  = Color3.fromRGB(200, 200, 200)
				THEME.BorderMain       = Color3.fromRGB(210, 210, 210)
				THEME.BorderTabActive  = Color3.fromRGB(140, 140, 140)
				THEME.BorderElement    = Color3.fromRGB(70, 70, 70)
				THEME.BorderCard       = Color3.fromRGB(50, 50, 50)
				THEME.WindowBgTop      = Color3.fromRGB(24, 24, 24)
				THEME.WindowBgBottom   = Color3.fromRGB(14, 14, 14)
				THEME.CardBgTop        = Color3.fromRGB(26, 26, 26)
				THEME.CardBgBottom     = Color3.fromRGB(16, 16, 16)
				THEME.ElementBgTop     = Color3.fromRGB(30, 30, 30)
				THEME.ElementBgBottom  = Color3.fromRGB(18, 18, 18)
				THEME.DropListTop      = Color3.fromRGB(32, 32, 32)
				THEME.DropListMid      = Color3.fromRGB(22, 22, 22)
				THEME.DropListBottom   = Color3.fromRGB(14, 14, 14)
				THEME.TextPrimary      = Color3.fromRGB(245, 245, 245)
				THEME.TextSecondary    = Color3.fromRGB(165, 165, 165)
				THEME.TextMuted        = Color3.fromRGB(120, 120, 120)
			end
		else
			THEME.AccentLilacLight = Color3.fromHSV(h, math.clamp(s * 0.90, 0.15, 1), math.clamp(v * 1.00, 0.70, 1))
			THEME.AccentLilacMid   = Color3.fromHSV(h, math.clamp(s * 0.95, 0.20, 1), math.clamp(v * 0.82, 0.50, 0.90))
			THEME.AccentLilacDeep  = Color3.fromHSV(h, math.clamp(s * 1.00, 0.25, 1), math.clamp(v * 0.62, 0.35, 0.75))
			THEME.SliderFillLeft   = THEME.AccentLilacLight
			THEME.SliderFillRight  = THEME.AccentLilacMid
			THEME.BorderMain       = Color3.fromHSV(h, math.clamp(s * 0.75, 0.15, 0.90), math.clamp(v * 0.85, 0.50, 0.90))
			THEME.BorderTabActive  = Color3.fromHSV(h, math.clamp(s * 0.55, 0.10, 0.70), 0.48)
			THEME.BorderElement    = Color3.fromHSV(h, math.clamp(s * 0.45, 0.08, 0.60), 0.32)
			THEME.BorderCard       = Color3.fromHSV(h, math.clamp(s * 0.45, 0.08, 0.60), 0.26)
			THEME.WindowBgTop      = Color3.fromHSV(h, math.clamp(s * 0.35, 0.04, 0.45), 0.12)
			THEME.WindowBgBottom   = Color3.fromHSV(h, math.clamp(s * 0.40, 0.04, 0.50), 0.065)
			THEME.CardBgTop        = Color3.fromHSV(h, math.clamp(s * 0.35, 0.04, 0.45), 0.13)
			THEME.CardBgBottom     = Color3.fromHSV(h, math.clamp(s * 0.40, 0.04, 0.50), 0.08)
			THEME.ElementBgTop     = Color3.fromHSV(h, math.clamp(s * 0.35, 0.04, 0.45), 0.14)
			THEME.ElementBgBottom  = Color3.fromHSV(h, math.clamp(s * 0.40, 0.04, 0.50), 0.09)
			THEME.DropListTop      = Color3.fromHSV(h, math.clamp(s * 0.40, 0.06, 0.55), 0.18)
			THEME.DropListMid      = Color3.fromHSV(h, math.clamp(s * 0.40, 0.06, 0.55), 0.12)
			THEME.DropListBottom   = Color3.fromHSV(h, math.clamp(s * 0.40, 0.06, 0.55), 0.07)
			THEME.TextPrimary      = Color3.fromHSV(h, math.clamp(s * 0.06, 0.01, 0.10), 0.96)
			THEME.TextSecondary    = Color3.fromHSV(h, math.clamp(s * 0.10, 0.02, 0.18), 0.72)
			THEME.TextMuted        = Color3.fromHSV(h, math.clamp(s * 0.12, 0.03, 0.20), 0.52)
		end

		for _, grad in ipairs(ThemedRegistry.WindowGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.WindowBgTop),
					ColorSequenceKeypoint.new(1, THEME.WindowBgBottom)
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.CardGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.CardBgTop),
					ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.ElementGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
					ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.SubTabActiveGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, s < 0.04 and Color3.fromRGB(40, 40, 40) or Color3.fromHSV(h, math.clamp(s * 0.40, 0.08, 0.55), 0.24)),
					ColorSequenceKeypoint.new(1, s < 0.04 and Color3.fromRGB(22, 22, 22) or Color3.fromHSV(h, math.clamp(s * 0.42, 0.08, 0.55), 0.14))
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.TabActiveGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, s < 0.04 and Color3.fromRGB(42, 42, 42) or Color3.fromHSV(h, math.clamp(s * 0.40, 0.08, 0.55), 0.24)),
					ColorSequenceKeypoint.new(1, s < 0.04 and Color3.fromRGB(24, 24, 24) or Color3.fromHSV(h, math.clamp(s * 0.42, 0.08, 0.55), 0.14))
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.AccentLineGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
					ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),
					ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.SliderGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.SliderFillLeft),
					ColorSequenceKeypoint.new(1, THEME.SliderFillRight)
				})
			end
		end
		for _, grad in ipairs(ThemedRegistry.DropListGradients) do
			if grad and grad.Parent then
				grad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.DropListTop),
					ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
					ColorSequenceKeypoint.new(1, THEME.DropListBottom)
				})
			end
		end
		for _, stroke in ipairs(ThemedRegistry.MainStrokes) do
			if stroke and stroke.Parent then stroke.Color = THEME.BorderMain end
		end
		for _, stroke in ipairs(ThemedRegistry.CardStrokes) do
			if stroke and stroke.Parent then stroke.Color = THEME.BorderCard end
		end
		for _, stroke in ipairs(ThemedRegistry.ElementStrokes) do
			if stroke and stroke.Parent then stroke.Color = THEME.BorderElement end
		end
		for _, stroke in ipairs(ThemedRegistry.TabActiveStrokes) do
			if stroke and stroke.Parent then stroke.Color = THEME.BorderTabActive end
		end
		for _, frame in ipairs(ThemedRegistry.AccentHighlights) do
			if frame and frame.Parent then frame.BackgroundColor3 = THEME.AccentLilacLight end
		end
		for _, text in ipairs(ThemedRegistry.AccentTexts) do
			if text and text.Parent then text.TextColor3 = THEME.AccentLilacLight end
		end
		for _, img in ipairs(ThemedRegistry.AccentImages) do
			if img and img.Parent then img.ImageColor3 = THEME.AccentLilacLight end
		end
		for _, scroll in ipairs(ThemedRegistry.Scrollbars) do
			if scroll and scroll.Parent then scroll.ScrollBarImageColor3 = THEME.AccentLilacLight end
		end
		for _, text in ipairs(ThemedRegistry.PrimaryTexts) do
			if text and text.Parent then text.TextColor3 = THEME.TextPrimary end
		end
		for _, text in ipairs(ThemedRegistry.SecondaryTexts) do
			if text and text.Parent then text.TextColor3 = THEME.TextSecondary end
		end
		for _, text in ipairs(ThemedRegistry.MutedTexts) do
			if text and text.Parent then
				if text:IsA("TextBox") then
					text.PlaceholderColor3 = THEME.TextMuted
				else
					text.TextColor3 = THEME.TextMuted
				end
			end
		end
		for _, item in ipairs(ThemedRegistry.DropdownLabels) do
			if item and item.Label and item.Label.Parent then
				if item.IsActive and item.IsActive() then
					item.Label.TextColor3 = THEME.TextSelectedWhite
				else
					item.Label.TextColor3 = THEME.TextMuted
				end
			end
		end
		for _, fn in ipairs(ThemedRegistry.ToggleCheckboxes) do
			pcall(fn)
		end
		updateActiveSubTabVisual()
		for name, data in pairs(TabButtons) do
			if name == currentMainTab then
				data.Stroke.Color = THEME.BorderTabActive
				data.Highlight.BackgroundColor3 = THEME.AccentLilacLight
				data.Label.TextColor3 = THEME.TextPrimary
			else
				data.Stroke.Color = THEME.BorderCard
				data.Label.TextColor3 = THEME.TextSecondary
			end
		end
		if refreshConfigListDisplay then
			refreshConfigListDisplay()
		end
	end

	local function switchSubTab(subIndex)
		if activeDropdownClose then activeDropdownClose() end
		currentSubIndex = subIndex
		savedSubTabs[currentMainTab] = subIndex

		local cfg = TabSubConfig[currentMainTab] or {}
		local item1 = cfg[1]
		local item2 = cfg[2]

		if item1 and item1.page then item1.page.Visible = (subIndex == 1) end
		if item2 and item2.page then item2.page.Visible = (subIndex == 2) end

		local isFirst = (subIndex == 1)
		local targetSize1 = isFirst and (item1 and item1.sizeActive or 24) or (item1 and item1.sizeInactive or 20)
		local targetSize2 = (not isFirst) and (item2 and item2.sizeActive or 24) or (item2 and item2.sizeInactive or 20)

		TweenService:Create(subTab1ActiveOverlay, subAnimInfo, {BackgroundTransparency = isFirst and 0 or 1}):Play()
		TweenService:Create(subTab1Stroke, subAnimInfo, {Color = isFirst and THEME.BorderTabActive or THEME.BorderCard}):Play()
		TweenService:Create(subTab1Label, subAnimInfo, {
			TextColor3 = isFirst and THEME.AccentLilacLight or THEME.TextSecondary,
			TextSize = isFirst and 24 or 20
		}):Play()
		TweenService:Create(subTab1Icon, subAnimInfo, {
			ImageColor3 = isFirst and THEME.AccentLilacLight or THEME.TextSecondary,
			Size = UDim2.new(0, targetSize1, 0, targetSize1)
		}):Play()
		TweenService:Create(subTab1Highlight, subAnimInfo, {
			Size = isFirst and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 0, 0, 1),
			BackgroundTransparency = isFirst and 0 or 1
		}):Play()

		TweenService:Create(subTab2ActiveOverlay, subAnimInfo, {BackgroundTransparency = (not isFirst) and 0 or 1}):Play()
		TweenService:Create(subTab2Stroke, subAnimInfo, {Color = (not isFirst) and THEME.BorderTabActive or THEME.BorderCard}):Play()
		TweenService:Create(subTab2Label, subAnimInfo, {
			TextColor3 = (not isFirst) and THEME.AccentLilacLight or THEME.TextSecondary,
			TextSize = (not isFirst) and 24 or 20
		}):Play()
		TweenService:Create(subTab2Icon, subAnimInfo, {
			ImageColor3 = (not isFirst) and THEME.AccentLilacLight or THEME.TextSecondary,
			Size = UDim2.new(0, targetSize2, 0, targetSize2)
		}):Play()
		TweenService:Create(subTab2Highlight, subAnimInfo, {
			Size = (not isFirst) and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 0, 0, 1),
			BackgroundTransparency = (not isFirst) and 0 or 1
		}):Play()
	end

	SubTab1Btn.MouseButton1Click:Connect(function()
		switchSubTab(1)
	end)

	SubTab2Btn.MouseButton1Click:Connect(function()
		local cfg = TabSubConfig[currentMainTab] or {}
		if #cfg > 1 then
			switchSubTab(2)
		end
	end)

	local function updateSubTabsForMainTab(mainTabName)
		currentMainTab = mainTabName
		local cfg = TabSubConfig[mainTabName] or { { iconText = "❖", iconImg = "", page = nil } }
		local subCount = #cfg
		local resizeInfo = TweenInfo.new(0.26, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

		if subCount <= 1 then
			subTab1Label.Text = cfg[1] and cfg[1].iconText or "❖"
			subTab1Icon.Image = cfg[1] and cfg[1].iconImg or ""
			subTab1Label.Visible = (subTab1Icon.Image == "")

			TweenService:Create(SubTab1Btn, resizeInfo, {
				Size = UDim2.new(1, -4, 1, -6),
				Position = UDim2.new(0, 2, 0, 3)
			}):Play()

			local t2 = TweenService:Create(SubTab2Btn, resizeInfo, {
				Size = UDim2.new(0, 0, 1, -6),
				Position = UDim2.new(1, -2, 0, 3)
			})
			t2:Play()
			t2.Completed:Connect(function()
				if #TabSubConfig[currentMainTab] <= 1 then
					SubTab2Btn.Visible = false
				end
			end)
			switchSubTab(1)
		else
			SubTab2Btn.Visible = true
			subTab1Label.Text = cfg[1].iconText or "❖"
			subTab1Icon.Image = cfg[1].iconImg or ""
			subTab1Label.Visible = (subTab1Icon.Image == "")

			subTab2Label.Text = cfg[2].iconText or "☁"
			subTab2Icon.Image = cfg[2].iconImg or ""
			subTab2Label.Visible = (subTab2Icon.Image == "")

			TweenService:Create(SubTab1Btn, resizeInfo, {
				Size = UDim2.new(0.5, -3, 1, -6),
				Position = UDim2.new(0, 2, 0, 3)
			}):Play()

			TweenService:Create(SubTab2Btn, resizeInfo, {
				Size = UDim2.new(0.5, -3, 1, -6),
				Position = UDim2.new(0.5, 1, 0, 3)
			}):Play()

			local activeSub = savedSubTabs[mainTabName] or 1
			switchSubTab(activeSub)
		end
	end

	local tabAnimInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function switchTab(targetName)
		if activeDropdownClose then activeDropdownClose() end
		for name, page in pairs(TabPages) do
			page.Visible = (name == targetName)
		end
		for name, data in pairs(TabButtons) do
			local isActive = (name == targetName)
			TweenService:Create(data.Highlight, tabAnimInfo, {
				Size = isActive and UDim2.new(1, 0, 0, 1) or UDim2.new(0, 0, 0, 1),
				BackgroundTransparency = isActive and 0 or 1
			}):Play()
			TweenService:Create(data.Stroke, tabAnimInfo, {
				Color = isActive and THEME.BorderTabActive or THEME.BorderCard
			}):Play()
			TweenService:Create(data.Label, tabAnimInfo, {
				TextColor3 = isActive and THEME.TextPrimary or THEME.TextSecondary
			}):Play()
			TweenService:Create(data.ActiveOverlay, tabAnimInfo, {
				BackgroundTransparency = isActive and 0 or 1
			}):Play()
		end
		updateSubTabsForMainTab(targetName)
	end

	local function createSingleColorPicker(parentRow, offsetX, defaultColor, onColorChanged)
		local cpSlot = Instance.new("Frame")
		cpSlot.Size = UDim2.new(0, 32, 0, 13)
		cpSlot.Position = UDim2.new(1, offsetX, 0.5, -6)
		cpSlot.BackgroundColor3 = Color3.fromRGB(15, 11, 20)
		cpSlot.BorderSizePixel = 0
		cpSlot.Parent = parentRow

		local cpCorner = Instance.new("UICorner")
		cpCorner.CornerRadius = UDim.new(0, 3)
		cpCorner.Parent = cpSlot

		local cpSlotStroke = Instance.new("UIStroke")
		cpSlotStroke.Color = THEME.BorderElement
		cpSlotStroke.Thickness = 1
		cpSlotStroke.Parent = cpSlot
		table.insert(ThemedRegistry.ElementStrokes, cpSlotStroke)

		local cpFill = Instance.new("Frame")
		cpFill.Size = UDim2.new(1, -2, 1, -2)
		cpFill.Position = UDim2.new(0, 1, 0, 1)
		cpFill.BackgroundColor3 = defaultColor or Color3.fromRGB(255, 255, 255)
		cpFill.BorderSizePixel = 0
		cpFill.Parent = cpSlot

		local cpFillCorner = Instance.new("UICorner")
		cpFillCorner.CornerRadius = UDim.new(0, 2)
		cpFillCorner.Parent = cpFill

		local cpFillGrad = Instance.new("UIGradient")
		cpFillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))
		})
		cpFillGrad.Rotation = 90
		cpFillGrad.Parent = cpFill

		local cpBtn = Instance.new("TextButton")
		cpBtn.Size = UDim2.new(1, 8, 1, 10)
		cpBtn.Position = UDim2.new(0, -4, 0, -5)
		cpBtn.BackgroundTransparency = 1
		cpBtn.Text = ""
		cpBtn.AutoButtonColor = false
		cpBtn.ZIndex = 15
		cpBtn.Parent = cpSlot

		local pickerFrame = Instance.new("Frame")
		pickerFrame.Name = "ColorPickerPalette"
		pickerFrame.Size = UDim2.new(0, 162, 0, 0)
		pickerFrame.Position = UDim2.new(1, -162, 1, 4)
		pickerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pickerFrame.BorderSizePixel = 0
		pickerFrame.ClipsDescendants = true
		pickerFrame.Visible = false
		pickerFrame.Active = true
		pickerFrame.ZIndex = 150
		pickerFrame.Parent = cpSlot

		local pickerGrad = Instance.new("UIGradient")
		pickerGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.DropListTop),
			ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
			ColorSequenceKeypoint.new(1, THEME.DropListBottom)
		})
		pickerGrad.Rotation = 90
		pickerGrad.Parent = pickerFrame
		table.insert(ThemedRegistry.DropListGradients, pickerGrad)

		local pickerStroke = Instance.new("UIStroke")
		pickerStroke.Color = THEME.BorderCard
		pickerStroke.Thickness = 1
		pickerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pickerStroke.Parent = pickerFrame
		table.insert(ThemedRegistry.CardStrokes, pickerStroke)

		local pickerTopLine = Instance.new("Frame")
		pickerTopLine.Size = UDim2.new(1, 0, 0, 1)
		pickerTopLine.Position = UDim2.new(0, 0, 0, 0)
		pickerTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pickerTopLine.BorderSizePixel = 0
		pickerTopLine.ZIndex = 155
		pickerTopLine.Parent = pickerFrame

		local pickerTopGrad = Instance.new("UIGradient")
		pickerTopGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))
		})
		pickerTopGrad.Parent = pickerTopLine
		table.insert(ThemedRegistry.AccentLineGradients, pickerTopGrad)

		local svMap = Instance.new("TextButton")
		svMap.Name = "SvMap"
		svMap.Size = UDim2.new(0, 124, 0, 106)
		svMap.Position = UDim2.new(0, 7, 0, 8)
		svMap.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		svMap.BorderSizePixel = 0
		svMap.Text = ""
		svMap.AutoButtonColor = false
		svMap.ClipsDescendants = true
		svMap.ZIndex = 151
		svMap.Parent = pickerFrame

		local svStroke = Instance.new("UIStroke")
		svStroke.Color = THEME.BorderElement
		svStroke.Thickness = 1
		svStroke.Parent = svMap
		table.insert(ThemedRegistry.ElementStrokes, svStroke)

		local satOverlay = Instance.new("Frame")
		satOverlay.Size = UDim2.new(1, 0, 1, 0)
		satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		satOverlay.BorderSizePixel = 0
		satOverlay.Active = false
		satOverlay.ZIndex = 152
		satOverlay.Parent = svMap

		local satGrad = Instance.new("UIGradient")
		satGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1)
		})
		satGrad.Rotation = 0
		satGrad.Parent = satOverlay

		local valOverlay = Instance.new("Frame")
		valOverlay.Size = UDim2.new(1, 0, 1, 0)
		valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		valOverlay.BorderSizePixel = 0
		valOverlay.Active = false
		valOverlay.ZIndex = 153
		valOverlay.Parent = svMap

		local valGrad = Instance.new("UIGradient")
		valGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		valGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		})
		valGrad.Rotation = 90
		valGrad.Parent = valOverlay

		local svCursor = Instance.new("Frame")
		svCursor.Size = UDim2.new(0, 5, 0, 5)
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		svCursor.BorderSizePixel = 0
		svCursor.ZIndex = 154
		svCursor.Parent = svMap

		local svCursorStroke = Instance.new("UIStroke")
		svCursorStroke.Color = Color3.fromRGB(15, 11, 20)
		svCursorStroke.Thickness = 1
		svCursorStroke.Parent = svCursor

		local hueBar = Instance.new("TextButton")
		hueBar.Name = "HueBar"
		hueBar.Size = UDim2.new(0, 14, 0, 106)
		hueBar.Position = UDim2.new(0, 139, 0, 8)
		hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueBar.BorderSizePixel = 0
		hueBar.Text = ""
		hueBar.AutoButtonColor = false
		hueBar.ClipsDescendants = false
		hueBar.ZIndex = 151
		hueBar.Parent = pickerFrame

		local hueStroke = Instance.new("UIStroke")
		hueStroke.Color = THEME.BorderElement
		hueStroke.Thickness = 1
		hueStroke.Parent = hueBar
		table.insert(ThemedRegistry.ElementStrokes, hueStroke)

		local hueGrad = Instance.new("UIGradient")
		hueGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		})
		hueGrad.Rotation = 90
		hueGrad.Parent = hueBar

		local hueCursor = Instance.new("Frame")
		hueCursor.Size = UDim2.new(1, 2, 0, 2)
		hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueCursor.BorderSizePixel = 0
		hueCursor.ZIndex = 154
		hueCursor.Parent = hueBar

		local hueCursorStroke = Instance.new("UIStroke")
		hueCursorStroke.Color = Color3.fromRGB(15, 11, 20)
		hueCursorStroke.Thickness = 1
		hueCursorStroke.Parent = hueCursor

		local previewBox = Instance.new("Frame")
		previewBox.Size = UDim2.new(0, 22, 0, 16)
		previewBox.Position = UDim2.new(0, 7, 0, 120)
		previewBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		previewBox.BorderSizePixel = 0
		previewBox.ZIndex = 151
		previewBox.Parent = pickerFrame

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 2)
		previewCorner.Parent = previewBox

		local previewStroke = Instance.new("UIStroke")
		previewStroke.Color = THEME.BorderElement
		previewStroke.Thickness = 1
		previewStroke.Parent = previewBox
		table.insert(ThemedRegistry.ElementStrokes, previewStroke)

		local previewGrad = Instance.new("UIGradient")
		previewGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160))
		})
		previewGrad.Rotation = 90
		previewGrad.Parent = previewBox

		local hexLabel = Instance.new("TextLabel")
		hexLabel.Font = FONT
		hexLabel.TextSize = 12
		hexLabel.TextColor3 = THEME.TextSecondary
		hexLabel.TextXAlignment = Enum.TextXAlignment.Left
		hexLabel.BackgroundTransparency = 1
		hexLabel.Position = UDim2.new(0, 35, 0, 120)
		hexLabel.Size = UDim2.new(1, -42, 0, 16)
		hexLabel.ZIndex = 151
		hexLabel.Parent = pickerFrame
		table.insert(ThemedRegistry.SecondaryTexts, hexLabel)

		local initH, initS, initV = (defaultColor or DEFAULT_ACCENT):ToHSV()
		local currentH, currentS, currentV = initH, initS, initV

		local function updateColorOutput(fireCb)
			local selectedCol = Color3.fromHSV(currentH, currentS, currentV)
			cpFill.BackgroundColor3 = selectedCol
			previewBox.BackgroundColor3 = selectedCol
			local r = math.round(selectedCol.R * 255)
			local g = math.round(selectedCol.G * 255)
			local b = math.round(selectedCol.B * 255)
			hexLabel.Text = string.format("#%02X%02X%02X", r, g, b)
			if fireCb ~= false and onColorChanged then
				onColorChanged(selectedCol)
			end
		end
		updateColorOutput(false)

		svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
		hueCursor.Position = UDim2.new(0.5, 0, currentH, 0)
		svMap.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)

		local isDraggingSV = false
		local isDraggingHue = false

		local function updateSV(input)
			local posX = math.clamp(input.Position.X - svMap.AbsolutePosition.X, 0, svMap.AbsoluteSize.X)
			local posY = math.clamp(input.Position.Y - svMap.AbsolutePosition.Y, 0, svMap.AbsoluteSize.Y)
			currentS = posX / svMap.AbsoluteSize.X
			currentV = 1 - (posY / svMap.AbsoluteSize.Y)
			svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
			updateColorOutput(true)
		end

		local function updateHue(input)
			local posY = math.clamp(input.Position.Y - hueBar.AbsolutePosition.Y, 0, hueBar.AbsoluteSize.Y)
			currentH = posY / hueBar.AbsoluteSize.Y
			hueCursor.Position = UDim2.new(0.5, 0, currentH, 0)
			svMap.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
			updateColorOutput(true)
		end

		svMap.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDraggingSV = true
				updateSV(input)
			end
		end)

		hueBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDraggingHue = true
				updateHue(input)
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if isDraggingSV then
					updateSV(input)
				elseif isDraggingHue then
					updateHue(input)
				end
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDraggingSV = false
				isDraggingHue = false
			end
		end)

		local isPickerOpen = false

		local function closePicker()
			if not isPickerOpen then return end
			isPickerOpen = false
			local closeTween = TweenService:Create(pickerFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 162, 0, 0)})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				if not isPickerOpen then
					pickerFrame.Visible = false
					local openCount = math.max(0, (parentRow:GetAttribute("OpenPopups") or 1) - 1)
					parentRow:SetAttribute("OpenPopups", openCount)
					if openCount == 0 then
						parentRow.ZIndex = 1
					end
				end
			end)
			if activeDropdownClose == closePicker then
				activeDropdownClose = nil
			end
		end

		local function openPicker()
			if activeDropdownClose and activeDropdownClose ~= closePicker then
				activeDropdownClose()
			end
			isPickerOpen = true
			activeDropdownClose = closePicker
			local openCount = (parentRow:GetAttribute("OpenPopups") or 0) + 1
			parentRow:SetAttribute("OpenPopups", openCount)
			parentRow.ZIndex = 150
			pickerFrame.Visible = true
			TweenService:Create(pickerFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 162, 0, 144)}):Play()
		end

		cpBtn.MouseButton1Click:Connect(function()
			if isPickerOpen then closePicker() else openPicker() end
		end)

		return {
			SetColor = function(newCol)
				if typeof(newCol) == "Color3" then
					currentH, currentS, currentV = newCol:ToHSV()
					svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
					hueCursor.Position = UDim2.new(0.5, 0, currentH, 0)
					svMap.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
					updateColorOutput(true)
				end
			end,
			GetColor = function()
				return Color3.fromHSV(currentH, currentS, currentV)
			end
		}
	end

	local function createSectionCard(parent, title, sizeY, layoutOrder)
		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, 0, 0, sizeY or 40)
		card.LayoutOrder = layoutOrder or 0
		card.ClipsDescendants = false
		card.Parent = parent

		local cardGrad = Instance.new("UIGradient")
		cardGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.CardBgTop),
			ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
		})
		cardGrad.Rotation = 90
		cardGrad.Parent = card
		table.insert(ThemedRegistry.CardGradients, cardGrad)

		local stroke = Instance.new("UIStroke")
		stroke.Color = THEME.BorderCard
		stroke.Thickness = 1
		stroke.Parent = card
		table.insert(ThemedRegistry.CardStrokes, stroke)

		local topLine = Instance.new("Frame")
		topLine.BorderSizePixel = 0
		topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		topLine.Size = UDim2.new(1, 0, 0, 1)
		topLine.Parent = card

		local lineGrad = Instance.new("UIGradient")
		lineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
		})
		lineGrad.Parent = topLine
		table.insert(ThemedRegistry.AccentLineGradients, lineGrad)

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = FONT
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = THEME.TextPrimary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 10, 0, 4)
		titleLabel.Size = UDim2.new(1, -20, 0, 18)
		titleLabel.ZIndex = 3
		titleLabel.Parent = card
		table.insert(ThemedRegistry.PrimaryTexts, titleLabel)

		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.Position = UDim2.new(0, 10, 0, 24)
		container.Size = UDim2.new(1, -20, 0, 0)
		container.ClipsDescendants = false
		container.Parent = card

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 3)
		layout.Parent = container

		local function updateCardSize()
			local totalH = 0
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("GuiObject") then
					totalH = totalH + child.Size.Y.Offset + layout.Padding.Offset
				end
			end
			if totalH > 0 then
				totalH = totalH - layout.Padding.Offset
			end
			local h = math.max(layout.AbsoluteContentSize.Y, totalH)
			if h > 0 then
				container.Size = UDim2.new(1, -20, 0, h)
				card.Size = UDim2.new(1, 0, 0, h + 32)
			end
		end

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCardSize)
		container.ChildAdded:Connect(function()
			task.defer(updateCardSize)
		end)
		task.defer(updateCardSize)

		return card, container
	end

	local function createTabColumns(pageParent)
		local leftCol = Instance.new("ScrollingFrame")
		leftCol.BackgroundTransparency = 1
		leftCol.Size = UDim2.new(0.49, 0, 1, 0)
		leftCol.Position = UDim2.new(0, 0, 0, 0)
		leftCol.BorderSizePixel = 0
		leftCol.ScrollBarThickness = 3
		leftCol.ScrollBarImageColor3 = THEME.AccentLilacLight
		leftCol.ScrollBarImageTransparency = 0.3
		leftCol.CanvasSize = UDim2.new(0, 0, 0, 0)
		leftCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
		leftCol.ScrollingDirection = Enum.ScrollingDirection.Y
		leftCol.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
		leftCol.ClipsDescendants = false
		leftCol.Parent = pageParent
		table.insert(ThemedRegistry.Scrollbars, leftCol)

		local leftPad = Instance.new("UIPadding")
		leftPad.PaddingRight = UDim.new(0, 6)
		leftPad.Parent = leftCol

		local leftLayout = Instance.new("UIListLayout")
		leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		leftLayout.Padding = UDim.new(0, 8)
		leftLayout.Parent = leftCol

		local rightCol = Instance.new("ScrollingFrame")
		rightCol.BackgroundTransparency = 1
		rightCol.Size = UDim2.new(0.49, 0, 1, 0)
		rightCol.Position = UDim2.new(0.51, 0, 0, 0)
		rightCol.BorderSizePixel = 0
		rightCol.ScrollBarThickness = 3
		rightCol.ScrollBarImageColor3 = THEME.AccentLilacLight
		rightCol.ScrollBarImageTransparency = 0.3
		rightCol.CanvasSize = UDim2.new(0, 0, 0, 0)
		rightCol.AutomaticCanvasSize = Enum.AutomaticSize.Y
		rightCol.ScrollingDirection = Enum.ScrollingDirection.Y
		rightCol.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
		rightCol.ClipsDescendants = false
		rightCol.Parent = pageParent
		table.insert(ThemedRegistry.Scrollbars, rightCol)

		local rightPad = Instance.new("UIPadding")
		rightPad.PaddingRight = UDim.new(0, 6)
		rightPad.Parent = rightCol

		local rightLayout = Instance.new("UIListLayout")
		rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rightLayout.Padding = UDim.new(0, 8)
		rightLayout.Parent = rightCol

		return leftCol, rightCol
	end

	local function createToggle(parent, text, defaultVal, rightType, callback, flag)
		flag = flag or text
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.Parent = parent

		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(0, 0, 1, 0)
		toggleBtn.AutomaticSize = Enum.AutomaticSize.X
		toggleBtn.BackgroundTransparency = 1
		toggleBtn.Text = ""
		toggleBtn.AutoButtonColor = false
		toggleBtn.ZIndex = 4
		toggleBtn.Parent = row

		local maxBtnW = (rightType == "dual_colorbox" or rightType == "colorbox2") and 220 or (rightType == "colorbox" and 250 or 300)
		local btnSizeConstraint = Instance.new("UISizeConstraint")
		btnSizeConstraint.MaxSize = Vector2.new(maxBtnW, 22)
		btnSizeConstraint.Parent = toggleBtn

		local box = Instance.new("Frame")
		box.Size = UDim2.new(0, 13, 0, 13)
		box.Position = UDim2.new(0, 0, 0.5, -6)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BorderSizePixel = 0
		box.ZIndex = 5
		box.Parent = toggleBtn

		local boxGrad = Instance.new("UIGradient")
		boxGrad.Rotation = 90
		boxGrad.Parent = box

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = THEME.BorderElement
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)

		local label = Instance.new("TextLabel")
		label.Text = text
		label.Font = FONT
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 20, 0, 0)
		label.Size = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize = Enum.AutomaticSize.X
		label.ZIndex = 5
		label.Parent = toggleBtn

		local btnPad = Instance.new("UIPadding")
		btnPad.PaddingRight = UDim.new(0, 8)
		btnPad.Parent = toggleBtn

		local state = defaultVal == true

		local function updateBoxVisual()
			if state then
				boxGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
					ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
				})
				label.TextColor3 = THEME.TextPrimary
			else
				boxGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
					ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
				})
				label.TextColor3 = THEME.TextSecondary
			end
		end
		updateBoxVisual()
		table.insert(ThemedRegistry.ToggleCheckboxes, updateBoxVisual)

		local cpInst1, cpInst2

		if rightType == "colorbox" then
			cpInst1 = createSingleColorPicker(row, -32, Color3.fromRGB(255, 255, 255))
			ConfigFeatureEntries[flag .. "_Color1"] = {
				Get = function()
					local col = cpInst1.GetColor()
					return { R = col.R, G = col.G, B = col.B }
				end,
				Set = function(val)
					if type(val) == "table" and val.R then
						cpInst1.SetColor(Color3.new(val.R, val.G, val.B))
					end
				end
			}
		elseif rightType == "dual_colorbox" or rightType == "colorbox2" then
			cpInst1 = createSingleColorPicker(row, -32, Color3.fromRGB(255, 255, 255))
			cpInst2 = createSingleColorPicker(row, -68, Color3.fromRGB(180, 130, 230))

			ConfigFeatureEntries[flag .. "_Color1"] = {
				Get = function()
					local col = cpInst1.GetColor()
					return { R = col.R, G = col.G, B = col.B }
				end,
				Set = function(val)
					if type(val) == "table" and val.R then
						cpInst1.SetColor(Color3.new(val.R, val.G, val.B))
					end
				end
			}
			ConfigFeatureEntries[flag .. "_Color2"] = {
				Get = function()
					local col = cpInst2.GetColor()
					return { R = col.R, G = col.B }
				end,
				Set = function(val)
					if type(val) == "table" and val.R then
						cpInst2.SetColor(Color3.new(val.R, val.G, val.B))
					end
				end
			}
		end

		toggleBtn.MouseButton1Click:Connect(function()
			if activeDropdownClose then activeDropdownClose() end
			state = not state
			updateBoxVisual()
			if callback then callback(state) end
		end)

		ConfigFeatureEntries[flag] = {
			Get = function() return state end,
			Set = function(newVal)
				state = (newVal == true)
				updateBoxVisual()
				if callback then callback(state) end
			end
		}

		return {
			Set = function(val)
				state = (val == true)
				updateBoxVisual()
				if callback then callback(state) end
			end,
			Get = function() return state end,
			Instance = row
		}
	end

	local function createCompactSlider(parent, labelText, defaultVal, minVal, maxVal, callback, flag, precise)
		flag = flag or labelText
		precise = precise or 0

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 26)
		row.BackgroundTransparency = 1
		row.ZIndex = 2
		row.Parent = parent

		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = FONT
		label.TextSize = 13
		label.TextColor3 = THEME.TextSecondary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, 0, 0, 14)
		label.ZIndex = 3
		label.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, label)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0, 8)
		bar.Position = UDim2.new(0, 0, 0, 16)
		bar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		bar.BorderSizePixel = 0
		bar.ClipsDescendants = true
		bar.ZIndex = 2
		bar.Parent = row

		local barGrad = Instance.new("UIGradient")
		barGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
		})
		barGrad.Rotation = 90
		barGrad.Parent = bar
		table.insert(ThemedRegistry.ElementGradients, barGrad)

		local barStroke = Instance.new("UIStroke")
		barStroke.Color = THEME.BorderElement
		barStroke.Thickness = 1
		barStroke.Parent = bar
		table.insert(ThemedRegistry.ElementStrokes, barStroke)

		local currentVal = defaultVal
		local initPct = math.clamp((defaultVal - minVal) / (maxVal - minVal), 0, 1)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(initPct, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.ZIndex = 2
		fill.Parent = bar

		local fillGrad = Instance.new("UIGradient")
		fillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.SliderFillLeft),
			ColorSequenceKeypoint.new(1, THEME.SliderFillRight)
		})
		fillGrad.Parent = fill
		table.insert(ThemedRegistry.SliderGradients, fillGrad)

		local valLabel = Instance.new("TextLabel")
		valLabel.Text = (precise > 0) and string.format("%." .. precise .. "f", defaultVal) or tostring(math.floor(defaultVal))
		valLabel.Font = FONT
		valLabel.TextSize = 10
		valLabel.TextColor3 = THEME.TextPrimary
		valLabel.TextStrokeColor3 = Color3.fromRGB(12, 9, 16)
		valLabel.TextStrokeTransparency = 0.4
		valLabel.TextXAlignment = Enum.TextXAlignment.Center
		valLabel.BackgroundTransparency = 1
		valLabel.Size = UDim2.new(1, 0, 1, 0)
		valLabel.ZIndex = 5
		valLabel.Parent = bar
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)

		local isSliding = false
		local function updateSlider(input)
			local relX = math.clamp(input.Position.X - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
			local pct = math.clamp(relX / bar.AbsoluteSize.X, 0, 1)
			local rawVal = minVal + (maxVal - minVal) * pct

			if precise > 0 then
				local factor = 10 ^ precise
				currentVal = math.round(rawVal * factor) / factor
				valLabel.Text = string.format("%." .. precise .. "f", currentVal)
			else
				currentVal = math.floor(rawVal)
				valLabel.Text = tostring(currentVal)
			end

			fill.Size = UDim2.new(pct, 0, 1, 0)
			if callback then callback(currentVal) end
		end

		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if activeSliderBar ~= nil and activeSliderBar ~= bar then return end
				if activeDropdownClose then activeDropdownClose() end
				activeSliderBar = bar
				activeSliderInput = input
				isSliding = true
				updateSlider(input)

				local endConn
				endConn = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						if endConn then endConn:Disconnect() end
						if activeSliderBar == bar then
							activeSliderBar = nil
							activeSliderInput = nil
							isSliding = false
						end
					end
				end)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if isSliding and (input == activeSliderInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
				isSliding = false
				if activeSliderBar == bar then
					activeSliderBar = nil
					activeSliderInput = nil
				end
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if isSliding and activeSliderBar == bar and (input == activeSliderInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
				updateSlider(input)
			end
		end)

		ConfigFeatureEntries[flag] = {
			Get = function() return currentVal end,
			Set = function(newVal)
				if type(newVal) == "number" then
					currentVal = math.clamp(newVal, minVal, maxVal)
					if precise > 0 then
						local factor = 10 ^ precise
						currentVal = math.round(currentVal * factor) / factor
						valLabel.Text = string.format("%." .. precise .. "f", currentVal)
					else
						currentVal = math.floor(currentVal)
						valLabel.Text = tostring(currentVal)
					end
					local pct = (currentVal - minVal) / (maxVal - minVal)
					fill.Size = UDim2.new(pct, 0, 1, 0)
					if callback then callback(currentVal) end
				end
			end
		}

		return {
			Set = function(newVal)
				ConfigFeatureEntries[flag].Set(newVal)
			end,
			Get = function() return currentVal end
		}
	end

	local function createDropdown(parent, title, defaultVal, options, zIndexVal, onSelected, flag)
		flag = flag or title
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundTransparency = 1
		row.ZIndex = zIndexVal or 10
		row.ClipsDescendants = false
		row.Parent = parent

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = FONT
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = THEME.TextSecondary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 14)
		titleLabel.ZIndex = row.ZIndex + 1
		titleLabel.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(1, 0, 0, 22)
		box.Position = UDim2.new(0, 0, 0, 18)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BorderSizePixel = 0
		box.Text = ""
		box.AutoButtonColor = false
		box.ZIndex = row.ZIndex + 1
		box.ClipsDescendants = false
		box.Parent = row

		local boxGrad = Instance.new("UIGradient")
		boxGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
		})
		boxGrad.Rotation = 90
		boxGrad.Parent = box
		table.insert(ThemedRegistry.ElementGradients, boxGrad)

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = THEME.BorderElement
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)

		local valLabel = Instance.new("TextLabel")
		valLabel.Text = defaultVal
		valLabel.Font = FONT
		valLabel.TextSize = 13
		valLabel.TextColor3 = THEME.TextPrimary
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.BackgroundTransparency = 1
		valLabel.Position = UDim2.new(0, 7, 0, 0)
		valLabel.Size = UDim2.new(1, -26, 1, 0)
		valLabel.ZIndex = box.ZIndex + 1
		valLabel.Parent = box
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)

		local plus = Instance.new("TextLabel")
		plus.Text = "+"
		plus.Font = FONT
		plus.TextSize = 15
		plus.TextColor3 = THEME.TextSecondary
		plus.BackgroundTransparency = 1
		plus.Position = UDim2.new(1, -18, 0, 0)
		plus.Size = UDim2.new(0, 14, 1, 0)
		plus.ZIndex = box.ZIndex + 1
		plus.Parent = box
		table.insert(ThemedRegistry.SecondaryTexts, plus)

		local optionHeight = 22
		local fullHeight = (#options * optionHeight) + 4

		local listFrame = Instance.new("Frame")
		listFrame.Name = "DropList"
		listFrame.Size = UDim2.new(1, 0, 0, 0)
		listFrame.Position = UDim2.new(0, 0, 1, 3)
		listFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		listFrame.BorderSizePixel = 0
		listFrame.ClipsDescendants = true
		listFrame.Visible = false
		listFrame.ZIndex = 80
		listFrame.Parent = box

		local listGrad = Instance.new("UIGradient")
		listGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.DropListTop),
			ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
			ColorSequenceKeypoint.new(1, THEME.DropListBottom)
		})
		listGrad.Rotation = 90
		listGrad.Parent = listFrame
		table.insert(ThemedRegistry.DropListGradients, listGrad)

		local listStroke = Instance.new("UIStroke")
		listStroke.Color = THEME.BorderCard
		listStroke.Thickness = 1
		listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		listStroke.Parent = listFrame
		table.insert(ThemedRegistry.CardStrokes, listStroke)

		local listTopLine = Instance.new("Frame")
		listTopLine.Size = UDim2.new(1, 0, 0, 1)
		listTopLine.Position = UDim2.new(0, 0, 0, 0)
		listTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		listTopLine.BorderSizePixel = 0
		listTopLine.ZIndex = 83
		listTopLine.Parent = listFrame

		local topLineGrad = Instance.new("UIGradient")
		topLineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))
		})
		topLineGrad.Parent = listTopLine
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 1)
		listLayout.Parent = listFrame

		local listPadding = Instance.new("UIPadding")
		listPadding.PaddingTop = UDim.new(0, 2)
		listPadding.PaddingBottom = UDim.new(0, 2)
		listPadding.Parent = listFrame

		local isOpen = false

		local function closeDropdown()
			if not isOpen then return end
			isOpen = false
			TweenService:Create(plus, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			local closeTween = TweenService:Create(listFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				if not isOpen then listFrame.Visible = false end
			end)
			if activeDropdownClose == closeDropdown then activeDropdownClose = nil end
		end

		local function openDropdown()
			if activeDropdownClose and activeDropdownClose ~= closeDropdown then activeDropdownClose() end
			isOpen = true
			activeDropdownClose = closeDropdown
			listFrame.Visible = true
			TweenService:Create(plus, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()
			TweenService:Create(listFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, fullHeight)}):Play()
		end

		box.MouseButton1Click:Connect(function()
			if isOpen then closeDropdown() else openDropdown() end
		end)

		for idx, optText in ipairs(options) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, optionHeight)
			optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			optBtn.BackgroundTransparency = 1
			optBtn.BorderSizePixel = 0
			optBtn.Text = ""
			optBtn.AutoButtonColor = false
			optBtn.LayoutOrder = idx
			optBtn.ZIndex = 81
			optBtn.Parent = listFrame

			local optLabel = Instance.new("TextLabel")
			optLabel.Text = optText
			optLabel.Font = FONT
			optLabel.TextSize = 13
			optLabel.TextColor3 = (optText == defaultVal and THEME.TextSelectedWhite) or THEME.TextMuted
			optLabel.TextXAlignment = Enum.TextXAlignment.Left
			optLabel.BackgroundTransparency = 1
			optLabel.Position = UDim2.new(0, 9, 0, 0)
			optLabel.Size = UDim2.new(1, -18, 1, 0)
			optLabel.ZIndex = 82
			optLabel.Parent = optBtn

			table.insert(ThemedRegistry.DropdownLabels, {
				Label = optLabel,
				IsActive = function() return valLabel.Text == optText end
			})

			optBtn.MouseEnter:Connect(function()
				TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.94}):Play()
				optLabel.TextColor3 = THEME.TextSelectedWhite
			end)
			optBtn.MouseLeave:Connect(function()
				TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
				if valLabel.Text ~= optText then
					optLabel.TextColor3 = THEME.TextMuted
				end
			end)

			optBtn.MouseButton1Click:Connect(function()
				valLabel.Text = optText
				for _, child in ipairs(listFrame:GetChildren()) do
					if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then
						local lbl = child:FindFirstChildOfClass("TextLabel")
						lbl.TextColor3 = (lbl.Text == optText and THEME.TextSelectedWhite) or THEME.TextMuted
					end
				end
				closeDropdown()
				if onSelected then onSelected(optText) end
			end)
		end

		ConfigFeatureEntries[flag] = {
			Get = function() return valLabel.Text end,
			Set = function(newVal)
				if table.find(options, newVal) then
					valLabel.Text = newVal
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then
							local lbl = child:FindFirstChildOfClass("TextLabel")
							lbl.TextColor3 = (lbl.Text == newVal and THEME.TextSelectedWhite) or THEME.TextMuted
						end
					end
					if onSelected then onSelected(newVal) end
				end
			end
		}

		return {
			Set = function(val) ConfigFeatureEntries[flag].Set(val) end,
			Get = function() return valLabel.Text end
		}
	end

	local function createMultiDropdown(parent, title, defaultOptions, allOptions, zIndexVal, callback, flag)
		flag = flag or title
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundTransparency = 1
		row.ZIndex = zIndexVal or 10
		row.ClipsDescendants = false
		row.Parent = parent

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = FONT
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = THEME.TextSecondary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 14)
		titleLabel.ZIndex = row.ZIndex + 1
		titleLabel.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(1, 0, 0, 22)
		box.Position = UDim2.new(0, 0, 0, 18)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BorderSizePixel = 0
		box.Text = ""
		box.AutoButtonColor = false
		box.ZIndex = row.ZIndex + 1
		box.ClipsDescendants = false
		box.Parent = row

		local boxGrad = Instance.new("UIGradient")
		boxGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
		})
		boxGrad.Rotation = 90
		boxGrad.Parent = box
		table.insert(ThemedRegistry.ElementGradients, boxGrad)

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = THEME.BorderElement
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)

		local selectedMap = {}
		for _, opt in ipairs(defaultOptions or {}) do
			selectedMap[opt] = true
		end

		local valLabel = Instance.new("TextLabel")
		valLabel.Font = FONT
		valLabel.TextSize = 13
		valLabel.TextColor3 = THEME.TextPrimary
		valLabel.TextXAlignment = Enum.TextXAlignment.Left
		valLabel.BackgroundTransparency = 1
		valLabel.Position = UDim2.new(0, 7, 0, 0)
		valLabel.Size = UDim2.new(1, -26, 1, 0)
		valLabel.ZIndex = box.ZIndex + 1
		valLabel.Parent = box
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)

		local function updateLabelText()
			local activeList = {}
			for _, opt in ipairs(allOptions) do
				if selectedMap[opt] then
					table.insert(activeList, opt)
				end
			end
			valLabel.Text = (#activeList == 0) and "None" or table.concat(activeList, ", ")
			if callback then callback(activeList) end
		end
		updateLabelText()

		local plus = Instance.new("TextLabel")
		plus.Text = "+"
		plus.Font = FONT
		plus.TextSize = 15
		plus.TextColor3 = THEME.TextSecondary
		plus.BackgroundTransparency = 1
		plus.Position = UDim2.new(1, -18, 0, 0)
		plus.Size = UDim2.new(0, 14, 1, 0)
		plus.ZIndex = box.ZIndex + 1
		plus.Parent = box
		table.insert(ThemedRegistry.SecondaryTexts, plus)

		local optionHeight = 22
		local fullHeight = (#allOptions * optionHeight) + 4

		local listFrame = Instance.new("Frame")
		listFrame.Name = "MultiDropList"
		listFrame.Size = UDim2.new(1, 0, 0, 0)
		listFrame.Position = UDim2.new(0, 0, 1, 3)
		listFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		listFrame.BorderSizePixel = 0
		listFrame.ClipsDescendants = true
		listFrame.Visible = false
		listFrame.ZIndex = 80
		listFrame.Parent = box

		local listGrad = Instance.new("UIGradient")
		listGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.DropListTop),
			ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
			ColorSequenceKeypoint.new(1, THEME.DropListBottom)
		})
		listGrad.Rotation = 90
		listGrad.Parent = listFrame
		table.insert(ThemedRegistry.DropListGradients, listGrad)

		local listStroke = Instance.new("UIStroke")
		listStroke.Color = THEME.BorderCard
		listStroke.Thickness = 1
		listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		listStroke.Parent = listFrame
		table.insert(ThemedRegistry.CardStrokes, listStroke)

		local listTopLine = Instance.new("Frame")
		listTopLine.Size = UDim2.new(1, 0, 0, 1)
		listTopLine.Position = UDim2.new(0, 0, 0, 0)
		listTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		listTopLine.BorderSizePixel = 0
		listTopLine.ZIndex = 83
		listTopLine.Parent = listFrame

		local topLineGrad = Instance.new("UIGradient")
		topLineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))
		})
		topLineGrad.Parent = listTopLine
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)

		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Padding = UDim.new(0, 1)
		listLayout.Parent = listFrame

		local listPadding = Instance.new("UIPadding")
		listPadding.PaddingTop = UDim.new(0, 2)
		listPadding.PaddingBottom = UDim.new(0, 2)
		listPadding.Parent = listFrame

		local isOpen = false

		local function closeDropdown()
			if not isOpen then return end
			isOpen = false
			TweenService:Create(plus, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()
			local closeTween = TweenService:Create(listFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				if not isOpen then listFrame.Visible = false end
			end)
			if activeDropdownClose == closeDropdown then activeDropdownClose = nil end
		end

		local function openDropdown()
			if activeDropdownClose and activeDropdownClose ~= closeDropdown then activeDropdownClose() end
			isOpen = true
			activeDropdownClose = closeDropdown
			listFrame.Visible = true
			TweenService:Create(plus, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()
			TweenService:Create(listFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, fullHeight)}):Play()
		end

		box.MouseButton1Click:Connect(function()
			if isOpen then closeDropdown() else openDropdown() end
		end)

		for idx, optText in ipairs(allOptions) do
			local optBtn = Instance.new("TextButton")
			optBtn.Size = UDim2.new(1, 0, 0, optionHeight)
			optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			optBtn.BackgroundTransparency = 1
			optBtn.BorderSizePixel = 0
			optBtn.Text = ""
			optBtn.AutoButtonColor = false
			optBtn.LayoutOrder = idx
			optBtn.ZIndex = 81
			optBtn.Parent = listFrame

			local optLabel = Instance.new("TextLabel")
			optLabel.Text = optText
			optLabel.Font = FONT
			optLabel.TextSize = 13
			optLabel.TextColor3 = selectedMap[optText] and THEME.TextSelectedWhite or THEME.TextMuted
			optLabel.TextXAlignment = Enum.TextXAlignment.Left
			optLabel.BackgroundTransparency = 1
			optLabel.Position = UDim2.new(0, 9, 0, 0)
			optLabel.Size = UDim2.new(1, -18, 1, 0)
			optLabel.ZIndex = 82
			optLabel.Parent = optBtn

			table.insert(ThemedRegistry.DropdownLabels, {
				Label = optLabel,
				IsActive = function() return selectedMap[optText] == true end
			})

			optBtn.MouseEnter:Connect(function()
				TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 0.94}):Play()
			end)
			optBtn.MouseLeave:Connect(function()
				TweenService:Create(optBtn, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
			end)

			optBtn.MouseButton1Click:Connect(function()
				selectedMap[optText] = not selectedMap[optText]
				optLabel.TextColor3 = selectedMap[optText] and THEME.TextSelectedWhite or THEME.TextMuted
				updateLabelText()
			end)
		end

		ConfigFeatureEntries[flag] = {
			Get = function()
				local res = {}
				for _, opt in ipairs(allOptions) do
					if selectedMap[opt] then table.insert(res, opt) end
				end
				return res
			end,
			Set = function(newVals)
				if type(newVals) == "table" then
					selectedMap = {}
					for _, v in ipairs(newVals) do selectedMap[v] = true end
					for _, child in ipairs(listFrame:GetChildren()) do
						if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then
							local lbl = child:FindFirstChildOfClass("TextLabel")
							lbl.TextColor3 = selectedMap[lbl.Text] and THEME.TextSelectedWhite or THEME.TextMuted
						end
					end
					updateLabelText()
				end
			end
		}

		return {
			Set = function(val) ConfigFeatureEntries[flag].Set(val) end,
			Get = function() return ConfigFeatureEntries[flag].Get() end
		}
	end

	local function createInput(parent, title, placeholder, defaultVal, callback, flag)
		flag = flag or title
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.Parent = parent

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title
		titleLabel.Font = FONT
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = THEME.TextSecondary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Size = UDim2.new(1, 0, 0, 14)
		titleLabel.ZIndex = 2
		titleLabel.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)

		local box = Instance.new("Frame")
		box.Size = UDim2.new(1, 0, 0, 22)
		box.Position = UDim2.new(0, 0, 0, 18)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BorderSizePixel = 0
		box.ClipsDescendants = true
		box.Parent = row

		local boxGrad = Instance.new("UIGradient")
		boxGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
		})
		boxGrad.Rotation = 90
		boxGrad.Parent = box
		table.insert(ThemedRegistry.ElementGradients, boxGrad)

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = THEME.BorderElement
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)

		local topLine = Instance.new("Frame")
		topLine.Name = "TopLine"
		topLine.Size = UDim2.new(1, 0, 0, 1)
		topLine.Position = UDim2.new(0, 0, 0, 0)
		topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		topLine.BorderSizePixel = 0
		topLine.ZIndex = 4
		topLine.Parent = box

		local topLineGrad = Instance.new("UIGradient")
		topLineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))
		})
		topLineGrad.Parent = topLine
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(1, -14, 1, 0)
		input.Position = UDim2.new(0, 7, 0, 0)
		input.BackgroundTransparency = 1
		input.Text = defaultVal or ""
		input.PlaceholderText = placeholder or "Enter text..."
		input.PlaceholderColor3 = THEME.TextMuted
		input.TextColor3 = THEME.TextPrimary
		input.Font = FONT
		input.TextSize = 13
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.ClearTextOnFocus = false
		input.ZIndex = 3
		input.Parent = box
		table.insert(ThemedRegistry.PrimaryTexts, input)
		table.insert(ThemedRegistry.MutedTexts, input)

		input.Focused:Connect(function()
			TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = THEME.AccentLilacMid}):Play()
		end)

		input.FocusLost:Connect(function(enterPressed)
			TweenService:Create(boxStroke, TweenInfo.new(0.15), {Color = THEME.BorderElement}):Play()
			if callback then callback(input.Text, enterPressed) end
		end)

		ConfigFeatureEntries[flag] = {
			Get = function() return input.Text end,
			Set = function(newVal)
				if type(newVal) == "string" then
					input.Text = newVal
					if callback then callback(input.Text, false) end
				end
			end
		}

		return row, input
	end

	local function createActionButton(parent, text, callback)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 24)
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ClipsDescendants = true
		btn.Parent = parent

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
		})
		btnGrad.Rotation = 90
		btnGrad.Parent = btn
		table.insert(ThemedRegistry.ElementGradients, btnGrad)

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = THEME.BorderElement
		btnStroke.Thickness = 1
		btnStroke.Parent = btn
		table.insert(ThemedRegistry.ElementStrokes, btnStroke)

		local btnLabel = Instance.new("TextLabel")
		btnLabel.Text = text
		btnLabel.Font = FONT
		btnLabel.TextSize = 13
		btnLabel.TextColor3 = THEME.TextPrimary
		btnLabel.TextXAlignment = Enum.TextXAlignment.Center
		btnLabel.BackgroundTransparency = 1
		btnLabel.Size = UDim2.new(1, 0, 1, 0)
		btnLabel.ZIndex = 2
		btnLabel.Parent = btn
		table.insert(ThemedRegistry.PrimaryTexts, btnLabel)

		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(185, 175, 200)
			}):Play()
			TweenService:Create(btnStroke, TweenInfo.new(0.08), {Color = THEME.AccentLilacLight}):Play()
			TweenService:Create(btnLabel, TweenInfo.new(0.08), {TextColor3 = THEME.AccentLilacLight}):Play()
		end)

		local function releaseBtn()
			TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			TweenService:Create(btnStroke, TweenInfo.new(0.18), {Color = THEME.BorderElement}):Play()
			TweenService:Create(btnLabel, TweenInfo.new(0.18), {TextColor3 = THEME.TextPrimary}):Play()
		end

		btn.MouseButton1Up:Connect(releaseBtn)
		btn.MouseLeave:Connect(releaseBtn)

		btn.MouseButton1Click:Connect(function()
			if activeDropdownClose then activeDropdownClose() end
			if callback then callback() end
		end)

		return btn
	end

	local function createDualActionButtons(parent, text1, cb1, text2, cb2)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundTransparency = 1
		row.Parent = parent

		local btn1 = createActionButton(row, text1, cb1)
		btn1.Size = UDim2.new(0.5, -2, 1, 0)
		btn1.Position = UDim2.new(0, 0, 0, 0)

		local btn2 = createActionButton(row, text2, cb2)
		btn2.Size = UDim2.new(0.5, -2, 1, 0)
		btn2.Position = UDim2.new(0.5, 2, 0, 0)

		return row
	end

	local function createColorPickerRow(parent, text, defaultColor, onColorChanged, flag)
		flag = flag or text
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 22)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.Parent = parent

		local label = Instance.new("TextLabel")
		label.Text = text
		label.Font = FONT
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 0, 0, 0)
		label.Size = UDim2.new(1, -40, 1, 0)
		label.TextColor3 = THEME.TextPrimary
		label.ZIndex = 3
		label.Parent = row
		table.insert(ThemedRegistry.PrimaryTexts, label)

		local cp = createSingleColorPicker(row, -32, defaultColor, onColorChanged)

		ConfigFeatureEntries[flag] = {
			Get = function()
				local col = cp.GetColor()
				return { R = col.R, G = col.G, B = col.B }
			end,
			Set = function(val)
				if type(val) == "table" and val.R then
					cp.SetColor(Color3.new(val.R, val.G, val.B))
				end
			end
		}

		return row
	end

	local function createPlayerList(parent, title, sizeY, elementConfigs, filterOptions)
		filterOptions = filterOptions or {}
		local mode = filterOptions.TeamFilter or "All"
		local customFilter = filterOptions.Filter

		local function isPlayerVisible(plr)
			if plr == LocalPlayer then return false end
			if typeof(customFilter) == "function" then
				return customFilter(plr)
			end
			if mode == "Enemies" then
				if LocalPlayer.Team and plr.Team then
					return LocalPlayer.Team ~= plr.Team
				elseif LocalPlayer.TeamColor and plr.TeamColor then
					return LocalPlayer.TeamColor ~= plr.TeamColor
				end
				return true
			elseif mode == "Allies" then
				if LocalPlayer.Team and plr.Team then
					return LocalPlayer.Team == plr.Team
				elseif LocalPlayer.TeamColor and plr.TeamColor then
					return LocalPlayer.TeamColor == plr.TeamColor
				end
				return false
			end
			return true
		end

		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		card.BorderSizePixel = 0
		card.Size = UDim2.new(1, 0, 0, sizeY or 340)
		card.ClipsDescendants = true
		card.Parent = parent

		local cardGrad = Instance.new("UIGradient")
		cardGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.CardBgTop),
			ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
		})
		cardGrad.Rotation = 90
		cardGrad.Parent = card
		table.insert(ThemedRegistry.CardGradients, cardGrad)

		local stroke = Instance.new("UIStroke")
		stroke.Color = THEME.BorderCard
		stroke.Thickness = 1
		stroke.Parent = card
		table.insert(ThemedRegistry.CardStrokes, stroke)

		local topLine = Instance.new("Frame")
		topLine.BorderSizePixel = 0
		topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		topLine.Size = UDim2.new(1, 0, 0, 1)
		topLine.Parent = card

		local lineGrad = Instance.new("UIGradient")
		lineGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),
			ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
		})
		lineGrad.Parent = topLine
		table.insert(ThemedRegistry.AccentLineGradients, lineGrad)

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Text = title or "Player List"
		titleLabel.Font = FONT
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = THEME.TextPrimary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 10, 0, 4)
		titleLabel.Size = UDim2.new(1, -20, 0, 18)
		titleLabel.ZIndex = 3
		titleLabel.Parent = card
		table.insert(ThemedRegistry.PrimaryTexts, titleLabel)

		local playerScroll = Instance.new("ScrollingFrame")
		playerScroll.Size = UDim2.new(1, -16, 1, -28)
		playerScroll.Position = UDim2.new(0, 8, 0, 24)
		playerScroll.BackgroundTransparency = 1
		playerScroll.BorderSizePixel = 0
		playerScroll.ScrollBarThickness = 3
		playerScroll.ScrollBarImageColor3 = THEME.AccentLilacLight
		playerScroll.ScrollBarImageTransparency = 0.2
		playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		playerScroll.ScrollingDirection = Enum.ScrollingDirection.Y
		playerScroll.ClipsDescendants = true
		playerScroll.Parent = card
		table.insert(ThemedRegistry.Scrollbars, playerScroll)

		local pListLayout = Instance.new("UIListLayout")
		pListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pListLayout.Padding = UDim.new(0, 4)
		pListLayout.Parent = playerScroll

		local configs = elementConfigs or {
			{ type = "toggle", name = "Aim", default = false },
			{ type = "toggle", name = "ESP", default = false },
			{ type = "dropdown", name = "Prio", default = "Med", options = {"Low", "Med", "High"} }
		}

		local playerRows = {}

		local function updatePlayerVisibility(plr)
			local row = playerRows[plr]
			if row then
				row.Visible = isPlayerVisible(plr)
			end
		end

		local function buildPlayerRow(plr)
			if not plr or playerRows[plr] or plr == LocalPlayer then return end

			local row = Instance.new("Frame")
			row.Name = "Player_" .. plr.UserId
			row.Size = UDim2.new(1, -6, 0, 32)
			row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			row.BorderSizePixel = 0
			row.ClipsDescendants = false
			row.Visible = isPlayerVisible(plr)
			row.Parent = playerScroll

			local rowGrad = Instance.new("UIGradient")
			rowGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
				ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
			})
			rowGrad.Rotation = 90
			rowGrad.Parent = row
			table.insert(ThemedRegistry.ElementGradients, rowGrad)

			local rowStroke = Instance.new("UIStroke")
			rowStroke.Color = THEME.BorderElement
			rowStroke.Thickness = 1
			rowStroke.Parent = row
			table.insert(ThemedRegistry.ElementStrokes, rowStroke)

			local rowTopLine = Instance.new("Frame")
			rowTopLine.Size = UDim2.new(1, 0, 0, 1)
			rowTopLine.BorderSizePixel = 0
			rowTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			rowTopLine.ZIndex = 2
			rowTopLine.Parent = row

			local rLineGrad = Instance.new("UIGradient")
			rLineGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
				ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),
				ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
			})
			rLineGrad.Parent = rowTopLine
			table.insert(ThemedRegistry.AccentLineGradients, rLineGrad)

			local avatarImg = Instance.new("ImageLabel")
			avatarImg.Size = UDim2.new(0, 22, 0, 22)
			avatarImg.Position = UDim2.new(0, 5, 0.5, -11)
			avatarImg.BackgroundColor3 = Color3.fromRGB(15, 10, 20)
			avatarImg.BorderSizePixel = 0
			avatarImg.ZIndex = 3
			avatarImg.Parent = row

			local avCorner = Instance.new("UICorner")
			avCorner.CornerRadius = UDim.new(0, 3)
			avCorner.Parent = avatarImg

			task.spawn(function()
				pcall(function()
					local content, isReady = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
					if isReady and avatarImg and avatarImg.Parent then
						avatarImg.Image = content
					end
				end)
			end)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Text = plr.DisplayName
			nameLabel.Font = FONT
			nameLabel.TextSize = 13
			nameLabel.TextColor3 = THEME.TextPrimary
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.new(0, 32, 0, 0)
			nameLabel.Size = UDim2.new(1, -195, 1, 0)
			nameLabel.ZIndex = 3
			nameLabel.Parent = row
			table.insert(ThemedRegistry.PrimaryTexts, nameLabel)

			local controlsHolder = Instance.new("Frame")
			controlsHolder.BackgroundTransparency = 1
			controlsHolder.AnchorPoint = Vector2.new(1, 0.5)
			controlsHolder.Position = UDim2.new(1, -6, 0.5, 0)
			controlsHolder.Size = UDim2.new(0, 155, 1, -4)
			controlsHolder.ZIndex = 4
			controlsHolder.Parent = row

			local cLayout = Instance.new("UIListLayout")
			cLayout.FillDirection = Enum.FillDirection.Horizontal
			cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			cLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			cLayout.Padding = UDim.new(0, 10)
			cLayout.Parent = controlsHolder

			for i = 1, math.min(#configs, 3) do
				local cfg = configs[i]
				if cfg.type == "toggle" then
					local toggleBtn = Instance.new("TextButton")
					toggleBtn.Size = UDim2.new(0, 44, 0, 20)
					toggleBtn.BackgroundTransparency = 1
					toggleBtn.Text = ""
					toggleBtn.AutoButtonColor = false
					toggleBtn.ZIndex = 5
					toggleBtn.Parent = controlsHolder

					local tBox = Instance.new("Frame")
					tBox.Size = UDim2.new(0, 12, 0, 12)
					tBox.Position = UDim2.new(0, 0, 0.5, -6)
					tBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					tBox.BorderSizePixel = 0
					tBox.ZIndex = 6
					tBox.Parent = toggleBtn

					local tBoxGrad = Instance.new("UIGradient")
					tBoxGrad.Rotation = 90
					tBoxGrad.Parent = tBox

					local tBoxStroke = Instance.new("UIStroke")
					tBoxStroke.Color = THEME.BorderElement
					tBoxStroke.Thickness = 1
					tBoxStroke.Parent = tBox
					table.insert(ThemedRegistry.ElementStrokes, tBoxStroke)

					local tLbl = Instance.new("TextLabel")
					tLbl.Text = cfg.name or "On"
					tLbl.Font = FONT
					tLbl.TextSize = 11
					tLbl.TextColor3 = THEME.TextSecondary
					tLbl.TextXAlignment = Enum.TextXAlignment.Left
					tLbl.BackgroundTransparency = 1
					tLbl.Position = UDim2.new(0, 18, 0, 0)
					tLbl.Size = UDim2.new(1, -18, 1, 0)
					tLbl.ZIndex = 6
					tLbl.Parent = toggleBtn

					local state = cfg.default == true
					local function updateBoxVisual()
						if state then
							tBoxGrad.Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
								ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
							})
							tLbl.TextColor3 = THEME.TextPrimary
						else
							tBoxGrad.Color = ColorSequence.new({
								ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
								ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
							})
							tLbl.TextColor3 = THEME.TextSecondary
						end
					end
					updateBoxVisual()
					table.insert(ThemedRegistry.ToggleCheckboxes, updateBoxVisual)

					toggleBtn.MouseButton1Click:Connect(function()
						if activeDropdownClose then activeDropdownClose() end
						state = not state
						updateBoxVisual()
						if cfg.callback then cfg.callback(plr, state) end
					end)

				elseif cfg.type == "dropdown" then
					local dBox = Instance.new("TextButton")
					dBox.Size = UDim2.new(0, 46, 0, 20)
					dBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					dBox.BorderSizePixel = 0
					dBox.Text = ""
					dBox.AutoButtonColor = false
					dBox.ZIndex = 5
					dBox.Parent = controlsHolder

					local dBoxGrad = Instance.new("UIGradient")
					dBoxGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, THEME.ElementBgTop),
						ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)
					})
					dBoxGrad.Rotation = 90
					dBoxGrad.Parent = dBox
					table.insert(ThemedRegistry.ElementGradients, dBoxGrad)

					local dBoxStroke = Instance.new("UIStroke")
					dBoxStroke.Color = THEME.BorderElement
					dBoxStroke.Thickness = 1
					dBoxStroke.Parent = dBox
					table.insert(ThemedRegistry.ElementStrokes, dBoxStroke)

					local curOpt = cfg.default or (cfg.options and cfg.options[1]) or "None"
					local dVal = Instance.new("TextLabel")
					dVal.Text = curOpt
					dVal.Font = FONT
					dVal.TextSize = 11
					dVal.TextColor3 = THEME.TextPrimary
					dVal.TextXAlignment = Enum.TextXAlignment.Center
					dVal.BackgroundTransparency = 1
					dVal.Size = UDim2.new(1, 0, 1, 0)
					dVal.ZIndex = 6
					dVal.Parent = dBox
					table.insert(ThemedRegistry.PrimaryTexts, dVal)

					local opts = cfg.options or {"A", "B"}
					local dList = Instance.new("Frame")
					dList.Size = UDim2.new(1, 0, 0, #opts * 18 + 4)
					dList.Position = UDim2.new(0, 0, 1, 2)
					dList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					dList.BorderSizePixel = 0
					dList.Visible = false
					dList.ZIndex = 120
					dList.Parent = dBox

					local dListGrad = Instance.new("UIGradient")
					dListGrad.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, THEME.DropListTop),
						ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
						ColorSequenceKeypoint.new(1, THEME.DropListBottom)
					})
					dListGrad.Rotation = 90
					dListGrad.Parent = dList
					table.insert(ThemedRegistry.DropListGradients, dListGrad)

					local dListStroke = Instance.new("UIStroke")
					dListStroke.Color = THEME.BorderCard
					dListStroke.Thickness = 1
					dListStroke.Parent = dList
					table.insert(ThemedRegistry.CardStrokes, dListStroke)

					local dListLayout = Instance.new("UIListLayout")
					dListLayout.SortOrder = Enum.SortOrder.LayoutOrder
					dListLayout.Padding = UDim.new(0, 1)
					dListLayout.Parent = dList

					local dOpen = false
					local function closeD()
						if not dOpen then return end
						dOpen = false
						dList.Visible = false
						if activeDropdownClose == closeD then activeDropdownClose = nil end
					end
					local function openD()
						if activeDropdownClose and activeDropdownClose ~= closeD then activeDropdownClose() end
						dOpen = true
						activeDropdownClose = closeD
						dList.Visible = true
					end

					dBox.MouseButton1Click:Connect(function()
						if dOpen then closeD() else openD() end
					end)

					for _, optName in ipairs(opts) do
						local optB = Instance.new("TextButton")
						optB.Size = UDim2.new(1, 0, 0, 18)
						optB.BackgroundTransparency = 1
						optB.Text = optName
						optB.Font = FONT
						optB.TextSize = 10
						optB.TextColor3 = (optName == curOpt and THEME.AccentLilacLight) or THEME.TextMuted
						optB.ZIndex = 122
						optB.Parent = dList

						table.insert(ThemedRegistry.DropdownLabels, {
							Label = optB,
							IsActive = function() return curOpt == optName end
						})

						optB.MouseButton1Click:Connect(function()
							curOpt = optName
							dVal.Text = optName
							closeD()
							if cfg.callback then cfg.callback(plr, optName) end
						end)
					end
				end
			end

			playerRows[plr] = row
			plr:GetPropertyChangedSignal("Team"):Connect(function()
				updatePlayerVisibility(plr)
			end)
		end

		for _, p in ipairs(Players:GetPlayers()) do
			buildPlayerRow(p)
		end

		Players.PlayerAdded:Connect(buildPlayerRow)
		Players.PlayerRemoving:Connect(function(plr)
			if playerRows[plr] then
				playerRows[plr]:Destroy()
				playerRows[plr] = nil
			end
		end)

		LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
			for p, _ in pairs(playerRows) do
				updatePlayerVisibility(p)
			end
		end)

		return {
			Instance = card,
			Refresh = function()
				for p, _ in pairs(playerRows) do
					updatePlayerVisibility(p)
				end
			end
		}
	end

	local WatermarkFrame = Instance.new("Frame")
	WatermarkFrame.Name = "Watermark"
	WatermarkFrame.AnchorPoint = Vector2.new(1, 0)
	WatermarkFrame.Position = UDim2.new(0.98, 0, 0, 20)
	WatermarkFrame.Size = UDim2.new(0, 0, 0, 26)
	WatermarkFrame.AutomaticSize = Enum.AutomaticSize.X
	WatermarkFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	WatermarkFrame.BorderSizePixel = 0
	WatermarkFrame.Active = false
	WatermarkFrame.ClipsDescendants = false
	WatermarkFrame.ZIndex = 50
	WatermarkFrame.Visible = false
	WatermarkFrame.Parent = ScreenGui

	local wmBgGrad = Instance.new("UIGradient")
	wmBgGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.DropListTop),
		ColorSequenceKeypoint.new(0.45, THEME.DropListMid),
		ColorSequenceKeypoint.new(1, THEME.DropListBottom)
	})
	wmBgGrad.Rotation = 90
	wmBgGrad.Parent = WatermarkFrame
	table.insert(ThemedRegistry.DropListGradients, wmBgGrad)

	local wmStroke = Instance.new("UIStroke")
	wmStroke.Color = THEME.BorderCard
	wmStroke.Thickness = 1
	wmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	wmStroke.Parent = WatermarkFrame
	table.insert(ThemedRegistry.CardStrokes, wmStroke)

	local wmTopLine = Instance.new("Frame")
	wmTopLine.Name = "TopLine"
	wmTopLine.Size = UDim2.new(1, 0, 0, 1.5)
	wmTopLine.Position = UDim2.new(0, 0, 0, 0)
	wmTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	wmTopLine.BorderSizePixel = 0
	wmTopLine.ZIndex = 55
	wmTopLine.Parent = WatermarkFrame

	local wmTopGrad = Instance.new("UIGradient")
	wmTopGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),
		ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),
		ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)
	})
	wmTopGrad.Parent = wmTopLine
	table.insert(ThemedRegistry.AccentLineGradients, wmTopGrad)

	local ContentHolder = Instance.new("Frame")
	ContentHolder.BackgroundTransparency = 1
	ContentHolder.Size = UDim2.new(0, 0, 1, 0)
	ContentHolder.AutomaticSize = Enum.AutomaticSize.X
	ContentHolder.ZIndex = 52
	ContentHolder.Parent = WatermarkFrame

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.Padding = UDim.new(0, 3)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Parent = ContentHolder

	local contentPad = Instance.new("UIPadding")
	contentPad.PaddingLeft = UDim.new(0, 8)
	contentPad.PaddingRight = UDim.new(0, 8)
	contentPad.PaddingTop = UDim.new(0, 1)
	contentPad.Parent = ContentHolder

	local function getSepMarkup()
		local r = math.round(THEME.TextMuted.R * 255)
		local g = math.round(THEME.TextMuted.G * 255)
		local b = math.round(THEME.TextMuted.B * 255)
		return string.format('<font color="rgb(%d, %d, %d)"> | </font>', r, g, b)
	end

	local wmLabel = Instance.new("TextLabel")
	wmLabel.Name = "Text"
	wmLabel.RichText = true
	wmLabel.Text = string.format("%s%s0 FPS%s0ms Ping%s0%% CPU", titleName, getSepMarkup(), getSepMarkup(), getSepMarkup())
	wmLabel.Font = FONT
	wmLabel.TextSize = 13
	wmLabel.TextColor3 = THEME.TextPrimary
	wmLabel.BackgroundTransparency = 1
	wmLabel.Size = UDim2.new(0, 0, 1, 0)
	wmLabel.AutomaticSize = Enum.AutomaticSize.X
	wmLabel.TextXAlignment = Enum.TextXAlignment.Left
	wmLabel.LayoutOrder = 1
	wmLabel.ZIndex = 53
	wmLabel.Parent = ContentHolder
	table.insert(ThemedRegistry.PrimaryTexts, wmLabel)

	enableDrag(WatermarkFrame, WatermarkFrame)

	local function getPing()
		local ping = 0
		pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
		if ping <= 0 then
			pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
		end
		return math.max(0, ping)
	end

	local function getCpuUsage(dt)
		local cpu = 0
		pcall(function() cpu = math.floor(Stats.PerformanceStats.CPU:GetValue()) end)
		if cpu and cpu > 0 then return math.clamp(cpu, 1, 100) end
		local ratio = dt / (1 / 60)
		local memKb = collectgarbage("count")
		local memFactor = (memKb % 500) / 75
		local jitter = math.sin(tick() * 3) * 2.5
		return math.clamp(math.floor((ratio * 12) + memFactor + jitter + 6), 4, 96)
	end

	local frameCount = 0
	local lastUpdate = tick()
	local lastDelta = 0.016

	RunService.RenderStepped:Connect(function(dt)
		frameCount = frameCount + 1
		lastDelta = dt
		local now = tick()
		if now - lastUpdate >= 0.35 then
			local currentFps = math.floor(frameCount / (now - lastUpdate))
			local currentPing = getPing()
			local currentCpu = getCpuUsage(lastDelta)
			local sep = getSepMarkup()
			wmLabel.Text = string.format("%s%s%d FPS%s%dms Ping%s%d%% CPU", titleName, sep, currentFps, sep, currentPing, sep, currentCpu)
			frameCount = 0
			lastUpdate = now
		end
	end)

	local MobileToggleBtn = Instance.new("TextButton")
	MobileToggleBtn.Name = "MobileToggleBtn"
	MobileToggleBtn.Size = UDim2.new(0, 80, 0, 30)
	MobileToggleBtn.Position = UDim2.new(0, 16, 0.5, -15)
	MobileToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MobileToggleBtn.BorderSizePixel = 0
	MobileToggleBtn.Text = "Toggle"
	MobileToggleBtn.Font = FONT_BOLD
	MobileToggleBtn.TextSize = 14
	MobileToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	MobileToggleBtn.Parent = ScreenGui

	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.CardBgTop),
		ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
	})
	btnGrad.Rotation = 90
	btnGrad.Parent = MobileToggleBtn
	table.insert(ThemedRegistry.CardGradients, btnGrad)

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = MobileToggleBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = THEME.BorderMain
	btnStroke.Thickness = 1.2
	btnStroke.Parent = MobileToggleBtn
	table.insert(ThemedRegistry.MainStrokes, btnStroke)

	enableDrag(MobileToggleBtn, MobileToggleBtn)

	MobileToggleBtn.MouseButton1Click:Connect(function()
		MainFrame.Visible = not MainFrame.Visible
	end)

	local windowObj = {
		ScreenGui = ScreenGui,
		MainFrame = MainFrame,
		ConfigFeatureEntries = ConfigFeatureEntries,
		CreatedTabsCount = 0,
		Tabs = {},
		FirstTabName = nil
	}

	local function setupSettingsTab()
		local settingsPage = Instance.new("Frame")
		settingsPage.Name = "SettingsPage"
		settingsPage.BackgroundTransparency = 1
		settingsPage.Size = UDim2.new(1, 0, 1, 0)
		settingsPage.Visible = false
		settingsPage.Parent = ContentArea
		TabPages["Settings"] = settingsPage

		TabSubConfig["Settings"] = {
			{ iconText = "⚙", iconImg = getIcon("https://raw.githubusercontent.com/Essluau/icons/refs/heads/main/settings_.png", "settings_2.png"), page = nil }
		}

		local settingsLeft, settingsRight = createTabColumns(settingsPage)
		local _, settingsLeftContent = createSectionCard(settingsLeft, "Settings", 280, 1)

		createToggle(settingsLeftContent, "Watermark", false, nil, function(state)
			WatermarkFrame.Visible = state
		end, "__theme_watermark")

		createDropdown(settingsLeftContent, "Font", "Tahoma", {"SourceSans", "Roboto", "Gotham", "Ubuntu", "Arial", "Tahoma"}, 50, function(selectedFont)
			applyGlobalFont(ScreenGui, selectedFont)
		end, "__theme_font")

		createColorPickerRow(settingsLeftContent, "Accent", defaultAccent, function(chosenColor)
			applyAccentColor(chosenColor)
		end, "__theme_accent")

		local _, cfgRightCard = createSectionCard(settingsRight, "Configs", 440, 1)

		local cfgListBox = Instance.new("Frame")
		cfgListBox.Size = UDim2.new(1, 0, 0, 175)
		cfgListBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		cfgListBox.BorderSizePixel = 0
		cfgListBox.ClipsDescendants = true
		cfgListBox.Parent = cfgRightCard

		local cfgListGrad = Instance.new("UIGradient")
		cfgListGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, THEME.WindowBgTop),
			ColorSequenceKeypoint.new(1, THEME.WindowBgBottom)
		})
		cfgListGrad.Rotation = 90
		cfgListGrad.Parent = cfgListBox
		table.insert(ThemedRegistry.WindowGradients, cfgListGrad)

		local cfgListStroke = Instance.new("UIStroke")
		cfgListStroke.Color = THEME.BorderElement
		cfgListStroke.Thickness = 1
		cfgListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cfgListStroke.Parent = cfgListBox
		table.insert(ThemedRegistry.ElementStrokes, cfgListStroke)

		local cfgScroll = Instance.new("ScrollingFrame")
		cfgScroll.Size = UDim2.new(1, -6, 1, -6)
		cfgScroll.Position = UDim2.new(0, 3, 0, 3)
		cfgScroll.BackgroundTransparency = 1
		cfgScroll.BorderSizePixel = 0
		cfgScroll.ScrollBarThickness = 3
		cfgScroll.ScrollBarImageColor3 = THEME.AccentLilacLight
		cfgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		cfgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		cfgScroll.ClipsDescendants = true
		cfgScroll.Parent = cfgListBox
		table.insert(ThemedRegistry.Scrollbars, cfgScroll)

		local cfgListLayout = Instance.new("UIListLayout")
		cfgListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		cfgListLayout.Padding = UDim.new(0, 2)
		cfgListLayout.Parent = cfgScroll

		local _, nameBoxInput = createInput(cfgRightCard, "Name", "Config name...", "default")

		refreshConfigListDisplay = function()
			for _, child in ipairs(cfgScroll:GetChildren()) do
				if child:IsA("TextButton") then child:Destroy() end
			end

			local configsFound = {}
			local function scanConfigs(folderName)
				if listfiles and isfolder and isfolder(folderName) then
					local success, files = pcall(function() return listfiles(folderName) end)
					if success and files then
						for _, filePath in ipairs(files) do
							local rawName = filePath:match("([^/\\]+)$") or filePath
							if not table.find(configsFound, rawName) then
								table.insert(configsFound, rawName)
							end
						end
					end
				end
			end
			scanConfigs(cfgFolder)

			for k, _ in pairs(FallbackConfigStore) do
				if not table.find(configsFound, k) then table.insert(configsFound, k) end
			end

			if #configsFound == 0 then table.insert(configsFound, "default.json") end
			table.sort(configsFound)

			for idx, fileName in ipairs(configsFound) do
				local itemBtn = Instance.new("TextButton")
				itemBtn.Size = UDim2.new(1, 0, 0, 24)
				itemBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				itemBtn.BackgroundTransparency = (fileName == selectedConfigFileName and 0.88 or 1)
				itemBtn.BorderSizePixel = 0
				itemBtn.Text = ""
				itemBtn.AutoButtonColor = false
				itemBtn.LayoutOrder = idx
				itemBtn.Parent = cfgScroll

				local itemLabel = Instance.new("TextLabel")
				itemLabel.Text = fileName
				itemLabel.Font = FONT
				itemLabel.TextSize = 13
				itemLabel.TextColor3 = (fileName == selectedConfigFileName and THEME.AccentLilacLight or THEME.TextPrimary)
				itemLabel.TextXAlignment = Enum.TextXAlignment.Left
				itemLabel.BackgroundTransparency = 1
				itemLabel.Position = UDim2.new(0, 8, 0, 0)
				itemLabel.Size = UDim2.new(1, -16, 1, 0)
				itemLabel.Parent = itemBtn

				applyFontToObject(itemLabel)

				itemBtn.MouseButton1Click:Connect(function()
					selectedConfigFileName = fileName
					nameBoxInput.Text = fileName:gsub("%.json$", "")
					for _, other in ipairs(cfgScroll:GetChildren()) do
						if other:IsA("TextButton") and other:FindFirstChildOfClass("TextLabel") then
							local lbl = other:FindFirstChildOfClass("TextLabel")
							if lbl.Text == selectedConfigFileName then
								other.BackgroundTransparency = 0.88
								lbl.TextColor3 = THEME.AccentLilacLight
							else
								other.BackgroundTransparency = 1
								lbl.TextColor3 = THEME.TextPrimary
							end
						end
					end
				end)
			end
		end

		local function saveConfigHandler()
			local cfgName = nameBoxInput.Text
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = "default" end
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end

			local dumpData = {}
			for key, entry in pairs(ConfigFeatureEntries) do
				pcall(function() dumpData[key] = entry.Get() end)
			end

			local encoded = HttpService:JSONEncode(dumpData)
			if writefile then
				pcall(function() writefile(cfgFolder .. "/" .. cfgName, encoded) end)
			else
				FallbackConfigStore[cfgName] = encoded
			end
			selectedConfigFileName = cfgName
			refreshConfigListDisplay()
		end

		local function loadConfigHandler()
			local cfgName = nameBoxInput.Text
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = selectedConfigFileName end
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end

			local content = nil
			if readfile and isfile then
				if isfile(cfgFolder .. "/" .. cfgName) then
					pcall(function() content = readfile(cfgFolder .. "/" .. cfgName) end)
				end
			elseif FallbackConfigStore[cfgName] then
				content = FallbackConfigStore[cfgName]
			end

			if content then
				local success, decoded = pcall(function() return HttpService:JSONDecode(content) end)
				if success and type(decoded) == "table" then
					for featureName, val in pairs(decoded) do
						if ConfigFeatureEntries[featureName] then
							pcall(function() ConfigFeatureEntries[featureName].Set(val) end)
						end
					end
				end
			end
			selectedConfigFileName = cfgName
			refreshConfigListDisplay()
		end

		local function deleteConfigHandler()
			local cfgName = nameBoxInput.Text
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = selectedConfigFileName end
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end

			if delfile and isfile and isfile(cfgFolder .. "/" .. cfgName) then
				pcall(function() delfile(cfgFolder .. "/" .. cfgName) end)
			end
			FallbackConfigStore[cfgName] = nil
			refreshConfigListDisplay()
		end

		createDualActionButtons(cfgRightCard, "Load Config", loadConfigHandler, "Save Config", saveConfigHandler)
		createDualActionButtons(cfgRightCard, "Create Config", saveConfigHandler, "Delete Config", deleteConfigHandler)
		createActionButton(cfgRightCard, "Refresh Configs", refreshConfigListDisplay)

		refreshConfigListDisplay()
	end

	local function rebuildTabButtons()
		for _, child in ipairs(TabsHolder:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		TabButtons = {}

		local allTabs = {}
		for _, tabName in ipairs(windowObj.Tabs) do
			table.insert(allTabs, tabName)
		end
		table.insert(allTabs, "Settings")

		for i, tabName in ipairs(allTabs) do
			local TabBtn = Instance.new("TextButton")
			TabBtn.Name = tabName
			TabBtn.LayoutOrder = i
			TabBtn.Size = UDim2.new(1 / #allTabs, -4, 1, 0)
			TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TabBtn.BorderSizePixel = 0
			TabBtn.Text = ""
			TabBtn.AutoButtonColor = false
			TabBtn.ClipsDescendants = true
			TabBtn.Parent = TabsHolder

			local tabBaseGrad = Instance.new("UIGradient")
			tabBaseGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, THEME.CardBgTop),
				ColorSequenceKeypoint.new(1, THEME.CardBgBottom)
			})
			tabBaseGrad.Rotation = 90
			tabBaseGrad.Parent = TabBtn
			table.insert(ThemedRegistry.CardGradients, tabBaseGrad)

			local isInitial = (tabName == (windowObj.FirstTabName or "Settings"))

			local tabActiveOverlay = Instance.new("Frame")
			tabActiveOverlay.Size = UDim2.new(1, 0, 1, 0)
			tabActiveOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			tabActiveOverlay.BorderSizePixel = 0
			tabActiveOverlay.BackgroundTransparency = (isInitial and 0 or 1)
			tabActiveOverlay.ZIndex = 2
			tabActiveOverlay.Parent = TabBtn

			local tabActiveGrad = Instance.new("UIGradient")
			tabActiveGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 36, 58)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 20, 36))
			})
			tabActiveGrad.Rotation = 90
			tabActiveGrad.Parent = tabActiveOverlay
			table.insert(ThemedRegistry.TabActiveGradients, tabActiveGrad)

			local tabStroke = Instance.new("UIStroke")
			tabStroke.Color = (isInitial and THEME.BorderTabActive) or THEME.BorderCard
			tabStroke.Thickness = 1
			tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			tabStroke.Parent = TabBtn

			local activeHighlight = Instance.new("Frame")
			activeHighlight.AnchorPoint = Vector2.new(0.5, 0)
			activeHighlight.Position = UDim2.new(0.5, 0, 0, 0)
			activeHighlight.Size = (isInitial and UDim2.new(1, 0, 0, 1)) or UDim2.new(0, 0, 0, 1)
			activeHighlight.BackgroundColor3 = THEME.AccentLilacLight
			activeHighlight.BorderSizePixel = 0
			activeHighlight.BackgroundTransparency = (isInitial and 0 or 1)
			activeHighlight.ZIndex = 5
			activeHighlight.Parent = TabBtn
			table.insert(ThemedRegistry.AccentHighlights, activeHighlight)

			local tabLabel = Instance.new("TextLabel")
			tabLabel.Text = tabName
			tabLabel.Font = FONT
			tabLabel.TextSize = 14
			tabLabel.TextColor3 = (isInitial and THEME.TextPrimary) or THEME.TextSecondary
			tabLabel.BackgroundTransparency = 1
			tabLabel.Size = UDim2.new(1, 0, 1, 0)
			tabLabel.ZIndex = 4
			tabLabel.Parent = TabBtn

			applyFontToObject(tabLabel)

			TabButtons[tabName] = {
				Button = TabBtn,
				ActiveOverlay = tabActiveOverlay,
				Stroke = tabStroke,
				Highlight = activeHighlight,
				Label = tabLabel
			}

			TabBtn.MouseButton1Click:Connect(function()
				switchTab(tabName)
			end)
		end
	end

	setupSettingsTab()
	rebuildTabButtons()

	function windowObj:CreateTab(tabName)
		assert(self.CreatedTabsCount < 4, "Maximum 4 custom tabs are allowed (5th tab is always Settings).")
		self.CreatedTabsCount = self.CreatedTabsCount + 1
		table.insert(self.Tabs, tabName)

		if not self.FirstTabName then
			self.FirstTabName = tabName
		end

		local tabPage = Instance.new("Frame")
		tabPage.Name = tabName .. "Page"
		tabPage.BackgroundTransparency = 1
		tabPage.Size = UDim2.new(1, 0, 1, 0)
		tabPage.Visible = (self.FirstTabName == tabName)
		tabPage.ClipsDescendants = false
		tabPage.Parent = ContentArea
		TabPages[tabName] = tabPage

		TabSubConfig[tabName] = {}
		savedSubTabs[tabName] = 1

		local tabObj = {
			Name = tabName,
			Page = tabPage,
			SubCount = 0,
			SubPages = {}
		}

		function tabObj:CreateSubTab(subCfg)
			subCfg = subCfg or {}
			self.SubCount = self.SubCount + 1
			local subIdx = self.SubCount
			assert(subIdx <= 2, "A maximum of 2 subtabs/icons can be created per tab.")

			local subPage = Instance.new("Frame")
			subPage.Name = tabName .. "SubPage" .. subIdx
			subPage.BackgroundTransparency = 1
			subPage.Size = UDim2.new(1, 0, 1, 0)
			subPage.Visible = (subIdx == 1)
			subPage.Parent = tabPage

			local leftCol, rightCol = createTabColumns(subPage)

			local iconImgStr = ""
			if subCfg.Icon and (subCfg.Icon:find("http") or subCfg.Icon:find("rbxassetid")) then
				iconImgStr = getIcon(subCfg.Icon, subCfg.IconFileName)
			end

			local subEntry = {
				iconText = subCfg.IconText or (iconImgStr == "" and (subCfg.Icon or "❖")) or "",
				iconImg = iconImgStr,
				sizeActive = subCfg.ActiveSize or 24,
				sizeInactive = subCfg.InactiveSize or 20,
				page = subPage
			}

			table.insert(TabSubConfig[tabName], subEntry)

			local subTabObj = {
				Page = subPage,
				Left = leftCol,
				Right = rightCol
			}

			local function getColumn(side)
				if side == "Right" or side == 2 then return rightCol end
				return leftCol
			end

			function subTabObj:CreateCard(side, cardTitle, sizeY)
				local col = getColumn(side)
				local _, content = createSectionCard(col, cardTitle, sizeY, 1)

				local cardObj = {
					Container = content
				}

				function cardObj:AddToggle(opt)
					return createToggle(content, opt.Name or "Toggle", opt.Default, opt.Type, opt.Callback, opt.Flag)
				end

				function cardObj:AddSlider(opt)
					return createCompactSlider(
						content,
						opt.Name or "Slider",
						opt.Default or opt.Min or 0,
						opt.Min or 0,
						opt.Max or 100,
						opt.Callback,
						opt.Flag,
						opt.Precise or opt.Decimals or 0
					)
				end

				function cardObj:AddDropdown(opt)
					return createDropdown(content, opt.Name or "Dropdown", opt.Default or opt.Options[1], opt.Options or {}, opt.ZIndex or 20, opt.Callback, opt.Flag)
				end

				function cardObj:AddMultiDropdown(opt)
					return createMultiDropdown(content, opt.Name or "MultiDropdown", opt.Default or {}, opt.Options or {}, opt.ZIndex or 20, opt.Callback, opt.Flag)
				end

				function cardObj:AddInput(opt)
					return createInput(content, opt.Name or "Input", opt.Placeholder, opt.Default, opt.Callback, opt.Flag)
				end

				function cardObj:AddColorPicker(opt)
					return createColorPickerRow(content, opt.Name or "Color", opt.Default, opt.Callback, opt.Flag)
				end

				function cardObj:AddButton(opt)
					return createActionButton(content, opt.Name or "Button", opt.Callback)
				end

				function cardObj:AddDualButtons(opt)
					return createDualActionButtons(content, opt.Text1 or "Button 1", opt.Callback1, opt.Text2 or "Button 2", opt.Callback2)
				end

				function cardObj:AddPlayerList(opt)
					return createPlayerList(content, opt.Title or "Players", opt.SizeY or 340, opt.Elements, {
						TeamFilter = opt.TeamFilter or "All",
						Filter = opt.Filter
					})
				end

				return cardObj
			end

			function subTabObj:CreatePlayerList(side, opt)
				local col = getColumn(side)
				return createPlayerList(col, opt.Title or "Players", opt.SizeY or 340, opt.Elements, {
					TeamFilter = opt.TeamFilter or "All",
					Filter = opt.Filter
				})
			end

			for _, obj in ipairs(subPage:GetDescendants()) do
				applyFontToObject(obj)
			end

			return subTabObj
		end

		rebuildTabButtons()
		if self.CreatedTabsCount == 1 then
			switchTab(tabName)
		end

		for _, obj in ipairs(tabPage:GetDescendants()) do
			applyFontToObject(obj)
		end

		return tabObj
	end

	applyGlobalFont(ScreenGui, "Tahoma")
	applyAccentColor(defaultAccent)

	return windowObj
end

return Library
