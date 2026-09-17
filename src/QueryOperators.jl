module QueryOperators

using DataStructures
using IteratorInterfaceExtensions
using TableShowUtils
import DataValues
import Random

export Grouping, key

include("operators.jl")
include("NamedTupleUtilities.jl")

include("enumerable/enumerable.jl")
include("enumerable/enumerable_groupby.jl")
include("enumerable/enumerable_join.jl")
include("enumerable/enumerable_groupjoin.jl")
include("enumerable/enumerable_leftjoin.jl")
include("enumerable/enumerable_rightjoin.jl")
include("enumerable/enumerable_fulljoin.jl")
include("enumerable/enumerable_orderby.jl")
include("enumerable/enumerable_map.jl")
include("enumerable/enumerable_filter.jl")
include("enumerable/enumerable_mapmany.jl")
include("enumerable/enumerable_defaultifempty.jl")
include("enumerable/enumerable_count.jl")
include("enumerable/enumerable_take.jl")
include("enumerable/enumerable_drop.jl")
include("enumerable/enumerable_takewhile.jl")
include("enumerable/enumerable_dropwhile.jl")
include("enumerable/enumerable_takelast.jl")
include("enumerable/enumerable_droplast.jl")
include("enumerable/enumerable_unique.jl")
include("enumerable/enumerable_concat.jl")
include("enumerable/enumerable_union.jl")
include("enumerable/enumerable_except.jl")
include("enumerable/enumerable_intersect.jl")
include("enumerable/enumerable_reverse.jl")
include("enumerable/enumerable_shuffle.jl")
include("enumerable/enumerable_index.jl")
include("enumerable/enumerable_append.jl")
include("enumerable/enumerable_prepend.jl")
include("enumerable/enumerable_zip.jl")
include("enumerable/enumerable_pivot.jl")
include("enumerable/enumerable_summarize.jl")
include("enumerable/enumerable_countby.jl")
include("enumerable/enumerable_aggregateby.jl")
include("enumerable/enumerable_chunk.jl")
include("enumerable/show.jl")

include("source_iterable.jl")

end # module
