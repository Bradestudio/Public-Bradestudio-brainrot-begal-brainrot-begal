-- BrainrotModel: builds the 3D model of one brainrot from its catalog entry.
-- Body + head + eyes + one accessory per shape, plus a floating label with
-- its name, rarity and money-per-second, and a ProximityPrompt to catch or
-- steal it. Every part is anchored and non-colliding so the model never
-- blocks a player's walk.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotCatalog"))

local BrainrotModel = {}

local BODY_SIZE = 2.2

local function makePart(name, size, color, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = parent
	return part
end

-- One small accessory part that says what shape this brainrot is.
local function addAccessory(shape, body, size, color)
	local s = size
	if shape == "Cat" then
		local ear1 = makePart("EarLeft", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Color3.fromRGB(40, 40, 40), body.Parent)
		ear1.CFrame = body.CFrame * CFrame.new(-0.6 * s, 1.3 * s, 0)
		local ear2 = makePart("EarRight", Vector3.new(0.5 * s, 0.6 * s, 0.2 * s), Color3.fromRGB(40, 40, 40), body.Parent)
		ear2.CFrame = body.CFrame * CFrame.new(0.6 * s, 1.3 * s, 0)
	elseif shape == "Chicken" then
		local beak = makePart("Beak", Vector3.new(0.5 * s, 0.4 * s, 0.5 * s), Color3.fromRGB(255, 160, 40), body.Parent)
		beak.CFrame = body.CFrame * CFrame.new(0, 0.7 * s, 1.2 * s)
		local comb = makePart("Comb", Vector3.new(0.7 * s, 0.5 * s, 0.4 * s), Color3.fromRGB(255, 60, 60), body.Parent)
		comb.CFrame = body.CFrame * CFrame.new(0, 1.5 * s, 0)
	elseif shape == "Cup" then
		local straw = makePart("Straw", Vector3.new(0.25 * s, 1.2 * s, 0.25 * s), Color3.fromRGB(255, 80, 120), body.Parent)
		straw.CFrame = body.CFrame * CFrame.new(0.5 * s, 1.4 * s, 0)
	elseif shape == "Noodle" then
		for i = 1, 3 do
			local strand = makePart("Noodle" .. i, Vector3.new(0.25 * s, 1.0 * s, 0.25 * s), Color3.fromRGB(255, 230, 150), body.Parent)
			strand.CFrame = body.CFrame * CFrame.new(-0.6 * s + (i - 1) * 0.6 * s, 1.2 * s, 0)
		end
	elseif shape == "Crown" or shape == "King" then
		for i = 1, 3 do
			local spike = makePart("Crown" .. i, Vector3.new(0.35 * s, 0.8 * s, 0.35 * s), Color3.fromRGB(255, 215, 0), body.Parent)
			spike.CFrame = body.CFrame * CFrame.new(-0.7 * s + (i - 1) * 0.7 * s, 1.5 * s, 0)
		end
	elseif shape == "Star" then
		local bar = makePart("StarBar", Vector3.new(2.0 * s, 0.4 * s, 0.4 * s), color, body.Parent)
		bar.CFrame = body.CFrame * CFrame.new(0, 1.4 * s, 0) * CFrame.Angles(0, 0, math.rad(45))
	elseif shape == "Skewer" then
		local stick = makePart("Skewer", Vector3.new(0.25 * s, 0.25 * s, 3.2 * s), Color3.fromRGB(180, 130, 70), body.Parent)
		stick.CFrame = body.CFrame * CFrame.new(0, 0.6 * s, 0)
	elseif shape == "Ghost" then
		body.Transparency = 0.35
	end
end

-- Builds the model. Returns (model, bodyHeight).
function BrainrotModel.build(character, rarityKey, mutationKey, uid)
	local rarity = Catalog.getRarity(rarityKey)
	local mutation = Catalog.getMutation(mutationKey)
	local size = character.size
	local displayName = Catalog.displayName(character, mutationKey)
	local rate = Catalog.effectiveRate(character, mutationKey)

	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. uid
	model:SetAttribute("BrainrotUid", uid)

	local bodyHeight = 2.0 * size
	local body = makePart("Body", Vector3.new(BODY_SIZE * size, bodyHeight, BODY_SIZE * size), character.color, model)
	body.CFrame = CFrame.new(0, bodyHeight / 2, 0)

	local head = makePart("Head", Vector3.new(1.4 * size, 1.1 * size, 1.4 * size), character.color, model)
	head.CFrame = CFrame.new(0, bodyHeight + 0.55 * size, 0)

	local eyeColor = Color3.fromRGB(20, 20, 20)
	local eyeLeft = makePart("EyeLeft", Vector3.new(0.3 * size, 0.3 * size, 0.2 * size), eyeColor, model)
	eyeLeft.CFrame = CFrame.new(-0.35 * size, bodyHeight + 0.65 * size, 0.75 * size)
	local eyeRight = makePart("EyeRight", Vector3.new(0.3 * size, 0.3 * size, 0.2 * size), eyeColor, model)
	eyeRight.CFrame = CFrame.new(0.35 * size, bodyHeight + 0.65 * size, 0.75 * size)

	addAccessory(character.shape, body, size, character.color)

	-- Mutation gem: a small floating gem above the head when mutated.
	if mutation.key ~= "None" then
		local gem = makePart("MutationGem", Vector3.new(0.6 * size, 0.6 * size, 0.6 * size), mutation.color, model)
		gem.Material = Enum.Material.Neon
		gem.CFrame = CFrame.new(0, bodyHeight + 1.6 * size, 0)
	end

	-- Floating label: name, rarity and money per second.
	local labelGui = Instance.new("BillboardGui")
	labelGui.Name = "BrainrotLabel"
	labelGui.Size = UDim2.fromOffset(140, 56)
	labelGui.StudsOffsetWorldSpace = Vector3.new(0, bodyHeight + 2.4 * size, 0)
	labelGui.AlwaysOnTop = true
	labelGui.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.fromScale(1, 0.55)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = labelGui

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Position = UDim2.fromScale(0, 0.55)
	rateLabel.Size = UDim2.fromScale(1, 0.45)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. rate .. "/dtk  -  " .. rarity.name
	rateLabel.TextColor3 = rarity.color
	rateLabel.TextStrokeTransparency = 0
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.SourceSansBold
	rateLabel.Parent = labelGui

	-- The prompt the player holds E on to catch (or steal) this brainrot.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "CatchPrompt"
	prompt.ObjectText = displayName
	prompt.ActionText = "Tangkap"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = body

	model.PrimaryPart = body
	return model, bodyHeight
end

return BrainrotModel
