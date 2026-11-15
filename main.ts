// Dusk Vault's hand-in program (Node 22, standard library only).
//
// The game is the Rojo project in this directory: `rojo build default.project.json -o game.rbxl`
// turns src/ into game.rbxl. This program copies game.rbxl, PLAY.json, src/ and screenshots/ to the
// output directory and writes dossier.json there with the kit's library.
//
// Outside the grader, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const repo = dirname(fileURLToPath(import.meta.url));
const output = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The scorer's caps, as the kit states them.
const CAPS = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};

// Everything the entry hands in. Each must exist: a missing one is named, not skipped.
const HAND_IN = ['game.rbxl', 'PLAY.json', 'src', 'screenshots'];

mkdirSync(output, { recursive: true });
for (const name of HAND_IN) {
  const source = join(repo, name);
  if (!existsSync(source)) {
    throw new Error(`main.ts: ${name} is missing beside main.ts; build the place with rojo and add the screenshots first`);
  }
  cpSync(source, join(output, name), { recursive: true });
}
writeFileSync(join(output, 'dossier.json'), buildDossier(output, CAPS));
