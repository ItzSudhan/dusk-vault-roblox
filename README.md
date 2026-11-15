# dusk-vault-roblox

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/ItzSudhan/dusk-vault-roblox/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/ItzSudhan/dusk-vault-roblox/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

Dusk Vault is a turn-based heist game for Roblox, drawn flat on the screen with Roblox GUI objects. You are a thief on a 13 by 9 grid. Every step you take is one turn, and the vault answers. Grab every key to unlock the door and get out before your moves run out.

- **Six vaults**, each with its own layout and twist: the Gallery (guards), the Kennels (lasers that fire every third turn), the Crypt (a wraith), the Foundry (two drones on rings), the Mirror Hall (teleport pads and a mimic), the Crown Room (all five enemies).
- **Five enemies**, each with its own rule: guards pace their corridors, hounds chase on every second turn, wraiths drift through walls on every third, drones fly straight and turn right at walls, mimics take your own step backwards.
- **Three tools**: smoke freezes every enemy for four turns, the cloak lets enemies pass through you for three, the jammer keeps lasers dark for five.
- **Two modes**: HEIST (three lives) and MASTER (two lives, 70% of the moves, double points). Your best score is saved.

Controls: WASD or the arrow keys move, Space waits a turn, Q smoke, E cloak, R jammer, 1 and 2 pick the mode, Enter starts, M returns to the menu. The on-screen buttons do the same.

Eleven scripts, one job each (`default.project.json` says where each goes in the place):

- In ServerStorage, out of the client's reach, the game as pure functions: `src/Rules.luau` (the turn, modes, scoring, win and loss), `src/Levels.luau` (the six maps), `src/Enemies.luau` (the five movement rules), `src/Tools.luau` (the three tools), and `src/BestScore.luau` (the saved best score, every DataStore call in `pcall`).
- `src/Sessions.server.luau`: the server owns every player's run, applies intents with the rules and sends the state back.
- `src/Client.client.luau`: sends intents (keys and buttons) and hands each state to the views in StarterGui: `src/Board.luau` (the vault), `src/Hud.luau` (the ledger, goal line and buttons), `src/Screens.luau` (title, end, vault banner) and `src/Draw.luau` (palette, sprites, the cast).

Every vault is proven solvable in both modes by a breadth-first search over `Rules.act`.

## Run it

```sh
rojo build default.project.json -o game.rbxl   # src/ -> the place file
open -a RobloxStudio game.rbxl                 # press Play to play it
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts   # the hand-in: copies the entry and writes out/dossier.json
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=1pww8frk&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
