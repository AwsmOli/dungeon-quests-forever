# Dungeon Quests: WoW Forever

A route planner for WoW Forever dungeon quests. Pick your faction, your party (up to 5) and who can teleport. The planner works out the quickest way to pick up every quest before the run. When splitting up is faster, it says who goes where and who shares which quest when you meet.

**Live site:** https://awsmoli.github.io/dungeon-quests-forever/

## What it covers

All 35 WoW Forever dungeons, from Ragefire Chasm and the Hall of Thanes up to Upper Blackrock Spire. That includes the 9 dungeons new in Forever: Hall of Thanes, Ruins of Lordaeron, Excavation Site: Wetlands, City of Dalaran, The Drowned City, Krol'dok Stronghold, Alcaz Prison, Blackmaw Hold and Shaper's Terrace. The dungeon list is sorted by the level you need to accept every quest for one run.

The planner knows when travel abilities unlock. Mage teleports come at 20 (Darnassus and Thunder Bluff at 30) and portals at 40 (50). Riding is 40, Ritual of Summoning 20 and Teleport: Moonglade 10. Below 40 everyone runs, and the boat network includes Forever's Stormwind ↔ Auberdine and Steamwheedle Port ↔ Riverglades routes.

For each dungeon you get:

- The earliest level at which you can accept everything for one run, and the level for the whole quest set including follow-ups
- A pickup route that uses mage portals, warlock summons, druid Moonglade teleports and engineering teleporters when your party has them
- For bigger groups, a split plan: one route per player, a meeting point, and a list of who shares what
- Quests picked up inside, follow-ups, optional and class quests, and quests that aren't in Forever or whose status is unclear

## In-game addon

`addon/DungeonQuestsForever` is a WoW Forever addon built from the same data. It knows your level, quest log and party, ticks steps off as you go, and puts the route on your world map and minimap.

**[Download DungeonQuestsForever.zip](https://github.com/AwsmOli/dungeon-quests-forever/releases/latest/download/DungeonQuestsForever.zip)**, unzip it, and put the folder in `World of Warcraft\_forever_\Interface\AddOns\`. More in [addon/README.md](addon/README.md).

## How it works

- `planner/data.py`: endgame quest data, the base map (places, positions, flight access) and boats
- `planner/dungeons/*.py`: the other dungeon groups. `planner/dungeons/README.md` explains the format, and `python planner/check.py <file>` checks one file
- `planner/engine.js`: the planner. It runs a greedy tour that respects quest chain order, and assigns shareable pickups to players by brute force
- `planner/template.html`: the page
- `planner/build.py`: combines these into `index.html`

```bash
python planner/build.py          # rebuild index.html
node planner/test.js             # print plans for sample parties
node planner/domtest.js index.html  # render every dungeon and check for errors
```

## Caveats

- Quest data comes from community trackers that read Forever's game data (mainly [foreverchanges.pro](https://foreverchanges.pro), build 1.60.1), plus ConquestCapped, Zockify, Warcraft Tavern and warcraft.wiki.gg. Classic details fill the gaps. NPC positions are mostly Classic's, so check anything marked "unclear" in game.
- Travel times come from a rough map model. Use them to compare plans, not as exact times.
- This is a fan project, not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment.
