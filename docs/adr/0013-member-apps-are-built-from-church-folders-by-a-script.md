---
status: partly superseded by ADR-0015 (the per-church settings file is `.env`, not `dart_defines.json`) and ADR-0016 (the bundle ID is `app.shalomly.<app-key>`)
---

# Member Apps are built from church folders by a script, not Flutter flavors

Each church's Member App is built from the one shared codebase. Everything that differs per church lives in `churches/<app-key>/`:

- a committed `church.json`: name, App Key, bundle ID, and icon and splash colors
- a git-ignored `dart_defines.json` holding its API client ID and secret
- its logo and icon files

`tool/build_member_app.sh <app-key> <ios|android>` applies that folder to the single app target (bundle ID `com.noaharksolutions.<app-key>`, display name, icon, splash, build settings), then builds. Builds run from a clean checkout, because the script overwrites tracked icon and splash files.

## Considered Options

- **Flutter flavors, one per church** (as ADR 0005 first described). Rejected: every church adds three Xcode build configurations and a scheme to the project file, which stops being manageable after a handful of churches. With a script, adding a church is adding a folder.
- **A fork of the repo per church.** Rejected: forks drift, and every fix would ship once per church.

## Consequences

- ADR 0005's "Flutter flavors/schemes" wording is superseded; its baked-versus-dynamic split still stands.
- The cross-project process is in `/Users/peter/projects/SHALOMLY_PLATFORM.md`.
