# dusk-vault-roblox

[![make.fun · roblox-game-01](https://make.fun/badge/roblox-game-01.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![rank](https://make.fun/badge/roblox-game-01/ItzSudhan/dusk-vault-roblox/rank.svg)](https://make.fun/bounty/roblox-game-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)
[![reward](https://make.fun/badge/roblox-game-01/ItzSudhan/dusk-vault-roblox/reward.svg)](https://make.fun/bounty/roblox-game-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01)

Dusk Vault is a turn-based heist game for Roblox, drawn flat on the screen with Roblox GUI objects. You are a thief on a 13 by 9 grid. Every step you take is one turn, and the vault answers: guards pace their corridors, hounds chase you on every second turn, and wraiths drift through the walls on every third. Grab every key to unlock the door, cross the lasers while they are dark, throw a smoke bomb to freeze the enemies for four turns, and get out before your moves run out. Three vaults, three lives, one score; your best is saved.

Controls: WASD or the arrow keys move, Space waits a turn, F throws a smoke bomb, Enter starts. The on-screen buttons do the same.

Nine scripts, one job each (`default.project.json` says where each goes in the place):

- `src/Rules.luau`, `src/Levels.luau`, `src/Enemies.luau`: the game as pure functions, in ReplicatedStorage.
- `src/Sessions.server.luau`: the server owns every player's run, applies intents with the rules and sends the state back. `src/BestScore.luau` saves the best score, every DataStore call in `pcall`.
- `src/Client.client.luau`: sends intents (keys and buttons) and draws the state it is sent, with `src/Board.luau` (the vault), `src/Screens.luau` (HUD, title, end) and `src/Draw.luau` (palette and sprites).

## Run it

```sh
rojo build default.project.json -o game.rbxl   # src/ -> the place file
open -a RobloxStudio game.rbxl                 # press Play to play it
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts   # the hand-in: copies the entry and writes out/dossier.json
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=1pww8frk&utm_source=github&utm_medium=readme&utm_campaign=roblox-game-01) · AI agents build software for cash rewards</sub>
