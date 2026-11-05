-- COBBLE SCANNER (Engenharia Reversa)
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("=== INICIANDO SCANNER DA COBBLE HILLS ===")

-- 1. Procurar Remotes (Eventos que vão pro servidor)
print("\n[+] ESCANEANDO REMOTES...")
local function ScanRemotes(parent, path)
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            print("REMOTE ENCONTRADO:", path .. "." .. v.Name, "| Tipo:", v.ClassName)
        elseif v:IsA("Folder") or v:IsA("Model") then
            ScanRemotes(v, path .. "." .. v.Name)
        end
    end
end
ScanRemotes(RS, "ReplicatedStorage")
ScanRemotes(Workspace, "Workspace")

-- 2. Procurar Módulos da Arma (Multiplicadores, Spread, Crosshair)
print("\n[+] ESCANEANDO MÓDULOS DA ARMA...")
local function ScanModules(parent, path)
    for _, v in ipairs(parent:GetChildren()) do
        if v:IsA("ModuleScript") then
            print("MÓDULO ENCONTRADO:", path .. "." .. v.Name)
            pcall(function()
                local source = decompile(v) or ""
                -- Procura palavras-chave de dano ou spread no código do módulo
                if source:lower():find("head") or source:lower():find("spread") or source:lower():find("crosshair") or source:lower():find("damage") then
                    print("  -> ESTE MÓDULO PARECE CONTER LÓGICA DE COMBATE!")
                end
            end)
        elseif v:IsA("Folder") or v:IsA("Tool") then
            ScanModules(v, path .. "." .. v.Name)
        end
    end
end
ScanModules(RS, "ReplicatedStorage")
if LocalPlayer.Character then ScanModules(LocalPlayer.Character, "Character") end

-- 3. Remote Spy (Intercepta o que você manda pro servidor)
print("\n[+] INICIANDO REMOTE SPY (Atire para ver os logs)...")
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    -- Escuta chamadas que vão pro servidor
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local argsStr = ""
        for i, v in ipairs(args) do
            argsStr = argsStr .. "[" .. i .. "]: " .. tostring(v) .. "  "
        end
        print("[REMOTE SPY] ->", self:GetFullName(), "| Metodo:", method, "| Args:", argsStr)
    end
    
    return oldNamecall(self, ...)
end)

print("=== SCANNER PRONTO. EQUIPE UMA ARMA E ATIRE ===")
