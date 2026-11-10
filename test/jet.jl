@testitem "JET" begin
    using NonconvexSearch, Test
    # JET 0.13's `report_package` corrupts the loaded method tables on
    # Julia 1.13 (its virtual top-level replay re-evaluates `@params`
    # definitions in the running process), so analyze in a fresh subprocess
    # to keep the test process intact for the remaining testitems.
    julia = joinpath(Sys.BINDIR, Base.julia_exename())
    project = dirname(Base.active_project())
    code =
        "using JET, NonconvexSearch\n" *
        "JET.test_package(NonconvexSearch; target_modules=(NonconvexSearch,))"
    @test success(
        pipeline(
            `$julia --startup-file=no --project=$project -e $code`;
            stdout=devnull,
            stderr=devnull,
        ),
    )
end
