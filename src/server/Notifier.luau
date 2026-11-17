-- Notifier: the one place that sends toast messages to players, so no two
-- services need to require each other just to say something.

local Notifier = {}

local notifyRemote = nil

function Notifier.init(remotes)
	notifyRemote = remotes:WaitForChild("Notify")
end

function Notifier.to(player, text, kind)
	if notifyRemote ~= nil then
		notifyRemote:FireClient(player, { text = text, kind = kind or "info" })
	end
end

function Notifier.all(text, kind)
	if notifyRemote ~= nil then
		notifyRemote:FireAllClients({ text = text, kind = kind or "info" })
	end
end

return Notifier
