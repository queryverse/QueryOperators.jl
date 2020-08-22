struct EnumerableDrop{T,S} <: Enumerable
    source::S
    n::Int
end

function drop(source::Enumerable, n::Integer)
    T = eltype(source)
    S = typeof(source)
    return EnumerableDrop{T,S}(source, Int(n))
end

Base.IteratorSize(::Type{EnumerableDrop{T,S}}) where {T,S} = (Base.IteratorSize(S) isa Base.HasLength || Base.IteratorSize(S) isa Base.HasShape) ? Base.HasLength() : Base.SizeUnknown()

Base.eltype(::Type{EnumerableDrop{T,S}}) where {T,S} = T

Base.length(iter::EnumerableDrop{T,S}) where {T,S} = max(length(iter.source) - iter.n, 0)

function Base.iterate(iter::EnumerableDrop{T,S}) where {T,S}
    ret = iterate(iter.source)
    for i in 1:iter.n
        if ret === nothing
            return nothing
        else
            ret = iterate(iter.source, ret[2])
        end
    end
    return ret
end

function Base.iterate(iter::EnumerableDrop{T,S}, state) where {T,S}
    return iterate(iter.source, state)
end
