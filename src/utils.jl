# Helper functions that may be used from here or there

model_x_to_paper_x(Ox_model_in_paper_space, model_to_paper_scale, x) = Ox_model_in_paper_space + (x * model_to_paper_scale)
model_y_to_paper_y(Oy_model_in_paper_space, model_to_paper_scale, y) = Oy_model_in_paper_space + (y * model_to_paper_scale)
paper_x_to_model_x(Ox_model_in_paper_space, model_to_paper_scale, paper_x) = (paper_x - Ox_model_in_paper_space) / model_to_paper_scale
paper_y_to_model_y(Oy_model_in_paper_space, model_to_paper_scale, paper_y) = (paper_y - Oy_model_in_paper_space) / model_to_paper_scale

"""
    wrap_to_two_words_per_line(text::String)
    ---> String

# Example
```
julia> RouteMap.wrap_to_two_words_per_line("Un dau tri, pedwar\n pump") |> println
Un dau
tri, pedwar
pump

julia> RouteMap.wrap_to_two_words_per_line("Un\n dau tri, pedwar pump") |> println
Un dau
tri, pedwar
pump
```
"""
function wrap_to_two_words_per_line(text::String)
    words = split(text)
    wrapped_text = ""
    for i in 1:length(words)
        wrapped_text *= words[i]
        if i < length(words)
            if i % 2 == 0
                wrapped_text *= "\n"
            else
                wrapped_text *= " "
            end
        end
    end
    return wrapped_text
end


"""
    height_of_toy_font()
    ---> Float64

This depends on the current 'Toy API' text size, and can be changed with
fontsize(fs). 

# Example
```
julia> height_of_toy_font()
9.0
```
"""
height_of_toy_font() = textextents("|")[4]

"""
    width_of_toy_string(s::String)
    ---> Float64

# Example
```
julia> width_of_toy_string("1234")
26.0
```
"""
width_of_toy_string(s::String) = textextents(s)[3]


"""
    is_colliding(bb, bbs) --> Bool

true if boundingbox b overlaps any of the boundingboxes in sel_bbs.
"""
function is_colliding(bb, bbs)
    for bbe in bbs
        if boundingboxesintersect(bb, bbe)
            return true
        end
    end
    false
end

"""
    check_kwds(;kwds...)
    ---> true

Simple check for common syntax error. 
"""
function check_kwds(;kwds...)
    if !isempty(kwds)
        if first(kwds)[1] == :kwds
            throw(ArgumentError("Optional keywords: Use splatting in call: ;kwds..."))
        end
    end
    true
end



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