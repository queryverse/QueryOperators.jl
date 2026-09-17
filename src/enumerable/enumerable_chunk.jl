struct EnumerableChunk{T,TI,S} <: Enumerable
    source::S
    n::Int
end

# Enumerable.Chunk (.NET 6): split the source into batches of at most `n`
# elements. The final batch is shorter when the source does not divide evenly.
function chunk(source::Enumerable, n::Integer)
    n < 1 && error("The chunk size must be at least 1, got $n.")

    TI = eltype(source)
    T = Vector{TI}

    return EnumerableChunk{T,TI,typeof(source)}(source, Int(n))
end

Base.IteratorSize(::Type{EnumerableChunk{T,TI,S}}) where {T,TI,S} = haslength(S)

Base.eltype(::Type{EnumerableChunk{T,TI,S}}) where {T,TI,S} = T

Base.length(iter::EnumerableChunk) = cld(length(iter.source), iter.n)

Base.iterate(iter::EnumerableChunk) = _chunk_next(iter, _NotStarted())

Base.iterate(iter::EnumerableChunk, state) = _chunk_next(iter, state)

# Pulls at most `n` elements per call, so a chunked source is only walked as
# far as the batches actually consumed.
function _chunk_next(iter::EnumerableChunk{T,TI,S}, source_state) where {T,TI,S}
    buffer = TI[]

    while length(buffer) < iter.n
        ret = _iterate_from(iter.source, source_state)
        ret === nothing && break
        push!(buffer, ret[1])
        source_state = ret[2]
    end

    length(buffer)==0 && return nothing

    return buffer, source_state
end
