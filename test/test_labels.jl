using Test
using LuxorLabels
import Luxor
using Luxor: Drawing, background, Colorant, BoundingBox, snapshot
import ColorSchemes
using ColorSchemes: browncyan
#
# Prepare a dense grid of labels
#
txt = String[]
prominence = Float64[]
x = Float64[]
y = Float64[]
textcolor = Colorant[]
shadowcolor = Colorant[]
for i = 1:30
    for j = 1:30
        n = (i - 1) * 30 + j
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
        push!(x, j * 10)
        push!(y, i * 10)
    end
end

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
# Even simpler, don't plot the bounding boxes at all! Blank output.
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
# Drop labels with overlap based on prominence.
#
Drawing(NaN, NaN, :rec)
background(browncyan[5])
it, bbs = label_prioritized_at_given_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# encompassing bounding box
cb1 = foldr(+, bbs)
snapshot(;cb, fname = "test_interfaces_14.svg")
@test it[1] == 10
@test length(it) == 91