-- cobble hills logic (ENTRENCHED EDITION)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

getgenv().CobbleConfig = {
    ESP = { 
        Enabled = true, 
        Box = true, 
        Name = true, 
        Dist = true, 
        Health = true, 
        TeamCheck = true 
    },
    Aimbot = { 
        Enabled = true, 
        HoldMode = true, 
        Key = Enum.UserInputType.MouseButton2, 
        FOV = 120, 
        Smoothness = 0.25, 
        TargetPart = "Head", 
        WallCheck = true,
        HitboxExpand = 0 -- 0 = Desligado, valor em studs para expandir
    },
    Util = { 
        Fullbright = false 
    }
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
                    temp[plr.Character] = { 
                        Player = plr, 
                        Hum = hum, 
                        Root = hrp 
                    }
                end
            end
        end
        CachedPlayers = temp
    end
end)

-- ESP
local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do
            for _, d in pairs(obj) do d.Visible = false end
        end
        return
    end

    local activeChars = {}

    for char, data in pairs(CachedPlayers) do
        local plr = data.Player
        local hum = data.Hum
        local root = data.Root

        -- Team Check
        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        activeChars[char] = true

        if not espObjects[char] then
            espObjects[char] = {
                box = Drawing.new("Square"),
                name = Drawing.new("Text"),
                dist = Drawing.new("Text"),
                healthBg = Drawing.new("Square"),
                healthFg = Drawing.new("Square")
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
            obj.box.Color = Color3.fromRGB(255, 50, 50) -- Vermelho para inimigos
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

-- AIMBOT
local function GetTarget()
    local mouse = UserInputService:GetMouseLocation()
    local camPos = Camera.CFrame.Position
    local best, bestDist = nil, Config.Aimbot.FOV

    for char, data in pairs(CachedPlayers) do
        local plr = data.Player
        if Config.ESP.TeamCheck and plr.Team == LocalPlayer.Team then continue end

        local part = char:FindFirstChild(Config.Aimbot.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if part then
            if Config.Aimbot.WallCheck then
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { LocalPlayer.Character, char }
                if Workspace:Raycast(camPos, part.Position - camPos, params) then continue end
            end

            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                -- Hitbox Expansion (Matemática)
                local effectiveFOV = Config.Aimbot.FOV + (Config.Aimbot.HitboxExpand * 10)
                if d < bestDist or (d < effectiveFOV and d < bestDist + 50) then
                    best, bestDist = part, d
                end
            end
        end
    end
    return best
end

RunService:BindToRenderStep("CobbleAim", Enum.RenderPriority.Camera.Value + 1, function()
    if not Config.Aimbot.Enabled then return end
    local isKeyDown = Config.Aimbot.HoldMode and (Config.Aimbot.Key.EnumType == Enum.KeyCode and UserInputService:IsKeyDown(Config.Aimbot.Key) or UserInputService:IsMouseButtonPressed(Config.Aimbot.Key)) or not Config.Aimbot.HoldMode

    if isKeyDown then
        local target = GetTarget()
        if target then
            local desired = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(desired, Config.Aimbot.Smoothness)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    
    if Config.Aimbot.Enabled and not Config.Aimbot.HoldMode then
        fovCircle.Visible = false
    elseif Config.Aimbot.Enabled and Config.Aimbot.HoldMode then
        fovCircle.Visible = true
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    else
        fovCircle.Visible = false
    end

    -- Fullbright
    if Config.Util.Fullbright then
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.Brightness = 2
    end
end)

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleAim") end)
    for _, obj in pairs(espObjects) do
        for _, d in pairs(obj) do pcall(function() d:Remove() end) end
    end
    pcall(function() fovCircle:Remove() end)
    -- Restaura o Fullbright
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
end
