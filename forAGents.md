# Notes For AI Agents

This project is a The Binding of Isaac: Repentance mod that exposes a global
`StatsAPI` table for other mods. Be conservative: keep public API compatibility,
prefer existing patterns, and avoid broad rewrites unless the user explicitly
asks for them.

## Project Shape

- Entry point: `main.lua`
- Core bootstrap/settings/save logic: `scripts/statsapi_core.lua`
- Main stats API, queueing, display, and callback wiring: `scripts/lib/stats.lua`
- Per-stat apply modules: `scripts/lib/stats/*.lua`
- Vanilla multiplier helpers: `scripts/lib/vanilla_multipliers.lua`
- Damage source helper: `scripts/lib/damage_utils.lua`
- User docs: `README.en.md`, `README.ko.md`

## Worktree Rules

- Do not touch `metadata.xml` unless the user asks. Steam/Isaac tooling may
  modify it independently.
- The worktree may already contain user changes. Read before editing and never
  revert unrelated changes.
- Use `apply_patch` for manual edits.
- Prefer `rg` for searching.

## Stats Rules

- `Tears` and `FixedTears` are different concepts.
- `Tears` means regular fire-rate changes using shots-per-second math.
- `FixedTears` means direct `player.MaxFireDelay` changes. Negative additions
  make the player fire faster.
- Aliases `FireDelay`, `TearDelay`, and `FixedFireDelay` normalize to
  `FixedTears`.
- `CACHE_FIREDELAY` must evaluate both `Tears` and `FixedTears`; do not collapse
  them into one stat.
- `Speed` is clamped through `shared.ClampMoveSpeed`.
- Default speed cap is `2.0`, but callers can override it with:
  - `StatsAPI.stats.setSpeedCap(maxSpeed)`
  - `StatsAPI.stats.getSpeedCap()`
  - `StatsAPI.stats.resetSpeedCap()`
  - `StatsAPI.stats.speed.setCap/getCap/resetCap`
- Keep the old speed functions working when changing cap behavior.

## Damage And Poison

- Damage changes should keep tear poison damage in sync when the Isaac API
  exposes `player:GetTearPoisonDamage` and `player:SetTearPoisonDamage`.
- Unified damage uses `(base + add) * mult`.
- Player-slot damage is applied on top of unified damage as
  `current * playerMult + playerAdd`.
- Poison damage should follow the same final formula as damage for the relevant
  layer.

## Persistence

- `unifiedMultipliers` is saved/restored through StatsAPI save data.
- The cache queue itself is runtime state and should not be treated as durable.
- `playerMultipliers` is runtime slot state. If another mod needs it after a
  continue/restart, that mod should re-register its player-slot effects.
- If changing persistence, update both code and README examples/notes.

## Documentation

- Keep `README.en.md` and `README.ko.md` in sync when changing public behavior.
- README examples are intended to be copyable Lua snippets.
- Document behavior differences, not just function names. In particular, avoid
  describing all stats with one formula because `Tears` and `FixedTears` are
  special.

## Verification

- Parse changed Lua files with `luaparse` when possible.
- Do not rely on a full-tree `luaparse` pass as a clean signal: the existing
  `scripts/lib/damage_utils.lua` uses Lua bitwise syntax such as `flag & ...`,
  which the current `luaparse` command reports as an error.
- For README Lua blocks, parsing snippets through temporary `.lua` files is more
  reliable than passing code through shell arguments.
- In-game behavior still needs Isaac runtime testing; local parsing only catches
  syntax/load-shape issues.

## Loader Notes

- Isaac mods may differ in whether `include` or `require` succeeds for a path.
- Existing loaders try dot and slash path variants. Preserve that compatibility
  when moving files.
- Per-stat modules should tolerate shared helpers being absent where practical,
  but the normal load order is `shared.lua` first, then stat modules.

