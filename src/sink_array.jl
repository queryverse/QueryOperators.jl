function Base.collect(enumerable::Enumerable)
    T = eltype(enumerable)
    ret = Array{T}(0)
    for i in enumerable
        push!(ret, i)
    end
    return ret
end

function Base.collect(source::Queryable{TS,Provider}) where {TS,Provider}
    collect(Provider, source)
end
