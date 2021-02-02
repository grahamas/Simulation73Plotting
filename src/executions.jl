
function heatmap_slices_execution(exec::AbstractExecution, n_slices=5, resolution=(1600,1200)
                                 ; max_ts = 1000, max_xs = 1000)
    scene, layout = layoutscene(resolution=resolution)
    
    # adding timepoint slices
    soln = exec.solution
    t = soln.t
    xs = frame_xs(exec)
    pop_names = exec.simulation.model.pop_names
    pop_idxs = 1:length(pop_names)
    
    n_x, n_p, n_t = size(soln)
    step = (length(soln.t)) ÷ n_slices
    t_idxs = 2:step:length(soln.t)
    
    hm_axes = [LAxis(scene, title = "$pop_name activity", aspect=1.0) for pop_name in pop_names]
    t_idx_subs = 1:max(1,(length(t) ÷ max_ts)):length(t) 
    xs_idx_subs = 1:max(1,(length(xs) ÷ max_xs)):length(xs) 
    heatmaps = map(1:length(pop_names)) do idx_pop
        ax = hm_axes[idx_pop]
        pop_activity = cat(population.(soln.u, idx_pop)..., dims=2)
        heatmap!(ax, t[t_idx_subs], xs[xs_idx_subs], parent(pop_activity[xs_idx_subs,t_idx_subs])')
    end
    tightlimits!.(hm_axes)
    linkaxes!(hm_axes...)
    hideydecorations!.(hm_axes[2:end])
    
    layout[2,pop_idxs] = map(pop_idxs) do pop_idx
        slices_layout = GridLayout(rowsizes=[Auto()], alignmode=Outside(10), tellheight=true)
        slice_axes = slices_layout[:h] = map(t_idxs) do t_idx
            ax = LAxis(scene, aspect=1.0, tellheight=true)
            lines!(ax, xs[xs_idx_subs], soln[xs_idx_subs,pop_idx,t_idx])
            tightlimits!(ax)
            hideydecorations!(ax)
            hidexdecorations!(ax)
            ax
        end
        linkaxes!(slice_axes...)
        slices_layout[2,1:length(t_idxs)] = [LText(scene, "t=$(round(time, digits=1))", textsize=14, tellwidth=false) for time in t[t_idxs]]
        trim!(slices_layout)
        slices_layout        
    end
    layout[1,pop_idxs] = hm_axes
    cbar = layout[1, end+1] = LColorbar(scene, heatmaps[1], label = "Activity Level")
    cbar.width = 25

    ylabel = layout[:,0] = LText(scene, "space (μm)", rotation=pi/2, tellheight=false)
    xlabel = layout[end+1,2:3] = LText(scene, "time (ms)")
    return (scene, layout)
end

function animate_execution(filename::AbstractString, execution::AbstractFullExecution{T,<:Simulation{T,M}}; fps=20, kwargs...) where {T, M<:AbstractModel{T,1}}
    @show "extracting variables"
    solution = execution.solution
    pop_names = execution.simulation.model.pop_names
    x = coordinate_axes(Simulation73.reduced_space(execution))[1]
    t = timepoints(execution)
    max_val = maximum(solution)
	min_val = minimum(solution)
    
    scene, layout = layoutscene();
    time_idx_node = Node(1)
    single_pop = lift(idx -> population_timepoint(solution, 1, idx), time_idx_node)
    title = lift(idx -> "t = $(t[idx])", time_idx_node)
    ax = layout[1,1] = LAxis(scene, title=title)
    lines!(ax, x, single_pop)
    @show single_pop
    @show x
    @show (min_val, max_val)
    ylims!(ax, (min_val, max_val))
    
    @show "animating $(length(t)) frames"
    record(scene, filename, 1:length(t); framerate=fps) do time_idx # TODO @views
        @show time_idx
        time_idx_node[] = time_idx
    end
end

# function animate_execution(filename::AbstractString, execution::AbstractFullExecution{T,<:Simulation{T,M}}; fps=20, kwargs...) where {T, M<:AbstractModel{T,2}}
#     solution = execution.solution
#     pop_names = execution.simulation.model.pop_names
#     x,y = coordinate_axes(Simulation73.reduced_space(execution))
#     t = timepoints(execution)
#     max_val = maximum(solution)
# 	min_val = minimum(solution)
    
#     scene, layout = layoutscene();
#     time_idx_node = Node(1)
#     single_pop = lift(idx -> population_timepoint(solution, 1, idx), time_idx_node)
#     title = lift(idx -> "t = $(t[idx])", time_idx_node)
#     @assert size(single_pop[]) == (length(x), length(y))
#     # layout[1,1] = LText(scene, title, tellwidth=false)
#     layout[1,1] = ax = LAxis(scene, title=title)
#     heatmap!(ax, x, y, single_pop, colorrange=(min_val,max_val))
    
#     record(scene, filename, 1:length(t); framerate=fps) do time_idx # TODO @views
#         time_idx_node[] = time_idx
#     end
# end

function exec_heatmap(exec::AbstractExecution; kwargs...)
    scene, layout = layoutscene(resolution=(600, 1200))
    layout[1,1] = exec_heatmap!(scene, exec; kwargs...)
    trim!(layout)
    return scene
end

function exec_heatmap!(scene::Scene, exec::AbstractExecution;
        no_labels=false, title=nothing, colorbar_width=25, axis_kwargs=Dict(), kwargs...)
    layout = GridLayout()
    soln = exec.solution
    t = soln.t
    xs = coordinate_axes(Simulation73.reduced_space(exec))[1] |> collect
    pop_names = exec.simulation.model.pop_names

    hm_axes = layout[1:length(pop_names), 1] = [LAxis(scene; axis_kwargs...) for pop_name in pop_names]
    u_max = maximum(maximum.(soln.u))
    u_min = minimum(minimum.(soln.u))
    clims = if u_max == u_min
        if 0. ≤ u_max ≤ 1.
            [0., 1.]
        else
            [clims-0.5, clims+0.5]
        end
    else
        [min(0., u_min), u_max]
    end
    heatmaps = map(1:length(pop_names)) do idx_pop
        ax = hm_axes[idx_pop]
        pop_activity = cat(population.(soln.u, idx_pop)..., dims=2)
        htmp = heatmap!(ax, t, xs, parent(pop_activity)'; colorrange=clims, kwargs...)
        ax.xticks = [0, floor(Int,t[end])]
        htmp
    end
    tightlimits!.(hm_axes)
    linkaxes!(hm_axes...)
    hideydecorations!.(hm_axes)#[2:end])
    hidexdecorations!.(hm_axes[1:end-1])

    cbar = layout[length(pop_names),2] = LColorbar(scene, heatmaps[begin], width=colorbar_width, vertical=true)

    if title !== nothing
        layout[0,:] = LText(scene, title, tellwidth=false)
    end
  
    if !no_labels
        ylabel = layout[2,0] = LText(scene, "space (μm)", rotation=pi/2, tellheight=false)
        xlabel = layout[end+1,2] = LText(scene, "time (ms)", tellwidth=false)
    end
    return layout
end 

