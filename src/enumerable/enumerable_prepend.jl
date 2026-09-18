struct EnumerablePrepend{T,S} <: Enumerable
    source::S
    element::T
end

# Enumerable.Prepend: one element followed by the source. As with `append`, the
# element is converted to the source's element type.
function prepend(source::Enumerable, element)
    T = eltype(source)
    return EnumerablePrepend{T,typeof(source)}(source, convert(T, element))
end

Base.IteratorSize(::Type{EnumerablePrepend{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerablePrepend{T,S}}) where {T,S} = T

Base.length(iter::EnumerablePrepend) = length(iter.source) + 1

Base.iterate(iter::EnumerablePrepend) = (iter.element, (state=_NotStarted(),))

function Base.iterate(iter::EnumerablePrepend, state)
    ret = _iterate_from(iter.source, state.state)
    ret === nothing && return nothing
    return ret[1], (state=ret[2],)
end
