struct EnumerableUnique{T,TKEY,S,Q <: Function} <: Enumerable
    source::S
    f::Q
end

function unique(source::Enumerable, f::Function, f_expr::Expr)
    T = eltype(source)
    S = typeof(source)
    TKEY = Base._return_type(f, Tuple{T,})
    return EnumerableUnique{T,TKEY,S,typeof(f)}(source, f)
end

Base.eltype(::Type{EnumerableUnique{T,TKEY,S,Q}}) where {T,TKEY,S,Q} = T

function Base.iterate(iter::EnumerableUnique{T,TKEY,S,Q}) where {T,TKEY,S,Q}
    ret = iterate(iter.source)
    
    ret === nothing && return nothing

    observed_keys = Set{TKEY}()

    first_element = ret[1]
    source_state = ret[2]

    key_first_element = iter.f(first_element)

    push!(observed_keys, key_first_element)

    return first_element, (observed_keys = observed_keys, source_state = source_state)
end

function Base.iterate(iter::EnumerableUnique{T,TKEY,S,Q}, state) where {T,TKEY,S,Q}
    ret = iterate(iter.source, state.source_state)

    ret === nothing && return nothing

    while true
        current_element = ret[1]
        key_current_element = iter.f(current_element)
        if key_current_element in state.observed_keys
            ret = iterate(iter.source, ret[2])
            ret === nothing && return nothing
        else
            push!(state.observed_keys, key_current_element)

            return current_element, (observed_keys = state.observed_keys, source_state = ret[2])
        end
    end
end
