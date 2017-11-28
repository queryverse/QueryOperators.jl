function Base.collect(source::Queryable{TS,Provider}) where {TS,Provider}
    collect(Provider, source)
end
