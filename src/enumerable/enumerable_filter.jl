# T is the type of the elements produced by this iterator
struct EnumerableFilter{T,S,Q <: Function} <: Enumerable
    source::S
    filter::Q
end

Base.eltype(iter::Type{EnumerableFilter{T,S,Q}}) where {T,S,Q} = T

function filter(source::Enumerable, filter_func::Function, filter_expr::Expr)
    T = eltype(source)
    S = typeof(source)
    Q = typeof(filter_func)
    return EnumerableFilter{T,S,Q}(source, filter_func)
end

function Base.iterate(iter::EnumerableFilter{T,S,Q}, state...) where {T,S,Q}
    ret = iterate(iter.source, state...)

    while ret !== nothing
        if iter.filter(ret[1])
            return ret
        end

        ret = iterate(iter.source, ret[2])
    end

    return nothing
end
