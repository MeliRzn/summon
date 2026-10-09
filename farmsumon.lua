-- ============================================================
-- DEX FARM v5.9 — interface Obsidian UI Library
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Golpear = ReplicatedStorage:WaitForChild("Golpear")
local Atacar = ReplicatedStorage:WaitForChild("Atacar")
local DadosArmas = require(ReplicatedStorage:WaitForChild("DadosArmas"))
local DadosMonstros = require(ReplicatedStorage:WaitForChild("DadosMonstros"))

-- Cores semânticas usadas pelos avisos de estado; a aparência dos controles
-- pertence integralmente ao tema da biblioteca Obsidian.
local C = {
    text = Color3.fromRGB(241, 245, 249),
    dim = Color3.fromRGB(148, 163, 184),
    blue = Color3.fromRGB(96, 165, 250),
    green = Color3.fromRGB(74, 222, 128),
    red = Color3.fromRGB(248, 113, 113),
    orange = Color3.fromRGB(251, 146, 60),
    gold = Color3.fromRGB(250, 204, 21),
    purple = Color3.fromRGB(192, 132, 252),
}

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
    autoEquipar = true,
    autoLimpar = true,
    autoVenderAte = true,
    autoEvoluir = false,
    autoCraftMelhores = true,
    ultimoPedidoCraft = 0,
    craftPlanejamentoPendente = false,
    craftEmCurso = false,
    intervaloInv = 45,
    raridadeVender = 2,
    ultimoInv = 0,
    moedasVendidas = 0,
    itensVendidos = 0,
    equipamentos = 0,
    portalAreaAtual = "Hub",
    portalAutoViajar = true,
    portalEmCurso = false,
    movimentoToken = 0,
    torreAtivo = false,
    torreAutoEntrar = true,
    torreAutoAdvance = true,
    torreAutoReviver = true,
    torreAndar = 0,
}

local walkOriginal = 16
local equiparMelhores, limparRepetidos, venderAte, sincronizarInv
local setStatus
local iniciarPortalArea
local selecionarBioma
local atualizarEstadoFarm
local SLab, SLab2, SLab3, SLab4
local StatMoedas, StatItens, StatEquip
local GUI
local FarmBiomeToggle, TowerFarmToggle
local sincronizandoToggles = false
local sincronizandoArea = false
local sincronizandoCriatura = false

-- A biblioteca e o tema são carregados da fonte oficial do projeto Obsidian.
-- Falha de rede/carregamento encerra com uma mensagem clara em vez de deixar
-- meia interface antiga e meia interface nova na tela.
local repoObsidian = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local okLibrary, LibraryOrError = pcall(function()
    local source = game:HttpGet(repoObsidian .. "Library.lua")
    local loader = loadstring(source)
    assert(loader, "loadstring não está disponível neste ambiente")
    return loader()
end)
if not okLibrary or type(LibraryOrError) ~= "table" then
    warn("[DexFarm] Não foi possível carregar a Obsidian UI Library: " .. tostring(LibraryOrError))
    return
end
local Library = LibraryOrError

local okTheme, ThemeManagerOrError = pcall(function()
    local source = game:HttpGet(repoObsidian .. "addons/ThemeManager.lua")
    local loader = loadstring(source)
    assert(loader, "não foi possível preparar o ThemeManager")
    return loader()
end)
local ThemeManager = okTheme and ThemeManagerOrError or nil
if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:SetFolder("DexFarm")
    pcall(function()
        ThemeManager:ApplyTheme("Catppuccin")
    end)
else
    warn("[DexFarm] ThemeManager indisponível; a interface usará o tema padrão da Obsidian.")
end

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true
Library.NotifyOnError = true

local Window = Library:CreateWindow({
    Title = "DEX FARM",
    Footer = "v5.9 • Obsidian UI",
    Icon = 95816097006870,
    Center = true,
    AutoShow = true,
    Resizable = true,
    ToggleKeybind = Enum.KeyCode.RightControl,
    NotifySide = "Right",
    ShowCustomCursor = false,
    AlwaysOnTop = true,
    ShowMobileButtons = true,
    MobileButtonsSide = "Right",
    Size = UDim2.fromOffset(650, 520),
})

GUI = Library.ScreenGui
if not GUI then
    pcall(function() Library:Unload() end)
    warn("[DexFarm] A Obsidian não criou sua ScreenGui; execução interrompida.")
    return
end

local Tabs = {
    Farm = Window:AddTab("Farm", "target"),
    Movimento = Window:AddTab("Movimento", "move"),
    Inventario = Window:AddTab("Inventário", "backpack"),
    Torre = Window:AddTab("Torre", "layers"),
    Config = Window:AddTab("Configurações", "settings"),
}

if ThemeManager then
    pcall(function()
        ThemeManager:ApplyToTab(Tabs.Config)
        ThemeManager:ApplyTheme("Catppuccin")
    end)
end

local FarmBox = Tabs.Farm:AddLeftGroupbox("Farm por bioma", "map")
local FarmStatusBox = Tabs.Farm:AddRightGroupbox("Estado atual", "activity")
local CombatBox = Tabs.Farm:AddRightGroupbox("Combate e coleta", "swords")
local MovementBox = Tabs.Movimento:AddLeftGroupbox("Movimento", "move")
local InventoryBox = Tabs.Inventario:AddLeftGroupbox("Automação do inventário", "package")
local EconomyBox = Tabs.Inventario:AddRightGroupbox("Estatísticas", "chart-no-axes-combined")
local InventoryActionsBox = Tabs.Inventario:AddRightGroupbox("Ações rápidas", "zap")
local PortalBox = Tabs.Movimento:AddRightGroupbox("Viajar para área", "map-pin")
local TowerBox = Tabs.Torre:AddLeftGroupbox("Torre infinita", "layers")
local TowerStatusBox = Tabs.Torre:AddRightGroupbox("Status da torre", "activity")
local ConfigBox = Tabs.Config:AddLeftGroupbox("Controles da interface", "sliders-horizontal")

local AreaInfo = FarmBox:AddLabel({
    Text = "Selecione uma área para ver suas criaturas.",
    DoesWrap = true,
})
local CreatureInfo = FarmBox:AddLabel({
    Text = "A lista de criaturas acompanha o bioma selecionado.",
    DoesWrap = true,
})
local AreaDropdown
local MonsterDropdown
local PortalDropdown

SLab = FarmStatusBox:AddLabel({ Text = "● Inativo", DoesWrap = true })
SLab2 = FarmStatusBox:AddLabel({ Text = "Abates: 0 · Núcleos: 0", DoesWrap = true })
SLab3 = FarmStatusBox:AddLabel({ Text = "Alvo: nenhum", DoesWrap = true })
SLab4 = FarmStatusBox:AddLabel({ Text = "Pronto.", DoesWrap = true })

local TowerStatusLabel = TowerStatusBox:AddLabel({
    Text = "Aguardando ativação da Torre.",
    DoesWrap = true,
})

StatMoedas = EconomyBox:AddLabel("Moedas ganhas: 0", false)
StatItens = EconomyBox:AddLabel("Itens vendidos: 0", false)
StatEquip = EconomyBox:AddLabel("Equipamentos trocados: 0", false)

local function aviso(texto, duracao)
    pcall(function()
        Library:Notify({
            Title = "DEX FARM",
            Description = tostring(texto),
            Time = duracao or 3,
        })
    end)
end

local function atualizarTextoTorre(texto)
    TowerStatusLabel:SetText(tostring(texto or ""))
end
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
-- INTERFACE OBSIDIAN: controles conectados à lógica existente
-- ============================================================

local function mapaBiomas()
    local valores = {}
    for _, bioma in ipairs(Biomas) do
        valores[bioma.id] = bioma.nome
    end
    return valores
end

local function mapaAreasDeViagem()
    local valores = {}
    for _, area in ipairs(Biomas) do
        if area.id ~= "Torre" then
            valores[area.id] = area.nome
        end
    end
    return valores
end

AreaDropdown = FarmBox:AddDropdown("DexFarmBioma", {
    Text = "Bioma / área",
    Values = mapaBiomas(),
    Default = "Hub",
    Searchable = true,
    Callback = function(id)
        if sincronizandoArea then return end
        for _, bioma in ipairs(Biomas) do
            if bioma.id == id then
                if selecionarBioma then selecionarBioma(bioma) end
                break
            end
        end
    end,
})

MonsterDropdown = FarmBox:AddDropdown("DexFarmCriatura", {
    Text = "Criatura-alvo",
    Values = { Slime = "Slime Musgoso" },
    Default = "Slime",
    Searchable = true,
    Callback = function(id)
        if sincronizandoCriatura then return end
        if not id then return end
        S.monstroId = id
        local bioma = nil
        for _, area in ipairs(Biomas) do
            if area.id == S.biomaId then bioma = area break end
        end
        if bioma then
            for _, criatura in ipairs(bioma.monstros) do
                if criatura.id == id then
                    S.monstroNome = criatura.nome
                    break
                end
            end
        end
    end,
})

FarmBox:AddSlider("DexFarmDistancia", {
    Text = "Distância do alvo",
    Default = S.distancia,
    Min = 3,
    Max = 12,
    Rounding = 0,
    Callback = function(v) S.distancia = v end,
})

FarmBiomeToggle = FarmBox:AddToggle("DexFarmAtivo", {
    Text = "Ativar farm do bioma",
    Default = false,
    Callback = function(ativado)
        if sincronizandoToggles then return end
        if ativado then
            if S.biomaId == "Torre" then
                sincronizandoToggles = true
                FarmBiomeToggle:SetValue(false)
                sincronizandoToggles = false
                aviso("Selecione um bioma normal para usar este modo.")
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
        else
            S.farmBiomaAtivo = false
            S.portalEmCurso = false
            atualizarEstadoFarm()
            setStatus("Farm do bioma desativado", C.dim)
        end
    end,
})

MovementBox:AddToggle("DexFarmBoost", {
    Text = "Boost de velocidade",
    Default = S.walkBoost,
    Callback = function(v)
        S.walkBoost = v
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and S.walkSpeed or walkOriginal end
    end,
})
MovementBox:AddSlider("DexFarmWalkSpeed", {
    Text = "WalkSpeed",
    Default = S.walkSpeed,
    Min = 16,
    Max = 250,
    Rounding = 0,
    Callback = function(v)
        S.walkSpeed = v
        if S.walkBoost then
            local ch = LP.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

CombatBox:AddToggle("DexFarmAutoAtaque", {
    Text = "Auto ataque",
    Default = S.autoAtaque,
    Callback = function(v) S.autoAtaque = v end,
})
CombatBox:AddToggle("DexFarmTravarMira", {
    Text = "Travar mira",
    Default = S.travarMira,
    Callback = function(v) S.travarMira = v end,
})
CombatBox:AddToggle("DexFarmAutoColetar", {
    Text = "Auto coletar núcleos",
    Default = S.autoColetar,
    Callback = function(v) S.autoColetar = v end,
})
CombatBox:AddSlider("DexFarmRaioColeta", {
    Text = "Raio de coleta",
    Default = S.raioColeta,
    Min = 10,
    Max = 200,
    Rounding = 0,
    Suffix = " studs",
    Callback = function(v) S.raioColeta = v end,
})

InventoryBox:AddToggle("DexFarmAutoEquipar", {
    Text = "Auto equipar melhores",
    Default = S.autoEquipar,
    Callback = function(v) S.autoEquipar = v end,
})
InventoryBox:AddToggle("DexFarmAutoLimpar", {
    Text = "Auto limpar repetidos",
    Default = S.autoLimpar,
    Callback = function(v) S.autoLimpar = v end,
})
InventoryBox:AddToggle("DexFarmAutoVender", {
    Text = "Auto vender itens ruins",
    Default = S.autoVenderAte,
    Callback = function(v) S.autoVenderAte = v end,
})
InventoryBox:AddToggle("DexFarmAutoEvoluir", {
    Text = "Auto evoluir iguais",
    Default = S.autoEvoluir,
    Callback = function(v) S.autoEvoluir = v end,
})
InventoryBox:AddToggle("DexFarmAutoCraftMelhores", {
    Text = "Auto craftar só melhorias",
    Default = S.autoCraftMelhores,
    Callback = function(v) S.autoCraftMelhores = v end,
})
InventoryBox:AddSlider("DexFarmIntervaloInv", {
    Text = "Intervalo do inventário",
    Default = S.intervaloInv,
    Min = 15,
    Max = 180,
    Rounding = 0,
    Suffix = " s",
    Callback = function(v) S.intervaloInv = math.floor(v + 0.5) end,
})
InventoryBox:AddDropdown("DexFarmRaridadeVender", {
    Text = "Limite de raridade para venda",
    Values = {
        [1] = "Só Básicos",
        [2] = "Até Raros",
        [3] = "Até Épicos",
    },
    Default = 2,
    Callback = function(id) S.raridadeVender = tonumber(id) or 2 end,
})

InventoryActionsBox:AddButton({
    Text = "Equipar melhores agora",
    Func = function()
        if equiparMelhores then equiparMelhores() end
        task.wait(1.2)
        if sincronizarInv then sincronizarInv() end
    end,
})
InventoryActionsBox:AddButton({
    Text = "Limpar repetidos",
    Func = function()
        if limparRepetidos then limparRepetidos() end
        task.wait(1.2)
        if sincronizarInv then sincronizarInv() end
    end,
})
InventoryActionsBox:AddButton({
    Text = "Vender itens ruins",
    Func = function()
        if venderAte then venderAte(S.raridadeVender) end
        task.wait(1.2)
        if sincronizarInv then sincronizarInv() end
    end,
})

PortalDropdown = PortalBox:AddDropdown("DexFarmDestino", {
    Text = "Destino",
    Values = mapaAreasDeViagem(),
    Default = "Hub",
    Searchable = true,
    Callback = function(id)
        if id then S.portalAreaAtual = id end
    end,
})
PortalBox:AddButton({
    Text = "Viajar agora e iniciar farm",
    Func = function()
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
        if selecionarBioma then selecionarBioma(destino, true) end
        S.torreFarmAtivo = false
        S.torreAtivo = false
        S.farmBiomaAtivo = true
        atualizarEstadoFarm()
        if iniciarPortalArea then
            iniciarPortalArea(destino.id, true)
        else
            setStatus("Preparando sistema de portais...", C.blue)
        end
    end,
})
PortalBox:AddToggle("DexFarmAutoPortal", {
    Text = "Auto entrar no portal",
    Default = S.portalAutoViajar,
    Callback = function(v) S.portalAutoViajar = v end,
})

TowerBox:AddToggle("DexFarmTorreAutoEntrar", {
    Text = "Auto entrar",
    Default = S.torreAutoEntrar,
    Callback = function(v) S.torreAutoEntrar = v end,
})
TowerBox:AddToggle("DexFarmTorreAutoAdvance", {
    Text = "Auto avançar andar",
    Default = S.torreAutoAdvance,
    Callback = function(v) S.torreAutoAdvance = v end,
})
TowerBox:AddToggle("DexFarmTorreAutoReviver", {
    Text = "Auto reviver",
    Default = S.torreAutoReviver,
    Callback = function(v) S.torreAutoReviver = v end,
})
TowerFarmToggle = TowerBox:AddToggle("DexFarmTorreAtiva", {
    Text = "Ativar farm da Torre",
    Default = false,
    Callback = function(ativado)
        if sincronizandoToggles then return end
        if ativado then
            S.farmBiomaAtivo = false
            S.biomaId = "Torre"
            S.torreAtivo = false
            S.torreFarmAtivo = true
            atualizarEstadoFarm()
            setStatus("Modo Torre · procurando entrada", C.purple)
            SLab4:SetText("Torre Infinita · aguardando servidor")
            atualizarTextoTorre("Torre Infinita · aguardando servidor")
        else
            S.torreFarmAtivo = false
            S.torreAtivo = false
            atualizarEstadoFarm()
            setStatus("Farm da Torre desativado", C.dim)
        end
    end,
})

ConfigBox:AddLabel({
    Text = "Interface fornecida pela Obsidian UI Library. Use RightControl no PC para alternar a janela.",
    DoesWrap = true,
})
ConfigBox:AddButton({
    Text = "Descarregar interface",
    Func = function()
        pcall(function() Library:Unload() end)
    end,
})

setStatus = function(texto, cor)
    local r, g, b = 241, 245, 249
    if typeof(cor) == "Color3" then
        r, g, b = math.floor(cor.R * 255), math.floor(cor.G * 255), math.floor(cor.B * 255)
    end
    SLab:SetText(string.format('<font color="rgb(%d,%d,%d)">●</font> %s', r, g, b, tostring(texto)))
end

atualizarEstadoFarm = function()
    S.ativo = S.farmBiomaAtivo or S.torreFarmAtivo
    sincronizandoToggles = true
    if FarmBiomeToggle and FarmBiomeToggle.Value ~= S.farmBiomaAtivo then
        FarmBiomeToggle:SetValue(S.farmBiomaAtivo)
    end
    if TowerFarmToggle and TowerFarmToggle.Value ~= S.torreFarmAtivo then
        TowerFarmToggle:SetValue(S.torreFarmAtivo)
    end
    sincronizandoToggles = false

    if not S.ativo then
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = walkOriginal end
    end
end

selecionarBioma = function(bioma, suprimirViagem)
    local biomaAnterior = S.biomaId
    S.biomaId = bioma.id

    if bioma.id == "Torre" and S.farmBiomaAtivo then
        S.farmBiomaAtivo = false
        S.portalEmCurso = false
        atualizarEstadoFarm()
    elseif bioma.id ~= "Torre" and S.torreFarmAtivo then
        S.torreFarmAtivo = false
        S.torreAtivo = false
        atualizarEstadoFarm()
    end

    sincronizandoArea = true
    if AreaDropdown then AreaDropdown:SetValue(bioma.id) end
    sincronizandoArea = false
    AreaInfo:SetText(bioma.nome .. " · " .. bioma.nivel)

    local lista = obterListaBioma(bioma)
    if #lista == 0 then
        MonsterDropdown:SetVisible(false)
        CreatureInfo:SetText(bioma.id == "Torre"
            and "A Torre usa as ondas dinâmicas do sistema de torre."
            or "Nenhuma criatura foi definida para esta área.")
    else
        local valores = {}
        local achouSelecionado = false
        for _, criatura in ipairs(lista) do
            valores[criatura.id] = criatura.nome
            if criatura.id == S.monstroId then achouSelecionado = true end
        end
        if not achouSelecionado then
            S.monstroId = lista[1].id
            S.monstroNome = lista[1].nome
        end
        sincronizandoCriatura = true
        MonsterDropdown:SetValues(valores)
        MonsterDropdown:SetValue(S.monstroId)
        MonsterDropdown:SetVisible(true)
        sincronizandoCriatura = false
        CreatureInfo:SetText("Alvo atual: " .. S.monstroNome)
    end

    if S.farmBiomaAtivo and biomaAnterior ~= bioma.id and not suprimirViagem then
        S.movimentoToken = S.movimentoToken + 1
        local ch = LP.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if hum and root then hum:MoveTo(root.Position) end

        S.portalEmCurso = true
        S.portalAreaAtual = bioma.id
        S.alvoAtual = "viajando para " .. bioma.id
        setStatus("Trocando para " .. bioma.nome .. "...", C.blue)
        SLab4:SetText("Cancelando o movimento anterior e solicitando novo portal")
        task.defer(function()
            if S.farmBiomaAtivo and S.biomaId == bioma.id and iniciarPortalArea then
                iniciarPortalArea(bioma.id, true)
            end
        end)
    end
end

selecionarBioma(Biomas[1])
atualizarEstadoFarm()

-- A lógica do jogo continua abaixo, separada da construção visual.
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
    local tokenMovimento = S.movimentoToken
    if S.walkBoost then hum.WalkSpeed = S.walkSpeed end
    hum:MoveTo(destino)
    local t0 = os.clock()
    local limite = timeout or 8
    while os.clock() - t0 < limite do
        task.wait(0.08)
        if not S.ativo or tokenMovimento ~= S.movimentoToken then
            local atual = getChar()
            local atualHum = atual and atual:FindFirstChildOfClass("Humanoid")
            local atualRoot = atual and atual:FindFirstChild("HumanoidRootPart")
            if atualHum and atualRoot then atualHum:MoveTo(atualRoot.Position) end
            return false
        end
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
            fireproximityprompt(prompt)
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
    -- Cada solicitação de portal invalida deslocamentos anteriores.
    S.movimentoToken = S.movimentoToken + 1
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
        S.portalAreaAtual = "Hub"
        setStatus("Farm do Hub iniciado", C.green)
        SLab4:SetText("")
        return true
    end
    if not PortalEvento or not PortalEvento:IsA("RemoteEvent") then
        S.portalEmCurso = false
        S.farmBiomaAtivo = false
        atualizarEstadoFarm()
        setStatus("Erro: PortalEvento indisponível", C.red)
        SLab4:SetText("Não foi possível solicitar o portal")
        return false
    end
    if LP:GetAttribute("Liberada_" .. areaId) == false then
        S.portalEmCurso = false
        S.farmBiomaAtivo = false
        atualizarEstadoFarm()
        setStatus("Área bloqueada: " .. tostring(areaId), C.red)
        SLab4:SetText("Desbloqueie a área antes de viajar")
        return false
    end

    S.portalEmCurso = true
    S.portalAreaAtual = areaId
    portalAtual = nil
    portalExpira = 0
    portalAvisouChegou = false
    portalAguardandoDesde = 0
    setStatus("Solicitando portal para " .. tostring(areaId) .. "...", C.blue)
    SLab4:SetText("Aguardando o portal aparecer")
    local ok = pcall(function()
        PortalEvento:FireServer("Abrir", areaId)
    end)
    if not ok then
        S.portalEmCurso = false
        S.farmBiomaAtivo = false
        atualizarEstadoFarm()
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
            if S.farmBiomaAtivo and (not areaId or areaId == S.biomaId or areaId == S.portalAreaAtual) then
                S.portalEmCurso = false
                portalAtual = nil
                portalAguardandoDesde = 0
                setStatus("Chegou em " .. tostring(areaId or S.biomaId), C.green)
                SLab4:SetText("Farm iniciado em " .. tostring(areaId or S.biomaId))
            end
        elseif acao == "Erro" then
            -- Não deixa erro atrasado do portal antigo cancelar a nova área.
            if areaId and areaId ~= S.biomaId and areaId ~= S.portalAreaAtual then return end
            S.portalEmCurso = false
            S.farmBiomaAtivo = false
            atualizarEstadoFarm()
            portalAtual = nil
            setStatus("Erro no portal: " .. tostring(areaId), C.red)
            SLab4:SetText("Verifique se a área está liberada")
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
            SLab4:SetText("Ative Auto Entrar no Portal para continuar")
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
                    S.farmBiomaAtivo = false
                    atualizarEstadoFarm()
                    setStatus("Portal não encontrado", C.red)
                    SLab4:SetText("Tente ativar o farm novamente")
                else
                    setStatus("Aguardando portal de " .. tostring(S.biomaId), C.blue)
                    SLab4:SetText("O portal pode levar alguns instantes para aparecer")
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
            SLab4:SetText("Destino: " .. tostring(S.biomaId) .. " · " .. math.floor(distanciaPortal) .. " studs")
            andarAte(Vector3.new(pos.X, hrp.Position.Y, pos.Z), 4)
            continue
        end

        setStatus("Entrando no portal...", C.blue)
        SLab4:SetText("Ativando Entrada · " .. tostring(S.biomaId))
        if not portalAvisouChegou then
            portalAvisouChegou = true
            pcall(function() PortalEvento:FireServer("Chegou", S.biomaId) end)
        end
        ativarEntradaPortal(prompt)
        if portalAguardandoDesde == 0 then portalAguardandoDesde = os.clock() end
        if os.clock() - portalAguardandoDesde > 10 then
            S.portalEmCurso = false
            S.farmBiomaAtivo = false
            atualizarEstadoFarm()
            setStatus("Entrada não confirmada", C.red)
            SLab4:SetText("O servidor não confirmou a viagem")
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

-- ============================================================
-- COLETA PRIORITÁRIA: itens tagueados como ItemChao + fallback Nucleos
-- ============================================================
local function getPosicaoItem(item)
    if not item or not item.Parent then return nil end
    if item:IsA("BasePart") then
        return item.Position
    elseif item:IsA("Model") then
        local pp = item.PrimaryPart
        if pp then return pp.Position end
        local ok, pivot = pcall(function() return item:GetPivot() end)
        if ok and pivot then return pivot.Position end
    elseif item:IsA("Attachment") then
        return item.WorldPosition
    end
    local parte = item:FindFirstChildWhichIsA("BasePart", true)
    return parte and parte.Position or nil
end

local function getNucleos()
    local items, vistos = {}, {}
    -- A tag encontra drops em qualquer pasta/parte do mapa, sem varrer toda a árvore.
    for _, item in ipairs(CollectionService:GetTagged("ItemChao")) do
        if item:IsDescendantOf(workspace) and not vistos[item] then
            vistos[item] = true
            table.insert(items, item)
        end
    end
    -- Fallback para manter compatibilidade com núcleos que ainda não tenham a tag.
    local pasta = workspace:FindFirstChild("Nucleos")
    if pasta then
        for _, item in ipairs(pasta:GetChildren()) do
            if item:IsDescendantOf(workspace) and not vistos[item] then
                vistos[item] = true
                table.insert(items, item)
            end
        end
    end
    return items
end

local function acharNucleoPerto()
    local ch = getChar()
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local mp = hrp.Position
    local agora = workspace:GetServerTimeNow()
    local melhor, melhorScore, melhorDist = nil, -math.huge, math.huge

    for _, item in ipairs(getNucleos()) do
        local pos = getPosicaoItem(item)
        if pos then
            local expira = tonumber(item:GetAttribute("ExpiraEm"))
            local tempo = expira and (expira - agora) or (tonumber(item:GetAttribute("DuracaoTotal")) or 30)
            -- Itens expirados não entram na seleção.
            if tempo > 0 then
                local dist = (pos - mp).Magnitude
                if dist <= S.raioColeta then
                    -- Urgência pesa mais que a distância para evitar perder drops.
                    local urgencia = 0
                    if tempo <= 5 then
                        urgencia = 1000
                    elseif tempo <= 10 then
                        urgencia = 500
                    elseif tempo <= 15 then
                        urgencia = 200
                    end
                    local score = urgencia - dist
                    if score > melhorScore then
                        melhorScore, melhorDist, melhor = score, dist, item
                    end
                end
            end
        end
    end
    return melhor, melhorDist
end

local function getPromptNucleo(nucleo)
    if not nucleo or not nucleo.Parent then return nil end
    if nucleo:IsA("ProximityPrompt") then return nucleo end
    for _, d in ipairs(nucleo:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then return d end
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
                SLab4:SetText("→ " .. n.Name)
                local nomeItem = n.Name
                coletarNucleo(n)
                task.wait(0.2)
                if not n.Parent or not n:IsDescendantOf(workspace) then
                    S.coletados = S.coletados + 1
                    SLab4:SetText("✔ " .. nomeItem)
                else
                    -- Mesmo que o prompt não gere erro, aproximamos e tentamos novamente.
                    -- Isso evita confundir chamada local bem-sucedida com coleta confirmada.
                    local pos = getPosicaoItem(n)
                    if pos then
                        local chColeta = getChar()
                        local hrpColeta = chColeta and chColeta:FindFirstChild("HumanoidRootPart")
                        if hrpColeta and (hrpColeta.Position - pos).Magnitude > 7 then
                            andarAte(pos, 3)
                        end
                        if n.Parent and n:IsDescendantOf(workspace) then
                            coletarNucleo(n)
                            task.wait(0.15)
                        end
                    end
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
        SLab4:SetText("")

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
        SLab2:SetText(string.format("Abates: %d · Núcleos: %d", S.abates, S.coletados))
        SLab3:SetText("Alvo: " .. S.alvoAtual)
    end
end)

-- Garante a restauração da velocidade quando os modos de farm estão desligados.
task.spawn(function()
    while GUI and GUI.Parent do
        task.wait(0.2)
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
            SLab4:SetText("Andar " .. S.torreAndar .. " · " .. tipo)

        elseif acao == "Restantes" then
            -- Evento de estado recebido; o servidor continua sendo a fonte da verdade.
            if S.torreAtivo and type(dados) == "table" and dados.Quantidade ~= nil then
                SLab4:SetText("Andar " .. S.torreAndar .. " · Restantes: " .. tostring(dados.Quantidade))
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
            SLab4:SetText("Não é possível entrar na Torre")
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
                    SLab4:SetText("Andar " .. S.torreAndar .. " · " .. alvo.Name)

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
                SLab4:SetText("Andar " .. S.torreAndar .. " · aguardando...")
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
                    SLab4:SetText((prompt and "Entrada localizada · " or "Indo para a zona · ") .. math.floor(distanciaTorre) .. " studs")
                    -- Igual ao farm do Hub: MoveTo em trechos curtos, recalculando até o destino.
                    andarAte(Vector3.new(pos.X, hrp.Position.Y, pos.Z), 4)
                    task.wait(0.15)
                    continue
                end

                setStatus("Chegou à Torre · solicitando entrada...", C.purple)
                SLab4:SetText("Abrir → Entrar · aguardando confirmação")
                pcall(function() TorreEvento:FireServer("Abrir") end)
                task.wait(0.45)
                if LP:GetAttribute("NaTorre") ~= true then
                    pcall(function() TorreEvento:FireServer("Entrar") end)
                end
                task.wait(2.5)
            else
                setStatus("Auto Entrar desativado", C.orange)
                SLab4:SetText("Ative Auto Entrar para iniciar a Torre")
                task.wait(0.5)
            end
        end
    end
end)

-- ============================================================
-- SISTEMA DE INVENTÁRIO
-- ============================================================
local InventarioAcao = ReplicatedStorage:WaitForChild("InventarioAcao", 5)
local InventarioAtualizar = ReplicatedStorage:WaitForChild("InventarioAtualizar", 5)
local VendaEvento = ReplicatedStorage:WaitForChild("VendaEvento", 5)
local CraftingEvento = ReplicatedStorage:WaitForChild("CraftingEvento", 5)
local DadosItens
do
    local ok, dados = pcall(function()
        return require(ReplicatedStorage:WaitForChild("DadosItens", 5))
    end)
    if ok then DadosItens = dados end
end

local invCache = { inv = {}, corpo = {}, tamanho = 0 }
local inventarioCicloEmCurso = false

if InventarioAtualizar and InventarioAtualizar:IsA("RemoteEvent") then
    InventarioAtualizar.OnClientEvent:Connect(function(dados, msg)
        if typeof(dados) ~= "table" then return end
        invCache.inv = {}
        invCache.corpo = {}
        invCache.tamanho = dados.Tamanho or 90
        for _, item in ipairs(dados.Inventario or {}) do
            if typeof(item) == "table" and item.Slot ~= nil then
                invCache.inv[item.Slot] = item
            end
        end
        for _, item in ipairs(dados.Corpo or {}) do
            if typeof(item) == "table" and item.Slot ~= nil then
                invCache.corpo[item.Slot] = item
            end
        end
        if msg and msg ~= "" then
            SLab4:SetText("⚙ " .. tostring(msg))
        end
    end)
end

if VendaEvento and VendaEvento:IsA("RemoteEvent") then
    VendaEvento.OnClientEvent:Connect(function(moedas, quantidade)
        if typeof(moedas) == "number" and moedas > 0 then
            S.moedasVendidas = S.moedasVendidas + moedas
            S.itensVendidos = S.itensVendidos + (typeof(quantidade) == "number" and math.max(0, math.floor(quantidade)) or 1)
        end
    end)
end

-- Craft automático: só confirma o craft se o servidor planejar itens e ganho de poder positivo.
if CraftingEvento and CraftingEvento:IsA("RemoteEvent") then
    CraftingEvento.OnClientEvent:Connect(function(acao, dados, mensagem)
        if acao == "PlanoMelhores" then
            S.craftPlanejamentoPendente = false
            if not S.craftEmCurso then return end

            local itens = typeof(dados) == "table" and dados.Itens or nil
            local ganho = typeof(dados) == "table" and tonumber(dados.Ganho) or nil
            local quantidade = 0
            if typeof(itens) == "table" then
                for _, item in ipairs(itens) do
                    if item ~= nil then quantidade = quantidade + 1 end
                end
            end

            if S.autoCraftMelhores and quantidade > 0 and ganho and ganho > 0 then
                SLab4:SetText("Craft de melhorias: +" .. tostring(ganho) .. " de poder")
                local ok, err = pcall(function()
                    CraftingEvento:FireServer("CraftarMelhores")
                end)
                if not ok then
                    S.craftEmCurso = false
                    SLab4:SetText("Falha ao solicitar craft")
                    warn("[DexFarm] Falha no craft: " .. tostring(err))
                else
                    task.delay(20, function()
                        if S.craftEmCurso then
                            S.craftEmCurso = false
                            SLab4:SetText("Craft: resposta do servidor não recebida")
                        end
                    end)
                end
            else
                S.craftEmCurso = false
                if S.autoCraftMelhores then
                    SLab4:SetText("Craft ignorado: nenhuma melhoria de poder")
                end
            end
        elseif acao == "ResultadoMelhores" then
            S.craftEmCurso = false
            if dados == true then
                SLab4:SetText("Craft de melhorias concluído")
            elseif mensagem then
                SLab4:SetText("Craft: " .. tostring(mensagem))
            end
        end
    end)
end

local function hashCorpo()
    local partes = {}
    for slot, item in pairs(invCache.corpo) do
        if item then
            table.insert(partes, tostring(slot) .. ":" .. tostring(item.Tipo or item.Nome or "?") .. ":" .. tostring(item.Estrelas or 0))
        end
    end
    table.sort(partes)
    return table.concat(partes, "|")
end

local function acaoInventario(acao, ...)
    if not InventarioAcao or not InventarioAcao:IsA("RemoteEvent") then
        setStatus("Inventário indisponível", C.red)
        SLab4:SetText("Remote InventarioAcao não encontrado")
        return false
    end
    local argumentos = {...}
    local unpackArgs = table.unpack or unpack
    local ok, err = pcall(function()
        InventarioAcao:FireServer(acao, unpackArgs(argumentos))
    end)
    if not ok then
        SLab4:SetText("Falha na ação: " .. tostring(err))
        return false
    end
    return true
end

equiparMelhores = function()
    setStatus("Equipando melhores...", C.purple)
    SLab4:SetText("Auto-equip")
    return acaoInventario("EquiparMelhores", "equipamento")
end

limparRepetidos = function()
    setStatus("Limpando repetidos...", C.gold)
    SLab4:SetText("Limpando repetidos")
    return acaoInventario("LimparRepetidos")
end

venderAte = function(raridade)
    raridade = math.clamp(math.floor(tonumber(raridade) or 1), 1, 3)
    local nomes = { "Básicos", "Raros", "Épicos" }
    setStatus("Vendendo " .. nomes[raridade] .. "...", C.gold)
    SLab4:SetText("Vendendo até: " .. nomes[raridade])
    return acaoInventario("VenderAte", raridade)
end

sincronizarInv = function()
    return acaoInventario("Sincronizar")
end

local function tentarEvoluir()
    if not InventarioAcao or not DadosItens or type(DadosItens.dadosDe) ~= "function" then return 0 end
    local grupos = {}
    for slot, item in pairs(invCache.inv) do
        if item.Categoria == "Equipamento" and item.Travado ~= true then
            local estrelas = tonumber(item.Estrelas) or 0
            if estrelas < 5 and item.Tipo and DadosItens.dadosDe(item) then
                local chave = tostring(item.Tipo) .. ":" .. tostring(estrelas)
                grupos[chave] = grupos[chave] or { itens = {}, estrelas = estrelas }
                table.insert(grupos[chave].itens, slot)
            end
        end
    end
    local evoluiu = 0
    for _, grupo in pairs(grupos) do
        if #grupo.itens >= 3 then
            -- O servidor valida os itens e os recursos; tenta uma unidade por grupo.
            local ok = acaoInventario("EvoluirEquip", "inv", grupo.itens[1])
            if ok then
                evoluiu = evoluiu + 1
                task.wait(0.6)
            end
            if evoluiu >= 3 then break end
        end
    end
    return evoluiu
end

task.spawn(function()
    while GUI.Parent do
        task.wait(1)
        if not S.ativo then
            S.ultimoInv = 0
            continue
        end
        if inventarioCicloEmCurso or not InventarioAcao or not InventarioAcao:IsA("RemoteEvent") then
            continue
        end
        local agora = os.clock()
        if S.ultimoInv ~= 0 and agora - S.ultimoInv < S.intervaloInv then
            continue
        end
        inventarioCicloEmCurso = true
        S.ultimoInv = agora
        local hashAntes = hashCorpo()
        local okCiclo, errCiclo = pcall(function()
            sincronizarInv()
            task.wait(1)
            if S.autoEquipar then
                equiparMelhores()
                task.wait(1.2)
                sincronizarInv()
                task.wait(0.8)
            end
            if S.autoEvoluir then
                local n = tentarEvoluir()
                if n > 0 then
                    setStatus("Evoluindo " .. n .. " grupo(s)...", C.green)
                    task.wait(1)
                    sincronizarInv()
                    task.wait(0.6)
                end
            end
            if S.autoLimpar then
                limparRepetidos()
                task.wait(1.2)
                sincronizarInv()
                task.wait(0.6)
            end
            if S.autoVenderAte then
                venderAte(S.raridadeVender)
                task.wait(1.2)
                sincronizarInv()
                task.wait(0.6)
            end
            local hashDepois = hashCorpo()
            if hashAntes ~= hashDepois and hashDepois ~= "" then
                S.equipamentos = S.equipamentos + 1
            end
            setStatus("Farmando...", C.green)
            SLab4:SetText("")

            -- Planeja no fim do ciclo para não competir com limpeza/venda/equipamento.
            local agoraCraft = os.clock()
            if S.autoCraftMelhores
                and CraftingEvento
                and CraftingEvento:IsA("RemoteEvent")
                and not S.craftEmCurso
                and not S.craftPlanejamentoPendente
                and (S.ultimoPedidoCraft == 0 or agoraCraft - S.ultimoPedidoCraft >= 60) then
                S.craftEmCurso = true
                S.craftPlanejamentoPendente = true
                S.ultimoPedidoCraft = agoraCraft
                local okCraft, errCraft = pcall(function()
                    CraftingEvento:FireServer("PlanejarMelhores")
                end)
                if not okCraft then
                    S.craftPlanejamentoPendente = false
                    S.craftEmCurso = false
                    warn("[DexFarm] Falha ao planejar craft: " .. tostring(errCraft))
                else
                    task.delay(15, function()
                        if S.craftPlanejamentoPendente then
                            S.craftPlanejamentoPendente = false
                            S.craftEmCurso = false
                        end
                    end)
                end
            end
        end)
        if not okCiclo then
            warn("[DexFarm] Erro no ciclo de inventário: " .. tostring(errCiclo))
            SLab4:SetText("Erro no inventário; ciclo seguinte tentará novamente")
        end
        inventarioCicloEmCurso = false
    end
end)

task.spawn(function()
    while GUI.Parent do
        task.wait(0.5)
        StatMoedas:SetText("Moedas ganhas: " .. tostring(S.moedasVendidas))
        StatItens:SetText("Itens vendidos: " .. tostring(S.itensVendidos))
        StatEquip:SetText("Equipamentos trocados: " .. tostring(S.equipamentos))
    end
end)

print("[DexFarm v5.9] Carregado com Obsidian UI!")
