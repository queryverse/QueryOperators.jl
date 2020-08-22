struct EnumerableGroupJoin{T,TKey,TI,SO,SI,OKS <: Function,IKS <: Function,RS <: Function} <: Enumerable
    outer::SO
    inner::SI
    outerKeySelector::OKS
    innerKeySelector::IKS
    resultSelector::RS
end

Base.eltype(::Type{EnumerableGroupJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}}) where {T,TKeyOuter,TI,SO,SI,OKS,IKS,RS} = T

function groupjoin(outer::Enumerable, inner::Enumerable, f_outerKeySelector::Function, outerKeySelector::Expr, f_innerKeySelector::Function, innerKeySelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TO = eltype(outer)
    TI = eltype(inner)
    TKeyOuter = Base._return_type(f_outerKeySelector, Tuple{TO,})
    TKeyInner = Base._return_type(f_innerKeySelector, Tuple{TI,})

    if TKeyOuter != TKeyInner
        error("The keys in the join clause have different types, $TKeyOuter and $TKeyInner.")
    end

    SO = typeof(outer)
    SI = typeof(inner)

    T = Base._return_type(f_resultSelector, Tuple{TO,Array{TI,1}})

    OKS = typeof(f_outerKeySelector)
    IKS = typeof(f_innerKeySelector)
    RS = typeof(f_resultSelector)

    return EnumerableGroupJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}(outer, inner, f_outerKeySelector, f_innerKeySelector, f_resultSelector)
end

function Base.iterate(iter::EnumerableGroupJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}) where {T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}
    results = Array{T}(undef, 0)

    inner_dict = OrderedDict{TKeyOuter,Array{TI,1}}()
    for i in iter.inner
        key = iter.innerKeySelector(i)
        if !haskey(inner_dict, key)
            inner_dict[key] = Array{TI}(undef, 0)
        end
        push!(inner_dict[key], i)
    end

    for i in iter.outer
        outerKey = iter.outerKeySelector(i)
        if haskey(inner_dict, outerKey)
            g = inner_dict[outerKey]
        else
            g = Array{TI}(undef, 0)
        end
        push!(results, iter.resultSelector(i, g))
    end

    if length(results) == 0
        return nothing
    end

    return results[1], (results, 2)
end

function Base.iterate(iter::EnumerableGroupJoin{T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}, state) where {T,TKeyOuter,TI,SO,SI,OKS,IKS,RS}
    if state[2] > length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2] + 1)
    end
end
