# Additional feature tests for NonconvexSearch (src/mts.jl, src/rcd.jl)
# targeting the exported-surface gaps not covered by the main suite: the
# MTSOptions/LS1Options fields, the no-explicit-start-point path for MTS and
# LS1, and RCDOptions field handling and clamping.

@testitem "MTSOptions and LS1Options fields" begin
    using NonconvexSearch, Test

    @testset "MTSOptions" begin
        o = MTSOptions(M=40, maxiter=10, search_range_tol=1e-10, n_foreground=30)
        @test o.M == 40
        @test o.maxiter == 10
        @test o.search_range_tol == 1e-10
        @test o.n_foreground == 30
        # The remaining tunable fields keep their defaults.
        @test o.n_local_search == 200
        @test o.n_local_search_test == 3
        @test o.n_local_search_best == 300
        @test o.BONUS1 == 10
        @test o.BONUS2 == 1
        @test o.a_min == 0.4
        @test o.a_max == 0.5
        @test o.b_min == 0.1
        @test o.b_max == 0.3
        @test o.c_min == 0
        @test o.c_max == 1
        @test o.REDUCE_SEARCH_RANGE_FACTOR == 2.5
        @test o.SEARCH_RANGE_DEGERATE_FACTOR == 2
        @test o.Y1_INCR == 0.1
        @test o.Y1_DECR == 0.1
        @test o.X2_INCR == 0.2
    end

    @testset "LS1Options" begin
        o = LS1Options(M=20, maxiter=5, search_range_tol=1e-9)
        @test o.M == 20
        @test o.maxiter == 5
        @test o.search_range_tol == 1e-9
        @test o.REDUCE_SEARCH_RANGE_FACTOR == 2.5
        @test o.SEARCH_RANGE_DEGERATE_FACTOR == 2
        @test o.Y1_INCR == 0.1
        @test o.Y1_DECR == 0.1
        @test o.X2_INCR == 0.2
        @test o.BONUS1 == 10
        @test o.BONUS2 == 1
    end
end

@testitem "tiny MTS and LS1 solves with custom options" begin
    using NonconvexSearch, NonconvexCore, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    x0 = [[-3.0, -3.0], [-2.0, -2.0], [3.0, 3.0]]

    # MTS/LS1 take a trajectory start point (a vector of vectors), so the
    # solve goes through Workspace on the VecModel directly.
    @testset "MTS" begin
        w = NonconvexSearch.Workspace(
            vm,
            MTSAlg(),
            x0;
            options=MTSOptions(
                M=3,
                maxiter=5,
                n_foreground=3,
                n_local_search=2,
                n_local_search_test=2,
                n_local_search_best=2,
            ),
        )
        r = NonconvexCore.optimize!(w)
        @test isfinite(r.minimum)
        @test length(r.minimizer) == 2
        @test all(-5.0 .<= r.minimizer .<= 5.0)
    end

    @testset "LS1" begin
        w = NonconvexSearch.Workspace(vm, LS1Alg(), x0; options=LS1Options(M=3, maxiter=10))
        r = NonconvexCore.optimize!(w)
        @test isfinite(r.minimum)
        @test length(r.minimizer) == 2
        @test all(-5.0 .<= r.minimizer .<= 5.0)
    end
end

@testitem "MTS and LS1 without an explicit start point" begin
    using NonconvexSearch, NonconvexCore, Test

    f(x) = sum(x .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])

    @testset "MTS (initialize_x path)" begin
        r = optimize(
            m,
            MTSAlg(),
            options=MTSOptions(
                M=3,
                maxiter=3,
                n_foreground=3,
                n_local_search=2,
                n_local_search_test=2,
                n_local_search_best=2,
            ),
        )
        @test isfinite(r.minimum)
        @test all(isfinite, r.minimizer)
    end

    @testset "LS1 (initialize_x path)" begin
        r = optimize(m, LS1Alg(), options=LS1Options(M=3, maxiter=3))
        @test isfinite(r.minimum)
        @test all(isfinite, r.minimizer)
    end
end

@testitem "RCDOptions fields and ncoords clamping" begin
    using NonconvexSearch, NonconvexMMA, Test

    @testset "fields" begin
        o = RCDOptions()
        @test o.maxiter == 100
        @test o.fraction == 0.5
        @test o.ncoords === nothing
        @test o.sub_options === nothing
        @test o.verbose === true
        o2 = RCDOptions(maxiter=5, fraction=0.25, ncoords=2, verbose=false)
        @test o2.maxiter == 5
        @test o2.fraction == 0.25
        @test o2.ncoords == 2
        @test o2.verbose === false
    end

    @testset "ncoords larger than the dimension is clamped" begin
        f(x) = sum((x .- 1.0) .^ 2)
        m = Model(f)
        addvar!(m, fill(-5.0, 2), fill(5.0, 2))
        r = optimize(
            m,
            RCDAlg(MMA02()),
            fill(0.0, 2),
            options=RCDOptions(maxiter=10, ncoords=10, verbose=false),
        )
        @test norm(r.minimizer - ones(2)) < 1e-2
        @test abs(r.minimum) < 1e-3
    end
end
