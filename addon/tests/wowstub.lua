-- A tiny fake of the WoW API: enough to load the addon under plain Lua and drive it with events.
local W = {}

W.player = { name = "Tester", class = "MAGE", faction = "Alliance", race = "Human", level = 50 }
W.party = {}        -- { {name=, class=, level=} }
W.log = {}          -- { {title=, questID=, complete=bool} }
W.completed = {}    -- [questID] = true
W.mapPos = { map = 1429, x = 0.55, y = 0.70 }  -- player on the Eastern Kingdoms continent map (made-up ids)
W.sent = {}         -- addon messages sent

-- Maps: 1 = world, 1415 = Eastern Kingdoms, 1414 = Kalimdor, zones below.
local maps = {
  [1] = { mapID = 1, name = "Azeroth", parentMapID = 0, mapType = 1 },
  [1415] = { mapID = 1415, name = "Eastern Kingdoms", parentMapID = 1, mapType = 2 },
  [1414] = { mapID = 1414, name = "Kalimdor", parentMapID = 1, mapType = 2 },
  [1428] = { mapID = 1428, name = "Burning Steppes", parentMapID = 1415, mapType = 3 },
  [1429] = { mapID = 1429, name = "Redridge Mountains", parentMapID = 1415, mapType = 3 },
  [1455] = { mapID = 1455, name = "Ironforge", parentMapID = 1415, mapType = 3 },
  [1453] = { mapID = 1453, name = "Stormwind City", parentMapID = 1415, mapType = 3 },
  [1426] = { mapID = 1426, name = "Dun Morogh", parentMapID = 1415, mapType = 3 },
  [1418] = { mapID = 1418, name = "Badlands", parentMapID = 1415, mapType = 3 },
}
W.areas = { [46] = "Burning Steppes", [1537] = "Ironforge" }

local function noop() end
local frameMT = {}
-- Unknown fields are both callable (methods) and indexable (child regions like TitleText).
local anyMT = {}
anyMT.__call = function() end
anyMT.__index = function(t, k) return setmetatable({}, anyMT) end
frameMT.__index = function(t, k)
  if k == "CreateFontString" or k == "CreateTexture" then
    return function() return setmetatable({ text = "" , SetText = function(s, v) s.text = v end,
      GetStringHeight = function() return 12 end }, frameMT) end
  end
  if k == "IsShown" then return function(s) return rawget(s, "shown") end end
  if k == "Show" then return function(s) s.shown = true end end
  if k == "Hide" then return function(s) s.shown = false end end
  if k == "SetScript" then return function(s, ev, fn) local sc = rawget(s, "scripts") or {}; rawset(s, "scripts", sc); sc[ev] = fn end end
  if k == "RegisterEvent" then return function(s, ev)
    for _, f in ipairs(W.frames) do if f == s then return end end
    W.frames[#W.frames + 1] = s
  end end
  if k == "SetText" then return function(s, v) s.text = v end end
  if k == "GetText" then return function(s) return s.text end end
  if k == "GetWidth" or k == "GetHeight" then return function() return 350 end end
  if k == "GetStringHeight" then return function() return 12 end end
  if k == "GetChecked" then return function(s) return rawget(s, "checked") end end
  if k == "SetChecked" then return function(s, v) rawset(s, "checked", v) end end
  if k == "GetCenter" then return function() return 100, 100 end end
  if k == "GetEffectiveScale" then return function() return 1 end end
  if k == "GetHighlightTexture" then return function() return setmetatable({}, frameMT) end end
  return setmetatable({}, anyMT)
end
W.frames = {}

function W.install()
  _G.CreateFrame = function(_, name) local f = setmetatable({}, frameMT); if name then _G[name] = f end; return f end
  _G.UIParent = setmetatable({}, frameMT)
  _G.Minimap = setmetatable({}, frameMT)
  _G.GetCursorPosition = function() return 120, 80 end
  W.instance = nil
  _G.IsInInstance = function() return W.instance ~= nil end
  _G.GetInstanceInfo = function() return W.instance end
  _G.GameTooltip = setmetatable({}, frameMT)
  _G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, m) W.chat = W.chat or {}; table.insert(W.chat, m) end }
  _G.SlashCmdList = {}
  _G.UISpecialFrames = {}
  _G.tinsert = table.insert
  _G.strsplit = function(sep, s)
    local out = {}
    for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do out[#out + 1] = part end
    return unpack(out)
  end
  _G.Ambiguate = function(n) return (n:gsub("%-.*", "")) end
  _G.GetTime = function() return 100 end
  _G.C_Timer = { After = function(_, fn) fn() end }
  _G.UnitName = function(u)
    if u == "player" then return W.player.name end
    local i = tonumber(u:match("party(%d)")); return i and W.party[i] and W.party[i].name
  end
  _G.UnitClass = function(u)
    if u == "player" then return W.player.class, W.player.class end
    local i = tonumber(u:match("party(%d)")); local p = i and W.party[i]; return p and p.class, p and p.class
  end
  _G.UnitLevel = function(u)
    if u == "player" then return W.player.level end
    local i = tonumber(u:match("party(%d)")); return i and W.party[i] and W.party[i].level or 0
  end
  _G.UnitRace = function() return W.player.race, W.player.race end
  _G.UnitFactionGroup = function() return W.player.faction end
  _G.UnitExists = function(u) local i = tonumber(u:match("party(%d)")); return i and W.party[i] ~= nil end
  _G.IsInGroup = function() return #W.party > 0 end
  _G.IsInRaid = function() return false end
  _G.C_ChatInfo = { RegisterAddonMessagePrefix = noop, SendAddonMessage = function(p, m, c) W.sent[#W.sent + 1] = { p, m, c } end }
  _G.C_QuestLog = {
    GetNumQuestLogEntries = function() return #W.log end,
    GetInfo = function(i) local e = W.log[i]; return e and { title = e.title, questID = e.questID, isHeader = false } end,
    IsComplete = function(id) for _, e in ipairs(W.log) do if e.questID == id then return e.complete end end return false end,
    IsQuestFlaggedCompleted = function(id) return W.completed[id] == true end,
  }
  _G.C_Map = {
    GetBestMapForUnit = function() return W.mapPos.zone or 1429 end,
    GetMapInfo = function(id) return maps[id] end,
    GetMapChildrenInfo = function(root)
      local out = {}
      for _, m in pairs(maps) do if m.mapID ~= root then out[#out + 1] = m end end
      return out
    end,
    GetPlayerMapPosition = function(id)
      if id == 1415 then return { GetXY = function() return W.mapPos.x, W.mapPos.y end } end
    end,
    GetAreaInfo = function(id) return W.areas[id] end,
    SetUserWaypoint = function(p) W.waypoint = p end,
    CanSetUserWaypointOnMap = function() return true end,
  }
  _G.UiMapPoint = { CreateFromCoordinates = function(m, x, y) return { mapId = m, x = x, y = y } end }
  _G.C_SuperTrack = { SetSuperTrackedUserWaypoint = noop }
  _G.Enum = { UIMapType = { Zone = 3 } }
  -- HereBeDragons stand-in that records pins.
  W.pins = {}
  local pinsLib = {
    AddWorldMapIconMap = function(_, ref, f, m, x, y) W.pins[#W.pins + 1] = { kind = "world", map = m, x = x, y = y, n = f.num.text } end,
    AddMinimapIconMap = function(_, ref, f, m, x, y) W.pins[#W.pins + 1] = { kind = "mini", map = m, x = x, y = y } end,
    RemoveAllWorldMapIcons = function() W.pins = {} end,
    RemoveAllMinimapIcons = noop,
  }
  _G.LibStub = function(name) if name == "HereBeDragons-Pins-2.0" then return pinsLib end end
  _G.bit = _G.bit or require("bit")
end

function W.load(dir)
  local ns = {}
  local toc = io.open(dir .. "/DungeonQuestsForever.toc"):read("*a")
  for file in toc:gmatch("\n([%w_]+%.lua)") do
    local chunk = assert(loadfile(dir .. "/" .. file))
    chunk("DungeonQuestsForever", ns)
  end
  return ns
end

function W.fire(event, ...)
  for _, f in ipairs(W.frames) do
    local sc = rawget(f, "scripts")
    if sc and sc.OnEvent then sc.OnEvent(f, event, ...) end
  end
end

return W
