struct EnumerableGather{T,S,F,I,A} <: Enumerable
    source::S
    fields::F
    indexFields::I
    savedFields::A
    key::Symbol
    value::Symbol
end

struct Not{T}
    val::T
end

function gather(source::Enumerable, args...; key::Symbol = :key, value::Symbol = :value)
    fields = fieldnames(eltype(source))
    
    if length(args) > 0
        indexFields = ()
        firstArg = true
        for arg in args
            if typeof(arg) == Symbol
                indexFields = (indexFields..., arg)
            else typeof(arg) == Not{Symbol}
                if firstArg
                    indexFields = (a for a in fields if a != arg.val)
                else
                    indexFields = (a for a in indexFields if a != arg.val)
                end
            end
            firstArg = false
        end
    else
        indexFields = fields
    end

    savedFields = (n for n in fields if !(n in indexFields)) # fields that are not in `indexFields`
    T = NamedTuple{(key, value, savedFields...)}
    return EnumerableGather{T, typeof(source), typeof(fields), typeof(indexFields), typeof(savedFields)}(source, fields, indexFields, savedFields, key, value)
end

function Base.iterate(iter::EnumerableGather{T, S, F, I, A}) where {T, S, F, I, A}
    source_iterate = iterate(iter.source)
    if source_iterate == nothing || length(iter.indexFields) == 0
        return nothing
    end
    key = iter.indexFields[1]
    current_source_row = source_iterate[1]
    value = current_source_row[key]
    return (NamedTuple{(iter.key, iter.value, iter.savedFields...)}((key, value, Base.map(n->current_source_row[n], iter.savedFields)...)), 
        (current_source_row=current_source_row, source_state=source_iterate[2], current_index_field_index=1))
end

function Base.iterate(iter::EnumerableGather{T, S, F, I, A}, state) where {T, S, F, I, A}
    current_index_field_index = state.current_index_field_index + 1
    if current_index_field_index > length(iter.indexFields)
        source_iterate = iterate(iter.source, state.source_state)
        if source_iterate == nothing || length(iter.indexFields) == 0
            return nothing
        end
        current_index_field_index = 1
        source_state = source_iterate[2]
        current_source_row = source_iterate[1]
    else
        source_state = state.source_state
        current_source_row = state.current_source_row
    end
    key = iter.indexFields[current_index_field_index]
    value = current_source_row[key]
    return (NamedTuple{(iter.key, iter.value, iter.savedFields...)}((key, value, Base.map(n->current_source_row[n], iter.savedFields)...)), 
        (current_source_row=current_source_row, source_state=source_state, current_index_field_index=current_index_field_index))
end

function Base.eltype(iter::EnumerableGather{T, S, F, I, A}) where {T, S, F, I, A}
    return T
end
