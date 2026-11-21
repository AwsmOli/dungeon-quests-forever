-- Route planner engine: a Lua 5.1 port of planner/engine.js, plus quest progress.
-- Pure logic, no WoW API calls, so it runs under plain Lua for tests.
local ADDON, ns = ...
ns = ns or {}

local Engine = {}
ns.Engine = Engine

local FLY_SPEED, RIDE_SPEED, FOOT = 6, 2.6, 1.6
local FP_OVERHEAD, CAST, SUMMON, ACT = 1, 0.5, 1.5, 0.5
local CITIES = { A = { "SW", "IF", "DARN" }, H = { "ORG", "UC", "TB" } }
Engine.CITIES = CITIES
local RULES = {
  teleport = { SW = 20, IF = 20, ORG = 20, UC = 20, DARN = 30, TB = 30 },
  portal = { SW = 40, IF = 40, ORG = 40, UC = 40, DARN = 50, TB = 50 },
  mount = 40, summon = 20, moonglade = 10,
}
Engine.RULES = RULES

local H, BOATS = {}, {}
local CTX = { level = 60, mounted = true }
local memo, nets = {}, {}
local INF = math.huge

function Engine.Setup(hubs, boats, rules)
  H, BOATS = hubs or {}, boats or {}
  if rules then for k, v in pairs(rules) do RULES[k] = v end end
  memo, nets = {}, {}
end

local function setLevel(lvl)
  CTX.level = lvl or 60
  CTX.mounted = CTX.level >= RULES.mount
end
Engine.SetLevel = setLevel

local function can(kind, city)
  local t = RULES[kind]
  if type(t) == "table" then return CTX.level >= (t[city] or 99) end
  return CTX.level >= t
end
Engine.Can = can

local function dist(a, b) local dx, dy = a.x - b.x, a.y - b.y; return math.sqrt(dx * dx + dy * dy) end
local function rideOf(h, f)
  local r = h.ride and h.ride[f]
  if r == nil then r = 4 end
  return CTX.mounted and r or r * FOOT
end
local function flySame(a, b, f) return FP_OVERHEAD + rideOf(H[a], f) + dist(H[a], H[b]) / FLY_SPEED + rideOf(H[b], f) end
local function rideSame(a, b) return 0.3 + dist(H[a], H[b]) / (CTX.mounted and RIDE_SPEED or RIDE_SPEED / FOOT) end
local function sameCont(a, b, f)
  if a == b then return { min = 0, via = "Here" } end
  local fly, ride = flySame(a, b, f), rideSame(a, b)
  if ride <= fly then return { min = ride, via = CTX.mounted and "Ride" or "Run" } end
  return { min = fly, via = "Fly" }
end

-- Shortest paths between docks (Floyd-Warshall over a handful of nodes).
local function network(f)
  local key = f .. (CTX.mounted and "m" or "w")
  if nets[key] then return nets[key] end
  local nodes, seen, edges = {}, {}, {}
  for _, b in ipairs(BOATS) do
    if (b.f == "both" or b.f == f) and H[b.a] and H[b.b] then
      for _, n in ipairs({ b.a, b.b }) do if not seen[n] then seen[n] = true; nodes[#nodes + 1] = n end end
      edges[#edges + 1] = b
    end
  end
  local D = {}
  for _, i in ipairs(nodes) do
    D[i] = {}
    for _, j in ipairs(nodes) do
      if i == j then D[i][j] = 0
      elseif H[i].cont == H[j].cont then D[i][j] = sameCont(i, j, f).min
      else D[i][j] = INF end
    end
  end
  for _, e in ipairs(edges) do
    D[e.a][e.b] = math.min(D[e.a][e.b], e.min)
    if not e.oneWay then D[e.b][e.a] = math.min(D[e.b][e.a], e.min) end
  end
  for _, k in ipairs(nodes) do for _, i in ipairs(nodes) do for _, j in ipairs(nodes) do
    if D[i][k] + D[k][j] < D[i][j] then D[i][j] = D[i][k] + D[k][j] end
  end end end
  nets[key] = { nodes = nodes, D = D }
  return nets[key]
end

local function baseTravel(a, b, f)
  local key = a .. ">" .. b .. ">" .. f .. (CTX.mounted and "m" or "w")
  if memo[key] then return memo[key] end
  local r
  if a == b then r = { min = 0, via = "Here" }
  elseif H[a].cont == H[b].cont then r = sameCont(a, b, f)
  else
    local net, best = network(f), nil
    for _, pa in ipairs(net.nodes) do
      if H[pa].cont == H[a].cont then
        for _, pb in ipairs(net.nodes) do
          if H[pb].cont == H[b].cont and net.D[pa][pb] < INF then
            local t = sameCont(a, pa, f).min + net.D[pa][pb] + sameCont(pb, b, f).min
            if not best or t < best then best = t end
          end
        end
      end
    end
    r = { min = best or 40, via = f == "H" and "Travel + zeppelin/boat" or "Travel + boat" }
  end
  memo[key] = r
  return r
end
Engine.BaseTravel = baseTravel

-- Cheapest way for someone with `abil` to get from `from` to `to`. extra = { {via=, min=} } (hearth)
local function travel(from, to, f, abil, extra)
  if from == to then return { min = 0, via = "Here" } end
  local best = baseTravel(from, to, f)
  local function consider(o) if o.min < best.min then best = o end end
  for _, c in ipairs(CITIES[f]) do
    if H[c] then
      local leg = (c == to) and 0 or baseTravel(c, to, f).min
      if abil.portalAll and abil.portalFromMage and can("portal", c) then
        consider({ min = CAST + leg, via = "Mage portal: " .. H[c].name })
      elseif abil.mage and can("teleport", c) then
        consider({ min = CAST + leg, via = "Teleport: " .. H[c].name })
      elseif abil.portalFromMage and can("portal", c) then
        consider({ min = CAST + leg, via = "Mage portal: " .. H[c].name })
      end
    end
  end
  if abil.gnomish and H.GADGETZAN then consider({ min = 1 + ((to == "GADGETZAN") and 0 or baseTravel("GADGETZAN", to, f).min), via = "Ultrasafe Transporter: Gadgetzan" }) end
  if abil.goblin and H.EVERLOOK then consider({ min = 1 + ((to == "EVERLOOK") and 0 or baseTravel("EVERLOOK", to, f).min), via = "Dimensional Ripper: Everlook" }) end
  if abil.druid and H.MOONGLADE and can("moonglade") then consider({ min = CAST + ((to == "MOONGLADE") and 0 or baseTravel("MOONGLADE", to, f).min), via = "Teleport: Moonglade" }) end
  if extra then for _, o in ipairs(extra) do consider(o) end end
  return best
end
Engine.Travel = travel

---------------------------------------------------------------------------
-- Quest helpers
---------------------------------------------------------------------------
local function isLive(q) return q.status == nil or q.status == "live" end
local function forFaction(q, f) return q.f == f or q.f == "B" end
local function isOptional(q) return q.cat == "optional" or q.cat == "class" end
local function pathOf(q, f)
  if not q.path then return nil end
  if q.path[1] then return q.path end
  return q.path[f]
end
Engine.IsLive, Engine.ForFaction, Engine.IsOptional, Engine.PathOf = isLive, forFaction, isOptional, pathOf

local function classOk(q, classes)
  if q.cat ~= "class" then return true end
  if not classes or not q.cls then return false end
  if q.cls == "All" then return true end
  for c in string.gmatch(q.cls:lower(), "[^/]+") do
    c = c:gsub("^%s+", ""):gsub("%s+$", "")
    for _, have in ipairs(classes) do if have == c then return true end end
  end
  return false
end
Engine.ClassOk = classOk

local function routable(q, f, incl, classes)
  return forFaction(q, f) and isLive(q) and pathOf(q, f) ~= nil
    and (incl or (not isOptional(q) and not q.optRoute)) and classOk(q, classes)
end
Engine.Routable = routable

function Engine.LevelInfo(d, f)
  local function mx(filter)
    local best, who
    for _, q in ipairs(d.quests) do
      if forFaction(q, f) and isLive(q) and q.req and filter(q) and (not best or q.req > best) then best, who = q.req, q.n end
    end
    return { lvl = best, q = who }
  end
  return {
    firstRun = mx(function(q) return not isOptional(q) and q.cat ~= "followup" and not q.optRoute end),
    full = mx(function(q) return not isOptional(q) end),
    cls = mx(function(q) return q.cat == "class" end),
    optional = mx(function(q) return q.cat == "optional" end),
  }
end

function Engine.MinLevel(d) return tonumber((tostring(d.range):match("^(%d+)"))) or 1 end

function Engine.PlannedLevel(d, f)
  local L = Engine.LevelInfo(d, f)
  return math.max(L.firstRun.lvl or 0, Engine.MinLevel(d))
end

-- opt.progress(q) -> first step still to do (1-based; > #steps means nothing left), or nil for "from the start".
-- opt.canAccept(q) -> false hides quests the party can't take yet.
local function buildTasks(d, f, opt, classes)
  local tasks, byName = {}, {}
  for _, q in ipairs(d.quests) do
    if routable(q, f, opt.includeOptional, classes) and (not opt.canAccept or opt.canAccept(q)) then
      local steps = pathOf(q, f)
      local first = opt.progress and opt.progress(q, steps) or 1
      local t = { q = q, steps = steps, first = first, after = {} }
      byName[q.n] = byName[q.n] or {}
      table.insert(byName[q.n], #tasks + 1)
      tasks[#tasks + 1] = t
    end
  end
  for _, t in ipairs(tasks) do
    for _, n in ipairs(t.q.after or {}) do
      for _, i in ipairs(byName[n] or {}) do table.insert(t.after, i) end
    end
  end
  -- Drop what's already done; a finished prerequisite no longer blocks anything.
  local keep, map = {}, {}
  for i, t in ipairs(tasks) do
    if t.first <= #t.steps then
      if t.first > 1 then
        local s = {}
        for k = t.first, #t.steps do s[#s + 1] = t.steps[k] end
        t.steps = s
      end
      keep[#keep + 1] = t; map[i] = #keep
    end
  end
  for _, t in ipairs(keep) do
    local a = {}
    for _, i in ipairs(t.after) do if map[i] then a[#a + 1] = map[i] end end
    t.after = a
  end
  return keep
end
Engine.BuildTasks = buildTasks

local function tour(f, start, tasks, abilFn, endHub)
  if #tasks == 0 then
    local fin0 = endHub and travel(start, endHub, f, abilFn(0), nil) or { min = 0, via = "Here" }
    return { visits = {}, time = fin0.min, final = fin0, finish = endHub or start }
  end
  local function readyIdx(ptr)
    local out = {}
    for i, t in ipairs(tasks) do
      if ptr[i] <= #t.steps then
        local ok = true
        for _, a in ipairs(t.after) do if ptr[a] <= #tasks[a].steps then ok = false; break end end
        if ok then out[#out + 1] = i end
      end
    end
    return out
  end
  local function run(firstHub)
    local ptr = {}
    for i = 1, #tasks do ptr[i] = 1 end
    local cur, t, visits, n, guard, hearthUsed = start, 0, {}, 0, 0, false
    while guard < 200 do
      guard = guard + 1
      local ready = readyIdx(ptr)
      if #ready == 0 then break end
      local abil = abilFn(n)
      local hub, best, bestTr
      for _, i in ipairs(ready) do
        local s = tasks[i].steps[ptr[i]]
        local tr = travel(cur, s.hub, f, abil, (not hearthUsed) and s.opts or nil)
        local score = tr.min + i * 1e-4
        if n == 0 and firstHub then score = (s.hub == firstHub) and -1 or (score + 1e6) end
        if not best or score < best then best, hub, bestTr = score, s.hub, tr end
      end
      if bestTr.via:find("^Hearth") then hearthUsed = true end
      local visit = { hub = hub, travel = bestTr, acts = {}, work = 0 }
      local moved = true
      while moved do
        moved = false
        for _, i in ipairs(readyIdx(ptr)) do
          local s = tasks[i].steps[ptr[i]]
          if s.hub == hub then
            local q = tasks[i].q
            visit.acts[#visit.acts + 1] = { q = q.n, quest = q, a = s.a, t = s.t or "", step = s, share = q.share,
              cls = (q.cat == "class") and q.cls or nil }
            visit.work = visit.work + ACT + (s.work or 0)
            ptr[i] = ptr[i] + 1
            moved = true
          end
        end
      end
      t = t + bestTr.min + visit.work
      cur = hub
      visits[#visits + 1] = visit
      n = n + 1
    end
    local fin = endHub and travel(cur, endHub, f, abilFn(n), nil) or { min = 0, via = "Here" }
    return { visits = visits, time = t + fin.min, final = fin, finish = endHub or cur }
  end
  local firsts, order = {}, {}
  for _, i in ipairs(readyIdx((function() local p = {}; for k = 1, #tasks do p[k] = 1 end; return p end)())) do
    local h = tasks[i].steps[1].hub
    if not firsts[h] then firsts[h] = true; order[#order + 1] = h end
  end
  local best
  for _, h in ipairs(order) do
    local r = run(h)
    if not best or r.time < best.time then best = r end
  end
  return best
end
Engine.Tour = tour

-- players: { {name=, cls="mage"|..., eng="none"|"gnomish"|"goblin"} }
function Engine.Plan(d, opt)
  local f, players, start = opt.faction, opt.players, opt.start
  local N = #players
  setLevel(opt.level or Engine.PlannedLevel(d, f))
  local classes = {}
  for i, p in ipairs(players) do classes[i] = p.cls end
  local tasks = buildTasks(d, f, opt, classes)
  local anyMage, warlockIdx = false, nil
  for i, p in ipairs(players) do
    if p.cls == "mage" then anyMage = true end
    if not warlockIdx and p.cls == "warlock" then warlockIdx = i end
  end
  local groupAbil = { portalFromMage = anyMage, portalAll = true }
  if N == 1 then
    local p0 = players[1]
    groupAbil = { mage = p0.cls == "mage", druid = p0.cls == "druid", gnomish = p0.eng == "gnomish", goblin = p0.eng == "goblin" }
  end
  local function abilOf(p, first)
    return { mage = p.cls == "mage", druid = p.cls == "druid", gnomish = p.eng == "gnomish", goblin = p.eng == "goblin",
      portalFromMage = first and anyMage and p.cls ~= "mage" }
  end
  local function finish(res, other) res.compare = other; res.tasks = #tasks; return res end
  local dependedOn = {}
  for _, t in ipairs(tasks) do for _, a in ipairs(t.after) do dependedOn[a] = true end end

  local all = tour(f, start, tasks, function() return groupAbil end, d.entrance)
  local together = { mode = "together", group = all, total = all.time, meet = (all.visits[1] and all.visits[1].hub) or d.entrance }
  if N == 1 then return finish(together, nil) end

  local cand, rest = {}, {}
  for i, t in ipairs(tasks) do
    local single = #t.steps == 1 and t.steps[1].a == "take" and #t.after == 0 and not dependedOn[i]
    local ok = single and (t.q.cat == "class" or (t.q.share == true and not t.q.pre))
    if ok then cand[#cand + 1] = t else rest[#rest + 1] = t end
  end
  local function reindex(list)
    local idx = {}
    for i, t in ipairs(tasks) do idx[t] = i end
    local map = {}
    for i, t in ipairs(list) do map[idx[t]] = i end
    local out = {}
    for i, t in ipairs(list) do
      local a = {}
      for _, x in ipairs(t.after) do if map[x] then a[#a + 1] = map[x] end end
      out[i] = { q = t.q, steps = t.steps, after = a }
    end
    return out
  end
  local restT = reindex(rest)
  local grp = tour(f, start, restT, function() return groupAbil end, d.entrance)
  local groupHubs = {}
  if #rest > 0 then for _, v in ipairs(grp.visits) do groupHubs[v.hub] = true end end
  local units, unitOrder, tagAlong = {}, {}, {}
  for _, t in ipairs(cand) do
    if groupHubs[t.steps[1].hub] then tagAlong[#tagAlong + 1] = t
    else
      local key = t.steps[1].hub .. ((t.q.cat == "class") and ("|" .. t.q.cls) or "")
      if not units[key] then units[key] = {}; unitOrder[#unitOrder + 1] = key end
      table.insert(units[key], t)
    end
  end
  if #tagAlong > 0 then
    local merged = {}
    for _, t in ipairs(rest) do merged[#merged + 1] = t end
    for _, t in ipairs(tagAlong) do merged[#merged + 1] = t end
    restT = reindex(merged)
    grp = tour(f, start, restT, function() return groupAbil end, d.entrance)
  end
  local unitList = {}
  for _, k in ipairs(unitOrder) do
    local ts, allowed = units[k], nil
    for _, t in ipairs(ts) do
      if t.q.cat == "class" then
        local ok = {}
        for i, p in ipairs(players) do if classOk(t.q, { p.cls }) then ok[#ok + 1] = i end end
        if allowed then
          local keep = {}
          for _, i in ipairs(allowed) do for _, j in ipairs(ok) do if i == j then keep[#keep + 1] = i end end end
          allowed = keep
        else allowed = ok end
      end
    end
    unitList[#unitList + 1] = { hub = ts[1].steps[1].hub, tasks = ts, allowed = allowed }
  end
  if #unitList == 0 then return finish(together, nil) end

  local meet = (grp.visits[1] and grp.visits[1].hub) or d.entrance
  local grpFromMeet = tour(f, meet, restT, function() return groupAbil end, d.entrance)

  local function allowedFor(u, pi)
    if not u.allowed then return true end
    for _, i in ipairs(u.allowed) do if i == pi then return true end end
    return false
  end
  local function evalAssign(assign)
    for u = 1, #unitList do if not allowedFor(unitList[u], assign[u]) then return { per = {}, time = INF } end end
    local per = {}
    for i = 1, N do per[i] = {} end
    for u, pi in ipairs(assign) do
      for _, t in ipairs(unitList[u].tasks) do table.insert(per[pi], { q = t.q, steps = t.steps, after = {} }) end
    end
    local res = {}
    for pi = 1, N do
      local p = players[pi]
      local tr = tour(f, start, per[pi], function(n) return abilOf(p, n == 0) end, meet)
      res[pi] = { player = p, pi = pi, visits = tr.visits, toMeet = tr.final, arrive = tr.time }
    end
    if warlockIdx and N >= 3 and can("summon") then
      local tw = res[warlockIdx].arrive
      local others, times = {}, {}
      for _, r in ipairs(res) do if r.pi ~= warlockIdx then others[#others + 1] = r; times[#times + 1] = r.arrive end end
      table.sort(times)
      local ready = math.max(tw, times[2])
      table.sort(others, function(a, b) return a.arrive < b.arrive end)
      local k = 0
      for _, r in ipairs(others) do
        local doneAt = r.arrive - r.toMeet.min
        local at = math.max(doneAt, ready + SUMMON * k) + SUMMON
        if at < r.arrive - 0.01 then
          k = k + 1
          r.toMeet = { min = at - doneAt, via = "Warlock summon" }
          r.arrive = at; r.summoned = true
        end
      end
    end
    local make = 0
    for _, r in ipairs(res) do if r.arrive > make then make = r.arrive end end
    return { per = res, time = make }
  end

  local C, best = #unitList, nil
  local total = N ^ C
  if total <= 4000 then
    for n = 0, total - 1 do
      local a, x = {}, n
      for i = 1, C do a[i] = (x % N) + 1; x = math.floor(x / N) end
      local r = evalAssign(a)
      if not best or r.time < best.time - 1e-9 then best = r end
    end
  else
    local ga = {}
    for j, u in ipairs(unitList) do ga[j] = u.allowed and u.allowed[1] or 1 end
    for j = 1, C do
      local bj
      for pi = 1, N do
        if allowedFor(unitList[j], pi) then
          ga[j] = pi
          local rr = evalAssign(ga)
          if not bj or rr.time < bj.time then bj = { time = rr.time, pi = pi } end
        end
      end
      ga[j] = bj.pi
    end
    best = evalAssign(ga)
  end
  local split = { mode = "split", players = best.per, splitTime = best.time, meet = meet, group = grpFromMeet,
    total = best.time + grpFromMeet.time, shares = {} }
  for _, r in ipairs(best.per) do
    for _, v in ipairs(r.visits) do
      for _, ac in ipairs(v.acts) do
        if not ac.cls then split.shares[#split.shares + 1] = { q = ac.q, from = r.player.name } end
      end
    end
  end
  if split.total >= together.total - 0.5 then return finish(together, split.total) end
  return finish(split, together.total)
end

return Engine
