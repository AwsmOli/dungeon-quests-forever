"""Quest data for the Forever dungeon planner. Built from Forever trackers (foreverchanges.pro build 1.60.1.70959,
conquestcapped, zockify, warcrafttavern, wowforeverguides) with Classic fill-ins where noted."""

# ---------- hubs: continent-map positions (0-100), ride = minutes from usable flight point ----------
def hub(name, zone, cont, x, y, a=0, h=0):
    return {"name": name, "zone": zone, "cont": cont, "x": x, "y": y, "ride": {"A": a, "H": h}}

HUBS = {
    # capitals
    "SW": hub("Stormwind", "Stormwind City", "EK", 42, 78, 0, None),
    "IF": hub("Ironforge", "Ironforge", "EK", 47, 57, 0, None),
    "UC": hub("Undercity", "Undercity", "EK", 42, 22, None, 0),
    "DARN": hub("Darnassus", "Darnassus", "K", 36, 8, 1, None),
    "ORG": hub("Orgrimmar", "Orgrimmar", "K", 60, 40, None, 0),
    "TB": hub("Thunder Bluff", "Thunder Bluff", "K", 46, 54, None, 0),
    # ports
    "MENETHIL": hub("Menethil Harbor", "Wetlands", "EK", 40, 50, 0, None),
    "GROMGOL": hub("Grom'gol", "Stranglethorn Vale", "EK", 42, 90, None, 0),
    "AUBERDINE": hub("Auberdine", "Darkshore", "K", 40, 22, 0, None),
    "THERAMORE": hub("Theramore", "Dustwallow Marsh", "K", 66, 68, 0, None),
    # Eastern Kingdoms
    "KHARANOS": hub("Kharanos", "Dun Morogh", "EK", 44, 58, 2, 4),
    "LAKESHIRE": hub("Lakeshire", "Redridge Mountains", "EK", 53, 79, 0, 3),
    "NETHERGARDE": hub("Nethergarde Keep", "Blasted Lands", "EK", 61, 88, 0, 3),
    "DAIO": hub("Daio the Decrepit", "Blasted Lands", "EK", 58, 87, 2, 3),
    "MORGANS": hub("Morgan's Vigil", "Burning Steppes", "EK", 57, 76, 0, 3),
    "FLAMECREST": hub("Flame Crest", "Burning Steppes", "EK", 53, 72, 3, 0),
    "SLITHER": hub("Slither Rock", "Burning Steppes", "EK", 58, 72, 3, 3),
    "BS_FIELD": hub("Burning Steppes (mobs and relics)", "Burning Steppes", "EK", 54, 74, 2, 2),
    "BRM": hub("Blackrock Mountain", "Burning Steppes", "EK", 48, 71, 3, 2),
    "THORIUM": hub("Thorium Point", "Searing Gorge", "EK", 47, 67, 0, 0),
    "KALARAN": hub("Kalaran Windblade", "Searing Gorge", "EK", 47, 69, 1, 1),
    "KARGATH": hub("Kargath", "Badlands", "EK", 52, 66, 2, 0),
    "LOTWIL": hub("Lotwil Veriatus", "Badlands", "EK", 56, 66, 3, 2),
    "DALARAN": hub("Dalaran", "Alterac Mountains", "EK", 40, 38, 3, 3),
    "CHILLWIND": hub("Chillwind Camp", "Western Plaguelands", "EK", 46, 35, 0, 3),
    "BULWARK": hub("The Bulwark", "Tirisfal Glades", "EK", 48, 26, 4, 2),
    "CAERDARROW": hub("Caer Darrow", "Western Plaguelands", "EK", 50, 33, 2, 4),
    "LIGHTSHOPE": hub("Light's Hope Chapel", "Eastern Plaguelands", "EK", 66, 28, 0, 0),
    "TERRORDALE": hub("Terrordale", "Eastern Plaguelands", "EK", 54, 22, 4, 4),
    "MARRIS": hub("The Marris Stead", "Eastern Plaguelands", "EK", 56, 30, 3, 3),
    "STRAT": hub("Stratholme", "Eastern Plaguelands", "EK", 59, 17, 4, 4),
    # Kalimdor
    "SUNWATCHER": hub("Sunwatcher Plateau", "Mulgore", "K", 44, 52, 4, 2),
    "GADGETZAN": hub("Gadgetzan", "Tanaris", "K", 63, 82, 0, 0),
    "STEAMWHEEDLE": hub("Steamwheedle Port", "Tanaris", "K", 67, 80, 2, 2),
    "EVERLOOK": hub("Everlook", "Winterspring", "K", 62, 17, 0, 0),
    "MOONGLADE": hub("Moonglade", "Moonglade", "K", 52, 13, 0, 0),
    "HALEH": hub("Mazthoril", "Winterspring", "K", 60, 20, 3, 3),
    "LORAX": hub("Lorax", "Winterspring", "K", 63, 23, 2, 2),
    "FEATHERMOON": hub("Feathermoon Stronghold", "Feralas", "K", 32, 72, 0, None),
    "MOJACHE": hub("Camp Mojache", "Feralas", "K", 47, 73, 4, 0),
    "LARISS": hub("Lariss Pavilion", "Feralas", "K", 48, 69, 4, 2),
    "DIREMAUL": hub("Dire Maul", "Feralas", "K", 40, 71, 4, 4),
    "SILITHUS": hub("Southwind Village", "Silithus", "K", 42, 87, 2, 2),
    "URSOLAN": hub("Ursolan", "Azshara", "K", 70, 26, 5, 4),
    "ELDARATH": hub("Ruins of Eldarath", "Azshara", "K", 71, 31, 4, 3),
    "OGTINC": hub("Ogtinc", "Azshara", "K", 71, 33, 4, 3),
    "BMH": hub("Blackmaw Hold", "Azshara", "K", 68, 27, 5, 4),
    "UNGORO": hub("Marshal's Refuge", "Un'Goro Crater", "K", 52, 81, 0, 0),
    "SHAPERS": hub("Shaper's Terrace", "Un'Goro Crater", "K", 52, 79, 1, 1),
}


def Q(n, f, req, cat, share, start, path=None, **kw):
    d = {"n": n, "f": f, "req": req, "cat": cat, "share": share, "start": start}
    if path is not None:
        if isinstance(path, dict):
            d["path"] = {k: [S(*s) for s in v] for k, v in path.items()}
        else:
            d["path"] = [S(*s) for s in path]
    for k, v in kw.items():
        if v is not None:
            d[k] = v
    return d


def S(hub_id, a, t="", work=0, hearth=False):
    s = {"hub": hub_id, "a": a}
    if t: s["t"] = t
    if work: s["work"] = work
    if hearth: s["opts"] = [{"via": "Hearth", "min": 1}]
    return s


UNCLEAR_T05 = "Tier 0.5 (Dungeon Set 2). Listed in Forever data but not confirmed live."

DUNGEONS = []

# ======================= BRD =======================
DUNGEONS.append({
    "id": "brd", "name": "Blackrock Depths", "short": "BRD", "range": "52-60", "entrance": "BRM",
    "entranceNote": "Blackrock Mountain, between Burning Steppes and Searing Gorge.",
    "notes": [
        "Molten Core isn't in Forever, so Attunement to the Core and A Binding Contract are dead.",
        "Dark Iron Legacy is taken as a ghost: everyone dies once in Blackrock Mountain.",
        "Kill Overmaster Pyron (outside the BRD portal) before your first run so you can carry the follow-ups in.",
    ],
    "sources": ["https://foreverchanges.pro/quests/blackrock-depths",
                "https://conquestcapped.com/guides/wow-forever/wow-forever-blackrock-depths-quests/",
                "https://www.zockify.com/forever/dungeons/blackrock-depths/"],
    "quests": [
        Q("Dark Iron Legacy", "B", 48, "pre_run_pickup", False, "Franclorn Forgewright (ghost), Blackrock Mountain",
          [("BRM", "take", "Die, then take parts 1 and 2 from Franclorn as a ghost", 3)],
          note="Part 2 gives the Shadowforge Key; one holder per group is enough."),
        Q("Ribbly Screwspigot", "B", 48, "pre_run_pickup", True, "Yuka Screwspigot, Flame Crest (66.0, 22.0)",
          [("FLAMECREST", "take", "Yuka Screwspigot")]),
        Q("Yuka Screwspigot", "B", 48, "optional", True, "Yorba Screwspigot, Steamwheedle Port, Tanaris",
          [("STEAMWHEEDLE", "take", "Yorba Screwspigot"), ("FLAMECREST", "turnin", "Yuka Screwspigot")],
          note="Breadcrumb for Ribbly. XP only."),
        Q("The Heart of the Mountain", "B", 50, "pre_run_pickup", True, "Maxwort Uberglint, Flame Crest (65.2, 23.8)",
          [("FLAMECREST", "take", "Maxwort Uberglint")], note="Loot repeatable since the Nov 9 hotfix."),
        Q("A Taste of Flame", "B", 52, "optional", False, "Cyrus Therepentous, Slither Rock (94.8, 31.6)",
          [("KALARAN", "do", "Kalaran Windblade: talk through Divine Retribution"),
           ("SLITHER", "take", "Cyrus; kill the level 54 elite drake he spawns for the molt", 6)],
          pre=True, note="Needs Divine Retribution from Kalaran Windblade, Searing Gorge (39, 39)."),
        Q("The Love Potion", "B", 50, "optional", False, "Mistress Nagmara, Grim Guzzler (inside)", ch="changed",
          note="Gromsblood, Giant Silver Veins and a vial filled in Un'Goro."),
        Q("The Spectral Chalice", "B", 40, "optional", True, "Spectral Chalice, Summoners' Tomb (inside)", ch="changed", note="Mining 230."),
        Q("Rocknot's Ale", "B", 1, "optional", False, "Private Rocknot, Grim Guzzler (inside)", note="Repeatable, no XP."),
        Q("Attunement to the Core", "B", 55, "attunement", True, "Lothos Riftwaker, Blackrock Mountain", status="not_in_forever", note="Molten Core isn't in Forever."),
        Q("A Binding Contract", "B", 60, "optional", False, "Thorium Brotherhood Contract (item)", status="not_in_forever", note="Needs a Sulfuron Ingot from Molten Core."),
        Q("The Challenge", "B", 58, "followup", False, "Falrin Treeshaper, Dire Maul", status="unclear", note=UNCLEAR_T05),
        # Alliance
        Q("Overmaster Pyron", "A", 48, "pre_run_pickup", True, "Jalinda Sprig, Morgan's Vigil (85.4, 70.0)",
          [("MORGANS", "take", "Jalinda Sprig"), ("BRM", "do", "Kill Pyron (elite) outside the BRD portal", 3),
           ("MORGANS", "turnin", "Jalinda Sprig")]),
        Q("Incendius!", "A", 48, "pre_run_pickup", True, "Jalinda Sprig, Morgan's Vigil", [("MORGANS", "take", "Jalinda Sprig")],
          pre=True, after=["Overmaster Pyron"]),
        Q("The Good Stuff", "A", 50, "pre_run_pickup", True, "Oralius, Morgan's Vigil (84.5, 68.5)", [("MORGANS", "take", "Oralius")]),
        Q("Ragnar Thunderbrew", "A", 50, "optional", True, "Enohar Thunderbrew, Nethergarde Keep",
          [("NETHERGARDE", "take", "Enohar Thunderbrew"), ("KHARANOS", "turnin", "Ragnar Thunderbrew")], note="Breadcrumb for Hurley. 550 XP."),
        Q("Hurley Blackbreath", "A", 50, "pre_run_pickup", True, "Ragnar Thunderbrew, Kharanos (46.8, 52.5)",
          [("KHARANOS", "take", "Ragnar Thunderbrew")], ch="changed", note="New reward option: Ragnar's Favorite Hat."),
        Q("The Smoldering Ruins of Thaurissan", "A", 48, "pre_run_pickup", False, "Royal Historian Archesonus, Ironforge (38.5, 55.5)",
          [("IF", "take", "Archesonus: listen to part 1, take part 2"), ("BS_FIELD", "do", "Read the Thaurissan relics", 4),
           ("IF", "turnin", "Archesonus")]),
        Q("Kharan Mighthammer", "A", 50, "pre_run_pickup", True, "King Magni Bronzebeard, Ironforge (39.4, 55.6)",
          [("IF", "take", "King Magni")], pre=True, after=["The Smoldering Ruins of Thaurissan"], ch="changed"),
        Q("Kharan's Tale", "A", 50, "inside_pickup", True, "Kharan Mighthammer, Detention Block"),
        Q("The Bearer of Bad News", "A", 50, "inside_pickup", True, "Kharan Mighthammer, Detention Block", note="Turn in to Magni."),
        Q("The Fate of the Kingdom", "A", 50, "followup", True, "King Magni, Ironforge", note="Kill the Emperor, keep Moira alive."),
        Q("The Princess's Surprise", "A", 50, "followup", True, "Princess Moira (inside)"),
        Q("Dragonkin Menace", "A", 48, "pre_run_pickup", True, "Helendis Riverhorn, Morgan's Vigil (85.5, 68.9)",
          [("MORGANS", "take", "Helendis Riverhorn"), ("BS_FIELD", "do", "Kill the dragonkin", 8), ("MORGANS", "turnin", "Helendis Riverhorn")],
          note="Starts the Alliance Onyxia attunement chain."),
        Q("The True Masters", "A", 48, "pre_run_pickup", False, "Helendis Riverhorn, Morgan's Vigil",
          [("MORGANS", "take", "Helendis Riverhorn"), ("LAKESHIRE", "do", "Magistrate Solomon"),
           ("SW", "do", "Stormwind Keep: Highlord Bolvar and Lady Prestor", 2), ("LAKESHIRE", "do", "Magistrate Solomon"),
           ("MORGANS", "turnin", "Marshal Maxwell (last steps)", 2)],
          pre=True, after=["Dragonkin Menace"], note="Six talk/courier steps."),
        Q("Marshal Windsor", "A", 48, "pre_run_pickup", True, "Marshal Maxwell, Morgan's Vigil (84.6, 68.8)",
          [("MORGANS", "take", "Marshal Maxwell")], pre=True, after=["The True Masters"]),
        Q("Abandoned Hope", "A", 48, "inside_pickup", True, "Marshal Windsor (inside)", ch="changed"),
        Q("A Crumpled Up Note", "A", 50, "followup", False, "Drops in BRD once Abandoned Hope is turned in"),
        Q("A Shred of Hope", "A", 50, "followup", True, "Marshal Windsor (inside)"),
        Q("Jail Break!", "A", 50, "followup", False, "Marshal Windsor (inside)", note="Escort."),
        # Horde
        Q("Fragment of the Firelands", "H", 46, "pre_run_pickup", True, "Alaana Stormwalker, Sunwatcher Plateau, Mulgore (33.4, 22.5)",
          [("SUNWATCHER", "take", "Alaana Stormwalker")], ch="new",
          note="New in Forever. Turn in at Magmus. Location from one tracker; shareability assumed."),
        Q("Vivian Lagrave", "H", 50, "optional", True, "Apothecary Zinge, Undercity",
          [("UC", "take", "Apothecary Zinge, The Apothecarium"), ("KARGATH", "turnin", "Shadowmage Vivian Lagrave")], note="Breadcrumb. XP only."),
        Q("Disharmony of Flame", "H", 48, "pre_run_pickup", True, "Thunderheart, Kargath (3.4, 48.2)",
          [("KARGATH", "take", "Thunderheart"), ("BRM", "do", "Kill Pyron (elite) outside the BRD portal", 3),
           ("KARGATH", "turnin", "Thunderheart", 0, True)]),
        Q("Disharmony of Fire", "H", 48, "pre_run_pickup", True, "Thunderheart, Kargath", [("KARGATH", "take", "Thunderheart")],
          pre=True, after=["Disharmony of Flame"]),
        Q("Commander Gor'shak", "H", 48, "pre_run_pickup", True, "Galamav the Marksman, Kargath (5.8, 47.4)",
          [("KARGATH", "take", "Galamav the Marksman")], pre=True, after=["Disharmony of Flame"]),
        Q("The Last Element", "H", 48, "pre_run_pickup", True, "Shadowmage Vivian Lagrave, Kargath (3.0, 47.5)",
          [("KARGATH", "take", "Shadowmage Vivian Lagrave")], pre=True, after=["Disharmony of Flame"], ch="changed",
          note="Some trackers list Disharmony of Flame as a prereq. New reward option: Dark Iron Signet."),
        Q("Lost Thunderbrew Recipe", "H", 50, "pre_run_pickup", True, "Shadowmage Vivian Lagrave, Kargath",
          [("KARGATH", "take", "Shadowmage Vivian Lagrave")], ch="changed"),
        Q("KILL ON SIGHT: Dark Iron Dwarves", "H", 48, "pre_run_pickup", True, "WANTED poster, Kargath (3.8, 47.5)",
          [("KARGATH", "take", "WANTED poster left of the inn door")]),
        Q("KILL ON SIGHT: High Ranking Dark Iron Officials", "H", 50, "followup", True, "Poster right of the Kargath inn door"),
        Q("Grark Lorkrub", "H", 52, "followup", False, "Lexlort, Kargath (5.8, 47.5)"),
        Q("Precarious Predicament", "H", 52, "followup", False, "Grark Lorkrub, Burning Steppes (40.2, 34.2)", note="Escort."),
        Q("Operation: Death to Angerforge", "H", 52, "followup", True, "Warlord Goretooth, Kargath"),
        Q("The Rise of the Machines", "H", 52, "pre_run_pickup", False, "Hierophant Theodora Mulvadania, Kargath (3.0, 47.6)",
          [("KARGATH", "take", "Theodora (part 1). Set your hearth here."), ("BS_FIELD", "do", "10 Fractured Elemental Shards", 8),
           ("KARGATH", "do", "Turn in the shards to Theodora", 0, True), ("LOTWIL", "take", "Lotwil Veriatus (25.8, 44.7)")], pre=True),
        Q("What Is Going On?", "H", 48, "inside_pickup", False, "Commander Gor'shak (inside)", ch="changed", note="Two parts; part 2 ends at Thrall."),
        Q("The Eastern Kingdoms", "H", 48, "followup", True, "Thrall, Orgrimmar", ch="changed"),
        Q("The Royal Rescue", "H", 48, "followup", True, "Thrall, Orgrimmar", ch="changed"),
        Q("The Princess Saved?", "H", 48, "followup", True, "Princess Moira (inside)", ch="changed"),
    ],
})

# ======================= Dire Maul East =======================
DUNGEONS.append({
    "id": "dme", "name": "Warpwood Quarter", "aka": "Dire Maul East", "short": "DME", "range": "54-60", "entrance": "DIREMAUL",
    "entranceNote": "Dire Maul, central Feralas. Pusillin drops the Crescent Key for the other wings.",
    "notes": [
        "Shards of the Felvine needs each player's own Reliquary of Purity from Silithus first. A druid's Moonglade teleport helps.",
        "Most Forever changes here are XP. Lethtendris's Web gained two new reward choices.",
    ],
    "sources": ["https://foreverchanges.pro/quests/dire-maul", "https://www.warcrafttavern.com/forever/guides/"],
    "quests": [
        Q("Lethtendris's Web", "A", 54, "pre_run_pickup", True, "Latronicus Moonspear, Feathermoon Stronghold (30.4, 46.2)",
          [("FEATHERMOON", "take", "Latronicus Moonspear")], ch="changed", note="New reward choices: Warpwood Bracers, Satyrhide Armbands."),
        Q("Feathermoon Stronghold", "A", 50, "optional", True, "Crier Goodman, Stormwind (sources disagree: Courier Hammerfall, Ironforge)",
          [("SW", "take", "Crier Goodman"), ("FEATHERMOON", "turnin", "Latronicus Moonspear")], note="Breadcrumb. XP only."),
        Q("Lethtendris's Web", "H", 54, "pre_run_pickup", True, "Talo Thornhoof, Camp Mojache (76.2, 43.8)",
          [("MOJACHE", "take", "Talo Thornhoof")], ch="changed", note="New reward choices: Warpwood Bracers, Satyrhide Armbands."),
        Q("Camp Mojache", "H", 50, "optional", True, "Warcaller Gorlach, Orgrimmar (48.2, 66.1)",
          [("ORG", "take", "Warcaller Gorlach"), ("MOJACHE", "turnin", "Talo Thornhoof")], note="Breadcrumb. XP only."),
        Q("Pusillin and the Elder Azj'Tordin", "B", 54, "pre_run_pickup", True, "Azj'Tordin, Lariss Pavilion (76.9, 37.4)",
          [("LARISS", "take", "Azj'Tordin")], note="Pusillin also drops the Crescent Key."),
        Q("Shards of the Felvine", "B", 56, "pre_run_pickup", False, "Rabine Saturna, Nighthaven, Moonglade (51.7, 45.1)",
          [("MOONGLADE", "take", "Rabine Saturna: A Reliquary of Purity"),
           ("SILITHUS", "do", "Loot the Dusty Reliquary in a Southwind Village building", 4),
           ("MOONGLADE", "turnin", "Rabine Saturna: turn in, take Shards of the Felvine")],
          pre=True, note="Kill Alzzin, then fill the Reliquary at a Felvine patch."),
        Q("The Prison's Bindings", "B", 60, "class", True, "Daio the Decrepit, Blasted Lands (34.1, 50.1)",
          [("DAIO", "take", "Daio the Decrepit")], cls="Warlock", note="Warlock only. 15 Satyr Blood from Wildspawn satyrs."),
        Q("Arcane Refreshment", "B", 60, "class", False, "Lorekeeper Lydros, the Athenaeum (Dire Maul West)", cls="Mage",
          note="Starts in DMW; the kill (Hydrospawn) is in DME."),
        Q("The Left Piece of Lord Valthalak's Amulet (Isalien)", "B", 58, "followup", False, "Bodley, Blackrock Mountain", status="unclear", note=UNCLEAR_T05),
    ],
})

# ======================= LBRS =======================
DUNGEONS.append({
    "id": "lbrs", "name": "Lower Blackrock Spire", "short": "LBRS", "range": "55-60", "entrance": "BRM",
    "entranceNote": "Blackrock Mountain, upper level. No key needed.",
    "notes": [
        "Seal of Ascension (UBRS key) starts from an Unadorned Seal that drops inside. Forever data says level 57 (Classic guides say 55).",
        "Mother's Milk: keep the poison debuff until Ragged John, so don't dispel it.",
        "New in Forever: Blood and Thunder (Horde), from Warlord Goretooth in Kargath. It's probably a lead-in to Warlord's Command, but that isn't confirmed.",
        "Smolderweb Carrier and Worg Carrier are no longer bind-on-pickup. Quartermaster Zigris is a normal elite.",
    ],
    "sources": ["https://foreverchanges.pro/quests/blackrock-spire", "https://conquestcapped.com/guides/wow-forever/"],
    "quests": [
        Q("Put Her Down", "A", 55, "pre_run_pickup", True, "Helendis Riverhorn, Morgan's Vigil (85.8, 68.9)",
          [("MORGANS", "take", "Helendis Riverhorn")], note="Kill Halycon."),
        Q("Bijou's Belongings", "A", 55, "inside_pickup", True, "Bijou, ledge above Hordemar City"),
        Q("Message to Maxwell", "A", 55, "followup", False, "Bijou (inside)"),
        Q("Maxwell's Mission", "A", 55, "followup", True, "Marshal Maxwell, Morgan's Vigil", ch="changed", note="Kill Voone, Omokk and Wyrmthalak."),
        Q("General Drakkisath's Command", "A", 55, "inside_pickup", False, "Item from Overlord Wyrmthalak", ch="changed",
          note="Turn in to Maxwell; unlocks General Drakkisath's Demise (UBRS)."),
        Q("Blood and Thunder", "H", 55, "optional", True, "Warlord Goretooth, Kargath (3.4, 48.0)",
          [("KARGATH", "take", "Warlord Goretooth")], ch="new", note="New in Forever. Possibly the lead-in to Warlord's Command."),
        Q("Warlord's Command", "H", 55, "attunement", False, "Warlord Goretooth, Kargath watchtower (5.8, 47.5)",
          [("KARGATH", "take", "Warlord Goretooth: talk through his dialogue for the item that starts it")], ch="changed",
          note="Step 1 of the Horde Onyxia attunement. Kill Voone, Omokk, Wyrmthalak and loot the documents."),
        Q("Operative Bijou", "H", 55, "pre_run_pickup", True, "Lexlort, Kargath watchtower (5.9, 47.6)", [("KARGATH", "take", "Lexlort")]),
        Q("Bijou's Belongings", "H", 55, "inside_pickup", False, "Bijou, ledge above Hordemar City"),
        Q("Bijou's Reconnaissance Report", "H", 55, "followup", None, "Bijou (inside)", note="Turn in to Lexlort."),
        Q("The Pack Mistress", "H", 55, "pre_run_pickup", True, "Galamav the Marksman, Kargath (6.0, 47.7)",
          [("KARGATH", "take", "Galamav the Marksman")], note="Kill Halycon."),
        Q("Kibler's Exotic Pets", "B", 55, "pre_run_pickup", False, "Kibler, Flame Crest cave (65.9, 21.9)",
          [("FLAMECREST", "take", "Kibler (cave)")], ch="changed", note="Each player needs their own cage. Worg Carrier no longer BoP."),
        Q("En-Ay-Es-Tee-Why", "B", 55, "pre_run_pickup", True, "Kibler, Flame Crest cave (65.9, 21.9)",
          [("FLAMECREST", "take", "Kibler (cave)")], ch="changed", note="15 Spire Spider Eggs."),
        Q("Mother's Milk", "B", 55, "pre_run_pickup", True, "Ragged John, Flame Crest",
          [("FLAMECREST", "take", "Ragged John (outside the cave)")], note="Keep the debuff up until you're back with him."),
        Q("Urok Doomhowl", "B", 55, "inside_pickup", False, "Warosh, Hordemar City"),
        Q("Seal of Ascension", "B", 57, "attunement", False, "Vaelan, top of the rubble ramp near the entrance",
          note="UBRS key. Needs an Unadorned Seal (drops inside). Part 2 needs Emberstrife in Dustwallow Marsh (elite)."),
        Q("The Final Tablets", "B", 40, "optional", True, "Prospector Ironboot, Steamwheedle Port (66.9, 24.0)",
          [("STEAMWHEEDLE", "take", "Prospector Ironboot")], pre=True,
          note="Only if you've done the Mosh'aru tablets chain (Zul'Farrak)."),
        Q("The Left Piece of Lord Valthalak's Amulet (Mor Grayhoof)", "B", 58, "followup", False, "Bodley, Blackrock Mountain", status="unclear", note=UNCLEAR_T05),
    ],
})

# ======================= Blackmaw Hold =======================
DUNGEONS.append({
    "id": "bmh", "name": "Blackmaw Hold", "short": "BMH", "range": "55-60", "entrance": "BMH", "isNew": True,
    "entranceNote": "Northern Azshara, furbolg tunnel at about 38.7, 33.4. The portal shows on the Winterspring map.",
    "notes": [
        "New Forever dungeon. Every quest here is new.",
        "The Twin Bears and Blackmaw Reclamation reportedly need Neutral with Timbermaw Hold.",
        "Blackmaw Reclamation is a long outdoor chain (Azshara, Felwood, Timbermaw Hold). Do it as its own session.",
    ],
    "sources": ["https://foreverchanges.pro/dungeons/blackmaw-hold", "https://www.warcrafttavern.com/forever/guides/"],
    "quests": [
        Q("Get to the Roots of It", "A", 45, "pre_run_pickup", True, "Mathrengyl Bearwalker, Cenarion Enclave, Darnassus (35.2, 8.2)",
          [("DARN", "take", "Mathrengyl Bearwalker, Cenarion Enclave")], ch="new", note="10 Nordrassil Root Caps inside."),
        Q("Get to the Roots of It", "H", 45, "pre_run_pickup", True, "Nara Wildmane, Elder Rise, Thunder Bluff (75.8, 31.1)",
          [("TB", "take", "Nara Wildmane, Elder Rise")], ch="new", note="10 Nordrassil Root Caps inside."),
        Q("Beneath Nordrassil", "A", 45, "optional", None, "Commander Truesong, Azshara (location not given)", ch="new",
          note="Breadcrumb from Azshara to Darnassus."),
        Q("Beneath Nordrassil", "H", 45, "optional", None, "Jediga, Valormok, Azshara", ch="new", note="Breadcrumb from Azshara to Thunder Bluff."),
        Q("The Twin Bears", "B", 47, "pre_run_pickup", True, "Lorekeeper Nok, Ursolan, Azshara",
          [("URSOLAN", "take", "Lorekeeper Nok")], ch="new", note="Totems of Ursoc and Ursol inside. May need Neutral Timbermaw."),
        Q("Claws That Rend, Tusks that Gore", "B", 45, "pre_run_pickup", True, "Ogtinc, Azshara (42.3, 42.7)",
          [("OGTINC", "take", "Ogtinc")], ch="new", note="Withermaw and Bonesnout the Unbroken."),
        Q("Blackmaw Magic", "A", 52, "pre_run_pickup", True, "Archmage Timear, Dalaran, Alterac Mountains (15.5, 74.0)",
          [("DALARAN", "take", "Archmage Timear")], ch="new", note="Blackmaw Ritual Totem from Elder Shaman Bloodmane."),
        Q("Blackmaw Magic", "H", 52, "pre_run_pickup", True, "Muln Earthfury, Sunwatcher Plateau, Mulgore (33.5, 22.5)",
          [("SUNWATCHER", "take", "Muln Earthfury")], ch="new", note="Blackmaw Ritual Totem from Elder Shaman Bloodmane."),
        Q("Blackmaw Pouches", "B", 55, "pre_run_pickup", True, "Ekkal, Ruins of Eldarath, Azshara (42.0, 38.9)",
          [("ELDARATH", "take", "Ekkal")], ch="new", note="Repeatable after the first turn-in (+100 Timbermaw)."),
        Q("A Lost Memento", "B", 47, "inside_pickup", False, "Feathered Charm Necklace (drops inside)", ch="new", note="Return to Un'ell, Azshara."),
        Q("Blackmaw Reclamation", "B", 47, "pre_run_pickup", None, "Gatekeeper Rageroar, Ursolan (42.3, 20.3)", ch="new", optRoute=True,
          note="End of a 5 to 10 step chain that starts with Ekkal (The Legashi Threat) and runs through Legashi Stronghold and Timbermaw Hold."),
        Q("Feeding Time!", "B", None, "optional", None, "Unclear: inside the dungeon or Ruins of Eldarath", ch="new", status="unclear",
          note="Repeatable Timbermaw reputation quest."),
    ],
})

# ======================= Dire Maul West =======================
DUNGEONS.append({
    "id": "dmw", "name": "Capital Gardens", "aka": "Dire Maul West", "short": "DMW", "range": "56-60", "entrance": "DIREMAUL",
    "entranceNote": "Dire Maul, Feralas. Locked doors need the Crescent Key (from Pusillin in DME) or 300 Lockpicking.",
    "notes": [
        "New in Forever: Libram of Binding (repeatable, from Lorekeeper Lydros after Elven Legends).",
        "Libram turn-ins now need level 54. Class book quests need level 54 and give 6,600 XP.",
        "Class books (warrior, paladin, hunter, rogue, priest, shaman, mage, warlock, druid) drop from Dire Maul bosses.",
    ],
    "sources": ["https://foreverchanges.pro/quests/dire-maul", "https://warcraft.wiki.gg/wiki/Patch_1.60"],
    "quests": [
        Q("Elven Legends", "A", 54, "pre_run_pickup", True, "Scholar Runethorn, Feathermoon Stronghold (31.2, 43.9)",
          [("FEATHERMOON", "take", "Scholar Runethorn (patrols the road)")], ch="changed"),
        Q("Elven Legends", "H", 54, "pre_run_pickup", True, "Sage Korolusk, Camp Mojache (75.2, 43.8)",
          [("MOJACHE", "take", "Sage Korolusk (patrols the camp)")], ch="changed"),
        Q("The Madness Within", "B", 56, "inside_pickup", True, "Shen'dralar Ancient, Court of the Highborne", ch="changed",
          note="Talk to him before killing Immol'thar."),
        Q("The Treasure of the Shen'dralar", "B", 56, "inside_pickup", True, "Shen'dralar Ancient (after The Madness Within)", ch="changed"),
        Q("Libram turn-ins (Focus, Protection, Rapidity)", "B", 54, "optional", True, "Lorekeeper Lydros, the Athenaeum", ch="changed",
          note="Repeatable. Needs the libram plus reagents."),
        Q("Libram of Binding", "B", 57, "optional", None, "Lorekeeper Lydros, the Athenaeum", ch="new",
          note="Forever-only. Repeatable. Rewards Arcanum of Binding (+500 Shen'dralar)."),
        Q("Class book turn-ins", "B", 54, "class", False, "Book drops from Dire Maul bosses", ch="changed",
          note="One per class. Rewards a Royal Seal of Eldre'Thalas.", cls="All"),
        Q("Foror's Compendium", "B", 60, "class", False, "Foror's Compendium (rare drop)", ch="changed", cls="Warrior/Paladin",
          note="Leads to Quel'Serrar, which needs Onyxia."),
        Q("Dreadsteed of Xoroth", "B", 60, "class", False, "Mor'zul Bloodbringer, Burning Steppes (12.7, 31.6)", ch="changed", cls="Warlock",
          note="Epic mount ritual in DMW after a long chain."),
        Q("Anthion's Old Friend", "B", 58, "followup", False, "Anthion Harmon, Eastern Plaguelands", status="unclear", note=UNCLEAR_T05),
        Q("Falrin's Vendetta", "B", 58, "followup", True, "Falrin Treeshaper (inside)", status="unclear", note=UNCLEAR_T05),
        Q("The Instigator's Enchantment", "B", 58, "followup", None, "Falrin Treeshaper (inside)", status="unclear", note=UNCLEAR_T05),
    ],
})

# ======================= Dire Maul North =======================
DUNGEONS.append({
    "id": "dmn", "name": "Gordok Commons", "aka": "Dire Maul North", "short": "DMN", "range": "56-60", "entrance": "DIREMAUL",
    "entranceNote": "Dire Maul, Feralas, north side. Gordok keys drop from the guards inside.",
    "notes": [
        "Every quest here starts inside. Nothing to pick up first.",
        "Free Knot! and The Gordok Taste Test now need level 56 (Classic: 57).",
        "Taste Test and Unfinished Gordok Business need a tribute run: kill King Gordok with the other bosses alive.",
    ],
    "sources": ["https://foreverchanges.pro/quests/dire-maul"],
    "quests": [
        Q("Free Knot!", "B", 56, "inside_pickup", True, "Knot Thimblejack (shackled inside)", ch="changed"),
        Q("Unfinished Gordok Business", "B", 56, "inside_pickup", False, "Captain Kromcrush (after a tribute run)",
          note="Needs the Gauntlet of Gordok Might from the Prince's chest in DMW."),
        Q("The Gordok Taste Test", "B", 56, "inside_pickup", True, "Stomper Kreeg (after a tribute run)", ch="changed"),
        Q("The Gordok Ogre Suit", "B", 56, "optional", True, "Knot Thimblejack (inside)", note="Runecloth, rugged leather, rune thread, ogre tannin."),
        Q("A Broken Trap", "B", 56, "optional", True, "Broken Trap (object, inside)", note="Thorium Widget + Frost Oil."),
    ],
})

# ======================= Shaper's Terrace =======================
DUNGEONS.append({
    "id": "sht", "name": "Shaper's Terrace", "short": "ShT", "range": "58-60", "entrance": "SHAPERS", "isNew": True,
    "entranceNote": "Un'Goro Crater, on the hill above Marshal's Refuge (48.1, 6.1).",
    "notes": [
        "New Forever dungeon. Every quest here is new.",
        "To summon the last boss (Nanaya) you need 15 Power Crystals of each colour: red, blue, green and yellow. Farm them in Un'Goro first.",
        "XP figures come from a pre-launch build. Turn-ins are mostly unconfirmed.",
    ],
    "sources": ["https://foreverchanges.pro/dungeons/shapers-terrace", "https://www.warcrafttavern.com/forever/guides/",
                "https://www.zockify.com/forever/dungeons/"],
    "quests": [
        Q("Mapping the Way Forward", "A", 55, "pre_run_pickup", False, "Curator Thorius, Hall of Explorers, Ironforge (71.5, 16.6)",
          [("IF", "take", "Curator Thorius, Hall of Explorers")], ch="new", note="Not shareable (one source)."),
        Q("Panic at the Digsite", "A", 55, "pre_run_pickup", True, "Curator Thorius, Hall of Explorers, Ironforge",
          [("IF", "take", "Curator Thorius, Hall of Explorers")], ch="new"),
        Q("Digestible Research", "A", 55, "inside_pickup", False, "Torn field journal near the entrance pond", ch="new"),
        Q("Crystalline Elements", "H", 55, "pre_run_pickup", True, "Mayena Earthseeker, Sunwatcher Plateau, Mulgore (34.9, 22.1)",
          [("SUNWATCHER", "take", "Mayena Earthseeker")], ch="new"),
        Q("Essence of Seeping Slimes", "H", 55, "pre_run_pickup", True, "Chemist Fuely, The Apothecarium, Undercity (47.7, 73.3)",
          [("UC", "take", "Chemist Fuely, The Apothecarium")], ch="new"),
        Q("The Dark Crystal", "H", 55, "pre_run_pickup", True, "Master Apothecary Faranell, The Apothecarium (48.6, 68.8)",
          [("UC", "take", "Master Apothecary Faranell, The Apothecarium")], ch="new"),
        Q("Prep: 15 Power Crystals of each colour", "B", None, "optional", False, "Un'Goro Crater (not a quest)",
          [("UNGORO", "do", "Farm red, blue, green and yellow Power Crystals around the crater", 20)],
          note="Needed to summon the final boss."),
    ],
})

# ======================= Stratholme Live =======================
DUNGEONS.append({
    "id": "stratl", "name": "Stratholme Main Gate", "aka": "Stratholme Live", "short": "Strat Live", "range": "58-60", "entrance": "STRAT",
    "entranceNote": "Stratholme, northern Eastern Plaguelands. Key to the City drops from Magistrate Barthilas.",
    "notes": [
        "The tracker's coordinates use Forever's map: Light's Hope NPCs show at about 71, 49, not Classic's 81, 59.",
        "The Great Fras Siabi's target is called Ezra Grimm in one Forever guide. The quest item is Grimm's Premium Tobacco.",
        "Forever changes here are XP only.",
    ],
    "sources": ["https://foreverchanges.pro/quests/stratholme", "https://www.warcrafttavern.com/forever/guides/"],
    "quests": [
        Q("The Great Fras Siabi", "B", 55, "pre_run_pickup", True, "Smokey LaRue, Light's Hope Chapel (70.9, 48.4)",
          [("LIGHTSHOPE", "take", "Smokey LaRue")], ch="changed"),
        Q("The Archivist", "B", 55, "pre_run_pickup", True, "Duke Nicholas Zverenhoff, Light's Hope Chapel (71.6, 50.1)",
          [("LIGHTSHOPE", "take", "Duke Nicholas Zverenhoff")], note="Start of the Argent Dawn chain."),
        Q("The Truth Comes Crashing Down", "B", 55, "followup", False, "Head of Balnazzar (drop)",
          note="Can't be taken until The Archivist is turned in."),
        Q("The Medallion of Faith", "B", 55, "inside_pickup", True, "Aurius, just inside the Undead side",
          note="Medallion is in Malor's Strongbox on the Live side."),
        Q("The Restless Souls", "B", 55, "pre_run_pickup", False, "Egan, Terrordale (11.4, 26.6)",
          [("LIGHTSHOPE", "take", "Caretaker Alen, just south of the chapel: The Restless Souls (part 1)"),
           ("TERRORDALE", "turnin", "Egan, westernmost house: turn in, take part 2")], pre=True, ch="changed",
          note="Use Egan's Blaster on the ghosts; don't kill them."),
        Q("Of Love and Family", "B", 52, "pre_run_pickup", True, "Artist Renfray, Caer Darrow (65.8, 75.4)", optRoute=True,
          note="Needs the Tirion Fordring chain in Eastern Plaguelands first. Can only be shared to people who did that chain."),
        Q("Sweet Serenity", "B", 50, "optional", True, "Lilith the Lithe, Everlook (61.3, 37.1)",
          [("EVERLOOK", "take", "Lilith the Lithe")], note="Blacksmithing 250."),
        Q("The Left Piece of Lord Valthalak's Amulet (Jarien and Sothos)", "B", 58, "followup", False, "Bodley, Blackrock Mountain", status="unclear", note=UNCLEAR_T05),
    ],
})

# ======================= Stratholme Undead =======================
DUNGEONS.append({
    "id": "stratu", "name": "Stratholme Service Gate", "aka": "Stratholme Undead", "short": "Strat UD", "range": "58-60", "entrance": "STRAT",
    "entranceNote": "Stratholme, east side service entrance.",
    "notes": [
        "Naxxramas isn't in Forever, so the Atiesh summon is dead.",
        "Menethil's Gift needs the Scholomance Sarkhoff chain first (Krastinov, Bag of Horrors, Kirtonos).",
        "Forever changes here are XP only: Aurius' Reckoning went up, The Active Agent and Corruption went down.",
    ],
    "sources": ["https://foreverchanges.pro/quests/stratholme"],
    "quests": [
        Q("The Flesh Does Not Lie", "B", 55, "pre_run_pickup", True, "Betina Bigglezink, Light's Hope Chapel (71.7, 49.9)",
          [("LIGHTSHOPE", "take", "Betina Bigglezink")]),
        Q("The Active Agent", "B", 55, "followup", True, "Betina Bigglezink (after The Flesh Does Not Lie)", ch="changed"),
        Q("Houses of the Holy", "B", 55, "pre_run_pickup", True, "Leonid Barthalomew the Revered, Light's Hope Chapel (71.9, 48.3)",
          [("LIGHTSHOPE", "take", "Leonid Barthalomew")]),
        Q("Above and Beyond", "B", 55, "followup", True, "Duke Nicholas Zverenhoff (after the Live-side chain)"),
        Q("Aurius' Reckoning", "B", 55, "inside_pickup", True, "Aurius (after The Medallion of Faith)", ch="changed"),
        Q("Ramstein", "H", 56, "pre_run_pickup", True, "Nathanos Blightcaller, The Marris Stead (22.2, 63.5)",
          [("MARRIS", "take", "Nathanos Blightcaller")], pre=True, optRoute=True,
          note="Needs The Ranger Lord's Behest and Nathanos's elite kills first."),
        Q("Menethil's Gift", "B", 57, "pre_run_pickup", False, "Leonid Barthalomew the Revered, Light's Hope Chapel",
          [("LIGHTSHOPE", "take", "Leonid Barthalomew")], pre=True, optRoute=True, note="Needs the Scholomance Sarkhoff chain first."),
        Q("Menethil's Gift (part 2)", "B", None, "inside_pickup", False, "Menethil's Gift (object, Baron's room)"),
        Q("Corruption", "B", 50, "optional", True, "Seril Scourgebane, Everlook (61.3, 37.2)",
          [("EVERLOOK", "take", "Seril Scourgebane")], ch="changed", note="Blacksmithing 250."),
        Q("Dead Man's Plea", "B", 58, "followup", True, "Anthion Harmon, Stratholme entrance (ghost)", status="unclear", note=UNCLEAR_T05),
        Q("Atiesh, the Befouled Greatstaff", "B", None, "class", False, "Anachronos, Caverns of Time", status="not_in_forever",
          cls="Mage/Priest/Warlock/Druid", note="Needs Naxxramas."),
    ],
})

# ======================= Scholomance =======================
DUNGEONS.append({
    "id": "scholo", "name": "Scholomance", "short": "Scholo", "range": "58-60", "entrance": "CAERDARROW",
    "entranceNote": "Caer Darrow, Western Plaguelands. The door needs a Skeleton Key, a rogue (280 Lockpicking) or a Seaforium charge.",
    "notes": [
        "Only one person needs the Skeleton Key to open the door for the group.",
        "Eva Sarkhoff stands outside the door: step out mid-run to hand in Krastinov and take the next steps.",
        "Shaman: The Darkreaver Menace now needs level 58 (was 60). A second version is marked new in Forever.",
    ],
    "sources": ["https://foreverchanges.pro/quests/scholomance", "https://conquestcapped.com/guides/wow-forever/"],
    "quests": [
        Q("The Key to Scholomance", "A", 55, "attunement", False, "Alchemist Arbington, Chillwind Camp (42.7, 83.8)", optRoute=True,
          note="Long chain from Commander Ashlam Valorfist at Chillwind Camp. One key holder per group is enough."),
        Q("The Key to Scholomance", "H", 55, "attunement", False, "High Executor Derrington, The Bulwark (83.1, 68.9)", optRoute=True,
          note="Long chain from the Bulwark. One key holder per group is enough."),
        Q("Barov Family Fortune", "A", 52, "pre_run_pickup", True, "Weldon Barov, Chillwind Camp (43.5, 83.7)",
          [("CHILLWIND", "take", "Weldon Barov")]),
        Q("Barov Family Fortune", "H", 52, "pre_run_pickup", True, "Alexi Barov, The Bulwark (83.1, 71.6)",
          [("BULWARK", "take", "Alexi Barov")]),
        Q("The Last Barov", "A", 52, "followup", False, "Weldon Barov, Chillwind Camp", note="Kill Alexi Barov at the Bulwark."),
        Q("The Last Barov", "H", 52, "followup", False, "Alexi Barov, The Bulwark", note="Kill Weldon Barov at Chillwind Camp."),
        Q("Doctor Theolen Krastinov, the Butcher", "B", 55, "pre_run_pickup", True, "Eva Sarkhoff, Caer Darrow (70.2, 73.7)",
          [("CAERDARROW", "take", "Eva Sarkhoff")]),
        Q("Krastinov's Bag of Horrors", "B", 55, "inside_pickup", False, "Eva Sarkhoff, outside the door", note="Step out after Krastinov."),
        Q("Kirtonos the Herald", "B", 55, "inside_pickup", False, "Eva Sarkhoff, outside the door", note="Only the holder can summon Kirtonos."),
        Q("The Lich, Ras Frostwhisper", "B", 57, "followup", False, "Magistrate Marduke, Caer Darrow", note="Runs through Stratholme (Menethil's Gift)."),
        Q("Plagued Hatchlings", "B", 55, "pre_run_pickup", True, "Betina Bigglezink, Light's Hope Chapel (71.7, 49.9)",
          [("LIGHTSHOPE", "take", "Betina Bigglezink")]),
        Q("Healthy Dragon Scale", "B", 55, "inside_pickup", False, "Healthy Dragon Scale (drop from Plagued Hatchlings)"),
        Q("Dawn's Gambit", "B", 57, "pre_run_pickup", False, "Betina Bigglezink, Light's Hope Chapel",
          [("LIGHTSHOPE", "take", "Betina Bigglezink (after Leonid)")], pre=True, optRoute=True,
          note="End of the Tinkee egg chain, which goes through UBRS."),
        Q("The Darkreaver Menace", "H", 58, "class", False, "Sagorne Creststrider, Valley of Wisdom, Orgrimmar (38.7, 35.9)", ch="changed", cls="Shaman",
          note="Level 58 in Forever (was 60). Starts with Material Assistance."),
        Q("Judgment and Redemption", "A", 60, "class", False, "Lord Grayson Shadowbreaker, Cathedral of Light, Stormwind", cls="Paladin",
          note="Epic mount chain."),
        Q("Imp Delivery", "B", 60, "class", False, "Gorzeeki Wildeyes, Burning Steppes (12.4, 31.6)", cls="Warlock", note="Dreadsteed chain."),
        Q("The Left Piece of Lord Valthalak's Amulet (Kormok)", "B", 58, "followup", False, "Bodley, Blackrock Mountain", status="unclear", note=UNCLEAR_T05),
    ],
})

# ======================= UBRS =======================
DUNGEONS.append({
    "id": "ubrs", "name": "Upper Blackrock Spire", "short": "UBRS", "range": "59-60", "entrance": "BRM",
    "entranceNote": "Blackrock Mountain. One person must hold the Seal of Ascension ring to open the door.",
    "notes": [
        "Blackhand's Command (Blackwing Lair) and Eye of the Emberseer (Molten Core) are in the data, but neither raid is in Forever.",
        "Onyxia's Lair is in Forever, so the Drakefire Amulet chains matter for both factions.",
        "Finkle Einhorn now needs level 57. The Demon Forge plans now need Blacksmithing 260.",
    ],
    "sources": ["https://foreverchanges.pro/quests/blackrock-spire", "https://conquestcapped.com/guides/wow-forever/"],
    "quests": [
        Q("Mayara Brightwing", "A", 57, "optional", None, "Count Remington Ridgewell, Stormwind Keep",
          [("SW", "take", "Count Remington Ridgewell, Stormwind Keep"), ("MORGANS", "turnin", "Mayara Brightwing")],
          note="Breadcrumb. One guide says it's required for Doomrigger's Clasp."),
        Q("Doomrigger's Clasp", "A", 57, "pre_run_pickup", True, "Mayara Brightwing, Morgan's Vigil (84.8, 69.1)",
          [("MORGANS", "take", "Mayara Brightwing")]),
        Q("Delivery to Ridgewell", "A", 57, "followup", None, "Mayara Brightwing, Morgan's Vigil"),
        Q("General Drakkisath's Demise", "A", 55, "pre_run_pickup", None, "Marshal Maxwell, Morgan's Vigil (84.7, 69.0)",
          [("MORGANS", "take", "Marshal Maxwell")], pre=True, note="Needs General Drakkisath's Command (LBRS) turned in."),
        Q("Drakefire Amulet", "A", 50, "attunement", True, "Haleh, Mazthoril, Winterspring (54.5, 51.2)",
          [("HALEH", "take", "Haleh")], pre=True, optRoute=True, ch="changed",
          note="Alliance Onyxia key. Last step of the Windsor chain (BRD) and The Great Masquerade."),
        Q("For The Horde!", "H", 55, "attunement", False, "Thrall, Grommash Hold, Orgrimmar",
          [("ORG", "take", "Thrall")], pre=True, optRoute=True, ch="changed", note="Needs Warlord's Command (LBRS) and Eitrigg's Wisdom."),
        Q("Oculus Illusions", "H", 55, "followup", None, "Myranda the Hag, Western Plaguelands", note="Horde Onyxia chain, after For The Horde!"),
        Q("Blood of the Black Dragon Champion", "H", 55, "followup", True, "Rexxar, Desolace/Feralas road", note="Horde Onyxia key, end of the chain."),
        Q("The Darkstone Tablet", "H", 57, "pre_run_pickup", True, "Shadowmage Vivian Lagrave, Kargath",
          [("KARGATH", "take", "Shadowmage Vivian Lagrave")]),
        Q("Vivian Lagrave and the Darkstone Tablet", "H", 57, "optional", None, "Apothecary Zinge, Undercity",
          [("UC", "take", "Apothecary Zinge, The Apothecarium"), ("KARGATH", "turnin", "Shadowmage Vivian Lagrave")], note="Breadcrumb."),
        Q("Egg Freezing", "B", 57, "pre_run_pickup", False, "Tinkee Steamboil, Flame Crest (65.2, 24.0)",
          [("FLAMECREST", "take", "Tinkee Steamboil: Broodling Essence"), ("BS_FIELD", "do", "Collect broodling essence from dragonkin", 8),
           ("FLAMECREST", "turnin", "Tinkee: turn in, take Felnok Steelspring"), ("EVERLOOK", "do", "Felnok Steelspring: take Chillwind Horns"),
           ("EVERLOOK", "do", "Kill Chillwind Chimaeras for the horns, return to Felnok", 10),
           ("FLAMECREST", "turnin", "Tinkee: Return to Tinkee, take Egg Freezing")], pre=True,
          note="Some guides call the Everlook breadcrumb optional; the chain order here follows the Forever tracker."),
        Q("Egg Collection", "B", 57, "followup", False, "Tinkee Steamboil, Flame Crest", note="Leads to Dawn's Gambit (Scholomance)."),
        Q("The Demon Forge", "B", 55, "pre_run_pickup", None, "Lorax, Winterspring",
          [("LORAX", "take", "Lorax: listen to Lorax's Tale, take The Demon Forge")], ch="changed",
          note="Plans now need Blacksmithing 260. One source says warriors and paladins only (unverified)."),
        Q("The Matron Protectorate", "B", 57, "inside_pickup", False, "Awbee (inside)", note="Leads to Haleh in Winterspring."),
        Q("Finkle Einhorn, At Your Service!", "B", 57, "inside_pickup", False, "Finkle Einhorn, after skinning The Beast", ch="changed",
          note="Only the skinner gets it."),
        Q("Mea Culpa, Lord Valthalak", "B", 58, "followup", False, "Bodley, Blackrock Mountain", status="unclear", note=UNCLEAR_T05),
        Q("Blackhand's Command", "B", 55, "attunement", False, "Item drop in LBRS", status="not_in_forever", note="Blackwing Lair isn't in Forever."),
        Q("Eye of the Emberseer", "B", 55, "attunement", True, "Duke Hydraxis, Azshara", status="not_in_forever", note="Molten Core chain; not in Forever."),
    ],
})

ORDER = ["brd", "dme", "lbrs", "bmh", "dmw", "dmn", "sht", "stratl", "stratu", "scholo", "ubrs"]
