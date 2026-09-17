struct EnumerableIntersect{T,TKEY,S1,S2,Q<:Function} <: Enumerable
    first::S1
    second::S2
    f::Q
end

Base.eltype(::Type{EnumerableIntersect{T,TKEY,S1,S2,Q}}) where {T,TKEY,S1,S2,Q} = T

function intersect(first::Enumerable, second::Enumerable)
    T1 = eltype(first)
    T2 = eltype(second)

    _check_same_eltype("intersect", T1, T2)

    return EnumerableIntersect{T1,T1,typeof(first),typeof(second),typeof(identity)}(first, second, identity)
end

# As with `except_by`, the key selector is applied to both sequences rather than
# the second being a bare sequence of keys as in Enumerable.IntersectBy.
function intersect_by(first::Enumerable, second::Enumerable, f::Function, f_expr::Expr)
    T1 = eltype(first)
    T2 = eltype(second)

    TKEY1 = Base._return_type(f, Tuple{T1,})
    TKEY2 = Base._return_type(f, Tuple{T2,})

    _check_same_keytype("intersect_by", TKEY1, TKEY2)

    return EnumerableIntersect{T1,TKEY1,typeof(first),typeof(second),typeof(f)}(first, second, f)
end

function Base.iterate(iter::EnumerableIntersect{T,TKEY,S1,S2,Q}) where {T,TKEY,S1,S2,Q}
    required = Set{TKEY}()
    for i in iter.second
        push!(required, iter.f(i))
    end

    return _intersect_next(iter, required, Set{TKEY}(), _NotStarted())
end

function Base.iterate(iter::EnumerableIntersect, state)
    return _intersect_next(iter, state.required, state.observed, state.state)
end

# Yields the distinct elements of the first source whose key also occurs in the
# second, matching Enumerable.Intersect's de-duplicating behaviour.
function _intersect_next(iter::EnumerableIntersect, required, observed, source_state)
    while true
        ret = _iterate_from(iter.first, source_state)
        ret === nothing && return nothing

        element, source_state = ret
        k = iter.f(element)
        if k in required && !(k in observed)
            push!(observed, k)
            return element, (required=required, observed=observed, state=source_state)
        end
    end
end
