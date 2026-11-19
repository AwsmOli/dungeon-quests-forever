"""Check one dungeon group file on its own and print sample plans.

    python planner/check.py planner/dungeons/g1_barrens.py
"""
import importlib.util, json, os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

# Base hubs only (don't load the other group files, which may be half-written).
import qlib  # noqa: F401
base_src = open(os.path.join(HERE, "data.py"), encoding="utf-8").read().split("# ---------- load the other dungeon groups")[0]
base = {}
exec(compile(base_src, "data.py", "exec"), base)
HUBS = dict(base["HUBS"])

# Places defined by the other group files can be reused too.
import glob
for other in sorted(glob.glob(os.path.join(HERE, "dungeons", "*.py"))):
    if os.path.abspath(other) == os.path.abspath(sys.argv[1]):
        continue
    try:
        sp = importlib.util.spec_from_file_location("other", other); om = importlib.util.module_from_spec(sp); sp.loader.exec_module(om)
        for k, v in getattr(om, "HUBS", {}).items():
            HUBS.setdefault(k, v)
    except Exception as e:  # a half-written file shouldn't block checking this one
        print(f"note: skipped {os.path.basename(other)}: {e}")

fn = sys.argv[1]
spec = importlib.util.spec_from_file_location("frag", fn)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

errors, warns = [], []
for k, v in getattr(mod, "HUBS", {}).items():
    if k in base["HUBS"] and base["HUBS"][k] != v:
        errors.append(f"hub {k} already exists in data.py with different values; reuse it instead")
    for f in ("name", "zone", "cont", "x", "y", "ride"):
        if f not in v: errors.append(f"hub {k} missing {f}")
    if v.get("cont") not in ("EK", "K", "RG"):
        errors.append(f"hub {k}: cont must be EK, K or RG")
    HUBS[k] = v

CATS = {"pre_run_pickup", "inside_pickup", "followup", "optional", "attunement", "class"}
ids = set()
for d in mod.DUNGEONS:
    for f in ("id", "name", "short", "range", "entrance", "entranceNote", "notes", "sources", "quests"):
        if f not in d: errors.append(f"{d.get('id')}: missing {f}")
    if d["id"] in ids: errors.append(f"duplicate id {d['id']}")
    ids.add(d["id"])
    if d["entrance"] not in HUBS: errors.append(f"{d['id']}: entrance hub {d['entrance']} not defined")
    names = {q["n"] for q in d["quests"]}
    for q in d["quests"]:
        tag = f"{d['id']}/{q['n']}"
        if q["f"] not in ("A", "H", "B"): errors.append(f"{tag}: f must be A, H or B")
        if q["cat"] not in CATS: errors.append(f"{tag}: bad cat {q['cat']}")
        if q.get("status", "live") not in ("live", "unclear", "not_in_forever"): errors.append(f"{tag}: bad status")
        p = q.get("path")
        paths = list(p.values()) if isinstance(p, dict) else ([p] if p else [])
        for pp in paths:
            for s in pp:
                if s["hub"] not in HUBS: errors.append(f"{tag}: hub {s['hub']} not defined")
                if s["a"] not in ("take", "turnin", "do"): errors.append(f"{tag}: step action must be take/turnin/do")
            if pp and not any(s["a"] == "take" for s in pp): warns.append(f"{tag}: path has no 'take' step")
        if q["cat"] == "pre_run_pickup" and not p and not q.get("optRoute"):
            warns.append(f"{tag}: pre_run_pickup without a path (set optRoute=True if it needs a long chain)")
        for a in q.get("after", []):
            if a not in names: errors.append(f"{tag}: after '{a}' is not a quest in this dungeon")

print("\n".join("ERROR " + e for e in errors) or "no errors")
print("\n".join("warn  " + w for w in warns))
if errors:
    sys.exit(1)

tmp = os.path.join(tempfile.gettempdir(), "planner-check-" + os.path.basename(fn) + ".json")
boats = [{"a": a, "b": b, "f": f, "min": m} for a, b, f, m in base["BOATS"] + list(getattr(mod, "BOATS", [])) if a in HUBS and b in HUBS]
json.dump({"hubs": HUBS, "boats": boats, "dungeons": mod.DUNGEONS}, open(tmp, "w", encoding="utf-8"))
subprocess.run(["node", os.path.join(HERE, "test.js")], env=dict(os.environ, DATA=tmp), check=False)
