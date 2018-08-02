__precompile__()
module QueryOperators

using DataStructures
using IteratorInterfaceExtensions
using TableShowUtils

export Grouping, key

include("operators.jl")

include("enumerable/enumerable.jl")
include("enumerable/enumerable_groupby.jl")
include("enumerable/enumerable_join.jl")
include("enumerable/enumerable_groupjoin.jl")
include("enumerable/enumerable_orderby.jl")
include("enumerable/enumerable_map.jl")
include("enumerable/enumerable_filter.jl")
include("enumerable/enumerable_mapmany.jl")
include("enumerable/enumerable_defaultifempty.jl")
include("enumerable/enumerable_count.jl")
include("enumerable/enumerable_take.jl")
include("enumerable/enumerable_drop.jl")
include("enumerable/show.jl")

include("queryable/queryable.jl")
include("queryable/queryable_map.jl")
include("queryable/queryable_filter.jl")
include("queryable/sink_array.jl")

include("source_iterable.jl")


end # module
