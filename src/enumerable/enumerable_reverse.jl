struct EnumerableReverse{T,S} <: Enumerable
    source::S
end

function reverse(source::Enumerable)
    T = eltype(source)
    return EnumerableReverse{T,typeof(source)}(source)
end

Base.IteratorSize(::Type{EnumerableReverse{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableReverse{T,S}}) where {T,S} = T

Base.length(iter::EnumerableReverse) = length(iter.source)

# Reversing needs the whole source, so the elements are collected on the first
# call and then handed out back to front.
function Base.iterate(iter::EnumerableReverse{T,S}) where {T,S}
    elements = Base.collect(T, iter.source)

    if length(elements)==0
        return nothing
    end

    return elements[end], (elements, length(elements)-1)
end

function Base.iterate(iter::EnumerableReverse{T,S}, state) where {T,S}
    if state[2]<1
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]-1)
    end
end
