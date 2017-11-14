struct EnumerableGroupBySimple{T,TKey,TS,SO,ES<:Function} <: Enumerable
    source::SO
    elementSelector::ES
end

struct Grouping{TKey,T} <: AbstractArray{T,1}
    key::TKey
    elements::Array{T,1}
end

Base.size(A::Grouping{TKey,T}) where {TKey,T} = size(A.elements)
Base.getindex(A::Grouping{TKey,T},i) where {TKey,T} = A.elements[i]
Base.length(A::Grouping{TKey,T}) where {TKey,T} = length(A.elements)

Base.eltype(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}) where {T,TKey,TS,SO,ES} = T

Base.eltype(iter::Type{EnumerableGroupBySimple{T,TKey,TS,SO,ES}}) where {T,TKey,TS,SO,ES} = T

function groupby(source::Enumerable, f_elementSelector::Function, elementSelector::Expr)
    TS = eltype(source)
    TKey = Base._return_type(f_elementSelector, Tuple{TS,})

    SO = typeof(source)

    T = Grouping{TKey,TS}

    ES = typeof(f_elementSelector)

    return EnumerableGroupBySimple{T,TKey,TS,SO,ES}(source,f_elementSelector)
end

# TODO This should be rewritten as a lazy iterator
function Base.start(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}) where {T,TKey,TS,SO,ES}
    result = OrderedDict{TKey,T}()
    for i in iter.source
        key = iter.elementSelector(i)
        if !haskey(result, key)
            result[key] = T(key,Array{TS}(0))
        end
        push!(result[key].elements,i)
    end
    return collect(values(result)),1
end

function Base.next(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}, state) where {T,TKey,TS,SO,ES}
    results = state[1]
    curr_index = state[2]
    return results[curr_index], (results, curr_index+1)
end

function Base.done(iter::EnumerableGroupBySimple{T,TKey,TS,SO,ES}, state) where {T,TKey,TS,SO,ES}
    results = state[1]
    curr_index = state[2]
    return curr_index > length(results)
end

struct EnumerableGroupBy{T,TKey,TR,SO,ES<:Function,RS<:Function} <: Enumerable
    source::SO
    elementSelector::ES
    resultSelector::RS
end

Base.eltype(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}) where {T,TKey,TR,SO,ES} = T

Base.eltype(iter::Type{EnumerableGroupBy{T,TKey,TR,SO,ES}}) where {T,TKey,TR,SO,ES} = T

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

# TODO This should be rewritten as a lazy iterator
function Base.start(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}) where {T,TKey,TR,SO,ES}
    result = OrderedDict{TKey,T}()
    for i in iter.source
        key = iter.elementSelector(i)
        if !haskey(result, key)
            result[key] = T(key,Array{TR}(0))
        end
        push!(result[key].elements,iter.resultSelector(i))
    end
    return collect(values(result)),1
end

function Base.next(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}, state) where {T,TKey,TR,SO,ES}
    results = state[1]
    curr_index = state[2]
    return results[curr_index], (results, curr_index+1)
end

function Base.done(iter::EnumerableGroupBy{T,TKey,TR,SO,ES}, state) where {T,TKey,TR,SO,ES}
    results = state[1]
    curr_index = state[2]
    return curr_index > length(results)
end
