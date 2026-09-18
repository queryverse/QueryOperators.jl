struct EnumerableConcat{T,S1,S2} <: Enumerable
    first::S1
    second::S2
end

function concat(first::Enumerable, second::Enumerable)
    T1 = eltype(first)
    T2 = eltype(second)

    _check_same_eltype("concat", T1, T2)

    return EnumerableConcat{T1,typeof(first),typeof(second)}(first, second)
end

Base.eltype(::Type{EnumerableConcat{T,S1,S2}}) where {T,S1,S2} = T

function Base.IteratorSize(::Type{EnumerableConcat{T,S1,S2}}) where {T,S1,S2}
    return haslength(S1) isa Base.HasLength && haslength(S2) isa Base.HasLength ?
        Base.HasLength() : Base.SizeUnknown()
end

Base.length(iter::EnumerableConcat) = length(iter.first) + length(iter.second)

Base.iterate(iter::EnumerableConcat) = _concat_next(iter, 1, _NotStarted())

function Base.iterate(iter::EnumerableConcat, state)
    return _concat_next(iter, state.side, state.state)
end

function _concat_next(iter::EnumerableConcat, side, source_state)
    if side == 1
        ret = _iterate_from(iter.first, source_state)
        if ret !== nothing
            return ret[1], (side=1, state=ret[2])
        end
        # First source exhausted — fall through to the second.
        side = 2
        source_state = _NotStarted()
    end

    ret = _iterate_from(iter.second, source_state)
    ret === nothing && return nothing
    return ret[1], (side=2, state=ret[2])
end
