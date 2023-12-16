module LuxorLabels
import Luxor
import Base: show
using Luxor: BoundingBox, boundingboxesintersect, boxdiagonal, Point, +,
    @layer, fontsize, textextents, sethue, text, setdash, line, box,
    circle
import JuMP
using GLPK
import GLPK.MathOptInterface
using JuMP: set_optimizer_attribute, @variable, @constraint, optimize!, @objective, 
    termination_status, Model, value, num_constraints, delete, unregister


# These are the most powerful interface functions:
export label_prioritized_optimize_offset,
    label_all_at_given_offset,
    label_all_optimize_vertical_offset,
    label_all_optimize_horizontal_offset,
    label_all_optimize_offset,
    label_prioritized_at_given_offset,
    label_prioritized_optimize_vertical_offset,
    label_prioritized_optimize_horizontal_offset,
    bounding_boxes_all_at_given_offset
# These may be nice for debugging and prettier printing:
export LabelPaperSpace,
    plot_label_bounding_box, labels_paper_space, labels_broadcast_plotfunc

@kwdef mutable struct LabelPaperSpace
    txt::String = "Label\ntext"
    prominence::Float64 = 1.0
    x::Float64 = 0.0
    y::Float64 = 0.0
    halign::Symbol = :left
    offset::Point = Point(-39.0, 52.0)
    fontsize_prominence_1::Float64 = 22.0
    offsetbelow::Bool = true
    shadowcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.342992,0.650614,0.772702)
    textcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.347677,0.199863,0.085069)
    leaderline::Bool = true
end



"""
    labels_paper_space(;kwds...)
    ---> Vector{LabelPaperSpace}

This constructor expects keywords with vector values. The number of returned
LabelPaperSpace elements match the longest vector. Arguments with a single value
are broadcast to all labels.

# Example

Also see tests.

```
julia> begin
    txt = ["0", "1", "2", "10", "20", "30"]
    prominence = [1.0,   3,    3,    2,   2,   1]
    x = parse.(Float64, txt) * 10
    labels = labels_paper_space(;txt, prominence, x, y = 100)
end;

julia> labels[6]
LabelPaperSpace(txt                   = "30",
                prominence             = 1.0,
                x                      = 300.0,
                y                      = 100.0,
                halign                 = :left,
                offset                 = Point(-39.0, 52.0),
                fontsize_prominence_1  = 22.0,
                offsetbelow            = true,
                shadowcolor            = RGB{Float64}(0.342992,0.650614,0.772702),
                textcolor              = RGB{Float64}(0.347677,0.199863,0.085069),
                leaderline             = true)
```
"""
function labels_paper_space(;kwds...)
    check_kwds(;kwds...)
    for k in kwds
        if k[1] ∉ fieldnames(LabelPaperSpace)
            throw(ArgumentError("$(k[1]) not a keyword for LabelPaperSpace. Use $(fieldnames(LabelPaperSpace))"))
        end
    end
    # Find the lengths of the provided keyword argument arrays
    lengths = length.(collect(values(kwds)))
    if ! isempty(setdiff(unique(lengths), 1, maximum(lengths))) 
        throw(ArgumentError("The length of keyword argument values should be either identical or 1. Currrent lengths are $(lengths)"))
    end
    # Create a vector to store the LabelPaperSpace objects
    label_paper_spaces = LabelPaperSpace[]
    # Iterate over the range of the maximum length
    for i in 1:maximum(lengths)
        kwargs_for_this_instance = Dict{Symbol, Any}()
        # For each keyword argument, pick the corresponding element, cycling if necessary
        for (key, value_array) in kwds
            kwargs_for_this_instance[key] = value_array[mod1(i, length(value_array))]
        end
        # Create a new LabelPaperSpace object using these keyword arguments
        push!(label_paper_spaces, LabelPaperSpace(; kwargs_for_this_instance...))
    end
    label_paper_spaces
end
include("io.jl")
include("utils.jl")
include("overlap_prominence_order.jl")
include("default_plot_label_bounding_box.jl")
include("label_functions.jl")
include("optimize_offset.jl")


"""
    labels_broadcast_plotfunc(f, labels; kwds...)

Calls `f` once per label in `labels`. Also passes (all of the) keyword arguments to f.

# Example
```
julia> labels_broadcast_plotfunc(x -> string(x), ["abc", "def"])
2-element Vector{String}:
 "abc"
 "def"

julia> fi(a; kw = "nokw") = string(a) * " " * kw 
fi (generic function with 1 method)

julia> labels_broadcast_plotfunc(fi, ["abc", "def"]; kw = "kw")
2-element Vector{String}:
 "abc kw"
 "def kw"
```
"""
function labels_broadcast_plotfunc(f, labels; kwds...)
    check_kwds(;kwds...)
    map(labels) do l
        if isempty(kwds)
            f(l)
        else
            f(l; kwds...)
        end
    end
end

end # Module