@testitem "MTS does not crash when the optimum is never set" begin
    using NonconvexSearch, NonconvexCore, Test

    # An all-NaN objective keeps `optimal_val = Inf` and `optimal_ind = -1`,
    # which used to make `mts` index `x[-1]` in the polishing pass.
    m = Model(x -> NaN)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(
        vm,
        MTSAlg(),
        [[0.0, 0.0]];
        options=MTSOptions(
            M=1,
            maxiter=1,
            n_foreground=1,
            n_local_search=2,
            n_local_search_test=1,
            n_local_search_best=1,
        ),
    )
    r = NonconvexCore.optimize!(w)
    @test w.optimal_ind == -1
    @test !isfinite(r.minimum)
end

@testitem "MTS clamps n_foreground to the number of enabled trajectories" begin
    using NonconvexSearch, NonconvexCore, Test

    # `n_foreground = 80 > M = 1` used to throw a BoundsError in
    # `reverse(sortperm(grade_x))[begin:n_foreground]`.
    f(x) = sum(x .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(
        vm,
        MTSAlg(),
        [[1.0, 1.0]];
        options=MTSOptions(
            M=1,
            maxiter=2,
            n_foreground=80,
            n_local_search=2,
            n_local_search_test=1,
            n_local_search_best=1,
        ),
    )
    r = NonconvexCore.optimize!(w)
    @test count(w.enable) == 1
    @test isfinite(r.minimum)
end

@testitem "LS3 tracks the accepted iterate" begin
    using NonconvexSearch, NonconvexCore, Test

    # Starting at [-3, -3], every probe (x ± 0.1/0.2 per coordinate) improves
    # the quadratic objective, and the blended final iterate moves every
    # coordinate toward 0 by at least ~0.47, so it is always better than any
    # probe. The final `_xk` that becomes `x[k]` used to never be evaluated or
    # compared against `optimal_val`, so the tracked optimum missed it.
    f = x -> sum(abs2, x)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(vm, MTSAlg(), [[-3.0, -3.0]]; options=MTSOptions())
    NonconvexSearch._localsearch3(w, 1)
    @test w.optimal_val <= f(w.x[1])
    @test w.optimal_val ≈ f(w.optimal_x)
end

@testitem "MTS result minimizer does not alias the workspace" begin
    using NonconvexSearch, NonconvexCore, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(
        vm,
        MTSAlg(),
        [[-3.0, -3.0], [-2.0, -2.0], [3.0, 3.0]];
        options=MTSOptions(
            M=3,
            maxiter=2,
            n_foreground=3,
            n_local_search=2,
            n_local_search_test=2,
            n_local_search_best=2,
        ),
    )
    r1 = NonconvexCore.optimize!(w)
    # Regression test: `MTSResult` used to alias the live `workspace.optimal_x`.
    @test r1.minimizer !== w.optimal_x
    r2 = NonconvexCore.optimize!(w)
    @test r1.minimizer !== r2.minimizer
    snapshot = copy(r2.minimizer)
    r1.minimizer .= 42.0
    @test r2.minimizer == snapshot
end
