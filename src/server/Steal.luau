-- Brainrot Bay: stealing and base locks.
-- Stealing is the game's tension: any brainrot on an unlocked base can be taken
-- by clicking it, so a rich base is a target and a lock is real defence.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local Steal = {}

-- Try to steal the brainrot in one slot of a victim's base.
-- Returns ok, message. Refused when the base is locked, the thief is on
-- cooldown, the thief's base is full, or the slot is empty.
function Steal.attemptSteal(thief, victimUserId, slot)
	local thiefState = GameState.getPlayerState(thief)
	if not thiefState then
		return false, "You have no base yet."
	end
	if os.time() - thiefState.lastStealAt < Config.STEAL_COOLDOWN then
		local waitFor = Config.STEAL_COOLDOWN - (os.time() - thiefState.lastStealAt)
		return false, "Steal on cooldown — wait " .. tostring(waitFor) .. "s."
	end
	if victimUserId == thief.UserId then
		return false, "That is your own brainrot!"
	end
	local victimState = GameState.Players[victimUserId]
	if not victimState then
		return false, "That player has no base."
	end
	if GameState.isBaseLocked(victimState) then
		return false, "That base is LOCKED. Try again when the lock runs out!"
	end
	local freeSlot = GameState.findFreeSlot(thiefState)
	if not freeSlot then
		return false, "Your base is full — no room for a stolen brainrot."
	end
	local stolenId = GameState.removeBrainrotAtSlot(victimState, slot)
	if not stolenId then
		return false, "Nothing in that slot to steal."
	end
	local entry = Brainrots.getById(stolenId)
	thiefState.lastStealAt = os.time()
	table.insert(thiefState.brainrots, { id = stolenId, slot = freeSlot })
	if entry then
		return true, "You stole " .. entry.name .. " (" .. entry.rarity .. ")!"
	end
	return true, "You stole a brainrot!"
end

-- Buy a lock for your own base: nobody can steal from it until it expires.
-- Returns ok, message. Refused when already locked or too poor.
function Steal.lockBase(player)
	local state = GameState.getPlayerState(player)
	if not state then
		return false, "You have no base yet."
	end
	if GameState.isBaseLocked(state) then
		return false, "Your base is already locked for "
			.. tostring(GameState.getLockSecondsLeft(state))
			.. "s more."
	end
	if state.money < Config.LOCK_COST then
		return false, "A base lock costs " .. Brainrots.formatMoney(Config.LOCK_COST) .. "."
	end
	state.money -= Config.LOCK_COST
	state.lockUntil = os.time() + Config.LOCK_DURATION
	return true, "Base locked for " .. tostring(Config.LOCK_DURATION) .. " seconds!"
end

return Steal
