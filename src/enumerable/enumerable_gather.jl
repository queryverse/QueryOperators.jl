struct EnumerableGather{T,S,F} <: Enumerable
    source::S
    fields::F
    indexField::Symbol
end

function gather(source::Enumerable, withIndex::Bool = false)
    T = eltype(source)
    fields = fieldnames(T)
    F = typeof(fields)
    if withIndex
        return EnumerableGather{T, typeof(source), F}(source, fields, fields[1])
    else
        return EnumerableGather{T, typeof(source), F}(source, fields, Symbol())
    end
end

function Base.iterate(iter::EnumerableGather{T, S}) where {T, S}
    source = iter.source
    fields = fieldnames(T)
    elements = Array{Any}(undef, 0)
    for i in iter.source
        if iter.indexField == Symbol() # without index field
            for j in fields
                push!(elements, (columnName = j, value = i[j]))
            end
        else
            for j in fields
                if j != iter.indexField
                    push!(elements, (index = i[iter.indexField], columnName = j, value = i[j]))
                end
            end
        end
    end
    if length(elements) == 0
        return nothing
    end
    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableGather{T,S}, state) where {T,S}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
