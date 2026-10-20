-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- สถานะการทำงานของฟีเจอร์ต่างๆ
local Config = {
    AutoPower = false,
    AutoAttack = false,
    AutoCollect = false,
    WalkSpeed = 16,
    JumpPower = 50,
    -- ตั้งค่าชื่อ Remote และ Folder ตามโครงสร้างแมพ (สามารถเปลี่ยนได้หลังจากกดปุ่ม Scan)
    PowerRemoteName = "GainPower", 
    AttackRemoteName = "DamageObject",
    DropFolderName = "Drops"
}

-- ==========================================
-- 1. สร้างระบบ UI (ScreenGui)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SuperpowerDestructionUI"
ScreenGui.ResetOnSpawn = false
-- ป้องกัน Error กรณีรันในสภาพแวดล้อมที่ต่างกัน
local success, parentTarget = pcall(function() return game:GetService("CoreGui") end)
ScreenGui.Parent = (success and parentTarget) or LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 360)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- แถบหัวข้อด้านบน (ใช้ลากหน้าต่าง)
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "+1 Superpower Destruction Tool"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

-- ระบบลากหน้าต่าง (Draggable UI)
local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TopBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- พื้นที่วางปุ่ม
local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, -20, 1, -50)
Container.Position = UDim2.new(0, 10, 0, 45)
Container.BackgroundTransparency = 1
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Container

-- ฟังก์ชันสร้างปุ่ม Toggle
local function CreateToggle(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    Button.Text = text .. " : OFF"
    Button.TextColor3 = Color3.fromRGB(200, 200, 200)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Button.Parent = Container

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    local state = false
    Button.MouseButton1Click:Connect(function()
        state = not state
        if state then
            Button.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
            Button.Text = text .. " : ON"
            Button.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Button.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
            Button.Text = text .. " : OFF"
            Button.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        callback(state)
    end)
end

-- ฟังก์ชันสร้างปุ่มกดครั้งเดียว (Action Button)
local function CreateButton(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
    Button.Text = text
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.GothamSemibold
    Button.TextSize = 13
    Button.Parent = Container

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button

    Button.MouseButton1Click:Connect(callback)
end

-- ==========================================
-- 2. ระบบการทำงานหลัก (Core Logic)
-- ==========================================

-- ปุ่มที่ 1: สแกนหา RemoteEvents ในเกม (กดแล้วเปิด F9 ดูชื่อได้เลย)
CreateButton("🔍 Scan Game Remotes & Folders (F9)", function()
    print("=== [SCANNING REPLICATED STORAGE REMOTES] ===")
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print(string.format("[%s] Path: %s", v.ClassName, v:GetFullName()))
        end
    end
    print("=== [SCANNING WORKSPACE FOLDERS] ===")
    for _, v in ipairs(Workspace:GetChildren()) do
        if v:IsA("Folder") or v:IsA("Model") then
            print(string.format("[%s] Name: %s (Children: %d)", v.ClassName, v.Name, #v:GetChildren()))
        end
    end
end)

-- ปุ่มที่ 2: Auto Power / Auto Train
CreateToggle("⚡ Auto Gain Power", function(state)
    Config.AutoPower = state
    task.spawn(function()
        while Config.AutoPower do
            -- ค้นหา Remote ตามชื่อ หรือเรียกใช้ Tool ที่ถืออยู่
            local remote = ReplicatedStorage:FindFirstChild(Config.PowerRemoteName, true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer()
            else
                -- กรณีแมพใช้การคลิกด้วย Tool ในมือเพื่อเพิ่มพลัง
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then
                        tool:Activate()
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end)

-- ปุ่มที่ 3: Auto Destruction (ทำลายสิ่งของ/โจมตีอัตโนมัติ)
CreateToggle("💥 Auto Destruction / Attack", function(state)
    Config.AutoAttack = state
    task.spawn(function()
        while Config.AutoAttack do
            local remote = ReplicatedStorage:FindFirstChild(Config.AttackRemoteName, true)
            if remote and remote:IsA("RemoteEvent") then
                remote:FireServer()
            end
            task.wait(0.15)
        end
    end)
end)

-- ปุ่มที่ 4: Auto Collect Drops / Orbs
CreateToggle("🧲 Auto Collect Drops / Orbs", function(state)
    Config.AutoCollect = state
    task.spawn(function()
        while Config.AutoCollect do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local dropFolder = Workspace:FindFirstChild(Config.DropFolderName, true)

            if hrp and dropFolder then
                for _, item in ipairs(dropFolder:GetChildren()) do
                    if not Config.AutoCollect then break end
                    local targetPart = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if targetPart then
                        -- ดึงไอเทมมาชนตัวละครเพื่อเก็บอัตโนมัติ
                        targetPart.CFrame = hrp.CFrame
                    end
                end
            end
            task.wait(0.2)
        end
    end)
end)

-- ปุ่มที่ 5: Speed & Jump Boost
CreateToggle("🏃 Speed & Jump Boost", function(state)
    Config.WalkSpeed = state and 80 or 16
    Config.JumpPower = state and 120 or 50
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = Config.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = Config.JumpPower
    end
end)

-- รักษาค่าความเร็วเวลาเดินแม้เกมพยายามรีเซ็ตค่า
RunService.Stepped:Connect(function()
    if Config.WalkSpeed > 16 then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= Config.WalkSpeed then
            hum.WalkSpeed = Config.WalkSpeed
        end
    end
end)
