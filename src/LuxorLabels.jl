module LuxorLabels
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, boxdiagonal, Point, +
export broadcast_prominent_labels_to_plotfunc, broadcast_all_labels_to_plotfunc

"""
    broadcast_prominent_labels_to_plotfunc(f, txtlabels, anchors, pris; crashpadding = 1.05, anchor = "left") \n
    broadcast_prominent_labels_to_plotfunc(f, txtlabels, anchors::T, pris; crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number} \n
    --> selected_indexes, selected_padding_bounding_boxes

`f` is user's label plotting function taking three variables:

    - `label`
    - `pos`
    - `pri`

`txtlabels`        Strings to send to f one by one if selected 
'anchors'       Positions to send to f one by one if selected. Elements should behave like Point, 
                but may well be points on a line.
                If a vector of numbers, will be interpreted as horizontally distributed points: `Point.(anchors, zero(eltype(anchors)))` 
'pris'          Priorities. '1' is higher priority than '2'.
'crashpadding'  Keyword argument, default 1.05. Increases bounding boxes around txtlabels by this factor. 
                Can also be given as a vector of individual scaling factor. 
                Centre of the scaling is the centre of each bounding box.
'anchor'        Keyword argument, default "left'". For right-aligning, set to "right", which means
                that the bounding box is mirrored around the anchor point compared to the default. 
                A right-aligned anchor point will be on the right lower edge of the bounding box.

Intention:

    - Prioritize between txtlabels. 
    - Display (the selected non-overlapping) labels by calling f
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
function broadcast_prominent_labels_to_plotfunc(f, txtlabels, anchors, pris; 
        crashpadding = 1.05, anchor = "left")
    if ! (length(txtlabels) == length(anchors) == length(pris)) 
        throw(ArgumentError("Vectors have unequal length: $(length(txtlabels))  $(length(anchors))  $(length(pris))"))
    end
    if length(crashpadding) !== 1 && length(pris) !== length(txtlabels)
        throw(ArgumentError("Vectors have unequal length: $(length(txtlabels))  $(length(anchors))  $(length(pris)) $(length(crashpadding))"))
    end
    @assert anchor == "left" || anchor == "right"
    # The boundingboxes of all placed and padded labels (were that possible).
    # Multiplication scales from the centre of the box.
    # Note that keyword `crashpadding` could also be a vector, for more detailed control.
    # (not tested so far)
    it, sel_bbs, sel_lbs, sel_anchors, sel_pris = non_overlapping_labels_data(txtlabels, anchors, pris; 
        crashpadding, anchor)
    # Plot the selected and adjusted data.
    labels_broadcast_plotfunc(f, sel_lbs, sel_anchors, sel_pris)
    it, sel_bbs
end
function broadcast_prominent_labels_to_plotfunc(f, txtlabels, anchors::T, pris; 
        crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number}
    ps = Point.(anchors, zero(eltype(anchors)))
    broadcast_prominent_labels_to_plotfunc(f, txtlabels, ps, pris; crashpadding, anchor)
end

"""
    non_overlapping_labels_data(txtlabels, anchors, pris; 
    crashpadding = 1.05, anchor = "left")
    ---> it           Indexes of input labels which can be shown without overlap. Reordered by prominence.
         adj_bbs      Adjusted boundary boxes. Adjustments depend on anchor right or left.
         sel_lbs      Labels which can be shown without overlap. Reordered by prominence.
         sel_anchors  Position of anchors, depending on anchor right or left. Can be 2d points or 1d numbers.
         sel_pris     The prominence of the selected labels.

    
See 'broadcast_prominent_labels_to_plotfunc for input arguments.
"""
function non_overlapping_labels_data(txtlabels, anchors, pris; 
    crashpadding = 1.05, anchor = "left")
    # The boundingboxes of all placed and padded labels (were that possible).
    # Multiplication scales from the centre of the box.
    # Note that keyword `crashpadding` could also be a vector, for more detailed control.
    # Note that keyword `crashpadding` could also be a vector, for more detailed control.
    bbs = crash_padded_boundingboxes(txtlabels, anchors, crashpadding)
    Δps = zero(anchors)
    if anchor == "right"
        bbs, Δps = mirror_box_around_anchor(bbs, anchors)
    end
    # Which of these are most interesting and can fit without intersecting?
    it = boundingboxes_select_non_overlapping_by_priority_then_order(bbs, pris)
    sel_lbs = txtlabels[it]
    sel_Δps = Δps[it]
    sel_p = anchors[it]
    sel_anchors = sel_p .+ sel_Δps
    sel_pris = pris[it]
    sel_bbs = bbs[it]
    adj_bbs = map(zip(sel_bbs, sel_Δps)) do (bb, Δp)
        BoundingBox(bb.corner1 + Δp, bb.corner2 + Δp)
    end
    it, adj_bbs, sel_lbs, sel_anchors, sel_pris
end


"""
    crash_padded_boundingboxes(txtlabels, anchors, crashpadding)
    --> Vector{BoundingBox}

The boundingboxes of all placed and padded labels (were that possible).
Multiplication scales from the centre of the box.
Note that `crashpadding` can also be a vector of factors, for more detailed control.
"""
function crash_padded_boundingboxes(txtlabels, anchors, crashpadding)
    bbo = BoundingBox.(txtlabels) .* crashpadding
    # Adding a point to a boundingbox does not move the boundingbox.
    # Me must do that corner by corner
    map(zip(bbo, anchors)) do (bb, p)
        BoundingBox(bb.corner1 + p, bb.corner2 + p)
    end
end

"""
    boundingboxes_select_non_overlapping_by_priority_then_order(boundingboxes::T2, pris::T3) where {T3 <: Vector, T2 <: Vector{BoundingBox}}

    --> Indexes of boundingboxes (& other collections) 
"""
function boundingboxes_select_non_overlapping_by_priority_then_order(boundingboxes::T2, pris::T3) where {T3 <: Vector, T2 <: Vector{BoundingBox}}
    p = sortperm(pris)
    sel = boundingboxes_select_non_overlapping_by_order(boundingboxes[p])
    p[sel]
end

"""
    boundingboxes_select_non_overlapping_by_order(sorted_boundingboxes::T) where T

Return the index of boundingboxes which can be placed in the given order 
without any overlapping already placed boxes. 

If no overlap, returns [1..length(sorted_boundingboxes)]
As a minimum, returns [1]
"""
function boundingboxes_select_non_overlapping_by_order(sorted_boundingboxes::T) where T
    sel_bbs = T()
    selected = Int64[]
    for (i, b) in enumerate(sorted_boundingboxes)
        if i == 1 || ! is_colliding(b, sel_bbs)
            push!(sel_bbs, b)
            push!(selected, i)
        end 
    end
    if length(selected) < length(sorted_boundingboxes)
        @debug "Selected $(length(selected)) of $(length(sorted_boundingboxes)) non-overlapping labels"
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
    labels_broadcast_plotfunc(f, sel_lbs, sel_bbs, sel_pris)

Calls 'f' with three corresponding arguments.
Returns output as a vector (output is for checking purposes, 'f' should plot the label)
"""
function labels_broadcast_plotfunc(f, sel_lbs, sel_bbs, sel_pris)
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

"""
    broadcast_all_labels_to_plotfunc(f, txtlabels, anchors, pris; 
        crashpadding = 1.05, anchor = "left")
    broadcast_all_labels_to_plotfunc(f, txtlabels, anchors::T, pris; 
        crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number}
    --> selected_indexes, selected_padding_bounding_boxes


Primarily for problem-solving or for manual nudging of labels. 
Plot all labels regardless of overlapping. A roughly similar output 
may be achieved by setting `crashpadding` to zero or close to zero.
"""
function broadcast_all_labels_to_plotfunc(f, txtlabels, anchors, pris; 
        crashpadding = 1.05, anchor = "left")
    if ! (length(txtlabels) == length(anchors) == length(pris)) 
        throw(ArgumentError("Vectors have unequal length: $(length(txtlabels))  $(length(anchors))  $(length(pris))"))
    end
    if length(crashpadding) !== 1 && length(pris) !== length(txtlabels)
        throw(ArgumentError("Vectors have unequal length: $(length(txtlabels))  $(length(anchors))  $(length(pris)) $(length(crashpadding))"))
    end
    @assert anchor == "left" || anchor == "right"
    bbs = crash_padded_boundingboxes(txtlabels, anchors, crashpadding)
    Δps = zero(anchors)
    if anchor == "right"
        bbs, Δps = mirror_box_around_anchor(bbs, anchors)
    end
    adj_anchors = anchors .+ Δps
    # Plot the selected and adjusted data.
    labels_broadcast_plotfunc(f, txtlabels, adj_anchors, pris)
    1:length(txtlabels), bbs
end
function broadcast_all_labels_to_plotfunc(f, txtlabels, anchors::T, pris; 
        crashpadding = 1.05, anchor = "left") where T<:Vector{<:Number}
    ps = Point.(anchors, zero(eltype(anchors)))
    broadcast_all_labels_to_plotfunc(f, txtlabels, ps, pris; crashpadding, anchor)
end



end # Module