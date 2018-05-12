struct EnumerableTake{S} <: Enumerable
    source::S
    n::Int
end

function take(source::Enumerable, n::Integer)
    S = typeof(source)
    return EnumerableTake{S}(source, Int(n))
end

Base.iteratorsize(::Type{EnumerableTake{S}}) where {S} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.SizeUnknown()

Base.iteratoreltype(::Type{EnumerableTake{S}}) where {S} = Base.iteratoreltype(S)

Base.eltype(::Type{EnumerableTake{S}}) where {S} = eltype(S)

Base.length(iter::EnumerableTake{S}) where {S} = min(length(iter.source),iter.n)

function Base.start(iter::EnumerableTake{S}) where {S}
    return iter.n, start(iter.source)
end

function Base.next(iter::EnumerableTake{S}, s) where {S}
    n, source_state = s
    x = next(iter.source, source_state)
    v = x[1]
    source_new = x[2]
    return v, (n-1, source_new)
end

function Base.done(iter::EnumerableTake{S}, state) where {S}
    n, source_state = state
    return n<=0 || done(iter.source, source_state)
end
