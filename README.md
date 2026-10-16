# Shalomly — church member app (Flutter)

The member app for the Shalomly platform: one Flutter codebase that
every church ships as its own branded app. Each church gets its own build —
its own name, store listing, icon, and app key — and every build talks to the
same shared backend, the FastAPI project in `shalomly-backend`.

A member opens their church's app and sees that church's content, in that
church's colors, before signing in. Signing in unlocks the personal parts:
RSVPs, prayer requests, giving.

The domain language (Member, Pastor, Prayer Chain, Theme, …) is defined in
[`GLOSSARY.md`](GLOSSARY.md), a copy of the backend's `CONTEXT.md`.

---

## What works today

The app's screens are further along than the backend, so several of them call
endpoints that don't exist yet and fall back to built-in sample data. If a
screen shows something you never created, that's why.

| Feature | Backend calls | State |
|---|---|---|
| Sign in, register, stay signed in | `/auth/login`, `/auth/member/register`, `/auth/me`, `/auth/refresh`, `/auth/logout` | **Works**; an expired access token is refreshed quietly, waiting up to 60 seconds for a sleeping server; the launch check waits up to 45 seconds and tries three times, and keeps the stored tokens if the server stays silent (see [Tokens](#how-a-churchs-app-works)); sanctuary brand hero header, curved bottom surface card, Newsreader greeting, and responsive member registration |
| Theme (church colors) | `GET /theme` | **Works** — see [Theme](#theme) |
| Home (sanctuary feed) | `GET /daily-quotes`, `GET /sermons`, `GET /events?type=worship`, `GET /events?type=notice` | **Works**; warm Newsreader/Inter typography pairing, a worship card showing the next `worship` Event (a service in progress still shows; Order of Service opens that Event when it has text or a PDF; with no worship Event it says "Worship With Us" and leads to the calendar), up to three Notices from this week, shortcuts to Sermons and Small Groups (and the Church Workspace for church leaders only) that wrap instead of scrolling sideways, 3-Card Devotional layout (Today's Scripture with Philippians 4:6-7 fallback, Pastoral Reflection, Prayer for Today), Fellowship Highlights (`/prayer`, `/events`), and Featured Sermon spotlight with YouTube playback |
| Sermons | `GET /sermons` | **Works**; sanctuary media archive with search, preacher filter chips, 16:9 video preview cards, and bottom sheet sermon notes |
| Events and RSVP | `GET /events` (with `type`, `starts_after`, `starts_before`), `GET`/`PATCH`/`DELETE /events/{id}`, `POST /events`, `PUT`/`DELETE /events/{id}/rsvp`, `POST /groups/{id}/posts` | **Works**; every Event has a type (worship, fellowship, conference, Bible study, prayer meeting, outreach, celebration, notice, other), is church-wide, and shows on a calendar at the top of the Events tab (a week that opens up to the whole month, with a dot on each day that has an Event; tapping a day lists that day's Events) and in a list under it, grouped by date and showing its type; filters All Upcoming / This Week / Past Events are cut at the start of today; opens an Event detail screen (`/events/:id`) with text, a PDF link, an image, RSVP, and Edit / Cancel / Delete for Pastors, Admins and the Youth Leader who posted it; the form needs a title, type, start date and start time, and can repeat weekly for a month (four separate Events) and share the Event with Groups; PDF and image are pasted links until uploads exist; no sample events |
| Giving | `GET /funds`, `GET`/`POST /donations` | **Works**; sanctuary hero and fund cards with serif balances; backend payment methods (`manual_cash`, `manual_cheque`, `bank_transfer`); manual gift entry restricted to finance roles (`isFinanceManager`); failed gifts never show a fake receipt and preserve form inputs |
| Prayer | `GET`/`POST /prayers/chain`, `GET`/`POST /prayers/private`, `POST`/`DELETE /prayers/{id}/intercessions`, `GET /prayers/private/{id}/pastoral-prayers` | **Works**; real prayer routes for Prayer Chain and Private Prayer Requests; handles unassigned pastors; optimistic intercession toggle with failure rollback; sanctuary cards with member avatar, prayer body, and "Intercede" / "Interceding" state |
| Hymns | `GET /hymns` | **No backend route yet**; sanctuary bilingual songbook with serif typography, dual-column and single-language lyric viewer, search, and bookmarking |
| Groups | `GET /groups`, `GET /groups/{id}`, `POST /groups`, `POST /groups/{id}/join`, `POST /groups/{id}/leave`, `GET`/`POST`/`DELETE /groups/{id}/members`, `POST`/`DELETE /groups/{id}/leaders/{user_id}`, `GET`/`POST`/`PATCH`/`DELETE /groups/{id}/posts` | **Works**; real backend routes with no sample data; signed-out visitors see sign-in prompt; open/closed group status; join/leave call `POST`; dedicated Group view (`/groups/:id`) with Group Posts (a post can show an Event, with its current details), member management, and leader appointments |
| Church Workspace (`/admin`, `/workspace`) | — | **Mockup**: hardcoded numbers and rows; "Reconcile" only shows a message |
| Watch glance (`/watch/glance`) | — | A black two-page route showing the first quote and event; there is no watchOS or Wear OS target |

---

## Running it

You need **Flutter 3.47.5** (pinned in [`.fvmrc`](.fvmrc); `fvm use` picks it
up, or use a matching `flutter`) and the backend running locally.

**1. Get the app an API client from the backend.** A church app proves which
app it is with a `client_id` / `client_secret` and trades them for a guest
token; without one, nothing loads before sign-in. In the backend project:

```bash
./venv/bin/python -m scripts.generate_api_client create --tenant-key sbc --name "SBC Church app (dev)"
```

The secret is printed once — copy both values. A secret inside a mobile app is
not really secret (anyone can pull it from the bundle); the backend treats it
as an app identity it can throttle and rotate, not as access control.

**2. Put your settings in `.env` and generate them into the app.**

```bash
cp .env.example .env              # git-ignored; fill in CLIENT_ID and CLIENT_SECRET
dart run build_runner build -d    # writes lib/src/core/config/env.g.dart (git-ignored)
```

Run `build_runner` again after every edit to `.env`; until you do, the app
keeps the old values. `--dart-define` no longer changes any setting.

**3. Run.**

```bash
flutter run -d chrome
flutter run -d "iPhone 18 Pro"
```

### Settings

Every setting is fixed when the app is built: [envied](https://pub.dev/packages/envied)
reads `.env` during `build_runner` and generates `Env` in
`lib/src/core/config/env.g.dart`, with `CLIENT_ID` and `CLIENT_SECRET`
obfuscated. A missing key, or a missing `.env`, takes the default below.

| Key | What it is | Default |
|---|---|---|
| `TENANT_KEY` | The church's app key; picks which church this build is | `sbc` (on the web: the subdomain, e.g. `sbc.shalomly.app` → `sbc`) |
| `CHURCH_NAME` | Name shown in the app and window title | `SBC Church` |
| `API_BASE_URL` | Backend address, including `/api/v1` | `http://127.0.0.1:8000/api/v1` |
| `CLIENT_ID` | The app's API client id | empty — guest content won't load |
| `CLIENT_SECRET` | The app's API client secret | empty |

### Gotchas talking to a local backend

- **A real phone can't reach `127.0.0.1`** — that's the phone itself. Use your
  Mac's Wi-Fi address (`http://192.168.x.x:8000/api/v1`), run uvicorn with
  `--host 0.0.0.0`, and add that address to the backend's `TRUSTED_HOSTS`,
  which only allows `localhost` and `127.0.0.1` by default and answers anything
  else with a 400. The Android emulator reaches your Mac at `10.0.2.2`.
- **The web build needs CORS.** The backend allows no browser origins by
  default; set its `CORS_ORIGINS` to the address Chrome runs the app on.
- **The web build has no local database.** Drift isn't configured for the web
  (`driftDatabase` gets no `web:` options), so nothing is cached there.

---

## How a church's app works

**At startup** ([`lib/main.dart`](lib/main.dart)), in order:

1. Read the build settings (`AppConfig`).
2. Open secure token storage and the local Drift database.
3. Create the HTTP client.
4. Load the church's Theme (below). The native splash screen stays up meanwhile.
5. Start the app. Every screen's data starts loading at once.

**Tokens** ([`auth_interceptor.dart`](lib/src/core/network/auth_interceptor.dart)):
every request carries the church's `X-Tenant-Key` and the signed-in member's
token, or the guest token when nobody is signed in. On a `401` the app tries,
in turn: refreshing the member's session (`POST /auth/refresh`), then trading
the client credentials for a new guest token. Then it replays the request once.
A burst of `401`s spends the refresh token once; requests that failed with the
old token retry with the new one. Only the backend rejecting the refresh token
signs the member out (and `AuthBloc` follows); being offline or a server error
keeps the session. The refresh call waits up to 60 seconds, because the backend
revokes the old token the moment it answers and a free host can take that long
to wake; the launch check (`/auth/me`) waits up to 45 seconds and tries three
times, and never clears the tokens (ADR 0010). A `401` from sign-in,
registration or the token routes themselves is never retried. Tokens live in the platform keychain/keystore
(`flutter_secure_storage`).

**Whose data** ([`member_session_scope.dart`](lib/src/features/auth/presentation/widgets/member_session_scope.dart)):
the blocs holding a member's own data (prayer, giving, Groups, Events with
their RSVPs) are replaced with fresh ones and reloaded whenever a different
member, or nobody, is signed in, so a shared phone never shows the last
member's Private Prayer Requests or giving.

**Navigation** ([`app_router.dart`](lib/src/core/routing/app_router.dart)):
five tabs (Home, Hymns, Events, Prayer, Giving) — a bottom bar on phones, a
side rail from 720px wide — plus full-screen routes for an Event (`/events/:id`), sermons,
groups, sign-in, and the Workspace. There is no route guard; screens check
roles themselves.

---

## Adding a church

Each church gets its own Member App: its own name, icon, store listing and App Key, built from this one codebase. The full process, the decisions behind it and what to collect from the church are in [`/Users/peter/projects/SHALOMLY_PLATFORM.md`](/Users/peter/projects/SHALOMLY_PLATFORM.md), outside both repos. Most steps aren't built yet; each one names its ticket.

1. **Create the church in the backend.** Not built: backend ticket `churches/01` adds `python -m scripts.provision_church create`. It makes the church, its first Pastor and the app's API client, and prints the client ID and secret once. Keep them in the password manager. Until then, `POST /auth/register` makes the church and its first Pastor, and `scripts.generate_api_client create --tenant-key <app-key>` makes the client.
2. **Set its colors and logo.** Colors work today: as a Super Admin, `PUT /theme?tenant_id=<id>`. Logo upload is backend ticket `theme/07`.
3. **Add its folder here.** Not built: ticket `member-apps/01` adds `tool/new_church.sh <app-key>`, which creates `churches/<app-key>/`. Fill in `church.json`, add the logo, and put the client ID and secret in its git-ignored `.env`.
4. **Build.** Not built: tickets `member-apps/01` and `member-apps/02` add `tool/build_member_app.sh <app-key> <ios|android>`. It applies the bundle ID (`app.shalomly.<app-key>`; app ADR 0016), name, icon and splash screen, then builds. Build from a clean checkout. Until then, set the church in `.env`, run `dart run build_runner build -d`, then `flutter run`; that runs one church at a time under the app target's own bundle ID, `app.shalomly.sbc`, and name, "SBC Church".
5. **Submit to the stores** under the church's own Apple and Google accounts, with its privacy policy URL (backend ticket `stores/01`). Every church ships the same version at the same time.

The web app is one build for every church, chosen by subdomain (`<app-key>.localhost` during development): ticket `web/01`.

---

## Theme

A church's colors come from the backend at `GET /theme`, so a church can
change them without a new app release.

- **Twelve colors, named by job**, in a light and a dark set: `primary`,
  `secondary`, `success`, `warning`, `error`, `info`, `background`, `surface`,
  `raised`, `text`, `textMuted`, `border`. The backend fills in any the church
  hasn't chosen from its Default Theme, so the app always gets all twelve.
- **Text on a colored fill is black or white**, whichever contrasts better
  (`ChurchColors.onColor`), so no church can make a button unreadable.
- **Loading:** the first launch waits on the splash screen for up to about two
  seconds for the Theme, then falls back to the Default Theme baked into the
  app. The Theme is kept on the device, so later launches open in it
  immediately and refresh it quietly for the next launch. A change on the
  server shows up the next time the app opens.
- **In a widget**, use `context.churchColors.primary` and friends, never a
  hardcoded color, so the screen follows the church and light/dark mode.
- **The baked Default Theme** in
  [`church_colors.dart`](lib/src/core/theme/church_colors.dart) must match the
  backend's `app/models/theme.py`. Change both together.

The app's icon, store name, and splash screen are not part of the Theme: they
belong to each church's build.

---

## Project layout

```
lib/
├── main.dart                     startup (see above)
└── src/
    ├── app.dart                  MaterialApp, repositories, blocs
    ├── core/
    │   ├── config/               AppConfig: build settings
    │   ├── database/             Drift tables (app_database.dart) and generated code
    │   ├── localization/         English / Nepali text helper
    │   ├── network/              Dio client, auth interceptor, endpoint paths
    │   ├── routing/              GoRouter routes, tab shell
    │   ├── security/             token storage
    │   └── theme/                ChurchColors, AppTheme, ThemeRepository
    └── features/                 one folder per feature: data/ (repository),
                                  domain/ (models), presentation/ (bloc, screens)
```

State is managed with `flutter_bloc`; each feature has a repository that calls
the backend and a bloc the screens listen to. A bloc is three files (`x_bloc.dart`,
`x_event.dart`, `x_state.dart`) with one `Equatable` state and an enum for its
status; see [`AGENTS.md`](AGENTS.md). `event_detail_bloc`, `calendar_events_bloc`
and `home_events_bloc` follow it; older blocs are moved as they are changed. Internal imports always use the
`package:shalomly_app/...` form.

**Local database** ([`app_database.dart`](lib/src/core/database/app_database.dart),
schema version 2): `CachedThemes` (the kept Theme), `CachedHymns`,
`CachedDailyQuotes`, `CachedEvents`, `CachedBulletins`, and `CachedServiceTimes`,
which nothing uses any more (Bulletins and Service Times are Events now; the
two tables go in the next schema version). After changing a table, regenerate the code:

```bash
dart run build_runner build -d
```

---

## Checks

```bash
flutter analyze    # must stay clean
flutter test       # everything under test/: models, blocs and filters for Events, the
                   # sign-in check and token refresh, routes, and the widget tests in
                   # test/widget_test.dart (the Home and auth screens)
```

---

## Weekly report email

Every Friday at 12:30 UTC, [`weekly-report.yml`](.github/workflows/weekly-report.yml)
emails a summary of the past week's commits (on every branch) and pushes,
written by Gemini's free API, followed by the full commit list. If Gemini fails,
the email still goes out with the commit list. Everything it uses is free.
The commit messages go to Google, and on the free tier Google may use them to
improve its products.

Setup, once. Under **Settings → Secrets and variables → Actions**, add these
repository secrets:

| Secret | Value |
|---|---|
| `GEMINI_API_KEY` | a key from [Google AI Studio](https://aistudio.google.com/apikey) |
| `SMTP_USERNAME` | the Gmail address that sends the report |
| `SMTP_PASSWORD` | a Gmail [App Password](https://myaccount.google.com/apppasswords) (needs 2-Step Verification), not the account password |
| `REPORT_TO` | optional: recipients, comma-separated; defaults to `SMTP_USERNAME` |

To pick a model other than `gemini-flash-latest`, set a repository *variable*
`GEMINI_MODEL`. To send a report now, open **Actions → Weekly report → Run
workflow**. To preview it locally without sending anything, run
`python3 .github/scripts/weekly_report.py --dry-run`, which writes
`weekly-report.html`. To change the day or time, edit the `cron` line.

---

## Known gaps

Beyond the feature table above:

- Prayer, events, and giving send requests the backend doesn't understand
  (wrong paths, parameter names, or values) — see the table.
- **The giving screen invents a "completed" receipt when a gift fails to send.**
  A member can believe they gave when nothing was recorded.
- Sample-data fallbacks hide real failures. Once each backend route exists, the
  fallback should go.
- The daily-quote cache has no church column, so two church builds on one
  device would share it.
- No route guards: the Workspace is reachable by URL, and only the screen
  checks the role.
- Launching offline shows a signed-in member as a guest: the app keeps their
  tokens but has no cached profile to show until `/auth/me` answers. At launch
  it now waits up to 45 seconds and tries three times before giving up (a
  sleeping free-tier server takes up to a minute to wake), and it never clears
  the tokens for a server that doesn't answer; only a `401` from the refresh
  call ends the session.

---

## Decisions and tickets

- [`docs/adr/`](docs/adr/) — decisions specific to this app: prayer
  confidentiality (0001–0003), feature-first structure with BLoC and Drift
  (0004), baked and dynamic church selection (0005), guest-first onboarding
  (0006), GoRouter shell routing (0008), bilingual hymns (0009), queued token
  refresh (0010), and the church Theme from the backend (0011, replacing the
  palette engine in 0007).
- Tickets for this app go in `.scratch/` here; tickets spanning both projects
  live in the backend repo under `.scratch/`.
- AI agents follow [`AGENTS.md`](AGENTS.md). To let one see the backend too,
  add its folder to the session, e.g.
  `agy --add-dir /Users/peter/projects/shalomly-backend`.
