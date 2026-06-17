--[[
    Kaitun Hub - Anime Warriors 3 (Fixed & Enhanced)
    Phiên bản: 3.0
    Tác giả: Kaituncuahau
    Tự động dò RemoteEvent, fix lỗi không hoạt động.
--]]

-- Dịch vụ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Ảnh nền anime (có thể thay ID)
local ANIME_BG_IMAGE = "rbxassetid://7483861177"

-- Trạng thái
local autoFarm = false
local autoQuest = false
local autoStats = false
local espEnabled = false

-- Tự động dò RemoteEvent theo tên gần đúng
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

-- Tìm NPC quest
local function findQuestNPC()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            local name = v.Name:lower()
            if name:find("quest") or name:find("npc") or name:find("giver") then
                return v
            end
        end
    end
    -- Fallback: tìm bất kỳ NPC nào đứng yên
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") and not Players:GetPlayerFromCharacter(v) then
            return v
        end
    end
    return nil
end

-- Tìm Boss
local function findBoss()
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name:lower():find("boss") and v:FindFirstChild("HumanoidRootPart") then
            return v
        end
    end
    return nil
end

-- Tìm quái gần nhất (không phải người chơi, có Humanoid, có HumanoidRootPart)
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

-- Auto Farm
local function doAutoFarm()
    if not autoFarm then return end
    local mob = getNearestMob()
    if mob then
        LocalPlayer.Character:MoveTo(mob.HumanoidRootPart.Position)
        -- Dùng tool
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool and tool:FindFirstChild("Activate") then
            tool:Activate()
        end
        -- Gửi remote tấn công nếu có
        if attackRemote then
            pcall(function() attackRemote:FireServer(mob) end)
        end
    end
end

-- Auto Quest
local lastQuestTime = 0
local function doAutoQuest()
    if not autoQuest then return end
    if tick() - lastQuestTime < 10 then return end -- Mỗi 10s làm 1 lần
    lastQuestTime = tick()

    local npc = findQuestNPC()
    if not npc then return end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
    if not npcRoot then return end

    LocalPlayer.Character:MoveTo(npcRoot.Position)
    wait(1) -- Đợi đến nơi
    if startQuestRemote then
        pcall(function() startQuestRemote:FireServer() end)
        print("[Kaitun] Đã gửi yêu cầu nhận quest")
    end
    wait(3) -- Giả lập thời gian làm quest
    if completeQuestRemote then
        pcall(function() completeQuestRemote:FireServer() end)
        print("[Kaitun] Đã gửi yêu cầu nộp quest")
    end
end

-- Auto Stats
local function doAutoStats()
    if not autoStats then return end
    if not addStatsRemote then return end
    -- Gửi tăng từng chỉ số ưu tiên
    local stats = {"Strength", "Defense", "Speed", "Chakra", "Sword", "Health"}
    for _, stat in ipairs(stats) do
        pcall(function() addStatsRemote:FireServer(stat) end)
        wait(0.1)
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

-- Teleport Boss
local function teleportToBoss()
    local boss = findBoss()
    if boss and LocalPlayer.Character then
        LocalPlayer.Character:MoveTo(boss.HumanoidRootPart.Position)
    end
end

-- ====== GIAO DIỆN ======
local function createGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaitunHub"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = ScreenGui
    Main.Size = UDim2.new(0, 300, 0, 430)
    Main.Position = UDim2.new(0.05, 0, 0.1, 0)
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    Main.BackgroundTransparency = 0.1
    Main.Active = true
    Main.Draggable = true
    Main.ClipsDescendants = true
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    -- BG anime
    local img = Instance.new("ImageLabel")
    img.Parent = Main
    img.Size = UDim2.new(1, 0, 1, 0)
    img.Image = ANIME_BG_IMAGE
    img.ScaleType = Enum.ScaleType.Crop
    img.BackgroundTransparency = 1
    img.ZIndex = 1

    -- Overlay
    local ov = Instance.new("Frame")
    ov.Parent = Main
    ov.Size = UDim2.new(1, 0, 1, 0)
    ov.BackgroundColor3 = Color3.fromRGB(0,0,0)
    ov.BackgroundTransparency = 0.5
    ov.ZIndex = 2

    -- Title
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

    makeToggle("Auto Farm", 0.18, false, function(v) autoFarm = v end)
    makeToggle("Auto Quest", 0.32, false, function(v) autoQuest = v end)
    makeToggle("Auto Stats", 0.46, false, function(v) autoStats = v end)

    -- Teleport
    local teleBtn = Instance.new("TextButton")
    teleBtn.Parent = Main
    teleBtn.Position = UDim2.new(0.1,0,0.6,0)
    teleBtn.Size = UDim2.new(0.8,0,0,40)
    teleBtn.BackgroundColor3 = Color3.fromRGB(70,70,150)
    teleBtn.Text = "⚡ Teleport to Boss"
    teleBtn.TextColor3 = Color3.fromRGB(255,255,255)
    teleBtn.Font = Enum.Font.GothamSemibold
    teleBtn.TextSize = 16
    teleBtn.ZIndex = 3
    teleBtn.AutoButtonColor = false
    Instance.new("UICorner", teleBtn).CornerRadius = UDim.new(0, 8)
    teleBtn.MouseButton1Click:Connect(teleportToBoss)
    teleBtn.MouseEnter:Connect(function() teleBtn.BackgroundColor3 = Color3.fromRGB(100,100,200) end)
    teleBtn.MouseLeave:Connect(function() teleBtn.BackgroundColor3 = Color3.fromRGB(70,70,150) end)

    makeToggle("Player ESP", 0.74, false, function(v) espEnabled = v end)

    local ver = Instance.new("TextLabel")
    ver.Parent = Main
    ver.Position = UDim2.new(0,0,0.92,0)
    ver.Size = UDim2.new(1,0,0,25)
    ver.BackgroundTransparency = 1
    ver.Font = Enum.Font.Gotham
    ver.Text = "v3.0 · fixed by Kaitun"
    ver.TextColor3 = Color3.fromRGB(180,180,180)
    ver.TextSize = 12
    ver.ZIndex = 3
end

-- Khởi tạo
createGUI()
print("[Kaitun] GUI loaded. Remote tìm thấy: Attack="..tostring(attackRemote~=nil).." QuestStart="..tostring(startQuestRemote~=nil).." QuestComplete="..tostring(completeQuestRemote~=nil).." AddStats="..tostring(addStatsRemote~=nil))

-- Vòng lặp chính
RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        doAutoFarm()
        updateESP()
    end
end)

-- Timer riêng cho quest và stats (không spam)
spawn(function()
    while wait(10) do
        if autoQuest then doAutoQuest() end
    end
end)

spawn(function()
    while wait(5) do
        if autoStats then doAutoStats() end
    end
end)
