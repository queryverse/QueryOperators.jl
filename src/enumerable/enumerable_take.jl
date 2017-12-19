struct EnumerableTake{T,S} <: Enumerable
    source::S
    n::Int
end

function take(source::Enumerable, n::Integer)
    T = eltype(source)
    S = typeof(source)
    return EnumerableTake{T,S}(source, Int(n))
end

Base.iteratorsize(::Type{EnumerableTake{T,S}}) where {T,S} = Base.iteratorsize(S) in (Base.HasLength(), Base.HasShape()) ? Base.HasLength() : Base.SizeUnknown()

Base.eltype(iter::EnumerableTake{T,S}) where {T,S} = T

Base.length(iter::EnumerableTake{T,S}) where {T,S} = min(length(iter.source),iter.n)

function Base.start(iter::EnumerableTake{T,S}) where {T,S}
    return iter.n, start(iter.source)
end

function Base.next(iter::EnumerableTake{T,S}, s) where {T,S}
    n, source_state = s
    x = next(iter.source, source_state)
    v = x[1]
    source_new = x[2]
    return v, (n-1, source_new)
end

function Base.done(iter::EnumerableTake{T,S}, state) where {T,S}
    n, source_state = state
    return n<=0 || done(iter.source, source_state)
end
