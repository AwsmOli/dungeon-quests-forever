-- Map positions for route stops, numbered pins (world map + minimap) and a waypoint to the next stop.
local ADDON, ns = ...

local Map = {}
ns.Map = Map

local HBD = LibStub and LibStub("HereBeDragons-2.0", true)
local HBDPins = LibStub and LibStub("HereBeDragons-Pins-2.0", true)

---------------------------------------------------------------------------
-- Zone name / area id -> uiMapID
---------------------------------------------------------------------------
local zoneByName
local function BuildZoneIndex()
  zoneByName = {}
  if not (C_Map and C_Map.GetMapInfo and C_Map.GetMapChildrenInfo) then return end
  -- Walk up from wherever the player is to the top map, then list every zone below it.
  local id = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  local root, guard = id, 0
  while root and guard < 10 do
    local info = C_Map.GetMapInfo(root)
    if not info or not info.parentMapID or info.parentMapID == 0 then break end
    root, guard = info.parentMapID, guard + 1
  end
  if not root then return end
  local kids = C_Map.GetMapChildrenInfo(root, nil, true) or {}
  for _, m in ipairs(kids) do
    if m.name and (not zoneByName[m.name] or (Enum and Enum.UIMapType and m.mapType == Enum.UIMapType.Zone)) then
      zoneByName[m.name] = m.mapID
    end
  end
end

function Map.ZoneMapId(name)
  if not zoneByName or not next(zoneByName) then BuildZoneIndex() end
  return zoneByName and zoneByName[name]
end

local function AreaToMap(areaId)
  local loader = _G.QuestieLoader
  if loader and loader.ImportModule then
    local ok, ZoneDB = pcall(loader.ImportModule, loader, "ZoneDB")
    if ok and ZoneDB and ZoneDB.GetUiMapIdByAreaId then
      local ok2, mapId = pcall(ZoneDB.GetUiMapIdByAreaId, ZoneDB, areaId)
      if ok2 and mapId then return mapId end
    end
  end
  if C_Map and C_Map.GetAreaInfo then
    local name = C_Map.GetAreaInfo(areaId)
    if name then return Map.ZoneMapId(name) end
  end
end

---------------------------------------------------------------------------
-- Where a stop is: { mapId, x, y } with x, y in 0..1
---------------------------------------------------------------------------
local hubCoords -- [hub] = { zx, zy } from any step in the data that has coordinates
local function HubFallback(hubId)
  if not hubCoords then
    hubCoords = {}
    for _, d in ipairs(ns.Data.dungeons) do
      for _, q in ipairs(d.quests) do
        local paths = q.path and (q.path[1] and { q.path } or { q.path.A, q.path.H }) or {}
        for _, p in ipairs(paths) do
          for _, s in ipairs(p or {}) do
            if s.zx and not hubCoords[s.hub] then hubCoords[s.hub] = { s.zx, s.zy } end
          end
        end
      end
    end
  end
  return hubCoords[hubId]
end

function Map.VisitPosition(visit)
  local hub = ns.Data.hubs[visit.hub]
  if not hub then return nil end
  local zoneMap = Map.ZoneMapId(hub.zone)
  -- 1. The quest giver's real spawn (QuestieDB), preferring one in this stop's zone.
  for _, act in ipairs(visit.acts) do
    if act.a == "take" and act.quest then
      local spawns = ns.State.GiverSpawns(act.quest)
      if spawns then
        local pick
        for _, s in ipairs(spawns) do
          local m = AreaToMap(s.areaId)
          if m and (not zoneMap or m == zoneMap) then pick = { mapId = m, x = s.x / 100, y = s.y / 100 }; break end
          if m and not pick then pick = { mapId = m, x = s.x / 100, y = s.y / 100 } end
        end
        if pick then return pick end
      end
    end
  end
  if not zoneMap then return nil end
  -- 2. Coordinates written in our data for a step here.
  for _, act in ipairs(visit.acts) do
    if act.step and act.step.zx then return { mapId = zoneMap, x = act.step.zx / 100, y = act.step.zy / 100 } end
  end
  -- 3. Any known spot at this place.
  local c = HubFallback(visit.hub)
  if c then return { mapId = zoneMap, x = c[1] / 100, y = c[2] / 100 } end
end

-- A guide step as a pin: { n, title, lines, pos, next }. Positions are cached per guide step.
local posCache = {}
function Map.StopPin(stop)
  local key = (ns.db and ns.db.char.guide and ns.db.char.guide.dungeon or "") .. ":" .. stop.n .. ":" .. stop.hub
  if posCache[key] == nil then
    local pos = Map.VisitPosition(stop.visit or { hub = stop.hub, acts = {} })
    posCache[key] = pos or false
  end
  local lines = {}
  for _, a in ipairs(stop.acts) do if not a.done then lines[#lines + 1] = ns.UI.ActText(a) end end
  return { n = stop.n, title = stop.title, lines = lines, pos = posCache[key] or nil, next = stop.current }
end
function Map.ClearCache() posCache = {} end

---------------------------------------------------------------------------
-- Pins
---------------------------------------------------------------------------
local pool, used = {}, {}

local function NewPin()
  local f = CreateFrame("Button", nil, UIParent)
  f:SetSize(18, 18)
  local tex = f:CreateTexture(nil, "ARTWORK")
  tex:SetAllPoints()
  tex:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
  f.icon = tex
  local num = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  num:SetPoint("TOP", f, "BOTTOM", 0, 2)
  f.num = num
  f:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self.title or "", 1, 0.82, 0)
    for _, l in ipairs(self.lines or {}) do GameTooltip:AddLine(l, 1, 1, 1, true) end
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return f
end

function Map.HasPins() return HBDPins ~= nil end

function Map.ClearPins()
  if not HBDPins then return end
  HBDPins:RemoveAllWorldMapIcons(Map)
  HBDPins:RemoveAllMinimapIcons(Map)
  for _, f in ipairs(used) do f:Hide(); pool[#pool + 1] = f end
  used = {}
end

-- stops = { { n = 1, title = "...", lines = {...}, pos = {mapId,x,y}, next = bool } }
function Map.ShowPins(stops)
  Map.ClearPins()
  if not HBDPins then return 0 end
  local shown = 0
  for _, stop in ipairs(stops) do
    if stop.pos then
      for _, where in ipairs({ "world", "mini" }) do
        local f = table.remove(pool) or NewPin()
        f.title, f.lines = stop.title, stop.lines
        f.num:SetText(stop.n)
        f.icon:SetVertexColor(stop.next and 1 or 0.75, stop.next and 1 or 0.75, stop.next and 1 or 0.75)
        f:SetSize(stop.next and 22 or 16, stop.next and 22 or 16)
        f:Show()
        used[#used + 1] = f
        if where == "world" then
          HBDPins:AddWorldMapIconMap(Map, f, stop.pos.mapId, stop.pos.x, stop.pos.y, HBD_PINS_WORLDMAP_SHOW_CONTINENT)
        else
          HBDPins:AddMinimapIconMap(Map, f, stop.pos.mapId, stop.pos.x, stop.pos.y, true, true)
        end
      end
      shown = shown + 1
    end
  end
  return shown
end

---------------------------------------------------------------------------
-- Waypoint to one stop
---------------------------------------------------------------------------
function Map.SetWaypoint(stop)
  if not stop or not stop.pos then return false end
  local p = stop.pos
  if _G.TomTom and _G.TomTom.AddWaypoint then
    if Map.tomtomUid and _G.TomTom.RemoveWaypoint then pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, Map.tomtomUid) end
    local ok, uid = pcall(_G.TomTom.AddWaypoint, _G.TomTom, p.mapId, p.x, p.y, { title = stop.title, persistent = false })
    if ok then Map.tomtomUid = uid; return true end
  end
  if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates
    and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(p.mapId)) then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(p.mapId, p.x, p.y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
    return true
  end
  return false
end

-- Distance in yards from the player to a stop, if HereBeDragons can tell.
function Map.DistanceTo(pos)
  if not (HBD and pos) then return nil end
  local px, py, pInstance = HBD:GetPlayerWorldPosition()
  local wx, wy, wInstance = HBD:GetWorldCoordinatesFromZone(pos.x, pos.y, pos.mapId)
  if not (px and wx) or pInstance ~= wInstance then return nil end
  return HBD:GetWorldDistance(pInstance, px, py, wx, wy)
end

return Map
