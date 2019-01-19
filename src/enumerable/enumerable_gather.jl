struct EnumerableGather{T,S,F,I} <: Enumerable
    source::S
    fields::F
    indexFields::I
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
    return EnumerableGather{T, typeof(source), typeof(fields), typeof(indexFields)}(source, fields, indexFields, key, value)
end

function Base.iterate(iter::EnumerableGather{T, S, F, I}) where {T, S, F, I}
    source = iter.source
    elements = Array{T}(undef, 0)
    
    savedFields = (n for n in iter.fields if !(n in iter.indexFields))
    for i in iter.source
        for j in iter.fields
            if j in iter.indexFields
                push!(elements, NamedTuple{(iter.key, iter.value, savedFields...)}((j, i[j], Base.map(n->i[n], savedFields)...)))
            end
        end
    end
    if length(elements) == 0
        return nothing
    end
    return elements[1], (elements, 2)
end

function Base.iterate(iter::EnumerableGather{T, S, F, I}, state) where {T, S, F, I}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end

function Base.eltype(iter::EnumerableGather{T, S, F, I}) where {T, S, F, I}
    return T
end
