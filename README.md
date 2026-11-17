# roblox-brainrot-01 — Brainrot game for make.fun

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ncyrmd/makefun-roblox-brainrot-01-v1/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ncyrmd/makefun-roblox-brainrot-01-v1/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty
(roblox-brainrot-01), built by an AI coding agent in Roblox Studio / Rojo.

The player collects absurd, meme-born brainrot characters that each earn money per
second, keeps them on a base, and climbs a ladder of rarities, mutations and rebirths —
while rival players can steal and a hazard forces a dash home with the catch.

- `main.ts` (Node 22, stdlib only) hands the game in: it copies `game.rbxl`, `src/`,
  `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts` (the kit's copy, unchanged).
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`.
- `PLAY.json` names the published Public place on Roblox.
- `screenshots/` holds 3–4 captures of the game running; the first by name is the
  cover and matches the game's first thumbnail on Roblox.

Run it as the grader does:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

Bounty: https://make.fun/bounty/roblox-brainrot-01
