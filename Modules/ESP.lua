
-- Modules/ESP.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local espObjects = {}
local connections = {}

local function createESP(player)
	if player == Players.LocalPlayer then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESP_" .. player.Name
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Enabled = false

	local text = Instance.new("TextLabel")
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.fromRGB(255, 80, 80)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 14
	text.Text = player.Name
	text.Parent = billboard

	billboard.Parent = player.Character or player.CharacterAdded:Wait()
	espObjects[player] = billboard
end

-- Render loop to update positions
table.insert(connections, RunService.RenderStepped:Connect(function()
	for player, gui in pairs(espObjects) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			gui.Adornee = char.HumanoidRootPart
			gui.Enabled = true
		else
			gui.Enabled = false
		end
	end
end))

-- Player management
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(createESP, p)
end

table.insert(connections, Players.PlayerAdded:Connect(function(p)
	createESP(p)
	p.CharacterAdded:Connect(function()
		if espObjects[p] then
			espObjects[p].Parent = p.Character
		end
	end)
end))

table.insert(connections, Players.PlayerRemoving:Connect(function(p)
	if espObjects[p] then
		espObjects[p]:Destroy()
		espObjects[p] = nil
	end
end))

-- THE MAGIC: Return a cleanup function so the UI can turn it off
return function()
	for _, c in ipairs(connections) do c:Disconnect() end
	for _, gui in pairs(espObjects) do gui:Destroy() end
	espObjects = {}
	connections = {}
end
