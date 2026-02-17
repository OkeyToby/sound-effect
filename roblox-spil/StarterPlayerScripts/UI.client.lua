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
