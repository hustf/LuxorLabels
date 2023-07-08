using Test
using LuxorLabels
using LuxorLabels.Luxor
f(label, pos, pri) = text(label, pos)
Drawing(NaN, NaN, :rec)
background("salmon")
lbls = String[]
pris = Int64[]
poss = Float64[]
for i = 0:30
    push!(lbls, string(i))
    push!(pris, mod(i, 10) == 0 ? 1 : 2)
    push!(poss, i * 10)
end
it, bbs = labels_prominent(f, lbls, poss, pris)
cb = BoundingBox(bbs[1].corner1, bbs[4].corner2)
snapshot(;fname = "test_line_1.svg", cb)
###
background("gold4")
lbls = String[]
pris = Int64[]
poss = Float64[]
for i = 0:30
    push!(lbls, string(i))
    if mod(i, 10) == 0 
        push!(pris, 1)
    elseif mod(i, 5) == 0
        push!(pris, 2)
    else
        push!(pris, 3)
    end
    push!(poss, i * 10)
end
it, bbs = labels_prominent(f, lbls, poss, pris)
cb = BoundingBox(bbs[1].corner1, bbs[4].corner2)
snapshot(;fname = "test_line_2.svg", cb)
@test Luxor.finish()

