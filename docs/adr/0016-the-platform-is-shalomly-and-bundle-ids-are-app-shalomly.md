# The platform is Shalomly, and Member App bundle IDs are `app.shalomly.<app-key>`

The platform, and the company behind it, is Shalomly, on the domain `shalomly.app`. "Noah Ark Solutions" was only ever a working name and is gone everywhere. Each church's Member App gets the bundle ID `app.shalomly.<app-key>`, one per church as ADR 0013 describes, in place of `com.noaharksolutions.<app-key>`. The Android `namespace` and `MainActivity` package stay fixed at `app.shalomly.memberapp` whichever church is built; only `applicationId` and `PRODUCT_BUNDLE_IDENTIFIER` change per church. Until the build script exists, the app target carries SBC's identity: `app.shalomly.sbc`, "SBC Church", `TENANT_KEY=sbc`.

The Dart package is `shalomly_app`, the repo folder `shalomly_app/`, and the on-device database file `shalomly_db`. The `macos/`, `linux/` and `windows/` folders were deleted, because the platform ships only on mobile and the web.

## Considered Options

- **Keep `com.noaharksolutions.<app-key>`.** Rejected: a bundle ID can't change after a church's first store release, and it should sit under a domain the platform owns. Nothing had been released, so this was the last free moment to change it.
- **Rename the user-facing brand only, and keep `noah_ark` in code identifiers.** Rejected: two names for one thing is the drift the glossary exists to stop.
- **Start a new project and copy the code across.** Rejected: it loses the git history and risks dropping ADRs and tickets.

## Consequences

- Supersedes ADR 0013's bundle ID, `com.noaharksolutions.<app-key>`.
- `shalomly.app` must be bought before the first store release.
- Renaming the on-device database dropped any locally cached data on test devices.
- `flutter create --platforms=macos .` (or `linux`, `windows`) brings a desktop platform back if it's ever wanted.
