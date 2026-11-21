-- Party sync: members running the addon tell each other which of the selected dungeon's quests they
-- already have or have done, plus class, level and teleport gadget, so the party plan is right.
local ADDON, ns = ...

local Comms = {}
ns.Comms = Comms

local PREFIX = "DQF1"
local CODE = { done = "d", have = "h", ready = "r", low = "l" }
local DECODE = { d = "done", h = "have", r = "ready", l = "low" }

local function Send(msg)
  if not IsInGroup or not IsInGroup() then return end
  local channel = (IsInRaid and IsInRaid()) and "RAID" or "PARTY"
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
  elseif SendAddonMessage then SendAddonMessage(PREFIX, msg, channel) end
end

function Comms.Init()
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
  elseif RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end
end

-- "S|<dungeon>|<class>|<gadget>|<level>|<i><code>,<i><code>..." (only quests that aren't plain to-do)
function Comms.Encode(d, me)
  local parts = {}
  for i, q in ipairs(d.quests) do
    if ns.Engine.ForFaction(q, me.faction) then
      local c = CODE[ns.State.Status(q, me.level)]
      if c then parts[#parts + 1] = i .. c end
    end
  end
  return table.concat({ "S", d.id, me.cls, me.eng or "none", tostring(me.level or 0), table.concat(parts, ",") }, "|")
end

function Comms.Decode(msg)
  local kind, id, cls, eng, level, list = strsplit("|", msg)
  if kind ~= "S" then return kind, id end
  local d = ns.dungeonById[id]
  if not d then return nil end
  local status = {}
  for item in string.gmatch(list or "", "[^,]+") do
    local i, c = item:match("^(%d+)(%a)$")
    local q = i and d.quests[tonumber(i)]
    if q and DECODE[c] then status[q.n] = DECODE[c] end
  end
  return "S", id, { cls = cls, eng = eng, level = tonumber(level), status = status }
end

function Comms.SendState()
  local d = ns.Selected and ns.Selected()
  if d then Send(Comms.Encode(d, ns.State.Player())) end
end

function Comms.Request()
  local d = ns.Selected and ns.Selected()
  if d then Send("R|" .. d.id) end
end

function Comms.OnMessage(prefix, msg, _, sender)
  if prefix ~= PREFIX or not msg then return end
  local name = Ambiguate and Ambiguate(sender, "none") or sender
  if name == UnitName("player") then return end
  local kind, id, info = Comms.Decode(msg)
  if kind == "R" then
    -- Someone selected a dungeon: answer with our state for it.
    local d = ns.dungeonById[id]
    if d then Send(Comms.Encode(d, ns.State.Player())) end
  elseif kind == "S" and info then
    info.dungeon, info.at = id, GetTime and GetTime() or 0
    ns.State.party[name] = info
    if ns.OnPartyState then ns.OnPartyState(id) end
  end
end

return Comms
