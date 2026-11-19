"""Low-level Classic dungeons: The Deadmines, Shadowfang Keep, The Stockade, Blackfathom Deeps.

Forever data from foreverchanges.pro (build 1.60.1.70959), warcrafttavern.com/forever, method.gg/wow-forever and
conquestcapped. Giver coordinates and some chain details are filled in from Classic (wowhead, warcraft.wiki.gg).
"""
from qlib import hub, Q

HUBS = {
    # Westfall / Duskwood / Stormwind
    "SENTINEL": hub("Sentinel Hill", "Westfall", "EK", 37, 83, 0, 7),
    "DM_ENTRANCE": hub("The Deadmines (Moonbrook)", "Westfall", "EK", 35, 86, 3, 7),
    "STOCKADE": hub("The Stockade (Mage Quarter)", "Stormwind City", "EK", 41, 78, 2, None),
    "DARKSHIRE": hub("Darkshire", "Duskwood", "EK", 49, 85, 0, 6),
    "DUNMODR": hub("Dun Modr", "Wetlands", "EK", 46, 45, 6, 8),
    # Silverpine
    "SEPULCHER": hub("The Sepulcher", "Silverpine Forest", "EK", 38, 29, 10, 0),
    "SFK_ENTRANCE": hub("Shadowfang Keep", "Silverpine Forest", "EK", 38, 32, 8, 3),
    # Kalimdor
    "ZORAMGAR": hub("Zoram'gar Outpost", "Ashenvale", "K", 38, 29, 5, 0),
    "BFD_ENTRANCE": hub("Blackfathom Deeps (Zoram Strand)", "Ashenvale", "K", 37, 27, 6, 2),
    "ASTRANAAR": hub("Astranaar", "Ashenvale", "K", 46, 31, 0, 5),
    "SUNROCK": hub("Sun Rock Retreat", "Stonetalon Mountains", "K", 43, 41, 4, 0),
    "DOAN_KARHAN": hub("Doan Karhan, near Camp Taurajo", "The Barrens", "K", 53, 60, 7, 2),
}

# Shared class quest entries (same giver and chain, used in several dungeons)
_TEST_RIGHT = dict(
    n="The Test of Righteousness", f="A", req=20, cat="class", share=False,
    start="Jordan Stilwell, outside the Ironforge gate, Dun Morogh (52.5, 36.8)",
    path=[("IF", "take", "Jordan Stilwell, just outside the Ironforge gate", 1)],
)
_MOON_BLADE = dict(
    n="A Moon-Kissed Blade", f="H", req=20, cat="class", share=False,
    start="Lumina Windsinger, The Sepulcher, Silverpine Forest (43.2, 41.0)",
    path=[("SEPULCHER", "take", "Lumina Windsinger (after The Debt)")],
)
_ORB = dict(
    n="The Orb of Soran'ruk", f="B", req=20, cat="class", share=False,
    start="Doan Karhan, near Camp Taurajo, The Barrens (49.2, 57.2)",
    path=[("DOAN_KARHAN", "take", "Doan Karhan")],
)


def _c(base, **kw):
    d = dict(base)
    d.update(kw)
    return Q(d.pop("n"), d.pop("f"), d.pop("req"), d.pop("cat"), d.pop("share"), d.pop("start"), d.pop("path", None), **d)


DUNGEONS = []

# ======================= The Deadmines =======================
DUNGEONS.append({
    "id": "dm", "name": "The Deadmines", "short": "DM", "range": "17-26", "entrance": "DM_ENTRANCE", "isNew": False,
    "aka": None,
    "entranceNote": "Moonbrook, southern Westfall: enter the mine in the old town hall. No key needed.",
    "notes": [
        "New in Forever: Destruction in Deadmines, the end of Alba Fairmoon's 11-step Toxic Soil chain (Westfall and Stormwind).",
        "Alba waits at the Deadmines exit with the detonator, so leave by the back door to finish part 2.",
        "All Classic quests carry over with about double XP. Rewards are still Classic's on the trackers.",
        "Paladins of both factions collect Whitestone Oak Lumber here for their level 20 weapon chains. Horde paladins (Undead) are new in Forever.",
        "Collecting Memories and Oh Brother are done in the tunnels before the instance portal.",
    ],
    "sources": ["https://foreverchanges.pro/quests/the-deadmines",
                "https://foreverchanges.pro/dungeons/the-deadmines",
                "https://foreverchanges.pro/quest/92753/destruction-in-deadmines",
                "https://www.warcrafttavern.com/forever/guides/the-deadmines-quests/",
                "https://conquestcapped.com/guides/wow-forever/wow-forever-paladin-weapon-quest/",
                "https://warcraft.wiki.gg/wiki/A_Moon-Kissed_Blade"],
    "quests": [
        Q("Destruction in Deadmines", "A", 9, "pre_run_pickup", False, "Alba Fairmoon, Sentinel Hill, Westfall (52.5, 53.1)",
          [("SENTINEL", "take", "Alba Fairmoon (after the Toxic Soil chain)")], pre=True, ch="new",
          note="Needs the Testing the Wells chain first, with Stormwind steps and 10 Rough Dynamite. Plant explosives by Gilnid's forge."),
        Q("Destruction in Deadmines (part 2)", "A", 9, "inside_pickup", False, "Alba Fairmoon, at the Deadmines exit (38.7, 83.8)",
          after=["Destruction in Deadmines"], ch="new", note="Use the detonator at the exit. Turn in to Alba."),
        Q("The Defias Brotherhood", "A", 14, "pre_run_pickup", True, "Gryan Stoutmantle, Sentinel Hill (56.3, 47.5)",
          [("SENTINEL", "take", "Gryan Stoutmantle")], pre=True, ch="changed",
          note="Last step of the Defias Brotherhood chain (Westfall, Stormwind, Redridge, escort). Kill VanCleef."),
        Q("Red Silk Bandanas", "A", 14, "pre_run_pickup", True, "Scout Riell, Sentinel Hill tower (56.6, 47.6)",
          [("SENTINEL", "take", "Scout Galiaan: Red Leather Bandanas"),
           ("DM_ENTRANCE", "do", "Kill Defias around Moonbrook for 15 Red Leather Bandanas", 8),
           ("SENTINEL", "turnin", "Scout Galiaan"), ("SENTINEL", "take", "Scout Riell, top of the tower")],
          pre=True, ch="changed", note="Needs Red Leather Bandanas first. Warcraft Tavern lists level 15."),
        Q("Collecting Memories", "A", 14, "pre_run_pickup", True, "Wilder Thistlenettle, Dwarven District, Stormwind (65.4, 21.2)",
          [("SW", "take", "Wilder Thistlenettle, Dwarven District")], ch="changed",
          note="4 Miners' Union Cards from undead miners outside the portal."),
        Q("Oh Brother...", "A", 15, "pre_run_pickup", True, "Wilder Thistlenettle, Dwarven District, Stormwind (65.4, 21.2)",
          [("SW", "take", "Wilder Thistlenettle, Dwarven District")], ch="changed",
          note="Foreman Thistlenettle, outside the portal."),
        Q("Underground Assault", "A", 15, "pre_run_pickup", True, "Shoni the Shilent, Dwarven District, Stormwind (55.6, 12.6)",
          [("SW", "take", "Shoni the Shilent, Dwarven District")], ch="changed", note="Gnoam Sprecklesprocket from Sneed's Shredder."),
        Q("Speak with Shoni", "A", 15, "optional", True, "Gnoarn, Tinker Town, Ironforge (69.4, 50.6)",
          [("IF", "take", "Gnoarn, Tinker Town"), ("SW", "turnin", "Shoni the Shilent")],
          note="Breadcrumb for Underground Assault. Trackers list it as step 1, but it isn't confirmed as required."),
        Q("The Unsent Letter", "A", 16, "inside_pickup", False, "An Unsent Letter (drops from Edwin VanCleef)",
          note="Turn in to Baros Alexston, Stormwind. Leads to The Stockade Riots."),
        _c(_TEST_RIGHT, cls="Paladin", pre=True,
           note="Whitestone Oak Lumber from Goblin Woodcarvers. Needs The Tome of Valor chain. Reward Verigan's Fist."),
        _c(_MOON_BLADE, cls="Paladin", pre=True, ch="new",
           note="Undead paladins. Whitestone Oak Lumber from Goblin Woodcarvers. Chain starts with Diplomatic Incident, Tirisfal."),
    ],
})

# ======================= Shadowfang Keep =======================
DUNGEONS.append({
    "id": "sfk", "name": "Shadowfang Keep", "short": "SFK", "range": "20-30", "entrance": "SFK_ENTRANCE", "isNew": False,
    "aka": None,
    "entranceNote": "Castle on the hill above Pyrewood Village, southern Silverpine Forest. No key needed.",
    "notes": [
        "The three main quests are Horde only. Alliance only has class quests here.",
        "New in Forever: A Moon-Kissed Blade for Undead paladins (Enchanted Silver Ingot on a table in Arugal's room).",
        "Alliance paladins click Jordan's Smithing Hammer inside for The Test of Righteousness.",
        "foreverchanges lists the range as 22-30. Classic quests pay about 2.7 times the old XP.",
    ],
    "sources": ["https://foreverchanges.pro/quests/shadowfang-keep",
                "https://foreverchanges.pro/dungeons/shadowfang-keep",
                "https://www.method.gg/wow-forever/dungeons/shadowfang-keep",
                "https://www.warcrafttavern.com/forever/guides/shadowfang-keep-quests/",
                "https://conquestcapped.com/guides/wow-forever/wow-forever-paladin-weapon-quest/",
                "https://warcraft.wiki.gg/wiki/A_Moon-Kissed_Blade"],
    "quests": [
        Q("The Book of Ur", "H", 16, "pre_run_pickup", True, "Keeper Bel'dugur, The Apothecarium, Undercity (53.8, 74.8)",
          [("UC", "take", "Keeper Bel'dugur, The Apothecarium")], ch="changed"),
        Q("Deathstalkers in Shadowfang", "H", 18, "pre_run_pickup", True, "High Executor Hadrec, The Sepulcher (43.4, 40.8)",
          [("SEPULCHER", "take", "High Executor Hadrec")], ch="changed", note="Find Adamant and Vincent inside."),
        Q("Arugal Must Die", "H", 18, "pre_run_pickup", True, "Dalar Dawnweaver, The Sepulcher (44.2, 39.8)",
          [("SEPULCHER", "take", "Dalar Dawnweaver")], ch="changed", note="Reward Seal of Sylvanas."),
        _c(_ORB, cls="Warlock", note="Large Soran'ruk Fragment from Shadowfang Darksoul. The 3 small ones come from BFD."),
        _c(_TEST_RIGHT, cls="Paladin", pre=True, note="Jordan's Smithing Hammer is an object inside. Needs The Tome of Valor chain."),
        _c(_MOON_BLADE, cls="Paladin", pre=True, ch="new",
           note="Undead paladins. Enchanted Silver Ingot on a table by Arugal after he dies. One guide says Tauren too."),
    ],
})

# ======================= The Stockade =======================
DUNGEONS.append({
    "id": "stocks", "name": "The Stockade", "short": "Stocks", "range": "24-32", "entrance": "STOCKADE", "isNew": False,
    "aka": "Stormwind Stockades",
    "entranceNote": "Inside Stormwind City, by the canal between the Mage Quarter and Old Town. Horde can't reach it.",
    "notes": [
        "All six quests are Alliance and unchanged from Classic apart from XP (about double).",
        "The Stockade Riots needs An Unsent Letter from VanCleef in the Deadmines.",
        "The Fury Runs Deep needs The Dark Iron War from Motley Garmason in Dun Modr first.",
    ],
    "sources": ["https://foreverchanges.pro/dungeons/the-stockade",
                "https://www.warcrafttavern.com/forever/guides/the-stockade-quests/"],
    "quests": [
        Q("Quell The Uprising", "A", 22, "pre_run_pickup", True, "Warden Thelwater, Stockade entrance, Stormwind (41.2, 58.0)",
          [("STOCKADE", "take", "Warden Thelwater")], ch="changed"),
        Q("The Color of Blood", "A", 22, "pre_run_pickup", True, "Nikova Raskol, Old Town, Stormwind (73.0, 46.0)",
          [("SW", "take", "Nikova Raskol, walks around Old Town", 2)], ch="changed"),
        Q("What Comes Around...", "A", 22, "pre_run_pickup", True, "Guard Berton, Lakeshire, Redridge (26.6, 46.4)",
          [("LAKESHIRE", "take", "Guard Berton")], ch="changed", note="Head of Targorr the Dread."),
        Q("Crime and Punishment", "A", 22, "pre_run_pickup", True, "Councilman Millstipe, Darkshire, Duskwood (72.0, 47.6)",
          [("DARKSHIRE", "take", "Councilman Millstipe, town hall")], ch="changed", note="Hand of Dextren Ward."),
        Q("The Fury Runs Deep", "A", 25, "pre_run_pickup", True, "Motley Garmason, Dun Modr, Wetlands (49.8, 18.2)",
          [("DUNMODR", "take", "Motley Garmason: The Dark Iron War"), ("DUNMODR", "do", "Kill Dark Iron dwarves around Dun Modr", 8),
           ("DUNMODR", "turnin", "Motley Garmason"), ("DUNMODR", "take", "Motley Garmason: The Fury Runs Deep")],
          pre=True, note="Head of Kam Deepfury. Forever XP not yet recorded."),
        Q("The Stockade Riots", "A", 16, "pre_run_pickup", True, "Warden Thelwater, Stockade entrance, Stormwind",
          [("SW", "turnin", "Baros Alexston, City Hall: The Unsent Letter, take Bazil Thredd"),
           ("STOCKADE", "turnin", "Warden Thelwater: Bazil Thredd"), ("STOCKADE", "take", "Warden Thelwater: The Stockade Riots")],
          pre=True, ch="changed", note="Needs An Unsent Letter from VanCleef (Deadmines). Head of Bazil Thredd."),
    ],
})

# ======================= Blackfathom Deeps =======================
DUNGEONS.append({
    "id": "bfd", "name": "Blackfathom Deeps", "short": "BFD", "range": "24-32", "entrance": "BFD_ENTRANCE", "isNew": False,
    "aka": None,
    "entranceNote": "Zoram Strand, northwest Ashenvale. Swim down into the temple ruins in the lake. No key needed.",
    "notes": [
        "No new or removed quests. XP is about 2.3 times Classic's. Baron Aquanis gained a Dreamer's Chestguard reward choice.",
        "Paladin weapon chains (both factions) need a Corrupted Kor Gem from naga in the caves before the portal. You don't need to zone in.",
        "Twilight Acolytes inside drop the small Soran'ruk Fragments for the warlock Orb quest.",
        "The Essence of Aku'Mai sapphires are on the cave walls before the portal.",
    ],
    "sources": ["https://foreverchanges.pro/dungeons/blackfathom-deeps",
                "https://foreverchanges.pro/quest/6922/baron-aquanis",
                "https://foreverchanges.pro/quest/1198/in-search-of-thaelrid",
                "https://foreverchanges.pro/quest/6562/trouble-in-the-deeps",
                "https://foreverchanges.pro/quest/3765/the-corruption-abroad",
                "https://www.warcrafttavern.com/forever/guides/blackfathom-deeps-quests/",
                "https://conquestcapped.com/guides/wow-forever/wow-forever-paladin-weapon-quest/",
                "https://warcraft.wiki.gg/wiki/A_Moon-Kissed_Blade"],
    "quests": [
        # Alliance
        Q("Knowledge in the Deeps", "A", 10, "pre_run_pickup", True, "Gerrig Bonegrip, The Forlorn Cavern, Ironforge (50.8, 5.6)",
          [("IF", "take", "Gerrig Bonegrip, The Forlorn Cavern")], ch="changed",
          note="Lorgalis Manuscript in the Ghamoo-ra room. Warcraft Tavern lists level 18."),
        Q("Researching the Corruption", "A", 18, "pre_run_pickup", True, "Gershala Nightwhisper, Auberdine, Darkshore (38.3, 43.0)",
          [("AUBERDINE", "take", "Gershala Nightwhisper")], note="8 Corrupted Brain Stems, inside and outside."),
        Q("The Corruption Abroad", "A", 18, "optional", True, "Argos Nightwhisper, Stormwind (36.2, 67.6)",
          [("SW", "take", "Argos Nightwhisper"), ("AUBERDINE", "turnin", "Gershala Nightwhisper")],
          note="Breadcrumb for Researching the Corruption."),
        Q("In Search of Thaelrid", "A", 18, "pre_run_pickup", True, "Dawnwatcher Shaedlass, Craftsmen's Terrace, Darnassus (55.4, 25.0)",
          [("DARN", "take", "Dawnwatcher Shaedlass, Craftsmen's Terrace")], ch="changed",
          note="Turn in to Argent Guard Thaelrid inside."),
        Q("Twilight Falls", "A", 20, "pre_run_pickup", True, "Argent Guard Manados, Craftsmen's Terrace, Darnassus (55.2, 24.6)",
          [("DARN", "take", "Argent Guard Manados, Craftsmen's Terrace")], ch="changed", note="10 Twilight Pendants."),
        Q("Blackfathom Villainy", "A", 18, "inside_pickup", True, "Argent Guard Thaelrid (inside)", after=["In Search of Thaelrid"],
          ch="changed", note="Head of Kelris to Dawnwatcher Selgorm, Darnassus."),
        # Horde
        Q("The Essence of Aku'Mai", "H", 17, "pre_run_pickup", True, "Je'neu Sancrea, Zoram'gar Outpost, Ashenvale (11.6, 34.3)",
          [("ZORAMGAR", "take", "Je'neu Sancrea")],
          note="20 Sapphires of Aku'Mai before the portal. foreverchanges lists Trouble in the Deeps as its prequest."),
        Q("Trouble in the Deeps", "H", 17, "optional", True, "Tsunaman, Sun Rock Retreat, Stonetalon (47.4, 64.2)",
          [("SUNROCK", "take", "Tsunaman"), ("ZORAMGAR", "turnin", "Je'neu Sancrea")],
          note="Breadcrumb for The Essence of Aku'Mai. Warcraft Tavern calls it optional."),
        Q("Allegiance to the Old Gods", "H", 17, "pre_run_pickup", True, "Je'neu Sancrea, Zoram'gar Outpost (after the Damp Note)",
          [("BFD_ENTRANCE", "do", "Kill Blackfathom Tide Priestesses outside the portal until a Damp Note drops", 8),
           ("ZORAMGAR", "turnin", "Je'neu Sancrea: the Damp Note"), ("ZORAMGAR", "take", "Je'neu Sancrea: part 2")],
          pre=True, ch="changed", note="Part 1 starts from the Damp Note and can't be shared. Part 2: kill Lorgus Jett."),
        Q("Amongst the Ruins", "H", 21, "pre_run_pickup", True, "Je'neu Sancrea, Zoram'gar Outpost (11.6, 34.3)",
          [("ZORAMGAR", "take", "Je'neu Sancrea")], ch="changed",
          note="Summon Baron Aquanis at the underwater stone; each player clicks it for the Fathom Core."),
        Q("Baron Aquanis", "H", 21, "inside_pickup", False, "Strange Water Globe (drops from Baron Aquanis)", after=["Amongst the Ruins"],
          ch="changed", note="Turn in to Je'neu Sancrea. New reward choice: Dreamer's Chestguard."),
        Q("Blackfathom Villainy", "H", 18, "inside_pickup", True, "Argent Guard Thaelrid (inside)",
          note="No prequest for Horde. Head of Kelris to Bashana Runetotem, Thunder Bluff."),
        # Class
        _c(_ORB, cls="Warlock", note="3 Soran'ruk Fragments from Twilight Acolytes. The large one is from SFK."),
        _c(_TEST_RIGHT, cls="Paladin", pre=True,
           note="Corrupted Kor Gem from naga before the portal. Tandaan Lightmane in Astranaar purifies it."),
        Q("Seeking the Kor Gem", "H", 20, "class", None, "Ulric Frostveil, Zoram'gar Outpost, Ashenvale (11.8, 34.5)",
          [("ZORAMGAR", "take", "Ulric Frostveil")], cls="Paladin", pre=True, ch="new",
          note="Undead paladins, during A Moon-Kissed Blade. Corrupted Kor Gem from naga before the portal. Level assumed."),
    ],
})
