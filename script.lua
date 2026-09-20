-- ============================================================
--  MODERN SETTINGS v2 — for your own Roblox Studio game
--  Features:
--    • Sidebar nav with icons + smooth transitions
--    • Light / Dark theme switch
--    • Profile presets (Default / Custom / Minimal)
--    • Keyboard shortcuts (Ctrl+1..4, Ctrl+Shift+R)
--    • Tooltips on hover
--    • Toast notifications + confirm dialog
--    • Search with live filtering
--    • Persistent settings + last tab via DataStore
--    • Draggable, minimizable, animated
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

local player = Players.LocalPlayer

-- ============================================================
--  PALETTES (theme aware)
-- ============================================================
local THEMES = {
	dark = {
		bg        = Color3.fromRGB(18, 18, 24),
		panel     = Color3.fromRGB(26, 26, 34),
		panelAlt  = Color3.fromRGB(36, 36, 46),
		row       = Color3.fromRGB(30, 30, 40),
		rowStroke = Color3.fromRGB(52, 52, 66),
		accent    = Color3.fromRGB(96, 140, 255),
		accentDim = Color3.fromRGB(64, 96, 190),
		text      = Color3.fromRGB(240, 240, 248),
		textDim   = Color3.fromRGB(150, 150, 168),
		danger    = Color3.fromRGB(230, 78, 78),
		success   = Color3.fromRGB(80, 210, 130),
		track     = Color3.fromRGB(52, 52, 66),
	},
	light = {
		bg        = Color3.fromRGB(245, 246, 250),
		panel     = Color3.fromRGB(255, 255, 255),
		panelAlt  = Color3.fromRGB(236, 238, 245),
		row       = Color3.fromRGB(250, 250, 253),
		rowStroke = Color3.fromRGB(220, 222, 232),
		accent    = Color3.fromRGB(70, 110, 240),
		accentDim = Color3.fromRGB(50, 80, 190),
		text      = Color3.fromRGB(28, 28, 38),
		textDim   = Color3.fromRGB(120, 120, 140),
		danger    = Color3.fromRGB(210, 60, 60),
		success   = Color3.fromRGB(50, 180, 110),
		track     = Color3.fromRGB(220, 222, 232),
	},
}

local C = {} -- active palette (mutated by theme switch)

-- ============================================================
--  DEFAULTS & PROFILES
-- ============================================================
local PROFILES = {
	Default = {
		Movement = { Speed = 16, JumpPower = 50, Gravity = 196.2 },
		Combat   = { Damage = 10, FireRate = 1, AutoAim = false },
		Visual   = { FOV = 70, Brightness = 1, Sensitivity = 1 },
		Misc     = { Sound = true, Music = true, UIScale = 1 },
	},
	Minimal = {
		Movement = { Speed = 12, JumpPower = 40, Gravity = 196.2 },
		Combat   = { Damage = 5, FireRate = 0.8, AutoAim = false },
		Visual   = { FOV = 65, Brightness = 0.9, Sensitivity = 0.8 },
		Misc     = { Sound = false, Music = false, UIScale = 1 },
	},
	Performance = {
		Movement = { Speed = 20, JumpPower = 60, Gravity = 200 },
		Combat   = { Damage = 15, FireRate = 1.2, AutoAim = false },
		Visual   = { FOV = 80, Brightness = 1, Sensitivity = 1.2 },
		Misc     = { Sound = true, Music = false, UIScale = 0.9 },
	},
}

local DEFAULTS = PROFILES.Default
local currentProfile = "Default"
local currentTheme = "dark"

local function deepCopy(t)
	local c = {}
	for k, v in pairs(t) do c[k] = type(v) == "table" and deepCopy(v) or v end
	return c
end

local settings = deepCopy(DEFAULTS)
local lastTab = "Movement"

-- ============================================================
--  DATA STORE
-- ============================================================
local store = DataStoreService:GetDataStore("ModernSettings_v2")
local STORE_KEY = "player_" .. player.UserId

local ok, data = pcall(function() return store:GetAsync(STORE_KEY) end)
if ok and type(data) == "table" then
	if data.Settings then
		for cat, vals in pairs(data.Settings) do
			if settings[cat] then
				for k, v in pairs(vals) do settings[cat][k] = v end
			end
		end
	end
	if type(data.LastTab) == "string" then lastTab = data.LastTab end
	if type(data.Theme) == "string" and THEMES[data.Theme] then currentTheme = data.Theme end
	if type(data.Profile) == "string" and PROFILES[data.Profile] then currentProfile = data.Profile end
end

local saveQueued = false
local function saveData()
	if saveQueued then return end
	saveQueued = true
	task.delay(2, function()
		saveQueued = false
		pcall(function()
			store:SetAsync(STORE_KEY, {
				Settings = settings,
				LastTab  = lastTab,
				Theme    = currentTheme,
				Profile  = currentProfile,
			})
		end)
	end)
end

-- ============================================================
--  UTILITIES
-- ============================================================
local function tween(obj, props, time, style, dir)
	return TweenService:Create(
		obj,
		TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	):Play()
end

-- ============================================================
--  GUI ROOT
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ModernSettingsV2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- ============================================================
--  TOASTS
-- ============================================================
local toastHolder = Instance.new("Frame")
toastHolder.Size = UDim2.new(0, 340, 1, 0)
toastHolder.Position = UDim2.new(1, -360, 0, 0)
toastHolder.BackgroundTransparency = 1
toastHolder.ZIndex = 50
toastHolder.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.Padding = UDim.new(0, 8)
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastHolder

local toastPad = Instance.new("UIPadding")
toastPad.PaddingBottom = UDim.new(0, 20)
toastPad.PaddingRight  = UDim.new(0, 20)
toastPad.Parent = toastHolder

local function toast(text, colorKey)
	local color = C[colorKey or "accent"] or C.accent
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 50)
	frame.BackgroundColor3 = C.panel
	frame.BorderSizePixel = 0
	frame.ZIndex = 60
	frame.Parent = toastHolder

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = color
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3

	local bar = Instance.new("Frame", frame)
	bar.Size = UDim2.new(0, 4, 1, -12)
	bar.Position = UDim2.new(0, 6, 0, 6)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0

	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local lbl = Instance.new("TextLabel", frame)
	lbl.Size = UDim2.new(1, -30, 1, 0)
	lbl.Position = UDim2.new(0, 20, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = C.text
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 14
	lbl.TextXAlignment = Enum.TextXAlignment.Left

	frame.Position = UDim2.new(1, 20, 0, 0)
	tween(frame, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)

	task.delay(2.6, function()
		tween(frame, { Position = UDim2.new(1, 20, 0, 0), BackgroundTransparency = 1 }, 0.25)
		task.wait(0.3)
		frame:Destroy()
	end)
end

-- ============================================================
--  CONFIRM DIALOG
-- ============================================================
local function confirm(titleText, bodyText, onConfirm)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.ZIndex = 100
	overlay.Parent = gui

	tween(overlay, { BackgroundTransparency = 0.5 }, 0.2)

	local box = Instance.new("Frame")
	box.Size = UDim2.new(0, 340, 0, 160)
	box.Position = UDim2.new(0.5, -170, 0.5, -80)
	box.BackgroundColor3 = C.panel
	box.BorderSizePixel = 0
	box.ZIndex = 101
	box.Parent = overlay

	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", box)
	stroke.Color = C.rowStroke
	stroke.Thickness = 1

	local t = Instance.new("TextLabel", box)
	t.Size = UDim2.new(1, -24, 0, 30)
	t.Position = UDim2.new(0, 12, 0, 14)
	t.BackgroundTransparency = 1
	t.Text = titleText
	t.TextColor3 = C.text
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.TextXAlignment = Enum.TextXAlignment.Left

	local b = Instance.new("TextLabel", box)
	b.Size = UDim2.new(1, -24, 0, 50)
	b.Position = UDim2.new(0, 12, 0, 48)
	b.BackgroundTransparency = 1
	b.Text = bodyText
	b.TextColor3 = C.textDim
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.TextYAlignment = Enum.TextYAlignment.Top

	local function mkBtn(txt, xPos, color, cb)
		local btn = Instance.new("TextButton", box)
		btn.Size = UDim2.new(0, 140, 0, 34)
		btn.Position = UDim2.new(0, xPos, 1, -50)
		btn.BackgroundColor3 = color
		btn.Text = txt
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 13
		btn.AutoButtonColor = false
		btn.ZIndex = 102
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

		btn.MouseEnter:Connect(function() tween(btn, { BackgroundTransparency = -0.1 }, 0.12) end)
		btn.MouseLeave:Connect(function() tween(btn, { BackgroundTransparency = 0 }, 0.12) end)
		btn.MouseButton1Click:Connect(cb)
		return btn
	end

	local function close()
		tween(overlay, { BackgroundTransparency = 1 }, 0.15)
		tween(box, { Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0) }, 0.15)
		task.wait(0.18)
		overlay:Destroy()
	end

	mkBtn("Cancel", 16, C.rowStroke, close)
	mkBtn("Confirm", 184, C.danger, function()
		close()
		if onConfirm then onConfirm() end
	end)
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 700, 0, 450)
main.Position = UDim2.new(0.5, -350, 0.5, -225)
main.BackgroundColor3 = THEMES[currentTheme].bg
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = Color3.fromRGB(60, 60, 75)
mainStroke.Thickness = 1

-- Soft drop shadow
local shadow = Instance.new("ImageLabel", main)
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 10)
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5028857084"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.55
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(24, 24, 276, 276)
shadow.ZIndex = -1

-- ============================================================
--  TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame", main)
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundColor3 = THEMES[currentTheme].panel
titleBar.BorderSizePixel = 0

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleFix = Instance.new("Frame", titleBar)
titleFix.Size = UDim2.new(1, 0, 0, 14)
titleFix.Position = UDim2.new(0, 0, 1, -14)
titleFix.BackgroundColor3 = THEMES[currentTheme].panel
titleFix.BorderSizePixel = 0

local logoDot = Instance.new("Frame", titleBar)
logoDot.Size = UDim2.new(0, 10, 0, 10)
logoDot.Position = UDim2.new(0, 18, 0.5, -5)
logoDot.BackgroundColor3 = THEMES[currentTheme].accent
logoDot.BorderSizePixel = 0
Instance.new("UICorner", logoDot).CornerRadius = UDim.new(1, 0)

local logoGlow = Instance.new("ImageLabel", titleBar)
logoGlow.Size = UDim2.new(0, 26, 0, 26)
logoGlow.Position = UDim2.new(0, 10, 0.5, -13)
logoGlow.BackgroundTransparency = 1
logoGlow.Image = "rbxassetid://5028857084"
logoGlow.ImageColor3 = THEMES[currentTheme].accent
logoGlow.ImageTransparency = 0.45

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.Position = UDim2.new(0, 38, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Settings"
titleLabel.TextColor3 = THEMES[currentTheme].text
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local versionBadge = Instance.new("TextLabel", titleBar)
versionBadge.Size = UDim2.new(0, 44, 0, 18)
versionBadge.Position = UDim2.new(0, 110, 0.5, -9)
versionBadge.BackgroundColor3 = THEMES[currentTheme].panelAlt
versionBadge.Text = "v2.0"
versionBadge.TextColor3 = THEMES[currentTheme].accent
versionBadge.Font = Enum.Font.GothamBold
versionBadge.TextSize = 11
Instance.new("UICorner", versionBadge).CornerRadius = UDim.new(0, 5)

local profileBadge = Instance.new("TextLabel", titleBar)
profileBadge.Size = UDim2.new(0, 110, 0, 18)
profileBadge.Position = UDim2.new(0, 160, 0.5, -9)
profileBadge.BackgroundColor3 = THEMES[currentTheme].panelAlt
profileBadge.Text = "· " .. currentProfile
profileBadge.TextColor3 = THEMES[currentTheme].textDim
profileBadge.Font = Enum.Font.GothamMedium
profileBadge.TextSize = 11
Instance.new("UICorner", profileBadge).CornerRadius = UDim.new(0, 5)

-- Window buttons
local function windowBtn(icon, colorKey, xOff, tip, cb)
	local btn = Instance.new("TextButton", titleBar)
	btn.Size = UDim2.new(0, 30, 0, 30)
	btn.Position = UDim2.new(1, xOff, 0.5, -15)
	btn.BackgroundColor3 = THEMES[currentTheme].panelAlt
	btn.Text = icon
	btn.TextColor3 = THEMES[currentTheme].textDim
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = THEMES[currentTheme][colorKey], TextColor3 = Color3.new(1, 1, 1) }, 0.15)
		showTooltip(btn, tip)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = THEMES[currentTheme].panelAlt, TextColor3 = THEMES[currentTheme].textDim }, 0.15)
		hideTooltip()
	end)
	btn.MouseButton1Click:Connect(cb)
	return btn
end

local themeBtn
local minimizeBtn
local closeBtn

themeBtn = windowBtn("◐", "accent", -140, "Toggle theme (Ctrl+T)", function()
	currentTheme = currentTheme == "dark" and "light" or "dark"
	applyTheme()
	saveData()
	toast("Theme: " .. currentTheme, "accent")
end)

minimizeBtn = windowBtn("—", "accent", -104, "Minimize", function()
	local collapsed = main.Size.Y.Offset == 46
	local target = collapsed and UDim2.new(0, 700, 0, 450) or UDim2.new(0, 700, 0, 46)
	tween(main, { Size = target }, 0.28, Enum.EasingStyle.Quart)
end)

closeBtn = windowBtn("✕", "danger", -68, "Close (RightShift)", function()
	tween(main, { Size = UDim2.new(0, 700, 0, 0), BackgroundTransparency = 1 }, 0.22)
	task.wait(0.22)
	main.Visible = false
	main.BackgroundTransparency = 0
	main.Size = UDim2.new(0, 700, 0, 450)
end)

-- ============================================================
--  TOOLTIP
-- ============================================================
local tooltip
local function showTooltip(parentObj, text)
	if tooltip then tooltip:Destroy() end
	tooltip = Instance.new("TextLabel", gui)
	tooltip.Size = UDim2.new(0, 160, 0, 24)
	tooltip.Position = UDim2.new(0, parentObj.AbsolutePosition.X + parentObj.AbsoluteSize.X/2 - 80,
		0, parentObj.AbsolutePosition.Y + parentObj.AbsoluteSize.Y + 6)
	tooltip.BackgroundColor3 = THEMES[currentTheme].panelAlt
	tooltip.Text = text
	tooltip.TextColor3 = THEMES[currentTheme].text
	tooltip.Font = Enum.Font.Gotham
	tooltip.TextSize = 11
	tooltip.ZIndex = 40
	Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0, 6)
	tooltip.BackgroundTransparency = 1
	tooltip.TextTransparency = 1
	tween(tooltip, { BackgroundTransparency = 0, TextTransparency = 0 }, 0.15)
end
local function hideTooltip()
	if tooltip then
		local t = tooltip
		tooltip = nil
		tween(t, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.12)
		task.wait(0.13)
		t:Destroy()
	end
end

-- ============================================================
--  SIDEBAR
-- ============================================================
local sidebar = Instance.new("Frame", main)
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 190, 1, -46)
sidebar.Position = UDim2.new(0, 0, 0, 46)
sidebar.BackgroundColor3 = THEMES[currentTheme].panel
sidebar.BorderSizePixel = 0

local sidebarLayout = Instance.new("UIListLayout", sidebar)
sidebarLayout.Padding = UDim.new(0, 5)
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder

local sidebarPad = Instance.new("UIPadding", sidebar)
sidebarPad.PaddingTop = UDim.new(0, 14)
sidebarPad.PaddingLeft = UDim.new(0, 12)
sidebarPad.PaddingRight = UDim.new(0, 12)
sidebarPad.PaddingBottom = UDim.new(0, 56)

-- Search
local searchFrame = Instance.new("Frame", sidebar)
searchFrame.Size = UDim2.new(1, 0, 0, 32)
searchFrame.BackgroundColor3 = THEMES[currentTheme].panelAlt
searchFrame.BorderSizePixel = 0
searchFrame.LayoutOrder = -1
Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

local searchIcon = Instance.new("TextLabel", searchFrame)
searchIcon.Size = UDim2.new(0, 26, 1, 0)
searchIcon.Position = UDim2.new(0, 6, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextColor3 = THEMES[currentTheme].textDim
searchIcon.Font = Enum.Font.Gotham
searchIcon.TextSize = 12

local searchBox = Instance.new("TextBox", searchFrame)
searchBox.Size = UDim2.new(1, -34, 1, 0)
searchBox.Position = UDim2.new(0, 30, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "Search..."
searchBox.PlaceholderColor3 = THEMES[currentTheme].textDim
searchBox.TextColor3 = THEMES[currentTheme].text
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 13
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false

-- ============================================================
--  CONTENT AREA
-- ============================================================
local content = Instance.new("Frame", main)
content.Name = "Content"
content.Size = UDim2.new(1, -190, 1, -46)
content.Position = UDim2.new(0, 190, 0, 46)
content.BackgroundColor3 = THEMES[currentTheme].bg
content.BorderSizePixel = 0

local contentHeader = Instance.new("Frame", content)
contentHeader.Size = UDim2.new(1, -48, 0, 46)
contentHeader.Position = UDim2.new(0, 24, 0, 14)
contentHeader.BackgroundTransparency = 1

local contentTitle = Instance.new("TextLabel", contentHeader)
contentTitle.Size = UDim2.new(1, -100, 0, 24)
contentTitle.BackgroundTransparency = 1
contentTitle.Text = "Movement"
contentTitle.TextColor3 = THEMES[currentTheme].text
contentTitle.Font = Enum.Font.GothamBold
contentTitle.TextSize = 19
contentTitle.TextXAlignment = Enum.TextXAlignment.Left

local contentCount = Instance.new("TextLabel", contentHeader)
contentCount.Size = UDim2.new(0, 80, 0, 24)
contentCount.Position = UDim2.new(1, -80, 0, 0)
contentCount.BackgroundTransparency = 1
contentCount.Text = ""
contentCount.TextColor3 = THEMES[currentTheme].textDim
contentCount.Font = Enum.Font.GothamMedium
contentCount.TextSize = 12
contentCount.TextXAlignment = Enum.TextXAlignment.Right

local contentDesc = Instance.new("TextLabel", contentHeader)
contentDesc.Size = UDim2.new(1, 0, 0, 16)
contentDesc.Position = UDim2.new(0, 0, 0, 26)
contentDesc.BackgroundTransparency = 1
contentDesc.Text = ""
contentDesc.TextColor3 = THEMES[currentTheme].textDim
contentDesc.Font = Enum.Font.Gotham
contentDesc.TextSize = 12
contentDesc.TextXAlignment = Enum.TextXAlignment.Left

local divider = Instance.new("Frame", content)
divider.Size = UDim2.new(1, -48, 0, 1)
divider.Position = UDim2.new(0, 24, 0, 68)
divider.BackgroundColor3 = THEMES[currentTheme].rowStroke
divider.BorderSizePixel = 0

local scroll = Instance.new("ScrollingFrame", content)
scroll.Size = UDim2.new(1, -48, 1, -88)
scroll.Position = UDim2.new(0, 24, 0, 80)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = THEMES[currentTheme].accentDim
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local scrollLayout = Instance.new("UIListLayout", scroll)
scrollLayout.Padding = UDim.new(0, 10)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

local scrollPad = Instance.new("UIPadding", scroll)
scrollPad.PaddingBottom = UDim.new(0, 16)
scrollPad.PaddingRight  = UDim.new(0, 8)

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 16)
end)

-- ============================================================
--  WIDGET BUILDERS
-- ============================================================
local function clearContent()
	for _, ch in ipairs(scroll:GetChildren()) do
		if ch:IsA("Frame") or ch:IsA("TextButton") then ch:Destroy() end
	end
end

local function makeRow(order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 46)
	row.BackgroundColor3 = C.row
	row.BorderSizePixel = 0
	row.LayoutOrder = order or 0
	row.Parent = scroll
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke", row)
	s.Color = C.rowStroke
	s.Thickness = 1
	s.Transparency = 0.4
	return row
end

local function createToggle(parent, labelText, default, callback, order)
	local row = makeRow(order)
	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -90, 1, 0)
	label.Position = UDim2.new(0, 16, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = C.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left

	local sw = Instance.new("TextButton", row)
	sw.Size = UDim2.new(0, 46, 0, 24)
	sw.Position = UDim2.new(1, -62, 0.5, -12)
	sw.BackgroundColor3 = default and C.accent or C.track
	sw.Text = ""
	sw.AutoButtonColor = false
	Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", sw)
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local state = default
	sw.MouseButton1Click:Connect(function()
		state = not state
		tween(sw, { BackgroundColor3 = state and C.accent or C.track }, 0.15)
		tween(knob, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.15)
		callback(state)
	end)
end

local function createSlider(parent, labelText, min, max, default, callback, order)
	local row = makeRow(order)
	row.Size = UDim2.new(1, 0, 0, 58)

	local label = Instance.new("TextLabel", row)
	label.Size = UDim2.new(1, -100, 0, 20)
	label.Position = UDim2.new(0, 16, 0, 8)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = C.text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left

	local vLbl = Instance.new("TextLabel", row)
	vLbl.Size = UDim2.new(0, 70, 0, 20)
	vLbl.Position = UDim2.new(1, -86, 0, 8)
	vLbl.BackgroundTransparency = 1
	vLbl.Text = tostring(default)
	vLbl.TextColor3 = C.accent
	vLbl.Font = Enum.Font.GothamBold
	vLbl.TextSize = 13
	vLbl.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame", row)
	track.Size = UDim2.new(1, -32, 0, 6)
	track.Position = UDim2.new(0, 16, 0, 38)
	track.BackgroundColor3 = C.track
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local rel = math.clamp((default - min) / (max - min), 0, 1)

	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new(rel, 0, 1, 0)
	fill.BackgroundColor3 = C.accent
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", track)
	knob.Size = UDim2.new(0, 14, 0, 14)
	knob.Position = UDim2.new(rel, -7, 0.5, -7)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.BorderSizePixel = 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
	local ks = Instance.new("UIStroke", knob)
	ks.Color = C.accent
	ks.Thickness = 2

	local dragging = false

	local function updateFromX(x)
		local r = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = min + (max - min) * r
		if max - min <= 2 then value = math.floor(value * 100 + 0.5) / 100
		elseif max - min <= 20 then value = math.floor(value * 10 + 0.5) / 10
		else value = math.floor(value + 0.5) end
		fill.Size = UDim2.new(r, 0, 1, 0)
		knob.Position = UDim2.new(r, -7, 0.5, -7)
		vLbl.Text = tostring(value)
		callback(value)
	end

	local function startDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end

	knob.InputBegan:Connect(startDrag)
	track.InputBegan:Connect(startDrag)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- ============================================================
--  TAB CONFIG
-- ============================================================
local tabConfig = {
	{
		name = "Movement", icon = "🏃", key = Enum.KeyCode.One,
		description = "Character movement parameters.",
		items = {
			{ type = "slider", label = "Walk Speed", min = 0, max = 100, default = 16, key = "Speed" },
			{ type = "slider", label = "Jump Power", min = 0, max = 200, default = 50, key = "JumpPower" },
			{ type = "slider", label = "Gravity", min = 0, max = 500, default = 196.2, key = "Gravity" },
		},
	},
	{
		name = "Combat", icon = "⚔️", key = Enum.KeyCode.Two,
		description = "Weapon and combat parameters.",
		items = {
			{ type = "slider", label = "Damage", min = 0, max = 100, default = 10, key = "Damage" },
			{ type = "slider", label = "Fire Rate", min = 0.1, max = 5, default = 1, key = "FireRate" },
			{ type = "toggle", label = "Auto Aim (own game)", default = false, key = "AutoAim" },
		},
	},
	{
		name = "Visual", icon = "🎨", key = Enum.KeyCode.Three,
		description = "Camera and visual settings.",
		items = {
			{ type = "slider", label = "Field of View", min = 50, max = 120, default = 70, key = "FOV" },
			{ type = "slider", label = "Brightness", min = 0, max = 2, default = 1, key = "Brightness" },
			{ type = "slider", label = "Sensitivity", min = 0.1, max = 5, default = 1, key = "Sensitivity" },
		},
	},
	{
		name = "Misc", icon = "🧩", key = Enum.KeyCode.Four,
		description = "Sound, UI and others.",
		items = {
			{ type = "toggle", label = "Sound Effects", default = true, key = "Sound" },
			{ type = "toggle", label = "Music", default = true, key = "Music" },
			{ type = "slider", label = "UI Scale", min = 0.5, max = 2, default = 1, key = "UIScale" },
		},
	},
}

-- ============================================================
--  APPLY SETTING
-- ============================================================
local function applySetting(category, key, value)
	settings[category][key] = value

	if category == "Visual" and key == "FOV" then
		workspace.CurrentCamera.FieldOfView = value
	end

	local ev = game:GetService("ReplicatedStorage"):FindFirstChild("SettingsEvent")
	if ev then ev:FireServer(category, key, value) end

	saveData()
end

-- ============================================================
--  SIDEBAR BUTTONS
-- ============================================================
local tabButtons = {}
local activeTabButton = nil
local currentTabName = nil

local function setActiveButton(btn)
	if activeTabButton then
		local old = activeTabButton
		tween(old, { BackgroundColor3 = C.panel }, 0.15)
		local ind = old:FindFirstChild("Indicator")
		if ind then tween(ind, { BackgroundTransparency = 1, Size = UDim2.new(0, 3, 0, 0) }, 0.15) end
	end
	activeTabButton = btn
	tween(btn, { BackgroundColor3 = C.panelAlt }, 0.15)
	local ind = btn:FindFirstChild("Indicator")
	if ind then
		ind.BackgroundTransparency = 0
		ind.Size = UDim2.new(0, 3, 0, 0)
		tween(ind, { Size = UDim2.new(0, 3, 0, 26) }, 0.22, Enum.EasingStyle.Quart)
	end
end

local function createSidebarButton(name, icon, description, order)
	local btn = Instance.new("TextButton", sidebar)
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = C.panel
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local ind = Instance.new("Frame", btn)
	ind.Name = "Indicator"
	ind.Size = UDim2.new(0, 3, 0, 0)
	ind.Position = UDim2.new(0, 0, 0.5, -13)
	ind.BackgroundColor3 = C.accent
	ind.BorderSizePixel = 0
	ind.BackgroundTransparency = 1
	Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

	local iconL = Instance.new("TextLabel", btn)
	iconL.Size = UDim2.new(0, 26, 1, 0)
	iconL.Position = UDim2.new(0, 12, 0, 0)
	iconL.BackgroundTransparency = 1
	iconL.Text = icon
	iconL.TextColor3 = C.text
	iconL.Font = Enum.Font.GothamBold
	iconL.TextSize = 16

	local textL = Instance.new("TextLabel", btn)
	textL.Size = UDim2.new(1, -48, 1, 0)
	textL.Position = UDim2.new(0, 44, 0, 0)
	textL.BackgroundTransparency = 1
	textL.Text = name
	textL.TextColor3 = C.text
	textL.Font = Enum.Font.GothamMedium
	textL.TextSize = 14
	textL.TextXAlignment = Enum.TextXAlignment.Left

	local hint = Instance.new("TextLabel", btn)
	hint.Size = UDim2.new(0, 30, 1, 0)
	hint.Position = UDim2.new(1, -34, 0, 0)
	hint.BackgroundTransparency = 1
	hint.Text = "Ctrl+" .. order
	hint.TextColor3 = C.textDim
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 10
	hint.TextXAlignment = Enum.TextXAlignment.Right

	btn.MouseEnter:Connect(function()
		if btn ~= activeTabButton then
			tween(btn, { BackgroundColor3 = C.panelAlt }, 0.12)
		end
	end)
	btn.MouseLeave:Connect(function()
		if btn ~= activeTabButton then
			tween(btn, { BackgroundColor3 = C.panel }, 0.12)
		end
	end)

	tabButtons[name] = { btn = btn, description = description }
end

-- ============================================================
--  TAB RENDERING
-- ============================================================
local function renderTab(tabName, animated)
	local data = tabButtons[tabName]
	if not data then return end

	currentTabName = tabName
	lastTab = tabName
	saveData()

	setActiveButton(data.btn)
	contentTitle.Text = tabName
	contentDesc.Text = data.description or ""

	local filter = string.lower(searchBox.Text)
	local shown = 0
	clearContent()

	local cfg
	for _, t in ipairs(tabConfig) do
		if t.name == tabName then cfg = t break end
	end

	if cfg then
		for _, item in ipairs(cfg.items) do
			if filter == "" or string.find(string.lower(item.label), filter, 1, true) then
				shown += 1
				local currentValue = settings[tabName][item.key]
				if currentValue == nil then currentValue = item.default end

				if item.type == "toggle" then
					createToggle(scroll, item.label, currentValue, function(v)
						applySetting(tabName, item.key, v)
					end, shown)
				elseif item.type == "slider" then
					createSlider(scroll, item.label, item.min, item.max, currentValue, function(v)
						applySetting(tabName, item.key, v)
					end, shown)
				end
			end
		end
	end

	contentCount.Text = shown .. " / " .. (#cfg and #cfg.items or 0)

	if shown == 0 then
		local empty = Instance.new("TextLabel", scroll)
		empty.Size = UDim2.new(1, 0, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Text = "No settings found"
		empty.TextColor3 = C.textDim
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
	end

	if animated then
		for _, ch in ipairs(scroll:GetChildren()) do
			if ch:IsA("Frame") then
				ch.BackgroundTransparency = 1
				tween(ch, { BackgroundTransparency = 0 }, 0.2)
			end
		end
	end
end

-- Build sidebar
for i, tab in ipairs(tabConfig) do
	createSidebarButton(tab.name, tab.icon, tab.description, i)
end

-- Search live filter
searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	if currentTabName then renderTab(currentTabName, false) end
end)

-- ============================================================
--  BOTTOM BAR (profile + reset)
-- ============================================================
local bottomBar = Instance.new("Frame", sidebar)
bottomBar.Size = UDim2.new(1, 0, 0, 46)
bottomBar.Position = UDim2.new(0, 0, 1, -46)
bottomBar.BackgroundTransparency = 1

local profileBtn = Instance.new("TextButton", bottomBar)
profileBtn.Size = UDim2.new(0, 78, 0, 30)
profileBtn.Position = UDim2.new(0, 0, 0.5, -15)
profileBtn.BackgroundColor3 = C.panelAlt
profileBtn.Text = "Profile"
profileBtn.TextColor3 = C.textDim
profileBtn.Font = Enum.Font.GothamMedium
profileBtn.TextSize = 12
profileBtn.AutoButtonColor = false
Instance.new("UICorner", profileBtn).CornerRadius = UDim.new(0, 8)

profileBtn.MouseEnter:Connect(function() tween(profileBtn, { BackgroundColor3 = C.accent, TextColor3 = Color3.new(1,1,1) }, 0.15) end)
profileBtn.MouseLeave:Connect(function() tween(profileBtn, { BackgroundColor3 = C.panelAlt, TextColor3 = C.textDim }, 0.15) end)

-- Simple profile cycle
profileBtn.MouseButton1Click:Connect(function()
	local names = {}
	for k in pairs(PROFILES) do table.insert(names, k) end
	table.sort(names)
	local idx = table.find(names, currentProfile) or 1
	idx = idx % #names + 1
	currentProfile = names[idx]
	settings = deepCopy(PROFILES[currentProfile])
	profileBadge.Text = "· " .. currentProfile
	applyTheme() -- refresh colors after settings change
	if currentTabName then renderTab(currentTabName, true) end
	saveData()
	toast("Profile: " .. currentProfile, "success")
end)

local resetBtn = Instance.new("TextButton", bottomBar)
resetBtn.Size = UDim2.new(0, 84, 0, 30)
resetBtn.Position = UDim2.new(1, -84, 0.5, -15)
resetBtn.BackgroundColor3 = C.panelAlt
resetBtn.Text = "↺ Reset"
resetBtn.TextColor3 = C.textDim
resetBtn.Font = Enum.Font.GothamMedium
resetBtn.TextSize = 12
resetBtn.AutoButtonColor = false
Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 8)

resetBtn.MouseEnter:Connect(function() tween(resetBtn, { BackgroundColor3 = C.danger, TextColor3 = Color3.new(1,1,1) }, 0.15) end)
resetBtn.MouseLeave:Connect(function() tween(resetBtn, { BackgroundColor3 = C.panelAlt, TextColor3 = C.textDim }, 0.15) end)

resetBtn.MouseButton1Click:Connect(function()
	confirm("Reset settings?",
		"This will restore all settings in the current profile to their defaults. This action cannot be undone.",
		function()
			settings = deepCopy(DEFAULTS)
			saveData()
			if currentTabName then renderTab(currentTabName, true) end
			toast("Settings reset", "danger")
		end)
end)

-- ============================================================
--  THEME APPLY
-- ============================================================
function applyTheme()
	local t = THEMES[currentTheme]
	for k, v in pairs(t) do C[k] = v end

	main.BackgroundColor3        = t.bg
	titleBar.BackgroundColor3    = t.panel
	titleFix.BackgroundColor3    = t.panel
	sidebar.BackgroundColor3     = t.panel
	content.BackgroundColor3     = t.bg
	logoDot.BackgroundColor3     = t.accent
	logoGlow.ImageColor3         = t.accent
	titleLabel.TextColor3        = t.text
	versionBadge.BackgroundColor3= t.panelAlt
	versionBadge.TextColor3      = t.accent
	profileBadge.BackgroundColor3= t.panelAlt
	profileBadge.TextColor3      = t.textDim
	searchFrame.BackgroundColor3 = t.panelAlt
	searchIcon.TextColor3        = t.textDim
	searchBox.PlaceholderColor3  = t.textDim
	searchBox.TextColor3         = t.text
	contentTitle.TextColor3      = t.text
	contentCount.TextColor3      = t.textDim
	contentDesc.TextColor3       = t.textDim
	divider.BackgroundColor3     = t.rowStroke
	mainStroke.Color             = t.rowStroke

	for _, btn in ipairs(tabButtons and {} or {}) do end -- placeholder

	for name, data in pairs(tabButtons) do
		local btn = data.btn
		btn.BackgroundColor3 = (btn == activeTabButton) and t.panelAlt or t.panel
		local iconL = btn:FindFirstChildWhichIsA("TextLabel")
		local labels = {}
		for _, c in ipairs(btn:GetChildren()) do
			if c:IsA("TextLabel") then table.insert(labels, c) end
		end
		for _, l in ipairs(labels) do
			if l.Text ~= "Ctrl+1" and l.Text ~= "Ctrl+2" and l.Text ~= "Ctrl+3" and l.Text ~= "Ctrl+4" then
				l.TextColor3 = t.text
			else
				l.TextColor3 = t.textDim
			end
		end
		local ind = btn:FindFirstChild("Indicator")
		if ind then ind.BackgroundColor3 = t.accent end
	end

	-- Refresh widgets (rows use C values)
	if currentTabName then renderTab(currentTabName, false) end
end

-- ============================================================
--  DRAG WINDOW
-- ============================================================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = main.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
	or input.UserInputType == Enum.UserInputType.Touch) then
		local d = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
	or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ============================================================
--  HOTKEYS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		if main.Visible then
			main.Size = UDim2.new(0, 700, 0, 0)
			tween(main, { Size = UDim2.new(0, 700, 0, 450) }, 0.3, Enum.EasingStyle.Quart)
		end
		return
	end

	if not main.Visible then return end

	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
	or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
		for _, tab in ipairs(tabConfig) do
			if input.KeyCode == tab.key then
				renderTab(tab.name, true)
				return
			end
		end
		if input.KeyCode == Enum.KeyCode.T then
			currentTheme = currentTheme == "dark" and "light" or "dark"
			applyTheme()
			saveData()
			toast("Theme: " .. currentTheme, "accent")
		elseif input.KeyCode == Enum.KeyCode.R then
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
				settings = deepCopy(DEFAULTS)
				saveData()
				if currentTabName then renderTab(currentTabName, true) end
				toast("Quick reset", "danger")
			end
		end
	end
end)

-- ============================================================
--  INIT
-- ============================================================
for k, v in pairs(THEMES[currentTheme]) do C[k] = v end

task.defer(function()
	if not tabButtons[lastTab] then lastTab = tabConfig[1].name end
	renderTab(lastTab, true)

	main.Size = UDim2.new(0, 700, 0, 0)
	tween(main, { Size = UDim2.new(0, 700, 0, 450) }, 0.38, Enum.EasingStyle.Quart)

	task.wait(0.45)
	toast("Loaded · tab: " .. lastTab .. " · theme: " .. currentTheme, "success")
end)

-- Save on leave
game:BindToClose(function()
	pcall(function()
		store:SetAsync(STORE_KEY, {
			Settings = settings, LastTab = lastTab,
			Theme = currentTheme, Profile = currentProfile,
		})
	end)
end)
Players.PlayerRemoving:Connect(function(p)
	if p == player then
		pcall(function()
			store:SetAsync(STORE_KEY, {
				Settings = settings, LastTab = lastTab,
				Theme = currentTheme, Profile = currentProfile,
			})
		end)
	end
end)
