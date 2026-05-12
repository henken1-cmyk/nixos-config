# Hyprland Lua Config Migration — Design

**Date:** 2026-05-12
**Status:** Design, awaiting approval
**Motivation:** Future-proofing. Hyprland v0.55.0 introduced a Lua config manager (PR hyprwm/Hyprland#13817) and now generates Lua by default for fresh installs. Legacy hyprlang remains supported, but Lua is upstream's direction of travel. Home Manager's `wayland.windowManager.hyprland` module currently emits only hyprlang. This spec covers adding Lua emission so HM users can opt in.

## Goal

Add Lua-format output to Home Manager's `wayland.windowManager.hyprland` module, validated locally on this flake first, then contributed upstream. After the upstream PR merges, our three hosts opt into Lua via one option.

## Non-goals

- Migrating Hyprlock or hypridle configs. Those are separate programs with their own (still-hyprlang-only) config languages. Out of scope; `hyprlock.conf` and `hypridle.conf` continue to be emitted as hyprlang regardless.
- Adopting Lua-only Hyprland features (event callbacks like `hl.on("workspace.changed", ...)`, dynamic rules, custom Lua dispatcher functions, timers). These can land in follow-up commits once the basic Lua emission works.
- Plugin Lua hooks — the plugin Lua API is incomplete in v0.55.0; plugin-using configs stay on hyprlang format until upstream stabilises it.
- Deprecating hyprlang format. Both formats stay first-class options.
- Changing the user-facing shape of `wayland.windowManager.hyprland.settings`. Users write the same Nix attrset; we change only what serialization runs at build time.

## Constraints and principles

- **Repeat established patterns.** Mirror `lib.hm.generators.toHyprconf`, `lib.generators.toLua`, `lib.generators.mkLuaInline`, the option layout from `programs.wezterm.settings`, the option naming from existing format switches in HM. Do not invent new abstractions where existing ones suffice.
- **Backwards compatible by default.** New `format` option defaults to `"hyprlang"`. Existing users see no change.
- **Single source of truth for input.** The `settings` attrset is canonical. Two serializers consume it; users do not see a fork.
- **Dogfood before contributing.** Ship the generator and module change in this flake first, on `lightspeed`, until it has cleared a concrete validation gate (defined below). Only then extract into an upstream PR.

## What the Lua emission actually looks like

From `example/hyprland.lua` at tag v0.55.0, the API surface is procedural and typed. The generator must emit each top-level key in `settings` as one of the following forms:

| Hyprlang input | Lua emission | Notes |
|---|---|---|
| `general { gaps_in = 5; ... }` | `hl.config({ general = { gaps_in = 5, ... } })` | Each section becomes one `hl.config({...})` call (or coalesced into fewer calls; merge semantics are additive). |
| `decoration { ... }` | `hl.config({ decoration = { ... } })` | Same as above. |
| `monitor = ["DP-1,...", ...]` | `hl.monitor({ output = "DP-1", mode = "...", ... })` per item | Hyprlang's positional comma form must be parsed back into a record. |
| `bezier=name,p1x,p1y,p2x,p2y` | `hl.curve("name", { type = "bezier", points = { {p1x, p1y}, {p2x, p2y} } })` | New API; no direct hyprlang equivalent in shape. |
| `animation=name,enabled,speed,curve[,style]` | `hl.animation({ leaf = "name", enabled = true, speed = ..., bezier = "curve", style = "..." })` | Positional → keyword translation. |
| `bind = "MODS, KEY, dispatcher, arg"` | `hl.bind("MODS + KEY", hl.dsp.<path>(...), { opts })` | **The hard one.** See "Bind translation" below. |
| `windowrulev2 = "rule, selector"` | `hl.window_rule({ ... })` | Exact field shape confirmed against Lua API stubs at implementation time. |
| `workspace = "id, rules"` | `hl.workspace_rule({ ... })` | Exact field shape confirmed at implementation time. |
| `gesture = "..."` | `hl.gesture({ ... })` | Exact field shape confirmed at implementation time. |
| `device { name = "..."; ... }` | `hl.device({ name = "...", ... })` | Per-device blocks become record calls. |
| `env = "KEY,value"` | `hl.env("KEY", "value")` | Per item. |
| `exec-once = "cmd"` | inside `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` | All exec-once entries grouped into one callback. |
| `exec = "cmd"` | inside `hl.on("config.reload", function() hl.exec_cmd("cmd") end)` | Distinct callback hook. |
| `submap = name { bindings... } submap = reset` | `hl.define_submap("name", reset_bool, function() ...binds... end)` | Submap block emits one `hl.define_submap` call wrapping its inner binds. The `submap, reset` exit dispatcher inside a submap stays as `hl.dsp.submap("reset")`. |
| `plugin` | **deferred** until upstream plugin Lua API stabilises | |
| Nix-interpolated literals (`${colors.base00}`, `${vars.monitors}`) | unchanged — Nix runs at build time, output is plain strings/numbers/lists | |
| Raw Lua values (callable dispatchers, future hooks) | `lib.generators.mkLuaInline "hl.dsp.exec_cmd(...)"` | Escape hatch for users who need Lua-native types. |

### Bind translation

This is the load-bearing complexity. Hyprlang binds are `"MODS, KEY, dispatcher, arg"` (string-positional). Lua binds are `hl.bind(keychord, hl.dsp.<path>(args), opts)`. The translation requires:

1. **Keychord rewrite.** `"SUPER, Q"` → `"SUPER + Q"`. Comma-to-plus with whitespace trimming. Hyprland's Lua API accepts the same keysym strings hyprlang accepts (X11 keysyms, mouse:N, XF86 names) — no casing normalization needed beyond what hyprlang already permits.
2. **Dispatcher mapping table — not 1:1, with sub-namespaces.** Hyprland's Lua dispatchers live under `hl.dsp.*` organised into namespaces. Confirmed in v0.55.0 source (`src/config/lua/bindings/LuaBindingsDispatchers.cpp`): 14 top-level (`exec_cmd`, `exec_raw`, `exit`, `submap`, `pass`, `send_shortcut`, `send_key_state`, `layout`, `dpms`, `event`, `global`, `force_renderer_reload`, `force_idle`, `focus`, `no_op`), 21 under `hl.dsp.window.*`, 4 under `hl.dsp.workspace.*`, 7 under `hl.dsp.group.*`, 2 under `hl.dsp.cursor.*`. 48 Lua dispatchers total, absorbing the larger hyprlang dispatcher set through keyword-argument variants. Examples observed in source:
   - hyprlang `movefocus, l` → Lua `hl.dsp.focus({ direction = "left" })`
   - hyprlang `workspace, e+1` → Lua `hl.dsp.focus({ workspace = "e+1" })`
   - hyprlang `togglefloating` → Lua `hl.dsp.window.float({ action = "toggle" })`
   - hyprlang `movetoworkspace, N` → Lua `hl.dsp.window.move({ workspace = N })`

   The mapping is many-to-many: multiple hyprlang dispatcher names map to one Lua function path, differentiated by which keyword args are populated.
3. **Bind flag prefix translation.** Hyprlang prefix syntax (`binde`, `bindl`, `bindm`, etc.) maps to keyword opts in Lua: `{ repeating = true }`, `{ locked = true }`, `{ mouse = true }`.

**The dispatcher mapping table is the maintenance liability of the generator.** It must be kept in sync with Hyprland's dispatcher set across versions. It is also the strongest argument for landing this work in HM rather than fragmenting it across personal flakes — the table should be maintained in one place by the same people maintaining the Hyprland HM module.

## Phases

### Phase 1 — Audit

Walk `home/system/hyprland.nix` linearly. For each key in the generated `settings` attrset, record:
- the emission bucket (per the table above)
- the target Lua line(s)
- any data shape transformations needed (string-form parsing, dispatcher-table lookup)

**Done when:** a table in the implementation plan lists every key in our current `settings` with its emission target, and every dispatcher used in our binds appears in the dispatcher table draft. No "TBD" entries.

### Phase 2 — Local generator and migration

Three components, hosted in this flake:

1. **A Lua serializer** in our flake `lib/` (e.g., `lib/toHyprlandLua.nix`) that mirrors `toHyprconf`'s structural knowledge and emits the buckets above. Built on `lib.generators.toLua` for primitive values and `lib.generators.mkLuaInline` for raw-Lua passthrough. Includes the dispatcher table.
2. **A vendored HM module fork.** Copy `modules/services/window-managers/hyprland.nix` from HM into our flake under e.g., `overlays/home-manager-hyprland.nix`. Add a `format = "hyprlang" | "lua"` option. When `"lua"`, route `settings` through our generator and write `~/.config/hypr/hyprland.lua`; otherwise unchanged. Activated via `disabledModules = [ "services/window-managers/hyprland.nix" ]` + import of the fork in our HM imports list. This is the only mechanism that actually swaps a HM module cleanly.
3. **A one-line flip** in `home/system/hyprland.nix`: add `format = "lua";`. The `settings` attrset is unchanged.

**Done when, in this exact order:**
1. `nh os test` builds successfully on `lightspeed`.
2. `~/.config/hypr/hyprland.lua` exists, is valid Lua (lints with `luac -p`), and matches a hand-audit of the bucket table from Phase 1.
3. `hyprctl reload` succeeds; journalctl shows `Using lua config found at ...` (the Lua manager log line).
4. Monitor config (`hyprctl monitors`) matches our `vars.monitors` declaration.
5. A full normal-use cycle covering at least: one DPMS-off→on transition while locked, one `hyprctl reload`, one fresh session via `Hyprland` start (after logout), use of every workspace, exercise of all ~40 keybinds at least once. No coredumps, no Hyprland warnings about unknown config keys, no missing or broken keybinds.

Only after all six gates pass does Phase 3 begin.

### Phase 3 — Upstream contribution

Lift the same generator and module changes into a `nix-community/home-manager` PR.

**PR shape — commit chain:**

1. `lib.hm.generators: init toHyprlandLua` — generator function only, with tests against fixture inputs. No consumer yet.
2. `hyprland: add format option` — wires the generator into the module. Defaults to `"hyprlang"`.
3. `hyprland: tests for lua format` — snapshot tests using `assertFileContent` against expected `.lua` fixtures. Mirror existing toHyprconf test layout.
4. `news: announce hyprland lua format option`.
5. (Conditional) `maintainers: add kacper` — only if a new maintainer entry is required by reviewers.

**Reviewer expectations** (derived from `nix-community/home-manager` PRs #5341, #8442, #9050):

- Likely reviewers: `khaneliman` (authored `toHyprconf`, reviewed wezterm settings), `fufexan` (Hyprland-ecosystem reviewer), `ambroisie` (broader HM reviewer), `rycee` (lead maintainer).
- **Commit granularity.** Split into the commits above, don't bundle.
- **No spurious whitespace.**
- **Tests via `assertFileContent` (full-file snapshot), not `assertFileContains` (line-match).**
- **Place declarations close to usage.** Don't hoist `let`-bindings far from their consumers.
- **Backwards compatibility stated explicitly in the PR description.**
- **Thorough option `description` blocks.** Document `mkLuaInline` escape, merge semantics, the dispatcher table's version coupling.
- **`nix fmt` before pushing.**

**Why `format = "hyprlang" | "lua"` and not `useLua = true`:**

- Extensibility: a future emission format (e.g., a hypothetical JSON config) wouldn't fit a boolean.
- Discoverability: `format = ?` invites tab-completion / docs lookup; `useLua` requires knowing the name in advance.
- Symmetry with how HM exposes other emission switches (e.g., `programs.git.iniContent`-style options where the format is implicit by file but explicit in option naming).

**Done when:** PR merges; our flake drops its vendored module fork and local generator; `home/system/hyprland.nix` depends on the upstream HM option directly. End state: zero behavioral diff between pre-PR-merge and post-PR-merge on our hosts.

## Risks

| Risk | Mitigation |
|---|---|
| **Dispatcher table is the maintenance burden.** Hyprland may add/rename dispatchers between releases. Out-of-sync table = silent bind breakage on upgrade. | Generator emits a clear error when an unknown dispatcher appears (rather than silently passing the string through). Add a dispatcher to the table the moment it appears in our config. After upstream merge, the burden is shared with HM maintainers, not on us alone. |
| **Lua API surface drifts between v0.55.0 and PR merge.** | Generator targets the API as documented at `example/hyprland.lua` for a pinned version. Nix flake update cadence forces us to revisit on each Hyprland bump. The surface is small (~10 top-level `hl.*` functions) so point-fixes are cheap. |
| **Reviewers want a different option name or generator shape.** | Local generator decouples our flake from upstream design. We absorb feedback in the PR; running system unaffected. Worst case: rename and adjust during review. |
| **Plugin Lua API is incomplete in v0.55.0.** Configs that load plugins via `plugin { ... }` blocks can't switch to `format = "lua"` until upstream stabilises the plugin Lua side. | Plugin-using configs stay on hyprlang format. Generator rejects plugin blocks with a clear error in Lua mode. |
| **HM ships its own competing Lua support during our work.** | Unlikely (issue nix-community/home-manager#9242 has no implementation in flight as of 2026-05-12). If it happens, our PR either coordinates with or supersedes that work; either way our flake keeps working in the interim via the vendored fork. |
| **Hyprlock/hypridle users assume "Hyprland Lua" means their configs also migrate.** | Explicitly scope-excluded in Non-goals. Document in option description and PR. |

## Out of scope (deferred follow-ups)

- Plugin Lua hooks — the plugin-side Lua API is incomplete in v0.55.0. Generator rejects `plugin { ... }` blocks in Lua mode with a clear error pointing users back to hyprlang format until upstream stabilises.
- Hyprlock and hypridle Lua support — no upstream Lua support exists for either program.
- Lua-native features like `hl.on("workspace.changed", ...)` event callbacks, dynamic rules at runtime, custom Lua dispatchers, `hl.timer(...)`. These become first-class once the basic emitter works.

## References

- Hyprland v0.55.0 release notes (2026-05-09)
- Hyprland Lua config manager: hyprwm/Hyprland#13817
- Hyprland Lua example config: `example/hyprland.lua` at tag v0.55.0
- Hyprland Lua API type stubs: `hl.meta.lua` (not yet stable in v0.55.0 — currently a stub file)
- HM `toHyprconf` generator init: nix-community/home-manager#5341
- HM `toHyprconf` extension: nix-community/home-manager#8442
- HM `programs.wezterm.settings` precedent: nix-community/home-manager#9050
- HM hyprland Lua feature request: nix-community/home-manager#9242
- Our running config: `home/system/hyprland.nix`
