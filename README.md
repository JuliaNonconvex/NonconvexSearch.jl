<p align="center">
  <img src="assets/logo.png" width="400" alt="NonconvexSearch.jl logo">
</p>

[![Documentation (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://julianonconvex.github.io/NonconvexSearch.jl/stable)
[![Documentation (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://julianonconvex.github.io/NonconvexSearch.jl/dev)
[![Build Status](https://github.com/JuliaNonconvex/NonconvexSearch.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/JuliaNonconvex/NonconvexSearch.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaNonconvex/NonconvexSearch.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaNonconvex/NonconvexSearch.jl)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-Blue-4473c9.svg)](https://github.com/invenia/BlueStyle)
[![JET](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a)](https://github.com/aviatesk/JET.jl)

# NonconvexSearch.jl

Multi-trajectory search and random coordinate descent

The MTS heuristic with its LS1 local search and the RCD meta-algorithm.

NonconvexSearch.jl is part of the [JuliaNonconvex](https://github.com/JuliaNonconvex) ecosystem built on [NonconvexCore.jl](https://github.com/JuliaNonconvex/NonconvexCore.jl).

## Quick start

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

## Documentation

The full documentation is available at [https://julianonconvex.github.io/NonconvexSearch.jl/stable](https://julianonconvex.github.io/NonconvexSearch.jl/stable) (stable) and [https://julianonconvex.github.io/NonconvexSearch.jl/dev](https://julianonconvex.github.io/NonconvexSearch.jl/dev) (development).

## Installation

```julia
using Pkg
Pkg.add("NonconvexSearch")
```
