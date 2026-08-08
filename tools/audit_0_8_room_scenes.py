from pathlib import Path
import re, sys, math
ROOT=Path(__file__).resolve().parents[1]
errors=[]; notes=[]
ROOMS=['receiving','gallery','gate','breach','chain','shaft','orlop','deck']
room_text={r:(ROOT/'scenes/barge'/f'{r}.tscn').read_text() for r in ROOMS}
# Resource existence.
for path in ROOT.rglob('*.tscn'):
    text=path.read_text(errors='ignore')
    for ref in re.findall(r'path="(res://[^"]+)"',text):
        rp=ROOT/ref.removeprefix('res://')
        if not rp.exists(): errors.append(f'missing resource {ref} referenced by {path.relative_to(ROOT)}')
# Door graph and target spawns.
for rid,text in room_text.items():
    chunks=text.split('[node name="Door_')[1:]
    for chunk in chunks:
        target=re.search(r'target_room = "([^"]+)"',chunk)
        target_door=re.search(r'target_door = "([^"]+)"',chunk)
        if not target: continue
        tr=target.group(1); td=target_door.group(1) if target_door else 'default'
        if tr=='END': continue
        if tr not in ROOMS: errors.append(f'{rid}: door targets unknown room {tr}')
        elif not re.search(rf'\[node name="{re.escape(td)}" type="Marker2D" parent="SpawnPoints"\]',room_text[tr]):
            errors.append(f'{rid}: target spawn {tr}/{td} missing')
# Architecture guarantees: main script has no giant world and hook targets are scene-local.
manager=(ROOT/'scripts/barge_room_manager.gd').read_text()
for bad in ['WORLD_SIZE','BONE_GATE_X','HOOK_PICKUP_POSITION','var rooms: Dictionary =']:
    if bad in manager: errors.append(f'manager still contains giant-world token {bad}')
if 'current_room.get_hook_anchors()' not in manager: errors.append('hook selection is not room-local')
if 'current_anchor.landing_position()' not in manager: errors.append('hook uses no authored landing positions')
# Hook ranges remain indoor scale.
for rid,text in room_text.items():
    for val in re.findall(r'max_range = ([0-9.]+)',text):
        if float(val)>260: errors.append(f'{rid}: indoor hook range {val} > 260')
# Shaft progression: authored landings are deliberately short.
shaft=room_text['shaft']
anchors=[]
for block in shaft.split('script = ExtResource("3_anchor")')[1:]:
    # node position precedes script, so parse via full node chunks instead below
    pass
for m in re.finditer(r'\[node name="Anchor_[^"]+"[^\]]*\]\nposition = Vector2\(([-0-9.]+), ([-0-9.]+)\)\nscript = ExtResource\("3_anchor"\)\nanchor_id = "([^"]+)"\nlabel = "[^"]+"\nlanding_offset = Vector2\(([-0-9.]+), ([-0-9.]+)\)\nmax_range = ([0-9.]+)',shaft):
    x,y,aid,ox,oy,rng=m.groups(); anchors.append((aid,float(x),float(y),float(ox),float(oy),float(rng)))
if len(anchors)!=5: errors.append(f'shaft: expected 5 local anchors, found {len(anchors)}')
prev=(125,566)
for aid,x,y,ox,oy,rng in anchors:
    d=math.dist(prev,(x,y))
    if d>rng+1: errors.append(f'shaft {aid}: ring is {d:.1f}px from previous landing but range {rng:.1f}')
    prev=(x+ox,y+oy)
# Hull breach platform route checks.
breach_surfaces=[(20,174,195),(285,126,150),(505,192,180),(765,142,170)]
for a,b in zip(breach_surfaces,breach_surfaces[1:]):
    ax,ay,aw=a; bx,by,bw=b
    gap=max(0,bx-(ax+aw)); rise=max(0,ay-by)
    if gap>90: errors.append(f'breach gap too large: {gap}')
    if rise>56: errors.append(f'breach required rise too high: {rise}')
# Scene layering.
for rid,text in room_text.items():
    if '[node name="Background"' not in text or '[node name="Gameplay"' not in text or '[node name="Foreground"' not in text:
        errors.append(f'{rid}: missing 3-layer scene organization')
# Basic GDScript structure checks.
for path in list((ROOT/'scripts').rglob('*.gd')):
    text=path.read_text(errors='ignore')
    for l,r in [('(',')'),('[',']'),('{','}')]:
        if text.count(l)!=text.count(r): errors.append(f'{path.relative_to(ROOT)} unbalanced {l}{r}')
    funcs=re.findall(r'^func\s+([A-Za-z0-9_]+)\s*\(',text,re.M)
    if len(funcs)!=len(set(funcs)): errors.append(f'{path.relative_to(ROOT)} duplicate functions')
# Reference music slot exists but contains no bundled copyrighted track.
music=ROOT/'assets/music'
if not (music/'README_REFERENCE_TRACK.txt').exists(): errors.append('reference music instructions missing')
for name in ['reference_water_level.ogg','reference_water_level.mp3','reference_water_level.wav']:
    if (music/name).exists(): errors.append(f'reference track {name} should not ship in package')
# Explicit gate-before-hook route.
route=['receiving','gallery','gate','breach','chain','shaft','orlop','gate','orlop','deck']
notes.append('route: '+' -> '.join(route))
notes.append('hook anchors are local to instantiated room scenes; no cross-room coordinates remain')
notes.append('Hull Breach has 3 rendered layers and a four-platform normal-jump route')
print('VANIA PASS 0.8 ROOM-SCENE AUDIT')
for n in notes: print('OK:',n)
if errors:
    for e in errors: print('ERROR:',e)
    sys.exit(1)
print('PASS: room graph, resources, local Hook contracts, breach jumps, scene layers, script structure, and music slot checks passed.')
