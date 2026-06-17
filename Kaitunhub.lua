--[[
    Kaitun Hub - Anime Warriors 3 Script (UI Anime Theme)
    Giao diện: Nền anime, nút toggle hiện đại.
    Chức năng: Auto Farm, Auto Quest, Auto Stats, Teleport Boss, ESP.
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Cấu hình
local ANIME_BG_IMAGE = "rbxassetid://7483861177" -- ID ảnh nền anime (có thể thay đổi)

-- Trạng thái bật/tắt
local autoFarmEnabled = false
local autoQuestEnabled = false
local autoStatsEnabled = false
local espEnabled = false

-- Tạo giao diện chính
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaitunHub"
    ScreenGui.Parent = game.CoreGui
    ScreenGui.ResetOnSpawn = false

    -- Khung chính
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MainFrame.BackgroundTransparency = 0.1
    MainFrame.Position = UDim2.new(0.1, 0, 0.15, 0)
    MainFrame.Size = UDim2.new(0, 280, 0, 420)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.ClipsDescendants = true -- Ảnh nền không tràn ra ngoài

    -- Bo góc cho frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = MainFrame

    -- Ảnh nền anime
    local AnimeBG = Instance.new("ImageLabel")
    AnimeBG.Name = "AnimeBG"
    AnimeBG.Parent = MainFrame
    AnimeBG.BackgroundTransparency = 1
    AnimeBG.Size = UDim2.new(1, 0, 1, 0)
    AnimeBG.Position = UDim2.new(0, 0, 0, 0)
    AnimeBG.Image = ANIME_BG_IMAGE
    AnimeBG.ScaleType = Enum.ScaleType.Crop
    AnimeBG.ZIndex = 1

    -- Lớp phủ mờ để chữ dễ đọc
    local Overlay = Instance.new("Frame")
    Overlay.Name = "Overlay"
    Overlay.Parent = MainFrame
    Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Overlay.BackgroundTransparency = 0.5
    Overlay.Size = UDim2.new(1, 0, 1, 0)
    Overlay.ZIndex = 2

    -- Tiêu đề
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

    -- Hàm tạo nút toggle đẹp
    local function CreateToggleButton(name, posY, defaultState, callback)
        local Button = Instance.new("TextButton")
        Button.Name = name
        Button.Parent = MainFrame
        Button.BackgroundColor3 = defaultState and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
        Button.Position = UDim2.new(0.1, 0, posY, 0)
        Button.Size = UDim2.new(0.8, 0, 0, 42)
        Button.Font = Enum.Font.GothamSemibold
        Button.Text = name .. ": " .. (defaultState and "ON" or "OFF")
        Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        Button.TextSize = 16
        Button.ZIndex = 3
        Button.AutoButtonColor = false

        local UICornerBtn = Instance.new("UICorner")
        UICornerBtn.CornerRadius = UDim.new(0, 10)
        UICornerBtn.Parent = Button

        -- Hiệu ứng di chuột
        Button.MouseEnter:Connect(function()
            Button.BackgroundColor3 = defaultState and Color3.fromRGB(46, 160, 46) or Color3.fromRGB(200, 50, 50)
        end)
        Button.MouseLeave:Connect(function()
            Button.BackgroundColor3 = defaultState and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
        end)

        Button.MouseButton1Click:Connect(function()
            local newState = not defaultState
            defaultState = newState
            Button.Text = name .. ": " .. (newState and "ON" or "OFF")
            Button.BackgroundColor3 = newState and Color3.fromRGB(34, 139, 34) or Color3.fromRGB(178, 34, 34)
            callback(newState)
        end)

        return Button
    end

    -- Tạo các nút toggle
    CreateToggleButton("Auto Farm", 0.18, autoFarmEnabled, function(state)
        autoFarmEnabled = state
    end)

    CreateToggleButton("Auto Quest", 0.32, autoQuestEnabled, function(state)
        autoQuestEnabled = state
    end)

    CreateToggleButton("Auto Stats", 0.46, autoStatsEnabled, function(state)
        autoStatsEnabled = state
    end)

    -- Nút Teleport đặc biệt
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

    TeleportBtn.MouseEnter:Connect(function()
        TeleportBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    end)
    TeleportBtn.MouseLeave:Connect(function()
        TeleportBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 150)
    end)
    TeleportBtn.MouseButton1Click:Connect(function()
        -- Tìm boss và dịch chuyển
        local boss = Workspace:FindFirstChild("Boss", true)
        if boss and boss:IsA("Model") and boss:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character:MoveTo(boss.HumanoidRootPart.Position)
        end
    end)

    -- Nút Player ESP
    CreateToggleButton("Player ESP", 0.74, espEnabled, function(state)
        espEnabled = state
        if not state then
            -- Xóa ESP khi tắt
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    local hl = plr.Character:FindFirstChild("ESP_Highlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end)

    -- Nhãn phiên bản
    local Version = Instance.new("TextLabel")
    Version.Name = "Version"
    Version.Parent = MainFrame
    Version.BackgroundTransparency = 1
    Version.Position = UDim2.new(0, 0, 0.9, 0)
    Version.Size = UDim2.new(1, 0, 0, 30)
    Version.Font = Enum.Font.Gotham
    Version.Text = "v1.0 · by Kaitun"
    Version.TextColor3 = Color3.fromRGB(180, 180, 180)
    Version.TextSize = 12
    Version.ZIndex = 3

    return ScreenGui
end

-- Khởi tạo GUI
local gui = CreateGUI()

-- Vòng lặp chức năng chính
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- Auto Farm
    if autoFarmEnabled then
        local nearestMob = nil
        local minDist = math.huge
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") and obj ~= char then
                local hum = obj:FindFirstChild("Humanoid")
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
            char:MoveTo(nearestMob.HumanoidRootPart.Position)
            -- Kích hoạt vũ khí nếu có
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Activate") then
                tool:Activate()
            end
        end
    end

    -- Auto Quest (placeholder – cần custom theo game)
    if autoQuestEnabled then
        -- Ở đây có thể thêm logic nhận/nộp quest thông qua RemoteEvent
        -- Hiện tại để trống
    end

    -- Auto Stats (placeholder)
    if autoStatsEnabled then
        -- Logic tăng chỉ số, ví dụ: game:GetService("ReplicatedStorage"):FindFirstChild("AddStats"):FireServer("Strength")
    end

    -- Player ESP
    if espEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local existing = player.Character:FindFirstChild("ESP_Highlight")
                if not existing then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "ESP_Highlight"
                    highlight.Parent = player.Character
                    highlight.FillTransparency = 0.4
                    highlight.OutlineColor = Color3.fromRGB(255, 80, 80)
                    highlight.OutlineTransparency = 0.3
                end
            end
        end
    end
end)

print("[Kaitun Hub] Giao diện Anime đã sẵn sàng!")
