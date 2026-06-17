--[[
    Kaitun Hub - Anime Warriors 3 (One Button Auto Pilot)
    Phiên bản: 6.0
    Tác giả: Kaitun
    - Tự động chạy tất cả khi load script (Farm, Quest, Stats, ESP).
    - Một nút STOP nhỏ ở góc phải để dừng/tiếp tục mọi thứ.
    - Tự động cầm vũ khí, ưu tiên đánh quái máu thấp nhất trên đảo hiện tại.
    - Cần cập nhật tọa độ thực của các đảo trong bảng ISLANDS.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ================== CẤU HÌNH ==================
local FARM_RANGE = 250  -- Phạm vi tìm quái (có thể sửa trực tiếp)

-- ================== HỆ THỐNG ĐẢO (CẦN TỌA ĐỘ THỰC TẾ) ==================
local ISLANDS = {
    {Name = "Starter Island",     Center = Vector3.new(0, 50, 0),    Radius = 200},
    {Name = "Sand Village",       Center = Vector3.new(500, 50, 0),  Radius = 250},
    {Name = "Leaf Village",       Center = Vector3.new(-500, 50, 0), Radius = 250},
    {Name = "Cloud Village",      Center = Vector3.new(0, 300, 500), Radius = 200},
    {Name = "Mist Village",       Center = Vector3.new(0, 50, -500), Radius = 200},
    {Name = "War Zone",           Center = Vector3.new(1000, 50, 1000), Radius = 300},
    {Name = "Training Grounds",   Center = Vector3.new(-1000, 50, -1000), Radius = 250},
}

-- Trạng thái (mặc định bật tất cả)
local autoFarm = true
local autoQuest = true
local autoStats = true
local espEnabled = true

-- ================== CHỨC NĂNG ==================
local function getCurrentIsland()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    local pos = LocalPlayer.Character.HumanoidRootPart.Position
    local closestIsland = nil
    local closestDistance = math.huge

    for _, island in ipairs(ISLANDS) do
        local dist = (pos - island.Center).Magnitude
        if dist <= island.Radius then
            if dist < closestDistance then
                closestDistance = dist
                closestIsland = island
            end
        end
    end
    return closestIsland
end

local function findNPCOnIsland(island)
    if not island then return nil end
    local npcs = {}
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if not Players:GetPlayerFromCharacter(v) then
                local hrp = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Head")
                if hrp then
                    local dist = (hrp.Position - island.Center).Magnitude
                    if dist <= island.Radius then
                        table.insert(npcs, v)
                    end
                end
            end
        end
    end
    if #npcs == 0 then return nil end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local playerPos = LocalPlayer.Character.HumanoidRootPart.Position
        table.sort(npcs, function(a, b)
            local rootA = a:FindFirstChild("HumanoidRootPart") or a.Head
            local rootB = b:FindFirstChild("HumanoidRootPart") or b.Head
            return (rootA.Position - playerPos).Magnitude < (rootB.Position - playerPos).Magnitude
        end)
    end
    return npcs[1]
end

local function equipBestWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer.Backpack
    if not backpack then return end

    local currentTool = char:FindFirstChildOfClass("Tool")
    local tools = {}
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then table.insert(tools, tool) end
    end
    if #tools == 0 and not currentTool then return end

    table.sort(tools, function(a, b)
        local dmgA = a:GetAttribute("Damage") or 0
        local dmgB = b:GetAttribute("Damage") or 0
        if dmgA ~= dmgB then return dmgA > dmgB end
        local keywords = {"sword", "blade", "kunai", "shuriken", "rasengan", "chidori", "katana"}
        local pA, pB = 0, 0
        for i, kw in ipairs(keywords) do
            if a.Name:lower():find(kw) then pA = math.max(pA, i) end
            if b.Name:lower():find(kw) then pB = math.max(pB, i) end
        end
        if pA ~= pB then return pA > pB end
        return #a.Name > #b.Name
    end)

    local bestTool = tools[1]
    if currentTool == bestTool then return end
    if currentTool then currentTool.Parent = backpack end
    if bestTool then bestTool.Parent = char end
end

local function findBestTarget()
    local island = getCurrentIsland()
    if not island then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local targets = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local objPos = obj.HumanoidRootPart.Position
                local distToCenter = (objPos - island.Center).Magnitude
                if distToCenter <= island.Radius then
                    local distToPlayer = (objPos - root.Position).Magnitude
                    if distToPlayer <= FARM_RANGE then
                        table.insert(targets, {obj = obj, hp = hum.Health, dist = distToPlayer})
                    end
                end
            end
        end
    end
    if #targets == 0 then return nil end
    table.sort(targets, function(a, b)
        if a.hp ~= b.hp then return a.hp < b.hp
        else return a.dist < b.dist end
    end)
    return targets[1].obj
end

local function findRemote(keyword)
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name:lower():find(keyword:lower()) then
            return v
        end
    end
    return nil
end

local attackRemote = findRemote("attack") or findRemote("hit") or findRemote("damage")
local startQuestRemote = findRemote("startquest") or findRemote("takequest") or findRemote("acceptquest")
local completeQuestRemote = findRemote("completequest") or findRemote("finishquest") or findRemote("submitquest")
local addStatsRemote = findRemote("addstats") or findRemote("upgrade") or findRemote("stat")

-- Auto Farm
local function doAutoFarm()
    if not autoFarm then return end
    equipBestWeapon()
    local target = findBestTarget()
    if target then
        LocalPlayer.Character:MoveTo(target.HumanoidRootPart.Position)
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Activate") then
            tool:Activate()
        end
        if attackRemote then
            pcall(function() attackRemote:FireServer(target) end)
        end
    end
end

-- Auto Quest
local lastQuestTime = 0
local function doAutoQuest()
    if not autoQuest then return end
    if tick() - lastQuestTime < 15 then return end

    local island = getCurrentIsland()
    if not island then return end
    local npc = findNPCOnIsland(island)
    if not npc then return end

    lastQuestTime = tick()
    local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
    if not npcRoot then return end

    LocalPlayer.Character:MoveTo(npcRoot.Position)
    wait(1.5)

    if startQuestRemote then
        pcall(function() startQuestRemote:FireServer() end)
    end
    wait(5)

    if completeQuestRemote then
        pcall(function() completeQuestRemote:FireServer() end)
    end
end

-- Auto Stats
local function doAutoStats()
    if not autoStats then return end
    if not addStatsRemote then return end
    local stats = {"Strength", "Defense", "Speed", "Chakra", "Sword", "Health"}
    for _, stat in ipairs(stats) do
        pcall(function() addStatsRemote:FireServer(stat) end)
        wait(0.15)
    end
end

-- ESP
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            if espEnabled then
                if not char:FindFirstChild("ESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.Parent = char
                    hl.FillTransparency = 0.5
                    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
                end
            else
                local hl = char:FindFirstChild("ESP_Highlight")
                if hl then hl:Destroy() end
            end
        end
    end
end

-- ================== GIAO DIỆN NÚT STOP ==================
local function createStopButton()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaitunHub"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Name = "StopButton"
    btn.Parent = ScreenGui
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.Position = UDim2.new(0.92, -40, 0.02, 0) -- góc trên phải
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- đỏ
    btn.Text = "STOP"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.Active = true
    btn.Draggable = true
    btn.ZIndex = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local running = true

    btn.MouseButton1Click:Connect(function()
        running = not running
        if running then
            autoFarm = true
            autoQuest = true
            autoStats = true
            espEnabled = true
            btn.Text = "STOP"
            btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        else
            autoFarm = false
            autoQuest = false
            autoStats = false
            espEnabled = false
            btn.Text = "START"
            btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
        end
    end)
end

-- ================== KHỞI ĐỘNG ==================
createStopButton()
print("[Kaitun] Auto Pilot started. Press STOP button to pause.")

-- Vòng lặp chính
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        doAutoFarm()
        updateESP()
    end
end)

spawn(function()
    while wait(15) do
        if autoQuest then doAutoQuest() end
    end
end)

spawn(function()
    while wait(5) do
        if autoStats then doAutoStats() end
    end
end)
