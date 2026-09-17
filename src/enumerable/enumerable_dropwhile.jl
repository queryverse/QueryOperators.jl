struct EnumerableDropWhile{T,S,Q<:Function} <: Enumerable
    source::S
    f::Q
end

# Enumerable.SkipWhile: discards the leading run of elements satisfying the
# predicate, then yields everything that follows without testing it again.
function drop_while(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    return EnumerableDropWhile{T,typeof(source),typeof(f)}(source, f)
end

Base.eltype(::Type{EnumerableDropWhile{T,S,Q}}) where {T,S,Q} = T

function Base.iterate(iter::EnumerableDropWhile)
    ret = iterate(iter.source)

    while ret !== nothing && iter.f(ret[1])
        ret = iterate(iter.source, ret[2])
    end

    ret === nothing && return nothing

    return ret[1], ret[2]
end

Base.iterate(iter::EnumerableDropWhile, state) = iterate(iter.source, state)
