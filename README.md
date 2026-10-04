# Stilbomber 2
<img width="806" height="594" alt="image" src="https://github.com/user-attachments/assets/50f32a6d-39e1-43f3-9e41-0b4b2492ffd9" />


## Author

This game was made by Tomaxko (Tomáš Zachar)

It was released at 2004 for free.

## Info

Stilbomber 2 is a space shooter that combines the fast action of classic shooters such as *Raptor* and *Tyrian* with a surprising number of RPG elements similar what you can see in i.e. *Diablo 2*.

You receive random items to equip, choose from many ways to improve your ship, and spend a lot of time grinding for better equipment. The result is a classic shooter with a substantial progression system alongside the action.

Unfortunately, the original game stopped running correctly on newer versions of Windows. For many years it remained a great memory, and I occasionally found myself wishing I could play it again.

On 2 October 2026, I asked Astra to make it run again—and it was done in seven minutes :)

## How to run it

This project is for **Windows**. It has been tested on **Windows 11**.

### Quick-start capture

```text
1. Open the Stilbomber-2 folder
2. Run:  Play-Stilbomber-Windowed.cmd
3. Play Stilbomber 2

                 +-------------------------------------------+
                 | Play-Stilbomber-Windowed.cmd              |
                 |                                           |
                 |  Double-click this file to start the game  |
                 +-------------------------------------------+
```

The recommended way to start the game is to double-click [`Play-Stilbomber-Windowed.cmd`](Play-Stilbomber-Windowed.cmd) in the project folder.

You can also launch it from PowerShell:

```powershell
.\Play-Stilbomber-Windowed.cmd
```

The repository may include a `.cache` folder containing the required compatibility-wrapper archive. It is kept there so the project can work more self-contained and does not need to download the wrapper immediately. You can delete `.cache` at any time; the launcher will automatically download and recreate it when the wrapper is needed. If the cache is not present, an internet connection is required the first time the game is prepared.

The game opens in a borderless window at desktop size. Press `Ctrl+Tab` to release the mouse. Windowed-mode progress is stored separately in `game-windowed\save`.

## Repository layout

- `originalgame\` — the original game files
- `compatibility\` — compatibility-wrapper configuration and license
- `.cache\` — cached compatibility-wrapper download; safe to delete because the launcher recreates it
- `scripts\` — setup and launch scripts
- `Play-Stilbomber-Windowed.cmd` — recommended launcher

The preparation script verifies the SHA-256 hashes of the game and compatibility files before using them, and keeps the original game folder unchanged.

## Screenshots

<img width="2101" height="1579" alt="image" src="https://github.com/user-attachments/assets/5829b192-05c1-44b7-8d30-6dc9015effb7" />
