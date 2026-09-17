struct EnumerableOfType{T,S} <: Enumerable
    source::S
end

# Enumerable.OfType: keeps only the elements that are instances of T, and
# narrows the element type to T. Useful for sources whose element type is Any
# or a Union; a no-op filter on a homogeneously typed table.
function of_type(source::Enumerable, ::Type{T}) where {T}
    return EnumerableOfType{T,typeof(source)}(source)
end

Base.eltype(::Type{EnumerableOfType{T,S}}) where {T,S} = T

Base.iterate(iter::EnumerableOfType) = _of_type_next(iter, _NotStarted())

Base.iterate(iter::EnumerableOfType, state) = _of_type_next(iter, state)

function _of_type_next(iter::EnumerableOfType{T,S}, source_state) where {T,S}
    while true
        ret = _iterate_from(iter.source, source_state)
        ret === nothing && return nothing

        element, source_state = ret
        element isa T && return element, source_state
    end
end

struct EnumerableCast{T,S} <: Enumerable
    source::S
end

# Enumerable.Cast. .NET's Cast is a type assertion; the Julia counterpart is a
# conversion, so `cast` runs every element through `convert` and fails the same
# way `convert` would on an element that cannot be represented as T.
function cast(source::Enumerable, ::Type{T}) where {T}
    return EnumerableCast{T,typeof(source)}(source)
end

Base.IteratorSize(::Type{EnumerableCast{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableCast{T,S}}) where {T,S} = T

Base.length(iter::EnumerableCast) = length(iter.source)

function Base.iterate(iter::EnumerableCast{T,S}) where {T,S}
    ret = iterate(iter.source)
    ret === nothing && return nothing
    return convert(T, ret[1]), ret[2]
end

function Base.iterate(iter::EnumerableCast{T,S}, state) where {T,S}
    ret = iterate(iter.source, state)
    ret === nothing && return nothing
    return convert(T, ret[1]), ret[2]
end
