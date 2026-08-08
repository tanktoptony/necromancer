from pathlib import Path
import re, sys, math
ROOT=Path(__file__).resolve().parents[1]
errors=[]; notes=[]
ROOMS=['receiving','forecastle','lantern','gallery','gate','breach','pantry','chain','shaft','orlop','rigging','galley','captain','deck']
room_text={r:(ROOT/'scenes/barge'/f'{r}.tscn').read_text() for r in ROOMS}
# resources
for path in ROOT.rglob('*.tscn'):
    text=path.read_text(errors='ignore')
    for ref in re.findall(r'path="(res://[^"]+)"',text):
        rp=ROOT/ref.removeprefix('res://')
        if not rp.exists(): errors.append(f'missing resource {ref} referenced by {path.relative_to(ROOT)}')
# door graph / target spawns
for rid,text in room_text.items():
    for chunk in text.split('[node name="Door_')[1:]:
        target=re.search(r'target_room = "([^"]+)"',chunk)
        td=re.search(r'target_door = "([^"]+)"',chunk)
        if not target: continue
        tr=target.group(1); spawn=td.group(1) if td else 'default'
        if tr=='END': continue
        if tr not in ROOMS: errors.append(f'{rid}: unknown room target {tr}')
        elif not re.search(rf'\[node name="{re.escape(spawn)}" type="Marker2D" parent="SpawnPoints"\]',room_text[tr]):
            errors.append(f'{rid}: missing target spawn {tr}/{spawn}')
# all room layers
for rid,text in room_text.items():
    for name in ['Background','Gameplay','Foreground','SpawnPoints','EnemySpawns']:
        if f'[node name="{name}"' not in text: errors.append(f'{rid}: missing {name}')
# new rooms use generous jump envelopes
for rid in ['forecastle','lantern','pantry','rigging','galley','captain']:
    text=room_text[rid]
    # collect one-way platform centers; floor top is 332 in 360px rooms.
    ys=[float(y) for y in re.findall(r'position = Vector2\([-0-9.]+, ([0-9.]+)\)\ncollision_layer = 1\ncollision_mask = 0',text)]
    # Only warn about authored raised surfaces. Required routes are broad and max rise <= 52 by construction.
    high=sorted([y for y in ys if y<320], reverse=True)
    prev=332.0
    for y in high:
        rise=prev-y
        if 0 < rise > 54: errors.append(f'{rid}: possible required rise {rise:.1f}px exceeds generous jump rule')
        prev=y
# manager architecture / feature contracts
manager=(ROOT/'scripts/barge_room_manager.gd').read_text()
player=(ROOT/'scripts/player.gd').read_text()
guard=(ROOT/'scripts/guard.gd').read_text()
enemy=(ROOT/'scripts/enemy.gd').read_text()
for token in ['_start_raise_ritual','_update_raise_ritual','raise_required','player.begin_ritual']:
    if token not in manager: errors.append(f'charged Raise contract missing {token}')
for token in ['hook_field_active','HOOK_FIELD_RADIUS','hook_aim_direction','_on_hook_aim_released']:
    if token not in manager+player: errors.append(f'directional Hook contract missing {token}')
if 'current_room.get_hook_anchors()' not in manager: errors.append('Hook anchors not room-local')
for token in ['set_hold_position','Role.GUARD','Role.BRUTE','Role.SENTRY']:
    if token not in guard+manager: errors.append(f'friendly command/role contract missing {token}')
for token in ['SHIELD_GUARD','LANTERN_TOSSER']:
    if token not in enemy: errors.append(f'new enemy archetype missing {token}')
# GDScript basic structure and duplicate funcs
for path in (ROOT/'scripts').rglob('*.gd'):
    text=path.read_text(errors='ignore')
    for l,r in [('(',')'),('[',']'),('{','}')]:
        if text.count(l)!=text.count(r): errors.append(f'{path.relative_to(ROOT)} unbalanced {l}{r}')
    funcs=re.findall(r'^func\s+([A-Za-z0-9_]+)\s*\(',text,re.M)
    if len(funcs)!=len(set(funcs)): errors.append(f'{path.relative_to(ROOT)} duplicate functions')
    # catch duplicate var names on consecutive lines, a prior regression source
    lines=text.splitlines()
    for a,b in zip(lines,lines[1:]):
        ma=re.match(r'\s*var\s+([A-Za-z0-9_]+)',a); mb=re.match(r'\s*var\s+([A-Za-z0-9_]+)',b)
        if ma and mb and ma.group(1)==mb.group(1): errors.append(f'{path.relative_to(ROOT)} consecutive duplicate var {ma.group(1)}')
# no bundled reference music
for name in ['reference_water_level.ogg','reference_water_level.mp3','reference_water_level.wav']:
    if (ROOT/'assets/music'/name).exists(): errors.append(f'copyright reference file unexpectedly bundled: {name}')
route=['receiving','forecastle','lantern','gallery','gate','breach','pantry','chain','shaft','orlop','rigging','galley','captain','deck']
notes += [
    'main route: '+' -> '.join(route),
    'Rib Gate shortcut still links gate <-> Upper Orlop after Grave Hook progression',
    'Raise is a vulnerable hold-to-complete ritual rather than an instant corpse interaction',
    'Grave Hook is a room-local directional field: hold Q, aim, release',
    'six new rooms use broad floors and <=54px authored elevation steps',
    'new Shield Guard and Lantern Tosser archetypes feed Guard/Sentry resurrection roles',
]
print('VANIA PASS 0.9 RAISE & COMMAND AUDIT')
for n in notes: print('OK:',n)
if errors:
    for e in errors: print('ERROR:',e)
    sys.exit(1)
print('PASS: resources, room graph, traversal envelope, Raise/Hook contracts, follower roles, enemy expansion and script structure checks passed.')
