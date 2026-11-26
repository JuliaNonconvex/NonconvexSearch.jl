# NEWS

## 0.2.8

- Allow NonconvexIpopt 0.9 (the previous compat pinned it below 0.9, forcing co-resolved environments onto the outdated 0.8.x line).

## 0.2.7

- Docs: the logo now appears only in the sidebar, not in the page body.
## 0.2.6

- Docs: package-name section titles and left-aligned logos (no code changes).
## 0.2.5

- `reset!` for the RCD, MTS and LS1 workspaces now restarts the search
  from the new `x0` (nesting inside meta-algorithms like `HyperoptAlg` used
  to silently continue from the previous endpoint).
- Non-finite objective values are no longer treated as improvements and no
  longer corrupt the MTS trajectories.
- RCD `verbose` now defaults to `false`.

## 0.2.4

- Added docstrings for `MTSAlg`, `LS1Alg` and their options (REPL help and API reference).


## Unreleased

- Fixed a memoization buffer in the MTS/LS1 local searches that could raise a
  spurious `KeyError` during optimization (flaky CI failures on Julia 1.13+).
  The buffer now uses a single `get!` lookup and keys on the evaluation point
  only.

## 0.2.3

- Fixed the RCD semidefinite-constraint drop and MTS edge cases; covered
  the LS1 constraint warning and the MTS improvement branch; scheduled
  formatter workflow.

## 0.2.1

- Fixed the docs layout (RCD is a section, not a second page title);
  NonconvexCore 2 with strict solver capability declarations
  (`infinite_bounds`); DocumenterFragments docs; TestItems/JET/Aqua.

## 0.2.0

- Added `RCDAlg` and `RCDOptions`: a random coordinate descent
  meta-algorithm that optimizes a random subset of the coordinates in every
  iteration using a configurable sub-algorithm (`ncoords` or `fraction`
  coordinates per iteration, `sub_options` forwarded to the sub-solver).

## 0.1.4

- Fixed invalid stdlib compat bounds (`Random = "1.11.0 - 1"`) that
  accidentally shipped in 0.1.3 and made the package uninstallable on
  Julia 1.10 (users silently resolved to 0.1.2).
- Requires Julia 1.10+.
