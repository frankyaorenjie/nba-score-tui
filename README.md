# nba-score-tui

`nba-score-tui` is an NBA scoreboard repo with two user-facing apps built on the same live game data:
- a keyboard-driven terminal UI
- a native macOS menubar app

## Choose Your App

| App | Best for | Highlights |
| --- | --- | --- |
| Terminal UI | Staying in the terminal | Live scores, standings, transactions, watch list alerts, game flow, box score, self-update |
| macOS Menubar App | Keeping today's games visible on macOS | Menu bar rotation, starred games, native popover, detail window, startup settings |

## Current Release

- Version: `1.0.0`
- GitHub release: [`v1.0.0`](https://github.com/frankyaorenjie/nba-score-tui/releases/tag/v1.0.0)
- Apple Silicon macOS download: [`NBAScoreMenubar-v1.0.0-arm64.zip`](https://github.com/frankyaorenjie/nba-score-tui/releases/download/v1.0.0/NBAScoreMenubar-v1.0.0-arm64.zip)
- SHA-256 checksum: [`NBAScoreMenubar-v1.0.0-arm64.zip.sha256`](https://github.com/frankyaorenjie/nba-score-tui/releases/download/v1.0.0/NBAScoreMenubar-v1.0.0-arm64.zip.sha256)
- The downloadable release assets are for the macOS menubar app.
- The TUI runs from source with `npm start`.
- Menubar app requirement: macOS 13+

## Quick Start

### Terminal UI

Requirements:
- Node.js
- npm

```bash
git clone https://github.com/frankyaorenjie/nba-score-tui.git
cd nba-score-tui
npm install
npm start
```

`node index.js` runs the same app directly.

### macOS Menubar App

Requirements:
- macOS 13+
- Xcode Command Line Tools / Swift 6

Download the prebuilt Apple Silicon build from the current release, or run it from source:

```bash
git clone https://github.com/frankyaorenjie/nba-score-tui.git
cd nba-score-tui
npm install
npm run menubar
```

Build commands:

```bash
npm run menubar:build
npm run menubar:bundle
```

`npm run menubar:bundle` creates `dist/NBAScoreMenubar-<arch>.app`.

## macOS Menubar App

The menubar app is a native SwiftUI/AppKit companion for keeping today's NBA slate visible without living in the terminal.

### Highlights

- Polls the live NBA scoreboard every 20 seconds
- Shows today's games in a native menu bar popover
- Lets you star games to pin them to the menu bar
- Rotates starred games every 6 seconds, or rotates all games when none are starred
- Opens a separate detail window with game flow, recent plays, and full box score
- Includes footer actions for manual refresh, the NBA.com scoreboard, and quit
- Supports a right-click menu with `Settings`, `About`, and `Quit`
- Settings include `Start at login` and `Start and hide`
- Stores pinned games and settings in `UserDefaults`

### Interactions

- Left click the status item to open or close the scoreboard popover
- Click the star icon to pin or unpin a game in the menu bar rotation
- Click `Detail` to open the separate game detail window
- Right click the status item for `Settings`, `About`, and `Quit`
- Use `Settings` to control `Start at login` and `Start and hide`

### macOS Menubar App Screenshots

<img width="798" height="1172" alt="macOS menubar scoreboard popover" src="https://github.com/user-attachments/assets/2df9c99c-0d3a-4aa7-a038-af1bdb6e82a3" />

<img width="2400" height="1584" alt="macOS menubar game detail window" src="https://github.com/user-attachments/assets/847a7292-06bc-44e1-a88f-ba767a4beeab" />

## Terminal UI

The TUI is the keyboard-first experience for following scores, standings, transactions, and deeper game detail from the terminal.

### Highlights

- Scores view refreshes every 5 seconds with live status and top performers
- Standings view refreshes every 60 seconds for both conferences
- Transactions view refreshes every 60 seconds and includes a player watch list
- Watch list subscriptions trigger desktop notifications and persist in `~/.nba-score-tui-subscriptions.json`
- Game detail view shows score differential, lead changes, recent plays, and full box scores
- Auto-update checks GitHub every hour and pulls from `origin/main`

### Controls

#### Main Views (Scores / Standings / Transactions)

| Key | Action |
| --- | --- |
| `1` | Switch to Scores view |
| `2` | Switch to Standings view |
| `3` | Switch to Transactions view |
| `h` / `←` | Switch to previous view |
| `l` / `→` | Switch to next view |
| `j` / `↓` | Move down / Scroll |
| `k` / `↑` | Move up / Scroll |
| `Space` / `Enter` | Open game details from Scores |
| `u` | Check for updates / Install update |
| `q` | Quit with confirmation |
| `Ctrl+C` | Quit immediately |

#### Transactions View (Watch List)

| Key | Action |
| --- | --- |
| `Tab` | Switch between transactions and watch list panels |
| `Enter` | Search players / Subscribe / Remove from list |
| `d` / `Backspace` | Remove selected player from watch list |
| `Esc` | Cancel search / Go back |

#### Game Detail View

| Key | Action |
| --- | --- |
| `Tab` | Switch focus between Game Flow and Box Score |
| `j` / `↓` | Scroll down in focused section |
| `k` / `↑` | Scroll up in focused section |
| `q` / `Esc` | Go back to main view |

#### Quit Confirmation Dialog

| Key | Action |
| --- | --- |
| `Y` / `Q` / `Enter` | Confirm quit |
| `N` / `Esc` | Cancel |

### Terminal UI Screenshots

#### Scores View

<img width="1520" height="638" alt="Terminal UI scores view" src="https://github.com/user-attachments/assets/b1d5a2ce-9c79-440d-a65f-eece76433f84" />

#### Standings View

<img width="1410" height="960" alt="Terminal UI standings view" src="https://github.com/user-attachments/assets/bff130d9-5395-4b09-83c7-b804a9d14b79" />

#### Transactions View

```text
 [1] Scores   [2] Standings   [3] Transactions

┌─ Transactions ─────────────────────────┐┌─ Watch List ────────────┐
│                                        ││ LeBron James            │
│  Tuesday, January 27                   ││ Trae Young              │
│  ──────────────────────────────────    ││                         │
│    WSH  Signed F Skal Labissiere...    │├─ Search Player ─────────┤
│    CLE  Waived F Chris Livingston.     ││ > lebron                │
│                                        │├─────────────────────────┤
│  Friday, January 9                     ││ ✓ LeBron James          │
│  ──────────────────────────────────    ││   LeBron James Jr.      │
│    WSH  Acquired G Trae Young...       ││                         │
│    ATL  Acquired G CJ McCollum...      ││                         │
└────────────────────────────────────────┘└─────────────────────────┘

  ● 14:32:15 | Tab switch panels | Enter subscribe/remove | q quit
```

#### Game Detail View

<img width="1546" height="1812" alt="Terminal UI game detail view" src="https://github.com/user-attachments/assets/1d120c79-2e6f-46d9-8e12-2c311c5007a8" />

## Data Sources

- Scores: Official NBA live scoreboard and box score APIs
- Standings: ESPN API
- Transactions: ESPN Transactions API
- Player Search: ESPN Search API

## Persistence

- TUI player subscriptions: `~/.nba-score-tui-subscriptions.json`
- Menubar pinned games and settings: `UserDefaults`

## License

MIT
