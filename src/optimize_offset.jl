# TODO: Work on sorted by pri and order label vector.
# If no solution is reached, drop labels from bottom,
# and possibly by identifying which low-pri label 
# is involved in the most constraints.

function optimize_offset_direction_vertical!(labels, f; kwds...)
    check_kwds(;kwds...)
    model = Model(GLPK.Optimizer)
    set_optimizer_attribute(model, "tm_lim", 60 * 1_000)
    set_optimizer_attribute(model, "msg_lev", GLPK.GLP_MSG_OFF)
    # The problem is one of label placement.
    # The number of labels
    n = length(labels)
    # The number of possible offset directions for each label
    m = 2
    # We have a vector of labels. To each assign one row of
    # binary variables. There are m columns in each row.
    # A value of 'true' or '1' at (i, j) indicates that label i
    # offsets it label to position j.
    # Define binary variables
    @variable(model, c[1:n, 1:m], Bin)
    # Each label i must have exactly one offset value j.
    # Each element of the row vector c[i, :] must take exactly one value
    for i in 1:n
        @constraint(model, sum(c[i, :]) == 1)
    end

    # Some positions possibly crashes. Loop over labels and offset directions '(label-direction)'
    # to add one constraint for each possible crash. Each constraint is symmetrical,
    # so not allowing (1-2) to crash with (4-1) also disallows (4-1) crashing with (1-2).
    #
    # A container for storing constraints, because we may need to relieve some constraints,
    # i.e. we may need to allow some labels crashing.
    constraint_by_label_index = Dict{Int64, Vector{JuMP.ConstraintRef}}()
    for i1 in 1:n
        for j1 in 1:m
            # Boundary boxes of text and label anchor
            bb1, bbp1 = boundary_box_of_label_offset_at_direction_no(f, labels[i1], j1; kwds...)
            for i2 in 1:n
                # Skip along because of the constraint symmetry described above.
                i2 <= i1 && continue
                for j2 in 1:m
                    # Boundary boxes potentially colliding text and label anchor
                    bb2, bbp2 = boundary_box_of_label_offset_at_direction_no(f, labels[i2], j2; kwds...)
                    if is_colliding(bb1, bb2) || is_colliding(bb1, bbp2) || is_colliding(bbp1, bb2)
                        constraint_ref = @constraint(model, c[i1, j1] + c[i2, j2] <= 1)
                        store_constraintref_in_dict!(constraint_by_label_index, constraint_ref, i1)
                        store_constraintref_in_dict!(constraint_by_label_index, constraint_ref, i2)
                        @debug "constraint  ($i1, $j1 ) <=> ($i2, $j2)" maxlog = 5
                    end
                end
            end
        end
    end
    # Since we just need to find a feasible solution, no objective function is defined.
    # TODO Consider: Prefer the solution with most offsets in a preferred direction.
    # 
    # If there are no possible label overlaps, there's nothing to optimize
    if ! isempty(constraint_by_label_index)
        # Now try to find a solution. If unsuccessful, drop some (more) constraints.
        tries = 0
        while true
            tries += 1 
            @debug "Optimizing model with " num_constraints(model; count_variable_in_set_constraints = false) 
            @assert num_constraints(model; count_variable_in_set_constraints = false) > n
            optimize!(model)
            # Check if the model has a solution
            @debug termination_status(model)
            if termination_status(model) == MathOptInterface.OPTIMAL
                break
            else
                drop_constraints_for_most_problematic_label!(model, constraint_by_label_index, labels)
            end
            @assert tries < 1000 # May be increased if beneficial...
        end
        solution_c = value.(c)
        # Mutate the labels to match this solution.
        for i in 1:n
            jsol = findfirst(e -> e == 1, solution_c[i, :])
            label_offset_at_direction_no!(labels, i, jsol)
        end
    else
        @debug "No possible label overlab => no offset directions to optimize for"
    end
    labels
end

"""
     boundary_box_of_label_offset_at_direction_no(f, label::LabelPaperSpace, j; kwds...)
    ---> Vector{BoundingBox}

This is called by `optimize_offset_direction_vertical!` and returns TWO bounding boxes: 

- f typically returns one box covering the text of the label.
- Additionally, this returns a 'single point box' covering the label anchor (where it's pointing at)

Reason being, we don't want labels to overlap where other labels are pointing at.

# Example
```
julia> l
LabelPaperSpace(txt                    = "1", 
                prominence             = 3.0,
                x                      = 10.0,
                y                      = 10.0,
                halign                 = :left,
                offset                 = Luxor.Point(-39.0, 52.0),
                fontsize_prominence_1  = 22.0,
                offsetbelow            = true,
                shadowcolor            = RGB{Float64}(0.639101,0.925688,0.971463),
                textcolor              = RGB{Float64}(0.729634,0.613774,0.512),
                leaderline             = false)
julia> using LuxorLabels: boundary_box_of_label_offset_at_direction_no

julia> boundary_box_of_label_offset_at_direction_no(plot_label_bounding_box, l, 1)
( ⤡ Point(-30.0, 52.0) : Point(-24.0, 68.536),  ⤡ Point(10.0, 10.0) : Point(10.0, 10.0))

julia> boundary_box_of_label_offset_at_direction_no(plot_label_bounding_box, l, 2)
( ⤡ Point(-30.0, -52.0) : Point(-24.0, -35.464),  ⤡ Point(10.0, 10.0) : Point(10.0, 10.0))
```
"""
function boundary_box_of_label_offset_at_direction_no(f, label::LabelPaperSpace, j; kwds...)
    check_kwds(;kwds...)
    l = label_offset_at_direction_no(label, j)
    anchor_bb = BoundingBox(Point(l.x, l.y), Point(l.x, l.y))
    if isempty(kwds)
        bb = f(l; noplot = true)
    else
        bb = f(l; kwds..., noplot = true)
    end
    bb, anchor_bb
end

function label_offset_at_direction_no(label::LabelPaperSpace, j; debug = false)
    l = deepcopy(label)
    if j == 1
        # Keep the original (default) offset direction
    elseif j == 2
        # Flip the original (default) offset direction
        debug && @debug "Flipping $(label.txt)"
        l.offsetbelow = ! l.offsetbelow
    else
        throw("unexpected")
    end
    l
end
function label_offset_at_direction_no!(labels, i, j)
    if j == 1
        # Keep the original (default) offset direction
    elseif j == 2
        # Flip the original (default) offset direction
        @debug "Flipping $(labels[i].txt)"
        labels[i].offsetbelow = ! labels[i].offsetbelow
    else
        throw("unexpected")
    end
    labels[i]
end

function store_constraintref_in_dict!(constraint_by_label_index, constraint_ref::T, label_key::Int64) where T
    v = get(constraint_by_label_index, label_key, Vector{T}())
    push!(v, constraint_ref)
    push!(constraint_by_label_index, label_key => v)
    constraint_by_label_index
end


function label_index_to_drop_constraints_for(constraint_by_label_index::Dict{Int, T}, labels) where T
    # We want to find the one index into 'labels' which represents
    # a) Label with constraints
    # b) Label with highest 'prominence' value (i.e. the least important label)
    # c) Label with the largest number of constraints.
    # d) Placed last of these.
    n = length(labels)
    all = 1:n
    # a)
    constrained = filter(all) do i
        v = get(constraint_by_label_index, i, Vector{T}())
        length(v) > 0
    end
    # b)
    # There may be a built-in function which does this, but we do it in two steps.
    max_prom_val = maximum(constrained) do i
        labels[i].prominence
    end
    with_max_prominence = filter(constrained) do i
        labels[i].prominence == max_prom_val
    end
    # c)
    max_no_constraints = maximum(with_max_prominence) do i
        v = get(constraint_by_label_index, i, Vector{T}())
        length(v)
    end
    with_max_no_constraints = filter(with_max_prominence) do i
        v = get(constraint_by_label_index, i, Vector{T}())
        length(v) == max_no_constraints
    end
    # debug @show n all constrained max_prom_val with_max_prominence max_no_constraints with_max_no_constraints
    # d) Label index to drop constraints for
    with_max_no_constraints[end]
end


function drop_constraints_for_most_problematic_label!(model, constraint_by_label_index::Dict{Int, T}, labels) where T
    i_drop_constraint = label_index_to_drop_constraints_for(constraint_by_label_index, labels)
    v = get(constraint_by_label_index, i_drop_constraint, Vector{T}())
    @debug "Reduce the number of model constraints by dropping those for label no $(i_drop_constraint).
        It has $(length(v)) constraints."
    # Now drop all the constraints associated with i_drop_constraint.
    # That is: for all cn in v: Drop all entries from the dictionary, and then drop it from the model.
    for cn in v
        # (The following loop is not very elegant, but we did not store which other label index cn affects.
        # So remove it from dict the hard way...)
        for (key, label_constraints_vector) in constraint_by_label_index
            if cn ∈ label_constraints_vector
                @debug "Label index $key is associated with $cn"
                filter!(c -> c !== cn, label_constraints_vector)
                push!(constraint_by_label_index, key => label_constraints_vector)
            end
        end
        # Having deleted all dictinary entries for cn, now drop it from the model!
        delete(model, cn)
        #unregister(model, Symbol(cn))
    end
    model
end
