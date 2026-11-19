# Dungeon Quests: WoW Forever

A route planner for WoW Forever dungeon quests. Pick your faction, your party (up to 5) and who can teleport. The planner works out the quickest way to pick up every quest before the run. When splitting up is faster, it says who goes where and who shares which quest when you meet.

**Live site:** https://awsmoli.github.io/dungeon-quests-forever/

## What it covers

Blackrock Depths and the 10 dungeons after it: Dire Maul (East, West, North), Lower and Upper Blackrock Spire, Stratholme (both gates), Scholomance, and the new Forever dungeons Blackmaw Hold and Shaper's Terrace.

For each dungeon you get:

- The earliest level at which you can accept everything for one run, and the level for the whole quest set including follow-ups
- A pickup route that uses mage portals, warlock summons, druid Moonglade teleports and engineering teleporters when your party has them
- For bigger groups, a split plan: one route per player, a meeting point, and a list of who shares what
- Quests picked up inside, follow-ups, optional and class quests, and quests that aren't in Forever or whose status is unclear

## How it works

- `planner/data.py`: quest data and the map model (places, positions, flight access)
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
