#!/usr/bin/env python3
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/"scripts"
errors=[]
for path in sorted(ROOT.rglob("*.gd")):
    lines=path.read_text(encoding="utf-8", errors="ignore").splitlines()
    for i,line in enumerate(lines):
        stripped=line.strip()
        if not stripped or stripped.startswith("#") or not stripped.endswith(":"):
            continue
        indent=len(line)-len(line.lstrip("\t "))
        j=i+1
        while j<len(lines) and (not lines[j].strip() or lines[j].lstrip().startswith("#")):
            j+=1
        if j>=len(lines):
            continue
        next_indent=len(lines[j])-len(lines[j].lstrip("\t "))
        if next_indent<=indent:
            errors.append(f"{path.relative_to(ROOT)}:{i+1}: block has no indented body; next code line is {j+1}")
if errors:
    print("\n".join("ERROR: "+e for e in errors))
    raise SystemExit(1)
print("PASS: all GDScript block starters have indented bodies")
