--[[
MODULESCRIPT bernama: FxB
Anak dari Script "BossSystemServer". Isi: efek proyektil & serangan (geyser, meteor, fireball, orb, ombak, duri, angka damage).
]]
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Core = require(script.Parent.Core)
local Fx = require(script.Parent.Fx)

local S, C, TEX = Core.S, Core.C, Core.TEX
local V3, CF, rad, rng = Core.V3, Core.CF, Core.rad, Core.rng
local LAVA, LAVA_HOT = C.LAVA, C.LAVA_HOT
local TEX_FIRE = TEX.FIRE
local hitRadius, dealDamage, getTargets, nearestTarget = Core.hitRadius, Core.dealDamage, Core.getTargets, Core.nearestTarget
local playSfx, shakeNear = Core.playSfx, Core.shakeNear
local fxPart, makeEmitter, shockRing, sparks, explode = Fx.fxPart, Fx.makeEmitter, Fx.shockRing, Fx.sparks, Fx.explode
local warnCircle, lavaPool = Fx.warnCircle, Fx.lavaPool

local FxB = {}

function FxB.geyserAt(pos, radius, dmg, delay, vol)
	warnCircle(pos, radius, delay)
	task.spawn(function()
		task.wait(delay)
		local h = 70
		local gy = S.GROUND_Y
		local col = fxPart(Enum.PartType.Cylinder, V3(h, radius * 1.4, radius * 1.4), LAVA,
			CF(pos.X, gy + h / 2, pos.Z) * CFrame.Angles(0, 0, rad(90)))
		TweenService:Create(col, TweenInfo.new(0.7), { Size = V3(h, radius * 0.4, radius * 0.4), Transparency = 1 }):Play()
		Debris:AddItem(col, 0.8)
		local core = fxPart(Enum.PartType.Cylinder, V3(h * 0.9, radius * 0.7, radius * 0.7), LAVA_HOT,
			CF(pos.X, gy + h * 0.45, pos.Z) * CFrame.Angles(0, 0, rad(90)))
		TweenService:Create(core, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		Debris:AddItem(core, 0.6)
		sparks(V3(pos.X, gy, pos.Z), 8)
		shockRing(pos, radius * 1.3, 0.4)
		playSfx(nil, pos, "geyser", vol or 1)
		hitRadius(pos, radius, dmg, nil, 55)
		shakeNear(pos, 120, 0.7, 0.4)
	end)
end

function FxB.meteorAt(pos, radius, dmg, delay, makePool)
	warnCircle(pos, radius, delay)
	task.spawn(function()
		local gy = S.GROUND_Y
		local m = fxPart(Enum.PartType.Ball, V3(8, 8, 8), LAVA, CF(pos.X, gy + 190, pos.Z))
		local light = Instance.new("PointLight")
		light.Color = LAVA
		light.Range = 40
		light.Brightness = 4
		light.Parent = m
		local att = Instance.new("Attachment")
		att.Parent = m
		makeEmitter(att, TEX_FIRE, {
			Rate = 80, Lifetime = NumberRange.new(0.7), Speed = NumberRange.new(0),
			Size = NumberSequence.new(9, 2), Transparency = NumberSequence.new(0, 1),
			Color = ColorSequence.new(LAVA_HOT, Color3.fromRGB(120, 20, 0)), LightEmission = 1,
		})
		playSfx(m, nil, "whoosh", 0.8)
		local tw = TweenService:Create(m, TweenInfo.new(delay, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = V3(pos.X, gy + 4, pos.Z) })
		tw:Play()
		tw.Completed:Wait()
		m:Destroy()
		explode(V3(pos.X, gy + 1, pos.Z), radius)
		playSfx(nil, pos, "boom", 1.2)
		hitRadius(pos, radius, dmg, nil, 50)
		shakeNear(pos, 140, 0.6, 0.35)
		if makePool then
			lavaPool(pos, radius * 0.9, 7, 14)
		end
	end)
end

function FxB.fireball(origin, dir, speed, dmg)
	local ball = fxPart(Enum.PartType.Ball, V3(5, 5, 5), LAVA, CF(origin))
	local light = Instance.new("PointLight")
	light.Color = LAVA
	light.Range = 30
	light.Brightness = 3
	light.Parent = ball
	local att = Instance.new("Attachment")
	att.Parent = ball
	makeEmitter(att, TEX_FIRE, {
		Rate = 70, Lifetime = NumberRange.new(0.6), Speed = NumberRange.new(0),
		Size = NumberSequence.new(7, 1.5), Transparency = NumberSequence.new(0, 1),
		Color = ColorSequence.new(LAVA_HOT, Color3.fromRGB(150, 30, 0)), LightEmission = 1,
	})
	playSfx(ball, nil, "fireball", 1)
	task.spawn(function()
		local pos = origin
		local life = 0
		local done = false
		while life < 3.5 and not done do
			local dt = RunService.Heartbeat:Wait()
			life = life + dt
			pos = pos + dir * speed * dt
			ball.Position = pos
			for _, t in ipairs(getTargets()) do
				if (t.hrp.Position - pos).Magnitude < 6 then
					done = true
				end
			end
			if pos.Y <= S.GROUND_Y + 2 then
				done = true
			end
		end
		ball:Destroy()
		explode(pos, 9)
		playSfx(nil, pos, "boom", 1)
		hitRadius(pos, 9, dmg, nil, 40)
		shakeNear(pos, 100, 0.5, 0.3)
	end)
end

function FxB.seekerOrb(startPos, delay, dmg)
	local orb = fxPart(Enum.PartType.Ball, V3(4.5, 4.5, 4.5), LAVA_HOT, CF(startPos))
	local light = Instance.new("PointLight")
	light.Color = LAVA
	light.Range = 26
	light.Brightness = 3
	light.Parent = orb
	local att = Instance.new("Attachment")
	att.Parent = orb
	makeEmitter(att, TEX_FIRE, {
		Rate = 60, Lifetime = NumberRange.new(0.5), Speed = NumberRange.new(0),
		Size = NumberSequence.new(6, 1), Transparency = NumberSequence.new(0, 1),
		Color = ColorSequence.new(LAVA_HOT, Color3.fromRGB(150, 30, 0)), LightEmission = 1,
	})
	task.spawn(function()
		TweenService:Create(orb, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Position = startPos + V3(0, 12, 0) }):Play()
		task.wait(0.5 + delay)
		local pos = orb.Position
		local vel = V3(0, 0, 0)
		local life = 0
		playSfx(orb, nil, "ping", 1)
		while life < 6 do
			local dt = RunService.Heartbeat:Wait()
			life = life + dt
			local tg = nearestTarget(pos)
			local want = V3(0, -1, 0)
			if tg then want = (tg.hrp.Position - pos).Unit end
			vel = vel:Lerp(want * 36, math.min(1, dt * 2.2))
			pos = pos + vel * dt
			orb.Position = pos
			if tg and (tg.hrp.Position - pos).Magnitude < 5 then break end
			if pos.Y <= S.GROUND_Y + 2 then break end
		end
		orb:Destroy()
		explode(pos, 10)
		playSfx(nil, pos, "boom", 1)
		hitRadius(pos, 10, dmg, nil, 40)
		shakeNear(pos, 100, 0.5, 0.3)
	end)
end

function FxB.waveRun(origin, dir, speed, length, dmg)
	local right = V3(-dir.Z, 0, dir.X)
	local wall = fxPart(Enum.PartType.Block, V3(62, 9, 5), LAVA, CF(origin))
	wall.Transparency = 0.15
	makeEmitter(wall, TEX_FIRE, {
		Shape = Enum.ParticleEmitterShape.Box, Rate = 250, Lifetime = NumberRange.new(0.8, 1.2),
		Speed = NumberRange.new(2, 6), Size = NumberSequence.new(8, 2), Transparency = NumberSequence.new(0, 1),
		Color = ColorSequence.new(LAVA_HOT, Color3.fromRGB(150, 30, 0)), LightEmission = 1,
	})
	playSfx(wall, nil, "whoosh", 1.3)
	local pos = V3(origin.X, 0, origin.Z)
	local hit = {}
	local traveled = 0
	while traveled < length do
		local dt = RunService.Heartbeat:Wait()
		local step = speed * dt
		pos = pos + dir * step
		traveled = traveled + step
		local wp = V3(pos.X, S.GROUND_Y + 4.5, pos.Z)
		wall.CFrame = CFrame.lookAt(wp, wp + dir)
		for _, t in ipairs(getTargets()) do
			if not hit[t.hum] then
				local rel = t.hrp.Position - pos
				local along = rel.X * dir.X + rel.Z * dir.Z
				local across = rel.X * right.X + rel.Z * right.Z
				if math.abs(along) < 6 and math.abs(across) < 31 and t.hrp.Position.Y - S.GROUND_Y <= 7.5 then
					hit[t.hum] = true
					dealDamage(t.hum, dmg)
					t.hrp.AssemblyLinearVelocity = dir * 55 + V3(0, 40, 0)
				end
			end
		end
	end
	TweenService:Create(wall, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	Debris:AddItem(wall, 0.5)
end

function FxB.spikeAt(pos, delay)
	warnCircle(pos, 7, delay)
	task.delay(delay, function()
		local gy = S.GROUND_Y
		local rot = CFrame.Angles(0, rng:NextNumber(0, 6.28), 0)
		local sp = Instance.new("Part")
		sp.Name = "ObsidianSpike"
		sp.Anchored = true
		sp.CanCollide = false
		sp.Size = V3(6, 20, 6)
		sp.Color = C.OBS
		sp.Material = Enum.Material.Plastic
		sp.TopSurface = Enum.SurfaceType.Studs
		sp.LeftSurface = Enum.SurfaceType.Studs
		sp.RightSurface = Enum.SurfaceType.Studs
		sp.FrontSurface = Enum.SurfaceType.Studs
		sp.BackSurface = Enum.SurfaceType.Studs
		sp.CFrame = CF(pos.X, gy - 11, pos.Z) * rot
		sp.Parent = workspace
		local band = Instance.new("Part")
		band.Anchored = false
		band.CanCollide = false
		band.Massless = true
		band.Size = V3(6.3, 1.3, 6.3)
		band.Color = LAVA
		band.Material = Enum.Material.Neon
		band.CFrame = sp.CFrame * CF(0, 3, 0)
		band.Parent = workspace
		local w = Instance.new("WeldConstraint")
		w.Part0 = sp
		w.Part1 = band
		w.Parent = band
		TweenService:Create(sp, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = CF(pos.X, gy + 8, pos.Z) * rot }):Play()
		hitRadius(pos, 7, 40, nil, 50)
		sparks(pos, 5)
		playSfx(nil, pos, "hit", 1.4)
		shakeNear(pos, 90, 0.3, 0.2)
		task.delay(1.8, function()
			TweenService:Create(sp, TweenInfo.new(0.4), { CFrame = CF(pos.X, gy - 11, pos.Z) * rot }):Play()
			Debris:AddItem(sp, 0.5)
			Debris:AddItem(band, 0.5)
		end)
	end)
end

function FxB.damagePopup(part, amount)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 140, 0, 46)
	bb.StudsOffset = V3(rng:NextNumber(-5, 5), 10, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = tostring(math.floor(amount + 0.5))
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(255, 230, 90)
	l.TextStrokeColor3 = Color3.fromRGB(120, 20, 0)
	l.TextStrokeTransparency = 0
	l.Parent = bb
	TweenService:Create(bb, TweenInfo.new(0.8), { StudsOffset = V3(bb.StudsOffset.X, 18, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(bb, 0.9)
end


return FxB
