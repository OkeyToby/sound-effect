local Config = require(script.Parent.Config)

local PlayerData = {}

PlayerData.Default = {
	Coins = 0,
	XP = 0,
	Level = 1,
	Tokens = 0,
	UnlockedSkills = {},
}

local function deepClone(source)
	local clone = {}
	for key, value in pairs(source) do
		if type(value) == "table" then
			clone[key] = deepClone(value)
		else
			clone[key] = value
		end
	end
	return clone
end

function PlayerData.new()
	return deepClone(PlayerData.Default)
end

function PlayerData.requiredXP(level)
	if level <= 1 then
		return Config.PROGRESSION.BaseXPForLevel
	end
	return Config.PROGRESSION.BaseXPForLevel + ((level - 1) * Config.PROGRESSION.GrowthPerLevel)
end

function PlayerData.applyXP(state, amount)
	state.XP += amount

	while state.Level < Config.PROGRESSION.MaxLevel do
		local needed = PlayerData.requiredXP(state.Level)
		if state.XP < needed then
			break
		end
		state.XP -= needed
		state.Level += 1
	end
end

function PlayerData.unlockSkill(state, skillName)
	if not state.UnlockedSkills[skillName] then
		state.UnlockedSkills[skillName] = true
		return true
	end
	return false
end

return PlayerData
