--[[
    Kaitun Hub - Anime Warriors 3 (Island System - Real Island Names)
    Phiên bản: 4.1
    Tác giả: Kaitun
    ISLANDS đã được đặt tên theo map thực tế. Bạn cần cập nhật tọa độ Center và Radius!
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ANIME_BG_IMAGE = "rbxassetid://7483861177"

local autoFarm = false
local autoQuest = false
local autoStats = false
local espEnabled = false

-- ================== HỆ THỐNG ĐẢO (CẬP NHẬT TỌA ĐỘ THỰC TẾ) ==================
-- Hướng dẫn lấy tọa độ: 
--   1. Đứng giữa đảo, mở executor chạy: print(game.Players.LocalPlayer.Character.HumanoidRootPart.Position)
--   2. Copy kết quả (dạng Vector3.new(x, y, z)) vào Center.
--   3. Ước lượng bán kính (khoảng cách từ tâm đến rìa đảo) và điền vào Radius.
local ISLANDS = {
    {Name = "Starter Island",     Center = Vector3.new(0, 50, 0),    Radius = 200},  -- Đảo khởi đầu
    {Name = "Sand Village",       Center = Vector3.new(500, 50, 0),  Radius = 250},  -- Làng Cát
    {Name = "Leaf Village",       Center = Vector3.new(-500, 50, 0), Radius = 250},  -- Làng Lá
    {Name = "Cloud Village",      Center = Vector3.new(0, 300, 500), Radius = 200},  -- Làng Mây
    {Name = "Mist Village",       Center = Vector3.new(0, 50, -500), Radius = 200},  -- Làng Sương
    {Name = "War Zone",           Center = Vector3.new(1000, 50, 1000), Radius = 300}, -- Khu vực chiến đấu
    {Name = "Training Grounds",   Center = Vector3.new(-1000, 50, -1000), Radius = 250},
    -- Thêm đảo khác nếu có (VD: Boss Room, Event Island...)
}

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
                        local name = v.Name:lower()
                        if name:find("quest") or name:find("npc") or name:find("giver") or true then
                            table.insert(npcs, v)
                        end
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

local function getQuestNPCForCurrentIsland()
    local island = getCurrentIsland()
    if island then
        return findNPCOnIsland(island)
    end
    return nil
end

local function teleportToQuestNPC()
    local npc = getQuestNPCForCurrentIsland()
    if npc and LocalPlayer.Character then
        local target = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
        if target then
            LocalPlayer.Character:MoveTo(target.Position)
        end
    end
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

local function getNearestMob()
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local nearest, minDist = nil, math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local dist = (obj.HumanoidRootPart.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

local function doAutoFarm()
    if not autoFarm then return end
    local mob = getNearestMob()
    if mob then
        LocalPlayer.Character:MoveTo(mob.HumanoidRootPart.Position)
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Activate") then
            tool:Activate()
        end
        if attackRemote then
            pcall(function() attackRemote:FireServer(mob) end)
        end
    end
end

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

local function doAutoStats()
    if not autoStats then return end
    if not addStatsRemote then return end
    local stats = {"Strength", "Defense", "Speed", "Chakra", "Sword", "Health"}
    for _, stat in ipairs(stats) do
        pcall(function() addStatsRemote:FireServer(stat) end)
        wait(0.15)
    end
end

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

local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaitunHub"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.Size = UDim2.new(0, 320, 0, 480)
    Main.Position = UDim2.new(0.05, 0, 0.08, 0)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Main.BackgroundTransparency = 0.1
    Main.Active = true
    Main.Draggable = true
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local img = Instance.new("ImageLabel")
    img.Parent = Main
    img.Size = UDim2.new(1, 0, 1, 0)
    img.Image = ANIME_BG_IMAGE
    img.ScaleType = Enum.ScaleType.Crop
    img.BackgroundTransparency = 1
    img.ZIndex = 1

    local ov = Instance.new("Frame")
    ov.Parent = Main
    ov.Size = UDim2.new(1, 0, 1, 0)
    ov.BackgroundColor3 = Color3.fromRGB(0,0,0)
    ov.BackgroundTransparency = 0.55
    ov.ZIndex = 2

    local title = Instance.new("TextLabel")
    title.Parent = Main
    title.Size = UDim2.new(1,0,0,45)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "⚔️ KAITUN HUB ⚔️"
    title.TextColor3 = Color3.fromRGB(255,215,0)
    title.TextSize = 22
    title.ZIndex = 3

    local function makeToggle(name, y, startState, callback)
        local btn = Instance.new("TextButton")
        btn.Parent = Main
        btn.Position = UDim2.new(0.1, 0, y, 0)
        btn.Size = UDim2.new(0.8, 0, 0, 40)
        btn.BackgroundColor3 = startState and Color3.fromRGB(34,139,34) or Color3.fromRGB(178,34,34)
        btn.Text = name .. ": " .. (startState and "ON" or "OFF")
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 16
        btn.ZIndex = 3
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

        local state = startState
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = name .. ": " .. (state and "ON" or "OFF")
            btn.BackgroundColor3 = state and Color3.fromRGB(34,139,34) or Color3.fromRGB(178,34,34)
            callback(state)
        end)
        btn.MouseEnter:Connect(function()
            btn.BackgroundColor3 = state and Color3.fromRGB(50,180,50) or Color3.fromRGB(200,60,60)
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundColor3 = state and Color3.fromRGB(34,139,34) or Color3.fromRGB(178,34,34)
        end)
        return btn
    end

    makeToggle("Auto Farm", 0.14, false, function(v) autoFarm = v end)
    makeToggle("Auto Quest", 0.25, false, function(v) autoQuest = v end)
    makeToggle("Auto Stats", 0.36, false, function(v) autoStats = v end)

    local teleNPCBtn = Instance.new("TextButton")
    teleNPCBtn.Parent = Main
    teleNPCBtn.Position = UDim2.new(0.1, 0, 0.47, 0)
    teleNPCBtn.Size = UDim2.new(0.8, 0, 0, 42)
    teleNPCBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
    teleNPCBtn.Text = "🗺️ Teleport to Quest NPC"
    teleNPCBtn.TextColor3 = Color3.fromRGB(255,255,255)
    teleNPCBtn.Font = Enum.Font.GothamSemibold
    teleNPCBtn.TextSize = 15
    teleNPCBtn.ZIndex = 3
    teleNPCBtn.AutoButtonColor = false
    Instance.new("UICorner", teleNPCBtn).CornerRadius = UDim.new(0, 8)
    teleNPCBtn.MouseButton1Click:Connect(teleportToQuestNPC)
    teleNPCBtn.MouseEnter:Connect(function() teleNPCBtn.BackgroundColor3 = Color3.fromRGB(110, 160, 110) end)
    teleNPCBtn.MouseLeave:Connect(function() teleNPCBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 80) end)

    local teleBossBtn = Instance.new("TextButton")
    teleBossBtn.Parent = Main
    teleBossBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
    teleBossBtn.Size = UDim2.new(0.8, 0, 0, 42)
    teleBossBtn.BackgroundColor3 = Color3.fromRGB(70,70,150)
    teleBossBtn.Text = "⚡ Teleport to Boss"
    teleBossBtn.TextColor3 = Color3.fromRGB(255,255,255)
    teleBossBtn.Font = Enum.Font.GothamSemibold
    teleBossBtn.TextSize = 16
    teleBossBtn.ZIndex = 3
    teleBossBtn.AutoButtonColor = false
    Instance.new("UICorner", teleBossBtn).CornerRadius = UDim.new(0, 8)
    teleBossBtn.MouseButton1Click:Connect(function()
        local boss = nil
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("boss") and v:FindFirstChild("HumanoidRootPart") then
                boss = v
                break
            end
        end
        if boss and LocalPlayer.Character then
            LocalPlayer.Character:MoveTo(boss.HumanoidRootPart.Position)
        end
    end)
    teleBossBtn.MouseEnter:Connect(function() teleBossBtn.BackgroundColor3 = Color3.fromRGB(100,100,200) end)
    teleBossBtn.MouseLeave:Connect(function() teleBossBtn.BackgroundColor3 = Color3.fromRGB(70,70,150) end)

    makeToggle("Player ESP", 0.74, false, function(v) espEnabled = v end)

    local islandLabel = Instance.new("TextLabel")
    islandLabel.Name = "IslandLabel"
    islandLabel.Parent = Main
    islandLabel.Position = UDim2.new(0.1, 0, 0.86, 0)
    islandLabel.Size = UDim2.new(0.8, 0, 0, 25)
    islandLabel.BackgroundTransparency = 1
    islandLabel.Font = Enum.Font.Gotham
    islandLabel.Text = "Đảo: Đang xác định..."
    islandLabel.TextColor3 = Color3.fromRGB(200,200,200)
    islandLabel.TextSize = 14
    islandLabel.ZIndex = 3

    spawn(function()
        while wait(2) do
            local island = getCurrentIsland()
            if island then
                islandLabel.Text = "Đảo: " .. island.Name
            else
                islandLabel.Text = "Đảo: Không xác định"
            end
        end
    end)

    local ver = Instance.new("TextLabel")
    ver.Parent = Main
    ver.Position = UDim2.new(0,0,0.93,0)
    ver.Size = UDim2.new(1,0,0,25)
    ver.BackgroundTransparency = 1
    ver.Font = Enum.Font.Gotham
    ver.Text = "v4.1 · Real Islands"
    ver.TextColor3 = Color3.fromRGB(180,180,180)
    ver.TextSize = 12
    ver.ZIndex = 3
end

createGUI()
print("[Kaitun] GUI loaded. Remote: Attack="..tostring(attackRemote~=nil).." QuestStart="..tostring(startQuestRemote~=nil).." QuestComplete="..tostring(completeQuestRemote~=nil).." AddStats="..tostring(addStatsRemote~=nil))

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
