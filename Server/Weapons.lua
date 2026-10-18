--[[
MODULESCRIPT bernama: Weapons
Anak dari Script "BossSystemServer". Isi: "Pedang Lava" otomatis di Backpack + sistem cadangan
supaya SEMUA senjata (Tool dari Toolbox) tetap bisa melukai boss walau script senjatanya tidak kena.
]]
local Players = game:GetService("Players")
local Core = require(script.Parent.Core)

local CONFIG, S = Core.CONFIG, Core.S
local V3, CF, rad = Core.V3, Core.CF, Core.rad
local Weapons = {}

local hooked = {}

local function hook(tool)
	if hooked[tool] then return end
	hooked[tool] = true
	tool.Activated:Connect(function()
		local bd = S.B
		if not bd or not S.alive then return end
		local handle = tool:FindFirstChild("Handle")
		if not handle then return end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { bd.model }
		local h0 = bd.hum.Health
		local t0 = os.clock()
		while os.clock() - t0 < 0.8 and S.alive do
			local parts = workspace:GetPartsInPart(handle, params)
			if #parts > 0 then
				task.wait(0.2) -- beri waktu script senjata sendiri
				if S.alive and bd.hum.Health >= h0 then
					local dmg = tool:GetAttribute("BossDamage") or CONFIG.WeaponFallbackDamage
					bd.hum:TakeDamage(dmg)
				end
				break
			end
			task.wait(0.05)
		end
	end)
end

local function scanPlayer(plr)
	local bp = plr:FindFirstChildOfClass("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then hook(t) end
		end
	end
	if plr.Character then
		for _, t in ipairs(plr.Character:GetChildren()) do
			if t:IsA("Tool") then hook(t) end
		end
	end
end

local function makeSword()
	local tool = Instance.new("Tool")
	tool.Name = "Pedang Lava"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.Grip = CF(0, 0, -1.5)
	tool:SetAttribute("BossDamage", 25)
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = V3(1, 1, 5)
	h.Color = Color3.fromRGB(255, 190, 60)
	h.Material = Enum.Material.Neon
	h.CanCollide = false
	h.Massless = true
	h.Parent = tool
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 30)
	light.Range = 10
	light.Parent = h
	tool.Activated:Connect(function()
		if not tool.Enabled then return end
		tool.Enabled = false
		tool.Grip = CF(0, 0, -1.5) * CFrame.Angles(rad(-75), 0, 0)
		task.wait(0.25)
		tool.Grip = CF(0, 0, -1.5)
		task.wait(0.35)
		tool.Enabled = true
	end)
	return tool
end

local function giveSword(plr)
	local bp = plr:WaitForChild("Backpack", 10)
	if bp and not bp:FindFirstChild("Pedang Lava") and not (plr.Character and plr.Character:FindFirstChild("Pedang Lava")) then
		makeSword().Parent = bp
	end
end

function Weapons.start()
	if CONFIG.GiveSword then
		local function setup(plr)
			task.spawn(giveSword, plr)
			plr.CharacterAdded:Connect(function()
				task.wait(0.6)
				giveSword(plr)
			end)
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			setup(plr)
		end
		Players.PlayerAdded:Connect(setup)
	end
	if CONFIG.WeaponFallback then
		task.spawn(function()
			while true do
				for _, plr in ipairs(Players:GetPlayers()) do
					scanPlayer(plr)
				end
				task.wait(1)
			end
		end)
	end
end

return Weapons
