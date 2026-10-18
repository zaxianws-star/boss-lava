--[[
BOSS LAVA v3 - SCRIPT UTAMA (dibagi jadi banyak file supaya tidak kena batas kode Studio Lite)

CARA PASANG:
1. Buat Script bernama "BossSystemServer" di ServerScriptService, isi dengan file ini.
2. Di DALAM Script itu, buat ModuleScript dengan nama PERSIS:
   Config, Core, Fx, FxB, Arena, Builder, Anim, SkillsA, SkillsB, Weapons, Fight
   lalu isi tiap ModuleScript dengan file yang namanya sama.
3. Client: LocalScript "BossSystemClient" di StarterPlayerScripts + 3 ModuleScript di dalamnya:
   ClientCore, ClientUI, ClientCutscene.
Boss ke-Part "BossSpawn" di Workspace kalau ada; kalau tidak otomatis 130 stud di depan pemain pertama.
]]
local Core = require(script.Core)
local Fight = require(script.Fight)
local Weapons = require(script.Weapons)
local CONFIG = Core.CONFIG

Weapons.start()

task.spawn(function()
	task.wait(CONFIG.FirstSpawnDelay)
	while true do
		repeat
			task.wait(1)
		until #Core.getTargets() > 0
		local ok, err = pcall(Fight.run)
		if not ok then
			warn("[Boss] error: " .. tostring(err))
			Fight.cleanupAfterError()
		end
		task.wait(CONFIG.RespawnDelay)
	end
end)
