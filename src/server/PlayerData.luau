-- PlayerData: one record per player in the server. Cash, owned brainrots,
-- rebirths and the steal/lock timers all live here, in one place.
-- A record: { player, cash, owned (list of brainrot uids), rebirths,
--   multiplier, lockUntil (unix), lockCooldownUntil (unix), slapCooldownUntil (unix),
--   carryingUid (uid or nil), baseIndex }.

local PlayerData = {}

local byPlayer = {}

local START_CASH = 100

function PlayerData.newPlayer(player)
	local data = {
		player = player,
		cash = START_CASH,
		owned = {},
		rebirths = 0,
		multiplier = 1,
		lockUntil = 0,
		lockCooldownUntil = 0,
		slapCooldownUntil = 0,
		carryingUid = nil,
		baseIndex = 0,
	}
	byPlayer[player] = data
	return data
end

function PlayerData.get(player)
	return byPlayer[player]
end

function PlayerData.remove(player)
	byPlayer[player] = nil
end

function PlayerData.all()
	local list = {}
	for _, data in pairs(byPlayer) do
		table.insert(list, data)
	end
	return list
end

-- Income per second from everything the player owns, after the rebirth multiplier.
function PlayerData.incomePerSecond(data, Registry)
	local total = 0
	for _, uid in ipairs(data.owned) do
		local record = Registry.get(uid)
		if record ~= nil then
			total = total + record.rate
		end
	end
	return total * data.multiplier
end

function PlayerData.addOwned(data, uid)
	table.insert(data.owned, uid)
end

function PlayerData.removeOwned(data, uid)
	for i, held in ipairs(data.owned) do
		if held == uid then
			table.remove(data.owned, i)
			return true
		end
	end
	return false
end

function PlayerData.hasFreeSlot(data, maxSlots)
	return #data.owned < maxSlots
end

function PlayerData.isBaseLocked(data)
	return os.time() < data.lockUntil
end

return PlayerData
