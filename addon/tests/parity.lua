-- Prints one line per plan so it can be diffed against planner/tests/parity.js
package.path = "addon/DungeonQuestsForever/?.lua;" .. package.path
local D = dofile("addon/DungeonQuestsForever/Data.lua")
local E = dofile("addon/DungeonQuestsForever/Engine.lua")
E.Setup(D.hubs, D.boats)
local parties = {
  { { name = "M", cls = "mage", eng = "none" } },
  { { name = "W", cls = "warrior", eng = "none" } },
  { { name = "M", cls = "mage", eng = "none" }, { name = "W", cls = "warrior", eng = "none" }, { name = "P", cls = "priest", eng = "none" } },
  { { name = "M", cls = "mage", eng = "none" }, { name = "W", cls = "warrior", eng = "none" }, { name = "L", cls = "warlock", eng = "goblin" },
    { name = "D", cls = "druid", eng = "gnomish" }, { name = "R", cls = "rogue", eng = "none" } },
}
for _, d in ipairs(D.dungeons) do
  for _, f in ipairs({ "A", "H" }) do
    for pi, party in ipairs(parties) do
      for _, opt in ipairs({ false, true }) do
        local r = E.Plan(d, { faction = f, players = party, start = (f == "A") and "SW" or "ORG", includeOptional = opt })
        local hubs = {}
        for _, v in ipairs(r.group.visits) do hubs[#hubs + 1] = v.hub end
        local split = ""
        if r.mode == "split" then
          for _, p in ipairs(r.players) do
            local hs = {}
            for _, v in ipairs(p.visits) do hs[#hs + 1] = v.hub end
            split = split .. p.player.name .. ":" .. table.concat(hs, ",") .. ";"
          end
        end
        print(string.format("%s %s p%d o%s %s %.2f %s | %s", d.id, f, pi, tostring(opt), r.mode, r.total, table.concat(hubs, ","), split))
      end
    end
  end
end
