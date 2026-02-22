local Config = {}

Config.TAGS = {
	BananaCrystal = "BananaCrystal",
	LeafToken = "LeafToken",
	FinishZone = "FinishZone",
	SwingPoint = "SwingPoint",
	ZiplineStart = "ZiplineStart",
	LevelGate = "LevelGate",
}

Config.RUN = {
	Duration = 180,
	BaseGoalRewardCoins = 30,
	BaseGoalRewardXP = 65,
	TimeBonusPerSecond = 1,
	BananaCoinValue = 2,
	LeafTokenValue = 1,
	LeafTokenXP = 5,
	MinimumFinishTime = 8,
}

Config.PROGRESSION = {
	MaxLevel = 25,
	BaseXPForLevel = 100,
	GrowthPerLevel = 25,
	GateLevel = 5,
}

Config.SKILLS = {
	DoubleJump = "DoubleJump",
	Dash = "Dash",
	SwingBoost = "SwingBoost",
}

Config.REMOTES = {
	PlayerDataSync = "PlayerDataSync",
	RunStateSync = "RunStateSync",
	RequestRunStart = "RequestRunStart",
	RequestFinish = "RequestFinish",
	RequestSwing = "RequestSwing",
	SwingEffect = "SwingEffect",
	SystemMessage = "SystemMessage",
}

Config.DATABSTORE_KEY = "MonkeyCanopyDash_v1"

return Config
