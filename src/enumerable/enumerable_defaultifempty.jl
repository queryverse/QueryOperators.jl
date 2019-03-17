struct EnumerableDefaultIfEmpty{T,S} <: Enumerable
    source::S
    default_value::T
end

Base.eltype(iter::Type{EnumerableDefaultIfEmpty{T,S}}) where {T,S} = T

_default_value_expr(::Type{T}) where {T} = :( DataValues.DataValue{$T}() )

_default_value_expr(::Type{T}) where {T<:DataValues.DataValue} = :( $T() )

function _default_value_expr(::Type{T}) where {T<:NamedTuple}
    return :( NamedTuple{$(fieldnames(T))}( ($( (_default_value_expr(fieldtype(T,i)) for i in 1:length(fieldnames(T)))...   ),)) )
end

@generated function default_if_empty(source::S) where {S}
    T_source = eltype(source)

    default_value_expr = _default_value_expr(T_source)

    q = quote
        default_value = $default_value_expr

        T = typeof(default_value)

        return EnumerableDefaultIfEmpty{T,$S}(source, default_value)
    end

    return q
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
        return convert(T,s[1]), s[2]
    end
end

function Base.iterate(iter::EnumerableDefaultIfEmpty{T,S}, state) where {T,S}
    state===nothing && return nothing

    s = iterate(iter.source, state)
    if s===nothing
        return nothing
    else
        return convert(T, s[1]), s[2]
    end
end
