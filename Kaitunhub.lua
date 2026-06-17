--[[
    Hậu Hub - Anime Warriors 3 (No Conflict Stop Button)
    Phiên bản: 6.7
    Tác giả: Hậu
    - Tự động chạy tất cả khi load script.
    - Lọc quái: bỏ qua NPC "quest"/"giver", các NPC khác vẫn đánh.
    - Teleport an toàn: CFrame, nếu lỗi thì siêu tốc di chuyển.
    - Nút STOP nhỏ, không xung đột, có thể kéo thả.
    - Đảo: Planet Nemak, Future City, Sand Village, Sky Island, Rain Village, Soul District.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FARM_RANGE = 300

-- ================== HỆ THỐNG ĐẢO (CẦN TỌA ĐỘ THỰC TẾ) ==================
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

-- Lấy đảo hiện tại
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

-- Tìm NPC quest
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

-- Trang bị vũ khí tốt nhất
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

-- Tìm mục tiêu farm (chỉ bỏ qua NPC quest/giver)
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

    for _, t in ipairs(targets) do
        if t.dist <= FARM_RANGE then return t.obj end
    end
    return targets[1].obj
end

-- Teleport an toàn
local function safeTeleport(targetPos)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = getHRP(char)
    if not hrp then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health == 0 then return false end

    local distance = (hrp.Position - targetPos).Magnitude
    if distance < 1 then return true end

    local success, err = pcall(function()
        hrp.CFrame = CFrame.new(targetPos)
    end)
    if success then return true end

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

-- Tìm Remote
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

-- Auto Farm
local function doAutoFarm()
    if not autoFarm then return end
    equipBestWeapon()
    local target = findBestTarget()
    if target then
        local targetPos = target.HumanoidRootPart.Position
        safeTeleport(targetPos + Vector3.new(0, 0, 3))
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

-- ESP
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

-- ================== NÚT STOP AN TOÀN (KHÔNG XUNG ĐỘT) ==================
local function createStopButton()
    -- Đặt tên độc nhất, tránh trùng với GUI khác
    local guiName = "HauHub_StopBtn"
    local existing = game.CoreGui:FindFirstChild(guiName)
    if existing then
        -- Nếu đã có GUI cũ, xóa đi để tạo mới (tránh lỗi khi chạy lại script)
        existing:Destroy()
    end

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

-- Khởi tạo nút
createStopButton()
print("[Hậu Hub] Đã sẵn sàng farm! Nút STOP ở góc phải, không xung đột.")

-- Vòng lặp chính
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
