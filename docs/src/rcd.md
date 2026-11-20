# Random coordinate descent meta-algorithm

## Description

Random coordinate descent (RCD) is a meta-algorithm that optimizes a random
subset of the coordinates in every iteration using a sub-algorithm while
keeping the other coordinates fixed. Breaking the coupling between
coordinates this way can help counter non-convexity. The method is available
in `NonconvexSearch.jl` as `RCDAlg(sub_alg)` where `sub_alg` is any
`AbstractOptimizer` from the Nonconvex ecosystem.

### Quick start

```julia
using NonconvexMMA, NonconvexSearch

f(x) = sum((x .- 1.0) .^ 2)
m = Model(f)
addvar!(m, fill(-5.0, 4), fill(5.0, 4))

alg = RCDAlg(MMA02())
options = RCDOptions(maxiter = 20, ncoords = 2)
r = optimize(m, alg, fill(0.0, 4), options = options)
```

The options are:

- `maxiter`: the maximum number of outer iterations.
- `fraction`: the fraction of coordinates updated in each iteration. Ignored
  when `ncoords` is set.
- `ncoords`: the number of coordinates updated in each iteration. When
  `nothing`, `fraction` is used.
- `sub_options`: the options passed to the sub-solver. When `nothing`, the
  sub-solver's default options are used.
- `verbose`: whether to print the objective in every iteration.
