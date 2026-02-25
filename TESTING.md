# Testing Octoid

Octoid includes:

- Unit tests for decoding and endpoint path behavior.
- Opt-in live integration tests against the GitHub API.

Run all tests with:

```bash
swift test
```

## Live Integration Tests

Live tests are opt-in and automatically skip when credentials are unavailable.

These tests call the real GitHub API, so they require valid credentials with read access to the repositories being polled.

Octoid reuses the same credential sources as ActionStatus on macOS:

- Keychain service defaults to `api.github.com`.
- Keychain account is the GitHub username from ActionStatus defaults (`GithubUser` in `com.elegantchaos.actionstatus`).

If credentials are missing, set them up with:

```bash
./Extras/Scripts/octoid-integration-signin
```

The script runs GitHub device-flow sign-in and stores credentials in your local keychain for subsequent test runs.

After that, run tests normally:

```bash
swift test
```
