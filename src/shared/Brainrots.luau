-- Brainrot Bay: the cast of collectible brainrot characters.
-- Every brainrot earns its owner money every second while it sits on a base.
-- The cast is the game's own: 14 named characters across 6 rarities.

local Brainrots = {}

Brainrots.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

Brainrots.RARITY_COLORS = {
	Common = Color3.fromRGB(170, 170, 170),
	Rare = Color3.fromRGB(80, 160, 255),
	Epic = Color3.fromRGB(170, 90, 255),
	Legendary = Color3.fromRGB(255, 190, 40),
	Mythic = Color3.fromRGB(255, 80, 120),
	["Brainrot God"] = Color3.fromRGB(120, 255, 200),
}

-- Weighted spawn chances on the conveyor (out of 100).
Brainrots.RARITY_WEIGHTS = {
	Common = 40,
	Rare = 28,
	Epic = 16,
	Legendary = 9,
	Mythic = 5,
	["Brainrot God"] = 2,
}

-- id, display name, rarity, buy price, dollars earned per second, body color, joke.
Brainrots.CAST = {
	{ id = "noobini", name = "Noobini Pizzanini", rarity = "Common", price = 25, perSecond = 1, color = Color3.fromRGB(255, 214, 120), blurb = "A pizza slice that learned to walk. Slowly." },
	{ id = "spaghetti", name = "Sir Spaghetti Legs", rarity = "Common", price = 60, perSecond = 2, color = Color3.fromRGB(255, 240, 180), blurb = "Knighted for services to carbohydrates." },
	{ id = "carl", name = "Cappuccino Carl", rarity = "Common", price = 120, perSecond = 4, color = Color3.fromRGB(190, 140, 90), blurb = "Foams at the mouth. Literally. It's his job." },
	{ id = "tungy", name = "Tungy the Traffic Cone", rarity = "Rare", price = 300, perSecond = 9, color = Color3.fromRGB(255, 120, 40), blurb = "Directs traffic nobody asked him to direct." },
	{ id = "baguette", name = "Madame Baguette", rarity = "Rare", price = 650, perSecond = 18, color = Color3.fromRGB(230, 190, 120), blurb = "Fluent in French. Fluent in crime." },
	{ id = "fridge", name = "DJ Fridge Magnet", rarity = "Rare", price = 1200, perSecond = 32, color = Color3.fromRGB(90, 200, 255), blurb = "Stuck to the fridge. Still drops bangers." },
	{ id = "pickle", name = "Professor Pickle Rickshaw", rarity = "Epic", price = 2500, perSecond = 60, color = Color3.fromRGB(120, 220, 90), blurb = "Holds three PhDs. None of them real." },
	{ id = "goldfish", name = "Goldfish CEO", rarity = "Epic", price = 5000, perSecond = 120, color = Color3.fromRGB(255, 170, 60), blurb = "Forgot the meeting. Remembers the money." },
	{ id = "vaca", name = "La Vaca's Intern", rarity = "Legendary", price = 12000, perSecond = 260, color = Color3.fromRGB(200, 120, 255), blurb = "Saturn called. It wants its cow back." },
	{ id = "chimp", name = "Chimpanzini Bananini Jr.", rarity = "Legendary", price = 25000, perSecond = 520, color = Color3.fromRGB(255, 220, 90), blurb = "Banana royalty. Peel responsibly." },
	{ id = "tralala", name = "Tralala's Lawyer", rarity = "Mythic", price = 60000, perSecond = 1100, color = Color3.fromRGB(90, 220, 255), blurb = "Sues in shark. Wins in shark." },
	{ id = "bombardiro", name = "Bombardiro's Uncle", rarity = "Mythic", price = 120000, perSecond = 2200, color = Color3.fromRGB(120, 140, 160), blurb = "A crocodile. A bomber. A family man." },
	{ id = "burrito", name = "The Forbidden Burrito", rarity = "Brainrot God", price = 300000, perSecond = 5000, color = Color3.fromRGB(255, 90, 90), blurb = "Do not eat. Do not look directly at it." },
	{ id = "router", name = "Grandma's WiFi Router", rarity = "Brainrot God", price = 750000, perSecond = 12000, color = Color3.fromRGB(140, 255, 180), blurb = "The password is on the fridge. It always was." },
}

-- Look up one brainrot by its id, or nil when no such brainrot exists.
function Brainrots.getById(id)
	for _, entry in ipairs(Brainrots.CAST) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

-- All brainrots of one rarity, in cast order.
function Brainrots.getByRarity(rarity)
	local found = {}
	for _, entry in ipairs(Brainrots.CAST) do
		if entry.rarity == rarity then
			table.insert(found, entry)
		end
	end
	return found
end

-- The display color of a rarity, grey when the rarity is unknown.
function Brainrots.getRarityColor(rarity)
	return Brainrots.RARITY_COLORS[rarity] or Color3.fromRGB(170, 170, 170)
end

-- Position of a rarity on the ladder, 1 for Common up to 6 for Brainrot God.
function Brainrots.getRarityIndex(rarity)
	for index, name in ipairs(Brainrots.RARITY_ORDER) do
		if name == rarity then
			return index
		end
	end
	return 1
end

-- Pick a random brainrot, weighted so Common appears often and Brainrot God rarely.
function Brainrots.pickRandom()
	local total = 0
	for _, weight in pairs(Brainrots.RARITY_WEIGHTS) do
		total += weight
	end
	local roll = math.random(1, total)
	local running = 0
	local pickedRarity = "Common"
	for _, rarity in ipairs(Brainrots.RARITY_ORDER) do
		running += Brainrots.RARITY_WEIGHTS[rarity]
		if roll <= running then
			pickedRarity = rarity
			break
		end
	end
	local pool = Brainrots.getByRarity(pickedRarity)
	return pool[math.random(1, #pool)]
end

-- Short money text for labels: 1250 -> "$1.2K", 2500000 -> "$2.5M".
function Brainrots.formatMoney(amount)
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount + 0.5))
	end
end

return Brainrots
