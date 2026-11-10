@testitem "test function sanity checks" setup = [TestProblems] begin
    using NonconvexSearch, Test

    for F in TEST_FUNCTIONS
        @test F(minimum_location(F, 10)) ≈ 0
    end
end

@testitem "MTS" setup = [TestProblems] begin
    using NonconvexSearch, Test

    # Temporary disable ROSENBROCK
    println("Testing MTS... ")
    for F in setdiff(TEST_FUNCTIONS, (ROSENBROCK,))
        println("Testing nonconvex function: ", F)
        m = Model(x -> F(x))
        lb = [lu_bounds(F)[1] for _ in 1:test_dim]
        ub = [lu_bounds(F)[2] for _ in 1:test_dim]
        addvar!(m, lb, ub)
        alg = MTSAlg()
        r = optimize(m, alg, options=MTSOptions())
        println(r.minimizer)
        println(r.minimum)
        @test abs(r.minimum) < tol(F)
    end
end

@testitem "Localsearch1" setup = [TestProblems] begin
    using NonconvexSearch, Test

    println("Testing Localsearch1... ")
    for F in setdiff(TEST_FUNCTIONS, (ROSENBROCK,))
        println("Testing nonconvex function: ", F)
        m = Model(x -> F(x))
        lb = [lu_bounds(F)[1] for _ in 1:test_dim]
        ub = [lu_bounds(F)[2] for _ in 1:test_dim]
        addvar!(m, lb, ub)
        alg = LS1Alg()
        r = optimize(m, alg, options=LS1Options())
        println(r.minimizer)
        println(r.minimum)
        @test abs(r.minimum) < tol(F)
    end
end

@testitem "LS3 records the improving candidate" begin
    using NonconvexSearch, NonconvexCore, Test

    # Regression test: LS3 used to store the current point and value instead
    # of the improving probe, corrupting the best-so-far tracking.
    f = x -> sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(vm, MTSAlg(), [[-3.0, -3.0]]; options=MTSOptions())
    NonconvexSearch._localsearch3(w, 1)
    @test isapprox(w.optimal_val, f(w.optimal_x); atol=1e-10)
    @test w.optimal_val < f([-3.0, -3.0])
end

@testitem "optimize does not mutate the caller's x0" begin
    using NonconvexSearch, NonconvexCore, Test

    f = x -> sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    x0 = [[-3.0, -3.0], [-2.0, -2.0], [3.0, 3.0]]
    x0_snapshot = deepcopy(x0)
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(
        vm,
        MTSAlg(),
        x0;
        options=MTSOptions(
            M=3,
            maxiter=3,
            n_foreground=3,
            n_local_search=2,
            n_local_search_test=2,
            n_local_search_best=2,
        ),
    )
    NonconvexCore.optimize!(w)
    @test x0 == x0_snapshot
end

@testitem "initialize_x with M = 1" begin
    using NonconvexSearch, NonconvexCore, Test

    m = Model(x -> sum(x .^ 2))
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    x0 = NonconvexSearch.initialize_x(vm, MTSOptions(M=1))
    @test length(x0) == 1
    @test all(isfinite, x0[1])
end

@testitem "Random coordinate descent" begin
    using NonconvexSearch, NonconvexMMA, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 4), fill(5.0, 4))
    r = optimize(
        m,
        RCDAlg(MMA02()),
        fill(0.0, 4),
        options=RCDOptions(maxiter=20, ncoords=2, verbose=false),
    )
    @test norm(r.minimizer - ones(4)) < 1e-2
    @test abs(r.minimum) < 1e-3

    # Constrained problem: min sum((x - 1)^2) s.t. x[1] + x[2] <= 1.
    m2 = Model(f)
    addvar!(m2, fill(-5.0, 4), fill(5.0, 4))
    add_ineq_constraint!(m2, x -> x[1] + x[2] - 1.0)
    r2 = optimize(
        m2,
        RCDAlg(MMA02()),
        fill(0.0, 4),
        options=RCDOptions(maxiter=30, ncoords=2, verbose=false),
    )
    @test r2.minimizer[1] + r2.minimizer[2] <= 1.0 + 1e-3
    @test abs(r2.minimum - 0.5) < 0.05
end

@testitem "Random coordinate descent - fraction and sub_options" begin
    using NonconvexSearch, NonconvexMMA, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 4), fill(5.0, 4))
    # The fraction option (ncoords === nothing) and sub_options forwarding.
    r = optimize(
        m,
        RCDAlg(MMA02()),
        fill(0.0, 4),
        options=RCDOptions(
            maxiter=10,
            fraction=0.5,
            sub_options=MMAOptions(maxiter=50, verbose=false),
            verbose=false,
        ),
    )
    @test isfinite(r.minimum)
    @test norm(r.minimizer - ones(4)) < 1e-2
end

@testitem "Random coordinate descent - equality constraints" begin
    using NonconvexSearch, NonconvexIpopt, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 4), fill(5.0, 4))
    add_eq_constraint!(m, x -> x[3] + x[4] - 2.0)
    r = optimize(
        m,
        RCDAlg(IpoptAlg()),
        fill(0.0, 4),
        options=RCDOptions(
            maxiter=5,
            ncoords=3,
            verbose=false,
            # Pass the sub-solver's default options explicitly.
            sub_options=IpoptOptions(),
        ),
    )
    # The optimum x = ones(4) satisfies the constraint.
    @test abs(r.minimizer[3] + r.minimizer[4] - 2.0) < 1e-3
    @test abs(r.minimum) < 0.2
end

@testitem "solver capabilities" begin
    using NonconvexSearch, Test

    for A in (MTSAlg, LS1Alg)
        caps = solver_capabilities(A())
        @test caps isa ConstraintCapabilities
        @test caps.linear_eq === false
        @test caps.nonlinear_eq === false
        @test caps.linear_ineq === false
        @test caps.nonlinear_ineq === false
        @test caps.linear_sd === false
        @test caps.nonlinear_sd === false
        @test caps.box === true
        @test caps.integer === false
        @test caps.infinite_bounds === false
    end
    # RCD forwards the sub-solver's capabilities.
    @test solver_capabilities(RCDAlg(MTSAlg())) == solver_capabilities(MTSAlg())
end
