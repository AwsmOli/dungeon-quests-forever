"""Package the addon for download.

    python tools/package_addon.py            -> dist/DungeonQuestsForever.zip
    python tools/package_addon.py --version  -> prints the version from the TOC

The zip holds one folder, DungeonQuestsForever/, ready to drop into
World of Warcraft/_forever_/Interface/AddOns/.
"""
import os, re, sys, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAME = "DungeonQuestsForever"
SRC = os.path.join(ROOT, "addon", NAME)
TOC = os.path.join(SRC, NAME + ".toc")


def toc_version():
    m = re.search(r"^## Version:\s*(\S+)", open(TOC, encoding="utf-8").read(), re.M)
    if not m:
        sys.exit("no ## Version in the TOC")
    return m.group(1)


def toc_files():
    """Every file the TOC loads, plus the TOC itself. Fails if one is missing."""
    files = [NAME + ".toc"]
    for line in open(TOC, encoding="utf-8").read().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            files.append(line.replace("\\", "/"))
    missing = [f for f in files if not os.path.isfile(os.path.join(SRC, f))]
    if missing:
        sys.exit("files named in the TOC are missing: " + ", ".join(missing))
    return files


def main():
    if "--version" in sys.argv:
        print(toc_version())
        return
    version = toc_version()
    os.makedirs(os.path.join(ROOT, "dist"), exist_ok=True)
    out = os.path.join(ROOT, "dist", NAME + ".zip")
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in toc_files():
            z.write(os.path.join(SRC, f), NAME + "/" + f)
    print(f"wrote {os.path.relpath(out, ROOT)} (version {version}, {os.path.getsize(out):,} bytes)")


if __name__ == "__main__":
    main()
