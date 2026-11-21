-- Look and feel: colours, fonts, drawn borders, and each dungeon's loading-screen art from the game files.
local ADDON, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.BG = { 0.055, 0.047, 0.040, 0.97 }      -- window
Theme.PANEL = { 0.085, 0.072, 0.060, 0.95 }   -- sidebar, group headers
Theme.ROW = { 0.10, 0.085, 0.07, 0.55 }       -- table rows
Theme.LINE = { 0.55, 0.43, 0.22, 0.85 }       -- gold hairlines
Theme.LINE_SOFT = { 0.55, 0.43, 0.22, 0.30 }
Theme.SELECT = { 0.80, 0.60, 0.20, 0.22 }
Theme.GOLD = "|cffffc94a"
Theme.GOLD_DIM = "|cffc9a35b"
Theme.WHITE = "|cffe8e2d6"
Theme.GREY = "|cff8a8478"
Theme.GREEN = "|cff6fd28a"
Theme.ORANGE = "|cffe8743b"
Theme.FONT = "Fonts\\FRIZQT__.TTF"

-- Loading screens (game FileDataIDs): { file, crop {left, right, top, bottom} of the picture inside the file,
-- the picture's real width/height }. Classic screens are 4:3 files, Forever's own are 16:9.
local CLASSIC = { { 0.03, 0.97, 0.20, 0.80 }, 2.089 }
local FOREVER = { { 0.00, 1.00, 0.1591, 0.8385 }, 2.615 }
local SCARLET = { { 0.02, 0.98, 0.21, 0.87 }, 1.939 }
local SPIRE = { { 0.02, 0.98, 0.27, 0.81 }, 2.370 }
local ART = {
  hot = { 7963781, FOREVER }, rfc = { 131862, CLASSIC }, rol = { 7963782, FOREVER }, wc = { 131882, CLASSIC },
  dm = { 131833, CLASSIC }, sfk = { 131869, CLASSIC }, bfd = { 131823, CLASSIC }, stocks = { 131870, CLASSIC },
  esw = { 7963777, FOREVER }, dal = { 7963775, FOREVER }, gnomer = { 131841, CLASSIC }, rfk = { 131865, CLASSIC },
  smgy = { 131852, CLASSIC }, smlib = { 643908, SCARLET }, smarm = { 643908, SCARLET }, smcath = { 645156, SCARLET },
  dc = { 7963741, FOREVER }, rfd = { 131864, CLASSIC }, ks = { 7963780, FOREVER }, uld = { 131876, CLASSIC },
  zf = { 131885, CLASSIC }, mara = { 131850, CLASSIC }, ap = { 7963734, FOREVER }, st = { 131872, CLASSIC },
  brd = { 131824, CLASSIC }, dme = { 131835, CLASSIC }, dmw = { 131835, CLASSIC }, dmn = { 131835, CLASSIC },
  lbrs = { 131825, CLASSIC }, ubrs = { 1035275, SPIRE }, bmh = { 7963784, FOREVER }, scholo = { 131868, CLASSIC },
  sht = { 7963783, FOREVER }, stratl = { 131871, CLASSIC }, stratu = { 131871, CLASSIC },
}

-- Put dungeon `id`'s art on `tex`, cropped from the middle to fill a w x h box without stretching.
function Theme.SetArt(tex, id, w, h)
  local a = ART[id]
  if not a then tex:SetColorTexture(0.15, 0.12, 0.09, 1); return end
  tex:SetTexture(a[1])
  local c, have = a[2][1], a[2][2]
  local l, r, t, b = c[1], c[2], c[3], c[4]
  local want = w / h
  if want > have then            -- box is wider than the picture: trim top and bottom
    local keep, mid = (b - t) * have / want, (t + b) / 2
    t, b = mid - keep / 2, mid + keep / 2
  else                           -- box is narrower: trim the sides
    local keep, mid = (r - l) * want / have, (l + r) / 2
    l, r = mid - keep / 2, mid + keep / 2
  end
  tex:SetTexCoord(l, r, t, b)
end

function Theme.Font(fs, size, flags)
  local font, _, fl = fs:GetFont()
  fs:SetFont(font or Theme.FONT, size, flags or fl)
end

function Theme.Fill(parent, color, layer)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetAllPoints()
  t:SetColorTexture(color[1], color[2], color[3], color[4])
  return t
end

-- 1px border drawn with four textures.
function Theme.Border(f, color, inset)
  color, inset = color or Theme.LINE, inset or 0
  local function edge(p1, p2, horizontal)
    local t = f:CreateTexture(nil, "BORDER")
    t:SetColorTexture(color[1], color[2], color[3], color[4])
    t:SetPoint(p1, inset * ((p1:find("LEFT") and 1) or -1), inset * ((p1:find("TOP") and -1) or 1))
    t:SetPoint(p2, inset * ((p2:find("LEFT") and 1) or -1), inset * ((p2:find("TOP") and -1) or 1))
    if horizontal then t:SetHeight(1) else t:SetWidth(1) end
    return t
  end
  f.borderT = edge("TOPLEFT", "TOPRIGHT", true)
  f.borderB = edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
  f.borderL = edge("TOPLEFT", "BOTTOMLEFT", false)
  f.borderR = edge("TOPRIGHT", "BOTTOMRIGHT", false)
end

function Theme.HLine(parent, color)
  local t = parent:CreateTexture(nil, "BORDER")
  t:SetHeight(1)
  color = color or Theme.LINE_SOFT
  t:SetColorTexture(color[1], color[2], color[3], color[4])
  return t
end

-- Vertical fade from `top` to `bottom` colour (r, g, b, a tables); quietly flat if gradients aren't available.
function Theme.Gradient(tex, top, bottom)
  tex:SetColorTexture(1, 1, 1, 1)
  local ok = false
  if CreateColor and tex.SetGradient then
    ok = pcall(tex.SetGradient, tex, "VERTICAL", CreateColor(bottom[1], bottom[2], bottom[3], bottom[4]),
      CreateColor(top[1], top[2], top[3], top[4]))
  end
  if not ok then tex:SetColorTexture(bottom[1], bottom[2], bottom[3], (top[4] + bottom[4]) / 2) end
end

return Theme
