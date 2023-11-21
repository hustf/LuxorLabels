using Test
using LuxorLabels
using LuxorLabels: labels_broadcast_plotfunc, is_colliding
using LuxorLabels: boundingboxes_select_non_overlapping_by_order
using LuxorLabels: boundingboxes_select_non_overlapping_by_priority_then_order
using LuxorLabels: crash_padded_boundingboxes, non_overlapping_labels_data
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, O, Point, Drawing, circle, box
using Luxor: background, setcolor, snapshot

foo(a, b, c) = string("a: ", a, " b:", b,  " c:", c)
tes = labels_broadcast_plotfunc(foo, [1,2,3], [10,20,30], [100, 200, 300])
@test tes == ["a: 3 b:30 c:300", "a: 2 b:20 c:200", "a: 1 b:10 c:100"]

b1 = BoundingBox(O,         O + (1,1))
b2 = BoundingBox(O + (1,0), O + (2,1))
b3 = BoundingBox(O + (2,0), O + (3,1))
@test is_colliding(b1, [b2, b3])
@test ! is_colliding(BoundingBox(O, O - (1,1)), [b2, b3])
@test boundingboxes_select_non_overlapping_by_order([b1, b2, b3]) == [1, 3]
@test boundingboxes_select_non_overlapping_by_order([b2, b1, b3]) == [1]

txtlabels = ["0", "1", "2", "10", "20", "30"]
pris =    [1,   3,    3,    2,   2,   1]
b4 = BoundingBox(O + (3,0), O + (4,1))
b5 = BoundingBox(O + (4,0), O + (5,1))
b6 = BoundingBox(O + (5,0), O + (6,1))
boundingboxes = [b1, b2, b3, b4, b5, b6]

tes1 = boundingboxes_select_non_overlapping_by_priority_then_order(boundingboxes, pris)
@test tes1 == [1, 6, 4]
@test txtlabels[tes1] == ["0", "30", "10"]

# Luxor needs a Cairo context for finding text extents
Drawing(640,640, :rec)
background("grey")
setcolor("black")
poss = parse.(Float64, txtlabels) * 10
all_bbs = crash_padded_boundingboxes(txtlabels, poss, 10)
it, bbs = broadcast_prominent_labels_to_plotfunc((x,y,z)->nothing, txtlabels, poss, pris; crashpadding = 10)
# Mark anchor point and boundingbox
for (i, b) in zip(it, bbs)
    circle(Point(poss[i], 100), 3, :stroke)
    box(b + (0, 100), :stroke)
end
snapshot(fname = "test_unit.svg")
@test it == [1,6]
@test ! boundingboxesintersect(bbs[1], bbs[2])
it, adj_bbs, sel_lbs, sel_anchors, sel_pris = non_overlapping_labels_data(txtlabels, poss, pris; 
    crashpadding = 1.05, anchor = "left")
# Drop the Cairo context
Luxor.finish()