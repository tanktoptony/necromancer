from pathlib import Path
import re, sys

ROOT=Path(__file__).resolve().parents[1]
errors=[]
warnings=[]

SCRIPT_CONSTANT_RE=re.compile(r'=\s*(?:Vector2|Vector2i|Vector3|Vector3i|Vector4|Color|Rect2|Rect2i|Transform2D|Transform3D|Basis|Quaternion|Plane|AABB)\.[A-Z_]+\s*$')
SECTION_RE=re.compile(r'^\[(\w+)(?:\s+(.*))?\]$')
ATTR_RE=re.compile(r'(\w+)=("(?:[^"\\]|\\.)*"|[^\s]+)')
EXT_DECL_RE=re.compile(r'^\[ext_resource\s+.*\bid="([^"]+)".*\]$')
SUB_DECL_RE=re.compile(r'^\[sub_resource\s+.*\bid="([^"]+)".*\]$')
EXT_USE_RE=re.compile(r'ExtResource\("([^"]+)"\)')
SUB_USE_RE=re.compile(r'SubResource\("([^"]+)"\)')

for path in sorted(ROOT.rglob('*.tscn')):
    rel=path.relative_to(ROOT)
    lines=path.read_text(encoding='utf-8',errors='replace').splitlines()
    if not lines or not lines[0].startswith('[gd_scene '):
        errors.append(f'{rel}:1 missing/invalid gd_scene header')
        continue
    ext_ids=set(); sub_ids=set(); declared_nodes=set(); root_seen=False
    for ln,line in enumerate(lines,1):
        s=line.strip()
        if not s or s.startswith(';'): continue
        if s.startswith('['):
            if not s.endswith(']'):
                errors.append(f'{rel}:{ln} malformed section header: {s}')
                continue
            m=EXT_DECL_RE.match(s)
            if m:
                rid=m.group(1)
                if rid in ext_ids: errors.append(f'{rel}:{ln} duplicate ext_resource id {rid}')
                ext_ids.add(rid)
                pm=re.search(r'\bpath="([^"]+)"',s)
                if pm and pm.group(1).startswith('res://'):
                    target=ROOT/pm.group(1)[6:]
                    if not target.exists(): errors.append(f'{rel}:{ln} missing ext_resource path {pm.group(1)}')
                continue
            m=SUB_DECL_RE.match(s)
            if m:
                rid=m.group(1)
                if rid in sub_ids: errors.append(f'{rel}:{ln} duplicate sub_resource id {rid}')
                sub_ids.add(rid)
                continue
            if s.startswith('[node '):
                attrs=dict(ATTR_RE.findall(s[len('[node '):-1]))
                name=attrs.get('name','').strip('"')
                parent=attrs.get('parent')
                if not name:
                    errors.append(f'{rel}:{ln} node without name')
                    continue
                if parent is None:
                    if root_seen: errors.append(f'{rel}:{ln} second root node {name}')
                    root_seen=True
                    full=name
                else:
                    par=parent.strip('"')
                    if par == '.': full=name if not root_seen else name  # parent root, path is child name
                    else:
                        # Node paths in tscn are relative to root; parent must have appeared already.
                        if par not in declared_nodes:
                            errors.append(f'{rel}:{ln} parent path not declared earlier: {par} for {name}')
                        full=f'{par}/{name}'
                    if full in declared_nodes: errors.append(f'{rel}:{ln} duplicate node path {full}')
                declared_nodes.add(full)
                continue
            # Any other section is valid textually; no extra validation here.
            continue
        if SCRIPT_CONSTANT_RE.search(s):
            errors.append(f'{rel}:{ln} GDScript-only constant in serialized scene: {s}')
        if '=' in s:
            rhs=s.split('=',1)[1].strip()
            if ' if ' in rhs or ' else ' in rhs or '&&' in rhs or '||' in rhs:
                errors.append(f'{rel}:{ln} code expression in serialized scene: {s}')
            for rid in EXT_USE_RE.findall(rhs):
                if rid not in ext_ids: errors.append(f'{rel}:{ln} references undeclared ExtResource {rid}')
            for rid in SUB_USE_RE.findall(rhs):
                if rid not in sub_ids: errors.append(f'{rel}:{ln} references undeclared SubResource {rid}')
    if not root_seen:
        errors.append(f'{rel}: no root [node] section')

print(f'SCENE SERIALIZATION AUDIT: {len(list(ROOT.rglob("*.tscn")))} .tscn files checked')
if warnings:
    for w in warnings: print('WARNING:',w)
if errors:
    for e in errors: print('ERROR:',e)
    print(f'FAIL: {len(errors)} scene serialization issue(s)')
    sys.exit(1)
print('PASS: scene text uses serializable values, resource ids resolve, ext_resource paths exist, and node parents are ordered')
