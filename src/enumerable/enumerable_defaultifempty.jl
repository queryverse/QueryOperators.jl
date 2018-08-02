struct EnumerableDefaultIfEmpty{T,S} <: Enumerable
    source::S
    default_value::T
end

Base.eltype(iter::Type{EnumerableDefaultIfEmpty{T,S}}) where {T,S} = T

function default_if_empty(source::S) where {S}
    T = eltype(source)

    if T<:NamedTuple
        default_value = T(([fieldtype(T,i)() for i in 1:length(fieldnames(T))]...,))
    else
        default_value = T()
    end

    return EnumerableDefaultIfEmpty{T,S}(source, default_value)
end


function default_if_empty(source::S, default_value::TD) where {S,TD}
    T = eltype(source)
    if T!=TD
        error("The default value must have the same type as the elements from the source.")
    end
    return EnumerableDefaultIfEmpty{T,S}(source, default_value)
end

function Base.iterate(iter::EnumerableDefaultIfEmpty{T,S}) where {T,S}
    s = iterate(iter.source)

    if s===nothing
        return iter.default_value, nothing
    else
        return s
    end
end

function Base.iterate(iter::EnumerableDefaultIfEmpty{T,S}, state) where {T,S}
    if state===nothing
        return nothing
    else
        return iterate(iter.source, state)
    end
end
