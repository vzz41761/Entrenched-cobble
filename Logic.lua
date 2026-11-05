-- cobble hills logic (ENTRENCHED V13 - STABLE)
pcall(function() if setthreadidentity then setthreadidentity(8) end end)

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local VirtualUser      = game:GetService("VirtualUser")
local VIM              = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

getgenv().CobbleConfig = {
    ESP = { Enabled = true, Box = true, Chams = true, Name = true, Dist = true, Health = true, Tracer = true, TeamCheck = true },
    Aimbot = { Enabled = true, Silent = true, TargetPart = "Head", FOV = 250 },
    Triggerbot = { Enabled = false, Delay = 0.02, FOV = 15 },
    Util = { Fullbright = false, NoSpread = true, NoRecoil = true, FOVChanger = false, FOVValue = 90, Crosshair = true }
}

local Config = getgenv().CobbleConfig

-- ==========================================================
-- 1. DESATIVANDO O CAMERA SHAKER (Fim do bug da câmera)
-- ==========================================================
local cameraShaker = ReplicatedStorage:FindFirstChild("CameraShaker")
if cameraShaker then
    cameraShaker:Destroy() -- Remove o tremor de câmera do jogo
end

-- ==========================================================
-- 2. GUN MODS SEGUROS (Apenas Spread e Recoil)
-- ==========================================================
task.spawn(function()
    while task.wait(1) do -- Roda 1x por segundo para não quebrar a arma
        local containers = {LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")}
        for _, container in pairs(containers) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") then
                        local gunStates = tool:FindFirstChild("GunStates")
                        if gunStates then
                            pcall(function()
                                local states = require(gunStates)
                                if Config.Util.NoSpread then
                                    states.Spread = 0; states.MinSpread = 0; states.MaxSpread = 0; states.SpreadIncrease = 0
                                end
                                if Config.Util.NoRecoil then
                                    states.Recoil = 0; states.MinRecoil = 0; states.MaxRecoil = 0; states.CameraRecoil = 0
                                end
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- 3. CACHE E ESP
-- ==========================================================
local CachedPlayers = {}
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
        CachedPlayers = temp
    end
end)

local espObjects, chamsObjects = {}, {}
local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, obj in pairs(espObjects) do for _, d in pairs(obj) do d.Visible = false end end
        return
    end
    local active = {}
    for char, data in pairs(CachedPlayers) do
        if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
        active[char] = true
        
        if Config.ESP.Chams then
            if not chamsObjects[char] then
                local h = Instance.new("Highlight")
                h.Name = "CobbleChams"; h.FillColor = Color3.fromRGB(255, 50, 50); h.OutlineColor = Color3.new(1,1,1)
                h.FillTransparency = 0.5; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = char
                chamsObjects[char] = h
            end
        elseif chamsObjects[char] then chamsObjects[char]:Destroy(); chamsObjects[char] = nil end

        if not espObjects[char] then
            espObjects[char] = { box = Drawing.new("Square"), name = Drawing.new("Text"), dist = Drawing.new("Text"), healthBg = Drawing.new("Square"), healthFg = Drawing.new("Square"), tracer = Drawing.new("Line") }
            local o = espObjects[char]
            o.box.Thickness = 1; o.name.Size = 13; o.name.Center = true; o.name.Outline = true
            o.dist.Size = 12; o.dist.Center = true; o.dist.Outline = true
            o.healthBg.Filled = true; o.healthBg.Color = Color3.new(0,0,0); o.healthFg.Filled = true; o.tracer.Thickness = 1
        end
        local obj = espObjects[char]
        local head = char:FindFirstChild("Head") or data.Root
        local top3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bot3 = Camera:WorldToViewportPoint(data.Root.Position - Vector3.new(0, 2.5, 0))
        
        if top3.Z > 0 and bot3.Z > 0 then
            local topV, botV = Vector2.new(top3.X, top3.Y), Vector2.new(bot3.X, bot3.Y)
            local h, w = botV.Y - topV.Y, (botV.Y - topV.Y) * 0.55
            local bx = topV.X - w * 0.5
            obj.box.Visible = Config.ESP.Box; obj.box.Color = Color3.fromRGB(255, 50, 50); obj.box.Position = Vector2.new(bx, topV.Y); obj.box.Size = Vector2.new(w, h)
            local hp = math.clamp(data.Hum.Health / data.Hum.MaxHealth, 0, 1)
            obj.healthBg.Visible = Config.ESP.Health; obj.healthBg.Position = Vector2.new(bx - 6, topV.Y); obj.healthBg.Size = Vector2.new(3, h)
            obj.healthFg.Visible = Config.ESP.Health; obj.healthFg.Position = Vector2.new(bx - 6, topV.Y + h * (1 - hp)); obj.healthFg.Size = Vector2.new(3, h * hp); obj.healthFg.Color = Color3.fromRGB(240,90,90):Lerp(Color3.fromRGB(80,220,130), hp)
            obj.name.Visible = Config.ESP.Name; obj.name.Text = data.Player.Name; obj.name.Color = Color3.new(1,1,1); obj.name.Position = Vector2.new(topV.X, topV.Y - 16)
            obj.dist.Visible = Config.ESP.Dist; obj.dist.Text = math.floor((Camera.CFrame.Position - data.Root.Position).Magnitude) .. "m"; obj.dist.Color = Color3.fromRGB(200,200,200); obj.dist.Position = Vector2.new(topV.X, botV.Y + 2)
            obj.tracer.Visible = Config.ESP.Tracer; obj.tracer.Color = Color3.fromRGB(255,50,50); obj.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); obj.tracer.To = Vector2.new(topV.X, botV.Y)
        else for _, d in pairs(obj) do d.Visible = false end end
    end
    for char in pairs(espObjects) do
        if not active[char] then for _, d in pairs(espObjects[char]) do d:Remove() end; espObjects[char] = nil end
    end
end

-- ==========================================================
-- 4. AIMBOT E TRIGGERBOT (CORRIGIDOS)
-- ==========================================================
local function GetClosestPlayer(fovOverride)
    local mouse, camPos = UserInputService:GetMouseLocation(), Camera.CFrame.Position
    local best, bestDist = nil, fovOverride or Config.Aimbot.FOV
    
    -- Se o FOV for muito grande (ex: 360), ignora a verificação de distância da tela
    local checkFov = bestDist < 360
    
    for char, data in pairs(CachedPlayers) do
        if Config.ESP.TeamCheck and data.Player.Team == LocalPlayer.Team then continue end
        
        -- Tenta Head, se não tiver, Torso, se não tiver, Root
        local part = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or data.Root
        if part then
            local sp = Camera:WorldToViewportPoint(part.Position)
            if sp.Z > 0 then
                local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
                if (not checkFov) or (d < bestDist) then
                    best, bestDist = part, d
                end
            end
        end
    end
    return best
end

local shootRemote = ReplicatedStorage:WaitForChild("ServerEvents"):WaitForChild("Shoot")
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if self == shootRemote and method == "FireServer" then
        local args = {...}
        if Config.Aimbot.Enabled and Config.Aimbot.Silent then
            local targetPart = GetClosestPlayer()
            if targetPart then
                args[2] = targetPart.Position
            end
        end
        return oldNamecall(self, table.unpack(args))
    end
    return oldNamecall(self, ...)
end)

-- ==========================================================
-- 5. LOOPS
-- ==========================================================
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1.5; fovCircle.NumSides = 60; fovCircle.Color = Color3.fromRGB(90, 140, 255)

local crosshair = Drawing.new("Circle")
crosshair.Thickness = 1; crosshair.NumSides = 4; crosshair.Filled = true; crosshair.Color = Color3.fromRGB(0, 255, 0)

RunService.RenderStepped:Connect(function()
    UpdateESP()
    if Config.Util.Crosshair then
        crosshair.Visible = true
        crosshair.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        crosshair.Radius = 1.5
    else crosshair.Visible = false end
    
    if Config.Util.Fullbright then
        Lighting.Ambient = Color3.new(1,1,1); Lighting.OutdoorAmbient = Color3.new(1,1,1); Lighting.Brightness = 2
    end
    
    fovCircle.Visible = Config.Aimbot.Enabled
    if fovCircle.Visible then
        fovCircle.Position = UserInputService:GetMouseLocation()
        fovCircle.Radius = Config.Aimbot.FOV
    end
end)

-- TRIGGERBOT MELHORADO (Usa press/release em vez de click)
task.spawn(function()
    while task.wait(Config.Triggerbot.Delay) do
        if not Config.Triggerbot.Enabled then continue end
        local target = GetClosestPlayer(Config.Triggerbot.FOV)
        if target then
            pcall(function()
                if mouse1press and mouse1release then
                    mouse1press(); task.wait(0.01); mouse1release()
                elseif VirtualUser then
                    VirtualUser:CaptureController(); VirtualUser:ClickButton1(Vector2.new(0, 0))
                end
            end)
        end
    end
end)

-- FOV CHANGER (Com prioridade correta)
RunService:BindToRenderStep("CobbleFOV", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if Config.Util.FOVChanger then Camera.FieldOfView = Config.Util.FOVValue else Camera.FieldOfView = 70 end
end)

getgenv().Cobble_Unload = function()
    pcall(function() RunService:UnbindFromRenderStep("CobbleFOV") end)
    for _, obj in pairs(espObjects) do for _, d in pairs(obj) do pcall(function() d:Remove() end) end end
    for _, h in pairs(chamsObjects) do pcall(function() h:Destroy() end) end
    pcall(function() fovCircle:Remove() end)
    pcall(function() crosshair:Remove() end)
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false); mt.__namecall = oldNamecall; setreadonly(mt, true)
    end)
end
