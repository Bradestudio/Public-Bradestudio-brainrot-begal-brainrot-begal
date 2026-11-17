-- Economy: the money tick. Every second each player earns the sum of their
-- brainrots' rates times their rebirth multiplier, and the server sends a
-- full state snapshot to that player's client so the HUD always shows the
-- true numbers.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Economy = {}

local stateRemote = nil

function Economy.sendState(data, Registry)
	local ownedList = {}
	for _, uid in ipairs(data.owned) do
		local record = Registry.get(uid)
		if record ~= nil then
			table.insert(ownedList, {
				name = Catalog.displayName(record.character, record.mutationKey),
				rarity = record.rarityKey,
				rate = record.rate,
			})
		end
	end
	local lockLeft = 0
	if data.lockUntil > os.time() then
		lockLeft = data.lockUntil - os.time()
	end
	stateRemote:FireClient(data.player, {
		cash = math.floor(data.cash),
		income = PlayerData.incomePerSecond(data, Registry),
		owned = ownedList,
		rebirths = data.rebirths,
		multiplier = data.multiplier,
		lockSecondsLeft = lockLeft,
		carrying = data.carryingUid ~= nil,
	})
end

function Economy.init(remotes, Registry)
	stateRemote = remotes:WaitForChild("StateUpdate")
	task.spawn(function()
		while true do
			task.wait(1)
			for _, data in ipairs(PlayerData.all()) do
				data.cash = data.cash + PlayerData.incomePerSecond(data, Registry)
				Economy.sendState(data, Registry)
			end
		end
	end)
end

return Economy
