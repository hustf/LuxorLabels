# Test that label text don't overlap other text OR other label anchors.
# Also use more realistic label text lengths.
using Test
using LuxorLabels
import Luxor
using Luxor: Drawing, background, Colorant, BoundingBox, snapshot, O, circle
import ColorSchemes
using ColorSchemes: browncyan
using Random
using SpecialFunctions

# We want to define "random labels" similar to typical bus stop names,
# and we prefer not to use `Distributions.jl` because it's a heavy dependency.
std_normal_pdf(x) = exp(-0.5 * x^2) / sqrt(2 * π)
std_normal_cdf(x) = 0.5 * (1 + erf(x / sqrt(2)))
skew_normal_pdf(x, location, scale, alpha) = 2 / scale * std_normal_pdf((x - location) / scale) * std_normal_cdf(alpha * (x - location) / scale)
# A rough distribution intended for testing label text lengths
function generate_skew_normal_integers(;n = 100, mean = 7.0, lower_std = 3.0, upper_std = 10.0, min_val = 3, max_val = 24)
    alpha = (upper_std - lower_std) / (upper_std + lower_std)
    scale = (upper_std + lower_std) / 2
    values = Int64[]
    while length(values) < n
        x = min_val + (max_val - min_val) * rand()
        rand() <= skew_normal_pdf(x, mean, scale, alpha) / skew_normal_pdf(mean, mean, scale, alpha) && push!(values, round(Int, x))
    end
    values
end

function generate_random_label_text(; nlabels = 10)
    # The letter frequencies are taken from 'Fedrelandssalmen'...
    rng = join([repeat(' ', 121),
        repeat('g', 30),
        repeat('u', 7),
        repeat('d', 36),
        repeat('s', 29),
        repeat('i', 19),
        repeat('n', 31),
        repeat('e', 53),
        repeat('v', 7),
        repeat('å', 13),
        repeat('r', 33),
        repeat('t', 30),
        repeat('y', 7),
        repeat('f', 7),
        repeat('l', 27),
        repeat('a', 20),
        repeat('o', 30),
        repeat('m', 17),
        repeat('h', 2),
        repeat('b', 4),
        repeat('ø', 8),
        repeat('j', 6),
        repeat('k', 10),
        repeat('æ', 2),
        repeat('p', 2)])
    wordlength = generate_skew_normal_integers(;n = nlabels)
    labeltexts = map(wordlength) do n
        s = strip(join(rand(rng, n)))
        uppercasefirst(replace(s, "  " => ' ' ))
    end
end


function generate_labelsdata_circle_randomdist(; nlabels = 10, r = 500)
    txt = generate_random_label_text(; nlabels)
    prominence = generate_skew_normal_integers(;n = nlabels, mean = 2.8, lower_std = 1.0, upper_std = 0.1, min_val = 1, max_val = 3)
    α = 2π .*rand(nlabels)
    x = r .* cos.(α)
    y = r .* sin.(α)
    textcolor = [browncyan[Int64(p)] for p in prominence]
    shadowcolor = [browncyan[Int64(10 - p)] for p in prominence]
    halign = [x < 0 ? :left : :right for (x,y) in zip(x, y)]
    txt, prominence, x, y, textcolor, shadowcolor, halign
end


function makepic(;f, r = 500, nlabels = 10, fname = "t4_random_circle.svg")
    txt, prominence, x, y, textcolor, shadowcolor, halign = generate_labelsdata_circle_randomdist(;r, nlabels)
    Drawing(NaN, NaN, :rec)
    background(browncyan[5])
    circle(O, r ; action = :stroke)
    it, bbs = f(;txt, prominence, x, y, textcolor, shadowcolor, halign)
    # encompassing bounding box
    cb = BoundingBox(O + (-1.15r, -1.15r), O + (1.15r, 1.15r))
    cb = foldr(+, bbs, init = cb)
    if length(it) < nlabels
        if isnothing(match(r"prioritized", string(Symbol(f))))
            @info "$(nlabels - length(it)) of $nlabels overlap and are shown."
        else
            @info "Showing $(length(it)) of $nlabels, some would overlap."
        end
    end
    snapshot(;cb,  fname)
end

makepic(; f = label_prioritized_optimize_vertical_offset)
# With debug logging on:
#[ Info: Showing 44 of 80, some would overlap.
#  1.058 s (607479 allocations: 38.87 MiB)
makepic(;nlabels = 80, f = label_prioritized_optimize_vertical_offset, fname = "t4_random_circle_1.svg")
makepic(;nlabels = 80, f = label_prioritized_optimize_horizontal_offset, fname = "t4_random_circle_2.svg")
makepic(;nlabels = 80, f = label_prioritized_optimize_diagonal_offset, fname = "t4_random_circle_3.svg")
# The time this takes varies wildly, probably depending on whether two important labels are interferring.
# In that case, all other constraints are removed before the model can be resolved.
makepic(;nlabels = 40, f = label_prioritized_optimize_offset, fname = "t4_random_circle_4.svg")

# For readme...
makepic(;nlabels = 30, r = 280, f = label_prioritized_optimize_diagonal_offset, fname = "label_prioritized_optimize_diagonal_offset.svg")