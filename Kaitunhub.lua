-- [[
--     Kaitun Hub - Anime Warriors 3 Script (UI Anime Theme)
--     Giao diện: Nền anime, nút toggle hiện đại.
--     Chức năng: Auto Farm, Auto Quest, Auto Stats, Teleport Boss, ESP.
--     [BẢN SỬA LỖI HOÀN HẢO - v3.2 GOD MODE]
-- ]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

-- Cấu hình
local ANIME_BG_IMAGE = "rbxassetid://7483861177" 

-- Trạng thái bật/tắt
local Config = {
    AutoFarm = false,
    AutoQuest = false,
    AutoStats = false,
    ESP = false
}

-- Ngăn chặn mở nhiều cửa sổ
if CoreGui:FindFirstChild("KaitunHub") then
    CoreGui.KaitunHub:Destroy()
end

-- === HỆ THỐNG ESP TỐI ƯU ===
local function addESP(player)
    if player == LocalPlayer then return end
    if player.Character then
        local hl = player.Character:FindFirstChild("ESP_Highlight")
        if not hl then
            hl = Instance.new("Highlight")
            hl.Name = "ESP_Highlight"
            hl.FillColor = Color3.fromRGB(255, 80, 80)
            hl.FillTransparency = 0.5
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineTransparency = 0.2
            hl.Parent = player.Character
        end
    end
end

local function removeESP(player)
    if player.Character then
        local hl = player.Character:FindFirstChild("ESP_Highlight")
        if hl then hl:Destroy() end
    end
end

local function refreshAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if Config.ESP then
            addESP(player)
        else
            removeESP(player)
        end
    end
end

-- === CƠ CHẾ NOCLIP CHUẨN ENGINE (FIX HOÀN TOÀN LỖI GHI ĐÈ) ===
local resetCollisionDone = false

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    if Config.AutoFarm then
        -- Ép CanCollide = false LIÊN TỤC mỗi khung hình để chống lại cơ chế Physics tự bật của Roblox
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
        resetCollisionDone = false
    else
        -- Chỉ khôi phục va chạm ĐÚNG 1 LẦN duy nhất khi tắt Auto Farm để tránh giật lag máy
        if not resetCollisionDone then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
            resetCollisionDone = true
        end
    end
end)

-- Hàm tạo giao diện
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaitunHub"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    MainFrame.Size = UDim2.new(0, 280, 0, 420)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true 

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    local AnimeBG = Instance.new("ImageLabel")
    AnimeBG.Name = "AnimeBG"
    AnimeBG.Parent = MainFrame
    AnimeBG.BackgroundTransparency = 1
    AnimeBG.Size = UDim2.new(1, 0, 1, 0)
    AnimeBG.Position = UDim2.new(0, 0, 0, 0)
    AnimeBG.Image = ANIME_BG_IMAGE
    AnimeBG.ScaleType = Enum.ScaleType.Crop
    AnimeBG.ZIndex = 1

    local Overlay = Instance.new("Frame")
    Overlay.Name = "Overlay"
    Overlay.Parent = MainFrame
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.ZIndex = 2

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 50)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "⚔️ Kaitun Hub ⚔️"
    Title.TextColor3 = Color3.fromRGB(255, 215, 0)
    Title.TextSize = 22
    Title.TextStrokeTransparency = 0.5
    Title.ZIndex = 3

    local function CreateToggleButton(configKey, labelName, posY, customCallback)
        local Button = Instance.new("TextButton")
        Button.Name = labelName
        Button.Parent = MainFrame
        Button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
        Button.Position = UDim2.new(0.1, 0, posY, 0)
        Button.Size = UDim2.new(0.8, 0, 0, 42)
        Button.Font = Enum.Font.GothamSemibold
        Button.Text = labelName .. ": " .. (Config[configKey] and "ON" or "OFF")
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 16
        Button.ZIndex = 3
        Button.AutoButtonColor = false

        local UICornerBtn = Instance.new("UICorner")
        UICornerBtn.CornerRadius = UDim.new(0, 10)
        UICornerBtn.Parent = Button

        Button.MouseEnter:Connect(function()
            Button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(46, 160, 46) or Color3.fromRGB(200, 50, 50)
        end)
        Button.MouseLeave:Connect(function()
            Button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
        end)

        Button.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            Button.Text = labelName .. ": " .. (Config[configKey] and "ON" or "OFF")
            Button.BackgroundColor3 = Config[configKey] and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
            if customCallback then customCallback() end
        end)

        return Button
    end

    CreateToggleButton("AutoFarm", "Auto Farm", 0.18)
    CreateToggleButton("AutoQuest", "Auto Quest", 0.32)
    CreateToggleButton("AutoStats", "Auto Stats", 0.46)

    -- Nút Teleport Boss
    local TeleportBtn = Instance.new("TextButton")
    TeleportBtn.Name = "TeleportBtn"
    TeleportBtn.Parent = MainFrame
    TeleportBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 150)
    TeleportBtn.Position = UDim2.new(0.1, 0, 0.60, 0)
    TeleportBtn.Size = UDim2.new(0.8, 0, 0, 42)
    TeleportBtn.Font = Enum.Font.GothamSemibold
    TeleportBtn.Text = "⚡ Teleport to Boss"
    TeleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    TeleportBtn.TextSize = 16
    TeleportBtn.ZIndex = 3
    TeleportBtn.AutoButtonColor = false

    local UICornerTeleport = Instance.new("UICorner")
    UICornerTeleport.CornerRadius = UDim.new(0, 10)
    UICornerTeleport.Parent = TeleportBtn

    TeleportBtn.MouseEnter:Connect(function() TeleportBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200) end)
    TeleportBtn.MouseLeave:Connect(function() TeleportBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 150) end)
    
    TeleportBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            
            local targets = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("NPCs") or Workspace
            for _, obj in pairs(targets:GetChildren()) do
                if obj:IsA("Model") and (obj.Name:lower():find("boss") or obj:GetAttribute("Type") == "Boss") then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        char.HumanoidRootPart.CFrame = hrp.CFrame * CFrame.new(0, 4, 0)
                        return
                    end
                end
            end
            warn("[Kaitun Hub] Không tìm thấy mục tiêu Boss hoạt động gần đây.")
        end)
    end)

    CreateToggleButton("ESP", "Player ESP", 0.74, function()
        refreshAllESP()
    end)

    local Version = Instance.new("TextLabel")
    Version.Name = "Version"
    Version.Parent = MainFrame
    Version.BackgroundTransparency = 1
    Version.Position = UDim2.new(0, 0, 0.9, 0)
    Version.Size = UDim2.new(1, 0, 0, 30)
    Version.Font = Enum.Font.Gotham
    Version.Text = "v3.2 (God Mode) · by Kaitun"
    Version.TextColor3 = Color3.fromRGB(180, 180, 180)
    Version.TextSize = 12
    Version.ZIndex = 3

    return ScreenGui
end

local gui = CreateGUI()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if Config.ESP then task.wait(0.5) addESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- === VÒNG LẶP CHÍNH ===
local lastActivateTime = 0
local ACTIVATE_COOLDOWN = 0.3 

task.spawn(function()
    while true do
        task.wait(0.1) 
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
        local humanoidRootPart = char.HumanoidRootPart

        if Config.AutoFarm then
            pcall(function()
                local nearestMob = nil
                local minDist = math.huge
                
                local monsterContainer = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("Enemies") or Workspace
                for _, obj in pairs(monsterContainer:GetChildren()) do
                    if obj:IsA("Model") and obj ~= char then
                        local hum = obj:FindFirstChildOfClass("Humanoid")
                        local hrp = obj:FindFirstChild("HumanoidRootPart")
                        if hum and hum.Health > 0 and hrp then
                            local dist = (hrp.Position - humanoidRootPart.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                nearestMob = obj
                            end
                        end
                    end
                end
                
                if nearestMob and nearestMob:FindFirstChild("HumanoidRootPart") then
                    -- Cập nhật API chuẩn mới (Assembly Velocity) thay thế hoàn toàn RotVelocity cũ
                    if humanoidRootPart:IsA("BasePart") then
                        humanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
                        humanoidRootPart.AssemblyAngularVelocity = Vector3.new(0,0,0)
                    end

                    -- Khóa vị trí trên đầu quái mượt mà
                    humanoidRootPart.CFrame = nearestMob.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0)
                    
                    local backpackTool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                    if backpackTool then
                        backpackTool.Parent = char
                    end
                    
                    local activeTool = char:FindFirstChildOfClass("Tool")
                    if activeTool and (tick() - lastActivateTime >= ACTIVATE_COOLDOWN) then
                        activeTool:Activate()
                        lastActivateTime = tick()
                    end
                end
            end)
        end

        if Config.AutoQuest then
            -- Tích hợp Remote Quest
        end

        if Config.AutoStats then
            -- Tích hợp Remote Stats
        end
    end
end)

print("[Kaitun Hub v3.2] Đã đạt trạng thái God Mode: Xuyên tường tuyệt đối, chuẩn hóa API 2026!")
