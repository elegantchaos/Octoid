# Octoid Agent Instructions

## Project Specific Rules

- This repository is a SwiftPM library that provides minimal GitHub API models and polling/session helpers for ActionStatus.
- Preserve source compatibility for existing public types and behavior unless a breaking change is explicitly requested.
- Prefer focused changes in `Sources/Octoid/` and matching validation in `Tests/OctoidTests/`.
- Never commit secrets or tokens. Integration tests must use local secure credential sources (Keychain/environment) and skip when unavailable.
- Local guidance context: [Agent Guidance Notes](Extras/Documentation/Guidelines/Agent-Guidance-Notes.md), [Good Code](Extras/Documentation/Guidelines/Good%20Code.md).

## Standard Rules

### Methodology & Principles

- Prefer red/green TDD unless impractical; otherwise follow repository validation workflow and report gaps.
- Always write good code: correct, minimal, maintainable, tested, and aligned with current behavior/docs.
- Apply: KISS, YAGNI, DRY, make illegal states unrepresentable, dependency injection, composition over inheritance, command-query separation, Law of Demeter, structured concurrency, design by contract, and idempotency.
- Guidance: [Principles](Extras/Documentation/Guidelines/Principles.md), [Good Code](Extras/Documentation/Guidelines/Good%20Code.md), [Testing](Extras/Documentation/Guidelines/Testing.md).

### Scope and Change Strategy

- Prefer minimal, focused changes that solve the requested problem.
- Preserve existing architecture/style unless change is requested or clearly needed.
- Prefer fixing root causes over layered workarounds.
- Guidance: [Principles](Extras/Documentation/Guidelines/Principles.md).

### Core Workflow Expectations

1. Understand request boundaries.
2. Inspect relevant code/docs before editing.
3. Apply the smallest coherent change set.
4. Add/update tests for behavior changes where feasible.
5. Run relevant validation checks.
6. Report changes, validation status, and residual risks.
- Guidance: [Testing](Extras/Documentation/Guidelines/Testing.md), [Good Code](Extras/Documentation/Guidelines/Good%20Code.md).

### Engineering Rules

- Prioritize correctness, clarity, and maintainability.
- Keep interfaces explicit and intentionally small.
- Avoid hidden coupling and surprising side effects.
- Do not add dependencies without clear justification.
- Never expose or commit credentials/secrets.
- Guidance: [Principles](Extras/Documentation/Guidelines/Principles.md), [Good Code](Extras/Documentation/Guidelines/Good%20Code.md).

### Swift Guidance

- Follow project Swift/platform targets and repository conventions.
- Prefer one primary type per file and tight visibility.
- Prefer value semantics by default and `final` classes unless inheritance is intentional.
- Prefer structured concurrency (`async/await`, actors, task lifetimes) with explicit ownership of shared mutable state.
- Avoid force unwraps and `try!` outside truly unrecoverable/test-only paths.
- Prefer domain-specific errors and type-safe modeling of invalid states.
- Guidance: [Swift](Extras/Documentation/Guidelines/Swift.md), [Principles](Extras/Documentation/Guidelines/Principles.md).

### Code Comments

- Add compact documentation comments for each type, method/function, and member/property describing purpose.
- Comments should add intent and context, not restate symbol names.
- For the primary type in a source file, add a larger top-level documentation comment with design and implementation detail.
- Keep inline/block comments sparse and focused on subtle logic or non-obvious constraints.
- Guidance: [Good Code](Extras/Documentation/Guidelines/Good%20Code.md).

### Testing and Validation

- Add/update unit or integration tests for new behavior and bug fixes where feasible.
- Run focused checks first, then broader project checks (`swift test`, validation scripts when present).
- If validation cannot run, report exactly what was skipped and why.
- Always validate code changes before committing.
- Guidance: [Testing](Extras/Documentation/Guidelines/Testing.md).

### Research and Source Quality

- Prefer official sources for uncertain behavior: Apple docs, swift.org docs/book, Swift Evolution proposals, SwiftPM docs/repo, and dependency first-party docs.
- Use local docs under `Extras/Documentation/` as project authority.
- Treat blogs/forums as secondary and verify before relying on them.
- Guidance: [Trusted Sources](Extras/Documentation/Guidelines/Trusted%20Sources.md).

### Documentation

- Keep docs factual and aligned with current behavior.
- Update local docs when workflows, commands, or architecture change.
- Keep agent docs compact and move explanatory detail to human-facing docs.
- Guidance: [Good Code](Extras/Documentation/Guidelines/Good%20Code.md), [Agent Guidance Notes](Extras/Documentation/Guidelines/Agent-Guidance-Notes.md).

### GitHub Workflow Hygiene

- For `gh` commands with rich markdown, prefer `--body-file` over inline `--body`.
- Use deterministic, non-interactive commands and verify shell quoting/newline preservation.
- Keep PR descriptions factual, scoped to the actual diff, and include validation status.
- Guidance: [GitHub](Extras/Documentation/Guidelines/GitHub.md).

### Safety and Discipline

- Do not perform destructive actions without explicit approval.
- Avoid unrelated refactors during focused tasks.
- If unexpected workspace changes appear, pause and confirm direction.
- Guidance: [Good Code](Extras/Documentation/Guidelines/Good%20Code.md), [Principles](Extras/Documentation/Guidelines/Principles.md).

---

Regenerate this file regularly using `~/.local/share/agents/REFRESH.md`, `~/.local/share/agents/COMMON.md`, and relevant modules under `~/.local/share/agents/instructions/`.
