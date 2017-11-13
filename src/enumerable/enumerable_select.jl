struct EnumerableSelect{T, S, Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.iteratorsize(::Type{EnumerableSelect{T,S,Q}}) where {T,S,Q} = Base.iteratorsize(S)

Base.eltype(iter::EnumerableSelect{T,S,Q}) where {T,S,Q} = T

Base.eltype(iter::Type{EnumerableSelect{T,S,Q}}) where {T,S,Q} = T

Base.length(iter::EnumerableSelect{T,S,Q}) where {T,S,Q} = length(iter.source)

function select(source::Enumerable, f::Function, f_expr::Expr)
    TS = eltype(source)
    T = Base._return_type(f, Tuple{TS,})
    S = typeof(source)
    Q = typeof(f)
    return EnumerableSelect{T,S,Q}(source, f)
end

macro select_internal(source, f)
    q = Expr(:quote, f)
    :(select($(esc(source)), $(esc(f)), $(esc(q))))
end

function Base.start(iter::EnumerableSelect{T,S,Q}) where {T,S,Q}
    s = start(iter.source)
    return s
end

function Base.next(iter::EnumerableSelect{T,S,Q}, s) where {T,S,Q}
    x = next(iter.source, s)
    v = x[1]
    s_new = x[2]
    v_new = iter.f(v)::T
    return v_new, s_new
end

function Base.done(iter::EnumerableSelect{T,S,Q}, state) where {T,S,Q}
    return done(iter.source, state)
end
