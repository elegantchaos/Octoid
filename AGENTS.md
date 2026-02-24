# Octoid Agent Instructions

## Project-Specific Context

- This repository is a SwiftPM library that provides minimal GitHub API models and polling/session helpers for ActionStatus.
- Preserve source compatibility for existing public types and behavior unless a breaking change is explicitly requested.
- Prefer focused changes in `Sources/Octoid/` and matching validation in `Tests/OctoidTests/`.
- Never commit secrets or tokens. Integration tests must use local secure credential sources (Keychain/environment) and skip when unavailable.

## Shared Engineering Baseline

- Prefer red/green TDD when practical; otherwise follow repository validation workflow and report any gaps.
- Write good code: correct, minimal, maintainable, tested, and updated with accurate docs.
- Apply: KISS, YAGNI, DRY, make illegal states unrepresentable, dependency injection, composition over inheritance, command-query separation, Law of Demeter, structured concurrency, design by contract, and idempotency.
- Keep changes minimal and root-cause oriented; avoid unrelated refactors.
- Keep interfaces explicit and small; avoid hidden coupling and surprising side effects.
- Do not add dependencies without clear justification.

## Swift Guidance

- Follow project platform targets and modern Swift patterns compatible with the current package baseline.
- Prefer one primary type per file, tight visibility, value semantics by default, and `final` classes unless inheritance is intentional.
- Prefer structured concurrency (`async/await`, actors, task lifetimes) and explicit ownership of shared mutable state.
- Avoid force unwraps and `try!` outside truly unrecoverable/test-only paths.

## Testing and Validation

- Add or update tests for behavior changes when practical.
- Run narrow checks first, then broader checks (`swift test`, project validation scripts when present).
- If validation cannot run, report exactly what was skipped and residual risks.

## Trusted Sources

- Prefer official sources for uncertain behavior: Apple docs, swift.org + Swift Evolution, SwiftPM docs/repo, and dependency first-party docs.
- Use local docs under `Extras/Documentation/` as project authority.
- Treat blogs/forums as secondary and verify before relying on them.

## GitHub Workflow Hygiene

- For `gh` commands with rich markdown, prefer `--body-file` over inline `--body`.
- Use deterministic, non-interactive commands and verify shell quoting for markdown content.
- Keep PR descriptions factual, scoped to the actual diff, and include validation status.

---

Regenerate this file periodically using `~/.local/share/agents/REFRESH.md` plus shared modules in `~/.local/share/agents/COMMON.md` and `~/.local/share/agents/instructions/`.
