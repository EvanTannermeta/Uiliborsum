-- Modules/BoneESP.lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

if not Drawing then
	warn("[BoneESP] Drawing library not found!")
	return function() end
end

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local SkeletonCache = {}
local Connections = {}

-- Define which parts connect to which
local BoneConnections = {
	{"head", "torso"},
	{"torso", "shoulder1"},
	{"shoulder1", "arm1"},
	{"torso", "shoulder2"},
	{"shoulder2", "arm2"},
	{"torso", "hip1"},
	{"hip1", "leg1"},
	{"torso", "hip2"},
	{"hip2", "leg2"}
}

local ValidParts = {
	["head"] = true,
	["torso"] = true,
	["shoulder1"] = true,
	["shoulder2"] = true,
	["arm1"] = true,
	["arm2"] = true,
	["hip1"] = true,
	["hip2"] = true,
	["leg1"] = true,
	["leg2"] = true
}

-- Helper to setup a Viewmodel skeleton
local function SetupViewmodel(vm)
	if vm.Name ~= "Viewmodel" then return end -- Ignore "LocalViewmodel"
	if SkeletonCache[vm] then return end

	local parts = {}
	local lines = {}

	-- Find all target parts
	for _, child in ipairs(vm:GetDescendants()) do
		if child:IsA("BasePart") and ValidParts[child.Name] then
			parts[child.Name] = child
		end
	end

	-- If it doesn't have at least a torso, it's not a full viewmodel
	if not parts["torso"] then return end

	-- Create a line for each bone connection
	for _, connection in ipairs(BoneConnections) do
		local line = Drawing.new("Line")
		line.Color = Color3.fromRGB(255, 50, 50) -- Red skeleton
		line.Thickness = 1.5
		line.Transparency = 1
		line.Visible = false
		table.insert(lines, line)
	end

	SkeletonCache[vm] = {
		parts = parts,
		lines = lines
	}
end

local function RemoveViewmodel(vm)
	if SkeletonCache[vm] then
		for _, line in ipairs(SkeletonCache[vm].lines) do
			line:Remove()
		end
		SkeletonCache[vm] = nil
	end
end

-- Initial Scan for existing Viewmodels
local viewmodelsFolder = Workspace:WaitForChild("Viewmodels", 5)
if viewmodelsFolder then
	for _, child in ipairs(viewmodelsFolder:GetChildren()) do
		if child:IsA("Model") then SetupViewmodel(child) end
	end
	-- Listen for new ones
	table.insert(Connections, viewmodelsFolder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then SetupViewmodel(child) end
	end))
	table.insert(Connections, viewmodelsFolder.ChildRemoved:Connect(function(child)
		RemoveViewmodel(child)
	end))
end

-- Main Render Loop
table.insert(Connections, RunService.RenderStepped:Connect(function()
	if not Camera then Camera = Workspace.CurrentCamera end

	for vm, data in pairs(SkeletonCache) do
		-- Check if viewmodel was destroyed or removed
		if not vm.Parent or not data.parts["torso"] then
			RemoveViewmodel(vm)
			continue
		end

		for i, conn in ipairs(BoneConnections) do
			local part1 = data.parts[conn[1]]
			local part2 = data.parts[conn[2]]
			local line = data.lines[i]

			if part1 and part2 then
				local p1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
				local p2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)

				-- Draw the line if either part is visible on screen
				if onScreen1 or onScreen2 then
					line.From = Vector2.new(p1.X, p1.Y)
					line.To = Vector2.new(p2.X, p2.Y)
					line.Visible = true
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	end
end))

-- Return cleanup function for the UI loader
return function()
	for _, conn in ipairs(Connections) do
		conn:Disconnect()
	end
	for vm, _ in pairs(SkeletonCache) do
		RemoveViewmodel(vm)
	end
	SkeletonCache = {}
	Connections = {}
end
