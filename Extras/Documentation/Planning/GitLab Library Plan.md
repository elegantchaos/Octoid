# GitLab Library Plan

This plan defines how to build a GitLab-focused companion to Octoid that preserves Octoid's lightweight model-and-polling approach while adapting to GitLab API semantics.

## Status Snapshot

Current state:
- Octoid is tightly focused on GitHub endpoints and payloads (`events`, `actions/workflows`, `actions/runs`).
- Polling and processor patterns are reusable through `JSONSession`.
- Existing integration support and local sign-in tooling are GitHub-specific.

Target state:
- A GitLab-first library that exposes minimal project events + CI pipeline models and resource resolvers.
- Compatibility with both GitLab.com and self-managed instances.
- Clear non-goals to avoid trying to force GitHub workflow semantics onto GitLab.

## Objectives

1. Deliver a focused Swift package for GitLab API polling and model decoding.
2. Reuse Octoid transport/polling patterns where they fit.
3. Keep public APIs explicit and small, emphasizing pipelines over workflow files.
4. Add fixture + optional integration coverage without introducing secrets into the repo.

## Scope and Non-Goals

In scope:
- GitLab project events (`/projects/:id/events`).
- GitLab pipelines (`/projects/:id/pipelines`, `/latest`, `/:pipeline_id`).
- Optional pipeline jobs endpoint support when needed by ActionStatus.
- Error payload handling and unchanged-response handling where endpoint behavior supports it.

Out of scope:
- Full GitLab API coverage.
- Feature parity with every GitHub Actions workflow concept.
- Complex OAuth/device-flow tooling in the initial release.

## Proposed Package Shape

Primary types:
- `ProjectEvents`, `ProjectEvent`, and supporting actor/user/project models.
- `Pipelines`, `Pipeline`, and optional `PipelineJobs`, `PipelineJob`.
- `ProjectEventsResource`, `PipelinesResource`, `LatestPipelineResource`, `PipelineResource`.
- `GitLabMessage` and `GitLabMessageProcessor`.

Compatibility guidance:
- Prefer a sibling package (`GitLaboid`) over retrofitting Octoid internals.
- If shared abstractions emerge, extract only small, transport-level helpers later.

## Phase A: API Contract and Model Design

Actions:
1. Define minimal endpoint set and map to Swift public types.
2. Decide project identity strategy (`projectID` and/or URL-encoded namespace path).
3. Define status/conclusion mappings for pipelines/jobs to align with ActionStatus needs.

Exit criteria:
- Public API draft reviewed and frozen for MVP.
- JSON fixtures captured for events/pipelines success + error cases.

## Phase B: Core Implementation

Actions:
1. Implement resource resolvers for project events and pipelines.
2. Implement Codable models with strict optionality only where API values are genuinely nullable.
3. Implement GitLab error/message processor and logging channel.
4. Add pagination handling strategy (initially first page only unless consumer requires deep traversal).

Exit criteria:
- Core endpoints decode fixtures and run through polling pipeline.
- API paths and request construction are deterministic and tested.

## Phase C: Testing

Actions:
1. Add fixture-based unit tests for decoding and path construction.
2. Add optional integration tests guarded by environment/keychain credentials.
3. Validate behavior on at least one public GitLab.com project and one private project path.

Exit criteria:
- `swift test` passes locally.
- Integration tests skip cleanly when credentials are absent.

## Phase D: Consumer Integration (ActionStatus)

Actions:
1. Add adapter layer in ActionStatus to choose provider (`GitHub` vs `GitLab`).
2. Keep provider-specific differences explicit instead of over-generalizing early.
3. Verify end-to-end polling UI behavior using GitLab pipeline statuses.

Exit criteria:
- ActionStatus can poll and display GitLab pipeline state for configured repos/projects.
- No regression in existing GitHub behavior.

## Risks and Mitigations

Risk: Trying to mirror GitHub workflow abstractions directly.
Mitigation: Keep GitLab API design pipeline-centric.

Risk: Self-managed GitLab variability and version differences.
Mitigation: Support configurable base URL and document tested API assumptions.

Risk: Conditional request behavior differs by endpoint.
Mitigation: Treat unchanged/304 as optional optimization, not a core invariant.

Risk: Authentication setup friction for integration tests.
Mitigation: Use personal access token env/keychain lookup first; defer advanced auth flows.

## Validation Rule

For each implementation slice:
1. Run focused tests for changed files.
2. Run `swift test`.
3. Run optional integration tests only with local credentials configured.
4. Record any skipped validation and residual risk in commit/PR notes.
