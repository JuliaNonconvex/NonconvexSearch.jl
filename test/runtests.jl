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
