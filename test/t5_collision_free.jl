# None of the tests so far have set LabelPaperSpace.collision_free = true
# This uses functions from t3_interfaces.jl
include("t3_interfaces.jl")
@assert @isdefined generate_labelsdata_grid
#
# Prepare a 2x2 small grid of labels where 3 and 4 are too close for comfort.
#
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(; rws = 2, cols = 2, dx = 9, dy = 9)
Drawing(NaN, NaN, :rec); background(browncyan[5])
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# This is the full, INFEASIBLE constraint set from debug log:
# (1, 1 ) <=> (3, 1)
# (1, 1 ) <=> (4, 1)
# (1, 3 ) <=> (2, 3)
# (1, 3 ) <=> (3, 3)
# (1, 3 ) <=> (4, 3)
# (2, 1 ) <=> (3, 1)
# (2, 1 ) <=> (4, 1)
# (2, 3 ) <=> (3, 3)
# (2, 3 ) <=> (4, 3)
# (3, 1 ) <=> (4, 1)
# (3, 3 ) <=> (4, 3)
# This is 15 = 11 constraints + 4 constraints (each label must have one position)
#
# How does it look?
snapshot(;cb = foldr(+, bbs),  fname = "t5_collision_free_1.svg")
# Label 4 does not show, because constraints were dropped automatically from 4, so other 
# labels took its place. 
@test it == [1, 2, 3]

# Let us make 3 collision free!
Drawing(NaN, NaN, :rec); background(browncyan[5])
collision_free = [false, false, true, false]
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, collision_free)
## This is the full, OPTIMAL constraint set from debug log:
# (1, 1 ) <=> (4, 1)
# (1, 3 ) <=> (2, 3)
# (1, 3 ) <=> (4, 3)
# (2, 1 ) <=> (4, 1)
# (2, 3 ) <=> (4, 3)
# This is 9 = 5 constraints + 4 constraints (each label must have one position)
# How does it look?
snapshot(;cb = foldr(+, bbs),  fname = "t5_collision_free_2.svg") 
# Label 3 does not show, because 4 took its place. 
@test it == [1, 2, 4]

# This time, let's specify that we want to plot overlapped labels. 3 is still collision-free.
Drawing(NaN, NaN, :rec); background(browncyan[5])
it, bbs = label_all_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, collision_free)
# How does it look?
snapshot(;cb = foldr(+, bbs),  fname = "t5_collision_free_3.svg") 
@test it == [1, 2, 3, 4]
# We can clearly see that 3 is allowed to overlap with 1. We can make the plot easier to interpret:
Drawing(NaN, NaN, :rec); background(browncyan[5])
it, bbs = label_all_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, collision_free,
    plot_guides = true)
snapshot(;cb = foldr(+, bbs),  fname = "t5_collision_free_4.svg") 
@test it == [1, 2, 3, 4]

