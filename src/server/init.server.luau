-- Brainrot Bay server: wires the whole game together.
-- Creates the remotes, hands each joining player a base, pays income every
-- second, syncs the HUD, and turns buys / steals / locks / rebirths into
-- visible brainrots standing on base slots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))
local Spawner = require(script.Parent:WaitForChild("Spawner"))
local Steal = require(script.Parent:WaitForChild("Steal"))
local Rebirth = require(script.Parent:WaitForChild("Rebirth"))
local Hazard = require(script.Parent:WaitForChild("Hazard"))

-- RemoteEvents live under ReplicatedStorage/BrainrotRemotes.
local remotes = Instance.new("Folder")
remotes.Name = "BrainrotRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local BuyRemote = makeRemote("BuyBrainrot")
local StealRemote = makeRemote("StealBrainrot")
local LockRemote = makeRemote("LockBase")
local RebirthRemote = makeRemote("Rebirth")
local NotifyRemote = makeRemote("Notify")
local StateSyncRemote = makeRemote("StateSync")
local HazardRemote = makeRemote("HazardEvent")

-- [baseIndex] = { [slot] = brainrot Model standing on that slot }
local BaseVisuals = {}

-- Tell one player something in their HUD toast.
local function notify(player, message)
	NotifyRemote:FireClient(player, message)
end

-- The world position of one base slot, from the place built in default.project.json.
local function getSlotPosition(baseIndex, slot)
	local bases = Workspace:FindFirstChild("Bases")
	local base = bases and bases:FindFirstChild("Base" .. tostring(baseIndex))
	local slotPart = base and base:FindFirstChild("Slot" .. tostring(slot))
	if slotPart and slotPart:IsA("BasePart") then
		return slotPart.Position + Vector3.new(0, 2, 0)
	end
	return Vector3.new(0, 5, 0)
end

-- Build the little standing model of a brainrot on a base slot, clickable to steal.
local function buildBaseBrainrot(entry, baseIndex, slot)
	local model = Instance.new("Model")
	model.Name = "Owned_" .. entry.id

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(3.4, 2.6, 2)
	body.Color = entry.color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(200, 80)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = entry.rarity
	rarityLabel.TextColor3 = Brainrots.getRarityColor(entry.rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 0, 0.7, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = Brainrots.formatMoney(entry.perSecond) .. "/s"
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = billboard

	local clicker = Instance.new("ClickDetector")
	clicker.Name = "StealClick"
	clicker.MaxActivationDistance = 32
	clicker.Parent = body
	clicker.MouseClick:Connect(function(clickingPlayer)
		local victimUserId = GameState.Bases[baseIndex]
		if not victimUserId then
			return
		end
		local ok, message = Steal.attemptSteal(clickingPlayer, victimUserId, slot)
		notify(clickingPlayer, message)
		if ok then
			refreshBaseVisuals(baseIndex)
			local thiefState = GameState.getPlayerState(clickingPlayer)
			if thiefState then
				refreshBaseVisuals(thiefState.baseIndex)
			end
		end
	end)

	model.PrimaryPart = body
	model:PivotTo(CFrame.new(getSlotPosition(baseIndex, slot)))
	model.Parent = Workspace
	return model
end

-- Rebuild every standing brainrot on one base from its owner's state.
function refreshBaseVisuals(baseIndex)
	local visuals = BaseVisuals[baseIndex]
	if visuals then
		for _, model in pairs(visuals) do
			model:Destroy()
		end
	end
	BaseVisuals[baseIndex] = {}
	local ownerUserId = GameState.Bases[baseIndex]
	local ownerState = ownerUserId and GameState.Players[ownerUserId]
	if not ownerState then
		return
	end
	for _, owned in ipairs(ownerState.brainrots) do
		local entry = Brainrots.getById(owned.id)
		if entry then
			BaseVisuals[baseIndex][owned.slot] = buildBaseBrainrot(entry, baseIndex, owned.slot)
		end
	end
end

-- First free base index (1..MAX_BASES), or nil when the island is full.
local function claimFreeBase()
	for index = 1, Config.MAX_BASES do
		if not GameState.Bases[index] then
			return index
		end
	end
	return nil
end

-- Set up one joining player: base, leaderstats, spawn point, storm speed.
local function onPlayerAdded(player)
	local baseIndex = claimFreeBase()
	if not baseIndex then
		notify(player, "The island is full — all 4 bases are taken!")
		return
	end
	GameState.createPlayerState(player, baseIndex)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local moneyValue = Instance.new("IntValue")
	moneyValue.Name = "Money"
	moneyValue.Value = Config.STARTING_CASH
	moneyValue.Parent = leaderstats

	local rebirthValue = Instance.new("IntValue")
	rebirthValue.Name = "Rebirths"
	rebirthValue.Value = 0
	rebirthValue.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		if Hazard.Active then
			humanoid.WalkSpeed = Config.HAZARD_WALK_SPEED
		end
		-- Spawn on your own base's spawn pad.
		local root = character:WaitForChild("HumanoidRootPart")
		local bases = Workspace:FindFirstChild("Bases")
		local base = bases and bases:FindFirstChild("Base" .. tostring(baseIndex))
		local pad = base and base:FindFirstChild("SpawnPad")
		if pad and pad:IsA("BasePart") then
			root.CFrame = CFrame.new(pad.Position + Vector3.new(0, 3, 0))
		end
	end)

	notify(player, "Welcome to Brainrot Bay! Your base is Base " .. tostring(baseIndex)
		.. ". Click a brainrot on the conveyor to buy it!")
end

local function onPlayerRemoving(player)
	local state = GameState.getPlayerState(player)
	if state then
		local baseIndex = state.baseIndex
		GameState.removePlayerState(player)
		refreshBaseVisuals(baseIndex)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Buying from the Shop panel: same rules as clicking the conveyor.
BuyRemote.OnServerEvent:Connect(function(player, brainrotId)
	local ok, message = GameState.buyBrainrot(player, brainrotId)
	notify(player, message)
	if ok then
		local state = GameState.getPlayerState(player)
		if state then
			refreshBaseVisuals(state.baseIndex)
		end
	end
end)

-- Buying by clicking a brainrot walking down the conveyor.
Spawner.OnBrainrotClicked = function(player, brainrotId, model)
	local ok, message = GameState.buyBrainrot(player, brainrotId)
	notify(player, message)
	if ok then
		Spawner.removeModel(model)
		local state = GameState.getPlayerState(player)
		if state then
			refreshBaseVisuals(state.baseIndex)
		end
	end
end

-- Steals normally come from clicking a brainrot on another player's base;
-- the remote also accepts a steal request for clients that send one.
StealRemote.OnServerEvent:Connect(function(player, victimUserId, slot)
	local ok, message = Steal.attemptSteal(player, victimUserId, slot)
	notify(player, message)
	if ok then
		local victimState = GameState.Players[victimUserId]
		if victimState then
			refreshBaseVisuals(victimState.baseIndex)
		end
		local thiefState = GameState.getPlayerState(player)
		if thiefState then
			refreshBaseVisuals(thiefState.baseIndex)
		end
	end
end)

LockRemote.OnServerEvent:Connect(function(player)
	local _ok, message = Steal.lockBase(player)
	notify(player, message)
end)

RebirthRemote.OnServerEvent:Connect(function(player)
	local ok, message = Rebirth.attemptRebirth(player)
	notify(player, message)
	if ok then
		local state = GameState.getPlayerState(player)
		if state then
			refreshBaseVisuals(state.baseIndex)
		end
	end
end)

-- Broadcast storm phases to every client.
Hazard.OnStormChanged = function(phase)
	HazardRemote:FireAllClients(phase)
end

-- Income tick + HUD sync, once a second.
task.spawn(function()
	while true do
		task.wait(Config.INCOME_TICK_SECONDS)
		GameState.tickIncome()
		for _, player in ipairs(Players:GetPlayers()) do
			local snapshot = GameState.getPublicSnapshot(player)
			if snapshot then
				StateSyncRemote:FireClient(player, snapshot)
				local leaderstats = player:FindFirstChild("leaderstats")
				local moneyValue = leaderstats and leaderstats:FindFirstChild("Money")
				if moneyValue and moneyValue:IsA("IntValue") then
					moneyValue.Value = snapshot.money
				end
				local rebirthValue = leaderstats and leaderstats:FindFirstChild("Rebirths")
				if rebirthValue and rebirthValue:IsA("IntValue") then
					rebirthValue.Value = snapshot.rebirths
				end
			end
		end
	end
end)

Spawner.start()
Hazard.start()
print("Brainrot Bay server ready: 4 bases, conveyor live, storms every "
	.. tostring(Config.HAZARD_INTERVAL) .. "s.")
