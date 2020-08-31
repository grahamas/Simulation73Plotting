
function mean_skip_missing(A::AbstractArray; dims)
    missings = ismissing.(A)
    zeroed = copy(A)
    zeroed[missings] .= 0
    nonmissingsum = sum(zeroed; dims=dims)
    nonmissingmean = nonmissingsum ./ sum(.!missings; dims=dims)
    return nonmissingmean
end

function avg_across_dims(arr, dims)
    avgd = mean_skip_missing(arr, dims=dims)
    squeezed = dropdims(avgd, dims=dims)
    return squeezed
end
