struct EnumerableFullJoin{T,TKey,TOD,TID,SO,SI,OKS<:Function,IKS<:Function,RS<:Function} <: Enumerable
    outer::SO
    inner::SI
    outerKeySelector::OKS
    innerKeySelector::IKS
    resultSelector::RS
    default_outer::TOD
    default_inner::TID
end

Base.eltype(::Type{EnumerableFullJoin{T,TKey,TOD,TID,SO,SI,OKS,IKS,RS}}) where {T,TKey,TOD,TID,SO,SI,OKS,IKS,RS} = T

function full_join(outer::Enumerable, inner::Enumerable, f_outerKeySelector::Function, outerKeySelector::Expr, f_innerKeySelector::Function, innerKeySelector::Expr, f_resultSelector::Function, resultSelector::Expr)
    TO = eltype(outer)
    TI = eltype(inner)
    TKeyOuter = Base._return_type(f_outerKeySelector, Tuple{TO,})
    TKeyInner = Base._return_type(f_innerKeySelector, Tuple{TI,})

    _check_join_key_types("full_join", TKeyOuter, TKeyInner)

    default_outer = _default_value(TO)
    default_inner = _default_value(TI)
    TOD = typeof(default_outer)
    TID = typeof(default_inner)

    T = Base._return_type(f_resultSelector, Tuple{TOD,TID})

    SO = typeof(outer)
    SI = typeof(inner)
    OKS = typeof(f_outerKeySelector)
    IKS = typeof(f_innerKeySelector)
    RS = typeof(f_resultSelector)

    return EnumerableFullJoin{T,TKeyOuter,TOD,TID,SO,SI,OKS,IKS,RS}(outer, inner, f_outerKeySelector, f_innerKeySelector, f_resultSelector, default_outer, default_inner)
end

function Base.iterate(iter::EnumerableFullJoin{T,TKey,TOD,TID,SO,SI,OKS,IKS,RS}) where {T,TKey,TOD,TID,SO,SI,OKS,IKS,RS}
    results = Array{T}(undef, 0)

    inner_dict = _outerjoin_lookup(iter.inner, iter.innerKeySelector, TKey, TID)

    # All outer elements first, in source order: matched pairs where a key
    # matches, otherwise the outer element paired with an all-null inner.
    matched_keys = Set{TKey}()
    for i in iter.outer
        outerKey = iter.outerKeySelector(i)
        converted_i = convert(TOD, i)
        if haskey(inner_dict, outerKey)
            push!(matched_keys, outerKey)
            for j in inner_dict[outerKey]
                push!(results, iter.resultSelector(converted_i, j))
            end
        else
            push!(results, iter.resultSelector(converted_i, iter.default_inner))
        end
    end

    # Then the inner elements whose key never appeared on the outer side,
    # in inner source order, paired with an all-null outer.
    for (innerKey, elements) in inner_dict
        innerKey in matched_keys && continue
        for j in elements
            push!(results, iter.resultSelector(iter.default_outer, j))
        end
    end

    if length(results)==0
        return nothing
    end

    return results[1], (results, 2)
end

function Base.iterate(iter::EnumerableFullJoin{T,TKey,TOD,TID,SO,SI,OKS,IKS,RS}, state) where {T,TKey,TOD,TID,SO,SI,OKS,IKS,RS}
    if state[2]>length(state[1])
        return nothing
    else
        return state[1][state[2]], (state[1], state[2]+1)
    end
end
