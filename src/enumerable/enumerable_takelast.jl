struct EnumerableTakeLast{T,S} <: Enumerable
    source::S
    n::Int
end

# Enumerable.TakeLast: the trailing `n` elements. A count of zero or less
# yields nothing, as in .NET.
function take_last(source::Enumerable, n::Integer)
    T = eltype(source)
    return EnumerableTakeLast{T,typeof(source)}(source, max(Int(n), 0))
end

Base.IteratorSize(::Type{EnumerableTakeLast{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableTakeLast{T,S}}) where {T,S} = T

Base.length(iter::EnumerableTakeLast) = min(length(iter.source), iter.n)

# Which elements are last is only known once the source is exhausted, so the
# whole source is walked, holding at most `n` elements in a ring buffer.
function Base.iterate(iter::EnumerableTakeLast{T,S}) where {T,S}
    iter.n == 0 && return nothing

    buffer = CircularBuffer{T}(iter.n)
    for i in iter.source
        push!(buffer, i)
    end

    length(buffer)==0 && return nothing

    elements = Base.collect(buffer)

    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableTakeLast{T,S}, state) where {T,S}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
