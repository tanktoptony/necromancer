# Sprite & Environment Production Brief — 0.11 Handoff

## Style target

Buildable pixel art, not polished key art.

Target qualities:
- chunky readable silhouettes at gameplay scale;
- expressive animation and slightly exaggerated proportions;
- graveyard-storybook / Halloween gothic shapes;
- crooked timber, wrought iron, coffins, bells, lanterns, bone, ropes, chains, cemetery ornament;
- selective violet necromancy against warm orange practical lights;
- enough detail to feel authored, but not so much micro-detail that platforms or attacks become hard to read;
- transparent backgrounds for all sprites/props;
- hard pixel edges; no smooth vector-like contours or anti-aliased “UI illustration” look.

Avoid:
- Blasphemous-level religious brutality as the dominant identity;
- photoreal rendering;
- ornate prestige-game UI frames everywhere;
- generic skeleton recolors;
- procedural geometric symbols posing as world artifacts.

## Character frame contract

Current runtime compatibility uses individual PNG frames on a **96 × 80 px transparent canvas**.

The default standing character baseline is approximately y=74 and horizontal center x=48. Keep feet/collision visually stable across frames unless the animation intentionally leaves the ground.

Current 8-frame contract:

| File | Current semantic use | Art direction |
|---|---|---|
| enemy_0.png | dead/corpse | unmistakably the same creature, readable as raisable corpse |
| enemy_1.png | reserved | use as hurt/rise anticipation; retained for future code expansion |
| enemy_2.png | idle A | clear silhouette |
| enemy_3.png | idle B | characterful secondary idle |
| enemy_4.png | walk A | strong leg/coat/prop separation |
| enemy_5.png | walk B | opposite stride |
| enemy_6.png | attack windup | telegraph behavior clearly |
| enemy_7.png | attack release | committed attack pose |

Do not combine the frames into a sheet unless you ALSO return the eight individually named PNGs exactly as above.

### Raised versions
The current code reuses the enemy's source frames and applies a necromantic tint. Therefore the base silhouette must remain attractive/readable when tinted mint-green. Do not bake green into the hostile source sprites.

Future expansion may add bespoke raised animations, but the 8-frame contract above is the immediate production target.

## Enemy roster

### 1. Lantern Tosser — PRIORITY 1
Role: ranged pressure / desirable ranged follower.

Silhouette:
- crooked plague-barge deckhand or undertaker;
- one prominent orange lantern that is unmistakable at gameplay scale;
- asymmetrical coat, rope belt, exaggerated throwing arm;
- spooky rather than gruesome.

Animation goals:
- idle lantern sway;
- cautious walking posture;
- frame 6 clearly lifts/cocks lantern before throw;
- frame 7 follows through dramatically;
- corpse should retain lantern or broken lantern nearby so the player recognizes the recruit.

Raised fantasy: becomes ranged support. Must still visually read as Lantern Tosser under mint necromancy tint.

### 2. Grave Guard
Role: defensive melee / future projectile interception.

Silhouette:
- broad shield + shovel/sabre/short polearm;
- cemetery gate / burial-company uniform rather than generic knight;
- shield is the defining read.

Animation goal: attack windup visibly exposes body after defensive posture.

### 3. Bilge Crawler
Role: fast low-profile harassment / future crawl-space utility.

Silhouette:
- humanoid corpse compressed into crablike crawl;
- oversized hands, bent knees/elbows;
- substantially lower than standard enemies.

Needs to remain readable on dark timber floors.

### 4. Hook Brute
Role: slow armored space-control enemy / heavy raised follower.

Silhouette:
- dramatically larger shoulders and torso;
- ship hook / anchor-hook / butcher-hook weapon;
- rope, cargo harness, coffin-chain details;
- should look like it occupies space before it moves.

Attack must have a very obvious windup and heavy release.

### 5. Bell Keeper
Role: support enemy / buffs encounter, then buffs undead when raised.

Silhouette:
- tall bent figure carrying hand bell or wearable ship bell;
- bell must be readable from silhouette alone;
- ritual/cemetery sexton vibe.

Frame 6 = lift/prepare bell. Frame 7 = violent ring pose.

### 6. Hanged Sailor
Role: vertical threat / rigging enemy.

Silhouette:
- elongated dangling torso/legs, rope/noose/rigging motif;
- coat tails or limbs that exaggerate vertical motion;
- unsettling but still cartoony enough for the game's tone.

### 7. Bone Crow
Role: aerial nuisance / future aerial follower utility.

Use the same 96×80 canvas but much smaller occupied alpha area.
- skeletal/corpse seabird, not generic bat;
- exaggerated beak and ragged wing silhouette;
- clearly nautical/cemetery hybrid.

### 8. Coffin Mimic
Role: environmental ambusher.

Silhouette:
- starts as a readable coffin/crate-like object;
- attack frame reveals absurd teeth/arms/bone hardware;
- playful macabre surprise, not body-horror realism.

## Player art — next pass after enemy roster

Keep the current hooded necromancer's overall silhouette. Improve animation rather than redesigning the identity.

Future needed player actions:
- charged Raise ritual;
- heavy shovel attack;
- anti-air “shovel pop”: shovel flicks a rock, bottle, bone or breakable fragment upward;
- Grave Field aiming/channel pose;
- short backstep/dodge if retained.

**Parked mechanic:** Up/anti-air attack should eventually use the shovel to toss a physical object upward rather than remaining a generic rising slash.

## World-art kit priorities

### Purple Grave Lantern
Replace all geometric Hook symbols with an actual physical artifact.
- 40×56 to 48×64 px transparent PNG;
- wrought iron / bone cage;
- unmistakable purple internal flame;
- strong top chain/attachment point;
- must look like something installed in the ship, not a UI icon.

Optional variants:
- dormant/unlit;
- active/purple;
- selected/bright active.
Prefer separate sprite states over circles/arcs drawn around it.

### Orange lantern family
Create matching mundane lantern(s), same construction language but orange flame. Purple Hook lantern should visually feel like a corrupted/sorcerous sibling.

### Platforms
Need modular readable gameplay surfaces rather than invisible collision on painted backgrounds.

Suggested modules:
- 64×24 deck/platform segment;
- 32×24 end-cap left/right;
- 64×32 heavy cargo platform;
- 64×64 stair module;
- 32×48 railing/edge module;
- broken hull ledge module;
- waterlogged/bilge variants.

Top collision edge must be visually obvious. Favor a bright-ish timber/iron lip against darker wall art.

### Doors / hatches
Need authored ship-compartment transitions.
- horizontal/side bulkhead door: roughly 64×88 or 80×96;
- hatch/drop door: roughly 64×40;
- states: closed, opening, open, closing if feasible;
- real hinges/iron/wood mass; readable transition point.

### Breakables & drops
- orange breakable lantern/candle;
- bone urn;
- grave-ash pickup;
- flesh/health pickup;
- coffin bundle / suspicious prop for mimic camouflage.

### Rib Gate
Large bone-and-iron gate. Must explain visually that it is a specific obstruction, then feel satisfying when Grave Hook eventually tears it open.

## Map art

The map should feel like a Castlevania map drawn into a physical ship's log/parchment, not CSS boxes.

Needed assets:
- parchment/map background 600×330;
- room tile family (explored, current, secret/unexplored hint), approximately 18×18 or 24×18;
- horizontal/vertical/corner connector pieces;
- door marker;
- current-player marker;
- Grave Hook/relic marker;
- gate marker;
- secret/item marker.

Make map geometry chunky and pixel-authored. It is okay for rooms to remain grid-based; the problem is the *presentation*, not the Castlevania grid logic.

## Output requirements

- PNG only for runtime art, transparent where applicable.
- No SVG for gameplay art.
- No text baked into sprites unless specifically requested.
- Do not change filenames arbitrarily.
- Preserve pixel dimensions specified in `ASSET_MANIFEST.csv` where marked REQUIRED.
- If producing larger source art, also export the runtime-sized nearest-neighbor pixel version.
