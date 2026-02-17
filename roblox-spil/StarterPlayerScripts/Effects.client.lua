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
