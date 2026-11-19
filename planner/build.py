"""Build the planner.

    python planner/build.py            -> index.html (standalone page for GitHub Pages)
    python planner/build.py --artifact -> build/artifact.html (body-only page for a claude.ai artifact)
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from data import HUBS, DUNGEONS, ORDER, BOATS, RULES

# Source links per dungeon (taken from the research notes).
SOURCES = json.load(open(os.path.join(HERE, "sources.json"), encoding="utf-8"))

errors = []
for d in DUNGEONS:
    if d["id"] in SOURCES:
        d["sources"] = SOURCES[d["id"]]
    if d["entrance"] not in HUBS:
        errors.append(f"{d['id']}: entrance {d['entrance']}")
    names = {q["n"] for q in d["quests"]}
    for q in d["quests"]:
        p = q.get("path")
        paths = p.values() if isinstance(p, dict) else ([p] if p else [])
        for pp in paths:
            for s in pp:
                if s["hub"] not in HUBS:
                    errors.append(f"{d['id']}/{q['n']}: hub {s['hub']}")
        for a in q.get("after", []):
            if a not in names:
                errors.append(f"{d['id']}/{q['n']}: after {a}")
if errors:
    print("ERRORS:\n" + "\n".join(errors))
    sys.exit(1)

dmap = {d["id"]: d for d in DUNGEONS}
boats = [{"a": a, "b": b_, "f": f, "min": m} for a, b_, f, m in BOATS if a in HUBS and b_ in HUBS]
for a, b_, f, m in BOATS:
    if a not in HUBS or b_ not in HUBS:
        print(f"note: boat {a}-{b_} skipped, unknown dock")
out = {"hubs": HUBS, "boats": boats, "rules": RULES, "dungeons": [dmap[i] for i in ORDER]}
json.dump(out, open(os.path.join(HERE, "data.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)

tpl = open(os.path.join(HERE, "template.html"), encoding="utf-8").read()
engine = open(os.path.join(HERE, "engine.js"), encoding="utf-8").read()
body = tpl.replace("/*__ENGINE__*/", engine).replace("/*__DATA__*/", json.dumps(out, ensure_ascii=False, separators=(",", ":")))

if "--artifact" in sys.argv:
    os.makedirs(os.path.join(ROOT, "build"), exist_ok=True)
    target = os.path.join(ROOT, "build", "artifact.html")
    html = body
else:
    # Standalone page: split the template's head part (title, fonts, styles) from the content.
    head, rest = body.split("</style>", 1)
    head = head.replace('<meta name="claude:viewport-fit-sides" content="cover">\n', "")
    reset = ("<style>html{color-scheme:light}:root{padding-top:env(safe-area-inset-top,0px);"
             "padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}img{max-width:100%}"
             "[hidden]{display:none!important}</style>\n")
    html = ("<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, viewport-fit=cover\">\n"
            "<meta name=\"description\" content=\"Plan the fastest pickup route for every dungeon quest in WoW Forever, "
            "for your party, faction and teleports.\">\n"
            + reset + head + "</style>\n</head>\n<body>\n" + rest.lstrip() + "\n</body>\n</html>\n")
    target = os.path.join(ROOT, "index.html")

open(target, "w", encoding="utf-8").write(html)
print(f"wrote {os.path.relpath(target, ROOT)} ({len(html):,} bytes): {len(DUNGEONS)} dungeons, "
      f"{sum(len(d['quests']) for d in DUNGEONS)} quests")
