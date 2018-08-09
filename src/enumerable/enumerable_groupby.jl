struct EnumerableGroupBySimple{T,TKey,TS,SO,ES<:Function} <: Enumerable
    source::SO
    elementSelector::ES
end

struct Grouping{TKey,T} <: AbstractArray{T,1}
    _key::TKey
    elements::Array{T,1}
end

key(g::Grouping) = getfield(g, :_key)

function Base.getproperty(g::Grouping{TKey,T}, name::Symbol) where {TKey,T}
    a = getfield(g, :elements)
    return Base.map(i->getfield(i, name), a)
    # s = QueryOperators.query(getfield(g, :elements))
    # return QueryOperators.@map(s, i->getfield(i,name))
end

Base.size(A::Grouping{TKey,T}) where {TKey,T} = size(getfield(A, :elements))
Base.getindex(A::Grouping{TKey,T},i) where {TKey,T} = getfield(A, :elements)[i]
Base.length(A::Grouping{TKey,T}) where {TKey,T} = length(getfield(A, :elements))

Base.eltype(::Type{EnumerableGroupBySimple{T,TKey,TS,SO,ES}}) where {T,TKey,TS,SO,ES} = T

function groupby(source::Enumerable, f_elementSelector::Function, elementSelector::Expr)
    TS = eltype(source)
    TKey = Base._return_type(f_elementSelector, Tuple{TS,})

    SO = typeof(source)

    T = Grouping{TKey,TS}

    ES = typeof(f_elementSelector)

    return EnumerableGroupBySimple{T,TKey,TS,SO,ES}(source,f_elementSelector)
end

function Base.iterate(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}) where {T,TKey,TS,SO,ES}
    result = OrderedDict{TKey,T}()
    for i in iter.source
        key = iter.elementSelector(i)
        if !haskey(result, key)
            result[key] = T(key,Array{TS}(undef, 0))
        end
        push!(getfield(result[key], :elements),i)
    end

    groups = collect(values(result))
    if length(groups)==0
        return nothing
    else
        return groups[1], (groups, 2)
    end
end

function Base.iterate(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}, state) where {T,TKey,TS,SO,ES}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end

struct EnumerableGroupBy{T,TKey,TR,SO,ES<:Function,RS<:Function} <: Enumerable
    source::SO
    elementSelector::ES
    resultSelector::RS
end

Base.eltype(::Type{EnumerableGroupBy{T,TKey,TR,SO,ES, RS}}) where {T,TKey,TR,SO,ES,RS} = T

function groupby(source::Enumerable, f_elementSelector::Function, elementSelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TS = eltype(source)
    TKey = Base._return_type(f_elementSelector, Tuple{TS,})

    SO = typeof(source)

    TR = Base._return_type(f_resultSelector, Tuple{TS,})

    T = Grouping{TKey,TR}

    ES = typeof(f_elementSelector)
    RS = typeof(f_resultSelector)

    return EnumerableGroupBy{T,TKey,TR,SO,ES,RS}(source,f_elementSelector,f_resultSelector)
end

function Base.iterate(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}) where {T,TKey,TR,SO,ES}
    result = OrderedDict{TKey,T}()
    for i in iter.source
        key = iter.elementSelector(i)
        if !haskey(result, key)
            result[key] = T(key,Array{TR}(undef,0))
        end
        push!(getfield(result[key], :elements),iter.resultSelector(i))
    end

    groups = collect(values(result))
    if length(groups)==0
        return nothing
    else
        return groups[1], (groups, 2)
    end
end

function Base.iterate(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}, state) where {T,TKey,TR,SO,ES}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
