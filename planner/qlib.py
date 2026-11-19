"""Helpers for writing dungeon quest data. See planner/dungeons/README.md."""


def hub(name, zone, cont, x, y, a=0, h=0):
    return {"name": name, "zone": zone, "cont": cont, "x": x, "y": y, "ride": {"A": a, "H": h}}


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
