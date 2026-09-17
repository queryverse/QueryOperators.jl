struct EnumerableDropLast{T,S} <: Enumerable
    source::S
    n::Int
end

# Enumerable.SkipLast: everything but the trailing `n` elements. A count of
# zero or less leaves the source unchanged, as in .NET.
function drop_last(source::Enumerable, n::Integer)
    T = eltype(source)
    return EnumerableDropLast{T,typeof(source)}(source, max(Int(n), 0))
end

Base.IteratorSize(::Type{EnumerableDropLast{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableDropLast{T,S}}) where {T,S} = T

Base.length(iter::EnumerableDropLast) = max(length(iter.source) - iter.n, 0)

# Stays `n` elements behind the source: an element is only emitted once `n`
# further elements have been read, which proves it is not one of the last `n`.
function Base.iterate(iter::EnumerableDropLast{T,S}) where {T,S}
    buffer = T[]
    source_state = _NotStarted()

    while length(buffer) < iter.n
        ret = _iterate_from(iter.source, source_state)
        # Fewer than n elements in total, so every one of them is dropped.
        ret === nothing && return nothing
        push!(buffer, ret[1])
        source_state = ret[2]
    end

    return _drop_last_next(iter, buffer, source_state)
end

function Base.iterate(iter::EnumerableDropLast, state)
    return _drop_last_next(iter, state.buffer, state.state)
end

function _drop_last_next(iter::EnumerableDropLast, buffer, source_state)
    ret = _iterate_from(iter.source, source_state)
    ret === nothing && return nothing

    push!(buffer, ret[1])
    element = popfirst!(buffer)

    return element, (buffer=buffer, state=ret[2])
end
