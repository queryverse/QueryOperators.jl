using TestItemRunner

include("test_core.jl")
include("test_enumerable_outerjoins.jl")
include("test_enumerable_setops.jl")
include("test_enumerable_ordering.jl")
include("test_enumerable_keyed_aggregation.jl")
include("test_enumerable_partitioning.jl")
include("test_enumerable_combining.jl")
include("test_enumerable_terminal.jl")
include("test_enumerable_typefiltering.jl")
include("test_enumerable_unique.jl")
include("test_enumerable_summarize.jl")
include("test_namedtupleutilities.jl")
include("test_pivot.jl")

@run_package_tests
