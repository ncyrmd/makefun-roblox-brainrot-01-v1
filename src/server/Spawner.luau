-- Brainrot Bay: the conveyor spawner.
-- Brainrots appear at the west end of the central conveyor and waddle east
-- along it, each one a little character with a floating name / rarity / $/sec
-- label. Click one to buy it (if you can afford it and have a free base slot);
-- unclaimed ones fall off the east end and despawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))

local Spawner = {}
Spawner.OnBrainrotClicked = nil -- set by init.server.luau: (player, brainrotId, model)
Spawner.Active = {} -- live conveyor models, newest last

-- Build the little character model for one brainrot entry.
local function buildBrainrotModel(entry)
	local model = Instance.new("Model")
	model.Name = "Brainrot_" .. entry.id

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Anchored = true
	body.CanCollide = false
	body.Size = Vector3.new(4, 3, 2)
	body.Color = entry.color
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Size = Vector3.new(2.4, 2.2, 2)
	head.Color = Color3.fromRGB(255, 220, 180)
	head.Material = Enum.Material.SmoothPlastic
	head.Parent = model

	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	-- Floating label: name, rarity and $/sec, readable from across the map.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(220, 90)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = entry.rarity
	rarityLabel.TextColor3 = Brainrots.getRarityColor(entry.rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = billboard

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Position = UDim2.new(0, 0, 0.7, 0)
	priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = Brainrots.formatMoney(entry.price) .. "  ·  "
		.. Brainrots.formatMoney(entry.perSecond) .. "/s"
	priceLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	priceLabel.TextScaled = true
	priceLabel.Font = Enum.Font.GothamBold
	priceLabel.Parent = billboard

	local clicker = Instance.new("ClickDetector")
	clicker.Name = "BuyClick"
	clicker.MaxActivationDistance = 32
	clicker.Parent = body

	model.PrimaryPart = body
	return model
end

-- Spawn one random brainrot at the west end of the conveyor.
function Spawner.spawnOne()
	if #Spawner.Active >= Config.MAX_CONVEYOR_BRAINROTS then
		return nil
	end
	local entry = Brainrots.pickRandom()
	local model = buildBrainrotModel(entry)
	model:SetAttribute("BrainrotId", entry.id)
	model:SetAttribute("SpawnedAt", os.time())
	model.Parent = Workspace
	model:PivotTo(CFrame.new(Config.CONVEYOR_START_X, Config.CONVEYOR_Y, 0))

	local body = model:FindFirstChild("Body")
	local clicker = body and body:FindFirstChildOfClass("ClickDetector")
	if clicker then
		clicker.MouseClick:Connect(function(player)
			if Spawner.OnBrainrotClicked then
				Spawner.OnBrainrotClicked(player, entry.id, model)
			end
		end)
	end

	table.insert(Spawner.Active, model)
	return model
end

-- Remove a conveyor model from the world and from the live list.
function Spawner.removeModel(model)
	for index, live in ipairs(Spawner.Active) do
		if live == model then
			table.remove(Spawner.Active, index)
			break
		end
	end
	model:Destroy()
end

-- Move every live brainrot east along the conveyor; despawn at the east end.
local function stepConveyor(dt)
	for index = #Spawner.Active, 1, -1 do
		local model = Spawner.Active[index]
		if not model.Parent then
			table.remove(Spawner.Active, index)
		else
			local pivot = model:GetPivot()
			local nextX = pivot.Position.X + Config.CONVEYOR_SPEED * dt
			if nextX >= Config.CONVEYOR_END_X then
				Spawner.removeModel(model)
			else
				model:PivotTo(CFrame.new(nextX, Config.CONVEYOR_Y, 0))
			end
		end
	end
end

-- Start spawning brainrots on a timer and walking them down the conveyor.
function Spawner.start()
	RunService.Heartbeat:Connect(stepConveyor)
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL)
			Spawner.spawnOne()
		end
	end)
end

return Spawner
