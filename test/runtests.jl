using Test
ENV["JULIA_DEBUG"] = "LuxorLabels"

function run_all_tests()
    @testset "unit" begin
       include("t1_unit.jl")
    end
    @testset "line" begin
        include("t2_line.jl")
    end
    @testset "labels" begin
        include("t3_interfaces.jl")
    end
    @testset "random circle" begin
        include("t4_random_circle.jl")
    end
    @testset "collision free labels" begin
        include("t5_collision_free.jl")
    end
    @testset "font family" begin
        include("t6_font_family.jl")
    end
    @testset "fixpos" begin
        include("t8_fixpos.jl")
    end
    @testset "rbox" begin
        include("t9_rbox.jl")
    end
end

# This is copied directly from Luxor.
if get(ENV, "LUXOR_KEEP_TEST_RESULTS", false) == "true"
    cd(mktempdir(cleanup=false))
    @info("...Keeping the results in: $(pwd())")
    run_all_tests()
    @info("Test images were saved in: $(pwd())")
else
mktempdir() do tmpdir
    cd(tmpdir) do
        msg = """Running tests in: $(pwd())
        but not keeping the results
        because you didn't do: ENV[\"LUXOR_KEEP_TEST_RESULTS\"] = \"true\""""
        @info msg
        run_all_tests()
        @info("Test images weren't saved. To see the test images, next time do this before running:")
        @info(" ENV[\"LUXOR_KEEP_TEST_RESULTS\"] = \"true\"")
    end
end
end