--[[
MODULESCRIPT bernama: Fx
Anak dari Script "BossSystemServer". Isi: semua efek (ring, meteor, geyser, fireball, dll).
]]
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)

local S, C, TEX = Core.S, Core.C, Core.TEX
local V3, CF, rad, rng = Core.V3, Core.CF, Core.rad, Core.rng
local LAVA, LAVA_HOT, WARN = C.LAVA, C.LAVA_HOT, C.WARN
local TEX_FIRE = TEX.FIRE
local hitRadius, dealDamage, getTargets, nearestTarget = Core.hitRadius, Core.dealDamage, Core.getTargets, Core.nearestTarget
local playSfx, shakeNear = Core.playSfx, Core.shakeNear

local Fx = {}

local function fxPart(shape, size, color, cf)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.Neon
	p.CFrame = cf
	p.Parent = workspace
	return p
end
Fx.fxPart = fxPart

function Fx.makeEmitter(att, tex, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = att
	return e
end
local makeEmitter = Fx.makeEmitter

local function shockRing(pos, radius, dur)
	local r = fxPart(Enum.PartType.Cylinder, V3(1.5, 4, 4), LAVA,
		CF(pos.X, S.GROUND_Y + 0.8, pos.Z) * CFrame.Angles(0, 0, rad(90)))
	TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = V3(1.5, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(r, dur + 0.1)
end
Fx.shockRing = shockRing

local function sparks(pos, n)
	for _ = 1, n do
		local p = Instance.new("Part")
		p.Size = V3(1, 1, 1) * rng:NextNumber(0.8, 2.2)
		p.Material = Enum.Material.Neon
		p.Color = LAVA
		p.CanTouch = false
		p.CanQuery = false
		p.Position = pos + V3(0, 2, 0)
		p.Parent = workspace
		p.AssemblyLinearVelocity = V3(rng:NextNumber(-40, 40), rng:NextNumber(35, 75), rng:NextNumber(-40, 40))
		TweenService:Create(p, TweenInfo.new(1.6), { Transparency = 1, Size = V3(0.2, 0.2, 0.2) }):Play()
		Debris:AddItem(p, 1.7)
	end
end
Fx.sparks = sparks

local function explode(pos, radius)
	local b = fxPart(Enum.PartType.Ball, V3(2, 2, 2), LAVA_HOT, CF(pos))
	b.Transparency = 0.2
	TweenService:Create(b, TweenInfo.new(0.45), { Size = V3(1, 1, 1) * (radius * 2), Transparency = 1, Color = LAVA }):Play()
	Debris:AddItem(b, 0.5)
	shockRing(pos, radius * 1.3, 0.5)
	sparks(pos, 8)
end
Fx.explode = explode

function Fx.warnCircle(pos, radius, dur)
	local cf = CF(pos.X, S.GROUND_Y + 0.35, pos.Z) * CFrame.Angles(0, 0, rad(90))
	local outer = fxPart(Enum.PartType.Cylinder, V3(0.3, radius * 2, radius * 2), WARN, cf)
	outer.Transparency = 0.65
	local inner = fxPart(Enum.PartType.Cylinder, V3(0.4, 1, 1), WARN, cf)
	inner.Transparency = 0.35
	TweenService:Create(inner, TweenInfo.new(dur, Enum.EasingStyle.Linear),
		{ Size = V3(0.4, radius * 2, radius * 2) }):Play()
	Debris:AddItem(outer, dur)
	Debris:AddItem(inner, dur)
end
local warnCircle = Fx.warnCircle

function Fx.warnLine(origin, dir, length, width, dur)
	local center = V3(origin.X, S.GROUND_Y + 0.35, origin.Z) + dir * (length / 2)
	local cf = CFrame.lookAt(center, center + dir)
	local outer = fxPart(Enum.PartType.Block, V3(width, 0.3, length), WARN, cf)
	outer.Transparency = 0.65
	local inner = fxPart(Enum.PartType.Block, V3(width, 0.4, length), WARN, cf)
	inner.Transparency = 0.85
	TweenService:Create(inner, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Transparency = 0.25 }):Play()
	Debris:AddItem(outer, dur)
	Debris:AddItem(inner, dur)
end

function Fx.groundCracks(center, count, minLen, maxLen)
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local len = rng:NextNumber(minLen, maxLen)
		local dir = V3(math.cos(a), 0, math.sin(a))
		local c = fxPart(Enum.PartType.Block, V3(len, 0.25, rng:NextNumber(0.8, 1.6)), LAVA,
			CF(center + dir * (len / 2 + 5) + V3(0, S.GROUND_Y + 0.3, 0)) * CFrame.Angles(0, -a, 0))
		TweenService:Create(c, TweenInfo.new(6, Enum.EasingStyle.Linear), { Transparency = 1 }):Play()
		Debris:AddItem(c, 6.2)
	end
end

function Fx.lavaPool(pos, radius, life, dps)
	local cf = CF(pos.X, S.GROUND_Y + 0.45, pos.Z) * CFrame.Angles(0, 0, rad(90))
	local pool = fxPart(Enum.PartType.Cylinder, V3(0.5, 1, 1), LAVA, cf)
	local light = Instance.new("PointLight")
	light.Color = LAVA
	light.Range = radius * 2.5
	light.Brightness = 2
	light.Parent = pool
	TweenService:Create(pool, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = V3(0.5, radius * 2, radius * 2) }):Play()
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < life do
			hitRadius(pos, radius, dps * 0.5, 4)
			task.wait(0.5)
		end
		TweenService:Create(pool, TweenInfo.new(0.7), { Transparency = 1 }):Play()
		task.wait(0.7)
		pool:Destroy()
	end)
end
local lavaPool = Fx.lavaPool

function Fx.jumpWave(center, maxR, dur, dmg, maxH)
	local r = fxPart(Enum.PartType.Cylinder, V3(1.2, 4, 4), LAVA_HOT,
		CF(center.X, S.GROUND_Y + 0.7, center.Z) * CFrame.Angles(0, 0, rad(90)))
	TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Linear),
		{ Size = V3(1.2, maxR * 2, maxR * 2), Transparency = 0.75 }):Play()
	Debris:AddItem(r, dur + 0.1)
	local hit = {}
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local radius = maxR * ((os.clock() - t0) / dur)
			for _, t in ipairs(getTargets()) do
				if not hit[t.hum] then
					local p = t.hrp.Position
					local d = V3(p.X - center.X, 0, p.Z - center.Z).Magnitude
					if math.abs(d - radius) <= 5 and p.Y - S.GROUND_Y <= maxH then
						hit[t.hum] = true
						dealDamage(t.hum, dmg)
						t.hrp.AssemblyLinearVelocity = V3(0, 45, 0)
					end
				end
			end
			task.wait()
		end
	end)
end

return Fx
