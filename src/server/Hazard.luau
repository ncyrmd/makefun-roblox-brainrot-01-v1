-- Brainrot Bay: the Brainrot Storm hazard.
-- Every 90 seconds a storm warning flashes, then the storm sweeps the island:
-- every base earns double, but every player walks at half speed, so a dash home
-- with a fresh catch is a real decision. The storm wall part visibly crosses
-- the map while the storm runs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local GameState = require(script.Parent:WaitForChild("GameState"))

local Hazard = {}
Hazard.Active = false
Hazard.OnStormChanged = nil -- set by init.server.luau to broadcast to clients

-- Tell every client the storm state changed ("warning", "start", "end").
local function broadcast(phase)
	if Hazard.OnStormChanged then
		Hazard.OnStormChanged(phase)
	end
end

-- Slow every player down while the storm runs, restore them after.
local function setAllWalkSpeeds(speed)
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = speed
		end
	end
end

-- Run one full storm cycle: warn, storm, calm. Called in a loop by start().
function Hazard.runOneStorm()
	task.wait(Config.HAZARD_INTERVAL)
	broadcast("warning")
	task.wait(Config.HAZARD_WARNING_SECONDS)

	Hazard.Active = true
	GameState.HazardMultiplier = Config.HAZARD_INCOME_MULTIPLIER
	setAllWalkSpeeds(Config.HAZARD_WALK_SPEED)
	broadcast("start")

	local wall = Workspace:FindFirstChild("StormWall")
	local startTime = os.clock()
	local stormConnection
	stormConnection = RunService.Heartbeat:Connect(function()
		local progress = (os.clock() - startTime) / Config.HAZARD_DURATION
		if progress >= 1 then
			stormConnection:Disconnect()
			return
		end
		-- Sweep the storm wall from one end of the island to the other.
		if wall and wall:IsA("BasePart") then
			wall.CFrame = CFrame.new(-80 + progress * 160, 12, 0)
		end
	end)

	task.wait(Config.HAZARD_DURATION)
	if stormConnection.Connected then
		stormConnection:Disconnect()
	end
	if wall and wall:IsA("BasePart") then
		wall.CFrame = CFrame.new(-120, 12, 0)
	end

	Hazard.Active = false
	GameState.HazardMultiplier = 1
	setAllWalkSpeeds(16)
	broadcast("end")
end

-- Start the endless storm cycle in the background.
function Hazard.start()
	task.spawn(function()
		while true do
			Hazard.runOneStorm()
		end
	end)
end

-- Trigger a storm right now (used by the TOUR.json review step).
function Hazard.triggerStorm(_reason)
	if Hazard.Active then
		return "A storm is already running."
	end
	task.spawn(function()
		broadcast("warning")
		task.wait(2)
		Hazard.Active = true
		GameState.HazardMultiplier = Config.HAZARD_INCOME_MULTIPLIER
		setAllWalkSpeeds(Config.HAZARD_WALK_SPEED)
		broadcast("start")
		task.wait(Config.HAZARD_DURATION)
		Hazard.Active = false
		GameState.HazardMultiplier = 1
		setAllWalkSpeeds(16)
		broadcast("end")
	end)
	return "Brainrot Storm incoming!"
end

return Hazard
