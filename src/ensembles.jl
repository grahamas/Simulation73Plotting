
function sweep_2D_slice_heatmaps(fig::Figure, A::NamedDimsArray, A_dims::NamedTuple; 
                       plot_color = :magma, title = "FILLER")
    mod_names = [string(name) for name in keys(A_dims)]
    mod_values = values(A_dims)
    all_dims = 1:length(mod_names)
    slices_2d = IterTools.subsets(all_dims, Val{2}())
    #plot_side_size = 350 * (length(all_dims) - 1)
    #plot_size = (plot_side_size, plot_side_size)
    layout = GridLayout()

    heatmaps = map(slices_2d) do (x,y)
        (x,y) = x < y ? (x,y) : (y,x)
        collapsed_dims = Tuple(setdiff(all_dims, (x,y)))
        mean_values = avg_across_dims(A, collapsed_dims)
        my = mod_values[y] |> collect
        mx = mod_values[x] |> collect
        
        @assert size(mean_values) == length.((mod_values[x], mod_values[y]))
        
        layout[x,y] = ax = MakieLayout.Axis(fig); 
        tightlimits!(ax)
        heatmap!(ax, my, mx, parent(mean_values)', colorrange=(0,1), color=plot_color)
            #xlab=mod_names[y], ylab=mod_names[x], color=plot_color, title="prop epileptic"),
    end
    layout[:,1] = Label.(Ref(fig), mod_names[1:end-1], tellheight=false, rotation=pi/2)
    layout[end+1,2:end] = Label.(fig, mod_names[2:end], tellwidth=false)
    layout[0, :] = Label(fig, title, textsize = 30)
    cbar = layout[2:end-1, end+1] = Colorbar(fig, heatmaps[1], label = "Proportion classified")
    cbar.width = 25
    return layout
end

