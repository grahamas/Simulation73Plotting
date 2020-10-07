module Simulation73Plotting

using Simulation73

using AbstractPlotting, AbstractPlotting.MakieLayout
using Makie

using AxisIndices
using IterTools

include("reducing.jl")
export mean_skip_missing,
       avg_across_dims

include("executions.jl")
export heatmap_slices_execution, animate_execution,
    exec_heatmap, exec_heatmap!,
    exec_heatmap_slices

include("ensembles.jl")
export sweep_2D_slice_heatmaps


end # module
