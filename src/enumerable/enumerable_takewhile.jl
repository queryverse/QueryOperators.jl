struct EnumerableTakeWhile{T,S,Q<:Function} <: Enumerable
    source::S
    f::Q
end

# Enumerable.TakeWhile: yields elements until the predicate first fails, then
# stops — later elements are not examined even if they would satisfy it.
function take_while(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    return EnumerableTakeWhile{T,typeof(source),typeof(f)}(source, f)
end

Base.eltype(::Type{EnumerableTakeWhile{T,S,Q}}) where {T,S,Q} = T

Base.iterate(iter::EnumerableTakeWhile) = _take_while_step(iter, iterate(iter.source))

Base.iterate(iter::EnumerableTakeWhile, state) = _take_while_step(iter, iterate(iter.source, state))

function _take_while_step(iter::EnumerableTakeWhile, ret)
    ret === nothing && return nothing
    iter.f(ret[1]) || return nothing
    return ret[1], ret[2]
end
