-- AccurateDashboard_15_I18N.lua
-- Localização pura em Lua (mesma abordagem do LiteHealth).
-- Sem pasta Translate, sem .txt: as strings vivem aqui em tabelas,
-- e os acentos vão como escape de byte (\195\173 etc.), deixando
-- este arquivo 100% ASCII — imune a encoding/BOM.

local AD = AccurateDashboard
if not AD then return end

AD.L10N = {}
local L10N = AD.L10N

-- Para testar um idioma sem mudar o idioma do jogo:
-- L10N.FORCE_LANGUAGE = "ES"   (ou "PTBR" / "EN")
L10N.FORCE_LANGUAGE = nil

L10N.TABLES = {
  EN = {
    Tooltip_AccurateDash_EngineTemp = "Engine temperature",
    Tooltip_AccurateDash_Fuel       = "Fuel",
    Tooltip_RetroDash_TankLocation  = "Tank location",
    Tooltip_RetroDash_Left          = "Left",
    Tooltip_RetroDash_Right         = "Right",
    Tooltip_RetroDash_Center        = "Center",
    Tooltip_AccurateDash_front      = "front",
    Tooltip_AccurateDash_middle     = "middle",
    Tooltip_AccurateDash_rear       = "rear",
  },

  PTBR = {
    Tooltip_AccurateDash_EngineTemp = "Temperatura do motor",
    Tooltip_AccurateDash_Fuel       = "Combust\195\173vel", -- Combustível
    Tooltip_RetroDash_TankLocation  = "Local do tanque",
    Tooltip_RetroDash_Left          = "Esquerda",
    Tooltip_RetroDash_Right         = "Direita",
    Tooltip_RetroDash_Center        = "Centro",
    Tooltip_AccurateDash_front      = "frente",
    Tooltip_AccurateDash_middle     = "meio",
    Tooltip_AccurateDash_rear       = "traseira",
  },

  ES = {
    Tooltip_AccurateDash_EngineTemp = "Temperatura del motor",
    Tooltip_AccurateDash_Fuel       = "Combustible",
    Tooltip_RetroDash_TankLocation  = "Ubicaci\195\179n del tanque", -- Ubicación
    Tooltip_RetroDash_Left          = "Izquierda",
    Tooltip_RetroDash_Right         = "Derecha",
    Tooltip_RetroDash_Center        = "Centro",
    Tooltip_AccurateDash_front      = "delantera",
    Tooltip_AccurateDash_middle     = "medio",
    Tooltip_AccurateDash_rear       = "trasera",
  },
}

-- Apelidos -> código canônico
local ALIASES = {
  PT = "PTBR",
  PTBR = "PTBR",
  PORTUGUESEBRAZIL = "PTBR",
  PORTUGUESEBR = "PTBR",
  PORTUGUESBRASIL = "PTBR",
  PORTUGUESE = "PTBR",
  ES = "ES",
  SPANISH = "ES",
  ESPANOL = "ES",
  CASTELLANO = "ES",
  EN = "EN",
  ENGLISH = "EN",
}

local function normalizeLanguage(raw)
  local code = tostring(raw):upper():gsub("[^%w]", "")
  if ALIASES[code] then return ALIASES[code] end
  if code:find("BRAZIL") or code:find("BRASIL") then return "PTBR" end
  if code:find("SPANISH") or code:find("ESPAN") then return "ES" end
  if code:find("ENGLISH") then return "EN" end
  if code:find("PORTUG") then return "PTBR" end
  return code
end

local LANG

function L10N.detectLanguage()
  if L10N.FORCE_LANGUAGE then
    return L10N.FORCE_LANGUAGE
  end

  local ok, lang = pcall(function() return getCore():getOptionLanguageName() end)
  if not (ok and lang and lang ~= "") then
    ok, lang = pcall(function() return Translator.getLanguage():name() end)
  end

  if ok and lang and lang ~= "" then
    return normalizeLanguage(lang)
  end

  return "EN"
end

function L10N.getLanguage()
  if not LANG then
    LANG = L10N.detectLanguage()
    print("[AccurateDashboard] language=" .. LANG)
  end
  return LANG
end

-- Traduz: idioma atual -> EN -> nil (quem chama decide o fallback final)
function L10N.T(key)
  local tables = L10N.TABLES
  local lang = tables[L10N.getLanguage()]

  if lang and lang[key] then return lang[key] end
  if tables.EN[key] then return tables.EN[key] end

  return nil
end
