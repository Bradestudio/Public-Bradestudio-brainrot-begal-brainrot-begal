-- BRAINROT BEGAL — server bootstrap.
-- Boots every service in order, wires the LockBase and Slap remotes, and
-- gives each joining player a base, starting cash and a welcome message.
-- Leaving players hand back stolen brainrots, lose their owned ones, and
-- free their base.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local Notifier = require(script:WaitForChild("Notifier"))
local PlayerData = require(script:WaitForChild("PlayerData"))
local BaseManager = require(script:WaitForChild("BaseManager"))
local Registry = require(script:WaitForChild("BrainrotRegistry"))
local Spawner = require(script:WaitForChild("Spawner"))
local CatchService = require(script:WaitForChild("CatchService"))
local StealService = require(script:WaitForChild("StealService"))
local WaveService = require(script:WaitForChild("WaveService"))
local RebirthService = require(script:WaitForChild("RebirthService"))
local Economy = require(script:WaitForChild("Economy"))

math.randomseed(os.time())

Notifier.init(remotes)
BaseManager.init()
StealService.init()
WaveService.init(remotes)
RebirthService.init(remotes)
Economy.init(remotes, Registry)
Spawner.init()

-- LockBase: $500 locks your base for 15 seconds (45 second cooldown), so
-- nobody can steal from you while it holds.
remotes:WaitForChild("LockBase").OnServerEvent:Connect(function(player)
	local data = PlayerData.get(player)
	if data == nil then
		return
	end
	local now = os.time()
	if now < data.lockCooldownUntil then
		Notifier.to(player, "Kunci base masih cooldown (" .. (data.lockCooldownUntil - now) .. " detik lagi).", "warn")
		return
	end
	if data.cash < 500 then
		Notifier.to(player, "Kunci base butuh $500.", "warn")
		return
	end
	data.cash = data.cash - 500
	data.lockUntil = now + 15
	data.lockCooldownUntil = now + 45
	Notifier.to(player, "Base terkunci 15 detik! Tidak ada yang bisa mencuri.", "good")
end)

-- Slap: knock a stolen brainrot out of a thief's hands.
remotes:WaitForChild("Slap").OnServerEvent:Connect(function(player)
	StealService.slap(player)
end)

local function onPlayerAdded(player)
	local data = PlayerData.newPlayer(player)
	local baseIndex = BaseManager.assignBase(player)
	data.baseIndex = baseIndex
	Economy.sendState(data, Registry)
	Notifier.to(player, "Selamat datang di PASAR BEGAL! Tangkap brainrot di konveyor (E), simpan di base, dan awas pencuri!", "info")
end

local function onPlayerRemoving(player)
	local data = PlayerData.get(player)
	if data == nil then
		return
	end
	-- A leaver carrying a stolen brainrot hands it back to its owner.
	if data.carryingUid ~= nil then
		local record = Registry.get(data.carryingUid)
		if record ~= nil then
			StealService.dropToOwner(record)
		end
	end
	-- Everything they owned is destroyed with them.
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
	BaseManager.freeBase(player)
	PlayerData.remove(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("BRAINROT BEGAL server ready.")
