using Test
ENV["JULIA_DEBUG"] = "LuxorLayout"

function run_all_tests()
    @testset "snap" begin
        include("test_line.jl")
    end
    @testset "scale" begin
        include("test_box.jl")
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