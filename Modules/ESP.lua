-- Modules/ESP.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Check if Drawing library exists
if not Drawing then
	warn("[ESP] Drawing library not found! Your executor does not support 2D ESP.")
	return function() end
end

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ESP_Cache = {}
local Connections = {}

-- Helper to create Drawing objects cleanly
local function CreateDrawing(className, properties)
	local obj = Drawing.new(className)
	for k, v in pairs(properties) do
		obj[k] = v
	end
	return obj
end

local function CreateESP(player)
	if player == LocalPlayer then return end
	if ESP_Cache[player] then return end

	local Box = CreateDrawing("Square", {
		Color = Color3.fromRGB(255, 80, 80),
		Thickness = 1.5,
		Filled = false,
		Transparency = 1,
		Visible = false
	})

	local Name = CreateDrawing("Text", {
		Color = Color3.fromRGB(255, 255, 255),
		Size = 14,
		Center = true,
		Outline = true,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Font = Drawing.Fonts.GothamBold,
		Visible = false
	})

	local Distance = CreateDrawing("Text", {
		Color = Color3.fromRGB(200, 200, 200),
		Size = 12,
		Center = true,
		Outline = true,
		OutlineColor = Color3.fromRGB(0, 0, 0),
		Font = Drawing.Fonts.Gotham,
		Visible = false
	})

	ESP_Cache[player] = {
		Box = Box,
		Name = Name,
		Distance = Distance
	}
end

local function RemoveESP(player)
	if ESP_Cache[player] then
		ESP_Cache[player].Box:Remove()
		ESP_Cache[player].Name:Remove()
		ESP_Cache[player].Distance:Remove()
		ESP_Cache[player] = nil
	end
end

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
	CreateESP(player)
end

-- Player Join/Leave
table.insert(Connections, Players.PlayerAdded:Connect(CreateESP))
table.insert(Connections, Players.PlayerRemoving:Connect(RemoveESP))

-- Main Render Loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
	if not Camera then
		Camera = Workspace.CurrentCamera
	end

	for player, esp in pairs(ESP_Cache) do
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			local head = character:FindFirstChild("Head")

			if humanoid and humanoid.Health > 0 and rootPart and head then
				-- Calculate 2D screen positions
				local headPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
				local rootPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 2.5, 0))
				
				if onScreen then
					local height = math.abs(headPos.Y - rootPos.Y)
					local width = height / 2
					local x = headPos.X - width / 2
					local y = headPos.Y

					-- Update Box
					esp.Box.Size = Vector2.new(width, height)
					esp.Box.Position = Vector2.new(x, y)
					esp.Box.Visible = true

					-- Update Name
					esp.Name.Text = player.Name
					esp.Name.Position = Vector2.new(headPos.X, y - 18)
					esp.Name.Visible = true

					-- Update Distance
					local dist = math.floor((rootPart.Position - Camera.CFrame.Position).Magnitude)
					esp.Distance.Text = tostring(dist) .. " studs"
					esp.Distance.Position = Vector2.new(headPos.X, y + height + 2)
					esp.Distance.Visible = true
				else
					esp.Box.Visible = false
					esp.Name.Visible = false
					esp.Distance.Visible = false
				end
			else
				esp.Box.Visible = false
				esp.Name.Visible = false
				esp.Distance.Visible = false
			end
		else
			esp.Box.Visible = false
			esp.Name.Visible = false
			esp.Distance.Visible = false
		end
	end
end))

-- Return the cleanup function so the UI loader can turn it off
return function()
	for _, conn in ipairs(Connections) do
		conn:Disconnect()
	end
	for player, _ in pairs(ESP_Cache) do
		RemoveESP(player)
	end
	ESP_Cache = {}
	Connections = {}
end
