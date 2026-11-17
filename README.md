# Brainrot Bay — Steal a Brainrot · roblox-brainrot-01

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ncyrmd/makefun-roblox-brainrot-01-v1/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ncyrmd/makefun-roblox-brainrot-01-v1/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

**Brainrot Bay** is a 3D Roblox brainrot game for make.fun's "Make the best AI Roblox
brainrot game" bounty (roblox-brainrot-01), built by an AI coding agent with Rojo + Luau.

You spawn on a sunny bay island. Absurd brainrot characters waddle down the central
conveyor — buy one, carry it home, and plant it on your base. Every brainrot earns
money every second, so a full base prints cash while you hunt the next rarity tier.
Rivals can steal straight off your base unless you lock it, and every 90 seconds a
Brainrot Storm sweeps the island: income doubles, but the wind halves your walk
speed, so grab your catch and dash home. Spend your fortune on rebirths for a
permanent income multiplier and climb from a pizza slice to a Brainrot God.

## How to play

- **Move** with WASD / arrow keys (Roblox default character controls).
- **Buy** a brainrot by clicking it on the conveyor, or from the Shop panel (right).
- **Earn** — every brainrot on your base pays its $/sec into your wallet, every second.
- **Steal** — click a brainrot on another player's base (20 s cooldown; locked bases
  can't be robbed).
- **Lock** your base with `L` (costs $500, lasts 60 s) so nobody can steal from you.
- **Rebirth** — when you can afford it, reset your cash and brainrots for +25%
  income forever. Rebirths stack.
- **Storm** — when the warning flashes, income is 2× but you walk at half speed.

## The cast

14 named brainrots across 6 rarities — Common, Rare, Epic, Legendary, Mythic and
Brainrot God — from **Noobini Pizzanini** ($25, $1/s) to **Grandma's WiFi Router**
($750,000, $12,000/s). See `src/shared/Brainrots.luau` for the full ladder.

## Layout of this repo

- `main.ts` (Node 22, stdlib only) hands the game in: it validates the entry, copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes
  `/output/dossier.json` with `vendor/makefun-roblox.ts` (the kit's copy, unchanged).
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `src/shared/` — `Brainrots.luau` (cast data + rarity helpers) and `Config.luau`
  (economy tuning, single source of truth).
- `src/server/` — `GameState.luau` (the single state store: money, bases, income),
  `Spawner.luau` (conveyor brainrots), `Steal.luau` (stealing + base lock),
  `Rebirth.luau` (rebirth costs and resets), `Hazard.luau` (Brainrot Storm timer),
  `init.server.luau` (wiring: remotes, base assignment, income tick).
- `src/client/Game.client.luau` — the HUD: money, Shop, base slots, Lock/Rebirth
  buttons, storm warnings (kept clear of the top-left Roblox menu corner).
- `screenshots/` — 3 images, 1280×720, first by name is the cover / thumbnail.
  **Note:** until the game is published and played in Studio, these are composed
  artwork of the game's own world and characters, NOT captures of it running —
  see `BUILD_NOTES.md`. They must be replaced with real Studio captures before
  any submit.
- `PLAY.json` names the published Public place on Roblox. It still holds the
  starter zeros: publishing needs Nicky's Roblox account (see `BUILD_NOTES.md`).

## Verify it as the grader would

```sh
export PATH="$HOME/workspace/makefun/tools:$PATH"
for f in $(find src -name '*.luau'); do luau-analyze "$f" && luau-compile "$f" > /dev/null; done
rojo build default.project.json --output game.rbxl
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
node cli/makefun.mjs check --repo . --worktree   # from the unpacked kit dir
```

Bounty: https://make.fun/bounty/roblox-brainrot-01
