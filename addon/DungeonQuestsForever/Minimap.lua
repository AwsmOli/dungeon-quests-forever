-- Minimap button. Uses LibDBIcon when another addon loaded it (minimap skins collect those buttons),
-- otherwise draws its own button you can drag around the minimap. Also adds an Addon Compartment entry.
local ADDON, ns = ...

local Minimap_ = {}
ns.Minimap = Minimap_

local ICON = "Interface\\Icons\\INV_Misc_Book_09"
local button

local function OnClick(_, mouse)
  if mouse == "RightButton" then
    ns.db.char.pins = not ns.db.char.pins
    ns.Print("map pins " .. (ns.db.char.pins and "on" or "off"))
    ns.Refresh(true)
  else
    ns.UI.Toggle()
  end
end

local function Tooltip(tt)
  tt:AddLine("Dungeon Quests")
  local g = ns.Guide.Current()
  if g and ns.guideState then
    local s = ns.guideState
    tt:AddLine(s.dungeon.name .. string.format("  %d/%d steps", s.doneCount, s.total), 1, 1, 1)
    local cur = s.current and s.stops[s.current]
    if cur then
      tt:AddLine("Next: " .. cur.title, 1, 0.82, 0)
      for _, a in ipairs(cur.acts) do if not a.done then tt:AddLine("  " .. ns.UI.ActText(a), 0.9, 0.9, 0.9); break end end
    end
  else
    tt:AddLine("Pick a dungeon to get a step-by-step guide.", 1, 1, 1)
  end
  tt:AddLine(" ")
  tt:AddLine("|cffffd100Click|r open  |cffffd100Right-click|r map pins on/off", 0.8, 0.8, 0.8)
end

---------------------------------------------------------------------------
-- Own button (no LibDBIcon)
---------------------------------------------------------------------------
local function Place(b)
  local angle = math.rad(ns.db.char.minimap.angle or 210)
  local r = (Minimap:GetWidth() / 2) + 5
  b:ClearAllPoints()
  b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
end

local function OwnButton()
  local b = CreateFrame("Button", "DungeonQuestsForeverMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetSize(20, 20); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); bg:SetPoint("TOPLEFT", 7, -5)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18); icon:SetTexture(ICON); icon:SetPoint("TOPLEFT", 7, -6)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetSize(53, 53); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetPoint("TOPLEFT")
  b:SetScript("OnClick", OnClick)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT"); Tooltip(GameTooltip); GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(s)
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local scale = Minimap:GetEffectiveScale()
      ns.db.char.minimap.angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
      Place(s)
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  Place(b)
  return b
end

function Minimap_.Init()
  ns.db.char.minimap = ns.db.char.minimap or { hide = false, angle = 210 }
  local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
  local DBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
  if LDB and DBIcon then
    local obj = LDB:NewDataObject("DungeonQuestsForever", {
      type = "launcher", text = "Dungeon Quests", icon = ICON,
      OnClick = OnClick, OnTooltipShow = Tooltip,
    })
    DBIcon:Register("DungeonQuestsForever", obj, ns.db.char.minimap)
    Minimap_.lib = DBIcon
  else
    button = OwnButton()
    if ns.db.char.minimap.hide then button:Hide() end
  end
end

function Minimap_.SetShown(show)
  ns.db.char.minimap.hide = not show
  if Minimap_.lib then
    if show then Minimap_.lib:Show("DungeonQuestsForever") else Minimap_.lib:Hide("DungeonQuestsForever") end
  elseif button then
    if show then button:Show() else button:Hide() end
  end
end

-- Addon Compartment (the addons menu by the minimap), named in the TOC.
function DungeonQuestsForever_OnAddonCompartmentClick(_, mouse) OnClick(nil, mouse) end

return Minimap_
