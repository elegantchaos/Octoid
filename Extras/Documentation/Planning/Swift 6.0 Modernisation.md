# Swift 6.0 Modernisation Plan

This plan adapts the ActionStatus Swift 6 adoption approach to Octoid with a package-focused rollout.

## Status Snapshot

Current state:
- `Package.swift` is still on older toolchain metadata (`swift-tools-version:5.6`).
- Octoid relies on callback/session polling patterns inherited from `JSONSession`.
- Unit tests are mostly fixture-decoding tests and do not regularly validate against live GitHub API behavior.

Completed in this worktree slice:
- Added this plan and project agent guidance/docs refresh.
- Added opt-in integration tests for real GitHub API calls with Keychain-sourced credentials.

## Objectives

1. Move Octoid to Swift 6-compatible package configuration.
2. Introduce modern async API surfaces while preserving existing behavior.
3. Improve concurrency correctness (`Sendable`, explicit isolation/ownership).
4. Keep migration low-risk for ActionStatus and other consumers.

## Phase A: Baseline and Toolchain Alignment

Actions:
1. Update package metadata to current Swift tools/language expectations.
2. Confirm dependency compatibility matrix for Swift 6 mode.
3. Keep strict-concurrency rollout staged (warnings first, then clean build).

Exit criteria:
- Package builds cleanly with Swift 6-capable toolchain in compatibility mode.

## Phase B: Async API Introduction

Actions:
1. Add async request APIs for events and workflow runs in Octoid.
2. Keep existing callback/polling APIs available during migration.
3. Add clear error taxonomy for auth, transport, decoding, and server status failures.

Exit criteria:
- Async APIs available and covered by tests without regressing existing call sites.

## Phase C: Concurrency Hardening

Actions:
1. Audit models/protocols for `Sendable` conformance where appropriate.
2. Remove or isolate shared mutable state behind actors/value boundaries.
3. Document actor/thread ownership at API boundaries.

Exit criteria:
- Concurrency-related warnings are resolved or tracked with explicit rationale.

## Phase D: Strict Concurrency + Swift 6 Language Mode

Actions:
1. Enable strict concurrency checks for the Octoid target.
2. Resolve diagnostics in source and tests.
3. Switch fully to Swift 6 language mode.

Exit criteria:
- `swift test` passes under Swift 6 language mode and strict concurrency settings.

## Integration Test Strategy

- Keep live GitHub tests opt-in and non-secret-bearing in repo.
- Reuse the ActionStatus token entry from macOS Keychain (service defaults to `api.github.com`, account is the configured GitHub username).
- Skip integration tests automatically when Keychain credentials are not present.

## Validation Rule

For each migration slice:
1. Run `swift test`.
2. Run live integration tests only when credentials are configured locally.
3. Keep commits phase-scoped and reversible.
