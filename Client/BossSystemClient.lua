--[[
BOSS LAVA v3 - CLIENT UTAMA
LocalScript bernama "BossSystemClient" di StarterPlayer > StarterPlayerScripts.
Buat 3 ModuleScript DI DALAM LocalScript ini dengan nama PERSIS:
ClientCore, ClientUI, ClientCutscene (isi dari file yang namanya sama).
]]
local K = require(script.ClientCore)
local UI = require(script.ClientUI)
local Cut = require(script.ClientCutscene)

K.Remote.OnClientEvent:Connect(function(action, a, b, d)
	if action == "Shake" then
		K.addShake(a, b)
	elseif action == "Flash" then
		K.screenFlash(a, b)
	elseif action == "Cutscene" then
		task.spawn(Cut.playIntro, a, b, d)
	elseif action == "DefeatCutscene" then
		task.spawn(Cut.playDefeat, a, b, d)
	elseif action == "Skill" then
		UI.showSkill(a)
	elseif action == "Phase" then
		K.redFlash()
		K.addShake(1.5, 1.2)
		K.flashText(b or "NEW PHASE", UI.PHASE_COL[math.clamp(a or 2, 1, 3)], 2.2)
	elseif action == "Enraged" then
		task.delay(2.4, function()
			K.flashText("THE TITAN IS ENRAGED!", Color3.fromRGB(255, 60, 30), 2.0, 0.4)
		end)
	elseif action == "Countdown" then
		UI.showCountdown(a, b or "")
	end
end)
