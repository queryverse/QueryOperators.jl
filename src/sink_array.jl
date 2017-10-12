init_sink(enumerable::Enumerable) = Vector{eltype(enumerable)}()

# preserve AbstractArray subtype when collecting
# allows collecting CategoricalValue into CategoricalArray
init_sink(enumerable::SimpleSourceEnumerable{T,<:AbstractVector{T}}) where T =
    similar(source(enumerable), 0)

# recurse to get to the root source
init_sink(enumerable::SimpleSourceEnumerable{T,<:SimpleSourceEnumerable{T}}) where T =
    init_sink(source(enumerable))

function Base.collect(enumerable::Enumerable)
    ret = init_sink(enumerable)
    append!(ret, enumerable)
end

function Base.collect{TS,Provider}(source::Queryable{TS,Provider})
    collect(Provider, source)
end
