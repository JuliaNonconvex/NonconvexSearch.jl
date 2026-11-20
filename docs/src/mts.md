# MTS

### Quick start

Given a model `model`, the `MTSAlg` optimizer can be used with the default `MTSOptions()` as follows.

```julia
using NonconvexSearch

f(x) = sum(x .^ 2)
m = Model(f)
lb = [0, 0]
ub = [5, 5]
addvar!(m, lb, ub)

alg = MTSAlg()
options = MTSOptions()
result = optimize(m, alg, options = options)
```

`MTS` only supports box-constrained continuous problems; (in)equality constraints are ignored with a warning.

### Options

The options keyword argument to the `optimize` function shown above must be an instance of the `MTSOptions` struct when the algorithm is an `MTSAlg`. To specify options use keyword arguments in the constructor of `MTSOptions`, e.g:

```julia
options = MTSOptions(M = 40, maxiter = 100)
```

The most important options are:
- `M`: the number of trajectories, `100` by default.
- `maxiter`: the maximum number of iterations of the multi-trajectory search, `200` by default.
- `search_range_tol`: the tolerance below which a search range is reset, `1e-15` by default.
- `n_foreground`: the number of foreground trajectories kept in every iteration, `80` by default.
- `n_local_search`, `n_local_search_test`, `n_local_search_best`: the number of local search steps performed on the best trajectory, the test and the best local searches, `200`, `3` and `300` by default respectively.
