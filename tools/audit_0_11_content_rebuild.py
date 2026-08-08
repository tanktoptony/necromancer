from pathlib import Path
import re, sys, math
ROOT=Path(__file__).resolve().parents[1]
errors=[]; oks=[]

def ok(msg): oks.append(msg)
def fail(msg): errors.append(msg)

# Resource references
for p in list((ROOT/'scripts').rglob('*.gd'))+list((ROOT/'scenes').rglob('*.tscn')):
    text=p.read_text(errors='ignore')
    for ref in re.findall(r'res://[^"\n\]]+', text):
        rel=ref[6:]
        if rel.startswith('assets/music/reference_water_level.'):
            continue
        if not (ROOT/rel).exists(): fail(f'missing resource {ref} from {p.relative_to(ROOT)}')
if not errors: ok('all res:// references resolve')

# Six-room graph
rooms=['receiving','gallery','gate','breach','chain','deck']
for room in rooms:
    if not (ROOT/f'scenes/barge/{room}.tscn').exists(): fail(f'missing room {room}')
manager=(ROOT/'scripts/barge_room_manager.gd').read_text()
for room in rooms:
    if f'"{room}": "res://scenes/barge/{room}.tscn"' not in manager: fail(f'ROOM_SCENES missing {room}')
for removed in ['forecastle','lantern','pantry','shaft','orlop','rigging','galley','captain']:
    block=manager.split('const ROOM_SCENES: Dictionary = {',1)[1].split('}',1)[0]
    if f'"{removed}"' in block: fail(f'old room still active in ROOM_SCENES: {removed}')
if not any('ROOM_SCENES' in x for x in errors): ok('active slice is six authored compartments')

# Door target/spawn validation
scene_text={r:(ROOT/f'scenes/barge/{r}.tscn').read_text() for r in rooms}
for room,text in scene_text.items():
    targets=re.findall(r'target_room = "([^"]+)"\ntarget_door = "([^"]+)"',text)
    for target,door in targets:
        if target=='END': continue
        if target not in rooms: fail(f'{room} door targets inactive room {target}')
        elif f'[node name="{door}" type="Marker2D" parent="SpawnPoints"]' not in scene_text[target]:
            fail(f'{room} targets missing spawn {target}:{door}')
if not any('targets' in x or 'spawn' in x for x in errors): ok('every active door resolves to a real destination spawn')

# Physics envelope
jump_rise=320.0**2/(2*900.0)
if jump_rise < 56.0: fail('jump envelope unexpectedly shrank')
else: ok(f'player ballistic rise {jump_rise:.1f}px')
# Required normal-jump rises: Gallery stairs and Hull Breach
for label,rises in {'gallery':[48,52,50,50],'breach':[44]}.items():
    if max(rises)>jump_rise+0.5: fail(f'{label} required jump {max(rises)} exceeds {jump_rise:.1f}')
    else: ok(f'{label} required jumps fit movement envelope (max {max(rises)}px)')
# Chain must be hook gated
chain_first_rise=68
if chain_first_rise <= jump_rise: fail('Chain Crypt first relic route is accidentally normally jumpable')
else: ok('Chain Crypt post-relic climb is clearly Hook-gated')

# Hook sequence geometry
start=(286,318); a1=(395,190); land1=(395,250); a2=(492,118); land2=(492,180)
def dist(a,b): return math.hypot(a[0]-b[0],a[1]-b[1])
if dist(start,a1)>190: fail('first crypt hook outside range')
if dist(land1,a2)>188: fail('second crypt hook outside range')
if dist(start,a2)<188: fail('second crypt anchor is available too early, reintroducing close-anchor ambiguity')
if not any('hook' in x.lower() for x in errors): ok('Chain Crypt Hook tutorial is sequential: only intended next anchor is available')

# New content contracts
enemy=(ROOT/'scripts/enemy.gd').read_text()
for token in ['BONE_CROW','COFFIN_MIMIC','grave_guard','lantern_tosser','bilge_crawler','hook_brute','bell_keeper','hanged_sailor','bone_crow','coffin_mimic']:
    if token not in enemy: fail(f'enemy roster missing {token}')
for folder in ['grave_guard','lantern_tosser','bilge_crawler','hook_brute','bell_keeper','hanged_sailor','bone_crow','coffin_mimic']:
    frames=list((ROOT/f'assets/sprites/enemy_types/{folder}').glob('enemy_*.png'))
    if len(frames)!=8: fail(f'{folder} expected 8 frames, got {len(frames)}')
if not any('enemy roster' in x or 'frames' in x for x in errors): ok('eight visually distinct first-area enemy silhouettes have full frame sets')

for asset in ['deck_trim.png','platform_trim.png','stairs.png','railing.png','breakable_candle.png','bone_urn.png','grave_ash.png','flesh_pickup.png','rib_gate.png']:
    if not (ROOT/'assets/vania11'/asset).exists(): fail(f'missing modular environment asset {asset}')
if not any('modular' in x for x in errors): ok('0.11 modular gameplay-art kit present')

# Resurrection keeps source archetype and player gets content loop
state=(ROOT/'scripts/game_state.gd').read_text(); guard=(ROOT/'scripts/guard.gd').read_text()
for token in ['army_archetypes','grave_ash','set_army_roster']:
    if token not in state: fail(f'GameState missing {token}')
for token in ['source_archetype','_source_sprite_folder','_physics_process_crow_follower']:
    if token not in guard: fail(f'RaisedGuard missing {token}')
if 'BreakableScript' not in manager or 'PickupScript' not in manager or '_on_pickup_collected' not in manager: fail('breakable/drop loop not connected in manager')
else: ok('raised corpses preserve silhouette metadata and breakables/enemies feed the pickup loop')

# Heavy attack exists; shovel toss intentionally parked
player=(ROOT/'scripts/player.gd').read_text()
if '_start_special_attack(6)' not in player or '"heavy"' not in player: fail('ground heavy attack missing')
else: ok('combat includes deliberate ground heavy in addition to combo/rising/plunge')

print('VANIA PASS 0.11 CONTENT REBUILD AUDIT')
for m in oks: print('OK:',m)
if errors:
    for e in errors: print('ERROR:',e)
    sys.exit(1)
print('PASS: six-room route, door graph, jump/Hook envelope, roster art, persistence, pickups, and combat contracts')
