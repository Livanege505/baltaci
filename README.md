# Baltacı 🪓🐶

Cozy 2D incremental tree-cutting game made with **Godot 4.7.2 (GDScript)**. You play **Pipsy**, a yellow
puppy who arrives at grandpa Bodo's abandoned lumber camp. Shifts are short and timed. The axe swings on
its own, and a felled tree knocks over the ones in its path, so chains build up like dominoes. You spend
the gold at the camp on upgrades, and a light story unfolds between shifts.

> Status: week‑1 vertical slice (playable). The game's final name is undecided. UI text is in Turkish.

## Features
- **Felling chain:** a tree falls away from the side you hit it from and damages trees in its fall range by its height. Chains are capped at a +100% bonus.
- **Five chapters:** Kavak Korusu → Çam Patikası → Ladin Yamacı → Sisli Vadi → Altın Meşe Yolu. Each has a finite forest, saved tree checkpoints and a new chapter unlock on completion. Finished chapters can be replayed.
- **Route map:** the upper HUD shows your current chapter, cleared trees, unlocked destinations and a moving Pipsy marker. The camp map selects unlocked chapters.
- **Camp:** a five-slot upgrade bench. Costs target roughly 30–40 shifts with a perfect-aim balance simulator; human play takes longer.
- **Controls:** persistent edge-scroll, camera-follow, scroll-speed, cursor-smoothing, automatic/hold-to-chop and screen-shake preferences. Escape pauses the shift and opens these settings; switching away from the game pauses automatically.
- **Story ("Dedenin Kampı"):** dialogue with portraits and a typewriter effect. Characters are Bilge Baykuş (the wise owl) and Kunduz Kemal (the rival beaver), plus grandpa's letters.
- **Juice:** wind-up and hit-stop on the axe, spring wobble on hit, a gravity fall with bounces, particles, trauma-based screen shake, and iris scene transitions.
- **Save system:** versioned saves with a backup and recovery from corrupted files.
- **Audio:** varied wood chops, critical hits, short wood taps, landings, chain feedback, coins, menus, results and dialogue-page sounds, plus a seamless forest ambience. The door-like creak recordings have been removed. **Ayarlar → Ses** has persistent master, effects and ambience levels, a mute switch and a preview button. World audio pauses with the game; losing focus silences the mix.

## Run
1. Install [Godot 4.7.2](https://godotengine.org/) (the standard build, not .NET).
2. Open `project.godot` in Godot, or run `godot --path .`

To run the tests headless, use `godot --headless --path . -s tests/run_all.gd`. A screenshot mode is also available: `godot --path . res://scenes/forest/forest.tscn -- --autoshot=/abs/shot.png`

Aim at a trunk with the mouse; the aim mark shows the exact hit location and the bottom hint shows the tree's health and fall direction. Move with A/D, the arrow keys, or the screen edges. Clear all trees to finish a chapter. If time runs out, the next shift resumes its saved tree checkpoint; the payout and checkpoint are saved together. Closing the game also saves landed trees. Choose unlocked chapters on the camp map; finished chapters start an explicit replay. Change controls from **Ayarlar** at camp or **Escape** during a shift. Preferences are saved separately from progression.

Screenshot mode uses boosted damage for a visual preview and never writes progression. `--chapter=ridge` selects a preview chapter. The legacy endless-forest economy benchmark is `godot --headless --path . -s tools/sim_balance.gd -- all --samples=8`; its upgrade-completion shift count does not describe the new finite campaign.

See [the Turkish change notes](docs/DUZELTMELER-2026-10-30.md) for fixes, balance changes and remaining content work.

## Repository map
| Path | What |
|---|---|
| `scripts/autoload/` | `Balance` (data), `Art` (sprite lookup with fallback), `Settings`, `Sound` (bounded mixer), `GameState` (save), `Story` |
| `scenes/forest/`, `scenes/camp/`, `scenes/story/`, `scenes/ui/` | gameplay, hub, dialogue, shared UI and juice |
| `data/*.json` | all balance numbers, upgrades, story beats |
| `tests/`, `tools/sim_balance.gd` | headless tests, balance simulator |
| `art/` | sprites + generation tools (see license below) |
| `audio/`, `data/audio.json` | bundled audio, credits/licenses and cue/mix configuration |
| `data/chapters.json`, `scripts/autoload/chapters.gd` | finite chapter definitions and checkpoint/unlock rules |
| `CONTRACT.md`, `HANDOFF.md` | architecture contract and current handoff notes |
| `docs/GELISTIRME-NOTLARI.md` | how it was built: phases, tools, AI agents, lessons (Turkish) |

## License
- **Code:** MIT ([LICENSE](LICENSE)).
- **Art and the Pipsy character:** **not** covered by MIT, all rights reserved ([art/LICENSE.md](art/LICENSE.md)). Pipsy is a friend's character, used with permission.
- **Bundled audio:** CC0 by Kenney and TinyWorlds; original sources and license notices are in [audio/CREDITS.md](audio/CREDITS.md).
