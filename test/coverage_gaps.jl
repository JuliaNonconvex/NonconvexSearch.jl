@testitem "LS1 constraint warning and MTS improvement" begin
    using NonconvexSearch, NonconvexCore, LinearAlgebra, Test

    # LS1 with a constraint hits the unsupported-constraints warning when the
    # workspace is built directly (optimize() rejects it earlier via the
    # capability checks).
    m = NonconvexCore.Model(x -> sum(x .^ 2))
    addvar!(m, [-5.0, -5.0], [5.0, 5.0])
    add_ineq_constraint!(m, x -> x[1] + x[2] - 1.0)
    vm = NonconvexCore.tovecmodel(m)[1]
    w = NonconvexSearch.Workspace(vm, LS1Alg(), [[2.0, 2.0]]; options=LS1Options(maxiter=100))
    @test w isa NonconvexSearch.LS1Workspace

    # A regular MTS solve traverses the improvement branch when a candidate
    # beats the incumbent.
    m2 = NonconvexCore.Model(x -> (x[1] - 1.0)^2 + (x[2] - 2.0)^2)
    addvar!(m2, [-5.0, -5.0], [5.0, 5.0])
    r2 = NonconvexSearch.optimize(m2, MTSAlg(), options=MTSOptions(maxiter=50))
    @test isfinite(r2.minimum)
end
