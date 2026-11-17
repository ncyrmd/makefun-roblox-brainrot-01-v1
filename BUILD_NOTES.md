# Brainrot Bay — BUILD NOTES (v1)

Game: **Brainrot Bay** ("Steal a Brainrot"-genre, own world/cast).
Built 2026-11-17 in the recorded session (recording 01a1e9fc, live since 21:50 WIB).
Repo: https://github.com/ncyrmd/makefun-roblox-brainrot-01-v1 — local HEAD to be
filled in by the commit below. NOT submitted, NOT published.

## What was built

- **Cast** (`src/shared/Brainrots.luau`): 14 named brainrots across 6 rarities
  (Common → Brainrot God), $25/$1-per-sec up to $750,000/$12,000-per-sec.
  Names: Noobini Pizzanini, Sir Spaghetti Legs, Cappuccino Carl, Tungy the
  Traffic Cone, Madame Baguette, DJ Fridge Magnet, Professor Pickle Rickshaw,
  Goldfish CEO, La Vaca's Intern, Chimpanzini Bananini Jr., Tralala's Lawyer,
  Bombardiro's Uncle, The Forbidden Burrito, Grandma's WiFi Router.
- **Game loop** (server, single state in `GameState.luau`): character moves in
  the 3D world → brainrots waddle down the central conveyor (`Spawner.luau`,
  weighted rarity spawns every 4 s) → click to buy (or buy from the Shop) →
  brainrot stands on your base slot and pays $/sec every second (income tick)
  → next tier bought with the earnings.
- **Tension/progression** (each real in code): stealing by clicking a brainrot
  on a rival's base (`Steal.luau`, 20 s cooldown, refused on locked bases);
  base lock ($500, 60 s, key `L` via ContextActionService); Brainrot Storm
  hazard (`Hazard.luau`, every 90 s: 10 s warning, 20 s storm, 2× income,
  WalkSpeed halved to 8, storm wall sweeps the map); rebirths (`Rebirth.luau`:
  cost $100K × 2.5^n, resets cash + base, +25% income forever, stacks).
- **Client HUD** (`src/client/Game.client.luau`): title top-center, money panel
  top-right, Shop panel (full cast with Buy buttons, `B` toggles), Lock/Rebirth
  buttons bottom-center, toast messages, storm banner, steal hint. All HUD
  text is clear of the top-left Roblox menu corner. Keys use
  ContextActionService, not InputBegan + gameProcessedEvent.
- **World** (`default.project.json`): grass island, 4 player bases (6 neon
  slots + spawn pad + BASE N sign each), 12-segment yellow/black conveyor,
  spawn location, storm wall, 8 trees, 4 lamps, 4 clouds. 129 instances total.
- **Entrypoint** (`main.ts`): extended with my own preflight validation
  (binary `<roblox!` magic, ≤32 MiB place, 3–4 screenshots ≤256 KiB, PLAY.json
  parse; warns — does not fail — on placeholder ids so the local build still
  verifies before publish day). README.md rewritten in full (badges kept).
- **TOUR.json**: updated to the new screenshots; step 3 calls
  `ServerScriptService.Hazard.triggerStorm` on the server.

## Verification (as the grader would)

1. `luau-analyze` on all 9 `.luau` files: zero real errors. (The standalone
   analyzer also reports "Unknown global" for Roblox runtime globals —
   `game`, `Instance`, `Color3`, `Enum`, `task`, `script` — because it runs
   outside Roblox; those are not code errors. The gate's `luau_compiles` row
   is compilation only.)
2. `luau-compile` on all 9 files: OK, 9/9.
3. `rojo build default.project.json --output game.rbxl`: OK. Binary place
   (`<roblox!` magic), 25,395 bytes, ≤32 MiB. Built INSIDE this recorded
   session from `src/` (a place built outside the recording would be a
   disqualification).
4. `mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts`: runs clean, writes
   `out/dossier.json` (498,832 bytes, under the 1.5 MiB cap). Dossier says:
   129 instances, 9 scripts, 46,190 bytes of source, **100.0% matched to
   src/** (9 of 9 scripts, 9 of 9 src/ files) — no hand-placed scripts exist
   only in the place. `out/` holds exactly game.rbxl, PLAY.json,
   dossier.json, src/, screenshots/ (no dotfiles).
5. Kit check (`node cli/makefun.mjs check --repo … --worktree`):
   - PASS: competition_open (open 14:30 UTC 17 Nov → deadline 14:30 UTC
     20 Nov), snapshot (36 files, 1,392,884 bytes), license_osi (MIT),
     entrypoint (main.ts, node22).
   - FAIL (expected): play_link — PLAY.json still holds starter zeros
     (no published place yet). Everything else is a skip (transcript checks
     run on the site) or "checked at submission" (repo_public, repo_owner,
     repo_created_after_open, commit_in_repo, duplicate_snapshot — the commit
     has not been pushed to GitHub yet).
   - Play code (code 0 of 4): **makefun-cattail-saucer-frost** — goes in the
     experience description at publish (see below).

## Screenshots — COMPOSED PLACEHOLDERS, NOT CAPTURES

`screenshots/` holds 3 images (1280×720 JPEG, ~104–118 KiB each, 16:9,
first by name `1-cover.jpg` is the cover/thumbnail):
`1-cover.jpg` (title + 4 brainrots on the conveyor), `2-play.jpg`
(gameplay: base + conveyor + Shop), `3-base.jpg` (base close-up + storm
banner + Lock/Rebirth buttons). They are **artwork composed with PIL from
this game's own world and characters — NOT captures of the game running in
Roblox Studio**. That is allowed for the thumbnail, but the rules say an
entry whose screenshots are plainly not captures of the game it hands in is
disqualified at finalist review. **Before any submit, replace all three
with real Studio captures of actual gameplay** (and upload the cover as the
experience's first thumbnail on the Creator Dashboard).

## Publish steps for Nicky (blocks submit until done)

Publishing needs YOUR Roblox account — the agent cannot do it (Roblox Studio
is Windows/macOS only; this VM is Linux headless). The account must be
≥2 days old and past Roblox's age check.

1. On a Windows/Mac with Roblox Studio, sign in to your Roblox account,
   open `game.rbxl` from this repo in Studio.
2. File → Publish to Roblox As… → create a NEW experience (name it
   "Brainrot Bay"), publish the place as its start place.
3. On the Creator Dashboard (https://create.roblox.com/dashboard/creations):
   open the experience → Configure → add a description containing the play
   code exactly as it stands: **makefun-cattail-saucer-frost** (any one of
   your 4 codes passes; do not write it as a web address — Roblox refuses
   descriptions that read like URLs, so put the code on its own line),
   set a genre, answer the content questions, then set the audience to
   **Public**.
4. Get the ids: `place_id` = the number in the play link
   (https://www.roblox.com/games/<placeId>), `universe_id` = the number
   after `experiences/` in the experience's Creator Dashboard address
   (or `game.GameId` in Studio). Tell woony both numbers (or paste the play
   link) — woony fills PLAY.json inside a recorded session and re-verifies
   with `makefun check` until play_link passes.
5. Take the real screenshots in Studio (game running, HUD clear of the
   top-left corner), replace the 3 files in `screenshots/`, then upload on
   the Creator Dashboard: the experience's start place → Icon (512×512
   square) and Thumbnails (first thumbnail = the same file as
   `screenshots/1-cover.jpg`). Wait until the experience page shows both
   (Roblox reviews each upload).
6. Then woony submits (quota: 5/day, 10 total; check `makefun status`
   first — 3 submits were already used on 17 Nov against the country cap,
   so the first submit window is after the 07:00 WIB reset; keep 1 slot in
   reserve for a final attempt 2h before the deadline, Fri 20 Nov 19:30 WIB).

## Rojo lessons (for the next build)

- `TextLabel.Size` (UDim2) in a project file must use the EXPLICIT form:
  `"Size": {"UDim2": [[1.0, 0], [1.0, 0]]}`. A 4-number array
  (`[1,0,1,0]` or `[1.0,1.0,0.0,0.0]`) fails with "Expected UDim2, got an
  array of four numbers", and `{"Scale":[…],"Offset":[…]}` fails JSON
  deserialization outright. (Docs: https://rojo.space/docs/v7/properties/ —
  UDim2 section.)
- `"Shape": "Ball"`, `"Face": "Front"/"Back"`, `"Font": "GothamBold"`,
  `"Material": "Wood"/"Grass"/"Neon"`, `"Technology": "Future"` all build
  fine in Rojo 7.7.1.
- `luau-analyze` run standalone will always flag Roblox globals as
  unknown; judge it by `luau-compile` + the filtered analyze output.
