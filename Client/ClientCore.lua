--[[
MODULESCRIPT bernama: ClientCore
Anak dari LocalScript "BossSystemClient". Isi: GUI dasar, camera shake, flash layar, helper teks.
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local K = {}
K.player = Players.LocalPlayer
K.Remote = ReplicatedStorage:WaitForChild("BossEvent")

local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "BossFlash"
cc.Parent = Lighting

function K.screenFlash(color, dur)
	cc.TintColor = color
	cc.Brightness = 0.15
	TweenService:Create(cc, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
end

local gui = Instance.new("ScreenGui")
gui.Name = "BossGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = K.player:WaitForChild("PlayerGui")
K.gui = gui

local shakeMag, shakeEnd, shakeDur = 0, 0, 1
function K.addShake(mag, dur)
	local remain = shakeEnd - os.clock()
	if remain > 0 and shakeMag * (remain / shakeDur) > mag then
		return
	end
	shakeMag = mag
	shakeDur = math.max(dur, 0.05)
	shakeEnd = os.clock() + dur
end

RunService:BindToRenderStep("BossShake", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	if now >= shakeEnd then return end
	local m = shakeMag * ((shakeEnd - now) / shakeDur) * 0.5
	local function r()
		return (math.random() - 0.5) * 2 * m
	end
	local cam = workspace.CurrentCamera
	cam.CFrame = cam.CFrame * CFrame.new(r(), r(), 0) * CFrame.Angles(0, 0, r() * 0.01)
end)

function K.setControls(enabled)
	pcall(function()
		local pm = require(K.player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		local ctl = pm:GetControls()
		if enabled then ctl:Enable() else ctl:Disable() end
	end)
end

function K.makeBars()
	local function bar(anchorY)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0, anchorY)
		f.Position = UDim2.fromScale(0, anchorY)
		f.Size = UDim2.fromScale(1, 0)
		f.ZIndex = 10
		f.Parent = gui
		return f
	end
	local top, bottom = bar(0), bar(1)
	local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(top, info, { Size = UDim2.fromScale(1, 0.12) }):Play()
	TweenService:Create(bottom, info, { Size = UDim2.fromScale(1, 0.12) }):Play()
	return function()
		TweenService:Create(top, info, { Size = UDim2.fromScale(1, 0) }):Play()
		TweenService:Create(bottom, info, { Size = UDim2.fromScale(1, 0) }):Play()
		task.delay(0.7, function()
			top:Destroy()
			bottom:Destroy()
		end)
	end
end

function K.makeLabel(parent, text, font, color, pos, size, maxText, z)
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.Font = font
	l.TextScaled = true
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.TextStrokeTransparency = 1
	l.TextTransparency = 1
	l.ZIndex = z
	l.Parent = parent
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = maxText
	c.Parent = l
	return l
end

function K.fadeIn(l, t)
	TweenService:Create(l, TweenInfo.new(t), { TextTransparency = 0, TextStrokeTransparency = 0 }):Play()
end

function K.fadeOut(l, t)
	TweenService:Create(l, TweenInfo.new(t), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end

function K.flashText(text, color, hold, yPos)
	local l = K.makeLabel(gui, text, Enum.Font.GothamBlack, color,
		UDim2.fromScale(0.5, yPos or 0.3), UDim2.fromScale(0.9, 0.1), 60, 30)
	local scale = Instance.new("UIScale")
	scale.Scale = 2
	scale.Parent = l
	K.fadeIn(l, 0.2)
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	task.delay(hold, function()
		K.fadeOut(l, 0.6)
		task.delay(0.7, function()
			l:Destroy()
		end)
	end)
end

function K.redFlash()
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(255, 30, 0)
	f.BackgroundTransparency = 0.65
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = 5
	f.Parent = gui
	TweenService:Create(f, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
	task.delay(1.3, function()
		f:Destroy()
	end)
end

return K
