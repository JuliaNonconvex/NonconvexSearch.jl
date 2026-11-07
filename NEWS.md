# NEWS

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
