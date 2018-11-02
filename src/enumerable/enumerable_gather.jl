struct EnumerableGather{T,S} <: Enumerable
    source::S
end

function gather(source::Enumerable)
    T = eltype(source)
    return EnumerableGather{T, typeof(source)}(source)
end

function Base.iterate(iter::EnumerableGather{T, S}) where {T, S}
    source = iter.source
    fields = fieldnames(T)
    #rows = (Base.IteratorSize(typeof(source)) isa Base.HasLength || Base.IteratorSize(typeof(source)) isa Base.HasShape) ? length(source) * length(fieldnames(T)) : 0

    elements = Array{Any}(undef, 0)
    # println("T:", T)
    # println("fieldnames: ",fieldnames(T))
    for i in iter.source
        for j in fields
            # println("What j is:", j)
            push!(elements, (columnName = j, value = i[j]))
        end
        # println("What i is: ", i)
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
