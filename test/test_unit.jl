using Test
using LuxorLabels
using LuxorLabels: labels_broadcast_plotfunc, is_colliding, non_overlapping_indexes_by_order,
    non_overlapping_indexes_by_prominence_then_order
import Luxor
using Luxor: BoundingBox, boundingboxesintersect, O, Point, Drawing, circle, box
using Luxor: background, setcolor, snapshot, finish

@testset "labels_broadcast_plotfunc" begin
    foo(a) = string(a)
    tes = labels_broadcast_plotfunc(foo, ["abc", "def"])
    @test tes == ["abc", "def"]

    tes = labels_broadcast_plotfunc(foo, [LabelPaperSpace(;txt = "abc")])
    @test tes == ["""LabelPaperSpace("abc", 1.0, 0.0, 0.0, :left, Point(-39.0, 52.0), 22.0, true, RGB{Float64}(0.342992,0.650614,0.772702), RGB{Float64}(0.347677,0.199863,0.085069), true)"""]

    fi(a; kw = "nokw") = string(a) * " " * kw
    tes = labels_broadcast_plotfunc(fi, ["abc", "def"])
    @test tes == ["abc nokw", "def nokw"]

    tes = labels_broadcast_plotfunc(fi, ["abc", "def"]; kw = "kw")
    @test tes == ["abc kw", "def kw"]
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



@testset "wrap_to_two_words_per_line" begin
    @test LuxorLabels.wrap_to_two_words_per_line("Label\ntxt") == "Label txt"
    @test LuxorLabels.wrap_to_two_words_per_line("Un dau tri, pedwar\n pump") == "Un dau\ntri, pedwar\npump"
end

@testset "plot_label_bounding_box" begin
    Drawing(NaN, NaN, :rec)
    l = LabelPaperSpace()
    bb = plot_label_bounding_box(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb = bb
    snapshot(;cb)

    l = LabelPaperSpace(;offsetbelow = false)
    bb = plot_label_bounding_box(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(; cb )

    l = LabelPaperSpace(halign = :right)
    bb = plot_label_bounding_box(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(; cb )

    l = LabelPaperSpace(halign = :right, offsetbelow = false)
    bb = plot_label_bounding_box(l; noplot = false, plot_guides = true, two_word_lines = true)
    cb += bb
    snapshot(; cb, fname = "plot_label_bounding_box.png" )
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
    @test_throws ArgumentError labels_paper_space(;txt, prominence, x, y =[ 100, 200])
end 
