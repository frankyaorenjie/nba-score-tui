# AGENTS.md

## Purpose

This repository contains two user-facing apps that share the same NBA scoreboard domain:

- A Node.js terminal UI in `index.js`
- A native macOS menubar app in `macos-menubar/`

Keep changes scoped to the surface you are modifying. Do not rewrite both apps unless the feature clearly requires parity across them.

## Repository Layout

- `index.js`: main TUI app, data fetching, rendering, keybindings, notifications, and self-update flow
- `macos-menubar/Sources/NBAScoreMenubar/`: SwiftUI/AppKit menubar app
- `scripts/build-menubar-app.sh`: release bundle script for `dist/NBAScoreMenubar-<arch>.app`
- `README.md`: user-facing install, release, and feature documentation
- `dist/`: generated release artifacts only, ignored by git

## Working Rules

- Prefer small, local changes. `index.js` is intentionally monolithic today; avoid broad refactors unless requested.
- Preserve current refresh behavior unless the task explicitly changes it.
  - TUI scores refresh every 5 seconds.
  - TUI standings and transactions refresh every 60 seconds.
  - Menubar scoreboard refreshes every 20 seconds.
  - Menubar label rotation runs every 6 seconds.
- Do not commit generated artifacts from `dist/`, `.build/`, or `node_modules/`.
- Keep macOS deployment assumptions aligned with the current project settings: macOS 13+ and Swift 6.

## Build And Verification

Use the narrowest validation that matches the change:

- `npm start`: run the TUI
- `npm run menubar`: run the macOS menubar app
- `npm run menubar:build`: compile the Swift package
- `npm run menubar:bundle`: build the standalone `.app` bundle in `dist/`

There is no automated test suite in this repository right now. For code changes, prefer at least one of these:

- `npm run menubar:build` for menubar changes
- Manual TUI run for `index.js` changes
- Manual verification of any changed keyboard flow, refresh flow, or release link

## State And Persistence

- TUI player subscriptions are stored in `~/.nba-score-tui-subscriptions.json`.
- Menubar pinned games and settings are stored in `UserDefaults`.
- The TUI self-update flow uses `git fetch` and `git pull` against `origin/main`; keep that in mind before changing update behavior.

## Release And Versioning

When preparing a new release, update all relevant version references together:

- `package.json`
- `README.md` current release section and download links
- `scripts/build-menubar-app.sh` plist values such as `CFBundleShortVersionString` and `CFBundleVersion`

If you publish a GitHub release for the menubar app:

- Build the bundle with `npm run menubar:bundle`
- Zip `dist/NBAScoreMenubar-<arch>.app`
- Generate a SHA-256 checksum file for the zip
- Upload the zip and checksum as release assets

Be explicit when reusing an existing tag or release. Replacing assets for an existing version can make the published binary differ from the tagged source.

## Documentation Expectations

- Keep `README.md` in sync with user-visible behavior.
- If a menubar behavior changes, update the menubar feature list in `README.md`.
- If release assets or version numbers change, update the `Current Release` section in `README.md` in the same change.
