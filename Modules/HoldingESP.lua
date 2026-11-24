-- Modules/HoldingESP.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not Drawing then
	warn("[HoldingESP] Drawing library not found!")
	return function() end
end

local HoldingCache = {}
local Connections = {}

-- 1. Look inside the player's character for Configuration "Character" -> ObjectValue "equipped"
local function GetPlayerEquipped(player)
	local charModel = player.Character
	if not charModel then return nil end
	
	local config = charModel:FindFirstChild("Character")
	if not config then return nil end
	
	local equipped = config:FindFirstChild("equipped")
	if not equipped or not equipped.Value then return nil end
	
	return tostring(equipped.Value)
end

-- 2. Check Viewmodel for Configuration "State" -> ObjectValue "owner"
local function GetViewmodelOwner(vm)
	local state = vm:FindFirstChild("State")
	if not state then return nil end
	
	local owner = state:FindFirstChild("owner")
	if not owner or not owner.Value then return nil end
	
	return owner.Value
end

local function UpdateViewmodel(vm)
	if vm.Name ~= "Viewmodel" then return end

	local owner = GetViewmodelOwner(vm)
	if not owner or not owner:IsA("Player") then
		if HoldingCache[vm] then HoldingCache[vm].Text.Visible = false end
		return
	end

	local equippedName = GetPlayerEquipped(owner)
	if not equippedName then
		if HoldingCache[vm] then HoldingCache[vm].Text.Visible = false end
		return
	end

	-- 3. Look inside Viewmodel for a Model matching the equipped name
	local toolModel = vm:FindFirstChild(equippedName)
	if not toolModel or not toolModel:IsA("Model") then
		if HoldingCache[vm] then HoldingCache[vm].Text.Visible = false end
		return
	end

	-- Find a part to attach the text to
	local part = toolModel.PrimaryPart or toolModel:FindFirstChildWhichIsA("BasePart")
	if not part then
		if HoldingCache[vm] then HoldingCache[vm].Text.Visible = false end
		return
	end

	-- Create the Drawing text if it doesn't exist
	if not HoldingCache[vm] then
		local text = Drawing.new("Text")
		text.Color = Color3.fromRGB(255, 255, 0) -- Yellow
		text.Size = 14
		text.Center = true
		text.Outline = true
		text.Font = Drawing.Fonts.GothamBold
		
		HoldingCache[vm] = { Text = text }
	end

	local cache = HoldingCache[vm]
	cache.Text.Text = `[{equippedName}]`
	
	-- Update position on screen
	local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
	if onScreen then
		cache.Text.Position = Vector2.new(screenPos.X, screenPos.Y)
		cache.Text.Visible = true
	else
		cache.Text.Visible = false
	end
end

-- Main Render Loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
	local vmFolder = Workspace:FindFirstChild("Viewmodels")
	if not vmFolder then return end

	for _, vm in ipairs(vmFolder:GetChildren()) do
		if vm:IsA("Model") then
			UpdateViewmodel(vm)
		end
	end

	-- Clean up destroyed Viewmodels
	for vm, cache in pairs(HoldingCache) do
		if not vm.Parent then
			cache.Text:Remove()
			HoldingCache[vm] = nil
		end
	end
end))

-- Return cleanup function
return function()
	for _, conn in ipairs(Connections) do conn:Disconnect() end
	for vm, cache in pairs(HoldingCache) do
		cache.Text:Remove()
	end
	HoldingCache = {}
	Connections = {}
end
