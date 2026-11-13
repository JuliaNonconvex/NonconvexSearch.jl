@testitem "rcd_submodel keeps SD constraints" begin
    using NonconvexSearch, NonconvexCore, Test

    f(x) = sum(x .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 3), fill(5.0, 3))
    add_sd_constraint!(m, x -> [x[1] 0.0; 0.0 x[2]], 2)
    vm, _, _ = NonconvexCore.tovecmodel(m)
    @test length(vm.sd_constraints.fs) == 1
    # Regression test: `rcd_submodel` used to rebuild the sub-model with an
    # empty `VectorOfFunctions(SDConstraint[])`, silently dropping the parent
    # model's semidefinite constraints even though `solver_capabilities(RCDAlg)`
    # forwards the sub-solver's SD capabilities.
    sub = NonconvexSearch.rcd_submodel(vm, zeros(3), [1, 2])
    @test length(sub.sd_constraints.fs) == 1
    c = sub.sd_constraints.fs[1]
    @test c.dim == 2
    # The sub-constraint applies the coordinate substitution: the sub-problem
    # coordinates [1, 2] map onto the parent coordinates [1, 2] (coordinate 3
    # stays fixed at its substituted value 0).
    out = c([0.5, -0.25])
    @test out == [0.5 0.0; 0.0 -0.25]
end

@testitem "RCD result minimizer does not alias the workspace" begin
    using NonconvexSearch, NonconvexMMA, NonconvexCore, Test

    f(x) = sum((x .- 1.0) .^ 2)
    m = Model(f)
    addvar!(m, fill(-5.0, 4), fill(5.0, 4))
    vm, _, _ = NonconvexCore.tovecmodel(m)
    w = NonconvexSearch.Workspace(
        vm,
        RCDAlg(MMA02()),
        zeros(4);
        options=RCDOptions(maxiter=2, ncoords=2, verbose=false),
    )
    r1 = NonconvexCore.optimize!(w)
    # Regression test: `RCDResult` used to alias the live `workspace.x`, so
    # re-running `optimize!` mutated previously returned results.
    @test r1.minimizer !== w.x
    r2 = NonconvexCore.optimize!(w)
    @test r1.minimizer !== r2.minimizer
    snapshot = copy(r2.minimizer)
    r1.minimizer .= 42.0
    @test r2.minimizer == snapshot
end
