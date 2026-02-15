---
name: commit
description: Create atomic git commits following project conventions
---

# Commit

## When to use

Use this skill when asked to commit changes, group changes into commits, or prepare commits.

## Commit message rules

- Focus on **why** the change was made, not what changed — the diff shows the "what"
- First line: imperative mood, max 72 characters (e.g. "Ensure order draft flow in unit tests")
- Leave a blank line after the first line if adding a body
- Body (optional): explain motivation, context, or trade-offs — not a list of files changed
- Never mention AI tools, Claude, Claude Code, or assistants in commit messages
- No "Co-Authored-By" lines

## Atomic commits

- Each commit must leave the test suite green (`make test` must pass)
- Group related changes together — a commit should represent one logical change
- If a change spans multiple files but serves one purpose, it belongs in one commit
- Order commits so each builds on the previous without breaking tests
- When splitting a large changeset into commits, verify each commit independently:
  1. Stage only the files for that commit
  2. Stash the rest (`git stash --keep-index`)
  3. Run tests (`make test`)
  4. Unstash (`git stash pop`)
  5. If tests pass, commit

## Process

1. Review all uncommitted changes (`git status`, `git diff`)
2. Identify logical groups of changes
3. Determine the right commit order (dependencies first)
4. For each commit:
   - Stage relevant files
   - Verify tests pass with only those changes
   - Draft a commit message following the rules above
   - Present the staged files and message for user approval
5. Wait for user confirmation before committing

## Examples of good commit messages

```
Ensure integration tests use proper order creation flow

Tests were creating orders via SecureRandom.uuid without going through
the draft flow, skipping the OfferDrafted event that read models depend on.
```

```
Add Deals read model for sales pipeline tracking
```

```
Replace defensive &. checks with find_by! in event handlers

Events always follow the real application flow, so records are
guaranteed to exist. Using find_by! surfaces bugs instead of hiding them.
```
