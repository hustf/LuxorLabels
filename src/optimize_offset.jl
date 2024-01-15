function optimize_offset_direction_vertical!(labels, f; kwds...)
    check_kwds(;kwds...)
    optimize_offset_direction!(labels, f, 1:2; kwds...)
end

function optimize_offset_direction_horizontal!(labels, f; kwds...)
    check_kwds(;kwds...)
    optimize_offset_direction!(labels, f, [1, 4]; kwds...)
end
function optimize_offset_direction_diagonal!(labels, f; kwds...)
    check_kwds(;kwds...)
    optimize_offset_direction!(labels, f, [1, 3]; kwds...)
end
function optimize_offset_direction!(labels, f; kwds...)
    check_kwds(;kwds...)
    # The complexity of allowing four possible offset directions
    # instead of two is extremely costly. And the graphics are
    # uglier too (if a leader line is included). So don't, please!
    optimize_offset_direction!(labels, f, 1:4; kwds...)
end


function optimize_offset_direction!(labels, f, direction_nos; kwds...)
    check_kwds(;kwds...)
    model = Model(GLPK.Optimizer)
    set_optimizer_attribute(model, "tm_lim", 30 * 1_000)
    #set_optimizer_attribute(model, "msg_lev", GLPK.GLP_MSG_OFF)
    # The problem is one of label placement.
    # The number of labels
    n = length(labels)
    # The number of possible offset directions for each label
    m = length(direction_nos)
    @debug "Bulding model. Size estimate: Labels n = $n, positions for each label m = $m.
            Number of combinations before adding overlap constraints: mⁿ = $(BigInt(m)^n)"
    # We have a vector of labels. For each assign one row of
    # binary variables. There are m columns in each row.
    # A value of 'true' or '1' at (i, j) indicates that label i
    # offsets it label to position j.
    # Define binary variables
    @variable(model, c[1:n, direction_nos], Bin)
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
        for j1 in direction_nos
            # Boundary boxes of text and label anchor
            bb1, bbp1 = boundary_box_of_label_offset_at_direction_no(f, labels[i1], j1; kwds...)
            for i2 in 1:n
                # Skip along because of the constraint symmetry described above.
                i2 <= i1 && continue
                for j2 in direction_nos
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
    # TODO Consider: define callbacks and possibly unrestrain the most difficult constraint.
    #      Ref. https://github.com/jump-dev/GLPK.jl#callbacks
    #
    # If there are no possible label overlaps, there's nothing to optimize
    if ! isempty(constraint_by_label_index)
        sol_c = iterate_to_solution_by_dropping_constraints(model, n, constraint_by_label_index, labels, c, m)
        # Mutate the labels to match this solution.
        for i in 1:n
            sol_c_row = sol_c[i, :]
            sol_colno = findfirst(e -> e == 1, sol_c_row)
            sol_dirno = direction_nos[sol_colno]
            label_offset_at_direction_no!(labels, i, sol_dirno)
        end
    else
        @debug "No possible label overlab => no offset directions to optimize for"
    end
    labels
end

function iterate_to_solution_by_dropping_constraints(model, n, constraint_by_label_index, labels, c, m)
    tries = 0
    lastsoltime = NaN
    while true
        tries += 1
        @debug "Optimizing model with " num_constraints(model; count_variable_in_set_constraints = false)
        nconstr = num_constraints(model; count_variable_in_set_constraints = false)
        if nconstr > 500
            if m > 2
                @warn "The number of constraints $nconstr > 500, consider restraining label offset to two positions only."
            end
        end
        @assert num_constraints(model; count_variable_in_set_constraints = false) > n
        optimize!(model)
        lastsoltime = MathOptInterface.get(model, MathOptInterface.SolveTimeSec())
        @debug "Last solve time [s], constraints, labels:" lastsoltime nconstr n
        # Check if the model has a solution
        @debug termination_status(model)
        if termination_status(model) == MathOptInterface.OPTIMAL
            break
        else
            drop_constraints_for_most_problematic_label!(model, constraint_by_label_index, labels)
        end
        @assert tries < 10000 # May be increased if beneficial...
    end
    # Extract and convert the solution stepwise
    sol_c1 = value.(c)
    sol_c2 = Int.(round.(sol_c1))
    # The container type is some exotic DenseAxisArray for speed. Julify it!
    Matrix(sol_c2)
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
    offsetbelow, halign = direction_tuple(label, j; debug)
    l = deepcopy(label)
    l.halign = halign
    l.offsetbelow = offsetbelow
    l
end
function label_offset_at_direction_no!(labels, i::Int64, j::Int64; debug = true)
    offsetbelow, halign = direction_tuple(labels[i], j; debug)
    labels[i].halign = halign
    labels[i].offsetbelow = offsetbelow
    labels[i]
end

function direction_tuple(l::LabelPaperSpace, j::Int; debug = false)
    if j == 1
        # Keep the original (default) vertical
        # Keep the horizontal offset direction
        offsetbelow, halign = l.offsetbelow, l.halign
    elseif j == 2
        # Flip the vertical offset direction
        # Keep the horizontal offset direction
        debug && @debug "2 Flip vertical '$(l.txt)'"
        offsetbelow, halign = ! l.offsetbelow, l.halign
    elseif j == 3
        # Flip the vertical offset direction
        # Flip the horizontal offset direction
        debug && @debug "3 Flip vertical and horizontal '$(l.txt)'"
        offsetbelow = ! l.offsetbelow
        if l.halign == :left
            halign = :right
        elseif l.halign == :right
            halign = :left
        else
            throw("halign unexpected: $(l.halign)")
        end
    elseif j == 4
        # Keep the vertical offset direction
        # Flip the horizontal offset direction
        offsetbelow = l.offsetbelow
        debug && @debug "4 Flip horizontal '$(l.txt)'"
        if l.halign == :left
            halign = :right
        elseif l.halign == :right
            halign = :left
        else
            throw("halign unexpected: $(l.halign)")
        end
    else
        throw("unexpected $j")
    end
    offsetbelow, halign
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
                # @debug "Label index $key is associated with $cn"
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
