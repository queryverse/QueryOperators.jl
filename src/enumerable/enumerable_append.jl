struct EnumerableAppend{T,S} <: Enumerable
    source::S
    element::T
end

# Enumerable.Append: the source followed by one more element. The element is
# converted to the source's element type, so appending an Int to a sequence of
# Float64 works.
function append(source::Enumerable, element)
    T = eltype(source)
    return EnumerableAppend{T,typeof(source)}(source, convert(T, element))
end

Base.IteratorSize(::Type{EnumerableAppend{T,S}}) where {T,S} = haslength(S)

Base.eltype(::Type{EnumerableAppend{T,S}}) where {T,S} = T

Base.length(iter::EnumerableAppend) = length(iter.source) + 1

Base.iterate(iter::EnumerableAppend) = _append_next(iter, _NotStarted())

function Base.iterate(iter::EnumerableAppend, state)
    # `state.done` marks the appended element as already handed out.
    state.done && return nothing
    return _append_next(iter, state.state)
end

function _append_next(iter::EnumerableAppend, source_state)
    ret = _iterate_from(iter.source, source_state)
    ret === nothing && return iter.element, (done=true, state=source_state)
    return ret[1], (done=false, state=ret[2])
end
