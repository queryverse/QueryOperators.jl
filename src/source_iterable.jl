struct EnumerableIterable{T,S} <: Enumerable
    source::S
end

function query(source)
    IteratorInterfaceExtensions.isiterable(source) || error()
    typed_source = IteratorInterfaceExtensions.getiterator(source)
	T = eltype(typed_source)
    S = typeof(typed_source)

    source_enumerable = EnumerableIterable{T,S}(typed_source)

    return source_enumerable
end

Base.iteratorsize(::Type{EnumerableIterable{T,S}}) where {T,S} = Base.iteratorsize(S)

Base.eltype(iter::EnumerableIterable{T,S}) where {T,S} = T

Base.eltype(iter::Type{EnumerableIterable{T,S}}) where {T,S} = T

Base.length(iter::EnumerableIterable{T,S}) where {T,S} = length(iter.source)

function Base.start(iter::EnumerableIterable{T,S}) where {T,S}
    return start(iter.source)
end

@inline function Base.next(iter::EnumerableIterable{T,S}, state) where {T,S}
    return next(iter.source, state)
end

function Base.done(iter::EnumerableIterable{T,S}, state) where {T,S}
    return done(iter.source, state)
end

