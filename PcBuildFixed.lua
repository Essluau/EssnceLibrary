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
			local currentScale = 1
			local s = targetFrame:FindFirstChildOfClass("UIScale")
			if s then currentScale = s.Scale end

			local delta = (input.Position - dragStart) / currentScale
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local function enableResize(targetFrame, minSize, maxSize)
	local resizing = false
	local startSize = UDim2.new()
	local startInputPos = Vector2.new()

	local resizeGrip = Instance.new("TextButton")
	resizeGrip.Name = "ResizeGrip"
	resizeGrip.AnchorPoint = Vector2.new(1, 1)
	resizeGrip.Position = UDim2.new(1, 0, 1, 0)
	resizeGrip.Size = UDim2.new(0, 12, 0, 12)
	resizeGrip.BackgroundTransparency = 1
	resizeGrip.Text = ""
	resizeGrip.AutoButtonColor = false
	resizeGrip.ZIndex = 60
	resizeGrip.Parent = targetFrame

	local gripLabel = Instance.new("TextLabel")
	gripLabel.Text = "⋰"
	gripLabel.Font = FONT
	gripLabel.TextSize = 13
	gripLabel.TextColor3 = THEME.TextMuted
	gripLabel.BackgroundTransparency = 1
	gripLabel.Size = UDim2.new(1, 0, 1, 0)
	gripLabel.ZIndex = 61
	gripLabel.Parent = resizeGrip
	table.insert(ThemedRegistry.MutedTexts, gripLabel)

	resizeGrip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			startSize = targetFrame.Size
			startInputPos = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)

	resizeGrip.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local currentScale = 1
			local s = targetFrame:FindFirstChildOfClass("UIScale")
			if s then currentScale = s.Scale end

			local deltaX = (input.Position.X - startInputPos.X) / currentScale
			local deltaY = (input.Position.Y - startInputPos.Y) / currentScale

			local newW = math.clamp(startSize.X.Offset + deltaX, minSize.X, maxSize and maxSize.X or 1400)
			local newH = math.clamp(startSize.Y.Offset + deltaY, minSize.Y, maxSize and maxSize.Y or 1000)

			targetFrame.Size = UDim2.new(0, newW, 0, newH)
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
	ScreenGui.IgnoreGuiInset = true

	pcall(function()
		ScreenGui.Parent = (gethui and gethui()) or CoreGui
	end)
	if not ScreenGui.Parent then
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end

	local customCursorEnabled = false
	local customCursorColor = Color3.fromRGB(255, 255, 255)

	local customCursorImage = Instance.new("ImageLabel")
	customCursorImage.Name = "CustomCursor"
	customCursorImage.Size = UDim2.new(0, 20, 0, 20)
	customCursorImage.AnchorPoint = Vector2.new(0, 0)
	customCursorImage.Position = UDim2.new(0, 0, 0, 0)
	customCursorImage.BackgroundTransparency = 1
	customCursorImage.BorderSizePixel = 0
	customCursorImage.Image = "rbxassetid://107466177907852"
	customCursorImage.ImageColor3 = customCursorColor
	customCursorImage.Rotation = -45
	customCursorImage.Visible = false
	customCursorImage.Active = false
	customCursorImage.Selectable = false
	customCursorImage.ZIndex = 2147483647
	customCursorImage.Parent = ScreenGui

	pcall(function()
		ScreenGui.Destroying:Connect(function()
			UserInputService.MouseIconEnabled = true
		end)
	end)

	UserInputService:GetPropertyChangedSignal("MouseIconEnabled"):Connect(function()
		if customCursorEnabled then
			UserInputService.MouseIconEnabled = false
		end
	end)

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

	local baseWidth = 563
	local baseHeight = 650

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.Size = config.Size or config.size or UDim2.new(0, baseWidth, 0, baseHeight)
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = false
	MainFrame.ZIndex = 10
	MainFrame.Parent = ScreenGui

	local modalHelper = Instance.new("TextButton")
	modalHelper.Name = "ModalHelper"
	modalHelper.BackgroundTransparency = 1
	modalHelper.Size = UDim2.new(0, 0, 0, 0)
	modalHelper.Position = UDim2.new(0, 0, 0, 0)
	modalHelper.Text = ""
	modalHelper.Modal = true
	modalHelper.Parent = MainFrame

	local wasFirstPersonLocked = false

	local function handleMenuVisibility(visible)
		if visible then
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCurrentPosition then
				wasFirstPersonLocked = true
			end
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		else
			local camera = workspace.CurrentCamera
			local isFirstPerson = false
			if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and camera then
				if (camera.CFrame.Position - LocalPlayer.Character.Head.Position).Magnitude < 1.5 then
					isFirstPerson = true
				end
			end
			if wasFirstPersonLocked or isFirstPerson then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				wasFirstPersonLocked = false
			end
		end
	end

	MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		handleMenuVisibility(MainFrame.Visible)
	end)

	local function getAncestorCard(obj)
		local curr = obj and obj.Parent
		while curr and curr ~= ScreenGui do
			if curr.Parent and (curr.Parent:IsA("ScrollingFrame") or curr.Parent == ContentArea or curr.Parent.Name:match("Page$") or curr.Parent.Name:match("Col$")) then
				return curr
			end
			curr = curr.Parent
		end
		return nil
	end

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
	MainStroke.Thickness = 1.2
	MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	MainStroke.Parent = MainFrame
	table.insert(ThemedRegistry.MainStrokes, MainStroke)

	local UiScale = Instance.new("UIScale")
	UiScale.Parent = MainFrame

	local function updateScale()
		local camera = workspace.CurrentCamera
		if camera then
			local vp = camera.ViewportSize
			local scaleX = (vp.X - 20) / baseWidth
			local scaleY = (vp.Y - 20) / baseHeight
			UiScale.Scale = math.clamp(math.min(scaleX, scaleY, 1.0), 0.5, 1.0)
		end
	end
	updateScale()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end

	local TopTitle = Instance.new("TextLabel")
	TopTitle.Text = titleName
	TopTitle.Font = FONT
	TopTitle.TextSize = 13
	TopTitle.TextColor3 = THEME.TextSecondary
	TopTitle.TextXAlignment = Enum.TextXAlignment.Left
	TopTitle.BackgroundTransparency = 1
	TopTitle.Position = UDim2.new(0, 12, 0, 6)
	TopTitle.Size = UDim2.new(1, -24, 0, 16)
	TopTitle.ZIndex = 12
	TopTitle.Parent = MainFrame
	table.insert(ThemedRegistry.SecondaryTexts, TopTitle)

	enableDrag(TopTitle, MainFrame)
	enableDrag(MainFrame, MainFrame)
	enableResize(MainFrame, Vector2.new(460, 420), Vector2.new(1200, 900))

	local TabsHolder = Instance.new("Frame")
	TabsHolder.BackgroundTransparency = 1
	TabsHolder.Position = UDim2.new(0, 12, 0, 25)
	TabsHolder.Size = UDim2.new(1, -24, 0, 24)
	TabsHolder.ZIndex = 11
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
	SubHeaderBar.Position = UDim2.new(0, 12, 0, 53)
	SubHeaderBar.Size = UDim2.new(1, -24, 0, 32)
	SubHeaderBar.ClipsDescendants = true
	SubHeaderBar.ZIndex = 11
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
	SubTab1Btn.Size = UDim2.new(0.5, -2, 1, -4)
	SubTab1Btn.Position = UDim2.new(0, 2, 0, 2)
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
	subTab1Icon.Size = UDim2.new(0, 18, 0, 18)
	subTab1Icon.BackgroundTransparency = 1
	subTab1Icon.Image = ""
	subTab1Icon.ImageColor3 = THEME.AccentLilacLight
	subTab1Icon.ZIndex = 4
	subTab1Icon.Parent = SubTab1Btn

	local subTab1Label = Instance.new("TextLabel")
	subTab1Label.Text = "❖"
	subTab1Label.Font = FONT_BOLD
	subTab1Label.TextSize = 18
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
	SubTab2Btn.Size = UDim2.new(0.5, -2, 1, -4)
	SubTab2Btn.Position = UDim2.new(0.5, 0, 0, 2)
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
	subTab2Icon.Size = UDim2.new(0, 16, 0, 16)
	subTab2Icon.BackgroundTransparency = 1
	subTab2Icon.Image = ""
	subTab2Icon.ImageColor3 = THEME.TextSecondary
	subTab2Icon.ZIndex = 4
	subTab2Icon.Parent = SubTab2Btn

	local subTab2Label = Instance.new("TextLabel")
	subTab2Label.Text = "☁"
	subTab2Label.Font = FONT_BOLD
	subTab2Label.TextSize = 18
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
	ContentArea.Position = UDim2.new(0, 12, 0, 91)
	ContentArea.Size = UDim2.new(1, -24, 1, -97)
	ContentArea.ClipsDescendants = false
	ContentArea.ZIndex = 11
	ContentArea.Parent = MainFrame

	local currentMainTab = nil
	local currentSubIndex = 1
	local TabButtons = {}
	local TabPages = {}
	local TabSubConfig = {}
	local savedSubTabs = {}

	local subAnimInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
		local targetSize1 = isFirst and (item1 and item1.sizeActive or 18) or (item1 and item1.sizeInactive or 15)
		local targetSize2 = (not isFirst) and (item2 and item2.sizeActive or 18) or (item2 and item2.sizeInactive or 15)

		TweenService:Create(subTab1ActiveOverlay, subAnimInfo, {BackgroundTransparency = isFirst and 0 or 1}):Play()
		TweenService:Create(subTab1Stroke, subAnimInfo, {Color = isFirst and THEME.BorderTabActive or THEME.BorderCard}):Play()
		TweenService:Create(subTab1Label, subAnimInfo, {
			TextColor3 = isFirst and THEME.AccentLilacLight or THEME.TextSecondary,
			TextSize = isFirst and 18 or 15
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
			TextSize = (not isFirst) and 18 or 15
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
		local resizeInfo = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

		if subCount <= 1 then
			subTab1Label.Text = cfg[1] and cfg[1].iconText or "❖"
			subTab1Icon.Image = cfg[1] and cfg[1].iconImg or ""
			subTab1Label.Visible = (subTab1Icon.Image == "")

			TweenService:Create(SubTab1Btn, resizeInfo, {
				Size = UDim2.new(1, -4, 1, -4),
				Position = UDim2.new(0, 2, 0, 2)
			}):Play()

			local t2 = TweenService:Create(SubTab2Btn, resizeInfo, {
				Size = UDim2.new(0, 0, 1, -4),
				Position = UDim2.new(1, -2, 0, 2)
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
				Size = UDim2.new(0.5, -2, 1, -4),
				Position = UDim2.new(0, 2, 0, 2)
			}):Play()

			TweenService:Create(SubTab2Btn, resizeInfo, {
				Size = UDim2.new(0.5, -2, 1, -4),
				Position = UDim2.new(0.5, 0, 0, 2)
			}):Play()

			local activeSub = savedSubTabs[mainTabName] or 1
			switchSubTab(activeSub)
		end
	end

	local tabAnimInfo = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
		local parentCard = getAncestorCard(parentRow)
		local parentCol = parentCard and parentCard.Parent

		local cpSlot = Instance.new("Frame")
		cpSlot.Size = UDim2.new(0, 30, 0, 12)
		cpSlot.Position = UDim2.new(1, offsetX, 0.5, -6)
		cpSlot.BackgroundColor3 = Color3.fromRGB(15, 11, 20)
		cpSlot.BorderSizePixel = 0
		cpSlot.Parent = parentRow

		local cpCorner = Instance.new("UICorner")
		cpCorner.CornerRadius = UDim.new(0, 2)
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
		cpBtn.Size = UDim2.new(1, 0, 1, 0)
		cpBtn.BackgroundTransparency = 1
		cpBtn.Text = ""
		cpBtn.AutoButtonColor = false
		cpBtn.ZIndex = 10
		cpBtn.Parent = cpSlot

		local pickerFrame = Instance.new("Frame")
		pickerFrame.Name = "ColorPickerPalette"
		pickerFrame.Size = UDim2.new(0, 150, 0, 0)
		pickerFrame.Position = UDim2.new(1, -150, 1, 4)
		pickerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		pickerFrame.BorderSizePixel = 0
		pickerFrame.ClipsDescendants = true
		pickerFrame.Visible = false
		pickerFrame.Active = true
		pickerFrame.ZIndex = 350
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
		pickerTopLine.ZIndex = 355
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
		svMap.Size = UDim2.new(0, 114, 0, 96)
		svMap.Position = UDim2.new(0, 6, 0, 8)
		svMap.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		svMap.BorderSizePixel = 0
		svMap.Text = ""
		svMap.AutoButtonColor = false
		svMap.ClipsDescendants = true
		svMap.ZIndex = 351
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
		satOverlay.ZIndex = 352
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
		valOverlay.ZIndex = 353
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
		svCursor.ZIndex = 354
		svCursor.Parent = svMap

		local svCursorStroke = Instance.new("UIStroke")
		svCursorStroke.Color = Color3.fromRGB(15, 11, 20)
		svCursorStroke.Thickness = 1
		svCursorStroke.Parent = svCursor

		local hueBar = Instance.new("TextButton")
		hueBar.Name = "HueBar"
		hueBar.Size = UDim2.new(0, 14, 0, 96)
		hueBar.Position = UDim2.new(0, 128, 0, 8)
		hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueBar.BorderSizePixel = 0
		hueBar.Text = ""
		hueBar.AutoButtonColor = false
		hueBar.ClipsDescendants = false
		hueBar.ZIndex = 351
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
		hueCursor.ZIndex = 354
		hueCursor.Parent = hueBar

		local hueCursorStroke = Instance.new("UIStroke")
		hueCursorStroke.Color = Color3.fromRGB(15, 11, 20)
		hueCursorStroke.Thickness = 1
		hueCursorStroke.Parent = hueCursor

		local previewBox = Instance.new("Frame")
		previewBox.Size = UDim2.new(0, 20, 0, 15)
		previewBox.Position = UDim2.new(0, 6, 0, 110)
		previewBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		previewBox.BorderSizePixel = 0
		previewBox.ZIndex = 351
		previewBox.Parent = pickerFrame

		local previewCorner = Instance.new("UICorner")
		previewCorner.CornerRadius = UDim.new(0, 2)
		previewCorner.Parent = previewBox

		local previewStroke = Instance.new("UIStroke")
		previewStroke.Color = THEME.BorderElement
		previewStroke.Thickness = 1
		previewStroke.Parent = previewBox
		table.insert(ThemedRegistry.ElementStrokes, previewStroke)

		local hexLabel = Instance.new("TextLabel")
		hexLabel.Font = FONT
		hexLabel.TextSize = 11
		hexLabel.TextColor3 = THEME.TextSecondary
		hexLabel.TextXAlignment = Enum.TextXAlignment.Left
		hexLabel.BackgroundTransparency = 1
		hexLabel.Position = UDim2.new(0, 32, 0, 110)
		hexLabel.Size = UDim2.new(1, -38, 0, 15)
		hexLabel.ZIndex = 351
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
			local closeTween = TweenService:Create(pickerFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 150, 0, 0)})
			closeTween:Play()
			closeTween.Completed:Connect(function()
				if not isPickerOpen then
					pickerFrame.Visible = false
					local openCount = math.max(0, (parentRow:GetAttribute("OpenPopups") or 1) - 1)
					parentRow:SetAttribute("OpenPopups", openCount)
					if openCount == 0 then
						parentRow.ZIndex = 1
						if parentRow.Parent and parentRow.Parent:IsA("GuiObject") then
							parentRow.Parent.ZIndex = 1
						end
						if parentCard then parentCard.ZIndex = 1 end
						if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 1 end
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

			local openUp = false
			if parentCol and parentCol:IsA("GuiObject") then
				local limitY = math.min(parentCol.AbsolutePosition.Y + parentCol.AbsoluteSize.Y, MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y)
				if (limitY - (cpSlot.AbsolutePosition.Y + cpSlot.AbsoluteSize.Y)) < 140 then
					openUp = true
				end
			end

			if openUp then
				pickerFrame.AnchorPoint = Vector2.new(0, 1)
				pickerFrame.Position = UDim2.new(1, -150, 0, -4)
				pickerTopLine.Position = UDim2.new(0, 0, 1, -1)
			else
				pickerFrame.AnchorPoint = Vector2.new(0, 0)
				pickerFrame.Position = UDim2.new(1, -150, 1, 4)
				pickerTopLine.Position = UDim2.new(0, 0, 0, 0)
			end

			local openCount = (parentRow:GetAttribute("OpenPopups") or 0) + 1
			parentRow:SetAttribute("OpenPopups", openCount)
			parentRow.ZIndex = 350
			if parentRow.Parent and parentRow.Parent:IsA("GuiObject") then
				parentRow.Parent.ZIndex = 50
			end
			if parentCard then parentCard.ZIndex = 350 end
			if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 50 end

			pickerFrame.Visible = true
			TweenService:Create(pickerFrame, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 150, 0, 134)}):Play()
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
		card.Size = UDim2.new(1, 0, 0, sizeY or 36)
		card.LayoutOrder = layoutOrder or 0
		card.ClipsDescendants = false
		card.ZIndex = 1
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
		titleLabel.TextSize = 13
		titleLabel.TextColor3 = THEME.TextPrimary
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.BackgroundTransparency = 1
		titleLabel.Position = UDim2.new(0, 8, 0, 3)
		titleLabel.Size = UDim2.new(1, -16, 0, 16)
		titleLabel.ZIndex = 3
		titleLabel.Parent = card
		table.insert(ThemedRegistry.PrimaryTexts, titleLabel)

		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.Position = UDim2.new(0, 8, 0, 22)
		container.Size = UDim2.new(1, -16, 0, 0)
		container.ClipsDescendants = false
		container.ZIndex = 1
		container.Parent = card

		local layout = Instance.new("UIListLayout")
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 4)
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
				container.Size = UDim2.new(1, -16, 0, h)
				card.Size = UDim2.new(1, 0, 0, h + 28)
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
		leftCol.ClipsDescendants = true
		leftCol.ZIndex = 1
		leftCol.Parent = pageParent
		table.insert(ThemedRegistry.Scrollbars, leftCol)

		local leftPad = Instance.new("UIPadding")
		leftPad.PaddingRight = UDim.new(0, 4)
		leftPad.Parent = leftCol

		local leftLayout = Instance.new("UIListLayout")
		leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
		leftLayout.Padding = UDim.new(0, 6)
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
		rightCol.ClipsDescendants = true
		rightCol.ZIndex = 1
		rightCol.Parent = pageParent
		table.insert(ThemedRegistry.Scrollbars, rightCol)

		local rightPad = Instance.new("UIPadding")
		rightPad.PaddingRight = UDim.new(0, 4)
		rightPad.Parent = rightCol

		local rightLayout = Instance.new("UIListLayout")
		rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
		rightLayout.Padding = UDim.new(0, 6)
		rightLayout.Parent = rightCol

		return leftCol, rightCol
	end

	local function createToggle(parent, text, defaultVal, rightType, callback, flag, onColorChanged, defaultColor)
		flag = flag or text
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 20)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.ZIndex = 1
		row.Parent = parent

		local box = Instance.new("TextButton")
		box.Size = UDim2.new(0, 12, 0, 12)
		box.Position = UDim2.new(0, 0, 0.5, -6)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.BorderSizePixel = 0
		box.Text = ""
		box.AutoButtonColor = false
		box.ZIndex = 3
		box.Parent = row

		local boxGrad = Instance.new("UIGradient")
		boxGrad.Rotation = 90
		boxGrad.Parent = box

		local boxStroke = Instance.new("UIStroke")
		boxStroke.Color = THEME.BorderElement
		boxStroke.Thickness = 1
		boxStroke.Parent = box
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)

		local labelWidthOffset = -26
		if rightType == "colorbox" then
			labelWidthOffset = -42
		elseif rightType == "dual_colorbox" or rightType == "colorbox2" then
			labelWidthOffset = -76
		end

		local label = Instance.new("TextLabel")
		label.Text = text
		label.Font = FONT
		label.TextSize = 13
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 20, 0, 0)
		label.Size = UDim2.new(1, labelWidthOffset, 1, 0)
		label.ZIndex = 3
		label.Parent = row

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
			cpInst1 = createSingleColorPicker(row, -30, defaultColor or Color3.fromRGB(255, 255, 255), onColorChanged)
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
			cpInst1 = createSingleColorPicker(row, -30, Color3.fromRGB(255, 255, 255), onColorChanged)
			cpInst2 = createSingleColorPicker(row, -64, Color3.fromRGB(180, 130, 230))

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
					return { R = col.R, G = col.G, B = col.B }
				end,
				Set = function(val)
					if type(val) == "table" and val.R then
						cpInst2.SetColor(Color3.new(val.R, val.G, val.B))
					end
				end
			}
		end

		box.MouseButton1Click:Connect(function()
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
		row.Size = UDim2.new(1, 0, 0, 24)
		row.BackgroundTransparency = 1
		row.ZIndex = 2
		row.Parent = parent

		local label = Instance.new("TextLabel")
		label.Text = labelText
		label.Font = FONT
		label.TextSize = 12
		label.TextColor3 = THEME.TextSecondary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 0, 0, 0)
		label.Size = UDim2.new(1, -50, 0, 13)
		label.ZIndex = 3
		label.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, label)

		local valLabel = Instance.new("TextLabel")
		valLabel.Text = (precise > 0) and string.format("%." .. precise .. "f", defaultVal) or tostring(math.floor(defaultVal))
		valLabel.Font = FONT
		valLabel.TextSize = 12
		valLabel.TextColor3 = THEME.TextPrimary
		valLabel.TextXAlignment = Enum.TextXAlignment.Right
		valLabel.BackgroundTransparency = 1
		valLabel.Position = UDim2.new(1, -50, 0, 0)
		valLabel.Size = UDim2.new(0, 50, 0, 13)
		valLabel.ZIndex = 3
		valLabel.Parent = row
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0, 6)
		bar.Position = UDim2.new(0, 0, 0, 15)
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

		local hitArea = Instance.new("TextButton")
		hitArea.Name = "HitArea"
		hitArea.Size = UDim2.new(1, 0, 0, 12)
		hitArea.Position = UDim2.new(0, 0, 0, 12)
		hitArea.BackgroundTransparency = 1
		hitArea.Text = ""
		hitArea.AutoButtonColor = false
		hitArea.ZIndex = 10
		hitArea.Parent = row

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
				currentVal = math.floor(rawVal + 0.5)
				valLabel.Text = tostring(currentVal)
			end

			fill.Size = UDim2.new(pct, 0, 1, 0)
			if callback then callback(currentVal) end
		end

		hitArea.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				if activeDropdownClose then activeDropdownClose() end
				isSliding = true
				updateSlider(input)
			end
		end)

		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isSliding = false
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateSlider(input)
			end
		end)

		hitArea.MouseEnter:Connect(function()
			TweenService:Create(barStroke, TweenInfo.new(0.12), {Color = THEME.AccentLilacLight}):Play()
		end)
		hitArea.MouseLeave:Connect(function()
			if not isSliding then
				TweenService:Create(barStroke, TweenInfo.new(0.12), {Color = THEME.BorderElement}):Play()
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
						currentVal = math.floor(currentVal + 0.5)
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

	local function createKeybind(parent, text, defaultKey, callback, flag, onKeyChanged)
		flag = flag or text
		local currentKey = defaultKey or Enum.KeyCode.Unknown
		if type(currentKey) == "string" then
			currentKey = Enum.KeyCode[currentKey] or Enum.KeyCode.Unknown
		end
		local isListening = false

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 20)
		row.BackgroundTransparency = 1
		row.ClipsDescendants = false
		row.ZIndex = 1
		row.Parent = parent

		local label = Instance.new("TextLabel")
		label.Text = text
		label.Font = FONT
		label.TextSize = 13
		label.TextColor3 = THEME.TextSecondary
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Position = UDim2.new(0, 0, 0, 0)
		label.Size = UDim2.new(1, -75, 1, 0)
		label.ZIndex = 3
		label.Parent = row
		table.insert(ThemedRegistry.SecondaryTexts, label)

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 70, 0, 18)
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, 0, 0.5, 0)
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		btn.BorderSizePixel = 0
		btn.Text = ""
		btn.AutoButtonColor = false
		btn.ZIndex = 4
		btn.Parent = row

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
		btnLabel.Font = FONT
		btnLabel.TextSize = 11
		btnLabel.TextColor3 = THEME.TextPrimary
		btnLabel.TextXAlignment = Enum.TextXAlignment.Center
		btnLabel.BackgroundTransparency = 1
		btnLabel.Size = UDim2.new(1, 0, 1, 0)
		btnLabel.ZIndex = 5
		btnLabel.Parent = btn
		table.insert(ThemedRegistry.PrimaryTexts, btnLabel)

		local numberKeyDisplay = {
			[Enum.KeyCode.Zero] = "0",
			[Enum.KeyCode.One] = "1",
			[Enum.KeyCode.Two] = "2",
			[Enum.KeyCode.Three] = "3",
			[Enum.KeyCode.Four] = "4",
			[Enum.KeyCode.Five] = "5",
			[Enum.KeyCode.Six] = "6",
			[Enum.KeyCode.Seven] = "7",
			[Enum.KeyCode.Eight] = "8",
			[Enum.KeyCode.Nine] = "9",
			[Enum.KeyCode.KeypadZero] = "0",
			[Enum.KeyCode.KeypadOne] = "1",
			[Enum.KeyCode.KeypadTwo] = "2",
			[Enum.KeyCode.KeypadThree] = "3",
			[Enum.KeyCode.KeypadFour] = "4",
			[Enum.KeyCode.KeypadFive] = "5",
			[Enum.KeyCode.KeypadSix] = "6",
			[Enum.KeyCode.KeypadSeven] = "7",
			[Enum.KeyCode.KeypadEight] = "8",
			[Enum.KeyCode.KeypadNine] = "9",
		}

		local function formatKeyName(key)
			if not key or key == Enum.KeyCode.Unknown then return "None" end
			if numberKeyDisplay[key] then
				return numberKeyDisplay[key]
			end
			return key.Name
		end

		local function updateDisplay()
			if isListening then
				btnLabel.Text = "..."
				btnLabel.TextColor3 = THEME.AccentLilacLight
				btnStroke.Color = THEME.AccentLilacLight
			else
				btnLabel.Text = "[" .. formatKeyName(currentKey) .. "]"
				btnLabel.TextColor3 = THEME.TextPrimary
				btnStroke.Color = THEME.BorderElement
			end
		end
		updateDisplay()

		btn.MouseButton1Click:Connect(function()
			if isListening then return end
			if activeDropdownClose then activeDropdownClose() end
			isListening = true
			updateDisplay()
		end)

		UserInputService.InputBegan:Connect(function(input, gpe)
			if isListening then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					local key = input.KeyCode
					if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace then
						currentKey = Enum.KeyCode.Unknown
					else
						currentKey = key
					end
					isListening = false
					updateDisplay()
					if onKeyChanged then pcall(onKeyChanged, currentKey) end
				end
				return
			end

			local isTextBox = UserInputService:GetFocusedTextBox() ~= nil
			local isSpecialKey = (
				currentKey == Enum.KeyCode.RightShift or currentKey == Enum.KeyCode.LeftShift
				or currentKey == Enum.KeyCode.RightControl or currentKey == Enum.KeyCode.LeftControl
				or currentKey == Enum.KeyCode.RightAlt or currentKey == Enum.KeyCode.LeftAlt
			)

			if (not gpe or isSpecialKey) and not isTextBox and currentKey ~= Enum.KeyCode.Unknown and input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == currentKey then
					if callback then pcall(callback, currentKey) end
				end
			end
		end)

		local numberNameToKey = {
			["0"] = Enum.KeyCode.Zero,
			["1"] = Enum.KeyCode.One,
			["2"] = Enum.KeyCode.Two,
			["3"] = Enum.KeyCode.Three,
			["4"] = Enum.KeyCode.Four,
			["5"] = Enum.KeyCode.Five,
			["6"] = Enum.KeyCode.Six,
			["7"] = Enum.KeyCode.Seven,
			["8"] = Enum.KeyCode.Eight,
			["9"] = Enum.KeyCode.Nine,
		}

		ConfigFeatureEntries[flag] = {
			Get = function()
				return (currentKey and currentKey ~= Enum.KeyCode.Unknown) and currentKey.Name or "None"
			end,
			Set = function(val)
				if typeof(val) == "EnumItem" then
					currentKey = val
				elseif type(val) == "string" then
					pcall(function()
						currentKey = numberNameToKey[val] or Enum.KeyCode[val] or Enum.KeyCode.Unknown
					end)
				end
				updateDisplay()
				if onKeyChanged then pcall(onKeyChanged, currentKey) end
			end
		}

		return {
			Set = function(key)
				if typeof(key) == "EnumItem" then
					currentKey = key
				elseif type(key) == "string" then
					pcall(function() currentKey = numberNameToKey[key] or Enum.KeyCode[key] or Enum.KeyCode.Unknown end)
				end
				updateDisplay()
				if onKeyChanged then pcall(onKeyChanged, currentKey) end
			end,
			Get = function() return currentKey end,
			Instance = row
		}
	end
	local function createDropdown(parent, title, defaultVal, options, zIndexVal, onSelected, flag)[span_0](start_span)[span_0](end_span)
		flag = flag or title[span_1](start_span)[span_1](end_span)
		local parentCard = getAncestorCard(parent)[span_2](start_span)[span_2](end_span)
		local parentCol = parentCard and parentCard.Parent

		local row = Instance.new("Frame")[span_3](start_span)[span_3](end_span)
		row.Size = UDim2.new(1, 0, 0, 38)[span_4](start_span)[span_4](end_span)
		row.BackgroundTransparency = 1[span_5](start_span)[span_5](end_span)
		row.ZIndex = zIndexVal or 10[span_6](start_span)[span_6](end_span)
		row.ClipsDescendants = false[span_7](start_span)[span_7](end_span)
		row.Parent = parent[span_8](start_span)[span_8](end_span)

		local titleLabel = Instance.new("TextLabel")[span_9](start_span)[span_9](end_span)
		titleLabel.Text = title[span_10](start_span)[span_10](end_span)
		titleLabel.Font = FONT[span_11](start_span)[span_11](end_span)
		titleLabel.TextSize = 12[span_12](start_span)[span_12](end_span)
		titleLabel.TextColor3 = THEME.TextSecondary[span_13](start_span)[span_13](end_span)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left[span_14](start_span)[span_14](end_span)
		titleLabel.BackgroundTransparency = 1[span_15](start_span)[span_15](end_span)
		titleLabel.Size = UDim2.new(1, 0, 0, 13)[span_16](start_span)[span_16](end_span)
		titleLabel.ZIndex = row.ZIndex + 1[span_17](start_span)[span_17](end_span)
		titleLabel.Parent = row[span_18](start_span)[span_18](end_span)
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)[span_19](start_span)[span_19](end_span)

		local box = Instance.new("TextButton")[span_20](start_span)[span_20](end_span)
		box.Size = UDim2.new(1, 0, 0, 20)[span_21](start_span)[span_21](end_span)
		box.Position = UDim2.new(0, 0, 0, 16)[span_22](start_span)[span_22](end_span)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_23](start_span)[span_23](end_span)
		box.BorderSizePixel = 0[span_24](start_span)[span_24](end_span)
		box.Text = "[span_25](start_span)"[span_25](end_span)
		box.AutoButtonColor = false[span_26](start_span)[span_26](end_span)
		box.ZIndex = row.ZIndex + 1[span_27](start_span)[span_27](end_span)
		box.ClipsDescendants = false[span_28](start_span)[span_28](end_span)
		box.Parent = row[span_29](start_span)[span_29](end_span)

		local boxGrad = Instance.new("UIGradient")[span_30](start_span)[span_30](end_span)
		boxGrad.Color = ColorSequence.new({[span_31](start_span)[span_31](end_span)
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_32](start_span)[span_32](end_span)
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_33](start_span)[span_33](end_span)
		})[span_34](start_span)[span_34](end_span)
		boxGrad.Rotation = 90[span_35](start_span)[span_35](end_span)
		boxGrad.Parent = box[span_36](start_span)[span_36](end_span)
		table.insert(ThemedRegistry.ElementGradients, boxGrad)[span_37](start_span)[span_37](end_span)

		local boxStroke = Instance.new("UIStroke")[span_38](start_span)[span_38](end_span)
		boxStroke.Color = THEME.BorderElement[span_39](start_span)[span_39](end_span)
		boxStroke.Thickness = 1[span_40](start_span)[span_40](end_span)
		boxStroke.Parent = box[span_41](start_span)[span_41](end_span)
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)[span_42](start_span)[span_42](end_span)

		local valLabel = Instance.new("TextLabel")[span_43](start_span)[span_43](end_span)
		valLabel.Text = defaultVal[span_44](start_span)[span_44](end_span)
		valLabel.Font = FONT[span_45](start_span)[span_45](end_span)
		valLabel.TextSize = 12[span_46](start_span)[span_46](end_span)
		valLabel.TextColor3 = THEME.TextPrimary[span_47](start_span)[span_47](end_span)
		valLabel.TextXAlignment = Enum.TextXAlignment.Left[span_48](start_span)[span_48](end_span)
		valLabel.BackgroundTransparency = 1[span_49](start_span)[span_49](end_span)
		valLabel.Position = UDim2.new(0, 6, 0, 0)[span_50](start_span)[span_50](end_span)
		valLabel.Size = UDim2.new(1, -24, 1, 0)[span_51](start_span)[span_51](end_span)
		valLabel.ZIndex = box.ZIndex + 1[span_52](start_span)[span_52](end_span)
		valLabel.Parent = box[span_53](start_span)[span_53](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)[span_54](start_span)[span_54](end_span)

		local plus = Instance.new("TextLabel")[span_55](start_span)[span_55](end_span)
		plus.Text = "+[span_56](start_span)"[span_56](end_span)
		plus.Font = FONT[span_57](start_span)[span_57](end_span)
		plus.TextSize = 14[span_58](start_span)[span_58](end_span)
		plus.TextColor3 = THEME.TextSecondary[span_59](start_span)[span_59](end_span)
		plus.BackgroundTransparency = 1[span_60](start_span)[span_60](end_span)
		plus.Position = UDim2.new(1, -16, 0, 0)[span_61](start_span)[span_61](end_span)
		plus.Size = UDim2.new(0, 12, 1, 0)[span_62](start_span)[span_62](end_span)
		plus.ZIndex = box.ZIndex + 1[span_63](start_span)[span_63](end_span)
		plus.Parent = box[span_64](start_span)[span_64](end_span)
		table.insert(ThemedRegistry.SecondaryTexts, plus)[span_65](start_span)[span_65](end_span)

		local optionHeight = 20[span_66](start_span)[span_66](end_span)
		local fullHeight = (#options * optionHeight) + 4[span_67](start_span)[span_67](end_span)

		local listFrame = Instance.new("Frame")[span_68](start_span)[span_68](end_span)
		listFrame.Name = "DropList[span_69](start_span)"[span_69](end_span)
		listFrame.Size = UDim2.new(1, 0, 0, 0)[span_70](start_span)[span_70](end_span)
		listFrame.Position = UDim2.new(0, 0, 1, 2)[span_71](start_span)[span_71](end_span)
		listFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_72](start_span)[span_72](end_span)
		listFrame.BorderSizePixel = 0[span_73](start_span)[span_73](end_span)
		listFrame.ClipsDescendants = true[span_74](start_span)[span_74](end_span)
		listFrame.Visible = false[span_75](start_span)[span_75](end_span)
		listFrame.ZIndex = 320
		listFrame.Parent = box[span_76](start_span)[span_76](end_span)

		local listGrad = Instance.new("UIGradient")[span_77](start_span)[span_77](end_span)
		listGrad.Color = ColorSequence.new({[span_78](start_span)[span_78](end_span)
			ColorSequenceKeypoint.new(0, THEME.DropListTop),[span_79](start_span)[span_79](end_span)
			ColorSequenceKeypoint.new(0.45, THEME.DropListMid),[span_80](start_span)[span_80](end_span)
			ColorSequenceKeypoint.new(1, THEME.DropListBottom)[span_81](start_span)[span_81](end_span)
		})[span_82](start_span)[span_82](end_span)
		listGrad.Rotation = 90[span_83](start_span)[span_83](end_span)
		listGrad.Parent = listFrame[span_84](start_span)[span_84](end_span)
		table.insert(ThemedRegistry.DropListGradients, listGrad)[span_85](start_span)[span_85](end_span)

		local listStroke = Instance.new("UIStroke")[span_86](start_span)[span_86](end_span)
		listStroke.Color = THEME.BorderCard[span_87](start_span)[span_87](end_span)
		listStroke.Thickness = 1[span_88](start_span)[span_88](end_span)
		listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border[span_89](start_span)[span_89](end_span)
		listStroke.Parent = listFrame[span_90](start_span)[span_90](end_span)
		table.insert(ThemedRegistry.CardStrokes, listStroke)[span_91](start_span)[span_91](end_span)

		local listTopLine = Instance.new("Frame")[span_92](start_span)[span_92](end_span)
		listTopLine.Size = UDim2.new(1, 0, 0, 1)[span_93](start_span)[span_93](end_span)
		listTopLine.Position = UDim2.new(0, 0, 0, 0)[span_94](start_span)[span_94](end_span)
		listTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_95](start_span)[span_95](end_span)
		listTopLine.BorderSizePixel = 0[span_96](start_span)[span_96](end_span)
		listTopLine.ZIndex = 323
		listTopLine.Parent = listFrame[span_97](start_span)[span_97](end_span)

		local topLineGrad = Instance.new("UIGradient")[span_98](start_span)[span_98](end_span)
		topLineGrad.Color = ColorSequence.new({[span_99](start_span)[span_99](end_span)
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_100](start_span)[span_100](end_span)
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),[span_101](start_span)[span_101](end_span)
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))[span_102](start_span)[span_102](end_span)
		})[span_103](start_span)[span_103](end_span)
		topLineGrad.Parent = listTopLine[span_104](start_span)[span_104](end_span)
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)[span_105](start_span)[span_105](end_span)

		local listLayout = Instance.new("UIListLayout")[span_106](start_span)[span_106](end_span)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_107](start_span)[span_107](end_span)
		listLayout.Padding = UDim.new(0, 1)[span_108](start_span)[span_108](end_span)
		listLayout.Parent = listFrame[span_109](start_span)[span_109](end_span)

		local listPadding = Instance.new("UIPadding")[span_110](start_span)[span_110](end_span)
		listPadding.PaddingTop = UDim.new(0, 2)[span_111](start_span)[span_111](end_span)
		listPadding.PaddingBottom = UDim.new(0, 2)[span_112](start_span)[span_112](end_span)
		listPadding.Parent = listFrame[span_113](start_span)[span_113](end_span)

		local isOpen = false[span_114](start_span)[span_114](end_span)

		local function closeDropdown()[span_115](start_span)[span_115](end_span)
			if not isOpen then return end[span_116](start_span)[span_116](end_span)
			isOpen = false[span_117](start_span)[span_117](end_span)
			TweenService:Create(plus, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()[span_118](start_span)[span_118](end_span)
			local closeTween = TweenService:Create(listFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})[span_119](start_span)[span_119](end_span)
			closeTween:Play()[span_120](start_span)[span_120](end_span)
			closeTween.Completed:Connect(function()[span_121](start_span)[span_121](end_span)
				if not isOpen then[span_122](start_span)[span_122](end_span)
					listFrame.Visible = false[span_123](start_span)[span_123](end_span)
					row.ZIndex = zIndexVal or 10[span_124](start_span)[span_124](end_span)
					if parent and parent:IsA("GuiObject") then parent.ZIndex = 1 end
					if parentCard then parentCard.ZIndex = 1 end[span_125](start_span)[span_125](end_span)
					if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 1 end
				end[span_126](start_span)[span_126](end_span)
			end)[span_127](start_span)[span_127](end_span)
			if activeDropdownClose == closeDropdown then activeDropdownClose = nil end[span_128](start_span)[span_128](end_span)
		end[span_129](start_span)[span_129](end_span)

		local function openDropdown()[span_130](start_span)[span_130](end_span)
			if activeDropdownClose and activeDropdownClose ~= closeDropdown then activeDropdownClose() end[span_131](start_span)[span_131](end_span)
			isOpen = true[span_132](start_span)[span_132](end_span)
			activeDropdownClose = closeDropdown[span_133](start_span)[span_133](end_span)

			local openUp = false
			if parentCol and parentCol:IsA("GuiObject") then
				local limitY = math.min(parentCol.AbsolutePosition.Y + parentCol.AbsoluteSize.Y, MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y)
				local spaceBelow = limitY - (box.AbsolutePosition.Y + box.AbsoluteSize.Y)
				if spaceBelow < (fullHeight + 10) then
					openUp = true
				end
			end

			if openUp then
				listFrame.AnchorPoint = Vector2.new(0, 1)
				listFrame.Position = UDim2.new(0, 0, 0, -2)
				listTopLine.Position = UDim2.new(0, 0, 1, -1)
			else
				listFrame.AnchorPoint = Vector2.new(0, 0)
				listFrame.Position = UDim2.new(0, 0, 1, 2)
				listTopLine.Position = UDim2.new(0, 0, 0, 0)
			end

			row.ZIndex = 300
			if parent and parent:IsA("GuiObject") then parent.ZIndex = 50 end
			if parentCard then parentCard.ZIndex = 300 end
			if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 50 end

			listFrame.Visible = true[span_134](start_span)[span_134](end_span)
			TweenService:Create(plus, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()[span_135](start_span)[span_135](end_span)
			TweenService:Create(listFrame, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, fullHeight)}):Play()[span_136](start_span)[span_136](end_span)
		end[span_137](start_span)[span_137](end_span)

		box.MouseButton1Click:Connect(function()[span_138](start_span)[span_138](end_span)
			if isOpen then closeDropdown() else openDropdown() end[span_139](start_span)[span_139](end_span)
		end)[span_140](start_span)[span_140](end_span)

		for idx, optText in ipairs(options) do[span_141](start_span)[span_141](end_span)
			local optBtn = Instance.new("TextButton")[span_142](start_span)[span_142](end_span)
			optBtn.Size = UDim2.new(1, 0, 0, optionHeight)[span_143](start_span)[span_143](end_span)
			optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_144](start_span)[span_144](end_span)
			optBtn.BackgroundTransparency = 1[span_145](start_span)[span_145](end_span)
			optBtn.BorderSizePixel = 0[span_146](start_span)[span_146](end_span)
			optBtn.Text = "[span_147](start_span)"[span_147](end_span)
			optBtn.AutoButtonColor = false[span_148](start_span)[span_148](end_span)
			optBtn.LayoutOrder = idx[span_149](start_span)[span_149](end_span)
			optBtn.ZIndex = 321
			optBtn.Parent = listFrame[span_150](start_span)[span_150](end_span)

			local optLabel = Instance.new("TextLabel")[span_151](start_span)[span_151](end_span)
			optLabel.Text = optText[span_152](start_span)[span_152](end_span)
			optLabel.Font = FONT[span_153](start_span)[span_153](end_span)
			optLabel.TextSize = 12[span_154](start_span)[span_154](end_span)
			optLabel.TextColor3 = (optText == defaultVal and THEME.TextSelectedWhite) or THEME.TextMuted[span_155](start_span)[span_155](end_span)
			optLabel.TextXAlignment = Enum.TextXAlignment.Left[span_156](start_span)[span_156](end_span)
			optLabel.BackgroundTransparency = 1[span_157](start_span)[span_157](end_span)
			optLabel.Position = UDim2.new(0, 8, 0, 0)[span_158](start_span)[span_158](end_span)
			optLabel.Size = UDim2.new(1, -16, 1, 0)[span_159](start_span)[span_159](end_span)
			optLabel.ZIndex = 322
			optLabel.Parent = optBtn[span_160](start_span)[span_160](end_span)

			table.insert(ThemedRegistry.DropdownLabels, {[span_161](start_span)[span_161](end_span)
				Label = optLabel,[span_162](start_span)[span_162](end_span)
				IsActive = function() return valLabel.Text == optText end[span_163](start_span)[span_163](end_span)
			})[span_164](start_span)[span_164](end_span)

			optBtn.MouseEnter:Connect(function()[span_165](start_span)[span_165](end_span)
				TweenService:Create(optBtn, TweenInfo.new(0.10), {BackgroundTransparency = 0.94}):Play()[span_166](start_span)[span_166](end_span)
				optLabel.TextColor3 = THEME.TextSelectedWhite[span_167](start_span)[span_167](end_span)
			end)[span_168](start_span)[span_168](end_span)
			optBtn.MouseLeave:Connect(function()[span_169](start_span)[span_169](end_span)
				TweenService:Create(optBtn, TweenInfo.new(0.10), {BackgroundTransparency = 1}):Play()[span_170](start_span)[span_170](end_span)
				if valLabel.Text ~= optText then[span_171](start_span)[span_171](end_span)
					optLabel.TextColor3 = THEME.TextMuted[span_172](start_span)[span_172](end_span)
				end[span_173](start_span)[span_173](end_span)
			end)[span_174](start_span)[span_174](end_span)

			optBtn.MouseButton1Click:Connect(function()[span_175](start_span)[span_175](end_span)
				valLabel.Text = optText[span_176](start_span)[span_176](end_span)
				for _, child in ipairs(listFrame:GetChildren()) do[span_177](start_span)[span_177](end_span)
					if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then[span_178](start_span)[span_178](end_span)
						local lbl = child:FindFirstChildOfClass("TextLabel")[span_179](start_span)[span_179](end_span)
						lbl.TextColor3 = (lbl.Text == optText and THEME.TextSelectedWhite) or THEME.TextMuted[span_180](start_span)[span_180](end_span)
					end[span_181](start_span)[span_181](end_span)
				end[span_182](start_span)[span_182](end_span)
				closeDropdown()[span_183](start_span)[span_183](end_span)
				if onSelected then onSelected(optText) end[span_184](start_span)[span_184](end_span)
			end)[span_185](start_span)[span_185](end_span)
		end[span_186](start_span)[span_186](end_span)

		ConfigFeatureEntries[flag] = {[span_187](start_span)[span_187](end_span)
			Get = function() return valLabel.Text end,[span_188](start_span)[span_188](end_span)
			Set = function(newVal)[span_189](start_span)[span_189](end_span)
				if table.find(options, newVal) then[span_190](start_span)[span_190](end_span)
					valLabel.Text = newVal[span_191](start_span)[span_191](end_span)
					for _, child in ipairs(listFrame:GetChildren()) do[span_192](start_span)[span_192](end_span)
						if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then[span_193](start_span)[span_193](end_span)
							local lbl = child:FindFirstChildOfClass("TextLabel")[span_194](start_span)[span_194](end_span)
							lbl.TextColor3 = (lbl.Text == newVal and THEME.TextSelectedWhite) or THEME.TextMuted[span_195](start_span)[span_195](end_span)
						end[span_196](start_span)[span_196](end_span)
					end[span_197](start_span)[span_197](end_span)
					if onSelected then onSelected(newVal) end[span_198](start_span)[span_198](end_span)
				end[span_199](start_span)[span_199](end_span)
			end[span_200](start_span)[span_200](end_span)
		}[span_201](start_span)[span_201](end_span)

		return {[span_202](start_span)[span_202](end_span)
			Set = function(val) ConfigFeatureEntries[flag].Set(val) end,[span_203](start_span)[span_203](end_span)
			Get = function() return valLabel.Text end[span_204](start_span)[span_204](end_span)
		}[span_205](start_span)[span_205](end_span)
	end[span_206](start_span)[span_206](end_span)

	local function createMultiDropdown(parent, title, defaultOptions, allOptions, zIndexVal, callback, flag)[span_207](start_span)[span_207](end_span)
		flag = flag or title[span_208](start_span)[span_208](end_span)
		local parentCard = getAncestorCard(parent)[span_209](start_span)[span_209](end_span)
		local parentCol = parentCard and parentCard.Parent

		local row = Instance.new("Frame")[span_210](start_span)[span_210](end_span)
		row.Size = UDim2.new(1, 0, 0, 38)[span_211](start_span)[span_211](end_span)
		row.BackgroundTransparency = 1[span_212](start_span)[span_212](end_span)
		row.ZIndex = zIndexVal or 10[span_213](start_span)[span_213](end_span)
		row.ClipsDescendants = false[span_214](start_span)[span_214](end_span)
		row.Parent = parent[span_215](start_span)[span_215](end_span)

		local titleLabel = Instance.new("TextLabel")[span_216](start_span)[span_216](end_span)
		titleLabel.Text = title[span_217](start_span)[span_217](end_span)
		titleLabel.Font = FONT[span_218](start_span)[span_218](end_span)
		titleLabel.TextSize = 12[span_219](start_span)[span_219](end_span)
		titleLabel.TextColor3 = THEME.TextSecondary[span_220](start_span)[span_220](end_span)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left[span_221](start_span)[span_221](end_span)
		titleLabel.BackgroundTransparency = 1[span_222](start_span)[span_222](end_span)
		titleLabel.Size = UDim2.new(1, 0, 0, 13)[span_223](start_span)[span_223](end_span)
		titleLabel.ZIndex = row.ZIndex + 1[span_224](start_span)[span_224](end_span)
		titleLabel.Parent = row[span_225](start_span)[span_225](end_span)
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)[span_226](start_span)[span_226](end_span)

		local box = Instance.new("TextButton")[span_227](start_span)[span_227](end_span)
		box.Size = UDim2.new(1, 0, 0, 20)[span_228](start_span)[span_228](end_span)
		box.Position = UDim2.new(0, 0, 0, 16)[span_229](start_span)[span_229](end_span)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_230](start_span)[span_230](end_span)
		box.BorderSizePixel = 0[span_231](start_span)[span_231](end_span)
		box.Text = "[span_232](start_span)"[span_232](end_span)
		box.AutoButtonColor = false[span_233](start_span)[span_233](end_span)
		box.ZIndex = row.ZIndex + 1[span_234](start_span)[span_234](end_span)
		box.ClipsDescendants = false[span_235](start_span)[span_235](end_span)
		box.Parent = row[span_236](start_span)[span_236](end_span)

		local boxGrad = Instance.new("UIGradient")[span_237](start_span)[span_237](end_span)
		boxGrad.Color = ColorSequence.new({[span_238](start_span)[span_238](end_span)
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_239](start_span)[span_239](end_span)
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_240](start_span)[span_240](end_span)
		})[span_241](start_span)[span_241](end_span)
		boxGrad.Rotation = 90[span_242](start_span)[span_242](end_span)
		boxGrad.Parent = box[span_243](start_span)[span_243](end_span)
		table.insert(ThemedRegistry.ElementGradients, boxGrad)[span_244](start_span)[span_244](end_span)

		local boxStroke = Instance.new("UIStroke")[span_245](start_span)[span_245](end_span)
		boxStroke.Color = THEME.BorderElement[span_246](start_span)[span_246](end_span)
		boxStroke.Thickness = 1[span_247](start_span)[span_247](end_span)
		boxStroke.Parent = box[span_248](start_span)[span_248](end_span)
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)[span_249](start_span)[span_249](end_span)

		local selectedMap = {}[span_250](start_span)[span_250](end_span)
		for _, opt in ipairs(defaultOptions or {}) do[span_251](start_span)[span_251](end_span)
			selectedMap[opt] = true[span_252](start_span)[span_252](end_span)
		end[span_253](start_span)[span_253](end_span)

		local valLabel = Instance.new("TextLabel")[span_254](start_span)[span_254](end_span)
		valLabel.Font = FONT[span_255](start_span)[span_255](end_span)
		valLabel.TextSize = 12[span_256](start_span)[span_256](end_span)
		valLabel.TextColor3 = THEME.TextPrimary[span_257](start_span)[span_257](end_span)
		valLabel.TextXAlignment = Enum.TextXAlignment.Left[span_258](start_span)[span_258](end_span)
		valLabel.BackgroundTransparency = 1[span_259](start_span)[span_259](end_span)
		valLabel.Position = UDim2.new(0, 6, 0, 0)[span_260](start_span)[span_260](end_span)
		valLabel.Size = UDim2.new(1, -24, 1, 0)[span_261](start_span)[span_261](end_span)
		valLabel.ZIndex = box.ZIndex + 1[span_262](start_span)[span_262](end_span)
		valLabel.Parent = box[span_263](start_span)[span_263](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, valLabel)[span_264](start_span)[span_264](end_span)

		local function updateLabelText()[span_265](start_span)[span_265](end_span)
			local activeList = {}[span_266](start_span)[span_266](end_span)
			for _, opt in ipairs(allOptions) do[span_267](start_span)[span_267](end_span)
				if selectedMap[opt] then[span_268](start_span)[span_268](end_span)
					table.insert(activeList, opt)[span_269](start_span)[span_269](end_span)
				end[span_270](start_span)[span_270](end_span)
			end[span_271](start_span)[span_271](end_span)
			valLabel.Text = (#activeList == 0) and "None" or table.concat(activeList, ", ")[span_272](start_span)[span_272](end_span)
			if callback then callback(activeList) end[span_273](start_span)[span_273](end_span)
		end[span_274](start_span)[span_274](end_span)
		updateLabelText()[span_275](start_span)[span_275](end_span)

		local plus = Instance.new("TextLabel")[span_276](start_span)[span_276](end_span)
		plus.Text = "+[span_277](start_span)"[span_277](end_span)
		plus.Font = FONT[span_278](start_span)[span_278](end_span)
		plus.TextSize = 14[span_279](start_span)[span_279](end_span)
		plus.TextColor3 = THEME.TextSecondary[span_280](start_span)[span_280](end_span)
		plus.BackgroundTransparency = 1[span_281](start_span)[span_281](end_span)
		plus.Position = UDim2.new(1, -16, 0, 0)[span_282](start_span)[span_282](end_span)
		plus.Size = UDim2.new(0, 12, 1, 0)[span_283](start_span)[span_283](end_span)
		plus.ZIndex = box.ZIndex + 1[span_284](start_span)[span_284](end_span)
		plus.Parent = box[span_285](start_span)[span_285](end_span)
		table.insert(ThemedRegistry.SecondaryTexts, plus)[span_286](start_span)[span_286](end_span)

		local optionHeight = 20[span_287](start_span)[span_287](end_span)
		local fullHeight = (#allOptions * optionHeight) + 4[span_288](start_span)[span_288](end_span)

		local listFrame = Instance.new("Frame")[span_289](start_span)[span_289](end_span)
		listFrame.Name = "MultiDropList[span_290](start_span)"[span_290](end_span)
		listFrame.Size = UDim2.new(1, 0, 0, 0)[span_291](start_span)[span_291](end_span)
		listFrame.Position = UDim2.new(0, 0, 1, 2)[span_292](start_span)[span_292](end_span)
		listFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_293](start_span)[span_293](end_span)
		listFrame.BorderSizePixel = 0[span_294](start_span)[span_294](end_span)
		listFrame.ClipsDescendants = true[span_295](start_span)[span_295](end_span)
		listFrame.Visible = false[span_296](start_span)[span_296](end_span)
		listFrame.ZIndex = 320
		listFrame.Parent = box[span_297](start_span)[span_297](end_span)

		local listGrad = Instance.new("UIGradient")[span_298](start_span)[span_298](end_span)
		listGrad.Color = ColorSequence.new({[span_299](start_span)[span_299](end_span)
			ColorSequenceKeypoint.new(0, THEME.DropListTop),[span_300](start_span)[span_300](end_span)
			ColorSequenceKeypoint.new(0.45, THEME.DropListMid),[span_301](start_span)[span_301](end_span)
			ColorSequenceKeypoint.new(1, THEME.DropListBottom)[span_302](start_span)[span_302](end_span)
		})[span_303](start_span)[span_303](end_span)
		listGrad.Rotation = 90[span_304](start_span)[span_304](end_span)
		listGrad.Parent = listFrame[span_305](start_span)[span_305](end_span)
		table.insert(ThemedRegistry.DropListGradients, listGrad)[span_306](start_span)[span_306](end_span)

		local listStroke = Instance.new("UIStroke")[span_307](start_span)[span_307](end_span)
		listStroke.Color = THEME.BorderCard[span_308](start_span)[span_308](end_span)
		listStroke.Thickness = 1[span_309](start_span)[span_309](end_span)
		listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border[span_310](start_span)[span_310](end_span)
		listStroke.Parent = listFrame[span_311](start_span)[span_311](end_span)
		table.insert(ThemedRegistry.CardStrokes, listStroke)[span_312](start_span)[span_312](end_span)

		local listTopLine = Instance.new("Frame")[span_313](start_span)[span_313](end_span)
		listTopLine.Size = UDim2.new(1, 0, 0, 1)[span_314](start_span)[span_314](end_span)
		listTopLine.Position = UDim2.new(0, 0, 0, 0)[span_315](start_span)[span_315](end_span)
		listTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_316](start_span)[span_316](end_span)
		listTopLine.BorderSizePixel = 0[span_317](start_span)[span_317](end_span)
		listTopLine.ZIndex = 323
		listTopLine.Parent = listFrame[span_318](start_span)[span_318](end_span)

		local topLineGrad = Instance.new("UIGradient")[span_319](start_span)[span_319](end_span)
		topLineGrad.Color = ColorSequence.new({[span_320](start_span)[span_320](end_span)
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_321](start_span)[span_321](end_span)
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),[span_322](start_span)[span_322](end_span)
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))[span_323](start_span)[span_323](end_span)
		})[span_324](start_span)[span_324](end_span)
		topLineGrad.Parent = listTopLine[span_325](start_span)[span_325](end_span)
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)[span_326](start_span)[span_326](end_span)

		local listLayout = Instance.new("UIListLayout")[span_327](start_span)[span_327](end_span)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_328](start_span)[span_328](end_span)
		listLayout.Padding = UDim.new(0, 1)[span_329](start_span)[span_329](end_span)
		listLayout.Parent = listFrame[span_330](start_span)[span_330](end_span)

		local listPadding = Instance.new("UIPadding")[span_331](start_span)[span_331](end_span)
		listPadding.PaddingTop = UDim.new(0, 2)[span_332](start_span)[span_332](end_span)
		listPadding.PaddingBottom = UDim.new(0, 2)[span_333](start_span)[span_333](end_span)
		listPadding.Parent = listFrame[span_334](start_span)[span_334](end_span)

		local isOpen = false[span_335](start_span)[span_335](end_span)

		local function closeDropdown()[span_336](start_span)[span_336](end_span)
			if not isOpen then return end[span_337](start_span)[span_337](end_span)
			isOpen = false[span_338](start_span)[span_338](end_span)
			TweenService:Create(plus, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 0}):Play()[span_339](start_span)[span_339](end_span)
			local closeTween = TweenService:Create(listFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(1, 0, 0, 0)})[span_340](start_span)[span_340](end_span)
			closeTween:Play()[span_341](start_span)[span_341](end_span)
			closeTween.Completed:Connect(function()[span_342](start_span)[span_342](end_span)
				if not isOpen then[span_343](start_span)[span_343](end_span)
					listFrame.Visible = false[span_344](start_span)[span_344](end_span)
					row.ZIndex = zIndexVal or 10[span_345](start_span)[span_345](end_span)
					if parent and parent:IsA("GuiObject") then parent.ZIndex = 1 end
					if parentCard then parentCard.ZIndex = 1 end[span_346](start_span)[span_346](end_span)
					if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 1 end
				end[span_347](start_span)[span_347](end_span)
			end)[span_348](start_span)[span_348](end_span)
			if activeDropdownClose == closeDropdown then activeDropdownClose = nil end[span_349](start_span)[span_349](end_span)
		end[span_350](start_span)[span_350](end_span)

		local function openDropdown()[span_351](start_span)[span_351](end_span)
			if activeDropdownClose and activeDropdownClose ~= closeDropdown then activeDropdownClose() end[span_352](start_span)[span_352](end_span)
			isOpen = true[span_353](start_span)[span_353](end_span)
			activeDropdownClose = closeDropdown[span_354](start_span)[span_354](end_span)

			local openUp = false
			if parentCol and parentCol:IsA("GuiObject") then
				local limitY = math.min(parentCol.AbsolutePosition.Y + parentCol.AbsoluteSize.Y, MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y)
				local spaceBelow = limitY - (box.AbsolutePosition.Y + box.AbsoluteSize.Y)
				if spaceBelow < (fullHeight + 10) then
					openUp = true
				end
			end

			if openUp then
				listFrame.AnchorPoint = Vector2.new(0, 1)
				listFrame.Position = UDim2.new(0, 0, 0, -2)
				listTopLine.Position = UDim2.new(0, 0, 1, -1)
			else
				listFrame.AnchorPoint = Vector2.new(0, 0)
				listFrame.Position = UDim2.new(0, 0, 1, 2)
				listTopLine.Position = UDim2.new(0, 0, 0, 0)
			end

			row.ZIndex = 300
			if parent and parent:IsA("GuiObject") then parent.ZIndex = 50 end
			if parentCard then parentCard.ZIndex = 300 end
			if parentCol and parentCol:IsA("GuiObject") then parentCol.ZIndex = 50 end

			listFrame.Visible = true[span_355](start_span)[span_355](end_span)
			TweenService:Create(plus, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = 45}):Play()[span_356](start_span)[span_356](end_span)
			TweenService:Create(listFrame, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, fullHeight)}):Play()[span_357](start_span)[span_357](end_span)
		end[span_358](start_span)[span_358](end_span)

		box.MouseButton1Click:Connect(function()[span_359](start_span)[span_359](end_span)
			if isOpen then closeDropdown() else openDropdown() end[span_360](start_span)[span_360](end_span)
		end)[span_361](start_span)[span_361](end_span)

		for idx, optText in ipairs(allOptions) do[span_362](start_span)[span_362](end_span)
			local optBtn = Instance.new("TextButton")[span_363](start_span)[span_363](end_span)
			optBtn.Size = UDim2.new(1, 0, 0, optionHeight)[span_364](start_span)[span_364](end_span)
			optBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_365](start_span)[span_365](end_span)
			optBtn.BackgroundTransparency = 1[span_366](start_span)[span_366](end_span)
			optBtn.BorderSizePixel = 0[span_367](start_span)[span_367](end_span)
			optBtn.Text = "[span_368](start_span)"[span_368](end_span)
			optBtn.AutoButtonColor = false[span_369](start_span)[span_369](end_span)
			optBtn.LayoutOrder = idx[span_370](start_span)[span_370](end_span)
			optBtn.ZIndex = 321
			optBtn.Parent = listFrame[span_371](start_span)[span_371](end_span)

			local optLabel = Instance.new("TextLabel")[span_372](start_span)[span_372](end_span)
			optLabel.Text = optText[span_373](start_span)[span_373](end_span)
			optLabel.Font = FONT[span_374](start_span)[span_374](end_span)
			optLabel.TextSize = 12[span_375](start_span)[span_375](end_span)
			optLabel.TextColor3 = selectedMap[optText] and THEME.TextSelectedWhite or THEME.TextMuted[span_376](start_span)[span_376](end_span)
			optLabel.TextXAlignment = Enum.TextXAlignment.Left[span_377](start_span)[span_377](end_span)
			optLabel.BackgroundTransparency = 1[span_378](start_span)[span_378](end_span)
			optLabel.Position = UDim2.new(0, 8, 0, 0)[span_379](start_span)[span_379](end_span)
			optLabel.Size = UDim2.new(1, -16, 1, 0)[span_380](start_span)[span_380](end_span)
			optLabel.ZIndex = 322
			optLabel.Parent = optBtn[span_381](start_span)[span_381](end_span)

			table.insert(ThemedRegistry.DropdownLabels, {[span_382](start_span)[span_382](end_span)
				Label = optLabel,[span_383](start_span)[span_383](end_span)
				IsActive = function() return selectedMap[optText] == true end[span_384](start_span)[span_384](end_span)
			})[span_385](start_span)[span_385](end_span)

			optBtn.MouseEnter:Connect(function()[span_386](start_span)[span_386](end_span)
				TweenService:Create(optBtn, TweenInfo.new(0.10), {BackgroundTransparency = 0.94}):Play()[span_387](start_span)[span_387](end_span)
			end)[span_388](start_span)[span_388](end_span)
			optBtn.MouseLeave:Connect(function()[span_389](start_span)[span_389](end_span)
				TweenService:Create(optBtn, TweenInfo.new(0.10), {BackgroundTransparency = 1}):Play()[span_390](start_span)[span_390](end_span)
			end)[span_391](start_span)[span_391](end_span)

			optBtn.MouseButton1Click:Connect(function()[span_392](start_span)[span_392](end_span)
				selectedMap[optText] = not selectedMap[optText][span_393](start_span)[span_393](end_span)
				optLabel.TextColor3 = selectedMap[optText] and THEME.TextSelectedWhite or THEME.TextMuted[span_394](start_span)[span_394](end_span)
				updateLabelText()[span_395](start_span)[span_395](end_span)
			end)[span_396](start_span)[span_396](end_span)
		end[span_397](start_span)[span_397](end_span)

		ConfigFeatureEntries[flag] = {[span_398](start_span)[span_398](end_span)
			Get = function()[span_399](start_span)[span_399](end_span)
				local res = {}[span_400](start_span)[span_400](end_span)
				for _, opt in ipairs(allOptions) do[span_401](start_span)[span_401](end_span)
					if selectedMap[opt] then table.insert(res, opt) end[span_402](start_span)[span_402](end_span)
				end[span_403](start_span)[span_403](end_span)
				return res[span_404](start_span)[span_404](end_span)
			end,[span_405](start_span)[span_405](end_span)
			Set = function(newVals)[span_406](start_span)[span_406](end_span)
				if type(newVals) == "table" then[span_407](start_span)[span_407](end_span)
					selectedMap = {}[span_408](start_span)[span_408](end_span)
					for _, v in ipairs(newVals) do selectedMap[v] = true end[span_409](start_span)[span_409](end_span)
					for _, child in ipairs(listFrame:GetChildren()) do[span_410](start_span)[span_410](end_span)
						if child:IsA("TextButton") and child:FindFirstChildOfClass("TextLabel") then[span_411](start_span)[span_411](end_span)
							local lbl = child:FindFirstChildOfClass("TextLabel")[span_412](start_span)[span_412](end_span)
							lbl.TextColor3 = selectedMap[lbl.Text] and THEME.TextSelectedWhite or THEME.TextMuted[span_413](start_span)[span_413](end_span)
						end[span_414](start_span)[span_414](end_span)
					end[span_415](start_span)[span_415](end_span)
					updateLabelText()[span_416](start_span)[span_416](end_span)
				end[span_417](start_span)[span_417](end_span)
			end[span_418](start_span)[span_418](end_span)
		}[span_419](start_span)[span_419](end_span)

		return {[span_420](start_span)[span_420](end_span)
			Set = function(val) ConfigFeatureEntries[flag].Set(val) end,[span_421](start_span)[span_421](end_span)
			Get = function() return ConfigFeatureEntries[flag].Get() end[span_422](start_span)[span_422](end_span)
		}[span_423](start_span)[span_423](end_span)
	end[span_424](start_span)[span_424](end_span)

	local function createInput(parent, title, placeholder, defaultVal, callback, flag)[span_425](start_span)[span_425](end_span)
		flag = flag or title[span_426](start_span)[span_426](end_span)
		local row = Instance.new("Frame")[span_427](start_span)[span_427](end_span)
		row.Size = UDim2.new(1, 0, 0, 38)[span_428](start_span)[span_428](end_span)
		row.BackgroundTransparency = 1[span_429](start_span)[span_429](end_span)
		row.ClipsDescendants = false[span_430](start_span)[span_430](end_span)
		row.Parent = parent[span_431](start_span)[span_431](end_span)

		local titleLabel = Instance.new("TextLabel")[span_432](start_span)[span_432](end_span)
		titleLabel.Text = title[span_433](start_span)[span_433](end_span)
		titleLabel.Font = FONT[span_434](start_span)[span_434](end_span)
		titleLabel.TextSize = 12[span_435](start_span)[span_435](end_span)
		titleLabel.TextColor3 = THEME.TextSecondary[span_436](start_span)[span_436](end_span)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left[span_437](start_span)[span_437](end_span)
		titleLabel.BackgroundTransparency = 1[span_438](start_span)[span_438](end_span)
		titleLabel.Size = UDim2.new(1, 0, 0, 13)[span_439](start_span)[span_439](end_span)
		titleLabel.ZIndex = 2[span_440](start_span)[span_440](end_span)
		titleLabel.Parent = row[span_441](start_span)[span_441](end_span)
		table.insert(ThemedRegistry.SecondaryTexts, titleLabel)[span_442](start_span)[span_442](end_span)

		local box = Instance.new("Frame")[span_443](start_span)[span_443](end_span)
		box.Size = UDim2.new(1, 0, 0, 20)[span_444](start_span)[span_444](end_span)
		box.Position = UDim2.new(0, 0, 0, 16)[span_445](start_span)[span_445](end_span)
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_446](start_span)[span_446](end_span)
		box.BorderSizePixel = 0[span_447](start_span)[span_447](end_span)
		box.ClipsDescendants = true[span_448](start_span)[span_448](end_span)
		box.Parent = row[span_449](start_span)[span_449](end_span)

		local boxGrad = Instance.new("UIGradient")[span_450](start_span)[span_450](end_span)
		boxGrad.Color = ColorSequence.new({[span_451](start_span)[span_451](end_span)
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_452](start_span)[span_452](end_span)
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_453](start_span)[span_453](end_span)
		})[span_454](start_span)[span_454](end_span)
		boxGrad.Rotation = 90[span_455](start_span)[span_455](end_span)
		boxGrad.Parent = box[span_456](start_span)[span_456](end_span)
		table.insert(ThemedRegistry.ElementGradients, boxGrad)[span_457](start_span)[span_457](end_span)

		local boxStroke = Instance.new("UIStroke")[span_458](start_span)[span_458](end_span)
		boxStroke.Color = THEME.BorderElement[span_459](start_span)[span_459](end_span)
		boxStroke.Thickness = 1[span_460](start_span)[span_460](end_span)
		boxStroke.Parent = box[span_461](start_span)[span_461](end_span)
		table.insert(ThemedRegistry.ElementStrokes, boxStroke)[span_462](start_span)[span_462](end_span)

		local topLine = Instance.new("Frame")[span_463](start_span)[span_463](end_span)
		topLine.Name = "TopLine[span_464](start_span)"[span_464](end_span)
		topLine.Size = UDim2.new(1, 0, 0, 1)[span_465](start_span)[span_465](end_span)
		topLine.Position = UDim2.new(0, 0, 0, 0)[span_466](start_span)[span_466](end_span)
		topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_467](start_span)[span_467](end_span)
		topLine.BorderSizePixel = 0[span_468](start_span)[span_468](end_span)
		topLine.ZIndex = 4[span_469](start_span)[span_469](end_span)
		topLine.Parent = box[span_470](start_span)[span_470](end_span)

		local topLineGrad = Instance.new("UIGradient")[span_471](start_span)[span_471](end_span)
		topLineGrad.Color = ColorSequence.new({[span_472](start_span)[span_472](end_span)
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_473](start_span)[span_473](end_span)
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacDeep),[span_474](start_span)[span_474](end_span)
			ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 32, 52))[span_475](start_span)[span_475](end_span)
		})[span_476](start_span)[span_476](end_span)
		topLineGrad.Parent = topLine[span_477](start_span)[span_477](end_span)
		table.insert(ThemedRegistry.AccentLineGradients, topLineGrad)[span_478](start_span)[span_478](end_span)

		local input = Instance.new("TextBox")[span_479](start_span)[span_479](end_span)
		input.Size = UDim2.new(1, -12, 1, 0)[span_480](start_span)[span_480](end_span)
		input.Position = UDim2.new(0, 6, 0, 0)[span_481](start_span)[span_481](end_span)
		input.BackgroundTransparency = 1[span_482](start_span)[span_482](end_span)
		input.Text = defaultVal or "[span_483](start_span)"[span_483](end_span)
		input.PlaceholderText = placeholder or "Enter text...[span_484](start_span)"[span_484](end_span)
		input.PlaceholderColor3 = THEME.TextMuted[span_485](start_span)[span_485](end_span)
		input.TextColor3 = THEME.TextPrimary[span_486](start_span)[span_486](end_span)
		input.Font = FONT[span_487](start_span)[span_487](end_span)
		input.TextSize = 12[span_488](start_span)[span_488](end_span)
		input.TextXAlignment = Enum.TextXAlignment.Left[span_489](start_span)[span_489](end_span)
		input.ClearTextOnFocus = false[span_490](start_span)[span_490](end_span)
		input.ZIndex = 3[span_491](start_span)[span_491](end_span)
		input.Parent = box[span_492](start_span)[span_492](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, input)[span_493](start_span)[span_493](end_span)
		table.insert(ThemedRegistry.MutedTexts, input)[span_494](start_span)[span_494](end_span)

		input.Focused:Connect(function()[span_495](start_span)[span_495](end_span)
			TweenService:Create(boxStroke, TweenInfo.new(0.12), {Color = THEME.AccentLilacMid}):Play()[span_496](start_span)[span_496](end_span)
		end)[span_497](start_span)[span_497](end_span)

		input.FocusLost:Connect(function(enterPressed)[span_498](start_span)[span_498](end_span)
			TweenService:Create(boxStroke, TweenInfo.new(0.12), {Color = THEME.BorderElement}):Play()[span_499](start_span)[span_499](end_span)
			if callback then callback(input.Text, enterPressed) end[span_500](start_span)[span_500](end_span)
		end)[span_501](start_span)[span_501](end_span)

		ConfigFeatureEntries[flag] = {[span_502](start_span)[span_502](end_span)
			Get = function() return input.Text end,[span_503](start_span)[span_503](end_span)
			Set = function(newVal)[span_504](start_span)[span_504](end_span)
				if type(newVal) == "string" then[span_505](start_span)[span_505](end_span)
					input.Text = newVal[span_506](start_span)[span_506](end_span)
					if callback then callback(input.Text, false) end[span_507](start_span)[span_507](end_span)
				end[span_508](start_span)[span_508](end_span)
			end[span_509](start_span)[span_509](end_span)
		}[span_510](start_span)[span_510](end_span)

		return row, input[span_511](start_span)[span_511](end_span)
	end[span_512](start_span)[span_512](end_span)

	local function createActionButton(parent, text, callback)[span_513](start_span)[span_513](end_span)
		local btn = Instance.new("TextButton")[span_514](start_span)[span_514](end_span)
		btn.Size = UDim2.new(1, 0, 0, 22)[span_515](start_span)[span_515](end_span)
		btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_516](start_span)[span_516](end_span)
		btn.BorderSizePixel = 0[span_517](start_span)[span_517](end_span)
		btn.Text = "[span_518](start_span)"[span_518](end_span)
		btn.AutoButtonColor = false[span_519](start_span)[span_519](end_span)
		btn.ClipsDescendants = true[span_520](start_span)[span_520](end_span)
		btn.Parent = parent[span_521](start_span)[span_521](end_span)

		local btnGrad = Instance.new("UIGradient")[span_522](start_span)[span_522](end_span)
		btnGrad.Color = ColorSequence.new({[span_523](start_span)[span_523](end_span)
			ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_524](start_span)[span_524](end_span)
			ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_525](start_span)[span_525](end_span)
		})[span_526](start_span)[span_526](end_span)
		btnGrad.Rotation = 90[span_527](start_span)[span_527](end_span)
		btnGrad.Parent = btn[span_528](start_span)[span_528](end_span)
		table.insert(ThemedRegistry.ElementGradients, btnGrad)[span_529](start_span)[span_529](end_span)

		local btnStroke = Instance.new("UIStroke")[span_530](start_span)[span_530](end_span)
		btnStroke.Color = THEME.BorderElement[span_531](start_span)[span_531](end_span)
		btnStroke.Thickness = 1[span_532](start_span)[span_532](end_span)
		btnStroke.Parent = btn[span_533](start_span)[span_533](end_span)
		table.insert(ThemedRegistry.ElementStrokes, btnStroke)[span_534](start_span)[span_534](end_span)

		local btnLabel = Instance.new("TextLabel")[span_535](start_span)[span_535](end_span)
		btnLabel.Text = text[span_536](start_span)[span_536](end_span)
		btnLabel.Font = FONT[span_537](start_span)[span_537](end_span)
		btnLabel.TextSize = 12[span_538](start_span)[span_538](end_span)
		btnLabel.TextColor3 = THEME.TextPrimary[span_539](start_span)[span_539](end_span)
		btnLabel.TextXAlignment = Enum.TextXAlignment.Center[span_540](start_span)[span_540](end_span)
		btnLabel.BackgroundTransparency = 1[span_541](start_span)[span_541](end_span)
		btnLabel.Size = UDim2.new(1, 0, 1, 0)[span_542](start_span)[span_542](end_span)
		btnLabel.ZIndex = 2[span_543](start_span)[span_543](end_span)
		btnLabel.Parent = btn[span_544](start_span)[span_544](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, btnLabel)[span_545](start_span)[span_545](end_span)

		btn.MouseButton1Down:Connect(function()[span_546](start_span)[span_546](end_span)
			TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[span_547](start_span)[span_547](end_span)
				BackgroundColor3 = Color3.fromRGB(185, 175, 200)[span_548](start_span)[span_548](end_span)
			}):Play()[span_549](start_span)[span_549](end_span)
			TweenService:Create(btnStroke, TweenInfo.new(0.08), {Color = THEME.AccentLilacLight}):Play()[span_550](start_span)[span_550](end_span)
			TweenService:Create(btnLabel, TweenInfo.new(0.08), {TextColor3 = THEME.AccentLilacLight}):Play()[span_551](start_span)[span_551](end_span)
		end)[span_552](start_span)[span_552](end_span)

		local function releaseBtn()[span_553](start_span)[span_553](end_span)
			TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {[span_554](start_span)[span_554](end_span)
				BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_555](start_span)[span_555](end_span)
			}):Play()[span_556](start_span)[span_556](end_span)
			TweenService:Create(btnStroke, TweenInfo.new(0.16), {Color = THEME.BorderElement}):Play()[span_557](start_span)[span_557](end_span)
			TweenService:Create(btnLabel, TweenInfo.new(0.16), {TextColor3 = THEME.TextPrimary}):Play()[span_558](start_span)[span_558](end_span)
		end[span_559](start_span)[span_559](end_span)

		btn.MouseButton1Up:Connect(releaseBtn)[span_560](start_span)[span_560](end_span)
		btn.MouseLeave:Connect(releaseBtn)[span_561](start_span)[span_561](end_span)

		btn.MouseButton1Click:Connect(function()[span_562](start_span)[span_562](end_span)
			if activeDropdownClose then activeDropdownClose() end[span_563](start_span)[span_563](end_span)
			if callback then callback() end[span_564](start_span)[span_564](end_span)
		end)[span_565](start_span)[span_565](end_span)

		return btn[span_566](start_span)[span_566](end_span)
	end[span_567](start_span)[span_567](end_span)

	local function createDualActionButtons(parent, text1, cb1, text2, cb2)[span_568](start_span)[span_568](end_span)
		local row = Instance.new("Frame")[span_569](start_span)[span_569](end_span)
		row.Size = UDim2.new(1, 0, 0, 22)[span_570](start_span)[span_570](end_span)
		row.BackgroundTransparency = 1[span_571](start_span)[span_571](end_span)
		row.Parent = parent[span_572](start_span)[span_572](end_span)

		local btn1 = createActionButton(row, text1, cb1)[span_573](start_span)[span_573](end_span)
		btn1.Size = UDim2.new(0.5, -2, 1, 0)[span_574](start_span)[span_574](end_span)
		btn1.Position = UDim2.new(0, 0, 0, 0)[span_575](start_span)[span_575](end_span)

		local btn2 = createActionButton(row, text2, cb2)[span_576](start_span)[span_576](end_span)
		btn2.Size = UDim2.new(0.5, -2, 1, 0)[span_577](start_span)[span_577](end_span)
		btn2.Position = UDim2.new(0.5, 2, 0, 0)[span_578](start_span)[span_578](end_span)

		return row[span_579](start_span)[span_579](end_span)
	end[span_580](start_span)[span_580](end_span)

	local function createColorPickerRow(parent, text, defaultColor, onColorChanged, flag)[span_581](start_span)[span_581](end_span)
		flag = flag or text[span_582](start_span)[span_582](end_span)
		local row = Instance.new("Frame")[span_583](start_span)[span_583](end_span)
		row.Size = UDim2.new(1, 0, 0, 20)[span_584](start_span)[span_584](end_span)
		row.BackgroundTransparency = 1[span_585](start_span)[span_585](end_span)
		row.ClipsDescendants = false[span_586](start_span)[span_586](end_span)
		row.ZIndex = 1
		row.Parent = parent[span_587](start_span)[span_587](end_span)

		local label = Instance.new("TextLabel")[span_588](start_span)[span_588](end_span)
		label.Text = text[span_589](start_span)[span_589](end_span)
		label.Font = FONT[span_590](start_span)[span_590](end_span)
		label.TextSize = 13[span_591](start_span)[span_591](end_span)
		label.TextXAlignment = Enum.TextXAlignment.Left[span_592](start_span)[span_592](end_span)
		label.BackgroundTransparency = 1[span_593](start_span)[span_593](end_span)
		label.Position = UDim2.new(0, 0, 0, 0)[span_594](start_span)[span_594](end_span)
		label.Size = UDim2.new(1, -38, 1, 0)[span_595](start_span)[span_595](end_span)
		label.TextColor3 = THEME.TextPrimary[span_596](start_span)[span_596](end_span)
		label.ZIndex = 3[span_597](start_span)[span_597](end_span)
		label.Parent = row[span_598](start_span)[span_598](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, label)[span_599](start_span)[span_599](end_span)

		local cp = createSingleColorPicker(row, -30, defaultColor, onColorChanged)[span_600](start_span)[span_600](end_span)

		ConfigFeatureEntries[flag] = {[span_601](start_span)[span_601](end_span)
			Get = function()[span_602](start_span)[span_602](end_span)
				local col = cp.GetColor()[span_603](start_span)[span_603](end_span)
				return { R = col.R, G = col.G, B = col.B }[span_604](start_span)[span_604](end_span)
			end,[span_605](start_span)[span_605](end_span)
			Set = function(val)[span_606](start_span)[span_606](end_span)
				if type(val) == "table" and val.R then[span_607](start_span)[span_607](end_span)
					cp.SetColor(Color3.new(val.R, val.G, val.B))[span_608](start_span)[span_608](end_span)
				end[span_609](start_span)[span_609](end_span)
			end[span_610](start_span)[span_610](end_span)
		}[span_611](start_span)[span_611](end_span)

		return row[span_612](start_span)[span_612](end_span)
	end[span_613](start_span)[span_613](end_span)

	local function createPlayerList(parent, title, sizeY, elementConfigs, filterOptions)[span_614](start_span)[span_614](end_span)
		filterOptions = filterOptions or {}[span_615](start_span)[span_615](end_span)
		local mode = filterOptions.TeamFilter or "All[span_616](start_span)"[span_616](end_span)
		local customFilter = filterOptions.Filter[span_617](start_span)[span_617](end_span)

		local function isPlayerVisible(plr)[span_618](start_span)[span_618](end_span)
			if plr == LocalPlayer then return false end[span_619](start_span)[span_619](end_span)
			if typeof(customFilter) == "function" then[span_620](start_span)[span_620](end_span)
				return customFilter(plr)[span_621](start_span)[span_621](end_span)
			end[span_622](start_span)[span_622](end_span)
			if mode == "Enemies" then[span_623](start_span)[span_623](end_span)
				if LocalPlayer.Team and plr.Team then[span_624](start_span)[span_624](end_span)
					return LocalPlayer.Team ~= plr.Team[span_625](start_span)[span_625](end_span)
				elseif LocalPlayer.TeamColor and plr.TeamColor then[span_626](start_span)[span_626](end_span)
					return LocalPlayer.TeamColor ~= plr.TeamColor[span_627](start_span)[span_627](end_span)
				end[span_628](start_span)[span_628](end_span)
				return true[span_629](start_span)[span_629](end_span)
			elseif mode == "Allies" then[span_630](start_span)[span_630](end_span)
				if LocalPlayer.Team and plr.Team then[span_631](start_span)[span_631](end_span)
					return LocalPlayer.Team == plr.Team[span_632](start_span)[span_632](end_span)
				elseif LocalPlayer.TeamColor and plr.TeamColor then[span_633](start_span)[span_633](end_span)
					return LocalPlayer.TeamColor == plr.TeamColor[span_634](start_span)[span_634](end_span)
				end[span_635](start_span)[span_635](end_span)
				return false[span_636](start_span)[span_636](end_span)
			end[span_637](start_span)[span_637](end_span)
			return true[span_638](start_span)[span_638](end_span)
		end[span_639](start_span)[span_639](end_span)

		local card = Instance.new("Frame")[span_640](start_span)[span_640](end_span)
		card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_641](start_span)[span_641](end_span)
		card.BorderSizePixel = 0[span_642](start_span)[span_642](end_span)
		card.Size = UDim2.new(1, 0, 0, sizeY or 300)[span_643](start_span)[span_643](end_span)
		card.ClipsDescendants = false
		card.ZIndex = 1
		card.Parent = parent[span_644](start_span)[span_644](end_span)

		local cardGrad = Instance.new("UIGradient")[span_645](start_span)[span_645](end_span)
		cardGrad.Color = ColorSequence.new({[span_646](start_span)[span_646](end_span)
			ColorSequenceKeypoint.new(0, THEME.CardBgTop),[span_647](start_span)[span_647](end_span)
			ColorSequenceKeypoint.new(1, THEME.CardBgBottom)[span_648](start_span)[span_648](end_span)
		})[span_649](start_span)[span_649](end_span)
		cardGrad.Rotation = 90[span_650](start_span)[span_650](end_span)
		cardGrad.Parent = card[span_651](start_span)[span_651](end_span)
		table.insert(ThemedRegistry.CardGradients, cardGrad)[span_652](start_span)[span_652](end_span)

		local stroke = Instance.new("UIStroke")[span_653](start_span)[span_653](end_span)
		stroke.Color = THEME.BorderCard[span_654](start_span)[span_654](end_span)
		stroke.Thickness = 1[span_655](start_span)[span_655](end_span)
		stroke.Parent = card[span_656](start_span)[span_656](end_span)
		table.insert(ThemedRegistry.CardStrokes, stroke)[span_657](start_span)[span_657](end_span)

		local topLine = Instance.new("Frame")[span_658](start_span)[span_658](end_span)
		topLine.BorderSizePixel = 0[span_659](start_span)[span_659](end_span)
		topLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_660](start_span)[span_660](end_span)
		topLine.Size = UDim2.new(1, 0, 0, 1)[span_661](start_span)[span_661](end_span)
		topLine.Parent = card[span_662](start_span)[span_662](end_span)

		local lineGrad = Instance.new("UIGradient")[span_663](start_span)[span_663](end_span)
		lineGrad.Color = ColorSequence.new({[span_664](start_span)[span_664](end_span)
			ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_665](start_span)[span_665](end_span)
			ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),[span_666](start_span)[span_666](end_span)
			ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)[span_667](start_span)[span_667](end_span)
		})[span_668](start_span)[span_668](end_span)
		lineGrad.Parent = topLine[span_669](start_span)[span_669](end_span)
		table.insert(ThemedRegistry.AccentLineGradients, lineGrad)[span_670](start_span)[span_670](end_span)

		local titleLabel = Instance.new("TextLabel")[span_671](start_span)[span_671](end_span)
		titleLabel.Text = title or "Player List[span_672](start_span)"[span_672](end_span)
		titleLabel.Font = FONT[span_673](start_span)[span_673](end_span)
		titleLabel.TextSize = 13[span_674](start_span)[span_674](end_span)
		titleLabel.TextColor3 = THEME.TextPrimary[span_675](start_span)[span_675](end_span)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left[span_676](start_span)[span_676](end_span)
		titleLabel.BackgroundTransparency = 1[span_677](start_span)[span_677](end_span)
		titleLabel.Position = UDim2.new(0, 8, 0, 3)[span_678](start_span)[span_678](end_span)
		titleLabel.Size = UDim2.new(1, -16, 0, 16)[span_679](start_span)[span_679](end_span)
		titleLabel.ZIndex = 3[span_680](start_span)[span_680](end_span)
		titleLabel.Parent = card[span_681](start_span)[span_681](end_span)
		table.insert(ThemedRegistry.PrimaryTexts, titleLabel)[span_682](start_span)[span_682](end_span)

		local playerScroll = Instance.new("ScrollingFrame")[span_683](start_span)[span_683](end_span)
		playerScroll.Size = UDim2.new(1, -12, 1, -26)[span_684](start_span)[span_684](end_span)
		playerScroll.Position = UDim2.new(0, 6, 0, 22)[span_685](start_span)[span_685](end_span)
		playerScroll.BackgroundTransparency = 1[span_686](start_span)[span_686](end_span)
		playerScroll.BorderSizePixel = 0[span_687](start_span)[span_687](end_span)
		playerScroll.ScrollBarThickness = 3[span_688](start_span)[span_688](end_span)
		playerScroll.ScrollBarImageColor3 = THEME.AccentLilacLight[span_689](start_span)[span_689](end_span)
		playerScroll.ScrollBarImageTransparency = 0.2[span_690](start_span)[span_690](end_span)
		playerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y[span_691](start_span)[span_691](end_span)
		playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)[span_692](start_span)[span_692](end_span)
		playerScroll.ScrollingDirection = Enum.ScrollingDirection.Y[span_693](start_span)[span_693](end_span)
		playerScroll.ClipsDescendants = true[span_694](start_span)[span_694](end_span)
		playerScroll.ZIndex = 1
		playerScroll.Parent = card[span_695](start_span)[span_695](end_span)
		table.insert(ThemedRegistry.Scrollbars, playerScroll)[span_696](start_span)[span_696](end_span)

		local pListLayout = Instance.new("UIListLayout")[span_697](start_span)[span_697](end_span)
		pListLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_698](start_span)[span_698](end_span)
		pListLayout.Padding = UDim.new(0, 3)[span_699](start_span)[span_699](end_span)
		pListLayout.Parent = playerScroll[span_700](start_span)[span_700](end_span)

		local configs = elementConfigs or {[span_701](start_span)[span_701](end_span)
			{ type = "toggle", name = "Aim", default = false },[span_702](start_span)[span_702](end_span)
			{ type = "toggle", name = "ESP", default = false },[span_703](start_span)[span_703](end_span)
			{ type = "dropdown", name = "Prio", default = "Med", options = {"Low", "Med", "High"} }[span_704](start_span)[span_704](end_span)
		}[span_705](start_span)[span_705](end_span)

		local playerRows = {}[span_706](start_span)[span_706](end_span)

		local function updatePlayerVisibility(plr)[span_707](start_span)[span_707](end_span)
			local row = playerRows[plr][span_708](start_span)[span_708](end_span)
			if row then[span_709](start_span)[span_709](end_span)
				row.Visible = isPlayerVisible(plr)[span_710](start_span)[span_710](end_span)
			end[span_711](start_span)[span_711](end_span)
		end[span_712](start_span)[span_712](end_span)

		local function buildPlayerRow(plr)[span_713](start_span)[span_713](end_span)
			if not plr or playerRows[plr] or plr == LocalPlayer then return end[span_714](start_span)[span_714](end_span)

			local row = Instance.new("Frame")[span_715](start_span)[span_715](end_span)
			row.Name = "Player_" .. plr.UserId[span_716](start_span)[span_716](end_span)
			row.Size = UDim2.new(1, -4, 0, 28)[span_717](start_span)[span_717](end_span)
			row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_718](start_span)[span_718](end_span)
			row.BorderSizePixel = 0[span_719](start_span)[span_719](end_span)
			row.ClipsDescendants = false[span_720](start_span)[span_720](end_span)
			row.ZIndex = 1
			row.Visible = isPlayerVisible(plr)[span_721](start_span)[span_721](end_span)
			row.Parent = playerScroll[span_722](start_span)[span_722](end_span)

			local rowGrad = Instance.new("UIGradient")[span_723](start_span)[span_723](end_span)
			rowGrad.Color = ColorSequence.new({[span_724](start_span)[span_724](end_span)
				ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_725](start_span)[span_725](end_span)
				ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_726](start_span)[span_726](end_span)
			})[span_727](start_span)[span_727](end_span)
			rowGrad.Rotation = 90[span_728](start_span)[span_728](end_span)
			rowGrad.Parent = row[span_729](start_span)[span_729](end_span)
			table.insert(ThemedRegistry.ElementGradients, rowGrad)[span_730](start_span)[span_730](end_span)

			local rowStroke = Instance.new("UIStroke")[span_731](start_span)[span_731](end_span)
			rowStroke.Color = THEME.BorderElement[span_732](start_span)[span_732](end_span)
			rowStroke.Thickness = 1[span_733](start_span)[span_733](end_span)
			rowStroke.Parent = row[span_734](start_span)[span_734](end_span)
			table.insert(ThemedRegistry.ElementStrokes, rowStroke)[span_735](start_span)[span_735](end_span)

			local rowTopLine = Instance.new("Frame")[span_736](start_span)[span_736](end_span)
			rowTopLine.Size = UDim2.new(1, 0, 0, 1)[span_737](start_span)[span_737](end_span)
			rowTopLine.BorderSizePixel = 0[span_738](start_span)[span_738](end_span)
			rowTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_739](start_span)[span_739](end_span)
			rowTopLine.ZIndex = 2[span_740](start_span)[span_740](end_span)
			rowTopLine.Parent = row[span_741](start_span)[span_741](end_span)

			local rLineGrad = Instance.new("UIGradient")[span_742](start_span)[span_742](end_span)
			rLineGrad.Color = ColorSequence.new({[span_743](start_span)[span_743](end_span)
				ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_744](start_span)[span_744](end_span)
				ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),[span_745](start_span)[span_745](end_span)
				ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)[span_746](start_span)[span_746](end_span)
			})[span_747](start_span)[span_747](end_span)
			rLineGrad.Parent = rowTopLine[span_748](start_span)[span_748](end_span)
			table.insert(ThemedRegistry.AccentLineGradients, rLineGrad)[span_749](start_span)[span_749](end_span)

			local avatarImg = Instance.new("ImageLabel")[span_750](start_span)[span_750](end_span)
			avatarImg.Size = UDim2.new(0, 20, 0, 20)[span_751](start_span)[span_751](end_span)
			avatarImg.Position = UDim2.new(0, 4, 0.5, -10)[span_752](start_span)[span_752](end_span)
			avatarImg.BackgroundColor3 = Color3.fromRGB(15, 10, 20)[span_753](start_span)[span_753](end_span)
			avatarImg.BorderSizePixel = 0[span_754](start_span)[span_754](end_span)
			avatarImg.ZIndex = 3[span_755](start_span)[span_755](end_span)
			avatarImg.Parent = row[span_756](start_span)[span_756](end_span)

			local avCorner = Instance.new("UICorner")[span_757](start_span)[span_757](end_span)
			avCorner.CornerRadius = UDim.new(0, 2)[span_758](start_span)[span_758](end_span)
			avCorner.Parent = avatarImg[span_759](start_span)[span_759](end_span)

			task.spawn(function()[span_760](start_span)[span_760](end_span)
				pcall(function()[span_761](start_span)[span_761](end_span)
					local content, isReady = Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)[span_762](start_span)[span_762](end_span)
					if isReady and avatarImg and avatarImg.Parent then[span_763](start_span)[span_763](end_span)
						avatarImg.Image = content[span_764](start_span)[span_764](end_span)
					end[span_765](start_span)[span_765](end_span)
				end)[span_766](start_span)[span_766](end_span)
			end)[span_767](start_span)[span_767](end_span)

			local nameLabel = Instance.new("TextLabel")[span_768](start_span)[span_768](end_span)
			nameLabel.Text = plr.DisplayName[span_769](start_span)[span_769](end_span)
			nameLabel.Font = FONT[span_770](start_span)[span_770](end_span)
			nameLabel.TextSize = 12[span_771](start_span)[span_771](end_span)
			nameLabel.TextColor3 = THEME.TextPrimary[span_772](start_span)[span_772](end_span)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left[span_773](start_span)[span_773](end_span)
			nameLabel.TextTruncate = Enum.TextTruncate.AtEnd[span_774](start_span)[span_774](end_span)
			nameLabel.BackgroundTransparency = 1[span_775](start_span)[span_775](end_span)
			nameLabel.Position = UDim2.new(0, 28, 0, 0)[span_776](start_span)[span_776](end_span)
			nameLabel.Size = UDim2.new(1, -170, 1, 0)[span_777](start_span)[span_777](end_span)
			nameLabel.ZIndex = 3[span_778](start_span)[span_778](end_span)
			nameLabel.Parent = row[span_779](start_span)[span_779](end_span)
			table.insert(ThemedRegistry.PrimaryTexts, nameLabel)[span_780](start_span)[span_780](end_span)

			local controlsHolder = Instance.new("Frame")[span_781](start_span)[span_781](end_span)
			controlsHolder.BackgroundTransparency = 1[span_782](start_span)[span_782](end_span)
			controlsHolder.AnchorPoint = Vector2.new(1, 0.5)[span_783](start_span)[span_783](end_span)
			controlsHolder.Position = UDim2.new(1, -4, 0.5, 0)[span_784](start_span)[span_784](end_span)
			controlsHolder.Size = UDim2.new(0, 140, 1, -4)[span_785](start_span)[span_785](end_span)
			controlsHolder.ZIndex = 4[span_786](start_span)[span_786](end_span)
			controlsHolder.Parent = row[span_787](start_span)[span_787](end_span)

			local cLayout = Instance.new("UIListLayout")[span_788](start_span)[span_788](end_span)
			cLayout.FillDirection = Enum.FillDirection.Horizontal[span_789](start_span)[span_789](end_span)
			cLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right[span_790](start_span)[span_790](end_span)
			cLayout.VerticalAlignment = Enum.VerticalAlignment.Center[span_791](start_span)[span_791](end_span)
			cLayout.Padding = UDim.new(0, 8)[span_792](start_span)[span_792](end_span)
			cLayout.Parent = controlsHolder[span_793](start_span)[span_793](end_span)

			for i = 1, math.min(#configs, 3) do[span_794](start_span)[span_794](end_span)
				local cfg = configs[i][span_795](start_span)[span_795](end_span)
				if cfg.type == "toggle" then[span_796](start_span)[span_796](end_span)
					local toggleBtn = Instance.new("TextButton")[span_797](start_span)[span_797](end_span)
					toggleBtn.Size = UDim2.new(0, 40, 0, 18)[span_798](start_span)[span_798](end_span)
					toggleBtn.BackgroundTransparency = 1[span_799](start_span)[span_799](end_span)
					toggleBtn.Text = "[span_800](start_span)"[span_800](end_span)
					toggleBtn.AutoButtonColor = false[span_801](start_span)[span_801](end_span)
					toggleBtn.ZIndex = 5[span_802](start_span)[span_802](end_span)
					toggleBtn.Parent = controlsHolder[span_803](start_span)[span_803](end_span)

					local tBox = Instance.new("Frame")[span_804](start_span)[span_804](end_span)
					tBox.Size = UDim2.new(0, 10, 0, 10)[span_805](start_span)[span_805](end_span)
					tBox.Position = UDim2.new(0, 0, 0.5, -5)[span_806](start_span)[span_806](end_span)
					tBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_807](start_span)[span_807](end_span)
					tBox.BorderSizePixel = 0[span_808](start_span)[span_808](end_span)
					tBox.ZIndex = 6[span_809](start_span)[span_809](end_span)
					tBox.Parent = toggleBtn[span_810](start_span)[span_810](end_span)

					local tBoxGrad = Instance.new("UIGradient")[span_811](start_span)[span_811](end_span)
					tBoxGrad.Rotation = 90[span_812](start_span)[span_812](end_span)
					tBoxGrad.Parent = tBox[span_813](start_span)[span_813](end_span)

					local tBoxStroke = Instance.new("UIStroke")[span_814](start_span)[span_814](end_span)
					tBoxStroke.Color = THEME.BorderElement[span_815](start_span)[span_815](end_span)
					tBoxStroke.Thickness = 1[span_816](start_span)[span_816](end_span)
					tBoxStroke.Parent = tBox[span_817](start_span)[span_817](end_span)
					table.insert(ThemedRegistry.ElementStrokes, tBoxStroke)[span_818](start_span)[span_818](end_span)

					local tLbl = Instance.new("TextLabel")[span_819](start_span)[span_819](end_span)
					tLbl.Text = cfg.name or "On[span_820](start_span)"[span_820](end_span)
					tLbl.Font = FONT[span_821](start_span)[span_821](end_span)
					tLbl.TextSize = 10[span_822](start_span)[span_822](end_span)
					tLbl.TextColor3 = THEME.TextSecondary[span_823](start_span)[span_823](end_span)
					tLbl.TextXAlignment = Enum.TextXAlignment.Left[span_824](start_span)[span_824](end_span)
					tLbl.BackgroundTransparency = 1[span_825](start_span)[span_825](end_span)
					tLbl.Position = UDim2.new(0, 15, 0, 0)[span_826](start_span)[span_826](end_span)
					tLbl.Size = UDim2.new(1, -15, 1, 0)[span_827](start_span)[span_827](end_span)
					tLbl.ZIndex = 6[span_828](start_span)[span_828](end_span)
					tLbl.Parent = toggleBtn[span_829](start_span)[span_829](end_span)

					local state = cfg.default == true[span_830](start_span)[span_830](end_span)
					local function updateBoxVisual()[span_831](start_span)[span_831](end_span)
						if state then[span_832](start_span)[span_832](end_span)
							tBoxGrad.Color = ColorSequence.new({[span_833](start_span)[span_833](end_span)
								ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_834](start_span)[span_834](end_span)
								ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)[span_835](start_span)[span_835](end_span)
							})[span_836](start_span)[span_836](end_span)
							tLbl.TextColor3 = THEME.TextPrimary[span_837](start_span)[span_837](end_span)
						else[span_838](start_span)[span_838](end_span)
							tBoxGrad.Color = ColorSequence.new({[span_839](start_span)[span_839](end_span)
								ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_840](start_span)[span_840](end_span)
								ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_841](start_span)[span_841](end_span)
							})[span_842](start_span)[span_842](end_span)
							tLbl.TextColor3 = THEME.TextSecondary[span_843](start_span)[span_843](end_span)
						end[span_844](start_span)[span_844](end_span)
					end[span_845](start_span)[span_845](end_span)
					updateBoxVisual()[span_846](start_span)[span_846](end_span)
					table.insert(ThemedRegistry.ToggleCheckboxes, updateBoxVisual)[span_847](start_span)[span_847](end_span)

					toggleBtn.MouseButton1Click:Connect(function()[span_848](start_span)[span_848](end_span)
						if activeDropdownClose then activeDropdownClose() end[span_849](start_span)[span_849](end_span)
						state = not state[span_850](start_span)[span_850](end_span)
						updateBoxVisual()[span_851](start_span)[span_851](end_span)
						if cfg.callback then cfg.callback(plr, state) end[span_852](start_span)[span_852](end_span)
					end)[span_853](start_span)[span_853](end_span)

				elseif cfg.type == "dropdown" then[span_854](start_span)[span_854](end_span)
					local dBox = Instance.new("TextButton")[span_855](start_span)[span_855](end_span)
					dBox.Size = UDim2.new(0, 42, 0, 18)[span_856](start_span)[span_856](end_span)
					dBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_857](start_span)[span_857](end_span)
					dBox.BorderSizePixel = 0[span_858](start_span)[span_858](end_span)
					dBox.Text = "[span_859](start_span)"[span_859](end_span)
					dBox.AutoButtonColor = false[span_860](start_span)[span_860](end_span)
					dBox.ZIndex = 5[span_861](start_span)[span_861](end_span)
					dBox.Parent = controlsHolder[span_862](start_span)[span_862](end_span)

					local dBoxGrad = Instance.new("UIGradient")[span_863](start_span)[span_863](end_span)
					dBoxGrad.Color = ColorSequence.new({[span_864](start_span)[span_864](end_span)
						ColorSequenceKeypoint.new(0, THEME.ElementBgTop),[span_865](start_span)[span_865](end_span)
						ColorSequenceKeypoint.new(1, THEME.ElementBgBottom)[span_866](start_span)[span_866](end_span)
					})[span_867](start_span)[span_867](end_span)
					dBoxGrad.Rotation = 90[span_868](start_span)[span_868](end_span)
					dBoxGrad.Parent = dBox[span_869](start_span)[span_869](end_span)
					table.insert(ThemedRegistry.ElementGradients, dBoxGrad)[span_870](start_span)[span_870](end_span)

					local dBoxStroke = Instance.new("UIStroke")[span_871](start_span)[span_871](end_span)
					dBoxStroke.Color = THEME.BorderElement[span_872](start_span)[span_872](end_span)
					dBoxStroke.Thickness = 1[span_873](start_span)[span_873](end_span)
					dBoxStroke.Parent = dBox[span_874](start_span)[span_874](end_span)
					table.insert(ThemedRegistry.ElementStrokes, dBoxStroke)[span_875](start_span)[span_875](end_span)

					local curOpt = cfg.default or (cfg.options and cfg.options[1]) or "None[span_876](start_span)"[span_876](end_span)
					local dVal = Instance.new("TextLabel")[span_877](start_span)[span_877](end_span)
					dVal.Text = curOpt[span_878](start_span)[span_878](end_span)
					dVal.Font = FONT[span_879](start_span)[span_879](end_span)
					dVal.TextSize = 10[span_880](start_span)[span_880](end_span)
					dVal.TextColor3 = THEME.TextPrimary[span_881](start_span)[span_881](end_span)
					dVal.TextXAlignment = Enum.TextXAlignment.Center[span_882](start_span)[span_882](end_span)
					dVal.BackgroundTransparency = 1[span_883](start_span)[span_883](end_span)
					dVal.Size = UDim2.new(1, 0, 1, 0)[span_884](start_span)[span_884](end_span)
					dVal.ZIndex = 6[span_885](start_span)[span_885](end_span)
					dVal.Parent = dBox[span_886](start_span)[span_886](end_span)
					table.insert(ThemedRegistry.PrimaryTexts, dVal)[span_887](start_span)[span_887](end_span)

					local opts = cfg.options or {"A", "B"}[span_888](start_span)[span_888](end_span)
					local dList = Instance.new("Frame")[span_889](start_span)[span_889](end_span)
					dList.Size = UDim2.new(1, 0, 0, #opts * 16 + 4)[span_890](start_span)[span_890](end_span)
					dList.Position = UDim2.new(0, 0, 1, 2)[span_891](start_span)[span_891](end_span)
					dList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_892](start_span)[span_892](end_span)
					dList.BorderSizePixel = 0[span_893](start_span)[span_893](end_span)
					dList.Visible = false[span_894](start_span)[span_894](end_span)
					dList.ZIndex = 320
					dList.Parent = dBox[span_895](start_span)[span_895](end_span)

					local dListGrad = Instance.new("UIGradient")[span_896](start_span)[span_896](end_span)
					dListGrad.Color = ColorSequence.new({[span_897](start_span)[span_897](end_span)
						ColorSequenceKeypoint.new(0, THEME.DropListTop),[span_898](start_span)[span_898](end_span)
						ColorSequenceKeypoint.new(0.45, THEME.DropListMid),[span_899](start_span)[span_899](end_span)
						ColorSequenceKeypoint.new(1, THEME.DropListBottom)[span_900](start_span)[span_900](end_span)
					})[span_901](start_span)[span_901](end_span)
					dListGrad.Rotation = 90[span_902](start_span)[span_902](end_span)
					dListGrad.Parent = dList[span_903](start_span)[span_903](end_span)
					table.insert(ThemedRegistry.DropListGradients, dListGrad)[span_904](start_span)[span_904](end_span)

					local dListStroke = Instance.new("UIStroke")[span_905](start_span)[span_905](end_span)
					dListStroke.Color = THEME.BorderCard[span_906](start_span)[span_906](end_span)
					dListStroke.Thickness = 1[span_907](start_span)[span_907](end_span)
					dListStroke.Parent = dList[span_908](start_span)[span_908](end_span)
					table.insert(ThemedRegistry.CardStrokes, dListStroke)[span_909](start_span)[span_909](end_span)

					local dListLayout = Instance.new("UIListLayout")[span_910](start_span)[span_910](end_span)
					dListLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_911](start_span)[span_911](end_span)
					dListLayout.Padding = UDim.new(0, 1)[span_912](start_span)[span_912](end_span)
					dListLayout.Parent = dList[span_913](start_span)[span_913](end_span)

					local dOpen = false[span_914](start_span)[span_914](end_span)
					local function closeD()[span_915](start_span)[span_915](end_span)
						if not dOpen then return end[span_916](start_span)[span_916](end_span)
						dOpen = false[span_917](start_span)[span_917](end_span)
						dList.Visible = false[span_918](start_span)[span_918](end_span)
						row.ZIndex = 1
						if card then card.ZIndex = 1 end
						if activeDropdownClose == closeD then activeDropdownClose = nil end[span_919](start_span)[span_919](end_span)
					end[span_920](start_span)[span_920](end_span)
					local function openD()[span_921](start_span)[span_921](end_span)
						if activeDropdownClose and activeDropdownClose ~= closeD then activeDropdownClose() end[span_922](start_span)[span_922](end_span)
						dOpen = true[span_923](start_span)[span_923](end_span)
						activeDropdownClose = closeD[span_924](start_span)[span_924](end_span)

						local fullH = #opts * 16 + 4
						local spaceBelow = (playerScroll.AbsolutePosition.Y + playerScroll.AbsoluteSize.Y) - (dBox.AbsolutePosition.Y + dBox.AbsoluteSize.Y)
						if spaceBelow < fullH + 6 then
							dList.AnchorPoint = Vector2.new(0, 1)
							dList.Position = UDim2.new(0, 0, 0, -2)
						else
							dList.AnchorPoint = Vector2.new(0, 0)
							dList.Position = UDim2.new(0, 0, 1, 2)
						end

						row.ZIndex = 250
						if card then card.ZIndex = 250 end
						dList.Visible = true[span_925](start_span)[span_925](end_span)
					end[span_926](start_span)[span_926](end_span)

					dBox.MouseButton1Click:Connect(function()[span_927](start_span)[span_927](end_span)
						if dOpen then closeD() else openD() end[span_928](start_span)[span_928](end_span)
					end)[span_929](start_span)[span_929](end_span)

					for _, optName in ipairs(opts) do[span_930](start_span)[span_930](end_span)
						local optB = Instance.new("TextButton")[span_931](start_span)[span_931](end_span)
						optB.Size = UDim2.new(1, 0, 0, 16)[span_932](start_span)[span_932](end_span)
						optB.BackgroundTransparency = 1[span_933](start_span)[span_933](end_span)
						optB.Text = optName[span_934](start_span)[span_934](end_span)
						optB.Font = FONT[span_935](start_span)[span_935](end_span)
						optB.TextSize = 10[span_936](start_span)[span_936](end_span)
						optB.TextColor3 = (optName == curOpt and THEME.AccentLilacLight) or THEME.TextMuted[span_937](start_span)[span_937](end_span)
						optB.ZIndex = 322
						optB.Parent = dList[span_938](start_span)[span_938](end_span)

						table.insert(ThemedRegistry.DropdownLabels, {[span_939](start_span)[span_939](end_span)
							Label = optB,[span_940](start_span)[span_940](end_span)
							IsActive = function() return curOpt == optName end[span_941](start_span)[span_941](end_span)
						})[span_942](start_span)[span_942](end_span)

						optB.MouseButton1Click:Connect(function()[span_943](start_span)[span_943](end_span)
							curOpt = optName[span_944](start_span)[span_944](end_span)
							dVal.Text = optName[span_945](start_span)[span_945](end_span)
							closeD()[span_946](start_span)[span_946](end_span)
							if cfg.callback then cfg.callback(plr, optName) end[span_947](start_span)[span_947](end_span)
						end)[span_948](start_span)[span_948](end_span)
					end[span_949](start_span)[span_949](end_span)
				end[span_950](start_span)[span_950](end_span)
			end[span_951](start_span)[span_951](end_span)

			playerRows[plr] = row[span_952](start_span)[span_952](end_span)
			plr:GetPropertyChangedSignal("Team"):Connect(function()[span_953](start_span)[span_953](end_span)
				updatePlayerVisibility(plr)[span_954](start_span)[span_954](end_span)
			end)[span_955](start_span)[span_955](end_span)
		end[span_956](start_span)[span_956](end_span)

		for _, p in ipairs(Players:GetPlayers()) do[span_957](start_span)[span_957](end_span)
			buildPlayerRow(p)[span_958](start_span)[span_958](end_span)
		end[span_959](start_span)[span_959](end_span)

		Players.PlayerAdded:Connect(buildPlayerRow)[span_960](start_span)[span_960](end_span)
		Players.PlayerRemoving:Connect(function(plr)[span_961](start_span)[span_961](end_span)
			if playerRows[plr] then[span_962](start_span)[span_962](end_span)
				playerRows[plr]:Destroy()[span_963](start_span)[span_963](end_span)
				playerRows[plr] = nil[span_964](start_span)[span_964](end_span)
			end[span_965](start_span)[span_965](end_span)
		end)[span_966](start_span)[span_966](end_span)

		LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()[span_967](start_span)[span_967](end_span)
			for p, _ in pairs(playerRows) do[span_968](start_span)[span_968](end_span)
				updatePlayerVisibility(p)[span_969](start_span)[span_969](end_span)
			end[span_970](start_span)[span_970](end_span)
		end)[span_971](start_span)[span_971](end_span)

		return {[span_972](start_span)[span_972](end_span)
			Instance = card,[span_973](start_span)[span_973](end_span)
			Refresh = function()[span_974](start_span)[span_974](end_span)
				for p, _ in pairs(playerRows) do[span_975](start_span)[span_975](end_span)
					updatePlayerVisibility(p)[span_976](start_span)[span_976](end_span)
				end[span_977](start_span)[span_977](end_span)
			end[span_978](start_span)[span_978](end_span)
		}[span_979](start_span)[span_979](end_span)
	end[span_980](start_span)[span_980](end_span)

	local WatermarkFrame = Instance.new("Frame")[span_981](start_span)[span_981](end_span)
	WatermarkFrame.Name = "Watermark[span_982](start_span)"[span_982](end_span)
	WatermarkFrame.AnchorPoint = Vector2.new(1, 0)[span_983](start_span)[span_983](end_span)
	WatermarkFrame.Position = UDim2.new(0.98, 0, 0, 16)[span_984](start_span)[span_984](end_span)
	WatermarkFrame.Size = UDim2.new(0, 0, 0, 24)[span_985](start_span)[span_985](end_span)
	WatermarkFrame.AutomaticSize = Enum.AutomaticSize.X[span_986](start_span)[span_986](end_span)
	WatermarkFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_987](start_span)[span_987](end_span)
	WatermarkFrame.BorderSizePixel = 0[span_988](start_span)[span_988](end_span)
	WatermarkFrame.Active = false[span_989](start_span)[span_989](end_span)
	WatermarkFrame.ClipsDescendants = false[span_990](start_span)[span_990](end_span)
	WatermarkFrame.ZIndex = 50[span_991](start_span)[span_991](end_span)
	WatermarkFrame.Visible = false[span_992](start_span)[span_992](end_span)
	WatermarkFrame.Parent = ScreenGui[span_993](start_span)[span_993](end_span)

	local wmBgGrad = Instance.new("UIGradient")[span_994](start_span)[span_994](end_span)
	wmBgGrad.Color = ColorSequence.new({[span_995](start_span)[span_995](end_span)
		ColorSequenceKeypoint.new(0, THEME.DropListTop),[span_996](start_span)[span_996](end_span)
		ColorSequenceKeypoint.new(0.45, THEME.DropListMid),[span_997](start_span)[span_997](end_span)
		ColorSequenceKeypoint.new(1, THEME.DropListBottom)[span_998](start_span)[span_998](end_span)
	})[span_999](start_span)[span_999](end_span)
	wmBgGrad.Rotation = 90[span_1000](start_span)[span_1000](end_span)
	wmBgGrad.Parent = WatermarkFrame[span_1001](start_span)[span_1001](end_span)
	table.insert(ThemedRegistry.DropListGradients, wmBgGrad)[span_1002](start_span)[span_1002](end_span)

	local wmStroke = Instance.new("UIStroke")[span_1003](start_span)[span_1003](end_span)
	wmStroke.Color = THEME.BorderCard[span_1004](start_span)[span_1004](end_span)
	wmStroke.Thickness = 1[span_1005](start_span)[span_1005](end_span)
	wmStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border[span_1006](start_span)[span_1006](end_span)
	wmStroke.Parent = WatermarkFrame[span_1007](start_span)[span_1007](end_span)
	table.insert(ThemedRegistry.CardStrokes, wmStroke)[span_1008](start_span)[span_1008](end_span)

	local wmTopLine = Instance.new("Frame")[span_1009](start_span)[span_1009](end_span)
	wmTopLine.Name = "TopLine[span_1010](start_span)"[span_1010](end_span)
	wmTopLine.Size = UDim2.new(1, 0, 0, 1.2)[span_1011](start_span)[span_1011](end_span)
	wmTopLine.Position = UDim2.new(0, 0, 0, 0)[span_1012](start_span)[span_1012](end_span)
	wmTopLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_1013](start_span)[span_1013](end_span)
	wmTopLine.BorderSizePixel = 0[span_1014](start_span)[span_1014](end_span)
	wmTopLine.ZIndex = 55[span_1015](start_span)[span_1015](end_span)
	wmTopLine.Parent = WatermarkFrame[span_1016](start_span)[span_1016](end_span)

	local wmTopGrad = Instance.new("UIGradient")[span_1017](start_span)[span_1017](end_span)
	wmTopGrad.Color = ColorSequence.new({[span_1018](start_span)[span_1018](end_span)
		ColorSequenceKeypoint.new(0, THEME.AccentLilacLight),[span_1019](start_span)[span_1019](end_span)
		ColorSequenceKeypoint.new(0.65, THEME.AccentLilacLight),[span_1020](start_span)[span_1020](end_span)
		ColorSequenceKeypoint.new(1, THEME.AccentLilacDeep)[span_1021](start_span)[span_1021](end_span)
	})[span_1022](start_span)[span_1022](end_span)
	wmTopGrad.Parent = wmTopLine[span_1023](start_span)[span_1023](end_span)
	table.insert(ThemedRegistry.AccentLineGradients, wmTopGrad)[span_1024](start_span)[span_1024](end_span)

	local ContentHolder = Instance.new("Frame")[span_1025](start_span)[span_1025](end_span)
	ContentHolder.BackgroundTransparency = 1[span_1026](start_span)[span_1026](end_span)
	ContentHolder.Size = UDim2.new(0, 0, 1, 0)[span_1027](start_span)[span_1027](end_span)
	ContentHolder.AutomaticSize = Enum.AutomaticSize.X[span_1028](start_span)[span_1028](end_span)
	ContentHolder.ZIndex = 52[span_1029](start_span)[span_1029](end_span)
	ContentHolder.Parent = WatermarkFrame[span_1030](start_span)[span_1030](end_span)

	local contentLayout = Instance.new("UIListLayout")[span_1031](start_span)[span_1031](end_span)
	contentLayout.FillDirection = Enum.FillDirection.Horizontal[span_1032](start_span)[span_1032](end_span)
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center[span_1033](start_span)[span_1033](end_span)
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left[span_1034](start_span)[span_1034](end_span)
	contentLayout.Padding = UDim.new(0, 3)[span_1035](start_span)[span_1035](end_span)
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_1036](start_span)[span_1036](end_span)
	contentLayout.Parent = ContentHolder[span_1037](start_span)[span_1037](end_span)

	local contentPad = Instance.new("UIPadding")[span_1038](start_span)[span_1038](end_span)
	contentPad.PaddingLeft = UDim.new(0, 8)[span_1039](start_span)[span_1039](end_span)
	contentPad.PaddingRight = UDim.new(0, 8)[span_1040](start_span)[span_1040](end_span)
	contentPad.PaddingTop = UDim.new(0, 1)[span_1041](start_span)[span_1041](end_span)
	contentPad.Parent = ContentHolder[span_1042](start_span)[span_1042](end_span)

	local function getSepMarkup()[span_1043](start_span)[span_1043](end_span)
		local r = math.round(THEME.TextMuted.R * 255)[span_1044](start_span)[span_1044](end_span)
		local g = math.round(THEME.TextMuted.G * 255)[span_1045](start_span)[span_1045](end_span)
		local b = math.round(THEME.TextMuted.B * 255)[span_1046](start_span)[span_1046](end_span)
		return string.format('<font color="rgb(%d, %d, %d)"> | </font>', r, g, b)[span_1047](start_span)[span_1047](end_span)
	end[span_1048](start_span)[span_1048](end_span)

	local wmLabel = Instance.new("TextLabel")[span_1049](start_span)[span_1049](end_span)
	wmLabel.Name = "Text[span_1050](start_span)"[span_1050](end_span)
	wmLabel.RichText = true[span_1051](start_span)[span_1051](end_span)
	wmLabel.Text = string.format("%s%s0 FPS%s0ms Ping%s0%% CPU", titleName, getSepMarkup(), getSepMarkup(), getSepMarkup())[span_1052](start_span)[span_1052](end_span)
	wmLabel.Font = FONT[span_1053](start_span)[span_1053](end_span)
	wmLabel.TextSize = 12[span_1054](start_span)[span_1054](end_span)
	wmLabel.TextColor3 = THEME.TextPrimary[span_1055](start_span)[span_1055](end_span)
	wmLabel.BackgroundTransparency = 1[span_1056](start_span)[span_1056](end_span)
	wmLabel.Size = UDim2.new(0, 0, 1, 0)[span_1057](start_span)[span_1057](end_span)
	wmLabel.AutomaticSize = Enum.AutomaticSize.X[span_1058](start_span)[span_1058](end_span)
	wmLabel.TextXAlignment = Enum.TextXAlignment.Left[span_1059](start_span)[span_1059](end_span)
	wmLabel.LayoutOrder = 1[span_1060](start_span)[span_1060](end_span)
	wmLabel.ZIndex = 53[span_1061](start_span)[span_1061](end_span)
	wmLabel.Parent = ContentHolder[span_1062](start_span)[span_1062](end_span)
	table.insert(ThemedRegistry.PrimaryTexts, wmLabel)[span_1063](start_span)[span_1063](end_span)

	enableDrag(WatermarkFrame, WatermarkFrame)[span_1064](start_span)[span_1064](end_span)

	local function getPing()[span_1065](start_span)[span_1065](end_span)
		local ping = 0[span_1066](start_span)[span_1066](end_span)
		pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)[span_1067](start_span)[span_1067](end_span)
		if ping <= 0 then[span_1068](start_span)[span_1068](end_span)
			pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)[span_1069](start_span)[span_1069](end_span)
		end[span_1070](start_span)[span_1070](end_span)
		return math.max(0, ping)[span_1071](start_span)[span_1071](end_span)
	end[span_1072](start_span)[span_1072](end_span)

	local function getCpuUsage(dt)[span_1073](start_span)[span_1073](end_span)
		local cpu = 0[span_1074](start_span)[span_1074](end_span)
		pcall(function() cpu = math.floor(Stats.PerformanceStats.CPU:GetValue()) end)[span_1075](start_span)[span_1075](end_span)
		if cpu and cpu > 0 then return math.clamp(cpu, 1, 100) end[span_1076](start_span)[span_1076](end_span)
		local ratio = dt / (1 / 60)[span_1077](start_span)[span_1077](end_span)
		local memKb = collectgarbage("count")[span_1078](start_span)[span_1078](end_span)
		local memFactor = (memKb % 500) / 75[span_1079](start_span)[span_1079](end_span)
		local jitter = math.sin(tick() * 3) * 2.5[span_1080](start_span)[span_1080](end_span)
		return math.clamp(math.floor((ratio * 12) + memFactor + jitter + 6), 4, 96)[span_1081](start_span)[span_1081](end_span)
	end[span_1082](start_span)[span_1082](end_span)

	local frameCount = 0[span_1083](start_span)[span_1083](end_span)
	local lastUpdate = tick()[span_1084](start_span)[span_1084](end_span)
	local lastDelta = 0.016[span_1085](start_span)[span_1085](end_span)

	RunService.RenderStepped:Connect(function(dt)[span_1086](start_span)[span_1086](end_span)
		if customCursorEnabled then[span_1087](start_span)[span_1087](end_span)
			local mLoc = UserInputService:GetMouseLocation()[span_1088](start_span)[span_1088](end_span)
			customCursorImage.Position = UDim2.new(0, mLoc.X, 0, mLoc.Y)[span_1089](start_span)[span_1089](end_span)
		end[span_1090](start_span)[span_1090](end_span)

		frameCount = frameCount + 1[span_1091](start_span)[span_1091](end_span)
		lastDelta = dt[span_1092](start_span)[span_1092](end_span)
		local now = tick()[span_1093](start_span)[span_1093](end_span)
		if now - lastUpdate >= 0.35 then[span_1094](start_span)[span_1094](end_span)
			local currentFps = math.floor(frameCount / (now - lastUpdate))[span_1095](start_span)[span_1095](end_span)
			local currentPing = getPing()[span_1096](start_span)[span_1096](end_span)
			local currentCpu = getCpuUsage(lastDelta)[span_1097](start_span)[span_1097](end_span)
			local sep = getSepMarkup()[span_1098](start_span)[span_1098](end_span)
			wmLabel.Text = string.format("%s%s%d FPS%s%dms Ping%s%d%% CPU", titleName, sep, currentFps, sep, currentPing, sep, currentCpu)[span_1099](start_span)[span_1099](end_span)
			frameCount = 0[span_1100](start_span)[span_1100](end_span)
			lastUpdate = now[span_1101](start_span)[span_1101](end_span)
		end[span_1102](start_span)[span_1102](end_span)
	end)[span_1103](start_span)[span_1103](end_span)

	local windowObj = {[span_1104](start_span)[span_1104](end_span)
		ScreenGui = ScreenGui,[span_1105](start_span)[span_1105](end_span)
		MainFrame = MainFrame,[span_1106](start_span)[span_1106](end_span)
		ConfigFeatureEntries = ConfigFeatureEntries,[span_1107](start_span)[span_1107](end_span)
		CreatedTabsCount = 0,[span_1108](start_span)[span_1108](end_span)
		Tabs = {},[span_1109](start_span)[span_1109](end_span)
		FirstTabName = nil[span_1110](start_span)[span_1110](end_span)
	}[span_1111](start_span)[span_1111](end_span)

	local function setupSettingsTab()[span_1112](start_span)[span_1112](end_span)
		local settingsPage = Instance.new("Frame")[span_1113](start_span)[span_1113](end_span)
		settingsPage.Name = "SettingsPage[span_1114](start_span)"[span_1114](end_span)
		settingsPage.BackgroundTransparency = 1[span_1115](start_span)[span_1115](end_span)
		settingsPage.Size = UDim2.new(1, 0, 1, 0)[span_1116](start_span)[span_1116](end_span)
		settingsPage.Visible = false[span_1117](start_span)[span_1117](end_span)
		settingsPage.Parent = ContentArea[span_1118](start_span)[span_1118](end_span)
		TabPages["Settings"] = settingsPage[span_1119](start_span)[span_1119](end_span)

		TabSubConfig["Settings"] = {[span_1120](start_span)[span_1120](end_span)
			{ iconText = "⚙", iconImg = getIcon("https://raw.githubusercontent.com/Essluau/icons/refs/heads/main/settings_.png", "settings_2.png"), page = nil }[span_1121](start_span)[span_1121](end_span)
		}[span_1122](start_span)[span_1122](end_span)

		local settingsLeft, settingsRight = createTabColumns(settingsPage)[span_1123](start_span)[span_1123](end_span)
		local _, settingsLeftContent = createSectionCard(settingsLeft, "Settings", 260, 1)[span_1124](start_span)[span_1124](end_span)

		createKeybind(settingsLeftContent, "UI Keybind", Enum.KeyCode.K, function()[span_1125](start_span)[span_1125](end_span)
			MainFrame.Visible = not MainFrame.Visible[span_1126](start_span)[span_1126](end_span)
			if not MainFrame.Visible and activeDropdownClose then[span_1127](start_span)[span_1127](end_span)
				activeDropdownClose()[span_1128](start_span)[span_1128](end_span)
			end[span_1129](start_span)[span_1129](end_span)
		end, "__theme_ui_keybind")[span_1130](start_span)[span_1130](end_span)

		createToggle(settingsLeftContent, "Watermark", false, nil, function(state)[span_1131](start_span)[span_1131](end_span)
			WatermarkFrame.Visible = state[span_1132](start_span)[span_1132](end_span)
		end, "__theme_watermark")[span_1133](start_span)[span_1133](end_span)

		createToggle(settingsLeftContent, "CustomCursor", false, "colorbox", function(state)[span_1134](start_span)[span_1134](end_span)
			customCursorEnabled = state[span_1135](start_span)[span_1135](end_span)
			customCursorImage.Visible = state[span_1136](start_span)[span_1136](end_span)
			UserInputService.MouseIconEnabled = not state[span_1137](start_span)[span_1137](end_span)
		end, "__theme_custom_cursor", function(col)[span_1138](start_span)[span_1138](end_span)
			customCursorColor = col[span_1139](start_span)[span_1139](end_span)
			customCursorImage.ImageColor3 = col[span_1140](start_span)[span_1140](end_span)
		end, Color3.fromRGB(255, 255, 255))[span_1141](start_span)[span_1141](end_span)

		createDropdown(settingsLeftContent, "Font", "Tahoma", {"SourceSans", "Roboto", "Gotham", "Ubuntu", "Arial", "Tahoma"}, 50, function(selectedFont)[span_1142](start_span)[span_1142](end_span)
			applyGlobalFont(ScreenGui, selectedFont)[span_1143](start_span)[span_1143](end_span)
		end, "__theme_font")[span_1144](start_span)[span_1144](end_span)

		createColorPickerRow(settingsLeftContent, "Accent", defaultAccent, function(chosenColor)[span_1145](start_span)[span_1145](end_span)
			applyAccentColor(chosenColor)[span_1146](start_span)[span_1146](end_span)
		end, "__theme_accent")[span_1147](start_span)[span_1147](end_span)

		local _, secBindCard = createSectionCard(settingsLeft, "Section Binds", 200, 2)[span_1148](start_span)[span_1148](end_span)

		local bindSectionsActive = false[span_1149](start_span)[span_1149](end_span)
		local sectionKeyCodes = {[span_1150](start_span)[span_1150](end_span)
			Enum.KeyCode.One,[span_1151](start_span)[span_1151](end_span)
			Enum.KeyCode.Two,[span_1152](start_span)[span_1152](end_span)
			Enum.KeyCode.Three,[span_1153](start_span)[span_1153](end_span)
			Enum.KeyCode.Four,[span_1154](start_span)[span_1154](end_span)
			Enum.KeyCode.Five[span_1155](start_span)[span_1155](end_span)
		}[span_1156](start_span)[span_1156](end_span)

		local sectionKeybindObjects = {}[span_1157](start_span)[span_1157](end_span)

		createToggle(secBindCard, "Bind Sections", false, nil, function(state)[span_1158](start_span)[span_1158](end_span)
			bindSectionsActive = state[span_1159](start_span)[span_1159](end_span)
		end, "__theme_bind_sections")[span_1160](start_span)[span_1160](end_span)

		local schemePresets = {[span_1161](start_span)[span_1161](end_span)
			["1 - 5"]        = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five },[span_1162](start_span)[span_1162](end_span)
			["NumPad 1 - 5"] = { Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour, Enum.KeyCode.KeypadFive },[span_1163](start_span)[span_1163](end_span)
			["F1 - F5"]      = { Enum.KeyCode.F1, Enum.KeyCode.F2, Enum.KeyCode.F3, Enum.KeyCode.F4, Enum.KeyCode.F5 },[span_1164](start_span)[span_1164](end_span)
			["Z - B"]        = { Enum.KeyCode.Z, Enum.KeyCode.X, Enum.KeyCode.C, Enum.KeyCode.V, Enum.KeyCode.B }[span_1165](start_span)[span_1165](end_span)
		}[span_1166](start_span)[span_1166](end_span)

		createDropdown(secBindCard, "Sections Bind Preset", "1 - 5", {"1 - 5", "NumPad 1 - 5", "F1 - F5", "Z - B"}, 45, function(chosenPreset)[span_1167](start_span)[span_1167](end_span)
			local keys = schemePresets[chosenPreset][span_1168](start_span)[span_1168](end_span)
			if keys then[span_1169](start_span)[span_1169](end_span)
				for i = 1, 5 do[span_1170](start_span)[span_1170](end_span)
					sectionKeyCodes[i] = keys[i][span_1171](start_span)[span_1171](end_span)
					if sectionKeybindObjects[i] then[span_1172](start_span)[span_1172](end_span)
						sectionKeybindObjects[i].Set(keys[i])[span_1173](start_span)[span_1173](end_span)
					end[span_1174](start_span)[span_1174](end_span)
				end[span_1175](start_span)[span_1175](end_span)
			end[span_1176](start_span)[span_1176](end_span)
		end, "__theme_sections_bind_preset")[span_1177](start_span)[span_1177](end_span)

		for i = 1, 5 do[span_1178](start_span)[span_1178](end_span)
			local kb = createKeybind(secBindCard, "Section " .. i, sectionKeyCodes[i], function() end, "__theme_sec_bind_" .. i, function(newKey)[span_1179](start_span)[span_1179](end_span)
				sectionKeyCodes[i] = newKey[span_1180](start_span)[span_1180](end_span)
			end)[span_1181](start_span)[span_1181](end_span)
			sectionKeybindObjects[i] = kb[span_1182](start_span)[span_1182](end_span)
		end[span_1183](start_span)[span_1183](end_span)

		UserInputService.InputBegan:Connect(function(input, gpe)[span_1184](start_span)[span_1184](end_span)
			if not bindSectionsActive then return end[span_1185](start_span)[span_1185](end_span)
			if not MainFrame.Visible then return end[span_1186](start_span)[span_1186](end_span)
			if UserInputService:GetFocusedTextBox() ~= nil then return end[span_1187](start_span)[span_1187](end_span)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end[span_1188](start_span)[span_1188](end_span)

			for i = 1, 5 do[span_1189](start_span)[span_1189](end_span)
				local key = sectionKeyCodes[i][span_1190](start_span)[span_1190](end_span)
				if key and key ~= Enum.KeyCode.Unknown and input.KeyCode == key then[span_1191](start_span)[span_1191](end_span)
					local allTabs = {}[span_1192](start_span)[span_1192](end_span)
					for _, tabName in ipairs(windowObj.Tabs) do[span_1193](start_span)[span_1193](end_span)
						table.insert(allTabs, tabName)[span_1194](start_span)[span_1194](end_span)
					end[span_1195](start_span)[span_1195](end_span)
					table.insert(allTabs, "Settings")[span_1196](start_span)[span_1196](end_span)

					if allTabs[i] then[span_1197](start_span)[span_1197](end_span)
						switchTab(allTabs[i])[span_1198](start_span)[span_1198](end_span)
					end[span_1199](start_span)[span_1199](end_span)
					break[span_1200](start_span)[span_1200](end_span)
				end[span_1201](start_span)[span_1201](end_span)
			end[span_1202](start_span)[span_1202](end_span)
		end)[span_1203](start_span)[span_1203](end_span)

		local _, cfgRightCard = createSectionCard(settingsRight, "Configs", 400, 1)[span_1204](start_span)[span_1204](end_span)

		local cfgListBox = Instance.new("Frame")[span_1205](start_span)[span_1205](end_span)
		cfgListBox.Size = UDim2.new(1, 0, 0, 150)[span_1206](start_span)[span_1206](end_span)
		cfgListBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_1207](start_span)[span_1207](end_span)
		cfgListBox.BorderSizePixel = 0[span_1208](start_span)[span_1208](end_span)
		cfgListBox.ClipsDescendants = true[span_1209](start_span)[span_1209](end_span)
		cfgListBox.Parent = cfgRightCard[span_1210](start_span)[span_1210](end_span)

		local cfgListGrad = Instance.new("UIGradient")[span_1211](start_span)[span_1211](end_span)
		cfgListGrad.Color = ColorSequence.new({[span_1212](start_span)[span_1212](end_span)
			ColorSequenceKeypoint.new(0, THEME.WindowBgTop),[span_1213](start_span)[span_1213](end_span)
			ColorSequenceKeypoint.new(1, THEME.WindowBgBottom)[span_1214](start_span)[span_1214](end_span)
		})[span_1215](start_span)[span_1215](end_span)
		cfgListGrad.Rotation = 90[span_1216](start_span)[span_1216](end_span)
		cfgListGrad.Parent = cfgListBox[span_1217](start_span)[span_1217](end_span)
		table.insert(ThemedRegistry.WindowGradients, cfgListGrad)[span_1218](start_span)[span_1218](end_span)

		local cfgListStroke = Instance.new("UIStroke")[span_1219](start_span)[span_1219](end_span)
		cfgListStroke.Color = THEME.BorderElement[span_1220](start_span)[span_1220](end_span)
		cfgListStroke.Thickness = 1[span_1221](start_span)[span_1221](end_span)
		cfgListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border[span_1222](start_span)[span_1222](end_span)
		cfgListStroke.Parent = cfgListBox[span_1223](start_span)[span_1223](end_span)
		table.insert(ThemedRegistry.ElementStrokes, cfgListStroke)[span_1224](start_span)[span_1224](end_span)

		local cfgScroll = Instance.new("ScrollingFrame")[span_1225](start_span)[span_1225](end_span)
		cfgScroll.Size = UDim2.new(1, -6, 1, -6)[span_1226](start_span)[span_1226](end_span)
		cfgScroll.Position = UDim2.new(0, 3, 0, 3)[span_1227](start_span)[span_1227](end_span)
		cfgScroll.BackgroundTransparency = 1[span_1228](start_span)[span_1228](end_span)
		cfgScroll.BorderSizePixel = 0[span_1229](start_span)[span_1229](end_span)
		cfgScroll.ScrollBarThickness = 3[span_1230](start_span)[span_1230](end_span)
		cfgScroll.ScrollBarImageColor3 = THEME.AccentLilacLight[span_1231](start_span)[span_1231](end_span)
		cfgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)[span_1232](start_span)[span_1232](end_span)
		cfgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y[span_1233](start_span)[span_1233](end_span)
		cfgScroll.ClipsDescendants = true[span_1234](start_span)[span_1234](end_span)
		cfgScroll.Parent = cfgListBox[span_1235](start_span)[span_1235](end_span)
		table.insert(ThemedRegistry.Scrollbars, cfgScroll)[span_1236](start_span)[span_1236](end_span)

		local cfgListLayout = Instance.new("UIListLayout")[span_1237](start_span)[span_1237](end_span)
		cfgListLayout.SortOrder = Enum.SortOrder.LayoutOrder[span_1238](start_span)[span_1238](end_span)
		cfgListLayout.Padding = UDim.new(0, 2)[span_1239](start_span)[span_1239](end_span)
		cfgListLayout.Parent = cfgScroll[span_1240](start_span)[span_1240](end_span)

		local _, nameBoxInput = createInput(cfgRightCard, "Name", "Config name...", "default")[span_1241](start_span)[span_1241](end_span)

		refreshConfigListDisplay = function()[span_1242](start_span)[span_1242](end_span)
			for _, child in ipairs(cfgScroll:GetChildren()) do[span_1243](start_span)[span_1243](end_span)
				if child:IsA("TextButton") then child:Destroy() end[span_1244](start_span)[span_1244](end_span)
			end[span_1245](start_span)[span_1245](end_span)

			local configsFound = {}[span_1246](start_span)[span_1246](end_span)
			local function scanConfigs(folderName)[span_1247](start_span)[span_1247](end_span)
				if listfiles and isfolder and isfolder(folderName) then[span_1248](start_span)[span_1248](end_span)
					local success, files = pcall(function() return listfiles(folderName) end)[span_1249](start_span)[span_1249](end_span)
					if success and files then[span_1250](start_span)[span_1250](end_span)
						for _, filePath in ipairs(files) do[span_1251](start_span)[span_1251](end_span)
							local rawName = filePath:match("([^/\\]+)$") or filePath[span_1252](start_span)[span_1252](end_span)
							if not table.find(configsFound, rawName) then[span_1253](start_span)[span_1253](end_span)
								table.insert(configsFound, rawName)[span_1254](start_span)[span_1254](end_span)
							end[span_1255](start_span)[span_1255](end_span)
						end[span_1256](start_span)[span_1256](end_span)
					end[span_1257](start_span)[span_1257](end_span)
				end[span_1258](start_span)[span_1258](end_span)
			end[span_1259](start_span)[span_1259](end_span)
			scanConfigs(cfgFolder)[span_1260](start_span)[span_1260](end_span)

			for k, _ in pairs(FallbackConfigStore) do[span_1261](start_span)[span_1261](end_span)
				if not table.find(configsFound, k) then table.insert(configsFound, k) end[span_1262](start_span)[span_1262](end_span)
			end[span_1263](start_span)[span_1263](end_span)

			if #configsFound == 0 then table.insert(configsFound, "default.json") end[span_1264](start_span)[span_1264](end_span)
			table.sort(configsFound)[span_1265](start_span)[span_1265](end_span)

			for idx, fileName in ipairs(configsFound) do[span_1266](start_span)[span_1266](end_span)
				local itemBtn = Instance.new("TextButton")[span_1267](start_span)[span_1267](end_span)
				itemBtn.Size = UDim2.new(1, 0, 0, 22)[span_1268](start_span)[span_1268](end_span)
				itemBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_1269](start_span)[span_1269](end_span)
				itemBtn.BackgroundTransparency = (fileName == selectedConfigFileName and 0.88 or 1)[span_1270](start_span)[span_1270](end_span)
				itemBtn.BorderSizePixel = 0[span_1271](start_span)[span_1271](end_span)
				itemBtn.Text = "[span_1272](start_span)"[span_1272](end_span)
				itemBtn.AutoButtonColor = false[span_1273](start_span)[span_1273](end_span)
				itemBtn.LayoutOrder = idx[span_1274](start_span)[span_1274](end_span)
				itemBtn.Parent = cfgScroll[span_1275](start_span)[span_1275](end_span)

				local itemLabel = Instance.new("TextLabel")[span_1276](start_span)[span_1276](end_span)
				itemLabel.Text = fileName[span_1277](start_span)[span_1277](end_span)
				itemLabel.Font = FONT[span_1278](start_span)[span_1278](end_span)
				itemLabel.TextSize = 12[span_1279](start_span)[span_1279](end_span)
				itemLabel.TextColor3 = (fileName == selectedConfigFileName and THEME.AccentLilacLight or THEME.TextPrimary)[span_1280](start_span)[span_1280](end_span)
				itemLabel.TextXAlignment = Enum.TextXAlignment.Left[span_1281](start_span)[span_1281](end_span)
				itemLabel.BackgroundTransparency = 1[span_1282](start_span)[span_1282](end_span)
				itemLabel.Position = UDim2.new(0, 6, 0, 0)[span_1283](start_span)[span_1283](end_span)
				itemLabel.Size = UDim2.new(1, -12, 1, 0)[span_1284](start_span)[span_1284](end_span)
				itemLabel.Parent = itemBtn[span_1285](start_span)[span_1285](end_span)

				applyFontToObject(itemLabel)[span_1286](start_span)[span_1286](end_span)

				itemBtn.MouseButton1Click:Connect(function()[span_1287](start_span)[span_1287](end_span)
					selectedConfigFileName = fileName[span_1288](start_span)[span_1288](end_span)
					nameBoxInput.Text = fileName:gsub("%.json$", "")[span_1289](start_span)[span_1289](end_span)
					for _, other in ipairs(cfgScroll:GetChildren()) do[span_1290](start_span)[span_1290](end_span)
						if other:IsA("TextButton") and other:FindFirstChildOfClass("TextLabel") then[span_1291](start_span)[span_1291](end_span)
							local lbl = other:FindFirstChildOfClass("TextLabel")[span_1292](start_span)[span_1292](end_span)
							if lbl.Text == selectedConfigFileName then[span_1293](start_span)[span_1293](end_span)
								other.BackgroundTransparency = 0.88[span_1294](start_span)[span_1294](end_span)
								lbl.TextColor3 = THEME.AccentLilacLight[span_1295](start_span)[span_1295](end_span)
							else[span_1296](start_span)[span_1296](end_span)
								other.BackgroundTransparency = 1[span_1297](start_span)[span_1297](end_span)
								lbl.TextColor3 = THEME.TextPrimary[span_1298](start_span)[span_1298](end_span)
							end[span_1299](start_span)[span_1299](end_span)
						end[span_1300](start_span)[span_1300](end_span)
					end[span_1301](start_span)[span_1301](end_span)
				end)[span_1302](start_span)[span_1302](end_span)
			end[span_1303](start_span)[span_1303](end_span)
		end[span_1304](start_span)[span_1304](end_span)

		local function saveConfigHandler()[span_1305](start_span)[span_1305](end_span)
			local cfgName = nameBoxInput.Text[span_1306](start_span)[span_1306](end_span)
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = "default" end[span_1307](start_span)[span_1307](end_span)
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end[span_1308](start_span)[span_1308](end_span)

			local dumpData = {}[span_1309](start_span)[span_1309](end_span)
			for key, entry in pairs(ConfigFeatureEntries) do[span_1310](start_span)[span_1310](end_span)
				pcall(function() dumpData[key] = entry.Get() end)[span_1311](start_span)[span_1311](end_span)
			end[span_1312](start_span)[span_1312](end_span)

			local encoded = HttpService:JSONEncode(dumpData)[span_1313](start_span)[span_1313](end_span)
			if writefile then[span_1314](start_span)[span_1314](end_span)
				pcall(function() writefile(cfgFolder .. "/" .. cfgName, encoded) end)[span_1315](start_span)[span_1315](end_span)
			else[span_1316](start_span)[span_1316](end_span)
				FallbackConfigStore[cfgName] = encoded[span_1317](start_span)[span_1317](end_span)
			end[span_1318](start_span)[span_1318](end_span)
			selectedConfigFileName = cfgName[span_1319](start_span)[span_1319](end_span)
			refreshConfigListDisplay()[span_1320](start_span)[span_1320](end_span)
		end[span_1321](start_span)[span_1321](end_span)

		local function loadConfigHandler()[span_1322](start_span)[span_1322](end_span)
			local cfgName = nameBoxInput.Text[span_1323](start_span)[span_1323](end_span)
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = selectedConfigFileName end[span_1324](start_span)[span_1324](end_span)
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end[span_1325](start_span)[span_1325](end_span)

			local content = nil[span_1326](start_span)[span_1326](end_span)
			if readfile and isfile then[span_1327](start_span)[span_1327](end_span)
				if isfile(cfgFolder .. "/" .. cfgName) then[span_1328](start_span)[span_1328](end_span)
					pcall(function() content = readfile(cfgFolder .. "/" .. cfgName) end)[span_1329](start_span)[span_1329](end_span)
				end[span_1330](start_span)[span_1330](end_span)
			elseif FallbackConfigStore[cfgName] then[span_1331](start_span)[span_1331](end_span)
				content = FallbackConfigStore[cfgName][span_1332](start_span)[span_1332](end_span)
			end[span_1333](start_span)[span_1333](end_span)

			if content then[span_1334](start_span)[span_1334](end_span)
				local success, decoded = pcall(function() return HttpService:JSONDecode(content) end)[span_1335](start_span)[span_1335](end_span)
				if success and type(decoded) == "table" then[span_1336](start_span)[span_1336](end_span)
					for featureName, val in pairs(decoded) do[span_1337](start_span)[span_1337](end_span)
						if ConfigFeatureEntries[featureName] then[span_1338](start_span)[span_1338](end_span)
							pcall(function() ConfigFeatureEntries[featureName].Set(val) end)[span_1339](start_span)[span_1339](end_span)
						end[span_1340](start_span)[span_1340](end_span)
					end[span_1341](start_span)[span_1341](end_span)
				end[span_1342](start_span)[span_1342](end_span)
			end[span_1343](start_span)[span_1343](end_span)
			selectedConfigFileName = cfgName[span_1344](start_span)[span_1344](end_span)
			refreshConfigListDisplay()[span_1345](start_span)[span_1345](end_span)
		end[span_1346](start_span)[span_1346](end_span)

		local function deleteConfigHandler()[span_1347](start_span)[span_1347](end_span)
			local cfgName = nameBoxInput.Text[span_1348](start_span)[span_1348](end_span)
			if not cfgName or cfgName:gsub("%s+", "") == "" then cfgName = selectedConfigFileName end[span_1349](start_span)[span_1349](end_span)
			if not cfgName:lower():match("%.json$") then cfgName = cfgName .. ".json" end[span_1350](start_span)[span_1350](end_span)

			if delfile and isfile and isfile(cfgFolder .. "/" .. cfgName) then[span_1351](start_span)[span_1351](end_span)
				pcall(function() delfile(cfgFolder .. "/" .. cfgName) end)[span_1352](start_span)[span_1352](end_span)
			end[span_1353](start_span)[span_1353](end_span)
			FallbackConfigStore[cfgName] = nil[span_1354](start_span)[span_1354](end_span)
			refreshConfigListDisplay()[span_1355](start_span)[span_1355](end_span)
		end[span_1356](start_span)[span_1356](end_span)

		createDualActionButtons(cfgRightCard, "Load Config", loadConfigHandler, "Save Config", saveConfigHandler)[span_1357](start_span)[span_1357](end_span)
		createDualActionButtons(cfgRightCard, "Create Config", saveConfigHandler, "Delete Config", deleteConfigHandler)[span_1358](start_span)[span_1358](end_span)
		createActionButton(cfgRightCard, "Refresh Configs", refreshConfigListDisplay)[span_1359](start_span)[span_1359](end_span)

		refreshConfigListDisplay()[span_1360](start_span)[span_1360](end_span)
	end[span_1361](start_span)[span_1361](end_span)

	local function rebuildTabButtons()[span_1362](start_span)[span_1362](end_span)
		for _, child in ipairs(TabsHolder:GetChildren()) do[span_1363](start_span)[span_1363](end_span)
			if child:IsA("TextButton") then child:Destroy() end[span_1364](start_span)[span_1364](end_span)
		end[span_1365](start_span)[span_1365](end_span)
		TabButtons = {}[span_1366](start_span)[span_1366](end_span)

		local allTabs = {}[span_1367](start_span)[span_1367](end_span)
		for _, tabName in ipairs(windowObj.Tabs) do[span_1368](start_span)[span_1368](end_span)
			table.insert(allTabs, tabName)[span_1369](start_span)[span_1369](end_span)
		end[span_1370](start_span)[span_1370](end_span)
		table.insert(allTabs, "Settings")[span_1371](start_span)[span_1371](end_span)

		for i, tabName in ipairs(allTabs) do[span_1372](start_span)[span_1372](end_span)
			local TabBtn = Instance.new("TextButton")[span_1373](start_span)[span_1373](end_span)
			TabBtn.Name = tabName[span_1374](start_span)[span_1374](end_span)
			TabBtn.LayoutOrder = i[span_1375](start_span)[span_1375](end_span)
			TabBtn.Size = UDim2.new(1 / #allTabs, -4, 1, 0)[span_1376](start_span)[span_1376](end_span)
			TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_1377](start_span)[span_1377](end_span)
			TabBtn.BorderSizePixel = 0[span_1378](start_span)[span_1378](end_span)
			TabBtn.Text = "[span_1379](start_span)"[span_1379](end_span)
			TabBtn.AutoButtonColor = false[span_1380](start_span)[span_1380](end_span)
			TabBtn.ClipsDescendants = true[span_1381](start_span)[span_1381](end_span)
			TabBtn.Parent = TabsHolder[span_1382](start_span)[span_1382](end_span)

			local tabBaseGrad = Instance.new("UIGradient")[span_1383](start_span)[span_1383](end_span)
			tabBaseGrad.Color = ColorSequence.new({[span_1384](start_span)[span_1384](end_span)
				ColorSequenceKeypoint.new(0, THEME.CardBgTop),[span_1385](start_span)[span_1385](end_span)
				ColorSequenceKeypoint.new(1, THEME.CardBgBottom)[span_1386](start_span)[span_1386](end_span)
			})[span_1387](start_span)[span_1387](end_span)
			tabBaseGrad.Rotation = 90[span_1388](start_span)[span_1388](end_span)
			tabBaseGrad.Parent = TabBtn[span_1389](start_span)[span_1389](end_span)
			table.insert(ThemedRegistry.CardGradients, tabBaseGrad)[span_1390](start_span)[span_1390](end_span)

			local isInitial = (tabName == (windowObj.FirstTabName or "Settings"))[span_1391](start_span)[span_1391](end_span)

			local tabActiveOverlay = Instance.new("Frame")[span_1392](start_span)[span_1392](end_span)
			tabActiveOverlay.Size = UDim2.new(1, 0, 1, 0)[span_1393](start_span)[span_1393](end_span)
			tabActiveOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)[span_1394](start_span)[span_1394](end_span)
			tabActiveOverlay.BorderSizePixel = 0[span_1395](start_span)[span_1395](end_span)
			tabActiveOverlay.BackgroundTransparency = (isInitial and 0 or 1)[span_1396](start_span)[span_1396](end_span)
			tabActiveOverlay.ZIndex = 2[span_1397](start_span)[span_1397](end_span)
			tabActiveOverlay.Parent = TabBtn[span_1398](start_span)[span_1398](end_span)

			local tabActiveGrad = Instance.new("UIGradient")[span_1399](start_span)[span_1399](end_span)
			tabActiveGrad.Color = ColorSequence.new({[span_1400](start_span)[span_1400](end_span)
				ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 36, 58)),[span_1401](start_span)[span_1401](end_span)
				ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 20, 36))[span_1402](start_span)[span_1402](end_span)
			})[span_1403](start_span)[span_1403](end_span)
			tabActiveGrad.Rotation = 90[span_1404](start_span)[span_1404](end_span)
			tabActiveGrad.Parent = tabActiveOverlay[span_1405](start_span)[span_1405](end_span)
			table.insert(ThemedRegistry.TabActiveGradients, tabActiveGrad)[span_1406](start_span)[span_1406](end_span)

			local tabStroke = Instance.new("UIStroke")[span_1407](start_span)[span_1407](end_span)
			tabStroke.Color = (isInitial and THEME.BorderTabActive) or THEME.BorderCard[span_1408](start_span)[span_1408](end_span)
			tabStroke.Thickness = 1[span_1409](start_span)[span_1409](end_span)
			tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border[span_1410](start_span)[span_1410](end_span)
			tabStroke.Parent = TabBtn[span_1411](start_span)[span_1411](end_span)

			local activeHighlight = Instance.new("Frame")[span_1412](start_span)[span_1412](end_span)
			activeHighlight.AnchorPoint = Vector2.new(0.5, 0)[span_1413](start_span)[span_1413](end_span)
			activeHighlight.Position = UDim2.new(0.5, 0, 0, 0)[span_1414](start_span)[span_1414](end_span)
			activeHighlight.Size = (isInitial and UDim2.new(1, 0, 0, 1)) or UDim2.new(0, 0, 0, 1)[span_1415](start_span)[span_1415](end_span)
			activeHighlight.BackgroundColor3 = THEME.AccentLilacLight[span_1416](start_span)[span_1416](end_span)
			activeHighlight.BorderSizePixel = 0[span_1417](start_span)[span_1417](end_span)
			activeHighlight.BackgroundTransparency = (isInitial and 0 or 1)[span_1418](start_span)[span_1418](end_span)
			activeHighlight.ZIndex = 5[span_1419](start_span)[span_1419](end_span)
			activeHighlight.Parent = TabBtn[span_1420](start_span)[span_1420](end_span)
			table.insert(ThemedRegistry.AccentHighlights, activeHighlight)[span_1421](start_span)[span_1421](end_span)

			local tabLabel = Instance.new("TextLabel")[span_1422](start_span)[span_1422](end_span)
			tabLabel.Text = tabName[span_1423](start_span)[span_1423](end_span)
			tabLabel.Font = FONT[span_1424](start_span)[span_1424](end_span)
			tabLabel.TextSize = 13[span_1425](start_span)[span_1425](end_span)
			tabLabel.TextColor3 = (isInitial and THEME.TextPrimary) or THEME.TextSecondary[span_1426](start_span)[span_1426](end_span)
			tabLabel.BackgroundTransparency = 1[span_1427](start_span)[span_1427](end_span)
			tabLabel.Size = UDim2.new(1, 0, 1, 0)[span_1428](start_span)[span_1428](end_span)
			tabLabel.ZIndex = 4[span_1429](start_span)[span_1429](end_span)
			tabLabel.Parent = TabBtn[span_1430](start_span)[span_1430](end_span)

			applyFontToObject(tabLabel)[span_1431](start_span)[span_1431](end_span)

			TabButtons[tabName] = {[span_1432](start_span)[span_1432](end_span)
				Button = TabBtn,[span_1433](start_span)[span_1433](end_span)
				ActiveOverlay = tabActiveOverlay,[span_1434](start_span)[span_1434](end_span)
				Stroke = tabStroke,[span_1435](start_span)[span_1435](end_span)
				Highlight = activeHighlight,[span_1436](start_span)[span_1436](end_span)
				Label = tabLabel[span_1437](start_span)[span_1437](end_span)
			}[span_1438](start_span)[span_1438](end_span)

			TabBtn.MouseButton1Click:Connect(function()[span_1439](start_span)[span_1439](end_span)
				switchTab(tabName)[span_1440](start_span)[span_1440](end_span)
			end)[span_1441](start_span)[span_1441](end_span)
		end[span_1442](start_span)[span_1442](end_span)
	end[span_1443](start_span)[span_1443](end_span)

	setupSettingsTab()[span_1444](start_span)[span_1444](end_span)
	rebuildTabButtons()[span_1445](start_span)[span_1445](end_span)

	function windowObj:CreateTab(tabName)[span_1446](start_span)[span_1446](end_span)
		assert(self.CreatedTabsCount < 4, "Maximum 4 custom tabs are allowed (5th tab is always Settings).")[span_1447](start_span)[span_1447](end_span)
		self.CreatedTabsCount = self.CreatedTabsCount + 1[span_1448](start_span)[span_1448](end_span)
		table.insert(self.Tabs, tabName)[span_1449](start_span)[span_1449](end_span)

		if not self.FirstTabName then[span_1450](start_span)[span_1450](end_span)
			self.FirstTabName = tabName[span_1451](start_span)[span_1451](end_span)
		end[span_1452](start_span)[span_1452](end_span)

		local tabPage = Instance.new("Frame")[span_1453](start_span)[span_1453](end_span)
		tabPage.Name = tabName .. "Page[span_1454](start_span)"[span_1454](end_span)
		tabPage.BackgroundTransparency = 1[span_1455](start_span)[span_1455](end_span)
		tabPage.Size = UDim2.new(1, 0, 1, 0)[span_1456](start_span)[span_1456](end_span)
		tabPage.Visible = (self.FirstTabName == tabName)[span_1457](start_span)[span_1457](end_span)
		tabPage.ClipsDescendants = false[span_1458](start_span)[span_1458](end_span)
		tabPage.Parent = ContentArea[span_1459](start_span)[span_1459](end_span)
		TabPages[tabName] = tabPage[span_1460](start_span)[span_1460](end_span)

		TabSubConfig[tabName] = {}[span_1461](start_span)[span_1461](end_span)
		savedSubTabs[tabName] = 1[span_1462](start_span)[span_1462](end_span)

		local tabObj = {[span_1463](start_span)[span_1463](end_span)
			Name = tabName,[span_1464](start_span)[span_1464](end_span)
			Page = tabPage,[span_1465](start_span)[span_1465](end_span)
			SubCount = 0,[span_1466](start_span)[span_1466](end_span)
			SubPages = {}[span_1467](start_span)[span_1467](end_span)
		}[span_1468](start_span)[span_1468](end_span)

		function tabObj:CreateSubTab(subCfg)[span_1469](start_span)[span_1469](end_span)
			subCfg = subCfg or {}[span_1470](start_span)[span_1470](end_span)
			self.SubCount = self.SubCount + 1[span_1471](start_span)[span_1471](end_span)
			local subIdx = self.SubCount[span_1472](start_span)[span_1472](end_span)
			assert(subIdx <= 2, "A maximum of 2 subtabs/icons can be created per tab.")[span_1473](start_span)[span_1473](end_span)

			local subPage = Instance.new("Frame")[span_1474](start_span)[span_1474](end_span)
			subPage.Name = tabName .. "SubPage" .. subIdx[span_1475](start_span)[span_1475](end_span)
			subPage.BackgroundTransparency = 1[span_1476](start_span)[span_1476](end_span)
			subPage.Size = UDim2.new(1, 0, 1, 0)[span_1477](start_span)[span_1477](end_span)
			subPage.Visible = (subIdx == 1)[span_1478](start_span)[span_1478](end_span)
			subPage.Parent = tabPage[span_1479](start_span)[span_1479](end_span)

			local leftCol, rightCol = createTabColumns(subPage)[span_1480](start_span)[span_1480](end_span)

			local iconImgStr = "[span_1481](start_span)"[span_1481](end_span)
			if subCfg.Icon and (subCfg.Icon:find("http") or subCfg.Icon:find("rbxassetid")) then[span_1482](start_span)[span_1482](end_span)
				iconImgStr = getIcon(subCfg.Icon, subCfg.IconFileName)[span_1483](start_span)[span_1483](end_span)
			end[span_1484](start_span)[span_1484](end_span)

			local subEntry = {[span_1485](start_span)[span_1485](end_span)
				iconText = subCfg.IconText or (iconImgStr == "" and (subCfg.Icon or "❖")) or "",[span_1486](start_span)[span_1486](end_span)
				iconImg = iconImgStr,[span_1487](start_span)[span_1487](end_span)
				sizeActive = subCfg.ActiveSize or 18,[span_1488](start_span)[span_1488](end_span)
				sizeInactive = subCfg.InactiveSize or 15,[span_1489](start_span)[span_1489](end_span)
				page = subPage[span_1490](start_span)[span_1490](end_span)
			}[span_1491](start_span)[span_1491](end_span)

			table.insert(TabSubConfig[tabName], subEntry)[span_1492](start_span)[span_1492](end_span)

			local subTabObj = {[span_1493](start_span)[span_1493](end_span)
				Page = subPage,[span_1494](start_span)[span_1494](end_span)
				Left = leftCol,[span_1495](start_span)[span_1495](end_span)
				Right = rightCol[span_1496](start_span)[span_1496](end_span)
			}[span_1497](start_span)[span_1497](end_span)

			local function getColumn(side)[span_1498](start_span)[span_1498](end_span)
				if side == "Right" or side == 2 then return rightCol end[span_1499](start_span)[span_1499](end_span)
				return leftCol[span_1500](start_span)[span_1500](end_span)
			end[span_1501](start_span)[span_1501](end_span)

			function subTabObj:CreateCard(side, cardTitle, sizeY)[span_1502](start_span)[span_1502](end_span)
				local col = getColumn(side)[span_1503](start_span)[span_1503](end_span)
				local _, content = createSectionCard(col, cardTitle, sizeY, 1)[span_1504](start_span)[span_1504](end_span)

				local cardObj = {[span_1505](start_span)[span_1505](end_span)
					Container = content[span_1506](start_span)[span_1506](end_span)
				}[span_1507](start_span)[span_1507](end_span)

				function cardObj:AddToggle(opt)[span_1508](start_span)[span_1508](end_span)
					return createToggle(content, opt.Name or "Toggle", opt.Default, opt.Type, opt.Callback, opt.Flag)[span_1509](start_span)[span_1509](end_span)
				end[span_1510](start_span)[span_1510](end_span)

				function cardObj:AddSlider(opt)[span_1511](start_span)[span_1511](end_span)
					return createCompactSlider([span_1512](start_span)[span_1512](end_span)
						content,[span_1513](start_span)[span_1513](end_span)
						opt.Name or "Slider",[span_1514](start_span)[span_1514](end_span)
						opt.Default or opt.Min or 0,[span_1515](start_span)[span_1515](end_span)
						opt.Min or 0,[span_1516](start_span)[span_1516](end_span)
						opt.Max or 100,[span_1517](start_span)[span_1517](end_span)
						opt.Callback,[span_1518](start_span)[span_1518](end_span)
						opt.Flag,[span_1519](start_span)[span_1519](end_span)
						opt.Precise or opt.Decimals or 0[span_1520](start_span)[span_1520](end_span)
					)[span_1521](start_span)[span_1521](end_span)
				end[span_1522](start_span)[span_1522](end_span)

				function cardObj:AddKeybind(opt)[span_1523](start_span)[span_1523](end_span)
					return createKeybind([span_1524](start_span)[span_1524](end_span)
						content,[span_1525](start_span)[span_1525](end_span)
						opt.Name or "Keybind",[span_1526](start_span)[span_1526](end_span)
						opt.Default or Enum.KeyCode.Unknown,[span_1527](start_span)[span_1527](end_span)
						opt.Callback,[span_1528](start_span)[span_1528](end_span)
						opt.Flag,[span_1529](start_span)[span_1529](end_span)
						opt.OnKeyChanged[span_1530](start_span)[span_1530](end_span)
					)[span_1531](start_span)[span_1531](end_span)
				end[span_1532](start_span)[span_1532](end_span)

				function cardObj:AddDropdown(opt)[span_1533](start_span)[span_1533](end_span)
					return createDropdown(content, opt.Name or "Dropdown", opt.Default or opt.Options[1], opt.Options or {}, opt.ZIndex or 20, opt.Callback, opt.Flag)[span_1534](start_span)[span_1534](end_span)
				end[span_1535](start_span)[span_1535](end_span)

				function cardObj:AddMultiDropdown(opt)[span_1536](start_span)[span_1536](end_span)
					return createMultiDropdown(content, opt.Name or "MultiDropdown", opt.Default or {}, opt.Options or {}, opt.ZIndex or 20, opt.Callback, opt.Flag)[span_1537](start_span)[span_1537](end_span)
				end[span_1538](start_span)[span_1538](end_span)

				function cardObj:AddInput(opt)[span_1539](start_span)[span_1539](end_span)
					return createInput(content, opt.Name or "Input", opt.Placeholder, opt.Default, opt.Callback, opt.Flag)[span_1540](start_span)[span_1540](end_span)
				end[span_1541](start_span)[span_1541](end_span)

				function cardObj:AddColorPicker(opt)[span_1542](start_span)[span_1542](end_span)
					return createColorPickerRow(content, opt.Name or "Color", opt.Default, opt.Callback, opt.Flag)[span_1543](start_span)[span_1543](end_span)
				end[span_1544](start_span)[span_1544](end_span)

				function cardObj:AddButton(opt)[span_1545](start_span)[span_1545](end_span)
					return createActionButton(content, opt.Name or "Button", opt.Callback)[span_1546](start_span)[span_1546](end_span)
				end[span_1547](start_span)[span_1547](end_span)

				function cardObj:AddDualButtons(opt)[span_1548](start_span)[span_1548](end_span)
					return createDualActionButtons(content, opt.Text1 or "Button 1", opt.Callback1, opt.Text2 or "Button 2", opt.Callback2)[span_1549](start_span)[span_1549](end_span)
				end[span_1550](start_span)[span_1550](end_span)

				function cardObj:AddPlayerList(opt)[span_1551](start_span)[span_1551](end_span)
					return createPlayerList(content, opt.Title or "Players", opt.SizeY or 300, opt.Elements, {[span_1552](start_span)[span_1552](end_span)
						TeamFilter = opt.TeamFilter or "All",[span_1553](start_span)[span_1553](end_span)
						Filter = opt.Filter[span_1554](start_span)[span_1554](end_span)
					})[span_1555](start_span)[span_1555](end_span)
				end[span_1556](start_span)[span_1556](end_span)

				return cardObj[span_1557](start_span)[span_1557](end_span)
			end[span_1558](start_span)[span_1558](end_span)

			function subTabObj:CreatePlayerList(side, opt)[span_1559](start_span)[span_1559](end_span)
				local col = getColumn(side)[span_1560](start_span)[span_1560](end_span)
				return createPlayerList(col, opt.Title or "Players", opt.SizeY or 300, opt.Elements, {[span_1561](start_span)[span_1561](end_span)
					TeamFilter = opt.TeamFilter or "All",[span_1562](start_span)[span_1562](end_span)
					Filter = opt.Filter[span_1563](start_span)[span_1563](end_span)
				})[span_1564](start_span)[span_1564](end_span)
			end[span_1565](start_span)[span_1565](end_span)

			for _, obj in ipairs(subPage:GetDescendants()) do[span_1566](start_span)[span_1566](end_span)
				applyFontToObject(obj)[span_1567](start_span)[span_1567](end_span)
			end[span_1568](start_span)[span_1568](end_span)

			return subTabObj[span_1569](start_span)[span_1569](end_span)
		end[span_1570](start_span)[span_1570](end_span)

		rebuildTabButtons()[span_1571](start_span)[span_1571](end_span)
		if self.CreatedTabsCount == 1 then[span_1572](start_span)[span_1572](end_span)
			switchTab(tabName)[span_1573](start_span)[span_1573](end_span)
		end[span_1574](start_span)[span_1574](end_span)

		for _, obj in ipairs(tabPage:GetDescendants()) do[span_1575](start_span)[span_1575](end_span)
			applyFontToObject(obj)[span_1576](start_span)[span_1576](end_span)
		end[span_1577](start_span)[span_1577](end_span)

		return tabObj[span_1578](start_span)[span_1578](end_span)
	end[span_1579](start_span)[span_1579](end_span)

	applyGlobalFont(ScreenGui, "Tahoma")[span_1580](start_span)[span_1580](end_span)
	applyAccentColor(defaultAccent)[span_1581](start_span)[span_1581](end_span)

	return windowObj[span_1582](start_span)[span_1582](end_span)
end[span_1583](start_span)[span_1583](end_span)

return Library[span_1584](start_span)[span_1584](end_span)
