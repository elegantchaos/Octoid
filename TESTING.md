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

They read the same token entry that ActionStatus uses on macOS:

- Keychain service defaults to `api.github.com`.
- Keychain account is the GitHub username from ActionStatus defaults (`GithubUser` in `com.elegantchaos.actionstatus`).

### Environment Overrides

- `OCTOID_GITHUB_USER`: override username if ActionStatus defaults are unavailable.
- `OCTOID_GITHUB_SERVER`: GitHub API host (default: `api.github.com`).
- `OCTOID_TEST_OWNER`: repository owner used by live tests (default: `elegantchaos`).
- `OCTOID_TEST_REPO`: repository name for repository-scoped tests (default: `Octoid`).
- `OCTOID_TEST_WORKFLOW`: legacy workflow-name override retained for compatibility.

### Device Flow Sign-In (Optional)

If a token is missing, tests can optionally perform GitHub device-flow sign-in:

- `OCTOID_GITHUB_DEVICE_SIGNIN=1`
- `OCTOID_GITHUB_CLIENT_ID=<client-id>`

When enabled, tests print a verification URL and user code, then store retrieved credentials in the local keychain for reuse.
