-- cobble hills logic (ENTRENCHED MASTER EDITION)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local VirtualUser      = game:GetService("VirtualUser")
local VIM              = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ==========================================
-- CONFIGURAÇÕES (Namespace Protegido)
-- ==========================================
getgenv().Cobble = {
    Config = {
        ESP = { 
            Enabled = true, Box = true, Name = true, Dist = true, Health = true, Tracer = true, TeamCheck = true 
        },
        Aimbot = { 
            Enabled = true, Silent = true, HoldMode = true, Key = Enum.UserInputType.MouseButton2,
            FOV = 150, Smoothness = 0.3, TargetPart = "Head", WallCheck = true, Prediction = 0.165 
        },
        Triggerbot = { Enabled = false, Delay = 0.01, FOV = 10 },
        Hitbox = { Enabled = false, Size = 6, Transparency = 0.5 },
        Util = { Fullbright = false, NoSpread = true }
    },
    Cache = {},
    ESPObjects = {},
    Target = nil,
    Ballistic = { Speed = 1000, Gravity = Workspace.Gravity }
}

local Cobble = getgenv().Cobble
local Config = Cobble.Config

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(90, 140, 255)

-- ==========================================
-- CACHE DE JOGADORES (Background Thread)
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do
        local temp = {}
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    temp[plr.Character] = { Player = plr, Hum = hum, Root = hrp }
                end
            end
        end
        Cobble.Cache = temp
    end
end)

-- ==========================================
-- NO SPREAD & BALLISTIC UPDATE
-- ==========================================
task.spawn(function()
    while task.wait(1) do
        if not Config.Util.NoSpread then continue end
        local containers = {LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}
        
        for _, container in pairs(containers) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        local gunStates = tool:FindFirstChild("GunStates")
                        if gunStates then
                            pcall(function()
                                local states = require(gunStates)
                                states.Spread = 0
                                states.MinSpread = 0
                                states.MaxSpread = 0
                                states.SpreadIncrease = 0
                                if states.Velocity then Cobble.Ballistic.Speed = states.Velocity end
                                if states.Gravity then Cobble.Ballistic.Gravity = states.Gravity end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- HITBOX EXPANDER
-- ==========================================
task.spawn(function()
    while task.wait(0.1) do
        if not Config.Hitbox.Enabled then continue end
        for char, data in pairs(Cobble.Cache) do
            if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
            local targetSize = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size)
            for _, partName in ipairs({"HumanoidRootPart", "Head"}) do
                local part = char:FindFirstChild(partName)
                if part and part.Size ~= targetSize then
                    part.Size = targetSize
                    part.Transparency = Config.Hitbox.Transparency
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ==========================================
-- LÓGICA DE ALVO E BALÍSTICA
-- ==========================================
local function CalculateBallisticPosition(targetPart)
    if not Config.Aimbot.Prediction or Config.Aimbot.Prediction <= 0 then return targetPart.Position end
    local camPos = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local dist = (targetPos - camPos).Magnitude
    local timeToTarget = dist / Cobble.Ballistic.Speed
    
    local predictedPos = targetPos + (targetPart.AssemblyLinearVelocity * timeToTarget * Config.Aimbot.Prediction)
    predictedPos = predictedPos + Vector3.new(0, 0.5 * Cobble.Ballistic.Gravity * (timeToTarget ^ 2), 0)
    return predictedPos
end

local function GetClosestPlayer(fovOverride)
    local mouse, camPos = UserInputService:GetMouseLocation(), Camera.CFrame.Position
    local currentFov = fovOverride or Config.Aimbot.FOV
    local best, bestDist = nil, currentFov

    for char, data in pairs(Cobble.Cache) do
        if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or data.Root
        if part then
            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if d < bestDist then best, bestDist = part, d end
            end
        end
    end

    if best and Config.Aimbot.WallCheck then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        local result = Workspace:Raycast(camPos, best.Position - camPos, params)
        if result and result.Instance and not result.Instance:IsDescendantOf(best.Parent) then return nil end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    if Config.Aimbot.Enabled then Cobble.Target = GetClosestPlayer() else Cobble.Target = nil end
end)

-- ==========================================
-- ESP (Object Pooling - Zero Lag)
-- ==========================================
local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(Cobble.ESPObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end

    local activeChars = {}
    for char, data in pairs(Cobble.Cache) do
        if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
        activeChars[char] = true

        if not Cobble.ESPObjects[char] then
            Cobble.ESPObjects[char] = {
                box = Drawing.new("Square"), name = Drawing.new("Text"),
                dist = Drawing.new("Text"), healthBg = Drawing.new("Square"),
                healthFg = Drawing.new("Square"), tracer = Drawing.new("Line")
            }
            local o = Cobble.ESPObjects[char]
            o.box.Thickness = 1; o.box.Filled = false
            o.name.Size = 13; o.name.Center = true; o.name.Outline = true
            o.dist.Size = 12; o.dist.Center = true; o.dist.Outline = true
            o.healthBg.Filled = true; o.healthBg.Color = Color3.new(0,0,0)
            o.healthFg.Filled = true; o.tracer.Thickness = 1
        end

        local obj = Cobble.ESPObjects[char]
        local head = char:FindFirstChild("Head") or data.Root
        local top3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bot3 = Camera:WorldToViewportPoint(data.Root.Position - Vector3.new(0, 2.5, 0))

        if top3.Z > 0 and bot3.Z > 0 then
            local topV, botV = Vector2.new(top3.X, top3.Y), Vector2.new(bot3.X, bot3.Y)
            local h, w = botV.Y - topV.Y, (botV.Y - topV.Y) * 0.55
            local bx = topV.X - w * 0.5

            obj.box.Visible = Config.ESP.Box; obj.box.Color = Color3.fromRGB(255, 50, 50)
            obj.box.Position = Vector2.new(bx, topV.Y); obj.box.Size = Vector2.new(w, h)

            local hp = math.clamp(data.Hum.Health / data.Hum.MaxHealth, 0, 1)
            obj.healthBg.Visible = Config.ESP.Health; obj.healthBg.Position = Vector2.new(bx - 6, topV.Y); obj.healthBg.Size = Vector2.new(3, h)
            obj.healthFg.Visible = Config.ESP.Health; obj.healthFg.Position = Vector2.new(bx - 6, topV.Y + h * (1 - hp)); obj.healthFg.Size = Vector2.new(3, h * hp)
            obj.healthFg.Color = Color3.fromRGB(240,90,90):Lerp(Color3.fromRGB(80,220,130), hp)

            obj.name.Visible = Config.ESP.Name; obj.name.Text = data.Player.Name; obj.name.Color = Color3.fromRGB(255,255,255); obj.name.Position = Vector2.new(topV.X, topV.Y - 16)
            obj.dist.Visible = Config.ESP.Dist; obj.dist.Text = math.floor((Camera.CFrame.Position - data.Root.Position).Magnitude) .. "m"; obj.dist.Color = Color3.fromRGB(200,200,200); obj.dist.Position = Vector2.new(topV.X, botV.Y + 2)
            obj.tracer.Visible = Config.ESP.Tracer; obj.tracer.Color = Color3.fromRGB(255,50,50); obj.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); obj.tracer.To = Vector2.new(topV.X, botV.Y)
        else
            for _, d in pairs(obj) do d.Visible = false end
        end
    end

    for char, obj in pairs(Cobble.ESPObjects) do
        if not activeChars[char] then
            for _, d in pairs(obj) do d:Remove() end
            Cobble.ESPObjects[char] = nil
        end
    end
end

-- ==========================================
-- HOOKS (Com checkcaller)
-- ==========================================
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if checkcaller() then return oldIndex(self, key) end
    
    if self == Mouse and (key == "Hit" or key == "Target") then
        local isDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
        if Config.Aimbot.Enabled and Config.Aimbot.Silent and isDown and Cobble.Target then
            local ballisticPos = CalculateBallisticPosition(Cobble.Target)
            return key == "Hit" and CFrame.new(ballisticPos) or Cobble.Target
        end
    end
    return oldIndex(self, key)
end)

-- ==========================================
-- LOOPS (Aimbot, Triggerbot, Render)
-- ==========================================
RunService:BindToRenderStep("CobbleAim", Enum.RenderPriority.Camera.Value + 100, function(dt)
    if not Config.Aimbot.Enabled or Config.Aimbot.Silent then return end
    local isDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
    if isDown and Cobble.Target then
        local ballisticPos = CalculateBallisticPosition(Cobble.Target)
        local desired = CFrame.lookAt(Camera.CFrame.Position, ballisticPos)
        Camera.CFrame = Camera.CFrame:Lerp(desired, 1 - (1 - Config.Aimbot.Smoothness)^(dt * 60))
    end
end)

task.spawn(function()
    while task.wait(Config.Triggerbot.Delay) do
        if not Config.Triggerbot.Enabled then continue end
        local target = GetClosestPlayer(Config.Triggerbot.FOV)
        if target then
            pcall(function()
                if mouse1click then mouse1click()
                elseif VirtualUser then VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new(0, 0))
                else
                    VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
                    task.wait(0.03)
                    VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end)
        end
    end
end)

task.spawn(function()
    while task.wait(1) do
        if Config.Util.Fullbright then
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.Brightness = 2
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    fovCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.HoldMode and not Config.Aimbot.Silent
    if fovCircle.Visible then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    end
end)

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleAim") end)
    for _, obj in pairs(Cobble.ESPObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    pcall(function() fovCircle:Remove() end)
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        mt.__index = oldIndex
        setreadonly(mt, true)
    end)
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
end
