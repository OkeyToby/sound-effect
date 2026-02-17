local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(modules.Config)
local PlayerData = require(modules.PlayerData)
local Remotes = require(modules.Remotes)

local refs = Remotes.bootstrap()
local dataStore = DataStoreService:GetDataStore(Config.DATABSTORE_KEY)

local DataService = {}
local cache = {}

local function serialize(state)
	return {
		Coins = state.Coins,
		XP = state.XP,
		Level = state.Level,
		Tokens = state.Tokens,
		UnlockedSkills = state.UnlockedSkills,
	}
end

local function pushToClient(player)
	local state = cache[player.UserId]
	if not state then
		return
	end
	refs.PlayerDataSync:FireClient(player, serialize(state))
end

function DataService.Get(player)
	return cache[player.UserId]
end

function DataService.AddRewards(player, rewards)
	local state = DataService.Get(player)
	if not state then
		return
	end

	state.Coins += rewards.Coins or 0
	state.Tokens += rewards.Tokens or 0
	PlayerData.applyXP(state, rewards.XP or 0)

	pushToClient(player)
end

function DataService.TryUnlockSkill(player, skillName, tokenCost)
	local state = DataService.Get(player)
	if not state then
		return false, "Ingen data"
	end

	if state.Tokens < tokenCost then
		return false, "Ikke nok LeafTokens"
	end

	if PlayerData.unlockSkill(state, skillName) then
		state.Tokens -= tokenCost
		pushToClient(player)
		return true
	end

	return false, "Skill er allerede låst op"
end

local function loadPlayer(player)
	local key = tostring(player.UserId)
	local state = PlayerData.new()

	local ok, data = pcall(function()
		return dataStore:GetAsync(key)
	end)

	if ok and type(data) == "table" then
		state.Coins = tonumber(data.Coins) or 0
		state.XP = tonumber(data.XP) or 0
		state.Level = math.max(1, tonumber(data.Level) or 1)
		state.Tokens = tonumber(data.Tokens) or 0
		state.UnlockedSkills = type(data.UnlockedSkills) == "table" and data.UnlockedSkills or {}
	end

	cache[player.UserId] = state
	pushToClient(player)
end

local function savePlayer(player)
	local state = cache[player.UserId]
	if not state then
		return
	end

	local key = tostring(player.UserId)
	local payload = serialize(state)

	pcall(function()
		dataStore:UpdateAsync(key, function()
			return payload
		end)
	end)
end

Players.PlayerAdded:Connect(loadPlayer)
Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	cache[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)

_G.MonkeyCanopyDataService = DataService
