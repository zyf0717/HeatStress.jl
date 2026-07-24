# Readability refactor plan

1. Record the existing implementation/specification boundary and export policy.
2. Add documentation and replace stale scaffold wording.
3. Split source files without altering declarations or call order.
4. Make diagnostic batch copying explicit.
5. Verify source layout, public exports, tests, quality tooling, documentation,
   and benchmark smoke paths.

The refactor moves definitions only. Include order preserves dependencies:
statuses, configuration, results, diagnostics; then scalar internal state,
balance construction, result materialisation, row execution, and public API.
