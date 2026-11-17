-- Spawner: brainrots walk the conveyor from the spawn gate to the despawn
-- gate, one spawn every few seconds, at most 12 walking at once. Each spawn
-- rolls a rarity, a character of that rarity and a mutation, then builds its
-- model and wires its catch prompt.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local Registry = require(script.Parent:WaitForChild("BrainrotRegistry"))
local BrainrotModel = require(script.Parent:WaitForChild("BrainrotModel"))
local CatchService = require(script.Parent:WaitForChild("CatchService"))

local Spawner = {}

local SPAWN_X = -68
local DESPAWN_X = 68
local LANE_Z = -45
local MAX_WALKING = 12
local SPAWN_INTERVAL = 2.5
local WALK_SPEED = 4

local folder = nil

local function spawnBrainrot()
	local rarityKey = Catalog.rollRarity()
	local character = Catalog.rollCharacter(rarityKey)
	local mutationKey = Catalog.rollMutation()
	local rate = Catalog.effectiveRate(character, mutationKey)
	local uid = Registry.nextUid()

	local model, bodyHeight = BrainrotModel.build(character, rarityKey, mutationKey, uid)
	model.Parent = folder

	local record = {
		uid = uid,
		character = character,
		rarityKey = rarityKey,
		mutationKey = mutationKey,
		rate = rate,
		cost = character.cost,
		model = model,
		state = "walking",
		owner = nil,
		slotIndex = 0,
		speed = WALK_SPEED,
		x = SPAWN_X,
		y = 1 + bodyHeight / 2,
		bodyHeight = bodyHeight,
		carrier = nil,
	}
	Registry.register(record)
	model:PivotTo(CFrame.new(record.x, record.y, LANE_Z))
	CatchService.watchPrompt(model, record)
end

local function despawnRecord(record)
	if record.model ~= nil then
		record.model:Destroy()
	end
	Registry.remove(record.uid)
end

function Spawner.despawnRecord(record)
	despawnRecord(record)
end

function Spawner.init()
	folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	folder.Parent = workspace

	-- Walk every brainrot along the conveyor, despawn at the far gate.
	RunService.Heartbeat:Connect(function(dt)
		for _, record in ipairs(Registry.walking()) do
			record.x = record.x + record.speed * dt
			if record.x >= DESPAWN_X then
				despawnRecord(record)
			elseif record.model ~= nil and record.model.PrimaryPart ~= nil then
				record.model:PivotTo(CFrame.new(record.x, record.y, LANE_Z))
			end
		end
	end)

	-- Keep the conveyor stocked.
	task.spawn(function()
		while true do
			if #Registry.walking() < MAX_WALKING then
				spawnBrainrot()
			end
			task.wait(SPAWN_INTERVAL)
		end
	end)
end

return Spawner
