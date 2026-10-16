# Queued Token Refresh and Session Lifecycle

All HTTP requests pass through a custom `QueuedInterceptor` in Dio to prevent race conditions during refresh token rotation.

## Considered Options

- **Concurrent direct refresh**: Rejected: the backend revokes the previous refresh token immediately on use. Concurrent refresh calls using the same token would invalidate the user session.

## Consequences

- When an access token expires (`401 Unauthorized`), all outgoing requests are queued behind a single atomic refresh operation.
- If refresh succeeds, stored tokens in `flutter_secure_storage` are updated, and queued requests replay with the new bearer token.
- A queued request that failed with a token that has since been replaced retries with the current one instead of refreshing again, so a burst of `401`s spends the refresh token once.
- If the backend rejects the refresh token (`401` from `/auth/refresh`), the session is invalidated, and the network client gracefully falls back to the background guest token while notifying the authentication BLoC (`AuthInterceptor.sessionExpired` → `AuthSessionExpired`).
- If the refresh never gets an answer (offline, timeout, server error), the session is kept and the request's `401` is passed on; the next request tries again. Signing a member out because their phone lost signal would be worse than one failed request.
- The refresh call waits up to 60 seconds, not the usual 15. The backend revokes the old token the moment it answers, so a reply that arrives after the app gave up would leave the app holding a revoked token and the next refresh would end the session. A free host that has been idle takes up to a minute to wake.
- The launch check (`/auth/me`) likewise waits up to 45 seconds and tries three times when the server is silent (a timeout, or a `5xx`); a `401` is an answer and is not retried. Whatever it finds, it never clears the stored tokens: only a `401` from the refresh call does.
- A `401` from sign-in, registration or the token routes means bad credentials, not an expired token, and is never retried.
- When the signed-in member changes (sign-out, a session ending, someone else signing in), `MemberSessionScope` closes the blocs holding the last member's data and provides fresh ones, rather than clearing each bloc's state by hand: a late response for the old member then lands in a closed bloc and is dropped.
