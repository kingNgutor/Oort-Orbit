# S3 Ship — flying through a 3-sphere in Godot

A minimal Godot 4 project: a real `CharacterBody3D` spaceship, flown with
normal physics (velocity, `move_and_slide()`, a chase camera), through a
curved 3-sphere (S³) universe using a **floating-origin** technique.

## Running it

1. Open Godot 4.x (4.2+ recommended).
2. Import this folder as a project (point "Import" at `project.godot`).
3. Run the main scene (F5).

## Controls

- `W` / `S` — thrust forward / back
- `A` / `D` — strafe left / right
- `Space` / `Shift` — strafe up / down
- Mouse — steer (yaw/pitch the ship directly)
- `Esc` — release/recapture the mouse cursor

## How it works

There are two layers of state:

**1. The flat local patch (ordinary Godot physics).**
The `Ship` is a normal `CharacterBody3D`. It accelerates, strafes, and
turns exactly like it would in any flat-space game — `move_and_slide()`,
collisions, a `Camera3D` riding along as a child. Nothing about this layer
knows it's on a sphere. This is valid because any point on a manifold
looks flat close-up — a 3-sphere locally *is* ordinary ℝ³, to good
approximation, as long as you stay within a patch small compared to the
sphere's `radius`.

**2. The curved global state (`Q`, `F` in `Main.gd`).**
`Q` is a unit quaternion: the true position of the local patch's origin
on S³. `F` is the patch's orientation frame. Every marker in the world is
also just a fixed unit quaternion, and each frame `Main.gd` projects every
marker into the patch's ordinary `Vector3` coordinates via the
**logarithmic map** — same technique as the walking-camera version.

**The bridge: rebasing.**
Every physics step, after the ship moves, `Ship.gd` checks how far it has
drifted from the patch origin (`position.length()`). Once that exceeds
`rebase_threshold`, it hands the displacement to `Main.gd`'s
`fold_displacement()`, which folds it into `Q` via the **exponential
map** (the same update rule the walking-camera version used for plain
movement) and then recenters the ship back near zero. Because every
marker's projected position is recomputed from `Q`/`F` every frame, this
recentring is invisible — the world doesn't pop, it just continuously
re-centers itself under the ship. This is the same "floating origin"
trick large open-world/space games use to dodge float-precision issues at
huge distances, just folded through curved-space exp/log maps instead of
a plain translation.

Fly in a straight line (hold `W`, don't touch the mouse) for long enough
and you'll loop all the way around a great circle and arrive back at the
yellow HOME marker — the HUD tracks total distance traveled against the
loop-around distance (`2π·radius`) so you can watch it happen.

## Files

- `Main.gd` — world state (`Q`, `F`), marker spawning, the exponential map
  (`fold_displacement`) and logarithmic map (`local_position_of`), HUD.
- `Ship.gd` — ordinary `CharacterBody3D` flight controller, plus the
  rebase check that bridges into the curved global state.
- `Main.tscn` — scene: `Sun` light, empty `World` node (markers spawn into
  it), `Ship` (with hull mesh, collision shape, and a chase camera rig),
  HUD label.
- `project.godot` — input map (WASD / Space / Shift / Esc).

## Tuning notes

- `radius` (on the `Main` node) sets the size of the universe. Smaller
  values make the "fly in a circle and come home" effect fast and
  obvious — good for first confirming it works.
- `rebase_threshold` (on the `Ship` node) controls how often the flat
  patch re-centers. Smaller values track the true curved geodesic more
  precisely (the flat-patch approximation error scales roughly like
  `(threshold / radius)²`), at the cost of doing the fold more often —
  though the fold is cheap, so there's little reason not to keep this
  fairly small relative to `radius`.
- **Collisions**: the ship's `CollisionShape3D` only ever collides with
  geometry that actually exists in the local flat patch. The markers here
  are visual only (no colliders). If you want solid obstacles (asteroids,
  a station) scattered across the sphere, you'd stream their collision
  shapes in/out as the ship approaches/leaves them, the same way open-world
  games stream distant geography — same idea as marker projection, just
  also instancing/freeing physics bodies based on projected distance.
- **A subtlety for the curious**: `fold_displacement` updates `F` by the
  same rotation step as `Q`. For a bi-invariant metric on the unit
  quaternions this is a very good approximation of true parallel
  transport, but not exact in general — there's a known closed form
  involving the adjoint action for exact transport. The error from using
  the simpler update is second-order in `rebase_threshold`, so with a
  reasonably small threshold it's imperceptible in practice.
