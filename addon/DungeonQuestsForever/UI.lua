-- The window: a header, a sidebar, a dungeon table with loading-screen art, and the step-by-step guide.
local ADDON, ns = ...

local UI = {}
ns.UI = UI

local T = ns.Theme
local W, H = 1000, 620
local HEADER, SIDE, FOOT = 70, 196, 24
local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local TEX_BOX, TEX_CHECK = "Interface\\Buttons\\UI-CheckBox-Up", "Interface\\Buttons\\UI-CheckBox-Check"
local TEX_DONE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local TEX_CURRENT = "Interface\\GossipFrame\\AvailableQuestIcon"
-- The version lives in the TOC only.
local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
local VERSION = (GetMeta and GetMeta(ADDON or "DungeonQuestsForever", "Version")) or "dev"

local frame, side, listView, guideView
local view = "list"
local collapsed, search, sortKey = {}, "", "all"
-- Stops the player opened or closed by hand. Finished stops fold up unless opened here.
local stopFold = {}

local BANDS = { { 1, 19, "Levels 10 - 19" }, { 20, 29, "Levels 20 - 29" }, { 30, 39, "Levels 30 - 39" },
  { 40, 49, "Levels 40 - 49" }, { 50, 60, "Levels 50 - 60" } }

---------------------------------------------------------------------------
-- Small building blocks
---------------------------------------------------------------------------
local function FS(parent, size, justify)
  local f = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  T.Font(f, size or 12)
  f:SetJustifyH(justify or "LEFT")
  f:SetWordWrap(true)
  f:SetTextColor(1, 1, 1)
  return f
end

local function Minutes(m) return (m < 1) and "<1 min" or string.format("~%d min", math.floor(m + 0.5)) end

function UI.ActText(a)
  if a.a == "enter" then return "Go in" end
  local verb = (a.a == "take" and "Pick up") or (a.a == "turnin" and "Turn in") or "Do"
  return verb .. " " .. a.q
end

-- Flat button: dark fill, gold hairline, light text.
local function Flat(parent, text, w, h, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h or 24)
  b.bg = T.Fill(b, T.PANEL)
  T.Border(b, T.LINE)
  b.text = FS(b, 12, "CENTER")
  b.text:SetPoint("CENTER")
  b.text:SetText(T.WHITE .. text .. "|r")
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints(); hl:SetColorTexture(T.SELECT[1], T.SELECT[2], T.SELECT[3], T.SELECT[4])
  b:SetScript("OnClick", onClick)
  return b
end

-- Tooltip lines: the first is the title; missing or empty entries are skipped.
local function Tip(region, lines)
  region:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local first = true
    for i = 1, 6 do
      local l = lines[i]
      if l and l ~= "" then
        if first then GameTooltip:AddLine(l, 1, 0.82, 0); first = false else GameTooltip:AddLine(l, 1, 1, 1, true) end
      end
    end
    GameTooltip:Show()
  end)
  region:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- A scroll area filling `parent` below `top` px.
local function Scroller(parent, top)
  local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 0, -top)
  sf:SetPoint("BOTTOMRIGHT", -22, 0)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(W - SIDE - 60, 10)
  sf:SetScrollChild(child)
  child.sf = sf
  return child
end

-- A pool of reusable frames.
local function Pool(parent, make)
  local p = { items = {}, used = 0 }
  function p:Reset() for _, it in ipairs(self.items) do it:Hide() end; self.used = 0 end
  function p:Get()
    self.used = self.used + 1
    local it = self.items[self.used]
    if not it then it = make(parent); self.items[self.used] = it end
    it:ClearAllPoints()
    it:Show()
    return it
  end
  return p
end

---------------------------------------------------------------------------
-- Window, header, sidebar, footer
---------------------------------------------------------------------------
local function Header(f)
  local h = CreateFrame("Frame", nil, f)
  h:SetPoint("TOPLEFT", 1, -1); h:SetPoint("TOPRIGHT", -1, -1); h:SetHeight(HEADER)
  local solid = h:CreateTexture(nil, "BACKGROUND", nil, -1)
  solid:SetAllPoints(); solid:SetColorTexture(T.BG[1], T.BG[2], T.BG[3], 1)
  -- The selected dungeon's loading screen on the right, fading into the dark on its left.
  h.art = h:CreateTexture(nil, "BACKGROUND")
  h.art:SetPoint("TOPRIGHT"); h.art:SetPoint("BOTTOMRIGHT"); h.art:SetWidth(620)
  h.art:SetAlpha(0.6)
  h.fade = h:CreateTexture(nil, "BORDER")
  h.fade:SetPoint("TOPLEFT", h.art, "TOPLEFT"); h.fade:SetPoint("BOTTOMLEFT", h.art, "BOTTOMLEFT"); h.fade:SetWidth(280)
  h.fade:SetColorTexture(T.BG[1], T.BG[2], T.BG[3], 0.6)
  if h.fade.SetGradient and CreateColor then
    h.fade:SetColorTexture(1, 1, 1, 1)
    local ok = pcall(h.fade.SetGradient, h.fade, "HORIZONTAL", CreateColor(T.BG[1], T.BG[2], T.BG[3], 1), CreateColor(T.BG[1], T.BG[2], T.BG[3], 0))
    if not ok then h.fade:SetColorTexture(T.BG[1], T.BG[2], T.BG[3], 0.6) end
  end

  local emblem = h:CreateTexture(nil, "ARTWORK")
  emblem:SetSize(50, 50); emblem:SetPoint("LEFT", 14, 0); emblem:SetTexture(ICON)
  if emblem.SetMask then pcall(emblem.SetMask, emblem, "Interface\\CharacterFrame\\TempPortraitAlphaMask") end

  local title = FS(h, 24); title:SetPoint("TOPLEFT", emblem, "TOPRIGHT", 12, -4); title:SetText(T.WHITE .. "Dungeon Quests|r")
  local sub = FS(h, 10); sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -4); sub:SetText(T.GOLD_DIM .. "F O R E V E R    Q U E S T    G U I D E|r")
  local line = T.HLine(h, T.LINE); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")

  local close = Flat(h, "x", 26, 26, function() f:Hide() end)
  close:SetPoint("TOPRIGHT", -12, -12)
  h:EnableMouse(true); h:RegisterForDrag("LeftButton")
  h:SetScript("OnDragStart", function() f:StartMoving() end)
  h:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  return h
end

local function NavButton(parent, icon, label, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(SIDE - 20, 28)
  b.sel = T.Fill(b, T.SELECT, "BACKGROUND"); b.sel:Hide()
  b.bar = b:CreateTexture(nil, "ARTWORK"); b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT"); b.bar:SetWidth(2)
  b.bar:SetColorTexture(1, 0.79, 0.29, 1); b.bar:Hide()
  local hl = b:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
  if icon then
    b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetSize(18, 18); b.icon:SetPoint("LEFT", 8, 0)
    b.icon:SetTexture(icon); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  b.text = FS(b, 13); b.text:SetPoint("LEFT", icon and 32 or 10, 0); b.text:SetPoint("RIGHT", -28, 0)
  b.count = FS(b, 11, "RIGHT"); b.count:SetPoint("RIGHT", -8, 0)
  b.text:SetText(T.WHITE .. label .. "|r")
  b:SetScript("OnClick", onClick)
  function b:SetSelected(on) if on then self.sel:Show(); self.bar:Show() else self.sel:Hide(); self.bar:Hide() end end
  return b
end

local function Check(parent, label, get, set)
  local c = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  c:SetSize(22, 22)
  c.label = FS(parent, 12); c.label:SetPoint("LEFT", c, "RIGHT", 2, 1); c.label:SetText(T.WHITE .. label .. "|r")
  c:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
  c.refresh = function() c:SetChecked(get()) end
  return c
end

local function Sidebar(f)
  local s = CreateFrame("Frame", nil, f)
  s:SetPoint("TOPLEFT", 1, -HEADER - 1); s:SetPoint("BOTTOMLEFT", 1, FOOT); s:SetWidth(SIDE)
  T.Fill(s, T.PANEL)
  local edge = s:CreateTexture(nil, "BORDER"); edge:SetPoint("TOPRIGHT"); edge:SetPoint("BOTTOMRIGHT"); edge:SetWidth(1)
  edge:SetColorTexture(T.LINE_SOFT[1], T.LINE_SOFT[2], T.LINE_SOFT[3], T.LINE_SOFT[4])

  local icon = s:CreateTexture(nil, "ARTWORK"); icon:SetSize(30, 30); icon:SetPoint("TOPLEFT", 14, -16); icon:SetTexture(ICON)
  local t = FS(s, 15); t:SetPoint("LEFT", icon, "RIGHT", 8, 0); t:SetText(T.GOLD .. "Dungeon Quests|r")

  s.all = NavButton(s, "Interface\\Icons\\INV_Misc_Bone_HumanSkull_01", "All dungeons", function() UI.ShowList() end)
  s.all:SetPoint("TOPLEFT", 10, -62)
  s.guide = NavButton(s, "Interface\\Icons\\INV_Misc_Note_01", "My guide", function() if ns.Guide.Current() then UI.ShowGuide() end end)
  s.guide:SetPoint("TOPLEFT", s.all, "BOTTOMLEFT", 0, -4)
  local sep = T.HLine(s); sep:SetPoint("TOPLEFT", s.guide, "BOTTOMLEFT", 0, -10); sep:SetPoint("RIGHT", -10, 0)

  s.bands = {}
  local prev = s.guide
  for i, b in ipairs(BANDS) do
    local nb = NavButton(s, nil, b[3], function() UI.ShowList(); UI.JumpTo(i) end)
    nb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, (i == 1) and -20 or -2)
    s.bands[i] = nb
    prev = nb
  end

  s.who = FS(s, 11); s.who:SetPoint("BOTTOMLEFT", 14, 92); s.who:SetPoint("RIGHT", -10, 0)
  s.pins = Check(s, "Map pins", function() return ns.db.char.pins end, function(v) ns.db.char.pins = v; ns.Refresh(true) end)
  s.pins:SetPoint("BOTTOMLEFT", 10, 62)
  s.way = Check(s, "Auto waypoint", function() return ns.db.char.autoWaypoint end, function(v) ns.db.char.autoWaypoint = v end)
  s.way:SetPoint("BOTTOMLEFT", 10, 38)
  s.opt = Check(s, "Optional quests", function() return ns.db.char.optional end, function(v)
    ns.db.char.optional = v
    local g = ns.Guide.Current()
    if g then ns.Guide.Build(ns.dungeonById[g.dungeon]) end
    ns.Refresh(true)
  end)
  s.opt:SetPoint("BOTTOMLEFT", 10, 14)
  return s
end

function UI.Create()
  if frame then return end
  local f = CreateFrame("Frame", "DungeonQuestsForeverFrame", UIParent)
  frame = f
  f:SetSize(W, H)
  f:SetPoint("CENTER")
  f:SetFrameStrata("HIGH")
  f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true)
  f:SetScale(ns.db and ns.db.char.scale or 1)
  f:Hide()
  tinsert(UISpecialFrames, "DungeonQuestsForeverFrame")
  T.Fill(f, T.BG)
  T.Border(f, T.LINE)

  f.header = Header(f)
  side = Sidebar(f)

  local made = FS(f, 10); made:SetPoint("BOTTOMLEFT", 14, 7); made:SetText(T.GREY .. "made by AwsmOli|r")
  local ver = FS(f, 10, "RIGHT"); ver:SetPoint("BOTTOMRIGHT", -14, 7); ver:SetText(T.GREY .. "Version " .. VERSION .. "|r")
  local footLine = T.HLine(f); footLine:SetPoint("BOTTOMLEFT", 1, FOOT); footLine:SetPoint("BOTTOMRIGHT", -1, FOOT)

  local content = CreateFrame("Frame", nil, f)
  content:SetPoint("TOPLEFT", SIDE + 18, -HEADER - 14)
  content:SetPoint("BOTTOMRIGHT", -14, FOOT + 8)
  f.content = content
  listView = UI.MakeList(content)
  guideView = UI.MakeGuide(content)
  guideView:Hide()
end

function UI.Show() UI.Create(); frame:Show(); ns.Refresh(true) end
function UI.Toggle() UI.Create(); if frame:IsShown() then frame:Hide() else UI.Show() end end
function UI.ShowList() view = "list"; UI.Render() end
function UI.ShowGuide() view = "guide"; UI.Render() end
function UI.IsShown() return frame and frame:IsShown() end
function UI.SetScale(s) if frame then frame:SetScale(s) end end

---------------------------------------------------------------------------
-- Dungeon table
---------------------------------------------------------------------------
-- { header, x offset, sort key }
local COLS = { { "Dungeon", 0, "name" }, { "Level", 322, "level" }, { "All quests", 392, "all" }, { "Zone", 480, "zone" },
  { "Quests", 640, nil }, { "", 702, nil } }

local function ZoneOf(d) local h = ns.Data.hubs[d.entrance]; return h and h.zone or "" end

function UI.MakeList(parent)
  local v = CreateFrame("Frame", nil, parent)
  v:SetAllPoints()
  local skull = v:CreateTexture(nil, "ARTWORK"); skull:SetSize(34, 34); skull:SetPoint("TOPLEFT", 0, 0)
  skull:SetTexture("Interface\\Icons\\INV_Misc_Bone_HumanSkull_01")
  local t = FS(v, 18); t:SetPoint("TOPLEFT", skull, "TOPRIGHT", 10, -1); t:SetText(T.GOLD .. "Dungeons|r")
  v.sub = FS(v, 11); v.sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -3); v.sub:SetWidth(460)

  local box = CreateFrame("EditBox", nil, v, "InputBoxTemplate")
  box:SetSize(220, 22); box:SetPoint("TOPRIGHT", -10, -4); box:SetAutoFocus(false)
  box.hint = FS(box, 11); box.hint:SetPoint("LEFT", 4, 0); box.hint:SetText(T.GREY .. "Search name or zone...|r")
  box:SetScript("OnTextChanged", function(self)
    search = (self:GetText() or ""):lower()
    if search == "" then self.hint:Show() else self.hint:Hide() end
    UI.Render()
  end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  v.search = box

  -- Column headers (click to sort).
  local hdr = CreateFrame("Frame", nil, v)
  hdr:SetPoint("TOPLEFT", 0, -46); hdr:SetPoint("RIGHT", -22, 0); hdr:SetHeight(20)
  for _, c in ipairs(COLS) do
    local b = CreateFrame("Button", nil, hdr)
    b:SetPoint("LEFT", c[2] + 14, 0); b:SetSize(90, 20)
    b.text = FS(b, 10); b.text:SetPoint("LEFT"); b.text:SetText(T.GOLD_DIM .. c[1]:upper() .. "|r")
    if c[3] then b:SetScript("OnClick", function() sortKey = c[3]; UI.Render() end) end
  end
  local hl = T.HLine(hdr, T.LINE_SOFT); hl:SetPoint("BOTTOMLEFT"); hl:SetPoint("BOTTOMRIGHT")

  v.content = Scroller(v, 70)
  v.groups = Pool(v.content, function(p)
    local g = CreateFrame("Button", nil, p)
    g:SetHeight(32)
    T.Fill(g, T.PANEL); T.Border(g, T.LINE_SOFT)
    g.chev = FS(g, 13); g.chev:SetPoint("LEFT", 12, 0)
    g.text = FS(g, 15); g.text:SetPoint("LEFT", 32, 0)
    g.count = FS(g, 11, "RIGHT"); g.count:SetPoint("RIGHT", -14, 0)
    return g
  end)
  v.rows = Pool(v.content, function(p)
    local r = CreateFrame("Button", nil, p)
    r:SetHeight(52)
    r.bg = T.Fill(r, T.ROW)
    r.art = r:CreateTexture(nil, "ARTWORK"); r.art:SetSize(118, 50); r.art:SetPoint("LEFT", 1, 0)
    -- Fade the picture's right edge into the row.
    r.fade = r:CreateTexture(nil, "OVERLAY"); r.fade:SetPoint("TOPRIGHT", r.art); r.fade:SetPoint("BOTTOMRIGHT", r.art); r.fade:SetWidth(40)
    r.fade:SetColorTexture(T.ROW[1], T.ROW[2], T.ROW[3], 0)
    if r.fade.SetGradient and CreateColor then
      r.fade:SetColorTexture(1, 1, 1, 1)
      local ok = pcall(r.fade.SetGradient, r.fade, "HORIZONTAL", CreateColor(0.10, 0.085, 0.07, 0), CreateColor(0.10, 0.085, 0.07, 1))
      if not ok then r.fade:SetColorTexture(T.ROW[1], T.ROW[2], T.ROW[3], 0) end
    end
    r.active = r:CreateTexture(nil, "OVERLAY"); r.active:SetPoint("TOPLEFT"); r.active:SetPoint("BOTTOMLEFT"); r.active:SetWidth(3)
    r.active:SetColorTexture(1, 0.79, 0.29, 1)
    r.name = FS(r, 15); r.name:SetPoint("LEFT", 134, 4); r.name:SetWidth(182); r.name:SetWordWrap(false)
    r.tag = FS(r, 10); r.tag:SetPoint("LEFT", 134, -13)
    r.level = FS(r, 13); r.level:SetPoint("LEFT", COLS[2][2] + 14, 0)
    r.all = FS(r, 13); r.all:SetPoint("LEFT", COLS[3][2] + 14, 0)
    r.zone = FS(r, 13); r.zone:SetPoint("LEFT", COLS[4][2] + 14, 0); r.zone:SetWidth(150); r.zone:SetWordWrap(false)
    r.quests = FS(r, 13); r.quests:SetPoint("LEFT", COLS[5][2] + 14, 0)
    r.map = CreateFrame("Button", nil, r); r.map:SetSize(24, 24); r.map:SetPoint("LEFT", COLS[6][2] + 14, 0)
    r.map.icon = r.map:CreateTexture(nil, "ARTWORK"); r.map.icon:SetAllPoints(); r.map.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    r.map.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(T.SELECT[1], T.SELECT[2], T.SELECT[3], T.SELECT[4])
    local line = T.HLine(r, T.LINE_SOFT); line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT")
    return r
  end)
  return v
end

-- Small hooks (also used by the tests).
function UI.SetSearch(text) search = (text or ""):lower(); UI.Render() end
function UI.SetSort(key) sortKey = key; UI.Render() end
function UI.ToggleBand(i) collapsed[i] = not collapsed[i]; UI.Render() end
function UI.VisibleRows() return listView and listView.rows.used or 0 end
-- Test hooks for the guide: the header frame of stop n, and how many step lines show.
function UI.GuideHeader(n) return guideView and guideView.heads.items[n] end
function UI.GuideLines() return guideView and guideView.lines.used or 0 end
function UI.GuideLine(i) return guideView and guideView.lines.items[i] end

local groupOffsets = {}
function UI.JumpTo(i)
  local y = groupOffsets[i]
  if y and listView then listView.content.sf:SetVerticalScroll(y) end
end

local function RenderList()
  local me = ns.State.Player()
  listView.sub:SetText(T.GREY .. string.format("Level %d %s. Pick a dungeon for a step-by-step pickup guide.",
    me.level, me.faction == "H" and "Horde" or "Alliance") .. "|r")
  local content, w = listView.content, listView.content:GetWidth()
  listView.groups:Reset(); listView.rows:Reset()
  local active = ns.Guide.Current()

  local entries = {}
  for _, e in ipairs(ns.SortedDungeons(me.faction)) do
    local d = e.d
    local hay = (d.name .. " " .. (d.aka or "") .. " " .. d.short .. " " .. ZoneOf(d)):lower()
    if search == "" or hay:find(search, 1, true) then entries[#entries + 1] = e end
  end
  if sortKey == "level" then table.sort(entries, function(a, b) return a.min < b.min or (a.min == b.min and a.d.name < b.d.name) end)
  elseif sortKey == "name" then table.sort(entries, function(a, b) return a.d.name < b.d.name end)
  elseif sortKey == "zone" then table.sort(entries, function(a, b)
    local za, zb = ZoneOf(a.d), ZoneOf(b.d)
    return za < zb or (za == zb and a.all < b.all)
  end) end

  local y = 0
  for bi, band in ipairs(BANDS) do
    local inBand = {}
    for _, e in ipairs(entries) do if e.all >= band[1] and e.all <= band[2] then inBand[#inBand + 1] = e end end
    side.bands[bi].count:SetText(T.GREY .. #inBand .. "|r")
    groupOffsets[bi] = y
    if #inBand > 0 then
      local g = listView.groups:Get()
      g:SetPoint("TOPLEFT", 0, -y); g:SetWidth(w)
      g.chev:SetText(T.GOLD_DIM .. (collapsed[bi] and ">" or "v") .. "|r")
      g.text:SetText(T.GOLD .. band[3] .. "|r")
      g.count:SetText(T.GREY .. #inBand .. (#inBand == 1 and " dungeon" or " dungeons") .. "|r")
      g:SetScript("OnClick", function() collapsed[bi] = not collapsed[bi]; UI.Render() end)
      y = y + 36
      if not collapsed[bi] then
        for _, e in ipairs(inBand) do
          local d = e.d
          local r = listView.rows:Get()
          r:SetPoint("TOPLEFT", 0, -y); r:SetWidth(w)
          T.SetArt(r.art, d.id, 118, 50)
          local have, total, low = ns.Guide.Progress(d, me)
          local ready, tooLow = me.level >= e.all, me.level < e.min
          r.name:SetText(((tooLow and T.GREY) or T.GOLD) .. d.name .. "|r")
          r.tag:SetText((d.isNew and (T.GREEN .. "NEW   |r") or "") .. (d.aka and (T.GREY .. d.aka .. "|r") or ""))
          r.level:SetText(T.WHITE .. d.range .. "|r")
          r.all:SetText((ready and T.GREEN or T.WHITE) .. e.all .. "|r")
          r.zone:SetText(T.WHITE .. ZoneOf(d) .. "|r")
          r.quests:SetText(total == 0 and (T.GREY .. "-|r") or (((have == total) and T.GREEN or T.WHITE) .. have .. " / " .. total .. "|r"))
          if active and active.dungeon == d.id then r.active:Show() else r.active:Hide() end
          r:SetScript("OnClick", function() ns.Select(d.id); UI.ShowGuide() end)
          Tip(r, { d.name .. (d.aka and (" (" .. d.aka .. ")") or ""), d.entranceNote,
            string.format("%d of %d quests done or in your log.", have, total),
            low > 0 and string.format("%d need a higher level.", low) or nil, T.GREY .. "Click for the step-by-step guide.|r" })
          r.map:SetScript("OnClick", function()
            local pos = ns.Map.VisitPosition({ hub = d.entrance, acts = {} })
            if not ns.Map.SetWaypoint({ title = d.name, pos = pos }) then ns.Print("no map position for " .. d.name) end
          end)
          Tip(r.map, { "Waypoint to the entrance", d.entranceNote })
          y = y + 52
        end
      end
      y = y + 6
    end
  end
  content:SetHeight(math.max(y, 10))
end

---------------------------------------------------------------------------
-- Guide
---------------------------------------------------------------------------
function UI.MakeGuide(parent)
  local v = CreateFrame("Frame", nil, parent)
  v:SetAllPoints()
  local banner = CreateFrame("Frame", nil, v)
  banner:SetPoint("TOPLEFT"); banner:SetPoint("TOPRIGHT", -22, 0); banner:SetHeight(118)
  v.art = banner:CreateTexture(nil, "BACKGROUND"); v.art:SetAllPoints()
  local shade = banner:CreateTexture(nil, "BORDER"); shade:SetAllPoints()
  T.Gradient(shade, { 0, 0, 0, 0.05 }, { T.BG[1], T.BG[2], T.BG[3], 0.95 })
  T.Border(banner, T.LINE_SOFT)
  v.title = FS(banner, 22); v.title:SetPoint("BOTTOMLEFT", 16, 32)
  v.sub = FS(banner, 12); v.sub:SetPoint("BOTTOMLEFT", 16, 14); v.sub:SetPoint("RIGHT", -16, 0)
  v.bar = CreateFrame("StatusBar", nil, banner)
  v.bar:SetPoint("BOTTOMLEFT", 1, 1); v.bar:SetPoint("BOTTOMRIGHT", -1, 1); v.bar:SetHeight(4)
  v.bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8"); v.bar:SetStatusBarColor(1, 0.79, 0.29); v.bar:SetMinMaxValues(0, 1)

  v.back = Flat(v, "< All dungeons", 120, 24, function() UI.ShowList() end)
  v.back:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 0, -10)
  v.way = Flat(v, "Waypoint to next", 130, 24, function()
    local cur
    for _, p in ipairs(ns.stops or {}) do if p.next then cur = p end end
    if not ns.Map.SetWaypoint(cur) then ns.Print("no map position for the next step") end
  end)
  v.way:SetPoint("LEFT", v.back, "RIGHT", 8, 0)
  v.rebuild = Flat(v, "New route", 100, 24, function()
    local g = ns.Guide.Current()
    if g then ns.Guide.Build(ns.dungeonById[g.dungeon]); ns.Refresh(true) end
  end)
  v.rebuild:SetPoint("LEFT", v.way, "RIGHT", 8, 0)
  v.note = FS(v, 11, "RIGHT"); v.note:SetPoint("LEFT", v.rebuild, "RIGHT", 12, 0); v.note:SetPoint("RIGHT", -24, 0)

  v.content = Scroller(v, 162)
  v.heads = Pool(v.content, function(p)
    local g = CreateFrame("Button", nil, p)
    g:SetHeight(34)
    g.bg = T.Fill(g, T.PANEL); T.Border(g, T.LINE_SOFT)
    g.num = FS(g, 15, "CENTER"); g.num:SetPoint("LEFT", 6, 0); g.num:SetWidth(26)
    g.icon = g:CreateTexture(nil, "ARTWORK"); g.icon:SetSize(16, 16); g.icon:SetPoint("LEFT", 36, 0)
    g.text = FS(g, 14); g.text:SetPoint("LEFT", 58, 0); g.text:SetPoint("RIGHT", -170, 0)
    g.chev = FS(g, 13, "CENTER"); g.chev:SetPoint("RIGHT", -10, 0); g.chev:SetWidth(14)
    g.right = FS(g, 11, "RIGHT"); g.right:SetPoint("RIGHT", -30, 0)
    local hl = g:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
    return g
  end)
  v.lines = Pool(v.content, function(p)
    local r = CreateFrame("Button", nil, p)
    r.box = r:CreateTexture(nil, "ARTWORK"); r.box:SetSize(16, 16); r.box:SetPoint("TOPLEFT", 38, -3); r.box:SetTexture(TEX_BOX)
    r.check = r:CreateTexture(nil, "OVERLAY"); r.check:SetSize(16, 16); r.check:SetPoint("CENTER", r.box)
    r.text = FS(r, 13); r.text:SetPoint("TOPLEFT", 60, -4); r.text:SetPoint("RIGHT", -12, 0)
    r.detail = FS(r, 11); r.detail:SetPoint("TOPLEFT", r.text, "BOTTOMLEFT", 0, -2); r.detail:SetPoint("RIGHT", -12, 0)
    local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
    return r
  end)
  v.notes = Pool(v.content, function(p)
    local n = CreateFrame("Frame", nil, p)
    n.bg = T.Fill(n, { 0.12, 0.10, 0.07, 0.6 }); T.Border(n, T.LINE_SOFT)
    n.text = FS(n, 12); n.text:SetPoint("TOPLEFT", 12, -10); n.text:SetPoint("RIGHT", -12, 0)
    return n
  end)
  return v
end

local function RenderGuide()
  local st, g = ns.guideState, ns.Guide.Current()
  if not st or not g then view = "list"; return RenderList() end
  local d = st.dungeon
  local v = guideView
  T.SetArt(v.art, d.id, W - SIDE - 60, 118)
  v.title:SetText(T.WHITE .. d.name .. "|r" .. (d.isNew and (T.GREEN .. "  NEW|r") or ""))
  v.sub:SetText(T.GOLD_DIM .. string.format("Level %s  ·  %s  ·  %d of %d steps done  ·  %s %s", d.range, ZoneOf(d),
    st.doneCount, st.total, (g.mode == "split") and "split route" or "route", Minutes(g.total or 0)) .. "|r")
  v.bar:SetValue(st.total > 0 and (st.doneCount / st.total) or 1)
  if ns.partyCount and ns.partyCount ~= (g.members or 1) then
    v.note:SetText(T.ORANGE .. "Your party changed. New route plans for everyone.|r")
  else v.note:SetText("") end

  local content, w = v.content, v.content:GetWidth()
  v.heads:Reset(); v.lines:Reset(); v.notes:Reset()
  local y = 0
  local function Note(text)
    local n = v.notes:Get()
    n:SetPoint("TOPLEFT", 0, -y); n:SetWidth(w)
    n.text:SetText(text)
    local h = n.text:GetStringHeight() + 20
    n:SetHeight(h)
    y = y + h + 8
  end

  if g.mode == "split" and g.shares and #g.shares > 0 then
    local byFrom, parts = {}, {}
    for _, sh in ipairs(g.shares) do byFrom[sh.from] = (byFrom[sh.from] and (byFrom[sh.from] .. ", ") or "") .. sh.q end
    for who, qs in pairs(byFrom) do parts[#parts + 1] = T.GOLD_DIM .. who .. ":|r " .. T.WHITE .. qs .. "|r" end
    local meet = ns.Data.hubs[g.meet]
    Note(T.GOLD .. "Party plan|r  " .. T.WHITE .. "Everyone grabs their own pickups, then meets at " .. (meet and meet.name or g.meet) .. " to share.|r\n" .. table.concat(parts, "\n"))
  end

  for _, s in ipairs(st.stops) do
    local hdr = v.heads:Get()
    hdr:SetPoint("TOPLEFT", 0, -y); hdr:SetWidth(w)
    hdr.num:SetText((s.done and T.GREY or T.GOLD) .. s.n .. "|r")
    hdr.icon:SetTexture(s.done and TEX_DONE or (s.current and TEX_CURRENT or nil))
    hdr.text:SetText(((s.done and T.GREY) or (s.current and T.GOLD) or T.WHITE) .. s.title .. "|r")
    hdr.right:SetText(T.GREY .. ((s.via ~= "" and s.via ~= "Here") and (s.via .. "  " .. Minutes(s.min)) or "") .. "|r")
    if s.current then hdr.bg:SetColorTexture(0.20, 0.15, 0.07, 0.95) else hdr.bg:SetColorTexture(T.PANEL[1], T.PANEL[2], T.PANEL[3], T.PANEL[4]) end
    y = y + 36
    local foldKey = d.id .. ":" .. s.n .. ":" .. tostring(s.hub)
    local open = not s.done
    if stopFold[foldKey] ~= nil then open = stopFold[foldKey] end
    hdr.chev:SetText(T.GOLD_DIM .. (open and "v" or ">") .. "|r")
    hdr:SetScript("OnClick", function() stopFold[foldKey] = not open; UI.Render() end)
    Tip(hdr, { s.title, T.GREY .. (open and "Click to fold this stop." or "Click to open this stop, for example to untick a line.") .. "|r" })
    if open then
      local firstOpen = true
      for _, a in ipairs(s.acts) do
        local r = v.lines:Get()
        r:SetPoint("TOPLEFT", 0, -y); r:SetWidth(w)
        r.check:SetTexture(a.done and TEX_CHECK or nil)
        local isNext = s.current and not a.done and firstOpen
        if not a.done then firstOpen = false end
        r.text:SetText(((a.done and T.GREY) or (isNext and T.GOLD) or T.WHITE) .. UI.ActText(a) .. "|r")
        r.detail:SetText((a.t and a.t ~= "") and (T.GREY .. a.t .. "|r") or "")
        local h = r.text:GetStringHeight() + ((a.t and a.t ~= "") and (r.detail:GetStringHeight() + 2) or 0) + 10
        r:SetHeight(h)
        y = y + h
        if a.key ~= "enter" then
          r:SetScript("OnClick", function() ns.Guide.Toggle(a.key) end)
          local q = a.quest
          local hint
          if a.manual then hint = "Ticked by hand. Click to untick."
          elseif a.auto then hint = "Ticked from your quest log."
          else hint = "Click to tick this off by hand." end
          Tip(r, { a.q, q and q.start, q and q.note, T.GREY .. hint .. "|r" })
        else
          r:SetScript("OnClick", nil); Tip(r, { "Go in", d.entranceNote })
        end
      end
    end
    y = y + 6
  end

  local me = ns.State.Player()
  local inside = {}
  for _, q in ipairs(d.quests) do
    if q.cat == "inside_pickup" and ns.Engine.ForFaction(q, me.faction) and ns.Engine.IsLive(q) then
      local s = ns.State.Status(q, me.level)
      local mark = (s == "done" or s == "have" or s == "ready") and (T.GREEN .. "done  |r") or ""
      inside[#inside + 1] = mark .. T.WHITE .. q.n .. "|r  " .. T.GREY .. q.start .. "|r"
    end
  end
  if #inside > 0 then Note(T.GOLD .. "In the dungeon|r\n" .. table.concat(inside, "\n")) end
  content:SetHeight(math.max(y, 10))
end

---------------------------------------------------------------------------
-- Render
---------------------------------------------------------------------------
function UI.Render()
  if not frame or not frame:IsShown() then return end
  local me = ns.State.Player()
  local g = ns.Guide.Current()
  side.who:SetText(T.GREY .. me.name .. "  ·  level " .. me.level .. " " .. (me.faction == "H" and "Horde" or "Alliance") .. "|r")
  side.guide.count:SetText(g and (T.GOLD_DIM .. ns.dungeonById[g.dungeon].short .. "|r") or "")
  side.pins.refresh(); side.way.refresh(); side.opt.refresh()
  -- Header art: the guide's dungeon, or Blackrock Depths.
  T.SetArt(frame.header.art, g and g.dungeon or "brd", 620, HEADER)
  if view == "guide" and g then
    side.all:SetSelected(false); side.guide:SetSelected(true)
    listView:Hide(); guideView:Show(); RenderGuide()
  else
    view = "list"
    side.all:SetSelected(true); side.guide:SetSelected(false)
    guideView:Hide(); listView:Show(); RenderList()
  end
end

return UI
