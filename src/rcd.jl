# Random Coordinate Descent
#
# A meta-algorithm that optimizes a random subset of the coordinates in every
# iteration using a sub-algorithm, keeping the other coordinates fixed. This
# can help counter non-convexity by breaking the coupling between coordinates.

"""
    RCDAlg(sub_alg)

Random coordinate descent meta-algorithm. Each iteration selects a random
subset of the coordinates and solves the subproblem over those coordinates
with `sub_alg`, keeping the remaining coordinates fixed. `sub_alg` can be any
`AbstractOptimizer` from the Nonconvex ecosystem.
"""
@params struct RCDAlg{S<:AbstractOptimizer} <: AbstractOptimizer
    sub_alg::S
end

# RCD is a meta-algorithm: the sub-problems (with eq/ineq/box/integer
# features forwarded verbatim) are solved by the sub-solver.
NonconvexCore.solver_capabilities(alg::RCDAlg) = solver_capabilities(alg.sub_alg)

"""
    RCDOptions(; kwargs...)

Options of the random coordinate descent meta-algorithm. The fields are:
 - `maxiter`: the maximum number of outer iterations.
 - `fraction`: the fraction of coordinates updated in each iteration. Ignored
   when `ncoords` is set.
 - `ncoords`: the number of coordinates updated in each iteration. When
   `nothing`, `fraction` is used.
 - `sub_options`: the options passed to the sub-solver. When `nothing`, the
   sub-solver's default options are used.
 - `verbose`: whether to print the objective in every iteration.
"""
@with_kw struct RCDOptions
    maxiter::Int = 100
    fraction::Float64 = 0.5
    ncoords::Union{Nothing,Int} = nothing
    sub_options = nothing
    verbose::Bool = true
end

@params mutable struct RCDWorkspace <: Workspace
    model::VecModel
    sub_alg::AbstractOptimizer
    x0::AbstractVector
    options::RCDOptions
    x::AbstractVector
    f::Real
    iter::Int
end

function Workspace(
    model::VecModel,
    optimizer::RCDAlg,
    x0::AbstractVector;
    options::RCDOptions=RCDOptions(),
    kwargs...,
)
    objective = NonconvexCore.getobjective(model)
    objective === nothing && throw(ArgumentError("The model has no objective."))
    return RCDWorkspace(
        model, optimizer.sub_alg, copy(x0), options, copy(x0), objective(x0), 0
    )
end

@params struct RCDResult <: AbstractResult
    minimum::Any
    minimizer::Any
end

"""
    rcd_submodel(model, x, coords)

Builds a `VecModel` over the selected coordinates `coords` with the other
coordinates of `x` substituted in the objective and constraints.
"""
function rcd_submodel(model::VecModel, x::AbstractVector, coords::AbstractVector{Int})
    # Affine substitution map so the sub-model functions stay mutation-free
    # and therefore differentiable through Zygote.
    n = length(x)
    k = length(coords)
    E = zeros(n, k)
    for (i, c) in enumerate(coords)
        E[c, i] = 1.0
    end
    substitute(v) = x + E * (v - x[coords])
    obj = Objective(v -> model.objective(substitute(v)))
    eq_constraints = VectorOfFunctions(
        map(
            c -> EqConstraint(v -> c(substitute(v)), 0.0, c.dim, c.flags),
            model.eq_constraints.fs,
        ),
    )
    ineq_constraints = VectorOfFunctions(
        map(
            c -> IneqConstraint(v -> c(substitute(v)), 0.0, c.dim, c.flags),
            model.ineq_constraints.fs,
        ),
    )
    sd_constraints = VectorOfFunctions(
        map(c -> SDConstraint(v -> c(substitute(v)), c.dim), model.sd_constraints.fs)
    )
    return VecModel(
        obj,
        eq_constraints,
        ineq_constraints,
        sd_constraints,
        model.box_min[coords],
        model.box_max[coords],
        x[coords],
        model.integer[coords],
    )
end

function optimize!(workspace::RCDWorkspace)
    @unpack model, sub_alg, options = workspace
    n = length(workspace.x)
    for iter in 1:options.maxiter
        ncoord = if options.ncoords === nothing
            clamp(round(Int, options.fraction * n), 1, n)
        else
            clamp(options.ncoords, 1, n)
        end
        coords = randperm(n)[1:ncoord]
        sub_model = rcd_submodel(model, workspace.x, coords)
        sub_result = if options.sub_options === nothing
            optimize(sub_model, sub_alg, workspace.x[coords])
        else
            optimize(sub_model, sub_alg, workspace.x[coords]; options=options.sub_options)
        end
        workspace.x[coords] .= sub_result.minimizer
        objective = NonconvexCore.getobjective(model)
        objective === nothing && throw(ArgumentError("The model has no objective."))
        workspace.f = objective(workspace.x)
        workspace.iter = iter
        options.verbose && @info "RCD iteration $iter: objective = $(workspace.f)"
    end
    return RCDResult(workspace.f, copy(workspace.x))
end
