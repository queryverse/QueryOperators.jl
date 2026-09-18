struct EnumerableExcept{T,TKEY,S1,S2,Q<:Function} <: Enumerable
    first::S1
    second::S2
    f::Q
end

Base.eltype(::Type{EnumerableExcept{T,TKEY,S1,S2,Q}}) where {T,TKEY,S1,S2,Q} = T

function except(first::Enumerable, second::Enumerable)
    T1 = eltype(first)
    T2 = eltype(second)

    _check_same_eltype("except", T1, T2)

    return EnumerableExcept{T1,T1,typeof(first),typeof(second),typeof(identity)}(first, second, identity)
end

# Unlike Enumerable.ExceptBy, whose second argument is a sequence of keys, the
# key selector here is applied to both sequences. That keeps `except_by`
# consistent with `union_by`, matches the shape of the equivalent SQL
# (`WHERE k NOT IN (SELECT k FROM b)`), and is what a table-shaped second
# argument makes natural.
function except_by(first::Enumerable, second::Enumerable, f::Function, f_expr::Expr)
    T1 = eltype(first)
    T2 = eltype(second)

    TKEY1 = Base._return_type(f, Tuple{T1,})
    TKEY2 = Base._return_type(f, Tuple{T2,})

    _check_same_keytype("except_by", TKEY1, TKEY2)

    return EnumerableExcept{T1,TKEY1,typeof(first),typeof(second),typeof(f)}(first, second, f)
end

function Base.iterate(iter::EnumerableExcept{T,TKEY,S1,S2,Q}) where {T,TKEY,S1,S2,Q}
    excluded = Set{TKEY}()
    for i in iter.second
        push!(excluded, iter.f(i))
    end

    return _except_next(iter, excluded, Set{TKEY}(), _NotStarted())
end

function Base.iterate(iter::EnumerableExcept, state)
    return _except_next(iter, state.excluded, state.observed, state.state)
end

# Yields the distinct elements of the first source whose key does not occur in
# the second, matching Enumerable.Except's de-duplicating behaviour.
function _except_next(iter::EnumerableExcept, excluded, observed, source_state)
    while true
        ret = _iterate_from(iter.first, source_state)
        ret === nothing && return nothing

        element, source_state = ret
        k = iter.f(element)
        if !(k in excluded) && !(k in observed)
            push!(observed, k)
            return element, (excluded=excluded, observed=observed, state=source_state)
        end
    end
end
