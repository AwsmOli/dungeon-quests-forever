-- The step-by-step guide: a route fixed when you pick a dungeon, whose steps tick off as your quest log
-- changes (or when you click them). Saved per character, so it survives reloads.
local ADDON, ns = ...

local Guide = {}
ns.Guide = Guide

local function QuestFor(d, name, faction)
  for _, q in ipairs(d.quests) do
    if q.n == name and ns.Engine.ForFaction(q, faction) then return q end
  end
end

-- Index of `step` inside the quest's full path, so progress can be read later.
local function StepIndex(q, faction, step)
  local path = ns.Engine.PathOf(q, faction) or {}
  for i, s in ipairs(path) do if s == step then return i end end
  for i, s in ipairs(path) do if s.hub == step.hub and s.a == step.a and (s.t or "") == (step.t or "") then return i end end
  return 1
end

-- Build a fresh guide for dungeon `d` from the current plan.
function Guide.Build(d)
  ns.db.char.dungeon = d.id
  local plan = ns.BuildPlan()
  local me = plan.me
  local stops = {}
  for _, stop in ipairs(ns.MyStops(plan)) do
    local acts = {}
    for _, a in ipairs(stop.visit.acts) do
      acts[#acts + 1] = { q = a.q, a = a.a, t = a.t, k = StepIndex(a.quest, me.faction, a.step) }
    end
    stops[#stops + 1] = { hub = stop.visit.hub, via = stop.via, min = stop.minutes, acts = acts }
  end
  local shares = {}
  if plan.mode == "split" then
    for _, sh in ipairs(plan.shares) do shares[#shares + 1] = { q = sh.q, from = sh.from } end
  end
  ns.db.char.guide = { dungeon = d.id, faction = me.faction, stops = stops, manual = {}, mode = plan.mode,
    total = plan.total, meet = plan.meet, shares = shares, members = #plan.members }
  return ns.db.char.guide
end

function Guide.Current()
  local g = ns.db and ns.db.char.guide
  if g and ns.dungeonById[g.dungeon] then return g end
end

-- Annotate the guide with what's done. Returns { stops = {...}, current = stopIndex|nil, doneCount, total }.
function Guide.Evaluate(g)
  local d = ns.dungeonById[g.dungeon]
  local me = ns.State.Player()
  ns.State.ScanQuestLog()
  local out, current, doneCount, total = {}, nil, 0, 0
  for si, s in ipairs(g.stops) do
    local hub = ns.Data.hubs[s.hub]
    local stop = { n = si, hub = s.hub, via = s.via, min = s.min, acts = {}, title = hub and (hub.name .. ((hub.zone ~= hub.name and hub.zone ~= "") and (", " .. hub.zone) or "")) or s.hub }
    local allDone = true
    for ai, a in ipairs(s.acts) do
      local q = QuestFor(d, a.q, g.faction)
      local manual = g.manual[si .. "." .. ai] and true or false
      local auto = false
      if q then
        local steps = ns.Engine.PathOf(q, g.faction) or {}
        local status = ns.State.Status(q, me.level)
        auto = ns.State.FirstStep(status, steps) > a.k
      end
      local done = manual or auto
      stop.acts[ai] = { q = a.q, quest = q, a = a.a, t = a.t, k = a.k, done = done, manual = manual, auto = auto,
        key = si .. "." .. ai }
      total = total + 1
      if done then doneCount = doneCount + 1 else allDone = false end
    end
    stop.done = allDone
    if not allDone and not current then current = si end
    out[si] = stop
  end
  -- The last step: go in. Ticked once you're inside this dungeon.
  local inside = false
  if IsInInstance and GetInstanceInfo then
    local isIn = IsInInstance()
    local name = GetInstanceInfo()
    inside = isIn and name and (name == d.name or name == d.aka) or false
  end
  local entrance = ns.Data.hubs[d.entrance]
  out[#out + 1] = { n = #out + 1, hub = d.entrance, final = true, done = inside,
    title = "Enter " .. d.name, via = "", min = 0,
    acts = { { q = d.name, a = "enter", t = entrance and (entrance.name .. (entrance.zone ~= entrance.name and (", " .. entrance.zone) or "")) or "", done = inside, key = "enter" } } }
  if not current and not inside then current = #out end
  -- What the map needs for each stop: the quest and the path step behind every action.
  for _, s in ipairs(out) do
    s.current = (s.n == current)
    s.visit = { hub = s.hub, acts = {} }
    for _, a in ipairs(s.acts) do
      if a.quest then
        local path = ns.Engine.PathOf(a.quest, g.faction) or {}
        s.visit.acts[#s.visit.acts + 1] = { a = a.a, q = a.q, quest = a.quest, step = path[a.k] }
      end
    end
  end
  return { stops = out, current = current, doneCount = doneCount, total = total, dungeon = d }
end

function Guide.Toggle(key)
  local g = Guide.Current()
  if not g or key == "enter" then return end
  g.manual[key] = not g.manual[key] or nil
  ns.Refresh(true)
end

-- Quest counts for the dungeon list: done or in the log, out of the quests worth doing for you.
function Guide.Progress(d, me)
  local have, total, low = 0, 0, 0
  for _, q in ipairs(d.quests) do
    if ns.Engine.ForFaction(q, me.faction) and ns.Engine.IsLive(q) and not ns.Engine.IsOptional(q) then
      total = total + 1
      local s = ns.State.Status(q, me.level)
      if s == "done" or s == "have" or s == "ready" then have = have + 1 elseif s == "low" then low = low + 1 end
    end
  end
  return have, total, low
end

return Guide
