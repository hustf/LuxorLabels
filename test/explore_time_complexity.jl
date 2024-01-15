#
# Explore how fast the optimization becomes slow.
# Assuming LuxorLabels etc are imported, having run all other tests.
#
function timetaken(; f = label_prioritized_optimize_vertical_offset, cols = 5)
    rws = 2
    _ , prominence, x, y, textcolor, shadowcolor = generate_labelsdata_grid(;  rws, cols, dx = 1, dy = 10)
    txt = fill("9", rws * cols)
    t0 = Base.time_ns()
    # We assume this won't be optimized away!
    f(;txt, prominence, x, y, textcolor, shadowcolor)
    Float64((Base.time_ns() - t0) / 1e9)
end


colrng = collect(1:11) .^2
t_vert = map(colrng) do cols
    @show cols
    timetaken(; cols, f = label_prioritized_optimize_vertical_offset)
end
using UnicodePlots
lineplot(colrng, t_vert; title = "Time [s] vs n")
lineplot(colrng, t_vert.^(1/3); title =  "Time [s]^(1/3) vs n")
#
# ==> The time complexity is close to cubic for binary optimization.

# Let's compare with four possible label placements.
colrng = collect(1:4) .^2
t_all = map(colrng) do cols
    @show cols
    timetaken(; cols, f = label_prioritized_optimize_offset)
end
lineplot(colrng, t_all; title = "Time [s] vs n")
lineplot(colrng, t_all.^(1/3); title =  "Time [s]^(1/3) vs n")
# ==> The time complexity is hard to pinpoint for four possible label placement.
# It is very problem-dependant.
# A typical problem we may encounter is when two labels (say, two capital cities)
# interfer with each other. With less important labels present, all of those
# will be released first, even though the capital cities are the problem.
