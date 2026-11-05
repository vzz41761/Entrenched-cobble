-- cobble hills UI (ENTRENCHED EDITION)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Config = getgenv().CobbleConfig

local Theme = {
    bg = Color3.fromRGB(15, 16, 20), sidebar = Color3.fromRGB(20, 21, 27),
    surface = Color3.fromRGB(30, 32, 40), text = Color3.fromRGB(220, 222, 230),
    muted = Color3.fromRGB(120, 126, 142), accent = Color3.fromRGB(90, 140, 255),
    off = Color3.fromRGB(45, 48, 56)
}

local function Tween(inst, props, time)
    TweenService:Create(inst, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad), props):Play()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "cobble_entrenched"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = pcall(function() return gethui and gethui() end) and gethui() or game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(480, 400)
Main.Position = UDim2.new(0.5, -240, 0.5, -200)
Main.BackgroundColor3 = Theme.bg
Main.BorderSizePixel = 0
Main.Parent = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Theme.sidebar
Sidebar.Parent = Main
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "COBBLE.CC"
Title.TextColor3 = Theme.accent
Title.TextSize = 16
Title.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -20, 1, -60)
TabContainer.Position = UDim2.new(0, 10, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
Instance.new("UIListLayout", TabContainer).Padding = UDim.new(0, 5)

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -150, 1, -20)
ContentContainer.Position = UDim2.new(0, 140, 0, 10)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, 0)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Theme.accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = ContentContainer
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 8)

local function MakeTab(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Theme.bg
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text
    btn.TextColor3 = Theme.muted
    btn.TextSize = 13
    btn.Parent = TabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

local function MakeToggle(text, get, set)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = Scroll
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    local track = Instance.new("Frame")
    track.AnchorPoint = Vector2.new(1, 0.5)
    track.Position = UDim2.new(1, 0, 0.5, 0)
    track.Size = UDim2.fromOffset(36, 18)
    track.BackgroundColor3 = Theme.off
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(14, 14)
    dot.Position = UDim2.fromOffset(2, 2)
    dot.BackgroundColor3 = Theme.muted
    dot.Parent = track
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromScale(1, 1)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    local function refresh()
        if get() then
            Tween(track, {BackgroundColor3 = Theme.accent})
            Tween(dot, {Position = UDim2.fromOffset(20, 2), BackgroundColor3 = Color3.new(1,1,1)})
        else
            Tween(track, {BackgroundColor3 = Theme.off})
            Tween(dot, {Position = UDim2.fromOffset(2, 2), BackgroundColor3 = Theme.muted})
        end
    end
    btn.MouseButton1Click:Connect(function() set(not get()); refresh() end)
    refresh()
end

local function MakeButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 13
    btn.Text = text
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.MouseButton1Click:Connect(callback)
end

local function MakeSlider(text, min, max, get, set)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 45)
    holder.BackgroundTransparency = 1
    holder.Parent = Scroll
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 0, 15)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Theme.text
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = holder

    local valText = Instance.new("TextLabel")
    valText.Size = UDim2.new(50, 0, 0, 15)
    valText.Position = UDim2.new(1, -50, 0, 0)
    valText.BackgroundTransparency = 1
    valText.Font = Enum.Font.Gotham
    valText.TextColor3 = Theme.muted
    valText.TextSize = 12
    valText.TextXAlignment = Enum.TextXAlignment.Right
    valText.Parent = holder

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 25)
    track.BackgroundColor3 = Theme.off
    track.Parent = holder
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Theme.accent
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local function refresh()
        local v = get()
        local a = math.clamp((v - min) / (max - min), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        valText.Text = tostring(v)
    end

    local dragging = false
    local function setFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        set(math.floor(min + (max - min) * a))
        refresh()
    end

    track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; setFromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then setFromX(i.Position.X) end end)
    refresh()
end

local Tabs = { Visuals = MakeTab("Visuals"), Combat = MakeTab("Combat"), Utils = MakeTab("Utils") }

local function LoadTab(tabName)
    for _, v in ipairs(Scroll:GetChildren()) do if v:IsA("Frame") or v:IsA("TextButton") then v:Destroy() end end
    for name, btn in pairs(Tabs) do btn.TextColor3 = (name == tabName) and Theme.accent or Theme.muted end

    if tabName == "Visuals" then
        MakeToggle("ESP Enabled", function() return Config.ESP.Enabled end, function(v) Config.ESP.Enabled = v end)
        MakeToggle("Box", function() return Config.ESP.Box end, function(v) Config.ESP.Box = v end)
        MakeToggle("Name", function() return Config.ESP.Name end, function(v) Config.ESP.Name = v end)
        MakeToggle("Distance", function() return Config.ESP.Dist end, function(v) Config.ESP.Dist = v end)
        MakeToggle("Health Bar", function() return Config.ESP.Health end, function(v) Config.ESP.Health = v end)
        MakeToggle("Team Check", function() return Config.ESP.TeamCheck end, function(v) Config.ESP.TeamCheck = v end)
    elseif tabName == "Combat" then
        MakeToggle("Aimbot Enabled", function() return Config.Aimbot.Enabled end, function(v) Config.Aimbot.Enabled = v end)
        MakeToggle("Hold Mode (RMB)", function() return Config.Aimbot.HoldMode end, function(v) Config.Aimbot.HoldMode = v end)
        MakeToggle("Wall Check", function() return Config.Aimbot.WallCheck end, function(v) Config.Aimbot.WallCheck = v end)
        
        local tBtn = Instance.new("TextButton")
        tBtn.Size = UDim2.new(1, 0, 0, 35)
        tBtn.BackgroundColor3 = Theme.surface
        tBtn.Text = "Target: " .. Config.Aimbot.TargetPart
        tBtn.TextColor3 = Theme.text
        tBtn.Font = Enum.Font.Gotham
        tBtn.Parent = Scroll
        Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
        tBtn.MouseButton1Click:Connect(function()
            Config.Aimbot.TargetPart = (Config.Aimbot.TargetPart == "Head") and "HumanoidRootPart" or "Head"
            tBtn.Text = "Target: " .. Config.Aimbot.TargetPart
        end)

        MakeSlider("FOV", 20, 300, function() return Config.Aimbot.FOV end, function(v) Config.Aimbot.FOV = v end)
        MakeSlider("Smoothness", 0.05, 1, function() return Config.Aimbot.Smoothness end, function(v) Config.Aimbot.Smoothness = v end)
    elseif tabName == "Utils" then
        MakeToggle("Fullbright", function() return Config.Util.Fullbright end, function(v) Config.Util.Fullbright = v end)
        MakeSlider("Hitbox Expand (Studs)", 0, 5, function() return Config.Aimbot.HitboxExpand end, function(v) Config.Aimbot.HitboxExpand = v end)
        
        MakeButton("UNLOAD SCRIPT", Color3.fromRGB(255, 80, 80), function()
            if getgenv().Cobble_Unload then getgenv().Cobble_Unload() end
            Gui:Destroy()
        end)
    end
end

Tabs.Visuals.MouseButton1Click:Connect(function() LoadTab("Visuals") end)
Tabs.Combat.MouseButton1Click:Connect(function() LoadTab("Combat") end)
Tabs.Utils.MouseButton1Click:Connect(function() LoadTab("Utils") end)
LoadTab("Visuals")

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then Gui.Enabled = not Gui.Enabled end
end)
