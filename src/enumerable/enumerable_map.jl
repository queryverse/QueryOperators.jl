# This is the HasEltype() version

struct EnumerableMapHasEltype{T, S, Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.iteratorsize(::Type{EnumerableMapHasEltype{T,S,Q}}) where {T,S,Q} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.iteratorsize(S)

Base.eltype(iter::Type{EnumerableMapHasEltype{T,S,Q}}) where {T,S,Q} = T

Base.length(iter::EnumerableMapHasEltype{T,S,Q}) where {T,S,Q} = length(iter.source)

function Base.start(iter::EnumerableMapHasEltype{T,S,Q}) where {T,S,Q}
    s = start(iter.source)
    return s
end

function Base.next(iter::EnumerableMapHasEltype{T,S,Q}, s) where {T,S,Q}
    x = next(iter.source, s)
    v = x[1]
    s_new = x[2]
    v_new = iter.f(v)::T
    return v_new, s_new
end

function Base.done(iter::EnumerableMapHasEltype{T,S,Q}, state) where {T,S,Q}
    return done(iter.source, state)
end

# This is the EltypeUnknown() version

struct EnumerableMapEltypeUnknown{S, Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.iteratorsize(::Type{EnumerableMapEltypeUnknown{S,Q}}) where {S,Q} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.iteratorsize(S)

Base.iteratoreltype(::Type{EnumerableMapEltypeUnknown{S,Q}}) where {S,Q} = Base.EltypeUnknown()

Base.length(iter::EnumerableMapEltypeUnknown) = length(iter.source)

function Base.start(iter::EnumerableMapEltypeUnknown)
    s = start(iter.source)
    return s
end

function Base.next(iter::EnumerableMapEltypeUnknown, s)
    x = next(iter.source, s)
    v = x[1]
    s_new = x[2]
    v_new = iter.f(v)
    return v_new, s_new
end

function Base.done(iter::EnumerableMapEltypeUnknown, state)
    return done(iter.source, state)
end

# Implementation of the query operator

function _map(source::Enumerable, f::Function, f_expr::Expr, ::Base.EltypeUnknown)
    S = typeof(source)
    Q = typeof(f)
    println("Unkonwn")
    return EnumerableMapEltypeUnknown{S,Q}(source, f)
end

function _map(source::Enumerable, f::Function, f_expr::Expr, ::Base.HasEltype)
    TS = eltype(source)
    T = Base._return_type(f, Tuple{TS,})
    if isleaftype(T)
        S = typeof(source)
        Q = typeof(f)
        println("Known")
        return EnumerableMapHasEltype{T,S,Q}(source, f)
    else
        _map(source, f, f_expr, Base.EltypeUnknown())
    end
end

function map(source::T, f::Function, f_expr::Expr) where {T<:Enumerable}
    return _map(source, f, f_expr, Base.iteratoreltype(T))
end

