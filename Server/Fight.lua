--[[
MODULESCRIPT bernama: Fight
Anak dari Script "BossSystemServer". Isi: AI boss, pilih skill, ganti fase, kematian, alur satu pertarungan.
]]
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)
local FxB = require(script.Parent.FxB)
local Arena = require(script.Parent.Arena)
local Builder = require(script.Parent.Builder)
local Anim = require(script.Parent.Anim)

local CONFIG, S, C, Remote = Core.CONFIG, Core.S, Core.C, Core.Remote
local V3, rng = Core.V3, Core.rng
local pose, idlePose = Anim.pose, Anim.idlePose
local playSfx, shake, shakeNear, flash = Core.playSfx, Core.shake, Core.shakeNear, Core.flash
local explode, shockRing, sparks, groundCracks = Fx.explode, Fx.shockRing, Fx.sparks, Fx.groundCracks

local SKILLS = {}
for k, v in pairs(require(script.Parent.SkillsA)) do SKILLS[k] = v end
for k, v in pairs(require(script.Parent.SkillsB)) do SKILLS[k] = v end

local SKILL_NAMES = {
	MagmaSlam = "MAGMA SLAM", MeteorRain = "METEOR RAIN", FlameBreath = "FLAME BREATH", LavaWave = "LAVA WAVE",
	LavaGeysers = "LAVA GEYSERS", FireballBarrage = "FIREBALL BARRAGE", LavaCharge = "LAVA CHARGE",
	Whirlwind = "LAVA WHIRLWIND", MagmaPools = "MAGMA POOLS", ObsidianSpikes = "OBSIDIAN SPIKES",
	SeekerOrbs = "SEEKER ORBS", Cataclysm = "CATACLYSM",
}
local WEIGHTS = {
	MagmaSlam = 10, MeteorRain = 8, FlameBreath = 8, LavaWave = 9, LavaGeysers = 8, FireballBarrage = 9,
	LavaCharge = 8, Whirlwind = 7, MagmaPools = 7, ObsidianSpikes = 9, SeekerOrbs = 7,
}
local MINPHASE = { Whirlwind = 2, SeekerOrbs = 2 }
local lastSkill = nil

local function pickSkill()
	if S.phase >= 2 and os.clock() >= S.ultReadyAt then
		S.ultReadyAt = os.clock() + (S.phase == 3 and 32 or 48)
		return "Cataclysm"
	end
	local pool, total = {}, 0
	for name, w in pairs(WEIGHTS) do
		if name ~= lastSkill and S.phase >= (MINPHASE[name] or 1) then
			table.insert(pool, { name, w })
			total = total + w
		end
	end
	local r = rng:NextNumber(0, total)
	for _, e in ipairs(pool) do
		r = r - e[2]
		if r <= 0 then
			lastSkill = e[1]
			return e[1]
		end
	end
	lastSkill = pool[1][1]
	return pool[1][1]
end

local function doTransform(p)
	S.speedMul = 0
	S.moveMode = "stand"
	S.lookGoal = nil
	local ff = Instance.new("ForceField")
	ff.Visible = false
	ff.Parent = S.B.model
	pose({ lax = 2.6, rax = 2.6, laz = 1.0, raz = 1.0, hp = -0.7, tp = -0.4, wing = 1.4, y = 3 }, 6)
	playSfx(S.B.root, nil, "roar", 1.5)
	S.phase = p
	S.PHASE_MUL = 1 + (p - 1) * 0.25
	S.B.model:SetAttribute("Phase", p)
	Remote:FireAllClients("Phase", p, p == 2 and "PHASE II - INFERNO" or "PHASE III - ENRAGED")
	if p == 3 then
		Remote:FireAllClients("Enraged")
	end
	shake(1.6, 2.5)
	flash(C.WARN, 1.0)
	Anim.applyPhaseLook(p)
	task.wait(1.0)
	if S.alive then
		local c = V3(S.bossPos.X, S.GROUND_Y, S.bossPos.Z)
		shockRing(c, 80, 0.9)
		explode(c + V3(0, 6, 0), 30)
		Core.hitRadius(c, 38, 30, nil, 75)
		playSfx(nil, c, "bigboom", 1.3)
		shake(2.2, 1)
	end
	task.wait(1.4)
	ff:Destroy()
	idlePose(9)
end

local function aiLoop()
	while S.alive and S.B do
		if S.pendingPhase then
			local p = S.pendingPhase
			S.pendingPhase = nil
			doTransform(p)
		end
		if not S.alive then break end

		local roll = rng:NextNumber()
		S.moveMode = (roll < 0.5 and "chase") or (roll < 0.8 and "circle") or "wander"
		S.circleSign = (rng:NextInteger(0, 1) == 0) and 1 or -1
		S.speedMul = 1
		S.lookGoal = nil
		local dur = math.max(0.8, rng:NextNumber(1.5, 3.2) - (S.phase - 1) * 0.4)
		local t0 = os.clock()
		while S.alive and os.clock() - t0 < dur do
			task.wait(0.1)
		end
		if not S.alive then break end

		if #Core.getTargets() == 0 then
			S.moveMode = "wander"
			task.wait(1)
		else
			local name = pickSkill()
			Core.announce(SKILL_NAMES[name] or name)
			S.moveMode = "stand"
			S.speedMul = 0
			local ok, err = pcall(SKILLS[name])
			if not ok then warn("[Boss] skill error " .. name .. ": " .. tostring(err)) end
			S.speedMul = 1
			S.spinRate = 0
			S.lookGoal = nil
			S.legOverride = nil
			S.turnRate = 4
			S.orbitSpeed = 0.7
			if S.B and S.B.mouthFx then S.B.mouthFx.Enabled = false end
			idlePose(9)
			task.wait(math.max(0.2, rng:NextNumber(0.5, 1.1) - (S.phase - 1) * 0.2))
		end
	end
end

local function giveKillStat()
	if not CONFIG.GiveKillStat then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		local ls = plr:FindFirstChild("leaderstats")
		if not ls then
			ls = Instance.new("Folder")
			ls.Name = "leaderstats"
			ls.Parent = plr
		end
		local v = ls:FindFirstChild("Boss Kills")
		if not v then
			v = Instance.new("IntValue")
			v.Name = "Boss Kills"
			v.Parent = ls
		end
		v.Value = v.Value + 1
	end
end

local function onDeath()
	if not S.alive then return end
	S.alive = false
	S.moveMode, S.speedMul, S.spinRate, S.lookGoal, S.legOverride = "stand", 0, 0, nil, nil
	local B = S.B
	B.mouthFx.Enabled = false
	local center = V3(S.bossPos.X, S.GROUND_Y, S.bossPos.Z)
	Remote:FireAllClients("DefeatCutscene", CONFIG.BossName, center, S.bossLook)
	Remote:FireAllClients("Countdown", 0, "")
	playSfx(B.root, nil, "death", 1.5)
	shake(2, 3)
	flash(C.LAVA_HOT, 1)
	pose({ lax = 2.4, rax = 2.4, laz = 0.9, raz = 0.9, hp = -0.8, tp = -0.3, wing = 1.2 }, 6)
	local model = B.model
	task.wait(3.4)
	pose({ lax = 0.3, rax = 0.3, laz = 0.5, raz = 0.5, hp = 0.7, tp = 0.7, wing = -0.4, y = -12 }, 3)
	for _ = 1, 8 do
		local p = center + V3(rng:NextNumber(-12, 12), rng:NextNumber(4, 36), rng:NextNumber(-12, 12))
		explode(p, 9)
		playSfx(nil, p, "boom", 1.2)
		shakeNear(center, 200, 0.8, 0.4)
		task.wait(0.6)
	end
	task.wait(0.8)
	shockRing(center, 90, 1.2)
	explode(center + V3(0, 14, 0), 36)
	playSfx(nil, center, "bigboom", 2)
	shake(3, 1.5)
	flash(Color3.new(1, 1, 1), 1.4)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= B.root then
			TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
		elseif d:IsA("ParticleEmitter") then
			d.Enabled = false
		end
	end
	giveKillStat()
	task.wait(2.4)
	model:Destroy()
	S.fightOver = true
end

local Fight = {}

function Fight.run()
	Arena.resolveSpawn()
	if CONFIG.BuildArena and not workspace:FindFirstChild("BossArena") then
		Arena.build()
	end
	local hp = CONFIG.MaxHealth * (1 + CONFIG.HealthPerExtraPlayer * math.max(0, #Players:GetPlayers() - 1))

	S.phase, S.PHASE_MUL, S.pendingPhase, S.queuedPhase = 1, 1, nil, 1
	S.fightOver = false
	S.alive = false
	S.ultReadyAt = os.clock() + 30
	lastSkill = nil
	S.bossPos = V3(S.SPAWN.X, 0, S.SPAWN.Z)
	local first = Core.getTargets()[1]
	S.bossLook = first and Core.flatUnit(first.hrp.Position - S.bossPos) or V3(0, 0, -1)
	Anim.reset()

	S.B = Builder.build(S.bossPos, S.bossLook, hp)
	local B = S.B
	local ff = Instance.new("ForceField")
	ff.Visible = false
	ff.Parent = B.model
	local conn = RunService.Heartbeat:Connect(Anim.frame)
	Arena.setAtmosphere(true)

	local hum = B.hum
	local lastH = hum.Health
	local lastHitSfx = 0
	hum.HealthChanged:Connect(function(h)
		if S.alive and h < lastH then
			FxB.damagePopup(B.torso, lastH - h)
			if os.clock() - lastHitSfx > 0.15 then
				lastHitSfx = os.clock()
				playSfx(B.root, nil, "hit", 0.6)
			end
		end
		lastH = h
		local frac = h / hum.MaxHealth
		local want = (frac <= CONFIG.Phase3At and 3) or (frac <= CONFIG.Phase2At and 2) or 1
		if want > S.queuedPhase and h > 0 then
			S.queuedPhase = want
			S.pendingPhase = want
		end
	end)
	hum.Died:Connect(onDeath)

	-- intro: boss naik dari tanah (cutscene 9.6 detik)
	local center = V3(S.SPAWN.X, S.GROUND_Y, S.SPAWN.Z)
	Remote:FireAllClients("Cutscene", CONFIG.BossName, center, S.bossLook)
	task.wait(1.2)
	Anim.T.y = 0
	shake(1.0, 4.2)
	playSfx(nil, center, "rumble", 1.5)
	groundCracks(center, 20, 14, 50)
	task.wait(4.4)
	pose({ hp = -0.7, lax = 2.4, rax = 2.4, laz = 0.9, raz = 0.9, tp = -0.3, wing = 1.2 }, 7)
	playSfx(B.root, nil, "roar", 1.6)
	shake(2.4, 2)
	flash(C.LAVA_HOT, 0.8)
	shockRing(center, 60, 1)
	sparks(center, 12)
	task.wait(4.0)
	idlePose(9)
	ff:Destroy()
	S.alive = true
	task.spawn(aiLoop)

	while not S.fightOver do
		if not B.model.Parent then
			S.alive = false
			S.fightOver = true
		end
		task.wait(0.5)
	end
	S.alive = false
	conn:Disconnect()
	Arena.setAtmosphere(false)
	Remote:FireAllClients("Countdown", 0, "")
	S.B = nil
end

function Fight.cleanupAfterError()
	S.alive = false
	if S.B and S.B.model then S.B.model:Destroy() end
	S.B = nil
	Arena.setAtmosphere(false)
end

return Fight
