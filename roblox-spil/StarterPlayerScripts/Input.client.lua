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
