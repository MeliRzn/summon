-- ============================================================
-- DEX FARM v5.1 — Bugs corrigidos
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
}
local F  = Enum.Font.Gotham
local FB = Enum.Font.GothamBold
local FM = Enum.Font.GothamMedium

local S = {
    ativo = false,
    autoAtaque = true,
    travarMira = true,
    teleporte = true,
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
local W, H = 420, 540

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
Sub.Text = "v5.1 · farm + coleta"
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
    Holder.Size = UDim2.new(1, -8, 0, altura + 22)
    Holder.BackgroundTransparency = 1
    Holder.Parent = Scroll

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 16)
    Label.BackgroundTransparency = 1
    Label.Text = titulo:upper()
    Label.TextColor3 = C.dim
    Label.TextSize = 11
    Label.Font = FB
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Holder
    local lp = Instance.new("UIPadding")
    lp.PaddingLeft = UDim.new(0, 8)
    lp.Parent = Label

    local Box = Instance.new("Frame")
    Box.Size = UDim2.new(1, 0, 0, altura)
    Box.Position = UDim2.fromOffset(0, 22)
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
-- LISTA DE MONSTROS
-- ============================================================
local monstrosList = {}
for id, d in pairs(DadosMonstros) do
    if type(d) == "table" and d.Nome then
        table.insert(monstrosList, { id = id, nome = d.Nome })
    end
end
table.sort(monstrosList, function(a, b) return a.nome < b.nome end)

-- ============================================================
-- SEÇÕES
-- ============================================================
local BoxFarm = secao("Farm", 150)
dropdown(BoxFarm, "Monstro", monstrosList, S.monstroNome, function(id, nome)
    S.monstroId = id
    S.monstroNome = nome
end)
slider(BoxFarm, "Distância", 3, 12, S.distancia, function(v) S.distancia = v end)
toggle(BoxFarm, "Auto Teleporte", S.teleporte, function(v) S.teleporte = v end)

local BoxMov = secao("Movimento", 92)
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

local BoxCombate = secao("Combate", 92)
toggle(BoxCombate, "Auto Ataque", S.autoAtaque, function(v) S.autoAtaque = v end)
toggle(BoxCombate, "Travar Mira", S.travarMira, function(v) S.travarMira = v end)

local BoxColeta = secao("Coleta", 92)
toggle(BoxColeta, "Auto Coletar Núcleos", S.autoColetar, function(v) S.autoColetar = v end)
slider(BoxColeta, "Raio de Coleta", 10, 200, S.raioColeta, function(v) S.raioColeta = v end)

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

local SLab4 = Instance.new("TextLabel")
SLab4.Size = UDim2.new(1, -32, 0, 16)
SLab4.Position = UDim2.fromOffset(16, 66)
SLab4.BackgroundTransparency = 1
SLab4.Text = ""
SLab4.TextColor3 = C.gold
SLab4.TextSize = 11
SLab4.Font = FM
SLab4.TextXAlignment = Enum.TextXAlignment.Left
SLab4.Parent = StatusBox

local StartBtn = botao(Scroll, "▶  INICIAR FARM", C.green)
StartBtn.LayoutOrder = 200

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
MinBtn.MouseButton1Click:Connect(function()
    min = not min
    Scroll.Visible = not min
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = min and UDim2.fromOffset(W, 54) or UDim2.fromOffset(W, H)
    }):Play()
    MinBtn.Text = min and "+" or "—"
end)

CloseBtn.MouseButton1Click:Connect(function()
    S.ativo = false
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
local function setStatus(texto, cor)
    SLab.Text = texto
    SLab.TextColor3 = cor or C.text
end

local ultimoAtaque = 0
local alvoAtual = nil

spawn(function()
    while GUI.Parent do
        task.wait(0.05)
        if not S.ativo then alvoAtual = nil; S.alvoAtual = "nenhum"; continue end
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

StartBtn.MouseButton1Click:Connect(function()
    S.ativo = not S.ativo
    if S.ativo then
        StartBtn.Text = "■  PARAR FARM"
        StartBtn.TextColor3 = C.red
        SDot.BackgroundColor3 = C.green
        setStatus("Iniciando...", C.green)
        S.abates = 0; S.coletados = 0
        alvoAtual = nil
        local ch = LP.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then walkOriginal = h.WalkSpeed end
        end
    else
        StartBtn.Text = "▶  INICIAR FARM"
        StartBtn.TextColor3 = C.green
        SDot.BackgroundColor3 = C.red
        setStatus("Inativo", C.text)
        SLab4.Text = ""
        local ch = LP.Character
        if ch then
            local h = ch:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = walkOriginal end
        end
    end
end)

LP.CharacterAdded:Connect(function(ch)
    task.wait(1)
    local h = ch:FindFirstChildOfClass("Humanoid")
    if h and S.ativo and S.walkBoost then h.WalkSpeed = S.walkSpeed end
end)

print("[DexFarm v5.1] Carregado!")
