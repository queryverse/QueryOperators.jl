struct EnumerableZip{T,S1,S2,RS<:Function} <: Enumerable
    first::S1
    second::S2
    resultSelector::RS
end

Base.eltype(::Type{EnumerableZip{T,S1,S2,RS}}) where {T,S1,S2,RS} = T

# Enumerable.Zip. Like Base.zip and .NET, the result stops at the shorter of
# the two sources — nothing is padded, so no null values are manufactured.
function zip(first::Enumerable, second::Enumerable)
    return _zip(first, second, tuple)
end

function zip(first::Enumerable, second::Enumerable, f_resultSelector::Function, resultSelector::Expr)
    return _zip(first, second, f_resultSelector)
end

function _zip(first::Enumerable, second::Enumerable, f_resultSelector::Function)
    T1 = eltype(first)
    T2 = eltype(second)
    T = Base._return_type(f_resultSelector, Tuple{T1,T2})

    return EnumerableZip{T,typeof(first),typeof(second),typeof(f_resultSelector)}(first, second, f_resultSelector)
end

function Base.IteratorSize(::Type{EnumerableZip{T,S1,S2,RS}}) where {T,S1,S2,RS}
    return haslength(S1) isa Base.HasLength && haslength(S2) isa Base.HasLength ?
        Base.HasLength() : Base.SizeUnknown()
end

Base.length(iter::EnumerableZip) = min(length(iter.first), length(iter.second))

Base.iterate(iter::EnumerableZip) = _zip_next(iter, _NotStarted(), _NotStarted())

Base.iterate(iter::EnumerableZip, state) = _zip_next(iter, state.s1, state.s2)

function _zip_next(iter::EnumerableZip, s1, s2)
    r1 = _iterate_from(iter.first, s1)
    r1 === nothing && return nothing

    r2 = _iterate_from(iter.second, s2)
    r2 === nothing && return nothing

    return iter.resultSelector(r1[1], r2[1]), (s1=r1[2], s2=r2[2])
end
