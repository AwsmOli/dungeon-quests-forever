-- What the player (and party members running the addon) already has: level, class, quest log,
-- completed quests. Quest IDs and NPC positions come from QuestieDB when it is loaded.
local ADDON, ns = ...

local State = {}
ns.State = State

local CLASS_IDS = { WARRIOR = "warrior", PALADIN = "paladin", HUNTER = "hunter", ROGUE = "rogue", PRIEST = "priest",
  SHAMAN = "shaman", MAGE = "mage", WARLOCK = "warlock", DRUID = "druid" }

---------------------------------------------------------------------------
-- API wrappers (Forever uses the modern C_QuestLog; older clients the globals)
---------------------------------------------------------------------------
local function NumQuestLogEntries()
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then return C_QuestLog.GetNumQuestLogEntries() end
  if GetNumQuestLogEntries then return GetNumQuestLogEntries() end
  return 0
end

-- title, questID, isHeader, isComplete
local function QuestLogEntry(i)
  if C_QuestLog and C_QuestLog.GetInfo then
    local info = C_QuestLog.GetInfo(i)
    if not info then return nil end
    local complete = (not info.isHeader) and C_QuestLog.IsComplete and C_QuestLog.IsComplete(info.questID) or false
    return info.title, info.questID, info.isHeader, complete
  elseif GetQuestLogTitle then
    local title, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
    return title, questID, isHeader, isComplete == 1
  end
end

local function IsFlaggedCompleted(id)
  if not id then return false end
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then return C_QuestLog.IsQuestFlaggedCompleted(id) end
  if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(id) end
  return false
end

---------------------------------------------------------------------------
-- Player
---------------------------------------------------------------------------
function State.Player()
  local _, classFile = UnitClass("player")
  local faction = UnitFactionGroup("player")
  local _, raceFile = UnitRace("player")
  return {
    name = UnitName("player"),
    level = UnitLevel("player"),
    cls = CLASS_IDS[classFile or ""] or "warrior",
    race = raceFile,
    faction = (faction == "Horde") and "H" or "A",
    eng = (ns.db and ns.db.char and ns.db.char.eng) or "none",
  }
end

function State.ClassFromUnit(unit)
  local _, classFile = UnitClass(unit)
  return CLASS_IDS[classFile or ""] or "warrior"
end

---------------------------------------------------------------------------
-- Quest log snapshot: by title and by id
---------------------------------------------------------------------------
State.log = { byTitle = {}, byId = {} }

function State.ScanQuestLog()
  local byTitle, byId = {}, {}
  for i = 1, NumQuestLogEntries() do
    local title, id, isHeader, complete = QuestLogEntry(i)
    if title and not isHeader then
      local e = { title = title, id = id, complete = complete and true or false }
      byTitle[title] = e
      if id then byId[id] = e end
    end
  end
  State.log = { byTitle = byTitle, byId = byId }
  -- Remember which quest ID our quests have, so completion can be checked later without QuestieDB.
  local ids = ns.db and ns.db.global and ns.db.global.ids
  if ids then for title, e in pairs(byTitle) do if e.id and ns.questByName[title] then ids[title] = e.id end end end
end

---------------------------------------------------------------------------
-- QuestieDB (optional): quest IDs by name, quest givers' positions
---------------------------------------------------------------------------
local function QDB() return _G.LibQuestieDB end
State.HasQuestieDB = function() return QDB() ~= nil and _G.QuestDB ~= nil and _G.NpcDB ~= nil end

local idCache = {}
-- Every ID QuestieDB knows for this name that fits the faction (both sides' versions can share a name).
function State.QuestIds(q)
  local key = q.n .. "|" .. q.f .. (State.HasQuestieDB() and "|q" or "")
  if idCache[key] ~= nil then return idCache[key] or nil end
  local ids = {}
  local learned = ns.db and ns.db.global and ns.db.global.ids and ns.db.global.ids[q.n]
  if learned then ids[#ids + 1] = learned end
  if State.HasQuestieDB() and _G.QuestDB.IdsByName then
    local ok, found = pcall(_G.QuestDB.IdsByName, q.n)
    if ok and found then
      local masks = QDB().Enum and QDB().Enum.factionRaceMasks
      local want = (q.f == "A" and masks and masks.Alliance) or (q.f == "H" and masks and masks.Horde) or nil
      for _, id in ipairs(found) do
        local races = _G.QuestDB.Get(id, "requiredRaces")
        local fits = true
        if want and races and races ~= 0 and bit and bit.band then fits = bit.band(races, want) ~= 0 end
        if fits then ids[#ids + 1] = id end
      end
    end
  end
  idCache[key] = (#ids > 0) and ids or false
  return #ids > 0 and ids or nil
end

-- Several parts of a chain can share one name (The True Masters has six). With IDs known, only the
-- last part (the highest ID) counts as done; without them, the name we saw turned in.
function State.IsCompleted(q)
  local c = ns.db and ns.db.char
  local ids = State.QuestIds(q)
  if ids then
    local last
    for _, id in ipairs(ids) do if not last or id > last then last = id end end
    return IsFlaggedCompleted(last) or (c and c.doneIds and c.doneIds[last]) or false
  end
  return (c and c.done and c.done[q.n]) or false
end

function State.InLog(q)
  local e = State.log.byTitle[q.n]
  if e then return e end
  local ids = State.QuestIds(q)
  if ids then for _, id in ipairs(ids) do if State.log.byId[id] then return State.log.byId[id] end end end
end

-- Quest giver positions from QuestieDB: list of { areaId, x, y }.
function State.GiverSpawns(q)
  if not State.HasQuestieDB() then return nil end
  local ids = State.QuestIds(q)
  if not ids then return nil end
  for _, id in ipairs(ids) do
    local startedBy = _G.QuestDB.Get(id, "startedBy")
    local npcs = startedBy and startedBy[1]
    if npcs then
      for _, npcId in ipairs(npcs) do
        local spawns = _G.NpcDB.Get(npcId, "spawns")
        if spawns then
          local out = {}
          for areaId, list in pairs(spawns) do
            for _, p in ipairs(list) do
              if p[1] and p[1] > 0 then out[#out + 1] = { areaId = areaId, x = p[1], y = p[2] } end
            end
          end
          if #out > 0 then return out end
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- Progress: which step of a quest's pickup path is next for one player
---------------------------------------------------------------------------
-- status: "done" (completed), "have" (in log), "ready" (complete objectives), "todo", "low" (level too low)
function State.Status(q, level)
  if State.IsCompleted(q) then return "done" end
  local e = State.InLog(q)
  if e then return e.complete and "ready" or "have" end
  if q.req and level and level < q.req then return "low" end
  return "todo"
end

-- First step still to do for someone with `status`. In the log means everything up to the last
-- pickup is done; finished objectives also skip the "do" steps after it.
function State.FirstStep(status, steps)
  if status == "done" then return #steps + 1 end
  if status ~= "have" and status ~= "ready" then return 1 end
  local lastTake = 0
  for i, s in ipairs(steps) do if s.a == "take" then lastTake = i end end
  local i = lastTake + 1
  if status == "ready" then while steps[i] and steps[i].a == "do" do i = i + 1 end end
  return i
end

---------------------------------------------------------------------------
-- Party members' progress (filled by Comms)
---------------------------------------------------------------------------
State.party = {} -- [name] = { cls=, eng=, level=, dungeon=, status = { [questName] = status }, at = time }

return State
