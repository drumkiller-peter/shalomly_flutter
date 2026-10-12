# Agent Instructions

These instructions are for every AI agent working in this repo, and this file is the only copy: Antigravity (`agy`) reads `AGENTS.md` directly, Claude Code reaches it through `CLAUDE.md` (which imports it), and Gemini CLI through `.gemini/settings.json`. Don't add a `GEMINI.md`: Antigravity loads it in place of this file.

## Before you start

1. **Learn the language.** Read `GLOSSARY.md` and use its terms, never the ones it lists under _Avoid_.
2. **Know what's real.** Read the README, especially "What works today": several screens show built-in sample data because their backend route doesn't exist yet.
3. **Respect past decisions.** Read the ADRs in `docs/adr/` that touch what you're changing. If your change contradicts one, say so instead of silently overriding it.
4. **See what changed recently.** Run `git log --oneline -20`, and `git show <commit>` for anything relevant.
5. **Find the requirement.** This app's tickets are in `.scratch/<feature>/issues/` in this repo; a ticket's checkboxes are its acceptance criteria. Tickets spanning both projects live in the backend, `/Users/peter/projects/shalomly-backend/.scratch/`. You can read that folder only if your session includes it (for `agy`: `agy --add-dir /Users/peter/projects/shalomly-backend`); if you can't, ask the user instead of guessing.

## Keep the docs current

Updating the docs is part of every change, not a follow-up. Before you finish:

- A feature starts or stops working, loses its sample-data fallback, or calls a different endpoint: update the README's "What works today" table.
- A new build setting, command, or setup step: update the README.
- A decision that is hard to reverse, would surprise a future reader, and was a real trade-off: add an ADR to `docs/adr/` with the next number, and mark any ADR it replaces as superseded.
- A new or changed domain term: change the backend's `CONTEXT.md`, then copy it over `GLOSSARY.md`.
- A new rule every agent should follow: add it to this file.
- Tick the ticket's checkboxes and update its `Status:` line.
- In your final message, list which docs you updated, or say none needed it.

## Agent skills

### Issue tracker

Issues and specs live as local markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five-role triage vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context repository layout (`GLOSSARY.md` + `docs/adr/`). See `docs/agents/domain.md`.

## Working in this codebase

- **Read the README's "What works today" table first.** Several features call backend routes that don't exist yet and fall back to built-in sample data; don't mistake that data for real responses.
- **Colors:** always `context.churchColors.<job>` (see `lib/src/core/theme/church_colors.dart`), never a hardcoded color, so screens follow the church's Theme and light/dark mode. Text or icons on a filled color use `onPrimary`, `onError`, … or `ChurchColors.onColor(fill)`, never a fixed `Colors.white`. The baked Default Theme there must match the backend's `app/models/theme.py`; change both together.
- **Checks:** `flutter analyze` must stay clean. After changing a Drift table in `app_database.dart`, bump `schemaVersion`, add the step to `migration`, and run `dart run build_runner build -d`.
- **Networking:** inside `AuthInterceptor`, token requests and replays go through its private `_tokenDio`, never the intercepted client, which would deadlock on failure.
- **Build settings** (`TENANT_KEY`, `API_BASE_URL`, `CHURCH_NAME`, `CLIENT_ID`, `CLIENT_SECRET`) come from the git-ignored `.env` (copy `.env.example`), which envied generates into the git-ignored `lib/src/core/config/env.g.dart`; read them through `AppConfig`, never `String.fromEnvironment`. After editing `.env`, run `dart run build_runner build -d`. Never commit a client secret, `.env` or `env.g.dart`.
- **The backend** is the FastAPI project at `/Users/peter/projects/shalomly-backend`. `GLOSSARY.md` here is a copy of its `CONTEXT.md`: change terms there, then copy the file over, never edit `GLOSSARY.md` on its own. Tickets spanning both projects live in the backend's `.scratch/`.
- **Platform decisions** (adding a church, Member App builds, the Theme logo, the web app, store accounts) are in `/Users/peter/projects/SHALOMLY_PLATFORM.md`, outside both repos. Read it before working on any of those; for `agy`, reach it with `--add-dir /Users/peter/projects`.
- **The backend is the source of truth for design and terms.** Screens, copy and names follow the backend's `CONTEXT.md`, its ADRs and its tickets. Do not design from `church-saas-ui-direction.html` in the backend; it is an early-phase mock and is superseded.
- **UI copy uses glossary terms.** Use "Prayer Chain", not "prayer wall"; "Intercession" (button labels "Intercede" / "Interceding"), not "amen" or "like"; "Group", not "ministry" or "section"; "Church Workspace", not "dashboard" or "admin panel"; "Sermon", not "video"; "Preacher", not "speaker".
- **Names match the feature.** A screen's file and class take the name of the tab or feature it serves (e.g. the Home tab is `home_screen.dart` / `HomeScreen`), and feature folders follow the glossary term (e.g. `workspace/`, not `admin/`).
- **Sanctuary styling:** card surfaces use `AppTheme.sanctuaryCard(colors)`; a screen's one filled hero uses `AppTheme.heroGradient(colors)` with `onPrimary` text; titles and section headers use `AppTheme.serif`; eyebrow badges use `AppTheme.trackingBadge`. Typography stays Newsreader + Inter (ADR 0012). No `Colors.*` literals other than `Colors.transparent`.
