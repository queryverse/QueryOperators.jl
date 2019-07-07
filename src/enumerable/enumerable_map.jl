struct EnumerableMap{T, S, Q<:Function} <: Enumerable
    source::S
    f::Q
end

Base.IteratorSize(::Type{EnumerableMap{T,S,Q}}) where {T,S,Q} = Base.IteratorSize(S)

Base.eltype(iter::Type{EnumerableMap{T,S,Q}}) where {T,S,Q} = T

Base.length(iter::EnumerableMap{T,S,Q}) where {T,S,Q} = length(iter.source)

function map(source::Enumerable, f::Function, f_expr::Expr)
    TS = eltype(source)
    T = Base._return_type(f, Tuple{TS,})
    S = typeof(source)
    Q = typeof(f)
    return EnumerableMap{T,S,Q}(source, f)
end

function Base.iterate(iter::EnumerableMap{T,S,Q}, state...) where {T,S,Q}
    ret = iterate(iter.source, state...)
    if ret===nothing
        return nothing
    else
        return iter.f(ret[1]), ret[2]
    end
end
