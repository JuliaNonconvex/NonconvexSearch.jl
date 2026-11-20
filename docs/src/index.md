# Multi-trajectory search and random coordinate descent in pure Julia

![JuliaNonconvex logo](https://raw.githubusercontent.com/JuliaNonconvex/NonconvexSearch.jl/master/docs/src/assets/logo.png)



## Description

Multiple trajectory search (MTS) is a derivative-free heuristic optimization method presented by [Lin-Yu Tseng and Chun Chen, 2008](https://sci2s.ugr.es/sites/default/files/files/TematicWebSites/EAMHCO/contributionsCEC08/tseng08mts.pdf). 
The `MTS` algorithm is implemented in the `NonconvexSearch.jl` package. This module implements all the optimization methods in the paper, including the local search 1 (`LS1`) algorithm as a standalone optimizer.

See [MTS](mts.md) for the multiple trajectory search, [Local search
1](ls1.md) for the local search meta-algorithm, [Random coordinate
descent](rcd.md) for the RCD meta-algorithm and [Docstrings](docstrings.md)
for the full API reference.
