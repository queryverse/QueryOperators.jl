module QueryOperators

using DataStructures
using DataValues
using NamedTuples

export Grouping

include("enumerable/enumerable.jl")
include("enumerable/enumerable_groupby.jl")
include("enumerable/enumerable_join.jl")
include("enumerable/enumerable_groupjoin.jl")
include("enumerable/enumerable_orderby.jl")
include("enumerable/enumerable_select.jl")
include("enumerable/enumerable_where.jl")
include("enumerable/enumerable_selectmany.jl")
include("enumerable/enumerable_defaultifempty.jl")
include("enumerable/enumerable_count.jl")

include("queryable/queryable.jl")
include("queryable/queryable_select.jl")
include("queryable/queryable_where.jl")

end # module
