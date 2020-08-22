struct EnumerableTake{T,S} <: Enumerable
    source::S
    n::Int
end

function take(source::Enumerable, n::Integer)
    T = eltype(source)
    S = typeof(source)
    return EnumerableTake{T,S}(source, Int(n))
end

Base.IteratorSize(::Type{EnumerableTake{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableTake{T,S}}) where {T,S} = T

Base.length(iter::EnumerableTake{T,S}) where {T,S} = min(length(iter.source), iter.n)

function Base.iterate(iter::EnumerableTake{T,S}) where {T,S}
    ret = iterate(iter.source)

    if ret === nothing
        return nothing
    elseif iter.n == 0
        return nothing
    else
        return ret[1], (ret[2], 1)
    end
end

function Base.iterate(iter::EnumerableTake{T,S}, state) where {T,S}
    if state[2] == iter.n
        return nothing
    else
        ret = iterate(iter.source, state[1])

        if ret === nothing
            return nothing
        else
            return ret[1], (ret[2], state[2] + 1)
        end
    end
end
