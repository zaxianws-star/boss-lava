--[[
MODULESCRIPT bernama: Arena
Anak dari Script "BossSystemServer". Isi: arena stud, suasana langit, penentuan posisi spawn.
]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)

local CONFIG, S, C, TEX = Core.CONFIG, Core.S, Core.C, Core.TEX
local V3, CF, rad, rng = Core.V3, Core.CF, Core.rad, Core.rng
local fxPart, makeEmitter = Fx.fxPart, Fx.makeEmitter

local Arena = {}

local function studPart(parent, name, size, color, cf, allSides)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	if allSides then
		p.LeftSurface = Enum.SurfaceType.Studs
		p.RightSurface = Enum.SurfaceType.Studs
		p.FrontSurface = Enum.SurfaceType.Studs
		p.BackSurface = Enum.SurfaceType.Studs
	end
	p.CFrame = cf
	p.Parent = parent
	return p
end

function Arena.build()
	local P, GY = S.SPAWN, S.GROUND_Y
	local folder = Instance.new("Folder")
	folder.Name = "BossArena"
	folder.Parent = workspace

	studPart(folder, "Floor", V3(280, 6, 280), Color3.fromRGB(70, 58, 56), CF(P.X, GY - 2.8, P.Z), false)

	local edges = {
		{ V3(280, 0.4, 3), V3(0, 0, -138.5) }, { V3(280, 0.4, 3), V3(0, 0, 138.5) },
		{ V3(3, 0.4, 280), V3(-138.5, 0, 0) }, { V3(3, 0.4, 280), V3(138.5, 0, 0) },
	}
	for _, e in ipairs(edges) do
		fxPart(Enum.PartType.Block, e[1], C.LAVA, CF(P.X + e[2].X, GY + 0.35, P.Z + e[2].Z)).Parent = folder
	end

	for _ = 1, 30 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(12, 115)
		local len = rng:NextNumber(8, 26)
		fxPart(Enum.PartType.Block, V3(len, 0.1, rng:NextNumber(0.6, 1.3)), C.LAVA,
			CF(P.X + math.cos(a) * r, GY + 0.27, P.Z + math.sin(a) * r) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)).Parent = folder
	end

	for i, rr in ipairs({ 24, 46, 70 }) do
		local ring = fxPart(Enum.PartType.Cylinder, V3(0.1, rr * 2, rr * 2), C.LAVA_RAGE,
			CF(P.X, GY + 0.24 + i * 0.01, P.Z) * CFrame.Angles(0, 0, rad(90)))
		ring.Transparency = 0.7
		ring.Parent = folder
	end

	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + rng:NextNumber(-0.1, 0.1)
		local r = rng:NextNumber(112, 128)
		local h = rng:NextNumber(26, 56)
		local sx, sz = rng:NextNumber(9, 14), rng:NextNumber(9, 14)
		local cf = CF(P.X + math.cos(a) * r, GY + h / 2 - 2, P.Z + math.sin(a) * r)
			* CFrame.Angles(rng:NextNumber(-0.08, 0.08), rng:NextNumber(0, 6.28), rng:NextNumber(-0.08, 0.08))
		studPart(folder, "Spire", V3(sx, h, sz), C.ROCK, cf, true)
		fxPart(Enum.PartType.Block, V3(sx + 0.3, 1.4, sz + 0.3), C.LAVA, cf * CF(0, h * 0.12, 0)).Parent = folder
	end

	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2 + 0.4
		local x, z = P.X + math.cos(a) * 96, P.Z + math.sin(a) * 96
		studPart(folder, "BrazierBase", V3(7, 5, 7), C.ROCK2, CF(x, GY + 2.5, z), true)
		local bowl = fxPart(Enum.PartType.Block, V3(5, 1.2, 5), C.LAVA, CF(x, GY + 5.6, z))
		bowl.Parent = folder
		local att = Instance.new("Attachment")
		att.Position = V3(0, 1, 0)
		att.Parent = bowl
		makeEmitter(att, TEX.FIRE, {
			Rate = 18, Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(4, 8),
			Size = NumberSequence.new(4, 1), Transparency = NumberSequence.new(0.2, 1),
			Color = ColorSequence.new(C.LAVA_HOT, C.DARKRED), LightEmission = 1,
		})
		local light = Instance.new("PointLight")
		light.Color = C.LAVA
		light.Range = 36
		light.Brightness = 2
		light.Parent = bowl
	end
end

local atmosOrig = nil
function Arena.setAtmosphere(on)
	if not CONFIG.Atmosphere then return end
	if on then
		if atmosOrig then return end
		atmosOrig = {
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
			Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
		}
		TweenService:Create(Lighting, TweenInfo.new(3), {
			Ambient = Color3.fromRGB(60, 25, 15), OutdoorAmbient = Color3.fromRGB(70, 30, 20),
			Brightness = 1.2, ClockTime = 19,
		}):Play()
	elseif atmosOrig then
		TweenService:Create(Lighting, TweenInfo.new(3), atmosOrig):Play()
		atmosOrig = nil
	end
end

local resolved = false
function Arena.resolveSpawn()
	if resolved then return end
	resolved = true
	local part = workspace:FindFirstChild("BossSpawn")
	local tg = Core.getTargets()[1]
	local pos = V3(0, 0, 0)
	if CONFIG.SpawnPosition then
		pos = CONFIG.SpawnPosition
		S.GROUND_Y = pos.Y
	elseif part and part:IsA("BasePart") then
		pos = part.Position
		S.GROUND_Y = part.Position.Y + part.Size.Y / 2
	elseif tg then
		local hp = tg.hrp.Position
		pos = hp + Core.flatUnit(tg.hrp.CFrame.LookVector) * 130
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ex = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then table.insert(ex, plr.Character) end
		end
		params.FilterDescendantsInstances = ex
		local hit = workspace:Raycast(V3(pos.X, hp.Y + 60, pos.Z), V3(0, -300, 0), params)
		S.GROUND_Y = hit and hit.Position.Y or (hp.Y - 3)
	end
	S.SPAWN = V3(pos.X, S.GROUND_Y, pos.Z)
end

return Arena
