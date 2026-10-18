--[[
MODULESCRIPT bernama: SkillsB
Anak dari Script "BossSystemServer". Skill 7-12: Lava Charge, Whirlwind, Magma Pools, Obsidian Spikes, Seeker Orbs, Cataclysm.
]]
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)
local FxB = require(script.Parent.FxB)
local Anim = require(script.Parent.Anim)

local CONFIG, S, C = Core.CONFIG, Core.S, Core.C
local V3, CF, rad, rng = Core.V3, Core.CF, Core.rad, Core.rng
local pose = Anim.pose
local nearestTarget, randomTarget, getTargets = Core.nearestTarget, Core.randomTarget, Core.getTargets
local randomArenaPoint, flatUnit, flatDist = Core.randomArenaPoint, Core.flatUnit, Core.flatDist
local playSfx, shake, shakeNear, flash = Core.playSfx, Core.shake, Core.shakeNear, Core.flash
local hitRadius = Core.hitRadius
local warnCircle, warnLine, explode, shockRing, sparks, lavaPool, fxPart =
	Fx.warnCircle, Fx.warnLine, Fx.explode, Fx.shockRing, Fx.sparks, Fx.lavaPool, Fx.fxPart

local SK = {}

SK.LavaCharge = function()
	local tg = nearestTarget(S.bossPos)
	if not tg then return end
	S.lookGoal = tg.hrp.Position
	S.turnRate = 8
	pose({ tp = 0.5, lax = -0.8, rax = -0.8, laz = 0.3, raz = 0.3, hp = 0.2 }, 7)
	playSfx(S.B.root, nil, "charge", 1)
	task.wait(0.7)
	local dir = flatUnit(tg.hrp.Position - S.bossPos)
	S.lookGoal = S.bossPos + dir * 600
	warnLine(S.bossPos, dir, 125, 15, 0.9)
	task.wait(0.9)
	if not S.alive then return end
	local hit = {}
	S.legOverride = 30
	pose({ tp = 0.55, lax = -1.0, rax = -1.0, laz = 0.5, raz = 0.5, wing = -0.3 }, 10)
	playSfx(S.B.root, nil, "roar", 1)
	local traveled, trail = 0, 0
	while traveled < 135 and S.alive do
		local dt = task.wait()
		local step = 95 * dt
		S.bossPos = S.bossPos + dir * step
		traveled = traveled + step
		hitRadius(S.bossPos, 14, 55, 14, 70, hit)
		trail = trail + step
		if trail >= 16 then
			trail = 0
			lavaPool(V3(S.bossPos.X, S.GROUND_Y, S.bossPos.Z), 7, 5, 12)
		end
	end
	S.legOverride = nil
	pose({ tp = 0.6, hp = 0.5, lax = 0.6, rax = 0.6 }, 5)
	shake(1.2, 0.6)
	task.wait(1.6)
end

SK.Whirlwind = function()
	pose({ laz = 1.5, raz = 1.5, lax = 0, rax = 0, tp = 0.1, wing = 1.0 }, 12)
	playSfx(S.B.root, nil, "spin", 1.2)
	warnCircle(S.bossPos, 34, 0.8)
	task.wait(0.8)
	if not S.alive then return end
	S.spinRate = 9
	S.speedMul = 0.45
	S.moveMode = "chase"
	local function tornadoCF()
		return CF(S.bossPos.X, S.GROUND_Y + 28, S.bossPos.Z) * CFrame.Angles(0, 0, rad(90))
	end
	local tornado = fxPart(Enum.PartType.Cylinder, V3(56, 60, 60), C.LAVA, tornadoCF())
	tornado.Transparency = 0.78
	local t0 = os.clock()
	local lastHit, lastRing = 0, 0
	while os.clock() - t0 < 4.5 and S.alive do
		tornado.CFrame = tornadoCF()
		local now = os.clock()
		if now - lastHit >= 0.3 then
			lastHit = now
			hitRadius(S.bossPos, 32, 16, nil, 35)
		end
		if now - lastRing >= 0.45 then
			lastRing = now
			shockRing(S.bossPos, 34, 0.5)
			sparks(V3(S.bossPos.X, S.GROUND_Y, S.bossPos.Z), 4)
		end
		task.wait()
	end
	tornado:Destroy()
	S.spinRate = 0
	S.speedMul = 0
	S.moveMode = "stand"
	pose({ laz = 0.3, raz = 0.3, tp = 0.25, hp = 0.3, wing = 0 }, 8)
	task.wait(1.4)
end

SK.MagmaPools = function()
	pose({ lax = 2.2, rax = 2.2, laz = 0.6, raz = 0.6, tp = -0.15 }, 8)
	playSfx(S.B.root, nil, "roar", 0.9)
	shake(0.6, 1)
	task.wait(0.7)
	pose({ lax = 0.8, rax = 0.8, tp = 0.4 }, 16)
	for i = 1, 5 + S.phase * 2 do
		if not S.alive then return end
		local tg = (i % 2 == 1) and randomTarget() or nil
		local p = tg and tg.hrp.Position or randomArenaPoint(0.85)
		local pos = V3(p.X + rng:NextNumber(-6, 6), S.GROUND_Y, p.Z + rng:NextNumber(-6, 6))
		warnCircle(pos, 15, 1.1)
		task.delay(1.1, function()
			lavaPool(pos, 15, 9, 22)
			playSfx(nil, pos, "boom", 0.8)
			shakeNear(pos, 100, 0.4, 0.3)
		end)
		task.wait(0.3)
	end
	task.wait(2)
end

SK.ObsidianSpikes = function()
	local tg = nearestTarget(S.bossPos)
	if not tg then return end
	S.lookGoal = tg.hrp.Position
	pose({ lax = 2.0, rax = 2.0, laz = 0.3, raz = 0.3, tp = -0.2 }, 9)
	task.wait(0.6)
	if not S.alive then return end
	pose({ lax = 0.4, rax = 0.4, tp = 0.35 }, 20)
	playSfx(S.B.root, nil, "slam", 1)
	shake(0.9, 0.5)
	local base = flatUnit(tg.hrp.Position - S.bossPos)
	local fans = { { 0 }, { -16, 16 }, { -25, 0, 25 } }
	for _, deg in ipairs(fans[S.phase]) do
		local d = CFrame.Angles(0, rad(deg), 0):VectorToWorldSpace(base)
		for i = 1, 13 do
			local p = S.bossPos + d * (14 + i * 9)
			local pos = V3(p.X, S.GROUND_Y, p.Z)
			if flatDist(pos, S.SPAWN) < S.ARENA_R + 10 then
				FxB.spikeAt(pos, 0.9 + i * 0.1)
			end
		end
	end
	task.wait(3.4)
end

SK.SeekerOrbs = function()
	pose({ lax = 1.9, rax = 1.9, laz = 0.9, raz = 0.9, hp = -0.3 }, 9)
	playSfx(S.B.root, nil, "ping", 1.2)
	for _ = 1, S.phase + 1 do
		if not S.alive then return end
		for i, m in ipairs(S.B.orbits) do
			FxB.seekerOrb(m.Part1.Position, 0.2 * i, 32)
		end
		task.wait(1.4)
	end
	task.wait(2)
end

SK.Cataclysm = function()
	S.lookGoal = nil
	pose({ lax = 3.0, rax = 3.0, laz = 0.8, raz = 0.8, tp = -0.35, hp = -0.6, wing = 1.2, y = 10 }, 4)
	S.orbitSpeed = 3
	playSfx(S.B.root, nil, "roar", 1.6)
	flash(C.WARN, 1)
	local zones = {}
	local count = math.max(2, math.min(4, #getTargets() + 1))
	for i = 1, count do
		local p = randomArenaPoint(0.75)
		local ring = fxPart(Enum.PartType.Cylinder, V3(0.5, 36, 36), C.SAFE,
			CF(p.X, S.GROUND_Y + 0.6, p.Z) * CFrame.Angles(0, 0, rad(90)))
		ring.Transparency = 0.4
		local beam = fxPart(Enum.PartType.Cylinder, V3(60, 34, 34), C.SAFE,
			CF(p.X, S.GROUND_Y + 30, p.Z) * CFrame.Angles(0, 0, rad(90)))
		beam.Transparency = 0.85
		zones[i] = { pos = V3(p.X, S.GROUND_Y, p.Z), r = 17, parts = { ring, beam } }
	end
	local total = 6
	for s = total, 1, -1 do
		if not S.alive then break end
		Core.Remote:FireAllClients("Countdown", s, "CATACLYSM! MASUK LINGKARAN BIRU")
		shake(0.5 + (total - s) * 0.15, 1)
		task.wait(1)
	end
	Core.Remote:FireAllClients("Countdown", 0, "")
	if S.alive then
		pose({ lax = 0.2, rax = 0.2, tp = 0.6, hp = 0.4, y = 0 }, 22)
		local c = V3(S.bossPos.X, S.GROUND_Y, S.bossPos.Z)
		shockRing(c, 170, 1.0)
		explode(c + V3(0, 10, 0), 40)
		flash(Color3.new(1, 1, 1), 1.2)
		shake(3.5, 1.8)
		playSfx(nil, c, "bigboom", 2)
		for _, t in ipairs(getTargets()) do
			local safe = false
			for _, z in ipairs(zones) do
				if flatDist(t.hrp.Position, z.pos) <= z.r then
					safe = true
					break
				end
			end
			if not safe then
				t.hum:TakeDamage(CONFIG.CataclysmDamage * CONFIG.DamageMultiplier)
			end
		end
	end
	for _, z in ipairs(zones) do
		for _, p in ipairs(z.parts) do
			p:Destroy()
		end
	end
	S.orbitSpeed = 0.7
	if S.alive then
		for _ = 1, 10 do
			FxB.meteorAt(randomArenaPoint(0.9), 12, 45, 1.5, true)
			task.wait(0.15)
		end
	end
	task.wait(2.5)
end

return SK
