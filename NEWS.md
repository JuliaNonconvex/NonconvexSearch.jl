# NEWS

## 0.1.4

- Fixed invalid stdlib compat bounds (`Random = "1.11.0 - 1"`) that
  accidentally shipped in 0.1.3 and made the package uninstallable on
  Julia 1.10 (users silently resolved to 0.1.2).
- Requires Julia 1.10+.
