--[[
MODULESCRIPT bernama: Config
Letakkan SEBAGAI ANAK dari Script "BossSystemServer" (ServerScriptService > BossSystemServer > Config).
Semua pengaturan boss ada di sini.
]]
return {
	BossName = "LAVAGOR, THE MOLTEN TITAN",
	SpawnPosition = nil,        -- nil = otomatis. Boleh Vector3 atau Part "BossSpawn" di Workspace
	BuildArena = true,
	Atmosphere = true,
	MaxHealth = 8000,
	HealthPerExtraPlayer = 0.35,
	WalkSpeed = 18,
	DamageMultiplier = 1,
	CataclysmDamage = 400,
	Phase2At = 0.6,
	Phase3At = 0.3,
	FirstSpawnDelay = 6,
	RespawnDelay = 60,
	GiveKillStat = true,
	SoundEnabled = true,
	MasterVolume = 1,
	CustomSounds = {},          -- contoh: roar = "rbxassetid://123456"

	GiveSword = true,           -- tiap pemain otomatis dapat "Pedang Lava" di Backpack
	WeaponFallback = true,      -- senjata apa pun (Toolbox) tetap bisa melukai boss
	WeaponFallbackDamage = 20,  -- damage cadangan per ayunan kalau script senjata tidak mengenai boss
}
