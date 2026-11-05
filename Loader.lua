-- cobble hills loader (Entrenched)
local baseUrl = "https://raw.githubusercontent.com/vzz41761/Entrenched-cobble/refs/heads/main/"

-- Limpa a versão anterior se já estiver rodando
if getgenv().Cobble_Unload then 
    pcall(getgenv().Cobble_Unload) 
end

-- Puxa a Lógica e a UI do seu GitHub
local success, err = pcall(function()
    loadstring(game:HttpGet(baseUrl .. "Logic.lua"))()
    loadstring(game:HttpGet(baseUrl .. "UI.lua"))()
end)

if not success then
    warn("[cobble] Erro ao carregar: " .. tostring(err))
end
