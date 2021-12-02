module Simulation73Plotting

using Simulation73

using Makie, Makie.MakieLayout

using NamedDims

using IterTools

include("reducing.jl")
export mean_skip_missing,
       avg_across_dims

include("executions.jl")
export heatmap_slices_execution, animate_execution,
    exec_heatmap, exec_heatmap!, isolimit_exec_heatmaps!,
    exec_heatmap_slices

include("ensembles.jl")
export sweep_2D_slice_heatmaps

end # module
