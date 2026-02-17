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
