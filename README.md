# Assembly Dice Game

A simple console dice game written in **x86 (32-bit) MASM assembly** with a small C++ helper module.

## Gameplay

- Start with a balance of **$100**.
- Default bet is **$10** (configurable from the in-game menu).
- Each turn rolls two six-sided dice:
  - **7 or 11** → win the bet amount
  - **2, 3, or 12** → lose the bet amount
  - **Anything else** → push (no change)
- Run out of money? The game offers a **$100 loan** to keep playing.
- Save your progress to a file named after your player name and reload it later.

## Download & Play (Windows)

The easiest way to play — no build tools required:

1. Go to the [Releases](../../releases) page of this repo.
2. Download `Final Project.exe` from the latest release.
3. Double-click the `.exe`, or run it from a terminal:
   ```
   "Final Project.exe"
   ```

> **Note:** Windows SmartScreen may warn you about an unsigned executable. Click **More info → Run anyway** if you trust the source. The game has no installer and writes save files (`<playername>.txt`) into whatever folder you run it from.

**Requirements:** 64-bit or 32-bit Windows 10/11. The build is 32-bit (x86) so it runs on both.

## Project Structure

| File | Purpose |
|------|---------|
| `callme.asm` | Main MASM source — UI, menus, game loop, save/load, console color output |
| `DiceGame.inc` | Constants, prototypes, and the `mPrint` macro |
| `Final Project.cpp` | C++ helpers: `rollDice`, `applyBet`, `classifyRoll`, plus `main()` |
| `Final Project.vcxproj` / `.slnx` | Visual Studio solution and project files |

The C++ side seeds and runs `std::rand`; the assembly side calls back into C++ via `extern "C"` for randomness and bet math.

## Build From Source

### Requirements

- **Visual Studio 2019 or later** with the **C++ desktop development** workload
- **MASM** build customization enabled for the project (already configured in the `.vcxproj`)
- **Irvine32 library** — `Irvine32.inc` / `Irvine32.lib` must be on the include and library paths

Target platform: **Win32 (x86)**. The project will not build under x64 because Irvine32 is 32-bit only.

### Steps

1. Clone the repo:
   ```
   git clone https://github.com/Seamus-Hennigan/Assembly-Dice-Game.git
   ```
2. Open `Final Project.slnx` in Visual Studio.
3. Set the solution platform to **x86**.
4. Choose **Debug** or **Release** configuration.
5. Build → Run (`F5` to debug, `Ctrl+F5` to run without debugging).

The compiled `.exe` lands in `Debug/` or `Release/` in the project root.

## Author

Seamus Hennigan
