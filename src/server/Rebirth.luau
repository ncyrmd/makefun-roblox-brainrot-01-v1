-- Brainrot Bay: rebirths.
-- A rebirth trades everything the player owns for a permanent income bonus,
-- so the ladder never ends: richer brainrots fund the next rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local Rebirth = {}

-- Cash a rebirth costs when the player already owns this many rebirths.
function Rebirth.getRebirthCost(rebirthsOwned)
	return math.floor(Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_GROWTH ^ rebirthsOwned) + 0.5)
end

-- Spend the cash, clear the base, and grant +25% income forever.
-- Returns ok, message. Refused when the player cannot afford it yet.
function Rebirth.attemptRebirth(player)
	local state = GameState.getPlayerState(player)
	if not state then
		return false, "You have no base yet."
	end
	local cost = Rebirth.getRebirthCost(state.rebirths)
	if state.money < cost then
		return false, "Rebirth costs " .. Brainrots.formatMoney(cost) .. " — you have "
			.. Brainrots.formatMoney(state.money) .. "."
	end
	state.money = Config.STARTING_CASH
	state.brainrots = {}
	state.rebirths += 1
	state.multiplier = 1 + state.rebirths * Config.REBIRTH_MULTIPLIER_BONUS
	state.lockUntil = 0
	return true, "REBIRTH #" .. tostring(state.rebirths) .. "! Income is now x"
		.. string.format("%.2f", state.multiplier) .. " forever."
end

return Rebirth
