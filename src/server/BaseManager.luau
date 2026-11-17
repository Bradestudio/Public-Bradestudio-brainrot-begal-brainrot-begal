-- BaseManager: the 8 player bases around the plaza. Each base is a Model in
-- the place (Workspace/Bases/Base1..Base8) with a floor, a sign and 8 slot
-- pads. A base belongs to one player at a time; its slots hold that player's
-- brainrots. The sign shows the owner's name.

local BaseManager = {}

local MAX_SLOTS = 8

-- Plaza layout: two rows of four bases south of the conveyor.
local BASE_CENTERS = {
	Vector3.new(-52, 0, 8),
	Vector3.new(-17, 0, 8),
	Vector3.new(17, 0, 8),
	Vector3.new(52, 0, 8),
	Vector3.new(-52, 0, 36),
	Vector3.new(-17, 0, 36),
	Vector3.new(17, 0, 36),
	Vector3.new(52, 0, 36),
}

-- Slot pads inside a base, two rows of four.
local SLOT_OFFSETS = {
	Vector3.new(-11, 0, -6),
	Vector3.new(-3.7, 0, -6),
	Vector3.new(3.7, 0, -6),
	Vector3.new(11, 0, -6),
	Vector3.new(-11, 0, 6),
	Vector3.new(-3.7, 0, 6),
	Vector3.new(3.7, 0, 6),
	Vector3.new(11, 0, 6),
}

local bases = {}

function BaseManager.maxSlots()
	return MAX_SLOTS
end

function BaseManager.init()
	local basesFolder = workspace:WaitForChild("Bases")
	for i = 1, 8 do
		local model = basesFolder:WaitForChild("Base" .. i)
		local signPart = model:WaitForChild("Sign")
		local signGui = signPart:WaitForChild("SignGui")
		local signLabel = signGui:WaitForChild("SignLabel")
		-- The sign label's size is set here, in code: Rojo 7.7 cannot express
		-- a UDim2 value in a project file, so the static tree leaves it out.
		signLabel.Size = UDim2.fromScale(1, 1)
		local slots = {}
		for s = 1, MAX_SLOTS do
			local pad = model:WaitForChild("Slot" .. s)
			slots[s] = { part = pad, occupiedUid = 0 }
		end
		bases[i] = {
			index = i,
			center = BASE_CENTERS[i],
			model = model,
			signLabel = signLabel,
			slots = slots,
			owner = nil,
		}
		signLabel.Text = "BASE " .. i .. " - KOSONG"
	end
end

-- Gives the player the first free base. Returns its index, or 0 when full.
function BaseManager.assignBase(player)
	for i = 1, 8 do
		if bases[i].owner == nil then
			bases[i].owner = player
			bases[i].signLabel.Text = player.Name .. " - BASE " .. i
			return i
		end
	end
	return 0
end

function BaseManager.freeBase(player)
	for i = 1, 8 do
		if bases[i].owner == player then
			bases[i].owner = nil
			bases[i].signLabel.Text = "BASE " .. i .. " - KOSONG"
			for s = 1, MAX_SLOTS do
				bases[i].slots[s].occupiedUid = 0
			end
			return
		end
	end
end

function BaseManager.baseOf(player)
	for i = 1, 8 do
		if bases[i].owner == player then
			return bases[i]
		end
	end
	return nil
end

function BaseManager.baseByIndex(index)
	return bases[index]
end

-- First free slot number on a base, or nil when the base is full.
function BaseManager.firstFreeSlot(base)
	for s = 1, MAX_SLOTS do
		if base.slots[s].occupiedUid == 0 then
			return s
		end
	end
	return nil
end

function BaseManager.slotPosition(base, slotIndex)
	local pad = base.slots[slotIndex].part
	return pad.Position
end

-- Puts a brainrot model on a base slot and marks the slot taken.
function BaseManager.placeOnSlot(base, slotIndex, record)
	local padTop = base.slots[slotIndex].part.Position + Vector3.new(0, 0.1 + record.bodyHeight / 2, 0)
	record.model:PivotTo(CFrame.new(padTop))
	base.slots[slotIndex].occupiedUid = record.uid
	record.slotIndex = slotIndex
	record.state = "owned"
	local prompt = record.model:FindFirstChild("Body", true)
	if prompt ~= nil then
		local catchPrompt = prompt:FindFirstChild("CatchPrompt")
		if catchPrompt ~= nil then
			catchPrompt.ActionText = "Curi"
			catchPrompt.Enabled = true
		end
	end
end

function BaseManager.clearSlot(base, slotIndex)
	if slotIndex >= 1 and slotIndex <= MAX_SLOTS then
		base.slots[slotIndex].occupiedUid = 0
	end
end

-- Is this player's character standing inside their own base?
function BaseManager.isInsideOwnBase(player)
	local base = BaseManager.baseOf(player)
	if base == nil then
		return false
	end
	local character = player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local pos = root.Position
	return math.abs(pos.X - base.center.X) <= 15 and math.abs(pos.Z - base.center.Z) <= 12
end

return BaseManager
