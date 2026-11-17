-- CatchService: what happens when a player holds E on a brainrot's prompt.
-- A walking brainrot on the conveyor is caught (paid for, moved to the
-- player's base). A brainrot sitting on someone else's base is a steal
-- attempt, handled by StealService. Every check runs on the server, so a
-- client can never catch what it cannot afford.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local Registry = require(script.Parent:WaitForChild("BrainrotRegistry"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local StealService = require(script.Parent:WaitForChild("StealService"))
local Notifier = require(script.Parent:WaitForChild("Notifier"))

local CatchService = {}

-- Wires one brainrot model's prompt to this service.
function CatchService.watchPrompt(model, record)
	local body = model:WaitForChild("Body")
	local prompt = body:WaitForChild("CatchPrompt")
	prompt.Triggered:Connect(function(player)
		CatchService.onPrompt(player, record)
	end)
end

function CatchService.onPrompt(player, record)
	if record.state == "walking" then
		CatchService.tryCatch(player, record)
	elseif record.state == "owned" then
		StealService.trySteal(player, record)
	end
end

function CatchService.tryCatch(player, record)
	local data = PlayerData.get(player)
	if data == nil then
		return
	end
	if not PlayerData.hasFreeSlot(data, BaseManager.maxSlots()) then
		Notifier.to(player, "Base kamu penuh (8/8)! Rebirth dulu untuk mengosongkannya.", "warn")
		return
	end
	if data.cash < record.cost then
		Notifier.to(player, "Uang kurang! " .. Catalog.displayName(record.character, record.mutationKey) .. " butuh $" .. record.cost .. ", kamu punya $" .. math.floor(data.cash) .. ".", "warn")
		return
	end
	local base = BaseManager.baseOf(player)
	if base == nil then
		Notifier.to(player, "Kamu belum punya base!", "warn")
		return
	end
	local slot = BaseManager.firstFreeSlot(base)
	if slot == nil then
		Notifier.to(player, "Base kamu penuh (8/8)!", "warn")
		return
	end
	data.cash = data.cash - record.cost
	record.owner = player
	PlayerData.addOwned(data, record.uid)
	BaseManager.placeOnSlot(base, slot, record)
	Notifier.to(player, "Kamu menangkap " .. Catalog.displayName(record.character, record.mutationKey) .. "! +$" .. record.rate .. "/detik.", "good")
end

return CatchService
