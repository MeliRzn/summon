-- ============================================================
-- DEX FARM v5.5 — UI organizada + modo Torre separado
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Golpear = ReplicatedStorage:WaitForChild("Golpear")
local Atacar = ReplicatedStorage:WaitForChild("Atacar")
local DadosArmas = require(ReplicatedStorage:WaitForChild("DadosArmas"))
local DadosMonstros = require(ReplicatedStorage:WaitForChild("DadosMonstros"))

local C = {
    bg      = Color3.fromRGB(20, 20, 24),
    card    = Color3.fromRGB(30, 30, 36),
    card2   = Color3.fromRGB(42, 42, 50),
    stroke  = Color3.fromRGB(58, 58, 66),
    text    = Color3.fromRGB(240, 240, 245),
    dim     = Color3.fromRGB(142, 142, 152),
    blue    = Color3.fromRGB(10, 132, 255),
    green   = Color3.fromRGB(48, 209, 88),
    red     = Color3.fromRGB(255, 69, 58),
    orange  = Color3.fromRGB(255, 159, 10),
    gold    = Color3.fromRGB(255, 214, 90),
    purple  = Color3.fromRGB(175, 82, 222),
}
local F  = Enum.Font.Gotham
local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium

local S = {
    ativo = false, -- calculado pelos modos individuais
    farmBiomaAtivo = false,
    torreFarmAtivo = false,
    autoAtaque = true,
    travarMira = true,
    walkBoost = true,
    autoColetar = true,
    monstroId = "Slime",
    monstroNome = "Slime Musgoso",
    distancia = 5,
    walkSpeed = 100,
    raioColeta = 60,
    abates = 0,
    coletados = 0,
    alvoAtual = "nenhum",
    -- Portais de área
    portalAreaAtual = "Hub",
    portalAutoViajar = true,
    portalEmCurso = false,
    -- Torre via remote TorreEvento
    torreAtivo = false,
    torreAutoEntrar = true,
    torreAutoAdvance = true,
    torreAutoReviver = true,
    torreAndar = 0,
}
local walkOriginal = 16

-- Limpa
for _, g in pairs(LP.PlayerGui:GetChildren()) do
    if g.Name == "DexFarm" or g.Name == "DexFarmDrop" then g:Destroy() end
end

local GUI = Instance.new("ScreenGui")
GUI.Name = "DexFarm"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.DisplayOrder = 999
GUI.Parent = LP:WaitForChild("PlayerGui")

-- GUI separada para o dropdown (fica por cima de tudo)
local DropGui = Instance.new("ScreenGui")
DropGui.Name = "DexFarmDrop"
DropGui.ResetOnSpawn = false
DropGui.IgnoreGuiInset = true
DropGui.DisplayOrder = 9999
DropGui.Parent = LP:WaitForChild("PlayerGui")

local function corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end
local function stroke(p, c, t)
    local s = Instance.new("UIStroke")
    s.Color = c or C.stroke; s.Thickness = t or 1; s.Parent = p
end

-- ============================================================
-- JANELA
-- ============================================================
local camera = workspace.CurrentCamera
local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
local W, H = math.max(300, math.min(500, viewport.X - 24)), math.max(380, math.min(650, viewport.Y - 24))

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(W, H)
Main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = GUI
corner(Main, 18)
stroke(Main, C.stroke, 1)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 54)
Header.BackgroundColor3 = C.card
Header.BorderSizePixel = 0
Header.Parent = Main
corner(Header, 18)

local HFix = Instance.new("Frame")
HFix.Size = UDim2.new(1, 0, 0, 18)
HFix.Position = UDim2.new(0, 0, 1, -18)
HFix.BackgroundColor3 = C.card
HFix.BorderSizePixel = 0
HFix.Parent = Header

local Icon = Instance.new("TextLabel")
Icon.Size = UDim2.fromOffset(28, 28)
Icon.Position = UDim2.fromOffset(16, 13)
Icon.BackgroundTransparency = 1
Icon.Text = "✦"
Icon.TextColor3 = C.blue
Icon.TextSize = 22
Icon.Font = FB
Icon.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -120, 0, 20)
Title.Position = UDim2.fromOffset(50, 11)
Title.BackgroundTransparency = 1
Title.Text = "DEX FARM"
Title.TextColor3 = C.text
Title.TextSize = 16
Title.Font = FB
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -120, 0, 14)
Sub.Position = UDim2.fromOffset(50, 30)
Sub.BackgroundTransparency = 1
Sub.Text = "v5.5 · farm por área + Torre"
Sub.TextColor3 = C.dim
Sub.TextSize = 10
Sub.Font = F
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = Header

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.fromOffset(30, 30)
MinBtn.Position = UDim2.new(1, -76, 0, 12)
MinBtn.BackgroundColor3 = C.card2
MinBtn.Text = "—"
MinBtn.TextColor3 = C.text
MinBtn.TextSize = 14
MinBtn.Font = FB
MinBtn.AutoButtonColor = false
MinBtn.Parent = Header
corner(MinBtn, 15)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = C.red
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 12
CloseBtn.Font = FB
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
corner(CloseBtn, 15)

-- ============================================================
-- SCROLL — Fix #1: AutomaticCanvasSize (sem scroll infinito)
-- ============================================================
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -74)
Scroll.Position = UDim2.fromOffset(10, 64)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = C.stroke
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)  -- ← deixa o Automatic calcular
Scroll.ScrollBarImageTransparency = 0.3
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 12)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Pad = Instance.new("UIPadding")
Pad.PaddingTop = UDim.new(0, 4)
Pad.PaddingBottom = UDim.new(0, 20)
Pad.PaddingRight = UDim.new(0, 6)
Pad.Parent = Scroll

-- ============================================================
-- COMPONENTES
-- ============================================================
local function secao(titulo, altura)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -8, 0, altura + 38)
    Holder.BackgroundTransparency = 1
    Holder.Parent = Scroll

    local Head = Instance.new("TextButton")
    Head.Size = UDim2.new(1, 0, 0, 32)
    Head.BackgroundColor3 = C.card2
    Head.BorderSizePixel = 0
    Head.Text = "  " .. titulo
    Head.TextColor3 = C.text
    Head.TextSize = 13
    Head.Font = FB
    Head.TextXAlignment = Enum.TextXAlignment.Left
    Head.AutoButtonColor = false
    Head.Parent = Holder
    corner(Head, 9)
    stroke(Head, C.stroke, 1)
    local Arrow = Instance.new("TextLabel")
    Arrow.Size = UDim2.fromOffset(28, 32)
    Arrow.Position = UDim2.new(1, -32, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Text = "v"
    Arrow.TextColor3 = C.dim
    Arrow.TextSize = 18
    Arrow.Font = FB
    Arrow.Parent = Head

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, 0, 0, altura)
    Box.Position = UDim2.fromOffset(0, 38)
    Box.BackgroundColor3 = C.card
    Box.BorderSizePixel = 0
    Box.Parent = Holder
    corner(Box, 12)
    stroke(Box, C.stroke, 1)

    local BL = Instance.new("UIListLayout")
    BL.Padding = UDim.new(0, 0)
    BL.SortOrder = Enum.SortOrder.LayoutOrder
    BL.Parent = Box

    local BP = Instance.new("UIPadding")
    BP.PaddingTop = UDim.new(0, 6)
    BP.PaddingBottom = UDim.new(0, 6)
    BP.Parent = Box

    local expanded = true
    Head.MouseButton1Click:Connect(function()
        expanded = not expanded
        Box.Visible = expanded
        Holder.Size = UDim2.new(1, -8, 0, expanded and (altura + 38) or 32)
        Arrow.Text = expanded and "v" or ">"
    end)
    return Box
end

local function toggle(parent, texto, default, cb)
    local R = Instance.new("Frame")
    R.Size = UDim2.new(1, 0, 0, 42)
    R.BackgroundTransparency = 1
    R.Parent = parent

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -86, 1, 0)
    L.Position = UDim2.fromOffset(14, 0)
    L.BackgroundTransparency = 1
    L.Text = texto
    L.TextColor3 = C.text
    L.TextSize = 14
    L.Font = FM
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = R

    local Track = Instance.new("Frame")
    Track.Size = UDim2.fromOffset(48, 28)
    Track.Position = UDim2.new(1, -62, 0.5, -14)
    Track.BackgroundColor3 = default and C.green or Color3.fromRGB(80, 80, 90)
    Track.BorderSizePixel = 0
    Track.Parent = R
    corner(Track, 14)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.fromOffset(24, 24)
    Knob.Position = default and UDim2.new(1, -26, 0, 2) or UDim2.fromOffset(2, 2)
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.BorderSizePixel = 0
    Knob.Parent = Track
    corner(Knob, 12)

    local Click = Instance.new("TextButton")
    Click.Size = UDim2.fromScale(1, 1)
    Click.BackgroundTransparency = 1
    Click.Text = ""
    Click.Parent = R

    local est = default
    Click.MouseButton1Click:Connect(function()
        est = not est
        TweenService:Create(Track, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            BackgroundColor3 = est and C.green or Color3.fromRGB(80, 80, 90)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Quart), {
            Position = est and UDim2.new(1, -26, 0, 2) or UDim2.fromOffset(2, 2)
        }):Play()
        if cb then cb(est) end
    end)
    return { set = function(v) est = v end }
end

local function slider(parent, texto, minV, maxV, default, cb)
    local R = Instance.new("Frame")
    R.Size = UDim2.new(1, 0, 0, 56)
    R.BackgroundTransparency = 1
    R.Parent = parent

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -100, 0, 18)
    L.Position = UDim2.fromOffset(14, 8)
    L.BackgroundTransparency = 1
    L.Text = texto
    L.TextColor3 = C.text
    L.TextSize = 13
    L.Font = FM
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = R

    local Val = Instance.new("TextLabel")
    Val.Size = UDim2.fromOffset(60, 18)
    Val.Position = UDim2.new(1, -74, 0, 8)
    Val.BackgroundTransparency = 1
    Val.Text = tostring(default)
    Val.TextColor3 = C.blue
    Val.TextSize = 13
    Val.Font = FB
    Val.TextXAlignment = Enum.TextXAlignment.Right
    Val.Parent = R

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -28, 0, 4)
    Track.Position = UDim2.fromOffset(14, 38)
    Track.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
    Track.BorderSizePixel = 0
    Track.Parent = R
    corner(Track, 2)

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - minV) / (maxV - minV), 0, 1, 0)
    Fill.BackgroundColor3 = C.blue
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    corner(Fill, 2)

    local Knob = Instance.new("Frame")
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.Size = UDim2.fromOffset(16, 16)
    Knob.Position = UDim2.new((default - minV) / (maxV - minV), 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.new(1, 1, 1)
    Knob.BorderSizePixel = 0
    Knob.Parent = Track
    corner(Knob, 8)

    local Click = Instance.new("TextButton")
    Click.Size = UDim2.fromScale(1, 1)
    Click.BackgroundTransparency = 1
    Click.Text = ""
    Click.Parent = R

    local drag = false
    local function setX(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local v = minV + rel * (maxV - minV)
        v = math.floor(v * 10 + 0.5) / 10
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        Knob.Position = UDim2.new(rel, 0, 0.5, 0)
        Val.Text = tostring(v)
        if cb then cb(v) end
    end
    Click.MouseButton1Down:Connect(function() drag = true; setX(UserInputService:GetMouseLocation().X) end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then setX(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

-- ============================================================
-- DROPDOWN — Fix #2: usa GUI separada + CanvasSize correto
-- ============================================================
local function dropdown(parent, texto, opcoes, defaultNome, cb)
    local R = Instance.new("Frame")
    R.Size = UDim2.new(1, 0, 0, 44)
    R.BackgroundTransparency = 1
    R.Parent = parent

    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, -180, 1, 0)
    L.Position = UDim2.fromOffset(14, 0)
    L.BackgroundTransparency = 1
    L.Text = texto
    L.TextColor3 = C.text
    L.TextSize = 13
    L.Font = FM
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = R

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.fromOffset(170, 30)
    Btn.Position = UDim2.new(1, -184, 0.5, -15)
    Btn.BackgroundColor3 = C.card2
    Btn.Text = defaultNome
    Btn.TextColor3 = C.blue
    Btn.TextSize = 12
    Btn.Font = FB
    Btn.AutoButtonColor = false
    Btn.TextTruncate = Enum.TextTruncate.AtEnd
    Btn.Parent = R
    corner(Btn, 8)
    stroke(Btn, C.stroke, 1)

    local overlay = nil
    local lista = nil
    local aberto = false

    local function fechar()
        if lista then lista:Destroy(); lista = nil end
        if overlay then overlay:Destroy(); overlay = nil end
        aberto = false
    end

    Btn.MouseButton1Click:Connect(function()
        if aberto then fechar(); return end
        aberto = true

        -- Overlay cobre a tela toda (na GUI de cima)
        overlay = Instance.new("TextButton")
        overlay.Size = UDim2.fromScale(1, 1)
        overlay.BackgroundTransparency = 1
        overlay.Text = ""
        overlay.ZIndex = 1
        overlay.Parent = DropGui

        -- Lista
        local altura = math.min(#opcoes * 32 + 12, 260)
        lista = Instance.new("ScrollingFrame")
        lista.Size = UDim2.fromOffset(180, altura)
        lista.Position = UDim2.fromOffset(Btn.AbsolutePosition.X - 10, Btn.AbsolutePosition.Y + 32)
        lista.BackgroundColor3 = C.card2
        lista.BorderSizePixel = 0
        lista.ScrollBarThickness = 2
        lista.ScrollBarImageColor3 = C.stroke
        lista.ZIndex = 2
        -- ✅ Fix: CanvasSize correto pro conteúdo
        lista.CanvasSize = UDim2.new(0, 0, 0, #opcoes * 32 + 12)
        lista.Parent = overlay
        corner(lista, 10)
        stroke(lista, C.stroke, 1)

        local LL = Instance.new("UIListLayout")
        LL.Padding = UDim.new(0, 0)
        LL.SortOrder = Enum.SortOrder.LayoutOrder
        LL.Parent = lista

        for i, op in ipairs(opcoes) do
            local B = Instance.new("TextButton")
            B.Size = UDim2.new(1, 0, 0, 32)
            B.BackgroundTransparency = 1
            B.Text = "  " .. op.nome
            B.TextColor3 = C.text
            B.TextSize = 12
            B.Font = F
            B.TextXAlignment = Enum.TextXAlignment.Left
            B.AutoButtonColor = false
            B.LayoutOrder = i
            B.ZIndex = 3
            B.Parent = lista

            B.MouseEnter:Connect(function()
                B.BackgroundTransparency = 0
                B.BackgroundColor3 = C.blue
            end)
            B.MouseLeave:Connect(function()
                B.BackgroundTransparency = 1
            end)
            B.MouseButton1Click:Connect(function()
                Btn.Text = op.nome
                if cb then cb(op.id, op.nome) end
                fechar()
            end)
        end
    end)

    -- Overlay fecha ao clicar fora
    task.spawn(function()
        while GUI.Parent do
            task.wait(0.1)
            if overlay and overlay.Parent then
                -- Handler de click-outside via InputBegan
                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local pos = input.Position
                        local absX, absY = lista.AbsolutePosition.X, lista.AbsolutePosition.Y
                        local absX2, absY2 = absX + lista.AbsoluteSize.X, absY + lista.AbsoluteSize.Y
                        if not (pos.X >= absX and pos.X <= absX2 and pos.Y >= absY and pos.Y <= absY2) then
                            fechar()
                            conn:Disconnect()
                        end
                    end
                end)
            end
        end
    end)
end

local function botao(parent, texto, cor, cb)
    local B = Instance.new("TextButton")
    B.Size = UDim2.new(1, 0, 0, 46)
    B.BackgroundColor3 = C.card
    B.Text = texto
    B.TextColor3 = cor or C.blue
    B.TextSize = 15
    B.Font = FB
    B.AutoButtonColor = false
    B.Parent = parent
    corner(B, 12)
    stroke(B, C.stroke, 1)

    B.MouseButton1Down:Connect(function()
        TweenService:Create(B, TweenInfo.new(0.1), { BackgroundColor3 = C.card2 }):Play()
    end)
    B.MouseButton1Up:Connect(function()
        TweenService:Create(B, TweenInfo.new(0.2), { BackgroundColor3 = C.card }):Play()
    end)
    B.MouseLeave:Connect(function()
        TweenService:Create(B, TweenInfo.new(0.2), { BackgroundColor3 = C.card }):Play()
    end)
    if cb then B.MouseButton1Click:Connect(cb) end
    return B
end

-- ============================================================
-- BIOMAS E CRIATURAS: cada monstro fica somente na sua área.
-- ============================================================
local Biomas = {
    { id="Hub", nome="Hub · Clareira do Pylon", nivel="Nv. 1+", monstros={{id="Slime",nome="Slime Musgoso"},{id="Lobo",nome="Lobo Glacial"}} },
    { id="Deserto", nome="Deserto · Dunas Escaldantes", nivel="Nv. 8+", monstros={{id="Guardiao",nome="Guardião do Deserto"},{id="GuardiaoChefe",nome="Guardião Carmesim (chefe)"}} },
    { id="Floresta", nome="Floresta · Floresta Encantada", nivel="Nv. 14+", monstros={{id="Espreitador",nome="Espreitador de Espinhos"},{id="AnciaoRaiz",nome="Ancião Raiz Corrompido (chefe)"}} },
    { id="Picos", nome="Picos · Picos Congelados", nivel="Nv. 20+", monstros={{id="Lanceiro",nome="Lanceiro Congelado"},{id="RainhaTormenta",nome="Rainha da Tormenta (chefe)"}} },
    { id="Vulcao", nome="Vulcão · Vulcão Sinan", nivel="Nv. 26+", monstros={{id="Reptil",nome="Réptil Vulcânico"},{id="Colosso",nome="Colosso Acorrentado (chefe)"}} },
    { id="Abismo", nome="Abismo · Abismo Oceânico", nivel="Nv. 32+", monstros={{id="Enguia",nome="Enguia Voltaica Abissal"},{id="Leviata",nome="Leviatã das Profundezas (chefe)"}} },
    { id="Fabrica", nome="Fábrica · Complexo Mecânico", nivel="Nv. 38+", monstros={{id="Sentinela",nome="Sentinela Autômata"},{id="Predador",nome="Terror Industrial (chefe)"}} },
    { id="Eclipse", nome="Eclipse · Terras do Eclipse", nivel="Nv. 46+", monstros={{id="Cavaleiro",nome="Cavaleiro Profanado"},{id="Espadachim",nome="Espadachim do Eclipse (chefe final)"}} },
    { id="Cume", nome="Cume · Cume dos Ventos", nivel="Nv. 52+", monstros={{id="DragaoCeleste",nome="Dragão Serpentino Celestial"},{id="Garugon",nome="Garugon (chefe dragão demônio)"}} },
    { id="Catacumbas", nome="Catacumbas · Catacumbas Abissais", nivel="Nv. 56+", monstros={{id="AranhaCristal",nome="Aranha Cristalina"},{id="RainhaTeias",nome="Rainha das Teias (chefe aracne)"}} },
    { id="Pantano", nome="Pântano · Pântano Febril", nivel="Nv. 60+", monstros={{id="LouvaDeusPestilento",nome="Louva-deus Pestilento"},{id="HidraFebril",nome="Hidra Febril (chefe de três cabeças)"}} },
    { id="Cidadela", nome="Cidadela · Cidadela do Vazio", nivel="Nv. 64+", monstros={{id="EspectroVazio",nome="Espectro do Vazio"},{id="SoberanoVazio",nome="Soberano Vazio (chefe)"}} },
    { id="Selva", nome="Selva · Selva de Jade", nivel="Nv. 68+", monstros={{id="OncaJade",nome="Onça de Jade"},{id="ImperadorSimio",nome="Imperador Símio (chefe)"}} },
    { id="Biblioteca", nome="Biblioteca · Biblioteca Arcana", nivel="Nv. 72+", monstros={{id="GrimorioVivo",nome="Grimório Vivo"},{id="Arquimago",nome="Arquimago Esquecido (chefe)"}} },
    { id="Sakura", nome="Sakura · Santuário Sakura", nivel="Nv. 76+", monstros={{id="Kitsune",nome="Kitsune Espiritual"},{id="OniRubro",nome="Oni Rubro (chefe)"}} },
    { id="Circo", nome="Circo · Circo do Crepúsculo", nivel="Nv. 80+", monstros={{id="Marionete",nome="Marionete Sombria"},{id="Arlequim",nome="Arlequim (chefe)"}} },
    { id="Astral", nome="Astral · Fronteira Astral", nivel="Nv. 84+", monstros={{id="MedusaAstral",nome="Medusa Astral"},{id="TitaEstelar",nome="Titã Estelar (chefe)"}} },
    { id="Halloween", nome="Halloween · Vale Assombrado", nivel="Evento · Nv. 88+", monstros={{id="EspantalhoMaldito",nome="Espantalho Maldito"},{id="ZumbiCoveiro",nome="Zumbi Coveiro"},{id="CavaleiroSemCabeca",nome="Cavaleiro Sem Cabeça (chefe)"},{id="JackCeifador",nome="Jack, o Ceifador (chefe)"}} },
    { id="Torre", nome="Torre · Torre Infinita", nivel="Endgame · Nv. 20+", monstros={} },
}

local function obterListaBioma(bioma)
    local lista = {}
    for _, criatura in ipairs(bioma.monstros) do
        table.insert(lista, {id=criatura.id, nome=criatura.nome})
    end
    return lista
end

-- ============================================================
-- SEÇÕES EXPANSÍVEIS + ABAS DE BIOMA
-- ============================================================
local BoxFarm = secao("Farm / Biomas", 286)
local AreaTitle = Instance.new("TextLabel")
AreaTitle.Size = UDim2.new(1, -20, 0, 18)
AreaTitle.BackgroundTransparency = 1
AreaTitle.Text = "BIOMA / ÁREA"
AreaTitle.TextColor3 = C.dim
AreaTitle.TextSize = 10
AreaTitle.Font = FB
AreaTitle.TextXAlignment = Enum.TextXAlignment.Left
AreaTitle.Parent = BoxFarm

local AreaInfo = Instance.new("TextLabel")
AreaInfo.Size = UDim2.new(1, -20, 0, 18)
AreaInfo.BackgroundTransparency = 1
AreaInfo.Text = "Selecione a área para listar apenas suas criaturas."
AreaInfo.TextColor3 = C.dim
AreaInfo.TextSize = 10
AreaInfo.Font = F
AreaInfo.TextXAlignment = Enum.TextXAlignment.Left
AreaInfo.Parent = BoxFarm

local AreaTabs = Instance.new("ScrollingFrame")
AreaTabs.Size = UDim2.new(1, -16, 0, 38)
AreaTabs.BackgroundTransparency = 1
AreaTabs.BorderSizePixel = 0
AreaTabs.ScrollBarThickness = 2
AreaTabs.ScrollBarImageColor3 = C.blue
AreaTabs.ScrollingDirection = Enum.ScrollingDirection.X
AreaTabs.CanvasSize = UDim2.new(0, 0, 0, 0)
AreaTabs.AutomaticCanvasSize = Enum.AutomaticSize.X
AreaTabs.Parent = BoxFarm
local AreaTabsLayout = Instance.new("UIListLayout")
AreaTabsLayout.FillDirection = Enum.FillDirection.Horizontal
AreaTabsLayout.Padding = UDim.new(0, 6)
AreaTabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
AreaTabsLayout.Parent = AreaTabs

local MonsterHost = Instance.new("Frame")
MonsterHost.Size = UDim2.new(1, 0, 0, 44)
MonsterHost.BackgroundTransparency = 1
MonsterHost.Parent = BoxFarm

local FarmBiomeBtn, TowerFarmBtn, SLab4
local setStatus
local iniciarPortalArea

local function atualizarEstadoFarm()
    S.ativo = S.farmBiomaAtivo or S.torreFarmAtivo
    if FarmBiomeBtn then
        FarmBiomeBtn.Text = S.farmBiomaAtivo and "■  DESATIVAR FARM DO BIOMA" or "▶  ATIVAR FARM DO BIOMA"
        FarmBiomeBtn.TextColor3 = S.farmBiomaAtivo and C.red or C.green
        FarmBiomeBtn.BackgroundColor3 = S.farmBiomaAtivo and Color3.fromRGB(58, 34, 36) or C.card
    end
    if TowerFarmBtn then
        TowerFarmBtn.Text = S.torreFarmAtivo and "■  DESATIVAR FARM DA TORRE" or "▶  ATIVAR FARM DA TORRE"
        TowerFarmBtn.TextColor3 = S.torreFarmAtivo and C.red or C.purple
        TowerFarmBtn.BackgroundColor3 = S.torreFarmAtivo and Color3.fromRGB(58, 34, 36) or C.card
    end
end

local function selecionarBioma(bioma)
    S.biomaId = bioma.id
    if bioma.id == "Torre" and S.farmBiomaAtivo then
        S.farmBiomaAtivo = false
        atualizarEstadoFarm()
    elseif bioma.id ~= "Torre" and S.torreFarmAtivo then
        S.torreFarmAtivo = false
        S.torreAtivo = false
        atualizarEstadoFarm()
    end
    AreaInfo.Text = bioma.nome .. "  ·  " .. bioma.nivel
    for _, child in ipairs(MonsterHost:GetChildren()) do child:Destroy() end

    local lista = obterListaBioma(bioma)
    if #lista == 0 then
        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1, -16, 1, 0)
        info.Position = UDim2.fromOffset(8, 0)
        info.BackgroundTransparency = 1
        info.Text = bioma.id == "Torre" and "Ondas dinâmicas · usa DadosTorre" or "Nenhuma criatura disponível nos DadosMonstros"
        info.TextColor3 = C.gold
        info.TextSize = 11
        info.Font = FM
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.Parent = MonsterHost
        return
    end

    local achouSelecionado = false
    for _, criatura in ipairs(lista) do
        if criatura.id == S.monstroId then achouSelecionado = true end
    end
    if not achouSelecionado then
        S.monstroId = lista[1].id
        S.monstroNome = lista[1].nome
    end
    dropdown(MonsterHost, "Criatura", lista, S.monstroNome, function(id, nome)
        S.monstroId = id
        S.monstroNome = nome
    end)
end

for i, bioma in ipairs(Biomas) do
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.fromOffset(116, 30)
    Tab.BackgroundColor3 = i == 1 and C.blue or C.card2
    Tab.BorderSizePixel = 0
    Tab.Text = bioma.id
    Tab.TextColor3 = C.text
    Tab.TextSize = 11
    Tab.Font = FB
    Tab.AutoButtonColor = false
    Tab.LayoutOrder = i
    Tab.Parent = AreaTabs
    corner(Tab, 8)
    stroke(Tab, C.stroke, 1)
    Tab.MouseButton1Click:Connect(function()
        for _, sibling in ipairs(AreaTabs:GetChildren()) do
            if sibling:IsA("TextButton") then sibling.BackgroundColor3 = sibling == Tab and C.blue or C.card2 end
        end
        selecionarBioma(bioma)
    end)
end
selecionarBioma(Biomas[1])

FarmBiomeBtn = botao(BoxFarm, "▶  ATIVAR FARM DO BIOMA", C.green, function()
    if S.farmBiomaAtivo then
        S.farmBiomaAtivo = false
        S.portalEmCurso = false
        atualizarEstadoFarm()
        setStatus("Farm do bioma desativado", C.dim)
        return
    end
    if S.biomaId == "Torre" then
        setStatus("Selecione um bioma para farmar", C.orange)
        return
    end
    S.torreFarmAtivo = false
    S.torreAtivo = false
    S.farmBiomaAtivo = true
    atualizarEstadoFarm()
    if S.biomaId ~= "Hub" then
        if iniciarPortalArea then
            iniciarPortalArea(S.biomaId, false)
        else
            setStatus("Preparando portal...", C.blue)
        end
    else
        S.portalEmCurso = false
        setStatus("Farm do bioma: " .. tostring(S.biomaId), C.green)
    end
end)
slider(BoxFarm, "Distância", 3, 12, S.distancia, function(v) S.distancia = v end)
local BoxMov = secao("Movimento", 108)
toggle(BoxMov, "Boost de Velocidade", S.walkBoost, function(v)
    S.walkBoost = v
    local ch = LP.Character
    if ch then
        local h = ch:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v and S.walkSpeed or walkOriginal end
    end
end)
slider(BoxMov, "WalkSpeed", 16, 250, S.walkSpeed, function(v)
    S.walkSpeed = v
    if S.walkBoost then
        local ch = LP.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = v end
        end
    end
end)

local BoxCombate = secao("Combate", 108)
toggle(BoxCombate, "Auto Ataque", S.autoAtaque, function(v) S.autoAtaque = v end)
toggle(BoxCombate, "Travar Mira", S.travarMira, function(v) S.travarMira = v end)

local BoxColeta = secao("Coleta", 108)
toggle(BoxColeta, "Auto Coletar Núcleos", S.autoColetar, function(v) S.autoColetar = v end)
slider(BoxColeta, "Raio de Coleta", 10, 200, S.raioColeta, function(v) S.raioColeta = v end)

-- Portais: viajar manualmente ou iniciar a viagem ao ativar o farm da área.
local BoxPortal = secao("Viajar para Área", 150)
local areasList = {}
for _, area in ipairs(Biomas) do
    if area.id ~= "Torre" then
        table.insert(areasList, { id = area.id, nome = area.nome })
    end
end
dropdown(BoxPortal, "Destino", areasList, Biomas[1].nome, function(id)
    S.portalAreaAtual = id
end)
botao(BoxPortal, "VIAJAR AGORA", C.blue, function()
    local destino
    for _, area in ipairs(Biomas) do
        if area.id == S.portalAreaAtual and area.id ~= "Torre" then
            destino = area
            break
        end
    end
    if not destino then
        setStatus("Destino inválido", C.red)
        return
    end
    selecionarBioma(destino)
    S.torreFarmAtivo = false
    S.torreAtivo = false
    S.farmBiomaAtivo = true
    atualizarEstadoFarm()
    if iniciarPortalArea then
        iniciarPortalArea(destino.id, true)
    else
        setStatus("Preparando sistema de portais...", C.blue)
    end
end)
toggle(BoxPortal, "Auto Entrar no Portal", S.portalAutoViajar, function(v)
    S.portalAutoViajar = v
end)

-- Torre Infinita (altura suficiente para os três controles)
local BoxTorre = secao("Torre Infinita", 200)
toggle(BoxTorre, "Auto Entrar", S.torreAutoEntrar, function(v) S.torreAutoEntrar = v end)
toggle(BoxTorre, "Auto Avançar Andar", S.torreAutoAdvance, function(v) S.torreAutoAdvance = v end)
toggle(BoxTorre, "Auto Reviver", S.torreAutoReviver, function(v) S.torreAutoReviver = v end)
TowerFarmBtn = botao(BoxTorre, "▶  ATIVAR FARM DA TORRE", C.purple, function()
    if S.torreFarmAtivo then
        S.torreFarmAtivo = false
        S.torreAtivo = false
        atualizarEstadoFarm()
        setStatus("Farm da Torre desativado", C.dim)
        return
    end
    S.farmBiomaAtivo = false
    S.biomaId = "Torre"
    S.torreAtivo = false
    S.torreFarmAtivo = true
    atualizarEstadoFarm()
    setStatus("Modo Torre · procurando entrada", C.purple)
    SLab4.Text = "Torre Infinita · aguardando servidor"
end)
atualizarEstadoFarm()

-- Status
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1, -8, 0, 86)
StatusBox.BackgroundColor3 = C.card
StatusBox.BorderSizePixel = 0
StatusBox.LayoutOrder = 100
StatusBox.Parent = Scroll
corner(StatusBox, 12)
stroke(StatusBox, C.stroke, 1)

local SDot = Instance.new("Frame")
SDot.Size = UDim2.fromOffset(8, 8)
SDot.Position = UDim2.fromOffset(16, 16)
SDot.BackgroundColor3 = C.red
SDot.BorderSizePixel = 0
SDot.Parent = StatusBox
corner(SDot, 4)

local SLab = Instance.new("TextLabel")
SLab.Size = UDim2.new(1, -40, 0, 16)
SLab.Position = UDim2.fromOffset(30, 12)
SLab.BackgroundTransparency = 1
SLab.Text = "Inativo"
SLab.TextColor3 = C.text
SLab.TextSize = 13
SLab.Font = FB
SLab.TextXAlignment = Enum.TextXAlignment.Left
SLab.Parent = StatusBox

local SLab2 = Instance.new("TextLabel")
SLab2.Size = UDim2.new(1, -32, 0, 16)
SLab2.Position = UDim2.fromOffset(16, 34)
SLab2.BackgroundTransparency = 1
SLab2.Text = "Abates: 0 · Núcleos: 0"
SLab2.TextColor3 = C.dim
SLab2.TextSize = 11
SLab2.Font = F
SLab2.TextXAlignment = Enum.TextXAlignment.Left
SLab2.Parent = StatusBox

local SLab3 = Instance.new("TextLabel")
SLab3.Size = UDim2.new(1, -32, 0, 16)
SLab3.Position = UDim2.fromOffset(16, 50)
SLab3.BackgroundTransparency = 1
SLab3.Text = "Alvo: nenhum"
SLab3.TextColor3 = C.dim
SLab3.TextSize = 11
SLab3.Font = F
SLab3.TextXAlignment = Enum.TextXAlignment.Left
SLab3.Parent = StatusBox

SLab4 = Instance.new("TextLabel")
SLab4.Size = UDim2.new(1, -32, 0, 16)
SLab4.Position = UDim2.fromOffset(16, 66)
SLab4.BackgroundTransparency = 1
SLab4.Text = ""
SLab4.TextColor3 = C.gold
SLab4.TextSize = 11
SLab4.Font = FM
SLab4.TextXAlignment = Enum.TextXAlignment.Left
SLab4.Parent = StatusBox

-- Os modos agora são controlados pelos botões dentro de cada menu.
-- Não existe mais um botão global que inicia o farm errado.

-- ============================================================
-- DRAG
-- ============================================================
local drag, ds, sp
Header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = true; ds = i.Position; sp = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - ds
        Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

-- ============================================================
-- MINIMIZAR / FECHAR
-- ============================================================
local min = false
local alturaConteudo = H

local function ajustarAlturaConteudo()
    -- O painel acompanha o conteúdo: recolher seções também remove o espaço vazio.
    local alturaDesejada = math.clamp(Scroll.AbsoluteCanvasSize.Y + 82, 230, H)
    alturaConteudo = alturaDesejada
    if not min then
        TweenService:Create(Main, TweenInfo.new(0.16, Enum.EasingStyle.Quart), {
            Size = UDim2.fromOffset(W, alturaConteudo)
        }):Play()
    end
end

Scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(ajustarAlturaConteudo)
task.defer(ajustarAlturaConteudo)

MinBtn.MouseButton1Click:Connect(function()
    min = not min
    Scroll.Visible = not min
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = UDim2.fromOffset(W, min and 54 or alturaConteudo)
    }):Play()
    MinBtn.Text = min and "+" or "−"
end)

CloseBtn.MouseButton1Click:Connect(function()
    S.ativo = false
    S.farmBiomaAtivo = false
    S.torreFarmAtivo = false
    S.torreAtivo = false
    local ch = LP.Character
    if ch then
        local h = ch:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = walkOriginal end
    end
    GUI:Destroy()
    DropGui:Destroy()
end)

-- ============================================================
-- FUNÇÕES DE JOGO
-- ============================================================
local function getChar()
    local ch = LP.Character
    if not ch or not ch:FindFirstChild("HumanoidRootPart") then return nil end
    local h = ch:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return nil end
    return ch
end

local function getArma()
    local ch = getChar()
    if not ch then return DadosArmas.Lista.Maos end
    local n = ch:GetAttribute("Arma")
    return DadosArmas.Lista[n] or DadosArmas.Lista.Maos
end

local function acharMaisProximo()
    local ch = getChar()
    if not ch then return nil end
    local pasta = workspace:FindFirstChild("Monstros")
    if not pasta then return nil end
    local mp = ch.HumanoidRootPart.Position
    local filtro = S.monstroId:lower()

    local melhor, mdist = nil, math.huge
    for _, m in ipairs(pasta:GetChildren()) do
        local h = m:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 and m:FindFirstChild("HumanoidRootPart") then
            if m.Name:lower() == filtro or m.Name:lower():find(filtro, 1, true) then
                local d = (m.HumanoidRootPart.Position - mp).Magnitude
                if d < mdist then mdist = d; melhor = m end
            end
        end
    end
    return melhor, mdist
end

local function andarAte(destino, timeout)
    local ch = getChar()
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    if S.walkBoost then hum.WalkSpeed = S.walkSpeed end
    hum:MoveTo(destino)
    local t0 = os.clock()
    local timeout = timeout or 8
    while os.clock() - t0 < timeout do
        task.wait(0.08)
        if not S.ativo then return false end
        local c = getChar()
        if not c then return false end
        if (c.HumanoidRootPart.Position - destino).Magnitude < 4 then return true end
        hum:MoveTo(destino)
    end
    return false
end

-- ============================================================
-- SISTEMA DE PORTAIS DE ÁREA
-- ============================================================
local PortalEvento = ReplicatedStorage:WaitForChild("PortalEvento", 5)
local CollectionService = game:GetService("CollectionService")
local portalAtual = nil
local portalExpira = 0
local portalAvisouChegou = false
local portalAguardandoDesde = 0

local function localizarPortalDoJogador()
    for _, obj in ipairs(CollectionService:GetTagged("PortalArea")) do
        if obj and obj.Parent and obj:GetAttribute("Dono") == LP.UserId then
            return obj
        end
    end
    return nil
end

local function obterEntradaPortal(portal)
    if not portal then return nil, nil end
    local prompt
    for _, obj in ipairs(portal:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and (obj.Name == "Entrada" or not prompt) then
            prompt = obj
            if obj.Name == "Entrada" then break end
        end
    end
    if not prompt then return nil, nil end

    local parent = prompt.Parent
    local pos
    if parent and parent:IsA("Attachment") then
        pos = parent.WorldPosition
    elseif parent and parent:IsA("BasePart") then
        pos = parent.Position
    elseif parent and parent:IsA("Model") then
        local ok, pivot = pcall(function() return parent:GetPivot().Position end)
        if ok then pos = pivot end
    end
    if not pos and portal:IsA("Model") then
        local ok, pivot = pcall(function() return portal:GetPivot().Position end)
        if ok then pos = pivot end
    elseif not pos and portal:IsA("BasePart") then
        pos = portal.Position
    end
    return prompt, pos
end

local function ativarEntradaPortal(prompt)
    if not prompt or not prompt.Parent then return false end
    if type(fireproximityprompt) == "function" then
        local ok = pcall(function()
            fireproximityprompt(prompt, math.max(prompt.HoldDuration, 0.5))
        end)
        if ok then return true end
    end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.5) + 0.1)
        prompt:InputHoldEnd()
    end)
    return ok
end

iniciarPortalArea = function(areaId, forcar)
    if not S.farmBiomaAtivo then
        S.portalEmCurso = false
        return false
    end
    if areaId == "Torre" then
        S.portalEmCurso = false
        return false
    end
    if areaId == "Hub" then
        S.portalEmCurso = false
        setStatus("Farm do Hub iniciado", C.green)
        SLab4.Text = ""
        return true
    end
    if not PortalEvento or not PortalEvento:IsA("RemoteEvent") then
        S.portalEmCurso = false
        setStatus("Erro: PortalEvento indisponível", C.red)
        SLab4.Text = "Não foi possível solicitar o portal"
        return false
    end
    if LP:GetAttribute("Liberada_" .. areaId) == false then
        S.portalEmCurso = false
        S.farmBiomaAtivo = false
        atualizarEstadoFarm()
        setStatus("Área bloqueada: " .. tostring(areaId), C.red)
        SLab4.Text = "Desbloqueie a área antes de viajar"
        return false
    end

    S.portalEmCurso = true
    S.portalAreaAtual = areaId
    portalAtual = nil
    portalExpira = 0
    portalAvisouChegou = false
    portalAguardandoDesde = 0
    setStatus("Solicitando portal para " .. tostring(areaId) .. "...", C.blue)
    SLab4.Text = "Aguardando o portal aparecer"
    local ok = pcall(function()
        PortalEvento:FireServer("Abrir", areaId)
    end)
    if not ok then
        S.portalEmCurso = false
        setStatus("Falha ao solicitar portal", C.red)
        return false
    end
    return true
end

if PortalEvento and PortalEvento:IsA("RemoteEvent") then
    PortalEvento.OnClientEvent:Connect(function(acao, areaId)
        if acao == "Aberto" then
            task.delay(0.25, function()
                local encontrado = localizarPortalDoJogador()
                if encontrado then
                    portalAtual = encontrado
                    portalExpira = encontrado:GetAttribute("ExpiraEm") or (workspace:GetServerTimeNow() + 30)
                end
            end)
            setStatus("Portal aberto: " .. tostring(areaId), C.blue)
        elseif acao == "Viajar" then
            setStatus("Entrando na área " .. tostring(areaId or S.biomaId) .. "...", C.blue)
        elseif acao == "Chegou" then
            if not areaId or areaId == S.biomaId or areaId == S.portalAreaAtual then
                S.portalEmCurso = false
                portalAtual = nil
                portalAguardandoDesde = 0
                setStatus("Chegou em " .. tostring(areaId or S.biomaId), C.green)
                SLab4.Text = "Farm iniciado em " .. tostring(areaId or S.biomaId)
            end
        elseif acao == "Erro" then
            S.portalEmCurso = false
            portalAtual = nil
            setStatus("Erro no portal: " .. tostring(areaId), C.red)
            SLab4.Text = "Verifique se a área está liberada"
        end
    end)
end

task.spawn(function()
    while GUI.Parent do
        task.wait(0.2)
        if not S.portalEmCurso or not S.farmBiomaAtivo or S.torreFarmAtivo then
            continue
        end
        if S.biomaId ~= S.portalAreaAtual then
            S.portalEmCurso = false
            portalAtual = nil
            continue
        end
        if not S.portalAutoViajar then
            setStatus("Portal aberto · entrada automática pausada", C.orange)
            SLab4.Text = "Ative Auto Entrar no Portal para continuar"
            continue
        end

        if not portalAtual or not portalAtual.Parent then
            portalAtual = localizarPortalDoJogador()
            if portalAtual then
                portalExpira = portalAtual:GetAttribute("ExpiraEm") or (workspace:GetServerTimeNow() + 30)
                -- Reinicia o cronômetro: a espera pela criação não deve contar como falha de entrada.
                portalAguardandoDesde = 0
            else
                if portalAguardandoDesde == 0 then portalAguardandoDesde = os.clock() end
                if os.clock() - portalAguardandoDesde > 28 then
                    S.portalEmCurso = false
                    setStatus("Portal não encontrado", C.red)
                    SLab4.Text = "Tente ativar o farm novamente"
                else
                    setStatus("Aguardando portal de " .. tostring(S.biomaId), C.blue)
                    SLab4.Text = "O portal pode levar alguns instantes para aparecer"
                end
                continue
            end
        end

        if portalExpira > 0 and portalExpira - workspace:GetServerTimeNow() <= 0 then
            portalAtual = nil
            portalAguardandoDesde = 0
            setStatus("Portal expirou; solicitando outro...", C.orange)
            pcall(function() PortalEvento:FireServer("Abrir", S.biomaId) end)
            continue
        end

        local prompt, pos = obterEntradaPortal(portalAtual)
        local ch = getChar()
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not prompt or not pos or not hrp then
            task.wait(0.2)
            continue
        end

        local distanciaPortal = (hrp.Position - pos).Magnitude
        if distanciaPortal > math.max(prompt.MaxActivationDistance - 1, 5) then
            setStatus("Indo até o portal...", C.blue)
            SLab4.Text = "Destino: " .. tostring(S.biomaId) .. " · " .. math.floor(distanciaPortal) .. " studs"
            andarAte(Vector3.new(pos.X, hrp.Position.Y, pos.Z), 4)
            continue
        end

        setStatus("Entrando no portal...", C.blue)
        SLab4.Text = "Ativando Entrada · " .. tostring(S.biomaId)
        if not portalAvisouChegou then
            portalAvisouChegou = true
            pcall(function() PortalEvento:FireServer("Chegou", S.biomaId) end)
        end
        ativarEntradaPortal(prompt)
        if portalAguardandoDesde == 0 then portalAguardandoDesde = os.clock() end
        if os.clock() - portalAguardandoDesde > 10 then
            S.portalEmCurso = false
            setStatus("Entrada não confirmada", C.red)
            SLab4.Text = "O servidor não confirmou a viagem"
        end
        task.wait(0.8)
    end
end)

local function atacar(alvo)
    local ch = getChar()
    if not ch or not alvo then return end
    local hrp = alvo:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if S.travarMira then pcall(function() Atacar:FireServer(alvo) end) end
    local mp = ch.HumanoidRootPart.Position
    local ap = hrp.Position
    local dir = Vector3.new(ap.X - mp.X, 0, ap.Z - mp.Z)
    if dir.Magnitude > 0.1 then
        dir = dir.Unit
        ch.HumanoidRootPart.CFrame = CFrame.lookAt(mp, mp + dir)
        pcall(function() Golpear:FireServer(dir, true, ap) end)
    end
end

-- Coleta
local function getNucleos()
    local pasta = workspace:FindFirstChild("Nucleos")
    if not pasta then return {} end
    return pasta:GetChildren()
end

local function acharNucleoPerto()
    local ch = getChar()
    if not ch then return nil end
    local mp = ch.HumanoidRootPart.Position
    local melhor, mdist = nil, math.huge
    for _, n in ipairs(getNucleos()) do
        if n:IsA("Model") and n.PrimaryPart then
            local d = (n.PrimaryPart.Position - mp).Magnitude
            if d < mdist and d <= S.raioColeta then
                mdist = d; melhor = n
            end
        end
    end
    return melhor, mdist
end

local function getPromptNucleo(nucleo)
    for _, d in ipairs(nucleo:GetDescendants()) do
        if d:IsA("ProximityPrompt") then return d end
    end
    return nil
end

local function coletarNucleo(nucleo)
    if not nucleo or not nucleo.Parent then return false end
    local prompt = getPromptNucleo(nucleo)
    if not prompt then return false end
    if fireproximityprompt then
        local ok = pcall(function() fireproximityprompt(prompt) end)
        if ok then return true end
    end
    local ok = pcall(function()
        prompt:InputHoldBegin()
        task.wait(math.max(prompt.HoldDuration, 0.1) + 0.05)
        prompt:InputHoldEnd()
    end)
    return ok
end

-- ============================================================
-- LOOP
-- ============================================================
setStatus = function(texto, cor)
    SLab.Text = texto
    SLab.TextColor3 = cor or C.text
end

local ultimoAtaque = 0
local alvoAtual = nil

spawn(function()
    while GUI.Parent do
        task.wait(0.05)
        if not S.farmBiomaAtivo then alvoAtual = nil; S.alvoAtual = "nenhum"; continue end
        if S.portalEmCurso then
            alvoAtual = nil
            S.alvoAtual = "viajando para " .. tostring(S.biomaId)
            task.wait(0.12)
            continue
        end
        -- No modo Torre, o loop de farm comum não pode disputar movimento/alvo.
        if S.torreFarmAtivo or S.biomaId == "Torre" then
            alvoAtual = nil
            task.wait(0.15)
            continue
        end
        local ch = getChar()
        if not ch then setStatus("Sem personagem", C.orange); task.wait(0.5); continue end

        -- Coleta
        if S.autoColetar then
            local n, dn = acharNucleoPerto()
            if n and dn then
                setStatus("Coletando núcleo...", C.gold)
                SLab4.Text = "→ " .. n.Name
                local ok = coletarNucleo(n)
                task.wait(0.15)
                if ok and not n.Parent then
                    S.coletados = S.coletados + 1
                    SLab4.Text = "✔ " .. n.Name
                elseif not ok then
                    local pos = n.PrimaryPart and n.PrimaryPart.Position or n:GetPivot().Position
                    andarAte(pos, 3)
                    coletarNucleo(n)
                end
                task.wait(0.1)
                continue
            end
        end

        -- Ataque
        if alvoAtual then
            local h = alvoAtual:FindFirstChildOfClass("Humanoid")
            if not h or h.Health <= 0 or not alvoAtual.Parent then
                S.abates = S.abates + 1
                alvoAtual = nil
                S.alvoAtual = "nenhum"
                task.wait(0.15)
                continue
            end
        else
            alvoAtual = acharMaisProximo()
            if not alvoAtual then
                setStatus("Procurando " .. S.monstroNome .. "...", C.orange)
                S.alvoAtual = "nenhum"
                task.wait(0.5)
                continue
            end
        end

        local hrp = alvoAtual:FindFirstChild("HumanoidRootPart")
        if not hrp then alvoAtual = nil; continue end
        local mp = ch.HumanoidRootPart.Position
        local ap = hrp.Position
        local dist = (ap - mp).Magnitude
        S.alvoAtual = alvoAtual.Name
        setStatus("Farmando: " .. alvoAtual.Name, C.green)
        SLab4.Text = ""

        if dist > S.distancia + 1 then
            local offset = (mp - ap)
            if offset.Magnitude > 0.1 then offset = offset.Unit end
            andarAte(ap + offset * S.distancia, 6)
        else
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then hum:MoveTo(mp) end
            local arma = getArma()
            local cd = math.max(arma.Cooldown or 0.6, 0.5) + 0.06
            if S.autoAtaque and os.clock() - ultimoAtaque >= cd then
                atacar(alvoAtual)
                ultimoAtaque = os.clock()
            end
        end
    end
end)

spawn(function()
    while GUI.Parent do
        task.wait(0.3)
        SLab2.Text = string.format("Abates: %d · Núcleos: %d", S.abates, S.coletados)
        SLab3.Text = "Alvo: " .. S.alvoAtual
    end
end)

-- Estado visual do indicador, independente do modo selecionado.
task.spawn(function()
    while GUI.Parent do
        task.wait(0.2)
        SDot.BackgroundColor3 = S.ativo and C.green or C.red
        if not S.ativo then
            local ch = LP.Character
            if ch then
                local h = ch:FindFirstChildOfClass("Humanoid")
                if h and h.WalkSpeed ~= walkOriginal then h.WalkSpeed = walkOriginal end
            end
        end
    end
end)

LP:GetAttributeChangedSignal("NaTorre"):Connect(function()
    if LP:GetAttribute("NaTorre") == true then
        if S.torreFarmAtivo then
            S.torreAtivo = true
            setStatus("Torre detectada!", C.purple)
        end
    else
        if S.torreFarmAtivo then
            S.torreAtivo = false
            setStatus("Saiu da torre", C.dim)
        end
    end
end)

LP.CharacterAdded:Connect(function(ch)
    task.wait(1)
    local h = ch:FindFirstChildOfClass("Humanoid")
    if h and S.ativo and S.walkBoost then h.WalkSpeed = S.walkSpeed end
end)

-- ============================================================
-- ============================================================
-- SISTEMA DE TORRE INFINITA (via remote TorreEvento)
-- ============================================================
local TorreEvento = ReplicatedStorage:WaitForChild("TorreEvento", 5)

-- Escuta os estados enviados pelo servidor da torre.
if TorreEvento and TorreEvento:IsA("RemoteEvent") then
    TorreEvento.OnClientEvent:Connect(function(acao, dados)
        if acao == "Andar" and type(dados) == "table" then
            S.torreAtivo = true
            S.torreAndar = dados.Andar or 0
            local tipo = dados.Chefe and "CHEFE" or (dados.Elite and "ELITE" or "normal")
            setStatus("Torre A" .. S.torreAndar .. " [" .. tipo .. "]", C.purple)
            SLab4.Text = "Andar " .. S.torreAndar .. " · " .. tipo

        elseif acao == "Restantes" then
            -- Evento de estado recebido; o servidor continua sendo a fonte da verdade.
            if S.torreAtivo and type(dados) == "table" and dados.Quantidade ~= nil then
                SLab4.Text = "Andar " .. S.torreAndar .. " · Restantes: " .. tostring(dados.Quantidade)
            end

        elseif acao == "Intervalo" then
            if S.torreAutoAdvance and S.torreFarmAtivo then
                task.wait(0.4)
                pcall(function() TorreEvento:FireServer("Continuar") end)
                setStatus("Avançando...", C.gold)
            end

        elseif acao == "Morreu" then
            if S.torreAutoReviver and S.torreFarmAtivo and type(dados) == "table" and dados.PodeReviver then
                task.wait(0.8)
                pcall(function() TorreEvento:FireServer("Reviver") end)
                setStatus("Revivendo...", C.orange)
            else
                task.wait(0.5)
                pcall(function() TorreEvento:FireServer("Desistir") end)
                setStatus("Desistindo...", C.red)
            end

        elseif acao == "Fim" then
            S.torreAndar = 0
            S.torreAtivo = false
            setStatus("Run acabou. Reentrando...", C.gold)
            task.wait(3)
            if S.torreFarmAtivo and S.biomaId == "Torre" and S.torreAutoEntrar then
                pcall(function() TorreEvento:FireServer("Abrir") end)
                task.wait(0.3)
                pcall(function() TorreEvento:FireServer("Entrar") end)
            end

        elseif acao == "Revivido" then
            S.torreAtivo = true
            setStatus("Revivido! Continuando...", C.green)
        end
    end)
end

local function estaNaTorre()
    return LP:GetAttribute("NaTorre") == true
end

-- Procura a entrada da Torre em todo o mapa, não apenas num raio de 30 studs.
-- Escolhe o prompt "Torre" mais próximo para poder caminhar até ele desde longe.
local function acharPromptTorre()
    local ch = getChar()
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local mp = hrp.Position
    local melhorPrompt, melhorPos, menorDist = nil, nil, math.huge

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Name == "Torre" and obj.Enabled then
            local parent = obj.Parent
            local pos
            if parent and parent:IsA("Attachment") then
                pos = parent.WorldPosition
            elseif parent and parent:IsA("BasePart") then
                pos = parent.Position
            elseif parent and parent:IsA("Model") then
                local ok, pivot = pcall(function() return parent:GetPivot().Position end)
                if ok then pos = pivot end
            end
            if pos then
                local dist = (pos - mp).Magnitude
                if dist < menorDist then
                    menorDist = dist
                    melhorPrompt = obj
                    melhorPos = pos
                end
            end
        end
    end

    return melhorPrompt, melhorPos, menorDist
end

local function acharMonstroTorre()
    local ch = getChar()
    local hrpPlayer = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrpPlayer then return nil end
    local mp = hrpPlayer.Position
    local pasta = workspace:FindFirstChild("Monstros")
    if not pasta then return nil end

    local melhor, mdist = nil, math.huge
    for _, m in ipairs(pasta:GetChildren()) do
        if m ~= ch then
            local h = m:FindFirstChildOfClass("Humanoid")
            local hrp = m:FindFirstChild("HumanoidRootPart")
            if h and h.Health > 0 and hrp then
                local d = (hrp.Position - mp).Magnitude
                if d < mdist and d < 250 then
                    melhor, mdist = m, d
                end
            end
        end
    end
    return melhor, mdist
end

-- Loop da Torre: o combate reutiliza as funções já existentes.
task.spawn(function()
    while GUI.Parent do
        task.wait(0.12)
        if not S.torreFarmAtivo or S.biomaId ~= "Torre" then
            continue
        end
        if not TorreEvento or not TorreEvento:IsA("RemoteEvent") then
            setStatus("Erro: TorreEvento indisponível", C.red)
            SLab4.Text = "Não é possível entrar na Torre"
            task.wait(1)
            continue
        end

        -- O atributo pode mudar entre eventos; sincroniza sem depender só do botão.
        if estaNaTorre() then
            S.torreAtivo = true
        end

        if estaNaTorre() then
            local ch = getChar()
            local hrpPlayer = ch and ch:FindFirstChild("HumanoidRootPart")
            if not hrpPlayer then continue end

            local alvo = acharMonstroTorre()
            if alvo then
                local hrp = alvo:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local mp, ap = hrpPlayer.Position, hrp.Position
                    local d = (ap - mp).Magnitude
                    S.alvoAtual = "[Torre] " .. alvo.Name
                    SLab4.Text = "Andar " .. S.torreAndar .. " · " .. alvo.Name

                    if d > S.distancia + 1 then
                        local offset = mp - ap
                        if offset.Magnitude > 0.1 then offset = offset.Unit end
                        andarAte(ap + offset * S.distancia, 3)
                    else
                        local hum = ch:FindFirstChildOfClass("Humanoid")
                        if hum then hum:MoveTo(mp) end
                        local arma = getArma()
                        local cooldown = math.max((arma and arma.Cooldown) or 0.6, 0.5) + 0.05
                        if S.autoAtaque and os.clock() - ultimoAtaque >= cooldown then
                            atacar(alvo)
                            ultimoAtaque = os.clock()
                        end
                    end
                end
            else
                SLab4.Text = "Andar " .. S.torreAndar .. " · aguardando..."
            end
        elseif S.torreAtivo then
            -- Já estava no modo Torre, mas o servidor informa que saiu.
            S.torreAtivo = false
        else
            -- Aba Torre selecionada: tenta o protocolo do servidor, sem fallback para Slime.
            if S.torreAutoEntrar then
                local prompt, pos, distanciaTorre = acharPromptTorre()
                local ch = getChar()
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")

                -- O centro da zona vem de DadosAreas.Lista.Torre.Centro.
                -- Se não existir ProximityPrompt no mapa, usa as coordenadas conhecidas.
                if not pos then
                    pos = Vector3.new(0, 0, 5000)
                    if hrp then
                        distanciaTorre = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - pos).Magnitude
                    end
                end

                if hrp and pos and distanciaTorre and distanciaTorre > 10 then
                    setStatus("Indo até a Torre Infinita...", C.orange)
                    SLab4.Text = (prompt and "Entrada localizada · " or "Indo para a zona · ") .. math.floor(distanciaTorre) .. " studs"
                    -- Igual ao farm do Hub: MoveTo em trechos curtos, recalculando até o destino.
                    andarAte(Vector3.new(pos.X, hrp.Position.Y, pos.Z), 4)
                    task.wait(0.15)
                    continue
                end

                setStatus("Chegou à Torre · solicitando entrada...", C.purple)
                SLab4.Text = "Abrir → Entrar · aguardando confirmação"
                pcall(function() TorreEvento:FireServer("Abrir") end)
                task.wait(0.45)
                if LP:GetAttribute("NaTorre") ~= true then
                    pcall(function() TorreEvento:FireServer("Entrar") end)
                end
                task.wait(2.5)
            else
                setStatus("Auto Entrar desativado", C.orange)
                SLab4.Text = "Ative Auto Entrar para iniciar a Torre"
                task.wait(0.5)
            end
        end
    end
end)

print("[DexFarm v5.5] Carregado!")
