using NonconvexSearch, Test

include("problems.jl")

@testset "test function sanity checks" begin
    for F in TEST_FUNCTIONS
        @test F(minimum_location(F, 10)) ≈ 0
    end
end

d_tol = Dict(
    SHIFTED_QUADRATIC => 1e-6,
    GRIEWANK => 1e-6,
    LEVY_MONTALVO2 => 1e-6,
    RASTRIGIN => 1e-6,
    ROSENBROCK => 1e-1,
)
tol(F) = (d_tol[F])

test_dim = 2

@testset "MTS" begin
    # Temporary disable ROSENBROCK
    println("Testing MTS... ")
    for F in setdiff(TEST_FUNCTIONS, (ROSENBROCK,))
        println("Testing nonconvex function: ", F)
        m = Model(x -> F(x))
        lb = [lu_bounds(F)[1] for _ = 1:test_dim]
        ub = [lu_bounds(F)[2] for _ = 1:test_dim]
        addvar!(m, lb, ub)
        alg = MTSAlg()
        r = optimize(m, alg, options = MTSOptions())
        println(r.minimizer)
        println(r.minimum)
        @test abs(r.minimum) < tol(F)
    end
end

@testset "Localsearch1" begin
    println("Testing Localsearch1... ")
    for F in setdiff(TEST_FUNCTIONS, (ROSENBROCK,))
        println("Testing nonconvex function: ", F)
        m = Model(x -> F(x))
        lb = [lu_bounds(F)[1] for _ = 1:test_dim]
        ub = [lu_bounds(F)[2] for _ = 1:test_dim]
        addvar!(m, lb, ub)
        alg = LS1Alg()
        r = optimize(m, alg, options = LS1Options())
        println(r.minimizer)
        println(r.minimum)
        @test abs(r.minimum) < tol(F)
    end
end

@testset "LS3 records the improving candidate" begin
    # Regression test: LS3 used to store the current point and value instead
    # of the improving probe, corrupting the best-so-far tracking.
    f = x -> sum((x .- 1.0).^2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(vm, MTSAlg(), [[-3.0, -3.0]]; options = MTSOptions())
    NonconvexSearch._localsearch3(w, 1)
    @test isapprox(w.optimal_val, f(w.optimal_x); atol = 1e-10)
    @test w.optimal_val < f([-3.0, -3.0])
end

@testset "optimize does not mutate the caller's x0" begin
    f = x -> sum((x .- 1.0).^2)
    m = Model(f)
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    x0 = [[-3.0, -3.0], [-2.0, -2.0], [3.0, 3.0]]
    x0_snapshot = deepcopy(x0)
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(vm, MTSAlg(), x0; options = MTSOptions(
            M = 3,
            maxiter = 3,
            n_foreground = 3,
            n_local_search = 2,
            n_local_search_test = 2,
            n_local_search_best = 2,
        ))
    NonconvexCore.optimize!(w)
    @test x0 == x0_snapshot
end

@testset "initialize_x with M = 1" begin
    m = Model(x -> sum(x.^2))
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    vm, _, _ = NonconvexCore.tovecmodel(m)
    x0 = NonconvexSearch.initialize_x(vm, MTSOptions(M = 1))
    @test length(x0) == 1
    @test all(isfinite, x0[1])
end

@testset "Random coordinate descent" begin
    using NonconvexMMA
    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 4), fill(5.0, 4))
    r = optimize(
        m,
        RCDAlg(MMA02()),
        fill(0.0, 4),
        options = RCDOptions(maxiter = 20, ncoords = 2, verbose = false),
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
        options = RCDOptions(maxiter = 30, ncoords = 2, verbose = false),
    )
    @test r2.minimizer[1] + r2.minimizer[2] <= 1.0 + 1e-3
    @test abs(r2.minimum - 0.5) < 0.05
end
