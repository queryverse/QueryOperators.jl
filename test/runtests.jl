using TestItemRunner

include("test_core.jl")
include("test_enumerable_unique.jl")
include("test_namedtupleutilities.jl")

@run_package_tests
