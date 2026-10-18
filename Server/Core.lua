--[[
MODULESCRIPT bernama: Core
Anak dari Script "BossSystemServer". Isi: status bersama, util, damage, suara.
]]
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CONFIG = require(script.Parent.Config)

local Core = {}
local V3, CF, rad = Vector3.new, CFrame.new, math.rad
local rng = Random.new()
Core.CONFIG, Core.V3, Core.CF, Core.rad, Core.rng = CONFIG, V3, CF, rad, rng

Core.C = {
	LAVA = Color3.fromRGB(255, 105, 20),
	LAVA_HOT = Color3.fromRGB(255, 225, 100),
	LAVA_RAGE = Color3.fromRGB(255, 205, 70),
	DARKRED = Color3.fromRGB(150, 25, 0),
	WARN = Color3.fromRGB(255, 50, 30),
	SAFE = Color3.fromRGB(80, 220, 255),
	OBS = Color3.fromRGB(38, 30, 34),
	ROCK = Color3.fromRGB(62, 52, 50),
	ROCK2 = Color3.fromRGB(96, 80, 72),
}
Core.TEX = {
	FIRE = "rbxasset://textures/particles/fire_main.dds",
	SMOKE = "rbxasset://textures/particles/smoke_main.dds",
	SPARK = "rbxasset://textures/particles/sparkles_main.dds",
}

local Remote = ReplicatedStorage:FindFirstChild("BossEvent") or Instance.new("RemoteEvent")
Remote.Name = "BossEvent"
Remote.Parent = ReplicatedStorage
Core.Remote = Remote

local S = {
	GROUND_Y = 0, SPAWN = V3(0, 0, 0), ROOT_Y = 16.5, ARENA_R = 128,
	PHASE_MUL = 1, phase = 1, pendingPhase = nil, queuedPhase = 1,
	alive = false, fightOver = true, ultReadyAt = 0, B = nil,
	bossPos = V3(0, 0, 0), bossLook = V3(0, 0, -1), lookGoal = nil,
	moveMode = "stand", speedMul = 0, circleSign = 1, wanderPoint = nil,
	spinRate = 0, turnRate = 4, legOverride = nil, orbitSpeed = 0.7,
}
Core.S = S

function Core.shake(mag, dur)
	Remote:FireAllClients("Shake", mag, dur)
end

function Core.shakeNear(pos, radius, mag, dur)
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - pos).Magnitude <= radius then
			Remote:FireClient(plr, "Shake", mag, dur)
		end
	end
end

function Core.flash(color, dur)
	Remote:FireAllClients("Flash", color, dur)
end

function Core.announce(name)
	Remote:FireAllClients("Skill", name)
end

function Core.flatUnit(v)
	local f = V3(v.X, 0, v.Z)
	if f.Magnitude < 0.001 then return V3(0, 0, -1) end
	return f.Unit
end

function Core.flatDist(a, b)
	return V3(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function Core.getTargets()
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if hrp and h and h.Health > 0 then
			table.insert(list, { hrp = hrp, hum = h })
		end
	end
	return list
end

function Core.nearestTarget(pos)
	local best, bd
	for _, t in ipairs(Core.getTargets()) do
		local d = Core.flatDist(t.hrp.Position, pos)
		if not bd or d < bd then
			best, bd = t, d
		end
	end
	return best, bd
end

function Core.randomTarget()
	local l = Core.getTargets()
	if #l == 0 then return nil end
	return l[rng:NextInteger(1, #l)]
end

function Core.randomArenaPoint(f)
	local a = rng:NextNumber(0, math.pi * 2)
	local r = math.sqrt(rng:NextNumber(0, 1)) * S.ARENA_R * f
	return V3(S.SPAWN.X + math.cos(a) * r, S.GROUND_Y, S.SPAWN.Z + math.sin(a) * r)
end

function Core.dealDamage(hum, dmg)
	hum:TakeDamage(dmg * S.PHASE_MUL * CONFIG.DamageMultiplier)
end

function Core.hitRadius(pos, radius, dmg, maxHeight, knock, hitSet)
	for _, t in ipairs(Core.getTargets()) do
		local p = t.hrp.Position
		local flat = V3(p.X - pos.X, 0, p.Z - pos.Z)
		if flat.Magnitude <= radius and (not maxHeight or p.Y - S.GROUND_Y <= maxHeight) and not (hitSet and hitSet[t.hum]) then
			if hitSet then hitSet[t.hum] = true end
			Core.dealDamage(t.hum, dmg)
			if knock then
				local dir = V3(0, 0, 1)
				if flat.Magnitude > 0.1 then dir = flat.Unit end
				t.hrp.AssemblyLinearVelocity = dir * knock + V3(0, knock * 0.8, 0)
			end
		end
	end
end

function Core.hitCone(origin, look, range, halfDeg, dmg)
	local cosMax = math.cos(rad(halfDeg))
	for _, t in ipairs(Core.getTargets()) do
		local p = t.hrp.Position
		local flat = V3(p.X - origin.X, 0, p.Z - origin.Z)
		local m = flat.Magnitude
		if m <= range and (m < 4 or flat.Unit:Dot(look) >= cosMax) then
			Core.dealDamage(t.hum, dmg)
		end
	end
end

--========================  SUARA  ========================
local SND = "rbxasset://sounds/"
local BANK = {
	roar     = { { SND .. "bass.wav", 0.45, 3 }, { SND .. "uuhhh.mp3", 0.3, 2.5 }, { SND .. "impact_explosion_03.mp3", 0.5, 1.2 } },
	step     = { { SND .. "action_footsteps_plastic.mp3", 0.3, 2.5 }, { SND .. "bass.wav", 1.2, 0.9 } },
	slam     = { { SND .. "impact_explosion_03.mp3", 0.7, 3 }, { SND .. "bass.wav", 0.6, 2 } },
	boom     = { { SND .. "impact_explosion_03.mp3", 1.0, 2 } },
	bigboom  = { { SND .. "impact_explosion_03.mp3", 0.55, 3.5 }, { SND .. "bass.wav", 0.4, 2 } },
	whoosh   = { { SND .. "Rocket whoosh 01.wav", 0.7, 1.6 } },
	fireball = { { SND .. "Rocket shot.wav", 0.8, 2 } },
	flame    = { { SND .. "Rocket whoosh 01.wav", 0.5, 2.2 } },
	charge   = { { SND .. "bass.wav", 0.3, 2.5 } },
	geyser   = { { SND .. "impact_explosion_03.mp3", 0.85, 2 }, { SND .. "Rocket whoosh 01.wav", 1.0, 1.4 } },
	rumble   = { { SND .. "bass.wav", 0.2, 1.8 } },
	spin     = { { SND .. "Rocket whoosh 01.wav", 0.6, 1.8 } },
	ping     = { { SND .. "electronicpingshort.wav", 0.6, 1.2 } },
	hit      = { { SND .. "impact_explosion_03.mp3", 2.0, 0.7 } },
	death    = { { SND .. "uuhhh.mp3", 0.2, 3 }, { SND .. "impact_explosion_03.mp3", 0.5, 3.5 }, { SND .. "bass.wav", 0.35, 2.5 } },
}

local function sfxParent(part, pos)
	if part then return part end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = V3(1, 1, 1)
	p.Position = pos
	p.Parent = workspace
	Debris:AddItem(p, 14)
	return p
end

function Core.playSfx(part, pos, key, volMul, speedMul, looped)
	local out = {}
	if not CONFIG.SoundEnabled then return out end
	local layers = BANK[key]
	local custom = CONFIG.CustomSounds[key]
	if custom and custom ~= "" then
		layers = { { custom, 1, 2 } }
	end
	if not layers then return out end
	local parent = sfxParent(part, pos)
	for _, L in ipairs(layers) do
		local s = Instance.new("Sound")
		s.SoundId = L[1]
		s.PlaybackSpeed = L[2] * (speedMul or 1)
		s.Volume = math.min(L[3] * (volMul or 1) * CONFIG.MasterVolume, 10)
		s.RollOffMinDistance = 40
		s.RollOffMaxDistance = 400
		s.Looped = looped or false
		s.Parent = parent
		s:Play()
		if not looped then
			Debris:AddItem(s, 12)
		end
		table.insert(out, s)
	end
	return out
end

function Core.stopSfx(list)
	for _, s in ipairs(list) do
		if s and s.Parent then
			s:Stop()
			s:Destroy()
		end
	end
end

return Core
