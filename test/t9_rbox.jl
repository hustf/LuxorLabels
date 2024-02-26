# Test the newest keyword (used internally through broadcast), suppress.
# Test a rounded, slightly smaller default background box.
# 
# This uses functions and definitions from t3_interfaces.jl
include("t3_interfaces.jl")
@assert @isdefined generate_labelsdata_grid

txt, prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(; rws = 1, cols = 4, dx = 15)
txt[2] = "2.1 2.2 2.3 2.4"
txt[4] = "§4"
Drawing(NaN, NaN, :rec); background(browncyan[end])
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y)
snapshot(;cb = foldr(+, bbs),  fname = "t9_rbox_1.svg")


#= A good shadow color may be the complementary of foreground text color.

julia> labels_paper_space(;txt, prominence, x, y)[1].textcolor |> println
RGB{Float64}(0.347677,0.199863,0.085069)

julia> compl_sh = ColorSchemes.RGB(1 - 0.347677, 1 - 0.199863, 1 -0.085069)

..But that is a little too light here. We reduce the luminance in the Lab colorspace here...
=#

Drawing(NaN, NaN, :rec); background(browncyan[end])
it, bbs = label_prioritized_optimize_diagonal_offset(;txt, prominence, x, y, textcolor, 
    shadowcolor = ColorSchemes.Lab(50,-5.837970596445919,-18.528067637048906))
snapshot(;cb = foldr(+, bbs),  fname = "t9_rbox_2.svg")

@test true