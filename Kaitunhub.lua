--[[
    Hậu Hub - Anime Warriors 3 (Full Fix by Tâm Dev)
    Phiên bản: 6.8.1
    Tác giả: Hậu, Tâm Dev (sửa lỗi hoàn chỉnh)
    - Tự động chạy tất cả khi load script.
    - Teleport tức thời an toàn (CFrame + fallback siêu tốc).
    - Ưu tiên đánh quái máu thấp, bỏ qua NPC quest/giver.
    - Nút STOP nhỏ gọn, không xung đột.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FARM_RANGE = 250

-- ================== HỆ THỐNG ĐẢO (cần tọa độ thực) ==================
local ISLANDS = {
    {Name = "Planet Nemak",    Center = Vector3.new(0, 50, 0),    Radius = 300},
    {Name = "Future City",     Center = Vector3.new(500, 50, 500), Radius = 300},
    {Name = "Sand Village",    Center = Vector3.new(-500, 50, -500), Radius = 300},
    {Name = "Sky Island",      Center = Vector3.new(0, 500, 0),   Radius = 250},
    {Name = "Rain Village",    Center = Vector3.new(1000, 50, -1000), Radius = 300},
    {Name = "Soul District",   Center = Vector3.new(-1000, 50, 1000), Radius = 300},
}

local autoFarm = true
local autoQuest = true
local autoStats = true
local espEnabled = true

-- Hàm lấy HumanoidRootPart an toàn
local function getHRP(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Lấy đảo hiện tại dựa trên vị trí nhân vật
local function getCurrentIsland()
    local hrp = getHRP(LocalPlayer.Character)
    if not hrp then return nil end
    local pos = hrp.Position
    local closest = nil
    local minDist = math.huge
    for _, island in ipairs(ISLANDS) do
        local dist = (pos - island.Center).Magnitude
        if dist <= island.Radius and dist < minDist then
            minDist = dist
            closest = island
        end
    end
    return closest
end

-- Tìm NPC nhiệm vụ (quest NPC) trên đảo hiện tại
local function findNPCOnIsland(island)
    if not island then return nil end
    local npcs = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if not Players:GetPlayerFromCharacter(v) then
                local root = v:FindFirstChild("HumanoidRootPart") or v.Head
                if root and (root.Position - island.Center).Magnitude <= island.Radius then
                    table.insert(npcs, v)
                end
            end
        end
    end
    if #npcs == 0 then return nil end
    local playerPos = getHRP(LocalPlayer.Character).Position
    table.sort(npcs, function(a, b)
        local rootA = a:FindFirstChild("HumanoidRootPart") or a.Head
        local rootB = b:FindFirstChild("HumanoidRootPart") or b.Head
        return (rootA.Position - playerPos).Magnitude < (rootB.Position - playerPos).Magnitude
    end)
    return npcs[1]
end

-- Tự động trang bị vũ khí tốt nhất (dựa vào damage hoặc tên)
local function equipBestWeapon()
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer.Backpack
    local currentTool = char:FindFirstChildOfClass("Tool")
    local tools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
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

    local best = tools[1]
    if currentTool == best then return end
    if currentTool then currentTool.Parent = backpack end
    if best then best.Parent = char end
end

-- Tìm mục tiêu quái (ưu tiên máu thấp nhất, chỉ bỏ qua quest/giver NPC)
local function findBestTarget()
    local island = getCurrentIsland()
    if not island then return nil end
    local char = LocalPlayer.Character
    if not char then return nil end
    local root = getHRP(char)
    if not root then return nil end

    local targets = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= char
            and obj:FindFirstChild("Humanoid")
            and obj:FindFirstChild("HumanoidRootPart") then
            local hum = obj.Humanoid
            if hum.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                local name = obj.Name:lower()
                -- Chỉ bỏ qua NPC có "quest" hoặc "giver", vẫn đánh lính canh (npc thường)
                if not name:find("quest") and not name:find("giver") then
                    local objPos = obj.HumanoidRootPart.Position
                    if (objPos - island.Center).Magnitude <= island.Radius then
                        local dist = (objPos - root.Position).Magnitude
                        table.insert(targets, {obj = obj, hp = hum.Health, dist = dist})
                    end
                end
            end
        end
    end
    if #targets == 0 then return nil end

    table.sort(targets, function(a, b)
        if a.hp ~= b.hp then return a.hp < b.hp end
        return a.dist < b.dist
    end)

    -- Trả về mục tiêu gần nhất trong phạm vi farm, hoặc con máu thấp nhất toàn đảo
    for _, t in ipairs(targets) do
        if t.dist <= FARM_RANGE then return t.obj end
    end
    return targets[1].obj
end

-- Dịch chuyển an toàn: thử CFrame, nếu lỗi thì chạy siêu tốc đến
local function safeTeleport(targetPos)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = getHRP(char)
    if not hrp then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local distance = (hrp.Position - targetPos).Magnitude
    if distance < 1 then return true end  -- đã đến nơi

    -- Cách 1: Dịch chuyển bằng CFrame
    local success, err = pcall(function()
        hrp.CFrame = CFrame.new(targetPos)
    end)
    if success then return true end

    -- Cách 2: Tăng tốc chạy (fallback)
    local oldSpeed = humanoid.WalkSpeed
    humanoid.WalkSpeed = 300
    char:MoveTo(targetPos)

    task.spawn(function()
        while true do
            local currentHRP = getHRP(char)
            if not currentHRP then break end
            local human = char:FindFirstChildOfClass("Humanoid")
            if not human or human.Health <= 0 then break end
            if (currentHRP.Position - targetPos).Magnitude <= 5 then
                human.WalkSpeed = oldSpeed
                break
            end
            task.wait(0.1)
        end
    end)
    return true
end

-- Tìm RemoteEvent theo từ khóa
local function findRemote(keyword)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
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

-- Auto Farm chính
local function doAutoFarm()
    if not autoFarm then return end
    equipBestWeapon()
    local target = findBestTarget()
    if target then
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        if not targetRoot then return end
        local targetPos = targetRoot.Position
        safeTeleport(targetPos + Vector3.new(0, 0, 3))  -- đứng cách 3 stud
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Activate") then
            tool:Activate()
        end
        if attackRemote then
            pcall(function() attackRemote:FireServer(target) end)
        end
    else
        local island = getCurrentIsland()
        if island then
            safeTeleport(island.Center)
        end
    end
end

-- Auto Quest (nhận/nộp quest từ NPC trên đảo)
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
    safeTeleport(npcRoot.Position)
    task.wait(1.5)
    if startQuestRemote then pcall(function() startQuestRemote:FireServer() end) end
    task.wait(5)
    if completeQuestRemote then pcall(function() completeQuestRemote:FireServer() end) end
end

-- Auto Stats
local function doAutoStats()
    if not autoStats then return end
    if not addStatsRemote then return end
    local stats = {"Strength", "Defense", "Speed", "Chakra", "Sword", "Health"}
    for _, stat in ipairs(stats) do
        pcall(function() addStatsRemote:FireServer(stat) end)
        task.wait(0.15)
    end
end

-- ESP (hiển thị người chơi khác)
local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
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

-- Nút STOP nhỏ góc phải, không xung đột
local function createStopButton()
    local guiName = "HauHub_StopBtn"
    local existing = game.CoreGui:FindFirstChild(guiName)
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local btn = Instance.new("TextButton")
    btn.Name = "StopButton"
    btn.Parent = ScreenGui
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.Position = UDim2.new(0.92, -40, 0.02, 0) -- góc trên phải
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
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

-- Khởi động
createStopButton()
print("[Hậu Hub] Sẵn sàng - Tâm Dev fix hoàn chỉnh.")

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and getHRP(LocalPlayer.Character) then
        doAutoFarm()
        updateESP()
    end
end)

task.spawn(function()
    while task.wait(15) do
        if autoQuest then doAutoQuest() end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if autoStats then doAutoStats() end
    end
end)
