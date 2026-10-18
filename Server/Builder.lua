--[[
MODULESCRIPT bernama: Builder
Anak dari Script "BossSystemServer". Isi: model boss baru - Colossus melayang
(mahkota matahari, mata tunggal, bahu cakram, lengan bersendi, cincin rune, kristal melayang, tanpa kaki/sayap/tanduk).
]]
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)

local CONFIG, S, C, TEX = Core.CONFIG, Core.S, Core.C, Core.TEX
local V3, CF, rad = Core.V3, Core.CF, Core.rad
local LAVA, LAVA_HOT, DARKRED = C.LAVA, C.LAVA_HOT, C.DARKRED
local TEX_FIRE, TEX_SMOKE, TEX_SPARK = TEX.FIRE, TEX.SMOKE, TEX.SPARK
local makeEmitter = Fx.makeEmitter

local function newPart(parent, name, size, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	if shape then p.Shape = shape end
	p.Size = size
	p.Color = color
	p.CanCollide = false
	p.Massless = true
	local mat = material or Enum.Material.Plastic
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if mat == Enum.Material.Plastic and not shape then
		p.TopSurface = Enum.SurfaceType.Studs
		p.LeftSurface = Enum.SurfaceType.Studs
		p.RightSurface = Enum.SurfaceType.Studs
		p.FrontSurface = Enum.SurfaceType.Studs
		p.BackSurface = Enum.SurfaceType.Studs
	end
	p.Parent = parent
	return p
end

local function fix(baseP, part, offset)
	part.CFrame = baseP.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = baseP
	w.Part1 = part
	w.Parent = part
	return part
end

local function joint(name, p0, p1, c0, c1)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = p0
	m.Part1 = p1
	m.C0 = c0
	m.C1 = c1 or CF()
	p1.CFrame = p0.CFrame * m.C0 * m.C1:Inverse()
	m.Parent = p0
	return m
end

-- tanduk/duri bersegmen; tumbuh ke arah +Y dari cf (relatif terhadap base)
local function horn(base, cf, len, th, segs, curve, color, tipColor)
	local segLen = len / segs
	for i = 1, segs do
		local t = th * (1 - (i - 1) / segs * 0.85)
		local isTip = (i == segs)
		local part = newPart(base.Parent, "Spike", V3(t, segLen + 0.15, t),
			(isTip and tipColor) or color, isTip and Enum.Material.Neon or nil)
		fix(base, part, cf * CF(0, segLen / 2, 0))
		cf = cf * CF(0, segLen, 0) * curve
	end
end

local BASALT = Color3.fromRGB(78, 30, 28)
local BASALT2 = Color3.fromRGB(122, 52, 42)
local CHAR = Color3.fromRGB(28, 20, 22)
local GOLD = Color3.fromRGB(255, 190, 60)
local TOOTH = Color3.fromRGB(235, 215, 175)

local function buildBoss(pos, look, maxHp)
	local model = Instance.new("Model")
	model.Name = "LavaBoss"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = V3(8, 4, 5)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	local startPos = V3(pos.X, S.GROUND_Y + S.ROOT_Y - 52, pos.Z)
	root.CFrame = CFrame.lookAt(startPos, startPos + look)
	root.Parent = model
	model.PrimaryPart = root

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = maxHp
	hum.Health = maxHp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.RequiresNeck = false
	hum.WalkSpeed = 0
	hum.Parent = model

	local bd = { model = model, root = root, hum = hum, glow = {}, eyes = {}, emit = {}, orbits = {}, rings = {} }

	local function solid(base, name, size, color, offset, shape, mat)
		local p = newPart(model, name, size, color, mat, shape)
		fix(base, p, offset)
		return p
	end

	local function glowPart(base, name, size, offset, shape)
		local p = solid(base, name, size, LAVA, offset, shape, Enum.Material.Neon)
		table.insert(bd.glow, p)
		return p
	end

	local function hitbox(base, size, offset)
		local p = newPart(model, "Hitbox", size, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
		p.Transparency = 1
		p.CanTouch = true
		p.CanQuery = true
		fix(base, p, offset)
	end

	local function emit(part, offset, tex, props)
		local att = Instance.new("Attachment")
		att.CFrame = offset
		att.Parent = part
		local e = makeEmitter(att, tex, props)
		e:SetAttribute("base", e.Rate)
		table.insert(bd.emit, e)
		return e
	end

	-- PEDESTAL MELAYANG (tidak punya kaki, melayang di atas semburan api)
	local widths = { 13, 10.5, 8, 5.5, 3 }
	for i, w in ipairs(widths) do
		local y = -2.4 - (i - 1) * 2.8
		solid(root, "BaseTier", V3(w, 2.6, w), (i % 2 == 1) and BASALT or BASALT2, CF(0, y, 0))
		glowPart(root, "BaseSeam", V3(w + 0.4, 0.5, w + 0.4), CF(0, y - 1.45, 0))
	end
	solid(root, "Waist", V3(6.5, 4.5, 6.5), CHAR, CF(0, 0.8, 0))
	hitbox(root, V3(13, 13, 13), CF(0, -7, 0))
	local jet = emit(root, CF(0, -16.5, 0), TEX_FIRE, {
		Rate = 60, Lifetime = NumberRange.new(0.6, 1.0), Speed = NumberRange.new(12, 20),
		SpreadAngle = Vector2.new(18, 18), Size = NumberSequence.new(8, 2),
		Transparency = NumberSequence.new(0.1, 1), Color = ColorSequence.new(LAVA_HOT, DARKRED), LightEmission = 1,
	})
	jet.EmissionDirection = Enum.NormalId.Bottom
	local baseLight = Instance.new("PointLight")
	baseLight.Color = LAVA
	baseLight.Range = 45
	baseLight.Brightness = 2.5
	baseLight.Parent = root

	-- TORSO
	local torso = newPart(model, "Torso", V3(16, 13, 9), BASALT)
	bd.torso = torso
	bd.rootJoint = joint("RootJoint", root, torso, CF(0, 2, 0), CF(0, -6.5, 0))
	hitbox(torso, V3(17, 14, 10), CF(0, 0, 0))
	for _, y in ipairs({ -4.2, 4.6 }) do
		solid(torso, "Band", V3(16.5, 0.9, 9.5), GOLD, CF(0, y, 0), nil, Enum.Material.Neon)
	end

	-- tungku di dada
	bd.core = solid(torso, "MagmaCore", V3(5.8, 5.8, 5.8), LAVA_HOT, CF(0, 0.5, -4.4), Enum.PartType.Ball, Enum.Material.Neon)
	local coreLight = Instance.new("PointLight")
	coreLight.Color = LAVA
	coreLight.Range = 40
	coreLight.Brightness = 3
	coreLight.Parent = bd.core
	bd.coreLight = coreLight
	solid(torso, "FurnaceL", V3(1.6, 8.6, 1.6), CHAR, CF(-3.9, 0.5, -4.9))
	solid(torso, "FurnaceR", V3(1.6, 8.6, 1.6), CHAR, CF(3.9, 0.5, -4.9))
	solid(torso, "FurnaceTop", V3(9.4, 1.6, 1.6), CHAR, CF(0, 4.8, -4.9))
	solid(torso, "FurnaceBottom", V3(9.4, 1.6, 1.6), CHAR, CF(0, -3.8, -4.9))
	for _, x in ipairs({ -1.9, 0, 1.9 }) do
		solid(torso, "Grate", V3(0.7, 7, 0.7), CHAR, CF(x, 0.5, -7.6))
	end

	-- cerobong di punggung
	for _, sx in ipairs({ -1, 1 }) do
		solid(torso, "Chimney", V3(3.4, 10, 3.4), CHAR, CF(sx * 6.2, 5, 6.2))
		glowPart(torso, "ChimneyRim", V3(3.9, 0.6, 3.9), CF(sx * 6.2, 10.2, 6.2))
		emit(torso, CF(sx * 6.2, 11, 6.2), TEX_FIRE, {
			Rate = 22, Lifetime = NumberRange.new(0.9, 1.5), Speed = NumberRange.new(6, 11),
			SpreadAngle = Vector2.new(15, 15), Size = NumberSequence.new(4, 1),
			Transparency = NumberSequence.new(0.2, 1), Color = ColorSequence.new(LAVA_HOT, DARKRED), LightEmission = 1,
		})
		emit(torso, CF(sx * 6.2, 11, 6.2), TEX_SMOKE, {
			Rate = 7, Lifetime = NumberRange.new(3, 4), Speed = NumberRange.new(4, 7),
			Size = NumberSequence.new(5, 15), Transparency = NumberSequence.new(0.5, 1),
			Color = ColorSequence.new(Color3.fromRGB(35, 30, 30)),
		})
	end

	-- BAHU CAKRAM
	for _, sx in ipairs({ -1, 1 }) do
		solid(torso, "ShoulderPeg", V3(3, 3, 3), CHAR, CF(sx * 8.7, 5, 0))
		solid(torso, "ShoulderDisc", V3(3, 11, 11), BASALT2, CF(sx * 10.5, 5, 0), Enum.PartType.Cylinder)
		glowPart(torso, "DiscRim", V3(0.6, 11.8, 11.8), CF(sx * 12.15, 5, 0), Enum.PartType.Cylinder)
		for k = 0, 5 do
			local th = k * math.pi / 3
			horn(torso, CF(sx * 10.5, 5 + 5.6 * math.cos(th), 5.6 * math.sin(th)) * CFrame.Angles(th, 0, 0),
				3.8, 1.7, 2, CF(), CHAR, GOLD)
		end
	end

	-- KEPALA: topeng bermata satu dengan mahkota matahari
	solid(torso, "Neck", V3(4, 3, 4), CHAR, CF(0, 7.5, 0))
	local head = newPart(model, "Head", V3(9, 10, 4), BASALT2)
	bd.head = head
	bd.neck = joint("Neck", torso, head, CF(0, 6.8, 0), CF(0, -5.6, 0))
	hitbox(head, V3(10, 11, 5), CF(0, 0, 0))
	local eye = solid(head, "Eye", V3(4.6, 4.6, 4.6), LAVA_HOT, CF(0, 1.4, -2.0), Enum.PartType.Ball, Enum.Material.Neon)
	table.insert(bd.eyes, eye)
	solid(head, "Pupil", V3(0.9, 4.2, 0.4), Color3.new(0, 0, 0), CF(0, 1.4, -4.3))
	for _, sx in ipairs({ -1, 1 }) do
		solid(head, "Brow", V3(5, 1.1, 1.2), CHAR, CF(sx * 2.7, 4.2, -2.2) * CFrame.Angles(0, 0, sx * 0.3))
		horn(head, CF(sx * 4.5, -1, 0) * CFrame.Angles(0, 0, -sx * 1.2), 3.5, 1.4, 2, CF(), CHAR, GOLD)
	end
	glowPart(head, "Mouth", V3(5.4, 0.8, 0.4), CF(0, -3.2, -2.05))
	for i = -2, 2 do
		solid(head, "Tooth", V3(0.7, 1.8, 0.5), TOOTH, CF(i * 1.1, -3.2, -2.2))
	end
	local headLight = Instance.new("PointLight")
	headLight.Color = LAVA
	headLight.Range = 30
	headLight.Brightness = 2
	headLight.Parent = head

	local matt = Instance.new("Attachment")
	matt.CFrame = CF(0, -3.2, -2.4)
	matt.Parent = head
	bd.mouthFx = makeEmitter(matt, TEX_FIRE, {
		Rate = 160, Lifetime = NumberRange.new(0.7, 1.0), Speed = NumberRange.new(55, 70),
		SpreadAngle = Vector2.new(14, 14), Size = NumberSequence.new(5, 16),
		Transparency = NumberSequence.new(0.1, 1), Color = ColorSequence.new(LAVA_HOT, Color3.fromRGB(200, 40, 0)),
		LightEmission = 1, Enabled = false,
	})
	bd.mouthFx.EmissionDirection = Enum.NormalId.Front

	-- mahkota matahari (berputar)
	local crownBase = newPart(model, "CrownBase", V3(1, 1, 1), CHAR, Enum.Material.Neon)
	crownBase.Transparency = 1
	bd.crown = joint("Crown", head, crownBase, CF(0, 1.4, 2.6), CF())
	glowPart(crownBase, "SunDisc", V3(0.5, 12, 12), CF(0, 0, 0.6) * CFrame.Angles(0, rad(90), 0), Enum.PartType.Cylinder).Transparency = 0.55
	for i = 0, 11 do
		local a = i * math.pi / 6
		horn(crownBase, CF(math.sin(a) * 6, math.cos(a) * 6, 0) * CFrame.Angles(0, 0, -a),
			(i % 2 == 0) and 6.5 or 4, 1.5, 2, CF(), CHAR, GOLD)
	end
	emit(head, CF(0, 5, 0), TEX_SPARK, {
		Rate = 20, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(6, 12),
		SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(1.2, 0.2),
		Transparency = NumberSequence.new(0, 1), Color = ColorSequence.new(LAVA_HOT), LightEmission = 1,
		Acceleration = V3(0, 4, 0),
	})

	-- LENGAN BERSENDI (bahu - siku - tinju magma)
	for _, sx in ipairs({ -1, 1 }) do
		local tag = sx < 0 and "Left" or "Right"
		local upper = newPart(model, tag .. "UpperArm", V3(4.6, 8, 4.6), BASALT2)
		local sh = joint(tag .. "Shoulder", torso, upper, CF(sx * 14.5, 4.5, 0), CF(0, 3.6, 0))
		local fore = newPart(model, tag .. "Forearm", V3(5.6, 9, 5.6), BASALT)
		local el = joint(tag .. "Elbow", upper, fore, CF(0, -4, 0), CF(0, 3.8, 0))
		if sx < 0 then
			bd.lSh, bd.lEl = sh, el
		else
			bd.rSh, bd.rEl = sh, el
		end
		hitbox(upper, V3(6, 9, 6), CF())
		hitbox(fore, V3(7, 10, 7), CF())
		solid(fore, "Bracer", V3(6.4, 1.1, 6.4), GOLD, CF(0, 2.6, 0), nil, Enum.Material.Neon)
		horn(upper, CF(sx * 2.6, -3.8, 0) * CFrame.Angles(0, 0, -sx * 1.35), 5, 2, 3, CFrame.Angles(0, 0, -sx * 0.1), CHAR, GOLD)
		glowPart(fore, "MagmaFist", V3(7.4, 7.4, 7.4), CF(0, -6.4, 0), Enum.PartType.Ball)
		for i = -1, 1 do
			horn(fore, CF(i * 2.2, -8.6, -2) * CFrame.Angles(rad(200), 0, 0), 4, 1.7, 2, CF(), CHAR, GOLD)
		end
	end

	-- CINCIN RUNE BERPUTAR
	for r, y in ipairs({ -5.5, 1.5 }) do
		local rb = newPart(model, "RingBase", V3(1, 1, 1), CHAR, Enum.Material.Neon)
		rb.Transparency = 1
		bd.rings[r] = joint("Ring" .. r, torso, rb, CF(0, y, 0), CF())
		for i = 0, 11 do
			local a = i * math.pi / 6
			glowPart(rb, "RuneSeg", V3(5.5, 0.6, 1.8), CF(math.sin(a) * 21, 0, math.cos(a) * 21) * CFrame.Angles(0, a, 0))
		end
	end

	-- PECAHAN KRISTAL MELAYANG
	for i = 1, 5 do
		local shard = newPart(model, "Shard", V3(3.2, 9, 3.2), LAVA_HOT, Enum.Material.Neon)
		bd.orbits[i] = joint("Orbit" .. i, root, shard, CF(0, 14, 0), CF())
		table.insert(bd.glow, shard)
	end

	-- PARTIKEL
	emit(torso, CF(0, 0, 0), TEX_SPARK, {
		Rate = 24, Lifetime = NumberRange.new(2, 3.2), Speed = NumberRange.new(6, 14),
		SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new(1.2, 0.2),
		Transparency = NumberSequence.new(0, 1), Color = ColorSequence.new(LAVA_HOT), LightEmission = 1,
		Acceleration = V3(0, 4, 0),
	})

	model.Parent = workspace
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	model:SetAttribute("Phase", 1)
	model:SetAttribute("P2", CONFIG.Phase2At)
	model:SetAttribute("P3", CONFIG.Phase3At)
	return bd
end

return { build = buildBoss }

