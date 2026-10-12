# The church logo comes from the Theme

A church's logo is part of its Theme: `GET /theme` returns a light logo and an optional dark one as paths on the backend, and the app shows them wherever it shows the church's mark. The web Member App serves every church from one build, so it can't bake a logo in. Mobile reads the same server logo, so a church changes its logo with one upload. Each mobile build also bakes the church's logo in as a first-launch fallback, the same pattern as the baked Default Theme. The web shows the church's name in serif type until a logo is uploaded.

## Consequences

- This partly supersedes ADR 0011, which said only colors are runtime. The icon, store name and splash screen still belong to the build.
- Logo paths are relative to the backend and resolved against `API_BASE_URL`, because an address saved as `127.0.0.1` would break on a real phone.
- Backend side: its ADR 0007. Process: `/Users/peter/projects/SHALOMLY_PLATFORM.md`.
