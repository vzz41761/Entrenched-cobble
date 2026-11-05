-- cobble hills logic (ENTRENCHED PRO V7)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

getgenv().CobbleConfig = {
    ESP      = { Enabled = true,  Box = true, Name = true, Dist = true, Health = true, Tracer = true, TeamCheck = true },
    Aimbot   = { Enabled = true,  Silent = true, HoldMode = true, Key = Enum.UserInputType.MouseButton2,
                 FOV = 150, Smoothness = 0.3, TargetPart = "Head", WallCheck = true, Prediction = 0.165 },
    Triggerbot = { Enabled = false, Delay = 0.01, FOV = 10 },
    Hitbox   = { Enabled = false, Size = 6, Transparency = 0.5 },
    Util     = { Fullbright = false, NoSpread = true }
}

local Config        = getgenv().CobbleConfig
local CachedPlayers = {}
local espObjects    = {}
local fovCircle     = Drawing.new("Circle")
local CurrentTarget = nil -- Cache do alvo atual (Evita crashes)

fovCircle.Thickness = 1.5
fovCircle.NumSides  = 60
fovCircle.Color     = Color3.fromRGB(90, 140, 255)

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

-- HITBOX EXPANDER
task.spawn(function()
    while task.wait(0.1) do
        if not Config.Hitbox.Enabled then continue end
        for char, data in pairs(CachedPlayers) do
            if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
            local targetSize = Vector3.new(Config.Hitbox.Size, Config.Hitbox.Size, Config.Hitbox.Size)
            for _, partName in ipairs({"HumanoidRootPart", "Head"}) do
                local part = char:FindFirstChild(partName)
                if part and part.Size ~= targetSize then
                    part.Size         = targetSize
                    part.Transparency = Config.Hitbox.Transparency
                    part.CanCollide   = false
                end
            end
        end
    end
end)

-- LÓGICA DO ALVO (Roda em segundo plano para não sobrecarregar os hooks)
local function GetClosestPlayer(fovOverride)
    local mouse      = UserInputService:GetMouseLocation()
    local camPos     = Camera.CFrame.Position
    local currentFov = fovOverride or Config.Aimbot.FOV
    local best, bestDist = nil, currentFov

    for char, data in pairs(CachedPlayers) do
        local plr = data.Player
        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if part then
            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if d < bestDist then 
                    -- O WallCheck só roda no candidato mais próximo para economizar processamento
                    if Config.Aimbot.WallCheck then
                        local params = RaycastParams.new()
                        params.FilterDescendantsInstances = {LocalPlayer.Character}
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        local result = Workspace:Raycast(camPos, part.Position - camPos, params)
                        if not (result and result.Instance and not result.Instance:IsDescendantOf(char)) then
                            best, bestDist = part, d
                        end
                    else
                        best, bestDist = part, d
                    end
                end
            end
        end
    end
    return best
end

-- Atualiza o CurrentTarget 30 vezes por segundo (Fim do crash)
task.spawn(function()
    while task.wait(0.03) do
        if Config.Aimbot.Enabled then
            CurrentTarget = GetClosestPlayer()
        else
            CurrentTarget = nil
        end
    end
end)

-- ESP
local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end

    local activeChars  = {}
    local screenCenter = Camera.ViewportSize / 2

    for char, data in pairs(CachedPlayers) do
        local plr  = data.Player
        local hum  = data.Hum
        local root = data.Root
        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end
        activeChars[char] = true

        if not espObjects[char] then
            espObjects[char] = {
                box      = Drawing.new("Square"), name     = Drawing.new("Text"),
                dist     = Drawing.new("Text"),   healthBg = Drawing.new("Square"),
                healthFg = Drawing.new("Square"), tracer   = Drawing.new("Line")
            }
            local o = espObjects[char]
            o.box.Thickness = 1;  o.box.Filled = false
            o.name.Size = 13;     o.name.Center = true;  o.name.Outline = true
            o.dist.Size = 12;     o.dist.Center = true;  o.dist.Outline = true
            o.healthBg.Filled = true; o.healthBg.Color = Color3.new(0,0,0)
            o.healthFg.Filled = true
            o.tracer.Thickness = 1
        end

        local obj  = espObjects[char]
        local head = char:FindFirstChild("Head") or root
        local top3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bot3 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0))

        if top3.Z > 0 and bot3.Z > 0 then
            local topV = Vector2.new(top3.X, top3.Y)
            local botV = Vector2.new(bot3.X, bot3.Y)
            local h    = botV.Y - topV.Y
            local w    = h * 0.55
            local bx   = topV.X - w * 0.5

            obj.box.Visible  = Config.ESP.Box
            obj.box.Color    = Color3.fromRGB(255, 50, 50)
            obj.box.Position = Vector2.new(bx, topV.Y)
            obj.box.Size     = Vector2.new(w, h)

            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            obj.healthBg.Visible  = Config.ESP.Health
            obj.healthBg.Position = Vector2.new(bx - 6, topV.Y)
            obj.healthBg.Size     = Vector2.new(3, h)
            obj.healthFg.Visible  = Config.ESP.Health
            obj.healthFg.Position = Vector2.new(bx - 6, topV.Y + h * (1 - hp))
            obj.healthFg.Size     = Vector2.new(3, h * hp)
            obj.healthFg.Color    = Color3.fromRGB(240,90,90):Lerp(Color3.fromRGB(80,220,130), hp)

            obj.name.Visible  = Config.ESP.Name
            obj.name.Text     = plr.Name
            obj.name.Color    = Color3.fromRGB(255,255,255)
            obj.name.Position = Vector2.new(topV.X, topV.Y - 16)

            obj.dist.Visible  = Config.ESP.Dist
            obj.dist.Text     = math.floor((Camera.CFrame.Position - root.Position).Magnitude) .. "m"
            obj.dist.Color    = Color3.fromRGB(200,200,200)
            obj.dist.Position = Vector2.new(topV.X, botV.Y + 2)

            obj.tracer.Visible = Config.ESP.Tracer
            obj.tracer.Color   = Color3.fromRGB(255,50,50)
            obj.tracer.From    = Vector2.new(screenCenter.X, Camera.ViewportSize.Y)
            obj.tracer.To      = Vector2.new(topV.X, botV.Y)
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

-- SILENT AIM (Hook Index usando Cache)
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if self == Mouse and (key == "Hit" or key == "Target") then
        local isDown = Config.Aimbot.Key.EnumType == Enum.KeyCode
            and UserInputService:IsKeyDown(Config.Aimbot.Key)
            or  UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
        if Config.Aimbot.Enabled and Config.Aimbot.Silent and isDown and CurrentTarget then
            local predicted = CurrentTarget.Position + (CurrentTarget.AssemblyLinearVelocity * Config.Aimbot.Prediction)
            return key == "Hit" and CFrame.new(predicted) or CurrentTarget
        end
    end
    return oldIndex(self, key)
end)

-- NO SPREAD (Hook Namecall usando Cache)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if Config.Util.NoSpread and (method == "Raycast" or method == "FindPartOnRay") then
        local args = {...}
        if method == "Raycast" then
            local origin, direction, params = args[1], args[2], args[3]
            -- Se tiver alvo, puxa pro alvo. Se não, força a ir reto na câmera.
            local targetDir = CurrentTarget and (CurrentTarget.Position - origin).Unit or Camera.CFrame.LookVector
            return oldNamecall(self, origin, targetDir * direction.Magnitude, params)
        elseif method == "FindPartOnRay" then
            local ray, ignore = args[1], args[2]
            local targetDir = CurrentTarget and (CurrentTarget.Position - ray.Origin).Unit or Camera.CFrame.LookVector
            return oldNamecall(self, Ray.new(ray.Origin, targetDir * ray.Direction.Magnitude), ignore)
        end
    end
    return oldNamecall(self, ...)
end)

-- CAMERA LOCK AIMBOT (Usando Cache)
RunService:BindToRenderStep("CobbleAim", Enum.RenderPriority.Camera.Value + 100, function(dt)
    if not Config.Aimbot.Enabled or Config.Aimbot.Silent then return end
    local isDown = Config.Aimbot.Key.EnumType == Enum.KeyCode
        and UserInputService:IsKeyDown(Config.Aimbot.Key)
        or  UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)
    if isDown and CurrentTarget then
        local desired = CFrame.lookAt(Camera.CFrame.Position, CurrentTarget.Position)
        local alpha = 1 - (1 - Config.Aimbot.Smoothness)^(dt * 60)
        Camera.CFrame = Camera.CFrame:Lerp(desired, alpha)
    end
end)

-- TRIGGERBOT (Agressivo com Fallbacks)
task.spawn(function()
    while task.wait(Config.Triggerbot.Delay) do
        if not Config.Triggerbot.Enabled then continue end
        local target = GetClosestPlayer(Config.Triggerbot.FOV)
        if target then
            pcall(function()
                if mouse1click then
                    mouse1click()
                elseif game:GetService("VirtualUser") then
                    game:GetService("VirtualUser"):CaptureController()
                    game:GetService("VirtualUser"):ClickButton1(Vector2.new(0, 0))
                else
                    local vim = game:GetService("VirtualInputManager")
                    vim:SendMouseButtonEvent(0, 0, 0, true,  game, 1)
                    task.wait(0.03)
                    vim:SendMouseButtonEvent(0, 0, 0, false, game, 1)
                end
            end)
        end
    end
end)

-- FULLBRIGHT
task.spawn(function()
    while task.wait(1) do
        if Config.Util.Fullbright then
            Lighting.Ambient        = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.Brightness     = 2
        end
    end
end)

-- RENDER LOOP
RunService.RenderStepped:Connect(function()
    UpdateESP()
    if Config.Aimbot.Enabled and Config.Aimbot.HoldMode and not Config.Aimbot.Silent then
        fovCircle.Visible  = true
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius   = Config.Aimbot.FOV
    else
        fovCircle.Visible = false
    end
end)

-- UNLOAD
getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleAim") end)
    for _, obj in pairs(espObjects) do
        for _, d in pairs(obj) do pcall(function() d:Remove() end) end
    end
    pcall(function() fovCircle:Remove() end)
    pcall(function()
        if hookmetamethod then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            if oldNamecall then mt.__namecall = oldNamecall end
            if oldIndex    then mt.__index    = oldIndex    end
            setreadonly(mt, true)
        end
    end)
    Lighting.Ambient        = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness     = 1
end
