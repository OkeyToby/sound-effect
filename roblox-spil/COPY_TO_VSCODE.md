# Copy-paste pakke til VS Code (Monkey Canopy Dash)

Du bad om noget der er nemt at kopiere direkte over i VS Code.
Her er alt samlet med **filsti + kode**.

## 1) Opret mapper i VS Code

```bash
mkdir -p roblox-spil/ReplicatedStorage/Modules
mkdir -p roblox-spil/ServerScriptService
mkdir -p roblox-spil/StarterPlayerScripts
```

## 2) Opret filer (kopiér blokke 1:1)

### `roblox-spil/ReplicatedStorage/Modules/Config.lua`
```lua
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
```

### `roblox-spil/ReplicatedStorage/Modules/Remotes.lua`
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)

local Remotes = {}

function Remotes.getFolder()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

function Remotes.ensureRemote(name, className)
	local folder = Remotes.getFolder()
	local remote = folder:FindFirstChild(name)
	if remote and remote.ClassName == className then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	remote = Instance.new(className)
	remote.Name = name
	remote.Parent = folder
	return remote
end

function Remotes.bootstrap()
	local refs = {}
	refs.PlayerDataSync = Remotes.ensureRemote(Config.REMOTES.PlayerDataSync, "RemoteEvent")
	refs.RunStateSync = Remotes.ensureRemote(Config.REMOTES.RunStateSync, "RemoteEvent")
	refs.RequestRunStart = Remotes.ensureRemote(Config.REMOTES.RequestRunStart, "RemoteEvent")
	refs.RequestFinish = Remotes.ensureRemote(Config.REMOTES.RequestFinish, "RemoteEvent")
	refs.RequestSwing = Remotes.ensureRemote(Config.REMOTES.RequestSwing, "RemoteEvent")
	refs.SwingEffect = Remotes.ensureRemote(Config.REMOTES.SwingEffect, "RemoteEvent")
	refs.SystemMessage = Remotes.ensureRemote(Config.REMOTES.SystemMessage, "RemoteEvent")
	return refs
end

return Remotes
```

### `roblox-spil/ReplicatedStorage/Modules/PlayerData.lua`
```lua
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
```

### `roblox-spil/ServerScriptService/DataService.lua`
```lua
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
```

### `roblox-spil/ServerScriptService/RunService.lua`
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(modules.Config)
local Remotes = require(modules.Remotes)

local refs = Remotes.bootstrap()

local activeRuns = {}

local function getDataService()
	return _G.MonkeyCanopyDataService
end

local function sendRunState(player, state)
	refs.RunStateSync:FireClient(player, state)
end

local function createCharacterLook(player)
	local character = player.Character
	if not character then
		return
	end

	if character:FindFirstChild("MonkeyHat") then
		return
	end

	local hat = Instance.new("Part")
	hat.Name = "MonkeyHat"
	hat.Shape = Enum.PartType.Ball
	hat.Size = Vector3.new(1.2, 1.2, 1.2)
	hat.Color = Color3.fromRGB(120, 72, 32)
	hat.CanCollide = false
	hat.Massless = true
	hat.Parent = character

	local head = character:FindFirstChild("Head")
	if head then
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hat
		weld.Part1 = head
		weld.Parent = hat
		hat.CFrame = head.CFrame * CFrame.new(0, 0.9, 0)
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		createCharacterLook(player)
	end)
end)

refs.RequestRunStart.OnServerEvent:Connect(function(player)
	if activeRuns[player.UserId] then
		return
	end

	activeRuns[player.UserId] = {
		StartedAt = os.clock(),
		Bananas = 0,
		Leaves = 0,
	}

	sendRunState(player, {
		IsRunning = true,
		StartedAt = activeRuns[player.UserId].StartedAt,
		Duration = Config.RUN.Duration,
	})
end)

local function finishRun(player)
	local run = activeRuns[player.UserId]
	if not run then
		return false
	end

	local elapsed = os.clock() - run.StartedAt
	if elapsed < Config.RUN.MinimumFinishTime then
		refs.SystemMessage:FireClient(player, "For hurtig finish - run blev ikke godkendt.")
		return false
	end

	activeRuns[player.UserId] = nil

	local timeLeft = math.max(0, Config.RUN.Duration - math.floor(elapsed))
	local rewards = {
		Coins = Config.RUN.BaseGoalRewardCoins
			+ (run.Bananas * Config.RUN.BananaCoinValue)
			+ (run.Leaves * Config.RUN.LeafTokenValue)
			+ (timeLeft * Config.RUN.TimeBonusPerSecond),
		Tokens = run.Leaves,
		XP = Config.RUN.BaseGoalRewardXP + (run.Leaves * Config.RUN.LeafTokenXP) + run.Bananas,
	}

	local dataService = getDataService()
	if dataService then
		dataService.AddRewards(player, rewards)
	end

	sendRunState(player, { IsRunning = false })
	refs.SystemMessage:FireClient(player, string.format("Run complete! +%d coins, +%d xp, +%d tokens", rewards.Coins, rewards.XP, rewards.Tokens))
	return true
end

refs.RequestFinish.OnServerEvent:Connect(function(player, finishPart)
	if typeof(finishPart) == "Instance" and CollectionService:HasTag(finishPart, Config.TAGS.FinishZone) then
		finishRun(player)
	end
end)

refs.RequestSwing.OnServerEvent:Connect(function(player, swingPoint)
	if typeof(swingPoint) ~= "Instance" or not CollectionService:HasTag(swingPoint, Config.TAGS.SwingPoint) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	if (root.Position - swingPoint.Position).Magnitude > 40 then
		return
	end

	local direction = (swingPoint.Position - root.Position).Unit
	root.AssemblyLinearVelocity = direction * 70 + Vector3.new(0, 35, 0)
	refs.SwingEffect:FireAllClients(root.Position, swingPoint.Position)
end)

_G.MonkeyCanopyRunService = {
	GetRun = function(player)
		return activeRuns[player.UserId]
	end,
	FinishRun = finishRun,
}
```

### `roblox-spil/ServerScriptService/Collectibles.lua`
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(modules.Config)
local Remotes = require(modules.Remotes)

Remotes.bootstrap()
local pickupDebounce = {}

local function getRunService()
	return _G.MonkeyCanopyRunService
end

local function getDataService()
	return _G.MonkeyCanopyDataService
end

local function getPlayerFromPart(hit)
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function pickup(item, player, kind)
	local key = item:GetDebugId() .. ":" .. player.UserId
	if pickupDebounce[key] then
		return
	end
	pickupDebounce[key] = true

	local runService = getRunService()
	local run = runService and runService.GetRun(player)
	if run then
		if kind == Config.TAGS.BananaCrystal then
			run.Bananas += 1
		elseif kind == Config.TAGS.LeafToken then
			run.Leaves += 1
		end
	end

	item.Transparency = 1
	item.CanTouch = false
	task.delay(8, function()
		if item and item.Parent then
			item.Transparency = 0
			item.CanTouch = true
		end
		pickupDebounce[key] = nil
	end)
end

local function bindCollectible(item, kind)
	if item:GetAttribute("CollectibleBound") then
		return
	end
	item:SetAttribute("CollectibleBound", true)
	item.Touched:Connect(function(hit)
		local player = getPlayerFromPart(hit)
		if player then
			pickup(item, player, kind)
		end
	end)
end

local function bindFinishZone(zone)
	if zone:GetAttribute("FinishBound") then
		return
	end
	zone:SetAttribute("FinishBound", true)
	zone.Touched:Connect(function(hit)
		local player = getPlayerFromPart(hit)
		local runService = getRunService()
		if player and runService then
			runService.FinishRun(player)
		end
	end)
end

local function bindGate(gate)
	if gate:GetAttribute("GateBound") then
		return
	end
	gate:SetAttribute("GateBound", true)
	gate.Touched:Connect(function(hit)
		local player = getPlayerFromPart(hit)
		if not player then
			return
		end
		local dataService = getDataService()
		local state = dataService and dataService.Get(player)
		if not state then
			return
		end
		if state.Level < Config.PROGRESSION.GateLevel then
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyLinearVelocity = Vector3.new(0, 30, 0)
				root.CFrame = root.CFrame + Vector3.new(0, 0, -7)
			end
		end
	end)
end

for _, item in ipairs(CollectionService:GetTagged(Config.TAGS.BananaCrystal)) do
	bindCollectible(item, Config.TAGS.BananaCrystal)
end
CollectionService:GetInstanceAddedSignal(Config.TAGS.BananaCrystal):Connect(function(item)
	bindCollectible(item, Config.TAGS.BananaCrystal)
end)

for _, item in ipairs(CollectionService:GetTagged(Config.TAGS.LeafToken)) do
	bindCollectible(item, Config.TAGS.LeafToken)
end
CollectionService:GetInstanceAddedSignal(Config.TAGS.LeafToken):Connect(function(item)
	bindCollectible(item, Config.TAGS.LeafToken)
end)

for _, zone in ipairs(CollectionService:GetTagged(Config.TAGS.FinishZone)) do
	bindFinishZone(zone)
end
CollectionService:GetInstanceAddedSignal(Config.TAGS.FinishZone):Connect(bindFinishZone)

for _, gate in ipairs(CollectionService:GetTagged(Config.TAGS.LevelGate)) do
	bindGate(gate)
end
CollectionService:GetInstanceAddedSignal(Config.TAGS.LevelGate):Connect(bindGate)
```

### `roblox-spil/StarterPlayerScripts/UI.client.lua`
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local dataSync = remotes:WaitForChild("PlayerDataSync")
local runSync = remotes:WaitForChild("RunStateSync")
local startRun = remotes:WaitForChild("RequestRunStart")
local systemMessage = remotes:WaitForChild("SystemMessage")

local gui = Instance.new("ScreenGui")
gui.Name = "MonkeyCanopyHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local info = Instance.new("TextLabel")
info.Size = UDim2.new(0, 420, 0, 120)
info.Position = UDim2.new(0, 16, 0, 16)
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.BackgroundTransparency = 0.3
info.TextScaled = false
info.TextSize = 22
info.Font = Enum.Font.GothamBold
info.Parent = gui

local timer = Instance.new("TextLabel")
timer.Size = UDim2.new(0, 220, 0, 50)
timer.Position = UDim2.new(0.5, -110, 0, 16)
timer.BackgroundTransparency = 0.3
timer.TextScaled = true
timer.Font = Enum.Font.GothamBold
timer.Text = "Run Timer: --"
timer.Parent = gui

local message = Instance.new("TextLabel")
message.Size = UDim2.new(0, 500, 0, 55)
message.Position = UDim2.new(0.5, -250, 0, 72)
message.BackgroundTransparency = 0.5
message.TextScaled = true
message.Font = Enum.Font.Gotham
message.Text = "Tryk [R] for at starte et run"
message.Parent = gui

local state = {
	Coins = 0,
	XP = 0,
	Level = 1,
	Tokens = 0,
	Running = false,
	StartedAt = 0,
	Duration = 0,
}

local function refresh()
	info.Text = string.format(
		"Monkey Canopy Dash\nCoins: %d\nLeafTokens: %d\nLevel: %d (XP: %d)",
		state.Coins,
		state.Tokens,
		state.Level,
		state.XP
	)
end

refresh()

startRun:FireServer()

dataSync.OnClientEvent:Connect(function(payload)
	state.Coins = payload.Coins or state.Coins
	state.XP = payload.XP or state.XP
	state.Level = payload.Level or state.Level
	state.Tokens = payload.Tokens or state.Tokens
	refresh()
end)

runSync.OnClientEvent:Connect(function(payload)
	state.Running = payload.IsRunning
	state.StartedAt = payload.StartedAt or 0
	state.Duration = payload.Duration or state.Duration
	if not state.Running then
		timer.Text = "Run Timer: --"
	end
end)

systemMessage.OnClientEvent:Connect(function(text)
	message.Text = text
end)

task.spawn(function()
	while true do
		if state.Running and state.Duration > 0 then
			local elapsed = os.clock() - state.StartedAt
			local remaining = math.max(0, state.Duration - math.floor(elapsed))
			timer.Text = string.format("Run Timer: %ds", remaining)
		end
		task.wait(0.25)
	end
end)
```

### `roblox-spil/StarterPlayerScripts/Input.client.lua`
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

local modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(modules.Config)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestRunStart = remotes:WaitForChild("RequestRunStart")
local requestSwing = remotes:WaitForChild("RequestSwing")

local function nearestSwingPoint(maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local nearest = nil
	local bestDistance = maxDistance
	for _, point in ipairs(CollectionService:GetTagged(Config.TAGS.SwingPoint)) do
		local dist = (point.Position - root.Position).Magnitude
		if dist < bestDistance then
			bestDistance = dist
			nearest = point
		end
	end
	return nearest
end

local function onStartRun(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		requestRunStart:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

local function onSwing(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		local point = nearestSwingPoint(40)
		if point then
			requestSwing:FireServer(point)
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("StartMonkeyRun", onStartRun, true, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
ContextActionService:SetTitle("StartMonkeyRun", "Start Run")
ContextActionService:SetPosition("StartMonkeyRun", UDim2.new(1, -150, 1, -120))

ContextActionService:BindAction("MonkeySwing", onSwing, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("MonkeySwing", "Swing")
ContextActionService:SetPosition("MonkeySwing", UDim2.new(1, -150, 1, -60))
```

### `roblox-spil/StarterPlayerScripts/Effects.client.lua`
```lua
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local swingEffect = remotes:WaitForChild("SwingEffect")

swingEffect.OnClientEvent:Connect(function(fromPos, toPos)
	local a = Instance.new("Part")
	a.Anchored = true
	a.CanCollide = false
	a.Transparency = 1
	a.Position = fromPos
	a.Parent = Workspace

	local b = Instance.new("Part")
	b.Anchored = true
	b.CanCollide = false
	b.Transparency = 1
	b.Position = toPos
	b.Parent = Workspace

	local att0 = Instance.new("Attachment")
	att0.Parent = a
	local att1 = Instance.new("Attachment")
	att1.Parent = b

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Color = ColorSequence.new(Color3.fromRGB(111, 255, 96))
	beam.Width0 = 0.2
	beam.Width1 = 0.2
	beam.FaceCamera = true
	beam.Parent = a

	Debris:AddItem(a, 0.2)
	Debris:AddItem(b, 0.2)
end)
```

---

## 3) Hurtig checkliste før Play
- Alle scripts placeret i korrekt Explorer-placering.
- Dine map parts er tagget (`BananaCrystal`, `LeafToken`, `FinishZone`, `SwingPoint`, `LevelGate`).
- Test i Play: `R` starter run, `E` swinger.

Hvis du vil, kan jeg bagefter lave en **ekstra fil med kun zipline-systemet** som du også kan copy-paste direkte.
