from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors=[]; warnings=[]; oks=[]
def ok(x): oks.append(x)
def fail(x): errors.append(x)
def warn(x): warnings.append(x)

manager=(ROOT/'scripts/barge_room_manager.gd').read_text()
if re.search(r'\bBreakableProp\b|\bPickupDrop\b', manager):
    fail('barge_room_manager.gd still has parser-coupled BreakableProp/PickupDrop type names')
else:
    ok('manager no longer depends on globally resolved BreakableProp/PickupDrop class names')

for token in ['BreakableScript.new()', 'PickupScript.new()', '_on_breakable_broken', '_on_pickup_collected']:
    if token not in manager: fail(f'missing runtime breakable/pickup contract: {token}')
if not any('runtime breakable' in x for x in errors): ok('breakable/pickup runtime contract remains connected')

policy=ROOT/'ART_PLACEHOLDER_POLICY.md'
handoff=ROOT/'ART_HANDOFF/SPRITE_PRODUCTION_BRIEF.md'
if policy.exists() and handoff.exists(): ok('no-CSS-art policy and production handoff are present')
else: fail('art policy/handoff missing')

# Production-facing procedural pieces still present are explicit handoff TODOs, not silently accepted.
map_text=(ROOT/'scripts/map_overlay.gd').read_text()
if 'draw_line(' in map_text:
    warn('map connector lines are still procedural legacy art; replace with map connector sprites before next visual build')
hook_text=(ROOT/'scripts/rooms/hook_anchor.gd').read_text()
if 'draw_circle(' in hook_text or 'draw_arc(' in hook_text:
    warn('Grave Lantern still has procedural selection-glow VFX; world artifact itself is sprite-based, but art handoff requests authored active/selected states')

# Stale .bak files must not reintroduce old procedural implementations.
baks=list((ROOT/'scripts').rglob('*.bak'))
if baks: fail(f'stale backup scripts remain: {len(baks)}')
else: ok('stale procedural-art backup scripts removed')

print('VANIA PASS 0.11.1 RUNTIME + ART POLICY AUDIT')
for x in oks: print('OK:', x)
for x in warnings: print('WARNING:', x)
if errors:
    for x in errors: print('ERROR:', x)
    sys.exit(1)
