# None of the tests so far have set LabelPaperSpace.collision_free = true
# This uses functions from 
#include("test/t3_interfaces.jl")
@assert @isdefined generate_labelsdata_grid
#fname = "t5_collision_free_1.svg"
#txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(; rws = 1, cols = 4, dx = 9, dy = 15)
@test true