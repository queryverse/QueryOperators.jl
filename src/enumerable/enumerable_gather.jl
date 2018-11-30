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
    T = eltype(source)
    fields = fieldnames(T)
    F = typeof(fields)
    if args != (false,)
        prev = ()
        firstArg = true
        for arg in args
            if typeof(arg) == Symbol
                prev = (prev..., arg)
            else typeof(arg) == Not{Symbol}
                if firstArg
                    prev = (a for a in fields if a != arg.val)
                else
                    prev = (a for a in prev if a != arg.val)
                end
            end
            firstArg = false
        end
    else
        prev = fields
    end

    I = typeof(prev)
    return EnumerableGather{T, typeof(source), F, I}(source, fields, prev, key, value)
end

function Base.iterate(iter::EnumerableGather{T, S, F, I}) where {T, S, F, I}
    source = iter.source
    fields = fieldnames(T)
    elements = Array{Any}(undef, 0)
    
    savedFields = (n for n in iter.fields if !(n in iter.indexFields))
    for i in iter.source
        for j in fields
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
    if length(iter.indexFields) == 0
        return nothing
    end
    savedFields = (n for n in iter.fields if !(n in iter.indexFields))
    firstRow = iterate(iter.source)[1]
    firstIndex = iter.indexFields[1]
    return NamedTuple{(iter.key, iter.value, savedFields...), typeof(((firstIndex, firstRow[firstIndex], Base.map(n->firstRow[n], savedFields)...)))}
end
