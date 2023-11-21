using Test
using LuxorLabels
using LuxorLabels.Luxor
function foo(label, pos, pri)
    if pri == 1
        setcolor("black")
    elseif pri == 2
        setcolor("green")
    else
        setcolor("grey")
    end
     text(label, pos)
end
Drawing(NaN, NaN, :rec)
background("cyan")
lbls = String[]
pris = Int64[]
poss = Point[]
for i = 1:30
    for j = 1:30
        n = (i - 1) * 30 + j
        push!(lbls, string(n))
        if mod(n, 10) == 0
            push!(pris, 1)
        elseif mod(n, 5) == 0
            push!(pris, 2)
        else
            push!(pris, 3)
        end
        push!(poss, Point(j * 10, i * 10))
    end
end
it, bbs = broadcast_prominent_labels_to_plotfunc(foo, lbls, poss, pris)
setline(0.05)
# Mark anchor point and boundingbox
for (i, b) in zip(it, bbs)
    circle(poss[i], 1, :stroke)
    box(b, :stroke)
end
cb = BoundingBox(Point(-15, -15), Point(325, 325))
snapshot(;fname = "test_box.svg", cb)
@test Luxor.finish()

