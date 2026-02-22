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
