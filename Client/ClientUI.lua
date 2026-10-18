--[[
MODULESCRIPT bernama: ClientUI
Anak dari LocalScript "BossSystemClient". Isi: health bar boss + penanda fase, nama skill,
countdown Cataclysm, efek layar merah saat kena damage.
]]
local TweenService = game:GetService("TweenService")
local K = require(script.Parent.ClientCore)
local gui, makeLabel, fadeIn, fadeOut = K.gui, K.makeLabel, K.fadeIn, K.fadeOut

local UI = {}
UI.PHASE_COL = { Color3.fromRGB(255, 90, 20), Color3.fromRGB(255, 55, 35), Color3.fromRGB(255, 215, 70) }
local PHASE_COL = UI.PHASE_COL
local PHASE_TXT = { "PHASE I", "PHASE II - INFERNO", "PHASE III - ENRAGED" }

--========================  EFEK KENA DAMAGE  ========================
local hurt = Instance.new("Frame")
hurt.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
hurt.BackgroundTransparency = 1
hurt.BorderSizePixel = 0
hurt.Size = UDim2.fromScale(1, 1)
hurt.ZIndex = 4
hurt.Parent = gui

local function hurtFlash(frac)
	hurt.BackgroundTransparency = math.clamp(0.88 - frac * 1.2, 0.55, 0.88)
	TweenService:Create(hurt, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	K.addShake(0.4 + frac * 3, 0.25)
end

local function watchCharacter(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then return end
	local last = hum.Health
	hum.HealthChanged:Connect(function(h)
		if h < last - 1 then
			hurtFlash((last - h) / math.max(hum.MaxHealth, 1))
		end
		last = h
	end)
end

K.player.CharacterAdded:Connect(watchCharacter)
if K.player.Character then
	task.spawn(watchCharacter, K.player.Character)
end

--========================  COUNTDOWN  ========================
local countLabel = makeLabel(gui, "", Enum.Font.GothamBlack, Color3.fromRGB(120, 230, 255),
	UDim2.fromScale(0.5, 0.62), UDim2.fromScale(0.9, 0.1), 54, 30)
local countScale = Instance.new("UIScale")
countScale.Parent = countLabel

function UI.showCountdown(n, text)
	if n <= 0 then
		fadeOut(countLabel, 0.3)
		return
	end
	countLabel.Text = text .. "  [" .. n .. "]"
	countLabel.TextTransparency = 0
	countLabel.TextStrokeTransparency = 0
	countScale.Scale = 1.35
	TweenService:Create(countScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

--========================  HEALTH BAR BOSS  ========================
local barFrame, skillLbl, phaseLbl
local skillToken = 0

function UI.removeBar()
	if barFrame then
		barFrame:Destroy()
		barFrame = nil
		skillLbl = nil
		phaseLbl = nil
	end
end

function UI.showSkill(text)
	if not skillLbl then return end
	skillToken = skillToken + 1
	local my = skillToken
	skillLbl.Text = text
	skillLbl.TextTransparency = 0
	skillLbl.TextStrokeTransparency = 0.2
	task.delay(1.8, function()
		if my == skillToken and skillLbl then
			fadeOut(skillLbl, 0.5)
		end
	end)
end

function UI.showBossBar(bossName)
	UI.removeBar()
	local model = workspace:FindFirstChild("LavaBoss")
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, -0.1)
	frame.Size = UDim2.fromScale(0.5, 0.075)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	barFrame = frame

	local name = makeLabel(frame, bossName, Enum.Font.GothamBlack, Color3.fromRGB(255, 200, 120),
		UDim2.fromScale(0.5, 0.22), UDim2.fromScale(1, 0.44), 26, 2)
	fadeIn(name, 0.3)

	local back = Instance.new("Frame")
	back.Position = UDim2.fromScale(0, 0.48)
	back.Size = UDim2.fromScale(1, 0.5)
	back.BackgroundColor3 = Color3.fromRGB(25, 10, 10)
	back.BorderSizePixel = 0
	back.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 120, 40)
	stroke.Thickness = 2
	stroke.Parent = back
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = back

	local ghost = Instance.new("Frame")
	ghost.Size = UDim2.fromScale(1, 1)
	ghost.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
	ghost.BorderSizePixel = 0
	ghost.ZIndex = 1
	ghost.Parent = back
	local gc = Instance.new("UICorner")
	gc.CornerRadius = UDim.new(0, 6)
	gc.Parent = ghost

	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = PHASE_COL[1]
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = back
	local fc = Instance.new("UICorner")
	fc.CornerRadius = UDim.new(0, 6)
	fc.Parent = fill

	for _, attr in ipairs({ "P2", "P3" }) do
		local v = model:GetAttribute(attr)
		if v then
			local tick = Instance.new("Frame")
			tick.AnchorPoint = Vector2.new(0.5, 0)
			tick.Position = UDim2.fromScale(v, 0)
			tick.Size = UDim2.new(0, 3, 1, 0)
			tick.BackgroundColor3 = Color3.new(0, 0, 0)
			tick.BorderSizePixel = 0
			tick.ZIndex = 4
			tick.Parent = back
		end
	end

	local hpText = makeLabel(back, "", Enum.Font.GothamBold, Color3.new(1, 1, 1),
		UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 0.8), 18, 5)
	hpText.TextTransparency = 0
	hpText.TextStrokeTransparency = 0.4

	phaseLbl = makeLabel(frame, PHASE_TXT[1], Enum.Font.GothamBold, PHASE_COL[1],
		UDim2.fromScale(0.5, 1.32), UDim2.fromScale(0.6, 0.42), 18, 2)
	phaseLbl.TextTransparency = 0
	phaseLbl.TextStrokeTransparency = 0.3

	skillLbl = makeLabel(frame, "", Enum.Font.GothamBlack, Color3.fromRGB(255, 235, 170),
		UDim2.fromScale(0.5, 1.85), UDim2.fromScale(0.8, 0.5), 26, 2)

	local function currentPhase()
		return math.clamp(model:GetAttribute("Phase") or 1, 1, 3)
	end

	local function update()
		local a = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(a, 1) }):Play()
		TweenService:Create(ghost, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.3),
			{ Size = UDim2.fromScale(a, 1) }):Play()
		hpText.Text = math.ceil(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
		fill.BackgroundColor3 = PHASE_COL[currentPhase()]
	end
	hum.HealthChanged:Connect(update)
	update()

	model:GetAttributeChangedSignal("Phase"):Connect(function()
		local p = currentPhase()
		if phaseLbl then
			phaseLbl.Text = PHASE_TXT[p]
			phaseLbl.TextColor3 = PHASE_COL[p]
		end
		update()
	end)
	model.Destroying:Connect(UI.removeBar)

	TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.05) }):Play()
end

return UI
