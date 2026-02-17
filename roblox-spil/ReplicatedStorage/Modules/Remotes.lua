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
