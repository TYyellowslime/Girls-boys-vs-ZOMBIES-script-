-- LocalScript in StarterPlayer -> StarterPlayerScripts
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ===== SETTINGS STORAGE =====
local settings = {
	Movement = { Speed = 16, JumpPower = 50, Gravity = 196.2 },
	Combat   = { Damage = 10, FireRate = 1, AutoAim = false },
	Visual   = { FOV = 70, Brightness = 1, Sensitivity = 1 },
	Misc     = { Sound = true, Music = true, UIScale = 1 },
}

local function applySetting(category, key, value)
	settings[category][key] = value
	print(string.format("[Settings] %s.%s = %s", category, key, tostring(value)))

	-- To send to your own game's server:
	-- local ev = game:GetService("ReplicatedStorage"):FindFirstChild("SettingsEvent")
	-- if ev then ev:FireServer(category, key, value) end
end

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "ModernSettings"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 460, 0, 360)
main.Position = UDim2.new(0.5, -230, 0.5, -180)
main.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 42)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚙ Settings"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
end)

-- Tabs container
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, -20, 0, 34)
tabsFrame.Position = UDim2.new(0, 10, 0, 50)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = main

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 6)
tabsLayout.Parent = tabsFrame

-- Content area
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -100)
content.Position = UDim2.new(0, 10, 0, 90)
content.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.Parent = main

local contentCorner = Instance.new("UICorner")
contentCorner.CornerRadius = UDim.new(0, 8)
contentCorner.Parent = content

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 8)
contentPadding.PaddingBottom = UDim.new(0, 8)
contentPadding.PaddingLeft = UDim.new(0, 8)
contentPadding.PaddingRight = UDim.new(0, 8)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 8)
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = content

-- ===== HELPERS =====
local function clearContent()
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

local function createToggle(parent, labelText, default, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 68)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = btn

	local state = default
	btn.MouseButton1Click:Connect(function()
		state = not state
		btn.BackgroundColor3 = state and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(60, 60, 68)
		callback(state)
	end)
end

local function createSlider(parent, labelText, min, max, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 44)
	container.BackgroundTransparency = 1
	container.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.6, 0, 0, 18)
	label.Position = UDim2.new(0, 4, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(235, 235, 235)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.4, -4, 0, 18)
	valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(default)
	valueLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -8, 0, 6)
	track.Position = UDim2.new(0, 4, 0, 28)
	track.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
	track.BorderSizePixel = 0
	track.Parent = container

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local relative = (default - min) / (max - min)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(relative, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Position = UDim2.new(relative, -8, 0.5, -8)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.Text = ""
	knob.AutoButtonColor = false
	knob.Parent = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent = knob

	local dragging = false

	local function updateFromX(x)
		local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local value = min + (max - min) * rel
		value = math.floor(value * 100 + 0.5) / 100
		fill.Size = UDim2.new(rel, 0, 1, 0)
		knob.Position = UDim2.new(rel, -8, 0.5, -8)
		valueLabel.Text = tostring(value)
		callback(value)
	end

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

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

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			updateFromX(input.Position.X)
		end
	end)
end

-- ===== TAB CONFIG =====
local tabConfig = {
	{
		name = "Movement",
		items = {
			{ type = "slider", label = "Walk Speed", min = 0, max = 100, default = 16, key = "Speed" },
			{ type = "slider", label = "Jump Power", min = 0, max = 200, default = 50, key = "JumpPower" },
			{ type = "slider", label = "Gravity", min = 0, max = 500, default = 196.2, key = "Gravity" },
		},
	},
	{
		name = "Combat",
		items = {
			{ type = "slider", label = "Damage", min = 0, max = 100, default = 10, key = "Damage" },
			{ type = "slider", label = "Fire Rate", min = 0.1, max = 5, default = 1, key = "FireRate" },
			{ type = "toggle", label = "Auto Aim (own game)", default = false, key = "AutoAim" },
		},
	},
	{
		name = "Visual",
		items = {
			{ type = "slider", label = "Field of View", min = 50, max = 120, default = 70, key = "FOV" },
			{ type = "slider", label = "Brightness", min = 0, max = 2, default = 1, key = "Brightness" },
			{ type = "slider", label = "Sensitivity", min = 0.1, max = 5, default = 1, key = "Sensitivity" },
		},
	},
	{
		name = "Misc",
		items = {
			{ type = "toggle", label = "Sound Effects", default = true, key = "Sound" },
			{ type = "toggle", label = "Music", default = true, key = "Music" },
			{ type = "slider", label = "UI Scale", min = 0.5, max = 2, default = 1, key = "UIScale" },
		},
	},
}

local activeTabButton = nil

local function showTab(categoryName, items)
	clearContent()

	for _, item in ipairs(items) do
		local currentValue = settings[categoryName][item.key]
		if currentValue == nil then
			currentValue = item.default
		end

		if item.type == "toggle" then
			createToggle(content, item.label, currentValue, function(v)
				applySetting(categoryName, item.key, v)
			end)
		elseif item.type == "slider" then
			createSlider(content, item.label, item.min, item.max, currentValue, function(v)
				applySetting(categoryName, item.key, v)
			end)
		end
	end
end

local function createTabButton(name, items, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 100, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(220, 220, 220)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.LayoutOrder = order
	btn.Parent = tabsFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		if activeTabButton then
			activeTabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
		end
		activeTabButton = btn
		btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		showTab(name, items)
	end)

	return btn
end

for i, tab in ipairs(tabConfig) do
	createTabButton(tab.name, tab.items, i)
end

-- Open the first tab by default
if tabsFrame:GetChildren()[1] and tabsFrame:GetChildren()[1]:IsA("TextButton") then
	tabsFrame:GetChildren()[1].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	activeTabButton = tabsFrame:GetChildren()[1]
	showTab(tabConfig[1].name, tabConfig[1].items)
end

-- ===== TOGGLE MENU (RightShift) =====
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
	end
end)
