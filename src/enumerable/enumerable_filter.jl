# This is the HasEltype() version
struct EnumerableFilterHasEltype{T,S,Q<:Function} <: Enumerable
    source::S
    filter::Q
end

Base.eltype(iter::EnumerableFilterHasEltype{T,S,Q}) where {T,S,Q} = T

Base.eltype(iter::Type{EnumerableFilterHasEltype{T,S,Q}}) where {T,S,Q} = T

struct EnumerableFilterHasEltypeState{T,S}
    done::Bool
    next_value::Nullable{T}
    source_state::S
end

function Base.start(iter::EnumerableFilterHasEltype{T,S,Q}) where {T,S,Q}
    s = start(iter.source)
    while !done(iter.source, s)
        v,t = next(iter.source, s)
        if iter.filter(v)
            return EnumerableFilterHasEltypeState(false, Nullable(v), t)
        end
        s = t
    end
    # The s we return here is fake, just to make sure we
    # return something of the right type
    return EnumerableFilterHasEltypeState(true, Nullable{T}(), s)
end

function Base.next(iter::EnumerableFilterHasEltype{T,S,Q}, state) where {T,S,Q}
    v = get(state.next_value)
    s = state.source_state
    while !done(iter.source,s)
        temp = next(iter.source,s)
        w = temp[1]
        t = temp[2]
        if iter.filter(w)::Bool
            temp2 = Nullable(w)
            new_state = EnumerableFilterHasEltypeState(false, temp2, t)
            return v, new_state
        end
        s=t
    end
    # The s we return here is fake, just to make sure we
    # return something of the right type
    v, EnumerableFilterHasEltypeState(true,Nullable{T}(), s)
end

Base.done(f::EnumerableFilterHasEltype{T,S,Q}, state) where {T,S,Q} = state.done

# This is the EltypeUnknown() version

struct EnumerableFilterEltypeUnknown{S,Q<:Function} <: Enumerable
    source::S
    filter::Q
end

Base.iteratoreltype(::Type{EnumerableFilterEltypeUnknown{S,Q}}) where {S,Q} = Base.EltypeUnknown()

function Base.start(iter::EnumerableFilterEltypeUnknown{S,Q}) where {S,Q}
    s = start(iter.source)
    while !done(iter.source, s)
        v,t = next(iter.source, s)
        if iter.filter(v)
            return (false, v, t)
        end
        s = t
    end
    return (true, )
end

function Base.next(iter::EnumerableFilterEltypeUnknown{S,Q}, state) where {S,Q}
    v = state[2]
    s = state[3]
    while !done(iter.source,s)
        temp = next(iter.source,s)
        w = temp[1]
        t = temp[2]
        if iter.filter(w)::Bool
            return v, (false, w, t)
        end
        s=t
    end
    v, (true, v, s)
end

Base.done(f::EnumerableFilterEltypeUnknown{S,Q}, state) where {S,Q} = state[1]

# Implementation of the query operator

function _filter(source::Enumerable, f::Function, f_expr::Expr, ::Base.EltypeUnknown)
    S = typeof(source)
    Q = typeof(f)
    return EnumerableFilterEltypeUnknown{S,Q}(source, f)
end

function _filter(source::Enumerable, f::Function, f_expr::Expr, ::Base.HasEltype)
    T = eltype(source)
    S = typeof(source)
    Q = typeof(f)
    return EnumerableFilterHasEltype{T,S,Q}(source, f)
end

function filter(source::T, filter_func::Function, filter_expr::Expr) where {T<:Enumerable}
    return _filter(source, filter_func, filter_expr, Base.iteratoreltype(T))
end
