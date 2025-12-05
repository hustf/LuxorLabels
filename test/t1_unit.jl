using Test
using LuxorLabels
using LuxorLabels: labels_broadcast_plotfunc, is_colliding, non_overlapping_indexes_by_order,
    non_overlapping_indexes_by_prominence_then_order, label_offset_at_direction_no!, label_offset_at_direction_no
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, O, Point, Drawing, circle
using Luxor: background, setcolor, snapshot, finish

@testset "labels_broadcast_plotfunc" begin
    foo(a; kws...) = string(a)
    tes = labels_broadcast_plotfunc(foo, ["abc", "def"])
    @test tes == ["abc", "def"]
    tes = labels_broadcast_plotfunc(foo, [LabelPaperSpace(;txt = "abc")])
    @test tes == ["LabelPaperSpace(\"abc\", 1.0, 0.0, 0.0, Point(-39.0, 52.0), :left, true, posfree, RGB{Float64}(0.342992, 0.650614, 0.772702), RGB{Float64}(0.347677, 0.199863, 0.085069), true, false, 22.0, \"\")"]
    fi(a; kw = "nokw", kws...) = string(a) * " " * kw
    tes = labels_broadcast_plotfunc(fi, ["abc", "def"])
    @test tes == ["abc nokw", "def nokw"]
    # A single keyword broadcast to each
    tes = labels_broadcast_plotfunc(fi, ["abc", "def"]; kw = "kw")
    @test tes == ["abc kw", "def kw"]
    # Two keywords broadcast to each
    function fa(a; kw...)
        string(a) * " " * join(map(collect(kw)) do (k, v)
            string(k) * " = " * string(v)
        end, "   ")
    end
    tes = labels_broadcast_plotfunc(fa, ["abc", "def"]; kw = "kw", kw1 = "kw1")
    @test tes == ["abc suppress = leader   kw = kw   kw1 = kw1", "def suppress = leader   kw = kw   kw1 = kw1"]
    # One keyword with different values for each label
    @test_throws ArgumentError labels_broadcast_plotfunc(fa, ["abc", "def"]; kw = ["ABC", "DEF"])
end

@testset "is_colliding" begin
    b1 = BoundingBox(O,         O + (1,1))
    b2 = BoundingBox(O + (1,0), O + (2,1))
    b3 = BoundingBox(O + (2,0), O + (3,1))
    @test is_colliding(b1, [b2, b3])
    @test ! is_colliding(BoundingBox(O, O - (1,1)), [b2, b3])
    @test non_overlapping_indexes_by_order([b1, b2, b3]) == [1, 3]
    @test non_overlapping_indexes_by_order([b2, b1, b3]) == [1]
    @test non_overlapping_indexes_by_prominence_then_order([b1, b2, b3], [1.0, 1, 1]) == [1, 3]
    @test non_overlapping_indexes_by_prominence_then_order([b1, b2, b3], [2.0, 1, 1]) == [2]
    @test non_overlapping_indexes_by_prominence_then_order([b1, b2, b3], [2.0, 2.0, 1]) == [3, 1]
end

@testset "wrap_to_lines" begin
    @test LuxorLabels.wrap_to_lines("Label\ntxt") == "Label txt"
    @test LuxorLabels.wrap_to_lines("Un dau tri, pedwar\n pump") == "Un dau\ntri, pedwar\npump"
    @test wrap_to_lines("1 2 3, 4 5") == "1 2\n3, 4\n5"
    @test wrap_to_lines("1\n 2 3, 4 5") == "1 2\n3, 4\n5"
    @test wrap_to_lines("1\\n2 3, 4 5") == "1\n2 3,\n4 5"
    @test wrap_to_lines("Ungdomsskulen sin skysstasjon ved fylkesvegen til Ovra er liten") == "Ungdomsskulen\nsin \nskysstasjon\nved \nfylkesvegen\ntil Ovra\ner liten"
    @test wrap_to_lines("Hareid ungdomsskule fv. 61") == "Hareid \nungdomsskule\nfv. 61"
end

@testset "plot_label_return_bb" begin
    Drawing(NaN, NaN, :rec)
    l = LabelPaperSpace()
    bb = plot_label_return_bb(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb = bb
    snapshot(;cb, fname = "t1_unit_1.svg")

    l = LabelPaperSpace(;offsetbelow = false)
    bb = plot_label_return_bb(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(;cb, fname = "t1_unit_2.svg")

    l = LabelPaperSpace(halign = :right)
    bb = plot_label_return_bb(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(;cb, fname = "t1_unit_3.svg")

    l = LabelPaperSpace(halign = :right, offsetbelow = false)
    bb = plot_label_return_bb(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(;cb, fname = "t1_unit_4.svg")
    @test true
end


@testset "Constructor labels_paper_space" begin
    txt = ["0", "1", "2", "10", "20", "30"]
    prominence = [1.0,   3,    3,    2,   2,   1]
    x = parse.(Float64, txt) * 10
    xx = x
    @test_throws ArgumentError labels_paper_space(;txt, prominence, xx)
    @test length(labels_paper_space(;txt, prominence, x)) == 6
    @test length(labels_paper_space(;txt, prominence, x = 42)) == 6
    @test labels_paper_space(;txt, prominence, x = 42)[6].x == 42
    @test labels_paper_space(;txt, prominence, x = 42)[6].txt == txt[6]
    @test labels_paper_space(;txt, prominence, x = 42, offsetbelow = false)[6].txt == txt[6]
    @test_throws ArgumentError labels_paper_space(;txt, prominence, x, y =[ 100, 200])
end


@testset "Offset directions for optimizations" begin
    txt = ["0", "1", "2", "10", "20", "30"]
    prominence = [1.0,   3,    3,    2,   2,   1]
    x = parse.(Float64, txt) * 10
    labels = labels_paper_space(;txt, prominence, x)
    @test length(labels) == 6
    label_offset_at_direction_no!(labels, 1, 1)
    label_offset_at_direction_no!(labels, 2, 2)
    label_offset_at_direction_no!(labels, 3, 3)
    label_offset_at_direction_no!(labels, 4, 4)
    @test labels[1].offsetbelow
    @test labels[1].halign == :left
    @test ! labels[2].offsetbelow
    @test labels[2].halign == :left
    @test ! labels[3].offsetbelow
    @test labels[3].halign == :right
    @test labels[4].offsetbelow
    @test labels[4].halign == :right
end