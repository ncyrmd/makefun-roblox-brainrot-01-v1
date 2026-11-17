// A working roblox-brainrot-01 entry (Node 22, standard library only): the game is this directory's Rojo
// project, built into game.rbxl with `rojo build default.project.json --output game.rbxl`, and the program
// hands it in. It copies game.rbxl, src/, screenshots/ and PLAY.json from beside this file to /output and
// writes /output/dossier.json, the summary the judge reads, with the vendored make.fun library. A starting
// point, not a winner: it is a grey square that moves with the arrow keys. Build your game, rebuild
// game.rbxl, put your PNG or JPEG screenshots in screenshots/ (the first by name is the cover, and one of
// them is the thumbnail you upload for your game on Roblox) and fill in PLAY.json with your published place.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -: the
// grader fails an entry whose output holds any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/**
 * Brainrot Bay entry preflight, written for this game (not part of the kit starter):
 * refuse to hand in an entry the gate would refuse on its face — a missing or
 * XML-format place, the wrong number of screenshots, or an unreadable PLAY.json —
 * so a broken build fails loudly here instead of silently at grading time.
 */
function validateBrainrotBayEntry(): void {
  const placePath = join(here, 'game.rbxl');
  const place = readFileSync(placePath);
  if (place.length < 8 || place.subarray(0, 8).toString('latin1') !== '<roblox!') {
    throw new Error('game.rbxl is not a binary Roblox place (expected <roblox! magic)');
  }
  if (place.length > 32 * 1024 * 1024) {
    throw new Error(`game.rbxl is ${place.length} bytes, over the 32 MiB gate cap`);
  }
  const shots = readdirSync(join(here, 'screenshots')).filter((n) => !n.startsWith('.'));
  if (shots.length < 3 || shots.length > 4) {
    throw new Error(`screenshots/ holds ${shots.length} images, the gate wants 3 or 4`);
  }
  for (const shot of shots) {
    const size = statSync(join(here, 'screenshots', shot)).size;
    if (size > 256 * 1024) throw new Error(`${shot} is ${size} bytes, over the 256 KiB cap`);
  }
  const play = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8')) as {
    url: string;
    place_id: number;
    universe_id: number;
  };
  if (typeof play.url !== 'string' || !play.url.startsWith('https://www.roblox.com/games/')) {
    throw new Error('PLAY.json url is not a Roblox games link');
  }
  if (play.place_id === 0 || play.universe_id === 0) {
    // Expected until Nicky publishes the experience: warn, do not fail, so the
    // local build and dossier still verify end to end before publish day.
    console.warn('Brainrot Bay: PLAY.json still holds placeholder ids (0) — publish is pending.');
  }
  console.log(
    `Brainrot Bay entry validated: place ${place.length} bytes, ${shots.length} screenshots, PLAY ${play.url}`,
  );
}

validateBrainrotBayEntry();

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
