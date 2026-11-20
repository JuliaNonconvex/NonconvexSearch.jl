# Local search 1 (LS1)

`LS1Alg` exposes the first local search strategy of the MTS paper as a standalone optimizer. It also only supports box-constrained continuous problems.

### Quick start

```julia
using NonconvexSearch

f(x) = sum(x .^ 2)
m = Model(f)
addvar!(m, [0, 0], [5, 5])

alg = LS1Alg()
options = LS1Options()
result = optimize(m, alg, options = options)
```

### Options

The options keyword argument to the `optimize` function shown above must be an instance of the `LS1Options` struct when the algorithm is an `LS1Alg`. To specify options use keyword arguments in the constructor of `LS1Options`, e.g:

```julia
options = LS1Options(M = 40, maxiter = 100)
```

The most important options are:
- `M`: the number of trajectories, `100` by default.
- `maxiter`: the maximum number of iterations of the local search, `200` by default.
- `search_range_tol`: the tolerance below which a search range is reset, `1e-15` by default.
