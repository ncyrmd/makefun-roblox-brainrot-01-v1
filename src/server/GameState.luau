-- Brainrot Bay: the single state store for the whole game.
-- Every server module reads and writes player state through here, so money,
-- bases, locks and rebirths can never disagree between systems.

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))

local GameState = {}

-- [UserId] = { money, brainrots = { {id, slot} }, rebirths, multiplier, lockUntil, lastStealAt, baseIndex }
GameState.Players = {}
-- [baseIndex] = UserId of the owner, or nil when the base is free
GameState.Bases = {}
GameState.HazardMultiplier = 1 -- 1 normally, Config.HAZARD_INCOME_MULTIPLIER during a storm

-- Create a fresh state row for a player who just joined.
function GameState.createPlayerState(player, baseIndex)
	GameState.Players[player.UserId] = {
		money = Config.STARTING_CASH,
		brainrots = {},
		rebirths = 0,
		multiplier = 1,
		lockUntil = 0,
		lastStealAt = 0,
		baseIndex = baseIndex,
	}
	GameState.Bases[baseIndex] = player.UserId
	return GameState.Players[player.UserId]
end

-- The state row for a player, or nil when they have none.
function GameState.getPlayerState(player)
	return GameState.Players[player.UserId]
end

-- Drop a player's state and free their base when they leave.
function GameState.removePlayerState(player)
	local state = GameState.Players[player.UserId]
	if state and state.baseIndex then
		GameState.Bases[state.baseIndex] = nil
	end
	GameState.Players[player.UserId] = nil
end

-- Dollars per second the player's base earns right now, before the storm bonus.
function GameState.getBaseIncomePerSecond(state)
	local total = 0
	for _, owned in ipairs(state.brainrots) do
		local entry = Brainrots.getById(owned.id)
		if entry then
			total += entry.perSecond
		end
	end
	return total * state.multiplier
end

-- Pay every player their income for one tick. Called once a second by the server.
function GameState.tickIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = GameState.Players[player.UserId]
		if state then
			state.money += GameState.getBaseIncomePerSecond(state) * GameState.HazardMultiplier
		end
	end
end

-- First free slot number on a player's base (1..BASE_SLOTS), or nil when full.
function GameState.findFreeSlot(state)
	local used = {}
	for _, owned in ipairs(state.brainrots) do
		used[owned.slot] = true
	end
	for slot = 1, Config.BASE_SLOTS do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Buy a brainrot and plant it on the buyer's base.
-- Returns ok, message: ok is false with a reason when the buy is refused.
function GameState.buyBrainrot(player, brainrotId)
	local state = GameState.Players[player.UserId]
	local entry = Brainrots.getById(brainrotId)
	if not state then
		return false, "You have no base yet."
	end
	if not entry then
		return false, "That brainrot does not exist."
	end
	if state.money < entry.price then
		return false, "Not enough money for " .. entry.name .. "."
	end
	local slot = GameState.findFreeSlot(state)
	if not slot then
		return false, "Your base is full! Rebirth or steal a better one."
	end
	state.money -= entry.price
	table.insert(state.brainrots, { id = entry.id, slot = slot })
	return true, "Bought " .. entry.name .. " for " .. Brainrots.formatMoney(entry.price) .. "!"
end

-- Take one brainrot out of a player's base by slot, returning its id or nil.
function GameState.removeBrainrotAtSlot(state, slot)
	for index, owned in ipairs(state.brainrots) do
		if owned.slot == slot then
			table.remove(state.brainrots, index)
			return owned.id
		end
	end
	return nil
end

-- True while a base lock bought with LockBase is still running.
function GameState.isBaseLocked(state)
	return os.time() < state.lockUntil
end

-- Seconds left on a base lock, 0 when unlocked.
function GameState.getLockSecondsLeft(state)
	return math.max(0, state.lockUntil - os.time())
end

-- A small public snapshot of a player's state for the HUD sync.
function GameState.getPublicSnapshot(player)
	local state = GameState.Players[player.UserId]
	if not state then
		return nil
	end
	return {
		money = math.floor(state.money),
		perSecond = GameState.getBaseIncomePerSecond(state) * GameState.HazardMultiplier,
		rebirths = state.rebirths,
		multiplier = state.multiplier,
		lockSecondsLeft = GameState.getLockSecondsLeft(state),
		brainrotCount = #state.brainrots,
		baseIndex = state.baseIndex,
	}
end

return GameState
