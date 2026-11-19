# Writing a dungeon group file

Each file in `planner/dungeons/` (for example `g1_barrens.py`) adds dungeons to the planner. `planner/data.py` loads every `*.py` here. Check your file on its own with:

```bash
python planner/check.py planner/dungeons/<your file>.py
```

It must print `no errors`. It then prints sample plans from the real planner: read them and make sure the routes make sense.

## File shape

```python
from qlib import hub, Q, UNCLEAR_T05

HUBS = {
    # Only places that aren't already in the table below. Reuse existing ids where they fit.
    "CROSSROADS": hub("The Crossroads", "The Barrens", "K", 56, 52, 4, 0),
}

DUNGEONS = [{
    "id": "wc", "name": "Wailing Caverns", "short": "WC", "range": "15-24", "entrance": "WC_ENTRANCE",
    "isNew": False,          # True only for dungeons new in Forever
    "aka": None,             # optional second name, e.g. "Dire Maul East"
    "entranceNote": "Where the entrance is, one sentence. Key or attunement needs.",
    "notes": ["Short Forever-specific facts: new/changed/removed quests, level changes, gotchas."],
    "sources": ["https://… urls you actually used"],
    "quests": [ Q(...), Q(...) ],
}]
```

## hub(name, zone, cont, x, y, ride_alliance, ride_horde)

- `cont`: `"EK"` (Eastern Kingdoms), `"K"` (Kalimdor), or `"RG"` (Riverglades, if it's a separate landmass reached by boat).
- `x, y`: rough position on the continent map, 0–100, with y going down. Keep it consistent with the existing places in the table below. These only drive travel-time estimates, so being off by 2 or 3 is fine.
- `ride_alliance` / `ride_horde`: minutes from the nearest flight point that faction can use to the spot. Use `0` if it's at a flight point, and `None` if that faction can't go there (the other faction's capital).
- Make one hub per place where quest givers stand together, plus one for each dungeon entrance.

## Q(name, faction, req_level, cat, shareable, start, path=None, **extra)

- `faction`: `"A"`, `"H"` or `"B"` (both). If the two factions get different givers for the same quest, write two entries.
- `req_level`: minimum level to accept, from the Forever tracker if it has one.
- `cat`:
  - `pre_run_pickup`: picked up outside before the run
  - `inside_pickup`: starts inside the dungeon (NPC or drop) and can be done in the same run
  - `followup`: needs an earlier part turned in first, so it's a second run or a later trip
  - `optional`: breadcrumbs, profession quests, repeatables
  - `attunement`: keys and attunements
  - `class`: class-only quests (also set `cls="Warrior"`, `"Mage/Priest"` and so on)
- `shareable`: `True`, `False` or `None` (unknown). Escorts, item-started and event quests can't be shared in Forever.
- `start`: "NPC, subzone, zone (x, y)" in human words.
- `path`: the steps someone does outside before the run to end up holding the quest. It's a list of `(hub, action, text, extra_minutes)` with action `take`, `turnin` or `do`. Use a dict `{"A": [...], "H": [...]}` when the factions differ. The last step is normally the `take`. Leave the path off for inside, followup and dead quests.
- Extras:
  - `pre=True`: it has a required prequest, so it can't be shared to someone who hasn't done that
  - `after=["Other quest name"]`: in-dungeon ordering, e.g. a follow-up you can only take after turning in a quest whose path is also listed
  - `optRoute=True`: it needs a long chain that doesn't fit in a pickup trip. List it but don't route it
  - `status="unclear"` or `"not_in_forever"`
  - `ch="new"` or `"changed"`
  - `note="…"`: one short sentence
  - `cls="Warrior"`

### Examples (from BRD)

```python
Q("Overmaster Pyron", "A", 48, "pre_run_pickup", True, "Jalinda Sprig, Morgan's Vigil (85.4, 70.0)",
  [("MORGANS", "take", "Jalinda Sprig"), ("BRM", "do", "Kill Pyron (elite) outside the BRD portal", 3),
   ("MORGANS", "turnin", "Jalinda Sprig")]),
Q("Incendius!", "A", 48, "pre_run_pickup", True, "Jalinda Sprig, Morgan's Vigil",
  [("MORGANS", "take", "Jalinda Sprig")], pre=True, after=["Overmaster Pyron"]),
Q("Hurley Blackbreath", "A", 50, "pre_run_pickup", True, "Ragnar Thunderbrew, Kharanos (46.8, 52.5)",
  [("KHARANOS", "take", "Ragnar Thunderbrew")], ch="changed", note="New reward option: Ragnar's Favorite Hat."),
Q("Ragnar Thunderbrew", "A", 50, "optional", True, "Enohar Thunderbrew, Nethergarde Keep",
  [("NETHERGARDE", "take", "Enohar Thunderbrew"), ("KHARANOS", "turnin", "Ragnar Thunderbrew")], note="Breadcrumb. XP only."),
Q("Kharan's Tale", "A", 50, "inside_pickup", True, "Kharan Mighthammer, Detention Block"),
Q("A Binding Contract", "B", 60, "optional", False, "Thorium Brotherhood Contract (item)", status="not_in_forever",
  note="Needs a Sulfuron Ingot from Molten Core."),
```

Write all text in plain, short sentences. No em dashes.

## Existing places (reuse these ids)

| id | name | zone | cont | x, y | ride A / H |
|---|---|---|---|---|---|
| `SW` | Stormwind | Stormwind City | EK | 42, 78 | 0 / None |
| `IF` | Ironforge | Ironforge | EK | 47, 57 | 0 / None |
| `UC` | Undercity | Undercity | EK | 42, 22 | None / 0 |
| `DARN` | Darnassus | Darnassus | K | 36, 8 | 1 / None |
| `ORG` | Orgrimmar | Orgrimmar | K | 60, 40 | None / 0 |
| `TB` | Thunder Bluff | Thunder Bluff | K | 46, 54 | None / 0 |
| `MENETHIL` | Menethil Harbor | Wetlands | EK | 40, 50 | 0 / None |
| `GROMGOL` | Grom'gol | Stranglethorn Vale | EK | 42, 90 | None / 0 |
| `AUBERDINE` | Auberdine | Darkshore | K | 40, 22 | 0 / None |
| `THERAMORE` | Theramore | Dustwallow Marsh | K | 66, 68 | 0 / None |
| `KHARANOS` | Kharanos | Dun Morogh | EK | 44, 58 | 2 / 4 |
| `LAKESHIRE` | Lakeshire | Redridge Mountains | EK | 53, 79 | 0 / 3 |
| `NETHERGARDE` | Nethergarde Keep | Blasted Lands | EK | 61, 88 | 0 / 3 |
| `DAIO` | Daio the Decrepit | Blasted Lands | EK | 58, 87 | 2 / 3 |
| `MORGANS` | Morgan's Vigil | Burning Steppes | EK | 57, 76 | 0 / 3 |
| `FLAMECREST` | Flame Crest | Burning Steppes | EK | 53, 72 | 3 / 0 |
| `SLITHER` | Slither Rock | Burning Steppes | EK | 58, 72 | 3 / 3 |
| `BS_FIELD` | Burning Steppes (mobs and relics) | Burning Steppes | EK | 54, 74 | 2 / 2 |
| `BRM` | Blackrock Mountain | Burning Steppes | EK | 48, 71 | 3 / 2 |
| `THORIUM` | Thorium Point | Searing Gorge | EK | 47, 67 | 0 / 0 |
| `KALARAN` | Kalaran Windblade | Searing Gorge | EK | 47, 69 | 1 / 1 |
| `KARGATH` | Kargath | Badlands | EK | 52, 66 | 2 / 0 |
| `LOTWIL` | Lotwil Veriatus | Badlands | EK | 56, 66 | 3 / 2 |
| `DALARAN` | Dalaran | Alterac Mountains | EK | 40, 38 | 3 / 3 |
| `CHILLWIND` | Chillwind Camp | Western Plaguelands | EK | 46, 35 | 0 / 3 |
| `BULWARK` | The Bulwark | Tirisfal Glades | EK | 48, 26 | 4 / 2 |
| `CAERDARROW` | Caer Darrow | Western Plaguelands | EK | 50, 33 | 2 / 4 |
| `LIGHTSHOPE` | Light's Hope Chapel | Eastern Plaguelands | EK | 66, 28 | 0 / 0 |
| `TERRORDALE` | Terrordale | Eastern Plaguelands | EK | 54, 22 | 4 / 4 |
| `MARRIS` | The Marris Stead | Eastern Plaguelands | EK | 56, 30 | 3 / 3 |
| `STRAT` | Stratholme | Eastern Plaguelands | EK | 59, 17 | 4 / 4 |
| `SUNWATCHER` | Sunwatcher Plateau | Mulgore | K | 44, 52 | 4 / 2 |
| `GADGETZAN` | Gadgetzan | Tanaris | K | 63, 82 | 0 / 0 |
| `STEAMWHEEDLE` | Steamwheedle Port | Tanaris | K | 67, 80 | 2 / 2 |
| `EVERLOOK` | Everlook | Winterspring | K | 62, 17 | 0 / 0 |
| `MOONGLADE` | Moonglade | Moonglade | K | 52, 13 | 0 / 0 |
| `HALEH` | Mazthoril | Winterspring | K | 60, 20 | 3 / 3 |
| `LORAX` | Lorax | Winterspring | K | 63, 23 | 2 / 2 |
| `FEATHERMOON` | Feathermoon Stronghold | Feralas | K | 32, 72 | 0 / None |
| `MOJACHE` | Camp Mojache | Feralas | K | 47, 73 | 4 / 0 |
| `LARISS` | Lariss Pavilion | Feralas | K | 48, 69 | 4 / 2 |
| `DIREMAUL` | Dire Maul | Feralas | K | 40, 71 | 4 / 4 |
| `SILITHUS` | Southwind Village | Silithus | K | 42, 87 | 2 / 2 |
| `URSOLAN` | Ursolan | Azshara | K | 70, 26 | 5 / 4 |
| `ELDARATH` | Ruins of Eldarath | Azshara | K | 71, 31 | 4 / 3 |
| `OGTINC` | Ogtinc | Azshara | K | 71, 33 | 4 / 3 |
| `BMH` | Blackmaw Hold | Azshara | K | 68, 27 | 5 / 4 |
| `UNGORO` | Marshal's Refuge | Un'Goro Crater | K | 52, 81 | 0 / 0 |
| `SHAPERS` | Shaper's Terrace | Un'Goro Crater | K | 52, 79 | 1 / 1 |