-- BrainrotRegistry: the single table of every live brainrot in the game.
-- A record: { uid, character, rarityKey, mutationKey, rate, cost, model,
--   state, owner (Player or nil), slotIndex, speed, x }.
-- States: "walking" (on the conveyor), "owned" (on a base slot),
-- "carried" (stolen, above a thief's head), "returning" (dropped, walking home).

local Registry = {}

local records = {}
local nextUid = 1

function Registry.nextUid()
	local uid = nextUid
	nextUid = nextUid + 1
	return uid
end

function Registry.register(record)
	records[record.uid] = record
	return record
end

function Registry.get(uid)
	return records[uid]
end

function Registry.remove(uid)
	records[uid] = nil
end

function Registry.all()
	local list = {}
	for _, record in pairs(records) do
		table.insert(list, record)
	end
	return list
end

function Registry.walking()
	local list = {}
	for _, record in pairs(records) do
		if record.state == "walking" then
			table.insert(list, record)
		end
	end
	return list
end

function Registry.ownedBy(player)
	local list = {}
	for _, record in pairs(records) do
		if record.state == "owned" and record.owner == player then
			table.insert(list, record)
		end
	end
	return list
end

function Registry.findByModel(model)
	for _, record in pairs(records) do
		if record.model == model then
			return record
		end
	end
	return nil
end

function Registry.count()
	local count = 0
	for _ in pairs(records) do
		count = count + 1
	end
	return count
end

return Registry
