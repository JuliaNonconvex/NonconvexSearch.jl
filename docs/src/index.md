# Multi-trajectory search and random coordinate descent in pure Julia

![JuliaNonconvex logo](https://raw.githubusercontent.com/JuliaNonconvex/NonconvexSearch.jl/master/docs/src/assets/logo.png)

## Description

Multiple trajectory search (MTS) is a derivative-free heuristic optimization method presented by [Lin-Yu Tseng and Chun Chen, 2008](https://sci2s.ugr.es/sites/default/files/files/TematicWebSites/EAMHCO/contributionsCEC08/tseng08mts.pdf). 
The `MTS` algorithm is implemented in the `NonconvexSearch.jl` package. This module implements all the optimization methods in the paper, including the local search 1 (`LS1`) algorithm as a standalone optimizer.

## MTS

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

## Local search 1 (LS1)

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

## Random coordinate descent meta-algorithm

## Description

Random coordinate descent (RCD) is a meta-algorithm that optimizes a random
subset of the coordinates in every iteration using a sub-algorithm while
keeping the other coordinates fixed. Breaking the coupling between
coordinates this way can help counter non-convexity. The method is available
in `NonconvexSearch.jl` as `RCDAlg(sub_alg)` where `sub_alg` is any
`AbstractOptimizer` from the Nonconvex ecosystem.

## Quick start

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
