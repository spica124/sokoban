"""build_windows.py [--tpz PATH] - install export templates (optional) and build the Windows exe.

  python tools/build_windows.py                 build with already-installed templates
  python tools/build_windows.py --tpz file.tpz  install templates from a .tpz first, then build

Output: build/Sokoban.exe (pck embedded). Requires Godot at GODOT below.
"""
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GODOT = Path(r"C:\Users\limji\Godot\Godot.exe")
VERSION = "4.7.1.stable"
TEMPLATES = Path(os.environ["APPDATA"]) / "Godot" / "export_templates" / VERSION


def install_templates(tpz: Path) -> None:
    """A .tpz is a zip with a top-level 'templates/' folder."""
    TEMPLATES.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(tpz) as z:
        names = [n for n in z.namelist() if n.startswith("templates/") and not n.endswith("/")]
        for n in names:
            target = TEMPLATES / Path(n).name
            with z.open(n) as src, open(target, "wb") as dst:
                shutil.copyfileobj(src, dst)
    print(f"installed {len(names)} template files to {TEMPLATES}")


def build() -> int:
    out = ROOT / "build" / "Sokoban.exe"
    out.parent.mkdir(exist_ok=True)
    cmd = [str(GODOT), "--headless", "--path", str(ROOT), "--export-release", "Windows Desktop", str(out)]
    print(" ".join(cmd))
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    tail = "\n".join((r.stdout + r.stderr).splitlines()[-15:])
    print(tail)
    if out.exists():
        print(f"OK: {out} ({out.stat().st_size // 1024 // 1024} MB)")
        return 0
    print("FAILED: exe not produced")
    return 1


if __name__ == "__main__":
    if "--tpz" in sys.argv:
        install_templates(Path(sys.argv[sys.argv.index("--tpz") + 1]))
    needed = ["windows_release_x86_64.exe", "windows_debug_x86_64.exe"]
    missing = [n for n in needed if not (TEMPLATES / n).exists()]
    if missing:
        print("missing templates:", missing)
        sys.exit(2)
    sys.exit(build())
