struct EnumerableMap{T, S, Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.iteratorsize(::Type{EnumerableMap{T,S,Q}}) where {T,S,Q} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.iteratorsize(S)

Base.eltype(iter::EnumerableMap{T,S,Q}) where {T,S,Q} = T

Base.eltype(iter::Type{EnumerableMap{T,S,Q}}) where {T,S,Q} = T

Base.length(iter::EnumerableMap{T,S,Q}) where {T,S,Q} = length(iter.source)

function map(source::Enumerable, f::Function, f_expr::Expr)
    TS = eltype(source)
    T = Base._return_type(f, Tuple{TS,})
    S = typeof(source)
    Q = typeof(f)
    return EnumerableMap{T,S,Q}(source, f)
end

function Base.start(iter::EnumerableMap{T,S,Q}) where {T,S,Q}
    s = start(iter.source)
    return s
end

function Base.next(iter::EnumerableMap{T,S,Q}, s) where {T,S,Q}
    x = next(iter.source, s)
    v = x[1]
    s_new = x[2]
    v_new = iter.f(v)::T
    return v_new, s_new
end

function Base.done(iter::EnumerableMap{T,S,Q}, state) where {T,S,Q}
    return done(iter.source, state)
end
