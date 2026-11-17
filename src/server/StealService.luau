-- StealService: stealing a brainrot off another player's base, carrying it
-- home, and slapping thieves. A steal only works when the victim's base is
-- not locked and the thief is not already carrying one. The thief carries
-- the brainrot above their head; if they reach their own base it becomes
-- theirs, if anyone slaps them (F) within range it drops back to its owner.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local Registry = require(script.Parent:WaitForChild("BrainrotRegistry"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Notifier = require(script.Parent:WaitForChild("Notifier"))

local StealService = {}

local SLAP_RANGE = 12
local SLAP_COOLDOWN = 5

local function promptOf(record)
	local body = record.model:FindFirstChild("Body")
	if body == nil then
		return nil
	end
	return body:FindFirstChild("CatchPrompt")
end

function StealService.trySteal(player, record)
	local owner = record.owner
	if owner == nil then
		return
	end
	if owner == player then
		Notifier.to(player, "Itu brainrot kamu sendiri!", "warn")
		return
	end
	local data = PlayerData.get(player)
	if data == nil then
		return
	end
	if data.carryingUid ~= nil then
		Notifier.to(player, "Kamu sudah membawa satu brainrot! Bawa pulang dulu.", "warn")
		return
	end
	local ownerData = PlayerData.get(owner)
	if ownerData ~= nil and PlayerData.isBaseLocked(ownerData) then
		Notifier.to(player, "Base " .. owner.Name .. " terkunci! Tidak bisa mencuri.", "warn")
		return
	end
	local base = BaseManager.baseOf(owner)
	if base ~= nil then
		BaseManager.clearSlot(base, record.slotIndex)
	end
	if ownerData ~= nil then
		PlayerData.removeOwned(ownerData, record.uid)
	end
	record.state = "carried"
	record.carrier = player
	data.carryingUid = record.uid
	local prompt = promptOf(record)
	if prompt ~= nil then
		prompt.Enabled = false
	end
	local displayName = Catalog.displayName(record.character, record.mutationKey)
	Notifier.to(player, "Kamu mencuri " .. displayName .. "! Bawa pulang ke basemu, jangan sampai ditampar!", "good")
	Notifier.to(owner, player.Name .. " mencuri " .. displayName .. " kamu! Tampar dia (F)!", "warn")
end

-- Returns a carried brainrot to its owner's base (slapped, carrier left, or
-- carrier's base was full). The thief's carry slot is cleared either way.
function StealService.dropToOwner(record)
	local carrier = record.carrier
	if carrier ~= nil then
		local carrierData = PlayerData.get(carrier)
		if carrierData ~= nil and carrierData.carryingUid == record.uid then
			carrierData.carryingUid = nil
		end
	end
	record.carrier = nil
	local owner = record.owner
	local ownerData = nil
	if owner ~= nil then
		ownerData = PlayerData.get(owner)
	end
	local base = nil
	if owner ~= nil then
		base = BaseManager.baseOf(owner)
	end
	local slot = nil
	if base ~= nil then
		slot = BaseManager.firstFreeSlot(base)
	end
	if base ~= nil and slot ~= nil then
		if ownerData ~= nil then
			PlayerData.addOwned(ownerData, record.uid)
		end
		BaseManager.placeOnSlot(base, slot, record)
	else
		if record.model ~= nil then
			record.model:Destroy()
		end
		Registry.remove(record.uid)
		if owner ~= nil then
			Notifier.to(owner, "Brainrot kamu hilang: base penuh saat dikembalikan.", "warn")
		end
	end
end

-- The steal completes when the thief reaches their own base.
local function completeSteal(record)
	local thief = record.carrier
	local oldOwner = record.owner
	local thiefData = nil
	if thief ~= nil then
		thiefData = PlayerData.get(thief)
	end
	if thief == nil or thiefData == nil then
		StealService.dropToOwner(record)
		return
	end
	local base = BaseManager.baseOf(thief)
	local slot = nil
	if base ~= nil then
		slot = BaseManager.firstFreeSlot(base)
	end
	if base == nil or slot == nil then
		Notifier.to(thief, "Base kamu penuh! Brainrot balik ke pemiliknya.", "warn")
		StealService.dropToOwner(record)
		return
	end
	thiefData.carryingUid = nil
	record.carrier = nil
	record.owner = thief
	PlayerData.addOwned(thiefData, record.uid)
	BaseManager.placeOnSlot(base, slot, record)
	local displayName = Catalog.displayName(record.character, record.mutationKey)
	Notifier.to(thief, "Berhasil! " .. displayName .. " sekarang milikmu. +$" .. record.rate .. "/detik.", "good")
	if oldOwner ~= nil and oldOwner ~= thief then
		Notifier.to(oldOwner, thief.Name .. " berhasil mencuri " .. displayName .. " kamu!", "warn")
	end
end

-- Slap: anyone near a thief can knock the stolen brainrot out of their hands.
function StealService.slap(requester)
	local data = PlayerData.get(requester)
	if data == nil then
		return
	end
	local now = os.time()
	if now < data.slapCooldownUntil then
		return
	end
	local character = requester.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	for _, record in ipairs(Registry.all()) do
		if record.state == "carried" and record.carrier ~= nil and record.carrier ~= requester then
			local carrierChar = record.carrier.Character
			if carrierChar ~= nil then
				local carrierRoot = carrierChar:FindFirstChild("HumanoidRootPart")
				if carrierRoot ~= nil then
					local distance = (carrierRoot.Position - root.Position).Magnitude
					if distance <= SLAP_RANGE then
						data.slapCooldownUntil = now + SLAP_COOLDOWN
						local displayName = Catalog.displayName(record.character, record.mutationKey)
						local owner = record.owner
						local carrier = record.carrier
						StealService.dropToOwner(record)
						Notifier.to(requester, "Tampar! " .. displayName .. " jatuh dari tangan " .. carrier.Name .. "!", "good")
						Notifier.to(carrier, "Kamu ditampar! Brainrot jatuh!", "warn")
						if owner ~= nil then
							Notifier.to(owner, displayName .. " kamu berhasil diselamatkan!", "good")
						end
						return
					end
				end
			end
		end
	end
end

function StealService.init()
	-- Carry loop: a stolen brainrot floats above its thief's head, and the
	-- steal completes the moment the thief steps inside their own base.
	RunService.Heartbeat:Connect(function(_dt)
		for _, record in ipairs(Registry.all()) do
			if record.state == "carried" then
				local carrier = record.carrier
				if carrier == nil then
					StealService.dropToOwner(record)
				else
					local character = carrier.Character
					local root = nil
					if character ~= nil then
						root = character:FindFirstChild("HumanoidRootPart")
					end
					if root == nil then
						StealService.dropToOwner(record)
					elseif record.model ~= nil and record.model.PrimaryPart ~= nil then
						record.model:PivotTo(root.CFrame + Vector3.new(0, 4.5, 0))
						if BaseManager.isInsideOwnBase(carrier) then
							completeSteal(record)
						end
					end
				end
			end
		end
	end)
end

return StealService
