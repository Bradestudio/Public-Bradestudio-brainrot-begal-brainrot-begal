-- RebirthService: trade everything for a permanent multiplier. A player
-- with at least $50,000 cash and 4 brainrots on their base can rebirth:
-- every owned brainrot is destroyed, cash resets to zero, and the rebirth
-- count rises by one. The money multiplier doubles with each rebirth.

local Registry = require(script.Parent:WaitForChild("BrainrotRegistry"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Notifier = require(script.Parent:WaitForChild("Notifier"))

local RebirthService = {}

local REBIRTH_CASH = 50000
local REBIRTH_MIN_OWNED = 4

function RebirthService.init(remotes)
	remotes:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
		local data = PlayerData.get(player)
		if data == nil then
			return
		end
		if data.cash < REBIRTH_CASH or #data.owned < REBIRTH_MIN_OWNED then
			Notifier.to(player, "Rebirth butuh $50.000 dan 4 brainrot di base. Kamu: $" .. math.floor(data.cash) .. " dan " .. #data.owned .. " brainrot.", "warn")
			return
		end
		local base = BaseManager.baseOf(player)
		for _, uid in ipairs(data.owned) do
			local record = Registry.get(uid)
			if record ~= nil then
				if base ~= nil then
					BaseManager.clearSlot(base, record.slotIndex)
				end
				if record.model ~= nil then
					record.model:Destroy()
				end
				Registry.remove(uid)
			end
		end
		data.owned = {}
		data.cash = 0
		data.rebirths = data.rebirths + 1
		data.multiplier = 2 ^ data.rebirths
		Notifier.all(player.Name .. " REBIRTH ke-" .. data.rebirths .. "! Multiplier sekarang x" .. data.multiplier .. "!", "good")
	end)
end

return RebirthService
