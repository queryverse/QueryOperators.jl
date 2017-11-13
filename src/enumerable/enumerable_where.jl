# T is the type of the elements produced by this iterator
struct EnumerableWhere{T,S,Q<:Function} <: Enumerable
    source::S
    filter::Q
end

Base.eltype(iter::EnumerableWhere{T,S,Q}) where {T,S,Q} = T

Base.eltype(iter::Type{EnumerableWhere{T,S,Q}}) where {T,S,Q} = T

struct EnumerableWhereState{T,S}
    done::Bool
    next_value::Nullable{T}
    source_state::S
end

function where(source::Enumerable, filter::Function, filter_expr::Expr)
    T = eltype(source)
    S = typeof(source)
    Q = typeof(filter)
    return EnumerableWhere{T,S,Q}(source, filter)
end

macro where_internal(source, f)
    q = Expr(:quote, f)
    :(QueryOperators.where($(esc(source)), $(esc(f)), $(esc(q))))
end

function Base.start(iter::EnumerableWhere{T,S,Q}) where {T,S,Q}
    s = start(iter.source)
    while !done(iter.source, s)
        v,t = next(iter.source, s)
        if iter.filter(v)
            return EnumerableWhereState(false, Nullable(v), t)
        end
        s = t
    end
    # The s we return here is fake, just to make sure we
    # return something of the right type
    return EnumerableWhereState(true, Nullable{T}(), s)
end

function Base.next(iter::EnumerableWhere{T,S,Q}, state) where {T,S,Q}
    v = get(state.next_value)
    s = state.source_state
    while !done(iter.source,s)
        temp = next(iter.source,s)
        w = temp[1]
        t = temp[2]
        if iter.filter(w)::Bool
            temp2 = Nullable(w)
            new_state = EnumerableWhereState(false, temp2, t)
            return v, new_state
        end
        s=t
    end
    # The s we return here is fake, just to make sure we
    # return something of the right type
    v, EnumerableWhereState(true,Nullable{T}(), s)
end

Base.done(f::EnumerableWhere{T,S,Q}, state) where {T,S,Q} = state.done
