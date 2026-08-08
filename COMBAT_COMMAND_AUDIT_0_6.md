# Vania Pass 0.6 — Combat & Command Audit

## Scope

This pass was built directly on the 0.5.2 playability package. It does not expand the world footprint. The goal is to make the existing slice feel more responsive, tactically legible, and specific to the necromancer premise.

## Player combat

- Added a three-step attack chain.
- First and second attacks deal one damage; the third attack has greater reach, a forward lunge, and two damage.
- Separate startup, active-hit, and continuation timing prevents one held input from becoming a completely automatic combo.
- Added slash arcs, impact bursts, hit-stop, stronger third-hit camera shake, and separate light/heavy impact sounds.
- Taking damage cancels the current combo.

## Enemy intelligence

- Enemies periodically reassess whether the player or a nearby raised ally is the immediate threat.
- Only two non-ranged enemies in a room may be in an active windup/attack state at once. Others position or wait instead of creating one synchronized body wall.
- Existing Walker, Charger, Sentry, and Hopper roles remain.
- Added Hook Brute: slow, durable, long telegraph, large melee reach, and heavy damage.
- Added Bell Wretch: support enemy that keeps distance and periodically accelerates nearby enemies' movement and attack readiness.
- Light enemies can be pulled by the Grave Hook. Chargers, Brutes, and elites resist it.
- Hostile projectiles can hit raised allies, and enemies can kill followers.

## Army commands

Press C to cycle:

1. **Follow** — close formation and normal engagement range.
2. **Hold** — each follower defends the position where the order was issued.
3. **Assault** — followers search farther ahead and pursue enemies more aggressively.

The selected command is shown in the top HUD and persists through checkpoint reloads.

## Raised corpse roles

- Walker/Hopper corpses become balanced melee Guards.
- Charger/Brute corpses become durable Brutes with heavy attacks.
- Sentry/Bell Wretch corpses become ranged Sentries.
- Roles persist through checkpoint reloads.

## Follower movement

- Increased acceleration and braking.
- Reduced constant low-speed correction near formation points.
- Added role-specific speeds and stopping distances.
- Run animation speed tracks actual movement speed.
- Hold mode prevents catch-up teleporting unless recovery logic is required by a fall.

## Grave Hook

- Existing traversal-ring and bone-gate functions remain.
- With no ring selected, Q can pull a light enemy in front of the player from up to roughly 172 pixels away.
- Added chain sound and arrival feedback.

## Audio

The package includes original synthesized PCM effects for:

- light swing
- light impact
- heavy impact
- resurrection
- Grave Hook
- relic acquisition
- army command
- enemy alert / Bell Wretch pulse
- player/follower hurt

## Automated checks completed

- Resource references: pass
- Script delimiter and duplicate-function check: pass
- Critical pit jumps: pass
- Critical Chain Locker Hook route: pass
- Combo signal/callback arity: pass
- Enemy archetype and coordination system presence: pass
- Army command and role persistence links: pass
- Friendly/hostile projectile separation: pass
- WAV file header and PCM format validation: pass

## Runtime validation still required

The Godot executable is not available in the artifact environment, so engine parsing, physics feel, audio balance, and actual encounter tuning still require the first launch in Godot. F3 collision visualization remains enabled as a development tool.
