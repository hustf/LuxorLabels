# Overlap, prominence, order...


"""
    is_colliding(bb, bbs) --> Bool

true if boundingbox b overlaps any of the boundingboxes in sel_bbs.
"""
function is_colliding(bb, bbs::Vector{T}) where T<: BoundingBox
    for bbe in bbs
        if boundingboxesintersect(bb, bbe)
            return true
        end
    end
    false
end
is_colliding(bb1, bb2) = boundingboxesintersect(bb1, bb2)

"""
    non_overlapping_indexes_by_prominence_then_order(boundingboxes, labels)
    non_overlapping_indexes_by_prominence_then_order(boundingboxes, prominence::Vector{Float64})
    ---> Vector{Int64}

Picks a non-overlapping subset of indexes for the input collections.
"""
function non_overlapping_indexes_by_prominence_then_order(boundingboxes, labels)
    @assert length(boundingboxes) == length(labels)
    prominence = getfield.(labels, :prominence)
    non_overlapping_indexes_by_prominence_then_order(boundingboxes, prominence)
end
function non_overlapping_indexes_by_prominence_then_order(boundingboxes, prominence::Vector{Float64})
    @assert length(boundingboxes) == length(prominence)
    # The order of indices that places high prominence (i.e. 1) first
    p = sortperm(prominence)
    boundingboxes_by_prominence = boundingboxes[p]
    indexes_in_bbs_by_prom = non_overlapping_indexes_by_order(boundingboxes_by_prominence)
    # Return the indices in boundingboxes
    p[indexes_in_bbs_by_prom]
end

"""
    non_overlapping_indexes_by_order(sorted_boundingboxes::Vector{T}) where T <: BoundingBox
    ---> Vector{Int64}

Return the index of boundingboxes which can be placed in the given order 
without any overlapping previous boundingboxes.

If no overlap, returns 1..length(sorted_boundingboxes).

As a minimum, returns [1].
"""
function non_overlapping_indexes_by_order(sorted_boundingboxes::Vector{T}) where T <: BoundingBox
    # What we have picked so far
    selected_boundingboxes = T[]
    selected_indexes = Int64[]
    for (i, b) in enumerate(sorted_boundingboxes)
        if i == 1 || ! is_colliding(b, selected_boundingboxes)
            # We can select this one without crashing with the previously selected boxes
            push!(selected_boundingboxes, b)
            push!(selected_indexes, i)
        end 
    end
    if length(selected_indexes) < length(sorted_boundingboxes)
        @debug "Selected $(length(selected_indexes)) of $(length(sorted_boundingboxes)) non-overlapping bounding boxes"
    end
    selected_indexes
end