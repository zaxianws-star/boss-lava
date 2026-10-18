--[[
MODULESCRIPT bernama: SkillsA
Anak dari Script "BossSystemServer". Skill 1-6: Magma Slam, Meteor Rain, Flame Breath, Lava Wave, Lava Geysers, Fireball Barrage.
]]
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)
local FxB = require(script.Parent.FxB)
local Anim = require(script.Parent.Anim)

local S, C = Core.S, Core.C
local V3, rad, rng = Core.V3, Core.rad, Core.rng
local pose = Anim.pose
local nearestTarget, randomTarget, getTargets = Core.nearestTarget, Core.randomTarget, Core.getTargets
local randomArenaPoint, flatUnit = Core.randomArenaPoint, Core.flatUnit
local playSfx, stopSfx, shake, shakeNear, flash = Core.playSfx, Core.stopSfx, Core.shake, Core.shakeNear, Core.flash
local hitCone, hitRadius = Core.hitCone, Core.hitRadius
local warnCircle, warnLine, explode, groundCracks, jumpWave = Fx.warnCircle, Fx.warnLine, Fx.explode, Fx.groundCracks, Fx.jumpWave

local SK = {}

SK.MagmaSlam = function()
	local tgt = nearestTarget(S.bossPos)
	if tgt then S.lookGoal = tgt.hrp.Position end
	pose({ lax = 3.0, rax = 3.0, laz = 0.35, raz = 0.35, tp = -0.3, hp = -0.2, wing = 0.5, y = 5 }, 7)
	local center = S.bossPos + S.bossLook * 30
	center = V3(center.X, S.GROUND_Y, center.Z)
	warnCircle(center, 24, 1.0)
	playSfx(S.B.root, nil, "charge", 1)
	shakeNear(S.bossPos, 150, 0.4, 1.0)
	task.wait(1.0)
	if not S.alive then return end
	pose({ lax = 0.3, rax = 0.3, laz = 0.2, raz = 0.2, tp = 0.5, hp = 0.3, wing = 0, y = 0 }, 24)
	task.wait(0.12)
	explode(center + V3(0, 1, 0), 24)
	groundCracks(center, 16, 14, 46)
	hitRadius(center, 24, 55, 8, 65)
	playSfx(nil, center, "slam", 1.3)
	shake(1.8, 0.7)
	flash(C.LAVA, 0.5)
	jumpWave(center, 70, 0.9, 30, 4.5)
	if S.phase >= 2 then
		task.delay(0.5, function() jumpWave(center, 90, 1.0, 30, 4.5) end)
	end
	task.wait(1.1)
end

SK.MeteorRain = function()
	pose({ lax = 2.9, rax = 2.9, laz = 0.5, raz = 0.5, hp = -0.5, tp = -0.2, wing = 0.8 }, 8)
	playSfx(S.B.root, nil, "roar", 1)
	shake(0.8, 1.2)
	flash(C.WARN, 0.4)
	task.wait(0.8)
	for i = 1, 12 + S.phase * 5 do
		if not S.alive then return end
		local pos
		local tg = randomTarget()
		if tg and i % 2 == 1 then
			pos = tg.hrp.Position + V3(rng:NextNumber(-12, 12), 0, rng:NextNumber(-12, 12))
		else
			pos = randomArenaPoint(0.9)
		end
		FxB.meteorAt(V3(pos.X, S.GROUND_Y, pos.Z), 13, 50, 1.7, S.phase >= 2)
		task.wait(0.22)
	end
	task.wait(2)
end

SK.FlameBreath = function()
	local tgt = nearestTarget(S.bossPos)
	if not tgt then return end
	S.lookGoal = tgt.hrp.Position
	S.turnRate = 6
	pose({ hp = -0.6, tp = -0.3, lax = 0.5, rax = 0.5, laz = 0.6, raz = 0.6, wing = 0.6 }, 6)
	local dir0 = flatUnit(tgt.hrp.Position - S.bossPos)
	warnLine(S.bossPos, dir0, 62, 30, 1.0)
	playSfx(S.B.root, nil, "charge", 1)
	task.wait(1.0)
	if not S.alive then return end
	pose({ hp = 0.25, tp = 0.15 }, 10)
	S.B.mouthFx.Enabled = true
	local snd = playSfx(S.B.head, nil, "flame", 1, 1, true)
	local dur = 3.2
	local t0 = os.clock()
	local sweep = (rng:NextInteger(0, 1) == 0) and 1 or -1
	while os.clock() - t0 < dur and S.alive do
		local a = (os.clock() - t0) / dur
		local d = CFrame.Angles(0, rad(-38 + 76 * a) * sweep, 0):VectorToWorldSpace(dir0)
		S.lookGoal = S.bossPos + d * 50
		hitCone(S.bossPos, S.bossLook, 60, 24, 5)
		task.wait(0.1)
	end
	stopSfx(snd)
	S.B.mouthFx.Enabled = false
	task.wait(0.8)
end

SK.LavaWave = function()
	local tgt = nearestTarget(S.bossPos)
	if not tgt then return end
	S.lookGoal = tgt.hrp.Position
	pose({ lax = 2.6, rax = 2.6, laz = 0.3, raz = 0.3, tp = -0.3, y = 4 }, 8)
	task.wait(0.4)
	local base = flatUnit(tgt.hrp.Position - S.bossPos)
	local sets = { { 0 }, { -14, 14 }, { -22, 0, 22 } }
	local dirs = {}
	for _, deg in ipairs(sets[S.phase]) do
		local d = CFrame.Angles(0, rad(deg), 0):VectorToWorldSpace(base)
		table.insert(dirs, d)
		warnLine(S.bossPos, d, 150, 62, 1.2)
	end
	playSfx(S.B.root, nil, "rumble", 1.2)
	task.wait(1.2)
	if not S.alive then return end
	pose({ lax = 0.3, rax = 0.3, tp = 0.5, y = 0 }, 24)
	playSfx(nil, S.bossPos, "slam", 1.2)
	shake(1.4, 0.6)
	for _, d in ipairs(dirs) do
		task.spawn(FxB.waveRun, S.bossPos + d * 8, d, 70, 150, 45)
	end
	task.wait(2.4)
end

SK.LavaGeysers = function()
	pose({ lax = 0.9, rax = 0.9, laz = 0.8, raz = 0.8, tp = 0.35, hp = 0.2 }, 9)
	playSfx(S.B.root, nil, "rumble", 1)
	shake(0.5, 1.5)
	for _ = 1, 2 + S.phase do
		if not S.alive then return end
		for _, t in ipairs(getTargets()) do
			FxB.geyserAt(t.hrp.Position, 11, 45, 1.2)
		end
		for _ = 1, 4 + S.phase * 2 do
			FxB.geyserAt(randomArenaPoint(0.85), 10, 40, 1.2)
		end
		task.wait(1.5)
	end
	task.wait(1)
end

SK.FireballBarrage = function()
	pose({ lax = 1.5, rax = 1.5, laz = 0.2, raz = 0.2, tp = 0.1, hp = -0.1, wing = 0.3 }, 9)
	for i = 1, 6 + S.phase * 4 do
		if not S.alive then return end
		local tg = (i % 2 == 0) and randomTarget() or nearestTarget(S.bossPos)
		if tg then
			S.lookGoal = tg.hrp.Position
			local origin = S.bossPos + V3(0, S.GROUND_Y + 26, 0) + S.bossLook * 12
			local aim = tg.hrp.Position + tg.hrp.AssemblyLinearVelocity * 0.4
			local dir = (aim - origin).Unit + V3(rng:NextNumber(-0.06, 0.06), rng:NextNumber(-0.03, 0.03), rng:NextNumber(-0.06, 0.06))
			FxB.fireball(origin, dir.Unit, 75, 28)
			pose({ lax = 1.2 + (i % 2) * 0.5, rax = 1.7 - (i % 2) * 0.5 }, 14)
		end
		task.wait(0.35 - S.phase * 0.04)
	end
	task.wait(1)
end

return SK
