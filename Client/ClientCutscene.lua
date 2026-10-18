--[[
MODULESCRIPT bernama: ClientCutscene
Anak dari LocalScript "BossSystemClient". Isi: cutscene boss muncul + cutscene boss kalah.
]]
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local K = require(script.Parent.ClientCore)
local UI = require(script.Parent.ClientUI)
local gui, makeLabel, fadeIn, fadeOut = K.gui, K.makeLabel, K.fadeIn, K.fadeOut

local Cut = {}
local active = false

local function showBanner(bossName)
	local holder = Instance.new("Frame")
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromScale(1, 1)
	holder.ZIndex = 20
	holder.Parent = gui

	local title = makeLabel(holder, "BOSS HAS APPEARED", Enum.Font.GothamBlack, Color3.fromRGB(255, 80, 30),
		UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.9, 0.13), 72, 21)
	local scale = Instance.new("UIScale")
	scale.Scale = 2.4
	scale.Parent = title
	fadeIn(title, 0.25)
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local sub = makeLabel(holder, "", Enum.Font.GothamBold, Color3.fromRGB(255, 220, 150),
		UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.07), 36, 21)
	sub.TextTransparency = 0
	sub.TextStrokeTransparency = 0
	task.spawn(function()
		task.wait(0.4)
		for i = 1, #bossName do
			sub.Text = string.sub(bossName, 1, i)
			task.wait(0.045)
		end
	end)

	return function()
		fadeOut(title, 0.5)
		fadeOut(sub, 0.5)
		task.delay(0.6, function()
			holder:Destroy()
		end)
	end
end

local function say(speaker, text, typeTime, hold)
	local lbl = makeLabel(gui, "", Enum.Font.GothamBlack, Color3.fromRGB(255, 190, 70),
		UDim2.fromScale(0.5, 0.82), UDim2.fromScale(0.9, 0.08), 40, 22)
	lbl.TextTransparency = 0
	lbl.TextStrokeTransparency = 0
	local n = #text
	task.spawn(function()
		for i = 1, n do
			lbl.Text = speaker .. ": " .. string.sub(text, 1, i)
			task.wait(typeTime / n)
		end
		task.wait(hold)
		fadeOut(lbl, 0.5)
		task.delay(0.6, function()
			lbl:Destroy()
		end)
	end)
end

local function safeLook(look)
	if typeof(look) == "Vector3" and look.Magnitude > 0.1 then
		return look.Unit
	end
	return Vector3.new(0, 0, -1)
end

local function runShots(bindName, shots, onTick)
	local camera = workspace.CurrentCamera
	local total = 0
	for _, s in ipairs(shots) do
		total = total + s.dur
	end
	local t0 = os.clock()
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Camera.Value, function()
		local el = os.clock() - t0
		local shot = shots[#shots]
		local lt = shot.dur
		local acc = 0
		for _, s in ipairs(shots) do
			if el < acc + s.dur then
				shot = s
				lt = el - acc
				break
			end
			acc = acc + s.dur
		end
		local a = math.clamp(lt / shot.dur, 0, 1)
		local e = a * a * (3 - 2 * a)
		camera.CFrame = CFrame.lookAt(shot.p0:Lerp(shot.p1, e), shot.l0:Lerp(shot.l1, e))
		camera.FieldOfView = shot.f0 + (shot.f1 - shot.f0) * e
		if onTick then onTick(el) end
	end)
	while os.clock() - t0 < total do
		task.wait()
	end
	RunService:UnbindFromRenderStep(bindName)
end

-- boss muncul (9.6 detik). G = posisi tanah boss, look = arah hadap boss
function Cut.playIntro(bossName, G, look)
	if active then return end
	active = true
	look = safeLook(look)
	local camera = workspace.CurrentCamera
	local oldFov = camera.FieldOfView
	K.setControls(false)
	local closeBars = K.makeBars()
	camera.CameraType = Enum.CameraType.Scriptable

	local frame = CFrame.new(G, G + look)
	local function W(x, y, z)
		return frame:PointToWorldSpace(Vector3.new(x, y, z))
	end
	local shots = {
		{ dur = 3.6, p0 = W(-72, 6, -110), p1 = W(-50, 12, -90), l0 = W(0, 6, 0), l1 = W(0, 16, 0), f0 = 70, f1 = 66 },
		{ dur = 3.2, p0 = W(40, 18, -78), p1 = W(14, 36, -56), l0 = W(0, 30, 0), l1 = W(0, 38, 0), f0 = 70, f1 = 58 },
		{ dur = 2.8, p0 = W(0, 42, -50), p1 = W(0, 43, -36), l0 = W(0, 37, 0), l1 = W(0, 39, 0), f0 = 58, f1 = 46 },
	}
	local hideBanner
	runShots("BossCutscene", shots, function(el)
		if not hideBanner and el >= 6.0 then
			hideBanner = showBanner(bossName)
		end
	end)
	if hideBanner then hideBanner() end
	closeBars()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = oldFov
	K.setControls(true)
	UI.showBossBar(bossName)
	active = false
end

-- boss kalah (11.2 detik)
function Cut.playDefeat(bossName, G, look)
	if active then return end
	active = true
	UI.removeBar()
	look = safeLook(look)
	local camera = workspace.CurrentCamera
	local oldFov = camera.FieldOfView
	K.setControls(false)
	local closeBars = K.makeBars()
	camera.CameraType = Enum.CameraType.Scriptable

	local frame = CFrame.new(G, G + look)
	local function W(x, y, z)
		return frame:PointToWorldSpace(Vector3.new(x, y, z))
	end
	local shots = {
		{ dur = 3.0, p0 = W(0, 14, -58), p1 = W(0, 16, -44), l0 = W(0, 26, 0), l1 = W(0, 28, 0), f0 = 66, f1 = 58 },
		{ dur = 3.6, p0 = W(10, 34, -30), p1 = W(4, 30, -22), l0 = W(0, 36, 0), l1 = W(0, 24, 0), f0 = 50, f1 = 42 },
		{ dur = 4.6, p0 = W(66, 28, -62), p1 = W(56, 40, -58), l0 = W(0, 10, 0), l1 = W(0, 6, 0), f0 = 70, f1 = 66 },
	}
	local speaker = string.match(bossName, "^[^,]+") or bossName
	task.delay(0.8, function()
		say(speaker, "NOOOO...!", 1.6, 0.8)
	end)
	task.delay(3.4, function()
		say(speaker, "I WILL COME BACK AGAIN!", 2.4, 1.2)
	end)
	task.delay(9.0, function()
		K.flashText("BOSS DEFEATED", Color3.fromRGB(255, 215, 80), 2.4)
	end)
	runShots("BossDefeatCam", shots)
	closeBars()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = oldFov
	K.setControls(true)
	active = false
end

return Cut
