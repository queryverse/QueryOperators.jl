abstract type Enumerable end

Base.IteratorSize(::Type{T}) where {T <: Enumerable} = Base.SizeUnknown()
IteratorInterfaceExtensions.isiterable(x::Enumerable) = true

haslength(S) = Base.IteratorSize(S) isa Union{Base.HasLength, Base.HasShape} ? Base.HasLength() : Base.IteratorSize(S)

# Operators that walk more than one source keep "which source, how far into it"
# in their iteration state. `_NotStarted` marks a source that has not been
# iterated yet, so that `_iterate_from` can pick the right `iterate` method
# without conflating it with a source whose own state happens to be `nothing`.
struct _NotStarted end

_iterate_from(source, ::_NotStarted) = iterate(source)
_iterate_from(source, state) = iterate(source, state)

# Element types of two sources that will be emitted into a single stream have
# to agree, the same requirement `default_if_empty` places on its default value.
function _check_same_eltype(op, ::Type{T1}, ::Type{T2}) where {T1,T2}
    if T1 != T2
        error("The two sequences passed to $op have different element types, $T1 and $T2.")
    end
end

function _check_same_keytype(op, ::Type{TKey1}, ::Type{TKey2}) where {TKey1,TKey2}
    if TKey1 != TKey2
        error("The keys of the two sequences passed to $op have different types, $TKey1 and $TKey2.")
    end
end
