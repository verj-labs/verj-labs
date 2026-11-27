#!/usr/bin/env python3
"""Tries balance changes side by side without touching the real project.

Each variant gets its own copy of godot/ (in a temporary folder), with constants changed, and
all variants play tools/balance.gd in parallel. Compare the lines, pick the best, then make that
change for real. See docs/BALANCE.md.

  python3 tools/sweep.py --variant "upgrades.SCALE_C=0.04" --variant "upgrades.SCALE_C=0.03" -- fresh mid

A variant is a ';'-separated list of edits:
  FILE.CONST=VALUE        sets `const CONST := ...` in godot/core/FILE.gd
  FILE~REGEX~REPLACEMENT  a regular-expression edit in godot/core/FILE.gd (for dictionary entries)
Use an empty variant ("") as the baseline. Arguments after -- go to balance.gd (profiles,
seeds=, tier=, hero=, cap=). Godot is found from $GODOT_BIN or `godot` on the PATH.
"""
import argparse
import os
import re
import shutil
import subprocess
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def apply(project, variant):
    for edit in filter(None, (e.strip() for e in variant.split(";"))):
        if "~" in edit:
            name, pattern, repl = edit.split("~", 2)
            path = os.path.join(project, "core", name + ".gd")
            text, n = re.subn(pattern, repl, open(path).read())
        else:
            target, value = edit.split("=", 1)
            name, const = target.split(".", 1)
            path = os.path.join(project, "core", name + ".gd")
            text, n = re.subn(rf"^const {re.escape(const)}( *:?= *)[^#\n]*", rf"const {const}\g<1>{value}", open(path).read(), flags=re.M)
        if n == 0:
            raise SystemExit(f"edit matched nothing: {edit}")
        open(path, "w").write(text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", action="append", default=[], help="edits to try (repeatable)")
    parser.add_argument("rest", nargs="*", help="arguments for balance.gd")
    args = parser.parse_args()
    godot = os.environ.get("GODOT_BIN") or shutil.which("godot")
    if not godot:
        raise SystemExit("Godot not found: set GODOT_BIN")
    work = tempfile.mkdtemp(prefix="flintkeep-sweep-")
    runs = []
    for i, variant in enumerate(args.variant or [""]):
        project = os.path.join(work, f"v{i}", "godot")
        shutil.copytree(os.path.join(ROOT, "godot"), project, ignore=shutil.ignore_patterns("builds"))
        shutil.copytree(os.path.join(ROOT, "tools"), os.path.join(work, f"v{i}", "tools"))
        apply(project, variant)
        cmd = [godot, "--headless", "--path", project, "-s", "../tools/balance.gd", "--"] + args.rest
        runs.append((variant or "(baseline)", subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)))
    for variant, proc in runs:
        out = proc.communicate()[0]
        lines = [l for l in out.splitlines() if " waves " in l or "SCRIPT ERROR" in l]
        print(f"== {variant}")
        for line in lines:
            print("   " + line)
    shutil.rmtree(work, ignore_errors=True)


if __name__ == "__main__":
    main()
