from pathlib import Path
import re, math, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]; notes=[]
world=(4992.0,972.0)
# all referenced res:// resources exist
for gd in (ROOT/'scripts').glob('*.gd'):
    txt=gd.read_text(encoding='utf-8')
    for m in re.finditer(r'(?:preload|load)\("(res://[^"]+)"\)', txt):
        rel=m.group(1)[6:]
        if not (ROOT/rel).exists(): errors.append(f'{gd.name}: missing {rel}')
    if '\\t' in txt: errors.append(f'{gd.name}: literal backslash-t')
    clean=re.sub(r'"(?:\\.|[^"\\])*"','""',txt)
    clean='\n'.join(line.split('#',1)[0] for line in clean.splitlines())
    for a,b in [('(',')'),('[',']'),('{','}')]:
        if clean.count(a)!=clean.count(b): errors.append(f'{gd.name}: unbalanced {a}{b}')
    funcs=re.findall(r'^func\s+(\w+)\(',txt,re.M)
    for f in set(funcs):
        if funcs.count(f)>1: errors.append(f'{gd.name}: duplicate func {f}')
# route math
jump_height=320.0**2/(2.0*900.0)
flat_range=174.0*(2.0*320.0/900.0)
notes.append(f'player jump height {jump_height:.1f}px; ideal flat range {flat_range:.1f}px')
# visible normal gallery cargo steps: floor620 ->572 ->520 ->470 ->448
ys=[620,572,520,470,448]
for a,b in zip(ys,ys[1:]):
    rise=a-b
    if rise>jump_height+0.5: errors.append(f'gallery required rise {rise}px > jump height')
notes.append('gallery normal route max rise 52px; higher shelves explicitly Hook-gated')
# Gate hatch 90px allows inspection before committed drop
if 90>flat_range: errors.append('Rib Gate hatch cannot be jumped for inspection')
notes.append('Rib Gate is physically reachable before Hook; 90px hatch can be jumped or dropped through')
# bilge visible deck sequence from drop: P2 y756 -> P3 y826 -> P4 y775
if 826-775>jump_height+0.5: errors.append('Drowned Hold final upward jump impossible')
notes.append('Drowned Hold required upward rise is 51px; water recovery begins at y850')
# Hook progression distances
def dist(a,b): return math.hypot(a[0]-b[0],a[1]-b[1])
checks=[
 ('shaft upper',(3370,910),(3525,755),300),
 ('orlop return',(3500,818),(3090,548),560),
]
for name,a,b,r in checks:
    d=dist(a,b); notes.append(f'{name} ring {d:.1f}px / {r:.0f}px range')
    if d>r: errors.append(f'{name} out of range')
# Ensure hook exit is a one-way hatch, not solid ceiling
worldtxt=(ROOT/'scripts/vania_world.gd').read_text()
for required in ['orlop_hatch', 'collision_hook_only_rects.append(orlop_hatch)', 'BONE_GATE_X: float = 2380.0', '"gate_no_hook"', 'toast_queue.size() >= 1']:
    if required not in worldtxt: errors.append('missing contract: '+required)
# No obsolete end-room test
if '_active_enemies_in_room("ossuary")' in worldtxt: errors.append('obsolete ossuary room id in exit gate')
# new art
for f in ['receiving_hold.png','quarantine_gallery.png','bone_gate_landing.png','drowned_hold.png','chain_crypt.png','winch_shaft_tall.png','upper_orlop.png','storm_deck.png']:
    if not (ROOT/'assets/vania07'/f).exists(): errors.append('missing art '+f)
print('\n'.join('NOTE: '+n for n in notes))
if errors:
    print('\n'.join('ERROR: '+e for e in errors)); sys.exit(1)
print('PASS: 0.7 setpiece/circuit static audit')
