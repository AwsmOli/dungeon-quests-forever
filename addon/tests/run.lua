-- Scenario tests for the addon under a fake WoW API. Run: luajit addon/tests/run.lua
local W = dofile("addon/tests/wowstub.lua")
W.install()
local ns = W.load("addon/DungeonQuestsForever")
local pass, fail = 0, 0
local function check(cond, what) if cond then pass = pass + 1 else fail = fail + 1; print("FAIL: " .. what) end end
-- The guide's steps for one quest, as "action:done" pairs.
local function guideActs(qname)
  local out = {}
  for _, s in ipairs(ns.guideState.stops) do
    for _, a in ipairs(s.acts) do if a.q == qname then out[#out + 1] = a.a .. ":" .. (a.done and "x" or "-") end end
  end
  return table.concat(out, ",")
end

-- Login: level 50 Alliance mage in Redridge. No guide yet; the list shows.
W.fire("PLAYER_LOGIN")
check(ns.guideState == nil, "no guide before picking a dungeon")
check(_G.DungeonQuestsForeverMinimapButton ~= nil, "own minimap button without LibDBIcon")
ns.UI.Show()
check(ns.UI.IsShown(), "window opens")
SlashCmdList.DUNGEONQUESTSFOREVER("list")
check(ns.UI.VisibleRows() == #ns.Data.dungeons, "list shows every dungeon, got " .. ns.UI.VisibleRows())
ns.UI.SetSearch("feralas")
check(ns.UI.VisibleRows() == 3, "search 'feralas' finds the three Dire Maul wings, got " .. ns.UI.VisibleRows())
ns.UI.SetSearch("")
for _, k in ipairs({ "level", "name", "zone", "all" }) do ns.UI.SetSort(k) end
check(ns.UI.VisibleRows() == #ns.Data.dungeons, "sorting keeps every row")
ns.UI.ToggleBand(1)
check(ns.UI.VisibleRows() < #ns.Data.dungeons, "collapsing a level group hides its rows")
ns.UI.ToggleBand(1)
ns.UI.JumpTo(3)
SlashCmdList.DUNGEONQUESTSFOREVER("scale 0.9")
check(ns.db.char.scale == 0.9, "/dqf scale saves the scale")

-- Pick BRD: a guide is built and nothing is ticked.
ns.Select("brd")
local st = ns.guideState
check(st and #st.stops > 2, "BRD guide has stops")
check(st.doneCount == 0, "nothing done yet")
check(st.stops[#st.stops].final, "last step is going in")
check(guideActs("Overmaster Pyron") == "take:-,do:-,turnin:-", "Pyron fresh: " .. guideActs("Overmaster Pyron"))
print("BRD guide: " .. #st.stops .. " stops, " .. st.total .. " steps; first: " .. st.stops[1].title)

-- Pyron accepted: the pickup ticks. Objective done: the kill ticks. Turned in: all ticked.
W.log = { { title = "Overmaster Pyron", questID = 4262, complete = false } }
W.fire("QUEST_ACCEPTED", 4262)
check(guideActs("Overmaster Pyron") == "take:x,do:-,turnin:-", "Pyron accepted: " .. guideActs("Overmaster Pyron"))
W.log[1].complete = true; W.fire("QUEST_LOG_UPDATE")
check(guideActs("Overmaster Pyron") == "take:x,do:x,turnin:-", "Pyron killed: " .. guideActs("Overmaster Pyron"))
W.fire("QUEST_TURNED_IN", 4262); W.log = {}; W.fire("QUEST_LOG_UPDATE")
check(guideActs("Overmaster Pyron") == "take:x,do:x,turnin:x", "Pyron turned in: " .. guideActs("Overmaster Pyron"))
check(ns.guideState.doneCount == 3, "three steps done, got " .. ns.guideState.doneCount)
check(#ns.guideState.stops == #st.stops, "guide keeps its stops as steps tick")

-- Tick a step by hand, and untick it.
local key
for _, s in ipairs(ns.guideState.stops) do
  for _, a in ipairs(s.acts) do if not a.done and a.key ~= "enter" and not key then key = a.key end end
end
ns.Guide.Toggle(key)
local d1 = ns.guideState.doneCount
ns.Guide.Toggle(key)
check(d1 == 4 and ns.guideState.doneCount == 3, "manual tick toggles")

-- Tick a whole stop by hand: it folds up, but its header opens it again so a line can be unticked.
local function click(f) local sc = rawget(f, "scripts"); sc.OnClick(f, "LeftButton") end
local si
for i, s in ipairs(ns.guideState.stops) do if not s.done and not s.final and not si then si = i end end
for _, a in ipairs(ns.guideState.stops[si].acts) do if not a.done then ns.Guide.Toggle(a.key) end end
check(ns.guideState.stops[si].done, "stop ticked by hand is done")
ns.UI.Show(); ns.UI.ShowGuide()
local linesFolded = ns.UI.GuideLines()
click(ns.UI.GuideHeader(si))
check(ns.UI.GuideLines() == linesFolded + #ns.guideState.stops[si].acts, "header opens a finished stop")
-- The opened stop's lines come right after the lines of the open stops before it.
local before = 0
for i = 1, si - 1 do
  local s = ns.guideState.stops[i]
  if not s.done then before = before + #s.acts end
end
local mj
for j, a in ipairs(ns.guideState.stops[si].acts) do if a.manual and not a.auto and not mj then mj = j end end
local manualKey = ns.guideState.stops[si].acts[mj].key
click(ns.UI.GuideLine(before + mj))
check(not ns.guideState.stops[si].done, "unticking a line reopens the stop")
check(not ns.guideState.stops[si].acts[mj].manual, "manual tick removed for " .. manualKey)
for _, a in ipairs(ns.guideState.stops[si].acts) do if a.manual then ns.Guide.Toggle(a.key) end end

-- Pins only for stops still open; the waypoint follows the current one.
local open = 0
for _, s in ipairs(ns.guideState.stops) do if not s.done then open = open + 1 end end
check(#ns.stops == open, "one pin per open stop")
check(W.waypoint ~= nil, "waypoint set")

-- Going into the dungeon ticks the last step.
W.instance = "Blackrock Depths"; W.fire("PLAYER_ENTERING_WORLD")
check(ns.guideState.stops[#ns.guideState.stops].done, "entering BRD ticks the last step")
W.instance = nil

-- A party: answers right after a guide is built feed a new route.
W.party = { { name = "Bob", class = "WARRIOR", level = 50 }, { name = "Cid", class = "WARLOCK", level = 50 } }
W.fire("GROUP_ROSTER_UPDATE")
check(ns.partyCount == 3, "party of three seen")
ns.Select("brd")
check(ns.db.char.guide.members == 3, "new guide planned for three")
local idx
for i, q in ipairs(ns.dungeonById.brd.quests) do if q.n == "The Good Stuff" then idx = i end end
W.fire("CHAT_MSG_ADDON", "DQF1", "S|brd|warrior|none|50|" .. idx .. "h", "PARTY", "Bob-Realm")
check(ns.State.party.Bob and ns.State.party.Bob.status["The Good Stuff"] == "have", "Bob's state decoded")
W.party = {}; W.fire("GROUP_ROSTER_UPDATE")

-- QuestieDB present: quest giver spawns become pin positions (LBRS at 57).
_G.LibQuestieDB = { Enum = { factionRaceMasks = { Alliance = 77, Horde = 178 } } }
_G.QuestDB = {
  IdsByName = function(n) if n == "Put Her Down" then return { 4701 } end end,
  Get = function(id, key)
    if id == 4701 and key == "startedBy" then return { { 9562 } } end
    if key == "requiredRaces" then return 77 end
  end,
}
_G.NpcDB = { Get = function(id, key) if id == 9562 and key == "spawns" then return { [46] = { { 85.0, 69.0 } } } end end }
W.player.level = 57
SlashCmdList.DUNGEONQUESTSFOREVER("lbrs")
local found
for _, p in ipairs(ns.stops) do for _, l in ipairs(p.lines) do if l:find("Put Her Down") then found = p.pos end end end
check(found and found.mapId == 1428 and math.abs(found.x - 0.85) < 1e-6, "QuestieDB spawn used for Put Her Down")
_G.LibQuestieDB, _G.QuestDB, _G.NpcDB = nil, nil, nil

-- Slash commands and the addon compartment.
SlashCmdList.DUNGEONQUESTSFOREVER("pins")
check(ns.db.char.pins == false and #W.pins == 0, "/dqf pins turns pins off")
SlashCmdList.DUNGEONQUESTSFOREVER("pins")
SlashCmdList.DUNGEONQUESTSFOREVER("minimap"); SlashCmdList.DUNGEONQUESTSFOREVER("minimap")
_G.DungeonQuestsForever_OnAddonCompartmentClick(nil, "LeftButton")
SlashCmdList.DUNGEONQUESTSFOREVER("reset")
check(ns.guideState == nil, "/dqf reset clears the guide")

-- Every dungeon, both factions, three levels: build, evaluate and draw without errors.
ns.UI.Show()
local errors = 0
for _, fac in ipairs({ "Alliance", "Horde" }) do
  W.player.faction = fac
  for _, d in ipairs(ns.Data.dungeons) do
    for _, lvl in ipairs({ 20, 45, 60 }) do
      W.player.level = lvl
      local ok, err = pcall(function() ns.Select(d.id); ns.UI.ShowGuide(); ns.UI.ShowList() end)
      if not ok or not ns.guideState or ns.guideState.dungeon.id ~= d.id then
        errors = errors + 1; print("error in " .. d.id .. " " .. fac .. ": " .. tostring(err))
      end
    end
  end
end
check(errors == 0, "all dungeons build and draw without errors")
for _, m in ipairs(W.chat or {}) do if m:find("went wrong") then print(m); fail = fail + 1 end end

print(string.format("\n%d passed, %d failed", pass, fail))
os.exit(fail == 0 and 0 or 1)
