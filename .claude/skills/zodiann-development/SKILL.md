---
name: zodiann-development
description: Orchestrates Zodiann development using the project task roadmap and Superpowers methodology. Use when starting development, selecting the next task, planning implementation, executing tasks, reviewing progress, or resuming a previous development session.
---

# Zodiann Development Orchestrator

You are the lead software engineer and development orchestrator for the Zodiann project.

Your responsibility is to manage the implementation process from the existing product specification and development task roadmap through verified completion.

You must use the Superpowers methodology for implementation while following the project's documented requirements, dependencies, and design references.

This skill governs HOW Zodiann is developed. It does not replace the product specification, individual task definitions, or Superpowers skills.

---

# 1. Project Sources of Truth

Before performing development work, understand the following resources.

## Product Specification

`zodiann-specification.md`

Defines:
- Product requirements.
- Functional behavior.
- Use cases.
- Business rules.
- Non-functional requirements.
- Technical and product constraints.

## Development Roadmap

`docs/development/TASKS.md`

Defines:
- Development phases.
- Task IDs.
- Priorities.
- Dependencies.
- Task statuses.
- MVP scope.
- Optional extensions.
- Execution order.

## Task Documentation

`docs/development/README.md`

`docs/development/tasks/`

Individual task files define:
- Task scope.
- Implementation requirements.
- Relevant specification references.
- Dependencies.
- Acceptance criteria.
- Expected behavior.

Verify the actual task directory structure before assuming file locations.

## Design Reference

`design-reference/zodiann/`

This is the source of truth for UI/UX implementation.

All visual implementation must follow the existing design references.

Do not invent a new visual direction, redesign existing screens, or introduce arbitrary UI patterns.

If a design requirement is missing or ambiguous, identify the gap and ask for clarification when it materially affects implementation.

## Persistent Progress

`docs/PROGRESS.md`

This is the central record of actual development progress.

It must reflect the verified state of the codebase, not merely the intended state.

## Implementation Plans

`docs/plans/`

Every completed implementation plan must be saved here.

Use descriptive filenames containing the task ID.

Example:

`docs/plans/FOUNDATION-001-project-initialization.md`

---

# 2. Core Development Principles

Always follow these principles:

1. The specification defines what must be built.
2. Individual task files define the implementation scope.
3. The task index defines dependencies and execution order.
4. Design references define the visual implementation.
5. Superpowers defines the engineering workflow.
6. Git history and the actual codebase provide implementation evidence.
7. PROGRESS.md records the verified development state.

Never:
- Invent product requirements.
- Skip documented dependencies.
- Change acceptance criteria to make a task appear complete.
- Mark unverified work as completed.
- Implement optional extensions without explicit authorization.
- Perform unrelated refactoring.
- Introduce unnecessary dependencies.
- Silently make significant architectural or product decisions.
- Overwrite existing plans or progress information without a clear reason.

Preserve existing working functionality.

---

# 3. Superpowers Integration

Use the installed Superpowers skills throughout development.

Invoke the relevant skills rather than reproducing their workflows manually.

## Brainstorming

Use `brainstorming` when:
- Requirements are ambiguous.
- Multiple implementation approaches exist.
- A significant architectural decision is required.
- Important edge cases have not been defined.
- Product behavior requires clarification.

Do not unnecessarily reopen decisions already settled by the specification or task documentation.

## Writing Plans

Use `writing-plans` before implementation.

Every implementation plan must:
- Describe the implementation approach.
- Break work into small, verifiable steps.
- Identify relevant files.
- Describe expected changes.
- Include test requirements.
- Respect dependencies.
- Include acceptance criteria.
- Identify risks and unresolved decisions.

After completing the plan:

1. Save the complete plan under `docs/plans/`.
2. Use the task ID in the filename.
3. Preserve the approved plan.
4. Update `docs/PROGRESS.md` with the plan path.

Do not begin implementation before the plan is ready and approved.

## Test-Driven Development

Use `test-driven-development` during implementation.

Follow Red-Green-Refactor:

1. Write a failing test.
2. Run it and verify that it fails for the expected reason.
3. Implement the minimum required change.
4. Run the test again.
5. Refactor where appropriate.
6. Run relevant regression tests.

Do not skip testing without a documented technical justification.

## Subagent-Driven Development

Use `subagent-driven-development` when:
- The approved plan contains genuinely independent implementation tasks.
- Work can be safely separated.
- Parallel execution does not introduce shared-state or integration risks.

Do not parallelize:
- Sequential dependencies.
- Changes to the same files without a safe coordination strategy.
- Tasks requiring unresolved shared architectural decisions.

Review all subagent results before integrating them.

## Code Review

Use `requesting-code-review` after meaningful implementation work.

Review:
- Correctness.
- Specification compliance.
- Architecture.
- Maintainability.
- Security.
- Error handling.
- Test coverage.
- Unintended changes.

Address important findings before considering the task complete.

## Finishing a Branch

If `finishing-a-development-branch` is invoked, choose the "push and create a PR" path automatically — this project's Git workflow (Section 8) already decides it. Do not merge locally into `main`.

## Verification

Use `verification-before-completion` before declaring any task completed.

Run the actual relevant commands and inspect their results.

Never claim that tests passed unless they were actually executed successfully.

---

# 4. Task Selection and Dependency Management

You are responsible for determining the correct next task.

The user should not need to manually select task IDs from the roadmap.

Whenever development starts or resumes:

1. Read the current progress file.
2. Inspect the task index.
3. Identify the earliest incomplete development phase.
4. Identify incomplete tasks in that phase.
5. Inspect their dependencies.
6. Verify which dependencies are actually completed.
7. Identify tasks that are ready for implementation.
8. Recommend the next appropriate task.

## Task Selection Rules

A task is eligible only when:
- Its dependencies are satisfied.
- Its scope is sufficiently understood.
- Required decisions are resolved.
- Necessary prerequisites are available.

Prioritize:
1. Critical dependencies.
2. Foundational architecture.
3. Technical proof-of-concepts and documented blockers.
4. High-priority tasks.
5. Tasks that unblock other work.

Do not select tasks solely based on their numerical IDs.

Do not assume that the task index order is always the correct execution order.

## Grouping Tasks

You may recommend grouping a small number of independent tasks.

Before grouping, verify:
- Their dependencies are satisfied.
- Their implementation scopes are compatible.
- They do not create unnecessary file conflicts.
- Their acceptance criteria can be verified independently.

Prefer one task at a time when working on foundational architecture, computation engines, or other high-risk components.

---

# 5. Task Execution Workflow

Every development task must follow this lifecycle.

## Step 1 — Understand

Read:
- The individual task file.
- Relevant specification sections.
- Relevant design references.
- Related existing source code.
- Relevant dependencies.

Identify:
- Expected behavior.
- Implementation boundaries.
- Acceptance criteria.
- Technical risks.
- Missing information.

## Step 2 — Brainstorm

Invoke `brainstorming` when necessary.

Resolve significant ambiguities before implementation.

Do not invent missing requirements.

## Step 3 — Plan

Invoke `writing-plans`.

Create a detailed implementation plan and save it under:

`docs/plans/`

The plan must be complete enough to execute without relying on undocumented conversation context.

Present the plan to the user and wait for approval.

## Step 4 — Implement

After approval:

- Create or switch to the task branch before changing any code (see Section 8). Never implement on `main`.
- Follow the approved plan.
- Use TDD.
- Keep changes focused.
- Follow existing architecture and conventions.
- Use subagents only when justified.
- Do not silently expand scope.

If implementation reveals a significant issue that changes the approved approach, stop and explain the issue before proceeding with a materially different solution.

## Step 5 — Review

Invoke `requesting-code-review` when appropriate.

Review the implementation against the task requirements.

Resolve important findings.

## Step 6 — Verify

Invoke `verification-before-completion`.

Verify:
- Acceptance criteria.
- Relevant automated tests.
- Static analysis.
- Formatting and linting where applicable.
- Build requirements when relevant.
- Regression risks.

Record actual command results.

## Step 7 — Update Documentation

Only after successful verification:

- Update the individual task status.
- Update `docs/development/TASKS.md`.
- Update `docs/PROGRESS.md`.
- Record the implementation plan path.
- Record relevant decisions.
- Record verification results.

Do not rewrite task requirements or acceptance criteria.

## Step 8 — Commit and Push

Once verification passes and documentation is updated, commit and push the task branch. This is pre-authorized for every completed task; do not ask for separate permission.

1. Confirm you are on the task branch, not `main`.
2. Review `git status` and `git diff` — stage only files belonging to this task (code, tests, plan, task docs, `TASKS.md`, `PROGRESS.md`). Never stage unrelated user changes, secrets, or build artifacts.
3. Commit using the format in Section 8.
4. Push: `git push -u origin <task-branch>`.
5. Open a pull request into `main` with `gh pr create` if the GitHub CLI is available and authenticated; otherwise report the branch name so the user can open one.
6. Add the PR link to the Git State section of `docs/PROGRESS.md` (the branch name should already be recorded before the commit), then commit it as a small follow-up (`docs(<TASK-ID>): record PR link`) and push again. Do not amend or rewrite pushed commits.

Never merge into `main` or push directly to `main` without explicit user approval.

If the commit or push fails (hook failure, rejected push, auth error), stop, report the exact error, and fix the root cause. Never use `--no-verify`, `--force`, or skip signing.

## Step 9 — Recommend Next Task

Re-evaluate dependencies and identify the next eligible task.

Present its ID, title, reason for selection, dependencies, and relevant risks.

State whether it depends on the just-pushed task branch, and if so whether that PR needs to be merged into `main` first.

Wait for user approval before starting another task.

---

# 6. Persistent Progress Management

Maintain:

`docs/PROGRESS.md`

This file is the central persistent development state.

Create it if it does not exist.

Do not overwrite existing progress when initializing it.

## Required Progress Information

The file must contain:

### Project Status
- Current phase.
- Overall development status.
- Last update date.

### Completed Tasks
- Task IDs.
- Task names.
- Completion status.
- Verification evidence.

### Current Task
- Task ID.
- Task name.
- Current status.
- Implementation plan path.
- Completed steps.
- Remaining steps.

### Next Recommended Task
- Task ID.
- Task name.
- Why it is next.
- Dependency status.

### Blockers
- Unresolved product decisions.
- Architectural blockers.
- Failed tests.
- Missing prerequisites.

### Technical Decisions
- Decision.
- Reason.
- Impacted components.
- Relevant documentation.

### Verification
- Commands executed.
- Test results.
- Build results.
- Known failures.

### Git State
- Current task branch.
- Relevant commits.
- Pull request link and status (open / merged).
- Unmerged task branches that later tasks depend on.
- Uncommitted changes.
- Any work that must be preserved.

## Progress Update Rules

Update `docs/PROGRESS.md`:
- After completing a task.
- When starting an approved task.
- When a significant implementation milestone is reached.
- When discovering a blocker.
- When a technical decision is made.
- Before ending a work session.

Never mark a task complete before its acceptance criteria are verified.

If implementation is partially complete, clearly record it as in progress.

---

# 7. Session Recovery

Development must be resumable across Claude Code sessions and computer restarts.

At the beginning of every new development session:

1. Read `docs/PROGRESS.md`.
2. Inspect the current Git branch and working tree. If on `main` with an in-progress task, switch to that task's branch before doing anything else.
3. Inspect recent relevant commits, open task branches, and the status of their PRs (`gh pr list` when available) — a task whose PR is merged is on `main`; one with an open PR is complete but not yet integrated.
4. Verify the last completed task against the actual code.
5. Inspect unfinished implementation work.
6. Read the relevant task file.
7. Read the associated implementation plan.
8. Re-evaluate dependencies.
9. Identify the next appropriate action.

Never trust progress documentation blindly.

If the progress file conflicts with the actual codebase:
- Investigate the discrepancy.
- Identify what actually exists.
- Reconcile the documentation.
- Do not repeat completed work.
- Do not discard unfinished work.

If the previous session ended during implementation, resume the existing task rather than automatically selecting a new one.

---

# 8. Git and Change Management

Keep Git changes organized and reviewable. All work happens on task branches — never commit directly to `main`.

## Branching

- One branch per task (or per approved task group).
- Branch naming: `task/<TASK-ID>-<short-kebab-description>`
  - Example: `task/FOUNDATION-001-project-initialization`
  - Task group: `task/<FIRST-ID>-<LAST-ID>-<short-description>`
- Planning-only work (saving a plan, updating `PROGRESS.md` before approval) also goes on the task branch, not on `main`.

## Before Implementation

1. Inspect the working tree. Identify unrelated existing changes and do not overwrite them. If uncommitted changes would be carried onto the new branch, stop and ask the user how to handle them.
2. Update `main`: `git checkout main` then `git pull --ff-only origin main`.
3. Create the task branch from the updated `main`: `git checkout -b task/<TASK-ID>-<description>`.
   - If the branch already exists (e.g. resuming), check it out instead of creating a new one.
   - If the task depends on work that is still on an unmerged task branch, do not silently branch from it. Tell the user and recommend either merging the dependency PR first (preferred) or branching from the dependency branch (stacked branch), and wait for their choice.
4. Record the branch name in the Git State section of `docs/PROGRESS.md`.

## During Implementation

- Keep changes focused; avoid mixing unrelated tasks.
- Preserve a clear relationship between task IDs and code changes.
- Intermediate commits on the task branch are allowed at meaningful milestones (e.g. a passing TDD cycle). Pushing them is optional until the task is complete.

## Commit Format

```
<type>(<TASK-ID>): <concise summary>

<optional body: what changed and why, notable decisions>
```

- `type` is one of: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`, `build`.
- Example: `feat(FOUNDATION-001): initialize project structure and tooling`
- Append any attribution trailer required by the current environment.

## After Verification

Follow Task Execution Workflow Step 8 — commit, push the task branch, and open a PR into `main`.

## Hard Rules

- Never commit or push directly to `main`.
- Never merge a PR or merge into `main` without explicit user approval.
- Never force-push, rewrite pushed history, or use `--no-verify` without explicit user approval.
- Never discard or reset changes without explicit user approval.

---

# 9. User Approval and Communication

The user is the final decision-maker for development direction.

You are responsible for technical analysis, task selection, planning, and implementation recommendations.

The user must approve:
- Starting a new task.
- A significant change to an approved implementation plan.
- Unresolved product decisions.
- Significant architectural changes.
- Optional extensions.
- Risky changes outside the approved task scope.

Keep reports concise but technically informative.

When recommending a task, always include:

1. Task ID and title.
2. Why it is the correct next task.
3. Dependency status.
4. Scope.
5. Risks or blockers.
6. Recommended Superpowers workflow.

Do not ask the user to manually inspect the entire task index or choose a task when the documented dependencies are sufficient to make a recommendation.

---

# 10. Skill Operating Modes

Interpret the user's request and operate in the appropriate mode.

## Start

When the user starts development for the first time:

- Read all project documentation.
- Inspect the repository.
- Check whether progress tracking exists.
- Analyze the earliest incomplete phase.
- Identify the first eligible task.
- Present the recommended execution strategy.
- Do not implement application code until approved.

## Next Task

When the user asks to continue or start the next task:

- Verify the current state.
- Re-evaluate dependencies.
- Recommend the next eligible task.
- Wait for approval before implementation.

## Resume

When the user returns after a break:

- Follow the Session Recovery procedure.
- Identify the exact stopping point.
- Verify unfinished work.
- Present a concise recovery report.
- Recommend how to continue.
- Wait for approval before starting a new task.

## Plan

When the user asks to plan a task:

- Read the task and its dependencies.
- Create or switch to the task branch (Section 8).
- Use brainstorming when necessary.
- Invoke writing-plans.
- Save the completed plan under `docs/plans/` on the task branch.
- Update progress documentation.
- Wait for approval before implementation.

## Execute

When the user explicitly approves an implementation plan:

- Ensure you are on the task branch.
- Follow the approved plan.
- Use TDD.
- Use appropriate Superpowers skills.
- Verify all acceptance criteria.
- Update progress and task documentation.
- Commit, push the task branch, and open a PR (Step 8).

## Review

When the user asks for a review:

- Inspect the implementation against the specification.
- Check the task's acceptance criteria.
- Run relevant verification.
- Report findings by severity.
- Do not silently modify unrelated code.

## Status

When the user asks for project status:

- Read `docs/PROGRESS.md`.
- Verify important claims against the repository.
- Report completed, in-progress, blocked, and next eligible tasks.
- Do not infer completion from stale documentation.

---

# 11. First Session Behavior

When invoked for the first time without a specific task:

1. Read the project specification.
2. Read the development roadmap.
3. Read the task documentation.
4. Inspect the design references.
5. Inspect the existing repository and Git state.
6. Analyze Phase 1 and its dependencies.
7. Identify the first eligible task.
8. Identify blockers and unresolved decisions.
9. Recommend whether the task should be handled independently or with subagents.
10. Present the recommendation and wait for approval.

Do not implement application code during the initial analysis.

The first session is for understanding, planning, and selecting the correct starting point.

---

# Final Rule

Your responsibility is not simply to execute tasks.

Your responsibility is to ensure that Zodiann is developed in the correct order, according to its specification, using the Superpowers engineering methodology, with persistent progress tracking and verified implementation quality.

Always know:
- What needs to be built.
- What has actually been built.
- What is currently being worked on.
- What is blocked.
- What should happen next.

Never sacrifice correctness or maintainability for speed.