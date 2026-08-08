from pathlib import Path
import re, sys
root=Path(__file__).resolve().parents[1]
errors=[]
required=[
 'assets/vania10/grave_lantern.png','assets/vania10/platform_lip.png','assets/vania10/bulkhead_door.png',
 'assets/vania10/map_parchment.png','assets/vania10/map_room_explored.png','assets/vania10/map_room_current.png',
 'assets/vania10/grave_hook_relic.png'
]
for rel in required:
    if not (root/rel).exists(): errors.append(f'missing {rel}')

hook=(root/'scripts/rooms/hook_anchor.gd').read_text()
if 'grave_lantern.png' not in hook: errors.append('Hook anchor is not using purple lantern art')
room=(root/'scripts/rooms/room_scene.gd').read_text()
if 'PLATFORM_LIP_TEXTURE' not in room or '_decorate_one_way_platforms' not in room:
    errors.append('one-way platform visual decorator missing')
door=(root/'scripts/rooms/door_portal.gd').read_text()
if 'bulkhead_door.png' not in door: errors.append('illustrated bulkhead door art missing')
mp=(root/'scripts/map_overlay.gd').read_text()
for token in ['map_parchment.png','map_room_explored.png','map_room_current.png','map_player.png','map_hook.png']:
    if token not in mp: errors.append(f'map art missing ref {token}')

enemy=(root/'scripts/enemy.gd').read_text()
for token in ['BILGE_CRAWLER','HANGED_SAILOR']:
    if token not in enemy: errors.append(f'new enemy archetype missing: {token}')
for scene,arch in [('breach.tscn','archetype = 8'),('rigging.tscn','archetype = 9')]:
    text=(root/'scenes/barge'/scene).read_text()
    if arch not in text: errors.append(f'{scene} does not feature expected new archetype')
chain=(root/'scenes/barge/chain.tscn').read_text()
if 'grave_hook_relic.png' not in chain or 'RelicArt' not in chain:
    errors.append('Chain Crypt Grave Hook pickup is still procedural')

# resource refs (allow optional reference music)
pattern=re.compile(r'res://[^"\')\s]+')
for p in list((root/'scripts').rglob('*.gd'))+list((root/'scenes').rglob('*.tscn')):
    text=p.read_text(errors='ignore')
    for ref in pattern.findall(text):
        if ref.startswith('res://assets/music/reference_water_level.'):
            continue
        local=root/ref.removeprefix('res://')
        if not local.exists():
            errors.append(f'{p.relative_to(root)} missing resource {ref}')

# simple delimiter checks ignoring comments/strings approximately
for p in (root/'scripts').rglob('*.gd'):
    text=p.read_text()
    scrub=[]
    for line in text.splitlines():
        line=re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
        line=re.sub(r"'(?:\\.|[^'\\])*'", "''", line)
        line=line.split('#',1)[0]
        scrub.append(line)
    joined='\n'.join(scrub)
    for a,b in [('(',')'),('[',']'),('{','}')]:
        if joined.count(a)!=joined.count(b): errors.append(f'{p.relative_to(root)} unbalanced {a}{b}')

if errors:
    print('VANIA PASS 0.10 VISUAL IDENTITY AUDIT')
    for e in errors: print('ERROR:',e)
    sys.exit(1)
print('VANIA PASS 0.10 VISUAL IDENTITY AUDIT')
print('OK: purple Grave Lantern anchors replace abstract ring artifacts')
print('OK: one-way platforms receive tiled wooden/iron visual lips')
print('OK: room portals use illustrated bulkhead sprites')
print('OK: map uses parchment, illustrated room tiles, and artifact markers')
print('OK: Grave Hook pickup has dedicated relic art')
print('OK: Bilge Crawler and Hanged Sailor are implemented and placed in encounters')
print('PASS: resources, archetype placement, map/hook/platform art, scene references, and script delimiters')
