# Instead of a multitude of keywords to a few functions, our interface
# consists of a lot of functions ("the keywords are in the function name"). 
# Test the interface functions, all with the default label plotting function.
using Test
using LuxorLabels
import Luxor
using Luxor: Drawing, background, Colorant, BoundingBox, snapshot, O
import ColorSchemes
using ColorSchemes: browncyan
#ENV["JULIA_DEBUG"] = "LuxorLabels"


function generate_labelsdata_grid(; rws = 1, cols = 9, dx = 9, dy = 15)
    txt = String[]
    prominence = Float64[]
    x = Float64[]
    y = Float64[]
    textcolor = Colorant[]
    shadowcolor = Colorant[]
    for i = 1:rws
        for j = 1:cols
            n = (i - 1) * cols + j
            push!(txt, string(n))
            if mod(n, 10) == 0
                prom = 1.0
            elseif mod(n, 5) == 0
                prom = 2.0
            else
                prom = 3.0
            end
            push!(prominence, prom)
            push!(textcolor, browncyan[Int64(prom)])
            push!(shadowcolor, browncyan[10 - Int64(prom)])
            push!(x, j * dx)
            push!(y, i * dy)
        end
    end
    txt, prominence, x, y, textcolor, shadowcolor
end
#
# Prepare a dense grid of labels
#
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(; rws = 30, cols = 30, dx = 10, dy = 10)
#
# Test the most simple label function first:
#
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_all_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb = foldr(+, bbs)
snapshot(;cb, fname = "test_interfaces_10.svg")

# Slightly prettier without leader lines:
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_all_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor, leaderline = false)
# encompassing bounding box
cb = foldr(+, bbs)
snapshot(;cb, fname = "test_interfaces_11.svg")
@test it == 1:900

# Test that we can pass keywords through the pipeline that ends up in the 
# label plotting function (if they're not relevant to defining LabelPaperSpace objects).
Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor, leaderline = false, plot_guides = true)
snapshot(;cb, fname = "test_interfaces_12.svg")


#
# Even simpler function call: don't plot the bounding boxes at all! Blank output.
#
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = bounding_boxes_all_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor, leaderline = false)
# encompassing bounding box
cb1 = foldr(+, bbs)
snapshot(;cb, fname = "test_interfaces_13.svg")
@test cb[1] == cb1[1]
@test cb[2] == cb1[2]
@test it == 1:900

#
# Drop labels with overlap - considering prominence.
#
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor, halign = :right)
# encompassing bounding box
cb1 = foldr(+, bbs)
snapshot(;cb = cb1, fname = "test_interfaces_14.svg")
@test it[1] == 10
@test length(it) == 91


#
# Prepare a smaller and less dense grid of labels for optimization tests
#
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 10, dx = 10, dy = 10)
#
# Optimize offset directions vertically
# Drop labels with overlap based on prominence.
#
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb1 = foldr(+, bbs)
cb1 += BoundingBox(O, O + (100, 0))
snapshot(;cb = cb1,  fname = "test_interfaces_15.svg")
@test it[1] == 10
@test length(it) == 10


# Optimize offset directions horizontally
# Drop labels with overlap based on prominence.
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_optimize_horizontal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb1 = foldr(+, bbs)
cb1 += BoundingBox(O, O + (100, 0))
snapshot(;cb = cb1,  fname = "test_interfaces_16.svg")
@test it[1] == 10
@test length(it) == 10

# Optimize offset directions diagonally
# Drop labels with overlap based on prominence.
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb1 = foldr(+, bbs)
cb1 += BoundingBox(O, O + (100, 0))
snapshot(;cb = cb1,  fname = "test_interfaces_17.svg")
@test it[1] == 10
@test length(it) == 10



#
# Prepare a rectangular grid of labels 
# We need a wider grid for longer labels
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 2, cols = 10, dx = 14, dy = 10)

# Optimize offset directions, four quadrants
# Drop labels with overlap based on prominence.
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_optimize_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb1 = foldr(+, bbs)
cb1 += BoundingBox(O, O + (100, 0))
snapshot(;cb = cb1,  fname = "test_interfaces_18.svg")
@test it[1] == 10
@test length(it) == 20


# Test the remaining 'Keep all labels' variants
Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_optimize_horizontal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
snapshot(;cb = cb1,  fname = "test_interfaces_19.svg")

Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor)
snapshot(;cb = cb1,  fname = "test_interfaces_20.svg")

Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
snapshot(;cb = cb1,  fname = "test_interfaces_21.svg")


Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, halign = :right)
snapshot(;cb = cb1,  fname = "test_interfaces_22.svg")

Drawing(NaN, NaN, :rec)
background(browncyan[5])
label_all_optimize_offset(;txt, prominence, x, y, textcolor, shadowcolor)
snapshot(;cb = cb1,  fname = "test_interfaces_23.svg")

