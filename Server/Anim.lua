--[[
MODULESCRIPT bernama: Anim
Anak dari Script "BossSystemServer". Isi: animasi pose, gerak/melayang boss, perubahan warna per fase.
]]
local TweenService = game:GetService("TweenService")
local Core = require(script.Parent.Core)

local CONFIG, S, C = Core.CONFIG, Core.S, Core.C
local V3, CF = Core.V3, Core.CF
local flatUnit, flatDist, nearestTarget, randomArenaPoint = Core.flatUnit, Core.flatDist, Core.nearestTarget, Core.randomArenaPoint

local Anim = {}
local KEYS = { "lax", "laz", "rax", "raz", "ty", "tp", "hp", "wing", "y" }
local A = { lax = 0, laz = 0.2, rax = 0, raz = 0.2, ty = 0, tp = 0, hp = 0, wing = 0, y = 0 }
local T = { lax = 0, laz = 0.2, rax = 0, raz = 0.2, ty = 0, tp = 0, hp = 0, wing = 0, y = 0 }
local animRate = 9
Anim.A, Anim.T = A, T

function Anim.pose(t, rate)
	for k, v in pairs(t) do
		T[k] = v
	end
	if rate then animRate = rate end
end

function Anim.idlePose(rate)
	T.lax, T.laz, T.rax, T.raz = 0, 0.2, 0, 0.2
	T.ty, T.tp, T.hp, T.wing, T.y = 0, 0, 0, 0, 0
	animRate = rate or 9
end

function Anim.setRate(r)
	animRate = r
end

-- dipanggil di awal pertarungan: boss mulai terkubur 52 stud di bawah tanah
function Anim.reset()
	for _, k in ipairs(KEYS) do
		A[k] = 0
		T[k] = 0
	end
	A.laz, T.laz, A.raz, T.raz = 0.2, 0.2, 0.2, 0.2
	A.y, T.y = -52, -52
	animRate = 1.15
	S.orbitSpeed = 0.7
	S.moveMode, S.speedMul, S.spinRate, S.lookGoal, S.legOverride, S.turnRate = "stand", 0, 0, nil, nil, 4
end

local walkPhase, walkAmp = 0, 0
local orbitAngle, crownAngle, ringAngle = 0, 0, 0

local function hoverPulse()
	Core.playSfx(nil, S.bossPos + V3(0, S.GROUND_Y, 0), "rumble", 0.5)
	Core.shakeNear(S.bossPos, 90, 0.25, 0.2)
end

function Anim.frame(dt)
	local b = S.B
	if not b or not b.root.Parent then return end
	local now = os.clock()

	local k = math.min(1, dt * animRate)
	for _, key in ipairs(KEYS) do
		A[key] = A[key] + (T[key] - A[key]) * k
	end

	local focus = nearestTarget(S.bossPos)
	local moving, spd, dir = false, 0, nil
	local base = CONFIG.WalkSpeed * (1 + (S.phase - 1) * 0.2)
	if S.alive and S.speedMul > 0 and S.moveMode ~= "stand" then
		spd = base * S.speedMul
		if S.moveMode == "wander" then
			if not S.wanderPoint or flatDist(S.wanderPoint, S.bossPos) < 8 then
				S.wanderPoint = randomArenaPoint(0.7)
			end
			dir = flatUnit(S.wanderPoint - S.bossPos)
		elseif focus then
			local to = focus.hrp.Position - S.bossPos
			local dist = flatDist(focus.hrp.Position, S.bossPos)
			if S.moveMode == "chase" then
				if dist > 14 then dir = flatUnit(to) end
			else
				local radial = flatUnit(to)
				local tangent = V3(-radial.Z, 0, radial.X) * S.circleSign
				local pull = math.clamp((dist - 38) / 30, -1, 1)
				dir = (tangent + radial * pull).Unit
			end
		end
		if dir then
			S.bossPos = S.bossPos + dir * spd * dt
			moving = true
		end
	end
	if S.legOverride then
		moving = true
		spd = S.legOverride
	end

	local off = V3(S.bossPos.X - S.SPAWN.X, 0, S.bossPos.Z - S.SPAWN.Z)
	if off.Magnitude > S.ARENA_R then
		S.bossPos = V3(S.SPAWN.X, 0, S.SPAWN.Z) + off.Unit * S.ARENA_R
	end

	if S.alive then
		if S.spinRate ~= 0 then
			S.bossLook = CFrame.Angles(0, S.spinRate * dt, 0):VectorToWorldSpace(S.bossLook)
		else
			local want
			if S.lookGoal then
				want = flatUnit(S.lookGoal - S.bossPos)
			elseif S.moveMode == "wander" and dir then
				want = dir
			elseif focus then
				want = flatUnit(focus.hrp.Position - S.bossPos)
			end
			if want then
				S.bossLook = flatUnit(S.bossLook:Lerp(want, math.min(1, dt * S.turnRate)))
			end
		end
	end

	walkAmp = walkAmp + ((moving and 0.75 or 0) - walkAmp) * math.min(1, dt * 8)
	if moving then
		local prev = math.sin(walkPhase)
		walkPhase = walkPhase + dt * math.max(spd, 6) * 0.2
		if prev * math.sin(walkPhase) < 0 and walkAmp > 0.35 then
			hoverPulse()
		end
	end
	local swing = math.sin(walkPhase) * walkAmp
	local bob = math.sin(now * 1.8) * 1.2 + walkAmp * 0.4
	local breathe = math.sin(now * 2) * 0.025

	b.rootJoint.C0 = CF(0, 2, 0) * CFrame.Angles(-A.tp - walkAmp * 0.18 - breathe, A.ty, math.sin(now * 1.1) * 0.02)
	b.neck.C0 = CF(0, 6.8, 0) * CFrame.Angles(-A.hp + math.sin(now * 0.9) * 0.04, math.sin(now * 0.6) * 0.1, 0)
	b.lSh.C0 = CF(-14.5, 4.5, 0) * CFrame.Angles(A.lax - swing * 0.35 + breathe, 0, -A.laz)
	b.rSh.C0 = CF(14.5, 4.5, 0) * CFrame.Angles(A.rax + swing * 0.35 + breathe, 0, A.raz)
	b.lEl.C0 = CF(0, -4, 0) * CFrame.Angles(math.clamp(0.3 + A.lax * 0.15, 0, 1.2), 0, 0)
	b.rEl.C0 = CF(0, -4, 0) * CFrame.Angles(math.clamp(0.3 + A.rax * 0.15, 0, 1.2), 0, 0)

	crownAngle = crownAngle + dt * (0.5 + math.max(A.wing, 0) * 2.2 + (S.phase - 1) * 0.5)
	ringAngle = ringAngle + dt * (0.8 + (S.phase - 1) * 0.4)
	b.crown.C0 = CF(0, 1.4, 2.6) * CFrame.Angles(0, 0, crownAngle)
	b.rings[1].C0 = CF(0, -5.5, 0) * CFrame.Angles(0, ringAngle, 0)
	b.rings[2].C0 = CF(0, 1.5, 0) * CFrame.Angles(0, -ringAngle * 1.3, 0)

	orbitAngle = orbitAngle + dt * S.orbitSpeed
	for i, m in ipairs(b.orbits) do
		local a = orbitAngle + (i - 1) * math.pi * 2 / #b.orbits
		m.C0 = CF(0, 14 + math.sin(now * 1.5 + i) * 2, 0) * CFrame.Angles(0, a, 0) * CF(30, 0, 0) * CFrame.Angles(now * 1.5, now * 0.9, 0)
	end

	b.core.Size = V3(1, 1, 1) * (5.8 + math.sin(now * 5) * 0.35)
	b.coreLight.Brightness = 3 + math.sin(now * 5) * 1.2

	local y = S.GROUND_Y + S.ROOT_Y + A.y + bob
	local rp = V3(S.bossPos.X, y, S.bossPos.Z)
	b.root.CFrame = CFrame.lookAt(rp, rp + S.bossLook)
end

function Anim.applyPhaseLook(p)
	local b = S.B
	local glowCol = (p == 2 and Color3.fromRGB(255, 60, 20)) or (p == 3 and C.LAVA_RAGE) or C.LAVA
	local eyeCol = (p == 3 and Color3.new(1, 1, 1)) or C.LAVA_HOT
	local coreCol = (p == 3 and Color3.new(1, 1, 1)) or C.LAVA_HOT
	local mult = (p == 3 and 2.2) or (p == 2 and 1.5) or 1
	for _, g in ipairs(b.glow) do
		TweenService:Create(g, TweenInfo.new(1.2), { Color = glowCol }):Play()
	end
	for _, e in ipairs(b.eyes) do
		TweenService:Create(e, TweenInfo.new(1.2), { Color = eyeCol }):Play()
	end
	TweenService:Create(b.core, TweenInfo.new(1.2), { Color = coreCol }):Play()
	b.coreLight.Color = glowCol
	for _, e in ipairs(b.emit) do
		e.Rate = (e:GetAttribute("base") or e.Rate) * mult
	end
end

return Anim
