# Interfaces. These call 'label_general' with keywords.
# `bounding_boxes_all_at_given_offset`
# `label_all_at_given_offset`
# `label_all_optimize_vertical_offset`
# `label_all_optimize_horizontal_offset`
# `label_all_optimize_offset`
# `label_prioritized_at_given_offset`
# `label_prioritized_optimize_vertical_offset`
# `label_prioritized_optimize_horizontal_offset`
# `label_prioritized_optimize_offset`

"""
    bounding_boxes_all_at_given_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Don't plot labels
- Return bounding boxes of all labels

"""
function bounding_boxes_all_at_given_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_vert = false, 
                    optim_horiz = false,
                    prioritize = false,
                    plot = false,
                    kwds...)
end

"""
    label_prioritized_at_given_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Drop labels overlapped by others based on prominence and order.
"""
function label_prioritized_at_given_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_vert = false, 
                    optim_horiz = false,
                    kwds...)
end

"""
    label_prioritized_optimize_vertical_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Optimize offset: up or down.
- Drop labels overlapped by others based on prominence and order.
"""
function label_prioritized_optimize_vertical_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_horiz = false,
                    kwds...)
end



"""
    label_prioritized_optimize_horizontal_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Optimize offset: left or right.
- Drop labels overlapped by others based on prominence and order.
"""
function label_prioritized_optimize_horizontal_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_vert = false, 
                    kwds...)
end

"""
    label_prioritized_optimize_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Most powerful / abstract.
- Optimize offset up, down, right, left. 
- Drop labels overlapped by others based on prominence and order.
"""
function label_prioritized_optimize_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; kwds...)
end



"""
    label_all_at_given_offset(;  kwds...)
    ---> prioritized_indexes, boundary boxes

- Most simple.
- Plot all labels at default / specified offset.
"""
function label_all_at_given_offset(;  kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_vert = false, 
                    optim_horiz = false,
                    prioritize = false,
                    kwds...)
end


"""
    label_all_optimize_vertical_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Most powerful / abstract.
- Optimize offset: up or down.
"""
function label_all_optimize_vertical_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_horiz = false,
                    prioritize = false,
                    kwds...)
end


"""
    label_all_optimize_horizontal_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Most powerful / abstract.
- Optimize offset: left or right.
"""
function label_all_optimize_horizontal_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; optim_horiz = false,
                    prioritize = false,
                    kwds...)
end


"""
    label_all_optimize_offset(; kwds...)
    ---> prioritized_indexes, boundary boxes

- Optimize offset up, down, right, left. 
"""
function label_all_optimize_offset(; kwds...)
    check_kwds(;kwds...)
    @assert :optim_vert  ∉ keys(kwds)
    @assert :optim_horiz ∉ keys(kwds)
    @assert :prioritize  ∉ keys(kwds)
    @assert :plot        ∉ keys(kwds)
    label_general(; prioritize = false,
                    kwds...)
end





"""
    label_general(; f::Function = plot_label_bounding_box,
    kwds...)
    label_general(f::Function, labels::Vector{LabelPaperSpace}; 
            optim_vert = true, 
            optim_horiz = true,
            prioritize = true,
            plot = true, 
            kwds...)
    ---> prioritized_indexes, boundary boxes

General functional behind interfaces
- `bounding_boxes_all_at_given_offset`
- `label_all_at_given_offset`
- `label_all_optimize_vertical_offset`
- `label_all_optimize_horizontal_offset`
- `label_all_optimize_offset`
- `label_prioritized_at_given_offset`
- `label_prioritized_optimize_vertical_offset`
- `label_prioritized_optimize_horizontal_offset`
- `label_prioritized_optimize_offset`

Default keywords are all true. They specify the most powerful / abstract
functionality. 
"""
function label_general(; f::Function = plot_label_bounding_box,
    kwds...)
    check_kwds(;kwds...)
    # Make a vector of labels from the relevant keywords.
    kwds_labels = filter(kwds) do k
        k[1] ∈ fieldnames(LabelPaperSpace)
    end
    if isempty(kwds_labels) && :labels ∈ keys(kwds)
        labels = kwds[:labels]
    elseif ! isempty(kwds_labels)
        labels = labels_paper_space(;kwds_labels...)
    else
        throw("labels not defined.")
    end
    # Remove the keywords 'labels', we'll pass labels as a normal argument
    kwds_dict = filter(kwds -> kwds[1] != :labels, kwds)
    @assert ! isempty(labels)
    # Isolate the remaining keywords. Those will be
    # passed to the plotting function.
    kwds_plotfunc = setdiff(kwds_dict, kwds_labels)
    label_general(f, labels; kwds_plotfunc...)
end
function label_general(f::Function, labels::Vector{LabelPaperSpace}; 
        optim_vert = true, 
        optim_horiz = true,
        prioritize = true,
        plot = true, 
        kwds...)
    check_kwds(;kwds...)
    @assert ! isempty(labels)
    # Optimize label offset directions for fitting
    # as many labels as possible without overlap.
    # When several optimized solutions exist,
    # prefer the already defined offset direction.
    if optim_vert && optim_horiz
        labels_optimized = optimize_offset_direction!(labels, f, kwds...)
    elseif optim_vert
        labels_optimized = optimize_offset_direction_vertical!(labels, f, kwds...)
    elseif optim_horiz
        labels_optimized = optimize_offset_direction_horizontal!(labels, f, kwds...)
    else
        labels_optimized = labels
    end
    # Boundary boxes of optimized labels
    bbs_optimized = labels_broadcast_plotfunc(f, labels_optimized; noplot = true, kwds...)
    @assert eltype(bbs_optimized) <: BoundingBox "Plotting function must return a BoundingBox. Instead returned: $(eltype(bbs_optimized))"
    # Prioritize labels
    if prioritize
        # If some labels are overlapping after offset optimization,
        # follow rules: 
        # Prominence 1 is preferred over prominence 2 etc.
        # Low index labels (in the vector order) is preferred over high index. 
        prioritized_indexes = non_overlapping_indexes_by_prominence_then_order(bbs_optimized, labels_optimized)
    else
        prioritized_indexes = 1:length(labels_optimized)
    end
    labels_prioritized = labels_optimized[prioritized_indexes]
    bbs_prioritized = bbs_optimized[prioritized_indexes]
    # 
    if ! plot
        return prioritized_indexes, bbs_prioritized
    else
        # When plotting, we do it in reverse order. The most 
        # important labels are plotted last. Thus,
        # lower prominence labels leader lines won't overlap
        # prominent labels.
        return prioritized_indexes, labels_broadcast_plotfunc(f, reverse(labels_prioritized); kwds...)
    end
end



