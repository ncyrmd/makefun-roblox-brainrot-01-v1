-- Brainrot Bay client: the HUD over the 3D world.
-- Money, Shop, base buttons and storm warnings. All HUD text stays clear of
-- the top-left corner, where Roblox's own menu buttons sit. Keys are bound
-- with ContextActionService, never InputBegan + gameProcessedEvent, because
-- Roblox's camera eats arrow keys before InputBegan ever sees them.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Brainrots = require(Shared:WaitForChild("Brainrots"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")

local BuyRemote = Remotes:WaitForChild("BuyBrainrot")
local LockRemote = Remotes:WaitForChild("LockBase")
local RebirthRemote = Remotes:WaitForChild("Rebirth")
local NotifyRemote = Remotes:WaitForChild("Notify")
local StateSyncRemote = Remotes:WaitForChild("StateSync")
local HazardRemote = Remotes:WaitForChild("HazardEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Title, top-center (never top-left: Roblox menu buttons live there).
local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0, 8)
title.Size = UDim2.fromOffset(360, 44)
title.BackgroundTransparency = 1
title.Text = "🌴 BRAINROT BAY"
title.TextColor3 = Color3.fromRGB(255, 220, 90)
title.TextSize = 32
title.Font = Enum.Font.GothamBlack
title.TextStrokeTransparency = 0.2
title.Parent = gui

-- Storm banner, under the title, hidden until a storm warns or hits.
local stormBanner = Instance.new("TextLabel")
stormBanner.Name = "StormBanner"
stormBanner.AnchorPoint = Vector2.new(0.5, 0)
stormBanner.Position = UDim2.new(0.5, 0, 0, 58)
stormBanner.Size = UDim2.fromOffset(460, 36)
stormBanner.BackgroundColor3 = Color3.fromRGB(140, 40, 40)
stormBanner.BackgroundTransparency = 0.15
stormBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
stormBanner.TextSize = 22
stormBanner.Font = Enum.Font.GothamBold
stormBanner.Text = ""
stormBanner.Visible = false
stormBanner.Parent = gui

-- Money panel, top-right.
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.AnchorPoint = Vector2.new(1, 0)
moneyPanel.Position = UDim2.new(1, -12, 0, 8)
moneyPanel.Size = UDim2.fromOffset(250, 96)
moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
moneyPanel.BackgroundTransparency = 0.25
moneyPanel.BorderSizePixel = 0
moneyPanel.Parent = gui

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.new(1, -16, 0, 36)
moneyLabel.Position = UDim2.new(0, 8, 0, 4)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "💰 $100"
moneyLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
moneyLabel.TextSize = 26
moneyLabel.Font = Enum.Font.GothamBold
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyPanel

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(1, -16, 0, 26)
incomeLabel.Position = UDim2.new(0, 8, 0, 40)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "+$0/s"
incomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
incomeLabel.TextSize = 20
incomeLabel.Font = Enum.Font.GothamBold
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = moneyPanel

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Name = "RebirthLabel"
rebirthLabel.Size = UDim2.new(1, -16, 0, 26)
rebirthLabel.Position = UDim2.new(0, 8, 0, 66)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.Text = "🔁 Rebirths: 0  (x1.00)"
rebirthLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
rebirthLabel.TextSize = 18
rebirthLabel.Font = Enum.Font.GothamBold
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
rebirthLabel.Parent = moneyPanel

-- Shop panel, right side under the money panel: the full cast with Buy buttons.
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(1, 0)
shopFrame.Position = UDim2.new(1, -12, 0, 116)
shopFrame.Size = UDim2.fromOffset(250, 420)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
shopFrame.BackgroundTransparency = 0.25
shopFrame.BorderSizePixel = 0
shopFrame.Parent = gui

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "ShopTitle"
shopTitle.Size = UDim2.new(1, 0, 0, 32)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "🛒 BRAINROT SHOP  (B to hide)"
shopTitle.TextColor3 = Color3.fromRGB(255, 220, 90)
shopTitle.TextSize = 18
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Parent = shopFrame

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopList"
shopList.Position = UDim2.new(0, 0, 0, 34)
shopList.Size = UDim2.new(1, 0, 1, -34)
shopList.BackgroundTransparency = 1
shopList.ScrollBarThickness = 6
shopList.CanvasSize = UDim2.new(0, 0, 0, #Brainrots.CAST * 46)
shopList.Parent = shopFrame

local function makeShopRow(entry, index)
	local row = Instance.new("Frame")
	row.Name = "ShopRow_" .. entry.id
	row.Size = UDim2.new(1, -8, 0, 42)
	row.Position = UDim2.new(0, 4, 0, (index - 1) * 46)
	row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	row.BackgroundTransparency = 0.88
	row.BorderSizePixel = 0
	row.Parent = shopList

	local swatch = Instance.new("Frame")
	swatch.Size = UDim2.fromOffset(14, 14)
	swatch.Position = UDim2.fromOffset(6, 6)
	swatch.BackgroundColor3 = entry.color
	swatch.BorderSizePixel = 0
	swatch.Parent = row

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromOffset(26, 2)
	nameLabel.Size = UDim2.new(1, -90, 0, 20)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = row

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Position = UDim2.fromOffset(26, 22)
	infoLabel.Size = UDim2.new(1, -90, 0, 18)
	infoLabel.BackgroundTransparency = 1
	infoLabel.Text = entry.rarity .. " · " .. Brainrots.formatMoney(entry.perSecond) .. "/s"
	infoLabel.TextColor3 = Brainrots.getRarityColor(entry.rarity)
	infoLabel.TextSize = 13
	infoLabel.Font = Enum.Font.GothamBold
	infoLabel.TextXAlignment = Enum.TextXAlignment.Left
	infoLabel.Parent = row

	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.AnchorPoint = Vector2.new(1, 0)
	buyButton.Position = UDim2.new(1, -4, 0, 5)
	buyButton.Size = UDim2.fromOffset(58, 32)
	buyButton.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
	buyButton.Text = Brainrots.formatMoney(entry.price)
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.TextSize = 14
	buyButton.Font = Enum.Font.GothamBold
	buyButton.Parent = row
	buyButton.MouseButton1Click:Connect(function()
		BuyRemote:FireServer(entry.id)
	end)
	return row
end

for index, entry in ipairs(Brainrots.CAST) do
	makeShopRow(entry, index)
end

-- Bottom-center action buttons: Lock Base and Rebirth.
local buttonRow = Instance.new("Frame")
buttonRow.Name = "ActionButtons"
buttonRow.AnchorPoint = Vector2.new(0.5, 1)
buttonRow.Position = UDim2.new(0.5, 0, 1, -12)
buttonRow.Size = UDim2.fromOffset(430, 48)
buttonRow.BackgroundTransparency = 1
buttonRow.Parent = gui

local function makeActionButton(name, text, xOffset, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(xOffset, 0)
	button.Size = UDim2.fromOffset(205, 48)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.Parent = buttonRow
	return button
end

local lockButton = makeActionButton(
	"LockButton",
	"🔒 Lock Base (L) — $500",
	0,
	Color3.fromRGB(60, 110, 220)
)
local rebirthButton = makeActionButton(
	"RebirthButton",
	"🔁 Rebirth — $100K",
	220,
	Color3.fromRGB(180, 60, 200)
)

lockButton.MouseButton1Click:Connect(function()
	LockRemote:FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	RebirthRemote:FireServer()
end)

-- Toast: server messages (buys, steals, locks, rebirths) above the buttons.
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -68)
toast.Size = UDim2.fromOffset(560, 30)
toast.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toast.BackgroundTransparency = 0.4
toast.Text = "Click a brainrot on the conveyor to buy it!"
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextSize = 17
toast.Font = Enum.Font.GothamBold
toast.Parent = gui

local toastHideAt = 0
local function showToast(message)
	toast.Text = message
	toast.Visible = true
	toastHideAt = os.clock() + 4
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if toast.Visible and os.clock() > toastHideAt then
			toast.Visible = false
		end
	end
end)

-- Hint line, bottom-left: how stealing works.
local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(0, 1)
hint.Position = UDim2.new(0, 12, 1, -12)
hint.Size = UDim2.fromOffset(330, 44)
hint.BackgroundTransparency = 1
hint.Text = "Steal: click a brainrot on a rival base.\nLocked bases can't be robbed!"
hint.TextColor3 = Color3.fromRGB(230, 230, 230)
hint.TextSize = 15
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = gui

-- Keybinds via ContextActionService: L locks the base, B toggles the shop.
local function onLockAction(_actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		LockRemote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("BrainrotBayLockBase", onLockAction, false, Enum.KeyCode.L)

local function onToggleShop(_actionName, inputState, _inputObject)
	if inputState == Enum.UserInputState.Begin then
		shopFrame.Visible = not shopFrame.Visible
	end
	return Enum.ContextActionResult.Sink
end
ContextActionService:BindAction("BrainrotBayToggleShop", onToggleShop, false, Enum.KeyCode.B)

-- Server pushes: state sync, toasts, storm phases.
StateSyncRemote.OnClientEvent:Connect(function(snapshot)
	moneyLabel.Text = "💰 " .. Brainrots.formatMoney(snapshot.money)
	incomeLabel.Text = "+" .. Brainrots.formatMoney(snapshot.perSecond) .. "/s  ·  "
		.. tostring(snapshot.brainrotCount) .. "/" .. tostring(Config.BASE_SLOTS) .. " on base"
	rebirthLabel.Text = "🔁 Rebirths: " .. tostring(snapshot.rebirths) .. "  (x"
		.. string.format("%.2f", snapshot.multiplier) .. ")"
	if snapshot.lockSecondsLeft > 0 then
		lockButton.Text = "🔒 Locked — " .. tostring(snapshot.lockSecondsLeft) .. "s left"
	else
		lockButton.Text = "🔒 Lock Base (L) — " .. Brainrots.formatMoney(Config.LOCK_COST)
	end
	local rebirthCost = math.floor(
		Config.REBIRTH_BASE_COST * (Config.REBIRTH_COST_GROWTH ^ snapshot.rebirths) + 0.5
	)
	rebirthButton.Text = "🔁 Rebirth — " .. Brainrots.formatMoney(rebirthCost)
end)

NotifyRemote.OnClientEvent:Connect(function(message)
	showToast(message)
end)

HazardRemote.OnClientEvent:Connect(function(phase)
	if phase == "warning" then
		stormBanner.Text = "⛈️ BRAINROT STORM INCOMING — income 2×, walk speed halved!"
		stormBanner.Visible = true
	elseif phase == "start" then
		stormBanner.Text = "⛈️ STORM! 2× INCOME — dash home with your catch!"
		stormBanner.Visible = true
	elseif phase == "end" then
		stormBanner.Text = ""
		stormBanner.Visible = false
	end
end)

print("Brainrot Bay client ready: HUD live, shop has " .. tostring(#Brainrots.CAST) .. " brainrots.")
