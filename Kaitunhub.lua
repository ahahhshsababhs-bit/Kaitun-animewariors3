local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager") -- Hỗ trợ Auto Click chuẩn hệ thống

local ANIME_BG_IMAGE = "rbxassetid://7483861177"

local Config = {
    AutoFarm = true,
    Distance = 2.5 -- Khoảng cách áp sát quái vật (Tính bằng Studs)
}

if CoreGui:FindFirstChild("AnimeWarriors3Hub") then
    CoreGui.AnimeWarriors3Hub:Destroy()
end

local noClipParts = {}
local hrp = nil

local function cacheCharacterParts(char)
    noClipParts = {}
    if not char then return end
    
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(noClipParts, part)
        end
    end
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(noClipParts, desc)
        end
    end)
end

if LocalPlayer.Character then
    cacheCharacterParts(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(cacheCharacterParts)

-- Vòng lặp Noclip & Triệt tiêu hoàn toàn lực đẩy từ quái vật/boss
RunService.Stepped:Connect(function()
    if Config.AutoFarm and hrp then
        for i = #noClipParts, 1, -1 do
            local part = noClipParts[i]
            if part and part.Parent then
                part.CanCollide = false
            else
                table.remove(noClipParts, i)
            end
        end
        if hrp:IsA("BasePart") then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end)

-- Tạo GUI điều khiển thu gọn
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AnimeWarriors3Hub"
    ScreenGui.Parent = CoreGui
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.Position = UDim2.new(0.4, 0, 0.4, 0)
    MainFrame.Size = UDim2.new(0, 180, 0, 100)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Parent = MainFrame
    Title.BackgroundTransparency = 1
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "AW3 - AUTO FARM"
    Title.TextColor3 = Color3.fromRGB(255, 85, 85)
    Title.TextSize = 14

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Parent = MainFrame
    ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
    ToggleButton.Position = UDim2.new(0.1, 0, 0.45, 0)
    ToggleButton.Size = UDim2.new(0.8, 0, 0, 35)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Text = "STATUS: ON"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 13

    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(0, 8)
    UICornerBtn.Parent = ToggleButton

    ToggleButton.MouseButton1Click:Connect(function()
        Config.AutoFarm = not Config.AutoFarm
        if Config.AutoFarm then
            ToggleButton.Text = "STATUS: ON"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
        else
            ToggleButton.Text = "STATUS: OFF"
            ToggleButton.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
            for _, part in ipairs(noClipParts) do
                if part and part.Parent then part.CanCollide = true end
            end
        end
    end)

    return ScreenGui
end

local gui = CreateGUI()

-- Hàm tìm kiếm quái vật thông minh thích ứng theo map/phụ bản của AW3
local function GetNearestMonster()
    local nearestMob = nil
    local minDist = math.huge
    
    -- Danh sách các thư mục chứa quái thường gặp trong game RPG/Dungeon
    local targets = {}
    local folders = {Workspace:FindFirstChild("Monsters"), Workspace:FindFirstChild("Enemies"), Workspace:FindFirstChild("Mobs"), Workspace}
    
    for _, folder in ipairs(folders) do
        if folder then
            for _, v in ipairs(folder:GetDescendants()) do
                if v:IsA("Model") and v:FindFirstChild("HumanoidRootPart") and v ~= LocalPlayer.Character then
                    local hum = v:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and not Players:GetPlayerFromCharacter(v) then
                        table.insert(targets, v)
                    end
                end
            end
        end
    end

    for _, mob in ipairs(targets) do
        if hrp and mob:FindFirstChild("HumanoidRootPart") then
            local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearestMob = mob
            end
        end
    end
    
    return nearestMob
end

-- Luồng Auto Click chuột trái tốc độ cao độc lập
task.spawn(function()
    while task.wait(0.05) do -- Tốc độ bấm chiêu/đánh thường siêu nhanh
        if Config.AutoFarm and Config.AutoFarm == true then
            local char = LocalPlayer.Character
            if char and char:FindFirstChildOfClass("Humanoid") and char.Humanoid.Health > 0 then
                -- Giả lập nhấn chuột trái lên màn hình để kích hoạt đòn đánh của nhân vật Anime
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end
        end
    end
end)

-- Luồng dịch chuyển (Teleport) áp sát mục tiêu
task.spawn(function()
    while task.wait() do
        if not Config.AutoFarm then continue end

        local char = LocalPlayer.Character
        if not char or not hrp then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local mob = GetNearestMonster()

        if mob and mob:FindFirstChild("HumanoidRootPart") then
            local targetHrp = mob.HumanoidRootPart
            
            -- Khóa vị trí ra phía sau hoặc trước mặt quái một khoảng cách nhỏ để combo không bị hụt
            hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, Config.Distance)
            
            -- Tự động lấy vũ khí cầm tay nếu có trong Túi đồ (Backpack)
            local currentTool = char:FindFirstChildOfClass("Tool")
            if not currentTool then
                local tool = LocalPlayer.Backpack:FindFirstChildOfClass("Tool")
                if tool then
                    tool.Parent = char
                end
            end
        end
    end
end)

print("Anime Warriors 3 Custom Farm Script Loaded.")
