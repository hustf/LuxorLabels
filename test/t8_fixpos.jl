# None of the tests so far have set LabelPaperSpace.fixedpos to other than the default,
# 
# This uses functions from t3_interfaces.jl
include("t3_interfaces.jl")
@assert @isdefined generate_labelsdata_grid
# Prepare a 2x2 small grid of labels where 3 and 4 are too close for comfort.
#
txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(; rws = 1, cols = 4, dx = 6)
Drawing(NaN, NaN, :rec); background(browncyan[5])
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor)
# How does the default look?
snapshot(;cb = foldr(+, bbs),  fname = "t8_fixedpos_1.svg")
# Label 1 and 3 is in the default position, 3 and 4 are flipped diagonally. 
# Debug logging shows the collision constraints. All are additionaly limited to either pos 1 or 3.
# Debug: Collision constraints table
#                                        1    1      c[1,1] + c[2,1] <= 1  c[1,3] + c[2,3] <= 1
#                                        2    2      c[1,1] + c[2,1] <= 1  c[1,3] + c[2,3] <= 1  c[2,1] + c[3,1] <= 1  c[2,3] + c[3,3] <= 1
#                                        3    3      c[2,1] + c[3,1] <= 1  c[2,3] + c[3,3] <= 1  c[3,1] + c[4,1] <= 1  c[3,3] + c[4,3] <= 1
#                                        4    4      c[3,1] + c[4,1] <= 1  c[3,3] + c[4,3] <= 1
#
# Let us fix 4 to the default, unflipped position!
Drawing(NaN, NaN, :rec); background(browncyan[5])
fixpos = [posfree, posfree, posfree, keep]
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, fixpos)
snapshot(;cb = foldr(+, bbs),  fname = "t8_fixedpos_2.svg")
# All labels were flipped compared to above, while the collision constraints table remains the same. The additional
# restraint has lead to picking the other possible solution of the same problem.

# We can't force '4' to another position, since this is a diagonal-flipping problem. 
Drawing(NaN, NaN, :rec); background(browncyan[5])
fixpos = [posfree, posfree, posfree, fliphor]
@test_throws KeyError label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, shadowcolor, fixpos)

