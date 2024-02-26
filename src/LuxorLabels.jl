module LuxorLabels
import Luxor
import Base: show
using Luxor: BoundingBox, boundingboxesintersect, boxdiagonal, Point, +,
    @layer, fontsize, fontface, textextents, sethue, text, setdash, line,
    circle, getline, setline, setopacity, box
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
    label_all_optimize_diagonal_offset,
    label_all_optimize_offset,
    label_prioritized_at_given_offset,
    label_prioritized_optimize_vertical_offset,
    label_prioritized_optimize_horizontal_offset,
    label_prioritized_optimize_diagonal_offset,
    indexes_and_bbs_all_at_given_offset,
    indexes_and_bbs_prioritized_at_given_offset
# These may be nice for debugging and prettier printing:
export LabelPaperSpace,
    plot_label_return_bb, labels_paper_space, labels_broadcast_plotfunc,
    wrap_to_lines, PosEnum, posfree, keep, flipvert, flipdiag, fliphor

# During label optimization, a posfree LabelPaperSpace can flip to make room.
# We can also fix (some) labels by setting the fixpox field to either:
#@enum PosEnum posfree = 0 botleft=1 topleft = 2 topright=3 botright = 4
"""
PosEnum is used for defining the boolean satisfiability problem of fitting labels.

    posfree     0    Default, this label can be flipped to solve the label-fitting problem.
    keep        1    Fix to  the position defined by .halign, .offsetbelow and .offset
    flipvert    2    Fix to flipped .offsetbelow
    flipdiag    3    Fix to flipped .offsetbelow and .halign
    fliphor     4    Fix to flipped .halign
"""
@enum PosEnum posfree = 0 keep = 1 flipvert = 2 flipdiag = 3 fliphor = 4
"""
Keywords and default values for single instances of LabelPaperSpace.

    - txt::String = "Label\\\\ntext"        # You can escape newline like this to preserve (force) line breaks.
    - prominence::Float64 = 1.0             # 1 is 'high prominence', 3, is 'low prominence'. Confusing, yes.
    - x::Float64 = 0.0                      # This is x of the label anchor point (label describes this point)
    - y::Float64 = 0.0                      # This is y (+ down) of the label anchor point
    - offset::Point = Point(-39.0, 52.0)    # Vector from label anchor to near start of text baseline (some of it may be hidden)
    - halign::Symbol = :left                # :right will flip horizontal offset sign 
    - offsetbelow::Bool = true              # false will flip vertical offset sign
    - fixpos::PosEnum = posfree             # Meaning NOT fixed in optimization. Can be {posfree, keep, flipvert, flipdiag, fliphor}
    - shadowcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.342992,0.650614,0.772702)
    - textcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.347677,0.199863,0.085069)
    - leaderline::Bool = true               # For short offsets, we may want to drop the dashed leader line.
    - collision_free::Bool = false          # If true, the label does not occupy space during placement optimization. Debug option.
    - fontsize_prominence_1::Float64 = 22.0 # If prominence value is > 1, font size will be reduced from this.
    - fontfamily::String = ""               # "" means use the default font. Example value "Arial".

    # Available fonts
    
    How to list available font families in Windows terminal:
    ```
    PS C:\\> Add-Type -AssemblyName System.Drawing
    PS C:\\> \$fontFolder = New-Object System.Drawing.Text.PrivateFontCollection
    PS C:\\> Get-ChildItem "C:\\Windows\\Fonts\\*.ttf","C:\\Windows\\Fonts\\*.otf" -Recurse | ForEach-Object {
        \$fontFamily = New-Object System.Drawing.Text.PrivateFontCollection
        \$fontFamily.AddFontFile(\$_.FullName)
        [System.Drawing.FontFamily]::new(\$fontFamily.Families[0].Name)
    } | Select-Object -ExpandProperty Name | Sort-Object -Unique
    
    Arial
    Arial Black
    Bahnschrift
    ...
    Verdana
    ```
"""
@kwdef mutable struct LabelPaperSpace
    txt::String = "Label\\ntext"
    prominence::Float64 = 1.0
    x::Float64 = 0.0
    y::Float64 = 0.0
    offset::Point = Point(-39.0, 52.0)
    halign::Symbol = :left
    offsetbelow::Bool = true
    fixpos::PosEnum = posfree
    shadowcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.342992,0.650614,0.772702)
    textcolor::Luxor.Colorant = Luxor.RGB{Float64}(0.347677,0.199863,0.085069)
    leaderline::Bool = true
    collision_free::Bool = false
    fontsize_prominence_1::Float64 = 22.0
    fontfamily::String = ""
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
    lengths = map(collect(values(kwds))) do v
        if v isa AbstractArray # Probably just a boring vector
            length(v)
        else
            1 # Strings and other types are all of 'length' 1 in this context.
        end
    end
    if ! isempty(setdiff(unique(lengths), 1, maximum(lengths)))
        throw(ArgumentError("The length of keyword argument values should be either N or 1. Currrent lengths are $(lengths)"))
    end
    # Create a vector to store the LabelPaperSpace objects
    label_paper_spaces = LabelPaperSpace[]
    # Iterate over the range of the maximum length
    for i in 1:maximum(lengths)
        kwargs_for_this_instance = Dict{Symbol, Any}()
        # For each keyword argument, pick the corresponding element, cycling if necessary
        for (key, val) in kwds
            if val isa AbstractArray
                kwargs_for_this_instance[key] = val[mod1(i, length(val))]
            else
                # e.g. a keyword like 'halign' can be specified as ':right' and apply to
                # all the generated labels.
                kwargs_for_this_instance[key] = val
            end
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
    # We don't want leaders overlapping background (semi-transparent) boxes.
    # So first plot all leaders, then all text.
    if isempty(kwds)
        map(labels) do l
            f(l; suppress = :text)
        end
        map(labels) do l
            f(l; suppress = :leader)
        end
    else
        hasvector = any(map(values(kwds)) do v
            typeof(v) <: Vector 
        end)
        if hasvector
            @warn "labels_broadcast_plotfunc received kwds" kwds
            throw(ArgumentError("It seems you passed a vector valued keyword! We have not implemented that yet..."))
        else
            map(labels) do l
                f(l; suppress = :text, kwds...)
            end
            map(labels) do l
                f(l; suppress = :leader, kwds...)
            end
        end
    end
end

end # Module