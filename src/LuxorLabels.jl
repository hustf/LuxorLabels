module LuxorLabels
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, boxdiagonal, Point
export labels_prominent

"""
    labels_prominent(f, labels::T1, poss::T2, pris::T3; crashpadding = 1.05) where {T1, T2, T3 <: Vector} \n
    --> selected_indexes, selected_padding_bounding_boxes

`f` is user's label plotting function taking three variables:

    - `label`
    - `pos`
    - `pri`

`labels`        Strings to send to f one by one if selected
'poss'          Positions to send to f one by one if selected. Elements should behave like Point, 
                but may well be points on a line.
                If a vector of numbers, will be interpreted as horizontally distributed points: `Point.(poss, zero(eltype(poss)))` 
'pris'          Priorities. '1' is higher priority than '2'.
'crashpadding'  Keyword argument, default 1.05. Increases bounding boxes around labels by this factor. 
                Can also be given as a vector of individual scaling factor. 
                Centre of the scaling is the centre of each bounding box.

Intention:

    - Prioritize between labels. 
    - Display (the selected) labels by calling f
    - Lower priority (selected) labels are plotted first (at "bottom"). This has a possible visual effect
      if 'f' adds textboxes or other graphics around the text, outside of 'textentents' bounding boxes.
      Higher priority labels will never be partially covered by lower priority labels.
    - Labels have prominence (are selected) if:

      1) All higher priority labels have been checked. Equal priority labels are checked in the order given.
      2) There is still room: We use 'textextents' multiplied by chrashpadding to 
        check if there is. Text extents are found using the current text configuration at the time of
        call. Thus, you may change e.g. font size in `f` based on `pri`, but this has no effect on 
        the label's expected bounding box. And you cannot configure different text direction in 'f' based on 
        pri: There is only one text direction, one alignment, etc.

Use case:
    - While displaying a ruler, priorize showing "10" over "8", and "8" over "7.5". 
    - While displaying a map, prioritize showing capital cities over street names.
    - While displaying a train schedule, prioritize end stops.
"""
function labels_prominent(f, labels, poss, pris; crashpadding = 1.05) #where {T1, T2, T3 <: Vector}
    if ! (length(labels) == length(poss) == length(pris)) 
        throw(ArgumentError("Vectors have unequal length: $(length(labels))  $(length(poss))  $(length(pris))"))
    end
    if length(crashpadding) !== 1 && length(scalefactor) !== length(labels)
        throw(ArgumentError("Vectors have unequal length: $(length(labels))  $(length(poss))  $(length(pris)) $(length(crashpadding))"))
    end
    # The boundingboxes of all placed and padded labels (were that possible).
    # Multiplication scales from the centre of the box.
    # Note that keyword `crashpadding` could also be a vector, for more detailed control.
    bbs = crash_padded_boundingboxes(labels, poss, crashpadding)
    # Which of these are most interesting and can fit without intersecting?
    it = boundingboxes_select_non_intersecting_by_priority_then_order(bbs, pris) 
    sel_lbs = labels[it]
    sel_pos = poss[it]
    sel_pris = pris[it]
    selected_labels_broadcast_f(f, sel_lbs, sel_pos, sel_pris)
    it, bbs[it]
end
function labels_prominent(f, labels, poss::T, pris; crashpadding = 1.05) where T<:Vector{<:Number}
    ps = Point.(poss, zero(eltype(poss)))
    labels_prominent(f, labels, ps, pris; crashpadding)
end

"""
    crash_padded_boundingboxes(labels, poss, crashpadding)
    --> Vector{BoundingBox}

The boundingboxes of all placed and padded labels (were that possible).
Multiplication scales from the centre of the box.
Note that `crashpadding` can also be a vector of factors, for more detailed control.
"""
function crash_padded_boundingboxes(labels, poss, crashpadding)
    bbo = BoundingBox.(labels) .* crashpadding
    # Adding a point to a boundingbox does not move the boundingbox.
    # Me must do that corner by corner
    map(zip(bbo, poss)) do (bb, p)
        BoundingBox(bb.corner1 + p, bb.corner2 + p)
    end
end

"""
    boundingboxes_select_non_intersecting_by_priority_then_order(boundingboxes::T2, pris::T3) where {T3 <: Vector, T2 <: Vector{BoundingBox}}

    --> Indexes of boundingboxes (& other collections) 
"""
function boundingboxes_select_non_intersecting_by_priority_then_order(boundingboxes::T2, pris::T3) where {T3 <: Vector, T2 <: Vector{BoundingBox}}
    p = sortperm(pris)
    sel = boundingboxes_select_non_intersecting_by_order(boundingboxes[p])
    p[sel]
end

"""
    boundingboxes_select_non_intersecting_by_order(sorted_boundingboxes::T) where T

Return the index of boundingboxes which can be placed in the given order 
without any overlapping already placed boxes. 

If no overlap, returns [1..length(sorted_boundingboxes)]
As a minimum, returns [1]
"""
function boundingboxes_select_non_intersecting_by_order(sorted_boundingboxes::T) where T
    sel_bbs = T()
    selected = Int64[]
    for (i, b) in enumerate(sorted_boundingboxes)
        if i == 1 || ! is_colliding(b, sel_bbs)
            push!(sel_bbs, b)
            push!(selected, i)
        end 
    end
    selected
end

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
    selected_labels_broadcast_f(f, sel_lbs, sel_bbs, sel_pris)

Calls 'f' with three corresponding arguments.
Returns output as a vector (output is for checking purposes, 'f' should plot the label)
"""
function selected_labels_broadcast_f(f, sel_lbs, sel_bbs, sel_pris)
    it = zip(reverse(sel_lbs), reverse(sel_bbs), reverse(sel_pris))
    map(it) do (l, b, p)
        f(l, b, p)
    end
end

end # Module