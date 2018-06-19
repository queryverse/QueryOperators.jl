struct EnumerableIterable{S} <: Enumerable
    source::S
end

function query(source)
    IteratorInterfaceExtensions.isiterable(source) || error()
    typed_source = IteratorInterfaceExtensions.getiterator(source)
    S = typeof(typed_source)

    source_enumerable = EnumerableIterable{S}(typed_source)

    return source_enumerable
end

Base.iteratorsize(::Type{EnumerableIterable{S}}) where {S} = Base.iteratorsize(S) == Base.HasShape() ? Base.HasLength() : Base.iteratorsize(S)

Base.iteratoreltype(::Type{EnumerableIterable{S}}) where {S} = Base.iteratoreltype(S)

Base.eltype(::Type{EnumerableIterable{S}}) where {S} = eltype(S)

Base.length(iter::EnumerableIterable{S}) where {S} = length(iter.source)

function Base.start(iter::EnumerableIterable{S}) where {S}
    return start(iter.source)
end

@inline function Base.next(iter::EnumerableIterable{S}, state) where {S}
    return next(iter.source, state)
end

function Base.done(iter::EnumerableIterable{S}, state) where {S}
    return done(iter.source, state)
end

