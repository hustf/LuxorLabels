# This tests with user-defined label plotting functions.
# All labels on a line.
using Test
using LuxorLabels
using LuxorLabels.Luxor
using Luxor: box, circle
txt = String[]
prominence = Int64[]
x = Float64[]
for i = 0:30
    push!(txt, string(i))
    push!(prominence, mod(i, 10) == 0 ? 1 : 2)
    push!(x, i * 10)
end
labels = labels_paper_space(;txt, x, prominence)

# A very simple label plot, doesn't return anything interesting
f(label) = text(label.txt, label.x, label.y)
Drawing(NaN, NaN, :rec)
background("salmon")
pts = labels_broadcast_plotfunc(f, labels)
cb = BoundingBox(Point(-10, -20), pts[end] + (50, 0))
setcolor("blue")
box(cb, :dash)
circle(0, 0, 10, :stroke)
snapshot(;fname = "test_line_1.svg", cb)

# To avoid overlaps, we must specify a function
# that returns a bounding box, and which accepts
# keyword 'noplot'
function bb_of_simple_label(l; noplot = false)
    # For single text lines only
    if ! noplot
        text(l.txt, l.x, l.y)
    end
    xb, yb, w, h, _, _ = textextents(l.txt)
    # yte position of baseline
    yte = l.y
    # y top of boundary box
    ytl = yte + yb
    # xte position of baseline
    xte = l.x
    # x left of boundary box
    xtl = xte + xb
    # y bottom of boundary box
    ybr = ytl + h
    # x right of boundary box
    xbr = xtl + w
    # Boundary box
    BoundingBox(Point(xtl, ytl), Point(xbr, ybr))
end

Drawing(NaN, NaN, :rec)
background("salmon")
bbs = labels_broadcast_plotfunc(bb_of_simple_label, labels)
@test eltype(bbs) <: BoundingBox
# encompassing bounding box
cb = foldr(+, bbs)
setcolor("blue")
circle(0, 0, 10, :stroke)
snapshot(;fname = "test_line_2.svg", cb)

Drawing(NaN, NaN, :rec)
background("salmon")
# To drop the overlaps, call this higher-level function. We
# get the displayed labels indices, as well as the bounding boxes
# for those labels.
it, bbs = label_prioritized_at_given_offset(; f = bb_of_simple_label, labels)
@test length(it) == 21
@test sort(it)[end] == 31 # starts at 0
@test labels[31].txt == "30"
cb = foldr(+, bbs)
setcolor("blue")
circle(0, 0, 10, :stroke)
snapshot(;fname = "test_line_3.svg", cb)
# Cleanup
@test Luxor.finish()
