struct EnumerableUnion{T,TKEY,S1,S2,Q<:Function} <: Enumerable
    first::S1
    second::S2
    f::Q
end

Base.eltype(::Type{EnumerableUnion{T,TKEY,S1,S2,Q}}) where {T,TKEY,S1,S2,Q} = T

function union(first::Enumerable, second::Enumerable)
    T1 = eltype(first)
    T2 = eltype(second)

    _check_same_eltype("union", T1, T2)

    return EnumerableUnion{T1,T1,typeof(first),typeof(second),typeof(identity)}(first, second, identity)
end

function union_by(first::Enumerable, second::Enumerable, f::Function, f_expr::Expr)
    T1 = eltype(first)
    T2 = eltype(second)

    _check_same_eltype("union_by", T1, T2)

    TKEY = Base._return_type(f, Tuple{T1,})

    return EnumerableUnion{T1,TKEY,typeof(first),typeof(second),typeof(f)}(first, second, f)
end

function Base.iterate(iter::EnumerableUnion{T,TKEY,S1,S2,Q}) where {T,TKEY,S1,S2,Q}
    return _union_next(iter, Set{TKEY}(), 1, _NotStarted())
end

function Base.iterate(iter::EnumerableUnion, state)
    return _union_next(iter, state.observed, state.side, state.state)
end

# Walks the first source and then the second, yielding each element whose key
# has not been seen before, so that the result is distinct across both sources.
function _union_next(iter::EnumerableUnion{T,TKEY,S1,S2,Q}, observed, side, source_state) where {T,TKEY,S1,S2,Q}
    while true
        source = side == 1 ? iter.first : iter.second
        ret = _iterate_from(source, source_state)

        if ret === nothing
            side == 2 && return nothing
            side = 2
            source_state = _NotStarted()
            continue
        end

        element, source_state = ret
        k = iter.f(element)
        if !(k in observed)
            push!(observed, k)
            return element, (observed=observed, side=side, state=source_state)
        end
    end
end
