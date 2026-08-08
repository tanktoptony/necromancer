# First Dawn 0.11 Content Rebuild — Design/Technical Audit

## Why this pass exists
0.10 had more rooms but not enough new decisions. The active slice has been reduced to six rooms so each room can introduce a distinct combat, traversal, visual or recruitment idea.

## Physics contract
Player jump velocity remains -320 px/s under 900 px/s² gravity, for a theoretical vertical rise of ~56.9 px. Required normal route rises are <=52 px. Chain Crypt's first post-relic ledge rises 68 px and is intentionally Grave Hook-gated. Hull Breach uses broad surfaces; water is recovery, not an endless fall.

## Content contract
A room must contribute at least one of: new enemy silhouette/behavior, environmental hazard, traversal decision, recruitable role, secret/reward, or set-piece composition. The six active rooms satisfy this via the roster and route described in README_0_11.txt.

## Recruitment contract
Raised enemies carry source_archetype through room transitions/checkpoints. The visual sheet is selected from source archetype while tactical role remains Guard/Brute/Sentry. This allows future sprite replacements and deeper role specialization without changing save/state architecture.

## Known limitations for playtest
- Dedicated enemy sheets are deliberately first-pass pixel assets, not final production animation.
- Hanged Sailor and Crawler use existing state animation counts with new silhouettes rather than bespoke twelve-plus-frame animation sets.
- Bone Crow follower flight is functional but should be assessed for formation obstruction and room-door reform behavior.
- The map is intentionally simplified around the six-room slice; it should be judged as navigation, not final UI art.
- Runtime Godot validation is still required locally.

## Test questions
1. Does each of the six rooms feel meaningfully different within one playthrough?
2. Does the enemy roster finally create "I want that corpse" moments?
3. Are all normal surfaces obviously jumpable/readable?
4. Does the Chain Crypt teach the Hook without anchor-selection confusion?
5. Does returning behind the Rib Gate make the route feel like a small Castlevania circuit?
6. Does the mixed Deck encounter remain readable with three followers?
