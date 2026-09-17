struct EnumerableIndex{T,TI,S} <: Enumerable
    source::S
end

# Enumerable.Index (.NET 9) pairs each element with its position. .NET yields
# (Index, Item) tuples; the Julia equivalent is an (index, item) NamedTuple.
# Indices are 1-based, matching the rest of Julia rather than .NET.
function index(source::Enumerable)
    TI = eltype(source)
    T = NamedTuple{(:index, :item),Tuple{Int,TI}}
    return EnumerableIndex{T,TI,typeof(source)}(source)
end

Base.IteratorSize(::Type{EnumerableIndex{T,TI,S}}) where {T,TI,S} = haslength(S)

Base.eltype(::Type{EnumerableIndex{T,TI,S}}) where {T,TI,S} = T

Base.length(iter::EnumerableIndex) = length(iter.source)

function Base.iterate(iter::EnumerableIndex{T,TI,S}) where {T,TI,S}
    ret = iterate(iter.source)
    ret === nothing && return nothing

    return T((1, ret[1])), (i=1, state=ret[2])
end

function Base.iterate(iter::EnumerableIndex{T,TI,S}, state) where {T,TI,S}
    ret = iterate(iter.source, state.state)
    ret === nothing && return nothing

    i = state.i + 1
    return T((i, ret[1])), (i=i, state=ret[2])
end
