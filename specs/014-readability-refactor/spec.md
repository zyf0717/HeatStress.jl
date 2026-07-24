# Readability refactor

## Purpose

Improve source and documentation readability without changing scientific
behaviour, public-call semantics, numerical results, allocation behaviour, or
benchmark outcomes.

## Scope

- document package architecture, public API, and the Liljegren execution path;
- replace stale scaffold status text in the README and documentation home page;
- reconcile exports with completed owning specifications;
- remove only empty placeholder source files and their includes, if any;
- split the monolithic type and scalar implementation files by responsibility;
- replace reflective diagnostic row copying with equivalent explicit assignments.

No formula, validation policy, execution order, public type definition, or
public signature may change. Non-empty secondary-index sources remain included
but unexported while spec 009's formula-selection gate is unresolved.

## Acceptance criteria

- all existing tests pass without changes to their scientific expectations;
- completed Liljegren scalar and batch APIs are exported, while incomplete
  specification-owned APIs remain unexported;
- scalar and batch paths retain their existing row execution order;
- generated documentation includes architecture, API, and Liljegren pages;
- Aqua, JET, documentation build, and benchmark smoke runs succeed;
- benchmark smoke output preserves the established scalar/batch result
  equivalence checks, with no performance claim inferred from smoke timing.
