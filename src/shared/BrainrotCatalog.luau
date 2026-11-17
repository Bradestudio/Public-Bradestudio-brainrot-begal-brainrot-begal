-- BrainrotCatalog: the whole cast of BRAINROT BEGAL, shared by server and client.
-- Every character is an original invention for this game: absurd Indonesian
-- street-food and market memes. None of them copies Steal a Brainrot or any
-- other game's cast. A character earns money every second while it sits on
-- its owner's base. Rarities climb Common -> Mythic; mutations multiply the
-- rate. Prices are the cash a player pays to catch one off the conveyor.

local Catalog = {}

Catalog.RARITIES = {
	{ key = "Common", name = "Biasa", color = Color3.fromRGB(190, 190, 190), weight = 45 },
	{ key = "Uncommon", name = "Jarang", color = Color3.fromRGB(80, 200, 90), weight = 27 },
	{ key = "Rare", name = "Langka", color = Color3.fromRGB(60, 140, 255), weight = 15 },
	{ key = "Epic", name = "Epik", color = Color3.fromRGB(170, 80, 255), weight = 8 },
	{ key = "Legendary", name = "Legendaris", color = Color3.fromRGB(255, 180, 30), weight = 4 },
	{ key = "Mythic", name = "Mitos", color = Color3.fromRGB(255, 60, 120), weight = 1 },
}

Catalog.MUTATIONS = {
	{ key = "None", name = "", color = Color3.fromRGB(255, 255, 255), mult = 1, weight = 84.5 },
	{ key = "Emas", name = "Emas", color = Color3.fromRGB(255, 215, 0), mult = 2, weight = 10 },
	{ key = "Pelangi", name = "Pelangi", color = Color3.fromRGB(120, 220, 255), mult = 3, weight = 4 },
	{ key = "Berlian", name = "Berlian", color = Color3.fromRGB(180, 240, 255), mult = 5, weight = 1.5 },
}

-- name, rarity, $/sec, catch price, body color, body size, accessory shape.
Catalog.CHARACTERS = {
	{ name = "Kucing Nasi Padang", rarity = "Common", rate = 1, cost = 25, color = Color3.fromRGB(255, 205, 110), size = 1.0, shape = "Cat" },
	{ name = "Ayam Geprek Terbang", rarity = "Common", rate = 2, cost = 50, color = Color3.fromRGB(255, 240, 200), size = 1.0, shape = "Chicken" },
	{ name = "Tahu Bulat Sakti", rarity = "Common", rate = 2, cost = 75, color = Color3.fromRGB(245, 230, 180), size = 1.1, shape = "Ball" },
	{ name = "Es Teh Manis Raksasa", rarity = "Uncommon", rate = 5, cost = 150, color = Color3.fromRGB(200, 120, 40), size = 1.2, shape = "Cup" },
	{ name = "Gorengan Terakhir", rarity = "Uncommon", rate = 7, cost = 250, color = Color3.fromRGB(190, 130, 60), size = 1.1, shape = "Ball" },
	{ name = "Kopi Tubruk Galak", rarity = "Uncommon", rate = 9, cost = 400, color = Color3.fromRGB(90, 60, 30), size = 1.1, shape = "Cup" },
	{ name = "Bakso Uranium", rarity = "Rare", rate = 15, cost = 800, color = Color3.fromRGB(120, 255, 120), size = 1.3, shape = "Ball" },
	{ name = "Nasi Kucing Sultan", rarity = "Rare", rate = 20, cost = 1200, color = Color3.fromRGB(255, 215, 0), size = 1.2, shape = "Bowl" },
	{ name = "Mie Ayam Terbang", rarity = "Rare", rate = 25, cost = 2000, color = Color3.fromRGB(255, 220, 120), size = 1.2, shape = "Noodle" },
	{ name = "Rujak Petis Halilintar", rarity = "Epic", rate = 45, cost = 4000, color = Color3.fromRGB(255, 100, 180), size = 1.4, shape = "Bowl" },
	{ name = "Sate Klathak Emas", rarity = "Epic", rate = 60, cost = 6000, color = Color3.fromRGB(255, 200, 40), size = 1.4, shape = "Skewer" },
	{ name = "Soto Ayam Angkasa", rarity = "Epic", rate = 80, cost = 9000, color = Color3.fromRGB(120, 200, 255), size = 1.5, shape = "Bowl" },
	{ name = "Rendang Abadi", rarity = "Legendary", rate = 150, cost = 18000, color = Color3.fromRGB(150, 80, 20), size = 1.6, shape = "Bowl" },
	{ name = "Gudeg Keramat", rarity = "Legendary", rate = 200, cost = 25000, color = Color3.fromRGB(200, 160, 60), size = 1.6, shape = "Crown" },
	{ name = "Nasi Goreng Kilat", rarity = "Legendary", rate = 260, cost = 32000, color = Color3.fromRGB(255, 150, 50), size = 1.6, shape = "Star" },
	{ name = "Begal Terakhir", rarity = "Mythic", rate = 500, cost = 75000, color = Color3.fromRGB(40, 40, 40), size = 1.8, shape = "Ghost" },
	{ name = "Nasi Padang Semesta", rarity = "Mythic", rate = 750, cost = 120000, color = Color3.fromRGB(255, 215, 0), size = 1.9, shape = "Crown" },
	{ name = "Raja Pasar Begal", rarity = "Mythic", rate = 1000, cost = 200000, color = Color3.fromRGB(255, 60, 120), size = 2.0, shape = "King" },
}

function Catalog.getRarity(key)
	for _, rarity in ipairs(Catalog.RARITIES) do
		if rarity.key == key then
			return rarity
		end
	end
	return Catalog.RARITIES[1]
end

function Catalog.getMutation(key)
	for _, mutation in ipairs(Catalog.MUTATIONS) do
		if mutation.key == key then
			return mutation
		end
	end
	return Catalog.MUTATIONS[1]
end

-- Weighted roll: returns a rarity key.
function Catalog.rollRarity()
	local total = 0
	for _, rarity in ipairs(Catalog.RARITIES) do
		total = total + rarity.weight
	end
	local roll = math.random() * total
	local running = 0
	for _, rarity in ipairs(Catalog.RARITIES) do
		running = running + rarity.weight
		if roll <= running then
			return rarity.key
		end
	end
	return "Common"
end

-- Weighted roll: returns a mutation key.
function Catalog.rollMutation()
	local total = 0
	for _, mutation in ipairs(Catalog.MUTATIONS) do
		total = total + mutation.weight
	end
	local roll = math.random() * total
	local running = 0
	for _, mutation in ipairs(Catalog.MUTATIONS) do
		running = running + mutation.weight
		if roll <= running then
			return mutation.key
		end
	end
	return "None"
end

-- A random character of the given rarity.
function Catalog.rollCharacter(rarityKey)
	local pool = {}
	for _, character in ipairs(Catalog.CHARACTERS) do
		if character.rarity == rarityKey then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return Catalog.CHARACTERS[1]
	end
	return pool[math.random(1, #pool)]
end

-- The display name of a brainrot, with its mutation in front when mutated.
function Catalog.displayName(character, mutationKey)
	local mutation = Catalog.getMutation(mutationKey)
	if mutation.key == "None" then
		return character.name
	end
	return mutation.name .. " " .. character.name
end

-- The money a brainrot earns per second, after its mutation.
function Catalog.effectiveRate(character, mutationKey)
	local mutation = Catalog.getMutation(mutationKey)
	return character.rate * mutation.mult
end

return Catalog
