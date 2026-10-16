# Frictionless Guest-First Onboarding

The app launches directly into public church content (Daily Quotes, Hymns, public Events) by acquiring an unauthenticated guest token behind the scenes, postponing mandatory login until personal or write actions occur.

## Considered Options

- **Mandatory login gate at startup**: Rejected: creates barrier to entry on Sunday mornings for church visitors who want to follow hymns or read the weekly bulletin.

## Consequences

- An unauthenticated visitor can immediately access devotional quotes, calendar events, and bilingual hymn books without registration.
- Any attempt to RSVP, submit a prayer request, give tithes/donations, or join a group triggers an authentication modal or navigation flow that smoothly returns the user to their desired action upon sign-in.
- The networking layer transparently manages token states, switching between the guest token and authenticated user token.
