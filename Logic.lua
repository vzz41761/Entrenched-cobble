-- cobble hills logic (ENTRENCHED PRO V5)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

getgenv().CobbleConfig = {
    ESP = { Enabled = true, Box = true, Name = true, Dist = true, Health = true, Tracer = true, TeamCheck = true },
    Aimbot = { Enabled = true, Silent = true, HoldMode = true, Key = Enum.UserInputType.MouseButton2, FOV = 150, Smoothness = 0.3, TargetPart = "Head", WallCheck = true, Prediction = 0.165 },
    Triggerbot = { Enabled = false, Delay = 0.01, FOV = 10 }, -- Atira sozinho
    Hitbox = { Enabled = false, Size = 10, Transparency = 0.5 },
    Util = { Fullbright = false, NoSpread = true }
}

local Config = getgenv().CobbleConfig
local CachedPlayers = {}
local espObjects = {}
local fovCircle = Drawing.new("Circle")

fovCircle.Thickness = 1.5
fovCircle.NumSides = 60
fovCircle.Color = Color3.fromRGB(90, 140, 255)

-- CACHE DE JOGADORES
task.spawn(function()
    while task.wait(0.5) do
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
        CachedPlayers = temp
    end
end)

-- HITBOX EXPANDER (Frame a Frame para não resetar)
RunService.Stepped:Connect(function()
    if not Config.Hitbox.Enabled then return end
    for char, data in pairs(CachedPlayers) do
        if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
        local root = data.Root
        local head = char:FindFirstChild("Head")
        local targetSize = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size)
        
        if root and root.Size ~= targetSize then
            root.Size = targetSize
            root.Transparency = Config.Hitbox.Transparency
            root.CanCollide = false
        end
        if head and head.Size ~= targetSize then
            head.Size = targetSize
            head.Transparency = Config.Hitbox.Transparency
            head.CanCollide = false
        end
    end
end)

-- ESP
local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end

    local activeChars = {}
    local screenCenter = Camera.ViewportSize / 2

    for char, data in pairs(CachedPlayers) do
        local plr = data.Player
        local hum = data.Hum
        local root = data.Root

        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        activeChars[char] = true

        if not espObjects[char] then
            espObjects[char] = {
                box = Drawing.new("Square"), name = Drawing.new("Text"),
                dist = Drawing.new("Text"), healthBg = Drawing.new("Square"),
                healthFg = Drawing.new("Square"), tracer = Drawing.new("Line")
            }
            espObjects[char].box.Thickness = 1
            espObjects[char].box.Filled = false
            espObjects[char].name.Size = 13
            espObjects[char].name.Center = true
            espObjects[char].name.Outline = true
            espObjects[char].dist.Size = 12
            espObjects[char].dist.Center = true
            espObjects[char].dist.Outline = true
            espObjects[char].healthBg.Filled = true
            espObjects[char].healthBg.Color = Color3.new(0,0,0)
            espObjects[char].healthFg.Filled = true
            espObjects[char].tracer.Thickness = 1
        end

        local obj = espObjects[char]
        local head = char:FindFirstChild("Head") or root
        local top3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bot3 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

        if top3.Z > 0 and bot3.Z > 0 then
            local topV = Vector2.new(top3.X, top3.Y)
            local botV = Vector2.new(bot3.X, bot3.Y)
            local h = botV.Y - topV.Y
            local w = h * 0.55
            local bx = topV.X - w * 0.5

            obj.box.Visible = Config.ESP.Box
            obj.box.Color = Color3.fromRGB(255, 50, 50)
            obj.box.Position = Vector2.new(bx, topV.Y)
            obj.box.Size = Vector2.new(w, h)

            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            obj.healthBg.Visible = Config.ESP.Health
            obj.healthBg.Position = Vector2.new(bx - 6, topV.Y)
            obj.healthBg.Size = Vector2.new(3, h)
            obj.healthFg.Visible = Config.ESP.Health
            obj.healthFg.Position = Vector2.new(bx - 6, topV.Y + h * (1 - hp))
            obj.healthFg.Size = Vector2.new(3, h * hp)
            obj.healthFg.Color = Color3.fromRGB(240, 90, 90):Lerp(Color3.fromRGB(80, 220, 130), hp)

            obj.name.Visible = Config.ESP.Name
            obj.name.Text = plr.Name
            obj.name.Color = Color3.fromRGB(255, 255, 255)
            obj.name.Position = Vector2.new(topV.X, topV.Y - 16)

            obj.dist.Visible = Config.ESP.Dist
            obj.dist.Text = math.floor((Camera.CFrame.Position - root.Position).Magnitude) .. "m"
            obj.dist.Color = Color3.fromRGB(200, 200, 200)
            obj.dist.Position = Vector2.new(topV.X, botV.Y + 2)

            obj.tracer.Visible = Config.ESP.Tracer
            obj.tracer.Color = Color3.fromRGB(255, 50, 50)
            obj.tracer.From = Vector2.new(screenCenter.X, Camera.ViewportSize.Y)
            obj.tracer.To = Vector2.new(topV.X, botV.Y)
        else
            for _, d in pairs(obj) do d.Visible = false end
        end
    end

    for char, obj in pairs(espObjects) do
        if not activeChars[char] then
            for _, d in pairs(obj) do d:Remove() end
            espObjects[char] = nil
        end
    end
end

-- FUNÇÃO DO AIMBOT
local function GetClosestPlayer(fovOverride)
    local mouse = UserInputService:GetMouseLocation()
    local camPos = Camera.CFrame.Position
    local currentFov = fovOverride or Config.Aimbot.FOV
    local best, bestDist = nil, currentFov

    for char, data in pairs(CachedPlayers) do
        local plr = data.Player
        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if part then
            if Config.Aimbot.WallCheck then
                local ray = Ray.new(camPos, part.Position - camPos)
                local hitPart = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
                if hitPart and hitPart ~= part and not hitPart:IsDescendantOf(char) then
                    continue
                end
            end

            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if d < bestDist then
                    best, bestDist = part, d
                end
            end
        end
    end
    return best
end

-- HOOK DO SILENT AIM E NO SPREAD (Namecall)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- Silent Aim
    if Config.Aimbot.Enabled and Config.Aimbot.Silent and self == Mouse then
        local isKeyDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
        if isKeyDown then
            if method == "GetMouse" or method == "get" then
                -- Fallback, mas o hook abaixo pega direto
            elseif method == "Hit" or method == "Target" then
                local target = GetClosestPlayer()
                if target then
                    local predictedPos = target.Position + (target.Velocity * Config.Aimbot.Prediction)
                    return (method == "Hit" and CFrame.new(predictedPos) or target)
                end
            end
        end
    end

    -- No Spread (Hook no Raycast do jogo)
    if Config.Util.NoSpread and (method == "Raycast" or method == "FindPartOnRay") then
        local args = {...}
        if method == "Raycast" then
            local origin, direction, params = args[1], args[2], args[3]
            -- Força a direção a ser o centro da tela (ou o alvo do Silent Aim)
            local target = Config.Aimbot.Enabled and GetClosestPlayer()
            if target then
                direction = (target.Position - origin).Unit * direction.Magnitude
            else
                local unitRay = Camera:ScreenPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                direction = unitRay.Direction * direction.Magnitude
            end
            return oldNamecall(self, origin, direction, params)
        elseif method == "FindPartOnRay" then
            local ray, ignore = args[1], args[2]
            local target = Config.Aimbot.Enabled and GetClosestPlayer()
            if target then
                ray = Ray.new(ray.Origin, (target.Position - ray.Origin).Unit * ray.Direction.Magnitude)
            else
                local unitRay = Camera:ScreenPointToRay(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                ray = Ray.new(ray.Origin, unitRay.Direction * ray.Direction.Magnitude)
            end
            return oldNamecall(self, ray, ignore)
        end
    end

    return oldNamecall(self, ...)
end)

-- Camera Lock Aimbot (Se não for Silent)
RunService:BindToRenderStep("CobbleAim", Enum.RenderPriority.Camera.Value + 100, function()
    if not Config.Aimbot.Enabled or Config.Aimbot.Silent then return end
    local isKeyDown = Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
    if isKeyDown then
        local target = GetClosestPlayer()
        if target then
            local desired = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(desired, Config.Aimbot.Smoothness)
        end
    end
end)

-- TRIGGERBOT (Atira sozinho)
task.spawn(function()
    while task.wait(Config.Triggerbot.Delay) do
        if not Config.Triggerbot.Enabled then continue end
        
        -- Ele não checa mais se você tá segurando o mouse, ele simplesmente atira se o inimigo passar no FOV
        local target = GetClosestPlayer(Config.Triggerbot.FOV)
        if target then
            pcall(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton1(Vector2.new(0, 0))
            end)
        end
    end
end)

-- FULLBRIGHT
task.spawn(function()
    while task.wait(1) do
        if Config.Util.Fullbright then
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.Brightness = 2
        end
    end
end)

-- LOOP DE RENDERIZAÇÃO
RunService.RenderStepped:Connect(function()
    UpdateESP()
    if Config.Aimbot.Enabled and Config.Aimbot.HoldMode and not Config.Aimbot.Silent then
        fovCircle.Visible = true
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    else
        fovCircle.Visible = false
    end
end)

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleAim") end)
    for _, obj in pairs(espObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    pcall(function() fovCircle:Remove() end)
    pcall(function()
        if hookmetamethod and oldNamecall then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end
    end)
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
end
