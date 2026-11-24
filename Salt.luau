--!strict
-- Luau UI Library v1.1

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Library = {}
Library.Theme = table.freeze({
	Background = Color3.fromRGB(15, 15, 20),
	Secondary = Color3.fromRGB(25, 25, 30),
	Accent = Color3.fromRGB(100, 220, 140),
	Text = Color3.fromRGB(240, 240, 245),
	SubText = Color3.fromRGB(150, 150, 160),
	Border = Color3.fromRGB(45, 45, 55),
    Close = Color3.fromRGB(255, 80, 80)
})

local function Create(className: string, props: {[string]: any}?, children: {Instance}?): any
	local inst = Instance.new(className)
	if props then
		for k, v in props do
			inst[k] = v
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	return inst
end

local Window = {}
Window.__index = Window

function Library:CreateWindow(config: {Title: string, Size: UDim2?})
	local self = setmetatable({}, Window)
	self.Size = config.Size or UDim2.new(0, 500, 0, 350)
	
	-- Re-execution check
	local guiParent = if gethui then gethui() else Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = guiParent:FindFirstChild("LuauUILib")
	if existing then
		existing:Destroy()
	end

	self.ScreenGui = Create("ScreenGui", {
		Name = "LuauUILib",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 9999,
		Parent = guiParent
	})

	self.Main = Create("Frame", {
		Name = "Main",
		Size = self.Size,
		Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Parent = self.ScreenGui
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIStroke", { Color = Library.Theme.Border, Thickness = 1 })
	})

	-- Title Bar
	self.TitleBar = Create("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundTransparency = 1,
		Parent = self.Main
	})

	local titleLbl = Create("TextLabel", {
		Text = config.Title,
		Size = UDim2.new(1, -80, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.TitleBar
	})

    -- Close Button
	local closeBtn = Create("TextButton", {
		Size = UDim2.new(0, 25, 0, 25),
		Position = UDim2.new(1, -30, 0, 5),
		BackgroundColor3 = Library.Theme.Close,
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = Library.Theme.Text,
		Parent = self.TitleBar
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })
    
    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)

    -- Minimize Button
	local minBtn = Create("TextButton", {
		Size = UDim2.new(0, 25, 0, 25),
		Position = UDim2.new(1, -60, 0, 5),
		BackgroundColor3 = Library.Theme.Secondary,
		Text = "-",
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = Library.Theme.Text,
		Parent = self.TitleBar
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 4) }) })

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(self.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = if minimized then UDim2.new(0, 500, 0, 35) else self.Size
        }):Play()
    end)

	-- Tab Container
	self.TabList = Create("Frame", {
		Name = "Tabs",
		Size = UDim2.new(0, 120, 1, -35),
		Position = UDim2.new(0, 0, 0, 35),
		BackgroundTransparency = 1,
		Parent = self.Main
	})

	-- Content Container
	self.Content = Create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -120, 1, -35),
		Position = UDim2.new(0, 120, 0, 35),
		BackgroundColor3 = Library.Theme.Secondary,
		BorderSizePixel = 0,
		Parent = self.Main
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 8) }) })
	
	-- Draggable Logic
	local dragging, dragStart, startPos
	self.TitleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = self.Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	self.Tabs = {}
	return self
end

function Window:CreateTab(name: string)
	local tab = { Elements = {} }
	
	local btn = Create("TextButton", {
		Name = name,
		Size = UDim2.new(1, -10, 0, 30),
		Position = UDim2.new(0, 5, 0, #self.Tabs * 35),
		BackgroundColor3 = Library.Theme.Accent,
		BackgroundTransparency = 1,
		Text = name,
		Font = Enum.Font.GothamSemibold,
		TextSize = 13,
		TextColor3 = Library.Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.TabList
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 10) })
	})
	
	local scroll = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, -20, 1, -20),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 1,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Library.Theme.Border,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
		Parent = self.Content
	}, { Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	
	table.insert(self.Tabs, tab)
	
	local function SelectTab()
		for _, t in self.Tabs do
			t.Content.Visible = false
			t.Button.BackgroundTransparency = 1
			t.Button.TextColor3 = Library.Theme.SubText
		end
		scroll.Visible = true
		btn.BackgroundTransparency = 0.8
		btn.TextColor3 = Library.Theme.Text
	end
	
	btn.MouseButton1Click:Connect(SelectTab)
	
	tab.Button = btn
	tab.Content = scroll
	tab.Window = self
	
	-- Auto-select first tab safely (fixes the Activated error)
	if #self.Tabs == 1 then
		SelectTab()
	end
	
	return tab
end

local function CreateElement(tab, height: number): Frame
	local f = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Library.Theme.Background,
		BorderSizePixel = 0,
		Parent = tab.Content
	}, { Create("UICorner", { CornerRadius = UDim.new(0, 6) }) })
	tab.Content.CanvasSize += UDim2.new(0, 0, 0, height + 8)
	return f
end

function Window:AddButton(tab, text: string, callback: () -> ())
	local frame = CreateElement(tab, 32)
	Create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Library.Theme.Accent,
		Parent = frame
	}).MouseButton1Click:Connect(function()
		task.spawn(callback)
	end)
end

function Window:AddToggle(tab, text: string, default: boolean, callback: (boolean) -> ())
	local frame = CreateElement(tab, 32)
	local state = default
	
	Create("TextLabel", {
		Size = UDim2.new(1, -50, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame
	})
	
	local btn = Create("TextButton", {
		Size = UDim2.new(0, 36, 0, 20),
		Position = UDim2.new(1, -46, 0.5, -10),
		BackgroundColor3 = if state then Library.Theme.Accent else Library.Theme.Border,
		Text = "",
		Parent = frame
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	
	local knob = Create("Frame", {
		Size = UDim2.new(0, 16, 0, 16),
		Position = if state then UDim2.new(1, -18, 0.5, -8) else UDim2.new(0, 2, 0.5, -8),
		BackgroundColor3 = Library.Theme.Text,
		Parent = btn
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	
	btn.MouseButton1Click:Connect(function()
		state = not state
		TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = if state then Library.Theme.Accent else Library.Theme.Border }):Play()
		TweenService:Create(knob, TweenInfo.new(0.15), { Position = if state then UDim2.new(1, -18, 0.5, -8) else UDim2.new(0, 2, 0.5, -8) }):Play()
		task.spawn(callback, state)
	end)
end

function Window:AddSlider(tab, text: string, min: number, max: number, default: number, callback: (number) -> ())
	local frame = CreateElement(tab, 45)
	
	Create("TextLabel", {
		Size = UDim2.new(0.7, 0, 0, 20),
		Position = UDim2.new(0, 10, 0, 5),
		BackgroundTransparency = 1,
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = Library.Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = frame
	})
	
	local valLbl = Create("TextLabel", {
		Size = UDim2.new(0.3, -10, 0, 20),
		Position = UDim2.new(0.7, 0, 0, 5),
		BackgroundTransparency = 1,
		Text = `{math.round(default)}`,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = Library.Theme.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = frame
	})
	
	local bar = Create("Frame", {
		Size = UDim2.new(1, -20, 0, 6),
		Position = UDim2.new(0, 10, 0, 30),
		BackgroundColor3 = Library.Theme.Border,
		Parent = frame
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	
	local fill = Create("Frame", {
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Library.Theme.Accent,
		Parent = bar
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	
	local hitbox = Create("TextButton", {
		Size = UDim2.new(1, 0, 3, 0),
		Position = UDim2.new(0, 0, 0, -6),
		BackgroundTransparency = 1,
		Text = "",
		Parent = bar
	})
	
	local sliding = false
	hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = true
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local relX = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local val = math.round(min + (max - min) * relX)
			fill.Size = UDim2.new(relX, 0, 1, 0)
			valLbl.Text = `{val}`
			task.spawn(callback, val)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
		end
	end)
end

return Library
