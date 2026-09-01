# Internal marker used as the key of the keyless Grouping that the ungrouped
# summarize path wraps its source in.
struct _SummarizeUngroupedKey end

_key_namedtuple(k::NamedTuple) = k                        # multi-column grouping key: splat fields in
_key_namedtuple(::_SummarizeUngroupedKey) = NamedTuple()  # ungrouped: no key columns
_key_namedtuple(k) = (key = k,)                           # scalar key: column named `key`

# Lazy one-element enumerable used by the ungrouped summarize path: on first
# iterate it collects the source rows, wraps them in a keyless Grouping (so
# that column access on the group works exactly as in the grouped path) and
# yields the single aggregated row.
struct EnumerableSummarizeAll{T,S,Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.eltype(::Type{EnumerableSummarizeAll{T,S,Q}}) where {T,S,Q} = T
Base.IteratorSize(::Type{<:EnumerableSummarizeAll}) = Base.HasLength()
Base.length(::EnumerableSummarizeAll) = 1

function Base.iterate(iter::EnumerableSummarizeAll{T,S,Q}) where {T,S,Q}
    TS = eltype(iter.source)
    elements = Base.collect(TS, iter.source)
    g = Grouping{_SummarizeUngroupedKey,TS}(_SummarizeUngroupedKey(), elements)
    return iter.f(g), nothing
end

Base.iterate(::EnumerableSummarizeAll, state) = nothing

summarize(source::Enumerable, f::Function, f_expr::Expr) =
    _summarize(source, eltype(source), f, f_expr)

# Grouped input: one output row per group, as a lazy map over the groups.
_summarize(source, ::Type{<:Grouping}, f::Function, f_expr::Expr) =
    map(source, f, f_expr)

# Ungrouped input: the whole source is treated as a single keyless group,
# producing a stream of exactly one row.
function _summarize(source, ::Type{TS}, f::Function, f_expr::Expr) where {TS}
    TG = Grouping{_SummarizeUngroupedKey,TS}
    T = Base._return_type(f, Tuple{TG})
    return EnumerableSummarizeAll{T,typeof(source),typeof(f)}(source, f)
end
