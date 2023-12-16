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
# label plotting function:
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
it, bbs = label_prioritized_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor)
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


#
# Find how fast the optimization becomes slow....
#
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 10, dx = 10, dy = 10)
#  10:     0.004572 seconds (8.63 k allocations: 487.656 KiB)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 100, dx = 10, dy = 10)
#  100:   0.424828 seconds (469.28 k allocations: 31.900 MiB)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 200, dx = 10, dy = 10)
# 200: 2.396099 seconds (1.86 M allocations: 132.544 MiB, 0.63% gc time)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 300, dx = 10, dy = 10)
# 300: 6.223864 seconds (4.16 M allocations: 296.359 MiB, 0.55% gc time)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 400, dx = 10, dy = 10)
# 400: 12.388219 seconds (7.37 M allocations: 531.959 MiB, 0.46% gc time)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws = 1, cols = 500, dx = 10, dy = 10)
# 500:  21.493384 seconds (11.50 M allocations: 825.824 MiB, 0.44% gc time)
@time it, bbs = label_prioritized_optimize_vertical_offset(;txt, prominence, x, y, textcolor, shadowcolor);
# encompassing bounding box
cb1 = foldr(+, bbs)
cb1 += BoundingBox(O, O + (100, 0))
snapshot(;cb = cb1,  fname = "test_interfaces_16.svg")

