module LuxorLabels
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, boxdiagonal, Point, +
export labels_prominent

"""
    labels_prominent(f, labels, anchors, pris; crashpadding = 1.05, anchor = "left") \n
    labels_prominent(f, labels, anchors::T, pris; crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number} \n
    --> selected_indexes, selected_padding_bounding_boxes

`f` is user's label plotting function taking three variables:

    - `label`
    - `pos`
    - `pri`

`labels`        Strings to send to f one by one if selected
'anchors'          Positions to send to f one by one if selected. Elements should behave like Point, 
                but may well be points on a line.
                If a vector of numbers, will be interpreted as horizontally distributed points: `Point.(anchors, zero(eltype(anchors)))` 
'pris'          Priorities. '1' is higher priority than '2'.
'crashpadding'  Keyword argument, default 1.05. Increases bounding boxes around labels by this factor. 
                Can also be given as a vector of individual scaling factor. 
                Centre of the scaling is the centre of each bounding box.
'anchor'        Keyword argument, default "left'". For right-aligning, set to "right", which means
                that the bounding box is mirrored around the anchor point compared to the default. 
                A right-aligned anchor point will be on the right lower edge of the bounding box.

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
function labels_prominent(f, labels, anchors, pris; 
        crashpadding = 1.05, anchor = "left")
    if ! (length(labels) == length(anchors) == length(pris)) 
        throw(ArgumentError("Vectors have unequal length: $(length(labels))  $(length(anchors))  $(length(pris))"))
    end
    if length(crashpadding) !== 1 && length(scalefactor) !== length(labels)
        throw(ArgumentError("Vectors have unequal length: $(length(labels))  $(length(anchors))  $(length(pris)) $(length(crashpadding))"))
    end
    @assert anchor == "left" || anchor == "right"
    # The boundingboxes of all placed and padded labels (were that possible).
    # Multiplication scales from the centre of the box.
    # Note that keyword `crashpadding` could also be a vector, for more detailed control.
    bbs = crash_padded_boundingboxes(labels, anchors, crashpadding)
    Δps = zero(anchors)
    if anchor == "right"
        bbs, Δps = mirror_box_around_anchor(bbs, anchors)
    end
    # Which of these are most interesting and can fit without intersecting?
    it = boundingboxes_select_non_intersecting_by_priority_then_order(bbs, pris) 
    sel_lbs = labels[it]
    sel_Δps = Δps[it]
    sel_p = anchors[it]
    sel_anchors = sel_p .+ sel_Δps
    sel_pris = pris[it]
    selected_labels_broadcast_f(f, sel_lbs, sel_anchors, sel_pris)
    it, bbs[it]
end
function labels_prominent(f, labels, anchors::T, pris; 
        crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number}
    ps = Point.(anchors, zero(eltype(anchors)))
    labels_prominent(f, labels, ps, pris; crashpadding, anchor)
end

"""
    crash_padded_boundingboxes(labels, anchors, crashpadding)
    --> Vector{BoundingBox}

The boundingboxes of all placed and padded labels (were that possible).
Multiplication scales from the centre of the box.
Note that `crashpadding` can also be a vector of factors, for more detailed control.
"""
function crash_padded_boundingboxes(labels, anchors, crashpadding)
    bbo = BoundingBox.(labels) .* crashpadding
    # Adding a point to a boundingbox does not move the boundingbox.
    # Me must do that corner by corner
    map(zip(bbo, anchors)) do (bb, p)
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


function mirror_box_around_anchor(bbs::Vector{BoundingBox}, anchors::Vector{Point})
    @assert length(bbs) == length(anchors)
    mbbs = similar(bbs)
    Δp_anchors = similar(anchors)
    for (i, (bb, anchor)) in enumerate(zip(bbs, anchors))
        mbbs[i], Δp_anchors[i] = mirror_box_around_anchor(bb, anchor)
    end
    mbbs, Δp_anchors
end
function mirror_box_around_anchor(bb::BoundingBox, anchor::Point)
    xl = anchor.x - bb.corner1.x
    xr = bb.corner2.x - anchor.x
    c1x = anchor.x - xr
    c2x = anchor.x + xl
    BoundingBox(Point(c1x, bb.corner1.y), Point(c2x, bb.corner2.y)), Point(xl - xr, 0.0)
end

end # Module