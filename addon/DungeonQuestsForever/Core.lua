-- Glue: saved settings, who is in the party, where we are, the plan, events and slash commands.
local ADDON, ns = ...

local Engine, State, Map = ns.Engine, ns.State, ns.Map
local Data = ns.Data

ns.dungeonById, ns.questByName = {}, {}
for _, d in ipairs(Data.dungeons) do
  ns.dungeonById[d.id] = d
  for _, q in ipairs(d.quests) do ns.questByName[q.n] = q end
end

local function Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffe8743bDungeon Quests|r " .. msg) end
ns.Print = Print

---------------------------------------------------------------------------
-- Saved settings
---------------------------------------------------------------------------
local function InitDB()
  DungeonQuestsForeverDB = DungeonQuestsForeverDB or {}
  DungeonQuestsForeverChar = DungeonQuestsForeverChar or {}
  local g, c = DungeonQuestsForeverDB, DungeonQuestsForeverChar
  g.ids = g.ids or {}            -- quest name -> quest ID seen in a quest log
  c.done = c.done or {}          -- quest names this character turned in
  c.doneIds = c.doneIds or {}    -- quest IDs this character turned in
  c.eng = c.eng or "none"        -- "gnomish" | "goblin" | "none"
  if c.pins == nil then c.pins = true end
  if c.autoWaypoint == nil then c.autoWaypoint = true end
  if c.optional == nil then c.optional = false end
  ns.db = { global = g, char = c }
end

---------------------------------------------------------------------------
-- Dungeons, sorted by the level needed to take every quest for one run
---------------------------------------------------------------------------
function ns.SortedDungeons(faction)
  local list = {}
  for _, d in ipairs(Data.dungeons) do
    local L = Engine.LevelInfo(d, faction)
    list[#list + 1] = { d = d, all = L.firstRun.lvl or Engine.MinLevel(d), min = Engine.MinLevel(d) }
  end
  table.sort(list, function(a, b)
    if a.all ~= b.all then return a.all < b.all end
    if a.min ~= b.min then return a.min < b.min end
    return a.d.name < b.d.name
  end)
  return list
end

function ns.Selected()
  local id = ns.db and ns.db.char.dungeon
  if id and ns.dungeonById[id] then return ns.dungeonById[id] end
  -- First pick: the highest dungeon whose quests you can all take now.
  local me = State.Player()
  local pick
  for _, e in ipairs(ns.SortedDungeons(me.faction)) do if e.all <= me.level then pick = e.d end end
  return pick or ns.SortedDungeons(me.faction)[1].d
end

-- Pick a dungeon: build its guide and ask the party for their quest status.
function ns.Select(id)
  local d = ns.dungeonById[id]
  if not d then return end
  ns.Map.ClearCache()
  ns.Guide.Build(d)
  ns.builtAt = GetTime and GetTime() or 0
  ns.Comms.Request()
  ns.Comms.SendState()
  ns.Refresh(true)
end

---------------------------------------------------------------------------
-- Party and position
---------------------------------------------------------------------------
function ns.PartyCount()
  local n = 1
  if IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) then
    for i = 1, 4 do if UnitExists("party" .. i) then n = n + 1 end end
  end
  return n
end

local function PartyMembers(me)
  local list = { { name = me.name, cls = me.cls, eng = me.eng, level = me.level, self = true } }
  if IsInGroup and IsInGroup() and not (IsInRaid and IsInRaid()) then
    for i = 1, 4 do
      local unit = "party" .. i
      if UnitExists(unit) then
        local name = UnitName(unit)
        local synced = State.party[name]
        list[#list + 1] = { name = name, cls = State.ClassFromUnit(unit), level = UnitLevel(unit),
          eng = synced and synced.eng or "none", synced = synced }
      end
    end
  end
  return list
end

local CONT_KEYS = { ["Eastern Kingdoms"] = "EK", ["Kalimdor"] = "K" }
local hubsWithHere
-- A virtual "HERE" place at the player's continent position, so routes start where you stand.
local function StartHub(me)
  if not hubsWithHere then
    hubsWithHere = {}
    for k, v in pairs(Data.hubs) do hubsWithHere[k] = v end
  end
  hubsWithHere.HERE = nil
  if C_Map and C_Map.GetBestMapForUnit then
    local m = C_Map.GetBestMapForUnit("player")
    local guard = 0
    while m and guard < 8 do
      local info = C_Map.GetMapInfo(m)
      if not info then break end
      local cont = CONT_KEYS[info.name]
      if cont then
        local pos = C_Map.GetPlayerMapPosition(m, "player")
        if pos then
          local x, y = pos:GetXY()
          hubsWithHere.HERE = { name = "Your position", zone = "", cont = cont, x = x * 100, y = y * 100, ride = { A = 1, H = 1 } }
        end
        break
      end
      m, guard = info.parentMapID, guard + 1
    end
  end
  Engine.Setup(hubsWithHere, Data.boats)
  if hubsWithHere.HERE then return "HERE" end
  return me.faction == "H" and "ORG" or "SW"
end

---------------------------------------------------------------------------
-- The plan
---------------------------------------------------------------------------
function ns.BuildPlan()
  local d = ns.Selected()
  local me = State.Player()
  State.ScanQuestLog()
  local members = PartyMembers(me)
  local minLevel = me.level
  for _, m in ipairs(members) do if m.level and m.level > 0 and m.level < minLevel then minLevel = m.level end end

  local function statusFor(m, q)
    if m.self then return State.Status(q, m.level) end
    if m.synced and m.synced.dungeon == d.id then
      local s = m.synced.status[q.n]
      if s then return s end
    end
    if q.req and m.level and m.level > 0 and m.level < q.req then return "low" end
    return "todo"
  end

  local start = StartHub(me)
  local plan = Engine.Plan(d, {
    faction = me.faction, players = members, start = start, level = minLevel,
    includeOptional = ns.db.char.optional,
    -- Next step = the furthest-behind member who can still take the quest.
    progress = function(q, steps)
      local first = #steps + 1
      for _, m in ipairs(members) do
        local s = statusFor(m, q)
        if s ~= "low" then
          local f = State.FirstStep(s, steps)
          if f < first then first = f end
        end
      end
      return first
    end,
  })
  plan.dungeon, plan.me, plan.members, plan.level, plan.start = d, me, members, minLevel, start
  plan.statusFor = statusFor
  return plan
end

-- The stops this player walks: their own split route first, then the group route.
function ns.MyStops(plan)
  local visits = {}
  if plan.mode == "split" then
    for _, r in ipairs(plan.players) do
      if r.player.self then for _, v in ipairs(r.visits) do visits[#visits + 1] = v end end
    end
  end
  for _, v in ipairs(plan.group.visits) do visits[#visits + 1] = v end
  local stops = {}
  for i, v in ipairs(visits) do
    local hub = ns.Data.hubs[v.hub]
    local lines = {}
    for _, a in ipairs(v.acts) do
      local verb = (a.a == "take" and "Take") or (a.a == "turnin" and "Turn in") or "Do"
      lines[#lines + 1] = verb .. " " .. a.q .. ((a.t ~= "" and (": " .. a.t)) or "")
    end
    stops[#stops + 1] = { n = i, visit = v, title = hub and (hub.name .. (hub.zone ~= hub.name and (", " .. hub.zone) or "")) or v.hub,
      via = v.travel.via, minutes = v.travel.min, lines = lines, pos = Map.VisitPosition(v), next = (i == 1) }
  end
  return stops
end

---------------------------------------------------------------------------
-- Refresh (throttled): tick off guide steps, move pins and the waypoint on
---------------------------------------------------------------------------
local pending, lastCurrent = false, nil
function ns.Refresh(now)
  if pending and not now then return end
  pending = true
  local function run()
    pending = false
    local ok, err = pcall(function()
      local g = ns.Guide.Current()
      ns.partyCount = ns.PartyCount()
      if g then
        local st = ns.Guide.Evaluate(g)
        ns.guideState = st
        local pins, current = {}, nil
        for _, s in ipairs(st.stops) do
          if not s.done then
            local p = Map.StopPin(s)
            pins[#pins + 1] = p
            if s.current then current = p end
          end
        end
        ns.stops = pins
        if ns.db.char.pins then Map.ShowPins(pins) else Map.ClearPins() end
        local key = current and (g.dungeon .. ":" .. current.n)
        if ns.db.char.autoWaypoint and current and key ~= lastCurrent then Map.SetWaypoint(current) end
        lastCurrent = key
      else
        ns.guideState, ns.stops = nil, {}
        Map.ClearPins()
      end
      if ns.UI and ns.UI.Render then ns.UI.Render() end
    end)
    if not ok then Print("something went wrong: " .. tostring(err)) end
  end
  if now or not C_Timer then run() else C_Timer.After(0.5, run) end
end

-- Party answers that arrive right after a guide was built are worth a fresh route (nothing ticked yet).
function ns.OnPartyState(dungeonId)
  local g = ns.Guide.Current()
  local st = ns.guideState
  if g and g.dungeon == dungeonId and ns.builtAt and (GetTime() - ns.builtAt) < 10
    and st and st.doneCount == 0 and not next(g.manual) then
    ns.Guide.Build(ns.dungeonById[dungeonId])
  end
  ns.Refresh()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local events = { "PLAYER_LOGIN", "QUEST_ACCEPTED", "QUEST_TURNED_IN", "QUEST_REMOVED", "QUEST_LOG_UPDATE",
  "PLAYER_LEVEL_UP", "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "CHAT_MSG_ADDON" }
for _, e in ipairs(events) do frame:RegisterEvent(e) end
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    InitDB()
    ns.Comms.Init()
    if ns.UI and ns.UI.Create then ns.UI.Create() end
    ns.Minimap.Init()
    ns.Refresh(true)
    if not State.HasQuestieDB() then
      Print("tip: with QuestieDB installed the addon also knows quests you finished earlier and exact NPC spots.")
    end
    if not Map.HasPins() then
      Print("map pins need HereBeDragons (comes with Questie or ForeverMaps). The route list still works.")
    end
  elseif event == "QUEST_TURNED_IN" then
    local questID = ...
    local e = State.log.byId[questID]
    if e and ns.questByName[e.title] then ns.db.char.done[e.title] = true end
    if questID then ns.db.char.doneIds[questID] = true end
    ns.Comms.SendState()
    ns.Refresh()
  elseif event == "CHAT_MSG_ADDON" then
    ns.Comms.OnMessage(...)
  elseif event == "GROUP_ROSTER_UPDATE" then
    ns.Comms.Request(); ns.Comms.SendState(); ns.Refresh()
  elseif ns.db then
    if event == "QUEST_ACCEPTED" or event == "PLAYER_LEVEL_UP" then ns.Comms.SendState() end
    ns.Refresh()
  end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_DUNGEONQUESTSFOREVER1, SLASH_DUNGEONQUESTSFOREVER2 = "/dqf", "/dungeonquests"
SlashCmdList.DUNGEONQUESTSFOREVER = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  local cmd, arg = msg:match("^(%S*)%s*(.-)$")
  if cmd == "" then if ns.UI then ns.UI.Toggle() end
  elseif cmd == "pins" then ns.db.char.pins = not ns.db.char.pins; Print("map pins " .. (ns.db.char.pins and "on" or "off")); ns.Refresh(true)
  elseif cmd == "way" then
    local cur
    for _, p in ipairs(ns.stops or {}) do if p.next then cur = p end end
    if not Map.SetWaypoint(cur) then Print("no map position for the next step") end
  elseif cmd == "optional" then ns.db.char.optional = not ns.db.char.optional; Print("optional quests " .. (ns.db.char.optional and "included" or "hidden")); ns.Refresh(true)
  elseif cmd == "eng" and (arg == "gnomish" or arg == "goblin" or arg == "none") then ns.db.char.eng = arg; Print("teleport gadget: " .. arg); ns.Comms.SendState(); ns.Refresh(true)
  elseif cmd == "list" then ns.UI.Create(); ns.UI.ShowList(); ns.UI.Show()
  elseif cmd == "scale" and tonumber(arg) then
    local v = math.max(0.5, math.min(1.5, tonumber(arg)))
    ns.db.char.scale = v; ns.UI.SetScale(v); Print("window scale " .. v)
  elseif cmd == "minimap" then ns.Minimap.SetShown(ns.db.char.minimap.hide); Print("minimap button " .. (ns.db.char.minimap.hide and "hidden" or "shown"))
  elseif cmd == "reset" then ns.db.char.guide = nil; ns.Refresh(true); Print("guide cleared")
  else
    for _, d in ipairs(Data.dungeons) do
      if d.id == msg or d.short:lower() == msg or d.name:lower() == msg then ns.Select(d.id); ns.UI.Create(); ns.UI.ShowGuide(); ns.UI.Show(); return end
    end
    Print("/dqf, /dqf <dungeon> (e.g. /dqf brd), /dqf list, /dqf pins, /dqf way, /dqf optional, /dqf minimap, /dqf scale 0.9, /dqf reset, /dqf eng gnomish|goblin|none")
  end
end
